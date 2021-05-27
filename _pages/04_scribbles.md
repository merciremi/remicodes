---
layout: page
title: Scribbles
permalink: /scribbles/
excerpt: "This is where I scribble random thoughts, drawings, songs, etc. Both in French and in English."
---

_Griffonages à la hâte_ and random thoughts in French and English.

{% assign sorted_scribbles = site.scribbles | sort: 'date' | reverse %}

{% for scribble in sorted_scribbles %}
  <div class="scribble">
    <a href="#{{ scribble.date | date: '%Y-%m-%d'}}" class="scribble-icon-link">
      <img src="{{ site.baseurl }}/media/scribble.png" class="scribble-icon" id="{{ scribble.date | date: '%Y-%m-%d'}}" />
    </a>
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
