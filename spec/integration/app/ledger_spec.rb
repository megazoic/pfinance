require_relative '../../../app/ledger'

module FinanceTracker
  RSpec.describe Ledger, :aggregate_failures, :db do
    before(:example) do
            # set up for testing transfers & unprocessed_records table
            DB[:users].insert(id: 1, name: "Nick")
            DB[:users].insert(id: 2, name: "Sally")
            DB[:categories].insert(id: 1, name: "Revenue", normal: -1)
            DB[:categories].insert(id: 2, name: "Assets", normal: 1)
            DB[:categories].insert(id: 3, name: "Expense", normal: 1)
            DB[:categories].insert(id: 4, name: "Liabilities", normal: -1)
            DB[:categories].insert(id: 5, name: "CreditCard", normal: -1, parent_id: 4)
            DB[:categories].insert(id: 6, name: "DiscretionarySpending", normal: 1, parent_id: 3)
            DB[:categories].insert(id: 7, name: "Checking", normal: 1, parent_id: 2)
            DB[:categories].insert(id: 8, name: "NonDiscSpending", normal: 1, parent_id: 3)
            DB[:categories].insert(id: 9, name: "Equity", normal: -1)
            DB[:accounts].insert(id: 1, name: "Liability_1", category_id: 5)
            DB[:accounts].insert(id: 2, name: "Liability_2", category_id: 5)
            DB[:accounts].insert(id: 3, name: "Asset_1", category_id: 7)
            DB[:accounts].insert(id: 4, name: "Expense_1", category_id: 6)
            DB[:accounts].insert(id: 5, name: "Expense_2", category_id: 8)
            DB[:accounts].insert(id: 6, name: "Revenue_1", category_id: 1)
            DB[:accounts].insert(id: 7, name: "Equity_1", category_id: 9)
    end

    let(:ledger) { Ledger.new }
    let(:transfer) do
      {
        'shared' => {
          'posted_date' => '2024-01-23',
          'amount' => 14000,
          'user_id' => 1,
          'category_id' => 1,
          'description' => 'BLAHBLAH|Merchandise',
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
              'direction' => "1",
              'date' => '2024-03-09',
              'skip' => 0,
              'refund' => 0
          }
        end
        let(:record_to_import2) do 
          {
              'account' => ENV['PFINANCE_LIABILITY_1'],
              'amount' => 1600,
              'description' => "#{ENV['BANK1']} CRDT CD  ONLINE PMT",
              'posted_date' => '2024-02-13',
              'direction' => "-1",
              'date' => '2024-03-09',
              'skip' => 0,
              'refund' => 0
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
            'direction' => "-1",
            'date' => '2024-03-09',
            'skip' => 0,
            'refund' => 0
          }
        end
        let(:record_to_import4) do
          {
            'account' => ENV['PFINANCE_ASSET_1'],
            'amount' => 1600,
            #'description' => "#{ENV['BANK1']} CRDT CD  ONLINE PMT        20245111|",
            'description' => "BLAH #{ENV['WORK_REIMBURSE']}      BLAH*VV*13456895-1-V1334300345-1*BU000.00*00.00\|",
            'posted_date' => '2024-02-13',
            'direction' => "1",
            'date' => '2024-03-09',
            'skip' => 0,
            'refund' => 0
          }
        end
        let(:record_to_import5) do
          {
            'account' => ENV['PFINANCE_LIABILITY_1'],
            'amount' => 1600,
            'description' => 'ELECTRONIC PAYMENT|Payment/Credit',
            'posted_date' => '2024-02-13',
            'direction' => "1",
            'date' => '2024-03-09',
            'skip' => 0,
            'refund' => 0
          }
        end
        let(:record_to_import6) do
          {
            'account' => ENV['PFINANCE_ASSET_1'],
            'amount' => 1600,
            'description' => "BLAH BLAH 310      #{ENV['SALARY']}         23440122|",
            'posted_date' => '2024-02-13',
            'direction' => "1",
            'date' => '2024-03-09',
            'skip' => 0,
            'refund' => 0
          }
        end
        let (:record_to_import7) do
          {
            'account' => ENV['PFINANCE_LIABILITY_1'],
            'amount' => 1600,
            'description' => 'BLAHBLAH|Merchandise',
            'posted_date' => '2024-02-13',
            'direction' => "-1",
            'date' => '2024-03-09',
            'skip' => 1,
            'refund' => 0
          }
        end
        let (:record_to_import8) do
          {
            'account' => ENV['PFINANCE_LIABILITY_1'],
            'amount' => 1600,
            'description' => 'BLAHBLAH|Merchandise',
            'posted_date' => '2024-02-13',
            'direction' => "-1",
            'date' => '2024-03-09',
            'skip' => 0,
            'refund' => 1
          }
        end
        it 'returns the next unprocessed record that doesn\'t have skip or refund' do
          result7 = record_importer.import_record(record_to_import7)
          expect(result7).to be_success
          result8 = record_importer.import_record(record_to_import8)
          expect(result8).to be_success
          result1 = record_importer.import_record(record_to_import1)
          expect(result1).to be_success
          result = ledger.next_unprocessed_record
          result = result.transform_keys(&:to_s)
          result.reject! { |k,v| ['account_id', 'paired_accounts', 'posted_date', 'date',
            'description', 'direction', 'id'].include?(k) }
          expect(result).to include({
            'account_name' => Account::RWA_2_ACCOUNT[ENV['PFINANCE_LIABILITY_1']],
            'amount' => 140000,
            'skip' => 0,
            'refund' => 0
          })
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
          expect(DB[:entries].count).to eq(2)
          expect(DB[:transactions].count).to eq(1)
          expect(DB[:entries].select(:id, :amount, :account_id, :direction).all).to match [a_hash_including(
            id: result.transfer_ids["debit_record_id"],
            amount: 14000,
            account_id: 1,
            direction: 1
          ), a_hash_including(
            id: result.transfer_ids["credit_record_id"],
            amount: 14000,
            account_id: 2,
            direction: -1
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

          expect(DB[:transactions].count).to eq(0)
        end
      end
      context 'when the transfer comes from an unprocessed record' do
        it 'successfully saves the transfer and deletes the unprocessed record' do
          DB[:unprocessed_records].insert(id: 1, account: 1, amount: 140000,
            posted_date: '2024-01-23', date: '2024-03-09', description: 'BLAHBLAH|Merchandise', direction: -1)
          transfer['shared']['un_pr_record_id'] = 1
          result = ledger.record(transfer)
          expect(result).to be_success
          expect(DB[:transactions].count).to eq(1)
          expect(DB[:entries].count).to eq(2)
          expect(DB[:unprocessed_records].count).to eq(0)
        end
        it 'rejects the transfer and does not delete the unprocessed record when it is invalid' do
          DB[:unprocessed_records].insert(id: 1, account: 1, amount: 140000,
            posted_date: '2024-01-23', date: '2024-03-09', description: 'BLAHBLAH|Merchandise', direction: -1)
          transfer['shared']['un_pr_record_id'] = 1
          transfer['debit_account_id'] = nil
          result = ledger.record(transfer)
          expect(result).not_to be_success
          expect(DB[:transactions].count).to eq(0)
          expect(DB[:unprocessed_records].count).to eq(1)
        end
      end
      context 'with transactons and entries to balance' do
        let(:transfer1) do
          {
            'shared' => {
              'posted_date' => '2024-01-23',
              'amount' => 14000,
              'user_id' => 1,
              'description' => 'BLAHBLAH|Merchandise',
            },
            'debit_account_id' => 4,
            'credit_account_id' => 1
          }
        end
        let(:transfer2) do
          {
            'shared' => {
              'posted_date' => '2024-01-23',
              'amount' => 14000,
              'user_id' => 1,
              'description' => 'BLAHBLAH|Pay off credit card',
            },
            'debit_account_id' => 1,
            'credit_account_id' => 3
          }
        end
        let(:transfer3) do
          {
            'shared' => {
              'posted_date' => '2024-01-20',
              'amount' => 15000,
              'user_id' => 1,
              'description' => 'BLAHBLAH|Load money into checking account',
            },
            'debit_account_id' => 3,
            'credit_account_id' => 7
          }
        end
        let(:transfer4) do
          {
            'shared' => {
              'posted_date' => '2024-02-28',
              'amount' => 1600000,
              'user_id' => 2,
              'description' => 'BLAHBLAH|Record a paycheck',
            },
            'debit_account_id' => 3,
            'credit_account_id' => 6
          }
        end
        it 'returns a hash for the account balance of all accounts' do
          #need to load the transactions table and entries table with some data
          #to test the account balance. this is the format of the data that is sent to Ledger#record(transfer)
          #{"shared"=>{"posted_date"=>"2024-02-23", "description"=>"a desc", "amount"=>14000, "user_id"=>1}, "debit_account_id"=>1, "credit_account_id"=>2}
          result1 = ledger.record(transfer1)
          expect(result1).to be_success
          result2 = ledger.record(transfer2)
          expect(result2).to be_success
          result3 = ledger.record(transfer3)
          expect(result3).to be_success
          result4 = ledger.record(transfer4)
          expect(result4).to be_success
          balance = ledger.calculate_account_balances
          expect(balance).to include({"Asset_1" => 1601000, "Equity_1" => 15000, "Expense_1" => 14000,
            "Expense_2" => 0, "Liability_1" => 0, "Liability_2" => 0, "Revenue_1" => 1600000})
        end
      end
    end
    describe '#transfers_on' do
      it 'returns all transfers for the provided date' do
        result_1 = ledger.record(transfer.deep_merge({'shared' => {'posted_date' => '2017-06-10'}}))
        expect(result_1).to be_success
        result_2 = ledger.record(transfer.deep_merge({'shared' => {'posted_date' => '2017-06-10',
          'amount' => 15000}}))
        expect(result_2).to be_success
        result_3 = ledger.record(transfer.deep_merge({'shared' => {'posted_date' => '2017-06-11',
          'amount' => 16000}}))
        expect(result_3).to be_success

        lt = ledger.transfers_on('2017-06-10')
        test_array = []
        test_array[0] = lt[:posted_date].to_s
        test_array[1] = lt[:transactions][0][:entries][:debit]
        test_array[2] = lt[:transactions][0][:entries][:credit]
        # will only look at the first transfer
        amt1_debit = DB[:entries].where(id: result_1.transfer_ids["debit_record_id"]).get(:amount)
        amt1_credit = DB[:entries].where(id: result_1.transfer_ids["credit_record_id"]).get(:amount)

        expect(test_array[0]).to eq('2017-06-10')
        expect(test_array[1][:amount]).to eq(amt1_debit)
        expect(test_array[2][:amount]).to eq(amt1_credit)
      end

      it 'returns a blank array when there are no matching transfers' do
        test_array = []
        lt = ledger.transfers_on('2017-06-10')
        test_array[0] = lt[:posted_date].to_s
        test_array[1] = lt[:transactions]
        expect(test_array[1]).to eq([])
      end
    end
  end
end