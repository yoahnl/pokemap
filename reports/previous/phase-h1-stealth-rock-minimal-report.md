# Phase H1 — Stealth Rock Minimal Side-Condition Slice

## 1. Résumé exécutif honnête

Verdict honnête : H1 est **réussi**, mais le lot n'a pas été un simple ajout de move. Le vrai travail a été de rendre Stealth Rock honnête de bout en bout sur un slice borné : pose side-level réelle, non-stackabilité, dégâts d'entrée réellement typés, déclenchement sur switch volontaire, auto-switch ennemi et remplacement forcé joueur, timeline observable, et bridge runtime minimal strictement dédié à `stealth_rock`.

Ce qui a réellement changé :
- `BattleSideState` porte maintenant un vrai état side-level vivant pour cette mécanique via `hasStealthRock`.
- Le move local sait porter l'intention Stealth Rock via `setsStealthRock` et un target side-level réel `BattleMoveTarget.opponentSide`.
- Le moteur battle produit désormais une famille d'événements observable strictement dédiée à H1 via `BattleStealthRockEvent`.
- `BattleSession` sait poser Stealth Rock, infliger ses dégâts au bon moment sur les entrées, et raconter cela honnêtement dans `timeline`.
- Le bridge runtime ouvre exactement `setSideCondition(stealthrock)` sur `foeSide`, et rien d'autre.
- Le bootstrap seed embedded ne ment plus sur `stealth_rock` : l'entrée seedée est réalignée sur un support désormais réel.

Ce qui n'a volontairement pas changé :
- aucun autre hazard ;
- aucune mécanique de retrait (`Defog`, `Rapid Spin`, etc.) ;
- aucune ability/item (`Heavy-Duty Boots`, `Magic Bounce`, etc.) ;
- aucune généralisation des side conditions ;
- aucun changement `examples/` ;
- aucun changement `map_core` ;
- aucun changement produit/UI hors affichage honnête de la timeline déjà existante.

Point important : le reviewer séparé a trouvé deux vrais bugs de timing après la première implémentation. Ils ont été corrigés avant conclusion :
- un switch volontaire qui mourait sur Piège de Roc annulait à tort le move adverse déjà en file ;
- la request de remplacement joueur pouvait apparaître avant la fin réelle de la chaîne d'auto-switch ennemi après un double K.O. + Piège de Roc.

## 2. Verdict global

- H1 Stealth Rock minimal était un premier lot H cohérent et borné.
- Le lot livré reste strictement Stealth Rock et n'ouvre pas d'autre slice H.
- Le design retenu est volontairement spécifique et petit ; il ne prétend pas être un framework générique de side conditions.
- Le moteur et le runtime restent verts sur les surfaces utiles après correction des findings review.
- La vérité bootstrap a été réalignée pour `stealth_rock` uniquement.

## 3. Pré-gates exécutés + résultats

Commandes Git read-only exécutées au début :

```bash
git status --short --untracked-files=all
git diff --stat
git ls-files --others --exclude-standard
```

Résultat initial : worktree propre, aucun diff local, aucun untracked.

## 4. Méthode réelle utilisée

1. Audit des reports canoniques A à G, du root `AGENTS.md`, puis audit du code battle/runtime réellement concerné.
2. Vérification de cohérence H1 : Stealth Rock était un bon premier lot H parce que C/D/E/F/G avaient déjà ouvert respectivement request model, side/slot, condition engine, queue et contrats observables suffisants.
3. TDD ciblé : pose, non-stackabilité, dégâts sur switch-in, auto-switch ennemi, remplacement forcé joueur, timeline ; puis ajout des tests rouges sur les bugs trouvés en review.
4. Implémentation minimale : état side-level dédié, move payload dédié, événement dédié, bridge dédié.
5. Validation locale large sur `map_battle`, validation ciblée sur runtime, validation ciblée sur le seed `map_editor`, smoke Phase A.
6. Review séparée réelle ; corrections ; reruns.
7. Report final ultra-complet.

## 5. Audit réel avant code

### 5.1. Ce qui bloquait réellement avant H1

Confirmé par lecture de code :
- `BattleSideState` n'avait aucun état side-level vivant pour un hazard.
- `BattleMoveData` / `BattleMove` ne savaient pas porter honnêtement une pose de side condition minimale.
- `BattleMoveTarget` n'avait pas de vraie cible side-level pour l'adversaire.
- `BattleSession` n'avait aucun point de pose side-level ni aucun déclenchement à l'entrée sur le terrain.
- `BattleTurnResult.timeline` n'avait aucun événement side-level dédié permettant de raconter honnêtement Stealth Rock.
- `runtime_battle_move_bridge.dart` rejetait encore `setSideCondition` comme hors subset honnête.

### 5.2. Ce qui était déjà suffisant et qu'il ne fallait pas rouvrir

Confirmé par lecture de code :
- Phase C : `decisionRequest` existait déjà réellement.
- Phase D : `playerSide` / `enemySide` + `activeSlotRef` suffisaient pour un hazard singles side-level.
- Phase E : pas besoin d'ouvrir un nouveau mini event engine plus large ; le timing pouvait être traité localement dans les seams d'entrée déjà identifiés.
- Phase F : la queue existait déjà et permettait d'insérer explicitement des étapes et de rendre le scheduling lisible.
- Phase G : les contrats observables étaient assez riches pour ajouter une petite famille d'événements sans regonfler toute l'architecture.

### 5.3. Conclusion d'audit

Conclusion retenue : H1 Stealth Rock était **justifié**.

Le lot n'exigeait pas :
- une refonte Phase E ;
- une refonte Phase F ;
- un système générique de side conditions.

Le plus petit design honnête était donc :
- un état side-level dédié sur `BattleSideState` ;
- un move payload dédié ;
- un événement dédié ;
- un bridge dédié ;
- des déclenchements dans les seams de switch déjà réels.

## 6. Critique explicite du prompt

### 6.1. Ce qui était juste

- Le prompt avait raison de forcer un lot Stealth Rock seulement.
- Il avait raison d'interdire tout framework générique de hazards.
- Il avait raison d'exiger une vraie review séparée, parce qu'elle a trouvé deux bugs réels.
- Il avait raison d'imposer TDD : les deux bugs review ont été verrouillés ensuite par tests rouges puis corrigés proprement.

### 6.2. Ce qui était discutable

- Le prompt interdisait `packages/map_editor/**`, mais exigeait aussi explicitement de réaligner honnêtement le bootstrap seed si `stealth_rock` devenait réellement supporté. Ces deux exigences entraient en tension. J'ai choisi la plus petite entorse honnête : un seul réalignement local de l'entrée seed `stealth_rock`.
- Le prompt supposait implicitement que Stealth Rock n'exigerait pas de seam de continuation de tour supplémentaire. La review a montré qu'un cas réel de timing existe : un switch volontaire peut mourir sur l'entrée avant qu'une action adverse déjà en file n'ait été consommée. Pour rester honnête, il a fallu ajouter une continuation de tour **strictement bornée à ce cas**.

### 6.3. Ce qui aurait été dangereux si suivi aveuglément

- Refuser toute petite continuation de tour sous prétexte de scope aurait laissé un faux scheduling : le move adverse était annulé à tort.
- Refuser toute mise à jour bootstrap aurait laissé un mensonge seed/runtime explicite sur `stealth_rock`.

## 7. Périmètre inclus / exclu

### Inclus
- `packages/map_battle/**`
- runtime minimal strictement nécessaire : bridge + formatting overlay + tests runtime déjà branchés à la prod
- un réalignement seed minimal dans `packages/map_editor` pour `stealth_rock` seulement
- report final

### Exclus volontairement
- `examples/**`
- `packages/map_core/**`
- toute autre mécanique hazard
- tout retrait de hazard
- abilities/items
- selfSwitch / forceSwitch
- tout système générique de side conditions
- tout targeting riche
- tout doubles

## 8. Design retenu

### 8.1. Design choisi

Design retenu : **Stealth-Rock-only slice**.

Éléments principaux :
- `BattleSideState.hasStealthRock` comme état side-level vivant ;
- `BattleMoveTarget.opponentSide` comme vraie cible locale side-level ;
- `BattleMoveData.setsStealthRock` et `BattleMove.setsStealthRock` comme payload minimal ;
- `battle_stealth_rock.dart` pour :
  - la famille d'événements observable H1 ;
  - la formule de dégâts d'entrée ;
- timeline enrichie via `BattleTurnStealthRockEvent` ;
- déclenchement localisé dans les seams réels de switch/auto-switch/replacement ;
- bridge runtime exact pour `stealth_rock` et rien d'autre.

### 8.2. Pourquoi ce design est le bon ici

- Il donne un vrai état side-level utilisé en prod immédiatement.
- Il ne crée pas de conteneur générique de hazards.
- Il garde les frontières H1 très nettes : aucun autre hazard n'entre par “bonus”.
- Il rend Stealth Rock observable dans la timeline sans inventer une hiérarchie d'événements multi-domaines plus large.

### 8.3. Ce qui a été refusé

- `Map<SideConditionId, SideConditionState>` générique : rejeté comme champ/framework mort.
- registry générique de hazards : rejeté.
- bridge `setSideCondition` générique : rejeté.
- side-condition engine séparé : rejeté.
- ouverture de toute la famille hazards : rejetée.

## 9. Justification fichier par fichier

- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_stealth_rock.dart`
  - Nouveau fichier dédié H1 : dégâts d'entrée + événements observables Stealth Rock.
- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/map_battle.dart`
  - Export du nouveau slice battle.
- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_move.dart`
  - Cible side-level minimale et payload move minimal.
- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_setup.dart`
  - Handoff setup -> battle du payload `setsStealthRock`.
- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_state.dart`
  - État side-level vivant `hasStealthRock`.
- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_resolution.dart`
  - Événements observables Stealth Rock et exécutions side-level.
- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_queue.dart`
  - Drain restant explicite pour suspendre honnêtement un tour sur remplacement forcé mid-turn H1.
- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart`
  - Pose, déclenchement, timing, suspension/reprise de tour, ordering auto-switch/replacement.
- `/Users/karim/Project/pokemonProject/packages/map_battle/test/battle_stealth_rock_test.dart`
  - TDD H1 + régressions review.
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart`
  - Bridge minimal `stealth_rock` seulement.
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`
  - Formatage overlay honnête des événements Stealth Rock.
- `/Users/karim/Project/pokemonProject/packages/map_runtime/test/runtime_battle_move_bridge_test.dart`
  - Preuve que seul `stealth_rock` est ouvert côté bridge.
- `/Users/karim/Project/pokemonProject/packages/map_runtime/test/battle_overlay_component_test.dart`
  - Preuve timeline/overlay.
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart`
  - Réalignement de vérité seed pour `stealth_rock` uniquement.

## 10. Classification des blockers réellement adressés

### Blockers adressés

- `required_now`
  - vrai état side-level pour Stealth Rock
  - vrai payload move pour poser Stealth Rock
  - vraie cible side-level adverse
  - vraie observabilité timeline de pose et de dégâts
  - vrai bridge runtime pour `setSideCondition(stealthrock)`
  - vrai scheduling de déclenchement sur les entrées supportées

- `not_required_yet`
  - conteneur générique de side conditions
  - prise en charge de plusieurs hazards
  - retrait de hazards
  - boots / bounce / defog / spin
  - slot conditions actives

- `rejected_dead_field`
  - `sideConditions` générique
  - `sideConditionMetadata`
  - enums/registries de hazards hors Stealth Rock

- `belongs_to_H_not_this_H1`
  - Spikes / Toxic Spikes / Sticky Web
  - retrait et interaction avec items/abilities
  - forced switch / self switch génériques
  - side-condition framework plus large s'il devient justifié

## 11. Contrats changés / non changés et pourquoi

- `BattleMove` : **changé**
  - pourquoi : H1 avait besoin d'un payload move vivant et d'un vrai target side-level.
  - lien avec H1 : direct.
  - lien avec H futur : utile pour d'autres slices, mais la forme retenue reste volontairement spécifique à Stealth Rock.

- `BattleSetup` / `BattleMoveData` : **changé**
  - pourquoi : le handoff runtime -> battle devait pouvoir transporter honnêtement Stealth Rock.

- `BattleState` / `BattleSideState` : **changé**
  - pourquoi : il fallait enfin un vrai état side-level vivant.

- `BattleFieldState` : **non changé**
  - pourquoi : Stealth Rock vit côté side, pas côté field.
  - justification de non-ajout : aucun champ field n'était requis.

- `BattleVolatileState` : **non changé**
  - pourquoi : Stealth Rock n'est pas un volatile.

- `BattleCombatant` : **non changé**
  - pourquoi : les dégâts d'entrée lisent un état déjà suffisant (HP max + typing).

- `BattleResolution` : **changé**
  - pourquoi : il fallait des événements observables honnêtes, plus un target side-level pour les moves concernés.

- `BattleConditionEngine` : **non changé**
  - pourquoi : H1 n'avait pas besoin d'un nouveau runner générique.
  - justification : le timing pertinent vivait dans les seams d'entrée/switch déjà existants.

- `BattleQueue` : **changé minimalement**
  - pourquoi : un vrai cas H1 imposait de suspendre puis reprendre un tour quand un switch-in joueur mourait sur entrée avec une action adverse encore en file.
  - justification : ce n'est pas une nouvelle queue Phase F, mais une extension locale d'honnêteté causale.

## 12. Commandes réellement exécutées

### Audit / lecture

```bash
git status --short --untracked-files=all
git diff --stat
git ls-files --others --exclude-standard
rg --files packages/map_editor/test
sed -n '1,220p' /Users/karim/.codex/plugins/cache/openai-curated/superpowers/314574a046f21938025ae443f9c6dbbd0c2c9b7a/skills/systematic-debugging/SKILL.md
sed -n '1,120p' pokemon-showdown-master/test/sim/misc/hazards.js
sed -n '1,220p' pokemon-showdown-master/test/common.js
sed -n '1,220p' pokemon-showdown-master/sim/battle-actions.ts
sed -n '2720,2815p' pokemon-showdown-master/sim/battle.ts
rg -n "stealthrock|switchIn|entry hazard|replacementRequired|fainted on switch" pokemon-showdown-master/sim pokemon-showdown-master/test
rg -n "switch 2.*stealthrock|stealth rock.*switch|faints to rocks|\[from\] Stealth Rock|switch 2" pokemon-showdown-master/test/sim -g '*.js' | head -n 80
```

### Format / analyze / tests

```bash
dart format packages/map_battle/lib/map_battle.dart packages/map_battle/lib/src/battle_stealth_rock.dart packages/map_battle/lib/src/battle_move.dart packages/map_battle/lib/src/battle_setup.dart packages/map_battle/lib/src/battle_state.dart packages/map_battle/lib/src/battle_resolution.dart packages/map_battle/lib/src/battle_session.dart packages/map_battle/test/battle_stealth_rock_test.dart packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart packages/map_runtime/test/runtime_battle_move_bridge_test.dart packages/map_runtime/test/battle_overlay_component_test.dart packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart
cd packages/map_battle && dart test test/battle_stealth_rock_test.dart
cd packages/map_runtime && flutter test test/runtime_battle_move_bridge_test.dart test/battle_overlay_component_test.dart
cd packages/map_battle && dart analyze lib test
cd packages/map_runtime && flutter analyze --no-pub lib test
cd packages/map_editor && flutter analyze --no-pub lib test
cd packages/map_runtime && flutter analyze --no-pub lib/src/application/runtime_battle_move_bridge.dart lib/src/presentation/flame/battle_overlay_component.dart test/runtime_battle_move_bridge_test.dart test/battle_overlay_component_test.dart test/phase_a_golden_battle_slice_smoke_test.dart
cd packages/map_editor && flutter analyze --no-pub lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart test/pokemon_moves_bootstrap_seed_test.dart
cd packages/map_battle && dart test
cd packages/map_runtime && flutter test test/runtime_battle_move_bridge_test.dart test/battle_overlay_component_test.dart test/runtime_battle_setup_mapper_test.dart test/phase_a_golden_battle_slice_smoke_test.dart
cd packages/map_editor && flutter test test/pokemon_moves_bootstrap_seed_test.dart
```

### Reproduction / diagnostic local pendant le débug review

```bash
nl -ba packages/map_battle/lib/src/battle_session.dart | sed -n '960,1165p'
sed -n '1,320p' packages/map_battle/test/battle_stealth_rock_test.dart
wc -l packages/map_battle/lib/map_battle.dart packages/map_battle/lib/src/battle_move.dart packages/map_battle/lib/src/battle_queue.dart packages/map_battle/lib/src/battle_resolution.dart packages/map_battle/lib/src/battle_session.dart packages/map_battle/lib/src/battle_setup.dart packages/map_battle/lib/src/battle_state.dart packages/map_battle/lib/src/battle_stealth_rock.dart packages/map_battle/test/battle_stealth_rock_test.dart packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart packages/map_runtime/test/battle_overlay_component_test.dart packages/map_runtime/test/runtime_battle_move_bridge_test.dart packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart
node /tmp/ps_stealthrock_switch_test.js
```

## 13. Résultats réels analyze / tests / smoke

### Confirmé par exécution

- `packages/map_battle`: `dart analyze lib test` -> vert.
- `packages/map_battle`: `dart test` complet -> vert.
- `packages/map_runtime`: analyze package-wide -> **rouge**, mais uniquement à cause de lints/informations historiques préexistants sans rapport avec H1.
- `packages/map_runtime`: analyze ciblé sur les fichiers touchés + smoke -> vert.
- `packages/map_runtime`: tests ciblés `runtime_battle_move_bridge_test.dart`, `battle_overlay_component_test.dart`, `runtime_battle_setup_mapper_test.dart`, `phase_a_golden_battle_slice_smoke_test.dart` -> verts.
- `packages/map_editor`: analyze package-wide -> **rouge**, également à cause d'un bruit historique préexistant ; pas causé par H1.
- `packages/map_editor`: analyze ciblé `pokemon_moves_bootstrap_seed.dart` + test associé -> vert.
- `packages/map_editor`: `flutter test test/pokemon_moves_bootstrap_seed_test.dart` -> vert.

### Confirmé par lecture de code

- la pose Stealth Rock est strictement dédiée à `stealth_rock` ;
- le bridge n'ouvre pas `setSideCondition` générique ;
- le state side-level est vivant et consommé ;
- les dégâts d'entrée lisent le type chart réel local ;
- la queue est réellement consommée ;
- le timing d'auto-switch et de replacement est désormais explicitement séquencé.

### Inférence raisonnable

- le slice H1 est suffisamment propre pour ouvrir plus tard un prochain hazard slice ciblé, mais sans réutiliser aveuglément toutes les structures telles quelles.

### Point incertain / non vérifié directement

- je n'ai pas pu exécuter le simulateur Showdown localement, car `pokemon-showdown-master/test/common.js` dépend d'un `dist/sim` absent dans cet état du dépôt. La lecture source Showdown a été utilisée comme référence textuelle, mais la règle exacte du simulateur n'a pas été rejouée localement de bout en bout.

## 14. Incidents rencontrés

1. `flutter analyze --no-pub lib test` sur `map_runtime` a échoué sur 154 issues historiques préexistantes ; le lot H1 n'a pas tenté de nettoyer ce bruit hors scope.
2. `flutter analyze --no-pub lib test` sur `map_editor` a échoué sur 162 issues historiques préexistantes ; même décision.
3. Le premier passage reviewer a trouvé deux bugs réels de timing ; ils ont nécessité une correction battle supplémentaire dans `battle_session.dart`.
4. La tentative d'exécuter un petit harness Node contre `pokemon-showdown-master/test/common.js` a échoué car `./../dist/sim` est absent localement.

## 15. Décisions retenues / rejetées

### Retenues
- Stealth Rock seulement.
- état side-level dédié.
- payload move dédié.
- événement dédié.
- bridge dédié.
- continuation de tour strictement bornée au cas “switch-in joueur meurt sur SR avant une action adverse déjà en file”.

### Rejetées
- side conditions génériques.
- hazards génériques.
- retrait de hazards.
- runtime UI plus large.
- refonte de queue générale.
- ouverture abilities/items.

## 16. Retour des sub-agents

### Audit/design battle-core

Sub-agent : Aristotle.

Apport :
- a confirmé que H1 Stealth Rock était cohérent avec C/D/E/F/G ;
- a recommandé un état side-level dédié, un move payload minimal et des déclenchements localisés dans les seams de switch.

Retenu : oui, sur le fond.

Rejeté : la tentation de généraliser plus tôt l'état side-level n'a pas été retenue.

### Scope creep

Sub-agent : Copernicus.

Apport :
- a explicitement refusé tout registry générique de side conditions/hazards ;
- a recommandé un bridge Stealth-Rock-only.

Retenu : oui, intégralement.

## 17. Retour du reviewer séparé

### Reviewer principal

Reviewer : Erdos.

Findings initiaux retenus :
- `[P1]` un switch volontaire dont l'entrant meurt sur Stealth Rock annulait à tort le move adverse déjà en file ;
- `[P2]` la request de remplacement joueur pouvait être racontée avant la fin réelle de la chaîne d'auto-switch ennemi.

Reviewer corroborant : Dalton.

Finding corroborant retenu :
- duplication du `[P1]` sur le switch volontaire K.O. sur entrée.

Re-review final Erdos après corrections :
- « no remaining concrete findings. The two prior timing regressions appear fixed, and I did not find a new concrete issue in the pending-turn continuation path. »

## 18. Corrections appliquées après review

1. Ajout d'une continuation de tour locale et strictement bornée quand un switch-in joueur meurt sur Stealth Rock avant une action adverse encore en file.
2. Ajout d'une suspension/reprise de queue honnête au lieu d'un auto-pick mensonger de remplaçant joueur.
3. Déplacement de la `replacementRequired` joueur après stabilisation complète de la chaîne d'auto-switch ennemi.
4. Ajout de tests rouges puis verts couvrant :
   - reprise du move adverse après remplacement ;
   - ordering auto-switch ennemi -> replacement joueur ;
   - absence de faux replacement joueur si la dernière réserve ennemie meurt sur SR.

## 19. Autocritique finale

Ce lot est bon, mais il a une limite claire qu'il faut dire explicitement :
- la continuation de tour ajoutée n'est pas un scheduler d'interruptions générique ;
- c'est un seam strictement borné au cas H1 où un remplacement joueur devient nécessaire en plein tour à cause de Stealth Rock ;
- si de futurs lots H ouvrent d'autres mécaniques d'interruption mid-turn, il faudra réévaluer honnêtement si ce seam reste suffisant ou s'il faut un vrai contrat plus large.

Autre point à garder en tête :
- le seed `stealth_rock` reste physiquement dans le bloc historique `_catalogOnlySeedMoves`, avec un commentaire d'exception et un support désormais honnête ; c'est défendable pour minimiser le diff, mais ce n'est pas la structure la plus élégante à long terme.

## 20. État git final utile

```text
 M packages/map_battle/lib/map_battle.dart
 M packages/map_battle/lib/src/battle_move.dart
 M packages/map_battle/lib/src/battle_queue.dart
 M packages/map_battle/lib/src/battle_resolution.dart
 M packages/map_battle/lib/src/battle_session.dart
 M packages/map_battle/lib/src/battle_setup.dart
 M packages/map_battle/lib/src/battle_state.dart
 M packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart
 M packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart
 M packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart
 M packages/map_runtime/test/battle_overlay_component_test.dart
 M packages/map_runtime/test/runtime_battle_move_bridge_test.dart
?? packages/map_battle/lib/src/battle_stealth_rock.dart
?? packages/map_battle/test/battle_stealth_rock_test.dart
?? reports/phase-h1-stealth-rock-minimal-report.md
```

```text
 packages/map_battle/lib/map_battle.dart            |   1 +
 packages/map_battle/lib/src/battle_move.dart       |  14 +
 packages/map_battle/lib/src/battle_queue.dart      |  15 +
 packages/map_battle/lib/src/battle_resolution.dart |  47 +-
 packages/map_battle/lib/src/battle_session.dart    | 498 +++++++++++++++++++--
 packages/map_battle/lib/src/battle_setup.dart      |  11 +
 packages/map_battle/lib/src/battle_state.dart      |  22 +
 .../seeds/pokemon_moves_bootstrap_seed.dart        |  10 +-
 .../application/runtime_battle_move_bridge.dart    | 108 ++++-
 .../flame/battle_overlay_component.dart            |  14 +
 .../test/battle_overlay_component_test.dart        |  86 ++++
 .../test/runtime_battle_move_bridge_test.dart      |  36 +-
 12 files changed, 818 insertions(+), 44 deletions(-)
