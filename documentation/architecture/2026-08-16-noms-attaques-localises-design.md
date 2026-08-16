# Noms d'attaques localisés — design

**Date :** 2026-08-16
**Statut :** validé, prêt pour un plan d'implémentation

## Problème

Les noms d'attaques sont affichés en anglais partout — en combat comme dans l'éditeur. La demande
est de les afficher en français, sans fermer la porte à d'autres langues plus tard.

Le catalogue moves est alimenté depuis Pokémon Showdown, qui ne publie que l'anglais. Le converter
écrit donc une seule langue, à
`packages/map_editor/lib/src/application/services/showdown_move_catalog_converter.dart:142` :

```dart
names: <String, String>{'en': displayName},
```

Le modèle canonique porte pourtant **déjà** la structure nécessaire, à
`packages/map_core/lib/src/models/pokemon_move.dart:217` :

```dart
required String name,
@Default(<String, String>{}) Map<String, String> names,
```

Ce champ est écrit et **jamais lu** : aucune résolution localisée n'existe côté lecture. Le tuyau
est posé, il est vide et personne n'est branché au bout.

Le merge de synchronisation, lui, préserve déjà volontairement les noms locaux
(`sync_pokemon_moves_catalog_use_case.dart:601`), et son commentaire cite explicitement `names.fr`
comme champ à ne pas écraser. L'intention existait donc déjà ; elle n'a simplement jamais été
alimentée ni consommée.

### Ce qui existe déjà et sera réutilisé

| Brique | Rôle | Emplacement |
|---|---|---|
| `SceneLocalizedText.resolve(locale)` | résolution `exact → langue → fallback` | `map_core/lib/src/models/scene_finish_game_contract.dart:70` |
| `ProjectLocaleResolver.resolve(...)` | négociation préférence ↔ locales disponibles | `map_core/lib/src/localization/project_locale_resolver.dart:9` |
| `GameSessionContract.locale` | la locale est déjà transportée dans le runtime | `map_runtime/lib/src/session/game_session_contract.dart:197` |
| `PlayableMapGame.runtimeLocale` | locale du jeu, défaut `'fr-FR'` | `map_runtime/lib/src/presentation/flame/playable_map_game.dart:242` |
| `PlayerLanguage { system, fr, en }` | préférence joueur persistée | `map_player_ui/lib/src/preferences/player_preferences.dart:3` |

La sémantique de résolution est donc déjà écrite et testée dans le projet. Elle est appliquée à
`names` plutôt que redéfinie.

### Les trois producteurs de noms

Le point qui structure toute la solution : il n'y a pas une source de noms de moves, mais trois.

1. **Le seed bootstrap embarqué** — 28 moves écrits en dur, utilisés à la création d'un projet
   neuf (`map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart`). Son commentaire
   est explicite : *« le bootstrap n'a donc ni dépendance `rootBundle`, ni dépendance réseau »*.
2. **Le converter Showdown** — ~900 moves, au moment de la synchronisation, via le réseau.
3. **Les moves custom** créés par l'auteur, que le merge préserve déjà.

Le seed étant offline par conception, une source purement réseau ne peut structurellement pas
l'alimenter. Un projet fraîchement bootstrappé resterait en anglais jusqu'à sa première
synchronisation. Il faut donc un artefact local.

## Décisions

| Question | Décision |
|---|---|
| Langues livrées | Français uniquement. La structure reste multi-langues sans travail supplémentaire. |
| Surfaces | Joueur **et** éditeur. |
| Source des noms FR | Table versionnée, générée hors ligne depuis PokeAPI. |
| Édition des noms dans l'éditeur | Lecture seule. Aucun champ de saisie ajouté. |
| Source de vérité à l'affichage | Le catalogue projet (`names`), jamais la table. |
| Surcharge manuelle de `names.fr` | Non garantie. La source externe fait autorité sur les langues qu'elle fournit. |
| Format de la table | Fichier Dart généré. |
| Localisation de la chrome battle | Hors périmètre. |

### Pourquoi une table versionnée plutôt qu'un enrichissement réseau

Trois raisons, par ordre d'importance :

1. Elle est la seule à pouvoir alimenter le **seed bootstrap**, qui interdit toute dépendance
   réseau. Un enrichissement au sync laisserait tout projet neuf en anglais.
2. Le matching d'ids Showdown ↔ PokeAPI est le vrai risque du chantier. Résolu à la génération, il
   produit un rapport lisible en revue de PR. Résolu à chaud, il dégrade silencieusement vers
   l'anglais et personne ne le voit.
