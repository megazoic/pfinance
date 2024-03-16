Sequel.migration do
    up do
        create_table :unprocessed_records do
            primary_key :id
            Date :posted_date, null: false
            Date :date, null: false
            Integer :amount, null: false
            String :account, null: false
            Integer :direction, null: false
            Integer :refund, null: false, default: 0
            Integer :skip, null: false, default: 0
            String :description
        end
    end
    down do
        drop_table :unprocessed_records
    end
end