---
layout: post
title: "Dependency injection in Ruby"
excerpt: "Classes depend on each other all the time. But the way you tie those classes together will determine the _cost of change_. Dependency injection can help you reduce that coupling, and make the change easy."
date: 2021-12-07
permalink: /dependency-injection-in-ruby/
category: 'ruby'
cover_image: /media/2021/12/remi-mercier-dependency-injection-in-ruby.png
---

Lately, I've been interested in abstractions: why objects behave the way they do, how do we architecture our code so it's open to change (without causing unnecessary headaches), to which class _that_ specific behavior should belong? And during that time, I've repeatedly heard folks talk about __dependency injection__.

I'm glad to report that I've finally managed to wrap my head around this enough to use this practice daily. I guess it's time for me to give you a tour of dependency injection: what it is, why do you need it, and how to use it?

## What is a dependency?

First, let's explain what a dependency is.

<blockquote>A dependency is an abstraction upon which another abstraction depends.</blockquote>

In the context of a Ruby - or a Rails - application, _abstraction_ mainly refers to _classes_.

Check out the codebase you're working on right now. Look out for classes that send messages to other classes directly from their methods.

Let's draw an example: each month, you need to compute revenue statistics for authors.

The code could look like this:

{% highlight ruby %}
  class Author
    # ...

    def monthly_revenue
      RevenueStatsCalculator.calculate_for(self, month_to_date)
    end
  end
{% endhighlight %}

Here, `Author` have __one dependency__: `Author` depends on `RevenueStatsCalculator` to pull the raw statistics.

That dependency lies within the body of the `Author` class in the `monthly_revenue` method.

`Author` knows that `RevenueStatsCalculator` exists, that it responds to `calculate_for`, and that `calculate_for` takes two arguments.

This knowledge introduces tight coupling between `Author` and `RevenueStatsCalculator`. And tight coupling makes for difficult changes when new requirements are introduced. And dependency injection can loosen the coupling between your classes.

## Dependency injection explained with simple words

<blockquote>Dependency injection is a coding practice that allows you to move a dependency from the guts of a class to its initialization.</blockquote>

