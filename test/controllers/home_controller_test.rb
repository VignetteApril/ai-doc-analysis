require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  fixtures :users

  test "redirects to login when not logged in" do
    get dashboard_url
    assert_response :redirect
    assert_redirected_to login_url
  end

  test "should get dashboard when logged in" do
    login_as users(:one)   # 使用 test/fixtures/users.yml 里的 one
    get dashboard_url
    assert_response :success
  end
end
