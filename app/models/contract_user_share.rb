class ContractUserShare < ApplicationRecord
  belongs_to :contract
  belongs_to :user
end
