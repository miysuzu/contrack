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

  # 締結日（契約開始日）を取得
  def extract_conclusion_date
    # 「契約日」「締結日」などの近くにある日付を優先
    if match = text.match(/(契約日|締結日|発効日|有効日)[\s:：]*([20\d{2}年\d{1,2}月\d{1,2}日|\/\.\-\d{1,2}]+)/)
      parse_date(match[2])
    else
      find_first_date
    end
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

  private

  # 最初に見つかった日付を取得（バックアップ用）
  def find_first_date
    if match = text.match(/(20\d{2}[-年\/\.]\d{1,2}[-月\/\.]\d{1,2})/)
      parse_date(match[1])
    else
      nil
    end
  end

  # 2番目に出てきた日付を取得（満了日がなかったときの補完用）
  def find_second_date
    if matches = text.scan(/(20\d{2}[-年\/\.]\d{1,2}[-月\/\.]\d{1,2})/)
      parse_date(matches[1][0]) if matches.length > 1
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
