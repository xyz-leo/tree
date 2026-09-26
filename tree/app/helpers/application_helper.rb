module ApplicationHelper
  HTML_LANGS = { "pt" => "pt-BR", "en" => "en" }.freeze
  OG_LOCALES = { "pt" => "pt_BR", "en" => "en_US" }.freeze

  def html_lang(lang)
    HTML_LANGS.fetch(lang)
  end

  def lang_path(lang)
    lang == "en" ? en_path : root_path
  end

  def lang_url(lang)
    lang == "en" ? en_url : root_url
  end

  def og_locale(lang)
    OG_LOCALES.fetch(lang)
  end

  # Absolute URL of the image shown in link previews.
  def share_image_url
    "#{request.base_url}/icon.png"
  end
end
