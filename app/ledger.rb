require 'date'

module FinanceTracker
    RecordResult = Struct.new(:success?, :transfer_ids, :error_message)
  
    class Ledger
        def record(transfer)
            puts "****** Transfer is #{transfer} *****"
            t_date_array = transfer['shared']['posted_date'].split("-")
            dt = DateTime.new(t_date_array[0].to_i, t_date_array[1].to_i,
                t_date_array[2].to_i)
            transfer_id = get_transfer_id(dt)
            record_ids = Hash.new
            begin
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
                    if (record_ids["debit"] || record_ids["credit"] == 0)
                        raise Sequel::Rollback
                    end
                end
            rescue Sequel::Rollback, Sequel::NotNullConstraintViolation, Sequel::DatabaseError => e
                puts "there was an error #{e}"

            end
            puts "^^^^^ db debit is: #{DB[:transfers].where(id: record_ids["debit"]).first} ^^^^^^^^^^^"
            puts "^^^^^^^ ids are: debit-#{record_ids["debit"]}, credit-#{record_ids["debit"]} ^^^^^^^^^^^^^^^^"
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
    end
end