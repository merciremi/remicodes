---
layout: post
title: 'how to test your Rails controllers with RSpec'
excerpt: 
date: 20/02/2024
permalink: 
category: 
cover_image: 
---

A year ago, I wrote about [testing your Rails models with RSpec]({{site.baseurl}}/how-to-test-rails-models-with-rspec/). I guess it's time we start testing our controllers, right? Let's dive in.

## A Rails controllers that needs some tests

{% highlight ruby %}
class BooksController < BaseController
  # GET /books
  def index
    render json: paginate(books)
  end

  # GET /books/:id
  def show
    authorize book

    render json: book
  end

  private

  def books
    policy_scope(Book.all)
  end

  def book
    @book ||= Book.find(params[:id])
  end
{% endhighlight %}

## What I always test

- will test the validity of my input, my output (response, serialization formatting (several schools there, might prefer test serializer in isolation))
- test respnses diff if need for auth or not, policies

## What I test on a case-to-case basis
- sometimes, if my controller did what it's supposed to do : create objects, call objects...

## My convention for controllers' tests
Here's my fav template:
- subject(:action)
- action in before do if possible
- describe REST actions in order, with path as comment
- check for respnse status, then respnse details



- in spec/requests : recommanded practice

But I usually stay as clear as possible of implementation details.


Done! You've cover most of your basis.
