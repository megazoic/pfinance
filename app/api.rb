require 'sinatra/base'
require 'sinatra/cross_origin'
require 'json'
require_relative 'ledger'
require './app/models/account'
require './app/models/category'
require './app/models/transfer'
require './app/models/user'
require_relative 'augmenter'

module FinanceTracker
    class API < Sinatra::Base
        configure do
            enable :cross_origin
        end
        before do
            response.headers['Access-Control-Allow-Origin'] = 'http://localhost'
        end
        def initialize(ledger: Ledger.new, augmenter: Augmenter.new)
            @augmenter = augmenter
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
        post '/accounts' do
            account = JSON.parse(request.body.read)
            result = @augmenter.create(account, :accounts)
            if result.success?
                JSON.generate('id' => result.id)
            else
                status 422
                JSON.generate('error' => result.error_message)
            end
        end
        post '/accounts/:id' do
            #was account = JSON.parse(request.body.string) but lint error no method string
            account = JSON.parse(request.body.read)
            account[:id] = params[:id]
            result = @augmenter.update(account, :accounts)
            if result.success?
                JSON.generate('id' => result.id)
            else
                status 422
                JSON.generate('error' => result.error_message)
            end
        end
        get '/accounts/user_id/:value' do
            result = @augmenter.get_accounts_w_user_id(params[:value])
            JSON.generate(result)
        end
        get '/accounts/normal/:value' do
            result = @augmenter.get_accounts_w_normal(params[:value])
            JSON.generate(result)
        end
        get '/accounts' do
            result = @augmenter.get_records(:accounts)
            JSON.generate(result)
        end
        get '/accounts/:id' do
            result = @augmenter.get_records(:accounts, params[:id])
            JSON.generate(result)
        end
        post '/users' do
            user = JSON.parse(request.body.read)
            result = @augmenter.create(user, :users)
            if result.success?
                JSON.generate('id' => result.id)
            else
                status 422
                JSON.generate('error' => result.error_message)
            end
        end
        post '/users/:id' do
            user = JSON.parse(request.body.read)
            user[:id] = params[:id]
            result = @augmenter.update(user, :users)
            if result.success?
                JSON.generate('id' => result.id)
            else
                status 422
                JSON.generate('error' => result.error_message)
            end
        end
        get '/users' do
            result = @augmenter.get_records(:users)
            JSON.generate(result)
        end
        get '/users/:id' do
            result = @augmenter.get_records(:users, params[:id])
            JSON.generate(result)
        end
    end
end    