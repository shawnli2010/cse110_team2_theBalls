class CreateAccounts < ActiveRecord::Migration
  def change
    create_table :accounts do |t|
      t.integer :user_id
      t.float :balance
      t.boolean :acct_type
      t.float :threshold
      t.boolean :is_threshold
      t.boolean :is_receiving
      t.timestamps
    end
  end
end
