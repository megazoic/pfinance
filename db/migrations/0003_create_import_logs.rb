Sequel.migration do
    change do
        create_table :import_logs do
            Date :date, null: false
            String :record
            String :error
            String :description, null: false
        end
    end
end