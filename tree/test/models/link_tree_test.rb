require "test_helper"

class LinkTreeTest < ActiveSupport::TestCase
  test "resolves translated text for each language" do
    pt = LinkTree.load("pt")
    en = LinkTree.load("en")

    assert_equal "Bio em português.", pt.bio
    assert_equal "Bio in English.", en.bio
    assert_equal [ "Social", "Projetos" ], pt.groups.map(&:label)
    assert_equal [ "Social", "Projects" ], en.groups.map(&:label)
    assert_equal "esta página", pt.groups.last.links.first.hint
    assert_equal "this page", en.groups.last.links.first.hint
  end

  test "plain strings are the same in every language" do
    LinkTree::LANGS.each do |lang|
      tree = LinkTree.load(lang)

      assert_equal "Test Person", tree.name
      assert_equal "test-handle", tree.handle
      assert_equal "@test-handle", tree.groups.first.links.first.hint
    end
  end

  test "optional fields can be missing" do
    tree = LinkTree.new({ "name" => "A", "handle" => "a", "groups" => [] }, "pt")

    assert_nil tree.bio
    assert_empty tree.groups
    assert_nil LinkTree.load("en").groups.first.links.last.hint
  end

  test "rejects unknown languages" do
    assert_raises(ArgumentError) { LinkTree.load("es") }
  end

  test "raises when a translation is missing" do
    data = { "name" => "A", "handle" => "a", "bio" => { "pt" => "só pt" }, "groups" => [] }

    assert_raises(KeyError) { LinkTree.new(data, "en") }
  end

  # Guards the real content file: a typo or missing translation there would
  # otherwise only show up as a 500 in production.
  test "config/links.yml is complete for every language" do
    LinkTree::LANGS.each do |lang|
      tree = LinkTree.load(lang, path: Rails.root.join("config/links.yml"))

      assert tree.name.present?
      assert tree.handle.present?
      assert tree.groups.any?

      tree.groups.each do |group|
        assert group.label.present?
        assert group.links.any?, "group #{group.label} has no links"

        group.links.each do |link|
          assert link.title.present?
          assert_match %r{\A(https://|mailto:)}, link.url, "#{link.title} must use https:// or mailto:"
        end
      end
    end
  end
end
