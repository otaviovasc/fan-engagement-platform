class CreateArtistMappings < ActiveRecord::Migration[7.0]
  def change
    create_table :artist_mappings do |t|
      t.string :spotify_id, null: false, index: true
      t.string :youtube_id, null: false, index: true

      t.timestamps
    end

    # Add a unique index to enforce that each mapping pair is unique
    add_index :artist_mappings, [:spotify_id, :youtube_id], unique: true
  end
end
