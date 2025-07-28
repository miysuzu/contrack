class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: [:show, :edit, :update, :unsubscribe, :withdraw]

  def show
    @contracts = @user.contracts.order(created_at: :desc).page(params[:page]).per(15)
  end

  def edit
  end

  def update
    if @user.update(user_params)
      redirect_to user_mypage_path, notice: "会員情報を更新しました"
    else
      render :edit
    end
  end

  def unsubscribe
  end

  def withdraw
    @user.update(is_active: false)
    sign_out @user
    redirect_to root_path, notice: "退会処理が完了しました。ご利用ありがとうございました。"
  end

  private

  def set_user
    @user = current_user
  end

  def user_params
    params.require(:user).permit(:name, :email)
  end
end
