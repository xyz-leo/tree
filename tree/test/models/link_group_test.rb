require "test_helper"

class LinkGroupTest < ActiveSupport::TestCase
  test "requires a portuguese label" do
    group = LinkGroup.new(label_en: "Only English")

    assert_not group.valid?
    assert group.errors.of_kind?(:label_pt, :blank)
  end

  test "new groups go to the end" do
    assert_equal 4, LinkGroup.create!(label_pt: "Nova").position
  end

  test "keeps a given position" do
    assert_equal 0, LinkGroup.create!(label_pt: "Primeira", position: 0).position
  end

  test "orders by position" do
    assert_equal %w[Social Projetos Vazio], LinkGroup.ordered.map(&:label_pt)
  end

  test "deleting a group deletes its links" do
    assert_difference -> { Link.count }, -2 do
      link_groups(:social).destroy
    end
  end
end
