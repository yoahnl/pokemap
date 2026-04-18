# Battle Canonical State v3.1

Statut: canon battle actuel du dépôt après `R1 — Battleable Slice Hardening`

Date de réalignement: 2026-04-18

## But du document

Ce document est la photographie canonique de l'état battle réel de PokeMap.

Il ne décrit ni une intention, ni une vieille phase, ni une promesse.
Il décrit ce que le dépôt sait réellement faire aujourd'hui, sur la base:

1. du code réel
2. des validations réellement relancées
3. du runtime réellement branché
4. du host et du golden slice réellement versionnés
5. du bootstrap réellement présent
6. de la comparaison locale ciblée avec Pokémon Showdown

Ce document remplace comme source de vérité battle actuelle les anciennes formulations qui racontent encore:

- un handoff runtime -> battle à construire
- une battleabilité encore purement future
- un moteur encore “pré-fondations”

## Résumé exécutif honnête

Le moteur battle PokeMap est déjà réel.

Le dépôt supporte déjà un vrai slice `singles-only` avec:

- une vraie battle loop locale
- un vrai handoff runtime -> battle
- une vraie overlay pilotée par une timeline observable
- de vraies battles wild et trainer
- de vraies réserves côté joueur et côté trainer
- une vraie fuite sauvage
- une vraie capture minimale
- un vrai write-back runtime minimal
- un vrai ordre local priorité / vitesse / Trick Room
- PP / accuracy / crit minimaux réels
- dégâts simples + STAB + effectiveness + immunités
- statuts majeurs `par`, `brn`, `psn`, `tox`
- volatiles bornés `protect`, `recharge`, `chargeThenStrike`
- `rain`, `sandstorm`, `trickRoom`
- switch volontaire
- forced replacement joueur
- auto-switch ennemi
- `Stealth Rock`
- `Spikes`

Le moteur n'est pas proche de Pokémon Showdown au sens structurel large.
L'écart dominant n'est plus l'absence de slice battleable. L'écart dominant est:

- la centralisation dans `packages/map_battle/lib/src/battle_session.dart`
- l'étroitesse des contracts requests / targeting / replacement
- la petitesse du scheduler local existant
- l'asymétrie entre conditions moteur et side conditions/hazards

La vérité produit actuelle est la suivante:

- un **golden slice battleable versionné** existe réellement
- un **host lançable** existe réellement
- un **bootstrap projet frais générique** existe réellement, mais il n'est pas équivalent à un projet battle-ready générique

Décision canonique après R1:

- la prochaine vraie étape officielle est `R2 — Scheduler Consolidation`

## État réel du moteur battle

### Ce qui existe déjà réellement

#### Topologie et état

Le moteur a déjà une vraie topologie singles-bornée:

- `BattleSideId`
- `BattleSlotRef`
- un seul slot actif par side
- réserves réelles des deux côtés

Fichiers pivots:

- `packages/map_battle/lib/src/battle_topology.dart`
- `packages/map_battle/lib/src/battle_state.dart`
- `packages/map_battle/lib/src/battle_setup.dart`

#### Requests et décisions

Le moteur expose déjà un vrai request model local via `BattleDecisionRequest`:

- `turnChoice`
- `forcedReplacement`
- `continue`
- `wait`

Ce n'est pas le request model riche de Showdown, mais ce n'est plus un placeholder.

Fichier pivot:

- `packages/map_battle/lib/src/battle_decision.dart`

#### Queue / scheduling local

Le moteur a déjà une vraie queue locale:

- `action`
- `endOfTurn`
- `postTurnChecks`
- `autoSwitch`
- `replacementRequired`

`Run` et `Capture` restent volontairement hors queue.

Ce seam existe déjà. Il ne faut plus le raconter comme “à créer”.

Fichier pivot:

- `packages/map_battle/lib/src/battle_queue.dart`

#### Condition engine local

Le moteur a déjà un vrai `BattleConditionEngine` local.

Il sait déjà piloter:

- `runActionAttempt`
- `runHitInterception`
- `runMoveResolved`
- `runForcedContinueTurn`
- `runEndOfTurn`

