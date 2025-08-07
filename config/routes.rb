Rails.application.routes.draw do
  # 管理者用ルーティング
  namespace :admin do
    root to: 'contracts#index'
    get 'search', to: 'search#index'
    resources :users, only: [:index, :show, :edit, :update]
    resources :contracts, only: [:index, :show, :new, :create, :edit, :update, :destroy] do
      resources :comments, only: [:create, :edit, :update, :destroy] do
        member do
          post :reply
        end
      end
      member do
        get :slack_message
      end
      collection do
        post :ocr_preview
      end
    end
    resources :statuses, only: [:index, :create, :destroy, :edit, :update]
    resources :tags, only: [:index, :show, :destroy]
    resources :groups, only: [:index, :show, :new, :create, :edit, :update, :destroy]
    resources :group_join_requests, only: [:index] do
      member do
        post :approve
        post :reject
      end
    end
    resources :employees do
      collection do
        get :invite
        post :create_invite
      end
    end
    resources :slack_message_templates do
      member do
        get :preview
      end
    end
    
    resources :comment_notifications, only: [] do
      collection do
        patch :mark_all_as_read
      end
      member do
        patch :mark_as_read
      end
    end
    
    get 'mypage', to: 'profiles#show', as: 'mypage'
    get 'mypage/edit', to: 'profiles#edit', as: 'edit_mypage'
    patch 'mypage', to: 'profiles#update'
  end

  # Devise（管理者とユーザー）
  devise_for :admins, path: 'admin', controllers: {
    sessions: 'admins/sessions'
  }
  devise_for :users, controllers: { registrations: 'users/registrations', passwords: 'users/passwords' }

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
  resources :groups, only: [:new, :create, :show, :edit, :update, :destroy] do
    member do
      post :leave
    end
  end
  resources :contracts do
    resources :comments, only: [:create, :edit, :update, :destroy] do
      member do
        post :reply
      end
    end
    member do
      get :slack_message
    end
    collection do
      post :ocr_preview
    end
  end
  resources :tags, only: [:index, :create]
  resources :group_searches, only: [:index]
  resources :group_join_requests, only: [:create, :index, :destroy] do
    member do
      post :approve
      post :reject
    end
  end

  
  resources :slack_message_templates do
    member do
      get :preview
    end
  end
  
  resources :comment_notifications, only: [] do
    collection do
      patch :mark_all_as_read
    end
    member do
      patch :mark_as_read
    end
  end

end
