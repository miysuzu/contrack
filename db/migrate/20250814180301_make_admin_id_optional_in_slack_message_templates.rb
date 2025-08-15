class MakeAdminIdOptionalInSlackMessageTemplates < ActiveRecord::Migration[6.1]
  def change
    change_column_null :slack_message_templates, :admin_id, true
  end
end
