class AddExpirationAndRenewalDatesToContracts < ActiveRecord::Migration[6.1]
  def change
    add_column :contracts, :expiration_date, :date
    add_column :contracts, :renewal_date, :date
  end
end
