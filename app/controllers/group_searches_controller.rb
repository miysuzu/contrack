class GroupSearchesController < ApplicationController
  def index
    # 自分の会社のグループのみを表示
    if current_user.company
      if params[:keyword].present?
        @groups = current_user.company.groups.where("name LIKE ?", "%#{params[:keyword]}%")
      else
        @groups = current_user.company.groups
      end
    else
      @groups = Group.none
    end
    @joined_group_ids = current_user.groups.pluck(:id)
  end
end
