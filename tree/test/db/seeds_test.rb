require "test_helper"

class SeedsTest < ActiveSupport::TestCase
  test "creates the admin user from the environment" do
    User.delete_all

    seed "ADMIN_EMAIL" => "me@example.com", "ADMIN_PASSWORD" => "a long password"

    assert_equal "me@example.com", User.sole.email_address
    assert User.sole.authenticate("a long password")
  end

  test "updates the existing user instead of adding another" do
    seed "ADMIN_EMAIL" => "new@example.com", "ADMIN_PASSWORD" => "another long password"

    assert_equal users(:admin).id, User.sole.id
    assert_equal "new@example.com", User.sole.email_address
    assert User.sole.authenticate("another long password")
  end

  test "keeps exactly one user" do
    User.create!(email_address: "extra@example.com", password: "a long password")

    seed "ADMIN_EMAIL" => "admin@example.com", "ADMIN_PASSWORD" => "a long password"

    assert_equal 1, User.count
  end

  test "does nothing without credentials" do
    assert_no_changes -> { User.pluck(:email_address, :password_digest) } do
      seed "ADMIN_EMAIL" => nil, "ADMIN_PASSWORD" => nil
      seed "ADMIN_EMAIL" => "me@example.com", "ADMIN_PASSWORD" => ""
    end
  end

  test "rejects a short password" do
    assert_raises(ActiveRecord::RecordInvalid) do
      seed "ADMIN_EMAIL" => "me@example.com", "ADMIN_PASSWORD" => "short"
    end
  end

  private
    def seed(env)
      previous = env.keys.index_with { ENV[it] }
      env.each { |key, value| ENV[key] = value }
      capture_io { load Rails.root.join("db/seeds.rb") }
    ensure
      previous.each { |key, value| ENV[key] = value }
    end
end
