---
layout: post
title: "More Minitest::Spec shenanigans"
date: 2025-10-19
tags: [minitest, testing]
permalink: /more-minitest-spec/
excerpt: "While I already covered the basics of `Minitest::Spec`, I forgot to discuss a few aspects of the spec flavor. This post serves as a complement to the previous one and digs a bit deeper into some extra `Minitest::Spec` shenanigans."
---

> ## TL;DR: What else does `Minitest::Spec` offer beyond the basics?
>
> `Minitest::Spec` also exposes `let` and `subject`, and lets you nest `describe` blocks. In my example, combining them lets me run multiple contexts for `user.full_name` while only adjusting the relevant variable.
>
> - `let` and `subject` are lazily evaluated. A `let` isn't re-evaluated within a test example, but it is across test examples, so states won't leak from one `it` case to the next.
> - Minitest has no `let!`, no named `subject`, and no `context`. Use `before do ... end` for objects your test examples don't explicitly reference, and be careful not to nest `describe` blocks too deeply.
> - The `minitest-rails` gem resolves the inheritance shenanigans through typing (`describe User, :model do`) and exposes extra expectations (`must_enqueue_jobs`). In my experience, mailers expectations didn't work out of the box: I had to include `Minitest::Rails::Expectations::ActionMailer` manually.
{:.tldr}

While I already covered [the basics of `Minitest::Spec`](/minitest-spec), I forgot to discuss a few aspects of the spec flavor. This post serves as a complement to the previous one and digs a bit deeper into some extra `Minitest::Spec` shenanigans.

## `let` over `@ivar`

So far, in my setup, I only used ivars to store a `User` accessible in my test examples:

```ruby
  class UserTest < Minitest::Spec
    before do
      @user = User.new(first_name: "buffy", last_name: "summers")
    end

    it "returns the capitalized full name" do
      expect(@user.full_name).must_equal "Buffy Summers"
    end
  end
```


However, `Minitest::Spec` allows me to use the `let(:user)` method instead of `@user`.

If you use RSpec, this will look *very familiar*. If you don't, `let` is a method exposed by the DSL, that allows you to define [memoized instance variables](https://github.com/minitest/minitest/blob/master/lib/minitest/spec.rb#L261){:target="_blank"} accessible in your test examples through accessors.

```ruby
  class UserTest < Minitest::Spec
    let(:user) { User.new(first_name: "buffy", last_name: "summers") }

    it "returns the capitalized full name" do
      expect(user.full_name).must_equal "Buffy Summers"
    end
  end
```


No more `@user`, just a plain `user`, as `Minitest::Spec` `let` adds an accessor to my instance variable.

Also, I no longer need the `before do ... end` block to define variables. I'll only use `before do ... end` if I need a more complex setup:

```ruby
  class UserTest < Minitest::Spec
    let(:user) { User.new(first_name: "buffy", last_name: "summers") }

    before do
      Account.create(user:, tokens: 100)
    end

    it "returns the capitalized full name" do
      expect(user.full_name).must_equal "Buffy Summers"
    end
  end
```


`before do ... end` remains the standard way to create objects not directly used in test examples or to mock objects.

## `let` lazy evaluation

`let` allows Minitest to lazily evaluate the variable when it’s called in a test example. Repeated references of `let` within the same test example won't trigger a re-evaluation. It means Minitest won't run `User.new` multiple times within a test example, but beware of mutations.

If I share a `let` across test examples, the `let` will be re-evaluated, so I don’t need to worry about mutability. States won't leak from one `it` case to the next.

Minitest does not have a `let!` method (like RSpec does). If you need to create objects required for your tests but not explicitly referenced, use the `before do ... end` method.

## Use `subject` over explicit calls to the tested method

`Minitest::Spec` also adds the `subject` method:

```ruby
  class UserTest < Minitest::Spec
    subject { user.full_name }

    let(:user) { User.new(first_name: "buffy", last_name: "summers") }

    it "returns the capitalized full name" do
      expect(subject).must_equal "Buffy Summers"
    end
  end
```


`subject` replaces explicit calls to the method I test. It’s a syntactic convenience that lets me define the *subject* of the current scope. I find it easy to read and handy when dealing with nested contexts:

