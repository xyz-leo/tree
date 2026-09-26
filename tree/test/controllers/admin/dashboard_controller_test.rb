require "test_helper"

class Admin::DashboardControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:admin) }

  test "lists the profile, groups and links" do
    get admin_root_path

    assert_response :success
    assert_select "meta[name=robots][content=?]", "noindex, nofollow"
    assert_select ".details dd", "Test Person"
    assert_select ".panel-header h2", /Projetos \/ Projects/
    assert_select ".admin-list li", 3
    assert_select ".admin-list .hint", "https://github.com/test-handle"
    assert_select ".empty", /No links yet/
  end

  test "delete buttons ask for confirmation" do
    get admin_root_path

    assert_select "form[data-confirm*='Delete the link \"GitHub\"']"
    assert_select "form[data-confirm*='Delete the group \"Social\" and its 2 links']"
  end

  test "works with no profile saved yet" do
    Profile.delete_all

    get admin_root_path

    assert_response :success
  end
end
