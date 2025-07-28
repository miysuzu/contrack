class Contract < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :status
  belongs_to :group
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
