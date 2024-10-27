class ArtistsController < ApplicationController
  before_action :authenticate_user!

  def show
    @artist = Artist.find(params[:id])

    if @artist
      @leaderboard = Rails.cache.fetch("artist_leaderboard/#{@artist.id}", expires_in: 1.hour) do
        ArtistStat.where(artist: @artist).order(points: :desc).includes(:user).to_a
      end

      respond_to do |format|
        format.turbo_stream { render partial: 'artists/leaderboard', locals: { artist: @artist, leaderboard: @leaderboard } }
        format.html { render partial: 'artists/leaderboard', locals: { artist: @artist, leaderboard: @leaderboard } }
        # ^ This ensures we can handle both turbo_stream and HTML requests, just in case
      end
    else
      redirect_to profile_path, alert: 'Artist not found.'
    end
  end


end
