Sequel.migration do
    change do
        alter_table :categories do
            add_unique_constraint :name
        end
        alter_table :accounts do
            set_column_not_null :category_id
        end
    end
end