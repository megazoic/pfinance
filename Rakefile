require_relative './app/record_importer.rb'
require 'logger'
require 'json'
require 'csv'

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
end


task :import_records, [:arg1] do |t, args|
  table = CSV.parse(File.read(args[:arg1]), headers: true)
  record_hash = {'account' => 0, 'amount' => 0, 'description' => 0, 'normal' => 0, 'posted_date' => 0}
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
    record_hash['account'] = data[account_header][-4..-1]
    if data['Debit'] != ""
      record_hash['amount'] = data['Debit']
      record_hash['normal'] = "-1"
    else
      record_hash['amount'] = data['Credit']
      record_hash['normal'] = "1"
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
