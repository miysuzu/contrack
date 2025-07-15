Rails.application.routes.draw do
  # 管理者用ルーティング
  namespace :admin do
    root to: 'contracts#index'
    get 'search', to: 'search#index'
    resources :users, only: [:index, :show, :edit, :update]
    resources :contracts, only: [:index, :show, :destroy]
    resources :statuses, only: [:index, :create, :destroy, :edit, :update]
  end

  # Devise（管理者とユーザー）
  devise_for :admins, path: 'admin', controllers: {
    sessions: 'admins/sessions'
  }
  devise_for :users

  # ユーザー用マイページなど
  devise_scope :user do
    get 'users/mypage' => 'users#show', as: 'user_mypage'
    get 'users/edit' => 'users#edit', as: 'edit_user'
    patch 'users/update' => 'users#update'
    get 'users/unsubscribe' => 'users#unsubscribe', as: 'unsubscribe_user'
    patch 'users/withdraw' => 'users#withdraw', as: 'withdraw_user'
  end

  # 一般ユーザー用トップ・契約書・タグ
  root to: 'homes#top'
  resources :contracts
  resources :tags, only: [:index]
end
