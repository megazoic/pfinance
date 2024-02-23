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
            expect(parsed).to include("account_id" => a_kind_of(Integer))
            account.merge('id' => parsed['account_id'])
         end
        it 'records submitted transfer' do
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
        it 'updates transfer' do
            pending 'updates not implemented yet'
        end
        it 'retrieves accounts with specific normal value' do
            pending 'Need to persist accounts'
            new_account1 = post_account(
                'name' => 'house',
                'normal' => '1',
                'description' => 'from which we pay bills to which salary added'
            )
            new_account2 = post_account(
                'name' => 'house',
                'normal' => '-1',
                'description' => 'from which we pay bills to which salary added'
            )
            new_account3 = post_account(
                'name' => 'house',
                'normal' => '1',
                'description' => 'from which we pay bills to which salary added'
            )
            get '/accounts/normal/-1'
            expect(last_response.status).to eq(200)
            accounts = JSON.parse(last_response.body)
            expect(accounts).to contain_exactly(new_account2)
        end
        it 'retrieves all accounts' do
            pending 'Need to persist accounts'
            new_account1 = post_account(
                'name' => 'house',
                'normal' => '1',
                'description' => 'from which we pay bills to which salary added'
            )
            new_account2 = post_account(
                'name' => 'house',
                'normal' => '-1',
                'description' => 'from which we pay bills to which salary added'
            )
            new_account3 = post_account(
                'name' => 'house',
                'normal' => '1',
                'description' => 'from which we pay bills to which salary added'
            )
            get '/accounts'
            expect(last_response.status).to eq(200)
            accounts = JSON.parse(last_response.body)
            expect(accounts).to contain_exactly(new_account1,new_account2,new_account3)
        end
        it 'creates new account' do
            new_account = {
                'name' => 'house',
                'normal' => '1',
                'description' => 'from which we pay bills to which salary added'
            }
            post '/accounts'
            expect(last_response.status).to eq(200)
            accounts = JSON.parse(last_response.body)
            expect(accounts).to include('account_id' => a_kind_of(Integer))
        end
    end
end