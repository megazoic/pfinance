module FinanceTracker
    AugmentResult = Struct.new(:success?, :id, :error_message)
    class Augmenter
        def record(obj_to_record)
            #will want to make this generic to accounts, categories, users
            id = DB[:accounts].insert(obj_to_record)
            AugmentResult.new(true, id, nil)
        end
    end
end