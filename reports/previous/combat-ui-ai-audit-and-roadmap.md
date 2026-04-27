# Combat UI / AI Audit And Roadmap

Date: 2026-04-19

## 1. Résumé exécutif honnête

Le dépôt est déjà au-delà du stade “moteur à construire”.
Le moteur battle est réel, le runtime handoff est réel, l'overlay est réelle, le host battleable est réel, et le golden slice est réel.

Le plus court chemin sain recommandé n'est donc pas un nouveau tunnel de plomberie battle-core.
Le plus court chemin sain est :

1. refaire la présentation combat côté `map_runtime` pour obtenir enfin une vraie scène de combat
2. brancher juste après un petit resolver de backgrounds dynamiques côté runtime, à partir du contexte déjà disponible
3. sortir ensuite la logique de choix ennemi de `battle_session.dart` via un seam de policy dédié, minimal, borné, puis mapper une difficulté produit `1..10` vers quelques profils internes

Verdict net :

- l'UI combat vit déjà au bon endroit : `packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`
- le vrai problème UI n'est pas l'absence d'overlay, c'est que l'overlay actuelle est encore un panneau monolithique très textuel
- les backgrounds dynamiques doivent vivre dans `map_runtime`, pas dans `map_battle`
- la difficulté IA ne doit pas entrer dans `packages/map_battle/lib/src/battle_session.dart`
- la bonne architecture IA est un seam de policy battle-local, choisi/configuré depuis le runtime ou la couche produit
- une échelle `1..10` est acceptable comme API produit, mais mauvaise comme modèle interne brut ; il vaut mieux la mapper vers quelques profils/tunings

Première étape concrète recommandée après cet audit :

`Battle Scene UI Pass` dans `map_runtime`, avec séparation explicite :

- scène de combat
- HUD joueur / ennemi
- zone commandes / texte
- debug séparé

Pas d'IA d'abord.
Pas de nouveau tunnel battle-core d'abord.

## 2. Pré-gates réellement exécutés + résultats

Pré-gates read-only exécutés exactement :

```bash
git status --short --untracked-files=all
git diff --stat
git ls-files --others --exclude-standard
```

Résultats réellement observés :

- `git status --short --untracked-files=all`
  - aucune sortie
- `git diff --stat`
  - aucune sortie
- `git ls-files --others --exclude-standard`
  - aucune sortie

Contrôle supplémentaire lancé parce que ce silence complet pouvait être suspect :

```bash
pwd
git rev-parse --is-inside-work-tree
git rev-parse --show-toplevel
git status --short --untracked-files=all | cat -vet
git diff --stat | cat -vet
git ls-files --others --exclude-standard | cat -vet
```

Constat réel :

- cwd correct : `/Users/karim/Project/pokemonProject`
- repo git confirmé
- worktree effectivement propre au début de l'audit

## 3. Méthode réellement suivie

Méthode suivie :

1. pré-gates read-only et constat exact du worktree
2. relecture des docs canoniques battle après `R3`
3. relecture ciblée du battle-core demandé
4. relecture ciblée du runtime/presentation combat demandé
5. relecture des tests runtime/host qui servent de vérité produit
6. recherches repo ciblées sur :
   - trainer data
   - wild encounter data
   - metadata de map / tags / indoor-outdoor
   - thème visuel / battleThemeId / portraitElementId
   - logique IA existante
   - seam potentiel pour `BattleBackgroundResolver`
   - seam potentiel pour `BattleOpponentPolicy`
7. relance des validations demandées
8. audits parallèles via sub-agents
9. synthèse en une seule roadmap recommandée

Skills/plugins réellement utilisés :

- `superpowers:using-superpowers`
- `superpowers:brainstorming`
- `superpowers:writing-plans`
- `superpowers:dispatching-parallel-agents`
- `superpowers:requesting-code-review`
- `superpowers:verification-before-completion`
- `game-studio:game-ui-frontend`

Usage réel :

