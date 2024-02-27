require_relative '../../../app/api'
require 'rack/test'

module FinanceTracker
    RSpec.describe API do
        include Rack::Test::Methods
        def app
            API.new(ledger: ledger, augmenter: augmenter)
        end
        let(:augmenter) {instance_double('FinanceTracker::Augmenter')}
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
        describe 'POST /accounts' do
            context 'when the account is successfully recorded' do
                let(:account) {{'some' => 'data'}}
                before do
                    allow(augmenter).to receive(:create)
                    .with(account, :accounts)
                    .and_return(AugmentResult.new(true, 32, nil))
                end
                it 'returns account id' do
                    post '/accounts', JSON.generate(account)
                    parsed = JSON.parse(last_response.body)
                    expect(parsed).to include('id' => 32)
                end
                it 'responds with a 200 (OK)' do
                    post '/accounts', JSON.generate(account)
                    expect(last_response.status).to eq(200)
                end
            end
            context 'when the account fails validation' do
                let(:account) {{'some' => 'data'}}
                before do
                    allow(augmenter).to receive(:create)
                    .with(account, :accounts)
                    .and_return(AugmentResult.new(false, 32, 'Account incomplete'))
                end
                it 'returns an error message' do
                    post '/accounts', JSON.generate(account)
                    parsed = JSON.parse(last_response.body)
                    expect(parsed).to include('error' => 'Account incomplete')
                end
                it 'responds with a 422 (Unprocessable entity)' do
                    post '/accounts', JSON.generate(account)
                    expect(last_response.status).to eq(422)
                end
            end
        end
        describe 'GET /accounts/:normal' do
            context 'when accounts exist with a specific normal' do
                before do
                    return_value = ['account_2']
                    allow(augmenter).to receive(:get_accounts_w_normal)
                    .with('-1')
                    .and_return(*return_value)
                end
                it 'returns a list of accounts as JSON' do
                    get '/accounts/normal/-1'
                    parsed = JSON.parse(last_response.body)
                    expect(parsed).to eq(['account_2'])
                end
                it 'responds with a 200 (OK)' do
                    get '/accounts/normal/-1'
                    expect(last_response.status).to eq(200)
                end
            end
            context 'when accounts exist with a specific user_id' do
                before do
                    return_value = ['account_2']
                    allow(augmenter).to receive(:get_accounts_w_user_id)
                    .with('2')
                    .and_return(*return_value)
                end
                it 'returns a list of accounts as JSON' do
                    get '/accounts/user_id/2'
                    parsed = JSON.parse(last_response.body)
                    expect(parsed).to eq(['account_2'])
                end
            end
        end
    end
end