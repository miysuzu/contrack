class AddConclusionDateToContracts < ActiveRecord::Migration[6.1]
  def change
    add_column :contracts, :conclusion_date, :date
  end
end
