require_relative '../../../app/ledger'
require_relative '../../../config/sequel'
require_relative '../../support/db'

module FinanceTracker
  RSpec.describe Ledger do
    let(:ledger) { Ledger.new }
    let(:transfer) do
      {
        'shared' => {
          'posted_date' => '2024-01-23',
          'amount' => 14000,
          'user_id' => 1,
          'category_id' => 1
        }, 'debit' => {
          'account_id' => 1
        }, 'credit' => {
          'account_id' => 2,
        }
      }
    end

    describe '#record' do
      context 'with a valid transfer' do
        it 'successfully saves the transfer in the DB', :aggregate_failures do
          result = ledger.record(transfer)

          expect(result).to be_success
          expect(DB[:transfers].select(:id, :posted_date).all).to match [a_hash_including(
            id: result.transfer_ids["debit"],
            posted_date: Date.iso8601('2024-01-23')
          ), a_hash_including(
            id: result.transfer_ids["credit"],
            posted_date: Date.iso8601('2024-01-23')
          )]
        end
      end

    end
  end
end