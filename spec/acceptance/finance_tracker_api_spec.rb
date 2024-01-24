require 'rack/test'
require 'json'
require_relative '../../app/api'

module FinanceTracker
    RSpec.describe 'Finance Tracker API' do
        include Rack::Test::Methods
        def app
            FinanceTracker::API.new
        end
        def post_transfer(transfer)
            post '/transfers', JSON.generate(transfer)
            expect(last_response.status).to eq(200)
            parsed = JSON.parse(last_response.body)
            puts "parsed is #{parsed['transfer_id']}"
            expect(parsed).to include('transfer_id' => a_kind_of(Integer))
            transfer.merge('id' => parsed['transfer_id'])
         end
        it 'records submitted tranfer' do
            pending 'Need to persist transfers'
            JanTransfer = post_transfer('shared' => {
                'date' => '2024-01-23',
                'amount' => 14000,
                'userId' => 1,
                'catId' => 1
            }, 'debit' => {
                'accountId' => 1,
                'direction' => 1
            }, 'credit' => {
                'accountId' => 2,
                'direction' => -1
            })
            FebTransfer = post_transfer('shared' => {
                'date' => '2024-02-21',
                'amount' => 13400,
                'userId' => 1,
                'catId' => 2
            }, 'debit' => {
                'accountId' => 1,
                'direction' => 1
            }, 'credit' => {
                'accountId' => 2,
                'direction' => -1
            })
            MarTransfer = post_transfer('shared' => {
                'date' => '2024-03-13',
                'amount' => 1400,
                'userId' => 1,
                'catId' => 3
            }, 'debit' => {
                'accountId' => 1,
                'direction' => 1
            }, 'credit' => {
                'accountId' => 2,
                'direction' => -1
            })
            get '/transfers/2024-02-21'
            expect(last_response.status).to eq(200)
            transfers = JSON.parse(last_response.body)
            expect(transfers).to contain_exactly(FebTransfer)
        end
    end
end