---
layout: post
title: Dependency injection in Ruby
---

Lately, I've been really interested in abstractions: why objects behave the way they do, how do we architecture our code so it's open to change (without causing unecessary headaches), to which class _that_ specific behavior should belong? And during that time, I've repeateadly heard folks talk about __dependency injection__.

I'm glad to report that I've finally managed to wrap my head around this enough to use this practice on a daily basis. So, I guess it's time for me to give you a tour of the _what_, the _why_, and the _how_.

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

That dependency is defined within the body of the `Author` class, in the `monthly_revenue` method.

`Author` knows that `RevenueStatsCalculator` exists, that it responds to `calculate_for`, and that `calculate_for` takes two arguments.

This knowledge introduces a tight coupling between `Author` and `RevenueStatsCalculator`. And tight coupling makes for difficult changes when new requirements are introduced. And dependency injection can help you loose the coupling between your classes.

## Dependency injection explained with simple words

<blockquote>Dependency injection is a coding practice that allows you to move a dependency from the guts of a class to its initialization.</blockquote>

Dependy injection is [the implementation derived from the Dependency Inversion Principle](https://stackoverflow.com/a/46745172){:target="\_blank"} (DIP). The `D` in DIP is also known as the `D` in the [SOLID principles](http://www.butunclebob.com/ArticleS.UncleBob.PrinciplesOfOod){:target="\_blank"}[^2].

The Dependency Inversion Principle says that your objects should not rely on other specific objects (_concretions_) but on higher-level abstractions.

Here are a few examples:
- `1` is a concretion. `Integer` is its higher-level abstraction.
- `like`, `follow`, `retweet` are concretions. `Interaction` is their higher-level abstraction.
- `Algolia` or `ElasticSearch` are concretions. `SearchEngine` is their higher-level abstraction.

## What's wrong with dependencies?

The best way to _feel_ the problem with dependencies is to work on existing abstractions and add new requirements.

Here's our initial code:

{% highlight ruby %}
  class Author
    # ...

    def monthly_revenue
      RevenueStatsCalculator.calculate_for(self, month_to_date)
    end
  end
{% endhighlight %}

So, what is the problem here?

Here, my `Author` class is _tighly coupled_ to the `RevenueStatsCalculator` class for its statistics calculations.

What if `RevenueStatsCalculator` is a third party application? What happens if, based on the country of the author, I need to use a different service to compute stats?

I could make some changes inside `Author` of course. A simple conditional would work just fine.

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

What if I need to add a different statistics service for another country? Should I add a new conditional? This is already confusing and ~~could~~ will end up in a big pile of mess.

Sandi Metz has a nice way to put it: conditionals breed. And we don't want that.

This is where dependency injection comes in and help.

## How to inject dependencies?

You'll see that the definition of dependency injection sounds quite pompous compared to the _how-to_.

The main idea behind dependency injection is that your class can interact with different abstractions instead of being stuck with one concretion. How do we do that? By passing the dependency to the class during initialization.

% highlight ruby %}
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
- Then, we replaced all other occurences of `RevenueStatsCalculator` by an instance variable describing the higher abstraction (`@revenue_calculator`).

Now, I can either pass a new calculator while initializing an author, or default to `RevenueStatsCalculator`.

`Author` is more modulable. The class can work with different calculators, as long as they respond to the same API (i.e. the same public methods).

## Why is dependency injection important?

### Loose coupling == decreased cost of change

We won't belabor the point. Classes depend on each other all the time. But the way you tie those classes together will determine the _cost of change_.

In the example above, we saw that if the need arise to handle several calculators for statistics, injecting them during initialization is much simpler that handling them with conditionals.

If you want to dig deeper, go and read [99 Bottles of OOP](https://sandimetz.com/99bottles){:target="\_blank"} by Sandi Metz. She wrote some beautiful chapters on the subject.

### Better readability

When dependencies are squattered around a class, it's not easy for the readers to find them, least keep track of them. Dependecy injection reduces that friction.

By moving all dependencies at initialization, they're all gathered in the same place. They are easier to read and to remember.

### Better testing

When a class is tighly coupled to another, it's complexity shows in your tests.

If you wanted to test `Author#monthly_revenue` as it's defined below, you would need to create an instance double for `RevenueStatsCalculator`, allow the double to receive `calculate_for`, then mock its response.

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

The complicated setup only shows that your tests know more than they should.

You should be able to test `Author#monthly_revenue` without being tied to the current implementation of your method. You also should be able to test `Author` in isolation without having to bring in other abstractions. But this will be the topic of another post.

Cheers,

Rémi


[^1]: If you're using Rails, you're already familiar with seeing a lot of `SomethingMailer` hang around your code.
[^2]: I've never managed to learn the meaning of all SOLID principles. I mean, an acronym that declines into five acronyms, that decline into cryptic principles.
