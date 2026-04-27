# Audit de migration combat vers Pokemon SDK

Date: 2026-04-24

## 1. Objectif

Ce rapport décrit comment repartir de zero sur le systeme de combat actuel et
le remplacer par une adaptation Dart, en clean architecture, du systeme de
combat de Pokemon SDK.

Le perimetre volontaire de ce document est le combat. Les animations PSDK/RMXP
ont deja ete traitees cote runtime, donc elles ne sont abordees ici que comme
contrat de sortie du moteur : le nouveau moteur doit produire une timeline
assez riche pour que les animations existantes puissent se brancher proprement.

Decision cible :

- supprimer l'integration Pokemon Showdown comme source de verite combat ;
- ne plus faire passer les moves par des callbacks ou des champs Showdown ;
- utiliser Pokemon SDK comme reference de mecanique combat ;
- adapter en Dart idiomatique, testable et pur dans `packages/map_battle` ;
- garder `map_runtime` comme couche d'orchestration/visualisation, sans logique
  de regles ;
- garder `map_core` comme contrat de donnees, sans execution de combat ;
- remplacer les pipelines editor/runtime lies a Showdown par des importeurs
  Pokemon SDK / Studio.

## 2. Sources analysees

### 2.1 Pokemon SDK

Source principale :

- `pokemonsdk-development/scripts/5 Battle`

Inventaire du dossier battle :

| Dossier PSDK | Nombre de fichiers | Role |
| --- | ---: | --- |
| `01 Scene` | 32 | Orchestration scene, inputs, messages, phases UI |
| `02 Visual` | 72 | Visual battle, transitions, choix UI, sprites |
| `03 PokemonBattler` | 8 | Entite Pokemon mutable pendant le combat |
| `04 Logic` | 26 | Etat, handlers, RNG, battlers, phases de fin de tour |
| `05 Actions` | 10 | Actions ordonnees/executables |
| `06 Effects` | 409 | Effets de moves, statuts, talents, objets, meteo, terrain |
| `10 Move` | 293 | Base Move, procedure, degats, ciblage, definitions |
| `20 MoveAnimation` | 29 | Animations de moves, hors refonte moteur |
| `30 AI` | 28 | IA, heuristiques moves/switch/items/fuite |
| `99 Pokemon Script Project` | 2 | Patches d'integration RMXP |

Autres sources PSDK utiles :

- `pokemonsdk-development/scripts/3 Studio/2 Data/031 Move.rb`
- `pokemonsdk-development/scripts/3 Studio/2 Data/001 Ability.rb`
- `pokemonsdk-development/scripts/3 Studio/2 Data/021 Item.rb`
- `pokemonsdk-development/scripts/3 Studio/2 Data/041 Creature.rb`
- `pokemonsdk-development/scripts/3 Studio/2 Data/071 Type.rb`
- `pokémon_sdk_test_project/Data/Studio/moves`
- `pokémon_sdk_test_project/Data/Studio/abilities`
- `pokémon_sdk_test_project/Data/Studio/items`
- `pokémon_sdk_test_project/Data/Studio/types`
- `pokémon_sdk_test_project/Data/Studio/pokemon`

Point important : `scripts/5 Battle` porte surtout le comportement. Les
donnees concretes des moves, talents, objets, types et creatures viennent des
donnees Studio. Par exemple, un move Studio expose `battleEngineMethod`
(`s_basic`, `s_status`, `s_multi_hit`, etc.), et les scripts PSDK enregistrent
les classes de comportement via `Move.register(:s_xxx, Klass)`.

Pour une migration saine, il faut donc importer deux choses :

- les donnees Studio JSON comme catalogue canonique ;
- les comportements Ruby PSDK comme reference de port Dart.

### 2.2 Etat actuel Dart

Paquets directement concernes :

- `packages/map_battle`
- `packages/map_core`
- `packages/map_runtime`
- `packages/map_editor`
- `examples/playable_runtime_host`

Fichiers actuels du moteur battle :

- `packages/map_battle/lib/map_battle.dart`
- `packages/map_battle/lib/src/battle_action.dart`
- `packages/map_battle/lib/src/battle_condition_engine.dart`
- `packages/map_battle/lib/src/battle_condition_side_conditions.dart`
- `packages/map_battle/lib/src/battle_decision.dart`
- `packages/map_battle/lib/src/battle_field.dart`
- `packages/map_battle/lib/src/battle_move.dart`
- `packages/map_battle/lib/src/battle_opponent_policy.dart`
- `packages/map_battle/lib/src/battle_queue.dart`
- `packages/map_battle/lib/src/battle_resolution.dart`
- `packages/map_battle/lib/src/battle_rng.dart`
- `packages/map_battle/lib/src/battle_session.dart`
- `packages/map_battle/lib/src/battle_session_scheduler.dart`
- `packages/map_battle/lib/src/battle_setup.dart`
- `packages/map_battle/lib/src/battle_spikes.dart`
- `packages/map_battle/lib/src/battle_state.dart`
- `packages/map_battle/lib/src/battle_stats.dart`
- `packages/map_battle/lib/src/battle_status.dart`
- `packages/map_battle/lib/src/battle_stealth_rock.dart`
- `packages/map_battle/lib/src/battle_switch.dart`
- `packages/map_battle/lib/src/battle_topology.dart`
- `packages/map_battle/lib/src/battle_type_chart.dart`
- `packages/map_battle/lib/src/battle_typing.dart`
- `packages/map_battle/lib/src/battle_volatile.dart`

Diagnostic court : `map_battle` est aujourd'hui un moteur singles MVP enrichi
par petits lots. Il gere deja certains concepts utiles, mais sous forme de
cas bornes : statuts partiels, quelques volatiles, meteo reduite, hazards
dedies, PP, precision, critique minimal, switch minimal, capture simplifiee.
La forme n'est pas compatible avec une reprise 100% PSDK, car elle encode les
mecaniques comme extensions successives d'un monolithe, pas comme un systeme
generique handlers/effects/moves.

## 3. Ce que Pokemon SDK fait mieux pour notre besoin

### 3.1 Architecture PSDK

PSDK separe trois instances principales :

- `Battle::Scene` : orchestre la scene, les inputs, les messages et les phases ;
- `Battle::Logic` : porte l'etat de combat, les battlers, handlers, effects,
  RNGs, actions, switch requests et battle result ;
- `Battle::Visual` : gere les sprites, animations et surfaces visuelles.

Pour notre architecture Dart :

- `Battle::Scene` ne doit pas etre porte dans `map_battle`.
  Son equivalent reste `map_runtime`.
- `Battle::Visual` ne doit pas etre porte dans `map_battle`.
  Les animations existantes restent dans `map_runtime`.
- `Battle::Logic`, `PokemonBattler`, `Actions`, `Handlers`, `Effects`,
  `Move` et `AI` sont le coeur a porter dans `map_battle`.

### 3.2 Les piliers a recopier/adapter

Les piliers PSDK a reprendre sont :

- un battler de combat riche (`PFM::PokemonBattler`) distinct du Pokemon source ;
- une pile d'actions executable et comparable ;
- une vraie phase de tri d'actions ;
- un systeme de handlers pour les mutations majeures ;
- un systeme d'effets avec hooks ;
- une classe `Move` comportementale, pas seulement des donnees ;
- un registre de moves par `battleEngineMethod` ;
- une procedure standard de move ;
- une formule de degats extensible par hooks ;
- des RNGs separees ;
- des historiques de moves/damages/stats ;
- une IA par niveaux et heuristiques.

### 3.3 Le point cle : `EffectBase`

PSDK ne code pas `Protect`, `Burn`, `Rain`, `Choice Band`, `Prankster`,
`Stealth Rock`, etc. comme des exceptions eparpillees dans une methode
centrale. Il les expose via des hooks d'effet.

Les familles de hooks importantes :

- prevention et modification des stats ;
- pre/post item change ;
- prevention et pre/post ability change ;
- prevention et post status change ;
- prevention et post damage/death ;
- drain prevention/pre ;
- switch passthrough/prevention/event ;
- flee passthrough/prevention ;
- post action ;
- end turn ;
- weather/terrain prevention/post ;
- pre/post accuracy ;
- move prevention user/target/failure ;
- move type change ;
- move disabled check ;
- move priority change ;
- ability immunity ;
- transform event ;
- type multiplier overwrite ;
- base power multiplier ;
- attack/defense multipliers ;
- mod1/mod2/mod3 multipliers ;
- chance of hit multiplier ;
- specific procedure override.

