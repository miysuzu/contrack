class AddCompanyToExistingData < ActiveRecord::Migration[6.1]
  def up
    # デフォルトの会社を作成
    default_company = Company.create!(
      name: 'デフォルト会社',
      created_at: Time.current,
      updated_at: Time.current
    )

    # 既存のユーザーに会社を設定
    User.where(company_id: nil).update_all(company_id: default_company.id)

    # 既存のグループに会社を設定
    Group.where(company_id: nil).update_all(company_id: default_company.id)

    # 既存の管理者に会社を設定
    Admin.where(company_id: nil).update_all(company_id: default_company.id)
  end

  def down
    # ロールバック時は何もしない（データを削除しない）
  end
end
