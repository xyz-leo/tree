module ApplicationHelper
  HTML_LANGS = { "pt" => "pt-BR", "en" => "en" }.freeze

  def html_lang(lang)
    HTML_LANGS.fetch(lang)
  end

  def lang_path(lang)
    lang == "en" ? en_path : root_path
  end

  def lang_url(lang)
    lang == "en" ? en_url : root_url
  end
end
