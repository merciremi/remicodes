---
layout: post
title: hands-on introduction to debugging your code with pry-byebug
---

When I taught Ruby's basics at Le Wagon Paris, one the things I loved passing along to students was how to debug code with pry-byebug.

Like every new developers, I first started as [a `puts` debugger](https://tenderlovemaking.com/2016/02/05/i-am-a-puts-debuggerer.html){:target="\_blank"}. I would write `puts` everywhere to see what was what - something I'm still doing when debugging Javascript [^1]. One day, I had the chance to spend some time with [Cecile Varin](https://www.linkedin.com/in/cecilevarin/?originalSubdomain=fr){:target="\_blank"} who showed me enough pry-byebug to feel confortable ditching the `puts`.

Let's dive right in so i can show you a very practical guide on using pry-byebug in your applications.

- set up
- your code doesn't work, what do you do?
  - add a breaking point
  - read the console
  - basic command #1: interrogate the current values, methods, vars...
  - basic command #2: go to the next line w/ next
  - basic command #3: continue
  - basic command #4: exit || exit!

that's it.

<!-- we need code from controller + console code -->

https://github.com/deivid-rodriguez/pry-byebug

[^1]: Can someone please explain to me how the hell is supposed to work `debugger` in Javascript?
