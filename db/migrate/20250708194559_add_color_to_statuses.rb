class AddColorToStatuses < ActiveRecord::Migration[6.1]
  def change
    add_column :statuses, :color, :string
  end
end
