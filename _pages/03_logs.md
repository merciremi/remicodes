---
layout: page
title: Logs
permalink: /logs/
---

<p>Breadcrumbs and moments of life logged in French or in English.</p>

{% for log in site.logs %}
  <div class="post-excerpt">
    <h4>
      <a href="{{ log.url | prepend: site.baseurl }}">{{ log.title }}</a>
      &nbsp; <time>{{ log.date | date: "%b %-d, %Y" }}</time>
      &nbsp; {% if log.lang %} 🇫🇷 {% endif %}
    </h4>
    <p>
      {{ log.excerpt }}
    </p>
  </div>
{% endfor %}