```

```text
packages/map_battle/lib/src/battle_stealth_rock.dart
packages/map_battle/test/battle_stealth_rock_test.dart
reports/phase-h1-stealth-rock-minimal-report.md
```

## 21. Checklist finale

- [x] ai-je bien implémenté uniquement Stealth Rock et rien d'autre ?
- [x] ai-je refusé tout élargissement mort ?
- [x] les side conditions ajoutées sont-elles réellement vivantes ?
- [x] le déclenchement sur switch-in est-il honnête ?
- [x] l'auto-switch ennemi est-il bien couvert ?
- [x] le remplacement forcé joueur est-il bien couvert ?
- [x] la timeline reste-t-elle honnête ?
- [x] ai-je évité d'ouvrir selfSwitch / forceSwitch / hazards génériques ?
- [x] ai-je relancé analyze/tests/smoke ?
- [x] ai-je fait une vraie review séparée ?
- [x] ai-je inclus le contenu complet des fichiers touchés ?
- [x] ai-je explicitement signalé les limites restantes ?

## 22. Décision finale : H1 réussi ou non

Décision nette : **H1 réussi**.

## 23. Ce que ce lot débloque exactement pour la suite

H1 débloque réellement :
- un premier hazard side-level honnête ;
- un vrai lieu de vie side-level pour une mécanique hazard en prod ;
- une observabilité timeline side-level honnête ;
- un pattern local pour un futur slice H ciblé qui devra, si justifié, traiter un autre hazard sans repartir de zéro.

H1 ne débloque toujours pas :
- la famille complète des hazards ;
- leur retrait ;
- leurs interactions avec items/abilities ;
- un système générique de side conditions ;
- selfSwitch / forceSwitch ;
- doubles.

## 24. Contenu complet de tous les fichiers modifiés / créés / supprimés

Le report n'inclut pas son propre contenu intégral pour éviter une récursion infinie absurde. Tous les autres fichiers touchés sont inclus ci-dessous avec leur contenu complet.


### `/Users/karim/Project/pokemonProject/packages/map_battle/lib/map_battle.dart`

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
/// // 3. Read the explicit decision request
/// final request = session.decisionRequest;
/// final choices = request.allowedChoices; // compatibility helper
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
export 'src/battle_decision.dart';
export 'src/battle_session.dart';
export 'src/battle_state.dart';
export 'src/battle_topology.dart';
export 'src/battle_field.dart';
export 'src/battle_stealth_rock.dart';
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


### `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_move.dart`

```dart
import 'battle_field.dart';
import 'battle_status.dart';
import 'battle_volatile.dart';

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
/// - `field` pour les moves BE9 qui posent une météo ou un pseudoWeather ;
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
  field,
  opponentSide,
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
///
/// Mini-fix BE6-2 :
/// - cette classe devient volontairement `final` ;
/// - ce n'est pas un point d'extension du moteur, mais un contrat de donnée ;
/// - le mini-fix précédent avait amélioré la robustesse locale, tout en
///   laissant un bypass trivial par héritage/override dans les tests ;
/// - on ferme donc ce trou au niveau langage au lieu de continuer à écrire
///   des preuves artificielles basées sur des sous-classes malformées.
final class BattleMove {
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
  /// [majorStatusEffect] - Effet `applyStatus` battle minimal réellement
  ///   supporté par BE7 pour `par`, `brn`, `psn`, `tox`.
  /// [selfVolatileStatus] - Volatile auto-appliqué dans le petit sous-ensemble
  ///   BE8 (`protect` uniquement).
  /// [weatherEffect] - Effet météo battle minimal réellement consommé par BE9.
  /// [pseudoWeatherEffect] - Effet pseudoWeather battle minimal réellement
  ///   consommé par BE9.
  /// [setsStealthRock] - H1 ouvre exactement Stealth Rock, et rien de plus,
  ///   comme premier hazard side-level honnête.
  /// [breaksProtect] - Permet au move de bypasser une protection active BE8.
  /// [requiresRecharge] - Demande un tour de recharge honnête au lanceur après
  ///   une exécution réussie.
  /// [chargeThenStrikeEffect] - Porte le petit contrat local d'un move qui
  ///   charge un tour puis frappe le tour suivant sans repayer les PP.
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
  /// - puis, en BE7, un petit sous-ensemble `applyStatus` réellement
  ///   exécutable sans ouvrir un système générique de statuts ;
  /// - puis, en BE8, quelques volatiles utiles strictement bornés à
  ///   `Protect`, `requireRecharge`, `chargeThenStrike` et `breakProtect` ;
  /// - puis, en BE9, un tout petit seam de champ pour `rain`, `sandstorm`
  ///   et `trickRoom`, sans ouvrir side/slot/terrain ;
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
    this.majorStatusEffect,
    this.selfVolatileStatus,
    this.weatherEffect,
    this.pseudoWeatherEffect,
    this.setsStealthRock = false,
    this.breaksProtect = false,
    this.requiresRecharge = false,
    this.chargeThenStrikeEffect,
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
  ///
  /// BE9 ajoute `field` pour les moves qui posent une météo ou `Trick Room` :
  /// - ces moves ne visent ni réellement `self`, ni réellement `opponent` ;
  /// - les marquer `unspecified` reperdrait une intention désormais consommée
  ///   par le moteur ;
  /// - on garde malgré tout un targeting battle très petit.
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
  /// - BE6-mini-fix-2 verrouille maintenant aussi la classe au niveau langage,
  ///   donc le bypass trivial par override externe disparaît ;
  /// - on ajoute quand même aussi une validation runtime au getter, parce
  ///   qu'un objet battle incohérent peut encore émerger d'un futur mauvais
  ///   refactor interne ou d'un état construit dans cette même librairie ;
  /// - le moteur garde enfin une dernière validation défensive plus loin :
  ///   cette garde n'est plus la preuve principale du contrat public, mais
  ///   une défense en profondeur.
  final int _critRatio;

  int get critRatio {
    if (_critRatio < 1) {
      throw StateError('BattleMove critRatio must be >= 1; got $_critRatio.');
    }
    return _critRatio;
  }

  /// Effet battle minimal de statut majeur transporté par le bridge runtime.
  ///
  /// BE7 garde ce contrat volontairement petit :
  /// - un seul effet de statut majeur par move ;
  /// - pas de payload canonique complet ;
  /// - pas de support des volatiles ;
  /// - pas de targeting générique, car le bridge ne laisse déjà passer que le
  ///   scope `target` honnêtement exécutable aujourd'hui.
  final BattleMoveMajorStatusEffect? majorStatusEffect;

  /// Volatile auto-appliqué par ce move dans le sous-ensemble BE8.
  ///
  /// Ce champ reste volontairement étroit :
  /// - `protect` seulement ;
  /// - pas de confusion, pas de semi-invulnérabilité, pas de framework
  ///   générique de volatiles.
  final BattleVolatileStatusId? selfVolatileStatus;

  /// Météo de champ posée par ce move dans le sous-ensemble BE9.
  ///
  /// Le move porte seulement l'intention de pose :
  /// - la durée et l'état actif vivent dans `BattleFieldState` ;
  /// - `rain` et `sandstorm` sont les seuls IDs réellement supportés ;
  /// - pas de météo avancée, pas d'abilities, pas d'items.
  final BattleWeatherId? weatherEffect;

  /// PseudoWeather de champ posé par ce move dans le sous-ensemble BE9.
  ///
  /// Même frontière que pour [weatherEffect] :
  /// - `trickRoom` seulement ;
  /// - aucun système générique de rooms ;
  /// - la durée et l'expiration vivent dans `BattleFieldState`.
  final BattlePseudoWeatherId? pseudoWeatherEffect;

  /// H1 ouvre uniquement Stealth Rock comme side condition vivante.
  ///
  /// On choisit volontairement un booléen dédié plutôt qu'un faux framework :
  /// - le lot ne supporte qu'une seule mécanique side-level ;
  /// - aucun autre hazard n'entre ici ;
  /// - si de futurs lots H ouvrent autre chose, ils devront le justifier à
  ///   nouveau au lieu de profiter d'un conteneur mort.
  final bool setsStealthRock;

  /// true si ce move peut percer une protection active BE8.
  ///
  /// Le booléen reste plus honnête qu'une abstraction générique :
  /// - il documente un unique besoin réel du lot ;
  /// - il évite d'ouvrir une taxonomie entière de "modificateurs de défense"
  ///   alors que seul `breakProtect` est réellement exécutable ici.
  final bool breaksProtect;

  /// true si ce move impose ensuite un tour de recharge au lanceur.
  ///
  /// BE8 garde une sémantique locale explicite :
  /// - le move réussi ;
  /// - le combattant marque ensuite un état `mustRecharge` ;
  /// - le tour suivant est perdu honnêtement, puis l'état est nettoyé.
  final bool requiresRecharge;

  /// Petit payload d'un move à charge sur deux tours.
  ///
  /// Si non-null :
  /// - le premier tour ne fait que charger ;
  /// - le second réutilise ce move sans redépenser les PP ;
  /// - le moteur n'ouvre ni raccourci météo, ni Power Herb, ni autres cas
  ///   spéciaux hors scope.
  final BattleChargeThenStrikeEffect? chargeThenStrikeEffect;

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
      majorStatusEffect: majorStatusEffect,
      selfVolatileStatus: selfVolatileStatus,
      weatherEffect: weatherEffect,
      pseudoWeatherEffect: pseudoWeatherEffect,
      setsStealthRock: setsStealthRock,
      breaksProtect: breaksProtect,
      requiresRecharge: requiresRecharge,
      chargeThenStrikeEffect: chargeThenStrikeEffect,
      selfStatStageChanges: selfStatStageChanges,
      targetStatStageChanges: targetStatStageChanges,
    );
  }
}

```


### `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_queue.dart`

```dart
import 'dart:collection';

import 'battle_action.dart';
import 'battle_topology.dart';

/// Queue locale des étapes d'un tour singles.
///
/// Frontière Phase F volontairement stricte :
/// - cette queue ne devient pas un contrat public du runtime ;
/// - elle ne remplace ni `BattleTurnResult.timeline`, ni `BattleDecisionRequest` ;
/// - elle ne sait gérer que les grandes étapes réellement supportées aujourd'hui ;
/// - elle n'ouvre ni targeting riche, ni callbacks génériques, ni hooks.
///
/// Son rôle est uniquement de devenir la vraie source de vérité du scheduling
/// interne du tour :
/// - des actions déjà légales (`Fight`, `Switch`, `Recharge`) ;
/// - de la fin de tour ;
/// - des checks post-résolution ;
/// - des remplacements déjà honnêtement supportés.
final class BattleTurnQueue {
  BattleTurnQueue(Iterable<BattleQueueStep> initialSteps)
      : _steps = ListQueue<BattleQueueStep>.of(initialSteps);

  final ListQueue<BattleQueueStep> _steps;

  bool get isEmpty => _steps.isEmpty;

  int get length => _steps.length;

  BattleQueueStep takeNext() {
    if (_steps.isEmpty) {
      throw StateError('BattleTurnQueue est vide.');
    }
    return _steps.removeFirst();
  }

  void pushBack(BattleQueueStep step) {
    _steps.addLast(step);
  }

  void pushBackAll(Iterable<BattleQueueStep> steps) {
    _steps.addAll(steps);
  }

  /// Retire et retourne les étapes encore en attente.
  ///
  /// H1 Stealth Rock en a besoin pour un cas très précis :
  /// - un switch volontaire peut faire entrer un Pokémon qui meurt aussitôt sur
  ///   Piège de Roc ;
  /// - le moteur doit alors suspendre honnêtement le tour, demander un vrai
  ///   remplacement joueur, puis reprendre les étapes restantes ;
  /// - on expose donc un drainage explicite de la queue au lieu d'introduire
  ///   un scheduler caché ou un deuxième conteneur parallèle.
  List<BattleQueueStep> drainRemainingSteps() {
    final remaining = List<BattleQueueStep>.of(_steps);
    _steps.clear();
    return remaining;
  }
}

/// Taxonomie volontairement petite des étapes que la queue peut transporter.
///
/// On choisit ici les vraies familles utiles au scheduling actuel, rien de plus.
enum BattleQueueStepKind {
  action,
  endOfTurn,
  postTurnChecks,
  autoSwitch,
  replacementRequired,
}

sealed class BattleQueueStep {
  const BattleQueueStep();

  BattleQueueStepKind get kind;
}

/// Retourne `true` seulement pour les actions réellement gérées par la queue.
///
/// Important :
/// - `Run` / `Capture` vivent encore hors queue car ils terminent
///   immédiatement le combat hors résolution normale ;
/// - `BattleActionNone` reste un marqueur d'étape inter-tour locale et ne doit
///   pas être déguisé en action de queue ;
/// - Phase F refuse donc de transformer toute `BattleAction` existante en
///   pseudo commande universelle.
bool isBattleQueueManagedAction(BattleAction action) {
  return action is BattleActionFight ||
      action is BattleActionRecharge ||
      action is BattleActionSwitch;
}

/// Étape de queue qui résout une action réellement jouée pendant le tour.
final class BattleQueueActionStep extends BattleQueueStep {
  factory BattleQueueActionStep({
    required BattleSideId side,
    required BattleSlotRef slot,
    required BattleAction action,
    bool wasForced = false,
  }) {
    _validateSlotAttachment(
      expectedSide: side,
      slot: slot,
      stepLabel: 'BattleQueueActionStep',
    );
    if (!isBattleQueueManagedAction(action)) {
      throw ArgumentError.value(
        action,
        'action',
        'BattleQueueActionStep n’accepte que Fight/Switch/Recharge.',
      );
    }
    return BattleQueueActionStep._(
      side: side,
      slot: slot,
      action: action,
      wasForced: wasForced,
    );
  }

  const BattleQueueActionStep._({
    required this.side,
    required this.slot,
    required this.action,
    required this.wasForced,
  });

  final BattleSideId side;
  final BattleSlotRef slot;
  final BattleAction action;

  /// Distingue le switch volontaire de l'étape de remplacement forcé joueur.
  ///
  /// Phase F garde ce flag localement borné :
  /// - il ne s'applique utilement qu'aux `BattleActionSwitch` ;
  /// - il évite de recréer une seconde taxonomie de step juste pour préserver
  ///   la vérité d'un flow déjà supporté ;
  /// - il n'ouvre aucun targeting ni scheduler plus riche.
  final bool wasForced;

  @override
  BattleQueueStepKind get kind => BattleQueueStepKind.action;
}

/// Étape explicite de fin de tour.
///
/// On la garde sans payload :
/// - la fin de tour actuelle s'applique encore au combat entier ;
/// - la vraie causalité vit dans l'engine de conditions et dans l'état courant ;
/// - ajouter ici des champs décoratifs ne ferait que gonfler l'API.
final class BattleQueueEndOfTurnStep extends BattleQueueStep {
  const BattleQueueEndOfTurnStep();

  @override
  BattleQueueStepKind get kind => BattleQueueStepKind.endOfTurn;
}

/// Étape qui inspecte l'état après la fin de tour et insère les suites utiles.
///
/// Elle existe pour rendre explicite le moment où le moteur décide :
/// - un auto-remplacement ennemi ;
/// - un remplacement requis côté joueur ;
/// - ou rien.
final class BattleQueuePostTurnChecksStep extends BattleQueueStep {
  const BattleQueuePostTurnChecksStep();

  @override
  BattleQueueStepKind get kind => BattleQueueStepKind.postTurnChecks;
}

/// Étape de switch automatique déjà réellement supportée.
final class BattleQueueAutoSwitchStep extends BattleQueueStep {
  factory BattleQueueAutoSwitchStep({
    required BattleSideId side,
    required BattleSlotRef slot,
    required int reserveIndex,
  }) {
    _validateSlotAttachment(
      expectedSide: side,
      slot: slot,
      stepLabel: 'BattleQueueAutoSwitchStep',
    );
    return BattleQueueAutoSwitchStep._(
      side: side,
      slot: slot,
      reserveIndex: reserveIndex,
    );
  }

  const BattleQueueAutoSwitchStep._({
    required this.side,
    required this.slot,
    required this.reserveIndex,
  });

  final BattleSideId side;
  final BattleSlotRef slot;
  final int reserveIndex;

  @override
  BattleQueueStepKind get kind => BattleQueueStepKind.autoSwitch;
}

/// Étape explicite disant qu'un remplacement joueur est requis avant le tour
/// suivant.
///
/// Cette étape n'effectue pas le switch elle-même :
/// - le moteur singles actuel laisse encore ce remplacement au prochain
///   `decisionRequest` joueur ;
/// - Phase F rend simplement ce moment explicite dans le scheduling.
final class BattleQueueReplacementRequiredStep extends BattleQueueStep {
  factory BattleQueueReplacementRequiredStep({
    required BattleSideId side,
    required BattleSlotRef slot,
    required String faintedSpeciesId,
  }) {
    _validateSlotAttachment(
      expectedSide: side,
      slot: slot,
      stepLabel: 'BattleQueueReplacementRequiredStep',
    );
    return BattleQueueReplacementRequiredStep._(
      side: side,
      slot: slot,
      faintedSpeciesId: faintedSpeciesId,
    );
  }

  const BattleQueueReplacementRequiredStep._({
    required this.side,
    required this.slot,
    required this.faintedSpeciesId,
  });

  final BattleSideId side;
  final BattleSlotRef slot;
  final String faintedSpeciesId;

  @override
  BattleQueueStepKind get kind => BattleQueueStepKind.replacementRequired;
}

void _validateSlotAttachment({
  required BattleSideId expectedSide,
  required BattleSlotRef slot,
  required String stepLabel,
}) {
  if (slot.side != expectedSide) {
    throw ArgumentError(
      '$stepLabel attend un slot rattaché au side ${expectedSide.name}, '
      'mais a reçu ${slot.side.name}.',
    );
  }
}

