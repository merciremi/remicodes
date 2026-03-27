---
layout: series_page
title: Ruby Blog
permalink: /series/ruby/
excerpt: "Looking for my Ruby tutorials and posts? You've come to the right place! This is where I blog about building applications with Ruby."
---

{% assign posts = site.posts | where: "category", "ruby" %}

<section class="archive">
  {% for post in posts %}
    <div class="m-b-48">
      <h2>
        <a href="{{ post.url | prepend: site.baseurl }}">{{ post.title }}</a>
      </h2>
      <p>{{ post.excerpt }}</p>
      <a href="{{ post.url | prepend: site.baseurl }}" class="read-more">Read this essay →</a>
    </div>
  {% endfor %}
</section>
