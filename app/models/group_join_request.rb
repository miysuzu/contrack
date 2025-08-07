class GroupJoinRequest < ApplicationRecord
  belongs_to :user
  belongs_to :group

  enum status: { pending: 'pending', approved: 'approved', rejected: 'rejected' }

  validates :user_id, uniqueness: { scope: :group_id, message: 'はすでに申請済みです' }
  validates :status, presence: true

  after_create :notify_group_creator

  private

  def notify_group_creator
    # 管理者が作成したグループの場合、その会社の管理者に通知を送信
    if group.admin_created? && group.company.present?
      # 会社の管理者を取得（最初の管理者に通知）
      admin = group.company.admins.first
      if admin
        CommentNotification.create!(
          user: nil,
          admin: admin,
          comment: nil,
          notifiable: self,
          message: "#{user.name}さんがグループ「#{group.name}」への参加を申請しました",
          read: false
        )
      end
    # ユーザーが作成したグループの場合、グループ作成者に通知を送信
    elsif group.user.present?
      CommentNotification.create!(
        user: group.user,
        admin: nil,
        comment: nil,
        notifiable: self,
        message: "#{user.name}さんがグループ「#{group.name}」への参加を申請しました",
        read: false
      )
    end
  end
end
