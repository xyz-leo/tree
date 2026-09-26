require "test_helper"

class TranslatableTest < ActiveSupport::TestCase
  test "returns the text for each language" do
    group = link_groups(:projects)

    assert_equal "Projetos", group.label("pt")
    assert_equal "Projects", group.label("en")
  end

  test "english falls back to portuguese when blank" do
    group = LinkGroup.new(label_pt: "Social", label_en: "")

    assert_equal "Social", group.label("en")
  end

  test "optional text can be missing in both languages" do
    assert_nil links(:email).hint("pt")
    assert_nil links(:email).hint("en")
  end

  test "rejects unknown languages" do
    assert_raises(ArgumentError) { profiles(:main).bio("es") }
  end
end
