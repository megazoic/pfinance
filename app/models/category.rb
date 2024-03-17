
class Category < Sequel::Model
    many_to_one :parent, class: self
    one_to_many :children, key: :parent_id, class: self
    one_to_many :accounts
    def return_ancestors
        ancestors = []
        current = self
        while current.parent
            current = current.parent
            ancestors << current
        end
        ancestors
    end
    def cats_w_accounts_to_hash
        {
          id: id,
          name: name,
          accounts: accounts.map(&:values),
          children: children.map(&:cats_w_accounts_to_hash)
        }
    end
    def has_descendants?
        !self.children.empty?
    end
    def return_descendants
        #return all descendants of a category as a hash with keys {id, name}
        descendants = []
        if self.children && self.children.length > 0
            self.children.each do |child|
                descendants << child.values
                descendants << child.return_descendants
            end
        end
        descendants.flatten(1)
    end
    def get_cats_as_nested_array(incl_accounts = false)
        cats_w_accounts = []
        if incl_accounts
            #return all categories with their accounts as a nested array of hashes
            root_cats = Category.where(parent_id: nil)
            trees = root_cats.map(&:cats_w_accounts_to_hash)
            trees
        else
            #return all categories as a nested array of hashes without their accounts
            Category.where(parent_id: nil).each do |cat|
                cats_w_accounts << cat.values
            end
        end
=begin
        if single_cat
            #return all categories with their accounts as a nested array of hashes
            Category.where(parent_id: nil).each do |cat|
                cats_w_accounts << cat.cats_w_accounts_to_hash
            end
        else
            if cat_id.nil?
                #we are getting all categories with their accounts

            else
                #only return the single category with its accounts
                cat = DB[:categories].where(id: cat_id).first
                cats_w_accounts << cat.cats_w_accounts_to_hash
            end
        end
        cats_w_accounts
=end
=begin
        cats = []
        cats << self.values.delete_if { |k, v| k == :parent_id }
        if self.children && self.children.length > 0
            self.children.each do |child|
                cats << child.get_cats_as_nested_array
            end
        end
        cats
=end
    end
end