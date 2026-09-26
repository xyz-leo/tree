class LinkGroup < ApplicationRecord
  include Translatable
  include Positioned

  has_many :links, -> { ordered }, dependent: :destroy

  translates :label

  validates :label_pt, presence: true
end
