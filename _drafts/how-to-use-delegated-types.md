---
layout: post
title: "Delegated types in Rails: I tried them, and I'm not sure I really understood them"
excerpt: Delegated types are a modelization pattern introduced in Rails in 2020. And developers have mostly been scratching their head for a few years trying to use them in their applications. Today, I want to share a real-world use case. I'll walk you through my pre-existing domain architecture, my initial requirements, my mistakes, how I eventually used delegated types, what I learned and my open questions.
date: 18/04/2024
permalink: /delegated-types/
category: rails
cover_image: "/media/2024/04/remi-mercier-delegated-types-ruby-on-rails.png"
---

Delegated types are a modelization pattern introduced in Rails in 2020 [^1]. While researching this pattern for a feature, I found that existing articles overly focus on the theoretical comparison between delegated types, STI, and polymorphism. Examples used in these posts are often unrepresentative of the complexity of real-life applications.

Today, I want to share a real-world use case. I'll walk you through my pre-existing domain architecture, the initial requirements, my mistakes, how I eventually used delegated types, what I learned, and my open questions.

This post is not your typical tutorial, so prepare for some detours. Hopefully, this post will help you better understand how delegated types can fit (or not) in your codebase.

## The existing domain and the new requirements

First, let me explain the core domain and its logic.

I currently work on an application where `Students` can sign up for `subjects`.

Each subject is taught through `lessons`. So far, `Lesson` is the only abstraction representing a growing concept.

Teachers now want the ability to have different flavors of `lessons`: `lectures` and `directed studies`.

Lectures are open to every student enrolled in a subject. Directed studies are reserved for subsets of the students.

Lectures and directed studies are very similar in their representation. Both are a __modality__ of any given subject. Both have a name, a start time, and an end time.

However, each type of lesson __has its way of getting its list of students__:
- Lectures access their students through the subject, then through the `enrollments`.
- Directed studies access their students through groups, the latter being subsets of students.

Here is the graph I initially drew (the arrows representing the logical path for each version of the method `#students`):

{% highlight zsh %}
    +----------------+
    |    Students    | <----------+
    +----------------+            |
            ^                     |
            |                     |
    +----------------+    +----------------+
    |  Enrollments  |    | GroupsStudents |
    +----------------+    +----------------+
            ^                     ^
            |                     |
            |                     |
    +----------------+    +----------------+
    |   Subjects     |    |    Groups      |
    +----------------+    +----------------+
            ^                     ^
            |                     |
  +---------+                     +---------------+
  |                                               |
  | +----------------- Lessons ----------------+  |
  | | +----------------+    +----------------+ |  |
  | | |  Lectures      |    |Directed Studies| |  |
  | | +----------------+    +----------------+ |  |
  +---- #students      |    | #students ----------+
    | +----------------+    +----------------+ |
    +------------------------------------------+
{% endhighlight %}

In this graph, `enrollments` and `groups students` are join tables, which allow us to have many-to-many relationships. They might get some logic of their own later.

I've not represented `lessons` as a proper class yet. You probably already know `lessons`, `lectures`, and `directed studies` will end up as delegated types, but when I initially drew that graph, I didn't.

Here's a first draft in Rails:

{% highlight ruby %}
  class Student < ApplicationRecord
    has_many :enrollments
    has_many :subjects, through: :enrollments

    has_many :groups_students
    has_many :groups, through: :groups_students
  end

  class Subject < ApplicationRecord
    has_many :enrollments
    has_many :students, through: :enrollments

    has_many :lectures
  end

  class Lecture < ApplicationRecord
    belongs_to :subject
    has_many :students, through: :subject
  end

  class Group < ApplicationRecord
    has_many :groups_students
    has_many :groups, through: :groups_students

    has_many :directed_studies
  end

  class DirectedStudy < ApplicationRecord
    belongs_to :group

    has_many :students, through: :group
  end
{% endhighlight %}

Some things I'd like to point out:
- Moving through the associations is straightforward, thanks to ActiveRecord associations.
- My code lacks a `Lesson` abstraction to allow me to have an aggregative logic (i.e. `student.lessons` that would return lessons, regardless of their type).

## Why did I pick-up delegated types?

Before jumping to technical solutions, I like to start with the API I want to expose. For this feature, I want to write code like this:

{% highlight ruby %}
  subject.lessons # => returns a collection of lessons
  subject.lessons.lectures # => returns a collection of lessons while filtering out those of type "directed studies"
  subject.lessons.map(&:students) # => returns a collection of students regardless of the type of lessons
{% endhighlight %}

First, I need an aggregative logic (I want a collection of `lessons`), and an exclusive logic (I want a collection of only one type of `lessons`).

I also need a common API between `lectures` and `directed studies` (so I can call `students` without raising an error).

There is a lot of common logic between `lectures` and `directed studies`. Both have a `name`, a `start time`, and a `stop time`. But I also have some distinctive logic (how each type of `lesson` fetches its students).

To recap: I need a bit of Single Table Inheritance for the aggregation logic, a bit of polymorphism for the API, and some flexibility in terms of persisting the information.

