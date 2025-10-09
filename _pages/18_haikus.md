---
layout: page
title: Haikus
permalink: /haikus/
---

A list of haikus, mostly written when I was working in marketing (and being bored out of my wits). Making fun as a tool to push through.

<div>
  {% for haikus_by_year in site.data.haikus %}
    <h2>{{ haikus_by_year[0] }}</h2>

    {% assign haikus = haikus_by_year[1] %}

    {% for haiku in haikus %}
      <p>{{ haiku.content }}</p>
    {% endfor %}
  {% endfor %}
</div>
