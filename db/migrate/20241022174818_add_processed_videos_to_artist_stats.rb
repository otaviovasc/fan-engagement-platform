class AddProcessedVideosToArtistStats < ActiveRecord::Migration[7.0]
  def change
    add_column :artist_stats, :processed_videos, :text, array: true, default: []  # Store video IDs as an array
  end
end
