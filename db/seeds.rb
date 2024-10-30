# # db/seeds.rb

# db/seeds.rb

# require 'net/http'
# require 'uri'
# require 'json'
# require 'base64'

# # Function to get Spotify access token using Client Credentials Flow
# def get_spotify_access_token
#   client_id = ENV['SPOTIFY_CLIENT_ID']
#   client_secret = ENV['SPOTIFY_CLIENT_SECRET']
#   raise "Please set SPOTIFY_CLIENT_ID and SPOTIFY_CLIENT_SECRET environment variables" unless client_id && client_secret

#   auth_token = Base64.strict_encode64("#{client_id}:#{client_secret}")

#   uri = URI('https://accounts.spotify.com/api/token')
#   request = Net::HTTP::Post.new(uri)
#   request['Authorization'] = "Basic #{auth_token}"
#   request.set_form_data('grant_type' => 'client_credentials')

#   response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
#     http.request(request)
#   end

#   json = JSON.parse(response.body)
#   access_token = json['access_token']

#   raise "Failed to obtain Spotify access token: #{json}" unless access_token

#   access_token
# end

# # Function to fetch popular playlists for a specific category across countries
# def fetch_popular_playlists(access_token, category)
#   countries = %w[BR US GB CA AU]
#   playlists = []

#   countries.each do |country|
#     uri = URI("https://api.spotify.com/v1/browse/categories/#{category}/playlists?country=#{country}&limit=10")
#     request = Net::HTTP::Get.new(uri)
#     request['Authorization'] = "Bearer #{access_token}"

#     response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
#       http.request(request)
#     end

#     next unless response.code.to_i == 200

#     json = JSON.parse(response.body)
#     if json['playlists'] && json['playlists']['items']
#       playlists += json['playlists']['items']
#     end

#     break if playlists.size >= 50 # Limit the number of playlists to process
#   end

#   playlists.uniq { |p| p['id'] }[0...50] # Limit to 50 unique playlists
# end

# # Function to fetch tracks from a playlist
# def fetch_tracks_from_playlist(access_token, playlist_id)
#   tracks = []
#   offset = 0
#   limit = 100

#   loop do
#     uri = URI("https://api.spotify.com/v1/playlists/#{playlist_id}/tracks?offset=#{offset}&limit=#{limit}")
#     request = Net::HTTP::Get.new(uri)
#     request['Authorization'] = "Bearer #{access_token}"

#     response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
#       http.request(request)
#     end

#     break unless response.code.to_i == 200

#     json = JSON.parse(response.body)
#     tracks += json['items']
#     break if json['items'].size < limit
#     offset += limit
#   end

#   tracks
# end

# # Main script to fetch and save artists, for a given category
# def seed_artists(category)
#   access_token = get_spotify_access_token
#   puts "Access token obtained"

#   artists_hash = {}
#   playlists = fetch_popular_playlists(access_token, category)
#   puts "Fetched #{playlists.size} playlists for category: #{category}"

#   playlists.each_with_index do |playlist, index|
#     puts "Processing playlist #{index + 1}/#{playlists.size}: #{playlist['name']}"
#     tracks = fetch_tracks_from_playlist(access_token, playlist['id'])
#     tracks.each do |track_item|
#       track = track_item['track']
#       next unless track && track['artists']
#       track['artists'].each do |artist_data|
#         artists_hash[artist_data['id']] ||= artist_data
#       end
#     end
#     break if artists_hash.size >= 1000
#   end

#   artists_data = artists_hash.values[0...1000]
#   puts "Fetched #{artists_data.size} unique artists for category: #{category}"

#   artists_data.each_with_index do |artist_data, index|
#     artist = Artist.find_or_initialize_by(spotify_id: artist_data['id'])
#     artist.name = artist_data['name']

#     # Fetch artist details to get image URL
#     artist_details = fetch_artist_details(access_token, artist.spotify_id)
#     if artist_details && artist_details['images'] && artist_details['images'].any?
#       artist.image_url = artist_details['images'].first['url']
#     else
#       artist.image_url = nil
#     end

#     artist.save!
#     puts "Saved artist #{index + 1}/#{artists_data.size}: #{artist.name}"
#   end
# end

