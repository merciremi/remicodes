---
layout: post
title: 'RSpec fundamentals: a basic glossary'
---

This post is part of a - hopefully - larger series about RSpec fundamentals. If you haven't read the first part - [how to setup, naming files and, digging into their basic structure]({{site.baseurl}}/rspec-101-basic-set-up/), please do so.

In this second part, I want to explore the methods you'll most use when testing with RSpec.

## describe

We've already dig into the inner workings of `describe` in the first post. I'll just sum up its main idea.

`describe` is used to group your tests around a common abstraction: a class, a request, etc. You describe _something_.

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

{% highlight ruby %}
  # spec/models/user_spec.rb

  require 'rails_helper'

  RSpec.describe User, type: :model do
    let(:user) { User.create(first_name: 'Buffy', last_name: 'Summers') }

    describe '#full_name' do
    end
  end
{% endhighlight %}

## subject named_subject

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

## subject named_subject

{% highlight ruby %}
  # spec/models/user_spec.rb

  require 'rails_helper'

  RSpec.describe User, type: :model do
    describe '#full_name' do
      subject { user.full_name }
    end
  end
{% endhighlight %}


## let let!
## it xit
## expect
## described_class


- let + let!
- context + describe
- it '' do end
- expect (put onliner in another post)
