# frozen_string_literal: true

# コントローラーをカスタマイズしてサインイン・サインアウト後のリダイレクト先を指定
class Users::SessionsController < Devise::SessionsController
  # before_action :configure_sign_in_params, only: [:create]

  # GET /resource/sign_in
  # def new
  #   super
  # end

  # POST /resource/sign_in
  # def create
  #   super
  # end

  # DELETE /resource/sign_out
  # def destroy
  #   super
  # end

  protected

  # ログイン時に email / password 以外のパラメータを送るときに使用
  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_in_params
  #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
  # end

  # サインイン後のリダイレクト先を指定
  def after_sign_in_path_for(resource)
    authenticated_root_path
  end

  # サインアウト後のリダイレクト先を指定
  def after_sign_out_path_for(resource_or_scope)
    new_user_session_path
  end
end
