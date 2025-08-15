class AddCompanyIdToContracts < ActiveRecord::Migration[6.1]
  def change
    add_reference :contracts, :company, foreign_key: true
  end
end
