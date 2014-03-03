class FrequentUnsuccessfulLevelSourcesController < ApplicationController
  before_filter :authenticate_user!

  def index
    raise "unauthorized" if !current_user.admin? && !current_user.hint_access?
  end
end
