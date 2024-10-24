class UserWaitlistsController < ApplicationController
  def new
    @user_waitlist = UserWaitlist.new
  end

  def create
    @user_waitlist = UserWaitlist.new(user_waitlist_params)

    if @user_waitlist.save
      # If email is successfully saved, you might want to redirect or flash a message
      redirect_to new_user_waitlist_path, notice: "Thanks for signing up! Please confirm your email to join the alpha."
    else
      # Re-render the form if there was an error
      render :new
    end
  end

  private

  def user_waitlist_params
    params.require(:user_waitlist).permit(:email)
  end
end
