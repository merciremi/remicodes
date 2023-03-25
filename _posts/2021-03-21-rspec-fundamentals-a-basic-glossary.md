---
layout: post
title: "RSpec fundamentals: a basic glossary"
date: 2021-03-21
excerpt: "RSpec syntax can be tricky to get at first. Here's a glossary of the keywords you'll use the most when testing with RSpec: describe, subject, let vs let!, it, context, etc..."
permalink: /rspec-fundamentals-glossary/
category: rspec
cover_image: /media/2021/03/rspec-fundamentals-glossary-remi-mercier.gif
---

In this second part of the [RSpec fundamentals series]({{site.baseurl}}/series/rspec/), I want to explore the methods you'll use the most when testing with RSpec: `describe`, `subject`, `let` and `let!`, `context`, and `it`.

If you haven't read the first part - [how to setup RSpec and name files and, digging into their basic structure]({{site.baseurl}}/rspec-101-basic-set-up/), go and read it, I'll wait.

Done? Let's move on to our second installment!

We'll build an example test for a `User` model. I'll explain key concepts and keywords along the way.

## Describe your abstraction with `describe`

We've already dug into the inner workings of `describe` in the first post. So here's a summary of what RSpec `describe` is:

> `describe` is a method used to group your tests around a common abstraction: a class, a request, etc. It's a wrapper that builds an example group.

Since methods are an abstraction, you usually nest several `describe`s in your example group. Let's test an instance method - `#full_name`.

{% highlight ruby %}
  # spec/models/user_spec.rb

  require 'rails_helper'

  RSpec.describe User, type: :model do
    describe '#full_name' do
      # test the output of the method full_name
    end
  end
{% endhighlight %}

As you can see, the first `describe` is called on the module `RSpec` and _describes_ the `User` class. <mark>This is the top-level example group</mark>. The second `describe` is called within our top-level example group and describes the method `#full_name`.

The second `describe` is nested in the top-level one. Both describe _something_: a class, a method.

The emphasis on _"something"_ here is important. We'll get back to it when we talk about `context`.

Note how the second `describe` takes a string as an argument. The string is the description of the abstraction your testing. As a rule of thumb, when testing a method, the description is its name. Prefix it with a hash or a dot, based on the scope of the method:
- `describe '#instance_method_name'` for instance methods
- `describe '.class_method_name'` for class methods

When you run your tests, RSpec will output your description like this:

{% highlight zsh %}
  Randomized with seed 4321

  User
    #full_name
{% endhighlight %}

Once we write tests, RSpec will output more details.

## Declare your abstraction with `subject` (and named subject)

`subject` represents the abstraction you're testing. Your subject can be a method, a request, a serialized object, etc. In our example, it's the method `#full_name`.

{% highlight ruby %}
  # spec/models/user_spec.rb

  require 'rails_helper'

  RSpec.describe User, type: :model do
    describe '#full_name' do
      subject { user.full_name }
    end
  end
{% endhighlight %}

`subject` is a method that takes a block in which I call the method `#full_name` on an instance of `User`.

What's the difference between `subject` and `describe` then? `subject` tells RSpec what to evaluate. `describe` is _just_ here to make your tests readable.

