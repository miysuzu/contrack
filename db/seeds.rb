
company_names = %w(
  サンプル会社
  A会社
  B会社
)

group_names = %w(
  グループ1
  グループ2
  グループ3
)

company_names.each.with_index(1) do |name, i|
  company = Company.create!(name: name)
  Admin.create!(email: "admin_#{i}@example.com", password: "password", name: "管理者", company_id: company.id)
  group_names.each.with_index(1) do |name, i|
    Group.create!(name: "#{company.name}_#{name}", company_id: company.id)
  end
end

Status.create!(name: "下書き", color: "secondary")
Status.create!(name: "確認中", color: "warning")
Status.create!(name: "締結済", color: "success")
