require "test_helper"

class ContentSecurityPolicyTest < ActionDispatch::IntegrationTest
  test "public pages send a strict policy" do
    [ root_path, en_path ].each do |path|
      get path
      policy = csp

      assert_equal [ "'self'" ], policy["default-src"], path
      assert_equal [ "'self'" ], policy["style-src"].first(1), path
      assert_equal [ "'self'" ], policy["font-src"], path
      assert_equal [ "'self'", "data:" ], policy["img-src"], path
      assert_equal [ "'none'" ], policy["object-src"], path
      assert_equal [ "'self'" ], policy["base-uri"], path
      assert_equal [ "'self'" ], policy["form-action"], path
      assert_equal [ "'none'" ], policy["frame-ancestors"], path
      assert_not policy.values.flatten.include?("'unsafe-inline'"), path
      assert_not policy.values.flatten.include?("'unsafe-eval'"), path
      assert_not policy.values.flatten.any? { it.start_with?("http") }, "#{path} allows an outside host"
    end
  end

  test "sign in and admin pages send the policy too" do
    get new_session_path
    assert_equal [ "'none'" ], csp["frame-ancestors"]

    sign_in_as users(:admin)
    admin_pages.each do |path|
      get path
      assert_equal [ "'none'" ], csp["frame-ancestors"], path
    end
  end

  test "every inline script carries this request's nonce" do
    sign_in_as users(:admin)

    ([ root_path, en_path, new_session_path ] + admin_pages).each do |path|
      get path
      nonce = csp_nonce

      assert_includes csp["script-src"], "'nonce-#{nonce}'", path
      inline = css_select("script:not([src])")
      assert inline.any?, "#{path} has no inline scripts (theme and importmap expected)"
      inline.each { |script| assert_equal nonce, script["nonce"], "#{path}: #{script.to_html.truncate(80)}" }
      assert_select "script[type=importmap][nonce=?]", nonce
    end
  end

  test "pages use no inline style attributes or event handlers" do
    sign_in_as users(:admin)

    ([ root_path, en_path, new_session_path ] + admin_pages).each do |path|
      get path

      assert_select "[style]", { count: 0 }, "#{path} has a style attribute"
      handlers = css_select("*").flat_map { |el| el.attributes.keys.select { it.start_with?("on") } }
      assert_empty handlers, "#{path} has inline event handlers"
    end
  end

  test "form errors render within the policy" do
    sign_in_as users(:admin)

    patch admin_profile_path, params: { profile: { name: "" } }

    assert_response :unprocessable_content
    assert_select "[style]", 0
    css_select("script:not([src])").each { |script| assert_equal csp_nonce, script["nonce"] }
  end

  test "each request gets a new nonce" do
    get root_path
    first = csp_nonce
    get root_path

    assert_not_equal first, csp_nonce
  end

  test "public page sets no cookies" do
    get root_path
    assert_nil response.headers["Set-Cookie"]

    get en_path
    assert_nil response.headers["Set-Cookie"]
  end

  test "CSRF token is on admin pages only" do
    with_forgery_protection do
      get root_path
      assert_select "meta[name=csrf-token]", 0
      assert_nil response.headers["Set-Cookie"]

      get new_session_path
      assert_select "meta[name=csrf-token]", 1

      sign_in_as users(:admin)
      get admin_root_path
      assert_select "meta[name=csrf-token]", 1
    end
  end

  private
    # The test environment turns CSRF protection off; these checks need it on.
    def with_forgery_protection
      ActionController::Base.allow_forgery_protection = true
      yield
    ensure
      ActionController::Base.allow_forgery_protection = false
    end

    def csp
      response.headers["Content-Security-Policy"].to_s.split(";").to_h do |directive|
        name, *values = directive.split
        [ name, values ]
      end
    end

    def csp_nonce
      csp["script-src"].find { it.start_with?("'nonce-") }.delete_prefix("'nonce-").delete_suffix("'")
    end

    def admin_pages
      [
        admin_root_path,
        edit_admin_profile_path,
        new_admin_link_group_path,
        edit_admin_link_group_path(link_groups(:social)),
        new_admin_link_group_link_path(link_groups(:social)),
        edit_admin_link_path(links(:github))
      ]
    end
end
