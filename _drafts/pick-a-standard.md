---
layout: post
title: Pick a standard and move on
excerpt: Why would you spend your cognitive capacity on useless choices?
date: 27/03/2024
permalink: /pick-a-standard/
category: rails
cover_image:
---

Let me tell you what my day looks like in a team with no standards, no conventions, and no processes in place.

Every time I work on a new API endpoint, I wonder about:
- Which routing syntax should I pick from the four pre-existing syntaxes used in the file?
- Should I shallow nest my controller action as per `SomeController` or shouldn't I shallow nest as per `AnotherController`?
- What about resource fetching? In a callback? Memoized perhaps?
- Am I to authorize the parent resource or the actual resource through Pundit? Why are there custom methods in our policies that do not match the methods from our controller?
- What about the methods of my controllers? CRUD? Not CRUD? Declarative? Imperative?
- and on, and on, and on.

Is the list getting boring? It certainly gets boring for your team. And I've not even started about models, service objects, jobs or serializers.

This (partial) list is every thought that goes through my brain before I can start working on my feature when there are no standards.

Not picking a standard or a convention results in me having to think about unimportant matters, over and over.

Add people to your team, and the cognitive load will grow exponentially. People will wonder when they could ship. Your pull requests will turn into an endless quagmire of opinions when they should be readable documentation.

So, in the name of our collective cognitive overload, pick a standard today!

Pick whichever you want - it does not matter - and focus on core work.

Some standards and conventions I'm currently working on:
- Routing: namespacing rules, no shallow nesting, syntax preferences, etc.
- Controllers: documented paths, CRUD methods as much as possible, parameters sanitization, etc.
- Pull requests: conventional comments, mandatory linting before opening a pull request, etc.

A lot of these standards are plain Ruby on Rails conventions. They're not even my opinions. My opinions on which standard is best are not even important.

Picking a standard - any standard - is. So everyone on your team can leave the wondering behind and start shipping.

Cheers,

Rémi - [@remi@ruby.social](https://ruby.social/@remi)
