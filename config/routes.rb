Rails.application.routes.draw do
  post "auth/register", to: "auth#register"
  post "auth/login", to: "auth#login"

  get "up" => "rails/health#show", as: :rails_health_check

  resources :groups, only: %i[index create show destroy], param: :id
  post "groups/:id/members", to: "group_members#create"
  get "groups/:id/expenses", to: "expenses#index"
  post "groups/:id/expenses", to: "expenses#create"
  delete "groups/:id/expenses/:expense_id", to: "expenses#destroy"
end
