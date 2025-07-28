class DashboardsController < ApplicationController
  before_action :authenticate_user!

  def index
    @groups = current_user.groups
    @selected_group = if params[:group_id]
      @groups.find_by(id: params[:group_id])
    else
      @groups.first
    end
    @contracts = @selected_group ? @selected_group.contracts : []
  end
end
