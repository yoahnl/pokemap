# BE6 mini-fix — Robustesse locale du contrat critique

## 1. Résumé exécutif honnête

Ce mini-fix corrige un vrai problème de code, pas seulement du wording.

Ce que j’ai réellement fait :

- j’ai durci le contrat public battle sur `critRatio` dans [packages/map_battle/lib/src/battle_move.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_move.dart) et [packages/map_battle/lib/src/battle_setup.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_setup.dart) ;
- j’ai supprimé la neutralisation silencieuse de `critRatio <= 0` dans [packages/map_battle/lib/src/battle_session.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart) ;
- j’ai aligné [packages/map_battle/lib/src/battle_rng.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_rng.dart) sur un vrai contrat runtime explicite pour `nextChance()` ;
- j’ai ajouté des tests battle ciblés pour verrouiller ces garanties dans [packages/map_battle/test/battle_session_test.dart](/Users/karim/Project/pokemonProject/packages/map_battle/test/battle_session_test.dart) et [packages/map_battle/test/battle_rng_test.dart](/Users/karim/Project/pokemonProject/packages/map_battle/test/battle_rng_test.dart) ;
- j’ai laissé le report historique BE6 intact et j’ai documenté honnêtement son incohérence de commande de format au lieu de le réécrire après coup.

Ce que je n’ai volontairement pas fait :

- je n’ai pas transformé BE6 en refonte du système critique ;
- je n’ai pas touché `map_runtime`, `map_core` ou `map_editor` ;
- je n’ai pas changé la table de crit BE6, ni les dégâts, ni le bridge runtime ;
- je n’ai pas “corrigé” le report historique BE6 pour maquiller l’historique.

Verdict court :

- oui, le diagnostic principal était réel ;
- oui, le fix est un vrai fix de robustesse de code ;
- non, le fail-fast “constructor throw” intégral n’était pas possible tel quel sans casser le contrat `const` existant, donc le bon compromis a été `assert` local + getter validé + garde moteur finale ;
- oui, l’incohérence de format dans le report BE6 historique était réelle, mais documentaire seulement.

## 2. Pré-gates exécutés + résultats

### Commandes exécutées avant modification

- `git status --short`
- `git diff --stat`
- `git ls-files --others --exclude-standard`
- `cd packages/map_battle && /opt/homebrew/bin/dart test`
- `cd packages/map_battle && /opt/homebrew/bin/dart analyze`

### Résultats honnêtes

Classification du pré-gate : vert.

- `git status --short` : aucune sortie
- `git diff --stat` : aucune sortie
- `git ls-files --others --exclude-standard` : aucune sortie
- `packages/map_battle` tests : vert
- `packages/map_battle` analyze : vert

J’ai ensuite exécuté aussi les validations runtime ciblées, même sans diff côté runtime, parce que le contrat public de `map_battle` est consommé par `map_runtime` et qu’un faux vert local aurait été trop facile.

## 3. État initial audité réel

Après lecture réelle des fichiers demandés, l’état initial était le suivant :

- [packages/map_battle/lib/src/battle_move.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_move.dart) transportait `critRatio`, mais sans vraie garde runtime locale au-delà du flux normal ;
- [packages/map_battle/lib/src/battle_setup.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_setup.dart) transportait aussi `critRatio`, mais avec la même faiblesse ;
- [packages/map_battle/lib/src/battle_session.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart) contenait `_critChanceForRatio(int critRatio)` avec un comportement silencieux `<= 1 -> neutre`, donc `0` et valeurs négatives étaient absorbées comme si elles étaient valides ;
- [packages/map_battle/lib/src/battle_rng.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_rng.dart) avait une asymétrie : `BattleScriptedRng.nextChance()` protégeait explicitement son contrat à l’exécution, mais `BattleSeededRng.nextChance()` ne le protégeait que par `assert` ;
- [reports/phase-battle-be6-crits-report.md](/Users/karim/Project/pokemonProject/reports/phase-battle-be6-crits-report.md) listait bien [packages/map_battle/lib/src/battle_move.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_move.dart) comme fichier modifié, mais sa commande finale de `dart format` oubliait ce fichier.

## 4. Problèmes confirmés / non confirmés

### Problèmes confirmés

1. Le diagnostic “`critRatio` invalide pouvait être neutralisé silencieusement” était réel.
   Le point exact était [packages/map_battle/lib/src/battle_session.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart), pas seulement les constructeurs.

2. Le diagnostic “`BattleSeededRng.nextChance()` était moins robuste que `BattleScriptedRng.nextChance()`” était réel.
   Les gardes runtime n’étaient pas symétriques.

3. Le diagnostic “incohérence possible de report BE6 sur le format” était réel.
   C’était une incohérence documentaire, pas un bug moteur.

### Points partiellement discutables

1. Le diagnostic “`BattleMoveData` et `BattleMove` doivent fail-fast explicitement au constructeur” était juste dans l’intention, mais trop strict dans la forme.
   Comme ces contrats restent `const`, un vrai `throw` runtime au constructeur n’était pas le plus petit compromis honnête sans casser inutilement l’API locale.

## 5. Cause racine réelle

La cause racine n’était pas un gros problème d’architecture.
C’était une dette de robustesse laissée par BE6 :

- le moteur consommait enfin `critRatio`, mais gardait encore une branche de compatibilité trop permissive ;
- les contrats publics battle restaient `const`, donc la validation locale n’était pas encore symétrique entre debug et runtime ;
- le seam RNG avait deux implémentations avec des niveaux de garde différents.

En clair : pas un problème de design global, un problème de fail-fast incomplet sur un contrat déjà ouvert.

## 6. Décisions retenues / rejetées

### Décisions retenues

- garder `BattleMoveData` et `BattleMove` `const` ;
- ajouter un `assert` local cohérent avec le style des constructeurs `const` ;
- ajouter un getter validé runtime sur `critRatio` dans les deux contrats publics ;
- garder une garde défensive finale dans `_critChanceForRatio()` ;
- durcir `BattleSeededRng.nextChance()` avec `StateError` pour l’aligner sur `BattleScriptedRng.nextChance()` ;
- ajouter un test dédié [packages/map_battle/test/battle_rng_test.dart](/Users/karim/Project/pokemonProject/packages/map_battle/test/battle_rng_test.dart) plutôt que disperser de petites preuves dans plusieurs fichiers.

### Décisions rejetées

- transformer les constructeurs `const` en constructeurs runtime non-`const` juste pour un mini-fix ;
- remplacer le compromis actuel par une nouvelle abstraction de validation ;
- toucher `map_runtime` “au cas où” ;
- modifier le report historique BE6 ;
- convertir la garde RNG en `ArgumentError` juste parce qu’on est dans une API publique.

### Choix du mécanisme d’erreur

Je n’ai pas choisi le mécanisme au hasard.

- `assert` dans [packages/map_battle/lib/src/battle_move.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_move.dart) et [packages/map_battle/lib/src/battle_setup.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_setup.dart) :
  c’est cohérent avec le style local des constructeurs `const`, et c’est le plus petit garde-fou immédiat en debug/test.
- `StateError` dans les getters validés et dans [packages/map_battle/lib/src/battle_rng.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_rng.dart) :
  c’est cohérent avec le style local du moteur quand un état battle incohérent a déjà franchi le contrat et est consommé à l’exécution.

Je n’ai pas utilisé `ArgumentError` parce qu’à ce stade on ne traite plus seulement une mauvaise saisie d’appelant : on protège un état moteur invalide déjà injecté dans le système.

## 7. Critique explicite du prompt reçu

### Ce qui était juste

- le prompt forçait un scope petit, ce qui était la bonne direction ;
- les deux trous de robustesse principaux étaient bien ciblés ;
- le point sur le report BE6 historique valait d’être audité honnêtement.

### Ce qui était discutable

- le prompt laissait entendre qu’un fail-fast purement local au constructeur était probablement suffisant ou attendu ;
- en pratique, avec des contrats `const`, ce n’était pas la bonne forme de correction la plus petite.

### Ce qui aurait été dangereux si suivi aveuglément

- casser le contrat `const` public juste pour obtenir un `throw` plus tôt ;
- surcorriger en touchant runtime ou le bridge alors que le bug était battle-local ;
- réécrire le report BE6 historique pour le rendre “plus propre” a posteriori.

### Ce que j’ai recadré

- j’ai gardé le lot strictement battle-local ;
- j’ai choisi un compromis de validation en trois couches :
  - `assert` constructeur ;
  - getter validé runtime ;
  - garde défensive moteur ;
- j’ai traité l’incohérence du report BE6 comme un fait historique documenté, pas comme quelque chose à éditer rétroactivement.

### Pourquoi ce recadrage est meilleur pour ce repo réel

Parce qu’il corrige le vrai bug sans casser des call sites `const`, sans propager une migration inutile, et sans rouvrir le chantier BE6 en refonte.

## 8. Périmètre inclus / exclu

### Inclus

- [packages/map_battle/lib/src/battle_move.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_move.dart)
- [packages/map_battle/lib/src/battle_setup.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_setup.dart)
- [packages/map_battle/lib/src/battle_session.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart)
- [packages/map_battle/lib/src/battle_rng.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_rng.dart)
- [packages/map_battle/test/battle_session_test.dart](/Users/karim/Project/pokemonProject/packages/map_battle/test/battle_session_test.dart)
- [packages/map_battle/test/battle_rng_test.dart](/Users/karim/Project/pokemonProject/packages/map_battle/test/battle_rng_test.dart)
- ce report

### Exclu

- `packages/map_runtime`
- `packages/map_core`
- `packages/map_editor`
- bridge runtime
- type chart
- dégâts
- accuracy
- STAB
- immunités
- tout lot BE7+

## 9. Liste exacte des fichiers modifiés / créés / supprimés

### Modifiés

- [packages/map_battle/lib/src/battle_move.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_move.dart)
- [packages/map_battle/lib/src/battle_setup.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_setup.dart)
- [packages/map_battle/lib/src/battle_rng.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_rng.dart)
- [packages/map_battle/lib/src/battle_session.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart)
- [packages/map_battle/test/battle_session_test.dart](/Users/karim/Project/pokemonProject/packages/map_battle/test/battle_session_test.dart)

### Créés

- [packages/map_battle/test/battle_rng_test.dart](/Users/karim/Project/pokemonProject/packages/map_battle/test/battle_rng_test.dart)
- [reports/phase-battle-be6-mini-fix-report.md](/Users/karim/Project/pokemonProject/reports/phase-battle-be6-mini-fix-report.md)

### Supprimés

- aucun

## 10. Justification fichier par fichier

- [packages/map_battle/lib/src/battle_move.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_move.dart)
  - ajout d’un garde local `assert` et d’un getter runtime validé sur `critRatio`
  - commentaire de conception sur le compromis `const`

- [packages/map_battle/lib/src/battle_setup.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_setup.dart)
  - même durcissement que `BattleMoveData`, pour que le contrat de setup ne soit pas plus permissif que le contrat de session

- [packages/map_battle/lib/src/battle_rng.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_rng.dart)
  - alignement de `BattleSeededRng.nextChance()` sur des gardes runtime explicites

- [packages/map_battle/lib/src/battle_session.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart)
  - suppression de la neutralisation silencieuse de `critRatio <= 0`
  - commentaire explicite sur la raison du `StateError`

- [packages/map_battle/test/battle_session_test.dart](/Users/karim/Project/pokemonProject/packages/map_battle/test/battle_session_test.dart)
  - preuve du garde local debug
  - preuve du rejet runtime setup -> session
  - preuve du rejet moteur avant résolution silencieuse du crit

- [packages/map_battle/test/battle_rng_test.dart](/Users/karim/Project/pokemonProject/packages/map_battle/test/battle_rng_test.dart)
  - tests dédiés au contrat `nextChance()`

- [reports/phase-battle-be6-mini-fix-report.md](/Users/karim/Project/pokemonProject/reports/phase-battle-be6-mini-fix-report.md)
  - traçabilité complète du mini-fix

## 11. Commandes réellement exécutées

### Pré-gates

- `git status --short`
- `git diff --stat`
- `git ls-files --others --exclude-standard`
- `cd packages/map_battle && /opt/homebrew/bin/dart test`
- `cd packages/map_battle && /opt/homebrew/bin/dart analyze`

### Audit ciblé

- lecture réelle de :
  - [packages/map_battle/lib/src/battle_move.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_move.dart)
  - [packages/map_battle/lib/src/battle_setup.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_setup.dart)
  - [packages/map_battle/lib/src/battle_rng.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_rng.dart)
  - [packages/map_battle/lib/src/battle_session.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart)
  - [packages/map_battle/test/battle_session_test.dart](/Users/karim/Project/pokemonProject/packages/map_battle/test/battle_session_test.dart)
  - [packages/map_battle/test/battle_move_effects_test.dart](/Users/karim/Project/pokemonProject/packages/map_battle/test/battle_move_effects_test.dart)
  - [reports/phase-battle-be6-crits-report.md](/Users/karim/Project/pokemonProject/reports/phase-battle-be6-crits-report.md)

### Validation ciblée intermédiaire

- `cd packages/map_battle && /opt/homebrew/bin/dart test test/battle_rng_test.dart test/battle_session_test.dart`

### Format final

- `cd packages/map_battle && /opt/homebrew/bin/dart format lib/src/battle_move.dart lib/src/battle_setup.dart lib/src/battle_rng.dart lib/src/battle_session.dart test/battle_session_test.dart test/battle_rng_test.dart`

### Validation finale battle

- `cd packages/map_battle && /opt/homebrew/bin/dart analyze`
- `cd packages/map_battle && /opt/homebrew/bin/dart test`

### Validation runtime ciblée par prudence contractuelle

