RSpec.configure do |c|
    c.before(:suite) do
        # migrates all tables
        Sequel.extension :migration
        Sequel::Migrator.run(DB, 'db/migrations')
        # empties the tables
        DB[:transfers, :accounts, :users, :categories].truncate(cascade: true)
        # set up for testing transfers table
        DB[:users].insert(id: 1, name: "Nick")
        DB[:accounts].insert(id: 1, name: "House", normal: 1)
        DB[:accounts].insert(id: 2, name: "Vacation", normal: 1)
        DB[:categories].insert(id: 1, name: "Discretionary")
    end
    c.around(:example, :db) do |example|
        DB.transaction(rollback: :always) { example.run }
    end    
end