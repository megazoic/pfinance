require 'date'
require 'json'
require_relative '../config/sequel'
require_relative './models/todo'
require_relative './models/transaction'


module FinanceTracker
    class TodoTracker
        attr_reader :todo
      def initialize(todo)
        @todo = todo
      end
  
      def add_transaction(transaction, date, completed, description)
        @todo.date = date
        @todo.completed = completed
        @todo.description = description
        @todo.save # Save the Todo to the database
        @todo.add_transaction(transaction) # Now you can add the transaction
      end
      def remove_transaction(transaction)
        @todo.remove_transaction(transaction)
      end
  
      def mark_as_completed
        @todo.update(completed: true)
      end
  
      def add_related_todo(todo)
        @todo.add_related_todo(todo)
      end
  
      def remove_related_todo(todo)
        @todo.remove_related_todo(todo)
      end
    end
  end