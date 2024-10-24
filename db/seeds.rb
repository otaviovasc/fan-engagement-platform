# db/seeds.rb

require 'net/http'
require 'uri'
require 'json'
require 'base64'

# Function to get Spotify access token using Client Credentials Flow
def get_spotify_access_token
  client_id = ENV['SPOTIFY_CLIENT_ID']
  client_secret = ENV['SPOTIFY_CLIENT_SECRET']
  raise "Please set SPOTIFY_CLIENT_ID and SPOTIFY_CLIENT_SECRET environment variables" unless client_id && client_secret

  auth_token = Base64.strict_encode64("#{client_id}:#{client_secret}")

  uri = URI('https://accounts.spotify.com/api/token')
  request = Net::HTTP::Post.new(uri)
  request['Authorization'] = "Basic #{auth_token}"
  request.set_form_data('grant_type' => 'client_credentials')

  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    http.request(request)
  end

  json = JSON.parse(response.body)
  access_token = json['access_token']

  raise "Failed to obtain Spotify access token: #{json}" unless access_token

  access_token
end

# Function to fetch popular playlists from multiple categories and countries
def fetch_popular_playlists(access_token)
  categories = %w[sertanejo modão]
  countries = %w[BR US GB CA AU]
  playlists = []

  categories.each do |category|
    countries.each do |country|
      uri = URI("https://api.spotify.com/v1/browse/categories/#{category}/playlists?country=#{country}&limit=10")
      request = Net::HTTP::Get.new(uri)
      request['Authorization'] = "Bearer #{access_token}"

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(request)
      end

      next unless response.code.to_i == 200

      json = JSON.parse(response.body)
      if json['playlists'] && json['playlists']['items']
        playlists += json['playlists']['items']
      end

      break if playlists.size >= 50 # Limit the number of playlists to process
    end
    break if playlists.size >= 50
  end

  playlists.uniq { |p| p['id'] }[0...50] # Limit to 50 unique playlists
end

# Function to fetch tracks from a playlist
def fetch_tracks_from_playlist(access_token, playlist_id)
  tracks = []
  offset = 0
  limit = 100

  loop do
    uri = URI("https://api.spotify.com/v1/playlists/#{playlist_id}/tracks?offset=#{offset}&limit=#{limit}")
    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "Bearer #{access_token}"

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    break unless response.code.to_i == 200

    json = JSON.parse(response.body)
    tracks += json['items']
    break if json['items'].size < limit
    offset += limit
  end

  tracks
end

# Main script to fetch and save artists
def seed_artists
  access_token = get_spotify_access_token
  puts "Access token obtained"

  artists_hash = {}
  playlists = fetch_popular_playlists(access_token)
  puts "Fetched #{playlists.size} playlists"

  playlists.each_with_index do |playlist, index|
    puts "Processing playlist #{index + 1}/#{playlists.size}: #{playlist['name']}"
    tracks = fetch_tracks_from_playlist(access_token, playlist['id'])
    tracks.each do |track_item|
      track = track_item['track']
      next unless track && track['artists']
      track['artists'].each do |artist_data|
        artists_hash[artist_data['id']] ||= artist_data
      end
    end
    break if artists_hash.size >= 1000
  end

  artists_data = artists_hash.values[0...1000]
  puts "Fetched #{artists_data.size} unique artists"

  artists_data.each_with_index do |artist_data, index|
    artist = Artist.find_or_initialize_by(spotify_id: artist_data['id'])
    artist.name = artist_data['name']

    # Fetch artist details to get image URL
    artist_details = fetch_artist_details(access_token, artist.spotify_id)
    if artist_details && artist_details['images'] && artist_details['images'].any?
      artist.image_url = artist_details['images'].first['url']
    else
      artist.image_url = nil
    end

    artist.save!
    puts "Saved artist #{index + 1}/#{artists_data.size}: #{artist.name}"
  end
end

# Function to fetch artist details
def fetch_artist_details(access_token, artist_id)
  uri = URI("https://api.spotify.com/v1/artists/#{artist_id}")
  request = Net::HTTP::Get.new(uri)
  request['Authorization'] = "Bearer #{access_token}"

  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    http.request(request)
  end

  return nil unless response.code.to_i == 200

  JSON.parse(response.body)
end

# Run the seeding process
seed_artists
