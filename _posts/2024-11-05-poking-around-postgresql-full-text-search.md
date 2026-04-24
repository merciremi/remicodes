---
toc: true
layout: post
title: "Poking around PostgreSQL full-text search: a beginners primer"
excerpt: "Today, I want to share a different type of post. Nothing polished. Just me goofing around with PostgreSQL's full-text search capabilities."
date: 2024-11-05
permalink: /postgresql-full-text-search-for-beginners/
categories: [other]
cover_image: "/media/2024/11/remi-mercier-postgresql-full-text-search-for-beginners.png"
---

Today, I want to share a different type of post. Nothing polished. Just me goofing around with PostgreSQL's full-text search capabilities. And yes, if you're wondering how someone can have fun while using full-text search, well, I'm wondering about that myself.

A note: this post is beginners friendly. Even though it is long, I'll only scratch the topic's surface.

Let's start with the basics!

## What is full-text search?

The PostgreSQL documentation says it best:

> Full-Text Searching (or just text search) provides the capability to identify natural-language documents that satisfy a query, and optionally to sort them by relevance to the query.
>
> <cite>[PostgreSQL documentation](https://www.postgresql.org/docs/current/textsearch-intro.html){:target="\_blank"}</cite>

In layman's terms, full-text search allows matches between a query and documents outside of exact matches. When querying with `=`, `LIKE`, or `ILIKE` is not enough, you reach for full-text search.

For instance, you have a database full of books, and you're searching for stories about `sorceresses`[^1]. But rows in your `books.title` column only have a few exact matches for this query. On the other hand, `books.blurb` contains a mixed bag of words like `sorceresses`, `sorceress` or `sorcerers`.

Some of these books might be of interest to you and you'd like them to match your query. Well, full-text search does just that. It takes your query `sorceresses`, normalizes it, matches it with normalized variations of your documents, and returns the results.

But I'm getting ahead of myself.

## What problems does full-text search solves?

Let's draw on the above example and look for a book filled with sorceresses!

My database currently stores a handful of books:

{% highlight sql %}
  CREATE TABLE books (
    title VARCHAR(255),
    blurb TEXT
  );

  INSERT INTO books (title, blurb) VALUES
  ('The Fair Sorceress', 'A thrilling tale of magic and mystery where a witch meets elves.'),
  ('The Silent Grove', 'A journey through an ancient, forgotten forest, with sorcerers and dwarves.'),
  ('The Last Kingdom', 'A historical novel set in medieval times where sorceresses save the day.'),
  ('Deep Depth', 'A suspenseful story of adventure of sailors at sea.'),
  ('Sorcery School', 'A young-adult thriller where a sorceress and a sorcerer fight to keep the school from being eat up by zombies.');

  INSERT 0 5
{% endhighlight %}

Let's try to select some books.

{% highlight sql %}
  SELECT * FROM books
  WHERE title LIKE '%sorceresses%';

   Title | Blurb
  -------+-------

  (0 rows)
{% endhighlight %}

Ugh, that's disappointing. What about querying on the blurb instead?

{% highlight sql %}
  SELECT * FROM books
  WHERE blurb LIKE '%sorceresses%';

          Title     |    Blurb
  ------------------+---------------------------------------------------------------------------------------------------------------------------------------
   The Last Kingdom | A historical novel set in medieval times where sorceresses save the day.

  (1 rows)
{% endhighlight %}

Better!

But I know I have more relevant books. Let's add an OR operator so I can search for variation of `sorceresses`.

{% highlight sql %}
  SELECT * FROM books
  WHERE blurb LIKE '%sorceress%' OR blurb LIKE '%sorceresses%';

        Title           |    Blurb
  ----------------------+---------------------------------------------------------------------------------------------------------------------------------------
   The Last Kingdom     | A historical novel set in medieval times where sorceresses save the day.
   Sorcery School       | A young-adult thriller where a sorceress and a sorcerer fight to keep the school from being eat up by zombies.

  (2 rows)

{% endhighlight %}

We're getting there, but what about `The Silent Grove` or `The Fair Sorceress`? They'd be a good match.

I could add new conditions to my `WHERE` clause. But in real-life applications, word variations and searchable columns could add up quite a bit.

This long-winded (yet contrived) example shows you, reader, that when you hit the limitations of basic search operators, it's time to reach for PostgreSQL's full-text search.

## How does full-text search works?

### From documents to tokens

Full-text search turns **documents** (for instance, the rows of your database) **into tokens**. Tokens are <mark>the smallest semantic units extracted from your documents</mark>. They can be strings, numbers, email addresses, etc. PostgreSQL uses a built-in parser, but you can provide your own parser if you wish.

Let's take the following string stored in a row of `books.blurb`:

{% highlight txt %}
  A young-adult thriller where a sorceress and a sorcerer fight to keep the school from being eat up by zombies.
{% endhighlight%}

PostgreSQL will first turn this string into tokens.

PostgreSQL does not expose (to my knowledge) the intermediate tokenization step, but here's a workaround I've found that'll help you make sense of this process.

Let's start by splitting the string into an array of words, unpacking the array, adding a `position` column indicating the index of each word, and ordering the words alphabetically.

{% highlight sql %}
  SELECT token, position
  FROM unnest(string_to_array('A young-adult thriller where a sorceress and a sorcerer fight to keep the school from being eat up by zombies.', ' '))
  WITH ORDINALITY AS t(token, position)
  ORDER BY token;

      token    | position
  -------------+----------
   A           |        1
   a           |        5
   a           |        8
   and         |        7
   being       |       16
   by          |       19
   eat         |       17
   fight       |       10
   from        |       15
   keep        |       12
   school      |       14
   sorcerer    |        9
   sorceress   |        6
   the         |       13
   thriller    |        3
   to          |       11
   up          |       18
   where       |        4
   young-adult |        2
   zombies.    |       20
  (20 rows)
{% endhighlight %}

Let's note a few things:
- Stop words are still present.
- Punctuation is still present.
- Words have not been converted to normalized representations yet (`zombies` is still `zombies`: plural, the `e` suffix representing the meaning as a word).

PostgreSQL strips stop words and suffixes during the next step when it converts tokens into lexemes.

### From tokens to lexemes

Once PostgreSQL has converted your documents to tokens, it **converts tokens into lexemes**.

Lexemes are **normalized representations of your tokens**: different forms of the same word made alike.

> In short, then, tokens are raw fragments of the document text, while lexemes are words that are believed useful for indexing and searching.
>
> <cite>[PostgreSQL documentation](https://www.postgresql.org/docs/current/textsearch-intro.html#TEXTSEARCH-DOCUMENT){:target="\_blank"}</cite>

For instance:

{% highlight txt%}
      tokens   |  lexemes
  -------------+-------------
   magic       | magic
   MAGICS      | magic
   magical     | magic
   magically   | magic
{% endhighlight %}

Wanna try it? Fire up a PostgreSQL console and type the following:

{% highlight sql %}
  SELECT to_tsvector('magic MAGICS magical magically');
     to_tsvector
  -----------------
   'magic':1,2,3,4
  (1 row)
{% endhighlight %}

`magic`, `magics`, `magical`, and `magically` are all variations of the stem `magic`, which PostgreSQL identifies as the relevant representation of the previous variations.

You can see how PostgreSQL distributes the lexemes when transforming several words:

{% highlight sql %}
  SELECT to_tsvector('magical MAGIC magician');

    to_tsvector
  --------------------------
    'magic':1,2 'magician':3

  (1 row)
{% endhighlight %}

The transformation of tokens into lexemes follows several steps:
- Folding upper-case letters to lower-case.
- Removing suffixes.
- Removing stop words.
- Adding the positional information of each token matched with its lexeme.

This is where full-text search shines: you get a natural language input from your users (i.e. `magical elves and fun sorceresses`) and you compare it against your data.

Chances are, you won't get an exact match. So, one way to up your chances of a match while keeping the results relevant is to split the input into manageable semantic chunks.

{% highlight sql %}
  SELECT to_tsvector('magical elves and fun sorceresses');

    to_tsvector
  -----------------------------------------
    'elv':2 'fun':4 'magic':1 'sorceress':5

  (1 row)
{% endhighlight %}

How does PostgreSQL turn tokens into lexemes? With **dictionaries**!

PostgreSQL uses default dictionaries, but you can pass or create custom ones based on your needs. Want to work with French documents? Pass `french` as first argument to your `to_tsvector()` method. Want to add a bit of fuzzy matching? Add an Ispell dictionary that'll map synonyms to a single word. Neat!

{% highlight sql %}
  SELECT to_tsvector('french', 'les bonnes baguettes et les croissants');
                to_tsvector
  ----------------------------------------
   'baguet':3 'bon':2 'croiss':6 'le':1,5
  (1 row)
{% endhighlight %}

I won't dig much into dictionaries at this point, but feel free to read the [documentation](https://www.postgresql.org/docs/current/textsearch-dictionaries.html){:target="\_blank"}. You can do a _lot_ of configuration around dictionaries with PostgreSQL.

Finally, normalized lexemes are stored in a specific datatype called `tsvector`.

{% highlight sql %}
  SELECT pg_typeof(to_tsvector('sorcerers'));

    pg_typeof
  -----------
    tsvector
  (1 row)
{% endhighlight %}

## Processing queries

So far, we've seen how PostgreSQL processes your data.

User queries follow the same basic steps as documents:
- Convert input into tokens.
- Convert tokens into lexemes.
- Return combined lexemes stored in a `ts_query`.

However, PostgreSQL adds several strategies when processing user queries.

### Boolean and phrase search operators

After converting user input into lexemes, PostgreSQL returns a `ts_query` where lexemes are combined using either:
- **boolean operators**: `&` (AND), `|` (OR), `!` (NOT)
- **phrase search operators**: `<->` (FOLLOWED BY), `<N>` (FOLLOWED BY where `N` is an integer specifying the distance between the two lexemes being searched for)

{% highlight sql %}
  -- Select both 'fun' and 'elves'
  SELECT 'fun & elves'::tsquery;
       tsquery
  -----------------
   'fun' & 'elves'
  (1 row)

  -- Select either 'fun' or 'elves'
  SELECT 'fun | elves'::tsquery;
       tsquery
  -----------------
   'fun' | 'elves'
  (1 row)

  -- Select 'elves' but not 'fun'
  SELECT '! fun & elves'::tsquery;
       tsquery
  ------------------
   !'fun' & 'elves'
  (1 row)
{% endhighlight %}

Of course, PostgreSQL provides a bunch of methods to parse a query and turn it into a `ts_query`.

### Parsing queries: `to_tsquery`, `plainto_tsquery`, `phraseto_tsquery`, `websearch_to_tsquery`

PostgreSQL offers different methods to parse a query, each with its own features.

#### `to_tsquery`

`to_tsquery` takes a query that must be a list of tokens already separated by operators. Tokens can be grouped using parenthesis to control the binding between operators (i.e. which couple of operators takes precedence over another couple).

For instance, I can't pass a plain sentence to `to_tsquery` because it expects tokens separated by operators such as `&`, `|`, etc.

{% highlight sql %}
  SELECT to_tsquery('The fun elves and the magical sorceresses');
  ERROR:  syntax error in tsquery: "The fun elves and the magical sorceresses"
{% endhighlight %}

Once I provide a formatted list, PostgreSQL turns my tokens into lexemes, and the fun can begin.

{% highlight sql %}
  SELECT to_tsquery('The & fun & elves & and & the & magical & sorceresses');
                to_tsquery
  ---------------------------------------
   'fun' & 'elv' & 'magic' & 'sorceress'
  (1 row)
{% endhighlight %}

`t_tsquery` needs a premilinary normalization on my part, which can be annoying, but it also gives me a lot of control over the query. `to_tsquery` allows me to specify my operators. Let's say I want books with `fun elves` but no `magical sorceresses`, I can group my tokens like so:

{% highlight sql %}
  SELECT to_tsquery('The & fun & elves & and & the & !magical & !sorceresses');
                 to_tsquery
  -----------------------------------------
   'fun' & 'elv' & !'magic' & !'sorceress'
  (1 row)
{% endhighlight %}

#### `plainto_tsquery`

If I don't want to normalize my input beforehand, I can delegate the work to PostgreSQL with `plainto_tsquery`. It'll normalize my text, remove stop words, and add the `&` operator inbetween surviving words.

{% highlight sql %}
  SELECT plainto_tsquery('The fun elves and the magical sorceresses');
              plainto_tsquery
  ---------------------------------------
   'fun' & 'elv' & 'magic' & 'sorceress'
  (1 row)
{% endhighlight %}

`plainto_tsquery` offers convenience over control. For instance, you can't use logical operators anymore. For example, you can't specify you don't want `magical sorceresses` anymore.

{% highlight sql %}
  SELECT plainto_tsquery('The fun elves and the !magical !sorceresses');
              plainto_tsquery
  ---------------------------------------
   'fun' & 'elv' & 'magic' & 'sorceress'
  (1 row)
{% endhighlight %}

#### `phraseto_tsquery`

`phraseto_tsquery` is similar to `plainto_tsquery` except the `&` (AND) operator is replace by the `<->` (FOLLOWED BY) operator. Also, the stop words are not discarded but are used to compute the number of semantically less important words between lexemes (using the `<N>` operator).

This is useful when you need to fetch results from a group of words that are semantically more relevant together than separated. Think `Lord of the Ring` or `The Wheel of Time`, or any such sentences.

{% highlight sql %}
  SELECT phraseto_tsquery('the wheel of time');
    phraseto_tsquery
  --------------------
   'wheel' <2> 'time'
  (1 row)
{% endhighlight %}

You'd rather get books from the Wheel of Time series than any random books with the words `wheels` and `time` in their blurb. `phraseto_tsquery` also does not recognize operators.

#### `websearch_to_tsquery`

Finally, `websearch_to_tsquery` offers a similar approach to _natural language_ inputs, but handles some operators too.

The PostgreSQL documentation explains its syntax:

> - `unquoted text`: text not inside quote marks will be converted to terms separated by & operators, as if processed by plainto_tsquery.
> - `"quoted text"`: text inside quote marks will be converted to terms separated by <-> operators, as if processed by phraseto_tsquery.
> - `OR`: the word “or” will be converted to the | operator.
> - `-`: a dash will be converted to the ! operator.
>
> <cite>[PostgreSQL documentation](https://www.postgresql.org/docs/current/textsearch-controls.html#TEXTSEARCH-PARSING-QUERIES){:target="\_blank"}</cite>

Let's search for books about `fun`, `elves`, but no `magical sorceresses`.

{% highlight sql %}
SELECT websearch_to_tsquery('The fun elves and -"the magical sorceresses"');
             websearch_to_tsquery
----------------------------------------------
 'fun' & 'elv' & !( 'magic' <-> 'sorceress' )
(1 row)
{% endhighlight %}

Books about `sorceresses` might pop up, as long as the `sorceress` is not preceded by `magical`.

The possibilities are endless.

## Ranking results

This post is getting very long, so I'll try to be brief.

PostgreSQL allows you to rank results based on:
- the frequency of lexemes in documents with `ts_rank`.
- the density of lexemes in documents (`frequency x proximity`) with `ts_rank_cd`.

{% highlight sql %}
  SELECT title,
         ts_rank(
             to_tsvector(blurb),
             websearch_to_tsquery('fun elves and magical sorceresses')
         ) AS rank
  FROM recipes
  ORDER BY rank DESC
  LIMIT 10;

                     title                     |   rank
-----------------------------------------------+----------
 The Fair Sorceress                            |      3.1
 The Last Kingdom                              |      2.4
 Sorcery School                                |  2.01317
 (3 rows)
{% endhighlight %}

You can add weights arguments to give an extra boost to specific columns for instance.

I'll let you read the ad hoc [documentation](https://www.postgresql.org/docs/current/textsearch-controls.html#TEXTSEARCH-RANKING){:target="\_blank"}

## Conclusion

Well, this post got quite long. If you made it to here, well done! But remember, we only just scratched the surface of full-text search. PostgreSQL provides much much more functionnalities, and search is a field on its own.

Cheers,

Rémi - [@remi@ruby.social](https://ruby.social/@remi)

[^1]: I probably should read something other than the Wheel of Time.
