class AllowNullUserIdOnSlackMessageTemplates < ActiveRecord::Migration[6.1]
  def change
    change_column_null :slack_message_templates, :user_id, true
  end
end
