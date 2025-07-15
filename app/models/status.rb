class Status < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  has_many :contracts
end
