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
  Status.find_or_create_by!(name: status[:name]) do |s|
    s.color = status[:color]
  end
end

group_names = %w(営業部 法務部 経理部)
company_names = %w(サンプリア会社 テスタス会社)

company_names.each.with_index(1) do |company_name, i|
  company = Company.find_or_create_by!(name: company_name)

  admin = Admin.find_or_initialize_by(email: "admin_#{i}@example.com")
  admin.password = "password"
  admin.name = "#{company.name} 管理者#{i}"
  admin.company = company
  admin.save!  

  users_data = [
    { email: "yamada@example.com", name: "山田 太郎" },
    { email: "sato@example.com", name: "佐藤 花子" },
    { email: "suzuki@example.com", name: "鈴木 翔太" }
  ]

  users = users_data.map do |user_info|
    user = User.find_or_initialize_by(email: user_info[:email])
    user.name = user_info[:name]
    user.password = "password"
    user.password_confirmation = "password"
    user.is_active = true
    user.company = company
    user.save!
    user
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

      Contract.find_or_create_by!(
        title: "#{%w(業務委託 業務提携 契約基本合意 秘密保持 使用許諾 ソフトウェアライセンス 開発委託 共同研究 売買 サービス利用 保守・サポート).sample}契約書（#{user.name}）#{k + 1}",
        user_id: user.id
      ) do |c|
        c.body = "これは#{user.name}が作成した契約書の本文です。"
        c.company_id = user.company_id
        c.status = Status.all.sample
        c.created_at = start_date
        c.signed_on = signed_on
        c.expires_on = expires_on
        c.renewal_date = renewed_on
      end
    end

    personal_group = Group.find_or_create_by!(name: "#{user.name}専用", company_id: user.company_id)
    GroupUser.find_or_create_by!(user_id: user.id, group_id: personal_group.id)
  end

  shared_group = Group.find_or_create_by!(name: "山田＋佐藤＋鈴木", company_id: company.id)
  users.each do |user|
    GroupUser.find_or_create_by!(user_id: user.id, group_id: shared_group.id)
  end

  users.each_with_index do |user, idx|
    contract = user.contracts.first
    if contract
      Comment.find_or_create_by!(content: "これはユーザー#{idx + 1}のコメントです", commentable: contract) do |comment|
        comment.contract_id = contract.id
      end
    end
  end

  3.times do |j|
    contract_title = "○○契約書#{j + 1}"
    user_name = "山田 太郎"
    comment_text = "コメント本文の例です"
    status_name = ["下書き", "確認中", "締結済", "差し戻し"].sample
    renewed_on = (Date.today + rand(15..90)).to_s

    template_texts = [
      "契約書「#{contract_title}」が締結されました。関係者はご確認ください。",
      "#{user_name} さんからコメントが追加されました：「#{comment_text}」",
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

puts " シード処理完了"
