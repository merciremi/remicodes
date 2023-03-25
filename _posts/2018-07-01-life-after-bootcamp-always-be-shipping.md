---
layout: post
title: 'Life After Bootcamp: Always Be Shipping'
date: 2018-07-01
excerpt: "Last week was the 9th and final week of my Ruby on Rails Bootcamp at Le Wagon Paris. My buddies and I showed to the public what could be shipped in two weeks. A lot of great projects stood out that night. But now, it’s Monday morning. The excitement has worn off over the weekend, the many naps and the odd drinks. What shall I do?"
category: 'other'
permalink: /life-after-bootcamp/
---

Last week was the 9th and final week of my Ruby on Rails Bootcamp at Le Wagon Paris. My buddies and I - from the batches 145 and 146 - showed to the public what could be shipped in two weeks. A lot of great projects stood out that night - whether for their overall classiness or their technical challenges. On top of my head, I really dug [Potify](https://www.potify.pw/), [Recll](http://www.recll.xyz/), [Diggerz](https://www.diggerz.co/), [Storymap](http://www.storymap.space/) and [Kbuddy](http://www.kbuddy.org/). I was very happy about the final release of [Harry](http://harry.team). [Antoine](https://github.com/agoffette), [Laura](https://github.com/Laumartin4) and [Giovanni](https://github.com/giovannirescaglio) made it a very cool project to work on. Kudos to you all!

It was an exciting night worthy of those exciting nine weeks.

But now, it’s Monday morning. The excitement has worn off over the weekend, the many naps and the odd drinks. What shall I do?

<blockquote>
  ⛵️Always. Be. Shipping.
</blockquote>

Being at Le Wagon was like getting into Hogwarts. I realized I could wave my fingers around my keyboard and make things appeared at will! There’s no way I’m going back to the Muggles.

So for the next two months, I’ll build an app a week and go back to some basic training (remember the Karate Kid? Well, the same but with more programming and less painting fences).

<img class='large' src="{{ site.baseurl }}/media/2018/karatekid.gif" alt="">

☝️ Note: This is an ongoing post so I’ll update my progress as I go, mostly depending on suggestions, whims...

## Jot it. Do it. Strike it.
### A public to-do app
#### Status: Done ✅
Let’s go back to the fundamentals of the CRUD for a moment.

<img class='large' src="{{ site.baseurl }}/media/2018/strikeitv0.gif" alt="Strike It App" height="90%" width="90%">

Basic features:
- CRUD 101
- Each user can CRUD his/her own tasks only
- Each task can be assigned one of three categories: to-do, doing, done
- Each user has a public page where everyone can check his/her current task, done tasks and, pending tasks
<!--
My very own public page 👇
![strike-it-public-profile](/content/images/2018/06/strike-it-public-profile.png) -->

Nice to have:
- Each task has a set deadline with some kind of countdown
- Update tasks list for the user without reloading the page
- Display user stats for day/week/month
- Create, update and destroy a task through a messaging app (this alone might do a week worth of work actually 🙀)

It’ll be good to go back to the routes. And I’ll finally be able to set up myself Devise and Pundit.

[Strike it V0.1](https://strike-it.herokuapp.com/) is now live. You can check it out and try it out yourself. 🚀

It has taken me ten days to ship it. And it still needs some work (especially that multi-step sign-up form that start from the homepage 🤔).

## RandCode
### Real-time coding challenges
#### Status: To-do

Some of my buddies presented Code and Drink, a coding challenges platform where multiple players can try and outsmart each other. I found the idea of coding challenges to be an interesting use of ActionCable.

Basic features:
- Multi-session app w/ ActionCable
- Each user can register to play against another random user
- Each user is paired w/ another user
- Two user can code on the same screen with two pages side by side
- The first one to get the answer wins
- General ranking of all participants

## App ideas backlog

- App with many models
- App consuming an API
- App with Action cable for real-time features like a chat
- App with background jobs and no front end
- App to track books I lent and borrowed
- Scan ISBN and get a book info prefilled
- Tag your friend
- Set a start date
- A state: lent, back at home
- APIs to try: Algolia, Twilio…
- A game where something moves to eat something (dynamisation)
- Trying my hand at react → app only exposing an API <a href="https://github.com/merciremi/vuejs-101" target="_blank">and interacting w/ a  JS framework.</a>

## Back to basics
### Learning the basics of programming
#### Status: Doing 🔥

- CodeWars katas up to 6th kyu / Leetcode
- Learn RSpec, integration tests, test coverage…
- Add linter in code
- Code speed: [complexity]({{site.baseurl}}/wtf-time-complexity/), n+1 queries…
- Basics of trigonometry, algorithms…

---

## Check the batch 145 demo day

<iframe src="https://www.youtube.com/embed/2KMdJLoWjCU?rel=0&amp;showinfo=0&amp;start=5555" frameborder="0" allow="autoplay; encrypted-media" allowfullscreen></iframe>