- `cd packages/map_runtime && /opt/homebrew/bin/flutter test test/runtime_move_catalog_loader_test.dart test/runtime_pokemon_species_loader_test.dart test/runtime_pokemon_learnset_loader_test.dart test/runtime_battle_move_bridge_test.dart test/runtime_battle_combatant_seed_builder_test.dart test/runtime_battle_setup_mapper_test.dart test/runtime_battle_outcome_apply_test.dart test/wild_battle_end_to_end_flow_test.dart test/playable_map_game_whiteout_lite_test.dart`
- `cd packages/map_runtime && /opt/homebrew/bin/flutter analyze --no-pub lib/src/application/runtime_battle_move_bridge.dart lib/src/application/runtime_battle_combatant_seed_builder.dart lib/src/application/runtime_battle_setup_mapper.dart lib/src/application/runtime_pokemon_species_loader.dart test/runtime_battle_move_bridge_test.dart test/runtime_battle_combatant_seed_builder_test.dart test/runtime_battle_setup_mapper_test.dart test/runtime_move_catalog_loader_test.dart test/runtime_pokemon_species_loader_test.dart test/runtime_pokemon_learnset_loader_test.dart test/runtime_battle_outcome_apply_test.dart test/wild_battle_end_to_end_flow_test.dart test/playable_map_game_whiteout_lite_test.dart`

## 12. Résultats réels de format / analyze / tests

### Format

- `dart format` sur `map_battle` : `Formatted 6 files (0 changed) in 0.02 seconds.`

### Analyze

- `packages/map_battle` : `No issues found!`
- `packages/map_runtime` analyze ciblé : `No issues found! (ran in 2.0s)`

### Tests

- `packages/map_battle` ciblé (`battle_rng_test.dart` + `battle_session_test.dart`) : vert
- `packages/map_battle` full suite : `All tests passed!`
- `packages/map_runtime` suite ciblée Pokémon : `All tests passed!`

## 13. Incidents rencontrés

- Aucun incident de compilation bloquant.
- Le pré-gate runtime n’a pas été exécuté avant modification ; il a été exécuté ensuite par prudence contractuelle, puis relancé en validation finale. Je le documente comme un écart de process réel, pas comme un pré-gate fictif.
- Un point de conception important a dû être recadré : le fail-fast constructeur pur en release n’était pas compatible avec le maintien honnête des contrats `const`.
- L’incohérence du report BE6 sur `dart format` a été confirmée.
- Je n’ai pas touché le report BE6 historique. C’est volontaire.
- Deux relances d’audit/design ont expiré sans payload exploitable. Le reviewer séparé, lui, a bien répondu.

## 14. État git utile

### Pré-gate initial

- `git status --short` : aucune sortie
- `git diff --stat` : aucune sortie
- `git ls-files --others --exclude-standard` : aucune sortie

### État final

- `git status --short`
  - ` M packages/map_battle/lib/src/battle_move.dart`
  - ` M packages/map_battle/lib/src/battle_rng.dart`
  - ` M packages/map_battle/lib/src/battle_session.dart`
  - ` M packages/map_battle/lib/src/battle_setup.dart`
  - ` M packages/map_battle/test/battle_session_test.dart`
  - `?? packages/map_battle/test/battle_rng_test.dart`
  - `?? reports/phase-battle-be6-mini-fix-report.md`
- `git diff --stat`
  - `packages/map_battle/lib/src/battle_move.dart      |  26 ++++-`
  - `packages/map_battle/lib/src/battle_rng.dart       |  14 ++-`
  - `packages/map_battle/lib/src/battle_session.dart   |  15 ++-`
  - `packages/map_battle/lib/src/battle_setup.dart     |  28 ++++-`
  - `packages/map_battle/test/battle_session_test.dart | 135 ++++++++++++++++++++++`
  - `5 files changed, 208 insertions(+), 10 deletions(-)`
- `git ls-files --others --exclude-standard`
  - `packages/map_battle/test/battle_rng_test.dart`
  - `reports/phase-battle-be6-mini-fix-report.md`

## 15. Checklist finale

- [x] j’ai audité le code réel avant de coder
- [x] je n’ai pas accepté le diagnostic aveuglément
- [x] j’ai corrigé un vrai trou de robustesse confirmé
- [x] je n’ai pas élargi le scope à BE7+
- [x] je n’ai pas touché `map_core`
- [x] je n’ai pas touché `map_editor`
- [x] je n’ai créé aucune stack parallèle
- [x] j’ai ajouté des tests ciblés utiles
- [x] j’ai exécuté format
- [x] j’ai exécuté analyze
- [x] j’ai exécuté les tests utiles
- [x] je n’ai fait aucune écriture Git interdite
- [x] le report explique précisément ce que j’ai fait
- [x] le report explique précisément ce que je n’ai pas fait

## 16. Retour du sub-agent d’audit/design

Sub-agent utilisé : `019d91c7-acbc-7cf2-bc96-2d00638f8841`

Retour utile retenu :

- les trois points du diagnostic étaient réels, mais le point “fail-fast au constructeur” devait être recadré à cause du contrat `const` ;
- le plus petit compromis honnête était :
  - `assert` constructeur ;
  - getter runtime validé ;
  - garde finale dans `_critChanceForRatio()` ;
- le point report BE6 sur `dart format` était bien une incohérence documentaire réelle.

Ce retour a été intégré.

Relances supplémentaires :

- `019d95ca-a7b4-7f81-ae97-d22f9a9e7eae` a ensuite confirmé le même diagnostic après implémentation ;
- `019d95ce-8dc5-7691-8a27-cc5b34447c66` a expiré sans payload exploitable ;
- une autre relance d’audit/design a également expiré sans payload exploitable.

## 17. Retour du reviewer séparé

Reviewer utilisé : `019d95cb-6880-7bf3-99c7-93042ef5daf0`

Retour exploitable :

- aucun finding sérieux ;
- le reviewer a explicitement validé :
  - la stratégie `assert` + getter validé + garde finale comme plus petit compromis honnête ;
  - l’alignement `BattleSeededRng` / `BattleScriptedRng` ;
  - le fait que le diff reste borné.

Point résiduel signalé mais non classé en finding :

- un vrai “throw immédiat” au constructeur reste impossible hors debug tant que les contrats doivent rester `const`.

## 18. Corrections appliquées après review

- aucune correction de code supplémentaire n’a été nécessaire après la review séparée ;
- j’ai seulement conservé explicitement dans ce report la limite assumée sur les constructeurs `const`, parce que le reviewer a eu raison de la pointer comme contrainte réelle du compromis.

## 19. Autocritique finale

Ce mini-fix est propre et honnête, mais il reste une limite assumée :

- le fail-fast absolu au moment exact de l’instanciation n’existe pas en release pour un contrat `const` Dart si on ne veut pas casser l’API ;
- le compromis retenu est solide pour ce repo, mais il n’est pas “magique” ;
- si un jour le package veut un contrat plus dur que ça, ce ne sera plus un mini-fix, ce sera une décision API plus large.

Ce qui est solide :

- la neutralisation silencieuse de `critRatio <= 0` a bien disparu ;
- le RNG seedé protège maintenant son contrat à l’exécution ;
- les tests couvrent les vrais trous de robustesse ;
- le scope est resté strictement local.

Ce que je n’ai pas essayé de faire :

- rendre l’historique BE6 “plus beau” en réécrivant son report ;
- ouvrir runtime ;
- élargir le sujet aux tables de crit ou aux dégâts.

## 20. Annexe avec le contenu complet de tous les fichiers texte touchés

Le report s’exclut lui-même de cette annexe pour éviter une récursion infinie.

### [packages/map_battle/lib/src/battle_move.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_move.dart)

