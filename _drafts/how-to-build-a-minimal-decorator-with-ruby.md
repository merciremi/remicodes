---
layout: post
title: Build a minimal decorator with Ruby in 30 minutes
excerpt: A while ago, I needed to add some view-related instance methods to a model. Decorators are my go-to pattern to handle this kind of logic. So, I built a minimal decorator from scratch, added a bunch of extra behaviors, only to end up abstracting all of that away. Follow along!
date: 2025-06-09
permalink: /minimal-decorator-ruby/
category: ruby
cover_image: "/media/2025/06/minimal-decorator-ruby-remi-mercier.png"
---

A few weeks ago, I needed to add some view-related methods to an object. Decorators are my go-to pattern to handle this kind of logic.

Normally, I'd use the [draper](https://github.com/drapergem/draper){:target="_blank"} gem to build decorators. But the app I'm working on used an older and incompatible version of Rails.

So I built a minimal decorator from scratch, added a bunch of extra behaviors, only to end up abstracting all of these away. Follow along!

## What I'm working with

My `Teacher` class has a handful of methods:
  - A one-to-many relationship with the `Student` class.
  - Two public methods: one that exposes the maximum number of students a teacher can teach to, and one exposing the available teaching places.

{% highlight ruby %}
  class Teacher < ApplicationRecord
    has_many :students

    def maximum_number_of_students = 30

    def available_places
      (maximum_number_of_students <=> students.size).clamp(0..)
    end
  end
{% endhighlight %}

In my views, I want to display a table of teachers where the number of available places for each teacher is backed by a background colour.

<img class='large' src="{{ site.baseurl }}/media/2025/06/minimal-decorator-table-example-remi-mercier.png" alt="a screenshot of a table with teachers names and available spaces for each">

{% highlight ruby %}
# teachers/index.html.erb

<table class="table table-striped">
  <thead>
    <tr>
      <th>Name of the teacher</th>
      <th>Available places</th>
    </tr>
  </thead>
  <tbody>
    <% teachers.each do |teacher| %>
      <tr>
        <td><%= teacher.full_name %></td>
        <td class="<%= teacher.colour_coded_availability %>">
            <%= teacher.available_places %>
        </td>
      </tr>
    <% end %>
  </tbody>
</table>
{% endhighlight %}

I could write the `Teacher#colour_coded_availability` method in my model like so:

{% highlight ruby %}
  class Teacher < ApplicationRecord
    has_many :students

    def maximum_number_of_students = 30

    def available_places
      (maximum_number_of_students <=> students.size).clamp(0..)
    end

    def colour_coded_availability
      case available_places
      when 0 then "bg-colour-red"
      else "bg-colour-green"
      end
    end
  end
{% endhighlight %}

However, models are not the place for methods generating CSS classes. Decorators are!

## Drafting a decorator

My decorator should accept an instance of `Teacher` and expose the `colour_coded_availability` public method.

{% highlight ruby %}
# app/decorators/teacher_decorator.rb

  class TeacherDecorator
    attr_reader :teacher

    def initialize(teacher:)
      @teacher = teacher
    end

    def colour_coded_availability
      case teacher.available_places
      when 0 then "bg-colour-red"
      else "bg-colour-green"
      end
    end
  end
{% endhighlight %}

Now, I can instantiate my decorator and use it in my views:

{% highlight ruby %}
# app/controllers/teachers_controller.rb
  class TeachersController < ApplicationController
    def index
      @teachers = Teacher.all.map { TeacherDecorator.new(teacher: _1) }
    end
  end

# teachers/index.html.erb
  <table class="table table-striped">
    <thead>
      <tr>
        <th>Name of the teacher</th>
        <th>Available places</th>
      </tr>
    </thead>
    <tbody>
      <% @teachers.each do |teacher| %>
        <tr>
          <td><%= teacher.full_name %></td>
          <td class="<%= teacher.colour_coded_availability %>">
              <%= teacher.available_places %>
          </td>
        </tr>
      <% end %>
    </tbody>
  </table>
{% endhighlight %}

When I can call `teacher.colour_coded_availability` in my views, the method retrieves a CSS class and adds it to the HTML `<td>` tag.

But if I were to run this code as is, I'd get a beautiful `NoMethodError`. Why?

My views do not handle instances of `Teacher` anymore. They handle instances of `TeacherDecorator`. So, when I'm calling the public methods defined on `Teacher`, the decorator doesn't know what to do with them.

My decorator needs to be able to handle both its own public methods and the public methods defined on the underlying record (`Teacher`, in this case).

And we do that by using Ruby's `method_missing`.

## Ruby's `method_missing` to the rescue

`method_missing` is how Ruby handles method calls made on objects where said methods are not defined. Ruby passes the method call along [the ancestry chain]({{site.baseurl}}/beginners-introduction-to-ruby-classes-objects/) until it can either resolves it or raises a `NoMethodError`.