C'est exactement le modele qui manque au moteur actuel. Le nouveau moteur doit
etre construit autour de ce bus de hooks typé.

## 4. Probleme de l'integration Showdown actuelle

Les traces Showdown actuelles ne sont pas seulement des commentaires.
Elles structurent encore les donnees et certains gates runtime.

### 4.1 `map_core`

Fichiers concernes :

- `packages/map_core/lib/src/models/pokemon_move.dart`
- `packages/map_core/lib/src/models/pokemon_move_effect.dart`
- `packages/map_core/lib/src/models/pokemon_move.freezed.dart`
- `packages/map_core/lib/src/models/pokemon_move.g.dart`
- `packages/map_core/test/pokemon_move_test.dart`

Problemes :

- `PokemonMoveTarget` reprend le vocabulaire Showdown.
- `PokemonMoveFlag` reprend des flags Showdown.
- `PokemonMoveSourceRefs` contient `showdownMoveId` et
  `showdownHooksPresent`.
- Les tests normalisent explicitement `source: 'showdown'`.
- Les `unsupportedReasons` stockent `showdown_callback:*`.

Action cible :

- remplacer la tracabilite Showdown par une tracabilite PSDK/Studio ;
- introduire `battleEngineMethod` comme champ central ;
- aligner les targets sur `battleEngineAimedTarget` PSDK ;
- aligner les flags sur les bools Studio (`isDirect`, `isCharge`,
  `isRecharge`, `isBlocable`, `isSnatchable`, etc.) ;
- conserver un modele serialisable, mais ne plus essayer de representer toute
  la mecanique en `PokemonMoveEffect`.

### 4.2 `map_editor`

Fichiers concernes :

- `packages/map_editor/lib/src/infrastructure/external/showdown_snapshot_source.dart`
- `packages/map_editor/lib/src/infrastructure/repositories/http_pokemon_external_source_repository.dart`
- `packages/map_editor/lib/src/application/ports/pokemon_external_source_repository.dart`
- `packages/map_editor/lib/src/application/services/showdown_move_catalog_converter.dart`
- `packages/map_editor/lib/src/application/services/showdown_pokemon_species_converter.dart`
- `packages/map_editor/lib/src/application/services/external_pokemon_catalog_normalizer.dart`
- `packages/map_editor/lib/src/application/services/pokeapi_pokemon_species_enricher.dart`
- `packages/map_editor/lib/src/application/use_cases/import_external_pokemon_use_cases.dart`
- `packages/map_editor/lib/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart`
- `packages/map_editor/lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart`
- `packages/map_editor/lib/src/application/use_cases/resolve_external_pokemon_batch_selection_use_case.dart`
- `packages/map_editor/lib/src/application/use_cases/search_external_pokemon_species_use_case.dart`
- `packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart`
- `packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart`
- `packages/map_editor/lib/src/ui/canvas/pokemon_catalogs_workspace/moves_catalog_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow_steps.dart`

Problemes :

- Le port externe expose `fetchShowdownPokedexSnapshot`,
  `fetchShowdownSpeciesPayload`, `fetchShowdownMovesSnapshot`.
- Le repository HTTP compose PokeAPI + Showdown.
- Le sync moves est explicitement `ShowdownMoveCatalogConverter`.
- Le seed embarque des moves "Showdown-backed".
- L'UI affiche "Sync depuis Showdown".
- Les tests de wiring et de use cases valident cette source.

Action cible :

- retirer `ShowdownSnapshotSource` ;
- creer une source/importeur Pokemon SDK Studio ;
- remplacer le sync moves par un sync/import Studio ;
- garder PokeAPI seulement si on l'assume pour media/meta hors combat ;
- si l'objectif est "zero Showdown" strict, remplacer aussi le converter
  species Showdown par un importer Studio creature ;
- renommer les labels UI vers "Import Pokemon SDK" ou "Sync depuis SDK".

### 4.3 `map_runtime`

Fichiers concernes :

- `packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart`
- `packages/map_runtime/lib/src/application/runtime_move_catalog_loader.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_move_visual_resolver.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_turn_animation_planner.dart`
- `packages/map_runtime/tool/phase_a_battle_coverage.dart`
- `packages/map_runtime/tool/phase_b_scaffold_pack_coverage.dart`

Problemes :

- `RuntimeBattleMoveBridge` est un gate qui refuse ou accepte un sous-ensemble
  de `PokemonMoveEffect`.
- Il contient des exceptions liees a `showdown_callback:*`.
- `BattleMoveVisualResolver` utilise
  `canonicalMove?.sourceRefs.showdownMoveId ?? move.id`.
- Le seed builder filtre les moves "non bridgeables", ce qui n'a plus de sens
  dans un moteur PSDK complet.

Action cible :

- supprimer le bridge Showdown/MVP ;
- creer un adapter runtime -> nouveau `BattleSetup` PSDK-like ;
- le moteur doit accepter un move par `moveId` + `battleEngineMethod`, pas via
  projection vers un `BattleMoveData` appauvri ;
- le resolver visuel doit utiliser un id SDK/Studio stable (`dbSymbol`,
  `sdkMoveId` ou `animationMoveId`), pas `showdownMoveId`.

### 4.4 `map_battle`

Fichiers concernes :

- `battle_move.dart` contient encore des commentaires "Showdown-like" et
  surtout un modele DTO trop petit.
- `battle_condition_engine.dart` contient un mini condition engine.
- `battle_session.dart` concentre trop de regles.
- `battle_session_scheduler.dart` trie les actions dans une logique locale
  qui ne couvre pas la richesse PSDK.
- `battle_stealth_rock.dart` et `battle_spikes.dart` sont des hazards dedies,
  alors que PSDK les modelise comme effects.

Action cible :

- ne pas etendre ce moteur ;
- le remplacer par un noyau PSDK-like.

## 5. Architecture Dart cible

### 5.1 Regle de package

`packages/map_battle` doit rester pur Dart, sans Flutter/Flame et sans import
`map_core`.

Pourquoi ne pas importer `map_core` dans `map_battle` :

- `map_core` est un contrat projet/editor/runtime ;
- `map_battle` doit pouvoir etre teste avec ses propres fixtures ;
- le runtime est la bonne couche pour adapter les donnees projet vers les
  seeds de combat ;
- cela conserve la frontiere actuelle du monorepo.

### 5.2 Structure proposee

Nouvelle structure recommandee :

```text
packages/map_battle/lib/src/
  domain/
    battle/
      battle_context.dart
      battle_state.dart
      battle_setup.dart
      battle_outcome.dart
      battle_timeline.dart
    battler/
      battle_battler.dart
      battle_battler_identity.dart
      battle_battler_stats.dart
      battle_battler_history.dart
      battle_battler_effects.dart
    action/
      battle_action.dart
      attack_action.dart
      item_action.dart
      switch_action.dart
      flee_action.dart
      mega_action.dart
      no_action.dart
    move/
      battle_move_instance.dart
      battle_move_data.dart
      battle_move_behavior.dart
      battle_move_registry.dart
      battle_move_targeting.dart
      battle_move_procedure.dart
      battle_damage_formula.dart
    effect/
      battle_effect.dart
      battle_effect_stack.dart
      battle_effect_scope.dart
      battle_effect_hooks.dart
    handler/
      stat_change_handler.dart
      item_change_handler.dart
      status_change_handler.dart
      damage_handler.dart
      switch_handler.dart
      end_turn_handler.dart
      weather_change_handler.dart
      flee_handler.dart
      catch_handler.dart
      ability_change_handler.dart
      battle_end_handler.dart
      field_terrain_change_handler.dart
      transform_handler.dart
      exp_handler.dart
    ai/
      battle_ai.dart
      battle_ai_level.dart
      move_heuristic.dart
      switch_heuristic.dart
    rng/
      battle_rng_streams.dart
  application/
    battle_engine.dart
    battle_turn_runner.dart
    battle_decision_service.dart
    battle_action_scheduler.dart
    battle_setup_factory.dart
  data/
    generated/
      generated_move_registry.dart
      generated_effect_registry.dart
```

