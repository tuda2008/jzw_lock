Rails.application.routes.draw do
  require 'sidekiq/web'
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)

  mount Sidekiq::Web => '/sidekiq'
  Sidekiq::Web.set :session_secret, Rails.application.credentials[:secret_key_base]

  root to: 'admin/brands#index'
 
  resources :faqs, only: [:index, :show]
  get 'wechat/get_token', to: 'wechat#get_token'
  get 'wechat/airkiss', to: 'wechat#airkiss'

  namespace :api do
    namespace :v1 do
      get 'users/wechat_auth', to: 'users#wechat_auth'
      get 'users/info', to: 'users#info'
      post 'users/update_wechat_userinfo', to: 'users#update_wechat_userinfo'
      post 'users/update_gps', to: 'users#update_gps'
      post 'users/update_mobile_and_name', to: 'users#update_mobile_and_name'
      post 'users/update_name', to: 'users#update_name'
      post 'users/sms_verification_code', to: 'users#sms_verification_code'
      post 'users/bind_mobile', to: 'users#bind_mobile'
      resources :users, except: [:new, :edit]
      post 'devices/bind', to: 'devices#bind'
      post 'devices/unbind', to: 'devices#unbind'
      post 'devices/cmd', to: 'devices#cmd'
      post 'devices/rename', to: 'devices#rename'
      post 'devices/users', to: 'devices#users'
      post 'devices/edit_user', to: 'devices#edit_user'
      post 'devices/set_open_warn', to: 'devices#set_open_warn'
      post 'invitations/get_token', to: 'invitations#create'
      post 'invitations/join_by_token', to: 'invitations#join_by_token'
      post 'wechat/update_form_ids', to: 'wechat#update_form_ids'
      resources :ble_settings, only: [:show, :create, :destroy]
      resources :devices, only: [:index, :show]
      resources :messages, only: [:index, :show]
      resources :app_versions, only: [:index, :show]
      resources :sys_notifiers, only: [:index, :show, :create]
    end
  end
  #post 'user_token' => 'user_token#create'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end