3. Elle supprime ~900 requêtes HTTP par synchronisation.

Le coût assumé est qu'il faut régénérer la table à la sortie d'une génération. Le dépôt a déjà
exactement ce pattern avec `tool/rebuild_pokemon_catalog.dart` et
`tool/export_embedded_pokemon_moves_bootstrap.dart`.

### Pourquoi un fichier Dart et non un asset JSON

Le seed bootstrap interdit `rootBundle`. Un asset JSON serait structurellement inutilisable par
l'un des deux consommateurs. Le fichier Dart généré reste par ailleurs cohérent avec le seed, qui
est déjà du Dart en dur, et reste diffable en revue.

### Pourquoi le catalogue reste la source de vérité à l'affichage

La table alimente le catalogue **en écriture** (sync et bootstrap) ; l'affichage lit le catalogue,
jamais la table. Le runtime n'embarque donc aucune table de traduction : il lit la donnée projet,
exactement comme aujourd'hui.

### Ce que la synchronisation écrase, et pourquoi c'est assumé

`_mergeNames` (`sync_pokemon_moves_catalog_use_case.dart:613`) fusionne la map locale puis laisse
la valeur externe écraser clé par clé. Aujourd'hui, un `names.fr` saisi à la main survit à un sync
uniquement parce que la source externe ne fournit jamais de `fr`. **Dès le lot 3, elle en fournira,
et l'écrasera donc.**

Ce comportement est conservé tel quel, sans exception pour le français, pour deux raisons :

1. La décision « lecture seule » signifie qu'aucun chemin supporté ne permet à l'auteur d'écrire un
   nom français. Protéger une valeur que l'UI ne sait pas produire reviendrait à construire une
   politique de surcharge avant d'avoir le besoin.
2. Une exception par langue rendrait toute correction de traduction dans la table incapable
   d'atteindre les projets existants — l'inverse du but recherché.

La conséquence est explicite : une surcharge manuelle de `names.fr` dans le JSON sera perdue à la
prochaine synchronisation. C'est précisément la question à trancher le jour où l'édition des
traductions sera ouverte, et une raison de plus de ne pas l'ouvrir dans ce lot.

## Architecture

```
    [tool offline, one-shot]
    PokeAPI /move/{id} ──► table de noms localisés versionnée (map_editor)
                                   │
                    ┌──────────────┴──────────────┐
                    ▼                             ▼
        converter Showdown (sync)        seed bootstrap (28 moves)
                    │                             │
                    └──────────────┬──────────────┘
                                   ▼
                    catalogue projet : names { en, fr }   ◄── source de vérité
                                   │
                    ┌──────────────┴──────────────┐
                    ▼                             ▼
         map_runtime (présentation)        map_editor (affichage)
         buildBattleCommandMenuModel       catalogue moves, learnsets
```

### Le domaine battle n'est pas touché

`BattleMoveDecisionOption` porte déjà `moveId` **et** `moveName` côte à côte
(`map_battle/lib/src/domain/decision/battle_decision.dart:254`). L'identifiant canonique voyage
donc jusqu'à la couche présentation, qui peut résoudre le libellé sans qu'aucune notion de langue
n'ait à descendre dans `battle_timeline_event` ni dans les timelines sérialisées.

C'est une contrainte dure, pas une préférence : localiser en amont rendrait les replays dépendants
de la locale du joueur qui les a enregistrés.

## Composants

### `map_core` — la résolution

- `LocalizedNames.resolve({names, locale, fallback})` dans `lib/src/localization/`, reprenant la
  sémantique de `SceneLocalizedText.resolve` : correspondance exacte, puis code langue, puis
  fallback.
- `PokemonMove.displayName(String locale)` qui l'utilise, avec `name` en fallback. Le modèle
  dispose déjà de `const PokemonMove._()`, la méthode s'ajoute sans toucher au code freezed généré.

### `map_editor` — la table et sa génération

- `tool/generate_pokemon_move_localized_names.dart` : parcourt PokeAPI, croise avec le snapshot
  Showdown, émet la table triée sur stdout et le rapport de non-appariés sur stderr.
- `lib/src/application/seeds/pokemon_move_localized_names.dart` : la table générée, voisine du seed
  bootstrap.
- `showdown_move_catalog_converter.dart:142` : `names` enrichi depuis la table.
- `pokemon_moves_bootstrap_seed.dart:870` (helper `_showdownSeedMove`) : même enrichissement.

#### Le matching d'ids

