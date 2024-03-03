
class Category < Sequel::Model
    many_to_one :parent, class: self
    one_to_many :children, key: :parent_id, class: self
    def return_ancestors
        ancestors = []
        current = self
        while current.parent
            current = current.parent
            ancestors << current
        end
        ancestors
    end
    def return_descendants
        #return all descendants of a category as a hash with keys {id, name}
        descendants = []
        current = self
        while current.children && current.children.length > 0
            current = Category.where(id: current.children[0].id).first
            current.values.reject! { |k, v| k == :parent_id }
            descendants << current.values
        end
        descendants
    end
    def return_cats_as_nested_array
        #return all categories as a nested array of hashes
        cats = []
        cats << self.values.delete_if { |k, v| k == :parent_id }
        if self.children && self.children.length > 0
            self.children.each do |child|
                cats << child.return_cats_as_nested_array
            end
        end
        cats
    end
end