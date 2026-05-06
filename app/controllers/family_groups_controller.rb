class FamilyGroupsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_family_group, only: [ :edit, :update, :show, :destroy ]

  def new
    @family_group = FamilyGroup.new
    authorize @family_group
  end

  def create
    @family_group = FamilyGroup.new(family_group_params)
    authorize @family_group

    # グループ作成とオーナー登録をトランザクションでまとめる
    ActiveRecord::Base.transaction do
      @family_group.save!
      UserFamilyGroup.create!(user: current_user, family_group: @family_group, role: :owner)
    end

    redirect_to @family_group, notice: "家族グループが作成されました"

  rescue ActiveRecord::RecordInvalid
    flash.now[:alert] = "家族グループの作成に失敗しました"
    render :new, status: :unprocessable_entity
  rescue ActiveRecord::RecordNotUnique # race condition 等の防御的フォールバック
    redirect_to mypage_path, alert: "既に家族グループに所属しています"
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
    # 最新の招待リンクを取得（存在する場合）。owner 判定は view 側で policy(...) を用いる。
    @latest_invitation = @family_group.invitations.where("expires_at > ?", Time.current).order(created_at: :desc).first
  end

  def destroy
    if @family_group.destroy
      redirect_to mypage_path, notice: "家族グループが削除されました"
    else
      redirect_to @family_group, alert: "家族グループの削除に失敗しました"
    end
  end

  private

  def family_group_params
    params.require(:family_group).permit(:name)
  end

  # 非メンバーには 404（存在を隠す）、メンバー以上には authorize で操作種別を判定する二段防衛。
  def set_family_group
    @family_group = policy_scope(FamilyGroup).find_by!(uuid: params[:uuid])
    authorize @family_group
  end
end
