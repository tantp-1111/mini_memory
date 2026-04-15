class FamilyGroupsController < ApplicationController
  before_action :authenticate_user!

  def new
    @family_group = FamilyGroup.new
  end

  def create
    @family_group = FamilyGroup.new(family_group_params)

    ActiveRecord::Base.transaction do
      @family_group.save!
      UserFamilyGroup.create!(user: current_user, family_group: @family_group, role: :owner)
    end

    redirect_to @family_group, notice: "家族グループが作成されました"

  rescue ActiveRecord::RecordInvalid
    flash.now[:alert] = "家族グループの作成に失敗しました"
    render :new, status: :unprocessable_entity
  end

  def update
    @family_group = current_user.family_groups.find(params[:id])
    if @family_group.update(family_group_params)
      redirect_to @family_group, notice: "家族グループが更新されました"
    else
      flash.now[:alert] = "家族グループの更新に失敗しました"
      render :edit, status: :unprocessable_entity
    end
  end

  def show
    @family_group = current_user.family_groups.find(params[:id])
  end

  def destroy
    @family_group = current_user.family_groups.find(params[:id])
    if @family_group.user_family_groups.find_by(user: current_user)&.owner?
      @family_group.destroy
      redirect_to dashboard_path, notice: "家族グループが削除されました"
    else
      redirect_to @family_group, alert: "家族グループの削除はオーナーのみ可能です"
    end
  end

  private

  def family_group_params
    params.require(:family_group).permit(:name)
  end
end
