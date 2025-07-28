class TagsController < ApplicationController
  before_action :authenticate_user!

  def index
    @tags = ActsAsTaggableOn::Tag.all.order(:name)
  end

  def create
    # 既存のタグをチェック
    existing_tag = ActsAsTaggableOn::Tag.find_by(name: params[:name])
    
    if existing_tag
      redirect_to tags_path, alert: "タグ「#{params[:name]}」は既に存在します"
    else
      @tag = ActsAsTaggableOn::Tag.new(name: params[:name])
      
      if @tag.save
        redirect_to tags_path, notice: "タグ「#{@tag.name}」を追加しました"
      else
        redirect_to tags_path, alert: "タグの追加に失敗しました: #{@tag.errors.full_messages.join(', ')}"
      end
    end
  end
end 