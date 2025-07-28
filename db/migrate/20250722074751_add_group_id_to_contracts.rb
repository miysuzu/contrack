class AddGroupIdToContracts < ActiveRecord::Migration[6.1]
  def change
    add_reference :contracts, :group, null: true, foreign_key: true
  end
end
