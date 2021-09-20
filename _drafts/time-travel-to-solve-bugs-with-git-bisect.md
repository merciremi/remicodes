---
layout: post
title: time travel to solve bugs with git bisect
---

No matter how good your test coverage is, you can't test everything.

Sometimes, a regression will occur in some part of your application and you won't notice it straight away. But when you notice something's wrong, it's hard to pin point where and when it happened.

The first option is to look at the list of commit your release branch and take wild guesses about the deploy that broke something. Then, you take even more wild guesses about the bit of code you changed. It's even worse if there are several people working on the app. I did this a few days ago, it doesn't work. You're chasing wrong leads and loosing precious time.

Then, I got introduced to git bisect. And man, that's a tool that instantly levels up your debugging skills. Let me show you how it works and how to use it.

## Linear search: Why checking every commit in antichronological order is not a good idea

- you have to check for every commit down the line. If you have 50 commits to check, it's super long.
- you have to take wild guesses about what could have broke your feature and sometimes, things are not that easy to pin point

git bisect uses a binary search algo to find which commit in your project’s history introduced a bug. What is a binary search?

A simple search check every commit one after the other. The more commits the longer it takes.
A binary search check the middle commit in a range of commits first. If the commit is not the one that sucks, it splits the remaining range of commits in two and move on to the next middle one. (Find a better way to explain bsearch).

## Binary search: Use git bisect

- go to your current app version that sucks
- `git bisect start`: enter git bisect mode
- `git bisect bad`: tell bisect that your current HEAD is fucked up
- `git bisect good <commit sha>`: tell bisect about a commit that you're sure worked just fine

<!-- now make draxing about the range of commit and which commit will bisect target -->

Now bisect will take you to the middle commit. This is the equivalent of doing a `git checkout <commit sha>` except you now leverage the power of bsearch.

What you need to do, is go and test your app, test your feature and see if it's working. I repeat, go and check your app. Click on something!

Why am I insisting on this? Because, the first time I used bisect, I had my own opinion about the commit that had introcued the bug and I didn't test my app, i would just say to bisect, no, it's not this one, not this one. Eventually ending up to the commit I thought was the bad. A good self refenrential loop. So no use. Also , turned out I was wrong about the culprit.

A side note: if you need to test your app in real life, it probable means you need to write a test of some kind. I my case, the problem would require an integration test with some response mock.

Anyway.

So you test your app and see what's what.

If your app is not working : `git bisect bad`
If your app is working : `git bisect good`

What it'll do :

<!-- make graph of turn right or left once you get it yourself -->

If the middle commit is `bad` it means that the bug got introduced prior of the middle commit. If the middle commit is `good` it means that the bug got introduced later to the middle commit.

So bisect will take that new range, and target the new middle commit.

Once you're there, you test your app once again. Select `good` or `bad` until bisect tells you : this is the culprit and output the files changed by that commit so you know where to look.

