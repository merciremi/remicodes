---
layout: post
title: asynchronous HTTP requests in rails with vanilla javascript
---

Today is a very special day. The main part of this post won't be only about Rails or Ruby, but about Javascript too!

I've been using AJAX requests in Rails apps for a while now, but only a few weeks ago did it started to make real sense. When I started using them a lot. They can be very handly when you need to refresh a section of your page without reloading the whole thing.

## Some context

Let's say you have a list of essays from your app's blog, sorted from newest to oldest. Now, you'd like your readers to have the ability to filter your essays by topic.

You might display some filters on the very top of your feed page. So, when a reader clicks the filter `Ruby`, the feed should refresh and only display the essays with the category `Ruby`. All this without reloading the whole page.

Sounds good? Let's go!

## How-to

We'll use some plain 'ol vanilla Javascript, Rails' partials, and some swag.

Start with our routes:

{% highlight ruby %}
  # expose an endpoint for our request
  resources :posts, only: :index, controller: 'blog/posts'
{% endhighlight %}

Our basic controller:

{% highlight ruby %}
  # Located at: app/controllers/blog/posts_controller.rb

  class Blog::PostsController < ApplicationController
    def index
      @posts = Post.all
    end
  end
{% endhighlight %}

Our view:
{% highlight erb %}
  # Located at: app/views/blog/posts/index.html.erb

  <h1>My app's blog</h1>

  <!-- Filters -->
  <section>
    <p>Check posts by topic: </p>
    <button id="ruby-filter">Ruby</button>
    <button id="javascript-filter">Javascript</button>
    <button id="remote-filter">Remote working</button>
  </section>

  <!-- Posts' index -->
  <section id="posts-list">
    <%= render 'posts_list', posts: @posts %>
  </section>
{% endhighlight %}

See what I'm doing here?
- Each filter has an ID.
- The actual index of posts is a partial. Why? 'Cause it'll be easier to render the whole thing with Javascript.

Speaking of partial, here is our `posts_list.html.erb`.

{% highlight erb %}
  # Located at: app/views/blog/posts/\_posts_list.html.erb

  <% posts.each do \|post\| %>
    <%= link_to blog_post_path(post.url) %>
      <h2><%= post.title %></h2>
    <% end %>
    <%= post.excerpt %>
  <% end %>
{% endhighlight %}

Pretty straightforward. It's just a loop on a collection of posts.

Now, let's dive into javascript. \0/

## Building an asynchronous request with `fetch()`: step-by-step

Here are the rough bones for it:

{% highlight js %}
  // Let's get our filters
  const rubyFilter = document.getElementById('ruby-filter');
  const javascriptFilter = document.getElementById('javascript-filter');
  const remoteFilter = document.getElementById('remote-filter');

  // Let's get the parent element of our list of posts
  const postsList = document.getElementById('posts-list');

  // Let's embed our fetch in a function
  const filterPosts = () => {
    // Let's attribute our route to actionUrl for clarity's sake
    let actionUrl = 'blog_posts_url';

    fetch(actionUrl, {
      // Put some stuff here.
    }).then((response) => {
      // And do stuff there.
    });
  }
{% endhighlight %}

- context
- what we'll use: rails, ES6 vanilla js, fetch, partials
- code :
  - routes
  - controller : list of posts with timeframe
  - views + partial
  - js code
