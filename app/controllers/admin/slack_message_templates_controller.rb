class Admin::SlackMessageTemplatesController < Admin::ApplicationController
  before_action :set_template, only: [:show, :edit, :update, :destroy]

  def index
    @templates = SlackMessageTemplate.where(admin: current_admin).order(:category, :name)
    @categories = SlackMessageTemplate.categories
  end

  def show
  end

  def new
    @template = SlackMessageTemplate.new
  end

  def create
    @template = SlackMessageTemplate.new(template_params)
    @template.admin = current_admin
    @template.user = nil  # 管理者作成の場合はuserをnilに設定
    @template.company = current_admin.company if current_admin.company
    
    if @template.save
      redirect_to admin_slack_message_templates_path, notice: 'テンプレートを作成しました。'
    else
      flash[:validation_errors] = @template.errors.full_messages
      render :new
    end
  end

  def edit
  end

  def update
    if @template.update(template_params)
      redirect_to admin_slack_message_templates_path, notice: 'テンプレートを更新しました。'
    else
      flash[:validation_errors] = @template.errors.full_messages
      render :edit
    end
  end

  def destroy
    @template.destroy
    redirect_to admin_slack_message_templates_path, notice: 'テンプレートを削除しました。'
  end

  def preview
    @template = SlackMessageTemplate.find(params[:id])
    @contract = Contract.find(params[:contract_id])
    
    # 変数置換してプレビュー生成
    preview_content = replace_variables(@template.content, @contract)
    render plain: preview_content
  end

  private

  def set_template
    @template = SlackMessageTemplate.where(admin: current_admin).find(params[:id])
  end

  def template_params
    params.require(:slack_message_template).permit(:name, :content, :category, :is_default)
  end

  def replace_variables(content, contract)
    # 変数置換
    content = content.gsub('{{title}}', contract.title)
    content = content.gsub('{{user_name}}', contract.user ? contract.user.name : '管理者作成')
    content = content.gsub('{{status}}', contract.status.name)
    content = content.gsub('{{expiration_date}}', contract.expiration_date&.strftime('%Y年%m月%d日') || '未設定')
    content = content.gsub('{{renewal_date}}', contract.renewal_date&.strftime('%Y年%m月%d日') || '未設定')
    content = content.gsub('{{conclusion_date}}', contract.conclusion_date&.strftime('%Y年%m月%d日') || '未設定')
    content = content.gsub('{{group_name}}', contract.group&.name || '未設定')
    content = content.gsub('{{tags}}', contract.tag_list.present? ? contract.tag_list.map { |tag| "##{tag}" }.join(' ') : 'なし')
    content = content.gsub('{{url}}', admin_contract_url(contract))
    
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

  def admin_contract_url(contract)
    "http://localhost:3000/admin/contracts/#{contract.id}"
  end
end 