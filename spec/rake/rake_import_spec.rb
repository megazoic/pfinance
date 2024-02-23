require 'rake'
require 'json'

module FinanceTracker
    RSpec.describe 'Rake import task' do
        before do
            load File.expand_path('Rakefile')
        end
        it 'successfully loads records in a CSV into DB' do
            expected_output = "success?: true\nrecords in file: 4\nrecords imported: 4\nerror: "
            expect {Rake::Task['import_records'].invoke('.ignore/ump_sm.csv')}.to output(expected_output).to_stdout
        end
=begin
        context 'when data cannot be imported' do
            let :run_rake_task do
                Rake::Task['import_records'].reenable
                #Rake.application.invoke_task 'import_records'
            end
            it 'records a log record on first failure' do
                #expected_output = "success?: false\nrecords in file: 4\nrecords imported: 3\nerror: Invalid record to import: missing or corrupt data"
                expected_output = "rake aborted!
                Date::Error: invalid date (Date::Error)"
                run_rake_task
                expect {Rake::Task['import_records'].invoke('.ignore/ump_sm_corrupt1.csv')}.to output(expected_output).to_stdout
            end
            it 'logs failure with a description and stops after second bad record' do
                run_rake_task
                expected_output = "success?: false\nrecords in file: 4\nrecords imported: 2\nerror: Invalid record to import: missing or corrupt data"
                expect {Rake::Task['import_records'].invoke('.ignore/ump_sm_corrupt2.csv')}.to output(expected_output).to_stdout
            end
        end
=end
    end
end

