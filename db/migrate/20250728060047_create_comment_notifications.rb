class CreateCommentNotifications < ActiveRecord::Migration[6.1]
  def change
    create_table :comment_notifications do |t|
      t.references :admin, null: false, foreign_key: true
      t.references :comment, null: false, foreign_key: true
      t.boolean :read, default: false, null: false
      t.timestamps
    end
  end
end
