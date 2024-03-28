class Transaction < Sequel::Model
    many_to_one :user
    one_to_many :entries
    many_to_one :todo
end