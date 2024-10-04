---
layout: post
title: 'Interfacing with third-party APIs: the facade pattern in Ruby'
excerpt: ''
date: 2024-07-23
permalink: 
category: 
cover_image: 
---

Interacting with third-party APIs is common practice in applications: converting addresses into geographic coordinates, fetching subscription information from marketplaces, prompting an LLM, etc.

Coding with Ruby, you'll often find gems providing a first abstraction over third-party APIs: the client layer. The client layer is often responsible for authenticating and accessing the features of external APIs.

One could use the client as is and sprinkle calls to the external API across their codebase. By doing so, teams will usually create duplicated logic, reinvent the wheel, and create multiple points of change.

One way to _DRY_ this up is to create an **authoritative representation** of the external API and **how it relates to your domain logic**. This is where the structural design pattern called **facade** comes into play.

## A brief introduction to the facade design pattern

Before we start, let's acknoledge one caveat: there is **no definitive consensus on the definition of the facade pattern**. For instance, the facade pattern and the gateway pattern are often used interchangeably.

Let's hear what others have to say about it.

### The facade pattern as defined in [Design Patterns: Elements of Reusable Object-Oriented Software](http://wiki.c2.com/?FacadePattern){:target="\_blank"}:

> [Facades] provide a unified interface to a set of interfaces in a subsystem. Facade defines a higher-level interface that makes the subsystem easier to use. This can be used to simplify a number of complicated object interactions into a single interface.

From this definition, we can deduce some key points:
- A facade simplifies the interactions between a system and a complex subsystem.
- A facade provides a single point-of-interaction.
- A facade does not add any feature to the subsystem.
- A facade is transparent to the subsystem.
- A facade's intention flows outward (from within to the ouside, from an internal system to an external system).

### The facade pattern as defined by [Martin Fowler](https://martinfowler.com/articles/gateway-pattern.html){:target="\_blank"}:

> While Facade simplifies a more complex API, it's usually done by the writer of the service for general use. A gateway is written by the client for its particular use.

From Martin Fowler's post on gateways, we can deduce that:
- The facade pattern served as a stepping stone for his own gateway pattern.
- The facade flows outward ("build by the writer of the service for general use") whereas the gateway flows inward (build "by the client for its particular use").
- The facade and the gateway are somewhat used interchangeably.

> [API gateway] is really more of a facade, since it's build by the service provider for general client usage.

### The facade pattern as defined on [Refactoring Guru](https://refactoring.guru/design-patterns/facade){:target="\_blank"}:

> Facade is a structural design pattern that provides a simplified interface to a library, a framework, or any other complex set of classes. [...] A facade might provide limited functionality in comparison to working with the subsystem directly. However, it includes only those features that clients really care about.

From this definition, we can infer:
- A facade acts a simplified interface to a more complex system.
- A facade can chose to only expose the necessary functionalities of a complex system.
- A facade has neither inward nor outward flows.

