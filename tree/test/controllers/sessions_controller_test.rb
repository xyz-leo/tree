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

    assert_redirected_to root_path
    assert cookies[:session_id].present?
    assert_equal 1, @user.sessions.count
  end

  test "email is matched case-insensitively" do
    post session_path, params: { email_address: " ADMIN@example.com ", password: "correct horse battery" }

    assert_redirected_to root_path
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
