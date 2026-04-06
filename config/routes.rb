Rails.application.routes.draw do
  post "auth/register", to: "auth#register"
  post "auth/login", to: "auth#login"

  get "up" => "rails/health#show", as: :rails_health_check
end
