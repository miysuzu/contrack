class SetDefaultNamesForAdmins < ActiveRecord::Migration[6.1]
  def up
    # 既存の管理者にデフォルトの名前を設定
    Admin.where(name: [nil, '']).each do |admin|
      admin.update!(name: "管理者#{admin.id}")
    end
  end

  def down
    # ロールバック時は何もしない
  end
end
