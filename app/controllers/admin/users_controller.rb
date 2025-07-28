class Admin::UsersController < Admin::ApplicationController
  layout "admin"
  before_action :set_user, only: [:show, :edit, :update]

  def index
    # 管理者の会社の会員のみを表示
    if current_admin.company
      @users = current_admin.company.users
      
      # キーワード検索
      if params[:keyword].present?
        @users = @users.where("name LIKE ? OR email LIKE ?", "%#{params[:keyword]}%", "%#{params[:keyword]}%")
      end
      
      # ステータスフィルター
      if params[:status].present?
        case params[:status]
        when 'active'
          @users = @users.where(is_active: true)
        when 'inactive'
          @users = @users.where(is_active: false)
        end
      end
      
      @users = @users.order(created_at: :desc)
    else
      @users = []
      flash.now[:alert] = "会社に所属していません。会員管理機能を使用するには会社に所属する必要があります。"
    end
  end

  def show
    @contracts = @user.contracts.order(created_at: :desc)
  end

  def edit
  end

  def update
    # 管理者の会社の会員以外は更新できない
    unless current_admin.company && @user.company_id == current_admin.company_id
      redirect_to admin_users_path, alert: "アクセス権限がありません"
      return
    end
    
    if @user.update(user_params)
      redirect_to admin_user_path(@user), notice: "ユーザー情報を更新しました"
    else
      render :edit
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
    # 管理者の会社の会員以外にはアクセスできないようにする
    unless current_admin.company && @user.company_id == current_admin.company_id
      redirect_to admin_users_path, alert: "アクセス権限がありません"
    end
  end

  def user_params
    params.require(:user).permit(:name, :email, :is_active)
  end
end
