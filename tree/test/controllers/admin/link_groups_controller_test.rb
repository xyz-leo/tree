require "test_helper"

class Admin::LinkGroupsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:admin) }

  test "new" do
    get new_admin_link_group_path

    assert_response :success
  end

  test "create adds a group at the end" do
    assert_difference -> { LinkGroup.count }, 1 do
      post admin_link_groups_path, params: { link_group: { label_pt: "Escrita", label_en: "Writing" } }
    end

    assert_redirected_to admin_root_path
    assert_equal [ "Escrita", "Writing", 4 ], LinkGroup.last.values_at(:label_pt, :label_en, :position)
  end

  test "invalid create shows errors" do
    assert_no_difference -> { LinkGroup.count } do
      post admin_link_groups_path, params: { link_group: { label_pt: "" } }
    end

    assert_response :unprocessable_content
    assert_select ".flash-alert", /Label pt can't be blank/
  end

  test "edit" do
    get edit_admin_link_group_path(link_groups(:projects))

    assert_response :success
    assert_select "input[name='link_group[label_en]'][value=?]", "Projects"
  end

  test "update" do
    patch admin_link_group_path(link_groups(:projects)), params: { link_group: { label_pt: "Trabalhos", position: 0 } }

    assert_redirected_to admin_root_path
    assert_equal [ "Trabalhos", 0 ], link_groups(:projects).reload.values_at(:label_pt, :position)
  end

  test "invalid update shows errors" do
    patch admin_link_group_path(link_groups(:projects)), params: { link_group: { position: "abc" } }

    assert_response :unprocessable_content
    assert_equal 2, link_groups(:projects).reload.position
  end

  test "destroy removes the group and its links" do
    assert_difference "LinkGroup.count" => -1, "Link.count" => -2 do
      delete admin_link_group_path(link_groups(:social))
    end

    assert_redirected_to admin_root_path
  end
end
