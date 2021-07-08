---
layout: post
title: WTF is time complexity? 🤔
excerpt: People who learn web development through coding bootcamp aren't (usually) familiar with time complexity. They might have read the words, but that's it. I know I tried to look up the Wikipedia page only to fall asleep at the end of the first paragraph. When I finally woke up, I thought "Nevermind, I'll never have to deal with it anyway". And boy, was I wrong.
category: 'other'
permalink: /wtf-time-complexity/
---

Here's a subject I never thought I'd write about. But life is full of surprises.

People who learn web development through coding bootcamp aren't (usually) familiar with time complexity. They might have read the words, but that's it. I know I tried to look up [the Wikipedia page](https://en.wikipedia.org/wiki/Time_complexity) only to fall asleep at the end of the first paragraph. When I finally woke up, I thought "Nevermind, I'll never have to deal with it anyway".

And boy, was I wrong. I was soon asked during a coding interview to write a pairing algorithm and to calculate its time complexity 🤔. It made me realize that time complexity is more than just a fancy word thrown by an engineer to make you sweat. Knowing the gist of it can be useful outside the coding-interviews-world too.

So, for all my fellow bootcampers out there, here are the very basics of time complexity - so you can shine like a diamond during your next cocktail party.

## Time complexity for noobs

<blockquote>Time complexity is how you measure your code's execution time depending on the size of the input.</blockquote>

That's it. You can stop reading right now and go back to your life.

Still with me? Ok, wannabe-CS-nerd, here's an example:

- If your code handles a 10-integer array and a 10,000-integer array during the same amount of time, well done, your code's time complexity is 👌.
- If your code takes 100x longer to handle a 10x larger array, sorry, your code's time complexity is 💩 [^1].


## A much-needed example

Let's take the coding interview classic I had to tackle:

Say you get an array of 10,000 random integers, positive and negative. You want to get all couples (without duplicates) of elements summing to a given number.

Here's a first solution:

{% highlight ruby%}
  def find_pairs(array, sum)
    array.repeated_combination(2).find_all { |a, b| a + b == sum }.uniq
  end
{% endhighlight %}

Let's break it down:
- `repeated_combination(2)` generates an enumerator containing all repeated pairs of integers from the 10,000 array (roughly 50,000,000 elements 😱).
- The `find_all` returns an array with all occurrences checking the block.
- `uniq` removes the duplicated pairs

But what's more important is: how much time does this method take to run depending on the size of the input?

We'll benchmark our code with [benchmark-ips](https://github.com/evanphx/benchmark-ips). This gem provides you with the number of time your code runs per second.

To add `benchmark-ips`, first run:

{% highlight zsh %}
  gem install benchmark-ips
{% endhighlight %}

Then add the benchmark to your code. Here, I'll run my `find_pairs(array, sum)` with four different inputs:
- a 10-integer array
- a 100-integer array
- a 1,000-integer array
- a 10,000-integer array

{% highlight ruby%}
  require 'benchmark/ips'

  def find_pairs(array, sum)
    array.repeated_combination(2).find_all { |a, b| a + b == sum }.uniq
  end

  ########################
  # COMPLEXITY BENCHMARK #
  ########################

  # Set up

  FIRST_ARRAY = Array.new(10) { rand(-10...20) }
  SECOND_ARRAY = Array.new(100) { rand(-100...200) }
  THIRD_ARRAY = Array.new(1000) { rand(-1000...2000) }
  FOURTH_ARRAY = Array.new(10_000) { rand(-10_000...20_000) }

  # Time complexity benchmark

  Benchmark.ips do |x|
    x.config(:time => 5, :warmup => 2)

    # Typical mode, runs the block as many times as it can
    x.report("find pairs in 10-integer array") {
      find_pairs(FIRST_ARRAY, 8)
    }

    x.report("find pairs in 100-integer array") {
      find_pairs(SECOND_ARRAY, 87)
    }

    x.report("find pairs in 1000-integer array") {
      find_pairs(THIRD_ARRAY, 876)
    }

    x.report("find pairs in 10_000-integer array") {
      find_pairs(FOURTH_ARRAY, 8765)
    }

    x.compare!
  end
{% endhighlight %}

Here's the output:

{% highlight zsh %}
  Warming up --------------------------------------
  find pairs in 10-integer array
                          10.685k i/100ms
  find pairs in 100-integer array
                         137.000  i/100ms
  find pairs in 1000-integer array
                           1.000  i/100ms
  find pairs in 10_000-integer array
                           1.000  i/100ms
  Calculating -------------------------------------
  find pairs in 10-integer array
                          112.738k (± 1.5%) i/s -    566.305k in   5.024381s
  find pairs in 100-integer array
                            1.388k (± 2.2%) i/s -      6.987k in   5.036686s
  find pairs in 1000-integer array
                           14.208  (± 0.0%) i/s -     72.000  in   5.069451s
  find pairs in 10_000-integer array
                            0.138  (± 0.0%) i/s -      1.000  in   7.241235s

  Comparison:
  find pairs in 10-integer array:   112737.7 i/s
  find pairs in 100-integer array:     1388.0 i/s - 81.22x  slower
  find pairs in 1000-integer array:       14.2 i/s - 7934.72x  slower
  find pairs in 10_000-integer array:        0.1 i/s - 816360.51x  slower
{% endhighlight %}

😓 As you can see, it takes my code 80x longer to run between a 10-integer array and a 100-integer array. But then, it takes 100x longer between the 100-integer array and the 1,000-integer array. And 100x longer between the 1,000-integer array and the 10,000-integer array.

<!-- Make graph -->

It's safe to say that its time complexity is 💩.

You can already picture the user looking at a blank screen for 10 seconds while your code runs. And that, friends, is not good at all.

## Moving from the "👌 and 💩" notation to the Big-0 notation

Time complexity has its own scale: the Big-0 notation [^2].

From best to worst:

- `0(1)`: the size of the input doesn't impact your code's runtime
- `0(log n)`: 10x the input and your code takes 2x longer to run
- `0(n)`: 10x the input and your code takes 10x longer to run
- `0(n log n)`: 10x the input and your code takes 50x longer to run
- `0(n^2)`: 10x the input and your code takes 100x longer to run
- `0(2^n)`: 10x the input and your user has fallen asleep while your code still runs

There's really no need to learn it by heart or to be able to calculate the right Big-0 on top of your head (the first reason is: [CS engineers and math nerds don't even agree on the calculus](https://www.reddit.com/r/programming/comments/1dotwe/bigo_cheat_sheet/c9si8pj/)).

It's better to understand some rules of thumb:
- the `n` refers to the **input size**
- if you iterate once on an array, the time to run is linearly proportional on the number of elements in the array (hence `0(n)`)
- code with a 2-level nested loop usually fits the `0(n^2)` (code with a 3-level nested loop would be `0(n^3)` and so on)
- time complexity indicates possible performance issues based on the input size

If you want to get a more in-depth explanation, go and check [A Rubyist's Guide to Big-O Notation by Honeybadger](https://blog.honeybadger.io/a-rubyist-s-guide-to-big-o-notation/). It's neat 👌.

## Getting back to our real-life example

Remember that?

{% highlight ruby%}
  def find_pairs(array, sum)
    array.repeated_combination(2).find_all { |a, b| a + b == sum }.uniq
  end
{% endhighlight %}

To calculate the time complexity of a piece of code, you just define the time complexity of each element, and the worst bit wins. So let's break down `find_pairs()` and see what's going on under the hood.

#### ☝️ First, let's create a 4-integer array

{% highlight ruby %}
  array = Array.new(4) { rand(-10...20) } # => [-6, 4, 14, 3]
{% endhighlight %}

#### ✌️ Then, let's define a method `find_pairs()` and call `repeated_combination(2)` on the array to create pairs

{% highlight ruby %}
  array = Array.new(4) { rand(-10...20) } # => [-6, 4, 14, 3]

  def find_pairs(array, sum)
    # Calling repeated_combination without a block returns an enumerator
    array.repeatead_combination(2)
  end

  # I add a to_a to transform my enumerator into an array for readability reasons
  find_pairs(array, 8).to_a # => [[-6, -6], [-6, 4], [-6, 14], [-6, 3], [4, 4], [4, 14], [4, 3], [14, 14], [14, 3], [3, 3]]
{% endhighlight %}

Let's stop there for a moment. `repeated_combination(2)` iterates over each element in `array` and pair it with each element of `array`. `repeated_combination(2)` creates a nested-loop.

The first loop first stops on `-6` then a second loop starts and iterates over each element. Once the second loop is done, we get back to the first loop which moves onto `4` where the second loop kicks in again. Rinse and repeat until `repeated_combination(2)` has iterated over each element and returned all combinations.

A loop inside a loop? 👉 The time complexity of this method is `0(n^2)`.

#### ☝️✌️ Now let's `find_all` pairs whose integers sum to a given number.

{% highlight ruby %}
  array = Array.new(4) { rand(-10...20) } # => [-6, 4, 14, 3]

  def find_pairs(array, sum)
    all_pairs = array.repeatead_combination(2).find_all { |a, b| a + b == sum }
  end

  find_pairs(array, 8) # => [[-6, 14], [4, 4]]
{% endhighlight %}

`find_all` iterates over the enumerator returned by `repeated_combination(2)` and checks for pairs that match the block.

A single loop means `0(n)`. Since `0(n)` is much faster than the `O(n^2)` from `repeated_combination(2)`, it will be of little consequence in the grand scheme of things.

#### ✌️✌️ Finally, let's remove duplicates with `uniq`

{% highlight ruby %}
  array = Array.new(4) { rand(-10...20) } # => [-6, 4, 14, 3]

  def find_pairs(array, sum)
    all_pairs = array.repeatead_combination(2).find_all { |a, b| a + b == sum }.uniq
  end

  find_pairs(array, 8) # => [[-6, 14], [4, 4]]
{% endhighlight %}

In this example, we don't have any duplicates. But when you run the algorithm on a 10,000-integer array, chances you'll have some.

`uniq` only iterates once on the array, so it's time complexity is `0(n)`. Once again, it won't affect much the time complexity of the whole method.

#### 🖐 Crunching the numbers

Now that we know the time complexity of each element, let's calculate the complexity of the whole method.

`0(n^2)` + `0(n)` + `0(n)` = `0(n^2)`

As I said before `0(n)` is so much faster than `0(n^2)` that it won't affect the final time complexity substantially.

So now, I know that my code's time complexity is `0(n^2)`. You can stick with my 💩 notation but `0(n^2)` will make you look slightly smarter.

This is where knowing the gist of time complexity comes in handy. If you know your code becomes exponentially slower when the input grows, then you know you'll have performance issues when you scale. So you have to make your code better.

## Making the algorithm better

Instead of using some of Ruby's built-in methods, I'll use [Set](https://devdocs.io/ruby~2.5/set). Set creates a collection of unordered values without duplicates with fast lookup capabilities.

{% highlight ruby %}
  require 'set'

  def find_pairs(array, sum)
    results = Set.new
    input = array.to_set

    input.each do |element|
      other_element = sum - element
      if input.include?(other_element)
        pair = element > other_element ? [other_element, element] : [element, other_element]
        results << pair
      end
    end
    results
  end
{% endhighlight %}

Let's break it down:
- I create an empty Set to store `results`.
- I transform my input array into a Set and store it into `input`.
- I iterate over `input`.
- I take the first integer (`element`) and subtract it from `sum`. This gives me a potential pairing integer (`other_element`).
- If `other_element` is included in `input` (my input array turned to a Set), then I make sure that `element` and `other_element` are paired from smallest to biggest, and pushed in `results`. Why bother to sort them? Because if I have duplicates, `results` being a Set will only keep the first occurrence 👌.

Here's the benchmark for this new code:

{% highlight zsh %}
  Warming up --------------------------------------
  find pairs in 10-integer array
                           8.171k i/100ms
  find pairs in 100-integer array
                           1.533k i/100ms
  find pairs in 1000-integer array
                         146.000  i/100ms
  find pairs in 10_000-integer array
                          14.000  i/100ms
  Calculating -------------------------------------
  find pairs in 10-integer array
                           80.106k (± 8.6%) i/s -    400.379k in   5.037247s
  find pairs in 100-integer array
                           14.005k (±12.4%) i/s -     68.985k in   5.026938s
  find pairs in 1000-integer array
                            1.540k (± 3.8%) i/s -      7.738k in   5.033787s
  find pairs in 10_000-integer array
                          157.341  (± 2.5%) i/s -    798.000  in   5.074419s

  Comparison:
  find pairs in 10-integer array:    80106.5 i/s
  find pairs in 100-integer array:    14005.1 i/s - 5.72x  slower
  find pairs in 1000-integer array:     1539.6 i/s - 52.03x  slower
  find pairs in 10_000-integer array:      157.3 i/s - 509.13x  slower
{% endhighlight %}

Much better! Now, my code only takes 10x longer to run when the input is multiplied by 10. Its time complexity has become linear (`0(n)`) and takes less than 0,006s to handle a 10,000-integer input 🥳.

Well, that was super geeky. I hope it'll help fellow bootcampers to wrap their head around time complexity and how it can be useful.

Did I missed something? Lemme know on [Twitter](https://twitter.com/mercier_remi),

Rémi


[^1]: Not a **Real Developer™** notation.
[^2]: A **Real Developer™** notation.
