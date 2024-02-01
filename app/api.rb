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
            puts "in GET /transfers/:date and date is #{params[:date]}"
            result = @ledger.transfers_on(params[:date])
            JSON.generate(result)
        end
    end
end    