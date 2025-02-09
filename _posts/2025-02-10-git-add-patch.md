---
layout: post
title: How I use git add --patch for reviewing my work
excerpt: "When working on features, I strive to preserve my flow, which means, that after a few hours, I'll have a bunch of untracked files waiting for me in git. I use `git add --patch` to effectively bundling my work into separate commits."
date: 2025-02-10
permalink: /git-add-patch/
category: other
cover_image: "media/2025/02/how-to-use-git-add-patch-remi-mercier.png"
---

When working on features, I strive to preserve my flow, which means, that after a few hours, I'll have a bunch of untracked files waiting for me in git. Since I like to make atomic changes, I need to remember which files go hand-in-hand to bundle them up in meaningful separate commits.

## `git add --patch` to the rescue

You probably already use `git add` to add files to your staging area. Well, `git add --patch` adds a few fancies to this process:
- Interactively review your additions.
- Select those you want to add to your staging area.
- Control the granularity with which you can do the above.

Let's take this website repository as an example (#meta)!

First, let's run `git status`.

{% highlight zsh %}
  merciremi/remicodes gh-pages → git status
  On branch gh-pages
  Your branch is up to date with 'origin/gh-pages'.

  Untracked files:
    (use "git add <file>..." to include in what will be committed)
  	_drafts/add-postgres-full-text-search-to-rails-app.md
  	_drafts/git-patch-draft.md
  	_drafts/speed-up-rspec-suite-by-understanding-lifecycles.md
  	_notes/

  nothing added to commit but untracked files present (use "git add" to track)
{% endhighlight %}

Here's a breakdown of the main git-related information:
- `On branch gh-pages` is pretty self-explanatory.
- `Your branch is up to date with 'origin/gh-pages'.` means that my local branch is up to date with my remote branch.
- `Untracked files` represents the working directory (i.e. my local changes).

I've just created `_drafts/git-patch-draft.md` and I want git to start tracking it. What happens if I run `git add --patch` on it?

{% highlight zsh %}
  merciremi/remicodes gh-pages → git add --patch _drafts/git-patch-draft.md
  No changes.
{% endhighlight %}

`git add --patch` needs a tracked file to work as intended. Trying to patch a file not tracked yet will result in a `No changes` message. It's pretty logical when you think about the _semantic_ used by git. If you do a bit of REST, you know you can only patch an existing resource[^1].

So, I'll add my draft to my staging area.

{% highlight zsh %}
  merciremi/remicodes gh-pages → git add _drafts/git-patch-draft.md
  merciremi/remicodes gh-pages → git status
  On branch gh-pages
  Your branch is up to date with 'origin/gh-pages'.

  Changes to be committed:
    (use "git restore --staged <file>..." to unstage)
  	new file:   _drafts/git-patch-draft.md

  Untracked files:
    (use "git add <file>..." to include in what will be committed)
  	_drafts/add-postgres-full-text-search-to-rails-app.md
  	_drafts/speed-up-rspec-suite-by-understanding-lifecycles.md
  	_notes/
{% endhighlight %}

