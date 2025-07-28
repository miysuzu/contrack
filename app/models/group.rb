class Group < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :company, optional: true
  has_many :group_users, dependent: :destroy
  has_many :users, through: :group_users
  has_many :contracts, dependent: :destroy
end
