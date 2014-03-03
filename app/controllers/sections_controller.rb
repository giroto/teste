class SectionsController < ApplicationController
  before_filter :authenticate_user!
  check_authorization
  load_and_authorize_resource

  before_action :set_section, only: [:edit, :update, :destroy]

  def new
    @section = Section.new
  end

  def edit
  end

  def create
    # this will quietly do nothing if this section already exists
    @section = Section.where(user: current_user, name: section_params[:name]).first_or_create!
    @section.user = current_user

    respond_to do |format|
      if @section.save
        format.html { redirect_to sections_followers_path, notice: I18n.t('crud.created', model: Section.model_name.human) }
      else
        format.html { render action: 'new' }
      end
    end
  end

  def update
    respond_to do |format|
      if @section.update(section_params)
        format.html { redirect_to sections_followers_path, notice: I18n.t('crud.updated', model: Section.model_name.human) }
      else
        format.html { render action: 'edit' }
      end
    end
  end

  def destroy
    Follower.where(:section_id => @section.id).update_all(:section_id => nil)

    @section.destroy
    
    respond_to do |format|
      format.html { redirect_to sections_followers_path, notice: I18n.t('crud.destroyed', model: Section.model_name.human) }
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_section
    @section = Section.find(params[:id])

    if @section.present?
      user = User.find_by_id(@section.user_id)
      if !current_user.admin? && (!user || (user.id != current_user.id))
        flash[:alert] = I18n.t('crud.access_denied', model: Section.model_name.human)
        redirect_to sections_followers_path
        return
      end
    end
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def section_params
    params.require(:section).permit(:name)
  end

  # this is to fix a ForbiddenAttributesError cancan issue
  prepend_before_filter do
    params[:section] &&= section_params
  end
end
