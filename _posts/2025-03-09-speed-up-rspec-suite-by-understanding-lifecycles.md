---
layout: post
title: "Speed up RSpec tests: understand lifecycle and execution"
excerpt: "One of RSpec's strengths is the legibility of its behavior-based DSL. The other side of this coin is that the proliferation of small example blocks  introduces a performance overhead."
date: 2025-03-10
permalink: /aggregate-rspec-expectations/
category: rspec
cover_image: "media/2025/03/faster-rspec-test-suite-remi-mercier.png"
---

One of RSpec's strengths is the legibility of its behavior-based DSL. The other side of this coin is that the proliferation of small example blocks introduces a performance overhead. Why? Because of RSpec test files' lifecycle! I'll describe broadly how RSpec handles a test file, and the performance implications. Then, we'll see how we can make your RSpec tests run faster!

This is an intermediate-level post. If you're unfamiliar with RSpec, [start at the beginning of the series]({{site.baseurl}}/series/rspec/).

## A typical test file

Let's draw a quick `books_controller_spec.rb` that checks the behavior of a `PATCH` action.

{% highlight ruby %}
  RSpec.describe BooksController do
    let(:book) do
      Book.create(title: "The Long Way to a Small, Angry Planet", blurb: nil)
    end

    describe "PATCH /books/:id" do
      let(:action) { patch :update, params: }
      let(:params) { { id: book.id, book: { blurb: } } }
      let(:blurb) do
        "Fleeing her old life, Rosemary Harper joins the multi-species crew of the Wayfarer as a file clerk, and follows them on their various missions throughout the galaxy."
      end

      it "returns an :ok response" do
        action

        expect(response).to have_http_status(:ok)
      end

      it "changes the blurb of the book" do
        action

        expect(book.reload).to eq(blurb)
      end

      it "redirects the user to the /show page" do
        action

        expect(response).to redirect_to("/books/#{book.id}")
      end
    end
  end
{% endhighlight %}

This test file is pretty straightforward:
  - The setup creates a book with a title and no blurb.
  - The tests verify that the `BooksController#update` method works as intended: update the attributes, return the correct response, and check for final redirection.

One question, though. Can you tell how RSpec **actually** runs this test?

## The lifecycle of a test file

Test files are separated into two concepts: **example groups** and **examples**.

**Example groups** are a recursive entity in RSpec. They represent:
  - the logic within `RSpec.describe BooksController do`,
  - the logic within `describe "PATCH /books/:id" do` or `context "when something is different" do`.

**Examples** represent the logic within `it` blocks. And `it` blocks encapsulate **expectations**.

{% highlight ruby %}
RSpec.describe BooksController do                 # <-- top-level example group
    describe "PATCH /books/:id" do                # <-- nested example group
      it "returns an :ok response" do             # <-- example
        expect(response).to have_http_status(:ok) # <-- expectation
      end
    end
  end
{% endhighlight %}

When running a test file, RSpec will:
  - `run` the top-level example group,
  - within `run`, `run_examples`,
  - if the examples are nested example groups, it will `run` recursively,
  - until RSpec can run an actual example, i.e. an `it` block.

Next, for each example (`it` blocks), RSpec does a handful of things [^1]:
  - `run_before_context_hooks`: creates the instance variables (your `let`)  and executes `before` blocks,
  - runs the expectations,
  - generates the report,
  - `run_after_context_hooks`: rollbacks the database and resets the ivars.

In layman's terms, it means that for each `it`, RSpec runs anew all your `let` and `before` blocks, only to discard them all at the end of the process.

Let's check our `book` instance in different `it` groups.

{% highlight ruby %}
  it "returns an :ok response" do
    p book.id # => 1
  end

  it "changes the blurb of the book" do
    p book.id # => 1
  end

  it "redirects the user to the /show page" do
    p book.id # => 1
  end
{% endhighlight %}

At first, I would assume that my `book` is always the same book. And yet.

Let's check the memory pointer associated with my `book`.

{% highlight ruby %}
  it "returns an :ok response" do
    p book.object_id # => 56100
  end

  it "changes the blurb of the book" do
    p book.object_id # => 56220
  end

  it "redirects the user to the /show page" do
    p book.object_id # => 56350
  end
{% endhighlight %}

Uh, what?

What it tells us is that while each `book` _looks_ identical at the database level (same `id`), each Ruby object we're looking at is different (different memory pointer `object_id`).

So, RSpec recreates new Ruby objects for every `it` block.

But what about `book` always having the same `id`?

Most Rails integration of RSpec offers the ability to wrap examples in a database transaction [^2], meaning that once your example has run, the database rolls back to its original state. Hence why you always have `book` with the same `id`.

The TL;DR is that the more `it` blocks you have, the more RSpec has to evaluate your setup, fill your test database with new records, instantiate new Ruby objects, and discard all of it.

While this decouples testing data from the order of test execution, for a lot of everyday tests, this is a tad overkill and slows your test suite down.

Ok, Rémi? So, how do we fix it?

## Aggregate examples and cut setup time

There's a very simple thing you can do, to cut setup time **big time**: aggregate your expectations in fewer examples.

{% highlight ruby %}
  RSpec.describe BooksController do
    let(:book) do
      Book.create(title: "The Long Way to a Small, Angry Planet", blurb: nil)
    end

    describe "PATCH /books/:id" do
      let(:action) { patch :update, params: }
      let(:params) { { id: book.id, book: { blurb: } } }
      let(:blurb) do
        "Fleeing her old life, Rosemary Harper joins the multi-species crew of the Wayfarer as a file clerk, and follows them on their various missions throughout the galaxy."
      end

      it "successfully updates the book", :aggregate_failures do
        action

        expect(response).to have_http_status(:ok)
        expect(book.reload).to eq(blurb)
        expect(response).to redirect_to("/books/#{book.id}")
      end
    end
  end
{% endhighlight %}

Sure, you lose _some_ legibility, but instead of having RSpec build your test setup three times, you only do it once. I'll try and post an update with some benchmarks later on, but this seems quite a big gain especially when used across a whole test suite.

Note that I added the `:aggregate_failures` flag to my `it` block. This tells RSpec to not fail fast, to run all my expectations in the block, and to bundle all my failures together.

That's it! Hope you liked this lengthy yack shaving, as much as I liked writing it!

{% include signature.html %}

PSS: Many thanks to [Sunny](https://boitam.eu/@sunny){:target="_blank"} for sending me down this rabbit hole!

[^1]: You can check the code about `run` [here](https://github.com/rspec/rspec/blob/main/rspec-core/lib/rspec/core/example_group.rb#L599){:target="_blank"}.
[^2]: The code about database migration is [here](https://github.com/rspec/rspec-rails/blob/main/lib/rspec/rails/fixture_support.rb){:target="_blank"}.
