class SetDefaultDepthForExistingComments < ActiveRecord::Migration[6.1]
  def up
    # 既存のコメントでdepthがnilの場合は0に設定
    Comment.where(depth: nil).update_all(depth: 0)
  end

  def down
    # ロールバック時は何もしない
  end
end
