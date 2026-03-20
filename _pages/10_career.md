---
layout: default
title: Career Growth
permalink: /series/career/
excerpt: "Looking for my Career Growth posts? You've come to the right place! This is where I blog about building a great career as a software developer."
---

{% assign posts = site.posts | where: "category", "career" %}

<div class="m-b-72">
  <div class="serie-icon">
    <img src="{{ site.baseurl }}/media/shared/stormy-river.svg">
  </div>
  <h1 class="serie-title">Career Growth</h1>
  <div class="breadcrumbs">
    <p><a href="{{ site.baseurl }}/blog">← Return to the complete archive</a></p>
  </div>
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