```


### `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_resolution.dart`

```dart
import 'battle_action.dart';
import 'battle_field.dart';
import 'battle_move.dart';
import 'battle_stealth_rock.dart';
import 'battle_state.dart';
import 'battle_status.dart';
import 'battle_topology.dart';
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
  /// [stealthRockEvents] - Les événements Stealth Rock visibles du tour.
  /// [timeline] - La chronologie ordonnée réellement produite par le moteur.
  const BattleTurnResult({
    required this.playerAction,
    required this.enemyAction,
    required this.executions,
    this.statusEvents = const <BattleStatusEvent>[],
    this.volatileEvents = const <BattleVolatileEvent>[],
    this.fieldEvents = const <BattleFieldEvent>[],
    this.stealthRockEvents = const <BattleStealthRockEvent>[],
    this.switchEvents = const <BattleSwitchEvent>[],
    this.timeline = const <BattleTurnEvent>[],
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

  /// Les événements Stealth Rock visibles pendant ce tour.
  ///
  /// H1 ouvre volontairement une petite liste sœur dédiée :
  /// - Stealth Rock n'est ni un statut, ni un volatile, ni un field event ;
  /// - on refuse pourtant d'ouvrir un journal universel des side conditions ;
  /// - ce lot garde donc un contrat dédié et vivant pour une seule mécanique.
  final List<BattleStealthRockEvent> stealthRockEvents;

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

  /// Chronologie ordonnée du tour telle que réellement résolue par le moteur.
  ///
  /// BE10A ajoute cette source de vérité pour arrêter un nouveau mensonge :
  /// - les buckets `executions` / `statusEvents` / `volatileEvents` /
  ///   `fieldEvents` / `switchEvents` restent utiles pour les tests ciblés
  ///   et la compatibilité locale ;
  /// - mais ils ne peuvent pas, à eux seuls, exprimer l'ordre croisé entre
  ///   un switch, une exécution d'attaque, un résiduel puis un remplacement ;
  /// - le runtime/overlay ne doit donc plus reconstruire la chronologie avec
  ///   un tri heuristique de buckets.
  ///
  /// Frontière volontaire :
  /// - ce n'est pas un event bus générique ;
  /// - on transporte uniquement les cinq familles déjà réellement supportées ;
  /// - l'ordre est celui construit pendant la résolution réelle du tour.
  final List<BattleTurnEvent> timeline;
}

/// Entrée de chronologie ordonnée d'un tour.
///
/// Ce contrat reste strictement local à la restitution du tour :
/// - il ne remplace pas les buckets historiques ;
/// - il ne devient pas un journal universel du moteur ;
/// - il sert uniquement à conserver un ordre causal honnête entre les familles
///   d'événements déjà réellement supportées.
sealed class BattleTurnEvent {
  const BattleTurnEvent();
}

final class BattleTurnExecutionEvent extends BattleTurnEvent {
  const BattleTurnExecutionEvent(this.execution);

  final BattleMoveExecution execution;
}

final class BattleTurnStatusEvent extends BattleTurnEvent {
  const BattleTurnStatusEvent(this.event);

  final BattleStatusEvent event;
}

final class BattleTurnVolatileEvent extends BattleTurnEvent {
  const BattleTurnVolatileEvent(this.event);

  final BattleVolatileEvent event;
}

final class BattleTurnFieldEvent extends BattleTurnEvent {
  const BattleTurnFieldEvent(this.event);

  final BattleFieldEvent event;
}

final class BattleTurnStealthRockEvent extends BattleTurnEvent {
  const BattleTurnStealthRockEvent(this.event);

  final BattleStealthRockEvent event;
}

final class BattleTurnSwitchEvent extends BattleTurnEvent {
  const BattleTurnSwitchEvent(this.event);

  final BattleSwitchEvent event;
}

/// Exécution d'une attaque.
///
/// Représente une attaque qui a été exécutée avec ses effets.
///
/// Phase G élargit volontairement ce contrat sur un point précis :
/// - l'exécution ne doit plus être seulement observable via des chaînes
///   `"player"` / `"enemy"` / `"field"` ;
/// - le moteur a désormais une vraie topologie singles (`side` / `slot`) ;
/// - la trace de résolution doit donc porter cette topologie elle aussi.
///
/// Garde-fou de scope :
/// - on n'ouvre pas un système de targeting riche ;
/// - on ne porte toujours que le sous-ensemble réellement supporté :
///   cible combattant active ou cible field ;
/// - les getters stringly-typed restent comme seam de compatibilité local.
enum BattleMoveExecutionTargetKind {
  combatant,
  field,
  side,
}

class BattleMoveExecution {
  /// Crée une exécution d'attaque.
  ///
  /// [attackerSlot] - Le slot qui a réellement exécuté l'attaque.
  /// [move] - L'attaque utilisée.
  /// [targetKind] - La famille de cible réellement résolue.
  /// [targetSlot] - Le slot ciblé quand [targetKind] vaut `combatant`.
  /// [damage] - Les dégâts infligés.
  /// [didHit] - true si le move a réellement touché.
  /// [didCrit] - true si le move a réellement déclenché un critique.
  /// [criticalMultiplier] - Multiplicateur critique réellement appliqué.
  /// [stabMultiplier] - Multiplicateur STAB réellement consommé pour ce hit.
  /// [typeEffectivenessMultiplier] - Multiplicateur de type réellement appliqué.
  const BattleMoveExecution({
    required this.attackerSlot,
    required this.move,
    required this.targetKind,
    this.targetSlot,
    this.targetSideRef,
    required this.damage,
    required this.didHit,
    this.didCrit = false,
    this.criticalMultiplier = 1.0,
    this.stabMultiplier = 1.0,
    this.typeEffectivenessMultiplier = 1.0,
  }) : assert(
          (targetKind == BattleMoveExecutionTargetKind.combatant &&
                  targetSlot != null &&
                  targetSideRef == null) ||
              (targetKind == BattleMoveExecutionTargetKind.field &&
                  targetSlot == null &&
                  targetSideRef == null) ||
              (targetKind == BattleMoveExecutionTargetKind.side &&
                  targetSlot == null &&
                  targetSideRef != null),
          'BattleMoveExecution target payload must describe exactly one of: combatant slot, field, or side.',
        );

  /// Slot attaquant réellement résolu par le moteur.
  ///
  /// En singles Phase D/F :
  /// - il s'agit encore toujours du slot actif `0` d'un side ;
  /// - mais l'exécution arrête de mentir en faisant comme si la topologie
  ///   n'existait pas.
  final BattleSlotRef attackerSlot;

  /// Side de l'attaquant.
  BattleSideId get attackerSide => attackerSlot.side;

  /// Compatibilité locale pour les surfaces encore stringly-typed.
  ///
  /// Ce getter n'est plus la source de vérité ; il dérive désormais du slot.
  String get attacker => attackerSide.actorId;

  /// L'attaque utilisée.
  final BattleMove move;

  /// Famille de cible réellement consommée par cette exécution.
  final BattleMoveExecutionTargetKind targetKind;

  /// Slot ciblé quand l'exécution vise un combattant.
  ///
  /// Frontière volontaire :
  /// - `null` signifie uniquement "le move vise le field" ;
  /// - `null` signifie aussi "le move vise un side" ;
  /// - on ne crée ni targeting riche, ni tableau de cibles multiples.
  final BattleSlotRef? targetSlot;

  /// Side ciblé quand l'exécution vise un side plutôt qu'un combattant.
  ///
  /// H1 ouvre ce seam pour une raison précise :
  /// - Stealth Rock vise le side adverse, pas le combattant adverse ;
  /// - le move execution ne doit donc plus mentir en se faisant passer pour
  ///   un target combatant ou field ;
  /// - on n'ouvre pour autant aucun targeting riche supplémentaire.
  final BattleSideId? targetSideRef;

  /// Side ciblé quand l'exécution vise un combattant.
  BattleSideId? get targetSide => switch (targetKind) {
        BattleMoveExecutionTargetKind.combatant => targetSlot?.side,
        BattleMoveExecutionTargetKind.side => targetSideRef,
        BattleMoveExecutionTargetKind.field => null,
      };

  /// Compatibilité locale pour les surfaces encore stringly-typed.
  ///
  /// Valeurs dérivées :
  /// - `"player"` / `"enemy"` pour une cible combattant ;
  /// - `"field"` pour une cible field.
  String get target => switch (targetKind) {
        BattleMoveExecutionTargetKind.combatant => targetSlot!.side.actorId,
        BattleMoveExecutionTargetKind.side => targetSideRef!.actorId,
        BattleMoveExecutionTargetKind.field => 'field',
      };

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


### `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart`

```dart
import 'battle_setup.dart';
import 'battle_decision.dart';
import 'battle_condition_engine.dart';
import 'battle_stealth_rock.dart';
import 'battle_state.dart';
import 'battle_action.dart';
import 'battle_queue.dart';
import 'battle_field.dart';
import 'battle_move.dart';
import 'battle_rng.dart';
import 'battle_resolution.dart';
import 'battle_status.dart';
import 'battle_switch.dart';
import 'battle_topology.dart';
import 'battle_volatile.dart';
import 'battle_stats.dart';
import 'battle_type_chart.dart';

const double _criticalHitMultiplier = 1.5;
const BattleConditionEngine _conditionEngine = BattleConditionEngine();

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
    playerSide: BattleSideState.player(
      active: player,
      reserve: playerReserve,
    ),
    enemySide: BattleSideState.enemy(
      active: enemy,
      reserve: enemyReserve,
    ),
    field: setup.fieldState,
    currentTurn: null,
    outcome: null,
  );

  return BattleSession._(
    state: initialState,
    setup: setup,
    rng: rng,
    pendingTurn: null,
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
            setsStealthRock: m.setsStealthRock,
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

BattleSideId _opposingSideId(BattleSideId side) {
  return switch (side) {
    BattleSideId.player => BattleSideId.enemy,
    BattleSideId.enemy => BattleSideId.player,
  };
}

/// Session de combat.
///
/// Encapsule l'état d'un combat et fournit les méthodes pour interagir avec.
/// Immutable : toutes les méthodes retournent une nouvelle session.
///
/// Cycle de vie :
/// 1. [createBattleSession] crée la session
/// 2. [decisionRequest] expose la vraie requête de décision joueur
/// 3. [getAvailableChoices] reste disponible comme adaptateur de compatibilité
/// 4. [applyChoice] applique un choix et retourne une nouvelle session
/// 5. Répéter 2-4 jusqu'à ce que [state.isFinished] soit true
/// 6. Récupérer [state.outcome] pour le résultat final
class BattleSession {
  /// Crée une session de combat.
  ///
  /// Constructeur privé. Utiliser [createBattleSession] à la place.
  const BattleSession._({
    required this.state,
    required this.setup,
    required this.rng,
    required this.pendingTurn,
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

  /// Continuation locale d'un tour déjà commencé mais suspendu pour demander
  /// un remplacement joueur en plein scheduling.
  ///
  /// Frontière H1 volontairement étroite :
  /// - ce seam n'ouvre pas un moteur général de tours interrompus ;
  /// - il sert uniquement à ne pas mentir quand un switch-in meurt aussitôt sur
  ///   Piège de Roc alors qu'une action adverse reste déjà en file ;
  /// - dès que le joueur choisit le remplacement, la queue reprend là où elle
  ///   s'était arrêtée.
  final _PendingTurnContinuation? pendingTurn;

  /// Requête de décision joueur explicitement exposée par le moteur.
  ///
  /// Phase C choisit ici le plus petit vrai progrès de fondation :
  /// - le moteur ne publie plus seulement une "liste plate de choix" ;
  /// - il expose désormais le type de demande courante :
  ///   tour libre, remplacement forcé, continuation forcée ou attente ;
  /// - runtime/UI peuvent donc consommer un contrat fort sans deviner le
  ///   sens du tour depuis les choix présents, le KO actif ou les volatiles.
  BattleDecisionRequest get decisionRequest => _buildDecisionRequest();

  /// Récupère les choix disponibles pour le joueur.
  ///
  /// Compatibilité locale Phase C :
  /// - cette méthode reste volontairement publique pour limiter le blast
  ///   radius immédiat ;
  /// - mais elle n'est plus la source principale de vérité ;
  /// - elle dérive désormais directement de [decisionRequest].
  ///
  List<PlayerBattleChoice> getAvailableChoices() {
    return decisionRequest.allowedChoices;
  }

  BattleDecisionRequest _buildDecisionRequest() {
    const playerSideId = BattleSideId.player;
    const playerSlot = BattleSlotRef.active(BattleSideId.player);

    if (state.phase == BattlePhase.finished) {
      return BattleWaitRequest(
        side: playerSideId,
        slot: playerSlot,
        reason: BattleWaitReason.battleFinished,
      );
    }

    if (state.phase != BattlePhase.playerChoice) {
      return BattleWaitRequest(
        side: playerSideId,
        slot: playerSlot,
        reason: BattleWaitReason.resolvingTurn,
      );
    }

    final replacementChoices = _availableForcedReplacementChoices();
    if (replacementChoices.isNotEmpty) {
      return BattleForcedReplacementRequest(
        side: playerSideId,
        slot: playerSlot,
        switchChoices: replacementChoices,
        reason: BattleForcedReplacementReason.activeFainted,
        faintedSpeciesId: state.player.speciesId,
      );
    }

    // Cas explicitement borné mais important :
    // - si l'actif est K.O. sans remplaçant valide et que la session n'est pas
    //   déjà terminée, on refuse d'inventer un faux tour libre ;
    // - le runtime voit alors un état "wait" bruyant au lieu d'un menu trompeur.
    if (state.player.isFainted) {
      return BattleWaitRequest(
        side: playerSideId,
        slot: playerSlot,
        reason: BattleWaitReason.activeFaintedWithoutReplacement,
      );
    }

    final volatileState = state.player.volatileState;
    if (volatileState.pendingCharge != null) {
      return BattleContinueRequest(
        side: playerSideId,
        slot: playerSlot,
        reason: BattleContinueReason.pendingChargeRelease,
      );
    }
    if (volatileState.mustRecharge) {
      return BattleContinueRequest(
        side: playerSideId,
        slot: playerSlot,
        reason: BattleContinueReason.mustRecharge,
      );
    }

    // On construit maintenant explicitement le vrai tour libre :
    // - moves encore jouables ;
    // - switches volontaires valides ;
    // - issues sauvages éventuellement autorisées.
    final moveChoices = <PlayerBattleChoiceFight>[];
    for (var i = 0; i < state.player.moves.length; i++) {
      if (state.player.moves[i].hasUsablePp) {
        moveChoices.add(PlayerBattleChoiceFight(i));
      }
    }
    final switchChoices = _availableVoluntarySwitchChoices();
    final captureChoice = !setup.isTrainerBattle && setup.allowCapture
        ? const PlayerBattleChoiceCapture()
        : null;
    final runChoice =
        !setup.isTrainerBattle ? const PlayerBattleChoiceRun() : null;

    if (moveChoices.isEmpty &&
        switchChoices.isEmpty &&
        captureChoice == null &&
        runChoice == null) {
      return BattleWaitRequest(
        side: playerSideId,
        slot: playerSlot,
        reason: BattleWaitReason.noLegalChoice,
      );
    }

    return BattleTurnChoiceRequest(
      side: playerSideId,
      slot: playerSlot,
      moveChoices: moveChoices,
      switchChoices: switchChoices,
      captureChoice: captureChoice,
      runChoice: runChoice,
    );
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
    final request = decisionRequest;
    if (request is BattleWaitRequest) {
      throw StateError(
        'Aucune décision joueur n’est attendue actuellement (${request.reason.name}).',
      );
    }
    if (!request.allows(choice)) {
      throw _illegalChoiceStateError(request, choice);
    }
    if (request case BattleForcedReplacementRequest()) {
      if (pendingTurn != null) {
        return _resumePendingTurnWithReplacement(
          choice as PlayerBattleChoiceSwitch,
        );
      }
      return _applyForcedPlayerReplacement(choice as PlayerBattleChoiceSwitch);
    }

    final forcedPlayerAction = switch (request) {
      BattleContinueRequest() => _resolveForcedAction(
          combatantLabel: 'player',
          combatant: state.player,
        ),
      _ => null,
    };
    if (request is BattleContinueRequest && forcedPlayerAction == null) {
      throw StateError(
        'La request ${request.kind.name} ne correspond plus à un vrai tour forcé côté moteur.',
      );
    }

    // Frontière métier défensive :
    // même si un call site contourne getAvailableChoices(), un combat trainer
    // ne doit jamais pouvoir produire ni "runaway", ni "captured".
    //
    // On rejette explicitement ce cas illégal au niveau du moteur, ce qui
    // évite de dépendre d'un filtre UI seulement.
    if (request is! BattleContinueRequest &&
        choice is PlayerBattleChoiceRun &&
        setup.isTrainerBattle) {
      throw StateError(
        'PlayerBattleChoiceRun est interdit pendant un trainer battle.',
      );
    }
    if (request is! BattleContinueRequest &&
        choice is PlayerBattleChoiceCapture &&
        setup.isTrainerBattle) {
      throw StateError(
        'PlayerBattleChoiceCapture est interdit pendant un trainer battle.',
      );
    }
    if (request is! BattleContinueRequest &&
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
    if (request is! BattleContinueRequest && choice is PlayerBattleChoiceRun) {
      final finalState = BattleState(
        phase: BattlePhase.finished,
        playerSide: state.playerSide,
        enemySide: state.enemySide,
        field: state.field,
        currentTurn: null,
        outcome: null,
      );
      return BattleSession._(
        state: BattleState(
          phase: BattlePhase.finished,
          playerSide: finalState.playerSide,
          enemySide: finalState.enemySide,
          field: finalState.field,
          currentTurn: null,
          outcome: BattleOutcome(
            type: BattleOutcomeType.runaway,
            finalState: finalState,
          ),
        ),
        setup: setup,
        rng: rng,
        pendingTurn: null,
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
    if (request is! BattleContinueRequest &&
        choice is PlayerBattleChoiceCapture) {
      final finalState = BattleState(
        phase: BattlePhase.finished,
        playerSide: state.playerSide,
        enemySide: state.enemySide,
        field: state.field,
        currentTurn: null,
        outcome: null,
      );
      return BattleSession._(
        state: BattleState(
          phase: BattlePhase.finished,
          playerSide: finalState.playerSide,
          enemySide: finalState.enemySide,
          field: finalState.field,
          currentTurn: null,
          outcome: BattleOutcome(
            type: BattleOutcomeType.captured,
            finalState: finalState,
          ),
        ),
        setup: setup,
        rng: rng,
        pendingTurn: null,
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

    // Phase F déplace ici la source de vérité du séquencement :
    // - `_resolveTurn` ne renvoie plus seulement "les deux actions puis un
    //   append post-traité" ;
    // - il consomme désormais une vraie queue locale incluant fin de tour et
    //   checks post-résolution ;
    // - le résultat qu'il renvoie est donc déjà le tour complet canonique.
    final turnResult = resolvedTurn.turnResult;

    // Phase 5: Vérifier si le combat est fini
    final outcome = resolvedTurn.pendingTurn != null
        ? null
        : _determineOutcome(
            resolvedTurn.playerSide,
            resolvedTurn.enemySide,
            resolvedTurn.field,
          );

    // Phase 6: Créer le nouvel état
    final newState = BattleState(
      phase: outcome != null ? BattlePhase.finished : BattlePhase.playerChoice,
      playerSide: resolvedTurn.playerSide,
      enemySide: resolvedTurn.enemySide,
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
      pendingTurn: resolvedTurn.pendingTurn,
    );
  }

  BattleSession _applyForcedPlayerReplacement(PlayerBattleChoiceSwitch choice) {
    // Review Phase F:
    // - le remplacement joueur inter-tour était encore sur un chemin manuel ;
    // - cela laissait une portion déjà supportée du flow hors scheduler
    //   canonique ;
    // - on le fait donc aussi passer par la queue, mais sans lui inventer
    //   une fausse fin de tour ni des checks post-résolution.
    final turn = _QueuedTurnContext(
      playerSide: state.playerSide,
      enemySide: state.enemySide,
      field: state.field,
      rng: rng,
      originalPlayerAction:
          BattleActionSwitch(reserveIndex: choice.reserveIndex),
      originalEnemyAction: const BattleActionNone(),
    );
    final queue = BattleTurnQueue(
      <BattleQueueStep>[
        BattleQueueActionStep(
          side: BattleSideId.player,
          slot: const BattleSlotRef.active(BattleSideId.player),
          action: BattleActionSwitch(reserveIndex: choice.reserveIndex),
          wasForced: true,
        ),
      ],
    );

    while (!queue.isEmpty) {
      _executeQueueStep(
        queue: queue,
        turn: turn,
        step: queue.takeNext(),
      );
    }

    final followUpReplacementIndex =
        _firstUsableReserveIndex(turn.playerSide.reserve);
    if (turn.playerSide.active.isFainted && followUpReplacementIndex != null) {
      final replacementRequiredEvent = BattleSwitchEvent.replacementRequired(
        side: BattleSideId.player,
        fromSpeciesId: turn.playerSide.active.speciesId,
      );
      turn.switchEvents.add(replacementRequiredEvent);
      turn.timeline.add(BattleTurnSwitchEvent(replacementRequiredEvent));
    }

    final outcome = _determineOutcome(
      turn.playerSide,
      turn.enemySide,
      turn.field,
    );

    return BattleSession._(
      state: BattleState(
        phase:
            outcome != null ? BattlePhase.finished : BattlePhase.playerChoice,
        playerSide: turn.playerSide,
        enemySide: turn.enemySide,
        field: turn.field,
        currentTurn: BattleTurnResult(
          playerAction: BattleActionSwitch(reserveIndex: choice.reserveIndex),
          enemyAction: const BattleActionNone(),
          executions: const <BattleMoveExecution>[],
          stealthRockEvents:
              List<BattleStealthRockEvent>.unmodifiable(turn.stealthRockEvents),
          switchEvents: List<BattleSwitchEvent>.unmodifiable(turn.switchEvents),
          timeline: List<BattleTurnEvent>.unmodifiable(turn.timeline),
        ),
        outcome: outcome,
      ),
      setup: setup,
      rng: turn.rng,
      pendingTurn: null,
    );
  }

  BattleSession _resumePendingTurnWithReplacement(
      PlayerBattleChoiceSwitch choice) {
    final pending = pendingTurn;
    if (pending == null) {
      throw StateError(
        'Aucune continuation de tour n’est disponible pour reprendre un remplacement joueur.',
      );
    }

    final turn = _QueuedTurnContext.resume(pending);
    final queue = BattleTurnQueue(
      <BattleQueueStep>[
        BattleQueueActionStep(
          side: BattleSideId.player,
          slot: const BattleSlotRef.active(BattleSideId.player),
          action: BattleActionSwitch(reserveIndex: choice.reserveIndex),
          wasForced: true,
        ),
        ...pending.remainingSteps,
      ],
    );

    while (!queue.isEmpty) {
      _executeQueueStep(
        queue: queue,
        turn: turn,
        step: queue.takeNext(),
      );
      if (turn.pendingTurn != null) {
        break;
      }
      _appendTurnTailWhenActionPhaseDrains(
        queue: queue,
        turn: turn,
      );
    }

    final outcome = turn.pendingTurn != null
        ? null
        : _determineOutcome(
            turn.playerSide,
            turn.enemySide,
            turn.field,
          );

    return BattleSession._(
      state: BattleState(
        phase:
            outcome != null ? BattlePhase.finished : BattlePhase.playerChoice,
        playerSide: turn.playerSide,
        enemySide: turn.enemySide,
        field: turn.field,
        currentTurn: _buildTurnResultFromContext(
          turn: turn,
          playerAction: pending.playerAction,
          enemyAction: pending.enemyAction,
        ),
        outcome: outcome,
      ),
      setup: setup,
      rng: turn.rng,
      pendingTurn: turn.pendingTurn,
    );
  }

  _ResolvedSwitchAction _resolveSwitchAction({
    required BattleSideState side,
    required int reserveIndex,
    required bool wasForced,
  }) {
    final reserve = side.reserve;
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
    updatedReserve[reserveIndex] = side.active.resetForReserveOnSwitchOut();

    return _ResolvedSwitchAction(
      side: side.withActiveAndReserve(
        active: incoming,
        reserve: List<BattleCombatant>.unmodifiable(updatedReserve),
      ),
      event: BattleSwitchEvent.switched(
        side: side.id,
        fromSpeciesId: side.active.speciesId,
        toSpeciesId: incoming.speciesId,
        wasForced: wasForced,
      ),
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
      throw StateError(
        'Le choix Fight(${choice.moveIndex}) vise un slot move invalide.',
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
    throw StateError(
      'Type de choix joueur non supporté par _choiceToAction: ${choice.runtimeType}.',
    );
  }

  String _describePlayerChoice(PlayerBattleChoice choice) {
    return switch (choice) {
      PlayerBattleChoiceFight(:final moveIndex) => 'Fight($moveIndex)',
      PlayerBattleChoiceSwitch(:final reserveIndex) => 'Switch($reserveIndex)',
      PlayerBattleChoiceRun() => 'Run()',
      PlayerBattleChoiceCapture() => 'Capture()',
      PlayerBattleChoiceContinue() => 'Continue()',
    };
  }

  StateError _illegalChoiceStateError(
    BattleDecisionRequest request,
    PlayerBattleChoice choice,
  ) {
    // On garde ici quelques diagnostics métier précis pour ne pas perdre en
    // lisibilité par rapport à l'ancien monde "liste plate" :
    // - un move à 0 PP doit rester identifiable comme tel ;
    // - un switch invalide ou vers une réserve K.O. mérite aussi un message
    //   ciblé ;
    // - tout le reste peut retomber sur le message générique request/kind.
    if (choice case PlayerBattleChoiceFight(:final moveIndex)) {
      if (moveIndex >= 0 && moveIndex < state.player.moves.length) {
        final move = state.player.moves[moveIndex];
        if (!move.hasUsablePp) {
          return StateError(
            'Le move "${move.name}" n’a plus de PP et ne peut pas être utilisé.',
          );
        }
      }
    }

    if (choice case PlayerBattleChoiceSwitch(:final reserveIndex)) {
      if (reserveIndex < 0 || reserveIndex >= state.playerReserve.length) {
        return StateError(
          'Le switch demandé vise un index de réserve invalide ($reserveIndex).',
        );
      }
      if (state.playerReserve[reserveIndex].isFainted) {
        return StateError(
          'Le switch demandé vise un Pokémon de réserve déjà K.O.',
        );
      }
    }

    return StateError(
      'Le choix ${_describePlayerChoice(choice)} est illégal pour la request courante ${request.kind.name}.',
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
  /// Phase F remplace ici l'ancien pipeline figé par une vraie queue locale :
  /// - l'ordre initial reste calculé honnêtement une seule fois au début ;
  /// - mais les étapes du tour passent ensuite par une file consommée ;
  /// - la fin de tour et les checks post-résolution sont insérés explicitement ;
  /// - les remplacements déjà supportés ne sont plus appendés "à côté" du tour.
  _ResolvedBattleTurn _resolveTurn(
    BattleAction playerAction,
    BattleAction enemyAction,
  ) {
    final turn = _QueuedTurnContext(
      playerSide: state.playerSide,
      enemySide: state.enemySide,
      field: state.field,
      rng: rng,
      originalPlayerAction: playerAction,
      originalEnemyAction: enemyAction,
    );
    final queue = BattleTurnQueue(
      _buildInitialTurnQueue(
        playerAction: playerAction,
        enemyAction: enemyAction,
        player: turn.playerSide.active,
        enemy: turn.enemySide.active,
        field: turn.field,
      ),
    );

    while (!queue.isEmpty) {
      final step = queue.takeNext();
      _executeQueueStep(
        queue: queue,
        turn: turn,
        step: step,
      );
      if (turn.pendingTurn != null) {
        break;
      }
      _appendTurnTailWhenActionPhaseDrains(
        queue: queue,
        turn: turn,
      );
    }

    return _ResolvedBattleTurn(
      playerSide: turn.playerSide,
      enemySide: turn.enemySide,
      field: turn.field,
      rng: turn.rng,
      turnResult: _buildTurnResultFromContext(
        turn: turn,
        playerAction: playerAction,
        enemyAction: enemyAction,
      ),
      pendingTurn: turn.pendingTurn,
    );
  }

  BattleTurnResult _buildTurnResultFromContext({
    required _QueuedTurnContext turn,
    required BattleAction playerAction,
    required BattleAction enemyAction,
  }) {
    return BattleTurnResult(
      playerAction: playerAction,
      enemyAction: enemyAction,
      executions: List<BattleMoveExecution>.unmodifiable(turn.executions),
      statusEvents: List<BattleStatusEvent>.unmodifiable(turn.statusEvents),
      volatileEvents:
          List<BattleVolatileEvent>.unmodifiable(turn.volatileEvents),
      fieldEvents: List<BattleFieldEvent>.unmodifiable(turn.fieldEvents),
      stealthRockEvents:
          List<BattleStealthRockEvent>.unmodifiable(turn.stealthRockEvents),
      switchEvents: List<BattleSwitchEvent>.unmodifiable(turn.switchEvents),
      timeline: List<BattleTurnEvent>.unmodifiable(turn.timeline),
    );
  }

  Iterable<BattleQueueStep> _buildInitialTurnQueue({
    required BattleAction playerAction,
    required BattleAction enemyAction,
    required BattleCombatant player,
    required BattleCombatant enemy,
    required BattleFieldState field,
  }) sync* {
    final orderedActions = _resolveTurnOrder(
      playerAction: playerAction,
      enemyAction: enemyAction,
      player: player,
      enemy: enemy,
      field: field,
    );

    for (final orderedAction in orderedActions) {
      if (!isBattleQueueManagedAction(orderedAction.action)) {
        continue;
      }

      yield BattleQueueActionStep(
        side: orderedAction.side,
        slot: BattleSlotRef.active(orderedAction.side),
        action: orderedAction.action,
        wasForced: false,
      );
    }
  }

  void _appendTurnTailWhenActionPhaseDrains({
    required BattleTurnQueue queue,
    required _QueuedTurnContext turn,
  }) {
    if (turn.turnTailScheduled || !queue.isEmpty) {
      return;
    }

    // La queue n'insère la fin de tour qu'une seule fois, exactement quand les
    // actions ordonnées du tour ont été consommées. C'est ce point d'insertion
    // explicite qui remplace l'ancien "et maintenant on fait la fin de tour"
    // codé en dur en bas de `_resolveTurn`.
    queue.pushBack(const BattleQueueEndOfTurnStep());
    queue.pushBack(const BattleQueuePostTurnChecksStep());
    turn.turnTailScheduled = true;
  }

  void _executeQueueStep({
    required BattleTurnQueue queue,
    required _QueuedTurnContext turn,
    required BattleQueueStep step,
  }) {
    switch (step) {
      case BattleQueueActionStep():
        _executeActionQueueStep(
          queue: queue,
          turn: turn,
          step: step,
        );
      case BattleQueueEndOfTurnStep():
        _executeEndOfTurnQueueStep(turn);
      case BattleQueuePostTurnChecksStep():
        _executePostTurnChecksQueueStep(
          queue: queue,
          turn: turn,
        );
      case BattleQueueAutoSwitchStep():
        _executeAutoSwitchQueueStep(
          queue: queue,
          turn: turn,
          step: step,
        );
      case BattleQueueReplacementRequiredStep():
        _executeReplacementRequiredQueueStep(turn: turn, step: step);
    }
  }

  void _executeActionQueueStep({
    required BattleTurnQueue queue,
    required _QueuedTurnContext turn,
    required BattleQueueActionStep step,
  }) {
    final actingSide = turn.side(step.side);
    final opposingSide = turn.side(_opposingSideId(step.side));

    if (step.action case BattleActionFight(:final move, :final moveIndex)) {
      if (actingSide.active.isFainted || opposingSide.active.isFainted) {
        return;
      }

      final resolution = _resolveMoveExecution(
        attackerSlot: actingSide.activeSlotRef,
        move: move,
        moveIndex: moveIndex,
        attacker: actingSide.active,
        defender: opposingSide.active,
        field: turn.field,
        targetSlot: opposingSide.activeSlotRef,
        rng: turn.rng,
      );
      turn.updateActive(step.side, resolution.attacker);
      turn.updateActive(_opposingSideId(step.side), resolution.defender);
      turn.field = resolution.field;
      turn.rng = resolution.rng;
      if (resolution.execution != null) {
        turn.executions.add(resolution.execution!);
      }
      turn.statusEvents.addAll(resolution.statusEvents);
      turn.volatileEvents.addAll(resolution.volatileEvents);
      turn.fieldEvents.addAll(resolution.fieldEvents);
      turn.timeline.addAll(resolution.timeline);
      final stealthRockResolution = _resolveStealthRockMoveEffect(
        move: move,
        didResolveHit: resolution.execution?.didHit == true,
        targetSide: turn.side(_opposingSideId(step.side)),
      );
      if (stealthRockResolution != null) {
        turn.updateSide(
          _opposingSideId(step.side),
          stealthRockResolution.side,
        );
        turn.stealthRockEvents.addAll(stealthRockResolution.events);
        turn.timeline
            .addAll(_turnEventsFromStealthRock(stealthRockResolution.events));
      }
      return;
    }

    if (step.action case BattleActionSwitch(:final reserveIndex)) {
      final resolution = _resolveSwitchAction(
        side: actingSide,
        reserveIndex: reserveIndex,
        wasForced: step.wasForced,
      );
      turn.updateSide(step.side, resolution.side);
      turn.switchEvents.add(resolution.event);
      turn.timeline.add(BattleTurnSwitchEvent(resolution.event));
      final stealthRockResolution = _resolveStealthRockEntry(
        side: turn.side(step.side),
      );
      turn.updateSide(step.side, stealthRockResolution.side);
      turn.stealthRockEvents.addAll(stealthRockResolution.events);
      turn.timeline
          .addAll(_turnEventsFromStealthRock(stealthRockResolution.events));

      final sideAfterEntry = turn.side(step.side);
      if (sideAfterEntry.active.isFainted &&
          step.side == BattleSideId.player &&
          _firstUsableReserveIndex(sideAfterEntry.reserve) != null &&
          !queue.isEmpty) {
        _suspendTurnForImmediatePlayerReplacement(
          queue: queue,
          turn: turn,
        );
      }
      return;
    }

    if (step.action is BattleActionRecharge) {
      if (actingSide.active.isFainted || opposingSide.active.isFainted) {
        return;
      }

      final resolution = _conditionEngine.runForcedContinueTurn(
        combatantSlot: actingSide.activeSlotRef,
        combatant: actingSide.active,
      );
      turn.updateActive(step.side, resolution.combatant);
      turn.volatileEvents.addAll(resolution.volatileEvents);
      turn.timeline.addAll(_turnEventsFromVolatile(resolution.volatileEvents));
    }
  }

  void _executeEndOfTurnQueueStep(_QueuedTurnContext turn) {
    final residualResolution = _conditionEngine.runEndOfTurn(
      player: turn.playerSide.active,
      enemy: turn.enemySide.active,
      field: turn.field,
    );
    turn.updateActive(BattleSideId.player, residualResolution.player);
    turn.updateActive(BattleSideId.enemy, residualResolution.enemy);
    turn.field = residualResolution.field;
    turn.statusEvents.addAll(residualResolution.statusEvents);
    turn.fieldEvents.addAll(residualResolution.fieldEvents);
    turn.timeline
        .addAll(_turnEventsFromStatus(residualResolution.statusEvents));
    turn.timeline.addAll(_turnEventsFromField(residualResolution.fieldEvents));
  }

  void _executePostTurnChecksQueueStep({
    required BattleTurnQueue queue,
    required _QueuedTurnContext turn,
  }) {
    final enemyReplacementIndex =
        _firstUsableReserveIndex(turn.enemySide.reserve);
    if (turn.enemySide.active.isFainted && enemyReplacementIndex != null) {
      queue.pushBack(
        BattleQueueAutoSwitchStep(
          side: BattleSideId.enemy,
          slot: const BattleSlotRef.active(BattleSideId.enemy),
          reserveIndex: enemyReplacementIndex,
        ),
      );
    }

    if (turn.playerSide.active.isFainted &&
        !turn.enemySide.active.isFainted &&
        _firstUsableReserveIndex(turn.playerSide.reserve) != null) {
      // Tant qu'une chaîne d'auto-switch ennemi reste possible, on refuse
      // d'annoncer le remplacement joueur trop tôt :
      // - sinon la timeline raconterait "le joueur doit remplacer" avant que
      //   l'ennemi ait fini d'entrer réellement ;
      // - en H1 Stealth Rock, un premier remplaçant ennemi peut même mourir
      //   en entrant, ce qui doit rester visible avant la request joueur.
      queue.pushBack(
        BattleQueueReplacementRequiredStep(
          side: BattleSideId.player,
          slot: const BattleSlotRef.active(BattleSideId.player),
          faintedSpeciesId: turn.playerSide.active.speciesId,
        ),
      );
    }
  }

  void _executeAutoSwitchQueueStep({
    required BattleTurnQueue queue,
    required _QueuedTurnContext turn,
    required BattleQueueAutoSwitchStep step,
  }) {
    final resolution = _resolveSwitchAction(
      side: turn.side(step.side),
      reserveIndex: step.reserveIndex,
      wasForced: true,
    );
    turn.updateSide(step.side, resolution.side);
    turn.switchEvents.add(resolution.event);
    turn.timeline.add(BattleTurnSwitchEvent(resolution.event));
    final stealthRockResolution = _resolveStealthRockEntry(
      side: turn.side(step.side),
    );
    turn.updateSide(step.side, stealthRockResolution.side);
    turn.stealthRockEvents.addAll(stealthRockResolution.events);
    turn.timeline
        .addAll(_turnEventsFromStealthRock(stealthRockResolution.events));

    if (turn.side(step.side).active.isFainted) {
      final nextReserveIndex =
          _firstUsableReserveIndex(turn.side(step.side).reserve);
      if (nextReserveIndex != null) {
        queue.pushBack(
          BattleQueueAutoSwitchStep(
            side: step.side,
            slot: step.slot,
            reserveIndex: nextReserveIndex,
          ),
        );
        return;
      }
    }

    if (step.side == BattleSideId.enemy &&
        turn.playerSide.active.isFainted &&
        !turn.enemySide.active.isFainted &&
        _firstUsableReserveIndex(turn.playerSide.reserve) != null) {
      queue.pushBack(
        BattleQueueReplacementRequiredStep(
          side: BattleSideId.player,
          slot: const BattleSlotRef.active(BattleSideId.player),
          faintedSpeciesId: turn.playerSide.active.speciesId,
        ),
      );
    }
  }

  void _executeReplacementRequiredQueueStep({
    required _QueuedTurnContext turn,
    required BattleQueueReplacementRequiredStep step,
  }) {
    final replacementRequiredEvent = BattleSwitchEvent.replacementRequired(
      side: step.side,
      fromSpeciesId: step.faintedSpeciesId,
    );
    turn.switchEvents.add(replacementRequiredEvent);
    turn.timeline.add(BattleTurnSwitchEvent(replacementRequiredEvent));
  }

  void _suspendTurnForImmediatePlayerReplacement({
    required BattleTurnQueue queue,
    required _QueuedTurnContext turn,
  }) {
    // H1 Stealth Rock ouvre ici le plus petit vrai seam d'interruption :
    // - uniquement pour un remplacement joueur devenu obligatoire en plein tour
    //   parce qu'un switch-in vient de mourir sur Piège de Roc ;
    // - on ne transforme pas cela en scheduler général ni en bus d'interruption ;
    // - on capture juste assez d'état pour reprendre honnêtement les étapes déjà
    //   en file après le futur choix de remplacement.
    final replacementRequiredEvent = BattleSwitchEvent.replacementRequired(
      side: BattleSideId.player,
      fromSpeciesId: turn.playerSide.active.speciesId,
    );
    turn.switchEvents.add(replacementRequiredEvent);
    turn.timeline.add(BattleTurnSwitchEvent(replacementRequiredEvent));
    turn.pendingTurn = _PendingTurnContinuation.capture(
      turn: turn,
      remainingSteps: queue.drainRemainingSteps(),
      playerAction: turn.originalPlayerAction ?? const BattleActionNone(),
      enemyAction: turn.originalEnemyAction ?? const BattleActionNone(),
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
    if (!isBattleQueueManagedAction(playerAction) ||
        !isBattleQueueManagedAction(enemyAction)) {
      return <_OrderedBattleAction>[
        _OrderedBattleAction(
          side: BattleSideId.player,
          action: playerAction,
        ),
        _OrderedBattleAction(
          side: BattleSideId.enemy,
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
                side: BattleSideId.player,
                action: playerAction,
              ),
              _OrderedBattleAction(
                side: BattleSideId.enemy,
                action: enemyAction,
              ),
            ]
          : <_OrderedBattleAction>[
              _OrderedBattleAction(
                side: BattleSideId.enemy,
                action: enemyAction,
              ),
              _OrderedBattleAction(
                side: BattleSideId.player,
                action: playerAction,
              ),
            ];
    }

    final playerSpeed = _resolveEffectiveSpeed(player);
    final enemySpeed = _resolveEffectiveSpeed(enemy);
    final trickRoomActive = _conditionEngine.doesFieldInvertSpeedOrder(field);
    if (playerSpeed != enemySpeed) {
      final playerActsFirst =
          trickRoomActive ? playerSpeed < enemySpeed : playerSpeed > enemySpeed;
      return playerActsFirst
          ? <_OrderedBattleAction>[
              _OrderedBattleAction(
                side: BattleSideId.player,
                action: playerAction,
              ),
              _OrderedBattleAction(
                side: BattleSideId.enemy,
                action: enemyAction,
              ),
            ]
          : <_OrderedBattleAction>[
              _OrderedBattleAction(
                side: BattleSideId.enemy,
                action: enemyAction,
              ),
              _OrderedBattleAction(
                side: BattleSideId.player,
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
        side: BattleSideId.player,
        action: playerAction,
      ),
      _OrderedBattleAction(
        side: BattleSideId.enemy,
        action: enemyAction,
      ),
    ];
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
    required BattleSlotRef attackerSlot,
    required BattleMove move,
    required int moveIndex,
    required BattleCombatant attacker,
    required BattleCombatant defender,
    required BattleFieldState field,
    required BattleSlotRef targetSlot,
    required BattleRng rng,
  }) {
    final actionAttempt = _conditionEngine.runActionAttempt(
      attackerSlot: attackerSlot,
      move: move,
      moveIndex: moveIndex,
      attacker: attacker,
      rng: rng,
    );

    if (actionAttempt.outcome == BattleActionAttemptOutcome.preventedAction) {
      return _ResolvedMoveExecution(
        attacker: actionAttempt.attacker,
        defender: defender,
        field: field,
        rng: actionAttempt.rng,
        execution: null,
        statusEvents: actionAttempt.statusEvents,
        volatileEvents: const <BattleVolatileEvent>[],
        fieldEvents: const <BattleFieldEvent>[],
        timeline: _turnEventsFromStatus(actionAttempt.statusEvents),
      );
    }

    if (actionAttempt.outcome == BattleActionAttemptOutcome.chargeStarted) {
      return _ResolvedMoveExecution(
        attacker: actionAttempt.attacker,
        defender: defender,
        field: field,
        rng: actionAttempt.rng,
        execution: null,
        statusEvents: const <BattleStatusEvent>[],
        volatileEvents: actionAttempt.volatileEvents,
        fieldEvents: const <BattleFieldEvent>[],
        timeline: _turnEventsFromVolatile(actionAttempt.volatileEvents),
      );
    }

    final preHitVolatileEvents =
        List<BattleVolatileEvent>.of(actionAttempt.volatileEvents);
    final hitCheck = _resolveHitCheck(
      move: move,
      rng: actionAttempt.rng,
    );

    if (!hitCheck.didHit) {
      final missExecution = BattleMoveExecution(
        attackerSlot: attackerSlot,
        move: actionAttempt.attacker.moves[moveIndex],
        targetKind: _resolveExecutionTargetKind(move),
        targetSlot: _resolveExecutionTargetSlot(
          move: move,
          attackerSlot: attackerSlot,
          opponentSlot: targetSlot,
        ),
        targetSideRef: _resolveExecutionTargetSide(
          move: move,
          opponentSlot: targetSlot,
        ),
        damage: 0,
        didHit: false,
        didCrit: false,
        criticalMultiplier: 1.0,
      );
      return _ResolvedMoveExecution(
        attacker: actionAttempt.attacker,
        defender: defender,
        field: field,
        rng: hitCheck.nextRng,
        execution: missExecution,
        statusEvents: const <BattleStatusEvent>[],
        volatileEvents: List<BattleVolatileEvent>.unmodifiable(
          preHitVolatileEvents,
        ),
        fieldEvents: const <BattleFieldEvent>[],
        timeline: _buildMoveTimeline(
          preExecutionVolatileEvents: preHitVolatileEvents,
          execution: missExecution,
        ),
      );
    }

    final hitInterception = _conditionEngine.runHitInterception(
      move: move,
      attackerSlot: attackerSlot,
      targetSlot: targetSlot,
      attacker: actionAttempt.attacker,
      defender: defender,
    );
    preHitVolatileEvents.addAll(hitInterception.volatileEvents);

    if (hitInterception.blockedByProtect) {
      final blockedExecution = BattleMoveExecution(
        attackerSlot: attackerSlot,
        move: hitInterception.attacker.moves[moveIndex],
        targetKind: _resolveExecutionTargetKind(move),
        targetSlot: _resolveExecutionTargetSlot(
          move: move,
          attackerSlot: attackerSlot,
          opponentSlot: targetSlot,
        ),
        targetSideRef: _resolveExecutionTargetSide(
          move: move,
          opponentSlot: targetSlot,
        ),
        damage: 0,
        didHit: true,
        didCrit: false,
        criticalMultiplier: 1.0,
      );
      return _ResolvedMoveExecution(
        attacker: hitInterception.attacker,
        defender: hitInterception.defender,
        field: field,
        rng: hitCheck.nextRng,
        execution: blockedExecution,
        statusEvents: const <BattleStatusEvent>[],
        volatileEvents: List<BattleVolatileEvent>.unmodifiable(
          preHitVolatileEvents,
        ),
        fieldEvents: const <BattleFieldEvent>[],
        timeline: _buildMoveTimeline(
          preExecutionVolatileEvents: preHitVolatileEvents,
          execution: blockedExecution,
        ),
      );
    }

    final damageResult = _computeMoveDamage(
      move: move,
      attacker: hitInterception.attacker,
      defender: hitInterception.defender,
      field: field,
      rng: hitCheck.nextRng,
    );

    final updatedAttacker = damageResult.wasImmune
        ? hitInterception.attacker
        : hitInterception.attacker
            .withAppliedStageChanges(move.selfStatStageChanges);
    final defenderAfterHit = damageResult.wasImmune
        ? hitInterception.defender
        : hitInterception.defender
            .withDamage(damageResult.damage)
            .withAppliedStageChanges(move.targetStatStageChanges);
    final postMoveConditions = _conditionEngine.runMoveResolved(
      move: move,
      attackerSlot: attackerSlot,
      targetSlot: targetSlot,
      attacker: updatedAttacker,
      defender: defenderAfterHit,
      field: field,
      wasImmune: damageResult.wasImmune,
      rng: damageResult.nextRng,
    );
    final preExecutionVolatileEvents =
        List<BattleVolatileEvent>.unmodifiable(preHitVolatileEvents);
    final allVolatileEvents = <BattleVolatileEvent>[
      ...preHitVolatileEvents,
      ...postMoveConditions.volatileEvents,
    ];

    final resolvedExecution = BattleMoveExecution(
      attackerSlot: attackerSlot,
      move: postMoveConditions.attacker.moves[moveIndex],
      targetKind: _resolveExecutionTargetKind(move),
      targetSlot: _resolveExecutionTargetSlot(
        move: move,
        attackerSlot: attackerSlot,
        opponentSlot: targetSlot,
      ),
      targetSideRef: _resolveExecutionTargetSide(
        move: move,
        opponentSlot: targetSlot,
      ),
      damage: damageResult.damage,
      didHit: true,
      didCrit: damageResult.didCrit,
      criticalMultiplier: damageResult.criticalMultiplier,
      stabMultiplier: damageResult.stabMultiplier,
      typeEffectivenessMultiplier: damageResult.typeEffectivenessMultiplier,
    );

    return _ResolvedMoveExecution(
      attacker: postMoveConditions.attacker,
      defender: postMoveConditions.defender,
      field: postMoveConditions.field,
      rng: postMoveConditions.rng,
      execution: resolvedExecution,
      statusEvents: postMoveConditions.statusEvents,
      volatileEvents: List<BattleVolatileEvent>.unmodifiable(allVolatileEvents),
      fieldEvents: postMoveConditions.fieldEvents,
      timeline: _buildMoveTimeline(
        preExecutionVolatileEvents: preExecutionVolatileEvents,
        execution: resolvedExecution,
        statusEvents: postMoveConditions.statusEvents,
        fieldEvents: postMoveConditions.fieldEvents,
        postExecutionVolatileEvents: postMoveConditions.volatileEvents,
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

  /// Résout la famille de cible observable d'une exécution.
  ///
  /// Phase G garde cette aide volontairement locale à la session :
  /// - elle évite de re-disperser la logique "combatant vs field" ;
  /// - elle ne transforme pas `BattleMoveTarget` en système de targeting riche ;
  /// - elle sert uniquement à produire un contrat d'exécution plus honnête.
  BattleMoveExecutionTargetKind _resolveExecutionTargetKind(
    BattleMove move,
  ) {
    return switch (move.target) {
      BattleMoveTarget.field => BattleMoveExecutionTargetKind.field,
      BattleMoveTarget.opponentSide => BattleMoveExecutionTargetKind.side,
      BattleMoveTarget.self ||
      BattleMoveTarget.opponent ||
      BattleMoveTarget.unspecified =>
        BattleMoveExecutionTargetKind.combatant,
    };
  }

  /// Résout le slot cible observable quand l'exécution vise un combattant.
  ///
  /// Frontière volontaire :
  /// - en singles, `self` et `opponent` suffisent encore ;
  /// - `field` garde explicitement l'absence de slot ;
  /// - on n'anticipe ni doubles, ni targeting multiple, ni side targeting.
  BattleSlotRef? _resolveExecutionTargetSlot({
    required BattleMove move,
    required BattleSlotRef attackerSlot,
    required BattleSlotRef opponentSlot,
  }) {
    return switch (move.target) {
      BattleMoveTarget.self => attackerSlot,
      BattleMoveTarget.field || BattleMoveTarget.opponentSide => null,
      BattleMoveTarget.opponent || BattleMoveTarget.unspecified => opponentSlot,
    };
  }

  BattleSideId? _resolveExecutionTargetSide({
    required BattleMove move,
    required BattleSlotRef opponentSlot,
  }) {
    return switch (move.target) {
      BattleMoveTarget.opponentSide => opponentSlot.side,
      BattleMoveTarget.self ||
      BattleMoveTarget.field ||
      BattleMoveTarget.opponent ||
      BattleMoveTarget.unspecified =>
        null,
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
    final burnMultiplier = _conditionEngine.resolveStatusDamageMultiplier(
      move: move,
      attacker: attacker,
    );
    final weatherMultiplier = _conditionEngine.resolveFieldDamageMultiplier(
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
    // - Phase E délègue ensuite à l'engine conditionnel le malus simple de
    //   paralysie, pour arrêter de disperser cette règle métier ;
    // - aucun RNG, aucune nature, aucun weather ;
    // - Trick Room BE9 n'altère pas cette valeur : il inverse ensuite la
    //   comparaison des deux vitesses au niveau du scheduler.
    final stagedSpeed = _resolveEffectiveStat(
      baseStat: combatant.stats.speed,
      multiplier: combatant.statStages.multiplierFor(BattleStatId.speed),
    );
    return _conditionEngine.resolveStatusAdjustedSpeed(
      combatant: combatant,
      stagedSpeed: stagedSpeed,
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
    BattleSideState playerSide,
    BattleSideState enemySide,
    BattleFieldState field,
  ) {
    // Vérifier la victoire (ennemi K.O.)
    if (enemySide.active.isFainted) {
      final finalState = BattleState(
        phase: BattlePhase.finished,
        playerSide: playerSide,
        enemySide: enemySide,
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
    if (playerSide.active.isFainted) {
      if (_firstUsableReserveIndex(playerSide.reserve) != null) {
        return null;
      }
      final finalState = BattleState(
        phase: BattlePhase.finished,
        playerSide: playerSide,
        enemySide: enemySide,
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

  List<BattleTurnEvent> _buildMoveTimeline({
    List<BattleVolatileEvent> preExecutionVolatileEvents =
        const <BattleVolatileEvent>[],
    BattleMoveExecution? execution,
    List<BattleStatusEvent> statusEvents = const <BattleStatusEvent>[],
    List<BattleFieldEvent> fieldEvents = const <BattleFieldEvent>[],
    List<BattleVolatileEvent> postExecutionVolatileEvents =
        const <BattleVolatileEvent>[],
  }) {
    // BE10A garde une granularité volontairement petite :
    // - on ne reconstruit plus l'ordre en UI ;
    // - on fabrique ici une chronologie ordonnée au moment où le moteur
    //   connaît réellement l'enchaînement causal ;
    // - on ne descend toutefois pas dans une micro-chronologie Showdown-like
    //   de chaque sous-étape interne.
    final timeline = <BattleTurnEvent>[
      ..._turnEventsFromVolatile(preExecutionVolatileEvents),
      if (execution != null) BattleTurnExecutionEvent(execution),
      ..._turnEventsFromStatus(statusEvents),
      ..._turnEventsFromField(fieldEvents),
      ..._turnEventsFromVolatile(postExecutionVolatileEvents),
    ];
    return List<BattleTurnEvent>.unmodifiable(timeline);
  }

  List<BattleTurnEvent> _turnEventsFromStatus(
    Iterable<BattleStatusEvent> events,
  ) {
    return List<BattleTurnEvent>.unmodifiable(
      events.map(BattleTurnStatusEvent.new),
    );
  }

  List<BattleTurnEvent> _turnEventsFromVolatile(
    Iterable<BattleVolatileEvent> events,
  ) {
    return List<BattleTurnEvent>.unmodifiable(
      events.map(BattleTurnVolatileEvent.new),
    );
  }

  List<BattleTurnEvent> _turnEventsFromField(
    Iterable<BattleFieldEvent> events,
  ) {
    return List<BattleTurnEvent>.unmodifiable(
      events.map(BattleTurnFieldEvent.new),
    );
  }

  List<BattleTurnEvent> _turnEventsFromStealthRock(
    Iterable<BattleStealthRockEvent> events,
  ) {
    return List<BattleTurnEvent>.unmodifiable(
      events.map(BattleTurnStealthRockEvent.new),
    );
  }

  _ResolvedStealthRockMoveEffect? _resolveStealthRockMoveEffect({
    required BattleMove move,
    required bool didResolveHit,
    required BattleSideState targetSide,
  }) {
    if (!move.setsStealthRock || !didResolveHit) {
      return null;
    }

    if (targetSide.hasStealthRock) {
      return _ResolvedStealthRockMoveEffect(
        side: targetSide,
        events: <BattleStealthRockEvent>[
          BattleStealthRockEvent.alreadyPresent(
            side: targetSide.id,
            sourceMoveId: move.id,
          ),
        ],
      );
    }

    return _ResolvedStealthRockMoveEffect(
      side: targetSide.withStealthRock(true),
      events: <BattleStealthRockEvent>[
        BattleStealthRockEvent.set(
          side: targetSide.id,
          sourceMoveId: move.id,
        ),
      ],
    );
  }

  _ResolvedStealthRockEntry _resolveStealthRockEntry({
    required BattleSideState side,
  }) {
    if (!side.hasStealthRock) {
      return _ResolvedStealthRockEntry(
        side: side,
        events: const <BattleStealthRockEvent>[],
      );
    }

    final intendedDamage = resolveStealthRockEntryDamage(side.active);
    if (intendedDamage <= 0) {
      return _ResolvedStealthRockEntry(
        side: side,
        events: const <BattleStealthRockEvent>[],
      );
    }

    final actualDamage = intendedDamage > side.active.currentHp
        ? side.active.currentHp
        : intendedDamage;
    final damagedActive = side.active.withDamage(actualDamage);

    return _ResolvedStealthRockEntry(
      side: side.withActive(damagedActive),
      events: <BattleStealthRockEvent>[
        BattleStealthRockEvent.damagedOnEntry(
          side: side.id,
          targetSlot: side.activeSlotRef,
          damage: actualDamage,
        ),
      ],
    );
  }
}

class _OrderedBattleAction {
  const _OrderedBattleAction({
    required this.side,
    required this.action,
  });

  final BattleSideId side;
  final BattleAction action;
}

class _ResolvedBattleTurn {
  const _ResolvedBattleTurn({
    required this.playerSide,
    required this.enemySide,
    required this.field,
    required this.rng,
    required this.turnResult,
    required this.pendingTurn,
  });

  final BattleSideState playerSide;
  final BattleSideState enemySide;
  final BattleFieldState field;
  final BattleRng rng;
  final BattleTurnResult turnResult;
  final _PendingTurnContinuation? pendingTurn;
}

final class _PendingTurnContinuation {
  const _PendingTurnContinuation({
    required this.playerSide,
    required this.enemySide,
    required this.field,
    required this.rng,
    required this.playerAction,
    required this.enemyAction,
    required this.turnTailScheduled,
    required this.remainingSteps,
    required this.executions,
    required this.statusEvents,
    required this.volatileEvents,
    required this.fieldEvents,
    required this.stealthRockEvents,
    required this.switchEvents,
    required this.timeline,
  });

  factory _PendingTurnContinuation.capture({
    required _QueuedTurnContext turn,
    required List<BattleQueueStep> remainingSteps,
    required BattleAction playerAction,
    required BattleAction enemyAction,
  }) {
    return _PendingTurnContinuation(
      playerSide: turn.playerSide,
      enemySide: turn.enemySide,
      field: turn.field,
      rng: turn.rng,
      playerAction: playerAction,
      enemyAction: enemyAction,
      turnTailScheduled: turn.turnTailScheduled,
      remainingSteps: List<BattleQueueStep>.unmodifiable(remainingSteps),
      executions: List<BattleMoveExecution>.unmodifiable(turn.executions),
      statusEvents: List<BattleStatusEvent>.unmodifiable(turn.statusEvents),
      volatileEvents:
          List<BattleVolatileEvent>.unmodifiable(turn.volatileEvents),
      fieldEvents: List<BattleFieldEvent>.unmodifiable(turn.fieldEvents),
      stealthRockEvents:
          List<BattleStealthRockEvent>.unmodifiable(turn.stealthRockEvents),
      switchEvents: List<BattleSwitchEvent>.unmodifiable(turn.switchEvents),
      timeline: List<BattleTurnEvent>.unmodifiable(turn.timeline),
    );
  }

  final BattleSideState playerSide;
  final BattleSideState enemySide;
  final BattleFieldState field;
  final BattleRng rng;
  final BattleAction playerAction;
  final BattleAction enemyAction;
  final bool turnTailScheduled;
  final List<BattleQueueStep> remainingSteps;
  final List<BattleMoveExecution> executions;
  final List<BattleStatusEvent> statusEvents;
  final List<BattleVolatileEvent> volatileEvents;
  final List<BattleFieldEvent> fieldEvents;
  final List<BattleStealthRockEvent> stealthRockEvents;
  final List<BattleSwitchEvent> switchEvents;
  final List<BattleTurnEvent> timeline;
}

class _ResolvedSwitchAction {
  const _ResolvedSwitchAction({
    required this.side,
    required this.event,
  });

  final BattleSideState side;
  final BattleSwitchEvent event;
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
    required this.timeline,
  });

  final BattleCombatant attacker;
  final BattleCombatant defender;
  final BattleFieldState field;
  final BattleRng rng;
  final BattleMoveExecution? execution;
  final List<BattleStatusEvent> statusEvents;
  final List<BattleVolatileEvent> volatileEvents;
  final List<BattleFieldEvent> fieldEvents;
  final List<BattleTurnEvent> timeline;
}

class _ResolvedStealthRockMoveEffect {
  const _ResolvedStealthRockMoveEffect({
    required this.side,
    required this.events,
  });

  final BattleSideState side;
  final List<BattleStealthRockEvent> events;
}

class _ResolvedStealthRockEntry {
  const _ResolvedStealthRockEntry({
    required this.side,
    required this.events,
  });

  final BattleSideState side;
  final List<BattleStealthRockEvent> events;
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

/// Contexte mutable strictement local à la consommation d'une queue de tour.
///
/// Phase F ne déplace pas la mutabilité vers `BattleState` :
/// - la session publique reste immutable ;
/// - ce contexte vit uniquement pendant `_resolveTurn` ;
/// - il sert à éviter de recopier manuellement le même faisceau de variables
///   `player/enemy/reserve/field/rng/events` dans chaque branche de queue.
final class _QueuedTurnContext {
  _QueuedTurnContext({
    required this.playerSide,
    required this.enemySide,
    required this.field,
    required this.rng,
    this.originalPlayerAction,
    this.originalEnemyAction,
  });

  factory _QueuedTurnContext.resume(_PendingTurnContinuation pending) {
    return _QueuedTurnContext(
      playerSide: pending.playerSide,
      enemySide: pending.enemySide,
      field: pending.field,
      rng: pending.rng,
      originalPlayerAction: pending.playerAction,
      originalEnemyAction: pending.enemyAction,
    )
      ..turnTailScheduled = pending.turnTailScheduled
      ..executions.addAll(pending.executions)
      ..statusEvents.addAll(pending.statusEvents)
      ..volatileEvents.addAll(pending.volatileEvents)
      ..fieldEvents.addAll(pending.fieldEvents)
      ..stealthRockEvents.addAll(pending.stealthRockEvents)
      ..switchEvents.addAll(pending.switchEvents)
      ..timeline.addAll(pending.timeline);
  }

  BattleSideState playerSide;
  BattleSideState enemySide;
  BattleFieldState field;
  BattleRng rng;
  BattleAction? originalPlayerAction;
  BattleAction? originalEnemyAction;
  bool turnTailScheduled = false;
  _PendingTurnContinuation? pendingTurn;

  final List<BattleMoveExecution> executions = <BattleMoveExecution>[];
  final List<BattleStatusEvent> statusEvents = <BattleStatusEvent>[];
  final List<BattleVolatileEvent> volatileEvents = <BattleVolatileEvent>[];
  final List<BattleFieldEvent> fieldEvents = <BattleFieldEvent>[];
  final List<BattleStealthRockEvent> stealthRockEvents =
      <BattleStealthRockEvent>[];
  final List<BattleSwitchEvent> switchEvents = <BattleSwitchEvent>[];
  final List<BattleTurnEvent> timeline = <BattleTurnEvent>[];

  BattleSideState side(BattleSideId sideId) {
    return switch (sideId) {
      BattleSideId.player => playerSide,
      BattleSideId.enemy => enemySide,
    };
  }

  void updateSide(BattleSideId sideId, BattleSideState sideState) {
    switch (sideId) {
      case BattleSideId.player:
        playerSide = sideState;
      case BattleSideId.enemy:
        enemySide = sideState;
    }
  }

  void updateActive(BattleSideId sideId, BattleCombatant active) {
    final existingSide = side(sideId);
    updateSide(
      sideId,
      existingSide.withActiveAndReserve(
        active: active,
        reserve: existingSide.reserve,
      ),
    );
  }
}

```


### `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_setup.dart`

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
  /// [setsStealthRock] - H1 ouvre exactement Stealth Rock, et rien de plus,
  ///   côté hazard side-level.
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
    this.setsStealthRock = false,
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

  /// H1 ouvre uniquement Stealth Rock comme premier hazard honnête.
  ///
  /// On garde ici le même design volontairement borné que dans `BattleMove` :
  /// - pas d'identifiant générique de side condition ;
  /// - pas de liste d'effets ;
  /// - juste le plus petit bit de vérité requis pour ce lot précis.
  final bool setsStealthRock;

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


### `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_state.dart`

```dart
import 'battle_field.dart';
import 'battle_move.dart';
import 'battle_resolution.dart';
import 'battle_status.dart';
import 'battle_topology.dart';
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
  /// Le runtime doit appeler [BattleSession.decisionRequest] pour connaître
  /// explicitement le type de décision attendu.
  ///
  /// Compatibilité locale conservée :
  /// - [BattleSession.getAvailableChoices()] reste disponible ;
  /// - mais il devient un simple adaptateur dérivé de la vraie requête.
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
/// - [playerSide.active.currentHp] est toujours entre 0 et
///   [playerSide.active.maxHp].
/// - [enemySide.active.currentHp] est toujours entre 0 et
///   [enemySide.active.maxHp].
class BattleState {
  /// Crée un état de combat.
  ///
  /// [phase] - La phase actuelle du combat.
  ///
  /// Phase D introduit ici le vrai progrès topologique du moteur :
  /// - la forme canonique du state devient `playerSide` / `enemySide` ;
  /// - chaque side porte un slot actif et une réserve ;
  /// - on cesse donc de considérer le moteur comme un simple sac de quatre
  ///   champs plats `player / playerReserve / enemy / enemyReserve`.
  ///
  /// Compatibilité bornée conservée :
  /// - beaucoup de call sites runtime/tests lisent encore `player`, `enemy`,
  ///   `playerReserve` et `enemyReserve` ;
  /// - cette surface de lecture reste donc disponible comme façade projetée ;
  /// - mais le stockage canonique du state vit désormais dans les deux sides.
  ///
  /// Contrat d'entrée :
  /// - fournir soit `playerSide`/`enemySide` ;
  /// - soit le vieux chemin plat `player`/`playerReserve`/`enemy`/
  ///   `enemyReserve` ;
  /// - ne pas mélanger les deux pour un même côté.
  /// [field] - L'état de champ observable (weather / pseudoWeather).
  /// [currentTurn] - Le résultat du tour en cours (null si aucun tour en cours).
  /// [outcome] - Le résultat final du combat (null si combat en cours).
  BattleState({
    required this.phase,
    BattleSideState? playerSide,
    BattleCombatant? player,
    List<BattleCombatant> playerReserve = const <BattleCombatant>[],
    BattleSideState? enemySide,
    BattleCombatant? enemy,
    List<BattleCombatant> enemyReserve = const <BattleCombatant>[],
    this.field = const BattleFieldState(),
    this.currentTurn,
    this.outcome,
  })  : playerSide = _resolveBattleStateSide(
          expectedId: BattleSideId.player,
          providedSide: playerSide,
          legacyActive: player,
          legacyReserve: playerReserve,
          sideLabel: 'player',
        ),
        enemySide = _resolveBattleStateSide(
          expectedId: BattleSideId.enemy,
          providedSide: enemySide,
          legacyActive: enemy,
          legacyReserve: enemyReserve,
          sideLabel: 'enemy',
        );

  /// La phase actuelle du combat.
  final BattlePhase phase;

  /// Side joueur canonique du combat.
  final BattleSideState playerSide;

  /// Side adverse canonique du combat.
  final BattleSideState enemySide;

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

  /// Compatibilité locale : actif joueur projeté depuis [playerSide].
  ///
  /// Ce getter reste volontairement public pour éviter qu'une migration de
  /// topologie Phase D force en douce une refonte runtime plus large.
  BattleCombatant get player => playerSide.active;

  /// Compatibilité locale : réserve joueur projetée depuis [playerSide].
  List<BattleCombatant> get playerReserve => playerSide.reserve;

  /// Compatibilité locale : actif adverse projeté depuis [enemySide].
  BattleCombatant get enemy => enemySide.active;

  /// Compatibilité locale : réserve adverse projetée depuis [enemySide].
  List<BattleCombatant> get enemyReserve => enemySide.reserve;

  /// Retourne le side demandé sans réintroduire un protocole plat.
  BattleSideState side(BattleSideId sideId) {
    return switch (sideId) {
      BattleSideId.player => playerSide,
      BattleSideId.enemy => enemySide,
    };
  }
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

/// Slot battle local réellement utilisé par le moteur singles.
///
/// Phase D refuse ici le faux type décoratif :
/// - ce slot n'est pas un placeholder vide ;
/// - il porte réellement le combattant actif du side ;
/// - les requests et événements peuvent donc enfin se rattacher à un slot
///   concret sans ouvrir une topologie multi-actifs ou doubles.
final class BattleSlotState {
  BattleSlotState({
    required this.side,
    required this.slotIndex,
    required this.combatant,
  });

  BattleSlotState.active({
    required BattleSideId side,
    required BattleCombatant combatant,
  }) : this(
          side: side,
          slotIndex: 0,
          combatant: combatant,
        );

  final BattleSideId side;
  final int slotIndex;
  final BattleCombatant combatant;

  /// Référence stable vers ce slot pour les requests et traces topologiques.
  BattleSlotRef get ref => BattleSlotRef(
        side: side,
        slotIndex: slotIndex,
      );

  /// Retourne une copie du slot avec un autre combattant.
  ///
  /// Le slot reste le même :
  /// - même side ;
  /// - même index ;
  /// - seule l'occupation change lors d'un switch ou d'une résolution de tour.
  BattleSlotState withCombatant(BattleCombatant updatedCombatant) {
    return BattleSlotState(
      side: side,
      slotIndex: slotIndex,
      combatant: updatedCombatant,
    );
  }
}

/// État local d'un side singles.
///
/// Ce type est volontairement petit mais réel :
/// - un side a maintenant une identité explicite ;
/// - il porte un vrai slot actif ;
/// - il porte une réserve ordonnée ;
/// - il devient le lieu honnête des futures responsabilités side-level, sans
///   ouvrir dès maintenant side conditions/hazards/doubles.
final class BattleSideState {
  BattleSideState({
    required this.id,
    required this.activeSlot,
    this.reserve = const <BattleCombatant>[],
    this.hasStealthRock = false,
  })  : assert(
          activeSlot.side == id,
          'BattleSideState.activeSlot must belong to the same side.',
        ),
        assert(
          activeSlot.slotIndex == 0,
          'Phase D remains singles-only and only supports active slot 0.',
        );

  BattleSideState.player({
    required BattleCombatant active,
    List<BattleCombatant> reserve = const <BattleCombatant>[],
  }) : this(
          id: BattleSideId.player,
          activeSlot: BattleSlotState.active(
            side: BattleSideId.player,
            combatant: active,
          ),
          reserve: reserve,
        );

  BattleSideState.enemy({
    required BattleCombatant active,
    List<BattleCombatant> reserve = const <BattleCombatant>[],
  }) : this(
          id: BattleSideId.enemy,
          activeSlot: BattleSlotState.active(
            side: BattleSideId.enemy,
            combatant: active,
          ),
          reserve: reserve,
        );

  final BattleSideId id;
  final BattleSlotState activeSlot;

  /// Réserve ordonnée locale de ce side.
  ///
  /// Invariant métier conservé :
  /// - chaque membre engagé dans le combat reste présent exactement une fois ;
  /// - le slot actif ne vit pas aussi dans la réserve ;
  /// - l'ordre de réserve reste stable tant qu'un switch ne l'altère pas.
  final List<BattleCombatant> reserve;

  /// H1 ouvre le plus petit vrai état side-level vivant : Stealth Rock.
  ///
  /// Garde-fou de périmètre :
  /// - pas de conteneur générique de hazards ;
  /// - pas de liste de side conditions ;
  /// - pas de "pour plus tard" ;
  /// - juste la vérité minimale nécessaire à cette mécanique.
  final bool hasStealthRock;

  /// Combattant actif de ce side.
  BattleCombatant get active => activeSlot.combatant;

  /// Référence canonique du slot actif.
  BattleSlotRef get activeSlotRef => activeSlot.ref;

  BattleSideState withActive(BattleCombatant updatedActive) {
    return BattleSideState(
      id: id,
      activeSlot: activeSlot.withCombatant(updatedActive),
      reserve: reserve,
      hasStealthRock: hasStealthRock,
    );
  }

  BattleSideState withReserve(List<BattleCombatant> updatedReserve) {
    return BattleSideState(
      id: id,
      activeSlot: activeSlot,
      reserve: updatedReserve,
      hasStealthRock: hasStealthRock,
    );
  }

  BattleSideState withActiveAndReserve({
    required BattleCombatant active,
    required List<BattleCombatant> reserve,
  }) {
    return BattleSideState(
      id: id,
      activeSlot: activeSlot.withCombatant(active),
      reserve: reserve,
      hasStealthRock: hasStealthRock,
    );
  }

  BattleSideState withStealthRock(bool value) {
    return BattleSideState(
      id: id,
      activeSlot: activeSlot,
      reserve: reserve,
      hasStealthRock: value,
    );
  }
}

BattleSideState _resolveBattleStateSide({
  required BattleSideId expectedId,
  required BattleSideState? providedSide,
  required BattleCombatant? legacyActive,
  required List<BattleCombatant> legacyReserve,
  required String sideLabel,
}) {
  // Phase D choisit ici un garde-fou runtime, pas seulement un assert debug :
  // - la migration introduit deux façons de construire `BattleState` ;
  // - mélanger la nouvelle forme side-based et l'ancien chemin plat serait
  //   sinon silencieusement ambigu en release ;
  // - on préfère donc échouer explicitement plutôt que de "deviner" quelle
  //   représentation l'appelant voulait vraiment utiliser.
  if (providedSide != null &&
      (legacyActive != null || legacyReserve.isNotEmpty)) {
    throw ArgumentError(
      'BattleState.$sideLabel must be built either from $sideLabel'
      'Side or from the legacy $sideLabel/$sideLabel'
      'Reserve inputs, not both.',
    );
  }

  if (providedSide != null) {
    if (providedSide.id != expectedId) {
      throw ArgumentError(
        'BattleState.$sideLabel must carry BattleSideId.${expectedId.name}.',
      );
    }
    return providedSide;
  }

  if (legacyActive == null) {
    throw ArgumentError(
      'BattleState.$sideLabel requires either ${sideLabel}Side or '
      '$sideLabel.',
    );
  }

  return switch (expectedId) {
    BattleSideId.player => BattleSideState.player(
        active: legacyActive,
        reserve: legacyReserve,
      ),
    BattleSideId.enemy => BattleSideState.enemy(
        active: legacyActive,
        reserve: legacyReserve,
      ),
  };
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


### `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_stealth_rock.dart`

```dart
import 'battle_state.dart';
import 'battle_topology.dart';
import 'battle_type_chart.dart';

/// Événements observables strictement dédiés à Stealth Rock.
///
/// Frontière H1 volontairement dure :
/// - ce fichier n'ouvre pas un système générique de side conditions ;
/// - il ne sert qu'à rendre Stealth Rock visible et testable ;
/// - il refuse d'anticiper Spikes, Toxic Spikes, Boots, Defog, etc.
enum BattleStealthRockEventKind {
  set,
  alreadyPresent,
  damagedOnEntry,
}

/// Trace observable strictement bornée au premier slice Stealth Rock.
final class BattleStealthRockEvent {
  const BattleStealthRockEvent.set({
    required this.side,
    required this.sourceMoveId,
  })  : kind = BattleStealthRockEventKind.set,
        targetSlot = null,
        damage = null;

  const BattleStealthRockEvent.alreadyPresent({
    required this.side,
    required this.sourceMoveId,
  })  : kind = BattleStealthRockEventKind.alreadyPresent,
        targetSlot = null,
        damage = null;

  const BattleStealthRockEvent.damagedOnEntry({
    required this.side,
    required this.targetSlot,
    required this.damage,
  })  : kind = BattleStealthRockEventKind.damagedOnEntry,
        sourceMoveId = null;

  final BattleSideId side;
  final BattleStealthRockEventKind kind;
  final String? sourceMoveId;
  final BattleSlotRef? targetSlot;
  final int? damage;
}

/// Calcule les dégâts d'entrée de Stealth Rock pour un combattant.
///
/// Vérité H1 explicitement alignée sur la mécanique Showdown-like lue dans le
/// dépôt de référence :
/// - base 1/8 des PV max ;
/// - multipliée par l'efficacité du type Roche contre le typing entrant ;
/// - puis tronquée avec un minimum de 1 si l'effet est non nul.
int resolveStealthRockEntryDamage(BattleCombatant combatant) {
  final typeMultiplier = BattleTypeChart.resolveEffectivenessMultiplier(
    moveType: 'rock',
    defenderTyping: combatant.typing,
  );
  if (typeMultiplier <= 0) {
    return 0;
  }

  final scaledDamage = (combatant.maxHp * typeMultiplier / 8).floor();
  return scaledDamage < 1 ? 1 : scaledDamage;
}

```


### `/Users/karim/Project/pokemonProject/packages/map_battle/test/battle_stealth_rock_test.dart`

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

BattleMoveData _stealthRock({
  int pp = 20,
  int currentPp = 20,
}) {
  return BattleMoveData(
    id: 'stealth_rock',
    name: 'Stealth Rock',
    power: 0,
    type: 'rock',
    category: BattleMoveCategory.status,
    target: BattleMoveTarget.opponentSide,
    accuracy: BattleMoveAccuracy.alwaysHits(),
    pp: pp,
    currentPp: currentPp,
    setsStealthRock: true,
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

BattleCombatantData _combatantData({
  required String speciesId,
  required int lineupIndex,
  int maxHp = 80,
  int? currentHp,
  BattleTypingSnapshot? typing,
  BattleStatsSnapshot? stats,
  BattleMajorStatusState? majorStatus,
  required List<BattleMoveData> moves,
}) {
  return BattleCombatantData(
    speciesId: speciesId,
    lineupIndex: lineupIndex,
    level: 40,
    maxHp: maxHp,
    currentHp: currentHp,
    stats: stats ?? _stats(),
    typing: typing,
    majorStatus: majorStatus,
    moves: moves,
  );
}

BattleSession _session({
  required BattleCombatantData player,
  List<BattleCombatantData> playerReserve = const <BattleCombatantData>[],
  required BattleCombatantData enemy,
  List<BattleCombatantData> enemyReserve = const <BattleCombatantData>[],
  bool isTrainerBattle = false,
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
  );
}

BattleCombatant _battleCombatant({
  required String speciesId,
  required int maxHp,
  required BattleTypingSnapshot typing,
}) {
  return BattleCombatant(
    speciesId: speciesId,
    level: 40,
    currentHp: maxHp,
    maxHp: maxHp,
    stats: _stats(),
    typing: typing,
    moves: const <BattleMove>[],
  );
}

void main() {
  group('BattleSession H1 Stealth Rock', () {
    test('sets Stealth Rock on the opposing side with a visible event', () {
      final session = _session(
        player: _combatantData(
          speciesId: 'lead_player',
          lineupIndex: 0,
          moves: <BattleMoveData>[_stealthRock()],
        ),
        enemy: _combatantData(
          speciesId: 'lead_enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterTurn.state.enemySide.hasStealthRock, isTrue);
      expect(
        afterTurn.state.currentTurn!.stealthRockEvents
            .map((event) => event.kind)
            .toList(growable: false),
        equals(<BattleStealthRockEventKind>[
          BattleStealthRockEventKind.set,
        ]),
      );
      expect(
        afterTurn.state.currentTurn!.timeline
            .whereType<BattleTurnStealthRockEvent>(),
        hasLength(1),
      );
    });

    test('does not stack Stealth Rock when it is already present', () {
      final session = _session(
        player: _combatantData(
          speciesId: 'lead_player',
          lineupIndex: 0,
          moves: <BattleMoveData>[_stealthRock()],
        ),
        enemy: _combatantData(
          speciesId: 'lead_enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
      );

      final afterFirstSet =
          session.applyChoice(const PlayerBattleChoiceFight(0));
      final afterSecondSet =
          afterFirstSet.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterSecondSet.state.enemySide.hasStealthRock, isTrue);
      expect(
        afterSecondSet.state.currentTurn!.stealthRockEvents
            .map((event) => event.kind)
            .toList(growable: false),
        equals(<BattleStealthRockEventKind>[
          BattleStealthRockEventKind.alreadyPresent,
        ]),
      );
    });

    test('damages a voluntary switch-in on an affected side', () {
      final session = _session(
        player: _combatantData(
          speciesId: 'lead_player',
          lineupIndex: 0,
          maxHp: 60,
          moves: <BattleMoveData>[_waitingMove()],
        ),
        playerReserve: <BattleCombatantData>[
          _combatantData(
            speciesId: 'bench_player',
            lineupIndex: 1,
            maxHp: 80,
            typing: const BattleTypingSnapshot(primaryType: 'water'),
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
        enemy: _combatantData(
          speciesId: 'lead_enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[
            _stealthRock(pp: 1, currentPp: 1),
            _waitingMove(),
          ],
        ),
      );

      final afterHazard = session.applyChoice(const PlayerBattleChoiceFight(0));
      final afterSwitch =
          afterHazard.applyChoice(const PlayerBattleChoiceSwitch(0));

      final damageEvent =
          afterSwitch.state.currentTurn!.stealthRockEvents.singleWhere(
        (event) => event.kind == BattleStealthRockEventKind.damagedOnEntry,
      );
      final timeline = afterSwitch.state.currentTurn!.timeline;
      final switchIndex = timeline.indexWhere(
        (event) =>
            event is BattleTurnSwitchEvent &&
            event.event.kind == BattleSwitchEventKind.switched,
      );
      final damageIndex = timeline.indexWhere(
        (event) =>
            event is BattleTurnStealthRockEvent &&
            event.event.kind == BattleStealthRockEventKind.damagedOnEntry,
      );

      expect(afterSwitch.state.player.speciesId, equals('bench_player'));
      expect(afterSwitch.state.player.currentHp, equals(70));
      expect(damageEvent.side, equals(BattleSideId.player));
      expect(damageEvent.damage, equals(10));
      expect(switchIndex, greaterThanOrEqualTo(0));
      expect(damageIndex, greaterThan(switchIndex));
    });

    test(
      'a switch-in KO from Stealth Rock keeps the pending enemy move alive '
      'after the forced replacement',
      () {
        final session = _session(
          player: _combatantData(
            speciesId: 'lead_player',
            lineupIndex: 0,
            maxHp: 80,
            moves: <BattleMoveData>[_waitingMove()],
          ),
          playerReserve: <BattleCombatantData>[
            _combatantData(
              speciesId: 'fragile_switch',
              lineupIndex: 1,
              maxHp: 10,
              currentHp: 5,
              typing: const BattleTypingSnapshot(
                primaryType: 'fire',
                secondaryType: 'flying',
              ),
              moves: <BattleMoveData>[_waitingMove()],
            ),
            _combatantData(
              speciesId: 'follow_up_switch',
              lineupIndex: 2,
              maxHp: 80,
              currentHp: 80,
              typing: const BattleTypingSnapshot(primaryType: 'water'),
              moves: <BattleMoveData>[_waitingMove()],
            ),
          ],
          enemy: _combatantData(
            speciesId: 'lead_enemy',
            lineupIndex: 0,
            stats: _stats(speed: 30, attack: 90),
            moves: <BattleMoveData>[
              _stealthRock(pp: 1, currentPp: 1),
              _tackle(power: 40),
            ],
          ),
        );

        final afterHazard =
            session.applyChoice(const PlayerBattleChoiceFight(0));
        final afterFailedEntry =
            afterHazard.applyChoice(const PlayerBattleChoiceSwitch(0));

        expect(
          afterFailedEntry.decisionRequest,
          isA<BattleForcedReplacementRequest>(),
        );
        expect(afterFailedEntry.state.player.isFainted, isTrue);
        expect(
          afterFailedEntry.state.currentTurn!.switchEvents.last.kind,
          equals(BattleSwitchEventKind.replacementRequired),
        );

        final resumedTurn =
            afterFailedEntry.applyChoice(const PlayerBattleChoiceSwitch(1));
        final switchEvents = resumedTurn.state.currentTurn!.timeline
            .whereType<BattleTurnSwitchEvent>()
            .toList(growable: false);
        final damageIndex = resumedTurn.state.currentTurn!.timeline.indexWhere(
          (event) =>
              event is BattleTurnStealthRockEvent &&
              event.event.kind == BattleStealthRockEventKind.damagedOnEntry,
        );
        final replacementSwitchIndex =
            resumedTurn.state.currentTurn!.timeline.indexWhere(
          (event) =>
              event is BattleTurnSwitchEvent &&
              event.event.kind == BattleSwitchEventKind.switched &&
              event.event.toSpeciesId == 'follow_up_switch',
        );
        final attackIndex = resumedTurn.state.currentTurn!.timeline.indexWhere(
          (event) => event is BattleTurnExecutionEvent,
        );

        expect(resumedTurn.state.player.speciesId, equals('follow_up_switch'));
        expect(resumedTurn.state.currentTurn!.executions, isNotEmpty);
        expect(
          switchEvents.map((event) => event.event.kind),
          containsAllInOrder(<BattleSwitchEventKind>[
            BattleSwitchEventKind.switched,
            BattleSwitchEventKind.replacementRequired,
            BattleSwitchEventKind.switched,
          ]),
        );
        expect(damageIndex, greaterThanOrEqualTo(0));
        expect(replacementSwitchIndex, greaterThan(damageIndex));
        expect(attackIndex, greaterThan(replacementSwitchIndex));
      },
    );

    test('damages an enemy auto-switch after a KO', () {
      final session = _session(
        isTrainerBattle: true,
        player: _combatantData(
          speciesId: 'lead_player',
          lineupIndex: 0,
          stats: _stats(speed: 90, attack: 100),
          moves: <BattleMoveData>[
            _stealthRock(),
            _tackle(power: 250),
          ],
        ),
        enemy: _combatantData(
          speciesId: 'lead_enemy',
          lineupIndex: 0,
          maxHp: 40,
          stats: _stats(speed: 20),
          moves: <BattleMoveData>[_waitingMove()],
        ),
        enemyReserve: <BattleCombatantData>[
          _combatantData(
            speciesId: 'bench_enemy',
            lineupIndex: 1,
            maxHp: 80,
            typing: const BattleTypingSnapshot(
              primaryType: 'fire',
              secondaryType: 'flying',
            ),
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
      );

      final afterHazard = session.applyChoice(const PlayerBattleChoiceFight(0));
      final afterKo = afterHazard.applyChoice(const PlayerBattleChoiceFight(1));

      final damageEvent =
          afterKo.state.currentTurn!.stealthRockEvents.singleWhere(
        (event) => event.kind == BattleStealthRockEventKind.damagedOnEntry,
      );
      final timeline = afterKo.state.currentTurn!.timeline;
      final switchIndex = timeline.indexWhere(
        (event) =>
            event is BattleTurnSwitchEvent &&
            event.event.side == BattleSideId.enemy,
      );
      final damageIndex = timeline.indexWhere(
        (event) =>
            event is BattleTurnStealthRockEvent &&
            event.event.kind == BattleStealthRockEventKind.damagedOnEntry,
      );

      expect(afterKo.state.enemy.speciesId, equals('bench_enemy'));
      expect(afterKo.state.enemy.currentHp, equals(40));
      expect(damageEvent.side, equals(BattleSideId.enemy));
      expect(damageEvent.damage, equals(40));
      expect(switchIndex, greaterThanOrEqualTo(0));
      expect(damageIndex, greaterThan(switchIndex));
    });

    test('damages a forced player replacement when the new active enters', () {
      final session = _session(
        player: _combatantData(
          speciesId: 'lead_player',
          lineupIndex: 0,
          maxHp: 80,
          currentHp: 15,
          majorStatus: const BattleMajorStatusState.tox(toxicCounter: 1),
          stats: _stats(speed: 20),
          moves: <BattleMoveData>[_waitingMove()],
        ),
        playerReserve: <BattleCombatantData>[
          _combatantData(
            speciesId: 'bench_player',
            lineupIndex: 1,
            maxHp: 80,
            typing: const BattleTypingSnapshot(primaryType: 'water'),
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
        enemy: _combatantData(
          speciesId: 'lead_enemy',
          lineupIndex: 0,
          stats: _stats(speed: 90),
          moves: <BattleMoveData>[_stealthRock()],
        ),
      );

      final afterHazard = session.applyChoice(const PlayerBattleChoiceFight(0));
      final afterKo = afterHazard.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterKo.decisionRequest, isA<BattleForcedReplacementRequest>());

      final afterReplacement =
          afterKo.applyChoice(const PlayerBattleChoiceSwitch(0));

      final damageEvent =
          afterReplacement.state.currentTurn!.stealthRockEvents.singleWhere(
        (event) => event.kind == BattleStealthRockEventKind.damagedOnEntry,
      );
      final timeline = afterReplacement.state.currentTurn!.timeline;
      final switchIndex = timeline.indexWhere(
        (event) =>
            event is BattleTurnSwitchEvent &&
            event.event.side == BattleSideId.player,
      );
      final damageIndex = timeline.indexWhere(
        (event) =>
            event is BattleTurnStealthRockEvent &&
            event.event.kind == BattleStealthRockEventKind.damagedOnEntry,
      );

      expect(afterReplacement.state.player.speciesId, equals('bench_player'));
      expect(afterReplacement.state.player.currentHp, equals(70));
      expect(afterReplacement.state.currentTurn!.enemyAction,
          isA<BattleActionNone>());
      expect(damageEvent.side, equals(BattleSideId.player));
      expect(damageEvent.damage, equals(10));
      expect(switchIndex, greaterThanOrEqualTo(0));
      expect(damageIndex, greaterThan(switchIndex));
    });

    test(
      'waits until the enemy auto-switch chain settles before asking the '
      'player to replace after a double KO',
      () {
        final session = _session(
          isTrainerBattle: true,
          player: _combatantData(
            speciesId: 'lead_player',
            lineupIndex: 0,
            maxHp: 10,
            currentHp: 2,
            majorStatus: const BattleMajorStatusState.psn(),
            moves: <BattleMoveData>[
              _stealthRock(pp: 1, currentPp: 1),
              _waitingMove(),
            ],
          ),
          playerReserve: <BattleCombatantData>[
            _combatantData(
              speciesId: 'player_backup',
              lineupIndex: 1,
              maxHp: 80,
              currentHp: 80,
              typing: const BattleTypingSnapshot(primaryType: 'water'),
              moves: <BattleMoveData>[_waitingMove()],
            ),
          ],
          enemy: _combatantData(
            speciesId: 'lead_enemy',
            lineupIndex: 0,
            maxHp: 10,
            currentHp: 2,
            majorStatus: const BattleMajorStatusState.psn(),
            moves: <BattleMoveData>[_waitingMove()],
          ),
          enemyReserve: <BattleCombatantData>[
            _combatantData(
              speciesId: 'fragile_enemy_backup',
              lineupIndex: 1,
              maxHp: 10,
              currentHp: 5,
              typing: const BattleTypingSnapshot(
                primaryType: 'fire',
                secondaryType: 'flying',
              ),
              moves: <BattleMoveData>[_waitingMove()],
            ),
            _combatantData(
              speciesId: 'stable_enemy_backup',
              lineupIndex: 2,
              maxHp: 80,
              currentHp: 80,
              typing: const BattleTypingSnapshot(primaryType: 'water'),
              moves: <BattleMoveData>[_waitingMove()],
            ),
          ],
        );

        final afterHazard =
            session.applyChoice(const PlayerBattleChoiceFight(0));
        final afterDoubleKo =
            afterHazard.applyChoice(const PlayerBattleChoiceFight(1));

        final switchEvents = afterDoubleKo.state.currentTurn!.timeline
            .whereType<BattleTurnSwitchEvent>()
            .toList(growable: false);

        expect(
          afterDoubleKo.decisionRequest,
          isA<BattleForcedReplacementRequest>(),
        );
        expect(
          switchEvents.map((event) => event.event.kind).toList(growable: false),
          equals(<BattleSwitchEventKind>[
            BattleSwitchEventKind.switched,
            BattleSwitchEventKind.switched,
            BattleSwitchEventKind.replacementRequired,
          ]),
        );
        expect(
          switchEvents[0].event.toSpeciesId,
          equals('fragile_enemy_backup'),
        );
        expect(
          switchEvents[1].event.toSpeciesId,
          equals('stable_enemy_backup'),
        );
        expect(
          switchEvents.last.event.side,
          equals(BattleSideId.player),
        );
      },
    );

    test(
      'does not emit a bogus player replacement when the last enemy reserve '
      'dies to Stealth Rock after a double KO',
      () {
        final session = _session(
          isTrainerBattle: true,
          player: _combatantData(
            speciesId: 'lead_player',
            lineupIndex: 0,
            maxHp: 10,
            currentHp: 2,
            majorStatus: const BattleMajorStatusState.psn(),
            moves: <BattleMoveData>[
              _stealthRock(pp: 1, currentPp: 1),
              _waitingMove(),
            ],
          ),
          playerReserve: <BattleCombatantData>[
            _combatantData(
              speciesId: 'player_backup',
              lineupIndex: 1,
              maxHp: 80,
              currentHp: 80,
              typing: const BattleTypingSnapshot(primaryType: 'water'),
              moves: <BattleMoveData>[_waitingMove()],
            ),
          ],
          enemy: _combatantData(
            speciesId: 'lead_enemy',
            lineupIndex: 0,
            maxHp: 10,
            currentHp: 2,
            majorStatus: const BattleMajorStatusState.psn(),
            moves: <BattleMoveData>[_waitingMove()],
          ),
          enemyReserve: <BattleCombatantData>[
            _combatantData(
              speciesId: 'fragile_enemy_backup',
              lineupIndex: 1,
              maxHp: 10,
              currentHp: 5,
              typing: const BattleTypingSnapshot(
                primaryType: 'fire',
                secondaryType: 'flying',
              ),
              moves: <BattleMoveData>[_waitingMove()],
            ),
          ],
        );

        final afterHazard =
            session.applyChoice(const PlayerBattleChoiceFight(0));
        final afterDoubleKo =
            afterHazard.applyChoice(const PlayerBattleChoiceFight(1));

        expect(afterDoubleKo.state.isFinished, isTrue);
        expect(
          afterDoubleKo.state.outcome?.type,
          equals(BattleOutcomeType.victory),
        );
        expect(
          afterDoubleKo.state.currentTurn!.switchEvents
              .where(
                (event) =>
                    event.kind == BattleSwitchEventKind.replacementRequired,
              )
              .toList(growable: false),
          isEmpty,
        );
      },
    );

    test(
        'resolves Stealth Rock damage from Rock effectiveness with a minimum of one',
        () {
      final quadrupleWeak = _battleCombatant(
        speciesId: 'charizard_like',
        maxHp: 80,
        typing: const BattleTypingSnapshot(
          primaryType: 'fire',
          secondaryType: 'flying',
        ),
      );
      final quarterResist = _battleCombatant(
        speciesId: 'resist_like',
        maxHp: 20,
        typing: const BattleTypingSnapshot(
          primaryType: 'fighting',
          secondaryType: 'ground',
        ),
      );

      expect(resolveStealthRockEntryDamage(quadrupleWeak), equals(40));
      expect(resolveStealthRockEntryDamage(quarterResist), equals(1));
    });
  });
}

```


### `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart`

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
/// - puis BE7 ouvre un petit sous-ensemble `applyStatus` pour les statuts
///   majeurs `par`, `brn`, `psn`, `tox` ;
/// - puis BE8 ouvre seulement quelques volatiles utiles strictement bornés :
///   `protect`, `breakProtect`, `requireRecharge`, `chargeThenStrike` ;
/// - puis BE9 ouvre seulement un petit sous-ensemble field réellement
///   consommé : `raindance`, `sandstorm`, `trickroom` ;
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
    BattleMoveMajorStatusEffect? majorStatusEffect;
    BattleVolatileStatusId? selfVolatileStatus;
    BattleWeatherId? weatherEffect;
    BattlePseudoWeatherId? pseudoWeatherEffect;
    var setsStealthRock = false;
    var breaksProtect = false;
    var requiresRecharge = false;
    BattleChargeThenStrikeEffect? chargeThenStrikeEffect;

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
        applyStatus: (effect) {
          if (majorStatusEffect != null) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'multiple_apply_status_effects_not_supported',
            );
          }

          if (effect.targetScope != PokemonMoveEffectTargetScope.target) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit:
                  'unsupported_apply_status_scope:${effect.targetScope.name}',
            );
          }
          if (target != BattleMoveTarget.opponent) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'unsupported_apply_status_target:${target.name}',
            );
          }

          if (effect.chance case final chance?) {
            if (chance < 1 || chance > 100) {
              _rejectMove(
                move: move,
                combatantLabel: combatantLabel,
                bridgeLimit: 'invalid_apply_status_chance:$chance',
              );
            }
          }

          majorStatusEffect = BattleMoveMajorStatusEffect(
            status: _translateSupportedMajorStatus(
              move: move,
              combatantLabel: combatantLabel,
              statusId: effect.statusId,
            ),
            chancePercent: effect.chance,
          );
        },
        applyVolatileStatus: (effect) {
          // BE8 n'ouvre surtout pas tout `applyVolatileStatus`.
          // Le bridge accepte uniquement le plus petit seam devenu exécutable :
          // - `protect` auto-appliqué au lanceur ;
          // - déterministe ;
          // - aucune autre taxonomie de volatile.
          if (selfVolatileStatus != null) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit:
                  'multiple_apply_volatile_status_effects_not_supported',
            );
          }
          if (effect.targetScope != PokemonMoveEffectTargetScope.self) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit:
                  'unsupported_apply_volatile_status_scope:${effect.targetScope.name}',
            );
          }
          if (target != BattleMoveTarget.self) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit:
                  'unsupported_apply_volatile_status_target:${target.name}',
            );
          }
          if (effect.chance != null) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'probabilistic_apply_volatile_status_not_supported',
            );
          }

          selfVolatileStatus = _translateSupportedSelfVolatileStatus(
            move: move,
            combatantLabel: combatantLabel,
            volatileStatusId: effect.volatileStatusId,
          );
        },
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
        setWeather: (effect) {
          if (weatherEffect != null) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'multiple_set_weather_effects_not_supported',
            );
          }
          if (effect.targetScope != PokemonMoveEffectTargetScope.field) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit:
                  'unsupported_set_weather_scope:${effect.targetScope.name}',
            );
          }
          if (target != BattleMoveTarget.field) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'unsupported_set_weather_target:${target.name}',
            );
          }
          if (effect.chance != null) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'probabilistic_set_weather_not_supported',
            );
          }
          if (move.usesStandardDamageFlow) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'unsupported_set_weather_move_shape',
            );
          }
          weatherEffect = _translateSupportedWeather(
            move: move,
            combatantLabel: combatantLabel,
            weatherId: effect.weatherId,
          );
        },
        setTerrain: (_) => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_effect_kind:set_terrain',
        ),
        setPseudoWeather: (effect) {
          if (pseudoWeatherEffect != null) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'multiple_set_pseudo_weather_effects_not_supported',
            );
          }
          if (effect.targetScope != PokemonMoveEffectTargetScope.field) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit:
                  'unsupported_set_pseudo_weather_scope:${effect.targetScope.name}',
            );
          }
          if (target != BattleMoveTarget.field) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit:
                  'unsupported_set_pseudo_weather_target:${target.name}',
            );
          }
          if (effect.chance != null) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'probabilistic_set_pseudo_weather_not_supported',
            );
          }
          if (move.usesStandardDamageFlow) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'unsupported_set_pseudo_weather_move_shape',
            );
          }
          pseudoWeatherEffect = _translateSupportedPseudoWeather(
            move: move,
            combatantLabel: combatantLabel,
            pseudoWeatherId: effect.pseudoWeatherId,
          );
        },
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
        breakProtect: (effect) {
          if (breaksProtect) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'multiple_break_protect_effects_not_supported',
            );
          }
          if (effect.targetScope != PokemonMoveEffectTargetScope.target) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit:
                  'unsupported_break_protect_scope:${effect.targetScope.name}',
            );
          }
          if (target != BattleMoveTarget.opponent) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'unsupported_break_protect_target:${target.name}',
            );
          }
          if (effect.chance != null) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'probabilistic_break_protect_not_supported',
            );
          }
          breaksProtect = true;
        },
        requireRecharge: (effect) {
          if (requiresRecharge) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'multiple_require_recharge_effects_not_supported',
            );
          }
          if (effect.targetScope != PokemonMoveEffectTargetScope.self) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit:
                  'unsupported_require_recharge_scope:${effect.targetScope.name}',
            );
          }
          if (effect.chance != null) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'probabilistic_require_recharge_not_supported',
            );
          }
          if (!move.usesStandardDamageFlow ||
              target != BattleMoveTarget.opponent) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'unsupported_require_recharge_move_shape',
            );
          }
          requiresRecharge = true;
        },
        chargeThenStrike: (effect) {
          if (chargeThenStrikeEffect != null) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'multiple_charge_then_strike_effects_not_supported',
            );
          }
          if (effect.targetScope != PokemonMoveEffectTargetScope.self) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit:
                  'unsupported_charge_then_strike_scope:${effect.targetScope.name}',
            );
          }
          if (effect.chance != null) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'probabilistic_charge_then_strike_not_supported',
            );
          }
          if (!move.usesStandardDamageFlow ||
              target != BattleMoveTarget.opponent) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'unsupported_charge_then_strike_move_shape',
            );
          }
          chargeThenStrikeEffect = BattleChargeThenStrikeEffect(
            chargeStateId: _normalizeOptionalId(effect.chargeStateId),
          );
        },
        setSideCondition: (effect) {
          if (setsStealthRock) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'multiple_set_side_condition_effects_not_supported',
            );
          }
          if (effect.targetScope != PokemonMoveEffectTargetScope.foeSide) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit:
                  'unsupported_set_side_condition_scope:${effect.targetScope.name}',
            );
          }
          if (target != BattleMoveTarget.opponentSide) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit:
                  'unsupported_set_side_condition_target:${target.name}',
            );
          }
          if (effect.chance != null) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'probabilistic_set_side_condition_not_supported',
            );
          }
          if (move.usesStandardDamageFlow) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'unsupported_set_side_condition_move_shape',
            );
          }
          final normalizedConditionId = effect.conditionId.trim().toLowerCase();
          if (normalizedConditionId != 'stealthrock') {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'unsupported_side_condition:$normalizedConditionId',
            );
          }
          setsStealthRock = true;
        },
        setSlotCondition: (_) => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_effect_kind:set_slot_condition',
        ),
      );
    }

    // BE8 revendique un sous-ensemble exact, pas une "approximation large".
    // On refuse donc explicitement les combinaisons d'effets qui ne font pas
    // partie du petit contrat local ouvert par ce lot, même si chaque brique
    // isolée serait supportée séparément.
    if (requiresRecharge && chargeThenStrikeEffect != null) {
      _rejectMove(
        move: move,
        combatantLabel: combatantLabel,
        bridgeLimit: 'unsupported_combined_charge_then_recharge',
      );
    }
    if ((weatherEffect != null || pseudoWeatherEffect != null) &&
        (majorStatusEffect != null ||
            selfVolatileStatus != null ||
            breaksProtect ||
            requiresRecharge ||
            chargeThenStrikeEffect != null ||
            selfChanges.isNotEmpty ||
            targetChanges.isNotEmpty)) {
      _rejectMove(
        move: move,
        combatantLabel: combatantLabel,
        bridgeLimit: 'unsupported_combined_field_effect_move',
      );
    }
    if (weatherEffect != null && pseudoWeatherEffect != null) {
      _rejectMove(
        move: move,
        combatantLabel: combatantLabel,
        bridgeLimit: 'multiple_field_effect_kinds_not_supported',
      );
    }
    if (setsStealthRock &&
        (majorStatusEffect != null ||
            selfVolatileStatus != null ||
            weatherEffect != null ||
            pseudoWeatherEffect != null ||
            breaksProtect ||
            requiresRecharge ||
            chargeThenStrikeEffect != null ||
            selfChanges.isNotEmpty ||
            targetChanges.isNotEmpty)) {
      _rejectMove(
        move: move,
        combatantLabel: combatantLabel,
        bridgeLimit: 'unsupported_combined_stealth_rock_move',
      );
    }

    // Un move battle exécutable doit avoir au moins un chemin d'exécution
    // réel pour le moteur actuel :
    // - soit des dégâts standards ;
    // - soit des changements d'étages de stats déterministes ;
    // - soit un effet `applyStatus` BE7 réellement supporté ;
    // - soit une pose de champ réellement consommée en BE9 ;
    // - soit une combinaison de ces chemins-là quand elle est explicitement
    //   autorisée plus haut.
    if (!move.usesStandardDamageFlow &&
        selfChanges.isEmpty &&
        targetChanges.isEmpty &&
        majorStatusEffect == null &&
        selfVolatileStatus == null &&
        weatherEffect == null &&
        pseudoWeatherEffect == null &&
        !setsStealthRock) {
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
      majorStatusEffect: majorStatusEffect,
      selfVolatileStatus: selfVolatileStatus,
      weatherEffect: weatherEffect,
      pseudoWeatherEffect: pseudoWeatherEffect,
      setsStealthRock: setsStealthRock,
      breaksProtect: breaksProtect,
      requiresRecharge: requiresRecharge,
      chargeThenStrikeEffect: chargeThenStrikeEffect,
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
            PokemonMoveEngineSupportLevel.structuredSupported ||
        _allowsStructuredPartialFieldMove(move)) {
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
    if (_isPureFieldMoveCandidate(move)) {
      return switch (move.target) {
        // Recadrage BE9 après review :
        // - le sous-ensemble honnête réellement seedé dans ce repo pose la
        //   météo / Trick Room avec `target: all` ;
        // - accepter aussi `self` élargissait inutilement le contrat et
        //   laissait passer un faux field move malformé ;
        // - on garde donc un bridge strict au lieu d'une tolérance qui ne
        //   sert aucun cas réel confirmé par l'audit.
        PokemonMoveTarget.all => BattleMoveTarget.field,
        _ => _rejectMove(
            move: move,
            combatantLabel: combatantLabel,
            bridgeLimit: 'unsupported_field_target:${move.target.name}',
          ),
      };
    }

    return switch (move.target) {
      PokemonMoveTarget.self => BattleMoveTarget.self,
      PokemonMoveTarget.normal ||
      PokemonMoveTarget.adjacentFoe ||
      PokemonMoveTarget.allAdjacentFoes ||
      PokemonMoveTarget.randomNormal =>
        BattleMoveTarget.opponent,
      PokemonMoveTarget.foeSide when _isPureStealthRockMoveCandidate(move) =>
        BattleMoveTarget.opponentSide,
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

  BattleMajorStatusId _translateSupportedMajorStatus({
    required PokemonMove move,
    required String combatantLabel,
    required String statusId,
  }) {
    final normalizedStatusId = statusId.trim().toLowerCase();
    return switch (normalizedStatusId) {
      'par' => BattleMajorStatusId.par,
      'brn' => BattleMajorStatusId.brn,
      'psn' => BattleMajorStatusId.psn,
      'tox' => BattleMajorStatusId.tox,
      _ => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_major_status:$normalizedStatusId',
        ),
    };
  }

  BattleVolatileStatusId _translateSupportedSelfVolatileStatus({
    required PokemonMove move,
    required String combatantLabel,
    required String volatileStatusId,
  }) {
    final normalizedStatusId = volatileStatusId.trim().toLowerCase();
    return switch (normalizedStatusId) {
      'protect' => BattleVolatileStatusId.protect,
      _ => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_volatile_status:$normalizedStatusId',
        ),
    };
  }

  BattleWeatherId _translateSupportedWeather({
    required PokemonMove move,
    required String combatantLabel,
    required String weatherId,
  }) {
    final normalizedWeatherId = weatherId.trim().toLowerCase();
    return switch (normalizedWeatherId) {
      'raindance' => BattleWeatherId.rain,
      'sandstorm' => BattleWeatherId.sandstorm,
      _ => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_weather:$normalizedWeatherId',
        ),
    };
  }

  BattlePseudoWeatherId _translateSupportedPseudoWeather({
    required PokemonMove move,
    required String combatantLabel,
    required String pseudoWeatherId,
  }) {
    final normalizedPseudoWeatherId = pseudoWeatherId.trim().toLowerCase();
    return switch (normalizedPseudoWeatherId) {
      'trickroom' => BattlePseudoWeatherId.trickRoom,
      _ => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_pseudo_weather:$normalizedPseudoWeatherId',
        ),
    };
  }

  bool _isPureFieldMoveCandidate(PokemonMove move) {
    if (move.usesStandardDamageFlow) {
      return false;
    }
    if (move.effects.isEmpty) {
      return false;
    }
    return move.effects.every(
      (effect) => effect.map(
        fixedDamage: (_) => false,
        multiHit: (_) => false,
        applyStatus: (_) => false,
        applyVolatileStatus: (_) => false,
        modifyStats: (_) => false,
        heal: (_) => false,
        drain: (_) => false,
        recoil: (_) => false,
        setWeather: (_) => true,
        setTerrain: (_) => false,
        setPseudoWeather: (_) => true,
        selfSwitch: (_) => false,
        forceSwitch: (_) => false,
        breakProtect: (_) => false,
        requireRecharge: (_) => false,
        chargeThenStrike: (_) => false,
        setSideCondition: (_) => false,
        setSlotCondition: (_) => false,
      ),
    );
  }

  bool _allowsStructuredPartialFieldMove(PokemonMove move) {
    if (move.engineSupportLevel !=
        PokemonMoveEngineSupportLevel.structuredPartial) {
      return false;
    }
    if (!_isPureFieldMoveCandidate(move)) {
      return false;
    }

    // Recadrage BE9 :
    // - on n'ouvre pas globalement tous les moves `structuredPartial` ;
    // - on autorise uniquement les vieux catalogues qui marquaient encore
    //   `Trick Room` comme partiel faute de couche de champ/durée ;
    // - tout autre motif de partial support reste refusé par défaut.
    const allowedReasons = <String>{
      'unsupported_mechanic:turn_order_inversion',
      'unsupported_mechanic:condition',
      'showdown_callback:condition.durationCallback',
      'showdown_callback:condition.onFieldEnd',
      'showdown_callback:condition.onFieldRestart',
      'showdown_callback:condition.onFieldStart',
    };
    return move.unsupportedReasons.every(allowedReasons.contains);
  }

  bool _isPureStealthRockMoveCandidate(PokemonMove move) {
    if (move.usesStandardDamageFlow || move.effects.isEmpty) {
      return false;
    }

    return move.effects.every(
      (effect) => effect.map(
        fixedDamage: (_) => false,
        multiHit: (_) => false,
        applyStatus: (_) => false,
        applyVolatileStatus: (_) => false,
        modifyStats: (_) => false,
        heal: (_) => false,
        drain: (_) => false,
        recoil: (_) => false,
        setWeather: (_) => false,
        setTerrain: (_) => false,
        setPseudoWeather: (_) => false,
        selfSwitch: (_) => false,
        forceSwitch: (_) => false,
        breakProtect: (_) => false,
        requireRecharge: (_) => false,
        chargeThenStrike: (_) => false,
        setSideCondition: (effect) =>
            effect.targetScope == PokemonMoveEffectTargetScope.foeSide &&
            effect.chance == null &&
            effect.conditionId.trim().toLowerCase() == 'stealthrock',
        setSlotCondition: (_) => false,
      ),
    );
  }

  String? _normalizeOptionalId(String? value) {
    if (value == null) {
      return null;
    }
    final normalizedValue = value.trim();
    return normalizedValue.isEmpty ? null : normalizedValue;
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


### `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`

```dart
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';
import 'package:map_battle/map_battle.dart';

/// Retourne le prompt de décision à afficher pour la requête courante.
///
/// Phase C utilise cette petite fonction pure pour une raison concrète :
/// - l'overlay doit désormais afficher le *type* de requête demandé par le
///   moteur, pas déduire ce type depuis une liste plate de choix ;
/// - garder ce formatage dans un helper pur permet aussi de le verrouiller en
///   test sans devoir piloter tout le composant Flame ;
/// - on reste très loin d'un système de présentation générique.
String buildBattleDecisionPromptForOverlay(BattleDecisionRequest request) {
  return switch (request) {
    BattleTurnChoiceRequest() => 'Que doit faire le joueur ?',
    BattleForcedReplacementRequest() =>
      'Le joueur doit remplacer son Pokémon K.O.',
    BattleContinueRequest() => 'Le joueur doit continuer un tour forcé',
    BattleWaitRequest(:final reason) => switch (reason) {
        BattleWaitReason.battleFinished => 'Combat terminé',
        BattleWaitReason.resolvingTurn => 'Résolution du tour en cours',
        BattleWaitReason.activeFaintedWithoutReplacement =>
          'Aucun remplaçant disponible',
        BattleWaitReason.noLegalChoice => 'Aucune décision légale disponible',
      },
  };
}

/// Construit les lignes de restitution d'un tour pour l'overlay runtime.
///
/// BE10A centralise ici la restitution textuelle pour une raison précise :
/// - l'overlay ne doit plus réinventer l'ordre du tour en triant des buckets ;
/// - la vraie source de vérité est désormais `BattleTurnResult.timeline` ;
/// - cette fonction garde donc la surface runtime alignée sur la chronologie
///   réellement produite par le moteur battle.
///
/// Garde-fou volontaire :
/// - si un `BattleTurnResult` porte encore des buckets non vides sans
///   chronologie ordonnée, on échoue explicitement ;
/// - mieux vaut un seam bruyant qu'une UI qui raconte un ordre faux.
List<String> buildBattleTurnLinesForOverlay(BattleTurnResult turnResult) {
  if (turnResult.timeline.isEmpty &&
      (turnResult.executions.isNotEmpty ||
          turnResult.statusEvents.isNotEmpty ||
          turnResult.volatileEvents.isNotEmpty ||
          turnResult.fieldEvents.isNotEmpty ||
          turnResult.stealthRockEvents.isNotEmpty ||
          turnResult.switchEvents.isNotEmpty)) {
    throw StateError(
      'BattleTurnResult.timeline est requis pour afficher honnêtement la chronologie du tour dans l’overlay runtime.',
    );
  }

  final lines = <String>[];
  for (final event in turnResult.timeline) {
    switch (event) {
      case BattleTurnExecutionEvent(:final execution):
        final attacker = _overlayCombatantLabelForSide(execution.attackerSide);
        lines.add(
          '$attacker utilise ${execution.move.name} → ${execution.damage} dégâts',
        );
      case BattleTurnStatusEvent(:final event):
        lines.add(_formatOverlayStatusEvent(event));
      case BattleTurnVolatileEvent(:final event):
        lines.add(_formatOverlayVolatileEvent(event));
      case BattleTurnFieldEvent(:final event):
        lines.add(_formatOverlayFieldEvent(event));
      case BattleTurnStealthRockEvent(:final event):
        lines.add(_formatOverlayStealthRockEvent(event));
      case BattleTurnSwitchEvent(:final event):
        lines.add(_formatOverlaySwitchEvent(event));
    }
  }

  return List<String>.unmodifiable(lines);
}

String _formatOverlaySwitchEvent(BattleSwitchEvent event) {
  final actor = _overlayCombatantLabelForSide(event.side);
  return switch (event.kind) {
    BattleSwitchEventKind.switched => event.wasForced
        ? '$actor remplace ${event.fromSpeciesId} par ${event.toSpeciesId}'
        : '$actor switch de ${event.fromSpeciesId} vers ${event.toSpeciesId}',
    BattleSwitchEventKind.replacementRequired =>
      '$actor doit remplacer ${event.fromSpeciesId} K.O.',
  };
}

String _formatOverlayStatusEvent(BattleStatusEvent event) {
  final actor = _overlayCombatantLabelForSide(event.targetSide);
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

String _formatOverlayVolatileEvent(BattleVolatileEvent event) {
  final actor = _overlayCombatantLabelForSide(event.actorSide);
  final target = event.targetSide == null
      ? null
      : _overlayCombatantLabelForSide(event.targetSide!);

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

String _formatOverlayFieldEvent(BattleFieldEvent event) {
  return switch (event.kind) {
    BattleFieldEventKind.weatherSet =>
      'Le champ passe à ${_overlayWeatherLabel(event.weather!)}',
    BattleFieldEventKind.weatherResidualDamage =>
      '${_overlayCombatantLabelForSide(event.targetSide!)} subit ${event.damage} dégâts de ${_overlayWeatherLabel(event.weather!)}',
    BattleFieldEventKind.weatherExpired =>
      '${_overlayWeatherLabel(event.weather!)} prend fin',
    BattleFieldEventKind.pseudoWeatherSet =>
      '${_overlayPseudoWeatherLabel(event.pseudoWeather!)} devient actif',
    BattleFieldEventKind.pseudoWeatherCleared =>
      '${_overlayPseudoWeatherLabel(event.pseudoWeather!)} est dissipé',
    BattleFieldEventKind.pseudoWeatherExpired =>
      '${_overlayPseudoWeatherLabel(event.pseudoWeather!)} prend fin',
  };
}

String _formatOverlayStealthRockEvent(BattleStealthRockEvent event) {
  final actor = _overlayCombatantLabelForSide(event.side);
  return switch (event.kind) {
    BattleStealthRockEventKind.set => 'Stealth Rock est posé du côté $actor',
    BattleStealthRockEventKind.alreadyPresent =>
      'Stealth Rock est déjà posé du côté $actor',
    BattleStealthRockEventKind.damagedOnEntry =>
      '$actor subit ${event.damage} dégâts de Stealth Rock à l’entrée',
  };
}

String _overlayCombatantLabelForSide(BattleSideId side) {
  return side == BattleSideId.player ? 'Joueur' : 'Ennemi';
}

String _overlayWeatherLabel(BattleWeatherId weather) {
  return switch (weather) {
    BattleWeatherId.rain => 'la pluie',
    BattleWeatherId.sandstorm => 'la tempête de sable',
  };
}

String _overlayPseudoWeatherLabel(BattlePseudoWeatherId pseudoWeather) {
  return switch (pseudoWeather) {
    BattlePseudoWeatherId.trickRoom => 'Trick Room',
  };
}

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
  TextComponent? _choicesTitleText;

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
    _choicesTitleText = TextComponent(
      text: buildBattleDecisionPromptForOverlay(_session.decisionRequest),
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
    _panel!.add(_choicesTitleText!);

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
    _choicesTitleText?.text =
        buildBattleDecisionPromptForOverlay(newSession.decisionRequest);

    // Afficher le résultat du tour si disponible
    _updateTurnResult();

    // Si le combat est fini, afficher le résultat
    if (newSession.state.isFinished) {
      _showOutcome(newSession.state.outcome!);
    } else {
      // Combat toujours en cours — maintenir la sélection cohérente
      // Clamper l'index si le nombre de choix a changé
      final choices = newSession.decisionRequest.allowedChoices;
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

    final lines = buildBattleTurnLinesForOverlay(turnResult);

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
    final request = _session.decisionRequest;
    final choices = request.allowedChoices;
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
      final text = _getChoiceText(request, choice);
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
  String _getChoiceText(
    BattleDecisionRequest request,
    PlayerBattleChoice choice,
  ) {
    if (choice is PlayerBattleChoiceFight) {
      // Lit les moves depuis _session.state.player.moves — toujours à jour
      final move = _session.state.player.moves[choice.moveIndex];
      return '⚔ ${move.name} (Puissance: ${move.power})';
    } else if (choice is PlayerBattleChoiceSwitch) {
      final reserve = _session.state.playerReserve[choice.reserveIndex];
      final isForcedReplacement = request is BattleForcedReplacementRequest;
      final actionLabel = isForcedReplacement ? 'Remplacer par' : 'Switch vers';
      return '↔ $actionLabel ${reserve.speciesId} '
          '(${reserve.currentHp}/${reserve.maxHp} PV)';
    } else if (choice is PlayerBattleChoiceContinue) {
      // Phase C cesse ici d'inférer le sens du tour forcé depuis l'état
      // volatile brut : la vraie source de vérité est désormais la requête.
      if (request case BattleContinueRequest(:final reason)) {
        if (reason == BattleContinueReason.pendingChargeRelease) {
          return 'Continuer (libérer la charge)';
        }
        if (reason == BattleContinueReason.mustRecharge) {
          return 'Continuer (recharge)';
        }
      }
      return 'Continuer';
    } else if (choice is PlayerBattleChoiceCapture) {
      return 'Capturer';
    } else if (choice is PlayerBattleChoiceRun) {
      return '🏃 Fuir';
    }
    return '???';
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


### `/Users/karim/Project/pokemonProject/packages/map_runtime/test/battle_overlay_component_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_runtime/src/presentation/flame/battle_overlay_component.dart';

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
  );
}

