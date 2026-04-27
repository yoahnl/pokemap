# PSDK Fight Engine Parity Master Report

Date: 2026-04-25

## Resume executif

Ce rapport definit la trajectoire de remplacement du systeme de combat actuel
par un moteur aligne sur Pokemon SDK, avec un focus prioritaire sur la parite
des attaques.

Nom de chantier propose: **PSDK Fight Engine**.

Pourquoi ce nom:

- "Fight" reprend l'intention claire du dossier `5 Battle` sans se limiter aux
  moves.
- "Engine" rappelle que la parite ne vient pas seulement des attaques, mais du
  moteur qui les execute: actions, handlers, effects, battlers, field, weather,
  AI, items, abilities, histories.
- "PSDK" rend explicite que Pokemon SDK devient la source de verite.

Etat actuel:

- Le lane Dart PSDK existe et il est sain: clean architecture, registry par
  `battleEngineMethod`, RNG separe, timeline, CLI, tests.
- La parite stricte reste basse:
  - moves PSDK: 20 `ported`, 24 `partial`, 286 `missing` sur 330 methods;
  - effects PSDK: 0 `ported`, 1 `partial`, 481 `missing` sur 482 classes;
  - tests `packages/map_battle`: 410 tests verts;
  - `dart analyze` dans `packages/map_battle`: vert.
- Beaucoup d'attaques ne peuvent pas fonctionner parce que les dependances
  PSDK qui les rendent executables n'existent pas encore en Dart: effects,
  handlers, targeting, field/weather, statuses, abilities, items, action queue,
  histories.

Conclusion:

Il ne faut pas continuer a porter seulement des `s_*` un par un. La suite doit
porter les **infrastructures PSDK** avant les gros lots de moves. Sinon on va
accumuler des comportements "partial" impossibles a promouvoir en `ported`.

## Sources auditees

### Source PSDK

Racine fournie:

- `pokemonsdk-development/scripts`

Focus:

- `pokemonsdk-development/scripts/5 Battle`

Inventaire `5 Battle`:

| Dossier PSDK | Fichiers | Role |
| --- | ---: | --- |
| `01 Scene` | 32 | UI battle, choix joueur, messages |
| `02 Visual` | 72 | animations, transitions, sprites battle |
| `03 PokemonBattler` | 8 | battler de combat, grounded, effects, histories |
| `04 Logic` | 26 | logique centrale, actions, handlers |
| `05 Actions` | 10 | Attack, Switch, Item, Flee, Mega, Shift |
| `06 Effects` | 409 | effects moves/status/abilities/items/weather/terrain |
| `10 Move` | 293 | procedure des moves et definitions `s_*` |
| `20 MoveAnimation` | 29 | mapping/chargement animations |
| `30 AI` | 28 | AI et heuristiques |
| `99 Pokemon Script Project` | 2 | integration projet |
| Total | 909 | systeme battle complet |

### Source Dart actuelle

Focus:

- `packages/map_battle`
- `packages/map_core/lib/src/models/pokemon_move.dart`
- `packages/map_editor` import/export PSDK + reste Showdown
- `packages/map_runtime` bridge combat/runtime

Inventaire `packages/map_battle`:

| Zone Dart | Fichiers | Role |
| --- | ---: | --- |
| `lib/src` total | 82 | legacy + clean lane |
| `lib/src/psdk` | 13 | lane PSDK |
| `lib/src/domain` | 41 | clean domain battle/move/rng/timeline |
| `lib/src/application` | 3 | facade clean engine |
| `test` | 43 | tests legacy + PSDK |
| `test/psdk_move_families` | 10 | tests moves PSDK |
| `tool` | 2 | extracteurs matrix moves/effects |

## Metriques de parite

### Moves PSDK

Source:

- `reports/psdk-move-porting-matrix.md`

Etat:

| Status | Count | Interpretation |
| --- | ---: | --- |
| `ported` | 20 | comportement local considere aligne pour le scope annonce |
| `partial` | 24 | executable mais dependances PSDK manquantes |
| `missing` | 286 | non executable dans le lane PSDK Dart |
| Total | 330 | methods `s_*` enregistrees dans PSDK |

Scores:

- Alignement strict moves: `20 / 330 = 6.1%`.
- Couverture executable moves: `(20 + 24) / 330 = 13.3%`.
- Score pondere moves (`ported = 1`, `partial = 0.5`):
  `(20 + 24 * 0.5) / 330 = 9.7%`.

### Effects PSDK

Source:

- `reports/psdk-effect-porting-matrix.md`

Etat:

| Status | Count | Interpretation |
| --- | ---: | --- |
| `ported` | 0 | aucun effect PSDK complet |
| `partial` | 1 | `Protect` represente comme id temporaire |
| `missing` | 481 | effects non portes |
| Total | 482 | classes d'effets extraites |

Score pondere effects:

- `(0 + 1 * 0.5) / 482 = 0.1%`.

### Score global honnete

Le score global n'est pas une moyenne simple. Les moves dependent massivement
des effects/handlers. Un move `ported` localement peut rester faux en combat
reel si ability/item/status/field ne passe pas par les hooks PSDK.

Evaluation actuelle:

| Axe | Score estime | Raison |
| --- | ---: | --- |
| Infrastructure clean PSDK | 35-40% | engine, registry, timeline, RNG, CLI, tests existent |
| Parite moves stricte | 6.1% | 20 methods sur 330 |
| Moves executables au moins partiellement | 13.3% | 44 methods sur 330 |
| Effects PSDK | ~0.1% | systeme d'effets absent |
| Moteur complet PSDK | 10-12% | base saine, mais handlers/effects manquent |

## Source de verite PSDK par systeme

### `03 PokemonBattler`

Fichiers importants:

- `03 PokemonBattler/001 PokemonBattler.rb`
- `03 PokemonBattler/002 Properties.rb`
- `03 PokemonBattler/003 Statistics.rb`
- `03 PokemonBattler/004 Grounded.rb`
- `03 PokemonBattler/005 Effects.rb`
- `03 PokemonBattler/100 MoveHistory.rb`
- `03 PokemonBattler/101 DamageHistory.rb`
- `03 PokemonBattler/102 StatsHistory.rb`

Ce que PSDK fournit:

- Battler riche, derive du Pokemon original.
- Copie/retour des proprietes battle.
- `turn_count`, `last_battle_turn`, `last_sent_turn`.
- `last_hit_by_move`.
- `type3`, transform, illusion.
- `battle_item`, `item_consumed`, `consumed_item`.
- `ko_count`, `sleep_turns`.
- `switching`, `has_just_shifted`.
- Histories:
  - move history;
  - successful move history;
  - damage history;
  - stat history.
