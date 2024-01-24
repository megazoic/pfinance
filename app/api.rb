require 'sinatra/base'
require 'json'
module FinanceTracker
    class API < Sinatra::Base
        post '/transfers' do
            JSON.generate('debit_id' => 45)
        end
        get '/transfers/:date' do
            JSON.generate([])
        end
    end
end    