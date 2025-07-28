class Users::PasswordsController < Devise::PasswordsController
  def create
    self.resource = resource_class.send_reset_password_instructions(resource_params)
    yield resource if block_given?

    if successfully_sent?(resource)
      token = resource.send(:set_reset_password_token)
      edit_password_url = edit_user_password_url(reset_password_token: token)

      mail_body = <<~MAIL
        #{resource.name || 'ユーザー'}様

        パスワード再設定のリクエストを受け付けました。

        下記URLから、パスワードを再設定してください：

        #{edit_password_url}

        ※有効期限を過ぎると無効になります。お早めにご対応ください。
      MAIL

      flash[:password_email_preview] = mail_body
      respond_with({}, location: new_session_path(resource_name))
    else
      respond_with(resource)
    end
  end
end
