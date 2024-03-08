Sequel.migration do
    change do
        alter_table(:unprocessed_records) do
            add_primary_key :id
            drop_column :normal
            add_column :direction, Integer, null: false
        end
    end
end