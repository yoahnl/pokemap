# Lot 113 — Surface Movement Effects Model Decision V0

## 1. Résumé exécutif honnête

Lot 113 est un lot documentaire et décisionnel. Aucun code de production, test, modèle, JSON, runtime Flutter ou UI editor n'a été modifié par ce lot.

Décision principale :

```text
Recommander un contrat `GameplayMovementEffect` côté `map_gameplay`,
exposé en V0 par `Moved.movementEffect`.
```

Décision complémentaire :

```text
V0 doit porter un seul effet de mouvement optionnel, résolu par priorité,
comme `Moved.hazardEffect`.
```

Pour l'authoring futur, ne pas surcharger `MovementZonePayload` et ne pas cacher ice/mud dans `SpecialZonePayload(scriptKey)`. La direction propre est un contrat explicite de movement effects, puis un payload persistant explicite si l'éditeur doit générer ces zones.

Prochain lot recommandé :

```text
Lot 114 — Surface Movement Effect Runtime Prep V0
```

But du Lot 114 : créer le contrat runtime minimal côté `map_gameplay` sans coder ice editor, mud editor, glissade complète ni ralentissement visuel.

## 2. Périmètre

Inclus :

- audit Lot 112 ;
- audit `stepGameplayWorld` / `GameplayStepResult` ;
- audit `GameplayWorldState` / player movement ;
- audit payloads `map_core` ;
- audit boucle de mouvement `PlayableMapGame` ;
- audit existant ice/mud/swamp ;
- comparaison des options de contrat movement effect ;
- décision effet unique vs liste ;
- taxonomie future proposée ;
- décision sur le pilotage de la glissade ;
- décision ice first vs mud first ;
- relance des tests de clôture.

Exclus :

- aucun `GameplayMovementEffect` codé ;
- aucune modification `Moved` ;
- aucune modification `GameplayStepResult` ;
- aucune modification `stepGameplayWorld` ;
- aucune modification `GameplayWorldState` ;
- aucune modification `PlayableMapGame` ;
- aucune glissade ;
- aucun ralentissement ;
- aucun movement cost ;
- aucune action editor ice/mud ;
- aucun changement de modèle persistant.

## 3. Gate 0 — status initial

Commandes exécutées depuis `/Users/karim/Project/pokemonProject` avant toute modification :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git log --oneline -n 12
find . -name AGENTS.md -print
```

Sortie :

```text
/Users/karim/Project/pokemonProject
main
 M examples/playable_runtime_host/lib/src/runtime_demo_party_seed.dart
 M examples/playable_runtime_host/test/runtime_demo_party_seed_test.dart
 M packages/map_runtime/lib/map_runtime.dart
 .../lib/src/runtime_demo_party_seed.dart           | 111 +++++++++++-
 .../test/runtime_demo_party_seed_test.dart         | 195 +++++++++++++++++++++
 packages/map_runtime/lib/map_runtime.dart          |   4 +
 3 files changed, 305 insertions(+), 5 deletions(-)
