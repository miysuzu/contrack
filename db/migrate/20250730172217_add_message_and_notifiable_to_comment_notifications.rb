class AddMessageAndNotifiableToCommentNotifications < ActiveRecord::Migration[6.1]
  def change
    add_column :comment_notifications, :message, :text
    add_reference :comment_notifications, :notifiable, null: true, polymorphic: true
  end
end
