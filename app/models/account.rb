class Account < Sequel::Model
    one_to_many :transfers
    many_to_one :user
    many_to_one :category
end