class AddDefaultReceivingIdToUsers < ActiveRecord::Migration
  def change
  	add_column :users, :default_receiving_ID, :integer
  end
end
