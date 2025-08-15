class Admin::SearchController < Admin::ApplicationController
  layout "admin"

  def index
    @search_type = params[:search_type] || "users"
    @keyword = params[:keyword]

    if @search_type == "users"
      search_users
    else
      search_contracts
    end
  end

  private

  def search_users
    @users = User.all
    
    if @keyword.present?
      keyword = "%#{@keyword}%"
      @users = @users.where("name LIKE ? OR email LIKE ?", keyword, keyword)
    end
    
    @users = @users.order(created_at: :desc)
  end

  def search_contracts
    # 管理者の会社の契約書のみを表示
    @contracts = current_admin.company ? 
      Contract.includes(:user, :status).where(company_id: current_admin.company_id) :
      Contract.none
    
    if @keyword.present?
      keyword = "%#{@keyword}%"
      @contracts = @contracts.where("title LIKE ? OR body LIKE ?", keyword, keyword)
    end
    
    # ステータス絞り込み
    @contracts = @contracts.where(status_id: params[:status_id]) if params[:status_id].present?
    
    # タグ絞り込み
    @contracts = @contracts.tagged_with(params[:tag]) if params[:tag].present?
    
    @contracts = @contracts.order(created_at: :desc)
  end
end 