---
layout: post
title: asynchronous HTTP requests in rails with vanilla javascript
---

Today is a very special day. This is the day I'll (mostly) talk about Javascript!

I've been struggling with AJAX requests in Rails apps for a while. But I've started using them a lot recently and the pieces kinda fell together. Those can be handly when you need to update some part of your application's page without reloading the whole thing [^1].

## Some context

Alright, let's say you have a list of essays from your app's blog. They are sorted from newest to oldest. But you'd like your readers to have the ability to filter your essays by topic.

You'd start by adding some buttons at the top of your feed. Now, when readers click the button `Ruby`, you'd like your feed to only display essays with the category `Ruby`. All of this, without reloading the whole page.

This sounds like a job for some asynchronous HTTP requests. To do this, we'll use plain 'ol vanilla Javascript (and its [fetch() method](https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API/Using_Fetch){:target="\_blank"}) and Rails native server-side partial rendering.

## The Rails bit

Let's add a new route:

{% highlight ruby %}
  # Expose an endpoint for our request
  resources :posts, only: :index, controller: 'blog/posts'
{% endhighlight %}

This will be the endpoint our Javascript pings. Now, here's a basic controller:

{% highlight ruby %}
  # Located at: app/controllers/blog/posts_controller.rb

  class Blog::PostsController < ApplicationController
    def index
      @posts = Post.all
    end
  end
{% endhighlight %}

The corresponding view:

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

Note that:
  - each filter has its own ID.
  - the DOM element embedding the list of posts has an ID
  - the list of posts is in a partial: this will make server-side rendering much easier

Speaking of partial, here's our `posts_list.html.erb`:

{% highlight erb %}
  # Located at: app/views/blog/posts/\_posts_list.html.erb

  <% posts.each do \|post\| %>
    <%= link_to blog_post_path(post.url) %>
      <h2><%= post.title %></h2>
    <% end %>
    <%= post.excerpt %>
  <% end %>
{% endhighlight %}

Just a loop building a collection of posts with a clickable title and an excerpt.

And now, ladies, gentlemen, and variations thereupon [^1], let's dive into Javascript!

## Building asynchronous requests in Rails with `fetch()`, step-by-step

Before we begin, you can either write your Javascript in your `app/assets/javascripts` directory or in `app/javascript/packs` based on your Rails configuration (i.e. Do you have webpacker installed or not?).

### The basic syntax for `fetch()`

Here are the outlines:

{% highlight js %}
  // Located at app/javascript/packs/blog_filters.js

  // Store all filter-type elements
  const rubyFilter = document.getElementById('ruby-filter');
  const javascriptFilter = document.getElementById('javascript-filter');
  const remoteFilter = document.getElementById('remote-filter');

  // Store the DOM element embedding the list
  const postsList = document.getElementById('posts-list');

  // Wrap our fetch() method in a function we can call whenever we want
  const filterPosts = () => {
    // Store our controller enpoint for clarity
    let actionUrl = 'posts_url';

    fetch(actionUrl, {
      // We'll add some configuration here.
    }).then((response) => {
      // And we'll do some fancy stuff there.
    });
  }
{% endhighlight %}

Here's what `blog_filters.js` does:
  - Find and store the DOM element embedding my list of posts.
  - Find and store every filter-type button.
  - Identify the URL where I will send my asynchronous request (i.e `Blog::PostsController#index`).
  - Fetch then handle the response from my controller.

A word about the `actionUrl`: this is the Rails path you'll get from your Rails routes. Only, you need to replace the `_path` bit by `_url`. Why? I do not know friend! [^2]

Let's work some magic between our Javascript file and our controller.

### Flesh out `fetch()`

