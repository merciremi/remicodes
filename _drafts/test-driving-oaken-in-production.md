---
layout: post
title: Test driving Oaken in production
excerpt:
date: 2000-01-01
permalink:
category:
cover_image:
toc: true
---

TL;DR: A post about how I use Oaken for a client test data (with a twist).

## Oaken: presentation
- Built by Kasper (link)
- General pitch: Oaken is fixtures + factories + seeds for your Rails development & test environments.
- Specificities: 
  - Uniting dev and test data: so you test with data closer to the real thing.
  - Scenarii, and object graphs: get a comprehensive understanding of how your data interacts and how your codebase works.

## The twist from my client codebase
The codebase has a seed file that is too complex to tackle at the same time as our test setup. And we had no prior tests in the app, so clean slate for this. Still, it's an app that's 8-ish years old, makes money ever since and has had no downtime since its launch, so not a toy app.

So we're moving slowly and take a side road to have Oaken only for test data.

## Key differences with factories
With factories you create the data you need on the fly, so it's tailored to your need. 

BUT it also means a lot of database operations making factories notoriously slower than fixtures (created once before tests start) and since you tailored your test data to your test, you also embed your biais on your testing, leaving gaps where the unexpected can happen.

## Key differences with fixtures
I never used fixtures in production, but Kasper has, and the "build data first then execute tests" approach is a tell.

One thing that stands for me, is that fixtures force you to build and hold the mental model of your object graph in your mind, whereas Oaken allows you to lay it out right there on paper (well, on your file). And this talks to me a lot.

## Building objects graphs
Something quite cool and confusing at first, is that Oaken allows to build object graphs, so how each piece of data relate to a larger ensemble. 

It looks a lot like how factory works but in a more explicit manner, but without a DSL to hide things out. I thing most of my confusion came from the fact I've used FactoryBot for years and I got so used to the DSL that it took some time to wire new paths in my brain.

Here is an example:

```
manuscript = manuscripts.first
editor = users.editor
author = users.create

# contract
contract = contracts.create(
  :,
  author: author,
  editor: editor,
  manuscript: manuscript,
  status: "first_read"
)

# reviews
meetings.create(contract:, event_type: "first-read",    start_time: 3.weeks.ago)
meetings.create(contract:, event_type: "final-review",  start_time: 2.days.ago)

# invoices
invoices.create(
  :advance,
  contract:,
  author:,
  invoice_type: "advance",
  invoice_amount_in_cents: "2_100_000",
  invoice_status: "added",
  invoice_date: 1.day.ago
)
```

## Default data and data access in tests
The ability to setup default data so you DRY for every test data.

You can also name objects so there are easy to reference in your tests. We used Buffy-themed data, so calling `users.giles` makes it easy to know where to look. Add some strong conventions on naming your test files, and your right at home.

For instance, in `db/seeds/test/users/` we have a folder for company-related users and one for public-facing users. So `db/seeds/test/users/team` and `db/seeds/test/users/customers`. So, it's super easy to go and find stuff.

## My main struggles while setting up Oaken
First, I had created a default user, that I would  use in my object graphs and it was causing conflict on unicity ofr instance. 

Also, understanding that defaults are more for defaults values than defualt object.

Using it only for test data required me to do some slightly out of the box setup. How it is supposed to work: seeds act as the entry point.

But we couldn't use seeds.rb. What we did instead: put everything in db/seeds/test, told Oaken to pick up the data from there instead of seeds.

Your mileage may vary, but for me the whole setup looks like this:

```
# seeds.rb
# Ask Oaken to setup the data
if Rails.env.test?
  Oaken.prepare do
    seed :setup # Allow Oaken to reference default values for our seed objects
    seed :users
    seed :manuscripts
    seed :contracts
    seed :meetings
    seed :invoices
  end

  return
end

# Just require Oaken in my test setup
# test/test_helper.rb
module ActiveSupport
  class TestCase
    # some other stuff
    include Oaken::TestSetup
    # some more stuff
  end
end

# Use the fully-fledged invoice in my test
# test/integration/manuscript_invoicing_test.rb
require "test_helper"

describe "ManuscriptInvoicing", :integration do
  let(:order) { invoices.advance }
  
  # assert a bunch of stuff
end
```

## Conclusion
Now that we have manage our setup, things go smoothly, tests run fast. Let me know if you want some more information.

Also, thanks to Kasper for helping me out setup Oaken for the application. I had many questions, and he kindly took time to answer them and point in the right direction.
