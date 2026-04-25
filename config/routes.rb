Rails.application.routes.draw do
  # ログインしているユーザーとそうでないユーザーでルートを分ける
  # ログインしているユーザーはダッシュボードのトップへ、そうでないユーザーは静的ページのトップへ
  authenticated :user do
    root to: "dashboard#top", as: :authenticated_root
  end

  root "static_pages#top"

  # deviseをカスタマイズ
  devise_for :users, controllers: {
    registrations: "users/registrations",
    sessions: "users/sessions",
    omniauth_callbacks: "users/omniauth_callbacks"
  }

  # マイページ
  get "mypage" => "mypages#show"

  # ミニメモリー - uuidをURLパラメータとして使用するため、param: :uuidを指定
  resources :memories, param: :uuid, only: %i[index new create show edit update destroy]

  # 掲示板 - uuidをURLパラメータとして使用するため、param: :uuidを指定
  resources :public_memories, param: :uuid, only: %i[index show]

  # 家族グループ - uuidをURLパラメータとして使用するため、param: :uuidを指定
  resources :family_groups, param: :uuid, only: %i[new create update show destroy]

  get "memory_game" => "memory_games#show", as: :memory_game

  # ゲーム（写真で神経衰弱）
  namespace :api do
    resource :memory_game, only: %i[show]
  end

  # 招待リンク
  get  "invitations/:token",      to: "invitations#show",  as: :invitation
  post "invitations/:token/join", to: "invitations#join",  as: :join_invitation
  post "invitations",             to: "invitations#create", as: :invitations

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Defines the root path route ("/")
  # root "posts#index"
end
