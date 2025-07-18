class Admin::SearchController < ApplicationController
  layout "admin"
  before_action :authenticate_admin!

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
    @contracts = Contract.includes(:user, :status).all
    
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