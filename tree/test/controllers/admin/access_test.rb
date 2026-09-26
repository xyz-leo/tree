require "test_helper"

class Admin::AccessTest < ActionDispatch::IntegrationTest
  test "every admin route requires sign in" do
    group = link_groups(:social)
    link = links(:github)

    requests = [
      [ :get, admin_root_path ],
      [ :get, edit_admin_profile_path ],
      [ :patch, admin_profile_path ],
      [ :get, new_admin_link_group_path ],
      [ :post, admin_link_groups_path ],
      [ :get, edit_admin_link_group_path(group) ],
      [ :patch, admin_link_group_path(group) ],
      [ :delete, admin_link_group_path(group) ],
      [ :get, new_admin_link_group_link_path(group) ],
      [ :post, admin_link_group_links_path(group) ],
      [ :get, edit_admin_link_path(link) ],
      [ :patch, admin_link_path(link) ],
      [ :delete, admin_link_path(link) ]
    ]

    assert_no_changes -> { [ Profile.pluck(:updated_at), LinkGroup.count, Link.count ] } do
      requests.each do |verb, path|
        send(verb, path)
        assert_redirected_to new_session_path, "#{verb.upcase} #{path}"
      end
    end
  end
end
