---
layout: post
title: A beginners guide to upgrading Ruby on Rails
---

"We need to upgrade Ruby on Rails". I've seen senior developers flinched at those words.

Today, I had the chance to migrate one app from Rails 5.2 to 6.0 (so, a major upgrade). I've kept some notes I'd like to share with you.

Let's see how we can approach this for the first time.

## Read the guide first

Rails has an [offical guide](https://edgeguides.rubyonrails.org/upgrading_ruby_on_rails.html){:target="\_blank"} to help us upgrade our apps from one version of Rails to a newer one.

The first advices are, in my opinion, underrated and golden. Before comitting the time to upgrade Rails, we should:
- have good reasons to do it because it can be no small task
- a good test coverage because there's a lot of things we'll change without grasping the full effect of these changes. So tests give us a (false?) sense of confidence.

## Basic process

- change Rails version in our Gemfile
- bundle update
- fix dependencies: usually update them

```
Bundler could not find compatible versions for gem "railties":
  In Gemfile:
    devise (~> 4.4.0) was resolved to 4.4.3, which depends on
      railties (>= 4.1.0, < 6.0)

    rails (~> 6.0.4) was resolved to 6.0.4, which depends on
      railties (= 6.0.4)

```

Means that my devise gem is capped at the latest minor version of 4. And its dependy on railties is not compatible with the latest version of Rails. I need to update devise to a higher version.

Every time, bundle update.

Then fix every depency as they arise. The next i had.

```
Bundler could not find compatible versions for gem "actionmailer":
  In Gemfile:
    premailer-rails (= 1.9.7) was resolved to 1.9.7, which depends on
      actionmailer (>= 3, < 6)

    rails (~> 6.0.4) was resolved to 6.0.4, which depends on
      actionmailer (= 6.0.4)


```

I had to upgrade premailer-rails.

One every depency are done. git add and git commit for this part of the upgrade.

do the same with package.json if you use javascript.

## App update

rails comes with the `rails app:update` command.

This will show you all the config files that Rails want to update. Use `d` to show the diff. What's printe din white in zsh is the same thging, what's red is what rails want to delete, green to be added. Be careful, sometimes, you want to keep your own configuration, sometimes, you want to add stuff from the new config.

Some things are obvious : comments for config. Some are less obvious : your own settings for configs. If you don't know, best to ask someone in the team about the current changes. Best to be conservative. But good to keep as much of the new information to stay in line with Rails default.

An example : rails wanted to delete all my routes file and replace it with the default comment when the file is empty. Nah!

```
bin/rails app:update
DEPRECATION WARNING: Single arity template handlers are deprecated. Template handlers must
now accept two parameters, the view object and the source for the view object.
Change:
  >> PrawnRails::Renderer.call(template)
To:
  >> PrawnRails::Renderer.call(template, source)
 (called from <main> at /Users/remi/code/merciremi/youboox-web/config/application.rb:11)
   identical  config/boot.rb
       exist  config
    conflict  config/routes.rb
Overwrite /Users/remi/code/merciremi/youboox-web/config/routes.rb? (enter "h" for help) [Ynaqdhm] d
  Rails.application.routes.draw do
-   # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
+   # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
-


```

What I did was add the updated comments like `# For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html` in my files a la mano. And replied `n` to the prompt.

Sometimes is Rails that changes the way it handle something
```
conflict  config/spring.rb
Overwrite /Users/remi/code/merciremi/youboox-web/config/spring.rb? (enter "h" for help) [Ynaqdhm] d
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


```
in that case, i've kept the new rails stuff with `y` in the prompt.

This is long and tedious. We need to stay super focused. I actually missed a couple of changes in my puma configuration file while doing it.

once we (a peu près) confident about the changes in our config files, git add git commit.

## Run tests

This is the first time we run tests. Start with models, then controllers/requests, then the others. Some upgrade introduce backward compatibility issue, changes on how things work. So, fix your tests.

have a ```LoadError:
       Unable to autoload constant``` ? Try `bin/spring stop` then rerun the tests.

At that point you might see a lot of deprecation warnings. Don't worry, we'll do them later.

Once tests are done, git add git commit.

## Deprecation warnings

Now we treat deprecation warnings introduced by our upgrade. Sometomes it's a method name that changes, sometimes, we need to upgrade yet another gem.

After fixing one kind of deprecation waring, git add git commit. Then move on to the next. A few things I had : `update_attributes`, `shouldamatchers`

```
DEPRECATION WARNING: Single arity template handlers are deprecated. Template handlers must
now accept two parameters, the view object and the source for the view object.
Change:
  >> PrawnRails::Renderer.call(template)

```

For each deprecation warning unexpected problems can arise. This is why upgrading can be so daunting. But when a problem comes from a gem, it's a good thing to go and read the changelog of the gem so we can identify what changed in the gem that breaks our code.

Sometime, when you upgrade a gem to remove a deprecation warning, a lot of test brake afterward. It's shitty but it's normal. Shouldamatcher had us on edge for a couple hours. We realized that that validation of uniqueness scoped to several stuff was not suported anymore (but we moved from v2 to v5 in one go, so heay!). I had t orewrite all tests without the syntax by shouldamatchers.

## Configure Framework Defaults

This I did last which was a error (even if nothing bad happened). But since Rails 5, the `app update` command generates a file with the new defaults config for the app. You need to flip them one by one and check that your tests pass.

Did I mention that we basically need to run our tests everytime we change the slightest thing? :D



One of tne specific i did with rails 6 as to change the autoloading strategy to zeitwerk. A lot of things had to be changed for this:
- Class name infered from names of files with inflections
- configuration about autoreloading and stale objects in tests (did  you know that when you compare to User.class, if you change and reload the first one it's not the same anymore because of the object_id?)

```
irb> joe = User.new
irb> reload!
irb> alice = User.new
irb> joe.class == alice.class
=> false

```

😱

Zeitwerk comes with a cool command `rails zeitwerk:check`! it gives you the next things that needs fixing!once everything is good with zeitwerk, time to... run your tests once again!

This part was the trickiest because the range of the things you have to change is enormous. Sometimes, you change things, it works and you don't really know why. 🤷‍♂️

## Last checks

Check your Rails guide if you missed anything relevant for you (for instance, we don't use actioncable, so that part of the guide was of no interest for us). Run your specs one last time. Then run your linter. Run a rails console. run your server and see what's what for real. Then you're done.

## the scope

Focus on making tests green. Don't refactor things now. You'll do it later.

Thanks Jeremy!
