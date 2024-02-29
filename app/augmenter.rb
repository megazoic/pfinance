module FinanceTracker
    AugmentResult = Struct.new(:success?, :id, :error_message)
    class Augmenter
        def create(obj_to_record, table)
            id = DB[table.to_sym].insert(obj_to_record)
            AugmentResult.new(true, id, nil)
        end
        def update(obj_to_update, table)
            account_id = obj_to_update[:id]
            obj_to_update.delete(:id)
            DB[table.to_sym].where(id: account_id).update(obj_to_update)
            AugmentResult.new(true, account_id, nil)
        end
        def get_records(table, record_id = nil)
            #records = DB[table.to_sym].all
            if table == :accounts
                if record_id.nil?
                    #we are getting all records
                    records = DB[:accounts].all
                    records.each do |record|
                        if record[:user_id].nil?
                            record[:user_name] = "N/A"
                        else
                            user_name = DB[:users].where(id: record[:user_id]).first[:name]
                            record[:user_name] = user_name
                        end
                    end
                else
                    record = DB[:accounts].where(id: record_id).first
                    if record[:user_id].nil?
                        record[:user_name] = "N/A"
                    else
                        user_name = DB[:users].where(id: record[:user_id]).first[:name]
                        record[:user_name] = user_name
                    end
                    records = [record]
                end
            elsif table == :users
                if record_id.nil?
                    records = DB[:users].all
                else
                    records = DB[:users].where(id: record_id).all
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