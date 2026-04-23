class FamilyGroupsController < ApplicationController
  before_action :set_family_group, only: [ :edit, :update, :show, :destroy ]
  before_action :authenticate_user!

  def new
    @family_group = FamilyGroup.new
  end

  def create
    @family_group = FamilyGroup.new(family_group_params)

    # グループ作成とオーナー登録をトランザクションでまとめる
    ActiveRecord::Base.transaction do
      @family_group.save!
      UserFamilyGroup.create!(user: current_user, family_group: @family_group, role: :owner)
    end

    redirect_to @family_group, notice: "家族グループが作成されました"

  rescue ActiveRecord::RecordInvalid
    flash.now[:alert] = "家族グループの作成に失敗しました"
    render :new, status: :unprocessable_entity
  end

  def edit
  end

  def update
    if @family_group.update(family_group_params)
      redirect_to @family_group, notice: "家族グループが更新されました"
    else
      flash.now[:alert] = "家族グループの更新に失敗しました"
      render :edit, status: :unprocessable_entity
    end
  end

  def show
    # ログインユーザーのグループ内での役割を取得
    @current_membership = @family_group.user_family_groups.find_by(user: current_user)
    # オーナーかどうかを判定し、ビュー側で条件分岐できるようにインスタンス変数にセット
    @is_owner = @current_membership&.owner?
    # 最新の招待リンクを取得（存在する場合）
    @latest_invitation = @family_group.invitations.order(created_at: :desc).first
  end

  def destroy
    # オーナーのみグループ削除可能
    if @family_group.user_family_groups.find_by(user: current_user)&.owner?
      if @family_group.destroy
        redirect_to mypage_path, notice: "家族グループが削除されました"
      else
        redirect_to @family_group, alert: "家族グループの削除に失敗しました"
      end
    else
      redirect_to @family_group, alert: "家族グループの削除はオーナーのみ可能です"
    end
  end

  private

  def family_group_params
    params.require(:family_group).permit(:name)
  end

  def set_family_group
    @family_group = current_user.family_groups.find_by!(uuid: params[:uuid])
  end
end
