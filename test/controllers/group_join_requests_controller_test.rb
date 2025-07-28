require "test_helper"

class GroupJoinRequestsControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get group_join_requests_create_url
    assert_response :success
  end
end
