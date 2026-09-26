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

  NEW_TAB_TEXT = { "pt" => "(abre em nova aba)", "en" => "(opens in a new tab)" }.freeze

  # Links open in a new tab, except email links (a new tab there would stay blank).
  # Screen readers are told about the new tab.
  def page_link_to(link, lang)
    return link_to(link.title, link.url) if mailto?(link.url)

    link_to link.url, target: "_blank", rel: "noopener" do
      safe_join([ link.title, tag.span(" #{NEW_TAB_TEXT.fetch(lang)}", class: "sr-only") ])
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

  private
    def mailto?(url)
      url.to_s.downcase.start_with?("mailto:")
    end
end