```ruby
  class UserTest < Minitest::Spec
    describe "#full_name" do
      subject { user.full_name }

      let(:user) { User.new(first_name: "buffy", last_name:) }

      describe "when the user has a one-word last name" do
        let(:last_name) { "summers" }

        it "returns the capitalized full name" do
          expect(subject).must_equal "Buffy Summers"
        end
      end

      describe "when the user has a two-word last name" do
        let(:last_name) { "anne summers" }

        it "does not return the capitalized full name" do
          expect(subject).wont_equal "Buffy Anne Summers"
        end
      end
    end
  end
```


The output for these tests is:

```zsh
  lab/minitest-post → ruby user_test.rb --verbose
  Run options: --verbose --seed 4199

  # Running:

  UserTest2::#full_name::when the user has a one-word last name#test_0001_returns the capitalized full name = 0.00 s = .
  UserTest2::#full_name::when the user has a two-word last name#test_0001_does not return the capitalized full name = 0.00 s = .

  Finished in 0.001340s, 1492.5373 runs/s, 1492.5373 assertions/s.
  2 runs, 2 assertions, 0 failures, 0 errors, 0 skips
```


I like how combining `let` and `subject` lets me run multiple contexts while only adjusting the relevant variable. Since `let`s are lazily evaluated, the initial `let(:user)` can leverage contextual `let`s to instantiate a new `User` with the *ad hoc* local variables.

In plain Minitest, it'd look like this:

```ruby
  class UserTest < Minitest::Test
    def setup
      @user = User.new(first_name: "buffy", last_name: "")
    end

    def test_full_name_with_one_word_last_name
      user.last_name = "summers"
      full_name = user.full_name

      assert_equal "Buffy Summers", full_name
    end

    def test_full_name_with_two_word_last_name
      user.last_name = "anne summers"
      full_name = user.full_name

      refute_equal "Buffy Anne Summers", full_name
    end
  end
```


Since `@user = User.new` is evaluated immediately during setup, it can't take advantage from local variables to create different variations of a `User` on the fly.

Note that there is no named `subject` (aka `subject(:name)`) in Minitest.

An aside: I guess this is one of the reasons Minitest maintainers aren't fond of porting assertions to expectations, because on top of the work, they constantly have to deal with comparison. Which, let's be honest, is a pain in the back.

## Nested `describe` blocks

My last example shows that we can nest `describe` blocks!

There are no `context` in Minitest, but `describe` blocks are still a nicer way to show context granularity compared to plain Minitest nested classes.

Be careful not to nest `describe` block too deeply:

```ruby
  class UserTest < Minitest::Spec
    describe "#full_name" do
      subject { user.full_name }

      describe "when the user has a two-word last name" do
        let(:user) { User.new(first_name: "buffy", last_name:) }
        let(:last_name) { "anne summers" }

        it "does not return the capitalized full name" do
          expect(subject).wont_equal "Buffy Anne Summers"
        end

        describe "when the two-word last name is hyphenated" do
          let(:last_name) { "anne-summers" }

          it "does not return the capitalized full name" do
            expect(subject).wont_equal "Buffy Anne Summers"
          end
        end
      end
    end
  end
```


The output for these tests becomes messy:

```zsh
  lab/minitest-post → ruby user_test.rb --verbose
  Run options: --verbose --seed 50406

  # Running:

  UserTest2::#full_name::when the user has a two-word last name#test_0001_does not return the capitalized full name = 0.00 s = .
  UserTest2::#full_name::when the user has a two-word last name::when the two-word last name is hyphanated#test_0001_does not return the capitalized full name = 0.00 s = .

  Finished in 0.001022s, 1956.9472 runs/s, 1956.9472 assertions/s.
  2 runs, 2 assertions, 0 failures, 0 errors, 0 skips
```


Output legibility is a common critique I hear about Minitest. At the same time, deep nesting makes reading both the files and the output difficult, no matter the framework.

## Solving the tricky inheritance in Rails apps

