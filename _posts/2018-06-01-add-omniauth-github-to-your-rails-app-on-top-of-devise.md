---
layout: post
title: 'Add Omniauth GitHub to Your Rails App on Top of Devise'
date: 2018-06-01 14:44 +0100
excerpt: "As I’ve moved into the last three weeks of Le Wagon coding bootcamp, the need to authorize people to sign-up with GitHub quickly arise. Here's a step-by-step tutorial on how to do it when you already use Devise to handle authentification."
category: 'rails'
permalink: /omniauth-github-rails-app-with-devise/
---

*Last update: 16 July 2018*

As I’ve moved into the last three weeks of [@lewagon](http://lewagon.com/), my teammates and I have been working on marketplace apps before getting to our final projects.

The need to authorize people to sign-up with GitHub quickly arise. Here's a step-by-step tutorial on how to do it when you already use Devise to handle authentification.

## Basic set up
Before working on your app, you need to set some things up.

### Create a application on Git Hub
First, we need to create a OAuth app on GitHub. Go to your profile, then `developper settings` and click `New OAuth App`.

Give your application a name, a URL and a callback URL. What if you want to work with localhost? Glad you asked.

For your homage URL: `http://http://localhost:your_port` will work perfectly

For the callback URL, you can’t use  `http://http://localhost:your_port` because GitHub needs you to specify an address that can be publicly access. So, what do we do?

### ngrok to the rescue
ngrok exposes your local web server through a public URL. So we need to install ngrok and have it listening to our local server. We’ll then be able to get a public URL and give it to GitHub.

First, run in your terminal:

{% highlight zsh %}
brew install ngrok
{% endhighlight %}

Then run:

{% highlight zsh %}
ngrok http your_port
{% endhighlight %}

You’ll get:

{% highlight zsh %}
ngrok by @inconshreveable                                       (Ctrl+C to quit)

Session Status                online
Session Expires               7 hours, 59 minutes
Version                       2.2.8
Region                        United States (us)
Web Interface                 http://127.0.0.1:4040
Forwarding                    http://3aa8f0f7.ngrok.io -> localhost:3000
Forwarding                    https://3aa8f0f7.ngrok.io -> localhost:3000

Connections                   ttl     opn     rt1     rt5     p50     p90
                 0       0       0.00    0.00    0.00    0.00
{% endhighlight %}

And there you have your callback URL: `http://3aa8f0f7.ngrok.io -> localhost:3000`.

Do not forget to append your callback URL with `/users/auth/github/callback`.

Your development callback URL should look like this:

`http://3aa8f0f7.ngrok.io/users/auth/github/callback`

We’ll need to change these two URLs once we move into production. ⚠️ Be careful to use the same protocol in your app URL and callback URL. Using `http` in one and `https` in another with result in a URL mismatch.

### Save your API keys in your Rails app
We don’t want our API keys being pushed to GitHub. So I’ll use the [figaro gem](https://github.com/laserlemon/figaro) to store these in a secure file.

{% highlight ruby %}
# Add figaro to your gem file@
gem 'figaro'
{% endhighlight %}

{% highlight zsh %}
# In your terminal
bundle install
{% endhighlight %}

Figaro creates a *config/application.yml* to put all your API keys and adds this file in .gitignore.

Copy/paste your secret keys in *config/application.yml*

{% highlight ruby %}
development:
  GITHUB_ID: 8***********************b
  GITHUB_SECRET: 4***********************************************3
{% endhighlight %}

Don’t forget to tell devise to use these keys in *config/initializers/devise.rb*.

{% highlight ruby %}
config.omniauth :github, ENV['GITHUB_ID'], ENV['GITHUB_SECRET'], scope: 'user,public_repo'
{% endhighlight %}

## Configure Omniauth GithHub with Devise

Since we use Devise to handle authentification, we don’t want to write config in *config/initializers/omniauth.rb*.

Let’s get down to it!

The first step is to had the Omniauth gem to your app. Go to your `Gemfile`:

{% highlight ruby %}
gem 'omniauth-github'
{% endhighlight %}

Then run:

{% highlight zsh %}
bundle install
{% endhighlight %}

Next step is to add the `provider` and `uid` columns to our User model. Remember we already declared the provider in our *config/initializers/devise.rb*.

{% highlight zsh %}
rails g migration AddOmniauthToUsers provider:string uid:string
rake db:migrate
{% endhighlight %}

We go to `user.rb` and make our user omniauthable.

{% highlight ruby %}
devise :omniauthable, omniauth_providers: %i[github]
{% endhighlight %}

With `devise_for :users` already in place, Devise will create two URL methods:
- `user_omniauth_authorize_path(provider)`
- `user_omniauth_callback_path(provider)`_

### Add it to your view

Paste the following code to get a simple link to test it out:
{% highlight ruby %}
<%= link_to "Sign up with GitHub", user_github_omniauth_authorize_path %>
{% endhighlight %}

⚠️ The symbol passed to the `user_omniauth_authorize_path` method should match the symbol of the provider passed to Devise's config block.

Now, when clicking on `Sign up with GitHub`, people will be redirected to GitHub to give their credentials. But as for now, nothing happens when GitHub sends back the user’s data.

### Add the callback to your app

Let’s go back to our `config/routes.rb` to tell Devise in which controller we’ll implement our callbacks:

{% highlight ruby %}
devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }
{% endhighlight %}

Now we just add the file `app/controllers/users/omniauth_callbacks_controller.rb`:

{% highlight ruby %}
class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
end
{% endhighlight %}
The callback should have the same name as the provider we passed in Devise’s config block.

{% highlight ruby %}
class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
   def github
       @user = User.from_omniauth(request.env["omniauth.auth"])
       if @user.persisted?
         sign_in_and_redirect @user, event: :authentication #this will throw if @user is not activated
         set_flash_message(:notice, :success, kind: "GitHub") if is_navigational_format?
       else
         session["devise.github_data"] = request.env["omniauth.auth"]
         redirect_to new_user_registration_url
       end
     end

     def failure
       redirect_to root_path
     end
 end
{% endhighlight %}

Then, from the controller, we move to our user model. Here is the code from Devise documentation:

{% highlight ruby %}
def self.from_omniauth(auth)
   where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
     user.email = auth.info.email
     user.password = Devise.friendly_token[0,20]
     user.name = auth.info.name   # assuming the user model has a name
     user.image = auth.info.image # assuming the user model has an image
     # If you are using confirmable and the provider(s) you use validate emails,
     # uncomment the line below to skip the confirmation emails.
     # user.skip_confirmation!
   end
 end
{% endhighlight %}

After changing the code above to suit my primary needs, I ran into several problems:
- I was using Carrierwave to upload picture on Cloudinary, so I needed to add the proper logic to the method.
- If a user was already persisted in my DB and was trying to sign-in with GitHub, he was redirect to sign-in without logging in.

So, here’s my own version of the Class method based on my schema and needs:

{% highlight ruby %}
def self.from_omniauth(auth)
     user = User.find_by(email: auth.info.email)
     if user
       user.provider = auth.provider
       user.uid = auth.uid
       user.save
     else
       user = User.where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
         user.email = auth.info.email
         user.password = Devise.friendly_token[0,20]
         user.first_name = auth.info.name.split(' ').first
         user.last_name = auth.info.name.split(' ').second
       end
     end
     unless user.avatar.present?
       photo_url = auth.info.image
       user.remote_avatar_url = photo_url # Carrierwave helper
       user.save
     end
     user
   end
{% endhighlight %}

What caused the second problem was that the model had two validation strategies conflicting with one another:
- Devise
- and Rails native `validates` method.

My user model had a `validates :password, presence: true` that was raising an error and preventing user from logging in. This useless line of code was caused by a lack of communication within our team. Talking more with each other would have saved us a lot of debugging ☝️.

## Push into production

After testing and merging my branch on GitHub we pushed it to Heroku. It’s important at that point to go back to your GitHub app page and update the app URL and the callback URL with your domain name.

Your app URLs should now look like these:

Homepage URL: `http://your_app_url.your_domain`

Callback URL: `http://your_app_url.your_domain/users/auth/github/callback`

Also, don’t forget to give Heroku your API keys. Otherwise your production environnement will not know how to interpret `config.omniauth :github, ENV['GITHUB_ID'], ENV['GITHUB_SECRET'], scope: 'user,public_repo’ ` in your *config/initializers/devise.rb* (and your users will get a magnificent 404).

Don’t forget to run:

{% highlight zsh %}
heroku run bundle # to install the omniauth gem
heroku run rails db:migrate # to update your users schema
heroku restart
{% endhighlight %}

And here it is, now people can sign-up and sign-in to your app using their GitHub credentials. 🙌
