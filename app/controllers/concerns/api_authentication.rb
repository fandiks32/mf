module ApiAuthentication
  extend ActiveSupport::Concern

  private

  def authenticate_user
    authenticate_with_http_basic do |user_id, password|
      @current_user = User.find_by(user_id: user_id)

      if @current_user&.authenticate(password)
        @current_user
      else
        render_authentication_error
        false
      end
    end || render_authentication_error
  end

  def current_user
    @current_user
  end

  def render_authentication_error
    render json: { message: "Authentication failed" }, status: :unauthorized
  end

  def check_user_permission(target_user_id)
    unless current_user.user_id == target_user_id
      render json: { message: "No permission for update" }, status: :forbidden
    end
  end
end