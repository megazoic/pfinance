require 'sinatra/base'
require 'json'
require_relative 'ledger'
require './app/models/account'
require './app/models/category'
require './app/models/transfer'
require './app/models/user'

module FinanceTracker
    class API < Sinatra::Base
        def initialize(ledger: Ledger.new)
            @ledger = ledger
            super()
        end
        post '/transfers' do
            #curl -i -X POST -H "Content-Type: application/json" -d "{\"shared\":{\"posted_date\":\"2024-02-23\",
            #\"amount\":14000,\"user_id\":1,\"category_id\":1},\"debit_account_id\":1,
            #\"credit_account_id\":2}"  http://localhost:9292/transfers
            request.body.rewind
            transfer = JSON.parse(request.body.read)
            result = @ledger.record(transfer)
            if result.success?
                JSON.generate('transfer_ids' => result.transfer_ids)
            else
                status 422
                JSON.generate('error' => result.error_message)
            end
        end
        get '/transfers/:date' do
            result = @ledger.transfers_on(params[:date])
            JSON.generate(result)
        end
    end
end    