class Admin::GroupsController < Admin::ApplicationController
  layout 'admin'
  before_action :reject_user_login

  def index
    # 管理者の会社のグループのみを表示（管理者作成のグループも含む）
    if current_admin.company
      @groups = Group.where(company_id: current_admin.company_id).order(:created_at)
    else
      @groups = Group.none
      flash.now[:alert] = "会社に所属していません。グループ管理機能を使用するには会社に所属する必要があります。"
    end
  end

  def show
    @group = Group.find(params[:id])
    # 管理者の会社のグループ以外にはアクセスできないようにする
    unless current_admin.company && @group.company_id == current_admin.company_id
      redirect_to admin_groups_path, alert: "アクセス権限がありません"
    end
  end

  def new
    @group = Group.new
    # 管理者が所属する会社のユーザーを取得
    @company_users = current_admin.company ? current_admin.company.users : []
  end

  def edit
    @group = Group.find(params[:id])
    # 管理者の会社のグループ以外にはアクセスできないようにする
    unless current_admin.company && @group.company_id == current_admin.company_id
      redirect_to admin_groups_path, alert: "アクセス権限がありません"
      return
    end
    # 同じ会社のユーザーを取得（グループに所属していないユーザー）
    @company_users = @group.company ? 
      @group.company.users.where.not(id: @group.user_ids) : []
  end

  def create
    @group = Group.new(group_params)
    @group.company = current_admin.company if current_admin.company
    @group.admin_created = true  # 管理者が作成したグループとしてマーク
    
    if @group.save
      # 管理者はメンバーとして参加しない（管理権限のみ）
      
      # 招待されたユーザーをグループに追加
      if params[:group][:invited_user_ids].present?
        invited_user_ids = params[:group][:invited_user_ids].reject(&:blank?)
        invited_users = User.where(id: invited_user_ids, company: current_admin.company)
        @group.users << invited_users
      end
      
      redirect_to admin_group_path(@group), notice: 'グループを作成しました。'
    else
      # 同じ会社のユーザーを再取得
      @company_users = current_admin.company ? current_admin.company.users : []
      render :new
    end
  end

  def update
    @group = Group.find(params[:id])
    # 管理者の会社のグループ以外は更新できない
    unless current_admin.company && @group.company_id == current_admin.company_id
      redirect_to admin_groups_path, alert: "アクセス権限がありません"
      return
    end
    
    if @group.update(group_params)
      # メンバーの追加
      if params[:group][:add_user_ids].present?
        add_user_ids = params[:group][:add_user_ids].reject(&:blank?)
        add_users = User.where(id: add_user_ids, company: @group.company)
        @group.users << add_users
      end
      
      # メンバーの削除
      if params[:group][:remove_user_ids].present?
        remove_user_ids = params[:group][:remove_user_ids].reject(&:blank?)
        remove_users = User.where(id: remove_user_ids)
        @group.users.delete(remove_users)
      end
      
      redirect_to admin_group_path(@group), notice: 'グループを更新しました。'
    else
      # 同じ会社のユーザーを再取得
      @company_users = @group.company ? 
        @group.company.users.where.not(id: @group.user_ids) : []
      render :edit
    end
  end

  def destroy
    @group = Group.find(params[:id])
    # 管理者の会社のグループ以外は削除できない
    unless current_admin.company && @group.company_id == current_admin.company_id
      redirect_to admin_groups_path, alert: "アクセス権限がありません"
      return
    end
    # グループに属する契約書のgroup_idをnullに設定（削除せずに保持）
    @group.contracts.update_all(group_id: nil)
    @group.group_users.destroy_all
    @group.destroy
    redirect_to admin_groups_path, notice: 'グループを削除しました。'
  end

  private

  def group_params
    params.require(:group).permit(:name, :description)
  end

  def require_admin
    redirect_to root_path, alert: "管理者権限が必要です" unless current_user&.admin?
  end

  # Userモデルでログインしている場合は管理者画面にアクセスできないようにする
  def reject_user_login
    if user_signed_in?
      sign_out(current_user)
      redirect_to root_path, alert: '管理者専用画面です。' and return
    end
  end
end
