# メール送信テストスクリプト
# 使用方法: rails runner test_mail.rb

puts "メール送信テストを開始します..."

# テスト用のユーザーを作成（存在しない場合）
user = User.find_or_create_by(email: 'test@example.com') do |u|
  u.name = 'テストユーザー'
  u.password = 'password123'
  u.password_confirmation = 'password123'
end

puts "テストユーザー: #{user.email}"

# パスワードリセットトークンを生成
token = user.send_reset_password_instructions

puts "パスワードリセットトークンが生成されました: #{token}"
puts "メール送信テストが完了しました。"

# 送信されたメールの内容を確認
if ActionMailer::Base.deliveries.any?
  puts "\n送信されたメール数: #{ActionMailer::Base.deliveries.count}"
  puts "最新のメールの件名: #{ActionMailer::Base.deliveries.last.subject}"
  puts "最新のメールの本文:"
  puts ActionMailer::Base.deliveries.last.body.to_s
else
  puts "\nメールが送信されませんでした。"
end 