`fetch()` takes an URL as first parameter. We've already done that. Now, we'll add details to the second parameter (it's called an `init` object).

{% highlight js %}
  const rubyFilter = document.getElementById('ruby-filter');
  const javascriptFilter = document.getElementById('javascript-filter');
  const remoteFilter = document.getElementById('remote-filter');

  const postsList = document.getElementById('posts-list');

  const filterPosts = () => {
    let actionUrl = 'blog_posts_url';

    fetch(actionUrl, {
      method: 'GET',
      headers: {
        'X-CSRF-Token':     document.getElementsByName('csrf-token')[0].getAttribute('content'),
        'X-Requested-With': 'XMLHttpRequest',
        'Content-Type':     'html',
        'Accept':           'html'
      },
      credentials: 'same-origin'
    }).then((response) => {
      // And do stuff there.
    });
  }
{% endhighlight %}

What's happening here?
  - I specify the HTTP request I want to do.
  - I fill in the request's headers with:
    - my CRSF token (so Rails doesn't think your request is illegitimate)
    - the type of content I expect to receive (in our case, HTML)
  - I specify that the request comes from our own app.

This bit will ping our `Blog::PostsController` (through the route stored in `actionUrl`). Remember, we want our controller to filter our essays based on a category sent through our Javascript request. So we need to add that category to our request:

{% highlight js %}
  const rubyFilter = document.getElementById('ruby-filter');
  const javascriptFilter = document.getElementById('javascript-filter');
  const remoteFilter = document.getElementById('remote-filter');

  const postsList = document.getElementById('posts-list');

  const filterPosts = (category) => {
    let categoryParams = `?category=${category}`;
    let actionUrl = 'blog_posts_url' + 'categoryParams';

    fetch(actionUrl, {
      method: 'GET',
      headers: {
        'X-CSRF-Token':     document.getElementsByName('csrf-token')[0].getAttribute('content'),
        'X-Requested-With': 'XMLHttpRequest',
        'Content-Type':     'html',
        'Accept':           'html'
      },
      credentials: 'same-origin'
    }).then((response) => {
      // And do stuff there.
    });
  }
{% endhighlight %}

I've added a parameter `category` to my `filterPosts` function. Then, I'm building my some Rails `params` with `category` and, I'm adding them to my `actionUrl`. Now, I can access my `category` in my `Blog::PostsController` through my `ActionController::Parameters`. 👌

### Filtering data in our controller

I can update our controller based on the presence of the `category` key in my `params`:

{% highlight ruby %}
  # Located at: app/controllers/blog/posts_controller.rb

  class Blog::PostsController < ApplicationController
    def index
      if params['category'].present?
        @posts = Post.where(category: params['category'])
        render partial: 'posts_list', locals: { posts: @posts}, layout: false
      else
        @posts = Post.all
      end
    end
  end
{% endhighlight %}

Let's break it down:
  - If `params['category']` is absent, my controller returns a list of posts (`@posts`) to `index.html.erb`which renders the partial `posts_list.html.erb`.
  - If `params['category']` is present, my controller directly returns the partial `posts_list.html.erb` with the filtered list of posts to **my Javascript method!** Not to the view, to the Javascript `filterPosts()` function.

Javascript kinda places itself inbetween my controller and my view. Why? Because we'll only update one bit of the page by manipulating the DOM.

### Handling the response from our controller


⚠️ what is layout false?


First, I'll check if my controller sent a `200` status.

{% highlight js %}
  // Let's get our filters
  const rubyFilter = document.getElementById('ruby-filter');
  const javascriptFilter = document.getElementById('javascript-filter');
  const remoteFilter = document.getElementById('remote-filter');

  // Let's get the parent element of our list of posts
  const postsList = document.getElementById('posts-list');

  // Let's embed our fetch in a function
  const filterPosts = (category) => {
    // Let's attribute our route to actionUrl for clarity's sake
    let categoryParams = `?category=${category}`;
    let actionUrl = 'blog_posts_url' + 'categoryParams';

    fetch(actionUrl, {
      method: 'GET',
      headers: {
        'X-CSRF-Token':     document.getElementsByName('csrf-token')[0].getAttribute('content'),
        'X-Requested-With': 'XMLHttpRequest',
        'Content-Type':     'html',
        'Accept':           'html'
      },
      credentials: 'same-origin'
    }).then((response) => {
      if (response.status == 200) {
        response.text().then((content) => {
          postsList.innerHTML = content;
        })
      }
    });
  }
{% endhighlight %}

What did I do? I applied the `text()` method to my response. `response` is - and I quote - a readable stream of byte data (you gotta love Javascript 🙃). `text()` take the stream and turns it into a UTF-8-encoded string.

In our case, here's what'll happen:
- our controller returns a partial with a loop in it
- erb file is interpreted and rendered as html
- then `text()` quicks in and turn the whole html into a string

I then assign the `response.text()` to `content` and replace the `postsList` section of my html with this new string that's basically html (pretty sure this post won't make it in javascirpt or ruby weeekly).

And wham! The DOM section where the posts are indexed is changed without the page reloading. Fancy as fuck!

[^1]: 👋 Doctor Who fans.
[^2]: Lemme know on Twitter if you know the reason.
[^1]: And when you don't have six months to learn React.

⚠️ Ajouter des graphs de interactions, ce serait pas mal.
