module ApiExceptions
  class BaseError < StandardError
    attr_reader :status, :message_key, :cause_key

    def initialize(message = nil, cause = nil)
      @message_key = message
      @cause_key = cause
      super(message)
    end
  end

  class AuthenticationError < BaseError
    def initialize
      super("Authentication failed")
      @status = :unauthorized
    end
  end

  class UserNotFoundError < BaseError
    def initialize
      super("No user found")
      @status = :not_found
    end
  end

  class PermissionDeniedError < BaseError
    def initialize
      super("No permission for update")
      @status = :forbidden
    end
  end

  class ValidationError < BaseError
    attr_reader :cause

    def initialize(message, cause)
      super(message)
      @cause = cause
      @status = :bad_request
    end
  end

  class AccountCreationError < ValidationError
    def initialize(cause)
      super("Account creation failed", cause)
    end
  end

  class UserUpdateError < ValidationError
    def initialize(cause)
      super("User updation failed", cause)
    end
  end

  class InvalidParametersError < ValidationError
    def initialize(message = "Invalid parameters provided")
      super(message, "Invalid input format")
    end
  end

  class MissingParametersError < ValidationError
    def initialize(required_params)
      case required_params
      when :signup
        super("Account creation failed", "Required user_id and password")
      when :update
        super("User updation failed", "Required nickname or comment")
      else
        super("Missing required parameters", "Required parameters not provided")
      end
    end
  end
end