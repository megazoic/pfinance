Sequel.migration do
  up do
    create_table :categories do
      primary_key :id
      String :name, null: false
      Integer :normal, null: false
      foreign_key :parent_id, :categories
    end
  end
  down do
    drop_table :categories
  end
end
