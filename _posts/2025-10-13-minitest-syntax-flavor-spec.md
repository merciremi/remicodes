---
toc: true
layout: post
title: "What is Minitest::Spec?"
excerpt: "In my previous post, I talked a lot about how Minitest comes in various syntax flavors. One flavor I did not cover much is Minitest's spec extension."
date: 2025-10-13
permalink: /minitest-spec/
categories: [other]
cover_image:
---

In my previous post, I talked a lot about how Minitest comes in various syntax flavors. One flavor I did not cover much is Minitest's spec extension.

Before I dive in with a dedicated post about assertions, I want to cover this RSpec-style way of writing tests.

## Minitest syntax flavors: a recap

As I wrote in [my previous post]({{site.baseurl}}/introduction-to-minitest/), Minitest comes in multiple flavors:
- plain Minitest: `def test_this_method`
- Rails' style: `test "this method"`
- and a spec system called `Minitest::Spec`: `it "tests this method"`

Each flavor changes the syntax we use to define our test files and our test examples. The changes in the DSL are minimal, in the sense that they all look familiar to Ruby developers.

Assertions are another matter.

While Rails adds a [handful of assertions](https://api.rubyonrails.org/classes/ActiveSupport/Testing/Assertions.html){:target="_blank"} (mostly around database changes), both Minitest and Rails rely on the following paradigm:

> Check that the expected assertion holds true against the actual result.

On the contrary, `Minitest::Spec` relies on the (RSpec-like) opposite paradigm:

> Check that the actual behavior matches the expected result.

I know this sounds "po-tay-to, po-tah-to", but bear with me for one sec.

### Plain Minitest flavor:

{% highlight ruby %}
  class UserTest < Minitest::Test
    def setup
      @user = User.new(first_name: "buffy", last_name: "summers")
    end

    def test_returns_the_full_name
      assert_equal "buffy summers", @user.full_name
    end
  end
{% endhighlight %}

### `Minitest::Spec` flavor:

{% highlight ruby %}
  class UserTest < Minitest::Spec
    before do
      @user = User.new(first_name: "buffy", last_name: "summers")
    end

    it "returns the capitalized full name" do
      expect(@user.full_name).must_equal "Buffy Summers"
    end
  end
{% endhighlight %}

For someone who comes from RSpec, this looks *very* familiar:
- Building a setup with `before do ... end` instead of `setup do ... end`.
- Defining test examples with `it` instead of `test` or `def test_*`.
- Expectations instead of assertions: `expect(actual behavior).must_equal expected_result`.

Using `Minitest::Spec` also allows me to organize my tests into describe blocks for different contexts.

{% highlight ruby %}
  class UserTest < Minitest::Spec
    before do
      @user = User.new(first_name: "buffy", last_name: "summers")
    end

    it "returns the capitalized full name" do
      expect(@user.full_name).must_equal "Buffy Summers"
    end

    describe "when the user has a two-word last name" do
      before do
        @user = User.new(first_name: "buffy", last_name: "jane summers")
      end

      it "does not return the capitalized full name" do
        expect(@user.full_name).wont_equal "Buffy Jane Summers"
      end
    end
  end
{% endhighlight %}

Expectations can also be slightly abstracted away with the following syntax:

{% highlight ruby %}
  it "returns the capitalized full name" do
    _(@user.full_name).must_equal "Buffy Summers"
  end
{% endhighlight %}

## How to enable `Minitest::Spec`?

### In Ruby applications

In plain Ruby files, there’s no need to configure anything at the application level. Minitest comes with both flavors, plain and spec, by default.

The only gotcha is that test classes need to inherit from `Minitest::Spec` instead of `Minitest::Test`. If you didn't find this documented in the official repository, you're not alone. It’s not documented at all. I found it [in the source code](https://github.com/minitest/minitest/blob/master/lib/minitest/spec.rb#L58C24-L58C38){:target="_blank"} while investigating why my spec-style tests weren’t working.

{% highlight ruby %}
  class UserTest < Minitest::Spec
    ...
  end
{% endhighlight %}

### In Rails applications

In Rails, I've found that you need to require `"minitest/spec"` and extend `Minitest::Spec::DSL` to the `ActiveSupport::TestCase` class.

Here's an extract from my `test_helper.rb` file:

{% highlight ruby %}
  # frozen_string_literal: true

  require "rails/test_help"
  require "minitest/spec"

  module ActiveSupport
    class TestCase
      extend Minitest::Spec::DSL
    end
  end
{% endhighlight %}

On the other hand, there's no need to change the inheritance of your test classes to `Minitest::Spec`. The inheritance in Rails is already *quite* complicated on its own, though:
- Unit tests inherit from `ActiveSupport::TestCase`
- Integration tests inherit from `ActionDispatch::IntegrationTest`
- Unit tests for views (think helpers) inherit from `ActionView::TestCase`
- System tests inherit from `ApplicationSystemTestCase`

## Sharp knives and gotchas

Ruby and Rails allow you to do some weird things at your own risk. Mixing `setup do` and `before do` in the same file is one of them.

*Don't do this. This is for educational purpose only.*

In plain Ruby, `setup` and `before` will work alongside one another without a hurdle.

In Rails, both will work if used exclusively in one file. If you mix them in one file, you have two possible outcomes:

- If you use `setup` before `before`, your tests will run normally.
- If you use `before` before `setup`, your test will potentially fail because `setup` was not executed.

{% highlight ruby %}
  require "test_helper"

  class UserTest < ActiveSupport::TestCase
    before do
      # will get executed
    end

    test "some method" do
      # will pass
    end

    describe "a nested context" do
      setup do
        # will not be executed
      end

      it "returns some result" do
        # will potentially fail
      end
    end
  end
{% endhighlight %}

Now that we're more familiar with `Minitest::Spec`, we have access to a new way of writing assertions, such as `must_equal`, `must_match`, and others. I'll cover those in a future post.

## Wrapping up

I hope this post helped clarify the basics of the `Minitest::Spec` syntax.

The TL;DR is:
- `Minitest::Spec` is an extension of `Minitest::Test`.
- `Minitest::Spec` is the third main flavor of Minitest.
- `Minitest::Spec` provides a bridge between assertions and spec-style expectations.
- Adding `Minitest::Spec` to Ruby or Rails comes with some gotchas.

The third post of this series – [More Minitest::Spec shenanigans]({{site.baseurl}}/more-minitest-spec/) – is live.
