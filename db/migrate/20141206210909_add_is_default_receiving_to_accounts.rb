class AddIsDefaultReceivingToAccounts < ActiveRecord::Migration
  def change
  	add_column :accounts, :is_default_receiving, :boolean
  end
end