- `grounded?` avec effets, items, abilities:
  - Gravity;
  - Iron Ball;
  - Smack Down;
  - Ingrain;
  - Air Balloon;
  - Flying type;
  - Levitate.
- `status_effect`, `ability_effect`, `item_effect`.

Etat Dart:

- `PsdkBattleCombatant` contient deja HP, stats, types, moves, effects ids,
  major status, poids, move history partielle.
- Il manque:
  - ability id effectif;
  - held item id et item state;
  - grounded model;
  - damage history;
  - stat history;
  - transform/illusion;
  - battle turns/last sent;
  - sleep counter;
  - consumed item state;
  - flags switching/shift/pre-attack;
  - forme/type3/temp types.

### `04 Logic`

Fichiers importants:

- `04 Logic/100 Logic.rb`
- `04 Logic/101 Battler.rb`
- `04 Logic/102 Actions.rb`
- `04 Logic/103 Critical_hit.rb`
- `04 Logic/104 end of battle phase & switch choice.rb`
- `04 Logic/105 Handlers.rb`
- `04 Logic/106 Effects.rb`
- `04 Logic/400 MegaEvolve.rb`
- `04 Logic/1 Handlers/*.rb`

Ce que PSDK fournit:

- Etat global de combat.
- Liste des actions courantes.
- `turn_actions`.
- `battle_result`.
- RNG separes.
- Bags par bank.
- Switch requests.
- Evolve requests.
- Mega helper.
- Gestion centralisee de:
  - action order;
  - handlers;
  - effects;
  - end turn;
  - battle end;
  - switch/exp;
  - flee/catch.

Etat Dart:

- `BattleEngine` + `BattleTurnRunner` couvrent un tour singles minimal.
- Action order: priority + speed basique.
- Pas de vrai `Actions::Base` polymorphique.
- Pas de high priority item / Quick Claw / Quick Draw / Stall / Lagging Tail /
  Trick Room / Pursuit switch interaction.
- Pas de battle phase switch/exp PSDK.
- Handlers PSDK absents comme objets first-class.

### `05 Actions`

Fichiers importants:

- `05 Actions/001 Actions.rb`
- `05 Actions/002 Attack.rb`
- `05 Actions/002 PreAttack.rb`
- `05 Actions/003 Mega.rb`
- `05 Actions/004 Item.rb`
- `05 Actions/005 Switch.rb`
- `05 Actions/006 Flee.rb`
- `05 Actions/007 HighPriorityItem.rb`
- `05 Actions/008 NoAction.rb`
- `05 Actions/009 Shift.rb`

Ce que PSDK fournit:

- Actions comparables/sortables.
- Attack avec:
  - priority;
  - pursuit enabled;
  - ignore speed;
  - target fallback;
  - dancer sub-launchers;
  - mycelium might ordering.
- PreAttack pour moves a charge/preparation.
- Switch, Item, Flee, Mega, Shift.

Etat Dart:

- `BattleDecision.fight` seulement pour le lane PSDK propre.
- Le legacy a des choix switch/items, mais ce n'est pas la structure PSDK.
- Pas d'action queue PSDK complete.

### `06 Effects`

Fichiers importants:

- `06 Effects/001 EffectsHandler.rb`
- `06 Effects/01 Mechanics/*.rb`
- `06 Effects/02 Move Effects/*.rb`
- `06 Effects/03 Status Effects/*.rb`
- `06 Effects/04 Ability Effects/*.rb`
- `06 Effects/05 Item Effects/*.rb`
- `06 Effects/06 Weather Effects/*.rb`
- `06 Effects/07 Field Terrain Effects/*.rb`

Ce que PSDK fournit:

- `EffectsHandler` avec:
  - add;
  - replace;
  - delete;
  - get/get_all;
  - update counters;
  - dead effect cleanup;
  - `on_delete`.
- Effets move-tied:
  - Protect;
  - Substitute;
  - Taunt;
  - Encore;
  - Bind;
  - Leech Seed;
  - Future Sight;
  - Light Screen/Reflect;
  - Spikes/Stealth Rock;
  - Trick Room;
  - Weather/Terrain support, etc.
- Status effects:
  - Burn;
  - Poison;
  - Toxic;
  - Paralysis;
  - Sleep;
  - Freeze.
- Ability effects:
  - weather setting;
  - terrain setting;
  - prevention hooks;
  - damage hooks;
  - stat hooks;
  - type hooks;
  - switch hooks.
- Item effects:
  - berries;
  - choice items;
  - damage/type/stat modifiers;
  - duration extenders;
  - Air Balloon;
  - held item prevention/consumption.
- Weather and terrain effects with counters and callbacks.

Etat Dart:

- `PsdkBattleEffectStack` est une liste d'ids, pas un vrai systeme d'objets.
- `Protect` existe comme id temporaire.
- Aucune classe d'effet PSDK complete n'est portee.
- Les partials actuels resteront partials tant que ce bloc n'existe pas.

### `10 Move`

Fichiers importants:

- `10 Move/120 Procedure.rb`
- `10 Move/1 Mechanics/100 Basic.rb`
- `10 Move/1 Mechanics/101 Self.rb`
- `10 Move/1 Mechanics/102 Status Stat.rb`
- `10 Move/1 Mechanics/103 TwoHit MultiHit.rb`
- `10 Move/1 Mechanics/110 TwoTurnBase.rb`
- `10 Move/1 Mechanics/130 Pledge.rb`
- `10 Move/2 Definitions/*.rb`

Ce que PSDK fournit:

- Procedure complete:
  - `move_usable_by_user`;
  - usage message;
  - pre-accuracy effects;
  - target resolution/remap;
  - accuracy;
  - immunity;
  - target blocking;
  - post-accuracy effects;
  - animation;
  - damage;
  - effect chance;
  - status;
  - stat changes;
  - local effect;
  - histories.
- 330 `battleEngineMethod` `s_*` enregistrees.

Etat Dart:

- Procedure minimalement alignee:
  - user fainted;
  - PP;
  - target;
  - accuracy;
  - type immunity;
  - Protect;
  - animation cue;
  - damage;
  - statuses/stages simples;
  - history tentative/success.
- Manque:
  - effects pre/post accuracy;
  - redirection;
  - snatch/magic coat/magic bounce;
  - multi-target procedure;
  - full target taxonomy;
  - bypass accuracy complet;
  - damage prevention hooks;
  - drain/heal/change handlers;
  - local move-specific effects persistants.

