require_relative '../../../app/augmenter'
require_relative '../../../config/sequel'
require_relative '../../support/db'

module FinanceTracker
    RSpec.describe Augmenter, :aggregate_failures, :db do
        let(:augmenter) { Augmenter.new }
        let(:account) do
          {
            'name' => 'brokerage',
            'normal' => 1,
            'user_id' => 1,
            'description' => 'some description'
          }
        end
    
        describe '#record' do
            context 'with a valid account' do
                it 'successfully saves the account in the db' do
                    result = augmenter.record(account)
                    expect(result).to be_success
                    expect(DB[:accounts].all).to match [a_hash_including(
                        id: result.id,
                        name: 'brokerage',
                        normal: 1,
                        user_id: 1,
                        description: 'some description'
                    )]
                end
            end
        end    
    end
end
