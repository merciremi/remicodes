---
layout: post
title: Dynamic image mosaics with modern CSS
excerpt:
date: 2000-01-01
permalink:
categories:
cover_image:
toc: true
---

For Cults, we launched Bundles (check them out) recently, and originally the public page for bundles looked like this: 

<!-- image -->

It looked a little sad and not super engaging, so I decided to reuse a view component we already have and tweak it to fit our bundles constrains. This would look like this: 

<!--image-->

In my initial environment, I worked with a bundle of creations that would have at least 5 creations. In development it looked good enough to make some of that page pop. But once in beta in production, it looked like that: 

<!--image of hugo -->

Meh.

The initial layout is relying on a CSS grid of four columns and two lines. The main image spans two columns and two rows on the right half of the container, the four side images each fits into a fourth of the remaining square.

<!-- add some pseudo code HTML and CSS -->

But since bundles have a minimum of two creations, how can we handle the fact that a bundle cover can be two, three, four or five illustrations gracefully? By dynamically distributing illustrations on the grid layouyt with the help of CSS `:has()`, `:nth-child()` and `:last_child`.

<!-- add some pseudo code HTML and CSS -->

The main trick here is that our container is a grid with fine enough granularity, that I can span illustrations over smaller or larger areas based on my need.

Some notes: 
- this is still pretty static in the sense that I have a CSS based on small enough set of illustrations that I can write all the scenarios by hand (the audacity!)
- nth-child() takes a nifty `1 of .css_class` which is very useful

And voilà: 

<!-- add images of the final layout in production -->

If you're a user of Cults, please check this new feature out and let us know if you like it and what we can do to improve it.
