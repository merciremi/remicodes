---
layout: post
title: Testing railway-oriented business transactions with Rspec
date:   2019-10-09
excerpt: "Railway-oriented business transactions are a great way to unclutter your Rails controllers. But how should we test them? Let's get down to it."
permalink: /testing-business-transactions-in-rails/
cover_image: /media/2019/testing-rails-transactions-rspec-remi-mercier.jpeg
---

Railway-oriented business transactions are a great way to [unclutter your Rails controllers]({{site.baseurl}}/transactions-in-rails/). We've already seen how to write 'em. Now let's see how we can test 'em. I'll be using [dry-transaction](https://dry-rb.org/gems/dry-transaction/) as a business transaction DSL and RSpec for testing. I'm assuming that you already have RSpec set up for your app. If not, check [Aaron Sumner's blog](https://everydayrails.com/) and his book [Everyday Rails Testing With RSpec](https://leanpub.com/everydayrailsrspec) to saddle up.

## Starting point: a basic transaction

Here's a basic transaction. I'll fetch some `params` and create a new lead. Based on the database response, I'll return either a `Success` or a `Failure`.

{% highlight ruby %}
  # app/transactions/leads/create.rb

  class Leads::Create < BaseTransaction
    map :params
    step :create_lead

    def params(input)
      input.fetch(:params)
    end

    def create_lead(params)
      lead = Lead.create(params)

      if lead.errors.any?
        Failure(error: lead.errors.full_messages.join(' | '))
      else
        Success(lead)
      end
    end
  end
{% endhighlight %}

Now, I want to test it. So where do I start?

## Testing transactions: the basics

First, I'll create a test file.

{% highlight zsh %}
  touch app/transactions/leads/create_spec.rb
{% endhighlight %}

Then, I'll write our test bare bones.

{% highlight ruby %}
  # app/transactions/leads/create_spec.rb

  require 'rails_helper'

  RSpec.describe Leads::Create, type: :transaction do
    subject { described_class.call(params: params) }

    let(:params) do
      {
        first_name:        'Steven',
        last_name:         'Universe',
        email:             'steven@crystalgems.com',
        opt_in_newsletter: true
      }
    end
  end
{% endhighlight %}

What I'm doing here:
- `described_class.call(params: params)` is calling my transaction with the awaited input (`params`)
- `subject` is a special variable that refers to my transaction being tested
- `let(:params)` stores the hash I'm sending to my transaction

## Covering positive scenarios

What should I test then? The first thing I want to test is the transaction returning a `Success` when called with valid `params`. From this starting point, I can check if the transaction <em>does</em> create a `Lead` or if this lead has the proper attributes filled in.

{% highlight ruby %}
  require 'rails_helper'

  RSpec.describe Leads::Create, type: :transaction do
    subject { described_class.call(params: params) }

    let(:params) do
      {
        first_name:        'Steven',
        last_name:         'Universe',
        email:             'steven@crystalgems.com',
        phone_number:      '+33660606060',
        opt_in_newsletter: false
      }
    end

    context 'a new lead signed up with valid params' do
      it { is_expected.to be_success }

      it 'creates a new lead' do
        expect { subject }.to(change { Lead.count }.by(1))
      end

      it 'return a new lead' do
        expect(subject.success).to be_a(Lead)
      end

      it 'fills in the ad hoc fields' do
        expect(subject.success).to have_attributes(
          first_name:        a_string_ending_with('n'),
          last_name:         a_string_starting_with('u'),
          email:             be_truthy,
          phone_number:      be_truthy,
          opt_in_newsletter: be_falsey
        )
      end
    end
  end
{% endhighlight %}

Here I'm using various [RSpec built-in matchers](https://relishapp.com/rspec/rspec-expectations/v/3-8/docs/built-in-matchers) to check several things:
- what's happening to my database when the transaction is called (with `expect { subject }.to()`)
- if my transaction returns a `Success` and the content of this `Success` (with `subject.success`)
- the newly created `Lead`'s attributes

## Testing for successes and failures

Say I want to send a SMS to my new lead through an external service. Let's add a step to my transaction.

{% highlight ruby %}
  class Leads::Create < BaseTransaction
    map :params
    step :create_lead
    step :send_welcome_sms

    def params(input)
      input.fetch(:params)
    end

    def create_lead(params)
      lead = Lead.create(params)

      if lead.errors.any?
        Failure(error: lead.errors.full_messages.join(' | '))
      else
        Success(lead)
      end
    end

    def send_welcome_sms(lead)
      MySmsProvider.welcome_sms(lead)

      Success(lead)
    rescue StandardError => exception
      Failure(error: exception)
    end
  end
{% endhighlight %}

Easy right? But `MySmsProvider` only provides production-ready credentials. So how can I test `MySmsProvider`'s different responses? RSpec allows me to mock responses.

Let's start with mocking a positive response. Our basic assumptions shouldn't change because whatever steps we're adding to the transaction, it should always return a `Success` or a `Failure`.

{% highlight ruby %}
  require 'rails_helper'

  RSpec.describe Leads::Create, type: :transaction do
    subject { described_class.call(params: params) }

    let(:params) do
      {
        first_name:        'Steven',
        last_name:         'Universe',
        email:             'steven@crystalgems.com',
        phone_number:      '+33660606060',
        opt_in_newsletter: false
      }
    end

    context 'a new lead signed up with valid params'
      before do
        response = {
          message_id:     01234,
          body:           'Hello Steven!',
          message_status: 'sent'
        }

        allow_any_instance_of(MySmsProvider).to receive(:deliver_now) { response }
      end

      it { is_expected.to be_success }

      it 'creates a new lead' do
        expect { subject }.to(change { Lead.count }.by(1))
      end

      it 'return a new lead' do
        expect(subject.success).to be_a(Lead)
      end

      it 'fills in the ad hoc fields' do
        expect(subject.success).to have_attributes(
          first_name:        a_string_ending_with('n'),
          last_name:         a_string_starting_with('u'),
          email:             be_truthy,
          phone_number:      be_truthy,
          opt_in_newsletter: be_falsey
        )
      end
    end
  end
{% endhighlight %}

But what if we want to test a negative response (i.e: Steven's phone number is invalid)?

I can either add a `context` block with specific `params` or mock a error message from `MySmsProvider`. I'll do the former. `context` behaves like a sub-folder where I can inherit my test's top-level information yet change it if need be.

{% highlight ruby %}
  require 'rails_helper'

  RSpec.describe Leads::Create, type: :transaction do
    subject { described_class.call(params: params) }

    let(:params) do
      {
        first_name:        'Steven',
        last_name:         'Universe',
        email:             'steven@crystalgems.com',
        phone_number:      '+33660606060',
        opt_in_newsletter: false
      }
    end

    context 'a new lead signed up with valid params' do
      before do
        response = {
          message_id:     01234,
          body:           'Hello Steven!',
          message_status: 'sent'
        }

        allow_any_instance_of(MySmsProvider).to receive(:welcome_sms) { response }
      end

      it { is_expected.to be_success }

      it 'creates a new lead' do
        expect { subject }.to(change { Lead.count }.by(1))
      end

      it 'return a new lead' do
        expect(subject.success).to be_a(Lead)
      end

      it 'fills in the ad hoc fields' do
        expect(subject.success).to have_attributes(
          first_name:        a_string_ending_with('n'),
          last_name:         a_string_starting_with('u'),
          email:             be_truthy,
          phone_number:      be_truthy,
          opt_in_newsletter: be_falsey
        )
      end
    end

    context 'a new lead signed up with invalid params' do
      # I can redefine my params here to include a nil value that'll trigger an error with my SMS provider
      let(:params) do
      {
        first_name:        'Steven',
        last_name:         'Universe',
        email:             'steven@crystalgems.com',
        phone_number:      nil,
        opt_in_newsletter: false
      }
    end

      it { is_expected.to be_failure }

      it 'returns an error from MySmsProvider' do
        expect(subject.deliver_sms_now).to be_kind_of(MySmsProvider::REST::RestError)
      end
    end
  end
{% endhighlight %}

In the last `context 'a new lead signed up with invalid params'`, the `before do` block defined in the first `context` does not apply (it's context dependent). I've decided to trigger an error based on my input rather than mocking an error with `allow_any_instance_of`. This way, I can decide to enforce validations at the transaction level to return a `Failure` if some data are missing.

And voilà!

I hope this boilerplate will help you start testing your transactions. Noticed something? [Ping me on Twitter](https://twitter.com/mercier_remi) or [create an issue on GitHub](https://github.com/merciremi/remicodes/issues/new).

Cheers,

Rémi