- `superpowers` a servi de garde-fou méthodologique
- `game-studio` a surtout servi à cadrer la lecture UI comme sujet de scène/runtime, pas de host-only hack

### Sub-agents réellement utilisés

- `Laplace`
  - audit battle-core / seams IA
- `Pasteur`
  - audit runtime / UI combat
- `Darwin`
  - audit backgrounds / contexte map / données disponibles
- `Dirac`
  - audit ordre de travail / lisibilité produit

Apport utile réel :

- `Laplace` confirme que le seam IA sain est un contrat de policy battle-local et non une logique plus riche recodée dans `battle_session.dart`
- `Pasteur` confirme que le vrai seam UI est déjà `PlayableMapGame` + `BattleOverlayComponent`, pas le host
- `Darwin` confirme que le contexte backgrounds existe déjà surtout côté `BattleStartRequest`, `MapMetadata`, `ProjectMapEntry`, `ProjectTrainerEntry` et `ProjectEncounterTable`
- `Dirac` confirme que l'ordre le plus sain est UI d'abord, décor ensuite, IA après

### Review séparée finale

Une review séparée finale a bien été tentée après rédaction.

Tentatives réellement faites :

- `Huygens` sollicité comme reviewer séparé principal
- `Carson` sollicité en repli

Résultat réel :

- aucune réponse exploitable n'est revenue dans le délai imparti
- je garde donc explicitement la mention : review séparée tentée, mais non obtenue à temps

## 4. Périmètre de l'audit

### Inclus

- lecture battle-core réelle
- lecture runtime/presentation combat réelle
- lecture host/tests vérité produit réelle
- recherche repo sur backgrounds dynamiques et seams IA
- validations battle/runtime/host ciblées
- recommandation d'architecture et d'ordre de travail

### Exclus volontairement

- toute modification de code source
- toute modification de test
- toute création d'asset
- tout refactor préventif
- toute ouverture mécanique battle
- toute implémentation d'IA
- toute réécriture documentaire large hors ce report

## 5. Fichiers lus

### Docs canoniques / reports

- `docs/combat/battle-canonical-state-v3.1.md`
- `docs/combat/battle-roadmap-canonical-v3.1.md`
- `reports/r2-scheduler-consolidation-report.md`
- `reports/r3-condition-lifecycle-consolidation-report.md`
- `reports/battle-roadmap-canonique-v3.1.md`

### Battle core

- `packages/map_battle/lib/map_battle.dart`
- `packages/map_battle/lib/src/battle_session.dart`
- `packages/map_battle/lib/src/battle_session_scheduler.dart`
- `packages/map_battle/lib/src/battle_state.dart`
- `packages/map_battle/lib/src/battle_setup.dart`
- `packages/map_battle/lib/src/battle_decision.dart`
- `packages/map_battle/lib/src/battle_queue.dart`
- `packages/map_battle/lib/src/battle_condition_engine.dart`
- `packages/map_battle/lib/src/battle_field.dart`
- `packages/map_battle/lib/src/battle_status.dart`
- `packages/map_battle/lib/src/battle_volatile.dart`
- `packages/map_battle/lib/src/battle_move.dart`
- `packages/map_battle/lib/src/battle_action.dart`
- `packages/map_battle/lib/src/battle_resolution.dart`
- `packages/map_battle/lib/src/battle_topology.dart`
- `packages/map_battle/lib/src/battle_type_chart.dart`
- `packages/map_battle/lib/src/battle_stealth_rock.dart`
- `packages/map_battle/lib/src/battle_spikes.dart`

### Runtime / présentation combat

- `packages/map_runtime/lib/src/application/battle_start_request.dart`
- `packages/map_runtime/lib/src/application/trainer_battle_request.dart`
- `packages/map_runtime/lib/src/application/encounter_to_battle_request.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart`
- `packages/map_runtime/lib/src/application/runtime_map_bundle.dart`
- `packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart`
- `packages/map_runtime/lib/src/application/runtime_move_catalog_loader.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_transition_overlay_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`

