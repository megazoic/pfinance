Sequel.migration do
    up do
        alter_table(:unprocessed_records) do
            add_primary_key :id
            drop_column :normal
            add_column :direction, Integer, null: false
            set_column_type :account, String
        end
    end
    down do
        alter_table(:unprocessed_records) do
            drop_column :id
            add_column :normal, Integer, null: false
            drop_column :direction
            set_column_type :account, Integer
        end
    end
end