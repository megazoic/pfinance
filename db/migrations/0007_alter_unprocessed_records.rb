Sequel.migration do
    up do
        alter_table(:unprocessed_records) do
            add_primary_key :id
            drop_column :normal
            add_column :direction, Integer, null: false
            drop_column :account
            add_column :account, String, null: false
            add_column :refund, Integer, null: false, default: 0
            add_column :skip, Integer, null: false, default: 0
        end
    end
    down do
        alter_table(:unprocessed_records) do
            drop_column :id
            add_column :normal, Integer, null: false
            drop_column :direction
            drop_column :account
            add_column :account, Integer, null: false
            drop_column :refund
            drop_column :skip
        end
    end
end