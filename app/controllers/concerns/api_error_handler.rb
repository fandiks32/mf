module ApiErrorHandler
  extend ActiveSupport::Concern

  included do
    # Order matters - more specific exceptions should come first
    # Rails processes rescue_from in reverse order (most recent first)
    rescue_from StandardError, with: :handle_unexpected_error
    rescue_from JSON::ParserError, with: :handle_json_parse_error
    rescue_from ActionController::ParameterMissing, with: :handle_missing_parameters
    rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
    rescue_from ApiExceptions::BaseError, with: :handle_api_error
  end

  private

  def handle_api_error(exception)
    log_error(exception)
    
    case exception
    when ApiExceptions::ValidationError
      render json: {
        message: exception.message_key,
        cause: exception.cause
      }, status: exception.status
    else
      render json: {
        message: exception.message_key
      }, status: exception.status
    end
  end

  def handle_not_found(exception)
    log_error(exception)
    render json: {
      message: "No user found"
    }, status: :not_found
  end

  def handle_missing_parameters(exception)
    log_error(exception)
    
    # Determine context based on action
    case action_name
    when 'create'
      render json: {
        message: "Account creation failed",
        cause: "Required user_id and password"
      }, status: :bad_request
    when 'update'
      render json: {
        message: "User updation failed",
        cause: "Required nickname or comment"
      }, status: :bad_request
    else
      render json: {
        message: "Missing required parameters"
      }, status: :bad_request
    end
  end

  def handle_json_parse_error(exception)
    log_error(exception)
    render json: {
      message: "Account creation failed",
      cause: "Invalid JSON format"
    }, status: :bad_request
  end

  def handle_unexpected_error(exception)
    log_error(exception, level: :error)
    
    # Don't expose internal errors in production
    if Rails.env.production?
      render json: {
        message: "Internal server error"
      }, status: :internal_server_error
    else
      render json: {
        message: "Internal server error",
        error: exception.message,
        backtrace: exception.backtrace&.first(5)
      }, status: :internal_server_error
    end
  end

  def log_error(exception, level: :warn)
    Rails.logger.send(level, {
      error_class: exception.class.name,
      error_message: exception.message,
      action: "#{controller_name}##{action_name}",
      params: request.params.except('action', 'controller'),
      user_agent: request.user_agent,
      remote_ip: request.remote_ip,
      backtrace: exception.backtrace&.first(3)
    }.to_json)
  end
end