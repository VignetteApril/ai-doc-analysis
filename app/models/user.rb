class User < ApplicationRecord
  has_secure_password

  NORMALIZED_EMAIL = /\A[^@\s]+@[^@\s]+\z/

  validates :email, presence: true, format: { with: NORMALIZED_EMAIL }
  validates :email, uniqueness: { case_sensitive: false }
  before_validation { self.email = email.to_s.downcase.strip }
end