09a9b0df lot 112: Ice Mud Movement Semantics Decision
f57ade04 Merge PSDK battle parity work
993b0033 Complete PSDK battle parity batch
a294999b lot 110: Lava Hazard Runtime E2E Closure
af24a783 lot 109: Editor Generate Lava Hazard Zone from Surface
3ef5fc92 lot 108: Hazard Runtime Consumption Prep
e8bfc68e lot 107: Lava Hazard from Surface Workflow Decision
4851b53f lot 106: Surface Behavior Action Menu
2305f276 lot 104: Surface Gameplay Bridge Runtime E2E Closure
d9a1a3e3 Port PSDK battle parity moves
8b5c3728 lot 103: Editor Generate Surfable Water Gameplay Zone from Surface
6a3db8e3 lot 101: Tall Grass Surface Workflow Hardening - Batch Apply
./AGENTS.md
```

Changements préexistants au Lot 113 :

```text
examples/playable_runtime_host/lib/src/runtime_demo_party_seed.dart
examples/playable_runtime_host/test/runtime_demo_party_seed_test.dart
packages/map_runtime/lib/map_runtime.dart
```

Ces fichiers étaient déjà modifiés avant le Lot 113. Ils ne sont pas touchés par ce lot.

Changements du Lot 113 :

```text
reports/surface/surface_engine_lot_113_surface_movement_effects_model_decision.md
```

## 4. Context Mode usage

Context Mode a été utilisé agressivement pour les audits et sorties de tests.

Synthèse compacte :

```text
Audit principal : 10 commandes, 9581 lignes, 1099.4KB indexés.
Audit PlayableMapGame ciblé : 4 commandes, 269 lignes, 10.4KB indexés.
Régression Surface Painter : 5 sections indexées, 15.1KB.
Smoke runtime Surface : 2 sections indexées, 6.5KB.
Total minimal explicitement rapporté par Context Mode : 1131.4KB indexés.
```

La commande `ctx stats` n'est pas exposée comme binaire shell dans cet environnement. Sa sortie exacte est incluse section 29.

## 5. Audit Lot 112

Commande obligatoire exécutée :

```bash
rg -n "Lot 112|Ice|Mud|Movement Effects|movement effect|MovementZonePayload|SpecialZonePayload|HazardKind.swamp|glissade|ralentissement|movement cost|forced movement" reports/surface
```

Lecture prioritaire :

```text
reports/surface/surface_engine_lot_112_ice_mud_movement_semantics_decision.md
```

Findings :

- Lot 112 refuse de coder ice directement parce que la glissade demande direction forcée, chain movement, arrêt sur obstacle et interactions avec warp/connection/collision.
- Lot 112 refuse de coder mud directement parce que le ralentissement demande coût de déplacement, cadence ou friction.
- `MovementZonePayload` est insuffisant : il ne porte que `requiredMode` et `allowedModes`.
- `SpecialZonePayload` est trop faible comme voie no-code : `scriptKey` cacherait une mécanique moteur dans une string.
- `HazardKind.swamp` existe, mais ne doit pas représenter une boue slow pure. Le contrat hazard actuel expose un danger/effet, surtout via `damagePerStep`.
- Lot 112 recommande un contrat commun de movement effects avant ice/mud.

## 6. Audit stepGameplayWorld / GameplayStepResult

Commande obligatoire exécutée :

```bash
rg -n "GameplayStepResult|Moved|Blocked|WarpTriggered|ConnectionTriggered|PlacedElementInteracted|MapEventInteracted|NothingToInteract|hazardEffect|pathAnimationSignals|stepGameplayWorld|_resolveMove|MoveIntent|InteractIntent|pixelsPerStep|Direction" packages/map_gameplay/lib packages/map_gameplay/test
```

Lectures prioritaires :

```text
packages/map_gameplay/lib/src/gameplay_step.dart
packages/map_gameplay/lib/src/gameplay_step_result.dart
packages/map_gameplay/lib/src/gameplay_hazard.dart
packages/map_gameplay/test/hazard_runtime_consumption_test.dart
packages/map_gameplay/test/surface_generated_gameplay_zone_bridge_test.dart
```

Résultats de step existants :

- `Moved`
- `Blocked`
- `WarpTriggered`
- `ConnectionTriggered`
- `NpcInteracted`
- `PlacedElementInteracted`
- `MapEventInteracted`
- `NothingToInteract`

Findings :

- `stepGameplayWorld` dispatch `MoveIntent` vers `_resolveMove`.
- `_resolveMove` commence par mettre à jour la direction du joueur.
- `waterRequiresSurf` bloque avant collision pixel.
- Les collisions solides retournent `Blocked`.
- Les connections et warps peuvent interrompre le flow avant un `Moved`.
- Les interactions placed element peuvent produire `PlacedElementInteracted`.
- `Moved` porte déjà `hazardEffect`.
- `hazardEffect` est résolu après un mouvement réussi vers la position finale.
- Ce pattern marche pour lava parce que lava est un effet post-mouvement.

Ce que cela implique pour movement effects :

- un movement effect ne doit pas être déclenché sur `Blocked` ;
- il ne doit pas être déclenché sur `ConnectionTriggered` ;
- il ne doit pas être déclenché si un warp remplace le déplacement normal ;
- il ne doit pas être déclenché sur `InteractIntent` ;
- il doit être détecté après un mouvement réussi, à partir de la position finale.

Questions tranchées :

- Un movement effect doit-il être attaché à `Moved` ? Oui en V0.
- Faut-il un nouveau résultat de step ? Non en V0.
- Faut-il un helper pur séparé ? Non comme contrat principal, seulement comme helper interne possible.
- Faut-il un intent spécial pour mouvement forcé ? Oui plus tard côté orchestration runtime, mais pas pour détecter l'effet initial.

## 7. Audit GameplayWorldState / player movement

Commande obligatoire exécutée :

```bash
rg -n "GameplayWorldState|GameplayPlayerState|movementMode|playerMovementMode|withPlayer|playerPositionPx|pos|facing|isWaterCell|waterCell|tileWidthPx|tileHeightPx|worldStaticObstaclesCollidePixelRect|pixel|collision" packages/map_gameplay/lib packages/map_gameplay/test packages/map_runtime/lib packages/map_runtime/test
```

Lectures prioritaires :

```text
packages/map_gameplay/lib/src/gameplay_world_state.dart
packages/map_gameplay/lib/src/gameplay_player_state.dart
packages/map_gameplay/lib/src/collision/pixel_movement_resolver.dart
packages/map_gameplay/test/movement_mode_water_test.dart
```

Findings :

- La position joueur vit dans `GameplayPlayerState`.
- `GameplayPlayerState` porte `pos`, `facing`, `movementMode`, `playerPositionPx`.
- `GameplayWorldState.initial` reconstruit l'état joueur depuis une cellule grille et les dimensions de tiles.
- `withPlayer` permet de remplacer l'état joueur.
- `movementMode` représente le mode courant du joueur, par exemple `walk` ou `surf`.
- `isWaterCell` dérive le blocage water depuis les zones movement/surf et caches.
- Le moteur a des collisions cell/pixel et un resolver séparé H/V.
- Aucun état transitoire de glissade n'existe dans `GameplayPlayerState`.
- Aucun coût de déplacement ou vitesse Surface n'existe dans `GameplayWorldState`.

Conclusion :

```text
Le world state sait porter position/facing/mode, mais pas une intention de glissade active ni une cadence mud.
```

## 8. Audit map_core gameplay zone payloads

Commande obligatoire exécutée :

```bash
rg -n "GameplayZoneKind|MovementZonePayload|MovementMode|HazardZonePayload|HazardKind|SpecialZonePayload|custom|priority|MapGameplayZone|movementCost|speed|slow|slide|forced|friction" packages/map_core/lib packages/map_core/test
```

Lectures prioritaires :

```text
packages/map_core/lib/src/models/map_gameplay_zone_payloads.dart
packages/map_core/lib/src/operations/map_gameplay_zones.dart
```

Findings :

- `GameplayZoneKind` contient `encounter`, `movement`, `hazard`, `special`, `custom`.
- `MovementZonePayload` contient `requiredMode` et `allowedModes`.
- `MovementMode` contient `walk`, `surf`, `fly`, `cut`, `strength`, `rockSmash`.
- `HazardZonePayload` contient `hazardKind` et `damagePerStep`.
- `HazardKind` contient `lava`, `poison`, `swamp`, `pitfall`, `other`.
- `SpecialZonePayload` contient `scriptKey` et `properties`.
- `MapGameplayZone` porte `priority`, déjà utilisé pour résoudre les zones.
- Aucun payload persistant dédié movement effect n'existe.

Décision modèle future :

```text
`GameplayZoneKind.movement` doit rester un gate/mode pour V0 existant.
Un futur payload persistant movement effect doit être explicite plutôt que greffé sur `MovementZonePayload`.
```

Option long terme recommandée :

```text
GameplayZoneKind.movementEffect
MovementEffectZonePayload(...)
```

Mais ce changement de modèle n'est pas codé en Lot 113.

## 9. Audit PlayableMapGame movement loop

Commande obligatoire exécutée :

```bash
rg -n "PlayableMapGame|stepGameplayWorld|MoveIntent|pixelsPerStep|movementMode|setPlayerMovementMode|hazardEffect|Moved|Blocked|update\\(|onLoad|keyboard|gamepad|input|player.*direction|pathAnimationSignals|timeline|feedback|dialogue" packages/map_runtime/lib packages/map_runtime/test
```

Lectures prioritaires :

```text
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
packages/map_runtime/test/surface
packages/map_runtime/test
```

Audit ciblé complémentaire :

```bash
nl -ba packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart | sed -n '1580,1745p'
nl -ba packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart | sed -n '3140,3185p'
nl -ba packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart | sed -n '3240,3275p'
rg -n "hazardEffect|GameplayHazardEffect|damagePerStep|Moved" packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart packages/map_runtime/lib packages/map_runtime/test | head -n 120
```

Findings :

- `PlayableMapGame` transforme les inputs en `MoveIntent`.
- `_fullTileMoveIntent` construit un `MoveIntent` avec `pixelsPerStep` correspondant à la taille d'une tile.
- `_driveMovement` appelle `stepGameplayWorld`.
- Après le step, `PlayableMapGame` consomme `pathAnimationSignals`.
- `Blocked(waterRequiresSurf)` déclenche un flow water blocked.
- `Moved` déclenche `PlayerComponent.startStep`, encounters, line of sight et triggers.
- `PlayableMapGame` ne lit pas encore `hazardEffect`.
- Il existe déjà des mouvements scriptés qui appellent `stepGameplayWorld` avec un intent full-tile, mais ce n'est pas une glissade Surface générique.

Question centrale :

```text
Qui doit piloter une glissade ?
```

Décision :

```text
map_gameplay détecte et expose l'effet.
map_runtime orchestre ensuite les pas forcés et l'animation.
Chaque pas forcé repasse par stepGameplayWorld.
```

Pourquoi :

- `map_gameplay` reste source de vérité sémantique ;
- `map_runtime` garde l'orchestration visuelle/input ;
- la glissade ne doit pas court-circuiter collisions, warps, connections ou triggers.

## 10. Audit ice / mud / swamp existant

Commande obligatoire exécutée :

```bash
rg -n "PathSurfaceKind.ice|PathSurfaceKind.swamp|HazardKind.swamp|ice|Ice|mud|Mud|swamp|Swamp|slide|sliding|glide|movementCost|slow|friction|surfacePresetId.*ice|surfacePresetId.*mud|surfacePresetId.*swamp" packages/map_core/lib packages/map_core/test packages/map_editor/lib packages/map_editor/test packages/map_gameplay/lib packages/map_gameplay/test packages/map_runtime/lib packages/map_runtime/test reports/surface
```

Findings :

- `PathSurfaceKind.ice` existe.
- `PathSurfaceKind.swamp` existe.
- `HazardKind.swamp` existe.
- Les tests `standard_ice_path_preset_vertical_atlas_builder_test.dart` couvrent un preset visuel ice.
- Les tests Surface manipulent `surfacePresetId: 'ice'` et `surfacePresetId: 'mud'` comme placements visuels.
- Le runtime Surface a des tests visuels avec `mud`.
- Les occurrences battle `ice` / `mud` concernent les moves et animations de combat, pas le mouvement overworld.
- Aucun test ne prouve une glissade overworld.
- Aucun test ne prouve un ralentissement mud overworld.
- Aucun contrat swamp runtime n'applique ralentissement ou enlisement.

Conclusion :

```text
ice/mud/swamp existent comme traces visuelles, legacy ou hazard enum,
mais pas comme movement effects gameplay.
```

## 11. Options de contrat comparées

| Option | Description | Avantages | Inconvénients | Verdict |
|---|---|---|---|---|
| A | Ajouter `movementEffect` optionnel à `Moved` | Cohérent avec `hazardEffect`; testable; post-mouvement réussi; pas de mutation cachée | `Moved` gagne un champ; ne résout pas toute la glissade | Recommandée V0 |
| B | Nouveau résultat `MovementEffectTriggered` | Très explicite | Complexifie tous les consumers; un mouvement avec effet reste un mouvement réussi | Rejetée V0 |
| C | Helper pur `resolveMovementEffectAtPosition` | Peu intrusif; testable | `stepGameplayWorld` ne consomme pas réellement l'effet; risque de résolution parallèle runtime | Rejetée comme contrat principal |
| D | `SpecialZonePayload(scriptKey)` | Aucun modèle nouveau | String-based; mauvais no-code; validation faible | Rejetée |
| E | Modifier `MovementZonePayload` | Réutilise kind movement | Mélange gate et effet; payload fourre-tout | Rejetée |
| F | Nouveau kind/payload persistant | Modèle explicite; sépare gates/hazards/effects | Change `map_core`; JSON/migration future | Recommandée plus tard pour authoring |

Décision combinée :

```text
V0 runtime : Option A.
Futur authoring persistant : Option F, pas E/D.
```

## 12. Décision contrat V0

Contrat recommandé :

```text
GameplayMovementEffect côté map_gameplay.
Moved.movementEffect côté GameplayStepResult.
Résolution après mouvement réussi, sur position finale.
```

Le contrat ne doit pas :

- appliquer directement plusieurs pas ;
- muter un état de glissade durable dans `GameplayWorldState` en V0 ;
- modifier HP / party / `GameState` ;
- être résolu côté runtime en parallèle de `stepGameplayWorld` ;
- utiliser `SpecialZonePayload(scriptKey)` comme source no-code principale.

Le futur Lot 114 devra tester :

- mouvement normal sans effect ;
- entrée sur zone slide produit effect ;
- entrée sur zone movement cost produit effect ;
- mouvement bloqué ne produit pas effect ;
- waterRequiresSurf bloque avant effect ;
- hazardEffect et movementEffect peuvent coexister sur un `Moved` ;
- priorité des zones movement effect.

## 13. Effet unique vs liste d'effets

Options :

```text
movementEffect: GameplayMovementEffect?
movementEffects: List<GameplayMovementEffect>
```

Décision V0 :

```text
movementEffect: GameplayMovementEffect?
```

Raison :

- cohérent avec `hazardEffect` ;
- plus simple à tester ;
- priorité de zone existe déjà ;
- évite de définir trop tôt la composition slide + slow + autre ;
- les effets multiples réels ne sont pas encore prouvés.

Règle de résolution recommandée :

```text
Prendre la zone movement effect couvrant la position finale avec la priorité la plus élevée.
En cas d'égalité, suivre l'ordre/résolution existant des zones sans inventer une nouvelle règle.
```

Interaction avec `hazardEffect` :

```text
hazardEffect reste séparé.
Un même Moved peut porter hazardEffect et movementEffect.
```

## 14. Taxonomie movement effects proposée

Taxonomie future recommandée, non codée :

```text
GameplayMovementEffect
- kind
- zoneId
- zoneName
- position
- priority
```

Kinds proposés :

```text
slide
movementCost
```

Slide-specific :

```text
direction
continuePolicy
stopPolicy
```

Valeurs conceptuelles :

```text
continuePolicy: oneStep | untilBlocked
stopPolicy: beforeObstacle | onObstacleBump | beforeWarp
```

MovementCost-specific :

```text
costMultiplier
extraStepCost
```

Notes :

- `direction` pour slide doit probablement reprendre la direction du mouvement entrant.
- `movementCost` doit rester abstrait côté gameplay ; le runtime traduira en durée/cadence.
- `swamp` peut devenir un movement cost ou un hazard selon décision produit future, mais pas automatiquement.

## 15. Qui pilote la glissade

Options :

| Option | Description | Verdict |
|---|---|---|
| A | `map_gameplay` renvoie un effect, `map_runtime` exécute les pas forcés | Recommandée |
| B | `map_gameplay` exécute toute la glissade en une boucle | Rejetée V0 |
| C | `map_runtime` détecte la zone et gère tout | Rejetée |

Décision :

```text
map_gameplay détecte l'effet.
map_runtime orchestre la suite.
Chaque pas forcé repasse par stepGameplayWorld.
```

Règles recommandées pour future glissade :

- déclencher seulement après `Moved` ;
- supprimer ou ignorer input joueur pendant la chaîne forcée ;
- arrêter sur `Blocked` ;
- laisser `WarpTriggered` / `ConnectionTriggered` interrompre la chaîne ;
- consommer `pathAnimationSignals` à chaque pas ;
- ne pas résoudre toute la chaîne dans un seul résultat gameplay.

## 16. Ice first vs mud first

Options :

| Option | Avantages | Risques | Verdict |
|---|---|---|---|
| Common movement effect first | évite deux modèles incompatibles | lot d'architecture sans feature visible | Recommandé |
| Ice sliding first | valeur produit claire; comportement classique | glissade plus complexe | Après Lot 114 |
| Mud movement cost first | plus simple visuellement | coût/cadence non défini | Après ice |
| Diagnostics/preview first | améliore UX existante | ne résout pas le manque moteur | À placer plus tard |

Décision :

```text
1. Contrat movement effect commun.
2. Ice sliding.
3. Mud movement cost.
```

## 17. Roadmap recommandée

| Lot | Sujet | Classement | Commentaire |
|---|---|---|---|
| 114 | Surface Movement Effect Runtime Prep V0 | Indispensable | Créer `GameplayMovementEffect` + `Moved.movementEffect` sans editor |
| 115 | Ice Sliding Runtime Prep V0 | Indispensable | Orchestration direction/chain/stop |
| 116 | Editor Generate Ice Behavior from Surface V0 | Indispensable après runtime | Authoring seulement après preuve moteur |
| 117 | Ice Runtime E2E / Closure V0 | Indispensable | Fermer surface ice -> gameplay |
| 118 | Mud Movement Cost Runtime Prep V0 | Indispensable | Définir coût/cadence |
| 119 | Editor Generate Mud Behavior from Surface V0 | Utile après prep | Attention mud vs swamp |
| 120 | Surface Gameplay Diagnostics / Coverage Preview V0 | Utile | Réduit erreurs utilisateur |
| 121 | PlayableMapGame Surface Gameplay Smoke V0 | Utile | Plus proche joueur, potentiellement bruité |
| 122 | Surface Gameplay V1 Documentation | Utile | À faire quand movement effects sont stabilisés |
| 123 | Surface Behavior Tests Split / Maintenance V0 | À retarder | Dette réelle mais non bloquante |

Prochain lot recommandé :

```text
Lot 114 — Surface Movement Effect Runtime Prep V0
```

## 18. Tests relancés

Commandes exécutées :

```bash
cd packages/map_editor && flutter test test/surface_painter/surface_to_gameplay_zone_action_test.dart --no-pub --reporter expanded
cd packages/map_editor && flutter test test/surface_painter --no-pub --reporter expanded
cd packages/map_gameplay && dart test test/surface_generated_gameplay_zone_bridge_test.dart --reporter expanded
cd packages/map_gameplay && dart test test/hazard_runtime_consumption_test.dart --reporter expanded
cd packages/map_gameplay && dart test test/movement_mode_water_test.dart --reporter expanded
cd packages/map_gameplay && dart test test/surf_evaluation_test.dart --reporter expanded
cd packages/map_core && dart test test/surface_to_gameplay_zone_generation_plan_test.dart --reporter expanded
cd packages/map_core && dart test test/surface_to_gameplay_zone_generation_assessment_test.dart --reporter expanded
cd packages/map_runtime && flutter test test/surface --reporter expanded
```

## 19. Résultats

Lignes finales exactes :

```text
surface_to_gameplay_zone_action_test.dart: 00:01 +29: All tests passed!
test/surface_painter: 00:02 +71: All tests passed!
surface_generated_gameplay_zone_bridge_test.dart: 00:00 +6: All tests passed!
hazard_runtime_consumption_test.dart: 00:00 +8: All tests passed!
movement_mode_water_test.dart: 00:00 +6: All tests passed!
surf_evaluation_test.dart: 00:00 +12: All tests passed!
surface_to_gameplay_zone_generation_plan_test.dart: 00:00 +16: All tests passed!
surface_to_gameplay_zone_generation_assessment_test.dart: 00:00 +12: All tests passed!
map_runtime test/surface: 00:01 +29: All tests passed!
```

Tous les tests de clôture demandés sont verts.

## 20. Analyse lancée

Aucune analyse Dart ciblée lancée.

Justification :

```text
Aucun fichier Dart n'a été créé ou modifié par le Lot 113.
```

## 21. Résultats analyze

Sans objet pour ce lot documentaire.

## 22. Fichiers créés

```text
reports/surface/surface_engine_lot_113_surface_movement_effects_model_decision.md
```

## 23. Fichiers modifiés

Fichiers modifiés par le Lot 113 :

```text
Aucun.
```

Fichiers modifiés préexistants, hors Lot 113 :

```text
examples/playable_runtime_host/lib/src/runtime_demo_party_seed.dart
examples/playable_runtime_host/test/runtime_demo_party_seed_test.dart
packages/map_runtime/lib/map_runtime.dart
```

Ces fichiers étaient visibles au Gate 0, mais ne sont plus visibles dans le status final.

## 24. Fichiers supprimés

```text
Aucun.
```

## 25. Contenu complet des fichiers créés

Fichier créé :

```text
reports/surface/surface_engine_lot_113_surface_movement_effects_model_decision.md
```

Le contenu complet de ce fichier est le présent rapport. Il n'est pas dupliqué une seconde fois dans cette section afin de respecter l'exception explicite anti-récursion du prompt.

## 26. Contenu complet des fichiers modifiés

```text
Aucun fichier modifié par le Lot 113.
```

Les trois fichiers déjà modifiés au Gate 0 sont des changements préexistants et hors périmètre Lot 113.

## 27. Git status final

Commandes exécutées :

```bash
git status --short --untracked-files=all
git diff --stat
git diff --check
rg -n <liste-des-formulations-interdites-du-prompt> reports/surface/surface_engine_lot_113_surface_movement_effects_model_decision.md || true
wc -l reports/surface/surface_engine_lot_113_surface_movement_effects_model_decision.md
```

`git status --short --untracked-files=all` :

```text
?? reports/surface/surface_engine_lot_113_surface_movement_effects_model_decision.md
```

`git diff --stat` :

```text
```

`git diff --check` :

```text
```

Vérification des formulations interdites dans le rapport :

```text
```

Taille du rapport après cette mise à jour finale :

```text
     814 reports/surface/surface_engine_lot_113_surface_movement_effects_model_decision.md
