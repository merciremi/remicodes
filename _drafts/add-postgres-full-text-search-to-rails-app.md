---
layout: post
title: Add postgres full-text search to Rails app
excerpt: 
date: 2000-01-01
permalink: 
categories: 
cover_image: 
---

PostreSQL full-text search is a powerful feature.

Let's build a completely over-engineered implem for this.





DO the rest in second post.
- implementation for fun
  - gem: we'll not do that but it use all stuff we talked before
  - homemade: just vectors
- what about performances?
  - calculations on the fly
  - pre-calculation kept uptodate with a trigger
  - perf gain

that was nerdy, not very readable so I don't think you should build that like that in production, but it was fun.
