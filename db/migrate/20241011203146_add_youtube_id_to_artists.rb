class AddYoutubeIdToArtists < ActiveRecord::Migration[7.0]
  def change
    add_column :artists, :youtube_id, :string
  end
end