### `30 AI`

Fichiers importants:

- `30 AI/*.rb`
- `30 AI/1 MoveHeuristic/*.rb`

Etat Dart:

- Le legacy a `BattleOpponentPolicy`.
- Ce n'est pas l'AI PSDK.
- La vraie parite AI doit venir apres un moteur PSDK plus complet.

## Etat Dart actuel par fichier: garder, changer, retirer

### Barrels et entree publique

| Fichier | Action | Raison |
| --- | --- | --- |
| `packages/map_battle/lib/map_battle.dart` | Modifier progressivement | Exporte encore legacy + clean. Il doit rester compatible pendant la migration, puis exposer le Fight Engine PSDK comme API principale. |
| `packages/map_battle/lib/src/psdk/psdk_battle.dart` | Garder et etendre | Barrel propre du lane PSDK. Ajouter effects, handlers, actions, AI quand portes. |

### Legacy root `packages/map_battle/lib/src/*.dart`

Ces fichiers constituent l'ancien moteur/contrat. Ils ne doivent pas etre
brutalement supprimes tant que `map_runtime` depend encore d'eux, mais ils ne
doivent plus etre la source de verite.

| Fichier | Action cible | Detail |
| --- | --- | --- |
| `battle_action.dart` | Retirer apres remplacement | Remplacer par actions PSDK: Fight, Switch, Item, Flee, Mega, Shift, PreAttack, NoAction. |
| `battle_condition_engine.dart` | Retirer/remplacer | Remplacer par effect hooks PSDK. Les conditions ne doivent plus vivre dans un mini-moteur parallele. |
| `battle_condition_side_conditions.dart` | Migrer puis retirer | Side conditions doivent devenir effects side/position PSDK: Spikes, ToxicSpikes, StealthRock, StickyWeb, Screens, Tailwind. |
| `battle_decision.dart` | Adapter ou deprecier | Garder comme facade UI temporaire, mapper vers actions PSDK. |
| `battle_field.dart` | Retirer | Remplace par field/weather/terrain PSDK. Ne pas melanger avec `PsdkBattleFieldState`. |
| `battle_move.dart` | Retirer comme source moteur | Remplacer par `PokemonMove` import PSDK + `PsdkBattleMoveData` runtime. |
| `battle_opponent_policy.dart` | Garder temporairement | IA produit actuelle. Remplacer plus tard par AI PSDK ou adapter AI PSDK. |
| `battle_queue.dart` | Retirer/remplacer | Remplacer par action queue PSDK avec priority/speed/items/abilities. |
| `battle_resolution.dart` | Migrer vers timeline PSDK | Garder seulement si runtime UI a besoin d'un DTO compatible. |
| `battle_rng.dart` | Retirer apres migration | Remplace par `BattleRngStreams` separe. |
| `battle_session.dart` | Garder comme facade legacy temporaire | Doit devenir wrapper du Fight Engine PSDK, puis disparaitre. |
| `battle_session_scheduler.dart` | Remplacer | La resolution de turn doit etre celle du PSDK action/handler pipeline. |
| `battle_setup.dart` | Adapter | Doit construire `BattleEngineSetup`/`PsdkBattleSetup` complet. |
| `battle_spikes.dart` | Migrer | A convertir en effect PSDK side/position `Spikes`. |
| `battle_state.dart` | Adapter puis retirer | Ancien state a remplacer par `PsdkBattleState` riche. |
| `battle_stats.dart` | Fusionner avec PSDK stats | Garder les helpers utiles, mais stages/modifiers doivent passer par handlers/effects PSDK. |
| `battle_status.dart` | Migrer | Remplacer par status effects PSDK. |
| `battle_stealth_rock.dart` | Migrer | A convertir en effect PSDK side/position `StealthRock`. |
| `battle_switch.dart` | Remplacer | Utiliser `Actions::Switch` + `SwitchHandler` PSDK. |
| `battle_topology.dart` | Adapter | PSDK doit supporter banks/positions/doubles et pas seulement legacy topology. |
| `battle_type_chart.dart` | Garder comme data util | Peut rester si tables compatibles. Doit etre appele par damage/type processor PSDK. |
| `battle_typing.dart` | Adapter | Typage temporaire/type3/transform/ability item doivent venir du battler/effects PSDK. |
| `battle_volatile.dart` | Migrer | Volatiles doivent devenir effects PSDK typed, pas enum legacy. |

### Clean application/domain `packages/map_battle/lib/src/application`

| Fichier | Action cible | Detail |
| --- | --- | --- |
| `application/battle_engine.dart` | Garder et etendre | Bonne facade. Ajouter decisions item/switch/flee/capture/mega quand actions PSDK existent. |
| `application/battle_session_facade.dart` | Garder temporairement | Sert de pont. Doit progressivement wrapper uniquement Fight Engine PSDK. |
| `application/battle_turn_runner.dart` | Refactor majeur | A remplacer par pipeline ActionQueue + Handlers + Effects. Garder les tests de rollback/outcome. |

### Clean domain battle

| Fichier | Action cible | Detail |
| --- | --- | --- |
| `domain/battle/battle_bank.dart` | Etendre | Banks/positions doivent couvrir singles/doubles/shift/switch requests. |
| `domain/battle/battle_battler.dart` | Revoir | Contient ability/held item mais le lane PSDK battler ne les hydrate pas encore. Unifier. |
| `domain/battle/battle_context.dart` | Etendre | Doit orchestrer handlers/effects, pas seulement state/rng/outcome. |
| `domain/battle/battle_outcome.dart` | Etendre | Ajouter flee/capture/draw/forced end si necessaire. |
| `domain/battle/battle_party.dart` | Etendre | Necessaire pour switch, exp, faint process, trainer/wild. |
| `domain/battle/battle_setup.dart` | Etendre | Ajouter battle type, banks, parties, field/weather, bags, AI config. |
| `domain/battle/battle_slot.dart` | Garder/etendre | Base utile. Ajouter target groups/multi-target helpers. |
| `domain/battle/battle_stats.dart` | Etendre | Accuracy/evasion, critical modifiers, stat handler integration. |
| `domain/battle/battle_topology.dart` | Etendre | Doubles/multi battle, allies, opposing banks. |

### Clean domain move

