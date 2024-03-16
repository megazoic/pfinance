Sequel.migration do
  up do
    create_table :entries do
      primary_key :id
      foreign_key :transaction_id, :transactions, null: false
      foreign_key :account_id, :accounts, null: false
      Integer :direction, null: false
      Integer :amount, null: false
    end
  end
  down do
    drop_table :entries
  end
end