Dependy injection is [the implementation derived from the Dependency Inversion Principle](https://stackoverflow.com/a/46745172){:target="\_blank"} (DIP). The `D` in DIP is also known as the `D` in the [SOLID principles](http://www.butunclebob.com/ArticleS.UncleBob.PrinciplesOfOod){:target="\_blank"}[^2].

The Dependency Inversion Principle says that your objects should not rely on other specific objects (_concretions_) but higher-level abstractions.

Here are a few examples:
- `1` is a concretion. `Integer` is its higher-level abstraction.
- `like`, `follow`, `retweet` are concretions. `Interaction` is their higher-level abstraction.
- `Algolia` or `ElasticSearch` are concretions. `SearchEngine` is their higher-level abstraction.

## What's wrong with dependencies?

The best way to _feel_ the problem with dependencies is to work on existing abstractions and add new requirements.

Here's your initial code:

{% highlight ruby %}
  class Author
    # ...

    def monthly_revenue
      RevenueStatsCalculator.calculate_for(self, month_to_date)
    end
  end
{% endhighlight %}

SWhat is the problem here?

Here, the `Author` class is _tighly coupled_ to the `RevenueStatsCalculator` class for its statistics calculations.

What if `RevenueStatsCalculator` is a third-party application? What if I need to use a different service based on the author's country?

I could make some changes inside `Author`, of course. A simple conditional would work just fine.

{% highlight ruby %}
  class Author
    def monthly_revenue
      if self.french?
        RevenueStatsCalculator.calculate_for(self, month_to_date)
      else
        AnotherRevenueCalculator.compute_date(id)
      end
    end
    # ...
  end
{% endhighlight %}

Can you see what's happening here? Not only did I add a conditional, but the two calculators are not responding to the same methods - to the same API:

- `RevenueStatsCalculator` responds to `calculate_for` with two arguments (an author and a date range).
- `AnotherRevenueCalculator` responds to `compute_date` with one argument (an id).

This code is already confusing, and ~~could~~ will end up even harder to read (and, to change).

Conditionals breed says, Sandi Metz. And you don't want that.

Time to call dependency injection to the rescue!

## How to inject dependencies?

You'll see that the definition of dependency injection sounds quite pompous compared to the _how-to_.

The main idea behind dependency injection is that your class can interact with different abstractions instead of being stuck with one concretion. How do you do that? By passing the dependency to the class during initialization.

{% highlight ruby %}
  class Author
    def initialize(revenue_calculator: RevenueStatsCalculator)
      @revenue_calculator = revenue_calculator
    end

    # ...

    def monthly_revenue
      @revenue_calculator.calculate_for(self, month_to_date)
    end
  end
{% endhighlight %}

What happened here:
- We moved the first mention of `RevenueStatsCalculator` from the guts of `Author` to its initialization.
- Then, we replaced all other occurrences of `RevenueStatsCalculator` with an instance variable describing the higher abstraction (`@revenue_calculator`).

Now, I can pass a new calculator while initializing an author or default to `RevenueStatsCalculator`.

`Author` is more modulable. The class can work with different calculators as long as they respond to the same API (i.e., the same public methods).

## Why is dependency injection important?

### Loose coupling == decreased cost of change

Without belaboring the point, let's repeat it one last time: Classes depend on each other all the time. But the way you tie those classes together will determine the _cost of change_.

In the example above, we saw that if the need arises to handle several calculators for statistics, injecting them during initialization is much simpler than choosing between them through conditionals.

If you want to dig deeper, go and read [99 Bottles of OOP](https://sandimetz.com/99bottles){:target="\_blank"} by Sandi Metz. She wrote some beautiful chapters on the subject.

### Better readability

When programmers scatter dependencies around a class, it's not easy for the readers to find them, even harder to keep track of them. Dependency injection reduces that friction.

Injecting dependencies at initialization gather them in the same place. They are easier to read and remember.

### Better testing

When a class is tightly coupled to another, its complexity shows through in your tests.

If you want to test `Author#monthly_revenue` as it's defined below, you'd need to create an instance double for `RevenueStatsCalculator`, allow the double to receive `calculate_for`, then mock its response.

{% highlight ruby %}
  class Author
    # ...

    def monthly_revenue
      RevenueStatsCalculator.calculate_for(self, month_to_date)
    end
  end

  RSpec.describle Author do
    describe '#montly_revenue' do
      subject(:montly_revenue) { author.monthly_revenue }

      let(:author) { create :author }
      let(:fake_calculator) { instance_double(RevenueStatsCalculator) }
      let(:response) { # some response }

      before do
        allow(fake_calculator).to receive(:calculate_for).and_return(response)
      end

      it 'fetches statistics' do
        # test things here
      end
    end
  end
{% endhighlight %}

The setup is complicated. Your tests know more than they should.

When `Author` keeps a dependency at its heart, it's impossible to test it in isolation. You _have_ to create a whole context around it. You need to bring in the dependency too. Your tests are tied to the current implementation of `#monthly_revenue`. If your code changes - by adding conditionals, for instance - your tests need to change too.

With dependency injection, you loosen that coupling a bit. You can inject any fake Ruby object that serves as a test-only statistics calculator. When you inject a dependency, you rely on polymorphism instead of conditionals. The dependency needed in `Author#monthly_revenue` responds to the same API, whichever calculator you feed your class. And your tests don't need to change.

Once again, I encourage you to read the end of 99 Bottles of OOP, which explores the topic of testing while moving dependencies to initialization with _brio_.

Cheers,

Rémi


[^1]: If you're using Rails, you're already familiar with seeing a lot of `SomethingMailer` hang around your code.
[^2]: I've never managed to learn the meaning of all SOLID principles. I mean, an acronym that declines into five acronyms, that decline into cryptic principles.
