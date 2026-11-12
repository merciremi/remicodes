# Generator: publishes the indexes behind the search field on the blog indexes, one per language:
#   - /search.json    → English posts and notes (blog/index.html);
#   - /fr/search.json → French posts (blog/fr/index.html).
# A document's language is its `lang` front matter, English by default.
# Scribbles are never indexed: only posts and notes are.
# Runs on every build, so new posts and notes are searchable for free.
#
# One entry per post and note:
#   { "title", "url", "excerpt", "tags" (topic names), "date", "kind" ("post" | "note") }
#
# Notes have no `excerpt` in their front matter: we fall back on their first paragraph.
# Opt a single document out with `search: false` in its front matter.

module SearchIndex
  DEFAULT_LANG = "en"
  FILENAME = "search.json"
  EXCERPT_LENGTH = 200

  class Generator < Jekyll::Generator
    safe true
    priority :lowest

    def generate(site)
      topic_names = Array(site.config["topics"]).to_h { |topic| [topic["slug"], topic["name"]] }

      documents(site).group_by { |doc| doc.data["lang"] || DEFAULT_LANG }.each do |lang, docs|
        entries = docs.map { |doc| entry_for(doc, topic_names) }
        site.pages << index_page(site, lang, entries)
      end
    end

    private

    def documents(site)
      notes = site.collections["notes"]&.docs || []

      (site.posts.docs + notes)
        .reject { |doc| doc.data["search"] == false }
        .sort_by(&:date)
        .reverse
    end

    def index_page(site, lang, entries)
      dir = lang == DEFAULT_LANG ? "" : lang
      page = Jekyll::PageWithoutAFile.new(site, site.source, dir, FILENAME)
      page.content = JSON.generate(entries)
      page.data.merge!(
        "layout" => "none",
        "sitemap" => false,
        "render_with_liquid" => false # titles or excerpts with {{ }} must stay as is
      )
      page
    end

    def entry_for(doc, topic_names)
      excerpt = excerpt_for(doc)
      {
        # Untitled notes (see notes.rb) go by their first words, so the result still has a link text.
        "title" => doc.data["title"].to_s.empty? ? untitled_title(excerpt) : doc.data["title"].to_s,
        "url" => doc.url,
        "excerpt" => excerpt,
        "tags" => Array(doc.data["tags"]).map { |slug| topic_names.fetch(slug, slug) },
        "date" => doc.date.strftime("%Y-%m-%d"),
        "kind" => doc.collection.label == "notes" ? "note" : "post"
      }
    end

    def untitled_title(excerpt)
      words = excerpt.split
      words.size > 10 ? "#{words.first(10).join(" ")}…" : excerpt
    end

    def excerpt_for(doc)
      excerpt = doc.data["excerpt"]
      text = excerpt.is_a?(String) ? excerpt : first_paragraph(doc.content)
      truncate(plain_text(text))
    end

    def first_paragraph(markdown)
      markdown.to_s
        .gsub(/\{%-?.*?-?%\}/m, "")
        .split(/\n{2,}/)
        .map(&:strip)
        .find { |block| block.match?(/\A[[:alnum:]_*"'(\[]/) } || ""
    end

    # Rough Markdown → text: good enough for a one-line preview.
    def plain_text(text)
      text
        .gsub(/!\[[^\]]*\]\([^)]*\)/, "")           # images
        .gsub(/\[([^\]]*)\]\([^)]*\)/, '\1')        # links
        .gsub(/<[^>]+>/, "")                        # HTML tags
        .gsub(/[*_`]/, "")                          # emphasis, code
        .gsub(/\s+/, " ")
        .strip
    end

    def truncate(text)
      return text if text.length <= EXCERPT_LENGTH

      "#{text[0, EXCERPT_LENGTH].sub(/\s+\S*\z/, '')}…"
    end
  end
end
