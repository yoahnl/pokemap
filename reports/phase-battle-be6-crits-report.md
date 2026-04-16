# BE6 — Crits réels minimaux + support honnête de `critRatio`

## 1. Résumé exécutif honnête

BE6 corrige un vrai trou moteur, pas juste de la documentation.

Ce que j’ai réellement fait :

- j’ai cessé de traiter `critRatio` comme une donnée rejetée ou décorative ;
- j’ai transporté `critRatio` du bridge runtime vers le contrat battle minimal ;
- j’ai ajouté un crit minimal réel dans `map_battle` avec une table explicite de chances, un multiplicateur explicite, et une trace explicite ;
- j’ai enrichi `BattleMoveExecution` avec `didCrit` et `criticalMultiplier` ;
- j’ai ajouté des tests battle/runtime ciblés qui prouvent le support réel et les non-régressions utiles.

Ce que je n’ai volontairement pas fait :

- je n’ai pas ouvert un système complet de critiques Pokémon ;
- je n’ai pas ouvert les règles avancées type ignore-stages, Focus Energy, Lucky Chant, items, abilities, burn, screens ou damage roll global ;
- je n’ai pas ouvert status, switch, weather, multi-hit, ni BE7/BE8 en douce ;
- je n’ai pas touché `map_core` ni `map_editor`.

Verdict court :

- oui, `critRatio` est maintenant réellement consommé ;
- oui, le bridge runtime n’est plus mensonger sur ce point ;
- oui, le moteur battle sait maintenant produire un crit réel minimal ;
- non, ce n’est pas un système de critiques Pokémon complet, et je le documente explicitement comme tel.

## 2. Pré-gates exécutés + résultats

Classification honnête du pré-gate : vert.

### Commandes exécutées avant code

- `git status --short`
- `git diff --stat`
- `git ls-files --others --exclude-standard`
- `cd packages/map_battle && /opt/homebrew/bin/dart test`
- `cd packages/map_battle && /opt/homebrew/bin/dart analyze`
- `cd packages/map_runtime && /opt/homebrew/bin/flutter test test/runtime_move_catalog_loader_test.dart test/runtime_pokemon_species_loader_test.dart test/runtime_pokemon_learnset_loader_test.dart test/runtime_battle_move_bridge_test.dart test/runtime_battle_combatant_seed_builder_test.dart test/runtime_battle_setup_mapper_test.dart test/runtime_battle_outcome_apply_test.dart test/wild_battle_end_to_end_flow_test.dart test/playable_map_game_whiteout_lite_test.dart`
- `cd packages/map_runtime && /opt/homebrew/bin/flutter analyze --no-pub lib/src/application/runtime_battle_move_bridge.dart lib/src/application/runtime_battle_combatant_seed_builder.dart lib/src/application/runtime_battle_setup_mapper.dart lib/src/application/runtime_pokemon_species_loader.dart test/runtime_battle_move_bridge_test.dart test/runtime_battle_combatant_seed_builder_test.dart test/runtime_battle_setup_mapper_test.dart test/runtime_move_catalog_loader_test.dart test/runtime_pokemon_species_loader_test.dart test/runtime_pokemon_learnset_loader_test.dart test/runtime_battle_outcome_apply_test.dart test/wild_battle_end_to_end_flow_test.dart test/playable_map_game_whiteout_lite_test.dart`

### Résultats

- `git status --short` : aucune ligne de sortie au pré-gate.
- `git diff --stat` : aucune ligne de sortie au pré-gate.
- `git ls-files --others --exclude-standard` : aucune ligne de sortie au pré-gate.
- `packages/map_battle` tests : vert.
- `packages/map_battle` analyze : vert.
- `packages/map_runtime` tests ciblés : vert.
- `packages/map_runtime` analyze ciblé : vert.

## 3. État initial audité réel

Avant BE6, le repo était dans cet état réel :
- `PokemonMove.critRatio` existait bien côté canonique et était validé comme strictement positif.
- le bridge runtime -> battle rejetait encore explicitement `critRatio != 1`.
- `BattleMoveData` et `BattleMove` ne transportaient pas `critRatio`.
- `BattleMoveExecution` n’exposait ni `didCrit`, ni `criticalMultiplier`.
- `map_battle` disposait déjà d’un vrai hit pipeline minimal, d’un RNG local injecté, d’un damage contract avec STAB/type/immunités, et d’une trace déjà plus honnête qu’avant.
- le moteur était donc mûr pour ouvrir un crit minimal réel sans devoir réécrire sa structure.

## 4. Problèmes confirmés / non confirmés

### Problèmes confirmés

- `critRatio` était bien encore décoratif ou rejeté à tort sur le chemin runtime normal.
- le bridge runtime -> battle mentait encore sur ce point : un move autrement supporté pouvait être rejeté uniquement à cause du crit.
- la trace d’exécution battle ne permettait pas de savoir honnêtement si un hit avait crit.
- le seam RNG battle existant couvrait le hit check, mais pas encore une chance rationnelle propre pour des tables de type `1/24`.

### Problèmes non confirmés

- je n’ai pas trouvé de besoin réel d’ouvrir un framework RNG général.
- je n’ai pas trouvé de raison saine d’ouvrir les règles avancées de critiques maintenant.
- je n’ai pas trouvé de justification à un clone battle de `PokemonMove`.

## 5. Cause racine réelle

La cause racine était simple : le chantier battle avait ouvert progressivement les couches nécessaires (PP, accuracy, STAB, type chart, ordre d’action), mais `critRatio` était resté bloqué entre deux mondes :
- suffisamment important pour ne plus pouvoir être honnêtement ignoré ;
- mais pas encore transporté ni consommé.
Autrement dit : le repo n’avait plus un problème de données, il avait un problème de contrat et de consommation moteur.

## 6. Décisions retenues / rejetées

### Décisions retenues

- transporter `critRatio` directement comme entier minimal dans `BattleMoveData` et `BattleMove` ;
- enrichir `BattleMoveExecution` avec `didCrit` et `criticalMultiplier` plutôt que d’essayer de déduire un crit via les dégâts ;
- ajouter un mini-seam RNG `nextChance(numerator, denominator)` pour éviter de trahir la table `1/24`, `1/8`, `1/2`, `1` avec des pourcentages arrondis ;
- utiliser une table explicite de stages critiques simplifiée : `1 -> 1/24`, `2 -> 1/8`, `3 -> 1/2`, `>=4 -> auto-crit` ;
- appliquer un multiplicateur critique fixe et explicite de `1.5` ;
- ne faire un roll critique que pour un hit offensif non immunisé.

### Décisions rejetées

- rejeter encore `critRatio != 1` au bridge : faux après BE4/BE5.
- ouvrir les règles avancées de critiques Pokémon : trop large et faux scope.
- simuler la table de crit avec `nextPercentRoll()` et des arrondis implicites : faisable, mais moins honnête sur `1/24`.
- introduire une structure battle miroir de `PokemonMove` : inutilement lourde.
- introduire un système générique d’événements RNG : hors proportion.

## 7. Critique explicite du prompt reçu

### Ce qui était juste

- le vrai trou post-BE5-mini-fix était bien `critRatio` ;
- le prompt forçait à rester petit, ce qui était sain ;
- la cible “crit simplifié mais honnête” était la bonne pour ce repo ;
- l’exigence d’une vraie trace battle était juste.

### Ce qui était discutable

- le prompt suggérait un ordre quasi canonique très précis, mais le repo réel n’avait pas besoin de consommer un roll critique avant de savoir si l’attaque était immunisée ; j’ai donc gardé un ordre mathématiquement équivalent pour le sous-ensemble actuel, mais plus sobre : hit check, immunité, puis crit ;
- le prompt laissait ouverte l’idée qu’on pouvait peut-être tout exprimer avec le seam RNG BE4 existant sans ajustement ; après audit, ce n’était pas le meilleur choix si on voulait éviter une table critique approximative.

### Ce qui aurait été dangereux si suivi aveuglément

- essayer de “faire comme Pokémon” sur les critiques complets aurait rouvert BE7 en douce ;
- forcer un pseudo-système complet de crits avec stages ignorés, items et abilities aurait créé un faux support ;
- traiter le multiplicateur critique comme un détail implicite du damage engine aurait entretenu une trace mensongère.

### Ce que j’ai recadré

- j’ai gardé un crit minimal réel, pas un crit complet Pokémon ;
- j’ai autorisé une extension locale du RNG pour exprimer proprement la table de crit ;
- j’ai choisi de résoudre l’immunité avant le roll critique pour éviter un tirage inutile sur un move qui n’aurait aucun effet.

### Pourquoi ce recadrage est meilleur pour ce repo réel

Parce qu’il ferme exactement le trou BE6 sans ouvrir un deuxième chantier caché. Le résultat est plus honnête que le rejet précédent, mais il reste strictement borné au moteur actuel.

## 8. Périmètre inclus / exclu

### Inclus

- transport de `critRatio` dans le contrat battle minimal ;
- consommation battle réelle de `critRatio` ;
- trace d’exécution enrichie sur le crit ;
- extension locale du RNG battle pour une chance rationnelle minimale ;
- tests battle/runtime ciblés ;
- report BE6.

### Exclu

- règles avancées de critique Pokémon ;
- status ;
- weather ;
- switch ;
- multi-hit ;
- random damage roll global ;
- items / abilities ;
- map_core ;
- map_editor.

## 9. Liste exacte des fichiers modifiés / créés / supprimés

### Modifiés

- `packages/map_battle/lib/src/battle_move.dart`
- `packages/map_battle/lib/src/battle_setup.dart`
- `packages/map_battle/lib/src/battle_resolution.dart`
- `packages/map_battle/lib/src/battle_rng.dart`
- `packages/map_battle/lib/src/battle_session.dart`
- `packages/map_battle/test/battle_session_test.dart`
- `packages/map_battle/test/battle_move_effects_test.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart`
- `packages/map_runtime/test/runtime_battle_move_bridge_test.dart`
- `packages/map_runtime/test/runtime_battle_combatant_seed_builder_test.dart`
- `packages/map_runtime/test/runtime_battle_setup_mapper_test.dart`

### Créé

- `reports/phase-battle-be6-crits-report.md`

### Supprimé

- aucun.

## 10. Justification fichier par fichier

- `packages/map_battle/lib/src/battle_move.dart` : ajout du transport minimal de `critRatio` dans le contrat move battle.
- `packages/map_battle/lib/src/battle_setup.dart` : ajout de `critRatio` au contrat de setup pour éviter sa perte au handoff.
- `packages/map_battle/lib/src/battle_resolution.dart` : ajout de `didCrit` et `criticalMultiplier` pour une trace honnête.
- `packages/map_battle/lib/src/battle_rng.dart` : ajout du plus petit seam utile pour exprimer proprement des chances rationnelles de critiques.
- `packages/map_battle/lib/src/battle_session.dart` : consommation réelle des critiques dans le pipeline battle.
- `packages/map_battle/test/battle_session_test.dart` : verrouillage de la propagation setup -> session et stabilisation explicite de tests qui vérifient autre chose que le crit.
- `packages/map_battle/test/battle_move_effects_test.dart` : preuves directes du comportement critique et des non-régressions utiles.
- `packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart` : arrêt du rejet artificiel de `critRatio != 1` et transport honnête vers battle.
- `packages/map_runtime/test/runtime_battle_move_bridge_test.dart` : inversion de la preuve côté bridge.
- `packages/map_runtime/test/runtime_battle_combatant_seed_builder_test.dart` : preuve que le seed builder préserve `critRatio`.
- `packages/map_runtime/test/runtime_battle_setup_mapper_test.dart` : preuve runtime -> battle -> session avec crit déterministe.
- `reports/phase-battle-be6-crits-report.md` : traçabilité du lot.

## 11. Commandes réellement exécutées

### Pré-gates

- `git status --short`
- `git diff --stat`
- `git ls-files --others --exclude-standard`
- `cd packages/map_battle && /opt/homebrew/bin/dart test`
- `cd packages/map_battle && /opt/homebrew/bin/dart analyze`
- `cd packages/map_runtime && /opt/homebrew/bin/flutter test test/runtime_move_catalog_loader_test.dart test/runtime_pokemon_species_loader_test.dart test/runtime_pokemon_learnset_loader_test.dart test/runtime_battle_move_bridge_test.dart test/runtime_battle_combatant_seed_builder_test.dart test/runtime_battle_setup_mapper_test.dart test/runtime_battle_outcome_apply_test.dart test/wild_battle_end_to_end_flow_test.dart test/playable_map_game_whiteout_lite_test.dart`
- `cd packages/map_runtime && /opt/homebrew/bin/flutter analyze --no-pub lib/src/application/runtime_battle_move_bridge.dart lib/src/application/runtime_battle_combatant_seed_builder.dart lib/src/application/runtime_battle_setup_mapper.dart lib/src/application/runtime_pokemon_species_loader.dart test/runtime_battle_move_bridge_test.dart test/runtime_battle_combatant_seed_builder_test.dart test/runtime_battle_setup_mapper_test.dart test/runtime_move_catalog_loader_test.dart test/runtime_pokemon_species_loader_test.dart test/runtime_pokemon_learnset_loader_test.dart test/runtime_battle_outcome_apply_test.dart test/wild_battle_end_to_end_flow_test.dart test/playable_map_game_whiteout_lite_test.dart`

### Audit ciblé

- lectures ciblées des fichiers battle/runtime/report mentionnés dans le prompt ;
- lecture ciblée de Showdown : `pokemon-showdown-master/sim/battle-actions.ts`, `pokemon-showdown-master/sim/dex-moves.ts`, `pokemon-showdown-master/data/moves.ts`.

### Validation intermédiaire

- `cd packages/map_battle && /opt/homebrew/bin/dart test test/battle_session_test.dart test/battle_move_effects_test.dart`
- `cd packages/map_runtime && /opt/homebrew/bin/flutter test test/runtime_battle_move_bridge_test.dart test/runtime_battle_combatant_seed_builder_test.dart test/runtime_battle_setup_mapper_test.dart`

### Format final

- `cd packages/map_battle && /opt/homebrew/bin/dart format lib/src/battle_setup.dart lib/src/battle_resolution.dart lib/src/battle_rng.dart lib/src/battle_session.dart test/battle_session_test.dart test/battle_move_effects_test.dart`
- `cd packages/map_runtime && /opt/homebrew/bin/dart format lib/src/application/runtime_battle_move_bridge.dart test/runtime_battle_move_bridge_test.dart test/runtime_battle_combatant_seed_builder_test.dart test/runtime_battle_setup_mapper_test.dart`

### Validation finale

- `cd packages/map_battle && /opt/homebrew/bin/dart analyze`
- `cd packages/map_battle && /opt/homebrew/bin/dart test`
- `cd packages/map_runtime && /opt/homebrew/bin/flutter analyze --no-pub lib/src/application/runtime_battle_move_bridge.dart lib/src/application/runtime_battle_combatant_seed_builder.dart lib/src/application/runtime_battle_setup_mapper.dart lib/src/application/runtime_pokemon_species_loader.dart test/runtime_battle_move_bridge_test.dart test/runtime_battle_combatant_seed_builder_test.dart test/runtime_battle_setup_mapper_test.dart test/runtime_move_catalog_loader_test.dart test/runtime_pokemon_species_loader_test.dart test/runtime_pokemon_learnset_loader_test.dart test/runtime_battle_outcome_apply_test.dart test/wild_battle_end_to_end_flow_test.dart test/playable_map_game_whiteout_lite_test.dart`
- `cd packages/map_runtime && /opt/homebrew/bin/flutter test test/runtime_move_catalog_loader_test.dart test/runtime_pokemon_species_loader_test.dart test/runtime_pokemon_learnset_loader_test.dart test/runtime_battle_move_bridge_test.dart test/runtime_battle_combatant_seed_builder_test.dart test/runtime_battle_setup_mapper_test.dart test/runtime_battle_outcome_apply_test.dart test/wild_battle_end_to_end_flow_test.dart test/playable_map_game_whiteout_lite_test.dart`

### Git read-only final

- `git status --short`
- `git diff --stat`
- `git ls-files --others --exclude-standard`

## 12. Résultats réels de format / analyze / tests

- format `packages/map_battle` : vert.
- format `packages/map_runtime` : vert.
- analyze `packages/map_battle` : `No issues found!`.
- analyze ciblé `packages/map_runtime` : `No issues found!`.
- tests `packages/map_battle` : `All tests passed!`.
- tests ciblés `packages/map_runtime` : `All tests passed!`.

## 13. Incidents rencontrés

- incident intermédiaire réel : les premiers tests ciblés rouges ont montré que l’ouverture des critiques rendait faux certains tests plus anciens qui supposaient implicitement “pas de crit” tout en vérifiant autre chose. Je les ai stabilisés avec un RNG scripté explicitement non critique, au lieu de neutraliser le moteur ;
- incident intermédiaire réel : quelques tests runtime utilisant `BattleScriptedRng` devaient être réalignés pour tenir compte de l’ordre d’action et du fait que l’ennemi pouvait consommer un roll critique avant le joueur ;
- incident agent réel : un reviewer séparé a expiré sans retour exploitable.

## 14. État git utile

### `git status --short`

