---
layout: post
title: 'Refactoring in practice'
---

It's been a while since I've wanted to write about __refactoring in practice__. But coming up with examples of neat architectures is less straightforward than with coming up with .

A few months ago, I had to write a service that would synchronize data between two versions of an application. The older application would store data on a Kafka topic. My service had to listen to this topic, parse the messages, and handle the data.

The solution I came up with illustrates well the inner working of refactoring and architecturing in real life.

A quick aside: I lean on the terminology of the tech I'm using but the tech is not _actually_ relevant. The philosophy underlying the architecturing is though.

## Understanding what we're working with

I've written about it a while back, [I like to gather as much information as possible about the problem I need to solve]({{site.baseurl}}/how-to-write-better-specifications/). So, let's do just that.

For this project, I'll build a Rails application that streams Kafka topics, and store data.

Kafka is an event-based way of exposing data. Applications can _listen_ to a stream of data instead of having the data sent to them through a request. It allows applications to stream a lot of data asynchronosly.

Kafka stores the data on __topics__. Each topic stores __messages__. Application streaming messages are __consumers__.

The emphases above will come handly later on.

Let's start with a quick sketch.

<img class='large' src="{{ site.baseurl }}/media/2023/10/flowchart.png" alt="">

Then, let's check the data stored in each `message`.

Each `message` stores a list of all the `highlights` made by one user. `Highlights` made by another `user` will be stored in another `message`.

The organisation of our Kafka topic looks like this:

{% highlight txt %}

  +----------------------------+
  | Topic `users.highlights` |
  |                            |
  | +------------------------+ |
  | |        Message         | |
  | | +--------------------+ | |
  | | | User 01 Highlights | | |
  | | +--------------------+ | |
  | +------------------------+ |
  | +------------------------+ |
  | |        Message         | |
  | | +--------------------+ | |
  | | | User 02 Highlights | | |
  | | +--------------------+ | |
  | +------------------------+ |
  | +------------------------+ |
  | |        Message         | |
  | .           ...          . |
  +----------------------------+

{% endhighlight %}

Each `message` looks like this:

{% highlight json %}
  {
    "message_id": "123456",
    "payload": {
      "user_id": 123,
      "first_name": "Anne",
      "last_name": "Shirley"
    },
      "data": {
        "book_id": 987,
        "highlights": [{
          "page": "18",
          "quote": "I am no bird; and no net ensnares me: I am a free human being with an independent will."
          "timestamp": "1893-10-19 20:07:34 -0400",
        },
        {
          "position": "198765",
          "quote": "I would always rather be happy than dignified."
          "timestamp": "1893-10-20 19:32:20 -0400",
        }
      ]
    }
  }
{% endhighlight %}

Each `highlight` is created from a specific `book`, and contains the `position` of the highlight in the book, the actual `quote` and a `timestamp`.

My Rails application needs a few ActiveRecord models to find and/or persist data in my database.

{% highlight txt %}

  +-----------+         +----------+
  | Highlight | *     1 | Book     |
  +-----------+ ------> +----------+
  | id        |         | id       |
  | position  |         | title    |
  | quote     |         | ...      |
  | timestamp |         +----------+
  | book_id   |
  +-----------+

{% endhighlight %}

To consume Kafka events, I'll use [Karafka](https://github.com/karafka/karafka){:target="\_blank"}. I won't get into the details of setting up Karafka, but just know that Karafka lets you define _routes_ for your consumers to listen to topics.

We've seen in our Kafka setup that the topic name is `users.highlights`. So, the first thing you'll need to note is that I name my `consumer` with a convention that match the topic name. This is extra useful when working accross multiple services. You'll be able to infer the name of the consumer you need just by parsing the name of the topic.

{% highlight ruby %}
  # karafka.rb

  Karafka::App.routes.draw do
    topic 'users.highlights' do
      consumer Users::HighlightsConsumer
    end
  end
{% endhighlight %}

## A first working version

{% highlight ruby %}
  module Users
    # Our consumers inherit from Karafka's ApplicationConsumer
    class HighlightsConsumer < ApplicationConsumer
      def consume
        messages.each do |message|
          user = User.find(message.fetch("payload", "user_id")


          book = Book.find(message.fetch("data", "book_id")


        end
      end
    end
  end

{% endhighlight %}

Okay, now that we have our bases covered, let's dig in!

!!! Move from no encapsulation with flat data to OOP

- consumer where everything happens

then

- consumer
- message where everything happen with flatten data

then

- consumer
- message w/ data and payload
- message::highlight





---



Then propose a solution that works okay : message listener, handling data as hash.

Now, make this better by having archi with similar terms than karafka and kafka : consumer, message, …

Explain why its better:

- clear terminology and pattern for data manipulation
- Can be reproduced easily for plenty use case so less cognitive load
- Offer a clear interface, where each piece knows only what it should

For using Kafka, I'll be using [Karafka](https://github.com/karafka/karafka){:target="\_blank"}.

{% highlight ruby %}
  # Gemfile

  gem 'karafka'
{% endhighlight %}
