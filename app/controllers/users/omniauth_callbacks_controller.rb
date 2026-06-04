class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def line
    callback_for(:line)
  end

  def google_oauth2
    callback_for(:google_oauth2)
  end

  private

  def callback_for(provider)
    user = User.from_omniauth(request.env["omniauth.auth"])
    if user.persisted?
      sign_in user, event: :authentication
      flash[:notice] = "#{provider_name(provider)}でログインしました"
      redirect_to stored_location_for(user) || authenticated_root_path
    else
      session["devise.#{provider}_data"] = request.env["omniauth.auth"].except(:extra)
      redirect_to new_user_session_path, alert: "ユーザー情報の取得に失敗しました。"
    end
  end

  def provider_name(provider)
    {
      line: "LINE",
      google_oauth2: "Google"
    }.fetch(provider.to_sym, provider.to_s.titleize)
  end
end
