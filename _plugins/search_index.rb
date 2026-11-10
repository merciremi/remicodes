# Generator: publishes /search.json, the index behind the search field on the blog index.
# Runs on every build, so new posts and notes are searchable for free.
#
# One entry per post and note:
#   { "title", "url", "excerpt", "tags" (topic names), "date", "kind" ("post" | "note") }
#
# Notes have no `excerpt` in their front matter: we fall back on their first paragraph.
# Opt a single document out with `search: false` in its front matter.

module SearchIndex
  PATH = "search.json"
  EXCERPT_LENGTH = 200

  class Generator < Jekyll::Generator
    safe true
    priority :lowest

    def generate(site)
      topic_names = Array(site.config["topics"]).to_h { |topic| [topic["slug"], topic["name"]] }

      entries = documents(site).map { |doc| entry_for(doc, topic_names) }

      index = Jekyll::PageWithoutAFile.new(site, site.source, "", PATH)
      index.content = JSON.generate(entries)
      index.data.merge!(
        "layout" => "none",
        "sitemap" => false,
        "render_with_liquid" => false # titles or excerpts with {{ }} must stay as is
      )
      site.pages << index
    end

    private

    def documents(site)
      notes = site.collections["notes"]&.docs || []

      (site.posts.docs + notes)
        .reject { |doc| doc.data["search"] == false }
        .sort_by(&:date)
        .reverse
    end

    def entry_for(doc, topic_names)
      {
        "title" => doc.data["title"].to_s,
        "url" => doc.url,
        "excerpt" => excerpt_for(doc),
        "tags" => Array(doc.data["tags"]).map { |slug| topic_names.fetch(slug, slug) },
        "date" => doc.date.strftime("%Y-%m-%d"),
        "kind" => doc.collection.label == "notes" ? "note" : "post"
      }
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
