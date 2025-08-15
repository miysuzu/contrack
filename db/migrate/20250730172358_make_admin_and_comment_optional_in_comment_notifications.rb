class MakeAdminAndCommentOptionalInCommentNotifications < ActiveRecord::Migration[6.1]
  def change
    change_column_null :comment_notifications, :admin_id, true
    change_column_null :comment_notifications, :comment_id, true
  end
end
