# Post-convert hook: makes images in posts and notes lazy-loaded and async
# decoded, so authors never write those attributes by hand.
#
# The first image of a document is left alone: it may sit above the fold,
# where lazy loading would delay it.

def lazy_load_images(html)
  seen_first = false

  html.gsub(/<img\b[^>]*>/m) do |tag|
    if !seen_first
      seen_first = true
      tag
    elsif tag.match?(/\sloading=/)
      tag
    else
      tag.sub(/\s*\/?>\z/) { |ending| %( loading="lazy" decoding="async"#{ending.strip.start_with?("/") ? " /" : ""}>) }
    end
  end
end

# :documents covers posts and every other collection (notes).
Jekyll::Hooks.register :documents, :post_convert do |doc|
  next unless doc.content
  next if doc.collection.label == MarkdownCopies::COLLECTION

  doc.content = lazy_load_images(doc.content)
end
