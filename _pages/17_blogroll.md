---
layout: page
title: Blogroll
permalink: /blogroll/
---

<ul>
{% for blog in site.data.blogroll %}
  <li>
    <a href="{{ blog.url }}">
      {{ blog.name }}
    </a>
  </li>
{% endfor %}
</ul>
