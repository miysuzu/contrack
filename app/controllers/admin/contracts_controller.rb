class Admin::ContractsController < ApplicationController
  layout 'admin'

  before_action :authenticate_admin!

  def index
    @contracts = Contract.includes(:user, :status)

    # キーワード検索
    if params[:keyword].present?
      keyword = "%#{params[:keyword]}%"
      @contracts = @contracts.where("title LIKE ? OR body LIKE ?", keyword, keyword)
    end

    # タグ絞り込み
    @contracts = @contracts.tagged_with(params[:tag]) if params[:tag].present?

    # ステータス絞り込み
    @contracts = @contracts.where(status_id: params[:status_id]) if params[:status_id].present?

    @contracts = @contracts.order(created_at: :desc)
  end

  def show
    @contract = Contract.find(params[:id])
  end

  def destroy
    @contract = Contract.find(params[:id])
    @contract.destroy
    redirect_to admin_contracts_path, notice: "契約を削除しました。"
  end
end
