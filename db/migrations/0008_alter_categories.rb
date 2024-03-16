Sequel.migration do
    up do
        alter_table :categories do
            add_unique_constraint :name
        end
        alter_table :accounts do
            set_column_not_null :category_id
        end
    end
    down do
        alter_table :categories do
            drop_constraint(:categories_name_key)
        end
        alter_table :accounts do
            set_column_allow_null :category_id
        end
    end
end