class User < Sequel::Model
    one_to_many :transfers
    one_to_one :accounts
end