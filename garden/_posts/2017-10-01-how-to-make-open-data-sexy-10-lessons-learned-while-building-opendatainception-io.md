---
layout: post
title: 'How to make Open Data sexy: 10 lessons learned while building opendatainception.io'
date: 2017-10-01
excerpt: "In June 2015, Nicolas Terpolilli and I were ranting about the difficulty to locate Open Data portals. Poor SEO seemed to result in poor rankings. Existing listings were either outdated or partisan. We started joking around with the idea of building a truly comprehensive resource. A resource that would gather every single Open Data portal we could lay our hands on."
permalink: /make-open-data-sexy/
---

In June 2015, [Nicolas Terpolilli](https://twitter.com/NTerpo) and I were ranting about the difficulty to locate Open Data portals. Poor SEO seemed to result in poor rankings. Existing listings were either outdated or partisan. We started joking around with the idea of building a truly comprehensive resource. A resource that would gather every single Open Data portal we could lay our hands on.
This seemed to be a common need too. We would come across multiple threads on Twitter, [Reddit](https://www.reddit.com/r/datasets/), [Quora](https://www.quora.com/Where-can-I-find-large-datasets-open-to-the-public)… And all of these would start with this unique question:

<blockquote>
  Where can I find clean and usable data?
</blockquote>

When you strive to build the best data and API management platform, you need data. A lot of data. Whether they be for [creating network effects](https://medium.com/@nicolasterpolilli/open-data-network-the-challenge-of-interconnectivity-c7a3cd2a073), innovative use-cases or quirky infographics.
So, instead of waiting for someone else to build a comprehensive listing of all Open Data portals around the world, we decided to make it happen.

A couple of Dr Evil gifs later, we wrote down what we then dubbed the **Open Data Inception** project on our respective to-do lists. Little did we know it would gather more than 85,000 unique visits over the course of the following months.

In November 2015, we released the V1 of Open Data Inception: [a list of 1,600+ Open Data portals around the world](https://www.opendatasoft.com/a-comprehensive-list-of-all-open-data-portals-around-the-world/). The list covered countries ranging from the US (500+ Open Data portals) to Afghanistan (3 portals).

Response was incredible. Open Data Inception reached people beyond the Open Data community: data scientist, statisticians, public good-doers… We gathered hundreds of feedbacks, more than 75,000 unique visits, and thousands of shares and interactions on social media.
This lead us to believe we had incidentally validated something that was worth pursuing: how design — in both a visual and service approach — can help knit a tighter and stronger Open Data network.

Without further ado, let’s get down to business. Here are the 10 lessons in making data sexy we learnt while building [opendatainception.io](https://opendatainception.io/).

## 👆 Know where to look: find usable data

When looking for data, the first go-to ressources are usually open data portals run by countries and metropolis. A few examples come to mind:

- The official French Open Data portal : https://www.data.gouv.fr/en/
- Paris Open Data portal: http://opendata.paris.fr/page/home/
- The official UK portal: https://data.gov.uk/
- The US Open Data portal: http://www.data.gov/

These portals grant access to hundreds of thousands of datasets. You can browse topics ranging from education to public safety, cadastral information, or biodiversity.

Some of these portals also harvest other portals. For example, [data.gouv.fr](https://www.data.gouv.fr/en/) harvests other French cities’ portals. Problem is, harvesting is not a lightweight feature on a technical roadmap. So harvesting is often incomplete and users only access a selection of all the Open Data available out there.

Once you’re done browsing these portals, you’re basically left with your own devices. I usually go and check Reddit, Quora, Twitter or GitHub. If I don’t find anything there, I’ll google for some data.

Problem is — and let’s be very candid about it — , Open Data portals’ SEO is usually 💩. Portals do not do well in terms of linking their datasets with each other (semantically for instance). Datasets’ pages don’t usually leverage the power of content (i.e. No text, no images, etc).

I also rely on serendipity, but this can take a while to find something valuable.

This is why we built opendatainception.io: to give people who need data a comprehensive ressource to easily find Open Data portals throughout the world.

## ✌️ Can’t find clean data? Make it yourself!

For something as open as Open Data, people have a hard time pooling resources regardless of technological obedience.

This is why we decided to scrap existing resources. We already did it for [our infamous list of French cheeses](https://www.opendatasoft.com/2015/05/04/how-to-create-a-map-with-open-data-the-map-of-french-cheese/). [And we did it again](https://www.youtube.com/watch?v=CduA0TULnow). 🤷‍♂️

We gathered a first list of ~1,600 open data portals. Data was incomplete: lot of geographic coordinates missing, encoding problems, duplicates, etc.

We used simple scripts, namely Clojure, to harmonize the different fields. For example, we capitalized textual fields or converted geographic data into one coordinate system.

We also did our best to remove duplicates, dead links… I spent days normalizing were portals were to be mapped, adding coordinates by hand (yup!), correcting names… We were working guerrilla-style, so we did not bother with quality that much. We wanted to launch it and test if people would be interested.

## 👆✌️ Find a story to tell

Aggregating data is one thing. Making it sexy is quite another.

Our story was easy to find. We wanted to built:

<blockquote>The most comprehensive list of data portals ever made!</blockquote>

Nicolas and I believe that being shy usually doesn’t get you anywhere. 😎

We could have played it safe a share a repository on GitHub. Techies would have opened it, may be even starred it for later? Who knows.

But we wanted more. We wanted it to be the go-to resource for everyone in the data community — from techies to n00bs. We wanted this list to be bookmarked, pocketed (yes, it’s verb nowadays) and sent through private messages from one person to another. We wanted this list to be the link sent everytime the question “Where can I find data?” would pop-up in a conversation.

## ✌️✌️ Make the magic happen. And make it happen fast!

I am extremely lucky to be surrounded by people who can make anything with data: infographic, words, tweets, commits, APIs, posters…

Because, let’s face it: rough data is only attractive to a handful of people.

Data should speak for itself but outside the realm of data scientists or data geeks like us, it doesn’t. Normal people, business stakeholders, politicians… they all need help to understand the underlying truths hidden in data.

It doesn’t mean you should aim for simplistic interpretation. Some things require people to reach a deeper level of understanding to express their full potential. But for opendatainception.io, we thought it’d be a shame to leave some many people behind.

That’s why we first launched a static list sorted by alphabetic order. Alphabetical list are easy to browse. We added a table of content where countries name would take readers directly to the appropriate part of the list.

<img src="{{ site.baseurl }}/media/2017/sexy-open-data-list-of-open-data-portals.gif" alt="">

The fist list was a HTML export. Nicolas would run a Ruby script turning a CSV into preformated HTML everytime we needed to update the list. After a dozen updates, we grew fed up with the process. We decided to inject some Angular JS context in our Wordpress page. We used open source widgets that create dynamic elements within a page. Our list would then update itself in real-time through APIs creating an endless communication between our widgets and the dataset (thanks to APIs). Timesaver!

Then, we decided to make a stand-alone website for people to browse the list a map. Hence was born opendatainception.io.

Once again, using open source widgets and Bootstrap, I built the website in a few hours. I used 25 lines of code, taken straight from the [tutorial](http://opendatasoft.github.io/ods-widgets/docs/#/tutorial/00setup). I didn’t have to handle Javascript, nor Python, nor PHP. Just some HTML and CSS. All the real-time filtering and map’s behaviour is handled by the widgets.

I simply focused on designing something usable, making room for the data and pretty (Sue me, I love pretty).

All along, we didn’t go by the book. We didn’t focus on a bulletproof quality. We launched it fast and asked questions later.

## 🖐 Launch and distribution

Years in marketing taught me one thing: writing is 20% of the job and distribution is 80%.

Yet, we didn’t have any smart-ass plan. We merely tweeted the list through the corporate Twitter account. A visual banner, a catchy tweet, nothing more.

At that time, OpenDataSoft Twitter account already had a decent number of highly engaged people. Retweets and mentions started to pile up in our Slack channel.

<blockquote class="twitter-tweet" data-lang="en"><p lang="en" dir="ltr">Ever dreamed of all <a href="https://twitter.com/hashtag/OpenData?src=hash&amp;ref_src=twsrc%5Etfw">#OpenData</a> portals around the 🌍 on a single list? We did it for you. - <a href="https://t.co/wbyqrd7Zua">https://t.co/wbyqrd7Zua</a> <a href="https://t.co/46Iak7C7XK">pic.twitter.com/46Iak7C7XK</a></p>&mdash; OpenDataSoft (@opendatasoft) <a href="https://twitter.com/opendatasoft/status/661899077391507456?ref_src=twsrc%5Etfw">November 4, 2015</a></blockquote>
<script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

The French version of this tweet [gathered 100 retweets](https://twitter.com/opendatasoft/status/662202481968062464) in 24 hours. ✌️

[I also posted it on Reddit](https://www.reddit.com/r/datasets/comments/3rih8y/i_have_listed_every_publicly_available_open_data/) where it gathered more than 150 upvotes in a couple of hours. I gave Redditors a bit of back story, a bit of how-it-was-built and, gave them regular updates. I spent a few minutes crafting a catchy title around two main points:

- the “I-build-this-as-an-individual-not-as-a-corporation” angle (which was perfectly true, so my karma is safe)
- a self-explanatory title with numbers in it.

So far, it’s still the second top post of all time in [r/datasets](https://www.reddit.com/r/datasets/top/?sort=top&t=all).

<img src="{{ site.baseurl }}/media/2017/how-to-make-open-data-sexy-reddit-remi-mercier.png" alt="">

The next day, we built and launched opendatainception.io, the list visualized as a map.

A few months later, we organized a webinar-thingy where Nicolas and I talked about the inception of opendatainception.io, the numbers, etc. This led to new tweets, people signing-up, traffic… We streamed the webinar on Periscope (and got called “fucking nerds” for it 🖕).

At the same time, [Nicolas shared opendatainception.io on Product Hunt](https://www.producthunt.com/posts/open-data-inception). The post became the 5th product of the day. For 48 hours, we saw a huge traffic spike.

Most importantly, we spent countless hours talking to people about it (mostly on Twitter), answering tweets, following-up when an update would be released… To me, this seems like the most important part of our distribution:

- talking a lot about it,
- not hammering people through “corporate” channels,
- a lot of informal conversations, follow-ups…

## 🖐👆 Explain the process

I guess I love explaining how things are built not because I took computers apart when I was 8 (I didn’t, I was busy playing ⚽️) but because of cooking. When you love to cook, you usually love talking about your recipes with friends (all the while topped with a lot of natural red wine).

It gives people a better understanding of how you did what you did and gives an extra push to your story.

For opendatainception.io, we wrote a long-form blog post explaining the nitty gritty of the process:

- the initial pain point a.k.a. “I can’t find any data portals on the internet”
- gathering data from multiple source
- cleaning data:
> It almost immediately raised the question of our own geopolitical knowledge. Should we classify England, Wales and Northern Ireland in different rows or include them in the United Kingdom? What about the Isle of Man, which is a self-governing British Crown Dependency? In order to avoid unnecessary fraying, we used [the United Nations list of sovereign states](https://en.wikipedia.org/wiki/List_of_sovereign_states). Source
- how we built opendatainception.io

I won’t re-tell the whole story, you can find it [here](https://www.opendatasoft.com/2015/11/02/how-we-put-together-a-list-of-1600-open-data-portals-around-the-world-to-help-open-data-community/).

## 🖐✌️ Make your product better

Whatever you do, it’s bound to be perfectible. Like Boileau said:

<blockquote>Put your work twenty times upon the anvil. Polish it continuously, and polish it again.</blockquote>

We took a lot of feedback through emails, on Twitter, Reddit, LinkedIn and, from our own team. At least 30% of the records were either dead links, or were displaying portals in the wrong place… We were determined to launch first and count on the community to give feedback! And it worked!

After this massive cleanup, we launched the V0.2. And we knew it was, at that point, the most comprehensive list ever made.

In late 2016, our UX designer and front-end engineer, redesigned opendatainception.io: better mobile navigation, tooltips customization… Kuddos to [Thibaut](https://twitter.com/ThibautDupre) and [Jeremy](https://twitter.com/jmorel_fr) 🙌 !

## 🖐✌️👆 Make your data available and reusable

Nicolas has a strong stance when in comes to open data as [HTML resources](https://medium.com/@nicolasterpolilli/nope-html-is-not-open-data-dabc2f172eb).

<blockquote>Let’s be clear, HTML resources are a terrible excuse for Open Data, and just make me want to leave your portal!</blockquote>

We wanted people to be able to use the resources in their favourite format. This is why we published it a list, a map and an open dataset that can be downloaded as a CSV or used as an API.

We also chose the Public Domain license. Everyone can use our legwork as a bedrock for building more cool things!

I’ve heard a few times this question: “Isn’t there a risk of people stealing your work and building a better product?”

Well, yes there is. And that’s exactly the point. If someone turn the list into something cooler and more useful for the community, that’s perfect! And as we said earlier, having data is far from enough. Creating something useful for a large crowd is the tricky part.

## 🖐✌️✌️ Keep in touch

We’ve kept in touch with a lot of people over the past months. Especially people on Twitter who pointed out corrections, suggested new portals… Nicolas went out of his way to follow-up with everyone (usually within the day).

<blockquote class="twitter-tweet" data-lang="en"><p lang="en" dir="ltr">Our friends at <a href="https://twitter.com/opendatasoft?ref_src=twsrc%5Etfw">@opendatasoft</a> have published a comprehensive list of <a href="https://twitter.com/hashtag/data?src=hash&amp;ref_src=twsrc%5Etfw">#data</a> portals around the world! - <a href="https://t.co/M9jVZIaBDf">https://t.co/M9jVZIaBDf</a> <a href="https://twitter.com/hashtag/opendata?src=hash&amp;ref_src=twsrc%5Etfw">#opendata</a></p>&mdash; ODI Leeds (@ODILeeds) <a href="https://twitter.com/ODILeeds/status/882173420041097217?ref_src=twsrc%5Etfw">July 4, 2017</a></blockquote>
<script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>
<blockquote class="twitter-tweet" data-lang="en"><p lang="en" dir="ltr">I&#39;d be glad to add them! ☺️ We&#39;ve got a form <a href="https://t.co/p3N5DerOlB">https://t.co/p3N5DerOlB</a> but please let me know if you prefer another solution</p>&mdash; Nicolas Terpolilli (@nterpo) <a href="https://twitter.com/nterpo/status/882262790202961921?ref_src=twsrc%5Etfw">July 4, 2017</a></blockquote>
<script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>
<blockquote class="twitter-tweet" data-lang="en"><p lang="en" dir="ltr">And here they are : <a href="https://t.co/Ms0cTzZaQr">https://t.co/Ms0cTzZaQr</a>&#39; thank you very much for your help! cc <a href="https://twitter.com/foldschmidt?ref_src=twsrc%5Etfw">@foldschmidt</a> <a href="https://twitter.com/opendatasoft?ref_src=twsrc%5Etfw">@opendatasoft</a></p>&mdash; Nicolas Terpolilli (@nterpo) <a href="https://twitter.com/nterpo/status/882620563319029760?ref_src=twsrc%5Etfw">July 5, 2017</a></blockquote>
<script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>
<blockquote class="twitter-tweet" data-conversation="none" data-lang="en"><p lang="en" dir="ltr">And we&#39;re nearly at 2,800 portals listed on opendatainception.io! 💪</p>&mdash; Rémi Mercier (@mercier_remi) <a href="https://twitter.com/mercier_remi/status/882621087883960323?ref_src=twsrc%5Etfw">July 5, 2017</a></blockquote>
<script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>
*Making opendatainception.io better, one tweet at a time!*


I’ve done the same on Reddit too.

The only thing I could have done better, would have been to keep in touch faster with people who submitted their email on opendatainception.io. I got caught in other stuff and waited months before sending word. Momentum lost. Sorry all, I’ll do better next time!

## 🖐🖐 Keep on pushing

Remember when I talked about open data portals being 💩 at SEO? Well, we thought that a technological layer could be a great solution. It would work as [a crawler](https://en.wikipedia.org/wiki/Web_crawler) coupled with a sitemap.xml file. The file would map a portal’s metadata (and link to deeper levels of information). Nicolas coded a first draft of dataportal.json:

{% highlight json %}
{
"language": "en",
"name": "Paris Data",
"description": "City of Paris Open Data portal",
"url": "http://opendata.paris.fr/",
"linked_portals": ["http://data.gouv.fr", "http://data.iledefrance.fr"],
"data_language": ["fr"],
"modified": "2016-03-04T13:44:44+00:00",
"themes": ["Culture, Heritage", "Education, Training, Research, Teaching", "Environment", "Transport, Movements", "Spatial Planning, Town Planning, Buildings, Equipment, Housing", "Health", "Economy, Business, SME, Economic development, Employment", "Services, Social", "Administration, Government, Public finances, Citizenship", "Justice, Safety, Police, Crime", "Sports, Leisure", "Accommodation, Hospitality Industry"],
"links": [
  {"url": "http://opendata.paris.fr/explore/download/", "rel": "Catalog CSV"},
  {"url": "http://opendata.paris.fr/api/", "rel": "API v1"},
  {"url": "http://opendata.paris.fr/api/datasets/1.0/search?format=rdf", "rel": "Catalog RDF"}
],
"version": "1.0",
"number_of_datasets": 176,
"organization_in_charge_of_the_portal":{
  "name": "City of Paris",
  "url": "http://www.paris.fr/"
},
"spatial": {
  "country": "FR",
  "coordinates": [
    48.8567,
    2.3508
  ],
  "locality": "Paris",
  "data_spatial_coverage": "a Geojson with the data coverage"
},
"type": "Local Government Open Data Portal",
"datapackages": [
  "http://opendata.paris.fr/explore/dataset/liste_des_sites_des_hotspots_paris_wifi/datapackage.json",
  "http://opendata.paris.fr/explore/dataset/points-de-vote-du-budget-participatif/datapackage.json",
  "http://opendata.paris.fr/explore/dataset/cinemas-a-paris/datapackage.json"
  ]
}
{% endhighlight %}

We 💘 Json.

We hosted a webinar thingy where we talked about numbers, the how-to, etc. We launched the metadata file during this webinar to see if it could get any traction. A handful of people got very interested but its redundancy with the [Project Open Data Metadata Schema v1.1](https://project-open-data.cio.gov/v1.1/schema/) was a real concern.

We quickly realized that dataportal.json would not gathering any steam, so we let it go. 👋

Today, opendatainception.io gathers almost 2,800 portals around the world and still remains the go-to resource for hundreds of people every month! 😍

## 👋 Let’s wrap it up 👋

I think the key take away of opendatainception.io is that building cool side projects — that are genuinely useful for the community — beats a lot of marketing gimmicks (and believe me, I know a few of these). It’s more fun to build, more useful for people and doesn’t take away your karma points.

The way I see it, marketing will have to become more and more transparent in the near future to stay relevant. Less scammy tactics; less waiting-until-it’s-perfect-shipping; less strategy. More opiniated products, some ol’ fashion elbow greese and a lot (LOT) of conversation with people using it.

----------

Kuddos to [Nicolas Terpolilli](https://medium.com/@nicolasterpolilli/) for making opendatainception.io such a fun project to build; the data community at large for sharing the love and giving us plenty of feedback; and the OpenDataSoft team for helping out and making it better over time!
