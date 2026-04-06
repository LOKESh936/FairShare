class AuthController < ApplicationController
  def register
    user = User.create!(register_params)
    token = JsonWebToken.encode(user_id: user.id)

    render json: {
      token: token,
      user: UserSerializer.render(user)
    }, status: :created
  end

  def login
    user = User.find_by(email: login_params[:email].to_s.downcase.strip)
    unless user&.authenticate(login_params[:password])
      raise AuthenticationError, "Invalid email or password"
    end

    token = JsonWebToken.encode(user_id: user.id)
    render json: {
      token: token,
      user: UserSerializer.render(user)
    }
  end

  private

  def register_params
    params.require(:name)
    params.require(:email)
    params.require(:password)
    params.require(:password_confirmation)

    params.permit(:name, :email, :password, :password_confirmation)
  end

  def login_params
    params.require(:email)
    params.require(:password)

    params.permit(:email, :password)
  end
end
