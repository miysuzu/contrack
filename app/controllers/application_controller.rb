class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
  end

  def after_sign_out_path_for(resource_or_scope)
    if resource_or_scope == :admin
      new_admin_session_path
    else
      root_path
    end
  end

  private

  def set_admin_layout
    if controller_path.start_with?('admin') || (devise_controller? && resource_name == :admin)
      'admin'
    else
      'application'
    end
  end
end
