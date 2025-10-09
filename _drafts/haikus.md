---
layout: post
title: Marketing Haikus
excerpt: Just a list of haikus, mostly written when I was working (and being bored out of my wits) in marketing. Making fun as a tool to push through.
date: 2025-10-09
permalink: /marketing-haikus/
redirect_from: /haikus/
category: other
cover_image:
---

Just a list of haikus, mostly written when I was ~~working~~ dying of boredom in marketing. Making fun as a tool to push through.

<div>
  {% for haikus_by_year in site.data.haikus %}
    <h2>{{ haikus_by_year[0] }}</h2>

    {% assign haikus = haikus_by_year[1] %}

    {% for haiku in haikus %}
      <p>{{ haiku.content }}</p>
      <p>---</p>
    {% endfor %}
  {% endfor %}
</div>
