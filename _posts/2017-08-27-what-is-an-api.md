---
layout: post
title: What is an API?
date: 2017-08-27 14:34 +0100
excerpt: "Wrapping your head around APIs can be challenging for non-technical users. What’s an API? What can be share through an API? Data? Services? How does one design an API?How do you code an API?"
category: 'other'
permalink: /what-is-an-api/
---

Before we start, I’d like to ask you a few questions. Do you know how:

- [Authentic Weather](http://authenticweather.com/) knows the weather it’ll be doing during your upcoming trip to Dunkirk?
- [Trainline](https://www.thetrainline.com/) knows if a seat is available (of that very same upcoming trip to Dunkirk)?
- [Airbnb](https://www.airbnb.com/) puts available flats on a map (do I even need to say “of Dunkirk”)?

<img class='large' src="{{ site.baseurl }}/media/2017/what-is-an-api-remi-mercier.gif" alt="">

These past few years, APIs (also known as Application Programming Interfaces) have spread like wildfire in the startup growth game.

To quote [Paul Bonaud](https://twitter.com/paulrb_r), back-end engineer at [@trainline_fr](https://twitter.com/trainline_fr) (formerly Captain-Train):

<blockquote>
  APIs, quite an interesting and vast subject, isn’t it?
</blockquote>

Wrapping your head around APIs can be challenging for non-technical users. What’s an API? What can be share through an API? Data? Services? How does one design an API?How do you code an API?

Because I asked myself all of these questions (and many more), I’ve decided that it was time to get a better understanding of what APIs are all about. It’s a bit scary though - especially when you come from a non-technical background - but I’m sure people will find it entertaining. I plan on writing about various topics:

- what’s an API?
- how does it work?
- who’s using it?
- etc…

But let’s start from the beginning.

## What is an API?

APIs - or Application Programming Interfaces - are defined as a set of functions (a coded procedure performing a particular task) through which two software can talk to each other without any human intermediation. An API is an abstracted point of entry to a piece of software with a description of the open interface and its behavior.

Let’s break that acronym down:

- **Application**: By application, we mean a service with which a developer wants to interact. This service can be a stream of meteorological data, an image sharing app or an open data portal.
- **Interface**: The interface is the entry door to the service. You have to go through that door to interact with the service capabilities (e.g., filtering meteorological data for a city, publishing pictures on Instagram…)
- **Program**: The program is a set of coded procedures written by a developer. The program is designed to interact with the application, so we don’t have to. For example, the program can submit a postal address to get coordinates (think Airbnb or Google Map).

<img class='large' src="{{ site.baseurl }}/media/2017/what-is-an-api-diagram-remi-mercier.png" alt="">

To sum it up: APIs are programs using a specific point of entry (the interface, also call an end-point) to interact with an application (or some features within this application).

## Ok, but what does an API do?

Nowadays, APIs are well covered. You’ll find lots of articles about the “Greatest XXX APIs every developer need to know.” But the very basics of APIs are not concisely explained and still elude non-technical users.

An API allows a developer to access a service. One usually says that an API exposes a service.

We’ve seen it above; the service can come in many shapes and forms: real-time data streams (e.g., Twitter), maps (OpenStreetMap), publishing a picture (Instagram).

Developers write programs that consume these APIs.

### APIs can be used in various environments:

👉 In a closed environment:

- to mutualize your company data across departments’ lines
- to expose a database’s serialization made from multiple data sources
- to test an API in a secure environment before releasing it publicly

👉 In an open environment:

- expose data to the world: think open data portals
- allow other companies to offer their services within your application: think Giphy integration in Slack, Zapier…

### Let's try a metaphor

Metaphors can be tricky when it comes to technological matters. But the gist of APIs can easily be understood using the electricity network as a proxy.

Let’s start with an electricity supplier:

- this supplier produces and distributes a service: electricity
- to distribute this service, the supplier relies on an infrastructure: the electric network (stations, transmission lines, utility poles, sockets)

Now, let’s take a lamp that needs to consume electricity:

- for the lamp to work, it needs to be connected to the electric grid
- to be connected, the lamp is sold with a plug that fits standards sockets

The socket is a standardized point of entry (an interface) through which a lamp consumes electricity. An API is a standardized point of entry (an interface) through which a program consumes an application.

APIs allow developers to delegate a service they need to consume. In the same way, the lamp’s owner delegates the electricity needed by her lamp to the electricity supplier.

Let’s dig further. APIs and electrical sockets both specify how the user can consume the service. Remember our lamp? It needs to respect some conditions to using the service:

- the number and shape of the pins
- voltage and frequency
- type of current
- etc…

APIs will do the same and specify conditions to use them:

- number of API calls for a defined laps of time
- what you can expect to do: read and/or write
- etc…

Thanks to the standardization of sockets, you can plug several lamps in your home without thinking twice about it. What matters is that every socket is functionally similar: it brings electricity right into your home.

**APIs and sockets are abstractions for the service they expose.**

Wait, what? Abstractions? 🤔

They hide the nitty-gritty of the service the customer uses.

Without sockets, you’d need to twist your lamp’s wires around those sticking out of your wall. Lamps don’t give a dime about the details of the electrical grid. They work whether the electricity comes from solar panels or wind turbines; whether the cables within the wall are black, red or pink; whether other lamps are plugged into the network or not. As long as the electricity supplier provides the lamp with its functional needs (AC and 110 volts if you live in the US), the supplier can modify its network at will. Without this abstraction, you’d need to wrap your lamp’s wires around the wires in the wall.

The abstraction works the other way round. The electric grid doesn’t care about the design of your lamp. Whether your lamp is designed by Ikea or [Wilhelm Wagenfeld](http://www.tecnolumen.com/12/Wilhelm-Wagenfeld-Table-lamp.htm), the grid only cares about the plug fitting the socket. Electricity flows from the station to your socket even if no lamps are plugged in it.

APIs work the same way.

Without APIs, Authentic Weather would need to weather.com’s data on a regular basis (or any other meteorological data provider). Thanks to APIs, Authentic Weather doesn’t care about the nitty-gritty of the meteorological data it receives every second. As long as the data stream (accessible through the API) is functionally stable, Authentic Weather is happy (and its users are happy).

The abstraction works the other way round. weather.com’s API doesn’t care about your app’s color scheme. As long as your app consume the API within the pre-defined conditions, it’s 👌.


----------

Was this helpful? Lemme know in the comments or on [Mastodon](https://ruby.social/@remi)!
