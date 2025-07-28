class Admin < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :trackable
  
  has_many :comments, as: :commentable, dependent: :destroy
  has_many :comment_notifications, dependent: :destroy
  belongs_to :company, optional: true
  
  # バリデーション
  validates :name, presence: true, length: { maximum: 50 }
end 