---
layout: default
title: Ruby on Rails
permalink: /series/rails/
---

{% assign posts = site.posts | where: "category", "rails" %}

<div class="m-b-72">
  <div class="serie-icon">
    <img src="{{ site.baseurl }}/media/shared/golden-mountain.svg">
  </div>
  <h1 class="serie-title">Ruby on Rails</h1>
  <p>There are <strong>{{ posts.size }}</strong> posts in this series.</p>
</div>

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

Wanna read more? <a href="{{ site.baseurl }}/blog">Browse the complete archive.</a>
