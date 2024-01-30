require_relative '../../../app/ledger'

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
            id: result.transfer_ids["debit_record_id"],
            posted_date: Date.iso8601('2024-01-23')
          ), a_hash_including(
            id: result.transfer_ids["credit_record_id"],
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
          expect(result.error_message).to include('Invalid transfer: missing or corrupt data')

          expect(DB[:transfers].count).to eq(0)
        end
      end
    end
    describe '#transfers_on' do
      it 'returns all transfers for the provided date' do
        result_1 = ledger.record(transfer.deep_merge({'shared' => {'posted_date' => '2017-06-10'}}))
        result_2 = ledger.record(transfer.deep_merge({'shared' => {'posted_date' => '2017-06-10'}}))
        result_3 = ledger.record(transfer.deep_merge({'shared' => {'posted_date' => '2017-06-11'}}))
        lt = ledger.transfers_on('2017-06-10')
        test_array = []
        lt.each do |k,v|
          test_array << {:transfer_ids => {"debit_record_id" => v["debit_record_id"], "credit_record_id" => v["credit_record_id"]}}
        end

        expect(test_array).to contain_exactly(
          a_hash_including(transfer_ids: result_1["transfer_ids"]),
          a_hash_including(transfer_ids: result_2["transfer_ids"])
        )
      end

      it 'returns a blank array when there are no matching transfers' do
        expect(ledger.transfers_on('2017-06-10')).to eq({})
      end
    end
  end
end