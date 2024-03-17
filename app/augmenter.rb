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
        def get_user_records(user_id = nil)
            if user_id.nil?
                records = DB[:users].all
            else
                records = DB[:users].where(id: user_id).all
            end
        end
        def get_account_records(account_id = nil)
            if account_id.nil?
                #we are getting all accounts
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
                    record.delete(:category_id)
                end
            else
                #we are getting a single account
                record = DB[:accounts].where(id: account_id).first
                if record[:user_id].nil?
                    record[:user_name] = "N/A"
                else
                    user_name = DB[:users].where(id: record[:user_id]).first[:name]
                    record[:user_name] = user_name
                end
                records = [record]
            end
        end
        def get_category_records(category_id = nil, as_hierarchy = false, incl_accounts = false)
            output = []
            if category_id.nil?
                #we are getting all categories
                if as_hierarchy
                    #we are getting all categories and their descendants in hierarchial format
                    if incl_accounts
                        #we are including accounts
                        c = Category.new
                        output = c.get_cats_as_nested_array(true)
=begin
                        records = Category.where(parent_id: nil).all
                        records.each do |record|
                            output << record.cats_w_accounts_to_hash
                        end
=end
                    else
                        #we are not including accounts

                    end
                else
                    #we are getting all categories as a flat array of hashes and going to ignore incl_accounts
                    records = DB[:categories].all
                    records.each do |record|
                        output << record
                    end
                end
            else
                #we are getting a single category as_hierarchy does not apply
                if incl_accounts
                    #we are including accounts
                    cat = DB[:categories].where(id: category_id).first
                    cat[:accounts] = DB[:accounts].where(category_id: category_id).all
                    output << cat
                else
                    #we are not including accounts just getting the category
                    cat = DB[:categories].where(id: category_id).first
                    output << cat
                end
            end
            output
=begin
            if category_id.nil?
                #we are getting all categories
                if parent_id.nil?
                    # we need to return all categories as a nested array of hashes
                    output = []
                    records = Category.where(parent_id: nil).all
                    records.each do |record|
                        output << record.get_cats_as_nested_array
                    end
                    if get_accounts
                        #we need to add account name and id to the category if there are any accounts with that cateogry_id
                        accounts = Account.all
                        accounts.each do |account|
                            output.each do |category|
                                if account.category_id == category[:id]
                                    category[:accounts] = [] if category[:accounts].nil?
                                    category[:accounts] << {name: account.name, id: account.id}
                                end
                            end
                        end
                    end
                    return output
                else
                    #we are getting all descendants of a category
                    records = Category.where(id: parent_id).first.return_descendants
                end
            else
                #we are getting a single category
                if get_accounts
                    #we need to add account name and id to the category if there are any accounts with that cateogry_id
                    output = Category.where(id: category_id).first.get_cats_as_nested_array(category_id, true)
                    return output
                else
                    #we are getting a single category and no accounts
                    records = Category.where(id: category_id).first
                    return records
                end
            end
=end
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