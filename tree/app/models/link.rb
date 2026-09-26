class Link < ApplicationRecord
  include Translatable
  include Positioned

  belongs_to :link_group

  translates :hint

  validates :title, presence: true
  validates :url, presence: true, format: { with: %r{\A(https?://\S+|mailto:\S+@\S+)\z}, message: "must start with https://, http:// or mailto:" }

  normalizes :url, with: ->(url) { url.strip }

  private
    def siblings
      Link.where(link_group_id: link_group_id)
    end
end
