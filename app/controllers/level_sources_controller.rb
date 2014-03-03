require 'image_lib'

class LevelSourcesController < ApplicationController
  include LevelsHelper
  helper_method :show_image

  def show
    common(true)
  end

  def edit
    common(false)
    # currently edit is the same as show...
    render "show"
  end

  protected
  def common(hide_source)
    @level_source_id = params[:id]
    @level_source = LevelSource.find(@level_source_id)
    @start_blocks = @level_source.data
    @level = @level_source.level
    @game = @level.game
    @full_width = true
    @hide_source = hide_source
    @share = true
    @no_padding = @share && phone? && @game.app == "flappy"
  end
end