```dart
/// Catégorie battle minimale d'une attaque.
///
/// M8 puis BE5 n'ouvrent toujours pas un système de typing complet, mais le
/// bridge runtime -> battle doit au moins distinguer :
/// - les attaques physiques ;
/// - les attaques spéciales ;
/// - les attaques de statut.
///
/// Cette information suffit pour donner un vrai effet battle au petit
/// sous-ensemble `modifyStats` retenu dans ce lot.
enum BattleMoveCategory {
  physical,
  special,
  status,
}

/// Cible battle minimale explicitement transportée par le bridge runtime.
///
/// BE1 ne crée pas un système de ciblage complet façon Showdown.
/// On transporte seulement ce qui est déjà honnête dans le moteur actuel :
/// - `self` pour les moves explicitement auto-ciblés ;
/// - `opponent` pour les moves qui, en 1v1 simple actif, ciblent l'adversaire ;
/// - `unspecified` comme compatibilité pour les anciens call sites/tests qui
///   construisaient encore des `BattleMoveData` pauvres à la main.
///
/// Important :
/// - `unspecified` n'est pas une nouvelle sémantique battle ;
/// - c'est un garde-fou de compatibilité pour éviter d'inventer une cible
///   mensongère sur les anciens setups locaux ;
/// - le bridge runtime BE1, lui, doit toujours fournir une cible explicite.
enum BattleMoveTarget {
  unspecified,
  opponent,
  self,
}

/// Contrat minimal de précision réellement exécutable par `map_battle`.
///
/// BE4 n'importe pas `PokemonMoveAccuracy` depuis `map_core` :
/// - `map_battle` doit rester pur et indépendant du modèle projet ;
/// - le bridge runtime traduit donc vers ce petit contrat local ;
/// - on ne transporte que ce que le moteur sait réellement consommer.
///
/// Frontière volontaire :
/// - `alwaysHits` pour les moves qui bypassent le hit check ;
/// - `percent` pour un pourcentage entier simple ;
/// - pas d'evasion/accuracy stages ;
/// - pas d'autres variantes exotériques.
///
/// Note BE4 :
/// - `percent(100)` reste distinct de `alwaysHits` dans la donnée transportée ;
/// - mais le moteur actuel le résout quand même de façon déterministe, faute
///   de modificateurs accuracy/evasion dans ce lot.
enum BattleMoveAccuracyKind {
  alwaysHits,
  percent,
}

/// Représentation battle minimale de la précision.
///
/// Décision de BE4 :
/// - ce type vit au plus près de `BattleMove` parce qu'il n'a de sens que
///   pour le contrat move battle ;
/// - il reste petit, explicite et testable ;
/// - il n'ouvre ni une taxonomie canonique parallèle, ni une logique moteur
///   générique hors de proportion.
class BattleMoveAccuracy {
  const BattleMoveAccuracy.alwaysHits()
      : kind = BattleMoveAccuracyKind.alwaysHits,
        value = 100;

  const BattleMoveAccuracy.percent({
    required this.value,
  })  : assert(value >= 1 && value <= 100),
        kind = BattleMoveAccuracyKind.percent;

  final BattleMoveAccuracyKind kind;
  final int value;

  bool get isAlwaysHits => kind == BattleMoveAccuracyKind.alwaysHits;
}

/// Identifiant de stat exploitable par le moteur battle MVP enrichi.
///
/// Décision volontairement bornée pour M8 puis BE3 :
/// - on ne porte que les stats déjà utiles à un effet battle réel ;
/// - BE3 ouvre `speed` parce qu'elle devient enfin consommée pour l'ordre
///   d'action minimal honnête ;
/// - on n'ouvre toujours pas accuracy / evasion, car cela rouvrirait la
///   précision réelle et d'autres mécaniques hors scope ;
/// - le bridge runtime continue donc de refuser explicitement ces autres cas.
enum BattleStatId {
  attack,
  defense,
  specialAttack,
  specialDefense,
  speed,
}

/// Changement d'étage de stat appliqué pendant le combat.
///
/// Ce type est petit mais typé :
/// - il évite de faire circuler des `Map<String, int>` peu robustes ;
/// - il garde `BattleMoveData` et `BattleMove` lisibles ;
/// - il permet au moteur MVP d'appliquer un vrai effet non-dégât.
class BattleStatStageChange {
  const BattleStatStageChange({
    required this.stat,
    required this.stages,
  });

  final BattleStatId stat;
  final int stages;
}

/// Attaque utilisée pendant un combat.
///
/// Ce modèle représente une attaque disponible pour un combattant.
/// Il est utilisé pendant le combat, contrairement à [BattleMoveData]
/// qui est utilisé uniquement pour la configuration initiale.
class BattleMove {
  /// Crée une attaque.
  ///
  /// [id] - L'identifiant canonique de l'attaque.
  /// [name] - Le nom affiché de l'attaque.
  /// [power] - La puissance de l'attaque (dégâts de base).
  /// [type] - Le type canonique transporté et désormais consommé pour STAB /
  ///   type chart dans le petit sous-ensemble honnête BE5.
  /// [category] - La catégorie battle minimale déjà résolue par le runtime.
  /// [target] - La cible battle minimale résolue par le bridge runtime.
  /// [accuracy] - La précision minimale réellement consommée par BE4.
  /// [pp] - Le PP max du move.
  /// [currentPp] - Le PP courant dans l'état battle.
  /// [priority] - Priorité canonique réellement consommée par BE3 pour
  ///   l'ordre d'action 1v1 minimal.
  /// [critRatio] - Ratio critique minimal désormais consommé par BE6.
  /// [selfStatStageChanges] - Boosts / baisses appliqués au lanceur.
  /// [targetStatStageChanges] - Boosts / baisses appliqués à la cible.
  ///
  /// M8 puis BE1 choisissent volontairement de n'embarquer ici qu'un petit
  /// sous-ensemble :
  /// - dégâts standards ;
  /// - modifications déterministes de stats ;
  /// - transport honnête de quelques dimensions structurantes (`type`,
  ///   `target`, `pp`) pour arrêter leur perte silencieuse au handoff ;
  /// - puis, en BE3, transport et consommation réelle de `priority` pour
  ///   sortir du mensonge "joueur puis ennemi" ;
  /// - puis, en BE4, un vrai hit pipeline minimal avec précision et PP ;
  /// - puis, en BE6, un crit minimal honnête via `critRatio` ;
  /// - toujours aucun status non volatil, aucun scheduler générique.
  const BattleMove({
    required this.id,
    required this.name,
    required this.power,
    this.type = 'unknown',
    this.category,
    this.target = BattleMoveTarget.unspecified,
    this.accuracy = const BattleMoveAccuracy.percent(value: 100),
    this.pp = 35,
    int? currentPp,
    this.priority = 0,
    int critRatio = 1,
    this.selfStatStageChanges = const <BattleStatStageChange>[],
    this.targetStatStageChanges = const <BattleStatStageChange>[],
  })  : assert(
          critRatio >= 1,
          'BattleMove critRatio must be >= 1.',
        ),
        _critRatio = critRatio,
        currentPp = currentPp ?? pp;

  /// L'identifiant canonique de l'attaque.
  final String id;

  /// Le nom affiché de l'attaque.
  final String name;

  /// La puissance de l'attaque (dégâts de base).
  ///
  /// Pour ce MVP enrichi :
  /// - les dégâts standards partent toujours de `power` ;
  /// - des multiplicateurs d'étages de stats peuvent maintenant s'ajouter ;
  /// - un move de statut garde généralement `power == 0`.
  final int power;

  /// Type canonique transporté jusqu'au moteur battle.
  ///
  /// Historique utile :
  /// - BE1 arrête d'abord sa perte silencieuse au bridge ;
  /// - BE5 commence ensuite à le consommer réellement pour STAB,
  ///   effectiveness et immunités ;
  /// - on reste malgré tout très loin d'un système de type Pokémon complet
  ///   (pas d'abilities, pas de Tera, pas d'effets spéciaux de move).
  final String type;

  /// Catégorie battle explicitement résolue par le bridge runtime.
  ///
  /// Compatibilité ascendante :
  /// - les anciens tests/call sites n'avaient que `power` ;
  /// - on garde donc ce champ optionnel ;
  /// - si absent, on déduit une catégorie minimale historique.
  final BattleMoveCategory? category;

  /// Cible battle minimale transportée jusqu'au moteur.
  ///
  /// Le moteur MVP ne l'exécute pas encore activement dans sa résolution :
  /// - le combat reste 1v1 simple actif ;
  /// - mais BE1 arrête au moins de perdre cette information au handoff ;
  /// - les targets incompatibles avec ce petit contrat sont refusés plus tôt
  ///   par le bridge runtime.
  final BattleMoveTarget target;

  /// Précision réellement consommée par le moteur battle.
  ///
  /// BE4 garde ici un contrat petit mais honnête :
  /// - `alwaysHits` bypasse le hit check ;
  /// - `percent` déclenche un check simple sur 1..100 pour les valeurs
  ///   réellement non triviales ;
  /// - `percent(100)` reste déterministe dans le moteur actuel, car BE4
  ///   n'ouvre toujours ni accuracy stages, ni evasion ;
  /// - pas d'autres couches de précision, pas d'evasion, pas de modificateurs.
  final BattleMoveAccuracy accuracy;

  /// PP maximum du move dans l'état battle.
  ///
  /// `pp` reste le contrat de capacité max du move.
  /// L'état courant vit dans [currentPp].
  ///
  /// Compatibilité volontairement bornée :
  /// - le runtime principal fournit déjà le PP canonique réel ;
  /// - les anciens call sites battle directs omettaient souvent ce champ ;
  /// - on garde donc un défaut pragmatique à 35 pour ne pas transformer BE4
  ///   en migration parasite de tous les setups battle locaux.
  final int pp;

  /// PP courant du move dans l'état battle.
  ///
  /// BE4 ouvre enfin cette donnée parce que :
  /// - les PP cessent d'être décoratifs ;
  /// - le moteur doit pouvoir filtrer les moves inutilisables ;
  /// - un miss consomme quand même 1 PP de façon honnête.
  final int currentPp;

  /// Priorité battle minimale du move.
  ///
  /// BE3 consomme enfin cette donnée pour fermer le trou :
  /// - priorité d'abord ;
  /// - puis vitesse effective ;
  /// - puis tie-break déterministe explicite.
  ///
  /// On garde un défaut à `0` pour préserver les anciens call sites/tests qui
  /// construisent encore des moves battle pauvres à la main.
  final int priority;

  /// Ratio critique minimal transporté jusqu'au moteur battle.
  ///
  /// BE6 choisit ici le plus petit contrat utile :
  /// - on transporte l'entier canonique déjà présent côté runtime ;
  /// - le moteur l'interprète via une table explicite de chances ;
  /// - on n'ouvre pas pour autant les règles Pokémon avancées liées aux crits
  ///   (abilities, items, Focus Energy, Lucky Chant, ignore stages, etc.).
  ///
  /// Valeur neutre :
  /// - `1` signifie le ratio critique standard.
  ///
  /// Garde-fou de mini-fix BE6 :
  /// - ce contrat public reste `const`, donc le garde-fou local le plus petit
  ///   et le plus cohérent ici reste une assertion ;
  /// - on ajoute quand même aussi une validation runtime au getter, parce
  ///   qu'un objet battle malformé peut encore contourner les assertions hors
  ///   debug ;
  /// - le moteur garde enfin une dernière validation défensive plus loin.
  final int _critRatio;

  int get critRatio {
    if (_critRatio < 1) {
      throw StateError('BattleMove critRatio must be >= 1; got $_critRatio.');
    }
    return _critRatio;
  }

  /// Changements d'étages de stats appliqués au lanceur.
  final List<BattleStatStageChange> selfStatStageChanges;

  /// Changements d'étages de stats appliqués à la cible.
  final List<BattleStatStageChange> targetStatStageChanges;

  /// true si le move peut encore être tenté honnêtement.
  ///
  /// BE4 n'ouvre toujours pas Struggle :
  /// - un move à `currentPp == 0` n'est donc plus utilisable ;
  /// - `getAvailableChoices()` doit le filtrer ;
  /// - un forçage direct du moteur doit être refusé explicitement.
  bool get hasUsablePp => currentPp > 0;

  /// Catégorie réellement utilisée par le moteur.
  ///
  /// Le bridge runtime fournit maintenant cette info explicitement, mais ce
  /// getter garde une compatibilité honnête avec les anciens setups pauvres :
  /// - `power <= 0` => move de statut ;
  /// - sinon, fallback historique sur "physical".
  BattleMoveCategory get resolvedCategory {
    if (category != null) {
      return category!;
    }
    if (power <= 0) {
      return BattleMoveCategory.status;
    }
    return BattleMoveCategory.physical;
  }

  /// Retourne une copie avec 1 PP consommé.
  ///
  /// Le décrément reste local au move, ce qui évite de réinventer un
  /// conteneur battle parallèle juste pour les PP.
  BattleMove withConsumedPp() {
    return BattleMove(
      id: id,
      name: name,
      power: power,
      type: type,
      category: category,
      target: target,
      accuracy: accuracy,
      pp: pp,
      currentPp: currentPp > 0 ? currentPp - 1 : 0,
      priority: priority,
      critRatio: critRatio,
      selfStatStageChanges: selfStatStageChanges,
      targetStatStageChanges: targetStatStageChanges,
    );
  }
}
```

### [packages/map_battle/lib/src/battle_setup.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_setup.dart)

```dart
import 'battle_move.dart';
import 'battle_stats.dart';
import 'battle_typing.dart';

/// Configuration initiale d'un combat.
///
/// Modèle pur, sans dépendance runtime.
/// Construit depuis [BattleStartRequest] par le runtime via un mapper dédié.
///
/// Ce modèle contient uniquement les données nécessaires au moteur de combat,
/// sans aucune référence à l'orchestration runtime (OverworldReturnContext, etc.).
class BattleSetup {
  /// Crée une configuration de combat.
  ///
  /// [playerPokemon] - Le Pokémon du joueur qui combat.
  /// [enemyPokemon] - Le Pokémon adverse qui combat.
  /// [isTrainerBattle] - true si c'est un combat contre un dresseur.
  /// [trainerId] - L'identifiant du dresseur (non-null si [isTrainerBattle] est true).
  /// [allowCapture] - true si le runtime autorise explicitement la capture
  ///   pour ce combat. Le lot 13 l'utilise uniquement pour les rencontres
  ///   sauvages quand la party a encore de la place.
  const BattleSetup({
    required this.playerPokemon,
    required this.enemyPokemon,
    required this.isTrainerBattle,
    required this.trainerId,
    this.allowCapture = false,
  });

  /// Le Pokémon du joueur qui combat.
  final BattleCombatantData playerPokemon;

  /// Le Pokémon adverse qui combat.
  final BattleCombatantData enemyPokemon;

  /// true si c'est un combat contre un dresseur.
  ///
  /// Si false, c'est une rencontre sauvage (wild battle).
  final bool isTrainerBattle;

  /// L'identifiant du dresseur.
  ///
  /// Non-null si [isTrainerBattle] est true.
  /// Utilisé par le runtime pour marquer `trainer_defeated:{trainerId}` après victoire.
  final String? trainerId;

  /// true si l'action Capture doit être exposée au joueur.
  ///
  /// Invariants métier lot 13 :
  /// - jamais en combat trainer ;
  /// - seulement si le runtime sait qu'une capture réussie peut être écrite
  ///   proprement dans l'état joueur ;
  /// - on évite ainsi toute promesse mensongère quand la party est pleine.
  final bool allowCapture;
}

/// Données minimales d'un combattant pour initialiser un combat.
///
/// Ce modèle est utilisé uniquement pour la configuration initiale.
/// Une fois le combat démarré, [BattleCombatant] est utilisé à la place.
class BattleCombatantData {
  /// Crée les données d'un combattant.
  ///
  /// [speciesId] - L'identifiant de l'espèce (ex: "pikachu", "lapras").
  /// [level] - Le niveau du combattant.
  /// [maxHp] - Les points de vie maximum.
  /// [currentHp] - Les PV courants si le runtime les connaît déjà.
  /// [stats] - Snapshot résolu des stats non-HP réellement exploitées par le
  /// moteur battle.
  /// [typing] - Typing défensif/offensif minimal du combattant si connu.
  /// [abilityId] - L'ability réellement résolue si le runtime la connaît.
  ///
  /// Le lot 9 du runtime -> battle handoff doit partir de la vraie party du
  /// joueur. On ajoute donc ce champ optionnel au setup pour éviter de soigner
  /// implicitement le Pokémon actif lors de l'ouverture du combat.
  /// [moves] - La liste des attaques disponibles (4 max).
  const BattleCombatantData({
    required this.speciesId,
    required this.level,
    required this.maxHp,
    required this.stats,
    this.typing,
    this.currentHp,
    this.abilityId = 'unknown',
    required this.moves,
  });

  /// L'identifiant de l'espèce (ex: "pikachu", "lapras").
  final String speciesId;

  /// Le niveau du combattant.
  final int level;

  /// Les points de vie maximum.
  final int maxHp;

  /// Snapshot résolu des stats non-HP pour ce combattant.
  ///
  /// BE2 choisit un vrai contrat typé ici pour deux raisons :
  /// - le moteur ne doit plus inventer implicitement des valeurs offensives /
  ///   défensives à partir de rien ;
  /// - le runtime est la bonne frontière pour résoudre ces stats à partir des
  ///   species data, du niveau et des IV/EV disponibles.
  ///
  /// `speed` est déjà transportée pour arrêter sa perte silencieuse, même si
  /// elle est maintenant consommée pour l'ordre d'action honnête minimal.
  final BattleStatsSnapshot stats;

  /// Typing minimal du combattant si le handoff le connaît déjà.
  ///
  /// BE5 choisit ici une compatibilité volontairement bornée :
  /// - le vrai chemin runtime -> battle doit fournir cette donnée ;
  /// - les anciens call sites directs de `map_battle` peuvent encore l'omettre
  ///   pour éviter une migration parasite de tout le package ;
  /// - en l'absence de typing, le moteur reste neutre sur STAB/effectiveness
  ///   au lieu d'inventer un type mensonger.
  final BattleTypingSnapshot? typing;

  /// Les points de vie courants si le handoff runtime les fournit déjà.
  ///
  /// Si null, le moteur démarre le combat à pleine vie, ce qui conserve le
  /// comportement historique des tests et call sites qui n'ont pas besoin de
  /// porter cet état.
  final int? currentHp;

  /// L'ability réellement résolue si le runtime la connaît déjà.
  ///
  /// Le moteur de combat MVP n'utilise pas encore cette donnée pour ses
  /// calculs, mais le lot 13 en a besoin pour construire un Pokémon capturé
  /// sans réinventer un deuxième format intermédiaire.
  final String abilityId;

  /// La liste des attaques disponibles.
  final List<BattleMoveData> moves;
}

/// Données minimales d'une attaque pour initialiser un combat.
///
/// Ce modèle est utilisé uniquement pour la configuration initiale.
/// Une fois le combat démarré, [BattleMove] est utilisé à la place.
class BattleMoveData {
  /// Crée les données d'une attaque.
  ///
  /// [id] - L'identifiant canonique de l'attaque.
  /// [name] - Le nom affiché de l'attaque.
  /// [power] - La puissance de l'attaque (dégâts de base).
  /// [type] - Le type canonique transporté puis consommé pour la couche type
  ///   minimale ouverte en BE5.
  /// [category] - La catégorie battle minimale déjà résolue par le runtime.
  /// [target] - La cible battle minimale résolue par le bridge runtime.
  /// [accuracy] - La précision battle minimale réellement consommée par BE4.
  /// [pp] - Le PP max transporté vers le moteur.
  /// [currentPp] - Le PP courant initial si un call site battle direct veut
  ///   forcer un état de combat déjà entamé.
  /// [priority] - Priorité canonique transportée et consommée par BE3 pour
  ///   l'ordre d'action minimal honnête.
  /// [critRatio] - Ratio critique minimal transporté et consommé par BE6.
  /// [selfStatStageChanges] - Boosts / baisses appliqués au lanceur.
  /// [targetStatStageChanges] - Boosts / baisses appliqués à la cible.
  ///
  /// Ce contrat reste volontairement petit :
  /// - il ne copie pas `PokemonMove` ;
  /// - il ne prétend pas transporter tous les `effects` canoniques ;
  /// - mais BE1 y ajoute aussi quelques dimensions battle fondamentales
  ///   (`type`, `target`, `pp`) pour arrêter leur perte silencieuse ;
  /// - puis BE3 et BE4 commencent à consommer réellement `priority`,
  ///   `speed`, `accuracy` et les PP ;
  /// - puis BE6 ouvre enfin un crit minimal honnête via `critRatio` ;
  /// - le reste reste explicitement hors scope.
  const BattleMoveData({
    required this.id,
    required this.name,
    required this.power,
    this.type = 'unknown',
    this.category,
    this.target = BattleMoveTarget.unspecified,
    this.accuracy = const BattleMoveAccuracy.percent(value: 100),
    this.pp = 35,
    this.currentPp,
    this.priority = 0,
    int critRatio = 1,
    this.selfStatStageChanges = const <BattleStatStageChange>[],
    this.targetStatStageChanges = const <BattleStatStageChange>[],
  })  : assert(
          critRatio >= 1,
          'BattleMoveData critRatio must be >= 1.',
        ),
        _critRatio = critRatio;

  /// L'identifiant canonique de l'attaque.
  final String id;

  /// Le nom affiché de l'attaque.
  final String name;

  /// La puissance de l'attaque (dégâts de base).
  ///
  /// Depuis BE2, cette donnée n'est plus utilisée seule :
  /// - `power` reste bien la base du damage contract ;
  /// - mais le moteur la combine maintenant avec les vraies stats résolues
  ///   du combattant et de sa cible ;
  /// - un move de statut garde `power <= 0` et inflige donc 0 dégât.
  final int power;

  /// Type canonique du move.
  ///
  /// Donnée transportée dès BE1 pour éviter sa perte silencieuse au handoff.
  ///
  /// BE5 commence enfin à la consommer réellement pour :
  /// - le STAB ;
  /// - l'efficacité de type ;
  /// - les immunités.
  ///
  /// Les anciens call sites directs peuvent encore garder la valeur par défaut
  /// `"unknown"` : dans ce cas, le moteur reste neutre au lieu de prétendre
  /// connaître un type qu'il n'a pas.
  final String type;

  /// Catégorie battle explicitement résolue par le bridge runtime.
  ///
  /// Ce champ est optionnel pour préserver les anciens call sites/tests qui ne
  /// transportaient encore que `power`.
  final BattleMoveCategory? category;

  /// Cible battle minimale résolue par le bridge runtime.
  ///
  /// Le moteur n'en tire pas encore une logique complète de targeting, mais le
  /// handoff ne doit plus jeter cette information quand elle reste simple et
  /// honnête dans le cadre 1v1 actuel.
  final BattleMoveTarget target;

  /// Contrat minimal de précision battle.
  ///
  /// BE4 ouvre enfin un vrai hit pipeline honnête :
  /// - le moteur n'a plus besoin que le runtime neutralise l'accuracy ;
  /// - `alwaysHits` et `percent` suffisent pour le sous-ensemble supporté ;
  /// - le reste des mécaniques de précision reste hors scope.
  final BattleMoveAccuracy accuracy;

  /// PP maximum du move.
  ///
  /// `BattleMoveData` reste un contrat de setup :
  /// - `pp` décrit la capacité max du move ;
  /// - `currentPp`, si fourni, permet seulement d'initialiser un état battle
  ///   déjà entamé ;
  /// - sinon, le moteur démarre à pleine valeur.
  ///
  /// Compatibilité volontairement bornée :
  /// - le chemin runtime -> battle fournit déjà le PP canonique réel ;
  /// - les anciens call sites `map_battle` directs n'avaient souvent aucun PP
  ///   explicite et supposaient juste "move utilisable" ;
  /// - on garde donc un défaut pragmatique à 35 pour ne pas transformer BE4
  ///   en migration massive hors scope ;
  /// - ce défaut n'est pas une vérité Pokédex : c'est un garde-fou de
  ///   compatibilité pour les setups battle locaux, documenté comme tel.
  final int pp;

  /// Valeur courante de PP au démarrage de la session si connue.
  ///
  /// Le runtime principal n'en a pas besoin aujourd'hui :
  /// - les combats commencent encore avec tous les PP pleins ;
  /// - la write-back des PP reste hors scope.
  ///
  /// En revanche, ce champ rend le contrat battle direct plus honnête et
  /// simplifie les tests ciblés de BE4 sans bricoler l'état après coup.
  final int? currentPp;

  /// Priorité battle minimale du move.
  ///
  /// BE1 refusait encore `priority != 0` parce que le moteur résolvait
  /// toujours "joueur puis ennemi". BE3 ouvre enfin ce champ :
  /// - il est transporté dès le setup ;
  /// - il est consommé ensuite par `BattleSession` pour l'ordre du tour ;
  /// - mais il ne crée pas pour autant une vraie queue générique.
  final int priority;

  /// Ratio critique minimal transporté jusqu'au moteur battle.
  ///
  /// BE6 reste volontairement petit :
  /// - on transporte seulement l'entier canonique déjà présent côté runtime ;
  /// - le moteur battle l'interprète via une table locale explicite ;
  /// - on n'ouvre pas les règles avancées de critique du jeu complet.
  ///
  /// Valeur neutre :
  /// - `1` correspond au ratio critique standard.
  ///
  /// Garde-fou de mini-fix BE6 :
  /// - comme pour `BattleMove`, ce contrat de setup reste `const` pour ne pas
  ///   casser inutilement les anciens call sites battle directs ;
  /// - l’assertion arrête donc tôt les usages invalides en debug/test ;
  /// - on garde en plus un getter validé, car un objet battle malformé peut
  ///   encore contourner les assertions hors debug ;
  /// - le moteur garde enfin sa propre validation défensive au moment exact où
  ///   il consomme le ratio critique.
  final int _critRatio;

  int get critRatio {
    if (_critRatio < 1) {
      throw StateError(
        'BattleMoveData critRatio must be >= 1; got $_critRatio.',
      );
    }
    return _critRatio;
  }

  /// Changements d'étages de stats appliqués au lanceur.
  final List<BattleStatStageChange> selfStatStageChanges;

  /// Changements d'étages de stats appliqués à la cible.
  final List<BattleStatStageChange> targetStatStageChanges;
}
```

