---
layout: post
title:  How to use railway-oriented business transactions to unclutter your Rails controllers
date:   2019-09-09
excerpt: "When your Rails app needs to handle multiple steps, your controllers' methods can become a mess. Let's see how to Marie-Kondo them with dry-transaction"
category: rails
permalink: /transactions-in-rails/
cover_image: /media/2019/rails-railway-oriented-business-transactions-remi-mercier.jpg
---

When your Rails app needs to handle multiple steps, your controllers' methods can become a mess.

Don't despair, though. You can delegate sequential steps to business transactions and Marie-Kondo those messy controllers. I'll show you how.

Let's keep in mind that business transactions are different from ActiveRecord transactions. Business transactions allow you to create a series of steps, each resulting in a `Success` or a `Failure` object. ActiveRecord transactions are about ensuring that several database operations work as a single unit and are all rollbacked if any error occurs.

In this tutorial, I'll use the [dry-transaction gem](https://github.com/dry-rb/dry-transaction/) whose documentation is neat.

## From clean to messy controllers in no time

Let's start with coding a basic controller.

{% highlight ruby %}
  class LeadsController < ApplicationController
    def new
      @lead = Lead.new
    end

    def create
      lead = Lead.create(lead_params)

      if lead.errors.any?
        lead = Lead.new(lead_params)
        render :new
      else
        redirect_to lead_path(lead)
      end
    end

    private

    def lead_params
      params.require(:lead).permit(
        :first_name, :last_name, :email
      )
    end
  end
{% endhighlight %}

Okay, so here's a basic `LeadsController`. You have two actions: `new` and `create`. As you can see, the `create` method is straightforward:
- I create a new lead with the information filled by our lead.
- I handle any errors by rendering the `leads/new` form prefilled with the information our current lead already gave us.
- If everything goes well, I redirect our lead to her profile page (or any page of my choosing).

But what if I want to do more? Let's say I want to:
- connect to a distant CRM [through an API]({{site.baseurl}}/what-is-an-api/) and synchronize the lead's information with my sales team
- send a welcome text and an email to the lead
- notify someone in my team

{% highlight ruby %}
  class LeadsController < ApplicationController
    def new
      @lead = Lead.new
    end

    def create
      lead = Lead.create(lead_params)

      if lead.errors.any?
        lead = Lead.new(lead_params)
        render :new
      else
        # synchronize new lead to distant CRM
        MyDistantCrm.create_lead(lead)

        # send welcome sms and email to new lead
        MySmsProvider.welcome_sms(lead).deliver_now
        LeadMailer.welcome(lead).deliver_now

        # notify business developer
        BusinessDevelopperMailer.new_lead(lead).deliver_now

        # redirect new leads to their profile page
        redirect_to lead_path(lead)

      # rescue any error to avoid a 500 error
      rescue StandardError => exception
        flash[:error] = exception
      end
    end

    private

    def lead_params
      params.require(:lead).permit(
        :first_name, :last_name, :email
      )
    end
  end
{% endhighlight %}

As you can see, there are several new steps doing very different things. In a real-life app, we could do a lot more than that: create associations, generate SKU numbers, etc. The other thing is that all these steps are dependent on the `lead` being created without any errors. This puts a lot of stuff into an `else` branch. This is where business transactions can come in handy.

Let's see how to do it.

## Transactions to the rescue

Let's set up dry-transaction and see how we can unclutter our controller.

### Step 1: Install dry-transaction

Add this line to your application's Gemfile:

{% highlight zsh %}
  gem 'dry-transaction'
{% endhighlight %}

Then execute:

{% highlight zsh %}
  bundle install
{% endhighlight %}

### Step 2: General principles

Before we dive into moving parts of our `LeadsController#create` into a transaction, let's look at a transaction file to see what's what.

<blockquote>A business transaction is a series of operations where any can fail and stop the processing.</blockquote>

Each step is processed one at a time and must return either a `Success` or a `Failure` object.

{% highlight ruby %}
  class Leads::Create < BaseTransaction
    # Here, I define the operation sequence
    tee :params
    step :create_lead

    # Here, I define each operation
    def params(input)
      @params = input.fetch(:params)
    end

    def create_lead(input)
      @lead = Lead.create(@params)

      if @lead.errors.any?
        Failure(error: @lead.errors.full_messages.join(' | '))
      else
        Success(input)
      end
    end
  end
{% endhighlight %}

Here are a few points to keep in mind:
- `tee` is a specific kind of step. It'll always return a `Success`. This is fine here because I'm simply fetching an input.
- `step` is the basic operation. It'll have to return either a `Success` or a `Failure` object.
- `@params` will be available to all other steps or methods of my transaction when `lead` will not.

