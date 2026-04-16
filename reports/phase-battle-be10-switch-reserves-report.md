# BE10 recadré — réserves réelles + remplacement + switch pipeline 1v1 singles + trainer multi-Pokémon minimal

## 1. Résumé exécutif honnête

Verdict court : le lot ouvre une vraie couche moteur de réserves et de switch 1v1 singles sans ouvrir de party engine générique, sans ouvrir `selfSwitch`/`forceSwitch`, et sans casser les lots BE3 à BE9 sur les validations relancées.

Ce que j’ai réellement fait :
- `map_battle` porte désormais un actif + une réserve explicite de chaque côté.
- le moteur sait gérer un switch volontaire joueur minimal, un remplacement automatique ennemi après K.O., et un remplacement forcé joueur après K.O.
- l’état local battle des combattants engagés reste cohérent pendant tout le combat : HP, PP courants, statut majeur, typing, stats résolues, lineup identity stable.
- le runtime ne s’arrête plus à `trainer.team.first` ; il mappe un actif ennemi et de vraies réserves.
- le write-back runtime ne réécrit plus naïvement un seul slot quand plusieurs membres ont effectivement combattu.
- la surface overlay trace honnêtement les switches/remplacements et distingue maintenant un remplacement forcé d’un switch volontaire.

Ce que je n’ai volontairement pas fait :
- pas de support `selfSwitch` / `forceSwitch` ; le bridge runtime reste fermé sur ces effets.
- pas de side/slot/hazards.
- pas d’IA de switch volontaire ennemi.
- pas de doubles / multi-slot.
- pas de persistance runtime complète de PP/statuts majeurs après combat ; le write-back runtime reste HP-only, ce qui est une dette connue hors scope de ce lot.
- pas de refonte d’architecture party générique.

## 2. Pré-gates exécutés + résultats

### 2.1. Git read-only

Commandes exécutées avant modification :

```bash
git status --short
git diff --stat
git ls-files --others --exclude-standard
```

Résultat honnête :
- ces trois commandes ont bien été exécutées avant code ;
- leur capture initiale dans l’outil est revenue vide/peu démonstrative ;
- je l’interprète comme un worktree sans bruit visible au moment du pré-gate, mais je ne sur-vends pas cette capture ;
- l’état git final exact est rerun et reporté plus bas en section 14.

Classification :
- `git status --short` : exécuté, capture initiale vide.
- `git diff --stat` : exécuté, capture initiale vide.
- `git ls-files --others --exclude-standard` : exécuté, capture initiale vide.

### 2.2. Battle pre-gates

Commandes exécutées avant modification :

```bash
cd packages/map_battle && /opt/homebrew/bin/dart test
cd packages/map_battle && /opt/homebrew/bin/dart analyze
```

Résultat :
- `dart test` : vert.
- `dart analyze` : vert.

### 2.3. Runtime pre-gates

Commandes exécutées avant modification :

```bash
cd packages/map_runtime && /opt/homebrew/bin/flutter test \
  test/runtime_move_catalog_loader_test.dart \
  test/runtime_pokemon_species_loader_test.dart \
  test/runtime_pokemon_learnset_loader_test.dart \
  test/runtime_battle_move_bridge_test.dart \
  test/runtime_battle_combatant_seed_builder_test.dart \
  test/runtime_battle_setup_mapper_test.dart \
  test/runtime_battle_outcome_apply_test.dart \
  test/wild_battle_end_to_end_flow_test.dart \
  test/playable_map_game_whiteout_lite_test.dart

cd packages/map_runtime && /opt/homebrew/bin/flutter analyze --no-pub \
  lib/src/application/runtime_battle_move_bridge.dart \
  lib/src/application/runtime_battle_combatant_seed_builder.dart \
  lib/src/application/runtime_battle_setup_mapper.dart \
  lib/src/presentation/flame/battle_overlay_component.dart \
  lib/src/application/runtime_pokemon_species_loader.dart \
  test/runtime_battle_move_bridge_test.dart \
  test/runtime_battle_combatant_seed_builder_test.dart \
  test/runtime_battle_setup_mapper_test.dart \
  test/runtime_move_catalog_loader_test.dart \
  test/runtime_pokemon_species_loader_test.dart \
  test/runtime_pokemon_learnset_loader_test.dart \
  test/runtime_battle_outcome_apply_test.dart \
  test/wild_battle_end_to_end_flow_test.dart \
  test/playable_map_game_whiteout_lite_test.dart
```

Résultat :
- `flutter test ...` : vert.
- `flutter analyze --no-pub ...` : vert.

## 3. État initial audité réel

Constats confirmés par audit avant modification :
- `map_battle` restait construit autour d’un actif joueur + un actif ennemi seulement.
- BE8/BE9 étaient bien présents : volatiles utiles, field state, fin de tour structurée.
- `BattleSession.getAvailableChoices()` ne savait pas exposer de vrai switch joueur.
- il n’existait pas de réserves battle côté state/setup.
- le runtime mapper sélectionnait encore un seul combattant joueur et un seul ennemi actif ; côté trainer, le moteur restait effectivement prisonnier de `trainer.team.first` sur le chemin de handoff.
- le write-back runtime post-combat restait mono-slot (`playerPartyIndex` seulement), donc faux dès qu’un vrai switch existerait.
- l’overlay runtime ne savait pas exprimer honnêtement un remplacement forcé ni des espèces actives qui changent au fil du combat.

## 4. Problèmes confirmés / non confirmés

### 4.1. Confirmés
- absence de réserves battle réelles.
- absence de switch volontaire joueur.
- victoire/défaite décidée trop tôt si un camp actif K.O. avait encore une réserve potentielle.
- runtime trainer multi-Pokémon encore mensonger à cause d’un mapping mono-actif.
- write-back runtime mono-slot incompatible avec un combat où plusieurs membres ont réellement été engagés.
- absence de trace dédiée de switch/remplacement.
- dette tox devenue fausse dès qu’un vrai switch existe : le compteur devait être reset sur switch-out.

### 4.2. Non confirmés ou recadrés
- le prompt sous-entendait qu’on pourrait peut-être garder tout le runtime quasi intact. Ce n’était pas réaliste : sans petit patch de `runtime_battle_outcome_apply.dart` et `playable_map_game.dart`, le write-back et le whiteout-lite auraient menti après switch.
- le prompt laissait ouverte la possibilité d’injecter aussi des membres déjà K.O. dans la réserve battle. Je ne l’ai pas retenu côté lineup runtime joueur : j’ai filtré les bench déjà K.O. au moment du handoff, parce qu’ils ne sont jamais switchables et compliqueraient inutilement la structure minimale BE10.

## 5. Cause racine réelle

La vraie cause racine n’était pas un simple manque de choix UI. Le moteur portait encore un contrat mono-combattant implicite à plusieurs niveaux :
- `BattleSetup` / `BattleState` sans réserves ;
- `BattleSession` sans action de switch ni phase de remplacement ;
- `RuntimeBattleSetupMapper` sans lineup réel ;
- `RuntimeActiveBattleContext` et le write-back post-combat pensés pour un seul slot joueur.

Autrement dit : tant que l’identité de lineup et la réserve n’existaient pas dans le contrat battle/runtime, tout support de trainer multi-Pokémon ou de switch aurait été cosmétique.

## 6. Décisions retenues / rejetées

### 6.1. Décisions retenues
- design minimal actif + réserve par camp, sans party engine générique.
- ajout d’une identité stable `lineupIndex` sur les combattants battle pour permettre un write-back runtime honnête sans reconstruire l’historique complet des switches.
- création d’un petit contrat dédié `BattleSwitchEvent` et d’une liste `switchEvents` dans `BattleTurnResult`.
- ajout de `PlayerBattleChoiceSwitch`, `BattleActionSwitch` et `BattleActionNone` uniquement.
- politique BE10 de priorité locale : le switch volontaire joueur résout avant un `Fight` adverse standard.
- reset sur switch-out : stat stages neutres, volatiles vidés, compteur toxique reset à 1 ; HP/PP/statut majeur conservés.
- remplacement ennemi automatique après K.O. ; remplacement joueur forcé via phase `playerChoice` avec uniquement des switches valides.
- conservation du field state BE9 au travers des switches.

### 6.2. Décisions rejetées
- pas de moteur de party/slot générique.
- pas de `BattleSideState` / `BattleSlotState` vides.
- pas de support implicite de `selfSwitch` / `forceSwitch`.
- pas d’auto-switch ennemi volontaire.
- pas de write-back runtime complet des PP et statuts majeurs hors combat.
- pas de draw system riche ; on garde la politique historique enemy-first documentée pour le double K.O. sans réserve.

## 7. Critique explicite du prompt

### 7.1. Ce qui était juste
- le prochain vrai bloc logique après BE8/BE9 était bien réserves + switch pipeline.
- il fallait refuser explicitement `selfSwitch` / `forceSwitch` plutôt que rouvrir le bridge en douce.
- un petit contrat de trace dédié de switch était la bonne direction.
- le runtime trainer multi-Pokémon ne pouvait plus rester au stade `trainer.team.first`.

### 7.2. Ce qui était discutable
- l’idée que `runtime_battle_move_bridge.dart` pourrait être touché “éventuellement” pour ce lot : après audit, ce n’était pas le seam utile. Le bridge pouvait honnêtement rester inchangé parce que BE10 ouvre le pipeline moteur de switch, pas les move effects qui le consomment.
- la suggestion que les réserves K.O. pouvaient éventuellement rester partout dans la structure battle. C’était acceptable théoriquement, mais inutilement lourd dans ce repo réel au moment du handoff runtime joueur.

### 7.3. Ce qui aurait été dangereux si suivi aveuglément
- ouvrir une abstraction party/slot plus générique “pour préparer la suite”. Cela aurait sur-architecturé un repo qui n’a encore ni doubles, ni hazards, ni `selfSwitch`.
- traiter la write-back runtime comme un détail secondaire. Sans elle, BE10 aurait immédiatement re-créé un mensonge grave post-combat.

### 7.4. Ce que j’ai recadré
- j’ai gardé `runtime_battle_move_bridge.dart` inchangé sur le fond.
- j’ai choisi de filtrer les benchs joueur déjà K.O. lors de la constitution du lineup battle runtime.
- j’ai assumé que le whiteout-lite devait être corrigé pour tenir compte du vrai slot actif final après switch, même si ce n’était pas le cœur du prompt initial.

Pourquoi ce recadrage est meilleur ici : il ferme les seams réellement faux du repo sans créer de système plus général que nécessaire.

## 8. Périmètre inclus / exclu

### 8.1. Inclus
- réserves battle réelles côté joueur et ennemi.
- switch volontaire joueur minimal.
- remplacement automatique ennemi après K.O.
- remplacement forcé joueur après K.O.
- persistance battle cohérente de HP / PP / statut / volatiles / stages sur switch.
- reset toxique honnête sur switch-out.
- runtime trainer multi-Pokémon minimal.
- write-back runtime multi-slot honnête pour les membres réellement engagés.
- patch overlay minimal pour rendre les switches/remplacements honnêtes.

### 8.2. Exclus
- `selfSwitch`
- `forceSwitch`
- doubles / triples
- side/slot state riche
- hazards
- terrains
- abilities / items
- draw system riche
- persistance runtime PP/statuts hors combat
- refonte d’architecture battle/runtime générale
- modifications `map_core`
- modifications `map_editor`

## 9. Liste exacte des fichiers modifiés / créés / supprimés

### 9.1. Modifiés
- `packages/map_battle/lib/map_battle.dart`
- `packages/map_battle/lib/src/battle_action.dart`
- `packages/map_battle/lib/src/battle_resolution.dart`
- `packages/map_battle/lib/src/battle_session.dart`
- `packages/map_battle/lib/src/battle_setup.dart`
- `packages/map_battle/lib/src/battle_state.dart`
- `packages/map_battle/lib/src/battle_status.dart`
- `packages/map_battle/lib/src/battle_volatile.dart`
- `packages/map_battle/test/battle_session_test.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `packages/map_runtime/test/runtime_battle_combatant_seed_builder_test.dart`
- `packages/map_runtime/test/runtime_battle_outcome_apply_test.dart`
- `packages/map_runtime/test/runtime_battle_setup_mapper_test.dart`

### 9.2. Créés
- `packages/map_battle/lib/src/battle_switch.dart`
- `packages/map_battle/test/battle_switch_test.dart`
- `reports/phase-battle-be10-switch-reserves-report.md`

### 9.3. Supprimés
- aucun.

### 9.4. État sale préexistant
- aucune autre famille de fichiers hors BE10 n’apparaît dans l’état git final.
- la capture git read-only initiale était vide, donc je ne prétends pas prouver plus que cela sur l’instant zéro ; en revanche, le diff final correspond uniquement au lot BE10 + ce report.

## 10. Justification fichier par fichier

- `packages/map_battle/lib/map_battle.dart` : export du nouveau petit contrat `battle_switch.dart`.
- `packages/map_battle/lib/src/battle_action.dart` : nouveau choix switch et nouvelles actions minimales liées au switch.
- `packages/map_battle/lib/src/battle_setup.dart` : réserves dans le setup et identité stable de lineup.
- `packages/map_battle/lib/src/battle_state.dart` : réserves dans l’état battle, `lineupIndex`, helper de reset sur switch-out.
- `packages/map_battle/lib/src/battle_status.dart` : reset du compteur toxique sur switch-out.
- `packages/map_battle/lib/src/battle_volatile.dart` : helper explicite de purge des volatiles sur switch-out.
- `packages/map_battle/lib/src/battle_switch.dart` : petit contrat local de trace des switches/remplacements.
- `packages/map_battle/lib/src/battle_resolution.dart` : `switchEvents` dans le résultat de tour.
- `packages/map_battle/lib/src/battle_session.dart` : cœur du lot BE10 (choix, actions, résolution de switch, remplacements post-K.O., outcome tenant compte des réserves).
- `packages/map_battle/test/battle_session_test.dart` : preuve de préservation des réserves/lineup identities à la création de session.
- `packages/map_battle/test/battle_switch_test.dart` : preuves ciblées BE10.
- `packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart` : projection de `lineupIndex` côté data battle.
- `packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart` : mapping runtime -> battle d’un vrai lineup actif + réserves côté joueur et trainer ennemi.
- `packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart` : write-back multi-slot honnête + correction whiteout-lite pour le vrai slot actif final.
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart` : mémorisation du lineup runtime injecté au combat et passage des infos nécessaires au whiteout-lite corrigé.
- `packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart` : affichage honnête des choix de switch/remplacement et des événements de switch dans un ordre causal plus propre.
- `packages/map_runtime/test/runtime_battle_combatant_seed_builder_test.dart` : preuve de `lineupIndex` stable.
- `packages/map_runtime/test/runtime_battle_outcome_apply_test.dart` : preuve du write-back multi-slot et du whiteout-lite corrigé après switch.
- `packages/map_runtime/test/runtime_battle_setup_mapper_test.dart` : preuves runtime de lineup joueur/enemy trainer et d’intégration BE10.
- `reports/phase-battle-be10-switch-reserves-report.md` : report complet du lot.

## 11. Commandes réellement exécutées

### 11.1. Pré-gates / validations principales

```bash
git status --short
git diff --stat
git ls-files --others --exclude-standard

cd packages/map_battle && /opt/homebrew/bin/dart test
cd packages/map_battle && /opt/homebrew/bin/dart analyze

cd packages/map_runtime && /opt/homebrew/bin/flutter test \
  test/runtime_move_catalog_loader_test.dart \
  test/runtime_pokemon_species_loader_test.dart \
  test/runtime_pokemon_learnset_loader_test.dart \
  test/runtime_battle_move_bridge_test.dart \
  test/runtime_battle_combatant_seed_builder_test.dart \
  test/runtime_battle_setup_mapper_test.dart \
  test/runtime_battle_outcome_apply_test.dart \
  test/wild_battle_end_to_end_flow_test.dart \
  test/playable_map_game_whiteout_lite_test.dart

cd packages/map_runtime && /opt/homebrew/bin/flutter analyze --no-pub \
  lib/src/application/runtime_battle_move_bridge.dart \
  lib/src/application/runtime_battle_combatant_seed_builder.dart \
  lib/src/application/runtime_battle_setup_mapper.dart \
  lib/src/presentation/flame/battle_overlay_component.dart \
  lib/src/application/runtime_pokemon_species_loader.dart \
  test/runtime_battle_move_bridge_test.dart \
  test/runtime_battle_combatant_seed_builder_test.dart \
  test/runtime_battle_setup_mapper_test.dart \
  test/runtime_move_catalog_loader_test.dart \
  test/runtime_pokemon_species_loader_test.dart \
  test/runtime_pokemon_learnset_loader_test.dart \
  test/runtime_battle_outcome_apply_test.dart \
  test/wild_battle_end_to_end_flow_test.dart \
  test/playable_map_game_whiteout_lite_test.dart
```

### 11.2. Audit réel

Commandes read-only réellement utilisées pendant l’audit :

```bash
rg --files -g 'AGENTS.md'
rg -n "playerPartyIndex" -S packages/map_runtime
sed -n '...p' <fichiers battle/runtime/tests/reports audités>
wc -l <fichiers touchés>
```

### 11.3. Validation intermédiaire ciblée

```bash
cd packages/map_battle && /opt/homebrew/bin/dart test test/battle_switch_test.dart
cd packages/map_runtime && /opt/homebrew/bin/flutter analyze --no-pub <surface runtime touchée>
cd packages/map_runtime && /opt/homebrew/bin/flutter test <suite runtime ciblée>
```

### 11.4. Format final

```bash
cd packages/map_battle && /opt/homebrew/bin/dart format \
  lib/map_battle.dart \
  lib/src/battle_action.dart \
  lib/src/battle_resolution.dart \
  lib/src/battle_session.dart \
  lib/src/battle_setup.dart \
  lib/src/battle_state.dart \
  lib/src/battle_status.dart \
  lib/src/battle_volatile.dart \
  lib/src/battle_switch.dart \
  test/battle_session_test.dart \
  test/battle_switch_test.dart

cd packages/map_runtime && /opt/homebrew/bin/dart format \
  lib/src/application/runtime_battle_combatant_seed_builder.dart \
  lib/src/application/runtime_battle_outcome_apply.dart \
  lib/src/application/runtime_battle_setup_mapper.dart \
  lib/src/presentation/flame/battle_overlay_component.dart \
  lib/src/presentation/flame/playable_map_game.dart \
  test/runtime_battle_combatant_seed_builder_test.dart \
  test/runtime_battle_outcome_apply_test.dart \
  test/runtime_battle_setup_mapper_test.dart
```

## 12. Résultats réels de format / analyze / tests

### 12.1. Format
- `packages/map_battle`: format exécuté, 1 fichier réellement changé lors du passage final documenté (`test/battle_switch_test.dart`) puis état stabilisé.
- `packages/map_runtime`: format exécuté, changements réels sur `runtime_battle_setup_mapper.dart`, `runtime_battle_setup_mapper_test.dart`, puis après review sur `runtime_battle_outcome_apply.dart`, `playable_map_game.dart`, `battle_overlay_component.dart`.

### 12.2. Analyze
- `packages/map_battle`: vert.
- `packages/map_runtime`: un premier passage a échoué sur 5 puis 4 lints `prefer_const_*` dans `runtime_battle_outcome_apply_test.dart`; corrigé ; rerun vert.

### 12.3. Tests
- `packages/map_battle`: ciblé BE10 rouge une première fois, puis corrigé ; full suite finale verte.
- `packages/map_runtime`: suite ciblée verte avant modifications, puis suite finale verte après corrections reviewer.

## 13. Incidents rencontrés

- capture initiale des trois commandes git read-only peu démonstrative / vide.
- premier run ciblé `battle_switch_test.dart` rouge :
  - la logique d’outcome déclarait encore une défaite alors qu’un joueur K.O. avait une réserve ;
  - un test toxique raisonnait trop naïvement sur le HP final au lieu de l’événement résiduel après switch-back.
- `flutter analyze` runtime est passé rouge sur des lints de `const` dans un test ajouté ; corrigé immédiatement.
- un reviewer a d’abord timeout sans payload exploitable, puis a finalement renvoyé un finding utile via notification.
- review runtime utile :
  - whiteout-lite réanimait le mauvais slot après switch ;
  - l’overlay ne distinguait pas assez le remplacement forcé ;
  - l’ordre d’affichage des `switchEvents` pouvait précéder le résiduel causal. Tous ces points ont été corrigés et revalidés.

## 14. État git utile

```text
 M packages/map_battle/lib/map_battle.dart
 M packages/map_battle/lib/src/battle_action.dart
 M packages/map_battle/lib/src/battle_resolution.dart
 M packages/map_battle/lib/src/battle_session.dart
 M packages/map_battle/lib/src/battle_setup.dart
 M packages/map_battle/lib/src/battle_state.dart
 M packages/map_battle/lib/src/battle_status.dart
 M packages/map_battle/lib/src/battle_volatile.dart
 M packages/map_battle/test/battle_session_test.dart
 M packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart
 M packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart
 M packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart
 M packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart
 M packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
 M packages/map_runtime/test/runtime_battle_combatant_seed_builder_test.dart
 M packages/map_runtime/test/runtime_battle_outcome_apply_test.dart
 M packages/map_runtime/test/runtime_battle_setup_mapper_test.dart
?? packages/map_battle/lib/src/battle_switch.dart
?? packages/map_battle/test/battle_switch_test.dart
?? reports/phase-battle-be10-switch-reserves-report.md
```

```text
 packages/map_battle/lib/map_battle.dart            |   1 +
 packages/map_battle/lib/src/battle_action.dart     |  42 ++
 packages/map_battle/lib/src/battle_resolution.dart |  13 +
 packages/map_battle/lib/src/battle_session.dart    | 500 ++++++++++++++++-----
 packages/map_battle/lib/src/battle_setup.dart      |  33 ++
 packages/map_battle/lib/src/battle_state.dart      |  57 +++
 packages/map_battle/lib/src/battle_status.dart     |  14 +
 packages/map_battle/lib/src/battle_volatile.dart   |  15 +
 packages/map_battle/test/battle_session_test.dart  |  61 +++
 .../runtime_battle_combatant_seed_builder.dart     |  10 +-
 .../application/runtime_battle_outcome_apply.dart  | 174 +++++--
 .../application/runtime_battle_setup_mapper.dart   | 181 ++++++--
 .../flame/battle_overlay_component.dart            |  58 ++-
 .../src/presentation/flame/playable_map_game.dart  |  44 +-
 ...runtime_battle_combatant_seed_builder_test.dart |  29 ++
 .../test/runtime_battle_outcome_apply_test.dart    | 140 ++++++
 .../test/runtime_battle_setup_mapper_test.dart     | 150 +++++++
 17 files changed, 1320 insertions(+), 202 deletions(-)
```

```text
packages/map_battle/lib/src/battle_switch.dart
packages/map_battle/test/battle_switch_test.dart
reports/phase-battle-be10-switch-reserves-report.md
```

## 15. Checklist finale

- [x] j’ai audité le code réel avant de modifier
- [x] j’ai challengé le prompt au lieu de l’appliquer aveuglément
- [x] j’ai gardé le scope strictement local à BE10 recadré
- [x] je n’ai pas touché `map_core`
- [x] je n’ai pas touché `map_editor`
- [x] je n’ai créé aucune stack parallèle
- [x] j’ai réellement amélioré la robustesse du moteur autour des réserves et du switch pipeline
- [x] le moteur porte désormais des réserves réelles côté joueur et ennemi
- [x] le joueur peut effectuer un switch volontaire minimal
- [x] le remplacement après K.O. est réellement géré
- [x] le trainer multi-Pokémon minimal n’est plus bloqué à `trainer.team.first`
- [x] je n’ai pas ouvert `selfSwitch` / `forceSwitch`
- [x] je n’ai pas ouvert hazards / side / slot / doubles / items / abilities
- [x] j’ai ajouté des tests ciblés utiles
- [x] j’ai exécuté format
- [x] j’ai exécuté analyze
- [x] j’ai exécuté les tests utiles
- [x] je n’ai fait aucune écriture Git interdite
- [x] le report explique précisément ce que j’ai fait
- [x] le report explique précisément ce que je n’ai pas fait
- [x] le report contient le contenu complet des fichiers touchés (hors lui-même pour éviter la récursion infinie)
- [x] j’ai utilisé un sub-agent d’audit/design
- [x] j’ai fait une vraie review séparée
- [x] j’ai intégré les remarques reviewer valides
- [x] j’ai fait une vraie autocritique finale

## 16. Retour du sub-agent d’audit/design

Sub-agent utilisé : `Confucius` (`019d96f7-6be2-7f82-8064-e0b2c3c96cc3`).

Retour utile retenu :
- garder un design actif + réserves plutôt qu’un party engine générique ;
- ajouter une identité stable de lineup pour éviter un write-back runtime faux ;
- utiliser une trace dédiée de switch/remplacement plutôt que gonfler les traces existantes.

Ce que j’ai retenu :
- `lineupIndex`
- `switchEvents`
- runtime mapping actif + réserves explicite.

Ce que j’ai rejeté ou resserré :
- je n’ai pas ouvert de phase “party” plus générale que nécessaire ; j’ai gardé la logique forcée sur `playerChoice` avec choix de switch uniquement.

## 17. Retour du reviewer séparé

Reviewers utilisés :
- `Einstein` (`019d970d-69be-7902-ab5c-2ec32491fcf8`)
- `Huygens` (`019d970f-3c6f-7231-b8e2-38cbc06c91d4`)

Findings utiles remontés :
- `Huygens` a trouvé un vrai bug : le whiteout-lite réanimait encore le slot initial au lieu du vrai slot actif final après switch BE10.
- `Huygens` a signalé aussi que l’overlay ne distinguait pas assez le remplacement forcé d’un switch volontaire.
- `Einstein` a signalé un problème causal d’overlay : un `switchEvent` pouvait s’afficher avant le résiduel/field event qui le provoquait.

Re-check reviewer après corrections :
- `Huygens` a revalidé les deux points comme `fixed` et n’a laissé aucun blocking issue.

## 18. Corrections appliquées après review

- correction du whiteout-lite pour réanimer le vrai slot actif final via `activePlayerLineupIndex` + `playerPartySlotIndicesByLineupIndex`.
- patch minimal de `PlayableMapGame` pour passer cette information réelle au helper de defeat recovery.
- overlay :
  - libellé explicite `Remplacer par ...` quand le joueur est en remplacement forcé ;
  - affichage des `statusEvents` ;
  - réordonnancement `statusEvents` -> `fieldEvents` -> `switchEvents` pour préserver un ordre causal plus honnête.
- rerun complet runtime analyze/tests après ces corrections.

## 19. Autocritique finale

Le lot est honnête, mais il garde volontairement des frontières strictes :
- le write-back runtime reste HP-only. C’est cohérent avec l’état réel du repo, mais ce n’est pas encore une persistance complète d’état battle hors combat.
- j’ai choisi de filtrer les benchs joueur déjà K.O. au moment du handoff battle. C’est le choix le plus simple et le plus propre pour BE10, mais si un futur lot veut un miroir plus complet de la party dans l’état battle, il faudra re-questionner cette politique.
- le switch pipeline est local et défendable, mais il n’est pas encore un système riche de remplacements/moves à effet de switch. C’est voulu.
- l’overlay est maintenant honnête sur les cas BE10, mais il reste une surface texte minimaliste, pas une UI dédiée de party.

## 20. Annexe — contenu complet de tous les fichiers texte touchés

Note importante :
- cette annexe inclut le contenu complet de tous les fichiers texte modifiés ou créés par ce lot ;
- le report lui-même est volontairement exclu de sa propre annexe pour éviter la récursion infinie.

### packages/map_battle/lib/map_battle.dart

```dart
/// Battle engine for Pokémon-like RPG combat.
///
/// Pure Dart package, independent of Flutter/Flame.
/// Deterministic, testable, and minimal.
///
/// ## Usage
///
/// ```dart
/// // 1. Create setup
/// final setup = BattleSetup(
///   playerPokemon: BattleCombatantData(
///     speciesId: 'pikachu',
///     level: 5,
///     maxHp: 20,
///     stats: const BattleStatsSnapshot(
///       attack: 10,
///       defense: 10,
///       specialAttack: 10,
///       specialDefense: 10,
///       speed: 10,
///     ),
///     moves: [BattleMoveData(id: 'tackle', name: 'Charge', power: 5)],
///   ),
///   enemyPokemon: BattleCombatantData(
///     speciesId: 'lapras',
///     level: 5,
///     maxHp: 25,
///     stats: const BattleStatsSnapshot(
///       attack: 10,
///       defense: 10,
///       specialAttack: 10,
///       specialDefense: 10,
///       speed: 10,
///     ),
///     moves: [BattleMoveData(id: 'tackle', name: 'Charge', power: 5)],
///   ),
///   isTrainerBattle: true,
///   trainerId: 'gym_leader_1',
/// );
///
/// // 2. Create session
/// final session = createBattleSession(setup);
///
/// // 3. Get available choices
/// final choices = session.getAvailableChoices();
///
/// // 4. Apply choice
/// final newSession = session.applyChoice(PlayerBattleChoiceFight(0));
///
/// // 5. Check if finished
/// if (newSession.state.isFinished) {
///   final outcome = newSession.state.outcome!;
///   if (outcome.isVictory) {
///     // Mark trainer as defeated
///   }
/// }
/// ```
library map_battle;

export 'src/battle_setup.dart';
export 'src/battle_session.dart';
export 'src/battle_state.dart';
export 'src/battle_field.dart';
export 'src/battle_status.dart';
export 'src/battle_volatile.dart';
export 'src/battle_switch.dart';
export 'src/battle_stats.dart';
export 'src/battle_typing.dart';
export 'src/battle_type_chart.dart';
export 'src/battle_rng.dart';
export 'src/battle_action.dart';
export 'src/battle_move.dart';
export 'src/battle_resolution.dart';

```

### packages/map_battle/lib/src/battle_action.dart

```dart
import 'battle_move.dart';

/// Choix disponible pour le joueur.
///
/// Représente une décision que le joueur peut prendre pendant son tour.
/// Ce modèle est utilisé par l'UI pour afficher les options disponibles.
sealed class PlayerBattleChoice {
  /// Constructeur constant pour les sous-classes.
  const PlayerBattleChoice();
}

/// Utiliser une attaque.
///
/// Le joueur choisit d'utiliser une de ses 4 attaques.
/// [moveIndex] est l'index dans la liste des attaques du Pokémon (0-3).
class PlayerBattleChoiceFight extends PlayerBattleChoice {
  /// Crée un choix d'attaque.
  ///
  /// [moveIndex] - L'index de l'attaque dans la liste (0-3).
  const PlayerBattleChoiceFight(this.moveIndex);

  /// L'index de l'attaque dans la liste des attaques du Pokémon.
  final int moveIndex;
}

/// Changer volontairement de Pokémon actif.
///
/// BE10 ouvre enfin un vrai seam de switch singles minimal :
/// - ce choix vise un index de réserve battle courant ;
/// - il ne cible ni une party globale, ni une grille de slots ;
/// - il sert à la fois au switch volontaire et au remplacement forcé, selon
///   l'état courant de la session.
class PlayerBattleChoiceSwitch extends PlayerBattleChoice {
  /// Crée un choix de switch vers un membre de réserve.
  ///
  /// [reserveIndex] pointe dans la réserve battle courante du joueur.
  const PlayerBattleChoiceSwitch(this.reserveIndex);

  final int reserveIndex;
}

/// Fuir le combat.
///
/// Le joueur choisit de tenter de fuir.
/// Pour ce MVP, la fuite est toujours réussie (simplification).
class PlayerBattleChoiceRun extends PlayerBattleChoice {
  /// Crée un choix de fuite.
  const PlayerBattleChoiceRun();
}

/// Capturer le Pokémon adverse.
///
/// Le lot 13 reste volontairement minimal :
/// - cette action n'est légitime qu'en combat sauvage ;
/// - elle ne modélise ni sac, ni consommation d'objet, ni formule canonique ;
/// - elle sert uniquement à produire un outcome explicite que le runtime
///   pourra écrire honnêtement dans la vraie party du joueur.
class PlayerBattleChoiceCapture extends PlayerBattleChoice {
  /// Crée un choix de capture.
  const PlayerBattleChoiceCapture();
}

/// Continuer un tour forcé sans sélectionner un nouveau move.
///
/// BE8 l'ajoute pour éviter un nouveau mensonge de surface :
/// - un Pokémon en recharge ou avec un move chargé en attente n'a pas
///   réellement un "choix de move" libre au tour suivant ;
/// - réutiliser artificiellement `Fight(0)` ou laisser tous les boutons de
///   move actifs ferait croire à l'UI et aux tests qu'une vraie sélection est
///   encore possible ;
/// - ce petit choix explicite sert uniquement d'acquittement UI pour avancer
///   le tour forcé, sans ouvrir une taxonomie complète de commandes.
class PlayerBattleChoiceContinue extends PlayerBattleChoice {
  /// Crée un choix de continuation de tour forcé.
  const PlayerBattleChoiceContinue();
}

/// Action résolue (interne au moteur de combat).
///
/// Contrairement à [PlayerBattleChoice] qui est un choix UI,
/// [BattleAction] représente l'action après résolution (attaque sélectionnée, etc.).
sealed class BattleAction {
  /// Constructeur constant pour les sous-classes.
  const BattleAction();
}

/// Utiliser une attaque (action résolue).
///
/// Contient l'attaque réelle à exécuter, pas juste l'index.
class BattleActionFight extends BattleAction {
  /// Crée une action d'attaque.
  ///
  /// [move] - L'attaque à exécuter.
  /// [moveIndex] - L'index du slot move dans le combattant.
  ///
  /// BE4 ajoute cet index pour une raison très concrète :
  /// - les PP vivent désormais dans l'état battle ;
  /// - le moteur doit savoir quel slot décrémenter honnêtement ;
  /// - transporter seulement l'objet `BattleMove` ne suffit plus.
  ///
  /// Ce n'est pas l'ouverture d'un système de queue plus riche :
  /// - on garde seulement la donnée minimale nécessaire au hit pipeline.
  const BattleActionFight(
    this.move, {
    required this.moveIndex,
  });

  /// L'attaque à exécuter.
  final BattleMove move;

  /// Le slot du move sur le combattant.
  final int moveIndex;
}

/// Fuir (action résolue).
///
/// Représente une tentative de fuite résolue.
class BattleActionRun extends BattleAction {
  /// Crée une action de fuite.
  const BattleActionRun();
}

/// Perdre honnêtement son tour à cause d'une recharge forcée.
///
/// BE8 préfère une action explicite plutôt que de tordre `BattleActionFight`
/// ou d'introduire un "tour vide" silencieux :
/// - cette action ne dépense pas de PP ;
/// - elle n'exécute aucun hit check ;
/// - elle rend visible le fait que le combattant a bien perdu ce tour pour
///   cause de recharge, puis nettoie l'état local.
class BattleActionRecharge extends BattleAction {
  /// Crée une action de recharge forcée.
  const BattleActionRecharge();
}

/// Changer le Pokémon actif pour un membre de réserve.
///
/// Le moteur BE10 garde ce contrat volontairement petit :
/// - `reserveIndex` référence la réserve battle courante ;
/// - le switch lui-même est résolu par `BattleSession` ;
/// - il ne transporte ni targeting riche, ni selfSwitch/forceSwitch de move.
class BattleActionSwitch extends BattleAction {
  const BattleActionSwitch({
    required this.reserveIndex,
  });

  final int reserveIndex;
}

/// Aucune action adverse pendant une étape inter-tour locale.
///
/// BE10 l'utilise uniquement pour garder une trace honnête quand le joueur
/// remplace un Pokémon K.O. entre deux tours :
/// - ce n'est pas une "attaque vide" ;
/// - ce n'est pas un nouveau système de queue ;
/// - c'est juste un marqueur explicite disant qu'aucune action adverse n'a été
///   résolue pendant cette étape de remplacement.
class BattleActionNone extends BattleAction {
  const BattleActionNone();
}

```

### packages/map_battle/lib/src/battle_resolution.dart

```dart
import 'battle_action.dart';
import 'battle_field.dart';
import 'battle_move.dart';
import 'battle_state.dart';
import 'battle_status.dart';
import 'battle_switch.dart';
import 'battle_volatile.dart';

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
  /// [statusEvents] - Les événements de statut/résiduel visibles du tour.
  /// [volatileEvents] - Les événements volatiles BE8 visibles du tour.
  /// [fieldEvents] - Les événements de champ BE9 visibles du tour.
  const BattleTurnResult({
    required this.playerAction,
    required this.enemyAction,
    required this.executions,
    this.statusEvents = const <BattleStatusEvent>[],
    this.volatileEvents = const <BattleVolatileEvent>[],
    this.fieldEvents = const <BattleFieldEvent>[],
    this.switchEvents = const <BattleSwitchEvent>[],
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

  /// Les événements de statut visibles pendant ce tour.
  ///
  /// BE7 ajoute cette trace minimale pour ne plus mentir sur deux axes :
  /// - l'application d'un statut majeur ne doit pas être une mutation muette ;
  /// - les résiduels de fin de tour ne doivent pas retirer des PV sans trace.
  final List<BattleStatusEvent> statusEvents;

  /// Les événements volatiles visibles pendant ce tour.
  ///
  /// BE8 les sépare volontairement de `statusEvents` :
  /// - `Protect`, la recharge et la charge sur deux tours n'ont pas la même
  ///   sémantique que les statuts majeurs ;
  /// - les entasser dans `BattleMoveExecution` ferait grossir ce contrat avec
  ///   des booléens croisés peu lisibles ;
  /// - une petite liste sœur garde la trace honnête sans créer un event bus.
  final List<BattleVolatileEvent> volatileEvents;

  /// Les événements de champ visibles pendant ce tour.
  ///
  /// BE9 les sépare volontairement du reste :
  /// - la météo et Trick Room sont désormais de vrais états moteur ;
  /// - les entasser dans `statusEvents` ou `volatileEvents` brouillerait les
  ///   invariants métier de chaque couche ;
  /// - une petite troisième liste suffit à garder le champ observable sans
  ///   ouvrir un journal universel.
  final List<BattleFieldEvent> fieldEvents;

  /// Les événements de switch / remplacement visibles pendant ce tour.
  ///
  /// BE10 les sépare volontairement du reste :
  /// - un switch n'est ni un statut majeur, ni un volatile BE8, ni un
  ///   événement de champ ;
  /// - le runtime/UI a besoin de distinguer un remplacement forcé d'une simple
  ///   exécution de move ;
  /// - cette petite liste sœur suffit à garder l'état observable sans ouvrir
  ///   de journal universel.
  final List<BattleSwitchEvent> switchEvents;
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
  /// Valeurs possibles : "player", "enemy" ou "field" pour un move qui agit
  /// sur le champ plutôt que sur un combattant.
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

### packages/map_battle/lib/src/battle_session.dart

```dart
import 'battle_setup.dart';
import 'battle_state.dart';
import 'battle_action.dart';
import 'battle_field.dart';
import 'battle_move.dart';
import 'battle_rng.dart';
import 'battle_resolution.dart';
import 'battle_status.dart';
import 'battle_switch.dart';
import 'battle_volatile.dart';
import 'battle_stats.dart';
import 'battle_type_chart.dart';

const double _criticalHitMultiplier = 1.5;
const int _supportedWeatherDurationTurns = 5;
const int _supportedPseudoWeatherDurationTurns = 5;
const Set<String> _sandstormResidualImmuneTypes = <String>{
  'ground',
  'rock',
  'steel',
};

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
  final player = _buildBattleCombatantFromData(setup.playerPokemon);
  final enemy = _buildBattleCombatantFromData(setup.enemyPokemon);
  final playerReserve = setup.playerReservePokemon
      .map(_buildBattleCombatantFromData)
      .toList(growable: false);
  final enemyReserve = setup.enemyReservePokemon
      .map(_buildBattleCombatantFromData)
      .toList(growable: false);

  // Créer l'état initial
  final initialState = BattleState(
    phase: BattlePhase.playerChoice,
    player: player,
    playerReserve: playerReserve,
    enemy: enemy,
    enemyReserve: enemyReserve,
    field: setup.fieldState,
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

BattleCombatant _buildBattleCombatantFromData(
  BattleCombatantData data,
) {
  // On convertit tout le petit contrat battle d'un même bloc pour garantir
  // qu'aucune dimension déjà jugée honnête n'est reperdue lors du passage
  // setup -> state, y compris maintenant l'identité de lineup BE10.
  return BattleCombatant(
    speciesId: data.speciesId,
    lineupIndex: data.lineupIndex,
    level: data.level,
    currentHp: _clampHp(
      currentHp: data.currentHp,
      maxHp: data.maxHp,
    ),
    maxHp: data.maxHp,
    stats: data.stats,
    typing: data.typing,
    majorStatus: data.majorStatus,
    volatileState: data.volatileState,
    abilityId: data.abilityId,
    moves: data.moves
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
            majorStatusEffect: m.majorStatusEffect,
            selfVolatileStatus: m.selfVolatileStatus,
            weatherEffect: m.weatherEffect,
            pseudoWeatherEffect: m.pseudoWeatherEffect,
            breaksProtect: m.breaksProtect,
            requiresRecharge: m.requiresRecharge,
            chargeThenStrikeEffect: m.chargeThenStrikeEffect,
            selfStatStageChanges: m.selfStatStageChanges,
            targetStatStageChanges: m.targetStatStageChanges,
          ),
        )
        .toList(growable: false),
  );
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
  /// - [PlayerBattleChoiceSwitch] pour chaque réserve encore vivante quand un
  ///   switch volontaire ou un remplacement forcé est honnêtement possible
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
    final replacementChoices = _availableForcedReplacementChoices();
    if (replacementChoices.isNotEmpty) {
      return replacementChoices;
    }

    final forcedChoice = _forcedPlayerChoice();
    if (forcedChoice != null) {
      return <PlayerBattleChoice>[forcedChoice];
    }

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

    // BE10 ajoute un seam de switch volontaire minimal sans ouvrir de système
    // de party complet :
    // - le joueur peut dépenser son tour pour envoyer un membre de réserve ;
    // - seuls les membres de réserve encore vivants sont proposés ;
    // - les membres K.O. restent éventuellement stockés pour le write-back,
    //   mais ne doivent jamais apparaître comme choix jouable.
    fightChoices.addAll(_availableVoluntarySwitchChoices());

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

  PlayerBattleChoice? _forcedPlayerChoice() {
    if (state.player.isFainted) {
      return null;
    }

    final volatileState = state.player.volatileState;
    if (!volatileState.mustRecharge && volatileState.pendingCharge == null) {
      return null;
    }

    // BE8 choisit ici la plus petite surface publique honnête :
    // - le joueur ne re-sélectionne pas un move librement pendant une
    //   recharge ou la libération d'un move déjà chargé ;
    // - on expose donc un simple "continuer" au lieu de maquiller ce tour
    //   forcé avec un faux bouton de move.
    return const PlayerBattleChoiceContinue();
  }

  List<PlayerBattleChoiceSwitch> _availableForcedReplacementChoices() {
    if (!state.player.isFainted) {
      return const <PlayerBattleChoiceSwitch>[];
    }

    return _selectableReserveIndices(state.playerReserve)
        .map(PlayerBattleChoiceSwitch.new)
        .toList(growable: false);
  }

  List<PlayerBattleChoiceSwitch> _availableVoluntarySwitchChoices() {
    if (state.player.isFainted) {
      return const <PlayerBattleChoiceSwitch>[];
    }

    return _selectableReserveIndices(state.playerReserve)
        .map(PlayerBattleChoiceSwitch.new)
        .toList(growable: false);
  }

  List<int> _selectableReserveIndices(List<BattleCombatant> reserve) {
    final indices = <int>[];
    for (var i = 0; i < reserve.length; i++) {
      if (!reserve[i].isFainted) {
        indices.add(i);
      }
    }
    return List<int>.unmodifiable(indices);
  }

  BattleAction? _resolveForcedAction({
    required String combatantLabel,
    required BattleCombatant combatant,
  }) {
    if (combatant.isFainted) {
      return null;
    }

    final volatileState = combatant.volatileState;
    final pendingCharge = volatileState.pendingCharge;
    if (pendingCharge != null) {
      if (pendingCharge.moveIndex < 0 ||
          pendingCharge.moveIndex >= combatant.moves.length) {
        throw StateError(
          'Le combattant $combatantLabel porte un move chargé invalide (index ${pendingCharge.moveIndex}).',
        );
      }

      final chargedMove = combatant.moves[pendingCharge.moveIndex];
      if (chargedMove.id != pendingCharge.moveId ||
          chargedMove.chargeThenStrikeEffect == null) {
        throw StateError(
          'Le combattant $combatantLabel porte un état de charge incohérent pour le move ${pendingCharge.moveId}.',
        );
      }

      return BattleActionFight(
        chargedMove,
        moveIndex: pendingCharge.moveIndex,
      );
    }

    if (volatileState.mustRecharge) {
      return const BattleActionRecharge();
    }

    return null;
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
    final forcedReplacementChoices = _availableForcedReplacementChoices();
    if (forcedReplacementChoices.isNotEmpty) {
      if (choice is! PlayerBattleChoiceSwitch) {
        throw StateError(
          'Le joueur doit d’abord remplacer son Pokémon K.O. avec un choix de switch valide.',
        );
      }
      return _applyForcedPlayerReplacement(choice);
    }

    final forcedPlayerAction = _resolveForcedAction(
      combatantLabel: 'player',
      combatant: state.player,
    );
    if (forcedPlayerAction != null && choice is! PlayerBattleChoiceContinue) {
      throw StateError(
        'Ce tour joueur est forcé; il faut l’acquitter avec PlayerBattleChoiceContinue.',
      );
    }
    if (forcedPlayerAction == null && choice is PlayerBattleChoiceContinue) {
      throw StateError(
        'PlayerBattleChoiceContinue est réservé aux tours forcés BE8.',
      );
    }

    // Frontière métier défensive :
    // même si un call site contourne getAvailableChoices(), un combat trainer
    // ne doit jamais pouvoir produire ni "runaway", ni "captured".
    //
    // On rejette explicitement ce cas illégal au niveau du moteur, ce qui
    // évite de dépendre d'un filtre UI seulement.
    if (forcedPlayerAction == null &&
        choice is PlayerBattleChoiceRun &&
        setup.isTrainerBattle) {
      throw StateError(
        'PlayerBattleChoiceRun est interdit pendant un trainer battle.',
      );
    }
    if (forcedPlayerAction == null &&
        choice is PlayerBattleChoiceCapture &&
        setup.isTrainerBattle) {
      throw StateError(
        'PlayerBattleChoiceCapture est interdit pendant un trainer battle.',
      );
    }
    if (forcedPlayerAction == null &&
        choice is PlayerBattleChoiceCapture &&
        !setup.allowCapture) {
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
    if (forcedPlayerAction == null && choice is PlayerBattleChoiceRun) {
      final finalState = BattleState(
        phase: BattlePhase.finished,
        player: state.player,
        playerReserve: state.playerReserve,
        enemy: state.enemy,
        enemyReserve: state.enemyReserve,
        field: state.field,
        currentTurn: null,
        outcome: null,
      );
      return BattleSession._(
        state: BattleState(
          phase: BattlePhase.finished,
          player: finalState.player,
          playerReserve: finalState.playerReserve,
          enemy: finalState.enemy,
          enemyReserve: finalState.enemyReserve,
          field: finalState.field,
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
    if (forcedPlayerAction == null && choice is PlayerBattleChoiceCapture) {
      final finalState = BattleState(
        phase: BattlePhase.finished,
        player: state.player,
        playerReserve: state.playerReserve,
        enemy: state.enemy,
        enemyReserve: state.enemyReserve,
        field: state.field,
        currentTurn: null,
        outcome: null,
      );
      return BattleSession._(
        state: BattleState(
          phase: BattlePhase.finished,
          player: finalState.player,
          playerReserve: finalState.playerReserve,
          enemy: finalState.enemy,
          enemyReserve: finalState.enemyReserve,
          field: finalState.field,
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
    final playerAction = forcedPlayerAction ?? _choiceToAction(choice);

    // Phase 2: Déterminer l'action de l'ennemi (IA simple)
    final enemyAction = _resolveForcedAction(
          combatantLabel: 'enemy',
          combatant: state.enemy,
        ) ??
        _chooseEnemyAction();

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
    // - pas de système générique de switch / hooks / réserves façon Showdown ;
    // - BE10 ajoute seulement le plus petit switch singles nécessaire :
    //   actif + réserve, switch volontaire joueur, remplacement après K.O. ;
    // - BE7 ajoute seulement un résiduel de fin de tour local pour les
    //   statuts majeurs supportés ;
    // - juste le plus petit mécanisme honnête pour les deux actions de ce
    //   tour et leur clôture immédiate.
    final resolvedTurn = _resolveTurn(playerAction, enemyAction);

    // Phase 4: Récupérer l'état résultant après dégâts + éventuels boosts.
    final newPlayer = resolvedTurn.player;
    final newPlayerReserve = resolvedTurn.playerReserve;
    final newEnemy = resolvedTurn.enemy;
    final newEnemyReserve = resolvedTurn.enemyReserve;
    final postTurnSwitches = _resolvePostTurnSwitchState(
      player: newPlayer,
      playerReserve: newPlayerReserve,
      enemy: newEnemy,
      enemyReserve: newEnemyReserve,
    );
    final switchEvents = <BattleSwitchEvent>[
      ...resolvedTurn.turnResult.switchEvents,
      ...postTurnSwitches.switchEvents,
    ];
    final turnResult = BattleTurnResult(
      playerAction: resolvedTurn.turnResult.playerAction,
      enemyAction: resolvedTurn.turnResult.enemyAction,
      executions: resolvedTurn.turnResult.executions,
      statusEvents: resolvedTurn.turnResult.statusEvents,
      volatileEvents: resolvedTurn.turnResult.volatileEvents,
      fieldEvents: resolvedTurn.turnResult.fieldEvents,
      switchEvents: List<BattleSwitchEvent>.unmodifiable(switchEvents),
    );

    // Phase 5: Vérifier si le combat est fini
    final outcome = _determineOutcome(
      postTurnSwitches.player,
      postTurnSwitches.playerReserve,
      postTurnSwitches.enemy,
      postTurnSwitches.enemyReserve,
      resolvedTurn.field,
    );

    // Phase 6: Créer le nouvel état
    final newState = BattleState(
      phase: outcome != null ? BattlePhase.finished : BattlePhase.playerChoice,
      player: postTurnSwitches.player,
      playerReserve: postTurnSwitches.playerReserve,
      enemy: postTurnSwitches.enemy,
      enemyReserve: postTurnSwitches.enemyReserve,
      field: resolvedTurn.field,
      // On conserve maintenant la trace du dernier tour même s'il termine le
      // combat :
      // - sinon un K.O. au résiduel, une paralysie bloquante ou une
      //   application de statut terminale redeviendraient invisibles ;
      // - `Run` et `Capture` gardent toujours `currentTurn == null`, car ils ne
      //   passent pas par `_resolveTurn`.
      currentTurn: turnResult,
      outcome: outcome,
    );

    return BattleSession._(
      state: newState,
      setup: setup,
      rng: resolvedTurn.rng,
    );
  }

  BattleSession _applyForcedPlayerReplacement(PlayerBattleChoiceSwitch choice) {
    final replacement = _resolveSwitchAction(
      actor: 'player',
      active: state.player,
      reserve: state.playerReserve,
      reserveIndex: choice.reserveIndex,
      wasForced: true,
    );

    return BattleSession._(
      state: BattleState(
        phase: BattlePhase.playerChoice,
        player: replacement.active,
        playerReserve: replacement.reserve,
        enemy: state.enemy,
        enemyReserve: state.enemyReserve,
        field: state.field,
        currentTurn: BattleTurnResult(
          playerAction: BattleActionSwitch(reserveIndex: choice.reserveIndex),
          enemyAction: const BattleActionNone(),
          executions: const <BattleMoveExecution>[],
          switchEvents: <BattleSwitchEvent>[replacement.event],
        ),
        outcome: null,
      ),
      setup: setup,
      rng: rng,
    );
  }

  _ResolvedSwitchAction _resolveSwitchAction({
    required String actor,
    required BattleCombatant active,
    required List<BattleCombatant> reserve,
    required int reserveIndex,
    required bool wasForced,
  }) {
    if (reserveIndex < 0 || reserveIndex >= reserve.length) {
      throw RangeError.index(reserveIndex, reserve, 'reserveIndex');
    }

    final incoming = reserve[reserveIndex];
    if (incoming.isFainted) {
      throw StateError(
        'Le switch demandé vise un Pokémon de réserve déjà K.O.',
      );
    }

    // BE10 choisit de conserver une réserve de taille stable :
    // - le membre entrant quitte la réserve ;
    // - l'actif sortant y retourne au même emplacement après reset ;
    // - chaque participant battle reste donc présent exactement une fois,
    //   ce qui simplifie le write-back runtime final.
    final updatedReserve = List<BattleCombatant>.of(reserve);
    updatedReserve[reserveIndex] = active.resetForReserveOnSwitchOut();

    return _ResolvedSwitchAction(
      active: incoming,
      reserve: List<BattleCombatant>.unmodifiable(updatedReserve),
      event: BattleSwitchEvent.switched(
        actor: actor,
        fromSpeciesId: active.speciesId,
        toSpeciesId: incoming.speciesId,
        wasForced: wasForced,
      ),
    );
  }

  _ResolvedPostTurnSwitchState _resolvePostTurnSwitchState({
    required BattleCombatant player,
    required List<BattleCombatant> playerReserve,
    required BattleCombatant enemy,
    required List<BattleCombatant> enemyReserve,
  }) {
    var updatedPlayer = player;
    var updatedPlayerReserve = playerReserve;
    var updatedEnemy = enemy;
    var updatedEnemyReserve = enemyReserve;
    final switchEvents = <BattleSwitchEvent>[];

    final enemyReplacementIndex = _firstUsableReserveIndex(updatedEnemyReserve);
    if (updatedEnemy.isFainted && enemyReplacementIndex != null) {
      final replacement = _resolveSwitchAction(
        actor: 'enemy',
        active: updatedEnemy,
        reserve: updatedEnemyReserve,
        reserveIndex: enemyReplacementIndex,
        wasForced: true,
      );
      updatedEnemy = replacement.active;
      updatedEnemyReserve = replacement.reserve;
      switchEvents.add(replacement.event);
    }

    if (updatedPlayer.isFainted &&
        !updatedEnemy.isFainted &&
        _firstUsableReserveIndex(updatedPlayerReserve) != null) {
      switchEvents.add(
        BattleSwitchEvent.replacementRequired(
          actor: 'player',
          fromSpeciesId: updatedPlayer.speciesId,
        ),
      );
    }

    return _ResolvedPostTurnSwitchState(
      player: updatedPlayer,
      playerReserve: updatedPlayerReserve,
      enemy: updatedEnemy,
      enemyReserve: updatedEnemyReserve,
      switchEvents: List<BattleSwitchEvent>.unmodifiable(switchEvents),
    );
  }

  int? _firstUsableReserveIndex(List<BattleCombatant> reserve) {
    for (var i = 0; i < reserve.length; i++) {
      if (!reserve[i].isFainted) {
        return i;
      }
    }
    return null;
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
    } else if (choice is PlayerBattleChoiceSwitch) {
      if (choice.reserveIndex < 0 ||
          choice.reserveIndex >= state.playerReserve.length) {
        throw StateError(
          'Le switch demandé vise un index de réserve invalide (${choice.reserveIndex}).',
        );
      }
      if (state.playerReserve[choice.reserveIndex].isFainted) {
        throw StateError(
          'Le switch demandé vise un Pokémon de réserve déjà K.O.',
        );
      }
      return BattleActionSwitch(
        reserveIndex: choice.reserveIndex,
      );
    } else if (choice is PlayerBattleChoiceRun) {
      return const BattleActionRun();
    } else if (choice is PlayerBattleChoiceContinue) {
      throw StateError(
        'PlayerBattleChoiceContinue ne doit jamais atteindre _choiceToAction sans action forcée résolue en amont.',
      );
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
  /// 4. `Run`/`Capture` restent hors pseudo-queue générique ;
  /// 5. BE7 ajoute ensuite seulement une petite phase de résiduel de fin de
  ///    tour pour les statuts majeurs supportés, sans ouvrir un système de
  ///    hooks générique.
  ///
  /// Cette méthode est interne au moteur de combat.
  _ResolvedBattleTurn _resolveTurn(
      BattleAction playerAction, BattleAction enemyAction) {
    final executions = <BattleMoveExecution>[];
    final statusEvents = <BattleStatusEvent>[];
    final volatileEvents = <BattleVolatileEvent>[];
    final fieldEvents = <BattleFieldEvent>[];
    final switchEvents = <BattleSwitchEvent>[];
    var player = state.player;
    var playerReserve = state.playerReserve;
    var enemy = state.enemy;
    var enemyReserve = state.enemyReserve;
    var field = state.field;
    var turnRng = rng;
    final orderedActions = _resolveTurnOrder(
      playerAction: playerAction,
      enemyAction: enemyAction,
      player: player,
      enemy: enemy,
      field: field,
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
              field: field,
              targetLabel: 'enemy',
              rng: turnRng,
            );
            player = resolution.attacker;
            enemy = resolution.defender;
            field = resolution.field;
            turnRng = resolution.rng;
            if (resolution.execution != null) {
              executions.add(resolution.execution!);
            }
            statusEvents.addAll(resolution.statusEvents);
            volatileEvents.addAll(resolution.volatileEvents);
            fieldEvents.addAll(resolution.fieldEvents);
          } else if (orderedAction.action
              case BattleActionSwitch(:final reserveIndex)) {
            final resolution = _resolveSwitchAction(
              actor: 'player',
              active: player,
              reserve: playerReserve,
              reserveIndex: reserveIndex,
              wasForced: false,
            );
            player = resolution.active;
            playerReserve = resolution.reserve;
            switchEvents.add(resolution.event);
          } else if (orderedAction.action is BattleActionRecharge) {
            if (player.isFainted || enemy.isFainted) {
              continue;
            }
            final resolution = _resolveRechargeAction(
              combatantLabel: 'player',
              combatant: player,
            );
            player = resolution.combatant;
            volatileEvents.addAll(resolution.volatileEvents);
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
              field: field,
              targetLabel: 'player',
              rng: turnRng,
            );
            enemy = resolution.attacker;
            player = resolution.defender;
            field = resolution.field;
            turnRng = resolution.rng;
            if (resolution.execution != null) {
              executions.add(resolution.execution!);
            }
            statusEvents.addAll(resolution.statusEvents);
            volatileEvents.addAll(resolution.volatileEvents);
            fieldEvents.addAll(resolution.fieldEvents);
          } else if (orderedAction.action
              case BattleActionSwitch(:final reserveIndex)) {
            final resolution = _resolveSwitchAction(
              actor: 'enemy',
              active: enemy,
              reserve: enemyReserve,
              reserveIndex: reserveIndex,
              wasForced: false,
            );
            enemy = resolution.active;
            enemyReserve = resolution.reserve;
            switchEvents.add(resolution.event);
          } else if (orderedAction.action is BattleActionRecharge) {
            if (enemy.isFainted || player.isFainted) {
              continue;
            }
            final resolution = _resolveRechargeAction(
              combatantLabel: 'enemy',
              combatant: enemy,
            );
            enemy = resolution.combatant;
            volatileEvents.addAll(resolution.volatileEvents);
          }
      }
    }

    final residualResolution = _resolveEndOfTurnPhase(
      player: player,
      enemy: enemy,
      field: field,
    );
    player = residualResolution.player;
    enemy = residualResolution.enemy;
    field = residualResolution.field;
    statusEvents.addAll(residualResolution.statusEvents);
    fieldEvents.addAll(residualResolution.fieldEvents);
    player = player.withVolatileState(
      player.volatileState.clearedEndOfTurnFlags(),
    );
    enemy = enemy.withVolatileState(
      enemy.volatileState.clearedEndOfTurnFlags(),
    );

    return _ResolvedBattleTurn(
      player: player,
      playerReserve: playerReserve,
      enemy: enemy,
      enemyReserve: enemyReserve,
      field: field,
      rng: turnRng,
      turnResult: BattleTurnResult(
        playerAction: playerAction,
        enemyAction: enemyAction,
        executions: executions,
        statusEvents: statusEvents,
        volatileEvents: volatileEvents,
        fieldEvents: fieldEvents,
        switchEvents: switchEvents,
      ),
    );
  }

  List<_OrderedBattleAction> _resolveTurnOrder({
    required BattleAction playerAction,
    required BattleAction enemyAction,
    required BattleCombatant player,
    required BattleCombatant enemy,
    required BattleFieldState field,
  }) {
    // BE3 refuse d'introduire une fausse queue générique.
    //
    // Le moteur actuel n'a besoin que d'un ordre honnête pour deux actions :
    // - si ce sont deux `Fight`, on compare priorité puis vitesse effective ;
    // - sinon, on conserve l'ordre historique minimal, car les autres actions
    //   restent déjà gérées explicitement ailleurs (`Run`/`Capture`) ou ne
    //   sont pas de vrais chemins gameplay du moteur MVP.
    if (!_supportsOrderedResolution(playerAction) ||
        !_supportsOrderedResolution(enemyAction)) {
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

    final playerPriority = _priorityForResolvedAction(playerAction);
    final enemyPriority = _priorityForResolvedAction(enemyAction);
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
    final trickRoomActive =
        field.isPseudoWeatherActive(BattlePseudoWeatherId.trickRoom);
    if (playerSpeed != enemySpeed) {
      final playerActsFirst =
          trickRoomActive ? playerSpeed < enemySpeed : playerSpeed > enemySpeed;
      return playerActsFirst
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
    // - Trick Room n'inverse pas ce tie-break : seul l'ordre de vitesse est
    //   renversé ;
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

  bool _supportsOrderedResolution(BattleAction action) {
    return action is BattleActionFight ||
        action is BattleActionRecharge ||
        action is BattleActionSwitch;
  }

  int _priorityForResolvedAction(BattleAction action) {
    return switch (action) {
      // Politique BE10 explicitement simplifiée :
      // - un switch volontaire singles résout avant un `Fight` standard ;
      // - on n'ouvre pas pour autant une vraie taxonomie Showdown de priorités
      //   de switch, selfSwitch, forceSwitch, etc. ;
      // - cette constante locale suffit au sous-ensemble honnête du lot.
      BattleActionSwitch() => 6,
      BattleActionFight(:final move) => move.priority,
      BattleActionRecharge() => 0,
      _ => 0,
    };
  }

  /// Résout une exécution unique de move.
  ///
  /// M8 puis BE4 gardent ici un contrat volontairement petit et honnête :
  /// - dégâts standards via `power` ;
  /// - influence de `modifyStats` uniquement sur atk/def/spa/spd ;
  /// - moves de statut => dégâts 0 ;
  /// - hit check minimal et PP réels ;
  /// - BE6 ajoute un crit minimal réel pour les hits offensifs non immunisés ;
  /// - les changements de stats sont appliqués immédiatement après un hit ;
  /// - BE7 ajoute ensuite un petit sous-ensemble `applyStatus` et un blocage
  ///   d'action par paralysie, sans ouvrir un système de statuts complet.
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
    required BattleFieldState field,
    required String targetLabel,
    required BattleRng rng,
  }) {
    final pendingCharge = attacker.volatileState.pendingCharge;
    final isChargeRelease = pendingCharge != null &&
        pendingCharge.moveIndex == moveIndex &&
        pendingCharge.moveId == move.id;

    if (!isChargeRelease && !move.hasUsablePp) {
      throw StateError(
        'Le move "${move.name}" n’a plus de PP et ne peut pas être résolu honnêtement.',
      );
    }

    // Ordre de résolution BE8, volontairement borné et documenté :
    // 1. si le move est la libération d'une charge déjà stockée, on réutilise
    //    ce move sans repayer les PP et on nettoie immédiatement l'état de
    //    charge ;
    // 2. sinon, on suit BE4 : tentative => consommation de PP ;
    // 3. blocage d'action par paralysie si applicable ;
    // 4. si le move est un chargeThenStrike en premier tour, on entre en
    //    charge et on s'arrête là ;
    // 5. hit check ;
    // 6. application éventuelle de `protect` sur le lanceur, puis interception
    //    par une protection adverse déjà active ;
    // 7. dégâts / statuts / BE5 / BE6 / BE7 ;
    // 8. éventuelle recharge forcée si le move le demande.
    final attackerAfterChargeClear = isChargeRelease
        ? attacker.withVolatileState(
            attacker.volatileState.withPendingCharge(null),
          )
        : attacker;
    final attackerAfterPpUse = isChargeRelease
        ? attackerAfterChargeClear
        : attackerAfterChargeClear.withUpdatedMoveAt(
            moveIndex,
            move.withConsumedPp(),
          );
    final actionGate = _resolveMajorStatusActionGate(
      combatantLabel: attackerLabel,
      combatant: attackerAfterPpUse,
      rng: rng,
    );

    if (!actionGate.canAct) {
      return _ResolvedMoveExecution(
        attacker: attackerAfterPpUse,
        defender: defender,
        field: field,
        rng: actionGate.nextRng,
        execution: null,
        statusEvents: actionGate.statusEvents,
        volatileEvents: const <BattleVolatileEvent>[],
        fieldEvents: const <BattleFieldEvent>[],
      );
    }

    if (!isChargeRelease && move.chargeThenStrikeEffect != null) {
      final chargingAttacker = attackerAfterPpUse.withVolatileState(
        attackerAfterPpUse.volatileState.withPendingCharge(
          BattlePendingChargeState(
            moveIndex: moveIndex,
            moveId: move.id,
            chargeStateId: move.chargeThenStrikeEffect!.chargeStateId,
          ),
        ),
      );

      return _ResolvedMoveExecution(
        attacker: chargingAttacker,
        defender: defender,
        field: field,
        rng: actionGate.nextRng,
        execution: null,
        statusEvents: const <BattleStatusEvent>[],
        volatileEvents: <BattleVolatileEvent>[
          BattleVolatileEvent.chargeStarted(
            actor: attackerLabel,
            sourceMoveId: move.id,
            chargeStateId: move.chargeThenStrikeEffect!.chargeStateId,
          ),
        ],
        fieldEvents: const <BattleFieldEvent>[],
      );
    }

    final volatileEvents = <BattleVolatileEvent>[
      if (isChargeRelease)
        BattleVolatileEvent.chargeReleased(
          actor: attackerLabel,
          sourceMoveId: move.id,
          chargeStateId: pendingCharge.chargeStateId,
        ),
    ];

    final hitCheck = _resolveHitCheck(
      move: move,
      rng: actionGate.nextRng,
    );

    if (!hitCheck.didHit) {
      return _ResolvedMoveExecution(
        attacker: attackerAfterPpUse,
        defender: defender,
        field: field,
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
        statusEvents: const <BattleStatusEvent>[],
        volatileEvents: List<BattleVolatileEvent>.unmodifiable(volatileEvents),
        fieldEvents: const <BattleFieldEvent>[],
      );
    }

    final protectResolution = _resolveProtectInteractions(
      move: move,
      attackerLabel: attackerLabel,
      targetLabel: targetLabel,
      attacker: attackerAfterPpUse,
      defender: defender,
    );
    volatileEvents.addAll(protectResolution.volatileEvents);

    if (protectResolution.blockedByProtect) {
      return _ResolvedMoveExecution(
        attacker: protectResolution.attacker,
        defender: protectResolution.defender,
        field: field,
        rng: hitCheck.nextRng,
        execution: BattleMoveExecution(
          attacker: attackerLabel,
          move: protectResolution.attacker.moves[moveIndex],
          target: _resolveExecutionTargetLabel(
            move: move,
            attackerLabel: attackerLabel,
            opponentLabel: targetLabel,
          ),
          damage: 0,
          didHit: true,
          didCrit: false,
          criticalMultiplier: 1.0,
        ),
        statusEvents: const <BattleStatusEvent>[],
        volatileEvents: List<BattleVolatileEvent>.unmodifiable(volatileEvents),
        fieldEvents: const <BattleFieldEvent>[],
      );
    }

    final damageResult = _computeMoveDamage(
      move: move,
      attacker: protectResolution.attacker,
      defender: protectResolution.defender,
      field: field,
      rng: hitCheck.nextRng,
    );

    // BE5 donne à l'immunité une sémantique simple et honnête pour le petit
    // sous-ensemble moteur actuellement supporté :
    // - le move a bien été tenté et a passé le hit check ;
    // - mais il n'a "aucun effet" sur la cible si le typing annule le hit ;
    // - on n'applique donc ni dégâts ni stage changes à partir d'un hit
    //   immunisé, ce qui évite des demi-effets mensongers.
    final updatedAttacker = damageResult.wasImmune
        ? protectResolution.attacker
        : protectResolution.attacker
            .withAppliedStageChanges(move.selfStatStageChanges);
    final defenderAfterHit = damageResult.wasImmune
        ? protectResolution.defender
        : protectResolution.defender
            .withDamage(damageResult.damage)
            .withAppliedStageChanges(move.targetStatStageChanges);
    final statusApplication = _resolveMajorStatusApplication(
      move: move,
      targetLabel: targetLabel,
      defender: defenderAfterHit,
      damageResult: damageResult,
      rng: damageResult.nextRng,
    );
    final fieldApplication = _resolveFieldApplication(
      move: move,
      field: field,
    );
    final rechargeFollowUp = _resolveRechargeFollowUp(
      move: move,
      attackerLabel: attackerLabel,
      attacker: updatedAttacker,
      damageResult: damageResult,
    );
    volatileEvents.addAll(rechargeFollowUp.volatileEvents);

    return _ResolvedMoveExecution(
      attacker: rechargeFollowUp.attacker,
      defender: statusApplication.defender,
      field: fieldApplication.field,
      rng: statusApplication.nextRng,
      execution: BattleMoveExecution(
        attacker: attackerLabel,
        move: rechargeFollowUp.attacker.moves[moveIndex],
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
      statusEvents: statusApplication.statusEvents,
      volatileEvents: List<BattleVolatileEvent>.unmodifiable(volatileEvents),
      fieldEvents: fieldApplication.fieldEvents,
    );
  }

  _ResolvedProtectInteractions _resolveProtectInteractions({
    required BattleMove move,
    required String attackerLabel,
    required String targetLabel,
    required BattleCombatant attacker,
    required BattleCombatant defender,
  }) {
    var updatedAttacker = attacker;
    var updatedDefender = defender;
    final volatileEvents = <BattleVolatileEvent>[];

    if (move.selfVolatileStatus == BattleVolatileStatusId.protect) {
      updatedAttacker = updatedAttacker.withVolatileState(
        updatedAttacker.volatileState.withProtectActive(true),
      );
      volatileEvents.add(
        BattleVolatileEvent.protectActivated(
          actor: attackerLabel,
          sourceMoveId: move.id,
        ),
      );
    }

    if (move.target != BattleMoveTarget.opponent ||
        !updatedDefender.volatileState.protectActive) {
      return _ResolvedProtectInteractions(
        attacker: updatedAttacker,
        defender: updatedDefender,
        blockedByProtect: false,
        volatileEvents: volatileEvents,
      );
    }

    if (move.breaksProtect) {
      updatedDefender = updatedDefender.withVolatileState(
        updatedDefender.volatileState.withProtectActive(false),
      );
      volatileEvents.add(
        BattleVolatileEvent.protectBroken(
          actor: attackerLabel,
          target: targetLabel,
          sourceMoveId: move.id,
        ),
      );
      return _ResolvedProtectInteractions(
        attacker: updatedAttacker,
        defender: updatedDefender,
        blockedByProtect: false,
        volatileEvents: volatileEvents,
      );
    }

    volatileEvents.add(
      BattleVolatileEvent.protectBlocked(
        actor: attackerLabel,
        target: targetLabel,
        sourceMoveId: move.id,
      ),
    );
    return _ResolvedProtectInteractions(
      attacker: updatedAttacker,
      defender: updatedDefender,
      blockedByProtect: true,
      volatileEvents: volatileEvents,
    );
  }

  _ResolvedRechargeFollowUp _resolveRechargeFollowUp({
    required BattleMove move,
    required String attackerLabel,
    required BattleCombatant attacker,
    required _ResolvedDamage damageResult,
  }) {
    // BE8 borne `requireRecharge` au sous-ensemble local réellement défendable :
    // - le move doit avoir atteint la phase "dégâts calculés" ;
    // - un miss ou un blocage par Protect sort déjà plus haut ;
    // - une immunité complète ne déclenche pas ce verrou, car aucun effet
    //   offensif réel n'a finalement été produit ;
    // - on ne prétend toujours pas reproduire tous les cas spéciaux Pokémon.
    if (!move.requiresRecharge ||
        move.resolvedCategory == BattleMoveCategory.status ||
        damageResult.wasImmune) {
      return _ResolvedRechargeFollowUp(
        attacker: attacker,
        volatileEvents: const <BattleVolatileEvent>[],
      );
    }

    return _ResolvedRechargeFollowUp(
      attacker: attacker.withVolatileState(
        attacker.volatileState.withMustRecharge(true),
      ),
      volatileEvents: <BattleVolatileEvent>[
        BattleVolatileEvent.rechargeRequired(
          actor: attackerLabel,
          sourceMoveId: move.id,
        ),
      ],
    );
  }

  _ResolvedRechargeAction _resolveRechargeAction({
    required String combatantLabel,
    required BattleCombatant combatant,
  }) {
    if (!combatant.volatileState.mustRecharge) {
      return _ResolvedRechargeAction(
        combatant: combatant,
        volatileEvents: const <BattleVolatileEvent>[],
      );
    }

    return _ResolvedRechargeAction(
      combatant: combatant.withVolatileState(
        combatant.volatileState.withMustRecharge(false),
      ),
      volatileEvents: <BattleVolatileEvent>[
        BattleVolatileEvent.rechargeTurnSpent(
          actor: combatantLabel,
        ),
      ],
    );
  }

  _ResolvedFieldApplication _resolveFieldApplication({
    required BattleMove move,
    required BattleFieldState field,
  }) {
    // BE9 garde un contrat de champ petit et explicite :
    // - un move ne pose au maximum qu'une météo OU un pseudoWeather ;
    // - aucune pile générique d'effets de champ ;
    // - aucune side/slot condition cachée derrière ce helper.
    if (move.weatherEffect == null && move.pseudoWeatherEffect == null) {
      return _ResolvedFieldApplication(
        field: field,
        fieldEvents: const <BattleFieldEvent>[],
      );
    }

    var updatedField = field;
    final fieldEvents = <BattleFieldEvent>[];

    if (move.weatherEffect case final weather?) {
      updatedField = updatedField.withWeather(
        BattleWeatherState(
          id: weather,
          remainingTurns: _supportedWeatherDurationTurns,
        ),
      );
      fieldEvents.add(
        BattleFieldEvent.weatherSet(
          weather: weather,
          sourceMoveId: move.id,
        ),
      );
    }

    if (move.pseudoWeatherEffect case final pseudoWeather?) {
      // Recadrage volontaire :
      // - BE9 ne crée pas un "room system" générique ;
      // - mais Trick Room réutilisé pendant qu'il est déjà actif doit rester
      //   honnête pour le sous-ensemble local ;
      // - on choisit donc un toggle simple : pose si absent, retrait si déjà
      //   actif, sans rouvrir d'autre mécanique de restart.
      if (updatedField.pseudoWeather?.id == pseudoWeather) {
        updatedField = updatedField.withPseudoWeather(null);
        fieldEvents.add(
          BattleFieldEvent.pseudoWeatherCleared(
            pseudoWeather: pseudoWeather,
            sourceMoveId: move.id,
          ),
        );
      } else {
        updatedField = updatedField.withPseudoWeather(
          BattlePseudoWeatherState(
            id: pseudoWeather,
            remainingTurns: _supportedPseudoWeatherDurationTurns,
          ),
        );
        fieldEvents.add(
          BattleFieldEvent.pseudoWeatherSet(
            pseudoWeather: pseudoWeather,
            sourceMoveId: move.id,
          ),
        );
      }
    }

    return _ResolvedFieldApplication(
      field: updatedField,
      fieldEvents: List<BattleFieldEvent>.unmodifiable(fieldEvents),
    );
  }

  _ResolvedActionGate _resolveMajorStatusActionGate({
    required String combatantLabel,
    required BattleCombatant combatant,
    required BattleRng rng,
  }) {
    final status = combatant.majorStatus;
    if (status?.id != BattleMajorStatusId.par) {
      return _ResolvedActionGate(
        canAct: true,
        nextRng: rng,
        statusEvents: const <BattleStatusEvent>[],
      );
    }

    // BE7 ouvre ici la plus petite sémantique honnête de paralysie :
    // - le move a déjà consommé 1 PP, car la tentative a bien eu lieu ;
    // - on bloque ensuite l'action avec une chance fixe de 25% ;
    // - on ne touche ni à l'ordre BE3 déjà figé, ni au hit check BE4.
    final roll = rng.nextChance(
      numerator: 1,
      denominator: 4,
    );
    if (!roll.didOccur) {
      return _ResolvedActionGate(
        canAct: true,
        nextRng: roll.next,
        statusEvents: const <BattleStatusEvent>[],
      );
    }

    return _ResolvedActionGate(
      canAct: false,
      nextRng: roll.next,
      statusEvents: <BattleStatusEvent>[
        BattleStatusEvent.preventedAction(
          target: combatantLabel,
          status: BattleMajorStatusId.par,
        ),
      ],
    );
  }

  _ResolvedStatusApplication _resolveMajorStatusApplication({
    required BattleMove move,
    required String targetLabel,
    required BattleCombatant defender,
    required _ResolvedDamage damageResult,
    required BattleRng rng,
  }) {
    final effect = move.majorStatusEffect;
    if (effect == null) {
      return _ResolvedStatusApplication(
        defender: defender,
        nextRng: rng,
        statusEvents: const <BattleStatusEvent>[],
      );
    }

    // BE7 ne crée pas encore de couche complète d'immunité de statut.
    // En revanche, pour un move qui inflige aussi des dégâts, on refuse
    // d'appliquer un statut si le hit a été entièrement annulé par une
    // immunité de type déjà supportée par BE5.
    if (damageResult.wasImmune &&
        move.resolvedCategory != BattleMoveCategory.status) {
      return _ResolvedStatusApplication(
        defender: defender,
        nextRng: rng,
        statusEvents: const <BattleStatusEvent>[],
      );
    }

    if (defender.majorStatus != null) {
      return _ResolvedStatusApplication(
        defender: defender,
        nextRng: rng,
        statusEvents: <BattleStatusEvent>[
          BattleStatusEvent.blockedExistingMajorStatus(
            target: targetLabel,
            status: effect.status,
            existingStatus: defender.majorStatus!.id,
            sourceMoveId: move.id,
          ),
        ],
      );
    }

    if (effect.chancePercent case final chance?) {
      final chanceRoll = rng.nextChance(
        numerator: chance,
        denominator: 100,
      );
      if (!chanceRoll.didOccur) {
        return _ResolvedStatusApplication(
          defender: defender,
          nextRng: chanceRoll.next,
          statusEvents: const <BattleStatusEvent>[],
        );
      }

      return _ResolvedStatusApplication(
        defender: defender.withMajorStatus(_majorStatusStateFor(effect.status)),
        nextRng: chanceRoll.next,
        statusEvents: <BattleStatusEvent>[
          BattleStatusEvent.applied(
            target: targetLabel,
            status: effect.status,
            sourceMoveId: move.id,
          ),
        ],
      );
    }

    return _ResolvedStatusApplication(
      defender: defender.withMajorStatus(_majorStatusStateFor(effect.status)),
      nextRng: rng,
      statusEvents: <BattleStatusEvent>[
        BattleStatusEvent.applied(
          target: targetLabel,
          status: effect.status,
          sourceMoveId: move.id,
        ),
      ],
    );
  }

  _ResolvedResidualPhase _resolveEndOfTurnPhase({
    required BattleCombatant player,
    required BattleCombatant enemy,
    required BattleFieldState field,
  }) {
    // BE9 restructure explicitement la fin de tour, sans créer un système
    // général de hooks :
    // 1. résiduels de statuts majeurs déjà ouverts en BE7 ;
    // 2. résiduels météo supportés en BE9 ;
    // 3. décrémentation puis expiration du champ ;
    // 4. l'outcome final est ensuite déterminé plus haut, à partir de l'état
    //    réellement obtenu après ces effets.
    final statusResidual = _applyEndOfTurnMajorStatusResiduals(
      player: player,
      enemy: enemy,
    );
    final weatherResidual = _applyEndOfTurnWeatherResiduals(
      player: statusResidual.player,
      enemy: statusResidual.enemy,
      field: field,
    );
    final fieldProgression =
        _advanceFieldStateAtEndOfTurn(weatherResidual.field);

    return _ResolvedResidualPhase(
      player: weatherResidual.player,
      enemy: weatherResidual.enemy,
      field: fieldProgression.field,
      statusEvents: statusResidual.statusEvents,
      fieldEvents: <BattleFieldEvent>[
        ...weatherResidual.fieldEvents,
        ...fieldProgression.fieldEvents,
      ],
    );
  }

  _ResolvedMajorStatusResiduals _applyEndOfTurnMajorStatusResiduals({
    required BattleCombatant player,
    required BattleCombatant enemy,
  }) {
    // BE7 reste volontairement local :
    // - pas de "hook system" de fin de tour ;
    // - pas de queue de résiduels générique ;
    // - juste la plus petite phase explicite pour les statuts majeurs
    //   supportés, après les actions et avant l'outcome final.
    final playerResidual = !player.isFainted
        ? _applyEndOfTurnResidualForCombatant(
            combatant: player,
            combatantLabel: 'player',
          )
        : const _ResolvedSingleResidual(
            combatant: null,
            statusEvents: <BattleStatusEvent>[],
          );
    final enemyResidual = !enemy.isFainted
        ? _applyEndOfTurnResidualForCombatant(
            combatant: enemy,
            combatantLabel: 'enemy',
          )
        : const _ResolvedSingleResidual(
            combatant: null,
            statusEvents: <BattleStatusEvent>[],
          );

    return _ResolvedMajorStatusResiduals(
      player: playerResidual.combatant ?? player,
      enemy: enemyResidual.combatant ?? enemy,
      statusEvents: <BattleStatusEvent>[
        ...playerResidual.statusEvents,
        ...enemyResidual.statusEvents,
      ],
    );
  }

  _ResolvedSingleResidual _applyEndOfTurnResidualForCombatant({
    required BattleCombatant combatant,
    required String combatantLabel,
  }) {
    final status = combatant.majorStatus;
    if (status == null || combatant.isFainted) {
      return _ResolvedSingleResidual(
        combatant: combatant,
        statusEvents: const <BattleStatusEvent>[],
      );
    }

    final residualDamage = switch (status.id) {
      BattleMajorStatusId.par => 0,
      BattleMajorStatusId.brn => _fractionalResidual(
          maxHp: combatant.maxHp,
          numerator: 1,
          denominator: 16,
        ),
      BattleMajorStatusId.psn => _fractionalResidual(
          maxHp: combatant.maxHp,
          numerator: 1,
          denominator: 8,
        ),
      BattleMajorStatusId.tox => _fractionalResidual(
          maxHp: combatant.maxHp,
          numerator: status.toxicCounter,
          denominator: 16,
        ),
    };

    if (residualDamage <= 0) {
      return _ResolvedSingleResidual(
        combatant: combatant,
        statusEvents: const <BattleStatusEvent>[],
      );
    }

    final damagedCombatant = combatant.withDamage(residualDamage);
    final nextCombatant =
        status.id == BattleMajorStatusId.tox && !damagedCombatant.isFainted
            ? damagedCombatant.withMajorStatus(status.incrementToxicCounter())
            : damagedCombatant;

    return _ResolvedSingleResidual(
      combatant: nextCombatant,
      statusEvents: <BattleStatusEvent>[
        BattleStatusEvent.residualDamage(
          target: combatantLabel,
          status: status.id,
          damage: residualDamage,
          toxicCounter:
              status.id == BattleMajorStatusId.tox ? status.toxicCounter : null,
        ),
      ],
    );
  }

  _ResolvedWeatherResiduals _applyEndOfTurnWeatherResiduals({
    required BattleCombatant player,
    required BattleCombatant enemy,
    required BattleFieldState field,
  }) {
    final weather = field.weather;
    if (weather == null || weather.id != BattleWeatherId.sandstorm) {
      return _ResolvedWeatherResiduals(
        player: player,
        enemy: enemy,
        field: field,
        fieldEvents: const <BattleFieldEvent>[],
      );
    }

    final playerResidual = _applySandstormResidual(
      combatant: player,
      combatantLabel: 'player',
    );
    final enemyResidual = _applySandstormResidual(
      combatant: enemy,
      combatantLabel: 'enemy',
    );

    return _ResolvedWeatherResiduals(
      player: playerResidual.combatant,
      enemy: enemyResidual.combatant,
      field: field,
      fieldEvents: <BattleFieldEvent>[
        ...playerResidual.fieldEvents,
        ...enemyResidual.fieldEvents,
      ],
    );
  }

  _ResolvedSandstormResidual _applySandstormResidual({
    required BattleCombatant combatant,
    required String combatantLabel,
  }) {
    if (combatant.isFainted || _isImmuneToSandstormResidual(combatant)) {
      return _ResolvedSandstormResidual(
        combatant: combatant,
        fieldEvents: const <BattleFieldEvent>[],
      );
    }

    final damage = _fractionalResidual(
      maxHp: combatant.maxHp,
      numerator: 1,
      denominator: 16,
    );
    final damagedCombatant = combatant.withDamage(damage);

    return _ResolvedSandstormResidual(
      combatant: damagedCombatant,
      fieldEvents: <BattleFieldEvent>[
        BattleFieldEvent.weatherResidualDamage(
          weather: BattleWeatherId.sandstorm,
          target: combatantLabel,
          damage: damage,
        ),
      ],
    );
  }

  bool _isImmuneToSandstormResidual(BattleCombatant combatant) {
    final typing = combatant.typing;
    if (typing == null) {
      return false;
    }
    return _sandstormResidualImmuneTypes.contains(typing.primaryType) ||
        (typing.secondaryType != null &&
            _sandstormResidualImmuneTypes.contains(typing.secondaryType));
  }

  _ResolvedFieldProgression _advanceFieldStateAtEndOfTurn(
      BattleFieldState field) {
    var updatedField = field;
    final fieldEvents = <BattleFieldEvent>[];

    if (field.weather case final weather?) {
      if (weather.remainingTurns <= 1) {
        updatedField = updatedField.withWeather(null);
        fieldEvents.add(
          BattleFieldEvent.weatherExpired(
            weather: weather.id,
          ),
        );
      } else {
        updatedField = updatedField.withWeather(weather.decrement());
      }
    }

    if (field.pseudoWeather case final pseudoWeather?) {
      if (pseudoWeather.remainingTurns <= 1) {
        updatedField = updatedField.withPseudoWeather(null);
        fieldEvents.add(
          BattleFieldEvent.pseudoWeatherExpired(
            pseudoWeather: pseudoWeather.id,
          ),
        );
      } else {
        updatedField =
            updatedField.withPseudoWeather(pseudoWeather.decrement());
      }
    }

    return _ResolvedFieldProgression(
      field: updatedField,
      fieldEvents: List<BattleFieldEvent>.unmodifiable(fieldEvents),
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
      BattleMoveTarget.field => 'field',
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
    required BattleFieldState field,
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
    // - toujours aucune abilities, aucun item, aucune Tera ;
    // - BE9 n'ajoute ensuite qu'un unique modificateur météo local :
    //   la pluie pour Eau/Feu.
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
    // 3. malus de brûlure sur les moves physiques dans BE7 ;
    // 4. STAB ;
    // 5. effectiveness / résistance ;
    // 6. météo BE9 réellement supportée ;
    // 7. clamp minimum 1 si le move a touché et n'est pas immunisé.
    //
    // On reste volontairement dans un modèle simple à base de doubles +
    // `floor` plutôt que de singer tous les paliers internes de Showdown.
    final burnMultiplier =
        attacker.majorStatus?.id == BattleMajorStatusId.brn &&
                move.resolvedCategory == BattleMoveCategory.physical
            ? 0.5
            : 1.0;
    final weatherMultiplier = _resolveWeatherDamageMultiplier(
      move: move,
      field: field,
    );
    final scaledDamage = (baseDamage *
            criticalHit.multiplier *
            burnMultiplier *
            stabMultiplier *
            typeEffectivenessMultiplier *
            weatherMultiplier)
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

  double _resolveWeatherDamageMultiplier({
    required BattleMove move,
    required BattleFieldState field,
  }) {
    final weather = field.weather;
    if (weather == null || weather.id != BattleWeatherId.rain) {
      return 1.0;
    }

    return switch (move.type) {
      'water' => 1.5,
      'fire' => 0.5,
      _ => 1.0,
    };
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
    // Mini-fix BE6 puis BE6-mini-fix-2 :
    // - la première version neutralisait silencieusement `critRatio <= 0`
    //   dans la branche "ratio neutre" ;
    // - cela laissait une donnée battle invalide devenir "à peu près valide" ;
    // - le contrat public est désormais mieux verrouillé en amont, donc cette
    //   garde sert surtout de défense en profondeur pour un état incohérent
    //   qui réapparaîtrait à l'intérieur même de `map_battle` ;
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
    // - BE7 y ajoute ensuite le malus simple de paralysie ;
    // - aucun RNG, aucune nature, aucun weather ;
    // - Trick Room BE9 n'altère pas cette valeur : il inverse ensuite la
    //   comparaison des deux vitesses au niveau du scheduler.
    final stagedSpeed = _resolveEffectiveStat(
      baseStat: combatant.stats.speed,
      multiplier: combatant.statStages.multiplierFor(BattleStatId.speed),
    );
    if (combatant.majorStatus?.id != BattleMajorStatusId.par) {
      return stagedSpeed;
    }

    final slowedSpeed = (stagedSpeed * 0.5).floor();
    return slowedSpeed < 1 ? 1 : slowedSpeed;
  }

  BattleMajorStatusState _majorStatusStateFor(BattleMajorStatusId status) {
    return switch (status) {
      BattleMajorStatusId.par => const BattleMajorStatusState.par(),
      BattleMajorStatusId.brn => const BattleMajorStatusState.brn(),
      BattleMajorStatusId.psn => const BattleMajorStatusState.psn(),
      BattleMajorStatusId.tox => const BattleMajorStatusState.tox(),
    };
  }

  int _fractionalResidual({
    required int maxHp,
    required int numerator,
    required int denominator,
  }) {
    final raw = (maxHp * numerator) ~/ denominator;
    return raw < 1 ? 1 : raw;
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
  /// Politique BE10, volontairement petite et explicite :
  /// - les remplacements automatiques honnêtes ont déjà été tentés avant
  ///   d'entrer ici ;
  /// - si l'ennemi actif est encore K.O. à ce stade, il n'a plus de réserve
  ///   valide et le joueur gagne ;
  /// - sinon, si le joueur actif est encore K.O. mais qu'une réserve valide
  ///   existe encore, le combat continue pour laisser place au switch forcé ;
  /// - sinon, si le joueur actif est encore K.O., il n'a plus de réserve
  ///   valide et le joueur perd ;
  /// - sinon le combat continue ;
  /// - en cas de double K.O. sans réserve des deux côtés, on conserve donc la
  ///   politique historique "enemy d'abord", ce qui produit une victoire.
  ///
  /// Cette méthode est interne au moteur de combat.
  BattleOutcome? _determineOutcome(
    BattleCombatant player,
    List<BattleCombatant> playerReserve,
    BattleCombatant enemy,
    List<BattleCombatant> enemyReserve,
    BattleFieldState field,
  ) {
    // Vérifier la victoire (ennemi K.O.)
    if (enemy.isFainted) {
      final finalState = BattleState(
        phase: BattlePhase.finished,
        player: player,
        playerReserve: playerReserve,
        enemy: enemy,
        enemyReserve: enemyReserve,
        field: field,
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
      if (_firstUsableReserveIndex(playerReserve) != null) {
        return null;
      }
      final finalState = BattleState(
        phase: BattlePhase.finished,
        player: player,
        playerReserve: playerReserve,
        enemy: enemy,
        enemyReserve: enemyReserve,
        field: field,
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
    required this.playerReserve,
    required this.enemy,
    required this.enemyReserve,
    required this.field,
    required this.rng,
    required this.turnResult,
  });

  final BattleCombatant player;
  final List<BattleCombatant> playerReserve;
  final BattleCombatant enemy;
  final List<BattleCombatant> enemyReserve;
  final BattleFieldState field;
  final BattleRng rng;
  final BattleTurnResult turnResult;
}

class _ResolvedSwitchAction {
  const _ResolvedSwitchAction({
    required this.active,
    required this.reserve,
    required this.event,
  });

  final BattleCombatant active;
  final List<BattleCombatant> reserve;
  final BattleSwitchEvent event;
}

class _ResolvedPostTurnSwitchState {
  const _ResolvedPostTurnSwitchState({
    required this.player,
    required this.playerReserve,
    required this.enemy,
    required this.enemyReserve,
    required this.switchEvents,
  });

  final BattleCombatant player;
  final List<BattleCombatant> playerReserve;
  final BattleCombatant enemy;
  final List<BattleCombatant> enemyReserve;
  final List<BattleSwitchEvent> switchEvents;
}

class _ResolvedMoveExecution {
  const _ResolvedMoveExecution({
    required this.attacker,
    required this.defender,
    required this.field,
    required this.rng,
    required this.execution,
    required this.statusEvents,
    required this.volatileEvents,
    required this.fieldEvents,
  });

  final BattleCombatant attacker;
  final BattleCombatant defender;
  final BattleFieldState field;
  final BattleRng rng;
  final BattleMoveExecution? execution;
  final List<BattleStatusEvent> statusEvents;
  final List<BattleVolatileEvent> volatileEvents;
  final List<BattleFieldEvent> fieldEvents;
}

class _ResolvedHitCheck {
  const _ResolvedHitCheck({
    required this.didHit,
    required this.nextRng,
  });

  final bool didHit;
  final BattleRng nextRng;
}

class _ResolvedActionGate {
  const _ResolvedActionGate({
    required this.canAct,
    required this.nextRng,
    required this.statusEvents,
  });

  final bool canAct;
  final BattleRng nextRng;
  final List<BattleStatusEvent> statusEvents;
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

class _ResolvedStatusApplication {
  const _ResolvedStatusApplication({
    required this.defender,
    required this.nextRng,
    required this.statusEvents,
  });

  final BattleCombatant defender;
  final BattleRng nextRng;
  final List<BattleStatusEvent> statusEvents;
}

class _ResolvedProtectInteractions {
  const _ResolvedProtectInteractions({
    required this.attacker,
    required this.defender,
    required this.blockedByProtect,
    required this.volatileEvents,
  });

  final BattleCombatant attacker;
  final BattleCombatant defender;
  final bool blockedByProtect;
  final List<BattleVolatileEvent> volatileEvents;
}

class _ResolvedRechargeFollowUp {
  const _ResolvedRechargeFollowUp({
    required this.attacker,
    required this.volatileEvents,
  });

  final BattleCombatant attacker;
  final List<BattleVolatileEvent> volatileEvents;
}

class _ResolvedRechargeAction {
  const _ResolvedRechargeAction({
    required this.combatant,
    required this.volatileEvents,
  });

  final BattleCombatant combatant;
  final List<BattleVolatileEvent> volatileEvents;
}

class _ResolvedResidualPhase {
  const _ResolvedResidualPhase({
    required this.player,
    required this.enemy,
    required this.field,
    required this.statusEvents,
    required this.fieldEvents,
  });

  final BattleCombatant player;
  final BattleCombatant enemy;
  final BattleFieldState field;
  final List<BattleStatusEvent> statusEvents;
  final List<BattleFieldEvent> fieldEvents;
}

class _ResolvedMajorStatusResiduals {
  const _ResolvedMajorStatusResiduals({
    required this.player,
    required this.enemy,
    required this.statusEvents,
  });

  final BattleCombatant player;
  final BattleCombatant enemy;
  final List<BattleStatusEvent> statusEvents;
}

class _ResolvedWeatherResiduals {
  const _ResolvedWeatherResiduals({
    required this.player,
    required this.enemy,
    required this.field,
    required this.fieldEvents,
  });

  final BattleCombatant player;
  final BattleCombatant enemy;
  final BattleFieldState field;
  final List<BattleFieldEvent> fieldEvents;
}

class _ResolvedSandstormResidual {
  const _ResolvedSandstormResidual({
    required this.combatant,
    required this.fieldEvents,
  });

  final BattleCombatant combatant;
  final List<BattleFieldEvent> fieldEvents;
}

class _ResolvedFieldProgression {
  const _ResolvedFieldProgression({
    required this.field,
    required this.fieldEvents,
  });

  final BattleFieldState field;
  final List<BattleFieldEvent> fieldEvents;
}

class _ResolvedFieldApplication {
  const _ResolvedFieldApplication({
    required this.field,
    required this.fieldEvents,
  });

  final BattleFieldState field;
  final List<BattleFieldEvent> fieldEvents;
}

class _ResolvedSingleResidual {
  const _ResolvedSingleResidual({
    required this.combatant,
    required this.statusEvents,
  });

  final BattleCombatant? combatant;
  final List<BattleStatusEvent> statusEvents;
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

### packages/map_battle/lib/src/battle_setup.dart

```dart
import 'battle_field.dart';
import 'battle_move.dart';
import 'battle_status.dart';
import 'battle_volatile.dart';
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
  /// [fieldState] - État de champ initial si le setup battle veut démarrer
  ///   sous une météo ou un pseudoWeather déjà actifs.
  const BattleSetup({
    required this.playerPokemon,
    this.playerReservePokemon = const <BattleCombatantData>[],
    required this.enemyPokemon,
    this.enemyReservePokemon = const <BattleCombatantData>[],
    required this.isTrainerBattle,
    required this.trainerId,
    this.allowCapture = false,
    this.fieldState = const BattleFieldState(),
  });

  /// Le Pokémon du joueur qui combat.
  final BattleCombatantData playerPokemon;

  /// Réserve battle locale du joueur.
  ///
  /// BE10 reste volontairement simple :
  /// - un seul actif joueur ;
  /// - zéro ou plusieurs membres de réserve ;
  /// - aucun système de side/slot riche.
  final List<BattleCombatantData> playerReservePokemon;

  /// Le Pokémon adverse qui combat.
  final BattleCombatantData enemyPokemon;

  /// Réserve battle locale de l'adversaire.
  ///
  /// Le lot l'ouvre surtout pour rendre honnêtes les trainer battles à
  /// plusieurs Pokémon, sans ouvrir de multi-battle.
  final List<BattleCombatantData> enemyReservePokemon;

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

  /// État de champ initial du combat.
  ///
  /// BE9 le porte dès le setup pour garder le champ observable :
  /// - le runtime principal démarre encore avec un champ vide ;
  /// - mais les tests et call sites directs peuvent injecter une pluie,
  ///   une tempête de sable ou un Trick Room déjà actifs ;
  /// - cela évite des mutations post-création qui mentiraient sur l'état
  ///   initial réellement résolu.
  final BattleFieldState fieldState;
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
  /// [majorStatus] - Statut majeur initial si un call site battle direct veut
  ///   démarrer depuis un état déjà entamé.
  /// [volatileState] - Sous-état volatile local BE8 si un setup battle direct
  ///   veut démarrer depuis une protection, une recharge ou une charge déjà
  ///   en cours.
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
    this.lineupIndex = 0,
    this.typing,
    this.majorStatus,
    this.volatileState = const BattleVolatileState(),
    this.currentHp,
    this.abilityId = 'unknown',
    required this.moves,
  });

  /// L'identifiant de l'espèce (ex: "pikachu", "lapras").
  final String speciesId;

  /// Identité stable du combattant dans la lineup battle de son camp.
  ///
  /// BE10 ajoute ce petit identifiant pour une raison très concrète :
  /// - pendant le combat, actif et réserve peuvent s'échanger plusieurs fois ;
  /// - le runtime doit malgré tout réécrire les bons slots de party après le
  ///   combat sans deviner l'historique des switches ;
  /// - on transporte donc un index local stable, purement battle/runtime,
  ///   qui n'ouvre ni grid de slots, ni modèle de party parallèle.
  ///
  /// Important :
  /// - ce n'est pas un slot de doubles ;
  /// - ce n'est pas un index UI ;
  /// - c'est uniquement une identité stable dans la lineup initiale de ce
  ///   camp pour le write-back et la cohérence des remplacements.
  final int lineupIndex;

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

  /// Statut majeur initial du combattant si le setup battle le connaît déjà.
  ///
  /// Le chemin runtime principal le laisse à `null` dans BE7 :
  /// - la persistance hors combat des statuts n'existe pas encore ;
  /// - mais le moteur battle a maintenant besoin d'un vrai état local de
  ///   statut majeur ;
  /// - garder ce champ optionnel évite aussi d'inventer des helpers de test
  ///   parallèles juste pour démarrer un combat déjà brûlé / paralysé / etc.
  final BattleMajorStatusState? majorStatus;

  /// Sous-état volatile local du combattant au démarrage.
  ///
  /// Le chemin runtime principal le laisse vide dans BE8 :
  /// - il n'existe pas encore de persistance hors combat de `Protect`,
  ///   `mustRecharge` ou des moves chargés ;
  /// - mais garder ce champ directement sur le setup battle permet des tests
  ///   honnêtes sans mutation post-création de session.
  final BattleVolatileState volatileState;

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
///
/// Mini-fix BE6-2 :
/// - ce contrat de setup devient lui aussi `final` ;
/// - il doit rester un petit DTO battle, pas une surface extensible ;
/// - verrouiller aussi le setup évite de fermer `BattleMove` tout en laissant
///   encore entrer des valeurs malformées par héritage avant la création de
///   session ;
/// - on garde `const`, les assertions locales, puis les gardes runtime comme
///   défense en profondeur, mais le bypass trivial par override disparaît.
final class BattleMoveData {
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
  /// [majorStatusEffect] - Effet `applyStatus` battle minimal supporté par
  ///   BE7 pour le petit sous-ensemble de statuts majeurs réellement
  ///   exécutable.
  /// [selfVolatileStatus] - Volatile auto-appliqué par le move dans le
  ///   sous-ensemble strict BE8 (`protect` uniquement).
  /// [weatherEffect] - Effet météo battle minimal réellement consommé par BE9.
  /// [pseudoWeatherEffect] - Effet pseudoWeather battle minimal réellement
  ///   consommé par BE9.
  /// [breaksProtect] - Le move peut bypasser une protection active BE8.
  /// [requiresRecharge] - Le move impose ensuite un tour de recharge au
  ///   lanceur.
  /// [chargeThenStrikeEffect] - Le move charge un tour puis frappe le tour
  ///   suivant sans repayer les PP.
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
  /// - puis BE7 ouvre un unique effet `applyStatus` battle minimal pour
  ///   `par`, `brn`, `psn`, `tox` ;
  /// - puis BE8 ajoute quelques volatiles utiles explicitement bornés aux
  ///   besoins de `Protect`, `breakProtect`, `requireRecharge` et
  ///   `chargeThenStrike` ;
  /// - puis BE9 ajoute uniquement la météo et le pseudoWeather réellement
  ///   consommés par le moteur (`rain`, `sandstorm`, `trickRoom`) ;
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
    this.majorStatusEffect,
    this.selfVolatileStatus,
    this.weatherEffect,
    this.pseudoWeatherEffect,
    this.breaksProtect = false,
    this.requiresRecharge = false,
    this.chargeThenStrikeEffect,
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
  ///
  /// BE9 ajoute aussi `BattleMoveTarget.field` pour les moves qui posent une
  /// météo ou un pseudoWeather réellement consommés par le moteur.
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
  /// - BE6-mini-fix-2 verrouille maintenant aussi la classe au niveau langage,
  ///   donc le contournement trivial par sous-classe externe disparaît ;
  /// - on garde en plus un getter validé, car un objet battle incohérent peut
  ///   encore apparaître via un futur mauvais refactor interne ;
  /// - le moteur garde enfin sa propre validation défensive au moment exact où
  ///   il consomme le ratio critique ; cette dernière garde reste une défense
  ///   en profondeur, pas la preuve principale du contrat public.
  final int _critRatio;

  int get critRatio {
    if (_critRatio < 1) {
      throw StateError(
        'BattleMoveData critRatio must be >= 1; got $_critRatio.',
      );
    }
    return _critRatio;
  }

  /// Effet battle minimal de statut majeur si le bridge runtime l'a autorisé.
  ///
  /// Ce champ reste volontairement simple :
  /// - pas de liste générique d'effets battle ;
  /// - pas de volatile status ;
  /// - pas de payload de scope, car le bridge BE7 ne laisse passer que
  ///   `targetScope: target`.
  final BattleMoveMajorStatusEffect? majorStatusEffect;

  /// Volatile auto-appliqué par le move dans le sous-ensemble BE8.
  final BattleVolatileStatusId? selfVolatileStatus;

  /// Météo de champ posée par ce move dans le sous-ensemble BE9.
  final BattleWeatherId? weatherEffect;

  /// PseudoWeather de champ posé par ce move dans le sous-ensemble BE9.
  final BattlePseudoWeatherId? pseudoWeatherEffect;

  /// true si ce move peut percer une protection active BE8.
  final bool breaksProtect;

  /// true si ce move demande ensuite un tour de recharge.
  final bool requiresRecharge;

  /// Payload battle minimal d'un move à charge sur deux tours.
  final BattleChargeThenStrikeEffect? chargeThenStrikeEffect;

  /// Changements d'étages de stats appliqués au lanceur.
  final List<BattleStatStageChange> selfStatStageChanges;

  /// Changements d'étages de stats appliqués à la cible.
  final List<BattleStatStageChange> targetStatStageChanges;
}

```

### packages/map_battle/lib/src/battle_state.dart

```dart
import 'battle_field.dart';
import 'battle_move.dart';
import 'battle_resolution.dart';
import 'battle_status.dart';
import 'battle_volatile.dart';
import 'battle_stats.dart';
import 'battle_typing.dart';

/// Phase du combat.
///
/// Représente l'état actuel du cycle de combat.
enum BattlePhase {
  /// En attente du choix du joueur.
  ///
  /// C'est la phase normale entre les tours.
  /// Le runtime doit appeler [BattleSession.getAvailableChoices()] pour
  /// afficher les options au joueur.
  playerChoice,

  /// Résolution en cours.
  ///
  /// Phase transitoire pendant laquelle le tour est en cours de résolution.
  /// Le runtime ne doit pas permettre de nouveaux choix pendant cette phase.
  resolving,

  /// Combat terminé.
  ///
  /// [BattleState.outcome] est non-null et contient le résultat final.
  /// Le runtime doit appeler `_onBattleFinished(outcome)` pour revenir à l'overworld.
  finished,
}

/// État immutable d'un combat.
///
/// Ce modèle représente l'état complet d'un combat à un instant donné.
/// Il est immutable : toutes les méthodes de modification retournent un nouvel état.
///
/// Invariants :
/// - Si [phase] == [BattlePhase.finished], alors [outcome] est non-null.
/// - Si [phase] != [BattlePhase.finished], alors [outcome] est null.
/// - [player.currentHp] est toujours entre 0 et [player.maxHp].
/// - [enemy.currentHp] est toujours entre 0 et [enemy.maxHp].
class BattleState {
  /// Crée un état de combat.
  ///
  /// [phase] - La phase actuelle du combat.
  /// [player] - Le combattant joueur.
  /// [enemy] - Le combattant adverse.
  /// [field] - L'état de champ observable (weather / pseudoWeather).
  /// [currentTurn] - Le résultat du tour en cours (null si aucun tour en cours).
  /// [outcome] - Le résultat final du combat (null si combat en cours).
  const BattleState({
    required this.phase,
    required this.player,
    this.playerReserve = const <BattleCombatant>[],
    required this.enemy,
    this.enemyReserve = const <BattleCombatant>[],
    this.field = const BattleFieldState(),
    this.currentTurn,
    this.outcome,
  });

  /// La phase actuelle du combat.
  final BattlePhase phase;

  /// Le combattant joueur.
  final BattleCombatant player;

  /// Réserve battle locale du joueur.
  ///
  /// BE10 garde ici un modèle très petit :
  /// - un seul actif ;
  /// - zéro ou plusieurs réserves ;
  /// - chaque membre reste un vrai `BattleCombatant`, donc avec ses PV,
  ///   moves/PP, statut majeur et typing déjà résolus.
  final List<BattleCombatant> playerReserve;

  /// Le combattant adverse.
  final BattleCombatant enemy;

  /// Réserve battle locale de l'adversaire.
  final List<BattleCombatant> enemyReserve;

  /// État de champ observable du combat.
  ///
  /// BE9 le porte directement dans `BattleState` pour éviter un nouveau
  /// mensonge :
  /// - la météo et Trick Room modifient maintenant réellement le moteur ;
  /// - ils ne doivent donc pas vivre comme un détail caché de résolution ;
  /// - le runtime et les tests peuvent relire cet état sans introspection
  ///   privée de `BattleSession`.
  final BattleFieldState field;

  /// Le résultat du tour en cours.
  ///
  /// Null si aucun tour n'est en cours (phase [playerChoice] ou [finished]).
  final BattleTurnResult? currentTurn;

  /// Le résultat final du combat.
  ///
  /// Non-null uniquement si [phase] == [BattlePhase.finished].
  final BattleOutcome? outcome;

  /// true si le combat est terminé.
  ///
  /// Raccourci pour `phase == BattlePhase.finished`.
  bool get isFinished => phase == BattlePhase.finished;
}

/// Combattant en combat.
///
/// Représente un Pokémon avec ses PV courants.
/// Immutable : utiliser [withDamage] pour créer une copie avec des PV modifiés.
///
/// Invariants :
/// - [currentHp] est toujours entre 0 et [maxHp].
/// - [isFainted] est true si et seulement si [currentHp] <= 0.
class BattleCombatant {
  /// Crée un combattant.
  ///
  /// [speciesId] - L'identifiant de l'espèce.
  /// [level] - Le niveau.
  /// [currentHp] - Les PV courants.
  /// [maxHp] - Les PV maximum.
  /// [stats] - Snapshot résolu des stats non-HP.
  /// [typing] - Typing battle minimal si connu.
  /// [majorStatus] - Statut majeur actuellement porté si le combattant en a un.
  /// [volatileState] - Sous-état volatile local BE8 (`protect`, recharge,
  ///   charge en attente).
  /// [abilityId] - L'ability réellement résolue si le runtime la connaît.
  /// [moves] - La liste des attaques disponibles.
  const BattleCombatant({
    required this.speciesId,
    this.lineupIndex = 0,
    required this.level,
    required this.currentHp,
    required this.maxHp,
    required this.stats,
    this.typing,
    this.majorStatus,
    this.volatileState = const BattleVolatileState(),
    this.abilityId = 'unknown',
    required this.moves,
    this.statStages = const BattleStatStages(),
  });

  /// L'identifiant de l'espèce.
  final String speciesId;

  /// Identité stable de lineup pour ce combattant.
  ///
  /// Voir `BattleCombatantData.lineupIndex` :
  /// - elle ne sert pas au gameplay direct ;
  /// - elle sert à préserver une identité stable malgré les switches ;
  /// - le runtime peut ensuite écrire les bons slots de party sans reconstruire
  ///   l'historique du combat.
  final int lineupIndex;

  /// Le niveau.
  final int level;

  /// Les PV courants.
  final int currentHp;

  /// Les PV maximum.
  final int maxHp;

  /// Snapshot résolu des stats non-HP.
  ///
  /// BE2 le transporte jusqu'à l'état battle pour que :
  /// - les moves physiques opposent enfin attaque vs défense ;
  /// - les moves spéciaux opposent enfin spécial vs spécial défense ;
  /// - `speed` survive au handoff jusqu'au moteur.
  ///
  /// BE3 commence ensuite à la consommer réellement pour l'ordre d'action,
  /// sans pour autant ouvrir toute une queue générique ni un système de
  /// précision / critique / résiduels.
  final BattleStatsSnapshot stats;

  /// Typing minimal du combattant si le setup le fournit.
  ///
  /// BE5 en a besoin pour fermer le trou où `type` était encore décoratif :
  /// - STAB dépend du typing de l'attaquant ;
  /// - résistances/faiblesses/immunités dépendent du typing du défenseur.
  ///
  /// Compatibilité résiduelle assumée :
  /// - un vieux setup direct `map_battle` peut encore laisser ce champ absent ;
  /// - dans ce cas, le moteur reste neutre sur la couche type au lieu de
  ///   fabriquer un typing par défaut qui mentirait davantage.
  final BattleTypingSnapshot? typing;

  /// Statut majeur actuellement porté par ce combattant.
  ///
  /// BE7 garde cet état volontairement étroit :
  /// - `null` signifie "aucun statut majeur" ;
  /// - sinon on porte uniquement `par`, `brn`, `psn` ou `tox` ;
  /// - il n'y a toujours ni volatiles génériques, ni `slp`, ni `frz`.
  final BattleMajorStatusState? majorStatus;

  /// Sous-état volatile local strictement borné à BE8.
  ///
  /// On évite volontairement un conteneur générique :
  /// - `protectActive` pour la fenêtre de protection du tour courant ;
  /// - `mustRecharge` pour le tour perdu suivant certains moves ;
  /// - `pendingCharge` pour la deuxième moitié d'un move à charge.
  final BattleVolatileState volatileState;

  /// L'ability réellement résolue pour ce combattant.
  ///
  /// Le moteur lot 13 n'en tire toujours aucun calcul de combat. On la transporte
  /// néanmoins jusqu'à l'issue finale pour permettre au runtime de persister un
  /// Pokémon capturé à partir du vrai ennemi engagé, sans données inventées.
  final String abilityId;

  /// La liste des attaques disponibles.
  ///
  /// À partir de BE4, les moves battle transportent aussi leur PP courant :
  /// - la liste n'est donc plus seulement descriptive ;
  /// - elle porte un vrai petit état mutable-mais-immutable du point de vue
  ///   des copies de session ;
  /// - on n'ouvre toujours pas de write-back runtime des PP hors combat.
  final List<BattleMove> moves;

  /// Étages de stats actuellement appliqués à ce combattant.
  ///
  /// M8 reste volontairement borné :
  /// - on ne porte que les stats utiles au petit sous-ensemble réellement
  ///   exécutable ;
  /// - BE3 ajoute `speed` parce qu'elle devient enfin une vraie donnée moteur
  ///   pour l'ordre d'action ;
  /// - les autres mécaniques (status, weather, précision, ordre d'action
  ///   complet, etc.) restent hors scope.
  final BattleStatStages statStages;

  /// true si le combattant est K.O.
  ///
  /// Un combattant est K.O. si ses PV courants sont <= 0.
  bool get isFainted => currentHp <= 0;

  /// Crée une copie de ce combattant avec des dégâts appliqués.
  ///
  /// [damage] - La quantité de dégâts à appliquer.
  ///
  /// Les PV sont clampés entre 0 et [maxHp].
  /// Cette méthode ne modifie pas cet objet (immutable).
  BattleCombatant withDamage(int damage) {
    return BattleCombatant(
      speciesId: speciesId,
      lineupIndex: lineupIndex,
      level: level,
      currentHp: (currentHp - damage).clamp(0, maxHp),
      maxHp: maxHp,
      stats: stats,
      typing: typing,
      majorStatus: majorStatus,
      volatileState: volatileState,
      abilityId: abilityId,
      moves: moves,
      statStages: statStages,
    );
  }

  /// Crée une copie de ce combattant avec des PV restaurés.
  ///
  /// [healAmount] - La quantité de PV à restaurer.
  ///
  /// Les PV sont clampés entre 0 et [maxHp].
  /// Cette méthode ne modifie pas cet objet (immutable).
  BattleCombatant withHeal(int healAmount) {
    return BattleCombatant(
      speciesId: speciesId,
      lineupIndex: lineupIndex,
      level: level,
      currentHp: (currentHp + healAmount).clamp(0, maxHp),
      maxHp: maxHp,
      stats: stats,
      typing: typing,
      majorStatus: majorStatus,
      volatileState: volatileState,
      abilityId: abilityId,
      moves: moves,
      statStages: statStages,
    );
  }

  /// Crée une copie de ce combattant avec des changements d'étages appliqués.
  ///
  /// Les étages sont toujours clampés dans la plage canonique minimale `[-6, 6]`.
  /// M8 ne gère ici que le sous-ensemble de stats réellement exploité par le
  /// moteur battle enrichi.
  BattleCombatant withAppliedStageChanges(
    List<BattleStatStageChange> changes,
  ) {
    if (changes.isEmpty) {
      return this;
    }
    return BattleCombatant(
      speciesId: speciesId,
      lineupIndex: lineupIndex,
      level: level,
      currentHp: currentHp,
      maxHp: maxHp,
      stats: stats,
      typing: typing,
      majorStatus: majorStatus,
      volatileState: volatileState,
      abilityId: abilityId,
      moves: moves,
      statStages: statStages.apply(changes),
    );
  }

  /// Crée une copie avec un slot move remplacé.
  ///
  /// BE4 évite ici une sur-architecture :
  /// - pas de nouveau sous-état `MoveState` parallèle ;
  /// - pas de map indexée future-proof ;
  /// - juste le plus petit helper honnête pour décrémenter les PP d'un slot.
  BattleCombatant withUpdatedMoveAt(int index, BattleMove updatedMove) {
    if (index < 0 || index >= moves.length) {
      throw RangeError.index(index, moves, 'index');
    }

    final updatedMoves = List<BattleMove>.of(moves);
    updatedMoves[index] = updatedMove;
    return BattleCombatant(
      speciesId: speciesId,
      lineupIndex: lineupIndex,
      level: level,
      currentHp: currentHp,
      maxHp: maxHp,
      stats: stats,
      typing: typing,
      majorStatus: majorStatus,
      volatileState: volatileState,
      abilityId: abilityId,
      moves: List<BattleMove>.unmodifiable(updatedMoves),
      statStages: statStages,
    );
  }

  /// Crée une copie avec un statut majeur mis à jour.
  ///
  /// Ce helper garde la transition d'état locale et lisible :
  /// - pas de builder parallèle de combattant ;
  /// - pas de mutation silencieuse d'un objet immutable ;
  /// - juste la plus petite brique utile pour `applyStatus`, la paralysie et
  ///   les résiduels de fin de tour.
  BattleCombatant withMajorStatus(BattleMajorStatusState? updatedStatus) {
    return BattleCombatant(
      speciesId: speciesId,
      lineupIndex: lineupIndex,
      level: level,
      currentHp: currentHp,
      maxHp: maxHp,
      stats: stats,
      typing: typing,
      majorStatus: updatedStatus,
      volatileState: volatileState,
      abilityId: abilityId,
      moves: moves,
      statStages: statStages,
    );
  }

  /// Crée une copie avec un sous-état volatile mis à jour.
  ///
  /// BE8 garde cette transition locale et lisible :
  /// - pas de mutation silencieuse ;
  /// - pas de builder parallèle ;
  /// - juste le plus petit helper immutable utile pour `Protect`, la recharge
  ///   et les moves à charge.
  BattleCombatant withVolatileState(BattleVolatileState updatedVolatileState) {
    return BattleCombatant(
      speciesId: speciesId,
      lineupIndex: lineupIndex,
      level: level,
      currentHp: currentHp,
      maxHp: maxHp,
      stats: stats,
      typing: typing,
      majorStatus: majorStatus,
      volatileState: updatedVolatileState,
      abilityId: abilityId,
      moves: moves,
      statStages: statStages,
    );
  }

  /// Prépare ce combattant à retourner en réserve après un switch.
  ///
  /// Politique BE10 explicitement bornée :
  /// - on conserve les PV courants ;
  /// - on conserve les PP courants ;
  /// - on conserve le statut majeur ;
  /// - mais on nettoie tout ce qui n'a de sens que "sur le terrain" :
  ///   stages, protect, recharge, charge en attente ;
  /// - `tox` garde le statut majeur, mais son compteur local repart à `1`
  ///   pour éviter que le switch rende BE7 mensonger.
  BattleCombatant resetForReserveOnSwitchOut() {
    return BattleCombatant(
      speciesId: speciesId,
      lineupIndex: lineupIndex,
      level: level,
      currentHp: currentHp,
      maxHp: maxHp,
      stats: stats,
      typing: typing,
      majorStatus: majorStatus?.resetOnSwitchOut(),
      volatileState: volatileState.clearedOnSwitchOut(),
      abilityId: abilityId,
      moves: moves,
      statStages: const BattleStatStages(),
    );
  }
}

/// Étages de stats utilisables par le moteur battle MVP enrichi.
///
/// On évite volontairement une structure générique "Map<Stat, int>" :
/// - le moteur n'a besoin que d'un petit sous-ensemble ;
/// - cette forme garde des accès simples et des invariants lisibles ;
/// - elle évite d'ouvrir de faux besoins "future-proof" trop tôt.
class BattleStatStages {
  const BattleStatStages({
    this.attack = 0,
    this.defense = 0,
    this.specialAttack = 0,
    this.specialDefense = 0,
    this.speed = 0,
  });

  final int attack;
  final int defense;
  final int specialAttack;
  final int specialDefense;
  final int speed;

  /// Retourne une copie avec les changements demandés appliqués.
  BattleStatStages apply(List<BattleStatStageChange> changes) {
    var updated = this;
    for (final change in changes) {
      updated = updated._applyOne(change);
    }
    return updated;
  }

  BattleStatStages _applyOne(BattleStatStageChange change) {
    switch (change.stat) {
      case BattleStatId.attack:
        return BattleStatStages(
          attack: _clampStage(attack + change.stages),
          defense: defense,
          specialAttack: specialAttack,
          specialDefense: specialDefense,
          speed: speed,
        );
      case BattleStatId.defense:
        return BattleStatStages(
          attack: attack,
          defense: _clampStage(defense + change.stages),
          specialAttack: specialAttack,
          specialDefense: specialDefense,
          speed: speed,
        );
      case BattleStatId.specialAttack:
        return BattleStatStages(
          attack: attack,
          defense: defense,
          specialAttack: _clampStage(specialAttack + change.stages),
          specialDefense: specialDefense,
          speed: speed,
        );
      case BattleStatId.specialDefense:
        return BattleStatStages(
          attack: attack,
          defense: defense,
          specialAttack: specialAttack,
          specialDefense: _clampStage(specialDefense + change.stages),
          speed: speed,
        );
      case BattleStatId.speed:
        return BattleStatStages(
          attack: attack,
          defense: defense,
          specialAttack: specialAttack,
          specialDefense: specialDefense,
          speed: _clampStage(speed + change.stages),
        );
    }
  }

  /// Retourne le multiplicateur utilisé par le calcul de dégâts MVP enrichi.
  ///
  /// On reprend la table canonique simplifiée des stages Pokémon :
  /// - stage 0 => 1.0
  /// - stage +1 => 1.5
  /// - stage +2 => 2.0
  /// - stage -1 => 2/3
  /// etc.
  ///
  /// Cela suffit pour rendre les boosts/débuffs battle réellement visibles,
  /// sans ouvrir les vraies stats détaillées du moteur complet.
  double multiplierFor(BattleStatId stat) {
    final stage = switch (stat) {
      BattleStatId.attack => attack,
      BattleStatId.defense => defense,
      BattleStatId.specialAttack => specialAttack,
      BattleStatId.specialDefense => specialDefense,
      BattleStatId.speed => speed,
    };
    if (stage >= 0) {
      return (2 + stage) / 2;
    }
    return 2 / (2 - stage);
  }

  int _clampStage(int value) => value.clamp(-6, 6);
}

```

### packages/map_battle/lib/src/battle_status.dart

```dart
/// Identifiant minimal de statut majeur réellement supporté par le moteur.
///
/// BE7 ouvre volontairement un seul sous-ensemble :
/// - `par`
/// - `brn`
/// - `psn`
/// - `tox`
///
/// Tout le reste reste explicitement hors scope :
/// - pas de `slp`
/// - pas de `frz`
/// - pas de confusion
/// - pas de système générique de volatiles.
enum BattleMajorStatusId {
  par,
  brn,
  psn,
  tox,
}

/// État minimal d'un statut majeur porté par un combattant battle.
///
/// Ce contrat reste volontairement petit :
/// - il porte seulement quel statut majeur est actif ;
/// - il ajoute un compteur toxique local pour `tox` ;
/// - il n'essaie pas d'anticiper un futur système de statuts générique.
///
/// Le compteur toxique suit une règle très simple :
/// - `tox` commence à `1` ;
/// - le résiduel de fin de tour consomme cette valeur ;
/// - si le combattant survit, on l'incrémente pour le tour suivant.
final class BattleMajorStatusState {
  const BattleMajorStatusState.par()
      : id = BattleMajorStatusId.par,
        toxicCounter = 0;

  const BattleMajorStatusState.brn()
      : id = BattleMajorStatusId.brn,
        toxicCounter = 0;

  const BattleMajorStatusState.psn()
      : id = BattleMajorStatusId.psn,
        toxicCounter = 0;

  const BattleMajorStatusState.tox({
    this.toxicCounter = 1,
  })  : assert(toxicCounter >= 1),
        id = BattleMajorStatusId.tox;

  final BattleMajorStatusId id;

  /// Compteur local du poison toxique.
  ///
  /// Pour les autres statuts, cette valeur reste à `0` et n'a aucune
  /// sémantique métier.
  final int toxicCounter;

  bool get isToxic => id == BattleMajorStatusId.tox;

  BattleMajorStatusState incrementToxicCounter() {
    if (!isToxic) {
      return this;
    }
    return BattleMajorStatusState.tox(
      toxicCounter: toxicCounter + 1,
    );
  }

  /// Réinitialise l'état local qui ne doit pas survivre à un switch-out.
  ///
  /// BE10 garde une politique très étroite :
  /// - `par`, `brn`, `psn` restent inchangés ;
  /// - `tox` reste bien `tox` ;
  /// - mais sa progression locale repart à `1` quand le Pokémon quitte puis
  ///   revient sur le terrain.
  BattleMajorStatusState resetOnSwitchOut() {
    if (!isToxic) {
      return this;
    }
    return const BattleMajorStatusState.tox();
  }
}

/// Effet battle minimal pour `applyStatus`.
///
/// Le bridge runtime -> battle traduit `PokemonMoveEffect.applyStatus` vers ce
/// contrat local seulement quand le sous-ensemble BE7 est réellement
/// exécutable. Il ne transporte pas la totalité du payload canonique :
/// - scope `target` seulement ;
/// - `chancePercent == null` pour un status garanti sur hit ;
/// - `chancePercent` entre 1 et 100 pour un status probabiliste.
final class BattleMoveMajorStatusEffect {
  const BattleMoveMajorStatusEffect({
    required this.status,
    this.chancePercent,
  }) : assert(
          chancePercent == null || (chancePercent >= 1 && chancePercent <= 100),
          'BattleMoveMajorStatusEffect chancePercent must be null or between 1 and 100.',
        );

  final BattleMajorStatusId status;
  final int? chancePercent;
}

/// Petite taxonomie des événements de statut visibles dans le résultat de tour.
///
/// BE7 ne crée pas un event bus général. On garde seulement ce qui évite une
/// mutation silencieuse :
/// - application d'un statut majeur ;
/// - blocage parce qu'un statut majeur existe déjà ;
/// - impossibilité d'agir à cause de la paralysie ;
/// - dégâts résiduels de fin de tour.
enum BattleStatusEventKind {
  applied,
  blockedExistingMajorStatus,
  preventedAction,
  residualDamage,
}

/// Trace minimale d'un événement de statut pendant un tour.
///
/// Ce contrat existe pour deux raisons :
/// - éviter que les statuts/résiduels modifient l'état sans trace ;
/// - rester assez petit pour ne pas ressembler à un journal d'événements
///   générique du moteur.
final class BattleStatusEvent {
  const BattleStatusEvent.applied({
    required this.target,
    required this.status,
    required this.sourceMoveId,
  })  : kind = BattleStatusEventKind.applied,
        damage = null,
        toxicCounter = null,
        existingStatus = null;

  const BattleStatusEvent.blockedExistingMajorStatus({
    required this.target,
    required this.status,
    required this.existingStatus,
    required this.sourceMoveId,
  })  : kind = BattleStatusEventKind.blockedExistingMajorStatus,
        damage = null,
        toxicCounter = null;

  const BattleStatusEvent.preventedAction({
    required this.target,
    required this.status,
  })  : kind = BattleStatusEventKind.preventedAction,
        sourceMoveId = null,
        damage = null,
        toxicCounter = null,
        existingStatus = null;

  const BattleStatusEvent.residualDamage({
    required this.target,
    required this.status,
    required this.damage,
    this.toxicCounter,
  })  : kind = BattleStatusEventKind.residualDamage,
        sourceMoveId = null,
        existingStatus = null;

  /// Combattant ciblé par l'événement (`player` ou `enemy`).
  final String target;

  final BattleStatusEventKind kind;
  final BattleMajorStatusId status;
  final String? sourceMoveId;
  final int? damage;
  final int? toxicCounter;
  final BattleMajorStatusId? existingStatus;
}

```

### packages/map_battle/lib/src/battle_switch.dart

```dart
/// Petite taxonomie des événements de switch/réserve visibles dans un tour.
///
/// BE10 reste volontairement très borné :
/// - pas de système de slots façon doubles ;
/// - pas de pipeline générique de selfSwitch / forceSwitch ;
/// - pas de journal universel ;
/// - seulement ce qu'il faut pour ne pas muter les actifs/réserves en silence.
enum BattleSwitchEventKind {
  switched,
  replacementRequired,
}

/// Trace minimale d'un switch ou d'un remplacement forcé.
///
/// Ce contrat sépare volontairement les événements de roster des :
/// - `BattleStatusEvent` (statuts majeurs) ;
/// - `BattleVolatileEvent` (protect/recharge/charge) ;
/// - `BattleFieldEvent` (weather/pseudoWeather).
///
/// Cela garde chaque couche lisible et évite de transformer `BattleTurnResult`
/// en sac de booléens croisés.
final class BattleSwitchEvent {
  const BattleSwitchEvent.switched({
    required this.actor,
    required this.fromSpeciesId,
    required this.toSpeciesId,
    required this.wasForced,
  }) : kind = BattleSwitchEventKind.switched;

  const BattleSwitchEvent.replacementRequired({
    required this.actor,
    required this.fromSpeciesId,
  })  : kind = BattleSwitchEventKind.replacementRequired,
        toSpeciesId = null,
        wasForced = true;

  /// Combattant concerné (`player` ou `enemy`).
  final String actor;

  final BattleSwitchEventKind kind;

  /// Espèce qui quitte le terrain.
  ///
  /// Sur `replacementRequired`, c'est l'espèce K.O. que le joueur doit
  /// remplacer avant de pouvoir reprendre un tour normal.
  final String fromSpeciesId;

  /// Espèce qui entre sur le terrain quand un switch a réellement eu lieu.
  final String? toSpeciesId;

  /// `true` pour un remplacement contraint par un K.O., `false` pour un
  /// switch volontaire du joueur.
  final bool wasForced;
}

```

### packages/map_battle/lib/src/battle_volatile.dart

```dart
/// Identifiant minimal de volatile réellement supporté par BE8.
///
/// On n'ouvre volontairement pas une taxonomie générique de volatiles :
/// - BE8 n'a besoin que de `protect` ;
/// - le reste (`confusion`, `substitute`, semi-invulnérabilité, etc.) reste
///   explicitement hors scope ;
/// - ce type documente donc un sous-ensemble battle local, pas un futur
///   catalogue complet de mécaniques.
enum BattleVolatileStatusId {
  protect,
}

/// Petit payload battle pour un move à charge sur deux tours.
///
/// BE8 choisit un contrat volontairement minimal :
/// - `chargeStateId` reste optionnel, uniquement pour garder une trace lisible
///   quand la donnée canonique en fournit une ;
/// - aucun système générique de "phases de move" n'est ouvert ;
/// - ce payload n'a de sens que pour `chargeThenStrike`.
final class BattleChargeThenStrikeEffect {
  const BattleChargeThenStrikeEffect({
    this.chargeStateId,
  });

  final String? chargeStateId;
}

/// État local du move actuellement chargé sur le combattant.
///
/// On porte exactement ce que le moteur doit retrouver au tour suivant :
/// - quel slot move doit être rejoué ;
/// - quel move est attendu, pour protéger le moteur d'un état incohérent ;
/// - un éventuel `chargeStateId` lisible pour la trace.
final class BattlePendingChargeState {
  const BattlePendingChargeState({
    required this.moveIndex,
    required this.moveId,
    this.chargeStateId,
  });

  final int moveIndex;
  final String moveId;
  final String? chargeStateId;
}

/// Sous-état volatile battle local du combattant.
///
/// Invariants BE8 :
/// - `protectActive` ne vaut que pour le tour courant et doit être nettoyé en
///   fin de tour ;
/// - `mustRecharge` représente uniquement le tour perdu qui suit certains
///   moves ; il ne doit pas coexister avec un move chargé en attente ;
/// - `pendingCharge` représente uniquement la deuxième moitié d'un move à
///   charge, sans ouvrir une pile de verrous/actions forcées.
final class BattleVolatileState {
  const BattleVolatileState({
    this.protectActive = false,
    this.mustRecharge = false,
    this.pendingCharge,
  }) : assert(
          !(mustRecharge && pendingCharge != null),
          'A battle combatant cannot be both recharging and holding a pending charged move.',
        );

  final bool protectActive;
  final bool mustRecharge;
  final BattlePendingChargeState? pendingCharge;

  bool get hasAny => protectActive || mustRecharge || pendingCharge != null;

  BattleVolatileState withProtectActive(bool value) {
    if (protectActive == value) {
      return this;
    }
    return BattleVolatileState(
      protectActive: value,
      mustRecharge: mustRecharge,
      pendingCharge: pendingCharge,
    );
  }

  BattleVolatileState withMustRecharge(bool value) {
    if (mustRecharge == value) {
      return this;
    }
    return BattleVolatileState(
      protectActive: protectActive,
      mustRecharge: value,
      pendingCharge: pendingCharge,
    );
  }

  BattleVolatileState withPendingCharge(BattlePendingChargeState? value) {
    if (pendingCharge == value) {
      return this;
    }
    return BattleVolatileState(
      protectActive: protectActive,
      mustRecharge: mustRecharge,
      pendingCharge: value,
    );
  }

  /// Nettoie les marqueurs qui ne doivent jamais survivre au tour suivant.
  ///
  /// BE8 garde cette règle explicite au niveau du petit contrat local :
  /// - `protect` protège uniquement pendant la fenêtre de résolution du tour ;
  /// - ni les résiduels BE7 ni le tour suivant ne doivent encore le voir actif ;
  /// - `mustRecharge` et `pendingCharge`, eux, vivent au-delà du tour et ne
  ///   doivent donc pas être effacés ici.
  BattleVolatileState clearedEndOfTurnFlags() {
    if (!protectActive) {
      return this;
    }
    return BattleVolatileState(
      protectActive: false,
      mustRecharge: mustRecharge,
      pendingCharge: pendingCharge,
    );
  }

  /// Nettoie intégralement les volatiles qui ne survivent pas à un switch-out.
  ///
  /// BE10 choisit ici une règle franche plutôt qu'une taxonomie progressive :
  /// - `Protect` n'a plus aucun sens une fois sur le banc ;
  /// - `mustRecharge` ne doit jamais forcer un Pokémon qui a quitté le terrain ;
  /// - `pendingCharge` ne doit jamais survivre à un switch ;
  /// - on revient donc à l'état vide, sans ouvrir un système générique de
  ///   "volatiles persistants".
  BattleVolatileState clearedOnSwitchOut() {
    if (!hasAny) {
      return this;
    }
    return const BattleVolatileState();
  }
}

/// Taxonomie minimale des événements volatiles visibles dans un tour.
///
/// BE8 n'étend pas `statusEvents` pour tout mélanger :
/// - les statuts majeurs et les volatiles n'ont pas la même temporalité ;
/// - `protect`, `mustRecharge` et `chargeThenStrike` ont besoin d'une trace
///   propre sans grossir `BattleMoveExecution` jusqu'à l'illisible ;
/// - on garde donc une petite liste sœur, bornée au lot BE8.
enum BattleVolatileEventKind {
  protectActivated,
  protectBlocked,
  protectBroken,
  rechargeRequired,
  rechargeTurnSpent,
  chargeStarted,
  chargeReleased,
}

/// Trace minimale d'un événement volatile pendant un tour.
///
/// Le contrat reste volontairement petit :
/// - pas de bus d'événements ;
/// - pas de payload dynamique ;
/// - juste les champs nécessaires pour expliquer ce qu'un tour BE8 a vraiment
///   fait ou empêché.
final class BattleVolatileEvent {
  const BattleVolatileEvent.protectActivated({
    required this.actor,
    required this.sourceMoveId,
  })  : kind = BattleVolatileEventKind.protectActivated,
        target = null,
        chargeStateId = null;

  const BattleVolatileEvent.protectBlocked({
    required this.actor,
    required this.target,
    required this.sourceMoveId,
  })  : kind = BattleVolatileEventKind.protectBlocked,
        chargeStateId = null;

  const BattleVolatileEvent.protectBroken({
    required this.actor,
    required this.target,
    required this.sourceMoveId,
  })  : kind = BattleVolatileEventKind.protectBroken,
        chargeStateId = null;

  const BattleVolatileEvent.rechargeRequired({
    required this.actor,
    required this.sourceMoveId,
  })  : kind = BattleVolatileEventKind.rechargeRequired,
        target = null,
        chargeStateId = null;

  const BattleVolatileEvent.rechargeTurnSpent({
    required this.actor,
  })  : kind = BattleVolatileEventKind.rechargeTurnSpent,
        target = null,
        sourceMoveId = null,
        chargeStateId = null;

  const BattleVolatileEvent.chargeStarted({
    required this.actor,
    required this.sourceMoveId,
    this.chargeStateId,
  })  : kind = BattleVolatileEventKind.chargeStarted,
        target = null;

  const BattleVolatileEvent.chargeReleased({
    required this.actor,
    required this.sourceMoveId,
    this.chargeStateId,
  })  : kind = BattleVolatileEventKind.chargeReleased,
        target = null;

  /// Combattant qui a provoqué l'événement (`player` ou `enemy`).
  final String actor;

  /// Cible explicite quand l'événement a une cible distincte.
  final String? target;

  final BattleVolatileEventKind kind;
  final String? sourceMoveId;
  final String? chargeStateId;
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
        'createBattleSession preserves the additional honest battle contract fields transported by BE1 through BE9',
        () {
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 20,
          stats: _neutralBattleStats,
          typing: const BattleTypingSnapshot(primaryType: 'electric'),
          volatileState: const BattleVolatileState(
            mustRecharge: true,
          ),
          moves: const [
            BattleMoveData(
              id: 'protect',
              name: 'Protect',
              power: 0,
              type: 'normal',
              category: BattleMoveCategory.status,
              target: BattleMoveTarget.self,
              accuracy: BattleMoveAccuracy.alwaysHits(),
              pp: 10,
              currentPp: 7,
              priority: 1,
              critRatio: 2,
              selfVolatileStatus: BattleVolatileStatusId.protect,
            ),
            BattleMoveData(
              id: 'hyper_beam',
              name: 'Hyper Beam',
              power: 150,
              type: 'normal',
              category: BattleMoveCategory.special,
              target: BattleMoveTarget.opponent,
              pp: 5,
              currentPp: 3,
              requiresRecharge: true,
            ),
            BattleMoveData(
              id: 'solar_beam',
              name: 'Solar Beam',
              power: 120,
              type: 'grass',
              category: BattleMoveCategory.special,
              target: BattleMoveTarget.opponent,
              pp: 10,
              currentPp: 9,
              chargeThenStrikeEffect: BattleChargeThenStrikeEffect(
                chargeStateId: 'solar_charge',
              ),
            ),
            BattleMoveData(
              id: 'feint',
              name: 'Feint',
              power: 30,
              type: 'normal',
              category: BattleMoveCategory.physical,
              target: BattleMoveTarget.opponent,
              breaksProtect: true,
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
          volatileState: const BattleVolatileState(
            pendingCharge: BattlePendingChargeState(
              moveIndex: 0,
              moveId: 'tackle',
              chargeStateId: 'stored_charge',
            ),
          ),
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
          ],
        ),
        isTrainerBattle: false,
        trainerId: null,
        fieldState: const BattleFieldState(
          weather: BattleWeatherState(
            id: BattleWeatherId.rain,
            remainingTurns: 3,
          ),
          pseudoWeather: BattlePseudoWeatherState(
            id: BattlePseudoWeatherId.trickRoom,
            remainingTurns: 2,
          ),
        ),
      );

      final session = createBattleSession(setup);
      final protect = session.state.player.moves[0];
      final hyperBeam = session.state.player.moves[1];
      final solarBeam = session.state.player.moves[2];
      final feint = session.state.player.moves[3];
      final playerTyping = session.state.player.typing!;
      final enemyTyping = session.state.enemy.typing!;

      expect(protect.type, equals('normal'));
      expect(protect.category, equals(BattleMoveCategory.status));
      expect(protect.target, equals(BattleMoveTarget.self));
      expect(protect.accuracy.kind, equals(BattleMoveAccuracyKind.alwaysHits));
      expect(protect.pp, equals(10));
      expect(protect.currentPp, equals(7));
      expect(protect.priority, equals(1));
      expect(protect.critRatio, equals(2));
      expect(
        protect.selfVolatileStatus,
        equals(BattleVolatileStatusId.protect),
      );
      expect(hyperBeam.requiresRecharge, isTrue);
      expect(solarBeam.chargeThenStrikeEffect?.chargeStateId,
          equals('solar_charge'));
      expect(feint.breaksProtect, isTrue);
      expect(playerTyping.primaryType, equals('electric'));
      expect(playerTyping.secondaryType, isNull);
      expect(enemyTyping.primaryType, equals('water'));
      expect(enemyTyping.secondaryType, equals('ice'));
      expect(session.state.player.volatileState.mustRecharge, isTrue);
      expect(
        session.state.enemy.volatileState.pendingCharge?.moveId,
        equals('tackle'),
      );
      expect(session.state.field.weather?.id, equals(BattleWeatherId.rain));
      expect(session.state.field.weather?.remainingTurns, equals(3));
      expect(
        session.state.field.pseudoWeather?.id,
        equals(BattlePseudoWeatherId.trickRoom),
      );
      expect(session.state.field.pseudoWeather?.remainingTurns, equals(2));
    });

    test(
        'createBattleSession preserves an explicit major status seed and move status effect',
        () {
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 20,
          stats: _neutralBattleStats,
          majorStatus: const BattleMajorStatusState.brn(),
          moves: const [
            BattleMoveData(
              id: 'thunder_wave',
              name: 'Thunder Wave',
              power: 0,
              category: BattleMoveCategory.status,
              majorStatusEffect: BattleMoveMajorStatusEffect(
                status: BattleMajorStatusId.par,
              ),
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

      expect(session.state.player.majorStatus?.id,
          equals(BattleMajorStatusId.brn));
      expect(
        session.state.player.moves.single.majorStatusEffect?.status,
        equals(BattleMajorStatusId.par),
      );
    });

    test('createBattleSession preserves reserves and stable lineup identities',
        () {
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'lead_player',
          lineupIndex: 0,
          level: 5,
          maxHp: 20,
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
          ],
        ),
        playerReservePokemon: const <BattleCombatantData>[
          BattleCombatantData(
            speciesId: 'bench_player',
            lineupIndex: 1,
            level: 5,
            maxHp: 22,
            currentHp: 18,
            stats: _neutralBattleStats,
            moves: <BattleMoveData>[
              BattleMoveData(id: 'growl', name: 'Growl', power: 0),
            ],
          ),
        ],
        enemyPokemon: BattleCombatantData(
          speciesId: 'lead_enemy',
          lineupIndex: 0,
          level: 5,
          maxHp: 25,
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
          ],
        ),
        enemyReservePokemon: const <BattleCombatantData>[
          BattleCombatantData(
            speciesId: 'bench_enemy',
            lineupIndex: 1,
            level: 5,
            maxHp: 24,
            stats: _neutralBattleStats,
            moves: <BattleMoveData>[
              BattleMoveData(id: 'growl', name: 'Growl', power: 0),
            ],
          ),
        ],
        isTrainerBattle: true,
        trainerId: 'trainer-reserve',
      );

      final session = createBattleSession(setup);

      expect(session.state.player.lineupIndex, equals(0));
      expect(session.state.playerReserve.single.lineupIndex, equals(1));
      expect(session.state.playerReserve.single.currentHp, equals(18));
      expect(session.state.enemy.lineupIndex, equals(0));
      expect(session.state.enemyReserve.single.lineupIndex, equals(1));
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

    test('BattleMoveData keeps a valid crit ratio unchanged', () {
      // Mini-fix BE6-2 :
      // - on supprime les faux tests qui contournaient le contrat par héritage ;
      // - le vrai contrat public doit maintenant être évalué tel qu'il est
      //   réellement exposé aux call sites : un DTO final, `const`, typé ;
      // - ce test vérifie simplement qu'une valeur valide reste stable.
      const move = BattleMoveData(
        id: 'slash',
        name: 'Slash',
        power: 50,
        critRatio: 2,
      );

      expect(move.critRatio, equals(2));
    });

    test('BattleMove.withConsumedPp preserves a valid crit ratio', () {
      // Ce test remplace honnêtement l'ancien scénario artificiel :
      // - on ne forge plus un move malformé via override ;
      // - on vérifie que le vrai contrat public battle conserve `critRatio`
      //   pendant une transition d'état normale du moteur.
      const move = BattleMove(
        id: 'slash',
        name: 'Slash',
        power: 50,
        pp: 10,
        currentPp: 3,
        critRatio: 3,
      );

      final consumed = move.withConsumedPp();

      expect(consumed.critRatio, equals(3));
      expect(consumed.currentPp, equals(2));
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

    test('getAvailableChoices exposes Continue for a forced recharge turn', () {
      final session = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'pikachu',
            level: 5,
            maxHp: 20,
            stats: _neutralBattleStats,
            volatileState: const BattleVolatileState(
              mustRecharge: true,
            ),
            moves: const [
              BattleMoveData(
                id: 'hyper_beam',
                name: 'Hyper Beam',
                power: 150,
                requiresRecharge: true,
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
        ),
      );

      final choices = session.getAvailableChoices();

      expect(choices, hasLength(1));
      expect(choices.single, isA<PlayerBattleChoiceContinue>());
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

### packages/map_battle/test/battle_switch_test.dart

```dart
import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

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

BattleMoveData _waitingMove() {
  return const BattleMoveData(
    id: 'wait',
    name: 'Wait',
    power: 0,
    category: BattleMoveCategory.status,
    target: BattleMoveTarget.self,
    accuracy: BattleMoveAccuracy.alwaysHits(),
  );
}

BattleMoveData _tackle({
  int power = 40,
}) {
  return BattleMoveData(
    id: 'tackle',
    name: 'Tackle',
    power: power,
    type: 'normal',
    category: BattleMoveCategory.physical,
    target: BattleMoveTarget.opponent,
  );
}

BattleCombatantData _combatant({
  required String speciesId,
  required int lineupIndex,
  int maxHp = 40,
  int? currentHp,
  BattleStatsSnapshot? stats,
  BattleMajorStatusState? majorStatus,
  BattleVolatileState volatileState = const BattleVolatileState(),
  required List<BattleMoveData> moves,
}) {
  return BattleCombatantData(
    speciesId: speciesId,
    lineupIndex: lineupIndex,
    level: 30,
    maxHp: maxHp,
    currentHp: currentHp,
    stats: stats ?? _stats(),
    majorStatus: majorStatus,
    volatileState: volatileState,
    moves: moves,
  );
}

BattleSession _session({
  required BattleCombatantData player,
  List<BattleCombatantData> playerReserve = const <BattleCombatantData>[],
  required BattleCombatantData enemy,
  List<BattleCombatantData> enemyReserve = const <BattleCombatantData>[],
  bool isTrainerBattle = false,
  BattleRng rng = const BattleSeededRng(),
}) {
  return createBattleSession(
    BattleSetup(
      playerPokemon: player,
      playerReservePokemon: playerReserve,
      enemyPokemon: enemy,
      enemyReservePokemon: enemyReserve,
      isTrainerBattle: isTrainerBattle,
      trainerId: isTrainerBattle ? 'trainer' : null,
    ),
    rng: rng,
  );
}

void main() {
  group('BattleSession BE10 switches and reserves', () {
    test('trainer enemy auto-replaces instead of ending the battle on first KO',
        () {
      final session = _session(
        isTrainerBattle: true,
        player: _combatant(
          speciesId: 'lead_player',
          lineupIndex: 0,
          stats: _stats(speed: 90, attack: 100),
          moves: <BattleMoveData>[
            _tackle(power: 200),
          ],
        ),
        enemy: _combatant(
          speciesId: 'lead_enemy',
          lineupIndex: 0,
          stats: _stats(speed: 20),
          moves: <BattleMoveData>[_waitingMove()],
        ),
        enemyReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'bench_enemy',
            lineupIndex: 1,
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterTurn.state.isFinished, isFalse);
      expect(afterTurn.state.enemy.speciesId, equals('bench_enemy'));
      expect(
          afterTurn.state.enemyReserve.single.speciesId, equals('lead_enemy'));
      final switchEvent = afterTurn.state.currentTurn!.switchEvents.single;
      expect(switchEvent.actor, equals('enemy'));
      expect(switchEvent.kind, equals(BattleSwitchEventKind.switched));
      expect(switchEvent.wasForced, isTrue);
    });

    test(
        'forced replacement choices override stale recharge/charge state on a KO active',
        () {
      final session = _session(
        player: _combatant(
          speciesId: 'fainted_player',
          lineupIndex: 0,
          currentHp: 0,
          volatileState: const BattleVolatileState(
            pendingCharge: BattlePendingChargeState(
              moveIndex: 0,
              moveId: 'beam',
              chargeStateId: 'charge',
            ),
          ),
          moves: <BattleMoveData>[
            const BattleMoveData(
              id: 'beam',
              name: 'Beam',
              power: 80,
              category: BattleMoveCategory.special,
              chargeThenStrikeEffect: BattleChargeThenStrikeEffect(
                chargeStateId: 'charge',
              ),
            ),
          ],
        ),
        playerReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'bench_player',
            lineupIndex: 1,
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
        enemy: _combatant(
          speciesId: 'enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
      );

      final choices = session.getAvailableChoices();

      expect(choices.whereType<PlayerBattleChoiceContinue>(), isEmpty);
      expect(choices.whereType<PlayerBattleChoiceFight>(), isEmpty);
      expect(choices.whereType<PlayerBattleChoiceSwitch>().single.reserveIndex,
          equals(0));

      final afterReplacement =
          session.applyChoice(const PlayerBattleChoiceSwitch(0));

      expect(afterReplacement.state.player.speciesId, equals('bench_player'));
      expect(afterReplacement.state.playerReserve.single.speciesId,
          equals('fainted_player'));
      expect(
        afterReplacement.state.playerReserve.single.volatileState.hasAny,
        isFalse,
      );
      expect(
        afterReplacement.state.currentTurn!.enemyAction,
        isA<BattleActionNone>(),
      );
      expect(
        afterReplacement.state.currentTurn!.switchEvents.single.wasForced,
        isTrue,
      );
    });

    test('voluntary switch resolves before an opposing attack and redirects it',
        () {
      final session = _session(
        player: _combatant(
          speciesId: 'lead_player',
          lineupIndex: 0,
          maxHp: 35,
          currentHp: 35,
          stats: _stats(speed: 20),
          moves: <BattleMoveData>[_waitingMove()],
        ),
        playerReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'bench_player',
            lineupIndex: 1,
            maxHp: 50,
            currentHp: 50,
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
        enemy: _combatant(
          speciesId: 'enemy',
          lineupIndex: 0,
          stats: _stats(speed: 100, attack: 80),
          moves: <BattleMoveData>[_tackle(power: 35)],
        ),
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceSwitch(0));

      expect(afterTurn.state.player.speciesId, equals('bench_player'));
      expect(afterTurn.state.player.currentHp, lessThan(50));
      expect(
        afterTurn.state.playerReserve.single.speciesId,
        equals('lead_player'),
      );
      expect(
        afterTurn.state.playerReserve.single.currentHp,
        equals(35),
      );
      expect(
        afterTurn.state.currentTurn!.switchEvents.single.wasForced,
        isFalse,
      );
    });

    test(
        'switching out resets stages and volatile baggage but keeps hp, pp, and major status while tox counter restarts at 1',
        () {
      final session = _session(
        player: _combatant(
          speciesId: 'lead_player',
          lineupIndex: 0,
          currentHp: 27,
          majorStatus: const BattleMajorStatusState.tox(toxicCounter: 4),
          stats: _stats(speed: 80),
          moves: <BattleMoveData>[
            const BattleMoveData(
              id: 'swords_dance',
              name: 'Swords Dance',
              power: 0,
              category: BattleMoveCategory.status,
              target: BattleMoveTarget.self,
              selfStatStageChanges: <BattleStatStageChange>[
                BattleStatStageChange(stat: BattleStatId.attack, stages: 2),
              ],
            ),
            const BattleMoveData(
              id: 'tackle',
              name: 'Tackle',
              power: 40,
              category: BattleMoveCategory.physical,
              currentPp: 7,
              pp: 35,
            ),
          ],
        ),
        playerReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'bench_player',
            lineupIndex: 1,
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
        enemy: _combatant(
          speciesId: 'enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
      );

      final afterBoost = session.applyChoice(const PlayerBattleChoiceFight(0));
      expect(afterBoost.state.player.statStages.attack, equals(2));

      final afterSwitchOut =
          afterBoost.applyChoice(const PlayerBattleChoiceSwitch(0));
      final benchedLead = afterSwitchOut.state.playerReserve.singleWhere(
        (combatant) => combatant.speciesId == 'lead_player',
      );
      expect(benchedLead.statStages.attack, equals(0));
      expect(
        benchedLead.currentHp,
        equals(afterBoost.state.player.currentHp),
      );
      expect(benchedLead.moves[1].currentPp, equals(7));
      expect(benchedLead.majorStatus!.id, equals(BattleMajorStatusId.tox));
      expect(benchedLead.majorStatus!.toxicCounter, equals(1));

      final afterSwitchBack =
          afterSwitchOut.applyChoice(const PlayerBattleChoiceSwitch(0));

      expect(afterSwitchBack.state.player.speciesId, equals('lead_player'));
      expect(afterSwitchBack.state.player.statStages.attack, equals(0));
      expect(afterSwitchBack.state.player.moves[1].currentPp, equals(7));
      expect(
        afterSwitchBack.state.currentTurn!.statusEvents
            .where(
              (event) =>
                  event.kind == BattleStatusEventKind.residualDamage &&
                  event.target == 'player',
            )
            .single
            .toxicCounter,
        equals(1),
      );
    });

    test(
        'double KO with reserves on both sides auto-replaces enemy and forces the player to switch',
        () {
      final session = _session(
        isTrainerBattle: true,
        player: _combatant(
          speciesId: 'lead_player',
          lineupIndex: 0,
          currentHp: 1,
          majorStatus: const BattleMajorStatusState.psn(),
          moves: <BattleMoveData>[_waitingMove()],
        ),
        playerReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'bench_player',
            lineupIndex: 1,
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
        enemy: _combatant(
          speciesId: 'lead_enemy',
          lineupIndex: 0,
          currentHp: 1,
          majorStatus: const BattleMajorStatusState.psn(),
          moves: <BattleMoveData>[_waitingMove()],
        ),
        enemyReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'bench_enemy',
            lineupIndex: 1,
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterTurn.state.isFinished, isFalse);
      expect(afterTurn.state.player.isFainted, isTrue);
      expect(afterTurn.state.enemy.speciesId, equals('bench_enemy'));
      expect(
        afterTurn.state.currentTurn!.switchEvents
            .map((event) => event.kind)
            .toList(growable: false),
        equals(<BattleSwitchEventKind>[
          BattleSwitchEventKind.switched,
          BattleSwitchEventKind.replacementRequired,
        ]),
      );
      expect(
        afterTurn.getAvailableChoices().whereType<PlayerBattleChoiceSwitch>(),
        hasLength(1),
      );
    });

    test('double KO with only an enemy reserve remains a defeat for the player',
        () {
      final session = _session(
        isTrainerBattle: true,
        player: _combatant(
          speciesId: 'lead_player',
          lineupIndex: 0,
          currentHp: 1,
          majorStatus: const BattleMajorStatusState.psn(),
          moves: <BattleMoveData>[_waitingMove()],
        ),
        enemy: _combatant(
          speciesId: 'lead_enemy',
          lineupIndex: 0,
          currentHp: 1,
          majorStatus: const BattleMajorStatusState.psn(),
          moves: <BattleMoveData>[_waitingMove()],
        ),
        enemyReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'bench_enemy',
            lineupIndex: 1,
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterTurn.state.isFinished, isTrue);
      expect(afterTurn.state.outcome!.isDefeat, isTrue);
      expect(afterTurn.state.enemy.speciesId, equals('bench_enemy'));
    });
  });
}

```

### packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart

```dart
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';

import 'battle_start_request.dart';
import 'runtime_battle_move_bridge.dart';
import 'runtime_battle_setup_exception.dart';
import 'runtime_move_catalog_loader.dart';
import 'runtime_pokemon_learnset_loader.dart';
import 'runtime_pokemon_species_loader.dart';

/// Builder runtime spécialisé des seeds de combattants injectés dans
/// `BattleSetup`.
///
/// M7 extrait ce seam pour éviter que `RuntimeBattleSetupMapper` concentre
/// encore :
/// - la sélection du membre joueur ;
/// - la lecture species/learnsets déjà extraite en M6 ;
/// - la dérivation du move set ;
/// - le gate M5-bis vers `BattleMoveData` ;
/// - le calcul de HP max ;
/// - et la construction finale des seeds de combattants.
///
/// Frontière intentionnelle :
/// - ce builder assemble des données runtime locales vers un seed battle ;
/// - il ne crée pas un framework générique de combat ;
/// - il ne modifie pas le contrat `BattleSetup` ;
/// - il ne rouvre pas M8 et n’essaie pas d’exécuter les `effects`.
class RuntimeBattleCombatantSeedBuilder {
  const RuntimeBattleCombatantSeedBuilder({
    this.speciesLoader = const RuntimePokemonSpeciesLoader(),
    this.learnsetLoader = const RuntimePokemonLearnsetLoader(),
    this.battleMoveBridge = const RuntimeBattleMoveBridge(),
  });

  final RuntimePokemonSpeciesLoader speciesLoader;
  final RuntimePokemonLearnsetLoader learnsetLoader;
  final RuntimeBattleMoveBridge battleMoveBridge;

  Future<RuntimeBattleCombatantSeed> buildPlayerCombatantSeed({
    required String projectRootDirectory,
    required ProjectPokemonConfig pokemonConfig,
    required RuntimeMoveCatalog movesCatalog,
    required PlayerPokemon playerPokemon,
  }) async {
    final species = await speciesLoader.loadById(
      projectRootDirectory: projectRootDirectory,
      pokemonConfig: pokemonConfig,
      speciesId: playerPokemon.speciesId,
    );
    final moveIds = playerPokemon.knownMoveIds.isNotEmpty
        ? playerPokemon.knownMoveIds
        : await _deriveLearnsetMoveIds(
            projectRootDirectory: projectRootDirectory,
            pokemonConfig: pokemonConfig,
            species: species,
            level: playerPokemon.level,
          );

    final moves = _resolveBattleMoves(
      movesCatalog: movesCatalog,
      moveIds: moveIds,
      combatantLabel: 'Le Pokémon actif du joueur',
    );

    final maxHp = _calculateMaxHp(
      baseHp: species.baseHp,
      level: playerPokemon.level,
      ivHp: playerPokemon.ivs.hp,
      evHp: playerPokemon.evs.hp,
    );
    final stats = _calculateStatsSnapshot(
      species: species,
      level: playerPokemon.level,
      ivs: playerPokemon.ivs,
      evs: playerPokemon.evs,
    );

    return RuntimeBattleCombatantSeed(
      speciesId: playerPokemon.speciesId.trim(),
      level: playerPokemon.level,
      maxHp: maxHp,
      stats: stats,
      typing: _buildBattleTypingSnapshot(species),
      currentHp: _clampInt(playerPokemon.currentHp, min: 0, max: maxHp),
      abilityId: playerPokemon.abilityId.trim().isEmpty
          ? 'unknown'
          : playerPokemon.abilityId.trim(),
      moves: moves,
    );
  }

  Future<RuntimeBattleCombatantSeed> buildWildCombatantSeed({
    required String projectRootDirectory,
    required ProjectPokemonConfig pokemonConfig,
    required RuntimeMoveCatalog movesCatalog,
    required WildBattleStartRequest request,
  }) async {
    final species = await speciesLoader.loadById(
      projectRootDirectory: projectRootDirectory,
      pokemonConfig: pokemonConfig,
      speciesId: request.speciesId,
    );
    final moveIds = await _deriveLearnsetMoveIds(
      projectRootDirectory: projectRootDirectory,
      pokemonConfig: pokemonConfig,
      species: species,
      level: request.level,
    );
    final moves = _resolveBattleMoves(
      movesCatalog: movesCatalog,
      moveIds: moveIds,
      combatantLabel: 'Le Pokémon sauvage "${request.speciesId}"',
    );

    return RuntimeBattleCombatantSeed(
      speciesId: request.speciesId.trim(),
      level: request.level,
      maxHp: _calculateMaxHp(
        baseHp: species.baseHp,
        level: request.level,
      ),
      stats: _calculateStatsSnapshot(
        species: species,
        level: request.level,
      ),
      typing: _buildBattleTypingSnapshot(species),
      abilityId: species.primaryAbilityId.isEmpty
          ? 'unknown'
          : species.primaryAbilityId,
      moves: moves,
    );
  }

  Future<RuntimeBattleCombatantSeed> buildTrainerCombatantSeed({
    required String projectRootDirectory,
    required ProjectPokemonConfig pokemonConfig,
    required RuntimeMoveCatalog movesCatalog,
    required ProjectTrainerPokemonEntry teamMember,
    required String trainerName,
  }) async {
    final species = await speciesLoader.loadById(
      projectRootDirectory: projectRootDirectory,
      pokemonConfig: pokemonConfig,
      speciesId: teamMember.speciesId,
    );
    final moveIds = teamMember.moves.isNotEmpty
        ? teamMember.moves
        : await _deriveLearnsetMoveIds(
            projectRootDirectory: projectRootDirectory,
            pokemonConfig: pokemonConfig,
            species: species,
            level: teamMember.level,
          );

    final moves = _resolveBattleMoves(
      movesCatalog: movesCatalog,
      moveIds: moveIds,
      combatantLabel:
          'Le Pokémon du dresseur "$trainerName" (${teamMember.speciesId})',
    );

    return RuntimeBattleCombatantSeed(
      speciesId: teamMember.speciesId.trim(),
      level: teamMember.level,
      maxHp: _calculateMaxHp(
        baseHp: species.baseHp,
        level: teamMember.level,
      ),
      stats: _calculateStatsSnapshot(
        species: species,
        level: teamMember.level,
      ),
      typing: _buildBattleTypingSnapshot(species),
      abilityId: species.primaryAbilityId.isEmpty
          ? 'unknown'
          : species.primaryAbilityId,
      moves: moves,
    );
  }

  Future<List<String>> _deriveLearnsetMoveIds({
    required String projectRootDirectory,
    required ProjectPokemonConfig pokemonConfig,
    required RuntimePokemonSpecies species,
    required int level,
  }) async {
    final learnset = await learnsetLoader.loadByRef(
      projectRootDirectory: projectRootDirectory,
      pokemonConfig: pokemonConfig,
      speciesRef: species.learnsetRef,
      fallbackSpeciesId: species.id,
    );

    // On conserve strictement la policy M6 :
    // - startingMoves
    // - relearnMoves
    // - levelUp <= niveau courant
    // - unicité préservant l'ordre
    // - 4 derniers moves maximum
    final ordered = <String>[
      ...learnset.startingMoves,
      ...learnset.relearnMoves,
      ...learnset.levelUp
          .where((entry) => entry.level <= level)
          .map((entry) => entry.moveId),
    ];
    final unique = _normalizeUniqueIdsPreserveOrder(ordered);
    if (unique.length <= 4) {
      return unique;
    }
    return unique.sublist(unique.length - 4);
  }

  List<BattleMoveData> _resolveBattleMoves({
    required RuntimeMoveCatalog movesCatalog,
    required List<String> moveIds,
    required String combatantLabel,
  }) {
    final normalizedMoveIds = _normalizeUniqueIdsPreserveOrder(moveIds);
    if (normalizedMoveIds.isEmpty) {
      throw RuntimeBattleSetupException(
        '$combatantLabel n’a aucune attaque exploitable pour démarrer le combat.',
      );
    }

    final moves = <BattleMoveData>[];
    for (final moveId in normalizedMoveIds.take(4)) {
      final move = movesCatalog.lookup(moveId);
      if (move == null) {
        throw RuntimeBattleSetupException(
          'Le catalogue local des attaques ne contient pas "$moveId".',
          debugDetails: 'combatant=$combatantLabel',
        );
      }
      // M8 sort enfin la policy de projection du builder brut :
      // - le builder assemble des seeds de combattants ;
      // - le bridge décide ce qui est réellement exécutable par `map_battle` ;
      // - cela rend le refus plus honnête que l'ancien simple gate
      //   `engineSupportLevel == structuredSupported`.
      moves.add(
        battleMoveBridge.toBattleMoveData(
          move: move,
          combatantLabel: combatantLabel,
        ),
      );
    }
    return List<BattleMoveData>.unmodifiable(moves);
  }

  List<String> _normalizeUniqueIdsPreserveOrder(List<String> rawIds) {
    final out = <String>[];
    final seen = <String>{};
    for (final rawId in rawIds) {
      final normalizedId = rawId.trim();
      if (normalizedId.isEmpty || !seen.add(normalizedId)) {
        continue;
      }
      out.add(normalizedId);
    }
    return List<String>.unmodifiable(out);
  }

  int _calculateMaxHp({
    required int baseHp,
    required int level,
    int ivHp = 0,
    int evHp = 0,
  }) {
    final safeBaseHp = _clampInt(baseHp, min: 1, max: 255);
    final safeLevel = _clampInt(level, min: 1, max: 100);
    final safeIv = _clampInt(ivHp, min: 0, max: 31);
    final safeEv = _clampInt(evHp, min: 0, max: 252);

    final hp =
        (((2 * safeBaseHp + safeIv + (safeEv ~/ 4)) * safeLevel) ~/ 100) +
            safeLevel +
            10;
    return _clampInt(hp, min: 1, max: 999);
  }

  BattleStatsSnapshot _calculateStatsSnapshot({
    required RuntimePokemonSpecies species,
    required int level,
    PokemonStatSpread ivs = const PokemonStatSpread(),
    PokemonStatSpread evs = const PokemonStatSpread(),
  }) {
    // BE2 résout ici les stats battle non-HP pour une raison simple :
    // - `map_runtime` possède encore la donnée projet (species, niveau, IV/EV) ;
    // - `map_battle` ne doit jamais relire le JSON projet brut ;
    // - le handoff battle doit donc déjà recevoir un snapshot typé, prêt à
    //   l'emploi, au lieu d'un bricolage `power + stages`.
    //
    // Politique volontairement bornée :
    // - joueur : on utilise les IV/EV réellement présents dans la sauvegarde ;
    // - sauvage / trainer : IV/EV par défaut à 0, déterministes, documentés ;
    // - nature neutre pour tout le monde dans BE2 ;
    // - `speed` est déjà transportée pour préparer la suite, sans être
    //   consommée pour l'ordre d'action dans ce lot.
    return BattleStatsSnapshot(
      attack: _calculateResolvedNonHpStat(
        baseStat: species.baseAttack,
        level: level,
        iv: ivs.attack,
        ev: evs.attack,
      ),
      defense: _calculateResolvedNonHpStat(
        baseStat: species.baseDefense,
        level: level,
        iv: ivs.defense,
        ev: evs.defense,
      ),
      specialAttack: _calculateResolvedNonHpStat(
        baseStat: species.baseSpecialAttack,
        level: level,
        iv: ivs.specialAttack,
        ev: evs.specialAttack,
      ),
      specialDefense: _calculateResolvedNonHpStat(
        baseStat: species.baseSpecialDefense,
        level: level,
        iv: ivs.specialDefense,
        ev: evs.specialDefense,
      ),
      speed: _calculateResolvedNonHpStat(
        baseStat: species.baseSpeed,
        level: level,
        iv: ivs.speed,
        ev: evs.speed,
      ),
    );
  }

  BattleTypingSnapshot _buildBattleTypingSnapshot(
    RuntimePokemonSpecies species,
  ) {
    // BE5 garde la frontière propre :
    // - le loader species lit et valide le typing projet ;
    // - le builder l'adapte vers le petit contrat battle ;
    // - `map_battle` reçoit ensuite une donnée déjà prête à consommer sans
    //   jamais relire le JSON projet brut.
    return BattleTypingSnapshot(
      primaryType: species.typing.first,
      secondaryType: species.typing.length > 1 ? species.typing[1] : null,
    );
  }

  int _calculateResolvedNonHpStat({
    required int baseStat,
    required int level,
    int iv = 0,
    int ev = 0,
  }) {
    final safeBaseStat = _clampInt(baseStat, min: 1, max: 255);
    final safeLevel = _clampInt(level, min: 1, max: 100);
    final safeIv = _clampInt(iv, min: 0, max: 31);
    final safeEv = _clampInt(ev, min: 0, max: 252);

    // Formule volontairement Pokémon-like, mais limitée et déterministe :
    // floor(((2 * base + iv + floor(ev / 4)) * level) / 100) + 5
    //
    // BE2 ne gère pas encore les natures. On garde donc ici un multiplicateur
    // neutre implicite de 1.0 au lieu d'introduire une mécanique partielle.
    final resolved =
        (((2 * safeBaseStat + safeIv + (safeEv ~/ 4)) * safeLevel) ~/ 100) + 5;
    return _clampInt(resolved, min: 1, max: 999);
  }

  int _clampInt(
    int value, {
    required int min,
    required int max,
  }) {
    if (value < min) {
      return min;
    }
    if (value > max) {
      return max;
    }
    return value;
  }
}

/// Seed runtime intermédiaire d'un combattant avant projection finale vers
/// `BattleCombatantData`.
///
/// On garde ce type séparé du mapper pour documenter explicitement la frontière
/// M7 :
/// - le builder assemble un seed runtime battle-ready ;
/// - le mapper assemble ensuite le `BattleSetup` global.
class RuntimeBattleCombatantSeed {
  const RuntimeBattleCombatantSeed({
    required this.speciesId,
    required this.level,
    required this.maxHp,
    required this.stats,
    required this.typing,
    required this.abilityId,
    required this.moves,
    this.currentHp,
  });

  final String speciesId;
  final int level;
  final int maxHp;
  final BattleStatsSnapshot stats;
  final BattleTypingSnapshot typing;
  final int? currentHp;
  final String abilityId;
  final List<BattleMoveData> moves;

  BattleCombatantData toBattleCombatantData({
    int lineupIndex = 0,
  }) {
    // BE10 garde la frontière propre :
    // - le seed builder ne connaît toujours pas la vraie party runtime ;
    // - mais le mapper peut maintenant lui demander de projeter ce seed vers
    //   un `BattleCombatantData` portant une identité de lineup stable ;
    // - cela évite de dupliquer à la main tout le DTO battle dans le mapper.
    return BattleCombatantData(
      speciesId: speciesId,
      lineupIndex: lineupIndex,
      level: level,
      maxHp: maxHp,
      stats: stats,
      typing: typing,
      currentHp: currentHp,
      abilityId: abilityId,
      moves: moves,
    );
  }
}

```

### packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart

```dart
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';

import 'battle_start_request.dart';
import 'story_flags_manager.dart';

const _runtimeCapturePokeBallItemId = 'poke-ball';
const _runtimeCapturePokeBallCategoryId = 'items';

/// Contexte runtime strictement nécessaire pour faire le write-back post-combat.
///
/// Invariant critique :
/// - [playerPartyIndex] est l'index exact du slot utilisé au moment du handoff
///   vers le combat ;
/// - il reste utile pour la compatibilité historique mono-slot et pour le
///   whiteout-lite ;
/// - BE10 ajoute en plus [playerPartySlotIndicesByLineupIndex] pour couvrir
///   honnêtement les combats où plusieurs membres sont réellement engagés.
///
/// Cette structure reste volontairement petite :
/// - la requête d'origine pour savoir si le combat était wild ou trainer ;
/// - l'index du slot joueur initial ;
/// - le mapping lineup battle -> slots runtime quand BE10 l'exige ;
/// - rien de plus.
class RuntimeActiveBattleContext {
  const RuntimeActiveBattleContext({
    required this.request,
    required this.playerPartyIndex,
    this.playerPartySlotIndicesByLineupIndex = const <int>[],
  });

  final BattleStartRequest request;
  final int playerPartyIndex;

  /// Mapping stable lineup battle joueur -> slots de party runtime.
  ///
  /// BE10 ajoute ce seam parce que le joueur peut désormais switcher pendant
  /// le combat :
  /// - `playerPartyIndex` seul ne suffit plus pour réécrire honnêtement les
  ///   PV de plusieurs membres engagés ;
  /// - le runtime mémorise donc l'ordre exact actif + réserves injecté dans
  ///   `BattleSetup` ;
  /// - `map_battle` garde ensuite une identité de lineup stable malgré les
  ///   switches, et le write-back peut retrouver les bons slots sans rejouer
  ///   l'historique du combat.
  ///
  /// Compatibilité volontaire :
  /// - l'ancien chemin mono-slot peut laisser cette liste vide ;
  /// - dans ce cas, le write-back retombe honnêtement sur le seul
  ///   `playerPartyIndex`.
  final List<int> playerPartySlotIndicesByLineupIndex;
}

/// Applique le strict minimum de reprise après une vraie défaite joueur.
///
/// Pourquoi ce helper existe :
/// - le lot 10 écrit honnêtement les PV finaux du combat, y compris `0` ;
/// - le lot 15 doit éviter l'état absurde "retour overworld + toute la party K.O.
///   + aucun moyen de rejouer" ;
/// - on ne veut pourtant pas ouvrir un vrai centre Pokémon, ni un système de
///   whiteout complet, ni une logique multi-Pokémon.
///
/// Contrat volontairement petit :
/// - si au moins un Pokémon de la party est encore jouable, on ne soigne rien ;
/// - si toute la party est K.O., on relève uniquement le slot exact qui a servi
///   au combat à `1 HP` ;
/// - on garde ainsi la mémoire fidèle du write-back lot 10 sur tous les autres
///   slots, tout en garantissant qu'un prochain handoff runtime->battle restera
///   possible sans inventer un heal global.
///
/// Ce helper reste pur :
/// - il ne téléporte pas ;
/// - il ne touche ni au bag, ni aux flags trainer, ni à seen/caught ;
/// - le repositionnement runtime "whiteout-lite" reste géré par `PlayableMapGame`,
///   car lui seul connaît la carte réellement chargée et les seams de respawn.
GameState applyRuntimeDefeatRecoveryToGameState({
  required GameState gameState,
  required int playerPartyIndex,
  int? activePlayerLineupIndex,
  List<int> playerPartySlotIndicesByLineupIndex = const <int>[],
}) {
  if (gameState.party.members.any((member) => !member.isFainted)) {
    return gameState;
  }

  final members = gameState.party.members;
  final revivePartySlotIndex = _resolveDefeatRecoveryPartySlotIndex(
    partyLength: members.length,
    playerPartyIndex: playerPartyIndex,
    activePlayerLineupIndex: activePlayerLineupIndex,
    playerPartySlotIndicesByLineupIndex: playerPartySlotIndicesByLineupIndex,
  );

  if (revivePartySlotIndex < 0 || revivePartySlotIndex >= members.length) {
    throw StateError(
      'Le whiteout-lite runtime pointe vers un slot party invalide: '
      'index=$revivePartySlotIndex, partyLength=${members.length}',
    );
  }

  final nextMembers = List<PlayerPokemon>.of(members, growable: false);
  final defeatedMember = nextMembers[revivePartySlotIndex];

  // Whiteout-lite lot 15 :
  // - on évite le softlock total après défaite ;
  // - on ne réanime qu'un seul Pokémon, sur le slot exact qui était encore
  //   actif au moment de la défaite ;
  // - BE10 impose ce détail : après un switch, l'ancien slot initial ne doit
  //   plus être "magiquement" réanimé à la place du vrai Pokémon tombé ;
  // - on ne transforme pas ce lot en heal center ou en reset complet de party.
  nextMembers[revivePartySlotIndex] = defeatedMember.copyWith(currentHp: 1);

  return gameState.copyWith(
    party: gameState.party.copyWith(members: nextMembers),
  );
}

int _resolveDefeatRecoveryPartySlotIndex({
  required int partyLength,
  required int playerPartyIndex,
  required int? activePlayerLineupIndex,
  required List<int> playerPartySlotIndicesByLineupIndex,
}) {
  // Compatibilité volontaire :
  // - les anciens call sites mono-slot ne connaissent que playerPartyIndex ;
  // - BE10 ajoute un mapping lineup -> slots runtime pour éviter de réanimer
  //   le mauvais membre après un switch ;
  // - on ne force donc le nouveau chemin que quand les deux informations
  //   modernes sont réellement disponibles.
  if (playerPartySlotIndicesByLineupIndex.isEmpty ||
      activePlayerLineupIndex == null) {
    return playerPartyIndex;
  }

  if (activePlayerLineupIndex < 0 ||
      activePlayerLineupIndex >= playerPartySlotIndicesByLineupIndex.length) {
    throw StateError(
      'Le whiteout-lite runtime a reçu un lineupIndex joueur invalide: '
      'lineupIndex=$activePlayerLineupIndex, '
      'lineupLength=${playerPartySlotIndicesByLineupIndex.length}',
    );
  }

  final mappedPartyIndex =
      playerPartySlotIndicesByLineupIndex[activePlayerLineupIndex];
  if (mappedPartyIndex < 0 || mappedPartyIndex >= partyLength) {
    throw StateError(
      'Le whiteout-lite runtime a reçu un mapping lineup->party invalide: '
      'lineupIndex=$activePlayerLineupIndex, '
      'partyIndex=$mappedPartyIndex, partyLength=$partyLength',
    );
  }

  return mappedPartyIndex;
}

/// Applique le résultat final du combat à l'état runtime.
///
/// Ce helper porte le write-back lot 10 dans un seul chemin explicite :
/// 1. écrire les PV finaux du lineup joueur sur les slots exacts mémorisés ;
/// 2. marquer le trainer battu uniquement en cas de victoire trainer ;
/// 3. laisser intact tout ce qui appartient aux lots 11+.
///
/// Important :
/// - on ne soigne jamais implicitement le joueur ;
/// - on ne téléporte jamais ;
/// - le lot 13/14 ne gère qu'une capture sauvage minimale ;
/// - le lot 14 consomme exactement une Poké Ball au write-back runtime ;
/// - aucun bag UI, aucune récompense, aucun switch n'est ouvert ici ;
/// - on ne recalculera jamais naïvement le slot actif après le combat.
GameState applyRuntimeBattleOutcomeToGameState({
  required GameState gameState,
  required RuntimeActiveBattleContext context,
  required BattleOutcome outcome,
  StoryFlagsManager storyFlagsManager = const StoryFlagsManager(),
}) {
  final stateWithPlayerHp = _writePlayerBattleLineupBackToPartySlots(
    gameState: gameState,
    context: context,
    finalState: outcome.finalState,
  );

  final request = context.request;
  if (outcome.isCaptured) {
    if (request is! WildBattleStartRequest) {
      throw StateError(
        'BattleOutcomeType.captured est interdit hors combat sauvage.',
      );
    }

    // Garde-fou lot 13/14 :
    // le moteur ne doit normalement jamais proposer Capture si la party est
    // pleine ou sans Poké Ball, mais on revalide ici pour qu'un call site forcé
    // ne fasse jamais "disparaître" un Pokémon capturé faute de boîte/PC ou
    // contourne le coût réel de capture introduit par le lot 14.
    if (stateWithPlayerHp.party.members.length >= 6) {
      throw StateError(
        'Impossible d’ajouter un Pokémon capturé : la party du joueur est pleine.',
      );
    }

    final bagAfterConsumption =
        _consumeOnePokeBallOrThrow(stateWithPlayerHp.bag);
    final capturedPokemon = _buildCapturedWildPlayerPokemon(
      enemy: outcome.finalState.enemy,
    );
    final nextMembers = List<PlayerPokemon>.of(
      stateWithPlayerHp.party.members,
      growable: true,
    )..add(capturedPokemon);

    // Lot 12 garantit déjà "party -> caught -> seen". On réutilise donc cette
    // normalisation partagée au lieu d'introduire un deuxième pipeline Pokédex.
    return normalizeLoadedGameState(
      stateWithPlayerHp.copyWith(
        party: stateWithPlayerHp.party.copyWith(members: nextMembers),
        bag: bagAfterConsumption,
      ),
    );
  }

  if (outcome.isVictory && request is TrainerBattleStartRequest) {
    return storyFlagsManager.markTrainerDefeated(
      stateWithPlayerHp,
      request.trainerId,
    );
  }

  return stateWithPlayerHp;
}

const _capturedPokemonDefaultNatureId = 'hardy';
const _capturedPokemonFallbackAbilityId = 'unknown';

/// Construit le Pokémon réellement ajouté à la party après une capture sauvage.
///
/// Le lot 13 reste volontairement minimal :
/// - l'espèce, le niveau, l'ability et les moves viennent du vrai combattant
///   sauvage réellement engagé dans le moteur battle ;
/// - la nature reste un fallback MVP déterministe (`hardy`) faute de véritable
///   génération runtime existante ;
/// - on ne tente pas d'inventer ivs/evs/status/shiny/held item au-delà des
///   defaults du modèle `PlayerPokemon`.
///
/// Invariant important :
/// - une capture réussie ne doit jamais produire un Pokémon owned déjà K.O. ;
/// - si un call site forge un outcome capturé incohérent avec `enemyHp <= 0`,
///   on clamp donc les PV du Pokémon capturé à 1 minimum.
PlayerPokemon _buildCapturedWildPlayerPokemon({
  required BattleCombatant enemy,
}) {
  final normalizedAbilityId = enemy.abilityId.trim().isEmpty
      ? _capturedPokemonFallbackAbilityId
      : enemy.abilityId.trim();
  final normalizedMoveIds = enemy.moves
      .map((move) => move.id.trim())
      .where((moveId) => moveId.isNotEmpty)
      .toSet()
      .toList(growable: false);

  return PlayerPokemon(
    speciesId: enemy.speciesId.trim(),
    natureId: _capturedPokemonDefaultNatureId,
    abilityId: normalizedAbilityId,
    level: enemy.level,
    knownMoveIds: normalizedMoveIds,
    currentHp: enemy.currentHp <= 0 ? 1 : enemy.currentHp,
  );
}

/// Consomme exactement une Poké Ball du bag runtime.
///
/// Pourquoi le coût est appliqué ici :
/// - le moteur battle n'a pas à connaître le bag réel du joueur ;
/// - la capture n'est "réelle" qu'au moment où le runtime accepte d'écrire le
///   résultat dans le `GameState` ;
/// - cela donne une frontière de sécurité unique contre les appels forcés :
///   si aucun `poke-ball` n'existe, le write-back échoue explicitement.
///
/// Le lot 14 reste volontairement minimal :
/// - une seule ressource est concernée (`poke-ball` / `items`) ;
/// - aucune UI d'inventaire n'est ouverte ;
/// - aucun autre item n'est touché ;
/// - aucune entrée à quantité 0 ne doit survivre, car `BagEntry` l'interdit.
Bag _consumeOnePokeBallOrThrow(Bag bag) {
  final nextEntries = <BagEntry>[];
  var didConsumePokeBall = false;

  for (final entry in bag.entries) {
    final isCaptureBall =
        entry.itemId.trim() == _runtimeCapturePokeBallItemId &&
            entry.categoryId.trim() == _runtimeCapturePokeBallCategoryId;
    if (!isCaptureBall || didConsumePokeBall) {
      nextEntries.add(entry);
      continue;
    }

    didConsumePokeBall = true;
    final nextQuantity = entry.quantity - 1;
    if (nextQuantity > 0) {
      nextEntries.add(
        entry.copyWith(quantity: nextQuantity),
      );
    }
  }

  if (!didConsumePokeBall) {
    throw StateError(
      'Impossible d’appliquer BattleOutcomeType.captured sans Poké Ball dans le bag du joueur.',
    );
  }

  return Bag(entries: nextEntries).normalized();
}

/// Réécrit les PV des combattants joueur réellement engagés dans la vraie party.
///
/// BE10 remplace l'ancien write-back mono-slot par une projection minimale
/// mais honnête du lineup battle joueur :
/// - l'actif final et les réserves finales portent tous un `lineupIndex`
///   battle stable ;
/// - le contexte runtime connaît la correspondance lineup -> slots de party ;
/// - on réécrit donc chaque membre réellement engagé sur le bon slot save,
///   sans recalculer l'historique des switches.
///
/// Frontière volontairement bornée :
/// - on n'écrit encore que les PV, car le runtime hors combat ne possède pas
///   encore de write-back honnête des PP courants ni des statuts majeurs ;
/// - les membres de party non engagés dans ce combat restent inchangés.
GameState _writePlayerBattleLineupBackToPartySlots({
  required GameState gameState,
  required RuntimeActiveBattleContext context,
  required BattleState finalState,
}) {
  final lineupToParty = context.playerPartySlotIndicesByLineupIndex.isEmpty
      ? <int>[context.playerPartyIndex]
      : context.playerPartySlotIndicesByLineupIndex;
  final playerLineup = <BattleCombatant>[
    finalState.player,
    ...finalState.playerReserve,
  ];

  if (playerLineup.length != lineupToParty.length) {
    throw StateError(
      'Le write-back runtime ne peut pas réconcilier une lineup battle et un mapping de party de tailles différentes: '
      'lineupLength=${playerLineup.length}, partyMappingLength=${lineupToParty.length}',
    );
  }

  final members = gameState.party.members;
  final nextMembers = List<PlayerPokemon>.of(members, growable: false);
  final seenLineupIndices = <int>{};

  for (final combatant in playerLineup) {
    final lineupIndex = combatant.lineupIndex;
    if (lineupIndex < 0 || lineupIndex >= lineupToParty.length) {
      throw StateError(
        'Le write-back runtime pointe vers un lineupIndex battle invalide: '
        'lineupIndex=$lineupIndex, mappingLength=${lineupToParty.length}',
      );
    }
    if (!seenLineupIndices.add(lineupIndex)) {
      throw StateError(
        'Le write-back runtime a rencontré deux combattants avec le même lineupIndex=$lineupIndex.',
      );
    }

    final partyIndex = lineupToParty[lineupIndex];
    if (partyIndex < 0 || partyIndex >= members.length) {
      throw StateError(
        'RuntimeActiveBattleContext pointe vers un slot party invalide: '
        'index=$partyIndex, partyLength=${members.length}',
      );
    }

    final currentMember = nextMembers[partyIndex];
    nextMembers[partyIndex] = currentMember.copyWith(
      currentHp: combatant.currentHp < 0 ? 0 : combatant.currentHp,
    );
  }

  return gameState.copyWith(
    party: gameState.party.copyWith(members: nextMembers),
  );
}

```

### packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart

```dart
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';

import 'battle_start_request.dart';
import 'runtime_battle_combatant_seed_builder.dart';
import 'runtime_battle_setup_exception.dart';
import 'runtime_map_bundle.dart';
import 'runtime_move_catalog_loader.dart';

export 'runtime_battle_setup_exception.dart' show RuntimeBattleSetupException;

const _runtimeCapturePokeBallItemId = 'poke-ball';
const _runtimeCapturePokeBallCategoryId = 'items';

/// Mapper runtime unique vers [BattleSetup].
///
/// Important :
/// - cette classe reste locale à `map_runtime` ;
/// - elle ne réintroduit pas de dépendance vers `map_editor` ;
/// - elle relit uniquement le strict nécessaire des données Pokémon projet
///   pour construire le setup de combat réel.
///
/// M5 introduit un seam runtime spécialisé pour les moves parce que :
/// - le catalogue moves est maintenant canonique et beaucoup plus riche ;
/// - `runtime_battle_setup_mapper.dart` ne doit plus relire `moves.json`
///   comme un tuple pauvre `id/name/power` ;
/// - `map_battle` ne doit toujours pas lire le JSON projet brut.
///
/// M6 poursuit cette extraction pour les espèces et learnsets :
/// - le mapper ne relit plus lui-même ces JSON projet ;
/// - il délègue à de petits loaders runtime spécialisés ;
/// - il reste centré sur la composition combat, pas sur la plomberie locale.
///
/// M7 poursuit dans la même direction :
/// - le mapper ne construit plus lui-même les seeds de combattants ;
/// - il délègue cette projection à un builder spécialisé ;
/// - il garde seulement l'orchestration de haut niveau, la politique de
///   capture et les sélections exactes qui appartiennent encore au runtime.
class RuntimeBattleSetupMapper {
  const RuntimeBattleSetupMapper({
    this.moveCatalogLoader = const RuntimeMoveCatalogLoader(),
    this.combatantSeedBuilder = const RuntimeBattleCombatantSeedBuilder(),
  });

  final RuntimeMoveCatalogLoader moveCatalogLoader;
  final RuntimeBattleCombatantSeedBuilder combatantSeedBuilder;

  Future<BattleSetup> map({
    required RuntimeMapBundle bundle,
    required GameState gameState,
    required BattleStartRequest request,
    int? playerPartyIndex,
  }) async {
    final movesCatalog = await moveCatalogLoader.load(
      projectRootDirectory: bundle.projectRootDirectory,
      pokemonConfig: bundle.manifest.pokemon,
    );
    final playerSelection = selectPlayerBattleLineup(
      gameState.party,
      playerPartyIndex: playerPartyIndex,
    );
    final playerPokemon = gameState.party.members[playerSelection.activeIndex];

    final playerSeed = await combatantSeedBuilder.buildPlayerCombatantSeed(
      projectRootDirectory: bundle.projectRootDirectory,
      pokemonConfig: bundle.manifest.pokemon,
      movesCatalog: movesCatalog,
      playerPokemon: playerPokemon,
    );
    final playerReserveSeeds = <RuntimeBattleCombatantSeed>[];
    for (final reserveIndex in playerSelection.reserveIndices) {
      playerReserveSeeds.add(
        await combatantSeedBuilder.buildPlayerCombatantSeed(
          projectRootDirectory: bundle.projectRootDirectory,
          pokemonConfig: bundle.manifest.pokemon,
          movesCatalog: movesCatalog,
          playerPokemon: gameState.party.members[reserveIndex],
        ),
      );
    }

    final enemyLineup = await switch (request) {
      WildBattleStartRequest() => combatantSeedBuilder
          .buildWildCombatantSeed(
            projectRootDirectory: bundle.projectRootDirectory,
            pokemonConfig: bundle.manifest.pokemon,
            movesCatalog: movesCatalog,
            request: request,
          )
          .then(
            (seed) => _RuntimeBattleEnemyLineup(
              active: seed,
              reserve: const <RuntimeBattleCombatantSeed>[],
            ),
          ),
      TrainerBattleStartRequest() => () async {
          final trainer = _findTrainer(bundle.manifest, request.trainerId);
          if (trainer.team.isEmpty) {
            throw RuntimeBattleSetupException(
              'Le dresseur "${trainer.name}" n’a aucun Pokémon dans son équipe.',
              debugDetails: 'trainerId=${trainer.id}',
            );
          }

          final activeSeed =
              await combatantSeedBuilder.buildTrainerCombatantSeed(
            projectRootDirectory: bundle.projectRootDirectory,
            pokemonConfig: bundle.manifest.pokemon,
            movesCatalog: movesCatalog,
            teamMember: trainer.team.first,
            trainerName: trainer.name,
          );
          final reserveSeeds = <RuntimeBattleCombatantSeed>[];
          for (final teamMember in trainer.team.skip(1)) {
            reserveSeeds.add(
              await combatantSeedBuilder.buildTrainerCombatantSeed(
                projectRootDirectory: bundle.projectRootDirectory,
                pokemonConfig: bundle.manifest.pokemon,
                movesCatalog: movesCatalog,
                teamMember: teamMember,
                trainerName: trainer.name,
              ),
            );
          }
          return _RuntimeBattleEnemyLineup(
            active: activeSeed,
            reserve:
                List<RuntimeBattleCombatantSeed>.unmodifiable(reserveSeeds),
          );
        }(),
    };

    return BattleSetup(
      playerPokemon: playerSeed.toBattleCombatantData(lineupIndex: 0),
      playerReservePokemon: List<BattleCombatantData>.unmodifiable(
        playerReserveSeeds.asMap().entries.map(
              (entry) => entry.value.toBattleCombatantData(
                lineupIndex: entry.key + 1,
              ),
            ),
      ),
      enemyPokemon: enemyLineup.active.toBattleCombatantData(lineupIndex: 0),
      enemyReservePokemon: List<BattleCombatantData>.unmodifiable(
        enemyLineup.reserve.asMap().entries.map(
              (entry) => entry.value.toBattleCombatantData(
                lineupIndex: entry.key + 1,
              ),
            ),
      ),
      isTrainerBattle: request is TrainerBattleStartRequest,
      trainerId:
          request is TrainerBattleStartRequest ? request.trainerId : null,
      // Le moteur battle ne connaît ni le bag runtime, ni les limites de party.
      // On garde donc la décision de "peut-on capturer ?" ici, au point où le
      // runtime possède encore les vraies données save/projet nécessaires.
      //
      // Lot 14 reste volontairement borné :
      // - combat sauvage uniquement ;
      // - aucune capture si la party est pleine (pas de PC/boxes ici) ;
      // - aucune capture sans Poké Ball réelle dans le bag du joueur.
      allowCapture: request is WildBattleStartRequest &&
          gameState.party.members.length < 6 &&
          _playerHasAtLeastOnePokeBall(gameState.bag),
    );
  }

  /// Sélectionne la lineup battle minimale du joueur : actif + réserves.
  ///
  /// Politique BE10 volontairement bornée :
  /// - l'actif reste soit l'index explicitement demandé, soit le premier
  ///   membre jouable ;
  /// - la réserve ne contient que les autres membres encore vivants ;
  /// - les membres déjà K.O. restent dans la save runtime, mais ne sont pas
  ///   injectés dans la lineup battle puisqu'ils ne seraient jamais
  ///   switchables honnêtement ;
  /// - l'ordre de réserve suit l'ordre de party réel, de façon stable.
  RuntimePlayerBattleLineupSelection selectPlayerBattleLineup(
    PlayerParty party, {
    int? playerPartyIndex,
  }) {
    final activeIndex = playerPartyIndex ?? selectUsablePartyMemberIndex(party);
    if (activeIndex < 0 || activeIndex >= party.members.length) {
      throw RuntimeBattleSetupException(
        'Le slot de party joueur demandé pour le combat est invalide.',
        debugDetails:
            'playerPartyIndex=$activeIndex, partyLength=${party.members.length}',
      );
    }

    final activeMember = party.members[activeIndex];
    if (activeMember.isFainted) {
      throw RuntimeBattleSetupException(
        'Le slot de party joueur demandé pour le combat est déjà K.O.',
        debugDetails:
            'playerPartyIndex=$activeIndex, speciesId=${activeMember.speciesId}',
      );
    }

    final reserveIndices = <int>[];
    for (var i = 0; i < party.members.length; i++) {
      if (i == activeIndex || party.members[i].isFainted) {
        continue;
      }
      reserveIndices.add(i);
    }

    return RuntimePlayerBattleLineupSelection(
      activeIndex: activeIndex,
      reserveIndices: List<int>.unmodifiable(reserveIndices),
    );
  }

  /// Retourne l'index du slot réellement utilisé pour le handoff combat.
  ///
  /// Le runtime lot 10 doit mémoriser cet index exact pour réécrire les PV du
  /// bon membre après le combat. On expose donc explicitement cette sélection
  /// au lieu de forcer [PlayableMapGame] à dupliquer la logique.
  int selectUsablePartyMemberIndex(PlayerParty party) {
    // Cette sélection reste volontairement dans le mapper :
    // - `PlayableMapGame` l'utilise déjà pour mémoriser le slot à réécrire
    //   après le combat ;
    // - elle relève d'une décision d'orchestration runtime de haut niveau,
    //   pas d'un assemblage de seed de combattant ;
    // - l'extraire dans le builder brouillerait la frontière M7 pour peu de
    //   valeur réelle dans ce repo.
    for (var i = 0; i < party.members.length; i++) {
      if (!party.members[i].isFainted) {
        return i;
      }
    }

    if (party.members.isEmpty) {
      throw const RuntimeBattleSetupException(
        'Impossible de lancer un combat sans Pokémon dans l’équipe du joueur.',
      );
    }

    throw const RuntimeBattleSetupException(
      'Tous les Pokémon de l’équipe du joueur sont K.O.; combat impossible.',
    );
  }

  ProjectTrainerEntry _findTrainer(ProjectManifest manifest, String trainerId) {
    final normalizedTrainerId = trainerId.trim();
    for (final trainer in manifest.trainers) {
      if (trainer.id == normalizedTrainerId) {
        return trainer;
      }
    }

    throw RuntimeBattleSetupException(
      'Dresseur introuvable pour démarrer le combat.',
      debugDetails: 'trainerId=$trainerId',
    );
  }
}

/// Sélection runtime de lineup battle du joueur.
///
/// Ce petit type évite de faire circuler des tuples implicites :
/// - `activeIndex` identifie le slot réellement actif au handoff ;
/// - `reserveIndices` garde l'ordre stable des réserves injectées dans
///   `BattleSetup` ;
/// - le runtime peut ensuite réutiliser exactement cette projection pour le
///   write-back post-combat.
final class RuntimePlayerBattleLineupSelection {
  const RuntimePlayerBattleLineupSelection({
    required this.activeIndex,
    required this.reserveIndices,
  });

  final int activeIndex;
  final List<int> reserveIndices;

  List<int> get lineupPartyIndices => <int>[activeIndex, ...reserveIndices];
}

final class _RuntimeBattleEnemyLineup {
  const _RuntimeBattleEnemyLineup({
    required this.active,
    required this.reserve,
  });

  final RuntimeBattleCombatantSeed active;
  final List<RuntimeBattleCombatantSeed> reserve;
}

/// Retourne `true` si le bag runtime contient au moins une Poké Ball exploitable.
///
/// Le guard vit ici plutôt que dans `map_battle` car :
/// - le moteur battle ne doit pas dépendre du système de bag ;
/// - le runtime est déjà la frontière qui décide si `allowCapture` peut être
///   activé pour une rencontre donnée ;
/// - le lot 14 n'ouvre pas un inventaire global ni une politique de capture.
///
/// On tolère des IDs non normalisés en mémoire (`" poke-ball "`) pour rester
/// robuste face à un état runtime pas encore passé par le pipeline save/load.
bool _playerHasAtLeastOnePokeBall(Bag bag) {
  for (final entry in bag.entries) {
    if (entry.itemId.trim() == _runtimeCapturePokeBallItemId &&
        entry.categoryId.trim() == _runtimeCapturePokeBallCategoryId &&
        entry.quantity > 0) {
      return true;
    }
  }
  return false;
}

```

### packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart

```dart
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';
import 'package:map_battle/map_battle.dart';

/// Composant UI d'overlay de combat.
///
/// Affiche l'état courant du combat et permet au joueur de choisir une action.
/// Ne contient AUCUNE logique métier de combat — pure UI.
///
/// La logique métier est dans `map_battle` (BattleSession).
/// Ce composant se contente de :
/// - Afficher les PV des combattants
/// - Afficher les choix disponibles
/// - Notifier le runtime du choix du joueur via [onPlayerChoice]
///
/// **Interaction** : L'utilisateur peut cliquer sur un choix pour le sélectionner.
/// Le clic appelle [onPlayerChoice] avec le choix correspondant.
///
/// **IMPORTANT** : Ce composant stocke une référence mutable vers la session
/// courante. Quand le runtime appelle [updateState()], la session interne
/// est mise à jour pour refléter le nouvel état. Toutes les méthodes d'affichage
/// lisent [session] qui est donc toujours à jour.
class BattleOverlayComponent extends PositionComponent with TapCallbacks {
  /// Crée un overlay de combat.
  ///
  /// [session] - La session de combat courante (état + API).
  /// [viewportSize] - La taille de la viewport pour centrer le panneau.
  /// [onPlayerChoice] - Callback appelé quand le joueur fait un choix.
  BattleOverlayComponent({
    required BattleSession session,
    required Vector2 viewportSize,
    required this.onPlayerChoice,
  })  : _session = session,
        super(
          size: viewportSize,
          anchor: Anchor.topLeft,
          priority: 97,
        );

  /// La session de combat courante.
  ///
  /// **Mutable** : mise à jour par [updateState()] pour refléter le nouvel état.
  /// Toutes les méthodes d'affichage lisent cette propriété, donc l'UI est
  /// toujours synchronisée avec l'état réel du combat.
  BattleSession _session;

  /// Callback appelé quand le joueur fait un choix.
  ///
  /// Le runtime doit appeler `session.applyChoice(choice)` pour appliquer le choix.
  final void Function(PlayerBattleChoice choice) onPlayerChoice;

  /// Référence vers le panneau principal (pour mise à jour dynamique).
  PositionComponent? _panel;

  /// Composants de texte pour les PV (pour mise à jour dynamique).
  TextComponent? _playerHpText;
  TextComponent? _enemyHpText;

  /// Composant de texte pour afficher le résultat du tour en cours.
  ///
  /// Affiche les attaques du joueur et de l'ennemi, ainsi que les dégâts.
  TextComponent? _turnResultText;

  /// Composants de choix (pour mise à jour dynamique).
  /// Chaque composant est associé à un index de choix.
  final List<_ChoiceComponent> _choiceComponents = [];

  /// Index du choix actuellement sélectionné.
  ///
  /// Utilisé pour la navigation clavier (↑/↓) et pour afficher visuellement
  /// le choix sélectionné avec un style différent.
  ///
  /// Invariant : `_selectedIndex` est toujours entre 0 et `_choiceComponents.length - 1`.
  int _selectedIndex = 0;

  /// Composant de surbrillance pour le choix sélectionné.
  ///
  /// Affiché derrière le choix sélectionné pour le mettre en évidence visuellement.
  RectangleComponent? _selectionHighlight;

  @override
  Future<void> onLoad() async {
    // Fond sombre
    final bg = RectangleComponent(
      size: size.clone(),
      anchor: Anchor.topLeft,
      paint: Paint()..color = const Color(0xF20B1020),
      priority: 0,
    );
    add(bg);

    // Panneau principal
    final panelWidth = (size.x - 80).clamp(240.0, 760.0);
    final panelHeight = (size.y - 120).clamp(220.0, 520.0);
    _panel = RectangleComponent(
      size: Vector2(panelWidth, panelHeight),
      position: Vector2((size.x - panelWidth) / 2, (size.y - panelHeight) / 2),
      anchor: Anchor.topLeft,
      paint: Paint()..color = const Color(0xE81A223B),
      priority: 1,
    );
    add(_panel!);

    // Bordure du panneau
    final panelBorder = RectangleComponent(
      size: _panel!.size.clone(),
      anchor: Anchor.topLeft,
      paint: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0x66FFFFFF),
      priority: 2,
    );
    _panel!.add(panelBorder);

    // Titre
    final title = TextComponent(
      text: _getTitleForSession(),
      anchor: Anchor.topLeft,
      position: Vector2(22, 20),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFF5F5F5),
          fontSize: 26,
          fontWeight: FontWeight.w700,
        ),
      ),
      priority: 3,
    );
    _panel!.add(title);

    // PV du joueur
    _playerHpText = TextComponent(
      text: _getPlayerHpText(),
      anchor: Anchor.topLeft,
      position: Vector2(22, 72),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFE5E9F2),
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
      priority: 3,
    );
    _panel!.add(_playerHpText!);

    // PV de l'ennemi
    _enemyHpText = TextComponent(
      text: _getEnemyHpText(),
      anchor: Anchor.topLeft,
      position: Vector2(22, 100),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFE5E9F2),
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
      priority: 3,
    );
    _panel!.add(_enemyHpText!);

    // Titre des choix
    final choicesTitle = TextComponent(
      text: 'Que doit faire le joueur ?',
      anchor: Anchor.topLeft,
      position: Vector2(22, 150),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFC4CCDA),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      priority: 3,
    );
    _panel!.add(choicesTitle);

    // Choix disponibles
    _renderChoices();

    // Astuce
    final hint = TextComponent(
      text: 'Utilisez les flèches ↑/↓ et E pour choisir',
      anchor: Anchor.bottomLeft,
      position: Vector2(22, panelHeight - 18),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFC4CCDA),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      priority: 3,
    );
    _panel!.add(hint);
  }

  /// Met à jour l'affichage avec un nouvel état de session.
  ///
  /// [newSession] - La nouvelle session avec l'état mis à jour.
  ///
  /// **IMPORTANT** : Cette méthode met à jour [_session] pour que toutes les
  /// méthodes d'affichage (_getChoiceText, etc.) lisent le bon état.
  ///
  /// Cette méthode gère aussi la cohérence de la sélection :
  /// - Si le combat est fini, la sélection est désactivée
  /// - Si la sélection est hors bornes (moins de choix), elle est clampée
  /// - Si un tour est en cours, affiche le résultat du tour (attaques + dégâts)
  void updateState(BattleSession newSession) {
    // Mettre à jour la session interne — CRITIQUE pour la cohérence
    _session = newSession;

    // Mettre à jour les PV
    _playerHpText?.text = _getPlayerHpText();
    _enemyHpText?.text = _getEnemyHpText();

    // Afficher le résultat du tour si disponible
    _updateTurnResult();

    // Si le combat est fini, afficher le résultat
    if (newSession.state.isFinished) {
      _showOutcome(newSession.state.outcome!);
    } else {
      // Combat toujours en cours — maintenir la sélection cohérente
      // Clamper l'index si le nombre de choix a changé
      final choices = newSession.getAvailableChoices();
      if (_selectedIndex >= choices.length) {
        _selectedIndex = choices.length - 1;
      }
      if (_selectedIndex < 0) {
        _selectedIndex = 0;
      }
      // Re-render pour mettre à jour les choix et la surbrillance
      _renderChoices();
    }
  }

  /// Met à jour l'affichage du résultat du tour en cours.
  ///
  /// Affiche les attaques du joueur et de l'ennemi, ainsi que les dégâts infligés.
  void _updateTurnResult() {
    // Supprimer l'ancien texte de résultat du tour
    _turnResultText?.removeFromParent();
    _turnResultText = null;

    final turnResult = _session.state.currentTurn;
    if (turnResult == null) {
      return;
    }

    // Construire le texte du résultat du tour
    final lines = <String>[];
    for (final execution in turnResult.executions) {
      final attacker = _combatantLabel(execution.attacker);
      lines.add(
          '$attacker utilise ${execution.move.name} → ${execution.damage} dégâts');
    }

    for (final event in turnResult.volatileEvents) {
      lines.add(_formatVolatileEvent(event));
    }

    // Garder un ordre d'affichage causal minimal :
    // - les résolutions de move d'abord ;
    // - ensuite les événements volatiles/statuts/field de fin de tour ;
    // - puis seulement les switches/remplacements qu'ils ont éventuellement
    //   déclenchés.
    //
    // Sans cet ordre, un auto-remplacement après résiduel pouvait apparaître
    // avant la ligne de dégâts qui l'avait provoqué, ce qui faisait mentir la
    // surface runtime alors même que le moteur battle restait correct.
    for (final event in turnResult.statusEvents) {
      lines.add(_formatStatusEvent(event));
    }

    for (final event in turnResult.fieldEvents) {
      lines.add(_formatFieldEvent(event));
    }

    for (final event in turnResult.switchEvents) {
      lines.add(_formatSwitchEvent(event));
    }

    if (lines.isEmpty) {
      return;
    }

    // Afficher le résultat du tour
    _turnResultText = TextComponent(
      text: lines.join('\n'),
      anchor: Anchor.topCenter,
      position: Vector2(_panel!.size.x / 2, 130),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFE5E9F2),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      priority: 3,
    );
    _panel!.add(_turnResultText!);
  }

  /// Affiche le résultat final du combat.
  void _showOutcome(BattleOutcome outcome) {
    final outcomeText = switch (outcome.type) {
      BattleOutcomeType.victory => 'Victoire !',
      BattleOutcomeType.defeat => 'Défaite...',
      BattleOutcomeType.runaway => 'Fuite réussie !',
      BattleOutcomeType.captured => 'Capture réussie !',
    };

    final outcomeComponent = TextComponent(
      text: outcomeText,
      anchor: Anchor.topCenter,
      position: Vector2(_panel!.size.x / 2, _panel!.size.y / 2 + 50),
      textRenderer: TextPaint(
        style: TextStyle(
          color: outcome.isVictory || outcome.isCaptured
              ? const Color(0xFF4CAF50)
              : const Color(0xFFF44336),
          fontSize: 32,
          fontWeight: FontWeight.w700,
        ),
      ),
      priority: 10,
    );
    _panel!.add(outcomeComponent);
  }

  /// Affiche les choix disponibles.
  ///
  /// Cette méthode :
  /// 1. Récupère les choix disponibles depuis [_session]
  /// 2. Crée un composant visuel pour chaque choix
  /// 3. Ajoute un composant de surbrillance pour le choix sélectionné
  /// 4. Met à jour [_selectionHighlight] pour le rendu visuel
  void _renderChoices() {
    // Lit [_session] qui est toujours à jour grâce à updateState()
    final choices = _session.getAvailableChoices();
    var y = 190.0;

    // Nettoyer les anciens composants de choix
    for (final component in _choiceComponents) {
      component.removeFromParent();
    }
    _choiceComponents.clear();

    // Nettoyer l'ancienne surbrillance
    _selectionHighlight?.removeFromParent();
    _selectionHighlight = null;

    for (var i = 0; i < choices.length; i++) {
      final choice = choices[i];
      final text = _getChoiceText(choice);
      final choiceComponent = _ChoiceComponent(
        choice: choice,
        text: text,
        position: Vector2(22, y),
      );
      _choiceComponents.add(choiceComponent);
      _panel!.add(choiceComponent);

      // Créer la surbrillance pour le choix sélectionné
      if (i == _selectedIndex) {
        _selectionHighlight = RectangleComponent(
          size: Vector2(280, 28),
          position: Vector2(24, y + 2),
          anchor: Anchor.topLeft,
          paint: Paint()
            ..color = const Color(0x40FFFFFF) // Blanc semi-transparent
            ..style = PaintingStyle.fill,
          priority: 2,
        );
        _panel!.add(_selectionHighlight!);
      }

      y += 32;
    }
  }

  /// Retourne le texte à afficher pour un choix.
  ///
  /// Lit [_session] qui est toujours à jour grâce à updateState().
  String _getChoiceText(PlayerBattleChoice choice) {
    if (choice is PlayerBattleChoiceFight) {
      // Lit les moves depuis _session.state.player.moves — toujours à jour
      final move = _session.state.player.moves[choice.moveIndex];
      return '⚔ ${move.name} (Puissance: ${move.power})';
    } else if (choice is PlayerBattleChoiceSwitch) {
      final reserve = _session.state.playerReserve[choice.reserveIndex];
      final isForcedReplacement = _session.state.player.isFainted;
      final actionLabel = isForcedReplacement ? 'Remplacer par' : 'Switch vers';
      return '↔ $actionLabel ${reserve.speciesId} '
          '(${reserve.currentHp}/${reserve.maxHp} PV)';
    } else if (choice is PlayerBattleChoiceContinue) {
      // BE8 ajoute des tours forcés honnêtes (recharge / libération d'un move
      // déjà chargé). Afficher `???` ici mentirait sur la surface joueur :
      // il ne choisit pas un nouveau move, il valide simplement la poursuite
      // de ce tour contraint par le moteur battle.
      final volatileState = _session.state.player.volatileState;
      if (volatileState.pendingCharge != null) {
        return 'Continuer (libérer la charge)';
      }
      if (volatileState.mustRecharge) {
        return 'Continuer (recharge)';
      }
      return 'Continuer';
    } else if (choice is PlayerBattleChoiceCapture) {
      return 'Capturer';
    } else if (choice is PlayerBattleChoiceRun) {
      return '🏃 Fuir';
    }
    return '???';
  }

  String _formatSwitchEvent(BattleSwitchEvent event) {
    final actor = _combatantLabel(event.actor);
    return switch (event.kind) {
      BattleSwitchEventKind.switched => event.wasForced
          ? '$actor remplace ${event.fromSpeciesId} par ${event.toSpeciesId}'
          : '$actor switch de ${event.fromSpeciesId} vers ${event.toSpeciesId}',
      BattleSwitchEventKind.replacementRequired =>
        '$actor doit remplacer ${event.fromSpeciesId} K.O.',
    };
  }

  String _formatStatusEvent(BattleStatusEvent event) {
    final actor = _combatantLabel(event.target);
    final status = event.status.name.toUpperCase();
    return switch (event.kind) {
      BattleStatusEventKind.applied =>
        '$actor reçoit le statut $status (${event.sourceMoveId})',
      BattleStatusEventKind.blockedExistingMajorStatus =>
        '$actor garde déjà ${event.existingStatus!.name.toUpperCase()} '
            'et ignore $status',
      BattleStatusEventKind.preventedAction =>
        '$actor ne peut pas agir à cause de $status',
      BattleStatusEventKind.residualDamage =>
        '$actor subit ${event.damage} dégâts résiduels ($status'
            '${event.toxicCounter == null ? '' : ', compteur ${event.toxicCounter}'}'
            ')',
    };
  }

  String _formatVolatileEvent(BattleVolatileEvent event) {
    final actor = _combatantLabel(event.actor);
    final target = event.target == null ? null : _combatantLabel(event.target!);

    return switch (event.kind) {
      BattleVolatileEventKind.protectActivated => '$actor active Protect',
      BattleVolatileEventKind.protectBlocked =>
        '${target ?? 'La cible'} bloque l’attaque avec Protect',
      BattleVolatileEventKind.protectBroken =>
        '$actor perce Protect sur ${target ?? 'la cible'}',
      BattleVolatileEventKind.rechargeRequired =>
        '$actor doit recharger au tour suivant',
      BattleVolatileEventKind.rechargeTurnSpent =>
        '$actor passe son tour pour recharger',
      BattleVolatileEventKind.chargeStarted =>
        '$actor commence à charger ${event.sourceMoveId ?? 'son attaque'}',
      BattleVolatileEventKind.chargeReleased =>
        '$actor libère ${event.sourceMoveId ?? 'son attaque chargée'}',
    };
  }

  String _formatFieldEvent(BattleFieldEvent event) {
    return switch (event.kind) {
      BattleFieldEventKind.weatherSet =>
        'Le champ passe à ${_weatherLabel(event.weather!)}',
      BattleFieldEventKind.weatherResidualDamage =>
        '${_combatantLabel(event.target!)} subit ${event.damage} dégâts de ${_weatherLabel(event.weather!)}',
      BattleFieldEventKind.weatherExpired =>
        '${_weatherLabel(event.weather!)} prend fin',
      BattleFieldEventKind.pseudoWeatherSet =>
        '${_pseudoWeatherLabel(event.pseudoWeather!)} devient actif',
      BattleFieldEventKind.pseudoWeatherCleared =>
        '${_pseudoWeatherLabel(event.pseudoWeather!)} est dissipé',
      BattleFieldEventKind.pseudoWeatherExpired =>
        '${_pseudoWeatherLabel(event.pseudoWeather!)} prend fin',
    };
  }

  String _combatantLabel(String combatantId) {
    return combatantId == 'player' ? 'Joueur' : 'Ennemi';
  }

  String _weatherLabel(BattleWeatherId weather) {
    return switch (weather) {
      BattleWeatherId.rain => 'la pluie',
      BattleWeatherId.sandstorm => 'la tempête de sable',
    };
  }

  String _pseudoWeatherLabel(BattlePseudoWeatherId pseudoWeather) {
    return switch (pseudoWeather) {
      BattlePseudoWeatherId.trickRoom => 'Trick Room',
    };
  }

  /// Retourne le titre pour la session.
  ///
  /// Lit [_session] qui est toujours à jour grâce à updateState().
  String _getTitleForSession() {
    if (_session.setup.isTrainerBattle) {
      return 'Combat Dresseur';
    }
    return 'Combat Sauvage';
  }

  /// Retourne le texte des PV du joueur.
  ///
  /// Lit [_session] qui est toujours à jour grâce à updateState().
  String _getPlayerHpText() {
    return 'Joueur (${_session.state.player.speciesId}): '
        '${_session.state.player.currentHp}/${_session.state.player.maxHp} PV';
  }

  /// Retourne le texte des PV de l'ennemi.
  ///
  /// Lit [_session] qui est toujours à jour grâce à updateState().
  String _getEnemyHpText() {
    return 'Ennemi (${_session.state.enemy.speciesId}): '
        '${_session.state.enemy.currentHp}/${_session.state.enemy.maxHp} PV';
  }

  /// Déplace la sélection vers le haut (choix précédent).
  ///
  /// Si la sélection est déjà au premier choix, reste au premier choix (pas de wrap).
  /// Met à jour visuellement la surbrillance.
  ///
  /// Retourne true si la sélection a changé, false sinon.
  bool moveSelectionUp() {
    if (_selectedIndex > 0) {
      _selectedIndex--;
      debugPrint('[battle-overlay] moveSelectionUp: new index=$_selectedIndex');
      _renderChoices(); // Re-render pour mettre à jour la surbrillance
      return true;
    }
    debugPrint(
        '[battle-overlay] moveSelectionUp: already at first choice (index=$_selectedIndex)');
    return false;
  }

  /// Déplace la sélection vers le bas (choix suivant).
  ///
  /// Si la sélection est déjà au dernier choix, reste au dernier choix (pas de wrap).
  /// Met à jour visuellement la surbrillance.
  ///
  /// Retourne true si la sélection a changé, false sinon.
  bool moveSelectionDown() {
    if (_selectedIndex < _choiceComponents.length - 1) {
      _selectedIndex++;
      debugPrint(
          '[battle-overlay] moveSelectionDown: new index=$_selectedIndex');
      _renderChoices(); // Re-render pour mettre à jour la surbrillance
      return true;
    }
    debugPrint(
        '[battle-overlay] moveSelectionDown: already at last choice (index=$_selectedIndex, max=${_choiceComponents.length - 1})');
    return false;
  }

  /// Retourne le choix actuellement sélectionné.
  ///
  /// Retourne null si aucun choix n'est disponible.
  PlayerBattleChoice? getSelectedChoice() {
    if (_choiceComponents.isEmpty ||
        _selectedIndex < 0 ||
        _selectedIndex >= _choiceComponents.length) {
      return null;
    }
    return _choiceComponents[_selectedIndex].choice;
  }

  /// Valide le choix actuellement sélectionné.
  ///
  /// Appelle [onPlayerChoice] avec le choix sélectionné.
  ///
  /// Retourne true si un choix a été validé, false si aucun choix n'est disponible.
  bool validateSelectedChoice() {
    final selectedChoice = getSelectedChoice();
    if (selectedChoice != null) {
      debugPrint(
          '[battle-overlay] validateSelectedChoice: choice=$selectedChoice');
      onPlayerChoice(selectedChoice);
      return true;
    }
    debugPrint('[battle-overlay] validateSelectedChoice: no choice selected');
    return false;
  }

  @override
  void onTapDown(TapDownEvent event) {
    // Vérifier si un choix a été cliqué
    final tapPos = event.localPosition;
    for (var i = 0; i < _choiceComponents.length; i++) {
      final choiceComponent = _choiceComponents[i];
      if (choiceComponent.containsPoint(tapPos)) {
        // Mettre à jour la sélection visuelle
        _selectedIndex = i;
        _renderChoices();

        // Choix cliqué — notifier le runtime
        onPlayerChoice(choiceComponent.choice);
        return;
      }
    }
  }
}

/// Composant de choix avec référence au choix associé.
///
/// Permet de détecter les clics sur un choix spécifique et de notifier
/// le runtime via [onPlayerChoice].
class _ChoiceComponent extends PositionComponent {
  _ChoiceComponent({
    required this.choice,
    required String text,
    required Vector2 position,
  }) : super(
          size: Vector2(300, 32),
          position: position,
          anchor: Anchor.topLeft,
        ) {
    // Ajouter le texte du choix
    add(TextComponent(
      text: text,
      anchor: Anchor.topLeft,
      position: Vector2.zero(),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFE5E9F2),
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
    ));
  }

  /// Le choix associé à ce composant.
  final PlayerBattleChoice choice;

  /// Vérifie si un point est dans les bounds de ce composant.
  @override
  bool containsPoint(Vector2 point) {
    return point.x >= position.x &&
        point.x <= position.x + size.x &&
        point.y >= position.y &&
        point.y <= position.y + size.y;
  }
}

```

### packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart

```dart
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import '../../../domain/repositories/game_save_repository.dart';
import '../../../src/application/load_game_use_case.dart';
import '../../../src/application/save_game_use_case.dart';
import '../../../src/infrastructure/file_game_save_repository.dart';
import '../../application/battle_start_request.dart';
import '../../application/cutscene_runtime_models.dart';
import '../../application/cutscene_runtime_runner.dart';
import '../../application/dialogue_runtime_models.dart';
import '../../application/encounter_to_battle_request.dart';
import '../../application/field_move_dialogue.dart';
import '../../application/global_story_chapter_runtime.dart';
import '../../application/load_dialogue_content.dart';
import '../../application/load_runtime_map_bundle.dart';
import '../../application/map_entity_runtime_predicate_evaluator.dart';
import '../../application/movement_feedback.dart';
import '../../application/npc_overworld_movement_defaults.dart';
import '../../application/npc_runtime_presence.dart';
import '../../application/placed_behavior_runtime_cooldown.dart';
import '../../application/resolve_dialogue.dart';
import '../../application/runtime_battle_setup_mapper.dart';
import '../../application/runtime_battle_outcome_apply.dart';
import '../../application/runtime_character_refs.dart';
import '../../application/runtime_map_bundle.dart';
import '../../application/runtime_story_branching.dart';
import '../../application/scenario_runtime/scenario_runtime_executor.dart';
import '../../application/scenario_runtime/scenario_runtime_models.dart';
import '../../application/scenario_runtime_completion_gate.dart';
import '../../application/script_runtime_controller.dart';
import '../../application/script_runtime_state.dart';
import '../../application/scripted_entity_movement_controller.dart';
import '../../application/scripted_entity_movement_models.dart';
import '../../application/scripted_npc_anchor_passability.dart';
import '../../application/step_studio_completion_runtime.dart';
import '../../application/step_studio_world_presence_runtime.dart';
import '../../application/story_flags_manager.dart';
import '../../application/trainer_battle_request.dart';
import '../../infrastructure/tile_image_loader.dart';
import 'battle_overlay_component.dart';
import 'battle_transition_overlay_component.dart';
import 'dialogue_overlay_component.dart';
import 'map_layers_component.dart';
import 'overworld_actor_component.dart';
import 'player_component.dart';
import 'warp_transition_overlay_component.dart';

const double _kViewportTilesX = 15.0;
const double _kViewportTilesY = 11.0;
const double _kWaterRequiresSurfMessageCooldownMs = 900;
const GameplayEncounterPolicy _kEncounterPolicy = GameplayEncounterPolicy(
  chancePerStep: 0.12,
);

enum _RuntimeFlowPhase {
  overworld,
  dialogue,
  mapTransition,
  battleTransition,
  battle,
}

class PlayableMapGame extends FlameGame with KeyboardEvents {
  PlayableMapGame({
    required RuntimeMapBundle bundle,
    required this.projectFilePath,
    SaveData? saveData,
    GameSaveRepository? saveRepository,
    this.bundleTransformer,
    this.runtimeCutscenes = const <RuntimeCutsceneAsset>[],
  })  : _bundle = bundle,
        _gameState = normalizeLoadedGameState(
          saveData == null
              ? const GameState(saveId: 'default')
              : gameStateFromSaveData(saveData),
        ),
        _saveRepo = saveRepository ?? FileGameSaveRepository() {
    if (bundleTransformer != null) {
      _bundle = bundleTransformer!(_bundle);
    }
    _saveGameUseCase = SaveGameUseCase(_saveRepo);
    _loadGameUseCase = LoadGameUseCase(_saveRepo);
  }

  final String projectFilePath;
  final RuntimeMapBundle Function(RuntimeMapBundle bundle)? bundleTransformer;
  final List<RuntimeCutsceneAsset> runtimeCutscenes;
  RuntimeMapBundle _bundle;
  GameState _gameState;
  late GameplayWorldState _world;
  late PlayerComponent _player;
  String _activeMapId = '';
  String? _previousMapId;
  _RuntimeFlowPhase _flowPhase = _RuntimeFlowPhase.overworld;
  final Set<LogicalKeyboardKey> _pressedKeys = <LogicalKeyboardKey>{};
  LogicalKeyboardKey? _lastMoveKey;
  TriggeredWarp? _pendingWarp;
  TriggeredConnection? _pendingConnection;
  BattleStartRequest? _pendingBattleRequest;
  PlacedElementInteracted? _pendingPlacedElementBehavior;
  DialogueOverlayComponent? _dialogueOverlay;
  BattleTransitionOverlayComponent? _battleTransitionOverlay;
  BattleOverlayComponent? _battleOverlay;
  WarpTransitionOverlayComponent? _warpTransitionOverlay;
  TextComponent? _notification;
  final List<OverworldActorComponent> _npcActors = [];
  final Map<String, _LoadedPlayableMap> _loadedMapsById = {};
  final Map<String, Future<_LoadedPlayableMap?>> _loadMapFutureById = {};
  final math.Random _encounterRandom = math.Random();
  final GridPathfinder _followPathfinder = const GridPathfinder();
  final RuntimeBattleSetupMapper _battleSetupMapper =
      const RuntimeBattleSetupMapper();
  final PlacedBehaviorCooldownGate _placedBehaviorCooldownGate =
      PlacedBehaviorCooldownGate();
  final StoryFlagsManager _storyFlags = const StoryFlagsManager();
  final RuntimeStoryBranching _storyBranching = const RuntimeStoryBranching();
  final ScenarioRuntimeExecutor _scenarioRuntime =
      const ScenarioRuntimeExecutor();

  /// Cache de l’index Step Studio ↔ cutscenes locales (invalidé quand [_bundle] change).
  StepCompletionCutsceneIndex? _cachedStepCompletionIndex;
  RuntimeMapBundle? _cachedStepCompletionBundleForIndex;

  /// Cache des `worldChanges` parsés (une entrée par ligne JSON) pour le manifeste courant.
  List<StepStudioWorldPresenceRule> _cachedStepStudioWorldRules =
      const <StepStudioWorldPresenceRule>[];
  ProjectManifest? _cachedStepStudioWorldRulesManifest;

  void _ensureStepStudioWorldRulesForManifest(ProjectManifest manifest) {
    if (identical(_cachedStepStudioWorldRulesManifest, manifest)) {
      return;
    }
    _cachedStepStudioWorldRulesManifest = manifest;
    _cachedStepStudioWorldRules =
        buildStepStudioWorldPresenceRuleList(manifest.scenarios);
  }

  late final CutsceneRuntimeRunner _cutsceneRunner =
      _buildCutsceneRuntimeRunner();
  CutsceneChoiceRequest? _pendingCutsceneChoiceRequest;
  ScriptedEntityMovementController? _scriptedEntityMovementController;
  final Map<String, GridPos> _runtimeNpcPositions = <String, GridPos>{};
  // Réservations temporaires d'occupation pour PNJ scriptés en cours de pas.
  //
  // Frontière intentionnelle:
  // - `GameplayWorldState` reste la source canonique des positions *commitées*.
  // - pendant une interpolation visuelle d'un pas PNJ, on réserve aussi les
  //   cellules de destination pour éviter les traversées joueur<->PNJ / PNJ<->PNJ.
  final Map<String, Set<GridPos>> _scriptedNpcReservedOccupiedCellsByEntity =
      <String, Set<GridPos>>{};
  double _runtimeClockMs = 0;
  double _lastWaterRequiresSurfMessageAtMs = -1000000000;
  void Function()? _pendingPostDialogueAction;
  bool _awaitingSurfConfirmation = false;
  bool _showCollisionOverlay = false;
  bool _showNpcCollisionDebugOverlay = false;
  bool _showBehaviorDebugOverlay = false;
  bool _showFpsOverlay = false;
  TextComponent? _behaviorDebugOverlay;
  TextComponent? _fpsOverlay;
  double _fpsAccumulatorSeconds = 0.0;
  int _fpsFrameCount = 0;
  double _currentFps = 0.0;
  String _lastBehaviorDebugLine = 'Aucun behavior déclenché';
  GridPos? _debugTileMarkerPos;
  String? _debugTileMarkerLabel;
  RectangleComponent? _debugTileMarkerFill;
  RectangleComponent? _debugTileMarkerBorder;
  TextComponent? _debugTileMarkerText;
  final Map<String, _NpcCollisionDebugVisual> _npcCollisionDebugByEntityId =
      <String, _NpcCollisionDebugVisual>{};

  ScriptRuntimeController? _activeScriptController;
  bool _isAwaitingScriptResume = false;
  Set<String> _activeScenarioTriggerIds = <String>{};
  _PendingScenarioFollowRequest? _pendingScenarioFollowRequest;
  _PendingScenarioTransitionMapRequest? _pendingScenarioTransitionMapRequest;
  final Map<String, _PendingScenarioNpcWarpEntry>
      _pendingScenarioNpcWarpEntries = <String, _PendingScenarioNpcWarpEntry>{};
  final Map<String, _PendingScenarioMoveContinuation>
      _pendingScenarioMoveContinuationsByEntity =
      <String, _PendingScenarioMoveContinuation>{};
  // File d'attente des scénarios ayant atteint `end` mais dont la complétion
  // doit attendre la fin réelle des effets runtime visibles.
  final List<_PendingScenarioReachedEnd> _pendingScenarioReachedEndQueue =
      <_PendingScenarioReachedEnd>[];
  String? _lastScenarioCompletionBlockReason;

  // Save/Load system
  final GameSaveRepository _saveRepo;
  late SaveGameUseCase _saveGameUseCase;
  late LoadGameUseCase _loadGameUseCase;

  // Battle system (map_battle integration)
  BattleSession? _battleSession;
  RuntimeActiveBattleContext? _activeBattleContext;

  // Battle flow hardening
  bool _isBattleResolving =
      false; // Lock pour empêcher spam clavier pendant résolution

  // Line of Sight (LoS) trainer detection
  final Set<String> _triggeredTrainerBattles = {}; // Anti-retrigger lock

  bool get showCollisionOverlay => _showCollisionOverlay;

  void setCollisionOverlayVisible(bool visible) {
    _showCollisionOverlay = visible;
    for (final loaded in _loadedMapsById.values) {
      loaded.backgroundLayers.showCollisionOverlay = visible;
    }
  }

  bool get showNpcCollisionDebugOverlay => _showNpcCollisionDebugOverlay;

  void setNpcCollisionDebugOverlayVisible(bool visible) {
    _showNpcCollisionDebugOverlay = visible;
    if (!isLoaded) {
      return;
    }
    _syncNpcCollisionDebugOverlay();
  }

  bool get showBehaviorDebugOverlay => _showBehaviorDebugOverlay;
  bool get showFpsOverlay => _showFpsOverlay;
  double get currentFps => _currentFps;

  /// Active/désactive l'affichage du compteur FPS dans le viewport runtime.
  ///
  /// Ce toggle est utilisé par l'example host pour un contrôle manuel.
  /// Le compteur est volontairement optionnel pour éviter toute pollution
  /// visuelle par défaut.
  void setFpsOverlayVisible(bool visible) {
    _showFpsOverlay = visible;
    if (!_showFpsOverlay) {
      _fpsOverlay?.removeFromParent();
      _fpsOverlay = null;
      return;
    }
    if (!isLoaded) {
      return;
    }
    _ensureFpsOverlay();
  }

  MovementMode get playerMovementMode {
    if (isLoaded) {
      return _world.player.movementMode;
    }
    return _gameState.playerMovementMode;
  }

  bool get isSurfing => playerMovementMode == MovementMode.surf;

  ({String mapId, int playerX, int playerY, String facing, String movementMode})
      get saveLoadInfo {
    if (isLoaded) {
      _syncGameStateFromWorld(mapIdOverride: _activeMapId);
    }
    return (
      mapId: _gameState.currentMapId,
      playerX: _gameState.playerPosition.x,
      playerY: _gameState.playerPosition.y,
      facing: _gameState.playerFacing.name,
      movementMode: _gameState.playerMovementMode.name,
    );
  }

  GameState get gameStateSnapshot {
    if (isLoaded) {
      _syncGameStateFromWorld(mapIdOverride: _activeMapId);
    }
    return _gameState;
  }

  @visibleForTesting
  String get debugFlowPhaseName => _flowPhase.name;

  @visibleForTesting
  void debugApplyBattleOutcomeForTest({
    required RuntimeActiveBattleContext context,
    required BattleOutcome outcome,
  }) {
    // Seam de test volontairement fin :
    // - on ne contourne pas la logique réelle de fin de combat ;
    // - on évite en revanche de devoir piloter tout l'overlay Flame au clavier
    //   pour prouver les garanties lot 15 ;
    // - le runtime garde donc un point d'entrée stable pour tester le write-back
    //   + la reprise overworld sans créer d'API produit parallèle.
    _activeBattleContext = context;
    _flowPhase = _RuntimeFlowPhase.battle;
    _onBattleFinished(outcome);
  }

  @visibleForTesting
  void debugSetPlayerStateForTest({
    required GridPos position,
    required Direction facing,
    MovementMode movementMode = MovementMode.walk,
  }) {
    // Petit seam de test volontaire :
    // - il permet de placer le joueur sur une cellule précise avant un scénario
    //   de reprise runtime ;
    // - il évite d'écrire un test d'input Flame plus fragile que la logique que
    //   l'on cherche réellement à prouver ici ;
    // - il ne sert pas au produit, uniquement à valider la cohérence du lot 15.
    _world = _world.withPlayer(
      _world.player.copyWith(
        pos: position,
        facing: facing,
        movementMode: movementMode,
      ),
    );
    _player.syncState(_world.player, snapToGrid: true);
    _syncGameStateFromWorld(mapIdOverride: _activeMapId);
    _syncCameraToPlayer();
  }

  void _syncGameStateFromWorld({String? mapIdOverride}) {
    final mapId = mapIdOverride ?? _activeMapId;
    _gameState = _gameState.copyWith(
      currentMapId: mapId,
      playerPosition: _world.player.pos,
      playerFacing: _world.player.facing.asFacing,
      playerMovementMode: _world.player.movementMode,
    );
  }

  /// Filtre spatial PNJ : d’abord [MapEntityNpcData.visibilityRule], puis
  /// les `worldChanges` Step Studio (même [mapId] / [entity.id] que l’authoring).
  ///
  /// Les règles Step Studio sont relues via [_ensureStepStudioWorldRulesForManifest]
  /// **à chaque évaluation** pour éviter une liste [worldRules] capturée une fois
  /// et obsolète si le cache manifeste est invalidé.
  NpcMapPresencePredicate _npcPresencePredicateFor(ProjectManifest manifest) {
    return (String mapId, MapEntity npcEntity) {
      _ensureStepStudioWorldRulesForManifest(manifest);
      return isNpcRuntimePresentOnMap(
        gameState: _gameState,
        manifest: manifest,
        stepStudioWorldRules: _cachedStepStudioWorldRules,
        mapId: mapId,
        entity: npcEntity,
      );
    };
  }

  /// Dialogue effectif : variantes ordonnées puis dialogue par défaut du PNJ.
  DialogueRef? _resolveNpcDialogueRef(MapEntity entity) {
    final npc = entity.npc;
    if (npc == null) {
      return null;
    }
    return MapEntityRuntimePredicateEvaluator(
      gameState: _gameState,
      chapterIndex:
          buildGlobalStoryChapterStepIndex(_bundle.manifest.scenarios),
    ).resolveNpcDialogue(npc);
  }

  void _refreshWorldNpcPresence() {
    if (!isLoaded) {
      return;
    }
    _world = _world.withNpcMapPresencePredicate(
      _npcPresencePredicateFor(_bundle.manifest),
    );
    // Retirer les acteurs Flame des PNJ désormais absents (évite toute dérive
    // visuelle / hit test si un composant repasse « visible » par défaut).
    _detachAbsentNpcActorsFromAllLoadedMaps();
    _syncNpcRenderVisibility();
    _syncNpcCollisionDebugOverlay();
    // Patrouilles / réservations / LoS trainer : mêmes règles que le gameplay
    // (un PNJ « absent » ne doit plus consommer ces systèmes parallèles).
    _stopGameplaySideEffectsForAbsentNpcs();
  }

  /// Retire les [OverworldActorComponent] pour tout PNJ avec personnage dont le
  /// prédicat de présence est faux (cartes chargées / voisines incluses).
  void _detachAbsentNpcActorsFromAllLoadedMaps() {
    for (final loaded in _loadedMapsById.values) {
      final npcPred = _npcPresencePredicateFor(loaded.bundle.manifest);
      final mapId = loaded.bundle.map.id;
      final toRemove = <String>[];
      for (final entity in loaded.bundle.map.entities) {
        if (entity.kind != MapEntityKind.npc) {
          continue;
        }
        final charId = resolveNpcCharacterId(entity, loaded.bundle.manifest);
        if (charId == null || charId.isEmpty) {
          continue;
        }
        if (npcPred(mapId, entity)) {
          continue;
        }
        if (loaded.npcActorByEntityId.containsKey(entity.id)) {
          toRemove.add(entity.id);
        }
      }
      for (final rawId in toRemove) {
        final id = rawId.trim();
        if (id.isEmpty) {
          continue;
        }
        _scriptedEntityMovementController?.stopPatrol(id);
        _scriptedEntityMovementController?.untrackEntity(id);
        _scriptedNpcReservedOccupiedCellsByEntity.remove(id);
        _runtimeNpcPositions.remove(id);
        _triggeredTrainerBattles.remove(id);
        if (_pendingScenarioFollowRequest?.leaderEntityId == id) {
          _pendingScenarioFollowRequest = null;
        }
        _pendingScenarioNpcWarpEntries.remove(id);
        _pendingScenarioMoveContinuationsByEntity.remove(id);
        _purgeMountedNpcActorForEntity(entityId: id, loaded: loaded);
      }
    }
  }

  void _purgeMountedNpcActorForEntity({
    required String entityId,
    required _LoadedPlayableMap loaded,
  }) {
    final actor = loaded.npcActorByEntityId.remove(entityId);
    if (actor != null) {
      loaded.npcActors.remove(actor);
      _npcActors.remove(actor);
      actor.removeFromParent();
    }
    final visual = _npcCollisionDebugByEntityId.remove(entityId);
    visual?.spriteRect.removeFromParent();
    visual?.collisionRect.removeFromParent();
    visual?.anchorMarker.removeFromParent();
  }

  /// Arrête tout effet runtime **hors** [GameplayWorldState] qui pourrait encore
  /// cibler un PNJ filtré par [NpcMapPresencePredicate] (patrouille, réservation
  /// de cases, lock trainer).
  void _stopGameplaySideEffectsForAbsentNpcs() {
    final controller = _scriptedEntityMovementController;
    final pred = _npcPresencePredicateFor(_bundle.manifest);
    final mapId = _world.map.id;
    for (final entity in _world.map.entities) {
      if (entity.kind != MapEntityKind.npc) {
        continue;
      }
      if (pred(mapId, entity)) {
        continue;
      }
      controller?.stopPatrol(entity.id);
      _scriptedNpcReservedOccupiedCellsByEntity.remove(entity.id);
      _runtimeNpcPositions.remove(entity.id);
      _triggeredTrainerBattles.remove(entity.id);
    }
    _applyNpcOverworldDefaultMovement();
  }

  void _syncNpcRenderVisibility() {
    for (final loaded in _loadedMapsById.values) {
      _applyNpcVisibilityToLoadedMap(loaded);
    }
  }

  void _applyNpcVisibilityToLoadedMap(_LoadedPlayableMap loaded) {
    final npcPred = _npcPresencePredicateFor(loaded.bundle.manifest);
    loaded.backgroundLayers.npcMapPresencePredicate = npcPred;
    loaded.foregroundLayers.npcMapPresencePredicate = npcPred;
    for (final entity in loaded.bundle.map.entities) {
      if (entity.kind != MapEntityKind.npc) {
        continue;
      }
      final present = npcPred(loaded.bundle.map.id, entity);
      // Trace "source de vérité -> rendu" :
      // on journalise la décision finale de présence pour chaque PNJ afin de
      // diagnostiquer rapidement un cas "la règle existe mais l'acteur reste visible".
      debugPrint(
        '[step_studio_trace] npc_presence_applied map=${loaded.bundle.map.id} entity=${entity.id} present=$present',
      );
      loaded.npcActorByEntityId[entity.id]?.setGameplayVisible(present);
    }
  }

  RuntimeMapBundle _resolveRuntimeBundle(RuntimeMapBundle bundle) {
    final transform = bundleTransformer;
    if (transform == null) {
      return bundle;
    }
    return transform(bundle);
  }

  void setPlayerMovementMode(MovementMode movementMode) {
    if (!isLoaded) {
      return;
    }
    if (_world.player.movementMode == movementMode) {
      return;
    }
    _world = _world.withPlayer(
      _world.player.copyWith(movementMode: movementMode),
    );
    _syncGameStateFromWorld();
    _player.syncState(_world.player);
  }

  void setSurfingEnabled(bool enabled) {
    setPlayerMovementMode(enabled ? MovementMode.surf : MovementMode.walk);
  }

  /// Lance un déplacement scripté ponctuel pour un PNJ.
  ///
  /// API runtime publique pensée pour une future orchestration cutscene:
  /// - start movement
  /// - poll status
  /// - wait until completed/failed
  ScriptedEntityMovementStatus startScriptedNpcMove({
    required String entityId,
    required GridPos destination,
  }) {
    final controller = _scriptedEntityMovementController;
    if (controller == null) {
      return ScriptedEntityMovementStatus(
        entityId: entityId,
        state: ScriptedEntityMovementState.failed,
        currentPos: const GridPos(x: 0, y: 0),
        targetPos: destination,
        failureReason: 'Scripted movement controller is not initialized.',
      );
    }
    return controller.moveEntityTo(
      entityId: entityId,
      destination: destination,
    );
  }

  /// Active une patrouille simple (waypoints) pour un PNJ.
  ScriptedEntityMovementStatus startScriptedNpcPatrol({
    required String entityId,
    required List<GridPos> waypoints,
    bool loop = true,
    int pauseDurationMs = 0,
    int stepDurationMs = 200,
  }) {
    final controller = _scriptedEntityMovementController;
    if (controller == null) {
      return ScriptedEntityMovementStatus(
        entityId: entityId,
        state: ScriptedEntityMovementState.failed,
        currentPos: const GridPos(x: 0, y: 0),
        failureReason: 'Scripted movement controller is not initialized.',
      );
    }
    return controller.startPatrol(
      ScriptedEntityPatrolRoute(
        entityId: entityId,
        waypoints: waypoints,
        loop: loop,
        pauseDurationMs: pauseDurationMs,
        stepDurationMs: stepDurationMs,
      ),
    );
  }

  void stopScriptedNpcPatrol(String entityId) {
    _scriptedEntityMovementController?.stopPatrol(entityId);
  }

  ScriptedEntityMovementStatus scriptedNpcMovementStatus(String entityId) {
    final controller = _scriptedEntityMovementController;
    if (controller == null) {
      return ScriptedEntityMovementStatus(
        entityId: entityId,
        state: ScriptedEntityMovementState.failed,
        currentPos: const GridPos(x: 0, y: 0),
        failureReason: 'Scripted movement controller is not initialized.',
      );
    }
    return controller.statusOf(entityId);
  }

  /// true si une cutscene runtime est en cours d'exécution.
  bool get isCutsceneRunning => _cutsceneRunner.isRunning;

  /// Identifiant de la cutscene active, `null` si aucune.
  String? get activeCutsceneId => _cutsceneRunner.activeCutsceneId;

  /// Snapshot détaillé du runner cutscene.
  CutsceneRuntimeStatus get cutsceneStatus => _cutsceneRunner.status;

  /// Requête de choix en attente (si la cutscene attend une décision joueur).
  CutsceneChoiceRequest? get pendingCutsceneChoiceRequest =>
      _pendingCutsceneChoiceRequest;

  bool get hasPendingCutsceneChoice => _pendingCutsceneChoiceRequest != null;

  /// Dernier choix résolu pendant la cutscene active.
  CutsceneChoiceResult? get lastCutsceneChoiceResult =>
      _cutsceneRunner.lastChoiceResult;

  /// Démarre une cutscene fournie explicitement.
  ///
  /// Cette API est utile pour des déclenchements runtime directs (tests,
  /// scripts d'initialisation, futur bridge Step -> Cutscene).
  bool startCutscene(RuntimeCutsceneAsset cutscene) {
    if (!isLoaded) {
      return false;
    }
    if (_flowPhase != _RuntimeFlowPhase.overworld) {
      return false;
    }
    _pendingCutsceneChoiceRequest = null;
    return _cutsceneRunner.start(cutscene);
  }

  /// Démarre une cutscene depuis le registre runtime injecté au game host.
  ///
  /// Retourne `false` si l'ID est introuvable ou si une cutscene est déjà active.
  bool startCutsceneById(String cutsceneId) {
    if (!isLoaded) {
      return false;
    }
    final normalized = cutsceneId.trim();
    if (normalized.isEmpty) {
      return false;
    }
    final cutscene = _findRuntimeCutsceneById(normalized);
    if (cutscene == null) {
      return false;
    }
    _pendingCutsceneChoiceRequest = null;
    return _cutsceneRunner.start(cutscene);
  }

  bool resolvePendingCutsceneChoiceByIndex(int selectedIndex) {
    final resolved = _cutsceneRunner.resolveActiveChoiceByIndex(selectedIndex);
    if (resolved) {
      _pendingCutsceneChoiceRequest = _cutsceneRunner.activeChoiceRequest;
    }
    return resolved;
  }

  bool resolvePendingCutsceneChoiceByValue(String selectedValue) {
    final resolved = _cutsceneRunner.resolveActiveChoiceByValue(selectedValue);
    if (resolved) {
      _pendingCutsceneChoiceRequest = _cutsceneRunner.activeChoiceRequest;
    }
    return resolved;
  }

  void setBehaviorDebugOverlayVisible(bool visible) {
    _showBehaviorDebugOverlay = visible;
    if (!visible) {
      _behaviorDebugOverlay?.removeFromParent();
      _behaviorDebugOverlay = null;
      return;
    }
    if (!isLoaded) {
      return;
    }
    _ensureBehaviorDebugOverlay();
  }

  void setDebugTileMarker({
    required GridPos? position,
    String? label,
  }) {
    _debugTileMarkerPos = position;
    _debugTileMarkerLabel = label;
    if (!isLoaded) {
      return;
    }
    _applyDebugTileMarker();
  }

  @override
  Future<void> onLoad() async {
    try {
      _world = GameplayWorldState.fromMap(
        _bundle.map,
        project: _bundle.manifest,
        tileWidth: _bundle.manifest.settings.tileWidth,
        tileHeight: _bundle.manifest.settings.tileHeight,
        npcMapPresencePredicate: _npcPresencePredicateFor(_bundle.manifest),
      );
      debugPrint(
        '[runtime] Map loaded: ${_bundle.map.id}, spawn at (${_world.player.pos.x}, ${_world.player.pos.y})',
      );
    } on GameplaySpawnResolutionException catch (e) {
      debugPrint(
          '[runtime] Spawn resolution failed ($e), falling back to (0,0)');
      _world = GameplayWorldState.initial(
        map: _bundle.map,
        playerPos: const GridPos(x: 0, y: 0),
        project: _bundle.manifest,
        tileWidth: _bundle.manifest.settings.tileWidth,
        tileHeight: _bundle.manifest.settings.tileHeight,
        npcMapPresencePredicate: _npcPresencePredicateFor(_bundle.manifest),
      );
    }
    final images =
        await loadTilesetImagesById(_bundle.tilesetAbsolutePathsById);
    _activeMapId = _bundle.map.id;
    final rootMap = await _mountLoadedMap(
      bundle: _bundle,
      tileImagesById: images,
      originCellX: 0,
      originCellY: 0,
    );
    final playerChar = _resolvePlayerCharacter(_bundle);
    _player = PlayerComponent(
      bundle: _bundle,
      state: _world.player,
      characterEntry: playerChar,
      tileImages: images,
      mapOrigin: _originPixelsOf(rootMap),
    );
    await world.add(_player);
    _syncGameStateFromWorld();
    _configureCameraViewport();
    _syncCameraToPlayer();
    _preloadActiveMapConnections();
    _ensureBehaviorDebugOverlay();
    _ensureFpsOverlay();
    _applyDebugTileMarker();
    _resetScriptedNpcMovementController();
    _activeScenarioTriggerIds = _scenarioRuntime.triggerIdsAtPosition(
      map: _bundle.map,
      pos: _world.player.pos,
    );
    _dispatchScenarioRuntimeSource(
      ScenarioRuntimeSourceEvent.mapEnter(mapId: _activeMapId),
    );
    return super.onLoad();
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    final isDown = event is KeyDownEvent || event is KeyRepeatEvent;
    final isUp = event is KeyUpEvent;
    final key = event.logicalKey;

    // IMPORTANT: Handle battle phase FIRST before movement keys
    // Otherwise arrow keys will be captured by movement handler
    if (_flowPhase == _RuntimeFlowPhase.battle) {
      // Navigation dans les choix du combat
      // ↑/↓ pour naviguer, E/Space/Enter pour valider, Escape pour fuir
      final overlay = _battleOverlay;
      if (overlay != null) {
        // ↑ : sélection précédente (KeyDownEvent ONLY, pas KeyRepeatEvent)
        if (key == LogicalKeyboardKey.arrowUp && event is KeyDownEvent) {
          final changed = overlay.moveSelectionUp();
          debugPrint('[battle] ArrowUp pressed, selection changed=$changed');
          return KeyEventResult.handled;
        }
        // ↓ : sélection suivante (KeyDownEvent ONLY, pas KeyRepeatEvent)
        if (key == LogicalKeyboardKey.arrowDown && event is KeyDownEvent) {
          final changed = overlay.moveSelectionDown();
          debugPrint('[battle] ArrowDown pressed, selection changed=$changed');
          return KeyEventResult.handled;
        }
        // E / Space / Enter : validation du choix sélectionné
        // CRITICAL: Only process KeyDownEvent, NOT KeyRepeatEvent!
        // KeyRepeatEvent is sent when key is held down, which causes multiple validations
        if (event is KeyDownEvent &&
            (key == LogicalKeyboardKey.keyE ||
                key == LogicalKeyboardKey.space ||
                key == LogicalKeyboardKey.enter)) {
          // CRITICAL: Re-check phase AFTER getting into this block
          // Because the phase might have changed during this same key event processing
          // (e.g., last attack of the battle finished it)
          if (_flowPhase != _RuntimeFlowPhase.battle) {
            debugPrint(
                '[battle] Validate key pressed but phase changed to $_flowPhase, IGNORING');
            return KeyEventResult.ignored;
          }
          // Also check if overlay is still valid (might have been removed)
          if (_battleOverlay == null) {
            debugPrint(
                '[battle] Validate key pressed but overlay is null, IGNORING');
            return KeyEventResult.ignored;
          }
          final selectedChoice = overlay.getSelectedChoice();
          debugPrint(
              '[battle] Validate key pressed (E/Space/Enter), selectedChoice=$selectedChoice');
          final validated = overlay.validateSelectedChoice();
          debugPrint('[battle] validateSelectedChoice returned=$validated');
          return KeyEventResult.handled;
        }
        // Escape : tentative de fuite (seulement si l'action est disponible)
        if (event is KeyDownEvent && key == LogicalKeyboardKey.escape) {
          // Vérifier si l'action "Fuir" est disponible dans les choix
          final selectedChoice = overlay.getSelectedChoice();
          debugPrint('[battle] Escape pressed, selectedChoice=$selectedChoice');
          if (selectedChoice is PlayerBattleChoiceRun) {
            overlay.validateSelectedChoice();
            debugPrint('[battle] Escape validated (run selected)');
            return KeyEventResult.handled;
          }
          // Si "Fuir" n'est pas sélectionné, ne rien faire
          debugPrint('[battle] Escape ignored (run not selected)');
          return KeyEventResult.ignored;
        }
      } else {
        debugPrint('[battle] Keyboard event but overlay is null!');
      }
      return KeyEventResult.ignored;
    }

    // Pendant une cutscene active en overworld, on bloque les entrées joueur
    // directes (déplacement/interact) pour garder la scène déterministe.
    if (isCutsceneRunning && _flowPhase == _RuntimeFlowPhase.overworld) {
      if (_isMovementKey(key)) {
        _pressedKeys.remove(key);
        if (_lastMoveKey == key) {
          _lastMoveKey = null;
        }
        return KeyEventResult.handled;
      }
      if (event is KeyDownEvent &&
          (key == LogicalKeyboardKey.keyE ||
              key == LogicalKeyboardKey.space ||
              key == LogicalKeyboardKey.enter)) {
        return KeyEventResult.handled;
      }
    }

    // Déplacement scripté joueur (scénario / cutscene): pas d’entrées clavier.
    if (_suppressOverworldInputForScriptedPlayerMovement() &&
        _flowPhase == _RuntimeFlowPhase.overworld) {
      if (_isMovementKey(key)) {
        _pressedKeys.remove(key);
        if (_lastMoveKey == key) {
          _lastMoveKey = null;
        }
        return KeyEventResult.handled;
      }
      if (event is KeyDownEvent &&
          (key == LogicalKeyboardKey.keyE ||
              key == LogicalKeyboardKey.space ||
              key == LogicalKeyboardKey.enter)) {
        return KeyEventResult.handled;
      }
    }

    // Handle movement keys (but NOT during battle)
    if (_isMovementKey(key)) {
      if (_flowPhase == _RuntimeFlowPhase.dialogue) {
        _pressedKeys.remove(key);
        if (_lastMoveKey == key) {
          _lastMoveKey = null;
        }
        if ((_dialogueOverlay?.isShowingChoices ?? false) && isDown) {
          if (key == LogicalKeyboardKey.arrowUp) {
            _moveChoiceCursor(-1);
          } else if (key == LogicalKeyboardKey.arrowDown) {
            _moveChoiceCursor(1);
          }
        }
        return KeyEventResult.handled;
      }
      if (_flowPhase != _RuntimeFlowPhase.overworld) {
        _pressedKeys.remove(key);
        if (_lastMoveKey == key) {
          _lastMoveKey = null;
        }
        return KeyEventResult.handled;
      }
      if (isDown) {
        _pressedKeys.add(key);
        _lastMoveKey = key;
      } else if (isUp) {
        _pressedKeys.remove(key);
        if (_lastMoveKey == key) {
          _lastMoveKey = null;
        }
      }
      return KeyEventResult.handled;
    }

    if (_flowPhase == _RuntimeFlowPhase.mapTransition ||
        _flowPhase == _RuntimeFlowPhase.battleTransition) {
      return KeyEventResult.ignored;
    }
    if (!isDown) return KeyEventResult.ignored;

    if (_flowPhase == _RuntimeFlowPhase.dialogue) {
      final overlay = _dialogueOverlay!;
      if (overlay.isShowingChoices) {
        if (key == LogicalKeyboardKey.arrowUp) {
          _moveChoiceCursor(-1);
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.arrowDown) {
          _moveChoiceCursor(1);
          return KeyEventResult.handled;
        }
        if (event is KeyDownEvent &&
            (key == LogicalKeyboardKey.keyE ||
                key == LogicalKeyboardKey.space)) {
          _confirmDialogueChoice();
          return KeyEventResult.handled;
        }
      } else {
        if (event is KeyDownEvent &&
            (key == LogicalKeyboardKey.keyE ||
                key == LogicalKeyboardKey.space)) {
          _advanceDialogue();
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    }

    if (_flowPhase != _RuntimeFlowPhase.overworld) {
      return KeyEventResult.ignored;
    }

    if (event is KeyDownEvent &&
        (key == LogicalKeyboardKey.keyE || key == LogicalKeyboardKey.space)) {
      _handleInteract();
      return KeyEventResult.handled;
    }

    return KeyEventResult.handled;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _updateFps(dt);
    _runtimeClockMs += dt * 1000;
    _placedBehaviorCooldownGate.prune(nowMs: _runtimeClockMs);
    _updateActorDepthOrdering();
    _syncCameraToPlayer();
    _syncNpcCollisionDebugOverlay();

    if (_flowPhase != _RuntimeFlowPhase.overworld) {
      return;
    }

    final pendingWarp = _pendingWarp;
    if (pendingWarp != null && !_player.isStepping) {
      _pendingWarp = null;
      _handleWarp(pendingWarp);
      return;
    }

    final pendingConnection = _pendingConnection;
    if (pendingConnection != null && !_player.isStepping) {
      _pendingConnection = null;
      _handleConnection(pendingConnection);
      return;
    }

    final pendingBattleRequest = _pendingBattleRequest;
    if (pendingBattleRequest != null && !_player.isStepping) {
      _pendingBattleRequest = null;
      _startBattleHandoff(pendingBattleRequest);
      return;
    }

    final pendingPlacedElementBehavior = _pendingPlacedElementBehavior;
    if (pendingPlacedElementBehavior != null && !_player.isStepping) {
      _pendingPlacedElementBehavior = null;
      _executePlacedElementBehavior(
        element: pendingPlacedElementBehavior.element,
        behavior: pendingPlacedElementBehavior.behavior,
        trigger: pendingPlacedElementBehavior.trigger,
      );
      return;
    }

    // Tick du système de déplacement scripté PNJ.
    //
    // Ce tick reste dans le flux overworld pour ce MVP:
    // - pas d'exécution pendant dialogue/battle transition;
    // - base propre pour un futur "wait movement" en cutscene.
    _scriptedEntityMovementController?.update(dt);
    _processPendingScenarioNpcWarpEntries();
    _processPendingScenarioMoveContinuations();
    _processPendingScenarioFollowRequest();
    _processPendingScenarioTransitionMapRequest();
    _processPendingScenarioReachedEndCompletions();

    // Tick runner cutscene MVP (séquentiel).
    _cutsceneRunner.update(dt);
    _pendingCutsceneChoiceRequest = _cutsceneRunner.activeChoiceRequest;
    if (isCutsceneRunning) {
      // Tant que la cutscene n'est pas terminée, on ne laisse pas la boucle
      // input joueur déplacer le player.
      return;
    }

    _driveMovement();
  }

  void _updateActorDepthOrdering() {
    _player.priority = 1000 + _player.footPoint.y.round();
    for (final actor in _npcActors) {
      actor.priority = 1000 + actor.depthSortY.round();
    }
  }

  bool _isMovementKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.keyW ||
        key == LogicalKeyboardKey.keyA ||
        key == LogicalKeyboardKey.keyS ||
        key == LogicalKeyboardKey.keyD;
  }

  GameplayIntent? _intentFromPressedKeys() {
    Direction? dirFor(LogicalKeyboardKey key) {
      if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.keyW) {
        return Direction.north;
      }
      if (key == LogicalKeyboardKey.arrowDown ||
          key == LogicalKeyboardKey.keyS) {
        return Direction.south;
      }
      if (key == LogicalKeyboardKey.arrowLeft ||
          key == LogicalKeyboardKey.keyA) {
        return Direction.west;
      }
      if (key == LogicalKeyboardKey.arrowRight ||
          key == LogicalKeyboardKey.keyD) {
        return Direction.east;
      }
      return null;
    }

    final preferred = _lastMoveKey;
    if (preferred != null && _pressedKeys.contains(preferred)) {
      final d = dirFor(preferred);
      if (d != null) {
        return MoveIntent(d);
      }
    }

    for (final key in _pressedKeys) {
      final d = dirFor(key);
      if (d != null) {
        return MoveIntent(d);
      }
    }
    return null;
  }

  void _driveMovement() {
    if (_suppressOverworldInputForScriptedPlayerMovement()) {
      _clearPressedMovementKeys();
      return;
    }
    if (_player.isStepping) {
      return;
    }

    final intent = _intentFromPressedKeys();
    if (intent == null) {
      _player.syncState(_world.player);
      return;
    }
    final attemptedDirection = intent is MoveIntent ? intent.direction : null;
    final attemptedX = attemptedDirection == null
        ? null
        : _world.player.pos.x + attemptedDirection.dx;
    final attemptedY = attemptedDirection == null
        ? null
        : _world.player.pos.y + attemptedDirection.dy;
    final attemptedOutOfBounds = attemptedX != null &&
        attemptedY != null &&
        (attemptedX < 0 ||
            attemptedY < 0 ||
            attemptedX >= _world.map.size.width ||
            attemptedY >= _world.map.size.height);

    // Collision runtime stricte contre les destinations PNJ réservées.
    //
    // Sans ce garde-fou, un joueur peut entrer dans la case cible d'un PNJ en
    // interpolation (avant commit canonique), créant un effet de traversée.
    if (attemptedDirection != null &&
        attemptedX != null &&
        attemptedY != null &&
        _isCellReservedByScriptedNpc(
          GridPos(x: attemptedX, y: attemptedY),
        )) {
      _world =
          _world.withPlayer(_world.player.copyWith(facing: attemptedDirection));
      _player.syncState(_world.player);
      return;
    }

    final previousPlayerPos = _world.player.pos;
    final result = stepGameplayWorld(_world, intent);
    _world = result.world;
    _syncGameStateFromWorld();
    _consumePathAnimationSignals(result.pathAnimationSignals);

    if (result is Blocked) {
      if (result.reason == GameplayMovementBlockReason.waterRequiresSurf) {
        _handleWaterBlocked();
      }
      if (attemptedOutOfBounds && attemptedDirection != null) {
        final direction = switch (attemptedDirection) {
          Direction.north => MapConnectionDirection.north,
          Direction.south => MapConnectionDirection.south,
          Direction.east => MapConnectionDirection.east,
          Direction.west => MapConnectionDirection.west,
        };
        debugPrint(
          '[connection] no connection for direction=${direction.name} map=${_bundle.map.id}',
        );
      }
      _player.syncState(_world.player);
      return;
    }

    if (result is Moved) {
      _player.startStep(
        _world.player,
        durationSeconds: PlayerComponent.kDefaultStepSeconds,
      );
      _checkStepEncounter();
      _checkTrainerLineOfSight(); // Check LoS only when player position changes
      _dispatchScenarioTriggerEnterFromMovement(
        previousPos: previousPlayerPos,
        currentPos: _world.player.pos,
      );
      return;
    }

    if (result is WarpTriggered) {
      if (result.warp.triggerMode == MapWarpTriggerMode.onEnter) {
        _player.startStep(
          _world.player,
          durationSeconds: PlayerComponent.kDefaultStepSeconds,
        );
      } else {
        _player.syncState(_world.player, snapToGrid: true);
      }
      _pendingWarp = result.warp;
      debugPrint(
        '[warp] Triggered warp ${result.warp.warpId} mode=${result.warp.triggerMode.name} -> map=${result.warp.targetMapId} pos=(${result.warp.targetPos.x}, ${result.warp.targetPos.y})',
      );
      return;
    }

    if (result is ConnectionTriggered) {
      _player.syncState(_world.player);
      _pendingConnection = result.connection;
      debugPrint(
        '[connection] exit detected map=${_bundle.map.id} direction=${result.connection.direction.name} target=${result.connection.targetMapId} offset=${result.connection.offset} source=(${result.connection.sourcePos.x}, ${result.connection.sourcePos.y})',
      );
      return;
    }

    if (result is PlacedElementInteracted) {
      final isMovementTrigger =
          result.trigger == MapPlacedElementTriggerType.onEnter ||
              result.trigger == MapPlacedElementTriggerType.onExit ||
              result.trigger == MapPlacedElementTriggerType.onNear;
      if (isMovementTrigger) {
        _player.startStep(
          _world.player,
          durationSeconds: PlayerComponent.kDefaultStepSeconds,
        );
      } else {
        _player.syncState(_world.player);
      }
      _pendingPlacedElementBehavior = result;
      final behaviorId = result.behavior.id.trim().isEmpty
          ? 'legacy'
          : result.behavior.id.trim();
      debugPrint(
        '[placed_behavior] queued trigger=${result.trigger.name} scope=${result.behavior.triggerScope.name} instance=${result.element.id} behavior=$behaviorId effect=${result.behavior.effect.type.name}',
      );
      _updateBehaviorDebugLine(
        'Queued ${result.trigger.name}/${result.behavior.triggerScope.name} · ${result.behavior.effect.type.name} · ${result.element.id}#$behaviorId',
      );
      return;
    }
  }

  void _checkStepEncounter() {
    final encounterKind = _world.player.movementMode == MovementMode.surf
        ? EncounterKind.surf
        : EncounterKind.walk;
    final pos = _world.player.pos;
    debugPrint(
      '[encounter] checking at x=${pos.x} y=${pos.y} kind=${encounterKind.name}',
    );
    final check = checkEncounterAtPlayerPosition(
      world: _world,
      project: _bundle.manifest,
      encounterKind: encounterKind,
      random: _encounterRandom,
      policy: _kEncounterPolicy,
    );
    _logEncounterCheck(check);
    if (!check.triggered) {
      return;
    }
    final encounter = check.encounter;
    if (encounter == null) {
      return;
    }
    final request = buildBattleStartRequestFromEncounter(
      encounter: encounter,
      world: _world,
    );
    _pendingBattleRequest = request;
    debugPrint(
      '[battle] battle request created kind=${request.kind.name} source=${request.source.name} requestId=${request.requestId}',
    );
    debugPrint(
      '[battle] wild payload species=${encounter.speciesId} level=${encounter.level} map=${encounter.mapId} zone=${encounter.zoneId}',
    );
  }

  /// Détecte les entrées dans des triggers de map pour alimenter les sources
  /// scénario `sourceTriggerEnter`.
  ///
  /// Le calcul est local et déterministe:
  /// - on lit les triggers couvrant l'ancienne position,
  /// - on lit les triggers couvrant la nouvelle position,
  /// - on déclenche uniquement les IDs présents dans "nouvelle - ancienne".
  void _dispatchScenarioTriggerEnterFromMovement({
    required GridPos previousPos,
    required GridPos currentPos,
  }) {
    // On privilégie l'état mémorisé pour éviter de recalculer l'ancienne
    // couverture à chaque tick. Un fallback de sécurité reste possible.
    final previousIds = _activeScenarioTriggerIds.isEmpty
        ? _scenarioRuntime.triggerIdsAtPosition(
            map: _bundle.map,
            pos: previousPos,
          )
        : _activeScenarioTriggerIds;
    final currentIds = _scenarioRuntime.triggerIdsAtPosition(
      map: _bundle.map,
      pos: currentPos,
    );
    _activeScenarioTriggerIds = currentIds;
    final enteredIds =
        currentIds.difference(previousIds).toList(growable: false)..sort();
    for (final triggerId in enteredIds) {
      _dispatchScenarioRuntimeSource(
        ScenarioRuntimeSourceEvent.triggerEnter(
          mapId: _activeMapId,
          triggerId: triggerId,
        ),
      );
    }
  }

  /// Point d'entrée unique pour les déclenchements runtime du Scenario Graph.
  ///
  /// Cette méthode centralise:
  /// - le guard de phase (overworld/script actif),
  /// - l'appel à l'exécuteur scénario,
  /// - le branchement vers les effets runtime (dialogue/script/message),
  /// - la synchronisation de GameState lorsque le flow mutera des flags.
  ScenarioRuntimeExecutionResult _dispatchScenarioRuntimeSource(
    ScenarioRuntimeSourceEvent sourceEvent,
  ) {
    if (_flowPhase != _RuntimeFlowPhase.overworld) {
      return const ScenarioRuntimeExecutionResult(
        status: ScenarioRuntimeExecutionStatus.noMatchingSource,
        effect: ScenarioRuntimeEffect.none(),
        message: 'Ignored: flow is not in overworld phase.',
      );
    }
    final activeScript = _activeScriptController;
    if (activeScript != null && !activeScript.isTerminated) {
      return const ScenarioRuntimeExecutionResult(
        status: ScenarioRuntimeExecutionStatus.noMatchingSource,
        effect: ScenarioRuntimeEffect.none(),
        message: 'Ignored: a script is already running.',
      );
    }
    final scenarios = _bundle.manifest.scenarios;
    if (scenarios.isEmpty) {
      return const ScenarioRuntimeExecutionResult(
        status: ScenarioRuntimeExecutionStatus.noMatchingSource,
        effect: ScenarioRuntimeEffect.none(),
        message: 'No scenario available in current manifest.',
      );
    }

    final result = _scenarioRuntime.dispatch(
      scenarios: scenarios,
      sourceEvent: sourceEvent,
      context: _buildScenarioRuntimeExecutionContext(),
    );

    // Step Studio : on ne complète pas sur "flow reached end" uniquement.
    // La completion est validée quand les effets runtime visibles sont terminés.
    _handleScenarioRuntimeCompletionResult(
      result,
      origin: 'dispatch:${sourceEvent.type.name}',
    );

    // On maintient une trace explicite en logs pour faciliter le debug.
    if (result.status == ScenarioRuntimeExecutionStatus.noMatchingSource) {
      return result;
    }
    debugPrint(
      '[scenario_runtime] source=${sourceEvent.type.name} map=${sourceEvent.mapId} trigger=${sourceEvent.triggerId ?? '-'} entity=${sourceEvent.entityId ?? '-'} status=${result.status.name} scenario=${result.scenarioId ?? '-'} sourceNode=${result.sourceNodeId ?? '-'} stopNode=${result.stopNodeId ?? '-'} message=${result.message}',
    );
    return result;
  }

  /// Contexte partagé dispatch / continuation : inclut le filtre Step Studio
  /// pour ne pas relancer une cutscene locale dont la step est déjà complétée.
  ScenarioRuntimeExecutionContext _buildScenarioRuntimeExecutionContext() {
    return ScenarioRuntimeExecutionContext(
      gameState: _gameState,
      onGameStateUpdated: (state) {
        _gameState = state;
        _refreshWorldNpcPresence();
      },
      shouldSkipScenario: _shouldSkipLocalScenarioForCompletedStep,
      openDialogue: _openScenarioDialogueById,
      runScript: _runScenarioScriptById,
      showMessage: (message) => _showNotification(message),
      moveCharacter: ({
        required entityId,
        required targetKind,
        required targetId,
        required waitForCompletion,
        runtimeSourceId,
      }) {
        return _runScenarioMoveCharacter(
          entityId: entityId,
          targetKind: targetKind,
          targetId: targetId,
          waitForCompletion: waitForCompletion,
          runtimeSourceId: runtimeSourceId,
        );
      },
      followCharacter: ({
        required leaderEntityId,
      }) {
        return _runScenarioFollowCharacter(leaderEntityId: leaderEntityId);
      },
      faceCharacter: ({
        required entityId,
        required direction,
      }) {
        return _runScenarioFaceCharacter(
          entityId: entityId,
          direction: direction,
        );
      },
      transitionMap: ({
        required mapId,
        required warpId,
      }) {
        return _runScenarioTransitionMap(
          mapId: mapId,
          warpId: warpId,
        );
      },
    );
  }

  /// Index Step Studio mis en cache tant que le bundle courant est inchangé
  /// (évite de re-parser le JSON à chaque déclencheur).
  StepCompletionCutsceneIndex _stepCompletionIndexForCurrentBundle() {
    if (!identical(_cachedStepCompletionBundleForIndex, _bundle)) {
      _cachedStepCompletionBundleForIndex = _bundle;
      _cachedStepCompletionIndex =
          buildStepCompletionCutsceneIndex(_bundle.manifest.scenarios);
    }
    return _cachedStepCompletionIndex!;
  }

  /// Si la cutscene [scenarioId] est la condition de fin d’une step déjà
  /// enregistrée dans [PlayerProgression.completedStepIds], on ignore ce
  /// scénario pour permettre à un autre candidat de matcher (ou aucun).
  bool _shouldSkipLocalScenarioForCompletedStep(String scenarioId) {
    final index = _stepCompletionIndexForCurrentBundle();
    final stepId = index.stepIdToCompleteWhenCutsceneEnds(scenarioId);
    if (stepId == null) {
      return false;
    }
    return _gameState.progression.completedStepIds.contains(stepId);
  }

  /// Capture un résultat scénario et décide si la completion doit être :
  /// - appliquée immédiatement;
  /// - ou différée jusqu'à la fin réelle des effets runtime visibles.
  void _handleScenarioRuntimeCompletionResult(
    ScenarioRuntimeExecutionResult result, {
    required String origin,
  }) {
    if (result.status != ScenarioRuntimeExecutionStatus.reachedEnd) {
      return;
    }
    final scenarioId = result.scenarioId?.trim();
    if (scenarioId == null || scenarioId.isEmpty) {
      return;
    }
    final blockingReason = _scenarioCompletionBlockingReason();
    if (blockingReason == null) {
      _applyScenarioReachedEndCompletion(
          scenarioId: scenarioId, origin: origin);
      return;
    }
    for (final pending in _pendingScenarioReachedEndQueue) {
      if (pending.scenarioId == scenarioId) {
        debugPrint(
          '[step_studio_trace] completion_deferred_duplicate scenario=$scenarioId origin=$origin reason="$blockingReason"',
        );
        return;
      }
    }
    _pendingScenarioReachedEndQueue.add(
      _PendingScenarioReachedEnd(
        scenarioId: scenarioId,
        origin: origin,
        queuedAtMs: _runtimeClockMs,
      ),
    );
    debugPrint(
      '[step_studio_trace] completion_deferred scenario=$scenarioId origin=$origin reason="$blockingReason"',
    );
  }

  /// Applique réellement la completion progression pour un scénario qui a
  /// atteint `end` ET dont la mise en scène runtime est terminée.
  void _applyScenarioReachedEndCompletion({
    required String scenarioId,
    required String origin,
  }) {
    var progression = _gameState.progression;
    var changed = false;

    final index = _stepCompletionIndexForCurrentBundle();
    final stepId = index.stepIdToCompleteWhenCutsceneEnds(scenarioId);
    if (stepId != null) {
      debugPrint(
        '[step_studio_trace] runtime_mark_step_completed_candidate scenario=$scenarioId step=$stepId before=${progression.completedStepIds}',
      );
      final nextSteps = appendCompletedStepIdIfAbsent(
        progression.completedStepIds,
        stepId,
      );
      if (!identical(nextSteps, progression.completedStepIds)) {
        progression = progression.copyWith(completedStepIds: nextSteps);
        changed = true;
        debugPrint(
          '[step_studio] step "$stepId" completed (cutscene "$scenarioId" reached end).',
        );
        debugPrint(
          '[step_studio_trace] runtime_completed_steps_updated scenario=$scenarioId step=$stepId after=${progression.completedStepIds}',
        );
      }
    }

    ScenarioAsset? scenarioAsset;
    for (final s in _bundle.manifest.scenarios) {
      if (s.id == scenarioId) {
        scenarioAsset = s;
        break;
      }
    }
    if (scenarioAsset != null &&
        scenarioAsset.scope == ScenarioScope.localEventFlow) {
      final nextCut = appendCompletedCutsceneIdIfAbsent(
        progression.completedCutsceneIds,
        scenarioId,
      );
      if (!identical(nextCut, progression.completedCutsceneIds)) {
        progression = progression.copyWith(completedCutsceneIds: nextCut);
        changed = true;
        debugPrint(
          '[runtime] local scenario "$scenarioId" marked completed (predicate cutsceneCompleted).',
        );
      }
    }

    if (changed) {
      _gameState = _gameState.copyWith(progression: progression);
      _refreshWorldNpcPresence();
    }
    debugPrint(
      '[step_studio_trace] completion_applied scenario=$scenarioId origin=$origin completedSteps=${_gameState.progression.completedStepIds} completedCutscenes=${_gameState.progression.completedCutsceneIds}',
    );
  }

  /// Retourne la raison bloquante empêchant de finaliser la cutscene.
  ///
  /// Tant qu'une raison existe, on ne matérialise pas les effects de progression
  /// (`completedStepIds`, `completedCutsceneIds`).
  String? _scenarioCompletionBlockingReason() {
    return scenarioRuntimeCompletionBlockingReason(
      isOverworldFlow: _flowPhase == _RuntimeFlowPhase.overworld,
      flowPhaseName: _flowPhase.name,
      isDialogueOpen: _dialogueOverlay != null,
      isCutsceneRunnerActive: isCutsceneRunning,
      hasPendingFollowCharacter: _pendingScenarioFollowRequest != null,
      hasPendingMoveContinuations:
          _pendingScenarioMoveContinuationsByEntity.isNotEmpty,
      hasPendingNpcWarpEntries: _pendingScenarioNpcWarpEntries.isNotEmpty,
      hasPendingTransitionMapRequest:
          _pendingScenarioTransitionMapRequest != null,
      hasPendingRuntimeWarp: _pendingWarp != null,
      hasPendingRuntimeConnection: _pendingConnection != null,
      isPlayerStepInProgress: _player.isStepping,
    );
  }

  /// Dès que les effets visibles sont terminés, on applique les complétions
  /// différées dans l'ordre d'arrivée.
  void _processPendingScenarioReachedEndCompletions() {
    if (_pendingScenarioReachedEndQueue.isEmpty) {
      _lastScenarioCompletionBlockReason = null;
      return;
    }
    final blockingReason = _scenarioCompletionBlockingReason();
    if (blockingReason != null) {
      if (_lastScenarioCompletionBlockReason != blockingReason) {
        debugPrint(
          '[step_studio_trace] completion_gate_blocked reason="$blockingReason" queue=${_pendingScenarioReachedEndQueue.length}',
        );
        _lastScenarioCompletionBlockReason = blockingReason;
      }
      return;
    }
    if (_lastScenarioCompletionBlockReason != null) {
      debugPrint(
        '[step_studio_trace] completion_gate_unblocked queue=${_pendingScenarioReachedEndQueue.length}',
      );
      _lastScenarioCompletionBlockReason = null;
    }
    final pendingItems =
        List<_PendingScenarioReachedEnd>.from(_pendingScenarioReachedEndQueue);
    _pendingScenarioReachedEndQueue.clear();
    for (final pending in pendingItems) {
      final waitMs = (_runtimeClockMs - pending.queuedAtMs).round();
      debugPrint(
        '[step_studio_trace] completion_deferred_flush scenario=${pending.scenarioId} waitedMs=$waitMs origin=${pending.origin}',
      );
      _applyScenarioReachedEndCompletion(
        scenarioId: pending.scenarioId,
        origin: 'deferred:${pending.origin}',
      );
    }
  }

  /// Ouvre un dialogue projet à partir d'un `dialogueId`.
  ///
  /// Callback utilisé par le bridge scénario.
  bool _openScenarioDialogueById(
    String dialogueId, {
    String? startNode,
    String? runtimeSourceId,
  }) {
    final normalizedDialogueId = dialogueId.trim();
    if (normalizedDialogueId.isEmpty) {
      return false;
    }
    final opened = _tryOpenDialogue(
      runtimeSourceId ?? 'scenario',
      DialogueRef(
        dialogueId: normalizedDialogueId,
        startNode: startNode,
      ),
      'Dialogue introuvable: $normalizedDialogueId',
    );
    if (opened && runtimeSourceId != null && runtimeSourceId.isNotEmpty) {
      _scheduleScenarioContinuationAfterDialogue(runtimeSourceId);
    }
    return opened;
  }

  void _scheduleScenarioContinuationAfterDialogue(String runtimeSourceId) {
    if (!runtimeSourceId.startsWith('scenario:')) {
      return;
    }
    final previous = _pendingPostDialogueAction;
    _pendingPostDialogueAction = () {
      previous?.call();
      _resumeScenarioAfterRuntimeSource(runtimeSourceId);
    };
  }

  void _resumeScenarioAfterRuntimeSource(String runtimeSourceId) {
    final parts = runtimeSourceId.split(':');
    if (parts.length != 4) {
      return;
    }
    final scenarioId = parts[1].trim();
    final sourceNodeId = parts[2].trim();
    final resumeAfterNodeId = parts[3].trim();
    if (scenarioId.isEmpty ||
        sourceNodeId.isEmpty ||
        resumeAfterNodeId.isEmpty) {
      return;
    }
    final result = _scenarioRuntime.dispatchContinuation(
      scenarios: _bundle.manifest.scenarios,
      scenarioId: scenarioId,
      sourceNodeId: sourceNodeId,
      resumeAfterNodeId: resumeAfterNodeId,
      context: _buildScenarioRuntimeExecutionContext(),
    );
    _handleScenarioRuntimeCompletionResult(
      result,
      origin: 'continuation:$runtimeSourceId',
    );
    debugPrint(
      '[scenario_runtime] continuation source=$runtimeSourceId status=${result.status.name} scenario=${result.scenarioId ?? '-'} stopNode=${result.stopNodeId ?? '-'} message=${result.message}',
    );
  }

  bool _runScenarioMoveCharacter({
    required String entityId,
    required String targetKind,
    required String targetId,
    required bool waitForCompletion,
    String? runtimeSourceId,
  }) {
    final trimmedEntity = entityId.trim();
    if (trimmedEntity == 'player') {
      _scriptedEntityMovementController?.syncTrackedEntityPosition(
        trimmedEntity,
        _world.player.pos,
      );
    }
    final destination = _resolveScenarioMoveTarget(
      targetKind: targetKind,
      targetId: targetId,
    );
    if (destination == null) {
      debugPrint(
        '[scenario_runtime] moveCharacter target unresolved kind=$targetKind targetId=$targetId',
      );
      return false;
    }
    var resolvedDestination = destination;
    var entityApproachCandidates = const <GridPos>[];
    if (targetKind == 'entity') {
      entityApproachCandidates = _resolveScenarioEntityApproachCandidates(
        moverEntityId: entityId,
        targetEntityId: targetId,
        primaryDestination: destination,
      );
      if (entityApproachCandidates.isEmpty) {
        debugPrint(
          '[scenario_runtime] moveCharacter entity target has no reachable adjacent cell entity=$entityId target=$targetId',
        );
        return false;
      }
      resolvedDestination = entityApproachCandidates.first;
    }
    var started = startScriptedNpcMove(
      entityId: entityId,
      destination: resolvedDestination,
    );
    if (started.state == ScriptedEntityMovementState.failed &&
        targetKind == 'warp') {
      final warp = _findMapWarpById(targetId);
      if (warp != null) {
        final fallbackCandidates = _resolveScenarioWarpApproachCandidates(
          entityId: entityId,
          warp: warp,
          primaryDestination: destination,
        );
        for (final candidate in fallbackCandidates) {
          final fallbackStarted = startScriptedNpcMove(
            entityId: entityId,
            destination: candidate,
          );
          if (fallbackStarted.state != ScriptedEntityMovementState.failed) {
            resolvedDestination = candidate;
            started = fallbackStarted;
            debugPrint(
              '[scenario_runtime] moveCharacter warp fallback entity=$entityId warp=${warp.id} destination=(${candidate.x},${candidate.y})',
            );
            break;
          }
        }
      }
    }
    if (started.state == ScriptedEntityMovementState.failed &&
        targetKind == 'entity') {
      final fallbackCandidates = entityApproachCandidates.isNotEmpty
          ? entityApproachCandidates.skip(1)
          : _resolveScenarioEntityApproachCandidates(
              moverEntityId: entityId,
              targetEntityId: targetId,
              primaryDestination: destination,
            );
      for (final candidate in fallbackCandidates) {
        final fallbackStarted = startScriptedNpcMove(
          entityId: entityId,
          destination: candidate,
        );
        if (fallbackStarted.state != ScriptedEntityMovementState.failed) {
          resolvedDestination = candidate;
          started = fallbackStarted;
          debugPrint(
            '[scenario_runtime] moveCharacter entity fallback entity=$entityId target=$targetId destination=(${candidate.x},${candidate.y})',
          );
          break;
        }
      }
    }
    if (started.state == ScriptedEntityMovementState.failed) {
      debugPrint(
        '[scenario_runtime] moveCharacter failed entity=$entityId destination=(${resolvedDestination.x},${resolvedDestination.y})',
      );
      return false;
    }
    if (targetKind == 'warp') {
      final warp = _findMapWarpById(targetId);
      if (warp != null) {
        _pendingScenarioNpcWarpEntries[entityId] = _PendingScenarioNpcWarpEntry(
          entityId: entityId,
          warpId: warp.id,
          warpPos: warp.pos,
          approachPos: resolvedDestination,
        );
      }
    } else {
      _pendingScenarioNpcWarpEntries.remove(entityId);
    }
    if (waitForCompletion) {
      final runtimeSource = runtimeSourceId?.trim() ?? '';
      if (runtimeSource.startsWith('scenario:') && trimmedEntity.isNotEmpty) {
        _pendingScenarioMoveContinuationsByEntity[trimmedEntity] =
            _PendingScenarioMoveContinuation(
          entityId: trimmedEntity,
          runtimeSourceId: runtimeSource,
          targetKind: targetKind,
        );
      }
      debugPrint(
        '[scenario_runtime] moveCharacter started entity=$entityId destination=(${resolvedDestination.x},${resolvedDestination.y}) waitForCompletion=true',
      );
    } else {
      _pendingScenarioMoveContinuationsByEntity.remove(trimmedEntity);
    }
    return true;
  }

  bool _runScenarioTransitionMap({
    required String mapId,
    required String warpId,
  }) {
    final normalizedMapId = mapId.trim();
    final normalizedWarpId = warpId.trim();
    if (normalizedMapId.isEmpty || normalizedWarpId.isEmpty) {
      debugPrint(
        '[scenario_runtime] transitionMap invalid mapId="$mapId" warpId="$warpId"',
      );
      return false;
    }
    _pendingScenarioTransitionMapRequest = _PendingScenarioTransitionMapRequest(
      mapId: normalizedMapId,
      warpId: normalizedWarpId,
    );
    debugPrint(
      '[scenario_runtime] transitionMap scheduled map=$normalizedMapId warp=$normalizedWarpId',
    );
    return true;
  }

  void _processPendingScenarioTransitionMapRequest() {
    final pending = _pendingScenarioTransitionMapRequest;
    if (pending == null) {
      return;
    }

    // On attend la fin du suivi (followCharacter) pour ne pas couper la scène.
    if (_pendingScenarioFollowRequest != null) {
      return;
    }
    if (_player.isStepping) {
      return;
    }

    _pendingScenarioTransitionMapRequest = null;
    unawaited(_executeScenarioTransitionMapRequest(pending));
  }

  Future<void> _executeScenarioTransitionMapRequest(
    _PendingScenarioTransitionMapRequest request,
  ) async {
    if (_flowPhase != _RuntimeFlowPhase.overworld) {
      debugPrint(
        '[scenario_runtime] transitionMap ignored: flow=${_flowPhase.name}',
      );
      return;
    }
    try {
      final loadedBundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: request.mapId,
      );
      final targetBundle = _resolveRuntimeBundle(loadedBundle);
      MapWarp? targetWarp;
      for (final candidate in targetBundle.map.warps) {
        if (candidate.id == request.warpId) {
          targetWarp = candidate;
          break;
        }
      }
      if (targetWarp == null) {
        debugPrint(
          '[scenario_runtime] transitionMap failed: warp "${request.warpId}" not found on map "${request.mapId}"',
        );
        _showNotification('Transition impossible (warp introuvable)');
        return;
      }

      final transition = TriggeredWarp(
        warpId: 'scenario:${request.warpId}',
        targetMapId: targetBundle.map.id,
        targetPos: targetWarp.pos,
        triggerMode: MapWarpTriggerMode.onEnter,
      );
      debugPrint(
        '[scenario_runtime] transitionMap start map=${transition.targetMapId} warp=${request.warpId} pos=(${transition.targetPos.x},${transition.targetPos.y})',
      );
      await _handleWarp(transition);
    } catch (e, st) {
      debugPrint(
        '[scenario_runtime] transitionMap failed map=${request.mapId} warp=${request.warpId}: $e\n$st',
      );
      _showNotification('Transition impossible');
    }
  }

  MapWarp? _findMapWarpById(String warpId) {
    final normalized = warpId.trim();
    if (normalized.isEmpty) {
      return null;
    }
    for (final warp in _world.map.warps) {
      if (warp.id == normalized) {
        return warp;
      }
    }
    return null;
  }

  List<GridPos> _resolveScenarioWarpApproachCandidates({
    required String entityId,
    required MapWarp warp,
    required GridPos primaryDestination,
  }) {
    final currentPos = _resolveScenarioEntityPosition(entityId) ?? warp.pos;
    final candidates = <GridPos>[];
    final seen = <GridPos>{primaryDestination};

    // Anneaux autour du warp: on essaie de rester proche de la porte tout en
    // respectant le footprint collision réel du PNJ (souvent 2x2).
    const maxRadius = 4;
    for (var radius = 1; radius <= maxRadius; radius++) {
      for (var dx = -radius; dx <= radius; dx++) {
        final top = GridPos(x: warp.pos.x + dx, y: warp.pos.y - radius);
        if (_addWarpApproachCandidate(
          seen: seen,
          out: candidates,
          candidate: top,
          entityId: entityId,
        )) {
          // no-op
        }
        final bottom = GridPos(x: warp.pos.x + dx, y: warp.pos.y + radius);
        _addWarpApproachCandidate(
          seen: seen,
          out: candidates,
          candidate: bottom,
          entityId: entityId,
        );
      }
      for (var dy = -radius + 1; dy <= radius - 1; dy++) {
        final left = GridPos(x: warp.pos.x - radius, y: warp.pos.y + dy);
        _addWarpApproachCandidate(
          seen: seen,
          out: candidates,
          candidate: left,
          entityId: entityId,
        );
        final right = GridPos(x: warp.pos.x + radius, y: warp.pos.y + dy);
        _addWarpApproachCandidate(
          seen: seen,
          out: candidates,
          candidate: right,
          entityId: entityId,
        );
      }
    }

    candidates.sort((a, b) {
      final aDoor = (a.x - warp.pos.x).abs() + (a.y - warp.pos.y).abs();
      final bDoor = (b.x - warp.pos.x).abs() + (b.y - warp.pos.y).abs();
      if (aDoor != bDoor) {
        return aDoor.compareTo(bDoor);
      }
      final aCurrent = (a.x - currentPos.x).abs() + (a.y - currentPos.y).abs();
      final bCurrent = (b.x - currentPos.x).abs() + (b.y - currentPos.y).abs();
      return aCurrent.compareTo(bCurrent);
    });
    return candidates;
  }

  List<GridPos> _resolveScenarioEntityApproachCandidates({
    required String moverEntityId,
    required String targetEntityId,
    required GridPos primaryDestination,
  }) {
    final currentPos =
        _resolveScenarioEntityPosition(moverEntityId) ?? primaryDestination;

    MapRect targetRect;
    if (targetEntityId == 'player') {
      targetRect = MapRect(
        pos: _world.player.pos,
        size: const GridSize(width: 1, height: 1),
      );
    } else {
      MapEntity? targetEntity;
      for (final entry in _world.map.entities) {
        if (entry.id == targetEntityId) {
          targetEntity = entry;
          break;
        }
      }
      if (targetEntity == null) {
        return const <GridPos>[];
      }
      targetRect = resolveEntityCollisionFootprint(targetEntity);
    }

    final candidates = <GridPos>[];
    final seen = <GridPos>{primaryDestination};
    for (final cell in _adjacentCellsAroundRect(targetRect)) {
      if (!seen.add(cell)) {
        continue;
      }
      if (!_isWithinMapBounds(_world.map, cell)) {
        continue;
      }
      if (!_isScenarioNpcAnchorPassable(
          entityId: moverEntityId, anchor: cell)) {
        continue;
      }
      candidates.add(cell);
    }

    candidates.sort((a, b) {
      final aCurrent = (a.x - currentPos.x).abs() + (a.y - currentPos.y).abs();
      final bCurrent = (b.x - currentPos.x).abs() + (b.y - currentPos.y).abs();
      if (aCurrent != bCurrent) {
        return aCurrent.compareTo(bCurrent);
      }
      final aTarget =
          (a.x - targetRect.pos.x).abs() + (a.y - targetRect.pos.y).abs();
      final bTarget =
          (b.x - targetRect.pos.x).abs() + (b.y - targetRect.pos.y).abs();
      return aTarget.compareTo(bTarget);
    });
    return candidates;
  }

  bool _addWarpApproachCandidate({
    required Set<GridPos> seen,
    required List<GridPos> out,
    required GridPos candidate,
    required String entityId,
  }) {
    if (!seen.add(candidate)) {
      return false;
    }
    if (!_isWithinMapBounds(_world.map, candidate)) {
      return false;
    }
    if (!_isScenarioNpcAnchorPassable(entityId: entityId, anchor: candidate)) {
      return false;
    }
    out.add(candidate);
    return true;
  }

  bool _isScenarioNpcAnchorPassable({
    required String entityId,
    required GridPos anchor,
  }) {
    if (entityId.trim() == 'player') {
      return _isPlayerScriptedMoveAnchorPassable(anchor);
    }
    final probe = evaluateScriptedNpcAnchorPassability(
      world: _world,
      entityId: entityId,
      anchorPos: anchor,
      movementMode: MovementMode.walk,
      dynamicBlockedCells: _scriptedNpcDynamicBlockedCells(
        ignoreEntityId: entityId,
      ),
    );
    return probe.passable;
  }

  bool _isPlayerScriptedMoveAnchorPassable(GridPos anchor) {
    final mode = _world.player.movementMode;
    if (_world.movementBlockReasonAt(
          x: anchor.x,
          y: anchor.y,
          movementMode: mode,
        ) !=
        null) {
      return false;
    }
    for (final cell
        in _scriptedNpcDynamicBlockedCells(ignoreEntityId: 'player')) {
      if (cell.x == anchor.x && cell.y == anchor.y) {
        return false;
      }
    }
    return true;
  }

  GridPos? _resolveScenarioEntityPosition(String entityId) {
    if (entityId == 'player') {
      return _world.player.pos;
    }
    final runtimePos = _runtimeNpcPositions[entityId];
    if (runtimePos != null) {
      return runtimePos;
    }
    for (final entity in _world.map.entities) {
      if (entity.id == entityId) {
        return entity.pos;
      }
    }
    return null;
  }

  GridPos? _resolveScenarioMoveTarget({
    required String targetKind,
    required String targetId,
  }) {
    final map = _world.map;
    switch (targetKind) {
      case 'warp':
        for (final warp in map.warps) {
          if (warp.id == targetId) {
            return warp.pos;
          }
        }
        return null;
      case 'spawn':
        for (final entity in map.entities) {
          if (entity.kind == MapEntityKind.spawn && entity.id == targetId) {
            return entity.pos;
          }
        }
        return null;
      case 'entity':
        if (targetId == 'player') {
          return _world.player.pos;
        }
        for (final entity in map.entities) {
          if (entity.id == targetId) {
            return entity.pos;
          }
        }
        return null;
      default:
        return null;
    }
  }

  bool _suppressOverworldInputForScriptedPlayerMovement() {
    final status = scriptedNpcMovementStatus('player');
    return status.state == ScriptedEntityMovementState.moving;
  }

  void _clearPressedMovementKeys() {
    _pressedKeys.removeWhere(_isMovementKey);
    if (_lastMoveKey != null && !_pressedKeys.contains(_lastMoveKey!)) {
      _lastMoveKey = null;
    }
  }

  void _processPendingScenarioNpcWarpEntries() {
    if (_pendingScenarioNpcWarpEntries.isEmpty) {
      return;
    }
    final entityIds =
        _pendingScenarioNpcWarpEntries.keys.toList(growable: false)..sort();
    for (final entityId in entityIds) {
      final pending = _pendingScenarioNpcWarpEntries[entityId];
      if (pending == null) {
        continue;
      }
      final status = scriptedNpcMovementStatus(entityId);
      if (status.state == ScriptedEntityMovementState.moving) {
        continue;
      }
      if (status.state == ScriptedEntityMovementState.failed) {
        debugPrint(
          '[scenario_runtime] npc warp canceled entity=$entityId warp=${pending.warpId} reason="${status.failureReason ?? 'move failed'}"',
        );
        _pendingScenarioNpcWarpEntries.remove(entityId);
        continue;
      }
      if (status.state != ScriptedEntityMovementState.completed) {
        final stillPresent = _resolveScenarioEntityPosition(entityId) != null;
        if (!stillPresent) {
          _pendingScenarioNpcWarpEntries.remove(entityId);
        }
        continue;
      }
      _pendingScenarioNpcWarpEntries.remove(entityId);
      _completeScenarioNpcWarpEntry(pending);
    }
  }

  void _processPendingScenarioMoveContinuations() {
    if (_pendingScenarioMoveContinuationsByEntity.isEmpty) {
      return;
    }
    final entityIds = _pendingScenarioMoveContinuationsByEntity.keys
        .toList(growable: false)
      ..sort();
    for (final entityId in entityIds) {
      final pending = _pendingScenarioMoveContinuationsByEntity[entityId];
      if (pending == null) {
        continue;
      }

      if (pending.targetKind == 'warp' && _pendingWarp != null) {
        // Le déplacement est "fini" uniquement après consommation effective du
        // warp joueur et retour en overworld.
        continue;
      }

      final status = scriptedNpcMovementStatus(entityId);
      if (status.state == ScriptedEntityMovementState.moving) {
        continue;
      }
      if (status.state == ScriptedEntityMovementState.failed) {
        _pendingScenarioMoveContinuationsByEntity.remove(entityId);
        continue;
      }
      if (status.state == ScriptedEntityMovementState.completed ||
          status.state == ScriptedEntityMovementState.idle) {
        _pendingScenarioMoveContinuationsByEntity.remove(entityId);
        _resumeScenarioAfterRuntimeSource(pending.runtimeSourceId);
      }
    }
  }

  void _completeScenarioNpcWarpEntry(_PendingScenarioNpcWarpEntry pending) {
    if (pending.entityId.trim() == 'player') {
      _completeScenarioPlayerWarpEntry(pending);
      return;
    }
    final removed = _despawnNpcFromActiveMap(pending.entityId);
    if (!removed) {
      debugPrint(
        '[scenario_runtime] npc warp failed to remove entity=${pending.entityId} warp=${pending.warpId}',
      );
      return;
    }
    debugPrint(
      '[scenario_runtime] npc entered warp entity=${pending.entityId} warp=${pending.warpId} approach=(${pending.approachPos.x},${pending.approachPos.y})',
    );
  }

  void _completeScenarioPlayerWarpEntry(_PendingScenarioNpcWarpEntry pending) {
    final warp = _findMapWarpById(pending.warpId);
    if (warp == null) {
      debugPrint(
        '[scenario_runtime] player warp failed: warp "${pending.warpId}" not found on map "${_bundle.map.id}"',
      );
      return;
    }
    _pendingWarp = TriggeredWarp(
      warpId: warp.id,
      targetMapId: warp.targetMapId,
      targetPos: warp.targetPos,
      triggerMode: warp.triggerMode,
    );
    debugPrint(
      '[scenario_runtime] player reached warp=${warp.id} -> map=${warp.targetMapId} target=(${warp.targetPos.x},${warp.targetPos.y})',
    );
  }

  bool _despawnNpcFromActiveMap(String entityId) {
    final normalized = entityId.trim();
    if (normalized.isEmpty) {
      return false;
    }
    final entities = _world.map.entities;
    final index = entities.indexWhere((entity) => entity.id == normalized);
    if (index < 0) {
      return false;
    }

    final updatedEntities = List<MapEntity>.from(entities)..removeAt(index);
    final updatedMap = _world.map.copyWith(entities: updatedEntities);
    final playerState = _world.player;
    _world = GameplayWorldState.initial(
      map: updatedMap,
      playerPos: playerState.pos,
      playerFacing: playerState.facing,
      playerMovementMode: playerState.movementMode,
      project: _bundle.manifest,
      tileWidth: _bundle.manifest.settings.tileWidth,
      tileHeight: _bundle.manifest.settings.tileHeight,
      npcMapPresencePredicate: _npcPresencePredicateFor(_bundle.manifest),
    );
    _bundle = RuntimeMapBundle(
      manifest: _bundle.manifest,
      map: updatedMap,
      projectRootDirectory: _bundle.projectRootDirectory,
      tilesetAbsolutePathsById: _bundle.tilesetAbsolutePathsById,
    );

    final loaded = _loadedMapsById[_activeMapId];
    if (loaded != null) {
      _purgeMountedNpcActorForEntity(entityId: normalized, loaded: loaded);
    }

    _scriptedNpcReservedOccupiedCellsByEntity.remove(normalized);
    _runtimeNpcPositions.remove(normalized);
    _triggeredTrainerBattles.remove(normalized);
    if (_pendingScenarioFollowRequest?.leaderEntityId == normalized) {
      _pendingScenarioFollowRequest = null;
    }
    _pendingScenarioNpcWarpEntries.remove(normalized);
    _pendingScenarioMoveContinuationsByEntity.remove(normalized);
    _scriptedEntityMovementController?.untrackEntity(normalized);
    _syncGameStateFromWorld();
    return true;
  }

  bool _runScenarioFollowCharacter({
    required String leaderEntityId,
  }) {
    _pendingScenarioFollowRequest = _PendingScenarioFollowRequest(
      leaderEntityId: leaderEntityId,
      requestedAtMs: _runtimeClockMs,
    );
    debugPrint(
      '[scenario_runtime] followCharacter activated leader=$leaderEntityId',
    );
    // On traite la première itération immédiatement pour éviter un frame de latence.
    _processPendingScenarioFollowRequest();
    return true;
  }

  void _processPendingScenarioFollowRequest() {
    final pending = _pendingScenarioFollowRequest;
    if (pending == null) {
      return;
    }
    final leaderPos = _resolveScenarioLeaderPosition(pending.leaderEntityId);
    if (leaderPos == null) {
      debugPrint(
        '[scenario_runtime] followCharacter canceled leader unresolved=${pending.leaderEntityId}',
      );
      _pendingScenarioFollowRequest = null;
      return;
    }
    final leaderRect = _resolveScenarioLeaderCollisionFootprint(
      leaderEntityId: pending.leaderEntityId,
      fallbackAnchor: leaderPos,
    );
    final leaderMovement = scriptedNpcMovementStatus(pending.leaderEntityId);
    final leaderTravelDirection = _resolveLeaderTravelDirection(
      pending: pending,
      leaderPos: leaderPos,
      movementStatus: leaderMovement,
    );
    final preferredTrailingSide = leaderTravelDirection == null
        ? null
        : _oppositeDirection(leaderTravelDirection);
    final playerPos = _world.player.pos;
    final playerAdjacentToLeader = _isPosAdjacentToRect(playerPos, leaderRect);

    // Condition de fin:
    // - leader immobile
    // - joueur déjà adjacent au footprint réel du leader.
    if (leaderMovement.state != ScriptedEntityMovementState.moving &&
        playerAdjacentToLeader) {
      debugPrint(
        '[scenario_runtime] followCharacter completed leader=${pending.leaderEntityId} player=(${playerPos.x},${playerPos.y})',
      );
      _pendingScenarioFollowRequest = null;
      return;
    }

    // Si le joueur est déjà en interpolation, on attend le prochain tick.
    if (_player.isStepping) {
      return;
    }

    final canReuseCachedPath = pending.cachedPath != null &&
        pending.cachedPathDestination != null &&
        pending.cachedPathLeaderPos != null &&
        pending.cachedPathLeaderPos!.x == leaderPos.x &&
        pending.cachedPathLeaderPos!.y == leaderPos.y;
    if (canReuseCachedPath) {
      final nextPos = _nextFollowPathStep(
        path: pending.cachedPath!,
        currentPos: playerPos,
      );
      if (nextPos != null) {
        final stepped = _stepPlayerAlongFollowPath(
          leaderEntityId: pending.leaderEntityId,
          leaderPos: leaderPos,
          destination: pending.cachedPathDestination!,
          nextPos: nextPos,
          preferredTrailingSide: preferredTrailingSide,
        );
        if (stepped) {
          pending.consecutiveBlockedSteps = 0;
          return;
        }
        pending.consecutiveBlockedSteps += 1;
        _clearPendingFollowPathCache(pending);
        if (leaderMovement.state != ScriptedEntityMovementState.moving &&
            pending.consecutiveBlockedSteps >= 10) {
          debugPrint(
            '[scenario_runtime] followCharacter canceled repeated blocked steps leader=${pending.leaderEntityId}',
          );
          _pendingScenarioFollowRequest = null;
        }
        return;
      }
      _clearPendingFollowPathCache(pending);
    }

    final followPlan = _resolveFollowPathPlanNearLeader(
      leaderEntityId: pending.leaderEntityId,
      leaderPos: leaderPos,
      preferredSide: preferredTrailingSide,
      strictPreferredSide:
          leaderMovement.state == ScriptedEntityMovementState.moving,
    );
    if (followPlan == null) {
      if (leaderMovement.state != ScriptedEntityMovementState.moving) {
        pending.consecutiveBlockedSteps += 1;
        if (pending.consecutiveBlockedSteps >= 10) {
          debugPrint(
            '[scenario_runtime] followCharacter canceled no reachable trailing path leader=${pending.leaderEntityId}',
          );
          _pendingScenarioFollowRequest = null;
        }
      }
      return;
    }
    pending.consecutiveBlockedSteps = 0;

    // Si on est déjà au meilleur point, on attend la prochaine évolution leader.
    if (followPlan.path.length <= 1 ||
        (followPlan.destination.x == playerPos.x &&
            followPlan.destination.y == playerPos.y)) {
      _clearPendingFollowPathCache(pending);
      return;
    }

    pending.cachedPath = followPlan.path;
    pending.cachedPathDestination = followPlan.destination;
    pending.cachedPathLeaderPos = leaderPos;
    final nextPos = _nextFollowPathStep(
      path: followPlan.path,
      currentPos: playerPos,
    );
    if (nextPos == null) {
      _clearPendingFollowPathCache(pending);
      return;
    }

    final stepped = _stepPlayerAlongFollowPath(
      leaderEntityId: pending.leaderEntityId,
      leaderPos: leaderPos,
      destination: followPlan.destination,
      nextPos: nextPos,
      preferredTrailingSide: preferredTrailingSide,
    );
    if (!stepped) {
      pending.consecutiveBlockedSteps += 1;
      _clearPendingFollowPathCache(pending);
      if (leaderMovement.state != ScriptedEntityMovementState.moving &&
          pending.consecutiveBlockedSteps >= 10) {
        debugPrint(
          '[scenario_runtime] followCharacter canceled repeated blocked steps leader=${pending.leaderEntityId}',
        );
        _pendingScenarioFollowRequest = null;
      }
    }
  }

  bool _stepPlayerAlongFollowPath({
    required String leaderEntityId,
    required GridPos leaderPos,
    required GridPos destination,
    required GridPos nextPos,
    required Direction? preferredTrailingSide,
  }) {
    final currentPos = _world.player.pos;
    final direction = _directionBetweenAdjacent(
      from: currentPos,
      to: nextPos,
    );
    if (direction == null) {
      debugPrint(
        '[scenario_runtime] followCharacter invalid non-adjacent path step leader=$leaderEntityId from=(${currentPos.x},${currentPos.y}) to=(${nextPos.x},${nextPos.y})',
      );
      return false;
    }

    final result = stepGameplayWorld(_world, MoveIntent(direction));
    if (result is! Moved) {
      debugPrint(
        '[scenario_runtime] followCharacter path step blocked leader=$leaderEntityId from=(${currentPos.x},${currentPos.y}) to=(${nextPos.x},${nextPos.y})',
      );
      return false;
    }
    _world = result.world;
    _syncGameStateFromWorld();
    _consumePathAnimationSignals(result.pathAnimationSignals);
    _player.startStep(
      _world.player,
      durationSeconds: PlayerComponent.kDefaultStepSeconds,
    );
    _dispatchScenarioTriggerEnterFromMovement(
      previousPos: currentPos,
      currentPos: _world.player.pos,
    );
    debugPrint(
      '[scenario_runtime] followCharacter stepping leader=$leaderEntityId leaderPos=(${leaderPos.x},${leaderPos.y}) trailingSide=${preferredTrailingSide?.name ?? '-'} destination=(${destination.x},${destination.y}) next=(${nextPos.x},${nextPos.y}) playerPos=(${_world.player.pos.x},${_world.player.pos.y})',
    );
    return true;
  }

  bool _runScenarioFaceCharacter({
    required String entityId,
    required String direction,
  }) {
    final facing = _parseEntityFacing(direction);
    if (facing == null) {
      debugPrint(
        '[scenario_runtime] faceCharacter invalid direction="$direction"',
      );
      return false;
    }
    if (entityId == 'player') {
      final next =
          _world.player.copyWith(facing: _directionFromEntityFacing(facing));
      _world = _world.withPlayer(next);
      _syncGameStateFromWorld();
      _player.syncState(_world.player, snapToGrid: true);
      return true;
    }
    final normalizedEntityId = entityId.trim();
    final active = _loadedMapsById[_activeMapId];
    final actor = active?.npcActorByEntityId[normalizedEntityId];
    if (actor != null) {
      final movement = scriptedNpcMovementStatus(normalizedEntityId);
      if (movement.state == ScriptedEntityMovementState.moving ||
          actor.isStepping) {
        debugPrint(
          '[scenario_runtime] faceCharacter deferred entity=$normalizedEntityId while moving',
        );
        return true;
      }
      actor.setMotion(facing, CharacterAnimationState.idle);
      return true;
    }

    // Tolérance runtime: si l’entité n’a pas d’acteur visuel actuellement
    // monté (ex: map context différente), on tente au moins de persister
    // l’orientation dans l’état map; sinon on ignore sans bloquer le flow.
    if (_setEntityFacingStateOnly(normalizedEntityId, facing)) {
      debugPrint(
        '[scenario_runtime] faceCharacter applied state-only entity="$normalizedEntityId"',
      );
      return true;
    }
    debugPrint(
      '[scenario_runtime] faceCharacter entity unresolved="$normalizedEntityId" (ignored)',
    );
    return true;
  }

  bool _setEntityFacingStateOnly(String entityId, EntityFacing facing) {
    if (entityId.isEmpty) {
      return false;
    }
    final entities = _world.map.entities;
    final index = entities.indexWhere((entity) => entity.id == entityId);
    if (index < 0) {
      return false;
    }
    final entity = entities[index];
    final npc = entity.npc;
    if (npc == null) {
      return false;
    }
    final updatedEntities = List<MapEntity>.from(entities);
    updatedEntities[index] = entity.copyWith(
      npc: npc.copyWith(facing: facing),
    );
    final updatedMap = _world.map.copyWith(entities: updatedEntities);
    final playerState = _world.player;
    _world = GameplayWorldState.initial(
      map: updatedMap,
      playerPos: playerState.pos,
      playerFacing: playerState.facing,
      playerMovementMode: playerState.movementMode,
      project: _bundle.manifest,
      tileWidth: _bundle.manifest.settings.tileWidth,
      tileHeight: _bundle.manifest.settings.tileHeight,
      npcMapPresencePredicate: _npcPresencePredicateFor(_bundle.manifest),
    );
    _bundle = RuntimeMapBundle(
      manifest: _bundle.manifest,
      map: updatedMap,
      projectRootDirectory: _bundle.projectRootDirectory,
      tilesetAbsolutePathsById: _bundle.tilesetAbsolutePathsById,
    );
    _syncGameStateFromWorld();
    return true;
  }

  EntityFacing? _parseEntityFacing(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'north':
        return EntityFacing.north;
      case 'south':
        return EntityFacing.south;
      case 'east':
        return EntityFacing.east;
      case 'west':
        return EntityFacing.west;
      default:
        return null;
    }
  }

  Direction _directionFromEntityFacing(EntityFacing facing) {
    switch (facing) {
      case EntityFacing.north:
        return Direction.north;
      case EntityFacing.south:
        return Direction.south;
      case EntityFacing.east:
        return Direction.east;
      case EntityFacing.west:
        return Direction.west;
    }
  }

  GridPos? _resolveScenarioLeaderPosition(String leaderEntityId) {
    final movementStatus = scriptedNpcMovementStatus(leaderEntityId);
    if (movementStatus.entityId == leaderEntityId) {
      return movementStatus.currentPos;
    }
    final active = _loadedMapsById[_activeMapId];
    final actor = active?.npcActorByEntityId[leaderEntityId];
    final actorGridPos = actor?.gridPos;
    if (actorGridPos != null) {
      return actorGridPos;
    }
    for (final entity in _world.map.entities) {
      if (entity.id == leaderEntityId) {
        return entity.pos;
      }
    }
    return null;
  }

  _FollowPathPlan? _resolveFollowPathPlanNearLeader({
    required String leaderEntityId,
    required GridPos leaderPos,
    required Direction? preferredSide,
    required bool strictPreferredSide,
  }) {
    final currentPlayerPos = _world.player.pos;
    final leaderRect = _resolveScenarioLeaderCollisionFootprint(
      leaderEntityId: leaderEntityId,
      fallbackAnchor: leaderPos,
    );
    final candidates = <GridPos>[];
    final preferredCandidates = <GridPos>{};
    if (preferredSide != null) {
      final trailing = _cellsAlongRectSide(leaderRect, preferredSide).toList();
      candidates.addAll(trailing);
      preferredCandidates.addAll(trailing);
    }
    if (!strictPreferredSide) {
      candidates.addAll(_adjacentCellsAroundRect(leaderRect));
    }
    final deduplicated = candidates.toSet().toList(growable: false);
    deduplicated.sort((a, b) {
      final aPreferred = preferredCandidates.contains(a) ? 0 : 1;
      final bPreferred = preferredCandidates.contains(b) ? 0 : 1;
      if (aPreferred != bPreferred) {
        return aPreferred.compareTo(bPreferred);
      }
      final da =
          (a.x - currentPlayerPos.x).abs() + (a.y - currentPlayerPos.y).abs();
      final db =
          (b.x - currentPlayerPos.x).abs() + (b.y - currentPlayerPos.y).abs();
      return da.compareTo(db);
    });
    for (final candidate in deduplicated) {
      if (!_canPlacePlayerAt(candidate)) {
        continue;
      }
      final path = _computeFollowPlayerPath(
        start: currentPlayerPos,
        goal: candidate,
      );
      if (path == null) {
        continue;
      }
      return _FollowPathPlan(
        destination: candidate,
        path: path,
      );
    }

    // Si la cible "derrière" est impossible en déplacement, on autorise un
    // fallback adjacent pour éviter les blocages durs dans les couloirs.
    if (strictPreferredSide) {
      final relaxedCandidates =
          _adjacentCellsAroundRect(leaderRect).toSet().toList(growable: false);
      relaxedCandidates.sort((a, b) {
        final da =
            (a.x - currentPlayerPos.x).abs() + (a.y - currentPlayerPos.y).abs();
        final db =
            (b.x - currentPlayerPos.x).abs() + (b.y - currentPlayerPos.y).abs();
        return da.compareTo(db);
      });
      for (final candidate in relaxedCandidates) {
        if (!_canPlacePlayerAt(candidate)) {
          continue;
        }
        final path = _computeFollowPlayerPath(
          start: currentPlayerPos,
          goal: candidate,
        );
        if (path == null) {
          continue;
        }
        return _FollowPathPlan(
          destination: candidate,
          path: path,
        );
      }
    }

    if (_isPosAdjacentToRect(currentPlayerPos, leaderRect) &&
        _canPlacePlayerAt(currentPlayerPos)) {
      return _FollowPathPlan(
        destination: currentPlayerPos,
        path: <GridPos>[currentPlayerPos],
      );
    }
    return null;
  }

  List<GridPos>? _computeFollowPlayerPath({
    required GridPos start,
    required GridPos goal,
  }) {
    final result = _followPathfinder.findPath(
      bounds: _world.map.size,
      start: start,
      goal: goal,
      isPassable: (x, y) {
        if (x == start.x && y == start.y) {
          return true;
        }
        final cell = GridPos(x: x, y: y);
        if (!_isWithinMapBounds(_world.map, cell)) {
          return false;
        }
        if (_isCellReservedByScriptedNpc(cell)) {
          return false;
        }
        final trial = _world.withPlayer(_world.player.copyWith(pos: cell));
        return !trial.isBlocked(x, y);
      },
    );
    if (!result.foundPath) {
      return null;
    }
    return result.path;
  }

  Direction? _directionBetweenAdjacent({
    required GridPos from,
    required GridPos to,
  }) {
    final dx = to.x - from.x;
    final dy = to.y - from.y;
    if (dx == 0 && dy == -1) return Direction.north;
    if (dx == 0 && dy == 1) return Direction.south;
    if (dx == 1 && dy == 0) return Direction.east;
    if (dx == -1 && dy == 0) return Direction.west;
    return null;
  }

  GridPos? _nextFollowPathStep({
    required List<GridPos> path,
    required GridPos currentPos,
  }) {
    if (path.length < 2) {
      return null;
    }
    final currentIndex = path.indexWhere(
      (cell) => cell.x == currentPos.x && cell.y == currentPos.y,
    );
    if (currentIndex < 0 || currentIndex + 1 >= path.length) {
      return null;
    }
    return path[currentIndex + 1];
  }

  void _clearPendingFollowPathCache(_PendingScenarioFollowRequest pending) {
    pending.cachedPath = null;
    pending.cachedPathDestination = null;
    pending.cachedPathLeaderPos = null;
  }

  MapRect _resolveScenarioLeaderCollisionFootprint({
    required String leaderEntityId,
    required GridPos fallbackAnchor,
  }) {
    for (final entity in _world.map.entities) {
      if (entity.id == leaderEntityId) {
        final footprint = resolveEntityCollisionFootprint(entity);
        final offsetX = footprint.pos.x - entity.pos.x;
        final offsetY = footprint.pos.y - entity.pos.y;
        return MapRect(
          pos: GridPos(
            x: fallbackAnchor.x + offsetX,
            y: fallbackAnchor.y + offsetY,
          ),
          size: footprint.size,
        );
      }
    }
    return MapRect(
      pos: fallbackAnchor,
      size: const GridSize(width: 1, height: 1),
    );
  }

  Iterable<GridPos> _adjacentCellsAroundRect(MapRect rect) sync* {
    final left = rect.pos.x;
    final top = rect.pos.y;
    final right = left + rect.size.width - 1;
    final bottom = top + rect.size.height - 1;
    final yielded = <GridPos>{};

    for (var x = left; x <= right; x++) {
      final north = GridPos(x: x, y: top - 1);
      if (yielded.add(north)) {
        yield north;
      }
      final south = GridPos(x: x, y: bottom + 1);
      if (yielded.add(south)) {
        yield south;
      }
    }
    for (var y = top; y <= bottom; y++) {
      final west = GridPos(x: left - 1, y: y);
      if (yielded.add(west)) {
        yield west;
      }
      final east = GridPos(x: right + 1, y: y);
      if (yielded.add(east)) {
        yield east;
      }
    }
  }

  Iterable<GridPos> _cellsAlongRectSide(MapRect rect, Direction side) sync* {
    final left = rect.pos.x;
    final top = rect.pos.y;
    final right = left + rect.size.width - 1;
    final bottom = top + rect.size.height - 1;
    switch (side) {
      case Direction.north:
        for (var x = left; x <= right; x++) {
          yield GridPos(x: x, y: top - 1);
        }
      case Direction.south:
        for (var x = left; x <= right; x++) {
          yield GridPos(x: x, y: bottom + 1);
        }
      case Direction.east:
        for (var y = top; y <= bottom; y++) {
          yield GridPos(x: right + 1, y: y);
        }
      case Direction.west:
        for (var y = top; y <= bottom; y++) {
          yield GridPos(x: left - 1, y: y);
        }
    }
  }

  Direction? _resolveLeaderTravelDirection({
    required _PendingScenarioFollowRequest pending,
    required GridPos leaderPos,
    required ScriptedEntityMovementStatus movementStatus,
  }) {
    final previous = pending.lastLeaderPos;
    pending.lastLeaderPos = leaderPos;
    if (previous != null) {
      final dx = leaderPos.x - previous.x;
      final dy = leaderPos.y - previous.y;
      final fromDelta = _directionFromDelta(dx, dy);
      if (fromDelta != null) {
        pending.lastLeaderTravelDirection = fromDelta;
        return fromDelta;
      }
    }
    if (movementStatus.state == ScriptedEntityMovementState.moving &&
        movementStatus.targetPos != null) {
      final target = movementStatus.targetPos!;
      final dx = target.x - leaderPos.x;
      final dy = target.y - leaderPos.y;
      final fromTargetVector = _directionFromDelta(dx, dy);
      if (fromTargetVector != null) {
        pending.lastLeaderTravelDirection = fromTargetVector;
        return fromTargetVector;
      }
    }
    return pending.lastLeaderTravelDirection;
  }

  Direction? _directionFromDelta(int dx, int dy) {
    if (dx == 0 && dy == 0) {
      return null;
    }
    if (dx.abs() >= dy.abs()) {
      return dx >= 0 ? Direction.east : Direction.west;
    }
    return dy >= 0 ? Direction.south : Direction.north;
  }

  Direction _oppositeDirection(Direction direction) {
    switch (direction) {
      case Direction.north:
        return Direction.south;
      case Direction.south:
        return Direction.north;
      case Direction.east:
        return Direction.west;
      case Direction.west:
        return Direction.east;
    }
  }

  bool _isPosAdjacentToRect(GridPos pos, MapRect rect) {
    final left = rect.pos.x;
    final top = rect.pos.y;
    final right = left + rect.size.width - 1;
    final bottom = top + rect.size.height - 1;
    final isInside =
        pos.x >= left && pos.x <= right && pos.y >= top && pos.y <= bottom;
    if (isInside) {
      return false;
    }
    final dx =
        pos.x < left ? left - pos.x : (pos.x > right ? pos.x - right : 0);
    final dy =
        pos.y < top ? top - pos.y : (pos.y > bottom ? pos.y - bottom : 0);
    return math.max(dx, dy) == 1;
  }

  bool _canPlacePlayerAt(GridPos pos) {
    if (!_isWithinMapBounds(_world.map, pos)) {
      return false;
    }
    final trial = _world.withPlayer(_world.player.copyWith(pos: pos));
    return !trial.isBlocked(pos.x, pos.y);
  }

  /// Lance un script projet à partir d'un `scriptId`.
  ///
  /// Callback utilisé par le bridge scénario.
  bool _runScenarioScriptById(
    String scriptId, {
    String? startNode,
    String? runtimeSourceId,
  }) {
    final normalizedScriptId = scriptId.trim();
    if (normalizedScriptId.isEmpty) {
      return false;
    }
    if (_activeScriptController != null &&
        !_activeScriptController!.isTerminated) {
      return false;
    }
    ScriptAsset? scriptAsset;
    for (final entry in _bundle.manifest.scripts) {
      if (entry.id == normalizedScriptId) {
        scriptAsset = entry.asset;
        break;
      }
    }
    if (scriptAsset == null) {
      debugPrint('[scenario_runtime] script not found: $normalizedScriptId');
      return false;
    }
    _startScriptExecution(
      script: scriptAsset,
      startNodeId: startNode,
      runtimeSourceId: runtimeSourceId ?? 'scenario',
    );
    return true;
  }

  void _logEncounterCheck(GameplayEncounterCheckResult check) {
    final kind = check.encounterKind?.name ?? EncounterKind.walk.name;
    switch (check.status) {
      case GameplayEncounterCheckStatus.noZone:
        debugPrint('[encounter] no compatible zone');
        return;
      case GameplayEncounterCheckStatus.noEncounterTableId:
        debugPrint(
          '[encounter] zone=${check.zoneId ?? 'unknown'} has no encounter table id (kind=$kind)',
        );
        return;
      case GameplayEncounterCheckStatus.encounterTableNotFound:
        debugPrint(
          '[encounter] zone=${check.zoneId ?? 'unknown'} table=${check.tableId ?? 'unknown'} not found',
        );
        return;
      case GameplayEncounterCheckStatus.encounterKindMismatch:
        debugPrint(
          '[encounter] zone=${check.zoneId ?? 'unknown'} table=${check.tableId ?? 'unknown'} kind mismatch (expected=$kind)',
        );
        return;
      case GameplayEncounterCheckStatus.emptyEncounterTable:
        debugPrint(
          '[encounter] zone=${check.zoneId ?? 'unknown'} table=${check.tableId ?? 'unknown'} has no valid entries',
        );
        return;
      case GameplayEncounterCheckStatus.rollFailed:
        debugPrint(
          '[encounter] matched zone=${check.zoneId ?? 'unknown'} table=${check.tableId ?? 'unknown'}',
        );
        debugPrint(
          '[encounter] rolled no encounter roll=${check.roll?.toStringAsFixed(3) ?? 'n/a'}',
        );
        return;
      case GameplayEncounterCheckStatus.triggered:
        final encounter = check.encounter;
        if (encounter == null) {
          debugPrint('[encounter] triggered status without payload');
          return;
        }
        debugPrint(
          '[encounter] matched zone=${encounter.zoneId} table=${encounter.tableId}',
        );
        debugPrint(
          '[encounter] triggered species=${encounter.speciesId} level=${encounter.level} kind=${encounter.encounterKind.name}',
        );
        return;
    }
  }

  /// Démarre le handoff de combat.
  ///
  /// [request] - La requête de combat (wild ou trainer).
  ///
  /// Cette méthode :
  /// 1. Stocke la requête pour le mapping vers BattleSetup
  /// 2. Passe en phase battleTransition
  /// 3. Affiche l'overlay de transition
  void _startBattleHandoff(BattleStartRequest request) {
    if (_flowPhase != _RuntimeFlowPhase.overworld) {
      return;
    }
    _flowPhase = _RuntimeFlowPhase.battleTransition;
    _notification?.removeFromParent();
    _notification = null;
    _battleTransitionOverlay?.removeFromParent();
    _battleTransitionOverlay = null;
    _battleOverlay?.removeFromParent();
    _battleOverlay = null;
    debugPrint(
      '[battle] transition started requestId=${request.requestId} kind=${request.kind.name}',
    );
    final overlay = BattleTransitionOverlayComponent(
      request: request,
      viewportSize: camera.viewport.size,
      onFinished: () {
        // Le mapping vers BattleSetup peut maintenant lire le vrai projet et
        // échouer explicitement. On déclenche donc l'ouverture de manière async
        // au lieu de supposer qu'un setup placeholder sera toujours disponible.
        unawaited(_openBattleOverlay(request));
      },
    );
    camera.viewport.add(overlay);
    _battleTransitionOverlay = overlay;
  }

  /// Ouvre l'overlay de combat après la transition.
  ///
  /// [request] - La requête de combat.
  ///
  /// Cette méthode :
  /// 1. Mappe BattleStartRequest → BattleSetup
  /// 2. Crée la BattleSession
  /// 3. Affiche BattleOverlayComponent avec la session
  Future<void> _openBattleOverlay(BattleStartRequest request) async {
    if (_flowPhase != _RuntimeFlowPhase.battleTransition) {
      return;
    }
    _battleTransitionOverlay?.removeFromParent();
    _battleTransitionOverlay = null;
    try {
      // BE10 recadré élargit légèrement cet invariant runtime :
      // - on mémorise toujours le slot actif exact utilisé au handoff ;
      // - mais on mémorise aussi l'ordre actif + réserves réellement injecté
      //   dans le combat ;
      // - cela permet ensuite un write-back honnête si le joueur switch.
      //
      // Pourquoi ici :
      // - la sélection se fait sur le vrai GameState runtime, juste avant le
      //   mapping vers BattleSetup ;
      // - on réutilise ensuite ce mapping stable au moment du write-back ;
      // - on évite ainsi le bug classique "recalculer le premier Pokémon
      //   jouable après le combat", qui casserait la cohérence dès qu'un
      //   switch a déplacé l'actif.
      final playerLineup =
          _battleSetupMapper.selectPlayerBattleLineup(_gameState.party);

      // Le lot 9 remplace enfin le setup placeholder par un mapping réel
      // depuis la save runtime et les données projet.
      final setup = await _toBattleSetup(
        request,
        playerPartyIndex: playerLineup.activeIndex,
      );

      // Lot 12 pose le premier write runtime honnête du "seen" :
      // l'espèce ennemie n'est marquée vue qu'une fois le handoff réellement
      // résolu et le combat effectivement prêt à s'ouvrir.
      //
      // On évite volontairement de marquer plus tôt :
      // - une simple case d'herbe ne suffit pas ;
      // - un setup qui échoue ne doit rien écrire ;
      // - aucune capture n'est ouverte ici.
      _gameState = markSpeciesSeenInGameState(
        _gameState,
        setup.enemyPokemon.speciesId,
      );
      _flowPhase = _RuntimeFlowPhase.battle;

      // Créer la session de combat
      _battleSession = createBattleSession(setup);
      _activeBattleContext = RuntimeActiveBattleContext(
        request: request,
        playerPartyIndex: playerLineup.activeIndex,
        playerPartySlotIndicesByLineupIndex: playerLineup.lineupPartyIndices,
      );

      // Afficher l'overlay de combat avec la session
      final overlay = BattleOverlayComponent(
        session: _battleSession!,
        viewportSize: camera.viewport.size,
        onPlayerChoice: _onPlayerBattleChoice,
      );
      camera.viewport.add(overlay);
      _battleOverlay = overlay;
      debugPrint(
        '[battle] overlay opened requestId=${request.requestId} kind=${request.kind.name}',
      );
    } on RuntimeBattleSetupException catch (error) {
      _cancelBattleHandoff(
        userMessage: error.message,
        debugDetails: error.debugDetails,
      );
    } catch (error, stackTrace) {
      _cancelBattleHandoff(
        userMessage:
            'Impossible de démarrer le combat avec les données locales du projet.',
        debugDetails: '$error\n$stackTrace',
      );
    }
  }

  /// Mappe BattleStartRequest → BattleSetup.
  ///
  /// [request] - La requête de combat depuis le runtime.
  ///
  /// Retourne un BattleSetup pur pour le moteur de combat.
  Future<BattleSetup> _toBattleSetup(
    BattleStartRequest request, {
    int? playerPartyIndex,
  }) {
    return _battleSetupMapper.map(
      bundle: _bundle,
      gameState: _gameState,
      request: request,
      playerPartyIndex: playerPartyIndex,
    );
  }

  void _cancelBattleHandoff({
    required String userMessage,
    String? debugDetails,
  }) {
    // On nettoie explicitement tout état battle partiellement initialisé.
    // Ce helper évite qu'un mapping KO laisse le runtime coincé en transition.
    _battleOverlay?.removeFromParent();
    _battleOverlay = null;
    _battleTransitionOverlay?.removeFromParent();
    _battleTransitionOverlay = null;
    _battleSession = null;
    _activeBattleContext = null;
    _isBattleResolving = false;
    _flowPhase = _RuntimeFlowPhase.overworld;
    _pressedKeys.clear();
    _lastMoveKey = null;
    debugPrint(
      '[battle] handoff cancelled message="$userMessage" details=${debugDetails ?? 'n/a'}',
    );
    _showNotification(userMessage);
  }

  /// Gère le choix du joueur pendant le combat.
  ///
  /// [choice] - Le choix fait par le joueur.
  ///
  /// Cette méthode :
  /// 1. Applique le choix via BattleSession.applyChoice()
  /// 2. Met à jour l'UI
  /// 3. Vérifie si le combat est fini
  /// 4. Si fini, appelle _onBattleFinished()
  ///
  /// **Lock anti-spam** : `_isBattleResolving` empêche le spam clavier
  /// pendant la résolution d'un tour.
  void _onPlayerBattleChoice(PlayerBattleChoice choice) {
    if (_battleSession == null) {
      return;
    }

    // Lock anti-spam : empêcher traitement multiple pendant résolution
    if (_isBattleResolving) {
      debugPrint('[battle] choice ignored: already resolving');
      return;
    }
    _isBattleResolving = true;

    try {
      // Appliquer le choix (retourne une nouvelle session immutable)
      _battleSession = _battleSession!.applyChoice(choice);

      // Mettre à jour l'UI avec le nouvel état
      final overlay = _battleOverlay;
      overlay?.updateState(_battleSession!);

      // Vérifier si le combat est fini
      if (_battleSession!.state.isFinished) {
        _onBattleFinished(_battleSession!.state.outcome!);
      }
    } finally {
      // Unlock après résolution (ou après fin de combat)
      // Si combat fini, _onBattleFinished() va reset l'état de toute façon
      if (_flowPhase == _RuntimeFlowPhase.battle) {
        _isBattleResolving = false;
      }
    }
  }

  /// Gère la fin du combat.
  ///
  /// [outcome] - Le résultat du combat.
  ///
  /// Cette méthode :
  /// 1. Applique le résultat au vrai GameState runtime
  /// 2. Nettoie l'overlay (SUPPRIME du parent)
  /// 3. Retourne à l'overworld
  void _onBattleFinished(BattleOutcome outcome) {
    debugPrint('[battle] battle finished outcome=${outcome.type.name}');

    // Le lot 10 normalise ici tout le write-back post-combat :
    // - PV du lineup joueur écrits sur les slots exacts mémorisés ;
    // - flag trainer_defeated uniquement sur une vraie victoire trainer ;
    // - aucune tentative de recalcul du Pokémon actif après la fin du combat.
    final activeBattleContext = _activeBattleContext;
    if (activeBattleContext != null) {
      final previousState = _gameState;
      _gameState = applyRuntimeBattleOutcomeToGameState(
        gameState: _gameState,
        context: activeBattleContext,
        outcome: outcome,
        storyFlagsManager: _storyFlags,
      );

      if (outcome.isDefeat) {
        _applyWhiteoutLiteAfterPlayerDefeat(
          activeBattleContext,
          activePlayerLineupIndex: outcome.finalState.player.lineupIndex,
        );
      }

      if (outcome.isVictory &&
          activeBattleContext.request is TrainerBattleStartRequest) {
        final trainerRequest =
            activeBattleContext.request as TrainerBattleStartRequest;
        debugPrint(
          '[battle] trainer marked as defeated: ${trainerRequest.trainerId}',
        );
      }

      // On ne refresh la présence PNJ que si les story flags ont réellement
      // changé ; cela garde le retour overworld minimal pour wild/defeat/run.
      if (!identical(previousState.storyFlags, _gameState.storyFlags) &&
          previousState.storyFlags != _gameState.storyFlags) {
        _refreshWorldNpcPresence();
      }
    }

    // Nettoyer et retourner à l'overworld
    // IMPORTANT: Il faut SUPPRIMER l'overlay du parent, pas juste mettre à null
    _battleOverlay?.removeFromParent();
    _battleOverlay = null;
    _battleTransitionOverlay?.removeFromParent();
    _battleTransitionOverlay = null;
    _battleSession = null;
    _activeBattleContext = null;
    _isBattleResolving = false; // Reset lock anti-spam

    // NOTE: NE PAS clear _triggeredTrainerBattles ici!
    // Le lock doit rester actif tant que le joueur est dans la LoS du trainer.
    // Si on clear le lock ici, le trainer sera re-déclenché immédiatement
    // car le joueur est probablement encore dans sa zone de LoS.
    //
    // Le lock sera clear automatiquement quand le joueur quittera la LoS,
    // via le mécanisme de réarmement dans _checkTrainerLineOfSight():
    //   if (_triggeredTrainerBattles.contains(entity.id)) {
    //     if (!inLoS) _triggeredTrainerBattles.remove(entity.id);
    //   }
    //
    // Et même si le lock est encore actif, le trainer ne sera pas re-déclenché
    // car il est marqué defeated dans storyFlags (guard dans _checkTrainerLineOfSight).

    _flowPhase = _RuntimeFlowPhase.overworld;
    _pressedKeys.clear();
    _lastMoveKey = null;
    debugPrint('[battle] overworld resumed');
  }

  void _applyWhiteoutLiteAfterPlayerDefeat(
    RuntimeActiveBattleContext activeBattleContext, {
    required int activePlayerLineupIndex,
  }) {
    // Le whiteout-lite reste volontairement plus petit que BE10 :
    // - le moteur battle sait maintenant switcher et porter une vraie réserve ;
    // - mais cette reprise overworld ne cherche toujours pas à ouvrir un vrai
    //   centre Pokémon, ni une politique riche de défaite ;
    // - on garde donc un simple filet de sécurité post-combat.
    //
    // Le lot 15 reste donc volontairement borné :
    // 1. on garde le write-back lot 10 fidèle aux PV réellement sortis du combat ;
    // 2. puis on évite seulement le softlock total avec une reprise minimale ;
    // 3. on n'ouvre ni centre Pokémon, ni économie, ni pénalité complexe.
    _gameState = applyRuntimeDefeatRecoveryToGameState(
      gameState: _gameState,
      playerPartyIndex: activeBattleContext.playerPartyIndex,
      activePlayerLineupIndex: activePlayerLineupIndex,
      playerPartySlotIndicesByLineupIndex:
          activeBattleContext.playerPartySlotIndicesByLineupIndex,
    );

    final respawn = _resolveWhiteoutLiteRespawn(activeBattleContext);
    _world = _buildSafeWorldState(
      map: _bundle.map,
      project: _bundle.manifest,
      preferredPos: respawn.pos,
      fallbackFacing: respawn.facing,
      tileWidth: _bundle.manifest.settings.tileWidth,
      tileHeight: _bundle.manifest.settings.tileHeight,
    );

    // On reste volontairement sur la carte courante :
    // - aucun "last heal center" persistant n'existe encore dans l'architecture ;
    // - aucun warp multi-map spécial whiteout n'est authoré ;
    // - réutiliser le spawn joueur déjà défini sur la map courante est donc le
    //   point de reprise le plus honnête disponible aujourd'hui.
    _player.syncState(_world.player, snapToGrid: true);
    _syncGameStateFromWorld(mapIdOverride: _activeMapId);
    _configureCameraViewport();
    _syncCameraToPlayer();
    _preloadActiveMapConnections();
    _pruneLoadedMapsToActiveNeighborhood();
    _activeScenarioTriggerIds = _scenarioRuntime.triggerIdsAtPosition(
      map: _bundle.map,
      pos: _world.player.pos,
    );
    _refreshWorldNpcPresence();
    _showNotification('Défaite... retour au point de reprise');
  }

  GameplayPlayerState _resolveWhiteoutLiteRespawn(
    RuntimeActiveBattleContext activeBattleContext,
  ) {
    try {
      return resolveInitialPlayerSpawn(_bundle.map);
    } catch (_) {
      // Fallback minimal :
      // - si la map courante n'a pas de spawn joueur exploitable, on repart de
      //   la position overworld mémorisée au moment du handoff combat ;
      // - `_buildSafeWorldState` gardera ensuite le dernier mot pour éviter une
      //   cellule bloquée et trouver un point sûr si nécessaire.
      return GameplayPlayerState(
        pos: activeBattleContext.request.returnContext.playerPos,
        facing: activeBattleContext.request.returnContext.playerFacing,
      );
    }
  }

  void _handleInteract() {
    final result = stepGameplayWorld(_world, const InteractIntent());
    _world = result.world;
    _consumePathAnimationSignals(result.pathAnimationSignals);
    var scenarioHandledEntityInteraction = false;

    switch (result) {
      case NothingToInteract():
        if (result.pathAnimationSignals.isNotEmpty) {
          debugPrint('[interact] Path animation trigger');
          return;
        }
        debugPrint('[interact] Nothing to interact with');
        _showNotification('...');
      case NpcInteracted(:final entity):
        debugPrint('[interact] NPC: ${entity.id}');
        _faceNpcTowardPlayer(entity.id);
        scenarioHandledEntityInteraction =
            _tryDispatchScenarioEntityInteraction(
          entity.id,
        );
        if (!scenarioHandledEntityInteraction) {
          _handleNpcInteraction(entity);
        }
      case SignInteracted(:final entity):
        debugPrint('[interact] Sign: ${entity.id}');
        scenarioHandledEntityInteraction =
            _tryDispatchScenarioEntityInteraction(
          entity.id,
        );
        if (!scenarioHandledEntityInteraction) {
          _tryOpenDialogue(
              entity.id, entity.sign?.dialogue, entity.inspectorHeadline);
        }
      case ItemInteracted(:final entity):
        debugPrint('[interact] Item: ${entity.id}');
        _showNotification(entity.inspectorHeadline);
      case EntityInteracted(:final entity):
        debugPrint('[interact] Entity: ${entity.id}');
        scenarioHandledEntityInteraction =
            _tryDispatchScenarioEntityInteraction(
          entity.id,
        );
        if (!scenarioHandledEntityInteraction) {
          _showNotification(entity.inspectorHeadline);
        }
      case PlacedElementInteracted(
          :final element,
          :final behavior,
          :final trigger,
        ):
        debugPrint('[interact] PlacedElement: ${element.id}');
        _executePlacedElementBehavior(
          element: element,
          behavior: behavior,
          trigger: trigger,
        );
      default:
        break;
    }

    if (result is NothingToInteract ||
        (result is EntityInteracted && !scenarioHandledEntityInteraction)) {
      _tryInteractWithMapEvent();
    }
  }

  bool _tryDispatchScenarioEntityInteraction(String entityId) {
    final result = _dispatchScenarioRuntimeSource(
      ScenarioRuntimeSourceEvent.entityInteract(
        mapId: _activeMapId,
        entityId: entityId,
      ),
    );
    return result.handled;
  }

  void _tryInteractWithMapEvent() {
    if (_activeScriptController != null &&
        !_activeScriptController!.isTerminated) {
      debugPrint('[interact] blocked: script is active');
      return;
    }

    if (_flowPhase != _RuntimeFlowPhase.overworld) {
      debugPrint('[interact] blocked: flow phase is $_flowPhase');
      return;
    }

    final facing = _world.player.facing;
    final tx = _world.player.pos.x + facing.dx;
    final ty = _world.player.pos.y + facing.dy;

    final map = _bundle.map;
    MapEventDefinition? event;
    for (final e in map.events) {
      if (e.position.x == tx && e.position.y == ty) {
        event = e;
        break;
      }
    }

    if (event == null) return;

    final activePage = _storyBranching.resolveEventPage(event, _gameState);

    if (activePage == null) return;

    if (activePage.page.isDisabled) return;

    debugPrint('[interact] MapEvent: ${event.id} page=${activePage.pageIndex}');
    _handleMapEventInteraction(event, activePage);
  }

  void _handleMapEventInteraction(
    MapEventDefinition event,
    ActiveEventPage page,
  ) {
    if (page.page.script != null) {
      final message = page.page.message?.trim();
      if (message != null && message.isNotEmpty) {
        _showNotification(message);
      }
      _executeEventScript(event, page, page.page.script!);
    } else if (page.page.message != null && page.page.message!.isNotEmpty) {
      _showNotification(page.page.message!);
    } else {
      _showNotification('...');
    }
  }

  void _executeEventScript(
    MapEventDefinition event,
    ActiveEventPage page,
    ScriptRef scriptRef,
  ) {
    final scriptAsset = _bundle.manifest.scripts
        .firstWhere(
          (s) => s.id == scriptRef.scriptId,
          orElse: () =>
              throw StateError('Script not found: ${scriptRef.scriptId}'),
        )
        .asset;
    _startScriptExecution(
      script: scriptAsset,
      startNodeId: scriptRef.startNode,
      runtimeSourceId: event.id,
    );
  }

  /// Démarrage générique d'exécution script.
  ///
  /// Cette méthode factorise le chemin script:
  /// - scripts de pages d'event map,
  /// - scripts déclenchés par le Scenario Runtime Bridge.
  void _startScriptExecution({
    required ScriptAsset script,
    String? startNodeId,
    required String runtimeSourceId,
  }) {
    final context = ScriptExecutionContext(
      gameState: _gameState,
      onGameStateUpdated: (state) {
        _gameState = state;
        _refreshWorldNpcPresence();
      },
      onDialogueOpened: (dialogue) {
        _openDialogueForScriptSource(runtimeSourceId, dialogue);
      },
      onWarpRequested: (mapId, x, y) {
        _pendingWarp = TriggeredWarp(
          warpId: 'script_warp',
          targetMapId: mapId,
          targetPos: GridPos(x: x, y: y),
          triggerMode: MapWarpTriggerMode.onEnter,
        );
      },
    );

    _activeScriptController = ScriptRuntimeController(
      script: script,
      context: context,
      startNodeId: startNodeId,
    );
    _isAwaitingScriptResume = false;
    _runScriptStep();
  }

  void _runScriptStep() {
    final controller = _activeScriptController;
    if (controller == null) {
      return;
    }

    if (controller.isTerminated) {
      _activeScriptController = null;
      _isAwaitingScriptResume = false;
      return;
    }

    if (controller.isSuspended) {
      _isAwaitingScriptResume = true;
      return;
    }

    final result = controller.step();

    if (result is ScriptCommandResultSuspended) {
      _isAwaitingScriptResume = true;
      if (result.reason == ScriptSuspendReason.waitingForDialogue) {
        _flowPhase = _RuntimeFlowPhase.dialogue;
      }
      return;
    }

    _runScriptStep();
  }

  void _openDialogueForScriptSource(
      String runtimeSourceId, YarnDialogueRef dialogueRef) {
    final resolved = resolveDialogue(
      entityId: runtimeSourceId,
      ref: DialogueRef(
        dialogueId: '',
        scriptPathRelative: dialogueRef.filePath,
        startNode: dialogueRef.startNode,
      ),
      projectRootDirectory: _bundle.projectRootDirectory,
      dialogues: _bundle.manifest.dialogues,
    );

    if (resolved == null) {
      debugPrint(
          '[script] failed to resolve dialogue: ${dialogueRef.filePath}');
      _runScriptStep();
      return;
    }

    loadDialogueContent(resolved).then((session) {
      if (session == null) {
        debugPrint('[script] failed to load dialogue');
        _runScriptStep();
        return;
      }

      _pendingPostDialogueAction = () {
        _flowPhase = _RuntimeFlowPhase.overworld;
        if (_isAwaitingScriptResume) {
          _isAwaitingScriptResume = false;
          _runScriptStep();
        }
      };

      _openDialogue(session);
    });
  }

  void _consumePathAnimationSignals(List<PathAnimationSignal> signals) {
    if (signals.isEmpty) {
      return;
    }
    final active = _loadedMapsById[_activeMapId];
    if (active == null) {
      return;
    }
    for (final signal in signals) {
      switch (signal.kind) {
        case PathAnimationSignalKind.trigger:
          final backgroundApplied =
              active.backgroundLayers.triggerPathAnimationRule(
            layerId: signal.layerId,
            ruleId: signal.ruleId,
            mode: signal.mode,
            scope: signal.scope,
            cellX: signal.sourcePos.x,
            cellY: signal.sourcePos.y,
          );
          final foregroundApplied =
              active.foregroundLayers.triggerPathAnimationRule(
            layerId: signal.layerId,
            ruleId: signal.ruleId,
            mode: signal.mode,
            scope: signal.scope,
            cellX: signal.sourcePos.x,
            cellY: signal.sourcePos.y,
          );
          if (!backgroundApplied && !foregroundApplied) {
            debugPrint(
              '[path_anim] trigger ignored layer=${signal.layerId} preset=${signal.presetId} rule=${signal.ruleId} trigger=${signal.trigger.name} mode=${signal.mode.name} source=(${signal.sourcePos.x}, ${signal.sourcePos.y})',
            );
            continue;
          }
          debugPrint(
            '[path_anim] trigger layer=${signal.layerId} preset=${signal.presetId} rule=${signal.ruleId} trigger=${signal.trigger.name} mode=${signal.mode.name} source=(${signal.sourcePos.x}, ${signal.sourcePos.y})',
          );
        case PathAnimationSignalKind.setActive:
          final activeValue = signal.active ?? false;
          final backgroundApplied =
              active.backgroundLayers.setPathAnimationRuleActive(
            layerId: signal.layerId,
            ruleId: signal.ruleId,
            active: activeValue,
            scope: signal.scope,
            cellX: signal.sourcePos.x,
            cellY: signal.sourcePos.y,
          );
          final foregroundApplied =
              active.foregroundLayers.setPathAnimationRuleActive(
            layerId: signal.layerId,
            ruleId: signal.ruleId,
            active: activeValue,
            scope: signal.scope,
            cellX: signal.sourcePos.x,
            cellY: signal.sourcePos.y,
          );
          if (!backgroundApplied && !foregroundApplied) {
            debugPrint(
              '[path_anim] active ignored layer=${signal.layerId} preset=${signal.presetId} rule=${signal.ruleId} trigger=${signal.trigger.name} active=$activeValue source=(${signal.sourcePos.x}, ${signal.sourcePos.y})',
            );
            continue;
          }
          debugPrint(
            '[path_anim] active layer=${signal.layerId} preset=${signal.presetId} rule=${signal.ruleId} trigger=${signal.trigger.name} active=$activeValue source=(${signal.sourcePos.x}, ${signal.sourcePos.y})',
          );
      }
    }
  }

  void _executePlacedElementBehavior({
    required MapPlacedElement element,
    required MapPlacedElementBehavior behavior,
    required MapPlacedElementTriggerType trigger,
  }) {
    if (!behavior.enabled) {
      return;
    }
    final effect = behavior.effect;
    final cooldownKey = _buildPlacedBehaviorCooldownKey(
      element: element,
      behavior: behavior,
      trigger: trigger,
    );
    final cooldownOverride = _resolvePlacedBehaviorCooldownOverride(behavior);
    if (!_placedBehaviorCooldownGate.canTrigger(
      key: cooldownKey,
      nowMs: _runtimeClockMs,
    )) {
      final remainingMs = _placedBehaviorCooldownGate.remainingMs(
        key: cooldownKey,
        nowMs: _runtimeClockMs,
      );
      debugPrint(
        '[placed_behavior] cooldown blocked trigger=${trigger.name} scope=${behavior.triggerScope.name} instance=${element.id} behavior=${cooldownKey.behaviorId} effect=${effect.type.name} remainingMs=${remainingMs.toStringAsFixed(0)}',
      );
      _updateBehaviorDebugLine(
        'Cooldown ${effect.type.name} (${remainingMs.toStringAsFixed(0)} ms) · ${element.id}#${cooldownKey.behaviorId} (${behavior.triggerScope.name})',
      );
      return;
    }
    debugPrint(
      '[placed_behavior] trigger=${trigger.name} scope=${behavior.triggerScope.name} instance=${element.id} behavior=${cooldownKey.behaviorId} effect=${effect.type.name}',
    );
    var effectApplied = false;
    switch (effect.type) {
      case MapPlacedElementEffectType.showMessage:
        final text = effect.message?.trim() ?? '';
        if (text.isEmpty) {
          debugPrint(
            '[placed_behavior] showMessage ignored instance=${element.id} behavior=${cooldownKey.behaviorId} reason=empty_message',
          );
          return;
        }
        _showNotification(text);
        effectApplied = true;
        break;
      case MapPlacedElementEffectType.openDialogue:
        effectApplied =
            _tryOpenDialogue(element.id, effect.dialogue, element.elementId);
        break;
      case MapPlacedElementEffectType.setAnimationEnabled:
        final enabled = effect.animationEnabled;
        if (enabled == null) {
          debugPrint(
            '[placed_behavior] setAnimationEnabled ignored instance=${element.id} behavior=${cooldownKey.behaviorId} reason=missing_value',
          );
          return;
        }
        final currentEnabled = _resolvePlacedElementAnimationEnabled(
          element.id,
        );
        if (currentEnabled == enabled) {
          debugPrint(
            '[placed_behavior] setAnimationEnabled ignored instance=${element.id} behavior=${cooldownKey.behaviorId} reason=no_change value=$enabled',
          );
          _updateBehaviorDebugLine(
            'Animation déjà ${enabled ? 'active' : 'inactive'} · ${element.id}#${cooldownKey.behaviorId}',
          );
          return;
        }
        _applyPlacedElementAnimationEnabled(
          instanceId: element.id,
          enabled: enabled,
        );
        effectApplied = true;
        break;
      case MapPlacedElementEffectType.playAnimationOnce:
        final triggered =
            _playPlacedElementAnimationOnce(instanceId: element.id);
        if (!triggered) {
          debugPrint(
            '[placed_behavior] playAnimationOnce ignored instance=${element.id} behavior=${cooldownKey.behaviorId} reason=no_animatable_frames',
          );
          _updateBehaviorDebugLine(
            'Animation 1x indisponible · ${element.id}#${cooldownKey.behaviorId}',
          );
          return;
        } else {
          debugPrint(
            '[placed_behavior] playAnimationOnce started instance=${element.id} behavior=${cooldownKey.behaviorId} strategy=restart',
          );
        }
        effectApplied = true;
        break;
    }
    if (!effectApplied) {
      return;
    }
    _placedBehaviorCooldownGate.markTriggered(
      key: cooldownKey,
      nowMs: _runtimeClockMs,
      overrideDuration: cooldownOverride,
    );
    _updateBehaviorDebugLine(
      'Triggered ${trigger.name}/${behavior.triggerScope.name} -> ${effect.type.name} · ${element.id}#${cooldownKey.behaviorId}',
    );
  }

  bool _playPlacedElementAnimationOnce({
    required String instanceId,
  }) {
    final loaded = _loadedMapsById[_activeMapId];
    if (loaded == null) {
      return false;
    }
    final fromBackground =
        loaded.backgroundLayers.playPlacedElementAnimationOnce(
      instanceId: instanceId,
    );
    final fromForeground =
        loaded.foregroundLayers.playPlacedElementAnimationOnce(
      instanceId: instanceId,
    );
    return fromBackground || fromForeground;
  }

  void _applyPlacedElementAnimationEnabled({
    required String instanceId,
    required bool enabled,
  }) {
    try {
      final updatedMap = setMapPlacedElementAnimationEnabled(
        _world.map,
        instanceId: instanceId,
        enabled: enabled,
      );
      _world = GameplayWorldState.initial(
        map: updatedMap,
        playerPos: _world.player.pos,
        playerFacing: _world.player.facing,
        playerMovementMode: _world.player.movementMode,
        project: _bundle.manifest,
        tileWidth: _bundle.manifest.settings.tileWidth,
        tileHeight: _bundle.manifest.settings.tileHeight,
        npcMapPresencePredicate: _npcPresencePredicateFor(_bundle.manifest),
      );
      _bundle = RuntimeMapBundle(
        manifest: _bundle.manifest,
        map: updatedMap,
        projectRootDirectory: _bundle.projectRootDirectory,
        tilesetAbsolutePathsById: _bundle.tilesetAbsolutePathsById,
      );
      final activeLoaded = _loadedMapsById[_activeMapId];
      if (activeLoaded != null) {
        activeLoaded.backgroundLayers.setPlacedElementAnimationEnabledOverride(
          instanceId: instanceId,
          enabled: enabled,
        );
        activeLoaded.foregroundLayers.setPlacedElementAnimationEnabledOverride(
          instanceId: instanceId,
          enabled: enabled,
        );
        _loadedMapsById[_activeMapId] = _LoadedPlayableMap(
          bundle: _bundle,
          originCellX: activeLoaded.originCellX,
          originCellY: activeLoaded.originCellY,
          backgroundLayers: activeLoaded.backgroundLayers,
          foregroundLayers: activeLoaded.foregroundLayers,
          npcActors: activeLoaded.npcActors,
          npcActorByEntityId: activeLoaded.npcActorByEntityId,
        );
      }
      debugPrint(
        '[placed_behavior] setAnimationEnabled applied instance=$instanceId enabled=$enabled',
      );
    } catch (e, st) {
      debugPrint(
        '[placed_behavior] setAnimationEnabled failed instance=$instanceId enabled=$enabled error=$e\n$st',
      );
      _showNotification('Animation update failed');
    }
  }

  bool _tryOpenDialogue(
      String entityId, DialogueRef? ref, String fallbackLabel) {
    if (_flowPhase != _RuntimeFlowPhase.overworld) return false;
    if (_dialogueOverlay != null) return false;
    if (!_npcEntityAllowedOnActiveMapForDialogue(entityId)) {
      debugPrint('[dialogue] blocked: npc absent entityId=$entityId');
      return false;
    }

    final resolved = resolveDialogue(
      entityId: entityId,
      ref: ref,
      projectRootDirectory: _bundle.projectRootDirectory,
      dialogues: _bundle.manifest.dialogues,
    );

    if (resolved == null) {
      _showNotification(fallbackLabel);
      return false;
    }

    loadDialogueContent(resolved).then((session) {
      if (_dialogueOverlay != null) return;
      if (session == null) {
        debugPrint('[dialogue] failed to load session for entity=$entityId');
        _showNotification(fallbackLabel);
        return;
      }
      debugPrint('[dialogue] opening dialogue for entity=$entityId');
      _openDialogue(session);
    });
    return true;
  }

  void _openDialogue(DialogueSession session) {
    _notification?.removeFromParent();
    _notification = null;
    _pressedKeys.clear();
    _lastMoveKey = null;
    _flowPhase = _RuntimeFlowPhase.dialogue;

    final overlay = DialogueOverlayComponent(
      session: session,
      viewportSize: camera.viewport.size,
      onFinished: () {
        debugPrint('[dialogue] dialogue closed');
        _dialogueOverlay = null;
        _flowPhase = _RuntimeFlowPhase.overworld;
        _awaitingSurfConfirmation = false;
        final action = _pendingPostDialogueAction;
        _pendingPostDialogueAction = null;
        action?.call();
      },
    );
    camera.viewport.add(overlay);
    _dialogueOverlay = overlay;
    final openedState = session.state;
    if (openedState is DialogueShowingLine) {
      debugPrint(
          '[dialogue] opened node=${session.currentNodeTitle} text="${openedState.text}"');
    } else if (openedState is DialogueWaitingForChoice) {
      debugPrint(
          '[dialogue] opened node=${session.currentNodeTitle} choice count=${openedState.choices.length}');
    }
  }

  void _advanceDialogue() {
    final overlay = _dialogueOverlay;
    if (overlay == null) return;
    final prevNode = overlay.currentSession.currentNodeTitle;
    final stillOpen = overlay.advance();
    if (!stillOpen) {
      debugPrint('[dialogue] finished');
      return;
    }
    final newNode = overlay.currentSession.currentNodeTitle;
    if (newNode != null && newNode != prevNode) {
      debugPrint('[dialogue] jump to=$newNode');
    }
    final newState = overlay.currentSession.state;
    if (newState is DialogueShowingLine) {
      debugPrint('[dialogue] line text="${newState.text}"');
    } else if (newState is DialogueWaitingForChoice) {
      debugPrint(
          '[dialogue] choice opened count=${newState.choices.length} selected=0');
    }
  }

  void _moveChoiceCursor(int delta) {
    final overlay = _dialogueOverlay;
    if (overlay == null) return;
    overlay.moveCursor(delta);
    final state = overlay.currentSession.state;
    if (state is DialogueWaitingForChoice) {
      debugPrint('[dialogue] choice moved selected=${state.selectedIndex}');
    }
  }

  void _confirmDialogueChoice() {
    final overlay = _dialogueOverlay;
    if (overlay == null) return;
    final state = overlay.currentSession.state;
    if (state is DialogueWaitingForChoice) {
      final idx = state.selectedIndex;
      debugPrint(
          '[dialogue] choice confirmed index=$idx text="${state.choices[idx].text}"');
      if (_awaitingSurfConfirmation) {
        if (idx == 0) {
          _pendingPostDialogueAction = () {
            setSurfingEnabled(true);
            debugPrint('[surf] mode activated via dialogue choice');
          };
        }
        _awaitingSurfConfirmation = false;
      }
    }
    final prevNode = overlay.currentSession.currentNodeTitle;
    final stillOpen = overlay.confirmChoice();
    if (!stillOpen) {
      debugPrint('[dialogue] finished');
      return;
    }
    final newNode = overlay.currentSession.currentNodeTitle;
    if (newNode != null && newNode != prevNode) {
      debugPrint('[dialogue] jump to=$newNode');
    }
    final newState = overlay.currentSession.state;
    if (newState is DialogueShowingLine) {
      debugPrint('[dialogue] line text="${newState.text}"');
    } else if (newState is DialogueWaitingForChoice) {
      debugPrint(
          '[dialogue] choice opened count=${newState.choices.length} selected=0');
    }
  }

  /// Garde-fou : tout dialogue / combat PNJ passe par ici ou [_tryOpenDialogue].
  bool _npcEntityAllowedOnActiveMapForDialogue(String entityId) {
    final normalized = entityId.trim();
    if (normalized.isEmpty) {
      return true;
    }
    MapEntity? found;
    for (final e in _world.map.entities) {
      if (e.id == normalized) {
        found = e;
        break;
      }
    }
    if (found == null) {
      return true;
    }
    if (found.kind != MapEntityKind.npc) {
      return true;
    }
    return _npcPresencePredicateFor(_bundle.manifest)(
      _world.map.id,
      found,
    );
  }

  void _handleNpcInteraction(MapEntity entity) {
    if (!_npcPresencePredicateFor(_bundle.manifest)(_world.map.id, entity)) {
      debugPrint('[interact] ignored absent npc=${entity.id}');
      return;
    }
    final trainerId = entity.npc?.trainerId?.trim();

    // Cas 1: pas de trainerId → dialogue normal
    if (trainerId == null || trainerId.isEmpty) {
      _tryOpenDialogue(
        entity.id,
        _resolveNpcDialogueRef(entity),
        entity.inspectorHeadline,
      );
      return;
    }

    // Cas 2: trainer déjà battu → defeat dialogue ou fallback
    if (_storyBranching.isTrainerDefeated(_gameState, trainerId)) {
      debugPrint(
        '[interact] trainer already defeated trainer=$trainerId npc=${entity.id}',
      );
      _openDefeatDialogue(entity);
      return;
    }

    // Cas 3: trainerId invalide → log + fallback dialogue
    final trainer =
        _bundle.manifest.trainers.cast<ProjectTrainerEntry?>().firstWhere(
              (t) => t?.id == trainerId,
              orElse: () => null,
            );
    if (trainer == null) {
      debugPrint(
        '[battle] trainer not found: $trainerId for npc=${entity.id}, fallback to dialogue',
      );
      _showNotification('Dresseur introuvable.');
      _tryOpenDialogue(
        entity.id,
        _resolveNpcDialogueRef(entity),
        entity.inspectorHeadline,
      );
      return;
    }

    // Cas 4: trainer non battu → battle normal
    // Vérifier aussi _triggeredTrainerBattles pour éviter double déclenchement
    if (_triggeredTrainerBattles.contains(entity.id)) {
      debugPrint(
        '[interact] trainer battle already triggered (LoS lock) trainer=$trainerId npc=${entity.id}',
      );
      // Ne pas déclencher un autre battle, mais ne pas bloquer l'interaction non plus
      // Juste ignorer silencieusement
      return;
    }

    final request = buildTrainerBattleRequestFromNpc(
      entity: entity,
      manifest: _bundle.manifest,
      world: _world,
    );
    if (request != null) {
      debugPrint(
        '[battle] trainer battle triggered npc=${entity.id} trainer=$trainerId',
      );
      // Lock ANTI-RETRIGGER avant de déclencher
      _triggeredTrainerBattles.add(entity.id);
      // UNIFIED PATTERN: Store in _pendingBattleRequest, let update() consume it
      // This is consistent with wild encounters and allows proper timing
      _pendingBattleRequest = request;
    }
  }

  void _openDefeatDialogue(MapEntity entity) {
    final defeatRef = entity.npc?.defeatDialogueRef;
    if (defeatRef != null) {
      debugPrint('[interact] opening defeat dialogue npc=${entity.id}');
      _tryOpenDialogue(entity.id, defeatRef, entity.inspectorHeadline);
    } else if (_resolveNpcDialogueRef(entity) != null) {
      debugPrint(
          '[interact] no defeat dialogue, fallback to normal dialogue npc=${entity.id}');
      _tryOpenDialogue(
        entity.id,
        _resolveNpcDialogueRef(entity),
        entity.inspectorHeadline,
      );
    } else {
      debugPrint(
          '[interact] no dialogue for defeated trainer npc=${entity.id}');
      _showNotification('Le dresseur est déjà vaincu.');
    }
  }

  /// DEBUG-ONLY: Marque un trainer comme battu.
  ///
  /// **À n'utiliser qu'en debug/dev pour tester le flux de défaite.**
  /// Tant que le gameplay de combat n'est pas implémenté, ce mécanisme
  /// permet de simuler une victoire pour vérifier le defeat dialogue.
  ///
  /// En production, ce flag devrait être positionné automatiquement
  /// après une vraie victoire en combat.
  void debugMarkTrainerAsDefeated(String trainerId) {
    final trimmedId = trainerId.trim();
    if (trimmedId.isEmpty) {
      debugPrint('[debug] invalid trainerId, ignored');
      return;
    }
    _gameState = _storyFlags.markTrainerDefeated(_gameState, trimmedId);
    debugPrint('[debug] trainer $trimmedId marked as defeated');
    _refreshWorldNpcPresence();
  }

  /// Vérifie la Line of Sight (LoS) des trainers et déclenche automatiquement
  /// le battle si le joueur est détecté.
  ///
  /// **Conditions de déclenchement :**
  /// 1. Runtime stable : overworld, pas de dialogue, pas de battle pending
  /// 2. Trainer avec trainerId valide et lineOfSightRange > 0
  /// 3. Trainer non déjà battu (flag trainer_defeated:{id})
  /// 4. Joueur dans la LoS du trainer (checkLineOfSight)
  /// 5. Trainer pas déjà dans _triggeredTrainerBattles (anti-retrigger)
  ///
  /// **Réarmement :**
  /// - Quand le joueur sort de la LoS → lock retirée
  /// - Sur changement de map → toutes les locks retirées
  ///
  /// **Origine du calcul :**
  /// - Depuis entity.pos du NPC
  /// - Axe cardinal uniquement (nord/sud/est/ouest)
  /// - Aucune diagonale
  /// - Obstacles via world.isBlocked() sur les cases STRICTEMENT entre
  ///   le NPC et le joueur (exclut case du NPC et case du joueur)
  void _checkTrainerLineOfSight() {
    // Condition de stabilité runtime stricte
    if (_flowPhase != _RuntimeFlowPhase.overworld) return;
    if (_dialogueOverlay != null) return;
    if (_pendingBattleRequest != null) return;

    for (final entity in _world.map.entities) {
      if (entity.kind != MapEntityKind.npc) continue;
      if (!_npcPresencePredicateFor(_bundle.manifest)(
        _world.map.id,
        entity,
      )) {
        continue;
      }

      final trainerId = entity.npc?.trainerId;
      if (trainerId == null || trainerId.isEmpty) continue;

      final losRange = entity.npc?.lineOfSightRange ?? 0;
      if (losRange <= 0) continue;

      // Vérifier si déjà battu
      if (_storyBranching.isTrainerDefeated(_gameState, trainerId)) continue;

      // Anti-retrigger : ignorer si déjà déclenché dans cette session
      if (_triggeredTrainerBattles.contains(entity.id)) {
        // Réarmement : si joueur sort de LoS, retirer le lock
        final inLoS = checkLineOfSight(
          npcPos: entity.pos,
          npcFacing: entity.npc!.facing,
          lineOfSightRange: losRange,
          playerPos: _world.player.pos,
          world: _world,
        );
        if (!inLoS) {
          _triggeredTrainerBattles.remove(entity.id);
        }
        continue;
      }

      // Check LoS
      final inLoS = checkLineOfSight(
        npcPos: entity.pos,
        npcFacing: entity.npc!.facing,
        lineOfSightRange: losRange,
        playerPos: _world.player.pos,
        world: _world,
      );

      if (inLoS) {
        // Lock anti-retrigger AVANT de déclencher
        _triggeredTrainerBattles.add(entity.id);
        _triggerTrainerBattle(entity);
      }
    }
  }

  /// Déclenche un battle trainer (appelé par interaction manuelle OU LoS auto).
  ///
  /// **Factorisation :** Cette méthode factorise UNIQUEMENT le démarrage du battle.
  /// Elle ne gère PAS :
  /// - La vérification trainer déjà battu (déjà fait par l'appelant)
  /// - Le defeat dialogue (géré par _handleNpcInteraction pour interaction manuelle)
  ///
  /// **Gestion d'erreur :**
  /// - trainerId invalide → log + notification + pas de crash
  /// - Battle request null → log + pas de battle
  void _triggerTrainerBattle(MapEntity entity) {
    final trainerId = entity.npc?.trainerId;
    if (trainerId == null || trainerId.isEmpty) {
      debugPrint('[trainer] no trainerId for entity=${entity.id}');
      return;
    }

    // Vérifier si déjà battu (pour LoS — interaction manuelle a déjà son check)
    if (_storyBranching.isTrainerDefeated(_gameState, trainerId)) {
      debugPrint('[trainer] already defeated trainer=$trainerId');
      return;
    }

    // Vérifier trainer valide
    final trainer =
        _bundle.manifest.trainers.cast<ProjectTrainerEntry?>().firstWhere(
              (t) => t?.id == trainerId,
              orElse: () => null,
            );
    if (trainer == null) {
      debugPrint('[trainer] not found trainer=$trainerId entity=${entity.id}');
      _showNotification('Dresseur introuvable.');
      return;
    }

    // Créer battle request
    final request = buildTrainerBattleRequestFromNpc(
      entity: entity,
      manifest: _bundle.manifest,
      world: _world,
    );
    if (request != null) {
      debugPrint(
          '[trainer] battle triggered trainer=$trainerId entity=${entity.id}');
      // UNIFIED PATTERN: Store in _pendingBattleRequest, let update() consume it
      // This is consistent with wild encounters and allows proper timing
      _pendingBattleRequest = request;
    } else {
      debugPrint(
          '[trainer] battle request failed trainer=$trainerId entity=${entity.id}');
    }
  }

  void _showNotification(String text) {
    _notification?.removeFromParent();
    final paint = TextPaint(
      style: const TextStyle(
        fontSize: 16,
        color: Colors.white,
        backgroundColor: Color(0xAA000000),
      ),
    );
    final component = TextComponent(
      text: text,
      textRenderer: paint,
      anchor: Anchor.topCenter,
    );
    component.position = Vector2(
      camera.viewport.size.x / 2,
      camera.viewport.size.y - 48,
    );
    camera.viewport.add(component);
    _notification = component;
    Future.delayed(const Duration(seconds: 2), () {
      if (_notification == component) {
        component.removeFromParent();
        _notification = null;
      }
    });
  }

  void _handleWaterBlocked() {
    final delta = _runtimeClockMs - _lastWaterRequiresSurfMessageAtMs;
    if (delta < _kWaterRequiresSurfMessageCooldownMs) {
      return;
    }
    _lastWaterRequiresSurfMessageAtMs = _runtimeClockMs;

    final evaluation = evaluateSurfAttempt(
      gameState: _gameState,
      isTargetWater: true,
    );
    final yarnNode = surfEvaluationToYarnNode(evaluation);
    if (yarnNode == null) {
      return;
    }

    final session = loadSurfDialogueSession(yarnNode);
    if (session == null) {
      debugPrint('[surf] failed to load dialogue node=$yarnNode');
      _showNotification(waterRequiresSurfFeedbackMessage);
      return;
    }

    debugPrint(
        '[surf] evaluation=${evaluation.runtimeType} -> dialogue=$yarnNode');

    if (evaluation is CanPromptSurf) {
      _awaitingSurfConfirmation = true;
    }
    _openDialogue(session);
  }

  /// Sauvegarde l'état actuel de la partie.
  ///
  /// Retourne `true` si la sauvegarde a réussi.
  Future<bool> saveGame() async {
    if (isLoaded) {
      _syncGameStateFromWorld(mapIdOverride: _activeMapId);
    }
    debugPrint(
      '[step_studio_trace] runtime_save_requested map=$_activeMapId completedStepIds=${_gameState.progression.completedStepIds} completedCutsceneIds=${_gameState.progression.completedCutsceneIds}',
    );
    return _saveGameUseCase.execute(_gameState);
  }

  /// Charge l'état de la partie et resync complètement le runtime.
  ///
  /// Retourne `true` si le chargement a réussi.
  /// Retourne `false` si aucune sauvegarde n'existe ou en cas d'échec.
  ///
  /// Effets de bord :
  /// - Modifie `_gameState`
  /// - Modifie `_activeMapId`
  /// - Recharge la map courante
  /// - Reconstruit `_world` avec la position/facing du joueur
  /// - Resync `_player` avec le nouveau `_world`
  /// - Resync caméra / streaming / bounds
  ///
  /// **Note** : Cette méthode ne restaure pas les overlays actifs (dialogue,
  /// battle transition) ni les états transitoires. Elle restaure uniquement
  /// l'état principal du runtime.
  ///
  /// **Limitation** : La phase destructive (à partir de `_gameState = loadedState`)
  /// n'est pas transactionnelle. En cas d'échec pendant le chargement de la map
  /// ou le remontage des layers, le runtime peut rester dans un état partiellement
  /// modifié. Aucun rollback n'est implémenté dans ce lot. Cette limitation sera
  /// adressée dans un futur lot si nécessaire.
  Future<bool> loadGame() async {
    // 1. Charger loadedState
    final rawLoadedState = await _loadGameUseCase.execute();
    if (rawLoadedState == null) {
      debugPrint('[load] no save found');
      return false;
    }
    final loadedState = normalizeLoadedGameState(rawLoadedState);

    // 2. Charger newBundle (avec error handling)
    RuntimeMapBundle newBundle;
    try {
      final loadedBundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: loadedState.currentMapId,
      );
      newBundle = _resolveRuntimeBundle(loadedBundle);
    } catch (e, st) {
      debugPrint('[load] failed to load map: $e\n$st');
      return false;
    }

    // 3. Charger newImages (avec error handling)
    Map<String, ui.Image> newImages;
    try {
      newImages =
          await loadTilesetImagesById(newBundle.tilesetAbsolutePathsById);
    } catch (e, st) {
      debugPrint('[load] failed to load tileset images: $e\n$st');
      return false;
    }

    // 4-16. Phase destructive (protégée par try/catch)
    try {
      // 4. Restaurer GameState
      _gameState = loadedState;

      // 5. Nettoyer l'état transitoire
      _clearTransientUiState();

      // 6. Unmount anciennes maps
      _unmountAllLoadedMaps();

      // 7. Assigner _bundle = newBundle
      _bundle = newBundle;

      // 8. Monter nouvelle map
      await _mountLoadedMap(
        bundle: newBundle,
        tileImagesById: newImages,
        originCellX: 0,
        originCellY: 0,
      );

      // 9. Reconstruire _world
      _world = GameplayWorldState.initial(
        map: newBundle.map,
        project: newBundle.manifest,
        playerPos: loadedState.playerPosition,
        playerFacing: loadedState.playerFacing.asDirection,
        playerMovementMode: loadedState.playerMovementMode,
        npcMapPresencePredicate: _npcPresencePredicateFor(newBundle.manifest),
      );

      // 10. Mettre _activeMapId + reset contrôleur PNJ scripté
      _activeMapId = loadedState.currentMapId;
      _resetScriptedNpcMovementController();

      // 10. Resync _player
      _player.setMapOrigin(Vector2(0, 0), snapToGrid: false);
      _player.syncState(_world.player, snapToGrid: true);

      // 11. Synchroniser GameState
      _syncGameStateFromWorld(mapIdOverride: _activeMapId);

      // 12-15. Resync caméra / streaming / bounds
      _configureCameraViewport();
      _syncCameraToPlayer();
      _preloadActiveMapConnections();
      _pruneLoadedMapsToActiveNeighborhood();
      _applyDebugTileMarker();
      _activeScenarioTriggerIds = _scenarioRuntime.triggerIdsAtPosition(
        map: _bundle.map,
        pos: _world.player.pos,
      );

      _refreshWorldNpcPresence();

      debugPrint('[load] game loaded from saveId=${loadedState.saveId}');
      return true;
    } catch (e, st) {
      debugPrint('[load] failed during destructive phase: $e\n$st');
      return false;
    }
  }

  PlacedBehaviorRuntimeKey _buildPlacedBehaviorCooldownKey({
    required MapPlacedElement element,
    required MapPlacedElementBehavior behavior,
    required MapPlacedElementTriggerType trigger,
  }) {
    final trimmedBehaviorId = behavior.id.trim();
    final behaviorId = trimmedBehaviorId.isEmpty ? 'legacy' : trimmedBehaviorId;
    return PlacedBehaviorRuntimeKey(
      instanceId: element.id,
      behaviorId: behaviorId,
      trigger: trigger,
      effectType: behavior.effect.type,
    );
  }

  Duration? _resolvePlacedBehaviorCooldownOverride(
    MapPlacedElementBehavior behavior,
  ) {
    final cooldownMs = behavior.cooldownMs;
    if (cooldownMs == null) {
      return null;
    }
    if (cooldownMs <= 0) {
      return Duration.zero;
    }
    return Duration(milliseconds: cooldownMs);
  }

  bool _resolvePlacedElementAnimationEnabled(String instanceId) {
    for (final instance in _world.map.placedElements) {
      if (instance.id != instanceId) {
        continue;
      }
      return instance.animation?.enabled ?? false;
    }
    return false;
  }

  void _ensureBehaviorDebugOverlay() {
    if (!_showBehaviorDebugOverlay) {
      return;
    }
    final existing = _behaviorDebugOverlay;
    if (existing != null) {
      existing.text = _lastBehaviorDebugLine;
      return;
    }
    final overlay = TextComponent(
      text: _lastBehaviorDebugLine,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white,
          backgroundColor: Color(0xAA111111),
        ),
      ),
      anchor: Anchor.topLeft,
      position: Vector2(10, 10),
      priority: 30000,
    );
    camera.viewport.add(overlay);
    _behaviorDebugOverlay = overlay;
  }

  void _ensureFpsOverlay() {
    if (!_showFpsOverlay) {
      return;
    }
    final existing = _fpsOverlay;
    if (existing != null) {
      existing.text = 'FPS ${_currentFps.toStringAsFixed(1)}';
      return;
    }
    final overlay = TextComponent(
      text: 'FPS ${_currentFps.toStringAsFixed(1)}',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 12,
          color: Colors.lightGreenAccent,
          backgroundColor: Color(0xAA111111),
          fontWeight: FontWeight.w600,
        ),
      ),
      anchor: Anchor.topLeft,
      position: Vector2(10, 28),
      priority: 30000,
    );
    camera.viewport.add(overlay);
    _fpsOverlay = overlay;
  }

  void _updateFps(double dt) {
    _fpsAccumulatorSeconds += dt;
    _fpsFrameCount += 1;

    // Fenêtre courte de 250ms: stable sans être trop lente.
    if (_fpsAccumulatorSeconds < 0.25) {
      return;
    }
    _currentFps = _fpsFrameCount / _fpsAccumulatorSeconds;
    _fpsAccumulatorSeconds = 0.0;
    _fpsFrameCount = 0;

    if (_showFpsOverlay) {
      _ensureFpsOverlay();
      _fpsOverlay?.text = 'FPS ${_currentFps.toStringAsFixed(1)}';
    }
  }

  void _updateBehaviorDebugLine(String line) {
    _lastBehaviorDebugLine = line;
    if (!_showBehaviorDebugOverlay) {
      return;
    }
    _ensureBehaviorDebugOverlay();
    final overlay = _behaviorDebugOverlay;
    if (overlay == null) {
      return;
    }
    overlay.text = line;
  }

  Future<void> _handleWarp(TriggeredWarp warp) async {
    if (_flowPhase != _RuntimeFlowPhase.overworld) {
      debugPrint('[warp] ignored: flow=${_flowPhase.name}');
      return;
    }
    _flowPhase = _RuntimeFlowPhase.mapTransition;
    final sourceBundle = _bundle;
    final sourceWorld = _world;
    final sourceMapId = _activeMapId;
    final sourcePos = _world.player.pos;
    final sourceFacing = _world.player.facing;
    WarpTransitionOverlayComponent? overlay;
    var swapCompleted = false;
    try {
      _clearTransientUiState();
      overlay = WarpTransitionOverlayComponent(
        viewportSize: camera.viewport.size,
      );
      camera.viewport.add(overlay);
      _warpTransitionOverlay = overlay;
      debugPrint(
        '[warp] start transition warp=${warp.warpId} map=$sourceMapId -> ${warp.targetMapId} target=(${warp.targetPos.x}, ${warp.targetPos.y})',
      );
      final loadedBundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: warp.targetMapId,
      );
      final newBundle = _resolveRuntimeBundle(loadedBundle);
      debugPrint('[warp] target map loaded id=${newBundle.map.id}');
      final transitionSpec = _resolveWarpTransitionSpec(
        sourceMap: sourceBundle.map,
        targetMap: newBundle.map,
      );
      if (transitionSpec.style == _WarpTransitionStyle.fade) {
        debugPrint(
          '[warp] fade out durationMs=${transitionSpec.fadeOut.inMilliseconds}',
        );
        await overlay.fadeOut(duration: transitionSpec.fadeOut);
      }
      if (!_isWithinMapBounds(newBundle.map, warp.targetPos)) {
        throw StateError(
          'warp target out of bounds map=${newBundle.map.id} pos=(${warp.targetPos.x}, ${warp.targetPos.y}) size=${newBundle.map.size.width}x${newBundle.map.size.height}',
        );
      }
      final newWorld = GameplayWorldState.initial(
        map: newBundle.map,
        playerPos: warp.targetPos,
        playerFacing: sourceFacing,
        project: newBundle.manifest,
        tileWidth: newBundle.manifest.settings.tileWidth,
        tileHeight: newBundle.manifest.settings.tileHeight,
        npcMapPresencePredicate: _npcPresencePredicateFor(newBundle.manifest),
      );
      if (newWorld.isBlocked(warp.targetPos.x, warp.targetPos.y)) {
        throw StateError(
          'warp target blocked map=${newBundle.map.id} pos=(${warp.targetPos.x}, ${warp.targetPos.y})',
        );
      }
      debugPrint('[warp] loading target map visuals id=${newBundle.map.id}');
      final newImages =
          await loadTilesetImagesById(newBundle.tilesetAbsolutePathsById);
      _unmountAllLoadedMaps();
      final root = await _mountLoadedMap(
        bundle: newBundle,
        tileImagesById: newImages,
        originCellX: 0,
        originCellY: 0,
      );
      _bundle = newBundle;
      _world = newWorld;
      _activeMapId = newBundle.map.id;
      _previousMapId = null;
      _triggeredTrainerBattles.clear(); // Reset LoS locks on map change
      _resetScriptedNpcMovementController();
      _player.setMapOrigin(_originPixelsOf(root), snapToGrid: false);
      _player.syncState(_world.player, snapToGrid: true);
      _syncGameStateFromWorld(mapIdOverride: _activeMapId);
      swapCompleted = true;
      debugPrint(
        '[warp] player placed at map=${newBundle.map.id} pos=(${_world.player.pos.x}, ${_world.player.pos.y})',
      );
      _configureCameraViewport();
      _syncCameraToPlayer();
      _preloadActiveMapConnections();
      _pruneLoadedMapsToActiveNeighborhood();
      _refreshWorldNpcPresence();
      if (transitionSpec.style == _WarpTransitionStyle.fade) {
        debugPrint(
          '[warp] fade in durationMs=${transitionSpec.fadeIn.inMilliseconds}',
        );
        await overlay.fadeIn(duration: transitionSpec.fadeIn);
      }
      debugPrint('[warp] transition completed');
    } catch (e, st) {
      debugPrint('[warp] transition failed: $e\n$st');
      _showNotification('Warp failed');
      if (!swapCompleted) {
        await _recoverFromWarpFailure(
          sourceBundle: sourceBundle,
          sourceWorld: sourceWorld,
          sourceMapId: sourceMapId,
        );
      }
      if (overlay != null) {
        await overlay.fadeIn(duration: const Duration(milliseconds: 140));
      }
    } finally {
      _warpTransitionOverlay?.close();
      _warpTransitionOverlay = null;
      _flowPhase = _RuntimeFlowPhase.overworld;
      debugPrint(
        '[warp] gameplay unlocked map=$_activeMapId pos=(${_world.player.pos.x}, ${_world.player.pos.y})',
      );
      if (swapCompleted) {
        _activeScenarioTriggerIds = _scenarioRuntime.triggerIdsAtPosition(
          map: _bundle.map,
          pos: _world.player.pos,
        );
        _dispatchScenarioRuntimeSource(
          ScenarioRuntimeSourceEvent.mapEnter(mapId: _activeMapId),
        );
      }
      if (_activeMapId == sourceMapId &&
          _world.player.pos.x == sourcePos.x &&
          _world.player.pos.y == sourcePos.y) {
        _player.syncState(_world.player, snapToGrid: true);
      }
    }
  }

  _WarpTransitionSpec _resolveWarpTransitionSpec({
    required MapData sourceMap,
    required MapData targetMap,
  }) {
    final sourceIndoor = sourceMap.mapMetadata.isIndoor ||
        sourceMap.mapMetadata.mapType == MapType.building ||
        sourceMap.mapMetadata.mapType == MapType.interior ||
        sourceMap.mapMetadata.mapType == MapType.cave ||
        sourceMap.mapMetadata.mapType == MapType.facility;
    final targetIndoor = targetMap.mapMetadata.isIndoor ||
        targetMap.mapMetadata.mapType == MapType.building ||
        targetMap.mapMetadata.mapType == MapType.interior ||
        targetMap.mapMetadata.mapType == MapType.cave ||
        targetMap.mapMetadata.mapType == MapType.facility;
    final duration = sourceIndoor == targetIndoor
        ? const Duration(milliseconds: 170)
        : const Duration(milliseconds: 230);
    return _WarpTransitionSpec(
      style: _WarpTransitionStyle.fade,
      fadeOut: duration,
      fadeIn: duration,
    );
  }

  Future<void> _recoverFromWarpFailure({
    required RuntimeMapBundle sourceBundle,
    required GameplayWorldState sourceWorld,
    required String sourceMapId,
  }) async {
    if (_loadedMapsById.isNotEmpty && _activeMapId == sourceMapId) {
      _bundle = sourceBundle;
      _world = sourceWorld;
      _syncGameStateFromWorld(mapIdOverride: sourceMapId);
      _player.syncState(_world.player, snapToGrid: true);
      _configureCameraViewport();
      _syncCameraToPlayer();
      debugPrint('[warp] rollback no-op (source map still mounted)');
      return;
    }

    try {
      _unmountAllLoadedMaps();
      final loadedFallbackBundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: sourceMapId,
      );
      final fallbackBundle = _resolveRuntimeBundle(loadedFallbackBundle);
      final fallbackWorld = _buildSafeWorldState(
        map: fallbackBundle.map,
        project: fallbackBundle.manifest,
        preferredPos: sourceWorld.player.pos,
        fallbackFacing: sourceWorld.player.facing,
        tileWidth: fallbackBundle.manifest.settings.tileWidth,
        tileHeight: fallbackBundle.manifest.settings.tileHeight,
      );
      final fallbackImages =
          await loadTilesetImagesById(fallbackBundle.tilesetAbsolutePathsById);
      final root = await _mountLoadedMap(
        bundle: fallbackBundle,
        tileImagesById: fallbackImages,
        originCellX: 0,
        originCellY: 0,
      );
      _bundle = fallbackBundle;
      _world = fallbackWorld;
      _activeMapId = fallbackBundle.map.id;
      _previousMapId = null;
      _resetScriptedNpcMovementController();
      _player.setMapOrigin(_originPixelsOf(root), snapToGrid: false);
      _player.syncState(_world.player, snapToGrid: true);
      _syncGameStateFromWorld(mapIdOverride: _activeMapId);
      _configureCameraViewport();
      _syncCameraToPlayer();
      _preloadActiveMapConnections();
      _pruneLoadedMapsToActiveNeighborhood();
      debugPrint(
        '[warp] rollback restored map=${fallbackBundle.map.id} pos=(${_world.player.pos.x}, ${_world.player.pos.y})',
      );
    } catch (e, st) {
      debugPrint('[warp] rollback failed: $e\n$st');
    }
  }

  GameplayWorldState _buildSafeWorldState({
    required MapData map,
    required ProjectManifest project,
    required GridPos preferredPos,
    required Direction fallbackFacing,
    required int tileWidth,
    required int tileHeight,
  }) {
    final safePos = _isWithinMapBounds(map, preferredPos)
        ? preferredPos
        : const GridPos(x: 0, y: 0);
    final world = GameplayWorldState.initial(
      map: map,
      playerPos: safePos,
      playerFacing: fallbackFacing,
      project: project,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      npcMapPresencePredicate: _npcPresencePredicateFor(project),
    );
    if (!world.isBlocked(safePos.x, safePos.y)) {
      return world;
    }

    try {
      final spawn = resolveInitialPlayerSpawn(map);
      final spawnWorld = GameplayWorldState.initial(
        map: map,
        playerPos: spawn.pos,
        playerFacing: fallbackFacing,
        project: project,
        tileWidth: tileWidth,
        tileHeight: tileHeight,
        npcMapPresencePredicate: _npcPresencePredicateFor(project),
      );
      if (!spawnWorld.isBlocked(spawn.pos.x, spawn.pos.y)) {
        return spawnWorld;
      }
    } catch (_) {}

    for (var y = 0; y < map.size.height; y++) {
      for (var x = 0; x < map.size.width; x++) {
        if (!world.isBlocked(x, y)) {
          return GameplayWorldState.initial(
            map: map,
            playerPos: GridPos(x: x, y: y),
            playerFacing: fallbackFacing,
            project: project,
            tileWidth: tileWidth,
            tileHeight: tileHeight,
            npcMapPresencePredicate: _npcPresencePredicateFor(project),
          );
        }
      }
    }

    return world;
  }

  bool _isWithinMapBounds(MapData map, GridPos pos) {
    return pos.x >= 0 &&
        pos.y >= 0 &&
        pos.x < map.size.width &&
        pos.y < map.size.height;
  }

  Future<void> _handleConnection(TriggeredConnection connection) async {
    _flowPhase = _RuntimeFlowPhase.mapTransition;
    var transitionCompleted = false;
    try {
      _clearTransientUiState();
      debugPrint(
        '[connection] attempting map=${_bundle.map.id} direction=${connection.direction.name} target=${connection.targetMapId} offset=${connection.offset} source=(${connection.sourcePos.x}, ${connection.sourcePos.y})',
      );
      final source = _loadedMapsById[_activeMapId];
      if (source == null) {
        debugPrint(
            '[connection] source map visuals missing for id=$_activeMapId');
        _player.syncState(_world.player, snapToGrid: true);
        _showNotification('Connection failed');
        return;
      }
      final target = await _ensureConnectionTargetLoaded(
        source: source,
        connection: connection,
      );
      if (target == null) {
        _player.syncState(_world.player, snapToGrid: true);
        _showNotification('Connection failed');
        return;
      }
      debugPrint('[connection] resolved target map=${target.bundle.map.id}');
      final targetPos = resolveConnectedMapTargetPos(
        sourcePos: connection.sourcePos,
        sourceSize: source.bundle.map.size,
        targetSize: target.bundle.map.size,
        direction: connection.direction,
        offset: connection.offset,
      );
      if (targetPos == null) {
        debugPrint(
          '[connection] invalid entry coordinates direction=${connection.direction.name} offset=${connection.offset} source=(${connection.sourcePos.x}, ${connection.sourcePos.y}) sourceSize=${source.bundle.map.size.width}x${source.bundle.map.size.height} targetSize=${target.bundle.map.size.width}x${target.bundle.map.size.height}',
        );
        _player.syncState(_world.player, snapToGrid: true);
        _showNotification('Connection invalid');
        return;
      }
      debugPrint(
        '[connection] computed entry pos=(${targetPos.x}, ${targetPos.y})',
      );
      final newWorld = GameplayWorldState.initial(
        map: target.bundle.map,
        playerPos: targetPos,
        playerFacing: _world.player.facing,
        project: target.bundle.manifest,
        tileWidth: target.bundle.manifest.settings.tileWidth,
        tileHeight: target.bundle.manifest.settings.tileHeight,
        npcMapPresencePredicate:
            _npcPresencePredicateFor(target.bundle.manifest),
      );
      if (newWorld.isBlocked(targetPos.x, targetPos.y)) {
        debugPrint(
          '[connection] blocked entry map=${target.bundle.map.id} pos=(${targetPos.x}, ${targetPos.y})',
        );
        _player.syncState(_world.player, snapToGrid: true);
        _showNotification('Connection blocked');
        return;
      }
      _bundle = target.bundle;
      _world = newWorld;
      _previousMapId = _activeMapId;
      _activeMapId = target.bundle.map.id;
      _resetScriptedNpcMovementController();
      _syncGameStateFromWorld(mapIdOverride: _activeMapId);
      final fromPx = _player.position.clone();
      final targetOriginPx = _originPixelsOf(target);
      final toPx = Vector2(
        targetOriginPx.x + targetPos.x * _cellWidth,
        targetOriginPx.y + targetPos.y * _cellHeight,
      );
      debugPrint(
        '[connection] player step pixels from=(${fromPx.x.toStringAsFixed(1)}, ${fromPx.y.toStringAsFixed(1)}) to=(${toPx.x.toStringAsFixed(1)}, ${toPx.y.toStringAsFixed(1)})',
      );
      _player.setMapOrigin(targetOriginPx, snapToGrid: false);
      _player.startStep(
        _world.player,
        durationSeconds: PlayerComponent.kDefaultStepSeconds,
      );
      _configureCameraViewport();
      final visibleSize = camera.viewfinder.visibleGameSize;
      debugPrint(
        '[connection] camera after transition focus=(${_player.focusPoint.x.toStringAsFixed(1)}, ${_player.focusPoint.y.toStringAsFixed(1)}) viewport=(${(visibleSize?.x ?? 0).toStringAsFixed(1)}, ${(visibleSize?.y ?? 0).toStringAsFixed(1)})',
      );
      debugPrint(
        '[connection] transition complete -> map=${target.bundle.map.id} pos=(${targetPos.x}, ${targetPos.y})',
      );
      _preloadActiveMapConnections();
      _pruneLoadedMapsToActiveNeighborhood();
      _refreshWorldNpcPresence();
      transitionCompleted = true;
    } catch (e, st) {
      debugPrint('[connection] transition failed: $e\n$st');
      _player.syncState(_world.player, snapToGrid: true);
      _showNotification('Connection failed');
    } finally {
      _flowPhase = _RuntimeFlowPhase.overworld;
      if (transitionCompleted) {
        _activeScenarioTriggerIds = _scenarioRuntime.triggerIdsAtPosition(
          map: _bundle.map,
          pos: _world.player.pos,
        );
        _dispatchScenarioRuntimeSource(
          ScenarioRuntimeSourceEvent.mapEnter(mapId: _activeMapId),
        );
      }
    }
  }

  void _clearTransientUiState() {
    _pendingWarp = null;
    _pendingConnection = null;
    // CRITICAL: Do NOT clear _pendingBattleRequest if a battle is active!
    // This would cancel a pending wild encounter battle.
    // Only clear if we're in overworld phase (no battle in progress).
    if (_flowPhase == _RuntimeFlowPhase.overworld) {
      _pendingBattleRequest = null;
    }
    _pendingPlacedElementBehavior = null;
    _notification?.removeFromParent();
    _notification = null;
    _dialogueOverlay?.removeFromParent();
    _dialogueOverlay = null;
    _battleTransitionOverlay?.removeFromParent();
    _battleTransitionOverlay = null;
    _battleOverlay?.removeFromParent();
    _battleOverlay = null;
    // Blindage défensif lot 10 :
    // ce reset central est utilisé par plusieurs chemins runtime (load, warp,
    // connection). Si un contexte battle survivait ici, on garderait en
    // mémoire un slot party et une requête de combat qui ne correspondent plus
    // à l'état overworld courant. On l'efface donc explicitement avec le reste
    // de l'UI transitoire.
    _activeBattleContext = null;
    _warpTransitionOverlay?.removeFromParent();
    _warpTransitionOverlay = null;
    _pressedKeys.clear();
    _lastMoveKey = null;
  }

  void _unmountAllLoadedMaps() {
    final ids = _loadedMapsById.keys.toList(growable: false);
    for (final id in ids) {
      _unmountLoadedMap(id);
    }
    _loadedMapsById.clear();
    _loadMapFutureById.clear();
  }

  void _applyDebugTileMarker() {
    _debugTileMarkerFill?.removeFromParent();
    _debugTileMarkerFill = null;
    _debugTileMarkerBorder?.removeFromParent();
    _debugTileMarkerBorder = null;
    _debugTileMarkerText?.removeFromParent();
    _debugTileMarkerText = null;

    final pos = _debugTileMarkerPos;
    if (pos == null) {
      return;
    }
    final loaded = _loadedMapsById[_activeMapId];
    if (loaded == null) {
      return;
    }
    final origin = _originPixelsOf(loaded);
    final x = origin.x + pos.x * _cellWidth;
    final y = origin.y + pos.y * _cellHeight;
    final size = Vector2(_cellWidth, _cellHeight);

    final fill = RectangleComponent(
      position: Vector2(x, y),
      size: size,
      paint: ui.Paint()..color = const ui.Color(0x66FF9800),
      priority: 150000,
    );
    final border = RectangleComponent(
      position: Vector2(x, y),
      size: size,
      paint: ui.Paint()
        ..color = const ui.Color(0xFFFF6D00)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 2,
      priority: 150001,
    );
    world.add(fill);
    world.add(border);
    _debugTileMarkerFill = fill;
    _debugTileMarkerBorder = border;

    final label = _debugTileMarkerLabel?.trim();
    if (label == null || label.isEmpty) {
      return;
    }
    final text = TextComponent(
      text: label,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      position: Vector2(x + 2, y + 2),
      priority: 150002,
    );
    world.add(text);
    _debugTileMarkerText = text;
  }

  void _clearNpcCollisionDebugOverlay() {
    final ids = _npcCollisionDebugByEntityId.keys.toList(growable: false);
    for (final id in ids) {
      final visual = _npcCollisionDebugByEntityId.remove(id);
      visual?.spriteRect.removeFromParent();
      visual?.collisionRect.removeFromParent();
      visual?.anchorMarker.removeFromParent();
    }
  }

  void _syncNpcCollisionDebugOverlay() {
    if (!_showNpcCollisionDebugOverlay) {
      _clearNpcCollisionDebugOverlay();
      return;
    }
    final loaded = _loadedMapsById[_activeMapId];
    if (loaded == null) {
      _clearNpcCollisionDebugOverlay();
      return;
    }
    final origin = _originPixelsOf(loaded);
    final seen = <String>{};
    for (final entity in _world.map.entities) {
      if (entity.kind != MapEntityKind.npc) {
        continue;
      }
      final actor = loaded.npcActorByEntityId[entity.id];
      if (actor == null) {
        continue;
      }
      seen.add(entity.id);
      final visual = _npcCollisionDebugByEntityId.putIfAbsent(entity.id, () {
        final spriteRect = RectangleComponent(
          priority: 200000,
          paint: ui.Paint()
            ..color = const ui.Color(0xAA00E5FF)
            ..style = ui.PaintingStyle.stroke
            ..strokeWidth = 2,
        );
        final collisionRect = RectangleComponent(
          priority: 200001,
          paint: ui.Paint()
            ..color = const ui.Color(0xAAFF1744)
            ..style = ui.PaintingStyle.stroke
            ..strokeWidth = 2,
        );
        final anchorMarker = CircleComponent(
          radius: 3.0,
          priority: 200002,
          paint: ui.Paint()..color = const ui.Color(0xFFFFEA00),
        );
        world.add(spriteRect);
        world.add(collisionRect);
        world.add(anchorMarker);
        return _NpcCollisionDebugVisual(
          spriteRect: spriteRect,
          collisionRect: collisionRect,
          anchorMarker: anchorMarker,
        );
      });

      // 1) Bounding box visuelle réelle du sprite.
      visual.spriteRect
        ..position = actor.position.clone()
        ..size = actor.size.clone();

      // 2) Footprint collision gameplay (grille -> pixels).
      final footprint = resolveEntityCollisionFootprint(entity);
      visual.collisionRect
        ..position = Vector2(
          origin.x + footprint.pos.x * _cellWidth,
          origin.y + footprint.pos.y * _cellHeight,
        )
        ..size = Vector2(
          footprint.size.width * _cellWidth,
          footprint.size.height * _cellHeight,
        );

      // 3) Point d'ancrage logique MapEntity.pos (top-left cellule logique).
      visual.anchorMarker.position = Vector2(
        origin.x + entity.pos.x * _cellWidth + (_cellWidth / 2) - 3,
        origin.y + entity.pos.y * _cellHeight + (_cellHeight / 2) - 3,
      );
    }

    final stale = _npcCollisionDebugByEntityId.keys
        .where((id) => !seen.contains(id))
        .toList(growable: false);
    for (final id in stale) {
      final visual = _npcCollisionDebugByEntityId.remove(id);
      visual?.spriteRect.removeFromParent();
      visual?.collisionRect.removeFromParent();
      visual?.anchorMarker.removeFromParent();
    }
  }

  void _unmountLoadedMap(String mapId) {
    _clearNpcCollisionDebugOverlay();
    final loaded = _loadedMapsById.remove(mapId);
    if (loaded == null) {
      return;
    }
    loaded.backgroundLayers.removeFromParent();
    loaded.foregroundLayers.removeFromParent();
    for (final actor in loaded.npcActors) {
      actor.removeFromParent();
      _npcActors.remove(actor);
    }
  }

  Future<_LoadedPlayableMap> _mountLoadedMap({
    required RuntimeMapBundle bundle,
    required Map<String, ui.Image> tileImagesById,
    required int originCellX,
    required int originCellY,
  }) async {
    final npcPred = _npcPresencePredicateFor(bundle.manifest);
    final backgroundLayers = MapLayersComponent(
      bundle: bundle,
      tileImagesByTilesetId: tileImagesById,
      showCollisionOverlay: _showCollisionOverlay,
      npcMapPresencePredicate: npcPred,
    );
    backgroundLayers.position = _originPixels(
      originCellX: originCellX,
      originCellY: originCellY,
    );
    backgroundLayers.priority = 0;
    await world.add(backgroundLayers);

    final foregroundLayers = MapLayersComponent(
      bundle: bundle,
      tileImagesByTilesetId: tileImagesById,
      renderPass: MapLayerRenderPass.foreground,
      showCollisionOverlay: false,
      npcMapPresencePredicate: npcPred,
    );
    foregroundLayers.position = _originPixels(
      originCellX: originCellX,
      originCellY: originCellY,
    );
    foregroundLayers.priority = 100000;
    await world.add(foregroundLayers);

    final npcActors = <OverworldActorComponent>[];
    final npcActorByEntityId = <String, OverworldActorComponent>{};
    final charById = {for (final c in bundle.manifest.characters) c.id: c};
    final cw = bundle.cellWidth;
    final ch = bundle.cellHeight;
    final originPx =
        _originPixels(originCellX: originCellX, originCellY: originCellY);
    for (final entity in bundle.map.entities) {
      if (entity.kind != MapEntityKind.npc) continue;
      if (!npcPred(bundle.map.id, entity)) {
        // Pas de création d'acteur si la règle runtime dit "absent".
        debugPrint(
          '[step_studio_trace] npc_mount_skipped map=${bundle.map.id} entity=${entity.id} reason=presence_predicate_false',
        );
        continue;
      }
      final charId = resolveNpcCharacterId(entity, bundle.manifest);
      if (charId == null || charId.isEmpty) continue;
      final char = charById[charId];
      if (char == null) continue;
      final actor = OverworldActorComponent(
        character: char,
        tileImages: tileImagesById,
        tileWidth: bundle.manifest.settings.tileWidth,
        tileHeight: bundle.manifest.settings.tileHeight,
        cellWidth: cw,
        cellHeight: ch,
        facing: entity.npc?.facing ?? EntityFacing.south,
      );
      actor.configureGridPlacement(
        pos: entity.pos,
        footprint: entity.size,
        mapOrigin: originPx,
        snapToGrid: true,
      );
      npcActors.add(actor);
      npcActorByEntityId[entity.id] = actor;
      _npcActors.add(actor);
      await world.add(actor);
      debugPrint(
        '[step_studio_trace] npc_mount_added map=${bundle.map.id} entity=${entity.id}',
      );
    }

    final loaded = _LoadedPlayableMap(
      bundle: bundle,
      originCellX: originCellX,
      originCellY: originCellY,
      backgroundLayers: backgroundLayers,
      foregroundLayers: foregroundLayers,
      npcActors: npcActors,
      npcActorByEntityId: npcActorByEntityId,
    );
    _loadedMapsById[bundle.map.id] = loaded;
    _applyNpcVisibilityToLoadedMap(loaded);
    return loaded;
  }

  Future<_LoadedPlayableMap?> _ensureConnectionTargetLoaded({
    required _LoadedPlayableMap source,
    required TriggeredConnection connection,
  }) async {
    final targetMapId = connection.targetMapId;
    final existing = _loadedMapsById[targetMapId];
    if (existing != null) {
      final expected = _computeConnectedOriginCells(
        source: source,
        connection: connection,
        targetSize: existing.bundle.map.size,
      );
      if (expected.x != existing.originCellX ||
          expected.y != existing.originCellY) {
        debugPrint(
          '[connection] origin mismatch target=$targetMapId existing=(${existing.originCellX}, ${existing.originCellY}) expected=(${expected.x}, ${expected.y})',
        );
      }
      return existing;
    }
    final inFlight = _loadMapFutureById[targetMapId];
    if (inFlight != null) {
      return await inFlight;
    }

    Future<_LoadedPlayableMap?> load() async {
      try {
        final loadedBundle = await loadRuntimeMapBundle(
          projectFilePath: projectFilePath,
          mapId: targetMapId,
        );
        final bundle = _resolveRuntimeBundle(loadedBundle);
        final origin = _computeConnectedOriginCells(
          source: source,
          connection: connection,
          targetSize: bundle.map.size,
        );
        final images =
            await loadTilesetImagesById(bundle.tilesetAbsolutePathsById);
        final loaded = await _mountLoadedMap(
          bundle: bundle,
          tileImagesById: images,
          originCellX: origin.x,
          originCellY: origin.y,
        );
        debugPrint(
          '[connection] loaded map=${bundle.map.id} origin=(${origin.x}, ${origin.y})',
        );
        return loaded;
      } catch (e, st) {
        debugPrint(
            '[connection] load failed target=$targetMapId error=$e\n$st');
        return null;
      }
    }

    final future = load();
    _loadMapFutureById[targetMapId] = future;
    try {
      return await future;
    } finally {
      final current = _loadMapFutureById[targetMapId];
      if (identical(current, future)) {
        _loadMapFutureById.remove(targetMapId);
      }
    }
  }

  _GridCellPos _computeConnectedOriginCells({
    required _LoadedPlayableMap source,
    required TriggeredConnection connection,
    required GridSize targetSize,
  }) {
    return switch (connection.direction) {
      MapConnectionDirection.east => _GridCellPos(
          x: source.originCellX + source.bundle.map.size.width,
          y: source.originCellY + connection.offset,
        ),
      MapConnectionDirection.west => _GridCellPos(
          x: source.originCellX - targetSize.width,
          y: source.originCellY + connection.offset,
        ),
      MapConnectionDirection.north => _GridCellPos(
          x: source.originCellX + connection.offset,
          y: source.originCellY - targetSize.height,
        ),
      MapConnectionDirection.south => _GridCellPos(
          x: source.originCellX + connection.offset,
          y: source.originCellY + source.bundle.map.size.height,
        ),
    };
  }

  void _preloadActiveMapConnections() {
    final active = _loadedMapsById[_activeMapId];
    if (active == null) {
      return;
    }
    for (final connection in active.bundle.map.connections) {
      _ensureConnectionTargetLoaded(
        source: active,
        connection: TriggeredConnection(
          direction: connection.direction,
          targetMapId: connection.targetMapId,
          offset: connection.offset,
          sourcePos: _world.player.pos,
        ),
      );
    }
  }

  void _pruneLoadedMapsToActiveNeighborhood() {
    final active = _loadedMapsById[_activeMapId];
    if (active == null) {
      return;
    }
    final keep = <String>{
      active.bundle.map.id,
      ...active.bundle.map.connections.map((c) => c.targetMapId),
    };
    final previousMapId = _previousMapId;
    if (previousMapId != null && previousMapId.isNotEmpty) {
      keep.add(previousMapId);
    }
    final toRemove = _loadedMapsById.keys
        .where((id) => !keep.contains(id))
        .toList(growable: false);
    for (final id in toRemove) {
      _unmountLoadedMap(id);
    }
  }

  Vector2 _originPixels({
    required int originCellX,
    required int originCellY,
  }) {
    return Vector2(originCellX * _cellWidth, originCellY * _cellHeight);
  }

  Vector2 _originPixelsOf(_LoadedPlayableMap map) {
    return _originPixels(
      originCellX: map.originCellX,
      originCellY: map.originCellY,
    );
  }

  ProjectCharacterEntry? _resolvePlayerCharacter(RuntimeMapBundle bundle) {
    return resolveDefaultPlayerCharacter(bundle.manifest);
  }

  void _faceNpcTowardPlayer(String entityId) {
    final loaded = _loadedMapsById[_activeMapId];
    final actor = loaded?.npcActorByEntityId[entityId];
    if (actor == null) {
      return;
    }
    final playerFacing = _world.player.facing;
    final npcFacing = switch (playerFacing) {
      Direction.north => EntityFacing.south,
      Direction.south => EntityFacing.north,
      Direction.east => EntityFacing.west,
      Direction.west => EntityFacing.east,
    };
    actor.setMotion(npcFacing, CharacterAnimationState.idle);
  }

  /// Construit le runner cutscene MVP avec callbacks runtime concrets.
  ///
  /// Le runner reste découplé de Flame; `PlayableMapGame` lui injecte juste
  /// les opérations nécessaires.
  CutsceneRuntimeRunner _buildCutsceneRuntimeRunner() {
    return CutsceneRuntimeRunner(
      context: CutsceneRuntimeContext(
        openDialogue: (dialogueId, {startNode}) {
          return _openScenarioDialogueById(
            dialogueId,
            startNode: startNode,
            runtimeSourceId: 'cutscene',
          );
        },
        isDialogueOpen: () => _dialogueOverlay != null,
        requestChoice: (request) {
          _pendingCutsceneChoiceRequest = request;
          return true;
        },
        resolveCutsceneById: _findRuntimeCutsceneById,
        moveNpcTo: ({required entityId, required destination}) {
          return startScriptedNpcMove(
            entityId: entityId,
            destination: destination,
          );
        },
        readNpcMovementStatus: (entityId) {
          return scriptedNpcMovementStatus(entityId);
        },
        faceNpc: ({required entityId, required facing}) {
          return _setNpcFacing(entityId, facing);
        },
        emitOutcome: (outcomeId) {
          _emitCutsceneOutcome(outcomeId);
        },
        setFlag: (flagName) {
          _gameState = _storyFlags.set(_gameState, flagName);
          _refreshWorldNpcPresence();
        },
        clearFlag: (flagName) {
          _gameState = _storyFlags.clear(_gameState, flagName);
          _refreshWorldNpcPresence();
        },
        isFlagSet: (flagName) => _storyFlags.isSet(_gameState, flagName),
        isOutcomeSet: (outcomeId) =>
            _storyFlags.isSet(_gameState, scenarioOutcomeFlagName(outcomeId)),
      ),
    );
  }

  RuntimeCutsceneAsset? _findRuntimeCutsceneById(String cutsceneId) {
    final normalized = cutsceneId.trim();
    if (normalized.isEmpty) {
      return null;
    }
    for (final candidate in runtimeCutscenes) {
      if (candidate.id == normalized) {
        return candidate;
      }
    }
    return null;
  }

  /// Oriente explicitement un PNJ (étape `faceNpc` de cutscene).
  ///
  /// On met à jour:
  /// - l'acteur visuel (immédiat),
  /// - la map runtime en mémoire (facing npc), pour rester cohérent avec les
  ///   futures logiques gameplay lisant l'orientation d'entité.
  bool _setNpcFacing(String entityId, EntityFacing facing) {
    final loaded = _loadedMapsById[_activeMapId];
    final actor = loaded?.npcActorByEntityId[entityId];
    if (actor == null) {
      return false;
    }
    actor.setMotion(facing, CharacterAnimationState.idle);

    final entities = _world.map.entities;
    final index = entities.indexWhere((entity) => entity.id == entityId);
    if (index < 0) {
      return true;
    }
    final entity = entities[index];
    final npc = entity.npc;
    if (npc == null) {
      return true;
    }
    final updatedEntities = List<MapEntity>.from(entities);
    updatedEntities[index] = entity.copyWith(
      npc: npc.copyWith(facing: facing),
    );
    final updatedMap = _world.map.copyWith(entities: updatedEntities);
    _world = GameplayWorldState.initial(
      map: updatedMap,
      playerPos: _world.player.pos,
      playerFacing: _world.player.facing,
      playerMovementMode: _world.player.movementMode,
      project: _bundle.manifest,
      tileWidth: _bundle.manifest.settings.tileWidth,
      tileHeight: _bundle.manifest.settings.tileHeight,
      npcMapPresencePredicate: _npcPresencePredicateFor(_bundle.manifest),
    );
    _bundle = RuntimeMapBundle(
      manifest: _bundle.manifest,
      map: updatedMap,
      projectRootDirectory: _bundle.projectRootDirectory,
      tilesetAbsolutePathsById: _bundle.tilesetAbsolutePathsById,
    );
    return true;
  }

  /// Émet un outcome depuis une cutscene.
  ///
  /// MVP:
  /// 1) on persiste l'outcome comme flag `scenario.outcome.*`,
  /// 2) on tente une transition vers un scénario global via `sourceOutcome`.
  void _emitCutsceneOutcome(String outcomeId) {
    final normalized = outcomeId.trim();
    if (normalized.isEmpty) {
      return;
    }
    _gameState =
        _storyFlags.set(_gameState, scenarioOutcomeFlagName(normalized));
    _refreshWorldNpcPresence();
    _dispatchScenarioRuntimeSource(
      ScenarioRuntimeSourceEvent.outcomeReceived(
        outcomeId: normalized,
      ),
    );
  }

  /// (Re)crée le contrôleur de déplacement scripté pour la map active.
  ///
  /// Cette méthode est appelée:
  /// - au chargement initial,
  /// - après warp/connection/load game (changement de map).
  ///
  /// On repart à chaque fois d'un snapshot propre des PNJ actifs pour éviter
  /// toute dérive d'état entre maps.
  void _resetScriptedNpcMovementController() {
    _runtimeNpcPositions
      ..clear()
      ..addAll(_collectCurrentNpcPositions());
    _runtimeNpcPositions['player'] = _world.player.pos;
    _scriptedNpcReservedOccupiedCellsByEntity.clear();

    final controller = ScriptedEntityMovementController(
      mapSize: _world.map.size,
      isCellBlocked: _isNpcCellBlockedForRoutePlanning,
      startEntityStep: _startScriptedNpcStep,
      isEntityStepping: _isScriptedNpcStepping,
      onEntityPositionCommitted: _commitScriptedNpcPosition,
      validateEntityStep: _validateScriptedNpcStepRuntimeCollision,
    );
    controller.replaceTrackedEntities(_runtimeNpcPositions);
    _scriptedEntityMovementController = controller;
    _applyNpcOverworldDefaultMovement();
  }

  void _applyNpcOverworldDefaultMovement() {
    final controller = _scriptedEntityMovementController;
    if (controller == null) {
      return;
    }
    final pred = _npcPresencePredicateFor(_bundle.manifest);
    final mapId = _world.map.id;
    for (final entity in _world.map.entities) {
      if (entity.kind != MapEntityKind.npc) {
        continue;
      }
      if (!pred(mapId, entity)) {
        controller.stopPatrol(entity.id);
        continue;
      }
      final route = resolveNpcDefaultPatrolRoute(entity);
      if (route == null) {
        controller.stopPatrol(entity.id);
        continue;
      }
      controller.startPatrol(route);
    }
  }

  Map<String, GridPos> _collectCurrentNpcPositions() {
    final loaded = _loadedMapsById[_activeMapId];
    if (loaded == null) {
      return const <String, GridPos>{};
    }
    final pred = _npcPresencePredicateFor(_bundle.manifest);
    final mapId = _world.map.id;
    final byId = <String, GridPos>{};
    for (final entity in _world.map.entities) {
      if (entity.kind != MapEntityKind.npc) {
        continue;
      }
      if (!pred(mapId, entity)) {
        continue;
      }
      // On ne suit que les PNJ présents **et** encore montés en acteur.
      if (!loaded.npcActorByEntityId.containsKey(entity.id)) {
        continue;
      }
      byId[entity.id] = entity.pos;
    }
    return byId;
  }

  bool _isNpcCellBlockedForRoutePlanning(
    int x,
    int y, {
    String? ignoreEntityId,
  }) {
    final normalizedIgnore = ignoreEntityId?.trim();
    if (normalizedIgnore == null || normalizedIgnore.isEmpty) {
      return _world.isBlocked(x, y);
    }
    if (normalizedIgnore == 'player') {
      final mode = _world.player.movementMode;
      if (_world.movementBlockReasonAt(
            x: x,
            y: y,
            movementMode: mode,
          ) !=
          null) {
        return true;
      }
      for (final cell
          in _scriptedNpcDynamicBlockedCells(ignoreEntityId: 'player')) {
        if (cell.x == x && cell.y == y) {
          return true;
        }
      }
      return false;
    }

    // Pathfinding anchor validation:
    // - `x,y` est la position logique MapEntity.pos (top-left),
    // - on valide le footprint collision réel (important pour NPC 2x2),
    // - on ignore l'auto-collision de l'entité courante.
    final probe = evaluateScriptedNpcAnchorPassability(
      world: _world,
      entityId: normalizedIgnore,
      anchorPos: GridPos(x: x, y: y),
      movementMode: MovementMode.walk,
      dynamicBlockedCells: _scriptedNpcDynamicBlockedCells(
        ignoreEntityId: normalizedIgnore,
      ),
    );
    if (!probe.passable) {
      debugPrint(
        '[npc_patrol] blocked anchor entity=$normalizedIgnore anchor=($x,$y) reason="${probe.reason}" footprint=${probe.evaluatedCollisionCells.map((c) => '(${c.x},${c.y})').join(',')}',
      );
    }
    return !probe.passable;
  }

  String? _validateScriptedNpcStepRuntimeCollision({
    required String entityId,
    required GridPos from,
    required GridPos to,
  }) {
    if (entityId.trim() == 'player') {
      final mode = _world.player.movementMode;
      final block = _world.movementBlockReasonAt(
        x: to.x,
        y: to.y,
        movementMode: mode,
      );
      if (block != null) {
        debugPrint(
          '[npc_patrol] runtime step rejected entity=player from=(${from.x},${from.y}) to=(${to.x},${to.y}) reason=${block.name}',
        );
        return block.name;
      }
      for (final cell
          in _scriptedNpcDynamicBlockedCells(ignoreEntityId: 'player')) {
        if (cell.x == to.x && cell.y == to.y) {
          debugPrint(
            '[npc_patrol] runtime step rejected entity=player to=(${to.x},${to.y}) reason=dynamic_blocker',
          );
          return 'Dynamic blocker at destination.';
        }
      }
      return null;
    }
    final probe = evaluateScriptedNpcAnchorPassability(
      world: _world,
      entityId: entityId,
      anchorPos: to,
      movementMode: MovementMode.walk,
      dynamicBlockedCells: _scriptedNpcDynamicBlockedCells(
        ignoreEntityId: entityId,
      ),
    );
    if (!probe.passable) {
      debugPrint(
        '[npc_patrol] runtime step rejected entity=$entityId from=(${from.x},${from.y}) to=(${to.x},${to.y}) reason="${probe.reason}"',
      );
      return probe.reason;
    }
    return null;
  }

  /// Cellules dynamiques à bloquer pour un pas NPC scripté.
  ///
  /// Frontière conceptuelle:
  /// - collision "statique" (layers + entités map) => via GameplayWorldState;
  /// - collision "dynamique" hors map entities (joueur) => injectée ici.
  ///
  /// On inclut volontairement:
  /// 1) la cellule logique canonique du joueur (`_world.player.pos`);
  /// 2) la cellule visuelle actuelle au niveau des pieds du player pendant
  ///    l'interpolation de pas.
  ///
  /// Le point (2) évite les traversées visuelles quand la simulation logique a
  /// déjà commité un déplacement joueur mais que le sprite est encore en train
  /// d'animer son pas.
  Iterable<GridPos> _scriptedNpcDynamicBlockedCells({
    String? ignoreEntityId,
  }) sync* {
    final activeFollowLeader = _pendingScenarioFollowRequest?.leaderEntityId;
    final ignorePlayerForLeader = activeFollowLeader != null &&
        ignoreEntityId != null &&
        ignoreEntityId == activeFollowLeader;

    if (!ignorePlayerForLeader) {
      final canonical = _world.player.pos;
      yield canonical;

      final rendered = _renderedPlayerFootGridCell();
      if (rendered != null &&
          (rendered.x != canonical.x || rendered.y != canonical.y)) {
        yield rendered;
      }
    }

    // Réservations de destination des autres PNJ en cours de pas.
    for (final entry in _scriptedNpcReservedOccupiedCellsByEntity.entries) {
      if (ignoreEntityId != null && entry.key == ignoreEntityId) {
        continue;
      }
      yield* entry.value;
    }
  }

  GridPos? _renderedPlayerFootGridCell() {
    final origin = _player.mapOrigin;
    if (_cellWidth <= 0 || _cellHeight <= 0) {
      return null;
    }
    final foot = _player.footPoint;
    final cellX = ((foot.x - origin.x) / _cellWidth).floor();
    final cellY = ((foot.y - 1 - origin.y) / _cellHeight).floor();
    if (cellX < 0 ||
        cellY < 0 ||
        cellX >= _world.map.size.width ||
        cellY >= _world.map.size.height) {
      return null;
    }
    return GridPos(x: cellX, y: cellY);
  }

  bool _startScriptedNpcStep({
    required String entityId,
    required GridPos from,
    required GridPos to,
    required EntityFacing facing,
    double? durationSeconds,
  }) {
    if (entityId.trim() == 'player') {
      final walkFacing = _directionFromEntityFacing(facing);
      final nextState = _world.player.copyWith(pos: to, facing: walkFacing);
      _player.startStep(
        nextState,
        durationSeconds: durationSeconds ?? PlayerComponent.kDefaultStepSeconds,
      );
      _reserveScriptedNpcStepOccupiedCells(
        entityId: entityId,
        fromAnchorPos: from,
        toAnchorPos: to,
      );
      return true;
    }
    final loaded = _loadedMapsById[_activeMapId];
    final actor = loaded?.npcActorByEntityId[entityId];
    if (actor == null) {
      return false;
    }
    final started = actor.startGridStep(
      to: to,
      facing: facing,
      durationSeconds: durationSeconds ?? PlayerComponent.kDefaultStepSeconds,
    );
    if (!started) {
      _scriptedNpcReservedOccupiedCellsByEntity.remove(entityId);
      return false;
    }
    _reserveScriptedNpcStepOccupiedCells(
      entityId: entityId,
      fromAnchorPos: from,
      toAnchorPos: to,
    );
    return true;
  }

  bool _isScriptedNpcStepping(String entityId) {
    if (entityId.trim() == 'player') {
      return _player.isStepping;
    }
    final loaded = _loadedMapsById[_activeMapId];
    final actor = loaded?.npcActorByEntityId[entityId];
    return actor?.isStepping ?? false;
  }

  void _commitScriptedNpcPosition(String entityId, GridPos position) {
    if (entityId.trim() == 'player') {
      final from = _world.player.pos;
      final facing = _directionBetweenAdjacent(from: from, to: position) ??
          _world.player.facing;
      _world = _world.withPlayer(
        _world.player.copyWith(pos: position, facing: facing),
      );
      _runtimeNpcPositions['player'] = position;
      _scriptedNpcReservedOccupiedCellsByEntity.remove(entityId);
      _player.syncState(_world.player, snapToGrid: true);
      _syncGameStateFromWorld();
      return;
    }
    _runtimeNpcPositions[entityId] = position;
    _scriptedNpcReservedOccupiedCellsByEntity.remove(entityId);
    _world = _world.withEntityPosition(entityId, position);
  }

  bool _isCellReservedByScriptedNpc(GridPos cell) {
    for (final cells in _scriptedNpcReservedOccupiedCellsByEntity.values) {
      if (cells.contains(cell)) {
        return true;
      }
    }
    return false;
  }

  void _reserveScriptedNpcStepOccupiedCells({
    required String entityId,
    required GridPos fromAnchorPos,
    required GridPos toAnchorPos,
  }) {
    if (entityId.trim() == 'player') {
      _scriptedNpcReservedOccupiedCellsByEntity[entityId] = <GridPos>{
        GridPos(x: fromAnchorPos.x, y: fromAnchorPos.y),
        GridPos(x: toAnchorPos.x, y: toAnchorPos.y),
      };
      return;
    }
    final entity = _world.map.entities
        .where((candidate) => candidate.id == entityId)
        .cast<MapEntity?>()
        .firstWhere((candidate) => candidate != null, orElse: () => null);
    if (entity == null) {
      _scriptedNpcReservedOccupiedCellsByEntity.remove(entityId);
      return;
    }

    // Réservation "anti-traversée visuelle":
    // - footprint collision de la destination (cohérence gameplay stricte),
    // - footprint visuel grille du NPC sur source + destination (cohérence
    //   perceptuelle pendant l'interpolation visuelle du sprite).
    final reserved = <GridPos>{}
      ..addAll(_resolveEntityCollisionCellsAtAnchor(entity, toAnchorPos))
      ..addAll(_resolveEntityVisualCellsAtAnchor(entity, fromAnchorPos))
      ..addAll(_resolveEntityVisualCellsAtAnchor(entity, toAnchorPos));
    if (reserved.isEmpty) {
      _scriptedNpcReservedOccupiedCellsByEntity.remove(entityId);
      return;
    }
    _scriptedNpcReservedOccupiedCellsByEntity[entityId] = reserved;
  }

  Set<GridPos> _resolveEntityCollisionCellsAtAnchor(
    MapEntity entity,
    GridPos anchorPos,
  ) {
    final moved = entity.copyWith(pos: anchorPos);
    return resolveEntityCollisionCells(moved).where(_isInMapBounds).toSet();
  }

  Set<GridPos> _resolveEntityVisualCellsAtAnchor(
    MapEntity entity,
    GridPos anchorPos,
  ) {
    final cells = <GridPos>{};
    for (var dy = 0; dy < entity.size.height; dy++) {
      for (var dx = 0; dx < entity.size.width; dx++) {
        final cell = GridPos(
          x: anchorPos.x + dx,
          y: anchorPos.y + dy,
        );
        if (_isInMapBounds(cell)) {
          cells.add(cell);
        }
      }
    }
    return cells;
  }

  bool _isInMapBounds(GridPos cell) {
    return cell.x >= 0 &&
        cell.y >= 0 &&
        cell.x < _world.map.size.width &&
        cell.y < _world.map.size.height;
  }

  double get _cellWidth =>
      _bundle.manifest.settings.tileWidth *
      _bundle.manifest.settings.displayScale;

  double get _cellHeight =>
      _bundle.manifest.settings.tileHeight *
      _bundle.manifest.settings.displayScale;

  void _configureCameraViewport() {
    final cw = _bundle.cellWidth;
    final ch = _bundle.cellHeight;
    final mw = _bundle.map.size.width * cw;
    final mh = _bundle.map.size.height * ch;
    final vw = math.min(_kViewportTilesX * cw, mw);
    final vh = math.min(_kViewportTilesY * ch, mh);
    camera.viewfinder.visibleGameSize = Vector2(vw, vh);
  }

  void _syncCameraToPlayer() {
    if (!isLoaded) {
      return;
    }
    final focus = _player.focusPoint;
    camera.viewfinder.position = Vector2(
      focus.x.roundToDouble(),
      focus.y.roundToDouble(),
    );
  }
}

class _LoadedPlayableMap {
  _LoadedPlayableMap({
    required this.bundle,
    required this.originCellX,
    required this.originCellY,
    required this.backgroundLayers,
    required this.foregroundLayers,
    required this.npcActors,
    required this.npcActorByEntityId,
  });

  final RuntimeMapBundle bundle;
  final int originCellX;
  final int originCellY;
  final MapLayersComponent backgroundLayers;
  final MapLayersComponent foregroundLayers;
  final List<OverworldActorComponent> npcActors;
  final Map<String, OverworldActorComponent> npcActorByEntityId;
}

class _NpcCollisionDebugVisual {
  _NpcCollisionDebugVisual({
    required this.spriteRect,
    required this.collisionRect,
    required this.anchorMarker,
  });

  final RectangleComponent spriteRect;
  final RectangleComponent collisionRect;
  final CircleComponent anchorMarker;
}

class _GridCellPos {
  const _GridCellPos({
    required this.x,
    required this.y,
  });

  final int x;
  final int y;
}

class _PendingScenarioFollowRequest {
  _PendingScenarioFollowRequest({
    required this.leaderEntityId,
    required this.requestedAtMs,
  });

  final String leaderEntityId;
  final double requestedAtMs;
  GridPos? lastLeaderPos;
  Direction? lastLeaderTravelDirection;
  List<GridPos>? cachedPath;
  GridPos? cachedPathDestination;
  GridPos? cachedPathLeaderPos;
  int consecutiveBlockedSteps = 0;
}

class _PendingScenarioTransitionMapRequest {
  const _PendingScenarioTransitionMapRequest({
    required this.mapId,
    required this.warpId,
  });

  final String mapId;
  final String warpId;
}

class _PendingScenarioNpcWarpEntry {
  const _PendingScenarioNpcWarpEntry({
    required this.entityId,
    required this.warpId,
    required this.warpPos,
    required this.approachPos,
  });

  final String entityId;
  final String warpId;
  final GridPos warpPos;
  final GridPos approachPos;
}

class _PendingScenarioMoveContinuation {
  const _PendingScenarioMoveContinuation({
    required this.entityId,
    required this.runtimeSourceId,
    required this.targetKind,
  });

  final String entityId;
  final String runtimeSourceId;
  final String targetKind;
}

class _PendingScenarioReachedEnd {
  const _PendingScenarioReachedEnd({
    required this.scenarioId,
    required this.origin,
    required this.queuedAtMs,
  });

  final String scenarioId;
  final String origin;
  final double queuedAtMs;
}

class _FollowPathPlan {
  const _FollowPathPlan({
    required this.destination,
    required this.path,
  });

  final GridPos destination;
  final List<GridPos> path;
}

enum _WarpTransitionStyle {
  fade,
}

class _WarpTransitionSpec {
  const _WarpTransitionSpec({
    required this.style,
    required this.fadeOut,
    required this.fadeIn,
  });

  final _WarpTransitionStyle style;
  final Duration fadeOut;
  final Duration fadeIn;
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
        'toBattleCombatantData can stamp a stable lineupIndex for BE10 write-back',
        () {
      const seed = RuntimeBattleCombatantSeed(
        speciesId: 'sproutle',
        level: 12,
        maxHp: 36,
        stats: BattleStatsSnapshot(
          attack: 20,
          defense: 16,
          specialAttack: 23,
          specialDefense: 20,
          speed: 17,
        ),
        typing: BattleTypingSnapshot(primaryType: 'grass'),
        abilityId: 'overgrow',
        currentHp: 23,
        moves: <BattleMoveData>[
          BattleMoveData(id: 'growl', name: 'Growl', power: 0),
        ],
      );

      final battleData = seed.toBattleCombatantData(lineupIndex: 2);

      expect(battleData.lineupIndex, equals(2));
      expect(battleData.speciesId, equals('sproutle'));
      expect(battleData.currentHp, equals(23));
    });

    test('preserves the BE8 move subset through the combatant seed contract',
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
          knownMoveIds: <String>[
            'protect',
            'hyper_beam',
            'solar_beam',
            'feint',
          ],
          currentHp: 23,
        ),
      );

      expect(
        seed.moves.map((move) => move.id).toList(growable: false),
        equals(<String>['protect', 'hyper_beam', 'solar_beam', 'feint']),
      );
      expect(
        seed.moves[0].selfVolatileStatus,
        equals(BattleVolatileStatusId.protect),
      );
      expect(seed.moves[1].requiresRecharge, isTrue);
      expect(
        seed.moves[2].chargeThenStrikeEffect?.chargeStateId,
        equals('solar_charge'),
      );
      expect(seed.moves[3].breaksProtect, isTrue);
    });

    test(
        'preserves the BE9 field move subset through the combatant seed contract',
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
          knownMoveIds: <String>['rain_dance', 'sandstorm', 'trick_room'],
          currentHp: 23,
        ),
      );

      expect(
        seed.moves.map((move) => move.id).toList(growable: false),
        equals(<String>['rain_dance', 'sandstorm', 'trick_room']),
      );
      expect(seed.moves[0].target, equals(BattleMoveTarget.field));
      expect(seed.moves[0].weatherEffect, equals(BattleWeatherId.rain));
      expect(seed.moves[1].target, equals(BattleMoveTarget.field));
      expect(seed.moves[1].weatherEffect, equals(BattleWeatherId.sandstorm));
      expect(seed.moves[2].target, equals(BattleMoveTarget.field));
      expect(
        seed.moves[2].pseudoWeatherEffect,
        equals(BattlePseudoWeatherId.trickRoom),
      );
      expect(seed.moves[2].priority, equals(-7));
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
        'keeps a structured supported major status move once BE7 opens applyStatus honestly',
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
          knownMoveIds: <String>['thunder_wave'],
          currentHp: 23,
        ),
      );

      expect(seed.moves, hasLength(1));
      expect(seed.moves.single.id, equals('thunder_wave'));
      expect(
        seed.moves.single.majorStatusEffect?.status,
        equals(BattleMajorStatusId.par),
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
        _moveEntry(
          'protect',
          'Protect',
          0,
          target: PokemonMoveTarget.self,
          pp: 10,
        ),
        _moveEntry('feint', 'Feint', 30, pp: 10),
        _moveEntry('hyper_beam', 'Hyper Beam', 150, pp: 5, accuracy: 90),
        _moveEntry('solar_beam', 'Solar Beam', 120, type: 'grass', pp: 10),
        _moveEntry(
          'rain_dance',
          'Rain Dance',
          0,
          type: 'water',
          target: PokemonMoveTarget.all,
          pp: 5,
        ),
        _moveEntry(
          'sandstorm',
          'Sandstorm',
          0,
          type: 'rock',
          target: PokemonMoveTarget.all,
          pp: 10,
        ),
        _moveEntry(
          'trick_room',
          'Trick Room',
          0,
          type: 'psychic',
          target: PokemonMoveTarget.all,
          pp: 5,
          priority: -7,
          engineSupportLevel: PokemonMoveEngineSupportLevel.structuredPartial,
          unsupportedReasons: const <String>[
            'unsupported_mechanic:turn_order_inversion',
            'showdown_callback:condition.durationCallback',
            'showdown_callback:condition.onFieldEnd',
          ],
        ),
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
  // - `thunder_wave` sert maintenant de move de statut majeur réellement
  //   supporté par le petit sous-ensemble BE7 ;
  // - `rain_dance` / `sandstorm` / `trick_room` servent à prouver que le
  //   builder ne reperd pas les nouveaux champs BE9 pendant la projection ;
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
    'protect' => const <PokemonMoveEffect>[
        PokemonMoveEffect.applyVolatileStatus(
          targetScope: PokemonMoveEffectTargetScope.self,
          volatileStatusId: 'protect',
        ),
      ],
    'feint' => const <PokemonMoveEffect>[
        PokemonMoveEffect.breakProtect(),
      ],
    'hyper_beam' => const <PokemonMoveEffect>[
        PokemonMoveEffect.requireRecharge(),
      ],
    'solar_beam' => const <PokemonMoveEffect>[
        PokemonMoveEffect.chargeThenStrike(
          chargeStateId: 'solar_charge',
        ),
      ],
    'rain_dance' => const <PokemonMoveEffect>[
        PokemonMoveEffect.setWeather(
          targetScope: PokemonMoveEffectTargetScope.field,
          weatherId: 'raindance',
        ),
      ],
    'sandstorm' => const <PokemonMoveEffect>[
        PokemonMoveEffect.setWeather(
          targetScope: PokemonMoveEffectTargetScope.field,
          weatherId: 'sandstorm',
        ),
      ],
    'trick_room' => const <PokemonMoveEffect>[
        PokemonMoveEffect.setPseudoWeather(
          targetScope: PokemonMoveEffectTargetScope.field,
          pseudoWeatherId: 'trickroom',
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

### packages/map_runtime/test/runtime_battle_outcome_apply_test.dart

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/battle_start_request.dart';
import 'package:map_runtime/src/application/runtime_battle_outcome_apply.dart';

const _outcomeTestStats = BattleStatsSnapshot(
  attack: 10,
  defense: 10,
  specialAttack: 10,
  specialDefense: 10,
  speed: 10,
);

void main() {
  group('applyRuntimeBattleOutcomeToGameState', () {
    test('writes back the exact party slot used for the battle handoff', () {
      const initialState = GameState(
        saveId: 'save-slot',
        party: PlayerParty(
          members: <PlayerPokemon>[
            PlayerPokemon(
              speciesId: 'slot_zero',
              natureId: 'hardy',
              abilityId: 'pressure',
              level: 40,
              knownMoveIds: <String>['a'],
              currentHp: 91,
            ),
            PlayerPokemon(
              speciesId: 'slot_one_active',
              natureId: 'bold',
              abilityId: 'overgrow',
              level: 20,
              knownMoveIds: <String>['b'],
              currentHp: 35,
            ),
            PlayerPokemon(
              speciesId: 'slot_two_stays_alive',
              natureId: 'calm',
              abilityId: 'torrent',
              level: 22,
              knownMoveIds: <String>['c'],
              currentHp: 18,
            ),
          ],
        ),
      );

      final updatedState = applyRuntimeBattleOutcomeToGameState(
        gameState: initialState,
        context: RuntimeActiveBattleContext(
          request: _wildRequest(),
          playerPartyIndex: 1,
        ),
        outcome: _finishedOutcome(
          type: BattleOutcomeType.defeat,
          playerCurrentHp: 0,
        ),
      );

      expect(updatedState.party.members[0].currentHp, equals(91));
      expect(updatedState.party.members[1].currentHp, equals(0));
      expect(updatedState.party.members[2].currentHp, equals(18));
    });

    test(
        'writes back every engaged player lineup member to its exact runtime party slot after switches',
        () {
      const initialState = GameState(
        saveId: 'save-switch-lineup',
        party: PlayerParty(
          members: <PlayerPokemon>[
            PlayerPokemon(
              speciesId: 'slot_zero_bench',
              natureId: 'hardy',
              abilityId: 'pressure',
              level: 18,
              knownMoveIds: <String>['a'],
              currentHp: 44,
            ),
            PlayerPokemon(
              speciesId: 'slot_one_initial_active',
              natureId: 'bold',
              abilityId: 'overgrow',
              level: 20,
              knownMoveIds: <String>['b'],
              currentHp: 35,
            ),
            PlayerPokemon(
              speciesId: 'slot_two_unused',
              natureId: 'calm',
              abilityId: 'torrent',
              level: 22,
              knownMoveIds: <String>['c'],
              currentHp: 18,
            ),
          ],
        ),
      );

      const outcome = BattleOutcome(
        type: BattleOutcomeType.victory,
        finalState: BattleState(
          phase: BattlePhase.finished,
          player: BattleCombatant(
            speciesId: 'slot_zero_bench',
            lineupIndex: 1,
            level: 18,
            currentHp: 9,
            maxHp: 44,
            stats: _outcomeTestStats,
            moves: <BattleMove>[
              BattleMove(id: 'a', name: 'a', power: 10),
            ],
          ),
          playerReserve: <BattleCombatant>[
            BattleCombatant(
              speciesId: 'slot_one_initial_active',
              lineupIndex: 0,
              level: 20,
              currentHp: 3,
              maxHp: 35,
              stats: _outcomeTestStats,
              moves: <BattleMove>[
                BattleMove(id: 'b', name: 'b', power: 10),
              ],
            ),
          ],
          enemy: BattleCombatant(
            speciesId: 'enemy',
            level: 20,
            currentHp: 0,
            maxHp: 30,
            stats: _outcomeTestStats,
            moves: <BattleMove>[
              BattleMove(id: 'x', name: 'x', power: 10),
            ],
          ),
          currentTurn: null,
          outcome: null,
        ),
      );

      final updatedState = applyRuntimeBattleOutcomeToGameState(
        gameState: initialState,
        context: RuntimeActiveBattleContext(
          request: _wildRequest(),
          playerPartyIndex: 1,
          playerPartySlotIndicesByLineupIndex: const <int>[1, 0],
        ),
        outcome: outcome,
      );

      expect(updatedState.party.members[0].currentHp, equals(9));
      expect(updatedState.party.members[1].currentHp, equals(3));
      expect(updatedState.party.members[2].currentHp, equals(18));
    });

    test('trainer victory writes player hp and marks trainer as defeated', () {
      final updatedState = applyRuntimeBattleOutcomeToGameState(
        gameState: _baseState(),
        context: RuntimeActiveBattleContext(
          request: _trainerRequest(trainerId: 'ace_jules'),
          playerPartyIndex: 0,
        ),
        outcome: _finishedOutcome(
          type: BattleOutcomeType.victory,
          playerCurrentHp: 14,
        ),
      );

      expect(updatedState.party.members[0].currentHp, equals(14));
      expect(
        updatedState.storyFlags.activeFlags,
        contains('trainer_defeated:ace_jules'),
      );
    });

    test('trainer defeat writes player hp without marking trainer defeated',
        () {
      final updatedState = applyRuntimeBattleOutcomeToGameState(
        gameState: _baseState(),
        context: RuntimeActiveBattleContext(
          request: _trainerRequest(trainerId: 'ace_jules'),
          playerPartyIndex: 0,
        ),
        outcome: _finishedOutcome(
          type: BattleOutcomeType.defeat,
          playerCurrentHp: 0,
        ),
      );

      expect(updatedState.party.members[0].currentHp, equals(0));
      expect(
        updatedState.storyFlags.activeFlags,
        isNot(contains('trainer_defeated:ace_jules')),
      );
    });

    test('runaway writes player hp without marking trainer defeated', () {
      final updatedState = applyRuntimeBattleOutcomeToGameState(
        gameState: _baseState(),
        context: RuntimeActiveBattleContext(
          request: _trainerRequest(trainerId: 'ace_jules'),
          playerPartyIndex: 0,
        ),
        outcome: _finishedOutcome(
          type: BattleOutcomeType.runaway,
          playerCurrentHp: 11,
        ),
      );

      expect(updatedState.party.members[0].currentHp, equals(11));
      expect(
        updatedState.storyFlags.activeFlags,
        isNot(contains('trainer_defeated:ace_jules')),
      );
    });

    test('captured wild battle appends the pokemon and syncs caught/seen', () {
      final updatedState = applyRuntimeBattleOutcomeToGameState(
        gameState: _baseState(),
        context: RuntimeActiveBattleContext(
          request: _wildRequest(),
          playerPartyIndex: 0,
        ),
        outcome: _finishedOutcome(
          type: BattleOutcomeType.captured,
          playerCurrentHp: 19,
          enemySpeciesId: 'wildmon',
          enemyLevel: 12,
          enemyCurrentHp: 7,
          enemyAbilityId: 'intimidate',
          enemyMoveIds: const <String>['scratch', 'leer'],
        ),
      );

      expect(updatedState.party.members[0].currentHp, equals(19));
      expect(updatedState.party.members, hasLength(3));

      final captured = updatedState.party.members.last;
      expect(captured.speciesId, equals('wildmon'));
      expect(captured.level, equals(12));
      expect(captured.abilityId, equals('intimidate'));
      expect(captured.natureId, equals('hardy'));
      expect(captured.knownMoveIds, equals(<String>['scratch', 'leer']));
      expect(captured.currentHp, equals(7));
      expect(
        updatedState.bag.entries,
        equals(
          const <BagEntry>[
            BagEntry(itemId: 'poke-ball', categoryId: 'items', quantity: 1),
            BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 3),
          ],
        ),
      );
      expect(updatedState.progression.caughtSpeciesIds, contains('wildmon'));
      expect(updatedState.progression.seenSpeciesIds, contains('wildmon'));
    });

    test('captured outcome removes the poke-ball entry when quantity reaches 0',
        () {
      final updatedState = applyRuntimeBattleOutcomeToGameState(
        gameState: _baseState().copyWith(
          bag: const Bag(
            entries: <BagEntry>[
              BagEntry(itemId: 'poke-ball', categoryId: 'items', quantity: 1),
              BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 3),
            ],
          ),
        ),
        context: RuntimeActiveBattleContext(
          request: _wildRequest(),
          playerPartyIndex: 0,
        ),
        outcome: _finishedOutcome(
          type: BattleOutcomeType.captured,
          playerCurrentHp: 19,
          enemySpeciesId: 'wildmon',
          enemyLevel: 12,
          enemyCurrentHp: 7,
          enemyAbilityId: 'intimidate',
          enemyMoveIds: const <String>['scratch'],
        ),
      );

      expect(
        updatedState.bag.entries,
        equals(
          const <BagEntry>[
            BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 3),
          ],
        ),
      );
    });

    test('captured outcome is rejected for trainer battles', () {
      expect(
        () => applyRuntimeBattleOutcomeToGameState(
          gameState: _baseState(),
          context: RuntimeActiveBattleContext(
            request: _trainerRequest(trainerId: 'ace_jules'),
            playerPartyIndex: 0,
          ),
          outcome: _finishedOutcome(
            type: BattleOutcomeType.captured,
            playerCurrentHp: 19,
            enemySpeciesId: 'wildmon',
            enemyLevel: 12,
            enemyCurrentHp: 7,
            enemyAbilityId: 'intimidate',
            enemyMoveIds: const <String>['scratch'],
          ),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('captured outcome is rejected when the party is already full', () {
      final fullPartyState = _baseState().copyWith(
        party: PlayerParty(
          members: <PlayerPokemon>[
            ..._baseState().party.members,
            const PlayerPokemon(
              speciesId: 'party_2',
              natureId: 'hardy',
              abilityId: 'pressure',
              level: 10,
              knownMoveIds: <String>['growl'],
              currentHp: 10,
            ),
            const PlayerPokemon(
              speciesId: 'party_3',
              natureId: 'hardy',
              abilityId: 'pressure',
              level: 10,
              knownMoveIds: <String>['growl'],
              currentHp: 10,
            ),
            const PlayerPokemon(
              speciesId: 'party_4',
              natureId: 'hardy',
              abilityId: 'pressure',
              level: 10,
              knownMoveIds: <String>['growl'],
              currentHp: 10,
            ),
            const PlayerPokemon(
              speciesId: 'party_5',
              natureId: 'hardy',
              abilityId: 'pressure',
              level: 10,
              knownMoveIds: <String>['growl'],
              currentHp: 10,
            ),
          ],
        ),
      );

      expect(
        () => applyRuntimeBattleOutcomeToGameState(
          gameState: fullPartyState,
          context: RuntimeActiveBattleContext(
            request: _wildRequest(),
            playerPartyIndex: 0,
          ),
          outcome: _finishedOutcome(
            type: BattleOutcomeType.captured,
            playerCurrentHp: 19,
            enemySpeciesId: 'wildmon',
            enemyLevel: 12,
            enemyCurrentHp: 7,
            enemyAbilityId: 'intimidate',
            enemyMoveIds: const <String>['scratch'],
          ),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('captured outcome is rejected when the bag has no poke-ball', () {
      expect(
        () => applyRuntimeBattleOutcomeToGameState(
          gameState: _baseState().copyWith(
            bag: const Bag(
              entries: <BagEntry>[
                BagEntry(
                  itemId: 'potion',
                  categoryId: 'medicine',
                  quantity: 3,
                ),
              ],
            ),
          ),
          context: RuntimeActiveBattleContext(
            request: _wildRequest(),
            playerPartyIndex: 0,
          ),
          outcome: _finishedOutcome(
            type: BattleOutcomeType.captured,
            playerCurrentHp: 19,
            enemySpeciesId: 'wildmon',
            enemyLevel: 12,
            enemyCurrentHp: 7,
            enemyAbilityId: 'intimidate',
            enemyMoveIds: const <String>['scratch'],
          ),
        ),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('applyRuntimeDefeatRecoveryToGameState', () {
    test(
        'revives the exact battle slot to 1 HP when the whole party is KO after defeat',
        () {
      const defeatedState = GameState(
        saveId: 'whiteout-lite',
        party: PlayerParty(
          members: <PlayerPokemon>[
            PlayerPokemon(
              speciesId: 'slot_zero',
              natureId: 'hardy',
              abilityId: 'pressure',
              level: 12,
              knownMoveIds: <String>['growl'],
              currentHp: 0,
            ),
            PlayerPokemon(
              speciesId: 'active_slot',
              natureId: 'bold',
              abilityId: 'overgrow',
              level: 18,
              knownMoveIds: <String>['vine_whip'],
              currentHp: 0,
            ),
            PlayerPokemon(
              speciesId: 'slot_two',
              natureId: 'calm',
              abilityId: 'torrent',
              level: 17,
              knownMoveIds: <String>['water_gun'],
              currentHp: 0,
            ),
          ],
        ),
      );

      final recoveredState = applyRuntimeDefeatRecoveryToGameState(
        gameState: defeatedState,
        playerPartyIndex: 1,
      );

      expect(recoveredState.party.members[0].currentHp, equals(0));
      expect(recoveredState.party.members[1].currentHp, equals(1));
      expect(recoveredState.party.members[2].currentHp, equals(0));
    });

    test(
        'revives the switched-in active slot instead of the original handoff slot after BE10 switches',
        () {
      const defeatedState = GameState(
        saveId: 'whiteout-lite-switched-active',
        party: PlayerParty(
          members: <PlayerPokemon>[
            PlayerPokemon(
              speciesId: 'initial_active_slot',
              natureId: 'hardy',
              abilityId: 'pressure',
              level: 12,
              knownMoveIds: <String>['growl'],
              currentHp: 0,
            ),
            PlayerPokemon(
              speciesId: 'switched_in_active_slot',
              natureId: 'bold',
              abilityId: 'overgrow',
              level: 18,
              knownMoveIds: <String>['vine_whip'],
              currentHp: 0,
            ),
            PlayerPokemon(
              speciesId: 'unused_slot',
              natureId: 'calm',
              abilityId: 'torrent',
              level: 17,
              knownMoveIds: <String>['water_gun'],
              currentHp: 0,
            ),
          ],
        ),
      );

      final recoveredState = applyRuntimeDefeatRecoveryToGameState(
        gameState: defeatedState,
        playerPartyIndex: 0,
        activePlayerLineupIndex: 1,
        playerPartySlotIndicesByLineupIndex: const <int>[0, 1],
      );

      expect(recoveredState.party.members[0].currentHp, equals(0));
      expect(recoveredState.party.members[1].currentHp, equals(1));
      expect(recoveredState.party.members[2].currentHp, equals(0));
    });

    test('does not heal the party when another member is already usable', () {
      const defeatedState = GameState(
        saveId: 'whiteout-lite-benched',
        party: PlayerParty(
          members: <PlayerPokemon>[
            PlayerPokemon(
              speciesId: 'active_slot',
              natureId: 'bold',
              abilityId: 'overgrow',
              level: 18,
              knownMoveIds: <String>['vine_whip'],
              currentHp: 0,
            ),
            PlayerPokemon(
              speciesId: 'bench_survivor',
              natureId: 'calm',
              abilityId: 'torrent',
              level: 22,
              knownMoveIds: <String>['water_gun'],
              currentHp: 9,
            ),
          ],
        ),
      );

      final recoveredState = applyRuntimeDefeatRecoveryToGameState(
        gameState: defeatedState,
        playerPartyIndex: 0,
      );

      expect(recoveredState.party.members[0].currentHp, equals(0));
      expect(recoveredState.party.members[1].currentHp, equals(9));
    });
  });
}

GameState _baseState() {
  return const GameState(
    saveId: 'save-1',
    bag: Bag(
      entries: <BagEntry>[
        BagEntry(itemId: 'poke-ball', categoryId: 'items', quantity: 2),
        BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 3),
      ],
    ),
    party: PlayerParty(
      members: <PlayerPokemon>[
        PlayerPokemon(
          speciesId: 'sproutle',
          natureId: 'bold',
          abilityId: 'overgrow',
          level: 12,
          knownMoveIds: <String>['growl', 'vine_whip'],
          currentHp: 23,
        ),
        PlayerPokemon(
          speciesId: 'benchmon',
          natureId: 'hardy',
          abilityId: 'pressure',
          level: 18,
          knownMoveIds: <String>['leer'],
          currentHp: 17,
        ),
      ],
    ),
  );
}

BattleOutcome _finishedOutcome({
  required BattleOutcomeType type,
  required int playerCurrentHp,
  String enemySpeciesId = 'aquafi',
  int enemyLevel = 18,
  int enemyCurrentHp = 0,
  String enemyAbilityId = 'torrent',
  List<String> enemyMoveIds = const <String>['water_gun'],
}) {
  final finalState = BattleState(
    phase: BattlePhase.finished,
    player: BattleCombatant(
      speciesId: 'sproutle',
      level: 12,
      currentHp: playerCurrentHp,
      maxHp: 32,
      stats: _outcomeTestStats,
      moves: const <BattleMove>[
        BattleMove(id: 'growl', name: 'Growl', power: 0),
      ],
    ),
    enemy: BattleCombatant(
      speciesId: enemySpeciesId,
      level: enemyLevel,
      currentHp: enemyCurrentHp,
      maxHp: 35,
      stats: _outcomeTestStats,
      abilityId: enemyAbilityId,
      moves: enemyMoveIds
          .map(
            (moveId) => BattleMove(
              id: moveId,
              name: moveId,
              power: 10,
            ),
          )
          .toList(growable: false),
    ),
    currentTurn: null,
    outcome: null,
  );

  return BattleOutcome(
    type: type,
    finalState: finalState,
  );
}

WildBattleStartRequest _wildRequest() {
  return const WildBattleStartRequest(
    requestId: 'wild-request',
    createdAtEpochMs: 1,
    returnContext: OverworldReturnContext(
      mapId: 'field_map',
      playerPos: GridPos(x: 1, y: 1),
      playerFacing: Direction.south,
    ),
    mapId: 'field_map',
    zoneId: 'grass',
    tableId: 'field_grass',
    encounterKind: EncounterKind.walk,
    speciesId: 'wildmon',
    level: 12,
    minLevel: 12,
    maxLevel: 12,
    weight: 30,
    playerPos: GridPos(x: 1, y: 1),
  );
}

TrainerBattleStartRequest _trainerRequest({required String trainerId}) {
  return TrainerBattleStartRequest(
    requestId: 'trainer-request',
    createdAtEpochMs: 1,
    returnContext: const OverworldReturnContext(
      mapId: 'field_map',
      playerPos: GridPos(x: 1, y: 1),
      playerFacing: Direction.south,
    ),
    trainerId: trainerId,
    npcEntityId: 'npc_ace',
    mapId: 'field_map',
    playerPos: const GridPos(x: 1, y: 1),
  );
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

    test(
        'maps player reserves from the real party and excludes bench members already KO',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);
      final setup = await mapper.map(
        bundle: bundle,
        gameState: const GameState(
          saveId: 'save-player-reserve',
          party: PlayerParty(
            members: <PlayerPokemon>[
              PlayerPokemon(
                speciesId: 'sproutle',
                natureId: 'bold',
                abilityId: 'overgrow',
                level: 12,
                knownMoveIds: <String>['growl'],
                currentHp: 23,
              ),
              PlayerPokemon(
                speciesId: 'aquafi',
                natureId: 'calm',
                abilityId: 'torrent',
                level: 18,
                knownMoveIds: <String>['water_gun'],
                currentHp: 17,
              ),
              PlayerPokemon(
                speciesId: 'sparkitten',
                natureId: 'rash',
                abilityId: 'blaze',
                level: 16,
                knownMoveIds: <String>['ember'],
                currentHp: 0,
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
      expect(setup.playerReservePokemon, hasLength(1));
      expect(setup.playerReservePokemon.single.speciesId, equals('aquafi'));
      expect(setup.playerReservePokemon.single.lineupIndex, equals(1));
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
      expect(setup.enemyReservePokemon, isEmpty);
    });

    test('maps trainer reserves instead of stopping at trainer.team.first',
        () async {
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
                moves: <String>['water_gun'],
              ),
              ProjectTrainerPokemonEntry(
                speciesId: 'sparkitten',
                level: 17,
                moves: <String>['ember'],
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

      expect(setup.enemyPokemon.speciesId, equals('aquafi'));
      expect(setup.enemyReservePokemon, hasLength(1));
      expect(setup.enemyReservePokemon.single.speciesId, equals('sparkitten'));
      expect(setup.enemyReservePokemon.single.lineupIndex, equals(1));
    });

    test(
        'mapped trainer multi-mon battle auto-replaces the enemy instead of ending on the first KO',
        () async {
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
                moves: <String>['growl'],
              ),
              ProjectTrainerPokemonEntry(
                speciesId: 'sparkitten',
                level: 17,
                moves: <String>['ember'],
              ),
            ],
          ),
        ],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);
      final setup = await mapper.map(
        bundle: bundle,
        gameState: const GameState(
          saveId: 'save-trainer-reserve',
          party: PlayerParty(
            members: <PlayerPokemon>[
              PlayerPokemon(
                speciesId: 'sproutle',
                natureId: 'bold',
                abilityId: 'overgrow',
                level: 40,
                knownMoveIds: <String>['hyper_beam'],
                currentHp: 99,
              ),
            ],
          ),
        ),
        request: _trainerRequest(),
      );

      final afterTurn = createBattleSession(setup).applyChoice(
        const PlayerBattleChoiceFight(0),
      );

      expect(afterTurn.state.isFinished, isFalse);
      expect(afterTurn.state.enemy.speciesId, equals('sparkitten'));
      expect(
        afterTurn.state.currentTurn!.switchEvents
            .where((event) => event.actor == 'enemy'),
        hasLength(1),
      );
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
        'maps a supported major status move and lets battle consume it honestly',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);

      final setup = await mapper.map(
        bundle: bundle,
        gameState: const GameState(
          saveId: 'save-supported-major-status',
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
      );

      expect(setup.playerPokemon.moves.single.id, equals('thunder_wave'));
      expect(
        setup.playerPokemon.moves.single.majorStatusEffect?.status,
        equals(BattleMajorStatusId.par),
      );

      final session = createBattleSession(setup);
      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterTurn.state.enemy.majorStatus?.id,
          equals(BattleMajorStatusId.par));
      expect(
        afterTurn.state.currentTurn?.statusEvents
            .where((event) => event.kind == BattleStatusEventKind.applied)
            .single
            .sourceMoveId,
        equals('thunder_wave'),
      );
    });

    test(
        'maps a supported requireRecharge move and keeps the forced follow-up honest in battle',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);

      final setup = await mapper.map(
        bundle: bundle,
        gameState: const GameState(
          saveId: 'save-supported-recharge',
          party: PlayerParty(
            members: <PlayerPokemon>[
              PlayerPokemon(
                speciesId: 'sparkitten',
                natureId: 'bold',
                abilityId: 'blaze',
                level: 80,
                knownMoveIds: <String>['hyper_beam'],
                currentHp: 120,
              ),
            ],
          ),
        ),
        request: _wildRequest(
          speciesId: 'aquafi',
          level: 80,
        ),
      );

      expect(setup.playerPokemon.moves.single.requiresRecharge, isTrue);

      final afterAttack = createBattleSession(
        setup,
        rng: const BattleScriptedRng(<int>[1, 24, 24, 24]),
      ).applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterAttack.state.player.volatileState.mustRecharge, isTrue);
      expect(afterAttack.getAvailableChoices().single,
          isA<PlayerBattleChoiceContinue>());

      final afterRecharge =
          afterAttack.applyChoice(const PlayerBattleChoiceContinue());

      expect(afterRecharge.state.player.volatileState.mustRecharge, isFalse);
      expect(
        afterRecharge.state.currentTurn?.volatileEvents
            .where((event) =>
                event.kind == BattleVolatileEventKind.rechargeTurnSpent)
            .single
            .actor,
        equals('player'),
      );
    });

    test('maps a supported weather move and lets battle consume rain honestly',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);

      final rainySetup = await mapper.map(
        bundle: bundle,
        gameState: const GameState(
          saveId: 'save-rain-dance',
          party: PlayerParty(
            members: <PlayerPokemon>[
              PlayerPokemon(
                speciesId: 'aquafi',
                natureId: 'calm',
                abilityId: 'torrent',
                level: 18,
                knownMoveIds: <String>['rain_dance', 'water_gun'],
                currentHp: 42,
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
        rainySetup.playerPokemon.moves.first.weatherEffect,
        equals(BattleWeatherId.rain),
      );

      final rainySession = createBattleSession(rainySetup);
      final afterRain =
          rainySession.applyChoice(const PlayerBattleChoiceFight(0));
      final rainyAttack =
          afterRain.applyChoice(const PlayerBattleChoiceFight(1));
      final rainyDamage = rainyAttack.state.currentTurn!.executions
          .firstWhere((execution) => execution.attacker == 'player')
          .damage;

      final neutralSetup = await mapper.map(
        bundle: bundle,
        gameState: const GameState(
          saveId: 'save-rain-neutral',
          party: PlayerParty(
            members: <PlayerPokemon>[
              PlayerPokemon(
                speciesId: 'aquafi',
                natureId: 'calm',
                abilityId: 'torrent',
                level: 18,
                knownMoveIds: <String>['water_gun'],
                currentHp: 42,
              ),
            ],
          ),
        ),
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
      );

      final neutralDamage = createBattleSession(neutralSetup)
          .applyChoice(const PlayerBattleChoiceFight(0))
          .state
          .currentTurn!
          .executions
          .firstWhere((execution) => execution.attacker == 'player')
          .damage;

      expect(afterRain.state.field.weather?.id, equals(BattleWeatherId.rain));
      expect(
        afterRain.state.currentTurn!.fieldEvents
            .where((event) => event.kind == BattleFieldEventKind.weatherSet)
            .single
            .weather,
        equals(BattleWeatherId.rain),
      );
      expect(rainyDamage, greaterThan(neutralDamage));
    });

    test('maps a supported Trick Room move and lets battle consume it honestly',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);

      final setup = await mapper.map(
        bundle: bundle,
        gameState: const GameState(
          saveId: 'save-trick-room',
          party: PlayerParty(
            members: <PlayerPokemon>[
              PlayerPokemon(
                speciesId: 'sproutle',
                natureId: 'bold',
                abilityId: 'overgrow',
                level: 12,
                knownMoveIds: <String>['trick_room', 'tackle'],
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

      expect(
        setup.playerPokemon.moves.first.pseudoWeatherEffect,
        equals(BattlePseudoWeatherId.trickRoom),
      );
      expect(setup.playerPokemon.moves.first.priority, equals(-7));

      final session = createBattleSession(setup);
      final afterRoom = session.applyChoice(const PlayerBattleChoiceFight(0));
      final afterAttack =
          afterRoom.applyChoice(const PlayerBattleChoiceFight(1));

      expect(
        afterRoom.state.field.pseudoWeather?.id,
        equals(BattlePseudoWeatherId.trickRoom),
      );
      expect(
        afterAttack.state.currentTurn!.executions.first.attacker,
        equals('player'),
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
        _moveEntry(
          'protect',
          'Protect',
          0,
          target: PokemonMoveTarget.self,
          pp: 10,
        ),
        _moveEntry('feint', 'Feint', 30, pp: 10),
        _moveEntry('hyper_beam', 'Hyper Beam', 150, pp: 5, accuracy: 90),
        _moveEntry('solar_beam', 'Solar Beam', 120, type: 'grass', pp: 10),
        _moveEntry(
          'rain_dance',
          'Rain Dance',
          0,
          type: 'water',
          target: PokemonMoveTarget.all,
          pp: 5,
        ),
        _moveEntry(
          'sandstorm',
          'Sandstorm',
          0,
          type: 'rock',
          target: PokemonMoveTarget.all,
          pp: 10,
        ),
        _moveEntry(
          'trick_room',
          'Trick Room',
          0,
          type: 'psychic',
          target: PokemonMoveTarget.all,
          pp: 5,
          priority: -7,
          engineSupportLevel: PokemonMoveEngineSupportLevel.structuredPartial,
          unsupportedReasons: const <String>[
            'unsupported_mechanic:turn_order_inversion',
            'showdown_callback:condition.durationCallback',
            'showdown_callback:condition.onFieldEnd',
          ],
        ),
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
  // Ces fixtures de mapper restent volontairement petites et canoniques :
  // - on encode seulement les effets déjà réellement consommés par le moteur ;
  // - BE9 ajoute ici juste assez de champ pour pluie / tempête de sable /
  //   Trick Room ;
  // - on ne crée pas un faux mini-catalogue parallèle plus riche que le repo.
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
    'protect' => const <PokemonMoveEffect>[
        PokemonMoveEffect.applyVolatileStatus(
          targetScope: PokemonMoveEffectTargetScope.self,
          volatileStatusId: 'protect',
        ),
      ],
    'feint' => const <PokemonMoveEffect>[
        PokemonMoveEffect.breakProtect(),
      ],
    'hyper_beam' => const <PokemonMoveEffect>[
        PokemonMoveEffect.requireRecharge(),
      ],
    'solar_beam' => const <PokemonMoveEffect>[
        PokemonMoveEffect.chargeThenStrike(
          chargeStateId: 'solar_charge',
        ),
      ],
    'rain_dance' => const <PokemonMoveEffect>[
        PokemonMoveEffect.setWeather(
          targetScope: PokemonMoveEffectTargetScope.field,
          weatherId: 'raindance',
        ),
      ],
    'sandstorm' => const <PokemonMoveEffect>[
        PokemonMoveEffect.setWeather(
          targetScope: PokemonMoveEffectTargetScope.field,
          weatherId: 'sandstorm',
        ),
      ],
    'trick_room' => const <PokemonMoveEffect>[
        PokemonMoveEffect.setPseudoWeather(
          targetScope: PokemonMoveEffectTargetScope.field,
          pseudoWeatherId: 'trickroom',
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
