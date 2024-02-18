require_relative '../config/sequel'

module FinanceTracker
    class RecordImporter
        def import_record(record_to_import)
            puts "record to import is #{record_to_import}"
        end
    end
end