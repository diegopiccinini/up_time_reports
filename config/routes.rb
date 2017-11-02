Rails.application.routes.draw do

  root 'dashboard#index'

  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)
  devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks" }

  resources :vpcs, only: [:index, :show] do
    resources :reports, only: [:show]
  end

  resources :global_reports, only: [:index, :show]

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
