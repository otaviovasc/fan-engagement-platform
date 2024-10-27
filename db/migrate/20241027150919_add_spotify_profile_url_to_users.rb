class AddSpotifyProfileUrlToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :spotify_profile_url, :string
  end
end
