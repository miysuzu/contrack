class RemoveThemeAndRuleFromGroups < ActiveRecord::Migration[6.1]
  def change
    remove_column :groups, :theme, :string
    remove_column :groups, :rule, :text
  end
end
