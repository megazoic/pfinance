class TodoTransaction < Sequel::Model
    many_to_one :todo
    many_to_one :transaction
  end