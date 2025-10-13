ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end

  def login_as(user, password: "secret")
    post login_path, params: { email: user.email, password: password }
    follow_redirect! if response.redirect?  # 可选，跟到登录后页
  end
end
