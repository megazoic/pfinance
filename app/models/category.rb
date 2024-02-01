
class Category < Sequel::Model
=begin
    plugin :rcte_tree
    one_to_many :transfers
    many_to_one :category, class: self
    one_to_many :children, key: :parent_id, class: self
=end
    many_to_many :parents, class: :Category, join_table: :hierarchy, left_key: :child_id,  right_key: :parent_id
    many_to_many :children, class: :Category, join_table: :hierarchy, left_key: :parent_id, right_key: :child_id
end