---
layout: default
title: Ruby
permalink: /series/ruby/
---

{% assign posts = site.posts | where: "category", "ruby" %}

<div class="m-b-72">
  <div class="serie-icon">
    <img src="{{ site.baseurl }}/media/shared/pinkish-sun.svg">
  </div>
  <h1 class="serie-title">A Ruby Blog</h1>
  <p>Hello, fellow Ruby programmer. <em>Looking for my Ruby posts and tutorials?</em> You've come to the right place!</p>
  <p>
    This is where <strong>I gather all the blog's entries about Ruby</strong>. There are currently <strong>{{ posts.size }} posts about Ruby</strong> in this series.
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
