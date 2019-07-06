Rails.application.routes.draw do
  require 'sidekiq/web'
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)

  mount Sidekiq::Web => '/sidekiq'
  Sidekiq::Web.set :session_secret, Rails.application.credentials[:secret_key_base]

  root to: "admin/brands#index"

  namespace :api do
    namespace :v1 do
      get 'users/wechat_auth', to: 'users#wechat_auth'
      get 'users/info', to: 'users#info'
      post 'users/update_wechat_userinfo', to: 'users#update_wechat_userinfo'
      post 'users/update_gps', to: 'users#update_gps' 
      resources :devices, only: [:index, :show]
      post 'devices/bind', to: 'devices#bind'
      post 'devices/unbind', to: 'devices#unbind'
      post 'devices/cmd', to: 'devices#cmd'
      post 'devices/rename', to: 'devices#rename'
      post 'devices/users', to: 'devices#users'
      post 'devices/edit_user', to: 'devices#edit_user'
      post 'invitations/get_token', to: 'invitations#create'
      post 'invitations/join_by_token', to: 'invitations#join_by_token'
      resources :messages, only: [:index, :show]
      resources :app_versions, only: [:index, :show]
    end
  end
  #post 'user_token' => 'user_token#create'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end