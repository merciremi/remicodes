---
layout: page
title: This is my garden 🌱
excerpt: This is where I plant seeds and nurture my interests.
permalink: /garden/
---

This is where I plant seeds and nurture my interests.

{% assign garden = site.collections | where_exp:"collection", "collection.permalink contains 'garden'" %}
{% for topic in garden %}
  [{{ topic.label | capitalize }}]({{site.baseurl}}{{topic.permalink}}/)
{% endfor %}
