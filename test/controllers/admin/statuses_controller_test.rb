require "test_helper"

class Admin::StatusesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get admin_statuses_index_url
    assert_response :success
  end

  test "should get new" do
    get admin_statuses_new_url
    assert_response :success
  end

  test "should get create" do
    get admin_statuses_create_url
    assert_response :success
  end

  test "should get destroy" do
    get admin_statuses_destroy_url
    assert_response :success
  end
end
