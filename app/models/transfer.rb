class Transfer < Sequel::Model
    many_to_one :user
    many_to_one :account
end