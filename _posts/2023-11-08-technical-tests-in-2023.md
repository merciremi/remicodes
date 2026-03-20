---
layout: post
title: "Technical tests in 2023: were they any good?"
excerpt: "As I'm reaching the end of this recruiting cycle, I wanted to reflect on the recruiting processes I've completed. Some were good, some not so much."
date: 2023-11-08
permalink: /technical-tests-in-2023/
category: career
cover_image: '/media/2023/11/remi-mercier-technical-tests-in-2023.png'
---

As I'm reaching the end of this recruiting cycle, I wanted to reflect on the recruiting processes I've completed. And yes, I've found a good team and product I'll join in mid-November!

__First, some data:__

In early September, I made the first phone calls to friends and acquaintances to talk about the company they were working with. I formally applied to four companies within this first week. I added a fifth process a week later.

Six weeks later, I accepted one offer, stopped one recruitment process early, got two NOs after completing all stages, and got a NO from an automatic email sent on a Sunday morning (🤔).

All in all, I did:

- Two (short) cover letters.
- Four initial screenings: two with HR representatives and two with technical people.
- Two one-hour technical tests followed by one-hour conversations.
- One three-day home assignement, followed by one-hour ~~conversation~~ poking holes at my work.
- One (paid) day of pair programming on the real codebase.
- Two one-hour calls on values, challenges, etc...
- Two reference checks.

I found all processes to lean on the lengthy side. I understand the need to mitigate the risks. I've been on the other side of the [hiring table]({{site.baseurl}}/series/career/). As a candidate, however, this seemed overboard. At the same time, I gained valuable insights into companies: organizational challenges, changes of priorities, managing technical debt versus deploying new features, etc.

## Technical tests: the good, the bad and the ugly

Let's talk more about the technical challenges _per se_. I had a surprising amount of fun doing them. However, some proved more efficient than others. Let's rate them as if we were all watching Next in Fashion together.

### ★★★ Review a pull request (30 minutes) and a discussion (20 minutes)

This was (by far!) my favorite format. I digged the smaller scope and the time constraint, even if I tend to take extra time when writing feedback to someone.