| Fichier | Action cible | Detail |
| --- | --- | --- |
| `domain/move/battle_accuracy_resolver.dart` | Refactor PSDK | Ajouter bypass hooks: No Guard, Lock-On, weather, accuracy/evasion, ability/item effects. |
| `domain/move/battle_move_behavior.dart` | Garder | Interface saine. Peut rester facade des move classes portees. |
| `domain/move/battle_move_critical_resolver.dart` | Etendre | Ajouter effects/items/abilities crit modifiers. |
| `domain/move/battle_move_damage_calculator.dart` | Refactor handler-driven | Garder formule, mais ajouter damage hooks: modifiers, weather, burn, screens, abilities, items, critical stage ignore. |
| `domain/move/battle_move_data.dart` | Etendre | Ajouter flags PSDK, target full taxonomy, ailment/status info si necessaire. |
| `domain/move/battle_move_execution.dart` | Etendre | Doit transporter action, actual targets, local context, pre/post hooks. |
| `domain/move/battle_move_instance.dart` | Garder/etendre | PP/state par battler. Ajouter forced next move, disable, encore, mimic/sketch. |
| `domain/move/battle_move_prevention.dart` | Etendre | Ajouter reasons PSDK et hooks user/target/weather/terrain/status. |
| `domain/move/battle_move_procedure.dart` | Refactor majeur | Doit suivre `10 Move/120 Procedure.rb`: precheck, pre accuracy effects, remap, immunity, post accuracy, animation, damage, status, stats, effect, histories. |
| `domain/move/battle_move_registry.dart` | Garder | Registry par `battleEngineMethod` est le bon pivot. |
| `domain/move/battle_move_secondary_effect_resolver.dart` | Remplacer par handlers | Aujourd'hui applique statuses/stages directement. A convertir vers StatusChangeHandler/StatChangeHandler. |
| `domain/move/battle_move_type_processor.dart` | Etendre | Ajouter type-changing hooks, immunities ability/item/effect, terrain/weather interactions. |
| `domain/move/battle_target_resolver.dart` | Refactor majeur | Ajouter toute la taxonomie PSDK Studio: user, adjacent foe, all foes, all battlers, ally, side, field, random, etc. |

### Move behaviors actuels

Tous ces fichiers sont utiles, mais ils ne doivent pas grossir en un monolithe.
Chaque famille doit rester limitee et delegate aux handlers PSDK.

| Fichier | Action cible |
| --- | --- |
| `behaviors/basic_damage_specialization_move_behavior.dart` | Garder; promouvoir `s_false_swipe` apres Substitute. |
| `behaviors/battle_move_behavior_support.dart` | Refactor apres procedure PSDK; eviter d'y accumuler toute la logique. |
| `behaviors/custom_stat_source_move_behavior.dart` | Garder; promouvoir apres abilities/items/effects modifiers. |
| `behaviors/direct_hp_move_behavior.dart` | Garder; completer faint process pour `Final Gambit`. |
| `behaviors/fixed_damage_move_behavior.dart` | Garder. |
| `behaviors/mind_blown_move_behavior.dart` | Garder; promouvoir apres Damp/Wonder Guard/ability gates. |
| `behaviors/multi_hit_move_behavior.dart` | Garder; promouvoir apres Skill Link, Loaded Dice, Population Bomb accuracy override. |
| `behaviors/no_effect_move_behavior.dart` | Garder; event messages PSDK restent a traiter cote timeline/messages. |
| `behaviors/recoil_move_behavior.dart` | Garder; promouvoir apres Rock Head/Reckless/Parental Bond/item callbacks. |
| `behaviors/self_destruct_move_behavior.dart` | Garder; promouvoir apres Damp/grounded. |
| `behaviors/terrain_power_move_behavior.dart` | Garder; ajouter autres terrain-powered seulement quand dependencies existent. |
| `behaviors/variable_power_move_behavior.dart` | Garder; migrer les variants history/weather/terrain vers fichiers separes. |
| `behaviors/weight_power_move_behavior.dart` | Garder; promouvoir apres Minimize/effects/modified weight abilities. |

### PSDK domain actuel

| Fichier | Action cible | Detail |
| --- | --- | --- |
| `psdk/domain/psdk_battle_combatant.dart` | Refactor majeur | Ajouter ability, item, histories, grounded, counters, transform/illusion, battle flags. |
| `psdk/domain/psdk_battle_field.dart` | Etendre | Ajouter setters/clear/tick/counters/effects refs. |
| `psdk/domain/psdk_battle_move.dart` | Etendre | Ajouter target taxonomy complete, flags, pre-attack, dance, recoil metadata si necessaire. |
| `psdk/domain/psdk_battle_outcome.dart` | Etendre | Ajouter flee/capture/draw si runtime le demande. |
| `psdk/domain/psdk_battle_rng.dart` | Garder | Bon alignement avec PSDK RNG separes. |
| `psdk/domain/psdk_battle_setup.dart` | Etendre | Ajouter parties, banks, bags, field initial, weather initial, battle info. |
| `psdk/domain/psdk_battle_slots.dart` | Etendre | Generaliser au multi-bank/multi-position. |
| `psdk/domain/psdk_battle_state.dart` | Etendre | Ajouter parties, actions, effects, weather, field terrain, pending requests. |
| `psdk/domain/psdk_battle_timeline.dart` | Etendre | Ajouter events PSDK: messages, effect start/end, weather/terrain change, item/ability trigger, heal/drain, switch/faint/catch. |
| `psdk/application/psdk_battle_engine.dart` | Garder | Facade PSDK utile pour CLI/tests. |
| `psdk/application/psdk_battle_move_behavior.dart` | Garder | Bridge registry propre. Ajouter resolvers de prevention/effects si necessaire. |
| `psdk/cli/psdk_battle_cli.dart` | Garder et enrichir | Doit devenir outil de parity smoke: scenarios par famille. |

### Data/tools

| Fichier | Action cible |
| --- | --- |
| `data/static_basic_move_registry.dart` | Remplacer progressivement par registry composee/generable. Garder tant que simple. |
| `data/generated/psdk_move_registry_manifest.dart` | Garder regenere. Doit devenir gate de parite. |
| `tool/extract_psdk_move_registry.dart` | Garder; enrichir avec families/dependencies. |
| `tool/extract_psdk_effect_matrix.dart` | Garder; enrichir avec hook taxonomy et ordre de portage. |

## Fichiers hors `map_battle` a changer/retirer

### `packages/map_core`

