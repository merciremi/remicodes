---
layout: series_page
title: Scribbles
permalink: /scribbles/
excerpt: "This is where I scribble random thoughts, drawings, songs, etc. Both in French and in English."
---

{% assign sorted_scribbles = site.data.scribbles | sort: 'date' | reverse %}

<section class="scribbles">
  {% for scribble in sorted_scribbles %}
    <div class="scribble">
      <div class="scribble--icon">
        <img src="{{ site.baseurl }}/media/shared/blue-star.svg">
      </div>
      <div>
        {{ scribble.content | markdownify }}
      </div>
      <a href="#{{ scribble.date | date: '%Y-%m-%d'}}" class="scribble-date">
        <p>{{ scribble.date | date: '%B %d, %Y'}} #</p>
      </a>
    </div>
  {% endfor %}
</section>
