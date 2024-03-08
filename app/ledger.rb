require 'date'
require 'json'
require_relative '../config/sequel'

module FinanceTracker
    RecordResult = Struct.new(:success?, :transfer_ids, :error_message)
    class ::Hash
        def deep_merge(second)
            merger = proc { |key, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2 }
            self.merge(second, &merger)
        end
    end
    class Ledger
        def unprocessed_records
            # get next unprocessed record which we assume is from either Asset or Liability account
            unprocessed_transfer =  DB[:unprocessed_records].order(:id).first
            # need to switch real world account with an account from our db
            a = Account.new
            account = a.get_corresp_app_account(unprocessed_transfer[:account])
            unprocessed_transfer[:account_id] = account.id
            unprocessed_transfer[:account_name] = account.name
            unprocessed_transfer.delete(:account)
            # need to build hash of account_id and account_name for the opposite accounts
            # to be used in the post '/transfers' route
            # split here depending on Liability or Asset
            if account.category.normal == -1
                # we are dealing with a liability account
                if unprocessed_transfer[:direction] == -1
                    # we are dealing with a debit return all expense accounts
                    root_cat = Category.where(name: 'Expense').first
                    all_cats = root_cat.return_cats_as_nested_array.flatten
                    expense_accounts = {}
                    all_cats.each do |cat|
                        accounts = Account.where(category_id: cat["id"])
                        accounts.each do |account|
                            expense_accounts[account.id] = account.name
                        end
                    end
                    unprocessed_transfer[:expense_accounts] = expense_accounts
                    return unprocessed_transfer
                else
                    # we are dealing with a credit
                    if unprocessed_transfer[:description].match(ENV['CC1_PMT_PATTERN'])
                        # we are dealing with a credit card payment return asset checking account
                    else
                        # we are dealing with a credit card reimbursement or cash back
                        # alert user to check for charge on same statement
                        # return all expense accounts
                    end
                end
            else
                # we are dealing with an asset account
                if unprocessed_transfer[:direction] == 1
                    # we are dealing with a debit entry
                    if unprocessed_transfer[:description].match(ENV['CC_PATTERN'])
                        # we are dealing with a payment to credit card return liability account
                    else
                        # we are dealing with purchase return all expense accounts
                    end
                else
                    # we are dealing with work reimbursement or salary
                    if unprocessed_transfer[:description].match(ENV['WORK_REIMBURSE_PATTERN'])
                        # we are dealing with work reimbursement return liability account
                    else
                        if unprocessed_transfer[:description].match(ENV['SALARY'])
                            # we are dealing with salary return revenue account
                        else
                            # we are dealing with payment to us return expense account
                        end
                    end
                end
            end
            a = Augmenter.new
            str_to_match = {salary: ENV['SALARY', work_reimburse: ENV['WORK_REIMBURSE_PATTERN'],
                cc_all: ENV['CC_PATTERN'], cc1_pmt: ENV['CC1_PMT_PATTERN']]}
            str_to_match.each do |key, value|
                if value.match(unprocessed_transfer[:description])
                end
            end
            unprocessed_transfer
        end
        def record(transfer)
            # validate data
            validated = validate_transfer(transfer)
            unless validated
                message = 'Invalid transfer: missing or corrupt data'
                return RecordResult.new(false, nil, message)
            end
            t_date_array = transfer['shared']['posted_date'].split("-")
            dt = DateTime.new(t_date_array[0].to_i, t_date_array[1].to_i,
                t_date_array[2].to_i)
            transfer_id = get_transfer_id(dt.to_date)
            record_ids = Hash.new
            DB.transaction do
                transfer_records =  DB[:transfers]
                # for debit side, money is going into this account
                record_ids["debit"] = transfer_records.insert(
                    transfer_id: transfer_id,
                    posted_date: dt.to_date,
                    date: DateTime.now.to_date,
                    direction: 1,
                    amount: transfer['shared']['amount'],
                    user_id: transfer['shared']['user_id'],
                    account_id: transfer['debit_account_id'],
                )
                # for credit side
                record_ids["credit"] = transfer_records.insert(
                    transfer_id: transfer_id,
                    posted_date: dt.to_date,
                    date: DateTime.now.to_date,
                    direction: -1,
                    amount: transfer['shared']['amount'],
                    user_id: transfer['shared']['user_id'],
                    account_id: transfer['credit_account_id'],
                )
            end
            RecordResult.new(true, {"debit_record_id" => record_ids["debit"], "credit_record_id" => record_ids["credit"]}, nil)
        end
        def get_transfer_id(dt)
            #first, look for transaction transfer_id
            transfer_records =  DB[:transfers]
            transfers_on_same_posted_date = transfer_records.where(posted_date: dt).all
            temp_transfer_id = 0
            unless transfers_on_same_posted_date.empty?
                transfers_on_same_posted_date.each do |t|
                    if temp_transfer_id > t[:transfer_id]
                        break
                    else
                        temp_transfer_id = t[:transfer_id] + 1
                    end
                end
            end
            temp_transfer_id
        end
        def validate_transfer(transfer)
            # are ids valid?
            is_valid = {"user" => 0, "debit_account" => 0, "date" => 0,
            "credit_account" => 0, "amount" => 0}
            user_ids = DB[:users].map(:id)
            account_ids = DB[:accounts].map(:id)
            user_ids.include?(transfer["shared"]["user_id"]) ? is_valid["user"] = 1 : false
            account_ids.include?(transfer["debit_account_id"]) ? is_valid["debit_account"] = 1 : false
            account_ids.include?(transfer["credit_account_id"]) ? is_valid["credit_account"] = 1 : false

            t_date_array = transfer['shared']['posted_date'].split("-")
            begin
                dt = DateTime.new(t_date_array[0].to_i, t_date_array[1].to_i,
                t_date_array[2].to_i)
                is_valid["date"] = 1
            rescue Date::Error => e
                puts "date's in error #{e}"
            end
            
            transfer["shared"]["amount"] > 0 ? is_valid["amount"] = 1 : false
            # test if any keys still have a false value
            !is_valid.value?(0)
        end
        def transfers_on(date)
            t_date_array = date.split("-")
            dt = DateTime.new(t_date_array[0].to_i, t_date_array[1].to_i,
            t_date_array[2].to_i)
            #expecting two ids per transaction and want to pacakage accordingly
            result_array = DB[:transfers].where(posted_date: dt.to_date).all
            group_transfers(result_array)
        end
        def group_transfers(transfers_array)
            transfer_record_complete = false
            transfer_hash = Hash.new
            count = 0
            transfers_array.each do |transfer_record|
                transaction_id = "#{transfer_record[:posted_date].to_s}_#{transfer_record[:transfer_id]}"
                if transfer_hash.has_key?(transaction_id)
                    if transfer_record[:direction] == -1 #credit directions always -1
                        transfer_hash[transaction_id]["credit_account_id"] = transfer_record[:account_id]
                        transfer_hash[transaction_id]["credit_record_id"] = transfer_record[:id]
                    else
                        transfer_hash[transaction_id]["debit_account_id"] = transfer_record[:account_id]
                        transfer_hash[transaction_id]["debit_record_id"] = transfer_record[:id]
                    end
                else
                    #starting with a new hash
                    transfer_hash[transaction_id] = {"shared" => {}, "credit_account_id" => nil, "debit_account_id" => nil,
                    "credit_record_id" => nil, "debit_record_id" => nil}
                    shared_hash = {"posted_date" => transfer_record[:posted_date], "amount" => transfer_record[:amount],
                        "user_id" => transfer_record[:user_id]}
                    transfer_hash[transaction_id]["shared"] = shared_hash
                    if transfer_record[:direction] == -1 #credit directions always -1
                        transfer_hash[transaction_id]["credit_account_id"] = transfer_record[:account_id]
                        transfer_hash[transaction_id]["credit_record_id"] = transfer_record[:id]
                    else
                        transfer_hash[transaction_id]["debit_account_id"] = transfer_record[:account_id]
                        transfer_hash[transaction_id]["debit_record_id"] = transfer_record[:id]
                    end
                end
                count = count +1
            end
            transfer_hash
        end
    end
end