require "test_helper"

class LinksHelperTest < ActionView::TestCase
  test "recognizes known sites" do
    {
      "https://github.com/xyz-leo" => "github",
      "https://www.instagram.com/someone" => "instagram",
      "https://x.com/someone" => "x",
      "https://twitter.com/someone" => "x",
      "https://www.linkedin.com/in/someone" => "linkedin",
      "https://br.linkedin.com/in/someone" => "linkedin",
      "https://facebook.com/someone" => "facebook",
      "https://m.facebook.com/someone" => "facebook",
      "https://fb.com/someone" => "facebook",
      "https://www.youtube.com/@someone" => "youtube",
      "https://youtu.be/abc123" => "youtube",
      "HTTPS://GitHub.com/Someone" => "github"
    }.each do |url, icon|
      assert_equal icon, link_icon_name(url), url
    end
  end

  test "email links get the mail icon" do
    assert_equal "mail", link_icon_name("mailto:someone@example.com")
  end

  test "other sites get no icon" do
    assert_nil link_icon_name("https://example.com")
    assert_nil link_icon_name("https://gist.example.com/github.com")
  end

  test "lookalike domains get no icon" do
    assert_nil link_icon_name("https://notgithub.com/someone")
    assert_nil link_icon_name("https://github.com.evil.example/someone")
  end

  test "invalid or relative URLs get no icon" do
    assert_nil link_icon_name("not a url")
    assert_nil link_icon_name("/relative/path")
  end

  test "every mapped icon has a partial" do
    (LinksHelper::ICON_DOMAINS.values.uniq + [ "mail" ]).each do |icon|
      assert lookup_context.exists?(icon, [ "icons" ], true), "missing app/views/icons/_#{icon}.html.erb"
    end
  end
end
