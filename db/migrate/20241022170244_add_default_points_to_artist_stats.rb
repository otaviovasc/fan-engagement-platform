class AddDefaultPointsToArtistStats < ActiveRecord::Migration[7.0]
  def change
    change_column_default :artist_stats, :points, from: nil, to: 0
  end
end