On top of the previous information, I now have:
- `Changes to be committed` which represents the [staging area](https://git-scm.com/about/staging-area){:target="_blank"} (a.k.a the place where we bundle our changes before committing them).

Now that git tracks my draft, I'll be able to patch every changes I make. There is a lot of stuff to parse, though:

{% highlight zsh %}
  merciremi/remicodes gh-pages → git add --patch _drafts/git-patch-draft.md

  diff --git a/_drafts/git-patch-draft.md b/_drafts/git-patch-draft.md
  index 0e1f8c8..389d061 100644
  --- a/_drafts/git-patch-draft.md
  +++ b/_drafts/git-patch-draft.md
  @@ -7,3 +7,83 @@ permalink: git-add-patch

  category: git
  cover_image:
  ---
  +
  +   When working on features, I strive to preserve my flow. Which means, that after a few hours, I'll have a bunch of untracked files waiting for me in git. Since I'd rather make atomic changes, I now need to remember which files go hand-in-hand in order to bundle them up in meaningful separate commits.
  +
  +   ## `git add --patch` to the rescue
  +
  +   May be you already use `git add` to add files to your staging area. Well `git add --patch` adds a few fancies to the process:
  +   - Interactively review your additions.
  +   - Select those you want to add to your staging area.
  +   - Control the granularity with which you can do the aboves.
  +
  +   Let's take this website repository as an example (#meta)!
  +
  +   First, let's run `git status` to where we at.

  (1/2) Stage this hunk [y,n,q,a,d,e,p,?]?
{% endhighlight %}

Let's explain default git metadata first:
- `diff --git a/_drafts/git-patch-draft.md b/_drafts/git-patch-draft.md` represents which file the current diff is for. `a/` is the file before changes, `b/` is the file after changes. Why? I could rename a file, and git knows how to track this type of change.
- `index 0e1f8c8..389d061` are the SHA-1 hashes of the file [^2].
- `100644` is the file mode. Here, it's a standard, non-executable file.
- `@@ -7,3 +7,83 @@` is the hunk header: it represents the line where the changes occur for each version of the file and how many lines are affected.
- Lines starting with `-` are the lines removed from your file.
- Lines starting with `+` are the lines added from your file.
- `(1/2) Stage this hunk [y,n,q,a,d,e,p,?]?` gives you options on how to handle the current hunk.

Before we move on to the various staging strategies, let's finish our yak-shaving with one question:

> What is a hunk?

A hunk is simply a slice of the changes you're reviewing. Hunks are scoped logically. In a Ruby file, git will split the changes so you can review them method by method, for instance. In my example here, git treats markdown as a monolithic chunk and sends me the whole file to review (not the most useful use of the feature, I agree.)

## Staging strategies

Git gives you a handful of options when adding hunks to the staging area:
- `y`: stage this hunk
- `n`: do not stage this hunk
- `q/quit`: do not stage this hunk and leave the patching process
- `a`: stage this hunk and all later hunks in the file
- `d`: do not stage this hunk or any of the later hunks in the file
- `e`: open the default editor and manually edit the current hunk
- `p`: print the current hunk
- `?`: display help

Git adds a couple of extra options for specific types of hunks:
- `s`: split this hunk into smaller hunks
- `/`: takes a regex as an argument and will search through the whole file for a match

### My personal favourites

When adding brand new files, I know I don't need to split changes into hunks, so I'll just do a quick `git add file_path`.

For existing files, git is pretty darn smart when splitting files into hunks. Most of the time, each hunk will be scoped to a method change, and I just accept them with `y` or reject them with `n`.

Currently, I work on a product whose translations live on a 3-rd party service. When I add translation keys, I add them to that service and pull the translations into my branch through a rake task. Most of these locales-as-a-service applications do not allow you to pull a subset of keys. So you end up fetching every translation added since your last pull.

For this scenario, I use the regex option with my key as a literal pattern: `/my_locale_key:`. Git finds a match and asks me what I want to do with it. I add it with `y`, then git keeps going through the file for the remaining hunks. Oftentimes, I'll add a hunk with `/` and then opt out of the file with `d`.

{% highlight zsh %}
  merciremi/some_app main → git add --patch config/locales.en.yml

  diff --git a/config/locales.en.yml b/config/locales.en.yml
  index 0e1f8c8..389d061 100644
  --- a/config/locales.en.yml
  +++ b/config/locales.en.yml
  @@ -3,3 +3,26 @@

  en:
  exceptions:
    book_errors:
      already_purchased: You already purchased this book.
      not_purchasable: This book cannot be purchased.
+     country_availability: This book is not available in your country.
+     empty_epub_slicing_metadata: Empty book slicing metadata
      epub_level_not_supported: The request book is not compatible with your device.
      audio_level_not_supported: The request book is not compatible with your device.
      geo_restrictions: Your geographic location does not allow you to access this book.
+     invalid_epub_slicing_status: The book slicing failed
+     no_editor: You cannot create a book without specifying its editor.

  (1/5) Stage this hunk [y,n,q,a,d,e,p,?]? /unknown_language:
  @@ -13,7 +14,6 @@ en:

    level_not_supported: The request book is not compatible with your device.
+   unknown_language: "Book language is unknown: %{language}"
    user_not_premium: The book is only available for premium user.
    visibility: "This book is not visible (current state: %{state})."
  (1/5) Stage this hunk [y,n,q,a,d,e,p,?]? y
    category_not_supported: Category does not contain any book readable on your device.
+   category_geo_restrictions: Category does not contain any books available in your geographic location.
    category_not_in_catalog: Category does not contain any book from your catalog.

  (2/5) Stage this hunk [y,n,q,a,d,e,p,?]? d
{% endhighlight %}

Some hunks you can split into smaller hunks with `s`. But this option depends on the hunk. A markdown file seems to be an indiscriminate blob for git, so there is no split option. A Ruby file with extensive changes can often be split.

One last option I only use - when changes are too cumbersome to parse and validate/invalidate in my terminal - is the edit option (`e`). `e` opens your default terminal (defined in your `~/.gitconfig` file) and allows you to manipulate which line you want to add, keep, or remove.

All in all, `git add --patch` is a great tool for reviewing your work, quickly bundling your changes into atomic commits, and safeguarding your adding changes blindly.

{% include signature.html %}

[^1]: When you `git add`, git adds the file to the `objects` folder ([read more about how git works under the hood](https://medium.com/@gurayy/how-git-really-works-part-1-how-git-add-works-under-the-hood-2c6221c48b91){:target="_blank"})

[^2]: A SHA-1 hash (Secure Hash Algorithm 1) is a cryptographic hash function that takes an input (like a file or text) and produces a 40-character hexadecimal string (a unique fingerprint of the input).
