require "test_helper"

class Admin::ProfilesControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:admin) }

  test "edit" do
    get edit_admin_profile_path

    assert_response :success
    assert_select "input[name='profile[name]'][value=?]", "Test Person"
  end

  test "update changes the public page" do
    patch admin_profile_path, params: { profile: { name: "New Name", handle: "new", bio_pt: "Nova bio", bio_en: "" } }

    assert_redirected_to admin_root_path
    get en_path
    assert_select "h1", "New Name"
    assert_select ".bio", "Nova bio"
  end

  test "creates the profile on first save" do
    Profile.delete_all

    assert_difference -> { Profile.count }, 1 do
      patch admin_profile_path, params: { profile: { name: "Leo", handle: "leo" } }
    end
    assert_redirected_to admin_root_path
  end

  test "invalid update shows errors" do
    patch admin_profile_path, params: { profile: { name: "" } }

    assert_response :unprocessable_content
    assert_select ".flash-alert", /Name can't be blank/
    assert_equal "Test Person", profiles(:main).reload.name
  end
end
