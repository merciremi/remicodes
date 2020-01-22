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

## The problem:
A while back, I needed to create an XML file, send it to a distant server then delete it.

## The solution:
At first, I thought about create the file in my `tmp` folder, then have a cron job running every day to get rid of these files. Not super pretty, right?.

So after looking on the internets, I came accross Tempfiles (and I - for the umpteenth time - rejoiced in using Ruby).

## Tempfiles 101

<blockquote>
  Tempfile is a utility class for managing temporary files. It behaves just like a File object, and you can perform all the usual file operations on it: reading data, writing data, changing its permissions, etc.
  <cite>
    the Ruby documentation
  </cite>
</blockquote>

So are there any differences between `Tempfile` and `File`? Glad you asked!

Tempfiles only exists as long as they are referenced. Once I leave this context, Tempfiles are automatically [garbage collected](https://stackify.com/how-does-ruby-garbage-collection-work-a-simple-tutorial/){:target="\_blank"}. Whereas Files are persisted outside of the context.

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







