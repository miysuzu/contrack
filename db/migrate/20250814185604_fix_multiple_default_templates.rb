class FixMultipleDefaultTemplates < ActiveRecord::Migration[6.1]
  def up
    # 各カテゴリで複数のデフォルトテンプレートがある場合、最初のもの以外を非デフォルトにする
    
    # ユーザーのテンプレート
    %w[default created updated expiring renewal].each do |category|
      # 各ユーザーごとに処理
      User.find_each do |user|
        default_templates = SlackMessageTemplate.where(user: user, category: category, is_default: true).order(:created_at)
        if default_templates.count > 1
          # 最初のテンプレート以外を非デフォルトにする
          default_templates.offset(1).update_all(is_default: false)
          puts "Fixed #{default_templates.count - 1} duplicate default templates for user #{user.id} in category #{category}"
        end
      end
    end
    
    # 管理者のテンプレート
    %w[default created updated expiring renewal].each do |category|
      # 各管理者ごとに処理
      Admin.find_each do |admin|
        default_templates = SlackMessageTemplate.where(admin: admin, category: category, is_default: true).order(:created_at)
        if default_templates.count > 1
          # 最初のテンプレート以外を非デフォルトにする
          default_templates.offset(1).update_all(is_default: false)
          puts "Fixed #{default_templates.count - 1} duplicate default templates for admin #{admin.id} in category #{category}"
        end
      end
    end
  end

  def down
    # このマイグレーションは元に戻せない（データの変更のため）
    raise ActiveRecord::IrreversibleMigration
  end
end
