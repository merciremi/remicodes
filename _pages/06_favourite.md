---
layout: default
title: My favourite posts - Rémi Mercier
permalink: /fav/
---

<h2>My favourite essays, handpicked with love: </h2>
{% assign posts = site.posts | where: "categories", "fav" %}
{% for post in posts %}
  <div class="post-excerpt">
    <h4>
      <a href="{{ post.url | prepend: site.baseurl }}">{{ post.title }}</a>
    </h4>
    <p>{{ post.excerpt }}</p>

  </div>
{% endfor %}

Wanna read more? <a href="{{ site.baseurl }}/blog">You can browse through my complete archive.</a>


