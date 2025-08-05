module SlackMessageHelper
  def generate_slack_message_for_contract(contract, action = 'created')
    # カスタムテンプレートを優先的に使用
    custom_template = find_custom_template(contract, action)
    if custom_template
      return replace_variables(custom_template.content, contract)
    end
    
    # デフォルトのメッセージ生成
    case action
    when 'created'
      generate_created_message(contract)
    when 'updated'
      generate_updated_message(contract)
    when 'expiring'
      generate_expiring_message(contract)
    when 'renewal'
      generate_renewal_message(contract)
    else
      generate_default_message(contract)
    end
  end

  def find_custom_template(contract, action)
    # 管理者側のコントローラーから呼び出された場合
    if controller_path.start_with?('admin/')
      # 現在の管理者のテンプレートから該当するものを検索
      templates = SlackMessageTemplate.where(admin: current_admin).by_category(action)
    else
      # 契約書の作成者のテンプレートから該当するものを検索
      if contract.user
        templates = SlackMessageTemplate.where(user: contract.user).by_category(action)
      else
        # 管理者作成の契約書の場合は、現在のユーザーのテンプレートを使用
        templates = SlackMessageTemplate.where(user: current_user).by_category(action)
      end
    end
    
    # デフォルトテンプレートを優先
    default_template = templates.where(is_default: true).first
    return default_template if default_template
    
    # デフォルトがない場合は最初のテンプレート
    templates.first
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

  private

  def generate_created_message(contract)
    message = "📄 *新規契約書が作成されました*\n\n"
    message += format_contract_info(contract)
    message += "\n詳細はこちら: #{contract_url(contract)}"
    message
  end

  def generate_updated_message(contract)
    message = "✏️ *契約書の内容が変更されました*\n\n"
    message += format_contract_info(contract)
    message += "\n詳細はこちら: #{contract_url(contract)}"
    message
  end

  def generate_expiring_message(contract)
    if contract.expiration_date.present?
      days_left = (contract.expiration_date - Date.current).to_i
      message = "⚠️ *契約書の満了日が近づいています*\n\n"
      message += format_contract_info(contract)
      message += "\n*満了まで残り: #{days_left}日*"
      message += "\n詳細はこちら: #{contract_url(contract)}"
    else
      message = "⚠️ *契約書の満了日が設定されていません*\n\n"
      message += format_contract_info(contract)
      message += "\n*満了日が設定されていないため、日数計算ができません*"
      message += "\n詳細はこちら: #{contract_url(contract)}"
    end
    message
  end

  def generate_renewal_message(contract)
    if contract.renewal_date.present?
      days_left = (contract.renewal_date - Date.current).to_i
      message = "🔄 *契約書の更新期限が近づいています*\n\n"
      message += format_contract_info(contract)
      message += "\n*更新期限まで残り: #{days_left}日*"
      message += "\n詳細はこちら: #{contract_url(contract)}"
    else
      message = "🔄 *契約書の更新期限が設定されていません*\n\n"
      message += format_contract_info(contract)
      message += "\n*更新期限が設定されていないため、日数計算ができません*"
      message += "\n詳細はこちら: #{contract_url(contract)}"
    end
    message
  end

  def generate_default_message(contract)
    message = "📋 *契約書情報*\n\n"
    message += format_contract_info(contract)
    message += "\n詳細はこちら: #{contract_url(contract)}"
    message
  end

  def format_contract_info(contract)
    info = []
    info << "【契約書名】: #{contract.title}"
    info << "【作成者】: #{contract.user ? contract.user.name : '管理者作成'}"
    info << "【ステータス】: #{contract.status.name}"
    
    if contract.expiration_date.present?
      info << "【満了日】: #{contract.expiration_date.strftime('%Y年%m月%d日')}"
    end
    
    if contract.renewal_date.present?
      info << "【更新日】: #{contract.renewal_date.strftime('%Y年%m月%d日')}"
    end
    
    if contract.conclusion_date.present?
      info << "【締結日】: #{contract.conclusion_date.strftime('%Y年%m月%d日')}"
    end
    
    if contract.group.present?
      info << "【グループ】: #{contract.group.name}"
    end
    
    if contract.tag_list.present?
      tags = contract.tag_list.map { |tag| "##{tag}" }.join(' ')
      info << "【タグ】: #{tags}"
    end
    
    info.join("\n")
  end

  def contract_url(contract)
    # 管理者側のコントローラーから呼び出された場合は管理者側のURLを生成
    if controller_path.start_with?('admin/')
      Rails.application.routes.url_helpers.admin_contract_url(contract, host: request.host_with_port)
    else
      Rails.application.routes.url_helpers.contract_url(contract, host: request.host_with_port)
    end
  end
end 