class GroupJoinRequestsController < ApplicationController
  before_action :authenticate_user!

  def index
    # 自分が作成したグループへの申請一覧
    @requests = GroupJoinRequest.joins(:group).where(groups: { user_id: current_user.id }, status: :pending)
  end

  def create
    group = Group.find(params[:group_id])
    # 自分の会社のグループ以外には参加申請できないようにする
    unless current_user.company && group.company_id == current_user.company_id
      redirect_to group_searches_path, alert: 'アクセス権限がありません。'
      return
    end
    request = GroupJoinRequest.new(user: current_user, group: group, status: :pending)
    if request.save
      redirect_to group_searches_path, notice: '参加申請を送信しました。'
    else
      redirect_to group_searches_path, alert: request.errors.full_messages.to_sentence
    end
  end

  def approve
    request = GroupJoinRequest.find(params[:id])
    # 自分の会社のグループ以外には承認できないようにする
    unless current_user.company && request.group.company_id == current_user.company_id
      redirect_to group_join_requests_path, alert: 'アクセス権限がありません。'
      return
    end
    if request.group.user_id == current_user.id && request.pending?
      request.update(status: :approved)
      # 承認時にグループに所属させる
      GroupUser.create(user: request.user, group: request.group)
      redirect_to group_join_requests_path, notice: '申請を承認しました。'
    else
      redirect_to group_join_requests_path, alert: '承認できません。'
    end
  end

  def reject
    request = GroupJoinRequest.find(params[:id])
    # 自分の会社のグループ以外には拒否できないようにする
    unless current_user.company && request.group.company_id == current_user.company_id
      redirect_to group_join_requests_path, alert: 'アクセス権限がありません。'
      return
    end
    if request.group.user_id == current_user.id && request.pending?
      request.update(status: :rejected)
      redirect_to group_join_requests_path, notice: '申請を拒否しました。'
    else
      redirect_to group_join_requests_path, alert: '拒否できません。'
    end
  end
end
