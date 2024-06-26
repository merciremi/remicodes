---
layout: post
title: "Add comments to your tables columns"
excerpt: "By default, Rails adds comments to some attributes like `id` (`not null, primary key` for instance.) But now, I can add comments to my own attributes."
date: 2024-06-22
permalink: /comment-tables-columns-attributes/
category: rails
cover_image: "/media/2024/06/remi-mercier-comment-columns-attributes-rails.png"
---

I've been looking for a way to add default comments on models attributes *for ages*!

By default, Rails adds comments to some attributes like `id` (`not null, primary key` for instance.)

But now, I can add my own. For example, I can specify the unit for a duration column. It's like Yard documentation for methods, but for attributes.

These default comments are defined in your `schema.rb`, so gems like [annotate](https://github.com/ctran/annotate_models){:target="\_blank"} will pick them up. No need to worry about overwrite anymore.

{% highlight ruby %}
  class Book
    # == Schema Information
    #
    # Table name: books
    #
    #  id          :integer    👉 not null, primary key 👈
    #  duration    :integer   👉 in seconds 👈
    #
  end
{% endhighlight %}

See this lil' `in seconds` above, that's me, adding extra documentation to my tables column so my teamates don't have to guess the unit.

Here's how to do that in a migration adding a new column:

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

Go and document those attributes!

Cheers,

Rémi - [@remi@ruby.social](https://ruby.social/@remi)
