require_relative '../../../app/ledger'
require_relative '../../../config/sequel'

module FinanceTracker
  RSpec.describe Ledger, :aggregate_failures, :db do
    let(:ledger) { Ledger.new }
    let(:transfer) do
      {
        'shared' => {
          'posted_date' => '2024-01-23',
          'amount' => 14000,
          'user_id' => 1,
          'category_id' => 1
        },
        'debit_account_id' => 1,
        'credit_account_id' => 2
      }
    end

    describe '#record' do
      context 'with a valid transfer' do
        it 'successfully saves the transfer in the DB' do
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
      context 'when the transfer lacks an account_id' do
        it 'rejects the tranfer as invalid' do
          transfer.delete('debit_account_id')

          result = ledger.record(transfer)

          expect(result).not_to be_success
          expect(result.transfer_ids).to eq(nil)
          expect(result.error_message).to include('`payee` is required')

          expect(DB[:transfers].count).to eq(0)
        end
      end
    end
  end
end