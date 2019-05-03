---
layout: post
title: "Meet your new friend: self"
excerpt: "tl;dr: When you're new to coding, it's not always easy to know where the fuck you are in your code. Well, call the most unexpected friend to the rescue: self!"
permalink: your-new-friend-self
---

When coding, it's not always easy to know what's what. Why can't I call that method on this array? When in a method, what am I working with exactly? In these cases, `self` can prove a super-duper friend!

Even if [you're a junior developer]({{site.baseurl}}/daily-recap-coding-bootcamp/), you've probably come across `self` in class methods definition.

{% highlight ruby %}
class Hello
  def self.from_the_class
    "👋 from the class method."
  end
end

Hello.from_the_class # => "👋 from the class method."
{% endhighlight %}

But that usually it.

Now, `self` can also come in handy when your understanding of what's going on is a bit muddy. Let's code something!

Say I want to recode the `.map` method.

{% highlight ruby %}
  # Native method
  p [1, 2, 3].map { |integer| integer * 2 } # => [2, 4, 6]

  # Let's write our own!
  p [1, 2, 3].my_map { |integer| integer * 2 }
{% endhighlight %}

First thing I'll do is to start by defining `.my_map` and have it output something nice.

{% highlight ruby %}
  def my_map
    "Hello from my_map"
  end

  p [1, 2, 3].my_map { |integer| integer * 2 }
{% endhighlight %}

What I expect, when running this code, is to get `"Hello from my_map"`.

{% highlight zsh %}
  NoMethodError: private method `.my_map` called for [1, 2, 3]:Array
  from (pry):8:in `<main>`
{% endhighlight %}

🤔 Duh.

What does it mean by private method? Let's output our current context (i.e. where the hell we are) with `self`.

{% highlight ruby %}
  p "Where are in: #{self}"

  def my_map
    "Hello from my_map"
  end

  p [1, 2, 3].my_map { |integer| integer * 2 }
{% endhighlight %}

{% highlight zsh %}
  "Where are in: main"
  NoMethodError: private method `my_map` called for [1, 2, 3]:Array
  from (pry):8:in `<main>`
{% endhighlight %}

`main` means that we currently are in the context of the Object object. Remember when you were told that all things in Ruby are objects? Well, even Object is an object.

<span class="highlight">Ruby top classes (or objects) are BasicObject > Kernel > Object.</span>

<span class="highlight">BasicObject is the parent class of all classes in Ruby.</span> Basic methods like `==`, `!`, `!=`, `equal?` are defined there. <span class="highlight">Kernel is a module with basics public/private methods</span> like `puts`, `gets` or `chomp`. <span class="highlight">Object inherits from BasicObject and mixes in the Kernel module for good measure. All other Ruby objects inherit from Object. This way, Ruby objects get tons of methods, the latter being defined at the appropriate level of abstraction.</span> Some methods from Object include: `to_s` or `nil?`. Fancy right?

Ok, but what about that `NoMethodError` of mine?

Here's my mistake: I've forgot to write `.my_map` in a class. So it's been defined in the Object object by default. And yet, I'm trying to call `.my_map` on an array.

In order to call `.my_map` on an array, I need to open and define it in the Array class.

{% highlight ruby %}
class Array
  p "Where are in: #{self}"

  def my_map
    "Hello from my_map"
  end
end

p [1, 2, 3].my_map { |integer| integer * 2 }
{% endhighlight %}

{% highlight zsh %}
  Where are in: Array
  Hello from my_map
{% endhighlight %}

👏 It works! Classes in Ruby can be opened and modified. Now that I've defined `.my_map` inside the Array class, I can call it on arrays. Easy peasy!

<span class="highlight">A side note: If you feel like it, you can modify the real `.map` and make it do weird things too.</span>

Alright, now I want to pass the `{ |integer| integer * 2 }` block to `.my_map`. I know I should loop through the array and yield the block at some point. But since I'm not passing the array as an argument, where am I to call `.each` on it?

Let's see what `self` has to say.

{% highlight ruby %}
class Array
  def my_map
    # Instantiate an empty array to store results
    results = []
    # Output yield to see the current context
    "Where are in: #{self}"
  end
end

p [1, 2, 3].my_map { |integer| integer * 2 }
{% endhighlight %}

{% highlight zsh %}
  "Where are in: [1, 2, 3]"
{% endhighlight %}

When we are in `.my_map`, the default value we're working with is the array `.my_map` was called upon. I now know I can call `.each` on `self` (i.e. `[1, 2, 3]`).

{% highlight ruby %}
class Array
  def my_map
    results = []
    # Loop through the array and output yield just to see what's what
    self.each do |i|
      yield
    end
  end
end

p [1, 2, 3].my_map { |integer| integer * 2 }
{% endhighlight %}

{% highlight zsh %}
  NoMethodError: undefined method `*' for nil:NilClass
  from (pry):94:in `block in <class:Array>'
{% endhighlight %}

First, I can read from the error message that I'm in the `<class:Array>`. That's good. Now, what about this `NoMethodError: undefined method '*' for nil:NilClass`? Well, it simply says that in the NilClass [^1], there are no methods `*` defined [^2].

It means that my block `{ |integer| integer * 2 }` can't execute the multiplication because the `integer` variable inside it is `nil`. `yield` can take arguments though. So inside the loop, I'll just pass the current integer - `i` - to `yield`.

{% highlight ruby %}
class Array
  def my_map
    results = []
    # Loop through the array and execute the block
    self.each do |i|
      # Give yield the current integer and store result in array
      results << yield(i)
    end
    # Return final array
    results
  end
end

p [1, 2, 3].my_map { |integer| integer * 2 }
{% endhighlight %}

{% highlight zsh %}
  [2, 4, 6]
{% endhighlight %}

Which can be refactored like this:

{% highlight ruby %}
class Array
  def my_map
    results = []
    # Loop through the array and execute the block
    each { |i| results << yield(i) } # self is implicite so I can remove it
    results
  end
end

p [1, 2, 3].my_map { |integer| integer * 2 }
{% endhighlight %}

🥳 Done!

`self` is also pretty useful to figure out the scopes of your variables. But that'll do for another article.

The key takeaway for today is: Next time you don't know where the fuck you are in your code, call `self` to the rescue!

Cheers,

Rémi

[^1]: Yes, `nil` also has its own class.
[^2]: Yes, `*` is a method defined on specific objects 🤪. To check if NilClass has the `*` method defined, run `NilClass.public_methods.include? '*'` and `NilClass.private_methods.include? '*'` in `irb`.