```

## 28. Périmètre explicitement non touché

Confirmations Lot 113 :

- map_core production non modifié ;
- map_editor production non modifié ;
- map_gameplay production non modifié ;
- map_runtime production non modifié par le Lot 113 ;
- map_battle non modifié ;
- `MapData` modèle non modifié ;
- `MapGameplayZone` modèle non modifié ;
- `HazardZonePayload` non modifié ;
- `HazardKind` non modifié ;
- `MovementZonePayload` non modifié ;
- `MovementMode` non modifié ;
- `SpecialZonePayload` non modifié ;
- `EncounterZonePayload` non modifié ;
- `GameplayStepResult` non modifié ;
- `Moved` non modifié ;
- `GameplayWorldState` non modifié ;
- `PlayableMapGame` non modifié ;
- `SurfaceLayer` non modifié ;
- `SurfaceCellPlacement` non modifié ;
- `ProjectManifest` non modifié ;
- aucun JSON ;
- aucun generated/build_runner ;
- aucune action editor nouvelle ;
- aucun dialog editor nouveau ;
- aucune glissade codée ;
- aucun ralentissement codé ;
- aucun movement cost codé ;
- aucune migration legacy ;
- aucun filtre `surfacePresetId` dans `MapGameplayZone`.

## 29. ctx stats

Commande exécutée :

```bash
ctx stats
```

Sortie exacte :

```text
Exit code: 127

