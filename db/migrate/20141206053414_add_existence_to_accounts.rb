class AddExistenceToAccounts < ActiveRecord::Migration
  def change
  	add_column :accounts, :existence, :boolean, default: true
  end
end
