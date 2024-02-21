require_relative '../../../app/record_importer.rb'
require_relative '../../../config/sequel'
require_relative '../../support/db'

module FinanceTracker
    RSpec.describe RecordImporter, :aggregate_failures, :db do
        let(:record_importer) { RecordImporter.new }
        let(:record_to_import) do
          {
              'account' => "3065",
              'amount' => "1400",
              'normal' => "-1",
              'description' => 'some cost',
              'posted_date' => '2024-02-10' 
          }
        end
        describe '#import' do
          context 'with a valid record' do
              it 'successfully saves the record in the db' do
                  result = record_importer.import_record(record_to_import)
                  expect(result).to be_success
                  expect(DB[:unprocessed_records].select(:posted_date).all).to match [a_hash_including(
                      posted_date: Date.iso8601('2024-02-10')
                  )]
              end
          end
          context 'when the record lacks an account' do
            it 'rejects the record as invalid' do
              record_to_import.delete('account')
              result = record_importer.import_record(record_to_import)
              expect(result).not_to be_success
              expect(result.error_message).to include('missing or corrupt data')
              expect(DB[:unprocessed_records].count).to eq(0)
            end
          end
        end
  end      
end