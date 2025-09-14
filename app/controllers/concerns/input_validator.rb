module InputValidator
  extend ActiveSupport::Concern

  private

  # Input sanitization methods
  def sanitize_string(value)
    return value unless value.is_a?(String)
    
    # Remove null bytes and basic control characters, but preserve printable chars
    value.delete("\x00").strip
  end

  def sanitize_password(value)
    return value unless value.is_a?(String)
    
    # For passwords, only remove null bytes but preserve other characters
    value.delete("\x00")
  end

  # Input validation methods
  def validate_user_id_format(user_id)
    if user_id.length < 6 || user_id.length > 20
      raise ApiExceptions::AccountCreationError.new("Input length is incorrect")
    end
    
    unless user_id.match?(/\A[a-zA-Z0-9]+\z/)
      raise ApiExceptions::AccountCreationError.new("Incorrect character pattern")
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