---
layout: post
title: Scoped Active Record Associations
date: 2020-10-01
excerpt: ""
permalink: /scoped-active-record-associations/
---

Active Record Associations are a great feature of Rails. Associations allow you to declare - well - associations for your object with minimal hastle. But I'd never thought of using them to query scoped associations until last week. So let me show you a nice little trick that'll make your code expressive and keep your N+1 queries in check.

## Defining basic associations

I won't dig into the basics of Active Record Associations. I'll assume you know them already. So, let's write up a few models with their associations.

{% highlight ruby %}
  class Author < ApplicationRecord
    has_many :books
  end
{% endhighlight %}

{% highlight ruby %}
  class Book < ApplicationRecord
    belongs_to :author
  end
{% endhighlight %}

So far, so good. Now, I can write stuff like:

{% highlight zsh %}
  author = Author.first

  author.books
{% endhighlight %}

Which will return a collection of books for said author.

## Filtering things out with scopes

But what about filtering out the books that are currently unavailable on my application?

I could query it like this:

{% highlight zsh %}
  author.books.where(available: true)
{% endhighlight %}

I could also write a scope in my `Book` model.

{% highlight ruby %}
  class Book < ApplicationRecord
    belongs_to :author

    scope :available, -> { where(available: true) }
  end
{% endhighlight %}

Which would allow me to do:

{% highlight zsh %}
  author.books.available
{% endhighlight %}

Looks already more readable right?

Let's make that even more readable.

## Scoped associations

Remember our `available` scope?

{% highlight ruby %}
  class Book < ApplicationRecord
    belongs_to :author

    scope :available, -> { where(available: true) }
  end
{% endhighlight %}

Well, now we can use it in our `Author` model.

{% highlight ruby %}
  class Author < ApplicationRecord
    has_many :books
    has_many :available_books, -> { available }, class_name: 'Book'
  end
{% endhighlight %}

Now, I can query like this:

{% highlight zsh %}
  author.available_books
{% endhighlight %}

## The same with many-to-many associations

What if our books now have several authors?

{% highlight ruby %}
  class Author < ApplicationRecord
    has_many :books, through: :authors_books
  end
{% endhighlight %}

{% highlight ruby %}
  class Book < ApplicationRecord
    has_many :authors, though: :authors_books
  end
{% endhighlight %}

{% highlight ruby %}
  class AuthorsBook < ApplicationRecord
    belongs_to :author
    belongs_to :book
  end
{% endhighlight %}

You create the scope in `Book`.

{% highlight ruby %}
  class Book < ApplicationRecord
    has_many :authors, though: :authors_books

    scope :available, -> { where(available: true) }
  end
{% endhighlight %}

Then scope the association. Note that we're not using `class: 'Book'` anymore but `source: :book` as per Rails convention. #### find source

{% highlight ruby %}
  class Author < ApplicationRecord
    has_many :books, through: :authors_books

    has_many :available_books, -> { available }, through: :authors_books, source: :book
  end
{% endhighlight %}










- show diff of queries betwen instance methods and scoped associations

- first, show with code inside associations with lambda, then, show that you can pass scope directly


what about preloading?
