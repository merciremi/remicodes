# Post-convert hook: runs on the rendered article HTML, before layouts wrap it.
#
# Wraps kramdown/Rouge code blocks with the code-window chrome (filename
# tab + dot) required by the design spec, so post authors just write plain
# fenced code blocks and never touch the chrome by hand.

TERMINAL_LANGS = %w[shell zsh bash console txt terminal irb git diff].freeze

def code_window_filename(lang)
  return "terminal" if lang.nil? || TERMINAL_LANGS.include?(lang)

  lang
end

def wrap_code_blocks(html)
  html.gsub(
    %r{<div class="language-(?<lang>[\w-]+) highlighter-rouge"><div class="highlight"><pre class="highlight"><code>(?<code>.*?)</code></pre></div></div>}m
  ) do
    lang = Regexp.last_match(:lang)
    code = Regexp.last_match(:code)
    <<~HTML.strip
      <div class="code">
        <div class="code__tab"><span class="code__dot" aria-hidden="true"></span><span class="code__name">#{code_window_filename(lang)}</span></div>
        <pre tabindex="0"><code>#{code}</code></pre>
      </div>
    HTML
  end.gsub(
    %r{<div class="highlighter-rouge"><div class="highlight"><pre class="highlight"><code>(?<code>.*?)</code></pre></div></div>}m
  ) do
    code = Regexp.last_match(:code)
    <<~HTML.strip
      <div class="code">
        <div class="code__tab"><span class="code__dot" aria-hidden="true"></span><span class="code__name">terminal</span></div>
        <pre tabindex="0"><code>#{code}</code></pre>
      </div>
    HTML
  end.gsub(
    # Languages Rouge has no lexer for (txt, git...) come out as a bare <pre>.
    %r{<pre><code class="language-(?<lang>[\w-]+)">(?<code>.*?)</code></pre>}m
  ) do
    lang = Regexp.last_match(:lang)
    code = Regexp.last_match(:code)
    <<~HTML.strip
      <div class="code">
        <div class="code__tab"><span class="code__dot" aria-hidden="true"></span><span class="code__name">#{code_window_filename(lang)}</span></div>
        <pre tabindex="0"><code>#{code}</code></pre>
      </div>
    HTML
  end
end

# :documents covers posts and every other collection (notes).
Jekyll::Hooks.register [:documents, :pages], :post_convert do |doc|
  next unless doc.content

  doc.content = wrap_code_blocks(doc.content)
end
