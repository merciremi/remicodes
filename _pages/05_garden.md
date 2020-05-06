---
layout: page
title: This is my garden 🌱
permalink: /garden/
---

This is where I plant seeds and nurture my interests.

{% assign garden = site.collections | where_exp:"collection", "collection.permalink contains 'garden'" %}
{% for topic in garden %}
  [{{ topic.label | remove: "garden_" | capitalize }}]({{site.baseurl}}{{topic.permalink}}/)
{% endfor %}
