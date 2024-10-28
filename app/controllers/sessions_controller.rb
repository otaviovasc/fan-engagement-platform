class SessionsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:omniauth_callback, :link_account, :create_account]

  # Handle OmniAuth callback for both signup and account linking
  def omniauth_callback
    auth = request.env['omniauth.auth']

    if current_user
      # Existing user: link the new account
      puts "Current user: #{current_user.email}"
      link_account(auth)
    else
      # New user: create a new account
      puts "New user: #{auth.info.email}"
      create_account(auth)
    end
  end

  def destroy
    session[:user_id] = nil
    reset_session  # This clears the entire session, including the CSRF token
    redirect_to root_path
  end

  def failure
    redirect_to new_user_waitlist_path, alert: 'User not allowed.'
  end

  private

  def link_account(auth)
    user = current_user  # We are sure the user is already logged in
    puts "Linking account for #{user.email}"

    case auth.provider
    when 'spotify'
      user.ensure_valid_access_token
      spotify_attributes = {
        spotify_id: auth.uid,
        access_token: auth.credentials.token,
        refresh_token: auth.credentials.refresh_token,
        display_name: auth.info.name || user.display_name || "Spotify User",  # Ensure display_name is updated
        spotify_profile_url: auth.info.urls.spotify,  # Add Spotify profile URL
        profile_image_url: extract_image_url(auth.info.images) || user.profile_image_url  # Ensure profile_image_url is updated
      }

      # Link Spotify to the existing user
      user.update(spotify_attributes)

    when 'google_oauth2'
      user.ensure_valid_youtube_access_token
      youtube_attributes = {
        youtube_id: auth.uid,
        youtube_access_token: auth.credentials.token,
        youtube_refresh_token: auth.credentials.refresh_token,
        display_name: auth.info.name || user.display_name || "YouTube User",
        profile_image_url: auth.info.image || user.profile_image_url
      }

      # Link YouTube to the existing user
      user.update(youtube_attributes)
    end

    redirect_to profile_path, notice: "Account successfully linked!"
  end


  def create_account(auth)
    # Try to find the user by email, YouTube ID, or Spotify ID
    user = User.find_by(email: auth.info.email) ||
           User.find_by(spotify_id: auth.uid) ||
           User.find_by(youtube_id: auth.uid)

    # If no user is found, initialize a new user (signing up)
    user ||= User.new(email: auth.info.email)

    case auth.provider
    when 'spotify'
      user.ensure_valid_access_token
      spotify_attributes = {
        spotify_id: auth.uid,
        access_token: auth.credentials.token,
        refresh_token: auth.credentials.refresh_token,
        display_name: auth.info.name || user.display_name || "Spotify User",  # Ensure display_name is updated
        spotify_profile_url: auth.info.urls.spotify,  # Add Spotify profile URL
        profile_image_url: extract_image_url(auth.info.images) || user.profile_image_url  # Ensure profile_image_url is updated
      }

      user.update(spotify_attributes)
    when 'google_oauth2'
      user.ensure_valid_youtube_access_token
      youtube_attributes = {
        youtube_id: auth.uid,
        youtube_access_token: auth.credentials.token,
        youtube_refresh_token: auth.credentials.refresh_token,
        display_name: auth.info.name || "YouTube User",
        profile_image_url: auth.info.image
      }

      user.update(youtube_attributes)
    end

    # Save the user in the session
    session[:user_id] = user.id
    redirect_to profile_path
  end

  def extract_image_url(images)
    images&.first&.fetch('url', nil)
  end
end
