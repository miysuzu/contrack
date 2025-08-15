class AddCompanyIdToAdmins < ActiveRecord::Migration[6.1]
  def change
    add_reference :admins, :company, null: true, foreign_key: true
  end
end
