require "test_helper"

class EmployeesControllerTest < ActionDispatch::IntegrationTest
  test "should get invite" do
    get employees_invite_url
    assert_response :success
  end

  test "should get create_invite" do
    get employees_create_invite_url
    assert_response :success
  end
end
