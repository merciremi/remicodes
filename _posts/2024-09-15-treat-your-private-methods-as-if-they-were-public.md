---
layout: post
title: "Write your private methods like they're public"
excerpt: When designing my abstractions, I’ve always had a very binary view about separating private and public behaviors. A recent gotcha got me to reconsider my practice with a little more nuance.
date: 2024-09-16
permalink: /private-methods-public-methods/
category: ruby
cover_image: "/media/2024/09/remi-mercier-private-methods-public-methods.png"
---

When designing my abstractions, I’ve always had a very binary view about separating private and public behaviors:
- Implementation details are hidden away in the private scope.
- Only the most necessary methods are accessible through the public interface.

However, someone recently pointed out to me a potential gotcha. And I started reconsidering my practice with a little more nuance.

## An innocent-looking piece of code

Let’s consider the following piece of code.

A `lender`  can lend an object to a `borrower` through a `rental`. At some point, we need to know the transactions related to a rental: where should we debit the money, and where should we credit it?

{% highlight ruby %}
  class Rental
    def initialize
      @transactions = []
    end

    def transactions
      return @transactions if @transactions.any?

      debit_transactions + credit_transactions

      @transactions
    end

    private

     def debit_transactions
      @transactions << Transaction.new(:borrower, :debit, 100)
    end

    def credit_transactions
      @transactions << Transaction.new(:lender, :credit, 70)
      @transactions << Transaction.new(:platform, :credit, 30)
    end
  end
{% endhighlight %}

When initializing a `Rental`, we instantiate an empty array assigned to the instance variable `@transactions`. To get the transactions, we call `Rental#transactions`. The method first checks if the instance variable `@transactions` is already populated. If so, `transactions` returns early with the content of the instance variable. If not, the method computes the debit transactions and the credit transactions.

This code works just fine, but we just introduced [a potential bug]({{site.baseurl}}/how-to-use-git-bisect/) in our application. Can you spot it?

## Booby-trapping the future with hidden procedures

In the middle of this fairly OOP class, we added an innocuous procedure. It’s almost abstracted enough to pass as simple array manipulation. And yet.

Several things happen at once. Given the right (and unfortunate) circumstances, `Rental#transactions` could behave unexpectedly.

Before I give you the solution, let’s ask ourselves:

> What would happen if we moved `Rental#debit_transactions` in the public scope?

{% highlight ruby %}
  class Rental
    def initialize
      @transactions = []
    end

    def transactions
      return @transactions if @transactions.any?

      debit_transactions + credit_transactions

      @transactions
    end

    def debit_transactions
      @transactions << Transaction.new(:borrower, :debit, 100)
    end

    private

    def credit_transactions
      @transactions << Transaction.new(:lender, :credit, 70)
      @transactions << Transaction.new(:platform, :credit, 30)
    end
  end
{% endhighlight %}

Now that `Rental#debit_transactions` is part of the public interface of `Rental` - which would make sense - what happens if our application calls `debit_transactions` before it calls `transactions`?

{% highlight ruby %}
  rental_01 = Rental.new
  rental_02 = Rental.new

  # The expected behavior returns an array of debit AND credit transactions
  rental_01.transactions
  # => [
  #      #<Transaction @amount=100, @recipient=:borrower, @type=:debit>,
  #      #<Transaction @amount=70, @recipient=:lender, @type=:credit>,
  #      #<Transaction @amount=30, @recipient=:platform, @type=:credit>
  #    ]

  # Calling `debit_transactions` before `transactions` returns an array of only debit transactions
  rental_02.debit_transactions
  # => [
  #      #<Transaction @amount=100, @recipient=:borrower, @type=:debit>
  #    ]

  rental_02.transactions
  # => [
  #      #<Transaction @amount=100, @recipient=:borrower, @type=:debit>
  #    ]

  # oops
{% endhighlight %}

Let's break down the unexpected behavior:
- Calling `debit_transactions` populate the instance variable `@transactions`.
- Then, calling `transactions` returns early with our instance variable `@transactions` because it's already populated.
- We never compute `credit_transactions` (as we should).

By moving one private method into the public scope, we realized that our initial procedure would eventually come back to bite us in the back.

When I initially wrote this code, I did not give it a second thought. Why would I? Private methods aren't supposed to be called directly, duh! Oh, do I have some news for you, Remi. They won’t be called, yet! But at some point, they just might be.

This is why, even when you’re writing your methods in the private scope, you should ask yourself: <mark><strong>What would happen if this method was in the public scope?</strong></mark>

## Adding some boundaries

Well, private methods mutating an instance variable defined by another method is a problem. [Boundaries are important](https://www.youtube.com/watch?v=aSFvJbSQdA4){:target="\_blank"}, let's add some[^1].

{% highlight ruby %}
  class Rental
    def transactions
      @transactions ||= debit_transactions + credit_transactions
    end

    private

    def debit_transactions
      @debit_transactions ||= [Transaction.new(:borrower, :debit, 100)]
    end

    def credit_transactions
      @credit_transactions ||= begin
        transactions = []

        transactions << Transaction.new(:lender, :credit, 70)
        transactions << Transaction.new(:platform, :credit, 30)
      end
    end
  end
{% endhighlight %}

Aaah, that’s much better.

First, each method has its own instance variable and memoization strategy.

Second, no other method is trying to mutate an instance variable defined by another method. Those methods now are **idempotent**, meaning that they will produce the same result, no matter how many times they are called.

Third, if I were to remove the `private` scope and make all methods public, **I would not get side effects**.

Lastly, just look at how clean the whole code is.

## Key points

Let's wrap it up:
- Treat private methods as if they were public methods.
- Do not let one method mutates the instance variable owned by another method.
- Beware of hidden procedures that could have side effects later down the road.

Y'all be careful with your private methods.

Cheers,

Rémi - [@remi@ruby.social](https://ruby.social/@remi)

[^1]: For the more serious reader, please refer to the concept of [legacy seams](https://martinfowler.com/bliki/LegacySeam.html){:target="\_blank"}.
