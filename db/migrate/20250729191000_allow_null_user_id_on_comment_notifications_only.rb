class AllowNullUserIdOnCommentNotificationsOnly < ActiveRecord::Migration[6.1]
  def change
    change_column_null :comment_notifications, :user_id, true
  end
end 