I liked the breadth of topics this test covered:

  - Technical knowledge: You need to identify technical problems quickly - from N+1 queries to tight coupling, from methods length to database throttling.
  - Tooling: In my comments, I flexed some basic tooling skills like [benchmarking code]({{site.baseurl}}/wtf-time-complexity/) snippets.
  - Communication: In 30 minutes, you don't have much time to think about how well you communicate. That's why I like to use [conventional comments](https://conventionalcomments.org/){:target="\_blank"}. **Conventional comments** give me a better structure for conveying __what needs to be said__ without forgetting __how it should be said__.
  - Methodology: The pull request included bits of code unused anywhere else. I solved this using two strategies: asking for context and opening the conversation around the potential challenges these bits implied. Often, we lack information. Asking for it allows us to make informed decisions.

### ★★☆ Build a small feature with someone as tech support (45 minutes) and a conversation (45 minutes)

It was a first for me, and it felt somewhat familiar (in a slightly boring yet comforting way).

I liked the mix of the _possible_ synchronicity of hopping on a call and the asynchronicity of doing the work on my own. The experience approximated my regular day-to-day remote routine.

After building the feature, my interlocutor and I hashed out my solution, the stuff I had noticed in the code (mostly "Why is this controller so full of stuff?").

I've found it's a good way to check how someone will work in a remote-first, asynchronous environment. The only downside is that you're missing out on the thought process. I also like the fact you can evaluate how someone communicates about their work and if they have an eye for noticing things to better the codebase.

TL;DR: Short, looking like a regular day, and to the point.

### ★★★ Pair on a real issue on a real codebase (one full day, paid)

I thought I had read about this kind of test on Basecamp's blog years ago, but I can't find the post again[^1]. I remember being "Voilà!" (which would translate as "There!").

And it's true, it makes for a great test.

It gives you enough room to solve something meaningful, albeit on a scope small enough to fit in one day. You get to know the people you'll be working with a little better, in the good moments and the bad ones. I mean, you learn a lot about someone when moving deep in the bowels of a defunct gem as you're [debugging an obscure error message]({{site.baseurl}}/pry-byebug-intermediate/).

It's time-consuming and a bit stressful to spend the whole day pair-programming with someone you barely know. But as the company pays you, it's easier to trick the mind into thinking it's just a consulting gig.

The two downsides I see:
- It's time-consuming for both the candidate and the company, so it's best to keep this test for a later stage.
- The pair programming nature of the test can be stressful to some people. Companies might lose potential great candidates.

### ★★☆ System design live interview (45 minutes)

Live interviews on tough topics are intimidating. I'm an ambivert- half-extrovert, half-introvert - so I can only sustain sweating out in front of several people for a time.

The people I talked to were extremely nice, so I _had_ a lovely time baring my thought process in public.

This interview was not about coding _per se_ but about:
- Showing how you think your way through an assignment.
- Taking a brief, asking questions, gathering information.
- Outlining the architecture for the feature.
- Preemptively digging out technical challenges.

I found this test to be slightly too time-constrained. I would have loved to dig deeper, especially on topics I was unfamiliar with.

I also realized the topic - building a URL shortener - is a classic of system design interviews. It's also immensely more complex than what we discussed.

Funnily enough, the technical test that got me my first job as a programmer - five years ago - was building a URL shortener, too. So, I have a bit of a sweet spot for this test. And I realized how much I had learned since then.

### ★☆☆ Build and host a full application (within a 7-day period)

Usually, I red-flag companies asking for fully-fledged applications as a technical test.

This time, though, I gave it a go as I needed to stretch my legs after a few months of not programming.

I've done several of these tests over the years, and my TL;DR is that they suck.

Fully-fledged apps are:
- Time-consuming.
- Too broad for being a useful basis for meaningful conversation.
- Evaluation is always based on the interviewer's sentiments rather than on a factual analysis grid.

This October, I had to build an app that would take ingredients as input and return recipes based on these ingredients. To handle the full-text search I needed, I followed the initial requirement that the app should be "as simple as possible."

I decided to leverage `pg_search`, a gem that does just that. What I discovered during the follow-up conversation was that the **hidden requirement** was that the team wanted a pure SQL implementation for a full-text search. Why not say it?

This ties in with what most technical tests lack.

## Where are your evaluation grids?

Too often, companies rely solely on the feelings of their team.

> Did this candidate feel like a good fit to you?

Whether they did or not, the real question is: why? How do you know your unconscious biases are not clouding your judgment?

<mark>Feelings are a poor substitute for an evaluation grid.</mark>

There is an extensive literature about the correlation between __fit__ and __homogeneous__ environment (in computer-related fields: male, white, able, upper-middle-class).

Here's a proposal:
- Ask yourself about your business needs.
- Build an evaluation grid that allows you to verify those needs are met.
- Build a test constraints that allow you to match your evaluation grid.
- Build a few variations of your technical test. Have at least two variations: a synchronous test and an asynchronous one.
- And stick to your grid!

As an IC, I need to be able to communicate with people. But I can communicate well enough to do my job through messaging or on a video call. I do not always need to talk to people. So why should I necessarily pass synchronous tests? Am I applying to be an Engineering Manager? Sure, being able to talk to people live seems like a pertinent criteria.

Some candidates will be extroverts, and some will be introverts. Having various paths for your candidates to choose from will broaden your ability to find good people.

It's a fascinating topic because its core lies in the power dynamic between companies and candidates, the usefulness of this power dynamic versus the needs of the business. But it'll make for another post.

<img src="{{ site.baseurl }}/media/2023/11/remi-mercier-how-to-get-a-job-joke.png" alt="a screenshot of a joke I made about how ridiculously long hiring processes are">

Cheers,

Rémi - [@remi@ruby.social](https://ruby.social/@remi)

[^1]: I see that Basecamp now proposes building a scoped feature, with an estimated 5-hour test spread over a full week.