### Tests vérité produit

- `packages/map_runtime/test/battle_overlay_component_test.dart`
- `packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart`
- `packages/map_runtime/test/phase_a_golden_battle_slice_smoke_test.dart`
- `packages/map_runtime/test/runtime_battle_move_bridge_test.dart`
- `packages/map_runtime/test/runtime_battle_combatant_seed_builder_test.dart`
- `examples/playable_runtime_host/test/project_loader_page_test.dart`
- `examples/playable_runtime_host/test/runtime_launch_save_test.dart`
- `examples/playable_runtime_host/test/runtime_demo_party_seed_test.dart`
- `examples/playable_runtime_host/test/phase_a_golden_slice_launch_test.dart`

### Données / modèles utiles au sujet

- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/project_trainer.dart`
- `packages/map_core/lib/src/models/map_metadata.dart`
- `packages/map_core/lib/src/models/map_entity_payloads.dart`
- `packages/map_gameplay/lib/src/gameplay_encounter.dart`
- `examples/playable_runtime_host/golden_battle_slice/project.json`
- `examples/playable_runtime_host/golden_battle_slice/maps/golden_field.json`

## 6. Validations réellement relancées

Battle :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_battle && dart analyze
cd /Users/karim/Project/pokemonProject/packages/map_battle && dart test
```

Runtime / vérité produit :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_runtime && flutter test \
  test/battle_overlay_component_test.dart \
  test/wild_battle_end_to_end_flow_test.dart \
  test/phase_a_golden_battle_slice_smoke_test.dart
```

Host :

```bash
cd /Users/karim/Project/pokemonProject/examples/playable_runtime_host && flutter test \
  test/project_loader_page_test.dart \
  test/runtime_launch_save_test.dart \
  test/runtime_demo_party_seed_test.dart \
  test/phase_a_golden_slice_launch_test.dart
