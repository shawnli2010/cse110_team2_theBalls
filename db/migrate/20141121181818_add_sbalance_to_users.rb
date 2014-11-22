class AddSbalanceToUsers < ActiveRecord::Migration
  def change
  	add_column :users, :sbalance, :float, default: 0.0
  end
end