When I call `@teacher.full_name`, I want my decorator to rescue the `NoMethodError`, and forward `#full_name` to the underlying instance of `Teacher`.

To do that, I need to re-open Ruby's `method_missing`, add a custom behavior, then allow `method_missing` to run its normal course.

{% highlight ruby %}
class TeacherDecorator
  attr_reader :teacher

  def initialize(teacher)
    @teacher = teacher
  end

  def availability_as_background
    case teacher.max_number_of_students <=> teacher.available_places
    when -1 then "background-danger"
    when 0 then "background-warning"
    when 1 then "background-success"
    end
  end

  private

  def method_missing(method, *args, &)
    return teacher.public_send(method, *args, &) if teacher.respond_to?(method)

    super
  end

  def respond_to_missing?(name, include_private = false)
    teacher.respond_to?(name) || super
  end
end
{% endhighlight %}

In this example, I keep the original signature of Ruby's `method_missing`.

The only thing I tweak is forwarding the method call to the underlying `teacher`. I only forward it if the `teacher` responds to the method. Then, I let Ruby resume its original behavior [^1].

Now, `@teacher.full_name` is properly forwarded to the underlying instance of `Teacher`.

What would be cool now, is to allow other decorators to share this behavior.

## Normalizing the behavior to create other decorators

One way to gather default behavior shared across various decorators is to rely on inheritance. I can create an `ApplicationDecorator` whose job is to handle instantiation, and forwarding method calls to the underlying record.

Then, I can have my `TeacherDecorator` inherit from the `ApplicationDecorator`.

{% highlight ruby %}
class ApplicationDecorator
  def initialize(record)
    @record = record
  end

  private

  attr_reader :record

  def method_missing(method, *args, &block)
    if record.respond_to?(method)
      record.public_send(method, *args, &block)
    else
      super
    end
  end

  def respond_to_missing?(name, include_private = false)
    record.respond_to?(name) || super
  end
end

class TeacherDecorator < ApplicationDecorator
  attr_reader :teacher

  def availability_as_background
    case teacher.max_number_of_students <=> teacher.available_places
    when -1 then "background-danger"
    when 0 then "background-warning"
    when 1 then "background-success"
    end
  end

  private

  alias_method :teacher, :record
end
{% endhighlight %}

My `TeacherDecorator` doesn't need to bother about its initialization since it's handled by the parent `ApplicationDecorator`. The only thing I added, is the ability to reference the `record` as `teacher` so it's clearer what kind of record we're working with.

## Ensure Rails default behavior works well

Some Rails native helpers will have a hard time handling my decorator.

Consider this code:

{% highlight ruby %}
  `edit_teacher_path(@teacher)` # => Should generate teachers/1/edit
{% endhighlight %}

But if `@teacher` references an instance of my `TeacherDecorator`, the generated path is `teachers/#TeacherDecorator/edit`.

How do I make my decorator integrate with Rails default behavior?

I can re-open the `to_param` method which is responsible for turning (among other things) a record into its `id`, and delegating its behavior to the record.

{% highlight ruby %}
class ApplicationDecorator
  def initialize(record)
    @record = record
  end

  delegate :to_param, to: :record

  private

  attr_reader :record

  def method_missing(method, *args, &block)
    if record.respond_to?(method)
      record.public_send(method, *args, &block)
    else
      super
    end
  end

  def respond_to_missing?(name, include_private = false)
    record.respond_to?(name) || super
  end
end
{% endhighlight %}

Of course, forwarding every Rails default behaviors to the underlying record is not a great strategy (too much complexity). So, how should I do it?

## Use Ruby standard SimpleDelegator

> [SimpleDelegator](https://ruby-doc.org/3.4.1/stdlibs/delegate/SimpleDelegator.html){:target="_blank"} provides the means to delegate all supported method calls to the object passed into the constructor.

This means that by using SimpleDelegator, I can remove the initialization and the delegation logics from my `ApplicationDelegator`.

{% highlight ruby %}
require "delegate"

class ApplicationDecorator < SimpleDelegator ; end
{% endhighlight %}

Everything is abstracted away. And it just works™. `@record` is not available anymore for my `TeacherDecorator` to reference, but SimpleDelegator exposes a `__getobj__` that works exactly as my previous `@record` ivar.

## Final implementation

Here's what I ended up with:

{% highlight ruby %}
require "delegate"

class ApplicationDecorator < SimpleDelegator ; end

class TeacherDecorator < ApplicationDecorator
  def availability_as_background
    case teacher.max_number_of_students <=> teacher.available_places
    when -1 then "background-danger"
    when 0 then "background-warning"
    when 1 then "background-success"
    end
  end

  alias_method :teacher, :__getobj__
end
{% endhighlight %}

That's it! A 30-minute minimal decorator in [plain Ruby]({{site.baseurl}}/series/ruby).

{% include signature.html %}

[^1]: `respond_to_missing?` only ensures that the `responds_to?` does not return false positives by allowing the decorator to respond to methods even if they are not statically defined on it.
