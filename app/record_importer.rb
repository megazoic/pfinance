require_relative '../config/sequel'

module FinanceTracker
    ImportResult = Struct.new(:success?, :import_id, :error_message)
    RakeResult = Struct.new(:success?, :records_in_file, :records_imported, :error_message)
    class RecordImporter
        def import_record(record_to_import)
            #puts "record to import is #{record_to_import}"
            # validate data
            validated = validate_record(record_to_import)
            unless validated
                message = 'Invalid record to import: missing or corrupt data'
                return ImportResult.new(false, nil, message)
            end
            imported_records =  DB[:unprocessed_records]
            record_id = imported_records.insert(
                account: record_to_import["account"].to_i,
                posted_date: Date.iso8601(record_to_import["posted_date"]),
                date: Date.today,
                amount: (record_to_import["amount"].to_i * 100),
                description: record_to_import["description"],
                normal: record_to_import["normal"].to_i
            )
            ImportResult.new(true, record_id, nil)
        end
        def validate_record(record_to_import)
            is_valid = {"account" => 0, "amount" => 0, "posted_date" => 0,
            "description" => 0, "normal" => 0}
            ["6723", "3065", "0855"].include?(record_to_import["account"]) ? is_valid["account"] = 1 : false
            record_to_import["amount"].to_i > 0 ? is_valid["amount"] = 1 : false
            begin
                Date.iso8601(record_to_import["posted_date"]).is_a?(Date) == true ? is_valid["posted_date"] = 1 : false
            rescue
                is_valid["posted_date"] = false
            end
            ["-1", "1"].include?(record_to_import["normal"]) ? is_valid["normal"] = 1 : false
            record_to_import["description"] != "" ? is_valid["description"] = 1 : false
            # test if any keys still have a false value
            !is_valid.value?(0)  
        end
        def log_error(erroneous_record, error, error_count)
            import_logs =  DB[:import_logs]
            if error_count > 1
              import_logs.insert(
                date: Date.today,
                record: erroneous_record,
                error: error,
                description: "exceeded two errors, processing halted"
              )
            else
              import_logs.insert(
                date: Date.today,
                record: erroneous_record,
                error: error,
                description: "error could be incorrect account number"
              )
            end
        end
        def log_import_results(description)
            import_logs =  DB[:import_logs]
            import_logs.insert(
                date: Date.today,
                description: description
            )
        end      
    end
end