### Step 3: Move the controller's logic into the transaction

Now, we can move parts of our `LeadsController#create` into a transaction.

My app's architecture was:

{% highlight zsh %}
  - app
    - controllers
      - application_controller.rb
      - leads_controller.rb
{% endhighlight %}

At the end of this tutorial, it'll be:

{% highlight zsh %}
  - app
    - controllers
      - application_controller.rb
      - leads_controller.rb
    - transactions
      - base_transaction.rb
      - leads
        - create.rb
{% endhighlight %}

Let's build `base_transaction.rb` first.

{% highlight ruby %}
  class BaseTransaction
    include Dry::Transaction

    def self.call(*args, &block)
      new.call(*args, &block)
    end
  end
{% endhighlight %}

`def self.call(*args, &block)` will allow us to **call** the transaction from our controllers with a hash of arguments.

I'll start with the transaction we started earlier and I'll move parts of our `LeadsController#create` into it.

{% highlight ruby %}
  class Leads::Create < BaseTransaction
    tee :params
    step :create_lead
    step :create_distant_lead
    step :send_welcome_sms
    step :send_welcome_email
    step :notify_business_developper

    def params(input)
      @params = input.fetch(:params)
    end

    def create_lead(input)
      @lead = Lead.create(@params)

      if @lead.errors.any?
        Failure(error: @lead.errors.full_messages.join(' | '))
      else
        Success(input)
      end
    end

    def create_distant_lead(input)
      MyDistantCrm.create_lead(@lead)

      Success(input)
    rescue StandardError => exception
      Failure(error: exception)
    end

    def send_welcome_sms(input)
      MySmsProvider.welcome_sms(@lead).deliver_now

      Success(input)
    rescue StandardError => exception
      Failure(error: exception)
    end

    def send_welcome_email(input)
      LeadMailer.welcome(@lead).deliver_now

      Success(input)
    rescue StandardError => exception
      Failure(error: exception)
    end

    def notify_business_developper(input)
      BusinessDevelopperMailer.new_lead(@lead).deliver_now

      Success(input)
    rescue StandardError => exception
      Failure(error: exception)
    end
  end
{% endhighlight %}

All of my `LeadsController#create` steps are now in my transaction.

Each operation handles its own errors and return a `Success` or a `Failure` object.

For instance, if my `MySmsProvider.welcome_sms(@lead).deliver_now` returns an error, my transaction will not execute the next steps and will return a `Failure` so I know that something went wrong here.

### Step 4: Call the transaction and handle its results

Now that all my steps are in my transaction, what should I do with my controller? We'll start by calling the transaction.

{% highlight ruby %}
  class LeadsController < ApplicationController
    def new
      @lead = Lead.new
    end

    def create
      Leads::Create.call(params: lead_params)
    end

    private

    def lead_params
      params.require(:lead).permit(
        :first_name, :last_name, :email
      )
    end
  end
{% endhighlight %}

Neat right?

<blockquote>Calling a transaction will run its operations in their specified order, with the output of each operation becoming the input for the next.</blockquote>

As I said before, a transaction either returns a `Success` or a `Failure` object. I can handle these results in the controller.

In our original controller, I would render the `new` form if the lead creation failed. On the other hand, if the creation succeeded, I'd redirect my new lead to its profile. Let's do this now!

{% highlight ruby %}
  class LeadsController < ApplicationController
    def new
      @lead = Lead.new
    end

    def create
      Leads::Create.call(lead_params) do |m|
        m.success do
          redirect_to lead_path(lead)
        end
        m.failure do |failure|
          lead = Lead.new(lead_params)
          render :new
        end
      end
    end

    private

    def lead_params
      params.require(:lead).permit(
        :first_name, :last_name, :email
      )
    end
  end
{% endhighlight %}

Now, my controller only handles calls to a grouped set of business operations. No more database operations mingling with sending out emails or redirection rules. There is some cohesiveness in the abstraction.

<img src="{{ site.baseurl }}/media/2019/marie-kondo.gif" alt="marie kondo">

This is it!

Y'all go and checkout [dry-transaction's documentation](https://dry-rb.org/gems/dry-transaction/) and do not hesitate [to read the source code](https://github.com/dry-rb/dry-transaction/) for more magic!

Thank you [Nicolas](https://twitter.com/nicoolas25) for your feedback and help with this post!

If you have any questions or if something is not clear enough, [ping me on Twitter](https://twitter.com/mercier_remi) or [create an issue on GitHub](https://github.com/merciremi/remicodes/issues/new) so we can make this tutorial better.

Next time, I'll show you [how to test your transactions with Rspec]({{site.baseurl}}/testing-business-transactions-in-rails/) [update: it's live! ✌️].

Cheers,

Rémi
