require 'sequel'

if ENV.fetch('RACK_ENV') == 'production'
    DB = Sequel.connect("postgres://pFinance:#{ENV.fetch('PG_PWD')}@localhost/pFinance_production")
else
    DB = Sequel.connect("postgres://FinanceTracker:@localhost/FinanceTracker_#{ENV.fetch('RACK_ENV', 'development')}")
end
