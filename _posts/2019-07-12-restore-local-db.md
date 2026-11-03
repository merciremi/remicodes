---
layout: post
title:  'Debugging PGError: ERROR: column of relation already exists'
date:   2019-07-10
tags: [postgresql]
excerpt: "How do you fix a corrupted database's schema? Here's a hands-on tutorial on restoring your local database."
permalink: /pgerror-restore-local-database/
---

This error happens when you try to run a migration adding a column that already exists.

For instance, let's say you write a migration in your local environment to add the column `source` to a `lead`. You run it then realize your migration is useless.

So you delete the migration file but forget to `rails db:rollback` 😱. Rookie mistake! Your `source` column is still in `schema.rb` and in your local database.

If you later pull a colleague's branch that add a `source` column to `leads`, you'll get:

```zsh
  PGError: ERROR: column “source” of relation “leads” already exists
```

Your database's schema is corrupted. At this point, you can't do much to correct your mistake. You could:
- write a migration file to delete your `source` column
- meddle with the fingerprinting to have this migration run before your colleague's
- delete the file once you ran `rails db:migrate`

<mark>But that's a lot of messing around with a lot of possibilities to make things worse.</mark>

Another - and safer way - is to save your database and restore it anew. Let's see how to do this:

## 1) Find the database's name in `database.yml` and run the following command.

```zsh
  pg_dump -F c -v -h localhost <database_name> -f tmp/<pick_a_file_name>.psql
```

This will export your database to a `.psql` file.

## 2) Drop the database and recreate it

```zsh
  rails db:drop db:create
```

## 3) Restore your data to your database

```zsh
  pg_restore --exit-on-error --verbose --dbname=<database_name> tmp/<pick_a_file_name>.psql
```

The schema and database will sync up on your migration files. No more `source` in `leads`. 🙌
Don't forget to delete your `<pick_a_file_name>.psql` file from `/tmp`.

And *voilà*!

---

If you run into the following error:

```zsh
  PG::ObjectInUse: ERROR:  database <your_database_name> is being accessed by other users
  DETAIL:  There are 2 other sessions using the database.
```

run this into your terminal:

```zsh
  kill -9 $(lsof -i tcp:3000 -t)
```

It'll identify the server already running and kill it.

Hope this will help! If you need more tips and tricks, check out the rest of [the technical blog](/blog/).

Cheers,

Remi - [@remi@ruby.social](https://ruby.social/@remi)