Eric, from the Ruby on Rails Links Slack, pointed out the [`rails-minitest` gem](https://github.com/minitest/minitest-rails){:target="_blank"}.

Maintained by the same people behind Minitest, `rails-minitest` provides a Minitest integration for Rails applications.

Its benefits include:
- It allows you to explicitly declare the type of class you're testing.
- It resolves [the inheritance shenanigans](/minitest-spec/#:~:text=On%20the%20other%20hand,ApplicationSystemTestCase) through that typing.
- It exposes extra spec-flavored expectations for Rails mailers, jobs, routing, and more.

### How to install `minitest-rails`

The gem follows the versioning of Rails, so I added `gem "minitest-rails", "~> 8.0.0"` to my Gemfile.

`minitest-rails` comes with a handy installation generator - `rails generate minitest:install`- which adds all the necessary files to the application.

Be careful, though, the generator will overwrite your existing setup ([much like the `rails app:update` command](/upgrading-ruby-on-rails/)).

To prevent this, I dry-ran the generator with the `--pretend` flag, which shows all the changes the gem would make: `rails generate minitest:install <APP_PATH> -p`.

The changes in my `application_system_test_case.rb` were minimal:

```zsh
class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  some existing stuff

+  register_spec_type(self) do |desc, *addl|
+    addl.include? :system
+  end

  more existing stuff
end
```


The generator only added `require "minitest/rails"` and some parallelization configuration to my `test_helper.rb`.

### Implicit and explicit test class typing

One of the benefits of the Minitest integration is that it lets me declare which class I'm testing with a `describe` block:

```ruby
  describe User do
    ...
  end
```


Instead of:

```ruby
  class UserTest < Minitest::Spec
    ...
  end
```


I don't need to suffix my test class with `Test` (*ie* `UserTest`) and `minitest-rails` is able to infer the inheritance from the declared class.

I also can cast the type explicitly to help Minitest figure out which kind of test I want to run.

```ruby
  describe User, :model do
    ...
  end
```


`minitest-rails` even lets me declare custom types and custom inheritance, but I haven't (yet) figured out how this works (and where I could use it).

### More spec-flavored expectations

`minitest-rails` also exposes extra expectations, specifically for mailers, jobs or routing. We don't need to choose between expectations for testing models, and assertions for testing jobs. Expectations everywhere!

For instance, Rails' default Minitest syntax would look like this:

```ruby
  assert_enqueued_jobs 1 do
    NotifyUser.perform_later(user_id: user.id)
  end
```


And `minitest-rails` will look like this:

```ruby
  must_enqueue_jobs 1 do
    NotifyUser.perform_later(user_id: user.id)
  end
```


The assertion becomes an expectation, harmonizing the syntax of my tests.

### Yes, but...

While I managed to install the gem and update the declaration of my tests, one thing refused to work out of the box: mailers expectations.

Consider this test:

```ruby
  describe NotifyUserJob, :job do
    let(:user) { User.new(first_name: "buffy", last_name: "summers") }

    it "sends a notification email to the user" do
      must_enqueue_email_with UserMailer, :notify, args: [user]
    end
  end
```


I used the new `describe` declaration for my test case, explicitly cast the `:job` type, and used the newly available `must_enqueue_email_with` expectation.

Easy, right? Well, no matter how I declared my test case, whether with implicit or explicit typing, `must_enqueue_email_with` raised a `NoMethodError`.

It means the [`Minitest::Rails::Expectations::ActiveMailer`](https://github.com/minitest/minitest-rails/blob/master/lib/minitest/rails/expectations/active_mailer.rb){:target="_blank"} module isn't mixed-in automatically.

I had to include `Minitest::Rails::Expectations::ActionMailer` within my test case to make this expectation work:

```ruby
describe CalendlyEventsManagerJob, :integration do
  include Minitest::Rails::Expectations::ActionMailer

  ...
end
```


There's no mention of this in the documentation, but I've found this comment in the `ActiveJob` expectations module:

> This exists as a module to allow easy mixing into classes
> other than ActiveJob::TestCase where you might want to do
> job testing e.g. in an Active Record model which triggers
> jobs in a callback.

So it seems there is still some manual mixin to do, despite most of the inheritance being automatically handled.

Is it normal? Did I do something wrong? I don't know (yet)!

## Wrapping up

Well, this was a fun chase!

Let's recap:
- `Minitest::Spec` also exposes `let` and `subject`.
- Both are lazily evaluated instance variables.
- With `Minitest::Spec`, you can nest `describe` blocks for better contextualisation.
- The `minitest-rails` gem provides a seamless integration of Minitest into Rails.
- The gem provides extra methods for an overall spec-flavored test suite.
- In my experience, it comes with some challenges around these extra expectations, which I solved by manually including the modules. But YMMV.

The fourth part of the series – [Using Minitest::Spec in Rails? Watch out for the lifecycle hooks!](/minitest-spec-and-rails-hooks/) – is not live.

Big thank-yous to Cecile for pointing out the topic of `let` and `subject`, and to Eric for helping me out with setting-up the `minitest-rails` gem.
