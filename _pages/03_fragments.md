---
layout: page
title: Fragments
permalink: /fragments/
excerpt: ""
---

Fragments are works in progress, rough notes, and early drafts that might end up as fully fledged posts.

{% for fragment in site.fragments %}
  <div class="post-excerpt">
    <h4>
      <a href="{{ fragment.url | prepend: site.baseurl }}">{{ fragment.title }}</a>
      <time>{{ fragment.date | date: "%b %-d, %Y"}}</time>
    </h4>
  </div>
{% endfor %}
