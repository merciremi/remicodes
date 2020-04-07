---
layout: post
title: A hands-on tutorial to debugging your code with pry-byebug
date: 2020-04-07
excerpt: "Like most new developers, I started as a puts developer. Then, I discovered pry-byebug and debugging things got a lot easier. This is a beginner-level, hands-on, introduction to debbuging your code with pry-byebug. Behold the power of binding.pry!"
permalink: /pry-byebug-tutorial/
---

Like most new developers, I first started as [a `puts` debugger](https://tenderlovemaking.com/2016/02/05/i-am-a-puts-debuggerer.html){:target="\_blank"}. I would write `puts` everywhere to see what's what - something I'm still doing when debugging Javascript [^1].

One day, I had the chance to spend some time with [Cecile Varin](https://www.linkedin.com/in/cecilevarin/){:target="\_blank"}, who showed me the ropes of _[pry-byebug](https://github.com/deivid-rodriguez/pry-byebug){:target="\_blank"}_.

So, when I taught Ruby's basics at Le Wagon Paris, I passed that knowledge along.

Let's dive right in, so I can give you practical tips on using _pry-byebug_ in your applications.

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

## Some context

Before we begin, let's build up a bit of context, so my demo is more idiomatic. I'll draw on something that happened to me a while back.

Here's our scenario:
- Some third-party service periodically sends us a webhook with people's information.
- We receive and handle the data: checking for people in our database, creating them if need be, etc.
- We check that people were either matched to an existing instance or created.

Sounds good? Let's check our code now.

First, here's an excerpt from the data **we expect** to receive:

{% highlight json %}
  {
    people: [
      { first_name: 'Buffy', last_name: 'Summers', email: 'buffy@sunnydale.edu'},
      { first_name: 'Willow', last_name: 'Rosenberg', email: 'willow@gmail.com'},
      { first_name: 'Rupert', last_name: 'Giles', email: 'giles@sunnydale.edu'},
      { first_name: 'Cordelia', last_name: 'Chase', email: 'cordelia@gmail.com'},
      { first_name: 'Xander', last_name: 'Harris', email: 'xander@sunnydale.edu'}
      etc...
    ]
  }.with_indifferent_access
{% endhighlight %}

One important thing to note: this is what we expect. At that point, **we only know for sure about the structure of the data**. The data itself? We don't know yet what we'll receive.

Second, here's our route.

{% highlight ruby %}
  # Expose endpoint for webhooks from some_service
  post '/some_service', to: 'some_service_hooks#find_or_create_person'
{% endhighlight %}

Third, here's our controller code:

{% highlight ruby %}
  class SomeServiceHooksController < ApplicationController
    def find_or_create_person
      params[:people].each do |person|
        new_person = Person.find_or_create_by(email: person[:email])

        new_person.assign_attributes(
          first_name: person[:first_name],
          last_name: person[:last_name]
        )

        new_person.save
      rescue StandardError => exception
        # handle exception
      end
    end
  end
{% endhighlight %}

What does it do:
- Loops over each person contained in the params.
- Finds or creates each person.
- Assigns the _ad hoc_ values and persists them.
- Handles unexpected errors.

Remember when I told I'd drawn the context from [my own experience]({{site.baseurl}}/2019-year-review/)? Well, here's what happened:

After a while, my users reported some discrepancies in the app: some people sent by the third-party service were neither found nor created. No clear pattern emerged from the get-go. 🤔

'Twas time for some `binding.pry`.

## pry-byebug basic commands

### Add a breakpoint and check current values: `binding.pry`

Let's go back to our `SomeServiceHooksController`. I'll add two breakpoints inside the loop. It'll help me check the data at different stages.

{% highlight ruby %}
  class SomeServiceHooksController < ApplicationController
    def find_or_create_person
      params[:people].each do |person|
        binding.pry
        new_person = Person.find_or_create_by(email: person[:email])

        new_person.assign_attributes(
          first_name: person[:first_name],
          last_name: person[:last_name]
        )

        binding.pry
        new_person.save
      rescue StandardError => exception
        # handle exception
      end
    end
  end
{% endhighlight %}

Now, I can send the concatenated content of the last few webhooks to our controller (with Postman, for instance). Each `binding.pry` will pause the execution of our code. And, right amid our server's logs, _pry-byebug_ will open a debugging console.

Let me show you what happens after I send the data to the endpoint:

{% highlight irb %}
  From: (pry) @ line 52 SomeServiceHooksController#find_or_create_person:

    49: def find_or_create_person(params)
    50:   params['people'].each do |person|
    51:     binding.pry
 => 52:     new_person = Person.find_or_create_by(email: person[:email])
    53:
    54:     new_person.assign_attributes(
    55:       first_name: person[:first_name],
    56:       last_name: person[:last_name]
    57:     )
    58:
    59:     binding.pry
    60:     new_person.save
    61:   rescue StandardError => exception
    62:     # handle exception
    63:   end
    64: end
{% endhighlight %}

Behold _pry-byebug_'s console!

See that `=>` in front of line 52? That's _pry-byebug_ telling you the execution paused there.

From here, you can check every variable already declared in the present context: our `params` and the current `person`.

Typing `params` in the console will give you the following output:

{% highlight irb %}
  pry(#<SomeServiceHooksController>)> params

  => {"people"=>
    [{"first_name"=>"Buffy", "last_name"=>"Summers", "email"=>"buffy@sunnydale.edu"},
     {"first_name"=>"Willow", "last_name"=>"Rosenberg", "email"=>"willow@gmail.com"},
     {"first_name"=>"Rupert", "last_name"=>"Giles", "email"=>"giles@sunnydale.edu"},
     {"first_name"=>"Cordelia", "last_name"=>"Chase", "email"=>"cordelia@gmail.com"},
     {"first_name"=>"Xander", "last_name"=>"Harris", "email"=>"xander@sunnydale.edu"}]}
{% endhighlight %}

Typing `person` will give you:

{% highlight irb %}
  pry(#<SomeServiceHooksController>)> person

  => {"first_name"=>"Buffy", "last_name"=>"Summers", "email"=>"buffy@sunnydale.edu"}
{% endhighlight %}

But soon-to-be-defined variables - like `new_person` - are not accessible yet.

{% highlight irb %}
  pry(#<SomeServiceHooksController>)> new_person

  => nil
{% endhighlight %}

I can also call the methods defined in my class because Ruby reads class definitions before their execution. I can even query things from my database:

{% highlight irb %}
  pry(#<SomeServiceHooksController>)> Person.count
     (0.6ms)  SELECT COUNT(\*) FROM "people"
  => 143
{% endhighlight %}

Fancy right? Let's move on.

### Execute the next line of code and wait: `next`

So, our application paused just before `new_person`'s definition. What if we want to move the cursor down one line and see what `Person.find_or_create_by(email: person[:email])` returns?

Well, we can type `next` in our _pry-byebug_ console.

{% highlight irb %}
  pry(#<SomeServiceHooksController>)> next
{% endhighlight %}

This'll output:

{% highlight irb %}
  From: (pry) @ line 54 SomeServiceHooksController#find_or_create_person:

    49: def find_or_create_person(params)
    50:   params['people'].each do |person|
    51:     binding.pry
    52:     new_person = Person.find_or_create_by(email: person[:email])
    53:
 => 54:     new_person.assign_attributes(
    55:       first_name: person[:first_name],
    56:       last_name: person[:last_name]
    57:     )
    58:
    59:     binding.pry
    60:     new_person.save
    61:   rescue StandardError => exception
    62:     # handle exception
    63:   end
    64: end
{% endhighlight %}

See what happened? The `=>` cursor moved through the definition of `new_person`, and stopped just before the next line of code. So now, `new_person` is accessible:

{% highlight irb %}
  pry(#<SomeServiceHooksController>)> new_person

  => #<Person:0x00007fcdb143e9b0
 id: 13,
 first_name: nil,
 last_name: nil,
 email: "buffy@sunnydale.edu">
{% endhighlight %}

Tada! An existing instance of `Person` was affected to `new_person` because it existed with the email `buffy@sunnydale.edu`.

### Continue execution until the next breakpoint (or until the end of the current process): `continue`

Now, remember when I said I'd throw a couple of breakpoints for good measure? Sometimes, I want to skip big chunks of code but still pause its execution later. Think about controllers calling multiple methods, one of which is faulty. I can add breakpoint in each method to see what's what.

In this case, `next` is not enough. You'd have to type it countless times and (sometimes) navigate through your app's stack (something that's way too much advanced for this tutorial).

So, what should you use? `continue` of course! Lemme show you:

{% highlight irb %}
  pry(#<SomeServiceHooksController>)> continue
{% endhighlight %}

And the output:

{% highlight irb %}
  From: (pry) @ line 60 SomeServiceHooksController#find_or_create_person:

      49: def find_or_create_person(params)
      50:   params[:people].each do |person|
      51:     binding.pry
      52:     new_person = Person.find_or_create_by(email: person[:email])
      53:
      54:     new_person.assign_attributes(
      55:       first_name: person[:first_name],
      56:       last_name: person[:last_name]
      57:     )
      58:
      59:     binding.pry
   => 60:     new_person.save
      61:   rescue StandardError => exception
      62:     # handle exception
      63:   end
      64: end
{% endhighlight %}

The `=>` cursor didn't just move onto the next line. It only stopped at the next breakpoint. So now, I have access to the updated version of `new_person`:

{% highlight irb %}
  pry(#<SomeServiceHooksController>)> new_person

  => #<Lead:0x00007fcdb143e9b0
   id: 162,
   first_name: "Buffy",
   last_name: "Summers",
   email: "buffy@sunnydale.edu">
{% endhighlight %}

Once you've passed the last breakpoint, `continue` will resume the code's execution until the end of the current context. In our example, the current context is `SomeServiceHooksController`. Since we're in a loop, `continue` will only bring you to the next `person` until we looped through every people. Then, it'll exit the `SomeServiceHooksController` class and get on with its life.

Want to exit _pry-byebug_ the dirty (my) way? Try `exit!`. It'll kill both the current process and the server. This is useful when having too many breakpoints across multiple places.

⚠️ A warning: since `binding.pry`'s pause code execution, don't push 'em into production. Or you'll be in for a rough time. 😬

## How my debugging ended up: never trust your database

When I learned to code, a lot of people told me to never trust users' input. Well, no one ever told me to never trust my database either!

Remember when I told you that I was only sure about the structure of the data sent through the webhook? Well, it turned out that some people's data were incomplete:

{% highlight json %}
  {
    people: [
      { first_name: 'Buffy', last_name: 'Summers', email: 'buffy@sunnydale.edu'},
      { first_name: 'Willow', last_name: 'Rosenberg', email: 'willow@gmail.com'},
      { first_name: 'Rupert', last_name: 'Giles', email: 'giles@sunnydale.edu'},
      { first_name: 'Cordelia', last_name: 'Chase', email: 'cordelia@gmail.com'},
      { first_name: 'Xander', last_name: 'Harris', email: 'xander@sunnydale.edu'},
      { first_name: 'Spike', last_name: '', email: 'nil'} # 👈 😱
    ]
  }.with_indifferent_access
{% endhighlight %}

Lesson #1: **never trust your users' input**

You would expect `Person.find_or_create_by(email: nil)` to return `nil`, right? Well, it turned out some of my oldest instances of `Person` had been created before I had a validation of presence in place for their email.

So, every time the third-party service would sent me a person with a `nil` email, I would update the first instance of `Person` with an `email == nil` instead of creating a new one (or handling this as an error). These people fell from the net for weeks before I managed to identified the core problem.

Lesson #2: **never trust your own data**

Well, that's it for today folks! I hope it'll make your debugging more enjoyable!

Noticed something? [Ping me on Twitter](https://twitter.com/mercier_remi) or [create an issue on GitHub](https://github.com/merciremi/remicodes/issues/new).

Cheers,

Rémi

[^1]: Can someone explain to me, how `debugger` is supposed to work in the Javascript console?
