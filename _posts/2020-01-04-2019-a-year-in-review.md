---
layout: post
title: "2019 - a year in review"
date:   2020-01-04
excerpt: "Well, here we are. December has come and gone. Now is the time to look back on what happened last year: a lot of writing and becoming a Real Developer™."
permalink: /2019-year-review/
---

Well, here we are. December has come and gone. Now is the time to look back on what happened last year - and to brew some mulled wine.

## Taking care of my internet garden

After writing sporadically for years, I've been itching to write more. And so I did! What changed? Well, I learned how to build software and ship things. As it turns out, it's easier to write about something you enjoy doing day in day out.

I also decided to write for my pleasure rather than for the whole _build an audience_ nonsense. That's why there are no analytics, no SEO optimization, no engagement hacks (and let me tell you that I know quite a lot about those) on my website.

Relaunching my own corner of the web would have not been possible without the tremendous help (unbeknown to her) of Tania Rascia's [fantastic tutorial on setting up Jekyll](https://www.taniarascia.com/make-a-static-website-with-jekyll/). So thank you, Tania.

My first post was an [introduction to time complexity]({{site.baseurl}}/wtf-time-complexity/). Not something I thought I'd ever write about! But after being tasked to compute the time complexity of an algorithm during a technical test, I thought I'd share this fancy knowledge with the world.

Some other technical stuff I've written this year:
- [An introduction to the keyword self]({{site.baseurl}}/your-new-friend-self/)
- [How to use railway-oriented business transactions to unclutter Rails controllers]({{site.baseurl}}/transactions-in-rails/)
- [Testing railway-oriented business transactions with Rspec]({{site.baseurl}}/testing-business-transactions-in-rails/)

The technical post I'm the proudest of is my [beginners' introduction to Ruby classes and objects]({{site.baseurl}}/beginners-introduction-to-ruby-classes-objects/).

Now, if I'm honest, my favourite posts are those about life and how it sometimes sucks. I've come to accept that sharing shitty moments is okay and that other people can relate to those stories. It's also okay to reclaim and feel empowered by our struggles.

One of these, in early 2019, was to [own my story as a thirty-five years old junior developer]({{site.baseurl}}/own-your-story/) and not trying to fake being a Real Developer™ (i.e. someone with a CS background and years of expertise).

I also wanted to share [my own stories about systemic violence in our mainstream work culture]({{site.baseurl}}/the-violence-within/) and how it can be fought back to some extent through the act of talking and caring.

These two posts alone sparked a lot of conversations with folks. They also reminded me why I love writing: to share stories (however they look), and not to build a personal brand.

I'll try to write more about stuff unrelated to tech this year. Some topics I care about: redefining our relationship to work, degrowth (the infamous _décroissance_), unlearning mainstream masculinity, feminism, rape culture, raising kids, building things with your hands, etc.

Also on my list of things I'd enjoy writing: a [wiki](https://tomcritchlow.com/wiki/) or [a personal garden](https://joelhooks.com/digital-garden), laying out my values, shorter notes ([see my scribbles]({{site.baseurl}}/scribbles/)) both in French and English. We'll see.

## My first year in a dev team

2019 was the year I got my first gig as a developer. I had some projects under my belt already. I'd spent some months teaching and mentoring too. But I'd never took the time to find a team I'd be happy to spend time with. So I did.

And to be honest, I've felt like a fish in the water.

There's been so much to learn that my curiosity has always been satisfied. I've been able to work in a calm environment, to feel safe enough to ask stupid questions ALL OF THE TIME, and to enjoy autonomy and flexibility.

The results:
- A learning curve steeper than most startups' growth trajectory while being able to disconnect at the end of each day.
- I've been able to do my best work and create substantial value for the company I work for (I can't go into any specifics obviously, but let's say <mark>it's A LOT compared to the market's perceived value of a junior developer</mark>).

So, everybody's happy.

### Some newbie vanity metrics

- I've opened \~170 pull requests.
- These amount to \~450 commits.
- I've also added \~110 tests (which is 🙌).

### What was really really cool

One of the biggest challenges was to wrap my head around an unfamiliar market (real estate) and an existing codebase, all the while getting comfortable with the basics of Ruby and Rails.

After three months on the job, I stopped checking the documentation every other minute. Some things became automatisms: handling migrations, querying data from the database, applying methods on [their proper objects]({{site.baseurl}}/beginners-introduction-to-ruby-classes-objects/), etc.

Getting to know the ropes of the codebase was tougher. I draw the schema and pasted it on my wall on my second day. But as soon as I was done, the team ran several migrations in production and my drawing was obsolete. Some parts of the codebase were easy to grasp. Some others, not so much. For instance, we have some controllers handling multiple steps with [Wicked](https://github.com/zombocom/wicked). And boy, those still give me the creeps every time I come near 'em. One of the solutions I've found: when I start working on some unfamiliar part of the codebase, I ask my senior teammates for a walk-through. What does it do? What's the necessary setup? What are the flows? What the hell is this method doing? This helps a lot.

After nine months of writing tests, I now feel I'm getting my head around the basics of RSpec. I can draft a test suite in no time, and I can tell things apart more easily. More importantly, I now leverage tests to dig out bugs or code smells beforehand. And that, friend, is one hell of a feeling.

### Some features I'm proud of

Real estate agents write up an advert for each property they're mandated to sell. Then, they copy and paste this advert across 40-ish different websites (for the French market). Each of these websites targets specific buyers.

Imagine that, having to copy and paste forty times (!) the same advert. So much time, so many potential errors.

Before the summer, I started working on a cool feature that would allow our agents - we call them _experts_ - to dispatch their advert on all those portals, with a single click. It was my first _big feature_ and I had the chance to get both autonomy and help to nail it.

A few of the things it involved: integrating with a third-party service through their API, building XML files from our data, [manipulating tempfiles]({{site.baseurl}}/working-with-tempfiles/) (~~I'll write a short post at some point~~ [update: it's live!]), [building]({{site.baseurl}}/transactions-in-rails/) and [testing several railway-oriented business transactions with Rspec]({{site.baseurl}}/testing-business-transactions-in-rails/), etc. This was no small stuff. But the feature has been cheered by the team, and <mark>it has saved hundreds of hours so far</mark>.

Let's get back in our real estate agents' shoes.

Once you've published your advert on 40-something websites, what happens? Well, people try and contact you. So you're left to your own devices to gather all your potential buyers' details: scribbled notes of pieces of paper, emails, multiple websites' interface, etc.

One of the other cool features I worked on was to create an MVP-ish CRM where all potential buyers' details are now gathered automatically. All in one place, not all over the place (as our Basecamp friends would say). It's now super easy for our team to know what's what and to deliver the best experience to our customers.

This, too, was intense yet rewarding: <mark>a huge adoption by the team, no more missed opportunities and less mental load</mark>. Also, I got to hunt a bug for several days which was both really frustrating and fun. <mark>This is where I learned that you should neither trust a user's input nor make assumptions on your database integrity.</mark>

There were a lot of other things this year: APIs, webhooks, performance optimisation, logs management, etc.

We'll see what 2020 has in store.

That's it for me folks!

Noticed something? [Ping me on Twitter](https://twitter.com/mercier_remi) or [create an issue on GitHub](https://github.com/merciremi/remicodes/issues/new).

Cheers,

Rémi
