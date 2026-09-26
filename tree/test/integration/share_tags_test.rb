require "test_helper"

class ShareTagsTest < ActionDispatch::IntegrationTest
  test "portuguese page describes itself for link previews" do
    get root_path

    assert_meta "og:type", "website"
    assert_meta "og:site_name", "test-handle"
    assert_meta "og:title", "Test Person"
    assert_meta "og:description", "Bio em português."
    assert_meta "og:url", "http://www.example.com/"
    assert_meta "og:locale", "pt_BR"
    assert_meta "og:locale:alternate", "en_US"
    assert_meta "og:image", "http://www.example.com/icon.png"
    assert_meta "og:image:alt", "Test Person"
    assert_select "meta[name='twitter:card'][content=summary]", 1
    assert_select "link[rel=canonical][href='http://www.example.com/']", 1
  end

  test "english page uses english text and its own URL" do
    get en_path

    assert_meta "og:description", "Bio in English."
    assert_meta "og:url", "http://www.example.com/en"
    assert_meta "og:locale", "en_US"
    assert_meta "og:locale:alternate", "pt_BR"
    assert_select "link[rel=canonical][href='http://www.example.com/en']", 1
  end

  test "english description falls back to portuguese" do
    profiles(:main).update!(bio_en: "")

    get en_path

    assert_meta "og:description", "Bio em português."
    assert_select "meta[name=description][content=?]", "Bio em português."
  end

  test "no description tags without a bio" do
    profiles(:main).update!(bio_pt: "", bio_en: "")

    get root_path

    assert_select "meta[property='og:description']", 0
    assert_select "meta[name=description]", 0
  end

  test "image URL follows the request protocol and host" do
    https!
    host! "links.example.org"

    get root_path

    assert_meta "og:image", "https://links.example.org/icon.png"
    assert_meta "og:url", "https://links.example.org/"
  end

  test "profile text is escaped in the tags" do
    profiles(:main).update!(name: %q(Evil "><script>alert(1)</script>), bio_pt: %q(a "quoted" <b>bio</b>))

    get root_path

    assert_meta "og:title", %q(Evil "><script>alert(1)</script>)
    assert_meta "og:description", %q(a "quoted" <b>bio</b>)
    assert_select "script", text: "alert(1)", count: 0
    assert_select "b", 0
  end

  test "works before a profile is saved" do
    Profile.delete_all

    get root_path

    assert_meta "og:title", "Tree"
    assert_meta "og:site_name", "tree"
  end

  test "admin pages have no share tags" do
    sign_in_as users(:admin)

    [ new_session_path, admin_root_path ].each do |path|
      get path
      assert_select "meta[property^='og:']", 0, path
      assert_select "link[rel=canonical]", 0, path
    end
  end

  private
    def assert_meta(property, content)
      assert_select "meta[property='#{property}']", { count: 1 }, "expected one #{property}" do |tags|
        assert_equal content, tags.first["content"], property
      end
    end
end
