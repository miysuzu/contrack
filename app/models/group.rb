class Group < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :company, optional: true
  has_many :group_users, dependent: :destroy
  has_many :users, through: :group_users
  has_many :contracts, dependent: :destroy
  has_many :group_join_requests, dependent: :destroy
  has_many :pending_join_requests, -> { where(status: :pending) }, class_name: 'GroupJoinRequest'
end