Cette structure peut etre ajustee selon les conventions exactes du repo, mais
la separation doit rester :

- Domain : modeles, invariants, comportements purs ;
- Application : use cases de resolution ;
- Data/generated : registres generes depuis l'inventaire PSDK ;
- pas de presentation dans `map_battle`.

### 5.3 Forme d'execution recommandee

PSDK est tres mutable. Dart peut l'adapter sans copier la mutabilite dans
l'API publique.

Recommandation :

- API publique immutable : `BattleSession` ou `BattleEngineState` retourne un
  nouvel etat apres chaque decision ;
- interne de resolution mutable : `BattleContext` modifiable pendant un tour ;
- sortie : `BattleResolution` contenant `nextState`, `timeline`, `requests`,
  `outcome`, `rngSeeds`.

Cela permet de garder :

- tests faciles ;
- determinisme ;
- compatibilite runtime ;
- ergonomie PSDK pendant la resolution.

### 5.4 Timeline cible

Le moteur ne doit pas appeler `display_message_and_wait` ni lancer
d'animation. Il doit emettre des evenements.

Families d'evenements minimales :

- `BattleMessageEvent`
- `BattleActionStartedEvent`
- `BattleMoveDeclaredEvent`
- `BattleMoveFailedEvent`
- `BattleAccuracyCheckedEvent`
- `BattleMoveHitEvent`
- `BattleDamageAppliedEvent`
- `BattleCriticalHitEvent`
- `BattleTypeEffectivenessEvent`
- `BattleStatusAppliedEvent`
- `BattleStatStageChangedEvent`
- `BattleEffectStartedEvent`
- `BattleEffectTickedEvent`
- `BattleEffectEndedEvent`
- `BattleItemChangedEvent`
- `BattleAbilityChangedEvent`
- `BattleSwitchStartedEvent`
- `BattleSwitchCompletedEvent`
- `BattleFaintEvent`
- `BattleCaptureEvent`
- `BattleExpAwardedEvent`
- `BattleOutcomeEvent`

Le runtime pourra ensuite traduire ces evenements en messages FR, animations,
HUD tweens et transitions.

## 6. Mapping PSDK vers clean architecture

### 6.1 `01 Scene`

PSDK :

- `100 Scene.rb`
- `101 Scene Choice.rb`
- `102 Scene AI trigger.rb`
- `103 Scene Battle Phase.rb`
- `104 Scene Event.rb`
- `105 Safari.rb`
- `200 Message.rb`

Adaptation :

- ne pas porter dans `map_battle` ;
- reprendre seulement la notion de phases et de requests ;
- implementer les equivalents dans `map_runtime` :
  - afficher les choix ;
  - envoyer une decision au moteur ;
  - consommer la timeline ;
  - bloquer/debloquer les inputs.

### 6.2 `02 Visual`

Adaptation :

- ne pas porter dans `map_battle` ;
- les animations ayant deja ete traitees, conserver seulement le mapping
  `moveId -> animation` cote runtime ;
- supprimer la dependance actuelle a `showdownMoveId`.

### 6.3 `03 PokemonBattler`

PSDK :

- `001 PokemonBattler.rb`
- `002 Properties.rb`
- `003 Statistics.rb`
- `004 Grounded.rb`
- `005 Effects.rb`
- `100 MoveHistory.rb`
- `101 DamageHistory.rb`
- `102 StatsHistory.rb`

Adaptation Dart :

- `BattleBattler` doit remplacer le `BattleCombatant` actuel ;
- il doit porter :
  - identite stable source ;
  - bank, position, partyId, placeInParty ;
  - level, form, gender, speciesId ;
  - HP, status, status counters ;
  - stats basis et stages ;
  - typing dynamique jusqu'a 3 types ;
  - ability courante et ability originale ;
  - item courant, item consomme, item original ;
  - effects stack ;
  - moveset de `BattleMoveInstance` ;
  - histories move/damage/stat ;
  - turnCount, lastBattleTurn, lastSentTurn ;
  - flags transform, illusion, switching, shifted ;
  - KO count, sleep turns.

Le `BattleCombatant` actuel est trop petit. Il peut devenir une vue publique
ou etre remplace par `BattleBattlerSnapshot`.

### 6.4 `04 Logic`

PSDK :

- `100 Logic.rb`
- `101 Battler.rb`
- `102 Actions.rb`
- `103 Critical_hit.rb`
- `104 end of battle phase & switch choice.rb`
- `105 Handlers.rb`
- `106 Effects.rb`
- `400 MegaEvolve.rb`
- `0 Battle Info/001 Battle_Info.rb`
- `1 Handlers/*`

Adaptation Dart :

- `BattleContext` remplace `Battle::Logic` pendant la resolution ;
- `BattleSetup` devient plus proche de `BattleInfo` ;
- `BattleActionScheduler` remplace `Logic#sort_actions` ;
- `BattleTurnRunner` remplace `perform_next_action` + phases de fin ;
- `BattleHandlerContainer` expose tous les handlers ;
- `BattleEffectDispatcher` expose `eachEffects`.

RNGs a separer comme PSDK :

- `moveDamageRng`
- `moveCriticalRng`
- `moveAccuracyRng`
- `genericRng`

Le moteur actuel a deja un concept de RNG, mais la refonte doit explicitement
separer les streams pour retrouver le determinisme PSDK.

### 6.5 `04 Logic/1 Handlers`

Handlers PSDK a porter :

- `100 ChangeHandler.rb`
- `101 StatChangeHandler.rb`
- `102 ItemChangeHandler.rb`
- `103 StatusChangeHandler.rb`
- `104 DamageHandler.rb`
- `105 SwitchHandler.rb`
- `106 EndTurnHandler.rb`
- `107 WeatherChangeHandler.rb`
- `108 FleeHandler.rb`
- `109 CatchHandler.rb`
- `110 AbilityChangeHandler.rb`
- `111 BattleEndHandler.rb`
- `112 FTerrainChangeHandler.rb`
- `113 TransformHandler.rb`
- `200 ExpHandler.rb`

Adaptation :

- chaque handler devient un service pur du domaine battle ;
- chaque handler recoit `BattleContext` ;
- chaque mutation produit des events ;
- les preventions passent par les hooks d'effets ;
- les messages PSDK deviennent des `BattleMessageEvent` typés ou codes.

Priorite de port :

1. `DamageHandler`
2. `StatusChangeHandler`
3. `StatChangeHandler`
4. `SwitchHandler`
5. `EndTurnHandler`
6. `ItemChangeHandler`
7. `WeatherChangeHandler`
8. `FTerrainChangeHandler`
9. `FleeHandler`
10. `CatchHandler`
11. `AbilityChangeHandler`
12. `TransformHandler`
13. `ExpHandler`
14. `BattleEndHandler`

### 6.6 `05 Actions`

PSDK :

- `001 Actions.rb`
- `002 Attack.rb`
- `002 PreAttack.rb`
- `003 Mega.rb`
- `004 Item.rb`
- `005 Switch.rb`
- `006 Flee.rb`
- `007 HighPriorityItem.rb`
- `008 NoAction.rb`
- `009 Shift.rb`

Adaptation Dart :

- remplacer `BattleAction` actuel par une hierarchie proche PSDK ;
- chaque action a :
  - `actor`/`launcher` ;
  - `priorityBucket` ;
  - `compareTo` via scheduler ;
  - `execute(context)` ;
  - `isValid(context)`.

Actions cible :

- `AttackAction`
- `PreAttackAction`
- `MegaAction`
- `ItemAction`
- `SwitchAction`
- `FleeAction`
- `HighPriorityItemAction`
- `NoAction`
- `ShiftAction`
- `ForcedMoveAction`
- `ForcedReplacementAction`

Le tri actuel dans `battle_session_scheduler.dart` doit etre remplace par un
tri PSDK-like qui gere :

- item haute priorite ;
- mega avant item/switch/move selon PSDK ;
- switch ;
- pursuit ;
- shift ;
- priority de move ;
- stall/lagging tail/full incense ;
- Trick Room ;
- speed tie ;
- forced move.

### 6.7 `06 Effects`

PSDK :

