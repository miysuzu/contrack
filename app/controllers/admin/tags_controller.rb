class Admin::TagsController < Admin::ApplicationController
  layout 'admin'
  before_action :set_tag, only: [:show, :destroy]

  def index
    @tags = ActsAsTaggableOn::Tag.includes(:taggings)
                                 .order(taggings_count: :desc)
    
    # タグ名での検索
    if params[:keyword].present?
      keyword = "%#{params[:keyword]}%"
      @tags = @tags.where("name LIKE ?", keyword)
    end
  end

  def show
    @contracts = Contract.tagged_with(@tag.name).includes(:user, :status).order(created_at: :desc)
  end

  def destroy
    if @tag.destroy
      redirect_to admin_tags_path, notice: "タグ「#{@tag.name}」を削除しました。"
    else
      redirect_to admin_tags_path, alert: "タグの削除に失敗しました。"
    end
  end

  private

  def set_tag
    @tag = ActsAsTaggableOn::Tag.find(params[:id])
  end
end