```text
 M packages/map_battle/lib/src/battle_move.dart
 M packages/map_battle/lib/src/battle_resolution.dart
 M packages/map_battle/lib/src/battle_rng.dart
 M packages/map_battle/lib/src/battle_session.dart
 M packages/map_battle/lib/src/battle_setup.dart
 M packages/map_battle/test/battle_move_effects_test.dart
 M packages/map_battle/test/battle_session_test.dart
 M packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart
 M packages/map_runtime/test/runtime_battle_combatant_seed_builder_test.dart
 M packages/map_runtime/test/runtime_battle_move_bridge_test.dart
 M packages/map_runtime/test/runtime_battle_setup_mapper_test.dart
?? reports/phase-battle-be6-crits-report.md
```

### `git diff --stat`

```text
 packages/map_battle/lib/src/battle_move.dart       |  18 +-
 packages/map_battle/lib/src/battle_resolution.dart |  23 ++
 packages/map_battle/lib/src/battle_rng.dart        |  77 ++++-
 packages/map_battle/lib/src/battle_session.dart    | 135 ++++++++-
 packages/map_battle/lib/src/battle_setup.dart      |  14 +
 .../map_battle/test/battle_move_effects_test.dart  | 326 ++++++++++++++++++++-
 packages/map_battle/test/battle_session_test.dart  |  19 +-
 .../application/runtime_battle_move_bridge.dart    |  30 +-
 ...runtime_battle_combatant_seed_builder_test.dart |  30 +-
 .../test/runtime_battle_move_bridge_test.dart      |  23 +-
 .../test/runtime_battle_setup_mapper_test.dart     |  56 +++-
 11 files changed, 688 insertions(+), 63 deletions(-)
```

### `git ls-files --others --exclude-standard`

```text
reports/phase-battle-be6-crits-report.md
```

## 15. Checklist finale

- [x] j’ai audité le code réel avant de coder
- [x] j’ai challengé le prompt
- [x] je n’ai pas ouvert status/BE7 en douce
- [x] j’ai ajouté un vrai support battle de `critRatio`
- [x] j’ai ajouté une vraie trace de critique via `didCrit` et `criticalMultiplier`
- [x] j’ai gardé le scope petit et local
- [x] je n’ai pas touché `map_core`
- [x] je n’ai pas touché `map_editor`
- [x] je n’ai créé aucune stack parallèle
- [x] j’ai exécuté les pré-gates
- [x] j’ai exécuté format
- [x] j’ai exécuté analyze
- [x] j’ai exécuté les tests utiles
- [x] j’ai utilisé un sub-agent d’audit/design
- [x] j’ai utilisé un reviewer séparé
- [x] je n’ai fait aucune écriture Git interdite
- [x] le report est honnête
- [x] le report contient le contenu complet des fichiers touchés, hors le report lui-même pour éviter la récursion infinie

## 16. Retour du sub-agent d’audit/design

Agent utilisé : `Volta`.

Retour exploitable : oui.

Synthèse utile retenue :
- il a correctement identifié que le vrai lot devait vivre à deux niveaux : `critRatio` sur le contrat move et `didCrit`/`criticalMultiplier` sur l’exécution ;
- il a confirmé que le bridge runtime était le vrai point de blocage initial ;
- il a rappelé utilement qu’il ne fallait pas dériver vers les règles avancées de critiques.

Point non retenu tel quel :
- l’agent estimait que le RNG existant pouvait suffire sans extension ;
- j’ai rejeté ce point, parce qu’exprimer proprement `1/24` avec un simple pourcentage entier aurait réintroduit une approximation silencieuse.

## 17. Retour du reviewer séparé

- reviewer 1 sollicité : pas de retour exploitable dans la fenêtre d’attente ; incident documenté, rien inventé ;
- reviewer 2 sollicité : retour exploitable.

Retour du reviewer 2 :
- `aucun finding bloquant` ;
- dette légère seulement : pas de test direct sur les chemins d’erreur de `BattleRng.nextChance` (arguments invalides / séquence épuisée).

## 18. Corrections appliquées après review

- aucune correction de code supplémentaire après la review exploitable ;
- j’ai conservé la dette légère sur les chemins d’erreur de `BattleRng.nextChance` comme dette documentée, non bloquante pour BE6.

## 19. Autocritique finale

Ce qui est solide :
- le lot ferme un vrai trou moteur ;
- la sémantique simplifiée est explicite ;
- les non-régressions utiles ont été réellement relancées ;
- le bridge runtime cesse enfin de mentir sur `critRatio`.

Ce qui reste fragile ou limité :
- le système de critiques reste volontairement incomplet ;
- `BattleScriptedRng.nextChance` n’a pas encore de tests dédiés sur ses erreurs propres ;
- certains tests battle historiques avaient besoin d’un RNG explicitement non critique, ce qui montre qu’une partie du package testait implicitement des dégâts déterministes sans le déclarer.

Ce que je n’ai pas pu conclure avec certitude absolue :
- je n’ai pas prouvé que le mapping BE6 est le meilleur pour tous les futurs lots ; j’ai prouvé qu’il est petit, honnête et cohérent avec le repo actuel.

## 20. Annexe — contenu complet de tous les fichiers texte touchés

Note : le report s’exclut lui-même volontairement de cette annexe pour éviter la récursion infinie.

### packages/map_battle/lib/src/battle_move.dart

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
    this.critRatio = 1,
    this.selfStatStageChanges = const <BattleStatStageChange>[],
    this.targetStatStageChanges = const <BattleStatStageChange>[],
  }) : currentPp = currentPp ?? pp;

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
  final int critRatio;

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

### packages/map_battle/lib/src/battle_setup.dart

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
    this.critRatio = 1,
    this.selfStatStageChanges = const <BattleStatStageChange>[],
    this.targetStatStageChanges = const <BattleStatStageChange>[],
  });

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
  final int critRatio;

  /// Changements d'étages de stats appliqués au lanceur.
  final List<BattleStatStageChange> selfStatStageChanges;

  /// Changements d'étages de stats appliqués à la cible.
  final List<BattleStatStageChange> targetStatStageChanges;
}

```

### packages/map_battle/lib/src/battle_resolution.dart

```dart
import 'battle_action.dart';
import 'battle_move.dart';
import 'battle_state.dart';

/// Résultat d'un tour de combat.
///
/// Contient les actions jouées et leurs exécutions.
/// Utilisé pour afficher le déroulement du tour au joueur.
class BattleTurnResult {
  /// Crée un résultat de tour.
  ///
  /// [playerAction] - L'action jouée par le joueur.
  /// [enemyAction] - L'action jouée par l'ennemi.
  /// [executions] - La liste des exécutions d'attaques (dans l'ordre).
  const BattleTurnResult({
    required this.playerAction,
    required this.enemyAction,
    required this.executions,
  });

  /// L'action jouée par le joueur.
  final BattleAction playerAction;

  /// L'action jouée par l'ennemi.
  final BattleAction enemyAction;

  /// La liste des exécutions d'attaques.
  ///
  /// Ordonnées selon l'ordre de résolution (déterministe).
  /// Depuis BE3 :
  /// - priorité décroissante ;
  /// - puis vitesse effective décroissante ;
  /// - puis tie-break déterministe explicite.
  final List<BattleMoveExecution> executions;
}

/// Exécution d'une attaque.
///
/// Représente une attaque qui a été exécutée avec ses effets.
class BattleMoveExecution {
  /// Crée une exécution d'attaque.
  ///
  /// [attacker] - L'identifiant de l'attaquant ("player" ou "enemy").
  /// [move] - L'attaque utilisée.
  /// [target] - L'identifiant de la cible ("player" ou "enemy").
  /// [damage] - Les dégâts infligés.
  /// [didHit] - true si le move a réellement touché.
  /// [didCrit] - true si le move a réellement déclenché un critique.
  /// [criticalMultiplier] - Multiplicateur critique réellement appliqué.
  /// [stabMultiplier] - Multiplicateur STAB réellement consommé pour ce hit.
  /// [typeEffectivenessMultiplier] - Multiplicateur de type réellement appliqué.
  const BattleMoveExecution({
    required this.attacker,
    required this.move,
    required this.target,
    required this.damage,
    required this.didHit,
    this.didCrit = false,
    this.criticalMultiplier = 1.0,
    this.stabMultiplier = 1.0,
    this.typeEffectivenessMultiplier = 1.0,
  });

  /// L'identifiant de l'attaquant.
  ///
  /// Valeurs possibles : "player" ou "enemy".
  final String attacker;

  /// L'attaque utilisée.
  final BattleMove move;

  /// L'identifiant de la cible.
  ///
  /// Valeurs possibles : "player" ou "enemy".
  final String target;

  /// Les dégâts infligés.
  ///
  /// Après M8 puis BE4 :
  /// - un move de statut touché peut infliger `0` dégât ;
  /// - un move qui miss inflige aussi `0` dégât ;
  /// - un move de dégâts standards part toujours de `move.power` ;
  /// - des multiplicateurs simples issus des étages de stats peuvent modifier
  ///   ce montant ;
  /// - BE5 y ajoute STAB et efficacité de type ;
  /// - on reste néanmoins très loin d'une formule Pokémon complète.
  final int damage;

  /// true si le move a réellement touché.
  ///
  /// BE4 l'ajoute pour arrêter un autre mensonge silencieux :
  /// - `damage == 0` ne distingue pas un miss d'un move de statut ;
  /// - la trace d'exécution doit donc porter explicitement le hit/miss ;
  /// - on évite ainsi de forcer l'UI/runtime à deviner l'issue depuis un
  ///   contrat trop pauvre.
  final bool didHit;

  /// true si le move a réellement déclenché un critique.
  ///
  /// BE6 ajoute ce flag pour éviter une nouvelle perte de vérité :
  /// - un critique ne doit pas être deviné indirectement depuis les dégâts ;
  /// - le runtime/UI doit pouvoir distinguer un simple hit d'un vrai crit ;
  /// - un miss, une immunité ou un move de statut gardent toujours `false`.
  final bool didCrit;

  /// Multiplicateur critique réellement appliqué à ce move.
  ///
  /// Valeurs attendues dans BE6 :
  /// - `1.5` sur un critique déclenché ;
  /// - `1.0` sinon.
  ///
  /// Ce champ reste volontairement petit :
  /// - il documente l'effet réellement appliqué ;
  /// - il n'ouvre pas un système complet de règles avancées de critique.
  final double criticalMultiplier;

  /// Multiplicateur STAB réellement appliqué à ce move.
  ///
  /// Valeurs attendues dans BE5 :
  /// - `1.5` si l'attaquant partage le type du move ;
  /// - `1.0` sinon ;
  /// - `1.0` aussi sur les vieux call sites battle qui n'ont pas de typing.
  final double stabMultiplier;

  /// Multiplicateur d'efficacité de type réellement appliqué.
  ///
  /// Valeurs typiques BE5 :
  /// - `2.0`, `4.0` pour les faiblesses ;
  /// - `0.5`, `0.25` pour les résistances ;
  /// - `0.0` pour une immunité ;
  /// - `1.0` pour un cas neutre ou pour un vieux setup battle sans typing.
  ///
  /// Important :
  /// - `didHit == true` et `typeEffectivenessMultiplier == 0.0` signifient
  ///   "le move a bien passé le hit check, mais la cible y est immunisée" ;
  /// - cela évite de confondre immunité, miss et move de statut.
  final double typeEffectivenessMultiplier;
}

/// Type de résultat final d'un combat.
enum BattleOutcomeType {
  /// Le joueur a gagné (ennemi K.O.).
  victory,

  /// Le joueur a perdu (joueur K.O.).
  defeat,

  /// Le joueur a fui avec succès.
  runaway,

  /// Le joueur a capturé avec succès un Pokémon sauvage.
  ///
  /// Le lot 13 garde ce contrat volontairement petit :
  /// - l'issue termine immédiatement le combat ;
  /// - elle ne porte pas de formule de capture canonique ;
  /// - le runtime se charge ensuite d'écrire réellement le Pokémon capturé
  ///   dans la party/save du joueur.
  captured,
}

/// Résultat final d'un combat.
///
/// Contient le type de résultat et l'état final du combat.
/// Utilisé par le runtime pour déterminer les actions post-combat
/// (marquage trainer defeated, retour overworld, etc.).
class BattleOutcome {
  /// Crée un résultat de combat.
  ///
  /// [type] - Le type de résultat (victoire, défaite, fuite).
  /// [finalState] - L'état final du combat.
  const BattleOutcome({required this.type, required this.finalState});

  /// Le type de résultat.
  final BattleOutcomeType type;

  /// L'état final du combat.
  final BattleState finalState;

  /// true si le joueur a gagné.
  bool get isVictory => type == BattleOutcomeType.victory;

  /// true si le joueur a perdu.
  bool get isDefeat => type == BattleOutcomeType.defeat;

  /// true si le joueur a fui.
  bool get isRunaway => type == BattleOutcomeType.runaway;

  /// true si le joueur a capturé le Pokémon sauvage.
  bool get isCaptured => type == BattleOutcomeType.captured;
}

```

### packages/map_battle/lib/src/battle_rng.dart

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
    assert(numerator >= 0);
    assert(denominator >= 1);
    assert(numerator <= denominator);

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

### packages/map_battle/lib/src/battle_session.dart

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
    return switch (critRatio) {
      <= 1 => const _CritChance(numerator: 1, denominator: 24),
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

### packages/map_battle/test/battle_session_test.dart

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

```

### packages/map_battle/test/battle_move_effects_test.dart

