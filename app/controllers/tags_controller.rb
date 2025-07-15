class TagsController < ApplicationController
  before_action :authenticate_user!

  def index
    @tags = ActsAsTaggableOn::Tag.all.order(:name)
  end
end 