### [packages/map_battle/lib/src/battle_rng.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_rng.dart)

```dart
/// Seam RNG battle minimal introduit par BE4.
///
/// But strict :
/// - rendre le hit pipeline testable ;
/// - éviter un `Random()` caché au milieu du moteur ;
/// - garder un contrat assez petit pour ne pas ouvrir un système générique
///   d'événements aléatoires.
///
/// Frontière volontaire :
/// - BE4 ouvrait seulement un roll de précision `1..100` ;
/// - BE6 ajoute un tout petit tirage "numerator / denominator" pour les crits ;
/// - on ne crée toujours pas de framework RNG général pour tous les futurs cas ;
/// - pas de PRNG global ;
/// - pas de singleton ;
/// - pas de notion d'event random autre que le hit check.
abstract class BattleRng {
  const BattleRng();

  /// Tire un pourcentage entier dans l'intervalle fermé `[1, 100]`.
  ///
  /// Le contrat retourne aussi l'instance RNG suivante pour préserver le style
  /// immutable du moteur : une session de combat produit une nouvelle session,
  /// avec un nouvel état RNG si un tirage a eu lieu.
  BattleRngRoll nextPercentRoll();

  /// Résout une chance rationnelle minimale pour les besoins battle actuels.
  ///
  /// BE6 l'introduit pour éviter un faux compromis en pourcentages arrondis :
  /// - la table de critiques a des probabilités du type `1/24`, `1/8`, `1/2` ;
  /// - les convertir de force en pourcentages ferait perdre la sémantique ;
  /// - un tirage numérateur / dénominateur suffit ici sans ouvrir un système
  ///   aléatoire généraliste.
  BattleRngChanceResult nextChance({
    required int numerator,
    required int denominator,
  });
}

/// Résultat d'un tirage RNG battle.
class BattleRngRoll {
  const BattleRngRoll({
    required this.value,
    required this.next,
  }) : assert(value >= 1 && value <= 100);

  /// Valeur tirée, toujours entre 1 et 100 inclus.
  final int value;

  /// État RNG suivant à réinjecter dans la session.
  final BattleRng next;
}

/// Résultat d'une chance rationnelle battle.
class BattleRngChanceResult {
  const BattleRngChanceResult({
    required this.didOccur,
    required this.next,
  });

  /// true si l'événement s'est produit.
  final bool didOccur;

  /// État RNG suivant à réinjecter dans la session.
  final BattleRng next;
}

/// RNG par défaut du moteur battle.
///
/// On choisit un petit générateur déterministe local plutôt que `Random()` :
/// - cela garde le moteur pur et reproductible ;
/// - cela évite une dépendance implicite à un état global ;
/// - cela suffit largement pour le hit pipeline minimal de BE4.
class BattleSeededRng extends BattleRng {
  const BattleSeededRng({
    this.state = 0x00C0FFEE,
  });

  final int state;

  @override
  BattleRngRoll nextPercentRoll() {
    // LCG volontairement simple :
    // - assez bon pour un MVP déterministe ;
    // - très facile à rejouer ;
    // - pas présenté comme un futur PRNG universel du moteur.
    final nextState = (1664525 * state + 1013904223) & 0xFFFFFFFF;
    final value = (nextState % 100) + 1;
    return BattleRngRoll(
      value: value,
      next: BattleSeededRng(state: nextState),
    );
  }

  @override
  BattleRngChanceResult nextChance({
    required int numerator,
    required int denominator,
  }) {
    // Mini-fix BE6 :
    // - `BattleScriptedRng` protégeait déjà ce contrat à l'exécution ;
    // - `BattleSeededRng` n'avait que des `assert`, donc un appel invalide
    //   pouvait survivre en dehors des builds debug ;
    // - on aligne donc explicitement les gardes runtime ici pour arrêter un
    //   bug de robustesse, sans créer une nouvelle couche RNG abstraite.
    if (denominator < 1 || numerator < 0 || numerator > denominator) {
      throw StateError(
        'BattleSeededRng received an invalid chance contract ($numerator/$denominator).',
      );
    }

    final nextState = (1664525 * state + 1013904223) & 0xFFFFFFFF;
    final value = (nextState % denominator) + 1;
    return BattleRngChanceResult(
      didOccur: value <= numerator,
      next: BattleSeededRng(state: nextState),
    );
  }
}

/// RNG scripté pour les tests ciblés.
///
/// Ce type permet d'écrire des preuves fortes du genre :
/// - ce move touche ;
/// - ce move miss ;
/// - l'état RNG avance bien d'un tirage à chaque tentative.
///
/// Si la séquence est épuisée, on préfère échouer explicitement plutôt que de
/// repartir silencieusement sur un fallback arbitraire.
class BattleScriptedRng extends BattleRng {
  const BattleScriptedRng(
    this.rolls, {
    this.index = 0,
  });

  final List<int> rolls;
  final int index;

  @override
  BattleRngRoll nextPercentRoll() {
    if (index >= rolls.length) {
      throw StateError(
        'BattleScriptedRng exhausted while a battle hit check still needed randomness.',
      );
    }
    final value = rolls[index];
    if (value < 1 || value > 100) {
      throw StateError(
        'BattleScriptedRng only accepts rolls between 1 and 100; got $value.',
      );
    }
    return BattleRngRoll(
      value: value,
      next: BattleScriptedRng(
        rolls,
        index: index + 1,
      ),
    );
  }

  @override
  BattleRngChanceResult nextChance({
    required int numerator,
    required int denominator,
  }) {
    if (index >= rolls.length) {
      throw StateError(
        'BattleScriptedRng exhausted while a battle random chance still needed randomness.',
      );
    }
    if (denominator < 1 || numerator < 0 || numerator > denominator) {
      throw StateError(
        'BattleScriptedRng received an invalid chance contract ($numerator/$denominator).',
      );
    }
    final value = rolls[index];
    if (value < 1 || value > denominator) {
      throw StateError(
        'BattleScriptedRng only accepts rolls between 1 and $denominator for this chance; got $value.',
      );
    }
    return BattleRngChanceResult(
      didOccur: value <= numerator,
      next: BattleScriptedRng(
        rolls,
        index: index + 1,
      ),
    );
  }
}
```

### [packages/map_battle/lib/src/battle_session.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart)

