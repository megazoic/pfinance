require_relative './app/record_importer.rb'
require 'logger'
require 'json'
require 'csv'
require 'sequel'
require 'rake'
require './.ignore/sensitive.rb'
require './app/models/account'

namespace :db do
    # Ensure DB is declared
    migrate = lambda do |version|
      Sequel.extension :migration
      DB.loggers << Logger.new($stdout) if DB.loggers.empty?
      Sequel::Migrator.run(DB, "db/migrations", target: version)
    end
  
    task :migrate do
      migrate.call(nil)
    end
  
    task :rollback do
      latest = DB[:schema_info].select_map(:version).first
      migrate.call(latest - 1)
    end
  
    task :reset do
      migrate.call(0)
      Sequel::Migrator.run(DB, "db/migrations")
    end
    task :rollback_all do
      migrate.call(0)
      Sequel::Migrator.run(DB, "db/migrations", target: 0)
      #migrate.call(0)
    end
end
task :load_dev_db do
  DB[:accounts].truncate(cascade: true)
  DB[:categories].truncate(cascade: true)
  DB[:users].truncate(cascade: true)
  DB[:users].insert(id: 1, name: "Nick")
  DB[:categories].insert(id: 1, name: "Revenue", normal: -1)
  DB[:categories].insert(id: 2, name: "Assets", normal: 1)
  DB[:categories].insert(id: 3, name: "Expense", normal: 1)
  DB[:categories].insert(id: 4, name: "Liabilities", normal: -1)
  DB[:categories].insert(id: 5, name: "CreditCard", normal: -1, parent_id: 4)
  DB[:categories].insert(id: 6, name: "DiscretionarySpending", normal: 1, parent_id: 3)
  DB[:categories].insert(id: 7, name: "Checking", normal: 1, parent_id: 2)
  DB[:categories].insert(id: 8, name: "NonDiscSpending", normal: 1, parent_id: 3)
  DB[:accounts].insert(id: 1, name: "Liability_1", category_id: 5)
  DB[:accounts].insert(id: 2, name: "Liability_2", category_id: 5)
  DB[:accounts].insert(id: 3, name: "Asset_1", category_id: 7)
  DB[:accounts].insert(id: 4, name: "Expense_1", category_id: 6)
  DB[:accounts].insert(id: 5, name: "Expense_2", category_id: 8)
  DB[:accounts].insert(id: 6, name: "Revenue_1", category_id: 1)
end

task :import_records, [:arg1] do |t, args|
  table = CSV.parse(File.read(args[:arg1]), headers: true)
  record_hash = {'account' => 0, 'amount' => 0, 'description' => 0, 'direction' => 0, 'posted_date' => 0}
  rake_result= FinanceTracker::RakeResult.new(false, table.length, 0, nil)
  error_count = 0
  account_header = ""
  posted_date = ""
  aux_header = ""
  terminate_import = false
  ri = FinanceTracker::RecordImporter.new
  #from RecordImporter::import_record ImportResult = Struct.new(:success?, :import_id, :error_message)

  if table.headers.include?('Card No.')
    account_header = 'Card No.'
    posted_date =  'Posted Date'
    aux_header = 'Category'
  else
    account_header = 'Account Number'
    posted_date =  'Post Date'
    aux_header = 'Check'
  end

  table.each do |data|
    real_world_accounts = Account::RWA
    record_hash['account'] = data[account_header][-4..-1]
    #test to see if account number is included in real_world_accounts
    found_account = false
    real_world_accounts.each do |key, value|
      if value.include?(record_hash['account'])
        found_account = true
        break
      end
    end
    if found_account == false
      terminate_import = true
    end
    if !data['Debit'].nil?
      #will need to increase balance of credit card account and expenses account
      #assign a direction that is opposite of what is listed in the csv
      #bc the csv is from the perspective of the bank/credit card company
      record_hash['amount'] = data['Debit']
=begin
      if real_world_accounts['liabilities'].include?(record_hash['account'])
        record_hash['direction'] = "1"
      else
        record_hash['direction'] = "-1"
      end
=end
      # since bringing into personal finance app, the direction needs to be opposite of what is in the csv
      record_hash['direction'] = "-1"
    else
      record_hash['amount'] = data['Credit']
=begin
      if real_world_accounts['liabilities'].include?(record_hash['account'])
        record_hash['direction'] = "-1"
      else
        record_hash['direction'] = "1"
      end
=end
      record_hash['direction'] = "1"
    end
    record_hash['description'] = "#{data['Description']}|#{data[aux_header]}"
    if posted_date == 'Post Date'
      new_date = Date.strptime(data[posted_date], '%m/%d/%Y')
      record_hash['posted_date'] = "#{new_date.to_s}"
    else
      record_hash['posted_date'] = data[posted_date]
    end
    #import
    result = ri.import_record(record_hash)
    #test for result.success to see if record was loaded into db
    if result.success? == true
      rake_result[:success?] = true
      rake_result[:records_imported] += 1
    else
      error_count += 1
      if error_count > 1
        terminate_import = true
      end
      record_to_report = "#{data[account_header]}|#{data[posted_date]}|#{data['Description']}"
      ri.log_error(record_to_report, result.error_message, error_count)
      rake_result[:error_message] = result.error_message
      if terminate_import == true
        break
      end
    end
  end
  ir = "success?: #{rake_result[:success?]}\nrecords in file: #{rake_result[:records_in_file]}\nrecords imported: #{rake_result[:records_imported]}\nerror: #{rake_result[:error_message]}"
  ri.log_import_results(ir)
  print ir
end
