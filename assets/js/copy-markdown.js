// "Copy Markdown" button next to a post's date: copies the post's Markdown copy
// (front matter, attribution and all, see _plugins/markdown_copies.rb) to the clipboard.
(() => {
  const button = document.querySelector("[data-copy-markdown]");
  if (!button || !navigator.clipboard) return; // no clipboard API: the button stays hidden

  const label = button.querySelector("span");
  const idleText = label.textContent;
  let timer;

  const fetchMarkdown = () =>
    fetch(button.dataset.copyMarkdown).then((response) => {
      if (!response.ok) throw new Error(response.statusText);
      return response.text();
    });

  // Safari only allows clipboard writes during the click itself, so we hand it a promise
  // (ClipboardItem) rather than awaiting the fetch first. Other browsers get writeText.
  const copy = () => {
    if (window.ClipboardItem && ClipboardItem.supports?.("text/plain") !== false) {
      const blob = fetchMarkdown().then((text) => new Blob([text], { type: "text/plain" }));
      return navigator.clipboard.write([new ClipboardItem({ "text/plain": blob })]);
    }
    return fetchMarkdown().then((text) => navigator.clipboard.writeText(text));
  };

  const show = (state, text) => {
    button.dataset.state = state;
    label.textContent = text;
    clearTimeout(timer);
    timer = setTimeout(() => {
      delete button.dataset.state;
      label.textContent = idleText;
    }, 2000);
  };

  button.hidden = false;
  button.addEventListener("click", () => {
    copy()
      .then(() => show("copied", button.dataset.textCopied))
      .catch(() => show("failed", button.dataset.textFailed));
  });
})();
