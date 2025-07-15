class CreateContracts < ActiveRecord::Migration[6.1]
  def change
    create_table :contracts do |t|
      t.bigint :user_id, null: false
      t.bigint :status_id, null: false
      t.string :title
      t.text :description

      t.timestamps
    end
    add_foreign_key :contracts, :users
    add_foreign_key :contracts, :statuses
  end
end