Overall, even amongst our trusted pairs, the definition of the facade vary. And many more people have [many](https://stackoverflow.com/a/13593045){:target="\_blank"} [more](https://stackoverflow.com/a/13496995){:target="\_blank"} [definitions](https://stackoverflow.com/a/4604911){:target="\_blank"}.

For the rest of this article, I'll use the term "facade" as:

> A simplified interface normalizing the interactions between the context of my application and a complex system.

## Why do I need a facade for?

Let's conjure up a little bit of context first.

We're building a text editor for students: it's packed with features that'll make their life easier.

Some students are currently working on an assignemnt. Before submitting their work, they'd like to check if their answer is correct and get additional suggestions for their answer.

To do that, our application could connect to an LLM, send relevant information and get a list of suggestions. Easy peasy.

Let's build it!

{% highlight ruby %}
module Answers
  class SuggestionsController
    def create
      # LLM::Client is defined by an imaginary gem
      llm_client = LLM::Client.new

      llm_client.login(credentials:).chat(parameters: default_parameters.merge(suggestion_parameters))
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

    def suggestion_parameters
      {
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

Our `Answers::SuggestionsController` only fetches suggestions from the external API, yet the boilerplate code is already several steps long:
- Instantiate a client,
- authenticate with the external service,
- pass default parameters,
- pass tailored parameters,
- get the necessary information from our own application.

Now that we drafted our feature, a couple of questions arise:
- What if we needed to add steps when we fetch suggestions?
- What if we needed to interact with the external API elsewhere in our application?

Let's write some more code.

{% highlight ruby %}
module Answers
  class SuggestionsController
    def create
      llm_client = LLM::Client.new

      llm_client.login(credentials:).chat(parameters: default_parameters.merge(suggestion_parameters))
    end

    ...
  end
end

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
            { role: "system", content: "I'm working on an admission application to my local university." },
            { role: "system", content: "Are there any improvements I could add to my application" },
            { role: "user", content: "Format the suggestion like this: #{formatting}"}
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

We now have a new controller: `Admissions::ApplicationsController`. This controller helps students get feedback on their universities applications.

Already, some saillant points start standing out:
- Boiler plate code is repeated.
- The `LLM::Client` exposes a couple of domain-agnostic methods: `chat` that takes a list of `messages`. And it's hard to infer the link between its interface and our domain.
- Custom instructions (like `formatting` or the context of the question `amdinssion` versus `answers`) are hidden accross the application which makes it impossible for a team to not repeat itself + share the knowledge.

## Building an authoritative representation

NOw is the time to build a facade, that will serve as a single point of interaction with the third party API + will federate the knowledge and domain logic in one place.

First, let's encapsulate the basic configuration used for the authentication strategy, and create a client.

{% highlight ruby %}
  # app/facades/llm_facade

  class LLMFacade
    attr_reader :configuration, :llm_client

    def initialize
      @configuration ||= Configuration.new
      @llm_client|| = LLM::Client.new.login(credentials: configuration.credentials)
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

Now I can create a new facade for my third-party API, with a default configuration for auth, and embed the gem-provided logic of the client.

Note I'm using nested value object called `Configuration`. I like this object-first approach over using a hash in the encapsulating class.

Now let's add a method to fetch suggestion.

{% highlight ruby %}
  # app/facades/llm_facade

  class LLMFacade
    attr_reader :configuration, :llm_client

    def initialize
      @configuration ||= Configuration.new
      @llm_client|| = LLM::Client.new.login(credentials: configuration.credentials)
    end

    def fetch_suggestion_for(question, answer)
      llm_client.chat default_parameters.merge(suggestion_parameters_for(question, answer))
    end

    private

    def default_parameters = { model: configuration.model, messages: [] }

    def suggestion_parameters_for(question, answer)
      {
        messages: [
          { role: 'user', content: "This is the question I'm answering about: #{question}" },
          { role: 'user', content: "This is the answer I've written: #{answer}" }
        ]
      }
    end

    class Configuration
      attr_reader :credentials

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

Now, let's add suggestions for admissions.

{% highlight ruby %}
  # app/facades/llm_facade

  class LLMFacade
    attr_reader :configuration, :llm_client

    def initialize
      @configuration ||= Configuration.new
      @llm_client|| = LLM::Client.new.login(credentials: configuration.credentials)
    end

    def fetch_suggestion_for(question, answer)
      llm_client.chat default_parameters.merge(suggestion_parameters_for(question, answer))
    end

    def fetch_suggestion_for_admission(assignment, admission)
      llm_client.chat default_parameters.merge(suggestion_parameters_for_admission(assignment, admission))
    end

    private

    def default_parameters = { model: configuration.model, messages: [] }

    def suggestion_parameters_for(question, answer)
      {
        messages: [
          { role: 'user', content: "This is the question I'm answering about: #{question}" },
          { role: 'user', content: "This is the answer I've written: #{answer}" }
        ]
      }
    end

    def suggestion_parameters_for_admission(assignment, admission)
      {
        messages: [
          { role: 'user', content: "This is the assignment I'm answering about: #{assignment}" },
          { role: 'user', content: "This is the admission blurb I've written: #{admission}" }
        ]
      }
    end

    class Configuration
      ...
    end
  end
{% endhighlight %}

If this looks the same, it's because it is. Let's refactor this.

{% highlight ruby %}
  # app/facades/llm_facade

  class LLMFacade
    attr_reader :configuration, :llm_client

    def initialize
      @configuration ||= Configuration.new
      @llm_client|| = LLM::Client.new.login(credentials: configuration.credentials)
    end

    def fetch_suggestion_for(directive, output)
      llm_client.chat(
        default_parameters.merge(suggestion_parameters_for(directive, output))
      )
    end

    private

    def default_parameters = { model: configuration.model, messages: [] }

    def suggestion_parameters_for(directive, output)
      {
        messages: [
          { role: 'user', content: "This is the directive I'm given: #{directive}" },
          { role: 'user', content: "This is the answer I've written: #{output}" }
        ]
      }
    end

    class Configuration
      ...
    end
  end
{% endhighlight %}

A note, we could use some [riffin](kasper) for finding good overarching concepts for this `fetch_suggestion_for`.

Some ideas that we could use:
- For questions: question, directive, instruction, assignment
- For answers: answer, output, response, production

Another thing to note, even if we decided to stick with the duplication, the facade gather the complexity, hence avoiding teams to dispatch complexity accross the application, hence making it easier to see potential refactorings and focus work.

Already, when we'll call `LLMFacade.new.fetch_suggestion_for()`, it'll be easier to understand that `LLM::Client.login().chat(messages: [])`. It'll be more connected to our domain.






Do a first version with specific information, then thry to give it more modularity on names and types of objects you use.




