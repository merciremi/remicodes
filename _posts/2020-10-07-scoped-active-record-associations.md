---
layout: post
title: Scoped Active Record Associations
date: 2020-10-07
excerpt: "Active Record Associations are a great feature of Rails. But I had never thought of using them as scopes until last week! So let me show you a neat little trick that'll make your code much much more expressive (and keep your N+1 queries in check)."
category: 'rails'
permalink: /scoped-active-record-associations/
---

Active Record Associations are a great feature of [Ruby on Rails]({{site.baseurl}}/series/rails/). Associations allow you to declare - well - associations between your models. AR Associations also allow you to write operations when several models are linked (e.g., `Author.first.books.create(title: 'I love Rails!')`).

But I had never thought of using them as scopes until last week! So let me show you a neat little trick that'll make your code much much more expressive (and keep your N+1 queries in check).

## Defining basic associations

I won't dig into the [basics of Active Record Associations](https://guides.rubyonrails.org/association_basics.html){:target="\_blank"}. If you don't know your way around them, go and read the doc first.

Let's define a couple of models with their associations.

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

Okay, so now we have a one-to-many relationship between an author and its books. In my console, I can query all the books from one author like this:

{% highlight zsh %}
  author = Author.first

  author.books
{% endhighlight %}

It will return a collection of books for my first author.

## Filtering things out with scopes

Now, let's say some books can either be available or not available. What I'd like is to get a collection of all the books that are currently available in my application.

How can I filter out unavailable books?

I could write something like this:

{% highlight zsh %}
  available_books = author.books.where(available: true)
{% endhighlight %}

But what if I write this line above in multiple places in my code? Well, if I decided to change the condition of the collection, I would need to edit my code several times. This would be time-consuming, and error-prone.

To DRY things up, I can write a scope in my `Book` model to centralize the `where(available: true)` bit.

{% highlight ruby %}
  class Book < ApplicationRecord
    belongs_to :author

    scope :available, -> { where(available: true) }
  end
{% endhighlight %}

The `available` scope now lets me do this:

{% highlight zsh %}
  author.books.available
{% endhighlight %}

It looks already more readable, right?

One caveat with scopes is that [they are not preloaded](https://www.justinweiss.com/articles/how-to-preload-rails-scopes/){:target="\_blank"}. This'll eventually results in N+1 queries.

{% highlight zsh %}
  authors = Author.first(2)

  authors.map do |author|
    "#{author.first_name} has #{author.books.available.length} books available"
  end

  Author Load (0.3ms)  SELECT "authors".* FROM "authors" ORDER BY "authors"."id" ASC LIMIT ?  [["LIMIT", 2]]
  Book Load (0.3ms)  SELECT "books".* FROM "books" WHERE "books"."author_id" = ? AND "books"."available" = ?  [["author_id", 1], ["available", 1]]
  Book Load (0.1ms)  SELECT "books".* FROM "books" WHERE "books"."author_id" = ? AND "books"."available" = ?  [["author_id", 2], ["available", 1]]

  => ["Bob has 2 books available", "Starhawk has 0 books available"]
{% endhighlight %}

What you see above are N+1 queries: one query for the author, one query for each book. Not something you want to keep around in your code.

Let's make our code more expressive and robust!

## Scoped associations

Remember our `available` scope?

{% highlight ruby %}
  class Book < ApplicationRecord
    belongs_to :author

    scope :available, -> { where(available: true) }
  end
{% endhighlight %}

I can define a new association with the `available` scope as a parameter.

{% highlight ruby %}
  class Author < ApplicationRecord
    has_many :books
    has_many :available_books, -> { available }, class_name: 'Book'
  end
{% endhighlight %}

Please note that I'm passing:
- the name of the scope - `available` - in the association lambda
- the name of the class the association points to, with the key `class_name`

Now, I can query available books like this:

{% highlight zsh %}
  author.available_books
{% endhighlight %}

It reads like plain English. Beautiful, isn't it?

I also like that the model `Author` doesn't get to know about the internal logic of books' availability. This logic is encapsulated in the `Book` model because it only concerns books. Neat!

## Scoped many-to-many associations

What if our books have several authors? How do we scope through the `has_many` association?

Let's edit our models.

{% highlight ruby %}
  class Author < ApplicationRecord
    has_many :books, through: :authors_books
  end
{% endhighlight %}

{% highlight ruby %}
  class Book < ApplicationRecord
    has_many :authors, though: :authors_books

    scope :available, -> { where(available: true) }
  end
{% endhighlight %}

{% highlight ruby %}
  class AuthorsBook < ApplicationRecord
    belongs_to :author
    belongs_to :book
  end
{% endhighlight %}

We changed the nature of the association in `Book` and added a third table to handle the relationship: `AuthorsBooks`. Let's re-create the `has_many :available_books` association.

{% highlight ruby %}
  class Author < ApplicationRecord
    has_many :books, through: :authors_books

    has_many :available_books, -> { available }, through: :authors_books, source: :book
  end
{% endhighlight %}

Like for the  `belongs_to` association, we passed the name of the scope in a lambda. Only this time, we send it through the `authors_books` table. Note that we're not using `class_name` anymore. We're using `source` instead *as per* [Rails documentation](https://guides.rubyonrails.org/association_basics.html#options-for-has-many-source){:target="\_blank"}.

And what about preloading?

{% highlight zsh %}
  authors = Author.includes(:available_books).first(2)

  authors.map do |author|
    "#{author.first_name} has #{author.available_books.length} books available"
  end

  Author Load (0.2ms)  SELECT "authors".* FROM "authors" ORDER BY "authors"."id" ASC LIMIT ?  [["LIMIT", 2]]

  Book Load (0.5ms)  SELECT "books".* FROM "books" WHERE "books"."available" = ? AND "books"."author_id" IN (?, ?)  [["available", 1], ["author_id", 1], ["author_id", 2]]

  => ["Bob has 2 books available", "Starhawk has 0 books available"]
{% endhighlight %}

Thanks to `includes`, I can preload my scoped association. No more N+1 queries: one query for the author and one query for all the books. Note that, in my loop, I can replace `author.books.available` with `author.available_books` for more readability.

I hope it'll help next time you need to access a scope through a `has_many` association!

Did I miss something? [Submit an edit on GitHub](https://github.com/merciremi/remicodes/issues/new){:target="\_blank"}.

Cheers,

Rémi - [@mercier_remi](https://twitter.com/mercier_remi){:target="\_blank"}
