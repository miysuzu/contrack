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

  def create
    @tag = ActsAsTaggableOn::Tag.new(tag_params)
    
    if @tag.save
      redirect_to admin_tags_path, notice: "タグ「#{@tag.name}」を作成しました。"
    else
      redirect_to admin_tags_path, alert: "タグの作成に失敗しました: #{@tag.errors.full_messages.join(', ')}"
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

  def tag_params
    # フォームから直接送信される場合とネストされた場合の両方に対応
    if params[:tag].present?
      params.require(:tag).permit(:name)
    else
      params.permit(:name)
    end
  end
end
