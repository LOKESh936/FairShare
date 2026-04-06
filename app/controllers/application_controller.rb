class ApplicationController < ActionController::API
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable_entity
  rescue_from ActionController::ParameterMissing, with: :render_bad_request
  rescue_from AuthenticationError, with: :render_unauthorized
  rescue_from AuthorizationError, with: :render_forbidden
  rescue_from ValidationError, with: :render_custom_validation_error

  private

  attr_reader :current_user

  def authorize_request
    auth_header = request.headers["Authorization"]
    token = auth_header.to_s.split.last
    raise AuthenticationError, "Missing authentication token" if token.blank?

    decoded = JsonWebToken.decode(token)
    @current_user = User.find(decoded[:user_id])
  rescue ActiveRecord::RecordNotFound
    raise AuthenticationError, "Invalid authentication token"
  end

  def render_not_found(exception)
    render json: { error: exception.message }, status: :not_found
  end

  def render_unprocessable_entity(exception)
    errors = exception.record&.errors&.full_messages || [ exception.message ]
    render json: { error: errors }, status: :unprocessable_entity
  end

  def render_bad_request(exception)
    render json: { error: exception.message }, status: :bad_request
  end

  def render_unauthorized(exception)
    render json: { error: exception.message }, status: :unauthorized
  end

  def render_forbidden(exception)
    render json: { error: exception.message }, status: :forbidden
  end

  def render_custom_validation_error(exception)
    render json: { error: exception.message }, status: :unprocessable_entity
  end
end
