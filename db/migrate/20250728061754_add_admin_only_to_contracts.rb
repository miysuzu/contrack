class AddAdminOnlyToContracts < ActiveRecord::Migration[6.1]
  def change
    add_column :contracts, :admin_only, :boolean
  end
end
