class FixContractStartDateDataTypes < ActiveRecord::Migration[6.1]
  def up
    # contract_start_dateが文字列として保存されている場合の修正
    Contract.find_each do |contract|
      if contract.contract_start_date.is_a?(String) && contract.contract_start_date.present?
        begin
          # 文字列をDate型に変換
          parsed_date = Date.parse(contract.contract_start_date)
          contract.update_column(:contract_start_date, parsed_date)
        rescue Date::Error
          # 無効な日付の場合はnilに設定
          contract.update_column(:contract_start_date, nil)
        end
      end
    end
  end

  def down
  end
end
