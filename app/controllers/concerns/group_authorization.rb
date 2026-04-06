module GroupAuthorization
  extend ActiveSupport::Concern

  private

  def load_group
    @group = Group.find(params[:id] || params[:group_id])
  end

  def authorize_group_member!
    raise AuthorizationError, "You are not a member of this group" unless @group.member?(current_user)
  end

  attr_reader :group
end