```dart
import 'battle_setup.dart';
import 'battle_state.dart';
import 'battle_action.dart';
import 'battle_move.dart';
import 'battle_rng.dart';
import 'battle_resolution.dart';
import 'battle_stats.dart';
import 'battle_type_chart.dart';

const double _criticalHitMultiplier = 1.5;

/// Crée une nouvelle session de combat.
///
/// [setup] - La configuration initiale du combat.
/// [rng] - Le seam RNG minimal utilisé par le hit pipeline.
///
/// Retourne une nouvelle [BattleSession] avec l'état initial.
/// C'est le point d'entrée principal du moteur de combat.
BattleSession createBattleSession(
  BattleSetup setup, {
  BattleRng rng = const BattleSeededRng(),
}) {
  // Le runtime peut maintenant fournir les PV courants réels du Pokémon actif.
  // On garde néanmoins un fallback explicite sur les PV max pour préserver les
  // anciens call sites/tests qui n'avaient pas besoin de cet état.
  final playerCurrentHp = _clampHp(
    currentHp: setup.playerPokemon.currentHp,
    maxHp: setup.playerPokemon.maxHp,
  );
  final enemyCurrentHp = _clampHp(
    currentHp: setup.enemyPokemon.currentHp,
    maxHp: setup.enemyPokemon.maxHp,
  );

  // Convertir les données de setup en combattants
  final player = BattleCombatant(
    speciesId: setup.playerPokemon.speciesId,
    level: setup.playerPokemon.level,
    currentHp: playerCurrentHp,
    maxHp: setup.playerPokemon.maxHp,
    stats: setup.playerPokemon.stats,
    typing: setup.playerPokemon.typing,
    abilityId: setup.playerPokemon.abilityId,
    // Le contrat battle enrichi doit survivre jusqu'à l'état de session :
    // - `type` et `target` restent surtout descriptifs à ce stade ;
    // - `priority` est déjà consommée depuis BE3 ;
    // - `accuracy` et `currentPp` deviennent réellement actives en BE4.
    // - `critRatio` devient réellement consommé en BE6.
    moves: setup.playerPokemon.moves
        .map(
          (m) => BattleMove(
            id: m.id,
            name: m.name,
            power: m.power,
            type: m.type,
            category: m.category,
            target: m.target,
            accuracy: m.accuracy,
            pp: m.pp,
            currentPp: m.currentPp,
            priority: m.priority,
            critRatio: m.critRatio,
            selfStatStageChanges: m.selfStatStageChanges,
            targetStatStageChanges: m.targetStatStageChanges,
          ),
        )
        .toList(),
  );

  final enemy = BattleCombatant(
    speciesId: setup.enemyPokemon.speciesId,
    level: setup.enemyPokemon.level,
    currentHp: enemyCurrentHp,
    maxHp: setup.enemyPokemon.maxHp,
    stats: setup.enemyPokemon.stats,
    typing: setup.enemyPokemon.typing,
    abilityId: setup.enemyPokemon.abilityId,
    // Même règle pour l'adversaire : on ne reperd aucune dimension déjà jugée
    // honnête dans le contrat battle minimal.
    moves: setup.enemyPokemon.moves
        .map(
          (m) => BattleMove(
            id: m.id,
            name: m.name,
            power: m.power,
            type: m.type,
            category: m.category,
            target: m.target,
            accuracy: m.accuracy,
            pp: m.pp,
            currentPp: m.currentPp,
            priority: m.priority,
            critRatio: m.critRatio,
            selfStatStageChanges: m.selfStatStageChanges,
            targetStatStageChanges: m.targetStatStageChanges,
          ),
        )
        .toList(),
  );

  // Créer l'état initial
  final initialState = BattleState(
    phase: BattlePhase.playerChoice,
    player: player,
    enemy: enemy,
    currentTurn: null,
    outcome: null,
  );

  return BattleSession._(
    state: initialState,
    setup: setup,
    rng: rng,
  );
}

int _clampHp({
  required int? currentHp,
  required int maxHp,
}) {
  final value = currentHp ?? maxHp;
  if (value < 0) {
    return 0;
  }
  if (value > maxHp) {
    return maxHp;
  }
  return value;
}

/// Session de combat.
///
/// Encapsule l'état d'un combat et fournit les méthodes pour interagir avec.
/// Immutable : toutes les méthodes retournent une nouvelle session.
///
/// Cycle de vie :
/// 1. [createBattleSession] crée la session
/// 2. [getAvailableChoices] récupère les choix disponibles
/// 3. [applyChoice] applique un choix et retourne une nouvelle session
/// 4. Répéter 2-3 jusqu'à ce que [state.isFinished] soit true
/// 5. Récupérer [state.outcome] pour le résultat final
class BattleSession {
  /// Crée une session de combat.
  ///
  /// Constructeur privé. Utiliser [createBattleSession] à la place.
  const BattleSession._({
    required this.state,
    required this.setup,
    required this.rng,
  });

  /// L'état actuel du combat.
  final BattleState state;

  /// La configuration initiale du combat.
  ///
  /// Gardée pour accéder aux métadonnées (trainerId, etc.).
  final BattleSetup setup;

  /// RNG minimal du moteur battle.
  ///
  /// BE4 choisit de le garder sur la session plutôt que dans `BattleState` :
  /// - l'état observable du combat reste centré sur les combattants / outcomes ;
  /// - le RNG reste un détail de résolution, pas une donnée UI/runtime ;
  /// - mais il reste explicitement injectable et immutable.
  final BattleRng rng;

  /// Récupère les choix disponibles pour le joueur.
  ///
  /// À appeler quand [state.phase] == [BattlePhase.playerChoice].
  ///
  /// Retourne une liste de choix :
  /// - [PlayerBattleChoiceFight] pour chaque attaque disponible (0-3)
  /// - [PlayerBattleChoiceCapture] pour capturer, uniquement en sauvage quand
  ///   le runtime a explicitement autorisé cette issue
  /// - [PlayerBattleChoiceRun] pour fuir, uniquement en combat sauvage
  ///
  /// Exemple d'usage :
  /// ```dart
  /// final choices = session.getAvailableChoices();
  /// // wild: [Fight(0), Fight(1), Fight(2), Fight(3), Capture(), Run()]
  /// // trainer: [Fight(0), Fight(1), Fight(2), Fight(3)]
  /// ```
  List<PlayerBattleChoice> getAvailableChoices() {
    // BE4 arrête ici un autre mensonge discret :
    // - un move à 0 PP ne doit plus apparaître comme un choix valide ;
    // - on conserve néanmoins l'index réel du slot pour que l'UI/runtime
    //   continue à référencer le vrai move dans la liste du combattant ;
    // - on n'ouvre toujours pas Struggle, donc un Pokémon peut n'avoir aucun
    //   choix `Fight` restant.
    final fightChoices = <PlayerBattleChoice>[];
    for (var i = 0; i < state.player.moves.length; i++) {
      if (state.player.moves[i].hasUsablePp) {
        fightChoices.add(PlayerBattleChoiceFight(i));
      }
    }

    // Invariants métier lots 11 + 13 :
    // - la fuite est autorisée en sauvage pour garder une vraie boucle jouable ;
    // - la capture n'est autorisée qu'en sauvage ;
    // - la capture n'est proposée que si le runtime a validé qu'elle pourra
    //   être écrite honnêtement (party avec place, pas de trainer battle) ;
    // - trainer battle : ni Run ni Capture ne doivent apparaître.
    if (!setup.isTrainerBattle && setup.allowCapture) {
      fightChoices.add(const PlayerBattleChoiceCapture());
    }

    // On filtre donc Run ici pour que l'UI/runtime n'ait pas de bouton
    // de fuite à afficher en trainer battle.
    if (!setup.isTrainerBattle) {
      fightChoices.add(const PlayerBattleChoiceRun());
    }

    return fightChoices;
  }

  /// Applique un choix du joueur et retourne une NOUVELLE session.
  ///
  /// [choice] - Le choix fait par le joueur.
  ///
  /// Cette méthode est immutable : elle ne modifie pas [this],
  /// mais retourne une nouvelle [BattleSession] avec l'état mis à jour.
  ///
  /// Comportement :
  /// 1. Convertit le [PlayerBattleChoice] en [BattleAction]
  /// 2. Détermine l'action de l'ennemi (IA simple)
  /// 3. Résout le tour (ordre d'exécution, dégâts, etc.)
  /// 4. Vérifie si un combattant est K.O.
  /// 5. Si combat fini, crée [BattleOutcome]
  /// 6. Retourne la nouvelle session
  ///
  /// Depuis BE4, la résolution d'un move n'est plus "toujours hit" :
  /// - la tentative peut consommer 1 PP puis rater ;
  /// - ce miss n'annule ni l'ordre du tour ni la consommation ;
  /// - seuls les effets réellement supportés sont alors appliqués sur hit.
  ///
  /// Exemple d'usage :
  /// ```dart
  /// final newSession = session.applyChoice(PlayerBattleChoiceFight(0));
  /// if (newSession.state.isFinished) {
  ///   final outcome = newSession.state.outcome!;
  ///   // outcome.isVictory, outcome.isDefeat, etc.
  /// }
  /// ```
  BattleSession applyChoice(PlayerBattleChoice choice) {
    // Frontière métier défensive :
    // même si un call site contourne getAvailableChoices(), un combat trainer
    // ne doit jamais pouvoir produire ni "runaway", ni "captured".
    //
    // On rejette explicitement ce cas illégal au niveau du moteur, ce qui
    // évite de dépendre d'un filtre UI seulement.
    if (choice is PlayerBattleChoiceRun && setup.isTrainerBattle) {
      throw StateError(
        'PlayerBattleChoiceRun est interdit pendant un trainer battle.',
      );
    }
    if (choice is PlayerBattleChoiceCapture && setup.isTrainerBattle) {
      throw StateError(
        'PlayerBattleChoiceCapture est interdit pendant un trainer battle.',
      );
    }
    if (choice is PlayerBattleChoiceCapture && !setup.allowCapture) {
      throw StateError(
        'PlayerBattleChoiceCapture est interdit pour ce combat.',
      );
    }

    // Lot 11 verrouille une boucle sauvage jouable de bout en bout.
    //
    // L'overlay runtime expose déjà explicitement l'action "Run". Si on la
    // laissait se comporter comme un tour vide sans issue finale, on garderait
    // une incohérence produit : la fuite semblerait disponible, mais ne
    // sortirait jamais réellement du combat.
    //
    // On choisit ici le comportement le plus petit et le plus honnête pour le
    // moteur MVP actuel :
    // - la fuite réussit immédiatement ;
    // - aucun dégât supplémentaire n'est appliqué ;
    // - aucun système lot 14+ (récompenses, sac, switch, XP, etc.) n'est ouvert ;
    // - le runtime lot 10 peut réutiliser directement cet outcome pour son
    //   write-back et son retour overworld.
    if (choice is PlayerBattleChoiceRun) {
      final finalState = BattleState(
        phase: BattlePhase.finished,
        player: state.player,
        enemy: state.enemy,
        currentTurn: null,
        outcome: null,
      );
      return BattleSession._(
        state: BattleState(
          phase: BattlePhase.finished,
          player: finalState.player,
          enemy: finalState.enemy,
          currentTurn: null,
          outcome: BattleOutcome(
            type: BattleOutcomeType.runaway,
            finalState: finalState,
          ),
        ),
        setup: setup,
        rng: rng,
      );
    }

    // Lot 13 choisit le plus petit contrat de capture honnête :
    // - pas de formule canonique de Poké Ball ;
    // - pas de consommation d'objet ;
    // - la capture réussit immédiatement quand elle est proposée ;
    // - le runtime reste responsable du vrai write-back dans la party/save.
    //
    // On garde l'ennemi inchangé dans le finalState : il représente le Pokémon
    // effectivement capturé, avec ses moves/niveau/ability réellement engagés.
    if (choice is PlayerBattleChoiceCapture) {
      final finalState = BattleState(
        phase: BattlePhase.finished,
        player: state.player,
        enemy: state.enemy,
        currentTurn: null,
        outcome: null,
      );
      return BattleSession._(
        state: BattleState(
          phase: BattlePhase.finished,
          player: finalState.player,
          enemy: finalState.enemy,
          currentTurn: null,
          outcome: BattleOutcome(
            type: BattleOutcomeType.captured,
            finalState: finalState,
          ),
        ),
        setup: setup,
        rng: rng,
      );
    }

    // Phase 1: Convertir le choix en action
    final playerAction = _choiceToAction(choice);

    // Phase 2: Déterminer l'action de l'ennemi (IA simple)
    final enemyAction = _chooseEnemyAction();

    // Phase 3: Résoudre le tour.
    //
    // BE3 corrige ici une ancienne approximation mensongère :
    // - on ne résout plus "joueur puis ennemi quoi qu'il arrive" ;
    // - on calcule un ordre minimal honnête une seule fois au début du tour ;
    // - priorité d'abord, puis vitesse effective, puis tie-break déterministe ;
    // - aucun recalcul rétroactif si un move modifie la vitesse pendant ce tour.
    //
    // Frontière volontairement stricte :
    // - pas de queue générique façon Showdown ;
    // - pas de PRNG ;
    // - pas de système de switch / residual / before-turn hooks ;
    // - juste le plus petit mécanisme honnête pour les deux actions de ce tour.
    final resolvedTurn = _resolveTurn(playerAction, enemyAction);

    // Phase 4: Récupérer l'état résultant après dégâts + éventuels boosts.
    final newPlayer = resolvedTurn.player;
    final newEnemy = resolvedTurn.enemy;

    // Phase 5: Vérifier si le combat est fini
    final outcome = _determineOutcome(newPlayer, newEnemy);

    // Phase 6: Créer le nouvel état
    final newState = BattleState(
      phase: outcome != null ? BattlePhase.finished : BattlePhase.playerChoice,
      player: newPlayer,
      enemy: newEnemy,
      currentTurn: outcome == null ? resolvedTurn.turnResult : null,
      outcome: outcome,
    );

    return BattleSession._(
      state: newState,
      setup: setup,
      rng: resolvedTurn.rng,
    );
  }

  /// Convertit un [PlayerBattleChoice] en [BattleAction].
  ///
  /// Cette méthode est interne au moteur de combat.
  BattleAction _choiceToAction(PlayerBattleChoice choice) {
    if (choice is PlayerBattleChoiceFight) {
      // Vérifier que l'index est valide
      if (choice.moveIndex >= 0 &&
          choice.moveIndex < state.player.moves.length) {
        final move = state.player.moves[choice.moveIndex];
        if (!move.hasUsablePp) {
          throw StateError(
            'Le move "${move.name}" n’a plus de PP et ne peut pas être utilisé.',
          );
        }
        return BattleActionFight(
          move,
          moveIndex: choice.moveIndex,
        );
      }
      // Fallback: première attaque si index invalide
      final fallbackMove = state.player.moves.first;
      if (!fallbackMove.hasUsablePp) {
        throw StateError(
          'Aucun fallback honnête possible : le move par défaut n’a plus de PP.',
        );
      }
      return BattleActionFight(
        fallbackMove,
        moveIndex: 0,
      );
    } else if (choice is PlayerBattleChoiceRun) {
      return const BattleActionRun();
    }
    // Fallback: première attaque
    final fallbackMove = state.player.moves.first;
    if (!fallbackMove.hasUsablePp) {
      throw StateError(
        'Aucun fallback honnête possible : le move par défaut n’a plus de PP.',
      );
    }
    return BattleActionFight(
      fallbackMove,
      moveIndex: 0,
    );
  }

  /// Détermine l'action de l'ennemi (IA simple).
  ///
  /// Pour ce MVP, l'IA est très simple :
  /// - Si l'ennemi peut attaquer, il attaque avec une attaque aléatoire (déterministe : première)
  /// - L'ennemi ne fuit jamais
  ///
  /// Cette méthode est interne au moteur de combat.
  BattleAction _chooseEnemyAction() {
    // IA simple : toujours utiliser la première attaque encore utilisable.
    //
    // BE4 ne réintroduit pas un comportement mensonger "le move part quand
    // même sans PP" et n'ouvre pas non plus Struggle :
    // - si aucun move n'a de PP, on échoue explicitement ;
    // - cela garde la dette visible au lieu de la maquiller.
    if (state.enemy.moves.isNotEmpty && !state.enemy.isFainted) {
      for (var i = 0; i < state.enemy.moves.length; i++) {
        if (state.enemy.moves[i].hasUsablePp) {
          return BattleActionFight(
            state.enemy.moves[i],
            moveIndex: i,
          );
        }
      }
      throw StateError(
        'Le combattant adverse n’a plus aucun move utilisable et Struggle est hors scope.',
      );
    }
    // Si aucune attaque, ne rien faire (cas edge)
    return const BattleActionRun();
  }

  /// Résout un tour de combat.
  ///
  /// [playerAction] - L'action du joueur.
  /// [enemyAction] - L'action de l'ennemi.
  ///
  /// Retourne l'état résolu du tour :
  /// - les exécutions à afficher ;
  /// - l'état joueur après dégâts / boosts ;
  /// - l'état ennemi après dégâts / boosts.
  ///
  /// Ordre de résolution BE3 :
  /// 1. on capture l'ordre une seule fois au début du tour ;
  /// 2. pour deux `Fight`, on compare :
  ///    - priorité décroissante ;
  ///    - vitesse effective décroissante ;
  ///    - tie-break déterministe explicite : joueur avant ennemi ;
  /// 3. une action de vitesse du premier acteur n'altère donc jamais
  ///    rétroactivement l'ordre du même tour ;
  /// 4. `Run`/`Capture` restent hors pseudo-queue générique.
  ///
  /// Cette méthode est interne au moteur de combat.
  _ResolvedBattleTurn _resolveTurn(
      BattleAction playerAction, BattleAction enemyAction) {
    final executions = <BattleMoveExecution>[];
    var player = state.player;
    var enemy = state.enemy;
    var turnRng = rng;
    final orderedActions = _resolveTurnOrder(
      playerAction: playerAction,
      enemyAction: enemyAction,
      player: player,
      enemy: enemy,
    );

    for (final orderedAction in orderedActions) {
      switch (orderedAction.actor) {
        case _BattleActor.player:
          if (orderedAction.action
              case BattleActionFight(:final move, :final moveIndex)) {
            if (player.isFainted || enemy.isFainted) {
              continue;
            }
            final resolution = _resolveMoveExecution(
              attackerLabel: 'player',
              move: move,
              moveIndex: moveIndex,
              attacker: player,
              defender: enemy,
              targetLabel: 'enemy',
              rng: turnRng,
            );
            player = resolution.attacker;
            enemy = resolution.defender;
            turnRng = resolution.rng;
            executions.add(resolution.execution);
          }
        case _BattleActor.enemy:
          if (orderedAction.action
              case BattleActionFight(:final move, :final moveIndex)) {
            if (enemy.isFainted || player.isFainted) {
              continue;
            }
            final resolution = _resolveMoveExecution(
              attackerLabel: 'enemy',
              move: move,
              moveIndex: moveIndex,
              attacker: enemy,
              defender: player,
              targetLabel: 'player',
              rng: turnRng,
            );
            enemy = resolution.attacker;
            player = resolution.defender;
            turnRng = resolution.rng;
            executions.add(resolution.execution);
          }
      }
    }

    return _ResolvedBattleTurn(
      player: player,
      enemy: enemy,
      rng: turnRng,
      turnResult: BattleTurnResult(
        playerAction: playerAction,
        enemyAction: enemyAction,
        executions: executions,
      ),
    );
  }

  List<_OrderedBattleAction> _resolveTurnOrder({
    required BattleAction playerAction,
    required BattleAction enemyAction,
    required BattleCombatant player,
    required BattleCombatant enemy,
  }) {
    // BE3 refuse d'introduire une fausse queue générique.
    //
    // Le moteur actuel n'a besoin que d'un ordre honnête pour deux actions :
    // - si ce sont deux `Fight`, on compare priorité puis vitesse effective ;
    // - sinon, on conserve l'ordre historique minimal, car les autres actions
    //   restent déjà gérées explicitement ailleurs (`Run`/`Capture`) ou ne
    //   sont pas de vrais chemins gameplay du moteur MVP.
    if (playerAction is! BattleActionFight ||
        enemyAction is! BattleActionFight) {
      return <_OrderedBattleAction>[
        _OrderedBattleAction(
          actor: _BattleActor.player,
          action: playerAction,
        ),
        _OrderedBattleAction(
          actor: _BattleActor.enemy,
          action: enemyAction,
        ),
      ];
    }

    final playerPriority = playerAction.move.priority;
    final enemyPriority = enemyAction.move.priority;
    if (playerPriority != enemyPriority) {
      return playerPriority > enemyPriority
          ? <_OrderedBattleAction>[
              _OrderedBattleAction(
                actor: _BattleActor.player,
                action: playerAction,
              ),
              _OrderedBattleAction(
                actor: _BattleActor.enemy,
                action: enemyAction,
              ),
            ]
          : <_OrderedBattleAction>[
              _OrderedBattleAction(
                actor: _BattleActor.enemy,
                action: enemyAction,
              ),
              _OrderedBattleAction(
                actor: _BattleActor.player,
                action: playerAction,
              ),
            ];
    }

    final playerSpeed = _resolveEffectiveSpeed(player);
    final enemySpeed = _resolveEffectiveSpeed(enemy);
    if (playerSpeed != enemySpeed) {
      return playerSpeed > enemySpeed
          ? <_OrderedBattleAction>[
              _OrderedBattleAction(
                actor: _BattleActor.player,
                action: playerAction,
              ),
              _OrderedBattleAction(
                actor: _BattleActor.enemy,
                action: enemyAction,
              ),
            ]
          : <_OrderedBattleAction>[
              _OrderedBattleAction(
                actor: _BattleActor.enemy,
                action: enemyAction,
              ),
              _OrderedBattleAction(
                actor: _BattleActor.player,
                action: playerAction,
              ),
            ];
    }

    // Tie-break volontairement déterministe et documenté :
    // - pas de PRNG pour résoudre les égalités d'ordre ;
    // - BE4 introduit bien un seam RNG pour le hit pipeline, mais pas pour ce
    //   tie-break ;
    // - pas de Fischer-Yates façon Showdown ;
    // - on choisit "joueur avant ennemi" parce que c'est stable, testable,
    //   et cohérent avec l'historique du moteur jusqu'ici.
    return <_OrderedBattleAction>[
      _OrderedBattleAction(
        actor: _BattleActor.player,
        action: playerAction,
      ),
      _OrderedBattleAction(
        actor: _BattleActor.enemy,
        action: enemyAction,
      ),
    ];
  }

  /// Résout une exécution unique de move.
  ///
  /// M8 puis BE4 gardent ici un contrat volontairement petit et honnête :
  /// - dégâts standards via `power` ;
  /// - influence de `modifyStats` uniquement sur atk/def/spa/spd ;
  /// - moves de statut => dégâts 0 ;
  /// - hit check minimal et PP réels ;
  /// - BE6 ajoute un crit minimal réel pour les hits offensifs non immunisés ;
  /// - les changements de stats sont appliqués immédiatement après un hit.
  ///
  /// Cette application immédiate reste importante :
  /// - un `growl` du joueur peut déjà réduire une contre-attaque physique
  ///   ennemie plus tard dans le même tour s'il touche ;
  /// - mais un changement de `speed` ne réordonne jamais rétroactivement un
  ///   tour déjà ordonné au début de `_resolveTurn`.
  _ResolvedMoveExecution _resolveMoveExecution({
    required String attackerLabel,
    required BattleMove move,
    required int moveIndex,
    required BattleCombatant attacker,
    required BattleCombatant defender,
    required String targetLabel,
    required BattleRng rng,
  }) {
    if (!move.hasUsablePp) {
      throw StateError(
        'Le move "${move.name}" n’a plus de PP et ne peut pas être résolu honnêtement.',
      );
    }

    // BE4 introduit ici le plus petit hit pipeline honnête :
    // 1. on valide que le move est encore utilisable ;
    // 2. on consomme 1 PP immédiatement sur la tentative ;
    // 3. on résout ensuite le hit check ;
    // 4. un miss n'applique ni dégâts ni stage changes ;
    // 5. un hit suit le chemin déjà supporté.
    final attackerAfterPpUse = attacker.withUpdatedMoveAt(
      moveIndex,
      move.withConsumedPp(),
    );
    final hitCheck = _resolveHitCheck(
      move: move,
      rng: rng,
    );

    if (!hitCheck.didHit) {
      return _ResolvedMoveExecution(
        attacker: attackerAfterPpUse,
        defender: defender,
        rng: hitCheck.nextRng,
        execution: BattleMoveExecution(
          attacker: attackerLabel,
          move: attackerAfterPpUse.moves[moveIndex],
          target: _resolveExecutionTargetLabel(
            move: move,
            attackerLabel: attackerLabel,
            opponentLabel: targetLabel,
          ),
          damage: 0,
          didHit: false,
          didCrit: false,
          criticalMultiplier: 1.0,
        ),
      );
    }

    final damageResult = _computeMoveDamage(
      move: move,
      attacker: attackerAfterPpUse,
      defender: defender,
      rng: hitCheck.nextRng,
    );

    // BE5 donne à l'immunité une sémantique simple et honnête pour le petit
    // sous-ensemble moteur actuellement supporté :
    // - le move a bien été tenté et a passé le hit check ;
    // - mais il n'a "aucun effet" sur la cible si le typing annule le hit ;
    // - on n'applique donc ni dégâts ni stage changes à partir d'un hit
    //   immunisé, ce qui évite des demi-effets mensongers.
    final updatedAttacker = damageResult.wasImmune
        ? attackerAfterPpUse
        : attackerAfterPpUse.withAppliedStageChanges(move.selfStatStageChanges);
    final updatedDefender = damageResult.wasImmune
        ? defender
        : defender
            .withDamage(damageResult.damage)
            .withAppliedStageChanges(move.targetStatStageChanges);

    return _ResolvedMoveExecution(
      attacker: updatedAttacker,
      defender: updatedDefender,
      rng: damageResult.nextRng,
      execution: BattleMoveExecution(
        attacker: attackerLabel,
        move: updatedAttacker.moves[moveIndex],
        // BE1 ne laisse plus `target` se reperdre au moment de la trace
        // d'exécution :
        // - un move `self` doit apparaître comme ciblant le lanceur ;
        // - un move `opponent` garde la cible adverse résolue du tour ;
        // - `unspecified` reste le fallback de compatibilité des anciens call
        //   sites qui construisaient des moves battle pauvres à la main.
        target: _resolveExecutionTargetLabel(
          move: move,
          attackerLabel: attackerLabel,
          opponentLabel: targetLabel,
        ),
        damage: damageResult.damage,
        didHit: true,
        didCrit: damageResult.didCrit,
        criticalMultiplier: damageResult.criticalMultiplier,
        stabMultiplier: damageResult.stabMultiplier,
        typeEffectivenessMultiplier: damageResult.typeEffectivenessMultiplier,
      ),
    );
  }

  _ResolvedHitCheck _resolveHitCheck({
    required BattleMove move,
    required BattleRng rng,
  }) {
    if (move.accuracy.isAlwaysHits || move.accuracy.value >= 100) {
      // Recadrage volontaire de BE4 :
      // - `alwaysHits` doit évidemment bypasser le hit check ;
      // - dans le moteur actuel, `percent(100)` est également déterministe,
      //   car nous n'avons encore ni accuracy stages, ni evasion, ni autres
      //   modificateurs de précision ;
      // - consommer du RNG sur 100% n'apporterait donc aucune vérité
      //   supplémentaire et compliquerait artificiellement les tests.
      return _ResolvedHitCheck(
        didHit: true,
        nextRng: rng,
      );
    }

    final roll = rng.nextPercentRoll();
    return _ResolvedHitCheck(
      didHit: roll.value <= move.accuracy.value,
      nextRng: roll.next,
    );
  }

  String _resolveExecutionTargetLabel({
    required BattleMove move,
    required String attackerLabel,
    required String opponentLabel,
  }) {
    return switch (move.target) {
      BattleMoveTarget.self => attackerLabel,
      BattleMoveTarget.opponent ||
      BattleMoveTarget.unspecified =>
        opponentLabel,
    };
  }

  /// Calcule les dégâts standards du moteur battle MVP enrichi.
  ///
  /// BE2 ne bascule toujours pas vers une formule Pokémon complète. Le but est
  /// maintenant plus honnête que l'ancien simple `damage = power` :
  /// - les dégâts standards reposent enfin sur un vrai snapshot de stats ;
  /// - les moves physiques utilisent `attack` vs `defense` ;
  /// - les moves spéciaux utilisent `specialAttack` vs `specialDefense` ;
  /// - les stages continuent à s'appliquer, mais sur ces vraies bases ;
  /// - `speed` influence désormais l'ordre d'action dans BE3, mais reste sans
  ///   rôle direct dans les dégâts.
  ///
  /// Frontière explicitement conservée :
  /// - pas d'accuracy/evasion stages ;
  /// - pas de règles Pokémon avancées de critique ;
  /// - le hit check BE4 vit en amont, avant d'entrer dans cette formule ;
  /// - BE6 ajoute seulement :
  ///   - une vraie chance de critique minimale ;
  ///   - un multiplicateur critique fixe ;
  ///   - aucune interaction avancée avec stages / items / abilities.
  _ResolvedDamage _computeMoveDamage({
    required BattleMove move,
    required BattleCombatant attacker,
    required BattleCombatant defender,
    required BattleRng rng,
  }) {
    if (move.resolvedCategory == BattleMoveCategory.status || move.power <= 0) {
      return _ResolvedDamage(
        damage: 0,
        didCrit: false,
        criticalMultiplier: 1.0,
        stabMultiplier: 1.0,
        typeEffectivenessMultiplier: 1.0,
        nextRng: rng,
      );
    }

    final offensiveStatId = switch (move.resolvedCategory) {
      BattleMoveCategory.physical => BattleStatId.attack,
      BattleMoveCategory.special => BattleStatId.specialAttack,
      BattleMoveCategory.status => BattleStatId.attack,
    };
    final defensiveStatId = switch (move.resolvedCategory) {
      BattleMoveCategory.physical => BattleStatId.defense,
      BattleMoveCategory.special => BattleStatId.specialDefense,
      BattleMoveCategory.status => BattleStatId.defense,
    };

    // Ordre de calcul volontairement documenté :
    // 1. on part du snapshot de stats résolu par le runtime ;
    // 2. on applique les stages côté attaquant et défenseur ;
    // 3. on utilise ensuite une formule entière simple, Pokémon-like ;
    // 4. on garde enfin un minimum de 1 dégât pour tout move non-status
    //    ayant passé le bridge BE1.
    final effectiveAttack = _resolveEffectiveStat(
      baseStat: _statValueFor(attacker.stats, offensiveStatId),
      multiplier: attacker.statStages.multiplierFor(offensiveStatId),
    );
    final effectiveDefense = _resolveEffectiveStat(
      baseStat: _statValueFor(defender.stats, defensiveStatId),
      multiplier: defender.statStages.multiplierFor(defensiveStatId),
    );
    final safePower = move.power < 0 ? 0 : move.power;
    final levelFactor = ((2 * attacker.level) ~/ 5) + 2;
    final baseDamage =
        ((((levelFactor * safePower * effectiveAttack) ~/ effectiveDefense) ~/
                    50) +
                2)
            .toInt();

    // BE5 ajoute ici la plus petite consommation honnête du type :
    // - STAB simple à 1.5 ;
    // - type chart standard ;
    // - immunité à 0 ;
    // - double type multiplicatif ;
    // - toujours aucune abilities, aucun item, aucun weather, aucune Tera.
    final stabMultiplier = BattleTypeChart.resolveStabMultiplier(
      moveType: move.type,
      attackerTyping: attacker.typing,
    );
    final typeEffectivenessMultiplier =
        BattleTypeChart.resolveEffectivenessMultiplier(
      moveType: move.type,
      defenderTyping: defender.typing,
    );

    if (typeEffectivenessMultiplier == 0.0) {
      return _ResolvedDamage(
        damage: 0,
        didCrit: false,
        criticalMultiplier: 1.0,
        stabMultiplier: stabMultiplier,
        typeEffectivenessMultiplier: typeEffectivenessMultiplier,
        nextRng: rng,
      );
    }

    // BE6 garde ici un ordre de résolution petit mais honnête :
    // 1. le hit check a déjà eu lieu en amont ;
    // 2. on vérifie ensuite l'immunité via le type chart ;
    // 3. seulement pour un hit offensif non immunisé, on résout un crit ;
    // 4. puis on applique STAB / efficacité de type et le clamp final.
    //
    // Ce choix évite de "dépenser" un tirage de crit sur un move qui n'aurait
    // de toute façon aucun effet. Pour le sous-ensemble actuel, c'est plus
    // honnête et reste mathématiquement neutre sur le résultat observable.
    final criticalHit = _resolveCriticalHit(
      move: move,
      rng: rng,
    );

    // Ordre de multiplication BE6 :
    // 1. baseDamage déterministe BE2 ;
    // 2. critique minimal BE6 ;
    // 3. STAB ;
    // 4. effectiveness / résistance ;
    // 5. clamp minimum 1 si le move a touché et n'est pas immunisé.
    //
    // On reste volontairement dans un modèle simple à base de doubles +
    // `floor` plutôt que de singer tous les paliers internes de Showdown.
    final scaledDamage = (baseDamage *
            criticalHit.multiplier *
            stabMultiplier *
            typeEffectivenessMultiplier)
        .floor();
    final finalDamage = scaledDamage < 1 ? 1 : scaledDamage;

    return _ResolvedDamage(
      damage: finalDamage,
      didCrit: criticalHit.didCrit,
      criticalMultiplier: criticalHit.multiplier,
      stabMultiplier: stabMultiplier,
      typeEffectivenessMultiplier: typeEffectivenessMultiplier,
      nextRng: criticalHit.nextRng,
    );
  }

  _ResolvedCriticalHit _resolveCriticalHit({
    required BattleMove move,
    required BattleRng rng,
  }) {
    final chance = _critChanceForRatio(move.critRatio);
    if (chance.didOccurWithoutRng) {
      return _ResolvedCriticalHit(
        didCrit: true,
        multiplier: _criticalHitMultiplier,
        nextRng: rng,
      );
    }

    final roll = rng.nextChance(
      numerator: chance.numerator,
      denominator: chance.denominator,
    );
    return _ResolvedCriticalHit(
      didCrit: roll.didOccur,
      multiplier: roll.didOccur ? _criticalHitMultiplier : 1.0,
      nextRng: roll.next,
    );
  }

  _CritChance _critChanceForRatio(int critRatio) {
    // Table BE6 volontairement explicite :
    // - on suit une lecture moderne Pokémon-like des stages de crit ;
    // - `1` reste le ratio neutre du canonique projet ;
    // - on ne prétend pas ouvrir Focus Energy, Lucky Chant ou d'autres
    //   modificateurs indirects.
    //
    // Mini-fix BE6 :
    // - la première version neutralisait silencieusement `critRatio <= 0`
    //   dans la branche "ratio neutre" ;
    // - cela laissait une donnée battle invalide devenir "à peu près valide"
    //   au lieu d'échouer franchement ;
    // - on préfère maintenant un `StateError` explicite, parce qu'à ce stade
    //   il s'agit d'un état battle incohérent, pas d'une simple option métier.
    if (critRatio < 1) {
      throw StateError(
        'Battle critical ratio must be >= 1; got $critRatio.',
      );
    }
    return switch (critRatio) {
      1 => const _CritChance(numerator: 1, denominator: 24),
      2 => const _CritChance(numerator: 1, denominator: 8),
      3 => const _CritChance(numerator: 1, denominator: 2),
      _ => const _CritChance.always(),
    };
  }

  int _statValueFor(BattleStatsSnapshot snapshot, BattleStatId stat) {
    return switch (stat) {
      BattleStatId.attack => snapshot.attack,
      BattleStatId.defense => snapshot.defense,
      BattleStatId.specialAttack => snapshot.specialAttack,
      BattleStatId.specialDefense => snapshot.specialDefense,
      BattleStatId.speed => snapshot.speed,
    };
  }

  int _resolveEffectiveSpeed(BattleCombatant combatant) {
    // L'ordre BE3 repose sur une vitesse effective déterministe :
    // - snapshot de speed résolu par le runtime ;
    // - multiplicateur de stages battle déjà présent ;
    // - aucun RNG, aucune nature, aucun weather, aucun trick room.
    return _resolveEffectiveStat(
      baseStat: combatant.stats.speed,
      multiplier: combatant.statStages.multiplierFor(BattleStatId.speed),
    );
  }

  int _resolveEffectiveStat({
    required int baseStat,
    required double multiplier,
  }) {
    // BE2 garde ici une règle simple et déterministe :
    // - pas de fraction stockée ;
    // - pas de rounding ambigu ;
    // - on applique les stages par multiplication, puis `floor` ;
    // - on clamp enfin au minimum 1 pour ne jamais diviser par 0 ni produire
    //   une stat offensive/défensive absurde.
    final resolved = (baseStat * multiplier).floor();
    return resolved < 1 ? 1 : resolved;
  }

  /// Détermine le résultat final du combat.
  ///
  /// [player] - L'état final du joueur.
  /// [enemy] - L'état final de l'ennemi.
  ///
  /// Retourne null si le combat continue, ou un [BattleOutcome] si fini.
  ///
  /// Règles :
  /// - Si enemy.isFainted → victoire
  /// - Si player.isFainted → défaite
  /// - Sinon → combat continue (null)
  ///
  /// Cette méthode est interne au moteur de combat.
  BattleOutcome? _determineOutcome(
      BattleCombatant player, BattleCombatant enemy) {
    // Vérifier la victoire (ennemi K.O.)
    if (enemy.isFainted) {
      final finalState = BattleState(
        phase: BattlePhase.finished,
        player: player,
        enemy: enemy,
        currentTurn: null,
        outcome: null, // Sera set dans le BattleOutcome
      );
      return BattleOutcome(
        type: BattleOutcomeType.victory,
        finalState: finalState,
      );
    }

    // Vérifier la défaite (joueur K.O.)
    if (player.isFainted) {
      final finalState = BattleState(
        phase: BattlePhase.finished,
        player: player,
        enemy: enemy,
        currentTurn: null,
        outcome: null,
      );
      return BattleOutcome(
        type: BattleOutcomeType.defeat,
        finalState: finalState,
      );
    }

    // Combat continue
    return null;
  }
}