- `001 EffectsHandler.rb`
- `100 EffectBase.rb`
- `200 PokemonTiedEffectBase.rb`
- `200 PositionTiedEffectBase.rb`
- `01 Mechanics/*`
- `02 Move Effects/*`
- `03 Status Effects/*`
- `04 Ability Effects/*`
- `05 Item Effects/*`
- `06 Weather Effects/*`
- `07 Field Terrain Effects/*`

Inventaire important :

- 409 fichiers effects ;
- 92 fichiers move effects ;
- 216 fichiers ability effects ;
- 62 fichiers item effects ;
- 6 status effects principaux ;
- weather et terrain comme effects.

Adaptation Dart :

- remplacer `BattleConditionEngine` par `BattleEffectStack` +
  `BattleEffectHooks`;
- chaque battler, bank/side, position/slot, field, terrain, weather peut porter
  une stack d'effets ;
- `BattleEffect` expose des hooks typés ;
- les effets sont petits et testables ;
- les effects generes/portes doivent etre organises par famille.

Le modele actuel avec `battle_status.dart`, `battle_volatile.dart`,
`battle_spikes.dart`, `battle_stealth_rock.dart`, `battle_field.dart` est a
retirer progressivement au profit de cette architecture.

### 6.8 `10 Move`

PSDK :

- `100 Move.rb`
- `101 Damage_Calc.rb`
- `102 Type.rb`
- `103 Type Processing.rb`
- `104 Chance of Hit.rb`
- `110 Target.rb`
- `120 Procedure.rb`
- `121 Specific Procedure.rb`
- `130 Move Prevention.rb`
- `1 Mechanics/*`
- `2 Definitions/*`

Inventaire :

- 293 fichiers move ;
- 272 fichiers de definitions ;
- registre `Move.register(:s_xxx, Klass)`.

Adaptation Dart :

- remplacer `BattleMove` DTO par :
  - `BattleMoveData` pour le catalogue ;
  - `BattleMoveInstance` pour PP/usage courant ;
  - `BattleMoveBehavior` pour la logique ;
  - `BattleMoveRegistry` pour `battleEngineMethod`.

Le champ cle des donnees Studio est `battleEngineMethod`. Le pipeline doit
mapper :

```text
Data/Studio/moves/*.json
  -> dbSymbol
  -> battleEngineMethod
  -> BattleMoveRegistry.resolve(method)
  -> BattleMoveBehavior.execute(...)
```

La procedure standard PSDK a porter :

1. verifier que le user peut utiliser le move ;
2. emettre le message d'utilisation ;
3. executer les hooks pre accuracy ;
4. resoudre les targets ;
5. faire le check accuracy ;
6. remapper user/targets si besoin ;
7. tester immunites et blocks ;
8. executer hooks post accuracy ;
9. produire l'evenement animation ;
10. appliquer degats ;
11. appliquer effets secondaires ;
12. appliquer statuts ;
13. appliquer stats ;
14. appliquer effect special ;
15. enregistrer histories.

La formule de degats PSDK a porter comme service :

- level ;
- base power reel ;
- atk/special atk selon categorie ;
- defense/special defense selon categorie ;
- stat stages ;
- critical ;
- mod1 ;
- mod2 ;
- random 85..100 ;
- STAB ;
- type multipliers type1/type2/type3 ;
- mod3 ;
- clamp avec substitute/target HP ;
- hooks d'effets a chaque etape.

### 6.9 `30 AI`

PSDK :

- `100 Base.rb`
- `101 MoveActionFor.rb`
- `102 MegaEvolve.rb`
- `103 Switch.rb`
- `104 Item.rb`
- `105 Flee.rb`
- `200 GenericAI.rb`
- `1 MoveHeuristic/*`

Adaptation Dart :

- remplacer `BattleOpponentPolicy` par `BattleAiPolicy`;
- conserver les niveaux PSDK :
  - wild ;
  - trainer lvl 1 a 7 ;
  - roaming wild ;
- porter les capabilities :
  - see power ;
  - see effectiveness ;
  - see move kind ;
  - can switch ;
  - can use item ;
  - can heal ;
  - can choose target ;
  - can flee ;
  - can read opponent movepool ;
  - can mega evolve.

L'IA doit rester dans `map_battle`, pure et deterministe. Le runtime ne choisit
pas les actions adverses.

## 7. Plan fichier par fichier

### 7.1 `packages/map_battle`

#### `packages/map_battle/lib/map_battle.dart`

Action :

- remplacer les exports actuels par les nouveaux barrels ;
- garder temporairement des aliases publics si necessaire pour une migration
  en plusieurs PR ;
- exporter les nouveaux contrats :
  - `BattleEngine`
  - `BattleSession`
  - `BattleSetup`
  - `BattleDecisionRequest`
  - `BattleTimeline`
  - `BattleOutcome`
  - `BattleAiPolicy`
  - `BattleMoveData`
  - `BattleMoveBehavior`
  - `BattleEffect`

#### `packages/map_battle/lib/src/battle_session.dart`

Etat actuel :

- monolithe de resolution ;
- contient choix joueur, fuite, capture, switch, moves, hit check, degats,
  stats, status/volatile/field, outcome ;
- depend d'un `BattleConditionEngine` et d'un scheduler adjacent.

Action :

- supprimer comme coeur moteur ;
- recreer une facade fine `BattleSession` si on veut proteger l'API runtime ;
- deplacer la logique vers :
  - `application/battle_engine.dart`
  - `application/battle_turn_runner.dart`
  - `domain/battle/battle_context.dart`
  - `domain/move/battle_move_procedure.dart`
  - `domain/move/battle_damage_formula.dart`
  - `domain/handler/*`.

Ce qui doit disparaitre :

- `_resolveMoveExecution` comme point central unique ;
- `_computeMoveDamage` local ;
- `_resolveHitCheck` local ;
- `_resolveEnemyAction` local ;
- capture auto success ;
- fuite auto success ;
- mini statuts hardcodes ;
- reliance directe sur dedicated hazards.

#### `packages/map_battle/lib/src/battle_session_scheduler.dart`

Etat actuel :

- gere la queue de continuation, switches, replacements, hazards, timeline ;
- trie fight/switch/items selon regles locales.

Action :

- remplacer par `BattleActionScheduler`;
- reprendre l'algorithme PSDK `Logic#sort_actions` et `Actions::<=>` ;
- separer :
  - construction des actions ;
  - refine/pre-attack ;
  - tri ;
  - execution action par action ;
  - post-action events ;
  - end-turn/switch/exp.

#### `packages/map_battle/lib/src/battle_action.dart`

Etat actuel :

- choix joueur et actions internes melanges ;
- action item limitee aux soins HP ;
- fuite/capture simplifiees.

Action :

- scinder :
  - `PlayerBattleCommand` ou `BattleDecision`;
  - `BattleAction` executable ;
- porter les actions PSDK ;
- remplacer `BattleActionBagHpHealItemUse` par `ItemAction` generique ;
- les potions deviennent des item effects, pas des actions dediees au moteur.

#### `packages/map_battle/lib/src/battle_decision.dart`

Etat actuel :

- modelise le request joueur singles ;
- expose fight/switch/run/capture/continue.

Action :

- garder le principe d'une request typée ;
- l'etendre a PSDK :
  - target selection ;
  - item selection ;
  - switch selection ;
  - forced action ;
  - no action ;
  - multi-bank/multi-position futur ;
- ne pas copier la scene PSDK, mais exposer assez d'informations pour que
  `map_runtime` affiche les menus.

#### `packages/map_battle/lib/src/battle_setup.dart`

Etat actuel :

- setup singles : player, enemy, reserves, trainer flag, allowCapture, field.

Action :

- remplacer par un setup plus proche `BattleInfo` :
  - banks ;
  - parties par bank/partyId ;
  - bags par bank/partyId ;
  - ai levels ;
  - trainer names/classes ;
  - vsType ;
  - max level ;
  - battle rules ;
  - allowExp ;
  - allowCapture ;
  - initial weather/terrain ;
  - RNG seeds separees.

#### `packages/map_battle/lib/src/battle_state.dart`

Etat actuel :

- etat actif/reserve singles ;
- outcome et currentTurn.

Action :

