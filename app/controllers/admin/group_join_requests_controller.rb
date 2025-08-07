class Admin::GroupJoinRequestsController < ApplicationController
  before_action :authenticate_admin!
  layout 'admin'

  def index
    # 管理者の会社のグループへの申請一覧を表示
    @requests = GroupJoinRequest.joins(:group)
                               .where(groups: { company_id: current_admin.company_id, admin_created: true }, status: :pending)
                               .order(created_at: :desc)
  end

  def approve
    request = GroupJoinRequest.find(params[:id])
    # 管理者の会社のグループ以外には承認できないようにする
    unless current_admin.company && request.group.company_id == current_admin.company_id && request.group.admin_created?
      redirect_to admin_group_join_requests_path, alert: 'アクセス権限がありません。'
      return
    end
    
    if request.pending?
      request.update(status: :approved)
      # 承認時にグループに所属させる
      GroupUser.create(user: request.user, group: request.group)
      
      # 申請者に承認通知を送信
      CommentNotification.create!(
        user: request.user,
        admin: nil,
        comment: nil,
        notifiable: request,
        message: "グループ「#{request.group.name}」への参加申請が管理者により承認されました",
        read: false
      )
      
      # 管理者が受け取った申請通知を削除（申請者への通知は残す）
      CommentNotification.where(notifiable: request, admin: current_admin).destroy_all
      redirect_to admin_group_join_requests_path, notice: '申請を承認しました。'
    else
      redirect_to admin_group_join_requests_path, alert: '承認できません。'
    end
  end

  def reject
    request = GroupJoinRequest.find(params[:id])
    # 管理者の会社のグループ以外には拒否できないようにする
    unless current_admin.company && request.group.company_id == current_admin.company_id && request.group.admin_created?
      redirect_to admin_group_join_requests_path, alert: 'アクセス権限がありません。'
      return
    end
    
    if request.pending?
      request.update(status: :rejected)
      
      # 申請者に拒否通知を送信
      CommentNotification.create!(
        user: request.user,
        admin: nil,
        comment: nil,
        notifiable: request,
        message: "グループ「#{request.group.name}」への参加申請が管理者により拒否されました",
        read: false
      )
      
      # 管理者が受け取った申請通知を削除（申請者への通知は残す）
      CommentNotification.where(notifiable: request, admin: current_admin).destroy_all
      redirect_to admin_group_join_requests_path, notice: '申請を拒否しました。'
    else
      redirect_to admin_group_join_requests_path, alert: '拒否できません。'
    end
  end
end 