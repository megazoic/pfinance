Sequel.migration do
    change do
        create_table :users do
            primary_key :id
            String :name, null: false
        end

        create_table :categories do
            primary_key :id
            String :name, null: false
            foreign_key :parent_id, :categories
        end

        create_table :accounts do
            primary_key :id
            String :name, null: false
            String :description
            Integer :normal, null: false
            foreign_key :user_id, :users
            foreign_key :category_id, :categories
        end
        create_table :transfers do
            primary_key :id
            Date :posted_date, null:false 
            Integer :transfer_id, null: false
            Integer :direction, null: false
            Integer :amount, null: false
            Date :date, null: false
            foreign_key :account_id, :accounts, null: false
            foreign_key :user_id, :users, null: false
      end
    end
  end