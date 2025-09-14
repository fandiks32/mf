module ApiAuthentication
  extend ActiveSupport::Concern

  private

  def authenticate_user
    authenticate_with_http_basic do |user_id, password|
      @extracted_user_id = user_id
      @current_user = User.find_by(user_id: user_id)

      if @current_user.nil?
        # User doesn't exist - should return 404 instead of 401
        Rails.logger.warn({
          event: "user_not_found",
          controller: controller_name,
          action: action_name,
          user_id: user_id,
          ip: request.remote_ip,
          user_agent: request.user_agent,
          timestamp: Time.current
        }.to_json)
        
        raise ApiExceptions::UserNotFoundError.new
      elsif @current_user.authenticate(password)
        Rails.logger.info({
          event: "authentication_success",
          controller: controller_name,
          action: action_name,
          user_id: user_id,
          ip: request.remote_ip,
          timestamp: Time.current
        }.to_json)
        
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
    Rails.logger.warn({
      event: "authentication_failed",
      controller: controller_name,
      action: action_name,
      user_id: extracted_user_id,
      ip: request.remote_ip,
      user_agent: request.user_agent,
      timestamp: Time.current
    }.to_json)
    
    raise ApiExceptions::AuthenticationError.new
  end

  def check_user_permission(target_user_id)
    unless current_user.user_id == target_user_id
      Rails.logger.warn({
        event: "permission_denied",
        controller: controller_name,
        action: action_name,
        authenticated_user: current_user.user_id,
        target_user: target_user_id,
        ip: request.remote_ip,
        timestamp: Time.current
      }.to_json)
      
      raise ApiExceptions::PermissionDeniedError.new
    end
  end

  private

  def extracted_user_id
    @extracted_user_id
  end
end