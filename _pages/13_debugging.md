---
layout: default
title: A blog about debugging
permalink: /series/debugging/
excerpt: "Looking for my debugging tutorials and posts? You've come to the right place! This is where I blog about troubleshooting and debugging applications."
---

{% assign posts = site.posts | where: "category", "debugging" %}

<div class="m-b-72">
  <div class="serie-icon">
    <img src="{{ site.baseurl }}/media/shared/brown-rock.svg">
  </div>
  <h1 class="serie-title">Debugging tutorials</h1>
  <div class="breadcrumbs">
    <p><a href="{{ site.baseurl }}/blog">← Return to the complete archive</a></p>
  </div>
  <p>Hello, fellow debuggers and troubleshooters. <em>Looking for my posts and tutorials about debugging your applications?</em> You've come to the right place!</p>
  <p>
    This is where <strong>I gather all the blog's entries about debugging</strong> whether you're a <i>puts</i> developer or using a debugger like <em>pry-byebug</em>. There are currently <strong>{{ posts.size }} posts</strong> in this series.
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
