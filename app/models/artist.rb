class Artist < ApplicationRecord
  has_many :artist_stats
  has_many :users, through: :artist_stats
  has_one :artist_mapping, foreign_key: :spotify_id, primary_key: :spotify_id

  def self.find_by_fuzzy_name(name)
    where("similarity(name, ?) > 0.6", name)
      .order(Arel.sql("similarity(name, #{ActiveRecord::Base.connection.quote(name)}) DESC"))
      .first
  end
end
