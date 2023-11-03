---
layout: post
title: How to wrap your head around a new codebase
date: 2020-06-12
excerpt: "For the last eighteen months, I've spent my time trying to understand bits of code I'd never seen before. Eighteen months later, I still don't know every corner of the codebase, but what I do know, is how to get efficiently familiar with new parts of a codebase."
category: 'other'
permalink: /wrap-your-head-around-new-codebase/
---

For the last eighteen months, I've spent my time trying to understand bits of code I'd never seen before. Eighteen months later, I still don't know every corner of this reasonably sized codebase (\~300_000 lines of code). But what I do know is how to get familiar with new parts of it.

So today, I'll try and give you some tips about an understated skill: how to wrap your head around a new (part of the) codebase.

## What you probably shouldn't do

<strong>Don't. Be. Stubborn.</strong>

That part, I've struggled with a lot. Stubbornness impeded the order of magnitude of my output for months.

I would try to understand the code alone and knock my head on my keyboard for hours on end. Man, my ego REALLY got into the way of my learning curve.

I had that same bad habit when learning Ruby. I would get to the point of self-loathing before asking teachers for help.

When I finally got to teach Ruby to new developers, I saw this was a common mistake. So, ask for help early, ask for help fast.

Once I identified that habit and worked on improving it, both my learning curve and my output skyrocketed.

## Some things you could do
The end goal for you is to get how things work, faster and more comprehensively, so you can work on improving the codebase.

### What you can do on our own
- Read the code you need to work with.
- If some things aren't clear, take notes. Things you don't understand can be very different: Is a whole class unclear? Is it just the syntax? Did a senior developer get overboard with their abstractions?
- Try and break down what's happening: isolate each logical part, how do they interact with each other, and get a sense of the flow.
- If you've identified some gems or patterns: go and read the relevant documentation.

Of course, you won't approach a whole new codebase the same way you approach a specific part of it. The granularity of what you want to do changes whether you're starting a new job or tackling a feature.

If after these steps you still feel unsure about where you should start, take a break. This is the tipping point where you'll fall into stubborn-mode.

Do you feel you've started to pull on a thread but still can't quite wrap your head around it - "I'm almost there."? Take a break. This is a tipping point too.

Move on to the next stage.

### What you can't do on your own
Note that depending on your situation, some of these tips cannot be copied and pasted. You'll sometimes need to adapt.

- Go and ask the person responsible for the code. With them, go through the following:
  - Explain your research, what you understood, and what's still unclear.
  - Ask for a walkthrough: what's the main goal underlying that part of the codebase, what are the interactions, why did they code things that way, etc.
  - Get a proper set up: do you need to create test accounts with 3rd-party software? Are there any credentials you'll need to do your work? Should you run any tasks?
  - As your understanding grows, dig deeper for edge cases. Don't shy away from tough questions. Your work is to improve the codebase, not stroke your colleagues' ego.
- If the person responsible for the code is not here, go to the person who has the highest seniority-mentorship ability ratio. If that one is not available, go to the next person with the second highest ratio.

### Some additional steps
- Draw things of paper: database interaction, data flow, user flow, etc...
- Check the data stored in the database: databases aren't as clean as they ought to be, so check the kind of values you have there. Look out for `nil` values in email columns, that kind of thing.

That's it!

Wanna add something to the list? [Submit your tip on GitHub](https://github.com/merciremi/remicodes/issues/new){:target="\_blank"}.

Cheers,

Rémi - [@remi@ruby.social](https://ruby.social/@remi){:target="\_blank"}
