---
layout: post
title: Asynchronous HTTP requests in Rails
date: 2020-05-05
excerpt: "Let's look at how we can update parts of our app's pages with asynchronous HTTP requests. This is a step-by-step how-to with some good ol' Javascript fetch() method, and Rails native server-side partial rendering."
permalink: /asynchronous-requests/
category: 'rails'
cover_image: /media/2020/05/async-requests-in-rails-remi-mercier.png
---

Today is a special day. It's the day I'll (mostly) talk about Javascript!

I've been struggling with AJAX requests in [Rails apps]({{site.baseurl}}/series/rails) for a while. But I've started using them a lot recently, and pieces of the puzzle kinda fell together. Asynchronous requests can be handy when you need to update some parts of your application's page without reloading the whole thing. I'll show you how to do this with plain ol' vanilla Javascript (and its [fetch() method](https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API/Using_Fetch){:target="\_blank"}), and Rails 6 native server-side partial rendering.

[2020-05-10 Update: If you're more confortable following along a video, I've recorded a screencast]({{site.baseurl}}/asynchronous-requests/#async-request-screencast).]

## Some context

Alright. Let's say you have a list of essays from your app's blog. They're sorted from newest to oldest. But you'd like your readers to have the ability to filter them by topic.

You'd start by adding some buttons at the top of your feed. Now, when readers click the button `Ruby`, you'd like your feed to only display essays with the category `Ruby`. All of this, without reloading the whole page.

Something like this 👇

<img src="{{ site.baseurl }}/media/2020/05/asynchronous-requests-in-rails.gif" alt="a gif showing someone clicking on three topic buttons and filtering post on the fly">

This sounds like a job for some asynchronous HTTP requests.

## The Rails bit

Let's dive right in and add a new route:

{% highlight ruby %}
  # Expose an endpoint for our request
  resources :posts, only: :index, controller: 'blog/posts'
{% endhighlight %}

This will be the endpoint our requests ping. Now, here's a basic controller:

{% highlight ruby %}
  # Located at: app/controllers/blog/posts_controller.rb

  class Blog::PostsController < ApplicationController
    def index
      @posts = Post.all
    end
  end
{% endhighlight %}

And the corresponding view:

{% highlight erb %}
  <!-- Located at: app/views/blog/posts/index.html.erb -->

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
  - Each filter has an ID.
  - The DOM element embedding the list of posts has an ID.
  - The list of posts is in a partial: this will make server-side rendering much easier.

Speaking of partial, here's `posts_list.html.erb`:

{% highlight erb %}
  <!-- Located at: app/views/blog/posts/\_posts_list.html.erb -->

  <% posts.each do \|post\| %>
    <%= link_to blog_post_path(post.url) %>
      <h2><%= post.title %></h2>
    <% end %>
    <%= post.excerpt %>
  <% end %>
{% endhighlight %}

We're looping over a collection of posts. For each post, we generate a clickable title and an excerpt.

And now, ladies, gentlemen, and variations thereupon [^1], let's make some Javascript!

## Building asynchronous requests in Rails with `fetch()`, step-by-step

Before we begin, you can either write your Javascript in your `app/assets/javascripts` directory or in your `app/javascript/packs` directory based on your Rails configuration (i.e. Do you have webpacker installed or not?). Both will work just fine!

### The basic syntax for `fetch()`

Here are the outlines of our Javascript file:

{% highlight js %}
  // Located at app/javascript/packs/blog_filters.js

  // Store the DOM element embedding the list
  const postsList = document.getElementById('posts-list');

  // Wrap our fetch() method in a function we can call whenever we want
  const filterPosts = () => {
    // Store our controller enpoint for clarity
    let actionUrl = 'posts';

    fetch(actionUrl, {
      // We'll add some configuration here.
    }).then((response) => {
      // And we'll do some fancy stuff there.
    });
  }

  // Store all filter-type elements
  const rubyFilter = document.getElementById('ruby-filter');
  const javascriptFilter = document.getElementById('javascript-filter');
  const remoteFilter = document.getElementById('remote-filter');

  // Trigger filterPosts when users click on a filter button
  rubyFilter.onclick = () => { filterPosts('ruby'); }
  javascriptFilter.onclick = () => { filterPosts('javascript'); }
  remoteFilter.onclick = () => { filterPosts('remote'); }
{% endhighlight %}

Here's what `blog_filters.js` does:
  - Find and store the DOM element embedding my list of posts.
  - Find and store every filter-type button on our page.
  - Add an event listener on each button that'll trigger our asynchronous request.
  - Store the URL where I'll send my asynchronous request (i.e `Blog::PostsController#index`).
  - Fetch then handle the response from my controller.

Now, let's work some magic between our Javascript file and our controller.

### Fleshing out `fetch()`

`fetch()` takes an URL as the first parameter. We've already done that. Now, we'll add details to the second parameter (it's called the `init` object).

{% highlight js %}
  // Located at app/javascript/packs/blog_filters.js

  const postsList = document.getElementById('posts-list');

  const filterPosts = () => {
    let actionUrl = 'posts';

    fetch(actionUrl, {
      method: 'GET',
      headers: {
        'X-CSRF-Token':     document.getElementsByName('csrf-token')[0].getAttribute('content'),
        'X-Requested-With': 'XMLHttpRequest',
        'Content-Type':     'application/html',
        'Accept':           'application/html'
      },
      credentials: 'same-origin'
    }).then((response) => {
      // And do stuff there.
    });
  }

  const rubyFilter = document.getElementById('ruby-filter');
  const javascriptFilter = document.getElementById('javascript-filter');
  const remoteFilter = document.getElementById('remote-filter');

  rubyFilter.onclick = () => { filterPosts('ruby'); }
  javascriptFilter.onclick = () => { filterPosts('javascript'); }
  remoteFilter.onclick = () => { filterPosts('remote'); }
{% endhighlight %}

What's happening here?
  - I specify the HTTP request I want to do.
  - I fill in the request's headers with:
    - my CRSF token (so Rails doesn't think your request is illegitimate)
    - the type of content I expect to receive (in our case, HTML)
  - I specify that the request comes from our app.

This bit will ping our `Blog::PostsController#index` (through the route stored in `actionUrl`). Remember, we want our controller to filter our essays based on the category sent through our `fetch()` method. So we need to add that category to our request:

{% highlight js %}
  // Located at app/javascript/packs/blog_filters.js

  const postsList = document.getElementById('posts-list');

  const filterPosts = (category) => {
    let categoryParams = `?category=${category}`;
    let actionUrl = 'posts' + categoryParams;

    fetch(actionUrl, {
      method: 'GET',
      headers: {
        'X-CSRF-Token':     document.getElementsByName('csrf-token')[0].getAttribute('content'),
        'X-Requested-With': 'XMLHttpRequest',
        'Content-Type':     'application/html',
        'Accept':           'application/html'
      },
      credentials: 'same-origin'
    }).then((response) => {
      // And do stuff there.
    });
  }

  const rubyFilter = document.getElementById('ruby-filter');
  const javascriptFilter = document.getElementById('javascript-filter');
  const remoteFilter = document.getElementById('remote-filter');

  rubyFilter.onclick = () => { filterPosts('ruby'); }
  javascriptFilter.onclick = () => { filterPosts('javascript'); }
  remoteFilter.onclick = () => { filterPosts('remote'); }
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
  - If `params['category']` is present, my controller directly returns the partial `posts_list.html.erb` with the filtered list of `@posts` to **my Javascript method**, not to the view.

If your partial is somewhere else (like in your `shared` directory, just give your controller the relative path - i.e. `../../shared/posts_list`).
Javascript kinda places itself in between my controller and my view. Why? Because we'll only update one bit of the page by manipulating the DOM.

`layout: false` tells Rails not to look for a template (since I'm feeding my Javascript method with a partial).

### Handling the response from our controller

The first thing I like to do, is to check the HTTP status sent from my controller. If it's a `200`, I'll use the response to replace the posts list in my view.

{% highlight js %}
  // Located at app/javascript/packs/blog_filters.js

  const postsList = document.getElementById('posts-list');

  const filterPosts = (category) => {
    let categoryParams = `?category=${category}`;
    let actionUrl = 'posts' + categoryParams;

    fetch(actionUrl, {
      method: 'GET',
      headers: {
        'X-CSRF-Token':     document.getElementsByName('csrf-token')[0].getAttribute('content'),
        'X-Requested-With': 'XMLHttpRequest',
        'Content-Type':     'application/html',
        'Accept':           'application/html'
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

  const rubyFilter = document.getElementById('ruby-filter');
  const javascriptFilter = document.getElementById('javascript-filter');
  const remoteFilter = document.getElementById('remote-filter');

  rubyFilter.onclick = () => { filterPosts('ruby'); }
  javascriptFilter.onclick = () => { filterPosts('javascript'); }
  remoteFilter.onclick = () => { filterPosts('remote'); }
{% endhighlight %}

What did I do? I applied the `text()` method to my controller `response`. `response` is - and I quote the Mozilla documentation - a readable stream of byte data (you gotta love Javascript 🙃). `text()` takes this stream and turns it into a UTF-8-encoded string.

In our case, here's what happens:
  - Our controller returns a partial with a loop in it.
  - Our ERB file is interpreted, and Javascript accesses the HTML as a readable stream.
  - `text()` kicks in and turns the stream into a string (which is a stringified version of our HTML).
  - I assign `response.text()` to `content`, and I replace the `postsList` section of my DOM with the stringify partial.

If the `response` status is an error (like a `500`), I can show the user an error. Whatever's tickling your fancy.

Phew! We just changed the posts section of my page without reloading the page. No fancy framework. No HTML written inside the Javascript code. Just some well-integrated server-side rendering and vanilla Javascript. 👌

<h2 id="async-request-screencast">Screencast</h2>

<iframe width="900" height="500" src="https://www.youtube-nocookie.com/embed/Gm7GdXx44mk" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

That's is for today folks! I hope you enjoyed it as much as I did.

If anything seems odd, [ping me on Twitter](https://twitter.com/mercier_remi){:target="\_blank"} or [create an issue on GitHub](https://github.com/merciremi/remicodes/issues/new){:target="\_blank"}.

Cheers,

Rémi - [@mercier_remi](https://twitter.com/mercier_remi){:target="\_blank"}

[^1]: 👋 Doctor Who fans.
