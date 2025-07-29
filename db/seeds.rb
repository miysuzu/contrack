puts " シード処理開始"

# ステータス初期化
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

statuses.each do |status|
  record = Status.find_or_initialize_by(name: status[:name])
  record.color = status[:color]
  record.save!
end

group_names = %w(営業部 法務部 経理部)
company_names = %w(サンプリア会社 テスタス会社)
all_statuses = Status.all.to_a

company_names.each.with_index(1) do |company_name, i|
  company = Company.find_or_create_by!(name: company_name)

  admin_email = "admin_#{i}@example.com"
  admin_name = "#{company.name} 管理者#{i}"
  admin = Admin.find_or_initialize_by(email: admin_email)
  admin.password = "password"
  admin.name = admin_name
  admin.company = company
  admin.save!

  users = []

  [
    ["yamada@example.com", "山田 太郎"],
    ["sato@example.com", "佐藤 花子"],
    ["suzuki@example.com", "鈴木 翔太"]
  ].each do |email, name|
    user = User.find_or_initialize_by(email: email)
    user.name = name
    user.password = "password"
    user.password_confirmation = "password"
    user.is_active = true
    user.company = company
    user.save!
    users << user
  end

  group_names.each do |group_name|
    Group.find_or_create_by!(name: "#{company.name}_#{group_name}", company_id: company.id)
  end

  users.each_with_index do |user, idx|
    5.times do |k|
      start_date  = rand(6..12).months.ago.to_date
      signed_on   = start_date + rand(1..10).days
      expires_on  = signed_on + rand(30..90).days
      renewed_on  = expires_on + rand(15..60).days

      contract = Contract.find_or_initialize_by(
        title: "#{%w(業務委託 業務提携 契約基本合意 秘密保持 使用許諾 ソフトウェアライセンス 開発委託 共同研究 売買 サービス利用 保守・サポート).sample}契約書（#{user.name}）#{k + 1}",
        user_id: user.id
      )

      contract.body = "これは#{user.name}が作成した契約書の本文です。"
      contract.company_id = user.company_id
      contract.status = all_statuses.sample
      contract.conclusion_date = signed_on
      contract.expires_on = expires_on
      contract.renewal_date = renewed_on
      contract.save!
    end

    personal_group = Group.find_or_create_by!(name: "#{user.name}専用", company_id: user.company_id)
    GroupUser.find_or_create_by!(user_id: user.id, group_id: personal_group.id)
  end

  users.each_with_index do |user, idx|
    contract = user.contracts.order(:created_at).first
    if contract
      comment = Comment.find_or_initialize_by(
        content: "これはユーザー#{idx + 1}のコメントです",
        commentable: contract
      )
      comment.contract_id = contract.id
      comment.save!
    end
  end

  users.each do |user|
    3.times do |j|
      contract_title = "○○契約書#{j + 1}"
      comment_text = "コメント本文の例です"
      status_name = ["下書き", "確認中", "締結済", "差し戻し"].sample
      renewed_on = (Date.today + rand(15..90)).to_s

      template_texts = [
        "契約書「#{contract_title}」が締結されました。関係者はご確認ください。",
        "#{user.name} さんからコメントが追加されました：「#{comment_text}」",
        "契約書「#{contract_title}」の承認をお願いします。現在のステータス：#{status_name}",
        "契約書「#{contract_title}」が#{renewed_on}に更新予定です。ご対応をお願いします。",
        "新しい契約書「#{contract_title}」が作成されました。初期ステータスは『#{status_name}』です。"
      ]

      SlackMessageTemplate.find_or_create_by!(
        admin: admin,
        company: company,
        content: template_texts.sample
      )
    end
  end
end

puts " シード処理完了"
