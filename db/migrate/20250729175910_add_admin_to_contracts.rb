class AddAdminToContracts < ActiveRecord::Migration[6.1]
  def change
    add_reference :contracts, :admin, null: true, foreign_key: true
  end
end
