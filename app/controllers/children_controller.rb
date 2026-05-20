class ChildrenController < ApplicationController
  before_action :set_family_group
  before_action :set_child, only: %i[edit update destroy]

  def index
    @children = policy_scope(@family_group.children).order(:birthday)
    authorize @family_group, :show?
  end

  def new
    @child = @family_group.children.new
    authorize @child
  end

  def create
    @child = @family_group.children.new(child_params)
    authorize @child

    if @child.save
      redirect_to family_group_children_path(@family_group),
                  notice: t("defaults.flash_message.created", model: Child.model_name.human)
    else
      flash.now[:alert] = t("defaults.flash_message.not_created", model: Child.model_name.human)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @child
  end

  def update
    authorize @child
    if @child.update(child_params)
      redirect_to family_group_children_path(@family_group),
                  notice: t("defaults.flash_message.updated", model: Child.model_name.human)
    else
      flash.now[:alert] = t("defaults.flash_message.not_updated", model: Child.model_name.human)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @child
    @child.destroy!
    redirect_to family_group_children_path(@family_group),
                notice: t("defaults.flash_message.deleted", model: Child.model_name.human)
  end

  private

  # 非メンバーには 404（存在を隠す）、メンバー以上には authorize で操作種別を判定する二段防衛。
  def set_family_group
    @family_group = policy_scope(FamilyGroup).find_by!(uuid: params[:family_group_uuid])
  end

  def set_child
    @child = @family_group.children.find_by!(uuid: params[:uuid])
  end

  def child_params
    params.require(:child).permit(:name, :birthday)
  end
end
