require './.ignore/sensitive.rb'

class Account < Sequel::Model
    one_to_many :entries
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
    def calculate_account_balances(net_all = false)
        single_account_balance = lambda do |account|
            # Get all entries for this account that belong to transactions that are not refunds
            entries = account.entries.reject { |entry| entry.transaction.refunded == 1 }
            if entries.empty?
                return 0
            else
                balance = entries.sum { |entry| (entry.amount * entry.direction) }
                return balance
            end
        end
        if net_all == true
            #return net balance for all accounts
            net_balance = 0
            Account.each do |account|
                normal = account.category.normal
                account_balance = single_account_balance.call(account)
                net_balance += account_balance# * normal
            end
            #need to account for fact that the amount is stored as an integer not floating point
            net_balance = net_balance/100.0
            return net_balance
        else
            balances = {}
            Account.each do |account|
                account_balance = single_account_balance.call(account)
                name = "#{account.id}-#{account.category.name}-#{account.name}"
                balances[name] = account_balance/100.0
            end
            balances.each do |key, value|
                if (value < 1 && value > -1)
                    balances[key] = 0.0
                end
            end
            return balances
        end
    end        

end
