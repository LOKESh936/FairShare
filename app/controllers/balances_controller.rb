class BalancesController < ApplicationController
  include GroupAuthorization

  before_action :authorize_request
  before_action :load_group
  before_action :authorize_group_member!

  def show
    render json: BalanceCalculator.new(group: group).call
  end
end
