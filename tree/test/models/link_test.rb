require "test_helper"

class LinkTest < ActiveSupport::TestCase
  test "accepts https, http and mailto URLs" do
    [ "https://example.com", "http://example.com/a?b=c", "mailto:me@example.com" ].each do |url|
      assert build(url: url).valid?, url
    end
  end

  test "rejects other URLs" do
    [ "javascript:alert(1)", "example.com", "/relative", "ftp://example.com", "mailto:nobody", "https://has space.com" ].each do |url|
      link = build(url: url)

      assert_not link.valid?, url
      assert link.errors.of_kind?(:url, :invalid), url
    end
  end

  test "strips whitespace around the URL" do
    assert_equal "https://example.com", build(url: "  https://example.com \n").url
  end

  test "requires a title" do
    assert_not build(title: "").valid?
  end

  test "new links go to the end of their own group" do
    assert_equal 3, links(:github).link_group.links.create!(title: "New", url: "https://example.com").position
    assert_equal 2, links(:tree).link_group.links.create!(title: "New", url: "https://example.com").position
  end

  test "group lists its links in order" do
    assert_equal %w[GitHub Email], link_groups(:social).links.map(&:title)
  end

  private
    def build(**attributes)
      link_groups(:social).links.new(title: "Site", url: "https://example.com", **attributes)
    end
end
