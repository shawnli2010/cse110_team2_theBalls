class CreateHistories < ActiveRecord::Migration
  def change
    create_table :histories do |t|
      t.integer :user_id
      t.float :balance
      t.integer :cd
      t.float :amount
      t.timestamps
    end

  end
end
