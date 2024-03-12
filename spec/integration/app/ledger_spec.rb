require_relative '../../../app/ledger'

module FinanceTracker
  RSpec.describe Ledger, :aggregate_failures, :db do
    before(:example) do
            # set up for testing transfers & unprocessed_records table
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
    describe '#next_unprocessed_record' do
      it 'returns an empty array when there are no unprocessed records' do
        expect(ledger.next_unprocessed_record).to eq([])
      end
      context 'with unprocessed records' do
        let(:record_importer) { RecordImporter.new }
        let(:record_to_import1) do
          {
              'account'=> ENV['PFINANCE_LIABILITY_1'],
              'amount' => 1400,
              'description' => 'BLAHBLAH|Merchandise',
              'posted_date' => '2024-01-25',
              'direction' => "-1",
              'date' => '2024-03-09'
          }
        end
        let(:record_to_import2) do 
          {
              'account' => ENV['PFINANCE_LIABILITY_1'],
              'amount' => 1600,
              'description' => "#{ENV['BANK1']} CRDT CD  ONLINE PMT",
              'posted_date' => '2024-02-13',
              'direction' => "1",
              'date' => '2024-03-09'
          }
        end
        let(:record_to_import3) do
          {
            'account' => ENV['PFINANCE_LIABILITY_1'],
            #'account' => ENV['PFINANCE_ASSET_1'],
            'amount' => 1600,
            'description' => 'BLAHBLAH|Merchandise',
            #'description' => 'TERMINAL CNP TX                     VENMO*BLAH BLAH NEW YORK NY|',
            #'description' => "POS PCH CSH BACK  TERMINAL 99999999 BLAHBLAH",
            'posted_date' => '2024-02-13',
            'direction' => "1",
            'date' => '2024-03-09'
          }
        end
        let(:record_to_import4) do
          {
            'account' => ENV['PFINANCE_ASSET_1'],
            'amount' => 1600,
            #'description' => "#{ENV['BANK1']} CRDT CD  ONLINE PMT        20245111|",
            'description' => "BLAH #{ENV['WORK_REIMBURSE']}      BLAH*VV*13456895-1-V1334300345-1*BU000.00*00.00\|",
            'posted_date' => '2024-02-13',
            'direction' => "-1",
            'date' => '2024-03-09'
          }
        end
        let(:record_to_import5) do
          {
            'account' => ENV['PFINANCE_LIABILITY_1'],
            'amount' => 1600,
            'description' => 'ELECTRONIC PAYMENT|Payment/Credit',
            'posted_date' => '2024-02-13',
            'direction' => "1",
            'date' => '2024-03-09'
          }
        end
        let(:record_to_import6) do
          {
            'account' => ENV['PFINANCE_ASSET_1'],
            'amount' => 1600,
            'description' => "BLAH BLAH 310      #{ENV['SALARY']}         23440122|",
            'posted_date' => '2024-02-13',
            'direction' => "-1",
            'date' => '2024-03-09'
          }
        end
        it 'returns the next unprocessed record' do
          result1 = record_importer.import_record(record_to_import1)
          expect(result1).to be_success
          result2 = record_importer.import_record(record_to_import2)
          expect(result2).to be_success
          result = ledger.next_unprocessed_record
          result = result.transform_keys(&:to_s)
          result.reject! { |k,v| ['account_id', 'paired_accounts', 'posted_date', 'date',
            'description', 'direction', 'id'].include?(k) }
          expect(result).to include({
            'account_name' => Account::RWA_2_ACCOUNT[ENV['PFINANCE_LIABILITY_1']],
            'amount' => 140000
          })
        end
        it 'returns Expense as paired_accounts' do
          result3 = record_importer.import_record(record_to_import3)
          expect(result3).to be_success
          result = ledger.next_unprocessed_record
          result = result.transform_keys(&:to_s)
          paired_accounts = result['paired_accounts']
          expect(paired_accounts).to include({ 4 => "Expense_1", 5 => "Expense_2" })
        end
        it 'returns Liabilities as paired_accounts' do
          result4 = record_importer.import_record(record_to_import4)
          expect(result4).to be_success
          result = ledger.next_unprocessed_record
          result = result.transform_keys(&:to_s)
          paired_accounts = result['paired_accounts']
          expect(paired_accounts).to include({ 1 => "Liability_1", 2 => "Liability_2" })
        end
        it 'returns Assets as paired_accounts' do
          result5 = record_importer.import_record(record_to_import5)
          expect(result5).to be_success
          result = ledger.next_unprocessed_record
          result = result.transform_keys(&:to_s)
          paired_accounts = result['paired_accounts']
          expect(paired_accounts).to include({ 3 => "Asset_1" })
        end
        it 'returns Revenue as paired_accounts' do
          result6 = record_importer.import_record(record_to_import6)
          expect(result6).to be_success
          result = ledger.next_unprocessed_record
          result = result.transform_keys(&:to_s)
          paired_accounts = result['paired_accounts']
          expect(paired_accounts).to include({ 6 => "Revenue_1"})
        end
      end
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