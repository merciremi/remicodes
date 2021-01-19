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
