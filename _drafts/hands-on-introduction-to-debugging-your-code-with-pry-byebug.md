---
layout: post
title: hands-on introduction to debugging your code with pry-byebug
---

Like every new developers, I first started as [a `puts` debugger](https://tenderlovemaking.com/2016/02/05/i-am-a-puts-debuggerer.html){:target="\_blank"}. I would write `puts` everywhere to see what was what - something I'm still doing when debugging Javascript [^1].

One day though, I had the chance to spend some time with [Cecile Varin](https://www.linkedin.com/in/cecilevarin/?originalSubdomain=fr){:target="\_blank"} who taught me the ropes of `pry-byebug`. I haven't gone back to `puts` ever since.

So, when I taught Ruby's basics at Le Wagon Paris, I passed that knowledge along.

Let's dive right in, so I can give you practical tips on using `pry-byebug` in your applications.

## Set up pry-byebug

Add the gem to your gemfile.

{% highlight ruby %}
  gem 'pry-byebug'
{% endhighlight %}

Then run:

{% highlight zsh %}
  bundle install
{% endhighlight %}

That's it.

## How-to

First, let's build up a bit of context so my demo is more idiomatic. I'll draw on something that happened to me a while back.

Here's the scenario:

- Some third-party service will send us a webhook.
- We'll receive and handle the data.
- We'll check the output.

Disclaimer: everything will look okay. But it will not be okay. At all.

First, the params we receive.

{% highlight json %}
  {
    "people": {

    }
  }
{% endhighlight %}

Second, our route.

{% highlight ruby %}
  # Expose endpoint for webhooks from some_service
  post '/some_service', to: 'some_service_hooks#create'
{% endhighlight %}

Then here's the controller code:

{% highlight ruby %}
  class SomeServiceHooksController
    def create

    end
  end

{% endhighlight %}





- receive webhooks
- route
- controller code
- data passed in webhook
- output
- the debug


Let's dive right in so i can show you a very practical guide on using pry-byebug in your applications.

- set up
- your code doesn't work, what do you do?
  - add a breaking point
  - read the console
  - basic command #1: interrogate the current values, methods, vars...
  - basic command #2: go to the next line w/ next
  - basic command #3: continue
  - basic command #4: exit || exit!

that's it.

<!-- we need code from controller + console code -->

https://github.com/deivid-rodriguez/pry-byebug

[^1]: Can someone please explain to me how the hell is supposed to work `debugger` in Javascript?