Sometimes, you need to explicitly reference your subject in your tests (we'll see an example in a little while). In that case, it's best to name your subject.

{% highlight ruby %}
  # spec/models/user_spec.rb

  require 'rails_helper'

  RSpec.describe User, type: :model do
    describe '#full_name' do
      subject(:full_name_method) { user.full_name }
    end
  end
{% endhighlight %}

Here `full_name_method` will reference the output of the `#full_name` method in our tests. I've chosen a somewhat crappy name - `full_name_method` - to highlight the difference between the name of the subject and the actual evaluation of the method.

Why the `User` class is not the subject of our whole example group? Are we not testing the model `User`? You're right. We _are_ testing the `User` class but you can't test the class as a whole. So you test each part, each behavior until they sum up to your class. Each behavior is a different test subject. This is why RSpec advertises itself as _behavior driven development_.

But hang on! In our example, where does that `user.full_name` comes from? Let me show you how variables work in RSpec.

## Creating variables with `let` and `let!`

`let` is specific to RSpec. It's the method that lets you create variables.

{% highlight ruby %}
  # spec/models/user_spec.rb

  require 'rails_helper'

  RSpec.describe User, type: :model do
    let(:user) { User.create(first_name: 'Buffy', last_name: 'Summers') }

    describe '#full_name' do
      subject { user.full_name }
    end
  end
{% endhighlight %}

Here, we create a user and assign it to the variable `user`.

But why don't we just use a good old `user = User.create`? We could get rid of those `:` and `{}`!

Technically, you could. This is valid and your tests will be able to access the value store in `user`.

But `let` is not just a way to assign values to variables.

First, `let` is lazy-evaluated. It means - in our example - that the user won't be created and assigned until your tests invoke the variable `user` for the first time. Second, `let` is a memoized helper method. Once the value is evaluated for the first time, it won't be evaluated again. Its value is cached across the example group. In our example above, `user` is evaluated once and its value is cached across all examples because `let(:user)` is defined at the top-level example group (the `RSpec.define` block)[^1].

### What about `let!`?

If you want to force the evaluation of `User.create` before your tests run, use `let!` instead. This is useful when you need to create several instances as a context for your tests.

To recap:
- `let(:user) { ... }` is only evaluated the first time a test calls the variable `user`.
- `let!(:user) { ... }` is evaluated before each test.

### Other variables

In your test, you can also access the variable `described_class` which represents the core abstraction of your spec file. In our case, this is the `User` class.

### Contextual `let`

You often need to change the value of variables based on some context. Here's an example:

{% highlight ruby %}
  # spec/models/user_spec.rb

  require 'rails_helper'

  RSpec.describe User, type: :model do
    let(:user) { User.create(first_name: first_name, last_name: last_name) }

    describe '#full_name' do
      subject { user.full_name }

      let(:first_name) { 'Buffy' }
      let(:last_name) { 'Summers' }
    end
  end
{% endhighlight %}

Here, `user` is still accessible everywhere, but `first_name: 'Buffy'` and `last_name: 'Summers'` are only accessible within the context of the `#full_name` example group.

This allows you to change the value when you need it. Speaking of context, let's check it out.

## Test conditionnal behavior with `context`

`context` is best understood with an example. Let me show you something before I give you a definition.

{% highlight ruby %}
  # spec/models/user_spec.rb

  require 'rails_helper'

  RSpec.describe User, type: :model do
    let(:user) { User.create(first_name: 'Buffy', last_name: 'Summers') }

    describe '#full_name' do
      subject { user.full_name }

      context 'when a user has a first_name and a last_name' do
        # test the output of the method full_name under a specific constraint
      end

      context 'when a user has no last_name' do
        # test the output of the method full_name under another constraint
      end
    end
  end
{% endhighlight %}

Can you guess what `context` does?

> `context` is used to group your tests around - drum roll 🥁 - a specific context.

I know. It sounds silly when you spell it out.

If you expect a different output for your method `#full_name` based on a condition - a blank last name, for example - you can group your tests in several `context` blocks.

Some examples of contexts you'll use in your tests:
- What happens if an attribute is `nil` when I expected a truthy value?
- What happens if the type of my input is different from the one I expected?
- What happens when methods raise an error? And when it doesn't?

Here's the output of your tests with some contexts:

{% highlight zsh %}
  Randomized with seed 4321

  User
    #full_name
      when a user has a first_name and a last_name
        ...
      when a user has no last_name
        ...

{% endhighlight %}

### When to use `describe` and when to use `context`

To be honest, when I first started testing, I would use `describe` and `context` indifferently. Then after a while, I set into a pattern:

- When I test _something_ - a class, a method, an abstraction -, I use `describe`.
- When I test _how that something fare under a certain circumstance_ - a missing parameter, an `nil` value, etc -, I use `context`.

## Describe your test with `it`

We're getting there! But before we write the _actual_ content of our first test, we need to describe it first. And this is what `it` does. As `describe` is a wrapper to build an example group, `it` is a wrapper to build an example. `it`takes a string as an argument.

The description of each test should state the expected behavior of the abstraction you're testing.

{% highlight ruby %}
  # spec/models/user_spec.rb

  require 'rails_helper'

  RSpec.describe User, type: :model do
    let(:user) { User.create(first_name: 'Buffy', last_name: 'Summers') }

    describe '#full_name' do
      subject { user.full_name }

      context 'when a user has a first_name and a last_name' do
        it "returns the user's full name" do
          # test expected behaviour
        end
      end

      context 'when a user has no last_name' do
        it "returns an error" do
          # test the expected behaviour
        end
      end
    end
  end
{% endhighlight %}

For each `context`, I expect a specific output. `it` makes it clear what I should get out of my abstraction.

RSpec will print out your `it`s in your console.

{% highlight zsh %}
  Randomized with seed 4321

  User
    #full_name
      when a user has a first_name and a last_name
        returns the user's full name
      when a user has no last_name
        returns an error

{% endhighlight %}

See? This is super easy to read. You are testing the instance method `full_name` defined in your class `User`. When your instance of `User` has a value for first name and last name, you expect your method to return your user's full name. When your user has no last name, you expect your method to raise an error.

And now, it's time to write the body of our first test, our expectation.

## What did you `expect`?

RSpec is behavior-based. It allows you to compare the _expected_ behavior of your abstraction with the actual behavior of your abstraction (i.e. your `subject`).

You `expect` your test's `subject` to equal / contain / include your expected output. Let me show you.

{% highlight ruby %}
  # spec/models/user_spec.rb

  require 'rails_helper'

  RSpec.describe User, type: :model do
    let(:user) { User.create(first_name: 'Buffy', last_name: 'Summers') }

    describe '#full_name' do
      subject { user.full_name }

      context 'when a user has a first_name and a last_name' do
        it "returns the user's full name" do
          expect(subject).to eq("Buffy Summers")
        end
      end

      context 'when a user has no last_name' do
        it "returns an error" do
          expect(subject).to raise_error(UserErrors::InvalidLastName)
        end
      end
    end
  end
{% endhighlight %}

`expect` takes your `subject` as an argument and returns an `ExpectationTarget` object with the actual result of your abstraction evaluation stored in it. Then `expect` calls the method `.to` with a _matcher_ as an argument. In our example, `eq` and `raise_error` are matchers. These matchers take an argument too: the expected output.

The matchers' job is to compare the expected output with the actual output. Here's the [code from RSpec](https://github.com/rspec/rspec-expectations/blob/main/lib/rspec/matchers/built_in/eq.rb#L34){:target="\_blank"}, it's pretty straighforward:

{% highlight ruby %}
  module RSpec
    module Matchers
      module BuiltIn
        class Eq < BaseMatcher
          # ...

          private

          def match(expected, actual)
            actual == expected
          end
        end
      end
    end
  end
{% endhighlight %}

If your expectation is fulfilled, your example's description will print out green. If the expectation is not fulfilled, it'll output red.

Before we conclude, let list the basic expectations and matchers from RSpec.

### Basic expectations and matchers

Expectations' job is mostly to create an `ExpectationTarget` object that responds to `.to` or `.to_not`. `.to` and `.to_not` allow you to create positive or negative expectations. This is also where RSpec handle specific examples, like aggregate failures (i.e. when you test several assertions in one example[^2]).

You can write your expectation in three ways:

{% highlight ruby %}
  # spec/models/user_spec.rb

  require 'rails_helper'

  RSpec.describe User, type: :model do
    let(:user) { User.create(first_name: 'Buffy', last_name: 'Summers') }

    describe '#full_name' do
      subject { user.full_name }

      it "returns the user's full name" do
        expect(subject).to eq("Buffy Summers")
      end

      it { expect(subject).to eq("Buffy Summers") }

      it { is_expected.to eq("Buffy Summers") }
    end
  end
{% endhighlight %}

RSpec generates its own message when your write `it { expect(subject).to ... }`. `is_expected` triggers the evaluation of your subject implicitly and returns an RSpec-generated message.

You can dive into [expectations in the RSpec codebase](https://github.com/rspec/rspec-expectations/tree/main/lib/rspec/expectations){:target="\_blank"}.

Matchers are a powerful feature. They allow you to define specific matching rules between your actual output and your expected output:

- `eq` does a simple comparison.
- `contain_exactly` checks if every arguments passed to your matcher are contain in your actual result regardless of order.
- `include` checks is the argument passed to your matcher is included in your result.
- `have_http_status` is damn useful for testing requests' responses.

You can discover all matchers [here](https://github.com/rspec/rspec-expectations/tree/main/lib/rspec/matchers/built_in
){:target="\_blank"}.

## TL;DR

You were too lazy to read all this? I've made you a gif.

<img src="{{ site.baseurl }}/media/2021/03/rspec-fundamentals-glossary-remi-mercier.gif" alt="a gif of a test building up">

If you feel like digging deeper, here are a few links for you:

- [How RSpec works?](https://www.youtube.com/watch?v=B8yKlTNlY5E){:target="\_blank"}: a presentation by Sam Phippen at RubyKaigi in 2019 that gives a good introduction to RSpec's architecture. It's neat!
- [RSpec core library](https://github.com/rspec/rspec-core/tree/main/lib/rspec/core){:target="\_blank"}: contains `it`, `describe`, `context`
- [RSpec expectations](https://github.com/rspec/rspec-expectations){:target="\_blank"}: contains `expect` and matchers

Cheers,

Rémi - [@mercier_remi](https://twitter.com/mercier_remi)

[^1]: This is the context which encapsulates all your tests for the class `User`.
[^2]: `aggregate failures` is pretty useful for testing attributes in a serialized object.
