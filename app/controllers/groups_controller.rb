class GroupsController < ApplicationController
  before_action :authenticate_user!
  def index
    @groups = current_user.company ? current_user.company.groups : []
  end

  def show
    @group = Group.find(params[:id])
    # 自分の会社のグループ以外にはアクセスできないようにする
    unless current_user.company && @group.company_id == current_user.company_id
      redirect_to group_searches_path, alert: 'アクセス権限がありません。'
    end
  end

  def new
    @group = Group.new
    # 同じ会社のユーザーを取得（自分以外）
    @company_users = current_user.company ? current_user.company.users.where.not(id: current_user.id) : []
  end

  def create
    @group = Group.new(group_params)
    @group.user = current_user
    @group.company = current_user.company if current_user.company
    
    if @group.save
      @group.users << current_user  # 作成者を所属させる
      
      # 招待されたユーザーをグループに追加
      if params[:group][:invited_user_ids].present?
        invited_user_ids = params[:group][:invited_user_ids].reject(&:blank?)
        invited_users = User.where(id: invited_user_ids, company: current_user.company)
        @group.users << invited_users
      end
      
      redirect_to @group, notice: 'グループを作成しました。'
    else
      # 同じ会社のユーザーを再取得
      @company_users = current_user.company ? current_user.company.users.where.not(id: current_user.id) : []
      render :new
    end
  end

  def edit
    @group = Group.find(params[:id])
    # 自分の会社のグループ以外にはアクセスできないようにする
    unless current_user.company && @group.company_id == current_user.company_id
      redirect_to group_searches_path, alert: 'アクセス権限がありません。'
      return
    end
    unless @group.users.include?(current_user)
      redirect_to group_searches_path, alert: '編集権限がありません。'
      return
    end
    
    # 同じ会社のユーザーを取得（グループに所属していないユーザー）
    @company_users = current_user.company ? 
      current_user.company.users.where.not(id: @group.user_ids) : []
  end

  def update
    @group = Group.find(params[:id])
    # 自分の会社のグループ以外にはアクセスできないようにする
    unless current_user.company && @group.company_id == current_user.company_id
      redirect_to group_searches_path, alert: 'アクセス権限がありません。'
      return
    end
    unless @group.users.include?(current_user)
      redirect_to group_searches_path, alert: '編集権限がありません。'
      return
    end
    
    if @group.update(group_params)
      # メンバーの追加
      if params[:group][:add_user_ids].present?
        add_user_ids = params[:group][:add_user_ids].reject(&:blank?)
        add_users = User.where(id: add_user_ids, company: current_user.company)
        @group.users << add_users
      end
      
      # メンバーの削除
      if params[:group][:remove_user_ids].present?
        remove_user_ids = params[:group][:remove_user_ids].reject(&:blank?)
        # 自分自身は削除できないようにする
        remove_user_ids = remove_user_ids.reject { |id| id.to_i == current_user.id }
        remove_users = User.where(id: remove_user_ids)
        @group.users.delete(remove_users)
      end
      
      redirect_to @group, notice: 'グループを更新しました。'
    else
      # 同じ会社のユーザーを再取得
      @company_users = current_user.company ? 
        current_user.company.users.where.not(id: @group.user_ids) : []
      render :edit
    end
  end

  def destroy
    @group = Group.find(params[:id])
    # 自分の会社のグループ以外にはアクセスできないようにする
    unless current_user.company && @group.company_id == current_user.company_id
      redirect_to group_searches_path, alert: 'アクセス権限がありません。'
      return
    end
    unless @group.users.include?(current_user)
      redirect_to group_searches_path, alert: '削除権限がありません。'
      return
    end
    @group.contracts.each(&:destroy)
    @group.group_users.destroy_all
    @group.destroy
    redirect_to group_searches_path, notice: 'グループを削除しました。'
  end

  def leave
    @group = Group.find(params[:id])
    # 自分の会社のグループ以外にはアクセスできないようにする
    unless current_user.company && @group.company_id == current_user.company_id
      redirect_to group_searches_path, alert: 'アクセス権限がありません。'
      return
    end
    if @group.users.include?(current_user)
      @group.users.delete(current_user)
      
      # グループ脱退時にGroupJoinRequestレコードも削除
      GroupJoinRequest.where(user: current_user, group: @group).destroy_all
      
      redirect_to group_searches_path, notice: 'グループから脱退しました。'
    else
      redirect_to group_searches_path, alert: 'このグループには所属していません。'
    end
  end

  private

  def group_params
    params.require(:group).permit(:name, :description)
  end
end
