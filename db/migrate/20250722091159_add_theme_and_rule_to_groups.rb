class AddThemeAndRuleToGroups < ActiveRecord::Migration[6.1]
  def change
    add_column :groups, :theme, :string
    add_column :groups, :rule, :text
  end
end
