---
layout: default
title: A blog about Ruby on Rails
permalink: /series/rails/
excerpt: "Looking for my Ruby on Rails tutorials and posts? You've come to the right place! This is where I blog about building applications with Ruby on Rails."
---

{% assign posts = site.posts | where: "category", "rails" %}

<div class="m-b-72">
  <div class="serie-icon">
    <img src="{{ site.baseurl }}/media/shared/golden-mountain.svg">
  </div>
  <h1 class="serie-title">A Ruby on Rails blog</h1>
  <div class="breadcrumbs">
    <p><a href="{{ site.baseurl }}/blog">← Return to the complete archive</a></p>
  </div>
  <p>
    Hello, fellow Ruby on Rails programmer. <em>Looking for my Ruby on Rails tutorials and posts?</em> You've come to the right place.
  </p>
  <p>
    This is where <strong>I gather all the blog's entries about Ruby on Rails</strong>. There are currently <strong>{{ posts.size }} posts about Rails</strong> in this series.
  </p>
</div>

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

Wanna read more? <a href="{{ site.baseurl }}/blog">Browse the complete archive.</a>
