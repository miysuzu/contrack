class RenameConclusionDateToContractStartDateAndAddContractConclusionDate < ActiveRecord::Migration[6.1]
  def change
    # conclusion_dateをcontract_start_dateにリネーム
    rename_column :contracts, :conclusion_date, :contract_start_date
    
    # contract_conclusion_dateカラムを追加
    add_column :contracts, :contract_conclusion_date, :date
  end
end
