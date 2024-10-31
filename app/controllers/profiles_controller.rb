class ProfilesController < ApplicationController
  before_action :authenticate_user!

  def show
    if current_user.spotify_connected?
      current_user.ensure_valid_access_token
      fetch_user_top_artists_spotify
    end

    if current_user.youtube_connected?
      puts "Fetching YouTube data"
      current_user.ensure_valid_youtube_access_token
      fetch_user_recently_played_youtube
    end

    # Update each artist_stat's total points based on spotify_points and youtube_points
    current_user.artist_stats.each do |artist_stat|
      artist_stat.update(points: artist_stat.spotify_points + artist_stat.youtube_points)
    end

    # Fetch top artists based on the updated points
    @top_artists = current_user.artist_stats.includes(:artist).order(points: :desc).limit(20).map(&:artist)
  end

  # def show
  #   # Cache key for Spotify top artists
  #   spotify_cache_key = "user/#{current_user.id}/spotify_top_artists"
  #   youtube_cache_key = "user/#{current_user.id}/youtube_recent_artists"

  #   # Fetch Spotify data only if the user is connected and data is not cached or expired
  #   if current_user.spotify_connected?
  #     @spotify_top_artists = Rails.cache.fetch(spotify_cache_key, expires_in: 1.hour) do
  #       fetch_user_top_artists_spotify
  #     end
  #   end

  #   # Fetch YouTube data only if the user is connected and data is not cached or expired
  #   if current_user.youtube_connected?
  #     @youtube_recent_artists = Rails.cache.fetch(youtube_cache_key, expires_in: 1.hour) do
  #       fetch_user_recently_played_youtube
  #     end
  #   end

  #   # Fetch top artists from the database based on ArtistStat points
  #   @top_artists = current_user.artist_stats.includes(:artist).order(points: :desc).limit(20).map(&:artist)
  # end

  private

  # Fetch Spotify Top Artists
  def fetch_user_top_artists_spotify

    # Fetch and store any new recently played tracks from Spotify
    fetch_recently_played_tracks

    response = HTTParty.get(
      'https://api.spotify.com/v1/me/top/artists',
      headers: { 'Authorization' => "Bearer #{current_user.access_token}" }
    )

    if response.code != 200 || response.parsed_response['items'].nil?
      Rails.logger.error "Spotify API error: #{response.body}"
      return []
    end

    artists = response.parsed_response['items']

    artists.each do |artist_data|
      artist = Artist.find_or_create_by(spotify_id: artist_data['id']) do |a|
        a.name = artist_data['name']
        a.image_url = artist_data['images'].first['url'] if artist_data['images'].any?
      end

      # Calculate total listening time for this artist based on last 30 days in UserTrack
      total_listening_time = calculate_listening_time_for_artist(artist.spotify_id)

      # Update or initialize ArtistStat with points based on last month's listening time
      artist_stat = ArtistStat.find_or_initialize_by(user: current_user, artist: artist)
      artist_stat.spotify_points = total_listening_time * 10
      artist_stat.save
    end
    artists
  end

  def fetch_recently_played_tracks
    one_month_ago = 30.days.ago
    response = HTTParty.get(
      'https://api.spotify.com/v1/me/player/recently-played',
      headers: { 'Authorization' => "Bearer #{current_user.access_token}" },
      query: { limit: 50 }
    )

    if response.code == 200
      tracks = response.parsed_response['items'].select do |track|
        DateTime.parse(track['played_at']) >= one_month_ago
      end

      tracks.each do |track|
        played_at = DateTime.parse(track['played_at'])
        spotify_track_id = track['track']['id']
        artist_id = track['track']['artists'].first['id']  # Assuming the first artist is the main artist

        # Store each play as a new entry if it hasn't been stored yet
        unless current_user.user_tracks.where(spotify_track_id: spotify_track_id).where("played_at = ?", played_at).exists?
          current_user.user_tracks.create(
            track_name: track['track']['name'],
            artist_names: track['track']['artists'].map { |artist| artist['name'] }.join(", "),
            spotify_track_id: spotify_track_id,
            artist_id: artist_id,  # Save the main artist's ID
            played_at: played_at,
            duration_ms: track['track']['duration_ms']
          )
        end
      end
    else
      Rails.logger.error "Error fetching recently played tracks: #{response.body}"
    end
  end

  def calculate_listening_time_for_artist(artist_id)
    one_month_ago = 30.days.ago

    # Calculate total time in minutes for the given artist
    user_tracks = current_user.user_tracks
                              .where("played_at >= ?", one_month_ago)
                              .where(artist_id: artist_id)

    total_time = user_tracks.sum { |track| track.duration_ms } / 1000 / 60  # in minutes
    total_time
  end

  # Fetch YouTube Recently Played Videos and Assign Points
  def fetch_user_recently_played_youtube
    channels_response = HTTParty.get(
      'https://www.googleapis.com/youtube/v3/channels',
      query: {
        part: 'contentDetails',
        mine: true,
        access_token: current_user.youtube_access_token
      }
    )

    if channels_response.code == 200
      channels = channels_response.parsed_response['items']
      if channels.any?
        likes_playlist_id = channels.first['contentDetails']['relatedPlaylists']['likes']
        fetch_and_process_liked_videos(likes_playlist_id)
      else
        Rails.logger.error "No channels found for user"
      end
    else
      Rails.logger.error "YouTube Channels API error: #{channels_response.body}"
    end
  end

  def fetch_and_process_liked_videos(playlist_id)
    response = HTTParty.get(
      'https://www.googleapis.com/youtube/v3/playlistItems',
      query: {
        part: 'snippet',
        playlistId: playlist_id,
        maxResults: 100,
        access_token: current_user.youtube_access_token
      }
    )

    if response.code == 200
      items = response.parsed_response['items']
      items.each do |item|
        video_id = item['snippet']['resourceId']['videoId']
        process_video(video_id) if video_id
      end
    else
      Rails.logger.error "YouTube PlaylistItems API error: #{response.body}"
    end
  end

  def process_video(video_id)
    video_details = fetch_video_details(video_id)
    return unless video_details

    # Check if the video is in the Music category
    if video_details['snippet']['categoryId'] == '10' # Category 10 is "Music"
      channel_id = video_details['snippet']['channelId']
      channel_title = video_details['snippet']['channelTitle']

      # Try to find the artist by YouTube ID in the mapping
      artist = Artist.joins(:artist_mapping).find_by(artist_mappings: { youtube_id: channel_id })

      # If no mapped artist is found, use fuzzy matching as a fallback
      artist ||= Artist.find_by_fuzzy_name(channel_title)

      if artist
        # If a match is found, update the YouTube ID if it isn't already set
        unless artist.youtube_id
          artist.update(youtube_id: channel_id)
          Rails.logger.info "Added YouTube ID to existing artist: #{artist.name} (YouTube ID: #{channel_id})"
        end

        # Calculate points for this artist
        artist_stat = ArtistStat.find_or_initialize_by(user: current_user, artist: artist)

        # Track processed videos to avoid duplicating points
        unless artist_stat.processed_videos.include?(video_id)
          # Calculate points only if the video hasn't been processed before
          artist_stat.processed_videos << video_id

          # Add 100 points for subscription only if they haven't been added before
          if user_subscribed_to_channel?(channel_id) && !artist_stat.subscribed_points_added
            artist_stat.youtube_points += 100
            artist_stat.subscribed_points_added = true  # Add a boolean attribute to track this
          end

          # Add points for each new liked video
          artist_stat.youtube_points += 40 # 40 points per new liked video
        end

        # Update processed_videos and save the updated stats
        artist_stat.updated_at = Time.now
        artist_stat.save
      else
        Rails.logger.info "No matching artist found for YouTube channel: #{channel_title}"
      end
    end
  end

  # Fetch video details to check category and channel
  def fetch_video_details(video_id)
    video_response = HTTParty.get(
      'https://www.googleapis.com/youtube/v3/videos',
      query: {
        part: 'snippet',
        id: video_id,
        key: ENV['YOUTUBE_API_KEY']
      }
    )

    if video_response.code == 200 && video_response.parsed_response['items'].any?
      video_response.parsed_response['items'].first
    else
      Rails.logger.error "YouTube Video API error: #{video_response.body}"
      nil
    end
  end

  # Check if the user is subscribed to a channel
  def user_subscribed_to_channel?(channel_id)
    response = HTTParty.get(
      'https://www.googleapis.com/youtube/v3/subscriptions',
      query: {
        part: 'snippet',
        forChannelId: channel_id,
        mine: true,
        access_token: current_user.youtube_access_token
      }
    )

    response.code == 200 && response.parsed_response['items'].any?
  end

  # Fetch channel image
  def fetch_channel_image(channel_id)
    response = HTTParty.get(
      'https://www.googleapis.com/youtube/v3/channels',
      query: {
        part: 'snippet',
        id: channel_id,
        key: ENV['YOUTUBE_API_KEY']
      }
    )

    if response.code == 200 && response.parsed_response['items'].any?
      response.parsed_response['items'].first['snippet']['thumbnails']['default']['url']
    else
      Rails.logger.error "YouTube Channel API error: #{response.body}"
      nil
    end
  end
end
