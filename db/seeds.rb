# ステータスの作成
puts " ステータス作成"
statuses = [
  { name: "下書き", color: "secondary" },
  { name: "承認待ち", color: "info" },
  { name: "確認中", color: "warning" },
  { name: "締結済", color: "success" },
  { name: "アーカイブ済", color: "light" },
  { name: "差し戻し", color: "danger" },
  { name: "保留", color: "primary" },
  { name: "キャンセル済", color: "dark" }
]

statuses.each do |status_data|
  status = Status.find_or_initialize_by(name: status_data[:name])
  status.color = status_data[:color]
  status.save!
  puts "   ステータス作成: #{status.name}"
end

# 会社の作成
puts " 会社作成"
sampuria_company = Company.find_or_create_by!(name: "サンプリア会社")
puts " 会社作成: サンプリア会社"

testas_company = Company.find_or_create_by!(name: "テスタス株式会社")
puts " 会社作成: テスタス株式会社"

# 管理者の作成
puts " 管理者作成"
sampuria_admin = Admin.find_or_initialize_by(email: "admin_1@example.com")
sampuria_admin.password = "password"
sampuria_admin.name = "サンプリア会社 管理者1"
sampuria_admin.company = sampuria_company
sampuria_admin.save!
puts " 管理者作成: サンプリア会社 管理者1 (admin_1@example.com)"

testas_admin = Admin.find_or_initialize_by(email: "admin_2@example.com")
testas_admin.password = "password"
testas_admin.name = "テスタス株式会社 管理者1"
testas_admin.company = testas_company
testas_admin.save!
puts " 管理者作成: テスタス株式会社 管理者1 (admin_2@example.com)"

# サンプリア会社のユーザー作成
puts " ユーザー作成"
yamada = User.find_or_initialize_by(email: "yamada@example.com")
yamada.name = "山田 太郎"
yamada.password = "password"
yamada.password_confirmation = "password"
yamada.is_active = true
yamada.company = sampuria_company
yamada.save!
puts " ユーザー作成: 山田 太郎 (yamada@example.com)"

sato = User.find_or_initialize_by(email: "sato@example.com")
sato.name = "佐藤 花子"
sato.password = "password"
sato.password_confirmation = "password"
sato.is_active = true
sato.company = sampuria_company
sato.save!
puts " ユーザー作成: 佐藤 花子 (sato@example.com)"

suzuki = User.find_or_initialize_by(email: "suzuki@example.com")
suzuki.name = "鈴木 翔太"
suzuki.password = "password"
suzuki.password_confirmation = "password"
suzuki.is_active = true
suzuki.company = sampuria_company
suzuki.save!
puts " ユーザー作成: 鈴木 翔太 (suzuki@example.com)"

sampuria_users = [yamada, sato, suzuki]

# グループの作成
puts " グループ作成"
group_names = %w[営業部 法務部 経理部]

sampuria_groups = []
group_names.each do |group_name|
  group = Group.find_or_create_by!(
    name: "サンプリア会社_#{group_name}",
    company_id: sampuria_company.id
  )
  sampuria_groups << group
  puts "   グループ作成: #{group.name}"
end

# サンプリア会社のグループにユーザーを割り当て
puts " グループユーザー割り当て"
sampuria_groups.each do |group|
  selected_users = sampuria_users.sample(2)
  selected_users.each do |user|
    GroupUser.find_or_create_by!(user_id: user.id, group_id: group.id)
  end
  puts "   グループ #{group.name} に #{selected_users.count} 人のユーザーを割り当て"
end

# サンプリア会社の専用グループ作成
sampuria_users.each do |user|
  personal_group = Group.find_or_create_by!(
    name: "#{user.name}専用",
    company_id: sampuria_company.id
  )
  GroupUser.find_or_create_by!(user_id: user.id, group_id: personal_group.id)
  puts " 専用グループ作成: #{personal_group.name}"
end

# 契約書の作成
contract_titles = [
  "業務委託契約書",
  "契約基本合意書",
  "秘密保持契約書",
  "使用許諾契約書",
  "開発委託契約書",
  "共同開発契約書",
  "売買契約書",
  "ソフトウェアライセンス契約書",
  "サービス契約書",
  "システム開発契約書",
  "システム保守契約書",
  "システム運用契約書",
  "顧問契約書",
  "業務提携契約書",
  "フランチャイズ契約書",
  "ライセンス契約書",
  "譲渡契約書",
  "委任契約書"
]
all_statuses = Status.all.to_a

sampuria_users.each do |user|
  3.times do |contract_index|
          start_date = rand(6..12).months.ago.to_date
      signed_on = start_date + rand(1..10).days
      expiration_date = signed_on + rand(30..90).days
      renewed_on = expiration_date + rand(15..60).days

    title = "#{contract_titles.sample}（#{user.name}）#{contract_index + 1}"
    
    selected_group = sampuria_groups.sample
    
    contract = Contract.find_or_initialize_by(
      title: title,
      user_id: user.id
    )
    contract.body = "これは#{user.name}が作成した#{title}の本文です。契約条項、対象期間、義務などが記載されています。"
    contract.company_id = user.company_id
    contract.status = all_statuses.sample
    contract.group_id = selected_group.id
    contract.conclusion_date = signed_on
    contract.expiration_date = expiration_date
    contract.renewal_date = renewed_on
    contract.save!
    
    puts "   契約書作成: #{title}"
  end
end

# デフォルトテンプレートの作成
default_templates = [
  { name: "契約締結通知", category: "created", content: "新しい契約書が締結されました。関係者はご確認ください。" },
  { name: "更新通知", category: "updated", content: "契約書が更新されました。変更内容をご確認ください。" },
  { name: "期限切れ通知", category: "expiring", content: "契約書の期限が近づいています。ご対応をお願いします。" },
  { name: "更新手続き通知", category: "renewal", content: "契約書の更新手続きが必要です。ご対応をお願いします。" }
]

default_templates.each do |template_data|
  template = SlackMessageTemplate.find_or_initialize_by(
    admin: sampuria_admin,
    company: sampuria_company,
    name: template_data[:name],
    category: template_data[:category]
  )
  template.content = template_data[:content]
  template.is_default = true
  template.save!
  puts "   デフォルトテンプレート作成: #{template.name}"
end

puts " データ作成完了"
puts " シード処理完了"
puts " 作成されたデータ:"
puts "  - 会社: #{Company.count}件"
puts "  - 管理者: #{Admin.count}件"
puts "  - ユーザー: #{User.count}件"
puts "  - グループ: #{Group.count}件"
puts "  - 契約書: #{Contract.count}件"
puts "  - コメント: #{Comment.count}件"
puts "  - Slackテンプレート: #{SlackMessageTemplate.count}件"
puts "  - ステータス: #{Status.count}件"

puts ""
puts "=== ログイン情報 ==="
puts "ユーザー（サンプリア会社）:"
puts "  山田 太郎"
puts "  メールアドレス: yamada@example.com"
puts "  パスワード: password"
puts ""
puts "  佐藤 花子"
puts "  メールアドレス: sato@example.com"
puts "  パスワード: password"
puts ""
puts "  鈴木 翔太"
puts "  メールアドレス: suzuki@example.com"
puts "  パスワード: password"
puts ""
puts "管理者:"
puts "  サンプリア会社 管理者1"
puts "  メールアドレス: admin_1@example.com"
puts "  パスワード: password"
puts ""
puts "  テスタス株式会社 管理者"
puts "  メールアドレス: admin_2@example.com"
puts "  パスワード: password"
