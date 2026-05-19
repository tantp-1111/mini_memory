class ReactionsController < ApplicationController
  before_action :set_memory
  before_action :validate_reaction_type!, only: %i[create destroy]

  # リアクションを追加
  def create
    authorize @memory, :react?

    reaction = @memory.reactions.build(
      user: current_user,
      reaction_type: params[:reaction_type]
    )

    if reaction.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to public_memory_path(@memory) }
      end
    else
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to public_memory_path(@memory), alert: reaction.errors.full_messages.join(", ") }
      end
    end
  rescue ActiveRecord::RecordNotUnique
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to public_memory_path(@memory), alert: t("reactions.alert.already_exists") }
    end
  end

  # リアクションを削除
  def destroy
    reaction = @memory.reactions.find_by!(
      user: current_user,
      reaction_type: params[:reaction_type]
    )
    authorize reaction

    reaction.destroy!
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to public_memory_path(@memory) }
    end
  end

  private

  # ネスト元 public_memories が param: :uuid のため、params[:public_memory_uuid] で受け取る。
  def set_memory
    @memory = Memory.find_by!(uuid: params[:public_memory_uuid])
  end

  def validate_reaction_type!
    return if Reaction.reaction_types.key?(params[:reaction_type])
    redirect_to public_memory_path(@memory), alert: t("reactions.alert.invalid_type")
  end
end
