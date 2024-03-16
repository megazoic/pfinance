class Entry < Sequel::Model
    many_to_one :account
    many_to_one :transaction
end