```dart
import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

const _balancedStats = BattleStatsSnapshot(
  attack: 60,
  defense: 60,
  specialAttack: 60,
  specialDefense: 60,
  speed: 50,
);

BattleStatsSnapshot _stats({
  int attack = 60,
  int defense = 60,
  int specialAttack = 60,
  int specialDefense = 60,
  int speed = 50,
}) {
  return BattleStatsSnapshot(
    attack: attack,
    defense: defense,
    specialAttack: specialAttack,
    specialDefense: specialDefense,
    speed: speed,
  );
}

BattleTypingSnapshot _typing(
  String primaryType, [
  String? secondaryType,
]) {
  return BattleTypingSnapshot(
    primaryType: primaryType,
    secondaryType: secondaryType,
  );
}

void main() {
  group('BattleSession BE2/BE3/BE4/BE5/BE6 combat contract', () {
    test('createBattleSession preserves the resolved stats snapshot', () {
      final session = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'pikachu',
            level: 12,
            maxHp: 40,
            stats: _stats(
              attack: 16,
              defense: 14,
              specialAttack: 20,
              specialDefense: 18,
              speed: 15,
            ),
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'tackle',
                name: 'Tackle',
                power: 10,
                category: BattleMoveCategory.physical,
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'bulbasaur',
            level: 12,
            maxHp: 40,
            stats: _balancedStats,
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'growl',
                name: 'Growl',
                power: 0,
                category: BattleMoveCategory.status,
              ),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
      );

      expect(session.state.player.stats.attack, equals(16));
      expect(session.state.player.stats.specialAttack, equals(20));
      expect(session.state.player.stats.speed, equals(15));
    });

    test('physical damage uses attack versus defense', () {
      final weakAttacker = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'sproutle',
            level: 20,
            maxHp: 50,
            stats: _stats(attack: 40, defense: 60, specialAttack: 40),
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'slash',
                name: 'Slash',
                power: 50,
                category: BattleMoveCategory.physical,
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'aquafi',
            level: 20,
            maxHp: 80,
            stats: _stats(defense: 80),
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'growl',
                name: 'Growl',
                power: 0,
                category: BattleMoveCategory.status,
              ),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
      );

      final strongAttacker = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'sproutle',
            level: 20,
            maxHp: 50,
            stats: _stats(attack: 120, defense: 60, specialAttack: 40),
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'slash',
                name: 'Slash',
                power: 50,
                category: BattleMoveCategory.physical,
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'aquafi',
            level: 20,
            maxHp: 80,
            stats: _stats(defense: 80),
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'growl',
                name: 'Growl',
                power: 0,
                category: BattleMoveCategory.status,
              ),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
      );

      final weakAfterTurn =
          weakAttacker.applyChoice(const PlayerBattleChoiceFight(0));
      final strongAfterTurn =
          strongAttacker.applyChoice(const PlayerBattleChoiceFight(0));

      final weakDamage = 80 - weakAfterTurn.state.enemy.currentHp;
      final strongDamage = 80 - strongAfterTurn.state.enemy.currentHp;
      expect(strongDamage, greaterThan(weakDamage));
    });

    test('special damage uses specialAttack versus specialDefense', () {
      final weakSpecialAttacker = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'sparkitten',
            level: 20,
            maxHp: 50,
            stats: _stats(attack: 120, specialAttack: 40),
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'ember',
                name: 'Ember',
                power: 40,
                category: BattleMoveCategory.special,
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'aquafi',
            level: 20,
            maxHp: 80,
            stats: _stats(specialDefense: 90),
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'growl',
                name: 'Growl',
                power: 0,
                category: BattleMoveCategory.status,
              ),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
      );

      final strongSpecialAttacker = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'sparkitten',
            level: 20,
            maxHp: 50,
            stats: _stats(attack: 120, specialAttack: 120),
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'ember',
                name: 'Ember',
                power: 40,
                category: BattleMoveCategory.special,
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'aquafi',
            level: 20,
            maxHp: 80,
            stats: _stats(specialDefense: 90),
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'growl',
                name: 'Growl',
                power: 0,
                category: BattleMoveCategory.status,
              ),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
      );

      final weakAfterTurn =
          weakSpecialAttacker.applyChoice(const PlayerBattleChoiceFight(0));
      final strongAfterTurn =
          strongSpecialAttacker.applyChoice(const PlayerBattleChoiceFight(0));

      final weakDamage = 80 - weakAfterTurn.state.enemy.currentHp;
      final strongDamage = 80 - strongAfterTurn.state.enemy.currentHp;
      expect(strongDamage, greaterThan(weakDamage));
    });

    test('physical stages do not affect the special damage path', () {
      var neutralSession = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'sparkitten',
            level: 20,
            maxHp: 50,
            stats: _balancedStats,
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'leer',
                name: 'Leer',
                power: 0,
                category: BattleMoveCategory.status,
              ),
              BattleMoveData(
                id: 'ember',
                name: 'Ember',
                power: 40,
                category: BattleMoveCategory.special,
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'aquafi',
            level: 20,
            maxHp: 80,
            stats: _balancedStats,
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'scratch',
                name: 'Scratch',
                power: 0,
                category: BattleMoveCategory.status,
              ),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
      );
      var boostedPhysicalStageSession = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'sparkitten',
            level: 20,
            maxHp: 50,
            stats: _balancedStats,
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'swords_dance',
                name: 'Swords Dance',
                power: 0,
                category: BattleMoveCategory.status,
                target: BattleMoveTarget.self,
                selfStatStageChanges: <BattleStatStageChange>[
                  BattleStatStageChange(
                    stat: BattleStatId.attack,
                    stages: 2,
                  ),
                ],
              ),
              BattleMoveData(
                id: 'ember',
                name: 'Ember',
                power: 40,
                category: BattleMoveCategory.special,
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'aquafi',
            level: 20,
            maxHp: 80,
            stats: _balancedStats,
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'scratch',
                name: 'Scratch',
                power: 0,
                category: BattleMoveCategory.status,
              ),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
      );

      neutralSession =
          neutralSession.applyChoice(const PlayerBattleChoiceFight(0));
      boostedPhysicalStageSession = boostedPhysicalStageSession
          .applyChoice(const PlayerBattleChoiceFight(0));

      expect(neutralSession.state.player.statStages.attack, equals(0));
      expect(boostedPhysicalStageSession.state.player.statStages.attack,
          equals(2));

      final neutralAfterTurn =
          neutralSession.applyChoice(const PlayerBattleChoiceFight(1));
      final boostedAfterTurn = boostedPhysicalStageSession
          .applyChoice(const PlayerBattleChoiceFight(1));

      expect(
        boostedAfterTurn.state.enemy.currentHp,
        equals(neutralAfterTurn.state.enemy.currentHp),
      );
    });

    test('special stages do not affect the physical damage path', () {
      var neutralSession = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'sproutle',
            level: 20,
            maxHp: 50,
            stats: _balancedStats,
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'leer',
                name: 'Leer',
                power: 0,
                category: BattleMoveCategory.status,
              ),
              BattleMoveData(
                id: 'slash',
                name: 'Slash',
                power: 50,
                category: BattleMoveCategory.physical,
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'aquafi',
            level: 20,
            maxHp: 80,
            stats: _balancedStats,
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'growl',
                name: 'Growl',
                power: 0,
                category: BattleMoveCategory.status,
              ),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
      );
      var boostedSpecialStageSession = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'sproutle',
            level: 20,
            maxHp: 50,
            stats: _balancedStats,
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'nasty_plot',
                name: 'Nasty Plot',
                power: 0,
                category: BattleMoveCategory.status,
                target: BattleMoveTarget.self,
                selfStatStageChanges: <BattleStatStageChange>[
                  BattleStatStageChange(
                    stat: BattleStatId.specialAttack,
                    stages: 2,
                  ),
                ],
              ),
              BattleMoveData(
                id: 'slash',
                name: 'Slash',
                power: 50,
                category: BattleMoveCategory.physical,
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'aquafi',
            level: 20,
            maxHp: 80,
            stats: _balancedStats,
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'growl',
                name: 'Growl',
                power: 0,
                category: BattleMoveCategory.status,
              ),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
      );

      neutralSession =
          neutralSession.applyChoice(const PlayerBattleChoiceFight(0));
      boostedSpecialStageSession = boostedSpecialStageSession
          .applyChoice(const PlayerBattleChoiceFight(0));

      expect(neutralSession.state.player.statStages.specialAttack, equals(0));
      expect(
        boostedSpecialStageSession.state.player.statStages.specialAttack,
        equals(2),
      );

      final neutralAfterTurn =
          neutralSession.applyChoice(const PlayerBattleChoiceFight(1));
      final boostedAfterTurn = boostedSpecialStageSession
          .applyChoice(const PlayerBattleChoiceFight(1));

      expect(
        boostedAfterTurn.state.enemy.currentHp,
        equals(neutralAfterTurn.state.enemy.currentHp),
      );
    });

    test('status moves still inflict zero damage while speed can affect order',
        () {
      final session = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'pikachu',
            level: 20,
            maxHp: 40,
            stats: _stats(speed: 200),
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'growl',
                name: 'Growl',
                power: 0,
                category: BattleMoveCategory.status,
                targetStatStageChanges: <BattleStatStageChange>[
                  BattleStatStageChange(
                    stat: BattleStatId.attack,
                    stages: -1,
                  ),
                ],
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'bulbasaur',
            level: 20,
            maxHp: 40,
            stats: _stats(speed: 10),
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'growl',
                name: 'Growl',
                power: 0,
                category: BattleMoveCategory.status,
              ),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterTurn.state.enemy.currentHp, equals(40));
      expect(afterTurn.state.player.currentHp, equals(40));
      expect(afterTurn.state.player.stats.speed, equals(200));
      expect(afterTurn.state.enemy.stats.speed, equals(10));
      expect(
        afterTurn.state.currentTurn!.executions.first.attacker,
        equals('player'),
      );
    });

    test('higher priority acts before a faster opponent', () {
      final session = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'pikachu',
            level: 20,
            maxHp: 50,
            stats: _stats(speed: 20),
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'quick_attack',
                name: 'Quick Attack',
                power: 40,
                category: BattleMoveCategory.physical,
                priority: 1,
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'electrode',
            level: 20,
            maxHp: 50,
            stats: _stats(speed: 120),
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'tackle',
                name: 'Tackle',
                power: 40,
                category: BattleMoveCategory.physical,
              ),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterTurn.state.currentTurn!.executions.first.attacker, 'player');
    });

    test('enemy higher priority acts before a faster player', () {
      final session = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'pikachu',
            level: 20,
            maxHp: 50,
            stats: _stats(speed: 120),
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'tackle',
                name: 'Tackle',
                power: 40,
                category: BattleMoveCategory.physical,
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'electrode',
            level: 20,
            maxHp: 50,
            stats: _stats(speed: 20),
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'quick_attack',
                name: 'Quick Attack',
                power: 40,
                category: BattleMoveCategory.physical,
                priority: 1,
              ),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterTurn.state.currentTurn!.executions.first.attacker, 'enemy');
    });

    test('higher effective speed acts first at equal priority', () {
      final session = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'pikachu',
            level: 20,
            maxHp: 50,
            stats: _stats(speed: 120),
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'tackle',
                name: 'Tackle',
                power: 40,
                category: BattleMoveCategory.physical,
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'snorlax',
            level: 20,
            maxHp: 50,
            stats: _stats(speed: 20),
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'tackle',
                name: 'Tackle',
                power: 40,
                category: BattleMoveCategory.physical,
              ),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterTurn.state.currentTurn!.executions.first.attacker, 'player');
    });

    test(
        'equal priority and equal speed use the deterministic player tie-break',
        () {
      final session = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'pikachu',
            level: 20,
            maxHp: 50,
            stats: _stats(speed: 70),
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'tackle',
                name: 'Tackle',
                power: 40,
                category: BattleMoveCategory.physical,
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'eevee',
            level: 20,
            maxHp: 50,
            stats: _stats(speed: 70),
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'tackle',
                name: 'Tackle',
                power: 40,
                category: BattleMoveCategory.physical,
              ),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterTurn.state.currentTurn!.executions.first.attacker, 'player');
    });

    test('a self speed boost changes order only on the following turn', () {
      var session = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'pikachu',
            level: 20,
            maxHp: 70,
            stats: _stats(speed: 50),
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'agility',
                name: 'Agility',
                power: 0,
                category: BattleMoveCategory.status,
                target: BattleMoveTarget.self,
                selfStatStageChanges: <BattleStatStageChange>[
                  BattleStatStageChange(
                    stat: BattleStatId.speed,
                    stages: 2,
                  ),
                ],
              ),
              BattleMoveData(
                id: 'tackle',
                name: 'Tackle',
                power: 40,
                category: BattleMoveCategory.physical,
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'electrode',
            level: 20,
            maxHp: 70,
            stats: _stats(speed: 80),
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'tackle',
                name: 'Tackle',
                power: 5,
                category: BattleMoveCategory.physical,
              ),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
      );

      session = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(session.state.currentTurn!.executions.first.attacker, 'enemy');
      expect(session.state.player.statStages.speed, 2);

      session = session.applyChoice(const PlayerBattleChoiceFight(1));

      expect(session.state.currentTurn!.executions.first.attacker, 'player');
    });

    test('a target speed drop changes order only on the following turn', () {
      var session = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'pikachu',
            level: 20,
            maxHp: 70,
            stats: _stats(speed: 50),
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'scary_face',
                name: 'Scary Face',
                power: 0,
                category: BattleMoveCategory.status,
                target: BattleMoveTarget.opponent,
                targetStatStageChanges: <BattleStatStageChange>[
                  BattleStatStageChange(
                    stat: BattleStatId.speed,
                    stages: -2,
                  ),
                ],
              ),
              BattleMoveData(
                id: 'tackle',
                name: 'Tackle',
                power: 40,
                category: BattleMoveCategory.physical,
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'electrode',
            level: 20,
            maxHp: 70,
            stats: _stats(speed: 90),
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'tackle',
                name: 'Tackle',
                power: 5,
                category: BattleMoveCategory.physical,
              ),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
      );

      session = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(session.state.currentTurn!.executions.first.attacker, 'enemy');
      expect(session.state.enemy.statStages.speed, -2);

      session = session.applyChoice(const PlayerBattleChoiceFight(1));

      expect(session.state.currentTurn!.executions.first.attacker, 'player');
    });

    test('an alwaysHits move bypasses the hit check and still applies damage',
        () {
      final session = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'sproutle',
            level: 20,
            maxHp: 70,
            stats: _balancedStats,
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'swift',
                name: 'Swift',
                power: 40,
                category: BattleMoveCategory.special,
                accuracy: BattleMoveAccuracy.alwaysHits(),
                pp: 20,
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'electrode',
            level: 20,
            maxHp: 70,
            stats: _balancedStats,
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'growl',
                name: 'Growl',
                power: 0,
                category: BattleMoveCategory.status,
              ),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
        rng: const BattleScriptedRng(<int>[2]),
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));
      final execution = afterTurn.state.currentTurn!.executions.first;

      expect(execution.didHit, isTrue);
      expect(execution.damage, greaterThan(0));
      expect(afterTurn.state.player.moves.single.currentPp, equals(19));
    });

    test('a percent accuracy move can miss deterministically', () {
      final session = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'sproutle',
            level: 20,
            maxHp: 70,
            stats: _balancedStats,
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'mud_slap',
                name: 'Mud-Slap',
                power: 20,
                category: BattleMoveCategory.special,
                accuracy: BattleMoveAccuracy.percent(value: 50),
                pp: 10,
                targetStatStageChanges: <BattleStatStageChange>[
                  BattleStatStageChange(
                    stat: BattleStatId.specialDefense,
                    stages: -1,
                  ),
                ],
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'electrode',
            level: 20,
            maxHp: 70,
            stats: _balancedStats,
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'growl',
                name: 'Growl',
                power: 0,
                category: BattleMoveCategory.status,
              ),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
        rng: const BattleScriptedRng(<int>[100]),
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));
      final execution = afterTurn.state.currentTurn!.executions.first;

      expect(execution.didHit, isFalse);
      expect(execution.damage, equals(0));
      expect(afterTurn.state.enemy.currentHp, equals(70));
      expect(afterTurn.state.enemy.statStages.specialDefense, equals(0));
      expect(afterTurn.state.player.moves.single.currentPp, equals(9));
    });

    test('a percent accuracy move that hits still consumes one PP', () {
      final session = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'sproutle',
            level: 20,
            maxHp: 70,
            stats: _balancedStats,
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'ember',
                name: 'Ember',
                power: 40,
                category: BattleMoveCategory.special,
                accuracy: BattleMoveAccuracy.percent(value: 75),
                pp: 15,
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'electrode',
            level: 20,
            maxHp: 70,
            stats: _balancedStats,
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'growl',
                name: 'Growl',
                power: 0,
                category: BattleMoveCategory.status,
              ),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
        rng: const BattleScriptedRng(<int>[1, 2]),
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));
      final execution = afterTurn.state.currentTurn!.executions.first;

      expect(execution.didHit, isTrue);
      expect(execution.damage, greaterThan(0));
      expect(afterTurn.state.player.moves.single.currentPp, equals(14));
    });

    test('STAB increases damage for the same move and target', () {
      final withoutStab = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'caster',
            level: 20,
            maxHp: 70,
            stats: _balancedStats,
            typing: _typing('grass'),
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'ember',
                name: 'Ember',
                power: 40,
                type: 'fire',
                category: BattleMoveCategory.special,
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'target',
            level: 20,
            maxHp: 80,
            stats: _balancedStats,
            typing: _typing('grass'),
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'growl',
                name: 'Growl',
                power: 0,
                category: BattleMoveCategory.status,
              ),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
      );

      final withStab = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'caster',
            level: 20,
            maxHp: 70,
            stats: _balancedStats,
            typing: _typing('fire'),
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'ember',
                name: 'Ember',
                power: 40,
                type: 'fire',
                category: BattleMoveCategory.special,
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'target',
            level: 20,
            maxHp: 80,
            stats: _balancedStats,
            typing: _typing('grass'),
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'growl',
                name: 'Growl',
                power: 0,
                category: BattleMoveCategory.status,
              ),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
      );

      final neutralTurn =
          withoutStab.applyChoice(const PlayerBattleChoiceFight(0));
      final stabTurn = withStab.applyChoice(const PlayerBattleChoiceFight(0));
      final neutralExecution = neutralTurn.state.currentTurn!.executions.first;
      final stabExecution = stabTurn.state.currentTurn!.executions.first;

      expect(stabExecution.damage, greaterThan(neutralExecution.damage));
      expect(neutralExecution.stabMultiplier, equals(1.0));
      expect(stabExecution.stabMultiplier, equals(1.5));
      expect(stabExecution.typeEffectivenessMultiplier, equals(2.0));
    });

    test('super-effective damage is greater than neutral damage', () {
      final neutral = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'caster',
            level: 20,
            maxHp: 70,
            stats: _balancedStats,
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'ember',
                name: 'Ember',
                power: 40,
                type: 'fire',
                category: BattleMoveCategory.special,
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'neutral_target',
            level: 20,
            maxHp: 80,
            stats: _balancedStats,
            typing: _typing('normal'),
            moves: const <BattleMoveData>[
              BattleMoveData(id: 'growl', name: 'Growl', power: 0),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
      );

      final superEffective = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'caster',
            level: 20,
            maxHp: 70,
            stats: _balancedStats,
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'ember',
                name: 'Ember',
                power: 40,
                type: 'fire',
                category: BattleMoveCategory.special,
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'grass_target',
            level: 20,
            maxHp: 80,
            stats: _balancedStats,
            typing: _typing('grass'),
            moves: const <BattleMoveData>[
              BattleMoveData(id: 'growl', name: 'Growl', power: 0),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
      );

      final neutralExecution = neutral
          .applyChoice(const PlayerBattleChoiceFight(0))
          .state
          .currentTurn!
          .executions
          .first;
      final superExecution = superEffective
          .applyChoice(const PlayerBattleChoiceFight(0))
          .state
          .currentTurn!
          .executions
          .first;

      expect(superExecution.damage, greaterThan(neutralExecution.damage));
      expect(neutralExecution.typeEffectivenessMultiplier, equals(1.0));
      expect(superExecution.typeEffectivenessMultiplier, equals(2.0));
    });

    test('resisted damage is lower than neutral damage', () {
      final neutral = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'caster',
            level: 20,
            maxHp: 70,
            stats: _balancedStats,
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'ember',
                name: 'Ember',
                power: 40,
                type: 'fire',
                category: BattleMoveCategory.special,
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'neutral_target',
            level: 20,
            maxHp: 80,
            stats: _balancedStats,
            typing: _typing('normal'),
            moves: const <BattleMoveData>[
              BattleMoveData(id: 'growl', name: 'Growl', power: 0),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
      );

      final resisted = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'caster',
            level: 20,
            maxHp: 70,
            stats: _balancedStats,
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'ember',
                name: 'Ember',
                power: 40,
                type: 'fire',
                category: BattleMoveCategory.special,
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'water_target',
            level: 20,
            maxHp: 80,
            stats: _balancedStats,
            typing: _typing('water'),
            moves: const <BattleMoveData>[
              BattleMoveData(id: 'growl', name: 'Growl', power: 0),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
      );

      final neutralExecution = neutral
          .applyChoice(const PlayerBattleChoiceFight(0))
          .state
          .currentTurn!
          .executions
          .first;
      final resistedExecution = resisted
          .applyChoice(const PlayerBattleChoiceFight(0))
          .state
          .currentTurn!
          .executions
          .first;

      expect(resistedExecution.damage, lessThan(neutralExecution.damage));
      expect(resistedExecution.typeEffectivenessMultiplier, equals(0.5));
    });

    test('type immunity deals zero damage but still records a hit', () {
      final session = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'caster',
            level: 20,
            maxHp: 70,
            stats: _balancedStats,
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'thunder_shock',
                name: 'Thunder Shock',
                power: 40,
                type: 'electric',
                category: BattleMoveCategory.special,
                accuracy: BattleMoveAccuracy.alwaysHits(),
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'ground_target',
            level: 20,
            maxHp: 80,
            stats: _balancedStats,
            typing: _typing('ground'),
            moves: const <BattleMoveData>[
              BattleMoveData(id: 'growl', name: 'Growl', power: 0),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));
      final execution = afterTurn.state.currentTurn!.executions.first;

      expect(execution.didHit, isTrue);
      expect(execution.damage, equals(0));
      expect(execution.typeEffectivenessMultiplier, equals(0.0));
      expect(afterTurn.state.enemy.currentHp, equals(80));
    });

    test('double types combine multiplicatively for effectiveness', () {
      final singleWeakness = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'caster',
            level: 20,
            maxHp: 70,
            stats: _balancedStats,
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'water_gun',
                name: 'Water Gun',
                power: 40,
                type: 'water',
                category: BattleMoveCategory.special,
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'ground_target',
            level: 20,
            maxHp: 80,
            stats: _balancedStats,
            typing: _typing('ground'),
            moves: const <BattleMoveData>[
              BattleMoveData(id: 'growl', name: 'Growl', power: 0),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
      );

      final doubleWeakness = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'caster',
            level: 20,
            maxHp: 70,
            stats: _balancedStats,
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'water_gun',
                name: 'Water Gun',
                power: 40,
                type: 'water',
                category: BattleMoveCategory.special,
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'rock_ground_target',
            level: 20,
            maxHp: 80,
            stats: _balancedStats,
            typing: _typing('rock', 'ground'),
            moves: const <BattleMoveData>[
              BattleMoveData(id: 'growl', name: 'Growl', power: 0),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
      );

      final singleExecution = singleWeakness
          .applyChoice(const PlayerBattleChoiceFight(0))
          .state
          .currentTurn!
          .executions
          .first;
      final doubleExecution = doubleWeakness
          .applyChoice(const PlayerBattleChoiceFight(0))
          .state
          .currentTurn!
          .executions
          .first;

      expect(singleExecution.typeEffectivenessMultiplier, equals(2.0));
      expect(doubleExecution.typeEffectivenessMultiplier, equals(4.0));
      expect(doubleExecution.damage, greaterThan(singleExecution.damage));
    });

    test('a non-immune damaging move still deals at least 1 damage', () {
      final session = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'caster',
            level: 1,
            maxHp: 10,
            stats: _stats(
                attack: 1, defense: 1, specialAttack: 1, specialDefense: 1),
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'leaf_tap',
                name: 'Leaf Tap',
                power: 1,
                type: 'grass',
                category: BattleMoveCategory.special,
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'resistant_target',
            level: 50,
            maxHp: 200,
            stats: _stats(defense: 200, specialDefense: 200),
            typing: _typing('fire', 'flying'),
            moves: const <BattleMoveData>[
              BattleMoveData(id: 'growl', name: 'Growl', power: 0),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
      );

      final execution = session
          .applyChoice(const PlayerBattleChoiceFight(0))
          .state
          .currentTurn!
          .executions
          .first;

      expect(execution.typeEffectivenessMultiplier, equals(0.25));
      expect(execution.damage, equals(1));
    });

    test('neutral crit ratio can still resolve to no crit', () {
      final session = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'sproutle',
            level: 25,
            maxHp: 80,
            stats: _balancedStats,
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'slash',
                name: 'Slash',
                power: 60,
                category: BattleMoveCategory.physical,
                critRatio: 1,
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'dummy',
            level: 25,
            maxHp: 80,
            stats: _balancedStats,
            moves: const <BattleMoveData>[
              BattleMoveData(id: 'growl', name: 'Growl', power: 0),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
        rng: const BattleScriptedRng(<int>[2]),
      );

      final execution = session
          .applyChoice(const PlayerBattleChoiceFight(0))
          .state
          .currentTurn!
          .executions
          .first;

      expect(execution.didHit, isTrue);
      expect(execution.didCrit, isFalse);
      expect(execution.criticalMultiplier, equals(1.0));
    });

    test('high crit ratio can trigger a real critical hit', () {
      final baseline = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'sproutle',
            level: 25,
            maxHp: 80,
            stats: _balancedStats,
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'razor_leaf',
                name: 'Razor Leaf',
                power: 55,
                type: 'grass',
                category: BattleMoveCategory.physical,
                critRatio: 2,
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'dummy',
            level: 25,
            maxHp: 80,
            stats: _balancedStats,
            moves: const <BattleMoveData>[
              BattleMoveData(id: 'growl', name: 'Growl', power: 0),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
        rng: const BattleScriptedRng(<int>[2]),
      );

      final critical = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'sproutle',
            level: 25,
            maxHp: 80,
            stats: _balancedStats,
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'razor_leaf',
                name: 'Razor Leaf',
                power: 55,
                type: 'grass',
                category: BattleMoveCategory.physical,
                critRatio: 2,
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'dummy',
            level: 25,
            maxHp: 80,
            stats: _balancedStats,
            moves: const <BattleMoveData>[
              BattleMoveData(id: 'growl', name: 'Growl', power: 0),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
        rng: const BattleScriptedRng(<int>[1]),
      );

      final baselineExecution = baseline
          .applyChoice(const PlayerBattleChoiceFight(0))
          .state
          .currentTurn!
          .executions
          .first;
      final criticalExecution = critical
          .applyChoice(const PlayerBattleChoiceFight(0))
          .state
          .currentTurn!
          .executions
          .first;

      expect(baselineExecution.didCrit, isFalse);
      expect(criticalExecution.didCrit, isTrue);
      expect(criticalExecution.criticalMultiplier, equals(1.5));
      expect(criticalExecution.damage, greaterThan(baselineExecution.damage));
    });

    test('a miss never resolves a critical hit but still spends PP', () {
      final session = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'sproutle',
            level: 20,
            maxHp: 60,
            stats: _balancedStats,
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'mud_slap',
                name: 'Mud-Slap',
                power: 20,
                type: 'ground',
                category: BattleMoveCategory.special,
                accuracy: BattleMoveAccuracy.percent(value: 50),
                pp: 10,
                critRatio: 4,
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'dummy',
            level: 20,
            maxHp: 80,
            stats: _balancedStats,
            moves: const <BattleMoveData>[
              BattleMoveData(id: 'growl', name: 'Growl', power: 0),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
        rng: const BattleScriptedRng(<int>[100]),
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));
      final execution = afterTurn.state.currentTurn!.executions.first;

      expect(execution.didHit, isFalse);
      expect(execution.didCrit, isFalse);
      expect(execution.criticalMultiplier, equals(1.0));
      expect(execution.damage, equals(0));
      expect(afterTurn.state.player.moves.single.currentPp, equals(9));
    });

    test('an immune hit never resolves a critical hit', () {
      final session = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'sparkitten',
            level: 25,
            maxHp: 70,
            stats: _balancedStats,
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'thunderbolt',
                name: 'Thunderbolt',
                power: 40,
                type: 'electric',
                category: BattleMoveCategory.special,
                accuracy: BattleMoveAccuracy.alwaysHits(),
                critRatio: 4,
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'ground_target',
            level: 25,
            maxHp: 80,
            stats: _balancedStats,
            typing: _typing('ground'),
            moves: const <BattleMoveData>[
              BattleMoveData(id: 'growl', name: 'Growl', power: 0),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
        rng: const BattleScriptedRng(<int>[]),
      );

      final execution = session
          .applyChoice(const PlayerBattleChoiceFight(0))
          .state
          .currentTurn!
          .executions
          .first;

      expect(execution.didHit, isTrue);
      expect(execution.didCrit, isFalse);
      expect(execution.criticalMultiplier, equals(1.0));
      expect(execution.damage, equals(0));
      expect(execution.typeEffectivenessMultiplier, equals(0.0));
    });

    test('a status move never resolves a critical hit', () {
      final session = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'sproutle',
            level: 20,
            maxHp: 60,
            stats: _balancedStats,
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'growl',
                name: 'Growl',
                power: 0,
                category: BattleMoveCategory.status,
                critRatio: 4,
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'dummy',
            level: 20,
            maxHp: 80,
            stats: _balancedStats,
            moves: const <BattleMoveData>[
              BattleMoveData(id: 'growl', name: 'Growl', power: 0),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
        rng: const BattleScriptedRng(<int>[]),
      );

      final execution = session
          .applyChoice(const PlayerBattleChoiceFight(0))
          .state
          .currentTurn!
          .executions
          .first;

      expect(execution.didHit, isTrue);
      expect(execution.didCrit, isFalse);
      expect(execution.criticalMultiplier, equals(1.0));
      expect(execution.damage, equals(0));
    });

    test('crit ratio >= 4 guarantees a critical hit without consuming RNG', () {
      final session = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'sproutle',
            level: 20,
            maxHp: 60,
            stats: _balancedStats,
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'leaf_blade',
                name: 'Leaf Blade',
                power: 50,
                type: 'grass',
                category: BattleMoveCategory.physical,
                critRatio: 4,
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'dummy',
            level: 20,
            maxHp: 80,
            stats: _balancedStats,
            moves: const <BattleMoveData>[
              BattleMoveData(id: 'growl', name: 'Growl', power: 0),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
        rng: const BattleScriptedRng(<int>[]),
      );

      final execution = session
          .applyChoice(const PlayerBattleChoiceFight(0))
          .state
          .currentTurn!
          .executions
          .first;

      expect(execution.didHit, isTrue);
      expect(execution.didCrit, isTrue);
      expect(execution.criticalMultiplier, equals(1.5));
      expect(execution.damage, greaterThan(0));
    });
  });
}

```

### packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart

```dart
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';

import 'runtime_battle_setup_exception.dart';

/// Bridge runtime -> battle pour un sous-ensemble honnête de `PokemonMove`.
///
/// Frontière volontaire de M8 :
/// - le loader runtime charge le canonique sans faire de policy d'exécution ;
/// - ce bridge décide si un move canonique peut être projeté honnêtement vers
///   le moteur battle MVP actuel ;
/// - `map_battle` exécute ensuite uniquement ce petit contrat battle enrichi.
///
/// Le but n'est pas de "supporter un peu tout" :
/// - on garde le standard damage flow ;
/// - on supporte `modifyStats` déterministe pour un petit sous-ensemble utile ;
/// - on refuse explicitement le reste.
///
/// BE1 durcit ce bridge sur un autre axe :
/// - certaines dimensions canoniques étaient encore perdues silencieusement ;
/// - on transporte maintenant le petit supplément de contrat battle qui évite
///   cette perte (`type`, `target`, `pp`) ;
/// - et on refuse explicitement les dimensions non neutres qui resteraient
///   encore mensongères sans nouvelle couche moteur (`priority`, cibles hors
///   1v1 simple honnête).
///
/// BE3 recadre ensuite ce point :
/// - `priority` n'est plus refusée, parce que `map_battle` sait enfin
///   ordonner honnêtement deux actions `Fight` ;
/// - `speed` stage devient également supportée pour ce même besoin ;
/// - puis BE4 ouvre enfin l'accuracy battle minimale et les PP réels ;
/// - puis BE6 ouvre enfin un crit minimal honnête via `critRatio` ;
/// - le reste reste explicitement hors scope et donc refusé.
class RuntimeBattleMoveBridge {
  const RuntimeBattleMoveBridge();

  /// Projette un move canonique vers le contrat `BattleMoveData`.
  ///
  /// Le refus est explicite et descriptif :
  /// - pas de fallback silencieux ;
  /// - pas de `power: 0` mensonger pour un move que le moteur n'exécute pas ;
  /// - pas de mutation opportuniste de `engineSupportLevel`.
  BattleMoveData toBattleMoveData({
    required PokemonMove move,
    required String combatantLabel,
  }) {
    _ensureEngineSupportLevelAllowsBridge(
      move: move,
      combatantLabel: combatantLabel,
    );
    final target = _translateSupportedTarget(
      move: move,
      combatantLabel: combatantLabel,
    );
    final type = _translateType(
      move: move,
      combatantLabel: combatantLabel,
    );
    final accuracy = _translateAccuracy(move.accuracy);

    final selfChanges = <BattleStatStageChange>[];
    final targetChanges = <BattleStatStageChange>[];

    for (final effect in move.effects) {
      effect.map(
        fixedDamage: (_) => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_effect_kind:fixed_damage',
        ),
        multiHit: (_) => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_effect_kind:multi_hit',
        ),
        applyStatus: (_) => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_effect_kind:apply_status',
        ),
        applyVolatileStatus: (_) => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_effect_kind:apply_volatile_status',
        ),
        modifyStats: (effect) {
          if (effect.chance != null) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'probabilistic_modify_stats_not_supported',
            );
          }
          if (effect.stageChanges.isEmpty) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'empty_modify_stats_not_supported',
            );
          }

          final translated = effect.stageChanges
              .map(
                (change) => _translateStageChange(
                  change: change,
                  move: move,
                  combatantLabel: combatantLabel,
                ),
              )
              .toList(growable: false);

          switch (effect.targetScope) {
            case PokemonMoveEffectTargetScope.self:
              selfChanges.addAll(translated);
            case PokemonMoveEffectTargetScope.target:
              targetChanges.addAll(translated);
            case PokemonMoveEffectTargetScope.field:
            case PokemonMoveEffectTargetScope.allySide:
            case PokemonMoveEffectTargetScope.foeSide:
            case PokemonMoveEffectTargetScope.slot:
              _rejectMove(
                move: move,
                combatantLabel: combatantLabel,
                bridgeLimit:
                    'unsupported_modify_stats_scope:${effect.targetScope.name}',
              );
          }
        },
        heal: (_) => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_effect_kind:heal',
        ),
        drain: (_) => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_effect_kind:drain',
        ),
        recoil: (_) => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_effect_kind:recoil',
        ),
        setWeather: (_) => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_effect_kind:set_weather',
        ),
        setTerrain: (_) => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_effect_kind:set_terrain',
        ),
        setPseudoWeather: (_) => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_effect_kind:set_pseudo_weather',
        ),
        selfSwitch: (_) => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_effect_kind:self_switch',
        ),
        forceSwitch: (_) => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_effect_kind:force_switch',
        ),
        breakProtect: (_) => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_effect_kind:break_protect',
        ),
        requireRecharge: (_) => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_effect_kind:require_recharge',
        ),
        chargeThenStrike: (_) => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_effect_kind:charge_then_strike',
        ),
        setSideCondition: (_) => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_effect_kind:set_side_condition',
        ),
        setSlotCondition: (_) => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_effect_kind:set_slot_condition',
        ),
      );
    }

    // Un move battle exécutable doit avoir au moins un chemin d'exécution
    // réel pour le moteur actuel :
    // - soit des dégâts standards ;
    // - soit des changements d'étages de stats déterministes ;
    // - soit les deux.
    if (!move.usesStandardDamageFlow &&
        selfChanges.isEmpty &&
        targetChanges.isEmpty) {
      _rejectMove(
        move: move,
        combatantLabel: combatantLabel,
        bridgeLimit: 'no_supported_execution_path',
      );
    }

    // Le moteur battle actuel sait seulement :
    // - infliger des dégâts à l'adversaire actif ;
    // - ou appliquer des boosts/baisses déterministes sur `self` / target.
    //
    // Un move auto-ciblé qui ferait malgré tout des dégâts standards serait
    // donc encore projeté mensongèrement : `map_battle` le résoudrait contre
    // l'adversaire faute de vrai contrat "self damage".
    //
    // On préfère refuser explicitement ce cas tant qu'un lot ultérieur n'ouvre
    // pas une sémantique battle claire pour ce type d'exécution.
    if (move.usesStandardDamageFlow && target == BattleMoveTarget.self) {
      _rejectMove(
        move: move,
        combatantLabel: combatantLabel,
        bridgeLimit: 'unsupported_standard_damage_target:self',
      );
    }

    return BattleMoveData(
      id: move.id,
      name: move.name,
      power: move.usesStandardDamageFlow ? move.basePower : 0,
      type: type,
      category: _translateCategory(move.category),
      target: target,
      accuracy: accuracy,
      pp: move.pp,
      priority: move.priority,
      critRatio: move.critRatio,
      selfStatStageChanges:
          List<BattleStatStageChange>.unmodifiable(selfChanges),
      targetStatStageChanges:
          List<BattleStatStageChange>.unmodifiable(targetChanges),
    );
  }

  void _ensureEngineSupportLevelAllowsBridge({
    required PokemonMove move,
    required String combatantLabel,
  }) {
    if (move.engineSupportLevel ==
        PokemonMoveEngineSupportLevel.structuredSupported) {
      return;
    }
    _rejectMove(
      move: move,
      combatantLabel: combatantLabel,
      bridgeLimit: 'engine_support_level_not_bridgeable',
    );
  }

  BattleMoveAccuracy _translateAccuracy(PokemonMoveAccuracy accuracy) {
    return accuracy.map(
      percent: (accuracy) => BattleMoveAccuracy.percent(value: accuracy.value),
      alwaysHits: (_) => const BattleMoveAccuracy.alwaysHits(),
    );
  }

  String _translateType({
    required PokemonMove move,
    required String combatantLabel,
  }) {
    final normalizedType = move.type.trim().toLowerCase();
    if (normalizedType.isEmpty) {
      _rejectMove(
        move: move,
        combatantLabel: combatantLabel,
        bridgeLimit: 'invalid_type:empty',
      );
    }

    // Même règle qu'au chargement des espèces :
    // - la liste des types réellement supportés ne doit vivre qu'à un seul
    //   endroit ;
    // - le bridge réutilise donc `BattleTypeChart.supportedTypes` au lieu de
    //   maintenir une seconde liste locale ;
    // - cela permet de rejeter le move au bon seam runtime -> battle, avec
    //   une erreur actionnable, plutôt que de laisser `map_battle` exploser
    //   plus tard par `StateError`.
    if (!BattleTypeChart.supportedTypes.contains(normalizedType)) {
      _rejectMove(
        move: move,
        combatantLabel: combatantLabel,
        bridgeLimit: 'unsupported_type:$normalizedType',
      );
    }

    return normalizedType;
  }

  BattleMoveCategory _translateCategory(PokemonMoveCategory category) {
    return switch (category) {
      PokemonMoveCategory.physical => BattleMoveCategory.physical,
      PokemonMoveCategory.special => BattleMoveCategory.special,
      PokemonMoveCategory.status => BattleMoveCategory.status,
    };
  }

  BattleMoveTarget _translateSupportedTarget({
    required PokemonMove move,
    required String combatantLabel,
  }) {
    // BE1 ne promet toujours pas un système de targeting complet.
    // En revanche, on peut déjà arrêter de perdre silencieusement l'intention
    // canonique quand elle reste honnête en 1v1 simple actif :
    // - `self` -> self ;
    // - `normal`, `adjacentFoe`, `allAdjacentFoes`, `randomNormal`
    //   -> opponent.
    //
    // Les autres formes (`all`, `allySide`, `foeSide`, etc.) exigent une
    // sémantique de terrain/sides/slots ou de multibattle absente aujourd'hui.
    return switch (move.target) {
      PokemonMoveTarget.self => BattleMoveTarget.self,
      PokemonMoveTarget.normal ||
      PokemonMoveTarget.adjacentFoe ||
      PokemonMoveTarget.allAdjacentFoes ||
      PokemonMoveTarget.randomNormal =>
        BattleMoveTarget.opponent,
      _ => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_target:${move.target.name}',
        ),
    };
  }

  BattleStatStageChange _translateStageChange({
    required PokemonMoveStatStageChange change,
    required PokemonMove move,
    required String combatantLabel,
  }) {
    final stat = switch (change.stat) {
      PokemonMoveStatId.attack => BattleStatId.attack,
      PokemonMoveStatId.defense => BattleStatId.defense,
      PokemonMoveStatId.specialAttack => BattleStatId.specialAttack,
      PokemonMoveStatId.specialDefense => BattleStatId.specialDefense,
      // BE3 ouvre ici la plus petite extension honnête possible :
      // - `speed` stage devient enfin utile car le moteur ordonne désormais
      //   les deux actions `Fight` par vitesse effective ;
      // - on ne profite pas de cette ouverture pour accepter accuracy/evasion,
      //   qui resteraient mensongères sans hit pipeline réel.
      PokemonMoveStatId.speed => BattleStatId.speed,
      PokemonMoveStatId.accuracy => _rejectUnsupportedStat(
          move: move,
          combatantLabel: combatantLabel,
          stat: change.stat,
        ),
      PokemonMoveStatId.evasion => _rejectUnsupportedStat(
          move: move,
          combatantLabel: combatantLabel,
          stat: change.stat,
        ),
    };

    return BattleStatStageChange(
      stat: stat,
      stages: change.stages,
    );
  }

  Never _rejectUnsupportedStat({
    required PokemonMove move,
    required String combatantLabel,
    required PokemonMoveStatId stat,
  }) {
    _rejectMove(
      move: move,
      combatantLabel: combatantLabel,
      bridgeLimit: 'unsupported_stat_stage:${stat.name}',
    );
  }

  Never _rejectMove({
    required PokemonMove move,
    required String combatantLabel,
    required String bridgeLimit,
  }) {
    final unsupportedReasons = move.unsupportedReasons.isEmpty
        ? '[]'
        : '[${move.unsupportedReasons.join(', ')}]';
    throw RuntimeBattleSetupException(
      'Le combat ne peut pas démarrer car "$combatantLabel" utilise une attaque que le bridge battle actuel ne sait pas projeter honnêtement.',
      debugDetails:
          'combatant=$combatantLabel, moveId=${move.id}, moveName=${move.name}, engineSupportLevel=${move.engineSupportLevel.name}, unsupportedReasons=$unsupportedReasons, bridgeLimit=$bridgeLimit',
    );
  }
}

```

