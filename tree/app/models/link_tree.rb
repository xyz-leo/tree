# The page content from config/links.yml, resolved for one language.
class LinkTree
  LANGS = %w[pt en].freeze

  Group = Data.define(:label, :links)
  Link = Data.define(:title, :url, :hint)

  attr_reader :lang, :name, :handle, :bio, :groups

  def self.load(lang, path: Rails.configuration.x.links_file)
    new(YAML.load_file(path), lang)
  end

  def initialize(data, lang)
    raise ArgumentError, "unknown lang: #{lang.inspect}" unless LANGS.include?(lang)

    @lang = lang
    @name = text(data.fetch("name"))
    @handle = text(data.fetch("handle"))
    @bio = text(data["bio"])
    @groups = data.fetch("groups").map do |group|
      Group.new(
        label: text(group.fetch("label")),
        links: group.fetch("links").map do |link|
          Link.new(title: text(link.fetch("title")), url: link.fetch("url"), hint: text(link["hint"]))
        end
      )
    end
  end

  private
    # A value is either the same in every language or a { "pt" => ..., "en" => ... } hash.
    def text(value)
      value.is_a?(Hash) ? value.fetch(lang) : value
    end
end
