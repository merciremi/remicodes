---
layout: post
title: 'RSpec fundamentals: a basic glossary'
---

This post is part of a - hopefully - larger series about RSpec fundamentals. If you haven't read the first part - [how to setup, naming files and, digging into their basic structure]({{site.baseurl}}/rspec-101-basic-set-up/), please do so.

In this second part, I want to explore the methods you'll most use when testing with RSpec. I'll build an example test for a `User` model, and explain key concepts along the way.

## describe

We've already dig into the inner workings of `describe` in the first post. I'll just sum up its main idea.

`describe` is used to group your tests around a common abstraction: a class, a request, etc.

You can - and usually do - nest several `describe`s in one file. An example were we want to test an instance method `#full_name` of the model `User`.

{% highlight ruby %}
  # spec/models/user_spec.rb

  require 'rails_helper'

  RSpec.describe User, type: :model do
    describe '#full_name' do
      # test the output of the method full_name
    end
  end
{% endhighlight %}

The first `describe` is called on the module `RSpec` and describes the `User` class. The second `describe` is called within the example group and describes the method `#full_name`.

The second `describe` is nested in the first one. But both describe _something_: a class, a method.

The emphasis here is important when we'll talk about `context`.

Note how the second `describe` takes a string as an argument. The string is the description of the abstraction your testing. When testing a method, keep the description to the name of the method. Prefix it with a hash or a dot based on the scope of the method:
- `describe '#instance_method_name' do...` for instance methods
- `describe '.class_method_name' do...` for class methods

When your tests run, the arguments of your `describe`s will display like this:

{% highlight zsh %}
  Randomized with seed 4321

  User
    #full_name
{% endhighlight %}

Once we write tests, RSpec will output more details. But for now, let's just remember:

<mark>describe is used to group your tests around a common abstraction. It describes a "what".</mark>

## let let!

`let` is the method that let's you create variable.

{% highlight ruby %}
  # spec/models/user_spec.rb

  require 'rails_helper'

  RSpec.describe User, type: :model do
    let(:user) { User.create(first_name: 'Buffy', last_name: 'Summers') }

    describe '#full_name' do
    end
  end
{% endhighlight %}

Here, we create a variable `user` in which is referenced an instance of `User`.

<!-- why not simply create a variable user? https://mixandgo.com/learn/let-vs-instance-variables-in-rspec -->

The `user` variable will be accessible by the tests in the current context. In the example above, `user` can be accessed by every tests because the `let` is defined at the root of the `RSpec.define` block. This the context which encapsulates all your tests for the class `User`.

ANother example:

{% highlight ruby %}
  # spec/models/user_spec.rb

  require 'rails_helper'

  RSpec.describe User, type: :model do
    let(:user) { User.create(first_name: first_name, last_name: last_name) }

    describe '#full_name' do
      let(:first_name) { 'Buffy' }
      let(:last_name) { 'Summers' }
    end
  end
{% endhighlight %}

Here, `user` is still accessible everywhere, but `first_name: 'Buffy'` and `last_name: 'Summers'` are only accessible by the tests written in the `describe '#full_name'` block.

This allows you to change the value when you need it. We'll see some examples when we write our first tests.

## subject and named_subject

`subject` represents the thing you're testing. For instance, it can be a method.

{% highlight ruby %}
  # spec/models/user_spec.rb

  require 'rails_helper'

  RSpec.describe User, type: :model do
    let(:user) { User.create(first_name: 'Buffy', last_name: 'Summers') }

    describe '#full_name' do
      subject { user.full_name }
    end
  end
{% endhighlight %}

`subject` takes a block in which I call the method `#full_name` on an instance of `User`. It reads as: my subject, is the result of `user.full_name`.

Here, `subject` makes use of my variable `user` defined in the parent context.

`subject` can be a lot of things: a method call, a request to an endpoint, a serialized object, etc. We saw earlier that the testing of the method `full_name` was described by the `describe '#full_name'`. Now, in order to test it, we need to call it. To trigger its behaviour. This is the subject of our tests.

SOmetimes, you need to reference the subject in your test, especially when you expect your subject to change things. The subject can be named to be easier to use in your tests.

{% highlight ruby %}
  # spec/models/user_spec.rb

  require 'rails_helper'

  RSpec.describe User, type: :model do
    let(:user) { User.create(first_name: 'Buffy', last_name: 'Summers') }

    describe '#full_name' do
      subject(:full_name_method) { user.full_name }
    end
  end
{% endhighlight %}

## context

Before I give you a definition, let's check an example.

{% highlight ruby %}
  # spec/models/user_spec.rb

  require 'rails_helper'

  RSpec.describe User, type: :model do
    let(:user) { User.create(first_name: 'Buffy', last_name: 'Summers') }

    describe '#full_name' do
      subject { user.full_name }

      context 'when a user has a first_name and a last_name' do
        # test the output of the method full_name under a specific constraint
      end

      context 'when a user has no last_name' do
        # test the output of the method full_name under another constraint
      end
    end
  end
{% endhighlight %}

Can you guess what `context` does?

<mark>context is used to group your tests around - drum roll 🥁 - a specific context.</mark> I know, it sounds obvious when you spell it out.

If you expect a different output for your method `#full_name` based on a condition, you group your tests in the `context` block.

Some examples of contexts you might use:
- what happens if an attribute is `nil` when I expected a truthy value?
- what happens if the value is not the one I expected
- ...

### When to use describe and when to use context

To be honest, when I first started testing, I would use `describe` and `context` indifferently. Then after a while, I set into a pattern:

- when I test something - a class, a method, an abstraction - I use `describe`.
- when I test how that something fare under a certain circumstance - a missing parameter, an `nil` value, etc - I use `context`

## it xit

{% highlight ruby %}
  # spec/models/user_spec.rb

  require 'rails_helper'

  RSpec.describe User, type: :model do
    let(:user) { User.create(first_name: 'Buffy', last_name: 'Summers') }

    describe '#full_name' do
      subject { user.full_name }

      context 'when a user has a first_name and a last_name' do
        it "returns the user's full name" do
          # test expected behaviour
        end
      end

      context 'when a user has no last_name' do
        it "returns an error" do
          # test the expected behaviour
        end
      end
    end
  end
{% endhighlight %}

## expect

expect, to, eq and variations

{% highlight ruby %}
  # spec/models/user_spec.rb

  require 'rails_helper'

  RSpec.describe User, type: :model do
    let(:user) { User.create(first_name: 'Buffy', last_name: 'Summers') }

    describe '#full_name' do
      subject { user.full_name }

      context 'when a user has a first_name and a last_name' do
        it "returns the user's full name" do
          expect(subject).to eq("Buffy Summers")
        end
      end

      context 'when a user has no last_name' do
        it "returns an error" do
          # test the expected behaviour
        end
      end
    end
  end
{% endhighlight %}

## expectations

eq, contain_exactly, ...

## described_class

<!-- faire gif d'un test qui se remplit par strates logiques -->

