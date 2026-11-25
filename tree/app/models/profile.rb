# Name, handle, tagline and bio at the top of the page. There is only ever one.
class Profile < ApplicationRecord
  include Translatable

  translates :bio, :tagline

  validates :name, :handle, presence: true

  def self.instance
    first || new(name: "Tree", handle: "tree")
  end
end
