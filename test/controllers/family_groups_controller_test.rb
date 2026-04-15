require "test_helper"

class FamilyGroupsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get family_groups_new_url
    assert_response :success
  end

  test "should get create" do
    get family_groups_create_url
    assert_response :success
  end

  test "should get show" do
    get family_groups_show_url
    assert_response :success
  end

  test "should get destroy" do
    get family_groups_destroy_url
    assert_response :success
  end
end
