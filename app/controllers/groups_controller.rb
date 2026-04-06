class GroupsController < ApplicationController
  include GroupAuthorization

  before_action :authorize_request
  before_action :load_group, only: %i[show destroy]
  before_action :authorize_group_member!, only: %i[show destroy]

  def index
    groups = current_user.groups.includes(:creator, :members).order(created_at: :desc)
    render json: { groups: GroupSerializer.render(groups) }
  end

  def create
    group = nil
    Group.transaction do
      group = Group.create!(name: group_params[:name], creator: current_user)
      group.group_memberships.create!(user: current_user, role: :admin)
    end

    render json: { group: GroupSerializer.render(group) }, status: :created
  end

  def show
    render json: { group: GroupSerializer.render(group) }
  end

  def destroy
    membership = group.group_memberships.find_by!(user_id: current_user.id)
    membership.destroy!

    group.destroy! if group.group_memberships.none?

    head :no_content
  end

  private

  def group_params
    params.require(:name)
    params.permit(:name)
  end
end
