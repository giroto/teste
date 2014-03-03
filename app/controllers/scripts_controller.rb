class ScriptsController < ApplicationController
  before_filter :authenticate_user!
  check_authorization

  def index
    authorize! :manage, Script
    # Show all the scripts that a user has created.
    @scripts = Script.where(user: current_user)
  end

  def new
    authorize! :manage, Script
    @script = Script.new
  end

  def create
    authorize! :manage, Script
    params[:script].require(:name)
    script = Script.create!(name: params[:script][:name], user: current_user)
    flash.notice = t("builder.created")
    redirect_to scripts_path
  end

  def edit
    authorize! :manage, Script
    @script = Script.find(params[:id])
    @current_script_levels = ScriptLevel.where(script_id: params[:id]).order(:chapter)
    # Get all levels that were created by seed (null user) or this user.
    @levels = Level.where("user_id is NULL or user_id = ?", current_user)
  end

  def sort
    authorize! :manage, Script

    script = Script.find(params[:id])
    old_script_levels = ScriptLevel.where(script: script).to_a  # tracks which levels are no longer included in script.

    params.fetch(:level, []).each_with_index do |level, index|
      script_level = ScriptLevel.where(level_id: level, script: script).first_or_create # 1 based indexed chapters
      old_script_levels.delete(script_level)
      script_level.update(chapter: index + 1, game_chapter: index + 1)
    end
    # old_script_levels now contains script_levels that were removed.
    old_script_levels.each { |sl| ScriptLevel.delete(sl) }

    render nothing: true
  end

  def destroy
    authorize! :manage, Script
    Script.find(params[:id]).destroy
    flash.notice = t("builder.destroyed")
    redirect_to scripts_path
  end
end
