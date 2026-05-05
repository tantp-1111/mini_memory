class MypagesController < ApplicationController
  # 自分自身のプロフィール表示のため Pundit による認可は不要。
  skip_after_action :verify_authorized

  def show
    @user = current_user
    @family_group = current_user.family_groups.first
    @current_membership = @family_group&.user_family_groups&.find_by(user: current_user)
  end
end
