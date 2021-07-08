---
layout: post
title: 'Building large features: my process for branches, requests and reviews'
excerpt: ""
---

During my first couple of years as a developer, I didn't have much of a process for large features.

I would start a feature branch from the main branch, work on my feature for weeks, and open up a pull request. I would subject my coworkers to grueling thousand-lines-of-code reviews without thinking about it twice.

At the time, that seemed normal. Everyone was doing it.

But no more!

Now that I regularly work on large features, I've found a process that suits my needs (and my teammates'). It helps me keep in touch with the main branch. Code reviews are easier for my coworkers. And it's easier for me to maintain over time.

This process was born from three constraints:
- Break down large features into smaller chunks to make reviews easier.
- Don't commit code to production that is not used right away.
- Make do with reviews (and subsequent modifications) that can happen over a few days.

For clarity's sake, I'll use the word `card` to describe an information entity where you write a piece of specification. Think Trello cards, Jira issues, Post-Its, whatever tickles your fancy.

## Step 01: The way I specify == the way I code

My brain has a mind of its own.

If I write my feature specifications in one card, I'll end up writing this feature in one go, then submit a massive pull request.

If I centralize all my specifications in one parent card, then isolate each conceptual chunk into its own child card, I'll create a dedicated branch and a (well-sized) pull request for each child card.

It's visual, really.

<!-- graph -->

One side benefit of splitting your feature into conceptual chunks is that you need to take some extra time to think about what needs to be done. You can organize your work and know that first, you need to code some endpoints, then move on to the views, then wrap up with some data migration.

The way you split your specifications is the way you'll work through your feature. There's no need for your favorite to-do list tool anymore. <mark>Your specifications are your to-do list.</mark>

<!-- graph w/ epic and sub tickets + branches + pull requests -->

Ok, time to code that feature!

## Step 02: Create the parent branch

As a title, I pick the ID of the parent card and append a descriptive name to it.

Make the naming suits your need. I use a number and a name because I work with an issue tracking software that heavily leans on card ids. The (most) important bit is the descriptive naming.

{% highlight zsh %}
  ➜  my-project git:(main) git pull origin main
  ➜  my-project git:(main) git checkout -b 313-my-feature-parent-branch

  Switched to a new branch '313-my-feature-parent-branch'
{% endhighlight %}

Now, `313-my-feature-parent-branch` will serve as a basis for all my child branches.

{% highlight git %}
                A' --- B' --- C' parent branch
               /
  X --- Y --- Z    main
{% endhighlight %}

<!-- graph of parent branch from main -->

Let's push my parent branch onto my remote repository manager[^1].

## Step 03: Open a pull request for the parent branch

Now that my code is online, I open a pull request for my parent branch.

Here's my set-up:
- The parent pull request has __a descriptive title__ - usually the name of my parent branch minus the number.
- Prefix the title of the parent pull request with `Draft`. It shouldn't be reviewed or merged.
- The parent pull request targets the `main` branch.
- The description of the parent pull request links to the parent card. Also, I usually add a link to each child pull request as I open them.

The parent pull request shows no difference with the `main` branch. It's perfectly normal. Right now, my parent pull request is an empty shell until my first child pull request is approved and merged in it. Since my parent branch is blank, I'm not submitting for reviews (yet).

Let's code our first code chunk!

## Step 04: Create the first child branch

Now, I can open my first child branch from my parent branch (`313-my-feature-parent-branch`).

{% highlight zsh %}
  ➜  my-project git:(313-my-feature-parent-branch) git checkout -b 314-my-feature-add-models

  Switched to a new branch '314-my-feature-add-models'
{% endhighlight %}

Once I've coded this part of my feature, I push my first child branch - `314-my-feature-add-models` - on my remote repository.

## Step 05: Open a pull request for the first child branch

Ok, now the code for my first child pull request is live on my remote repository manager.

I'll open a pull request for my first child branch:
- The child pull request has __a descriptive title__ - usually the name of my child branch minus the number.
- The child pull request __targets the parent branch__.
- The description of the child pull request specifies its status - `⚠️ This is a child-pull request of 313-my-feature-parent-branch` - and links to the parent branch.
- The description of the child pull request also specifies if the branch is forked from the parent branch or from another branch (we'll see why later).

<!-- graph -->

## Step 06: Submit the first child pull request

Now, my parent pull request and my first child pull request are open.

As I said, the parent pull request shows no difference with the `main` branch. There's no point in submitting it now.

Instead, I'll submit my first child pull request to my coworkers. Here's how I do it:
- Share a link to the child pull request.
- Share the number of added and removed lines: `+313 -23`. People can parse this diff count and decide if they can review it now or later.
- Explain in one line what the child pull request does and specify it's a child pull request (and from which branch it's forked).

