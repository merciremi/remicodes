---
layout: default
title: RSpec
permalink: /series/rspec/
---

{% assign posts = site.posts | where: "category", "rspec fundamentals" | sort: 'date' %}
{% assign other_posts = site.posts | where: "category", "rspec" %}

<div class="m-b-72">
  <div class="serie-icon">
    <img src="{{ site.baseurl }}/media/shared/brown-rock.svg">
  </div>
  <h1 class="serie-title">RSpec Fundamentals</h1>
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

  <h2 class="m-b-48">Other RSpec related posts</h2>
  {% for post in other_posts %}
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
