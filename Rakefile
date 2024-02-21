require_relative './app/record_importer.rb'
require 'logger'
require 'json'
require 'csv'
=begin
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
=end
task :import_records, [:arg1] do |t, args|
  RakeResult = Struct.new(:success?, :records_in_file, :records_imported, :error_message)
  table = CSV.parse(File.read(args[:arg1]), headers: true)
  record_hash = {'account' => 0, 'amount' => 0, 'description' => 0, 'normal' => 0, 'posted_date' => 0}
  rr = RakeResult.new(false, table.length, 0, nil)
  if table.headers.include?('Card No.')
    table.each do |data|
      record_hash['account'] = data['Card No.']
      if data['Debit'] != ""
        record_hash['amount'] = data['Debit']
        record_hash['normal'] = "-1"
      else
        record_hash['amount'] = data['Credit']
        record_hash['normal'] = "1"
      end
      record_hash['description'] = "#{data['Description']}|#{data['Category']}"
      record_hash['posted_date'] = data['Posted Date']
      #import
      ri = FinanceTracker::RecordImporter.new
      #from RecordImporter::import_record ImportResult = Struct.new(:success?, :import_id, :error_message)
      result = ri.import_record(record_hash)
      #test for result.success to see if record was loaded into db
      if result.success? == true
        rr[:success?] = true
        rr[:records_imported] += 1
      else
        rr[:error_message] = result.error_message
        break
      end
    end
  else
  end
  ir = "success?: #{rr[:success?]}\nrecords in file: #{rr[:records_in_file]}\nrecords imported: #{rr[:records_imported]}\nerror: #{rr[:error_message]}"
  print ir
end
