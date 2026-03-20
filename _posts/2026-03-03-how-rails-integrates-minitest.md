---
layout: post
title: "Using Minitest::Spec in Rails? Watch out for the lifecycle hooks!"
excerpt: "A small mistake sent me on an overly long investigation into Minitest hooks, and how Rails integrates with these."
date: 2026-03-03
permalink: /minitest-spec-and-rails-hooks/
category: other
cover_image:
---

After picking up [Minitest]({{site.url}}/introduction-to-minitest/) to complement the QA process of one of my retainer clients, I've had confusing errors in our test suite for a while. We were moving fast to cover critical parts of the application, so we never had the time to investigate the flakiness thoroughly.

While preparing my upcoming talk – Lost in Minitest, the missing guide for Minitest tourists – I dug into how Ruby on Rails pulls in Minitest. And there I found the answers to my burning question: why on Earth does the following test fail?

{% highlight ruby %}
require "test_helper"

class CustomerIdentificationTest < ActionDispatch::IntegrationTest
  before { @customer = customers.buffy }
  
  it "checks proofs of identification" do
    get customer_identification_path(@customer)
    
    assert_response :success
  end
  
  describe "when the customer has already been verified" do
    setup { @customer.update(verified_at: 2.days.ago) }
    
    it "returns a :success response" do
      get customer_identification_path(@customer)
    
      assert_response :success
    end
  end
{% endhighlight %}

These tests look pretty unremarkable: 
  - The main context checks the response status for a new customer.
  - The nested context checks the response for an existing customer.

A few things worth noting:
  - I'm using the `Minitest::Spec` syntax.
  - We're in a Ruby on Rails app (see the `< ActionDispatch::IntegrationTest`).
  - Several people are working on the test files.
    
Wait, what? How did I infer this?

Notice the difference in how each test is set up? The first test uses the `before` block syntax that is part of `Minitest::Spec`. The second test uses the `setup` block syntax, which is the Rails custom syntax. Minitest being pretty lax about conventions, two people used different syntaxes in the same file.

Is it problematic, though? 

{% highlight zsh %}
  $ bin/rails test
  Running via Spring preloader in process 31584
  Run options: --seed 16480
  
  # Running:
  
  .......................E
  
  Error:
  CustomerIdentificationTest::when the customer has already been verified#test_0001_returns a :success response:
  NoMethodError: undefined method 'update' for nil test/integration/customer_identification_test.rb:6:in 'block (2 levels) in <class:CustomerIdentificationTest>'
{% endhighlight %}

Well, looks like it is.

## A detour on picking a standard

I'm big on [picking a standard and moving on]({{site.baseurl}}/pick-a-standard/). But I also know that sometimes, you have to give yourself time to play with things before committing to a guideline.

It's like living in a house: live in it for a while before you start knocking walls down.

Due to the lack of Minitest onboarding, we were careful not to draw rules early on. We wanted to feel where our setup was stretching at the seams. What was working for us and what was not.

Coding with feelings? Why not.

## Back to our failing test

Taking the time to feel our way through our setup allowed us to experiment with our tests. Here's an updated version of the failing test, where I inverted the `setup` and `before` blocks.

{% highlight ruby %}
require "test_helper"

class CustomerIdentificationTest < ActionDispatch::IntegrationTest
  setup { @customer = customers.buffy }
  
  it "checks proofs of identification" do
    get customer_identification_path(@customer)
    
    assert_response :success
  end
  
  describe "when the customer has already been verified" do
    before { @customer.update(verified_at: 2.days.ago) }
    
    it "returns a :success response" do
      get customer_identification_path(@customer)
    
      assert_response :success
    end
  end
{% endhighlight %}

Can you see where this is going?

{% highlight zsh %}
  $ bin/rails test
  Running via Spring preloader in process 57332
  Run options: --seed 23226
  
  # Running:
  
  ...............................................................................................................................................
  
  Fabulous run in 2.511829s, 56.9306 runs/s, 199.8544 assertions/s.
  143 runs, 502 assertions, 0 failures, 0 errors, 0 skips
{% endhighlight %}

Yep, using `setup` first then `before` works. Flip them and it blows up. Let me tell you, this one had me scratch my head for a while.

Okay, why does it fail, then?

Because of how Rails integrates Minitest, specifically in how it resolves the lifecycle hooks of the tests. 

## A dive into Minitest hooks lifecycle

When Minitest executes your code, it runs some hooks around your test setup and your tests' examples. Those hooks are: 
  - empty methods by default
  - meant for library and framework extensions
  - not meant to be used in tests' setup
    
