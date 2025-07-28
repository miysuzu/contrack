class HomesController < ApplicationController
  def top
    if user_signed_in?
      redirect_to contracts_path
    end
  end

  def about
  end
end
