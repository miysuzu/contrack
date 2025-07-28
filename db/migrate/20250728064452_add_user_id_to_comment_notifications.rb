class AddUserIdToCommentNotifications < ActiveRecord::Migration[6.1]
  def change
    add_reference :comment_notifications, :user, null: false, foreign_key: true
  end
end
