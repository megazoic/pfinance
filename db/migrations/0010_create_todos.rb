Sequel.migration do
    up do
      create_table(:todos) do
        primary_key :id
        Date :date, null: false
        TrueClass :completed, default: false
        String :description, text: true
      end
  
      create_table(:todo_transactions) do
        foreign_key :todo_id, :todos
        foreign_key :transaction_id, :transactions
        primary_key [:todo_id, :transaction_id]
      end
  
      create_table(:todo_relations) do
        foreign_key :todo_id, :todos
        foreign_key :related_todo_id, :todos
        primary_key [:todo_id, :related_todo_id]
      end
    end
  
    down do
      drop_table(:todo_relations)
      drop_table(:todo_transactions)
      drop_table(:todos)
    end
  end