| Fichier | Action cible | Detail |
| --- | --- | --- |
| `lib/src/models/pokemon_move.dart` | Modifier | Retirer la taxonomie Showdown comme source principale. Garder migration tolerante seulement si necessaire. PSDK refs doivent devenir source officielle. |
| `lib/src/models/pokemon_move.freezed.dart` | Regenerer | Apres modification du modele source. |
| `lib/src/models/pokemon_move.g.dart` | Regenerer | Apres modification du modele source. |
| `lib/src/models/pokemon_move_accuracy.dart` | Verifier | Accuracy doit accepter les cas PSDK: bypass sentinel, accuracy/evasion, No Guard, weather. |
| `lib/src/models/pokemon_move_effect.dart` | Refactor | Le modele ne doit plus etre Showdown-like. Preferer PSDK effect refs + import data. |
| `test/pokemon_move_test.dart` | Recrire | Remplacer assertions Showdown par PSDK refs et migration legacy explicite. |

### `packages/map_editor`

| Fichier | Action cible | Detail |
| --- | --- | --- |
| `lib/src/application/services/pokemon_sdk_move_catalog_converter.dart` | Garder/etendre | Doit devenir source principale des moves. |
| `lib/src/application/services/pokemon_sdk_species_converter.dart` | Garder/etendre | Doit remplacer le besoin species Showdown strict. |
| `lib/src/infrastructure/external/pokemon_sdk_studio_source.dart` | Garder/etendre | Source PSDK officielle. |
| `lib/src/infrastructure/external/pokemon_sdk_studio_payload.dart` | Garder/etendre | Ajouter champs manquants si PSDK Studio expose plus de data utile. |
| `lib/src/application/use_cases/sync_pokemon_sdk_moves_catalog_use_case.dart` | Garder/etendre | Doit devenir le use case principal de sync moves. |
| `lib/src/application/services/showdown_move_catalog_converter.dart` | Supprimer apres migration | Ne doit plus alimenter le projet combat. |
| `lib/src/application/services/showdown_pokemon_species_converter.dart` | Supprimer ou isoler legacy import | Remplacer par PSDK/PokeAPI selon decision data. |
| `lib/src/infrastructure/external/showdown_snapshot_source.dart` | Supprimer apres migration | Source externe non PSDK. |
| `lib/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart` | Remplacer | Aujourd'hui source bulk Showdown. Doit deleguer vers PSDK sync ou etre renomme legacy. |
| `lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart` | Refaire | Seed "Showdown-backed" a remplacer par seed PSDK minimal. |
| `lib/src/app/providers/pokedex/pokedex_providers.dart` | Modifier | Retirer `showdownSnapshotSourceProvider` du chemin principal. |
| `lib/src/ui/canvas/pokemon_catalogs_workspace/moves_catalog_workspace.dart` | Modifier | Remplacer "Sync depuis Showdown" par PSDK Studio. |
| Tests Showdown | Supprimer/recrire | Remplacer par tests PSDK Studio converter/source/use cases. |

### `packages/map_runtime`

| Fichier | Action cible | Detail |
| --- | --- | --- |
| `lib/src/application/runtime_battle_move_bridge.dart` | Refactor majeur | Ne plus filtrer selon reasons Showdown. Mapper PokemonMove PSDK vers `PsdkBattleMoveData`. |
| `lib/src/application/runtime_battle_combatant_seed_builder.dart` | Etendre | Hydrater ability, item, status, weight, types, moves PSDK complets. |
| `lib/src/application/runtime_battle_setup_mapper.dart` | Etendre | Construire `PsdkBattleSetup` riche: parties, bags, field/weather, trainer/wild. |
| `lib/src/presentation/flame/battle_move_visual_resolver.dart` | Modifier | Ne plus fallback sur `showdownMoveId`; utiliser PSDK animation id/dbSymbol. |
| Tests runtime battle bridge | Recrire | Les cas `showdown_callback:*` doivent devenir limites PSDK explicites. |

## Pourquoi les attaques ne fonctionnent pas encore toutes

Beaucoup de moves PSDK sont de petites classes Ruby qui semblent simples, mais
elles s'appuient sur des services communs:

- `DamageHandler`;
- `StatusChangeHandler`;
- `StatChangeHandler`;
- `ItemChangeHandler`;
- `SwitchHandler`;
- `WeatherChangeHandler`;
- `FTerrainChangeHandler`;
- `EndTurnHandler`;
- `EffectsHandler`;
- `PokemonBattler#grounded?`;
- histories;
- ability/item/status/effect hooks.

Porter uniquement la classe move Dart sans ces services donne un comportement
partiel ou faux.

Exemples:

| Move family | Pourquoi bloque |
| --- | --- |
| `s_weather` | demande WeatherChangeHandler, duration items, prevention hooks |
| `s_terrain` | demande FTerrainChangeHandler, field terrain effects, terrain extender |
| `s_weather_ball` | type/power dynamiques + Air Lock/Cloud Nine |
| `s_rising_voltage` | grounded + Electric Terrain |
| `s_expanding_force` | Psychic Terrain + multi-target doubles |
| `s_grassy_glide` | priorite dynamique |
| `s_false_swipe` | Substitute |
| `s_multi_hit` | Skill Link / Loaded Dice / accuracy variants |
| `s_low_kick` / `s_heavy_slam` | Minimize / weight modifiers / abilities |
| `s_recoil` | Rock Head / Reckless / Parental Bond / item hooks |
| `s_explosion` / `s_mind_blown` | Damp / ability gates |
| `s_hex` | Comatose |
| `s_final_gambit` | faint process et double KO |
| `s_protect` | success-rate decay, variants, protection families |

## Architecture cible PSDK Fight Engine

### Modules Dart a creer

Proposition de nouvelle arborescence dans `packages/map_battle/lib/src/domain`:

```text
domain/
  action/
    battle_action.dart
    battle_action_queue.dart
    battle_action_ordering.dart
    battle_action_decision_mapper.dart
  battler/
    battle_combatant_state.dart
    battle_combatant_history.dart
    battle_grounding_resolver.dart
    battle_transform_state.dart
  effect/
    battle_effect.dart
    battle_effect_stack.dart
    battle_effect_scope.dart
    battle_effect_hooks.dart
    battle_effect_registry.dart
    ability/
    item/
    move/
    status/
    weather/
    terrain/
  handler/
    battle_change_handler.dart
    battle_damage_handler.dart
    battle_heal_handler.dart
    battle_stat_change_handler.dart
    battle_status_change_handler.dart
    battle_item_change_handler.dart
    battle_switch_handler.dart
    battle_end_turn_handler.dart
    battle_weather_change_handler.dart
    battle_terrain_change_handler.dart
    battle_ability_change_handler.dart
    battle_battle_end_handler.dart
  move/
    battle_move_procedure.dart
    battle_move_registry.dart
    behaviors/
  ai/
    battle_ai.dart
    battle_move_heuristic.dart
```

