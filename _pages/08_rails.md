---
layout: series_page
title: A blog about Ruby on Rails
permalink: /series/rails/
excerpt: "Looking for my Ruby on Rails tutorials and posts? You've come to the right place! This is where I blog about building applications with Ruby on Rails."
---

{% assign posts = site.posts | where: "category", "rails" %}

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
