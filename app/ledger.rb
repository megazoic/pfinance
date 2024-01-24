module FinanceTracker
    RecordResult = Struct.new(:success?, :transfer_id, :error_message)
  
    class Ledger
        def record(tranfer)
        end
    end
end