# # Function to fetch artist details
# def fetch_artist_details(access_token, artist_id)
#   uri = URI("https://api.spotify.com/v1/artists/#{artist_id}")
#   request = Net::HTTP::Get.new(uri)
#   request['Authorization'] = "Bearer #{access_token}"

#   response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
#     http.request(request)
#   end

#   return nil unless response.code.to_i == 200

#   JSON.parse(response.body)
# end

# # Example usage: Run the Spotify artist seeding process for a specific category
# # Replace 'sertanejo' with any category you want to fetch
# seed_artists('sertanejo')



require 'httparty'
require 'uri'

def fetch_spotify_artist_id(artist_name, access_token)
  response = HTTParty.get("https://api.spotify.com/v1/search",
                          headers: { "Authorization" => "Bearer #{access_token}" },
                          query: { q: artist_name, type: 'artist', limit: 1 })

  if response.code == 200 && response["artists"]["items"].any?
    spotify_id = response["artists"]["items"].first["id"]
    puts "Spotify ID for '#{artist_name}': #{spotify_id}"
    spotify_id
  else
    puts "No artist found on Spotify with name '#{artist_name}'"
    nil
  end
end

def extract_youtube_channel_name(youtube_url)
  uri = URI.parse(youtube_url)
  if uri.host == 'www.youtube.com' && uri.path.start_with?('/@')
    uri.path.split('/@').last
  else
    puts "Invalid YouTube URL format: #{youtube_url}"
    nil
  end
end

def fetch_youtube_channel_id(channel_name, api_key)
  response = HTTParty.get("https://www.googleapis.com/youtube/v3/search",
                          query: { part: 'snippet', q: channel_name, type: 'channel', maxResults: 1, key: api_key })

  if response.code == 200 && response["items"].any?
    youtube_id = response["items"].first["id"]["channelId"]
    puts "YouTube Channel ID for '#{channel_name}': #{youtube_id}"
    youtube_id
  else
    puts "No channel found on YouTube with name '#{channel_name}'"
    nil
  end
end

def create_artist_mappings(artists, spotify_access_token, youtube_api_key)
  artists.each do |artist|
    spotify_id = fetch_spotify_artist_id(artist[:spotify_name], spotify_access_token)
    youtube_channel_name = extract_youtube_channel_name(artist[:youtube_url])
    youtube_id = youtube_channel_name ? fetch_youtube_channel_id(youtube_channel_name, youtube_api_key) : nil

    if spotify_id && youtube_id
      ArtistMapping.find_or_create_by(spotify_id: spotify_id, youtube_id: youtube_id)
      puts "Created mapping for Spotify ID '#{spotify_id}' and YouTube ID '#{youtube_id}'"
    else
      puts "Failed to retrieve both IDs for #{artist[:spotify_name]} / #{artist[:youtube_url]}"
    end
  end
end

# Example usage
artists = [
  { spotify_name: "Bruno & Marrone", youtube_url: "https://www.youtube.com/@brunoemarroneoficial" },
  { spotify_name: "Matuê", youtube_url: "https://www.youtube.com/@30PRAUM" },
]

spotify_access_token = get_spotify_access_token # Ensure you have a valid Spotify access token
youtube_api_key = ENV['YOUTUBE_API_KEY']

create_artist_mappings(artists, spotify_access_token, youtube_api_key)


# Seed users
require 'faker'

# Create 19 fake users
21.times do
  user = User.create!(
    email: Faker::Internet.email,
    display_name: Faker::Name.name,
    spotify_id: Faker::Alphanumeric.alphanumeric(number: 10),
    profile_image_url: Faker::Avatar.image,
    spotify_profile_url: "https://open.spotify.com/user/#{Faker::Alphanumeric.alphanumeric(number: 10)}"
  )
  puts "Created user: #{user.display_name}"

  # Assign artist stats for every existing artist to this user
  Artist.find_each do |artist|
    ArtistStat.create!(
      user: user,
      artist: artist,
      points: rand(1..1000)  # Assign random points between 1 and 1000
    )
  end
  puts "Assigned artist stats for user: #{user.display_name}"
end

puts "Seeding completed with 21 users and artist stats for every artist!"
