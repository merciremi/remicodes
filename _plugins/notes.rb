# Support for the notes index (notes/index.html, _layouts/notes-tag.html).
#
# Notes have their own tags, separate from the posts' topics: `note_tags` in the
# front matter takes any words. Each tag gets a page at /notes/tags/:tag/.

module NoteFilters
  # Drops the filename tabs added by site_hooks.rb, so card previews don't read "zsh" or "terminal".
  def without_code_tabs(html)
    html.gsub(%r{<div class="code__tab">.*?</div>}m, "")
  end
end
Liquid::Template.register_filter(NoteFilters)

# Jekyll derives a title from the filename, so a missing title only shows in the raw front matter.
def untitled_note?(note)
  front_matter = File.read(note.path)[Jekyll::Document::YAML_FRONT_MATTER_REGEXP, 1]
  front_matter[/^title:(.*)$/, 1].to_s.delete(%q("')).strip.empty?
end

Jekyll::Hooks.register :site, :post_read do |site|
  site.collections["notes"].docs.each do |note|
    # Piles are built from tags, so an untagged note would silently vanish from the index.
    raise Jekyll::Errors::FatalException, "#{note.relative_path}: a note needs at least one note_tags entry" if Array(note.data["note_tags"]).empty?

    # A title is optional: without one, a note stays untitled rather than named after its file.
    note.data.delete("title") if untitled_note?(note)
  end
end

class NoteTagPages < Jekyll::Generator
  safe true

  # Tags are grouped by slug, so "Rails" and "rails" share a pile. Notes are oldest first.
  def generate(site)
    notes = site.collections["notes"].docs.sort_by(&:date)
    grouped = notes.flat_map { |note| Array(note.data["note_tags"]).map { |tag| [tag.to_s, note] } }
                   .group_by { |tag, _note| Jekyll::Utils.slugify(tag) }

    site.data["note_tags"] = grouped.map do |slug, pairs|
      { "slug" => slug, "name" => pairs.first.first, "notes" => pairs.map(&:last).uniq, "url" => "/notes/tags/#{slug}/" }
    end.sort_by { |tag| tag["name"].downcase }

    site.data["note_tags"].each { |tag| site.pages << tag_page(site, tag) }

    notes.each do |note|
      note.data["stack_notes"] = stack_notes(note, grouped)
      note.data["referenced_by"] = referencing_notes(note, notes, site)
    end
  end

  private

  # The other notes linking to this one, newest first. Reads the raw Markdown, so it catches
  # inline links and reference definitions, root-relative or with the full domain.
  def referencing_notes(note, notes, site)
    path = Regexp.escape(note.url.chomp("/"))
    domain = Regexp.escape(site.config["url"].to_s.sub(%r{\Ahttps?://(www\.)?}, ""))
    link = %r{(?:\]\(|^\[[^\]]+\]:\s*)(?:https?://(?:www\.)?#{domain})?#{path}/?(?:#[^)\s]*)?(?=[)\s]|\z)}

    notes.reject { |other| other == note }.select { |other| other.content.match?(link) }.reverse
  end

  STACK_DEPTH = 2

  # The sheets lying under a note on its page: the notes sharing one of its tags, those
  # that come after it first, then wrapping round to the oldest. Empty if it's alone in its piles.
  def stack_notes(note, grouped)
    slugs = Array(note.data["note_tags"]).map { |tag| Jekyll::Utils.slugify(tag.to_s) }
    mates = slugs.flat_map { |slug| grouped[slug].map(&:last) }.uniq.sort_by(&:date)
    index = mates.index(note)
    (mates[(index + 1)..] + mates[0...index]).first(STACK_DEPTH)
  end

  def tag_page(site, tag)
    Jekyll::PageWithoutAFile.new(site, site.source, "notes/tags/#{tag["slug"]}", "index.html").tap do |page|
      page.data.merge!("layout" => "notes-tag", "title" => "Notes about #{tag["name"]}", "note_tag" => tag, "view_transitions" => true)
    end
  end
end
