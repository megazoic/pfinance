require 'sinatra/base'
require 'sinatra/cross_origin'
require 'json'
require_relative 'ledger'
require_relative 'todo_tracker'
require './app/models/account'
require './app/models/category'
require './app/models/transaction'
require './app/models/entry'
require './app/models/user'
require './app/models/todo'
require './app/models/todo_transaction'
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
            result = {}
            case params[:detail]
            when 'flat'
                #don't need to pass in anything
                result = @augmenter.get_categories_flat
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
        post '/transactions' do
            # {"shared"=>{"posted_date"=>"2024-02-23", "amount"=>14000, "user_id"=>1}, "debit_account_id"=>1, "credit_account_id"=>2}
            #curl -i -X POST -H "Content-Type: application/json" -d "{\"shared\":{\"posted_date\":\"2024-02-23\",
            #\"amount\":14000,\"user_id\":1},\"debit_account_id\":1,
            #\"credit_account_id\":2}"  http://localhost:9292/transfers
            #debit_account is the one that money is going into with direction of +1
            request.body.rewind
            transaction = JSON.parse(request.body.read)
            #check for todos
            if !transaction["shared"]["todo"].nil?
                todo = Todo.create(date: Date.today, description: transaction["shared"]["todo"], completed: false)
                todo_tracker = FinanceTracker::TodoTracker.new(todo)
                #todo_tracker.add_todo(todo.date, false, 'New transaction todo')
            end
            result = @ledger.record(transaction)
            if result.success?
                if !todo.nil?
                    t = Transaction[result["transfer_ids"]["transaction_id"]]
                    t.todo = todo
                    t.save
                    # Create a TodoTransaction record to associate the Todo with the Transaction
                    tt = TodoTransaction.create(todo_id: todo.id, transaction_id: t.id)
                    puts "Transaction: #{t.inspect}"
                end

                JSON.generate('transfer_ids' => result.transfer_ids)
            else
                status 422
                JSON.generate('error' => result.error_message)
            end
        end
        get '/transaction/:date' do
            result = @ledger.transfers_on(params[:date])
            JSON.generate(result)
        end
        get '/todo_transactions' do
            todos = Todo.where(completed: false).all
            todo_transactions = todos.map do |todo|
              transactions = todo.transactions.map do |transaction|
                {
                  transaction_posted_date: transaction.posted_date,
                  transaction_description: transaction.description,
                  transaction_notes: transaction.notes,
                  todo_date: todo.date,
                  todo_description: todo.description,
                  todo_id: todo.id
                }
              end
              transactions
            end.flatten
            JSON.generate(todo_transactions)
        end
        post '/todos/completed' do
            # Parse the JSON request body
            data = JSON.parse(request.body.read)
            puts "**** todo data = #{data}"
          
            # Get the list of todo IDs
            todo_ids = data['todos']
            count = 0
            # Mark each todo as completed
            todo_ids.each do |id|
              todo = Todo[id]
              if todo
                count += 1
                todo.update(completed: true)
              end
            end
          
            # Return a success response
            status 200
            response = { message: "#{count} Todos marked as completed" }
            JSON.generate(response)
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
        get '/account_balances/:net' do
            if params[:net] == 'true'
                return JSON.generate(@ledger.get_account_balances(true))
            else
                return JSON.generate(@ledger.get_account_balances)
            end
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
            #transactions are generated denovo from web form
            transaction = JSON.parse(request.body.read)
            #the transaction is:
            #{"date"=>"2022-02-10", "notes"=>"some notes", "description"=>"a desc",
            # "amount"=>"200", "debit"=>"1", "credit"=>"2"}
            # leger.record(transaction) expects the following:
            #-d "{\"shared\":{\"posted_date\":\"2024-02-23\",
            #\"amount\":14000,\"user_id\":1},\"debit_account_id\":1,
            #\"credit_account_id\":2}"
            # shared key could also include a todo key
            userNick = DB[:users].where(name: "Nick").first
            data = {
                :shared.to_s => {
                    :posted_date.to_s => transaction["date"],
                    :amount.to_s => transaction["amount"],
                    :user_id.to_s => userNick[:id],
                    :notes.to_s => transaction["notes"],
                    :description.to_s => transaction["description"]
                },
                :debit_account_id.to_s => transaction["debit"],
                :credit_account_id.to_s => transaction["credit"]
            }
            result = @ledger.record(data)
            if result.success?
                #check to see if a todo was included
                if !transaction["todo"].nil?
                    todo = Todo.create(date: Date.today, description: transaction["todo"], completed: false)
                    todo_tracker = FinanceTracker::TodoTracker.new(todo)
                    t = Transaction[result["transfer_ids"]["transaction_id"]]
                    t.todo = todo
                    t.save
                    # Create a TodoTransaction record to associate the Todo with the Transaction
                    #tt = TodoTransaction.create(todo_id: todo.id, transaction_id: t.id)
                    todo_transaction = TodoTransaction.new
                    todo_transaction.todo_id = todo.id
                    todo_transaction.transaction_id = t.id
                    tt = todo_transaction.save
                    puts "Transaction: #{t.inspect} and todo_transaction: #{tt.inspect}"
                end
                #just interested in the total balance
                JSON.generate({net_balance: @ledger.get_account_balances(true)})
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