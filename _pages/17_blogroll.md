---
layout: page
title: A bunch of blogs I like to read
permalink: /blogroll/
---

{% assign sorted_collection = site.data.blogroll | sort: "name" %}
{% for item in sorted_collection %}
  - [{{ item.first_name }} {{ item.name }}]({{item.url}}){:target="\_blank"}
{% endfor %}