enum _BattleActor {
  player,
  enemy,
}

class _OrderedBattleAction {
  const _OrderedBattleAction({
    required this.actor,
    required this.action,
  });

  final _BattleActor actor;
  final BattleAction action;
}

class _ResolvedBattleTurn {
  const _ResolvedBattleTurn({
    required this.player,
    required this.enemy,
    required this.rng,
    required this.turnResult,
  });

  final BattleCombatant player;
  final BattleCombatant enemy;
  final BattleRng rng;
  final BattleTurnResult turnResult;
}

class _ResolvedMoveExecution {
  const _ResolvedMoveExecution({
    required this.attacker,
    required this.defender,
    required this.rng,
    required this.execution,
  });

  final BattleCombatant attacker;
  final BattleCombatant defender;
  final BattleRng rng;
  final BattleMoveExecution execution;
}

class _ResolvedHitCheck {
  const _ResolvedHitCheck({
    required this.didHit,
    required this.nextRng,
  });

  final bool didHit;
  final BattleRng nextRng;
}

class _ResolvedDamage {
  const _ResolvedDamage({
    required this.damage,
    required this.didCrit,
    required this.criticalMultiplier,
    required this.stabMultiplier,
    required this.typeEffectivenessMultiplier,
    required this.nextRng,
  });

