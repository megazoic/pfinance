require_relative '../../../app/augmenter'
require_relative '../../../config/sequel'
require_relative '../../support/db'
require_relative '../../../app/models/category'

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
                    updated_result = augmenter.update(updated_account, :accounts)
                    puts "updated_result: #{updated_result}"
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
            context 'for users' do  
                it 'successfully retrieves all users' do
                    all_users = augmenter.get_records(:users)
                    user_names = []
                    all_users.each do |user|
                        user_names << user[:name]
                    end
                    expect(user_names).to contain_exactly("Nick", "Irma")
                end
            end
            context 'for categories' do
                it 'successfully retrieves all categories' do
                    #set up for testing categories table
                    DB[:categories].insert(id: 1, name: "parent")
                    DB[:categories].insert(id: 2, name: "child", parent_id: 1)
                    all_categories = augmenter.get_records(:categories)
                    category_names = []
                    all_categories.each do |category|
                        category_names << category[:name]
                    end
                    expect(category_names).to contain_exactly("parent", "child")
                end
                it 'successfully retrieves all descendants of a category' do
                    #set up for testing categories table
                    DB[:categories].insert(id: 1, name: "parent")
                    DB[:categories].insert(id: 2, name: "child", parent_id: 1)
                    DB[:categories].insert(id: 3, name: "grandchild", parent_id: 2)
                    all_descendants = augmenter.get_records(:categories, nil, 1)
                    descendant_names = []
                    all_descendants.each do |descendant|
                        descendant_names << descendant[:name]
                    end
                    expect(descendant_names).to contain_exactly("child", "grandchild")
                end
            end
        end
    end
end
