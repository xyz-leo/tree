module LinksHelper
  # Domains with a brand icon in app/views/icons. Subdomains match too
  # (www.youtube.com, m.facebook.com, br.linkedin.com).
  ICON_DOMAINS = {
    "github.com" => "github",
    "instagram.com" => "instagram",
    "x.com" => "x",
    "twitter.com" => "x",
    "linkedin.com" => "linkedin",
    "facebook.com" => "facebook",
    "fb.com" => "facebook",
    "youtube.com" => "youtube",
    "youtu.be" => "youtube"
  }.freeze

  # Icon for links to any other site.
  DEFAULT_ICON = "link"

  NEW_TAB_TEXT = { "pt" => "(abre em nova aba)", "en" => "(opens in a new tab)" }.freeze

  EMPHASIS = /\*([^*\n]+)\*/

  # A link to link.url wrapping the block. Links open in a new tab, except
  # email links (a new tab there would stay blank). Screen readers are told
  # about the new tab.
  def page_link_to(link, lang, **options, &block)
    content = capture(&block)
    return link_to(link.url, **options) { content } if mailto?(link.url)

    link_to link.url, target: "_blank", rel: "noopener", **options do
      safe_join([ content, tag.span(" #{NEW_TAB_TEXT.fetch(lang)}", class: "sr-only") ])
    end
  end

  # Name of the icon partial for a link URL, or nil when there's none.
  def link_icon_name(url)
    uri = URI.parse(url)
    return "mail" if mailto?(url)
    return unless uri.host

    host = uri.host.downcase
    ICON_DOMAINS.find { |domain, _| host == domain || host.end_with?(".#{domain}") }&.last
  rescue URI::InvalidURIError
    nil
  end

  # Short form of a URL shown next to a link: the host without "www.", or the
  # address of an email link.
  def link_display(url)
    return url.to_s.sub(/\Amailto:/i, "").split("?").first if mailto?(url)

    URI.parse(url).host.to_s.downcase.delete_prefix("www.").presence || url
  rescue URI::InvalidURIError
    url
  end

  # Text with *words between asterisks* in <em>. Everything else is escaped.
  def emphasized(text)
    parts = text.to_s.split(EMPHASIS)
    safe_join(parts.each_with_index.map { |part, i| i.odd? ? tag.em(part) : part })
  end

  # The same text with the asterisks removed, for meta tags.
  def without_emphasis(text)
    text.to_s.gsub(EMPHASIS, '\1')
  end

  private
    def mailto?(url)
      url.to_s.downcase.start_with?("mailto:")
    end
end
