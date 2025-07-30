class UpdateExistingUsersIsActive < ActiveRecord::Migration[6.1]
  def up
    # 既存のユーザーでis_activeがnilのものをtrueに更新
    User.where(is_active: nil).update_all(is_active: true)
  end

  def down
  end
end
