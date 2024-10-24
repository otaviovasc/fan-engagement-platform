Rails.application.config.middleware.use OmniAuth::Builder do
  # Spotify Authentication
  provider :spotify,
           ENV['SPOTIFY_CLIENT_ID'],
           ENV['SPOTIFY_CLIENT_SECRET'],
           scope: 'user-read-email user-top-read user-read-recently-played user-read-playback-position'

  # YouTube (Google) Authentication
  provider :google_oauth2,
           ENV['GOOGLE_CLIENT_ID'],
           ENV['GOOGLE_CLIENT_SECRET'],
           scope: 'userinfo.email,userinfo.profile,https://www.googleapis.com/auth/youtube.readonly',
           access_type: 'offline',
           prompt: 'consent'
end