void main() {
  group('BattleOverlayComponent Phase C decision prompts', () {
    test('uses the request type instead of a flat choice list heuristic', () {
      final freeTurnSession = _session(
        player: _combatant(
          speciesId: 'lead_player',
          lineupIndex: 0,
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
          speciesId: 'enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
      );

      expect(
        buildBattleDecisionPromptForOverlay(freeTurnSession.decisionRequest),
        equals('Que doit faire le joueur ?'),
      );

      final forcedReplacementSession = _session(
        player: _combatant(
          speciesId: 'fainted_player',
          lineupIndex: 0,
          currentHp: 0,
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
          speciesId: 'enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
      );

      expect(
        buildBattleDecisionPromptForOverlay(
          forcedReplacementSession.decisionRequest,
        ),
        equals('Le joueur doit remplacer son Pokémon K.O.'),
      );

      final continueSession = _session(
        player: _combatant(
          speciesId: 'locked_player',
          lineupIndex: 0,
          moves: <BattleMoveData>[
            const BattleMoveData(
              id: 'hyper_beam',
              name: 'Hyper Beam',
              power: 150,
              requiresRecharge: true,
            ),
          ],
          volatileState: const BattleVolatileState(
            mustRecharge: true,
          ),
        ),
        enemy: _combatant(
          speciesId: 'enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
      );

      expect(
        buildBattleDecisionPromptForOverlay(continueSession.decisionRequest),
        equals('Le joueur doit continuer un tour forcé'),
      );
    });
  });

  group('BattleOverlayComponent BE10A chronology', () {
    test('renders a voluntary switch before the later enemy attack', () {
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
      final lines =
          buildBattleTurnLinesForOverlay(afterTurn.state.currentTurn!);

      final switchIndex =
          lines.indexWhere((line) => line.contains('Joueur switch de'));
      final attackIndex =
          lines.indexWhere((line) => line.contains('Ennemi utilise Tackle'));

      expect(switchIndex, greaterThanOrEqualTo(0));
      expect(attackIndex, greaterThanOrEqualTo(0));
      expect(switchIndex, lessThan(attackIndex));
    });

    test('rejects bucket-only turn results because chronology would be false',
        () {
      const bucketOnlyTurn = BattleTurnResult(
        playerAction: BattleActionNone(),
        enemyAction: BattleActionNone(),
        executions: <BattleMoveExecution>[
          BattleMoveExecution(
            attackerSlot: BattleSlotRef.active(BattleSideId.enemy),
            move: BattleMove(id: 'tackle', name: 'Tackle', power: 40),
            targetKind: BattleMoveExecutionTargetKind.combatant,
            targetSlot: BattleSlotRef.active(BattleSideId.player),
            damage: 12,
            didHit: true,
          ),
        ],
      );

      expect(
        () => buildBattleTurnLinesForOverlay(bucketOnlyTurn),
        throwsA(isA<StateError>()),
      );
    });

    test(
        'renders end-of-turn residuals before forced replacement markers after a double KO',
        () {
      final session = _session(
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
        isTrainerBattle: true,
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));
      final lines =
          buildBattleTurnLinesForOverlay(afterTurn.state.currentTurn!);

      final residualIndex = lines.indexWhere(
        (line) => line.contains('dégâts résiduels (PSN)'),
      );
      final enemyReplacementIndex = lines.indexWhere(
        (line) => line.contains('Ennemi remplace lead_enemy par bench_enemy'),
      );
      final playerReplacementIndex = lines.indexWhere(
        (line) => line.contains('Joueur doit remplacer lead_player K.O.'),
      );

      expect(residualIndex, greaterThanOrEqualTo(0));
      expect(enemyReplacementIndex, greaterThan(residualIndex));
      expect(playerReplacementIndex, greaterThan(enemyReplacementIndex));
    });

    test('renders Stealth Rock set and switch-in damage from timeline events',
        () {
      const turn = BattleTurnResult(
        playerAction: BattleActionFight(
          BattleMove(
            id: 'stealth_rock',
            name: 'Stealth Rock',
            power: 0,
            target: BattleMoveTarget.opponentSide,
            setsStealthRock: true,
          ),
          moveIndex: 0,
        ),
        enemyAction: BattleActionNone(),
        executions: <BattleMoveExecution>[
          BattleMoveExecution(
            attackerSlot: BattleSlotRef.active(BattleSideId.player),
            move: BattleMove(
              id: 'stealth_rock',
              name: 'Stealth Rock',
              power: 0,
              target: BattleMoveTarget.opponentSide,
              setsStealthRock: true,
            ),
            targetKind: BattleMoveExecutionTargetKind.side,
            targetSideRef: BattleSideId.enemy,
            damage: 0,
            didHit: true,
          ),
        ],
        stealthRockEvents: <BattleStealthRockEvent>[
          BattleStealthRockEvent.set(
            side: BattleSideId.enemy,
            sourceMoveId: 'stealth_rock',
          ),
          BattleStealthRockEvent.damagedOnEntry(
            side: BattleSideId.enemy,
            targetSlot: BattleSlotRef.active(BattleSideId.enemy),
            damage: 10,
          ),
        ],
        timeline: <BattleTurnEvent>[
          BattleTurnExecutionEvent(
            BattleMoveExecution(
              attackerSlot: BattleSlotRef.active(BattleSideId.player),
              move: BattleMove(
                id: 'stealth_rock',
                name: 'Stealth Rock',
                power: 0,
                target: BattleMoveTarget.opponentSide,
                setsStealthRock: true,
              ),
              targetKind: BattleMoveExecutionTargetKind.side,
              targetSideRef: BattleSideId.enemy,
              damage: 0,
              didHit: true,
            ),
          ),
          BattleTurnStealthRockEvent(
            BattleStealthRockEvent.set(
              side: BattleSideId.enemy,
              sourceMoveId: 'stealth_rock',
            ),
          ),
          BattleTurnStealthRockEvent(
            BattleStealthRockEvent.damagedOnEntry(
              side: BattleSideId.enemy,
              targetSlot: BattleSlotRef.active(BattleSideId.enemy),
              damage: 10,
            ),
          ),
        ],
      );

      final lines = buildBattleTurnLinesForOverlay(turn);

      expect(
        lines,
        contains('Stealth Rock est posé du côté Ennemi'),
      );
      expect(
        lines,
        contains('Ennemi subit 10 dégâts de Stealth Rock à l’entrée'),
      );
    });
  });
}

```


### `/Users/karim/Project/pokemonProject/packages/map_runtime/test/runtime_battle_move_bridge_test.dart`

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

    test('supports a deterministic major status move in the BE7 subset', () {
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

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.power, equals(0));
      expect(
        battleMove.majorStatusEffect?.status,
        equals(BattleMajorStatusId.par),
      );
      expect(battleMove.majorStatusEffect?.chancePercent, isNull);
    });

    test(
        'supports a probabilistic major status effect once battle owns the RNG',
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

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.power, equals(90));
      expect(
        battleMove.majorStatusEffect?.status,
        equals(BattleMajorStatusId.par),
      );
      expect(battleMove.majorStatusEffect?.chancePercent, equals(10));
    });

    test(
        'supports the exact protect volatile subset instead of reopening all applyVolatileStatus',
        () {
      const move = PokemonMove(
        id: 'protect',
        name: 'Protect',
        names: <String, String>{'en': 'Protect'},
        generation: 1,
        source: 'test',
        type: 'normal',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.self,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
        pp: 10,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.applyVolatileStatus(
            targetScope: PokemonMoveEffectTargetScope.self,
            volatileStatusId: 'protect',
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.target, equals(BattleMoveTarget.self));
      expect(
        battleMove.selfVolatileStatus,
        equals(BattleVolatileStatusId.protect),
      );
    });

    test('supports a breakProtect damage move in the BE8 subset', () {
      const move = PokemonMove(
        id: 'feint',
        name: 'Feint',
        names: <String, String>{'en': 'Feint'},
        generation: 4,
        source: 'test',
        type: 'normal',
        category: PokemonMoveCategory.physical,
        target: PokemonMoveTarget.normal,
        basePower: 30,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        pp: 10,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.breakProtect(),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.breaksProtect, isTrue);
      expect(battleMove.target, equals(BattleMoveTarget.opponent));
    });

    test('supports a requireRecharge damage move in the BE8 subset', () {
      const move = PokemonMove(
        id: 'hyper_beam',
        name: 'Hyper Beam',
        names: <String, String>{'en': 'Hyper Beam'},
        generation: 1,
        source: 'test',
        type: 'normal',
        category: PokemonMoveCategory.special,
        target: PokemonMoveTarget.normal,
        basePower: 150,
        accuracy: PokemonMoveAccuracy.percent(value: 90),
        pp: 5,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.requireRecharge(),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.requiresRecharge, isTrue);
      expect(battleMove.power, equals(150));
    });

    test('supports a chargeThenStrike damage move in the BE8 subset', () {
      const move = PokemonMove(
        id: 'solar_beam',
        name: 'Solar Beam',
        names: <String, String>{'en': 'Solar Beam'},
        generation: 1,
        source: 'test',
        type: 'grass',
        category: PokemonMoveCategory.special,
        target: PokemonMoveTarget.normal,
        basePower: 120,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        pp: 10,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.chargeThenStrike(chargeStateId: 'solar_charge'),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(
        battleMove.chargeThenStrikeEffect?.chargeStateId,
        equals('solar_charge'),
      );
      expect(battleMove.target, equals(BattleMoveTarget.opponent));
    });

    test(
        'still rejects a noncanonical move that combines chargeThenStrike and requireRecharge',
        () {
      const move = PokemonMove(
        id: 'bad_combo_beam',
        name: 'Bad Combo Beam',
        names: <String, String>{'en': 'Bad Combo Beam'},
        generation: 9,
        source: 'test',
        type: 'normal',
        category: PokemonMoveCategory.special,
        target: PokemonMoveTarget.normal,
        basePower: 120,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        pp: 5,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.requireRecharge(),
          PokemonMoveEffect.chargeThenStrike(),
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
            contains(
              'bridgeLimit=unsupported_combined_charge_then_recharge',
            ),
          ),
        ),
      );
    });

    test(
        'still rejects unsupported major statuses even when applyStatus is now partially bridgeable',
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
            contains('bridgeLimit=unsupported_major_status:slp'),
          ),
        ),
      );
    });

    test(
        'still rejects unsupported applyVolatileStatus outside the protect subset',
        () {
      const move = PokemonMove(
        id: 'confuse_ray',
        name: 'Confuse Ray',
        names: <String, String>{'en': 'Confuse Ray'},
        generation: 1,
        source: 'test',
        type: 'ghost',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.normal,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        pp: 10,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.applyVolatileStatus(
            targetScope: PokemonMoveEffectTargetScope.target,
            volatileStatusId: 'confusion',
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
            contains(
              'bridgeLimit=unsupported_apply_volatile_status_scope:target',
            ),
          ),
        ),
      );
    });

    test('supports the exact Rain Dance weather subset in BE9', () {
      const move = PokemonMove(
        id: 'rain_dance',
        name: 'Rain Dance',
        names: <String, String>{'en': 'Rain Dance'},
        generation: 2,
        source: 'test',
        type: 'water',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.all,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
        pp: 5,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.setWeather(
            targetScope: PokemonMoveEffectTargetScope.field,
            weatherId: 'raindance',
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.target, equals(BattleMoveTarget.field));
      expect(battleMove.weatherEffect, equals(BattleWeatherId.rain));
      expect(battleMove.pseudoWeatherEffect, isNull);
    });

    test(
        'rejects a malformed self-target field move instead of widening the BE9 field contract',
        () {
      const move = PokemonMove(
        id: 'bad_self_rain',
        name: 'Bad Self Rain',
        names: <String, String>{'en': 'Bad Self Rain'},
        generation: 9,
        source: 'test',
        type: 'water',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.self,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
        pp: 5,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.setWeather(
            targetScope: PokemonMoveEffectTargetScope.field,
            weatherId: 'raindance',
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
            contains('bridgeLimit=unsupported_field_target:self'),
          ),
        ),
      );
    });

    test('supports the exact Sandstorm weather subset in BE9', () {
      const move = PokemonMove(
        id: 'sandstorm',
        name: 'Sandstorm',
        names: <String, String>{'en': 'Sandstorm'},
        generation: 2,
        source: 'test',
        type: 'rock',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.all,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
        pp: 10,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.setWeather(
            targetScope: PokemonMoveEffectTargetScope.field,
            weatherId: 'sandstorm',
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.target, equals(BattleMoveTarget.field));
      expect(battleMove.weatherEffect, equals(BattleWeatherId.sandstorm));
    });

    test(
        'supports the exact Trick Room pseudoWeather subset without reopening all structuredPartial moves',
        () {
      const move = PokemonMove(
        id: 'trick_room',
        name: 'Trick Room',
        names: <String, String>{'en': 'Trick Room'},
        generation: 4,
        source: 'test',
        type: 'psychic',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.all,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
        pp: 5,
        priority: -7,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.setPseudoWeather(
            targetScope: PokemonMoveEffectTargetScope.field,
            pseudoWeatherId: 'trickroom',
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredPartial,
        unsupportedReasons: <String>[
          'unsupported_mechanic:turn_order_inversion',
          'showdown_callback:condition.durationCallback',
          'showdown_callback:condition.onFieldEnd',
        ],
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.target, equals(BattleMoveTarget.field));
      expect(
        battleMove.pseudoWeatherEffect,
        equals(BattlePseudoWeatherId.trickRoom),
      );
      expect(battleMove.priority, equals(-7));
    });

    test('still rejects unsupported weather ids outside the BE9 subset', () {
      const move = PokemonMove(
        id: 'sunny_day',
        name: 'Sunny Day',
        names: <String, String>{'en': 'Sunny Day'},
        generation: 2,
        source: 'test',
        type: 'fire',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.all,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
        pp: 5,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.setWeather(
            targetScope: PokemonMoveEffectTargetScope.field,
            weatherId: 'sunnyday',
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
            contains('bridgeLimit=unsupported_weather:sunnyday'),
          ),
        ),
      );
    });

    test('still rejects unsupported pseudoWeather ids outside the BE9 subset',
        () {
      const move = PokemonMove(
        id: 'magic_room',
        name: 'Magic Room',
        names: <String, String>{'en': 'Magic Room'},
        generation: 5,
        source: 'test',
        type: 'psychic',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.all,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
        pp: 10,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.setPseudoWeather(
            targetScope: PokemonMoveEffectTargetScope.field,
            pseudoWeatherId: 'magicroom',
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
            contains('bridgeLimit=unsupported_pseudo_weather:magicroom'),
          ),
        ),
      );
    });

    test('still rejects setTerrain because BE9 does not open terrains', () {
      const move = PokemonMove(
        id: 'electric_terrain',
        name: 'Electric Terrain',
        names: <String, String>{'en': 'Electric Terrain'},
        generation: 6,
        source: 'test',
        type: 'electric',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.all,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
        pp: 10,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.setTerrain(
            targetScope: PokemonMoveEffectTargetScope.field,
            terrainId: 'electricterrain',
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
            anyOf(
              contains('bridgeLimit=unsupported_target:all'),
              contains('bridgeLimit=unsupported_effect_kind:set_terrain'),
            ),
          ),
        ),
      );
    });

    test('supports Stealth Rock as the first honest side-level hazard slice',
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
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.setSideCondition(
            targetScope: PokemonMoveEffectTargetScope.foeSide,
            conditionId: 'stealthrock',
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.target, equals(BattleMoveTarget.opponentSide));
      expect(battleMove.setsStealthRock, isTrue);
    });

    test('still rejects non-Stealth-Rock side conditions during H1', () {
      const move = PokemonMove(
        id: 'spikes',
        name: 'Spikes',
        names: <String, String>{'en': 'Spikes'},
        generation: 2,
        source: 'test',
        type: 'ground',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.foeSide,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
        pp: 20,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.setSideCondition(
            targetScope: PokemonMoveEffectTargetScope.foeSide,
            conditionId: 'spikes',
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
            anyOf(
              contains('bridgeLimit=unsupported_target:foeSide'),
              contains('bridgeLimit=unsupported_side_condition:spikes'),
            ),
          ),
        ),
      );
    });

    test('still rejects setSlotCondition because BE9 does not open slot state',
        () {
      const move = PokemonMove(
        id: 'healing_wish',
        name: 'Healing Wish',
        names: <String, String>{'en': 'Healing Wish'},
        generation: 4,
        source: 'test',
        type: 'psychic',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.self,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
        pp: 10,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.setSlotCondition(
            targetScope: PokemonMoveEffectTargetScope.slot,
            conditionId: 'healingwish',
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
            anyOf(
              contains('bridgeLimit=unsupported_target:self'),
              contains(
                  'bridgeLimit=unsupported_effect_kind:set_slot_condition'),
              contains('bridgeLimit=unsupported_target:slot'),
            ),
          ),
        ),
      );
    });
  });
}

```


### `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart`

```dart
import 'package:map_core/map_core.dart';

import '../models/pokemon_project_data_models.dart';

/// Version logique du seed embarqué des moves bootstrap.
///
/// On ne crée pas ici un nouveau schéma JSON ni un framework de seed générique.
/// La "version" utile pour ce lot est simplement :
/// - un entier local, facile à relire dans le code ;
/// - reporté aussi dans les notes du catalogue seedé ;
/// - assez simple pour tracer les évolutions sans rouvrir `PokemonDataMeta`.
const int embeddedPokemonMovesSeedVersion = 1;

/// Construit le catalogue `moves` embarqué pour le bootstrap projet.
///
/// Choix d'architecture volontaire :
/// - le seed est codé en Dart, pas en asset Flutter ;
/// - le bootstrap n'a donc ni dépendance `rootBundle`, ni dépendance réseau ;
/// - le seed passe par les vrais modèles canoniques `PokemonMove`, puis
///   sérialise `toJson()` ;
/// - la copie dans le projet reste un simple write JSON, sans génération live.
///
/// Pourquoi pas un asset JSON pour M4 :
/// - `map_editor` ne versionne pas déjà ce type de seed via `flutter/assets` ;
/// - le use case d'initialisation est aujourd'hui un seam applicatif simple,
///   testable sans plomberie Flutter ;
/// - ajouter une lecture d'asset ici ouvrirait une couche de packaging plus
///   large que nécessaire pour ce seul lot.
///
/// Pourquoi pas le catalogue Showdown complet :
/// - cela demanderait soit du tooling de génération versionné, soit un gros
///   artefact généré hors scope M4 ;
/// - M4 doit fixer le seam bootstrap, pas ouvrir un chantier "catalog dump".
///
/// Le seed reste donc volontairement :
/// - canonique ;
/// - offline ;
/// - substantiel ;
/// - mais encore curaté.
PokemonCatalogFile buildEmbeddedPokemonMovesBootstrapSeed() {
  return PokemonCatalogFile(
    schemaVersion: 1,
    kind: 'pokemon_catalog',
    catalog: 'moves',
    meta: const PokemonDataMeta(
      description: 'Move catalog for the local Pokemon project database.',
      sourcePriority: <String>['internal'],
      notes: <String>[
        'Embedded canonical move seed shipped with map_editor for offline bootstrap.',
        'Curated from Showdown-backed move data and versioned in the repository.',
        'bootstrap_seed_version:$embeddedPokemonMovesSeedVersion',
      ],
    ),
    entries: _embeddedPokemonMovesSeedEntries
        .map((move) => move.toJson())
        .toList(growable: false),
  );
}

/// Le seed n'essaie pas d'être tout Showdown.
///
/// On prend un sous-ensemble volontairement utile pour un projet frais :
/// - attaques simples courantes ;
/// - quelques statuts et boosts ;
/// - quelques moves plus "structurels" pour garder des entrées qui montrent
///   honnêtement les limites actuelles (`catalog_only` quand nécessaire).
final List<PokemonMove> _embeddedPokemonMovesSeedEntries = <PokemonMove>[
  ..._structuredSupportedSeedMoves,
  ..._catalogOnlySeedMoves,
];

/// Moves dont la structure utile est déjà correctement portée par le modèle.
///
/// Même si `map_battle` ne consomme pas encore tout cela, le modèle canonique
/// est capable de les décrire sans mensonge métier majeur.
final List<PokemonMove> _structuredSupportedSeedMoves = <PokemonMove>[
  _showdownSeedMove(
    id: 'absorb',
    showdownMoveId: 'absorb',
    name: 'Absorb',
    generation: 1,
    type: 'grass',
    category: PokemonMoveCategory.special,
    basePower: 20,
    accuracy: const PokemonMoveAccuracy.percent(value: 100),
    pp: 25,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.heal,
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.drain(numerator: 1, denominator: 2),
    ],
    shortDescription: 'User recovers 50% of the damage dealt.',
    description:
        'The user recovers 1/2 the HP lost by the target, rounded half up. '
        'If Big Root is held by the user, the HP recovered is 1.3x normal, '
        'rounded half down.',
    engineSupportLevel: PokemonMoveEngineSupportLevel.catalogOnly,
    unsupportedReasons: <String>[
      'unsupported_effect_kind:drain',
    ],
  ),
  _showdownSeedMove(
    id: 'double_slap',
    showdownMoveId: 'doubleslap',
    name: 'Double Slap',
    generation: 1,
    type: 'normal',
    category: PokemonMoveCategory.physical,
    basePower: 15,
    accuracy: const PokemonMoveAccuracy.percent(value: 85),
    pp: 10,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.contact,
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.multiHit(minHits: 2, maxHits: 5),
    ],
    shortDescription: 'Hits 2-5 times in one turn.',
    description:
        'Hits two to five times. Has a 35% chance to hit two or three times '
        'and a 15% chance to hit four or five times. If one of the hits '
        'breaks the target\'s substitute, it will take damage for the '
        'remaining hits. If the user has the Skill Link Ability, this move '
        'will always hit five times.',
    engineSupportLevel: PokemonMoveEngineSupportLevel.catalogOnly,
    unsupportedReasons: <String>[
      'unsupported_effect_kind:multi_hit',
    ],
  ),
  // Phase B ajoute ici un seul lift bootstrap borné :
  // - des moves très fréquents en début de jeu ;
  // - déjà absorbés honnêtement par le bridge et le moteur ;
  // - choisis pour améliorer la battleability d'un scaffold frais sans ouvrir
  //   de nouvelle mécanique ni reclassifier artificiellement un seam limite.
  _showdownSeedMove(
    id: 'ember',
    showdownMoveId: 'ember',
    name: 'Ember',
    generation: 1,
    type: 'fire',
    category: PokemonMoveCategory.special,
    basePower: 40,
    accuracy: const PokemonMoveAccuracy.percent(value: 100),
    pp: 25,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.applyStatus(chance: 10, statusId: 'brn'),
    ],
    shortDescription: '10% chance to burn the target.',
    description: 'Has a 10% chance to burn the target.',
  ),
  _showdownSeedMove(
    id: 'feint',
    showdownMoveId: 'feint',
    name: 'Feint',
    generation: 4,
    type: 'normal',
    category: PokemonMoveCategory.physical,
    basePower: 30,
    accuracy: const PokemonMoveAccuracy.percent(value: 100),
    pp: 10,
    priority: 2,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.failCopycat,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.noAssist,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.breakProtect(),
    ],
    shortDescription: 'Nullifies Detect, Protect, and Quick/Wide Guard.',
    description: 'If this move is successful, it breaks through the target\'s '
        'Baneful Bunker, Detect, King\'s Shield, Protect, or Spiky Shield for '
        'this turn, allowing other Pokemon to attack the target normally. '
        'If the target\'s side is protected by Crafty Shield, Mat Block, '
        'Quick Guard, or Wide Guard, that protection is also broken for this '
        'turn and other Pokemon may attack the target\'s side normally.',
  ),
  _showdownSeedMove(
    id: 'growl',
    showdownMoveId: 'growl',
    name: 'Growl',
    generation: 1,
    type: 'normal',
    category: PokemonMoveCategory.status,
    target: PokemonMoveTarget.allAdjacentFoes,
    accuracy: const PokemonMoveAccuracy.percent(value: 100),
    pp: 40,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.bypassSubstitute,
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
      PokemonMoveFlag.reflectable,
      PokemonMoveFlag.sound,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.modifyStats(
        stageChanges: <PokemonMoveStatStageChange>[
          PokemonMoveStatStageChange(
            stat: PokemonMoveStatId.attack,
            stages: -1,
          ),
        ],
      ),
    ],
    shortDescription: 'Lowers the foe(s) Attack by 1.',
    description: 'Lowers the target\'s Attack by 1 stage.',
  ),
  _showdownSeedMove(
    id: 'hyper_beam',
    showdownMoveId: 'hyperbeam',
    name: 'Hyper Beam',
    generation: 1,
    type: 'normal',
    category: PokemonMoveCategory.special,
    basePower: 150,
    accuracy: const PokemonMoveAccuracy.percent(value: 90),
    pp: 5,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
      PokemonMoveFlag.recharge,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.requireRecharge(),
    ],
    shortDescription: 'User cannot move next turn.',
    description:
        'If this move is successful, the user must recharge on the following '
        'turn and cannot select a move.',
  ),
  _showdownSeedMove(
    id: 'leer',
    showdownMoveId: 'leer',
    name: 'Leer',
    generation: 1,
    type: 'normal',
    category: PokemonMoveCategory.status,
    target: PokemonMoveTarget.allAdjacentFoes,
    accuracy: const PokemonMoveAccuracy.percent(value: 100),
    pp: 30,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
      PokemonMoveFlag.reflectable,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.modifyStats(
        stageChanges: <PokemonMoveStatStageChange>[
          PokemonMoveStatStageChange(
            stat: PokemonMoveStatId.defense,
            stages: -1,
          ),
        ],
      ),
    ],
    shortDescription: 'Lowers the foe(s) Defense by 1.',
    description: 'Lowers the target\'s Defense by 1 stage.',
  ),
  _showdownSeedMove(
    id: 'quick_attack',
    showdownMoveId: 'quickattack',
    name: 'Quick Attack',
    generation: 1,
    type: 'normal',
    category: PokemonMoveCategory.physical,
    basePower: 40,
    accuracy: const PokemonMoveAccuracy.percent(value: 100),
    pp: 30,
    priority: 1,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.contact,
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
    ],
    shortDescription: 'Usually goes first.',
    description:
        'Nearly always goes first. No additional effect in the local subset.',
  ),
  _showdownSeedMove(
    id: 'rain_dance',
    showdownMoveId: 'raindance',
    name: 'Rain Dance',
    generation: 2,
    type: 'water',
    category: PokemonMoveCategory.status,
    target: PokemonMoveTarget.all,
    accuracy: const PokemonMoveAccuracy.alwaysHits(),
    pp: 5,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.metronome,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.setWeather(weatherId: 'raindance'),
    ],
    shortDescription: 'For 5 turns, heavy rain powers Water moves.',
    description: 'For 5 turns, the weather becomes Rain Dance. The damage of '
        'Water-type attacks is multiplied by 1.5 and the damage of Fire-type '
        'attacks is multiplied by 0.5 during the effect. Lasts for 8 turns if '
        'the user is holding Damp Rock. Fails if the current weather is Rain '
        'Dance.',
  ),
  _showdownSeedMove(
    id: 'razor_leaf',
    showdownMoveId: 'razorleaf',
    name: 'Razor Leaf',
    generation: 1,
    type: 'grass',
    category: PokemonMoveCategory.physical,
    target: PokemonMoveTarget.allAdjacentFoes,
    basePower: 55,
    accuracy: const PokemonMoveAccuracy.percent(value: 95),
    pp: 25,
    critRatio: 2,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
      PokemonMoveFlag.slicing,
    ],
    shortDescription: 'High critical hit ratio. Hits adjacent foes.',
    description: 'Has a higher chance for a critical hit.',
  ),
  _showdownSeedMove(
    id: 'scratch',
    showdownMoveId: 'scratch',
    name: 'Scratch',
    generation: 1,
    type: 'normal',
    category: PokemonMoveCategory.physical,
    basePower: 40,
    accuracy: const PokemonMoveAccuracy.percent(value: 100),
    pp: 35,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.contact,
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
    ],
    shortDescription: 'No additional effect.',
    description: 'No additional effect.',
  ),
  _showdownSeedMove(
    id: 'swords_dance',
    showdownMoveId: 'swordsdance',
    name: 'Swords Dance',
    generation: 1,
    type: 'normal',
    category: PokemonMoveCategory.status,
    target: PokemonMoveTarget.self,
    accuracy: const PokemonMoveAccuracy.alwaysHits(),
    pp: 20,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.dance,
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.snatch,
    ],
    effects: const <PokemonMoveEffect>[
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
    shortDescription: 'Raises the user\'s Attack by 2.',
    description: 'Raises the user\'s Attack by 2 stages.',
  ),
  _showdownSeedMove(
    id: 'swift',
    showdownMoveId: 'swift',
    name: 'Swift',
    generation: 1,
    type: 'normal',
    category: PokemonMoveCategory.special,
    target: PokemonMoveTarget.allAdjacentFoes,
    basePower: 60,
    accuracy: const PokemonMoveAccuracy.alwaysHits(),
    pp: 20,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
    ],
    shortDescription: 'This move does not check accuracy. Hits foes.',
    description: 'This move does not check accuracy.',
  ),
  _showdownSeedMove(
    id: 'tackle',
    showdownMoveId: 'tackle',
    name: 'Tackle',
    generation: 1,
    type: 'normal',
    category: PokemonMoveCategory.physical,
    basePower: 40,
    accuracy: const PokemonMoveAccuracy.percent(value: 100),
    pp: 35,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.contact,
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
    ],
    shortDescription: 'No additional effect.',
    description: 'No additional effect.',
  ),
  _showdownSeedMove(
    id: 'tail_whip',
    showdownMoveId: 'tailwhip',
    name: 'Tail Whip',
    generation: 1,
    type: 'normal',
    category: PokemonMoveCategory.status,
    target: PokemonMoveTarget.allAdjacentFoes,
    accuracy: const PokemonMoveAccuracy.percent(value: 100),
    pp: 30,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
      PokemonMoveFlag.reflectable,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.modifyStats(
        stageChanges: <PokemonMoveStatStageChange>[
          PokemonMoveStatStageChange(
            stat: PokemonMoveStatId.defense,
            stages: -1,
          ),
        ],
      ),
    ],
    shortDescription: 'Lowers the foe(s) Defense by 1.',
    description: 'Lowers the target\'s Defense by 1 stage.',
  ),
  _showdownSeedMove(
    id: 'thunder_wave',
    showdownMoveId: 'thunderwave',
    name: 'Thunder Wave',
    generation: 1,
    type: 'electric',
    category: PokemonMoveCategory.status,
    accuracy: const PokemonMoveAccuracy.percent(value: 90),
    pp: 20,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
      PokemonMoveFlag.reflectable,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.applyStatus(statusId: 'par'),
    ],
    shortDescription: 'Paralyzes the target.',
    description:
        'Paralyzes the target. This move does not ignore type immunity.',
  ),
  _showdownSeedMove(
    id: 'thunderbolt',
    showdownMoveId: 'thunderbolt',
    name: 'Thunderbolt',
    generation: 1,
    type: 'electric',
    category: PokemonMoveCategory.special,
    basePower: 90,
    accuracy: const PokemonMoveAccuracy.percent(value: 100),
    pp: 15,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.applyStatus(chance: 10, statusId: 'par'),
    ],
    shortDescription: '10% chance to paralyze the target.',
    description: 'Has a 10% chance to paralyze the target.',
  ),
  _showdownSeedMove(
    id: 'u_turn',
    showdownMoveId: 'uturn',
    name: 'U-turn',
    generation: 4,
    type: 'bug',
    category: PokemonMoveCategory.physical,
    basePower: 70,
    accuracy: const PokemonMoveAccuracy.percent(value: 100),
    pp: 20,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.contact,
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.selfSwitch(),
    ],
    shortDescription: 'User switches out after damaging the target.',
    description:
        'If this move is successful and the user has not fainted, the user '
        'switches out even if it is trapped and is replaced immediately by a '
        'selected party member. The user does not switch out if there are no '
        'unfainted party members, or if the target switched out using an '
        'Eject Button or through the effect of the Emergency Exit or Wimp Out '
        'Abilities.',
    engineSupportLevel: PokemonMoveEngineSupportLevel.catalogOnly,
    unsupportedReasons: <String>[
      'unsupported_effect_kind:self_switch',
    ],
  ),
  _showdownSeedMove(
    id: 'vine_whip',
    showdownMoveId: 'vinewhip',
    name: 'Vine Whip',
    generation: 1,
    type: 'grass',
    category: PokemonMoveCategory.physical,
    basePower: 45,
    accuracy: const PokemonMoveAccuracy.percent(value: 100),
    pp: 25,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.contact,
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
    ],
    shortDescription: 'No additional effect.',
    description: 'No additional effect.',
  ),
  _showdownSeedMove(
    id: 'water_gun',
    showdownMoveId: 'watergun',
    name: 'Water Gun',
    generation: 1,
    type: 'water',
    category: PokemonMoveCategory.special,
    basePower: 40,
    accuracy: const PokemonMoveAccuracy.percent(value: 100),
    pp: 25,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
    ],
    shortDescription: 'No additional effect.',
    description: 'No additional effect.',
  ),
  _showdownSeedMove(
    id: 'whirlwind',
    showdownMoveId: 'whirlwind',
    name: 'Whirlwind',
    generation: 1,
    type: 'normal',
    category: PokemonMoveCategory.status,
    accuracy: const PokemonMoveAccuracy.alwaysHits(),
    pp: 20,
    priority: -6,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.allyAnim,
      PokemonMoveFlag.bypassSubstitute,
      PokemonMoveFlag.failCopycat,
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.noAssist,
      PokemonMoveFlag.reflectable,
      PokemonMoveFlag.wind,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.forceSwitch(),
    ],
    shortDescription: 'Forces the target to switch to a random ally.',
    description:
        'The target is forced to switch out and be replaced with a random '
        'unfainted ally. Fails if the target is the last unfainted Pokemon in '
        'its party, or if the target used Ingrain previously or has the '
        'Suction Cups Ability.',
    engineSupportLevel: PokemonMoveEngineSupportLevel.catalogOnly,
    unsupportedReasons: <String>[
      'unsupported_effect_kind:force_switch',
    ],
  ),
];

/// Moves volontairement gardés dans le seed malgré un support encore limité.
///
/// On les garde parce qu'ils rendent le seed plus utile qu'une simple liste
/// d'attaques triviales, tout en exposant honnêtement les limites structurelles
/// actuelles via `catalog_only` et `unsupportedReasons`.
final List<PokemonMove> _catalogOnlySeedMoves = <PokemonMove>[
  // H1 supporte désormais Stealth Rock de bout en bout.
  //
  // On laisse volontairement l'entrée à sa place pour éviter un grand remaniement
  // du seed, mais son niveau de support ne doit plus mentir.
  _showdownSeedMove(
    id: 'stealth_rock',
    showdownMoveId: 'stealthrock',
    name: 'Stealth Rock',
    generation: 4,
    type: 'rock',
    category: PokemonMoveCategory.status,
    target: PokemonMoveTarget.foeSide,
    accuracy: const PokemonMoveAccuracy.alwaysHits(),
    pp: 20,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mustPressure,
      PokemonMoveFlag.reflectable,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.setSideCondition(conditionId: 'stealthrock'),
    ],
    shortDescription: 'Hurts foes on switch-in. Factors Rock weakness.',
    description:
        'Sets up a hazard on the opposing side of the field, damaging each '
        'opposing Pokemon that switches in. Fails if the effect is already '
        'active on the opposing side. Foes lose 1/32, 1/16, 1/8, 1/4, or 1/2 '
        'of their maximum HP, rounded down, based on their weakness to the '
        'Rock type; 0.25x, 0.5x, neutral, 2x, or 4x, respectively. Can be '
        'removed from the opposing side if any Pokemon uses Tidy Up, or if '
        'any opposing Pokemon uses Mortal Spin, Rapid Spin, or Defog '
        'successfully, or is hit by Defog.',
    showdownHooksPresent: <String>[
      'condition.onSideStart',
      'condition.onSwitchIn',
    ],
  ),
  _showdownSeedMove(
    id: 'electric_terrain',
    showdownMoveId: 'electricterrain',
    name: 'Electric Terrain',
    generation: 6,
    type: 'electric',
    category: PokemonMoveCategory.status,
    target: PokemonMoveTarget.all,
    accuracy: const PokemonMoveAccuracy.alwaysHits(),
    pp: 10,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.nonSky,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.setTerrain(terrainId: 'electricterrain'),
    ],
    shortDescription: '5 turns. Grounded: +Electric power, can\'t sleep.',
    description:
        'For 5 turns, the terrain becomes Electric Terrain. During the '
        'effect, the power of Electric-type attacks made by grounded Pokemon '
        'is multiplied by 1.3 and grounded Pokemon cannot fall asleep; Pokemon '
        'already asleep do not wake up. Grounded Pokemon cannot become '
        'affected by Yawn or fall asleep from its effect. Camouflage '
        'transforms the user into an Electric type, Nature Power becomes '
        'Thunderbolt, and Secret Power has a 30% chance to cause paralysis. '
        'Fails if the current terrain is Electric Terrain.',
    engineSupportLevel: PokemonMoveEngineSupportLevel.catalogOnly,
    unsupportedReasons: <String>[
      'showdown_callback:condition.durationCallback',
      'showdown_callback:condition.onBasePower',
      'showdown_callback:condition.onFieldEnd',
      'showdown_callback:condition.onFieldStart',
      'showdown_callback:condition.onSetStatus',
      'showdown_callback:condition.onTryAddVolatile',
      'unsupported_mechanic:condition',
    ],
    showdownHooksPresent: <String>[
      'condition.durationCallback',
      'condition.onBasePower',
      'condition.onFieldEnd',
      'condition.onFieldStart',
      'condition.onSetStatus',
      'condition.onTryAddVolatile',
    ],
  ),
  _showdownSeedMove(
    id: 'healing_wish',
    showdownMoveId: 'healingwish',
    name: 'Healing Wish',
    generation: 4,
    type: 'psychic',
    category: PokemonMoveCategory.status,
    target: PokemonMoveTarget.self,
    accuracy: const PokemonMoveAccuracy.alwaysHits(),
    pp: 10,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.heal,
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.snatch,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.setSlotCondition(conditionId: 'healingwish'),
    ],
    shortDescription: 'User faints. Next hurt Pokemon is fully healed.',
    description:
        'The user faints, and if the Pokemon brought out to replace it does '
        'not have full HP or has a non-volatile status condition, its HP is '
        'fully restored along with having any non-volatile status condition '
        'cured. The replacement is sent out at the end of the turn, and the '
        'healing happens before hazards take effect. This effect continues '
        'until a Pokemon that meets either of these conditions switches in at '
        'the user\'s position or gets swapped into the position with Ally '
        'Switch. Fails if the user is the last unfainted Pokemon in its party.',
    engineSupportLevel: PokemonMoveEngineSupportLevel.catalogOnly,
    unsupportedReasons: <String>[
      'showdown_callback:condition.onSwap',
      'showdown_callback:condition.onSwitchIn',
      'showdown_callback:onTryHit',
      'unsupported_mechanic:condition',
      'unsupported_mechanic:selfdestruct',
    ],
    showdownHooksPresent: <String>[
      'condition.onSwap',
      'condition.onSwitchIn',
      'onTryHit',
    ],
  ),
  _showdownSeedMove(
    id: 'solar_beam',
    showdownMoveId: 'solarbeam',
    name: 'Solar Beam',
    generation: 1,
    type: 'grass',
    category: PokemonMoveCategory.special,
    basePower: 120,
    accuracy: const PokemonMoveAccuracy.percent(value: 100),
    pp: 10,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.charge,
      PokemonMoveFlag.failInstruct,
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.noSleepTalk,
      PokemonMoveFlag.protect,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.chargeThenStrike(chargeStateId: 'solar_charge'),
    ],
    shortDescription: 'Charges turn 1. Hits turn 2. No charge in sunlight.',
    description:
        'This attack charges on the first turn and executes on the second. '
        'Power is halved if the weather is Primordial Sea, Rain Dance, '
        'Sandstorm, or Snow and the user is not holding Utility Umbrella. If '
        'the user is holding a Power Herb or the weather is Desolate Land or '
        'Sunny Day, the move completes in one turn. If the user is holding '
        'Utility Umbrella and the weather is Desolate Land or Sunny Day, the '
        'move still requires a turn to charge.',
    engineSupportLevel: PokemonMoveEngineSupportLevel.catalogOnly,
    unsupportedReasons: <String>[
      'showdown_callback:onBasePower',
      'showdown_callback:onTryMove',
      'unsupported_mechanic:weather_charge_shortcuts',
    ],
    showdownHooksPresent: <String>[
      'onBasePower',
      'onTryMove',
    ],
  ),
  _showdownSeedMove(
    id: 'trick_room',
    showdownMoveId: 'trickroom',
    name: 'Trick Room',
    generation: 4,
    type: 'psychic',
    category: PokemonMoveCategory.status,
    target: PokemonMoveTarget.all,
    accuracy: const PokemonMoveAccuracy.alwaysHits(),
    pp: 5,
    priority: -7,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.setPseudoWeather(pseudoWeatherId: 'trickroom'),
    ],
    shortDescription: 'Goes last. For 5 turns, turn order is reversed.',
    description:
        'For 5 turns, the Speed of every Pokemon is recalculated for the '
        'purposes of determining turn order. During the effect, each '
        'Pokemon\'s Speed is considered to be (10000 - its normal Speed), and '
        'if this value is greater than 8191, 8192 is subtracted from it. If '
        'this move is used during the effect, the effect ends.',
    engineSupportLevel: PokemonMoveEngineSupportLevel.structuredPartial,
    unsupportedReasons: <String>[
      'unsupported_mechanic:turn_order_inversion',
      'showdown_callback:condition.durationCallback',
      'showdown_callback:condition.onFieldEnd',
      'showdown_callback:condition.onFieldRestart',
      'showdown_callback:condition.onFieldStart',
      'unsupported_mechanic:condition',
    ],
    showdownHooksPresent: <String>[
      'condition.durationCallback',
      'condition.onFieldEnd',
      'condition.onFieldRestart',
      'condition.onFieldStart',
    ],
  ),
];

/// Helper unique pour garder le seed compact sans créer de framework.
///
/// `source` vaut volontairement `showdown` :
/// - il décrit l'origine du contenu métier ;
/// - pas le mode de chargement ;
/// - le bootstrap reste local/offline car ce seed est déjà versionné ici.
PokemonMove _showdownSeedMove({
  required String id,
  required String showdownMoveId,
  required String name,
  required int generation,
  required String type,
  required PokemonMoveCategory category,
  PokemonMoveTarget target = PokemonMoveTarget.normal,
  int basePower = 0,
  required PokemonMoveAccuracy accuracy,
  int pp = 0,
  bool noPpBoosts = false,
  int priority = 0,
  int critRatio = 1,
  List<PokemonMoveFlag> flags = const <PokemonMoveFlag>[],
  List<PokemonMoveEffect> effects = const <PokemonMoveEffect>[],
  String shortDescription = '',
  String description = '',
  PokemonMoveEngineSupportLevel engineSupportLevel =
      PokemonMoveEngineSupportLevel.structuredSupported,
  List<String> unsupportedReasons = const <String>[],
  List<String> showdownHooksPresent = const <String>[],
}) {
  return PokemonMove(
    id: id,
    name: name,
    names: <String, String>{'en': name},
    generation: generation,
    source: 'showdown',
    type: type,
    category: category,
    target: target,
    basePower: basePower,
    accuracy: accuracy,
    pp: pp,
    noPpBoosts: noPpBoosts,
    priority: priority,
    critRatio: critRatio,
    flags: flags,
    effects: effects,
    shortDescription: shortDescription,
    description: description,
    engineSupportLevel: engineSupportLevel,
    unsupportedReasons: unsupportedReasons,
    sourceRefs: PokemonMoveSourceRefs(
      showdownMoveId: showdownMoveId,
      showdownHooksPresent: showdownHooksPresent,
    ),
  ).normalized();
}

```
