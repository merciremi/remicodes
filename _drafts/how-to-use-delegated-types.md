---
layout: post
title: how to use delegated types
excerpt: 
date: 20/02/2024
permalink: 
category: 
cover_image: 
---

There are a bunch of posts about Ruby on Rails delegated types, out there. But a lot of these focus on theorical comparison between delegated types and STI or polymorphism. Also, the examples always revolve around the basic usecase explain in the initial pull request. And I did not find those examples very handy.

Today, I want to share a real-world use case. I’ll give you the context and my needs, what was considered before picking up delegated types as a technical solution, the first tries and the impasses, then, the final implementation and my learnings.

It won’t be a typical how-to, but hopefully, it’ll help you wrap your head around the pros and cons of delegated types.

## The context

Students sign-up for subjects. Each subject is taught through lessons. Lessons come inntwonflavours: lectures and directed studies.

Lectures are open to every student enrolled in a subject. Directed studies are reserved to subsets of the students.

Lectures and directed studies are very similar in their representation. Both are a modality of any given subject. Both have a name, a start time and end time.

However, when checking for enrollments, each has its own version. Lectures access their students through the subject. Directed studies access their students through a concept of group, a subset of students.

## Why use delegated types?

Given our business need, my teamates and I decided to use the little known delegated types, introduced in Rails a few years ago.

Why use delegated types?

A few pointes stood up for us:

- Store common info in one table
- Store specific attributes in separate tables
- Allow for deeper customisation, most notably on method name.
- Allow for aggregated list of all lessons.

## Initial wanderings and common pitfalls

---

- parent class is only interface
- Subclasses only there to handle specifix data
- Subclasses only there to handle custom interpretation of methods
- Parent class stores common attributes
- Parent class stores common behavior
- Parent class delagates methods that need interpretation on child class
- Not necessarily have same api accroS child classes (how do you handle qtuff then?)
- Child classes are not there to be instantiated in isolation

Maybe plan for post:

- The initial requieement
- The first plan and pitfalls
- Final implementation and learnings

