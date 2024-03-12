require './.ignore/sensitive.rb'

class Account < Sequel::Model
    one_to_many :transfers
    many_to_one :user
    many_to_one :category
    
    RWA = {'liabilities' => [ENV['PFINANCE_LIABILITY_1'], ENV['PFINANCE_LIABILITY_2']],
    'assets' => [ENV['PFINANCE_ASSET_1']]}
    RWA_2_ACCOUNT = {ENV['PFINANCE_LIABILITY_1'] => 'Liability_1', ENV['PFINANCE_LIABILITY_2'] => 'Liability_2',
        ENV['PFINANCE_ASSET_1'] => 'Asset_1'} 
    
    def get_corresp_app_account(wr_account)
        account_name = RWA_2_ACCOUNT[wr_account.to_s]
        account = Account.where(name: account_name).first
    end
end