class UserPresenter
  attr_reader :user

  def initialize(user)
    @user = user
  end

  def as_json(options = {})
    result = {
      user_id: user.user_id
    }

    # Only include nickname if it's not blank and different from user_id
    if user.nickname.present? && user.nickname != user.user_id
      result[:nickname] = user.nickname
    end

    # Only include comment if it's present
    result[:comment] = user.comment if user.comment.present?

    result
  end

  def to_json(options = {})
    as_json(options).to_json
  end
end