Sequel.migration do
    up do
        create_table :import_logs do
            Date :date, null: false
            String :record
            String :error
            String :description, null: false
        end
    end
    down do
        drop_table :import_logs
    end
end