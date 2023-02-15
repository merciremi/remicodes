---
layout: default
title: RSpec
permalink: /series/rspec/
---

{% assign posts = site.posts | where: "category", "rspec" %}

<div class="m-b-72">
  <div class="serie-icon">
    <img src="{{ site.baseurl }}/media/shared/brown-rock.svg">
  </div>
  <h1 class="serie-title">A blog about RSpec</h1>
  <p>Hello, fellow RSpec tester. <em>Looking for my RSpec posts and tutorials?</em> You've come to the right place!</p>
  <p>
    This is where <strong>I gather all the blog's entries about Rspec</strong>. There are currently <strong>{{ posts.size }} posts about RSpec</strong> in this series.
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
