---
layout: page
title: Scribbles
permalink: /scribbles/
---

_Griffonages à la hâte_ and random thoughts in French and English.

{% assign sorted_scribbles = site.scribbles | sort: 'date' | reverse %}

{% for scribble in sorted_scribbles %}
  <div class="scribble">
    <div>
      <img src="{{ site.baseurl }}/media/scribble.png" class="scribble-icon" />
    </div>
    <div>
      {{ scribble.content }}
    </div>
    <div>
      <time>
        {{ scribble.date | date: '%B %d, %Y'}}
      </time>
      {% if scribble.lang == 'fr' %}
        <span class="flag-emoji">🇫🇷</span>
      {% else %}
        <span class="flag-emoji">🇬🇧</span>
      {% endif %}
    </div>
  </div>
{% endfor %}
