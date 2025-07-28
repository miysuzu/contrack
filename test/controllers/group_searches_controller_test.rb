require "test_helper"

class GroupSearchesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get group_searches_index_url
    assert_response :success
  end
end
