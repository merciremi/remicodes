---
layout: page
title: Fragments
permalink: /fragments/
excerpt: "Fragments are works in progress, rough notes, and early drafts that might end up as fully fledged posts."
---

Fragments are works in progress, rough notes, and early drafts that might end up as fully fledged posts.

{% assign sorted_fragments = site.fragments | sort: 'date' | reverse %}

{% for fragment in sorted_fragments %}
  <div class="post-excerpt">
    <h4>
      <a href="{{ fragment.url }}">{{ fragment.title }}</a>
      <time>{{ fragment.date | date: "%b %-d, %Y"}}</time>
    </h4>
  </div>
{% endfor %}
