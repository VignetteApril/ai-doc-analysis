ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "bcrypt"

class ActiveSupport::TestCase
  parallelize(workers: :number_of_processors)
end

# ✅ 关键：放在 ActionDispatch::IntegrationTest 里
class ActionDispatch::IntegrationTest
  def login_as(user, password: "secret")
    post login_path, params: { email: user.email, password: password }
    follow_redirect! if response.redirect?
  end
end
