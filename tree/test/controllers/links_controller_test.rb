require "test_helper"

class LinksControllerTest < ActionDispatch::IntegrationTest
  test "root renders the portuguese page" do
    get root_path

    assert_response :success
    assert_select "html[lang=pt-BR]"
    assert_select "title", "test-handle"
    assert_select "meta[name=description][content=?]", "Bio em português."
    assert_select "h1", "Test Person"
    assert_select ".bio", "Bio em português."
    assert_equal [ "Social", "Projetos" ], css_select(".group-header").map { it.text.strip }
    assert_select ".hint", "esta página"
  end

  test "the page is public" do
    get root_path
    assert_response :success

    get en_path
    assert_response :success
  end

  test "/en renders the english page" do
    get en_path

    assert_response :success
    assert_select "html[lang=en]"
    assert_select ".bio", "Bio in English."
    assert_equal [ "Social", "Projects" ], css_select(".group-header").map { it.text.strip }
    assert_select ".hint", "this page"
  end

  test "/en/ with a trailing slash works" do
    get "/en/"

    assert_response :success
    assert_select "html[lang=en]"
  end

  test "renders every link in order" do
    get root_path

    assert_select ".group-list a" do |links|
      assert_equal [ "GitHub", "Email", "tree" ], links.map { it.children.first.text.strip }
      assert_equal [ "https://github.com/test-handle", "mailto:test@example.com", "https://example.com/tree" ],
        links.map { it["href"] }
    end
  end

  test "known sites and email get an icon, other links keep the bullet" do
    get root_path

    rows = css_select(".group-list li")
    assert_equal [ "icon-github", "icon-mail", nil ],
      rows.map { |li| li.at_css("svg.icon")&.[]("class")&.split&.last }
    assert_equal [ true, true, false ], rows.map { |li| li["class"].to_s.include?("has-icon") }
  end

  test "links open in a new tab, except email" do
    get root_path

    assert_select "a[href='https://github.com/test-handle'][target=_blank][rel=noopener]"
    assert_select "a[href='https://example.com/tree'][target=_blank][rel=noopener]"
    assert_select "a[href='mailto:test@example.com']:not([target])"
  end

  test "screen readers are told about the new tab in the page language" do
    get root_path
    assert_select "a[href='https://github.com/test-handle'] .sr-only", "(abre em nova aba)"
    assert_select "a[href='mailto:test@example.com'] .sr-only", 0

    get en_path
    assert_select "a[href='https://github.com/test-handle'] .sr-only", "(opens in a new tab)"
  end

  test "header links stay in the same tab" do
    get root_path

    assert_select ".site-header a[target]", 0
  end

  test "language switch marks the current language" do
    get root_path
    assert_select ".lang-option[aria-current=page]", "PT"
    assert_select ".lang-option[href='/en']", "EN"

    get en_path
    assert_select ".lang-option[aria-current=page]", "EN"
    assert_select ".lang-option[href='/']", "PT"
  end

  test "brand links to the page in the current language" do
    get en_path

    assert_select "a.brand[href='/en']", "test-handle"
  end

  test "points search engines at both languages" do
    get root_path

    assert_select "link[rel=alternate][hreflang=pt-BR][href='http://www.example.com/']"
    assert_select "link[rel=alternate][hreflang=en][href='http://www.example.com/en']"
    assert_select "link[rel=alternate][hreflang=x-default][href='http://www.example.com/']"
  end

  test "theme toggle is labelled in the page language" do
    get root_path
    assert_select "button.theme-toggle[aria-label=?]", "Alternar tema claro"

    get en_path
    assert_select "button.theme-toggle[aria-label=?]", "Toggle light theme"
  end

  test "follows the order set by position" do
    link_groups(:projects).update!(position: 0)
    links(:email).update!(position: 0)

    get root_path

    assert_equal [ "Projetos", "Social" ], css_select(".group-header").map { it.text.strip }
    assert_equal [ "tree", "Email", "GitHub" ], css_select(".group-list a").map { it.children.first.text.strip }
  end

  test "hides groups without links" do
    get en_path

    assert_select ".group-header", text: "Empty", count: 0
  end

  test "renders with no profile saved yet" do
    Profile.delete_all

    get root_path

    assert_response :success
    assert_select "h1", "Tree"
  end

  test "other languages are not routed" do
    get "/es"

    assert_response :not_found
  end
end
