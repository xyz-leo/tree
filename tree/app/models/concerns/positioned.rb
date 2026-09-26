# Ordered records. New records go to the end of their list unless given a position.
module Positioned
  extend ActiveSupport::Concern

  included do
    scope :ordered, -> { order(:position, :id) }

    before_validation :append_to_list, on: :create, if: -> { position.blank? }
    validates :position, numericality: { only_integer: true }
  end

  private
    def append_to_list
      self.position = (siblings.maximum(:position) || 0) + 1
    end

    # Records sharing the list this one belongs to.
    def siblings
      self.class.all
    end
end
