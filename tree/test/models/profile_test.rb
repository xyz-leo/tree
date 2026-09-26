require "test_helper"

class ProfileTest < ActiveSupport::TestCase
  test "requires name and handle" do
    profile = Profile.new

    assert_not profile.valid?
    assert profile.errors.of_kind?(:name, :blank)
    assert profile.errors.of_kind?(:handle, :blank)
  end

  test "instance is the saved profile" do
    assert_equal profiles(:main), Profile.instance
  end

  test "instance is an unsaved default when there is none" do
    Profile.delete_all

    assert Profile.instance.new_record?
    assert_equal "tree", Profile.instance.handle
  end
end
