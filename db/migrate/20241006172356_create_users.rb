class CreateUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :users do |t|
      t.string :spotify_id
      t.string :display_name
      t.string :access_token
      t.string :refresh_token
      t.string :profile_image_url

      t.timestamps
    end
  end
end
