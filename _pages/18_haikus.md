---
layout: page
title: Haiku
permalink: /haiku/
---

<div>
  {% for year in site.data.haikus %}
    <h2>{{ year[0] }}</h2>

    {% assign haikus = year[1] %}

    {% for haiku in haikus %}
      <p>{{ haiku.content }}</p>
    {% endfor %}
  {% endfor %}
</div>
