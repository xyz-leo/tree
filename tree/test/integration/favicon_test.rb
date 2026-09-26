require "test_helper"

class FaviconTest < ActionDispatch::IntegrationTest
  test "every layout links the icons" do
    sign_in_as users(:admin)

    [ root_path, en_path, new_session_path, admin_root_path, edit_admin_profile_path ].each do |path|
      get path
      assert_select "link[rel=icon][href='/icon.png']", 1, path
      assert_select "link[rel=apple-touch-icon][href='/apple-touch-icon.png']", 1, path
      assert_select "link[href='/icon.svg']", 0, path
    end
  end

  test "static error pages link the icons" do
    Dir[Rails.public_path.join("*.html")].each do |file|
      html = File.read(file)

      assert_includes html, '<link rel="icon" href="/icon.png" type="image/png">', file
      assert_includes html, '<link rel="apple-touch-icon" href="/apple-touch-icon.png">', file
    end
  end

  test "icon files exist" do
    %w[icon.png apple-touch-icon.png].each do |name|
      assert Rails.public_path.join(name).file?, "public/#{name} is missing"
    end
  end
end
