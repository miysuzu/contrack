class AddBodyToContracts < ActiveRecord::Migration[6.1]
  def change
    add_column :contracts, :body, :text
  end
end
