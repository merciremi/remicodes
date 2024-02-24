---
layout: post
title: Domain complexity vs applicative complexity
excerpt: "For years, code would fall into two categories: easy (good!) and hard (bad!). Recently, I've realized that not every piece of _hard_ code is created equal. Complex code often encompasses two kinds of complexity: domain complexity and applicative complexity. And I often failed to identify which is which."
date: 20/02/2024
permalink: /complexities/
category: other
cover_image: /media/2024/02/remi-mercier-domain-complexity-applicative-complexity.png
---

For years, code would fall into two categories: easy (good!) and hard (bad!).

Recently, I've realized that not every piece of _hard_ code is created equal. Complex code often encompasses two kinds of complexity: domain complexity and applicative complexity.

And I often failed to identify which is which.

## Domain complexity

Domain complexity is what we refer to when we talk about "rocket science". Building _actual_ spaceships, forecasting extreme meteorological events, studying the human genome, etc... You know, _hard_ stuff.

But any domain where programming happens has inbuilt complexity.

I once worked for a real estate company. The regulations were complex enough that they transpose as complexity in our codebase.

Later, I worked for a book-streaming company. Handling the (supposedly) standard formats used by publishers to share their books was the stuff of nightmares.

There's no way around domain complexity. If you want to solve your users' pain points, you'll have to solve domain complexity.

## Applicative complexity

Applicative complexity, on the other hand, happens from _how we solve problems_.

Applicative complexity is the code smell, the anti-pattern, and the method with thirty-seven conditionals nested three levels deep.

Applications have phases in their lifecycle. When you start building a company, the application is crucial, but not all that there is. Teams focus on shipping new features, not on following conventions and patterns. Getting the company off the ground _is_ the priority.

This first phase is where you'll introduce a lot of applicative complexity. And when applicative complexity adds up with domain complexity, you end up with _hard code_.

Your application starts leaking at the seams. Usage drives new problems: your database can't sustain a heavier load, and your abstractions do not allow you to introduce new requirements.

## Solving applicative complexity: consolidation

Later, when you're out of the woods, a new phase in the lifecycle begins.

I call this phase __consolidation__.

Features need preliminary refactoring. Teams finally take a look at their `.rubocop_todo.yml`. Maybe it's time to rewrite these seven service-objects nested in one another.

Consolidation often frightens teams. Features take twice as much time to ship. Programmers keep yammering about preliminary clean-ups. However, consolidation is necessary if you wish to grow or to evolve. Not doing the work now will only result in your application grinding to a halt.

I briefly worked with a company that did not ship a single feature in a year. Why? Their codebase was full of applicative complexity yet empty of any tests. They had decided against any consolidation, again and again. And now, they were toast.

When you can't be sure your changes won't break the application, you don't release any.

Life has seasons. Applications too. Be sure to watch for the signs so you don't sow when you should toil.

Cheers,

Rémi - [@remi@ruby.social](https://ruby.social/@remi)
