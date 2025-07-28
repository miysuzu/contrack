class ChangeCommentsToPolymorphic < ActiveRecord::Migration[6.1]
  def up
    # まずcommentable_typeとcommentable_idカラムを追加（nullを許可）
    add_reference :comments, :commentable, polymorphic: true, null: true, index: true
    
    # 既存のコメントをUserとして移行
    execute <<-SQL
      UPDATE comments 
      SET commentable_type = 'User', commentable_id = user_id 
      WHERE user_id IS NOT NULL
    SQL
    
    # commentableカラムをnull: falseに変更
    change_column_null :comments, :commentable_type, false
    change_column_null :comments, :commentable_id, false
    
    # user_idカラムを削除
    remove_reference :comments, :user, foreign_key: true
  end

  def down
    # user_idカラムを復元
    add_reference :comments, :user, null: true, foreign_key: true
    
    # データを元に戻す
    execute <<-SQL
      UPDATE comments 
      SET user_id = commentable_id 
      WHERE commentable_type = 'User'
    SQL
    
    # commentable関連を削除
    remove_reference :comments, :commentable, polymorphic: true
    
    # user_idカラムをnull: falseに変更
    change_column_null :comments, :user_id, false
  end
end
