---
layout: post
title: 'Refactoring in practice: moving toward convention'
excerpt: "A few months ago, I had to write a Rails micro-service that synchronizes data between two versions of an application. I'll show you the successive steps I used to refactor this piece of code, from shameless-green to convention."
date: 2024-02-05
permalink: /refactoring-in-practice/
category: rails
cover_image: '/media/2024/02/remi-mercier-refactoring-in-practice.png'
---

I've wanted to write about __real-life refactoring__ for ages! However, coming up with examples of neat refactorings is not straightforward.

A few months ago, I had to write a Rails micro-service that synchronizes data between two versions of an application. The older application would store data on a Kafka topic. My service would need to listen to this topic, parse the messages, and handle the data.

The final solution illustrates well the inner workings of refactoring and architecture in real life.

A quick aside: I lean on the terminology of the tech I'm using, but the tech is not relevant. **The philosophy underlying the refactoring is**.

## What are we working with?

I wrote about it a while back, [I like to gather as much information as possible about the problem I need to solve]({{site.baseurl}}/how-to-write-better-specifications/). So, let's do just that.

For this project, I'll build a Rails application that streams Kafka topics and stores data.

Kafka is an event-based way of exposing data. Applications can _listen_ to a stream of data instead of having the data sent to them through a request. It allows applications to process data asynchronously.

Kafka sends data to __topics__. Each topic stores __messages__. Application streaming messages are __consumers__.

Let's start with a quick sketch.

{% highlight txt %}

  legacy application (writes data)
    |
    |
    v
  kafka topic (stores data in messages)
    ^
    |
    |
  new application (reads data)

{% endhighlight %}

Now, let's check the data stored in each `message`.

Each `message` stores a list of all the `highlights` made by one user. `Highlights` made by another `user` will be stored in another `message`.

The organization of our Kafka topic looks like this:

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
        "position": "1846",
        "quote": "I am no bird; and no net ensnares me."
        "timestamp": "1893-10-19 20:07:34 -0400",
      },
      {
        "position": "198765",
        "quote": "I would always rather be happy than dignified."
        "timestamp": "1893-10-20 19:32:20 -0400",
      }]
    }
  }
{% endhighlight %}

Each `highlight` is created from a specific `book`, and contains the `position` of the highlight in the book, the actual `quote`, and a `timestamp`.

My Rails application needs a few ActiveRecord models to find and persist data in my database.

{% highlight txt %}

+----------------+      +----------------+
|   Highlight    | 1..* |     Book       |
+----------------+      +----------------+
| - id           |      | - id           |
| - position     |      | - title        |
| - quote        |      +----------------+
| - timestamp    |
| - book_id      |
| - user_id      |
+----------------+

{% endhighlight %}

To consume Kafka events, I'll use [Karafka](https://github.com/karafka/karafka){:target="\_blank"}. I won't get into the details of setting up Karafka but know that Karafka lets you define _routes_ for your consumers to listen to topics.

The name of the topic is `users.highlights`. As a convention, I'll name all my `consumers` with a convention matching the names of my topics. It'll allow me to infer the name of the consumer I need just by parsing the topic's name.

Here, my `users.highlights` will transpose to a `Users::HighlightsConsumer`.

{% highlight ruby %}
  # karafka.rb

  Karafka::App.routes.draw do
    topic 'users.highlights' do
      consumer Users::HighlightsConsumer
    end
  end
{% endhighlight %}

Now that our setup is done, let's move on.

## A shameless-green first working version

Let's implement the barest working version.

Our consumer (`Users::HighlightsConsumer`) needs to `consume` the `messages` stored in the topic.

Kafka's standard behavior is to store messages in a log-like manner on topics – i.e. Kafka appends new messages to a list of existing messages. Consumers then parse through these messages, one at a time.

So, I need to iterate on each message and find the values. Only then will I be able to find or create objects in my database.

Remember that the content of the message is formatted as JSON.

{% highlight ruby %}
  # app/consumers/users/highlights_consumer.rb
  module Users
    class HighlightsConsumer < ApplicationConsumer
      def consume
        messages.each do |message|
          user = User.find(message.fetch("payload", "user_id"))
          book = Book.find(message.fetch("data", "book_id"))

          highlights = message.fetch("data", "highlights")

          highlights.each do |highlight|
            user_highlight = Highlight.find_or_initialize_by(
              user: user,
              book: book,
              position: hightlight["position"]
            )

            user_highlight.assign_attributes(
              quote: highlight["quote"],
              timestamp: hightlight["timestamp"]
            )

            user_highlight.save!
          end
        end
      end
    end
  end
{% endhighlight %}

Our shameless-green version has a few benefits:
- It's easy to read.
- It's straightforward.
- It's all in one place.

A teammate could look at this piece of code and instantly understand it.

But I'd like to anticipate the moment I'll need to consume several topics and move toward a **convention** underlying the structure of Kafka topic consumption.

## Modeling the concept of `message`

Our first step is easy: let's create an abstraction reflecting the concept of Kafka messages.

A message is a JSON and contains information about the **highlights** created by a user from a book.

