// Autocomplete search over posts and notes.
// The index is /search.json (see _plugins/search_index.rb), fetched on first focus.
(() => {
  const MIN_LENGTH = 2;
  const MAX_RESULTS = 8;

  const root = document.querySelector("[data-search]");
  if (!root) return;

  const input = root.querySelector("input");
  const list = root.querySelector("[role=listbox]");
  const status = root.querySelector("[data-search-status]");

  // Interface strings, in the page's language (see _data/i18n.yml).
  const text = {
    empty: root.dataset.textEmpty,
    none: root.dataset.textNone,
    one: root.dataset.textOne,
    many: root.dataset.textMany,
  };

  let index = null;
  let loading = null;
  let results = [];
  let active = -1;

  // Lowercase and drop accents, so "regle" finds "règle".
  const normalize = (text) =>
    text.normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase();

  const load = () => {
    loading ||= fetch(root.dataset.indexUrl)
      .then((response) => response.json())
      .then((entries) => {
        index = entries.map((entry) => ({
          ...entry,
          _title: normalize(entry.title),
          _tags: normalize(entry.tags.join(" ")),
          _excerpt: normalize(entry.excerpt),
        }));
      })
      .catch(() => {
        loading = null; // let the next focus retry
      });
    return loading;
  };

  // Every term must match somewhere. Title matches weigh more than tags, tags more than excerpts.
  const search = (query) => {
    const terms = normalize(query).split(/\s+/).filter(Boolean);

    return index
      .map((entry) => {
        let score = 0;
        for (const term of terms) {
          const wordStart = new RegExp(`(^|\\W)${term.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}`);
          if (wordStart.test(entry._title)) score += 6;
          else if (entry._title.includes(term)) score += 4;
          else if (entry._tags.includes(term)) score += 3;
          else if (entry._excerpt.includes(term)) score += 1;
          else return null;
        }
        return { entry, score };
      })
      .filter(Boolean)
      .sort((a, b) => b.score - a.score) // stable: ties keep the newest first
      .slice(0, MAX_RESULTS)
      .map(({ entry }) => entry);
  };

  const close = () => {
    list.hidden = true;
    input.setAttribute("aria-expanded", "false");
    input.removeAttribute("aria-activedescendant");
    active = -1;
  };

  const highlight = (position) => {
    const options = list.querySelectorAll("[role=option]");
    options.forEach((option, i) => option.setAttribute("aria-selected", i === position));
    active = position;
    if (position >= 0) {
      input.setAttribute("aria-activedescendant", options[position].id);
      options[position].scrollIntoView({ block: "nearest" });
    } else {
      input.removeAttribute("aria-activedescendant");
    }
  };

  const element = (tag, className, text) => {
    const node = document.createElement(tag);
    if (className) node.className = className;
    if (text) node.textContent = text;
    return node;
  };

  const render = (query) => {
    list.replaceChildren();

    if (results.length === 0) {
      list.append(element("li", "search__empty", text.empty.replace("%{query}", query)));
      status.textContent = text.none;
    } else {
      results.forEach((entry, i) => {
        const option = element("li", "search__result");
        option.id = `search-result-${i}`;
        option.setAttribute("role", "option");
        option.setAttribute("aria-selected", "false");

        const link = element("a", null);
        link.href = entry.url;
        link.tabIndex = -1;

        const meta = element("span", "search__meta");
        if (entry.kind === "note") meta.append(element("span", "note-tag", "note"));
        if (entry.tags.length) meta.append(element("span", null, entry.tags.join(" · ")));

        link.append(element("span", "search__title", entry.title), meta);
        if (entry.excerpt) link.append(element("span", "search__excerpt", entry.excerpt));
        option.append(link);
        list.append(option);
      });
      status.textContent =
        results.length === 1 ? text.one : text.many.replace("%{count}", results.length);
    }

    list.hidden = false;
    input.setAttribute("aria-expanded", "true");
    active = -1;
  };

  const update = async () => {
    const query = input.value.trim();
    if (query.length < MIN_LENGTH) {
      close();
      status.textContent = "";
      return;
    }
    await load();
    if (!index || input.value.trim() !== query) return; // failed, or the user kept typing
    results = search(query);
    render(query);
  };

  input.addEventListener("focus", () => {
    load();
    if (input.value.trim().length >= MIN_LENGTH) update();
  });
  input.addEventListener("input", update);

  input.addEventListener("keydown", (event) => {
    if (list.hidden) return;

    switch (event.key) {
      case "ArrowDown":
        event.preventDefault();
        if (results.length) highlight((active + 1) % results.length);
        break;
      case "ArrowUp":
        event.preventDefault();
        if (results.length) highlight(active <= 0 ? results.length - 1 : active - 1);
        break;
      case "Enter": {
        const target = results[active === -1 ? 0 : active];
        if (target) {
          event.preventDefault();
          window.location.href = target.url;
        }
        break;
      }
      case "Escape":
        close();
        break;
    }
  });

  // Mouse hover drives the same highlight as the keyboard.
  list.addEventListener("mousemove", (event) => {
    const option = event.target.closest("[role=option]");
    if (!option) return;
    const position = [...list.children].indexOf(option);
    if (position !== active) highlight(position);
  });

  document.addEventListener("click", (event) => {
    if (!root.contains(event.target)) close();
  });
  root.addEventListener("focusout", (event) => {
    if (event.relatedTarget && !root.contains(event.relatedTarget)) close();
  });
})();
