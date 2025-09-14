class Api::UsersController < ApplicationController
  skip_before_action :verify_authenticity_token
  
  include ApiAuthentication
  include ApiErrorHandler
  include InputValidator

  before_action :authenticate_user, except: [:create]
  before_action :set_user, only: [:show, :update]
  before_action :check_user_permission, only: [:update]

  # POST /signup
  def create
    user_data = validate_signup_params
    @user = User.new(user_data)

    if @user.save
      Rails.logger.info({
        event: "user_created",
        user_id: @user.user_id,
        ip: request.remote_ip,
        user_agent: request.user_agent,
        timestamp: Time.current
      }.to_json)
      
      render json: {
        message: "Account successfully created",
        user: UserPresenter.new(@user).as_json
      }, status: :ok
      return
    else
      Rails.logger.warn({
        event: "user_creation_failed",
        user_id: user_data[:user_id],
        errors: @user.errors.messages,
        ip: request.remote_ip,
        timestamp: Time.current
      }.to_json)
      
      raise ApiExceptions::AccountCreationError.new(determine_create_error_cause(@user.errors))
    end
  end

  # GET /users/:user_id
  def show
    render json: {
      message: "User details by user_id",
      user: UserPresenter.new(@user).as_json
    }, status: :ok
  end

  # PATCH /users/:user_id
  def update
    permitted_params = validate_update_params

    if @user.update(permitted_params)
      Rails.logger.info({
        event: "user_updated",
        user_id: @user.user_id,
        updated_fields: permitted_params.keys,
        ip: request.remote_ip,
        timestamp: Time.current
      }.to_json)
      
      render json: {
        message: "User successfully updated",
        user: UserPresenter.new(@user).as_json
      }, status: :ok
    else
      Rails.logger.warn({
        event: "user_update_failed",
        user_id: @user.user_id,
        errors: @user.errors.messages,
        ip: request.remote_ip,
        timestamp: Time.current
      }.to_json)
      
      raise ApiExceptions::UserUpdateError.new("String length limit exceeded or containing invalid characters")
    end
  end

  # POST /close
  def destroy
    user_id = current_user.user_id
    current_user.destroy
    
    Rails.logger.info({
      event: "user_deleted",
      user_id: user_id,
      ip: request.remote_ip,
      timestamp: Time.current
    }.to_json)
    
    render json: {
      message: "Account and user successfully removed"
    }, status: :ok
  end

  private

  def set_user
    @user = User.find_by(user_id: params[:user_id])
    raise ApiExceptions::UserNotFoundError.new unless @user
  end

  def check_user_permission
    return unless @user
    raise ApiExceptions::PermissionDeniedError.new unless current_user.user_id == @user.user_id
  end

  def validate_signup_params
    # Validate content type
    unless request.content_type&.include?('application/json')
      raise ApiExceptions::InvalidParametersError.new("Content-Type must be application/json")
    end

    # Extract and validate parameters
    user_id = params[:user_id]
    password = params[:password]

    # Check required parameters
    raise ApiExceptions::MissingParametersError.new(:signup) if user_id.blank? || password.blank?

    # Sanitize input
    user_id = sanitize_string(user_id)
    password = sanitize_password(password)

    # Additional validation
    validate_user_id_format(user_id)
    validate_password_format(password)

    {
      user_id: user_id,
      password: password
    }
  end

  def validate_update_params
    # Get permitted parameters - try both top level and nested user params
    nickname = params[:nickname] || (params[:user] && params[:user][:nickname])
    comment = params[:comment] || (params[:user] && params[:user][:comment])

    # Check if at least one field is provided
    if nickname.nil? && comment.nil?
      raise ApiExceptions::MissingParametersError.new(:update)
    end

    # Sanitize and validate inputs
    result = {}
    
    unless nickname.nil?
      nickname = sanitize_string(nickname) if nickname.present?
      validate_nickname_format(nickname) if nickname.present?
      result[:nickname] = nickname
    end

    unless comment.nil?
      comment = sanitize_string(comment) if comment.present?
      validate_comment_format(comment) if comment.present?
      result[:comment] = comment
    end

    result
  end

  def determine_create_error_cause(errors)
    if errors[:user_id]&.any? { |msg| msg.include?("has already been taken") }
      "Already same user_id is used"
    elsif errors[:user_id]&.any? || errors[:password]&.any?
      if errors.messages.any? { |_, msgs| msgs.any? { |msg| msg.include?("too short") || msg.include?("too long") || msg.include?("wrong length") } }
        "Input length is incorrect"
      else
        "Incorrect character pattern"
      end
    else
      "Input length is incorrect"
    end
  end

  def validate_password_format(password)
    if password.length < 8 || password.length > 20
      raise ApiExceptions::AccountCreationError.new("Input length is incorrect")
    end
    
    # Check for printable ASCII without spaces/control codes
    unless password.match?(/\A[[:print:]&&[^ \t\n\r\f\v]]+\z/)
      raise ApiExceptions::AccountCreationError.new("Incorrect character pattern")
    end
  end

  def validate_nickname_format(nickname)
    if nickname.present? && nickname.length > 30
      raise ApiExceptions::UserUpdateError.new("String length limit exceeded or containing invalid characters")
    end
  end

  def validate_comment_format(comment)
    if comment.present? && comment.length > 100
      raise ApiExceptions::UserUpdateError.new("String length limit exceeded or containing invalid characters")
    end
  end
end