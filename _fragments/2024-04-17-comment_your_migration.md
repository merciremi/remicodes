---
layout: fragment
date: 2024-04-17
title: "Comment your tables' columns from your migration files"
permalink: /comment-attributes/
---

Here's a nifty TIL.

I've been looking for a way to add default comments on models attributes *for ages*! These default comments are picked up by gems like [annotate](https://github.com/ctran/annotate_models){:target="\_blank"}, so no need to worry about overwrite.

{% highlight ruby %}
  class Book
    # == Schema Information
    #
    # Table name: books
    #
    #  id          :integer    👉 not null, primary key 👈
    #  duration    :datetime   👉 in seconds 👈
    #
  end
{% endhighlight %}

By default, Rails adds comments to some attributes like `id` (see `not null, primary key` above).

But now, I can add my own. For example, I can specify the unit for a duration.

Here's how to do that in a migration:

{% highlight ruby %}
class AddDurationToBooks < ActiveRecord::Migration[7.0]
  def change
    add_column :books, :duration, :integer, comment: "in seconds", default: 0, null: false
  end
end
{% endhighlight %}

I can also add a default comment to an existing attribute:

{% highlight ruby %}
class AddCommentToBooksDuration < ActiveRecord::Migration[7.0]
  def change
    change_column_comment(:books, :duration, from: nil, to: "in seconds")
  end
end
{% endhighlight %}

Passing a hash containing `:from` and `:to` will make this change reversible in migrations.
