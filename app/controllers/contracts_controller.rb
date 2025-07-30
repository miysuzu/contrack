class ContractsController < ApplicationController
  include SlackMessageHelper
  
  before_action :authenticate_user!
  before_action :set_contract, only: [:show, :edit, :update, :destroy]
  before_action :ensure_owner!, only: [:edit, :update, :destroy]

  def index
    # 所属グループのIDのみ取得
    group_ids = current_user.groups.pluck(:id)
  
    # ビュー用：所属グループ一覧のみ
    @groups = current_user.groups
  
    # 選択されたグループが自分の所属グループか確認して取得
    @selected_group = current_user.groups.find_by(id: params[:group_id]) if params[:group_id].present?
  
    # 契約書一覧（自分が作成 or 所属グループの契約書）
    @contracts = Contract.where(
      Contract.arel_table[:user_id].eq(current_user.id)
      .or(Contract.arel_table[:group_id].in(group_ids))
    )
  
    # 特定グループでさらに絞り込み（所属している場合のみ）
    if @selected_group
      @contracts = @contracts.where(group_id: @selected_group.id)
    end
  
    # キーワード検索
    if params[:keyword].present?
      keyword = "%#{params[:keyword]}%"
      @contracts = @contracts.where("title LIKE ? OR body LIKE ?", keyword, keyword)
    end
  
    # タグ・ステータス絞り込み
    @contracts = @contracts.tagged_with(params[:tag]) if params[:tag].present?
    @contracts = @contracts.where(status_id: params[:status_id]) if params[:status_id].present?
  
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
  
    @contracts = @contracts.page(params[:page]).per(15)
  end  

  def show
    @slack_message = generate_slack_message_for_contract(@contract)

    # Slackテンプレート（カテゴリ別）を取得
    @slack_templates = {}
    %w[default created updated expiring renewal].each do |category|
      @slack_templates[category] = find_templates_for_category(@contract, category)
    end
  end

  def new
    @contract = Contract.new
    @groups = current_user.company ? Group.where(company_id: current_user.company_id) : Group.none
  end

  def create
    # ログイン中のユーザーに紐づけて契約書を作成
    @contract = current_user.contracts.build(contract_params)
    @contract.company = current_user.company if current_user.company

    if @contract.save
      if params[:contract][:shared_user_ids]
        @contract.shared_user_ids = params[:contract][:shared_user_ids].reject(&:blank?)
      end
      redirect_to contract_path(@contract), notice: "契約書を作成しました。"
    else
      @groups = current_user.company ? Group.where(company_id: current_user.company_id) : Group.none
      render :new
    end
  end

  def edit
    @groups = current_user.company ? Group.where(company_id: current_user.company_id) : Group.none
  end

  def update
    if @contract.update(contract_params)
      if params[:contract][:shared_user_ids]
        @contract.shared_user_ids = params[:contract][:shared_user_ids].reject(&:blank?)
      else
        @contract.shared_user_ids = []
      end
      redirect_to contract_path(@contract), notice: "契約書を更新しました。"
    else
      @groups = current_user.company ? Group.where(company_id: current_user.company_id) : Group.none
      render :edit
    end
  end

  def destroy
    @contract.destroy
    redirect_to contracts_path, notice: "契約書を削除しました。"
  end

  def slack_message
    group_ids = current_user.groups.pluck(:id)

    # slack_message も同様に、会員が見てよい契約書に限定
    @contract = Contract.where(
      Contract.arel_table[:user_id].eq(current_user.id)
      .or(Contract.arel_table[:group_id].in(group_ids))
    ).find(params[:id])

    message_type = params[:type] || 'default'
    template_id = params[:template_id]

    if template_id.present?
      template = current_user.company.slack_message_templates.find(template_id)
      slack_message = replace_variables(template.content, @contract)
    else
      slack_message = generate_slack_message_for_contract(@contract, message_type)
    end

    render plain: slack_message
  end

  private

  def set_contract
    group_ids = current_user.groups.pluck(:id)

    # show/edit/update/destroy で取得できる契約書も同じく絞り込み
    @contract = Contract.where(
      Contract.arel_table[:user_id].eq(current_user.id)
      .or(Contract.arel_table[:group_id].in(group_ids))
    ).find(params[:id])
  end

  def ensure_owner!
    # 管理者作成（user_idがnil）は編集不可
    if @contract.user.nil?
      redirect_to contracts_path, alert: "管理者作成の契約書は編集できません。"
    elsif @contract.user != current_user
      redirect_to contracts_path, alert: "この操作を実行する権限がありません。"
    end
  end

  def contract_params
    params.require(:contract).permit(
      :title, :body, :status_id, :tag_list,
      :expiration_date, :renewal_date, :group_id, :conclusion_date,
      attachments: []
    )
  end

  def find_templates_for_category(contract, category)
    return [] unless contract.user&.company
    contract.user.company.slack_message_templates.by_category(category).order(:is_default, :name)
  end
end
