class LevelSourceHintsController < ApplicationController
  before_filter :authenticate_user!

  def add_hint
    raise "unauthorized" if !current_user.admin? && !current_user.hint_access?
    @level_source_id = params[:level_source_id]
    common(@level_source_id)
  end

  def show_hints
    raise "unauthorized" if !current_user.admin? && !current_user.hint_access?

    @level_source_id = params[:level_source_id]
    @hints = LevelSourceHint.where(level_source_id: @level_source_id).sort_by { |hint| -hint.times_proposed}
    common(@level_source_id)
  end

  def add_pop_hint
    raise "unauthorized" if !current_user.admin? && !current_user.hint_access?
    unsuccessful_level_sources = FrequentUnsuccessfulLevelSource.where(active: true).order('num_of_attempts desc')
    idx = params[:idx].to_i
    if (idx >= 0 && unsuccessful_level_sources.length > idx)
      @level_source_id = unsuccessful_level_sources.at(idx).level_source_id
      @num_of_attempts = unsuccessful_level_sources.at(idx).num_of_attempts
      @prev_path = add_pop_hint_path(idx - 1)
      @current_path = add_pop_hint_path(idx)
      @next_path = add_pop_hint_path(idx + 1)
      common(@level_source_id)
    elsif (idx < 0)
      redirect_to frequent_unsuccessful_level_sources_path, notice: 'You have reached the first error program.'
    else
      redirect_to frequent_unsuccessful_level_sources_path, notice: 'No more hint to show. Thank you very much!'
    end
  end

  def show_pop_hints
    raise "unauthorized" if !current_user.admin?
    unsuccessful_level_sources = FrequentUnsuccessfulLevelSource.order('num_of_attempts desc')
    idx = params[:idx].to_i
    if (idx >= 0 && unsuccessful_level_sources.length > idx)
      @level_source_id = unsuccessful_level_sources.at(idx).level_source_id
      @num_of_attempts = unsuccessful_level_sources.at(idx).num_of_attempts
      @prev_path = show_pop_hints_path(idx - 1)
      @current_path = show_pop_hints_path(idx)
      @next_path = show_pop_hints_path(idx + 1)
      @hints = LevelSourceHint.where(level_source_id: @level_source_id).sort_by { |hint| -hint.times_proposed}
      common(@level_source_id)
    elsif (idx < 0)
      redirect_to frequent_unsuccessful_level_sources_path, notice: 'You have reached the first error program.'
    else
      redirect_to frequent_unsuccessful_level_sources_path, notice: 'No more hint to be added. Thank you very much!'
    end
  end

  def add_pop_hint_per_level
    raise "unauthorized" if !current_user.admin? && !current_user.hint_access?
    unsuccessful_level_sources = FrequentUnsuccessfulLevelSource.where(active: true, level_id: params[:level_id].to_i).order('num_of_attempts desc')
    idx = params[:idx].to_i
    level_idx = params[:level_id].to_i
    if (idx >= 0 && unsuccessful_level_sources.length > idx)
      @level_source_id = unsuccessful_level_sources.at(idx).level_source_id
      @num_of_attempts = unsuccessful_level_sources.at(idx).num_of_attempts
      @prev_path = add_pop_hint_per_level_path(level_idx, idx - 1)
      @current_path = add_pop_hint_per_level_path(level_idx, idx)
      @next_path = add_pop_hint_per_level_path(level_idx, idx + 1)
      common(@level_source_id)
      render 'add_pop_hint'
    elsif (idx < 0)
      redirect_to frequent_unsuccessful_level_sources_path, notice: 'You have reached the first error program of this level.'
    else
      redirect_to frequent_unsuccessful_level_sources_path, notice: 'No more hint to be added. Please select another level.'
    end
  end

  def show_pop_hints_per_level
    raise "unauthorized" if !current_user.admin?
    unsuccessful_level_sources = FrequentUnsuccessfulLevelSource.where(level_id: params[:level_id].to_i).order('num_of_attempts desc')
    idx = params[:idx].to_i
    level_idx = params[:level_id].to_i
    if (idx >= 0 && unsuccessful_level_sources.length > idx)
      @level_source_id = unsuccessful_level_sources.at(idx).level_source_id
      @num_of_attempts = unsuccessful_level_sources.at(idx).num_of_attempts
      @prev_path = show_pop_hints_per_level_path(level_idx, idx - 1)
      @current_path = show_pop_hints_per_level_path(level_idx, idx)
      @next_path = show_pop_hints_per_level_path(level_idx, idx + 1)
      @hints = LevelSourceHint.where(level_source_id: @level_source_id).sort_by { |hint| -hint.times_proposed}
      common(@level_source_id)
      render 'show_pop_hints'
    elsif (idx < 0)
      redirect_to frequent_unsuccessful_level_sources_path, notice: 'You have reached the first error program of this level.'
    else
      redirect_to frequent_unsuccessful_level_sources_path, notice: 'No more hint to show. Please select another level.'
    end
  end

  def create
    raise "unauthorized" if !current_user.admin? && !current_user.hint_access?
    # Find or create the hint data
    level_source_hint =
        LevelSourceHint.where(level_source_id: params[:level_source_id], hint: params[:hint_content]).first_or_create
    # Update the times this hint has been proposed
    level_source_hint.times_proposed = (level_source_hint.times_proposed || 0) + 1
    # Record the user_id entering the hint
    level_source_hint.user_id = current_user.id
    level_source_hint.save!

    # Set the associated frequent_unsuccessful_level_source to be inactive
    FrequentUnsuccessfulLevelSource.where(level_source_id: params[:level_source_id]).each do | unsuccessful_level_source |
      unsuccessful_level_source.active = false
      unsuccessful_level_source.save!
    end

    # Redirecting to the params[:redirect] page
    redirect_url = params[:redirect]
    redirect_to redirect_url, notice: I18n.t('add_hint_form.submit')
  end

  def add_hint_access
    redirect_url = params[:redirect]
    user = User.where(email: params[:user_email]).first
    if user
      user.update_attribute(:hint_access, true)
      redirect_to redirect_url, notice: "User hint access added to #{params[:user_email]}"
    else
      redirect_to redirect_url, notice: "Failed: cannot find user with email #{params[:user_email]}."
    end
  end

  protected
  def common(level_source_id)
    @level_source = LevelSource.find(level_source_id)
    @start_blocks = @level_source.data
    @level = @level_source.level
    @game = @level.game
    @full_width = true
    @hide_source = false
    @share = true
  end
end
