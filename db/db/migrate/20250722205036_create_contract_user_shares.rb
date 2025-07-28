class CreateContractUserShares < ActiveRecord::Migration[6.1]
  def change
    create_table :contract_user_shares do |t|
      t.references :contract, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
