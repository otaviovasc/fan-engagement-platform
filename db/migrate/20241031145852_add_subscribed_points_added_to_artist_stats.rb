class AddSubscribedPointsAddedToArtistStats < ActiveRecord::Migration[7.0]
  def change
    add_column :artist_stats, :subscribed_points_added, :boolean, default: false, null: false
  end
end
