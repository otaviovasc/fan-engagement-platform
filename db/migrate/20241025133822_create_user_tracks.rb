class CreateUserTracks < ActiveRecord::Migration[7.0]
  def change
    create_table :user_tracks do |t|
      t.references :user, null: false, foreign_key: true
      t.string :track_name
      t.string :artist_names
      t.string :spotify_track_id, index: true
      t.datetime :played_at
      t.integer :duration_ms

      t.timestamps
    end
  end
end