- remplacer par :
  - `BattleState`
  - `BattleBankState`
  - `BattlePartyState`
  - `BattleSlotState`
  - `BattleBattler`
  - `BattleFieldState`
  - `BattleEffectState`.

La notion `player` / `enemy` peut rester comme helper runtime, mais ne doit
plus etre la structure interne.

#### `packages/map_battle/lib/src/battle_topology.dart`

Etat actuel :

- topologie singles encore bornee.

Action :

- etendre vers le modele PSDK :
  - bank ;
  - position ;
  - partyId ;
  - vsType ;
  - adjacent foes/allies ;
  - all battlers ;
  - all alive battlers ;
  - active battlers by bank ;
  - battle slot refs.

#### `packages/map_battle/lib/src/battle_move.dart`

Etat actuel :

- `BattleMove` final DTO ;
- porte power/type/category/target/accuracy/pp/priority/crit/status/volatile/
  weather/hazards/stat stage riders ;
- il grossit en accumulant des champs.

Action :

- remplacer par :
  - `BattleMoveData` : donnees Studio portees ;
  - `BattleMoveInstance` : PP, consecutive use, used, histories ;
  - `BattleMoveBehavior` : methode de resolution ;
  - `BattleMoveRegistry` : mapping `battleEngineMethod`.

Ce qui doit disparaitre :

- `setsStealthRock`, `setsSpikes` comme champs directs ;
- `selfVolatileStatus` comme champ direct ;
- `weatherEffect`/`pseudoWeatherEffect` directs ;
- `majorStatusEffect` direct ;
- tout champ dedie a une mecanique particuliere quand un effect/behavior peut
  l'exprimer.

#### `packages/map_battle/lib/src/battle_condition_engine.dart`

Etat actuel :

- mini condition engine pour status, volatile, field, hazards ;
- concentre beaucoup de regles transverses.

Action :

- supprimer ;
- remplacer par :
  - `BattleEffectDispatcher`
  - handlers PSDK ;
  - effects par famille.

Les regles actuelles doivent etre deportees :

- paralysis action gate -> `StatusEffectParalysis`;
- burn damage multiplier -> `StatusEffectBurn`;
- poison/toxic residual -> `StatusEffectPoison/Toxic`;
- protect -> `MoveEffectProtect`;
- recharge -> move behavior/effect ;
- charge -> `TwoTurnBase`/effect ;
- weather residual/multiplier -> weather effects ;
- hazards -> position/side effects.

#### `packages/map_battle/lib/src/battle_condition_side_conditions.dart`

Action :

- supprimer ;
- side conditions deviennent des effects attaches a une bank/position/side.

#### `packages/map_battle/lib/src/battle_status.dart`

Etat actuel :

- statuts majeurs partiels : par, brn, psn, tox ;
- events dedies.

Action :

- remplacer par effects PSDK :
  - `StatusBase`
  - `Poison`
  - `Paralysis`
  - `Burn`
  - `Asleep`
  - `Frozen`
  - `Toxic`
  - confusion/flinch comme move effects/volatile selon PSDK.

Les events publics restent, mais doivent etre produits par `StatusChangeHandler`
et les effects, pas par un mini engine.

#### `packages/map_battle/lib/src/battle_volatile.dart`

Etat actuel :

- protect, recharge, pending charge.

Action :

- supprimer comme modele central ;
- remplacer par `BattleEffectStack` ;
- `Protect`, `Recharge`, `TwoTurn`, `OutOfReach`, `ForceNextMove`,
  `Substitute`, `Attract`, etc. deviennent effects.

#### `packages/map_battle/lib/src/battle_field.dart`

Etat actuel :

- rain, sandstorm, trickRoom uniquement.

Action :

- remplacer par effects field/weather/terrain :
  - weather : rain, sunny, sandstorm, hail, fog, hardrain, hardsun,
    strong_winds, snow ;
  - field terrain : electric, grassy, misty, psychic ;
  - pseudo/room : trick room, magic room, wonder room, gravity, etc.

#### `packages/map_battle/lib/src/battle_stealth_rock.dart`

Action :

- supprimer le fichier dedie ;
- porter PSDK `06 Effects/02 Move Effects/001 StealthRock.rb` ;
- `Stealth Rock` devient un position/side tied effect ;
- les events d'entree sont produits par `SwitchHandler` + effect hook.

#### `packages/map_battle/lib/src/battle_spikes.dart`

Action :

- supprimer le fichier dedie ;
- porter PSDK `Spikes` et `ToxicSpikes` comme effects ;
- gerer layers, grounded checks et poison via handlers.

#### `packages/map_battle/lib/src/battle_switch.dart`

Etat actuel :

- events de switch/replacement.

Action :

- garder une sortie eventuelle equivalente ;
- deplacer la logique dans `SwitchHandler` ;
- supporter :
  - switch volontaire ;
  - switch force ;
  - switch after KO ;
  - switch prevention/passthrough ;
  - reset states on switch ;
  - Baton Pass ;
  - U-Turn/Volt Switch ;
  - Pursuit ;
  - entry hazards.

#### `packages/map_battle/lib/src/battle_queue.dart`

Etat actuel :

- queue locale de continuation/replacement.

Action :

- supprimer ou reduire ;
- remplacer par action stack PSDK-like + pending requests ;
- les continuations de tour doivent etre gerees par effects/actions forcees.

#### `packages/map_battle/lib/src/battle_resolution.dart`

Etat actuel :

- buckets d'evenements et timeline.

Action :

- garder le concept de timeline ;
- le transformer en contrat central du moteur ;
- remplacer les buckets par une timeline riche et typée ;
- conserver des vues derivees si les tests/runtime en ont besoin.

#### `packages/map_battle/lib/src/battle_rng.dart`

Action :

- conserver l'idee ;
- l'etendre en `BattleRngStreams` :
  - moveDamage ;
  - moveCritical ;
  - moveAccuracy ;
  - generic ;
- exposer les seeds en sortie pour replay.

#### `packages/map_battle/lib/src/battle_stats.dart`

Action :

- conserver et etendre ;
- ajouter :
  - stages PSDK : atk, dfe, spd, ats, dfs, acc, eva ;
  - stat histories ;
  - modifiers de stat stage ;
  - bases et computed stats ;
  - special cases crit ignore stat drops/boosts.

#### `packages/map_battle/lib/src/battle_typing.dart`

Action :

- conserver et etendre ;
- supporter type1/type2/type3 ;
- supporter changement de type par effects ;
- supporter type immunity overwrite ;
- supporter grounded/flying/out-of-reach interactions.

#### `packages/map_battle/lib/src/battle_type_chart.dart`

Action :

- verifier la chart actuelle ;
- l'adapter au systeme PSDK `Type Processing` ;
- exposer un resolver injectable/testable ;
- supporter hooks `on_single_type_multiplier_overwrite`.

#### `packages/map_battle/lib/src/battle_opponent_policy.dart`

Etat actuel :

- policy adversaire minimale.

Action :

- remplacer par `BattleAiPolicy` PSDK-like ;
- porter `30 AI` ;
- l'IA choisit des `BattleAction`, pas seulement un move index.

### 7.2 Tests `packages/map_battle/test`

Tests actuels a reecrire :

- `battle_condition_engine_test.dart`
- `battle_decision_request_test.dart`
- `battle_field_test.dart`
- `battle_flow_integration_test.dart`
- `battle_move_effects_test.dart`
- `battle_opponent_policy_test.dart`
- `battle_queue_test.dart`
- `battle_rng_test.dart`
- `battle_session_flow_test.dart`
- `battle_session_test.dart`
- `battle_spikes_test.dart`
- `battle_state_topology_test.dart`
- `battle_stealth_rock_test.dart`
- `battle_switch_test.dart`
- `battle_volatiles_test.dart`

Nouvelle repartition recommandee :

- `battle_engine_smoke_test.dart`
- `battle_action_scheduler_test.dart`
- `battle_move_procedure_test.dart`
- `battle_damage_formula_test.dart`
- `battle_targeting_test.dart`
- `battle_stat_change_handler_test.dart`
- `battle_status_change_handler_test.dart`
- `battle_damage_handler_test.dart`
- `battle_switch_handler_test.dart`
- `battle_end_turn_handler_test.dart`
- `battle_effect_dispatcher_test.dart`
- `battle_move_registry_test.dart`
- `battle_ai_policy_test.dart`
- `psdk_tackle_parity_test.dart`
- `psdk_thunder_wave_parity_test.dart`
- `psdk_protect_parity_test.dart`
- `psdk_stealth_rock_parity_test.dart`
- `psdk_hyper_beam_parity_test.dart`
- `psdk_weather_parity_test.dart`

