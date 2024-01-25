require 'sequel'

DB = Sequel.connect("postgres://FinanceTracker:@localhost/FinanceTracker_#{ENV.fetch('RACK_ENV', 'development')}")