Le converter dérive son identifiant local du **nom anglais**, pas de l'identifiant Showdown
(`_normalizeSnakeCaseId(displayName)`, ligne 80). La normalisation, ligne 1252, met en minuscules,
remplace `[\s-]+` par `_`, puis supprime tout caractère hors `[a-z0-9_]`.

La table doit donc être indexée en passant le **nom anglais PokeAPI** dans cette même fonction, et
non le slug PokeAPI. Les deux divergent sur la ponctuation :

| Nom anglais | Showdown → id | Slug PokeAPI → id | Nom EN PokeAPI → id |
|---|---|---|---|
| `U-turn` | `u_turn` | `u_turn` | `u_turn` |
| `King's Shield` | `kings_shield` | `kings_shield` | `kings_shield` |
| `10,000,000 Volt Thunderbolt` | `10000000_volt_thunderbolt` | `10_000_000_volt_thunderbolt` | `10000000_volt_thunderbolt` |

Passer par le nom anglais garantit une entrée identique à celle de Showdown, donc une sortie
identique. Le slug est utilisé en repli uniquement si le nom anglais est absent du payload.

`_normalizeSnakeCaseId` est aujourd'hui une méthode privée d'instance du converter. Elle est
extraite en fonction de niveau supérieur partagée, et le converter continue de l'utiliser. C'est le
seul refactor de l'existant prévu par ce design, et il est nécessaire : le tool et le converter
doivent normaliser identiquement, sinon la table ne peut pas être indexée de façon fiable.

### `map_runtime` — la présentation

Une locale seule ne suffit pas, et la raison est structurelle. `BattleMove`
(`map_battle/lib/src/battle_move.dart:153`) porte `id` et `name`, mais **pas** la map `names` :
`map_battle` est délibérément pur et indépendant du modèle projet. La couche présentation ne peut
donc pas résoudre une traduction à partir du seul objet battle.

La résolution passe par une fonction injectée, alimentée par le catalogue projet :

- `RuntimeMoveCatalog` (`application/runtime_move_catalog_loader.dart:203`) expose déjà
  `Map<String, PokemonMove> entriesById`, chargé avec cache au moment du setup battle. C'est la
  table de résolution, elle existe.
- `PlayableMapGame` conserve le catalogue résolu et construit un
  `String Function(String moveId, String fallbackName)` combinant ce catalogue et `runtimeLocale`.
- `BattleOverlayComponent` reçoit ce resolver. C'est déjà la convention du composant, qui accepte
  `spriteResolver`, `genderResolver`, `bagItemIconResolver` et `itemCapabilityResolver`
  (`playable_map_game.dart:7591`).
- `buildBattleCommandMenuModel` (`presentation/flame/battle_command_menu_model.dart:100`) reçoit le
  resolver et l'applique dans `_entryForChoice`, en résolvant par `move.id` avec `move.name` en
  repli.

Ce détour est le prix de la pureté du domaine battle, et il la confirme plutôt qu'il ne la remet en
cause : aucune notion de langue n'entre dans `map_battle` ni dans les timelines sérialisées.

### `map_editor` — l'affichage

- `PokemonMoveCatalogEntryView` (`sync_pokemon_moves_catalog_use_case.dart:23`) transporte `names`
  en plus de `name`.
- Le catalogue moves et les panneaux de learnset affichent le nom résolu.
- Le tri se fait sur le nom affiché.
- **La recherche porte sur le nom français, le nom anglais et l'identifiant.** Sans cela, saisir
  `thunderbolt` ne renverrait plus rien.
- Un badge signale les moves dépourvus de nom français, avec un compteur global. C'est le seul
  chemin par lequel l'auteur apprend qu'une resynchronisation est nécessaire.

## Comportement en cas d'absence de donnée

Aucune de ces situations ne peut interrompre une partie.

| Situation | Comportement |
|---|---|
| Move sans nom français | Repli sur l'anglais. Silencieux côté joueur, badge côté éditeur. |
| Locale inconnue (`fr-CA`) | Repli sur le code langue (`fr`), puis sur `name`. Jamais de chaîne vide. |
| Catalogue jamais resynchronisé | Tout reste en anglais, comme aujourd'hui. Aucune régression. |
| Table et catalogue désynchronisés | Aucune erreur, dégradation silencieuse vers l'anglais. |
| PokeAPI indisponible | Le tool échoue, hors production. Le runtime n'a aucune dépendance réseau. |

Le seul composant susceptible d'échouer s'exécute hors production. C'est le bénéfice principal de
la table versionnée.

## Tests

