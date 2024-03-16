Sequel.migration do
  up do
    create_table :accounts do
      primary_key :id
      String :name, null: false
      String :description
      foreign_key :user_id, :users
      foreign_key :category_id, :categories
    end
  end
  down do
    drop_table :accounts
  end
end
