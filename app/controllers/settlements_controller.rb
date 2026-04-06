class SettlementsController < ApplicationController
  include GroupAuthorization

  before_action :authorize_request
  before_action :load_group
  before_action :authorize_group_member!

  def create
    settlement = SettlementCreator.new(
      group: group,
      actor: current_user,
      to_user_id: settlement_params[:to_user_id],
      amount: settlement_params[:amount]
    ).call

    render json: { settlement: SettlementSerializer.render(settlement) }, status: :created
  end

  private

  def settlement_params
    params.require(:to_user_id)
    params.require(:amount)

    params.permit(:to_user_id, :amount)
  end
end
