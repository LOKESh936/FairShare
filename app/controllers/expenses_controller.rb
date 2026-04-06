class ExpensesController < ApplicationController
  include GroupAuthorization

  before_action :authorize_request
  before_action :load_group
  before_action :authorize_group_member!

  def create
    expense = ExpenseCreator.new(group: group, creator: current_user, params: expense_params).call
    render json: { expense: ExpenseSerializer.render(expense) }, status: :created
  end

  def index
    expenses = group.expenses.includes(:payer, expense_splits: :user).order(created_at: :desc)
    render json: { expenses: ExpenseSerializer.render(expenses) }
  end

  def destroy
    expense = group.expenses.find(params[:expense_id])
    unless expense.payer_id == current_user.id || group.creator_id == current_user.id
      raise AuthorizationError, "Only the payer or group creator can delete this expense"
    end

    expense.destroy!
    head :no_content
  end

  private

  def expense_params
    params.require(:description)
    params.require(:amount)
    params.require(:payer_id)

    params.permit(:description, :amount, :payer_id, :split_type, custom_splits: %i[user_id amount])
  end
end
