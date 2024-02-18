Sequel.migration do
    change do
        create_table :unprocessed_records do
            Date :posted_date, null: false
            Date :date, null: false
            Integer :amount, null: false
            Integer :account, null: false
            Integer :normal, null: false
            String :description
        end
    end
end