---
layout: post
title: 'Interfacing with external APIs: the facade pattern in Ruby'
excerpt: "Interacting with third-party APIs is common practice in applications. This is where the structural design pattern called facade comes into play."
date: 2024-10-14
permalink: /facade-pattern/
category: ruby
cover_image: "/media/2024/10/remi-mercier-facade-pattern-in-ruby.png"
---

Interacting with third-party APIs is common practice in applications. You might need to convert addresses into geographic coordinates, fetch subscription information from marketplaces, prompt an LLM, etc.

Coding with Ruby, you'll often find gems providing a first abstraction over third-party APIs: **the client layer**. The client layer is usually responsible for accessing the features of the external API.

One could use the client as is and sprinkle calls to the external API across their codebase. By doing so, teams will often duplicate logic, reinvent the wheel, and create multiple change points.

One way to _DRY_ this is to create an **authoritative representation** of the external API that'll define **how it relates to your domain logic**. This is where the structural design pattern called **facade** comes into play.

## A brief introduction to the facade design pattern

Before we start, let's acknowledge two caveats:
- There is **no definitive consensus on the definition of the facade pattern**.
- There is a lot of confusion around facades, gateways and adapters.

Let's hear what seasoned developers and authors have to say about it.

### The facade pattern defined by the Gang of Four

