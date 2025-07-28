class ContractsController < ApplicationController
  include SlackMessageHelper
  
  before_action :authenticate_user!
  before_action :set_contract, only: [:show, :edit, :update, :destroy]
  before_action :ensure_owner!, only: [:edit, :update, :destroy]

  def index
    # ユーザーの契約書と会社の契約書（管理者作成を含む）を取得
    @contracts = if current_user.company
      Contract.where(company_id: current_user.company_id, admin_only: false)
    else
      current_user.contracts.where(admin_only: false)
    end
  
    # キーワード検索（タイトル or 本文）
    if params[:keyword].present?
      keyword = "%#{params[:keyword]}%"
      @contracts = @contracts.where("title LIKE ? OR body LIKE ?", keyword, keyword)
    end
  
    # タグ絞り込み
    @contracts = @contracts.tagged_with(params[:tag]) if params[:tag].present?
  
    # ステータス絞り込み
    @contracts = @contracts.where(status_id: params[:status_id]) if params[:status_id].present?

    # グループ絞り込み
    if params[:group_id].present?
      @contracts = @contracts.where(group_id: params[:group_id])
      Rails.logger.info "グループフィルター適用: group_id=#{params[:group_id]}"
    end
  
    # 並び順
    case params[:sort]
    when "created_asc"
      @contracts = @contracts.order(created_at: :asc)
    when "updated_desc"
      @contracts = @contracts.order(updated_at: :desc)
    when "updated_asc"
      @contracts = @contracts.order(updated_at: :asc)
    when "expiration_asc"
      @contracts = @contracts.order(expiration_date: :asc).where.not(expiration_date: nil)
    when "expiration_desc"
      @contracts = @contracts.order(expiration_date: :desc).where.not(expiration_date: nil)
    when "title_asc"
      @contracts = @contracts.order(:title)
    else
      @contracts = @contracts.order(created_at: :desc) # デフォルト
    end

    @contracts = @contracts.page(params[:page]).per(15)
  end
  

  def show
    @slack_message = generate_slack_message_for_contract(@contract)
    # 各カテゴリのテンプレートを取得
    @slack_templates = {}
    %w[default created updated expiring renewal].each do |category|
      @slack_templates[category] = find_templates_for_category(@contract, category)
    end
  end

  def new
    @contract = Contract.new
    # ユーザーの会社のグループのみを取得
    @groups = current_user.company ? Group.where(company_id: current_user.company_id) : Group.none
  end

  def create
    @contract = current_user.contracts.build(contract_params)
    @contract.company = current_user.company if current_user.company
    if @contract.save
      if params[:contract][:shared_user_ids]
        @contract.shared_user_ids = params[:contract][:shared_user_ids].reject(&:blank?)
      end
      redirect_to contract_path(@contract), notice: "契約書を作成しました。"
    else
      # エラー時に@groupsを再設定
      @groups = current_user.company ? Group.where(company_id: current_user.company_id) : Group.none
      render :new
    end
  end

  def edit
    # ユーザーの会社のグループのみを取得
    @groups = current_user.company ? Group.where(company_id: current_user.company_id) : Group.none
  end

  def update
    if @contract.update(contract_params)
      if params[:contract][:shared_user_ids]
        @contract.shared_user_ids = params[:contract][:shared_user_ids].reject(&:blank?)
      else
        @contract.shared_user_ids = []
      end
      redirect_to @contract, notice: "契約書を更新しました。"
    else
      # エラー時に@groupsを再設定
      @groups = current_user.company ? Group.where(company_id: current_user.company_id) : Group.none
      render :edit
    end
  end

  def destroy
    @contract.destroy
    redirect_to contracts_path, notice: "契約書を削除しました。"
  end

  def slack_message
    # ユーザーの契約書と会社の契約書（管理者作成を含む）から取得
    @contract = if current_user.company
      Contract.where(company_id: current_user.company_id, admin_only: false).find(params[:id])
    else
      current_user.contracts.where(admin_only: false).find(params[:id])
    end
    message_type = params[:type] || 'default'
    template_id = params[:template_id]
    
    if template_id.present?
      # 特定のテンプレートを使用
      template = current_user.company.slack_message_templates.find(template_id)
      slack_message = replace_variables(template.content, @contract)
    else
      # 従来の方法でメッセージ生成
      slack_message = generate_slack_message_for_contract(@contract, message_type)
    end
    
    render plain: slack_message
  end

  private

  def set_contract
    # ユーザーの契約書と会社の契約書（管理者作成を含む）から取得
    @contract = if current_user.company
      Contract.where(company_id: current_user.company_id, admin_only: false).find(params[:id])
    else
      current_user.contracts.where(admin_only: false).find(params[:id])
    end
  end

  def ensure_owner!
    # 管理者作成の契約書（userがnil）の場合は編集不可
    if @contract.user.nil?
      redirect_to contracts_path, alert: "管理者作成の契約書は編集できません。"
    elsif @contract.user != current_user
      redirect_to contracts_path, alert: "この操作を実行する権限がありません。"
    end
  end

  def contract_params
    params.require(:contract).permit(:title, :body, :status_id, :tag_list, :expiration_date, :renewal_date, :group_id, :conclusion_date, attachments: [])
  end

  def find_templates_for_category(contract, category)
    return [] unless contract.user&.company
    
    templates = contract.user.company.slack_message_templates.by_category(category)
    templates.order(:is_default, :name)
  end  
end
