Sequel.migration do
    change do
        alter_table :accounts do
            drop_column :normal
        end
        alter_table :categories do
            add_column :normal, Integer, not_null: true
        end
    end
end