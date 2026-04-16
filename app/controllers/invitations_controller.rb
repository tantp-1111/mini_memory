class InvitationsController < ApplicationController
  # 招待リンクの発行はログイン必須
  before_action :authenticate_user!, only: %i[create]
  # 招待リンクを踏む側は未ログインの可能性があるためスキップ
  skip_before_action :authenticate_user!, only: %i[show join]
  before_action :set_and_validate_invitation, only: %i[show join]


  def create
    family_group = current_user.family_groups.find(params[:family_group_id])
    family_group.invitations.create!
    redirect_to family_group, notice: "招待リンクが発行されました"
  end

  def show
    @family_group = @invitation.family_group
  end

  def join
    @family_group = @invitation.family_group
    UserFamilyGroup.create!(user: current_user, family_group: @family_group, role: :member)
    redirect_to mypage_path, notice: "#{@family_group.name}に参加しました"
  rescue ActiveRecord::RecordInvalid
    redirect_to invitation_path(params[:token]), alert: "グループへの参加に失敗しました"
  end

  private

  def set_and_validate_invitation
    @invitation = Invitation.find_by(token: params[:token])

    if @invitation.nil? || @invitation.expired?
      redirect_to root_path, alert: "招待リンクが無効または期限切れです" and return
    end

    unless user_signed_in?
      store_location_for(:user, invitation_path(params[:token]))
      redirect_to new_user_session_path, alert: "参加するにはログインが必要です" and return
    end

    if current_user.user_family_groups.exists?
      redirect_to mypage_path, alert: "すでにグループに参加しています" and return
    end
  end
end
