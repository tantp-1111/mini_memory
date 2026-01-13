require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  test "should get top" do
    get authenticated_root_path
    assert_response :success
  end
end
