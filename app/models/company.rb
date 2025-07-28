class Company < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :groups, dependent: :destroy
  has_many :admins, dependent: :destroy
  has_many :slack_message_templates, dependent: :destroy
  has_many :contracts, dependent: :destroy
  
  validates :name, presence: true, length: { maximum: 100 }
end
