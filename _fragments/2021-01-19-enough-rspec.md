---
layout: fragment
title: Enough RSpec
date: 2021-01-19
permalink: /enough-rspec/
---

How to force the user as the serializer's scope:

{% highlight ruby %}
  # spec/serializers/book_serializer_spec.rb

  RSpec.describe BookSerializer do
    subject(:serialized_book) { serialize(book, scope: user) }

    let(:user) { create :user }
    let(:book) { ... }

    # test stuff
  end
{% endhighlight %}

Based on how you define the `it` part, different behaviors are to be expected:

{% highlight ruby %}
  # spec/serializers/things_controller_spec.rb

  RSpec.describe ThingsController do
    subject { post :create, params: params }

    # Implicitly calls subject
    it { is_expected.to redirect_to(thing_path(Thing.last)) }

    # Explicitly call subject
    it "redirects to the new thing's show" do
      expect(subject).to redirect_to(thing_path(Thing.last))
    end

    # Does not call subject
    # For this test to work, a before { subject } is needed
    it 'has correct flash message' do
      expect(flash[:notice]).to eq "The thing has been created."
    end
  end
{% endhighlight %}

## Fixtures

- Sometimes, it's easier to return an OpenStruct with the ad hoc attributes, than relying on factories. Especially if these are crippled with complicated setup or if you don't need a full factory for the return.

Just wrote this for mocking the return value of a facade sub-class (`SomeDomainName::FacadeTo3rdPartyAPI::Response`):

```
    let(:expected_response) do
      OpenStruct.new(content: "art, renaissance, Giotto")
    end
```