### 7.3 `packages/map_core`

#### `packages/map_core/lib/src/models/pokemon_move.dart`

Action :

- supprimer `PokemonMoveSourceRefs(showdownMoveId, showdownHooksPresent)`;
- introduire par exemple :
  - `PokemonMoveSourceRefs.psdkStudioMoveId`
  - `PokemonMoveSourceRefs.psdkDbSymbol`
  - `PokemonMoveSourceRefs.psdkBattleEngineMethod`
  - `PokemonMoveSourceRefs.psdkScriptClass`
  - `PokemonMoveSourceRefs.psdkAnimationId` si necessaire cote runtime ;
- remplacer `source: 'showdown'` par `source: 'pokemon_sdk_studio'` ou
  `source: 'psdk'`;
- remplacer `PokemonMoveTarget` par la taxonomie Studio
  `battleEngineAimedTarget`;
- ajouter les champs Studio manquants :
  - `battleEngineMethod`
  - `effectChance`
  - `battleStageMod`
  - `moveStatus`
  - tous les flags bool Studio utiles.

#### `packages/map_core/lib/src/models/pokemon_move_effect.dart`

Action :

- ne plus faire de ce fichier la source de verite comportementale ;
- soit le reduire a des hints serialisables pour l'editeur ;
- soit le remplacer par des payloads PSDK Studio :
  - `PokemonMoveBattleStageMod`
  - `PokemonMoveStatus`
  - `PokemonMoveFlags`
  - `PokemonMoveBattleEngineMethod`.

Important : la logique ne doit plus etre derivee d'un union `PokemonMoveEffect`
inspire Showdown. Elle doit venir du `BattleMoveBehavior` resolu par
`battleEngineMethod`.

#### Generated files

Fichiers :

- `packages/map_core/lib/src/models/pokemon_move.freezed.dart`
- `packages/map_core/lib/src/models/pokemon_move.g.dart`
- `packages/map_core/lib/src/models/pokemon_move_effect.freezed.dart`
- `packages/map_core/lib/src/models/pokemon_move_effect.g.dart`

Action :

- regenerer uniquement apres modification des modeles ;
- commande :
  - `cd packages/map_core && dart run build_runner build --delete-conflicting-outputs`

#### `packages/map_core/test/pokemon_move_test.dart`

Action :

- supprimer les assertions Showdown ;
- ajouter les assertions PSDK :
  - normalization `dbSymbol`;
  - normalization `battleEngineMethod`;
  - flags Studio ;
  - move statuses ;
  - battle stage mods ;
  - source refs PSDK.

### 7.4 `packages/map_editor`

#### `showdown_snapshot_source.dart`

Action :

- supprimer ;
- remplacer par une source Pokemon SDK Studio :
  - lecture d'un dossier local `Data/Studio` ;
  - lecture de `moves/*.json`, `abilities/*.json`, `items/*.json`,
    `types/*.json`, `pokemon/*.json`, `trainers/*.json` selon besoin ;
  - option future : importer depuis un zip/export PSDK.

Nom possible :

- `pokemon_sdk_studio_source.dart`
- `pokemon_sdk_project_source.dart`

#### `pokemon_external_source_repository.dart`

Action :

- supprimer :
  - `fetchShowdownPokedexSnapshot`
  - `fetchShowdownSpeciesPayload`
  - `fetchShowdownMovesSnapshot`
- ajouter :
  - `fetchPokemonSdkStudioMoves`
  - `fetchPokemonSdkStudioSpecies`
  - `fetchPokemonSdkStudioTypes`
  - `fetchPokemonSdkStudioAbilities`
  - `fetchPokemonSdkStudioItems`
- garder PokeAPI uniquement pour les medias si decide.

#### `http_pokemon_external_source_repository.dart`

Action :

- retirer `ShowdownSnapshotSource`;
- si la source PSDK est locale, ce repository ne doit plus etre "HTTP only" ;
- creer plutot :
  - `CompositePokemonExternalSourceRepository`
  - `FilePokemonSdkStudioSource`
  - `PokeApiLiveSource` pour media/meta optionnelle.

#### `showdown_move_catalog_converter.dart`

Action :

- supprimer ;
- remplacer par :
  - `pokemon_sdk_move_catalog_converter.dart`
  - entree : JSON Studio move ;
  - sortie : `PokemonMove` canonique PSDK ;
  - conversion de `battleEngineMethod`, `battleEngineAimedTarget`,
    `battleStageMod`, `moveStatus`, flags bool.

#### `showdown_pokemon_species_converter.dart`

Action :

- si zero Showdown strict : supprimer ;
- remplacer par `pokemon_sdk_species_converter.dart` lisant les creatures
  Studio ;
- garder `PokeApiPokemonSpeciesEnricher` seulement si son role est non-combat
  et explicitement accepte.

#### `external_pokemon_catalog_normalizer.dart`

Action :

- supprimer `normalizeShowdownCatalog`;
- remplacer par `normalizePokemonSdkStudioCatalog`;
- ajuster messages, meta sourcePriority et tests.

#### `sync_pokemon_moves_catalog_use_case.dart`

Action :

- remplacer `SyncExternalPokemonMovesCatalogUseCase`;
- le nouveau use case importe/synchronise depuis PSDK Studio ;
- retirer les warnings `showdown_callback:*`;
- le merge se base sur `dbSymbol`/`id` PSDK.

#### `import_external_pokemon_use_cases.dart`

Action :

- remplacer le coeur "PokeAPI pour identity puis Showdown pour core species" ;
- utiliser PSDK Studio comme source structuree principale ;
- PokeAPI devient optionnel pour enrichissement media/description si souhaite ;
- ajuster dry-run, conflict merge et warnings.

#### `pokemon_moves_bootstrap_seed.dart`

Action :

- supprimer `_showdownSeedMove`;
- remplacer par un seed PSDK minimal ou par un export genere depuis
  `Data/Studio/moves`;
- `source` doit devenir `pokemon_sdk_studio`;
- `sourceRefs` doivent pointer vers PSDK.

#### Providers et UI

Fichiers :

- `packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart`
- `packages/map_editor/lib/src/ui/canvas/pokemon_catalogs_workspace/moves_catalog_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow_steps.dart`

Action :

- renommer providers Showdown ;
- retirer le bouton "Sync depuis Showdown" ;
- exposer "Importer Pokemon SDK" ;
- ajouter une selection de dossier PSDK Studio si necessaire.

#### Tests `map_editor`

Tests a supprimer/renommer :

- `showdown_move_catalog_converter_test.dart`
- `showdown_pokemon_species_converter_test.dart`
- `showdown_snapshot_source_test.dart`

Tests a adapter :

- `http_pokemon_external_source_repository_test.dart`
- `provider_wiring_test.dart`
- `sync_pokemon_moves_catalog_use_case_test.dart`
- `pokemon_moves_catalog_workspace_ui_test.dart`
- `import_external_pokemon_use_cases_test.dart`
- `resolve_external_pokemon_batch_selection_use_case_test.dart`
- `search_external_pokemon_species_use_case_test.dart`
- `external_pokemon_catalog_normalizer_test.dart`
- `initialize_pokemon_project_storage_use_case_test.dart`

Nouveaux tests :

- `pokemon_sdk_studio_source_test.dart`
- `pokemon_sdk_move_catalog_converter_test.dart`
- `pokemon_sdk_species_converter_test.dart`
- `sync_pokemon_sdk_moves_catalog_use_case_test.dart`
- `import_pokemon_sdk_project_use_case_test.dart`

### 7.5 `packages/map_runtime`

#### `runtime_battle_move_bridge.dart`

Action :

- supprimer ;
- remplacer par `runtime_battle_catalog_adapter.dart` ou
  `runtime_battle_setup_adapter.dart`;
