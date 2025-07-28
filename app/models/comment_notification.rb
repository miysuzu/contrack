class CommentNotification < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :admin, optional: true
  belongs_to :comment
  
  validates :read, inclusion: { in: [true, false] }
  
  scope :unread, -> { where(read: false) }
  scope :read, -> { where(read: true) }
  
  def mark_as_read!
    update!(read: true)
  end
end
