class SessionsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :create  # Skip CSRF check for OAuth callbacks

  def passthru
    render plain: "OmniAuth is not responding.", status: 404
  end

  def create
    auth = request.env['omniauth.auth']
    user = current_user || User.find_or_create_by(email: auth.info.email)

    case auth.provider
    when 'spotify'
      # Build the parameters conditionally
      user.ensure_valid_access_token
      spotify_attributes = {
        spotify_id: auth.uid,
        access_token: auth.credentials.token,
        refresh_token: auth.credentials.refresh_token
      }

      # Only update display_name if it's blank
      if user.display_name.blank?
        spotify_attributes[:display_name] = auth.info.display_name || auth.info.name || "Spotify User"
      end

      # Only update profile_image_url if it's blank
      if user.profile_image_url.blank?
        spotify_attributes[:profile_image_url] = extract_image_url(auth.info.images)
      end

      # Update the user with the built attributes
      user.update(spotify_attributes) unless user.spotify_id.present?

    when 'google_oauth2'
      # Build the parameters conditionally
      youtube_attributes = {
        youtube_id: auth.uid,
        youtube_access_token: auth.credentials.token,
        youtube_refresh_token: auth.credentials.refresh_token
      }

      # Only update display_name if it's blank
      if user.display_name.blank?
        youtube_attributes[:display_name] = auth.info.name || "YouTube User"
      end

      # Only update profile_image_url if it's blank
      if user.profile_image_url.blank?
        youtube_attributes[:profile_image_url] = auth.info.image
      end

      # Update the user with the built attributes
      user.update(youtube_attributes) unless user.youtube_id.present?
    end

    session[:user_id] = user.id
    redirect_to profile_path
  end

  def destroy
    session[:user_id] = nil
    reset_session  # This clears the entire session, including the CSRF token
    redirect_to root_path
  end

  def failure
    redirect_to root_path, alert: 'Authentication failed.'
  end

  private

  def extract_image_url(images)
    images&.first&.fetch('url', nil)
  end
end
