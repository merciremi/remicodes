---
layout: post
title: hands-on introduction to debugging your code with pry-byebug
---

Like most new developers, I first started as [a `puts` debugger](https://tenderlovemaking.com/2016/02/05/i-am-a-puts-debuggerer.html){:target="\_blank"}. I would write `puts` everywhere to see what was what - something I'm still doing when debugging Javascript [^1].

One day though, I had the chance to spend some time with [Cecile Varin](https://www.linkedin.com/in/cecilevarin/){:target="\_blank"} who taught me the ropes of _[pry-byebug](https://github.com/deivid-rodriguez/pry-byebug){:target="\_blank"}_.

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

Before we begin, let's build up a bit of context so my demo is more idiomatic. I'll draw on something that happened to me a while back.

Here's our scenario:

- Some third-party service periodically sends us a webhook with people information.
- We receive and handle the data: checking for people in our database, creating them if need be, etc.
- We check that people were either matched to an exisiting instance or created.

Sounds good? Let's check our code now.

First, here's an excerpt from the data **we expect** to receive:

{% highlight json %}
  {
    people: [
      { first_name: 'Buffy', last_name: 'Summers', email: 'buffy@sunnydale.edu'},
      { first_name: 'Willow', last_name: 'Rosenberg', email: 'willow@gmail.com'},
      { first_name: 'Rupert', last_name: 'Giles', email: 'giles@sunnydale.edu'},
      { first_name: 'Cordelia', last_name: 'Chase', email: 'cordelia@gmail.com'},
      { first_name: 'Xander', last_name: 'Harris', email: 'xander@sunnydale.edu'},
      etc...
    ]
  }.with_indifferent_access
{% endhighlight %}

One important thing to note: this is what we expect. At that point, **we only know for sure about the structure of the data**. The data itself, we don't know yet what we'll receive.

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

Remember when I told you the context was drawn from my own experience? Well here's what happened.

At first, I didn't notice anything wrong. The webhooks were sent and handled. No error showed up. But after a while, my users reported that some people were not created in the application. Some already existing people information seemed to dissapear. No clear pattern emerged from the get go. 🤔

'Twas time for some `binding.pry`.

## pry-byebug basic commands

### Add a breakpoint and check current values: binding.pry

Let's go back to our `SomeServiceHooksController`. I'll add two breakpoints - the `binding.pry`s - inside the loop to check each person information sent through the webhook, at different stages of my code.

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

Now, I can send the concatenated content of the last few webhooks to our controller. Each `binding.pry` will pause the execution of our code. And, right in the midst of our server's logs, _pry-byebug_ will open a debugging console. Let me show you.

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

See that `=>` in front of the line 52? That's _pry-byebug_ telling you the execution is paused before this line and that it's waiting on your instructions.

From there, you can check everything that's already declared in the present context: `params` and the current `person`.

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

But things that are not declared yet, like `new_person` are not accessible yet.

{% highlight irb %}
  pry(#<SomeServiceHooksController>)> new_person

  => nil
{% endhighlight %}

I can also call the methods defined in my class (because the code within class definition is read by Ruby before it's actual execution). I can even query things from my database:

{% highlight irb %}
  pry(#<SomeServiceHooksController>)> Person.count
     (0.6ms)  SELECT COUNT(\*) FROM "people"
  => 143
{% endhighlight %}

Fancy right? Let's move on.

### Execute the next line of code and wait: next

So, our application is paused by the first breakpoint, just before `new_person` is defined. What if we want to move the cursor down one line and see what `Person.find_or_create_by(email: person[:email])` returns?

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

See what happened there? The `=>` cursor move just before the next line of code. So now, `new_person` is defined.

{% highlight irb %}
  pry(#<SomeServiceHooksController>)> new_person

  => #<Person:0x00007fcdb143e9b0
 id: 13,
 first_name: nil,
 last_name: nil,
 email: "buffy@sunnydale.edu">
{% endhighlight %}

Tada! An existing person was affected to `new_person` because an existing instance of Person existed with the email `buffy@sunnydale.edu`.

### Continue execution until the next breaking point or until the end of the current process: continue

Now, remember when I said I'd throw a couple of breakpoints for good mesure? Sometimes, I want to skip big chunks of code but still pause at some point (like when you have private methods in your controller and want to check which one is home to the nasty bug). In this case, `next` is not enough. You'd have to type it countless times and navigate through your app's stack, something that's way too much advanced for this tutorial.

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

I know! This feels like a hell lot easier that putting `puts` everywhere.

### Exit the current context and/or debugger console: exit and exit!

`exit` will let the code run until the current context is done with. In our example, the context is `SomeServiceHooksController`. Since we're in a loop, `exit` will bring you to the next `person` until all people are handled and the code exit the class.

Want to exit _pry-byebug_ altogether? Try `exit!`. It'll kill the current process and the server.

### warning don't let binding.pry in prod code cause it breaks everything ya

A note of caution, since `binding.pry` pause code execution, don't let it pass into production.

## How my debug ended up: never trust users input + never trust your database's integrity


- receive webhooks
- route
- controller code
- data passed in webhook
- output
- the debug


Let's dive right in so i can show you a very practical guide on using _pry-byebug_ in your applications.

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




class SomeServiceHooksController
  def find_or_create_person(params)
    params[:people].each do |person|
      binding.pry
      new_person = Lead.find_or_create_by(email: person[:email])

      binding.pry
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
