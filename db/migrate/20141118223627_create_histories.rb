class CreateHistories < ActiveRecord::Migration
  def change
    create_table :histories do |t|
      t.integer :acct_id
      t.float :balance
      t.integer :cd
      t.float :amount
      t.boolean :cs
      t.timestamps
    end

  end
end
