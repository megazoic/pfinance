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
        def get_records(table, record_id = nil, parent_id = nil)
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
                        category_name = DB[:categories].where(id: record[:category_id]).first[:name]
                        record[:category_name] = category_name
                        record.delete(:catgeory_id)
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
            elsif table == :categories
                if record_id.nil?
                    #we are getting all records
                    if parent_id.nil?
                        # we need to return all categories as a nested array of hashes
                        output = []
                        records = Category.where(parent_id: nil).all
                        records.each do |record|
                            output << record.return_cats_as_nested_array
                        end
                        return output
                    else
                        #we are getting all descendants of a category
                        records = Category.where(id: parent_id).first.return_descendants
                    end
                else
                    #we are getting a single record
                    records = DB[:categories].where(id: record_id).first
                end
            end
        end
        def get_categories_flat
            records = DB[:categories].all
            records.each do |record|
                record.delete(:parent_id)
            end
        end
        def get_accounts_w_normal(normal)
            accounts = Account.all
            accounts_with_normal = []
            accounts.each do |account|
                if account.category.normal == normal.to_i
                    accounts_with_normal << account.values
                end
            end
            accounts_with_normal
        end
        def get_accounts_w_user_id(id)
            records = DB[:accounts].where(user_id: id).all
        end
    end
end