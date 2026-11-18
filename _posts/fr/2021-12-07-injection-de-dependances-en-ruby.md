---
layout: post
title: "L'injection de dépendances en Ruby"
date: 2021-12-07
excerpt: "Vos objets Ruby dépendent les uns des autres en permanence. Mais la façon dont vous les liez entre eux détermine à quel point votre code sera facile à modifier. L'injection de dépendances peut vous aider à réduire ce couplage et le coût du changement."
lang: fr
permalink: /fr/injection-de-dependances-en-ruby/
translation_key: dependency-injection-in-ruby
translation_service: "Opus 5.5"
translation_date: 2026-11-18
---

En ce moment, je m'intéresse aux abstractions : Pourquoi les objets se comportent-ils comme ils le font ? Comment architecturer mon code pour qu'il reste ouvert au changement (sans provoquer de migraines inutiles) ? À quelle classe tel comportement devrait-il appartenir ? Et quand on s'intéresse à ces questions, une expression revient souvent : l'__injection de dépendances__. D'accord, mais **c'est quoi l'injection de dépendances ?** et comment on injecte une dépendance avec Ruby ?

## Qu'est-ce qu'une dépendance ?

D'abord, expliquons ce qu'est une dépendance.

<blockquote>Une dépendance est une abstraction dont dépend une autre abstraction.</blockquote>

Dans le contexte de [Ruby](/topics/ruby/), [une abstraction désigne principalement une classe](/beginners-introduction-to-ruby-classes-objects/).

Jetez un œil à votre base de code préférée. Vous devriez rapidement trouver une classe qui appelle une autre classe depuis l'une de ses méthodes.

Prenons un exemple : chaque mois, vous voulez calculer les revenus générés par des auteur·ices de livres.

Le code pourrait ressembler à ceci :

```ruby
  class Author
    # ...

    def monthly_revenue(month)
      RevenueCalculator.calculate_for(self, month)
    end
  end
```


Ici, `Author` dépend de `RevenueCalculator` pour obtenir les revenus générés sur un mois donné. `RevenueCalculator` est une dépendance de `Author`.

Cette dépendance se trouve dans le corps de la classe `Author`, planquée dans la méthode `monthly_revenue`.

`Author` sait que : 
  - `RevenueCalculator` existe, 
  - que `RevenueCalculator` a une méthode publique `calculate_for`
  - et que `calculate_for` prend deux arguments, une instance d'`Author` et un mois.

Cette connaissance crée un couplage fort entre `Author` et `RevenueCalculator`. Or, un couplage fort rend les changements plus difficiles à introduire quand de nouvelles exigences apparaissent. Par exemple, je veux pouvoir fournir différents types de `Revenue Calculator` en fonction des auteur·ices. 

C'est là que l'injection de dépendances peut desserrer le couplage entre vos classes.

## L'injection de dépendances expliquée simplement

<blockquote>L'injection de dépendances est une pratique qui permet de déplacer une dépendance des tréfonds d'une classe vers son initialisateur.</blockquote>