```
➜  youboox-web git:(master) ✗ git bisect start
➜  youboox-web git:(master|BISECTING) ✗ git bisect bad
➜  youboox-web git:(master|BISECTING) ✗ git bisect good ae998022
Bisecting: 20 revisions left to test after this (roughly 4 steps)
[02ca345f3e29217bb65539a231fb88db4dd4159d] Let's make some refreshment on our assets
➜  youboox-web git:((02ca345f3...)|BISECTING) ✗ bad
zsh: command not found: bad
➜  youboox-web git:((02ca345f3...)|BISECTING) ✗ git bisect bad
Bisecting: 11 revisions left to test after this (roughly 3 steps)
[76c502e15dba8ac5b807a8a8dadb5e26d44dc1da] Merge branch 'fix/two-classes-one-file' into 'master'
➜  youboox-web git:((76c502e15...)|BISECTING) ✗ git bisect bad
Bisecting: 3 revisions left to test after this (roughly 2 steps)
[e7e6f2ab20a7f9bd1210dfa68c558309a034eb6f] Merge branch 'BACK-1231-select-product-plan-at-gateway-creation' into 'master'
➜  youboox-web git:((e7e6f2ab2...)|BISECTING) ✗ git bisect bad
Bisecting: 1 revision left to test after this (roughly 1 step)
[4a6d8943db4e2d6cc008b8a2eebd12d87615726d] Merge branch 'fix/staging-deploy' into 'master'
➜  youboox-web git:((4a6d8943d...)|BISECTING) ✗ git bisect bad
Bisecting: 0 revisions left to test after this (roughly 1 step)
[996e5a376c7b9bdf70eb2865095ecececcd0d522] Remove the Dokku special database.yml file
➜  youboox-web git:((996e5a376...)|BISECTING) ✗ git bisect bad
Bisecting: 0 revisions left to test after this (roughly 0 steps)
[a7c40a6818c34f1ea1835f15b9941d1967281e9d] Merge branch 'BACK-1267-rails-6-migration' into 'master'
➜  youboox-web git:((a7c40a681...)|BISECTING) ✗ git bisect bad
a7c40a6818c34f1ea1835f15b9941d1967281e9d is the first bad commit
commit a7c40a6818c34f1ea1835f15b9941d1967281e9d
Merge: cfca51b2a ae9980228
Author: Jeremy BERTRAND <jeremy.bertrand@youboox.fr>
Date:   Tue Aug 3 13:51:20 2021 +0000

    Merge branch 'BACK-1267-rails-6-migration' into 'master'

    🎉 Migrate to Rails 6.0

    See merge request back/youboox-web!3427

 .rubocop_todo.yml                                  |  51 ++-----
 CHANGELOG.md                                       |   4 +-
 Gemfile                                            |  11 +-
 Gemfile.lock                                       | 159 +++++++++++----------
 app/business/cultura/boxes_activation.rb           |   6 +-
 .../cultura/boxes_activation/csv_parser_service.rb |   2 +-
 app/business/ftp_boxes_services.rb                 |   2 +-
 .../admin/admins/activations_controller.rb         |   4 +-
 .../admin/admins/reset_passwords_controller.rb     |   2 +-
 app/controllers/admin/agents_controller.rb         |   2 +-
 app/controllers/admin/authors_controller.rb        |   2 +-
 app/controllers/admin/catalogs_controller.rb       |   2 +-
 .../admin/editors/finances_controller.rb           |   2 +-
 .../admin/external_service_tokens_controller.rb    |   2 +-
 app/controllers/admin/redirections_controller.rb   |   2 +-
 app/controllers/admin/series_controller.rb         |   2 +-
 .../application_api_keys_controller.rb             |   2 +-
 .../sub_applications/categories_controller.rb      |   2 +-
 .../centers_of_interest_controller.rb              |   2 +-
 .../device_opportunities_controller.rb             |   2 +-
 .../device_applications_controller.rb              |   2 +-
 .../physical_product_coupons/exports_controller.rb |   2 +-
 .../marketing_operations_controller.rb             |   2 +-
 .../sub_applications/mobile_offers_controller.rb   |   2 +-
 .../admin/sub_applications/offers_controller.rb    |   2 +-
 .../admin/sub_applications/partners_controller.rb  |   2 +-
 .../search_recommendations_controller.rb           |   2 +-
 .../sub_applications/selections_controller.rb      |   2 +-
 .../admin/sub_applications/showrooms_controller.rb |   2 +-
 .../users/mailjet_callbacks_controller.rb          |   2 +-
 .../admin/sub_applications_controller.rb           |   2 +-
 .../admin/virtual_catalogs_controller.rb           |   2 +-
 .../admin/youboox_earnings_controller.rb           |   2 +-
 app/controllers/editors/authors_controller.rb      |   2 +-
 app/controllers/editors/books_controller.rb        |   2 +-
 app/controllers/editors/comments_controller.rb     |   2 +-
 app/controllers/editors/reviews_controller.rb      |   2 +-
 app/controllers/editors_controller.rb              |   4 +-
 app/controllers/errors_controller.rb               |   4 +-
 app/middlewares/web_api_referer_middleware.rb      |  64 ---------
 app/models/book/scorable.rb                        |   2 +-
 app/models/dashboards/edito.rb                     |   4 +-
 app/models/net_affiliation_tracking.rb             |   2 +-
 app/models/physical_product_coupon.rb              |   4 +-
 .../physical_product_coupon_csv_serializer.rb      |   2 +-
 app/services/admin/recurring_payment_receiver.rb   |   4 +-
 app/services/ftp_service.rb                        |   2 +-
 bin/setup                                          |  12 +-
 config/application.rb                              |   8 +-
 config/cable.yml                                   |   2 +-
 config/environments/development.rb                 |   5 +-
 config/environments/production.rb                  |  30 +++-
 config/environments/test.rb                        |  20 +--
 config/initializers/content_security_policy.rb     |   5 +
 config/initializers/inflections.rb                 |   3 +
 config/initializers/new_framework_defaults.rb      |  20 ---
 config/initializers/new_framework_defaults_5_1.rb  |  14 --
 config/initializers/new_framework_defaults_5_2.rb  |  38 -----
 config/initializers/register_middleware.rb         |   2 +
 config/initializers/renderers.rb                   |   2 +-
 config/puma.rb                                     |  16 ++-
 config/routes.rb                                   |   2 +-
 config/spring.rb                                   |  12 +-
 extras/tasks/set_missing_user_country.rb           |  15 ++
 extras/tasks/set_users_country.rb                  |  15 --
 lib/csv_builder.rb                                 |   4 +-
 lib/middlewares/web_api_referer_middleware.rb      |  64 +++++++++
 .../stats/editor_monthly_book_earnings_stats.rb    |  52 +++----
 lib/youboox/stats/editor_monthly_stats.rb          |  58 ++++----
 spec/business/cultura/boxes_activation_spec.rb     |   2 +-
 .../admin/editors/finances_controller_spec.rb      |   2 +-
 .../external_service_tokens_controller_spec.rb     |   2 +-
 .../sub_applications/offers_controller_spec.rb     |   2 +-
 .../sub_applications/partners_controller_spec.rb   |   2 +-
 .../admin/transactions_controller_spec.rb          |   2 +-
 spec/controllers/editors/books_controller_spec.rb  |   4 +-
 spec/controllers/errors_controller_spec.rb         |   4 +-
 spec/decorators/user_decorator_spec.rb             |   6 +-
 spec/factories/users.rb                            |   2 +-
 .../middlewares/web_api_referer_middleware_spec.rb |  86 +++++++++++
 .../middlewares/web_api_referer_middleware_spec.rb |  86 -----------
 spec/models/book_reading_spec.rb                   |   2 +-
 spec/models/book_spec.rb                           |   8 +-
 spec/models/category_spec.rb                       |  37 ++++-
 spec/models/device_opportunity_spec.rb             |   2 +-
 spec/services/ftp_service_spec.rb                  |   4 +-
 spec/support/shoulda_matchers.rb                   |   6 +
 87 files changed, 520 insertions(+), 527 deletions(-)
 delete mode 100644 app/middlewares/web_api_referer_middleware.rb
 delete mode 100644 config/initializers/new_framework_defaults.rb
 delete mode 100644 config/initializers/new_framework_defaults_5_1.rb
 delete mode 100644 config/initializers/new_framework_defaults_5_2.rb
 create mode 100644 extras/tasks/set_missing_user_country.rb
 delete mode 100644 extras/tasks/set_users_country.rb
 create mode 100644 lib/middlewares/web_api_referer_middleware.rb
 create mode 100644 spec/lib/middlewares/web_api_referer_middleware_spec.rb
 delete mode 100644 spec/middlewares/web_api_referer_middleware_spec.rb
 create mode 100644 spec/support/shoulda_matchers.rb

```

If you can't try the commit bisect has selected (because it doesn't build or something) you can `git bisect skip` and bisect will pick a new range and a new commit.

This is a basic usage for bisect. You can check many more application here : https://git-scm.com/docs/git-bisect

Cheers,

Rémi