### packages/map_runtime/test/runtime_battle_move_bridge_test.dart

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_battle_move_bridge.dart';
import 'package:map_runtime/src/application/runtime_battle_setup_exception.dart';

void main() {
  group('RuntimeBattleMoveBridge', () {
    const bridge = RuntimeBattleMoveBridge();

    test('projects a standard damage move without destroying canonical data',
        () {
      const move = PokemonMove(
        id: 'vine_whip',
        name: 'Vine Whip',
        names: <String, String>{'en': 'Vine Whip'},
        generation: 1,
        source: 'test',
        type: 'grass',
        category: PokemonMoveCategory.physical,
        target: PokemonMoveTarget.normal,
        basePower: 45,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        pp: 25,
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.id, equals('vine_whip'));
      expect(battleMove.power, equals(45));
      expect(battleMove.type, equals('grass'));
      expect(battleMove.category, equals(BattleMoveCategory.physical));
      expect(battleMove.target, equals(BattleMoveTarget.opponent));
      expect(
        battleMove.accuracy.kind,
        equals(BattleMoveAccuracyKind.percent),
      );
      expect(battleMove.accuracy.value, equals(100));
      expect(battleMove.pp, equals(25));
      expect(battleMove.selfStatStageChanges, isEmpty);
      expect(battleMove.targetStatStageChanges, isEmpty);
    });

    test('projects a deterministic target stat drop move honestly', () {
      const move = PokemonMove(
        id: 'growl',
        name: 'Growl',
        names: <String, String>{'en': 'Growl'},
        generation: 1,
        source: 'test',
        type: 'normal',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.allAdjacentFoes,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        pp: 40,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.modifyStats(
            targetScope: PokemonMoveEffectTargetScope.target,
            stageChanges: <PokemonMoveStatStageChange>[
              PokemonMoveStatStageChange(
                stat: PokemonMoveStatId.attack,
                stages: -1,
              ),
            ],
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.power, equals(0));
      expect(battleMove.type, equals('normal'));
      expect(battleMove.category, equals(BattleMoveCategory.status));
      expect(battleMove.target, equals(BattleMoveTarget.opponent));
      expect(battleMove.pp, equals(40));
      expect(battleMove.selfStatStageChanges, isEmpty);
      expect(battleMove.targetStatStageChanges, hasLength(1));
      expect(
        battleMove.targetStatStageChanges.single.stat,
        equals(BattleStatId.attack),
      );
      expect(
        battleMove.targetStatStageChanges.single.stages,
        equals(-1),
      );
    });

    test('projects a deterministic self stat boost move honestly', () {
      const move = PokemonMove(
        id: 'swords_dance',
        name: 'Swords Dance',
        names: <String, String>{'en': 'Swords Dance'},
        generation: 1,
        source: 'test',
        type: 'normal',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.self,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
        pp: 20,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.modifyStats(
            targetScope: PokemonMoveEffectTargetScope.self,
            stageChanges: <PokemonMoveStatStageChange>[
              PokemonMoveStatStageChange(
                stat: PokemonMoveStatId.attack,
                stages: 2,
              ),
            ],
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.power, equals(0));
      expect(battleMove.selfStatStageChanges, hasLength(1));
      expect(
        battleMove.selfStatStageChanges.single.stat,
        equals(BattleStatId.attack),
      );
      expect(
        battleMove.selfStatStageChanges.single.stages,
        equals(2),
      );
      expect(battleMove.target, equals(BattleMoveTarget.self));
      expect(battleMove.pp, equals(20));
      expect(battleMove.targetStatStageChanges, isEmpty);
    });

    test(
        'rejects a self-target damage move that map_battle would still resolve against the opponent',
        () {
      const move = PokemonMove(
        id: 'mind_blown_self',
        name: 'Mind Blown Self',
        names: <String, String>{'en': 'Mind Blown Self'},
        generation: 9,
        source: 'test',
        type: 'fire',
        category: PokemonMoveCategory.special,
        target: PokemonMoveTarget.self,
        basePower: 50,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        pp: 5,
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      expect(
        () => bridge.toBattleMoveData(
          move: move,
          combatantLabel: 'Le Pokémon actif du joueur',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            allOf(
              contains('moveId=mind_blown_self'),
              contains('bridgeLimit=unsupported_standard_damage_target:self'),
            ),
          ),
        ),
      );
    });

    test(
        'projects a move with non-zero priority once battle order consumes it honestly',
        () {
      const move = PokemonMove(
        id: 'quick_attack',
        name: 'Quick Attack',
        names: <String, String>{'en': 'Quick Attack'},
        generation: 1,
        source: 'test',
        type: 'normal',
        category: PokemonMoveCategory.physical,
        target: PokemonMoveTarget.normal,
        basePower: 40,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        pp: 30,
        priority: 1,
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.id, equals('quick_attack'));
      expect(battleMove.priority, equals(1));
      expect(battleMove.power, equals(40));
      expect(battleMove.target, equals(BattleMoveTarget.opponent));
    });

    test('projects a deterministic speed boost move honestly', () {
      const move = PokemonMove(
        id: 'agility',
        name: 'Agility',
        names: <String, String>{'en': 'Agility'},
        generation: 1,
        source: 'test',
        type: 'psychic',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.self,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
        pp: 30,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.modifyStats(
            targetScope: PokemonMoveEffectTargetScope.self,
            stageChanges: <PokemonMoveStatStageChange>[
              PokemonMoveStatStageChange(
                stat: PokemonMoveStatId.speed,
                stages: 2,
              ),
            ],
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.power, equals(0));
      expect(battleMove.target, equals(BattleMoveTarget.self));
      expect(battleMove.selfStatStageChanges, hasLength(1));
      expect(
        battleMove.selfStatStageChanges.single.stat,
        equals(BattleStatId.speed),
      );
      expect(
        battleMove.selfStatStageChanges.single.stages,
        equals(2),
      );
    });

    test(
        'projects a move with non-trivial percent accuracy once battle owns the hit check',
        () {
      const move = PokemonMove(
        id: 'fire_blast',
        name: 'Fire Blast',
        names: <String, String>{'en': 'Fire Blast'},
        generation: 1,
        source: 'test',
        type: 'fire',
        category: PokemonMoveCategory.special,
        target: PokemonMoveTarget.normal,
        basePower: 110,
        accuracy: PokemonMoveAccuracy.percent(value: 85),
        pp: 5,
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.id, equals('fire_blast'));
      expect(
        battleMove.accuracy.kind,
        equals(BattleMoveAccuracyKind.percent),
      );
      expect(battleMove.accuracy.value, equals(85));
      expect(battleMove.pp, equals(5));
    });

    test(
        'rejects a move whose type is not actually supported by the current battle type chart',
        () {
      const move = PokemonMove(
        id: 'typo_bolt',
        name: 'Typo Bolt',
        names: <String, String>{'en': 'Typo Bolt'},
        generation: 1,
        source: 'test',
        type: 'electrik',
        category: PokemonMoveCategory.special,
        target: PokemonMoveTarget.normal,
        basePower: 80,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        pp: 15,
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      expect(
        () => bridge.toBattleMoveData(
          move: move,
          combatantLabel: 'Le Pokémon actif du joueur',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            allOf(
              contains('moveId=typo_bolt'),
              contains('moveName=Typo Bolt'),
              contains('bridgeLimit=unsupported_type:electrik'),
            ),
          ),
        ),
      );
    });

    test(
        'accepts a move whose non-neutral crit ratio is now transported honestly to battle',
        () {
      const move = PokemonMove(
        id: 'razor_leaf',
        name: 'Razor Leaf',
        names: <String, String>{'en': 'Razor Leaf'},
        generation: 1,
        source: 'test',
        type: 'grass',
        category: PokemonMoveCategory.physical,
        target: PokemonMoveTarget.allAdjacentFoes,
        basePower: 55,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        pp: 25,
        critRatio: 2,
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.id, equals('razor_leaf'));
      expect(battleMove.critRatio, equals(2));
    });

    test(
        'rejects a target shape that is still outside the honest 1v1 bridge subset',
        () {
      const move = PokemonMove(
        id: 'stealth_rock',
        name: 'Stealth Rock',
        names: <String, String>{'en': 'Stealth Rock'},
        generation: 4,
        source: 'test',
        type: 'rock',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.foeSide,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
        pp: 20,
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      expect(
        () => bridge.toBattleMoveData(
          move: move,
          combatantLabel: 'Le Pokémon actif du joueur',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            allOf(
              contains('moveId=stealth_rock'),
              contains('bridgeLimit=unsupported_target:foeSide'),
            ),
          ),
        ),
      );
    });

    test('rejects a status move that needs a real battle status system', () {
      const move = PokemonMove(
        id: 'thunder_wave',
        name: 'Thunder Wave',
        names: <String, String>{'en': 'Thunder Wave'},
        generation: 1,
        source: 'test',
        type: 'electric',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.normal,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        pp: 20,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.applyStatus(
            targetScope: PokemonMoveEffectTargetScope.target,
            statusId: 'par',
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      expect(
        () => bridge.toBattleMoveData(
          move: move,
          combatantLabel: 'Le Pokémon actif du joueur',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            allOf(
              contains('moveId=thunder_wave'),
              contains('engineSupportLevel=structuredSupported'),
              contains('bridgeLimit=unsupported_effect_kind:apply_status'),
            ),
          ),
        ),
      );
    });

    test('rejects a probabilistic secondary effect that would lie without RNG',
        () {
      const move = PokemonMove(
        id: 'thunderbolt',
        name: 'Thunderbolt',
        names: <String, String>{'en': 'Thunderbolt'},
        generation: 1,
        source: 'test',
        type: 'electric',
        category: PokemonMoveCategory.special,
        target: PokemonMoveTarget.normal,
        basePower: 90,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        pp: 15,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.applyStatus(
            targetScope: PokemonMoveEffectTargetScope.target,
            chance: 10,
            statusId: 'par',
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      expect(
        () => bridge.toBattleMoveData(
          move: move,
          combatantLabel: 'Le Pokémon actif du joueur',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            allOf(
              contains('moveId=thunderbolt'),
              contains('bridgeLimit=unsupported_effect_kind:apply_status'),
            ),
          ),
        ),
      );
    });

    test(
        'still rejects unsupported effect families even when accuracy is now bridgeable',
        () {
      const move = PokemonMove(
        id: 'sleep_powder',
        name: 'Sleep Powder',
        names: <String, String>{'en': 'Sleep Powder'},
        generation: 1,
        source: 'test',
        type: 'grass',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.normal,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.percent(value: 75),
        pp: 15,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.applyStatus(
            targetScope: PokemonMoveEffectTargetScope.target,
            statusId: 'slp',
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      expect(
        () => bridge.toBattleMoveData(
          move: move,
          combatantLabel: 'Le Pokémon actif du joueur',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            contains('bridgeLimit=unsupported_effect_kind:apply_status'),
          ),
        ),
      );
    });
  });
}

```

### packages/map_runtime/test/runtime_battle_combatant_seed_builder_test.dart

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/battle_start_request.dart';
import 'package:map_runtime/src/application/runtime_battle_combatant_seed_builder.dart';
import 'package:map_runtime/src/application/runtime_battle_setup_exception.dart';
import 'package:map_runtime/src/application/runtime_move_catalog_loader.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RuntimeBattleCombatantSeedBuilder', () {
    late Directory tempProjectRoot;
    const builder = RuntimeBattleCombatantSeedBuilder();
    const moveCatalogLoader = RuntimeMoveCatalogLoader();

    setUp(() async {
      tempProjectRoot =
          await Directory.systemTemp.createTemp('runtime_combatant_seed_');
    });

    tearDown(() async {
      if (await tempProjectRoot.exists()) {
        await tempProjectRoot.delete(recursive: true);
      }
    });

    test('builds a player combatant seed from explicit knownMoveIds', () async {
      await _writePokemonFixtures(tempProjectRoot);
      final movesCatalog = await moveCatalogLoader.load(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
      );

      final seed = await builder.buildPlayerCombatantSeed(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
        movesCatalog: movesCatalog,
        playerPokemon: const PlayerPokemon(
          speciesId: 'sproutle',
          natureId: 'bold',
          abilityId: 'overgrow',
          level: 12,
          ivs: PokemonStatSpread(
            hp: 31,
            attack: 31,
            specialAttack: 15,
            speed: 7,
          ),
          evs: PokemonStatSpread(
            hp: 8,
            attack: 12,
            specialAttack: 20,
            speed: 16,
          ),
          knownMoveIds: <String>['growl', 'vine_whip'],
          currentHp: 23,
        ),
      );

      expect(seed.speciesId, equals('sproutle'));
      expect(seed.level, equals(12));
      expect(seed.maxHp, equals(36));
      expect(seed.currentHp, equals(23));
      expect(seed.abilityId, equals('overgrow'));
      expect(seed.typing.primaryType, equals('grass'));
      expect(seed.typing.secondaryType, isNull);
      expect(seed.stats.attack, equals(20));
      expect(seed.stats.defense, equals(16));
      expect(seed.stats.specialAttack, equals(23));
      expect(seed.stats.specialDefense, equals(20));
      expect(seed.stats.speed, equals(17));
      expect(
        seed.moves.map((move) => move.id).toList(growable: false),
        equals(<String>['growl', 'vine_whip']),
      );
      expect(
        seed.moves.first.targetStatStageChanges.single.stat,
        equals(BattleStatId.attack),
      );
      expect(
        seed.moves.first.targetStatStageChanges.single.stages,
        equals(-1),
      );
      expect(seed.moves[1].power, equals(45));
    });

    test(
        'derives player moves from the learnset, falls back to species id and keeps the last four unique moves',
        () async {
      await _writePokemonFixtures(tempProjectRoot);
      await _rewriteSpeciesWithoutLearnsetRef(
        tempProjectRoot,
        speciesFileName: '001-sproutle.json',
        speciesId: 'sproutle',
        baseHp: 45,
        primaryAbilityId: 'overgrow',
      );
      final movesCatalog = await moveCatalogLoader.load(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
      );

      final seed = await builder.buildPlayerCombatantSeed(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
        movesCatalog: movesCatalog,
        playerPokemon: const PlayerPokemon(
          speciesId: 'sproutle',
          natureId: 'calm',
          abilityId: 'overgrow',
          level: 25,
          currentHp: 30,
        ),
      );

      // Le seam M7 doit conserver exactement la policy historique :
      // - concat starting/relearn/levelUp<=niveau ;
      // - unicité dans l'ordre d'apparition ;
      // - puis conservation des quatre derniers si la liste déborde.
      expect(
        seed.moves.map((move) => move.id).toList(growable: false),
        equals(<String>['growl', 'vine_whip', 'leer', 'razor_leaf']),
      );
    });

    test('builds a wild combatant seed from species and learnset data',
        () async {
      await _writePokemonFixtures(tempProjectRoot);
      final movesCatalog = await moveCatalogLoader.load(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
      );

      final seed = await builder.buildWildCombatantSeed(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
        movesCatalog: movesCatalog,
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
      );

      expect(seed.speciesId, equals('sparkitten'));
      expect(seed.level, equals(10));
      expect(seed.currentHp, isNull);
      expect(seed.abilityId, equals('blaze'));
      expect(seed.typing.primaryType, equals('fire'));
      expect(seed.typing.secondaryType, isNull);
      expect(seed.maxHp, equals(27));
      expect(seed.stats.attack, equals(15));
      expect(seed.stats.defense, equals(13));
      expect(seed.stats.specialAttack, equals(17));
      expect(seed.stats.specialDefense, equals(15));
      expect(seed.stats.speed, equals(18));
      expect(
        seed.moves.map((move) => move.id).toList(growable: false),
        equals(<String>['scratch', 'tail_whip', 'ember']),
      );
    });

    test('builds a trainer combatant seed from explicit trainer moves',
        () async {
      await _writePokemonFixtures(tempProjectRoot);
      final movesCatalog = await moveCatalogLoader.load(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
      );

      final seed = await builder.buildTrainerCombatantSeed(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
        movesCatalog: movesCatalog,
        teamMember: const ProjectTrainerPokemonEntry(
          speciesId: 'aquafi',
          level: 18,
          moves: <String>['water_gun', 'tail_whip'],
          heldItemId: 'mystic_water',
        ),
        trainerName: 'Ace Jules',
      );

      expect(seed.speciesId, equals('aquafi'));
      expect(seed.level, equals(18));
      expect(seed.abilityId, equals('torrent'));
      expect(seed.typing.primaryType, equals('water'));
      expect(seed.typing.secondaryType, equals('fairy'));
      expect(seed.stats.attack, equals(22));
      expect(seed.stats.defense, equals(28));
      expect(seed.stats.specialAttack, equals(23));
      expect(seed.stats.specialDefense, equals(28));
      expect(seed.stats.speed, equals(20));
      expect(
        seed.moves.map((move) => move.id).toList(growable: false),
        equals(<String>['water_gun', 'tail_whip']),
      );
    });

    test(
        'preserves the M5-bis gate and rejects a partially supported move during seed assembly',
        () async {
      await _writePokemonFixtures(tempProjectRoot);
      await _rewriteMoveCatalogEntrySupport(
        tempProjectRoot,
        moveId: 'growl',
        supportLevel: PokemonMoveEngineSupportLevel.structuredPartial,
        unsupportedReasons: const <String>[
          'unsupported_mechanic:stat_drop_bridge',
        ],
      );
      final movesCatalog = await moveCatalogLoader.load(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
      );

      await expectLater(
        () => builder.buildPlayerCombatantSeed(
          projectRootDirectory: tempProjectRoot.path,
          pokemonConfig: _pokemonConfig(),
          movesCatalog: movesCatalog,
          playerPokemon: const PlayerPokemon(
            speciesId: 'sproutle',
            natureId: 'bold',
            abilityId: 'overgrow',
            level: 12,
            knownMoveIds: <String>['growl', 'vine_whip'],
            currentHp: 23,
          ),
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            allOf(
              contains('combatant=Le Pokémon actif du joueur'),
              contains('moveId=growl'),
              contains('engineSupportLevel=structuredPartial'),
              contains(
                'unsupportedReasons=[unsupported_mechanic:stat_drop_bridge]',
              ),
            ),
          ),
        ),
      );
    });

    test('fails explicitly when a requested move is absent from the catalog',
        () async {
      await _writePokemonFixtures(tempProjectRoot);
      final movesCatalog = await moveCatalogLoader.load(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
      );

      await expectLater(
        () => builder.buildPlayerCombatantSeed(
          projectRootDirectory: tempProjectRoot.path,
          pokemonConfig: _pokemonConfig(),
          movesCatalog: movesCatalog,
          playerPokemon: const PlayerPokemon(
            speciesId: 'sproutle',
            natureId: 'bold',
            abilityId: 'overgrow',
            level: 12,
            knownMoveIds: <String>['move_that_does_not_exist'],
            currentHp: 23,
          ),
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.message,
            'message',
            contains('ne contient pas "move_that_does_not_exist"'),
          ),
        ),
      );
    });

    test(
        'rejects a structured supported move when the battle bridge cannot execute it honestly',
        () async {
      await _writePokemonFixtures(tempProjectRoot);
      final movesCatalog = await moveCatalogLoader.load(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
      );

      await expectLater(
        () => builder.buildPlayerCombatantSeed(
          projectRootDirectory: tempProjectRoot.path,
          pokemonConfig: _pokemonConfig(),
          movesCatalog: movesCatalog,
          playerPokemon: const PlayerPokemon(
            speciesId: 'sproutle',
            natureId: 'bold',
            abilityId: 'overgrow',
            level: 12,
            knownMoveIds: <String>['thunder_wave'],
            currentHp: 23,
          ),
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            allOf(
              contains('moveId=thunder_wave'),
              contains('engineSupportLevel=structuredSupported'),
              contains('bridgeLimit=unsupported_effect_kind:apply_status'),
            ),
          ),
        ),
      );
    });

    test(
        'keeps a non-zero priority move once battle order consumes it honestly',
        () async {
      await _writePokemonFixtures(tempProjectRoot);
      final movesCatalog = await moveCatalogLoader.load(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
      );

      final seed = await builder.buildPlayerCombatantSeed(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
        movesCatalog: movesCatalog,
        playerPokemon: const PlayerPokemon(
          speciesId: 'sproutle',
          natureId: 'bold',
          abilityId: 'overgrow',
          level: 12,
          knownMoveIds: <String>['quick_attack'],
          currentHp: 23,
        ),
      );

      expect(seed.moves, hasLength(1));
      expect(seed.moves.single.id, equals('quick_attack'));
      expect(seed.moves.single.priority, equals(1));
    });

    test('keeps a non-trivial accuracy move once battle owns the hit check',
        () async {
      await _writePokemonFixtures(tempProjectRoot);
      final movesCatalog = await moveCatalogLoader.load(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
      );

      final seed = await builder.buildPlayerCombatantSeed(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
        movesCatalog: movesCatalog,
        playerPokemon: const PlayerPokemon(
          speciesId: 'sproutle',
          natureId: 'bold',
          abilityId: 'overgrow',
          level: 12,
          knownMoveIds: <String>['mud_slap'],
          currentHp: 23,
        ),
      );

      expect(seed.moves, hasLength(1));
      expect(seed.moves.single.id, equals('mud_slap'));
      expect(seed.moves.single.accuracy.kind,
          equals(BattleMoveAccuracyKind.percent));
      expect(seed.moves.single.accuracy.value, equals(85));
    });

    test(
        'keeps a non-neutral crit ratio once battle owns minimal critical hits',
        () async {
      await _writePokemonFixtures(tempProjectRoot);
      final movesCatalog = await moveCatalogLoader.load(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
      );

      final seed = await builder.buildPlayerCombatantSeed(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
        movesCatalog: movesCatalog,
        playerPokemon: const PlayerPokemon(
          speciesId: 'sproutle',
          natureId: 'bold',
          abilityId: 'overgrow',
          level: 12,
          knownMoveIds: <String>['razor_leaf'],
          currentHp: 23,
        ),
      );

      expect(seed.moves, hasLength(1));
      expect(seed.moves.single.id, equals('razor_leaf'));
      expect(seed.moves.single.critRatio, equals(2));
    });
  });
}

ProjectPokemonConfig _pokemonConfig() {
  return const ProjectPokemonConfig(
    dataRoot: 'custom/pokemon',
    speciesDir: 'custom/pokemon/species',
    learnsetsDir: 'custom/pokemon/learnsets',
    evolutionsDir: 'custom/pokemon/evolutions',
    mediaDir: 'custom/pokemon/media',
    catalogFiles: <String, String>{
      'moves': 'custom/pokemon/catalogs/moves.json',
    },
  );
}

WildBattleStartRequest _wildRequest({
  required String speciesId,
  required int level,
}) {
  return WildBattleStartRequest(
    requestId: 'wild-request',
    createdAtEpochMs: 1,
    returnContext: const OverworldReturnContext(
      mapId: 'field_map',
      playerPos: GridPos(x: 1, y: 1),
      playerFacing: Direction.south,
    ),
    mapId: 'field_map',
    zoneId: 'grass',
    tableId: 'field_grass',
    encounterKind: EncounterKind.walk,
    speciesId: speciesId,
    level: level,
    minLevel: level,
    maxLevel: level,
    weight: 30,
    playerPos: const GridPos(x: 1, y: 1),
  );
}

Future<void> _writePokemonFixtures(Directory projectRoot) async {
  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/species/001-sproutle.json',
    <String, dynamic>{
      'id': 'sproutle',
      'typing': <String, Object>{
        'types': <String>['grass'],
      },
      'baseStats': <String, int>{
        'hp': 45,
        'atk': 49,
        'def': 49,
        'spa': 65,
        'spd': 65,
        'spe': 45,
      },
      'abilities': <String, String>{'primary': 'overgrow'},
      'refs': <String, String>{'learnset': 'sproutle'},
    },
  );
  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/species/004-sparkitten.json',
    <String, dynamic>{
      'id': 'sparkitten',
      'typing': <String, Object>{
        'types': <String>['fire'],
      },
      'baseStats': <String, int>{
        'hp': 39,
        'atk': 52,
        'def': 43,
        'spa': 60,
        'spd': 50,
        'spe': 65,
      },
      'abilities': <String, String>{'primary': 'blaze'},
      'refs': <String, String>{'learnset': 'sparkitten'},
    },
  );
  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/species/007-aquafi.json',
    <String, dynamic>{
      'id': 'aquafi',
      'typing': <String, Object>{
        'types': <String>['water', 'fairy'],
      },
      'baseStats': <String, int>{
        'hp': 44,
        'atk': 48,
        'def': 65,
        'spa': 50,
        'spd': 64,
        'spe': 43,
      },
      'abilities': <String, String>{'primary': 'torrent'},
      'refs': <String, String>{'learnset': 'aquafi'},
    },
  );

  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/learnsets/sproutle.json',
    <String, dynamic>{
      'speciesId': 'sproutle',
      'startingMoves': <String>['tackle', 'growl'],
      'relearnMoves': <String>['growl', 'vine_whip'],
      'levelUp': <Map<String, Object>>[
        <String, Object>{'moveId': 'vine_whip', 'level': 7},
        <String, Object>{'moveId': 'leer', 'level': 13},
        <String, Object>{'moveId': 'razor_leaf', 'level': 20},
      ],
    },
  );
  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/learnsets/sparkitten.json',
    <String, dynamic>{
      'speciesId': 'sparkitten',
      'startingMoves': <String>['scratch'],
      'relearnMoves': <String>['tail_whip'],
      'levelUp': <Map<String, Object>>[
        <String, Object>{'moveId': 'ember', 'level': 7},
        <String, Object>{'moveId': 'flame_wheel', 'level': 20},
      ],
    },
  );
  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/learnsets/aquafi.json',
    <String, dynamic>{
      'speciesId': 'aquafi',
      'startingMoves': <String>['tackle'],
      'relearnMoves': <String>['water_gun'],
      'levelUp': <Map<String, Object>>[
        <String, Object>{'moveId': 'tail_whip', 'level': 18},
      ],
    },
  );

  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/catalogs/moves.json',
    <String, dynamic>{
      'schemaVersion': 1,
      'kind': 'pokemon_catalog',
      'catalog': 'moves',
      'meta': <String, Object>{
        'description': 'Runtime combatant seed builder test catalog',
      },
      'entries': <Map<String, Object?>>[
        _moveEntry('tackle', 'Tackle', 40),
        _moveEntry('growl', 'Growl', 0),
        _moveEntry('vine_whip', 'Vine Whip', 45, type: 'grass'),
        _moveEntry('leer', 'Leer', 0),
        _moveEntry('razor_leaf', 'Razor Leaf', 55, type: 'grass', critRatio: 2),
        _moveEntry('scratch', 'Scratch', 40),
        _moveEntry('quick_attack', 'Quick Attack', 40, priority: 1),
        _moveEntry('mud_slap', 'Mud-Slap', 20, type: 'ground', accuracy: 85),
        _moveEntry('tail_whip', 'Tail Whip', 0),
        _moveEntry('ember', 'Ember', 40, type: 'fire'),
        _moveEntry('flame_wheel', 'Flame Wheel', 60, type: 'fire'),
        _moveEntry('water_gun', 'Water Gun', 40, type: 'water'),
        _moveEntry('thunder_wave', 'Thunder Wave', 0, type: 'electric'),
      ],
    },
  );
}

Map<String, Object?> _moveEntry(
  String id,
  String name,
  int power, {
  String type = 'normal',
  PokemonMoveTarget target = PokemonMoveTarget.normal,
  int pp = 35,
  int accuracy = 100,
  int priority = 0,
  int critRatio = 1,
  PokemonMoveEngineSupportLevel engineSupportLevel =
      PokemonMoveEngineSupportLevel.structuredSupported,
  List<String> unsupportedReasons = const <String>[],
}) {
  final effects = _defaultEffectsForMove(id);
  return PokemonMove(
    id: id,
    name: name,
    names: <String, String>{'en': name},
    generation: 1,
    source: 'test_runtime_fixture',
    type: type,
    category:
        power == 0 ? PokemonMoveCategory.status : PokemonMoveCategory.special,
    target: target,
    basePower: power,
    accuracy: power == 0
        ? const PokemonMoveAccuracy.alwaysHits()
        : PokemonMoveAccuracy.percent(value: accuracy),
    pp: pp,
    priority: priority,
    critRatio: critRatio,
    effects: effects,
    engineSupportLevel: engineSupportLevel,
    unsupportedReasons: unsupportedReasons,
  ).toJson();
}

List<PokemonMoveEffect> _defaultEffectsForMove(String moveId) {
  // Ces fixtures runtime doivent rester canoniques :
  // - `growl` / `tail_whip` / `leer` portent de vrais effets structurés ;
  // - `thunder_wave` sert explicitement de move chargé mais refusé par M8 ;
  // - les autres moves restent de simples attaques standard pour garder les
  //   happy paths lisibles.
  return switch (moveId) {
    'growl' => const <PokemonMoveEffect>[
        PokemonMoveEffect.modifyStats(
          targetScope: PokemonMoveEffectTargetScope.target,
          stageChanges: <PokemonMoveStatStageChange>[
            PokemonMoveStatStageChange(
              stat: PokemonMoveStatId.attack,
              stages: -1,
            ),
          ],
        ),
      ],
    'tail_whip' || 'leer' => const <PokemonMoveEffect>[
        PokemonMoveEffect.modifyStats(
          targetScope: PokemonMoveEffectTargetScope.target,
          stageChanges: <PokemonMoveStatStageChange>[
            PokemonMoveStatStageChange(
              stat: PokemonMoveStatId.defense,
              stages: -1,
            ),
          ],
        ),
      ],
    'thunder_wave' => const <PokemonMoveEffect>[
        PokemonMoveEffect.applyStatus(
          targetScope: PokemonMoveEffectTargetScope.target,
          statusId: 'par',
        ),
      ],
    _ => const <PokemonMoveEffect>[],
  };
}

Future<void> _rewriteMoveCatalogEntrySupport(
  Directory projectRoot, {
  required String moveId,
  required PokemonMoveEngineSupportLevel supportLevel,
  required List<String> unsupportedReasons,
}) async {
  final catalogFile =
      File(p.join(projectRoot.path, 'custom/pokemon/catalogs/moves.json'));
  final decoded =
      jsonDecode(await catalogFile.readAsString()) as Map<String, dynamic>;
  final rawEntries =
      ((decoded['entries'] as List?) ?? const <Object?>[]).cast<Object?>();
  final updatedEntries = <Map<String, Object?>>[];
  var replaced = false;

  for (final rawEntry in rawEntries) {
    final entry = (rawEntry as Map).cast<String, dynamic>();
    final entryId = (entry['id'] as String?)?.trim() ?? '';
    if (entryId != moveId) {
      updatedEntries.add(Map<String, Object?>.from(entry));
      continue;
    }

    replaced = true;
    final move = PokemonMove.fromJson(entry).copyWith(
      engineSupportLevel: supportLevel,
      unsupportedReasons: unsupportedReasons,
    );
    updatedEntries.add(move.toJson());
  }

  expect(
    replaced,
    isTrue,
    reason:
        'Expected to find move "$moveId" in the combatant seed builder fixture catalog.',
  );

  decoded['entries'] = updatedEntries;
  await catalogFile.writeAsString(const JsonEncoder.withIndent('  ').convert(
    decoded,
  ));
}

Future<void> _rewriteSpeciesWithoutLearnsetRef(
  Directory projectRoot, {
  required String speciesFileName,
  required String speciesId,
  required int baseHp,
  required String primaryAbilityId,
}) {
  return _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/species/$speciesFileName',
    <String, dynamic>{
      'id': speciesId,
      'typing': <String, Object>{
        'types': <String>['grass'],
      },
      'baseStats': <String, int>{
        'hp': baseHp,
        'atk': 49,
        'def': 49,
        'spa': 65,
        'spd': 65,
        'spe': 45,
      },
      'abilities': <String, String>{'primary': primaryAbilityId},
      // Le test retire volontairement `refs.learnset` pour prouver que le
      // seam M7 conserve bien le fallback historique vers l'id d'espèce.
    },
  );
}

Future<void> _writeProjectRelativeJson(
  Directory projectRoot,
  String relativePath,
  Map<String, dynamic> json,
) async {
  final absolutePath = p.join(projectRoot.path, relativePath);
  final file = File(absolutePath);
  await file.parent.create(recursive: true);
  await file.writeAsString(const JsonEncoder.withIndent('  ').convert(json));
}

```

### packages/map_runtime/test/runtime_battle_setup_mapper_test.dart

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/battle_start_request.dart';
import 'package:map_runtime/src/application/load_runtime_map_bundle.dart';
import 'package:map_runtime/src/application/runtime_battle_setup_mapper.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RuntimeBattleSetupMapper', () {
    late Directory tempProjectRoot;
    const mapper = RuntimeBattleSetupMapper();

    setUp(() async {
      tempProjectRoot =
          await Directory.systemTemp.createTemp('runtime_battle_mapper_');
    });

    tearDown(() async {
      if (await tempProjectRoot.exists()) {
        await tempProjectRoot.delete(recursive: true);
      }
    });

    test('maps the real player party member from runtime save data', () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);
      final setup = await mapper.map(
        bundle: bundle,
        gameState: const GameState(
          saveId: 'save-player',
          party: PlayerParty(
            members: <PlayerPokemon>[
              // Ce Pokémon K.O. ne doit jamais être choisi par le mapper.
              PlayerPokemon(
                speciesId: 'spentmon',
                natureId: 'hardy',
                abilityId: 'pressure',
                level: 99,
                knownMoveIds: <String>['do-not-use'],
                currentHp: 0,
              ),
              PlayerPokemon(
                speciesId: 'sproutle',
                natureId: 'bold',
                abilityId: 'overgrow',
                level: 12,
                ivs: PokemonStatSpread(hp: 31),
                evs: PokemonStatSpread(hp: 8),
                knownMoveIds: <String>['growl', 'vine_whip'],
                currentHp: 23,
              ),
            ],
          ),
        ),
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
      );

      expect(setup.playerPokemon.speciesId, equals('sproutle'));
      expect(setup.playerPokemon.level, equals(12));
      expect(setup.playerPokemon.currentHp, equals(23));
      expect(setup.playerPokemon.typing, isNotNull);
      expect(setup.playerPokemon.typing!.primaryType, equals('grass'));
      expect(setup.playerPokemon.typing!.secondaryType, isNull);
      expect(setup.playerPokemon.stats.attack, equals(16));
      expect(setup.playerPokemon.stats.specialAttack, equals(20));
      expect(setup.playerPokemon.stats.speed, equals(15));
      expect(
        setup.playerPokemon.moves.map((move) => move.id).toList(),
        equals(<String>['growl', 'vine_whip']),
      );
      expect(setup.playerPokemon.speciesId, isNot(equals('pikachu')));
    });

    test('uses the explicit player party index when the runtime provides one',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);
      final setup = await mapper.map(
        bundle: bundle,
        gameState: const GameState(
          saveId: 'save-player-index',
          party: PlayerParty(
            members: <PlayerPokemon>[
              PlayerPokemon(
                speciesId: 'sproutle',
                natureId: 'hardy',
                abilityId: 'overgrow',
                level: 12,
                knownMoveIds: <String>['growl'],
                currentHp: 21,
              ),
              PlayerPokemon(
                speciesId: 'aquafi',
                natureId: 'calm',
                abilityId: 'torrent',
                level: 18,
                knownMoveIds: <String>['water_gun', 'tail_whip'],
                currentHp: 17,
              ),
            ],
          ),
        ),
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
        playerPartyIndex: 1,
      );

      expect(setup.playerPokemon.speciesId, equals('aquafi'));
      expect(setup.playerPokemon.currentHp, equals(17));
      expect(
        setup.playerPokemon.moves.map((move) => move.id).toList(),
        equals(<String>['water_gun', 'tail_whip']),
      );
    });

    test('maps a wild encounter from real project species and learnset data',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);
      final setup = await mapper.map(
        bundle: bundle,
        gameState: _playerStateForTests(),
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
      );

      expect(setup.isTrainerBattle, isFalse);
      expect(setup.allowCapture, isTrue);
      expect(setup.enemyPokemon.speciesId, equals('sparkitten'));
      expect(setup.enemyPokemon.level, equals(10));
      expect(setup.enemyPokemon.abilityId, equals('blaze'));
      expect(setup.enemyPokemon.typing, isNotNull);
      expect(setup.enemyPokemon.typing!.primaryType, equals('fire'));
      expect(setup.enemyPokemon.typing!.secondaryType, isNull);
      expect(setup.enemyPokemon.stats.attack, equals(15));
      expect(setup.enemyPokemon.stats.specialAttack, equals(17));
      expect(setup.enemyPokemon.stats.speed, equals(18));
      expect(
        setup.enemyPokemon.moves.map((move) => move.id).toList(),
        equals(<String>['scratch', 'tail_whip', 'ember']),
      );
      expect(
        setup.enemyPokemon.moves
            .firstWhere((move) => move.id == 'scratch')
            .power,
        equals(40),
      );
      expect(
        setup.enemyPokemon.moves
            .firstWhere((move) => move.id == 'tail_whip')
            .power,
        equals(0),
      );
      expect(
        setup.enemyPokemon.moves
            .firstWhere((move) => move.id == 'tail_whip')
            .targetStatStageChanges
            .single
            .stat,
        equals(BattleStatId.defense),
      );
      expect(
        setup.enemyPokemon.moves.map((move) => move.id),
        isNot(contains('flame_wheel')),
      );
      expect(setup.enemyPokemon.speciesId, isNot(equals('mew')));
    });

    test(
        'preserves typing through to battle so STAB and effectiveness are really consumed',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);
      final setup = await mapper.map(
        bundle: bundle,
        gameState: const GameState(
          saveId: 'save-type-bridge',
          party: PlayerParty(
            members: <PlayerPokemon>[
              PlayerPokemon(
                speciesId: 'sparkitten',
                natureId: 'bold',
                abilityId: 'blaze',
                level: 12,
                knownMoveIds: <String>['ember'],
                currentHp: 23,
              ),
            ],
          ),
        ),
        request: _wildRequest(
          speciesId: 'sproutle',
          level: 10,
        ),
      );

      final session = createBattleSession(setup).applyChoice(
        const PlayerBattleChoiceFight(0),
      );
      final execution = session.state.currentTurn!.executions.firstWhere(
        (execution) => execution.attacker == 'player',
      );

      expect(setup.playerPokemon.typing, isNotNull);
      expect(setup.enemyPokemon.typing, isNotNull);
      expect(execution.move.id, equals('ember'));
      expect(execution.didHit, isTrue);
      expect(execution.stabMultiplier, equals(1.5));
      expect(execution.typeEffectivenessMultiplier, equals(2.0));
      expect(execution.damage, greaterThan(0));
    });

    test(
        'maps a non-trivial accuracy move honestly through to battle, where it can miss deterministically',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);
      final setup = await mapper.map(
        bundle: bundle,
        gameState: const GameState(
          saveId: 'save-accuracy',
          party: PlayerParty(
            members: <PlayerPokemon>[
              PlayerPokemon(
                speciesId: 'sproutle',
                natureId: 'bold',
                abilityId: 'overgrow',
                level: 12,
                knownMoveIds: <String>['mud_slap'],
                currentHp: 23,
              ),
            ],
          ),
        ),
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
      );

      expect(setup.playerPokemon.moves, hasLength(1));
      expect(
        setup.playerPokemon.moves.single.accuracy.kind,
        equals(BattleMoveAccuracyKind.percent),
      );
      expect(setup.playerPokemon.moves.single.accuracy.value, equals(85));

      final session = createBattleSession(
        setup,
        rng: const BattleScriptedRng(<int>[2, 100]),
      ).applyChoice(const PlayerBattleChoiceFight(0));

      final execution = session.state.currentTurn!.executions.firstWhere(
        (execution) => execution.attacker == 'player',
      );
      expect(execution.move.id, equals('mud_slap'));
      expect(execution.didHit, isFalse);
      expect(session.state.enemy.currentHp, equals(setup.enemyPokemon.maxHp));
    });

    test(
        'maps a non-neutral crit ratio honestly through to battle, where it can crit deterministically',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);
      final setup = await mapper.map(
        bundle: bundle,
        gameState: const GameState(
          saveId: 'save-crits',
          party: PlayerParty(
            members: <PlayerPokemon>[
              PlayerPokemon(
                speciesId: 'sproutle',
                natureId: 'bold',
                abilityId: 'overgrow',
                level: 12,
                knownMoveIds: <String>['razor_leaf'],
                currentHp: 23,
              ),
            ],
          ),
        ),
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
      );

      expect(setup.playerPokemon.moves, hasLength(1));
      expect(setup.playerPokemon.moves.single.id, equals('razor_leaf'));
      expect(setup.playerPokemon.moves.single.critRatio, equals(2));

      final session = createBattleSession(
        setup,
        rng: const BattleScriptedRng(<int>[2, 1]),
      ).applyChoice(const PlayerBattleChoiceFight(0));

      final execution = session.state.currentTurn!.executions.firstWhere(
        (execution) => execution.attacker == 'player',
      );
      expect(execution.move.id, equals('razor_leaf'));
      expect(execution.didHit, isTrue);
      expect(execution.didCrit, isTrue);
      expect(execution.criticalMultiplier, equals(1.5));
      expect(execution.damage, greaterThan(0));
    });

    test('falls back to the species id when the species has no learnset ref',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      await _rewriteSpeciesWithoutLearnsetRef(
        tempProjectRoot,
        speciesFileName: '001-sproutle.json',
        speciesId: 'sproutle',
        baseHp: 45,
        primaryAbilityId: 'overgrow',
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);

      final setup = await mapper.map(
        bundle: bundle,
        gameState: const GameState(
          saveId: 'save-species-id-fallback',
          party: PlayerParty(
            members: <PlayerPokemon>[
              PlayerPokemon(
                speciesId: 'sproutle',
                natureId: 'bold',
                abilityId: 'overgrow',
                level: 12,
                currentHp: 20,
              ),
            ],
          ),
        ),
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
      );

      expect(
        setup.playerPokemon.moves.map((move) => move.id).toList(),
        equals(<String>['tackle', 'growl', 'vine_whip']),
      );
    });

    test('disables capture in wild battles when the bag has no poke-ball',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);
      final setup = await mapper.map(
        bundle: bundle,
        gameState: _playerStateForTests(
          bag: const Bag(),
        ),
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
      );

      expect(setup.isTrainerBattle, isFalse);
      expect(setup.allowCapture, isFalse);
    });

    test('maps a trainer battle from the authored trainer team', () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'trainer_ace',
            name: 'Ace Jules',
            trainerClass: 'Ace Trainer',
            team: <ProjectTrainerPokemonEntry>[
              ProjectTrainerPokemonEntry(
                speciesId: 'aquafi',
                level: 18,
                moves: <String>['water_gun', 'tail_whip'],
                heldItemId: 'mystic_water',
              ),
            ],
          ),
        ],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);
      final setup = await mapper.map(
        bundle: bundle,
        gameState: _playerStateForTests(),
        request: _trainerRequest(),
      );

      expect(setup.isTrainerBattle, isTrue);
      expect(setup.allowCapture, isFalse);
      expect(setup.trainerId, equals('trainer_ace'));
      expect(setup.enemyPokemon.speciesId, equals('aquafi'));
      expect(setup.enemyPokemon.level, equals(18));
      expect(setup.enemyPokemon.abilityId, equals('torrent'));
      expect(setup.enemyPokemon.typing, isNotNull);
      expect(setup.enemyPokemon.typing!.primaryType, equals('water'));
      expect(setup.enemyPokemon.typing!.secondaryType, equals('fairy'));
      expect(
        setup.enemyPokemon.moves.map((move) => move.id).toList(),
        equals(<String>['water_gun', 'tail_whip']),
      );
      expect(setup.enemyPokemon.speciesId, isNot(equals('lapras')));
    });

    test('disables capture in wild battles when the party is already full',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);
      final fullPartyState = GameState(
        saveId: 'save-full-party',
        bag: const Bag(
          entries: <BagEntry>[
            BagEntry(
              itemId: 'poke-ball',
              categoryId: 'items',
              quantity: 2,
            ),
          ],
        ),
        party: PlayerParty(
          members: List<PlayerPokemon>.generate(
            6,
            (index) => PlayerPokemon(
              speciesId: 'sproutle',
              natureId: 'bold',
              abilityId: 'overgrow',
              level: 12 + index,
              knownMoveIds: const <String>['growl'],
              currentHp: 20,
            ),
            growable: false,
          ),
        ),
      );

      final setup = await mapper.map(
        bundle: bundle,
        gameState: fullPartyState,
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
      );

      expect(setup.isTrainerBattle, isFalse);
      expect(setup.allowCapture, isFalse);
    });

    test(
        'throws explicitly when a runtime move reference is absent from the canonical catalog',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);

      await expectLater(
        () => mapper.map(
          bundle: bundle,
          gameState: const GameState(
            saveId: 'save-missing-move',
            party: PlayerParty(
              members: <PlayerPokemon>[
                PlayerPokemon(
                  speciesId: 'sproutle',
                  natureId: 'bold',
                  abilityId: 'overgrow',
                  level: 12,
                  knownMoveIds: <String>['move_that_does_not_exist'],
                  currentHp: 20,
                ),
              ],
            ),
          ),
          request: _wildRequest(
            speciesId: 'sparkitten',
            level: 10,
          ),
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.message,
            'message',
            contains('ne contient pas "move_that_does_not_exist"'),
          ),
        ),
      );
    });

    test(
        'rejects an explicitly known move when its runtime support level is only partial',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      await _rewriteMoveCatalogEntrySupport(
        tempProjectRoot,
        moveId: 'growl',
        supportLevel: PokemonMoveEngineSupportLevel.structuredPartial,
        unsupportedReasons: const <String>[
          'unsupported_mechanic:stat_drop_bridge',
        ],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);

      await expectLater(
        () => mapper.map(
          bundle: bundle,
          gameState: const GameState(
            saveId: 'save-unsupported-known-move',
            party: PlayerParty(
              members: <PlayerPokemon>[
                PlayerPokemon(
                  speciesId: 'sproutle',
                  natureId: 'bold',
                  abilityId: 'overgrow',
                  level: 12,
                  knownMoveIds: <String>['growl', 'vine_whip'],
                  currentHp: 20,
                ),
              ],
            ),
          ),
          request: _wildRequest(
            speciesId: 'sparkitten',
            level: 10,
          ),
        ),
        throwsA(
          isA<RuntimeBattleSetupException>()
              .having(
                (error) => error.message,
                'message',
                contains('ne sait pas projeter honnêtement'),
              )
              .having(
                (error) => error.debugDetails,
                'debugDetails',
                allOf(
                  contains('combatant=Le Pokémon actif du joueur'),
                  contains('moveId=growl'),
                  contains('moveName=Growl'),
                  contains('engineSupportLevel=structuredPartial'),
                  contains(
                    'unsupportedReasons=[unsupported_mechanic:stat_drop_bridge]',
                  ),
                ),
              ),
        ),
      );
    });

    test(
        'rejects a learnset-derived move when its runtime support level is catalog only',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      await _rewriteMoveCatalogEntrySupport(
        tempProjectRoot,
        moveId: 'tackle',
        supportLevel: PokemonMoveEngineSupportLevel.catalogOnly,
        unsupportedReasons: const <String>[
          'unsupported_mechanic:legacy_damage_bridge',
        ],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);

      await expectLater(
        () => mapper.map(
          bundle: bundle,
          gameState: const GameState(
            saveId: 'save-derived-unsupported-move',
            party: PlayerParty(
              members: <PlayerPokemon>[
                PlayerPokemon(
                  speciesId: 'sproutle',
                  natureId: 'bold',
                  abilityId: 'overgrow',
                  level: 12,
                  currentHp: 20,
                ),
              ],
            ),
          ),
          request: _wildRequest(
            speciesId: 'sparkitten',
            level: 10,
          ),
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            allOf(
              contains('combatant=Le Pokémon actif du joueur'),
              contains('moveId=tackle'),
              contains('moveName=Tackle'),
              contains('engineSupportLevel=catalogOnly'),
              contains(
                'unsupportedReasons=[unsupported_mechanic:legacy_damage_bridge]',
              ),
            ),
          ),
        ),
      );
    });

    test(
        'rejects a structured supported move when the battle bridge cannot execute its effect family',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);

      await expectLater(
        () => mapper.map(
          bundle: bundle,
          gameState: const GameState(
            saveId: 'save-unsupported-battle-bridge',
            party: PlayerParty(
              members: <PlayerPokemon>[
                PlayerPokemon(
                  speciesId: 'sproutle',
                  natureId: 'bold',
                  abilityId: 'overgrow',
                  level: 12,
                  knownMoveIds: <String>['thunder_wave'],
                  currentHp: 20,
                ),
              ],
            ),
          ),
          request: _wildRequest(
            speciesId: 'sparkitten',
            level: 10,
          ),
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            allOf(
              contains('combatant=Le Pokémon actif du joueur'),
              contains('moveId=thunder_wave'),
              contains('engineSupportLevel=structuredSupported'),
              contains('bridgeLimit=unsupported_effect_kind:apply_status'),
            ),
          ),
        ),
      );
    });
  });
}

