class Api::UsersController < ApplicationController
  include ApiAuthentication

  before_action :authenticate_user, except: [:create]
  before_action :set_user, only: [:show, :update]
  before_action :check_user_permission, only: [:update]

  # POST /signup
  def create
    begin
      user_data = user_params
      @user = User.new(user_data)

      if @user.save
        render json: {
          message: "Account successfully created",
          user: UserPresenter.new(@user).as_json
        }, status: :ok
      else
        render_validation_error(@user.errors)
      end
    rescue ActionController::ParameterMissing => e
      render json: {
        message: "Account creation failed",
        cause: "Required user_id and password"
      }, status: :bad_request
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
    permitted_params = update_params
    return if performed? # Early return if validation error was rendered

    if @user.update(permitted_params)
      render json: {
        message: "User successfully updated",
        user: UserPresenter.new(@user).as_json
      }, status: :ok
    else
      render_update_validation_error(@user.errors)
    end
  end

  # POST /close
  def destroy
    current_user.destroy
    render json: {
      message: "Account and user successfully removed"
    }, status: :ok
  end

  private

  def set_user
    @user = User.find_by(user_id: params[:user_id])
    unless @user
      render json: { message: "No user found" }, status: :not_found
    end
  end

  def check_user_permission
    return unless @user
    unless current_user.user_id == @user.user_id
      render json: { message: "No permission for update" }, status: :forbidden
    end
  end

  def user_params
    params.require(:user_id)
    params.require(:password)
    {
      user_id: params[:user_id],
      password: params[:password]
    }
  end

  def update_params
    permitted = params.permit(:nickname, :comment)

    # Check if at least one field is provided
    if permitted.empty? || (permitted[:nickname].nil? && permitted[:comment].nil?)
      render json: {
        message: "User updation failed",
        cause: "Required nickname or comment"
      }, status: :bad_request
      return {}
    end

    # Check for invalid fields (user_id or password)
    if params[:user_id] && params[:user_id] != current_user.user_id
      render json: {
        message: "User updation failed",
        cause: "Not updatable user_id and password"
      }, status: :bad_request
      return {}
    end

    if params[:password]
      render json: {
        message: "User updation failed",
        cause: "Not updatable user_id and password"
      }, status: :bad_request
      return {}
    end

    permitted
  end

  def render_validation_error(errors)
    cause = determine_create_error_cause(errors)
    render json: {
      message: "Account creation failed",
      cause: cause
    }, status: :bad_request
  end

  def render_update_validation_error(errors)
    render json: {
      message: "User updation failed",
      cause: "String length limit exceeded or containing invalid characters"
    }, status: :bad_request
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
end