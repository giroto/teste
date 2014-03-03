class RegistrationsController < Devise::RegistrationsController

  before_filter :nonminimal

  def update
    @user = User.find(current_user.id)
    params.permit!

    # If email has changed for a non-teacher: clear confirmed_at but don't send notification email
    @user.skip_reconfirmation! if params[:user][:email].present? && !@user.confirmation_required?
    @user.confirmed_at = nil if params[:user][:email].present? && !@user.confirmation_required?

    successfully_updated = if needs_password?(@user, params)
      @user.update_with_password(params[:user])
    else
      # remove the virtual current_password attribute update_without_password
      # doesn't know how to ignore it
      params[:user].delete(:current_password)
      @user.update_without_password(params[:user])
    end

    if successfully_updated
      set_flash_message :notice, @user.pending_reconfirmation? ? :update_needs_confirmation : :updated
      cookies[:language_] = @user.locale
      # Sign in the user bypassing validation in case his password changed
      sign_in @user, :bypass => true
      redirect_to after_update_path_for(@user)
    else
      render "edit", formats: [:html]
    end
  end

  private

  # check if we need password to update user data
  # ie if password or email was changed
  # extend this as needed
  def needs_password?(user, params)
    user.email != params[:user][:email] ||
        params[:user][:password].present?
  end
end
