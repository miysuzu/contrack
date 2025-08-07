class GroupJoinRequestsController < ApplicationController
  before_action :authenticate_user!

  def index
    # 自分が作成したグループへの申請一覧のみ表示
    @requests = GroupJoinRequest.joins(:group).where(groups: { user_id: current_user.id }, status: :pending)
    
    # グループ作成者以外はアクセス不可
    unless current_user.groups.where(user_id: current_user.id).exists?
      redirect_to group_searches_path, alert: 'アクセス権限がありません。'
      return
    end
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
      
      # 申請者に承認通知を送信
      CommentNotification.create!(
        user: request.user,
        admin: nil,
        comment: nil,
        notifiable: request,
        message: "グループ「#{request.group.name}」への参加申請が承認されました",
        read: false
      )
      
      # グループ作成者が受け取った申請通知を削除（申請者への通知は残す）
      CommentNotification.where(notifiable: request, user: current_user).destroy_all
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
      
      # 申請者に拒否通知を送信
      CommentNotification.create!(
        user: request.user,
        admin: nil,
        comment: nil,
        notifiable: request,
        message: "グループ「#{request.group.name}」への参加申請が拒否されました",
        read: false
      )
      
      # グループ作成者が受け取った申請通知を削除（申請者への通知は残す）
      CommentNotification.where(notifiable: request, user: current_user).destroy_all
      redirect_to group_join_requests_path, notice: '申請を拒否しました。'
    else
      redirect_to group_join_requests_path, alert: '拒否できません。'
    end
  end

  def destroy
    request = GroupJoinRequest.find(params[:id])
    # 自分の申請のみ取り消し可能（pendingまたはrejected）
    if request.user_id == current_user.id && (request.pending? || request.rejected?)
      # 該当する通知を削除
      CommentNotification.where(notifiable: request).destroy_all
      request.destroy
      if request.rejected?
        redirect_to group_searches_path, notice: '拒否された申請を削除しました。再度申請できます。'
      else
        redirect_to group_searches_path, notice: '申請を取り消しました。'
      end
    else
      redirect_to group_searches_path, alert: '申請を取り消せません。'
    end
  end
end