### Principe central

Le move ne doit pas connaitre tous les cas. Il doit appeler les handlers.

Flux cible:

```text
Decision
-> ActionDecisionMapper
-> ActionQueue
-> ActionOrdering
-> Action.execute
-> MoveProcedure
-> Handlers
-> Effects hooks
-> State mutation
-> Timeline events
-> Next request / outcome
```

### Procedure move cible

Equivalent Dart de `10 Move/120 Procedure.rb`:

```text
1. user alive
2. resolve possible targets
3. move_usable_by_user
4. usage event/message
5. pre_accuracy effects
6. no target check
7. accuracy check
8. remap user/targets (Snatch, etc.)
9. immunity/blocking check
10. post_accuracy effects
11. post_accuracy move hook
12. animation cue
13. deal_damage
14. effect_working
15. deal_status
16. deal_stats
17. deal_effect
18. move history
19. successful move history
20. cleanup/faint/end state
```

## Plan de migration en grands lots

### FIGHT-00 - Verrouillage audit et gates

Objectif:

- Faire du rapport et des matrices des gates de migration.

Fichiers:

- Modifier: `packages/map_battle/test/psdk_registry_manifest_test.dart`
- Modifier: `packages/map_battle/tool/extract_psdk_move_registry.dart`
- Modifier: `packages/map_battle/tool/extract_psdk_effect_matrix.dart`
- Creer: `reports/psdk-fight-engine-parity-status.md`

Logique:

- Ajouter categories/dependencies aux matrices:
  - `needs_effects`;
  - `needs_handler_damage`;
  - `needs_handler_status`;
  - `needs_field`;
  - `needs_weather`;
  - `needs_targeting_multi`;
  - `needs_ability`;
  - `needs_item`;
  - `needs_history`;
  - `needs_switch`;
  - `needs_end_turn`.

Validation:

- `cd packages/map_battle && dart test test/psdk_registry_manifest_test.dart`

### FIGHT-01 - Coupure Showdown du chemin combat

Objectif:

- Plus aucune source Showdown active dans le pipeline moves/combat.

Fichiers a modifier:

- `packages/map_core/lib/src/models/pokemon_move.dart`
- `packages/map_core/lib/src/models/pokemon_move.freezed.dart`
- `packages/map_core/lib/src/models/pokemon_move.g.dart`
- `packages/map_core/test/pokemon_move_test.dart`
- `packages/map_editor/lib/src/application/services/pokemon_sdk_move_catalog_converter.dart`
- `packages/map_editor/lib/src/application/use_cases/sync_pokemon_sdk_moves_catalog_use_case.dart`
- `packages/map_editor/lib/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart`
- `packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart`
- `packages/map_editor/lib/src/ui/canvas/pokemon_catalogs_workspace/moves_catalog_workspace.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_move_visual_resolver.dart`

Fichiers a supprimer ou rendre legacy-only:

- `packages/map_editor/lib/src/application/services/showdown_move_catalog_converter.dart`
- `packages/map_editor/lib/src/application/services/showdown_pokemon_species_converter.dart`
- `packages/map_editor/lib/src/infrastructure/external/showdown_snapshot_source.dart`

Logique:

- PSDK Studio devient la source principale des moves.
- Les refs Showdown ne servent plus au runtime combat.
- Les animations utilisent PSDK `dbSymbol` / `psdkAnimationId`.

Validation:

- `rg -n "showdown|Showdown|showdownMoveId|showdownHooksPresent|fetchShowdown|Sync depuis Showdown" packages examples docs`
- Les seuls hits acceptables doivent etre rapports historiques ou adapters legacy explicitement isoles.

### FIGHT-02 - Battler PSDK complet

Objectif:

- Aligner `PsdkBattleCombatant` sur `PokemonBattler`.

Fichiers:

- Modifier: `packages/map_battle/lib/src/psdk/domain/psdk_battle_combatant.dart`
- Modifier: `packages/map_battle/lib/src/domain/battle/battle_battler.dart`
- Creer: `packages/map_battle/test/psdk_battler_parity_test.dart`

Ajouter:

- ability id;
- held item id;
- consumed item;
- sleep turns;
- battle turns;
- last sent turn;
- last hit by move;
- damage history;
- stat history;
- successful move history avec targets;
- transform/illusion placeholders;
- type3/temp type support;
- switching/hasJustShifted flags.

Validation:

- tests unitaires sur histories, grounded inputs, item/ability ids.

### FIGHT-03 - Effect kernel

Objectif:

- Remplacer `PsdkBattleEffectStack` id-only par un vrai systeme d'effets PSDK.

Fichiers a creer:

- `packages/map_battle/lib/src/domain/effect/battle_effect.dart`
- `packages/map_battle/lib/src/domain/effect/battle_effect_hooks.dart`
- `packages/map_battle/lib/src/domain/effect/battle_effect_stack.dart`
- `packages/map_battle/lib/src/domain/effect/battle_effect_scope.dart`
- `packages/map_battle/lib/src/domain/effect/battle_effect_registry.dart`

Fichiers a modifier:

- `packages/map_battle/lib/src/psdk/domain/psdk_battle_combatant.dart`
- `packages/map_battle/lib/src/psdk/domain/psdk_battle_state.dart`
- `packages/map_battle/lib/src/domain/move/behaviors/battle_move_behavior_support.dart`
- `packages/map_battle/lib/src/domain/timeline/battle_timeline_event.dart`

Hooks minimum a modeliser:

- `on_move_prevention_user`;
- `on_move_prevention_target`;
- `on_move_disabled_check`;
- `on_damage_prevention`;
- `on_post_damage`;
- `on_post_damage_death`;
- `on_end_turn_event`;
- `on_status_prevention`;
- `on_stat_change`;
- `on_stat_change_post`;
- `on_weather_prevention`;
- `on_post_weather_change`;
- `on_fterrain_prevention`;
- `on_post_fterrain_change`;
- `on_switch_event`;
- `on_switch_prevention`;
- `on_move_type_change`;
- `effect_chance_modifier`.

Validation:

- porter `Protect` comme vraie classe d'effet;
- `reports/psdk-effect-porting-matrix.md` passe au moins `Protect` en `ported`
  ou `partial` documente par classe.

### FIGHT-04 - Handlers PSDK

