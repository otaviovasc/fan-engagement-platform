require "test_helper"

class UserWaitlistsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get user_waitlists_new_url
    assert_response :success
  end

  test "should get create" do
    get user_waitlists_create_url
    assert_response :success
  end
end
