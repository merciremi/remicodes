---
layout: post
title: 'RSpec 101: naming files and understanding their structure'
date: 2021-03-04
excerpt: "When you learn development, it's not easy to know how to test, what to test, why should you test? Today, we'll check the first to writing tests with RSpec."
permalink: /rspec-101-basic-set-up/
---

When you learn development, it's not easy to know how to test, what to test, why should you test? You're probably taught that TDD (as in Test Driven Development) is THE best practice. But when you're starting out development, you don't know your head from your bottom, let alone what your code should do before you're writing it.

Testing is also a skill that requires a bit of practice to discover its potential. When I started testing, I'd copy other people's tests because, well, I had to test right? But after a while, my tests would reveal edge cases, potential bugs I'd over-looked.

I feel like a series of short know-hows, know-whats and know-whys could be of some use to newcomers. Synthetic essais around one aspect of testing with RSpec. If this sounds fun to you, let's start with the basics.

## What is RSpec?

RSpec is one of the several testing frameworks used in Ruby and Rails applications. You might also know Minitest.

## Adding RSpec to your application

First, add RSpec to your gemfile.

{% highlight ruby %}
  # Gemfile

  gem "rspec-rails", group: [:development, :test]
{% endhighlight %}

Install the gem with

{% highlight zsh %}
  bundle install
{% endhighlight %}

Then scaffold RSpec's configuration and tell Rails that the default testing framework in RSpec.

{% highlight zsh %}
  rails generate rspec:install
{% endhighlight %}

Now, run your migrations and prepare your test database.

{% highlight zsh %}
  rails db:migrate && rails db:test:prepare
{% endhighlight %}

There! Now, you can run `rspec spec` (`spec` being the folder where all your tests will be).

## Naming your RSpec files

RSpec naming convention is super straightforward: append `_spec` to the file you're testing.

- `users_controller.rb` is tested by `users_controller_spec.rb`
- `user.rb` is tested by `user_spec.rb`
- `user_notification_job.rb` is tested by `user_notification_job_spec.rb`

## The structure of your RSpec files

Let's say we want to test our `User` model. Our file's structure would look like this:

{% highlight ruby %}
  # user_spec.rb

  require 'rails_helper'

  RSpec.describe User do
    # test stuff
  end
{% endhighlight %}

Let's check each element.

- `require 'rails_helper'` loads the file where lies the configuration for RSpec. `rails_helper.rb` is located at the root of the `spec` folder. RSpec is configured out of the box. Sweet!

- `RSpec` is the core module for all RSpec code. It encapsulates and loads a lot of things on instantiation: configuration, expectations, examples, etc. You can check out the code [here](https://github.com/rspec/rspec-core/blob/main/lib/rspec/core.rb#L41){:target="\_blank"}.

- `.describe` is a class method defined on the `RSpec` module. It regroups your tests around a common abstraction: a class, a request, etc. In the example above, our abstraction is the `User` model.

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

It's a bit hard to read because of the metaprogramming bits but the main idea is that it defines the `.describe` instance method in the `RSpec::Core::ExampleGroup` class with the abstraction you're testing (`*args`) and your tests (`example_group_block`) as arguments.

- `User` is the class you're testing. It's passed as an argument to the `.describe` method.

- `do ... end` is the block where you're writing your tests. These will be passed as a second argument to the `.describe` method.

There! You're done. Your tests structure is in place. Next time, we'll write our first tests!

Noticed something? [Ping me on Twitter](https://twitter.com/mercier_remi) or [create an issue on GitHub](https://github.com/merciremi/remicodes/issues/new).

Cheers,

Rémi