Ce seam est réel, consommé, et testé.

Fichier pivot:

- `packages/map_battle/lib/src/battle_condition_engine.dart`

#### Résolution de tour

Le moteur résout déjà réellement:

- ordre priorité / vitesse / Trick Room
- accuracy locale
- consommation de PP
- crit minimal
- dégâts simples
- STAB
- effectiveness
- immunités
- statuts majeurs supportés
- volatiles supportés
- field supporté
- switch / replacement / auto-switch
- hazards supportées

Fichier pivot:

- `packages/map_battle/lib/src/battle_session.dart`

#### Restitution observable

Le moteur a déjà une vraie chronologie de tour exploitable via:

- `BattleTurnResult.timeline`

Fichier pivot:

- `packages/map_battle/lib/src/battle_resolution.dart`

### Ce qui est réellement supporté mais borné

- `singles-only`
- un slot actif par side
- targeting local minimal `self/opponent/field/opponentSide/unspecified`
- scheduler local réel mais borné
- condition engine réel mais borné
- side-level mechanics ouvertes sur deux slices dédiées, pas un framework générique
- write-back runtime réel mais étroit

### Ce qui est fragile

- `Struggle` reste absent et volontairement hors scope R1
- côté joueur, `BattleWaitReason.noLegalChoice` est un dead-end explicite et unsupported ; ce n'est ni un flow gameplay acceptable, ni un support implicite de `Struggle`
- côté ennemi, l'absence totale d'action légale reste un `StateError` explicite ; cette asymétrie est assumée en R1 et ne vaut pas support complet du cas “no move left”
- l'ennemi sans action légale échoue désormais explicitement au lieu de produire un faux `Run`
- tie-break vitesse égale déterministe joueur d'abord
- priorité de switch localement hardcodée
- politique de double KO locale, maintenue explicitement en R1
- ordre d'entrée hazards local `Stealth Rock` puis `Spikes`
- compatibilités legacy dans `BattleMove` et `BattleTypeChart`

### Ce qui n'est pas supporté honnêtement aujourd'hui

- doubles
- targeting riche Showdown
- `selfSwitch` générique
- `forceSwitch` / phazing générique
- terrains
- `Toxic Spikes`
- `Sticky Web`
- abilities
- items
- système générique de side conditions
- event engine Showdown-like

## État réel du runtime battle

### Handoff runtime -> battle

Le handoff runtime -> battle est réel.

Le runtime sait aujourd'hui:

- construire une `WildBattleStartRequest`
- construire une `TrainerBattleStartRequest`
- mapper ces requests vers un `BattleSetup` réel
- résoudre une lineup joueur active + réserves
- construire des seeds combatants réels à partir des données runtime/projet

Fichiers pivots:

- `packages/map_runtime/lib/src/application/battle_start_request.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart`

### Bridge moves

Le bridge runtime moves -> battle est réel et volontairement strict.

Il transporte honnêtement le sous-ensemble supporté et refuse explicitement le hors-scope.

Fichier pivot:

- `packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart`

### Overlay battle

L'overlay est branchée sur la vérité moteur actuelle:

- requests
- timeline
- refresh de session

Fichier pivot:

- `packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`

### Write-back

Le write-back runtime est réel, mais étroit.

Ce qu'il sait réellement faire:

- write-back des PV sur la party engagée
- marquage trainer defeated
- capture minimale
- whiteout-lite

Fichier pivot:

- `packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart`

## État réel du bootstrap / seed

### Ce qui existe réellement

- un seed moves embarqué et versionné
- un bootstrap projet frais générique
- un seed de démo explicite et séparé

Fichiers pivots:

- `packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart`
- `packages/map_editor/lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart`
- `packages/map_editor/lib/src/application/use_cases/seed_pokemon_demo_data_use_case.dart`

### Vérité bootstrap honnête

Le bootstrap projet frais générique ne doit pas être lu comme “projet battle-ready générique”.

Le dépôt distingue maintenant clairement:

- l'initialisation de structure projet
- le seed de données de démo
- le golden slice battleable versionné

### R1 a réaligné les points de vérité bootstrap les plus trompeurs

