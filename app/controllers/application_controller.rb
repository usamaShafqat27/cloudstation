class ApplicationController < ActionController::Base
  skip_before_action :verify_authenticity_token, if: :json_request?

  def json_request?
    request.format.json?
  end

  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end

  def authenticate_user!
    unless current_user
      respond_to do |format|
        format.html { redirect_to new_session_path, error: 'Log in to proceed' }
        format.json { render json: {error: 'Log in to proceed'}, status: :unauthorized }
      end
    end
  end
end
