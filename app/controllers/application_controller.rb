class ApplicationController < ActionController::Base
  include Pundit::Authorization

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :authenticate_user!, unless: :devise_controller?

  # Pundit::NotAuthorizedError を捕捉し、flash + 元のページへ戻すハンドリング。
  # verify_authorized は意図的に有効化していない（既存コントローラへの段階導入のため）。
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  protected

  # サインアップ時にname入力を許可
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :name ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :name ])
  end

  private

  def user_not_authorized
    flash[:alert] = t("pundit.not_authorized")
    redirect_back fallback_location: root_path
  end
end
