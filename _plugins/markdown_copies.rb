# Generator: publishes a raw Markdown copy of posts (and later pages) in the
# `markdown` collection, e.g. /ruby-stained-glass-notes-13/ → /ruby-stained-glass-notes-13.md.
# Runs on every build, so new posts get their copy for free.
#
# Which sources get a copy is set in _config.yml (`markdown_copies.sources`).
# Opt a single post or page out with `markdown_copy: false` in its front matter.
#
# Both sides know about each other:
#   - the original gets `markdown_url` → {{ page.markdown_url }} in layouts;
#   - the copy gets `source_url`, the URL of the original.
#
# Liquid tags ({% include signature.html %}, forms...) are HTML widgets with no
# Markdown equivalent, so they are dropped rather than rendered.

module MarkdownCopies
  COLLECTION = "markdown"

  class Copy < Jekyll::Document
    # The virtual source path ends in .txt so kramdown leaves the content alone
    # (the Identity converter copies it as is), but the output is still .md.
    def output_ext
      ".md"
    end
  end

  class Generator < Jekyll::Generator
    safe true
    priority :lowest

    def generate(site)
      collection = site.collections[COLLECTION]
      return unless collection

      sources(site).each do |source|
        copy = build_copy(site, collection, source)
        source.data["markdown_url"] = copy.url
        collection.docs << copy
      end
    end

    private

    def sources(site)
      Array(site.config.dig("markdown_copies", "sources")).flat_map do |source|
        case source
        when "posts" then site.posts.docs
        when "pages" then site.pages.select { |page| markdown_page?(site, page) }
        else raise ArgumentError, "markdown_copies: unknown source #{source.inspect}"
        end
      end.reject { |source| source.data["markdown_copy"] == false }
    end

    # Only pages written in Markdown: HTML pages have no Markdown to copy.
    def markdown_page?(site, page)
      page.is_a?(Jekyll::Page) &&
        site.config["markdown_ext"].split(",").include?(page.ext.delete_prefix("."))
    end

    def build_copy(site, collection, source)
      url = copy_url(source.url)
      copy = Copy.new(File.join(collection.directory, "#{url.delete_prefix('/').delete_suffix('.md')}.txt"),
                      site: site, collection: collection)

      copy.data.merge!(
        "title" => source.data["title"],
        "date" => source.data["date"],
        "permalink" => url,
        "source_url" => source.url,
        "layout" => "none",
        "sitemap" => false,
        "render_with_liquid" => false
      )
      copy.content = content_for(site, source)
      copy
    end

    # /my-post/ → /my-post.md, / → /index.md
    def copy_url(url)
      return "/index.md" if url == "/"

      "#{url.chomp('/').delete_suffix('.html')}.md"
    end

    def content_for(site, source)
      body = source.content
        .gsub(/\{%-?.*?-?%\}/m, "")
        .gsub(/\n{3,}/, "\n\n")
        .strip

      header = ["# #{source.data['title']}", ""]
      excerpt = source.data["excerpt"]
      header << "> #{excerpt.strip}" << "" if excerpt.is_a?(String)
      header << "Published on #{source.date.strftime('%Y-%m-%d')} by #{site.config['author']}." if source.respond_to?(:date)
      header << "Original: #{site.config['url']}#{source.url}"

      "#{header.join("\n")}\n\n#{body}\n"
    end
  end
end