- `trick_room` n'est plus sous-déclaré dans le seed par rapport au sous-ensemble réellement consommé
- `stealth_rock` et `spikes` ne vivent plus dans un regroupement historiquement trompeur

## Vérité produit réelle

### Golden slice battleable versionné

Le dépôt versionne une vérité produit battleable réelle:

- slice golden battleable
- save de lancement adjacente
- host Flutter lançable
- smoke tests wild et trainer

Fichiers pivots:

- `examples/playable_runtime_host/README.md`
- `examples/playable_runtime_host/golden_battle_slice/README.md`
- `examples/playable_runtime_host/lib/src/runtime_launch_save.dart`
- `examples/playable_runtime_host/test/phase_a_golden_slice_launch_test.dart`
- `packages/map_runtime/test/phase_a_golden_battle_slice_smoke_test.dart`

### Bootstrap projet frais générique

Un projet fraîchement initialisé n'est pas, à lui seul, la vérité produit battleable.

Le bootstrap générique:

- structure le projet
- seed le minimum nécessaire
- ne garantit pas une battleabilité générique équivalente au golden slice

### Distinction canonique à retenir

Il faut désormais distinguer explicitement:

- **golden slice battleable versionné**: preuve produit actuelle
- **bootstrap projet frais générique**: fondation projet, pas promesse battle complète

## Matrice de support par famille

| Famille | État réel PokeMap | Niveau de proximité Showdown | Notes canoniques |
|---|---|---|---|
| request model | réel mais joueur-only / slot-0 | faible structurellement, honnête localement | seam vivant, non générique |
| side / slot | réel, singles-borné avec réserves | honnête localement, loin du modèle Showdown large | vraie topologie locale |
| targeting | minimal et étroit | faible | pas de moteur de ciblage riche |
| queue / scheduling | réel mais petit | faible structurellement, honnête localement | ne pas le raconter comme absent |
| statuses | réels pour `par/brn/psn/tox` | faible | slice honnête |
| volatiles | réels pour `protect/recharge/chargeThenStrike` | faible | slice honnête |
| field / pseudoWeather | réel pour `rain/sandstorm/trickRoom` | faible structurellement, honnête localement | slice honnête |
| hazards / side conditions | réelles pour `Stealth Rock` et `Spikes` | faible | pas de framework générique |
| switch / replacement | réels | honnête localement, loin du modèle Showdown large | vrai pipeline local |
| PP / accuracy / crit / damage | réels et bornés | honnête localement, loin de la richesse Showdown | loin de la richesse Showdown |
| runtime bridge | réel et strict | n/a produit | très bon niveau de vérité |
| runtime write-back | réel mais étroit | n/a produit | ne pas sur-vendre |
| bootstrap truth | honnête mais curaté | n/a produit | bien distinguer bootstrap et golden slice |
| host / product truth | réel | n/a produit | golden slice = vérité battleable actuelle |

## Écarts structurels principaux vs Showdown

Écarts structurants dominants:

1. `battle_session.dart` reste trop central
2. le scheduler local existe mais reste trop petit pour des flows plus riches
3. les contracts requests / targeting / replacement restent trop serrés
4. les conditions moteur et les side conditions restent asymétriques
5. le runtime bridge est honnête, mais calibré pour un sous-ensemble strict

Écarts mécaniques dominants:

1. pas d'abilities
2. pas d'items
3. pas de targeting riche
4. pas de `forceSwitch` / `selfSwitch` génériques
5. pas de side conditions larges
6. pas de doubles

## Blockers classés

### Architecture

- centralisation excessive dans `battle_session.dart`

### Scheduling

- queue locale réelle mais pas encore assez expressive pour des flows plus riches

### Contracts

- requests / targeting / replacement trop serrés pour certaines mécaniques Showdown-like

### Runtime

- hard-fail “no bridgeable move left” honnête, plus explicite, et toujours volontairement bloquant

### Bootstrap

- les labels/support claims les plus trompeurs ont été réalignés en R1

### Documentation

- roadmap maître historique
- ancien plan battle engine
- ancien README runtime
- certains reports historiques
