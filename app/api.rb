require 'sinatra/base'
require 'json'
require_relative 'ledger'

module FinanceTracker
    class API < Sinatra::Base
        def initialize(ledger: Ledger.new)
            @ledger = ledger
            super()
        end
        post '/transfers' do
            transfer = JSON.parse(request.body.string)
            result = @ledger.record(transfer)
            if result.success?
                JSON.generate('transfer_id' => result.transfer_id)
            else
                status 422
                JSON.generate('error' => result.error_message)
            end
        end
        get '/transfers/:date' do
            JSON.generate([])
        end
    end
end    