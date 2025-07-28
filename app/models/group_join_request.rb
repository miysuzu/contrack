class GroupJoinRequest < ApplicationRecord
  belongs_to :user
  belongs_to :group

  enum status: { pending: 'pending', approved: 'approved', rejected: 'rejected' }

  validates :user_id, uniqueness: { scope: :group_id, message: 'はすでに申請済みです' }
  validates :status, presence: true
end
