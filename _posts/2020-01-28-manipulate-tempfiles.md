---
layout: post
title: Working with tempfiles
date:   2020-01-28
excerpt: "A while back, I needed to create XML files, send them to a distant server and delete them once the transfer completed. This is when I discovered Tempfiles and rejoiced in using Ruby."
permalink: /working-with-tempfiles/
cover_image: /media/2020/working-with-tempfiles-remi-mercier.jpeg
---

A while back, I needed to create XML files, send them to a distant server and delete them once the transfer completed.

At first, I thought about creating those files into my app's `tmp` directory. Then, a cron job would run daily to delete them. It would have worked, but I wasn't very happy with it.

So after looking on the internet, I came across the `Tempfile` object (and I - for the umpteenth time - rejoiced in using Ruby).

<blockquote>
  Tempfile is a utility class for managing temporary files. It behaves just like a File object, and you can perform all the usual file operations on it: reading data, writing data, changing its permissions, etc.
  <cite>
    the Ruby documentation
  </cite>
</blockquote>

## How-to tempfile?

Let's create a simple example. First, I'll [create an object]({{site.baseurl}}/beginners-introduction-to-ruby-classes-objects/) that generates a tempfile when instantiated. Then I'll export it on demand.

{% highlight ruby %}
  class FileExporter
    def initialize
      @my_file = create_file
    end

    def create_file
      Tempfile.open do |file|
        file.write('Bob wuz here.')
        file.rewind
        file
      end
    end

    def export_file
      Net::FTP.open('my_distant_server_address.com') do |ftp|
        ftp.login
        ftp.putbinaryfile(@my_file, remotefile = File.basename(@my_file))
      end
    end
  end
{% endhighlight %}

There! Here is the cool thing: once I'm done with my `FileExporter`, my tempfile will be automatically deleted. No need to do it manually.

But are there any differences between `Tempfile` and `File` objects?

## Tempfiles versus files

When you create a file, you can access it and perform operations on it from anywhere in your codebase as long as you have its path. Tempfiles behaves slightly differently.

When you create a tempfile, you can perform operations on it as long as its reference exists. Once the reference disappears, the [garbage collector](https://stackify.com/how-does-ruby-garbage-collection-work-a-simple-tutorial/){:target="\_blank"} automatically claims the tempfile.

Let me show you.

First, let's create a normal file.

{% highlight ruby %}
  class FileCreator
    def create_file
      file = File.new('my_file.md', 'r+')
      file.write('Bob wuz here.')
      file.rewind
      file
    end
  end
{% endhighlight %}

{% highlight irb %}
  file_creator = FileCreator.new

  my_file = file_creator.create_file # => #<File:my_file.md>
  File.basename(my_file.path)        # => "my_file.md"
  my_file.read                       # => "Bob wuz here."
{% endhighlight %}

You'll notice some subtleties:
- I need to pass a name and permissions as I create my file.
- I can read the content of my file despite being outside of the `FileCreator` class (i.e. outside of its original context)
- If I exit the current context or if my process dies, the file is created and can be accessed later.

Now, let's create a tempfile.

{% highlight ruby %}
  class FileCreator
    def create_file
      Tempfile.open do |file|
        file.write('Bob wuz here.')
        file.rewind
        file
      end
    end
  end
{% endhighlight %}

{% highlight irb %}
  file_creator = FileCreator.new

  my_file = file_creator.create_file # => #<File:my_file.md>
  File.basename(my_file.path)        # => "20200123-83768-1wrlh4s"
  my_file.read                       # => IOError: closed stream
  my_file.closed?                    # => true
{% endhighlight %}

Here, the tempfile doesn't need any input on my part for its name. It's automatically generated. Note that it is possible to specify a name and an extension too.

But the real interesting part is the `IOError: closed stream`.

It means that I can no longer perform operations on my tempfile - like reading its content - because the stream is now unavailable.

And why has the stream become unavailable? Here, I have two suspicions:

1) Because my tempfile was automatically closed when leaving its original context (the `Tempfile.open do [...] end` bit) and claimed by the garbage collector. This is suggested by the [Ruby documentation](https://ruby-doc.org/core-2.7.0/IO.html#method-i-close){:target="\_blank"}.

<blockquote>
  I/O streams are automatically closed when they are claimed by the garbage collector.
  <cite>the Ruby doc</cite>
</blockquote>

2) Because I use `Tempfile.open { ... }` (instead of `Templife.new`), `Tempfile#close` is implicitly called at the end of the block and closes the stream.

In any case, <mark>your temporary file will be deleted once the object is finalized</mark> (or when you lose the reference to the object).

## Tempfiles' quirks

Tempfiles are extremely useful when handled in strictly defined contexts, like a [railway-oriented business transaction]({{site.baseurl}}/transactions-in-rails/). But the following example can create some unwanted problems.

{% highlight ruby %}
  class FileCreator
    def create_file
      file = Tempfile.new
      file.write('Bob wuz here.')
      file.close
      file.path
    end
  end
{% endhighlight %}

{% highlight irb %}
  file_creator = FileCreator.new

  my_file_path = file_creator.create_file # => #<File:my_file.md>
  File.read(my_file_path)                 # => "Bob wuz here."
{% endhighlight %}

`FileCreator#create_file` now returns a path, not an actual reference to the file. It means that most of the time, you'll be able to read your file. But sometimes, you'll get an `Errno::ENOENT: No such file or directory @ rb_sysopen` error. Why? Because the garbage collector will have claimed your file during one of its collections. One solution would be to return the actual file - hence a reference.

So be careful when using tempfiles accross methods, classes, etc.

Read more about these quirks here:
- [Ruby Tempfile and Garbage Collection](https://www.hilman.io/blog/2016/01/tempfile/){:target="\_blank"}
- [where is my tempfile?](http://www.songjiayang.com/posts/where-is-my-tempfile){:target="\_blank"}

This whole tempfiles-are-garbage-collected-and-become-unavailable thing still feels a little fuzzy to me. But I'll keep digging at memory allocation.

Thank you [to the redditors](https://www.reddit.com/r/ruby/comments/ewm3mk/working_with_tempfiles/){:target="\_blank"} who helped make this article better through their suggestions and questions.

Noticed something? [Ping me on Twitter](https://twitter.com/mercier_remi) or [create an issue on GitHub](https://github.com/merciremi/remicodes/issues/new).

Cheers,

Rémi