stdout:


stderr:
/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/.ctx-mode-ciKuuh/script.sh: line 1: ctx: command not found
```

Synthèse Context Mode disponible :

```text
Audit principal : 10 commandes, 9581 lignes, 1099.4KB indexés.
Audit PlayableMapGame ciblé : 4 commandes, 269 lignes, 10.4KB indexés.
Régression Surface Painter : 5 sections indexées, 15.1KB.
Smoke runtime Surface : 2 sections indexées, 6.5KB.
Total minimal explicitement rapporté : 1131.4KB indexés.
```

## 30. Limites restantes

- Aucun contrat `GameplayMovementEffect` n'est encore codé.
- Aucun payload persistant movement effect n'existe encore.
- Ice sliding n'est pas implémenté.
- Mud movement cost n'est pas implémenté.
- `PlayableMapGame` ne lit pas encore `hazardEffect`, ni futur movementEffect.
- La composition hazard + movement effect reste à tester.
- La résolution de plusieurs movement effects reste volontairement hors V0.
- La stratégie de schema `map_core` pour un futur `GameplayZoneKind.movementEffect` devra être traitée dans un lot de code dédié.

## 31. Auto-critique

- Est-ce que `stepGameplayWorld` a été audité ? Oui.
- Est-ce que `GameplayStepResult` / `Moved` a été audité ? Oui.
- Est-ce que `GameplayWorldState` a été audité ? Oui.
- Est-ce que `PlayableMapGame` a été audité ? Oui.
- Est-ce que les payloads `map_core` ont été audités ? Oui.
- Est-ce que les options de contrat ont été comparées ? Oui.
- Est-ce qu'un contrat V0 est recommandé ? Oui : `GameplayMovementEffect` + `Moved.movementEffect`.
- Est-ce que effet unique vs liste est tranché ? Oui : effet unique optionnel en V0.
- Est-ce que la taxonomie future est proposée ? Oui.
- Est-ce que le pilotage de la glissade est décidé ? Oui : sémantique côté `map_gameplay`, orchestration côté `map_runtime`.
- Est-ce que ice first vs mud first est décidé ? Oui : contrat commun, puis ice, puis mud.
- Est-ce que le prochain lot recommandé est explicite ? Oui : Lot 114 — Surface Movement Effect Runtime Prep V0.
- Est-ce qu'aucun code de production n'a été modifié ? Oui par le Lot 113. Le Gate 0 contenait déjà des modifications hors lot dans `examples` / `map_runtime`.
- Est-ce que les tests de clôture ont été relancés ? Oui.
- Est-ce que Context Mode a été utilisé agressivement ? Oui.
- Est-ce que ctx stats est inclus ? Oui, avec sortie exacte et synthèse disponible.
- Est-ce que le contenu complet des fichiers créés/modifiés est copié dans le rapport ? Oui pour les fichiers modifiés par le Lot 113, aucun ; le rapport créé n'est pas recopié récursivement conformément à l'exception.
- Est-ce qu'un Lot 113-bis est nécessaire ? Non. La décision est suffisamment claire pour ouvrir un Lot 114 de prep runtime.

## 32. Regard critique sur le prompt

Le prompt pose la bonne barrière : ice et mud touchent au coeur du déplacement, donc il force une décision de contrat avant l'authoring editor. C'est exactement le garde-fou qui a évité de créer une lave purement décorative avant Lot 108.

Le point le plus important est la séparation entre :

- gate de mouvement (`MovementZonePayload`) ;
- danger post-mouvement (`HazardZonePayload`) ;
- effet de mouvement (`GameplayMovementEffect`) ;
- orchestration visuelle/runtime (`PlayableMapGame`).

La recommandation `Moved.movementEffect` garde le contrat proche de `Moved.hazardEffect` sans faire croire que la glissade complète est résolue. C'est sobre, testable, et assez honnête pour préparer ice sans transformer `MovementZonePayload` en tiroir à couverts.