GameState _playerStateForTests({
  Bag bag = const Bag(
    entries: <BagEntry>[
      BagEntry(
        itemId: 'poke-ball',
        categoryId: 'items',
        quantity: 2,
      ),
    ],
  ),
}) {
  return GameState(
    saveId: 'save-test',
    bag: bag,
    party: const PlayerParty(
      members: <PlayerPokemon>[
        PlayerPokemon(
          speciesId: 'sproutle',
          natureId: 'bold',
          abilityId: 'overgrow',
          level: 12,
          ivs: PokemonStatSpread(hp: 31),
          evs: PokemonStatSpread(hp: 8),
          knownMoveIds: <String>['growl', 'vine_whip'],
          currentHp: 23,
        ),
      ],
    ),
  );
}

RuntimeMapBundle _buildRuntimeBundle(
  String projectRootDirectory,
  ProjectManifest manifest,
) {
  return RuntimeMapBundle(
    manifest: manifest,
    map: const MapData(
      id: 'field_map',
      name: 'Field Map',
      size: GridSize(width: 8, height: 8),
      layers: <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
    ),
    projectRootDirectory: projectRootDirectory,
    tilesetAbsolutePathsById: const <String, String>{},
  );
}

WildBattleStartRequest _wildRequest({
  required String speciesId,
  required int level,
}) {
  return WildBattleStartRequest(
    requestId: 'wild-request',
    createdAtEpochMs: 1,
    returnContext: const OverworldReturnContext(
      mapId: 'field_map',
      playerPos: GridPos(x: 1, y: 1),
      playerFacing: Direction.south,
    ),
    mapId: 'field_map',
    zoneId: 'grass',
    tableId: 'field_grass',
    encounterKind: EncounterKind.walk,
    speciesId: speciesId,
    level: level,
    minLevel: level,
    maxLevel: level,
    weight: 30,
    playerPos: const GridPos(x: 1, y: 1),
  );
}

