class GroupMembersController < ApplicationController
  include GroupAuthorization

  before_action :authorize_request
  before_action :load_group
  before_action :authorize_group_member!

  def create
    email = member_params[:email].to_s.downcase.strip
    user = User.find_by(email: email)
    raise ActiveRecord::RecordNotFound, "User with email #{email} was not found" if user.nil?

    membership = group.group_memberships.find_or_initialize_by(user: user)
    if membership.persisted?
      render json: { member: UserSerializer.render(user), message: "User is already in the group" }
      return
    end

    membership.role = :member
    membership.save!

    render json: { member: UserSerializer.render(user) }, status: :created
  end

  private

  def member_params
    params.require(:email)
    params.permit(:email)
  end
end
