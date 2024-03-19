require 'sinatra/base'
require 'sinatra/cross_origin'
require 'json'
require_relative 'ledger'
require './app/models/account'
require './app/models/category'
require './app/models/transaction'
require './app/models/entry'
require './app/models/user'
require_relative 'augmenter'


module FinanceTracker
    class API < Sinatra::Base
        configure do
            enable :cross_origin
        end
        before do
            response.headers['Access-Control-Allow-Origin'] = '*'
        end
        def initialize(ledger: Ledger.new, augmenter: Augmenter.new)
            @augmenter = augmenter
            @ledger = ledger
            super()
        end
        get '/categories/:detail' do
            case params[:detail]
            when 'flat'
                #don't need to pass in anything
            when 'hierarchical'
                #as_hierarchy = true
            when 'accounts'
                #as_accounts = true and as_hierarchy = true
                result = @augmenter.get_category_records(nil, true, true)
            else
                status 404
                JSON.generate('error' => 'invalid detail')
            end
            json_result = JSON.generate(result)
            puts "json_result = #{json_result}"
            json_result
        end
        get '/catnaccounts' do
            output = @augmenter.build_cat_json
            output
        end
        get '/categories/flat' do
            result = @augmenter.get_categories_flat
            JSON.generate(result)
        end
        get '/categories/:id' do
            result = @augmenter.get_category_records(params[:id], false, false)
            JSON.generate(result)
        end
        get '/categories/parent_id/:value' do
            result = @augmenter.get_records(params[:value], true, true)
            JSON.generate(result)
        end
        post '/categories' do
            category = JSON.parse(request.body.read)
            result = @augmenter.create(category, :categories)
            if result.success?
                JSON.generate('id' => result.id)
            else
                status 422
                JSON.generate('error' => result.error_message)
            end
        end
        get '/next_unprocessed_record' do
            result = @ledger.next_unprocessed_record
            JSON.generate(result)
        end
        post '/next_unprocessed_record/refund/:value' do
            puts "params[:value] = #{params[:value]}"
            result = @ledger.refund_unprocessed_record(params[:value])
            JSON.generate(result)
        end
        post '/next_unprocessed_record/skip/:value' do
            result = @ledger.skip_unprocessed_record(params[:value])
            JSON.generate(result)
        end
        post '/transfers' do
            #curl -i -X POST -H "Content-Type: application/json" -d "{\"shared\":{\"posted_date\":\"2024-02-23\",
            #\"amount\":14000,\"user_id\":1},\"debit_account_id\":1,
            #\"credit_account_id\":2}"  http://localhost:9292/transfers
            #debit_account is the one that money is going into with direction of +1
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
            result = @augmenter.get_account_records
            JSON.generate(result)
        end
        get '/accounts/:id' do
            result = @augmenter.get_account_records(params[:id])
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
            result = @augmenter.get_user_records
            JSON.generate(result)
        end
        get '/users/:id' do
            result = @augmenter.get_user_records( params[:id])
            JSON.generate(result)
        end
        post '/add_new_transaction' do
            transaction = JSON.parse(request.body.read)
            #the transaction is:
            #{"date"=>"2022-02-10", "notes"=>"some notes", "description"=>"a desc",
            # "amount"=>"200", "debit"=>"1", "credit"=>"2"}
            # leger.record(transaction) expects the following:
            #-d "{\"shared\":{\"posted_date\":\"2024-02-23\",
            #\"amount\":14000,\"user_id\":1},\"debit_account_id\":1,
            #\"credit_account_id\":2}"
            data = {
                :shared.to_s => {
                    :posted_date.to_s => transaction["date"],
                    :amount.to_s => transaction["amount"],
                    :user_id.to_s => 1,
                    :notes.to_s => transaction["notes"],
                    :description.to_s => transaction["description"]
                },
                :debit_account_id.to_s => transaction["debit"],
                :credit_account_id.to_s => transaction["credit"]
            }
            result = @ledger.record(data)
            if result.success?
                JSON.generate('result' => "success")
            else
                status 422
                JSON.generate('error' => result.error_message)
            end
        end
        get '/test' do
            h = {
                :posted_date => "2024-02-11", :transactions => [
                  {:description => "1blahblah",
                     :entries => {
                        :debit => {:account_id => "value5", :amount => "value6"},
                        :credit => {:account_id => "value8", :amount => "value9"}}
                  },
                  {:description => "2blahblah",
                     :entries => {
                        :debit => {:account_id => "value5", :amount => "value6"},
                        :credit => {:account_id => "value8", :amount => "value9"}}
                  }
               ]
            }
            JSON.generate(h)
        end
        options "*" do
            response.headers["Allow"] = "GET, PUT, POST, DELETE, OPTIONS"
            response.headers["Access-Control-Allow-Headers"] = "Authorization, Content-Type, Accept, X-User-Email, X-Auth-Token"
            response.headers["Access-Control-Allow-Origin"] = "*"
            200
        end
    end
end    