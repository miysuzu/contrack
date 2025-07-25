require "test_helper"

class Admin::ContractsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get admin_contracts_index_url
    assert_response :success
  end

  test "should get show" do
    get admin_contracts_show_url
    assert_response :success
  end

  test "should get destroy" do
    get admin_contracts_destroy_url
    assert_response :success
  end
end