You can check the [Minitest code](https://github.com/minitest/minitest/blob/339492cbaec5c460ec278e754199619d6431af35/lib/minitest/test.rb).

One more thing: the `Minitest::Spec` `before` block [is just syntactic sugar](https://github.com/minitest/minitest/blob/339492cbaec5c460ec278e754199619d6431af35/lib/minitest/spec.rb) for `Minitest::Test#setup`. So both `def setup` and `before` block are equivalent.

{% highlight zsh %}
┌─────────────────────────────────────────┐
│         TEST EXECUTION STARTS           │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│      1. before_setup (hook)             │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│      2. setup (method)                  │
│      - def setup or before block        |
│        are executed here                |
│      - Runs once before each test       │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│      3. after_setup (hook)              │
└─────────────────────────────────────────┘
                    ↓
┌═════════════════════════════════════════┐
║      ★★★ MY TESTS RUN HERE ★★★          ║
└═════════════════════════════════════════┘
{% endhighlight %}

Whether I use the vanilla `def setup` or the `Minitest::Spec` `before` block, Minitest treats them the same. They will both run **after** the `before_setup` hook.

Ruby on Rails, though, makes things muddy.

## Ruby on Rails has entered the chat

In this instance, Rails does two things that will impact my tests:
 - Exposes a `setup` block to use *in lieu of* the `def setup`.
 - Hooks into Minitest by [prepending its own setup strategy](https://github.com/rails/rails/blob/cb91d817a78352fb41e33764d651991d566ae82b/activesupport/lib/active_support/test_case.rb#L219) to `ActiveSupport::TestCase`.

In its setup strategy, it hooks the `setup` block into `before_setup`.

{% highlight ruby %}
  # activesupport/lib/active_support/test_case.rb
  
  module ActiveSupport
    class TestCase < ::Minitest::Test
      Assertion = Minitest::Assertion
      
      class << self
        prepend ActiveSupport::Testing::SetupAndTeardown
      end
    end
  end
  
  # activesupport/lib/active_support/testing/setup_and_teardown.rb
  
  module ActiveSupport
    module Testing
      module SetupAndTeardown
        module ClassMethods
          # Add a callback, which runs before <tt>TestCase#setup</tt>.
          def setup(*args, &block)
            set_callback(:setup, :before, *args, &block)
          end
        end
      end
    end
  end
{% endhighlight %}

What it means for us:
  - We now have three ways of building a setup for our tests: `def setup` (vanilla Minitest), `setup` block (Rails' Minitest), `before` block (`Minitest::Spec`)
  - Each looks pretty similar to the next.
  - Mixing and matching will work most of the time...
  - BUT (!) these blocks are not executed at the same time due to the way Rails plugs its `setup` block in the Minitest lifecycle. So based on the order of declaration, some of my tests will fail!

{% highlight zsh %}
┌─────────────────────────────────────────┐
│         TEST EXECUTION STARTS           │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│      1. before_setup (hook)             |
|    ⚠️ Rails plugs its setup block here  |
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│      2. setup (method)                  │
│      - def setup or before block        |
│        are executed here                |
│      - Runs once before each test       │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│      3. after_setup (hook)              │
└─────────────────────────────────────────┘
                    ↓
┌═════════════════════════════════════════┐
║      ★★★ MY TESTS RUN HERE ★★★          ║
└═════════════════════════════════════════┘
{% endhighlight %}

So when I mix the `setup` block and the `before` block syntaxes in a test file, they are not executed in the order I think they are. 

No matter how deep the `setup` block is nested in my test file, in Rails, it'll always be executed first in the `before_setup` hook.

So the fix to my initial problem is simple: in a Rails app when using `Minitest::Spec`, don’t mix `setup` and `before` blocks.

## Closing thoughts

Funny how such a simple mistake – mixing `setup` blocks and `before` blocks – will have you neck-deep in parts of two codebases to understand what's what.

Of course, this post begs the question: why Rails did not handle the `Minitest::Spec` syntax too?

I don't have a definitive answer, but my guesses are:
  - Harder to inject the `before` block in the `before_setup` without hijacking Minitest (and making the connection brittle)?
  - Because Rails is bullish on the vanilla Minitest syntax and did not want to port the Spec syntax?

If you were one of the contributors who worked on this part of Rails, I'd love to know!

You might have noticed several things in my initial test: 
- Why not use `let` instead of `before | setup`? I used contrived examples for clarity. Usually, I'd use `let` for instantiating data and `before` for additional setup like authentification, stubbing, etc...
- Despite using `Minitest::Spec`, my test class still uses the Rails-styled inheritance – `class CustomerIdentificationTest < ActionDispatch::IntegrationTest` – instead of the `describe CustomerIdentification do` syntax one could expect. This is because `Minitest::Spec` is not set up properly. But this will be a story for another post.

Well, that was quite the rabbit hole! I now know the why behind [some of the gotchas]({{site.url}}/more-minitest-spec/) I'd written previously.

Anyway, I hope you enjoyed this one as much as I enjoyed writing it.

{% include signature.html %}
