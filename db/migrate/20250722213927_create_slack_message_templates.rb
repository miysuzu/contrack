class CreateSlackMessageTemplates < ActiveRecord::Migration[6.1]
  def change
    create_table :slack_message_templates do |t|
      t.string :name
      t.text :content
      t.string :category
      t.references :user, null: false, foreign_key: true
      t.references :company, null: false, foreign_key: true
      t.boolean :is_default

      t.timestamps
    end
  end
end
