---
layout: fragment
title: Enough Docker
date: 2020-11-12
permalink: /enough-docker/
---

The team I've joined in September uses Docker to keep local versions of our database's schema synced up with production.

Docker is one tough nail to learn, so I'm keeping my notes here.

{% highlight zsh %}
  # login to a self-hosted registry
  docker login your_host:8000

  # pull images defined in docker-compose.yml
  docker-compose pull

  # run a specific image (-rm stands for remove container after run)
  docker-compose run --rm my_image_name

  # list running containers
  docker ps
  # list all containers
  docker ps -a

  # stop a specific container
  docker container stop my_container

  # recreate a container after the config was changed
  docker-compose up
{% endhighlight %}
