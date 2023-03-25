---
layout: post
title: 'How to test your Rails models with RSpec'
excerpt: "Today, I want to share how to test your Rails models with RSpec. Testing your models is a no-brainer strategy when building your applications. It gives you the confidence to make changes without regressions. We'll cover the fundamental testing strategies with RSpec's built-in features. And for fun, we'll check some extra tools to amp up your models' coverage."
date: 2023-03-27
permalink: /how-to-test-rails-models-with-rspec/
category: rspec
cover_image: '/media/2023/03/how-to-test-rails-models-with-rspec-remi-mercier.png'
---

Today, I want to share __how to test Rails models with RSpec__. Testing your models is a no-brainer strategy when building your applications. It gives you the confidence to make changes without regressions.

We'll cover the fundamental testing strategies with RSpec's built-in features. And for fun, we'll check some extra tools to amp up your models' coverage.

A note: I will not get into [which tests are considered pertinent](https://getaround.tech/non-deterministic-testing/){:target="\_blank"} and [which are not](https://www.codewithjason.com/different-kinds-rails-tests-use/){:target="\_blank"}. This makes for more advanced practice. Keep in mind those opinions exist.

If you're unfamiliar with RSpec, please read the first two posts of this series: [RSpec setup and structure]({{site.baseurl}}/rspec-101-basic-set-up/) and [RSpec glossary]({{site.baseurl}}/rspec-fundamentals-glossary/).

## A Rails model in need of some tests

Let's use a classic example: a `User` model that handles data and behavior.

{% highlight ruby %}
  # app/models/user.rb

  class User < ActiveRecord::Base
    enum gender: { gender_neutral: 0, non_binary: 1, male: 2, female: 3, other: 4 }

    has_many :posts

    validates :gender, inclusion: { in: genders.keys }

    scope :by_gender, ->(gender) { where(gender: gender) }

    def full_name
      "#{formatted_first_name}" #{formatted_last_name}"
    end

    private

    def formatted_first_name
      first_name.capitalize
    end

    def formatted_last_name
      first_name.capitalize
    end
  end
{% endhighlight %}

This `User` model is composed of several elements:
- an enum `gender` that associates genders with integers in our database,
- a one-to-many association with the model `Post`,
- an inclusion helper,
- a public scope `by_gender`,
- a public instance method `full_name` that concatenates two strings,
- two private methods formatting the values provided by our user.

We now have a basic 15-line model, yet there are already a handful of things to test!

Let's start with the simplest ones: public methods.

## How to test your Rails model's public methods

In an ideal - bug-free - world, all your public methods are tested.

Why? Because public methods are (usually) exposed through your application's public API. Abstractions around your application can access them. Sometimes, users can too.

Since both software and people rely on your public API, you're in a contract with them. People are consuming your application (and giving you money to do so). In return, you ensure your application behaves as expected.

Testing your models allows you to make sure you don't break your public API when changing your codebase.

Convinced? Great! Let's dive in.

{% highlight ruby %}
  require 'rails_helper'

  RSpec.describe User, type: :model do
    describe '#full_name' do
      subject(:full_name) { user.full_name }

      # to-do: test the output of the public method #full_name
    end
  end
{% endhighlight %}

Whether I write my tests before or after writing my code, I like to ask myself these two questions:
- <mark>What is the input?</mark>
- <mark>What is the expected output?</mark>

_A lot of software engineering boils down to these two questions._

Here, `full_name` takes an instance of `User` as an input. It then concatenates the results of two private methods: `formatted_first_name` and `formatted_last_name`.

First, we'll test our input.

{% highlight ruby %}
  require 'rails_helper'

  RSpec.describe User, type: :model do
    let(:user) { described_class.create(first_name: 'buffy', last_name: 'suMMers', gender: :female) }

    describe '#full_name' do
      subject(:full_name) { user.full_name }

      # to-do: test the output of the public method full_name
    end
  end
{% endhighlight %}

Now, we have a subject `full_name` (_what I want to test_) and a `user` (_the input I'll check my behavior against_).

Although my user input their first and last name with a weird case, my method should capitalize them.

{% highlight ruby %}
  require 'rails_helper'

  RSpec.describe User, type: :model do
    let(:user) { described_class.create(first_name: 'buffy', last_name: 'suMMers', gender: :female) }

    describe '#full_name' do
      subject(:full_name) { user.full_name }

      it 'returns the capitalized full name of the user' do
        expect(full_name).to eq("Buffy Summers")
      end
    end
  end
{% endhighlight %}

Note how the formatting logic is nested in the concatenation. By testing `full_name`, we indirectly test our two private methods. One stone, three birds.

## Should I test my private methods?

You might have guessed the answer from the previous example, but the short answer is __It Depends™__.

A more comprehensive answer:

__We always strive to test behavior not implementation__. With said input, what output do I get?

__By testing private methods, you're coupling your tests to your code implementation.__ This defeats tests' purpose: I can change my code as long as my public API stays the same.

However, you can see in the example above that the private methods are tested indirectly.

## How to test your Rails model's scopes

With scopes, we're getting into a greyish area.

Testing scopes is an ongoing debate among programmers. [Some feel like scopes fall under the structure umbrella - like associations - and should not be tested](http://blog.davidchelimsky.net/blog/2012/02/12/validations-are-behavior-associations-are-structure/){:target="\_blank"}. Other feel scopes are behavior-driven. As I said before, I won't take a side today, but if you ever need to test scopes, here's how to do it.

{% highlight ruby %}
  require 'rails_helper'

  RSpec.describe User, type: :model do
    let(:buffy) { described_class.create(first_name: 'buffy', last_name: 'summers', gender: :female) }

    describe '.by_gender' do
      subject(:by_gender) { described_class.by_gender(gender) }

      let(:gender) { :female }

      it 'returns the correct users' do
        expect(by_gender).to contain_exactly(buffy)
      end
    end
  end
{% endhighlight %}

Here, we test that the scope `by_gender` returns all users with a gender set at `female`. We expect our scope to return our user Buffy.

Our test passes, but a question remains: what about users excluded by our scope? We should verify these are not returned.

{% highlight ruby %}
  require 'rails_helper'

  RSpec.describe User, type: :model do
    let(:buffy) { described_class.create(first_name: 'buffy', last_name: 'summers', gender: :female) }

    describe '.by_gender' do
      subject(:by_gender) { described_class.by_gender(gender) }

      let(:gender) { :female }

      before do
        described_class.create(first_name: 'Rupert', name: 'Giles', gender: :male)
      end

      it 'returns the correct users' do
        expect(by_gender).to contain_exactly(buffy)
      end
    end
  end
{% endhighlight %}

What happened here is we didn't change the test, only the context. By adding a user that does not match the scope condition, we can check that:
- Our scope returns the correct users.
- The users failing our scope's condition are not returned.

## How to test your Rails model's validations

Model-level validations are part of Rails' strategy to ensure your database integrity. Let me show you how to test your validations with RSpec's basic features.

{% highlight ruby %}
  require 'rails_helper'

  RSpec.describe User, type: :model do
    let(:buffy) { described_class.new(first_name: 'anya', last_name: 'jenkins', gender: gender) }

    describe '#valid?' do
      subject { user.valid? }

      let(:gender) { :female }

      it { is_expected.to be true }

      context 'when gender is not included in the allowlist' do
        let(:gender) { :demon }

        it { is_expected.to be false }
      end
    end
  end
{% endhighlight %}

Since we only have one validation, our tests are easy to write. If we had numerous validations, we'd have to add more `describe` blocks testing each validation.

## Testing your model's validations, associations and enums with Shoulda Matchers

We're now leaving RSpec built-in features to use the [Shoulda Matchers library by Thoughtbot](https://github.com/thoughtbot/shoulda-matchers){:target="\_blank"}.

> Shoulda Matchers provides RSpec- and Minitest-compatible one-liners to test common Rails functionality.

One of Shoulda Matchers neat tricks is that you do not need to write any context. Shoulda Matchers lean on Rails' conventions to check your application's functionalities.

Let me show you:

{% highlight ruby %}
  require 'rails_helper'

  RSpec.describe User, type: :model do
    describe 'Validations' do
      it { is_expected.to validate_inclusion_of(:gender) }
    end
  end
{% endhighlight %}

Here, we have the one-liner that test our model's validation. I didn't have to create instances of `Post`.

Shoulda Matchers come with qualifiers allowing you to test the options of your models' structure. In our example, our validation checks the inclusion of the user's gender against a list.

{% highlight ruby %}
  require 'rails_helper'

  RSpec.describe User, type: :model do
    describe 'Validations' do
      it { is_expected.to validate_inclusion_of(:gender).in_array(%i[gender_neutral non_binary male female other]) }
    end
  end
{% endhighlight %}

Shoulda Matchers cover _a lot_ of functionalities: ActiveModel, ActiveRecord, ActionController, etc. Go and read the doc!

Here are the Shoulda Matchers tests for our model:

{% highlight ruby %}
  require 'rails_helper'

  RSpec.describe User, type: :model do
    let(:buffy) { described_class.create(first_name: 'buffy', last_name: 'summers', gender: :female) }

    describe 'Enums' do
      it { is_expected.to define_enum_for(:gender).with_values(gender_neutral: 0, non_binary: 1, male: 2, female: 3, other: 4)
    end

    describe 'Associations' do
      it { is_expected.to have_many(:posts) }
    end

    describe 'Validations' do
      it { is_expected.to validate_inclusion_of(:gender).in_array(%i[gender_neutral non_binary male female other]) }
    end
  end
{% endhighlight %}

Easy peasy!

## Is code coverage really a thing?

Now that we covered the fundamentals of testing your Rails models, I'll give you my modest opinion on focusing on code coverage.

Code coverage is only a number and a useful number at first. Think: "We don't have a single test in our entire codebase, and we're afraid of making any significant changes".

But as you move up the coverage gauge, the number means less and less.

Testing every single model's method (known as unit testing) gives you a sense of false security. Why? Because you're testing your methods in isolation. My experience tells me that focusing on testing whole features (integration testing) is a more productive and down-to-earth way of securing your application.

I'll leave you with that! I hope you like this post as much as I enjoyed writing it!

Cheers,

Rémi - [@mercier_remi](https://twitter.com/mercier_remi)

ps: __I'm working on a "Special Projects Membership Program" to amp up this website (More tutorials! More topics! Until the end of the Internet!)__ Sign-up to my newsletter to be the first to know!
