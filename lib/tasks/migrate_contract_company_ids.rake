namespace :contracts do
  desc "既存の契約書に会社IDを設定"
  task migrate_company_ids: :environment do
    puts "契約書の会社IDを設定中..."
    
    Contract.where(company_id: nil).find_each do |contract|
      if contract.user&.company
        contract.update_column(:company_id, contract.user.company_id)
        puts "契約書ID #{contract.id}: 会社ID #{contract.user.company_id} を設定"
      else
        puts "契約書ID #{contract.id}: ユーザーまたは会社が見つかりません"
      end
    end
    
    puts "完了しました！"
  end
end 