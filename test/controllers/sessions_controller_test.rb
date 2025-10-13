require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  fixtures :users

  test "should get dashboard when logged in" do
    login_as users(:one)              # ← 先登录
    get dashboard_url
    assert_response :success
  end
end
