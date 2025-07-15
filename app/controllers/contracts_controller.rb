class ContractsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_contract, only: [:show, :edit, :update, :destroy]

  def index
    @contracts = current_user.contracts
  
    # キーワード検索（タイトル or 本文）
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
  end

  def new
    @contract = Contract.new
  end

  def create
    @contract = current_user.contracts.build(contract_params)
    if @contract.save
      redirect_to @contract, notice: "契約書を作成しました。"
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @contract.update(contract_params)
      redirect_to @contract, notice: "契約書を更新しました。"
    else
      render :edit
    end
  end

  def destroy
    @contract.destroy
    redirect_to contracts_path, notice: "契約書を削除しました。"
  end

  private

  def set_contract
    @contract = current_user.contracts.find(params[:id])
  end

  def contract_params
    params.require(:contract).permit(:title, :body, :status_id, :tag_list)
  end  
end
