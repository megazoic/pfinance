module FinanceTracker
    AugmentResult = Struct.new(:success?, :id, :error_message)
    class Augmenter
        def create(obj_to_record, table)
            id = DB[table.to_sym].insert(obj_to_record)
            AugmentResult.new(true, id, nil)
        end
        def update(obj_to_record, table, id)
            DB[table.to_sym].where(id: id).update(obj_to_record)
            AugmentResult.new(true, id, nil)
        end
        def get_records(table)
            records = DB[table.to_sym].all
            if table == :accounts
                records.each do |record|
                    user = DB[:users].where(id: record[:user_id]).first
                    record[:user_name] = user[:name]
                end
            end
        end
        def get_accounts_w_normal(normal)
            records = DB[:accounts].where(normal: normal).all
        end
        def get_accounts_w_user_id(id)
            records = DB[:accounts].where(user_id: id).all
        end
    end
end