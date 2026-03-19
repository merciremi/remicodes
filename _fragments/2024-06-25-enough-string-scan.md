---
layout: fragment
date: 2024-06-25
title: "StringScanner"
permalink: /enough-string-scanner/
---

Currently reading Rebuilding Rails by Noah Gibbs.

At some point, he writes about checking out Active Support for some pointers on metaprogramming. Currently felt into a rabbit hole on the [duration part of the lib](https://github.com/rails/rails/tree/main/activesupport/lib/active_support/duration){:target="\_blank"}.

Anyways. Here's a nifty class in Ruby that facilitates some scanning on strings.

> StringScanner provides for lexical scanning operations on a String. [source](https://ruby-doc.org/3.3.3/exts/strscan/StringScanner.html){:target="\_blank"}

## Usage:

{% highlight zsh %}
  string = StringScanner.new("bob")
  => #<StringScanner 0/3 @ "bob">

  [9] pry(main)> string.eos?
  => false

  [10] pry(main)> string.pos
  => 0

  [12] pry(main)> string.peek(5)
  => "bob"

  [14] pry(main)> string.getch
  => "b"

  [15] pry(main)> string.pos
  => 1

  [16] pry(main)> string.reset
  => #<StringScanner 0/3 @ "bob">

  [17] pry(main)> string.pos
  => 0
{% endhighlight %}

