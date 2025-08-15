class ChangeUserIdNullOnContracts < ActiveRecord::Migration[6.1]
  def change
    change_column_null :contracts, :user_id, true
  end
end
