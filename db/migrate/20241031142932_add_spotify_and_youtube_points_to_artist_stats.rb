class AddSpotifyAndYoutubePointsToArtistStats < ActiveRecord::Migration[7.0]
  def change
    add_column :artist_stats, :spotify_points, :integer, default: 0
    add_column :artist_stats, :youtube_points, :integer, default: 0
  end
end
