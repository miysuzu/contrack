class Admin::ApplicationController < ApplicationController
  before_action :authenticate_admin!
  before_action :set_notification_data
  layout 'admin'

  private

  def set_notification_data
    if admin_signed_in?
      # 管理者の会社に属する契約書のみを取得
      company_contracts = if current_admin.company
        Contract.where(company_id: current_admin.company_id)
      else
        Contract.none
      end

      # 満了日30日以内の契約書
      @expiring_contracts = company_contracts.where('expiration_date <= ? AND expiration_date >= ?', 
                                         30.days.from_now, Date.current)
                                   .order(:expiration_date)
                                   .limit(10)

      # 更新日7日以内の契約書
      @renewal_contracts = company_contracts.where('renewal_date <= ? AND renewal_date >= ?', 
                                        7.days.from_now, Date.current)
                                  .order(:renewal_date)
                                  .limit(10)

      # コメント通知を取得
      @comment_notifications = current_admin.comment_notifications.unread.order(created_at: :desc).limit(10)
      
      # 通知件数
      @notification_count = @expiring_contracts.count + @renewal_contracts.count + @comment_notifications.count
    else
      @expiring_contracts = []
      @renewal_contracts = []
      @comment_notifications = []
      @notification_count = 0
    end
  end
end 