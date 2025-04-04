---
layout: post
title: How to build a minimal decorator with Ruby
excerpt:
date: 2000-01-01
permalink:
category:
cover_image:
---
This is walkthrough.

The other day, I needed view-related method to call on my user, has to display some information. So, I thought about wrapping my user in a decorator.

The decorator is a pattern that allows you to wrap you object in an other object that has new properties.

Fun thing, i would normally use draper or such gems, but the app I'm working with is an old Rails version, and draper is not compatible. So, i thought, time to make minimal implementation of a decorator object for my app.

So, I have a kind of User that is a teacher. But teachers are only avalaible when the number of students they chappote is smaller than the max number of students. All this logic belongs in the model.

teacher.max_number_of_students => 30
teacher.students.size => 20
teacher.available_places => 10

So far, so good.

Now, I need to display this availability as a CSS class that will colorize the background of a row a color based on the value. Red : unavailable. Yellow : nearing soon-unavailable. Green : available.

Having a method returning a css class does not belong in the model, or in the controller. And I don't like helper methods for this kind of stuff. So decorator.

{% highlight ruby %}
class TeacherDecorator
  def initialize(teacher)
    @teacher = teacher
  end
end
{% endhighlight %}

So :

{% highlight zsh %}
decorated_teacher = TeacherDecorator.new(teacher)

decorated_teacher # => #<TeacherDecorator:0x0000000130ba0258 @teacher = #<Teacher id: 252, email: "bob@teacher.com">
{% endhighlight %}

Now i can add my method to compute availability as css class.

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
end
{% endhighlight %}

{% highlight zsh %}
decorated_teacher = TeacherDecorator.new(teacher)

decorated_teacher.availability_as_background # => "background-success"
{% endhighlight %}

## Make decorated_teacher responds to methods for the user

Now, in my view, my `@teacher` is not an instance of `Teacher` anymore, but an instance of `TeacherDecorator`. Which means that the public methods used in my view which were leaning on `Teacher` are now not working.

But i'd like to have them work anyway. How?

With `method_missing`

First time i use `method_missing` for something actually useful, and not just to show i can. But metaprogramming is a sharp knife.

The idea here is that when i call `@teacher.first_name`, i need my decorator to rescue the `NoMethodError` it'll raise, and pass the method along to the underlying `Teacher` instance.

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
    if teacher.respond_to?(method)
    teacher.public_send(method, *args, &)
    else
      super
    end
  end

  def respond_to_missing?(name, include_private)
    record.respond_to?(name) || super
  end
end
{% endhighlight %}

## Make the decorator logic applicable to other classes
- create application decorator
- use @record + alias in teacher decorator
- move method missing to application decorator

## Ensure Rails use underlying teacher in view helpers

`edit_teacher_path(@teacher)` will generate `teachers/#TeacherDecorator/edit` and not `teachers/1/edit`. Why? because @teacher is a TeacherDecorator instance.

So, how does rails convert a normal `teacher` into its id when passed to a path?

Thanks to `to_param` method (link to code)

So, if i want to reanable that behavior, i need to `delegate :to_param, to: :record` so to_param will be called on the instance of teacher, as rails expects.

ANd bam! it works.
