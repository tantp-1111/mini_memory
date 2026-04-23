class MypagesController < ApplicationController
  def show
    @user = current_user
    @family_group = current_user.family_groups.first
    @current_membership = @family_group&.user_family_groups&.find_by(user: current_user)
  end
end
