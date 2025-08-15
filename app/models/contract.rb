class Contract < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :admin, optional: true
  belongs_to :status
  belongs_to :group, optional: true
  belongs_to :company, optional: true
  has_many :comments, dependent: :destroy
  has_many_attached :attachments, dependent: :purge_later
  has_many :contract_user_shares, dependent: :destroy
  has_many :shared_users, through: :contract_user_shares, source: :user
  acts_as_taggable_on :tags
  
  # バリデーション
  validates :title, presence: true, length: { maximum: 100 }
  validates :body, presence: true
  
  # 添付ファイルのバリデーション
  validate :acceptable_attachments
  
  def conclusion_date
    contract_conclusion_date
  end
  
  def conclusion_date=(value)
    self.contract_conclusion_date = value
  end
  
  # データ型の確実な変換
  def contract_start_date
    value = read_attribute(:contract_start_date)
    return nil if value.nil?
    return value if value.is_a?(Date)
    Date.parse(value.to_s) rescue nil
  end
  
  def contract_conclusion_date
    value = read_attribute(:contract_conclusion_date)
    return nil if value.nil?
    return value if value.is_a?(Date)
    Date.parse(value.to_s) rescue nil
  end
  
  # 日付の判定メソッド
  def expiration_soon?
    return false unless expiration_date.present?
    days_until_expiration = (expiration_date - Date.current).to_i
    days_until_expiration <= 30 && days_until_expiration >= 0
  end
  
  def expiration_urgent?
    return false unless expiration_date.present?
    days_until_expiration = (expiration_date - Date.current).to_i
    days_until_expiration <= 7 && days_until_expiration >= 0
  end
  
  def renewal_soon?
    return false unless renewal_date.present?
    days_until_renewal = (renewal_date - Date.current).to_i
    days_until_renewal <= 30 && days_until_renewal >= 0
  end
  
  def renewal_urgent?
    return false unless renewal_date.present?
    days_until_renewal = (renewal_date - Date.current).to_i
    days_until_renewal <= 7 && days_until_renewal >= 0
  end
  
  def expired?
    return false unless expiration_date.present?
    expiration_date < Date.current
  end
  
  private
  
  def acceptable_attachments
    return unless attachments.attached?
    
    attachments.each do |attachment|
      unless attachment.byte_size <= 50.megabyte
        errors.add(:attachments, "ファイルサイズは50MB以下にしてください")
      end
      
      acceptable_types = ['application/pdf', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'image/jpeg', 'image/png']
      unless acceptable_types.include?(attachment.content_type)
        errors.add(:attachments, 'PDF、Word、画像ファイルのみアップロード可能です')
      end
    end
  end
end
