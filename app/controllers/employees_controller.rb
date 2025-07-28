class EmployeesController < ApplicationController
  before_action :authenticate_admin!

  def invite
  end

  def create_invite
    email = params[:email]
    password = Devise.friendly_token.first(10)
    user = User.new(email: email, name: '未設定', password: password, password_confirmation: password, company_id: current_admin.company_id)
    if user.save
      mail_body = <<~MAIL
        #{user.name || '従業員'}様

        会社への招待を受け付けました。
        ログインメールアドレス: #{user.email}
        初期パスワード: #{password}
        ログインURL: #{new_user_session_url}

        ※初回ログイン後、パスワードを変更してください。
      MAIL
      flash[:notice] = "招待しました。"
      flash[:invite_email_preview] = mail_body
    else
      flash[:alert] = user.errors.full_messages.to_sentence
    end
    redirect_to invite_employees_path
  end
end
