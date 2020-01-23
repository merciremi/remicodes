---
layout: post
title: manipulate tempfiles
---

- need: needed to create temporary files that I would wreate, send to a server, delete.
- at first i thought about creating a file in public folder then run a task to delete it but beurk.
- A while back I discovered tempfiles (link to docs)
- what are tempfiles? definition => files that are only available in the block you run
- how-to

when you do
```
Tempfile.open(stuff) do |file|
  # the file lives inside this block and ends here
  # except if it's stored in a var
end
```

A while back, I needed to handle temporary files. I had to create xml exports, send them to a distant server then delete them once the transfer is done.

At first, I thought about creating those files into my app's `tmp` directory. Then, a cron job would run every now and then to delete them. In would have worked in theory, but I wasn't very happy with it.

So after looking on the internet, I came accross `Tempfile` (and I - for the umpteenth time - rejoiced in using Ruby).

## Tempfiles 101

<blockquote>
  Tempfile is a utility class for managing temporary files. It behaves just like a File object, and you can perform all the usual file operations on it: reading data, writing data, changing its permissions, etc.
  <cite>
    the Ruby documentation
  </cite>
</blockquote>

So are there any differences between `Tempfile` and `File`? Glad you asked!

Files are created, persisted and are accessed from anywhere.

Tempfiles, on the other hand, only exist within the context they were defined. Lemme show you.

Let's create a file.

{% highlight irb %}
  class FileCreator
    def create_file
      file = File.new('my_file.md', 'r+')
      file.write('Bob wuz here.')
      file.rewind
      file
    end
  end

  file_creator = FileCreator.new

  my_file = file_creator.create_file # => #<File:my_file.md>
  my_file.read                       # => "Bob wuz here."
  File.basename(my_file.path)        # => "my_file.md"

{% endhighlight %}

Let's create a tempfile.

{% highlight irb %}
  class FileCreator
    def create_file
      Tempfile.open do |file|
        file
        file.write('Bob wuz here.')
        file.rewind
        file
      end
    end
  end

  file_creator = FileCreator.new

  my_file = file_creator.create_file # => #<File:my_file.md>
  my_file.read                       # => IOError: closed stream
  File.basename(my_file.path)        # => "20200123-83768-1wrlh4s"
{% endhighlight %}





When you create a `File`,

Tempfiles only exists as long as they are referenced. Meaning that if Once I leave this context, Tempfiles are automatically [garbage collected](https://stackify.com/how-does-ruby-garbage-collection-work-a-simple-tutorial/){:target="\_blank"}. Whereas Files are persisted outside of the context.

https://www.hilman.io/blog/2016/01/tempfile/
http://www.songjiayang.com/posts/where-is-my-tempfile
https://ruby-doc.org/core-2.7.0/IO.html#method-i-close


{% highlight zsh %}
  json_file = Tempfile.open(['.json']) do |file|
    file.write('bob wuz here')
    file
  end

  json_file.read # => IOError: closed stream
  # Means that the file is claimed by the garbage collector
  json_file.closed? # => true
  # Indeed, the file is closed. Means that the stream to the file is closed to further operations such as reading and writing

{% endhighlight %}

It means that once i get out of the block created by `#open`, the reference to the file is removed and when the garbage collector makes its sweep, it flagged my tempfile as ready for collection.







