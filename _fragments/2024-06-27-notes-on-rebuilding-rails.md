---
layout: fragment
date: 2024-06-27
title: "Notes on Rebuilding Rails"
permalink: /notes-on-rebuilding-rails/
---

Currently reading Rebuilding Rails by Noah Gibbs.

## Notes:

### Chapter 3

Sometimes, Noah writes methods in the context of a `module`, sometimes in the context of a class. Why?

> Modules are collections of methods and constants. They cannot generate instances. Classes may generate instances (objects), and have per-instance state (instance variables). [Source](https://www.ruby-lang.org/en/documentation/faq/8/){:target="\_blank"}

---

Checking `rails/active_support_dependencies/autoload.rb` and I see this `@_at_path`. What is the reason for this `@_`?

> So, @\_instance_var has no special meaning. Rails internally uses it to distinguish private/protected variables that other should not modify/access. [source](https://stackoverflow.com/questions/36551735/instance-variables-that-start-with){:target="\_blank"}

---

`bundler: failed to load command: rackup Couldn't find handler for: puma, thin, falcon, webrick. (LoadError)`

If you run into `bundle exec rackup -p 3001 bundler: failed to load command: rackup. Couldn't find handler for: puma, thin, falcon, webrick. (LoadError)`, look closely at your gemspec, and at the configuration described by Noah page 18.



