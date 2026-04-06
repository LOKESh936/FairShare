module JsonWebToken
  ALGORITHM = "HS256"

  def self.encode(payload, expires_at: 24.hours.from_now)
    JWT.encode(payload.merge(exp: expires_at.to_i), secret_key, ALGORITHM)
  end

  def self.decode(token)
    body = JWT.decode(token, secret_key, true, { algorithm: ALGORITHM }).first
    body.with_indifferent_access
  rescue JWT::DecodeError => e
    raise AuthenticationError, e.message
  end

  def self.secret_key
    ENV["JWT_SECRET"] || ENV["SECRET_KEY_BASE"] || Rails.application.secret_key_base
  end
  private_class_method :secret_key
end
