class ReactionsController < ApplicationController
  before_action :set_memory

  # リアクションを追加
  def create
    authorize @memory, :react?

    reaction = @memory.reactions.build(
      user: current_user,
      reaction_type: params[:reaction_type]
    )

    if reaction.save
      redirect_to public_memory_path(@memory)
    else
      redirect_to public_memory_path(@memory), alert: reaction.errors.full_messages.join(", ")
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
    redirect_to public_memory_path(@memory)
  end

  private

  # ネスト元 public_memories が param: :uuid のため、params[:public_memory_uuid] で受け取る。
  def set_memory
    @memory = Memory.find_by!(uuid: params[:public_memory_uuid])
  end
end
