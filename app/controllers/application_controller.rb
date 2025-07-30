class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_notifications, if: :user_signed_in?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  end

  def after_sign_out_path_for(resource_or_scope)
    if resource_or_scope == :admin
      new_admin_session_path
    else
      root_path
    end
  end

  def after_sign_in_path_for(resource_or_scope)
    if resource_or_scope == :admin
      admin_root_path
    else
      contracts_path
    end
  end

  private

  def set_admin_layout
    if controller_path.start_with?('admin') || (devise_controller? && resource_name == :admin)
      'admin'
    else
      'application'
    end
  end

  def set_notifications
    # ユーザーが作成した契約書のみを取得（admin_only: falseまたはnilのもの）
    user_contracts = current_user.contracts.where("admin_only IS NULL OR admin_only = ?", false)
    
    @expiring_contracts = user_contracts.where("expiration_date BETWEEN ? AND ?", Date.today, Date.today + 30)
    @renewal_contracts = user_contracts.where("renewal_date BETWEEN ? AND ?", Date.today, Date.today + 7)
    
    # コメント通知とグループ参加申請通知を取得
    @comment_notifications = current_user.comment_notifications.unread.order(created_at: :desc).limit(10)
    
    # グループ参加申請の通知数を取得
    @group_join_request_count = current_user.comment_notifications.unread.where(notifiable_type: 'GroupJoinRequest').count
    
    @notification_count = @expiring_contracts.size + @renewal_contracts.size + @comment_notifications.size
  end
end
