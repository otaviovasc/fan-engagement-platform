class CreateUserWaitlists < ActiveRecord::Migration[7.0]
  def change
    create_table :user_waitlists do |t|
      t.string :email
      t.boolean :confirmed

      t.timestamps
    end
  end
end
