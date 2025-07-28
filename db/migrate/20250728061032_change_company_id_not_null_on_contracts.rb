class ChangeCompanyIdNotNullOnContracts < ActiveRecord::Migration[6.1]
  def change
    change_column_null :contracts, :company_id, false
  end
end
