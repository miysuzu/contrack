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
    # 管理者専用の契約書は除外する
    @contracts = Contract.where(
      Contract.arel_table[:user_id].eq(current_user.id)
      .or(Contract.arel_table[:group_id].in(group_ids))
    ).where("admin_only IS NULL OR admin_only = ?", false)
  
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
    when "contract_start_date_asc"
      @contracts = @contracts.order(contract_start_date: :asc, created_at: :desc)
    when "contract_start_date_desc"
      @contracts = @contracts.order(contract_start_date: :desc, created_at: :desc)
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
  
    # 🔽 Google Cloud Vision APIを使って画像から本文を抽出する（複数対応）
    # 添付画像が存在する場合、それぞれの画像を順にOCRし、本文に結合する
    if params[:contract][:attachments].present?
      combined_text = ""
  
      params[:contract][:attachments].each_with_index do |image, index|
        begin
          extracted_text = Vision.get_text_from_image(image)
          if extracted_text.present?
            combined_text << "【ページ#{index + 1}】\n"
            combined_text << extracted_text
            combined_text << "\n\n---------- 改ページ ----------\n\n"
          end
        rescue => e
          Rails.logger.error("Vision API エラー: #{e.message}")
          flash.now[:alert] = "一部の画像の読み取りに失敗しました。"
        end
      end
  
      if combined_text.present?
        @contract.body = combined_text
  
        # 🔽 OCRされたテキストから契約情報を自動抽出する
        analyzer = ContractAnalyzer.new(combined_text)
  
        # 契約タイトルを抽出（例：「秘密保持契約書」など）
        @contract.title = analyzer.extract_title if analyzer.extract_title
  
        # 締結日（開始日）を抽出
        @contract.conclusion_date = analyzer.extract_conclusion_date
  
        # 満了日（終了日）を抽出
        @contract.expiration_date = analyzer.extract_expiration_date
  
        # タグ（キーワード）を抽出し、tag_listにセット
        @contract.tag_list = analyzer.extract_tags if analyzer.extract_tags.any?
      end
    end
  
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

  def ocr_preview
    if params[:file].blank?
      render json: { error: 'ファイルが選択されていません' }, status: :bad_request
      return
    end

    begin
      # 画像からテキストを抽出
      extracted_text = Vision.get_text_from_image(params[:file])
      
      if extracted_text.blank?
        render json: { error: 'テキストを抽出できませんでした' }, status: :unprocessable_entity
        return
      end

      # 契約情報を自動抽出
      analyzer = ContractAnalyzer.new(extracted_text)
      

      
      result = {
        body: extracted_text,
        title: analyzer.extract_title,
        tags: analyzer.extract_tags,
        contract_start_date: analyzer.extract_contract_start_date&.strftime('%Y-%m-%d'),
        contract_conclusion_date: analyzer.extract_contract_conclusion_date&.strftime('%Y-%m-%d'),
        expiration_date: analyzer.extract_expiration_date&.strftime('%Y-%m-%d')
      }

      render json: result
    rescue => e
      Rails.logger.error("OCR Preview Error: #{e.message}")
      render json: { error: "OCR処理中にエラーが発生しました: #{e.message}" }, status: :internal_server_error
    end
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
      template = SlackMessageTemplate.where(user: current_user).find(template_id)
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
    # 管理者専用の契約書は除外する
    @contract = Contract.where(
      Contract.arel_table[:user_id].eq(current_user.id)
      .or(Contract.arel_table[:group_id].in(group_ids))
    ).where("admin_only IS NULL OR admin_only = ?", false).find(params[:id])
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
      :expiration_date, :renewal_date, :group_id, :contract_start_date, :contract_conclusion_date,
      attachments: []
    )
  end

  def find_templates_for_category(contract, category)
    # 契約書の作成者のテンプレートから該当するものを検索
    if contract.user
      templates = SlackMessageTemplate.where(user: contract.user).by_category(category).order(:is_default, :name)
    else
      # 管理者作成の契約書の場合は、現在のユーザーのテンプレートを使用
      templates = SlackMessageTemplate.where(user: current_user).by_category(category).order(:is_default, :name)
    end
    templates
  end

  def replace_variables(content, contract)
    # 変数置換
    content = content.gsub('{{title}}', contract.title)
    content = content.gsub('{{user_name}}', contract.user ? contract.user.name : '管理者作成')
    content = content.gsub('{{status}}', contract.status.name)
    content = content.gsub('{{created_at}}', contract.created_at.strftime('%Y年%m月%d日'))
    content = content.gsub('{{expiration_date}}', contract.expiration_date&.strftime('%Y年%m月%d日') || '未設定')
    content = content.gsub('{{renewal_date}}', contract.renewal_date&.strftime('%Y年%m月%d日') || '未設定')
    content = content.gsub('{{contract_start_date}}', contract.contract_start_date&.strftime('%Y年%m月%d日') || '未設定')
    content = content.gsub('{{contract_conclusion_date}}', contract.contract_conclusion_date&.strftime('%Y年%m月%d日') || '未設定')
    content = content.gsub('{{conclusion_date}}', contract.conclusion_date&.strftime('%Y年%m月%d日') || '未設定')
    content = content.gsub('{{group_name}}', contract.group&.name || '未設定')
    content = content.gsub('{{tags}}', contract.tag_list.present? ? contract.tag_list.map { |tag| "##{tag}" }.join(' ') : 'なし')
    content = content.gsub('{{url}}', contract_url(contract))
    
    # 日付計算
    if contract.expiration_date.present?
      days_left = (contract.expiration_date - Date.current).to_i
      content = content.gsub('{{days_until_expiration}}', days_left.to_s)
    end
    
    if contract.renewal_date.present?
      days_left = (contract.renewal_date - Date.current).to_i
      content = content.gsub('{{days_until_renewal}}', days_left.to_s)
    end
    
    content
  end
end
