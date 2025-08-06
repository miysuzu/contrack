class ContractAnalyzer
  attr_reader :text

  def initialize(text)
    @text = text
  end

  # 契約タイトル（例：「秘密保持契約書」など）を取得
  def extract_title
    if match = text.match(/(.{1,30}契約書)/)
      match[1]
    else
      nil
    end
  end

  # 契約開始日を取得
  def extract_contract_start_date
    # 「契約開始日」「発効日」「有効日」などの近くにある日付を優先
    if match = text.match(/(契約開始日|発効日|有効日)[\s:：]*([20\d{2}年\d{1,2}月\d{1,2}日|\/\.\-\d{1,2}]+)/)
      parse_date(match[2])
    else
      find_first_date
    end
  end

  # 契約締結日を取得
  def extract_contract_conclusion_date
    # 文書の最後にある日付（署名日として扱う）
    # ただし、契約期間の日付と重複しないように注意
    last_date = find_last_date
    start_date = extract_contract_start_date
    expiration_date = extract_expiration_date
    
    # 最後の日付が契約開始日や満了日と異なる場合のみ契約締結日として使用
    # ただし、署名日っぽい場合は例外として契約締結日として使用
    if last_date && start_date && last_date == start_date
      # 署名日っぽい場合は契約締結日として使用
      if text.include?("成立を証する") && text.include?("記名押印")
        last_date
      else
        nil
      end
    elsif last_date && expiration_date && last_date == expiration_date
      nil
    else
      last_date
    end
  end

  # 後方互換性のためのメソッド
  def extract_conclusion_date
    extract_contract_start_date
  end

  # 満了日（契約終了日）を取得
  def extract_expiration_date
    # 「満了日」「契約期間」「終了日」などの周辺
    if match = text.match(/(満了日|終了日|契約期間.*?まで)[\s:：]*([20\d{2}年\d{1,2}月\d{1,2}日|\/\.\-\d{1,2}]+)/)
      parse_date(match[2])
    else
      find_second_date
    end
  end

  # タグ候補を抽出（契約書タイトルベース）
  def extract_tags
    tag_keywords = %w[
      業務委託 契約基本合意 秘密保持 使用許諾 開発委託
      共同開発 売買 ソフトウェアライセンス サービス
      システム開発 システム保守 システム運用 顧問
      業務提携 フランチャイズ ライセンス 譲渡 委任
    ]

    tag_keywords.select { |word| text.include?(word) }
  end

  # すべての日付を抽出（デバッグ用）
  def extract_all_dates
    dates = []
    text.scan(/(20\d{2}[-年\/\.]\d{1,2}[-月\/\.]\d{1,2}|20\d{2}年\s*\d{1,2}月\s*\d{1,2}日)/).each do |match|
      date = parse_date(match[0])
      dates << date if date
    end
    dates.uniq
  end

  private

  # 最初に見つかった日付を取得（バックアップ用）
  def find_first_date
    if match = text.match(/(20\d{2}[-年\/\.]\d{1,2}[-月\/\.]\d{1,2}|20\d{2}年\s*\d{1,2}月\s*\d{1,2}日)/)
      parse_date(match[1])
    else
      nil
    end
  end

  # 2番目に出てきた日付を取得（満了日がなかったときの補完用）
  def find_second_date
    if matches = text.scan(/(20\d{2}[-年\/\.]\d{1,2}[-月\/\.]\d{1,2}|20\d{2}年\s*\d{1,2}月\s*\d{1,2}日)/)
      parse_date(matches[1][0]) if matches.length > 1
    else
      nil
    end
  end

  # 最後にある日付を取得（署名日として扱う）
  def find_last_date
    # より広いパターンで日付を検索（日本語表記も含む）
    matches = text.scan(/(20\d{2}[-年\/\.]\d{1,2}[-月\/\.]\d{1,2}|20\d{2}年\s*\d{1,2}月\s*\d{1,2}日)/)
    if matches.length > 0
      parse_date(matches.last[0])
    else
      nil
    end
  end

  # 「2025年4月1日」などを Date 型に変換
  def parse_date(str)
    # 日本語表記などを「-」に統一し、余分な記号を除去
    str = str.tr('年月日', '-').gsub(/[^0-9\-\/\.]/, '').gsub(/[\.\s]/, '-')
    Date.parse(str) rescue nil
  end
end
