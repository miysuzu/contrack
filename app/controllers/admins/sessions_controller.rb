# frozen_string_literal: true

class Admins::SessionsController < Devise::SessionsController
  layout "admin"

  protected

  # ログイン成功後の遷移先
  def after_sign_in_path_for(resource)
    admin_root_path
  end

  # ログアウト後の遷移先
  def after_sign_out_path_for(resource_or_scope)
    new_admin_session_path
  end

  # ログイン失敗時の遷移先（Deviseバージョンによっては不要な場合あり）
  def new
    super
  rescue
    redirect_to new_admin_session_path
  end
end 