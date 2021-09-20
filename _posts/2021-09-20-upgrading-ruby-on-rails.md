---
layout: post
title: "Upgrading Ruby on Rails: a beginner's guide"
excerpt: "You're about to upgrade your application to the newest version of Ruby on Rails. And you've never done it before? Fear not! Here's my battle-tested companion to migrating Rails."
date: 2021-09-20
permalink: /upgrading-ruby-on-rails/
category: 'rails'
cover_image: /media/2021/09/upgrading-ruby-on-rails-guide-remi-mercier.png
---

For a long time, upgrading applications to newer versions of Ruby on Rails seemed one of those tasks reserved to experienced developers.

Last July, I migrated an app from Rails 5.2 to Rails 6.0. A major upgrade, then.

While upgrading the application, I wrote notes about the process, the tricky parts, etc. This is what I want to share with you today: a straightforward guide about upgrading Rails for those of you who never did it (yet!).

I was lucky enough to be coached through the whole thing by one of my senior colleagues. So if you have to do it alone, I want this guide to be a companion of sorts to you.

You'll see, it'll be fun!

## Read the official guide first

Rails has an [offical guide](https://edgeguides.rubyonrails.org/upgrading_ruby_on_rails.html){:target="\_blank"} for upgrading Ruby on Rails.

The first chapter - `General Advice` - is full of gold. If you're like me and tend to skim through documentation, don't! Carefully read that chapter and take notes about the important bits. You'll learn about the recommended process, the various commands Rails give, etc.

I particularly liked the first couple of advice:
  - You should have good reasons to upgrade your application because it can be a challenging feat.
  - You should have good test coverage to give you some confidence. Many things will change, and it can be hard to grasp the full effect of these changes.

## The full process I went through

### Upgrading Rails

Here, I'll leave the path of the recommended process to explain what I went through. There's a lot of overlaps with the official guide, though.

- Change the Rails version number in your Gemfile.
- Run `bundle update`.
- Fix dependencies as they arise during the `bundle update` process.

Let's pause for a minute and check a typical error message from a gem:

{% highlight zsh %}
Bundler could not find compatible versions for gem "railties":
  In Gemfile:
    devise (~> 4.4.0) was resolved to 4.4.3, which depends on
      railties (>= 4.1.0, < 6.0)

    rails (~> 6.0.4) was resolved to 6.0.4, which depends on
      railties (= 6.0.4)
{% endhighlight %}

Reading error messages is one fundamental skill in debugging (one I often overlook myself 😅).

What this message tells you is:
  - In your Gemfile, you declared the `devise` gem and locked it to the latest version between `4.4.0` and `< 5.0`.
  - Your version of `devise` needs a version of `railties` between `4.1.0` and the latest minor version before `6.0`.
  - On the other hand, you declared your new version of `rails` and locked it to the latest minor of `6.0.4`[^1].
  - The new version of `rails` needs a specific version of `railties`: the `6.0.4`.

There's a conflict between the version of `railties` your current configuration of `devise` uses and the one your new version of `rails` needs. __You need to upgrade `devise` too.__

To do so, change the Devise version number in your Gemfile, then run `bundle update`.

Rinse and repeat until you don't get any more error messages from your gems.

A side note: How do you chose the version of the gem you should use?

I went through the changelog of each gem and checked for backward-incompatible changes that would break my codebase. If all is safe, you can use the latest stable version. Keep in mind that there's a lot of guessing involved, and you will break things no matter how careful you are.

I didn't need to worry about Javascript packages (I upgraded an API). But if you use Javascript, check the [official guide](https://edgeguides.rubyonrails.org/upgrading_ruby_on_rails.html#moving-between-versions){:target="\_blank"}.

### Update your application

Rails comes with a handy command: `rails app:update`.

The command will output a list of configuration files Rails wants to update.

{% highlight zsh %}
  identical  config/boot.rb
  exist      config
  conflict   config/routes.rb
  Overwrite  ~/config/routes.rb? (enter "h" for help) [Ynaqdhm]

{% endhighlight %}

This is a tricky part. Sometimes, you're okay with Rails updating files, and sometimes you're not.

For each conflict, I've entered the letter `d` to print the **d**ifference in my terminal. The output is color-coded:
  - In white: the lines that won't change.
  - In green: the lines that Rails wants to add.
  - In red: the lines that Rails wants to delete.

You can also see the little `-` and `+` at the beginning of each line that hint about the expected behavior.

{% highlight zsh %}
Overwrite  ~/config/routes.rb? (enter "h" for help) [Ynaqdhm] d
Rails.application.routes.draw do
-   # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
+   # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
-
{% endhighlight %}

You want to be extra careful here. You should know what needs to stay (custom configuration, for example) and what can be changed (configuration comments, typos, etc.).

I chose to be conservative. I've kept everything that looked custom, and I've stayed as close to the new Rails defaults as possible.

I manually updated most of my configuration files. For each file, I would copy/paste the new content, then replied `n` in the terminal prompt (as in `no, do not overwrite`).

Sometimes, standard Rails configuration changes in its implementation:

{% highlight zsh %}
conflict  config/spring.rb
Overwrite ~/config/spring.rb? (enter "h" for help) [Ynaqdhm] d
- %w[
+ Spring.watch(
-   .ruby-version
+   ".ruby-version",
-   .rbenv-vars
+   ".rbenv-vars",
-   tmp/restart.txt
+   "tmp/restart.txt",
-   tmp/caching-dev.txt
+   "tmp/caching-dev.txt"
- ].each { |path| Spring.watch(path) }
+ )
Retrying...
Overwrite ~/config/spring.rb? (enter "h" for help) [Ynaqdhm] y
{% endhighlight %}

In this case, I would allow Rails to overwrite the whole file with `y`.

The process is long and tedious. You'll need to stay focused. I missed a couple of changes in my configuration file for `puma`.

Once you're confident (more or less) about the changes, add your files to GIT and commit them.

### Run your tests

Now, you can run your tests for the first time. Take it slow.

Start with testing your models, then your controllers/requests, then the whole suite.

A major upgrade can introduce breaking changes, so you'll need to fix your code (and your tests) to reflect those changes.

If you see some `LoadError: Unable to autoload constant`, try to run `bin/spring stop` to reload the application.

At this point, you'll see a lot of deprecation warnings. We'll tackle those in a minute.

Once your tests are all green again, add your files to GIT and commit them.

## Handling deprecation warnings

Upgrades also introduce deprecation warnings. These warnings can range from method aliases to gems that need an update.

Every time you fix one deprecation warning, add your modification to GIT and commit. You'd better keep your commit history clean if you need to revert some changes.

Here are a few warnings I had:
  - `DEPRECATION WARNING: update_attributes! is deprecated and will be removed from Rails 6.1`: I had to change those occurences in my code.
  - `DEPRECATION WARNING: Single arity template handlers are deprecated...`: an warning from Prawn, a gem handling PDF creation.

Each deprecation can introduce unexpected problems. Gems rely on other gems. Updating a gem can trigger the update of another one. This is why **upgrading can be so daunting**.

I had a lot of tests failing after I had resolved some deprecation warnings. That sucks, but that's normal.

Do not hesitate to read the changelog of the incriminated gems! The gem `shoulda matchers` had me on my heels for hours, but the changelog of `shoulda matchers` showed me the change that was breaking my tests. I had to rewrite a few tests from the ground up.

### Configure framework defaults

Since Rails 5, the `app update` command generates a file with the new default configuration.

You'll need to uncomment each configuration line gradually check if your tests still pass.

I've found it handy to have all my tests green before toggling on these new configuration defaults.

### A Rails 6 specificity: Zeitwerk

One of the major changes introduced by Rails 6 is the new autolading strategy: [Zeitwerk](https://github.com/fxn/zeitwerk){:target="\_blank"}.

I had to change a few things to make Zeitwerk work:
  - Class names inferred from filenames that contain inflections (i.e. `Csv`, `Ftp`). Some names were capitalized, others were uppercased. I had to homogenize them all.
  - Configuration about auto-reloading in tests.

Hopefully, Zeitwerk comes with a neat command: `rails zeitwerk:check`. It'll give you the next problem that needs fixing. Once you're done with Zeitwerk, run your test one more time!

## Last check

You're almost done!

Check the official Rails guide and verify you didn't miss anything relevant to you.

Run your specs one last time. Then run your linter.

Run a Rails console. Then fire up a server to see if your application behaves the way it should.

All good? Great, you're done!

## Beware of scope creep

While you're fixing things, you'll realize that some objects could do with a little refactoring. Don't!

Focus on making your tests pass. That way, if a new bug pops out, it'll be easier to tell it's because of your migration. You won't have to worry about separating the migration from the refactoring while chasing bugs.

Happy migrating!

Cheers,

Rémi - [@mercier_remi](https://twitter.com/mercier_remi)

[^1]: A small reminder on gem versioning: **0.0.x** is a patch: implementation details, bug fixes, etc..  **0.x.0** is a minor upgrade: new features with backward compatibility. **x.0.0** is a major upgrade: can contain backward incompatible changes.
