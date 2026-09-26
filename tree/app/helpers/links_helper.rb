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

  # Name of the icon partial for a link URL, or nil when there's none.
  def link_icon_name(url)
    uri = URI.parse(url)
    return "mail" if uri.scheme == "mailto"
    return unless uri.host

    host = uri.host.downcase
    ICON_DOMAINS.find { |domain, _| host == domain || host.end_with?(".#{domain}") }&.last
  rescue URI::InvalidURIError
    nil
  end
end
