Sequel.migration do
    up do
      alter_table(:transactions) do
        add_foreign_key :todo_id, :todos
      end
    end
    down do
      alter_table(:transactions) do
        drop_foreign_key :todo_id
      end
    end
  end