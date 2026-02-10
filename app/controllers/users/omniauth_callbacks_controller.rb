class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def line
    user = User.from_omniauth(request.env["omniauth.auth"])
    if user.persisted?
      sign_in user, event: :authentication
      flash[:notice] = "ログインしました"
      redirect_to authenticated_root_path
    else
      session["devise.line_data"] = request.env["omniauth.auth"].except(:extra)
      redirect_to new_user_session_path, alert: "ユーザー情報の取得に失敗しました。"
    end
  end
end
