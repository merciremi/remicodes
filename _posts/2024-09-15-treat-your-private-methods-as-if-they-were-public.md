---
layout: post
title: "What if your private method was a public method? A practical tip to identify bad design"
excerpt: Where I share a badly designed piece of code, think about what process I can use to reveal its flaws, and how to make it better.
date: 2024-09-16
permalink: /private-methods-public-methods/
category: ruby
cover_image: "/media/2024/09/remi-mercier-private-methods-public-methods.png"
---

Today, we're going to review a badly designed piece of code I once wrote, and think about a practical tip we can use to reveal its flaws, and how to make it better.

Let’s consider the following:

A `lender`  can lend an object to a `borrower` through a `rental`. At the end of the rental, we need to know the transactions related to a rental: where should we debit the money, and where should we credit it?

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

Let's break down the steps:

When initializing a `Rental`, we instantiate an empty array assigned to the instance variable `@transactions`.

To get the transactions, we call `Rental#transactions`. The method first checks if the instance variable `@transactions` is already populated. If so, `transactions` returns early with the content of the instance variable. If not, the method computes the debit transactions and the credit transactions.

As of now, this code works. But its design is problematic.

## Booby-trapping the future

Given the wrong circumstances, `Rental#transactions` could behave unexpectedly.

Here's a methodology trick to help you uncover the code smell:

> What would happen if we made `Rental#debit_transactions` public instead of private?

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

  # Calling `debit_transactions` before `transactions` returns an array
  # of debit transactions only.
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

Let's break it down:
- Calling `debit_transactions` populate the instance variable `@transactions`.
- Then, calling `transactions` returns early with our instance variable `@transactions` because it's already populated.
- We never compute `credit_transactions` (as we should).

This behavior is a sign that `transactions` is not **idempotent**.

> Idempotency means that a method will **always return the same result**, no matter how many times it's called.

Right now, the return value of `transactions` is somewhat safeguarded by the fact that `debit_transactions` and `credit_transactions` are private. But if the access control of these two methods was to change, `transactions` would become dependent on the order of execution of our code.

<mark>By imagining one private method as a public method, we revealed the bad design and realized it would eventually come back to bite us in the back.</mark>

## How do we fix it: making the methods idempotent

First, we need to ensure that `debit_transactions` and `credit_transactions` have consistent return values.

Instead of filling up `@transactions`, they'll both return an array, each populated with its own type of transactions.

{% highlight ruby %}
  class Rental
    # ...

    private

    def debit_transactions
      [Transaction.new(:borrower, :debit, 100)]
    end

    def credit_transactions
      [
        Transaction.new(:lender, :credit, 70),
        Transaction.new(:platform, :credit, 30)
      ]
    end
  end
{% endhighlight %}

Then, `transactions` will only focus on concatenating the return values from `debit_transactions` and `credit_transactions`, and assign it to the instance variable `@transactions`.

I've added a touch of memoization to prevent the recalculation of all transactions, and avoid appending duplicated transactions to our instance variable (the initial problem stated that transactions would only be computed at the very end of the rental lifecyle).

{% highlight ruby %}
  class Rental
    def transactions
      @transactions ||= debit_transactions + credit_transactions
    end

    private

    def debit_transactions
      [
        Transaction.new(:borrower, :debit, 100)
      ]
    end

    def credit_transactions
      [
        Transaction.new(:lender, :credit, 70),
        Transaction.new(:platform, :credit, 30)
      ]
    end
  end
{% endhighlight %}

That’s much better!

All methods are now idempotent. They will return the same result, no matter how many times they're called, no matter the order of execution.

Lastly, if I were to remove `private` and make all methods public, they would keep working as expected. In this case, `private` merely acts as bouncer between the public interface, and the private implementation.

## Key points

This example was contrived by design. Often, these code smells hide in the midst of a larger application.

Let's wrap it up:
- Don't turn your private scope into a junk drawer.
- Make your methods idempotent as much as possible.
- Avoid methods mutating the instance variable defined in another method (A note on this one: initial readers disagree on this one)[^1].
- Beware of hidden side effects that could pop up later down the road.

Y'all be careful with your private methods.

Cheers,

Rémi - [@remi@ruby.social](https://ruby.social/@remi)

ps: Big thank you to Zachery Hostens and [Jeremy](https://ruby.social/@notgrm){:target="\_blank"} for their thoughtful feedback.

[^1]: For the more serious reader, please refer to the concept of [legacy seams](https://martinfowler.com/bliki/LegacySeam.html){:target="\_blank"}.
