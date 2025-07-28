class SlackMessageTemplate < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :admin, optional: true
  belongs_to :company, optional: true
  
  # バリデーション
  validates :name, presence: { message: "を入力してください" }, length: { maximum: 100, message: "は100文字以内で入力してください" }
  validates :content, presence: { message: "を入力してください" }
  validates :category, presence: { message: "を選択してください" }, inclusion: { in: %w[default created updated expiring renewal], message: "は一覧から選択してください" }
  
  # スコープ
  scope :by_category, ->(category) { where(category: category) }
  scope :default_templates, -> { where(is_default: true) }
  scope :user_templates, -> { where(is_default: false) }
  
  # カテゴリの選択肢
  def self.categories
    {
      'default' => I18n.t('slack_message_template.categories.default'),
      'created' => I18n.t('slack_message_template.categories.created'),
      'updated' => I18n.t('slack_message_template.categories.updated'),
      'expiring' => I18n.t('slack_message_template.categories.expiring'),
      'renewal' => I18n.t('slack_message_template.categories.renewal')
    }
  end
  
  # カテゴリ名を取得
  def category_name
    self.class.categories[category] || category
  end
end
