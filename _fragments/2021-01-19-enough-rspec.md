---
layout: fragment
title: Enough RSpec
date: 2020-11-12
permalink: /enough-rspec/
---

How to force the `user` variable as the serializer's scope:

{% highlight ruby %}
  # spec/serializers/book_serializer_spec.rb

  RSpec.describe BookSerializer do
    subject(:serialized_book) { serialize(book, scope: user) }

    let(:user) { create :user }
    let(:book) { ... }

    # test stuff
  end
{% endhighlight %}
