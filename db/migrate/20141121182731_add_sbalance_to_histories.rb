class AddSbalanceToHistories < ActiveRecord::Migration
  def change
  	add_column :histories, :sbalance, :float, default: 0.0
  end
end
