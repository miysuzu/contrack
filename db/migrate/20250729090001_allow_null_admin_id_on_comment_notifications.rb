class AllowNullAdminIdOnCommentNotifications < ActiveRecord::Migration[6.1]
  def change
    change_column_null :comment_notifications, :admin_id, true
  end
end