- ne plus filtrer "bridgeable/non bridgeable" ;
- construire des seeds battle complets :
  - move id ;
  - dbSymbol ;
  - battleEngineMethod ;
  - PP ;
  - data Studio ;
  - ability/item/type ;
  - stats.

#### `runtime_battle_combatant_seed_builder.dart`

Action :

- retirer `resolveBattleMovesForSeed` base sur `RuntimeBattleMoveBridge`;
- passer a :
  - `RuntimeBattleBattlerSeedBuilder`;
  - selection moves depuis learnset ;
  - lookup `PokemonMove` PSDK ;
  - creation `BattleBattlerSeed`.

Le builder doit aussi fournir :

- ability courante ;
- held item ;
- gender/form ;
- types ;
- base stats ;
- current HP/status ;
- line-up identity ;
- battle move instances.

#### `runtime_battle_setup_mapper.dart`

Action :

- mapper vers le nouveau `BattleSetup/BattleInfo`;
- injecter parties et reserves comme banks/partyIds ;
- fournir les flags wild/trainer/capture ;
- fournir ai levels trainer ;
- fournir bag snapshot si les items battle doivent etre utilises.

#### `runtime_battle_outcome_apply.dart`

Action :

- adapter au nouvel outcome ;
- ecrire les PV/status/items/exp si le nouveau moteur les produit ;
- la capture doit utiliser le resultat du `CatchHandler`, pas une capture
  auto-success ;
- les rewards/exp doivent venir de `BattleEndHandler`/`ExpHandler` ou etre
  explicitement hors scope par phase.

#### `runtime_battle_bag_hp_heal_item_apply.dart`

Action :

- retirer la logique item HP dediee du runtime si les items battle passent dans
  le moteur ;
- le runtime verifie disponibilite du bag et envoie une `ItemAction`;
- le moteur resout l'effet item.

#### `battle_move_visual_resolver.dart`

Action :

- remplacer `canonicalMove?.sourceRefs.showdownMoveId ?? move.id`;
- utiliser :
  - `canonicalMove.sourceRefs.psdkDbSymbol`;
  - ou `BattleMoveData.dbSymbol`;
  - ou un champ `animationMoveId`;
- garder les catalogues RMXP/SDK deja importes.

#### `battle_turn_animation_planner.dart`

Action :

- consommer la nouvelle timeline riche ;
- ne plus reconstruire le sens a partir de buckets pauvres ;
- ajouter les steps pour :
  - move declared ;
  - failure ;
  - miss ;
  - immune ;
  - status ;
  - stat stage ;
  - item ;
  - ability ;
  - switch ;
  - catch bounces ;
  - exp/reward si affiche.

#### Overlay/menus

Fichiers probables :

- `battle_command_menu_model.dart`
- `battle_command_panel_component.dart`
- `battle_overlay_component.dart`
- `battle_bag_menu_model.dart`
- `battle_party_menu_model.dart`
- `battle_medicine_target_menu_model.dart`
- `playable_map_game.dart`

Action :

- passer de `allowedChoices` actuels a `BattleDecisionRequest` riche ;
- afficher targets si le move le demande ;
- afficher items battle utilisables ;
- afficher switch force/volontaire ;
- gerer forced action/continue depuis effects.

#### Tests `map_runtime`

Tests a adapter :

- `runtime_battle_move_bridge_test.dart` devient obsolete ;
- `runtime_battle_combatant_seed_builder_test.dart` ;
- `runtime_battle_setup_mapper_test.dart` ;
- `runtime_battle_outcome_apply_test.dart` ;
- `battle_move_visual_resolver_test.dart` ;
- `battle_turn_animation_planner_test.dart` ;
- `battle_overlay_component_test.dart` ;
- `wild_battle_end_to_end_flow_test.dart` ;
- `phase_a_golden_battle_slice_smoke_test.dart`.

Nouveaux tests :

- `runtime_battle_psdk_setup_adapter_test.dart`
- `runtime_battle_psdk_timeline_planner_test.dart`
- `runtime_battle_psdk_capture_outcome_test.dart`
- `runtime_battle_psdk_switch_flow_test.dart`

### 7.6 `examples/playable_runtime_host`

Fichier/fixture :

- `examples/playable_runtime_host/golden_battle_slice/data/pokemon/catalogs/moves.json`
- tests golden runtime.

Action :

- remplacer le catalogue moves par un catalogue PSDK ;
- verifier learnsets ;
- verifier que les moves choisis ont `battleEngineMethod`;
- mettre a jour golden smoke.

### 7.7 Docs

Fichiers existants :

- `docs/combat/battle-canonical-state-v3.1.md`
- `docs/combat/battle-roadmap-canonical-v3.1.md`

Action :

- ne pas patcher legerement ces docs ;
- creer une nouvelle version canonique :
  - `docs/combat/battle-canonical-state-v4-psdk.md`
  - `docs/combat/battle-roadmap-v4-psdk.md`
- y documenter :
  - nouveau moteur ;
  - suppression Showdown ;
  - architecture handlers/effects/moves ;
  - timeline ;
  - phases de migration.

Les anciens rapports `reports/*` contiennent beaucoup de references Showdown.
Ils ne doivent pas etre nettoyes retrospectivement sauf demande explicite.

## 8. Generateurs et importeurs a creer

### 8.1 Import Studio JSON

Creer un outil ou service qui lit :

- `Data/Studio/moves/*.json`
- `Data/Studio/abilities/*.json`
- `Data/Studio/items/*.json`
- `Data/Studio/types/*.json`
- `Data/Studio/pokemon/*.json`

Sorties :

- catalogues projet `map_core` ;
- fixtures de tests `map_battle` ;
- eventuellement registres generes.

### 8.2 Extracteur de registre moves PSDK

Creer un outil qui scanne :

- `pokemonsdk-development/scripts/5 Battle/10 Move/1 Mechanics`
- `pokemonsdk-development/scripts/5 Battle/10 Move/2 Definitions`

Objectif :

- detecter `Move.register(:s_xxx, Klass)`;
- produire une table :
  - `battleEngineMethod`;
  - fichier Ruby source ;
  - classe Ruby ;
  - statut de port Dart ;
  - tests parity associes.

Sortie possible :

- `packages/map_battle/lib/src/data/generated/generated_move_registry.dart`
- `reports/psdk-move-porting-matrix.md`

### 8.3 Extracteur effects PSDK

Creer une matrice effects :

- source Ruby ;
- type d'effet ;
- hooks overrides ;
- port Dart ;
- tests.

Cela permet de porter les 409 effects par tranche sans perdre le cap 100%.

## 9. Phases de migration recommandees

### Phase 0 - Verrouiller les contrats et baselines

But :

- figer ce qu'on supprime ;
- eviter de melanger animations deja faites et moteur ;
- garder une base de verification.

Actions :

- creer docs v4 PSDK ;
- lister tous les fichiers Showdown a supprimer ;
- lister tous les catalogues moves actuels ;
- choisir source PSDK Studio locale ;
- definir `BattleTimeline` cible ;
- definir format `BattleSetup` cible.

Validation :

- aucune modification moteur large encore ;
- rapport + schema + tests de non-regression existants.

### Phase 1 - Remplacer la source de donnees moves

But :

- ne plus importer de moves depuis Showdown.

Actions :

- creer `PokemonSdkStudioSource`;
- creer `PokemonSdkMoveCatalogConverter`;
- remplacer `ShowdownMoveCatalogConverter`;
- remplacer seed moves ;
- regenerer `map_core` si modele change.

Validation :

- `cd packages/map_core && dart test`
- `cd packages/map_editor && flutter test` cible sur converters/use cases.

### Phase 2 - Nouveau squelette `map_battle` PSDK-like

But :

- poser l'architecture sans encore porter 409 effects.

Actions :

- creer `BattleEngine`, `BattleContext`, `BattleBattler`, `BattleAction`,
  `BattleEffect`, `BattleMoveBehavior`;
- garder temporairement un facade si runtime en depend ;
- ecrire tests pour Tackle, Vine Whip, Thunder Wave.

Validation :

- tests unitaires du nouveau noyau ;
- pas de runtime cutover complet encore.

### Phase 3 - Battlers, topology, RNG

But :

- remplacer le modele player/enemy plat par bank/position/party.

Actions :

