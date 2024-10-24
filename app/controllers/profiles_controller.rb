class ProfilesController < ApplicationController
  before_action :authenticate_user!

  def show
    # Fetch data from both platforms if connected
    if current_user.spotify_connected?
      fetch_user_top_artists_spotify
    end

    if current_user.youtube_connected?
      fetch_user_recently_played_youtube
    end

    # Fetch top artists from the database based on ArtistStat points
    @top_artists = current_user.artist_stats.includes(:artist).order(points: :desc).limit(20).map(&:artist)
  end


  # def show
  #   cache_key = nil
  #   if current_user.spotify_connected?
  #     cache_key = "#{current_user.id}/spotify_top_artists"
  #     @top_artists = Rails.cache.fetch(cache_key, expires_in: 1.hour) do
  #       fetch_user_top_artists_spotify
  #     end
  #   elsif current_user.youtube_connected?
  #     cache_key = "#{current_user.id}/youtube_recent_artists"
  #     @top_artists = Rails.cache.fetch(cache_key, expires_in: 1.hour) do
  #       fetch_user_recently_played_youtube
  #     end
  #   else
  #     @top_artists = []
  #   end

  #   # Set the cache expiration time to send to the frontend
  #   cache_expires_at = Rails.cache.read("#{cache_key}_expires_at") || Time.now + 1.hour
  #   Rails.cache.write("#{cache_key}_expires_at", cache_expires_at, expires_in: 1.hour)
  #   @cache_expires_at = cache_expires_at

  #   # Fetch top artists from the database
  #   @top_artists = current_user.artist_stats.includes(:artist).order(points: :desc).limit(20).map(&:artist)
  # end



  private

  # Fetch Spotify Top Artists
  def fetch_user_top_artists_spotify
    response = HTTParty.get(
      'https://api.spotify.com/v1/me/top/artists',
      headers: { 'Authorization' => "Bearer #{current_user.access_token}" }
    )

    artists = response.parsed_response['items']

    artists.each do |artist_data|
      artist = Artist.find_or_create_by(spotify_id: artist_data['id']) do |a|
        a.name = artist_data['name']
        a.image_url = artist_data['images'].first['url'] if artist_data['images'].any?
      end

      # Fetch total listening time for this artist
      total_listening_time = fetch_artist_listening_time(artist_data['id'])

      # Update the artist's stats with actual listening time
      ArtistStat.find_or_create_by(user: current_user, artist: artist) do |stat|
        stat.points += total_listening_time * 10 # 10 points per minute
        stat.save
      end
    end
    artists
  end

  def fetch_artist_listening_time(artist_id)
    # Call Spotify's 'recently-played' endpoint to get tracks
    response = HTTParty.get(
      'https://api.spotify.com/v1/me/player/recently-played',
      headers: { 'Authorization' => "Bearer #{current_user.access_token}" },
      query: { time_range: 'medium_term' } # Can be 'medium_term' or 'long_term'
    )

    if response.code == 200
      tracks = response.parsed_response['items']
      total_time = 0

      tracks.each do |track|
        track_artists = track['track']['artists'].map { |artist| artist['id'] }

        if track_artists.include?(artist_id)
          # Add the track duration to total time (duration is in milliseconds)
          total_time += track['track']['duration_ms']
        end
      end

      # Convert milliseconds to minutes (or your preferred unit)
      total_time_in_minutes = total_time / 1000 / 60
      total_time_in_minutes
    else
      Rails.logger.error "Error fetching recently played tracks: #{response.body}"
      0
    end
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

      # Attempt to find an existing artist using fuzzy matching
      artist = Artist.find_by_fuzzy_name(channel_title)

      if artist
        # If a match is found, update the YouTube ID if it isn't already set
        unless artist.youtube_id
          artist.update(youtube_id: channel_id)
          Rails.logger.info "Added YouTube ID to existing artist: #{artist.name} (YouTube ID: #{channel_id})"
        end

        # Calculate points for this artist
        artist_stat = ArtistStat.find_or_initialize_by(user: current_user, artist: artist)

        # Check if the user is subscribed to the artist's YouTube channel
        if user_subscribed_to_channel?(channel_id)
          artist_stat.points += 100 # 100 points for being subscribed
        end

        # Add 20 points for each liked video
        artist_stat.points += 40
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