```

## 7. Résultats réellement obtenus

### Battle

- `dart analyze`
  - `Analyzing map_battle...`
  - `No issues found!`
- `dart test`
  - `+169: All tests passed!`

### Runtime

- `flutter test ... battle_overlay_component_test.dart wild_battle_end_to_end_flow_test.dart phase_a_golden_battle_slice_smoke_test.dart`
  - `All tests passed!`

### Host

- `flutter test ... project_loader_page_test.dart runtime_launch_save_test.dart runtime_demo_party_seed_test.dart phase_a_golden_slice_launch_test.dart`
  - `All tests passed!`

Interprétation utile :

- la baseline battle/runtime/host est saine au moment de l'audit
- il n'y a pas de signal qu'un redesign UI ou un seam IA exigerait d'abord une campagne de réparation battle-core large

## 8. État actuel du combat côté UI

### Où vit aujourd'hui la vraie responsabilité d'affichage du combat

La vraie responsabilité d'affichage du combat vit aujourd'hui dans :

- `packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`
- montée et pilotée par `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`

Concrètement :

- `_startBattleHandoff()` ouvre la transition battle
- `_openBattleOverlay()` crée `BattleSession` puis `BattleOverlayComponent`
- `_onPlayerBattleChoice()` applique le choix et rafraîchit l'overlay
- `_onBattleFinished()` écrit le résultat puis revient à l'overworld

L'UI de combat est donc déjà clairement runtime-side.
Ce n'est pas un sujet `map_battle`.

### Ce qui reste trop “debug panel”

Le problème actuel n'est pas l'absence d'UI.
Le problème est que `BattleOverlayComponent` reste un composant unique, très textuel, qui mélange :

- fond sombre plein écran
- panneau central unique
- titre de combat
- PV joueur / ennemi en texte
- prompt de décision en texte
- liste plate de choix
- restitution du tour sous forme de lignes de timeline concaténées
- gestion de sélection / highlight / input

Cette overlay lit encore comme un panneau technique monolithique.

Indices concrets :

- un seul `PositionComponent` racine pour tout le combat
- rendu texte des PV
- rendu texte des choix
- rendu texte du tour
- `⚔ MoveName (Puissance: X)` et `Switch vers speciesId`

### Ce qui est déjà bien séparé

Le repo a déjà un point de vérité utile :

- le panneau debug du host est séparé du combat normal
- dans `examples/playable_runtime_host/lib/main.dart`, les toggles collisions/FPS/Surf/save info sont dans une carte Flutter distincte

Donc le vrai problème n'est pas “debug et combat sont confondus partout”.
Le vrai problème est plus précis :

- le combat normal runtime est encore visuellement trop proche d'un panneau d'outil

### Meilleure stratégie pour introduire une vraie scène de combat

La meilleure stratégie repo-réelle est :

1. garder `PlayableMapGame` comme orchestrateur ouverture/fermeture/update
2. garder `BattleSession` comme vérité métier
3. faire évoluer la surface runtime de `BattleOverlayComponent` vers une vraie composition de scène
4. ne pas migrer la responsabilité de combat visuel vers le host
5. ne pas toucher `map_battle`

En pratique, la bonne séparation cible est :

- `BattleSceneRoot`
  - possède le fond, les ancrages visuels, la composition générale
- `BattleHudEnemy`
  - nom, niveau, HP, statut, infos hautes
- `BattleHudPlayer`
  - nom, niveau, HP, statut, infos basses
- `BattleCommandBox`
  - lit `BattleDecisionRequest` et rend les commandes
- `BattleLogBox`
  - lit `BattleTurnResult.timeline` et rend la narration
- `BattleDebugOverlay` optionnelle
  - séparée, désactivable, jamais fusionnée avec l'UI normale

Je ne recommande pas de déplacer tout ça directement en Flutter host-only.
Le seam vivant est déjà dans `map_runtime` / Flame.

## 9. État actuel du combat côté runtime / presentation

### Flow réel actuel

Le flow réel côté runtime est déjà cohérent :

1. `BattleStartRequest` construit le contexte d'entrée
2. `RuntimeBattleSetupMapper` fabrique le `BattleSetup`
3. `createBattleSession(setup)` ouvre le moteur
4. `BattleOverlayComponent` consomme `session`, `decisionRequest` et `currentTurn`
5. `applyRuntimeBattleOutcomeToGameState` fait le write-back

Ce flow n'a pas besoin d'être réinventé pour améliorer l'UI.

### Bonne séparation de responsabilités à conserver

- `map_battle`
  - vérité métier
  - request model
  - timeline
  - outcome
- `map_runtime` application
  - handoff
  - mapping setup
  - write-back
- `map_runtime` presentation
  - scène visuelle
  - HUD
  - commandes
  - narration
- host
  - lancement, debug out-of-band, menu global

### Ce qu'il ne faut pas faire

- ne pas pousser l'habillage battle dans `RuntimeBattleSetupMapper`
- ne pas mettre la vraie battle UI dans `examples/playable_runtime_host`
- ne pas demander un nouveau contrat battle-core juste pour dessiner mieux

## 10. État actuel de la logique IA

### Où vit aujourd'hui la logique de choix ennemi

Aujourd'hui, la logique de choix ennemi vit encore dans :

- `packages/map_battle/lib/src/battle_session.dart`
- `BattleSession.applyChoice(...)`
- `_chooseEnemyAction()`

Flow réel :

- `applyChoice()` convertit le choix joueur
- résout éventuellement une action forcée adverse
- sinon appelle `_chooseEnemyAction()`

### Ce que fait réellement `_chooseEnemyAction()`

Comportement actuel :

- ennemi K.O. -> `BattleActionNone()`
- aucun move configuré -> `StateError`
- sinon premier move avec PP utilisable
- si aucun move utilisable -> `StateError` explicite (`Struggle` hors scope)

Il n'existe aujourd'hui :

- ni `BattleOpponentPolicy`
- ni policy injection
- ni métadonnée trainer de difficulté
- ni échelle de difficulté runtime branchée au moteur

### Lecture architecturale honnête

Ce point n'est plus sain comme état final.
Mais il n'appelle pas un grand chantier battle-core.

Le seam minimal sain est :

- un petit contrat de policy battle-local côté `map_battle`
- choisi/configuré depuis le runtime ou une couche produit supérieure
- sans toucher au scheduler
- sans toucher au request model
- sans ouvrir `switch/replacement/targeting`

### Contrat candidat recommandé

Pseudo-signature candidate, volontairement petite :

```dart
/// Battle-local on purpose:
/// - the policy sees battle state that already exists;
/// - it does not own requests, queueing, replacement, or scheduler flow;
/// - it only answers one narrow question:
///   "which already-legal enemy fight action should be used now?"
abstract interface class BattleOpponentPolicy {
  BattleActionFight chooseFight({
    required BattleCombatant self,
    required BattleCombatant opponent,
    required BattleFieldState field,
    required List<BattleActionFight> legalFightActions,
  });
}
```

Pourquoi cette forme est saine :

- `fight-only` empêche la dérive immédiate vers `R4`
- le scheduler reste ailleurs
- les forced actions restent gérées par `BattleSession`
- pas de faux support `Run`, `Capture`, `Switch` intelligent

Ce qu'il ne faut pas faire :

- une policy qui reçoit `BattleSession` entière
- une policy qui pilote la queue
- une policy qui choisit déjà les remplacements
- une policy qui exige un targeting riche

## 11. État actuel des données / contextes disponibles pour backgrounds dynamiques

### Données déjà présentes et réellement utiles

#### BattleStartRequest

Le runtime a déjà :

- wild :
  - `mapId`
  - `zoneId`
  - `tableId`
  - `encounterKind`
  - `speciesId`
  - `playerPos`
- trainer :
  - `trainerId`
  - `npcEntityId`
  - `mapId`
  - `playerPos`

#### Map context

`MapMetadata` fournit déjà :

- `mapType`
- `weather`
- `isIndoor`
- `tags`
- `displayName`

`ProjectMapEntry` fournit déjà :

- `role`

#### Trainer context

`ProjectTrainerEntry` fournit déjà :

- `trainerClass`
- `portraitElementId`
- `battleThemeId`
- `victoryThemeId`
- `tags`

#### Encounter context

`ProjectEncounterTable` fournit déjà :

- `encounterKind`
- `tags`

#### NPC / authored context

`MapEntityNpcData` fournit déjà :

- `trainerId`
- `visualElementId`
- `characterId`

### Ce qui manque réellement

Il manque aujourd'hui :

- un `BattleBackgroundResolver` vivant
- un `BattleBackgroundSpec` vivant
- un vrai catalogue de backgrounds battle
- un champ `biome` typé dédié
- une validation/runtime consumption réelle de `battleThemeId` / `victoryThemeId`

Important :

- les données de contexte existent déjà
- ce qui manque est surtout le seam de résolution et le catalogue réel
- pas une nouvelle plomberie battle-core

### Où il faut brancher la résolution de fond de combat

Le bon point de branchement est juste avant l'ouverture de l'overlay combat, là où le runtime possède déjà :

- `BattleStartRequest`
- `RuntimeMapBundle`
- manifest
- map courante

Le bon lieu est donc `map_runtime`, pas `map_battle`.

### Contrat minimal honnête recommandé

```dart
/// Runtime-side on purpose:
/// - it consumes authored/runtime context that battle-core should never know;
/// - it returns presentation data only;
/// - it can start tiny and fallback-heavy.
abstract interface class BattleBackgroundResolver {
  BattleBackgroundSpec resolve({
    required RuntimeMapBundle bundle,
    required BattleStartRequest request,
  });
}

