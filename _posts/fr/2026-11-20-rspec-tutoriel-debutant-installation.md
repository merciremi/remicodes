---
layout: post
title: "Débuter avec RSpec : installation, conventions et structure des fichiers"
date: 2026-11-20
excerpt: "Dans ce tutoriel RSpec, je vous montre comment installer RSpec dans une application Rails, comprendre ses conventions et organiser vos fichiers de test."
lang: fr
permalink: /fr/rspec-tutoriel-debutant-installation/
translation_key: rspec-101-basic-set-up
translation_service: "Opus 5.5"
translation_date: 2026-11-20
---

> ## TL;DR : C'est quoi RSpec ?
>
> RSpec est un framework de test écrit en Ruby qui permet de tester du code Ruby (et Ruby on Rails). RSpec a été créé en 2005 par Steven Baker et est aujourd'hui le framework de test le plus utilisé de l'écosystème Ruby.
>
> La spécificité de RSpec par rapport à Minitest (un autre framework de test) ? RSpec se concentre sur le comportement attendu de votre programme : qu'est-ce que je passe en _input_ ? Qu'est-ce que j'attends en _output_ ?
>
> C'est aussi un super framework pour tester la quasi-totalité de votre _stack_.
{:.tldr}

Quand on débute en programmation, pas facile de savoir quoi tester, comment tester, et pourquoi tester. Vous avez sûrement entendu dire que le TDD (pour _Test Driven Development_) est LA bonne pratique par excellence. Mais au début, difficile de savoir ce que votre code doit faire avant même de l'écrire.

Les tests révèlent leur potentiel avec la pratique.

Quand j'ai commencé à programmer, je recopiais les tests des autres parce que, bon, il fallait bien commencer quelque part. Mais après quelques mois, mes tests ont commencé à révéler des _edge cases_, des bugs potentiels qui m'avaient échappé.

Commençons cette [série sur les fondamentaux de RSpec](/topics/rspec/) par **une introduction à RSpec** : comment installer RSpec dans votre application Rails, quelle convention de nommage suivre et comment structurer vos fichiers de test.

## Comment ajouter RSpec à votre application Rails ?

L'équipe de RSpec maintient la gem `rspec-rails` qui facilite l'utilisation du framework dans les applications Rails.

D'abord, ajoutez RSpec à votre Gemfile.

```ruby
  # Gemfile

  gem "rspec-rails", group: [:development, :test]
```

Installez la gem.

```zsh
  bundle install
```

Générez la configuration de RSpec et faites de RSpec le framework de test de votre application.

```zsh
  rails generate rspec:install
```

Maintenant, lancez vos migrations et préparez votre base de données de test.

```zsh
  rails db:migrate && rails db:test:prepare
```

Et voilà ! Vous pouvez maintenant lancer vos tests en tapant `rspec spec` dans votre terminal. `spec` est le dossier où vous créerez vos fichiers de test.

## La convention de nommage de RSpec

La convention de nommage de RSpec est simple :

- Le contrôleur `users_controller.rb` est testé par `users_controller_spec.rb`
- Le modèle `user.rb` est testé par `user_spec.rb`
- Le job `user_notification_job.rb` est testé par `user_notification_job_spec.rb`
- etc.

## Organisez votre dossier `spec`

Pour que RSpec et Rails fonctionnent ensemble, reproduisez l'arborescence de votre dossier `app` dans le dossier `spec`.

```zsh
  my_app_directory
  |
  |- app
  |  |
  |  |- models
  |     |
  |     |- user.rb
  |
  |- spec
     |
     |- models
        |
        |- user_spec.rb
```

Vos tests pourraient fonctionner, en partie, même si vous mettiez tous vos fichiers de test à la racine de `spec`. Mais RSpec essaie de deviner le type de test à partir de l'arborescence. Autant suivre cette convention.

Juste une subtilité : l'équipe de RSpec déconseille d'utiliser `spec/controllers`.

`app/controllers/users_controller.rb` est ainsi testé dans `spec/requests/users_controller_spec.rb` plutôt que dans `spec/controllers/users_controller_spec.rb`.

Pourquoi ? Parce que tester les requêtes vous permet de tester le comportement des actions de votre contrôleur à travers toute la _stack_ (routage, requête, réponse, etc.), plutôt que de tester le contrôleur isolément[^1].

Pour tester vos contrôleurs, la structure de votre dossier ressemble donc à ça :

```zsh
  my_app_directory
  |
  |- app
  |  |
  |  |- controllers
  |     |
  |     |- users_controller.rb
  |
  |- spec
     |
     |- controllers ❌
     |
     |- requests ✓
        |
        |- users_controller_spec.rb
```


## La structure de vos fichiers RSpec

Imaginons que nous voulions tester notre modèle `User`. Notre fichier ressemblera à ça :

```ruby
  # spec/models/user_spec.rb

  require 'rails_helper'

  RSpec.describe User do
    # test stuff
  end
```

Regardons chaque élément de plus près pour mieux comprendre ce qui se passe.

- `require 'rails_helper'` charge la configuration de RSpec. `rails_helper.rb` se trouve à la racine du dossier `spec`. RSpec est configuré d'office, donc pas besoin de vous en soucier.

- `RSpec` est le module principal de tout le code RSpec. Il encapsule et charge beaucoup de choses à l'instanciation : la configuration, le DSL des _expectations_, les exemples, etc. Vous pouvez jeter un œil au code [ici](https://github.com/rspec/rspec-core/blob/main/lib/rspec/core.rb#L41){:target="\_blank"}.

- `.describe` est une méthode définie sur le module `RSpec`. Elle regroupe vos tests autour d'une abstraction commune : une classe, une requête, etc. Dans l'exemple ci-dessus, notre abstraction est le modèle `User`.

Le code ci-dessous vient [du dépôt de RSpec](https://github.com/rspec/rspec-core/blob/fe3084758857f0714f05ada44a18f1dfe9bf7a7e/lib/rspec/core/dsl.rb#L42){:target="\_blank"}.

```ruby
  def self.expose_example_group_alias(name)
    return if example_group_aliases.include?(name)

    example_group_aliases << name

    (class << RSpec; self; end).__send__(:define_method, name) do |*args, &example_group_block|
      group = RSpec::Core::ExampleGroup.__send__(name, *args, &example_group_block)
      RSpec.world.record(group)
      group
    end

    expose_example_group_alias_globally(name) if exposed_globally?
  end
```

C'est un peu difficile à lire à cause de la métaprogrammation, mais l'idée principale est la suivante : ce code définit `describe` comme une méthode du module `RSpec`. Quand vous appelez `RSpec.describe User do ... end`, elle transmet vos arguments (`User`) et votre bloc à `RSpec::Core::ExampleGroup.describe`, qui en construit un groupe de tests, puis elle enregistre ce groupe pour que RSpec puisse l'exécuter.

- `User` est la classe que vous testez. Elle est passée en argument à la méthode `.describe`.

- `do ... end` est le bloc dans lequel vous écrivez vos tests. Ils seront passés en second argument à la méthode `.describe` (voir `&example_group_block` ci-dessus).

J'espère que ces explications vous aideront à mieux comprendre le fonctionnement de RSpec. La prochaine fois, nous écrirons nos premiers tests.

À bientôt,

Rémi - [@remi@ruby.social](https://ruby.social/@remi)

[^1]: Merci à [@Benoit](https://twitter.com/Benoit_Tgt){:target="\_blank"} de me l'avoir fait remarquer !
