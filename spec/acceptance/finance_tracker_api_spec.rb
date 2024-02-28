require 'rack/test'
require 'json'
require_relative '../../app/api'


module FinanceTracker
    RSpec.describe 'Finance Tracker API', :db do
        include Rack::Test::Methods

        def app
            FinanceTracker::API.new
        end
        def post_transfer(transfer)
            post '/transfers', JSON.generate(transfer)
            expect(last_response.status).to eq(200)
            parsed = JSON.parse(last_response.body)
            expect(parsed["transfer_ids"]).to include("debit_record_id" => a_kind_of(Integer))
            transfer.merge(parsed['transfer_ids'])
        end
        def post_account(account)
            post '/accounts', JSON.generate(account)
            expect(last_response.status).to eq(200)
            parsed = JSON.parse(last_response.body)
            expect(parsed).to include("id" => a_kind_of(Integer))
            account.merge('id' => parsed['id'])
        end
        context 'when testing transfers' do
            before(:example) do
                # set up for testing transfers table
                DB[:users].insert(id: 1, name: "Nick")
                DB[:categories].insert(id: 1, name: "discretionary")
                DB[:accounts].insert(id: 1, name: "cat1", normal: 1)
                DB[:accounts].insert(id: 2, name: "cat2", normal: 1)
            end
                it 'records submitted transfer' do
                transfer = {'shared' => {
                    'posted_date' => '2024-04-23',
                    'amount' => 14000,
                    'user_id' => 1,
                    'category_id' => 1
                    }, 'debit_account_id' => 1,
                    'credit_account_id' => 2
                }
                post '/transfers', JSON.generate(transfer)
                expect(last_response.status).to eq(200)
                parsed = JSON.parse(last_response.body)
                expect(parsed['transfer_ids']).to include('credit_record_id' => a_kind_of(Integer))
            end
            it 'updates transfer' do
                pending 'updates not implemented yet'
            end
            it 'retrieves records associated with specific date' do
                FebTransfer = post_transfer('shared' => {
                    'posted_date' => '2024-04-23',
                    'amount' => 14000,
                    'user_id' => 1,
                    'category_id' => 1
                    }, 'debit_account_id' => 1,
                    'credit_account_id' => 2
                )
                JanTransfer = post_transfer('shared' => {
                    'posted_date' => '2024-01-23',
                    'amount' => 14000,
                    'user_id' => 1,
                    'category_id' => 1
                    }, 'debit_account_id' => 1,
                    'credit_account_id' => 2
                )
                MarTransfer = post_transfer('shared' => {
                    'posted_date' => '2024-02-23',
                    'amount' => 14000,
                    'user_id' => 1,
                    'category_id' => 1
                    }, 'debit_account_id' => 1,
                    'credit_account_id' => 2
                )
                get '/transfers/2024-04-23'
                expect(last_response.status).to eq(200)
                transfers = JSON.parse(last_response.body)
                expect(transfers.values).to contain_exactly(FebTransfer)
            end
        end
        context 'when testing accounts' do
            it 'retrieves accounts with specific normal value' do
                new_account1 = post_account(
                    'name' => 'house',
                    'normal' => 1,
                    'description' => 'from which we pay bills to which salary added'
                )
                new_account2 = post_account(
                    'name' => 'house',
                    'normal' => -1,
                    'description' => 'from which we pay bills to which salary added'
                )
                new_account3 = post_account(
                    'name' => 'house',
                    'normal' => 1,
                    'description' => 'from which we pay bills to which salary added'
                )
                get '/accounts/normal/-1'
                expect(last_response.status).to eq(200)
                accounts = JSON.parse(last_response.body)
                clean_accounts = []
                accounts.each do |account|
                    clean_accounts << account.reject!{|k,v| k == "user_id"}
                end
                expect(clean_accounts).to contain_exactly(new_account2)
            end
            it 'retrieves all accounts' do
                new_account1 = post_account(
                    'name' => 'house',
                    'normal' => 1,
                    'description' => 'from which we pay bills to which salary added'
                )
                new_account2 = post_account(
                    'name' => 'house',
                    'normal' => -1,
                    'description' => 'from which we pay bills to which salary added'
                )
                new_account3 = post_account(
                    'name' => 'house',
                    'normal' => 1,
                    'description' => 'from which we pay bills to which salary added'
                )
                get '/accounts'
                expect(last_response.status).to eq(200)
                accounts = JSON.parse(last_response.body)
                clean_accounts = []
                accounts.each do |account|
                    clean_accounts << account.reject!{|k,v| ["user_id","user_name"].include? k}
                end
                expect(clean_accounts).to contain_exactly(new_account1,new_account2,new_account3)
            end
            it 'creates new account' do
                new_account = {
                    'name' => 'house',
                    'normal' => '1',
                    'description' => 'from which we pay bills to which salary added'
                }
                post_account(new_account)
                expect(last_response.status).to eq(200)
                accounts = JSON.parse(last_response.body)
                expect(accounts).to include('id' => a_kind_of(Integer))
            end
            context 'when updating an account' do
                before(:example) do
                    # set up for testing accounts table
                    DB[:users].insert(id: 1, name: "Nick")
                    DB[:accounts].insert(id: 1, name: "account1", normal: 1, user_id: 1)
                end
                it 'updates account' do
                    post '/accounts/1', JSON.generate('name' => 'account2')
                    expect(last_response.status).to eq(200)
                    get '/accounts/1'
                    expect(last_response.status).to eq(200)
                    account = JSON.parse(last_response.body)
                    puts "account: #{account}"
                    expect(*account).to include('name' => 'account2')
                end
            end
        end
    end
end