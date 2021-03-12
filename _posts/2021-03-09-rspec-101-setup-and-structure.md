---
layout: post
title: 'RSpec fundamentals: setup, naming and basic structure'
date: 2021-03-09
excerpt: "When you start programming, it's not easy to know what to test, how to test, and why should you test? So let's start with the basics: a basic setup and exploring your tests structure."
permalink: /rspec-101-basic-set-up/
---

When you start programming, it's not easy to know what to test, how to test, and why should you test? You've probably heard that TDD (as in Test Driven Development) is THE best practice. But at first, it's hard to know what your code should do before you're writing it.

Testing requires practice to reveal its potential.

When I started programming, I'd copy other people's tests because, well, I had to test, right? But after a while, my tests would uncover edge cases, potential bugs I'd overlooked.

So, I feel a series of short know-hows, know-whats and, know-whys, could be of some use to newcomers; brief essays explaining one aspect of testing with RSpec.

If this sounds fun to you, let's start with the basics.

## What is RSpec?

First, let's begin with the obvious question: what is RSpec?

<mark>RSpec is a testing framework built in Ruby to test Ruby code. It focuses on testing the behavior of your program: what am I feeding my code? What do I expect to come out?</mark>

It's one of several testing frameworks available out there. You might also know Minitest.

## Adding RSpec to your application

The RSpec team maintains a gem, making it easy to use the framework in Rails applications.

First, add RSpec to your Gemfile.

{% highlight ruby %}
  # Gemfile

  gem "rspec-rails", group: [:development, :test]
{% endhighlight %}

Install the gem.

{% highlight zsh %}
  bundle install
{% endhighlight %}

Scaffold RSpec's configuration and switch your application's testing framework to RSpec.

{% highlight zsh %}
  rails generate rspec:install
{% endhighlight %}

Now, run your migrations and prepare your test database.

{% highlight zsh %}
  rails db:migrate && rails db:test:prepare
{% endhighlight %}

There! Now, you can run your tests by typing `rspec spec` in your shell. `spec` is the folder where you'll create your test files.

## Naming your RSpec files

RSpec naming convention is straightforward:

- `users_controller.rb` is tested by `users_controller_spec.rb`
- `user.rb` is tested by `user_spec.rb`
- `user_notification_job.rb` is tested by `user_notification_job_spec.rb`

## Architecturing your spec folder

To make sure RSpec and Rails work smoothly together, <mark>mimick the structure of your `app` folder.</mark>

{% highlight zsh %}
  my_app_directory
  |
  |- app
  |  |
  |  |- models
  |     |
  |     |- user.rb
  |
  |- spec
     |
     |- models
        |
        |- user_spec.rb
{% endhighlight %}

- `app/models/user.rb` is tested by `spec/models/user_spec.rb`
- `app/serializers/admin/book_serializer.rb` is tested by `spec/serializers/admin/book_serializer_spec.rb`
- and so on.

When testing an API's controllers, you can write your tests in the `spec/requests` folder.

## The structure of your RSpec files

Let's say we want to test our `User` model. Our file's structure would look like this:

{% highlight ruby %}
  # spec/models/user_spec.rb

  require 'rails_helper'

  RSpec.describe User do
    # test stuff
  end
{% endhighlight %}

There! Your setup is done.

But now, I'd like us to dig into each element so we get a better understanding of what's going on.

- `require 'rails_helper'` loads the configuration for RSpec. `rails_helper.rb` is located at the root of the `spec` folder. RSpec is configured out of the box so no need to worry about it.

- `RSpec` is the core module for all RSpec code. It encapsulates and loads a lot of things on instantiation: configuration, expectations, examples, etc. You can check out the code [here](https://github.com/rspec/rspec-core/blob/main/lib/rspec/core.rb#L41){:target="\_blank"}.

- `.describe` is a class method defined on the `RSpec` module. It groups your tests around a common abstraction: a class, a request, etc. In the example above, our abstraction is the `User` model.

The code below is from [the RSpec repository](https://github.com/rspec/rspec-core/blob/fe3084758857f0714f05ada44a18f1dfe9bf7a7e/lib/rspec/core/dsl.rb#L42){:target="\_blank"}.

{% highlight ruby %}
  def self.expose_example_group_alias(name)
    return if example_group_aliases.include?(name)

    example_group_aliases << name

    (class << RSpec; self; end).__send__(:define_method, name) do |*args, &example_group_block|
      group = RSpec::Core::ExampleGroup.__send__(name, *args, &example_group_block)
      RSpec.world.record(group)
      group
    end

    expose_example_group_alias_globally(name) if exposed_globally?
  end
{% endhighlight %}

It's a bit hard to read because of the metaprogramming bits, but the main idea is that it defines the `.describe` instance method in the `RSpec::Core::ExampleGroup` class with the abstraction you're testing (`User`) and the tests you wrote as arguments.

- `User` is the class you're testing. It's passed as an argument to the `.describe` method.

- `do ... end` is the block where you're writing your tests. These will be passed as a second argument to the `.describe` method (see `&example_group_block` above).

I hope these explanations will give you a better understanding of how RSpec works. Next time, we'll write our first tests.

Noticed something? [Ping me on Twitter](https://twitter.com/mercier_remi) or [create an issue on GitHub](https://github.com/merciremi/remicodes/issues/new).

Cheers,

Rémi