> [Facades] provide a unified interface to a set of interfaces in a subsystem. Facade defines a higher-level interface that makes the subsystem easier to use. This can be used to simplify a number of complicated object interactions into a single interface.
>
> <cite>[Design Patterns: Elements of Reusable Object-Oriented Software](http://wiki.c2.com/?FacadePattern){:target="\_blank"}</cite>

From this definition, we can list some key takeaways:
- A facade simplifies the interactions between a system and a complex subsystem.
- A facade provides a single point of interaction.
- A facade does not add features to the subsystem.
- A facade is transparent for the subsystem (ie: the subsystem does not care if the facade exists or not).
- A facade's intention flows outward (from an internal to an external system).

### The facade pattern defined by Martin Fowler

Martin Fowler defines facades _in opposition to gateways_, which are often used interchangeably.

> While Facade simplifies a more complex API, it's usually done by the writer of the service for general use. A gateway is written by the client for its particular use.
>
> [API gateway] is really more of a facade, since it's built by the service provider for general client usage.
>
> <cite>[Martin Fowler](https://martinfowler.com/articles/gateway-pattern.html){:target="\_blank"}</cite>

Some key points made by Martin Fowler in his post:
- A facade simplifies the interactions between a system and a complex API.
- A facade and a gateway are sometimes used interchangeably.
- A facade is built by the writer of the complex API for general use, whereas a gateway is built by the API user for their particular use.

### The facade pattern defined on Refactoring Guru

> Facade is a structural design pattern that provides a simplified interface to a library, a framework, or any other complex set of classes. [...]
>
> A facade might provide limited functionality in comparison to working with the subsystem directly. However, it includes only those features that clients really care about.
>
> <cite>[Refactoring Guru](https://refactoring.guru/design-patterns/facade){:target="\_blank"}</cite>

From this definition, we can infer that:
- A facade acts as a simplified interface to a more complex system.
- A facade can only expose the necessary functionalities of a complex system (and leave out some others).
- A facade has neither inward nor outward intention.

### The facade pattern defined by yours truly

Overall, even trusted authors don't fully agree on the definition of facades. And many more people have [many](https://stackoverflow.com/a/13593045){:target="\_blank"} [more](https://stackoverflow.com/a/13496995){:target="\_blank"} [definitions](https://stackoverflow.com/a/4604911){:target="\_blank"}.

I think these definitions also overlook one advantage of the facade pattern: it serves as a bridge[^1] between some features you need from an external system and why you need it (i.e. the context of your application).

For the rest of this post, I'll use the term _facade_ as:

> A simplified interface for normalizing the interactions between a complex system and the context of my application.

### And what about the difference between facades and adapters?

Adapters make an interface _usable_, usually by doing a lot of transformation/adaptation. Their scope is also narrower since adapters typically focus on making one object usable.

Facades merely provide an interface for a system of objects.

## What do I need a facade for?

Now that we (mostly) agree on the definition, let's conjure a bit of context first.

We're building a text editor for students. It's packed with features that'll make their lives easier.

### Context

Some students are currently working on an assignment. Before submitting their work, they'd like to check if their answers are correct and get additional suggestions.

To do that, our application can send information to an LLM and get a list of suggestions back. Easy peasy.

Let's build it!

{% highlight ruby %}
module Answers
  class SuggestionsController
    def create
      # LLM::Client is defined by a dummy gem
      llm_client = LLM::Client.new

      llm_client.login(credentials:).chat(parameters:)
    end

    private

    def credentials
      {
        access_token: ENV['LLM_ACCESS_TOKEN'],
        student_uuid: ENV['LLM_STUDENT_ID']
      }
    end

    def parameters
      {
        model: 'some_llm_model',
        messages:
          [
            { role: "system", content: "This is the question in my assignment: #{question.content}" },
            { role: "system", content: "Are there any ameliorations I could add to my answer: #{answer}" }
          ]
      }
    end

    def answer
      Answer.find(params[:answer_id])
    end

    def question
      answer.question
    end
  end
end
{% endhighlight %}

Despite being straightforward, our `Answers::SuggestionsController` already handles a handful of steps:
- The `create` method instantiates a client to interact with an external API: `LLM::Client`.
- The client authenticates with the external API: `llm_client.login(credentials:)`.
- The client sends information from the application to the external API - `chat(parameters:)` - where the information is multifold: predefined prompts, roles for each prompt, a model name, etc...

Some aspects of the code above bother me:
- The methods exposed by the client carry little meaning in my domain (assessments, answers, suggestions).
- What am I getting back, exactly?
- I'm sending a mixed bag of configuration and contextual information.
- What happens if my teammates need to add steps when fetching suggestions?
- What happens if my teammates need to interact with the external API elsewhere in the application?

Let's write some more code.

{% highlight ruby %}
# app/controllers/answers/suggestions_controller.rb
module Answers
  class SuggestionsController
    def create
      llm_client = LLM::Client.new

      llm_client.login(credentials:).chat(parameters:)
    end

    # ...
  end
end

# app/controllers/admissions/applications_controller.rb
module Admissions
  class ApplicationsController
    def suggest_improvements
      llm_client = LLM::Client.new

      llm_client.login(credentials:).chat(parameters: default_parameters.merge(application_parameters))
    end

    private

    def credentials
      {
        access_token: ENV['LLM_ACCESS_TOKEN'],
        student_uuid: ENV['LLM_STUDENT_ID']
      }
    end

    def default_parameters
      {
        model: 'some_llm_model',
        messages: []
      }
    end

    def applications_parameters
      {
        messages:
          [
            { role: "system", content: "I'm working on an admission application to my local university: #{admission.content}" },
            { role: "system", content: "Are there any improvements I could add to my application: #{application}" },
            { role: "user", content: "Format the suggestion like this: #{formatting}" }
          ]
      }
    end

    def formatting
      <<-TXT
        Suggestions:
        -
        -
      TXT
    end
  end
end
{% endhighlight %}

Some notable points stand out:
- We repeat boilerplate code: instantiating the client, authenticating, and default configuration.
- Small differences start appearing by introducing a `default_parameters` instance method that handles the default configuration.
- Custom instructions - like `formatting` - are hiding in nooks of our application which makes it impossible for the team to share the cumulative knowledge.
- `LLM::Client` still exposes domain-agnostic namings such as `chat` or `messages`, making it hard to infer the link between its interface and our domain logic.

## Building an authoritative representation

Facades are a great solution for this type of problem.

A facade will serve as an authoritative representation of how the external API fits into our application, and it will gather the collective knowledge in one place.

### 1) Basic functionalities

First, let's encapsulate the basic functionalities of the external API into a facade: the authentication strategy, a default configuration, and the instantiation of the client.

{% highlight ruby %}
  # app/facades/llm_facade
  class LLMFacade
    attr_reader :configuration, :llm_client

    def initialize
      @configuration = Configuration.new

      @llm_client ||= LLM::Client.new.login(credentials: configuration.credentials)
    end

    class Configuration
      def initialize
        @credentials = credentials
      end

      private

      def credentials
        {
          access_token: ENV['LLM_ACCESS_TOKEN'],
          student_uuid: ENV['LLM_STUDENT_ID']
        }
      end
    end
  end
{% endhighlight %}

Let's note that my facade is _just_ a Ruby object: composable and testable. It has no dependencies. I could write this facade in any object-oriented language of my choice.

So, what happens in `LLMFacade`?

A facade object instantiates with a default configuration and an authenticated client. The core authentication logic is handled by the dummy gem. The facade only leverages the gem layer and returns a _ready-made[^2]_ client.

I'm using a value object `Configuration` to represent the default configuration. I like this object-first approach over using a hash for encapsulating default values. It also makes testing easier.

### 2) Fetching suggestions for answers

Now that we have an object with basic functionalities, let's add the ability to fetch suggestions.

{% highlight ruby %}
  # app/facades/llm_facade
  class LLMFacade
    attr_reader :configuration, :llm_client

    def initialize
      @configuration = Configuration.new

      @llm_client ||= LLM::Client.new.login(credentials: configuration.credentials)
    end

    def fetch_suggestion_for(question, answer)
      llm_client.chat(parameters:
        default_parameters.merge(suggestion_parameters_for(question, answer))
      )
    end

    private

    def default_parameters = { model: configuration.model }

    def suggestion_parameters_for(question, answer)
      {
        messages: [
          { role: 'user', content: "This is the question I'm answering about: #{question}" },
          { role: 'user', content: "This is the answer I've written: #{answer}" }
        ]
      }
    end

    class Configuration
      attr_reader :model, :credentials

      def initialize(model = 'some_llm_model')
        @model = model
        @credentials = credentials
      end

      private

      def credentials
        {
          access_token: ENV['LLM_ACCESS_TOKEN'],
          student_uuid: ENV['LLM_STUDENT_ID']
        }
      end
    end
  end
{% endhighlight %}

Here's a breakdown of what I changed:
- I added a specific model to my default configuration.
- I called the `chat` method on our client with our parameters: a default model and instructions.

As of now, our facade allows us to call `LLMFacade.new.fetch_suggestion_for()` in our controllers, which makes more sense in our application than the generic `chat` method.

### 3) Fetching suggestions for applications

The next use case we need to implement in the facade is the ability to fetch suggestions for admission applications.

{% highlight ruby %}
  # app/facades/llm_facade
  class LLMFacade
    attr_reader :configuration, :llm_client

    def initialize
      @configuration = Configuration.new

      @llm_client ||= LLM::Client.new.login(credentials: configuration.credentials)
    end

    def fetch_suggestion_for(question, answer)
      llm_client.chat(parameters:
        default_parameters.merge(suggestion_parameters_for(question, answer))
      )
    end

    def fetch_suggestion_for_application(admission, application)
      llm_client.chat(parameters:
        default_parameters.merge(suggestion_parameters_for_application(admission, application))
      )
    end

    private

    def default_parameters = { model: configuration.model }

    def suggestion_parameters_for(question, answer)
      {
        messages: [
          { role: 'user', content: "This is the question I'm answering about: #{question}" },
          { role: 'user', content: "This is the answer I've written: #{answer}" }
        ]
      }
    end

    def suggestion_parameters_for_application(admission, application)
      {
        messages: [
          { role: "system", content: "I'm working on an admission application to my local university: #{admission.content}" },
          { role: "system", content: "Are there any improvements I could add to my application: #{application}" },
          { role: "user", content: "Format the suggestion like this: #{formatting}" }
        ]
      }
    end

    def formatting
      <<-TXT
        Suggestions:
        -
        -
      TXT
    end

    class Configuration
      # ...
    end
  end
{% endhighlight %}

If you thought, "But Remi, this new code looks awfully like the code used to fetch suggestions for answers!" you're right.

The naming, the overarching concept, and the instructions are similar.

However, our new requirement also adds a custom instruction: formatting.

One advantage of the facade is that it gathers use cases in one place. Sure, the complexity grows along with your application, but since it's not sprinkled everywhere in your application, it's easy to identify and fix.

Let's use that to our advantage and find an encompassing concept for these suggestions.

### 4) Refactoring using the flocking rules

Popularized by Sandi Metz, the flocking rules lean on the analogy of a bird flock where patterns emerge from displaying behaviors similar to those of surrounding individuals.

In our facade, the overall logic of generating feedback - whether for `questions` or `admissions` - is the same: a pattern emerges from the flock.

The flocking rules states that:
- _Select the things that are most alike_: `suggestion_parameters_for` and `suggestion_parameters_for_application`
- _Find the smallest difference between them_: the name of their parameters.
- _Make the simplest change that will remove that difference_: find overarching concepts for each of these parameters.

Let's find the _ad hoc_ abstractions for our parameters:
- `questions` and `admissions` are directives upon which a student must produce something.
- `answers` and `applications` are productions created against a directive.

Now that we identified our similar behaviors, let's refactor these two methods. Then, we'll tackle the optional formatting parameter.

{% highlight ruby %}
  # app/facades/llm_facade
  class LLMFacade
    attr_reader :configuration, :llm_client

    def initialize
      @configuration = Configuration.new

      @llm_client ||= LLM::Client.new.login(credentials: configuration.credentials)
    end

    def fetch_suggestion_for(directive, production, format = false)
      llm_client.chat(parameters:
        default_parameters
          .merge(suggestion_parameters_for(directive, production))
          .merge(formatting_parameters(format))
      )
    end

    private

    def default_parameters = { model: configuration.model }

    def suggestion_parameters_for(directive, production)
      {
        messages: [
          { role: 'user', content: "This is the directive I'm given: #{directive}" },
          { role: 'user', content: "This is the answer I've written: #{production}" }
        ]
      }
    end

    def formatting_parameters(format)
      return {} unless format

      {
        messages: [
          { role: 'user', content: "Format the suggestion like this: #{formatting}" }
        ]
      }
    end

    def formatting
      <<-TXT
        Suggestions:
        -
        -
      TXT
    end

    class Configuration
      ...
    end
  end
{% endhighlight %}

And voilà!

I removed the `suggestion_parameters_for_application` method, and updated the names of the parameters for `suggestion_parameters_for`.

To allow the optional formatting, I added a third argument with a boolean flag.

We could improve the naming of our methods with some [riffing](https://ruby.social/@kaspth){:target="\_blank"}. Some ideas to best reveal the intention behind our code:
- `fetch_suggestion_for`: `generate_feedback_for`
- `suggestion_parameters_for`: `instructions_for`, `parameters_for`

## Using our facade in our controllers

Now that we have a working facade, let's use it in our controller.

{% highlight ruby %}
  # app/controllers/answers/suggestions_controller.rb
  module Answers
    class SuggestionsController
      def create
        llm_facade.fetch_suggestion_for(question, answer)
      end

      private

      def llm_facade
        LLMFacade.new
      end

      def answer
        Answer.find(params[:answer_id])
      end

      def question
        answer.question
      end
    end
  end
{% endhighlight %}

Sweet, right? No more boilerplate. No more crust. Just a very expressive and idiomatic call to our facade.

## The facade pattern: key takeaways

1. A facade creates an authoritative representation of an external API or any complex system you interact with.
2. A facade serves as a bridge between an external API and the context of your application.
3. A facade aggregates the use cases in one dedicated place.
4. A facade prevents duplicated logic, reinventing the wheel, and creating multiple change points.

Cheers,

Rémi - [@remi@ruby.social](https://ruby.social/@remi)

[^1]: Are we, software engineers, so enticed with being actual engineers that we keep using architectural metaphors to lend ourselves some credibility?
[^2]: Marcel Duchamp had the best mind for cool namings.
