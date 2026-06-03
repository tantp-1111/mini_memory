class StaticPagesController < ApplicationController
  skip_before_action :authenticate_user!
  # 未認証ランディングのため Pundit による認可は不要。
  skip_after_action :verify_authorized

  def top
  end

  def contact
  end

  def terms
  end

  def privacy
  end
end
