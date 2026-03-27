---
layout: series_page
title: Career Growth
permalink: /series/career/
excerpt: "Looking for my Career Growth posts? You've come to the right place! This is where I blog about building a great career as a software developer."
---

{% assign posts = site.posts | where: "category", "career" %}

<section class="archive">
  {% for post in posts %}
    <div class="m-b-48">
      <h3>
        <a href="{{ post.url | prepend: site.baseurl }}">{{ post.title }}</a>
      </h3>
      <p>{{ post.excerpt }}</p>
      <a href="{{ post.url | prepend: site.baseurl }}" class="read-more">Read this essay →</a>
    </div>
  {% endfor %}
</section>
