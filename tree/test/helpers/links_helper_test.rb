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

  test "short address of a link" do
    assert_equal "github.com", link_display("https://www.github.com/someone")
    assert_equal "br.linkedin.com", link_display("https://br.linkedin.com/in/someone")
    assert_equal "me@example.com", link_display("mailto:me@example.com?subject=Hi")
    assert_equal "not a url", link_display("not a url")
  end

  test "emphasis between asterisks, with everything escaped" do
    assert_equal "I build <em>small tools</em>.", emphasized("I build *small tools*.")
    assert_equal "&lt;b&gt;x&lt;/b&gt; <em>&lt;i&gt;</em>", emphasized("<b>x</b> *<i>*")
    assert_equal "a * b", emphasized("a * b")
    assert_equal "I build small tools.", without_emphasis("I build *small tools*.")
  end

  test "every mapped icon has a partial" do
    (LinksHelper::ICON_DOMAINS.values.uniq + [ "mail", LinksHelper::DEFAULT_ICON ]).each do |icon|
      assert lookup_context.exists?(icon, [ "icons" ], true), "missing app/views/icons/_#{icon}.html.erb"
    end
  end
end
