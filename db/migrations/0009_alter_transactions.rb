Sequel.migration do
    up do
        alter_table :transactions do
            add_column :refunded, Integer
        end
    end
    down do
        alter_table :transactions do
            drop_column :refunded
        end
    end
end