L'injection de dépendances est [un outil de conception dérivé du principe d'inversion des dépendances](https://stackoverflow.com/a/46745172){:target="\_blank"} (DIP, pour _Dependency Inversion Principle_). Le `D` de DIP est aussi le `D` des [principes SOLID](http://www.butunclebob.com/ArticleS.UncleBob.PrinciplesOfOod){:target="\_blank"}[^1].

Le principe d'inversion des dépendances dit que vos objets ne devraient pas dépendre d'autres objets spécifiques (des _concrétions_), mais d'abstractions de plus haut niveau.

Quelques exemples :
- `1` est une concrétion. `Integer` est son abstraction.
- `like`, `follow`, `retweet` sont des concrétions. `Interaction` est leur abstraction.
- `Algolia` ou `ElasticSearch` sont des concrétions. `SearchEngine` est leur abstraction.

## C'est quoi le problème avec les dépendances ?

La meilleure façon de comprendre le problème des dépendances, c'est de travailler sur des abstractions existantes et d'y ajouter de nouvelles exigences.

Voici votre code initial :

```ruby
  class Author
    # ...

    def monthly_revenue(month)
      RevenueCalculator.calculate_for(self, month)
    end
  end
```


Où est le problème ?

Ici, la classe `Author` est _fortement couplée_ à la classe `RevenueCalculator` pour ses calculs de statistiques.

Et si `RevenueCalculator` était une application tierce ? Et si je devais utiliser un service différent selon le pays de l'auteur·ice ?

Je pourrais bien sûr modifier `Author`. Une simple condition ferait parfaitement l'affaire.

```ruby
  class Author
    def monthly_revenue(month)
      if french?
        FrenchRevenueCalculator.calculate_for(self, month)
      else
        RevenueCalculator.calculate_for(self, month)
      end
    end
    # ...
  end
```

Mais que se passe-t-il si un nouveau pays nécessite un nouveau service tiers ? Je rajoute une condition ?

Comme l'écrit Sandi Metz, les conditions, ça se multiplie très vite. Une fois engagé sur cette voie, chaque nouvelle exigence rend votre code plus difficile à articuler.

Il est temps d'appeler l'injection de dépendances à la rescousse !

## Comment injecter des dépendances ?

Vous allez voir que la définition de l'injection de dépendances est plus compliquée que sa mise en pratique.

L'idée principale derrière l'injection de dépendances, c'est que votre classe puisse interagir avec différentes abstractions au lieu d'être coincée avec une seule concrétion. Comment ? En passant la dépendance à la classe lors de son initialisation.

On passe donc de ça : 

```ruby
  class Author
    # ...

    def monthly_revenue(month)
      RevenueCalculator.calculate_for(self, month)
    end
  end
```

à ça :

```ruby
  class Author
    def initialize(revenue_calculator: RevenueCalculator)
      @revenue_calculator = revenue_calculator
    end

    # ...

    def monthly_revenue(month)
      @revenue_calculator.calculate_for(self, month)
    end
  end
```

Ce qui s'est passé :
  - Nous avons déplacé la première mention de `RevenueCalculator` du corps d'`Author` vers son constructeur.
  - Puis, nous avons remplacé toutes les autres occurrences de `RevenueCalculator` par la variable d'instance décrivant l'abstraction, soit `@revenue_calculator`.

Désormais, je peux passer un nouveau calculateur lors de l'initialisation d'un auteur, ou utiliser `RevenueCalculator` par défaut.

```ruby
  # Will use FrenchRevenueCalculator
  french_author = Author.new(revenue_calculator: FrenchRevenueCalculator)
  french_author.monthly_revenue(Date.new(2021, 12))

  # Will use the default RevenueCalculator
  other_author = Author.new
  other_author.monthly_revenue(Date.new(2021, 12))
```

`Author` est plus modulable. La classe peut fonctionner avec différents calculateurs, du moment qu'ils répondent à la même API (c'est-à-dire, les mêmes méthodes publiques).

## Pourquoi l'injection de dépendances est-elle importante ?

### Couplage faible == coût du changement réduit

Au risque d'insister, répétons-le une dernière fois : les classes dépendent les unes des autres en permanence. Mais la façon dont vous les liez entre elles détermine le _coût du changement_.

Dans l'exemple ci-dessus, nous avons vu que s'il faut gérer plusieurs calculateurs de statistiques, les injecter lors de l'initialisation est bien plus simple que de choisir entre eux à coups de conditions.

