class AddTrigramIndexToArtists < ActiveRecord::Migration[7.0]
  def up
    execute "CREATE INDEX artists_name_trgm_idx ON artists USING gin (name gin_trgm_ops);"
  end

  def down
    execute "DROP INDEX artists_name_trgm_idx;"
  end
end
