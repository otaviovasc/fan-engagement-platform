class RenameListeningTimeToPointsInArtistStats < ActiveRecord::Migration[7.0]
  def change
    rename_column :artist_stats, :listening_time, :points
  end
end