TrainerBattleStartRequest _trainerRequest() {
  return const TrainerBattleStartRequest(
    requestId: 'trainer-request',
    createdAtEpochMs: 1,
    returnContext: OverworldReturnContext(
      mapId: 'field_map',
      playerPos: GridPos(x: 1, y: 1),
      playerFacing: Direction.south,
    ),
    trainerId: 'trainer_ace',
    npcEntityId: 'npc_ace',
    mapId: 'field_map',
    playerPos: GridPos(x: 1, y: 1),
  );
}

Future<ProjectManifest> _writeAndLoadProjectManifest(
  Directory projectRoot, {
  required List<ProjectTrainerEntry> trainers,
}) async {
  final manifest = ProjectManifest(
    name: 'Battle Mapper Test',
    maps: const <ProjectMapEntry>[
      ProjectMapEntry(
        id: 'field_map',
        name: 'Field Map',
        relativePath: 'maps/field_map.json',
      ),
    ],
    tilesets: const <ProjectTilesetEntry>[],
    trainers: trainers,
    pokemon: const ProjectPokemonConfig(
      dataRoot: 'custom/pokemon',
      speciesDir: 'custom/pokemon/species',
      learnsetsDir: 'custom/pokemon/learnsets',
      evolutionsDir: 'custom/pokemon/evolutions',
      mediaDir: 'custom/pokemon/media',
      catalogFiles: <String, String>{
        'moves': 'custom/pokemon/catalogs/moves.json',
      },
    ),
  );

  await _writeProjectJson(projectRoot, manifest.toJson());
  await _writePokemonFixtures(projectRoot);

  return loadProjectManifestFromFile(p.join(projectRoot.path, 'project.json'));
}

