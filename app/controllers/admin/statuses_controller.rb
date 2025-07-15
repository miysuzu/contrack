class Admin::StatusesController < ApplicationController
  layout 'admin'
  before_action :authenticate_admin!

  def index
    @statuses = Status.all.order(:id)
    @status = Status.new
  end

  def create
    @status = Status.new(status_params)
    if @status.save
      redirect_to admin_statuses_path, notice: "ステータスを追加しました。"
    else
      @statuses = Status.all
      render :index
    end
  end

  def edit
    @status = Status.find(params[:id])
  end

  def update
    @status = Status.find(params[:id])
    if @status.update(status_params)
      redirect_to admin_statuses_path, notice: "ステータスを更新しました。"
    else
      render :edit
    end
  end

  def destroy
    status = Status.find(params[:id])
    status.destroy
    redirect_to admin_statuses_path, alert: "ステータスを削除しました。"
  end

  private

  def status_params
    params.require(:status).permit(:name)
  end
end