/// Start with a tiny spec:
/// - one resolved key for the background family;
/// - optional variant tags if the scene wants them later;
/// - no promise of a full asset pipeline yet.
final class BattleBackgroundSpec {
  final String backgroundKey;
  final List<String> variantTags;
}
```

### Fallback chain recommandée

Premier fallback chain sain :

1. contexte map d'abord
   - `isIndoor`
   - `mapType`
   - `role`
   - `tags`
2. enrichissement wild
   - `encounterKind`
   - `encounterTable.tags`
3. enrichissement trainer
   - `trainerClass`
   - `trainer.tags`
4. fallback final stable
   - `default_wild`
   - `default_trainer`

Piège à éviter absolument :

- ne pas laisser le trainer dicter le décor avant l'environnement de map

## 12. Seams candidats identifiés

### Seam UI combat crédible

Seam recommandé :

- `PlayableMapGame._openBattleOverlay()`
- `BattleOverlayComponent` à faire évoluer en root de scène plus lisible

Pourquoi c'est le bon seam :

- battle handoff déjà vivant
- session déjà créée à cet endroit
- update loop déjà en place
- aucune raison de toucher `map_battle`

### Seam backgrounds crédible

Seam recommandé :

- petit `BattleBackgroundResolver` runtime-side
- appelé depuis le flow d'ouverture combat

Pourquoi c'est le bon seam :

- le runtime a déjà le bon contexte
- pas besoin d'élargir `BattleSetup` ni `BattleStartRequest` pour commencer
- pas besoin de battle-core

### Seam IA crédible

Seam recommandé :

- petit `BattleOpponentPolicy` battle-local
- choisi/configuré depuis runtime/product

Pourquoi c'est le bon seam :

- l'IA doit raisonner sur l'état battle réel
- mais la décision produit “quel niveau / quel profil ?” ne doit pas vivre dans `battle_session.dart`

### Lecture de séparation recommandée

- UI de combat -> `map_runtime`
- backgrounds dynamiques -> `map_runtime`
- choix de difficulté / mapping trainer -> runtime ou couche produit
- contrat de policy battle -> `map_battle`
- logique de résolution de combat -> `map_battle`

## 13. Zones dangereuses / anti-patterns à éviter

### À éviter absolument

- coder la difficulté directement dans `packages/map_battle/lib/src/battle_session.dart`
- créer 10 IA complètement séparées
- mettre les backgrounds dynamiques dans `map_battle`
- faire une vraie battle UI côté host seulement
- lancer un grand framework générique de présentation combat
- lancer un grand framework générique d'IA avant d'avoir le seam minimal
- ouvrir `switch/replacement` intelligent trop tôt
- ouvrir des scripts de boss trop tôt

### Faux beaux plans à éviter

- “on commence par rendre le battle-core encore plus propre avant tout résultat visible”
- “on crée un mega BattlePresentationSystem future-proof”
- “on supporte directement une difficulté 1..10 interne brute”
- “on fait des backgrounds dynamiques via heuristiques de tileset/layers”

### Lecture repo-réelle des risques

- le plus gros risque UI est un refactor de composants sans vrai gain de composition
- le plus gros risque backgrounds est de construire un système trop gros sans assets ni catalogue réel
- le plus gros risque IA est de faire un seam mal placé et de re-salir `battle_session.dart`

## 14. Classification `do_now / do_soon / defer / not_recommended`

### `do_now`

- refonte UI de combat
  - c'est le meilleur gain produit visible immédiat
- séparation panneau debug / UI combat normale
  - partiellement déjà vraie au host, mais à finaliser dans la présentation battle runtime

### `do_soon`

- backgrounds dynamiques
  - juste après la scène UI, sur le même seam runtime
- seam IA dédié
  - important pour la santé de la suite, mais moins visible que l'UI
- profils de difficulté mappés
  - bonne implémentation interne de la difficulté
- échelle de difficulté `1..10`
  - comme API produit mappée vers des profils, pas comme 10 IA brutes

### `defer`

- scripts de boss / scripts trainer spécifiques
  - utile plus tard, mauvais premier lot
- switch intelligent / replacement intelligent
  - risque de dérive vers `R4`
- logique IA riche condition-aware ou target-aware
  - utile plus tard, pas pour le seam minimal

### `not_recommended`

- toute logique IA directement dans `battle_session.dart`
- 10 IA totalement indépendantes
- host-only battle UI
- backgrounds dynamiques battle-core side
- grand framework générique de battle presentation
- grand framework générique de policy zoo

## 15. Roadmap unique recommandée

### Étape 1 — `Battle Scene UI Pass`

But :

- faire ressembler le combat à un jeu et non à un panneau technique

Travail :

- conserver le flow runtime existant
- transformer l'overlay monolithique en scène composée
- garder `BattleDecisionRequest` et `BattleTurnResult.timeline` comme vérité
- isoler la debug overlay du rendu normal

Sortie attendue :

- fond plein écran
- composition joueur bas / ennemi haut
- HUD séparés
- command box lisible en bas
- battle log / text zone lisible

### Étape 2 — `Contextual Battle Backgrounds`

But :

- faire varier le fond de combat sans élargir le battle-core

Travail :

- introduire un petit `BattleBackgroundResolver`
- consommer `BattleStartRequest + RuntimeMapBundle + manifest`
- commencer par un fallback chain simple et honnête
- ne pas dépendre d'un système d'assets parfait dès le premier lot

Sortie attendue :

- au moins quelques variations honnêtes :
  - sauvage vs trainer
  - indoor vs outdoor
  - quelques map types / tags

### Étape 3 — `Opponent Policy Seam Extraction`

But :

- sortir le choix ennemi de `battle_session.dart`

Travail :

- créer un seam de policy minimal fight-only
- garder le comportement initial équivalent au repo actuel
- laisser `BattleSession` gérer forced actions et validation

Sortie attendue :

- `battle_session.dart` n'est plus l'endroit où l'on code la difficulté
- le moteur reste stable

### Étape 4 — `Difficulty Profiles Mapped From 1..10`

But :

- exposer une difficulté lisible côté produit sans 10 IA ingérables

Travail :

- garder `1..10` comme input produit si tu le veux
- le mapper vers quelques profils internes
- faire grandir les heuristiques progressivement

Exemple de lecture saine :

- `1..2` -> très naïf
- `3..4` -> naïf + PP legal
- `5..6` -> dégâts simples / type-aware minimal
- `7..8` -> KO-aware / setup-aware léger
- `9..10` -> heuristique la plus forte disponible

Important :

- cela ne veut pas dire 10 IA différentes
- cela veut dire 1 contrat + quelques profils + réglages

## 16. Ordre de travail recommandé

### Ordre recommandé, net

1. UI combat d'abord
2. backgrounds ensuite, comme extension directe de la scène
3. seam IA ensuite
4. profils de difficulté ensuite
5. scripts de boss / comportements riches beaucoup plus tard

### Pourquoi cet ordre est le plus productif

#### Techniquement

- l'UI et les backgrounds vivent déjà naturellement dans le runtime
- ils n'ont pas besoin d'un gros chantier battle-core préalable
- l'IA, elle, exige un seam propre pour ne pas salir `battle_session.dart`

#### Psychologiquement / produit

- l'UI donne immédiatement un résultat visible
- les backgrounds amplifient immédiatement l'effet “ça ressemble à un vrai jeu”
- l'IA vient ensuite sur une base de présentation déjà satisfaisante

### Plus court chemin sain vers “moins proto technique”

Le plus court chemin sain n'est pas :

- “extraire l'IA d'abord”
- “retravail profond du battle-core d'abord”

Le plus court chemin sain est :

- scène de combat runtime
- fond dynamique minimal
- puis seam IA dédié

## 17. Critique explicite du prompt lui-même

### Parties utiles

- insister sur le fait que le moteur battle est déjà réel
- rappeler que l'UI appartient au runtime/presentation
- rappeler que les backgrounds appartiennent au runtime
- interdire la difficulté dans `battle_session.dart`
- demander une seule trajectoire recommandée
- exiger une lecture repo-réelle

### Parties discutables

- “échelle lisible de 1 à 10” est une bonne demande produit, mais une mauvaise forme d'architecture interne si prise littéralement
- vouloir auditer UI, backgrounds et IA en un seul passage mélange trois natures de travail très différentes ; c'est faisable pour l'audit, mais ce ne serait pas une bonne idée de tout implémenter dans un seul lot

### Parties trop rigides

- le caractère “ultra complet” peut pousser à l'excès documentaire ; j'ai donc resserré vers du concret repo-réel plutôt que vers une dissertation plus longue
- l'obligation de relire beaucoup de fichiers battle secondaires est saine comme garde-fou, mais les recherches repo ciblées ont été plus utiles que certaines relectures complètes pour le sujet backgrounds / IA
- l'exigence d'une review séparée finale est bonne, mais reste dépendante de la disponibilité réelle des agents ; elle ne doit pas conduire à inventer un retour qui n'existe pas

### Ce que j'ai volontairement resserré

- j'ai resserré l'audit backgrounds sur le vrai seam runtime et les données réellement existantes, pas sur une spéculation d'assets
- j'ai resserré l'audit IA sur le seam minimal fight-only, pas sur des comportements riches qui dériveraient vers `R4`
- j'ai resserré l'audit UI sur le combat runtime, pas sur un redesign global du host

## 18. Autocritique finale

- je n'ai pas fait de playtest visuel réel, seulement un audit code/tests, donc la recommandation UI reste structurelle et non artistique
- il n'existe pas encore de catalogue battle background dans le repo, donc la partie backgrounds reste forcément une proposition de seam plus que d'assets
- le détail exact des profils de difficulté devra être ajusté au moment d'implémenter, car le repo n'a pas encore de seam IA vivant à tester empiriquement
- je n'ai pas trouvé de métadonnée trainer de difficulté déjà existante ; si tu veux un réglage par trainer, il faudra vraisemblablement l'ajouter côté données produit plus tard

## 19. État git final utile

État final utile :

- aucun code source modifié
- aucun test modifié
- aucun asset créé
- aucun refactor effectué
- un seul fichier nouveau créé :
  - `reports/combat-ui-ai-audit-and-roadmap.md`

Pré-gates finaux réellement observés après création du report :

- `git status --short --untracked-files=all`
  - `?? reports/combat-ui-ai-audit-and-roadmap.md`
- `git diff --stat`
  - aucune sortie
- `git ls-files --others --exclude-standard`
  - `reports/combat-ui-ai-audit-and-roadmap.md`

Aucune écriture Git interdite n'a été faite :

- pas de commit
- pas d'amend
- pas de merge
- pas de rebase
- pas de push
- pas de tag

## 20. Checklist finale

- audit strictement read-only : oui
- modification de code source évitée : oui
- validations utiles relancées : oui
- seam UI combat crédible identifié : oui
- seam backgrounds crédible identifié : oui
- seam IA crédible identifié : oui
- logique de difficulté évitée dans `battle_session.dart` : oui
- roadmap unique et concrète proposée : oui
- sub-agents utilisés : oui
- review séparée tentée : oui
- review séparée effectivement obtenue : non, pas dans le délai imparti
- écriture Git interdite évitée : oui

## 21. Décision finale nette

### Plus court chemin sain recommandé

Le plus court chemin sain recommandé est :

1. **battle scene runtime d'abord**
2. **background resolver runtime ensuite**
3. **policy IA dédiée ensuite**
4. **difficulté produit `1..10` mappée vers quelques profils internes**

### Première étape concrète recommandée après cet audit

Première étape concrète recommandée :

`Battle Scene UI Pass` dans `packages/map_runtime/lib/src/presentation/flame`

Objectif :

- sortir d'un panneau monolithique textuel
- obtenir une vraie scène de combat
- garder la vérité actuelle du runtime et du moteur intacte

Si cette première étape est réussie, alors le lot backgrounds devient petit et naturel.
Ensuite seulement, le seam IA devient le prochain vrai chantier défendable.
