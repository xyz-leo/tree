require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = users(:admin) }

  test "sign in page is at /sessions/new" do
    get "/sessions/new"

    assert_response :success
    assert_select "meta[name=robots][content=?]", "noindex, nofollow"
    assert_select "form[action='/sessions']" do
      assert_select "input[type=email][name=email_address]"
      assert_select "input[type=password][name=password]"
    end
  end

  test "signs in with valid credentials" do
    post session_path, params: { email_address: @user.email_address, password: "correct horse battery" }

    assert_redirected_to admin_root_path
    assert cookies[:session_id].present?
    assert_equal 1, @user.sessions.count
  end

  test "returns to the admin page that asked for sign in" do
    get edit_admin_profile_path
    assert_redirected_to new_session_path

    post session_path, params: { email_address: @user.email_address, password: "correct horse battery" }
    assert_redirected_to edit_admin_profile_url
  end

  test "email is matched case-insensitively" do
    post session_path, params: { email_address: " ADMIN@example.com ", password: "correct horse battery" }

    assert_redirected_to admin_root_path
  end

  test "signs in through the form with CSRF protection on" do
    ActionController::Base.allow_forgery_protection = true

    get new_session_path
    token = css_select("form[action='/sessions'] input[name=authenticity_token]").first["value"]
    post session_path, params: { authenticity_token: token, email_address: @user.email_address, password: "correct horse battery" }
    assert_redirected_to admin_root_path

    follow_redirect!
    get edit_admin_profile_path
    token = css_select("form[action='/admin/profile'] input[name=authenticity_token]").first["value"]
    patch admin_profile_path, params: { authenticity_token: token, profile: { name: "Via Form" } }
    assert_redirected_to admin_root_path
    assert_equal "Via Form", profiles(:main).reload.name
  ensure
    ActionController::Base.allow_forgery_protection = false
  end

  test "rejects a sign in without a CSRF token" do
    ActionController::Base.allow_forgery_protection = true

    post session_path, params: { email_address: @user.email_address, password: "correct horse battery" }

    assert_response :unprocessable_content
    assert_nil cookies[:session_id]
  ensure
    ActionController::Base.allow_forgery_protection = false
  end

  test "rejects a wrong password" do
    post session_path, params: { email_address: @user.email_address, password: "wrong" }

    assert_redirected_to new_session_path
    assert_nil cookies[:session_id]
    follow_redirect!
    assert_select ".flash-alert", "Try another email address or password."
  end

  test "rejects an unknown email" do
    post session_path, params: { email_address: "nobody@example.com", password: "correct horse battery" }

    assert_redirected_to new_session_path
    assert_nil cookies[:session_id]
  end

  test "signed in pages offer sign out" do
    sign_in_as(@user)

    get new_session_path
    assert_select "form[action='/sessions'] input[name=_method][value=delete]"
  end

  test "sign out ends the session" do
    sign_in_as(@user)

    assert_difference -> { @user.sessions.count }, -1 do
      delete session_path
    end
    assert_redirected_to new_session_path
    assert_empty cookies[:session_id]
  end

  test "there is no password reset" do
    get "/passwords/new"

    assert_response :not_found
  end
end