- porter `PokemonBattler` ;
- porter stats/stages ;
- porter histories ;
- porter effect stacks ;
- porter RNG streams.

Validation :

- tests topology ;
- tests stats ;
- replay deterministe avec seeds.

### Phase 4 - Actions et scheduler

But :

- remplacer le scheduler actuel.

Actions :

- porter actions PSDK ;
- porter tri ;
- porter pre-attack ;
- porter post-action events ;
- porter forced moves/actions.

Validation :

- priority ;
- quick attack ;
- switch before attack ;
- trick room ;
- recharge/forced continue ;
- speed tie deterministe.

### Phase 5 - Handlers fondamentaux

But :

- sortir les mutations du monolithe.

Actions :

- `DamageHandler`;
- `StatusChangeHandler`;
- `StatChangeHandler`;
- `SwitchHandler`;
- `EndTurnHandler`.

Validation :

- damage ;
- burn/paralysis/poison/toxic ;
- stat boosts/debuffs ;
- switch resets ;
- end-turn residuals.

### Phase 6 - Move procedure et damage formula

But :

- porter le pipeline PSDK `Move`.

Actions :

- `BattleMoveProcedure`;
- `BattleDamageFormula`;
- target resolver ;
- accuracy resolver ;
- type processing ;
- critical resolver ;
- histories.

Validation :

- Tackle/Vine Whip parity ;
- miss/immunity/protect ;
- critical ;
- STAB/type effectiveness ;
- random damage 85..100.

### Phase 7 - Effects system

But :

- remplacer status/volatile/hazard dedies.

Actions :

- `BattleEffectHooks`;
- `BattleEffectStack`;
- port effects prioritaires :
  - Protect ;
  - Substitute ;
  - Leech Seed ;
  - Stealth Rock ;
  - Spikes ;
  - Toxic Spikes ;
  - Weather ;
  - Terrain ;
  - Recharge ;
  - Two-turn/out-of-reach ;
  - Force next move ;
  - Attract/confusion/flinch.

Validation :

- tests par effect ;
- tests interactions switch/end-turn.

### Phase 8 - Move registry et definitions

But :

- brancher les moves par `battleEngineMethod`.

Actions :

- generer la matrice `Move.register`;
- porter les mechanics `1 Mechanics`;
- porter definitions par tranches ;
- chaque tranche ajoute tests.

Priorite tranche :

1. `s_basic`, `s_status`, `s_stat`, `s_self_stat`, `s_self_status`
2. heal/drain/recoil
3. multi-hit/two-hit
4. two-turn/recharge
5. hazards
6. weather/terrain
7. switch/force switch
8. copy/redirect/magic coat/snatch
9. custom power/stat based
10. moves rares.

### Phase 9 - Talents et objets

But :

- porter les 216 ability effects et 62 item effects par familles.

Actions :

- ability base ;
- item base ;
- berries ;
- choice items ;
- type boosting/resisting items ;
- weather/terrain setting abilities ;
- immunities ;
- stat modifiers ;
- damage modifiers.

Validation :

- tests hooks ;
- tests ability/item trigger order.

### Phase 10 - Capture, fuite, EXP, battle end

But :

- remplacer les simplifications actuelles.

Actions :

- porter `FleeHandler`;
- porter `CatchHandler`;
- porter `ExpHandler`;
- porter `BattleEndHandler` de facon compatible runtime ;
- definir ce qui est moteur vs runtime pour argent, Pokedex, quest flags.

Validation :

- capture formula ;
- flee formula ;
- trainer battle block flee/catch ;
- exp distribution ;
- outcome write-back.

### Phase 11 - Cutover runtime/editor

But :

- retirer l'ancien moteur du chemin produit.

Actions :

- remplacer setup mapper ;
- remplacer move bridge ;
- adapter overlay ;
- adapter planner animation ;
- mettre a jour examples/golden slice ;
- retirer tests Showdown ;
- retirer docs v3 comme source canonique.

Validation :

- `cd packages/map_battle && dart test`
- `cd packages/map_runtime && flutter test`
- `cd packages/map_editor && flutter test`
- `cd examples/playable_runtime_host && flutter test`
- smoke golden battle slice.

### Phase 12 - Suppression finale Showdown

But :

- zero dependance Showdown dans le code actif.

Actions :

- supprimer source/converters/tests Showdown ;
- supprimer champs `showdown*` generes ;
- supprimer labels UI ;
- remplacer fixtures ;
- `rg -n "showdown|Showdown|Pokemon Showdown|showdownMoveId|showdownHooksPresent|showdown_callback"` doit ne retourner que d'anciens rapports ou une note historique explicitement hors code.

## 10. Risques et decisions a prendre

### 10.1 Les scripts seuls ne suffisent pas

Le dossier `5 Battle` ne suffit pas a creer le catalogue complet. Il faut aussi
les donnees Studio, car les moves pointent vers un `battleEngineMethod`.

Decision :

- utiliser `Data/Studio` comme source de donnees ;
- utiliser `scripts/5 Battle` comme source de comportements.

### 10.2 Port 100% ne veut pas dire big bang non teste

Le cap est 100% PSDK, mais il faut le livrer par tranches testees. Porter 272
move definitions, 409 effects, 216 abilities et 62 item effects en une seule
PR serait trop fragile.

Decision :

- architecture complete des le debut ;
- couverture behaviorale par tranches ;
- aucun fallback Showdown pendant la migration.

### 10.3 Ruby mutable vs Dart clean

PSDK mute beaucoup d'objets et appelle la scene pour afficher. En Dart, il faut
adapter :

- pas de `scene.display_message_and_wait` dans le moteur ;
- pas de globals Ruby ;
- pas de UI dans les handlers ;
- pas de `Random` global ;
- pas de `data_move` global non injecte.

Decision :

- `BattleContext` mutable interne ;
- `BattleTimeline` pour les sorties ;
- catalogues injectes ;
- RNG streams explicites.

### 10.4 Items/abilities explosent le scope

Beaucoup de comportements PSDK importants sont dans `06 Effects/04 Ability
Effects` et `06 Effects/05 Item Effects`, pas seulement dans `10 Move`.

Decision :

- ne pas pretendre que "toutes les attaques" sont supportees si ability/item
  hooks ne sont pas branches ;
- porter d'abord les hooks generiques ;
- porter ensuite les effects par familles.

## 11. Definition of Done de la refonte

La refonte peut etre consideree terminee quand :

- `map_battle` ne depend plus d'un DTO Showdown-like ;
- `map_runtime` n'a plus `RuntimeBattleMoveBridge`;
- `map_core` n'a plus `showdownMoveId` / `showdownHooksPresent`;
- `map_editor` n'a plus de source/converter Showdown ;
- les moves viennent de PSDK Studio ;
- les behaviors viennent du registre PSDK portee en Dart ;
- le moteur produit une timeline riche ;
- les animations runtime consomment cette timeline via ids PSDK ;
- les tests PSDK parity couvrent les familles majeures ;
- `rg` ne trouve plus Showdown dans le code actif.

Commandes de verification finales :

```bash
cd packages/map_core && dart test
cd packages/map_battle && dart test
cd packages/map_runtime && flutter test
cd packages/map_editor && flutter test
cd examples/playable_runtime_host && flutter test
rg -n "showdown|Showdown|Pokemon Showdown|showdownMoveId|showdownHooksPresent|showdown_callback" packages examples docs
```

## 12. Conclusion

La bonne strategie n'est pas d'etendre le moteur actuel. Il faut le remplacer.

Le moteur actuel est utile comme preuve d'integration runtime, mais sa forme
MVP accumule des cas dedies. Pokemon SDK propose le bon modele pour aller plus
loin : battler riche, actions triees, handlers, effects, hooks, moves
comportementaux, data Studio et AI.

La migration doit donc suivre cette ligne :

1. couper Showdown comme source de donnees ;
2. importer les donnees PSDK Studio ;
3. reconstruire `map_battle` autour de Logic/Actions/Handlers/Effects/Move ;
4. adapter runtime/editor autour du nouveau contrat ;
5. supprimer les anciennes surfaces Showdown et les bridges MVP.

Le resultat attendu est un moteur Dart propre, pur, testable, inspire de PSDK
dans sa structure, mais adapte aux frontieres du monorepo.
