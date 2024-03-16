class User < Sequel::Model
    one_to_many :transactions
    one_to_many :accounts
end