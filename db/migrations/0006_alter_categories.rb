Sequel.migration do
  change do
    alter_table(:categories) do
      set_column_not_null :normal
    end
  end
end