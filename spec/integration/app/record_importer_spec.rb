# from https://edgibbs.com/2020/02/9/more-testable-rake-tasks/
require_relative '../../../app/record_importer.rb'
require_relative '../../../config/sequel'
require_relative '../../support/db'

module FinanceTracker
    RSpec.describe RecordImporter, :aggregate_failures do
        let(:record_importer) { RecordImporter.new }
        let(:record_to_import) do
          {
              'date' => '2024-02-11',
              'account' => 1234,
              'amount' => 1400,
              'normal' => -1,
              'description' => 'some cost',
              'posted_date' => '2024-02-10' 
          }
        end
        describe '#import' do
          context 'with a valid record' do
              it 'successfully saves the record in the db' do
                  result = record_importer.import_record(record_to_import)
                  expect(result).to be_success
                  expect(DB[:unprocessed_records].all).to match [a_hash_including(
                      id: result.id,
                      description: 'some cost'
                  )]
              end
          end
        end
  end      
end