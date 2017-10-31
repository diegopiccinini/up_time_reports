class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def google_oauth2
    @user = User.from_omniauth(request.env['omniauth.auth'])

    if @user && @user.enabled && !@user.expired?
      sign_in_and_redirect @user
    else
      flash[:error]= "Authentication failed filtering by domain #{ENV['CUSTOM_DOMAIN_FILTER']}! "
      flash[:error] << "Your user is disabled in this server" if @user && !@user.enabled
      flash[:error] << "Your user is expired, please contact the Engineering Team." if @user && @user.expired?
      redirect_to new_user_session_path
    end
  end
end
