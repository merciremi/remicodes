---
toc: true
layout: post
title:  "C'est quoi une API ? Une explication (compréhensible) pour les utilisateurs métier"
date: 2016-04-13
excerpt: "Ces dernières années, les APIs (acronyme d'Application Programming Interface) sont devenues un vecteur incontournable de développement pour les start-ups."
category: 'other'
lang: fr
permalink: /fr/cest-quoi-une-api/
---

<div class="breadcrumbs">
  <a href="{{ site.baseurl }}/fr/blog">← Retourner au blog</a>
</div>

Avant de commencer, une rapide question. Savez-vous ce qui permet :
  - à votre application météo de toujours savoir le temps qu'il fera lors de votre week-end à Dunkerque ?
  - à Captain Train de savoir si un siège est disponible pour le trajet que vous avez sélectionné (Paris-Dunkerque) ?
  - à AirBnB de géolocaliser un bien sur une carte (est-il utile de préciser Dunkerque) ?

Eh oui, ce sont les APIs. 👍

Ces dernières années, les APIs (acronyme d'Application Programming Interface) sont devenues un vecteur incontournable de développement pour les start-ups.

Pour citer Paul Bonaud, développeur back-end chez Captain Train :

> Les APIs, intéressant et vaste sujet, n'est-ce pas !

Comprendre et proposer des APIs peut être un challenge pour les utilisateurs non techniques. Qu'est-ce qu'une API ? Que partage-t-on via une API ? Des données, des services ? Comment se pense une API ? Comment se code une API ? Quelle transformation stratégique cela implique-t-il ? Quels sont les investissements nécessaires ?

C'est parce que je me suis posé toutes ces questions (et bien plus encore) que j'ai décidé qu'il était temps de mieux comprendre de quoi il retournait. La tâche était un peu effrayante — quand on arrive comme moi d'un background aux antipodes de la technique -, mais j'ai bon espoir que les curieux seront satisfaits. Dans cette série d'articles, nous parlerons donc de :
  - c'est quoi une API ?
  - ça marche comment ?
  - qui s'en sert ?
  - etc.

Mais commençons par le commencement.

## C'est quoi une API ?

Les APIs, — ou Application Programming Interfaces — se définissent comme un ensemble de fonctions informatiques par lesquelles deux logiciels vont interagir sans intermédiation humaine. L'API est donc une abstraction définie par la description d'une interface et le comportement de l'interface.

Une API se décompose en trois mots-concepts :

  - Application. Par application s'entend tout service avec lequel un développeur ou une autre application souhaite interagir. Cela peut être un service météorologique, une application de partage d'images, un portail Open Data.
  - Interface. L'interface est la porte d'entrée par laquelle il sera possible d'interagir avec l'application.
  - Programme. Le programme est une fonction informatique à laquelle un développeur donne des instructions et qui va interagir avec l'application à notre place. Le programme peut par exemple récupérer des données à intervalles régulières ou soumettre une adresse postale (pour récupérer une coordonnée géographique)…

Les APIs sont donc utilisées par des programmes informatiques, permettant leurs interactions sous des conditions déterminées et documentées.

## Et ça fait quoi une API ?

Bien qu'étant couvertes de manière exponentielle par la presse spécialisée, les APIs et leurs enjeux sont encore mal saisis par les utilisateurs non-techniques.

Une API expose un service utile pour un développeur. Nous l'avons vu, ce service peut prendre des formes multiples: flux de données en temps réel, cartographie…

En parallèle, les développeurs écrivent des programmes qui consomment ces APIs.

Une API peut être utilisée dans différents environnements :

👉 Dans un environnement interne. Une API close peut revêtir différentes possibilités :
   - désiloter les données d'une grande entreprise en offrant un accès mutualisé à l'information
   - exposer une sérialisation complète d'une base de données constituée d'agrégation de données tierces et/ou multiples
   - tester son API dans des conditions d'intégrité de sécurité optimales

👉 Dans un environnement ouvert. Dans le cadre d'une exposition de points d'entrée publics à un service, une API peut servir à :
  - exposer des données (démarche Open Data, par exemple)
  - favoriser l'interpénétration d'un service au sein d'un écosystème (comme le propose le service Zapier

Si la pertinence des métaphores s'arrête où commence la complexité technologique, il peut être intéressant d'exposer les principales caractéristiques d'une API à travers la métaphore électrique.

Dans un premier temps, prenons un fournisseur d'électricité :
  - Ce fournisseur produit et distribue un service : l'électricité.
  - Pour distribuer ce service, il utilise une infrastructure : le réseau électrique (câbles, poteaux électriques, compteurs…).

Dans un second temps, prenons une lampe (consommateur de ce service) :
- La lampe, pour fonctionner, doit être reliée au réseau électrique.
- Pour y être reliée, la lampe est vendue avec une fiche qui devra être branchée dans une prise électrique.

La prise électrique est donc une interface (comme l'API) à travers laquelle la lampe (un développeur ou un programme) consomme un service (des données).

Les APIs permettent donc aux développeurs de déléguer le service qu'ils consomment. De la même façon, le propriétaire d'une lampe délègue la production d'énergie nécessaire à son fonctionnement à un pourvoyeur d'électricité.

Une autre caractéristique commune à une API et à une prise de courant : toutes deux spécifient les conditions d'interactions entre le consommateur et le service. Pour la lampe, cela peut prendre diverses formes :
  - le nombre et la forme des broches
  - le voltage et la fréquence
  - le type de courant

Une API fera de même et définira les paramètres de son utilisation :
  - la volumétrie : combien d'appels à l'API pour un laps de temps donné
  - le type de service que l'on peut en attendre : lire ou écrire
    etc…

Filons un instant encore la métaphore électrique.

Plusieurs lampes peuvent consommer simultanément ce même service en s'interfaçant à un réseau unique de par la standardisation de son interface (toutes les prises sont fonctionnellement similaires). Une personne peut également consommer simultanément plusieurs services en s'interfaçant avec chacun (électricité via une prise de courant ; eau via une arrivée d'eau).

L'API et la prise de courant sont donc des abstractions des services qu'elles exposent. Elles masquent au consommateur les spécificités du service. Les lampes sont insensibles aux détails du service qu'elles consomment (source de l'énergie, si d'autres lampes partagent le réseau, la couleur des câbles). Tant que le service correspond aux besoins fonctionnels des lampes (220 volts, courant continu), le fournisseur d'électricité peut modifier les détails de son réseau sans altérer le fonctionnement des luminaires.

Cette abstraction fonctionne dans l'autre sens, le service est insensible au design des lampes branchées sur son réseau. L'électricité circule sur le réseau électrique, qu'une lampe y soit, ou non, branchée.

Les APIs fonctionnent de la même façon. Elles permettent à un programme de consommer un service, qu'il soit composé de données temps-réel ou d'une fonctionnalité (partager des photographies). Les APIs et le service qu'elles exposent sont insensibles au programme qui les consomme.
