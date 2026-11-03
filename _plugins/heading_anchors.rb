# jekyll-toc's `inject_anchors` only runs when the page has `toc: true`.
# This one always runs, so headings keep their anchors when the TOC is off.
module HeadingAnchors
  def heading_anchors(html)
    toc_config = @context.registers[:site].config["toc"] || {}
    Jekyll::TableOfContents::Parser.new(html, toc_config).inject_anchors_into_html
  end
end

Liquid::Template.register_filter(HeadingAnchors)
