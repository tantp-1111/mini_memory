# frozen_string_literal: true

# 新規登録・アカウント編集時にname属性を許可するためのコントローラー

class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_sign_up_params, only: [ :create ]
  before_action :configure_account_update_params, only: [ :update ]

  # GET /resource/sign_up
  # def new
  #   super
  # end

  # POST /resource
  # def create
  #   super
  # end

  # GET /resource/edit
  # def edit
  #   super
  # end

  # PUT /resource
  # def update
  #   super
  # end

  # DELETE /resource
  # def destroy
  #   super
  # end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  # def cancel
  #   super
  # end

  protected

  # 許可する追加のパラメータがある場合は、それらをサニタイザーに追加(sign_up用) - ストロングパラメータ
  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :name ])
  end

  # 許可する追加のパラメータがある場合は、それらをサニタイザーに追加(account_update用) - ストロングパラメータ
  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [ :name ])
  end

  # sign up後のリダイレクト先を指定(dashboard#top)
  def after_sign_up_path_for(resource)
    authenticated_root_path
  end

  # アカウント更新時にパスワード不要で更新を可能にする
  def update_resource(resource, params)
    resource.update_without_password(params)
  end

  # アカウントupdate後のリダイレクト先を指定(mypage#show)
  def after_update_path_for(resource)
    mypage_path
  end

  # inactive sign up後のリダイレクト先を指定(confirmableモジュール使用時)
  # def after_inactive_sign_up_path_for(resource)
  #   root_path
  # end
end
