class GroupJoinRequest < ApplicationRecord
  belongs_to :user
  belongs_to :group

  enum status: { pending: 'pending', approved: 'approved', rejected: 'rejected' }

  validates :user_id, uniqueness: { scope: :group_id, message: 'はすでに申請済みです' }
  validates :status, presence: true

  after_create :notify_group_creator

  private

  def notify_group_creator
    return unless group.user.present?
    
    # グループ作成者に通知を送信
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