Future<void> _writeProjectJson(
  Directory projectRoot,
  Map<String, dynamic> json,
) async {
  final file = File(p.join(projectRoot.path, 'project.json'));
  await file.writeAsString(const JsonEncoder.withIndent('  ').convert(json));
}

Future<void> _writePokemonFixtures(Directory projectRoot) async {
  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/species/001-sproutle.json',
    <String, dynamic>{
      'id': 'sproutle',
      'slug': 'sproutle',
      'nationalDex': 1,
      'names': <String, String>{'en': 'Sproutle'},
      'speciesName': <String, String>{'en': 'Seedling'},
      'genIntroduced': 1,
      'typing': <String, Object>{
        'types': <String>['grass'],
      },
      'baseStats': <String, int>{
        'hp': 45,
        'atk': 49,
        'def': 49,
        'spa': 65,
        'spd': 65,
        'spe': 45,
        'bst': 318,
      },
      'abilities': <String, String>{'primary': 'overgrow'},
      'breeding': <String, Object>{
        'genderRatio': <String, double>{'male': 0.875, 'female': 0.125},
        'eggGroups': <String>['monster', 'grass'],
        'hatchCycles': 20,
      },
      'progression': <String, Object>{
        'growthRateId': 'medium_slow',
        'baseExp': 64,
        'catchRate': 45,
        'baseFriendship': 50,
      },
      'refs': <String, String>{
        'learnset': 'sproutle',
        'evolution': 'sproutle',
        'media': 'sproutle',
      },
      'dexContent': <String, Object>{
        'heightM': 0.7,
        'weightKg': 6.9,
      },
      'gameplayFlags': <String, bool>{'starterEligible': true},
      'sourceMeta': <String, Object>{'seededBy': 'test', 'seedVersion': 1},
    },
  );

  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/species/004-sparkitten.json',
    <String, dynamic>{
      'id': 'sparkitten',
      'slug': 'sparkitten',
      'nationalDex': 4,
      'names': <String, String>{'en': 'Sparkitten'},
      'speciesName': <String, String>{'en': 'Ember Cat'},
      'genIntroduced': 1,
      'typing': <String, Object>{
        'types': <String>['fire'],
      },
      'baseStats': <String, int>{
        'hp': 39,
        'atk': 52,
        'def': 43,
        'spa': 60,
        'spd': 50,
        'spe': 65,
        'bst': 309,
      },
      'abilities': <String, String>{'primary': 'blaze'},
      'breeding': <String, Object>{
        'genderRatio': <String, double>{'male': 0.875, 'female': 0.125},
        'eggGroups': <String>['field'],
        'hatchCycles': 20,
      },
      'progression': <String, Object>{
        'growthRateId': 'medium_slow',
        'baseExp': 62,
        'catchRate': 45,
        'baseFriendship': 50,
      },
      'refs': <String, String>{
        'learnset': 'sparkitten',
        'evolution': 'sparkitten',
        'media': 'sparkitten',
      },
      'dexContent': <String, Object>{
        'heightM': 0.6,
        'weightKg': 8.5,
      },
      'gameplayFlags': <String, bool>{'starterEligible': true},
      'sourceMeta': <String, Object>{'seededBy': 'test', 'seedVersion': 1},
    },
  );

  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/species/007-aquafi.json',
    <String, dynamic>{
      'id': 'aquafi',
      'slug': 'aquafi',
      'nationalDex': 7,
      'names': <String, String>{'en': 'Aquafi'},
      'speciesName': <String, String>{'en': 'Tadpole'},
      'genIntroduced': 1,
      'typing': <String, Object>{
        'types': <String>['water', 'fairy'],
      },
      'baseStats': <String, int>{
        'hp': 44,
        'atk': 48,
        'def': 65,
        'spa': 50,
        'spd': 64,
        'spe': 43,
        'bst': 314,
      },
      'abilities': <String, String>{'primary': 'torrent'},
      'breeding': <String, Object>{
        'genderRatio': <String, double>{'male': 0.5, 'female': 0.5},
        'eggGroups': <String>['water_1'],
        'hatchCycles': 20,
      },
      'progression': <String, Object>{
        'growthRateId': 'medium_slow',
        'baseExp': 63,
        'catchRate': 45,
        'baseFriendship': 50,
      },
      'refs': <String, String>{
        'learnset': 'aquafi',
        'evolution': 'aquafi',
        'media': 'aquafi',
      },
      'dexContent': <String, Object>{
        'heightM': 0.5,
        'weightKg': 9.0,
      },
      'gameplayFlags': <String, bool>{'starterEligible': false},
      'sourceMeta': <String, Object>{'seededBy': 'test', 'seedVersion': 1},
    },
  );

  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/learnsets/sproutle.json',
    <String, dynamic>{
      'speciesId': 'sproutle',
      'startingMoves': <String>['tackle'],
      'relearnMoves': <String>['growl'],
      'levelUp': <Map<String, Object>>[
        <String, Object>{
          'moveId': 'vine_whip',
          'level': 7,
          'source': 'level_up',
          'versionGroup': 'project',
        },
        <String, Object>{
          'moveId': 'razor_leaf',
          'level': 20,
          'source': 'level_up',
          'versionGroup': 'project',
        },
      ],
    },
  );

  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/learnsets/sparkitten.json',
    <String, dynamic>{
      'speciesId': 'sparkitten',
      'startingMoves': <String>['scratch'],
      'relearnMoves': <String>['tail_whip'],
      'levelUp': <Map<String, Object>>[
        <String, Object>{
          'moveId': 'ember',
          'level': 7,
          'source': 'level_up',
          'versionGroup': 'project',
        },
        <String, Object>{
          'moveId': 'flame_wheel',
          'level': 20,
          'source': 'level_up',
          'versionGroup': 'project',
        },
      ],
    },
  );

  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/learnsets/aquafi.json',
    <String, dynamic>{
      'speciesId': 'aquafi',
      'startingMoves': <String>['tackle'],
      'relearnMoves': <String>['water_gun'],
      'levelUp': <Map<String, Object>>[
        <String, Object>{
          'moveId': 'tail_whip',
          'level': 18,
          'source': 'level_up',
          'versionGroup': 'project',
        },
      ],
    },
  );

  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/catalogs/moves.json',
    <String, dynamic>{
      'schemaVersion': 1,
      'kind': 'pokemon_catalog',
      'catalog': 'moves',
      'meta': <String, Object>{
        'description': 'Runtime test move catalog',
      },
      'entries': <Map<String, Object?>>[
        _moveEntry('tackle', 'Tackle', 40),
        _moveEntry('growl', 'Growl', 0),
        _moveEntry('vine_whip', 'Vine Whip', 45, type: 'grass'),
        _moveEntry('razor_leaf', 'Razor Leaf', 55, type: 'grass', critRatio: 2),
        _moveEntry('scratch', 'Scratch', 40),
        _moveEntry('mud_slap', 'Mud-Slap', 20, type: 'ground', accuracy: 85),
        _moveEntry('tail_whip', 'Tail Whip', 0),
        _moveEntry('ember', 'Ember', 40, type: 'fire'),
        _moveEntry('flame_wheel', 'Flame Wheel', 60, type: 'fire'),
        _moveEntry('water_gun', 'Water Gun', 40, type: 'water'),
        _moveEntry('thunder_wave', 'Thunder Wave', 0, type: 'electric'),
      ],
    },
  );
}

Map<String, Object?> _moveEntry(
  String id,
  String name,
  int power, {
  String type = 'normal',
  int accuracy = 100,
  int critRatio = 1,
  PokemonMoveEngineSupportLevel engineSupportLevel =
      PokemonMoveEngineSupportLevel.structuredSupported,
  List<String> unsupportedReasons = const <String>[],
}) {
  final effects = _defaultEffectsForMove(id);
  return PokemonMove(
    id: id,
    name: name,
    names: <String, String>{'en': name},
    generation: 1,
    source: 'test_runtime_fixture',
    type: type,
    category:
        power == 0 ? PokemonMoveCategory.status : PokemonMoveCategory.special,
    target: PokemonMoveTarget.normal,
    basePower: power,
    accuracy: power == 0
        ? const PokemonMoveAccuracy.alwaysHits()
        : PokemonMoveAccuracy.percent(value: accuracy),
    pp: 35,
    critRatio: critRatio,
    effects: effects,
    engineSupportLevel: engineSupportLevel,
    unsupportedReasons: unsupportedReasons,
  ).toJson();
}

List<PokemonMoveEffect> _defaultEffectsForMove(String moveId) {
  return switch (moveId) {
    'growl' => const <PokemonMoveEffect>[
        PokemonMoveEffect.modifyStats(
          targetScope: PokemonMoveEffectTargetScope.target,
          stageChanges: <PokemonMoveStatStageChange>[
            PokemonMoveStatStageChange(
              stat: PokemonMoveStatId.attack,
              stages: -1,
            ),
          ],
        ),
      ],
    'tail_whip' => const <PokemonMoveEffect>[
        PokemonMoveEffect.modifyStats(
          targetScope: PokemonMoveEffectTargetScope.target,
          stageChanges: <PokemonMoveStatStageChange>[
            PokemonMoveStatStageChange(
              stat: PokemonMoveStatId.defense,
              stages: -1,
            ),
          ],
        ),
      ],
    'thunder_wave' => const <PokemonMoveEffect>[
        PokemonMoveEffect.applyStatus(
          targetScope: PokemonMoveEffectTargetScope.target,
          statusId: 'par',
        ),
      ],
    _ => const <PokemonMoveEffect>[],
  };
}

Future<void> _rewriteMoveCatalogEntrySupport(
  Directory projectRoot, {
  required String moveId,
  required PokemonMoveEngineSupportLevel supportLevel,
  required List<String> unsupportedReasons,
}) async {
  final catalogFile =
      File(p.join(projectRoot.path, 'custom/pokemon/catalogs/moves.json'));
  final decoded =
      jsonDecode(await catalogFile.readAsString()) as Map<String, dynamic>;
  final rawEntries =
      ((decoded['entries'] as List?) ?? const <Object?>[]).cast<Object?>();
  final updatedEntries = <Map<String, Object?>>[];
  var replaced = false;

  // Le helper reste volontairement minimal :
  // - il ne change que le niveau de support/runtime reasons d'une entrée déjà
  //   canonique ;
  // - il évite de dupliquer un second seed de test complet juste pour deux
  //   cas M5-bis ;
  // - il garde les fixtures globales existantes lisibles et stables.
  for (final rawEntry in rawEntries) {
    final entry = (rawEntry as Map).cast<String, dynamic>();
    final entryId = (entry['id'] as String?)?.trim() ?? '';
    if (entryId != moveId) {
      updatedEntries.add(Map<String, Object?>.from(entry));
      continue;
    }

    replaced = true;
    final move = PokemonMove.fromJson(entry).copyWith(
      engineSupportLevel: supportLevel,
      unsupportedReasons: unsupportedReasons,
    );
    updatedEntries.add(move.toJson());
  }

  expect(
    replaced,
    isTrue,
    reason: 'Expected to find move "$moveId" in the canonical runtime fixture.',
  );

  decoded['entries'] = updatedEntries;
  await catalogFile.writeAsString(const JsonEncoder.withIndent('  ').convert(
    decoded,
  ));
}

Future<void> _rewriteSpeciesWithoutLearnsetRef(
  Directory projectRoot, {
  required String speciesFileName,
  required String speciesId,
  required int baseHp,
  required String primaryAbilityId,
}) {
  return _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/species/$speciesFileName',
    <String, dynamic>{
      'id': speciesId,
      'typing': <String, Object>{
        'types': <String>['grass'],
      },
      'baseStats': <String, int>{
        'hp': baseHp,
        'atk': 49,
        'def': 49,
        'spa': 65,
        'spd': 65,
        'spe': 45,
      },
      'abilities': <String, String>{
        'primary': primaryAbilityId,
      },
      // Ce helper retire volontairement `refs.learnset` pour vérifier que le
      // mapper, via le loader learnset, retombe bien sur l'id de l'espèce.
    },
  );
}

Future<void> _writeProjectRelativeJson(
  Directory projectRoot,
  String relativePath,
  Map<String, dynamic> json,
) async {
  final absolutePath = p.join(projectRoot.path, relativePath);
  final file = File(absolutePath);
  await file.parent.create(recursive: true);
  await file.writeAsString(const JsonEncoder.withIndent('  ').convert(json));
}

```
