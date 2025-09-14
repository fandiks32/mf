class User < ApplicationRecord
  has_secure_password

  validates :user_id, presence: true,
                     length: { in: 6..20 },
                     format: { with: /\A[a-zA-Z0-9]+\z/, message: "must be alphanumeric" },
                     uniqueness: true

  validates :password, presence: true,
                      length: { in: 8..20 },
                      format: { with: /\A[[:print:]&&[^ \t\n\r\f\v]]+\z/, message: "must contain only printable ASCII characters without spaces or control codes" },
                      on: :create

  validates :password, length: { in: 8..20 },
                      format: { with: /\A[[:print:]&&[^ \t\n\r\f\v]]+\z/, message: "must contain only printable ASCII characters without spaces or control codes" },
                      allow_blank: true,
                      on: :update

  validates :nickname, length: { maximum: 30 }, allow_blank: true

  validates :comment, length: { maximum: 100 }, allow_blank: true

  before_save :set_default_nickname

  private

  def set_default_nickname
    self.nickname = user_id if nickname.blank?
  end
end