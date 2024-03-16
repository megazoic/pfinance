Sequel.migration do
  up do
    create_table :transactions do
      primary_key :id
      Date :posted_date, null: false
      String :description
      String :notes
      foreign_key :user_id, :users
    end
  end
  down do
    drop_table :transactions
  end
end