After pondering these various requirements, I decided to try delegated types.

Delegated types allow me to:
- Store common information in a single table: `lessons`.
- Store specific information into ad hoc tables: `lectures` and `directed studies`.
- Query each type of `lessons` through a unifying class: `Lesson`.
- Have custom method implementation for each type: `students`.
- Index all `lessons` regardless of their type: `Lesson.all`.
- Have predicate methods generated by Rails on the fly: `Lesson.all.lectures`.

## My initial implementation (and mistakes)

The application I'm working on has a slightly more complex architecture. But one thing stands out: moving from `Student` to `Lecture` is the easiest path. So, early on, I was happy following Rails' convention of interacting with `lectures` through `lessons`.

On the other hand, fetching `students` for `directed studies` was less straightforward. So, instead of following Rails' convention, I  bypassed `lessons` and created a direct relationship between `directed studies` and `groups`.

This association was also a way to assert the exclusive nature of the relationship between `groups` and `directed studies`.

Here's an updated version of my graph:

{% highlight zsh %}
    +----------------+
    |    Students    | -----------+
    +----------------+ 1          |
            |1                    |
            |                     |
            |*                    |*
    +----------------+    +----------------+
    |  Enrollments  |    | GroupsStudents |
    +----------------+    +----------------+
    |  student_id    |    | student_id     |
    |  subject_id    |    | group_id       |
    +----------------+    +----------------+
            |*                    |*
            |                     |
            |1                    |1
    +----------------+    +----------------+
    |   Subjects     |    |    Groups      |
    +----------------+    +----------------+
            |1                        |1
            +-----------+             |
                        |*            |
                +----------------+    |
                |    Lessons     |    |
                +----------------+    |
                | id             |    |
                | name           |    |
                | start_at       |    |
                | end_at         |    |
                | lessonable     |    |
                | #students      |    |
                +----------------+    |
                        |1            |
            +-----------+----------+  |
            |1                     |1 |*
    +----------------+    +----------------+
    |  Lectures      |    |Directed Studies|
    +----------------+    +----------------+
    | #students      |    | #students      |
    +----------------+    +----------------+
{% endhighlight %}

You can already tell from this graph that things will turn ugly in about a minute.

Here's what models look like:

{% highlight ruby %}
  class Student < ApplicationRecord
    has_many :enrollments
    has_many :subjects, through: :enrollments

    has_many :groups_students
    has_many :groups, through: :groups_students
  end

  class Subject < ApplicationRecord
    has_many :enrollments
    has_many :students, through: :enrollments

    has_many :lessons, -> { lectures }
  end

  class Group < ApplicationRecord
    has_many :groups_students
    has_many :groups, through: :groups_students

    has_many :directed_studies
  end

  class Lesson < ApplicationRecord
    belongs_to :subject

    delegated_type :lessonable, types: ["Lecture", "DirectedStudy"]

    delegate :students, to: :lessonable
  end

  class Lecture < ApplicationRecord
    has_one :lesson
    has_many :students, through: :subject
  end

  class DirectedStudy < ApplicationRecord
    belongs_to :group
    has_one :lesson
    has_many :students, through: :group
  end
{% endhighlight %}

First, let us parse through the syntax of delegated types:
- The containing class `Lesson` defines the delegated types `Lecture` and `DirectedStudy` and refers to them as `lessonable`s.
- The containing class delegates the ad hoc methods to the delegated types.
- The containing class and its delegated types are associated through a `one-to-one` relationship, where `Lesson` carries the `id` of its delegated type.
- Hence, each delegated type accesses its containing class through a `has_one :lesson`.

However, the setup above has poor design. Can you guess what's wrong?

- `Subject` and `Group` should interact with the same abstraction (`Lesson`), but they don't.
- `Group` can create instances of associated `DirectedStudy` instead of creating instances of `Lesson`, but it loses the common data stored in `Lesson` in the process.

{% highlight zsh %}
  directed_study = Group.first.directed_studies.create! # => returns an instance of DirectedStudy
  directed_study.students # => Returns an AR collection of students
  directed_study.name # => NoMethodError: undefined method `name' for <DirectedStudy id: 1>
  directed_study.lesson # => nil
{% endhighlight %}

By bypassing `Lesson` when instantiating `DirectedStudy` through `Group`, I turned the design of delegated types on its head.

If I had to pick **one** takeaway, it'd be this:

<p class='callout'>
  Delegated types do not work in isolation. The main interface for interacting with delegated types is the containing class.
</p>

It was the moment I remembered that Rails provides you with sharp knives. Sure, you can stick them in your foot if you want, but that doesn't mean you should.

## Final implementation and main takeaways

After pulling my hair for a while, I updated my architecture to place the containing class `Lesson` as the only interface for interacting with `Lecture` and `DirectedStudy`.

Here's an updated graph:

