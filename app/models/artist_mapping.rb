class ArtistMapping < ApplicationRecord
  validates :spotify_id, presence: true
  validates :youtube_id, presence: true
  validates_uniqueness_of :spotify_id, scope: :youtube_id
end
