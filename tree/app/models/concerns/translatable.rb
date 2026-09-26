# Text stored as <attr>_pt and <attr>_en columns. English is optional and
# falls back to Portuguese.
#
#   translates :label
#   group.label("en") # => label_en, or label_pt when label_en is blank
module Translatable
  extend ActiveSupport::Concern

  LANGS = %w[pt en].freeze

  class_methods do
    def translates(*attributes)
      attributes.each do |attribute|
        define_method(attribute) do |lang|
          raise ArgumentError, "unknown lang: #{lang.inspect}" unless LANGS.include?(lang)

          pt = public_send(:"#{attribute}_pt")
          lang == "en" ? public_send(:"#{attribute}_en").presence || pt : pt
        end
      end
    end
  end
end
