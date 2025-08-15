class AddAdminIdToSlackMessageTemplates < ActiveRecord::Migration[6.1]
  def change
    add_reference :slack_message_templates, :admin, null: false, foreign_key: true
  end
end
