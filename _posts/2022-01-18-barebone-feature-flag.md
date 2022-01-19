---
layout: post
title: "Build a minimal feature flags manager in under an hour"
excerpt: "Feature flags (or feature toggles) are a neat way to hide in-progress features from your users. For those who need a simple on-and-off system, here's a minimal feature flag manager that'll take less than an hour to build, using plain Ruby objects, the Rails configuration, and some neat variables organization."
date: 2022-01-18
permalink: /minimal-feature-flags-manager/
category: ['ruby', 'rails']
cover_image: '/media/2022/01/remi-mercier-build-feature-flags-manager.png'
---

When you deploy your code continuously, feature flags are a neat way to hide in-progress features from your users. In the past, I've written about [my process for releasing large features]({{site.baseurl}}/building-large-features-process/). But after using feature flags in the last six months, I've come to like them better than my former process.

Still, hiding behavior behind `if ENV['MY-FEATURE'].present?`-type conditionals bothers me.

First, I don't think the syntax is very legible. Second, I _know_ it's hard to maintain a naming convention across a team. You'll soon end up with endless variations: `ENV['MY-FEATURE]`, `ENV[FF-MY-FEATURE-NAME]`, `ENV['TOGGLE-FEATURE']`, etc... These discrepancies make it hard to keep track of all your feature flags.

Sure, you could use a gem or a third-party service. But for those who just need an _on-and-off_ system, here's a minimal feature flag manager that'll take you less than an hour to build. It's a plain [Ruby]({{site.baseurl}}/series/ruby) object but its configuration leans on [Ruby on Rails]({{site.baseurl}}/series/rails). I'm sure a Ruby-only implementation wouldn't be too hard to whip up, though.

## Expected outcome

Instead of `if ENV['EDITORIAL_FEED_FEATURE'].present?`, I'd like to see this syntax:

{% highlight ruby %}
  if Features.enabled? :editorial_feed
{% endhighlight %}

While looking at it, a few ideas come to mind:
- My `Features` class will need access to all available feature flags and check if the flag passed as argument is present and enabled.
- All my feature flags will need to follow the same naming strategy.
- Since I'll probably still use environment variables at some level of my stack, I'll need somewhere to centralize all those variables related to feature flags.
- My method `enabled?` should return either `true` or `false`.

A basic implementation of my `Features` class could be this:

{% highlight ruby %}
  class Features
    def self.enabled?(feature)
      # check if _feature_ is in the list of flags AND enabled
    end
  end
{% endhighlight %}

## A shameless green version

What behavior should we expect from our `Features` class?

If you pass a feature's name to `Features.enabled?`, the method should:
- Check if the feature's name is present in a list of feature flag.
- Check if the feature flag is either `true` or `false`.
- Return a boolean.

Let's draft our first test.

{% highlight ruby %}
  RSpec.describe Features do
    describe '.enabled?' do
      subject { described_class.enabled?(feature) }

      let(:feature) { :my_feature }

      it { is_expected.to be_in([true, false]) }
    end
  end
{% endhighlight %}

A minimal implementation could be:

{% highlight ruby %}
  class Features
    FEATURES = {
      audiobooks: false,
      comic_strips: true,
      editorial_feed: true
    }.freeze

    def self.enabled?(feature)
      FEATURES[feature.to_sym]
    end
  end
{% endhighlight %}

This code is problematic on several levels. Our test is green, though. If you were to put this code into the world right now, it'll work. I also like that all feature flags are neatly organized in one place.

Some of the problems we can guess:
- Every time we need to switch a feature flag from `false` to `true`, we'll have to push changes to production.
- Having a constant in the class might prove inefficient when the number of flags grows.
- We're not relying on environment variables like we originally intended to.

Let's try and tackle the latter first.

## Use environment variables

The smallest step we can take is to replace hardcoded values with environment variables.

{% highlight ruby %}
  class Features
    FEATURES = {
      audiobooks: ENV.fetch('AUDIOBOOKS_FEATURE', false),
      comic_strips: ENV.fetch('COMIC_STRIPS_FEATURE', false),
      editorial_feed: ENV.fetch('EDITORIAL_FEED_FEATURE', false)
    }.freeze

    def self.enabled?(feature)
      FEATURES[feature.to_sym]
    end
  end
{% endhighlight %}

With this code, our test still passes but not for the right reasons.

The application evaluates the presence of environment variables at runtime. If one misses in `ENV`, the variable will default to `false` instead of crashing (thanks to `fetch` accepting a default value).

So our test does not _really_ evaluate the presence and setting of our feature flags. It only tests if the return value is truthy or falsy. And it is, since `fetch` defaults to `false` every time. We could mock the value `ENV` returns, but it'll couple our tests too tightly to our testing environment. This _smells_ like a bad idea.

Our tests could be better if we changed the expectation from `.to be_in([true, false])` to a more constrained `.to be(true)`. This would make sure that the tests don't return a false positive.

Another thing I don't like is passing variables - which are _variable_ by definition - to a constant? Meh.

I'd rather group these variables into a dedicated file. If we could load all these feature flags' variables at boot time, we'd save up some time when our application needs to evaluate those flags.

## Move your environment variables to a single file and load them at boot time

One way to group your feature flags in the standard [Rails configuration](https://guides.rubyonrails.org/v5.1/configuring.html#custom-configuration){:target="\_blank"}. And it's simpler than it sounds.

You can create a custom accessor in your Rails configuration that leans on a single YAML file.

First, go to your `application.rb`. At the end of the `Application` class, add your own configuration.

{% highlight ruby %}
  # in config/application.rb
  module MyApp
  class Application < Rails::Application
    # ...

    config.features = config_for(:features)
  end
end
{% endhighlight %}

What's happening here? Now, your `Rails::Application::Configuration` class has a `features` accessor that you can call with `Rails.config.features`.

`Rails.config.features` will return an `ActiveSupport::OrderedOptions` that inherits from `Hash` and provides a dynamic accessor method.

Your application will now look for a `YAML` file named `features.yml`.

In your `config` directory, create a `features.yml` file. The first key represents the environment where your variables will apply. In our example, I've used `shared` which means that all environments will share the information.

{% highlight ruby %}
  # in config/features.yml
  shared:
    audiobooks: <%= ENV.fetch('AUDIOBOOKS_FEATURE', false) %>
    comic_strips: <%= ENV.fetch('COMIC_STRIPS_FEATURE', false) %>
    editorial_feed: <%= ENV.fetch('EDITORIAL_FEED_FEATURE', false) %>
{% endhighlight %}

We usually store strings in `YAML` files, but it's possible to execute Ruby code with the help of the `<%= =>` syntax.

Now, __we have a single file where all our feature flags and their respective environment variables will be neatly gathered__. I used to be a librarian, I love things arranged neatly.

## Access our feature flags through Rails configuration

Now, __a single file centralize all our feature flag keys and their respective environment variables__. I used to be a librarian. I love things arranged neatly.

It's time to get back to our `Features` class.

We don't need our constant anymore. But we need to pull the configuration in its place.

Let's whip up a second test.

{% highlight ruby %}
  RSpec.describe Features do
    describe '.configuration' do
      subject { described_class.configuration }

      it { is_expected.to be_an_instance_of(ActiveSupport::OrderedOptions) }
    end
  end
{% endhighlight %}

Let's try to code our method and make the test green.

{% highlight ruby %}
  class Features
    def self.configuration
      Rails.configuration.features
    end

    # ...
  end
{% endhighlight %}

Easy right! The test passes. On the other hand, we're creating a dependency between our `Features` class and the Rails configuration.

Now that we've made the change easy, it's just a matter of changing `FEATURES` by `configuration` in our `enabled?` method.

{% highlight ruby %}
  class Features
    def self.configuration
      Rails.configuration.features
    end

    def self.enabled?(feature)
      configuration[feature.to_sym]
    end
  end
{% endhighlight %}

The full test suite is:

{% highlight ruby %}
  RSpec.describe Features do
    describe '.configuration' do
      subject { described_class.configuration }

      it { is_expected.to be_an_instance_of(ActiveSupport::OrderedOptions) }
    end

    describe '.enabled?' do
      subject { described_class.enabled?(feature) }

      let(:feature) { :my_feature }

      it { is_expected.to be(true) }
    end
  end
{% endhighlight %}

Okay, so why does my second test throw a failure?

Well, we created a dependency between `Features.configuration` and the Rails configuration. And that dependency needs to be mocked!

{% highlight ruby %}
  RSpec.describe Features do
    describe '.configuration' do
      subject { described_class.configuration }

      it { is_expected.to be_an_instance_of(ActiveSupport::OrderedOptions) }
    end

    describe '.enabled?' do
      subject { described_class.enabled?(feature) }

      let(:feature) { :my_feature }

      before do
        allow(Rails.configuration).to receive(:features).and_return({ my_feature: true})
      end

      it { is_expected.to be(true) }
    end
  end
{% endhighlight %}

This'll take care of the dependency. Now, my tests pass.

## Check for different return scenarii

What happens if the feature we'd like to check is not in our list? `configuration[feature.to_sym]` will return `nil`. Let's update our tests accordingly.

{% highlight ruby %}
  RSpec.describe Features do
    describe '.configuration' do
      subject { described_class.configuration }

      it { is_expected.to be_an_instance_of(ActiveSupport::OrderedOptions) }
    end

    describe '.enabled?' do
      subject { described_class.enabled?(feature) }

      let(:feature) { :my_feature }

      before do
        allow(Rails.configuration).to receive(:features).and_return({ my_feature: true} )
      end

      it { is_expected.to be(true) }

      context 'with a feature not in the features list' do
        let(:feature) { :an_inexistant_feature }

        it { is_expected.to be(nil) }
      end
    end
  end
{% endhighlight %}

My third test passes. But by convention, `enabled?` should return a boolean, not `nil`. So we need to enforce its return type.

## Enforce a boolean return type

First, let's update our tests.

{% highlight ruby %}
  RSpec.describe Features do
    describe '.configuration' do
      subject { described_class.configuration }

      it { is_expected.to be_an_instance_of(ActiveSupport::OrderedOptions) }
    end

    describe '.enabled?' do
      subject { described_class.enabled?(feature) }

      let(:feature) { :my_feature }

      before do
        allow(Rails.configuration).to receive(:features).and_return({ my_feature: true} )
      end

      it { is_expected.to be(true) }

      context 'when the symbol is not present is our list of feature flags' do
        let(:feature) { :an_inexistent_feature }

        it { is_expected.to be(true) }
      end
    end
  end
{% endhighlight %}

There are several ways of doing this. Initially, I'd decided to modify `TrueClass`, `FalseClass`, and `NilClass` to accept a `to_boolean` method. Several readers pointed out it was _a tad_ overkill.

### Use hashes capabilities

Since `.configuration` return an object inheriting from `Hash`, we can use `.fetch` on it.

{% highlight ruby %}
  class Features
    def self.configuration
      Rails.configuration.features
    end

    def self.enabled?(feature)
      configuration.fetch(feature.to_sym, false)
    end
  end
{% endhighlight %}

What happens is if our `.configuration` contains `feature` we're passing along, `.enabled?` will return the boolean stored in the YAML. If `feature` is not present, `.fetch` will default to `false`.

### Use `.present?`

Another suggestion was using `.present?` on my configuration hash.

{% highlight ruby %}
  class Features
    def self.configuration
      Rails.configuration.features
    end

    def self.enabled?(feature)
      configuration[feature.to_sym].present?
    end
  end
{% endhighlight %}

The return results' strategy works as in the previous example.

### Use the double bang

A last suggestion was using `!!` a.k.a the _[double bang](https://stackoverflow.com/a/3994065){:target="\_blank"}_. This would look like this:

{% highlight ruby %}
  class Features
    def self.configuration
      Rails.configuration.features
    end

    def self.enabled?(feature)
      !!configuration[feature.to_sym]
    end
  end
{% endhighlight %}

The rationale behind it is:

> If you negate something, that forces a boolean context. Of course, it also negates it. If you double-negate it, it forces the boolean context, but returns the proper boolean value.

And voilà! Your feature flags manager is ready. Now, you can safely wrap your features with `Features.enabled? :editorial_feed` conditionals!

Hope you liked this code-along as much as I did!

Cheers,

Rémi

PS: Many thanks to [@NotGrm](https://twitter.com/NotGrm){:target="\_blank"}, [@sunfox](https://twitter.com/sunfox){:target="\_blank"}, [@_swanson](https://twitter.com/_swanson){:target="\_blank"}, and Kaloyan for their suggestions!