{% highlight ruby %}
  # app/consumers/users/highlights_consumer.rb
  module Users
    class HighlightsConsumer < ApplicationConsumer
      def consume
        messages.each do |message|
          HighlightsMessage.new(message).save
        end
      end
    end
  end

  # app/models/users/highlights_message.rb
  module Users
    class HighlightsMessage
      def initialize(attributes)
        @data = attributes.fetch('data')
        @payload = attributes.fetch('payload')
      end

      def save
        user = User.find(@payload.fetch("user_id"))
        book = Book.find(@data.fetch("book_id"))

        highlights = @data.fetch("highlights")

        highlights.each do |highlight|
          user_highlight = Highlight.find_or_initialize_by(
            user: user,
            book: book,
            position: hightlight["position"]
          )

          user_highlight.assign_attributes(
            quote: highlight["quote"],
            timestamp: hightlight["timestamp"]
          )

          user_highlight.save!
        end
      end
    end
  end
{% endhighlight %}

I merely moved the core of my data manipulation into a new object – `HighlightsMessage` – which responds to a `save` method.

Now, let's change the way we handle the data.

## Model input data in a object-oriented way

Don't get me wrong, I like JSON, but wouldn't it be nice to call `data.highlights` instead of `@data.fetch("highlights")`?

{% highlight ruby %}
  # app/models/users/highlight_message.rb
  module Users
    class HighlightsMessage
      attr_reader :data, :payload

      def initialize(attributes)
        @data = Data.new(attributes.fetch('data'))
        @payload = Payload.new(attributes.fetch('payload'))
      end

      def save
        user = User.find(payload.user_id)
        book = Book.find(data.book_id)

        highlights = data.highlights

        highlights.each do |highlight|
          user_highlight = Highlight.find_or_initialize_by(
            user: user,
            book: book,
            position: hightlight["position"]
          )

          user_highlight.assign_attributes(
            quote: highlight["quote"],
            timestamp: hightlight["timestamp"]
          )

          user_highlight.save!
        end
      end

      class Data
        attr_reader :book_id, :highlights

        def initialize(attributes)
          @book_id = attributes.fetch("book_id")
          @highlights = attributes.fetch("highlights")
        end
      end

      class Payload
        attr_reader :user_id

        def initialize(attributes)
          @user_id = attributes.fetch("user_id")
        end
      end
    end
  end
{% endhighlight %}

By introducing two small classes on initialization – `Data` and `Payload` – I keep the structure of my input data while making the code more idiomatic (i.e. a method invoked on a receiver).

## Use plain Ruby objects to model transient data.

So far, we've worked on interfacing our codebase with the outside world: consumers, messages, data formatted by someone else, etc.

But now that I can access the data stored in messages, I still lack a proper representation for the JSON-ified `highlights` before they become instances of my `Highlight` class.

There are still a handful of places where I need to fetch my data with a `highlight ["key"]` syntax. Since I'm leaning so much in OOP, I'd rather have a temporary object returning a hash with only the data I need (and none of the data I don't need).

{% highlight ruby %}
  # app/models/users/highlight_message.rb
  module Users
    class HighlightsMessage
      attr_reader :data, :payload

      def initialize(attributes)
        @data = Data.new(attributes.fetch('data'))
        @payload = Payload.new(attributes.fetch('payload'))

        @highlights = set_highlights
      end

      def save
        user = User.find(payload.user_id)
        book = Book.find(data.book_id)

        highlights.each do |highlight|
          user_highlight = Highlight.find_or_initialize_by(
            user: user,
            book: book,
            position: hightlight.position
          )

          user_highlight.assign_attributes(highlight.to_h)

          user_highlight.save!
        end
      end

      private

      def set_highlights
        data.highlights.map do |highlight|
          Users::HighlightsMessage::Highlight.new(highlight)
        end
      end

      class Data
        # ...
      end

      class Payload
        # ...
      end
    end
  end

  # app/models/users/highlights_message/highlight.rb
  module Users
    module HighlightsMessage
      class Highlight
        attr_reader :position, :quote, :timestamp

        def initialize(attributes)
          @position = attributes.fetch("position")
          @quote = attributes.fetch("quote")
          @timestamp = attributes.fetch("timestamp")
        end

        def to_h
          {
            position: position,
            quote: quote,
            timestamp: timestamp
          }
        end
      end
    end
  end
{% endhighlight %}

Now, on top of initializing a `Data` and a `Payload` objects, I also create a collection of `Users::HighlightsMessage::Highlight`.

`Users::HighlightsMessage::Highlight` is a temporary object that serves as a translator between data I don't have any control over and the data my application needs.

## When looking for patterns, squint!

Sandi Metz introduced generations of developers to the **Squint Test**.

When looking for a pattern, leave your reasoning out for a minute and squint at your screen. Search for visual patterns, such as indentation or color blocks.

All our previous refactoring becomes apparent with the Squint Test. The architecture of our application now matches the organization of Kafka topics.

{% highlight txt %}
--- Kafka architecture ----+----------- Rails architecture ---------
                           |
- topic "users.highlights" | - consumer "Users::HighlightsConsumer"
  - messages               |   - messages
    - message              |     - message "User::HighlightsMessage"
      - payload            |       - payload "User::HighlightsMessage::Payload"
        - "user_id"        |         - "#user_id"
      - data               |       - data "User::HighlightsMessage::Data"
        - "book_id"        |         - "#book_id"
        - highlights       |         - "User::HighlightsMessage::Highlight"
          - "position"     |           - "position"
          - "quote"        |           - "quote"
          - "timestamp"    |           - "timestamp"

{% endhighlight %}

By slowly refactoring our code, we've been able to establish:
- A clear terminology for consuming Kafka topics in our application,
- A reproducible convention allowing my teammates to easily infer the different pieces of code, and their roles.
- A clear interface for each level of abstraction.

I hope you like this real-life (albeit adapted) example of how small refactorings can make a compounding effect on your codebase.

Cheers,

Rémi - [@remi@ruby.social](https://ruby.social/@remi)