Objectif:

- Introduire les handlers qui remplacent les mutations directes.

Fichiers a creer:

- `domain/handler/battle_damage_handler.dart`
- `domain/handler/battle_heal_handler.dart`
- `domain/handler/battle_stat_change_handler.dart`
- `domain/handler/battle_status_change_handler.dart`
- `domain/handler/battle_item_change_handler.dart`
- `domain/handler/battle_switch_handler.dart`
- `domain/handler/battle_end_turn_handler.dart`
- `domain/handler/battle_weather_change_handler.dart`
- `domain/handler/battle_terrain_change_handler.dart`
- `domain/handler/battle_ability_change_handler.dart`
- `domain/handler/battle_battle_end_handler.dart`

Fichiers a modifier:

- `domain/move/battle_move_damage_calculator.dart`
- `domain/move/battle_move_secondary_effect_resolver.dart`
- `domain/move/battle_move_procedure.dart`
- tous les behaviors qui appliquent damage/status/stats directement.

Logique:

- Les moves appellent les handlers.
- Les handlers consultent les effects.
- Les handlers emettent les events.

Validation:

- reproduire `DamageHandler.damage_change_with_process`;
- reproduire status prevention;
- reproduire stat stage clamp + prevention.

### FIGHT-05 - Action queue PSDK

Objectif:

- Remplacer le runner singles simplifie par une queue d'actions PSDK.

Fichiers:

- Creer: `domain/action/battle_action.dart`
- Creer: `domain/action/battle_action_queue.dart`
- Creer: `domain/action/battle_action_ordering.dart`
- Modifier: `application/battle_turn_runner.dart`
- Modifier: `domain/decision/battle_decision.dart`

Ajouter actions:

- Fight;
- Switch;
- Item;
- Flee;
- Mega;
- Shift;
- PreAttack;
- NoAction;
- HighPriorityItem.

Ordre PSDK:

- move priority;
- Pursuit on switch;
- high priority item;
- Quick Claw;
- Custap Berry;
- Quick Draw;
- Stall;
- Full Incense;
- Lagging Tail;
- Mycelium Might;
- Trick Room;
- speed tie RNG.

Validation:

- tests d'ordre avec priority/speed/trick room/item/ability.

### FIGHT-06 - Targeting complet

Objectif:

- Faire fonctionner les moves multi-target et doubles.

Fichiers:

- Modifier: `psdk/domain/psdk_battle_move.dart`
- Modifier: `domain/move/battle_target_resolver.dart`
- Modifier: `domain/battle/battle_topology.dart`
- Modifier: `psdk/domain/psdk_battle_slots.dart`

Ajouter targets:

- user;
- adjacent foe;
- adjacent allies;
- all adjacent;
- all foes;
- all battlers;
- ally;
- ally side;
- foe side;
- field;
- random foe;
- scripted target.

Validation:

- `ExpandingForce`, spread damage, ally target, self target.

### FIGHT-07 - Field, weather, terrain

Objectif:

- Porter `s_weather`, `s_terrain`, weather/terrain effects.

Fichiers:

- Modifier: `psdk/domain/psdk_battle_field.dart`
- Creer: `domain/effect/weather/*.dart`
- Creer: `domain/effect/terrain/*.dart`
- Creer: `domain/handler/battle_weather_change_handler.dart`
- Creer: `domain/handler/battle_terrain_change_handler.dart`
- Modifier: `domain/move/behaviors/terrain_power_move_behavior.dart`
- Creer: `domain/move/behaviors/weather_power_move_behavior.dart`

Moves debloques:

- `s_weather`;
- `s_terrain`;
- `s_weather_ball`;
- `s_terrain_pulse`;
- `s_rising_voltage`;
- `s_expanding_force`;
- `s_grassy_glide`;
- `s_solar_beam`;
- `s_thunder`;
- `s_shore_up`.

Validation:

- duration 5/8 turns;
- terrain/weather prevention;
- expiration;
- Air Lock/Cloud Nine;
- hard weather;
- terrain extender/weather rocks.

### FIGHT-08 - Status lifecycle

Objectif:

- Porter les status effects PSDK et leurs ticks/preventions.

Fichiers:

- Creer: `domain/effect/status/burn_effect.dart`
- Creer: `domain/effect/status/poison_effect.dart`
- Creer: `domain/effect/status/toxic_effect.dart`
- Creer: `domain/effect/status/paralysis_effect.dart`
- Creer: `domain/effect/status/sleep_effect.dart`
- Creer: `domain/effect/status/freeze_effect.dart`
- Modifier: `domain/handler/battle_status_change_handler.dart`
- Modifier: `domain/handler/battle_end_turn_handler.dart`

Moves debloques/promouvables:

- `s_status`;
- `s_facade`;
- `s_hex`;
- `s_venoshock`;
- `s_infernal_parade`;
- `s_bitter_malice`;
- sleep/freeze/status dependent moves.

Validation:

- burn damage + attack modifier;
- poison/toxic counters;
- paralysis prevention/speed;
- sleep turns;
- freeze thaw.

### FIGHT-09 - Ability effects

Objectif:

- Porter abilities qui bloquent les partials les plus importants.

Priorite:

1. Damp;
2. No Guard;
3. Skill Link;
4. Rock Head;
5. Reckless;
6. Levitate;
7. Air Lock / Cloud Nine;
8. weather/terrain setters;
9. immunity/status prevention abilities;
10. type/damage modifiers.

Fichiers:

- Creer: `domain/effect/ability/*.dart`
- Creer: `domain/effect/ability/ability_effect_registry.dart`
- Modifier: `psdk/domain/psdk_battle_combatant.dart`
- Modifier: `runtime_battle_combatant_seed_builder.dart`

Validation:

- promouvoir `s_explosion`, `s_mind_blown`, `s_multi_hit`, `s_recoil`
  progressivement.

### FIGHT-10 - Item effects

Objectif:

- Porter held items qui changent action/damage/status/duree.

Priorite:

1. Air Balloon;
2. Iron Ball;
3. Quick Claw;
4. Lagging Tail;
5. Full Incense;
6. Choice items;
7. weather rocks;
8. Terrain Extender;
9. Loaded Dice;
10. berries status/heal/stat.

Fichiers:

- Creer: `domain/effect/item/*.dart`
- Creer: `domain/effect/item/item_effect_registry.dart`
- Modifier: battler setup/runtime seed.

### FIGHT-11 - Procedure move PSDK complete

Objectif:

- `BattleMoveProcedure` doit suivre `10 Move/120 Procedure.rb`.

