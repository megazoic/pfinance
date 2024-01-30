require_relative '../../../app/api'
require 'rack/test'

module FinanceTracker
    RSpec.describe API do
        include Rack::Test::Methods
        def app
            API.new(ledger: ledger)
        end
        let(:ledger) {instance_double('FinanceTracker::Ledger')}
        describe 'POST /transfers' do
            context 'when the transfer is successfully recorded' do
                let(:transfer) {{ 'some' => 'data' }}
                before do
                    allow(ledger).to receive(:record)
                        .with(transfer)
                        .and_return(RecordResult.new(true,417, nil))
                end
                it 'returns the transfer id' do
                    post '/transfers', JSON.generate(transfer)
                    parsed = JSON.parse(last_response.body)
                    expect(parsed).to include('transfer_ids' => 417)
                end
                it 'responds with a 200 (OK)' do
                    post '/transfers', JSON.generate(transfer)
                    expect(last_response.status).to eq(200)
                end
            end
            context 'when the transfer fails validation' do
                let(:transfer) { { 'some' => 'data' } }
        
                before do
                  allow(ledger).to receive(:record)
                    .with(transfer)
                    .and_return(RecordResult.new(false, 417, 'Transfer incomplete'))
                end
        
                it 'returns an error message' do
                  post '/transfers', JSON.generate(transfer)
        
                  parsed = JSON.parse(last_response.body)
                  expect(parsed).to include('error' => 'Transfer incomplete')
                end
        
                it 'responds with a 422 (Unprocessable entity)' do
                  post '/transfers', JSON.generate(transfer)
                  expect(last_response.status).to eq(422)
                end
            end
        end
    end
end