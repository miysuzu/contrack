class CommentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_contract
  before_action :set_comment, only: [:edit, :update, :destroy]
  before_action :ensure_comment_owner!, only: [:edit, :update, :destroy]

  def create
    @comment = @contract.comments.build(comment_params)
    @comment.commentable = current_user
    
    if @comment.save
      redirect_to @contract, notice: "メモを追加しました。"
    else
      error_message = @comment.errors.full_messages.join(', ')
      redirect_to @contract, alert: "メモの追加に失敗しました: #{error_message}"
    end
  end

  def reply
    @parent_comment = @contract.comments.find(params[:id])
    
    unless @parent_comment.can_reply?
      redirect_to @contract, alert: "返信の深さが上限に達しています。"
      return
    end
    
    @comment = @contract.comments.build(comment_params)
    @comment.commentable = current_user
    @comment.parent = @parent_comment
    
    if @comment.save
      redirect_to @contract, notice: "返信を追加しました。"
    else
      error_message = @comment.errors.full_messages.join(', ')
      redirect_to @contract, alert: "返信の追加に失敗しました: #{error_message}"
    end
  end

  def edit
  end

  def update
    if @comment.update(comment_params)
      redirect_to @contract, notice: "メモを更新しました。"
    else
      render :edit
    end
  end

  def destroy
    @comment.destroy
    redirect_to @contract, notice: "メモを削除しました。"
  end

  private

  def set_contract
    @contract = Contract.find(params[:contract_id])
  end

  def set_comment
    @comment = @contract.comments.find(params[:id])
  end

  def ensure_comment_owner!
    unless @comment.commentable == current_user || @contract.user == current_user
      redirect_to @contract, alert: "この操作を実行する権限がありません。"
    end
  end

  def comment_params
    params.require(:comment).permit(:content, :parent_id)
  end
end
