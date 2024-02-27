RSpec.configure do |c|
    c.before(:suite) do
        # migrates all tables
        Sequel.extension :migration
        Sequel::Migrator.run(DB, 'db/migrations')
        # empties the tables
        DB[:transfers, :accounts, :users, :categories, :unprocessed_records,
            :import_logs].truncate(cascade: true)
    end
    c.around(:example, :db) do |example|
        DB.transaction(rollback: :always) { example.run }
    end    
end