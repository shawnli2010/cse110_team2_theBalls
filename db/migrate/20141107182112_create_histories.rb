class CreateHistories < ActiveRecord::Migration
  def change
    create_table :histories do |t|
      t.float :amount
      t.datetime :date
      t.float :balance
      t.integer :user_id

      t.timestamps
    end
  end
end
