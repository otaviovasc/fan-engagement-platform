class CreateArtistStats < ActiveRecord::Migration[7.0]
  def change
    create_table :artist_stats do |t|
      t.references :user, null: false, foreign_key: true
      t.references :artist, null: false, foreign_key: true
      t.integer :listening_time

      t.timestamps
    end
  end
end
