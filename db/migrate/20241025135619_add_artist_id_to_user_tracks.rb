class AddArtistIdToUserTracks < ActiveRecord::Migration[7.0]
  def change
    add_column :user_tracks, :artist_id, :string, index: true
  end
end
