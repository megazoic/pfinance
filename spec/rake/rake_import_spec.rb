require 'rake'
require 'json'

module FinanceTracker
    RSpec.describe 'Rake import task' do
        it 'successfully loads records in a CSV into DB' do
            load File.expand_path('Rakefile')
            expected_output = "success?: true\nrecords in file: 2\nrecords imported: 2\nerror: "
            expect {Rake::Task['import_records'].invoke('.ignore/cap1_sm.csv')}.to output(expected_output).to_stdout
        end
        it 'loads all records into db table'
    end
end

