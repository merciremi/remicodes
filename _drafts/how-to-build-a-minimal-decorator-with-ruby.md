---
layout: post
title: How to build a minimal decorator with Ruby
excerpt:
date: 2000-01-01
permalink:
category:
cover_image:
---

A while ago, I needed to add some view-related instance methods to a model. Decorators are my go-to pattern to handle this kind of logic.

Normally, I'd use the [draper](https://github.com/drapergem/draper){:target="_blank"} gem to build decorators. But the app I'm working on was - at the time - built with an older and incompatible version of Rails.

So, I decided I'd build a minimal decorator from scratch.

## What I'm working with

My `Teacher` class has a handful of methods:
  - A one-to-many relationship with `Student`.
  - Two public methods: one exposing the maximum number of students a teacher can teach to, and one exposing the available teaching places.

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

However, models are not the place for methods generating CSS classes.

I like to keep my models as bare as possible. They're easier to test (amongst other things).

Let's move this logic into a homemade decorator.

## Drafting a decorator

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

When I can call `teacher.colour_coded_availability` in my views, the method retrives a CSS class and adds it to the HTML `<td>` tag.

But if I were to run this code as is, I'd get a beautiful `NoMethodError`. Why?

My views do not handle instances of `Teacher` anymore. They handle instances of `TeacherDecorator`. So, when I'm calling the public methods defined on `Teacher`, the decorator do not know what to do with them.

My decorator needs to be able to handle both its own public methods and the public methods defined on the underlying record (`Teacher`, in this case).

And we do that by using Ruby's `method_missing`.

## Ruby's `method_missing` to the rescue

A bit of yak shaving first: `method_missing` is how Ruby handles method calls made on objects where said methods are not defined. Ruby passes the method call along [the ancestry chain]({{site.baseurl}}/beginners-introduction-to-ruby-classes-objects/) until it can either resolves it or raise `NoMethodError`.

When I call `@teacher.first_name`, I want my decorator to rescue the `NoMethodError`, and forward `#first_name` to the underlying instance of `Teacher`.

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

The only thing I tweak is forwarding the method call to the underlying `teacher`. I only forward it if the `teacher` responds to the method. If not, I let Ruby resume the original behavior [^1].

Now that I have one decorator for my `Teacher` class, I'd like to extend this behavior to other models.

## Allow other models to rely on my decorator

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

  def initialize(teacher)
    super(teacher)
  end

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






- create application decorator
- use @record + alias in teacher decorator
- move method missing to application decorator


## Ensure Rails use underlying teacher in view helpers

`edit_teacher_path(@teacher)` will generate `teachers/#TeacherDecorator/edit` and not `teachers/1/edit`. Why? because @teacher is a TeacherDecorator instance.

So, how does rails convert a normal `teacher` into its id when passed to a path?

Thanks to `to_param` method (link to code)

So, if i want to reanable that behavior, i need to `delegate :to_param, to: :record` so to_param will be called on the instance of teacher, as rails expects.

ANd bam! it works.




[^1]: `respond_to_missing?` only ensures that the `responds_to?` does not return false positives by allowing the decorator to respond to methods even if they are not statically defined on it.




Now, you can simply use SImple Delegatro Ruby class
