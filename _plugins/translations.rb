# Generator: links the language versions of a page or post together.
#
# Give every version the same `translation_key` in its front matter:
#
#   blog/index.html     → translation_key: blog
#   blog/fr/index.html  → translation_key: blog, lang: fr
#
# Each version then gets `translations`, the list of its other versions
# ({ "lang", "url", "title" }), used for the hreflang tags in <head> and the
# language switch in layouts. A page with no `lang` is English.
#
# Pages in French also get `locale: fr_FR`, so jekyll-seo-tag's og:locale is
# a full locale rather than the bare `fr`.

module Translations
  DEFAULT_LANG = 'en'.freeze
  LOCALES = { 'fr' => 'fr_FR' }.freeze

  class Generator < Jekyll::Generator
    safe true
    priority :low

    def generate(site)
      documents = site.pages + site.documents

      documents.each do |document|
        locale = LOCALES[document.data["lang"]]
        document.data["locale"] ||= locale if locale
      end

      documents
        .select { |document| document.data["translation_key"] }
        .group_by { |document| document.data["translation_key"] }
        .each { |key, versions| link(key, versions) }
    end

    private

    def link(key, versions)
      langs = versions.map { |version| lang(version) }
      duplicates = langs.tally.select { |_, count| count > 1 }.keys
      if duplicates.any?
        Jekyll.logger.warn "Translations:", "#{key.inspect} has several versions in #{duplicates.join(', ')}"
      end

      versions.each do |version|
        version.data["translations"] = (versions - [version]).map do |other|
          { "lang" => lang(other), "url" => other.url, "title" => other.data["title"] }
        end
      end
    end

    def lang(document)
      document.data["lang"] || DEFAULT_LANG
    end
  end
end
