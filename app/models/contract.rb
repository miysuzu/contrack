class Contract < ApplicationRecord
  belongs_to :user
  belongs_to :status
  acts_as_taggable_on :tags
  
  # バリデーション
  validates :title, presence: true, length: { maximum: 100 }
  validates :body, presence: true
end
