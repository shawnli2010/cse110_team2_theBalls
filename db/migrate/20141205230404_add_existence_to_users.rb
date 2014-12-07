class AddExistenceToUsers < ActiveRecord::Migration
  def change
  	add_column :users, :existence, :boolean, default: true
  end
end
