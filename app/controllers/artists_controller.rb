class ArtistsController < ApplicationController
  before_action :authenticate_user!

  def show
    unless turbo_frame_request?
      redirect_to profile_path
      return
    end
    @artist = Artist.find(params[:id])

    if @artist
      @leaderboard = ArtistStat.where(artist: @artist).order(points: :desc).includes(:user).to_a

      # Get the current user's stats if they're not already in the top 10
      @current_user_stat = ArtistStat.find_by(user: current_user, artist: @artist)

      respond_to do |format|
        format.turbo_stream { render partial: 'artists/leaderboard', locals: { artist: @artist, leaderboard: @leaderboard, current_user_stat: @current_user_stat } }
        format.html { render partial: 'artists/leaderboard', locals: { artist: @artist, leaderboard: @leaderboard, current_user_stat: @current_user_stat } }
      end
    else
      redirect_to profile_path, alert: 'Artist not found.'
    end
  end
  # def show
  #   unless turbo_frame_request?
  #     redirect_to profile_path
  #     return
  #   end
  #   @artist = Artist.find(params[:id])

  #   if @artist
  #     @leaderboard = Rails.cache.fetch("artist_leaderboard/#{@artist.id}", expires_in: 1.hour) do
  #       ArtistStat.where(artist: @artist).order(points: :desc).includes(:user).to_a
  #     end

  #     # Get the current user's stats if they're not already in the top 10
  #     @current_user_stat = ArtistStat.find_by(user: current_user, artist: @artist)

  #     respond_to do |format|
  #       format.turbo_stream { render partial: 'artists/leaderboard', locals: { artist: @artist, leaderboard: @leaderboard, current_user_stat: @current_user_stat } }
  #       format.html { render partial: 'artists/leaderboard', locals: { artist: @artist, leaderboard: @leaderboard, current_user_stat: @current_user_stat } }
  #     end
  #   else
  #     redirect_to profile_path, alert: 'Artist not found.'
  #   end
  # end


end
