require 'date'
require 'json'
require_relative '../config/sequel'
require_relative './models/account'
require_relative './models/category'
require_relative './models/entry'
require_relative './augmenter'
require_relative './record_importer.rb'
require_relative './models/transaction'

module FinanceTracker
    RecordResult = Struct.new(:success?, :transfer_ids, :error_message)
    class ::Hash
        def deep_merge(second)
            merger = proc { |key, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2 }
            self.merge(second, &merger)
        end
    end
    class Ledger
        def refund_unprocessed_record(value)
            # get next unprocessed record that needs to be tagged as a refund
            unprocessed_record =  DB[:unprocessed_records].where(id: value).first
            # if no unprocessed records return empty array
            return [] unless unprocessed_record
            unprocessed_record[:refund] = 1
            result = DB[:unprocessed_records].where(id: unprocessed_record[:id]).update(unprocessed_record)
            result
        end
        def skip_unprocessed_record(value)
            # get next unprocessed record that needs to be skipped
            unprocessed_record =  DB[:unprocessed_records].where(id: value).first
            # if no unprocessed records return empty array
            return [] unless unprocessed_record
            unprocessed_record[:skip] = 1
            DB[:unprocessed_records].where(id: unprocessed_record[:id]).update(unprocessed_record)
            unprocessed_record
        end
        def next_unprocessed_record
            # get next unprocessed record which we assume is from either Asset or Liability account
            unprocessed_transfer =  DB[:unprocessed_records].where(skip: 0).where(refund:0).order(:id).first
            # if no unprocessed records return empty array
            return [] unless unprocessed_transfer
            # need to switch real world account with an account from our db
            a = Account.new
            account = a.get_corresp_app_account(unprocessed_transfer[:account])
            unprocessed_transfer[:account_id] = account.id
            unprocessed_transfer[:account_name] = account.name
            unprocessed_transfer.delete(:account)
            # need to adjust the amount that was stored (see record_importer.rb)
            #as an integer by multiplying by 100
            unprocessed_transfer[:amount] = unprocessed_transfer[:amount]/100.0
            # need to reverse the direction of the transfer since we are dealing with
            # unprocessed records which came from csv files from the bank
            unprocessed_transfer[:direction] = unprocessed_transfer[:direction] * -1
            # need to build hash of account_id and account_name for the paired accounts
            # which are those most likely to be used in the post '/transfers' route
            # split here depending on Liability or Asset
            if account.category.normal == -1
                # we are dealing with a liability account
                if unprocessed_transfer[:direction] == 1
                    # we are dealing with a debit return all expense accounts
                    unprocessed_transfer[:paired_accounts] = get_paired_accounts("Expense")
                else
                    # we are dealing with a credit
                    if unprocessed_transfer[:description].match(ENV['CC1_PMT_PATTERN'])
                        # we are dealing with a credit card payment return asset checking account
                        unprocessed_transfer[:paired_accounts] = get_paired_accounts("Assets")
                    else
                        # we are dealing with a credit card reimbursement or cash back
                        # alert user to check for charge on same statement
                        # return all expense accounts but TODO also need to return asset checking account
                        unprocessed_transfer[:alert] = "Refund or cash back"
                        unprocessed_transfer[:paired_accounts] = get_paired_accounts("Expense")
                    end
                end
            else
                # we are dealing with an asset account
                if unprocessed_transfer[:direction] == 1
                    # we are dealing with a debit entry
                    if unprocessed_transfer[:description].match(ENV['CC_PATTERN'])
                        # we are dealing with a payment to credit card return liability account
                        unprocessed_transfer[:paired_accounts] = get_paired_accounts("Liabilities")
                    else
                        # we are dealing with purchase return all expense accounts
                        unprocessed_transfer[:paired_accounts] = get_paired_accounts("Expense")
                    end
                else
                    # we are dealing with work reimbursement or salary
                    if unprocessed_transfer[:description].match(ENV['WORK_REIMBURSE_PATTERN'])
                        # we are dealing with work reimbursement return liability account
                        unprocessed_transfer[:alert] = "Work reimbursement"
                        unprocessed_transfer[:paired_accounts] = get_paired_accounts("Liabilities")
                    else
                        if unprocessed_transfer[:description].match(ENV['SALARY_PATTERN'])
                            # we are dealing with salary return revenue account
                            unprocessed_transfer[:paired_accounts] = get_paired_accounts("Revenue")
                        else
                            # we are dealing with payment to us return expense account
                            unprocessed_transfer[:alert] = "Reimbursement"
                            unprocessed_transfer[:paired_accounts] = get_paired_accounts("Expense")
                        end
                    end
                end
            end
            # need to reset the direction now that we have the paired accounts
            unprocessed_transfer[:direction] = unprocessed_transfer[:direction] * -1
            unprocessed_transfer
        end
        def get_paired_accounts(account_type)
            root_cat = Category.where(name: account_type).first
            #check if root_cat has descendants
            if root_cat.has_descendants?
                all_cats = root_cat.return_descendants
                paired_accounts = {}
                all_cats.each do |cat|
                    accounts = Account.where(category_id: cat[:id]).all
                    accounts.each do |account|
                        paired_accounts[account.values[:id]] = account.values[:name]
                    end
                end
            else
                accounts = Account.where(category_id: root_cat.id).all
                paired_accounts = {}
                accounts.each do |account|
                    paired_accounts[account.values[:id]] = account.values[:name]
                end
            end
            paired_accounts
        end
        def record(transfer)
            # validate data
            #first, we adjust the amount to be stored as an integer by multiplying by 100
            transfer['shared']['amount'] = (transfer['shared']['amount'].to_f * 100).to_i
            validated = validate_transfer(transfer)
            unless validated
                message = 'Invalid transfer: missing or corrupt data'
                return RecordResult.new(false, nil, message)
            end
            # look to see if un_pr_record_id is present and also found in the unprocessed_records table
            unprocessed_record = nil
            unless transfer['shared']['un_pr_record_id'].nil?
                unprocessed_record =  DB[:unprocessed_records].where(id: transfer['shared']['un_pr_record_id']).first
                unless unprocessed_record
                    message = 'Invalid transfer: unprocessed record id not found in unprocessed records table'
                    return RecordResult.new(false, nil, message)
                end
            end

            t_date_array = transfer['shared']['posted_date'].split("-")
            dt = DateTime.new(t_date_array[0].to_i, t_date_array[1].to_i,
                t_date_array[2].to_i)
            record_ids = Hash.new
            DB.transaction do
                transactions =  DB[:transactions]
                entries =  DB[:entries]
                # need to set up a transaction
                record_ids["transaction_id"] = transactions.insert(
                    posted_date: dt.to_date,
                    description: transfer['shared']['description'],
                    notes: transfer['shared']['notes'],
                    user_id: transfer['shared']['user_id']
                )
                # for debit side, money is going into this account
                record_ids["debit"] = entries.insert(
                    transaction_id: record_ids["transaction_id"],
                    account_id: transfer['debit_account_id'],
                    amount: transfer['shared']['amount'],
                    direction: 1
                )
                # for credit side
                record_ids["credit"] = entries.insert(
                    transaction_id: record_ids["transaction_id"],
                    account_id: transfer['credit_account_id'],
                    amount: transfer['shared']['amount'],
                    direction: -1
                )
                # if unprocessed_record is not nil then delete it
                if unprocessed_record
                    DB[:unprocessed_records].where(id: transfer['shared']['un_pr_record_id']).delete
                end
            end
            RecordResult.new(true, {"debit_record_id" => record_ids["debit"],  "credit_record_id" => record_ids["credit"],
                "transaction_id" => record_ids["transaction_id"]}, nil)
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
            user_ids.include?(transfer["shared"]["user_id"].to_i) ? is_valid["user"] = 1 : false
            account_ids.include?(transfer["debit_account_id"].to_i) ? is_valid["debit_account"] = 1 : false
            account_ids.include?(transfer["credit_account_id"].to_i) ? is_valid["credit_account"] = 1 : false

            t_date_array = transfer['shared']['posted_date'].split("-")
            begin
                dt = DateTime.new(t_date_array[0].to_i, t_date_array[1].to_i,
                t_date_array[2].to_i)
                is_valid["date"] = 1
            rescue Date::Error => e
                puts "date's in error #{e}"
            end
            
            transfer["shared"]["amount"].to_i > 0 ? is_valid["amount"] = 1 : false
            # test if any keys still have a false value
            !is_valid.value?(0)
        end
        def transfers_on(date)
            t_date_array = date.split("-")
            dt = DateTime.new(t_date_array[0].to_i, t_date_array[1].to_i,
            t_date_array[2].to_i)
            #expecting two ids per transaction and want to pacakage accordingly
            transactions_on_date = DB[:transactions].where(posted_date: dt.to_date).select(:id, :description).all
            #want the entries for each transaction
            transaction_hash = {posted_date: dt.to_date, transactions: []}
            t = Transaction
            transactions_on_date.each do |t_id|
                transaction_hash[:transactions] << {description: t_id[:description], entries: {}}
                t[t_id[:id]].entries.each do |e|
                    if e.direction == 1
                        #need to divide by 100 to get the amount in dollars
                        transaction_hash[:transactions].last[:entries][:debit] = {account_id: e.account_id, amount: ((e.amount.to_f)/100)}
                    else
                        transaction_hash[:transactions].last[:entries][:credit] = {account_id: e.account_id, amount: ((e.amount.to_f)/100)}
                    end
                end
            end
            transaction_hash
        end
        def calculate_account_balances(net_all = false)
            single_account_balance = lambda do |account|
                if account.entries.empty?
                    return 0
                else
                    balance = account.entries.sum { |entry| (entry.amount * entry.direction) }
                    return balance
                end
            end
            if net_all == true
                #return net balance for all accounts
                net_balance = 0
                Account.each do |account|
                    normal = account.category.normal
                    account_balance = single_account_balance.call(account)
                    net_balance += account_balance# * normal
                end
                #need to account for fact that the amount is stored as an integer not floating point
                net_balance = net_balance/100.0
                return net_balance
            else
                balances = {}
                Account.each do |account|
                    account_balance = single_account_balance.call(account)
                    balances[account.name] = account_balance/100.0
                end
                balances.each do |key, value|
                    if (value < 1 && value > -1)
                        balances[key] = 0.0
                    end
                end
                return balances
            end
        end        
        private :get_paired_accounts, :validate_transfer
    end
end