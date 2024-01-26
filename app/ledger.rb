require 'date'

module FinanceTracker
    RecordResult = Struct.new(:success?, :transfer_ids, :error_message)
  
    class Ledger
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
            transfer_id = get_transfer_id(dt)
            record_ids = Hash.new
            DB.transaction do
                transfer_records =  DB[:transfers]
                # for debit side
                record_ids["debit"] = transfer_records.insert(
                    transfer_id: transfer_id,
                    posted_date: dt.to_date,
                    date: DateTime.now.to_date,
                    direction: -1,
                    amount: transfer['shared']['amount'],
                    user_id: transfer['shared']['user_id'],
                    account_id: transfer['debit_account_id'],
                    category_id: transfer['shared']['category_id']
                )
                # for credit side
                record_ids["credit"] = transfer_records.insert(
                    transfer_id: transfer_id,
                    posted_date: dt.to_date,
                    date: DateTime.now.to_date,
                    direction: 1,
                    amount: transfer['shared']['amount'],
                    user_id: transfer['shared']['user_id'],
                    account_id: transfer['credit_account_id'],
                    category_id: transfer['shared']['category_id']
                )
            end
            RecordResult.new(true, {"debit" => record_ids["debit"], "credit" => record_ids["credit"]}, nil)
        end
        def get_transfer_id(dt)
            #first, look for unique transfer_id
            transfer_records =  DB[:transfers]
            transfers_on_same_posted_date = transfer_records.where{posted_date =~ dt.to_date}
            temp_transfer_id = 0
            !transfers_on_same_posted_date.empty? do
                transfers_on_same_posted_date.each do |t|
                    temp_transfer_id > t.transfer_id ? break : temp_transfer_id = t + 1
                end
            end
            temp_transfer_id
        end
        def validate_transfer(transfer)
            # are ids valid?
            is_valid = {"user" => 0, "category" => 0, "debit_account" => 0, "date" => 0,
            "credit_account" => 0, "amount" => 0}
            user_ids = DB[:users].map(:user_id)
            category_ids = DB[:categories].map(:category_id)
            account_ids = DB[:accounts].map(:account_id)
            user_ids.include?(transfer["shared"]["user_id"]) ? is_valid["user"] = 1 : false
            category_ids.include?(transfer["shared"]["category_id"]) ? is_valid["category"] = 1 : false
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
    end
end