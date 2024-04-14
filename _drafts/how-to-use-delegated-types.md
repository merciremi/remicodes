---
layout: post
title: How to use delegated types in Rails
excerpt: 
date: 20/02/2024
permalink: 
category: 
cover_image: 
---

Delegated types are a modelization pattern introduced in Rails in 2020. While reseaching this pattern for a feature, I found that most existing articles focus on the theoretical comparison between delegated types, STI, and polymorphism. Examples used in these posts are often unrepresentative of the complexity of real-life applications.

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

```

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

```

In this graph, `enrollements` and `groups students` are join tables, which allow us to have many-to-many relationships. They might get some logic of their own later down the road.

I've not represented `lessons` as a proper class yet. You probably already know `lessons`, `lectures` and `directed studies` will end up as delegated types, but when I initially drew that graph, I didn't.

## Why should I use delegated types?

Before jumping to technical solutions, I like to start from the API I'd like to expose. For this feature, I wanted to be able to write code like:

```ruby
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

My first idea was to treat `directed_studies` in isolation.

In my application, `lectures` were the "golden path" (read: the easiest path). So, I was happy following he Rails convention of interacting with `lectures` through `lessons`.

But fetching `students` for `directed studies` was slightly harder, so instead of following Rails' convention, I planed on bypassing `lessons` and create a direct relationship between `directed studies` and `groups`.

This association was also a way to assert the fact that `groups` would exlusively work with `directed studies`.

Here's an updated version of my graph:

```

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
```

You can already tell from this graph that things will turn ugly in about a minute.

Bypassing the parent class `lessons` for `groups` results in several pitfalls:

- `subjects` and `groups` do not interact with `lessons` in the same manner.
- `groups` can create a specific type of `lessons`, but lose the common information in the process.

```
  directed_study = Group.first.directed_studies.create! # => returns an instance of DirectedStudy
  directed_study.name # => NoMethodError
  directed_study.lesson # => nil
```

Whoopsy!

If I had one main take-away, it'll be this:

<p class='callout'>
  Delegated types are not designed to work in isolation. And the main interface for using delegated types should always be the parent class.
</p>

As per its manifesto, Rails provides you with sharp knives. Sure, you can stick them in your foot if you want, but that doesn't mean you should.

## Final implementation and main takeaways

After pulling my hair for a while, I updated my architecture to the following:

```

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
```

The main take-aways are:
- The parent class (`lessons`) should be the only interface.
- The parent class stores common attributes and behaviors.
- The parent class delegates the ad hoc methods to their delegated types.
- Delegated types (`lectures` and `directed studies`) are only there to handle specific data and custom implementation for methods.
- Delegated types are not designed to be used in isolation.

### Some points that are still unclear to me:

Right now, students can access their `lectures` through one path, and their `directed studies` through another path. This setup stems from the fact that `groups` are not scoped to a subject in our domain.

```ruby
  Student.first.subjects.first.lessons # => only lectures
  Student.first.groups.first.lessons # => only directed studies
```

These can be two scopes on `Student` but it's a pain to merge these two scopes, because the underlying stucture is not the same (meaning, you can't use `or`). So it's back to manually merging the two scopes, which makes it's nearly impossible to leverage `includes`.



