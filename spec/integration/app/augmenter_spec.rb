require_relative '../../../app/augmenter'
require_relative '../../../config/sequel'
require_relative '../../support/db'

module FinanceTracker
    RSpec.describe Augmenter, :aggregate_failures, :db do
        before(:example) do
            # set up for testing accounts table
            DB[:users].insert(id: 1, name: "Nick")
            DB[:users].insert(id: 2, name: "Irma")
        end

        let(:augmenter) { Augmenter.new }
        let(:account) do
          {
            'name' => 'brokerage',
            'normal' => 1,
            'user_id' => 1,
            'description' => 'some description'
          }
        end
    
        describe '#create' do
            context 'with a valid account' do
                it 'successfully saves the account in the db' do
                    result = augmenter.create(account, :accounts)
                    expect(result).to be_success
                    expect(DB[:accounts].all).to match [a_hash_including(
                        id: result.id,
                        name: 'brokerage',
                        normal: 1,
                        user_id: 1,
                        description: 'some description'
                    )]
                end
                it 'successfully updates the account' do
                    result = augmenter.create(account, :accounts)
                    updated_account = DB[:accounts].where(id: result.id).first
                    updated_account[:normal] = -1 
                    updated_result = augmenter.update(updated_account, :accounts, result.id)
                    expect(updated_result).to be_success
                    expect(DB[:accounts].where(id: updated_result.id).first).to include ({normal: -1})
                end
            end
            context 'with a valid user' do
                it 'successfully saves the user in the db'
            end
        end
        describe '#get_records' do
            context 'for accounts' do
                it 'successfully retrieves all accounts' do
                    augmenter.create(account, :accounts)
                    account['name'] = "new name"
                    augmenter.create(account, :accounts)
                    account['name'] = "new 2 name"
                    account['user_id'] = 2
                    augmenter.create(account, :accounts)
                    all_records = augmenter.get_records(:accounts)
                    record_names = []
                    record_user_names = []
                    all_records.each do |record|
                        record_names << record[:name]
                        record_user_names << record[:user_name]
                    end
                    expected_names = ["brokerage", "new name", "new 2 name"]
                    expected_user_names = ["Nick", "Nick", "Irma"]
                    expect(record_names).to contain_exactly(
                        *expected_names
                    )
                    expect(record_user_names).to contain_exactly(
                        *expected_user_names
                    )
                end
                it 'successfully retrieves accounts with specific normal value' do
                    augmenter.create(account, :accounts)
                    account['normal'] = -1
                    augmenter.create(account, :accounts)
                    account['normal'] = 1
                    augmenter.create(account, :accounts)
                    records_w_neg_normal = augmenter.get_accounts_w_normal(-1)
                    expect(records_w_neg_normal.length).to eq(1)
                end
                it 'successfully retrieves accounts with specific user_id' do
                    augmenter.create(account, :accounts)
                    account['name'] = "new name"
                    account['user_id'] = 2
                    augmenter.create(account, :accounts)
                    account['name'] = "new 2 name"
                    account['user_id'] = 2
                    augmenter.create(account, :accounts)
                    records_w_name = augmenter.get_accounts_w_user_id(2)
                    expect(records_w_name.length).to eq(2)
                end
            end
        end
    end
end