  final int damage;
  final bool didCrit;
  final double criticalMultiplier;
  final double stabMultiplier;
  final double typeEffectivenessMultiplier;
  final BattleRng nextRng;

  bool get wasImmune => typeEffectivenessMultiplier == 0.0;
}

class _ResolvedCriticalHit {
  const _ResolvedCriticalHit({
    required this.didCrit,
    required this.multiplier,
    required this.nextRng,
  });

  final bool didCrit;
  final double multiplier;
  final BattleRng nextRng;
}

class _CritChance {
  const _CritChance({
    required this.numerator,
    required this.denominator,
  }) : didOccurWithoutRng = false;

  const _CritChance.always()
      : numerator = 1,
        denominator = 1,
        didOccurWithoutRng = true;

  final int numerator;
  final int denominator;
  final bool didOccurWithoutRng;
}
```

### [packages/map_battle/test/battle_session_test.dart](/Users/karim/Project/pokemonProject/packages/map_battle/test/battle_session_test.dart)

```dart
import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

const _neutralBattleStats = BattleStatsSnapshot(
  attack: 50,
  defense: 50,
  specialAttack: 50,
  specialDefense: 50,
  speed: 50,
);

void main() {
  group('BattleSession', () {
    // Helper pour créer un setup de test
    BattleSetup createTestSetup({
      bool isTrainerBattle = false,
      String? trainerId,
      bool allowCapture = false,
    }) {
      return BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 20,
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
            BattleMoveData(id: 'scratch', name: 'Griffe', power: 4),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 25,
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
          ],
        ),
        isTrainerBattle: isTrainerBattle,
        trainerId: trainerId,
        allowCapture: allowCapture,
      );
    }

    test('createBattleSession creates session with playerChoice phase', () {
      final setup = createTestSetup();
      final session = createBattleSession(setup);

      expect(session.state.phase, equals(BattlePhase.playerChoice));
      expect(session.state.player.currentHp, equals(20)); // PV pleins
      expect(session.state.enemy.currentHp, equals(25)); // PV pleins
      expect(session.state.outcome, isNull);
      expect(session.state.isFinished, isFalse);
    });

    test('createBattleSession creates trainer battle with trainerId', () {
      final setup = createTestSetup(
        isTrainerBattle: true,
        trainerId: 'gym_leader_1',
      );
      final session = createBattleSession(setup);

      expect(session.setup.isTrainerBattle, isTrue);
      expect(session.setup.trainerId, equals('gym_leader_1'));
    });

    test('createBattleSession respects currentHp when provided by runtime', () {
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 20,
          currentHp: 7,
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 25,
          currentHp: 11,
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
          ],
        ),
        isTrainerBattle: false,
        trainerId: null,
      );

      final session = createBattleSession(setup);

      expect(session.state.player.currentHp, equals(7));
      expect(session.state.enemy.currentHp, equals(11));
    });

    test(
        'createBattleSession preserves the additional honest battle contract fields transported by BE1, BE3, BE4, BE5 and BE6',
        () {
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 20,
          stats: _neutralBattleStats,
          typing: const BattleTypingSnapshot(primaryType: 'electric'),
          moves: const [
            BattleMoveData(
              id: 'vine_whip',
              name: 'Vine Whip',
              power: 45,
              type: 'grass',
              category: BattleMoveCategory.physical,
              target: BattleMoveTarget.opponent,
              accuracy: BattleMoveAccuracy.percent(value: 95),
              pp: 25,
              currentPp: 7,
              priority: 1,
              critRatio: 2,
            ),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 25,
          stats: _neutralBattleStats,
          typing: const BattleTypingSnapshot(
            primaryType: 'water',
            secondaryType: 'ice',
          ),
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
          ],
        ),
        isTrainerBattle: false,
        trainerId: null,
      );

      final session = createBattleSession(setup);
      final move = session.state.player.moves.single;
      final playerTyping = session.state.player.typing!;
      final enemyTyping = session.state.enemy.typing!;

      expect(move.type, equals('grass'));
      expect(move.category, equals(BattleMoveCategory.physical));
      expect(move.target, equals(BattleMoveTarget.opponent));
      expect(move.accuracy.kind, equals(BattleMoveAccuracyKind.percent));
      expect(move.accuracy.value, equals(95));
      expect(move.pp, equals(25));
      expect(move.currentPp, equals(7));
      expect(move.priority, equals(1));
      expect(move.critRatio, equals(2));
      expect(playerTyping.primaryType, equals('electric'));
      expect(playerTyping.secondaryType, isNull);
      expect(enemyTyping.primaryType, equals('water'));
      expect(enemyTyping.secondaryType, equals('ice'));
    });

    test('BattleMoveData rejects an invalid crit ratio in debug builds', () {
      expect(
        () => BattleMoveData(
          id: 'slash',
          name: 'Slash',
          power: 50,
          critRatio: 0,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('BattleMove rejects an invalid crit ratio in debug builds', () {
      expect(
        () => BattleMove(
          id: 'slash',
          name: 'Slash',
          power: 50,
          critRatio: 0,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test(
        'a malformed battle move setup that bypasses constructor guards is rejected before session creation',
        () {
      // Mini-fix BE6 :
      // - `BattleMoveData` reste `const` pour ne pas casser les anciens call
      //   sites battle directs ;
      // - l'assertion de constructeur couvre donc surtout les builds debug ;
      // - ce test force volontairement un objet setup malformé via override
      //   pour prouver que `createBattleSession()` refuse encore explicitement
      //   l'état incohérent dès qu'il consomme `critRatio`.
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 20,
          stats: _neutralBattleStats,
          moves: const [
            _MalformedCritBattleMoveData(),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 25,
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
          ],
        ),
        isTrainerBattle: false,
        trainerId: null,
      );

      expect(
        () => createBattleSession(setup),
        // En debug/test, la session tombe encore plus tôt sur l'assertion du
        // constructeur `BattleMove` quand elle tente de matérialiser le move
        // setup malformé. Hors assertions, le getter validé de
        // `BattleMoveData` puis la garde moteur prennent le relais.
        throwsA(
          anyOf(
            isA<AssertionError>(),
            isA<StateError>().having(
              (error) => error.message,
              'message',
              contains('BattleMoveData critRatio must be >= 1'),
            ),
          ),
        ),
      );
    });

    test(
        'a malformed battle move that bypasses constructor guards is still rejected before crit resolution',
        () {
      final session = createBattleSession(
        createTestSetup(),
        rng: const BattleScriptedRng(<int>[2, 2]),
      );

      // Mini-fix BE6 :
      // - les constructeurs publics `const` ne peuvent pas lancer un vrai
      //   `throw` runtime sans casser inutilement le contrat battle existant ;
      // - on garde donc une assertion locale au constructeur ;
      // - et ce test force volontairement un objet malformé via override pour
      //   prouver que le moteur refuse encore explicitement l'état incohérent
      //   au moment où il consomme réellement le crit.
      session.state.player.moves[0] = _MalformedCritBattleMove();

      expect(
        () => session.applyChoice(const PlayerBattleChoiceFight(0)),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('critical ratio must be >= 1'),
          ),
        ),
      );
    });

    test('getAvailableChoices hides fight choices whose currentPp is zero', () {
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 20,
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(
              id: 'tackle',
              name: 'Charge',
              power: 5,
              pp: 10,
              currentPp: 0,
            ),
            BattleMoveData(
              id: 'scratch',
              name: 'Griffe',
              power: 4,
              pp: 10,
              currentPp: 3,
            ),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 25,
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
          ],
        ),
        isTrainerBattle: false,
        trainerId: null,
      );
      final session = createBattleSession(setup);

      final choices = session.getAvailableChoices();
      final fightChoices =
          choices.whereType<PlayerBattleChoiceFight>().toList();

      expect(fightChoices, hasLength(1));
      expect(fightChoices.single.moveIndex, equals(1));
    });

    test('forcing a move with zero PP is rejected explicitly', () {
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 20,
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(
              id: 'tackle',
              name: 'Charge',
              power: 5,
              pp: 10,
              currentPp: 0,
            ),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 25,
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
          ],
        ),
        isTrainerBattle: false,
        trainerId: null,
      );
      final session = createBattleSession(setup);

      expect(
        () => session.applyChoice(const PlayerBattleChoiceFight(0)),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('n’a plus de PP'),
          ),
        ),
      );
    });

    test('getAvailableChoices returns fight choices + run in wild battle', () {
      final setup = createTestSetup();
      final session = createBattleSession(setup);

      final choices = session.getAvailableChoices();

      // 2 attaques + 1 fuite
      expect(choices.length, equals(3));
      expect(choices[0], isA<PlayerBattleChoiceFight>());
      expect(choices[1], isA<PlayerBattleChoiceFight>());
      expect(choices[2], isA<PlayerBattleChoiceRun>());
    });

    test('getAvailableChoices exposes capture in wild battle when allowed', () {
      final setup = createTestSetup(allowCapture: true);
      final session = createBattleSession(setup);

      final choices = session.getAvailableChoices();

      expect(choices.length, equals(4));
      expect(choices[0], isA<PlayerBattleChoiceFight>());
      expect(choices[1], isA<PlayerBattleChoiceFight>());
      expect(choices[2], isA<PlayerBattleChoiceCapture>());
      expect(choices[3], isA<PlayerBattleChoiceRun>());
    });

    test('getAvailableChoices does not expose run in trainer battle', () {
      final setup = createTestSetup(
        isTrainerBattle: true,
        trainerId: 'gym_leader_1',
      );
      final session = createBattleSession(setup);

      final choices = session.getAvailableChoices();

      expect(choices.length, equals(2));
      expect(choices[0], isA<PlayerBattleChoiceFight>());
      expect(choices[1], isA<PlayerBattleChoiceFight>());
      expect(choices.whereType<PlayerBattleChoiceRun>(), isEmpty);
    });

    test('getAvailableChoices does not expose capture in trainer battle', () {
      final setup = createTestSetup(
        isTrainerBattle: true,
        trainerId: 'gym_leader_1',
        allowCapture: true,
      );
      final session = createBattleSession(setup);

      final choices = session.getAvailableChoices();

      expect(choices.whereType<PlayerBattleChoiceCapture>(), isEmpty);
    });

    test('applyChoice with fight resolves turn and damages enemy', () {
      final setup = createTestSetup();
      final session = createBattleSession(
        setup,
        rng: const BattleScriptedRng(<int>[2, 2]),
      );

      // Joueur utilise la première attaque (power=5)
      final newSession = session.applyChoice(const PlayerBattleChoiceFight(0));

      // Avec le contract de dégâts BE2, le move passe maintenant par les
      // vraies stats résolues au lieu de faire `damage = power`.
      expect(newSession.state.enemy.currentHp, equals(23));
      expect(newSession.state.currentTurn, isNotNull);
      expect(newSession.state.currentTurn!.executions.length, greaterThan(0));
    });

    test('applyChoice with fight resolves turn and damages player', () {
      final setup = createTestSetup();
      final session = createBattleSession(
        setup,
        rng: const BattleScriptedRng(<int>[2, 2]),
      );

      // Joueur utilise la première attaque
      final newSession = session.applyChoice(const PlayerBattleChoiceFight(0));

      // Même logique pour la contre-attaque : on attend désormais un dégât
      // déterministe issu de la formule BE2, pas la puissance brute.
      expect(newSession.state.player.currentHp, equals(18));
    });

    test('KO enemy results in victory', () {
      // Créer un ennemi avec peu de PV
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 100,
          maxHp: 20,
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(id: 'mega-punch', name: 'Mega-Poing', power: 25),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 20, // PV max = 20, donc 1 hit KO
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
          ],
        ),
        isTrainerBattle: false,
        trainerId: null,
      );
      final session = createBattleSession(setup);

      // Joueur utilise Mega-Punch (power=25, one-shot)
      final newSession = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(newSession.state.isFinished, isTrue);
      expect(newSession.state.outcome, isNotNull);
      expect(newSession.state.outcome!.isVictory, isTrue);
      expect(newSession.state.enemy.isFainted, isTrue);
    });

    test('KO player results in defeat', () {
      // Créer un joueur avec peu de PV face à un ennemi puissant
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 5, // Très peu de PV
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(id: 'growl', name: 'Rugissement', power: 0),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'mewtwo',
          level: 100,
          maxHp: 100,
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(id: 'psychic', name: 'Psyko', power: 10),
          ],
        ),
        isTrainerBattle: false,
        trainerId: null,
      );
      final session = createBattleSession(setup);

      // Joueur utilise Growl (power=0, ne fait rien)
      final newSession = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(newSession.state.isFinished, isTrue);
      expect(newSession.state.outcome, isNotNull);
      expect(newSession.state.outcome!.isDefeat, isTrue);
      expect(newSession.state.player.isFainted, isTrue);
    });

    test('trainer battle victory outcome is compatible with marking', () {
      // Créer un setup où le joueur gagne en 1 coup
      final oneHitSetup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'mewtwo',
          level: 100,
          maxHp: 100,
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(id: 'psystrike', name: 'Frapp Psy', power: 50),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 20, // One-shot
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
          ],
        ),
        isTrainerBattle: true,
        trainerId: 'gym_leader_1',
      );
      final session = createBattleSession(oneHitSetup);

      final newSession = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(newSession.state.isFinished, isTrue);
      expect(newSession.state.outcome!.isVictory, isTrue);
      expect(newSession.setup.trainerId, equals('gym_leader_1'));
      // Le runtime peut maintenant marquer : 'trainer_defeated:gym_leader_1'
    });

    test('applyChoice returns new session (immutable)', () {
      final setup = createTestSetup();
      final session = createBattleSession(setup);

      final newSession = session.applyChoice(const PlayerBattleChoiceFight(0));

      // Vérifier que c'est une nouvelle instance
      expect(identical(session, newSession), isFalse);
      expect(identical(session.state, newSession.state), isFalse);
    });

    test('multiple turns until one combatant faints', () {
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 30,
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 100),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 30,
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 100),
          ],
        ),
        isTrainerBattle: false,
        trainerId: null,
      );
      var session = createBattleSession(
        setup,
        rng: BattleScriptedRng(List<int>.filled(6, 2)),
      );

      // Tour 1
      session = session.applyChoice(const PlayerBattleChoiceFight(0));
      expect(session.state.isFinished, isFalse); // Les deux sont encore vivants
      expect(session.state.player.currentHp, equals(20)); // 30 - 10
      expect(session.state.enemy.currentHp, equals(20)); // 30 - 10

      // Tour 2
      session = session.applyChoice(const PlayerBattleChoiceFight(0));
      expect(session.state.isFinished, isFalse);
      expect(session.state.player.currentHp, equals(10)); // 20 - 10
      expect(session.state.enemy.currentHp, equals(10)); // 20 - 10

      // Tour 3
      session = session.applyChoice(const PlayerBattleChoiceFight(0));
      expect(session.state.isFinished, isTrue); // Les deux sont à 0 PV
      // Le joueur joue en premier, donc l'ennemi meurt en premier → victoire
      expect(session.state.outcome!.isVictory, isTrue);
    });
  });
}

