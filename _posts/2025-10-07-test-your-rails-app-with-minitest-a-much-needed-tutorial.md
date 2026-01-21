---
layout: post
title: "Lost in Minitest? Start here!"
excerpt: "I have a confession to make: I have never used Minitest in the seven years I've been a professional programmer. Lured by the promise of speed and wide adoption, I decided to try Minitest. Then I hit an unexpected roadblock."
date: 2025-10-07
permalink: /introduction-to-minitest/
category: other
cover_image:
---

I have a confession to make: I have never used Minitest in the seven years I've been a professional programmer.

I've always used [the *other framework*]({{site.baseurl}}/series/rspec/).

But earlier this year, I started working with a client whose application relied solely on QA instead of automated tests. In an effort to bring the team peace of mind during releases, I started adding tests to the most critical parts of the application.

Lured by the promise of speed and wide adoption, I suggested we try Minitest.

As I started working on writing my first tests, I hit an unexpected roadblock.

## Minitest (lack of) onboarding

After writing several hundred tests, I can confidently say that **Minitest's biggest weakness is its onboarding**. The information is so awfully scattered, so sparse and so obscure that it makes navigating your tax returns friendlier in comparison.

As a newcomer, I would have loved (let's forget about love, **I would have needed!**) to get the main information right off the bat:
- What does Minitest do?
- Why does Minitest do what it does?
- How do you make Minitest do what it does?

Instead, Minitest's [official repository](https://github.com/minitest/minitest){:target="_blank"} is a piece of writing more akin to Joyce's Ulysses than to a technical documentation.

Programmers get welcomed with a list of footer-worthy links, some congratulatory quotes, and hints that you should get a mental health check for having ever used RSpec.

You have to scroll past this cruft to get the first useful nugget of information: a breakdown of Minitest main components.

## Minitest 101

Minitest is a prominent testing framework for Ruby code. It's the default testing framework embedded by default in [Ruby](https://ruby-doc.org/stdlib-2.7.4/libdoc/minitest/rdoc/Minitest.html){:target="_blank"} and [Ruby on Rails](https://github.com/rails/rails/blob/main/activesupport/lib/active_support/test_case.rb){:target="_blank"}.

If you generate a new Rails app today, or if you have an existing app with no other test framework configured, you can run `rails test`, and Rails will find the `test` folder and check for test files.

Otherwise, it's just a matter of adding `gem 'minitest'` to your Gemfile, and off you go.
Minitest provides several components, each addressing a specific need. Here are a few:
- [minitest/test](https://docs.seattlerb.org/minitest/Minitest/Test.html){:target="_blank"} provides a set of assertions to test your code.
- [minitest/spec](https://docs.seattlerb.org/minitest/Minitest/Expectations.html){:target="_blank"} enables the use of RSpec-like matchers.
- [minitest/mock](https://docs.seattlerb.org/minitest/Minitest/Mock.html) is a lightweight mocking (and stubbing) library.


Minitest uses the concept of **assertions** which lets you verify that the expected result matches the actual result:

> Check that this condition holds true.

Coming from RSpec, I'm used to the concept of **expectations** which take the opposite perspective of Minitest’s assertions:

> This object should behave this way.

## Minitest syntax flavors : everything, everywhere, all at once

One thing that slowed down my adoption is that Minitest offers **multiple styles of syntaxes**. You can write the same test in several ways, sometimes even mixing styles together. Each style lives in its own module or extension.

RSpec is either loved or hated for its DSL, but it gives me one major advantage: I don’t have to decide for every test which style to use. [I use the standard and I move on]({{site.baseurl}}/pick-a-standard/).

With Minitest, though, I can choose from:
- the default syntax
- Rails’ custom syntax
- or Minitest’s spec syntax (which mimic RSpec’s style)

Let's write some tests so you get my point.

## Writing my first tests with Minitest

Let's say I have this plain Ruby `User` class:

{% highlight ruby %}
  class User
    attr_accessor :first_name, :last_name

    def initialize(first_name:, last_name:)
      @first_name = first_name
      @last_name = last_name
    end

    def full_name
      "#{first_name.capitalize} #{last_name.capitalize}"
    end
  end
{% endhighlight %}

And I want to write a simple test for it:

{% highlight ruby %}
  require "minitest/autorun"
  require_relative "user"

  class UserTest < Minitest::Test
    def setup
      @user = User.new(first_name: "buffy", last_name: "summers")
    end

    def test_returns_the_full_name
      assert_equal "buffy summers", @user.full_name
    end
  end
{% endhighlight %}

In this case, I'm using plain Minitest. It's the default syntax, with the simplest setup.

Several remarks:
- `require "minitest/autorun"` instructs Ruby to load Minitest and run the tests once the file is loaded.
- `UserTest` inherits from `Minitest::Test`, which allows me to use Minitest's syntax.
- My test method `def test_returns_the_full_name` is prefixed with `test_` which is a [Minitest convention](https://github.com/minitest/minitest?tab=readme-ov-file#label-Unit+tests){:target="_blank"}.
- The `assert_equal` method takes the expected result first, the actual result second.
- `def setup; end` lets me create my test setup before my code run, similar to RSpec's `before do ... end`).
- I use ivars to access the objects I set up for my test examples.

Here's the output for this first test:

{% highlight bash %}
  lab/minitest-post → ruby user_test.rb
  Run options: --seed 64661

  # Running:

  .

  Finished in 0.001239s, 807.1025 runs/s, 807.1025 assertions/s.
  1 runs, 1 assertions, 0 failures, 0 errors, 0 skips
{% endhighlight %}

If my test were to failed:

{% highlight bash %}
  lab/minitest-post → ruby user_test.rb
  Run options: --seed 22116

  # Running:

  F

  Failure:
  UserTest#test_returns_the_full_name [user_test.rb:10]:
  Expected: "buffy summers"
    Actual: "Buffy Summers"

  bin/rails test user_test.rb:9

  Finished in 0.001472s, 679.3478 runs/s, 679.3478 assertions/s.
  1 runs, 1 assertions, 1 failures, 0 errors, 0 skips
{% endhighlight %}

### The same test, but in Rails

{% highlight ruby %}
  class User < ApplicationRecord
    def full_name
      "#{first_name.capitalize} #{last_name.capitalize}"
    end
  end
{% endhighlight %}

{% highlight ruby %}
  require "test_helper"

  class UserTest < ActiveSupport::TestCase
    def setup
      @user = User.new(first_name: "buffy", last_name: "summers")
    end

    test "returns the full name" do
      assert_equal "Buffy Summers", @user.full_name
    end
  end
{% endhighlight %}

What's changed:
- My `User` now inherits from `ApplicationRecord` (because Rails).
- My test file starts with `require "test_helper"`, which loads the Rails testing environment (database, fixtures, helpers, etc.)
- `UserTest` now inherits from `ActiveSupport::TestCase`, which inherits from `Minitest::Test`. This allows Rails to define additional assertions.
- Minitest's test method definition (`def test_returns_the_full_name`) is now abstracted into the Rails DSL (`test "returns the full name"`). This syntax is just a method, `test`, that takes a description and a block as arguments ([see the code source](https://github.com/rails/rails/blob/main/activesupport/lib/active_support/testing/declarative.rb){:target="_blank"}).

Since `ActiveSupport::TestCase` inherits from `Minitest::Test`, I can also mix and match syntaxes if I ever feel so inclined:

{% highlight ruby %}
  require "test_helper"

  class UserTest < ActiveSupport::TestCase
    setup do
      @user = User.create(first_name: "buffy", last_name: "summers")
    end

    def test_returns_the_full_name
      assert_equal "buffy summers", @user.full_name
    end

    test "returns the user slug" do
      assert_equal "buffy_summers", @user.slug
    end
  end
{% endhighlight %}

Here, I use both Minitest syntax and the Rails DSL to define test examples in the same file. Does it work? Yep! Should I do it? I'd rather not!

But I wanted to show you that you can, even if you shouldn't.

I did not even toggle `minitest/spec` which opens up a third syntax to set up and define your test examples. I'll cover this in another post.

One thing I'm not showing here that you should know. In Rails, based on your type of test, you'll want your test file to inherit from a different class:
- Unit tests, inherit from `ActiveSupport::TestCase`
- Integration tests, inherit from `ActionDispatch::IntegrationTest`
- Unit tests for views (think helpers), inherit from `ActionView::TestCase`
- System tests, inherit from `ApplicationSystemTestCase`

## Wrapping up

As always, I intended this post to be short, and failed.

If you’re starting out with Minitest and feeling a bit lost, I hope this post helped you understand the basics.

The TL;DR is:
- Minitest is part of Ruby standard library.
- Minitest is part of Rails `ActiveSupport`.
- Minitest has several possible syntaxes to define your test examples.
- Minitest has a multitude of assertions (we'll cover those in the next post).
- Minitest is obscure at first, but once you get the hang of it, it's quite neat.

The second part of this series – [What is Minitest::Spec]({{site.baseurl}}/minitest-spec/) – is now live!

Thank you to [Cecile](https://www.cecilitse.org/){:target="_blank"} for her suggestions.
