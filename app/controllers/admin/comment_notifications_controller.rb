                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            class Admin::CommentNotificationsController < Admin::ApplicationController
  before_action :set_notification, only: [:mark_as_read]

  def mark_as_read
    @notification.mark_as_read!
    redirect_back(fallback_location: admin_contracts_path)
  end

  def mark_all_as_read
    current_admin.comment_notifications.unread.update_all(read: true)
    redirect_back(fallback_location: admin_contracts_path)
  end

  private

  def set_notification
    @notification = current_admin.comment_notifications.find(params[:id])
  end
end 