Fichiers:

- Modifier: `domain/move/battle_move_procedure.dart`
- Modifier: `domain/move/behaviors/battle_move_behavior_support.dart`
- Modifier: all behaviors touching prepare/apply damage.

Ajouter:

- target remap;
- snatch;
- magic coat/bounce;
- lock-on;
- bypass accuracy;
- target immune hooks;
- move blocked by target;
- effect working modifiers;
- move histories exactes.

### FIGHT-12 - Portage massif des move families

Objectif:

- Monter la matrice moves de 20 ported vers 330.

Ordre recommande:

1. Promouvoir les 24 `partial` existants apres leurs dependances.
2. Moves a formule locale sans effect persistant.
3. Moves basees sur history.
4. Moves status/stat.
5. Moves field/weather/terrain.
6. Moves switch/force/copy.
7. Moves ability/item/type changing.
8. Moves two-turn/pre-attack/out-of-reach.
9. Moves hazards/side effects.
10. Moves doubles/multi-target.

Regle:

- Chaque move family doit avoir:
  - test rouge;
  - implementation;
  - manifest update;
  - CLI scenario si utile;
  - statut `ported` seulement si toutes les branches PSDK utiles sont couvertes.

### FIGHT-13 - AI PSDK

Objectif:

- Remplacer `BattleOpponentPolicy` par AI/heuristics PSDK ou adapter equivalent.

Fichiers:

- Creer: `domain/ai/battle_ai.dart`
- Creer: `domain/ai/battle_move_heuristic.dart`
- Modifier: runtime trainer difficulty mapping.
- Migrer: `battle_opponent_policy.dart`.

Validation:

- tests decisions sur moves, switch, item si supporte.

### FIGHT-14 - Runtime bridge complet

Objectif:

- Le runtime utilise le Fight Engine PSDK comme source de verite.

Fichiers:

- `packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart`
- UI battle command/menu files.

Validation:

- wild battle end-to-end;
- trainer battle end-to-end;
- switch;
- item;
- capture;
- whiteout;
- runtime golden slices.

### FIGHT-15 - Parity test harness

Objectif:

- Avoir une CLI et des fixtures qui prouvent la parite famille par famille.

Fichiers:

- Modifier: `packages/map_battle/lib/src/psdk/cli/psdk_battle_cli.dart`
- Creer: `packages/map_battle/tool/psdk_parity_case_runner.dart`
- Creer: `packages/map_battle/test/psdk_parity_cases/*`

Scenarios:

- one-turn move cases;
- end-turn effects;
- field/weather duration;
- status lifecycle;
- ability/item interactions;
- switch/faint;
- doubles;
- AI smoke.

## Liste des moves actuellement portes

`ported`:

- `s_2hits`
- `s_3hits`
- `s_bitter_malice`
- `s_brine`
- `s_do_nothing`
- `s_electro_ball`
- `s_endeavor`
- `s_eruption`
- `s_facade`
- `s_fixed_damage`
- `s_flail`
- `s_full_crit`
- `s_hard_press`
- `s_hp_eq_level`
- `s_infernal_parade`
- `s_psywave`
- `s_super_fang`
- `s_terrain_boosting`
- `s_venoshock`
- `s_wring_out`

`partial`:

- `s_basic`
- `s_body_press`
- `s_chloroblast`
- `s_custom_stats_based`
- `s_explosion`
- `s_false_swipe`
- `s_final_gambit`
- `s_foul_play`
- `s_gyro_ball`
- `s_heavy_slam`
- `s_hex`
- `s_low_kick`
- `s_mind_blown`
- `s_misty_explosion`
- `s_multi_hit`
- `s_population_bomb`
- `s_protect`
- `s_psyshock`
- `s_recoil`
- `s_splash`
- `s_status`
- `s_steel_beam`
- `s_triple_kick`
- `s_water_shuriken`

## Definition of Done pour une vraie parite Fight Engine

On pourra dire que le moteur est vraiment aligne PSDK quand:

- `reports/psdk-move-porting-matrix.md` affiche 330 `ported`, 0 `partial`,
  0 `missing`, ou documente explicitement les rares exclusions produit.
- `reports/psdk-effect-porting-matrix.md` affiche les effects PSDK essentiels
  portes ou des exclusions justifiees.
- Le runtime ne depend plus de Showdown comme source moves/species/combat.
- `rg "showdown|Showdown|showdownMoveId|showdownHooksPresent|fetchShowdown"`
  ne retourne plus de code actif hors compat legacy documentee.
- Le CLI PSDK sait executer des scenarios:
  - basic damage;
  - status lifecycle;
  - weather;
  - terrain;
  - hazards;
  - switch/faint;
  - item;
  - ability;
  - doubles;
  - AI.
- Les tests `packages/map_battle`, `packages/map_runtime`,
  `examples/playable_runtime_host` passent sur golden battle slices.

## Ordre recommande immediat

Le prochain lot ne devrait pas etre "porter 20 moves de plus".

Ordre conseille:

1. **FIGHT-01 Showdown cleanup ciblé combat/moves** pour que la source de data
   soit PSDK.
2. **FIGHT-03 Effect kernel minimal** parce que presque tous les moves
   complexes en dependent.
3. **FIGHT-04 Handlers Damage/Status/Stat** pour arreter les mutations directes.
4. **FIGHT-07 Weather/Terrain handlers** pour debloquer un gros bloc de moves.
5. **FIGHT-08 Status lifecycle** pour rendre les moves status-dependent fiables.
6. **Promotion des 24 partials** avant d'ouvrir 100 nouveaux moves.

## Verification effectuee pendant cet audit

Commandes lancees:

```bash
cd /Users/karim/Project/pokemonProject/packages/map_battle
dart analyze
dart test
```

Resultats:

- `dart analyze`: no issues found.
- `dart test`: 410 tests passed.

Commandes de recherche:

```bash
find pokemonsdk-development/scripts/5\ Battle -type f
find packages/map_battle/lib/src packages/map_battle/test packages/map_battle/tool -type f
rg -n "showdown|Showdown|showdownMoveId|showdownHooksPresent|fetchShowdown|Sync depuis Showdown" packages/map_core packages/map_editor packages/map_runtime -g'*.dart'
```

Constat:

- `map_battle` est sain pour la tranche PSDK actuelle.
- Le reliquat Showdown actif existe surtout dans `map_core`, `map_editor` et
  `map_runtime`.
- La principale dette de parite est structurelle: effects/handlers/actions.

