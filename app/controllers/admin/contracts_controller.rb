class Admin::ContractsController < Admin::ApplicationController
  include SlackMessageHelper
  
  layout 'admin'
  before_action :set_contract, only: [:show, :edit, :update, :destroy]

  def index
    # 管理者の会社の契約書のみを表示（管理者作成の契約書も含む）
    @contracts = current_admin.company ? 
      Contract.includes(:user, :status, :group).where(company_id: current_admin.company_id) :
      Contract.none

    # キーワード検索
    if params[:contract] && params[:contract][:user_id]&.start_with?('admin_')
      contract_params_with_admin = contract_params
      contract_params_with_admin[:user_id] = nil                  # userなし
      @contract = Contract.new(contract_params_with_admin)
      @contract.admin = current_admin                             # adminに紐付け
    elsif params[:contract]
      @contract = Contract.new(contract_params)
    else
      @contract = Contract.new
    end

    # タグ絞り込み
    @contracts = @contracts.tagged_with(params[:tag]) if params[:tag].present?

    # ステータス絞り込み
    @contracts = @contracts.where(status_id: params[:status_id]) if params[:status_id].present?

    # グループ絞り込み
    @contracts = @contracts.where(group_id: params[:group_id]) if params[:group_id].present?

    # 並び順
    case params[:sort]
    when "created_desc"
      @contracts = @contracts.order(created_at: :desc)
    when "created_asc"
      @contracts = @contracts.order(created_at: :asc)
    when "updated_desc"
      @contracts = @contracts.order(renewal_date: :desc, created_at: :desc)
    when "updated_asc"
      @contracts = @contracts.order(renewal_date: :asc, created_at: :desc)
    when "expiration_asc"
      @contracts = @contracts.order(expiration_date: :asc, created_at: :desc)
    when "expiration_desc"
      @contracts = @contracts.order(expiration_date: :desc, created_at: :desc)
    when "title_asc"
      @contracts = @contracts.order(:title)
    else
      @contracts = @contracts.order(created_at: :desc) 
    end

    @contracts = @contracts.page(params[:page]).per(20)
  end

  def show
  end

  def new
    @contract = Contract.new
    # 管理者の会社のグループのみを取得（名前順）
    @groups = current_admin.company ? Group.where(company_id: current_admin.company_id).order(:name) : Group.none
    # 管理者の会社のユーザーリストを取得（管理者も含める）
    @users = current_admin.company ? current_admin.company.users.order(:name) : User.none
    # 管理者をユーザーリストに追加（仮想的なユーザーとして）
    if current_admin.company
      admin_user = OpenStruct.new(id: "admin_#{current_admin.id}", name: "管理者（#{current_admin.email}）")
      @users = [admin_user] + @users.to_a
    end
  end

  def create
    contract_params_with_admin = contract_params
  
    if params[:contract][:user_id]&.start_with?('admin_')
      Rails.logger.info "DEBUG: 管理者による作成 - user_id を nil に設定"
      contract_params_with_admin[:user_id] = nil
    end
  
    @contract = Contract.new(contract_params_with_admin)
  
    if params[:contract][:user_id]&.start_with?('admin_')
      @contract.admin = current_admin
      # admin_only フラグはフォームのチェックボックスで制御
      @contract.admin_only = params[:contract][:admin_only] == '1'
    end
  
    @contract.company = current_admin.company if current_admin.company
  
    Rails.logger.info "DEBUG: user_id=#{@contract.user_id.inspect}, admin_id=#{@contract.admin_id.inspect}"
  
    if @contract.save
      redirect_to admin_contract_path(@contract), notice: "契約書を作成しました。"
    else
      Rails.logger.error "Contract save failed: #{@contract.errors.full_messages.join(', ')}"
      @groups = current_admin.company ? Group.where(company_id: current_admin.company_id).order(:name) : Group.none
      @users = current_admin.company ? current_admin.company.users.order(:name) : User.none
      if current_admin.company
        admin_user = OpenStruct.new(id: "admin_#{current_admin.id}", name: "管理者（#{current_admin.email}）")
        @users = [admin_user] + @users.to_a
      end
      render :new
    end
  end
  

  def edit
    # 管理者の会社のグループのみを取得（名前順）
    @groups = current_admin.company ? Group.where(company_id: current_admin.company_id).order(:name) : Group.none
    # 管理者の会社のユーザーリストを取得（管理者も含める）
    @users = current_admin.company ? current_admin.company.users.order(:name) : User.none
    # 管理者をユーザーリストに追加（仮想的なユーザーとして）
    if current_admin.company
      admin_user = OpenStruct.new(id: "admin_#{current_admin.id}", name: "管理者（#{current_admin.email}）")
      @users = [admin_user] + @users.to_a
    end
  end

  def update
    contract_params_with_admin = contract_params
  
    if params[:contract][:user_id]&.start_with?('admin_')
      contract_params_with_admin[:user_id] = nil
      @contract.admin = current_admin
      # admin_only フラグはフォームのチェックボックスで制御
      @contract.admin_only = params[:contract][:admin_only] == '1'
    end
  
    if @contract.update(contract_params_with_admin)
      redirect_to admin_contract_path(@contract), notice: "契約書を更新しました。"
    else
      @groups = current_admin.company ? Group.where(company_id: current_admin.company_id).order(:name) : Group.none
      @users = current_admin.company ? current_admin.company.users.order(:name) : User.none
      if current_admin.company
        admin_user = OpenStruct.new(id: "admin_#{current_admin.id}", name: "管理者（#{current_admin.email}）")
        @users = [admin_user] + @users.to_a
      end
      render :edit
    end
  end  

  def destroy
    @contract.destroy
    redirect_to admin_contracts_path, notice: "契約を削除しました。"
  end

  def slack_message
    @contract = Contract.find(params[:id])
    message_type = params[:type] || 'default'
    slack_message = generate_slack_message_for_contract(@contract, message_type)
    render plain: slack_message
  end

  private

  def set_contract
    @contract = Contract.find(params[:id])
    # 管理者の会社の契約書以外にはアクセスできないようにする
    unless current_admin.company && @contract.company_id == current_admin.company_id
      redirect_to admin_contracts_path, alert: "アクセス権限がありません"
    end
  end

  def contract_params
    params.require(:contract).permit(:title, :body, :status_id, :tag_list, :expiration_date, :renewal_date, :user_id, :group_id, :conclusion_date, :admin_only, attachments: [])
  end
end