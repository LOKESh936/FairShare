class ActivitiesController < ApplicationController
  include GroupAuthorization

  before_action :authorize_request
  before_action :load_group
  before_action :authorize_group_member!

  def index
    activities = group.activities.includes(:actor, :trackable)
                    .order(created_at: :desc)
                    .limit(50)

    render json: { activity: ActivitySerializer.render(activities) }
  end
end
