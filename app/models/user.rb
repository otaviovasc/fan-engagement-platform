class User < ApplicationRecord
  has_many :artist_stats, dependent: :destroy
  has_many :artists, through: :artist_stats
  has_many :user_tracks, dependent: :destroy

  # Check if user is connected to Spotify
  def spotify_connected?
    access_token.present? && spotify_id.present?
  end

  # Check if user is connected to YouTube
  def youtube_connected?
    youtube_access_token.present? && youtube_id.present?
  end

  # Refresh Spotify access token
  def refresh_access_token
    response = HTTParty.post('https://accounts.spotify.com/api/token', body: {
      grant_type: 'refresh_token',
      refresh_token: self.refresh_token,
      client_id: ENV['SPOTIFY_CLIENT_ID'],
      client_secret: ENV['SPOTIFY_CLIENT_SECRET']
    })
    if response.code == 200
      self.update(access_token: response.parsed_response['access_token'])
      puts "Spotify Access token refreshed #{response.parsed_response['access_token']}"
    else
      false
    end
  end

  # Refresh YouTube access token
  def refresh_youtube_access_token
    response = HTTParty.post(
      'https://oauth2.googleapis.com/token',
      headers: { 'Content-Type' => 'application/x-www-form-urlencoded' },
      body: URI.encode_www_form({
        grant_type: 'refresh_token',
        refresh_token: self.youtube_refresh_token,
        client_id: ENV['GOOGLE_CLIENT_ID'],
        client_secret: ENV['GOOGLE_CLIENT_SECRET']
      })
    )

    if response.code == 200
      self.update(youtube_access_token: response.parsed_response['access_token'])
      puts "YouTube Access token refreshed #{response.parsed_response['access_token']}"
    else
      Rails.logger.error "YouTube token refresh failed: #{response.body}"
      false
    end
  end

  # Ensure Spotify access token is valid
  def ensure_valid_access_token
    refresh_access_token
  end

  # Ensure YouTube access token is valid
  def ensure_valid_youtube_access_token
    refresh_youtube_access_token
  end
end