class _MalformedCritBattleMove extends BattleMove {
  _MalformedCritBattleMove()
      : super(
          id: 'slash',
          name: 'Slash',
          power: 50,
          category: BattleMoveCategory.physical,
          critRatio: 1,
        );

  @override
  int get critRatio => 0;

  @override
  BattleMove withConsumedPp() => this;
}

class _MalformedCritBattleMoveData extends BattleMoveData {
  const _MalformedCritBattleMoveData()
      : super(
          id: 'slash',
          name: 'Slash',
          power: 50,
          critRatio: 1,
        );

  @override
  int get critRatio => 0;
}
```

### [packages/map_battle/test/battle_rng_test.dart](/Users/karim/Project/pokemonProject/packages/map_battle/test/battle_rng_test.dart)

```dart
import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('BattleRng mini-fix BE6', () {
    test('BattleSeededRng rejects a zero denominator explicitly', () {
      expect(
        () => const BattleSeededRng().nextChance(
          numerator: 1,
          denominator: 0,
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('invalid chance contract'),
          ),
        ),
      );
    });

    test('BattleSeededRng rejects a numerator greater than denominator', () {
      expect(
        () => const BattleSeededRng().nextChance(
          numerator: 3,
          denominator: 2,
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('invalid chance contract'),
          ),
        ),
      );
    });

    test('BattleSeededRng keeps a valid chance contract deterministic', () {
      final first = const BattleSeededRng(state: 12345).nextChance(
        numerator: 1,
        denominator: 24,
      );
      final second = const BattleSeededRng(state: 12345).nextChance(
        numerator: 1,
        denominator: 24,
      );

      // Ce test ne prétend pas valider un grand système RNG.
      // Il verrouille seulement le contrat minimal dont BE6 dépend :
      // - même seed + même chance => même résultat ;
      // - le seam garde un état suivant explicite.
      expect(first.didOccur, equals(second.didOccur));
      expect(first.next, isA<BattleSeededRng>());
    });
  });
}
```
