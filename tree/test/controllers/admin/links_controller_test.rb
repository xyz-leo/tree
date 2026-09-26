require "test_helper"

class Admin::LinksControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:admin) }

  test "new" do
    get new_admin_link_group_link_path(link_groups(:projects))

    assert_response :success
    assert_select "h1", /Projetos/
  end

  test "create adds the link to the group and the page" do
    group = link_groups(:projects)

    assert_difference -> { group.links.count }, 1 do
      post admin_link_group_links_path(group), params: { link: { title: "YouTube", url: "https://youtube.com/@me", hint_pt: "vídeos" } }
    end

    assert_redirected_to admin_root_path
    get root_path
    assert_select "li.has-icon", /YouTube/
  end

  test "rejects unsafe URLs" do
    assert_no_difference -> { Link.count } do
      post admin_link_group_links_path(link_groups(:social)), params: { link: { title: "Bad", url: "javascript:alert(1)" } }
    end

    assert_response :unprocessable_content
    assert_select ".flash-alert", /Url must start with/
  end

  test "edit" do
    get edit_admin_link_path(links(:github))

    assert_response :success
    assert_select "input[name='link[url]'][value=?]", "https://github.com/test-handle"
    assert_select "select[name='link[link_group_id]'] option", 3
  end

  test "update can move a link to another group" do
    patch admin_link_path(links(:github)), params: { link: { title: "GitHub", link_group_id: link_groups(:projects).id } }

    assert_redirected_to admin_root_path
    assert_equal link_groups(:projects), links(:github).reload.link_group
  end

  test "invalid update shows errors" do
    patch admin_link_path(links(:github)), params: { link: { title: "" } }

    assert_response :unprocessable_content
    assert_equal "GitHub", links(:github).reload.title
  end

  test "destroy" do
    assert_difference -> { Link.count }, -1 do
      delete admin_link_path(links(:github))
    end

    assert_redirected_to admin_root_path
  end

  test "unknown group or link is not found" do
    get new_admin_link_group_link_path(link_group_id: 0)
    assert_response :not_found

    get edit_admin_link_path(id: 0)
    assert_response :not_found
  end
end