Le test qui porte le risque réel est celui de la **normalisation d'ids** : c'est le seul endroit où
une erreur est silencieuse. La fonction extraite est testée sans réseau, sur des cas de ponctuation
choisis : `U-turn`, `King's Shield`, `10,000,000 Volt Thunderbolt`, `Will-O-Wisp`.

- **`map_core`** : résolution nominale, repli par code langue, map vide, locale malformée, fallback
  sur `name`.
- **Converter** : `names` contient `fr` lorsque la table connaît l'entrée ; conserve le
  comportement actuel sinon.
- **Seed bootstrap** : les 28 entrées portent un nom français.
- **Merge de sync** : une entrée externe portant `fr` écrase bien le `fr` local, et un move
  purement local absent du snapshot conserve l'intégralité de sa map `names`. Ce test fige le
  comportement décidé ci-dessus plutôt que de le laisser implicite.
- **`map_runtime`** : `buildBattleCommandMenuModel` rend le nom français quand le resolver en
  fournit un, et retombe sur `BattleMove.name` quand le resolver renvoie le fallback — y compris
  lorsque le move est absent du catalogue.
- **`map_editor`** : la recherche trouve un move par son nom anglais alors que l'affichage est en
  français.

### Goldens

`packages/map_player_ui/test/goldens/battle/separated_command_dock_508x379.png` est actuellement
**non suivi par git** et provient d'un chantier en cours. Il rend `_rootSnapshot`
(`player_battle_overlay_test.dart:199`), c'est-à-dire le menu racine et non la liste des attaques ;
il ne devrait donc pas être affecté. À confirmer au lot 4 plutôt qu'à supposer.

## Lots

| # | Lot | Contenu | Visible |
|---|---|---|---|
| 1 | `map_core` | `LocalizedNames.resolve` + `PokemonMove.displayName` + tests | non |
| 2 | Table & tool | Tool PokeAPI, extraction de la normalisation, table générée, rapport de matching | non |
| 3 | Producteurs | Converter et seed bootstrap enrichissent `names` | non |
| 4 | Runtime | Locale dans le menu model — les attaques passent en français en combat | **oui** |
| 5 | Éditeur | Affichage, recherche multi-champs, badge d'absence | **oui** |

Chaque lot est committable seul. Le lot 2 concentre le risque et le temps de revue.

L'ordre 4 avant 5 est délibéré : l'éditeur affiche la donnée produite au lot 3, autant l'avoir
vérifiée en jeu d'abord.

## Hors périmètre

- **La chrome de l'UI battle.** Les libellés `'CONTINUE'`, `'COMMANDS'` et
  `'Forced turn progression'` sont en dur dans `battle_command_menu_model.dart`. Même avec les
  attaques en français, l'habillage restera anglais. C'est un autre mécanisme (ARB) et un autre
  chantier ; les mélanger doublerait le lot.
- **Les noms d'objets, d'espèces et de talents.** Les items disposent déjà d'une map `names`
  alimentée par PokeAPI ; le même design leur serait applicable, mais ils ne sont pas demandés ici.
- **Toute UI de saisie de traduction**, écartée par la décision « lecture seule ».
- **Les descriptions d'attaques**, qui restent en anglais.

## Risques

**Trous de matching.** Des moves Showdown peuvent rester sans correspondance PokeAPI. Le rapport
émis par le tool les rend visibles en revue ; le badge éditeur les rend visibles à l'usage. Le
repli est l'anglais, jamais une chaîne vide. Le volume réel n'est pas connu avant la première
exécution du tool — c'est précisément ce que le lot 2 doit mesurer.

**Table figée.** Une nouvelle génération d'attaques n'apparaîtra en français qu'après régénération
de la table. Le comportement dégradé est l'anglais, ce qui est acceptable et cohérent avec le mode
de fonctionnement des autres artefacts générés du dépôt.

**Projets existants.** Un projet déjà synchronisé n'a pas de `names.fr` et devra relancer une
synchronisation moves. L'action existe déjà dans l'éditeur ; le badge et son compteur sont le
mécanisme par lequel l'auteur l'apprend.

**Perte d'une traduction manuelle.** Un `names.fr` écrit à la main dans le JSON d'un projet sera
écrasé au prochain sync moves, ce qui n'est pas le cas aujourd'hui. Le changement est assumé et
documenté ci-dessus, mais il constitue une modification de comportement observable pour quiconque
aurait déjà commencé à traduire à la main.

**Arbre de travail partagé.** Le chantier touche `battle_command_menu_model.dart` et
`battle_overlay_component.dart`, qui portent déjà des modifications non commitées d'un autre
chantier. Les commits doivent rester chirurgicaux, fichier par fichier.
