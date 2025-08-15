class AddAdminCreatedToGroups < ActiveRecord::Migration[6.1]
  def change
    add_column :groups, :admin_created, :boolean
  end
end
