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
    end
end