{% highlight zsh %}
  a-link-to-my-pull-request *313 -23*
  Adds the ad hoc models for my large feature
  ⚠️ This is a child-pull request of 313-my-feature-parent-branch + forked from <branch-name>
{% endhighlight %}

This is mostly inspired by [Thoughtbot](https://thoughtbot.com/blog/slack-emojis-for-pr-reviews){:target="\_blank"}.

## Step 07: Handling the following child branches and their respective pull requests

I've written my first chunk of code. I've opened a pull request for my first child card, and I'm waiting for reviews to pour in. Now what?

Now, I have a choice based on my need.

__Option #01__

If my different chunks of code work independently, I can __open a new child branch from the parent branch__. Then I move through steps #04 to #06 again. Disclaimer: this rarely happens.

You usually need the code you wrote earlier to move forward: you need your models to work on your endpoints, and you need your endpoints to work on your views, and so on.

This brings me to option #02.

__Option #02__

If I need the code in my first child branch in my second child branch, I can spawn a new child branch from a previous child branch.

Following up on step #06, instead of starting my second child branch from the `main` branch, I'll start it from the first child branch.

{% highlight zsh %}
  ➜  my-project git:(314-my-feature-add-models) git checkout -b 315-my-feature-add-endpoints

  Switched to a new branch '315-my-feature-add-endpoints'
{% endhighlight %}

<!-- graph with git graph showing branches branching out in cascade -->

Now, I can lean on the work I've done before.

But what happens if my first child branch - `314-my-feature-add-models` - is modified during reviews? It's easy. I can rebase `315-my-feature-add-endpoints` onto the latest `314-my-feature-add-models` to move the starting point where needed. We'll see different scenarios later on.

I usually have a cascading type of branch dependencies. Each new child branch starts from the previous child. It gives me the code and the context I need to move forward in my feature. Plus, it's easier for reviewers.

When I finish a child branch, I push it on my remote repository manager.

<!-- graph with cascade -->

I can picture horrified looks at the words _cascading type of branch dependencies_, but fear not! The benefits of branch dependency offset its potential problems.

Ok, now the code for my following child branches is online.

I'll open a pull request for each child branch:
- The child pull request has __a descriptive title__ - usually the name of my child branch minus the number.
- The child pull request __points to the branch it's forked from__ (either the parent branch, or the previous child branch).
- The child pull request's description specifies its status and links to the parent branch `⚠️ This is a child-pull request of 313-my-feature-parent-branch`.
- The child pull request's description specifies if the branch is forked from the parent branch or the previous child branch.

## Step 08: Getting things together with merge and rebase

Okay. Now is the time to start merging my branches. In real life, this happens progressively, one branch at a time.

The main take-aways are:
- Child pull requests are created in cascade.
- Each child pull request has to be merged into the parent pull request (not into the child pull request it's forked from).

My first child pull request targets the parent pull request. Once the first child pull request is finished and approved, I merge it into the parent pull request.

My second child pull request initially targets the first child pull request. Now that the first child pull request is merged into the parent pull request, I need things.

On my machine: rebase my second child branch onto the latest parent branch (which now contains the code from the first child branch). This rebase changes the basis for my second child branch from the first child branch to the parent branch.

{% highlight zsh %}
  ➜  my-project git:(313-my-feature-parent-branch) git pull origin 313-my-feature-parent-branch
  ➜  my-project git:(313-my-feature-parent-branch) git checkout 315-my-feature-add-endpoints

  Switched to branch '315-my-feature-add-endpoints'

  ➜  my-project git:(315-my-feature-add-endpoints) git rebase --onto 314-my-feature-add-models 313-my-feature-parent-branch

  Successfully rebased and updated refs/heads/315-my-feature-add-endpoints

  ➜  my-project git:(315-my-feature-add-endpoints) git push origin 315-my-feature-add-endpoints
{% endhighlight %}

<!-- graph of git rebase onto -->

Since I changed history by rebasing my second child branch onto my parent branch, I need to `git push --force-with-lease` onto my remote branch.

On my remote repository manager: change the target branch from the first child pull request to the parent pull request.

<!-- graph image of change target branch -->

For each child pull request, repeat step #08.

## Step 09: Submit the parent pull request

All child pull requests are merged into the parent pull request. Now is the time to submit the full feature for a final review.

Usually, reviews for the parent pull request are trivial: typos, tiny fixes, etc.

Once the parent pull request is approved, I merge it into `main`. And I'm done!

Hope you found this interesting! It's not set in stone obviously. But I've found this process to be adequate for me these past few months. Let me know if you have any suggestions to make it better.

Cheers,

Rémi - [@mercier_remi](https://twitter.com/mercier_remi)

[^1]: GitHub or GitLab for instance.
