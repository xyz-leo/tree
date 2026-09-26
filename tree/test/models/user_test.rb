require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "requires a password of at least 12 characters" do
    user = User.new(email_address: "new@example.com", password: "short")

    assert_not user.valid?
    assert user.errors.of_kind?(:password, :too_short)
    assert User.new(email_address: "new@example.com", password: "long enough pass").valid?
  end

  test "email must be unique" do
    user = User.new(email_address: users(:admin).email_address, password: "long enough pass")

    assert_not user.valid?
    assert user.errors.of_kind?(:email_address, :taken)
  end
end
