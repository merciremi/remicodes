---
layout: default
title: Bafouilles
permalink: /bafouilles/
excerpt: ""
---


<div class="m-b-72">
  <div class="serie-icon">
    <img src="{{ site.baseurl }}/media/shared/blue-star.svg">
  </div>
  <h1 class="serie-title">Bafouilles</h1>
  <div class="breadcrumbs">
    <p><a href="{{ site.baseurl }}/">← Vers la page d'accueil</a></p>
  </div>
  <div class='scribbles-filters'>
    <a href="{{site.baseurl}}/scribbles/" class='filter'>Anglais</a>
    <a href="{{site.baseurl}}/bafouilles/" class='filter' aria-current='true'>Français</a>
  </div>
</div>

{% assign sorted_scribbles = site.data.scribbles-fr | sort: 'date' | reverse %}

<section class="scribbles">
  {% for scribble in sorted_scribbles %}
    <div class="scribble">
      <a href="#{{ scribble.date | date: '%Y-%m-%d'}}">
        <img src="{{ site.baseurl }}/media/shared/blue-star.svg" class='scribble-icon'>
      </a>
      <div>
        {{ scribble.content | markdownify }}
      </div>
      <a href="#{{ scribble.date | date: '%Y-%m-%d'}}" class="scribble-date">
        <p>{{ scribble.date | date: '%B %d, %Y'}} #</p>
      </a>
    </div>
  {% endfor %}
</section>