Pour aller plus loin, je ne peux que vous recommander [99 Bottles of OOP](https://sandimetz.com/99bottles){:target="\_blank"} de Sandi Metz. Elle a écrit de très beaux chapitres sur le sujet.

### Meilleure lisibilité

Quand les développeurs éparpillent les dépendances dans une classe, il n'est pas facile pour les relecteurs de retrouver les dépendances, et encore moins de les garder en tête. L'injection de dépendances réduit cette friction.

Injecter les dépendances à l'initialisation les rassemble au même endroit. Elles sont plus faciles à lire et à retenir.

### Des tests plus simples

Quand une classe est fortement couplée à une autre, sa complexité transparaît dans vos tests.

Si vous voulez tester `Author#monthly_revenue` tel qu'il est défini ci-dessous, vous devez simuler `RevenueCalculator.calculate_for` et sa réponse.

```ruby
  class Author
    # ...

    def monthly_revenue(month)
      RevenueCalculator.calculate_for(self, month)
    end
  end

  RSpec.describe Author do
    describe '#monthly_revenue' do
      subject(:monthly_revenue) { author.monthly_revenue(Date.new(2021, 12)) }

      let(:author) { create :author }
      let(:value) { 3_666 }

      before do
        allow(RevenueCalculator).to receive(:calculate_for).and_return(value)
      end

      it 'fetches statistics' do
        # test things here
      end
    end
  end
```


Vos tests en savent plus qu'ils ne le devraient. Ils connaissent `RevenueCalculator` et sa méthode `calculate_for`.

Quand `Author` a une dépendance forte à une autre classe, impossible de le tester de manière isolée. Vous devez créer tout un contexte pour que vos tests passent. Vos tests sont ainsi liés à l'implémentation actuelle de `#monthly_revenue`. Si votre code change – en ajoutant des conditions, par exemple – vos tests devront changer aussi.

Avec l'injection de dépendances, vous relâchez un peu ce couplage. Vous pourrez même injecter, dans vos tests, un mock qui vous servira de calculateur réservé aux tests. 

Une fois encore, je vous encourage à lire la fin de _99 Bottles of OOP_, qui explore avec _brio_ la question des tests lorsqu'on déplace les dépendances vers l'initialisation.

## Quelques réflexions supplémentaires

Après avoir discuté avec [Jeremy Bertrand](https://blog.notgrm.dev/){:target="\_blank"}, j'ai eu envie d'ajouter quelques réflexions issues de notre conversation.

D'abord, l'injection de dépendances peut avoir lieu à différents moments de la vie d'un objet.

Prenons ce code :

```ruby
  class Author
    def initialize(revenue_calculator: RevenueCalculator)
      @revenue_calculator = revenue_calculator
    end

    # ...

    def monthly_revenue(month)
      @revenue_calculator.calculate_for(self, month)
    end
  end
```


Si je voulais spécifier un autre calculateur que celui par défaut, je devrais écrire quelque chose comme ceci :

```ruby
  Author.new(revenue_calculator: GermanRevenueCalculator)
```

Une injection plus réaliste pourrait être :

```ruby
  class Author
    # ...

    def monthly_revenue(month, revenue_calculator)
      revenue_calculator.calculate_for(self, month)
    end
  end
```


Ici, j'injecte un `revenue_calculator` uniquement quand j'en ai besoin. Et je n'ai pas besoin de savoir, lors de l'initialisation, de quel calculateur mon auteur·ice aura besoin.

Je pourrais tirer parti de la modularité de l'injection comme ceci :

```ruby
  author = Author.new(first_name: 'Deborah', last_name: 'Levy')

  author.monthly_revenue(Date.new(2021, 12), EnglishRevenueCalculator)
```


La définition de l'injection de dépendances que j'ai donnée plus haut est donc trompeuse.

Pour résumer, **voici une définition révisée de ce qu'est l'injection de dépendances en Ruby** :

<p class='callout'>L'injection de dépendances est une pratique qui permet <strong>d'exiger une dépendance</strong> au bon moment de la vie d'un objet, plutôt que de l'enfouir dans les entrailles d'une classe.</p>

L'injection de dépendances n'est pas non plus une panacée. Parfois, ce sera le bon outil. Parfois, il faudra un refactoring plus profond pour desserrer le couplage de votre code.

J'espère que ces dernières réflexions vous seront utiles !

À bientôt,

Rémi - [@remi@ruby.social](https://ruby.social/@remi)

[^1]: Je n'ai jamais réussi à retenir la signification de tous les principes SOLID. Franchement, un acronyme qui se décline en cinq acronymes, qui se déclinent eux-mêmes en principes cryptiques.
