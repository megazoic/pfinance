class Todo < Sequel::Model
    many_to_one :user
    one_to_many :todo_transactions
    many_to_many :transactions, join_table: :todo_transactions
    many_to_many :related_todos, 
                 class: :Todo, 
                 left_key: :todo_id, 
                 right_key: :related_todo_id, 
                 join_table: :todo_relations
end