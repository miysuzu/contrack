class CommentNotificationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_notification, only: [:mark_as_read]

  def mark_as_read
    @notification.mark_as_read!
    redirect_back(fallback_location: contracts_path)
  end

  def mark_all_as_read
    current_user.comment_notifications.unread.update_all(read: true)
    redirect_back(fallback_location: contracts_path)
  end

  private

  def set_notification
    @notification = current_user.comment_notifications.find(params[:id])
  end
end 