{% highlight zsh %}
    +----------------+
    |    Students    | -----------+
    +----------------+ 1          |
            |1                    |
            |                     |
            |*                    |*
    +----------------+    +----------------+
    |  Enrollments  |    | GroupsStudents |
    +----------------+    +----------------+
    |  student_id    |    | student_id     |
    |  subject_id    |    | group_id       |
    +----------------+    +----------------+
            |*                    |*
            |                     |
            |1                    |1
    +----------------+    +----------------+
    |   Subjects     |    |    Groups      |
    +----------------+    +----------------+
            |1                    |1
            +-----------+---------+
                        |*
                +----------------+
                |    Lessons     |
                +----------------+
                | id             |
                | name           |
                | start_at       |
                | end_at         |
                | lessonable     |
                | #students      |
                +----------------+
                        |1
            +-----------+---------±
            |1                    |1
    +----------------+    +----------------+
    |  Lectures      |    |Directed Studies|
    +----------------+    +----------------+
    | #students      |    | #students      |
    +----------------+    +----------------+
{% endhighlight %}

Here's the updated code:

{% highlight ruby %}
  class Student < ApplicationRecord
    has_many :enrollments
    has_many :subjects, through: :enrollments

    has_many :groups_students
    has_many :groups, through: :groups_students
  end

  class Subject < ApplicationRecord
    has_many :enrollments
    has_many :students, through: :enrollments

    has_many :lessons, -> { lectures }
  end

  class Group < ApplicationRecord
    has_many :groups_students
    has_many :groups, through: :groups_students

    has_many :lessons, -> { directed_studies }
  end

  class Lesson < ApplicationRecord
    belongs_to :subject
    belongs_to :group

    delegated_type :lessonable, types: ["Lecture", "DirectedStudy"]

    delegate :students, to: :lessonable
  end

  class Lecture < ApplicationRecord
    has_one :lesson
    has_many :students, through: :subject
  end

  class DirectedStudy < ApplicationRecord
    has_one :lesson
    has_many :students, through: :group
  end
{% endhighlight %}

Now, `Subject` and `Group` are associated with `Lesson`, and fetch the _ad hoc_ type through [Active Record scoped associations]({{site.baseurl}}/scoped-active-record-associations/). If you're wondering where these scopes - `lectures` and `directed_studies` - are defined: they're predicate methods built by Rails on the fly. It's part of the delegated types feature.

The main takeaways are:
- The containing class (`Lesson`) should be the only interface.
- The containing class stores common attributes and behaviors.
- The containing class delegates the ad hoc methods to their delegated types.
- Delegated types (`Lecture` and `DirectedStudy`) only handle specific data and custom implementation for methods.
- Delegated types are not designed to be used in isolation.

## Some open questions

As of now, I still have a lot of questions about delegated types.

Students can access their lectures through one path, and their directed studies through another path. This setup stems from a domain constraint: groups of students are not scoped to a subject.

{% highlight zsh %}
  Student.first.subjects.first.lessons # => Returns lessons of type :lecture
  Student.first.groups.first.lessons # => Return lessons of type :directed_study
{% endhighlight %}

While it's convenient to have built-in scopes for each type, merging or eager-loading them is a pain. I can't use the `or` query method because the underlying structure of the two scopes is not the same, and ActiveRecord throws an error.

Right now, I have a method that aggregates the two scopes, but it's impossible (to my current knowledge) to leverage `includes` for native eager loading evaluation.

{% highlight ruby %}
  class Student < ApplicationRecord
    has_many :enrollments
    has_many :subjects, through: :enrollments

    has_many :groups_students
    has_many :groups, through: :groups_students

    has_many :lectures, through: :subjects, source: :lessons
    has_many :directed_studies, through: :groups, source: :lessons

    def lessons
      Lesson.includes(:lessonable).where(id: lectures.select(:id) + directed_studies.select(:id))
    end
  end
{% endhighlight %}

A couple of things stand out:
- As I move across the associations, I need to do gymnastics for the association's name.
- The `lessons` method is a workaround and can't really leverage eager loading.

To be honest, I don't know if it's a case not covered by the delegated types as a feature or if my implementation lacks an intermediate abstraction.

It also feels like the naming of the pattern is off. "Delegated types" represent both the architecture and the "subclasses". But what should we call the wrapping class?
- "Parent class" sounds too much like STI.
- I've come to use "containing class", but it does not represent the whole behavior.
- [Kasper](https://ruby.social/@kaspth){:target="\_blank"} suggested "wrapping meta-type" of which I like the idea of wrapping.

Anyway, that's a lot of questions. And I feel a lot of developers are scratching their heads in front of delegated types for the same reasons. If you have any ideas, share them with us!

A big thank you to [Ronan](https://ruby.social/@r3trofitted){:target="\_blank"}, [Jeremy](https://ruby.social/@notgrm){:target="\_blank"} and [Kasper](https://ruby.social/@kaspth){:target="\_blank"} for reading an early draft of this post and for their suggestions!

Cheers,

Rémi - [@remi@ruby.social](https://ruby.social/@remi)

[^1]: You can find the original PR [here](https://github.com/rails/rails/pull/39341){:target="\_blank"}.
