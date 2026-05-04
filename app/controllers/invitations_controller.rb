class InvitationsController < ApplicationController
  # 招待リンクの発行(createアクション)はログイン必須
  before_action :authenticate_user!, only: %i[create]
  # 招待リンクのURLはログイン不要でアクセスできる
  skip_before_action :authenticate_user!, only: %i[show]
  before_action :set_and_validate_invitation, only: %i[show join]

  # 招待リンクの発行（owner であることは InvitationPolicy#create? で検証）
  def create
    @invitation = Invitation.new(family_group_id: params[:family_group_id])
    authorize @invitation
    @invitation.save!
    redirect_to @invitation.family_group, notice: "招待リンクが発行されました"
  end

  def show
    @family_group = @invitation.family_group
  end

  # 招待リンクを踏んで参加するアクション。
  # トークン検証は set_and_validate_invitation で済むが、authorize で
  # UserFamilyGroupPolicy#create? も通すことで verify_authorized 有効化時に対応できる構成にしておく。
  def join
    @family_group = @invitation.family_group
    membership = UserFamilyGroup.new(user: current_user, family_group: @family_group, role: :member)
    authorize membership
    membership.save!
    redirect_to mypage_path, notice: "#{@family_group.name}に参加しました"
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
    redirect_to invitation_path(params[:token]), alert: "グループへの参加に失敗しました"
  end

  private

  # 招待リンクの検証と参加条件のチェックを共通化
  def set_and_validate_invitation
    @invitation = Invitation.find_by(token: params[:token])

    # 招待リンクの有効性と期限切れのチェック
    if @invitation.nil? || @invitation.expired?
      redirect_to root_path, alert: "招待リンクが無効または期限切れです"
    end

    # ログインしていない場合はURLを保存し、ログインページへリダイレクト
    unless user_signed_in?
      store_location_for(:user, invitation_path(params[:token]))
      return redirect_to new_user_session_path, alert: "参加するにはログインが必要です"
    end

    # すでにグループに所属しているユーザーは参加できないようにする
    if current_user.user_family_groups.exists?
      redirect_to mypage_path, alert: "すでにグループに参加しています"
    end
  end
end
