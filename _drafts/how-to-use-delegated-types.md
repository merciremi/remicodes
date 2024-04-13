---
layout: post
title: how to use delegated types
excerpt: 
date: 20/02/2024
permalink: 
category: 
cover_image: 
---

Delegated types are a modelization pattern introduced in Rails in 2020. While reseaching delegated types for a feature, I found a handful of posts about them. However, most articles focus on the theoretical comparison between delegated types, STI, and polymorphism. Examples used in these posts are often unrepresentative of the complexity of real-life applications.

Today, I want to share a real-world use case. I'll walk you through my initial requirements, my first implementation and its hiccups, then how I eventually used delegated types with my main learning points.

This post won’t be your typical tutorial, but hopefully, it’ll help you better understand how delegated types can fit into your codebase.

## The initial problem

First, let me explain the core domain and its logic.

I currently work on an application where `Students` can sign-up for `subjects`.

Each subject is taught through `lessons`. Lessons come in two flavors: `lectures` and `directed studies`.

Lectures are `open` to every student enrolled in a subject. Directed studies are `reserved` to subsets of the students.

Lectures and directed studies are very similar in their representation. Both are a __modality__ of any given subject. Both have a name, a start time and an end time.

However, each type of lessons __has its own way of getting its list of students__:
- Lectures access their students through the subject, then through the `enrollements`.
- Directed studies access their students through groups, which are subsets of students.

Here is the graph I initially drew (the arrows representing the chain of the method `#students`):

{% highlight txt %}

    +----------------+
    |    Students    | <----------+
    +----------------+            |
            ^                     |
            |                     |
    +----------------+    +----------------+
    |  Enrollements  |    | GroupsStudents |
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

In this graph, `enrollements` and `groups students` are join tables, which allow us to have many-to-many relationships. They might get some logic of their own later down the road.

I've not represented `lessons` as a proper class yet. You probably already know `lessons`, `lectures` and `directed studies` will end up as delegated types, but when I initially drew that graph, I didn't.

## Why should I use delegated types?

Before jumping to technical solutions, I like to start from the API I'd like to expose. For this feature, I wanted to be able to write code like:

```
  subject.lessons # => returns a collection of lessons
  subject.lessons.lectures # => returns a collection of lessions while filtering out those of type "directed studies"
  subject.lessons.map(&:students) # => returns a collection of students regardless of the type of lessons
```

Right off the bat, we can see that I both need some kind of aggregative logic (I want a collection of `lessons`), but also an exclusive logic (I want a collection of only one type of `lessons`).

I also need a common API between `lectures` and `directed studies`. There is a lot of common logic - a `name`, a `start time` and a `stop time` -, but also some distinctive logic (the way each type of `lessons` fetch its students).

To resume: a bit of Single Table Inheritance for the aggregation, a bit of polymorphism for the common API, but also some flexibility in terms of persisting the information.

After pondering these various requirements, I decided to go with delegated types.

Delegated types allow me to:
- Store common information in a single table.
- Store specific information in specific tables.
- Query each type of `lessons` through a unified API: `Lesson`.
- Have custom method implementation for each type.
- Index all `lessons` regardless of their type.

## Initial implementation and pitfalls

My first idea was to treat `directed_studies` in isolation. In my mind, `lectures` where the "golden path" (read: the easiest) so I was happy following he Rails convention of interacting with `lectures` through `lessons`.

But fetching `students` for `directed studies` was slightly harder, so I plan on bypassing `lessons` and create a direct relationships between `directed studies` and `groups`.

<!-- I have to check my initial plan for this, I'm not 100% sure about the way I had planned  -->

{% highlight txt %}

    +----------------+
    |    Students    | -----------+
    +----------------+ 1          |
            |1                    |
            |                     |
            |*                    |*
    +----------------+    +----------------+
    |  Enrollements  |    | GroupsStudents |
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

You can already tell, even if you're not knee deep into the feature, that things will turn ugly in about a minute.

By bypassing the parent class `lessons`, `groups` can create `directed studies` directly.

```
  Group.first.directed_studies.create! # => returns an instance of DirectedStudy
```

But doing so means I lose the attributes and common logic defined in `lessons`.

```
Group.first.directed_studies.first.name # => NoMethodError
```

Oupsy!

This is my main take away: delegated types are not designed to work in isolation. The main interface for using delegated types should always be the parent class.

As often, Rails provides you with sharp knives. Sure, you can stick them in your foot if you want, but that doesn't mean you should.

## Final implementation and main takeaways

{% highlight txt %}

    +----------------+
    |    Students    | -----------+
    +----------------+ 1          |
            |1                    |
            |                     |
            |*                    |*
    +----------------+    +----------------+
    |  Enrollements  |    | GroupsStudents |
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

- parent class is only interface
- Subclasses only there to handle specifix data
- Subclasses only there to handle custom interpretation of methods
- Parent class stores common attributes
- Parent class stores common behavior
- Parent class delagates methods that need interpretation on child class
- Not necessarily have same api accroS child classes (how do you handle qtuff then?)
- Child classes are not there to be instantiated in isolation


