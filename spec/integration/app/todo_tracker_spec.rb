require_relative '../../../app/todo_tracker'

RSpec.describe FinanceTracker::TodoTracker do
  before(:each) do
    @transaction = Transaction.create(posted_date: "20024-10-22")
    @todo_tracker = FinanceTracker::TodoTracker.new(Todo.new)
  end

  describe '#add_transaction' do
    it 'creates a new Todo and associates it with an existing Transaction' do
      @todo_tracker.add_transaction(@transaction, Date.today, false, 'My new todo')
      expect(@todo_tracker.todo.transactions).to include(@transaction)
    end
  end
  describe '#remove_transaction' do
    it 'removes the association between the Todo and the Transaction' do
      @todo_tracker.add_transaction(@transaction, Date.today, false, 'My new todo')
      @todo_tracker.remove_transaction(@transaction)
      expect(@todo_tracker.todo.transactions).not_to include(@transaction)
    end
  end
  describe '#mark_as_completed' do
    it 'marks the Todo as completed' do
      @todo_tracker.add_transaction(@transaction, Date.today, false, 'My new todo')
      @todo_tracker.mark_as_completed
      expect(@todo_tracker.todo.completed).to be true
    end
  end
  describe '#add_related_todos' do
    it 'adds a related Todo' do
      related_todo = Todo.create(date: Date.today)
      @todo_tracker.add_transaction(@transaction, Date.today, false, 'My new todo')
      @todo_tracker.add_related_todo(related_todo)
      expect(@todo_tracker.todo.related_todos).to include(related_todo)
    end
  end
  describe '#remove_related_todo' do
    it 'removes a related Todo' do
      related_todo = Todo.create(date: Date.today)
      @todo_tracker.add_transaction(@transaction, Date.today, false, 'My new todo')
      @todo_tracker.add_related_todo(related_todo)
      @todo_tracker.remove_related_todo(related_todo)
      expect(@todo_tracker.todo.related_todos).not_to include(related_todo)
    end
  end
end