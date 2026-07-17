# NS-EVENT-V2 — Phase F2 Closure Evidence Pack

## 1. Identité

```text
Mission : Phase F2 — Runtime Source Bridges
Jalons : NS-EVENT-V2-19 à NS-EVENT-V2-22
Baseline : 2f68328a38bf218c843e497940f8dd24a7a9c194
Branche : main
Date : 2026-07-15
Verdict : PHASE F2 CLOSED / ACCEPTED — V2-19 à V2-22 PASS
```

Ce pack est l'annexe probatoire du rapport
`ns_event_v2_phase_f2_runtime_source_bridges_closure_v0.md`. Les deux fichiers
de clôture sont mutuellement référencés mais ne s'embarquent pas eux-mêmes dans
les annexes de contenu complet, afin d'éviter une récursion infinie. Tous les
autres fichiers créés par F2 sont reproduits intégralement en fin de document.

## 2. Gate 0 exact

```text
pwd : /Users/karim/Project/pokemonProject
branch : main
HEAD : 2f68328a feat(event-v2): close NS-EVENT-V2 Phase F1
status initial : aucune sortie
diff --stat initial : aucune sortie
diff --name-only initial : aucune sortie
diff --check initial : aucune sortie
```

Le verrou non suivi `selbrume/.pokemap-project-1f1a60297a27b0b0.lock` est
apparu après Gate 0 depuis un processus externe. Il n'appartient pas à F2.

## 3. Audit initial — symboles et chemins

| Domaine | Symboles/chemins inspectés | Conclusion initiale |
|---|---|---|
| Authority | `NarrativeEventDispatchAuthority`, planner, coordinator | F1 prêt, aucun hook production |
| Progress | `NarrativeEventProgress`, outbox processor, transactions | FIFO/receipts prêts, aucun producteur réel complet |
| Lifecycle | `NarrativeRuntimeActivityGate`, Scene hooks | V2 protégé, legacy/asynchrones incomplets |
| Map | boot, `_handleWarp`, `_handleConnection`, `loadGame` | raisons et occurrence non unifiées |
| Spatial | `_handleInteract`, trigger movement | plusieurs fallbacks directs concurrents |
| Outcomes | Scene/Battle/Scenario | IDs parfois bruts, causalité et ordre incomplets |
| Host | launch save/seed | `saveData != null` ambigu |

## 4. ADR et invariants de preuve

| ADR | Invariant vérifié |
|---|---|
| EV2-004 | producteur + producerId + outcomeId empêchent les collisions |
| EV2-007 | une seule autorité décide ; claim ne fallback jamais |
| EV2-011 | une occurrence lance au plus un Event |
| EV2-013 | aucun checkpoint pendant Scene/continuation mémoire |
| EV2-014 | commit parent avant enfant, FIFO, profondeur bornée, receipts |
| EV2-015 | restore complet + outbox FIFO avant unique `mapEnter saveRestore` |

## 5. Ledger des jalons

| Jalon | Gate | Preuves principales | Statut |
|---|---|---|---|
| V2-19 | quatre raisons, une occurrence, restore ordering | bridge map, boot/warp/connection/load tests | `PASS` |
| V2-20 | entity kinds, fallback/claim, erreur visible | bridge spatial + intégrations entity | `PASS` |
| V2-21 | fronts, overlap FIFO, rearm, warp interlock | résolveur pur + intégrations trigger | `PASS` |
| V2-22 | qualification, causalité, reentrance, save/load | outcomes/Scene/Battle/Scenario/barriers | `PASS` |

## 6. Matrice map activation

| Chemin | Raison | Quand l'occurrence part | Garde-fous |
|---|---|---|---|
| Boot neuf/seed | `initialBoot` | monde monté et phase cohérente | pas de double saveRestore |
| Warp | `warp` | transition physique réussie | cible KO = zéro occurrence |
| Connection | `connection` | animation d'entrée terminée | activation stale annulée |
| Load / launch save | `saveRestore` | état/map/pose restaurés, outbox quiescente | même map autorisée, FIFO avant mapEnter |
| Whiteout même map | aucune nouvelle activation | n/a | compteur inchangé |

## 7. Matrice entity interaction

| Kind physique | Occurrence V2 | Fallback possible | Preuve |
|---|---:|---:|---|
| `npc` | oui | seulement `noMatch` non claimé | intégration |
| `sign` | oui | seulement `noMatch` non claimé | intégration |
| `item` | oui | seulement `noMatch` non claimé | intégration + item readiness |
| `custom` | oui | seulement `noMatch` non claimé | intégration |
| `spawn` | non | pipeline historique | exclusion directe |
| `MapPlacedElement` | non | pipeline historique | non-régressions existantes |

## 8. Matrice trigger enter

| Cas | Résultat |
|---|---|
| spawn déjà intérieur | initialise l'occupation, aucune occurrence |
| reste intérieur | aucune occurrence supplémentaire |
| sortie puis réentrée | une nouvelle occurrence |
| overlap | ordre UTF-16 stable, FIFO runtime |
| `event` / `custom` | éligible |
| système / gameplay zone / raw tile | exclu |
| trigger puis warp | occurrence liée à l'activation source, aucune fuite stale |

## 9. Matrice outcomes qualifiés

| Producteur | Qualification | Moment de publication |
|---|---|---|
| Scene | `scene:<sceneId>:<outcomeId>` | après succès et commit Scene |
| Battle autonome | `battle:<battleId>:<outcomeId>` | après write-back autoritatif |
| Battle hébergée | `battle:<battleId>:<outcomeId>` | provisoire dans state Scene, publiée au commit parent |
| Scenario legacy | `legacyScenario:<scenarioId>:<outcomeId>` | collecte différée, jamais recursion inline |
| Yarn hors Scene | aucune source autonome V0 | reste legacy |

## 10. Matrice commit/rollback Battle hébergée

| Parent Scene | Write-back Battle | Outcome Battle | Outcome Scene |
|---|---|---|---|
| succès | commité | publié avant Scene | publié en dernier |
| échec | abandonné | abandonné | absent |
| annulation | abandonné | abandonné | absent |

## 11. Corrélation et profondeur

- une racine crée `causationExecutionId`, `rootCorrelationId`, `depth=0` ;
- chaque enfant conserve la corrélation et incrémente la profondeur ;
- dialogue/Battle/mouvement/script/warp conservent les métadonnées lors de la
  reprise ;
- une transition map et son `mapEnter` enfant ne créent pas une racine
  concurrente ;
- la borne F1 terminalise les deliveries trop profondes.

## 12. Barrière de continuation

Invariants :

1. la delivery raw courante devient terminale avant toute continuation ;
2. la tête FIFO suivante ne démarre pas pendant un effet suspendu ;
3. une lease `sceneSuspended` interdit save et load pendant un effet mémoire
   actif ; un load peut en revanche purger certaines queues encore inactives ;
4. l'effet est associé à un owner (`runtimeSourceId`, `requestId` ou cible) ;
5. succès vérifie l'owner et la cible avant reprise ;
6. erreur/cancel ferme la barrière sans faux succès ;
7. une continuation enfant ferme avant le parent (LIFO) ;
8. la barrière peut transférer son runtime source lors d'un second await ;
9. l'outbox causale est vide avant fermeture finale.

## 13. Restore fence

Ordre attendu et testé :

```text
load state
→ raw delivery #1
→ effet suspendu #1
→ continuation + enfants #1
→ raw delivery #2
→ continuation + enfants #2
→ outbox quiescente
→ préparation mapEnter saveRestore
→ Scene/fallback mapEnter
```

Le verrou d'activation continue de bloquer l'input, les triggers et les autres
lancements. Seul le handoff dont l'owner correspond à la barrière supérieure
peut avancer pour éviter un deadlock.

## 14. Blockers découverts par la critique

| # | Défaut reproduit | Correction attendue/faite | Preuve |
|---:|---|---|---|
| 1 | setup Battle async KO laisse pending + lease | owner Battle nettoyé/cancel | test mapper KO |
| 2 | move même entité écrase l'ancienne continuation | cancel owner remplacé | double move |
| 3 | script error boucle récursivement | terminalisation/catch + cancel | erreur après dialogue |
| 4 | restore rend la main avant continuation/FIFO | fence restore owner-scoped | dialogue/warp restore |
| 5 | raw outcome vole une transition déjà pending | identité/owner transition | pending indépendant |
| 6 | script adopte Battle/connection externe | ownership exact du handoff | pending externe |
| 7 | player move→warp reprend après warp KO | owner+cible typés | cible KO |
| 8 | Battle normal/Scenario s'écrasent | owner requestId atomique | collisions deux sens |
| 9 | warp physique écrase warp script | handoff typé + policy | deux cibles même front |
| 10 | callbacks legacy démarrent sous checkpoint | lease avant dispatch | checkpoint retenu |
| 11 | work Scenario pré-load survit au load | purge transitoire | completion/follow stale |
| 12 | callback dialogue/Surf survit au load | clear explicite | dialogue post-load |
| 13 | Scene V1 n'occupe pas le gate | lease `sceneActive` | dialogue/Battle + save/load |
| 14 | transfert de continuation observable avant son owner | réservation avant premier await | dialogue/script sync |
| 15 | `runScript` synchrone termine avant création de barrière | réservation de source différée | pre-barrier abort |
| 16 | cutscene continue après load ou démarre sous checkpoint | `cancel`, lease lifetime et purge | runner + load |
| 17 | save démarre pendant préparation map/spatial | lease avant préparation d'autorité | interlock map/entity |
| 18 | outcome racine ouvre un gap avant enqueue | lease de publication racine | checkpoint pré-enqueue |
| 19 | Battle normal async survit au load | handoff + interlock unifiés | Battle/load |
| 20 | enfant Scenario perd sa causation parent | causation de continuation propagée | graphe enfant |
| 21 | remplacement move immédiat/KO laisse l'ancien owner | remplacement atomique | current-cell/unreachable |
| 22 | cycle sur le même `runtimeSourceId` perd son signal | latch de completion différée | cycle valide |
| 23 | trigger pending est retiré pendant checkpoint | retention/réinsertion de queue | trigger/checkpoint |
| 24 | warp/connection/animation/placed pending avance sous checkpoint | interlocks de consommation | save/checkpoint |
| 25 | Battle Scene et Battle normal partagent le singleton | claim Battle global atomique | collision deux sens |
| 26 | loader dialogue Scenario jette synchronement | catch + cleanup commun | softlock Scenario |
| 27 | loader dialogue Scene jette synchronement | catch + rollback/cleanup | softlock Scene |
| 28 | continuation restore crée un `transitionMap` hors fence | capture identité avant/après resume | restore transition |
| 29 | leader move→warp reprend avant warp réel | owner `leaderMove`, cible exacte | restore/FIFO/corrélation |
| 30 | retry outcome d'une tâche boot/entity/trigger s'échappe de Zone | helper détaché typé, sans hot-loop | retry attempt 1 |
| 31 | warp physique non-Scenario oublie le helper de retry | `mapEnter.physicalWarp` via helper | vraie transition warp |

Verdicts contradictoires finaux : `PASS` et `PASS`. La première passe finale a
exécuté 191 tests ; la seconde a relu le diff final et réexécuté les 9 tests de
l'interlock d'activation map.

## 15. Tests ciblés — commandes exactes

```text
cd packages/map_runtime
flutter test --reporter compact \
  test/playable_map_game_qualified_outcome_v2_integration_test.dart \
  test/playable_map_game_checkpoint_load_safety_integration_test.dart \
  test/playable_map_game_map_activation_interlock_test.dart \
  test/playable_map_game_trigger_enter_v2_integration_test.dart \
  test/playable_map_game_entity_interaction_v2_integration_test.dart \
  test/playable_map_game_map_enter_v2_integration_test.dart \
  test/playable_map_game_initial_save_restore_activation_test.dart \
  test/playable_map_game_save_restore_outbox_integration_test.dart \
  test/playable_map_game_event_v2_boot_integration_test.dart \
  test/playable_map_game_input_test.dart \
  test/scripted_entity_movement_controller_test.dart \
  test/cutscene_runtime_runner_test.dart \
  test/script_runtime_mvp_test.dart \
  test/narrative_map_enter_production_dispatch_bridge_test.dart \
  test/narrative_spatial_production_dispatch_bridge_test.dart \
  test/narrative_scene_runtime_execution_test.dart \
  test/narrative_event_runtime_snapshot_test.dart
=> +191: All tests passed! (exit 0)

flutter test --reporter compact \
  test/playable_map_game_event_v2_boot_integration_test.dart \
  test/playable_map_game_entity_interaction_v2_integration_test.dart \
  test/playable_map_game_trigger_enter_v2_integration_test.dart \
  test/playable_map_game_save_restore_outbox_integration_test.dart \
  test/playable_map_game_map_activation_interlock_test.dart
=> +33: All tests passed! (exit 0)

flutter test test/playable_map_game_map_activation_interlock_test.dart
=> +9: All tests passed! (exit 0, seconde revue indépendante)

flutter test test/phase_a_golden_battle_slice_smoke_test.dart --reporter compact
=> +3: All tests passed! (exit 0)

cd examples/playable_runtime_host
flutter test test/phase_a_golden_slice_launch_test.dart \
  test/p3_narrative_smoke_slice_test.dart \
  test/runtime_launch_save_test.dart --reporter compact
=> +6: All tests passed! (exit 0)
```

## 16. Suites complètes — commandes exactes

```text
cd packages/map_core
dart test --reporter compact
=> +2987: All tests passed! (exit 0)

cd packages/map_gameplay
dart test --reporter compact
=> +282: All tests passed! (exit 0)

cd packages/map_runtime
flutter test --reporter compact
=> +1769 ~1: 1 skipped test. All other tests passed! (exit 0)

cd examples/playable_runtime_host
flutter test --reporter compact
=> +50: All tests passed! (exit 0)
```

Incident de validation conservé : une première suite runtime, exécutée pendant
qu'un processus externe écrivait les fixtures Selbrume, a terminé
`+1719 ~1 -44` puis une passe contradictoire `+1700 ~1 -46`. Aucun correctif F2
n'a été déduit de ce bruit. Après stabilisation, les 165 fichiers ne dépendant
pas de Selbrume ont passé `+1669`, les 14 fichiers Selbrume ont passé
`+100 ~1`, puis la suite complète ci-dessus a passé `+1769 ~1`. Un premier
pipeline NUL mal formé pour sélectionner ces fichiers a échoué à charger un
faux chemin `binary file matches`; la commande corrigée avec `tr '\n' '\0'` a
produit les résultats verts. Ces essais échoués sont rapportés pour ne pas
maquiller l'historique des commandes.

## 17. Analyse, format et diff

```text
cd packages/map_core && dart analyze
=> No issues found! (exit 0)

cd packages/map_gameplay && dart analyze
=> No issues found! (exit 0)

cd packages/map_runtime
flutter analyze --no-pub \
  lib/src/presentation/flame/playable_map_game.dart \
  lib/src/application/cutscene_runtime_runner.dart \
  lib/src/application/scenario_runtime/scenario_runtime_executor.dart \
  lib/src/application/scenario_runtime/scenario_runtime_models.dart \
  lib/src/application/scene_runtime/scene_event_runtime_hook.dart \
  lib/src/application/scripted_entity_movement_controller.dart \
  lib/src/application/map_activation.dart \
  lib/src/application/map_enter_production_dispatch_bridge.dart \
  lib/src/application/narrative_event_runtime_snapshot.dart \
  lib/src/application/narrative_scene_runtime_execution.dart \
  lib/src/application/narrative_spatial_production_dispatch_bridge.dart
=> Analyzing 11 items... No issues found! (exit 0)

flutter analyze
=> 347 issues found, uniquement niveau info (exit 1, infos fatales par défaut)

flutter analyze --no-fatal-infos
=> 347 issues found, uniquement niveau info (exit 0)

cd examples/playable_runtime_host
flutter analyze
=> 1 info prefer_const_constructors (exit 1)

flutter analyze --no-fatal-infos
=> 1 info prefer_const_constructors (exit 0)

cd /Users/karim/Project/pokemonProject
{ git diff --name-only -z -- '*.dart'; \
  git ls-files --others --exclude-standard -z -- '*.dart'; } \
  | sort -zu | xargs -0 dart format
=> Formatted 42 files (0 changed)

dart format \
  packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart \
  packages/map_runtime/test/playable_map_game_event_v2_boot_integration_test.dart \
  packages/map_runtime/test/playable_map_game_entity_interaction_v2_integration_test.dart \
  packages/map_runtime/test/playable_map_game_trigger_enter_v2_integration_test.dart \
  packages/map_runtime/test/playable_map_game_map_activation_interlock_test.dart
=> 5 files (0 changed)

git diff --check
=> aucune sortie (exit 0)
```

Une tentative de lancer simultanément les deux analyses host a rencontré le
startup lock Flutter et une erreur de suppression d'un fichier ephemeral. La
relance séquentielle ci-dessus a fourni les résultats canoniques.

## 18. Build

```text
cd examples/playable_runtime_host
flutter build macos --debug --no-pub
=> PASS — Built build/macos/Build/Products/Debug/playable_runtime_host.app

flutter build macos --release --no-pub
=> FAIL — Target release_unpack_macos failed; FlutterMacOS.framework annoncé
   sans "arm64 x86_64", alors que lipo -info retourne "x86_64 arm64".
   Failed to copy Flutter framework. ** BUILD FAILED **
   Aucun artefact Release n'est revendiqué.
```

## 19. Inventaire tracked modifié — deltas finaux

```text
44   13  MVP Selbrume/road_map_event_builder_v2.md
14   8   examples/playable_runtime_host/lib/main.dart
17   0   examples/playable_runtime_host/lib/src/runtime_launch_save.dart
12   1   examples/playable_runtime_host/test/p3_narrative_smoke_slice_test.dart
34   0   examples/playable_runtime_host/test/runtime_launch_save_test.dart
4    0   packages/map_gameplay/lib/map_gameplay.dart
28   0   packages/map_runtime/lib/map_runtime.dart
24   0   packages/map_runtime/lib/src/application/cutscene_runtime_runner.dart
25   0   packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
14   0   packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart
4    2   packages/map_runtime/lib/src/application/scene_runtime/scene_event_runtime_hook.dart
6    4   packages/map_runtime/lib/src/application/script_command_executor.dart
45   5   packages/map_runtime/lib/src/application/scripted_entity_movement_controller.dart
2926 369 packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
36   0   packages/map_runtime/test/cutscene_runtime_runner_test.dart
30   0   packages/map_runtime/test/item_pickup_give_item_readiness_test.dart
8    0   packages/map_runtime/test/ns_event_34_scene_target_handoff_smoke_test.dart
8    0   packages/map_runtime/test/ns_event_35_trigger_variants_lifecycle_gate_test.dart
292  1   packages/map_runtime/test/playable_map_game_input_test.dart
23   2   packages/map_runtime/test/playable_map_game_whiteout_lite_test.dart
107  0   packages/map_runtime/test/scenario_runtime_executor_test.dart
31   0   packages/map_runtime/test/script_runtime_mvp_test.dart
175  1   packages/map_runtime/test/scripted_entity_movement_controller_test.dart

Total : 23 fichiers tracked, 3907 insertions, 406 suppressions.
```

Zones précises au snapshot final :

| Fichier | Lignes / symboles | Impact |
|---|---|---|
| roadmap | L17-20, L1031-1203, L2027-2047 | statuts F2, gates, synthèse et prochaine mission |
| host `main.dart` | `_ProjectLoaderPageState`, L524-546 | save sélectionnée et raison d'activation explicite |
| `runtime_launch_save.dart` | L6, `resolveRuntimeHostInitialMapActivationReason` L24-39 | save versionnée = restore, seed = boot |
| tests host | p3 L59/L70-80 ; launch save L5-43 | attente activation et deux cas save/seed |
| barrel gameplay | L69-72 | export des fronts trigger purs |
| barrel runtime | L25-52 | exports activation, snapshot et bridges |
| `cutscene_runtime_runner.dart` | `cancel`, L133-156 | annulation frames/waits/choix |
| Scenario executor/models | executor L702-726 ; models L234-275 | collecte différée et port d'outcome |
| Scene hook | `runSceneTarget`, L30/L91-105 | rebase sur state autoritatif |
| script executor | `_executeWarpPlayer`, L200-214 | réservation du handoff avant mutation |
| movement controller | `moveEntityTo` L150-234, `updateOwnedMove` L324-345, `_fail` L597-608 | remplacement atomique owner-scoped |
| `PlayableMapGame` | L126-245 | composition bridges/gate/callbacks |
| idem | L361-1128 | activation, dispatch, snapshot, Scene, outbox et retry |
| idem | L1168-1510 | compteurs, owners et observabilité |
| idem | L2217-2462 | mouvement et Cutscene |
| idem | L2675-2949 | update, trigger queue, checkpoint et transitions |
| idem | L3258-5263 | Scenario, barrières et handoffs Battle/warp/move |
| idem | L6995-7150 | publication sûre et interaction entity |
| idem | L7306-7394 | MapEvent Scene V1 sous lease |
| idem | L8797-9647 | save/load, purge, warp/connection et restore fence |
| idem | L11143-11378 | types privés des queues/barrières/handoffs |
| tests runtime tracked | cutscene L9-44 ; input L165-1228 ; scenario L414-520 ; script L119-149 ; movement L131-303 | régressions lifecycle, owners et erreurs |

## 20. Inventaire des fichiers créés

```text
68    packages/map_gameplay/lib/src/narrative_trigger_enter_fronts.dart
124   packages/map_gameplay/test/narrative_trigger_enter_fronts_test.dart
48    packages/map_runtime/lib/src/application/map_activation.dart
279   packages/map_runtime/lib/src/application/map_enter_production_dispatch_bridge.dart
152   packages/map_runtime/lib/src/application/narrative_event_runtime_snapshot.dart
112   packages/map_runtime/lib/src/application/narrative_scene_runtime_execution.dart
317   packages/map_runtime/lib/src/application/narrative_spatial_production_dispatch_bridge.dart
45    packages/map_runtime/test/narrative_event_runtime_snapshot_test.dart
882   packages/map_runtime/test/narrative_map_enter_production_dispatch_bridge_test.dart
240   packages/map_runtime/test/narrative_scene_runtime_execution_test.dart
650   packages/map_runtime/test/narrative_spatial_production_dispatch_bridge_test.dart
1353  packages/map_runtime/test/playable_map_game_checkpoint_load_safety_integration_test.dart
790   packages/map_runtime/test/playable_map_game_entity_interaction_v2_integration_test.dart
637   packages/map_runtime/test/playable_map_game_event_v2_boot_integration_test.dart
177   packages/map_runtime/test/playable_map_game_initial_save_restore_activation_test.dart
1713  packages/map_runtime/test/playable_map_game_map_activation_interlock_test.dart
207   packages/map_runtime/test/playable_map_game_map_enter_v2_integration_test.dart
5360  packages/map_runtime/test/playable_map_game_qualified_outcome_v2_integration_test.dart
315   packages/map_runtime/test/playable_map_game_save_restore_outbox_integration_test.dart
1206  packages/map_runtime/test/playable_map_game_trigger_enter_v2_integration_test.dart
4351  reports/narrativeStudio/events/ns_event_v2_19_map_enter_production_dispatch_bridge_v0.md

Total hors deux documents de clôture : 21 fichiers, 19 026 lignes.
```

## 21. Tests créés/modifiés — index comportemental

```text
Créés :
- narrative_trigger_enter_fronts_test.dart : spawn intérieur silencieux, fronts,
  réarmement, overlaps et types exclus.
- narrative_event_runtime_snapshot_test.dart : snapshot registry/facts/claims.
- narrative_map_enter_production_dispatch_bridge_test.dart : raisons, dedupe,
  stale, fallback/claim, Scene manquante et autorité bloquée.
- narrative_scene_runtime_execution_test.dart : commit/rollback Scene et Battle.
- narrative_spatial_production_dispatch_bridge_test.dart : kinds entity,
  fallback/noMatch, claim, erreurs et lifecycle.
- playable_map_game_event_v2_boot_integration_test.dart : boot réel, dialogue,
  retry durable sans erreur détachée.
- playable_map_game_map_enter_v2_integration_test.dart : warp/connection mapEnter.
- playable_map_game_initial_save_restore_activation_test.dart : seed vs restore.
- playable_map_game_entity_interaction_v2_integration_test.dart : npc/sign/item/
  custom, duplicate input et retry.
- playable_map_game_trigger_enter_v2_integration_test.dart : fronts, overlaps,
  stale warp, checkpoint queue et retry.
- playable_map_game_qualified_outcome_v2_integration_test.dart : namespaces,
  Battle/Scene/Scenario, rollback, FIFO, reentrance, owners et causalité.
- playable_map_game_save_restore_outbox_integration_test.dart : receipts, replay,
  FIFO restaurée et mapEnter après drain.
- playable_map_game_checkpoint_load_safety_integration_test.dart : leases,
  purge load et refus checkpoint.
- playable_map_game_map_activation_interlock_test.dart : activation identity,
  restore fence, races et retry warp physique.

Modifiés :
- cutscene_runtime_runner_test.dart : cancel et lifetime lease.
- scripted_entity_movement_controller_test.dart : remplacement atomique.
- scenario_runtime_executor_test.dart : outcome différée et loader sync KO.
- script_runtime_mvp_test.dart : erreur/cancel terminal.
- playable_map_game_input_test.dart : warp/connection owners et interlocks.
- item_pickup_give_item_readiness_test.dart, ns_event_34_*.dart,
  ns_event_35_*.dart, playable_map_game_whiteout_lite_test.dart : attente boot et
  non-régressions.
- host p3_narrative_smoke_slice_test.dart et runtime_launch_save_test.dart :
  hook async, launch save versionnée et raison d'activation.
```

## 22. État Git final

```text
 M "MVP Selbrume/road_map_event_builder_v2.md"
 M examples/playable_runtime_host/lib/main.dart
 M examples/playable_runtime_host/lib/src/runtime_launch_save.dart
 M examples/playable_runtime_host/test/p3_narrative_smoke_slice_test.dart
 M examples/playable_runtime_host/test/runtime_launch_save_test.dart
 M packages/map_gameplay/lib/map_gameplay.dart
 M packages/map_runtime/lib/map_runtime.dart
 M packages/map_runtime/lib/src/application/cutscene_runtime_runner.dart
 M packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
 M packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart
 M packages/map_runtime/lib/src/application/scene_runtime/scene_event_runtime_hook.dart
 M packages/map_runtime/lib/src/application/script_command_executor.dart
 M packages/map_runtime/lib/src/application/scripted_entity_movement_controller.dart
 M packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
 M packages/map_runtime/test/cutscene_runtime_runner_test.dart
 M packages/map_runtime/test/item_pickup_give_item_readiness_test.dart
 M packages/map_runtime/test/ns_event_34_scene_target_handoff_smoke_test.dart
 M packages/map_runtime/test/ns_event_35_trigger_variants_lifecycle_gate_test.dart
 M packages/map_runtime/test/playable_map_game_input_test.dart
 M packages/map_runtime/test/playable_map_game_whiteout_lite_test.dart
 M packages/map_runtime/test/scenario_runtime_executor_test.dart
 M packages/map_runtime/test/script_runtime_mvp_test.dart
 M packages/map_runtime/test/scripted_entity_movement_controller_test.dart
?? packages/map_gameplay/lib/src/narrative_trigger_enter_fronts.dart
?? packages/map_gameplay/test/narrative_trigger_enter_fronts_test.dart
?? packages/map_runtime/lib/src/application/map_activation.dart
?? packages/map_runtime/lib/src/application/map_enter_production_dispatch_bridge.dart
?? packages/map_runtime/lib/src/application/narrative_event_runtime_snapshot.dart
?? packages/map_runtime/lib/src/application/narrative_scene_runtime_execution.dart
?? packages/map_runtime/lib/src/application/narrative_spatial_production_dispatch_bridge.dart
?? packages/map_runtime/test/narrative_event_runtime_snapshot_test.dart
?? packages/map_runtime/test/narrative_map_enter_production_dispatch_bridge_test.dart
?? packages/map_runtime/test/narrative_scene_runtime_execution_test.dart
?? packages/map_runtime/test/narrative_spatial_production_dispatch_bridge_test.dart
?? packages/map_runtime/test/playable_map_game_checkpoint_load_safety_integration_test.dart
?? packages/map_runtime/test/playable_map_game_entity_interaction_v2_integration_test.dart
?? packages/map_runtime/test/playable_map_game_event_v2_boot_integration_test.dart
?? packages/map_runtime/test/playable_map_game_initial_save_restore_activation_test.dart
?? packages/map_runtime/test/playable_map_game_map_activation_interlock_test.dart
?? packages/map_runtime/test/playable_map_game_map_enter_v2_integration_test.dart
?? packages/map_runtime/test/playable_map_game_qualified_outcome_v2_integration_test.dart
?? packages/map_runtime/test/playable_map_game_save_restore_outbox_integration_test.dart
?? packages/map_runtime/test/playable_map_game_trigger_enter_v2_integration_test.dart
?? reports/narrativeStudio/events/ns_event_v2_19_map_enter_production_dispatch_bridge_v0.md
?? reports/narrativeStudio/events/ns_event_v2_phase_f2_closure_evidence_pack.md
?? reports/narrativeStudio/events/ns_event_v2_phase_f2_runtime_source_bridges_closure_v0.md
```

Aucune opération Git d'écriture. Le lock et les autres artefacts Selbrume
apparus en cours de validation avaient disparu au snapshot final, sans action
de cette mission. Le contrôle `git status --short --untracked-files=all --
selbrume` était vide.

## 23. Limites et risques

- aucun Editor/UI/migration ;
- aucune nouvelle source placed element/spawn/raw tile/system ;
- aucun Yarn autonome/fan-out ;
- rollback de load échoué toujours `FG-014 TODO` ;
- rollback `legacyOnly` seulement avant V2-only ;
- ledger delivered non compacté ;
- handoffs mémoire non crash-resumable ;
- retry d'infrastructure conservé pending jusqu'à un drain ultérieur/reload,
  sans boucle automatique ;
- aucun test dédié au cas extrême d'un second warp legacy immédiat lancé depuis
  le `mapEnter` imbriqué d'un warp propriétaire ;
- `PlayableMapGame` demeure le hotspot principal ;
- packaging release universel non prouvé.

## 24. Auto-critique

Les premières suites vertes ne couvraient pas l'ownership des singletons
asynchrones. Le plus grand apport de la passe finale est donc moins une API
supplémentaire que la suppression de faux liens causaux : aucun Battle, warp,
mouvement ou transition externe ne peut désormais reprendre le mauvais
Scenario. La contrepartie est un diff concentré dans un composition root déjà
volumineux. Une extraction ultérieure devra préserver toutes les matrices de ce
pack avant de déplacer le code.

## 25. Annexes — contenus complets des fichiers créés

Les contenus ci-dessous correspondent aux fichiers finaux du worktree après
format et validation. Les deux documents de clôture sont exclus de leur propre
annexe, comme expliqué en section 1.

### 25.1 `packages/map_gameplay/lib/src/narrative_trigger_enter_fronts.dart`

~~~~~~~~dart
import 'package:map_core/map_core.dart';

/// Pure resolution of eligible trigger occupancy and newly-entered fronts.
class NarrativeTriggerEnterFrontResolution {
  NarrativeTriggerEnterFrontResolution._({
    required List<String> currentOccupiedTriggerIds,
    required List<String> enteredTriggerIds,
  })  : currentOccupiedTriggerIds = List.unmodifiable(
          currentOccupiedTriggerIds,
        ),
        enteredTriggerIds = List.unmodifiable(enteredTriggerIds);

  /// Eligible trigger IDs covering the current player position.
  final List<String> currentOccupiedTriggerIds;

  /// Eligible trigger IDs absent from the previous occupancy.
  final List<String> enteredTriggerIds;
}

/// Resolves the eligible `MapTrigger` entry fronts at [currentPosition].
///
/// Only `event` and `custom` triggers belong to the narrative source union.
/// Passing `null` for [previousOccupiedTriggerIds] initializes occupancy (for
/// example after spawn, load, or warp) without emitting entry fronts. Passing
/// an empty iterable represents a previous position outside every eligible
/// trigger and therefore emits every currently occupied trigger as an entry.
NarrativeTriggerEnterFrontResolution resolveNarrativeTriggerEnterFronts({
  required MapData map,
  required GridPos currentPosition,
  required Iterable<String>? previousOccupiedTriggerIds,
}) {
  final currentIds = <String>{};
  for (final trigger in map.triggers) {
    if (!_isNarrativeTrigger(trigger) ||
        !_contains(trigger.area, currentPosition)) {
      continue;
    }
    currentIds.add(trigger.id);
  }

  final orderedCurrentIds = currentIds.toList()
    ..sort(compareNarrativeEventUtf16);
  final previousIds = previousOccupiedTriggerIds?.toSet();
  final enteredIds = previousIds == null
      ? <String>[]
      : orderedCurrentIds
          .where((triggerId) => !previousIds.contains(triggerId))
          .toList(growable: false);

  return NarrativeTriggerEnterFrontResolution._(
    currentOccupiedTriggerIds: orderedCurrentIds,
    enteredTriggerIds: enteredIds,
  );
}

bool _isNarrativeTrigger(MapTrigger trigger) {
  final id = trigger.id;
  return id.isNotEmpty &&
      id.trim() == id &&
      (trigger.type == TriggerType.event || trigger.type == TriggerType.custom);
}

bool _contains(MapRect area, GridPos position) {
  return position.x >= area.pos.x &&
      position.y >= area.pos.y &&
      position.x < area.pos.x + area.size.width &&
      position.y < area.pos.y + area.size.height;
}
~~~~~~~~

### 25.2 `packages/map_gameplay/test/narrative_trigger_enter_fronts_test.dart`

~~~~~~~~dart
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  group('resolveNarrativeTriggerEnterFronts', () {
    test('initializes inside eligible triggers without emitting an entry', () {
      final map = _mapWithTriggers([
        _trigger('zone_event', TriggerType.event),
        _trigger('zone_custom', TriggerType.custom),
        for (final type in const [
          TriggerType.warp,
          TriggerType.message,
          TriggerType.interaction,
          TriggerType.spawn,
          TriggerType.camera,
        ])
          _trigger('system_${type.name}', type),
      ]);

      final resolution = resolveNarrativeTriggerEnterFronts(
        map: map,
        currentPosition: const GridPos(x: 2, y: 2),
        previousOccupiedTriggerIds: null,
      );

      expect(
        resolution.currentOccupiedTriggerIds,
        ['zone_custom', 'zone_event'],
      );
      expect(resolution.enteredTriggerIds, isEmpty);
    });

    test('does not emit while staying inside the same eligible trigger', () {
      final map = _mapWithTriggers([
        _trigger('zone_event', TriggerType.event),
      ]);
      final initialized = resolveNarrativeTriggerEnterFronts(
        map: map,
        currentPosition: const GridPos(x: 2, y: 2),
        previousOccupiedTriggerIds: null,
      );

      final maintained = resolveNarrativeTriggerEnterFronts(
        map: map,
        currentPosition: const GridPos(x: 3, y: 3),
        previousOccupiedTriggerIds: initialized.currentOccupiedTriggerIds,
      );

      expect(maintained.currentOccupiedTriggerIds, ['zone_event']);
      expect(maintained.enteredTriggerIds, isEmpty);
    });

    test('rearams after exit and emits once on re-entry', () {
      final map = _mapWithTriggers([
        _trigger('zone_event', TriggerType.event),
      ]);
      final initialized = resolveNarrativeTriggerEnterFronts(
        map: map,
        currentPosition: const GridPos(x: 2, y: 2),
        previousOccupiedTriggerIds: null,
      );
      final exited = resolveNarrativeTriggerEnterFronts(
        map: map,
        currentPosition: const GridPos(x: 8, y: 8),
        previousOccupiedTriggerIds: initialized.currentOccupiedTriggerIds,
      );

      final reentered = resolveNarrativeTriggerEnterFronts(
        map: map,
        currentPosition: const GridPos(x: 2, y: 2),
        previousOccupiedTriggerIds: exited.currentOccupiedTriggerIds,
      );

      expect(exited.currentOccupiedTriggerIds, isEmpty);
      expect(exited.enteredTriggerIds, isEmpty);
      expect(reentered.currentOccupiedTriggerIds, ['zone_event']);
      expect(reentered.enteredTriggerIds, ['zone_event']);
    });

    test('keeps overlapping fronts in canonical UTF-16 order', () {
      final map = _mapWithTriggers([
        _trigger('zone_\uE000', TriggerType.event),
        _trigger('zone_\u{10000}', TriggerType.custom),
        _trigger('zone_a', TriggerType.event),
      ]);

      final resolution = resolveNarrativeTriggerEnterFronts(
        map: map,
        currentPosition: const GridPos(x: 2, y: 2),
        previousOccupiedTriggerIds: const <String>[],
      );

      expect(
        resolution.enteredTriggerIds,
        ['zone_a', 'zone_\u{10000}', 'zone_\uE000'],
      );
      expect(
        resolution.currentOccupiedTriggerIds,
        resolution.enteredTriggerIds,
      );
    });
  });
}

MapData _mapWithTriggers(List<MapTrigger> triggers) {
  return MapData(
    id: 'map_test',
    name: 'Map test',
    size: const GridSize(width: 10, height: 10),
    triggers: triggers,
  );
}

MapTrigger _trigger(String id, TriggerType type) {
  return MapTrigger(
    id: id,
    type: type,
    area: const MapRect(
      pos: GridPos(x: 1, y: 1),
      size: GridSize(width: 4, height: 4),
    ),
  );
}
~~~~~~~~

### 25.3 `packages/map_runtime/lib/src/application/map_activation.dart`

~~~~~~~~dart
import 'package:map_core/map_core.dart';

/// Runtime-only reason for a successfully completed map activation.
///
/// This metadata deliberately stays outside [NarrativeEventOccurrence]: Event
/// V2 source identity is only the canonical map-enter source.
enum MapActivationReason {
  initialBoot,
  warp,
  connection,
  saveRestore,
}

/// Identifies one completed runtime activation of a map.
final class MapActivation {
  MapActivation({
    required String activationId,
    required String mapId,
    required this.reason,
  })  : activationId = _requireNonBlank(activationId, 'activationId'),
        mapId = _requireNonBlank(mapId, 'mapId');

  final String activationId;
  final String mapId;
  final MapActivationReason reason;

  NarrativeEventOccurrence get occurrence => NarrativeEventOccurrence(
        source: NarrativeEventSourceRef.mapEnter(mapId),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapActivation &&
          other.activationId == activationId &&
          other.mapId == mapId &&
          other.reason == reason;

  @override
  int get hashCode => Object.hash(activationId, mapId, reason);
}

String _requireNonBlank(String value, String name) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, name, 'must not be blank');
  }
  return value;
}
~~~~~~~~

### 25.4 `packages/map_runtime/lib/src/application/map_enter_production_dispatch_bridge.dart`

~~~~~~~~dart
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import 'map_activation.dart';

sealed class MapEnterProductionDispatchResult {
  const MapEnterProductionDispatchResult(this.activation);

  final MapActivation activation;
}

final class MapEnterProductionDispatchLegacyFallback
    extends MapEnterProductionDispatchResult {
  const MapEnterProductionDispatchLegacyFallback(super.activation);
}

final class MapEnterProductionDispatchDuplicate
    extends MapEnterProductionDispatchResult {
  const MapEnterProductionDispatchDuplicate(super.activation);
}

final class MapEnterProductionDispatchNoFallback
    extends MapEnterProductionDispatchResult {
  const MapEnterProductionDispatchNoFallback(
    super.activation, [
    this.reason,
  ]);

  final Object? reason;
}

final class MapEnterProductionDispatchV2Handled
    extends MapEnterProductionDispatchResult {
  const MapEnterProductionDispatchV2Handled(
    super.activation,
    this.execution,
  );

  final NarrativeEventExecutionSucceeded execution;
}

final class MapEnterProductionDispatchClaimedIneligible
    extends MapEnterProductionDispatchResult {
  const MapEnterProductionDispatchClaimedIneligible(
    super.activation,
    this.execution,
  );

  final NarrativeEventExecutionClaimedButIneligible execution;
}

final class MapEnterProductionDispatchStale
    extends MapEnterProductionDispatchResult {
  const MapEnterProductionDispatchStale(super.activation);
}

final class MapEnterProductionDispatchAuthorityBlocked
    extends MapEnterProductionDispatchResult {
  const MapEnterProductionDispatchAuthorityBlocked(
    super.activation,
    this.authority,
  );

  final NarrativeEventDispatchAuthorityBlocked authority;
}

final class MapEnterProductionDispatchFailed
    extends MapEnterProductionDispatchResult {
  const MapEnterProductionDispatchFailed(
    super.activation,
    this.failure, [
    this.stackTrace,
  ]);

  final Object failure;
  final StackTrace? stackTrace;
}

/// Application boundary between completed map activations and Event V2.
///
/// V2-19 owns map-enter dispatch and runtime activation deduplication. Outcome
/// reentrancy stays in V2-22, while save/load orchestration remains FG-014; the
/// save-restore callback here is only the ordering seam between those lots.
final class MapEnterProductionDispatchBridge {
  MapEnterProductionDispatchBridge({
    required NarrativeEventStateTransactions stateTransactions,
    required GameState Function() currentGameState,
    required void Function(GameState gameState) onGameStateCommitted,
    required Future<NarrativeEventDispatchAuthorityPreparation> Function(
      MapActivation activation,
      NarrativeEventOccurrence occurrence,
    ) prepareAuthority,
    required NarrativeSceneExecutionCallback executeScene,
    required Future<void> Function(
      MapActivation activation,
      NarrativeEventOccurrence occurrence,
      GameState gameState,
    ) legacyFallback,
    required NarrativeEventActivityPort activityPort,
    required Future<void> Function(MapActivation activation)
        beforeSaveRestoreDispatch,
    required bool Function(String activationId) isCurrentActivation,
    required NarrativeExecutionIdFactory executionIdFactory,
    required NarrativeCorrelationIdFactory correlationIdFactory,
    required NarrativeDeliveryIdFactory deliveryIdFactory,
  })  : _stateTransactions = stateTransactions,
        _currentGameState = currentGameState,
        _onGameStateCommitted = onGameStateCommitted,
        _prepareAuthority = prepareAuthority,
        _executeScene = executeScene,
        _legacyFallback = legacyFallback,
        _activityPort = activityPort,
        _beforeSaveRestoreDispatch = beforeSaveRestoreDispatch,
        _isCurrentActivation = isCurrentActivation,
        _executionIdFactory = executionIdFactory,
        _correlationIdFactory = correlationIdFactory,
        _deliveryIdFactory = deliveryIdFactory;

  final NarrativeEventStateTransactions _stateTransactions;
  final GameState Function() _currentGameState;
  final void Function(GameState gameState) _onGameStateCommitted;
  final Future<NarrativeEventDispatchAuthorityPreparation> Function(
    MapActivation activation,
    NarrativeEventOccurrence occurrence,
  ) _prepareAuthority;
  final NarrativeSceneExecutionCallback _executeScene;
  final Future<void> Function(
    MapActivation activation,
    NarrativeEventOccurrence occurrence,
    GameState gameState,
  ) _legacyFallback;
  final NarrativeEventActivityPort _activityPort;
  final Future<void> Function(MapActivation activation)
      _beforeSaveRestoreDispatch;
  final bool Function(String activationId) _isCurrentActivation;
  final NarrativeExecutionIdFactory _executionIdFactory;
  final NarrativeCorrelationIdFactory _correlationIdFactory;
  final NarrativeDeliveryIdFactory _deliveryIdFactory;

  // add() happens before the first await, so concurrent callers in the same
  // isolate cannot both claim the same completed activation.
  final Set<String> _claimedActivationIds = <String>{};

  Future<MapEnterProductionDispatchResult> dispatchCompletedActivation(
    MapActivation activation,
  ) async {
    late final String activationId;
    late final NarrativeEventOccurrence occurrence;
    try {
      activationId = activation.activationId;
      occurrence = activation.occurrence;

      // Only the current activation needs to stay claimed. This keeps the set
      // bounded across map transitions while retaining the current ID so a
      // concurrent or repeated dispatch remains a duplicate.
      _claimedActivationIds.removeWhere(
        (claimedId) => !_isCurrentActivation(claimedId),
      );
      if (!_isCurrentActivation(activationId)) {
        return _stale(activation, activationId);
      }
      if (!_claimedActivationIds.add(activationId)) {
        return MapEnterProductionDispatchDuplicate(activation);
      }

      // The runtime GameState is authoritative at activation completion. Put
      // that exact snapshot behind the serialized F1 transaction boundary
      // before planning or executing Event V2.
      await _stateTransactions.transact<GameState>((_) {
        final current = _currentGameState();
        return NarrativeEventStateTransaction.commit(current, current);
      });
      if (!_isCurrentActivation(activationId)) {
        return _stale(activation, activationId);
      }

      if (activation.reason == MapActivationReason.saveRestore) {
        await _beforeSaveRestoreDispatch(activation);
        if (!_isCurrentActivation(activationId)) {
          return _stale(activation, activationId);
        }
        final latestGameState = await _stateTransactions.read();
        if (!_isCurrentActivation(activationId)) {
          return _stale(activation, activationId);
        }
        _onGameStateCommitted(latestGameState);
        if (!_isCurrentActivation(activationId)) {
          return _stale(activation, activationId);
        }
      }

      final preparation = await _prepareAuthority(activation, occurrence);
      if (!_isCurrentActivation(activationId)) {
        return _stale(activation, activationId);
      }
      if (preparation is NarrativeEventDispatchAuthorityBlocked) {
        return MapEnterProductionDispatchAuthorityBlocked(
          activation,
          preparation,
        );
      }
      final authority = preparation as NarrativeEventDispatchAuthorityReady;
      final coordinator = NarrativeEventExecutionCoordinator(
        stateTransactions: _stateTransactions,
        planner: NarrativeEventDispatchPlanner(),
        executeScene: (request) async {
          if (!_isCurrentActivation(activationId)) {
            return NarrativeSceneExecutionResult.cancelled(
              'Map activation became stale before Scene execution.',
            );
          }
          final result = await _executeScene(request);
          if (!_isCurrentActivation(activationId)) {
            return NarrativeSceneExecutionResult.cancelled(
              'Map activation became stale during Scene execution.',
            );
          }
          return result;
        },
        activityPort: _activityPort,
        executionIdFactory: _executionIdFactory,
        correlationIdFactory: _correlationIdFactory,
        deliveryIdFactory: _deliveryIdFactory,
      );
      final execution = await coordinator.execute(authority: authority);
      if (!_isCurrentActivation(activationId)) {
        return _stale(activation, activationId);
      }

      if (execution is NarrativeEventExecutionSucceeded) {
        _onGameStateCommitted(execution.updatedGameState);
        return MapEnterProductionDispatchV2Handled(activation, execution);
      }
      if (execution is NarrativeEventExecutionClaimedButIneligible) {
        return MapEnterProductionDispatchClaimedIneligible(
          activation,
          execution,
        );
      }
      if (execution is NarrativeEventExecutionFailed) {
        return MapEnterProductionDispatchFailed(
          activation,
          execution.failure,
          execution.failure.stackTrace,
        );
      }
      if (execution is NarrativeEventExecutionCancelled) {
        return MapEnterProductionDispatchNoFallback(activation, execution);
      }

      final noMatch = execution as NarrativeEventExecutionNoMatch;
      if (!noMatch.legacyFallbackAllowed) {
        return MapEnterProductionDispatchNoFallback(activation, noMatch);
      }

      final gameState = await _stateTransactions.read();
      if (!_isCurrentActivation(activationId)) {
        return _stale(activation, activationId);
      }
      await _legacyFallback(activation, occurrence, gameState);
      if (!_isCurrentActivation(activationId)) {
        return _stale(activation, activationId);
      }
      return MapEnterProductionDispatchLegacyFallback(activation);
    } catch (error, stackTrace) {
      // Preparation, pre-hooks, callbacks and legacy failures all stay closed:
      // no secondary dispatch path is attempted after an infrastructure error.
      return MapEnterProductionDispatchFailed(activation, error, stackTrace);
    }
  }

  MapEnterProductionDispatchStale _stale(
    MapActivation activation,
    String activationId,
  ) {
    _claimedActivationIds.remove(activationId);
    return MapEnterProductionDispatchStale(activation);
  }
}
~~~~~~~~

### 25.5 `packages/map_runtime/lib/src/application/narrative_event_runtime_snapshot.dart`

~~~~~~~~dart
import 'package:map_core/map_core.dart';

/// Immutable Event V2 runtime view built from one project/map corpus.
///
/// The runtime deliberately refuses to combine maps loaded from a different
/// manifest revision. That keeps the registry, catalog and legacy-claim
/// evidence on the same authority snapshot.
final class NarrativeEventRuntimeSnapshot {
  const NarrativeEventRuntimeSnapshot._({
    required this.project,
    required this.mapsById,
    required this.registryResult,
    required this.factResolver,
    required this.projectCatalog,
    required this.legacyClaimIndex,
  });

  final ProjectManifest project;
  final Map<String, MapData> mapsById;
  final EventRegistryDecodeResult registryResult;
  final NarrativeFactRuntimeResolver factResolver;
  final NarrativeEventProjectCatalog projectCatalog;
  final ValidatedLegacyClaimIndex legacyClaimIndex;

  static Future<NarrativeEventRuntimeSnapshot> build({
    required ProjectManifest project,
    required Future<({ProjectManifest project, MapData map})> Function(
      String mapId,
    ) loadMap,
  }) async {
    final registry = project.eventRegistry ??
        NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.legacyOnly,
          records: const [],
          legacyClaims: const [],
        );
    final structuralClaimIndex = buildValidatedLegacyClaimIndex(registry);
    final registryResult = project.eventRegistry == null
        ? EventRegistryDecodeResult.absent()
        : EventRegistryDecodeResult.decoded(registry);
    final factResolver = NarrativeFactRuntimeResolver.fromFacts(project.facts);
    if (registry.mode == EventSystemMode.legacyOnly) {
      return NarrativeEventRuntimeSnapshot._(
        project: project,
        mapsById: const <String, MapData>{},
        registryResult: registryResult,
        factResolver: factResolver,
        projectCatalog: buildNarrativeEventProjectCatalog(
          project: project,
          maps: const <MapData>[],
        ),
        legacyClaimIndex: structuralClaimIndex,
      );
    }
    final projectFingerprint = canonicalizeNarrativeEventJson(project.toJson());
    final mapsById = <String, MapData>{};

    for (final mapEntry in project.maps) {
      if (mapsById.containsKey(mapEntry.id)) {
        throw StateError(
          'Event V2 runtime snapshot contains duplicate map id '
          '"${mapEntry.id}".',
        );
      }
      final loaded = await loadMap(mapEntry.id);
      if (canonicalizeNarrativeEventJson(loaded.project.toJson()) !=
          projectFingerprint) {
        throw StateError(
          'Event V2 runtime snapshot changed while loading map '
          '"${mapEntry.id}".',
        );
      }
      if (loaded.map.id != mapEntry.id) {
        throw StateError(
          'Event V2 runtime snapshot expected map "${mapEntry.id}" but '
          'loaded "${loaded.map.id}".',
        );
      }
      mapsById[mapEntry.id] = loaded.map;
    }

    final legacyMapProjections = <LegacyMapEventProjection>[
      for (final map in mapsById.values)
        for (final event in map.events)
          projectLegacyMapEventReadOnly(
            mapId: map.id,
            map: map,
            event: event,
            claimIndex: structuralClaimIndex,
            rawEventJson: Map<String, Object?>.from(event.toJson()),
          ),
    ];
    final legacyScenarioProjections = <LegacyScenarioSourceProjection>[
      for (final scenario in project.scenarios)
        for (final node in scenario.nodes)
          if (isLegacyScenarioSourceNode(node))
            projectLegacyScenarioSourceReadOnly(
              scenario: scenario,
              node: node,
              scenes: project.scenes,
              claimIndex: structuralClaimIndex,
            ),
    ];
    final runtimeEvidence = LegacyClaimRuntimeEvidence(
      entries: [
        for (final projection in legacyMapProjections)
          if (projection.confirmedSource != null)
            LegacyClaimRuntimeEvidenceEntry(
              provenance: projection.provenance,
              source: projection.confirmedSource!,
              sourceFingerprint: projection.sourceFingerprint,
            ),
        for (final projection in legacyScenarioProjections)
          if (projection.source != null)
            LegacyClaimRuntimeEvidenceEntry(
              provenance: projection.provenance,
              source: projection.source!,
              sourceFingerprint: projection.sourceFingerprint,
            ),
      ],
    );
    final referencedOutcomes = <NarrativeOutcomeRef>[
      for (final projection in legacyScenarioProjections)
        if (projection.source != null)
          ...projection.source!.when(
            entityInteract: (_, __) => const <NarrativeOutcomeRef>[],
            triggerEnter: (_, __) => const <NarrativeOutcomeRef>[],
            mapEnter: (_) => const <NarrativeOutcomeRef>[],
            outcomeReceived: (outcome) => <NarrativeOutcomeRef>[outcome],
          ),
    ];
    final projectCatalog = buildNarrativeEventProjectCatalog(
      project: project,
      maps: mapsById.values.toList(growable: false),
      legacyProjections: legacyMapProjections,
      referencedOutcomes: referencedOutcomes,
    );

    return NarrativeEventRuntimeSnapshot._(
      project: project,
      mapsById: Map<String, MapData>.unmodifiable(mapsById),
      registryResult: registryResult,
      factResolver: factResolver,
      projectCatalog: projectCatalog,
      legacyClaimIndex: buildRuntimeValidatedLegacyClaimIndex(
        registry,
        runtimeEvidence: runtimeEvidence,
      ),
    );
  }
}
~~~~~~~~

### 25.6 `packages/map_runtime/lib/src/application/narrative_scene_runtime_execution.dart`

~~~~~~~~dart
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import 'scene_runtime/scene_consequence_runtime_writer.dart';
import 'scene_runtime/scene_runtime_host_callbacks.dart';

/// Executes the configured Event V2 Scene against the coordinator snapshot.
///
/// Consequences are buffered until the Scene completes. A failed Scene never
/// leaks a partial GameState update to the F1 transaction coordinator.
Future<NarrativeSceneExecutionResult> executeNarrativeEventScene({
  required NarrativeSceneExecutionRequest request,
  required ProjectManifest project,
  required Map<String, MapData> mapsById,
  required GameState Function() currentGameState,
  required SceneRuntimeHostCallbacks callbacks,
  List<NarrativeOutcomeRef> hostedBattleOutcomes = const [],
  int maxSteps = 100,
}) async {
  if (currentGameState() != request.gameState) {
    return NarrativeSceneExecutionResult.failed(
      StateError(
        'Event V2 Scene "${request.sceneId}" has an initial GameState '
        'conflict.',
      ),
    );
  }

  final matchingScenes = project.scenes
      .where((scene) => scene.id == request.sceneId)
      .toList(growable: false);
  if (matchingScenes.length != 1) {
    return NarrativeSceneExecutionResult.failed(
      StateError(
        matchingScenes.isEmpty
            ? 'Event V2 Scene "${request.sceneId}" was not found.'
            : 'Event V2 Scene "${request.sceneId}" is ambiguous.',
      ),
    );
  }
  final scene = matchingScenes.single;
  final diagnostics = diagnoseSceneAgainstProject(
    scene,
    project,
    mapsById: mapsById,
  );
  if (diagnostics.hasErrors) {
    return NarrativeSceneExecutionResult.failed(
      StateError(
        'Event V2 Scene "${request.sceneId}" has blocking diagnostics.',
      ),
    );
  }
  final planResult = buildSceneRuntimePlan(scene);
  if (!planResult.canBuild) {
    return NarrativeSceneExecutionResult.failed(
      StateError(
        'Event V2 Scene "${request.sceneId}" cannot build a runtime plan.',
      ),
    );
  }

  // Only Scene consequences are buffered for the coordinator transaction.
  // Host callbacks (battle/dialogue) own their runtime side effects; once the
  // Scene completes, those authoritative writes are kept by rebasing the
  // buffered consequences onto the latest host GameState.
  final pendingConsequences = <SceneConsequence>[];
  final execution = await SceneRuntimeExecutor(
    callbacks: callbacks.toExecutionCallbacks(
      applyConsequence: (consequence) {
        pendingConsequences.add(consequence);
        return 'completed';
      },
    ),
    maxSteps: maxSteps,
  ).execute(planResult.plan!);
  if (execution.status != SceneRuntimeExecutionStatus.completed) {
    return NarrativeSceneExecutionResult.failed(
      StateError(
        execution.message ??
            'Event V2 Scene "${request.sceneId}" failed during execution.',
      ),
    );
  }

  final writeResult = SceneConsequenceRuntimeWriter(
    project: project,
    mapsById: mapsById,
  ).applyAll(currentGameState(), pendingConsequences);
  if (!writeResult.success) {
    return NarrativeSceneExecutionResult.failed(
      StateError(
        writeResult.message ??
            'Event V2 Scene "${request.sceneId}" consequence commit failed.',
      ),
    );
  }

  final sceneOutcomeId = execution.sceneOutcomeId;
  return NarrativeSceneExecutionResult.completed(
    updatedGameState: writeResult.gameState,
    qualifiedOutcomes: <NarrativeOutcomeRef>[
      ...hostedBattleOutcomes,
      if (sceneOutcomeId != null)
        NarrativeOutcomeRef(
          producerKind: NarrativeOutcomeProducerKind.scene,
          producerId: scene.id,
          outcomeId: sceneOutcomeId,
        ),
    ],
  );
}
~~~~~~~~

### 25.7 `packages/map_runtime/lib/src/application/narrative_spatial_production_dispatch_bridge.dart`

~~~~~~~~dart
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

sealed class NarrativeSpatialProductionDispatchResult {
  const NarrativeSpatialProductionDispatchResult(
    this.occurrenceId,
    this.occurrence,
  );

  final String occurrenceId;
  final NarrativeEventOccurrence occurrence;
}

final class NarrativeSpatialProductionDispatchLegacyFallback
    extends NarrativeSpatialProductionDispatchResult {
  const NarrativeSpatialProductionDispatchLegacyFallback(
    super.occurrenceId,
    super.occurrence,
  );
}

final class NarrativeSpatialProductionDispatchDuplicate
    extends NarrativeSpatialProductionDispatchResult {
  const NarrativeSpatialProductionDispatchDuplicate(
    super.occurrenceId,
    super.occurrence,
  );
}

final class NarrativeSpatialProductionDispatchNoFallback
    extends NarrativeSpatialProductionDispatchResult {
  const NarrativeSpatialProductionDispatchNoFallback(
    super.occurrenceId,
    super.occurrence, [
    this.reason,
  ]);

  final Object? reason;
}

final class NarrativeSpatialProductionDispatchV2Handled
    extends NarrativeSpatialProductionDispatchResult {
  const NarrativeSpatialProductionDispatchV2Handled(
    super.occurrenceId,
    super.occurrence,
    this.execution,
  );

  final NarrativeEventExecutionSucceeded execution;
}

final class NarrativeSpatialProductionDispatchClaimedIneligible
    extends NarrativeSpatialProductionDispatchResult {
  const NarrativeSpatialProductionDispatchClaimedIneligible(
    super.occurrenceId,
    super.occurrence,
    this.execution,
  );

  final NarrativeEventExecutionClaimedButIneligible execution;
}

final class NarrativeSpatialProductionDispatchStale
    extends NarrativeSpatialProductionDispatchResult {
  const NarrativeSpatialProductionDispatchStale(
    super.occurrenceId,
    super.occurrence,
  );
}

final class NarrativeSpatialProductionDispatchAuthorityBlocked
    extends NarrativeSpatialProductionDispatchResult {
  const NarrativeSpatialProductionDispatchAuthorityBlocked(
    super.occurrenceId,
    super.occurrence,
    this.authority,
  );

  final NarrativeEventDispatchAuthorityBlocked authority;
}

final class NarrativeSpatialProductionDispatchFailed
    extends NarrativeSpatialProductionDispatchResult {
  const NarrativeSpatialProductionDispatchFailed(
    super.occurrenceId,
    super.occurrence,
    this.failure, [
    this.stackTrace,
  ]);

  final Object failure;
  final StackTrace? stackTrace;
}

typedef NarrativeSpatialAuthorityPreparation
    = Future<NarrativeEventDispatchAuthorityPreparation> Function(
  String occurrenceId,
  NarrativeEventOccurrence occurrence,
);

typedef NarrativeSpatialLegacyFallback = Future<void> Function(
  String occurrenceId,
  NarrativeEventOccurrence occurrence,
  GameState gameState,
);

/// Production boundary shared by entity-interaction and trigger-entry hooks.
///
/// One stable [occurrenceId] is claimed before the first asynchronous boundary.
/// Event V2 owns every claimed or attempted candidate; legacy fallback is
/// reachable only for an authority-approved no-match decision.
final class NarrativeSpatialProductionDispatchBridge {
  NarrativeSpatialProductionDispatchBridge({
    required NarrativeEventStateTransactions stateTransactions,
    required GameState Function() currentGameState,
    required void Function(GameState gameState) onGameStateCommitted,
    required NarrativeSpatialAuthorityPreparation prepareAuthority,
    required NarrativeSceneExecutionCallback executeScene,
    required NarrativeSpatialLegacyFallback legacyFallback,
    required NarrativeEventActivityPort activityPort,
    required bool Function(String occurrenceId) isCurrentOccurrence,
    required NarrativeExecutionIdFactory executionIdFactory,
    required NarrativeCorrelationIdFactory correlationIdFactory,
    required NarrativeDeliveryIdFactory deliveryIdFactory,
  })  : _stateTransactions = stateTransactions,
        _currentGameState = currentGameState,
        _onGameStateCommitted = onGameStateCommitted,
        _prepareAuthority = prepareAuthority,
        _executeScene = executeScene,
        _legacyFallback = legacyFallback,
        _activityPort = activityPort,
        _isCurrentOccurrence = isCurrentOccurrence,
        _executionIdFactory = executionIdFactory,
        _correlationIdFactory = correlationIdFactory,
        _deliveryIdFactory = deliveryIdFactory;

  final NarrativeEventStateTransactions _stateTransactions;
  final GameState Function() _currentGameState;
  final void Function(GameState gameState) _onGameStateCommitted;
  final NarrativeSpatialAuthorityPreparation _prepareAuthority;
  final NarrativeSceneExecutionCallback _executeScene;
  final NarrativeSpatialLegacyFallback _legacyFallback;
  final NarrativeEventActivityPort _activityPort;
  final bool Function(String occurrenceId) _isCurrentOccurrence;
  final NarrativeExecutionIdFactory _executionIdFactory;
  final NarrativeCorrelationIdFactory _correlationIdFactory;
  final NarrativeDeliveryIdFactory _deliveryIdFactory;

  final Set<String> _claimedOccurrenceIds = <String>{};

  Future<NarrativeSpatialProductionDispatchResult> dispatch({
    required String occurrenceId,
    required NarrativeEventOccurrence occurrence,
  }) async {
    try {
      _validateOccurrence(occurrenceId, occurrence);

      // Claiming happens before the first await, so concurrent callers cannot
      // execute or fall back twice for the same production occurrence.
      _claimedOccurrenceIds.removeWhere(
        (claimedId) => !_isCurrentOccurrence(claimedId),
      );
      if (!_isCurrentOccurrence(occurrenceId)) {
        return _stale(occurrenceId, occurrence);
      }
      if (!_claimedOccurrenceIds.add(occurrenceId)) {
        return NarrativeSpatialProductionDispatchDuplicate(
          occurrenceId,
          occurrence,
        );
      }

      // The runtime snapshot is authoritative when the spatial occurrence is
      // captured. Install it transactionally before authority planning.
      await _stateTransactions.transact<GameState>((_) {
        final current = _currentGameState();
        return NarrativeEventStateTransaction.commit(current, current);
      });
      if (!_isCurrentOccurrence(occurrenceId)) {
        return _stale(occurrenceId, occurrence);
      }

      final preparation = await _prepareAuthority(occurrenceId, occurrence);
      if (!_isCurrentOccurrence(occurrenceId)) {
        return _stale(occurrenceId, occurrence);
      }
      if (preparation is NarrativeEventDispatchAuthorityBlocked) {
        return NarrativeSpatialProductionDispatchAuthorityBlocked(
          occurrenceId,
          occurrence,
          preparation,
        );
      }
      final authority = preparation as NarrativeEventDispatchAuthorityReady;
      final coordinator = NarrativeEventExecutionCoordinator(
        stateTransactions: _stateTransactions,
        planner: NarrativeEventDispatchPlanner(),
        executeScene: (request) async {
          if (!_isCurrentOccurrence(occurrenceId)) {
            return NarrativeSceneExecutionResult.cancelled(
              'Spatial occurrence became stale before Scene execution.',
            );
          }
          final result = await _executeScene(request);
          if (!_isCurrentOccurrence(occurrenceId)) {
            return NarrativeSceneExecutionResult.cancelled(
              'Spatial occurrence became stale during Scene execution.',
            );
          }
          return result;
        },
        activityPort: _activityPort,
        executionIdFactory: _executionIdFactory,
        correlationIdFactory: _correlationIdFactory,
        deliveryIdFactory: _deliveryIdFactory,
      );
      final execution = await coordinator.execute(authority: authority);
      if (!_isCurrentOccurrence(occurrenceId)) {
        return _stale(occurrenceId, occurrence);
      }

      if (execution is NarrativeEventExecutionSucceeded) {
        _onGameStateCommitted(execution.updatedGameState);
        if (!_isCurrentOccurrence(occurrenceId)) {
          return _stale(occurrenceId, occurrence);
        }
        return NarrativeSpatialProductionDispatchV2Handled(
          occurrenceId,
          occurrence,
          execution,
        );
      }
      if (execution is NarrativeEventExecutionClaimedButIneligible) {
        return NarrativeSpatialProductionDispatchClaimedIneligible(
          occurrenceId,
          occurrence,
          execution,
        );
      }
      if (execution is NarrativeEventExecutionFailed) {
        return NarrativeSpatialProductionDispatchFailed(
          occurrenceId,
          occurrence,
          execution.failure,
          execution.failure.stackTrace,
        );
      }
      if (execution is NarrativeEventExecutionCancelled) {
        return NarrativeSpatialProductionDispatchNoFallback(
          occurrenceId,
          occurrence,
          execution,
        );
      }

      final noMatch = execution as NarrativeEventExecutionNoMatch;
      if (!noMatch.legacyFallbackAllowed) {
        return NarrativeSpatialProductionDispatchNoFallback(
          occurrenceId,
          occurrence,
          noMatch,
        );
      }

      final gameState = await _stateTransactions.read();
      if (!_isCurrentOccurrence(occurrenceId)) {
        return _stale(occurrenceId, occurrence);
      }
      await _legacyFallback(occurrenceId, occurrence, gameState);
      if (!_isCurrentOccurrence(occurrenceId)) {
        return _stale(occurrenceId, occurrence);
      }
      return NarrativeSpatialProductionDispatchLegacyFallback(
        occurrenceId,
        occurrence,
      );
    } catch (error, stackTrace) {
      // Infrastructure and host callback failures stay fail-closed: a second
      // dispatch path must never be attempted after partial execution.
      return NarrativeSpatialProductionDispatchFailed(
        occurrenceId,
        occurrence,
        error,
        stackTrace,
      );
    }
  }

  void _validateOccurrence(
    String occurrenceId,
    NarrativeEventOccurrence occurrence,
  ) {
    if (occurrenceId.trim().isEmpty) {
      throw ArgumentError.value(
        occurrenceId,
        'occurrenceId',
        'must be non-empty',
      );
    }
    if (occurrence.source.kind != NarrativeEventSourceKind.entityInteract &&
        occurrence.source.kind != NarrativeEventSourceKind.triggerEnter) {
      throw ArgumentError.value(
        occurrence.source.kind,
        'occurrence.source.kind',
        'must be entityInteract or triggerEnter',
      );
    }
  }

  NarrativeSpatialProductionDispatchStale _stale(
    String occurrenceId,
    NarrativeEventOccurrence occurrence,
  ) {
    _claimedOccurrenceIds.remove(occurrenceId);
    return NarrativeSpatialProductionDispatchStale(occurrenceId, occurrence);
  }
}
~~~~~~~~

### 25.8 `packages/map_runtime/test/narrative_event_runtime_snapshot_test.dart`

~~~~~~~~dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/narrative_event_runtime_snapshot.dart';

void main() {
  test('legacyOnly snapshot never loads the project map corpus', () async {
    var loadCalls = 0;
    final project = ProjectManifest(
      name: 'Legacy-only lightweight snapshot',
      maps: const <ProjectMapEntry>[
        ProjectMapEntry(
          id: 'map_a',
          name: 'Map A',
          relativePath: 'maps/map_a.json',
        ),
        ProjectMapEntry(
          id: 'map_b',
          name: 'Map B',
          relativePath: 'maps/map_b.json',
        ),
      ],
      tilesets: const <ProjectTilesetEntry>[],
      eventRegistry: NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.legacyOnly,
        records: const [],
        legacyClaims: const [],
      ),
      surfaceCatalog: const ProjectSurfaceCatalog.empty(),
    );

    final snapshot = await NarrativeEventRuntimeSnapshot.build(
      project: project,
      loadMap: (_) async {
        loadCalls++;
        throw StateError('legacyOnly must not load maps');
      },
    );

    expect(loadCalls, 0);
    expect(snapshot.mapsById, isEmpty);
    expect(snapshot.registryResult.registryOrNull?.mode,
        EventSystemMode.legacyOnly);
  });
}
~~~~~~~~

### 25.9 `packages/map_runtime/test/narrative_map_enter_production_dispatch_bridge_test.dart`

~~~~~~~~dart
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

const _eventId = 'evt_019abcde-0000-7000-8000-000000000001';
const _executionId = 'evx_019abcde-0000-7000-8000-000000000002';
const _correlationId = 'corr_019abcde-0000-7000-8000-000000000003';
const _generatedDeliveryId = 'outd_019abcde-0000-7000-8000-000000000004';
const _firstPendingDeliveryId = 'outd_019abcde-0000-7000-8000-000000000005';
const _secondPendingDeliveryId = 'outd_019abcde-0000-7000-8000-000000000006';
const _legacyFingerprint =
    'sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

void main() {
  group('NS-EVENT-V2-19 map-enter production dispatch bridge', () {
    test('rejects empty and whitespace-only activation identities', () {
      for (final invalid in ['', ' ', '\t\n']) {
        expect(
          () => MapActivation(
            activationId: invalid,
            mapId: 'map',
            reason: MapActivationReason.initialBoot,
          ),
          throwsArgumentError,
        );
        expect(
          () => MapActivation(
            activationId: 'activation-valid',
            mapId: invalid,
            reason: MapActivationReason.initialBoot,
          ),
          throwsArgumentError,
        );
      }
    });

    test('all activation reasons keep runtime metadata and deduplicate by id',
        () async {
      for (final reason in MapActivationReason.values) {
        var currentState = const GameState(saveId: 'save');
        final transactions = NarrativeEventStateTransactions(currentState);
        final legacyTrace = <MapActivation>[];
        final activation = MapActivation(
          activationId: 'activation-${reason.name}',
          mapId: 'map-${reason.name}',
          reason: reason,
        );
        final bridge = _bridge(
          stateTransactions: transactions,
          currentGameState: () => currentState,
          onGameStateCommitted: (value) => currentState = value,
          prepareAuthority: (_, occurrence) async => _prepareAuthority(
            registry: _registry(EventSystemMode.legacyOnly),
            occurrence: occurrence,
          ),
          legacyFallback: (value, occurrence, gameState) async {
            expect(occurrence, value.occurrence);
            expect(gameState.saveId, 'save');
            legacyTrace.add(value);
          },
          isCurrentActivation: (value) => value == activation.activationId,
        );

        expect(
          activation.occurrence,
          NarrativeEventOccurrence(
            source: NarrativeEventSourceRef.mapEnter(activation.mapId),
          ),
        );

        final first = await bridge.dispatchCompletedActivation(activation);
        final duplicate = await bridge.dispatchCompletedActivation(activation);

        expect(first, isA<MapEnterProductionDispatchLegacyFallback>());
        expect(duplicate, isA<MapEnterProductionDispatchDuplicate>());
        expect(legacyTrace, [activation]);
      }
    });

    test('concurrent dispatches of one current activation execute once',
        () async {
      var currentState = const GameState(saveId: 'save');
      final transactions = NarrativeEventStateTransactions(currentState);
      final legacyStarted = Completer<void>();
      final releaseLegacy = Completer<void>();
      var legacyCalls = 0;
      final activation = MapActivation(
        activationId: 'activation-concurrent',
        mapId: 'map',
        reason: MapActivationReason.initialBoot,
      );
      final bridge = _bridge(
        stateTransactions: transactions,
        currentGameState: () => currentState,
        onGameStateCommitted: (value) => currentState = value,
        prepareAuthority: (_, occurrence) async => _prepareAuthority(
          registry: _registry(EventSystemMode.legacyOnly),
          occurrence: occurrence,
        ),
        legacyFallback: (_, __, ___) async {
          legacyCalls++;
          legacyStarted.complete();
          await releaseLegacy.future;
        },
        isCurrentActivation: (value) => value == activation.activationId,
      );

      final firstDispatch = bridge.dispatchCompletedActivation(activation);
      await legacyStarted.future;
      final secondResult = await bridge.dispatchCompletedActivation(activation);
      releaseLegacy.complete();
      final firstResult = await firstDispatch;

      expect(firstResult, isA<MapEnterProductionDispatchLegacyFallback>());
      expect(secondResult, isA<MapEnterProductionDispatchDuplicate>());
      expect(legacyCalls, 1);
    });

    test('legacyOnly falls back while v2Only no-match stays closed', () async {
      for (final testCase in <({
        EventSystemMode mode,
        int expectedLegacyCalls,
        Type expectedResult,
      })>[
        (
          mode: EventSystemMode.legacyOnly,
          expectedLegacyCalls: 1,
          expectedResult: MapEnterProductionDispatchLegacyFallback,
        ),
        (
          mode: EventSystemMode.v2Only,
          expectedLegacyCalls: 0,
          expectedResult: MapEnterProductionDispatchNoFallback,
        ),
      ]) {
        var currentState = const GameState(saveId: 'save');
        final transactions = NarrativeEventStateTransactions(currentState);
        var legacyCalls = 0;
        final activation = MapActivation(
          activationId: 'activation-authority-mode',
          mapId: 'map',
          reason: MapActivationReason.initialBoot,
        );
        final registry = _registry(testCase.mode);
        final bridge = _bridge(
          stateTransactions: transactions,
          currentGameState: () => currentState,
          onGameStateCommitted: (value) => currentState = value,
          prepareAuthority: (_, occurrence) async => _prepareAuthority(
            registry: registry,
            occurrence: occurrence,
          ),
          legacyFallback: (_, __, ___) async => legacyCalls++,
          isCurrentActivation: (value) => value == activation.activationId,
        );

        final result = await bridge.dispatchCompletedActivation(activation);

        expect(result.runtimeType, testCase.expectedResult);
        expect(legacyCalls, testCase.expectedLegacyCalls);
      }
    });

    test('dualRead handled event executes V2 and never invokes legacy',
        () async {
      var currentState = const GameState(saveId: 'save');
      final transactions = NarrativeEventStateTransactions(currentState);
      final source = NarrativeEventSourceRef.mapEnter('map');
      final registry = _registry(
        EventSystemMode.dualRead,
        records: [_record(source)],
      );
      var v2Calls = 0;
      var legacyCalls = 0;
      final activation = MapActivation(
        activationId: 'activation-dual-read-handled',
        mapId: 'map',
        reason: MapActivationReason.warp,
      );
      final bridge = _bridge(
        stateTransactions: transactions,
        currentGameState: () => currentState,
        onGameStateCommitted: (value) => currentState = value,
        prepareAuthority: (_, occurrence) async => _prepareAuthority(
          registry: registry,
          occurrence: occurrence,
          legacyClaimIndex: buildValidatedLegacyClaimIndex(registry),
        ),
        executeScene: (request) async {
          v2Calls++;
          expect(request.eventId, _eventId);
          return NarrativeSceneExecutionResult.completed(
            updatedGameState: request.gameState,
            qualifiedOutcomes: const [],
          );
        },
        legacyFallback: (_, __, ___) async => legacyCalls++,
        isCurrentActivation: (value) => value == activation.activationId,
      );

      final result = await bridge.dispatchCompletedActivation(activation);

      expect(result, isA<MapEnterProductionDispatchV2Handled>());
      expect(v2Calls, 1);
      expect(legacyCalls, 0);
    });

    test('stale activation during Scene rolls back its candidate state',
        () async {
      const originalState = GameState(
        saveId: 'save',
        metadata: {'runtime': 'original'},
      );
      var currentState = originalState;
      final transactions = NarrativeEventStateTransactions(currentState);
      final sceneStarted = Completer<void>();
      final releaseScene = Completer<void>();
      var currentActivationId = 'activation-stale-scene';
      var committedCalls = 0;
      var legacyCalls = 0;
      final source = NarrativeEventSourceRef.mapEnter('map');
      final registry = _registry(
        EventSystemMode.v2Only,
        records: [_record(source)],
      );
      final activation = MapActivation(
        activationId: 'activation-stale-scene',
        mapId: 'map',
        reason: MapActivationReason.warp,
      );
      final bridge = _bridge(
        stateTransactions: transactions,
        currentGameState: () => currentState,
        onGameStateCommitted: (value) {
          committedCalls++;
          currentState = value;
        },
        prepareAuthority: (_, occurrence) async => _prepareAuthority(
          registry: registry,
          occurrence: occurrence,
        ),
        executeScene: (request) async {
          sceneStarted.complete();
          await releaseScene.future;
          return NarrativeSceneExecutionResult.completed(
            updatedGameState: request.gameState.copyWith(
              metadata: const {'scene': 'must-not-commit'},
            ),
            qualifiedOutcomes: const [],
          );
        },
        legacyFallback: (_, __, ___) async => legacyCalls++,
        isCurrentActivation: (value) => value == currentActivationId,
      );

      final dispatch = bridge.dispatchCompletedActivation(activation);
      await sceneStarted.future;
      currentActivationId = 'activation-newer';
      releaseScene.complete();
      final result = await dispatch;

      expect(result, isA<MapEnterProductionDispatchStale>());
      expect(await transactions.read(), originalState);
      expect(currentState, originalState);
      expect(committedCalls, 0);
      expect(legacyCalls, 0);
    });

    test('claimed but ineligible dualRead event never falls back', () async {
      var currentState = const GameState(saveId: 'save');
      final transactions = NarrativeEventStateTransactions(currentState);
      final source = NarrativeEventSourceRef.mapEnter('map');
      final provenance = LegacySourceRef.mapEvent('map', 'legacy-map-enter');
      final registry = _registry(
        EventSystemMode.dualRead,
        records: [_record(source, enabled: false)],
        claims: [_claim(source, provenance)],
      );
      var v2Calls = 0;
      var legacyCalls = 0;
      final activation = MapActivation(
        activationId: 'activation-claimed-ineligible',
        mapId: 'map',
        reason: MapActivationReason.connection,
      );
      final bridge = _bridge(
        stateTransactions: transactions,
        currentGameState: () => currentState,
        onGameStateCommitted: (value) => currentState = value,
        prepareAuthority: (_, __) async => _prepareAuthority(
          registry: registry,
          occurrence: NarrativeEventOccurrence(
            source: source,
            provenance: provenance,
          ),
          legacyClaimIndex: buildRuntimeValidatedLegacyClaimIndex(
            registry,
            runtimeEvidence: LegacyClaimRuntimeEvidence(
              entries: [
                LegacyClaimRuntimeEvidenceEntry(
                  provenance: provenance,
                  source: source,
                  sourceFingerprint: _legacyFingerprint,
                ),
              ],
            ),
          ),
        ),
        executeScene: (request) async {
          v2Calls++;
          return NarrativeSceneExecutionResult.completed(
            updatedGameState: request.gameState,
            qualifiedOutcomes: const [],
          );
        },
        legacyFallback: (_, __, ___) async => legacyCalls++,
        isCurrentActivation: (value) => value == activation.activationId,
      );

      final result = await bridge.dispatchCompletedActivation(activation);

      expect(result, isA<MapEnterProductionDispatchClaimedIneligible>());
      expect(v2Calls, 0);
      expect(legacyCalls, 0);
    });

    test('blocked or failing authority preparation stays fail-closed',
        () async {
      for (final throwsDuringPreparation in [false, true]) {
        var currentState = const GameState(saveId: 'save');
        final transactions = NarrativeEventStateTransactions(currentState);
        var legacyCalls = 0;
        final activation = MapActivation(
          activationId:
              'activation-authority-${throwsDuringPreparation ? 'error' : 'blocked'}',
          mapId: 'map',
          reason: MapActivationReason.initialBoot,
        );
        final bridge = _bridge(
          stateTransactions: transactions,
          currentGameState: () => currentState,
          onGameStateCommitted: (value) => currentState = value,
          prepareAuthority: (_, __) async {
            if (throwsDuringPreparation) {
              throw StateError('authority preparation failed');
            }
            return NarrativeEventDispatchAuthorityBlocked(
              reason:
                  NarrativeEventDispatchAuthorityBlockReason.invalidRegistry,
              diagnostics: const ['blocked fixture'],
            );
          },
          legacyFallback: (_, __, ___) async => legacyCalls++,
          isCurrentActivation: (value) => value == activation.activationId,
        );

        final result = await bridge.dispatchCompletedActivation(activation);

        expect(
          result.runtimeType,
          throwsDuringPreparation
              ? MapEnterProductionDispatchFailed
              : MapEnterProductionDispatchAuthorityBlocked,
        );
        expect(legacyCalls, 0);
      }
    });

    test('failed or cancelled Scene rolls back without legacy fallback',
        () async {
      for (final testCase in <({
        NarrativeSceneExecutionResult sceneResult,
        Type expectedResult,
      })>[
        (
          sceneResult: NarrativeSceneExecutionResult.failed('scene failed'),
          expectedResult: MapEnterProductionDispatchFailed,
        ),
        (
          sceneResult:
              NarrativeSceneExecutionResult.cancelled('scene cancelled'),
          expectedResult: MapEnterProductionDispatchNoFallback,
        ),
      ]) {
        const originalState = GameState(
          saveId: 'save',
          metadata: {'runtime': 'original'},
        );
        var currentState = originalState;
        final transactions = NarrativeEventStateTransactions(currentState);
        final source = NarrativeEventSourceRef.mapEnter('map');
        final registry = _registry(
          EventSystemMode.v2Only,
          records: [_record(source)],
        );
        var committedCalls = 0;
        var legacyCalls = 0;
        final activation = MapActivation(
          activationId: 'activation-scene-${testCase.expectedResult}',
          mapId: 'map',
          reason: MapActivationReason.initialBoot,
        );
        final bridge = _bridge(
          stateTransactions: transactions,
          currentGameState: () => currentState,
          onGameStateCommitted: (value) {
            committedCalls++;
            currentState = value;
          },
          prepareAuthority: (_, occurrence) async => _prepareAuthority(
            registry: registry,
            occurrence: occurrence,
          ),
          executeScene: (_) async => testCase.sceneResult,
          legacyFallback: (_, __, ___) async => legacyCalls++,
          isCurrentActivation: (value) => value == activation.activationId,
        );

        final result = await bridge.dispatchCompletedActivation(activation);

        expect(result.runtimeType, testCase.expectedResult);
        expect(await transactions.read(), originalState);
        expect(currentState, originalState);
        expect(committedCalls, 0);
        expect(legacyCalls, 0);
      }
    });

    test('saveRestore drains the real F1 outbox FIFO before mapEnter',
        () async {
      final trace = <String>[];
      GameState? legacyGameState;
      var currentState = GameState(
        saveId: 'save',
        narrativeEventProgress: NarrativeEventProgress(
          pendingNarrativeOutcomeDeliveries: [
            _pendingDelivery(
              _firstPendingDeliveryId,
              producerId: 'restore',
              outcomeId: 'first',
            ),
            _pendingDelivery(
              _secondPendingDeliveryId,
              producerId: 'restore',
              outcomeId: 'second',
            ),
          ],
        ),
      );
      final transactions = NarrativeEventStateTransactions(currentState);
      final activityPort = NoopNarrativeEventActivityPort();
      final processor = NarrativeOutcomeOutboxProcessor(
        stateTransactions: transactions,
        activityPort: activityPort,
        dispatcher: (request) async {
          trace.add('outcome:${request.delivery.outcome.outcomeId}');
          return NarrativeOutcomeDispatchResult.delivered(
            updatedGameState: request.gameState,
          );
        },
        deliveryIdFactory: () => _generatedDeliveryId,
      );
      final activation = MapActivation(
        activationId: 'activation-save-restore',
        mapId: 'map',
        reason: MapActivationReason.saveRestore,
      );
      final bridge = _bridge(
        stateTransactions: transactions,
        currentGameState: () => currentState,
        onGameStateCommitted: (value) => currentState = value,
        prepareAuthority: (_, occurrence) async => _prepareAuthority(
          registry: _registry(EventSystemMode.legacyOnly),
          occurrence: occurrence,
        ),
        legacyFallback: (_, __, gameState) async {
          legacyGameState = gameState;
          trace.add('mapEnter:saveRestore');
        },
        activityPort: activityPort,
        beforeSaveRestoreDispatch: (_) async {
          while (true) {
            final result = await processor.processNext();
            if (result is NarrativeOutcomeOutboxEmpty) {
              return;
            }
            expect(result, isA<NarrativeOutcomeOutboxDelivered>());
          }
        },
        isCurrentActivation: (value) => value == activation.activationId,
      );

      final result = await bridge.dispatchCompletedActivation(activation);
      final latestTransactionalState = await transactions.read();

      expect(result, isA<MapEnterProductionDispatchLegacyFallback>());
      expect(
        trace,
        ['outcome:first', 'outcome:second', 'mapEnter:saveRestore'],
      );
      expect(
        latestTransactionalState
            .narrativeEventProgress.pendingNarrativeOutcomeDeliveries,
        isEmpty,
      );
      expect(currentState, latestTransactionalState);
      expect(legacyGameState, latestTransactionalState);
    });

    test('newer activation suppresses stale saveRestore after async prehook',
        () async {
      var currentState = const GameState(saveId: 'save');
      final transactions = NarrativeEventStateTransactions(currentState);
      final hookStarted = Completer<void>();
      final releaseHook = Completer<void>();
      var currentActivationId = 'activation-stale-restore';
      var authorityCalls = 0;
      var v2Calls = 0;
      var legacyCalls = 0;
      final activation = MapActivation(
        activationId: 'activation-stale-restore',
        mapId: 'map',
        reason: MapActivationReason.saveRestore,
      );
      final bridge = _bridge(
        stateTransactions: transactions,
        currentGameState: () => currentState,
        onGameStateCommitted: (value) => currentState = value,
        prepareAuthority: (_, occurrence) async {
          authorityCalls++;
          return _prepareAuthority(
            registry: _registry(EventSystemMode.legacyOnly),
            occurrence: occurrence,
          );
        },
        executeScene: (request) async {
          v2Calls++;
          return NarrativeSceneExecutionResult.completed(
            updatedGameState: request.gameState,
            qualifiedOutcomes: const [],
          );
        },
        legacyFallback: (_, __, ___) async => legacyCalls++,
        beforeSaveRestoreDispatch: (_) async {
          hookStarted.complete();
          await releaseHook.future;
        },
        isCurrentActivation: (value) => value == currentActivationId,
      );

      final dispatch = bridge.dispatchCompletedActivation(activation);
      await hookStarted.future;
      currentActivationId = 'activation-newer-warp';
      releaseHook.complete();
      final result = await dispatch;

      expect(result, isA<MapEnterProductionDispatchStale>());
      expect(authorityCalls, 0);
      expect(v2Calls, 0);
      expect(legacyCalls, 0);
    });

    test('newer activation marks an awaited legacy fallback stale', () async {
      var currentState = const GameState(saveId: 'save');
      final transactions = NarrativeEventStateTransactions(currentState);
      final legacyStarted = Completer<void>();
      final releaseLegacy = Completer<void>();
      var currentActivationId = 'activation-stale-legacy';
      var legacyCalls = 0;
      final activation = MapActivation(
        activationId: 'activation-stale-legacy',
        mapId: 'map',
        reason: MapActivationReason.initialBoot,
      );
      final bridge = _bridge(
        stateTransactions: transactions,
        currentGameState: () => currentState,
        onGameStateCommitted: (value) => currentState = value,
        prepareAuthority: (_, occurrence) async => _prepareAuthority(
          registry: _registry(EventSystemMode.legacyOnly),
          occurrence: occurrence,
        ),
        legacyFallback: (_, __, ___) async {
          legacyCalls++;
          legacyStarted.complete();
          await releaseLegacy.future;
        },
        isCurrentActivation: (value) => value == currentActivationId,
      );

      final dispatch = bridge.dispatchCompletedActivation(activation);
      await legacyStarted.future;
      currentActivationId = 'activation-newer';
      releaseLegacy.complete();
      final result = await dispatch;

      expect(result, isA<MapEnterProductionDispatchStale>());
      expect(legacyCalls, 1);
    });

    test('stale attempts are unclaimed while the current id stays claimed',
        () async {
      var currentState = const GameState(saveId: 'save');
      final transactions = NarrativeEventStateTransactions(currentState);
      var currentActivationId = 'activation-a';
      final legacyTrace = <String>[];
      final bridge = _bridge(
        stateTransactions: transactions,
        currentGameState: () => currentState,
        onGameStateCommitted: (value) => currentState = value,
        prepareAuthority: (_, occurrence) async => _prepareAuthority(
          registry: _registry(EventSystemMode.legacyOnly),
          occurrence: occurrence,
        ),
        legacyFallback: (activation, _, __) async {
          legacyTrace.add(activation.activationId);
        },
        isCurrentActivation: (value) => value == currentActivationId,
      );
      final activationA = MapActivation(
        activationId: 'activation-a',
        mapId: 'map-a',
        reason: MapActivationReason.initialBoot,
      );
      final activationB = MapActivation(
        activationId: 'activation-b',
        mapId: 'map-b',
        reason: MapActivationReason.warp,
      );
      final staleActivation = MapActivation(
        activationId: 'activation-stale',
        mapId: 'map-stale',
        reason: MapActivationReason.connection,
      );

      expect(
        await bridge.dispatchCompletedActivation(activationA),
        isA<MapEnterProductionDispatchLegacyFallback>(),
      );
      currentActivationId = activationB.activationId;
      expect(
        await bridge.dispatchCompletedActivation(activationB),
        isA<MapEnterProductionDispatchLegacyFallback>(),
      );
      expect(
        await bridge.dispatchCompletedActivation(staleActivation),
        isA<MapEnterProductionDispatchStale>(),
      );
      expect(
        await bridge.dispatchCompletedActivation(staleActivation),
        isA<MapEnterProductionDispatchStale>(),
      );
      expect(
        await bridge.dispatchCompletedActivation(activationB),
        isA<MapEnterProductionDispatchDuplicate>(),
      );
      expect(legacyTrace, ['activation-a', 'activation-b']);
    });

    test('current activation lookup exception fails closed before claim',
        () async {
      var authorityCalls = 0;
      var legacyCalls = 0;
      final bridge = _bridge(
        stateTransactions: NarrativeEventStateTransactions(
          const GameState(saveId: 'save'),
        ),
        currentGameState: () => const GameState(saveId: 'save'),
        onGameStateCommitted: (_) {},
        prepareAuthority: (_, occurrence) async {
          authorityCalls++;
          return _prepareAuthority(
            registry: _registry(EventSystemMode.legacyOnly),
            occurrence: occurrence,
          );
        },
        legacyFallback: (_, __, ___) async => legacyCalls++,
        isCurrentActivation: (_) => throw StateError('current lookup failed'),
      );
      final activation = MapActivation(
        activationId: 'activation-current-error',
        mapId: 'map',
        reason: MapActivationReason.initialBoot,
      );

      final result = await bridge.dispatchCompletedActivation(activation);

      expect(result, isA<MapEnterProductionDispatchFailed>());
      expect(authorityCalls, 0);
      expect(legacyCalls, 0);
    });
  });
}

MapEnterProductionDispatchBridge _bridge({
  required NarrativeEventStateTransactions stateTransactions,
  required GameState Function() currentGameState,
  required void Function(GameState gameState) onGameStateCommitted,
  required Future<NarrativeEventDispatchAuthorityPreparation> Function(
    MapActivation activation,
    NarrativeEventOccurrence occurrence,
  ) prepareAuthority,
  required Future<void> Function(
    MapActivation activation,
    NarrativeEventOccurrence occurrence,
    GameState gameState,
  ) legacyFallback,
  required bool Function(String activationId) isCurrentActivation,
  NarrativeSceneExecutionCallback? executeScene,
  NarrativeEventActivityPort? activityPort,
  Future<void> Function(MapActivation activation)? beforeSaveRestoreDispatch,
}) {
  return MapEnterProductionDispatchBridge(
    stateTransactions: stateTransactions,
    currentGameState: currentGameState,
    onGameStateCommitted: onGameStateCommitted,
    prepareAuthority: prepareAuthority,
    executeScene: executeScene ??
        (request) async => NarrativeSceneExecutionResult.completed(
              updatedGameState: request.gameState,
              qualifiedOutcomes: const [],
            ),
    legacyFallback: legacyFallback,
    activityPort: activityPort ?? NoopNarrativeEventActivityPort(),
    beforeSaveRestoreDispatch: beforeSaveRestoreDispatch ?? (_) async {},
    isCurrentActivation: isCurrentActivation,
    executionIdFactory: () => _executionId,
    correlationIdFactory: () => _correlationId,
    deliveryIdFactory: () => _generatedDeliveryId,
  );
}

NarrativeEventDispatchAuthorityPreparation _prepareAuthority({
  required NarrativeEventRegistry registry,
  required NarrativeEventOccurrence occurrence,
  ValidatedLegacyClaimIndex? legacyClaimIndex,
}) {
  return NarrativeEventDispatchAuthority.prepare(
    registryResult: EventRegistryDecodeResult.decoded(registry),
    occurrence: occurrence,
    factResolver: NarrativeFactRuntimeResolver.fromFacts(const []),
    legacyClaimIndex: legacyClaimIndex,
    projectCatalog: _catalog(registry, occurrence.source),
  );
}

NarrativeEventRegistry _registry(
  EventSystemMode mode, {
  List<NarrativeEventRecord> records = const [],
  List<LegacySourceClaim> claims = const [],
}) {
  return NarrativeEventRegistry(
    schemaVersion: 1,
    mode: mode,
    records: records,
    legacyClaims: claims,
  );
}

NarrativeEventRecord _record(
  NarrativeEventSourceRef source, {
  bool enabled = true,
}) {
  return NarrativeEventRecord.configuredStructurallyUnchecked(
    NarrativeEventDefinition(
      id: _eventId,
      name: 'Map enter event',
      source: source,
      conditions: const [],
      sceneId: 'scene_map_enter',
      reusePolicy: NarrativeEventReusePolicy.reusable,
      priority: 0,
      order: 0,
    ),
    enabled: enabled,
  );
}

LegacySourceClaim _claim(
  NarrativeEventSourceRef source,
  LegacySourceRef provenance,
) {
  final member = LegacySourceClaimMember(
    provenance: provenance,
    sourceFingerprint: _legacyFingerprint,
  );
  final cohortId = computeLegacySourceCohortId(source, [provenance]);
  return LegacySourceClaim(
    cohortId: cohortId,
    source: source,
    members: [member],
    cohortFingerprint: computeLegacySourceCohortFingerprint(cohortId, [member]),
    targetEventIds: const [_eventId],
    migrationReceiptId: 'receipt',
  );
}

NarrativeEventProjectCatalog _catalog(
  NarrativeEventRegistry registry,
  NarrativeEventSourceRef source,
) {
  final mapId = source.when(
    entityInteract: (value, _) => value,
    triggerEnter: (value, _) => value,
    mapEnter: (value) => value,
    outcomeReceived: (_) => 'map',
  );
  final sceneIds = {
    for (final record in registry.records)
      if (record.definitionOrNull case final definition?) definition.sceneId,
  };
  final project = ProjectManifest(
    name: 'Map enter bridge fixture',
    maps: [
      ProjectMapEntry(
        id: mapId,
        name: mapId,
        relativePath: 'maps/$mapId.json',
      ),
    ],
    tilesets: const [],
    eventRegistry: registry,
    scenes: [for (final sceneId in sceneIds) _scene(sceneId)],
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
  return buildNarrativeEventProjectCatalog(
    project: project,
    maps: [
      MapData(
        id: mapId,
        name: mapId,
        size: const GridSize(width: 1, height: 1),
        layers: const [MapLayer.object(id: 'objects', name: 'Objects')],
      ),
    ],
  );
}

SceneAsset _scene(String id) {
  return SceneAsset.fromJson({
    'id': id,
    'name': id,
    'graph': const {
      'startNodeId': 'start',
      'nodes': [
        {'id': 'start', 'kind': 'start'},
        {'id': 'end', 'kind': 'end'},
      ],
      'edges': [
        {
          'id': 'edge',
          'fromNodeId': 'start',
          'fromPortId': 'completed',
          'toNodeId': 'end',
          'kind': 'default',
        },
      ],
    },
  });
}

NarrativeOutcomeDelivery _pendingDelivery(
  String deliveryId, {
  required String producerId,
  required String outcomeId,
}) {
  return NarrativeOutcomeDelivery(
    deliveryId: deliveryId,
    outcome: NarrativeOutcomeRef(
      producerKind: NarrativeOutcomeProducerKind.scene,
      producerId: producerId,
      outcomeId: outcomeId,
    ),
    causationExecutionId: _executionId,
    rootCorrelationId: _correlationId,
    depth: 0,
    attemptCount: 0,
  );
}
~~~~~~~~

### 25.10 `packages/map_runtime/test/narrative_scene_runtime_execution_test.dart`

~~~~~~~~dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/narrative_scene_runtime_execution.dart';

void main() {
  group('executeNarrativeEventScene', () {
    test('rebases buffered consequences onto host battle write-back', () async {
      const requestGameState = GameState(
        saveId: 'save_scene_runtime',
        party: PlayerParty(
          members: <PlayerPokemon>[
            PlayerPokemon(
              speciesId: 'sproutle',
              natureId: 'hardy',
              abilityId: 'overgrow',
              currentHp: 12,
            ),
          ],
        ),
      );
      var runtimeGameState = requestGameState;
      var battleCalls = 0;
      final hostedBattleOutcomes = <NarrativeOutcomeRef>[];

      final result = await executeNarrativeEventScene(
        request: const NarrativeSceneExecutionRequest(
          eventId: 'event_scene_runtime',
          sceneId: 'scene_battle_then_fact',
          executionId: 'execution_scene_runtime',
          gameState: requestGameState,
        ),
        project: _project(),
        mapsById: const <String, MapData>{},
        currentGameState: () => runtimeGameState,
        hostedBattleOutcomes: hostedBattleOutcomes,
        callbacks: SceneRuntimeHostCallbacks(
          evaluateCondition: (_) => throw StateError('Unexpected condition.'),
          showDialogue: (_) => throw StateError('Unexpected dialogue.'),
          startBattle: (intent) {
            battleCalls++;
            expect(intent.trainerId, 'trainer_scene_runtime');
            runtimeGameState = runtimeGameState.copyWith(
              party: PlayerParty(
                members: <PlayerPokemon>[
                  runtimeGameState.party.members.single.copyWith(currentHp: 3),
                ],
              ),
              metadata: const <String, String>{
                'battleWriteBack': 'committed',
              },
            );
            hostedBattleOutcomes.add(
              NarrativeOutcomeRef(
                producerKind: NarrativeOutcomeProducerKind.battle,
                producerId: 'trainer:trainer_scene_runtime',
                outcomeId: 'victory',
              ),
            );
            return 'victory';
          },
          playCinematic: (_) => throw StateError('Unexpected cinematic.'),
        ),
      );

      expect(
        result,
        isA<NarrativeSceneExecutionCompleted>(),
        reason: result is NarrativeSceneExecutionFailed
            ? result.failure.toString()
            : null,
      );
      final completed = result as NarrativeSceneExecutionCompleted;
      expect(battleCalls, 1);
      expect(completed.updatedGameState.party.members.single.currentHp, 3);
      expect(
        completed.updatedGameState.metadata['battleWriteBack'],
        'committed',
      );
      expect(
        completed.updatedGameState.storyFlags.activeFlags,
        contains('fact_scene_runtime_completed'),
      );
      expect(
        completed.updatedGameState.narrativeFactRuntimeState.overridesByFactId,
        containsPair('fact_scene_runtime_completed', true),
      );
      expect(
        completed.qualifiedOutcomes,
        <NarrativeOutcomeRef>[
          NarrativeOutcomeRef(
            producerKind: NarrativeOutcomeProducerKind.battle,
            producerId: 'trainer:trainer_scene_runtime',
            outcomeId: 'victory',
          ),
          NarrativeOutcomeRef(
            producerKind: NarrativeOutcomeProducerKind.scene,
            producerId: 'scene_battle_then_fact',
            outcomeId: 'scene.completed',
          ),
        ],
      );
    });

    test('fails closed on an initial GameState conflict before host callbacks',
        () async {
      const requestGameState = GameState(saveId: 'save_scene_runtime');
      final runtimeGameState = requestGameState.copyWith(
        metadata: const <String, String>{'newerRuntimeState': 'true'},
      );
      var hostCallbackCalls = 0;
      String unexpectedCallback(SceneRuntimePlanIntent _) {
        hostCallbackCalls++;
        return 'victory';
      }

      final result = await executeNarrativeEventScene(
        request: const NarrativeSceneExecutionRequest(
          eventId: 'event_scene_runtime',
          sceneId: 'scene_battle_then_fact',
          executionId: 'execution_scene_runtime',
          gameState: requestGameState,
        ),
        project: _project(),
        mapsById: const <String, MapData>{},
        currentGameState: () => runtimeGameState,
        callbacks: SceneRuntimeHostCallbacks(
          evaluateCondition: unexpectedCallback,
          showDialogue: unexpectedCallback,
          startBattle: unexpectedCallback,
          playCinematic: unexpectedCallback,
        ),
      );

      expect(result, isA<NarrativeSceneExecutionFailed>());
      final failed = result as NarrativeSceneExecutionFailed;
      expect(failed.failure, isA<StateError>());
      expect(failed.failure.toString(), contains('initial GameState conflict'));
      expect(hostCallbackCalls, 0);
    });
  });
}

ProjectManifest _project() {
  return ProjectManifest(
    name: 'Narrative Scene Runtime Execution Test',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    trainers: const <ProjectTrainerEntry>[
      ProjectTrainerEntry(
        id: 'trainer_scene_runtime',
        name: 'Runtime Trainer',
        trainerClass: 'Tester',
        team: <ProjectTrainerPokemonEntry>[
          ProjectTrainerPokemonEntry(speciesId: 'embercub', level: 5),
        ],
      ),
    ],
    facts: <NarrativeFactDefinition>[
      NarrativeFactDefinition(
        id: 'fact_scene_runtime_completed',
        label: 'Runtime scene completed',
      ),
    ],
    scenes: <SceneAsset>[_battleThenFactScene()],
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
  );
}

SceneAsset _battleThenFactScene() {
  return SceneAsset(
    id: 'scene_battle_then_fact',
    name: 'Battle then Fact',
    declaredOutcomes: <SceneOutcome>[
      SceneOutcome(id: 'scene.completed', label: 'Scene completed'),
    ],
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: <SceneNode>[
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'battle',
          kind: SceneNodeKind.battle,
          payload: SceneBattlePayload(
            battleKind: 'trainer',
            trainerId: 'trainer_scene_runtime',
            declaredOutcomes: const <String>['victory', 'defeat'],
          ),
        ),
        SceneNode(
          id: 'set_fact',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.setFact(
              factId: 'fact_scene_runtime_completed',
              value: true,
            ),
          ),
        ),
        SceneNode(
          id: 'victory_end',
          kind: SceneNodeKind.end,
          payload: SceneEndPayload(sceneOutcomeId: 'scene.completed'),
        ),
        SceneNode(id: 'defeat_end', kind: SceneNodeKind.end),
      ],
      edges: <SceneEdge>[
        SceneEdge(
          id: 'start_to_battle',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'battle',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'battle_victory_to_fact',
          fromNodeId: 'battle',
          fromPortId: 'victory',
          toNodeId: 'set_fact',
          kind: SceneEdgeKind.battleVictory,
        ),
        SceneEdge(
          id: 'fact_to_victory_end',
          fromNodeId: 'set_fact',
          fromPortId: 'completed',
          toNodeId: 'victory_end',
          kind: SceneEdgeKind.actionCompleted,
        ),
        SceneEdge(
          id: 'battle_defeat_to_end',
          fromNodeId: 'battle',
          fromPortId: 'defeat',
          toNodeId: 'defeat_end',
          kind: SceneEdgeKind.battleDefeat,
        ),
      ],
    ),
  );
}
~~~~~~~~

### 25.11 `packages/map_runtime/test/narrative_spatial_production_dispatch_bridge_test.dart`

~~~~~~~~dart
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/narrative_spatial_production_dispatch_bridge.dart';

const _eventId = 'evt_019abcde-0000-7000-8000-000000000001';
const _executionId = 'evx_019abcde-0000-7000-8000-000000000002';
const _correlationId = 'corr_019abcde-0000-7000-8000-000000000003';
const _deliveryId = 'outd_019abcde-0000-7000-8000-000000000004';
const _legacyFingerprint =
    'sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

void main() {
  group('NS-EVENT-V2-20/21 spatial production dispatch bridge', () {
    test('executes one entityInteract occurrence through Event V2', () async {
      const runtimeState = GameState(
        saveId: 'save',
        metadata: {'origin': 'runtime'},
      );
      var currentState = runtimeState;
      final transactions = NarrativeEventStateTransactions(
        const GameState(saveId: 'save', metadata: {'origin': 'stale'}),
      );
      final occurrence = NarrativeEventOccurrence(
        source: NarrativeEventSourceRef.entityInteract('map', 'npc'),
      );
      final registry = _registry(
        EventSystemMode.v2Only,
        records: [_record(occurrence.source)],
      );
      var sceneCalls = 0;
      var legacyCalls = 0;
      final bridge = _bridge(
        stateTransactions: transactions,
        currentGameState: () => currentState,
        onGameStateCommitted: (value) => currentState = value,
        prepareAuthority: (_, value) async => _prepareAuthority(
          registry: registry,
          occurrence: value,
        ),
        executeScene: (request) async {
          sceneCalls++;
          expect(request.gameState.metadata, {'origin': 'runtime'});
          return NarrativeSceneExecutionResult.completed(
            updatedGameState: request.gameState.copyWith(
              metadata: const {'origin': 'scene'},
            ),
            qualifiedOutcomes: const [],
          );
        },
        legacyFallback: (_, __, ___) async => legacyCalls++,
      );

      final result = await bridge.dispatch(
        occurrenceId: 'interaction-map-npc-1',
        occurrence: occurrence,
      );

      expect(result, isA<NarrativeSpatialProductionDispatchV2Handled>());
      expect(sceneCalls, 1);
      expect(legacyCalls, 0);
      expect(currentState.metadata, {'origin': 'scene'});
      expect(await transactions.read(), currentState);
    });

    test('supports triggerEnter and claims a concurrent occurrence once',
        () async {
      var currentState = const GameState(saveId: 'save');
      final transactions = NarrativeEventStateTransactions(currentState);
      final occurrence = NarrativeEventOccurrence(
        source: NarrativeEventSourceRef.triggerEnter('map', 'zone'),
      );
      final registry = _registry(
        EventSystemMode.v2Only,
        records: [_record(occurrence.source)],
      );
      final sceneStarted = Completer<void>();
      final releaseScene = Completer<void>();
      var sceneCalls = 0;
      final bridge = _bridge(
        stateTransactions: transactions,
        currentGameState: () => currentState,
        onGameStateCommitted: (value) => currentState = value,
        prepareAuthority: (_, value) async => _prepareAuthority(
          registry: registry,
          occurrence: value,
        ),
        executeScene: (request) async {
          sceneCalls++;
          sceneStarted.complete();
          await releaseScene.future;
          return NarrativeSceneExecutionResult.completed(
            updatedGameState: request.gameState,
            qualifiedOutcomes: const [],
          );
        },
        legacyFallback: (_, __, ___) async {},
      );

      final firstDispatch = bridge.dispatch(
        occurrenceId: 'trigger-map-zone-entry-1',
        occurrence: occurrence,
      );
      await sceneStarted.future;
      final duplicate = await bridge.dispatch(
        occurrenceId: 'trigger-map-zone-entry-1',
        occurrence: occurrence,
      );
      releaseScene.complete();
      final first = await firstDispatch;

      expect(first, isA<NarrativeSpatialProductionDispatchV2Handled>());
      expect(duplicate, isA<NarrativeSpatialProductionDispatchDuplicate>());
      expect(sceneCalls, 1);
    });

    test('falls back only for an authority-approved no-match', () async {
      for (final testCase in <({
        EventSystemMode mode,
        Type expectedResult,
        int expectedFallbackCalls,
      })>[
        (
          mode: EventSystemMode.legacyOnly,
          expectedResult: NarrativeSpatialProductionDispatchLegacyFallback,
          expectedFallbackCalls: 1,
        ),
        (
          mode: EventSystemMode.v2Only,
          expectedResult: NarrativeSpatialProductionDispatchNoFallback,
          expectedFallbackCalls: 0,
        ),
      ]) {
        var currentState = const GameState(saveId: 'save');
        final transactions = NarrativeEventStateTransactions(currentState);
        final occurrence = NarrativeEventOccurrence(
          source: NarrativeEventSourceRef.entityInteract('map', 'npc'),
        );
        var fallbackCalls = 0;
        GameState? fallbackState;
        final bridge = _bridge(
          stateTransactions: transactions,
          currentGameState: () => currentState,
          onGameStateCommitted: (value) => currentState = value,
          prepareAuthority: (_, value) async => _prepareAuthority(
            registry: _registry(testCase.mode),
            occurrence: value,
          ),
          legacyFallback: (_, value, gameState) async {
            expect(value, occurrence);
            fallbackCalls++;
            fallbackState = gameState;
          },
        );

        final result = await bridge.dispatch(
          occurrenceId: 'interaction-${testCase.mode.name}',
          occurrence: occurrence,
        );

        expect(result.runtimeType, testCase.expectedResult);
        expect(fallbackCalls, testCase.expectedFallbackCalls);
        if (testCase.expectedFallbackCalls == 1) {
          expect(fallbackState, currentState);
        }
      }
    });

    test('claimed-ineligible dualRead occurrence never falls back', () async {
      var currentState = const GameState(saveId: 'save');
      final transactions = NarrativeEventStateTransactions(currentState);
      final source = NarrativeEventSourceRef.entityInteract('map', 'npc');
      final provenance = LegacySourceRef.mapEvent('map', 'legacy-npc-event');
      final registry = _registry(
        EventSystemMode.dualRead,
        records: [_record(source, enabled: false)],
        claims: [_claim(source, provenance)],
      );
      final occurrence = NarrativeEventOccurrence(
        source: source,
        provenance: provenance,
      );
      var sceneCalls = 0;
      var fallbackCalls = 0;
      final bridge = _bridge(
        stateTransactions: transactions,
        currentGameState: () => currentState,
        onGameStateCommitted: (value) => currentState = value,
        prepareAuthority: (_, value) async => _prepareAuthority(
          registry: registry,
          occurrence: value,
          legacyClaimIndex: buildRuntimeValidatedLegacyClaimIndex(
            registry,
            runtimeEvidence: LegacyClaimRuntimeEvidence(
              entries: [
                LegacyClaimRuntimeEvidenceEntry(
                  provenance: provenance,
                  source: source,
                  sourceFingerprint: _legacyFingerprint,
                ),
              ],
            ),
          ),
        ),
        executeScene: (request) async {
          sceneCalls++;
          return NarrativeSceneExecutionResult.completed(
            updatedGameState: request.gameState,
            qualifiedOutcomes: const [],
          );
        },
        legacyFallback: (_, __, ___) async => fallbackCalls++,
      );

      final result = await bridge.dispatch(
        occurrenceId: 'interaction-claimed-ineligible',
        occurrence: occurrence,
      );

      expect(
        result,
        isA<NarrativeSpatialProductionDispatchClaimedIneligible>(),
      );
      expect(sceneCalls, 0);
      expect(fallbackCalls, 0);
    });

    test('blocked, failed, and cancelled dispatches stay fail-closed',
        () async {
      for (final testCase in <({
        String label,
        Future<NarrativeEventDispatchAuthorityPreparation> Function(
          NarrativeEventOccurrence occurrence,
        ) prepare,
        NarrativeSceneExecutionResult? sceneResult,
        Type expectedResult,
      })>[
        (
          label: 'blocked',
          prepare: (_) async => NarrativeEventDispatchAuthorityBlocked(
                reason:
                    NarrativeEventDispatchAuthorityBlockReason.invalidRegistry,
                diagnostics: const ['blocked fixture'],
              ),
          sceneResult: null,
          expectedResult: NarrativeSpatialProductionDispatchAuthorityBlocked,
        ),
        (
          label: 'failed',
          prepare: (occurrence) async => _prepareAuthority(
                registry: _registry(
                  EventSystemMode.v2Only,
                  records: [_record(occurrence.source)],
                ),
                occurrence: occurrence,
              ),
          sceneResult: NarrativeSceneExecutionResult.failed('scene failed'),
          expectedResult: NarrativeSpatialProductionDispatchFailed,
        ),
        (
          label: 'cancelled',
          prepare: (occurrence) async => _prepareAuthority(
                registry: _registry(
                  EventSystemMode.v2Only,
                  records: [_record(occurrence.source)],
                ),
                occurrence: occurrence,
              ),
          sceneResult:
              NarrativeSceneExecutionResult.cancelled('scene cancelled'),
          expectedResult: NarrativeSpatialProductionDispatchNoFallback,
        ),
      ]) {
        var currentState = const GameState(saveId: 'save');
        final transactions = NarrativeEventStateTransactions(currentState);
        final occurrence = NarrativeEventOccurrence(
          source: NarrativeEventSourceRef.entityInteract('map', 'npc'),
        );
        var fallbackCalls = 0;
        var committedCalls = 0;
        final bridge = _bridge(
          stateTransactions: transactions,
          currentGameState: () => currentState,
          onGameStateCommitted: (value) {
            committedCalls++;
            currentState = value;
          },
          prepareAuthority: (_, value) => testCase.prepare(value),
          executeScene: (_) async => testCase.sceneResult!,
          legacyFallback: (_, __, ___) async => fallbackCalls++,
        );

        final result = await bridge.dispatch(
          occurrenceId: 'interaction-${testCase.label}',
          occurrence: occurrence,
        );

        expect(result.runtimeType, testCase.expectedResult);
        expect(fallbackCalls, 0);
        expect(committedCalls, 0);
      }
    });

    test('stale occurrence during Scene rolls back and can be reclaimed',
        () async {
      const originalState = GameState(
        saveId: 'save',
        metadata: {'origin': 'runtime'},
      );
      var currentState = originalState;
      final transactions = NarrativeEventStateTransactions(currentState);
      final occurrence = NarrativeEventOccurrence(
        source: NarrativeEventSourceRef.triggerEnter('map', 'zone'),
      );
      final registry = _registry(
        EventSystemMode.v2Only,
        records: [_record(occurrence.source)],
      );
      final sceneStarted = Completer<void>();
      final releaseScene = Completer<void>();
      var isCurrent = true;
      var sceneCalls = 0;
      var committedCalls = 0;
      final bridge = _bridge(
        stateTransactions: transactions,
        currentGameState: () => currentState,
        onGameStateCommitted: (value) {
          committedCalls++;
          currentState = value;
        },
        prepareAuthority: (_, value) async => _prepareAuthority(
          registry: registry,
          occurrence: value,
        ),
        executeScene: (request) async {
          sceneCalls++;
          if (sceneCalls == 1) {
            sceneStarted.complete();
            await releaseScene.future;
          }
          return NarrativeSceneExecutionResult.completed(
            updatedGameState: request.gameState.copyWith(
              metadata: {'sceneCall': '$sceneCalls'},
            ),
            qualifiedOutcomes: const [],
          );
        },
        legacyFallback: (_, __, ___) async {},
        isCurrentOccurrence: (_) => isCurrent,
      );

      final staleDispatch = bridge.dispatch(
        occurrenceId: 'trigger-stale-reclaimable',
        occurrence: occurrence,
      );
      await sceneStarted.future;
      isCurrent = false;
      releaseScene.complete();
      final staleResult = await staleDispatch;

      expect(staleResult, isA<NarrativeSpatialProductionDispatchStale>());
      expect(await transactions.read(), originalState);
      expect(currentState, originalState);
      expect(committedCalls, 0);

      isCurrent = true;
      final retry = await bridge.dispatch(
        occurrenceId: 'trigger-stale-reclaimable',
        occurrence: occurrence,
      );

      expect(retry, isA<NarrativeSpatialProductionDispatchV2Handled>());
      expect(sceneCalls, 2);
      expect(committedCalls, 1);
    });

    test('stale legacy fallback does not open a second dispatch path',
        () async {
      var currentState = const GameState(saveId: 'save');
      final transactions = NarrativeEventStateTransactions(currentState);
      final occurrence = NarrativeEventOccurrence(
        source: NarrativeEventSourceRef.entityInteract('map', 'npc'),
      );
      final fallbackStarted = Completer<void>();
      final releaseFallback = Completer<void>();
      var isCurrent = true;
      var fallbackCalls = 0;
      final bridge = _bridge(
        stateTransactions: transactions,
        currentGameState: () => currentState,
        onGameStateCommitted: (value) => currentState = value,
        prepareAuthority: (_, value) async => _prepareAuthority(
          registry: _registry(EventSystemMode.legacyOnly),
          occurrence: value,
        ),
        legacyFallback: (_, __, ___) async {
          fallbackCalls++;
          fallbackStarted.complete();
          await releaseFallback.future;
        },
        isCurrentOccurrence: (_) => isCurrent,
      );

      final dispatch = bridge.dispatch(
        occurrenceId: 'interaction-stale-fallback',
        occurrence: occurrence,
      );
      await fallbackStarted.future;
      isCurrent = false;
      releaseFallback.complete();
      final result = await dispatch;

      expect(result, isA<NarrativeSpatialProductionDispatchStale>());
      expect(fallbackCalls, 1);
    });

    test('invalid ids and non-spatial sources fail before host callbacks',
        () async {
      var authorityCalls = 0;
      var fallbackCalls = 0;
      final bridge = _bridge(
        stateTransactions: NarrativeEventStateTransactions(
          const GameState(saveId: 'save'),
        ),
        currentGameState: () => const GameState(saveId: 'save'),
        onGameStateCommitted: (_) {},
        prepareAuthority: (_, occurrence) async {
          authorityCalls++;
          return _prepareAuthority(
            registry: _registry(EventSystemMode.legacyOnly),
            occurrence: occurrence,
          );
        },
        legacyFallback: (_, __, ___) async => fallbackCalls++,
      );

      final invalidId = await bridge.dispatch(
        occurrenceId: '  ',
        occurrence: NarrativeEventOccurrence(
          source: NarrativeEventSourceRef.entityInteract('map', 'npc'),
        ),
      );
      final invalidSource = await bridge.dispatch(
        occurrenceId: 'map-enter-is-not-spatial',
        occurrence: NarrativeEventOccurrence(
          source: NarrativeEventSourceRef.mapEnter('map'),
        ),
      );

      expect(invalidId, isA<NarrativeSpatialProductionDispatchFailed>());
      expect(invalidSource, isA<NarrativeSpatialProductionDispatchFailed>());
      expect(authorityCalls, 0);
      expect(fallbackCalls, 0);
    });
  });
}

NarrativeSpatialProductionDispatchBridge _bridge({
  required NarrativeEventStateTransactions stateTransactions,
  required GameState Function() currentGameState,
  required void Function(GameState gameState) onGameStateCommitted,
  required Future<NarrativeEventDispatchAuthorityPreparation> Function(
    String occurrenceId,
    NarrativeEventOccurrence occurrence,
  ) prepareAuthority,
  required Future<void> Function(
    String occurrenceId,
    NarrativeEventOccurrence occurrence,
    GameState gameState,
  ) legacyFallback,
  NarrativeSceneExecutionCallback? executeScene,
  bool Function(String occurrenceId)? isCurrentOccurrence,
}) {
  return NarrativeSpatialProductionDispatchBridge(
    stateTransactions: stateTransactions,
    currentGameState: currentGameState,
    onGameStateCommitted: onGameStateCommitted,
    prepareAuthority: prepareAuthority,
    executeScene: executeScene ??
        (request) async => NarrativeSceneExecutionResult.completed(
              updatedGameState: request.gameState,
              qualifiedOutcomes: const [],
            ),
    legacyFallback: legacyFallback,
    activityPort: NoopNarrativeEventActivityPort(),
    isCurrentOccurrence: isCurrentOccurrence ?? (_) => true,
    executionIdFactory: () => _executionId,
    correlationIdFactory: () => _correlationId,
    deliveryIdFactory: () => _deliveryId,
  );
}

NarrativeEventDispatchAuthorityPreparation _prepareAuthority({
  required NarrativeEventRegistry registry,
  required NarrativeEventOccurrence occurrence,
  ValidatedLegacyClaimIndex? legacyClaimIndex,
}) {
  return NarrativeEventDispatchAuthority.prepare(
    registryResult: EventRegistryDecodeResult.decoded(registry),
    occurrence: occurrence,
    factResolver: NarrativeFactRuntimeResolver.fromFacts(const []),
    legacyClaimIndex: legacyClaimIndex,
    projectCatalog: _catalog(registry, occurrence.source),
  );
}

NarrativeEventRegistry _registry(
  EventSystemMode mode, {
  List<NarrativeEventRecord> records = const [],
  List<LegacySourceClaim> claims = const [],
}) {
  return NarrativeEventRegistry(
    schemaVersion: 1,
    mode: mode,
    records: records,
    legacyClaims: claims,
  );
}

NarrativeEventRecord _record(
  NarrativeEventSourceRef source, {
  bool enabled = true,
}) {
  return NarrativeEventRecord.configuredStructurallyUnchecked(
    NarrativeEventDefinition(
      id: _eventId,
      name: 'Spatial event',
      source: source,
      conditions: const [],
      sceneId: 'scene_spatial',
      reusePolicy: NarrativeEventReusePolicy.reusable,
      priority: 0,
      order: 0,
    ),
    enabled: enabled,
  );
}

LegacySourceClaim _claim(
  NarrativeEventSourceRef source,
  LegacySourceRef provenance,
) {
  final member = LegacySourceClaimMember(
    provenance: provenance,
    sourceFingerprint: _legacyFingerprint,
  );
  final cohortId = computeLegacySourceCohortId(source, [provenance]);
  return LegacySourceClaim(
    cohortId: cohortId,
    source: source,
    members: [member],
    cohortFingerprint: computeLegacySourceCohortFingerprint(cohortId, [member]),
    targetEventIds: const [_eventId],
    migrationReceiptId: 'receipt',
  );
}

NarrativeEventProjectCatalog _catalog(
  NarrativeEventRegistry registry,
  NarrativeEventSourceRef source,
) {
  final spatialOwner = source.when<
      ({
        String mapId,
        MapEntity? entity,
        MapTrigger? trigger,
      })>(
    entityInteract: (mapId, entityId) => (
      mapId: mapId,
      entity: MapEntity(
        id: entityId,
        name: entityId,
        kind: MapEntityKind.custom,
        pos: const GridPos(x: 0, y: 0),
      ),
      trigger: null,
    ),
    triggerEnter: (mapId, triggerId) => (
      mapId: mapId,
      entity: null,
      trigger: MapTrigger(
        id: triggerId,
        name: triggerId,
        type: TriggerType.event,
        area: const MapRect(
          pos: GridPos(x: 0, y: 0),
          size: GridSize(width: 1, height: 1),
        ),
      ),
    ),
    mapEnter: (mapId) => (mapId: mapId, entity: null, trigger: null),
    outcomeReceived: (_) => (mapId: 'map', entity: null, trigger: null),
  );
  final sceneIds = {
    for (final record in registry.records)
      if (record.definitionOrNull case final definition?) definition.sceneId,
  };
  final project = ProjectManifest(
    name: 'Spatial bridge fixture',
    maps: [
      ProjectMapEntry(
        id: spatialOwner.mapId,
        name: spatialOwner.mapId,
        relativePath: 'maps/${spatialOwner.mapId}.json',
      ),
    ],
    tilesets: const [],
    eventRegistry: registry,
    scenes: [for (final sceneId in sceneIds) _scene(sceneId)],
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
  return buildNarrativeEventProjectCatalog(
    project: project,
    maps: [
      MapData(
        id: spatialOwner.mapId,
        name: spatialOwner.mapId,
        size: const GridSize(width: 2, height: 2),
        layers: const [MapLayer.object(id: 'objects', name: 'Objects')],
        entities: [if (spatialOwner.entity case final entity?) entity],
        triggers: [if (spatialOwner.trigger case final trigger?) trigger],
      ),
    ],
  );
}

SceneAsset _scene(String id) {
  return SceneAsset.fromJson({
    'id': id,
    'name': id,
    'graph': const {
      'startNodeId': 'start',
      'nodes': [
        {'id': 'start', 'kind': 'start'},
        {'id': 'end', 'kind': 'end'},
      ],
      'edges': [
        {
          'id': 'edge',
          'fromNodeId': 'start',
          'fromPortId': 'completed',
          'toNodeId': 'end',
          'kind': 'default',
        },
      ],
    },
  });
}
~~~~~~~~

### 25.12 `packages/map_runtime/test/playable_map_game_checkpoint_load_safety_integration_test.dart`

~~~~~~~~dart
import 'dart:async';
import 'dart:ui' show Color;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/dialogue_runtime_models.dart';
import 'package:map_runtime/src/application/narrative_runtime_activity_gate.dart';
import 'package:map_runtime/src/application/runtime_battle_outcome_apply.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';
import 'package:map_runtime/src/presentation/flame/playable_map_game.dart'
    show
        RuntimeDialogueSessionLoader,
        RuntimeMapBundleLoader,
        RuntimeTilesetImageLoader;

import 'surface/surface_runtime_test_support.dart' show runtimeTilesetImage;

const _sourceMapId = 'checkpoint_source';
const _restoredMapId = 'checkpoint_restored';
const _legacyBlockedFlag = 'legacy.must_not_run_during_checkpoint';
const _staleScriptFlag = 'script.must_not_resume_after_load';
const _staleCutsceneFlag = 'cutscene.must_not_resume_after_checkpoint';
const _followScenarioId = 'legacy_follow_before_load';
const _trainerId = 'checkpoint_trainer';

const _battleStats = BattleStatsSnapshot(
  attack: 10,
  defense: 10,
  specialAttack: 10,
  specialDefense: 10,
  speed: 10,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlayableMapGame checkpoint/load safety', () {
    test(
      'checkpoint already in progress refuses an atomic Cutscene start',
      () async {
        final gate = NarrativeRuntimeActivityGate();
        final game = _game(
          bundle: _bundle(map: _plainMap(_sourceMapId)),
          initialState: _state(mapId: _sourceMapId),
          narrativeRuntimeActivityGate: gate,
        );
        await _load(game);

        final checkpointStarted = Completer<void>();
        final releaseCheckpoint = Completer<void>();
        final checkpoint = gate.runCheckpoint<void>(
          NarrativeRuntimeCheckpointOperation.save,
          () async {
            checkpointStarted.complete();
            await releaseCheckpoint.future;
          },
        );
        await checkpointStarted.future;

        expect(
          game.startCutscene(_waitThenFlagCutscene('checkpoint_refused')),
          isFalse,
        );
        game.update(20);
        expect(game.isCutsceneRunning, isFalse);
        expect(
          game.gameStateSnapshot.storyFlags.activeFlags,
          isNot(contains(_staleCutsceneFlag)),
        );

        releaseCheckpoint.complete();
        await checkpoint;
        expect(gate.activity, NarrativeRuntimeActivity.idle);
      },
    );

    for (final fixture in <({
      String name,
      RuntimeCutsceneAsset cutscene,
      List<ProjectDialogueEntry> dialogues,
      RuntimeDialogueSessionLoader? dialogueLoader,
    })>[
      (
        name: 'wait',
        cutscene: _waitThenFlagCutscene('wait_before_load'),
        dialogues: const <ProjectDialogueEntry>[],
        dialogueLoader: null,
      ),
      (
        name: 'choice',
        cutscene: const RuntimeCutsceneAsset(
          id: 'choice_before_load',
          name: 'Choice before load',
          steps: <RuntimeCutsceneStep>[
            CutsceneChoiceStep(
              choiceId: 'checkpoint_choice',
              prompt: 'Choose',
              options: <CutsceneChoiceOption>[
                CutsceneChoiceOption(value: 'yes', label: 'Yes'),
              ],
            ),
            CutsceneSetFlagStep(flagName: _staleCutsceneFlag),
          ],
        ),
        dialogues: const <ProjectDialogueEntry>[],
        dialogueLoader: null,
      ),
      (
        name: 'dialogue',
        cutscene: const RuntimeCutsceneAsset(
          id: 'dialogue_before_load',
          name: 'Dialogue before load',
          steps: <RuntimeCutsceneStep>[
            CutsceneDialogueStep(dialogueId: 'cutscene_dialogue'),
            CutsceneSetFlagStep(flagName: _staleCutsceneFlag),
          ],
        ),
        dialogues: const <ProjectDialogueEntry>[
          ProjectDialogueEntry(
            id: 'cutscene_dialogue',
            name: 'Cutscene dialogue',
            relativePath: 'dialogues/cutscene_dialogue.yarn',
          ),
        ],
        dialogueLoader: (_) async => _singleLineDialogue(),
      ),
    ]) {
      test(
        '${fixture.name} Cutscene owns sceneSuspended, blocks checkpoints and '
        'cannot mutate after cancellation/load',
        () async {
          final gate = NarrativeRuntimeActivityGate();
          final repository = _GateMemoryRepository(gate)
            ..storedState = _state(
              mapId: _sourceMapId,
              position: const GridPos(x: 2, y: 2),
            );
          final game = _game(
            bundle: _bundle(
              map: _plainMap(_sourceMapId),
              dialogues: fixture.dialogues,
            ),
            initialState: _state(mapId: _sourceMapId),
            narrativeRuntimeActivityGate: gate,
            saveRepository: repository,
            dialogueSessionLoader: fixture.dialogueLoader,
          );
          await _load(game);

          expect(game.startCutscene(fixture.cutscene), isTrue);
          game.update(0.016);
          await Future<void>.delayed(Duration.zero);

          expect(game.isCutsceneRunning, isTrue);
          expect(gate.activity, NarrativeRuntimeActivity.sceneSuspended);
          if (fixture.name == 'choice') {
            expect(game.hasPendingCutsceneChoice, isTrue);
          }
          expect(await game.saveGame(), isFalse);
          expect(await game.loadGame(), isFalse);
          expect(repository.saveCount, 0);
          expect(repository.loadCount, 0);

          expect(game.cancelCutscene(), isTrue);
          expect(game.isCutsceneRunning, isFalse);
          expect(game.pendingCutsceneChoiceRequest, isNull);
          expect(gate.activity, NarrativeRuntimeActivity.idle);

          expect(await game.loadGame(), isTrue);
          for (var i = 0; i < 8; i++) {
            game.update(1);
            await Future<void>.delayed(Duration.zero);
          }
          final state = game.gameStateSnapshot;
          expect(state.playerPosition, const GridPos(x: 2, y: 2));
          expect(
            state.storyFlags.activeFlags,
            isNot(contains(_staleCutsceneFlag)),
          );
          expect(game.isCutsceneRunning, isFalse);
        },
      );
    }

    test(
      'battle handoff blocks load until async setup terminates',
      () async {
        final gate = NarrativeRuntimeActivityGate();
        final repository = _GateMemoryRepository(gate)
          ..storedState = _state(
            mapId: _sourceMapId,
            position: const GridPos(x: 3, y: 3),
          );
        final setupStarted = Completer<void>();
        final releaseSetup = Completer<void>();
        final game = _game(
          bundle: _sceneBundle(),
          initialState: _battleReadyState(),
          narrativeRuntimeActivityGate: gate,
          saveRepository: repository,
          beforeBattleHandoffPreparation: () async {
            setupStarted.complete();
            await releaseSetup.future;
          },
        );
        await _load(game);

        final handoff = game.debugOpenBattleForTest(_trainerContext().request);
        await setupStarted.future;

        expect(game.debugFlowPhaseName, 'battleTransition');
        expect(await game.saveGame(), isFalse);
        expect(await game.loadGame(), isFalse);
        expect(repository.saveCount, 0);
        expect(repository.loadCount, 0);

        releaseSetup.complete();
        await handoff;
        expect(game.debugFlowPhaseName, isNot('battleTransition'));
        expect(game.gameStateSnapshot.currentMapId, _sourceMapId);
        expect(
          game.gameStateSnapshot.playerPosition,
          isNot(const GridPos(x: 3, y: 3)),
        );
      },
    );

    test(
      'Cutscene outcome source is refused while a checkpoint owns the '
      'narrative gate',
      () async {
        final gate = NarrativeRuntimeActivityGate();
        final game = _game(
          bundle: _bundle(
            map: _plainMap(_sourceMapId),
            scenarios: <ScenarioAsset>[_outcomeFlagScenario()],
          ),
          initialState: _state(mapId: _sourceMapId),
          narrativeRuntimeActivityGate: gate,
        );
        await _load(game);

        final checkpointStarted = Completer<void>();
        final releaseCheckpoint = Completer<void>();
        final checkpoint = gate.runCheckpoint<void>(
          NarrativeRuntimeCheckpointOperation.load,
          () async {
            checkpointStarted.complete();
            await releaseCheckpoint.future;
          },
        );
        await checkpointStarted.future;

        expect(
          game.startCutscene(
            const RuntimeCutsceneAsset(
              id: 'emit_during_checkpoint',
              name: 'Emit during checkpoint',
              steps: <RuntimeCutsceneStep>[
                CutsceneEmitOutcomeStep(outcomeId: 'checkpoint.seed'),
              ],
            ),
          ),
          isFalse,
        );
        expect(() => game.update(0.016), returnsNormally);

        expect(gate.checkpointInProgress, isTrue);
        expect(game.isCutsceneRunning, isFalse);
        expect(
          game.gameStateSnapshot.storyFlags.activeFlags,
          isNot(contains(_legacyBlockedFlag)),
        );

        releaseCheckpoint.complete();
        await checkpoint;
        expect(gate.activity, NarrativeRuntimeActivity.idle);
      },
    );

    test(
      'successful load discards queued Scenario completion and follow work '
      'before the restored state can be mutated',
      () async {
        final gate = NarrativeRuntimeActivityGate();
        final restoredState = _state(
          mapId: _restoredMapId,
          position: const GridPos(x: 1, y: 1),
        );
        final repository = _GateMemoryRepository(gate)
          ..storedState = restoredState;
        final restoredBundle = _bundle(map: _plainMap(_restoredMapId));
        final game = _game(
          bundle: _bundle(
            map: _followMap(),
            scenarios: <ScenarioAsset>[_mapEnterFollowScenario()],
          ),
          initialState: _state(mapId: _sourceMapId),
          narrativeRuntimeActivityGate: gate,
          saveRepository: repository,
          runtimeMapBundleLoader: ({required projectFilePath, required mapId}) {
            expect(mapId, _restoredMapId);
            return Future<RuntimeMapBundle>.value(restoredBundle);
          },
        );
        await _load(game);
        expect(game.debugHasActiveScenarioFollow, isTrue);

        expect(await game.loadGame(), isTrue);
        expect(
          game.debugHasActiveScenarioFollow,
          isFalse,
          reason: 'A successful load must purge the old map follow owner.',
        );
        for (var i = 0; i < 80; i++) {
          game.update(0.016);
          await Future<void>.delayed(Duration.zero);
        }

        final state = game.gameStateSnapshot;
        expect(state.currentMapId, _restoredMapId);
        expect(state.progression.completedCutsceneIds, isEmpty);
        expect(
          state.storyFlags.activeFlags,
          isNot(contains(scenarioOutcomeFlagName(_followScenarioId))),
        );
        expect(game.debugHasActiveScenarioFollow, isFalse);
        expect(game.debugHasPendingLeaderWarpHandoff, isFalse);
      },
    );

    test(
      'successful load purges an old-map Scenario NPC warp entry',
      () async {
        final gate = NarrativeRuntimeActivityGate();
        final repository = _GateMemoryRepository(gate)
          ..storedState = _state(mapId: _restoredMapId);
        final restoredBundle = _bundle(map: _plainMap(_restoredMapId));
        final game = _game(
          bundle: _leaderWarpBundle(),
          initialState: _state(mapId: _sourceMapId),
          narrativeRuntimeActivityGate: gate,
          saveRepository: repository,
          runtimeTilesetImageLoader: _leaderTilesetLoader,
          runtimeMapBundleLoader: ({required projectFilePath, required mapId}) {
            expect(mapId, _restoredMapId);
            return Future<RuntimeMapBundle>.value(restoredBundle);
          },
        );
        await _load(game);

        expect(
          game.debugRunScenarioMoveCharacterToWarp(
            entityId: 'leader',
            warpId: 'leader_exit',
          ),
          isTrue,
        );
        expect(game.debugPendingScenarioNpcWarpEntryCount, 1);

        expect(await game.loadGame(), isTrue);

        expect(game.debugPendingScenarioNpcWarpEntryCount, 0);
        expect(game.gameStateSnapshot.currentMapId, _restoredMapId);
      },
    );

    test(
      'successful load purges a leader warp handoff and its active follow',
      () async {
        final gate = NarrativeRuntimeActivityGate();
        final repository = _GateMemoryRepository(gate)
          ..storedState = _state(mapId: _restoredMapId);
        final restoredBundle = _bundle(map: _plainMap(_restoredMapId));
        final game = _game(
          bundle: _leaderWarpBundle(),
          initialState: _state(mapId: _sourceMapId),
          narrativeRuntimeActivityGate: gate,
          saveRepository: repository,
          runtimeTilesetImageLoader: _leaderTilesetLoader,
          runtimeMapBundleLoader: ({required projectFilePath, required mapId}) {
            expect(mapId, _restoredMapId);
            return Future<RuntimeMapBundle>.value(restoredBundle);
          },
        );
        await _load(game);

        expect(game.debugStartScenarioFollow('leader'), isTrue);
        expect(
          game.debugRunScenarioMoveCharacterToWarp(
            entityId: 'leader',
            warpId: 'leader_exit',
          ),
          isTrue,
        );
        await _waitUntil(game, () => game.debugHasPendingLeaderWarpHandoff);
        expect(game.debugHasActiveScenarioFollow, isTrue);

        expect(await game.loadGame(), isTrue);

        expect(game.debugHasPendingLeaderWarpHandoff, isFalse);
        expect(game.debugHasActiveScenarioFollow, isFalse);
        expect(game.gameStateSnapshot.currentMapId, _restoredMapId);
      },
    );

    test(
      'transient reset prevents a pre-load script dialogue continuation from '
      'resuming through a later Surf rejection',
      () async {
        final gate = NarrativeRuntimeActivityGate();
        final repository = _GateMemoryRepository(gate)
          ..storedState = _surfState(
            facing: EntityFacing.east,
            mapId: _sourceMapId,
          );
        final game = _game(
          bundle: _scriptAndWaterBundle(),
          initialState: _surfState(
            facing: EntityFacing.south,
            mapId: _sourceMapId,
          ),
          narrativeRuntimeActivityGate: gate,
          saveRepository: repository,
          dialogueSessionLoader: (_) async => _singleLineDialogue(),
        );
        await _load(game);
        game.debugSetPlayerStateForTest(
          position: const GridPos(x: 0, y: 0),
          facing: Direction.south,
        );

        expect(_press(game, RuntimeInputControl.primary), isTrue);
        await _waitUntil(game, () => game.debugFlowPhaseName == 'dialogue');

        expect(await game.loadGame(), isTrue);
        expect(game.debugFlowPhaseName, 'overworld');
        game.debugSetPlayerStateForTest(
          position: const GridPos(x: 0, y: 0),
          facing: Direction.east,
        );

        await _attemptStep(game, RuntimeInputControl.right);
        expect(game.debugFlowPhaseName, 'dialogue');
        expect(_press(game, RuntimeInputControl.primary), isTrue);
        expect(_press(game, RuntimeInputControl.down), isTrue);
        expect(_press(game, RuntimeInputControl.primary), isTrue);
        await Future<void>.delayed(Duration.zero);

        expect(game.playerMovementMode, MovementMode.walk);
        expect(
          game.gameStateSnapshot.storyFlags.activeFlags,
          isNot(contains(_staleScriptFlag)),
        );
      },
    );

    test(
      'transient reset prevents a pre-load Surf confirmation from leaking '
      'into an unrelated later choice',
      () async {
        final gate = NarrativeRuntimeActivityGate();
        final repository = _GateMemoryRepository(gate)
          ..storedState = _surfState(
            facing: EntityFacing.south,
            mapId: _sourceMapId,
          );
        final game = _game(
          bundle: _choiceNpcAndWaterBundle(),
          initialState: _surfState(
            facing: EntityFacing.east,
            mapId: _sourceMapId,
          ),
          narrativeRuntimeActivityGate: gate,
          saveRepository: repository,
          dialogueSessionLoader: (_) async => _choiceDialogue(),
        );
        await _load(game);
        game.debugSetPlayerStateForTest(
          position: const GridPos(x: 0, y: 0),
          facing: Direction.east,
        );

        await _attemptStep(game, RuntimeInputControl.right);
        expect(game.debugFlowPhaseName, 'dialogue');

        expect(await game.loadGame(), isTrue);
        expect(game.playerMovementMode, MovementMode.walk);
        game.debugSetPlayerStateForTest(
          position: const GridPos(x: 0, y: 0),
          facing: Direction.south,
        );

        expect(_press(game, RuntimeInputControl.primary), isTrue);
        await _waitUntil(game, () => game.debugFlowPhaseName == 'dialogue');
        expect(_press(game, RuntimeInputControl.primary), isTrue);

        expect(game.debugFlowPhaseName, 'overworld');
        expect(game.playerMovementMode, MovementMode.walk);
      },
    );

    test(
      'direct MapEvent Scene holds sceneActive through dialogue and hosted '
      'Battle then releases it terminally',
      () async {
        final gate = NarrativeRuntimeActivityGate();
        final repository = _GateMemoryRepository(gate)
          ..storedState = _battleReadyState();
        final game = _game(
          bundle: _sceneBundle(),
          initialState: _battleReadyState(),
          narrativeRuntimeActivityGate: gate,
          saveRepository: repository,
          dialogueSessionLoader: (_) async => _singleLineDialogue(),
        );
        await _load(game);

        expect(_press(game, RuntimeInputControl.primary), isTrue);
        await _waitUntilWithoutUpdate(
          () => game.debugFlowPhaseName == 'dialogue',
        );

        expect(gate.activity, NarrativeRuntimeActivity.sceneActive);
        expect(await game.saveGame(), isFalse);
        expect(await game.loadGame(), isFalse);
        expect(repository.saveCount, 0);
        expect(repository.loadCount, 0);

        expect(_press(game, RuntimeInputControl.primary), isTrue);
        await _waitUntilWithoutUpdate(() => game.debugHasPendingSceneBattle);

        expect(gate.activity, NarrativeRuntimeActivity.sceneActive);
        expect(await game.saveGame(), isFalse);
        expect(await game.loadGame(), isFalse);
        expect(repository.saveCount, 0);
        expect(repository.loadCount, 0);

        game.debugApplyBattleOutcomeForTest(
          context: _trainerContext(),
          outcome: _victoryOutcome(),
        );
        await _waitUntilWithoutUpdate(
          () => gate.activity == NarrativeRuntimeActivity.idle,
        );

        expect(await game.saveGame(), isTrue);
        expect(repository.saveCount, 1);
      },
    );
  });
}

PlayableMapGame _game({
  required RuntimeMapBundle bundle,
  required GameState initialState,
  NarrativeRuntimeActivityGate? narrativeRuntimeActivityGate,
  GameSaveRepository? saveRepository,
  RuntimeDialogueSessionLoader? dialogueSessionLoader,
  RuntimeMapBundleLoader? runtimeMapBundleLoader,
  RuntimeTilesetImageLoader? runtimeTilesetImageLoader,
  Future<void> Function()? beforeBattleHandoffPreparation,
}) {
  return _TestPlayableMapGame(
    bundle: bundle,
    projectFilePath: '/tmp/checkpoint_load_safety/project.json',
    saveData: saveDataFromGameState(initialState),
    narrativeRuntimeActivityGate: narrativeRuntimeActivityGate,
    saveRepository: saveRepository,
    dialogueSessionLoader: dialogueSessionLoader,
    runtimeMapBundleLoader: runtimeMapBundleLoader,
    runtimeTilesetImageLoader: runtimeTilesetImageLoader,
    beforeBattleHandoffPreparation: beforeBattleHandoffPreparation,
  );
}

final class _TestPlayableMapGame extends PlayableMapGame {
  _TestPlayableMapGame({
    required super.bundle,
    required super.projectFilePath,
    super.saveData,
    super.narrativeRuntimeActivityGate,
    super.saveRepository,
    super.dialogueSessionLoader,
    super.runtimeMapBundleLoader,
    super.runtimeTilesetImageLoader,
    super.beforeBattleHandoffPreparation,
  });

  @override
  bool get isLoaded => true;
}

Future<void> _load(PlayableMapGame game) async {
  game.onGameResize(Vector2(320, 240));
  await game.onLoad();
  await _waitUntilWithoutUpdate(
    () => !game.debugIsMapActivationDispatchInFlight,
  );
}

bool _press(PlayableMapGame game, RuntimeInputControl control) {
  return game.handleRuntimeInputEvent(RuntimeInputEvent.press(control));
}

Future<void> _attemptStep(
  PlayableMapGame game,
  RuntimeInputControl control,
) async {
  expect(_press(game, control), isTrue);
  game.update(0.016);
  await Future<void>.delayed(Duration.zero);
  expect(
    game.handleRuntimeInputEvent(RuntimeInputEvent.release(control)),
    isTrue,
  );
}

Future<void> _waitUntil(
  PlayableMapGame game,
  bool Function() done, {
  int maxTicks = 360,
}) async {
  for (var i = 0; i < maxTicks; i++) {
    if (done()) return;
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
  }
  fail(
    'Timed out: flow=${game.debugFlowPhaseName} '
    'activation=${game.debugIsMapActivationDispatchInFlight}.',
  );
}

Future<void> _waitUntilWithoutUpdate(
  bool Function() done, {
  int maxTurns = 360,
}) async {
  for (var i = 0; i < maxTurns; i++) {
    if (done()) return;
    await Future<void>.delayed(Duration.zero);
  }
  fail('Timed out waiting for an asynchronous runtime condition.');
}

RuntimeMapBundle _bundle({
  required MapData map,
  List<ScenarioAsset> scenarios = const <ScenarioAsset>[],
  List<ProjectDialogueEntry> dialogues = const <ProjectDialogueEntry>[],
  List<ProjectScriptEntry> scripts = const <ProjectScriptEntry>[],
  List<ProjectTrainerEntry> trainers = const <ProjectTrainerEntry>[],
  List<SceneAsset> scenes = const <SceneAsset>[],
  List<ProjectPathPreset> pathPresets = const <ProjectPathPreset>[],
}) {
  return RuntimeMapBundle(
    manifest: ProjectManifest(
      name: 'Checkpoint Load Safety',
      maps: <ProjectMapEntry>[
        ProjectMapEntry(
          id: map.id,
          name: map.name,
          relativePath: 'maps/${map.id}.json',
        ),
      ],
      tilesets: pathPresets.isEmpty
          ? const <ProjectTilesetEntry>[]
          : const <ProjectTilesetEntry>[
              ProjectTilesetEntry(
                id: 'water_tiles',
                name: 'Water',
                relativePath: 'tilesets/water.png',
              ),
            ],
      pathPresets: pathPresets,
      dialogues: dialogues,
      scripts: scripts,
      trainers: trainers,
      scenarios: scenarios,
      scenes: scenes,
      surfaceCatalog: const ProjectSurfaceCatalog.empty(),
    ),
    map: map,
    projectRootDirectory: '/tmp/checkpoint_load_safety',
    tilesetAbsolutePathsById: const <String, String>{},
  );
}

MapData _plainMap(String id) {
  return MapData(
    id: id,
    name: id,
    size: const GridSize(width: 6, height: 6),
    layers: const <MapLayer>[
      MapLayer.object(id: 'objects', name: 'Objects'),
    ],
    entities: <MapEntity>[
      MapEntity(
        id: 'spawn_$id',
        name: 'Spawn',
        kind: MapEntityKind.spawn,
        pos: const GridPos(x: 0, y: 0),
        blocksMovement: false,
        spawn: const MapEntitySpawnData(
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.east,
        ),
      ),
    ],
    mapMetadata: MapMetadata(defaultSpawnId: 'spawn_$id'),
  );
}

MapData _followMap() {
  return const MapData(
    id: _sourceMapId,
    name: 'Follow source',
    size: GridSize(width: 6, height: 6),
    layers: <MapLayer>[
      MapLayer.object(id: 'objects', name: 'Objects'),
    ],
    entities: <MapEntity>[
      MapEntity(
        id: 'spawn_follow',
        name: 'Spawn',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 0, y: 0),
        blocksMovement: false,
        spawn: MapEntitySpawnData(
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.east,
        ),
      ),
      MapEntity(
        id: 'leader',
        name: 'Leader',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 4, y: 4),
        npc: MapEntityNpcData(displayName: 'Leader'),
      ),
    ],
    mapMetadata: MapMetadata(defaultSpawnId: 'spawn_follow'),
  );
}

MapData _leaderWarpMap() {
  return const MapData(
    id: _sourceMapId,
    name: 'Leader warp source',
    size: GridSize(width: 6, height: 4),
    layers: <MapLayer>[
      MapLayer.object(id: 'objects', name: 'Objects'),
    ],
    warps: <MapWarp>[
      MapWarp(
        id: 'leader_exit',
        pos: GridPos(x: 4, y: 1),
        targetMapId: _restoredMapId,
        targetPos: GridPos(x: 1, y: 1),
      ),
    ],
    entities: <MapEntity>[
      MapEntity(
        id: 'spawn_leader_warp',
        name: 'Spawn',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 0, y: 1),
        blocksMovement: false,
        spawn: MapEntitySpawnData(
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.east,
        ),
      ),
      MapEntity(
        id: 'leader',
        name: 'Leader',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 2, y: 1),
        npc: MapEntityNpcData(
          displayName: 'Leader',
          characterId: 'leader_character',
        ),
      ),
    ],
    mapMetadata: MapMetadata(defaultSpawnId: 'spawn_leader_warp'),
  );
}

RuntimeMapBundle _leaderWarpBundle() {
  final map = _leaderWarpMap();
  return RuntimeMapBundle(
    manifest: const ProjectManifest(
      name: 'Leader warp checkpoint fixture',
      maps: <ProjectMapEntry>[
        ProjectMapEntry(
          id: _sourceMapId,
          name: 'Leader warp source',
          relativePath: 'maps/$_sourceMapId.json',
        ),
      ],
      tilesets: <ProjectTilesetEntry>[
        ProjectTilesetEntry(
          id: 'leader_tiles',
          name: 'Leader tiles',
          relativePath: 'tilesets/leader.png',
        ),
      ],
      characters: <ProjectCharacterEntry>[
        ProjectCharacterEntry(
          id: 'leader_character',
          name: 'Leader character',
          tilesetId: 'leader_tiles',
          frameWidth: 8,
          frameHeight: 8,
        ),
      ],
      surfaceCatalog: ProjectSurfaceCatalog.empty(),
    ),
    map: map,
    projectRootDirectory: '/tmp/checkpoint_load_safety',
    tilesetAbsolutePathsById: const <String, String>{
      'leader_tiles': '/tmp/checkpoint_load_safety/tilesets/leader.png',
    },
  );
}

Future<Map<String, RuntimeTilesetImage>> _leaderTilesetLoader(
  Map<String, String> absolutePathByTilesetId, {
  Map<String, TilesetTransparentColor> transparentColorByTilesetId =
      const <String, TilesetTransparentColor>{},
}) async {
  return <String, RuntimeTilesetImage>{
    for (final id in absolutePathByTilesetId.keys)
      id: await runtimeTilesetImage(
        List<Color>.filled(4, const Color(0xFF4060A0)),
      ),
  };
}

ScenarioAsset _outcomeFlagScenario() {
  return const ScenarioAsset(
    id: 'blocked_checkpoint_scenario',
    name: 'Blocked checkpoint scenario',
    scope: ScenarioScope.globalStory,
    entryNodeId: 'source',
    nodes: <ScenarioNode>[
      ScenarioNode(
        id: 'source',
        type: ScenarioNodeType.reference,
        payload: ScenarioNodePayload(actionKind: kScenarioSourceOutcome),
        binding: ScenarioNodeBinding(outcomeId: 'checkpoint.seed'),
      ),
      ScenarioNode(
        id: 'set_flag',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
        binding: ScenarioNodeBinding(flagName: _legacyBlockedFlag),
      ),
      ScenarioNode(id: 'end', type: ScenarioNodeType.end),
    ],
    edges: <ScenarioEdge>[
      ScenarioEdge(
        id: 'source_to_flag',
        fromNodeId: 'source',
        toNodeId: 'set_flag',
      ),
      ScenarioEdge(
        id: 'flag_to_end',
        fromNodeId: 'set_flag',
        toNodeId: 'end',
      ),
    ],
  );
}

ScenarioAsset _mapEnterFollowScenario() {
  return const ScenarioAsset(
    id: _followScenarioId,
    name: 'Follow before load',
    scope: ScenarioScope.localEventFlow,
    entryNodeId: 'source',
    nodes: <ScenarioNode>[
      ScenarioNode(
        id: 'source',
        type: ScenarioNodeType.reference,
        payload: ScenarioNodePayload(actionKind: kScenarioSourceMapEnter),
        binding: ScenarioNodeBinding(mapId: _sourceMapId),
      ),
      ScenarioNode(
        id: 'follow',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(
          actionKind: kScenarioActionFollowCharacter,
          params: <String, String>{'leaderId': 'leader'},
        ),
      ),
      ScenarioNode(id: 'end', type: ScenarioNodeType.end),
    ],
    edges: <ScenarioEdge>[
      ScenarioEdge(
        id: 'source_to_follow',
        fromNodeId: 'source',
        toNodeId: 'follow',
      ),
      ScenarioEdge(
        id: 'follow_to_end',
        fromNodeId: 'follow',
        toNodeId: 'end',
      ),
    ],
  );
}

RuntimeMapBundle _scriptAndWaterBundle() {
  return _bundle(
    map: _interactionWaterMap(includeScriptEvent: true),
    pathPresets: const <ProjectPathPreset>[_waterPreset],
    scripts: const <ProjectScriptEntry>[
      ProjectScriptEntry(
        id: 'stale_script',
        name: 'Stale script',
        asset: ScriptAsset(
          id: 'stale_script',
          defaultStartNode: 'start',
          nodes: <ScriptNode>[
            ScriptNode(
              id: 'start',
              commands: <ScriptCommand>[
                ScriptCommand(
                  type: ScriptCommandType.openDialogue,
                  params: <String, String>{
                    'filePath': 'dialogues/script.yarn',
                    'startNode': 'Start',
                  },
                ),
                ScriptCommand(
                  type: ScriptCommandType.setFlag,
                  params: <String, String>{'flagName': _staleScriptFlag},
                ),
                ScriptCommand(type: ScriptCommandType.end),
              ],
            ),
          ],
        ),
      ),
    ],
  );
}

RuntimeMapBundle _choiceNpcAndWaterBundle() {
  return _bundle(
    map: _interactionWaterMap(includeChoiceNpc: true),
    pathPresets: const <ProjectPathPreset>[_waterPreset],
    dialogues: const <ProjectDialogueEntry>[
      ProjectDialogueEntry(
        id: 'unrelated_choice',
        name: 'Unrelated choice',
        relativePath: 'dialogues/unrelated_choice.yarn',
      ),
    ],
  );
}

const _waterPreset = ProjectPathPreset(
  id: 'water_path',
  name: 'Water',
  surfaceKind: PathSurfaceKind.water,
  tilesetId: 'water_tiles',
);

MapData _interactionWaterMap({
  bool includeScriptEvent = false,
  bool includeChoiceNpc = false,
}) {
  final waterCells = List<bool>.filled(9, false)..[1] = true;
  return MapData(
    id: _sourceMapId,
    name: 'Interaction water map',
    size: const GridSize(width: 3, height: 3),
    layers: <MapLayer>[
      const MapLayer.object(id: 'objects', name: 'Objects'),
      MapLayer.path(
        id: 'water',
        name: 'Water',
        presetId: 'water_path',
        cells: waterCells,
      ),
    ],
    entities: <MapEntity>[
      const MapEntity(
        id: 'spawn_interaction',
        name: 'Spawn',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 0, y: 0),
        blocksMovement: false,
        spawn: MapEntitySpawnData(
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.east,
        ),
      ),
      if (includeChoiceNpc)
        const MapEntity(
          id: 'choice_npc',
          name: 'Choice NPC',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 0, y: 1),
          npc: MapEntityNpcData(
            displayName: 'Choice NPC',
            dialogue: DialogueRef(dialogueId: 'unrelated_choice'),
          ),
        ),
    ],
    events: <MapEventDefinition>[
      if (includeScriptEvent)
        const MapEventDefinition(
          id: 'script_event',
          title: 'Script event',
          position: EventPosition(layerId: 'objects', x: 0, y: 1),
          pages: <MapEventPage>[
            MapEventPage(
              pageNumber: 0,
              script: ScriptRef(scriptId: 'stale_script', startNode: 'start'),
            ),
          ],
        ),
    ],
    mapMetadata: const MapMetadata(defaultSpawnId: 'spawn_interaction'),
  );
}

RuntimeMapBundle _sceneBundle() {
  return _bundle(
    map: _sceneMap(),
    dialogues: const <ProjectDialogueEntry>[
      ProjectDialogueEntry(
        id: 'scene_dialogue',
        name: 'Scene dialogue',
        relativePath: 'dialogues/scene_dialogue.yarn',
      ),
    ],
    trainers: const <ProjectTrainerEntry>[
      ProjectTrainerEntry(
        id: _trainerId,
        name: 'Checkpoint Trainer',
        trainerClass: 'Tester',
        team: <ProjectTrainerPokemonEntry>[
          ProjectTrainerPokemonEntry(speciesId: 'embercub', level: 5),
        ],
      ),
    ],
    scenes: <SceneAsset>[_dialogueBattleScene()],
  );
}

MapData _sceneMap() {
  return const MapData(
    id: _sourceMapId,
    name: 'Scene map',
    size: GridSize(width: 4, height: 4),
    layers: <MapLayer>[
      MapLayer.object(id: 'objects', name: 'Objects'),
    ],
    entities: <MapEntity>[
      MapEntity(
        id: 'spawn_scene',
        name: 'Spawn',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 0, y: 0),
        blocksMovement: false,
        spawn: MapEntitySpawnData(
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.east,
        ),
      ),
      MapEntity(
        id: 'trainer_npc',
        name: 'Trainer NPC',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 2, y: 2),
        npc: MapEntityNpcData(
          displayName: 'Trainer NPC',
          trainerId: _trainerId,
        ),
      ),
    ],
    events: <MapEventDefinition>[
      MapEventDefinition(
        id: 'scene_event',
        title: 'Scene event',
        position: EventPosition(layerId: 'objects', x: 1, y: 0),
        pages: <MapEventPage>[
          MapEventPage(
            pageNumber: 0,
            sceneTarget: MapEventSceneTarget(sceneId: 'dialogue_battle_scene'),
          ),
        ],
      ),
    ],
    mapMetadata: MapMetadata(defaultSpawnId: 'spawn_scene'),
  );
}

SceneAsset _dialogueBattleScene() {
  return SceneAsset(
    id: 'dialogue_battle_scene',
    name: 'Dialogue and hosted battle',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: <SceneNode>[
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'dialogue',
          kind: SceneNodeKind.yarnDialogue,
          payload: SceneYarnDialoguePayload(dialogueId: 'scene_dialogue'),
        ),
        SceneNode(
          id: 'battle',
          kind: SceneNodeKind.battle,
          payload: SceneBattlePayload(
            battleKind: 'trainer',
            trainerId: _trainerId,
            npcEntityId: 'trainer_npc',
            declaredOutcomes: const <String>['victory', 'defeat'],
          ),
        ),
        SceneNode(id: 'victory_end', kind: SceneNodeKind.end),
        SceneNode(id: 'defeat_end', kind: SceneNodeKind.end),
      ],
      edges: <SceneEdge>[
        SceneEdge(
          id: 'start_to_dialogue',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'dialogue',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'dialogue_to_battle',
          fromNodeId: 'dialogue',
          fromPortId: 'completed',
          toNodeId: 'battle',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'battle_victory',
          fromNodeId: 'battle',
          fromPortId: 'victory',
          toNodeId: 'victory_end',
          kind: SceneEdgeKind.battleVictory,
        ),
        SceneEdge(
          id: 'battle_defeat',
          fromNodeId: 'battle',
          fromPortId: 'defeat',
          toNodeId: 'defeat_end',
          kind: SceneEdgeKind.battleDefeat,
        ),
      ],
    ),
  );
}

GameState _state({
  required String mapId,
  GridPos position = const GridPos(x: 0, y: 0),
}) {
  return GameState(
    saveId: 'checkpoint-load-safety',
    currentMapId: mapId,
    playerPosition: position,
    playerFacing: EntityFacing.east,
  );
}

GameState _surfState({
  required EntityFacing facing,
  required String mapId,
}) {
  return GameState(
    saveId: 'checkpoint-surf',
    currentMapId: mapId,
    playerPosition: const GridPos(x: 0, y: 0),
    playerFacing: facing,
    party: const PlayerParty(
      members: <PlayerPokemon>[
        PlayerPokemon(
          speciesId: 'aquafi',
          natureId: 'calm',
          abilityId: 'torrent',
          level: 10,
          knownMoveIds: <String>['surf'],
          currentHp: 25,
        ),
      ],
    ),
    progression: const PlayerProgression(
      unlockedFieldAbilities: <FieldAbility>[FieldAbility.surf],
    ),
  );
}

GameState _battleReadyState() {
  return const GameState(
    saveId: 'checkpoint-scene',
    currentMapId: _sourceMapId,
    playerPosition: GridPos(x: 0, y: 0),
    playerFacing: EntityFacing.east,
    party: PlayerParty(
      members: <PlayerPokemon>[
        PlayerPokemon(
          speciesId: 'sproutle',
          natureId: 'hardy',
          abilityId: 'overgrow',
          level: 5,
          knownMoveIds: <String>['tackle'],
          currentHp: 20,
        ),
      ],
    ),
  );
}

DialogueSession _singleLineDialogue() {
  return DialogueSession.start(
    <YarnNode>[
      YarnNode(
        title: 'Start',
        steps: <YarnStep>[YarnStepLine('Checkpoint dialogue')],
      ),
    ],
    'Start',
  )!;
}

RuntimeCutsceneAsset _waitThenFlagCutscene(String id) {
  return RuntimeCutsceneAsset(
    id: id,
    name: 'Wait then flag',
    steps: const <RuntimeCutsceneStep>[
      CutsceneWaitStep(durationMs: 10000),
      CutsceneSetFlagStep(flagName: _staleCutsceneFlag),
    ],
  );
}

DialogueSession _choiceDialogue() {
  return DialogueSession.start(
    <YarnNode>[
      YarnNode(
        title: 'Start',
        steps: <YarnStep>[
          YarnStepChoiceBlock(<YarnChoice>[
            YarnChoice(text: 'Unrelated yes', steps: <YarnStep>[]),
            YarnChoice(text: 'Unrelated no', steps: <YarnStep>[]),
          ]),
        ],
      ),
    ],
    'Start',
  )!;
}

RuntimeActiveBattleContext _trainerContext() {
  return const RuntimeActiveBattleContext(
    request: TrainerBattleStartRequest(
      requestId: 'checkpoint-scene-battle',
      createdAtEpochMs: 1,
      returnContext: OverworldReturnContext(
        mapId: _sourceMapId,
        playerPos: GridPos(x: 0, y: 0),
        playerFacing: Direction.east,
      ),
      trainerId: _trainerId,
      npcEntityId: 'trainer_npc',
      mapId: _sourceMapId,
      playerPos: GridPos(x: 0, y: 0),
    ),
    playerPartyIndex: 0,
  );
}

BattleOutcome _victoryOutcome() {
  return BattleOutcome(
    type: BattleOutcomeType.victory,
    finalState: BattleState(
      phase: BattlePhase.finished,
      player: const BattleCombatant(
        speciesId: 'sproutle',
        level: 5,
        currentHp: 12,
        maxHp: 20,
        stats: _battleStats,
        moves: <BattleMove>[
          BattleMove(id: 'tackle', name: 'Tackle', power: 10),
        ],
      ),
      enemy: const BattleCombatant(
        speciesId: 'embercub',
        level: 5,
        currentHp: 0,
        maxHp: 18,
        stats: _battleStats,
        moves: <BattleMove>[
          BattleMove(id: 'scratch', name: 'Scratch', power: 10),
        ],
      ),
      currentTurn: null,
      outcome: null,
    ),
  );
}

final class _GateMemoryRepository implements GameSaveRepository {
  _GateMemoryRepository(this.gate);

  final NarrativeRuntimeActivityGate gate;
  GameState? storedState;
  int saveCount = 0;
  int loadCount = 0;

  @override
  Future<void> save(GameState state) {
    return gate.runCheckpoint(
      NarrativeRuntimeCheckpointOperation.save,
      () async {
        saveCount++;
        storedState = state;
      },
    );
  }

  @override
  Future<GameState?> load() {
    return gate.runCheckpoint(
      NarrativeRuntimeCheckpointOperation.load,
      () async {
        loadCount++;
        return storedState;
      },
    );
  }

  @override
  Future<bool> exists() async => storedState != null;

  @override
  Future<void> delete() async {
    storedState = null;
  }
}
~~~~~~~~

### 25.13 `packages/map_runtime/test/playable_map_game_entity_interaction_v2_integration_test.dart`

~~~~~~~~dart
import 'dart:async';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/narrative_runtime_activity_gate.dart';

const _mapId = 'event_v2_entity_interaction_map';
const _legacyFlag = 'test.event_v2.entity.legacy_fallback';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlayableMapGame Event V2 entity interaction production hook', () {
    for (final fixture in _entityFixtures) {
      test(
        '${fixture.kind.name} executes its Scene once and suppresses legacy',
        () async {
          var nativeDialogueLoadCount = 0;
          final game = _TestPlayableMapGame(
            bundle: _v2Bundle(fixture),
            projectFilePath: '/tmp/event_v2_entity/project.json',
            dialogueSessionLoader: (_) async {
              nativeDialogueLoadCount++;
              return null;
            },
          );

          await _load(game);
          expect(_pressPrimary(game), isTrue);
          await _pumpUntil(
            game,
            () =>
                game.gameStateSnapshot.narrativeFactRuntimeState
                    .overridesByFactId[fixture.factId] ==
                true,
          );

          final state = game.gameStateSnapshot;
          expect(
            state.narrativeEventProgress.consumedNarrativeEventIds,
            contains(fixture.eventId),
            reason: 'The selected one-shot Event must be committed.',
          );
          expect(
            state.storyFlags.activeFlags,
            isNot(contains(_legacyFlag)),
            reason: 'A V2-handled occurrence must not run Scenario fallback.',
          );
          expect(
            nativeDialogueLoadCount,
            0,
            reason: 'NPC/sign native dialogue fallback must stay suppressed.',
          );
          expect(
            game.debugNotificationText,
            isNull,
            reason: 'Item/custom native feedback must stay suppressed.',
          );
        },
      );
    }

    test('spawn entities never create an entityInteract occurrence', () async {
      var entityAuthorityPreparationCount = 0;
      final game = _TestPlayableMapGame(
        bundle: _spawnExclusionBundle(),
        projectFilePath: '/tmp/event_v2_spawn_exclusion/project.json',
        beforeNarrativeAuthorityPreparation: (occurrence) async {
          if (occurrence.source.kind ==
              NarrativeEventSourceKind.entityInteract) {
            entityAuthorityPreparationCount++;
          }
        },
      );

      await _load(game);
      expect(_pressPrimary(game), isTrue);
      await _pumpMicrotasks(game);

      expect(entityAuthorityPreparationCount, 0);
    });

    test('legacyOnly noMatch keeps the matching Scenario fallback', () async {
      final fixture = _entityFixtures.first;
      final game = _TestPlayableMapGame(
        bundle: _legacyOnlyBundle(
          fixture.entity,
          scenarios: <ScenarioAsset>[_legacyScenario(fixture.entity.id)],
        ),
        projectFilePath: '/tmp/event_v2_legacy_scenario/project.json',
      );

      await _load(game);
      expect(_pressPrimary(game), isTrue);
      await _pumpUntil(
        game,
        () =>
            game.gameStateSnapshot.storyFlags.activeFlags.contains(_legacyFlag),
      );

      expect(
        game.gameStateSnapshot.storyFlags.activeFlags,
        contains(_legacyFlag),
      );
    });

    test('legacyOnly noMatch keeps native entity fallback', () async {
      const entity = MapEntity(
        id: 'custom_native_fallback',
        name: 'Native custom fallback',
        kind: MapEntityKind.custom,
        pos: GridPos(x: 1, y: 0),
      );
      final game = _TestPlayableMapGame(
        bundle: _legacyOnlyBundle(entity),
        projectFilePath: '/tmp/event_v2_legacy_native/project.json',
      );

      await _load(game);
      expect(_pressPrimary(game), isTrue);
      await _pumpUntil(
        game,
        () => game.debugNotificationText == entity.name,
      );

      expect(game.debugNotificationText, entity.name);
    });

    test('dualRead claimed-ineligible occurrence suppresses all fallback',
        () async {
      final fixture = _entityFixtures.first;
      final game = _TestPlayableMapGame(
        bundle: _claimedIneligibleBundle(fixture),
        projectFilePath: '/tmp/event_v2_claimed_ineligible/project.json',
      );

      await _load(game);
      expect(_pressPrimary(game), isTrue);
      await _pumpMicrotasks(game);

      final state = game.gameStateSnapshot;
      expect(
        state.storyFlags.activeFlags,
        isNot(contains(_legacyFlag)),
        reason: 'A validated claim owns the occurrence even when disabled.',
      );
      expect(
        state.narrativeFactRuntimeState.overridesByFactId[fixture.factId],
        isNot(true),
      );
      expect(
        state.narrativeEventProgress.consumedNarrativeEventIds,
        isNot(contains(fixture.eventId)),
      );
      expect(game.debugNotificationText, isNull);
    });

    test('a second input during async authority preparation launches once',
        () async {
      final fixture = _entityFixtures.first;
      final preparationStarted = Completer<void>();
      final releasePreparation = Completer<void>();
      var entityAuthorityPreparationCount = 0;
      final gate = NarrativeRuntimeActivityGate();
      final repository = _CheckpointCountingRepository(gate);
      final game = _TestPlayableMapGame(
        bundle: _v2Bundle(fixture),
        projectFilePath: '/tmp/event_v2_entity_interlock/project.json',
        narrativeRuntimeActivityGate: gate,
        saveRepository: repository,
        beforeNarrativeAuthorityPreparation: (occurrence) async {
          if (occurrence.source.kind !=
              NarrativeEventSourceKind.entityInteract) {
            return;
          }
          entityAuthorityPreparationCount++;
          if (!preparationStarted.isCompleted) {
            preparationStarted.complete();
          }
          await releasePreparation.future;
        },
      );

      await _load(game);
      expect(_pressPrimary(game), isTrue);
      await preparationStarted.future;

      expect(gate.activity, NarrativeRuntimeActivity.dispatching);
      expect(await game.saveGame(), isFalse);
      expect(await game.loadGame(), isFalse);
      expect(repository.saveCount, 0);
      expect(repository.loadCount, 0);

      expect(_pressPrimary(game), isTrue);
      await _pumpMicrotasks(game);
      expect(
        entityAuthorityPreparationCount,
        1,
        reason: 'The in-flight spatial dispatch must absorb duplicate input.',
      );

      releasePreparation.complete();
      await _pumpUntil(
        game,
        () =>
            game.gameStateSnapshot.narrativeFactRuntimeState
                .overridesByFactId[fixture.factId] ==
            true,
      );

      expect(entityAuthorityPreparationCount, 1);
      expect(
        game.gameStateSnapshot.narrativeEventProgress.consumedNarrativeEventIds,
        contains(fixture.eventId),
      );
      expect(gate.activity, NarrativeRuntimeActivity.idle);
      expect(await game.saveGame(), isTrue);
      expect(repository.saveCount, 1);
    });

    test(
      'entity outcome retry stays pending without escaping its detached task',
      () async {
        final fixture = _entityFixtures.first;
        final gate = NarrativeRuntimeActivityGate();
        final repository = _CheckpointCountingRepository(gate);
        var outcomePreparationCount = 0;
        final game = _TestPlayableMapGame(
          bundle: _retryOutcomeBundle(fixture),
          projectFilePath: '/tmp/event_v2_entity_retry/project.json',
          narrativeRuntimeActivityGate: gate,
          saveRepository: repository,
          beforeNarrativeAuthorityPreparation: (occurrence) async {
            if (occurrence.source.kind !=
                NarrativeEventSourceKind.outcomeReceived) {
              return;
            }
            outcomePreparationCount++;
            throw StateError(
              'retryable entity outcome infrastructure failure',
            );
          },
        );

        await _load(game);
        final uncaughtErrors = await _captureDetachedErrors(() async {
          expect(_pressPrimary(game), isTrue);
          await _pumpUntil(
            game,
            () =>
                !game.debugIsNarrativeSpatialDispatchInFlight &&
                !game.debugIsNarrativeOutcomeWorkInFlight &&
                game.gameStateSnapshot.narrativeEventProgress
                    .pendingNarrativeOutcomeDeliveries.isNotEmpty,
          );
          await Future<void>.delayed(Duration.zero);
        });

        final state = game.gameStateSnapshot;
        final pending =
            state.narrativeEventProgress.pendingNarrativeOutcomeDeliveries;
        expect(uncaughtErrors, isEmpty);
        expect(outcomePreparationCount, 1);
        expect(pending, hasLength(1));
        expect(pending.single.outcome.outcomeId, _entityRetryOutcomeId);
        expect(pending.single.attemptCount, 1);
        expect(
          state.narrativeEventProgress.deliveredNarrativeOutcomeDeliveryIds,
          isEmpty,
        );
        expect(
          state.narrativeEventProgress.consumedNarrativeEventIds,
          contains(fixture.eventId),
        );
        expect(game.debugIsNarrativeSpatialDispatchInFlight, isFalse);
        expect(game.debugIsNarrativeOutcomeWorkInFlight, isFalse);
        expect(game.debugIsGameplayInputLocked, isFalse);
        expect(gate.activity, NarrativeRuntimeActivity.idle);
        expect(await game.saveGame(), isTrue);
        expect(repository.saveCount, 1);
        expect(
          repository.storedState!.narrativeEventProgress
              .pendingNarrativeOutcomeDeliveries.single.attemptCount,
          1,
        );
      },
    );
  });
}

Future<List<Object>> _captureDetachedErrors(
  Future<void> Function() body,
) async {
  final errors = <Object>[];
  final bodyCompleted = Completer<void>();
  runZonedGuarded(
    () {
      body().then<void>(
        (_) => bodyCompleted.complete(),
        onError: (Object error, StackTrace stackTrace) {
          bodyCompleted.completeError(error, stackTrace);
        },
      );
    },
    (error, _) => errors.add(error),
  );
  await bodyCompleted.future;
  return errors;
}

final class _TestPlayableMapGame extends PlayableMapGame {
  _TestPlayableMapGame({
    required super.bundle,
    required super.projectFilePath,
    super.dialogueSessionLoader,
    super.beforeNarrativeAuthorityPreparation,
    super.narrativeRuntimeActivityGate,
    super.saveRepository,
  });

  @override
  bool get isLoaded => true;
}

final class _CheckpointCountingRepository implements GameSaveRepository {
  _CheckpointCountingRepository(this.gate);

  final NarrativeRuntimeActivityGate gate;
  GameState? storedState;
  int saveCount = 0;
  int loadCount = 0;

  @override
  Future<void> save(GameState state) {
    return gate.runCheckpoint(
      NarrativeRuntimeCheckpointOperation.save,
      () async {
        saveCount++;
        storedState = state;
      },
    );
  }

  @override
  Future<GameState?> load() {
    return gate.runCheckpoint(
      NarrativeRuntimeCheckpointOperation.load,
      () async {
        loadCount++;
        return storedState;
      },
    );
  }

  @override
  Future<bool> exists() async => storedState != null;

  @override
  Future<void> delete() async {
    storedState = null;
  }
}

final class _EntityFixture {
  const _EntityFixture({
    required this.entity,
    required this.eventId,
    required this.sceneId,
    required this.factId,
  });

  final MapEntity entity;
  final String eventId;
  final String sceneId;
  final String factId;

  MapEntityKind get kind => entity.kind;
}

const _entityFixtures = <_EntityFixture>[
  _EntityFixture(
    entity: MapEntity(
      id: 'npc_v2',
      name: 'NPC V2',
      kind: MapEntityKind.npc,
      pos: GridPos(x: 1, y: 0),
      npc: MapEntityNpcData(
        displayName: 'NPC native fallback',
        dialogue: DialogueRef(dialogueId: 'native_dialogue'),
      ),
    ),
    eventId: 'evt_019abcde-2000-7000-8000-000000000001',
    sceneId: 'scene_entity_npc_v2',
    factId: 'fact.event_v2.entity.npc',
  ),
  _EntityFixture(
    entity: MapEntity(
      id: 'sign_v2',
      name: 'Sign V2',
      kind: MapEntityKind.sign,
      pos: GridPos(x: 1, y: 0),
      sign: MapEntitySignData(
        title: 'Sign native fallback',
        dialogue: DialogueRef(dialogueId: 'native_dialogue'),
      ),
    ),
    eventId: 'evt_019abcde-2000-7000-8000-000000000002',
    sceneId: 'scene_entity_sign_v2',
    factId: 'fact.event_v2.entity.sign',
  ),
  _EntityFixture(
    entity: MapEntity(
      id: 'item_v2',
      name: 'Item native fallback',
      kind: MapEntityKind.item,
      pos: GridPos(x: 1, y: 0),
      item: MapEntityItemData(gameItemId: 'item_native_fallback'),
    ),
    eventId: 'evt_019abcde-2000-7000-8000-000000000003',
    sceneId: 'scene_entity_item_v2',
    factId: 'fact.event_v2.entity.item',
  ),
  _EntityFixture(
    entity: MapEntity(
      id: 'custom_v2',
      name: 'Custom native fallback',
      kind: MapEntityKind.custom,
      pos: GridPos(x: 1, y: 0),
    ),
    eventId: 'evt_019abcde-2000-7000-8000-000000000004',
    sceneId: 'scene_entity_custom_v2',
    factId: 'fact.event_v2.entity.custom',
  ),
];

const _entityRetryOutcomeId = 'entity.retry';

RuntimeMapBundle _v2Bundle(_EntityFixture fixture) {
  final source = NarrativeEventSourceRef.entityInteract(
    _mapId,
    fixture.entity.id,
  );
  final registry = NarrativeEventRegistry(
    schemaVersion: 1,
    mode: EventSystemMode.v2Only,
    records: <NarrativeEventRecord>[
      _eventRecord(fixture, source: source, enabled: true),
    ],
    legacyClaims: const <LegacySourceClaim>[],
  );
  return _bundle(
    entity: fixture.entity,
    eventRegistry: registry,
    facts: <NarrativeFactDefinition>[
      NarrativeFactDefinition(id: fixture.factId, label: fixture.factId),
    ],
    scenes: <SceneAsset>[_scene(fixture)],
    scenarios: <ScenarioAsset>[_legacyScenario(fixture.entity.id)],
  );
}

RuntimeMapBundle _retryOutcomeBundle(_EntityFixture fixture) {
  final source = NarrativeEventSourceRef.entityInteract(
    _mapId,
    fixture.entity.id,
  );
  final registry = NarrativeEventRegistry(
    schemaVersion: 1,
    mode: EventSystemMode.v2Only,
    records: <NarrativeEventRecord>[
      _eventRecord(fixture, source: source, enabled: true),
    ],
    legacyClaims: const <LegacySourceClaim>[],
  );
  return _bundle(
    entity: fixture.entity,
    eventRegistry: registry,
    scenes: <SceneAsset>[_outcomeScene(fixture)],
  );
}

RuntimeMapBundle _claimedIneligibleBundle(_EntityFixture fixture) {
  final source = NarrativeEventSourceRef.entityInteract(
    _mapId,
    fixture.entity.id,
  );
  final scenario = _legacyScenario(fixture.entity.id);
  final provenance = LegacySourceRef.scenarioSourceNode(
    scenario.id,
    'source',
  );
  final member = LegacySourceClaimMember(
    provenance: provenance,
    sourceFingerprint: computeScenarioSourceFingerprint(
      scenarioId: scenario.id,
      nodeId: 'source',
      scenario: scenario,
    ),
  );
  final cohortId = computeLegacySourceCohortId(source, <LegacySourceRef>[
    provenance,
  ]);
  final claim = LegacySourceClaim(
    cohortId: cohortId,
    source: source,
    members: <LegacySourceClaimMember>[member],
    cohortFingerprint: computeLegacySourceCohortFingerprint(
      cohortId,
      <LegacySourceClaimMember>[member],
    ),
    targetEventIds: <String>[fixture.eventId],
    migrationReceiptId: 'receipt-entity-claimed-ineligible',
  );
  final registry = NarrativeEventRegistry(
    schemaVersion: 1,
    mode: EventSystemMode.dualRead,
    records: <NarrativeEventRecord>[
      _eventRecord(fixture, source: source, enabled: false),
    ],
    legacyClaims: <LegacySourceClaim>[claim],
  );
  return _bundle(
    entity: fixture.entity,
    eventRegistry: registry,
    facts: <NarrativeFactDefinition>[
      NarrativeFactDefinition(id: fixture.factId, label: fixture.factId),
    ],
    scenes: <SceneAsset>[_scene(fixture)],
    scenarios: <ScenarioAsset>[scenario],
  );
}

RuntimeMapBundle _legacyOnlyBundle(
  MapEntity entity, {
  List<ScenarioAsset> scenarios = const <ScenarioAsset>[],
}) {
  return _bundle(
    entity: entity,
    eventRegistry: NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.legacyOnly,
      records: const <NarrativeEventRecord>[],
      legacyClaims: const <LegacySourceClaim>[],
    ),
    scenarios: scenarios,
  );
}

RuntimeMapBundle _spawnExclusionBundle() {
  const spawnTarget = MapEntity(
    id: 'spawn_event_target',
    name: 'Excluded spawn',
    kind: MapEntityKind.spawn,
    pos: GridPos(x: 1, y: 0),
    blocksMovement: false,
    spawn: MapEntitySpawnData(role: EntitySpawnRole.event),
  );
  return _bundle(
    entity: spawnTarget,
    eventRegistry: NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.v2Only,
      records: const <NarrativeEventRecord>[],
      legacyClaims: const <LegacySourceClaim>[],
    ),
  );
}

RuntimeMapBundle _bundle({
  required MapEntity entity,
  required NarrativeEventRegistry eventRegistry,
  List<NarrativeFactDefinition> facts = const <NarrativeFactDefinition>[],
  List<SceneAsset> scenes = const <SceneAsset>[],
  List<ScenarioAsset> scenarios = const <ScenarioAsset>[],
}) {
  final project = ProjectManifest(
    name: 'Event V2 entity interaction integration',
    maps: const <ProjectMapEntry>[
      ProjectMapEntry(
        id: _mapId,
        name: 'Event V2 Entity Map',
        relativePath: 'maps/event_v2_entity.json',
      ),
    ],
    tilesets: const <ProjectTilesetEntry>[],
    dialogues: const <ProjectDialogueEntry>[
      ProjectDialogueEntry(
        id: 'native_dialogue',
        name: 'Native fallback dialogue',
        relativePath: 'dialogues/native.yarn',
      ),
    ],
    facts: facts,
    scenes: scenes,
    scenarios: scenarios,
    eventRegistry: eventRegistry,
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
  );
  return RuntimeMapBundle(
    manifest: project,
    map: _map(entity),
    projectRootDirectory: '/tmp/event_v2_entity',
    tilesetAbsolutePathsById: const <String, String>{},
  );
}

MapData _map(MapEntity entity) => MapData(
      id: _mapId,
      name: 'Event V2 Entity Map',
      size: const GridSize(width: 3, height: 2),
      layers: const <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: <MapEntity>[
        const MapEntity(
          id: 'spawn_start',
          name: 'Player start',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 0, y: 0),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.east,
          ),
        ),
        entity,
      ],
      mapMetadata: const MapMetadata(defaultSpawnId: 'spawn_start'),
    );

NarrativeEventRecord _eventRecord(
  _EntityFixture fixture, {
  required NarrativeEventSourceRef source,
  required bool enabled,
}) {
  return NarrativeEventRecord.configuredStructurallyUnchecked(
    NarrativeEventDefinition(
      id: fixture.eventId,
      name: 'Entity Event ${fixture.kind.name}',
      source: source,
      conditions: const <NarrativeEventCondition>[],
      sceneId: fixture.sceneId,
      reusePolicy: NarrativeEventReusePolicy.oneShot,
      priority: 0,
      order: 0,
    ),
    enabled: enabled,
  );
}

SceneAsset _scene(_EntityFixture fixture) {
  return SceneAsset(
    id: fixture.sceneId,
    name: 'Entity Scene ${fixture.kind.name}',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: <SceneNode>[
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'set_fact',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.setFact(factId: fixture.factId, value: true),
          ),
        ),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ],
      edges: <SceneEdge>[
        SceneEdge(
          id: 'start_to_fact',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'set_fact',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'fact_to_end',
          fromNodeId: 'set_fact',
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.actionCompleted,
        ),
      ],
    ),
  );
}

SceneAsset _outcomeScene(_EntityFixture fixture) {
  return SceneAsset(
    id: fixture.sceneId,
    name: 'Entity retry Scene ${fixture.kind.name}',
    declaredOutcomes: <SceneOutcome>[
      SceneOutcome(id: _entityRetryOutcomeId, label: 'Entity retry'),
    ],
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: <SceneNode>[
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'end',
          kind: SceneNodeKind.end,
          payload: SceneEndPayload(sceneOutcomeId: _entityRetryOutcomeId),
        ),
      ],
      edges: <SceneEdge>[
        SceneEdge(
          id: 'start_to_end',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.defaultFlow,
        ),
      ],
    ),
  );
}

ScenarioAsset _legacyScenario(String entityId) {
  return ScenarioAsset(
    id: 'legacy_entity_$entityId',
    name: 'Legacy entity fallback',
    scope: ScenarioScope.localEventFlow,
    entryNodeId: 'source',
    nodes: <ScenarioNode>[
      ScenarioNode(
        id: 'source',
        type: ScenarioNodeType.reference,
        payload: const ScenarioNodePayload(
          actionKind: kScenarioSourceEntityInteract,
        ),
        binding: ScenarioNodeBinding(mapId: _mapId, entityId: entityId),
      ),
      const ScenarioNode(
        id: 'set_legacy_flag',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
        binding: ScenarioNodeBinding(flagName: _legacyFlag),
      ),
      const ScenarioNode(id: 'end', type: ScenarioNodeType.end),
    ],
    edges: const <ScenarioEdge>[
      ScenarioEdge(
        id: 'source_to_flag',
        fromNodeId: 'source',
        toNodeId: 'set_legacy_flag',
      ),
      ScenarioEdge(
        id: 'flag_to_end',
        fromNodeId: 'set_legacy_flag',
        toNodeId: 'end',
      ),
    ],
  );
}

Future<void> _load(PlayableMapGame game) async {
  game.onGameResize(Vector2(320, 240));
  await game.onLoad();
  await _pumpUntil(game, () => !game.debugIsMapActivationDispatchInFlight);
}

bool _pressPrimary(PlayableMapGame game) {
  return game.handleRuntimeInputEvent(
    const RuntimeInputEvent.press(RuntimeInputControl.primary),
  );
}

Future<void> _pumpMicrotasks(PlayableMapGame game, {int ticks = 12}) async {
  for (var i = 0; i < ticks; i++) {
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
  }
}

Future<void> _pumpUntil(
  PlayableMapGame game,
  bool Function() done, {
  int maxTicks = 240,
}) async {
  for (var i = 0; i < maxTicks; i++) {
    if (done()) {
      return;
    }
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
  }
  fail('Timed out waiting for the Event V2 entity interaction runtime.');
}
~~~~~~~~

### 25.14 `packages/map_runtime/test/playable_map_game_event_v2_boot_integration_test.dart`

~~~~~~~~dart
import 'dart:async';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/dialogue_runtime_models.dart';
import 'package:map_runtime/src/application/narrative_runtime_activity_gate.dart';

const _mapId = 'event_v2_boot_map';
const _eventId = 'evt_019abcde-1000-7000-8000-000000000001';
const _sceneId = 'scene_event_v2_boot';
const _factId = 'fact.event_v2.boot_scene_completed';
const _legacyFlag = 'test.event_v2.legacy_fallback_must_not_run';
const _dialogueEventId = 'evt_019abcde-1000-7000-8000-000000000002';
const _dialogueSceneId = 'scene_event_v2_boot_dialogue';
const _dialogueId = 'dialogue_event_v2_boot';
const _dialogueFactId = 'fact.event_v2.boot_dialogue_completed';
const _retryEventId = 'evt_019abcde-1000-7000-8000-000000000003';
const _retrySceneId = 'scene_event_v2_boot_retry';
const _retryOutcomeId = 'boot.retry';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('v2Only mapEnter executes the real Scene and suppresses legacy',
      () async {
    final bundle = _bundle();
    final game = PlayableMapGame(
      bundle: bundle,
      projectFilePath: '/tmp/event_v2_boot/project.json',
    );

    game.onGameResize(Vector2(320, 240));
    await game.onLoad();
    await _waitForActivationDispatch(game);

    final state = game.gameStateSnapshot;
    expect(state.narrativeFactRuntimeState.overridesByFactId[_factId], isTrue);
    expect(
      state.narrativeEventProgress.consumedNarrativeEventIds,
      contains(_eventId),
      reason: 'The one-shot Event must be committed by the F1 coordinator.',
    );
    expect(
      state.storyFlags.activeFlags,
      isNot(contains(_legacyFlag)),
      reason: 'v2Only authority must never invoke the legacy Scenario.',
    );
    expect(game.debugCompletedMapActivationDispatchCount, 1);
    expect(
      game.debugLastCompletedMapActivation?.reason,
      MapActivationReason.initialBoot,
    );
  });

  test('dualRead validated ineligible claim suppresses legacy fallback',
      () async {
    final game = PlayableMapGame(
      bundle: _dualReadClaimedBundle(),
      projectFilePath: '/tmp/event_v2_dual_read/project.json',
    );

    game.onGameResize(Vector2(320, 240));
    await game.onLoad();
    await _waitForActivationDispatch(game);

    final state = game.gameStateSnapshot;
    expect(state.storyFlags.activeFlags, isNot(contains(_legacyFlag)));
    expect(
      state.narrativeFactRuntimeState.overridesByFactId,
      isNot(contains(_factId)),
      reason: 'The claimed Event is disabled and its Scene must not execute.',
    );
    expect(
      state.narrativeEventProgress.consumedNarrativeEventIds,
      isNot(contains(_eventId)),
    );
    expect(game.debugCompletedMapActivationDispatchCount, 1);
  });

  test('boot Scene dialogue starts after onLoad and remains interactive',
      () async {
    final game = _LifecycleTestPlayableMapGame(
      bundle: _dialogueBundle(),
      projectFilePath: '/tmp/event_v2_boot_dialogue/project.json',
      dialogueSessionLoader: (_) async => _singleLineDialogueSession(),
    );

    game.onGameResize(Vector2(320, 240));
    await game.onLoad().timeout(const Duration(seconds: 2));

    expect(game.debugIsMapActivationDispatchInFlight, isTrue);
    await _waitUntil(game, () => game.debugFlowPhaseName == 'dialogue');
    expect(game.debugCompletedMapActivationDispatchCount, 0);
    expect(
      game.gameStateSnapshot.narrativeEventProgress.consumedNarrativeEventIds,
      isNot(contains(_dialogueEventId)),
    );

    expect(
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.press(RuntimeInputControl.primary),
      ),
      isTrue,
    );
    await _waitForActivationDispatch(game);

    final state = game.gameStateSnapshot;
    expect(state.narrativeEventProgress.consumedNarrativeEventIds,
        contains(_dialogueEventId));
    expect(
      state.narrativeFactRuntimeState.overridesByFactId[_dialogueFactId],
      isTrue,
    );
    expect(game.debugCompletedMapActivationDispatchCount, 1);
    expect(
      game.debugLastCompletedMapActivation?.reason,
      MapActivationReason.initialBoot,
    );
  });

  test(
    'boot outcome retry stays pending without escaping its detached task',
    () async {
      final gate = NarrativeRuntimeActivityGate();
      final repository = _CheckpointCountingRepository(gate);
      var outcomePreparationCount = 0;
      final game = PlayableMapGame(
        bundle: _retryBundle(),
        projectFilePath: '/tmp/event_v2_boot_retry/project.json',
        narrativeRuntimeActivityGate: gate,
        saveRepository: repository,
        beforeNarrativeAuthorityPreparation: (occurrence) async {
          if (occurrence.source.kind !=
              NarrativeEventSourceKind.outcomeReceived) {
            return;
          }
          outcomePreparationCount++;
          throw StateError('retryable boot outcome infrastructure failure');
        },
      );

      final uncaughtErrors = await _captureDetachedErrors(() async {
        game.onGameResize(Vector2(320, 240));
        await game.onLoad();
        await _waitUntil(
          game,
          () =>
              !game.debugIsMapActivationDispatchInFlight &&
              !game.debugIsNarrativeOutcomeWorkInFlight,
        );
        await Future<void>.delayed(Duration.zero);
      });

      final state = game.gameStateSnapshot;
      final pending =
          state.narrativeEventProgress.pendingNarrativeOutcomeDeliveries;
      expect(uncaughtErrors, isEmpty);
      expect(outcomePreparationCount, 1);
      expect(pending, hasLength(1));
      expect(pending.single.outcome.outcomeId, _retryOutcomeId);
      expect(pending.single.attemptCount, 1);
      expect(
        state.narrativeEventProgress.deliveredNarrativeOutcomeDeliveryIds,
        isEmpty,
      );
      expect(
        state.narrativeEventProgress.consumedNarrativeEventIds,
        contains(_retryEventId),
      );
      expect(game.debugCompletedMapActivationDispatchCount, 1);
      expect(game.debugIsGameplayInputLocked, isFalse);
      expect(gate.activity, NarrativeRuntimeActivity.idle);
      expect(await game.saveGame(), isTrue);
      expect(repository.saveCount, 1);
      expect(
        repository.storedState!.narrativeEventProgress
            .pendingNarrativeOutcomeDeliveries.single.attemptCount,
        1,
        reason: 'Saving must preserve the durable retry for a later reload.',
      );
    },
  );
}

Future<List<Object>> _captureDetachedErrors(
  Future<void> Function() body,
) async {
  final errors = <Object>[];
  final bodyCompleted = Completer<void>();
  runZonedGuarded(
    () {
      body().then<void>(
        (_) => bodyCompleted.complete(),
        onError: (Object error, StackTrace stackTrace) {
          bodyCompleted.completeError(error, stackTrace);
        },
      );
    },
    (error, _) => errors.add(error),
  );
  await bodyCompleted.future;
  return errors;
}

final class _CheckpointCountingRepository implements GameSaveRepository {
  _CheckpointCountingRepository(this.gate);

  final NarrativeRuntimeActivityGate gate;
  GameState? storedState;
  int saveCount = 0;

  @override
  Future<void> save(GameState state) {
    return gate.runCheckpoint(
      NarrativeRuntimeCheckpointOperation.save,
      () async {
        saveCount++;
        storedState = state;
      },
    );
  }

  @override
  Future<GameState?> load() async => storedState;

  @override
  Future<bool> exists() async => storedState != null;

  @override
  Future<void> delete() async {
    storedState = null;
  }
}

final class _LifecycleTestPlayableMapGame extends PlayableMapGame {
  _LifecycleTestPlayableMapGame({
    required super.bundle,
    required super.projectFilePath,
    required super.dialogueSessionLoader,
  });

  bool _onLoadCompleted = false;

  @override
  bool get isLoaded => _onLoadCompleted;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _onLoadCompleted = true;
  }
}

RuntimeMapBundle _bundle() {
  final scene = _scene();
  final registry = NarrativeEventRegistry(
    schemaVersion: 1,
    mode: EventSystemMode.v2Only,
    records: <NarrativeEventRecord>[
      _record(enabled: true),
    ],
    legacyClaims: const [],
  );
  return _bundleForRegistry(registry, scene);
}

RuntimeMapBundle _dialogueBundle() {
  final registry = NarrativeEventRegistry(
    schemaVersion: 1,
    mode: EventSystemMode.v2Only,
    records: <NarrativeEventRecord>[
      NarrativeEventRecord.configuredStructurallyUnchecked(
        NarrativeEventDefinition(
          id: _dialogueEventId,
          name: 'Boot dialogue Event V2',
          source: NarrativeEventSourceRef.mapEnter(_mapId),
          conditions: const <NarrativeEventCondition>[],
          sceneId: _dialogueSceneId,
          reusePolicy: NarrativeEventReusePolicy.oneShot,
          priority: 0,
          order: 0,
        ),
        enabled: true,
      ),
    ],
    legacyClaims: const <LegacySourceClaim>[],
  );
  final project = ProjectManifest(
    name: 'Event V2 boot dialogue integration',
    maps: const <ProjectMapEntry>[
      ProjectMapEntry(
        id: _mapId,
        name: 'Event V2 Boot Map',
        relativePath: 'maps/event_v2_boot.json',
      ),
    ],
    tilesets: const <ProjectTilesetEntry>[],
    dialogues: const <ProjectDialogueEntry>[
      ProjectDialogueEntry(
        id: _dialogueId,
        name: 'Boot dialogue',
        relativePath: 'dialogues/boot.yarn',
      ),
    ],
    facts: <NarrativeFactDefinition>[
      NarrativeFactDefinition(
        id: _dialogueFactId,
        label: 'Boot dialogue completed',
      ),
    ],
    eventRegistry: registry,
    scenes: <SceneAsset>[_dialogueScene()],
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
  );
  return RuntimeMapBundle(
    manifest: project,
    map: _map(),
    projectRootDirectory: '/tmp/event_v2_boot_dialogue',
    tilesetAbsolutePathsById: const <String, String>{},
  );
}

RuntimeMapBundle _retryBundle() {
  final registry = NarrativeEventRegistry(
    schemaVersion: 1,
    mode: EventSystemMode.v2Only,
    records: <NarrativeEventRecord>[
      NarrativeEventRecord.configuredStructurallyUnchecked(
        NarrativeEventDefinition(
          id: _retryEventId,
          name: 'Boot retry producer',
          source: NarrativeEventSourceRef.mapEnter(_mapId),
          conditions: const <NarrativeEventCondition>[],
          sceneId: _retrySceneId,
          reusePolicy: NarrativeEventReusePolicy.oneShot,
          priority: 0,
          order: 0,
        ),
        enabled: true,
      ),
    ],
    legacyClaims: const <LegacySourceClaim>[],
  );
  return _bundleForRegistry(registry, _retryOutcomeScene());
}

SceneAsset _retryOutcomeScene() => SceneAsset(
      id: _retrySceneId,
      name: 'Event V2 boot retry producer',
      declaredOutcomes: <SceneOutcome>[
        SceneOutcome(id: _retryOutcomeId, label: 'Boot retry'),
      ],
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: <SceneNode>[
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'end',
            kind: SceneNodeKind.end,
            payload: SceneEndPayload(sceneOutcomeId: _retryOutcomeId),
          ),
        ],
        edges: <SceneEdge>[
          SceneEdge(
            id: 'start_to_end',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: 'end',
            kind: SceneEdgeKind.defaultFlow,
          ),
        ],
      ),
    );

SceneAsset _dialogueScene() => SceneAsset(
      id: _dialogueSceneId,
      name: 'Event V2 boot dialogue Scene',
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: <SceneNode>[
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'dialogue',
            kind: SceneNodeKind.yarnDialogue,
            payload: SceneYarnDialoguePayload(dialogueId: _dialogueId),
          ),
          SceneNode(
            id: 'set_fact',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.consequence(
              SceneConsequence.setFact(
                factId: _dialogueFactId,
                value: true,
              ),
            ),
          ),
          SceneNode(id: 'end', kind: SceneNodeKind.end),
        ],
        edges: <SceneEdge>[
          SceneEdge(
            id: 'start_to_dialogue',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: 'dialogue',
            kind: SceneEdgeKind.defaultFlow,
          ),
          SceneEdge(
            id: 'dialogue_to_fact',
            fromNodeId: 'dialogue',
            fromPortId: 'completed',
            toNodeId: 'set_fact',
            kind: SceneEdgeKind.defaultFlow,
          ),
          SceneEdge(
            id: 'fact_to_end',
            fromNodeId: 'set_fact',
            fromPortId: 'completed',
            toNodeId: 'end',
            kind: SceneEdgeKind.actionCompleted,
          ),
        ],
      ),
    );

DialogueSession _singleLineDialogueSession() {
  return DialogueSession.start(
    <YarnNode>[
      YarnNode(
        title: 'Start',
        steps: <YarnStep>[YarnStepLine('Bienvenue.')],
      ),
    ],
    'Start',
  )!;
}

Future<void> _waitForActivationDispatch(PlayableMapGame game) {
  return _waitUntil(
    game,
    () => !game.debugIsMapActivationDispatchInFlight,
  );
}

Future<void> _waitUntil(
  PlayableMapGame game,
  bool Function() done, {
  int maxTicks = 240,
}) async {
  for (var i = 0; i < maxTicks; i++) {
    if (done()) {
      return;
    }
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
  }
  fail('Timed out waiting for the runtime activation dispatch.');
}

RuntimeMapBundle _dualReadClaimedBundle() {
  final source = NarrativeEventSourceRef.mapEnter(_mapId);
  final provenance = LegacySourceRef.scenarioSourceNode(
    _legacyMapEnterScenario.id,
    'source',
  );
  final member = LegacySourceClaimMember(
    provenance: provenance,
    sourceFingerprint: computeScenarioSourceFingerprint(
      scenarioId: _legacyMapEnterScenario.id,
      nodeId: 'source',
      scenario: _legacyMapEnterScenario,
    ),
  );
  final cohortId = computeLegacySourceCohortId(source, [provenance]);
  final claim = LegacySourceClaim(
    cohortId: cohortId,
    source: source,
    members: [member],
    cohortFingerprint: computeLegacySourceCohortFingerprint(
      cohortId,
      [member],
    ),
    targetEventIds: const [_eventId],
    migrationReceiptId: 'receipt-event-v2-boot-dual-read',
  );
  final registry = NarrativeEventRegistry(
    schemaVersion: 1,
    mode: EventSystemMode.dualRead,
    records: <NarrativeEventRecord>[_record(enabled: false)],
    legacyClaims: <LegacySourceClaim>[claim],
  );
  return _bundleForRegistry(registry, _scene());
}

NarrativeEventRecord _record({required bool enabled}) {
  return NarrativeEventRecord.configuredStructurallyUnchecked(
    NarrativeEventDefinition(
      id: _eventId,
      name: 'Boot Event V2',
      source: NarrativeEventSourceRef.mapEnter(_mapId),
      conditions: const <NarrativeEventCondition>[],
      sceneId: _sceneId,
      reusePolicy: NarrativeEventReusePolicy.oneShot,
      priority: 0,
      order: 0,
    ),
    enabled: enabled,
  );
}

SceneAsset _scene() {
  return SceneAsset(
    id: _sceneId,
    name: 'Event V2 boot Scene',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: <SceneNode>[
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'set_fact',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.setFact(factId: _factId, value: true),
          ),
        ),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ],
      edges: <SceneEdge>[
        SceneEdge(
          id: 'start_to_fact',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'set_fact',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'fact_to_end',
          fromNodeId: 'set_fact',
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.actionCompleted,
        ),
      ],
    ),
  );
}

RuntimeMapBundle _bundleForRegistry(
  NarrativeEventRegistry registry,
  SceneAsset scene,
) {
  final project = ProjectManifest(
    name: 'Event V2 boot integration',
    maps: const <ProjectMapEntry>[
      ProjectMapEntry(
        id: _mapId,
        name: 'Event V2 Boot Map',
        relativePath: 'maps/event_v2_boot.json',
      ),
    ],
    tilesets: const <ProjectTilesetEntry>[],
    facts: <NarrativeFactDefinition>[
      NarrativeFactDefinition(
        id: _factId,
        label: 'Boot Scene completed',
      ),
    ],
    scenarios: const <ScenarioAsset>[_legacyMapEnterScenario],
    eventRegistry: registry,
    scenes: <SceneAsset>[scene],
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
  );
  return RuntimeMapBundle(
    manifest: project,
    map: _map(),
    projectRootDirectory: '/tmp/event_v2_boot',
    tilesetAbsolutePathsById: const <String, String>{},
  );
}

MapData _map() => const MapData(
      id: _mapId,
      name: 'Event V2 Boot Map',
      size: GridSize(width: 3, height: 3),
      layers: <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: <MapEntity>[
        MapEntity(
          id: 'spawn',
          name: 'Spawn',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 1, y: 1),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.south,
          ),
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: 'spawn'),
    );

const _legacyMapEnterScenario = ScenarioAsset(
  id: 'legacy_map_enter_must_not_run',
  name: 'Legacy mapEnter must not run',
  scope: ScenarioScope.localEventFlow,
  entryNodeId: 'source',
  nodes: <ScenarioNode>[
    ScenarioNode(
      id: 'source',
      type: ScenarioNodeType.reference,
      payload: ScenarioNodePayload(actionKind: kScenarioSourceMapEnter),
      binding: ScenarioNodeBinding(mapId: _mapId),
    ),
    ScenarioNode(
      id: 'set_legacy_flag',
      type: ScenarioNodeType.action,
      payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
      binding: ScenarioNodeBinding(flagName: _legacyFlag),
    ),
    ScenarioNode(id: 'end', type: ScenarioNodeType.end),
  ],
  edges: <ScenarioEdge>[
    ScenarioEdge(
      id: 'source_to_flag',
      fromNodeId: 'source',
      toNodeId: 'set_legacy_flag',
    ),
    ScenarioEdge(
      id: 'flag_to_end',
      fromNodeId: 'set_legacy_flag',
      toNodeId: 'end',
    ),
  ],
);
~~~~~~~~

### 25.15 `packages/map_runtime/test/playable_map_game_initial_save_restore_activation_test.dart`

~~~~~~~~dart
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

const _sourceMapId = 'initial_bundle_map';
const _restoredMapId = 'restored_boot_map';
const _restoredFlag = 'test.initial_save_restore.map_enter';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('explicit saveRestore boot restores map and pose before one mapEnter',
      () async {
    final project = _project();
    final bundles = <String, RuntimeMapBundle>{
      _sourceMapId: _bundle(project, _sourceMap()),
      _restoredMapId: _bundle(project, _restoredMap()),
    };
    Future<RuntimeMapBundle> loadBundle({
      required String projectFilePath,
      required String mapId,
    }) async {
      return bundles[mapId] ?? (throw StateError('Unknown map $mapId'));
    }

    final game = PlayableMapGame(
      bundle: bundles[_sourceMapId]!,
      projectFilePath: '/tmp/initial_save_restore/project.json',
      saveData: const SaveData(
        saveId: 'versioned-launch-save',
        currentMapId: _restoredMapId,
        playerPosition: GridPos(x: 2, y: 1),
        playerFacing: EntityFacing.west,
      ),
      initialMapActivationReason: MapActivationReason.saveRestore,
      runtimeMapBundleLoader: loadBundle,
    );

    game.onGameResize(Vector2(320, 240));
    await game.onLoad();
    await _waitForActivationDispatch(game);

    expect(game.gameStateSnapshot.currentMapId, _restoredMapId);
    expect(game.debugPlayerGridPosition, const GridPos(x: 2, y: 1));
    expect(game.gameStateSnapshot.playerFacing, EntityFacing.west);
    expect(
        game.gameStateSnapshot.storyFlags.activeFlags, contains(_restoredFlag));
    expect(game.debugCompletedMapActivationDispatchCount, 1);
    expect(
      game.debugLastCompletedMapActivation?.reason,
      MapActivationReason.saveRestore,
    );
    expect(game.debugLastCompletedMapActivation?.mapId, _restoredMapId);
  });
}

Future<void> _waitForActivationDispatch(PlayableMapGame game) async {
  for (var i = 0; i < 240; i++) {
    if (!game.debugIsMapActivationDispatchInFlight) {
      return;
    }
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
  }
  fail('Timed out waiting for the saveRestore activation dispatch.');
}

ProjectManifest _project() {
  return const ProjectManifest(
    name: 'Initial save restore integration',
    maps: <ProjectMapEntry>[
      ProjectMapEntry(
        id: _sourceMapId,
        name: 'Initial Bundle Map',
        relativePath: 'maps/initial.json',
      ),
      ProjectMapEntry(
        id: _restoredMapId,
        name: 'Restored Boot Map',
        relativePath: 'maps/restored.json',
      ),
    ],
    tilesets: <ProjectTilesetEntry>[],
    scenarios: <ScenarioAsset>[_restoredMapEnterScenario],
    surfaceCatalog: ProjectSurfaceCatalog.empty(),
  );
}

RuntimeMapBundle _bundle(ProjectManifest project, MapData map) {
  return RuntimeMapBundle(
    manifest: project,
    map: map,
    projectRootDirectory: '/tmp/initial_save_restore',
    tilesetAbsolutePathsById: const <String, String>{},
  );
}

MapData _sourceMap() => const MapData(
      id: _sourceMapId,
      name: 'Initial Bundle Map',
      size: GridSize(width: 3, height: 3),
      layers: <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: <MapEntity>[
        MapEntity(
          id: 'source_spawn',
          name: 'Source Spawn',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 0, y: 0),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.south,
          ),
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: 'source_spawn'),
    );

MapData _restoredMap() => const MapData(
      id: _restoredMapId,
      name: 'Restored Boot Map',
      size: GridSize(width: 4, height: 3),
      layers: <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: <MapEntity>[
        MapEntity(
          id: 'restored_spawn',
          name: 'Restored Spawn',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 0, y: 0),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.south,
          ),
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: 'restored_spawn'),
    );

const _restoredMapEnterScenario = ScenarioAsset(
  id: 'restored_boot_map_enter_scenario',
  name: 'Restored boot map enter',
  scope: ScenarioScope.localEventFlow,
  entryNodeId: 'source_map_enter',
  nodes: <ScenarioNode>[
    ScenarioNode(
      id: 'source_map_enter',
      type: ScenarioNodeType.reference,
      payload: ScenarioNodePayload(actionKind: kScenarioSourceMapEnter),
      binding: ScenarioNodeBinding(mapId: _restoredMapId),
    ),
    ScenarioNode(
      id: 'set_restored_flag',
      type: ScenarioNodeType.action,
      payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
      binding: ScenarioNodeBinding(flagName: _restoredFlag),
    ),
    ScenarioNode(id: 'end', type: ScenarioNodeType.end),
  ],
  edges: <ScenarioEdge>[
    ScenarioEdge(
      id: 'source_to_flag',
      fromNodeId: 'source_map_enter',
      toNodeId: 'set_restored_flag',
    ),
    ScenarioEdge(
      id: 'flag_to_end',
      fromNodeId: 'set_restored_flag',
      toNodeId: 'end',
    ),
  ],
);
~~~~~~~~

### 25.16 `packages/map_runtime/test/playable_map_game_map_activation_interlock_test.dart`

~~~~~~~~dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/dialogue_runtime_models.dart';
import 'package:path/path.dart' as p;

const _sourceMapId = 'activation_interlock_source';
const _targetMapId = 'activation_interlock_target';
const _eventId = 'evt_019abcde-2000-7000-8000-000000000001';
const _sceneId = 'scene_activation_interlock_target_enter';
const _factId = 'fact.activation_interlock.target_enter_completed';
const _targetMapEnterOutcomeId = 'target_map_enter_completed';
const _legacyFlag = 'test.activation_interlock.legacy_must_not_run';
const _legacyOutcomeId = 'activation_interlock_transition_requested';
const _legacyChildOutcomeId = 'activation_interlock_child_after_transition';
const _legacyOutcomeProducerSceneId =
    'scene_activation_interlock_outcome_producer';
const _legacyOutcomeProducerScenarioId = 'legacy_restored_outcome_transition';
const _legacyTransitionDialogueId = 'legacy_restored_outcome_dialogue';
const _legacyMapEnterAFlag = 'test.activation_interlock.map_enter_a';
const _legacyMapEnterBFlag = 'test.activation_interlock.map_enter_b';
const _legacyDeliveryId = 'outd_019abcde-4000-7000-8000-000000000001';
const _legacyExecutionId = 'evx_019abcde-4000-7000-8000-000000000002';
const _legacyCorrelationId = 'corr_019abcde-4000-7000-8000-000000000003';
const _retryOutcomeId = 'activation_interlock_retry_outcome';
const _retryDeliveryId = 'outd_019abcde-4000-7000-8000-000000000011';
const _retryExecutionId = 'evx_019abcde-4000-7000-8000-000000000012';
const _retryCorrelationId = 'corr_019abcde-4000-7000-8000-000000000013';
const _physicalWarpRetryEventId = 'evt_019abcde-4000-7000-8000-000000000021';
const _physicalWarpRetrySceneId = 'scene_physical_warp_retry_producer';
const _physicalWarpRetryOutcomeId = 'physical_warp.retry';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'connection mapEnter dispatch interlocks movement, transitions and checkpoints',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'runtime_map_activation_interlock_',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });
      final projectFilePath = await _writeProject(root);
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: _sourceMapId,
      );
      final preparationStarted = Completer<void>();
      final releasePreparation = Completer<void>();
      var targetPreparationCount = 0;
      final repository = _CountingGameSaveRepository(
        const GameState(
          saveId: 'load-must-not-run',
          currentMapId: _sourceMapId,
          playerPosition: GridPos(x: 1, y: 0),
        ),
      );
      final game = _TestPlayableMapGame(
        bundle: bundle,
        projectFilePath: projectFilePath,
        saveRepository: repository,
        beforeNarrativeAuthorityPreparation: (occurrence) async {
          if (occurrence.source !=
              NarrativeEventSourceRef.mapEnter(_targetMapId)) {
            return;
          }
          targetPreparationCount++;
          if (!preparationStarted.isCompleted) {
            preparationStarted.complete();
          }
          await releasePreparation.future;
        },
      );

      game.onGameResize(Vector2(640, 480));
      await game.onLoad();
      await _pumpUntil(
        game,
        () => !game.debugIsMapActivationDispatchInFlight,
      );
      expect(game.debugCompletedMapActivationDispatchCount, 1);
      final initialActivationId =
          game.debugLastCompletedMapActivation?.activationId;

      await _runSingleMove(game, RuntimeInputControl.right);
      await preparationStarted.future.timeout(const Duration(seconds: 2));

      expect(game.gameStateSnapshot.currentMapId, _targetMapId);
      expect(game.debugFlowPhaseName, 'overworld');
      expect(game.debugIsMapActivationDispatchInFlight, isTrue);
      expect(game.debugPlayerGridPosition, const GridPos(x: 0, y: 0));
      expect(game.debugCompletedMapActivationDispatchCount, 1);
      expect(
        game.debugLastCompletedMapActivation?.reason,
        MapActivationReason.initialBoot,
      );
      expect(
        game.gameStateSnapshot.narrativeFactRuntimeState
            .overridesByFactId[_factId],
        isNot(isTrue),
      );

      expect(await game.loadGame(), isFalse);
      expect(repository.loadCount, 0);
      expect(await game.saveGame(), isFalse);
      expect(repository.saveCount, 0);

      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.right),
        ),
        isTrue,
      );
      for (var i = 0; i < 30; i++) {
        game.update(0.016);
        await Future<void>.delayed(Duration.zero);
      }
      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.release(RuntimeInputControl.right),
        ),
        isTrue,
      );

      expect(game.gameStateSnapshot.currentMapId, _targetMapId);
      expect(game.debugPlayerGridPosition, const GridPos(x: 0, y: 0));
      expect(game.debugCompletedMapActivationDispatchCount, 1);
      expect(
        game.debugLastCompletedMapActivation?.activationId,
        initialActivationId,
      );

      releasePreparation.complete();
      await _pumpUntil(
        game,
        () =>
            !game.debugIsMapActivationDispatchInFlight &&
            game.gameStateSnapshot.narrativeFactRuntimeState
                    .overridesByFactId[_factId] ==
                true,
      );

      final state = game.gameStateSnapshot;
      expect(targetPreparationCount, 1);
      expect(
        state.narrativeEventProgress.consumedNarrativeEventIds
            .where((id) => id == _eventId),
        hasLength(1),
      );
      expect(state.storyFlags.activeFlags, isNot(contains(_legacyFlag)));
      expect(game.debugCompletedMapActivationDispatchCount, 2);
      expect(
        game.debugLastCompletedMapActivation?.reason,
        MapActivationReason.connection,
      );
      expect(
        game.debugLastCompletedMapActivation?.activationId,
        isNot(initialActivationId),
      );
      expect(await game.saveGame(), isTrue);
      expect(repository.saveCount, 1);
    },
  );

  test(
    'load interlocks movement and connection until saveRestore dispatch',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'runtime_load_activation_interlock_',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });
      final projectFilePath = await _writeProject(root);
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: _sourceMapId,
      );
      final repository = _BlockingLoadGameSaveRepository(
        const GameState(
          saveId: 'blocked-load',
          currentMapId: _targetMapId,
          playerPosition: GridPos(x: 0, y: 0),
        ),
      );
      final game = _TestPlayableMapGame(
        bundle: bundle,
        projectFilePath: projectFilePath,
        saveRepository: repository,
      );

      game.onGameResize(Vector2(640, 480));
      await game.onLoad();
      await _pumpUntil(
        game,
        () => !game.debugIsMapActivationDispatchInFlight,
      );
      expect(game.debugCompletedMapActivationDispatchCount, 1);
      final initialActivationId =
          game.debugLastCompletedMapActivation?.activationId;

      final loadFuture = game.loadGame();
      await repository.loadStarted.future.timeout(const Duration(seconds: 2));

      expect(game.debugIsLoadActivationWorkInFlight, isTrue);
      expect(game.debugIsMapActivationDispatchInFlight, isFalse);
      expect(await game.loadGame(), isFalse);
      expect(repository.loadCount, 1);

      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.right),
        ),
        isTrue,
      );
      for (var i = 0; i < 30; i++) {
        game.update(0.016);
        await Future<void>.delayed(Duration.zero);
      }
      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.release(RuntimeInputControl.right),
        ),
        isTrue,
      );

      expect(game.gameStateSnapshot.currentMapId, _sourceMapId);
      expect(game.debugPlayerGridPosition, const GridPos(x: 1, y: 0));
      expect(game.debugHasPendingMapTransition, isFalse);
      expect(game.debugCompletedMapActivationDispatchCount, 1);
      expect(
        game.debugLastCompletedMapActivation?.activationId,
        initialActivationId,
      );

      repository.releaseLoad();
      expect(await loadFuture, isTrue);

      expect(game.debugIsLoadActivationWorkInFlight, isFalse);
      expect(game.gameStateSnapshot.currentMapId, _targetMapId);
      expect(game.debugPlayerGridPosition, const GridPos(x: 0, y: 0));
      expect(game.debugCompletedMapActivationDispatchCount, 2);
      expect(
        game.debugLastCompletedMapActivation?.reason,
        MapActivationReason.saveRestore,
      );
      expect(
        game.debugLastCompletedMapActivation?.activationId,
        isNot(initialActivationId),
      );
    },
  );

  test(
    'restored legacy outcome transition supersedes stale mapEnter activation',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'runtime_restore_outcome_transition_',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });
      final projectFilePath = await _writeLegacyOutcomeTransitionProject(root);
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: _sourceMapId,
      );
      final outcome = NarrativeOutcomeRef(
        producerKind: NarrativeOutcomeProducerKind.legacyScenario,
        producerId: _legacyOutcomeProducerScenarioId,
        outcomeId: _legacyOutcomeId,
      );
      late PlayableMapGame game;
      bool? parentDeliveredBeforeTargetMapEnter;
      game = PlayableMapGame(
        bundle: bundle,
        projectFilePath: projectFilePath,
        saveData: SaveData(
          saveId: 'restore-outcome-transition',
          currentMapId: _sourceMapId,
          playerPosition: const GridPos(x: 1, y: 0),
          narrativeEventProgress: NarrativeEventProgress(
            pendingNarrativeOutcomeDeliveries: <NarrativeOutcomeDelivery>[
              NarrativeOutcomeDelivery(
                deliveryId: _legacyDeliveryId,
                outcome: outcome,
                causationExecutionId: _legacyExecutionId,
                rootCorrelationId: _legacyCorrelationId,
                depth: 0,
                attemptCount: 0,
              ),
            ],
          ),
        ),
        initialMapActivationReason: MapActivationReason.saveRestore,
        beforeNarrativeAuthorityPreparation: (occurrence) async {
          if (occurrence.source ==
              NarrativeEventSourceRef.mapEnter(_targetMapId)) {
            parentDeliveredBeforeTargetMapEnter = game.gameStateSnapshot
                .narrativeEventProgress.deliveredNarrativeOutcomeDeliveryIds
                .contains(_legacyDeliveryId);
          }
        },
      );

      game.onGameResize(Vector2(640, 480));
      await game.onLoad().timeout(
            const Duration(seconds: 2),
          );
      await _pumpUntil(
        game,
        () => !game.debugIsMapActivationDispatchInFlight,
      );

      final state = game.gameStateSnapshot;
      expect(state.currentMapId, _targetMapId);
      expect(
          state.storyFlags.activeFlags, isNot(contains(_legacyMapEnterAFlag)));
      expect(
          state.storyFlags.activeFlags, isNot(contains(_legacyMapEnterBFlag)));
      expect(
        state.narrativeFactRuntimeState.overridesByFactId[_factId],
        isTrue,
      );
      expect(
        state.narrativeEventProgress.pendingNarrativeOutcomeDeliveries,
        isEmpty,
      );
      expect(
        state.narrativeEventProgress.deliveredNarrativeOutcomeDeliveryIds,
        contains(_legacyDeliveryId),
      );
      expect(
        parentDeliveredBeforeTargetMapEnter,
        isTrue,
        reason: 'The raw legacy parent must commit before its post-commit '
            'transition prepares the target mapEnter occurrence.',
      );
      expect(
        state.narrativeEventProgress.deliveredNarrativeOutcomeDeliveryIds,
        hasLength(2),
        reason: 'The restored delivery and the target mapEnter Scene outcome '
            'must both be drained.',
      );
      expect(game.debugCompletedMapActivationDispatchCount, 1);
      expect(
        game.debugLastCompletedMapActivation?.reason,
        MapActivationReason.warp,
      );
    },
  );

  test(
    'restored legacy outcome keeps transition ownership after an awaited '
    'dialogue continuation',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'runtime_restore_dialogue_transition_',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });
      final projectFilePath = await _writeLegacyOutcomeTransitionProject(
        root,
        awaitDialogueBeforeTransition: true,
      );
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: _sourceMapId,
      );
      final outcome = NarrativeOutcomeRef(
        producerKind: NarrativeOutcomeProducerKind.legacyScenario,
        producerId: _legacyOutcomeProducerScenarioId,
        outcomeId: _legacyOutcomeId,
      );
      late PlayableMapGame game;
      var sourceMapEnterCount = 0;
      var targetMapEnterCount = 0;
      bool? parentDeliveredBeforeTargetMapEnter;
      game = _TestPlayableMapGame(
        bundle: bundle,
        projectFilePath: projectFilePath,
        saveData: SaveData(
          saveId: 'restore-dialogue-transition',
          currentMapId: _sourceMapId,
          playerPosition: const GridPos(x: 1, y: 0),
          narrativeEventProgress: NarrativeEventProgress(
            pendingNarrativeOutcomeDeliveries: <NarrativeOutcomeDelivery>[
              NarrativeOutcomeDelivery(
                deliveryId: _legacyDeliveryId,
                outcome: outcome,
                causationExecutionId: _legacyExecutionId,
                rootCorrelationId: _legacyCorrelationId,
                depth: 0,
                attemptCount: 0,
              ),
            ],
          ),
        ),
        initialMapActivationReason: MapActivationReason.saveRestore,
        dialogueSessionLoader: (_) async => _singleLineDialogueSession(),
        beforeNarrativeAuthorityPreparation: (occurrence) async {
          if (occurrence.source ==
              NarrativeEventSourceRef.mapEnter(_sourceMapId)) {
            sourceMapEnterCount++;
          }
          if (occurrence.source ==
              NarrativeEventSourceRef.mapEnter(_targetMapId)) {
            targetMapEnterCount++;
            parentDeliveredBeforeTargetMapEnter = game.gameStateSnapshot
                .narrativeEventProgress.deliveredNarrativeOutcomeDeliveryIds
                .contains(_legacyDeliveryId);
          }
        },
      );

      game.onGameResize(Vector2(640, 480));
      await game.onLoad().timeout(const Duration(seconds: 2));
      await _pumpUntil(
        game,
        () =>
            game.debugFlowPhaseName == 'dialogue' &&
            !game.debugIsNarrativeOutcomeWorkInFlight,
      );

      expect(
        game.gameStateSnapshot.narrativeEventProgress
            .deliveredNarrativeOutcomeDeliveryIds,
        contains(_legacyDeliveryId),
      );
      expect(sourceMapEnterCount, 0);
      expect(targetMapEnterCount, 0);

      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.primary),
        ),
        isTrue,
      );
      await _pumpUntil(
        game,
        () =>
            game.gameStateSnapshot.currentMapId == _targetMapId &&
            game.debugLastCompletedMapActivation?.mapId == _targetMapId &&
            !game.debugIsMapActivationDispatchInFlight &&
            !game.debugIsNarrativeOutcomeWorkInFlight,
      );

      final state = game.gameStateSnapshot;
      expect(sourceMapEnterCount, 0);
      expect(targetMapEnterCount, 1);
      expect(parentDeliveredBeforeTargetMapEnter, isTrue);
      expect(
          state.storyFlags.activeFlags, isNot(contains(_legacyMapEnterAFlag)));
      expect(
          state.storyFlags.activeFlags, isNot(contains(_legacyMapEnterBFlag)));
      expect(
        state.narrativeFactRuntimeState.overridesByFactId[_factId],
        isTrue,
      );
      expect(
        state.narrativeEventProgress.pendingNarrativeOutcomeDeliveries,
        isEmpty,
      );
      expect(game.debugCompletedMapActivationDispatchCount, 1);
      expect(
        game.debugLastCompletedMapActivation?.reason,
        MapActivationReason.warp,
      );
    },
  );

  test(
    'drains a child outcome after an outcome transition whose target mapEnter '
    'uses legacy fallback',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'runtime_restore_outcome_legacy_target_',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });
      final projectFilePath = await _writeLegacyOutcomeTransitionProject(
        root,
        emitChildBeforeTransition: true,
      );
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: _sourceMapId,
      );
      final outcome = NarrativeOutcomeRef(
        producerKind: NarrativeOutcomeProducerKind.legacyScenario,
        producerId: _legacyOutcomeProducerScenarioId,
        outcomeId: _legacyOutcomeId,
      );
      final game = PlayableMapGame(
        bundle: bundle,
        projectFilePath: projectFilePath,
        saveData: SaveData(
          saveId: 'restore-outcome-legacy-target',
          currentMapId: _sourceMapId,
          playerPosition: const GridPos(x: 1, y: 0),
          narrativeEventProgress: NarrativeEventProgress(
            pendingNarrativeOutcomeDeliveries: <NarrativeOutcomeDelivery>[
              NarrativeOutcomeDelivery(
                deliveryId: _legacyDeliveryId,
                outcome: outcome,
                causationExecutionId: _legacyExecutionId,
                rootCorrelationId: _legacyCorrelationId,
                depth: 0,
                attemptCount: 0,
              ),
            ],
          ),
        ),
        initialMapActivationReason: MapActivationReason.saveRestore,
      );

      game.onGameResize(Vector2(640, 480));
      await game.onLoad().timeout(const Duration(seconds: 2));
      await _pumpUntil(
        game,
        () => !game.debugIsMapActivationDispatchInFlight,
      );

      final state = game.gameStateSnapshot;
      expect(state.currentMapId, _targetMapId);
      expect(state.storyFlags.activeFlags, contains(_legacyMapEnterBFlag));
      expect(
        state.narrativeFactRuntimeState.overridesByFactId[_factId],
        isTrue,
      );
      expect(
        state.narrativeEventProgress.pendingNarrativeOutcomeDeliveries,
        isEmpty,
      );
      expect(
        state.narrativeEventProgress.deliveredNarrativeOutcomeDeliveryIds,
        hasLength(3),
        reason: 'The restored parent, the child emitted immediately before '
            'the transition, and the child consumer Scene outcome must all be '
            'drained even when the target mapEnter has no V2 match.',
      );
      expect(game.debugCompletedMapActivationDispatchCount, 1);
      expect(
        game.debugLastCompletedMapActivation?.reason,
        MapActivationReason.warp,
      );
    },
  );

  test(
    'does not strand a child outcome when the transitioned mapEnter authority '
    'fails closed',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'runtime_restore_outcome_failed_target_',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });
      final projectFilePath = await _writeLegacyOutcomeTransitionProject(
        root,
        emitChildBeforeTransition: true,
      );
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: _sourceMapId,
      );
      final outcome = NarrativeOutcomeRef(
        producerKind: NarrativeOutcomeProducerKind.legacyScenario,
        producerId: _legacyOutcomeProducerScenarioId,
        outcomeId: _legacyOutcomeId,
      );
      var rejectedTargetMapEnterCount = 0;
      final game = PlayableMapGame(
        bundle: bundle,
        projectFilePath: projectFilePath,
        saveData: SaveData(
          saveId: 'restore-outcome-failed-target',
          currentMapId: _sourceMapId,
          playerPosition: const GridPos(x: 1, y: 0),
          narrativeEventProgress: NarrativeEventProgress(
            pendingNarrativeOutcomeDeliveries: <NarrativeOutcomeDelivery>[
              NarrativeOutcomeDelivery(
                deliveryId: _legacyDeliveryId,
                outcome: outcome,
                causationExecutionId: _legacyExecutionId,
                rootCorrelationId: _legacyCorrelationId,
                depth: 0,
                attemptCount: 0,
              ),
            ],
          ),
        ),
        initialMapActivationReason: MapActivationReason.saveRestore,
        beforeNarrativeAuthorityPreparation: (occurrence) async {
          if (occurrence.source ==
              NarrativeEventSourceRef.mapEnter(_targetMapId)) {
            rejectedTargetMapEnterCount++;
            throw StateError('Injected target mapEnter authority failure.');
          }
        },
      );

      game.onGameResize(Vector2(640, 480));
      await game.onLoad().timeout(const Duration(seconds: 2));
      await _pumpUntil(
        game,
        () =>
            !game.debugIsMapActivationDispatchInFlight &&
            !game.debugIsNarrativeOutcomeWorkInFlight,
      );

      final state = game.gameStateSnapshot;
      expect(state.currentMapId, _targetMapId);
      expect(rejectedTargetMapEnterCount, 1);
      expect(
        state.narrativeFactRuntimeState.overridesByFactId[_factId],
        isTrue,
      );
      expect(
        state.narrativeEventProgress.pendingNarrativeOutcomeDeliveries,
        isEmpty,
      );
      expect(
        state.narrativeEventProgress.deliveredNarrativeOutcomeDeliveryIds,
        hasLength(3),
        reason: 'A failed mapEnter dispatch may reject that source, but it '
            'must not orphan outcomes already emitted by the parent adapter.',
      );
    },
  );

  test(
    'restored Scene outcome cannot enter the raw legacy Scenario adapter',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'runtime_restore_scene_outcome_mismatch_',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });
      final projectFilePath = await _writeLegacyOutcomeTransitionProject(root);
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: _sourceMapId,
      );
      final outcome = NarrativeOutcomeRef(
        producerKind: NarrativeOutcomeProducerKind.scene,
        producerId: _legacyOutcomeProducerSceneId,
        outcomeId: _legacyOutcomeId,
      );
      final game = PlayableMapGame(
        bundle: bundle,
        projectFilePath: projectFilePath,
        saveData: SaveData(
          saveId: 'restore-scene-outcome-mismatch',
          currentMapId: _sourceMapId,
          playerPosition: const GridPos(x: 1, y: 0),
          narrativeEventProgress: NarrativeEventProgress(
            pendingNarrativeOutcomeDeliveries: <NarrativeOutcomeDelivery>[
              NarrativeOutcomeDelivery(
                deliveryId: _legacyDeliveryId,
                outcome: outcome,
                causationExecutionId: _legacyExecutionId,
                rootCorrelationId: _legacyCorrelationId,
                depth: 0,
                attemptCount: 0,
              ),
            ],
          ),
        ),
        initialMapActivationReason: MapActivationReason.saveRestore,
      );

      game.onGameResize(Vector2(640, 480));
      await game.onLoad().timeout(const Duration(seconds: 2));
      await _pumpUntil(
        game,
        () => !game.debugIsMapActivationDispatchInFlight,
      );

      final state = game.gameStateSnapshot;
      expect(state.currentMapId, _sourceMapId);
      expect(state.storyFlags.activeFlags, contains(_legacyMapEnterAFlag));
      expect(
          state.storyFlags.activeFlags, isNot(contains(_legacyMapEnterBFlag)));
      expect(
        state.narrativeFactRuntimeState.overridesByFactId[_factId],
        isNot(isTrue),
      );
      expect(
        state.narrativeEventProgress.pendingNarrativeOutcomeDeliveries,
        isEmpty,
      );
      expect(
        state.narrativeEventProgress.deliveredNarrativeOutcomeDeliveryIds,
        contains(_legacyDeliveryId),
      );
      expect(game.debugCompletedMapActivationDispatchCount, 1);
      expect(
        game.debugLastCompletedMapActivation?.reason,
        MapActivationReason.saveRestore,
      );
    },
  );

  test(
    'failed restored outcome authority keeps pending delivery and load fails',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'runtime_restore_outcome_retry_',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });
      final projectFilePath = await _writeProject(root);
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: _sourceMapId,
      );
      final retryOutcome = NarrativeOutcomeRef(
        producerKind: NarrativeOutcomeProducerKind.scene,
        producerId: 'scene_activation_interlock_retry_producer',
        outcomeId: _retryOutcomeId,
      );
      final repository = _CountingGameSaveRepository(
        GameState(
          saveId: 'restore-outcome-retry',
          currentMapId: _sourceMapId,
          playerPosition: const GridPos(x: 1, y: 0),
          narrativeEventProgress: NarrativeEventProgress(
            pendingNarrativeOutcomeDeliveries: <NarrativeOutcomeDelivery>[
              NarrativeOutcomeDelivery(
                deliveryId: _retryDeliveryId,
                outcome: retryOutcome,
                causationExecutionId: _retryExecutionId,
                rootCorrelationId: _retryCorrelationId,
                depth: 0,
                attemptCount: 0,
              ),
            ],
          ),
        ),
      );
      final game = _TestPlayableMapGame(
        bundle: bundle,
        projectFilePath: projectFilePath,
        saveRepository: repository,
        beforeNarrativeAuthorityPreparation: (occurrence) async {
          if (occurrence.source.kind ==
              NarrativeEventSourceKind.outcomeReceived) {
            throw StateError('Injected restored outcome authority failure.');
          }
        },
      );

      game.onGameResize(Vector2(640, 480));
      await game.onLoad();
      await _pumpUntil(
        game,
        () => !game.debugIsMapActivationDispatchInFlight,
      );
      expect(game.debugCompletedMapActivationDispatchCount, 1);
      final initialActivation = game.debugLastCompletedMapActivation;

      expect(await game.loadGame(), isFalse);

      final state = game.gameStateSnapshot;
      expect(game.debugIsLoadActivationWorkInFlight, isFalse);
      expect(game.debugCompletedMapActivationDispatchCount, 1);
      expect(game.debugLastCompletedMapActivation, initialActivation);
      expect(
        state.narrativeEventProgress.pendingNarrativeOutcomeDeliveries,
        hasLength(1),
      );
      expect(
        state.narrativeEventProgress.pendingNarrativeOutcomeDeliveries.single
            .deliveryId,
        _retryDeliveryId,
      );
      expect(
        state.narrativeEventProgress.deliveredNarrativeOutcomeDeliveryIds,
        isNot(contains(_retryDeliveryId)),
      );
    },
  );

  test(
    'physical warp contains a target mapEnter outcome retry',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'runtime_physical_warp_retry_',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });
      final projectFilePath = await _writePhysicalWarpRetryProject(root);
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: _targetMapId,
      );
      final repository = _CountingGameSaveRepository(
        const GameState(
          saveId: 'physical-warp-retry-save',
          currentMapId: _targetMapId,
          playerPosition: GridPos(x: 0, y: 0),
        ),
      );
      var outcomePreparationCount = 0;
      final game = _TestPlayableMapGame(
        bundle: bundle,
        projectFilePath: projectFilePath,
        saveRepository: repository,
        beforeNarrativeAuthorityPreparation: (occurrence) async {
          if (occurrence.source.kind !=
              NarrativeEventSourceKind.outcomeReceived) {
            return;
          }
          outcomePreparationCount++;
          throw StateError(
            'retryable physical warp outcome infrastructure failure',
          );
        },
      );

      game.onGameResize(Vector2(640, 480));
      await game.onLoad();
      await _pumpUntil(
        game,
        () => !game.debugIsMapActivationDispatchInFlight,
      );
      expect(game.debugCompletedMapActivationDispatchCount, 1);

      final uncaughtErrors = await _captureDetachedErrors(() async {
        expect(
          game.handleRuntimeInputEvent(
            const RuntimeInputEvent.press(RuntimeInputControl.right),
          ),
          isTrue,
        );
        game.update(0.016);
        expect(
          game.handleRuntimeInputEvent(
            const RuntimeInputEvent.release(RuntimeInputControl.right),
          ),
          isTrue,
        );
        await _pumpUntil(
          game,
          () =>
              game.gameStateSnapshot.currentMapId == _sourceMapId &&
              !game.debugIsMapActivationDispatchInFlight &&
              !game.debugIsNarrativeOutcomeWorkInFlight &&
              game.gameStateSnapshot.narrativeEventProgress
                  .pendingNarrativeOutcomeDeliveries.isNotEmpty,
        );
        await Future<void>.delayed(Duration.zero);
      });

      final state = game.gameStateSnapshot;
      final pending =
          state.narrativeEventProgress.pendingNarrativeOutcomeDeliveries;
      expect(uncaughtErrors, isEmpty);
      expect(outcomePreparationCount, 1);
      expect(state.currentMapId, _sourceMapId);
      expect(state.playerPosition, const GridPos(x: 1, y: 0));
      expect(pending, hasLength(1));
      expect(pending.single.outcome.outcomeId, _physicalWarpRetryOutcomeId);
      expect(pending.single.attemptCount, 1);
      expect(
        state.narrativeEventProgress.deliveredNarrativeOutcomeDeliveryIds,
        isEmpty,
      );
      expect(
        state.narrativeEventProgress.consumedNarrativeEventIds,
        contains(_physicalWarpRetryEventId),
      );
      expect(game.debugCompletedMapActivationDispatchCount, 2);
      expect(
        game.debugLastCompletedMapActivation?.reason,
        MapActivationReason.warp,
      );
      expect(game.debugLastCompletedMapActivation?.mapId, _sourceMapId);
      expect(game.debugFlowPhaseName, 'overworld');
      expect(game.debugIsGameplayInputLocked, isFalse);
      expect(await game.saveGame(), isTrue);
      expect(repository.saveCount, 1);
      expect(
        repository._state!.narrativeEventProgress
            .pendingNarrativeOutcomeDeliveries.single.attemptCount,
        1,
      );
    },
  );
}

Future<List<Object>> _captureDetachedErrors(
  Future<void> Function() body,
) async {
  final errors = <Object>[];
  final bodyCompleted = Completer<void>();
  runZonedGuarded(
    () {
      body().then<void>(
        (_) => bodyCompleted.complete(),
        onError: (Object error, StackTrace stackTrace) {
          bodyCompleted.completeError(error, stackTrace);
        },
      );
    },
    (error, _) => errors.add(error),
  );
  await bodyCompleted.future;
  return errors;
}

final class _TestPlayableMapGame extends PlayableMapGame {
  _TestPlayableMapGame({
    required super.bundle,
    required super.projectFilePath,
    super.saveData,
    super.saveRepository,
    super.dialogueSessionLoader,
    super.initialMapActivationReason,
    super.beforeNarrativeAuthorityPreparation,
  });

  @override
  bool get isLoaded => true;
}

final class _BlockingLoadGameSaveRepository implements GameSaveRepository {
  _BlockingLoadGameSaveRepository(this._state);

  final GameState _state;
  final Completer<void> loadStarted = Completer<void>();
  final Completer<GameState?> _loadResult = Completer<GameState?>();
  int loadCount = 0;

  void releaseLoad() {
    if (!_loadResult.isCompleted) {
      _loadResult.complete(_state);
    }
  }

  @override
  Future<void> save(GameState state) async {}

  @override
  Future<GameState?> load() {
    loadCount++;
    if (!loadStarted.isCompleted) {
      loadStarted.complete();
    }
    return _loadResult.future;
  }

  @override
  Future<bool> exists() async => true;

  @override
  Future<void> delete() async {}
}

final class _CountingGameSaveRepository implements GameSaveRepository {
  _CountingGameSaveRepository(this._state);

  GameState? _state;
  int saveCount = 0;
  int loadCount = 0;

  @override
  Future<void> save(GameState state) async {
    saveCount++;
    _state = state;
  }

  @override
  Future<GameState?> load() async {
    loadCount++;
    return _state;
  }

  @override
  Future<bool> exists() async => _state != null;

  @override
  Future<void> delete() async {
    _state = null;
  }
}

Future<void> _runSingleMove(
  PlayableMapGame game,
  RuntimeInputControl control,
) async {
  expect(
    game.handleRuntimeInputEvent(RuntimeInputEvent.press(control)),
    isTrue,
  );
  game.update(0.016);
  expect(
    game.handleRuntimeInputEvent(RuntimeInputEvent.release(control)),
    isTrue,
  );
  await _pumpUntil(
    game,
    () => !game.debugIsPlayerStepping && !game.debugHasPendingMapTransition,
  );
}

Future<void> _pumpUntil(
  PlayableMapGame game,
  bool Function() done, {
  int maxTicks = 240,
}) async {
  for (var i = 0; i < maxTicks; i++) {
    if (done()) {
      return;
    }
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
  }
  fail('Timed out waiting for the runtime game to settle.');
}

Future<String> _writeProject(Directory root) async {
  final maps = <MapData>[_sourceMap(), _targetMap()];
  final manifest = ProjectManifest(
    name: 'Map activation interlock integration',
    settings: const ProjectSettings(tileWidth: 16, tileHeight: 16),
    maps: maps
        .map(
          (map) => ProjectMapEntry(
            id: map.id,
            name: map.name,
            relativePath: 'maps/${map.id}.json',
          ),
        )
        .toList(growable: false),
    tilesets: const <ProjectTilesetEntry>[],
    facts: <NarrativeFactDefinition>[
      NarrativeFactDefinition(
        id: _factId,
        label: 'Target map enter completed',
      ),
    ],
    scenarios: const <ScenarioAsset>[_legacyTargetMapEnterScenario],
    eventRegistry: NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.v2Only,
      records: <NarrativeEventRecord>[
        NarrativeEventRecord.configuredStructurallyUnchecked(
          NarrativeEventDefinition(
            id: _eventId,
            name: 'Target map enter',
            source: NarrativeEventSourceRef.mapEnter(_targetMapId),
            conditions: const <NarrativeEventCondition>[],
            sceneId: _sceneId,
            reusePolicy: NarrativeEventReusePolicy.oneShot,
            priority: 0,
            order: 0,
          ),
          enabled: true,
        ),
      ],
      legacyClaims: const <LegacySourceClaim>[],
    ),
    scenes: <SceneAsset>[_scene()],
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
  );
  final mapsDirectory = Directory(p.join(root.path, 'maps'));
  await mapsDirectory.create(recursive: true);
  for (final map in maps) {
    await File(p.join(mapsDirectory.path, '${map.id}.json')).writeAsString(
      const JsonEncoder.withIndent('  ').convert(map.toJson()),
    );
  }
  final projectFile = File(p.join(root.path, 'project.json'));
  await projectFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
  );
  return projectFile.path;
}

Future<String> _writePhysicalWarpRetryProject(Directory root) async {
  final maps = <MapData>[_sourceMap(), _targetMap()];
  final manifest = ProjectManifest(
    name: 'Physical warp retry integration',
    settings: const ProjectSettings(tileWidth: 16, tileHeight: 16),
    maps: maps
        .map(
          (map) => ProjectMapEntry(
            id: map.id,
            name: map.name,
            relativePath: 'maps/${map.id}.json',
          ),
        )
        .toList(growable: false),
    tilesets: const <ProjectTilesetEntry>[],
    eventRegistry: NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.v2Only,
      records: <NarrativeEventRecord>[
        NarrativeEventRecord.configuredStructurallyUnchecked(
          NarrativeEventDefinition(
            id: _physicalWarpRetryEventId,
            name: 'Physical warp retry producer',
            source: NarrativeEventSourceRef.mapEnter(_sourceMapId),
            conditions: const <NarrativeEventCondition>[],
            sceneId: _physicalWarpRetrySceneId,
            reusePolicy: NarrativeEventReusePolicy.oneShot,
            priority: 0,
            order: 0,
          ),
          enabled: true,
        ),
      ],
      legacyClaims: const <LegacySourceClaim>[],
    ),
    scenes: <SceneAsset>[_physicalWarpRetryScene()],
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
  );
  final mapsDirectory = Directory(p.join(root.path, 'maps'));
  await mapsDirectory.create(recursive: true);
  for (final map in maps) {
    await File(p.join(mapsDirectory.path, '${map.id}.json')).writeAsString(
      const JsonEncoder.withIndent('  ').convert(map.toJson()),
    );
  }
  final projectFile = File(p.join(root.path, 'project.json'));
  await projectFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
  );
  return projectFile.path;
}

Future<String> _writeLegacyOutcomeTransitionProject(
  Directory root, {
  bool emitChildBeforeTransition = false,
  bool awaitDialogueBeforeTransition = false,
}) async {
  final maps = <MapData>[_sourceMap(), _targetMap()];
  final manifest = ProjectManifest(
    name: 'Restored legacy outcome transition integration',
    settings: const ProjectSettings(tileWidth: 16, tileHeight: 16),
    maps: maps
        .map(
          (map) => ProjectMapEntry(
            id: map.id,
            name: map.name,
            relativePath: 'maps/${map.id}.json',
          ),
        )
        .toList(growable: false),
    tilesets: const <ProjectTilesetEntry>[],
    facts: <NarrativeFactDefinition>[
      NarrativeFactDefinition(
        id: _factId,
        label: 'Target map enter completed',
      ),
    ],
    scenarios: <ScenarioAsset>[
      if (awaitDialogueBeforeTransition)
        _legacyOutcomeDialogueTransitionScenario
      else if (emitChildBeforeTransition)
        _legacyOutcomeEmitChildTransitionScenario
      else
        _legacyOutcomeTransitionScenario,
      _legacyMapEnterAScenario,
      _legacyMapEnterBScenario,
    ],
    eventRegistry: NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.dualRead,
      records: <NarrativeEventRecord>[
        NarrativeEventRecord.configuredStructurallyUnchecked(
          NarrativeEventDefinition(
            id: _eventId,
            name: emitChildBeforeTransition
                ? 'Child outcome after restored transition'
                : 'Target map enter after restored outcome',
            source: emitChildBeforeTransition
                ? NarrativeEventSourceRef.outcomeReceived(
                    NarrativeOutcomeRef(
                      producerKind: NarrativeOutcomeProducerKind.legacyScenario,
                      producerId: _legacyOutcomeProducerScenarioId,
                      outcomeId: _legacyChildOutcomeId,
                    ),
                  )
                : NarrativeEventSourceRef.mapEnter(_targetMapId),
            conditions: const <NarrativeEventCondition>[],
            sceneId: _sceneId,
            reusePolicy: NarrativeEventReusePolicy.oneShot,
            priority: 0,
            order: 0,
          ),
          enabled: true,
        ),
      ],
      legacyClaims: const <LegacySourceClaim>[],
    ),
    scenes: <SceneAsset>[
      _scene(),
      _legacyOutcomeProducerScene(),
    ],
    dialogues: <ProjectDialogueEntry>[
      if (awaitDialogueBeforeTransition)
        const ProjectDialogueEntry(
          id: _legacyTransitionDialogueId,
          name: 'Restored outcome transition dialogue',
          relativePath: 'dialogues/legacy_restored_outcome_dialogue.yarn',
        ),
    ],
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
  );
  final mapsDirectory = Directory(p.join(root.path, 'maps'));
  await mapsDirectory.create(recursive: true);
  for (final map in maps) {
    await File(p.join(mapsDirectory.path, '${map.id}.json')).writeAsString(
      const JsonEncoder.withIndent('  ').convert(map.toJson()),
    );
  }
  final projectFile = File(p.join(root.path, 'project.json'));
  await projectFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
  );
  return projectFile.path;
}

SceneAsset _legacyOutcomeProducerScene() => SceneAsset(
      id: _legacyOutcomeProducerSceneId,
      name: 'Legacy transition outcome producer',
      declaredOutcomes: <SceneOutcome>[
        SceneOutcome(
          id: _legacyOutcomeId,
          label: 'Transition requested',
        ),
      ],
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: <SceneNode>[
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'end',
            kind: SceneNodeKind.end,
            payload: SceneEndPayload(
              sceneOutcomeId: _legacyOutcomeId,
            ),
          ),
        ],
        edges: <SceneEdge>[
          SceneEdge(
            id: 'start_to_end',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: 'end',
            kind: SceneEdgeKind.defaultFlow,
          ),
        ],
      ),
    );

SceneAsset _physicalWarpRetryScene() => SceneAsset(
      id: _physicalWarpRetrySceneId,
      name: 'Physical warp retry producer',
      declaredOutcomes: <SceneOutcome>[
        SceneOutcome(
          id: _physicalWarpRetryOutcomeId,
          label: 'Physical warp retry',
        ),
      ],
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: <SceneNode>[
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'end',
            kind: SceneNodeKind.end,
            payload: SceneEndPayload(
              sceneOutcomeId: _physicalWarpRetryOutcomeId,
            ),
          ),
        ],
        edges: <SceneEdge>[
          SceneEdge(
            id: 'start_to_end',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: 'end',
            kind: SceneEdgeKind.defaultFlow,
          ),
        ],
      ),
    );

MapData _sourceMap() => const MapData(
      id: _sourceMapId,
      name: 'Activation interlock source',
      size: GridSize(width: 2, height: 2),
      layers: <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: <MapEntity>[
        MapEntity(
          id: 'spawn_source',
          name: 'Source spawn',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 1, y: 0),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.east,
          ),
        ),
      ],
      connections: <MapConnection>[
        MapConnection(
          direction: MapConnectionDirection.east,
          targetMapId: _targetMapId,
          offset: 0,
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: 'spawn_source'),
    );

MapData _targetMap() => const MapData(
      id: _targetMapId,
      name: 'Activation interlock target',
      size: GridSize(width: 3, height: 2),
      layers: <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: <MapEntity>[
        MapEntity(
          id: 'spawn_target',
          name: 'Target spawn',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 0, y: 0),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.east,
          ),
        ),
      ],
      warps: <MapWarp>[
        MapWarp(
          id: 'warp_back_to_source',
          pos: GridPos(x: 1, y: 0),
          targetMapId: _sourceMapId,
          targetPos: GridPos(x: 1, y: 0),
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: 'spawn_target'),
    );

SceneAsset _scene() => SceneAsset(
      id: _sceneId,
      name: 'Target map enter Scene',
      declaredOutcomes: <SceneOutcome>[
        SceneOutcome(
          id: _targetMapEnterOutcomeId,
          label: 'Target map enter completed',
        ),
      ],
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: <SceneNode>[
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'set_fact',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.consequence(
              SceneConsequence.setFact(factId: _factId, value: true),
            ),
          ),
          SceneNode(
            id: 'end',
            kind: SceneNodeKind.end,
            payload: SceneEndPayload(
              sceneOutcomeId: _targetMapEnterOutcomeId,
            ),
          ),
        ],
        edges: <SceneEdge>[
          SceneEdge(
            id: 'start_to_fact',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: 'set_fact',
            kind: SceneEdgeKind.defaultFlow,
          ),
          SceneEdge(
            id: 'fact_to_end',
            fromNodeId: 'set_fact',
            fromPortId: 'completed',
            toNodeId: 'end',
            kind: SceneEdgeKind.actionCompleted,
          ),
        ],
      ),
    );

const _legacyTargetMapEnterScenario = ScenarioAsset(
  id: 'legacy_target_map_enter_must_not_run',
  name: 'Legacy target mapEnter must not run',
  scope: ScenarioScope.localEventFlow,
  entryNodeId: 'start',
  nodes: <ScenarioNode>[
    ScenarioNode(id: 'start', type: ScenarioNodeType.start),
    ScenarioNode(
      id: 'source',
      type: ScenarioNodeType.reference,
      payload: ScenarioNodePayload(actionKind: kScenarioSourceMapEnter),
      binding: ScenarioNodeBinding(mapId: _targetMapId),
    ),
    ScenarioNode(
      id: 'set_legacy_flag',
      type: ScenarioNodeType.action,
      payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
      binding: ScenarioNodeBinding(flagName: _legacyFlag),
    ),
    ScenarioNode(id: 'end', type: ScenarioNodeType.end),
  ],
  edges: <ScenarioEdge>[
    ScenarioEdge(
      id: 'start_to_source',
      fromNodeId: 'start',
      toNodeId: 'source',
    ),
    ScenarioEdge(
      id: 'source_to_flag',
      fromNodeId: 'source',
      toNodeId: 'set_legacy_flag',
    ),
    ScenarioEdge(
      id: 'flag_to_end',
      fromNodeId: 'set_legacy_flag',
      toNodeId: 'end',
    ),
  ],
);

const _legacyOutcomeTransitionScenario = ScenarioAsset(
  id: _legacyOutcomeProducerScenarioId,
  name: 'Legacy restored outcome transition',
  scope: ScenarioScope.globalStory,
  entryNodeId: 'start',
  nodes: <ScenarioNode>[
    ScenarioNode(id: 'start', type: ScenarioNodeType.start),
    ScenarioNode(
      id: 'source_outcome',
      type: ScenarioNodeType.reference,
      payload: ScenarioNodePayload(actionKind: kScenarioSourceOutcome),
      binding: ScenarioNodeBinding(outcomeId: _legacyOutcomeId),
    ),
    ScenarioNode(
      id: 'transition_to_b',
      type: ScenarioNodeType.action,
      payload: ScenarioNodePayload(actionKind: kScenarioActionTransitionMap),
      binding: ScenarioNodeBinding(
        mapId: _targetMapId,
        warpId: 'warp_back_to_source',
      ),
    ),
    ScenarioNode(id: 'end', type: ScenarioNodeType.end),
  ],
  edges: <ScenarioEdge>[
    ScenarioEdge(
      id: 'start_to_source',
      fromNodeId: 'start',
      toNodeId: 'source_outcome',
    ),
    ScenarioEdge(
      id: 'source_to_transition',
      fromNodeId: 'source_outcome',
      toNodeId: 'transition_to_b',
    ),
    ScenarioEdge(
      id: 'transition_to_end',
      fromNodeId: 'transition_to_b',
      toNodeId: 'end',
    ),
  ],
);

const _legacyOutcomeDialogueTransitionScenario = ScenarioAsset(
  id: _legacyOutcomeProducerScenarioId,
  name: 'Legacy restored outcome dialogue then transition',
  scope: ScenarioScope.globalStory,
  entryNodeId: 'start',
  nodes: <ScenarioNode>[
    ScenarioNode(id: 'start', type: ScenarioNodeType.start),
    ScenarioNode(
      id: 'source_outcome',
      type: ScenarioNodeType.reference,
      payload: ScenarioNodePayload(actionKind: kScenarioSourceOutcome),
      binding: ScenarioNodeBinding(outcomeId: _legacyOutcomeId),
    ),
    ScenarioNode(
      id: 'dialogue',
      type: ScenarioNodeType.dialogue,
      binding: ScenarioNodeBinding(dialogueId: _legacyTransitionDialogueId),
    ),
    ScenarioNode(
      id: 'transition_to_b',
      type: ScenarioNodeType.action,
      payload: ScenarioNodePayload(actionKind: kScenarioActionTransitionMap),
      binding: ScenarioNodeBinding(
        mapId: _targetMapId,
        warpId: 'warp_back_to_source',
      ),
    ),
    ScenarioNode(id: 'end', type: ScenarioNodeType.end),
  ],
  edges: <ScenarioEdge>[
    ScenarioEdge(
      id: 'start_to_source',
      fromNodeId: 'start',
      toNodeId: 'source_outcome',
    ),
    ScenarioEdge(
      id: 'source_to_dialogue',
      fromNodeId: 'source_outcome',
      toNodeId: 'dialogue',
    ),
    ScenarioEdge(
      id: 'dialogue_to_transition',
      fromNodeId: 'dialogue',
      toNodeId: 'transition_to_b',
    ),
    ScenarioEdge(
      id: 'transition_to_end',
      fromNodeId: 'transition_to_b',
      toNodeId: 'end',
    ),
  ],
);

const _legacyOutcomeEmitChildTransitionScenario = ScenarioAsset(
  id: _legacyOutcomeProducerScenarioId,
  name: 'Legacy restored outcome child then transition',
  scope: ScenarioScope.globalStory,
  entryNodeId: 'start',
  declaredOutcomes: <String>[_legacyChildOutcomeId],
  nodes: <ScenarioNode>[
    ScenarioNode(id: 'start', type: ScenarioNodeType.start),
    ScenarioNode(
      id: 'source_outcome',
      type: ScenarioNodeType.reference,
      payload: ScenarioNodePayload(actionKind: kScenarioSourceOutcome),
      binding: ScenarioNodeBinding(outcomeId: _legacyOutcomeId),
    ),
    ScenarioNode(
      id: 'emit_child',
      type: ScenarioNodeType.action,
      payload: ScenarioNodePayload(actionKind: kScenarioActionEmitOutcome),
      binding: ScenarioNodeBinding(outcomeId: _legacyChildOutcomeId),
    ),
    ScenarioNode(
      id: 'transition_to_b',
      type: ScenarioNodeType.action,
      payload: ScenarioNodePayload(actionKind: kScenarioActionTransitionMap),
      binding: ScenarioNodeBinding(
        mapId: _targetMapId,
        warpId: 'warp_back_to_source',
      ),
    ),
    ScenarioNode(id: 'end', type: ScenarioNodeType.end),
  ],
  edges: <ScenarioEdge>[
    ScenarioEdge(
      id: 'start_to_source',
      fromNodeId: 'start',
      toNodeId: 'source_outcome',
    ),
    ScenarioEdge(
      id: 'source_to_emit',
      fromNodeId: 'source_outcome',
      toNodeId: 'emit_child',
    ),
    ScenarioEdge(
      id: 'emit_to_transition',
      fromNodeId: 'emit_child',
      toNodeId: 'transition_to_b',
    ),
    ScenarioEdge(
      id: 'transition_to_end',
      fromNodeId: 'transition_to_b',
      toNodeId: 'end',
    ),
  ],
);

const _legacyMapEnterAScenario = ScenarioAsset(
  id: 'legacy_map_enter_a',
  name: 'Legacy map enter A',
  scope: ScenarioScope.localEventFlow,
  entryNodeId: 'start',
  nodes: <ScenarioNode>[
    ScenarioNode(id: 'start', type: ScenarioNodeType.start),
    ScenarioNode(
      id: 'source_map_enter_a',
      type: ScenarioNodeType.reference,
      payload: ScenarioNodePayload(actionKind: kScenarioSourceMapEnter),
      binding: ScenarioNodeBinding(mapId: _sourceMapId),
    ),
    ScenarioNode(
      id: 'set_map_enter_a',
      type: ScenarioNodeType.action,
      payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
      binding: ScenarioNodeBinding(flagName: _legacyMapEnterAFlag),
    ),
    ScenarioNode(id: 'end', type: ScenarioNodeType.end),
  ],
  edges: <ScenarioEdge>[
    ScenarioEdge(
      id: 'start_to_source_a',
      fromNodeId: 'start',
      toNodeId: 'source_map_enter_a',
    ),
    ScenarioEdge(
      id: 'source_to_flag_a',
      fromNodeId: 'source_map_enter_a',
      toNodeId: 'set_map_enter_a',
    ),
    ScenarioEdge(
      id: 'flag_to_end_a',
      fromNodeId: 'set_map_enter_a',
      toNodeId: 'end',
    ),
  ],
);

const _legacyMapEnterBScenario = ScenarioAsset(
  id: 'legacy_map_enter_b',
  name: 'Legacy map enter B',
  scope: ScenarioScope.localEventFlow,
  entryNodeId: 'start',
  nodes: <ScenarioNode>[
    ScenarioNode(id: 'start', type: ScenarioNodeType.start),
    ScenarioNode(
      id: 'source_map_enter_b',
      type: ScenarioNodeType.reference,
      payload: ScenarioNodePayload(actionKind: kScenarioSourceMapEnter),
      binding: ScenarioNodeBinding(mapId: _targetMapId),
    ),
    ScenarioNode(
      id: 'set_map_enter_b',
      type: ScenarioNodeType.action,
      payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
      binding: ScenarioNodeBinding(flagName: _legacyMapEnterBFlag),
    ),
    ScenarioNode(id: 'end', type: ScenarioNodeType.end),
  ],
  edges: <ScenarioEdge>[
    ScenarioEdge(
      id: 'start_to_source_b',
      fromNodeId: 'start',
      toNodeId: 'source_map_enter_b',
    ),
    ScenarioEdge(
      id: 'source_to_flag_b',
      fromNodeId: 'source_map_enter_b',
      toNodeId: 'set_map_enter_b',
    ),
    ScenarioEdge(
      id: 'flag_to_end_b',
      fromNodeId: 'set_map_enter_b',
      toNodeId: 'end',
    ),
  ],
);

DialogueSession _singleLineDialogueSession() {
  return DialogueSession.start(
    <YarnNode>[
      YarnNode(
        title: 'Start',
        steps: <YarnStep>[YarnStepLine('Continuer.')],
      ),
    ],
    'Start',
  )!;
}
~~~~~~~~

### 25.17 `packages/map_runtime/test/playable_map_game_map_enter_v2_integration_test.dart`

~~~~~~~~dart
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

const _mapId = 'test_map_enter_load';
const _mapEnterFlag = 'test.map_enter.after_load';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loadGame dispatches legacy mapEnter after restoring the same map',
      () async {
    final repository = _MemoryGameSaveRepository(
      const GameState(
        saveId: 'restored-save',
        currentMapId: _mapId,
        playerPosition: GridPos(x: 1, y: 1),
      ),
    );
    final game = PlayableMapGame(
      bundle: _bundle(),
      projectFilePath: '/tmp/test_map_enter_load/project.json',
      saveRepository: repository,
    );

    game.onGameResize(Vector2(320, 240));
    await game.onLoad();
    await _waitForActivationDispatch(game);

    expect(
      game.gameStateSnapshot.storyFlags.activeFlags,
      contains(_mapEnterFlag),
      reason: 'The fixture must prove that the legacy mapEnter Scenario runs.',
    );
    expect(game.debugCompletedMapActivationDispatchCount, 1);
    expect(
      game.debugLastCompletedMapActivation?.reason,
      MapActivationReason.initialBoot,
    );
    expect(game.debugLastCompletedMapActivation?.mapId, _mapId);

    expect(await game.loadGame(), isTrue);
    expect(game.gameStateSnapshot.saveId, 'restored-save');
    expect(
      game.gameStateSnapshot.storyFlags.activeFlags,
      contains(_mapEnterFlag),
      reason: 'A successful load must dispatch mapEnter after state restore.',
    );
    expect(game.debugCompletedMapActivationDispatchCount, 2);
    expect(
      game.debugLastCompletedMapActivation?.reason,
      MapActivationReason.saveRestore,
    );
    expect(game.debugLastCompletedMapActivation?.mapId, _mapId);
  });

  test('missing save target never creates a completed map activation',
      () async {
    final repository = _MemoryGameSaveRepository(
      const GameState(
        saveId: 'missing-map-save',
        currentMapId: 'missing_save_target',
        playerPosition: GridPos(x: 1, y: 1),
      ),
    );
    var loaderCalls = 0;
    final game = PlayableMapGame(
      bundle: _bundle(),
      projectFilePath: '/tmp/test_map_enter_load/project.json',
      saveRepository: repository,
      runtimeMapBundleLoader: ({
        required String projectFilePath,
        required String mapId,
      }) async {
        loaderCalls++;
        throw StateError('Map $mapId is unavailable');
      },
    );

    game.onGameResize(Vector2(320, 240));
    await game.onLoad();
    await _waitForActivationDispatch(game);

    expect(await game.loadGame(), isFalse);
    expect(loaderCalls, 1);
    expect(game.gameStateSnapshot.currentMapId, _mapId);
    expect(game.debugCompletedMapActivationDispatchCount, 1);
    expect(
      game.debugLastCompletedMapActivation?.reason,
      MapActivationReason.initialBoot,
    );
    expect(game.debugLastCompletedMapActivation?.mapId, _mapId);
  });
}

Future<void> _waitForActivationDispatch(PlayableMapGame game) async {
  for (var i = 0; i < 240; i++) {
    if (!game.debugIsMapActivationDispatchInFlight) {
      return;
    }
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
  }
  fail('Timed out waiting for the initial map activation dispatch.');
}

RuntimeMapBundle _bundle() {
  return RuntimeMapBundle(
    manifest: ProjectManifest(
      name: 'Map Enter Load Integration Test',
      maps: const <ProjectMapEntry>[
        ProjectMapEntry(
          id: _mapId,
          name: 'Map Enter Load',
          relativePath: 'maps/test_map_enter_load.json',
        ),
      ],
      tilesets: const <ProjectTilesetEntry>[],
      scenarios: const <ScenarioAsset>[_mapEnterScenario],
      surfaceCatalog: ProjectSurfaceCatalog(),
    ),
    map: const MapData(
      id: _mapId,
      name: 'Map Enter Load',
      size: GridSize(width: 3, height: 3),
      layers: <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: <MapEntity>[
        MapEntity(
          id: 'spawn_start',
          name: 'Spawn Start',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 1, y: 1),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.south,
          ),
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: 'spawn_start'),
    ),
    projectRootDirectory: '/tmp/test_map_enter_load',
    tilesetAbsolutePathsById: const <String, String>{},
  );
}

const _mapEnterScenario = ScenarioAsset(
  id: 'test_map_enter_load_scenario',
  name: 'Set flag on map enter',
  scope: ScenarioScope.localEventFlow,
  entryNodeId: 'source_map_enter',
  nodes: <ScenarioNode>[
    ScenarioNode(
      id: 'source_map_enter',
      type: ScenarioNodeType.reference,
      payload: ScenarioNodePayload(actionKind: kScenarioSourceMapEnter),
      binding: ScenarioNodeBinding(mapId: _mapId),
    ),
    ScenarioNode(
      id: 'set_map_enter_flag',
      type: ScenarioNodeType.action,
      payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
      binding: ScenarioNodeBinding(flagName: _mapEnterFlag),
    ),
    ScenarioNode(
      id: 'end',
      type: ScenarioNodeType.end,
    ),
  ],
  edges: <ScenarioEdge>[
    ScenarioEdge(
      id: 'source_to_flag',
      fromNodeId: 'source_map_enter',
      toNodeId: 'set_map_enter_flag',
    ),
    ScenarioEdge(
      id: 'flag_to_end',
      fromNodeId: 'set_map_enter_flag',
      toNodeId: 'end',
    ),
  ],
);

final class _MemoryGameSaveRepository implements GameSaveRepository {
  _MemoryGameSaveRepository(this._state);

  GameState? _state;

  @override
  Future<void> save(GameState state) async {
    _state = state;
  }

  @override
  Future<GameState?> load() async => _state;

  @override
  Future<bool> exists() async => _state != null;

  @override
  Future<void> delete() async {
    _state = null;
  }
}
~~~~~~~~

### 25.18 `packages/map_runtime/test/playable_map_game_qualified_outcome_v2_integration_test.dart`

~~~~~~~~dart
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/dialogue_runtime_models.dart';
import 'package:map_runtime/src/application/narrative_runtime_activity_gate.dart';
import 'package:map_runtime/src/application/resolve_dialogue.dart';
import 'package:map_runtime/src/application/runtime_battle_outcome_apply.dart';
import 'package:map_runtime/src/presentation/flame/playable_map_game.dart'
    show RuntimeMapBundleLoader;

const _mapId = 'qualified_outcome_map';
const _trainerId = 'qualified_outcome_trainer';
const _trainerBattleRefId = 'trainer:$_trainerId';
const _trainerDefeatedFlag = 'trainer_defeated:$_trainerId';
const _sceneVictoryProducerId = 'scene_qualified_victory_producer';
const _sharedOutcomeId = 'victory';

const _sceneConsumerFact = 'fact.qualified.scene_consumer';
const _battleConsumerFact = 'fact.qualified.battle_consumer';
const _legacyConsumerFact = 'fact.qualified.legacy_consumer';
const _legacyAsyncConsumerFact = 'fact.qualified.legacy_async_consumer';
const _legacySynchronousChildConsumerFact =
    'fact.qualified.legacy_synchronous_child_consumer';
const _legacyBattleConsumerFact = 'fact.qualified.legacy_battle_consumer';
const _legacyBattleAfterConsumerFact =
    'fact.qualified.legacy_battle_after_consumer';
const _legacyOverlapFirstConsumerFact =
    'fact.qualified.legacy_overlap_first_consumer';
const _legacyOverlapSecondConsumerFact =
    'fact.qualified.legacy_overlap_second_consumer';
const _legacyRawFirstOutcomeId = 'raw.first';
const _legacyRawSecondOutcomeId = 'raw.second';
const _legacySynchronousParentOutcomeId = 'raw.synchronous_parent';
const _legacySynchronousChildOutcomeId = 'synchronous.child';
const _legacySynchronousParentDeliveryId =
    'outd_019abcde-5170-7000-8000-000000000001';
const _legacySynchronousParentCausationId =
    'evx_019abcde-5170-7000-8000-000000000002';
const _legacySynchronousRootCorrelationId =
    'corr_019abcde-5170-7000-8000-000000000003';
const _legacySameSourceCycleMarkedFlag = 'legacy.same_source_cycle.marked';
const _legacySameSourceCycleCompletedFlag =
    'legacy.same_source_cycle.completed';
const _legacyInvalidBattleOutcomeId = 'raw.invalid_battle';
const _legacyScriptWarpOutcomeId = 'raw.script_warp';
const _legacyRawFirstDeliveryId = 'outd_019abcde-5180-7000-8000-000000000001';
const _legacyRawSecondDeliveryId = 'outd_019abcde-5180-7000-8000-000000000002';
const _legacyRawRootCorrelationId = 'corr_019abcde-5180-7000-8000-000000000003';
const _legacyInvalidBattleDeliveryId =
    'outd_019abcde-5180-7000-8000-000000000003';
const _legacyScriptWarpDeliveryId = 'outd_019abcde-5180-7000-8000-000000000004';
const _legacyRawFirstCompletedFlag = 'legacy.raw.first.completed';
const _legacyRawSecondCompletedFlag = 'legacy.raw.second.completed';
const _legacyProducerSeedFact = 'fact.legacy.producer.seed';
const _legacyProducerAfterFact = 'fact.legacy.producer.after_dialogue';
const _legacyMoveWarpCompletedFlag = 'legacy.move_warp.completed';
const _legacyFollowMoveWarpOutcomeId = 'raw.follow_move_warp';
const _legacyFollowMoveWarpChildOutcomeId = 'follow_move_warp.child';
const _legacyFollowMoveWarpDeliveryId =
    'outd_019abcde-5180-7000-8000-000000000006';
const _legacyFollowMoveWarpCompletedFlag = 'legacy.follow_move_warp.completed';
const _legacyFollowMoveWarpTargetMapId =
    'qualified_outcome_follow_move_warp_target';
const _legacyScriptWarpCompletedFlag = 'legacy.script_warp.completed';
const _legacyScriptWarpTargetMapId = 'qualified_outcome_script_warp_target';
const _legacyScriptFailureOutcomeId = 'raw.script_failure';
const _legacyScriptFailureDeliveryId =
    'outd_019abcde-5180-7000-8000-000000000005';
const _legacyScriptFailureCompletedFlag = 'legacy.script_failure.completed';
const _legacyChainedEffectCompletedFlag = 'legacy.chained_effect.completed';
const _legacyMoveReplacementFirstFlag = 'legacy.move_replace.first';
const _legacyMoveReplacementSecondFlag = 'legacy.move_replace.second';
const _legacyPlayerWarpCompletedFlag = 'legacy.player_warp.completed';
const _legacyPlayerWarpTargetMapId = 'qualified_outcome_player_warp_target';
const _legacyPhysicalWarpTargetMapId = 'qualified_outcome_physical_target';
const _legacyTransitionTargetMapId = 'qualified_outcome_transition_target';
const _hostedBattleConsumerFact = 'fact.hosted.battle_consumer';
const _hostedSceneConsumerFact = 'fact.hosted.scene_after_battle';
const _rollbackBattleConsumerFact = 'fact.hosted.rollback_must_not_dispatch';

const _battleStats = BattleStatsSnapshot(
  attack: 10,
  defense: 10,
  specialAttack: 10,
  specialDefense: 10,
  speed: 10,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlayableMapGame qualified outcome V2 integration', () {
    test(
      'keeps identical Scene/Battle outcome ids isolated and publishes '
      'standalone trainer outcome after write-back',
      () async {
        final sceneOutcome = NarrativeOutcomeRef(
          producerKind: NarrativeOutcomeProducerKind.scene,
          producerId: _sceneVictoryProducerId,
          outcomeId: _sharedOutcomeId,
        );
        final battleOutcome = NarrativeOutcomeRef(
          producerKind: NarrativeOutcomeProducerKind.battle,
          producerId: _trainerBattleRefId,
          outcomeId: _sharedOutcomeId,
        );
        late PlayableMapGame game;
        int? hpObservedBeforeBattleOutcomePlanning;
        bool? trainerFlagObservedBeforeBattleOutcomePlanning;

        game = _game(
          project: _crossProducerProject(),
          beforeNarrativeAuthorityPreparation: (occurrence) async {
            if (occurrence.source !=
                NarrativeEventSourceRef.outcomeReceived(battleOutcome)) {
              return;
            }
            final state = game.gameStateSnapshot;
            hpObservedBeforeBattleOutcomePlanning =
                state.party.members.single.currentHp;
            trainerFlagObservedBeforeBattleOutcomePlanning =
                state.storyFlags.activeFlags.contains(_trainerDefeatedFlag);
          },
        );

        await _load(game);
        await _waitUntil(
          game,
          () => _factValue(game, _sceneConsumerFact) == true,
        );

        expect(_factValue(game, _sceneConsumerFact), isTrue);
        expect(
          _factValue(game, _battleConsumerFact),
          isNot(isTrue),
          reason: 'A Scene producer must not match the Battle producer even '
              'when both publish outcomeId="$_sharedOutcomeId".',
        );
        expect(
          game.gameStateSnapshot.narrativeEventProgress
              .deliveredNarrativeOutcomeDeliveryIds,
          hasLength(1),
        );

        game.debugApplyBattleOutcomeForTest(
          context: _trainerContext(),
          outcome: _victoryOutcome(playerCurrentHp: 4),
        );
        await _waitUntil(
          game,
          () => _factValue(game, _battleConsumerFact) == true,
        );

        final state = game.gameStateSnapshot;
        expect(hpObservedBeforeBattleOutcomePlanning, 4);
        expect(trainerFlagObservedBeforeBattleOutcomePlanning, isTrue);
        expect(state.party.members.single.currentHp, 4);
        expect(state.storyFlags.activeFlags, contains(_trainerDefeatedFlag));
        expect(_factValue(game, _sceneConsumerFact), isTrue);
        expect(_factValue(game, _battleConsumerFact), isTrue);
        expect(
          state.narrativeEventProgress.deliveredNarrativeOutcomeDeliveryIds,
          hasLength(2),
        );
        expect(
          sceneOutcome,
          isNot(battleOutcome),
          reason: 'Producer kind/id are part of the structural identity.',
        );
      },
    );

    test(
      'root outcome reserves outbox authority before fire-and-forget enqueue',
      () async {
        final gate = NarrativeRuntimeActivityGate();
        final repository = _CheckpointCountingRepository(gate);
        final game = _game(
          project: _crossProducerProject(),
          narrativeRuntimeActivityGate: gate,
          saveRepository: repository,
        );

        await _load(game);
        await _waitUntil(
          game,
          () =>
              _factValue(game, _sceneConsumerFact) == true &&
              !game.debugIsNarrativeOutcomeWorkInFlight,
        );

        game.debugApplyBattleOutcomeForTest(
          context: _trainerContext(),
          outcome: _victoryOutcome(playerCurrentHp: 4),
        );

        expect(game.debugIsNarrativeOutcomeWorkInFlight, isTrue);
        expect(gate.activity, NarrativeRuntimeActivity.outboxProcessing);
        expect(await game.saveGame(), isFalse);
        expect(repository.saveCount, 0);

        await _waitUntil(
          game,
          () =>
              _factValue(game, _battleConsumerFact) == true &&
              !game.debugIsNarrativeOutcomeWorkInFlight,
        );
        expect(gate.activity, NarrativeRuntimeActivity.idle);
        expect(await game.saveGame(), isTrue);
        expect(repository.saveCount, 1);
        expect(
          repository.storedState!.narrativeEventProgress
              .deliveredNarrativeOutcomeDeliveryIds,
          hasLength(2),
        );
      },
    );

    test(
      'defers a legacy Scenario emission then routes its qualified producer '
      'through the V2 outbox',
      () async {
        final game = _game(project: _legacyScenarioProject());

        await _load(game);
        await _waitUntil(
          game,
          () => _factValue(game, _legacyConsumerFact) == true,
        );

        final state = game.gameStateSnapshot;
        expect(
          state.storyFlags.activeFlags,
          contains(scenarioOutcomeFlagName('legacy.completed')),
        );
        expect(_factValue(game, _legacyConsumerFact), isTrue);
        expect(
          state.narrativeEventProgress.pendingNarrativeOutcomeDeliveries,
          isEmpty,
        );
        expect(
          state.narrativeEventProgress.deliveredNarrativeOutcomeDeliveryIds,
          hasLength(1),
        );
      },
    );

    test(
      'inherits causation, correlation, and depth for a synchronous child '
      'emitted by the raw legacy fallback',
      () async {
        const parentDepth = 3;
        final childOutcome = NarrativeOutcomeRef(
          producerKind: NarrativeOutcomeProducerKind.legacyScenario,
          producerId: 'legacy_synchronous_child_scenario',
          outcomeId: _legacySynchronousChildOutcomeId,
        );
        final childOccurrences = <NarrativeEventOccurrence>[];
        final childDeliveries = <NarrativeOutcomeDelivery>[];
        late PlayableMapGame game;
        game = _game(
          project: _legacySynchronousChildProject(),
          initialMapActivationReason: MapActivationReason.saveRestore,
          initialState: _initialState().copyWith(
            narrativeEventProgress: NarrativeEventProgress(
              pendingNarrativeOutcomeDeliveries: <NarrativeOutcomeDelivery>[
                NarrativeOutcomeDelivery(
                  deliveryId: _legacySynchronousParentDeliveryId,
                  outcome: NarrativeOutcomeRef(
                    producerKind: NarrativeOutcomeProducerKind.legacyScenario,
                    producerId: 'raw_restore_fixture',
                    outcomeId: _legacySynchronousParentOutcomeId,
                  ),
                  causationExecutionId: _legacySynchronousParentCausationId,
                  rootCorrelationId: _legacySynchronousRootCorrelationId,
                  depth: parentDepth,
                  attemptCount: 0,
                ),
              ],
            ),
          ),
          beforeNarrativeAuthorityPreparation: (occurrence) async {
            if (occurrence.source !=
                NarrativeEventSourceRef.outcomeReceived(childOutcome)) {
              return;
            }
            childOccurrences.add(occurrence);
            childDeliveries.add(
              game.gameStateSnapshot.narrativeEventProgress
                  .pendingNarrativeOutcomeDeliveries
                  .singleWhere((delivery) => delivery.outcome == childOutcome),
            );
          },
        );

        await _load(game);
        await _waitUntil(
          game,
          () => _factValue(game, _legacySynchronousChildConsumerFact) == true,
        );

        expect(childOccurrences, hasLength(1));
        expect(
          childOccurrences.single.rootCorrelationId,
          _legacySynchronousRootCorrelationId,
        );
        expect(childOccurrences.single.depth, parentDepth + 1);
        expect(childDeliveries, hasLength(1));
        expect(
          childDeliveries.single.causationExecutionId,
          _legacySynchronousParentCausationId,
        );
        expect(
          childDeliveries.single.rootCorrelationId,
          _legacySynchronousRootCorrelationId,
        );
        expect(childDeliveries.single.depth, parentDepth + 1);
      },
    );

    test(
      'latches a synchronous completion when a valid Scenario cycle reuses '
      'the current runtime source',
      () async {
        final gate = NarrativeRuntimeActivityGate();
        final project = _legacySameSourceCycleProject();
        expect(() => ProjectValidator.validate(project), returnsNormally);
        final game = _game(
          project: project,
          narrativeRuntimeActivityGate: gate,
        );

        await _load(game);
        await _waitUntil(
          game,
          () =>
              game.gameStateSnapshot.storyFlags.activeFlags
                  .contains(_legacySameSourceCycleCompletedFlag) &&
              gate.activity == NarrativeRuntimeActivity.idle,
        );

        expect(
          game.gameStateSnapshot.storyFlags.activeFlags,
          containsAll(<String>[
            _legacySameSourceCycleMarkedFlag,
            _legacySameSourceCycleCompletedFlag,
          ]),
        );
        expect(gate.activity, NarrativeRuntimeActivity.idle);
      },
    );

    test(
      'keeps correlation and depth when a legacy Scenario emits after an '
      'awaited dialogue continuation',
      () async {
        final outcomeOccurrences = <NarrativeEventOccurrence>[];
        final game = _game(
          project: _legacyAsyncScenarioProject(),
          dialogueSessionLoader: (_) async => _singleLineDialogueSession(),
          beforeNarrativeAuthorityPreparation: (occurrence) async {
            if (occurrence.source.kind ==
                NarrativeEventSourceKind.outcomeReceived) {
              outcomeOccurrences.add(occurrence);
            }
          },
        );

        await _load(game);
        await _waitUntil(
          game,
          () =>
              game.debugFlowPhaseName == 'dialogue' &&
              !game.debugIsMapActivationDispatchInFlight,
        );

        expect(
          game.handleRuntimeInputEvent(
            const RuntimeInputEvent.press(RuntimeInputControl.primary),
          ),
          isTrue,
        );
        await _waitUntil(
          game,
          () => _factValue(game, _legacyAsyncConsumerFact) == true,
        );

        expect(outcomeOccurrences, hasLength(2));
        expect(outcomeOccurrences[0].rootCorrelationId, isNotNull);
        expect(
          outcomeOccurrences[1].rootCorrelationId,
          outcomeOccurrences[0].rootCorrelationId,
        );
        expect(outcomeOccurrences.map((value) => value.depth), <int?>[0, 1]);
        expect(
          game.gameStateSnapshot.narrativeEventProgress
              .deliveredNarrativeOutcomeDeliveryIds,
          hasLength(2),
        );
      },
    );

    test(
      'keeps both outcomes from overlapping legacy system triggers',
      () async {
        const firstTriggerId = 'a_legacy_camera_trigger';
        const secondTriggerId = 'b_legacy_camera_trigger';
        final outcomeOccurrences = <NarrativeEventOccurrence>[];
        final game = _game(
          project: _legacyOverlappingTriggerOutcomeProject(),
          triggers: const <MapTrigger>[
            MapTrigger(
              id: secondTriggerId,
              name: 'Second legacy camera trigger',
              type: TriggerType.camera,
              area: MapRect(
                pos: GridPos(x: 1, y: 2),
                size: GridSize(width: 1, height: 1),
              ),
            ),
            MapTrigger(
              id: firstTriggerId,
              name: 'First legacy camera trigger',
              type: TriggerType.camera,
              area: MapRect(
                pos: GridPos(x: 1, y: 2),
                size: GridSize(width: 1, height: 1),
              ),
            ),
          ],
          beforeNarrativeAuthorityPreparation: (occurrence) async {
            if (occurrence.source.kind ==
                NarrativeEventSourceKind.outcomeReceived) {
              outcomeOccurrences.add(occurrence);
            }
          },
        );

        await _load(game);
        await _waitUntil(
          game,
          () =>
              !game.debugIsMapActivationDispatchInFlight &&
              !game.debugIsNarrativeOutcomeWorkInFlight,
        );
        expect(
          game.handleRuntimeInputEvent(
            const RuntimeInputEvent.press(RuntimeInputControl.down),
          ),
          isTrue,
        );
        game.update(0.016);
        await Future<void>.delayed(Duration.zero);
        expect(
          game.handleRuntimeInputEvent(
            const RuntimeInputEvent.release(RuntimeInputControl.down),
          ),
          isTrue,
        );
        await _waitUntil(
          game,
          () =>
              _factValue(game, _legacyOverlapFirstConsumerFact) == true &&
              _factValue(game, _legacyOverlapSecondConsumerFact) == true,
        );

        expect(outcomeOccurrences, hasLength(2));
        expect(
          outcomeOccurrences.map((occurrence) => occurrence.source),
          <NarrativeEventSourceRef>[
            NarrativeEventSourceRef.outcomeReceived(
              NarrativeOutcomeRef(
                producerKind: NarrativeOutcomeProducerKind.legacyScenario,
                producerId: 'legacy_overlap_first_scenario',
                outcomeId: 'overlap.first',
              ),
            ),
            NarrativeEventSourceRef.outcomeReceived(
              NarrativeOutcomeRef(
                producerKind: NarrativeOutcomeProducerKind.legacyScenario,
                producerId: 'legacy_overlap_second_scenario',
                outcomeId: 'overlap.second',
              ),
            ),
          ],
        );
        expect(
          game.gameStateSnapshot.narrativeEventProgress
              .pendingNarrativeOutcomeDeliveries,
          isEmpty,
        );
        expect(
          game.gameStateSnapshot.narrativeEventProgress
              .deliveredNarrativeOutcomeDeliveryIds,
          hasLength(2),
        );
      },
    );

    test(
      'commits a suspended raw legacy head but keeps the next FIFO delivery '
      'pending until its dialogue continuation completes',
      () async {
        final outcomeOccurrences = <NarrativeEventOccurrence>[];
        final game = _game(
          project: _legacyRawDialogueBarrierProject(),
          initialState: _initialState().copyWith(
            narrativeEventProgress: NarrativeEventProgress(
              pendingNarrativeOutcomeDeliveries: <NarrativeOutcomeDelivery>[
                _rawLegacyDelivery(
                  deliveryId: _legacyRawFirstDeliveryId,
                  outcomeId: _legacyRawFirstOutcomeId,
                ),
                _rawLegacyDelivery(
                  deliveryId: _legacyRawSecondDeliveryId,
                  outcomeId: _legacyRawSecondOutcomeId,
                ),
              ],
            ),
          ),
          dialogueSessionLoader: (_) async => _singleLineDialogueSession(),
          beforeNarrativeAuthorityPreparation: (occurrence) async {
            if (occurrence.source.kind ==
                NarrativeEventSourceKind.outcomeReceived) {
              outcomeOccurrences.add(occurrence);
            }
          },
        );

        await _load(game);
        await _waitUntilWithoutUpdate(
          () =>
              game.debugFlowPhaseName == 'dialogue' &&
              !game.debugIsNarrativeOutcomeWorkInFlight &&
              !game.debugIsMapActivationDispatchInFlight,
        );

        final suspendedState = game.gameStateSnapshot;
        expect(
          suspendedState
              .narrativeEventProgress.deliveredNarrativeOutcomeDeliveryIds,
          {_legacyRawFirstDeliveryId},
          reason: 'The raw parent is committed before its continuation.',
        );
        expect(
          suspendedState
              .narrativeEventProgress.pendingNarrativeOutcomeDeliveries
              .map((delivery) => delivery.deliveryId),
          [_legacyRawSecondDeliveryId],
        );
        expect(outcomeOccurrences, hasLength(1));
        expect(
          suspendedState.storyFlags.activeFlags,
          isNot(contains(_legacyRawSecondCompletedFlag)),
        );

        expect(
          game.handleRuntimeInputEvent(
            const RuntimeInputEvent.press(RuntimeInputControl.primary),
          ),
          isTrue,
        );
        await _waitUntil(
          game,
          () =>
              game.gameStateSnapshot.narrativeEventProgress
                  .pendingNarrativeOutcomeDeliveries.isEmpty &&
              game.gameStateSnapshot.narrativeEventProgress
                      .deliveredNarrativeOutcomeDeliveryIds.length ==
                  2 &&
              !game.debugIsNarrativeOutcomeWorkInFlight,
        );

        final completedState = game.gameStateSnapshot;
        expect(outcomeOccurrences, hasLength(2));
        expect(
          completedState.storyFlags.activeFlags,
          containsAll(<String>[
            _legacyRawFirstCompletedFlag,
            _legacyRawSecondCompletedFlag,
          ]),
        );
        expect(
          completedState
              .narrativeEventProgress.pendingNarrativeOutcomeDeliveries,
          isEmpty,
        );
        expect(
          completedState
              .narrativeEventProgress.deliveredNarrativeOutcomeDeliveryIds,
          {_legacyRawFirstDeliveryId, _legacyRawSecondDeliveryId},
        );
      },
    );

    test(
      'keeps save and load checkpoints blocked for the complete suspended '
      'Scenario continuation lifetime',
      () async {
        final gate = NarrativeRuntimeActivityGate();
        final repository = _CheckpointCountingRepository(gate);
        final game = _game(
          project: _legacyRawDialogueBarrierProject(),
          initialState: _initialState().copyWith(
            narrativeEventProgress: NarrativeEventProgress(
              pendingNarrativeOutcomeDeliveries: <NarrativeOutcomeDelivery>[
                _rawLegacyDelivery(
                  deliveryId: _legacyRawFirstDeliveryId,
                  outcomeId: _legacyRawFirstOutcomeId,
                ),
              ],
            ),
          ),
          dialogueSessionLoader: (_) async => _singleLineDialogueSession(),
          narrativeRuntimeActivityGate: gate,
          saveRepository: repository,
        );

        await _load(game);
        await _waitUntilWithoutUpdate(
          () =>
              game.debugFlowPhaseName == 'dialogue' &&
              !game.debugIsNarrativeOutcomeWorkInFlight &&
              !game.debugIsMapActivationDispatchInFlight,
        );

        expect(gate.activity, NarrativeRuntimeActivity.sceneSuspended);
        expect(await game.saveGame(), isFalse);
        expect(await game.loadGame(), isFalse);
        expect(repository.saveCount, 0);
        expect(repository.loadCount, 0);
        expect(gate.activity, NarrativeRuntimeActivity.sceneSuspended);

        expect(
          game.handleRuntimeInputEvent(
            const RuntimeInputEvent.press(RuntimeInputControl.primary),
          ),
          isTrue,
        );
        await _waitUntil(
          game,
          () =>
              game.gameStateSnapshot.storyFlags.activeFlags.contains(
                _legacyRawFirstCompletedFlag,
              ) &&
              !game.debugIsNarrativeOutcomeWorkInFlight,
        );

        expect(gate.activity, NarrativeRuntimeActivity.idle);
        expect(await game.saveGame(), isTrue);
        expect(repository.saveCount, 1);
      },
    );

    test(
      'finishes restored raw continuation and FIFO before preparing mapEnter',
      () async {
        var mapEnterPreparationCount = 0;
        Set<String>? deliveredAtMapEnter;
        List<String>? pendingAtMapEnter;
        Set<String>? flagsAtMapEnter;
        late PlayableMapGame game;
        game = _game(
          project: _legacyRawDialogueBarrierProject(),
          initialMapActivationReason: MapActivationReason.saveRestore,
          initialState: _initialState().copyWith(
            narrativeEventProgress: NarrativeEventProgress(
              pendingNarrativeOutcomeDeliveries: <NarrativeOutcomeDelivery>[
                _rawLegacyDelivery(
                  deliveryId: _legacyRawFirstDeliveryId,
                  outcomeId: _legacyRawFirstOutcomeId,
                ),
                _rawLegacyDelivery(
                  deliveryId: _legacyRawSecondDeliveryId,
                  outcomeId: _legacyRawSecondOutcomeId,
                ),
              ],
            ),
          ),
          dialogueSessionLoader: (_) async => _singleLineDialogueSession(),
          beforeNarrativeAuthorityPreparation: (occurrence) async {
            if (occurrence.source != NarrativeEventSourceRef.mapEnter(_mapId)) {
              return;
            }
            mapEnterPreparationCount++;
            final state = game.gameStateSnapshot;
            deliveredAtMapEnter = state
                .narrativeEventProgress.deliveredNarrativeOutcomeDeliveryIds;
            pendingAtMapEnter = state
                .narrativeEventProgress.pendingNarrativeOutcomeDeliveries
                .map((delivery) => delivery.deliveryId)
                .toList(growable: false);
            flagsAtMapEnter = state.storyFlags.activeFlags;
          },
        );

        await _load(game);
        await _waitUntilWithoutUpdate(
          () =>
              game.debugFlowPhaseName == 'dialogue' &&
              !game.debugIsNarrativeOutcomeWorkInFlight,
        );

        expect(mapEnterPreparationCount, 0);
        expect(game.debugIsMapActivationDispatchInFlight, isTrue);
        expect(
          game.gameStateSnapshot.narrativeEventProgress
              .deliveredNarrativeOutcomeDeliveryIds,
          {_legacyRawFirstDeliveryId},
        );
        expect(
          game.gameStateSnapshot.narrativeEventProgress
              .pendingNarrativeOutcomeDeliveries
              .map((delivery) => delivery.deliveryId),
          [_legacyRawSecondDeliveryId],
        );

        expect(
          game.handleRuntimeInputEvent(
            const RuntimeInputEvent.press(RuntimeInputControl.primary),
          ),
          isTrue,
        );
        await _waitUntil(
          game,
          () =>
              mapEnterPreparationCount == 1 &&
              !game.debugIsMapActivationDispatchInFlight,
        );

        expect(deliveredAtMapEnter, {
          _legacyRawFirstDeliveryId,
          _legacyRawSecondDeliveryId,
        });
        expect(pendingAtMapEnter, isEmpty);
        expect(
            flagsAtMapEnter,
            containsAll(<String>[
              _legacyRawFirstCompletedFlag,
              _legacyRawSecondCompletedFlag,
            ]));
      },
    );

    test(
      'keeps an emit-before-dialogue producer head pending and reuses its '
      'root correlation after the continuation',
      () async {
        final outcomeOccurrences = <NarrativeEventOccurrence>[];
        final game = _game(
          project: _legacySuspendedProducerProject(),
          dialogueSessionLoader: (_) async => _singleLineDialogueSession(),
          beforeNarrativeAuthorityPreparation: (occurrence) async {
            if (occurrence.source.kind ==
                NarrativeEventSourceKind.outcomeReceived) {
              outcomeOccurrences.add(occurrence);
            }
          },
        );

        await _load(game);
        await _waitUntilWithoutUpdate(
          () =>
              game.debugFlowPhaseName == 'dialogue' &&
              !game.debugIsNarrativeOutcomeWorkInFlight &&
              !game.debugIsMapActivationDispatchInFlight,
        );

        final suspendedState = game.gameStateSnapshot;
        expect(
          suspendedState
              .narrativeEventProgress.deliveredNarrativeOutcomeDeliveryIds,
          isEmpty,
        );
        expect(
          suspendedState
              .narrativeEventProgress.pendingNarrativeOutcomeDeliveries
              .map((delivery) => delivery.outcome.outcomeId),
          ['producer.seed'],
        );
        expect(outcomeOccurrences, isEmpty);

        expect(
          game.handleRuntimeInputEvent(
            const RuntimeInputEvent.press(RuntimeInputControl.primary),
          ),
          isTrue,
        );
        await _waitUntil(
          game,
          () =>
              _factValue(game, _legacyProducerSeedFact) == true &&
              _factValue(game, _legacyProducerAfterFact) == true,
        );

        expect(outcomeOccurrences, hasLength(2));
        expect(
          outcomeOccurrences.map((occurrence) => occurrence.rootCorrelationId),
          everyElement(outcomeOccurrences.first.rootCorrelationId),
        );
        expect(
          outcomeOccurrences.map((occurrence) => occurrence.depth),
          <int?>[0, 0],
        );
      },
    );

    test(
      'carries the raw outcome owner through a Scenario runScript warp before '
      'resuming and releasing the continuation lease',
      () async {
        final gate = NarrativeRuntimeActivityGate();
        final project = _legacyScriptWarpProject();
        final game = _game(
          project: project,
          initialState: _initialState().copyWith(
            narrativeEventProgress: NarrativeEventProgress(
              pendingNarrativeOutcomeDeliveries: <NarrativeOutcomeDelivery>[
                _rawLegacyDelivery(
                  deliveryId: _legacyScriptWarpDeliveryId,
                  outcomeId: _legacyScriptWarpOutcomeId,
                ),
                _rawLegacyDelivery(
                  deliveryId: _legacyRawSecondDeliveryId,
                  outcomeId: _legacyRawSecondOutcomeId,
                ),
              ],
            ),
          ),
          narrativeRuntimeActivityGate: gate,
          initialMapActivationReason: MapActivationReason.saveRestore,
          runtimeMapBundleLoader: ({
            required projectFilePath,
            required mapId,
          }) async {
            expect(mapId, _legacyScriptWarpTargetMapId);
            return RuntimeMapBundle(
              manifest: project,
              map: _scriptWarpTargetMap(),
              projectRootDirectory: '/tmp/qualified_outcome_v2',
              tilesetAbsolutePathsById: const <String, String>{},
            );
          },
        );

        await _load(game);
        await _waitUntilWithoutUpdate(
          () =>
              gate.activity == NarrativeRuntimeActivity.sceneSuspended &&
              game.debugHasPendingMapTransition &&
              !game.debugIsNarrativeOutcomeWorkInFlight &&
              game.debugIsMapActivationDispatchInFlight,
        );

        final suspendedProgress = game.gameStateSnapshot.narrativeEventProgress;
        expect(
          suspendedProgress.deliveredNarrativeOutcomeDeliveryIds,
          {_legacyScriptWarpDeliveryId},
        );
        expect(
          suspendedProgress.pendingNarrativeOutcomeDeliveries
              .map((delivery) => delivery.deliveryId),
          [_legacyRawSecondDeliveryId],
        );
        expect(
          game.gameStateSnapshot.storyFlags.activeFlags,
          isNot(contains(_legacyScriptWarpCompletedFlag)),
        );

        await _waitUntil(
          game,
          () =>
              game.debugLastCompletedMapActivation?.mapId ==
                  _legacyScriptWarpTargetMapId &&
              game.gameStateSnapshot.storyFlags.activeFlags
                  .contains(_legacyScriptWarpCompletedFlag) &&
              game.gameStateSnapshot.storyFlags.activeFlags
                  .contains(_legacyRawSecondCompletedFlag) &&
              gate.activity == NarrativeRuntimeActivity.idle,
          maxTicks: 600,
        );

        expect(game.debugPlayerGridPosition, const GridPos(x: 1, y: 1));
        expect(
          game.gameStateSnapshot.narrativeEventProgress
              .pendingNarrativeOutcomeDeliveries,
          isEmpty,
        );
        expect(
          game.gameStateSnapshot.narrativeEventProgress
              .deliveredNarrativeOutcomeDeliveryIds,
          {_legacyScriptWarpDeliveryId, _legacyRawSecondDeliveryId},
        );
        expect(gate.activity, NarrativeRuntimeActivity.idle);
      },
    );

    test(
      'releases the continuation lease and drains the FIFO after a Scenario '
      'dialogue load failure',
      () async {
        final gate = NarrativeRuntimeActivityGate();
        final game = _game(
          project: _legacyRawDialogueBarrierProject(),
          initialState: _initialState().copyWith(
            narrativeEventProgress: NarrativeEventProgress(
              pendingNarrativeOutcomeDeliveries: <NarrativeOutcomeDelivery>[
                _rawLegacyDelivery(
                  deliveryId: _legacyRawFirstDeliveryId,
                  outcomeId: _legacyRawFirstOutcomeId,
                ),
                _rawLegacyDelivery(
                  deliveryId: _legacyRawSecondDeliveryId,
                  outcomeId: _legacyRawSecondOutcomeId,
                ),
              ],
            ),
          ),
          dialogueSessionLoader: (_) async => null,
          narrativeRuntimeActivityGate: gate,
        );

        await _load(game);
        await _waitUntil(
          game,
          () =>
              game.gameStateSnapshot.narrativeEventProgress
                  .pendingNarrativeOutcomeDeliveries.isEmpty &&
              !game.debugIsNarrativeOutcomeWorkInFlight &&
              !game.debugIsMapActivationDispatchInFlight,
        );

        final state = game.gameStateSnapshot;
        expect(gate.activity, NarrativeRuntimeActivity.idle);
        expect(
          state.narrativeEventProgress.deliveredNarrativeOutcomeDeliveryIds,
          {_legacyRawFirstDeliveryId, _legacyRawSecondDeliveryId},
        );
        expect(
          state.storyFlags.activeFlags,
          isNot(contains(_legacyRawFirstCompletedFlag)),
        );
        expect(
          state.storyFlags.activeFlags,
          contains(_legacyRawSecondCompletedFlag),
        );
      },
    );

    test(
      'releases Scenario dialogue ownership after a synchronous loader '
      'exception and keeps checkpoints available',
      () async {
        final gate = NarrativeRuntimeActivityGate();
        final repository = _CheckpointCountingRepository(gate);
        final game = _game(
          project: _legacyRawDialogueBarrierProject(),
          initialState: _initialState().copyWith(
            narrativeEventProgress: NarrativeEventProgress(
              pendingNarrativeOutcomeDeliveries: <NarrativeOutcomeDelivery>[
                _rawLegacyDelivery(
                  deliveryId: _legacyRawFirstDeliveryId,
                  outcomeId: _legacyRawFirstOutcomeId,
                ),
                _rawLegacyDelivery(
                  deliveryId: _legacyRawSecondDeliveryId,
                  outcomeId: _legacyRawSecondOutcomeId,
                ),
              ],
            ),
          ),
          dialogueSessionLoader: (_) {
            throw StateError('synchronous Scenario dialogue load failed');
          },
          narrativeRuntimeActivityGate: gate,
          saveRepository: repository,
        );

        await _load(game);
        await _waitUntil(
          game,
          () =>
              game.gameStateSnapshot.narrativeEventProgress
                  .pendingNarrativeOutcomeDeliveries.isEmpty &&
              !game.debugIsNarrativeOutcomeWorkInFlight &&
              !game.debugIsMapActivationDispatchInFlight,
        );

        final state = game.gameStateSnapshot;
        expect(gate.activity, NarrativeRuntimeActivity.idle);
        expect(game.debugHasPendingDialogueLoad, isFalse);
        expect(game.debugFlowPhaseName, 'overworld');
        expect(game.debugIsGameplayInputLocked, isFalse);
        expect(
          state.narrativeEventProgress.deliveredNarrativeOutcomeDeliveryIds,
          {_legacyRawFirstDeliveryId, _legacyRawSecondDeliveryId},
        );
        expect(
          state.storyFlags.activeFlags,
          isNot(contains(_legacyRawFirstCompletedFlag)),
        );
        expect(
          state.storyFlags.activeFlags,
          contains(_legacyRawSecondCompletedFlag),
        );
        expect(await game.saveGame(), isTrue);
        expect(await game.loadGame(), isTrue);
        expect(repository.saveCount, 1);
        expect(repository.loadCount, 1);
      },
    );

    test(
      'keeps a Scenario script warp owner when the same step also triggers a '
      'different physical warp',
      () async {
        final gate = NarrativeRuntimeActivityGate();
        final project = _legacyWarpConflictProject();
        final game = _game(
          project: project,
          map: _warpConflictMap(),
          narrativeRuntimeActivityGate: gate,
          runtimeMapBundleLoader: ({
            required projectFilePath,
            required mapId,
          }) async {
            final targetMap = mapId == _legacyScriptWarpTargetMapId
                ? _scriptWarpTargetMap()
                : _physicalWarpTargetMap();
            return RuntimeMapBundle(
              manifest: project,
              map: targetMap,
              projectRootDirectory: '/tmp/qualified_outcome_v2',
              tilesetAbsolutePathsById: const <String, String>{},
            );
          },
        );

        await _load(game);
        await _waitUntil(
          game,
          () => !game.debugIsMapActivationDispatchInFlight,
        );
        expect(
          game.handleRuntimeInputEvent(
            const RuntimeInputEvent.press(RuntimeInputControl.down),
          ),
          isTrue,
        );
        game.update(0.016);
        expect(
          game.handleRuntimeInputEvent(
            const RuntimeInputEvent.release(RuntimeInputControl.down),
          ),
          isTrue,
        );

        await _waitUntil(
          game,
          () =>
              game.gameStateSnapshot.currentMapId ==
                  _legacyScriptWarpTargetMapId &&
              game.gameStateSnapshot.storyFlags.activeFlags
                  .contains(_legacyScriptWarpCompletedFlag) &&
              gate.activity == NarrativeRuntimeActivity.idle,
          maxTicks: 900,
        );

        expect(
          game.gameStateSnapshot.currentMapId,
          isNot(_legacyPhysicalWarpTargetMapId),
        );
      },
    );

    test(
      'does not adopt a pre-existing transition into an unrelated raw outcome '
      'continuation',
      () async {
        final gate = NarrativeRuntimeActivityGate();
        final project = _legacyTransitionOwnershipProject();
        final game = _game(
          project: project,
          map: _transitionOwnershipMap(),
          narrativeRuntimeActivityGate: gate,
          runtimeMapBundleLoader: ({
            required projectFilePath,
            required mapId,
          }) async {
            expect(mapId, _legacyTransitionTargetMapId);
            return RuntimeMapBundle(
              manifest: project,
              map: _transitionTargetMap(),
              projectRootDirectory: '/tmp/qualified_outcome_v2',
              tilesetAbsolutePathsById: const <String, String>{},
            );
          },
        );

        await _load(game);
        await _waitUntil(
          game,
          () => !game.debugIsMapActivationDispatchInFlight,
        );
        expect(
          game.handleRuntimeInputEvent(
            const RuntimeInputEvent.press(RuntimeInputControl.down),
          ),
          isTrue,
        );
        game.update(0.016);
        expect(
          game.handleRuntimeInputEvent(
            const RuntimeInputEvent.release(RuntimeInputControl.down),
          ),
          isTrue,
        );
        await _waitUntilWithoutUpdate(
          () =>
              game.gameStateSnapshot.storyFlags.activeFlags
                  .contains(_legacyRawSecondCompletedFlag) &&
              !game.debugIsNarrativeOutcomeWorkInFlight,
        );

        expect(game.debugHasPendingScenarioTransitionMap, isTrue);
        expect(
          game.debugPendingScenarioTransitionTargetMapId,
          _legacyTransitionTargetMapId,
        );
        expect(gate.activity, NarrativeRuntimeActivity.idle);

        await _waitUntil(
          game,
          () =>
              game.gameStateSnapshot.currentMapId ==
              _legacyTransitionTargetMapId,
          maxTicks: 900,
        );
      },
    );

    for (final throwsFromCommand in <bool>[false, true]) {
      test(
        'terminalizes a Scenario runScript ${throwsFromCommand ? 'exception' : 'error result'} '
        'after dialogue without orphaning its continuation',
        () async {
          final gate = NarrativeRuntimeActivityGate();
          final game = _game(
            project: _legacyScriptFailureProject(
              throwsFromCommand: throwsFromCommand,
            ),
            initialState: _initialState().copyWith(
              narrativeEventProgress: NarrativeEventProgress(
                pendingNarrativeOutcomeDeliveries: <NarrativeOutcomeDelivery>[
                  _rawLegacyDelivery(
                    deliveryId: _legacyScriptFailureDeliveryId,
                    outcomeId: _legacyScriptFailureOutcomeId,
                  ),
                  _rawLegacyDelivery(
                    deliveryId: _legacyRawSecondDeliveryId,
                    outcomeId: _legacyRawSecondOutcomeId,
                  ),
                ],
              ),
            ),
            dialogueSessionLoader: (_) async => _singleLineDialogueSession(),
            narrativeRuntimeActivityGate: gate,
          );

          await _load(game);
          await _waitUntilWithoutUpdate(
            () =>
                game.debugFlowPhaseName == 'dialogue' &&
                !game.debugIsNarrativeOutcomeWorkInFlight,
          );

          expect(
            () => game.handleRuntimeInputEvent(
              const RuntimeInputEvent.press(RuntimeInputControl.primary),
            ),
            returnsNormally,
          );
          await _waitUntil(
            game,
            () =>
                game.gameStateSnapshot.narrativeEventProgress
                    .pendingNarrativeOutcomeDeliveries.isEmpty &&
                gate.activity == NarrativeRuntimeActivity.idle,
          );

          expect(
            game.gameStateSnapshot.storyFlags.activeFlags,
            isNot(contains(_legacyScriptFailureCompletedFlag)),
          );
          expect(
            game.gameStateSnapshot.storyFlags.activeFlags,
            contains(_legacyRawSecondCompletedFlag),
          );
          expect(game.debugNotificationText, 'Script interrompu');
        },
      );
    }

    for (final throwsFromCommand in <bool>[false, true]) {
      test(
        'terminalizes an initial Scenario runScript '
        '${throwsFromCommand ? 'exception' : 'error result'} before barrier '
        'registration without orphaning the FIFO',
        () async {
          final gate = NarrativeRuntimeActivityGate();
          final repository = _CheckpointCountingRepository(gate);
          final game = _game(
            project: _legacyImmediateScriptFailureProject(
              throwsFromCommand: throwsFromCommand,
            ),
            initialState: _initialState().copyWith(
              narrativeEventProgress: NarrativeEventProgress(
                pendingNarrativeOutcomeDeliveries: <NarrativeOutcomeDelivery>[
                  _rawLegacyDelivery(
                    deliveryId: _legacyScriptFailureDeliveryId,
                    outcomeId: _legacyScriptFailureOutcomeId,
                  ),
                  _rawLegacyDelivery(
                    deliveryId: _legacyRawSecondDeliveryId,
                    outcomeId: _legacyRawSecondOutcomeId,
                  ),
                ],
              ),
            ),
            narrativeRuntimeActivityGate: gate,
            saveRepository: repository,
          );

          await _load(game);
          await _waitUntil(
            game,
            () =>
                game.gameStateSnapshot.narrativeEventProgress
                    .pendingNarrativeOutcomeDeliveries.isEmpty &&
                gate.activity == NarrativeRuntimeActivity.idle,
          );

          expect(
            game.gameStateSnapshot.storyFlags.activeFlags,
            isNot(contains(_legacyScriptFailureCompletedFlag)),
          );
          expect(
            game.gameStateSnapshot.storyFlags.activeFlags,
            contains(_legacyRawSecondCompletedFlag),
          );
          expect(game.debugNotificationText, 'Script interrompu');
          expect(await game.saveGame(), isTrue);
          expect(await game.loadGame(), isTrue);
          expect(repository.saveCount, 1);
          expect(repository.loadCount, 1);
        },
      );
    }

    for (final scriptBehavior in <String>['end', 'error', 'exception']) {
      test(
        'transfers a dialogue continuation owner before a synchronous '
        'runScript $scriptBehavior completion',
        () async {
          final gate = NarrativeRuntimeActivityGate();
          final game = _game(
            project: _legacyDialogueThenScriptProject(
              scriptBehavior: scriptBehavior,
            ),
            initialState: _initialState().copyWith(
              narrativeEventProgress: NarrativeEventProgress(
                pendingNarrativeOutcomeDeliveries: <NarrativeOutcomeDelivery>[
                  _rawLegacyDelivery(
                    deliveryId: _legacyScriptFailureDeliveryId,
                    outcomeId: _legacyScriptFailureOutcomeId,
                  ),
                  _rawLegacyDelivery(
                    deliveryId: _legacyRawSecondDeliveryId,
                    outcomeId: _legacyRawSecondOutcomeId,
                  ),
                ],
              ),
            ),
            dialogueSessionLoader: (_) async => _singleLineDialogueSession(),
            narrativeRuntimeActivityGate: gate,
          );

          await _load(game);
          await _waitUntilWithoutUpdate(
            () =>
                game.debugFlowPhaseName == 'dialogue' &&
                !game.debugIsNarrativeOutcomeWorkInFlight,
          );

          expect(
            game.handleRuntimeInputEvent(
              const RuntimeInputEvent.press(RuntimeInputControl.primary),
            ),
            isTrue,
          );
          await _waitUntil(
            game,
            () =>
                game.gameStateSnapshot.narrativeEventProgress
                    .pendingNarrativeOutcomeDeliveries.isEmpty &&
                gate.activity == NarrativeRuntimeActivity.idle,
          );

          expect(
            game.gameStateSnapshot.storyFlags.activeFlags.contains(
              _legacyChainedEffectCompletedFlag,
            ),
            scriptBehavior == 'end',
          );
          expect(
            game.gameStateSnapshot.storyFlags.activeFlags,
            contains(_legacyRawSecondCompletedFlag),
          );
        },
      );
    }

    for (final loaderThrows in <bool>[false, true]) {
      test(
        'transfers a dialogue continuation owner before the next dialogue '
        'loader ${loaderThrows ? 'throws' : 'returns null'}',
        () async {
          final gate = NarrativeRuntimeActivityGate();
          var loadCount = 0;
          final game = _game(
            project: _legacyDialogueThenDialogueProject(),
            initialState: _initialState().copyWith(
              narrativeEventProgress: NarrativeEventProgress(
                pendingNarrativeOutcomeDeliveries: <NarrativeOutcomeDelivery>[
                  _rawLegacyDelivery(
                    deliveryId: _legacyScriptFailureDeliveryId,
                    outcomeId: _legacyScriptFailureOutcomeId,
                  ),
                  _rawLegacyDelivery(
                    deliveryId: _legacyRawSecondDeliveryId,
                    outcomeId: _legacyRawSecondOutcomeId,
                  ),
                ],
              ),
            ),
            dialogueSessionLoader: (_) {
              loadCount++;
              if (loadCount == 1) {
                return Future<DialogueSession?>.value(
                  _singleLineDialogueSession(),
                );
              }
              if (loaderThrows) {
                return Future<DialogueSession?>.error(
                  StateError('second dialogue load failed'),
                );
              }
              return Future<DialogueSession?>.value(null);
            },
            narrativeRuntimeActivityGate: gate,
          );

          await _load(game);
          await _waitUntilWithoutUpdate(
            () =>
                game.debugFlowPhaseName == 'dialogue' &&
                !game.debugIsNarrativeOutcomeWorkInFlight,
          );

          expect(
            game.handleRuntimeInputEvent(
              const RuntimeInputEvent.press(RuntimeInputControl.primary),
            ),
            isTrue,
          );
          await _waitUntil(
            game,
            () =>
                game.gameStateSnapshot.narrativeEventProgress
                    .pendingNarrativeOutcomeDeliveries.isEmpty &&
                gate.activity == NarrativeRuntimeActivity.idle,
          );

          expect(loadCount, 2);
          expect(
            game.gameStateSnapshot.storyFlags.activeFlags,
            isNot(contains(_legacyChainedEffectCompletedFlag)),
          );
          expect(
            game.gameStateSnapshot.storyFlags.activeFlags,
            contains(_legacyRawSecondCompletedFlag),
          );
          expect(
            game.debugNotificationText,
            startsWith('Dialogue introuvable'),
          );
        },
      );
    }

    test(
      'transfers a dialogue continuation owner before the next dialogue '
      'loader throws synchronously',
      () async {
        final gate = NarrativeRuntimeActivityGate();
        final repository = _CheckpointCountingRepository(gate);
        var loadCount = 0;
        final game = _game(
          project: _legacyDialogueThenDialogueProject(),
          initialState: _initialState().copyWith(
            narrativeEventProgress: NarrativeEventProgress(
              pendingNarrativeOutcomeDeliveries: <NarrativeOutcomeDelivery>[
                _rawLegacyDelivery(
                  deliveryId: _legacyScriptFailureDeliveryId,
                  outcomeId: _legacyScriptFailureOutcomeId,
                ),
                _rawLegacyDelivery(
                  deliveryId: _legacyRawSecondDeliveryId,
                  outcomeId: _legacyRawSecondOutcomeId,
                ),
              ],
            ),
          ),
          dialogueSessionLoader: (_) {
            loadCount++;
            if (loadCount == 1) {
              return Future<DialogueSession?>.value(
                _singleLineDialogueSession(),
              );
            }
            throw StateError('second dialogue load failed synchronously');
          },
          narrativeRuntimeActivityGate: gate,
          saveRepository: repository,
        );

        await _load(game);
        await _waitUntilWithoutUpdate(
          () =>
              game.debugFlowPhaseName == 'dialogue' &&
              !game.debugIsNarrativeOutcomeWorkInFlight,
        );

        expect(
          game.handleRuntimeInputEvent(
            const RuntimeInputEvent.press(RuntimeInputControl.primary),
          ),
          isTrue,
        );
        await _waitUntil(
          game,
          () =>
              game.gameStateSnapshot.narrativeEventProgress
                  .pendingNarrativeOutcomeDeliveries.isEmpty &&
              gate.activity == NarrativeRuntimeActivity.idle,
        );

        expect(loadCount, 2);
        expect(game.debugHasPendingDialogueLoad, isFalse);
        expect(game.debugFlowPhaseName, 'overworld');
        expect(game.debugIsGameplayInputLocked, isFalse);
        expect(
          game.gameStateSnapshot.storyFlags.activeFlags,
          isNot(contains(_legacyChainedEffectCompletedFlag)),
        );
        expect(
          game.gameStateSnapshot.storyFlags.activeFlags,
          contains(_legacyRawSecondCompletedFlag),
        );
        expect(
          game.debugNotificationText,
          startsWith('Dialogue introuvable'),
        );
        expect(await game.saveGame(), isTrue);
        expect(await game.loadGame(), isTrue);
        expect(repository.saveCount, 1);
        expect(repository.loadCount, 1);
      },
    );

    test(
      'closes a runScript continuation without adopting an unrelated pending '
      'Battle handoff',
      () async {
        final gate = NarrativeRuntimeActivityGate();
        final normalBattle = _trainerContext().request;
        final game = _game(
          project: _legacyScriptNoWarpProject(),
          initialState: _initialState().copyWith(
            narrativeEventProgress: NarrativeEventProgress(
              pendingNarrativeOutcomeDeliveries: <NarrativeOutcomeDelivery>[
                _rawLegacyDelivery(
                  deliveryId: _legacyScriptFailureDeliveryId,
                  outcomeId: _legacyScriptFailureOutcomeId,
                ),
              ],
            ),
          ),
          narrativeRuntimeActivityGate: gate,
        );
        expect(
          game.debugTryEnqueueBattleRequestForTest(normalBattle),
          isTrue,
        );

        await _load(game);
        await _waitUntilWithoutUpdate(
          () =>
              game.gameStateSnapshot.storyFlags.activeFlags
                  .contains(_legacyScriptFailureCompletedFlag) &&
              gate.activity == NarrativeRuntimeActivity.idle,
        );

        expect(game.debugPendingBattleRequest, same(normalBattle));
        expect(game.debugHasPendingScenarioBattle, isFalse);
      },
    );

    test(
      'advances and releases a wait-for-completion move continuation when the '
      'NPC enters its target warp',
      () async {
        final gate = NarrativeRuntimeActivityGate();
        final game = _game(
          project: _legacyMoveWarpProject(),
          map: _moveWarpMap(),
          initialState: _initialState().copyWith(
            playerPosition: const GridPos(x: 0, y: 0),
          ),
          narrativeRuntimeActivityGate: gate,
        );

        await _load(game);
        await _waitUntil(
          game,
          () =>
              game.gameStateSnapshot.storyFlags.activeFlags
                  .contains(_legacyMoveWarpCompletedFlag) &&
              gate.activity == NarrativeRuntimeActivity.idle,
          maxTicks: 600,
        );

        expect(game.debugNpcGridPosition('moving_npc'), isNull);
        expect(gate.activity, NarrativeRuntimeActivity.idle);
      },
    );

    test(
      'keeps a restored raw follow leader warp owned until the exact player '
      'handoff completes before continuation and FIFO',
      () async {
        final gate = NarrativeRuntimeActivityGate();
        final repository = _CheckpointCountingRepository(gate);
        final project = _legacyFollowMoveWarpProject();
        final outcomeOrder = <String>[];
        final outcomeCorrelations = <String?>[];
        final outcomeDepths = <int?>[];
        var targetMapEnterCount = 0;
        String? mapAtTargetMapEnter;
        GridPos? positionAtTargetMapEnter;
        Set<String>? flagsAtTargetMapEnter;
        List<String>? pendingAtTargetMapEnter;
        NarrativeRuntimeActivity? activityAtTargetMapEnter;
        late PlayableMapGame game;
        game = _game(
          project: project,
          map: _followMoveWarpSourceMap(),
          initialMapActivationReason: MapActivationReason.saveRestore,
          initialState: _initialState().copyWith(
            playerPosition: const GridPos(x: 0, y: 1),
            narrativeEventProgress: NarrativeEventProgress(
              pendingNarrativeOutcomeDeliveries: <NarrativeOutcomeDelivery>[
                _rawLegacyDelivery(
                  deliveryId: _legacyFollowMoveWarpDeliveryId,
                  outcomeId: _legacyFollowMoveWarpOutcomeId,
                ),
                _rawLegacyDelivery(
                  deliveryId: _legacyRawSecondDeliveryId,
                  outcomeId: _legacyRawSecondOutcomeId,
                ),
              ],
            ),
          ),
          narrativeRuntimeActivityGate: gate,
          saveRepository: repository,
          runtimeMapBundleLoader: ({
            required projectFilePath,
            required mapId,
          }) async {
            expect(mapId, _legacyFollowMoveWarpTargetMapId);
            return RuntimeMapBundle(
              manifest: project,
              map: _followMoveWarpTargetMap(),
              projectRootDirectory: '/tmp/qualified_outcome_v2',
              tilesetAbsolutePathsById: const <String, String>{},
            );
          },
          beforeNarrativeAuthorityPreparation: (occurrence) async {
            if (occurrence.source.kind ==
                NarrativeEventSourceKind.outcomeReceived) {
              occurrence.source.when<void>(
                entityInteract: (_, __) {},
                triggerEnter: (_, __) {},
                mapEnter: (_) {},
                outcomeReceived: (outcome) {
                  outcomeOrder.add(outcome.outcomeId);
                  outcomeCorrelations.add(occurrence.rootCorrelationId);
                  outcomeDepths.add(occurrence.depth);
                },
              );
            }
            if (occurrence.source !=
                NarrativeEventSourceRef.mapEnter(
                  _legacyFollowMoveWarpTargetMapId,
                )) {
              return;
            }
            targetMapEnterCount++;
            final state = game.gameStateSnapshot;
            mapAtTargetMapEnter = state.currentMapId;
            positionAtTargetMapEnter = state.playerPosition;
            flagsAtTargetMapEnter = state.storyFlags.activeFlags;
            pendingAtTargetMapEnter = state
                .narrativeEventProgress.pendingNarrativeOutcomeDeliveries
                .map((delivery) => delivery.deliveryId)
                .toList(growable: false);
            activityAtTargetMapEnter = gate.activity;
          },
        );

        await _load(game);
        await _waitUntilWithoutUpdate(
          () =>
              gate.activity == NarrativeRuntimeActivity.sceneSuspended &&
              game.debugIsMapActivationDispatchInFlight,
        );

        expect(await game.loadGame(), isFalse);
        expect(repository.loadCount, 0);
        expect(
          game.gameStateSnapshot.storyFlags.activeFlags,
          isNot(contains(_legacyFollowMoveWarpCompletedFlag)),
        );

        await _waitUntil(
          game,
          () =>
              targetMapEnterCount == 1 &&
              game.gameStateSnapshot.storyFlags.activeFlags
                  .contains(_legacyFollowMoveWarpCompletedFlag) &&
              game.gameStateSnapshot.storyFlags.activeFlags
                  .contains(_legacyRawSecondCompletedFlag) &&
              gate.activity == NarrativeRuntimeActivity.idle,
          maxTicks: 900,
        );

        expect(mapAtTargetMapEnter, _legacyFollowMoveWarpTargetMapId);
        expect(positionAtTargetMapEnter, const GridPos(x: 2, y: 1));
        expect(
          flagsAtTargetMapEnter,
          isNot(contains(_legacyFollowMoveWarpCompletedFlag)),
          reason: 'The Scenario continuation must wait for the owned warp.',
        );
        expect(
          flagsAtTargetMapEnter,
          isNot(contains(_legacyRawSecondCompletedFlag)),
          reason: 'The next FIFO head must not overtake the owner.',
        );
        expect(
          pendingAtTargetMapEnter,
          [_legacyRawSecondDeliveryId],
        );
        expect(
          activityAtTargetMapEnter,
          NarrativeRuntimeActivity.dispatching,
          reason: 'The target mapEnter dispatch temporarily sits above the '
              'still-open Scenario suspension lease.',
        );
        expect(
          game.gameStateSnapshot.narrativeEventProgress
              .deliveredNarrativeOutcomeDeliveryIds,
          containsAll(<String>{
            _legacyFollowMoveWarpDeliveryId,
            _legacyRawSecondDeliveryId,
          }),
        );
        expect(
          game.gameStateSnapshot.narrativeEventProgress
              .deliveredNarrativeOutcomeDeliveryIds,
          hasLength(3),
        );
        expect(
          outcomeOrder,
          [
            _legacyFollowMoveWarpOutcomeId,
            _legacyRawSecondOutcomeId,
            _legacyFollowMoveWarpChildOutcomeId,
          ],
        );
        expect(
          outcomeCorrelations,
          everyElement(_legacyRawRootCorrelationId),
        );
        expect(outcomeDepths, <int?>[0, 0, 1]);
        expect(
          game.gameStateSnapshot.currentMapId,
          _legacyFollowMoveWarpTargetMapId,
        );
        expect(game.debugPlayerGridPosition, const GridPos(x: 2, y: 1));
        expect(game.debugHasPendingLeaderWarpHandoff, isFalse);
        expect(game.debugHasActiveScenarioFollow, isFalse);
      },
    );

    test(
      'preserves a wait-for-completion warp owner when an unreachable '
      'replacement is rejected',
      () async {
        final gate = NarrativeRuntimeActivityGate();
        final game = _game(
          project: _legacyMoveWarpProject(),
          map: _moveWarpMap(),
          initialState: _initialState().copyWith(
            playerPosition: const GridPos(x: 0, y: 0),
          ),
          narrativeRuntimeActivityGate: gate,
        );

        await _load(game);
        await _waitUntilWithoutUpdate(
          () =>
              gate.activity == NarrativeRuntimeActivity.sceneSuspended &&
              !game.debugIsMapActivationDispatchInFlight,
        );

        game.update(0.016);
        final forcedFailure = game.startScriptedNpcMove(
          entityId: 'moving_npc',
          destination: const GridPos(x: 99, y: 99),
        );
        expect(
          forcedFailure.state,
          ScriptedEntityMovementState.failed,
        );

        await _waitUntil(
          game,
          () =>
              gate.activity == NarrativeRuntimeActivity.idle &&
              game.gameStateSnapshot.storyFlags.activeFlags
                  .contains(_legacyMoveWarpCompletedFlag),
          maxTicks: 600,
        );

        expect(
          game.gameStateSnapshot.storyFlags.activeFlags,
          contains(_legacyMoveWarpCompletedFlag),
        );
        expect(game.debugNpcGridPosition('moving_npc'), isNull);
        expect(gate.activity, NarrativeRuntimeActivity.idle);
      },
    );

    test(
      'current-cell replacement cancels the previous warp owner and stale '
      'movement task',
      () async {
        final gate = NarrativeRuntimeActivityGate();
        final game = _game(
          project: _legacyMoveWarpProject(),
          map: _moveWarpMap(),
          initialState: _initialState().copyWith(
            playerPosition: const GridPos(x: 0, y: 0),
          ),
          narrativeRuntimeActivityGate: gate,
        );

        await _load(game);
        await _waitUntilWithoutUpdate(
          () =>
              gate.activity == NarrativeRuntimeActivity.sceneSuspended &&
              !game.debugIsMapActivationDispatchInFlight,
        );

        final replacement = game.startScriptedNpcMove(
          entityId: 'moving_npc',
          destination: const GridPos(x: 1, y: 1),
        );
        expect(
          replacement.state,
          ScriptedEntityMovementState.completed,
        );

        await _waitUntil(
          game,
          () => gate.activity == NarrativeRuntimeActivity.idle,
        );
        for (var i = 0; i < 10; i++) {
          game.update(0.016);
          await Future<void>.delayed(Duration.zero);
        }

        expect(
          game.gameStateSnapshot.storyFlags.activeFlags,
          isNot(contains(_legacyMoveWarpCompletedFlag)),
        );
        expect(
          game.debugNpcGridPosition('moving_npc'),
          const GridPos(x: 1, y: 1),
        );
        expect(gate.activity, NarrativeRuntimeActivity.idle);
      },
    );

    test(
      'cancels the first wait owner when a second move replaces the same entity',
      () async {
        final gate = NarrativeRuntimeActivityGate();
        final game = _game(
          project: _legacyMoveReplacementProject(),
          map: _moveReplacementMap(),
          initialState: _initialState().copyWith(
            playerPosition: const GridPos(x: 0, y: 0),
          ),
          narrativeRuntimeActivityGate: gate,
        );

        await _load(game);
        await _waitUntil(
          game,
          () => !game.debugIsMapActivationDispatchInFlight,
        );
        expect(
          game.handleRuntimeInputEvent(
            const RuntimeInputEvent.press(RuntimeInputControl.down),
          ),
          isTrue,
        );
        game.update(0.016);
        expect(
          game.handleRuntimeInputEvent(
            const RuntimeInputEvent.release(RuntimeInputControl.down),
          ),
          isTrue,
        );

        await _waitUntil(
          game,
          () =>
              game.gameStateSnapshot.storyFlags.activeFlags
                  .contains(_legacyMoveReplacementSecondFlag) &&
              gate.activity == NarrativeRuntimeActivity.idle,
          maxTicks: 900,
        );

        expect(
          game.gameStateSnapshot.storyFlags.activeFlags,
          isNot(contains(_legacyMoveReplacementFirstFlag)),
        );
        expect(game.debugNpcGridPosition('moving_npc'), isNull);
      },
    );

    test(
      'cancels a player move-to-warp owner when its target map fails to load',
      () async {
        final gate = NarrativeRuntimeActivityGate();
        final game = _game(
          project: _legacyPlayerMoveWarpProject(),
          map: _playerMoveWarpMap(),
          initialState: _initialState().copyWith(
            playerPosition: const GridPos(x: 0, y: 0),
          ),
          narrativeRuntimeActivityGate: gate,
          runtimeMapBundleLoader: ({
            required projectFilePath,
            required mapId,
          }) async {
            throw StateError('target loader failed for $mapId');
          },
        );

        await _load(game);
        await _waitUntilWithoutUpdate(
          () =>
              gate.activity == NarrativeRuntimeActivity.sceneSuspended &&
              !game.debugIsMapActivationDispatchInFlight,
        );
        await _waitUntil(
          game,
          () => gate.activity == NarrativeRuntimeActivity.idle,
          maxTicks: 900,
        );

        expect(game.gameStateSnapshot.currentMapId, _mapId);
        expect(
          game.gameStateSnapshot.storyFlags.activeFlags,
          isNot(contains(_legacyPlayerWarpCompletedFlag)),
        );
        expect(game.debugHasPendingMapTransition, isFalse);
      },
    );

    test(
      'does not orphan a continuation lease when an outcome-caused Battle '
      'handoff is invalid',
      () async {
        final gate = NarrativeRuntimeActivityGate();
        final game = _game(
          project: _legacyInvalidBattleProject(),
          initialState: _initialState().copyWith(
            narrativeEventProgress: NarrativeEventProgress(
              pendingNarrativeOutcomeDeliveries: <NarrativeOutcomeDelivery>[
                _rawLegacyDelivery(
                  deliveryId: _legacyInvalidBattleDeliveryId,
                  outcomeId: _legacyInvalidBattleOutcomeId,
                ),
                _rawLegacyDelivery(
                  deliveryId: _legacyRawSecondDeliveryId,
                  outcomeId: _legacyRawSecondOutcomeId,
                ),
              ],
            ),
          ),
          narrativeRuntimeActivityGate: gate,
        );

        await _load(game);
        await _waitUntil(
          game,
          () =>
              game.gameStateSnapshot.narrativeEventProgress
                  .pendingNarrativeOutcomeDeliveries.isEmpty &&
              !game.debugIsNarrativeOutcomeWorkInFlight &&
              !game.debugIsMapActivationDispatchInFlight,
        );

        expect(gate.activity, NarrativeRuntimeActivity.idle);
        expect(game.debugHasPendingScenarioBattle, isFalse);
        expect(
          game.gameStateSnapshot.narrativeEventProgress
              .deliveredNarrativeOutcomeDeliveryIds,
          {_legacyInvalidBattleDeliveryId, _legacyRawSecondDeliveryId},
        );
        expect(
          game.gameStateSnapshot.storyFlags.activeFlags,
          contains(_legacyRawSecondCompletedFlag),
        );
      },
    );

    test(
      'cancels an accepted Scenario Battle continuation when async setup '
      'fails',
      () async {
        final gate = NarrativeRuntimeActivityGate();
        final game = _game(
          project: _legacyBattleContinuationProject(),
          includeTrainerNpc: true,
          narrativeRuntimeActivityGate: gate,
        );

        await _load(game);
        await _waitUntilWithoutUpdate(
          () =>
              game.debugHasPendingScenarioBattle &&
              !game.debugIsNarrativeOutcomeWorkInFlight &&
              !game.debugIsMapActivationDispatchInFlight,
        );
        expect(gate.activity, NarrativeRuntimeActivity.sceneSuspended);

        game.update(0.016);
        expect(game.debugFlowPhaseName, 'battleTransition');
        await Future<void>.delayed(const Duration(milliseconds: 450));
        await _waitUntil(
          game,
          () => game.debugFlowPhaseName == 'overworld',
        );

        expect(game.debugHasPendingScenarioBattle, isFalse);
        expect(gate.activity, NarrativeRuntimeActivity.idle);
        expect(
          game.gameStateSnapshot.storyFlags.activeFlags,
          isNot(contains('battle:legacy_outcome_battle:victory')),
        );
        expect(
          _factValue(game, _legacyBattleAfterConsumerFact),
          isNot(isTrue),
        );
      },
    );

    test(
      'does not overwrite a normal pending Battle with a Scenario Battle',
      () async {
        final normalBattle = _trainerContext().request;
        final gate = NarrativeRuntimeActivityGate();
        final game = _game(
          project: _legacyBattleContinuationProject(),
          includeTrainerNpc: true,
          narrativeRuntimeActivityGate: gate,
        );
        expect(
          game.debugTryEnqueueBattleRequestForTest(normalBattle),
          isTrue,
        );

        await _load(game);
        await _waitUntilWithoutUpdate(
          () =>
              !game.debugIsMapActivationDispatchInFlight &&
              !game.debugIsNarrativeOutcomeWorkInFlight,
        );

        expect(game.debugPendingBattleRequest, same(normalBattle));
        expect(game.debugHasPendingScenarioBattle, isFalse);
        expect(gate.activity, NarrativeRuntimeActivity.idle);
      },
    );

    test(
      'does not overwrite a pending Scenario Battle with an unrelated Battle',
      () async {
        final game = _game(
          project: _legacyBattleContinuationProject(),
          includeTrainerNpc: true,
        );

        await _load(game);
        await _waitUntilWithoutUpdate(
          () =>
              game.debugHasPendingScenarioBattle &&
              !game.debugIsNarrativeOutcomeWorkInFlight &&
              !game.debugIsMapActivationDispatchInFlight,
        );
        final scenarioBattle = game.debugPendingBattleRequest!;
        final unrelatedBattle = _trainerContext().request;

        expect(
          game.debugTryEnqueueBattleRequestForTest(unrelatedBattle),
          isFalse,
        );
        expect(game.debugPendingBattleRequest, same(scenarioBattle));

        game.debugApplyBattleOutcomeForTest(
          context: RuntimeActiveBattleContext(
            request: scenarioBattle,
            playerPartyIndex: 0,
          ),
          outcome: _victoryOutcome(playerCurrentHp: 5),
        );
        await _waitUntil(
          game,
          () => game.gameStateSnapshot.storyFlags.activeFlags
              .contains('battle:legacy_outcome_battle:victory'),
        );
        expect(game.debugHasPendingScenarioBattle, isFalse);
      },
    );

    test(
      'publishes an outcome-caused Scenario Battle before its continuation '
      'with the inherited correlation and depth',
      () async {
        final battleOutcome = NarrativeOutcomeRef(
          producerKind: NarrativeOutcomeProducerKind.battle,
          producerId: _trainerBattleRefId,
          outcomeId: 'victory',
        );
        final scenarioOutcome = NarrativeOutcomeRef(
          producerKind: NarrativeOutcomeProducerKind.legacyScenario,
          producerId: 'legacy_outcome_battle_scenario',
          outcomeId: 'after.battle',
        );
        final outcomeOccurrences = <NarrativeEventOccurrence>[];
        final game = _game(
          project: _legacyBattleContinuationProject(),
          includeTrainerNpc: true,
          beforeNarrativeAuthorityPreparation: (occurrence) async {
            if (occurrence.source.kind ==
                NarrativeEventSourceKind.outcomeReceived) {
              outcomeOccurrences.add(occurrence);
            }
          },
        );

        await _load(game);
        await _waitUntilWithoutUpdate(
          () =>
              game.debugHasPendingScenarioBattle &&
              !game.debugIsNarrativeOutcomeWorkInFlight &&
              !game.debugIsMapActivationDispatchInFlight,
        );

        expect(game.debugHasPendingScenarioBattle, isTrue);
        expect(outcomeOccurrences, hasLength(1));

        final scenarioBattleRequest = game.debugPendingBattleRequest!;
        game.debugApplyBattleOutcomeForTest(
          context: RuntimeActiveBattleContext(
            request: scenarioBattleRequest,
            playerPartyIndex: 0,
          ),
          outcome: _victoryOutcome(playerCurrentHp: 5),
        );
        await _waitUntil(
          game,
          () =>
              _factValue(game, _legacyBattleConsumerFact) == true &&
              _factValue(game, _legacyBattleAfterConsumerFact) == true,
        );

        expect(outcomeOccurrences, hasLength(3));
        expect(
          outcomeOccurrences.map((occurrence) => occurrence.source),
          <NarrativeEventSourceRef>[
            NarrativeEventSourceRef.outcomeReceived(
              NarrativeOutcomeRef(
                producerKind: NarrativeOutcomeProducerKind.legacyScenario,
                producerId: 'legacy_async_seed_scenario',
                outcomeId: 'seed',
              ),
            ),
            NarrativeEventSourceRef.outcomeReceived(battleOutcome),
            NarrativeEventSourceRef.outcomeReceived(scenarioOutcome),
          ],
          reason: 'The qualified Battle outcome must enter the outbox before '
              'the resumed Scenario emission.',
        );
        final rootCorrelationId = outcomeOccurrences.first.rootCorrelationId;
        expect(rootCorrelationId, isNotNull);
        expect(
          outcomeOccurrences.map((occurrence) => occurrence.rootCorrelationId),
          everyElement(rootCorrelationId),
        );
        expect(
          outcomeOccurrences.map((occurrence) => occurrence.depth),
          <int?>[0, 1, 1],
        );
        expect(_factValue(game, _legacyBattleConsumerFact), isTrue);
        expect(_factValue(game, _legacyBattleAfterConsumerFact), isTrue);
        expect(
          game.gameStateSnapshot.narrativeEventProgress
              .deliveredNarrativeOutcomeDeliveryIds,
          hasLength(3),
        );
      },
    );

    test(
      'refuses a hosted Scene Battle while a normal Battle owns the queue '
      'then attributes only the normal Battle outcome',
      () async {
        final project = _hostedBattleProject();
        _expectScenesValid(project);
        final gate = NarrativeRuntimeActivityGate();
        final normalBattleContext = _trainerContext();
        final normalBattle = normalBattleContext.request;
        final game = _game(
          project: project,
          narrativeRuntimeActivityGate: gate,
        );
        expect(
          game.debugTryEnqueueBattleRequestForTest(normalBattle),
          isTrue,
        );

        await _load(game);
        await _waitUntilWithoutUpdate(
          () =>
              game.debugHasPendingSceneBattle ||
              (!game.debugIsMapActivationDispatchInFlight &&
                  !game.debugIsNarrativeOutcomeWorkInFlight &&
                  gate.activity == NarrativeRuntimeActivity.idle),
        );

        expect(game.debugHasPendingSceneBattle, isFalse);
        expect(game.debugHasPendingScenarioBattle, isFalse);
        expect(game.debugPendingBattleRequest, same(normalBattle));
        expect(game.debugFlowPhaseName, 'overworld');
        expect(_factValue(game, _hostedBattleConsumerFact), isNot(isTrue));
        expect(_factValue(game, _hostedSceneConsumerFact), isNot(isTrue));
        expect(
          game.gameStateSnapshot.narrativeEventProgress
              .deliveredNarrativeOutcomeDeliveryIds,
          isEmpty,
        );

        game.update(0.016);
        expect(game.debugPendingBattleRequest, isNull);
        expect(game.debugFlowPhaseName, 'battleTransition');

        game.debugApplyBattleOutcomeForTest(
          context: normalBattleContext,
          outcome: _victoryOutcome(playerCurrentHp: 6),
        );
        await _waitUntil(
          game,
          () =>
              _factValue(game, _hostedBattleConsumerFact) == true &&
              !game.debugIsNarrativeOutcomeWorkInFlight,
        );

        for (var i = 0; i < 3; i++) {
          game.update(0.016);
          await Future<void>.delayed(Duration.zero);
        }
        final state = game.gameStateSnapshot;
        expect(game.debugFlowPhaseName, 'overworld');
        expect(game.debugPendingBattleRequest, isNull);
        expect(game.debugHasPendingSceneBattle, isFalse);
        expect(game.debugHasPendingScenarioBattle, isFalse);
        expect(_factValue(game, _hostedBattleConsumerFact), isTrue);
        expect(_factValue(game, _hostedSceneConsumerFact), isNot(isTrue));
        expect(
          state.narrativeEventProgress.deliveredNarrativeOutcomeDeliveryIds,
          hasLength(1),
          reason: 'Only the normal trainer Battle may publish an outcome; '
              'the refused Scene Battle must not be started or attributed.',
        );
      },
    );

    test(
      'cleans a V2 Scene dialogue after a synchronous loader exception and '
      'accepts a second launch',
      () async {
        final gate = NarrativeRuntimeActivityGate();
        var loadCount = 0;
        final project = _sceneDialogueLoaderFailureProject();
        _expectScenesValid(project);
        final game = _game(
          project: project,
          dialogueSessionLoader: (_) {
            loadCount++;
            throw StateError('synchronous V2 Scene dialogue load failed');
          },
          narrativeRuntimeActivityGate: gate,
        );
        await _load(game);
        await _waitUntil(
          game,
          () => !game.debugIsMapActivationDispatchInFlight,
        );

        Future<NarrativeSceneExecutionResult> launch(String executionId) {
          return game.debugExecuteNarrativeSceneForTest(
            NarrativeSceneExecutionRequest(
              eventId: 'event_scene_dialogue_loader_failure',
              sceneId: 'scene_dialogue_loader_failure',
              executionId: executionId,
              gameState: game.gameStateSnapshot,
            ),
          );
        }

        final first = await launch('execution_first');

        expect(first, isA<NarrativeSceneExecutionFailed>());
        expect(loadCount, 1);
        expect(game.debugHasPendingDialogueLoad, isFalse);
        expect(game.debugFlowPhaseName, 'overworld');
        expect(game.debugIsGameplayInputLocked, isFalse);
        expect(gate.activity, NarrativeRuntimeActivity.idle);

        final second = await launch('execution_second');

        expect(second, isA<NarrativeSceneExecutionFailed>());
        expect(loadCount, 2);
        expect(game.debugHasPendingDialogueLoad, isFalse);
        expect(game.debugFlowPhaseName, 'overworld');
        expect(game.debugIsGameplayInputLocked, isFalse);
        expect(gate.activity, NarrativeRuntimeActivity.idle);
      },
    );

    test(
      'cleans a V1 MapEvent Scene dialogue after a synchronous loader '
      'exception and accepts a second interaction',
      () async {
        final gate = NarrativeRuntimeActivityGate();
        var loadCount = 0;
        final project = _sceneDialogueLoaderFailureProject();
        _expectScenesValid(project, map: _sceneDialogueMap());
        final game = _game(
          project: project,
          map: _sceneDialogueMap(),
          dialogueSessionLoader: (_) {
            loadCount++;
            throw StateError('synchronous V1 Scene dialogue load failed');
          },
          narrativeRuntimeActivityGate: gate,
        );
        await _load(game);
        await _waitUntil(
          game,
          () => !game.debugIsMapActivationDispatchInFlight,
        );

        expect(
          game.handleRuntimeInputEvent(
            const RuntimeInputEvent.press(RuntimeInputControl.primary),
          ),
          isTrue,
        );
        await _waitUntilWithoutUpdate(
          () =>
              loadCount == 1 && gate.activity == NarrativeRuntimeActivity.idle,
        );

        expect(game.debugHasPendingDialogueLoad, isFalse);
        expect(game.debugFlowPhaseName, 'overworld');
        expect(game.debugIsGameplayInputLocked, isFalse);

        expect(
          game.handleRuntimeInputEvent(
            const RuntimeInputEvent.press(RuntimeInputControl.primary),
          ),
          isTrue,
        );
        await _waitUntilWithoutUpdate(
          () =>
              loadCount == 2 && gate.activity == NarrativeRuntimeActivity.idle,
        );

        expect(game.debugHasPendingDialogueLoad, isFalse);
        expect(game.debugFlowPhaseName, 'overworld');
        expect(game.debugIsGameplayInputLocked, isFalse);
      },
    );

    test(
      'commits hosted Battle write-back and drains Battle outcome before the '
      'parent Scene outcome',
      () async {
        final project = _hostedBattleProject();
        _expectScenesValid(project);
        final game = _game(project: project);

        await _load(game);
        await _waitUntil(game, () => game.debugHasPendingSceneBattle);

        game.debugApplyBattleOutcomeForTest(
          context: _trainerContext(),
          outcome: _victoryOutcome(playerCurrentHp: 6),
        );
        await _waitUntil(
          game,
          () => _factValue(game, _hostedSceneConsumerFact) == true,
        );

        final state = game.gameStateSnapshot;
        expect(state.party.members.single.currentHp, 6);
        expect(state.storyFlags.activeFlags, contains(_trainerDefeatedFlag));
        expect(_factValue(game, _hostedBattleConsumerFact), isTrue);
        expect(
          _factValue(game, _hostedSceneConsumerFact),
          isTrue,
          reason: 'The Scene outcome Event is conditioned on the fact written '
              'by the preceding hosted Battle outcome Event.',
        );
        expect(
          state.narrativeEventProgress.deliveredNarrativeOutcomeDeliveryIds,
          hasLength(2),
        );
      },
    );

    test(
      'discards hosted Battle working state and provisional outcome when the '
      'parent Scene fails',
      () async {
        final project = _hostedBattleRollbackProject();
        _expectScenesValid(project);
        final game = _game(
          project: project,
          dialogueSessionLoader: (_) async => null,
        );

        await _load(game);
        await _waitUntil(game, () => game.debugHasPendingSceneBattle);

        game.debugApplyBattleOutcomeForTest(
          context: _trainerContext(),
          outcome: _victoryOutcome(playerCurrentHp: 2),
        );
        await _waitUntil(
          game,
          () =>
              !game.debugIsMapActivationDispatchInFlight &&
              !game.debugHasPendingSceneBattle,
        );

        final state = game.gameStateSnapshot;
        expect(state.party.members.single.currentHp, 20);
        expect(
          state.storyFlags.activeFlags,
          isNot(contains(_trainerDefeatedFlag)),
        );
        expect(_factValue(game, _rollbackBattleConsumerFact), isNot(isTrue));
        expect(
          state.narrativeEventProgress.pendingNarrativeOutcomeDeliveries,
          isEmpty,
        );
        expect(
          state.narrativeEventProgress.deliveredNarrativeOutcomeDeliveryIds,
          isEmpty,
        );
        expect(
          state.narrativeEventProgress.consumedNarrativeEventIds,
          isNot(contains('evt_019abcde-5200-7000-8000-000000000001')),
        );
      },
    );
  });
}

PlayableMapGame _game({
  required ProjectManifest project,
  bool includeTrainerNpc = false,
  List<MapTrigger> triggers = const <MapTrigger>[],
  MapData? map,
  GameState? initialState,
  Future<DialogueSession?> Function(ResolvedDialogue)? dialogueSessionLoader,
  Future<void> Function(NarrativeEventOccurrence occurrence)?
      beforeNarrativeAuthorityPreparation,
  NarrativeRuntimeActivityGate? narrativeRuntimeActivityGate,
  GameSaveRepository? saveRepository,
  RuntimeMapBundleLoader? runtimeMapBundleLoader,
  MapActivationReason initialMapActivationReason =
      MapActivationReason.initialBoot,
}) {
  return _QualifiedOutcomeTestGame(
    bundle: RuntimeMapBundle(
      manifest: project,
      map: map ??
          _map(
            includeTrainerNpc: includeTrainerNpc,
            triggers: triggers,
          ),
      projectRootDirectory: '/tmp/qualified_outcome_v2',
      tilesetAbsolutePathsById: const <String, String>{},
    ),
    projectFilePath: '/tmp/qualified_outcome_v2/project.json',
    saveData: saveDataFromGameState(initialState ?? _initialState()),
    dialogueSessionLoader: dialogueSessionLoader,
    beforeNarrativeAuthorityPreparation: beforeNarrativeAuthorityPreparation,
    narrativeRuntimeActivityGate: narrativeRuntimeActivityGate,
    saveRepository: saveRepository,
    runtimeMapBundleLoader: runtimeMapBundleLoader,
    initialMapActivationReason: initialMapActivationReason,
  );
}

final class _QualifiedOutcomeTestGame extends PlayableMapGame {
  _QualifiedOutcomeTestGame({
    required super.bundle,
    required super.projectFilePath,
    super.saveData,
    super.dialogueSessionLoader,
    super.beforeNarrativeAuthorityPreparation,
    super.narrativeRuntimeActivityGate,
    super.saveRepository,
    super.runtimeMapBundleLoader,
    super.initialMapActivationReason,
  });

  @override
  bool get isLoaded => true;
}

Future<void> _load(PlayableMapGame game) async {
  game.onGameResize(Vector2(320, 240));
  await game.onLoad();
}

Future<void> _waitUntil(
  PlayableMapGame game,
  bool Function() done, {
  int maxTicks = 360,
}) async {
  for (var i = 0; i < maxTicks; i++) {
    if (done()) return;
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
  }
  final state = game.gameStateSnapshot;
  fail(
    'Timed out waiting for the qualified outcome runtime condition: '
    'outcomeWork=${game.debugIsNarrativeOutcomeWorkInFlight} '
    'activationWork=${game.debugIsMapActivationDispatchInFlight} '
    'pending=${state.narrativeEventProgress.pendingNarrativeOutcomeDeliveries} '
    'delivered=${state.narrativeEventProgress.deliveredNarrativeOutcomeDeliveryIds} '
    'facts=${state.narrativeFactRuntimeState.overridesByFactId}.',
  );
}

Future<void> _waitUntilWithoutUpdate(
  bool Function() done, {
  int maxTurns = 360,
}) async {
  for (var i = 0; i < maxTurns; i++) {
    if (done()) return;
    await Future<void>.delayed(Duration.zero);
  }
  fail('Timed out waiting for the asynchronous qualified outcome condition.');
}

bool? _factValue(PlayableMapGame game, String factId) =>
    game.gameStateSnapshot.narrativeFactRuntimeState.overridesByFactId[factId];

void _expectScenesValid(ProjectManifest project, {MapData? map}) {
  for (final scene in project.scenes) {
    final report = diagnoseSceneAgainstProject(
      scene,
      project,
      mapsById: <String, MapData>{_mapId: map ?? _map()},
    );
    expect(
      report.hasErrors,
      isFalse,
      reason: report.diagnostics
          .map((diagnostic) => '${diagnostic.code.name}: ${diagnostic.message}')
          .join('\n'),
    );
  }
}

GameState _initialState() => const GameState(
      saveId: 'qualified-outcome-save',
      currentMapId: _mapId,
      playerPosition: GridPos(x: 1, y: 1),
      party: PlayerParty(
        members: <PlayerPokemon>[
          PlayerPokemon(
            speciesId: 'sproutle',
            natureId: 'hardy',
            abilityId: 'overgrow',
            level: 5,
            knownMoveIds: <String>['tackle'],
            currentHp: 20,
          ),
        ],
      ),
    );

MapData _map({
  bool includeTrainerNpc = false,
  List<MapTrigger> triggers = const <MapTrigger>[],
}) =>
    MapData(
      id: _mapId,
      name: 'Qualified Outcome Map',
      size: const GridSize(width: 3, height: 3),
      layers: const <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: <MapEntity>[
        const MapEntity(
          id: 'spawn',
          name: 'Spawn',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 1, y: 1),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.south,
          ),
        ),
        if (includeTrainerNpc)
          const MapEntity(
            id: 'trainer_npc',
            name: 'Qualified Outcome Trainer',
            kind: MapEntityKind.npc,
            pos: GridPos(x: 2, y: 2),
            npc: MapEntityNpcData(
              displayName: 'Qualified Outcome Trainer',
              trainerId: _trainerId,
            ),
          ),
      ],
      triggers: triggers,
      mapMetadata: const MapMetadata(defaultSpawnId: 'spawn'),
    );

MapData _sceneDialogueMap() => const MapData(
      id: _mapId,
      name: 'Scene Dialogue Loader Failure Map',
      size: GridSize(width: 3, height: 3),
      layers: <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: <MapEntity>[
        MapEntity(
          id: 'spawn',
          name: 'Spawn',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 1, y: 1),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.south,
          ),
        ),
      ],
      events: <MapEventDefinition>[
        MapEventDefinition(
          id: 'scene_dialogue_event',
          title: 'Scene Dialogue Event',
          position: EventPosition(layerId: 'objects', x: 1, y: 2),
          pages: <MapEventPage>[
            MapEventPage(
              pageNumber: 0,
              sceneTarget: MapEventSceneTarget(
                sceneId: 'scene_dialogue_loader_failure',
              ),
            ),
          ],
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: 'spawn'),
    );

MapData _moveWarpMap() => const MapData(
      id: _mapId,
      name: 'Qualified Outcome Move Warp Map',
      size: GridSize(width: 5, height: 3),
      layers: <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: <MapEntity>[
        MapEntity(
          id: 'spawn',
          name: 'Spawn',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 0, y: 0),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.south,
          ),
        ),
        MapEntity(
          id: 'moving_npc',
          name: 'Moving NPC',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 1, y: 1),
          npc: MapEntityNpcData(
            displayName: 'Moving NPC',
            characterId: 'moving_npc_character',
          ),
        ),
      ],
      warps: <MapWarp>[
        MapWarp(
          id: 'npc_exit',
          pos: GridPos(x: 4, y: 1),
          targetMapId: 'unused_npc_target',
          targetPos: GridPos(x: 0, y: 0),
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: 'spawn'),
    );

MapData _followMoveWarpSourceMap() => const MapData(
      id: _mapId,
      name: 'Qualified Outcome Follow Move Warp Source',
      size: GridSize(width: 8, height: 4),
      layers: <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: <MapEntity>[
        MapEntity(
          id: 'spawn',
          name: 'Spawn',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 0, y: 1),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.east,
          ),
        ),
        MapEntity(
          id: 'moving_npc',
          name: 'Moving NPC',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 2, y: 1),
          npc: MapEntityNpcData(
            displayName: 'Moving NPC',
            characterId: 'moving_npc_character',
          ),
        ),
      ],
      warps: <MapWarp>[
        MapWarp(
          id: 'leader_exit',
          pos: GridPos(x: 4, y: 1),
          targetMapId: _legacyFollowMoveWarpTargetMapId,
          targetPos: GridPos(x: 2, y: 1),
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: 'spawn'),
    );

MapData _followMoveWarpTargetMap() => const MapData(
      id: _legacyFollowMoveWarpTargetMapId,
      name: 'Qualified Outcome Follow Move Warp Target',
      size: GridSize(width: 6, height: 4),
      layers: <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: <MapEntity>[
        MapEntity(
          id: 'target_spawn',
          name: 'Target Spawn',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 2, y: 1),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.east,
          ),
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: 'target_spawn'),
    );

MapData _moveReplacementMap() => const MapData(
      id: _mapId,
      name: 'Qualified Outcome Move Replacement Map',
      size: GridSize(width: 6, height: 4),
      layers: <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: <MapEntity>[
        MapEntity(
          id: 'spawn',
          name: 'Spawn',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 0, y: 0),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.south,
          ),
        ),
        MapEntity(
          id: 'moving_npc',
          name: 'Moving NPC',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 1, y: 1),
          npc: MapEntityNpcData(
            displayName: 'Moving NPC',
            characterId: 'moving_npc_character',
          ),
        ),
      ],
      warps: <MapWarp>[
        MapWarp(
          id: 'first_exit',
          pos: GridPos(x: 5, y: 1),
          targetMapId: 'unused_first_target',
          targetPos: GridPos(x: 0, y: 0),
        ),
        MapWarp(
          id: 'second_exit',
          pos: GridPos(x: 5, y: 2),
          targetMapId: 'unused_second_target',
          targetPos: GridPos(x: 0, y: 0),
        ),
      ],
      triggers: <MapTrigger>[
        MapTrigger(
          id: 'b_move_replacement',
          name: 'Second move replacement',
          type: TriggerType.camera,
          area: MapRect(
            pos: GridPos(x: 0, y: 1),
            size: GridSize(width: 1, height: 1),
          ),
        ),
        MapTrigger(
          id: 'a_move_replacement',
          name: 'First move replacement',
          type: TriggerType.camera,
          area: MapRect(
            pos: GridPos(x: 0, y: 1),
            size: GridSize(width: 1, height: 1),
          ),
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: 'spawn'),
    );

MapData _playerMoveWarpMap() => const MapData(
      id: _mapId,
      name: 'Qualified Outcome Player Move Warp Map',
      size: GridSize(width: 5, height: 3),
      layers: <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: <MapEntity>[
        MapEntity(
          id: 'spawn',
          name: 'Spawn',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 0, y: 0),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.east,
          ),
        ),
      ],
      warps: <MapWarp>[
        MapWarp(
          id: 'player_exit',
          pos: GridPos(x: 4, y: 0),
          targetMapId: _legacyPlayerWarpTargetMapId,
          targetPos: GridPos(x: 1, y: 1),
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: 'spawn'),
    );

MapData _scriptWarpTargetMap() => const MapData(
      id: _legacyScriptWarpTargetMapId,
      name: 'Qualified Outcome Script Warp Target',
      size: GridSize(width: 3, height: 3),
      layers: <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: <MapEntity>[
        MapEntity(
          id: 'target_spawn',
          name: 'Target Spawn',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 1, y: 1),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.south,
          ),
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: 'target_spawn'),
    );

MapData _warpConflictMap() => const MapData(
      id: _mapId,
      name: 'Qualified Outcome Warp Conflict Map',
      size: GridSize(width: 3, height: 4),
      layers: <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: <MapEntity>[
        MapEntity(
          id: 'spawn',
          name: 'Spawn',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 1, y: 1),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.south,
          ),
        ),
      ],
      warps: <MapWarp>[
        MapWarp(
          id: 'physical_exit',
          pos: GridPos(x: 1, y: 2),
          targetMapId: _legacyPhysicalWarpTargetMapId,
          targetPos: GridPos(x: 1, y: 1),
        ),
      ],
      triggers: <MapTrigger>[
        MapTrigger(
          id: 'warp_conflict_trigger',
          name: 'Warp Conflict Trigger',
          type: TriggerType.camera,
          area: MapRect(
            pos: GridPos(x: 1, y: 2),
            size: GridSize(width: 1, height: 1),
          ),
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: 'spawn'),
    );

MapData _physicalWarpTargetMap() => const MapData(
      id: _legacyPhysicalWarpTargetMapId,
      name: 'Qualified Outcome Physical Warp Target',
      size: GridSize(width: 3, height: 3),
      layers: <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: <MapEntity>[
        MapEntity(
          id: 'target_spawn',
          name: 'Target Spawn',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 1, y: 1),
          blocksMovement: false,
          spawn: MapEntitySpawnData(role: EntitySpawnRole.playerStart),
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: 'target_spawn'),
    );

MapData _transitionOwnershipMap() => const MapData(
      id: _mapId,
      name: 'Qualified Outcome Transition Ownership Map',
      size: GridSize(width: 3, height: 4),
      layers: <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: <MapEntity>[
        MapEntity(
          id: 'spawn',
          name: 'Spawn',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 1, y: 1),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.south,
          ),
        ),
      ],
      triggers: <MapTrigger>[
        MapTrigger(
          id: 'b_transition_outcome',
          name: 'Transition outcome producer',
          type: TriggerType.camera,
          area: MapRect(
            pos: GridPos(x: 1, y: 2),
            size: GridSize(width: 1, height: 1),
          ),
        ),
        MapTrigger(
          id: 'a_transition_owner',
          name: 'Independent transition owner',
          type: TriggerType.camera,
          area: MapRect(
            pos: GridPos(x: 1, y: 2),
            size: GridSize(width: 1, height: 1),
          ),
        ),
        MapTrigger(
          id: 'c_transition_rejected',
          name: 'Rejected concurrent transition',
          type: TriggerType.camera,
          area: MapRect(
            pos: GridPos(x: 1, y: 2),
            size: GridSize(width: 1, height: 1),
          ),
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: 'spawn'),
    );

MapData _transitionTargetMap() => const MapData(
      id: _legacyTransitionTargetMapId,
      name: 'Qualified Outcome Transition Target',
      size: GridSize(width: 3, height: 3),
      layers: <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: <MapEntity>[
        MapEntity(
          id: 'target_spawn',
          name: 'Target Spawn',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 1, y: 1),
          blocksMovement: false,
          spawn: MapEntitySpawnData(role: EntitySpawnRole.playerStart),
        ),
      ],
      warps: <MapWarp>[
        MapWarp(
          id: 'arrival',
          pos: GridPos(x: 1, y: 1),
          targetMapId: _mapId,
          targetPos: GridPos(x: 1, y: 1),
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: 'target_spawn'),
    );

ProjectManifest _crossProducerProject() {
  final sceneOutcome = NarrativeOutcomeRef(
    producerKind: NarrativeOutcomeProducerKind.scene,
    producerId: _sceneVictoryProducerId,
    outcomeId: _sharedOutcomeId,
  );
  final battleOutcome = NarrativeOutcomeRef(
    producerKind: NarrativeOutcomeProducerKind.battle,
    producerId: _trainerBattleRefId,
    outcomeId: _sharedOutcomeId,
  );
  return _project(
    facts: const <String>[_sceneConsumerFact, _battleConsumerFact],
    records: <NarrativeEventRecord>[
      _record(
        id: 'evt_019abcde-5000-7000-8000-000000000001',
        name: 'Produce Scene victory',
        source: NarrativeEventSourceRef.mapEnter(_mapId),
        sceneId: _sceneVictoryProducerId,
        order: 0,
      ),
      _record(
        id: 'evt_019abcde-5000-7000-8000-000000000002',
        name: 'Consume qualified Scene victory',
        source: NarrativeEventSourceRef.outcomeReceived(sceneOutcome),
        sceneId: 'scene_consume_scene_victory',
        order: 1,
      ),
      _record(
        id: 'evt_019abcde-5000-7000-8000-000000000003',
        name: 'Consume qualified Battle victory',
        source: NarrativeEventSourceRef.outcomeReceived(battleOutcome),
        sceneId: 'scene_consume_battle_victory',
        order: 2,
      ),
    ],
    scenes: <SceneAsset>[
      _outcomeScene(
        id: _sceneVictoryProducerId,
        outcomeId: _sharedOutcomeId,
      ),
      _factScene(
        id: 'scene_consume_scene_victory',
        factId: _sceneConsumerFact,
      ),
      _factScene(
        id: 'scene_consume_battle_victory',
        factId: _battleConsumerFact,
      ),
    ],
  );
}

ProjectManifest _legacyScenarioProject() {
  final legacyOutcome = NarrativeOutcomeRef(
    producerKind: NarrativeOutcomeProducerKind.legacyScenario,
    producerId: 'legacy_map_enter_scenario',
    outcomeId: 'legacy.completed',
  );
  return _project(
    mode: EventSystemMode.dualRead,
    facts: const <String>[_legacyConsumerFact],
    records: <NarrativeEventRecord>[
      _record(
        id: 'evt_019abcde-5100-7000-8000-000000000001',
        name: 'Consume qualified legacy outcome',
        source: NarrativeEventSourceRef.outcomeReceived(legacyOutcome),
        sceneId: 'scene_consume_legacy_outcome',
        order: 0,
      ),
    ],
    scenes: <SceneAsset>[
      _factScene(
        id: 'scene_consume_legacy_outcome',
        factId: _legacyConsumerFact,
      ),
    ],
    scenarios: <ScenarioAsset>[_legacyMapEnterScenario()],
  );
}

ProjectManifest _legacySynchronousChildProject() {
  final childOutcome = NarrativeOutcomeRef(
    producerKind: NarrativeOutcomeProducerKind.legacyScenario,
    producerId: 'legacy_synchronous_child_scenario',
    outcomeId: _legacySynchronousChildOutcomeId,
  );
  return _project(
    mode: EventSystemMode.dualRead,
    facts: const <String>[_legacySynchronousChildConsumerFact],
    records: <NarrativeEventRecord>[
      _record(
        id: 'evt_019abcde-5170-7000-8000-000000000004',
        name: 'Consume synchronous raw fallback child',
        source: NarrativeEventSourceRef.outcomeReceived(childOutcome),
        sceneId: 'scene_consume_synchronous_raw_fallback_child',
        order: 0,
      ),
    ],
    scenes: <SceneAsset>[
      _factScene(
        id: 'scene_consume_synchronous_raw_fallback_child',
        factId: _legacySynchronousChildConsumerFact,
      ),
    ],
    scenarios: const <ScenarioAsset>[
      ScenarioAsset(
        id: 'legacy_synchronous_child_scenario',
        name: 'Legacy synchronous child producer',
        scope: ScenarioScope.globalStory,
        entryNodeId: 'source',
        declaredOutcomes: <String>[_legacySynchronousChildOutcomeId],
        nodes: <ScenarioNode>[
          ScenarioNode(
            id: 'source',
            type: ScenarioNodeType.reference,
            payload: ScenarioNodePayload(actionKind: kScenarioSourceOutcome),
            binding: ScenarioNodeBinding(
              outcomeId: _legacySynchronousParentOutcomeId,
            ),
          ),
          ScenarioNode(
            id: 'emit',
            type: ScenarioNodeType.action,
            payload: ScenarioNodePayload(
              actionKind: kScenarioActionEmitOutcome,
            ),
            binding: ScenarioNodeBinding(
              outcomeId: _legacySynchronousChildOutcomeId,
            ),
          ),
          ScenarioNode(id: 'end', type: ScenarioNodeType.end),
        ],
        edges: <ScenarioEdge>[
          ScenarioEdge(
            id: 'source_to_emit',
            fromNodeId: 'source',
            toNodeId: 'emit',
          ),
          ScenarioEdge(
            id: 'emit_to_end',
            fromNodeId: 'emit',
            toNodeId: 'end',
          ),
        ],
      ),
    ],
  );
}

ProjectManifest _legacySameSourceCycleProject() {
  return _project(
    mode: EventSystemMode.dualRead,
    facts: const <String>[],
    records: const <NarrativeEventRecord>[],
    scenes: const <SceneAsset>[],
    scenarios: const <ScenarioAsset>[
      ScenarioAsset(
        id: 'legacy_same_source_cycle_scenario',
        name: 'Legacy same runtime source cycle',
        scope: ScenarioScope.localEventFlow,
        entryNodeId: 'source',
        nodes: <ScenarioNode>[
          ScenarioNode(id: 'start', type: ScenarioNodeType.start),
          ScenarioNode(
            id: 'source',
            type: ScenarioNodeType.reference,
            payload: ScenarioNodePayload(actionKind: kScenarioSourceMapEnter),
            binding: ScenarioNodeBinding(mapId: _mapId),
          ),
          ScenarioNode(
            id: 'run_script',
            type: ScenarioNodeType.action,
            payload: ScenarioNodePayload(actionKind: kScenarioActionRunScript),
            binding: ScenarioNodeBinding(scriptId: 'legacy_chain_script'),
          ),
          ScenarioNode(
            id: 'already_marked',
            type: ScenarioNodeType.condition,
            payload: ScenarioNodePayload(
              condition: ScriptCondition(
                type: ScriptConditionType.flagIsSet,
                params: <String, String>{
                  ScriptConditionParams.flagName:
                      _legacySameSourceCycleMarkedFlag,
                },
              ),
            ),
          ),
          ScenarioNode(
            id: 'mark_cycle',
            type: ScenarioNodeType.action,
            payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
            binding: ScenarioNodeBinding(
              flagName: _legacySameSourceCycleMarkedFlag,
            ),
          ),
          ScenarioNode(
            id: 'complete_cycle',
            type: ScenarioNodeType.action,
            payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
            binding: ScenarioNodeBinding(
              flagName: _legacySameSourceCycleCompletedFlag,
            ),
          ),
          ScenarioNode(id: 'end', type: ScenarioNodeType.end),
        ],
        edges: <ScenarioEdge>[
          ScenarioEdge(
            id: 'source_to_script',
            fromNodeId: 'source',
            toNodeId: 'run_script',
          ),
          ScenarioEdge(
            id: 'script_to_condition',
            fromNodeId: 'run_script',
            toNodeId: 'already_marked',
          ),
          ScenarioEdge(
            id: 'condition_true_to_complete',
            fromNodeId: 'already_marked',
            toNodeId: 'complete_cycle',
            kind: ScenarioEdgeKind.trueBranch,
          ),
          ScenarioEdge(
            id: 'condition_false_to_mark',
            fromNodeId: 'already_marked',
            toNodeId: 'mark_cycle',
            kind: ScenarioEdgeKind.falseBranch,
          ),
          ScenarioEdge(
            id: 'mark_to_same_script',
            fromNodeId: 'mark_cycle',
            toNodeId: 'run_script',
          ),
          ScenarioEdge(
            id: 'complete_to_end',
            fromNodeId: 'complete_cycle',
            toNodeId: 'end',
          ),
        ],
      ),
    ],
    scripts: <ProjectScriptEntry>[
      _legacySynchronousScript(scriptBehavior: 'end'),
    ],
  );
}

ProjectManifest _legacyAsyncScenarioProject() {
  final legacyOutcome = NarrativeOutcomeRef(
    producerKind: NarrativeOutcomeProducerKind.legacyScenario,
    producerId: 'legacy_async_outcome_scenario',
    outcomeId: 'after.dialogue',
  );
  return _project(
    mode: EventSystemMode.dualRead,
    facts: const <String>[_legacyAsyncConsumerFact],
    records: <NarrativeEventRecord>[
      _record(
        id: 'evt_019abcde-5150-7000-8000-000000000002',
        name: 'Consume async qualified legacy outcome',
        source: NarrativeEventSourceRef.outcomeReceived(legacyOutcome),
        sceneId: 'scene_consume_async_legacy_outcome',
        order: 0,
      ),
    ],
    scenes: <SceneAsset>[
      _factScene(
        id: 'scene_consume_async_legacy_outcome',
        factId: _legacyAsyncConsumerFact,
      ),
    ],
    scenarios: <ScenarioAsset>[
      _legacyAsyncSeedScenario(),
      _legacyAsyncOutcomeScenario(),
    ],
    dialogues: const <ProjectDialogueEntry>[
      ProjectDialogueEntry(
        id: 'legacy_async_dialogue',
        name: 'Legacy async dialogue',
        relativePath: 'dialogues/legacy_async_dialogue.yarn',
      ),
    ],
  );
}

ProjectManifest _legacyOverlappingTriggerOutcomeProject() {
  final firstOutcome = NarrativeOutcomeRef(
    producerKind: NarrativeOutcomeProducerKind.legacyScenario,
    producerId: 'legacy_overlap_first_scenario',
    outcomeId: 'overlap.first',
  );
  final secondOutcome = NarrativeOutcomeRef(
    producerKind: NarrativeOutcomeProducerKind.legacyScenario,
    producerId: 'legacy_overlap_second_scenario',
    outcomeId: 'overlap.second',
  );
  return _project(
    mode: EventSystemMode.dualRead,
    facts: const <String>[
      _legacyOverlapFirstConsumerFact,
      _legacyOverlapSecondConsumerFact,
    ],
    records: <NarrativeEventRecord>[
      _record(
        id: 'evt_019abcde-5160-7000-8000-000000000001',
        name: 'Consume first overlapping legacy outcome',
        source: NarrativeEventSourceRef.outcomeReceived(firstOutcome),
        sceneId: 'scene_consume_legacy_overlap_first',
        order: 0,
      ),
      _record(
        id: 'evt_019abcde-5160-7000-8000-000000000002',
        name: 'Consume second overlapping legacy outcome',
        source: NarrativeEventSourceRef.outcomeReceived(secondOutcome),
        sceneId: 'scene_consume_legacy_overlap_second',
        order: 1,
      ),
    ],
    scenes: <SceneAsset>[
      _factScene(
        id: 'scene_consume_legacy_overlap_first',
        factId: _legacyOverlapFirstConsumerFact,
      ),
      _factScene(
        id: 'scene_consume_legacy_overlap_second',
        factId: _legacyOverlapSecondConsumerFact,
      ),
    ],
    scenarios: <ScenarioAsset>[
      _legacyTriggerOutcomeScenario(
        scenarioId: 'legacy_overlap_first_scenario',
        triggerId: 'a_legacy_camera_trigger',
        outcomeId: 'overlap.first',
      ),
      _legacyTriggerOutcomeScenario(
        scenarioId: 'legacy_overlap_second_scenario',
        triggerId: 'b_legacy_camera_trigger',
        outcomeId: 'overlap.second',
      ),
    ],
  );
}

ProjectManifest _legacyRawDialogueBarrierProject() {
  return _project(
    mode: EventSystemMode.dualRead,
    facts: const <String>[],
    records: const <NarrativeEventRecord>[],
    scenes: const <SceneAsset>[],
    scenarios: <ScenarioAsset>[
      _legacyRawFirstDialogueScenario(),
      _legacyRawSecondScenario(),
    ],
    dialogues: const <ProjectDialogueEntry>[
      ProjectDialogueEntry(
        id: 'legacy_raw_first_dialogue',
        name: 'Legacy raw first dialogue',
        relativePath: 'dialogues/legacy_raw_first_dialogue.yarn',
      ),
    ],
  );
}

ProjectManifest _legacySuspendedProducerProject() {
  final seedOutcome = NarrativeOutcomeRef(
    producerKind: NarrativeOutcomeProducerKind.legacyScenario,
    producerId: 'legacy_suspended_producer',
    outcomeId: 'producer.seed',
  );
  final afterOutcome = NarrativeOutcomeRef(
    producerKind: NarrativeOutcomeProducerKind.legacyScenario,
    producerId: 'legacy_suspended_producer',
    outcomeId: 'producer.after_dialogue',
  );
  return _project(
    mode: EventSystemMode.dualRead,
    facts: const <String>[
      _legacyProducerSeedFact,
      _legacyProducerAfterFact,
    ],
    records: <NarrativeEventRecord>[
      _record(
        id: 'evt_019abcde-5185-7000-8000-000000000001',
        name: 'Consume suspended producer seed',
        source: NarrativeEventSourceRef.outcomeReceived(seedOutcome),
        sceneId: 'scene_consume_suspended_producer_seed',
        order: 0,
      ),
      _record(
        id: 'evt_019abcde-5185-7000-8000-000000000002',
        name: 'Consume suspended producer continuation',
        source: NarrativeEventSourceRef.outcomeReceived(afterOutcome),
        sceneId: 'scene_consume_suspended_producer_after',
        order: 1,
      ),
    ],
    scenes: <SceneAsset>[
      _factScene(
        id: 'scene_consume_suspended_producer_seed',
        factId: _legacyProducerSeedFact,
      ),
      _factScene(
        id: 'scene_consume_suspended_producer_after',
        factId: _legacyProducerAfterFact,
      ),
    ],
    scenarios: <ScenarioAsset>[_legacySuspendedProducerScenario()],
    dialogues: const <ProjectDialogueEntry>[
      ProjectDialogueEntry(
        id: 'legacy_suspended_producer_dialogue',
        name: 'Legacy suspended producer dialogue',
        relativePath: 'dialogues/legacy_suspended_producer_dialogue.yarn',
      ),
    ],
  );
}

ProjectManifest _legacyMoveWarpProject() {
  return _project(
    mode: EventSystemMode.dualRead,
    facts: const <String>[],
    records: const <NarrativeEventRecord>[],
    scenes: const <SceneAsset>[],
    scenarios: <ScenarioAsset>[_legacyMoveWarpScenario()],
    characters: const <ProjectCharacterEntry>[
      ProjectCharacterEntry(
        id: 'moving_npc_character',
        name: 'Moving NPC Character',
        tilesetId: 'missing_test_tileset',
        frameWidth: 2,
        frameHeight: 2,
      ),
    ],
  );
}

ProjectManifest _legacyFollowMoveWarpProject() {
  return _project(
    mode: EventSystemMode.dualRead,
    facts: const <String>[],
    records: const <NarrativeEventRecord>[],
    scenes: const <SceneAsset>[],
    scenarios: <ScenarioAsset>[
      _legacyFollowMoveWarpScenario(),
      _legacyRawSecondScenario(),
    ],
    characters: const <ProjectCharacterEntry>[
      ProjectCharacterEntry(
        id: 'moving_npc_character',
        name: 'Moving NPC Character',
        tilesetId: 'missing_test_tileset',
        frameWidth: 2,
        frameHeight: 2,
      ),
    ],
    maps: const <ProjectMapEntry>[
      ProjectMapEntry(
        id: _mapId,
        name: 'Qualified Outcome Follow Move Warp Source',
        relativePath: 'maps/qualified_outcome_map.json',
      ),
      ProjectMapEntry(
        id: _legacyFollowMoveWarpTargetMapId,
        name: 'Qualified Outcome Follow Move Warp Target',
        relativePath: 'maps/qualified_outcome_follow_move_warp_target.json',
      ),
    ],
  );
}

ProjectManifest _legacyMoveReplacementProject() {
  return _project(
    mode: EventSystemMode.dualRead,
    facts: const <String>[],
    records: const <NarrativeEventRecord>[],
    scenes: const <SceneAsset>[],
    scenarios: <ScenarioAsset>[
      _legacyMoveReplacementScenario(
        id: 'legacy_move_replacement_first',
        triggerId: 'a_move_replacement',
        warpId: 'first_exit',
        completedFlag: _legacyMoveReplacementFirstFlag,
      ),
      _legacyMoveReplacementScenario(
        id: 'legacy_move_replacement_second',
        triggerId: 'b_move_replacement',
        warpId: 'second_exit',
        completedFlag: _legacyMoveReplacementSecondFlag,
      ),
    ],
    characters: const <ProjectCharacterEntry>[
      ProjectCharacterEntry(
        id: 'moving_npc_character',
        name: 'Moving NPC Character',
        tilesetId: 'missing_test_tileset',
        frameWidth: 2,
        frameHeight: 2,
      ),
    ],
  );
}

ProjectManifest _legacyPlayerMoveWarpProject() {
  return _project(
    mode: EventSystemMode.dualRead,
    facts: const <String>[],
    records: const <NarrativeEventRecord>[],
    scenes: const <SceneAsset>[],
    scenarios: <ScenarioAsset>[_legacyPlayerMoveWarpScenario()],
  );
}

ProjectManifest _legacyScriptWarpProject() {
  return _project(
    mode: EventSystemMode.dualRead,
    facts: const <String>[],
    records: const <NarrativeEventRecord>[],
    scenes: const <SceneAsset>[],
    scenarios: <ScenarioAsset>[
      _legacyScriptWarpScenario(),
      _legacyRawSecondScenario(),
    ],
    scripts: <ProjectScriptEntry>[_legacyWarpScript()],
    maps: const <ProjectMapEntry>[
      ProjectMapEntry(
        id: _mapId,
        name: 'Qualified Outcome Map',
        relativePath: 'maps/qualified_outcome_map.json',
      ),
      ProjectMapEntry(
        id: _legacyScriptWarpTargetMapId,
        name: 'Qualified Outcome Script Warp Target',
        relativePath: 'maps/qualified_outcome_script_warp_target.json',
      ),
    ],
  );
}

ProjectManifest _legacyWarpConflictProject() {
  return _project(
    mode: EventSystemMode.legacyOnly,
    facts: const <String>[],
    records: const <NarrativeEventRecord>[],
    scenes: const <SceneAsset>[],
    scenarios: <ScenarioAsset>[_legacyWarpConflictScenario()],
    scripts: <ProjectScriptEntry>[_legacyWarpScript()],
  );
}

ProjectManifest _legacyTransitionOwnershipProject() {
  return _project(
    mode: EventSystemMode.dualRead,
    facts: const <String>[],
    records: const <NarrativeEventRecord>[],
    scenes: const <SceneAsset>[],
    scenarios: <ScenarioAsset>[
      _legacyIndependentTransitionScenario(),
      _legacyRejectedTransitionScenario(),
      _legacyTriggerOutcomeScenario(
        scenarioId: 'legacy_transition_outcome_producer',
        triggerId: 'b_transition_outcome',
        outcomeId: _legacyRawSecondOutcomeId,
      ),
      _legacyRawSecondScenario(),
    ],
  );
}

ProjectManifest _legacyScriptFailureProject({
  required bool throwsFromCommand,
}) {
  return _project(
    mode: EventSystemMode.dualRead,
    facts: const <String>[],
    records: const <NarrativeEventRecord>[],
    scenes: const <SceneAsset>[],
    scenarios: <ScenarioAsset>[
      _legacyScriptFailureScenario(),
      _legacyRawSecondScenario(),
    ],
    scripts: <ProjectScriptEntry>[
      _legacyFailureScript(throwsFromCommand: throwsFromCommand),
    ],
    dialogues: const <ProjectDialogueEntry>[
      ProjectDialogueEntry(
        id: 'legacy_script_failure_dialogue',
        name: 'Legacy Script Failure Dialogue',
        relativePath: 'dialogues/script_failure.yarn',
      ),
    ],
  );
}

ProjectManifest _legacyImmediateScriptFailureProject({
  required bool throwsFromCommand,
}) {
  return _project(
    mode: EventSystemMode.dualRead,
    facts: const <String>[],
    records: const <NarrativeEventRecord>[],
    scenes: const <SceneAsset>[],
    scenarios: <ScenarioAsset>[
      _legacyScriptFailureScenario(),
      _legacyRawSecondScenario(),
    ],
    scripts: <ProjectScriptEntry>[
      _legacyImmediateFailureScript(throwsFromCommand: throwsFromCommand),
    ],
  );
}

ProjectManifest _legacyDialogueThenScriptProject({
  required String scriptBehavior,
}) {
  return _project(
    mode: EventSystemMode.dualRead,
    facts: const <String>[],
    records: const <NarrativeEventRecord>[],
    scenes: const <SceneAsset>[],
    scenarios: <ScenarioAsset>[
      _legacyDialogueThenScriptScenario(),
      _legacyRawSecondScenario(),
    ],
    scripts: <ProjectScriptEntry>[
      _legacySynchronousScript(scriptBehavior: scriptBehavior),
    ],
    dialogues: const <ProjectDialogueEntry>[
      ProjectDialogueEntry(
        id: 'legacy_chain_first_dialogue',
        name: 'Legacy chain first dialogue',
        relativePath: 'dialogues/chain_first.yarn',
      ),
    ],
  );
}

ProjectManifest _legacyDialogueThenDialogueProject() {
  return _project(
    mode: EventSystemMode.dualRead,
    facts: const <String>[],
    records: const <NarrativeEventRecord>[],
    scenes: const <SceneAsset>[],
    scenarios: <ScenarioAsset>[
      _legacyDialogueThenDialogueScenario(),
      _legacyRawSecondScenario(),
    ],
    dialogues: const <ProjectDialogueEntry>[
      ProjectDialogueEntry(
        id: 'legacy_chain_first_dialogue',
        name: 'Legacy chain first dialogue',
        relativePath: 'dialogues/chain_first.yarn',
      ),
      ProjectDialogueEntry(
        id: 'legacy_chain_second_dialogue',
        name: 'Legacy chain second dialogue',
        relativePath: 'dialogues/chain_second.yarn',
      ),
    ],
  );
}

ProjectManifest _legacyScriptNoWarpProject() {
  return _project(
    mode: EventSystemMode.dualRead,
    facts: const <String>[],
    records: const <NarrativeEventRecord>[],
    scenes: const <SceneAsset>[],
    scenarios: <ScenarioAsset>[_legacyScriptFailureScenario()],
    scripts: const <ProjectScriptEntry>[
      ProjectScriptEntry(
        id: 'legacy_failure_script',
        name: 'Legacy No-Warp Script',
        asset: ScriptAsset(
          id: 'legacy_failure_script',
          defaultStartNode: 'start',
          nodes: <ScriptNode>[
            ScriptNode(
              id: 'start',
              commands: <ScriptCommand>[
                ScriptCommand(type: ScriptCommandType.end),
              ],
            ),
          ],
        ),
      ),
    ],
  );
}

ProjectManifest _legacyInvalidBattleProject() {
  return _project(
    mode: EventSystemMode.dualRead,
    facts: const <String>[],
    records: const <NarrativeEventRecord>[],
    scenes: const <SceneAsset>[],
    scenarios: <ScenarioAsset>[
      _legacyInvalidBattleScenario(),
      _legacyRawSecondScenario(),
    ],
  );
}

ProjectManifest _legacyBattleContinuationProject() {
  final battleOutcome = NarrativeOutcomeRef(
    producerKind: NarrativeOutcomeProducerKind.battle,
    producerId: _trainerBattleRefId,
    outcomeId: 'victory',
  );
  final scenarioOutcome = NarrativeOutcomeRef(
    producerKind: NarrativeOutcomeProducerKind.legacyScenario,
    producerId: 'legacy_outcome_battle_scenario',
    outcomeId: 'after.battle',
  );
  return _project(
    mode: EventSystemMode.dualRead,
    facts: const <String>[
      _legacyBattleConsumerFact,
      _legacyBattleAfterConsumerFact,
    ],
    records: <NarrativeEventRecord>[
      _record(
        id: 'evt_019abcde-5175-7000-8000-000000000001',
        name: 'Consume correlated legacy Scenario Battle outcome',
        source: NarrativeEventSourceRef.outcomeReceived(battleOutcome),
        sceneId: 'scene_consume_legacy_battle_outcome',
        order: 0,
      ),
      _record(
        id: 'evt_019abcde-5175-7000-8000-000000000002',
        name: 'Consume correlated post-Battle Scenario outcome',
        source: NarrativeEventSourceRef.outcomeReceived(scenarioOutcome),
        sceneId: 'scene_consume_legacy_battle_after',
        conditions: <NarrativeEventCondition>[
          NarrativeEventCondition.fact(_legacyBattleConsumerFact, true),
        ],
        order: 1,
      ),
    ],
    scenes: <SceneAsset>[
      _factScene(
        id: 'scene_consume_legacy_battle_outcome',
        factId: _legacyBattleConsumerFact,
      ),
      _factScene(
        id: 'scene_consume_legacy_battle_after',
        factId: _legacyBattleAfterConsumerFact,
      ),
    ],
    scenarios: <ScenarioAsset>[
      _legacyAsyncSeedScenario(),
      _legacyOutcomeBattleScenario(),
    ],
  );
}

ProjectManifest _hostedBattleProject() {
  final battleOutcome = NarrativeOutcomeRef(
    producerKind: NarrativeOutcomeProducerKind.battle,
    producerId: _trainerBattleRefId,
    outcomeId: 'victory',
  );
  final sceneOutcome = NarrativeOutcomeRef(
    producerKind: NarrativeOutcomeProducerKind.scene,
    producerId: 'scene_hosted_battle_parent',
    outcomeId: 'scene.completed',
  );
  return _project(
    facts: const <String>[
      _hostedBattleConsumerFact,
      _hostedSceneConsumerFact,
    ],
    records: <NarrativeEventRecord>[
      _record(
        id: 'evt_019abcde-5200-7000-8000-000000000011',
        name: 'Run hosted Battle parent Scene',
        source: NarrativeEventSourceRef.mapEnter(_mapId),
        sceneId: 'scene_hosted_battle_parent',
        order: 0,
      ),
      _record(
        id: 'evt_019abcde-5200-7000-8000-000000000012',
        name: 'Consume hosted Battle victory',
        source: NarrativeEventSourceRef.outcomeReceived(battleOutcome),
        sceneId: 'scene_consume_hosted_battle',
        order: 1,
      ),
      _record(
        id: 'evt_019abcde-5200-7000-8000-000000000013',
        name: 'Consume parent Scene outcome after Battle',
        source: NarrativeEventSourceRef.outcomeReceived(sceneOutcome),
        sceneId: 'scene_consume_hosted_parent',
        conditions: <NarrativeEventCondition>[
          NarrativeEventCondition.fact(_hostedBattleConsumerFact, true),
        ],
        order: 2,
      ),
    ],
    scenes: <SceneAsset>[
      _hostedBattleScene(
        id: 'scene_hosted_battle_parent',
        sceneOutcomeId: 'scene.completed',
      ),
      _factScene(
        id: 'scene_consume_hosted_battle',
        factId: _hostedBattleConsumerFact,
      ),
      _factScene(
        id: 'scene_consume_hosted_parent',
        factId: _hostedSceneConsumerFact,
      ),
    ],
  );
}

ProjectManifest _hostedBattleRollbackProject() {
  final battleOutcome = NarrativeOutcomeRef(
    producerKind: NarrativeOutcomeProducerKind.battle,
    producerId: _trainerBattleRefId,
    outcomeId: 'victory',
  );
  return _project(
    facts: const <String>[_rollbackBattleConsumerFact],
    records: <NarrativeEventRecord>[
      _record(
        id: 'evt_019abcde-5200-7000-8000-000000000001',
        name: 'Run failing hosted Battle parent Scene',
        source: NarrativeEventSourceRef.mapEnter(_mapId),
        sceneId: 'scene_hosted_battle_rollback',
        order: 0,
      ),
      _record(
        id: 'evt_019abcde-5200-7000-8000-000000000002',
        name: 'Provisional Battle outcome must be discarded',
        source: NarrativeEventSourceRef.outcomeReceived(battleOutcome),
        sceneId: 'scene_rollback_battle_consumer',
        order: 1,
      ),
    ],
    scenes: <SceneAsset>[
      _hostedBattleScene(
        id: 'scene_hosted_battle_rollback',
        dialogueAfterVictoryId: 'missing_runtime_dialogue',
      ),
      _factScene(
        id: 'scene_rollback_battle_consumer',
        factId: _rollbackBattleConsumerFact,
      ),
    ],
    dialogues: const <ProjectDialogueEntry>[
      ProjectDialogueEntry(
        id: 'missing_runtime_dialogue',
        name: 'Authored but unavailable at runtime',
        relativePath: 'dialogues/missing_runtime_dialogue.yarn',
      ),
    ],
  );
}

ProjectManifest _sceneDialogueLoaderFailureProject() {
  return _project(
    facts: const <String>[],
    records: const <NarrativeEventRecord>[],
    scenes: <SceneAsset>[_sceneDialogueLoaderFailureScene()],
    dialogues: const <ProjectDialogueEntry>[
      ProjectDialogueEntry(
        id: 'scene_dialogue_loader_failure',
        name: 'Scene dialogue loader failure',
        relativePath: 'dialogues/scene_dialogue_loader_failure.yarn',
      ),
    ],
  );
}

ProjectManifest _project({
  required List<String> facts,
  required List<NarrativeEventRecord> records,
  required List<SceneAsset> scenes,
  EventSystemMode mode = EventSystemMode.v2Only,
  List<ScenarioAsset> scenarios = const <ScenarioAsset>[],
  List<ProjectDialogueEntry> dialogues = const <ProjectDialogueEntry>[],
  List<ProjectCharacterEntry> characters = const <ProjectCharacterEntry>[],
  List<ProjectScriptEntry> scripts = const <ProjectScriptEntry>[],
  List<ProjectMapEntry> maps = const <ProjectMapEntry>[
    ProjectMapEntry(
      id: _mapId,
      name: 'Qualified Outcome Map',
      relativePath: 'maps/qualified_outcome_map.json',
    ),
  ],
}) {
  return ProjectManifest(
    name: 'Qualified Outcome V2 Integration',
    maps: maps,
    tilesets: const <ProjectTilesetEntry>[],
    dialogues: dialogues,
    characters: characters,
    scripts: scripts,
    scenarios: scenarios,
    facts: <NarrativeFactDefinition>[
      for (final factId in facts)
        NarrativeFactDefinition(id: factId, label: factId),
    ],
    eventRegistry: NarrativeEventRegistry(
      schemaVersion: 1,
      mode: mode,
      records: records,
      legacyClaims: const <LegacySourceClaim>[],
    ),
    scenes: scenes,
    trainers: const <ProjectTrainerEntry>[
      ProjectTrainerEntry(
        id: _trainerId,
        name: 'Qualified Outcome Trainer',
        trainerClass: 'Tester',
        team: <ProjectTrainerPokemonEntry>[
          ProjectTrainerPokemonEntry(speciesId: 'embercub', level: 5),
        ],
      ),
    ],
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
  );
}

NarrativeEventRecord _record({
  required String id,
  required String name,
  required NarrativeEventSourceRef source,
  required String sceneId,
  required int order,
  List<NarrativeEventCondition> conditions = const <NarrativeEventCondition>[],
}) {
  return NarrativeEventRecord.configuredStructurallyUnchecked(
    NarrativeEventDefinition(
      id: id,
      name: name,
      source: source,
      conditions: conditions,
      sceneId: sceneId,
      reusePolicy: NarrativeEventReusePolicy.oneShot,
      priority: 0,
      order: order,
    ),
    enabled: true,
  );
}

SceneAsset _outcomeScene({required String id, required String outcomeId}) {
  return SceneAsset(
    id: id,
    name: id,
    declaredOutcomes: <SceneOutcome>[
      SceneOutcome(id: outcomeId, label: outcomeId),
    ],
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: <SceneNode>[
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'end',
          kind: SceneNodeKind.end,
          payload: SceneEndPayload(sceneOutcomeId: outcomeId),
        ),
      ],
      edges: <SceneEdge>[
        SceneEdge(
          id: 'start_to_end',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.defaultFlow,
        ),
      ],
    ),
  );
}

SceneAsset _factScene({required String id, required String factId}) {
  return SceneAsset(
    id: id,
    name: id,
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: <SceneNode>[
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'set_fact',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.setFact(factId: factId, value: true),
          ),
        ),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ],
      edges: <SceneEdge>[
        SceneEdge(
          id: 'start_to_fact',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'set_fact',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'fact_to_end',
          fromNodeId: 'set_fact',
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.actionCompleted,
        ),
      ],
    ),
  );
}

SceneAsset _sceneDialogueLoaderFailureScene() {
  return SceneAsset(
    id: 'scene_dialogue_loader_failure',
    name: 'Scene dialogue loader failure',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: <SceneNode>[
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'dialogue',
          kind: SceneNodeKind.yarnDialogue,
          payload: SceneYarnDialoguePayload(
            dialogueId: 'scene_dialogue_loader_failure',
          ),
        ),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ],
      edges: <SceneEdge>[
        SceneEdge(
          id: 'start_to_dialogue',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'dialogue',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'dialogue_to_end',
          fromNodeId: 'dialogue',
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.defaultFlow,
        ),
      ],
    ),
  );
}

SceneAsset _hostedBattleScene({
  required String id,
  String? sceneOutcomeId,
  String? dialogueAfterVictoryId,
}) {
  final victoryTarget =
      dialogueAfterVictoryId == null ? 'victory_end' : 'dialogue';
  return SceneAsset(
    id: id,
    name: id,
    declaredOutcomes: <SceneOutcome>[
      if (sceneOutcomeId != null)
        SceneOutcome(id: sceneOutcomeId, label: sceneOutcomeId),
    ],
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: <SceneNode>[
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'battle',
          kind: SceneNodeKind.battle,
          payload: SceneBattlePayload(
            battleKind: 'trainer',
            trainerId: _trainerId,
            npcEntityId: 'trainer_npc',
            declaredOutcomes: const <String>['victory', 'defeat'],
          ),
        ),
        if (dialogueAfterVictoryId != null)
          SceneNode(
            id: 'dialogue',
            kind: SceneNodeKind.yarnDialogue,
            payload: SceneYarnDialoguePayload(
              dialogueId: dialogueAfterVictoryId,
            ),
          ),
        SceneNode(
          id: 'victory_end',
          kind: SceneNodeKind.end,
          payload: sceneOutcomeId == null
              ? null
              : SceneEndPayload(sceneOutcomeId: sceneOutcomeId),
        ),
        SceneNode(id: 'defeat_end', kind: SceneNodeKind.end),
      ],
      edges: <SceneEdge>[
        SceneEdge(
          id: 'start_to_battle',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'battle',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'battle_victory',
          fromNodeId: 'battle',
          fromPortId: 'victory',
          toNodeId: victoryTarget,
          kind: SceneEdgeKind.battleVictory,
        ),
        if (dialogueAfterVictoryId != null)
          SceneEdge(
            id: 'dialogue_to_end',
            fromNodeId: 'dialogue',
            fromPortId: 'completed',
            toNodeId: 'victory_end',
            kind: SceneEdgeKind.defaultFlow,
          ),
        SceneEdge(
          id: 'battle_defeat',
          fromNodeId: 'battle',
          fromPortId: 'defeat',
          toNodeId: 'defeat_end',
          kind: SceneEdgeKind.battleDefeat,
        ),
      ],
    ),
  );
}

ScenarioAsset _legacyMapEnterScenario() {
  return const ScenarioAsset(
    id: 'legacy_map_enter_scenario',
    name: 'Legacy mapEnter outcome producer',
    entryNodeId: 'source',
    declaredOutcomes: <String>['legacy.completed'],
    nodes: <ScenarioNode>[
      ScenarioNode(
        id: 'source',
        type: ScenarioNodeType.reference,
        payload: ScenarioNodePayload(actionKind: kScenarioSourceMapEnter),
        binding: ScenarioNodeBinding(mapId: _mapId),
      ),
      ScenarioNode(
        id: 'emit',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(actionKind: kScenarioActionEmitOutcome),
        binding: ScenarioNodeBinding(outcomeId: 'legacy.completed'),
      ),
      ScenarioNode(id: 'end', type: ScenarioNodeType.end),
    ],
    edges: <ScenarioEdge>[
      ScenarioEdge(
          id: 'source_to_emit', fromNodeId: 'source', toNodeId: 'emit'),
      ScenarioEdge(id: 'emit_to_end', fromNodeId: 'emit', toNodeId: 'end'),
    ],
  );
}

ScenarioAsset _legacyTriggerOutcomeScenario({
  required String scenarioId,
  required String triggerId,
  required String outcomeId,
}) {
  return ScenarioAsset(
    id: scenarioId,
    name: scenarioId,
    scope: ScenarioScope.localEventFlow,
    entryNodeId: 'source',
    declaredOutcomes: <String>[outcomeId],
    nodes: <ScenarioNode>[
      ScenarioNode(
        id: 'source',
        type: ScenarioNodeType.reference,
        payload: const ScenarioNodePayload(
          actionKind: kScenarioSourceTriggerEnter,
        ),
        binding: ScenarioNodeBinding(
          mapId: _mapId,
          triggerId: triggerId,
        ),
      ),
      ScenarioNode(
        id: 'emit',
        type: ScenarioNodeType.action,
        payload: const ScenarioNodePayload(
          actionKind: kScenarioActionEmitOutcome,
        ),
        binding: ScenarioNodeBinding(outcomeId: outcomeId),
      ),
      const ScenarioNode(id: 'end', type: ScenarioNodeType.end),
    ],
    edges: const <ScenarioEdge>[
      ScenarioEdge(
        id: 'source_to_emit',
        fromNodeId: 'source',
        toNodeId: 'emit',
      ),
      ScenarioEdge(
        id: 'emit_to_end',
        fromNodeId: 'emit',
        toNodeId: 'end',
      ),
    ],
  );
}

ScenarioAsset _legacyAsyncOutcomeScenario() {
  return const ScenarioAsset(
    id: 'legacy_async_outcome_scenario',
    name: 'Legacy async outcome producer',
    scope: ScenarioScope.globalStory,
    entryNodeId: 'source',
    declaredOutcomes: <String>['after.dialogue'],
    nodes: <ScenarioNode>[
      ScenarioNode(
        id: 'source',
        type: ScenarioNodeType.reference,
        payload: ScenarioNodePayload(actionKind: kScenarioSourceOutcome),
        binding: ScenarioNodeBinding(outcomeId: 'seed'),
      ),
      ScenarioNode(
        id: 'dialogue',
        type: ScenarioNodeType.dialogue,
        binding: ScenarioNodeBinding(dialogueId: 'legacy_async_dialogue'),
      ),
      ScenarioNode(
        id: 'emit',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(actionKind: kScenarioActionEmitOutcome),
        binding: ScenarioNodeBinding(outcomeId: 'after.dialogue'),
      ),
      ScenarioNode(id: 'end', type: ScenarioNodeType.end),
    ],
    edges: <ScenarioEdge>[
      ScenarioEdge(
        id: 'source_to_dialogue',
        fromNodeId: 'source',
        toNodeId: 'dialogue',
      ),
      ScenarioEdge(
        id: 'dialogue_to_emit',
        fromNodeId: 'dialogue',
        toNodeId: 'emit',
      ),
      ScenarioEdge(id: 'emit_to_end', fromNodeId: 'emit', toNodeId: 'end'),
    ],
  );
}

ScenarioAsset _legacyRawFirstDialogueScenario() {
  return const ScenarioAsset(
    id: 'legacy_raw_first_scenario',
    name: 'Legacy raw first dialogue consumer',
    scope: ScenarioScope.globalStory,
    entryNodeId: 'source',
    nodes: <ScenarioNode>[
      ScenarioNode(
        id: 'source',
        type: ScenarioNodeType.reference,
        payload: ScenarioNodePayload(actionKind: kScenarioSourceOutcome),
        binding: ScenarioNodeBinding(outcomeId: _legacyRawFirstOutcomeId),
      ),
      ScenarioNode(
        id: 'dialogue',
        type: ScenarioNodeType.dialogue,
        binding: ScenarioNodeBinding(dialogueId: 'legacy_raw_first_dialogue'),
      ),
      ScenarioNode(
        id: 'complete',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
        binding: ScenarioNodeBinding(flagName: _legacyRawFirstCompletedFlag),
      ),
      ScenarioNode(id: 'end', type: ScenarioNodeType.end),
    ],
    edges: <ScenarioEdge>[
      ScenarioEdge(
        id: 'source_to_dialogue',
        fromNodeId: 'source',
        toNodeId: 'dialogue',
      ),
      ScenarioEdge(
        id: 'dialogue_to_complete',
        fromNodeId: 'dialogue',
        toNodeId: 'complete',
      ),
      ScenarioEdge(
        id: 'complete_to_end',
        fromNodeId: 'complete',
        toNodeId: 'end',
      ),
    ],
  );
}

ScenarioAsset _legacyRawSecondScenario() {
  return const ScenarioAsset(
    id: 'legacy_raw_second_scenario',
    name: 'Legacy raw second FIFO consumer',
    scope: ScenarioScope.globalStory,
    entryNodeId: 'source',
    nodes: <ScenarioNode>[
      ScenarioNode(
        id: 'source',
        type: ScenarioNodeType.reference,
        payload: ScenarioNodePayload(actionKind: kScenarioSourceOutcome),
        binding: ScenarioNodeBinding(outcomeId: _legacyRawSecondOutcomeId),
      ),
      ScenarioNode(
        id: 'complete',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
        binding: ScenarioNodeBinding(flagName: _legacyRawSecondCompletedFlag),
      ),
      ScenarioNode(id: 'end', type: ScenarioNodeType.end),
    ],
    edges: <ScenarioEdge>[
      ScenarioEdge(
        id: 'source_to_complete',
        fromNodeId: 'source',
        toNodeId: 'complete',
      ),
      ScenarioEdge(
        id: 'complete_to_end',
        fromNodeId: 'complete',
        toNodeId: 'end',
      ),
    ],
  );
}

ScenarioAsset _legacySuspendedProducerScenario() {
  return const ScenarioAsset(
    id: 'legacy_suspended_producer',
    name: 'Legacy suspended producer',
    entryNodeId: 'source',
    declaredOutcomes: <String>[
      'producer.seed',
      'producer.after_dialogue',
    ],
    nodes: <ScenarioNode>[
      ScenarioNode(
        id: 'source',
        type: ScenarioNodeType.reference,
        payload: ScenarioNodePayload(actionKind: kScenarioSourceMapEnter),
        binding: ScenarioNodeBinding(mapId: _mapId),
      ),
      ScenarioNode(
        id: 'emit_seed',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(actionKind: kScenarioActionEmitOutcome),
        binding: ScenarioNodeBinding(outcomeId: 'producer.seed'),
      ),
      ScenarioNode(
        id: 'dialogue',
        type: ScenarioNodeType.dialogue,
        binding: ScenarioNodeBinding(
          dialogueId: 'legacy_suspended_producer_dialogue',
        ),
      ),
      ScenarioNode(
        id: 'emit_after',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(actionKind: kScenarioActionEmitOutcome),
        binding: ScenarioNodeBinding(outcomeId: 'producer.after_dialogue'),
      ),
      ScenarioNode(id: 'end', type: ScenarioNodeType.end),
    ],
    edges: <ScenarioEdge>[
      ScenarioEdge(
        id: 'source_to_seed',
        fromNodeId: 'source',
        toNodeId: 'emit_seed',
      ),
      ScenarioEdge(
        id: 'seed_to_dialogue',
        fromNodeId: 'emit_seed',
        toNodeId: 'dialogue',
      ),
      ScenarioEdge(
        id: 'dialogue_to_after',
        fromNodeId: 'dialogue',
        toNodeId: 'emit_after',
      ),
      ScenarioEdge(
        id: 'after_to_end',
        fromNodeId: 'emit_after',
        toNodeId: 'end',
      ),
    ],
  );
}

ScenarioAsset _legacyMoveWarpScenario() {
  return const ScenarioAsset(
    id: 'legacy_move_warp_scenario',
    name: 'Legacy move-to-warp continuation',
    entryNodeId: 'source',
    nodes: <ScenarioNode>[
      ScenarioNode(
        id: 'source',
        type: ScenarioNodeType.reference,
        payload: ScenarioNodePayload(actionKind: kScenarioSourceMapEnter),
        binding: ScenarioNodeBinding(mapId: _mapId),
      ),
      ScenarioNode(
        id: 'move',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(
          actionKind: kScenarioActionMoveCharacter,
          params: <String, String>{
            'targetKind': 'warp',
            'targetId': 'npc_exit',
            'waitForCompletion': 'true',
          },
        ),
        binding: ScenarioNodeBinding(entityId: 'moving_npc'),
      ),
      ScenarioNode(
        id: 'complete',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
        binding: ScenarioNodeBinding(flagName: _legacyMoveWarpCompletedFlag),
      ),
      ScenarioNode(id: 'end', type: ScenarioNodeType.end),
    ],
    edges: <ScenarioEdge>[
      ScenarioEdge(
        id: 'source_to_move',
        fromNodeId: 'source',
        toNodeId: 'move',
      ),
      ScenarioEdge(
        id: 'move_to_complete',
        fromNodeId: 'move',
        toNodeId: 'complete',
      ),
      ScenarioEdge(
        id: 'complete_to_end',
        fromNodeId: 'complete',
        toNodeId: 'end',
      ),
    ],
  );
}

ScenarioAsset _legacyFollowMoveWarpScenario() {
  return const ScenarioAsset(
    id: 'legacy_follow_move_warp_scenario',
    name: 'Legacy raw follow move-to-warp continuation',
    scope: ScenarioScope.globalStory,
    entryNodeId: 'source',
    declaredOutcomes: <String>[_legacyFollowMoveWarpChildOutcomeId],
    nodes: <ScenarioNode>[
      ScenarioNode(
        id: 'source',
        type: ScenarioNodeType.reference,
        payload: ScenarioNodePayload(actionKind: kScenarioSourceOutcome),
        binding: ScenarioNodeBinding(
          outcomeId: _legacyFollowMoveWarpOutcomeId,
        ),
      ),
      ScenarioNode(
        id: 'follow',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(
          actionKind: kScenarioActionFollowCharacter,
          params: <String, String>{'leaderId': 'moving_npc'},
        ),
      ),
      ScenarioNode(
        id: 'move',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(
          actionKind: kScenarioActionMoveCharacter,
          params: <String, String>{
            'targetKind': 'warp',
            'targetId': 'leader_exit',
            'waitForCompletion': 'true',
          },
        ),
        binding: ScenarioNodeBinding(entityId: 'moving_npc'),
      ),
      ScenarioNode(
        id: 'complete',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
        binding: ScenarioNodeBinding(
          flagName: _legacyFollowMoveWarpCompletedFlag,
        ),
      ),
      ScenarioNode(
        id: 'emit_child',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(actionKind: kScenarioActionEmitOutcome),
        binding: ScenarioNodeBinding(
          outcomeId: _legacyFollowMoveWarpChildOutcomeId,
        ),
      ),
      ScenarioNode(id: 'end', type: ScenarioNodeType.end),
    ],
    edges: <ScenarioEdge>[
      ScenarioEdge(
        id: 'source_to_follow',
        fromNodeId: 'source',
        toNodeId: 'follow',
      ),
      ScenarioEdge(
        id: 'follow_to_move',
        fromNodeId: 'follow',
        toNodeId: 'move',
      ),
      ScenarioEdge(
        id: 'move_to_complete',
        fromNodeId: 'move',
        toNodeId: 'complete',
      ),
      ScenarioEdge(
        id: 'complete_to_child',
        fromNodeId: 'complete',
        toNodeId: 'emit_child',
      ),
      ScenarioEdge(
        id: 'child_to_end',
        fromNodeId: 'emit_child',
        toNodeId: 'end',
      ),
    ],
  );
}

ScenarioAsset _legacyMoveReplacementScenario({
  required String id,
  required String triggerId,
  required String warpId,
  required String completedFlag,
}) {
  return ScenarioAsset(
    id: id,
    name: id,
    scope: ScenarioScope.localEventFlow,
    entryNodeId: 'source',
    nodes: <ScenarioNode>[
      ScenarioNode(
        id: 'source',
        type: ScenarioNodeType.reference,
        payload: const ScenarioNodePayload(
          actionKind: kScenarioSourceTriggerEnter,
        ),
        binding: ScenarioNodeBinding(mapId: _mapId, triggerId: triggerId),
      ),
      ScenarioNode(
        id: 'move',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(
          actionKind: kScenarioActionMoveCharacter,
          params: <String, String>{
            'targetKind': 'warp',
            'targetId': warpId,
            'waitForCompletion': 'true',
          },
        ),
        binding: const ScenarioNodeBinding(entityId: 'moving_npc'),
      ),
      ScenarioNode(
        id: 'complete',
        type: ScenarioNodeType.action,
        payload: const ScenarioNodePayload(
          actionKind: kScenarioActionSetFlag,
        ),
        binding: ScenarioNodeBinding(flagName: completedFlag),
      ),
      const ScenarioNode(id: 'end', type: ScenarioNodeType.end),
    ],
    edges: const <ScenarioEdge>[
      ScenarioEdge(
        id: 'source_to_move',
        fromNodeId: 'source',
        toNodeId: 'move',
      ),
      ScenarioEdge(
        id: 'move_to_complete',
        fromNodeId: 'move',
        toNodeId: 'complete',
      ),
      ScenarioEdge(
        id: 'complete_to_end',
        fromNodeId: 'complete',
        toNodeId: 'end',
      ),
    ],
  );
}

ScenarioAsset _legacyPlayerMoveWarpScenario() {
  return const ScenarioAsset(
    id: 'legacy_player_move_warp_scenario',
    name: 'Legacy player move-to-warp continuation',
    entryNodeId: 'source',
    nodes: <ScenarioNode>[
      ScenarioNode(
        id: 'source',
        type: ScenarioNodeType.reference,
        payload: ScenarioNodePayload(actionKind: kScenarioSourceMapEnter),
        binding: ScenarioNodeBinding(mapId: _mapId),
      ),
      ScenarioNode(
        id: 'move',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(
          actionKind: kScenarioActionMoveCharacter,
          params: <String, String>{
            'targetKind': 'warp',
            'targetId': 'player_exit',
            'waitForCompletion': 'true',
          },
        ),
        binding: ScenarioNodeBinding(entityId: 'player'),
      ),
      ScenarioNode(
        id: 'complete',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
        binding: ScenarioNodeBinding(flagName: _legacyPlayerWarpCompletedFlag),
      ),
      ScenarioNode(id: 'end', type: ScenarioNodeType.end),
    ],
    edges: <ScenarioEdge>[
      ScenarioEdge(
        id: 'source_to_move',
        fromNodeId: 'source',
        toNodeId: 'move',
      ),
      ScenarioEdge(
        id: 'move_to_complete',
        fromNodeId: 'move',
        toNodeId: 'complete',
      ),
      ScenarioEdge(
        id: 'complete_to_end',
        fromNodeId: 'complete',
        toNodeId: 'end',
      ),
    ],
  );
}

ScenarioAsset _legacyOutcomeBattleScenario() {
  return const ScenarioAsset(
    id: 'legacy_outcome_battle_scenario',
    name: 'Legacy outcome-caused Battle producer',
    scope: ScenarioScope.globalStory,
    entryNodeId: 'source',
    declaredOutcomes: <String>['after.battle'],
    nodes: <ScenarioNode>[
      ScenarioNode(
        id: 'source',
        type: ScenarioNodeType.reference,
        payload: ScenarioNodePayload(actionKind: kScenarioSourceOutcome),
        binding: ScenarioNodeBinding(outcomeId: 'seed'),
      ),
      ScenarioNode(
        id: 'battle',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(
          actionKind: kScenarioActionStartTrainerBattle,
          params: <String, String>{
            'battleId': 'legacy_outcome_battle',
          },
        ),
        binding: ScenarioNodeBinding(
          trainerId: _trainerId,
          entityId: 'trainer_npc',
        ),
      ),
      ScenarioNode(
        id: 'emit',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(actionKind: kScenarioActionEmitOutcome),
        binding: ScenarioNodeBinding(outcomeId: 'after.battle'),
      ),
      ScenarioNode(id: 'end', type: ScenarioNodeType.end),
    ],
    edges: <ScenarioEdge>[
      ScenarioEdge(
          id: 'source_to_battle', fromNodeId: 'source', toNodeId: 'battle'),
      ScenarioEdge(
          id: 'battle_to_emit', fromNodeId: 'battle', toNodeId: 'emit'),
      ScenarioEdge(id: 'emit_to_end', fromNodeId: 'emit', toNodeId: 'end'),
    ],
  );
}

ScenarioAsset _legacyScriptWarpScenario() {
  return const ScenarioAsset(
    id: 'legacy_script_warp_scenario',
    name: 'Legacy raw Scenario script warp',
    scope: ScenarioScope.globalStory,
    entryNodeId: 'source',
    nodes: <ScenarioNode>[
      ScenarioNode(
        id: 'source',
        type: ScenarioNodeType.reference,
        payload: ScenarioNodePayload(actionKind: kScenarioSourceOutcome),
        binding: ScenarioNodeBinding(outcomeId: _legacyScriptWarpOutcomeId),
      ),
      ScenarioNode(
        id: 'run_script',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(actionKind: kScenarioActionRunScript),
        binding: ScenarioNodeBinding(scriptId: 'legacy_warp_script'),
      ),
      ScenarioNode(
        id: 'complete',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
        binding: ScenarioNodeBinding(flagName: _legacyScriptWarpCompletedFlag),
      ),
      ScenarioNode(id: 'end', type: ScenarioNodeType.end),
    ],
    edges: <ScenarioEdge>[
      ScenarioEdge(
        id: 'source_to_script',
        fromNodeId: 'source',
        toNodeId: 'run_script',
      ),
      ScenarioEdge(
        id: 'script_to_complete',
        fromNodeId: 'run_script',
        toNodeId: 'complete',
      ),
      ScenarioEdge(
        id: 'complete_to_end',
        fromNodeId: 'complete',
        toNodeId: 'end',
      ),
    ],
  );
}

ScenarioAsset _legacyWarpConflictScenario() {
  return const ScenarioAsset(
    id: 'legacy_warp_conflict_scenario',
    name: 'Legacy Scenario/physical warp conflict',
    scope: ScenarioScope.localEventFlow,
    entryNodeId: 'source',
    nodes: <ScenarioNode>[
      ScenarioNode(
        id: 'source',
        type: ScenarioNodeType.reference,
        payload: ScenarioNodePayload(actionKind: kScenarioSourceTriggerEnter),
        binding: ScenarioNodeBinding(
          mapId: _mapId,
          triggerId: 'warp_conflict_trigger',
        ),
      ),
      ScenarioNode(
        id: 'run_script',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(actionKind: kScenarioActionRunScript),
        binding: ScenarioNodeBinding(scriptId: 'legacy_warp_script'),
      ),
      ScenarioNode(
        id: 'complete',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
        binding: ScenarioNodeBinding(flagName: _legacyScriptWarpCompletedFlag),
      ),
      ScenarioNode(id: 'end', type: ScenarioNodeType.end),
    ],
    edges: <ScenarioEdge>[
      ScenarioEdge(
        id: 'source_to_script',
        fromNodeId: 'source',
        toNodeId: 'run_script',
      ),
      ScenarioEdge(
        id: 'script_to_complete',
        fromNodeId: 'run_script',
        toNodeId: 'complete',
      ),
      ScenarioEdge(
        id: 'complete_to_end',
        fromNodeId: 'complete',
        toNodeId: 'end',
      ),
    ],
  );
}

ScenarioAsset _legacyIndependentTransitionScenario() {
  return const ScenarioAsset(
    id: 'legacy_independent_transition',
    name: 'Legacy independent transition owner',
    scope: ScenarioScope.localEventFlow,
    entryNodeId: 'source',
    nodes: <ScenarioNode>[
      ScenarioNode(
        id: 'source',
        type: ScenarioNodeType.reference,
        payload: ScenarioNodePayload(actionKind: kScenarioSourceTriggerEnter),
        binding: ScenarioNodeBinding(
          mapId: _mapId,
          triggerId: 'a_transition_owner',
        ),
      ),
      ScenarioNode(
        id: 'transition',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(actionKind: kScenarioActionTransitionMap),
        binding: ScenarioNodeBinding(
          mapId: _legacyTransitionTargetMapId,
          warpId: 'arrival',
        ),
      ),
      ScenarioNode(id: 'end', type: ScenarioNodeType.end),
    ],
    edges: <ScenarioEdge>[
      ScenarioEdge(
        id: 'source_to_transition',
        fromNodeId: 'source',
        toNodeId: 'transition',
      ),
      ScenarioEdge(
        id: 'transition_to_end',
        fromNodeId: 'transition',
        toNodeId: 'end',
      ),
    ],
  );
}

ScenarioAsset _legacyRejectedTransitionScenario() {
  return const ScenarioAsset(
    id: 'legacy_rejected_transition',
    name: 'Legacy rejected concurrent transition',
    scope: ScenarioScope.localEventFlow,
    entryNodeId: 'source',
    nodes: <ScenarioNode>[
      ScenarioNode(
        id: 'source',
        type: ScenarioNodeType.reference,
        payload: ScenarioNodePayload(actionKind: kScenarioSourceTriggerEnter),
        binding: ScenarioNodeBinding(
          mapId: _mapId,
          triggerId: 'c_transition_rejected',
        ),
      ),
      ScenarioNode(
        id: 'transition',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(actionKind: kScenarioActionTransitionMap),
        binding: ScenarioNodeBinding(
          mapId: _legacyPhysicalWarpTargetMapId,
          warpId: 'never_adopted',
        ),
      ),
      ScenarioNode(id: 'end', type: ScenarioNodeType.end),
    ],
    edges: <ScenarioEdge>[
      ScenarioEdge(
        id: 'source_to_transition',
        fromNodeId: 'source',
        toNodeId: 'transition',
      ),
      ScenarioEdge(
        id: 'transition_to_end',
        fromNodeId: 'transition',
        toNodeId: 'end',
      ),
    ],
  );
}

ProjectScriptEntry _legacyWarpScript() {
  return const ProjectScriptEntry(
    id: 'legacy_warp_script',
    name: 'Legacy Warp Script',
    asset: ScriptAsset(
      id: 'legacy_warp_script',
      defaultStartNode: 'start',
      nodes: <ScriptNode>[
        ScriptNode(
          id: 'start',
          commands: <ScriptCommand>[
            ScriptCommand(
              type: ScriptCommandType.warpPlayer,
              params: <String, String>{
                'mapId': _legacyScriptWarpTargetMapId,
                'x': '1',
                'y': '1',
                'facing': 'south',
              },
            ),
            ScriptCommand(type: ScriptCommandType.end),
          ],
        ),
      ],
    ),
  );
}

ScenarioAsset _legacyScriptFailureScenario() {
  return const ScenarioAsset(
    id: 'legacy_script_failure_scenario',
    name: 'Legacy raw Scenario script failure',
    scope: ScenarioScope.globalStory,
    entryNodeId: 'source',
    nodes: <ScenarioNode>[
      ScenarioNode(
        id: 'source',
        type: ScenarioNodeType.reference,
        payload: ScenarioNodePayload(actionKind: kScenarioSourceOutcome),
        binding: ScenarioNodeBinding(outcomeId: _legacyScriptFailureOutcomeId),
      ),
      ScenarioNode(
        id: 'run_script',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(actionKind: kScenarioActionRunScript),
        binding: ScenarioNodeBinding(scriptId: 'legacy_failure_script'),
      ),
      ScenarioNode(
        id: 'complete',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
        binding: ScenarioNodeBinding(
          flagName: _legacyScriptFailureCompletedFlag,
        ),
      ),
      ScenarioNode(id: 'end', type: ScenarioNodeType.end),
    ],
    edges: <ScenarioEdge>[
      ScenarioEdge(
        id: 'source_to_script',
        fromNodeId: 'source',
        toNodeId: 'run_script',
      ),
      ScenarioEdge(
        id: 'script_to_complete',
        fromNodeId: 'run_script',
        toNodeId: 'complete',
      ),
      ScenarioEdge(
        id: 'complete_to_end',
        fromNodeId: 'complete',
        toNodeId: 'end',
      ),
    ],
  );
}

ProjectScriptEntry _legacyFailureScript({required bool throwsFromCommand}) {
  final failingCommand = throwsFromCommand
      ? const ScriptCommand(
          type: ScriptCommandType.setVariable,
          params: <String, String>{
            'variableName': 'legacy.script.failure',
            'value': 'not-an-int',
            'type': 'int',
          },
        )
      : const ScriptCommand(type: ScriptCommandType.setFlag);
  return ProjectScriptEntry(
    id: 'legacy_failure_script',
    name: 'Legacy Failure Script',
    asset: ScriptAsset(
      id: 'legacy_failure_script',
      defaultStartNode: 'start',
      nodes: <ScriptNode>[
        ScriptNode(
          id: 'start',
          commands: <ScriptCommand>[
            const ScriptCommand(
              type: ScriptCommandType.openDialogue,
              params: <String, String>{
                'filePath': 'dialogues/script_failure.yarn',
              },
            ),
            failingCommand,
            const ScriptCommand(type: ScriptCommandType.end),
          ],
        ),
      ],
    ),
  );
}

ProjectScriptEntry _legacyImmediateFailureScript({
  required bool throwsFromCommand,
}) {
  final failingCommand = throwsFromCommand
      ? const ScriptCommand(
          type: ScriptCommandType.setVariable,
          params: <String, String>{
            'variableName': 'legacy.script.failure',
            'value': 'not-an-int',
            'type': 'int',
          },
        )
      : const ScriptCommand(type: ScriptCommandType.setFlag);
  return ProjectScriptEntry(
    id: 'legacy_failure_script',
    name: 'Legacy Immediate Failure Script',
    asset: ScriptAsset(
      id: 'legacy_failure_script',
      defaultStartNode: 'start',
      nodes: <ScriptNode>[
        ScriptNode(
          id: 'start',
          commands: <ScriptCommand>[
            failingCommand,
            const ScriptCommand(type: ScriptCommandType.end),
          ],
        ),
      ],
    ),
  );
}

ProjectScriptEntry _legacySynchronousScript({
  required String scriptBehavior,
}) {
  final firstCommand = switch (scriptBehavior) {
    'end' => const ScriptCommand(type: ScriptCommandType.end),
    'error' => const ScriptCommand(type: ScriptCommandType.setFlag),
    'exception' => const ScriptCommand(
        type: ScriptCommandType.setVariable,
        params: <String, String>{
          'variableName': 'legacy.script.failure',
          'value': 'not-an-int',
          'type': 'int',
        },
      ),
    _ => throw ArgumentError.value(scriptBehavior, 'scriptBehavior'),
  };
  return ProjectScriptEntry(
    id: 'legacy_chain_script',
    name: 'Legacy Synchronous Chain Script',
    asset: ScriptAsset(
      id: 'legacy_chain_script',
      defaultStartNode: 'start',
      nodes: <ScriptNode>[
        ScriptNode(
          id: 'start',
          commands: <ScriptCommand>[firstCommand],
        ),
      ],
    ),
  );
}

ScenarioAsset _legacyDialogueThenScriptScenario() {
  return const ScenarioAsset(
    id: 'legacy_dialogue_then_script_scenario',
    name: 'Legacy dialogue then synchronous script',
    scope: ScenarioScope.globalStory,
    entryNodeId: 'source',
    nodes: <ScenarioNode>[
      ScenarioNode(
        id: 'source',
        type: ScenarioNodeType.reference,
        payload: ScenarioNodePayload(actionKind: kScenarioSourceOutcome),
        binding: ScenarioNodeBinding(outcomeId: _legacyScriptFailureOutcomeId),
      ),
      ScenarioNode(
        id: 'first_dialogue',
        type: ScenarioNodeType.dialogue,
        binding: ScenarioNodeBinding(
          dialogueId: 'legacy_chain_first_dialogue',
        ),
      ),
      ScenarioNode(
        id: 'run_script',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(actionKind: kScenarioActionRunScript),
        binding: ScenarioNodeBinding(scriptId: 'legacy_chain_script'),
      ),
      ScenarioNode(
        id: 'complete',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
        binding:
            ScenarioNodeBinding(flagName: _legacyChainedEffectCompletedFlag),
      ),
      ScenarioNode(id: 'end', type: ScenarioNodeType.end),
    ],
    edges: <ScenarioEdge>[
      ScenarioEdge(
        id: 'source_to_dialogue',
        fromNodeId: 'source',
        toNodeId: 'first_dialogue',
      ),
      ScenarioEdge(
        id: 'dialogue_to_script',
        fromNodeId: 'first_dialogue',
        toNodeId: 'run_script',
      ),
      ScenarioEdge(
        id: 'script_to_complete',
        fromNodeId: 'run_script',
        toNodeId: 'complete',
      ),
      ScenarioEdge(
        id: 'complete_to_end',
        fromNodeId: 'complete',
        toNodeId: 'end',
      ),
    ],
  );
}

ScenarioAsset _legacyDialogueThenDialogueScenario() {
  return const ScenarioAsset(
    id: 'legacy_dialogue_then_dialogue_scenario',
    name: 'Legacy dialogue then failing dialogue',
    scope: ScenarioScope.globalStory,
    entryNodeId: 'source',
    nodes: <ScenarioNode>[
      ScenarioNode(
        id: 'source',
        type: ScenarioNodeType.reference,
        payload: ScenarioNodePayload(actionKind: kScenarioSourceOutcome),
        binding: ScenarioNodeBinding(outcomeId: _legacyScriptFailureOutcomeId),
      ),
      ScenarioNode(
        id: 'first_dialogue',
        type: ScenarioNodeType.dialogue,
        binding: ScenarioNodeBinding(
          dialogueId: 'legacy_chain_first_dialogue',
        ),
      ),
      ScenarioNode(
        id: 'second_dialogue',
        type: ScenarioNodeType.dialogue,
        binding: ScenarioNodeBinding(
          dialogueId: 'legacy_chain_second_dialogue',
        ),
      ),
      ScenarioNode(
        id: 'complete',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
        binding:
            ScenarioNodeBinding(flagName: _legacyChainedEffectCompletedFlag),
      ),
      ScenarioNode(id: 'end', type: ScenarioNodeType.end),
    ],
    edges: <ScenarioEdge>[
      ScenarioEdge(
        id: 'source_to_first_dialogue',
        fromNodeId: 'source',
        toNodeId: 'first_dialogue',
      ),
      ScenarioEdge(
        id: 'first_to_second_dialogue',
        fromNodeId: 'first_dialogue',
        toNodeId: 'second_dialogue',
      ),
      ScenarioEdge(
        id: 'second_dialogue_to_complete',
        fromNodeId: 'second_dialogue',
        toNodeId: 'complete',
      ),
      ScenarioEdge(
        id: 'complete_to_end',
        fromNodeId: 'complete',
        toNodeId: 'end',
      ),
    ],
  );
}

ScenarioAsset _legacyInvalidBattleScenario() {
  return const ScenarioAsset(
    id: 'legacy_invalid_battle_scenario',
    name: 'Legacy invalid Battle handoff',
    scope: ScenarioScope.globalStory,
    entryNodeId: 'source',
    nodes: <ScenarioNode>[
      ScenarioNode(
        id: 'source',
        type: ScenarioNodeType.reference,
        payload: ScenarioNodePayload(actionKind: kScenarioSourceOutcome),
        binding: ScenarioNodeBinding(outcomeId: _legacyInvalidBattleOutcomeId),
      ),
      ScenarioNode(
        id: 'battle',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(
          actionKind: kScenarioActionStartTrainerBattle,
          params: <String, String>{'battleId': 'invalid_battle'},
        ),
        binding: ScenarioNodeBinding(
          trainerId: _trainerId,
          entityId: 'missing_trainer_npc',
        ),
      ),
      ScenarioNode(id: 'end', type: ScenarioNodeType.end),
    ],
    edges: <ScenarioEdge>[
      ScenarioEdge(
        id: 'source_to_battle',
        fromNodeId: 'source',
        toNodeId: 'battle',
      ),
      ScenarioEdge(
        id: 'battle_to_end',
        fromNodeId: 'battle',
        toNodeId: 'end',
      ),
    ],
  );
}

ScenarioAsset _legacyAsyncSeedScenario() {
  return const ScenarioAsset(
    id: 'legacy_async_seed_scenario',
    name: 'Legacy async seed producer',
    entryNodeId: 'source',
    declaredOutcomes: <String>['seed'],
    nodes: <ScenarioNode>[
      ScenarioNode(
        id: 'source',
        type: ScenarioNodeType.reference,
        payload: ScenarioNodePayload(actionKind: kScenarioSourceMapEnter),
        binding: ScenarioNodeBinding(mapId: _mapId),
      ),
      ScenarioNode(
        id: 'emit',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(actionKind: kScenarioActionEmitOutcome),
        binding: ScenarioNodeBinding(outcomeId: 'seed'),
      ),
      ScenarioNode(id: 'end', type: ScenarioNodeType.end),
    ],
    edges: <ScenarioEdge>[
      ScenarioEdge(
        id: 'source_to_emit',
        fromNodeId: 'source',
        toNodeId: 'emit',
      ),
      ScenarioEdge(id: 'emit_to_end', fromNodeId: 'emit', toNodeId: 'end'),
    ],
  );
}

DialogueSession _singleLineDialogueSession() {
  return DialogueSession.start(
    <YarnNode>[
      YarnNode(
        title: 'Start',
        steps: <YarnStep>[YarnStepLine('Continuer.')],
      ),
    ],
    'Start',
  )!;
}

NarrativeOutcomeDelivery _rawLegacyDelivery({
  required String deliveryId,
  required String outcomeId,
}) {
  return NarrativeOutcomeDelivery(
    deliveryId: deliveryId,
    outcome: NarrativeOutcomeRef(
      producerKind: NarrativeOutcomeProducerKind.legacyScenario,
      producerId: 'raw_restore_fixture',
      outcomeId: outcomeId,
    ),
    rootCorrelationId: _legacyRawRootCorrelationId,
    depth: 0,
    attemptCount: 0,
  );
}

RuntimeActiveBattleContext _trainerContext() {
  return const RuntimeActiveBattleContext(
    request: TrainerBattleStartRequest(
      requestId: 'qualified-outcome-trainer-request',
      createdAtEpochMs: 1,
      returnContext: OverworldReturnContext(
        mapId: _mapId,
        playerPos: GridPos(x: 1, y: 1),
        playerFacing: Direction.south,
      ),
      trainerId: _trainerId,
      npcEntityId: 'trainer_npc',
      mapId: _mapId,
      playerPos: GridPos(x: 1, y: 1),
    ),
    playerPartyIndex: 0,
  );
}

BattleOutcome _victoryOutcome({required int playerCurrentHp}) {
  return BattleOutcome(
    type: BattleOutcomeType.victory,
    finalState: BattleState(
      phase: BattlePhase.finished,
      player: BattleCombatant(
        speciesId: 'sproutle',
        level: 5,
        currentHp: playerCurrentHp,
        maxHp: 20,
        stats: _battleStats,
        moves: const <BattleMove>[
          BattleMove(id: 'tackle', name: 'Tackle', power: 10),
        ],
      ),
      enemy: const BattleCombatant(
        speciesId: 'embercub',
        level: 5,
        currentHp: 0,
        maxHp: 18,
        stats: _battleStats,
        moves: <BattleMove>[
          BattleMove(id: 'scratch', name: 'Scratch', power: 10),
        ],
      ),
      currentTurn: null,
      outcome: null,
    ),
  );
}

final class _CheckpointCountingRepository implements GameSaveRepository {
  _CheckpointCountingRepository(this.gate);

  final NarrativeRuntimeActivityGate gate;
  GameState? storedState;
  int saveCount = 0;
  int loadCount = 0;

  @override
  Future<void> save(GameState state) {
    return gate.runCheckpoint(
      NarrativeRuntimeCheckpointOperation.save,
      () async {
        saveCount++;
        storedState = state;
      },
    );
  }

  @override
  Future<GameState?> load() {
    return gate.runCheckpoint(
      NarrativeRuntimeCheckpointOperation.load,
      () async {
        loadCount++;
        return storedState;
      },
    );
  }

  @override
  Future<bool> exists() async => storedState != null;

  @override
  Future<void> delete() async {
    storedState = null;
  }
}
~~~~~~~~

### 25.19 `packages/map_runtime/test/playable_map_game_save_restore_outbox_integration_test.dart`

~~~~~~~~dart
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

const _mapId = 'save_restore_outbox_map';

const _outcomeOneProducerSceneId = 'scene_restore_producer_one';
const _outcomeTwoProducerSceneId = 'scene_restore_producer_two';
const _outcomeOneId = 'restore_outcome_one';
const _outcomeTwoId = 'restore_outcome_two';

const _outcomeOneEventId = 'evt_019abcde-3000-7000-8000-000000000001';
const _outcomeTwoEventId = 'evt_019abcde-3000-7000-8000-000000000002';
const _mapEnterEventId = 'evt_019abcde-3000-7000-8000-000000000003';

const _outcomeOneConsumerSceneId = 'scene_restore_sets_fact_a';
const _outcomeTwoConsumerSceneId = 'scene_restore_sets_fact_b';
const _mapEnterConsumerSceneId = 'scene_restore_sets_fact_c';

const _factA = 'fact.restore.outcome_one_processed';
const _factB = 'fact.restore.outcome_two_processed_after_a';
const _factC = 'fact.restore.map_enter_processed_after_b';

const _deliveryOneId = 'outd_019abcde-3000-7000-8000-000000000011';
const _deliveryTwoId = 'outd_019abcde-3000-7000-8000-000000000012';
const _causationExecutionId = 'evx_019abcde-3000-7000-8000-000000000013';
const _rootCorrelationId = 'corr_019abcde-3000-7000-8000-000000000014';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('saveRestore drains pending outcomes FIFO before mapEnter', () async {
    final project = _project();
    final game = PlayableMapGame(
      bundle: RuntimeMapBundle(
        manifest: project,
        map: _map(),
        projectRootDirectory: '/tmp/save_restore_outbox',
        tilesetAbsolutePathsById: const <String, String>{},
      ),
      projectFilePath: '/tmp/save_restore_outbox/project.json',
      saveData: SaveData(
        saveId: 'save-restore-outbox',
        currentMapId: _mapId,
        playerPosition: const GridPos(x: 1, y: 1),
        narrativeEventProgress: NarrativeEventProgress(
          pendingNarrativeOutcomeDeliveries: <NarrativeOutcomeDelivery>[
            _delivery(
              deliveryId: _deliveryOneId,
              outcome: _outcomeOne,
            ),
            _delivery(
              deliveryId: _deliveryTwoId,
              outcome: _outcomeTwo,
            ),
          ],
        ),
      ),
      initialMapActivationReason: MapActivationReason.saveRestore,
    );

    game.onGameResize(Vector2(320, 240));
    await game.onLoad();
    await _waitForActivationDispatch(game);

    final state = game.gameStateSnapshot;
    expect(
      state.narrativeFactRuntimeState.overridesByFactId,
      containsPair(_factA, true),
      reason: 'The FIFO head must execute the first outcome Event.',
    );
    expect(
      state.narrativeFactRuntimeState.overridesByFactId,
      containsPair(_factB, true),
      reason: 'The second outcome is eligible only after fact A is committed.',
    );
    expect(
      state.narrativeFactRuntimeState.overridesByFactId,
      containsPair(_factC, true),
      reason: 'mapEnter is eligible only after fact B is committed.',
    );
    expect(
      state.narrativeEventProgress.pendingNarrativeOutcomeDeliveries,
      isEmpty,
    );
    expect(
      state.narrativeEventProgress.deliveredNarrativeOutcomeDeliveryIds,
      {_deliveryOneId, _deliveryTwoId},
    );
    expect(game.debugCompletedMapActivationDispatchCount, 1);
    expect(
      game.debugLastCompletedMapActivation?.reason,
      MapActivationReason.saveRestore,
    );
  });
}

Future<void> _waitForActivationDispatch(PlayableMapGame game) async {
  for (var i = 0; i < 240; i++) {
    if (!game.debugIsMapActivationDispatchInFlight) {
      return;
    }
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
  }
  fail('Timed out waiting for the saveRestore outbox dispatch.');
}

final NarrativeOutcomeRef _outcomeOne = NarrativeOutcomeRef(
  producerKind: NarrativeOutcomeProducerKind.scene,
  producerId: _outcomeOneProducerSceneId,
  outcomeId: _outcomeOneId,
);

final NarrativeOutcomeRef _outcomeTwo = NarrativeOutcomeRef(
  producerKind: NarrativeOutcomeProducerKind.scene,
  producerId: _outcomeTwoProducerSceneId,
  outcomeId: _outcomeTwoId,
);

ProjectManifest _project() {
  final registry = NarrativeEventRegistry(
    schemaVersion: 1,
    mode: EventSystemMode.v2Only,
    records: <NarrativeEventRecord>[
      _eventRecord(
        id: _outcomeOneEventId,
        name: 'Restore outcome one',
        source: NarrativeEventSourceRef.outcomeReceived(_outcomeOne),
        sceneId: _outcomeOneConsumerSceneId,
      ),
      _eventRecord(
        id: _outcomeTwoEventId,
        name: 'Restore outcome two after A',
        source: NarrativeEventSourceRef.outcomeReceived(_outcomeTwo),
        conditions: <NarrativeEventCondition>[
          NarrativeEventCondition.fact(_factA, true),
        ],
        sceneId: _outcomeTwoConsumerSceneId,
      ),
      _eventRecord(
        id: _mapEnterEventId,
        name: 'Map enter after restored outcomes',
        source: NarrativeEventSourceRef.mapEnter(_mapId),
        conditions: <NarrativeEventCondition>[
          NarrativeEventCondition.fact(_factB, true),
        ],
        sceneId: _mapEnterConsumerSceneId,
      ),
    ],
    legacyClaims: const <LegacySourceClaim>[],
  );

  return ProjectManifest(
    name: 'Save restore outbox integration',
    maps: const <ProjectMapEntry>[
      ProjectMapEntry(
        id: _mapId,
        name: 'Save Restore Outbox Map',
        relativePath: 'maps/save_restore_outbox_map.json',
      ),
    ],
    tilesets: const <ProjectTilesetEntry>[],
    facts: <NarrativeFactDefinition>[
      NarrativeFactDefinition(id: _factA, label: 'Outcome one processed'),
      NarrativeFactDefinition(id: _factB, label: 'Outcome two processed'),
      NarrativeFactDefinition(id: _factC, label: 'Map enter processed'),
    ],
    eventRegistry: registry,
    scenes: <SceneAsset>[
      _outcomeProducerScene(
        id: _outcomeOneProducerSceneId,
        outcomeId: _outcomeOneId,
      ),
      _outcomeProducerScene(
        id: _outcomeTwoProducerSceneId,
        outcomeId: _outcomeTwoId,
      ),
      _factScene(id: _outcomeOneConsumerSceneId, factId: _factA),
      _factScene(id: _outcomeTwoConsumerSceneId, factId: _factB),
      _factScene(id: _mapEnterConsumerSceneId, factId: _factC),
    ],
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
  );
}

NarrativeEventRecord _eventRecord({
  required String id,
  required String name,
  required NarrativeEventSourceRef source,
  required String sceneId,
  List<NarrativeEventCondition> conditions = const <NarrativeEventCondition>[],
}) {
  return NarrativeEventRecord.configuredStructurallyUnchecked(
    NarrativeEventDefinition(
      id: id,
      name: name,
      source: source,
      conditions: conditions,
      sceneId: sceneId,
      reusePolicy: NarrativeEventReusePolicy.reusable,
      priority: 0,
      order: 0,
    ),
    enabled: true,
  );
}

SceneAsset _outcomeProducerScene({
  required String id,
  required String outcomeId,
}) {
  return SceneAsset(
    id: id,
    name: 'Outcome producer $outcomeId',
    declaredOutcomes: <SceneOutcome>[
      SceneOutcome(id: outcomeId, label: outcomeId),
    ],
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: <SceneNode>[
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'end',
          kind: SceneNodeKind.end,
          payload: SceneEndPayload(sceneOutcomeId: outcomeId),
        ),
      ],
      edges: <SceneEdge>[
        SceneEdge(
          id: 'start_to_end',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.defaultFlow,
        ),
      ],
    ),
  );
}

SceneAsset _factScene({required String id, required String factId}) {
  return SceneAsset(
    id: id,
    name: 'Set $factId',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: <SceneNode>[
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'set_fact',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.setFact(factId: factId, value: true),
          ),
        ),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ],
      edges: <SceneEdge>[
        SceneEdge(
          id: 'start_to_fact',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'set_fact',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'fact_to_end',
          fromNodeId: 'set_fact',
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.actionCompleted,
        ),
      ],
    ),
  );
}

NarrativeOutcomeDelivery _delivery({
  required String deliveryId,
  required NarrativeOutcomeRef outcome,
}) {
  return NarrativeOutcomeDelivery(
    deliveryId: deliveryId,
    outcome: outcome,
    causationExecutionId: _causationExecutionId,
    rootCorrelationId: _rootCorrelationId,
    depth: 0,
    attemptCount: 0,
  );
}

MapData _map() => const MapData(
      id: _mapId,
      name: 'Save Restore Outbox Map',
      size: GridSize(width: 3, height: 3),
      layers: <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: <MapEntity>[
        MapEntity(
          id: 'spawn',
          name: 'Spawn',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 1, y: 1),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.south,
          ),
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: 'spawn'),
    );
~~~~~~~~

### 25.20 `packages/map_runtime/test/playable_map_game_trigger_enter_v2_integration_test.dart`

~~~~~~~~dart
import 'dart:async';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/dialogue_runtime_models.dart';
import 'package:map_runtime/src/application/narrative_runtime_activity_gate.dart';
import 'package:map_runtime/src/presentation/flame/playable_map_game.dart'
    show RuntimeDialogueSessionLoader;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NS-EVENT-V2-21 PlayableMapGame triggerEnter integration', () {
    test('routes event and custom trigger fronts through Event V2', () async {
      const mapId = 'trigger_enter_positive_map';
      const eventTriggerId = 'trigger_event';
      const customTriggerId = 'trigger_custom';
      const eventId = 'evt_019abcde-3000-7000-8000-000000000001';
      const customEventId = 'evt_019abcde-3000-7000-8000-000000000002';
      const eventSceneId = 'scene_trigger_event';
      const customSceneId = 'scene_trigger_custom';
      const eventFactId = 'fact.trigger_enter.event';
      const customFactId = 'fact.trigger_enter.custom';
      final eventSource = NarrativeEventSourceRef.triggerEnter(
        mapId,
        eventTriggerId,
      );
      final customSource = NarrativeEventSourceRef.triggerEnter(
        mapId,
        customTriggerId,
      );
      final preparedSources = <NarrativeEventSourceRef>[];
      final game = await _loadGame(
        _bundle(
          mapId: mapId,
          triggers: const <MapTrigger>[
            MapTrigger(
              id: eventTriggerId,
              name: 'Event trigger',
              type: TriggerType.event,
              area: MapRect(
                pos: GridPos(x: 1, y: 1),
                size: GridSize(width: 1, height: 1),
              ),
            ),
            MapTrigger(
              id: customTriggerId,
              name: 'Custom trigger',
              type: TriggerType.custom,
              area: MapRect(
                pos: GridPos(x: 2, y: 1),
                size: GridSize(width: 1, height: 1),
              ),
            ),
          ],
          factIds: const <String>[eventFactId, customFactId],
          records: <NarrativeEventRecord>[
            _record(
              id: eventId,
              name: 'Event trigger Event V2',
              source: eventSource,
              sceneId: eventSceneId,
            ),
            _record(
              id: customEventId,
              name: 'Custom trigger Event V2',
              source: customSource,
              sceneId: customSceneId,
            ),
          ],
          scenes: <SceneAsset>[
            _factScene(sceneId: eventSceneId, factId: eventFactId),
            _factScene(sceneId: customSceneId, factId: customFactId),
          ],
        ),
        beforeNarrativeAuthorityPreparation: (occurrence) async {
          if (occurrence.source == eventSource ||
              occurrence.source == customSource) {
            preparedSources.add(occurrence.source);
          }
        },
      );

      await _runSingleMove(game, RuntimeInputControl.right);
      await _pumpUntil(
        game,
        () => _factValue(game, eventFactId) == true,
      );

      expect(_factValue(game, eventFactId), isTrue);
      expect(_factValue(game, customFactId), isNot(isTrue));

      await _runSingleMove(game, RuntimeInputControl.right);
      await _pumpUntil(
        game,
        () => _factValue(game, customFactId) == true,
      );

      expect(preparedSources, <NarrativeEventSourceRef>[
        eventSource,
        customSource,
      ]);
      expect(
        game.gameStateSnapshot.narrativeEventProgress.consumedNarrativeEventIds,
        containsAll(<String>[eventId, customEventId]),
      );
    });

    test(
      'retains a queued trigger occurrence while a checkpoint owns the gate',
      () async {
        const mapId = 'trigger_enter_checkpoint_map';
        const triggerId = 'trigger_checkpoint';
        const eventId = 'evt_019abcde-3000-7000-8000-000000000008';
        const sceneId = 'scene_trigger_checkpoint';
        const factId = 'fact.trigger_enter.checkpoint';
        final source = NarrativeEventSourceRef.triggerEnter(mapId, triggerId);
        final gate = NarrativeRuntimeActivityGate();
        var preparationCount = 0;
        final game = await _loadGame(
          _bundle(
            mapId: mapId,
            triggers: const <MapTrigger>[
              MapTrigger(
                id: triggerId,
                name: 'Checkpoint event trigger',
                type: TriggerType.event,
                area: MapRect(
                  pos: GridPos(x: 1, y: 1),
                  size: GridSize(width: 1, height: 1),
                ),
              ),
            ],
            factIds: const <String>[factId],
            records: <NarrativeEventRecord>[
              _record(
                id: eventId,
                name: 'Checkpoint-retained trigger Event',
                source: source,
                sceneId: sceneId,
              ),
            ],
            scenes: <SceneAsset>[
              _factScene(sceneId: sceneId, factId: factId),
            ],
          ),
          narrativeRuntimeActivityGate: gate,
          beforeNarrativeAuthorityPreparation: (occurrence) async {
            if (occurrence.source == source) {
              preparationCount++;
            }
          },
        );

        expect(
          game.handleRuntimeInputEvent(
            const RuntimeInputEvent.press(RuntimeInputControl.right),
          ),
          isTrue,
        );
        game.update(0.016);
        expect(
          game.handleRuntimeInputEvent(
            const RuntimeInputEvent.release(RuntimeInputControl.right),
          ),
          isTrue,
        );
        expect(game.debugPlayerGridPosition, const GridPos(x: 1, y: 1));
        expect(game.debugPendingNarrativeTriggerEntryCount, 1);

        final checkpointStarted = Completer<void>();
        final releaseCheckpoint = Completer<void>();
        final checkpoint = gate.runCheckpoint<void>(
          NarrativeRuntimeCheckpointOperation.save,
          () async {
            checkpointStarted.complete();
            await releaseCheckpoint.future;
          },
        );
        await checkpointStarted.future;

        await _pumpFrames(game, 30);

        expect(gate.checkpointInProgress, isTrue);
        expect(game.debugPendingNarrativeTriggerEntryCount, 1);
        expect(game.debugIsNarrativeSpatialDispatchInFlight, isFalse);
        expect(preparationCount, 0);
        expect(_factValue(game, factId), isNot(isTrue));

        releaseCheckpoint.complete();
        await checkpoint;
        await _pumpUntil(game, () => _factValue(game, factId) == true);
        await _pumpFrames(game, 4);

        expect(preparationCount, 1);
        expect(game.debugPendingNarrativeTriggerEntryCount, 0);
        expect(
          game.gameStateSnapshot.narrativeEventProgress
              .consumedNarrativeEventIds
              .where((id) => id == eventId),
          hasLength(1),
        );
      },
    );

    test(
      'pending warp blocks save and waits for an active checkpoint to finish',
      () async {
        const mapId = 'pending_warp_checkpoint_map';
        final gate = NarrativeRuntimeActivityGate();
        final repository = _CheckpointCountingRepository(gate);
        final game = await _loadGame(
          _bundle(
            mapId: mapId,
            triggers: const <MapTrigger>[],
            warps: const <MapWarp>[
              MapWarp(
                id: 'checkpoint_warp',
                pos: GridPos(x: 1, y: 1),
                targetMapId: mapId,
                targetPos: GridPos(x: 3, y: 1),
                triggerMode: MapWarpTriggerMode.onEnter,
              ),
            ],
            scenes: const <SceneAsset>[],
          ),
          narrativeRuntimeActivityGate: gate,
          saveRepository: repository,
        );

        expect(
          game.handleRuntimeInputEvent(
            const RuntimeInputEvent.press(RuntimeInputControl.right),
          ),
          isTrue,
        );
        game.update(0.016);
        expect(
          game.handleRuntimeInputEvent(
            const RuntimeInputEvent.release(RuntimeInputControl.right),
          ),
          isTrue,
        );
        expect(game.debugPlayerGridPosition, const GridPos(x: 1, y: 1));
        expect(game.debugHasPendingMapTransition, isTrue);

        expect(await game.saveGame(), isFalse);
        expect(repository.saveCount, 0);

        final checkpointStarted = Completer<void>();
        final releaseCheckpoint = Completer<void>();
        final checkpoint = gate.runCheckpoint<void>(
          NarrativeRuntimeCheckpointOperation.save,
          () async {
            checkpointStarted.complete();
            await releaseCheckpoint.future;
          },
        );
        await checkpointStarted.future;

        await _pumpFrames(game, 30);

        expect(game.debugPlayerGridPosition, const GridPos(x: 1, y: 1));
        expect(game.debugHasPendingMapTransition, isTrue);
        expect(game.debugFlowPhaseName, 'overworld');

        releaseCheckpoint.complete();
        await checkpoint;
        await _pumpUntil(
          game,
          () =>
              game.debugPlayerGridPosition == const GridPos(x: 3, y: 1) &&
              !game.debugHasPendingMapTransition &&
              game.debugFlowPhaseName == 'overworld' &&
              !game.debugIsMapActivationDispatchInFlight,
        );

        expect(repository.saveCount, 0);
        expect(game.debugFlowPhaseName, 'overworld');
      },
    );

    test('does not emit triggerEnter for a system trigger kind', () async {
      const mapId = 'trigger_enter_system_excluded_map';
      const triggerId = 'trigger_camera_system';
      final excludedSource = NarrativeEventSourceRef.triggerEnter(
        mapId,
        triggerId,
      );
      final preparedSources = <NarrativeEventSourceRef>[];
      final game = await _loadGame(
        _bundle(
          mapId: mapId,
          triggers: const <MapTrigger>[
            MapTrigger(
              id: triggerId,
              name: 'System camera trigger',
              type: TriggerType.camera,
              area: MapRect(
                pos: GridPos(x: 1, y: 1),
                size: GridSize(width: 1, height: 1),
              ),
            ),
          ],
          records: const <NarrativeEventRecord>[],
          scenes: const <SceneAsset>[],
        ),
        beforeNarrativeAuthorityPreparation: (occurrence) async {
          preparedSources.add(occurrence.source);
        },
      );
      preparedSources.clear();

      await _runSingleMove(game, RuntimeInputControl.right);
      await _pumpFrames(game, 8);

      expect(game.debugPlayerGridPosition, const GridPos(x: 1, y: 1));
      expect(preparedSources, isNot(contains(excludedSource)));
      expect(preparedSources, isEmpty);
    });

    test('spawn inside is silent and exit then re-entry rearms the trigger',
        () async {
      const mapId = 'trigger_enter_rearm_map';
      const triggerId = 'trigger_spawn_area';
      const eventId = 'evt_019abcde-3000-7000-8000-000000000003';
      const sceneId = 'scene_trigger_rearm';
      const factId = 'fact.trigger_enter.rearmed';
      final source = NarrativeEventSourceRef.triggerEnter(mapId, triggerId);
      final preparedSources = <NarrativeEventSourceRef>[];
      final game = await _loadGame(
        _bundle(
          mapId: mapId,
          triggers: const <MapTrigger>[
            MapTrigger(
              id: triggerId,
              name: 'Spawn-area event trigger',
              type: TriggerType.event,
              area: MapRect(
                pos: GridPos(x: 0, y: 1),
                size: GridSize(width: 1, height: 1),
              ),
            ),
          ],
          factIds: const <String>[factId],
          records: <NarrativeEventRecord>[
            _record(
              id: eventId,
              name: 'Reusable spawn-area trigger',
              source: source,
              sceneId: sceneId,
              reusePolicy: NarrativeEventReusePolicy.reusable,
            ),
          ],
          scenes: <SceneAsset>[
            _factScene(sceneId: sceneId, factId: factId),
          ],
        ),
        beforeNarrativeAuthorityPreparation: (occurrence) async {
          if (occurrence.source == source) {
            preparedSources.add(occurrence.source);
          }
        },
      );

      expect(game.debugPlayerGridPosition, const GridPos(x: 0, y: 1));
      expect(preparedSources, isEmpty);
      expect(_factValue(game, factId), isNot(isTrue));

      await _runSingleMove(game, RuntimeInputControl.right);
      await _pumpFrames(game, 4);
      expect(preparedSources, isEmpty);

      await _runSingleMove(game, RuntimeInputControl.left);
      await _pumpUntil(game, () => preparedSources.length == 1);
      expect(_factValue(game, factId), isTrue);

      await _runSingleMove(game, RuntimeInputControl.right);
      await _runSingleMove(game, RuntimeInputControl.left);
      await _pumpUntil(game, () => preparedSources.length == 2);

      expect(preparedSources, <NarrativeEventSourceRef>[source, source]);
      expect(
        game.gameStateSnapshot.narrativeEventProgress.consumedNarrativeEventIds,
        isNot(contains(eventId)),
        reason: 'A reusable Event must remain eligible after re-entry.',
      );
    });

    test('overlapping entries remain FIFO while the first Scene has dialogue',
        () async {
      const mapId = 'trigger_enter_overlap_map';
      const firstTriggerId = 'a_dialogue_trigger';
      const secondTriggerId = 'z_followup_trigger';
      const firstEventId = 'evt_019abcde-3000-7000-8000-000000000004';
      const secondEventId = 'evt_019abcde-3000-7000-8000-000000000005';
      const firstSceneId = 'scene_trigger_dialogue_first';
      const secondSceneId = 'scene_trigger_followup_second';
      const dialogueId = 'dialogue_trigger_fifo';
      const firstFactId = 'fact.trigger_enter.fifo_first';
      const secondFactId = 'fact.trigger_enter.fifo_second';
      final firstSource = NarrativeEventSourceRef.triggerEnter(
        mapId,
        firstTriggerId,
      );
      final secondSource = NarrativeEventSourceRef.triggerEnter(
        mapId,
        secondTriggerId,
      );
      final preparationOrder = <NarrativeEventSourceRef>[];
      final game = await _loadGame(
        _bundle(
          mapId: mapId,
          triggers: const <MapTrigger>[
            MapTrigger(
              id: secondTriggerId,
              name: 'Second overlapping trigger',
              type: TriggerType.custom,
              area: MapRect(
                pos: GridPos(x: 1, y: 1),
                size: GridSize(width: 1, height: 1),
              ),
            ),
            MapTrigger(
              id: firstTriggerId,
              name: 'First overlapping trigger',
              type: TriggerType.event,
              area: MapRect(
                pos: GridPos(x: 1, y: 1),
                size: GridSize(width: 1, height: 1),
              ),
            ),
          ],
          factIds: const <String>[firstFactId, secondFactId],
          dialogueIds: const <String>[dialogueId],
          records: <NarrativeEventRecord>[
            _record(
              id: firstEventId,
              name: 'First overlapping Event',
              source: firstSource,
              sceneId: firstSceneId,
            ),
            _record(
              id: secondEventId,
              name: 'Second overlapping Event',
              source: secondSource,
              sceneId: secondSceneId,
            ),
          ],
          scenes: <SceneAsset>[
            _dialogueFactScene(
              sceneId: firstSceneId,
              dialogueId: dialogueId,
              factId: firstFactId,
            ),
            _factScene(sceneId: secondSceneId, factId: secondFactId),
          ],
        ),
        dialogueSessionLoader: (_) async => _singleLineDialogueSession(),
        beforeNarrativeAuthorityPreparation: (occurrence) async {
          if (occurrence.source == firstSource ||
              occurrence.source == secondSource) {
            preparationOrder.add(occurrence.source);
          }
        },
      );

      await _runSingleMove(game, RuntimeInputControl.right);
      await _pumpUntil(game, () => game.debugFlowPhaseName == 'dialogue');

      expect(preparationOrder, <NarrativeEventSourceRef>[firstSource]);
      expect(_factValue(game, firstFactId), isNot(isTrue));
      expect(_factValue(game, secondFactId), isNot(isTrue));

      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.primary),
        ),
        isTrue,
      );
      await _pumpUntil(
        game,
        () =>
            _factValue(game, firstFactId) == true &&
            _factValue(game, secondFactId) == true,
      );

      expect(preparationOrder, <NarrativeEventSourceRef>[
        firstSource,
        secondSource,
      ]);
      expect(game.debugFlowPhaseName, 'overworld');
      expect(
        game.gameStateSnapshot.narrativeEventProgress.consumedNarrativeEventIds,
        containsAll(<String>[firstEventId, secondEventId]),
      );
    });

    test(
      'holds an on-enter warp until the trigger occurrence is committed',
      () async {
        const mapId = 'trigger_enter_warp_interlock_map';
        const triggerId = 'trigger_before_warp';
        const eventId = 'evt_019abcde-3000-7000-8000-000000000007';
        const sceneId = 'scene_trigger_before_warp';
        const factId = 'fact.trigger_enter.before_warp';
        final source = NarrativeEventSourceRef.triggerEnter(mapId, triggerId);
        final preparationStarted = Completer<void>();
        final releasePreparation = Completer<void>();
        var preparationCount = 0;
        final game = await _loadGame(
          _bundle(
            mapId: mapId,
            triggers: const <MapTrigger>[
              MapTrigger(
                id: triggerId,
                name: 'Trigger before warp',
                type: TriggerType.event,
                area: MapRect(
                  pos: GridPos(x: 1, y: 1),
                  size: GridSize(width: 1, height: 1),
                ),
              ),
            ],
            warps: const <MapWarp>[
              MapWarp(
                id: 'warp_after_trigger',
                pos: GridPos(x: 1, y: 1),
                targetMapId: mapId,
                targetPos: GridPos(x: 3, y: 1),
                triggerMode: MapWarpTriggerMode.onEnter,
              ),
            ],
            factIds: const <String>[factId],
            records: <NarrativeEventRecord>[
              _record(
                id: eventId,
                name: 'Commit trigger before warp',
                source: source,
                sceneId: sceneId,
              ),
            ],
            scenes: <SceneAsset>[
              _factScene(sceneId: sceneId, factId: factId),
            ],
          ),
          beforeNarrativeAuthorityPreparation: (occurrence) async {
            if (occurrence.source != source) {
              return;
            }
            preparationCount++;
            if (!preparationStarted.isCompleted) {
              preparationStarted.complete();
            }
            await releasePreparation.future;
          },
        );

        await _runSingleMove(game, RuntimeInputControl.right);
        await preparationStarted.future.timeout(const Duration(seconds: 2));
        expect(game.debugIsNarrativeSpatialDispatchInFlight, isTrue);
        expect(game.debugHasPendingMapTransition, isTrue);

        await _pumpFrames(game, 30);

        expect(game.gameStateSnapshot.currentMapId, mapId);
        expect(game.debugPlayerGridPosition, const GridPos(x: 1, y: 1));
        expect(game.debugHasPendingMapTransition, isTrue);
        expect(_factValue(game, factId), isNot(isTrue));

        releasePreparation.complete();
        await _pumpUntil(
          game,
          () =>
              _factValue(game, factId) == true &&
              game.debugPlayerGridPosition == const GridPos(x: 3, y: 1) &&
              !game.debugHasPendingMapTransition &&
              !game.debugIsMapActivationDispatchInFlight,
        );

        expect(preparationCount, 1);
        expect(
          game.gameStateSnapshot.narrativeEventProgress
              .consumedNarrativeEventIds
              .where((id) => id == eventId),
          hasLength(1),
        );
      },
    );

    test('validated claimed-ineligible entry never invokes legacy fallback',
        () async {
      const mapId = 'trigger_enter_claimed_map';
      const triggerId = 'trigger_claimed';
      const eventId = 'evt_019abcde-3000-7000-8000-000000000006';
      const sceneId = 'scene_trigger_claimed';
      const factId = 'fact.trigger_enter.claimed_scene';
      const legacyFlag = 'legacy.trigger_enter.claimed_must_not_run';
      const legacyScenario = ScenarioAsset(
        id: 'legacy_trigger_enter_claimed',
        name: 'Legacy claimed trigger must not run',
        scope: ScenarioScope.localEventFlow,
        entryNodeId: 'source',
        nodes: <ScenarioNode>[
          ScenarioNode(
            id: 'source',
            type: ScenarioNodeType.reference,
            payload: ScenarioNodePayload(
              actionKind: kScenarioSourceTriggerEnter,
            ),
            binding: ScenarioNodeBinding(
              mapId: mapId,
              triggerId: triggerId,
            ),
          ),
          ScenarioNode(
            id: 'set_legacy_flag',
            type: ScenarioNodeType.action,
            payload: ScenarioNodePayload(
              actionKind: kScenarioActionSetFlag,
            ),
            binding: ScenarioNodeBinding(flagName: legacyFlag),
          ),
          ScenarioNode(id: 'end', type: ScenarioNodeType.end),
        ],
        edges: <ScenarioEdge>[
          ScenarioEdge(
            id: 'source_to_flag',
            fromNodeId: 'source',
            toNodeId: 'set_legacy_flag',
          ),
          ScenarioEdge(
            id: 'flag_to_end',
            fromNodeId: 'set_legacy_flag',
            toNodeId: 'end',
          ),
        ],
      );
      final source = NarrativeEventSourceRef.triggerEnter(mapId, triggerId);
      final provenance = LegacySourceRef.scenarioSourceNode(
        legacyScenario.id,
        'source',
      );
      final member = LegacySourceClaimMember(
        provenance: provenance,
        sourceFingerprint: computeScenarioSourceFingerprint(
          scenarioId: legacyScenario.id,
          nodeId: 'source',
          scenario: legacyScenario,
        ),
      );
      final cohortId = computeLegacySourceCohortId(source, <LegacySourceRef>[
        provenance,
      ]);
      final claim = LegacySourceClaim(
        cohortId: cohortId,
        source: source,
        members: <LegacySourceClaimMember>[member],
        cohortFingerprint: computeLegacySourceCohortFingerprint(
          cohortId,
          <LegacySourceClaimMember>[member],
        ),
        targetEventIds: const <String>[eventId],
        migrationReceiptId: 'receipt-trigger-enter-claimed',
      );
      final registry = NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.dualRead,
        records: <NarrativeEventRecord>[
          _record(
            id: eventId,
            name: 'Disabled claimed trigger Event',
            source: source,
            sceneId: sceneId,
            enabled: false,
          ),
        ],
        legacyClaims: <LegacySourceClaim>[claim],
      );
      var preparationCount = 0;
      final game = await _loadGame(
        _bundle(
          mapId: mapId,
          triggers: const <MapTrigger>[
            MapTrigger(
              id: triggerId,
              name: 'Claimed event trigger',
              type: TriggerType.event,
              area: MapRect(
                pos: GridPos(x: 1, y: 1),
                size: GridSize(width: 1, height: 1),
              ),
            ),
          ],
          factIds: const <String>[factId],
          scenarios: const <ScenarioAsset>[legacyScenario],
          registry: registry,
          scenes: <SceneAsset>[
            _factScene(sceneId: sceneId, factId: factId),
          ],
        ),
        beforeNarrativeAuthorityPreparation: (occurrence) async {
          if (occurrence.source == source) {
            preparationCount++;
          }
        },
      );

      await _runSingleMove(game, RuntimeInputControl.right);
      await _pumpUntil(game, () => preparationCount == 1);
      await _pumpFrames(game, 8);

      expect(_factValue(game, factId), isNot(isTrue));
      expect(
        game.gameStateSnapshot.storyFlags.activeFlags,
        isNot(contains(legacyFlag)),
        reason: 'A validated claim blocks legacy even when V2 is ineligible.',
      );
      expect(
        game.gameStateSnapshot.narrativeEventProgress.consumedNarrativeEventIds,
        isNot(contains(eventId)),
      );
    });

    test(
      'trigger outcome retry stays pending and releases the detached queue',
      () async {
        const mapId = 'trigger_enter_retry_map';
        const triggerId = 'trigger_retry';
        const eventId = 'evt_019abcde-3000-7000-8000-00000000000a';
        const sceneId = 'scene_trigger_retry';
        const outcomeId = 'trigger.retry';
        final source = NarrativeEventSourceRef.triggerEnter(mapId, triggerId);
        final gate = NarrativeRuntimeActivityGate();
        final repository = _CheckpointCountingRepository(gate);
        var outcomePreparationCount = 0;
        final game = await _loadGame(
          _bundle(
            mapId: mapId,
            triggers: const <MapTrigger>[
              MapTrigger(
                id: triggerId,
                name: 'Retry event trigger',
                type: TriggerType.event,
                area: MapRect(
                  pos: GridPos(x: 1, y: 1),
                  size: GridSize(width: 1, height: 1),
                ),
              ),
            ],
            records: <NarrativeEventRecord>[
              _record(
                id: eventId,
                name: 'Trigger retry producer',
                source: source,
                sceneId: sceneId,
              ),
            ],
            scenes: <SceneAsset>[
              _outcomeScene(sceneId: sceneId, outcomeId: outcomeId),
            ],
          ),
          narrativeRuntimeActivityGate: gate,
          saveRepository: repository,
          beforeNarrativeAuthorityPreparation: (occurrence) async {
            if (occurrence.source.kind !=
                NarrativeEventSourceKind.outcomeReceived) {
              return;
            }
            outcomePreparationCount++;
            throw StateError(
              'retryable trigger outcome infrastructure failure',
            );
          },
        );

        final uncaughtErrors = await _captureDetachedErrors(() async {
          await _runSingleMove(game, RuntimeInputControl.right);
          await _pumpUntil(
            game,
            () =>
                game.debugPendingNarrativeTriggerEntryCount == 0 &&
                !game.debugIsNarrativeSpatialDispatchInFlight &&
                !game.debugIsNarrativeOutcomeWorkInFlight &&
                game.gameStateSnapshot.narrativeEventProgress
                    .pendingNarrativeOutcomeDeliveries.isNotEmpty,
          );
          await Future<void>.delayed(Duration.zero);
        });

        final state = game.gameStateSnapshot;
        final pending =
            state.narrativeEventProgress.pendingNarrativeOutcomeDeliveries;
        expect(uncaughtErrors, isEmpty);
        expect(outcomePreparationCount, 1);
        expect(pending, hasLength(1));
        expect(pending.single.outcome.outcomeId, outcomeId);
        expect(pending.single.attemptCount, 1);
        expect(
          state.narrativeEventProgress.consumedNarrativeEventIds,
          contains(eventId),
        );
        expect(game.debugPendingNarrativeTriggerEntryCount, 0);
        expect(game.debugIsNarrativeSpatialDispatchInFlight, isFalse);
        expect(game.debugIsNarrativeOutcomeWorkInFlight, isFalse);
        expect(game.debugIsGameplayInputLocked, isFalse);
        expect(gate.activity, NarrativeRuntimeActivity.idle);
        expect(await game.saveGame(), isTrue);
        expect(repository.saveCount, 1);
        expect(
          repository.storedState!.narrativeEventProgress
              .pendingNarrativeOutcomeDeliveries.single.attemptCount,
          1,
        );
      },
    );
  });
}

Future<List<Object>> _captureDetachedErrors(
  Future<void> Function() body,
) async {
  final errors = <Object>[];
  final bodyCompleted = Completer<void>();
  runZonedGuarded(
    () {
      body().then<void>(
        (_) => bodyCompleted.complete(),
        onError: (Object error, StackTrace stackTrace) {
          bodyCompleted.completeError(error, stackTrace);
        },
      );
    },
    (error, _) => errors.add(error),
  );
  await bodyCompleted.future;
  return errors;
}

NarrativeEventRecord _record({
  required String id,
  required String name,
  required NarrativeEventSourceRef source,
  required String sceneId,
  bool enabled = true,
  NarrativeEventReusePolicy reusePolicy = NarrativeEventReusePolicy.oneShot,
}) {
  return NarrativeEventRecord.configuredStructurallyUnchecked(
    NarrativeEventDefinition(
      id: id,
      name: name,
      source: source,
      conditions: const <NarrativeEventCondition>[],
      sceneId: sceneId,
      reusePolicy: reusePolicy,
      priority: 0,
      order: 0,
    ),
    enabled: enabled,
  );
}

RuntimeMapBundle _bundle({
  required String mapId,
  required List<MapTrigger> triggers,
  required List<SceneAsset> scenes,
  List<MapWarp> warps = const <MapWarp>[],
  List<NarrativeEventRecord> records = const <NarrativeEventRecord>[],
  List<String> factIds = const <String>[],
  List<String> dialogueIds = const <String>[],
  List<ScenarioAsset> scenarios = const <ScenarioAsset>[],
  NarrativeEventRegistry? registry,
}) {
  final manifest = ProjectManifest(
    name: 'V2-21 triggerEnter $mapId',
    settings: const ProjectSettings(tileWidth: 16, tileHeight: 16),
    maps: <ProjectMapEntry>[
      ProjectMapEntry(
        id: mapId,
        name: mapId,
        relativePath: 'maps/$mapId.json',
      ),
    ],
    tilesets: const <ProjectTilesetEntry>[],
    facts: <NarrativeFactDefinition>[
      for (final factId in factIds)
        NarrativeFactDefinition(id: factId, label: factId),
    ],
    dialogues: <ProjectDialogueEntry>[
      for (final dialogueId in dialogueIds)
        ProjectDialogueEntry(
          id: dialogueId,
          name: dialogueId,
          relativePath: 'dialogues/$dialogueId.yarn',
        ),
    ],
    scenarios: scenarios,
    eventRegistry: registry ??
        NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.v2Only,
          records: records,
          legacyClaims: const <LegacySourceClaim>[],
        ),
    scenes: scenes,
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
  );
  return RuntimeMapBundle(
    manifest: manifest,
    map: MapData(
      id: mapId,
      name: mapId,
      size: const GridSize(width: 4, height: 3),
      layers: const <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: const <MapEntity>[
        MapEntity(
          id: 'spawn',
          name: 'Spawn',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 0, y: 1),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.east,
          ),
        ),
      ],
      triggers: triggers,
      warps: warps,
      mapMetadata: const MapMetadata(defaultSpawnId: 'spawn'),
    ),
    projectRootDirectory: '/tmp/v2_21_trigger_enter_$mapId',
    tilesetAbsolutePathsById: const <String, String>{},
  );
}

SceneAsset _factScene({
  required String sceneId,
  required String factId,
}) {
  return SceneAsset(
    id: sceneId,
    name: sceneId,
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: <SceneNode>[
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'set_fact',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.setFact(factId: factId, value: true),
          ),
        ),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ],
      edges: <SceneEdge>[
        SceneEdge(
          id: 'start_to_fact',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'set_fact',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'fact_to_end',
          fromNodeId: 'set_fact',
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.actionCompleted,
        ),
      ],
    ),
  );
}

SceneAsset _outcomeScene({
  required String sceneId,
  required String outcomeId,
}) {
  return SceneAsset(
    id: sceneId,
    name: sceneId,
    declaredOutcomes: <SceneOutcome>[
      SceneOutcome(id: outcomeId, label: outcomeId),
    ],
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: <SceneNode>[
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'end',
          kind: SceneNodeKind.end,
          payload: SceneEndPayload(sceneOutcomeId: outcomeId),
        ),
      ],
      edges: <SceneEdge>[
        SceneEdge(
          id: 'start_to_end',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.defaultFlow,
        ),
      ],
    ),
  );
}

SceneAsset _dialogueFactScene({
  required String sceneId,
  required String dialogueId,
  required String factId,
}) {
  return SceneAsset(
    id: sceneId,
    name: sceneId,
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: <SceneNode>[
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'dialogue',
          kind: SceneNodeKind.yarnDialogue,
          payload: SceneYarnDialoguePayload(dialogueId: dialogueId),
        ),
        SceneNode(
          id: 'set_fact',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.setFact(factId: factId, value: true),
          ),
        ),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ],
      edges: <SceneEdge>[
        SceneEdge(
          id: 'start_to_dialogue',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'dialogue',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'dialogue_to_fact',
          fromNodeId: 'dialogue',
          fromPortId: 'completed',
          toNodeId: 'set_fact',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'fact_to_end',
          fromNodeId: 'set_fact',
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.actionCompleted,
        ),
      ],
    ),
  );
}

DialogueSession _singleLineDialogueSession() {
  return DialogueSession.start(
    <YarnNode>[
      YarnNode(
        title: 'Start',
        steps: <YarnStep>[YarnStepLine('Entrée détectée.')],
      ),
    ],
    'Start',
  )!;
}

Future<_TestPlayableMapGame> _loadGame(
  RuntimeMapBundle bundle, {
  RuntimeDialogueSessionLoader? dialogueSessionLoader,
  NarrativeRuntimeActivityGate? narrativeRuntimeActivityGate,
  GameSaveRepository? saveRepository,
  Future<void> Function(NarrativeEventOccurrence occurrence)?
      beforeNarrativeAuthorityPreparation,
}) async {
  final game = _TestPlayableMapGame(
    bundle: bundle,
    projectFilePath: '${bundle.projectRootDirectory}/project.json',
    dialogueSessionLoader: dialogueSessionLoader,
    narrativeRuntimeActivityGate: narrativeRuntimeActivityGate,
    saveRepository: saveRepository,
    beforeNarrativeAuthorityPreparation: beforeNarrativeAuthorityPreparation,
  );
  game.onGameResize(Vector2(640, 480));
  await game.onLoad().timeout(const Duration(seconds: 2));
  await _pumpUntil(
    game,
    () => !game.debugIsMapActivationDispatchInFlight,
  );
  return game;
}

bool? _factValue(PlayableMapGame game, String factId) {
  return game
      .gameStateSnapshot.narrativeFactRuntimeState.overridesByFactId[factId];
}

Future<void> _runSingleMove(
  PlayableMapGame game,
  RuntimeInputControl control,
) async {
  expect(
    game.handleRuntimeInputEvent(RuntimeInputEvent.press(control)),
    isTrue,
  );
  game.update(0.016);
  await Future<void>.delayed(Duration.zero);
  expect(
    game.handleRuntimeInputEvent(RuntimeInputEvent.release(control)),
    isTrue,
  );

  for (var i = 0; i < 180; i++) {
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
    if (!game.debugIsPlayerStepping) {
      return;
    }
  }
  fail('Timed out waiting for the V2-21 movement step to settle.');
}

Future<void> _pumpFrames(PlayableMapGame game, int count) async {
  for (var i = 0; i < count; i++) {
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
  }
}

Future<void> _pumpUntil(
  PlayableMapGame game,
  bool Function() done, {
  int maxTicks = 360,
}) async {
  for (var i = 0; i < maxTicks; i++) {
    if (done()) {
      return;
    }
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
  }
  fail('Timed out waiting for the V2-21 runtime integration.');
}

final class _TestPlayableMapGame extends PlayableMapGame {
  _TestPlayableMapGame({
    required super.bundle,
    required super.projectFilePath,
    super.dialogueSessionLoader,
    super.narrativeRuntimeActivityGate,
    super.saveRepository,
    super.beforeNarrativeAuthorityPreparation,
  });

  bool _onLoadCompleted = false;

  @override
  bool get isLoaded => _onLoadCompleted;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _onLoadCompleted = true;
  }
}

final class _CheckpointCountingRepository implements GameSaveRepository {
  _CheckpointCountingRepository(this.gate);

  final NarrativeRuntimeActivityGate gate;
  GameState? storedState;
  int saveCount = 0;

  @override
  Future<void> save(GameState state) {
    return gate.runCheckpoint(
      NarrativeRuntimeCheckpointOperation.save,
      () async {
        saveCount++;
        storedState = state;
      },
    );
  }

  @override
  Future<GameState?> load() async => storedState;

  @override
  Future<bool> exists() async => storedState != null;

  @override
  Future<void> delete() async {
    storedState = null;
  }
}
~~~~~~~~

### 25.21 `reports/narrativeStudio/events/ns_event_v2_19_map_enter_production_dispatch_bridge_v0.md`

~~~~~~~~markdown
# NS-EVENT-V2-19 — Map Enter Production Dispatch Bridge V0 — Evidence Pack

## 1. Identité et verdict proposé

```text
Lot exact : NS-EVENT-V2-19 — Map Enter Production Dispatch Bridge V0
Phase : F2 — Runtime Source Bridges
Date : 2026-07-15
Branche : main
Baseline : 2f68328a38bf218c843e497940f8dd24a7a9c194
Verdict proposé du jalon : PASS
Verdict proposé de la phase F2 : IN_PROGRESS
Prochain jalon : NS-EVENT-V2-20 — Entity Interaction Production Dispatch Bridge V0
Roadmap modifiée : non
Git write (add/commit/push/branch) : aucun
```

Le jalon V2-19 peut être proposé `PASS`. Il branche la seule source
`mapEnter` sur l'autorité F1, avec une activation unique et une raison explicite
par boot, warp, connection ou restauration. La phase F2 ne peut pas être close :
les bridges `entityInteract`, `triggerEnter` et `outcomeReceived` restent les
jalons V2-20 à V2-22.

## 2. Résumé exécutif

Le runtime dispose maintenant d'un contrat `MapActivation` explicite. Une
activation n'est installée qu'après un boot cohérent ou une transition réussie,
puis le bridge produit au maximum une occurrence canonique
`NarrativeEventSourceRef.mapEnter(mapId)`. Le même chemin arbitre Event V2 et
Scenario legacy : un claim valide mais inéligible ne réactive jamais le fallback.

Les quatre raisons ratifiées par ADR-EV2-015 sont prises en charge :

| Chemin | Raison | Point d'émission | Échec / rollback |
|---|---|---|---|
| démarrage normal ou seed de démonstration | `initialBoot` | monde monté, phase overworld, activation installée | aucune occurrence si `onLoad` échoue avant installation |
| warp | `warp` | swap map et placement joueur terminés | zéro si cible invalide, preload/load ou swap échoue |
| connection | `connection` | transition et éventuelle animation d'entrée terminées | zéro si entrée bloquée ou transition échoue |
| vraie save versionnée ou `loadGame` | `saveRestore` | état/map/joueur/NPC/occupancy/overworld cohérents | zéro avant activation ; résultat `false` si autorité/outbox échoue |

Une restauration sur la même map émet bien un `mapEnter saveRestore`. Les
deliveries outcome F1 déjà pending sont drainées FIFO avant cette occurrence.
Si une delivery provoque une autre activation, l'ancien `mapEnter` devient
`stale` et la nouvelle activation émet sa propre raison. Le whiteout même-map ne
fabrique aucune activation supplémentaire.

Le boot ne bloque plus le lifecycle Flame sur une Scene interactive :
`onLoad()` se termine, le dispatch reste in-flight et l'input overworld est
interlocké jusqu'à la fin. Les dialogues et combats déjà ouverts continuent à
recevoir leur input. Les tests historiques qui simulaient un input dès le retour
de `onLoad` attendent désormais explicitement cette frontière asynchrone.

## 3. Scope confirmé et non-objectifs

### Inclus

- contrat runtime `MapActivationReason` / `MapActivation` ;
- déduplication, staleness et résultat typé du bridge `mapEnter` ;
- composition réelle F1 dans `PlayableMapGame` ;
- snapshot d'autorité cohérent sur le manifest et le corpus de maps ;
- exécution de la Scene Event V2 avec commit transactionnel ;
- fallback Scenario legacy uniquement lorsque l'autorité l'autorise ;
- boot, warp, connection, restauration même-map et vraie save host ;
- drain FIFO de l'outbox restaurée avant `mapEnter saveRestore` ;
- interlocks contre transition/load/input concurrents ;
- non-régressions whiteout, P3, Scene V1 et interactions immédiates après boot.

### Volontairement hors scope

- V2-20 : aucun bridge Event V2 `entityInteract` ;
- V2-21 : aucun bridge Event V2 `triggerEnter` ;
- V2-22 : aucun bridge général live `outcomeReceived` ni saga complète de
  reentrancy ; le code outcome présent est uniquement le seam de restauration
  exigé par ADR-EV2-015 ;
- FG-014 : aucun rollback transactionnel complet de la phase destructive de
  `loadGame` ;
- aucune modification de schema core, d'authoring editor ou de roadmap ;
- aucune clôture de FG-082, FG-086 ou FG-088 ; ils restent `TODO`.

## 4. Audit initial

### 4.1 État Git initial

```text
pwd : /Users/karim/Project/pokemonProject
branch : main
HEAD : 2f68328a38bf218c843e497940f8dd24a7a9c194
origin/main : 2f68328a38bf218c843e497940f8dd24a7a9c194
git status --short --untracked-files=all : <empty>
git diff : <empty>
```

### 4.2 Documents et preuves lus

- `AGENTS.md` et `codex_rule.md` ;
- `pokemap_roadmap_mecaniques_fangame.md` ;
- `MVP Selbrume/road_map_event_builder_v2.md`, section Phase F2 / V2-19 ;
- `MVP Selbrume/event_builder_v2_architecture_decisions.md`, en particulier
  ADR-EV2-013, ADR-EV2-014 et ADR-EV2-015 ;
- clôtures et Evidence Packs des phases E, E-bis, F1-PREREQ et F1 ;
- historique Git jusqu'à `2f68328a feat(event-v2): close NS-EVENT-V2 Phase F1` ;
- implémentations F1 de l'autorité, du coordinator, des transactions, de
  l'activity gate et de l'outbox ;
- chemins runtime existants `onLoad`, warp, connection, `loadGame`, whiteout,
  Scenario mapEnter et Scene host callbacks ;
- host de lancement et distinction save versionnée / override / demo seed ;
- tests runtime P3, input, whiteout, Scene V1, save/load et host smokes.

Le serveur documentaire Flame attendu n'a pas fourni de résultat exploitable.
L'audit a donc vérifié la version installée (`flame ^1.35.0`) et réutilisé les
patterns lifecycle déjà présents dans le repo, sans inventer d'API Flame.

### 4.3 Constat avant changement

- boot, warp et connection appelaient directement le Scenario legacy
  `mapEnter` ;
- `loadGame` restaurait sans occurrence équivalente ;
- aucune identité d'activation ne permettait de dédupliquer ou d'invalider une
  occurrence devenue stale ;
- la save host était représentée par `SaveData`, comme les seeds manuels, donc
  `saveData != null` ne pouvait pas déterminer honnêtement `saveRestore` ;
- F1 fournissait déjà l'autorité, la progression, les transactions, l'outbox et
  les gates nécessaires ; V2-19 devait les composer, pas les réimplémenter ;
- la phase destructive de `loadGame` était déjà documentée non transactionnelle
  et appartient à FG-014.

### 4.4 Risques identifiés au Gate 0

- double boot/load ;
- mapEnter émis avant une transition réellement terminée ;
- fallback legacy malgré un claim inéligible ;
- outcome pending livré après mapEnter ou dans le désordre ;
- course load/warp/connection pendant un dispatch asynchrone ;
- deadlock de `onLoad` sur dialogue ou combat interactif ;
- overwrite d'un write-back combat par le snapshot Scene pré-combat ;
- tests historiques supposant implicitement un mapEnter synchrone.

## 5. Contrats et décisions d'implémentation

### 5.1 Identité d'activation

`MapActivation` contient un `activationId`, un `mapId` et une raison parmi les
quatre valeurs ADR. Son occurrence Event V2 ne contient que la source canonique
`mapEnter(mapId)` : la raison reste une métadonnée runtime et ne pollue pas le
contrat domaine F1.

### 5.2 Déduplication et staleness

Le bridge claim l'identité avant son premier `await`. Un second appel concurrent
sur la même activation retourne `Duplicate`. Des checks de staleness encadrent
chaque frontière asynchrone : transaction initiale, pre-hook restore, lecture
outbox, préparation d'autorité, Scene et fallback. Le set des IDs claimés est
borné à l'activation courante.

### 5.3 Autorité unique et fallback

Le bridge construit le coordinator F1 avec le snapshot runtime validé. Les
résultats `handled`, `claimedButIneligible`, `noMatch`, `failed`, `cancelled`,
`authorityBlocked` sont traduits sans second chemin concurrent. Le fallback
Scenario n'est exécuté que pour `noMatch` avec `legacyFallbackAllowed == true`.

### 5.4 Restauration et outbox

Pour `saveRestore`, le bridge synchronise d'abord l'état runtime dans la
transaction F1, draine l'outbox réelle FIFO, récupère l'état commité, puis
prépare le `mapEnter`. Un Scenario outcome restauré peut demander un
`transitionMap` : le runtime consomme précisément cette requête, installe la
nouvelle activation warp et laisse le mapEnter restore précédent devenir stale.

`loadGame()` acquiert son lock avant son premier `await`. Les inputs overworld,
warps et connections sont bloqués tant que le load ou un dispatch d'activation
est in-flight. Un résultat `Failed` ou `AuthorityBlocked` fait retourner `false`
et conserve une delivery retryable pending.

### 5.5 Scene, conséquences et write-back host

Les conséquences Event V2 sont bufferisées jusqu'au succès de la Scene, puis
appliquées au `GameState` host le plus récent. Cela conserve les PV, flags,
récompenses et métadonnées écrits par un combat. Un conflit d'état initial échoue
avant tout callback host.

La critique finale a trouvé que le refactor des callbacks Scene capturait un
`GameState` fixe pour les conditions V1. Le correctif final passe une closure
`GameState Function()` et lit `_gameState` à chaque branche, préservant les
write-backs dialogue/combat pour V1 comme V2.

### 5.6 Lifecycle du boot

Le dispatch boot est programmé après `super.onLoad()`, sans être attendu. Cela
évite qu'un dialogue ou combat Event V2 bloque le montage du `GameWidget`. Le
dispatch est immédiatement enregistré in-flight ; le runtime bloque seulement
les actions overworld concurrentes, pas les inputs du dialogue/combat actif.

### 5.7 Sélection host de la raison

Le host calcule la save sélectionnée une fois. Une save versionnée réellement
sélectionnée utilise `saveRestore`. Un override manuel ou seed de démonstration
reste `initialBoot`, même s'il est transporté par un objet `SaveData`. Aucun
heuristique `saveData != null` n'est utilisé.

## 6. Verdicts des sub-agents et passes contradictoires

| Passe | Verdict initial | Verdict final | Signal utile |
|---|---|---|---|
| Audit / Architecture | BLOCKED | PASS | ambiguïtés restore/seed/outbox résolues par ADR-EV2-015 : vraie save=`saveRestore`, seed=`initialBoot`, FIFO avant mapEnter, activation stale invalidée |
| Implémentation bridge | RED puis GREEN | PASS | bridge typé, déduplication, staleness, authority modes et outbox ; tests ciblés `+14` |
| Tests / intégration runtime | plusieurs races trouvées | GREEN | interlocks connection/load, transition outcome restaurée, boot interactif, failure outbox ; matrice `+64` |
| Review de spec | FAIL intermédiaire | PASS | courses activation/load et fallback transitionMap corrigées ; matrice raisons/échecs conforme |
| Review qualité | FAIL (3 findings) | QUALITY PASS | deadlock boot Scene, perte write-back combat et load faussement réussi corrigés ; aucun P0-P2 restant |
| Build / Validation | FAIL initial | BUILD / VALIDATION PASS | 6 runtime + 1 host supposaient le boot synchrone ; fixtures corrigées puis full runtime/host/build verts |
| Critique finale | P2 détecté | CRITIQUE PASS | condition Scene V1 lisait un snapshot figé ; closure dynamique ajoutée ; aucun P0-P2 restant |

La passe finale n'a pas masqué les échecs intermédiaires : ils sont conservés
ci-dessous avec leur correction et leur rerun.

## 7. Inventaire complet des fichiers

### 7.1 Fichiers de production créés

| Fichier | Lignes | Symboles / rôle |
|---|---:|---|
| `packages/map_runtime/lib/src/application/map_activation.dart` | 48 | `MapActivationReason`, `MapActivation`, occurrence canonique |
| `packages/map_runtime/lib/src/application/map_enter_production_dispatch_bridge.dart` | 279 | résultats typés, `MapEnterProductionDispatchBridge`, dédup/stale/authority/fallback |
| `packages/map_runtime/lib/src/application/narrative_event_runtime_snapshot.dart` | 152 | snapshot manifest/maps, catalog, facts et claims validés |
| `packages/map_runtime/lib/src/application/narrative_scene_runtime_execution.dart` | 111 | exécution Scene, conséquences bufferisées, rebase post-host |

### 7.2 Tests créés

| Fichier | Lignes | Couverture principale |
|---|---:|---|
| `packages/map_runtime/test/narrative_event_runtime_snapshot_test.dart` | 45 | `legacyOnly` ne charge pas le corpus maps |
| `packages/map_runtime/test/narrative_map_enter_production_dispatch_bridge_test.dart` | 882 | 14 tests : IDs, 4 raisons, concurrence, modes, claims, stale, fail-closed, Scene, FIFO restore |
| `packages/map_runtime/test/narrative_scene_runtime_execution_test.dart` | 203 | conservation write-back combat + conséquences ; conflit initial fail-closed |
| `packages/map_runtime/test/playable_map_game_event_v2_boot_integration_test.dart` | 466 | boot V2, claim inéligible, dialogue interactif après onLoad |
| `packages/map_runtime/test/playable_map_game_initial_save_restore_activation_test.dart` | 177 | vraie restauration initiale map/pose puis une occurrence |
| `packages/map_runtime/test/playable_map_game_map_activation_interlock_test.dart` | 902 | races connection/load, outcome→warp stale, échec outbox retryable |
| `packages/map_runtime/test/playable_map_game_map_enter_v2_integration_test.dart` | 207 | load même-map et cible absente |
| `packages/map_runtime/test/playable_map_game_save_restore_outbox_integration_test.dart` | 315 | outcomes A/B FIFO avant mapEnter C |

Le contenu complet de ces douze fichiers créés figure en annexe 16. Le présent
rapport, lui-même nouveau, est son propre contenu complet et n'est pas dupliqué
récursivement.

### 7.3 Fichiers modifiés et zones précises

| Fichier | Zones modifiées | Raison / impact |
|---|---|---|
| `examples/playable_runtime_host/lib/main.dart` | `_ProjectLoaderPageState` lors de la création de `PlayableMapGame` | calcule `selectedLaunchSave` une fois et passe la raison explicite |
| `examples/playable_runtime_host/lib/src/runtime_launch_save.dart` | imports et `resolveRuntimeHostInitialMapActivationReason` | distingue vraie save versionnée des overrides/seeds |
| `examples/playable_runtime_host/test/runtime_launch_save_test.dart` | groupe resolver | prouve `saveRestore` seulement pour la save réellement sélectionnée |
| `examples/playable_runtime_host/test/p3_narrative_smoke_slice_test.dart` | après `onLoad` + helper `_waitForInitialMapActivation` | adapte le smoke à la frontière boot asynchrone avant lecture du flag |
| `packages/map_runtime/lib/map_runtime.dart` | exports application | rend publics activation, bridge et résultats typés |
| `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart` | imports, constructeur, composition F1, IDs, snapshot/Scene/outbox, debug getters, `onLoad`, input/update interlocks, transitionMap, callbacks Scene, `loadGame`, warp, connection | branche le bridge production, garantit l'ordre et empêche les courses/doubles dispatchs |
| `packages/map_runtime/test/playable_map_game_input_test.dart` | groupe warp/connection et fixtures | raisons `warp`/`connection`, zéro activation sur échec, attente boot |
| `packages/map_runtime/test/playable_map_game_whiteout_lite_test.dart` | attente initiale + assertions compteur/raison | prouve qu'un whiteout même-map n'émet pas un second mapEnter |
| `packages/map_runtime/test/item_pickup_give_item_readiness_test.dart` | test interaction playable + helper d'attente | non-régression input immédiat après boot asynchrone |
| `packages/map_runtime/test/ns_event_34_scene_target_handoff_smoke_test.dart` | setup runtime + helper d'attente | non-régression Scene target V1 après boot |
| `packages/map_runtime/test/ns_event_35_trigger_variants_lifecycle_gate_test.dart` | `_loadRuntimeCase` + helper d'attente | non-régression interaction/mouvement/lifecycle NS-EVENT-35 |

#### Découpage précis de `PlayableMapGame`

```text
lignes ~140-220     : paramètres reason/gate/test seam et champs de composition
lignes ~319-599     : activation IDs, snapshot authority, Scene, bridge, outbox restore
lignes ~690-710     : getters de preuve activation/load
lignes ~1775-1884   : boot initialBoot/saveRestore et dispatch post-onLoad
lignes ~2021-2189   : interlocks input/update et installation connection animée
lignes ~3255-3300   : transitionMap runtime-owned autorisée pendant restore
lignes ~5625-5970   : callbacks Scene V1/V2 et GameState dynamique
lignes ~6935-7084   : lock load, restauration cohérente et résultat du bridge
lignes ~7209-7410   : warp, rollback et activation après succès
lignes ~7560-7708   : connection, rollback et activation après succès
lignes ~9208-9217   : activation attachée à l'animation d'entrée connection
```

## 8. Matrice de comportement prouvée

| Cas | Résultat attendu | Preuve |
|---|---|---|
| boot legacy | un fallback legacy | bridge + P3 + input |
| boot V2 eligible | Scene V2, aucun legacy | boot integration |
| boot V2 dialogue | `onLoad` termine, dialogue interactif, commit après input | boot integration |
| dualRead claim inéligible | aucun fallback | bridge + boot integration |
| warp réussi | une activation `warp` | input suite |
| warp invalide | zéro nouvelle activation | input suite |
| connection réussie | une activation `connection` | input suite |
| connection bloquée | zéro nouvelle activation | input suite |
| load même map | une activation `saveRestore` | map-enter integration |
| vraie save host | une seule raison `saveRestore` | initial restore + resolver host |
| save absente / map absente | zéro activation terminée | integration négative |
| outbox A puis B puis mapEnter C | A→B→C FIFO | outbox integration |
| outcome restore provoque warp | restore stale, nouvelle activation warp | interlock integration |
| échec authority/outbox retry | load false, delivery pending, métriques inchangées | interlock négatif |
| whiteout même map | compteur inchangé | whiteout lite |
| Scene combat puis conséquence | write-back combat conservé | scene execution |
| conflit Scene initial | aucun callback host | scene execution |
| activation concurrente dupliquée | une seule exécution | bridge concurrency |

## 9. TDD et commandes ciblées

### 9.1 Baseline avant implémentation

```text
cd packages/map_runtime && flutter test \
  test/narrative_event_legacy_runtime_characterization_test.dart \
  test/playable_map_game_whiteout_lite_test.dart \
  test/playable_map_game_input_test.dart
Résultat : exit 0, +37: All tests passed!
```

### 9.2 RED observés

- tests du bridge écrits avant production ;
- correction write-back Scene : exit 1, uniquement
  `No named parameter with the name 'currentGameState'` avant ajout du contrat ;
- première full suite : exit 1 avec six tests runtime et un host démontrant la
  nouvelle frontière boot non attendue par les fixtures.

### 9.3 Matrices GREEN ciblées

```text
cd packages/map_runtime && flutter test \
  test/narrative_event_runtime_snapshot_test.dart \
  test/narrative_map_enter_production_dispatch_bridge_test.dart \
  test/narrative_scene_runtime_execution_test.dart \
  test/playable_map_game_event_v2_boot_integration_test.dart \
  test/playable_map_game_initial_save_restore_activation_test.dart \
  test/playable_map_game_map_activation_interlock_test.dart \
  test/playable_map_game_map_enter_v2_integration_test.dart \
  test/playable_map_game_save_restore_outbox_integration_test.dart \
  test/playable_map_game_whiteout_lite_test.dart \
  test/playable_map_game_input_test.dart
Résultat : exit 0, +64: All tests passed!

cd packages/map_runtime && flutter test \
  test/item_pickup_give_item_readiness_test.dart \
  test/ns_event_34_scene_target_handoff_smoke_test.dart \
  test/ns_event_35_trigger_variants_lifecycle_gate_test.dart
Résultat après adaptation de la frontière boot : exit 0, +18: All tests passed!

cd examples/playable_runtime_host && \
  flutter test test/p3_narrative_smoke_slice_test.dart
Résultat après adaptation : exit 0, +1: All tests passed!

cd packages/map_runtime && flutter test \
  test/narrative_scene_runtime_execution_test.dart \
  test/ns_event_34_scene_target_handoff_smoke_test.dart \
  test/playable_map_game_event_v2_boot_integration_test.dart
Résultat après closure GameState dynamique : exit 0, +6: All tests passed!
```

### 9.4 Analyses ciblées

```text
flutter analyze [12 fichiers runtime V2-19 ciblés]
Résultat : exit 0, No issues found! (ran in 3.6s)

cd packages/map_runtime && flutter analyze \
  test/item_pickup_give_item_readiness_test.dart \
  test/ns_event_34_scene_target_handoff_smoke_test.dart \
  test/ns_event_35_trigger_variants_lifecycle_gate_test.dart
Résultat : exit 0, No issues found! (ran in 7.2s)

cd examples/playable_runtime_host && \
  flutter analyze test/p3_narrative_smoke_slice_test.dart
Résultat : exit 0, No issues found! (ran in 12.3s)

cd packages/map_runtime && flutter analyze \
  lib/src/presentation/flame/playable_map_game.dart \
  test/narrative_scene_runtime_execution_test.dart \
  test/ns_event_34_scene_target_handoff_smoke_test.dart \
  test/playable_map_game_event_v2_boot_integration_test.dart
Résultat : exit 0, No issues found! (ran in 10.1s)
```

## 10. Échec de validation intermédiaire et correction

La première passe Build / Validation a honnêtement conclu `FAIL` :

```text
packages/map_runtime: flutter test
exit 1, +1669 ~1 -6

examples/playable_runtime_host: flutter test
exit 1, +49 -1
```

Échecs reproduits : pickup objet, NS-EVENT-34, quatre cas NS-EVENT-35 et P3
host. Tous simulaient une interaction ou lisaient le flag immédiatement après
`await game.onLoad()` alors que l'interlock map activation était encore actif.
Le runtime était volontairement asynchrone pour ne pas deadlocker les Scenes
interactives. Les fixtures ont donc été corrigées pour attendre explicitement
`debugIsMapActivationDispatchInFlight == false`. Aucun contournement production
n'a été ajouté.

La critique finale a ensuite trouvé le snapshot condition Scene V1 figé. La
validation complète précédemment verte a été invalidée, le callback a été
corrigé, puis les sept commandes ont été relancées depuis zéro.

## 11. Validation complète finale

| Répertoire | Commande exacte | Exit | Résultat exact utile |
|---|---|---:|---|
| `packages/map_runtime` | `flutter test` | 0 | `+1675 ~1: All tests passed!` |
| `packages/map_runtime` | `flutter analyze --no-fatal-infos` | 0 | 347 diagnostics info existants, aucune erreur |
| `packages/map_runtime` | `flutter test test/phase_a_golden_battle_slice_smoke_test.dart` | 0 | `+3: All tests passed!` |
| `examples/playable_runtime_host` | `flutter test` | 0 | `+50: All tests passed!` |
| `examples/playable_runtime_host` | `flutter analyze --no-fatal-infos` | 0 | 1 diagnostic info existant, aucune erreur |
| `examples/playable_runtime_host` | `flutter test test/phase_a_golden_slice_launch_test.dart` | 0 | `+1: All tests passed!` |
| `examples/playable_runtime_host` | `flutter build macos --debug` | 0 | `build/macos/Build/Products/Debug/playable_runtime_host.app` construit |

Le `~1` runtime est un test explicitement skipped par la suite ; il ne représente
pas un échec. Les analyses ciblées des fichiers modifiés sont à zéro issue. Les
diagnostics info globaux sont conservés et n'ont pas été nettoyés hors scope.

## 12. Compatibilité, rollback et observabilité

- `legacyOnly` reste le rollback fonctionnel prévu : le même bridge autorise le
  fallback Scenario sans double dispatch ;
- `dualRead` et `v2Only` restent arbitrés par l'autorité F1 et les claims ;
- aucun schema persistant nouveau n'est introduit par V2-19 ;
- les logs `[event_v2] mapEnter` portent activation, map, raison et type de
  résultat ;
- les compteurs/getters de test n'incrémentent que pour un résultat réellement
  terminé (`LegacyFallback`, `V2Handled`, `ClaimedIneligible`, `NoFallback`) ;
- `Failed`, `AuthorityBlocked`, `Stale` et `Duplicate` ne mentent pas en étant
  comptés comme activations dispatchées ;
- le rollback structurel du diff consiste à retirer les quatre fichiers
  application, les exports et la composition `PlayableMapGame`, puis restaurer
  les appels legacy directs. Aucune opération Git de rollback n'a été exécutée.

## 13. Auto-critique finale

### Points solides

- l'identité d'activation rend les courses visibles et testables ;
- l'autorité V2/legacy reste unique ;
- l'ordre saveRestore/outbox/mapEnter est prouvé avec états A/B/C ;
- les échecs et les activations stale sont fail-closed ;
- les reviews ont réellement trouvé quatre défauts production et sept
  régressions de fixtures avant la clôture ;
- full tests, analyzes, smokes et build sont frais après le dernier correctif.

### Ce qui pourrait être amélioré plus tard

- le snapshot charge et canonicalise tout le corpus maps hors `legacyOnly` ;
  un cache/version fingerprint plus fin pourra devenir nécessaire sur de gros
  projets ;
- `beforeNarrativeAuthorityPreparation` et les getters debug exposent des seams
  publics marqués `@visibleForTesting` ; une boundary test dédiée réduirait la
  surface ;
- un repository injecté ne partage le gate du runtime que si l'appelant injecte
  aussi le même `NarrativeRuntimeActivityGate` ;
- le rebase combat est testé au niveau contrat, pas encore avec un overlay de
  combat production complet dans une Golden Slice Event V2 ;
- le boot détaché ne modélise pas l'annulation lors d'une destruction très
  précoce du composant ;
- un input envoyé dans la très courte fenêtre boot in-flight est volontairement
  consommé/bloqué, pas mis en queue.

## 14. Risques et limites restantes

1. **FG-014 — rollback load destructif.** Après le début de la phase destructive,
   une erreur peut laisser l'état restauré en mémoire malgré `loadGame() == false`.
   V2-19 ne prétend pas corriger ce contrat.
2. **V2-22 — atomicité hosted battle complète.** Le write-back combat est
   conservé sur succès ; l'abandon total des effets host si la Scene parente
   échoue ensuite n'est pas garanti par ce lot.
3. **Outcome bridge.** Le drain restore satisfait ADR-EV2-015 mais ne ferme pas
   le bridge général `outcomeReceived`.
4. **Performance snapshot.** Le coût mémoire/démarrage doit être mesuré sur un
   projet multi-maps important avant release.
5. **Gate repository custom.** Une composition custom incohérente peut contourner
   le partage du gate ; la composition standard est correcte.

## 15. État Git final avant remise

```text
Branche : main
HEAD : 2f68328a38bf218c843e497940f8dd24a7a9c194
Roadmap : non modifiée
Git write : aucun
Fichiers tracked modifiés : 11
Fichiers source/test créés : 12
Rapport créé : 1
git diff --check : exit 0, aucun output
```

L'état détaillé final est volontairement sale : il contient uniquement le lot
non commité et son Evidence Pack. Aucun fichier utilisateur préexistant n'était
modifié au Gate 0 et aucun `git add`, commit, push, branch, stash, reset, restore
ou checkout n'a été exécuté.

## 16. Contenu complet des fichiers créés

Les sections suivantes reproduisent intégralement les douze fichiers source et
test créés par le lot, conformément à `codex_rule.md`.

Une extraction `awk` de chaque fence suivie d'un `diff -u` contre son fichier
canonique a retourné exit 0 pour les douze annexes.

### 16.1 `packages/map_runtime/lib/src/application/map_activation.dart`

````dart
import 'package:map_core/map_core.dart';

/// Runtime-only reason for a successfully completed map activation.
///
/// This metadata deliberately stays outside [NarrativeEventOccurrence]: Event
/// V2 source identity is only the canonical map-enter source.
enum MapActivationReason {
  initialBoot,
  warp,
  connection,
  saveRestore,
}

/// Identifies one completed runtime activation of a map.
final class MapActivation {
  MapActivation({
    required String activationId,
    required String mapId,
    required this.reason,
  })  : activationId = _requireNonBlank(activationId, 'activationId'),
        mapId = _requireNonBlank(mapId, 'mapId');

  final String activationId;
  final String mapId;
  final MapActivationReason reason;

  NarrativeEventOccurrence get occurrence => NarrativeEventOccurrence(
        source: NarrativeEventSourceRef.mapEnter(mapId),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapActivation &&
          other.activationId == activationId &&
          other.mapId == mapId &&
          other.reason == reason;

  @override
  int get hashCode => Object.hash(activationId, mapId, reason);
}

String _requireNonBlank(String value, String name) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, name, 'must not be blank');
  }
  return value;
}
````

### 16.2 `packages/map_runtime/lib/src/application/map_enter_production_dispatch_bridge.dart`

````dart
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import 'map_activation.dart';

sealed class MapEnterProductionDispatchResult {
  const MapEnterProductionDispatchResult(this.activation);

  final MapActivation activation;
}

final class MapEnterProductionDispatchLegacyFallback
    extends MapEnterProductionDispatchResult {
  const MapEnterProductionDispatchLegacyFallback(super.activation);
}

final class MapEnterProductionDispatchDuplicate
    extends MapEnterProductionDispatchResult {
  const MapEnterProductionDispatchDuplicate(super.activation);
}

final class MapEnterProductionDispatchNoFallback
    extends MapEnterProductionDispatchResult {
  const MapEnterProductionDispatchNoFallback(
    super.activation, [
    this.reason,
  ]);

  final Object? reason;
}

final class MapEnterProductionDispatchV2Handled
    extends MapEnterProductionDispatchResult {
  const MapEnterProductionDispatchV2Handled(
    super.activation,
    this.execution,
  );

  final NarrativeEventExecutionSucceeded execution;
}

final class MapEnterProductionDispatchClaimedIneligible
    extends MapEnterProductionDispatchResult {
  const MapEnterProductionDispatchClaimedIneligible(
    super.activation,
    this.execution,
  );

  final NarrativeEventExecutionClaimedButIneligible execution;
}

final class MapEnterProductionDispatchStale
    extends MapEnterProductionDispatchResult {
  const MapEnterProductionDispatchStale(super.activation);
}

final class MapEnterProductionDispatchAuthorityBlocked
    extends MapEnterProductionDispatchResult {
  const MapEnterProductionDispatchAuthorityBlocked(
    super.activation,
    this.authority,
  );

  final NarrativeEventDispatchAuthorityBlocked authority;
}

final class MapEnterProductionDispatchFailed
    extends MapEnterProductionDispatchResult {
  const MapEnterProductionDispatchFailed(
    super.activation,
    this.failure, [
    this.stackTrace,
  ]);

  final Object failure;
  final StackTrace? stackTrace;
}

/// Application boundary between completed map activations and Event V2.
///
/// V2-19 owns map-enter dispatch and runtime activation deduplication. Outcome
/// reentrancy stays in V2-22, while save/load orchestration remains FG-014; the
/// save-restore callback here is only the ordering seam between those lots.
final class MapEnterProductionDispatchBridge {
  MapEnterProductionDispatchBridge({
    required NarrativeEventStateTransactions stateTransactions,
    required GameState Function() currentGameState,
    required void Function(GameState gameState) onGameStateCommitted,
    required Future<NarrativeEventDispatchAuthorityPreparation> Function(
      MapActivation activation,
      NarrativeEventOccurrence occurrence,
    ) prepareAuthority,
    required NarrativeSceneExecutionCallback executeScene,
    required Future<void> Function(
      MapActivation activation,
      NarrativeEventOccurrence occurrence,
      GameState gameState,
    ) legacyFallback,
    required NarrativeEventActivityPort activityPort,
    required Future<void> Function(MapActivation activation)
        beforeSaveRestoreDispatch,
    required bool Function(String activationId) isCurrentActivation,
    required NarrativeExecutionIdFactory executionIdFactory,
    required NarrativeCorrelationIdFactory correlationIdFactory,
    required NarrativeDeliveryIdFactory deliveryIdFactory,
  })  : _stateTransactions = stateTransactions,
        _currentGameState = currentGameState,
        _onGameStateCommitted = onGameStateCommitted,
        _prepareAuthority = prepareAuthority,
        _executeScene = executeScene,
        _legacyFallback = legacyFallback,
        _activityPort = activityPort,
        _beforeSaveRestoreDispatch = beforeSaveRestoreDispatch,
        _isCurrentActivation = isCurrentActivation,
        _executionIdFactory = executionIdFactory,
        _correlationIdFactory = correlationIdFactory,
        _deliveryIdFactory = deliveryIdFactory;

  final NarrativeEventStateTransactions _stateTransactions;
  final GameState Function() _currentGameState;
  final void Function(GameState gameState) _onGameStateCommitted;
  final Future<NarrativeEventDispatchAuthorityPreparation> Function(
    MapActivation activation,
    NarrativeEventOccurrence occurrence,
  ) _prepareAuthority;
  final NarrativeSceneExecutionCallback _executeScene;
  final Future<void> Function(
    MapActivation activation,
    NarrativeEventOccurrence occurrence,
    GameState gameState,
  ) _legacyFallback;
  final NarrativeEventActivityPort _activityPort;
  final Future<void> Function(MapActivation activation)
      _beforeSaveRestoreDispatch;
  final bool Function(String activationId) _isCurrentActivation;
  final NarrativeExecutionIdFactory _executionIdFactory;
  final NarrativeCorrelationIdFactory _correlationIdFactory;
  final NarrativeDeliveryIdFactory _deliveryIdFactory;

  // add() happens before the first await, so concurrent callers in the same
  // isolate cannot both claim the same completed activation.
  final Set<String> _claimedActivationIds = <String>{};

  Future<MapEnterProductionDispatchResult> dispatchCompletedActivation(
    MapActivation activation,
  ) async {
    late final String activationId;
    late final NarrativeEventOccurrence occurrence;
    try {
      activationId = activation.activationId;
      occurrence = activation.occurrence;

      // Only the current activation needs to stay claimed. This keeps the set
      // bounded across map transitions while retaining the current ID so a
      // concurrent or repeated dispatch remains a duplicate.
      _claimedActivationIds.removeWhere(
        (claimedId) => !_isCurrentActivation(claimedId),
      );
      if (!_isCurrentActivation(activationId)) {
        return _stale(activation, activationId);
      }
      if (!_claimedActivationIds.add(activationId)) {
        return MapEnterProductionDispatchDuplicate(activation);
      }

      // The runtime GameState is authoritative at activation completion. Put
      // that exact snapshot behind the serialized F1 transaction boundary
      // before planning or executing Event V2.
      await _stateTransactions.transact<GameState>((_) {
        final current = _currentGameState();
        return NarrativeEventStateTransaction.commit(current, current);
      });
      if (!_isCurrentActivation(activationId)) {
        return _stale(activation, activationId);
      }

      if (activation.reason == MapActivationReason.saveRestore) {
        await _beforeSaveRestoreDispatch(activation);
        if (!_isCurrentActivation(activationId)) {
          return _stale(activation, activationId);
        }
        final latestGameState = await _stateTransactions.read();
        if (!_isCurrentActivation(activationId)) {
          return _stale(activation, activationId);
        }
        _onGameStateCommitted(latestGameState);
        if (!_isCurrentActivation(activationId)) {
          return _stale(activation, activationId);
        }
      }

      final preparation = await _prepareAuthority(activation, occurrence);
      if (!_isCurrentActivation(activationId)) {
        return _stale(activation, activationId);
      }
      if (preparation is NarrativeEventDispatchAuthorityBlocked) {
        return MapEnterProductionDispatchAuthorityBlocked(
          activation,
          preparation,
        );
      }
      final authority = preparation as NarrativeEventDispatchAuthorityReady;
      final coordinator = NarrativeEventExecutionCoordinator(
        stateTransactions: _stateTransactions,
        planner: NarrativeEventDispatchPlanner(),
        executeScene: (request) async {
          if (!_isCurrentActivation(activationId)) {
            return NarrativeSceneExecutionResult.cancelled(
              'Map activation became stale before Scene execution.',
            );
          }
          final result = await _executeScene(request);
          if (!_isCurrentActivation(activationId)) {
            return NarrativeSceneExecutionResult.cancelled(
              'Map activation became stale during Scene execution.',
            );
          }
          return result;
        },
        activityPort: _activityPort,
        executionIdFactory: _executionIdFactory,
        correlationIdFactory: _correlationIdFactory,
        deliveryIdFactory: _deliveryIdFactory,
      );
      final execution = await coordinator.execute(authority: authority);
      if (!_isCurrentActivation(activationId)) {
        return _stale(activation, activationId);
      }

      if (execution is NarrativeEventExecutionSucceeded) {
        _onGameStateCommitted(execution.updatedGameState);
        return MapEnterProductionDispatchV2Handled(activation, execution);
      }
      if (execution is NarrativeEventExecutionClaimedButIneligible) {
        return MapEnterProductionDispatchClaimedIneligible(
          activation,
          execution,
        );
      }
      if (execution is NarrativeEventExecutionFailed) {
        return MapEnterProductionDispatchFailed(
          activation,
          execution.failure,
          execution.failure.stackTrace,
        );
      }
      if (execution is NarrativeEventExecutionCancelled) {
        return MapEnterProductionDispatchNoFallback(activation, execution);
      }

      final noMatch = execution as NarrativeEventExecutionNoMatch;
      if (!noMatch.legacyFallbackAllowed) {
        return MapEnterProductionDispatchNoFallback(activation, noMatch);
      }

      final gameState = await _stateTransactions.read();
      if (!_isCurrentActivation(activationId)) {
        return _stale(activation, activationId);
      }
      await _legacyFallback(activation, occurrence, gameState);
      if (!_isCurrentActivation(activationId)) {
        return _stale(activation, activationId);
      }
      return MapEnterProductionDispatchLegacyFallback(activation);
    } catch (error, stackTrace) {
      // Preparation, pre-hooks, callbacks and legacy failures all stay closed:
      // no secondary dispatch path is attempted after an infrastructure error.
      return MapEnterProductionDispatchFailed(activation, error, stackTrace);
    }
  }

  MapEnterProductionDispatchStale _stale(
    MapActivation activation,
    String activationId,
  ) {
    _claimedActivationIds.remove(activationId);
    return MapEnterProductionDispatchStale(activation);
  }
}
````

### 16.3 `packages/map_runtime/lib/src/application/narrative_event_runtime_snapshot.dart`

````dart
import 'package:map_core/map_core.dart';

/// Immutable Event V2 runtime view built from one project/map corpus.
///
/// The runtime deliberately refuses to combine maps loaded from a different
/// manifest revision. That keeps the registry, catalog and legacy-claim
/// evidence on the same authority snapshot.
final class NarrativeEventRuntimeSnapshot {
  const NarrativeEventRuntimeSnapshot._({
    required this.project,
    required this.mapsById,
    required this.registryResult,
    required this.factResolver,
    required this.projectCatalog,
    required this.legacyClaimIndex,
  });

  final ProjectManifest project;
  final Map<String, MapData> mapsById;
  final EventRegistryDecodeResult registryResult;
  final NarrativeFactRuntimeResolver factResolver;
  final NarrativeEventProjectCatalog projectCatalog;
  final ValidatedLegacyClaimIndex legacyClaimIndex;

  static Future<NarrativeEventRuntimeSnapshot> build({
    required ProjectManifest project,
    required Future<({ProjectManifest project, MapData map})> Function(
      String mapId,
    ) loadMap,
  }) async {
    final registry = project.eventRegistry ??
        NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.legacyOnly,
          records: const [],
          legacyClaims: const [],
        );
    final structuralClaimIndex = buildValidatedLegacyClaimIndex(registry);
    final registryResult = project.eventRegistry == null
        ? EventRegistryDecodeResult.absent()
        : EventRegistryDecodeResult.decoded(registry);
    final factResolver = NarrativeFactRuntimeResolver.fromFacts(project.facts);
    if (registry.mode == EventSystemMode.legacyOnly) {
      return NarrativeEventRuntimeSnapshot._(
        project: project,
        mapsById: const <String, MapData>{},
        registryResult: registryResult,
        factResolver: factResolver,
        projectCatalog: buildNarrativeEventProjectCatalog(
          project: project,
          maps: const <MapData>[],
        ),
        legacyClaimIndex: structuralClaimIndex,
      );
    }
    final projectFingerprint = canonicalizeNarrativeEventJson(project.toJson());
    final mapsById = <String, MapData>{};

    for (final mapEntry in project.maps) {
      if (mapsById.containsKey(mapEntry.id)) {
        throw StateError(
          'Event V2 runtime snapshot contains duplicate map id '
          '"${mapEntry.id}".',
        );
      }
      final loaded = await loadMap(mapEntry.id);
      if (canonicalizeNarrativeEventJson(loaded.project.toJson()) !=
          projectFingerprint) {
        throw StateError(
          'Event V2 runtime snapshot changed while loading map '
          '"${mapEntry.id}".',
        );
      }
      if (loaded.map.id != mapEntry.id) {
        throw StateError(
          'Event V2 runtime snapshot expected map "${mapEntry.id}" but '
          'loaded "${loaded.map.id}".',
        );
      }
      mapsById[mapEntry.id] = loaded.map;
    }

    final legacyMapProjections = <LegacyMapEventProjection>[
      for (final map in mapsById.values)
        for (final event in map.events)
          projectLegacyMapEventReadOnly(
            mapId: map.id,
            map: map,
            event: event,
            claimIndex: structuralClaimIndex,
            rawEventJson: Map<String, Object?>.from(event.toJson()),
          ),
    ];
    final legacyScenarioProjections = <LegacyScenarioSourceProjection>[
      for (final scenario in project.scenarios)
        for (final node in scenario.nodes)
          if (isLegacyScenarioSourceNode(node))
            projectLegacyScenarioSourceReadOnly(
              scenario: scenario,
              node: node,
              scenes: project.scenes,
              claimIndex: structuralClaimIndex,
            ),
    ];
    final runtimeEvidence = LegacyClaimRuntimeEvidence(
      entries: [
        for (final projection in legacyMapProjections)
          if (projection.confirmedSource != null)
            LegacyClaimRuntimeEvidenceEntry(
              provenance: projection.provenance,
              source: projection.confirmedSource!,
              sourceFingerprint: projection.sourceFingerprint,
            ),
        for (final projection in legacyScenarioProjections)
          if (projection.source != null)
            LegacyClaimRuntimeEvidenceEntry(
              provenance: projection.provenance,
              source: projection.source!,
              sourceFingerprint: projection.sourceFingerprint,
            ),
      ],
    );
    final referencedOutcomes = <NarrativeOutcomeRef>[
      for (final projection in legacyScenarioProjections)
        if (projection.source != null)
          ...projection.source!.when(
            entityInteract: (_, __) => const <NarrativeOutcomeRef>[],
            triggerEnter: (_, __) => const <NarrativeOutcomeRef>[],
            mapEnter: (_) => const <NarrativeOutcomeRef>[],
            outcomeReceived: (outcome) => <NarrativeOutcomeRef>[outcome],
          ),
    ];
    final projectCatalog = buildNarrativeEventProjectCatalog(
      project: project,
      maps: mapsById.values.toList(growable: false),
      legacyProjections: legacyMapProjections,
      referencedOutcomes: referencedOutcomes,
    );

    return NarrativeEventRuntimeSnapshot._(
      project: project,
      mapsById: Map<String, MapData>.unmodifiable(mapsById),
      registryResult: registryResult,
      factResolver: factResolver,
      projectCatalog: projectCatalog,
      legacyClaimIndex: buildRuntimeValidatedLegacyClaimIndex(
        registry,
        runtimeEvidence: runtimeEvidence,
      ),
    );
  }
}
````

### 16.4 `packages/map_runtime/lib/src/application/narrative_scene_runtime_execution.dart`

````dart
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import 'scene_runtime/scene_consequence_runtime_writer.dart';
import 'scene_runtime/scene_runtime_host_callbacks.dart';

/// Executes the configured Event V2 Scene against the coordinator snapshot.
///
/// Consequences are buffered until the Scene completes. A failed Scene never
/// leaks a partial GameState update to the F1 transaction coordinator.
Future<NarrativeSceneExecutionResult> executeNarrativeEventScene({
  required NarrativeSceneExecutionRequest request,
  required ProjectManifest project,
  required Map<String, MapData> mapsById,
  required GameState Function() currentGameState,
  required SceneRuntimeHostCallbacks callbacks,
  int maxSteps = 100,
}) async {
  if (currentGameState() != request.gameState) {
    return NarrativeSceneExecutionResult.failed(
      StateError(
        'Event V2 Scene "${request.sceneId}" has an initial GameState '
        'conflict.',
      ),
    );
  }

  final matchingScenes = project.scenes
      .where((scene) => scene.id == request.sceneId)
      .toList(growable: false);
  if (matchingScenes.length != 1) {
    return NarrativeSceneExecutionResult.failed(
      StateError(
        matchingScenes.isEmpty
            ? 'Event V2 Scene "${request.sceneId}" was not found.'
            : 'Event V2 Scene "${request.sceneId}" is ambiguous.',
      ),
    );
  }
  final scene = matchingScenes.single;
  final diagnostics = diagnoseSceneAgainstProject(
    scene,
    project,
    mapsById: mapsById,
  );
  if (diagnostics.hasErrors) {
    return NarrativeSceneExecutionResult.failed(
      StateError(
        'Event V2 Scene "${request.sceneId}" has blocking diagnostics.',
      ),
    );
  }
  final planResult = buildSceneRuntimePlan(scene);
  if (!planResult.canBuild) {
    return NarrativeSceneExecutionResult.failed(
      StateError(
        'Event V2 Scene "${request.sceneId}" cannot build a runtime plan.',
      ),
    );
  }

  // Only Scene consequences are buffered for the coordinator transaction.
  // Host callbacks (battle/dialogue) own their runtime side effects; once the
  // Scene completes, those authoritative writes are kept by rebasing the
  // buffered consequences onto the latest host GameState.
  final pendingConsequences = <SceneConsequence>[];
  final execution = await SceneRuntimeExecutor(
    callbacks: callbacks.toExecutionCallbacks(
      applyConsequence: (consequence) {
        pendingConsequences.add(consequence);
        return 'completed';
      },
    ),
    maxSteps: maxSteps,
  ).execute(planResult.plan!);
  if (execution.status != SceneRuntimeExecutionStatus.completed) {
    return NarrativeSceneExecutionResult.failed(
      StateError(
        execution.message ??
            'Event V2 Scene "${request.sceneId}" failed during execution.',
      ),
    );
  }

  final writeResult = SceneConsequenceRuntimeWriter(
    project: project,
    mapsById: mapsById,
  ).applyAll(currentGameState(), pendingConsequences);
  if (!writeResult.success) {
    return NarrativeSceneExecutionResult.failed(
      StateError(
        writeResult.message ??
            'Event V2 Scene "${request.sceneId}" consequence commit failed.',
      ),
    );
  }

  final sceneOutcomeId = execution.sceneOutcomeId;
  return NarrativeSceneExecutionResult.completed(
    updatedGameState: writeResult.gameState,
    qualifiedOutcomes: sceneOutcomeId == null
        ? const <NarrativeOutcomeRef>[]
        : <NarrativeOutcomeRef>[
            NarrativeOutcomeRef(
              producerKind: NarrativeOutcomeProducerKind.scene,
              producerId: scene.id,
              outcomeId: sceneOutcomeId,
            ),
          ],
  );
}
````

### 16.5 `packages/map_runtime/test/narrative_event_runtime_snapshot_test.dart`

````dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/narrative_event_runtime_snapshot.dart';

void main() {
  test('legacyOnly snapshot never loads the project map corpus', () async {
    var loadCalls = 0;
    final project = ProjectManifest(
      name: 'Legacy-only lightweight snapshot',
      maps: const <ProjectMapEntry>[
        ProjectMapEntry(
          id: 'map_a',
          name: 'Map A',
          relativePath: 'maps/map_a.json',
        ),
        ProjectMapEntry(
          id: 'map_b',
          name: 'Map B',
          relativePath: 'maps/map_b.json',
        ),
      ],
      tilesets: const <ProjectTilesetEntry>[],
      eventRegistry: NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.legacyOnly,
        records: const [],
        legacyClaims: const [],
      ),
      surfaceCatalog: const ProjectSurfaceCatalog.empty(),
    );

    final snapshot = await NarrativeEventRuntimeSnapshot.build(
      project: project,
      loadMap: (_) async {
        loadCalls++;
        throw StateError('legacyOnly must not load maps');
      },
    );

    expect(loadCalls, 0);
    expect(snapshot.mapsById, isEmpty);
    expect(snapshot.registryResult.registryOrNull?.mode,
        EventSystemMode.legacyOnly);
  });
}
````

### 16.6 `packages/map_runtime/test/narrative_map_enter_production_dispatch_bridge_test.dart`

````dart
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

const _eventId = 'evt_019abcde-0000-7000-8000-000000000001';
const _executionId = 'evx_019abcde-0000-7000-8000-000000000002';
const _correlationId = 'corr_019abcde-0000-7000-8000-000000000003';
const _generatedDeliveryId = 'outd_019abcde-0000-7000-8000-000000000004';
const _firstPendingDeliveryId = 'outd_019abcde-0000-7000-8000-000000000005';
const _secondPendingDeliveryId = 'outd_019abcde-0000-7000-8000-000000000006';
const _legacyFingerprint =
    'sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

void main() {
  group('NS-EVENT-V2-19 map-enter production dispatch bridge', () {
    test('rejects empty and whitespace-only activation identities', () {
      for (final invalid in ['', ' ', '\t\n']) {
        expect(
          () => MapActivation(
            activationId: invalid,
            mapId: 'map',
            reason: MapActivationReason.initialBoot,
          ),
          throwsArgumentError,
        );
        expect(
          () => MapActivation(
            activationId: 'activation-valid',
            mapId: invalid,
            reason: MapActivationReason.initialBoot,
          ),
          throwsArgumentError,
        );
      }
    });

    test('all activation reasons keep runtime metadata and deduplicate by id',
        () async {
      for (final reason in MapActivationReason.values) {
        var currentState = const GameState(saveId: 'save');
        final transactions = NarrativeEventStateTransactions(currentState);
        final legacyTrace = <MapActivation>[];
        final activation = MapActivation(
          activationId: 'activation-${reason.name}',
          mapId: 'map-${reason.name}',
          reason: reason,
        );
        final bridge = _bridge(
          stateTransactions: transactions,
          currentGameState: () => currentState,
          onGameStateCommitted: (value) => currentState = value,
          prepareAuthority: (_, occurrence) async => _prepareAuthority(
            registry: _registry(EventSystemMode.legacyOnly),
            occurrence: occurrence,
          ),
          legacyFallback: (value, occurrence, gameState) async {
            expect(occurrence, value.occurrence);
            expect(gameState.saveId, 'save');
            legacyTrace.add(value);
          },
          isCurrentActivation: (value) => value == activation.activationId,
        );

        expect(
          activation.occurrence,
          NarrativeEventOccurrence(
            source: NarrativeEventSourceRef.mapEnter(activation.mapId),
          ),
        );

        final first = await bridge.dispatchCompletedActivation(activation);
        final duplicate = await bridge.dispatchCompletedActivation(activation);

        expect(first, isA<MapEnterProductionDispatchLegacyFallback>());
        expect(duplicate, isA<MapEnterProductionDispatchDuplicate>());
        expect(legacyTrace, [activation]);
      }
    });

    test('concurrent dispatches of one current activation execute once',
        () async {
      var currentState = const GameState(saveId: 'save');
      final transactions = NarrativeEventStateTransactions(currentState);
      final legacyStarted = Completer<void>();
      final releaseLegacy = Completer<void>();
      var legacyCalls = 0;
      final activation = MapActivation(
        activationId: 'activation-concurrent',
        mapId: 'map',
        reason: MapActivationReason.initialBoot,
      );
      final bridge = _bridge(
        stateTransactions: transactions,
        currentGameState: () => currentState,
        onGameStateCommitted: (value) => currentState = value,
        prepareAuthority: (_, occurrence) async => _prepareAuthority(
          registry: _registry(EventSystemMode.legacyOnly),
          occurrence: occurrence,
        ),
        legacyFallback: (_, __, ___) async {
          legacyCalls++;
          legacyStarted.complete();
          await releaseLegacy.future;
        },
        isCurrentActivation: (value) => value == activation.activationId,
      );

      final firstDispatch = bridge.dispatchCompletedActivation(activation);
      await legacyStarted.future;
      final secondResult = await bridge.dispatchCompletedActivation(activation);
      releaseLegacy.complete();
      final firstResult = await firstDispatch;

      expect(firstResult, isA<MapEnterProductionDispatchLegacyFallback>());
      expect(secondResult, isA<MapEnterProductionDispatchDuplicate>());
      expect(legacyCalls, 1);
    });

    test('legacyOnly falls back while v2Only no-match stays closed', () async {
      for (final testCase in <({
        EventSystemMode mode,
        int expectedLegacyCalls,
        Type expectedResult,
      })>[
        (
          mode: EventSystemMode.legacyOnly,
          expectedLegacyCalls: 1,
          expectedResult: MapEnterProductionDispatchLegacyFallback,
        ),
        (
          mode: EventSystemMode.v2Only,
          expectedLegacyCalls: 0,
          expectedResult: MapEnterProductionDispatchNoFallback,
        ),
      ]) {
        var currentState = const GameState(saveId: 'save');
        final transactions = NarrativeEventStateTransactions(currentState);
        var legacyCalls = 0;
        final activation = MapActivation(
          activationId: 'activation-authority-mode',
          mapId: 'map',
          reason: MapActivationReason.initialBoot,
        );
        final registry = _registry(testCase.mode);
        final bridge = _bridge(
          stateTransactions: transactions,
          currentGameState: () => currentState,
          onGameStateCommitted: (value) => currentState = value,
          prepareAuthority: (_, occurrence) async => _prepareAuthority(
            registry: registry,
            occurrence: occurrence,
          ),
          legacyFallback: (_, __, ___) async => legacyCalls++,
          isCurrentActivation: (value) => value == activation.activationId,
        );

        final result = await bridge.dispatchCompletedActivation(activation);

        expect(result.runtimeType, testCase.expectedResult);
        expect(legacyCalls, testCase.expectedLegacyCalls);
      }
    });

    test('dualRead handled event executes V2 and never invokes legacy',
        () async {
      var currentState = const GameState(saveId: 'save');
      final transactions = NarrativeEventStateTransactions(currentState);
      final source = NarrativeEventSourceRef.mapEnter('map');
      final registry = _registry(
        EventSystemMode.dualRead,
        records: [_record(source)],
      );
      var v2Calls = 0;
      var legacyCalls = 0;
      final activation = MapActivation(
        activationId: 'activation-dual-read-handled',
        mapId: 'map',
        reason: MapActivationReason.warp,
      );
      final bridge = _bridge(
        stateTransactions: transactions,
        currentGameState: () => currentState,
        onGameStateCommitted: (value) => currentState = value,
        prepareAuthority: (_, occurrence) async => _prepareAuthority(
          registry: registry,
          occurrence: occurrence,
          legacyClaimIndex: buildValidatedLegacyClaimIndex(registry),
        ),
        executeScene: (request) async {
          v2Calls++;
          expect(request.eventId, _eventId);
          return NarrativeSceneExecutionResult.completed(
            updatedGameState: request.gameState,
            qualifiedOutcomes: const [],
          );
        },
        legacyFallback: (_, __, ___) async => legacyCalls++,
        isCurrentActivation: (value) => value == activation.activationId,
      );

      final result = await bridge.dispatchCompletedActivation(activation);

      expect(result, isA<MapEnterProductionDispatchV2Handled>());
      expect(v2Calls, 1);
      expect(legacyCalls, 0);
    });

    test('stale activation during Scene rolls back its candidate state',
        () async {
      const originalState = GameState(
        saveId: 'save',
        metadata: {'runtime': 'original'},
      );
      var currentState = originalState;
      final transactions = NarrativeEventStateTransactions(currentState);
      final sceneStarted = Completer<void>();
      final releaseScene = Completer<void>();
      var currentActivationId = 'activation-stale-scene';
      var committedCalls = 0;
      var legacyCalls = 0;
      final source = NarrativeEventSourceRef.mapEnter('map');
      final registry = _registry(
        EventSystemMode.v2Only,
        records: [_record(source)],
      );
      final activation = MapActivation(
        activationId: 'activation-stale-scene',
        mapId: 'map',
        reason: MapActivationReason.warp,
      );
      final bridge = _bridge(
        stateTransactions: transactions,
        currentGameState: () => currentState,
        onGameStateCommitted: (value) {
          committedCalls++;
          currentState = value;
        },
        prepareAuthority: (_, occurrence) async => _prepareAuthority(
          registry: registry,
          occurrence: occurrence,
        ),
        executeScene: (request) async {
          sceneStarted.complete();
          await releaseScene.future;
          return NarrativeSceneExecutionResult.completed(
            updatedGameState: request.gameState.copyWith(
              metadata: const {'scene': 'must-not-commit'},
            ),
            qualifiedOutcomes: const [],
          );
        },
        legacyFallback: (_, __, ___) async => legacyCalls++,
        isCurrentActivation: (value) => value == currentActivationId,
      );

      final dispatch = bridge.dispatchCompletedActivation(activation);
      await sceneStarted.future;
      currentActivationId = 'activation-newer';
      releaseScene.complete();
      final result = await dispatch;

      expect(result, isA<MapEnterProductionDispatchStale>());
      expect(await transactions.read(), originalState);
      expect(currentState, originalState);
      expect(committedCalls, 0);
      expect(legacyCalls, 0);
    });

    test('claimed but ineligible dualRead event never falls back', () async {
      var currentState = const GameState(saveId: 'save');
      final transactions = NarrativeEventStateTransactions(currentState);
      final source = NarrativeEventSourceRef.mapEnter('map');
      final provenance = LegacySourceRef.mapEvent('map', 'legacy-map-enter');
      final registry = _registry(
        EventSystemMode.dualRead,
        records: [_record(source, enabled: false)],
        claims: [_claim(source, provenance)],
      );
      var v2Calls = 0;
      var legacyCalls = 0;
      final activation = MapActivation(
        activationId: 'activation-claimed-ineligible',
        mapId: 'map',
        reason: MapActivationReason.connection,
      );
      final bridge = _bridge(
        stateTransactions: transactions,
        currentGameState: () => currentState,
        onGameStateCommitted: (value) => currentState = value,
        prepareAuthority: (_, __) async => _prepareAuthority(
          registry: registry,
          occurrence: NarrativeEventOccurrence(
            source: source,
            provenance: provenance,
          ),
          legacyClaimIndex: buildRuntimeValidatedLegacyClaimIndex(
            registry,
            runtimeEvidence: LegacyClaimRuntimeEvidence(
              entries: [
                LegacyClaimRuntimeEvidenceEntry(
                  provenance: provenance,
                  source: source,
                  sourceFingerprint: _legacyFingerprint,
                ),
              ],
            ),
          ),
        ),
        executeScene: (request) async {
          v2Calls++;
          return NarrativeSceneExecutionResult.completed(
            updatedGameState: request.gameState,
            qualifiedOutcomes: const [],
          );
        },
        legacyFallback: (_, __, ___) async => legacyCalls++,
        isCurrentActivation: (value) => value == activation.activationId,
      );

      final result = await bridge.dispatchCompletedActivation(activation);

      expect(result, isA<MapEnterProductionDispatchClaimedIneligible>());
      expect(v2Calls, 0);
      expect(legacyCalls, 0);
    });

    test('blocked or failing authority preparation stays fail-closed',
        () async {
      for (final throwsDuringPreparation in [false, true]) {
        var currentState = const GameState(saveId: 'save');
        final transactions = NarrativeEventStateTransactions(currentState);
        var legacyCalls = 0;
        final activation = MapActivation(
          activationId:
              'activation-authority-${throwsDuringPreparation ? 'error' : 'blocked'}',
          mapId: 'map',
          reason: MapActivationReason.initialBoot,
        );
        final bridge = _bridge(
          stateTransactions: transactions,
          currentGameState: () => currentState,
          onGameStateCommitted: (value) => currentState = value,
          prepareAuthority: (_, __) async {
            if (throwsDuringPreparation) {
              throw StateError('authority preparation failed');
            }
            return NarrativeEventDispatchAuthorityBlocked(
              reason:
                  NarrativeEventDispatchAuthorityBlockReason.invalidRegistry,
              diagnostics: const ['blocked fixture'],
            );
          },
          legacyFallback: (_, __, ___) async => legacyCalls++,
          isCurrentActivation: (value) => value == activation.activationId,
        );

        final result = await bridge.dispatchCompletedActivation(activation);

        expect(
          result.runtimeType,
          throwsDuringPreparation
              ? MapEnterProductionDispatchFailed
              : MapEnterProductionDispatchAuthorityBlocked,
        );
        expect(legacyCalls, 0);
      }
    });

    test('failed or cancelled Scene rolls back without legacy fallback',
        () async {
      for (final testCase in <({
        NarrativeSceneExecutionResult sceneResult,
        Type expectedResult,
      })>[
        (
          sceneResult: NarrativeSceneExecutionResult.failed('scene failed'),
          expectedResult: MapEnterProductionDispatchFailed,
        ),
        (
          sceneResult:
              NarrativeSceneExecutionResult.cancelled('scene cancelled'),
          expectedResult: MapEnterProductionDispatchNoFallback,
        ),
      ]) {
        const originalState = GameState(
          saveId: 'save',
          metadata: {'runtime': 'original'},
        );
        var currentState = originalState;
        final transactions = NarrativeEventStateTransactions(currentState);
        final source = NarrativeEventSourceRef.mapEnter('map');
        final registry = _registry(
          EventSystemMode.v2Only,
          records: [_record(source)],
        );
        var committedCalls = 0;
        var legacyCalls = 0;
        final activation = MapActivation(
          activationId: 'activation-scene-${testCase.expectedResult}',
          mapId: 'map',
          reason: MapActivationReason.initialBoot,
        );
        final bridge = _bridge(
          stateTransactions: transactions,
          currentGameState: () => currentState,
          onGameStateCommitted: (value) {
            committedCalls++;
            currentState = value;
          },
          prepareAuthority: (_, occurrence) async => _prepareAuthority(
            registry: registry,
            occurrence: occurrence,
          ),
          executeScene: (_) async => testCase.sceneResult,
          legacyFallback: (_, __, ___) async => legacyCalls++,
          isCurrentActivation: (value) => value == activation.activationId,
        );

        final result = await bridge.dispatchCompletedActivation(activation);

        expect(result.runtimeType, testCase.expectedResult);
        expect(await transactions.read(), originalState);
        expect(currentState, originalState);
        expect(committedCalls, 0);
        expect(legacyCalls, 0);
      }
    });

    test('saveRestore drains the real F1 outbox FIFO before mapEnter',
        () async {
      final trace = <String>[];
      GameState? legacyGameState;
      var currentState = GameState(
        saveId: 'save',
        narrativeEventProgress: NarrativeEventProgress(
          pendingNarrativeOutcomeDeliveries: [
            _pendingDelivery(
              _firstPendingDeliveryId,
              producerId: 'restore',
              outcomeId: 'first',
            ),
            _pendingDelivery(
              _secondPendingDeliveryId,
              producerId: 'restore',
              outcomeId: 'second',
            ),
          ],
        ),
      );
      final transactions = NarrativeEventStateTransactions(currentState);
      final activityPort = NoopNarrativeEventActivityPort();
      final processor = NarrativeOutcomeOutboxProcessor(
        stateTransactions: transactions,
        activityPort: activityPort,
        dispatcher: (request) async {
          trace.add('outcome:${request.delivery.outcome.outcomeId}');
          return NarrativeOutcomeDispatchResult.delivered(
            updatedGameState: request.gameState,
          );
        },
        deliveryIdFactory: () => _generatedDeliveryId,
      );
      final activation = MapActivation(
        activationId: 'activation-save-restore',
        mapId: 'map',
        reason: MapActivationReason.saveRestore,
      );
      final bridge = _bridge(
        stateTransactions: transactions,
        currentGameState: () => currentState,
        onGameStateCommitted: (value) => currentState = value,
        prepareAuthority: (_, occurrence) async => _prepareAuthority(
          registry: _registry(EventSystemMode.legacyOnly),
          occurrence: occurrence,
        ),
        legacyFallback: (_, __, gameState) async {
          legacyGameState = gameState;
          trace.add('mapEnter:saveRestore');
        },
        activityPort: activityPort,
        beforeSaveRestoreDispatch: (_) async {
          while (true) {
            final result = await processor.processNext();
            if (result is NarrativeOutcomeOutboxEmpty) {
              return;
            }
            expect(result, isA<NarrativeOutcomeOutboxDelivered>());
          }
        },
        isCurrentActivation: (value) => value == activation.activationId,
      );

      final result = await bridge.dispatchCompletedActivation(activation);
      final latestTransactionalState = await transactions.read();

      expect(result, isA<MapEnterProductionDispatchLegacyFallback>());
      expect(
        trace,
        ['outcome:first', 'outcome:second', 'mapEnter:saveRestore'],
      );
      expect(
        latestTransactionalState
            .narrativeEventProgress.pendingNarrativeOutcomeDeliveries,
        isEmpty,
      );
      expect(currentState, latestTransactionalState);
      expect(legacyGameState, latestTransactionalState);
    });

    test('newer activation suppresses stale saveRestore after async prehook',
        () async {
      var currentState = const GameState(saveId: 'save');
      final transactions = NarrativeEventStateTransactions(currentState);
      final hookStarted = Completer<void>();
      final releaseHook = Completer<void>();
      var currentActivationId = 'activation-stale-restore';
      var authorityCalls = 0;
      var v2Calls = 0;
      var legacyCalls = 0;
      final activation = MapActivation(
        activationId: 'activation-stale-restore',
        mapId: 'map',
        reason: MapActivationReason.saveRestore,
      );
      final bridge = _bridge(
        stateTransactions: transactions,
        currentGameState: () => currentState,
        onGameStateCommitted: (value) => currentState = value,
        prepareAuthority: (_, occurrence) async {
          authorityCalls++;
          return _prepareAuthority(
            registry: _registry(EventSystemMode.legacyOnly),
            occurrence: occurrence,
          );
        },
        executeScene: (request) async {
          v2Calls++;
          return NarrativeSceneExecutionResult.completed(
            updatedGameState: request.gameState,
            qualifiedOutcomes: const [],
          );
        },
        legacyFallback: (_, __, ___) async => legacyCalls++,
        beforeSaveRestoreDispatch: (_) async {
          hookStarted.complete();
          await releaseHook.future;
        },
        isCurrentActivation: (value) => value == currentActivationId,
      );

      final dispatch = bridge.dispatchCompletedActivation(activation);
      await hookStarted.future;
      currentActivationId = 'activation-newer-warp';
      releaseHook.complete();
      final result = await dispatch;

      expect(result, isA<MapEnterProductionDispatchStale>());
      expect(authorityCalls, 0);
      expect(v2Calls, 0);
      expect(legacyCalls, 0);
    });

    test('newer activation marks an awaited legacy fallback stale', () async {
      var currentState = const GameState(saveId: 'save');
      final transactions = NarrativeEventStateTransactions(currentState);
      final legacyStarted = Completer<void>();
      final releaseLegacy = Completer<void>();
      var currentActivationId = 'activation-stale-legacy';
      var legacyCalls = 0;
      final activation = MapActivation(
        activationId: 'activation-stale-legacy',
        mapId: 'map',
        reason: MapActivationReason.initialBoot,
      );
      final bridge = _bridge(
        stateTransactions: transactions,
        currentGameState: () => currentState,
        onGameStateCommitted: (value) => currentState = value,
        prepareAuthority: (_, occurrence) async => _prepareAuthority(
          registry: _registry(EventSystemMode.legacyOnly),
          occurrence: occurrence,
        ),
        legacyFallback: (_, __, ___) async {
          legacyCalls++;
          legacyStarted.complete();
          await releaseLegacy.future;
        },
        isCurrentActivation: (value) => value == currentActivationId,
      );

      final dispatch = bridge.dispatchCompletedActivation(activation);
      await legacyStarted.future;
      currentActivationId = 'activation-newer';
      releaseLegacy.complete();
      final result = await dispatch;

      expect(result, isA<MapEnterProductionDispatchStale>());
      expect(legacyCalls, 1);
    });

    test('stale attempts are unclaimed while the current id stays claimed',
        () async {
      var currentState = const GameState(saveId: 'save');
      final transactions = NarrativeEventStateTransactions(currentState);
      var currentActivationId = 'activation-a';
      final legacyTrace = <String>[];
      final bridge = _bridge(
        stateTransactions: transactions,
        currentGameState: () => currentState,
        onGameStateCommitted: (value) => currentState = value,
        prepareAuthority: (_, occurrence) async => _prepareAuthority(
          registry: _registry(EventSystemMode.legacyOnly),
          occurrence: occurrence,
        ),
        legacyFallback: (activation, _, __) async {
          legacyTrace.add(activation.activationId);
        },
        isCurrentActivation: (value) => value == currentActivationId,
      );
      final activationA = MapActivation(
        activationId: 'activation-a',
        mapId: 'map-a',
        reason: MapActivationReason.initialBoot,
      );
      final activationB = MapActivation(
        activationId: 'activation-b',
        mapId: 'map-b',
        reason: MapActivationReason.warp,
      );
      final staleActivation = MapActivation(
        activationId: 'activation-stale',
        mapId: 'map-stale',
        reason: MapActivationReason.connection,
      );

      expect(
        await bridge.dispatchCompletedActivation(activationA),
        isA<MapEnterProductionDispatchLegacyFallback>(),
      );
      currentActivationId = activationB.activationId;
      expect(
        await bridge.dispatchCompletedActivation(activationB),
        isA<MapEnterProductionDispatchLegacyFallback>(),
      );
      expect(
        await bridge.dispatchCompletedActivation(staleActivation),
        isA<MapEnterProductionDispatchStale>(),
      );
      expect(
        await bridge.dispatchCompletedActivation(staleActivation),
        isA<MapEnterProductionDispatchStale>(),
      );
      expect(
        await bridge.dispatchCompletedActivation(activationB),
        isA<MapEnterProductionDispatchDuplicate>(),
      );
      expect(legacyTrace, ['activation-a', 'activation-b']);
    });

    test('current activation lookup exception fails closed before claim',
        () async {
      var authorityCalls = 0;
      var legacyCalls = 0;
      final bridge = _bridge(
        stateTransactions: NarrativeEventStateTransactions(
          const GameState(saveId: 'save'),
        ),
        currentGameState: () => const GameState(saveId: 'save'),
        onGameStateCommitted: (_) {},
        prepareAuthority: (_, occurrence) async {
          authorityCalls++;
          return _prepareAuthority(
            registry: _registry(EventSystemMode.legacyOnly),
            occurrence: occurrence,
          );
        },
        legacyFallback: (_, __, ___) async => legacyCalls++,
        isCurrentActivation: (_) => throw StateError('current lookup failed'),
      );
      final activation = MapActivation(
        activationId: 'activation-current-error',
        mapId: 'map',
        reason: MapActivationReason.initialBoot,
      );

      final result = await bridge.dispatchCompletedActivation(activation);

      expect(result, isA<MapEnterProductionDispatchFailed>());
      expect(authorityCalls, 0);
      expect(legacyCalls, 0);
    });
  });
}

MapEnterProductionDispatchBridge _bridge({
  required NarrativeEventStateTransactions stateTransactions,
  required GameState Function() currentGameState,
  required void Function(GameState gameState) onGameStateCommitted,
  required Future<NarrativeEventDispatchAuthorityPreparation> Function(
    MapActivation activation,
    NarrativeEventOccurrence occurrence,
  ) prepareAuthority,
  required Future<void> Function(
    MapActivation activation,
    NarrativeEventOccurrence occurrence,
    GameState gameState,
  ) legacyFallback,
  required bool Function(String activationId) isCurrentActivation,
  NarrativeSceneExecutionCallback? executeScene,
  NarrativeEventActivityPort? activityPort,
  Future<void> Function(MapActivation activation)? beforeSaveRestoreDispatch,
}) {
  return MapEnterProductionDispatchBridge(
    stateTransactions: stateTransactions,
    currentGameState: currentGameState,
    onGameStateCommitted: onGameStateCommitted,
    prepareAuthority: prepareAuthority,
    executeScene: executeScene ??
        (request) async => NarrativeSceneExecutionResult.completed(
              updatedGameState: request.gameState,
              qualifiedOutcomes: const [],
            ),
    legacyFallback: legacyFallback,
    activityPort: activityPort ?? NoopNarrativeEventActivityPort(),
    beforeSaveRestoreDispatch: beforeSaveRestoreDispatch ?? (_) async {},
    isCurrentActivation: isCurrentActivation,
    executionIdFactory: () => _executionId,
    correlationIdFactory: () => _correlationId,
    deliveryIdFactory: () => _generatedDeliveryId,
  );
}

NarrativeEventDispatchAuthorityPreparation _prepareAuthority({
  required NarrativeEventRegistry registry,
  required NarrativeEventOccurrence occurrence,
  ValidatedLegacyClaimIndex? legacyClaimIndex,
}) {
  return NarrativeEventDispatchAuthority.prepare(
    registryResult: EventRegistryDecodeResult.decoded(registry),
    occurrence: occurrence,
    factResolver: NarrativeFactRuntimeResolver.fromFacts(const []),
    legacyClaimIndex: legacyClaimIndex,
    projectCatalog: _catalog(registry, occurrence.source),
  );
}

NarrativeEventRegistry _registry(
  EventSystemMode mode, {
  List<NarrativeEventRecord> records = const [],
  List<LegacySourceClaim> claims = const [],
}) {
  return NarrativeEventRegistry(
    schemaVersion: 1,
    mode: mode,
    records: records,
    legacyClaims: claims,
  );
}

NarrativeEventRecord _record(
  NarrativeEventSourceRef source, {
  bool enabled = true,
}) {
  return NarrativeEventRecord.configuredStructurallyUnchecked(
    NarrativeEventDefinition(
      id: _eventId,
      name: 'Map enter event',
      source: source,
      conditions: const [],
      sceneId: 'scene_map_enter',
      reusePolicy: NarrativeEventReusePolicy.reusable,
      priority: 0,
      order: 0,
    ),
    enabled: enabled,
  );
}

LegacySourceClaim _claim(
  NarrativeEventSourceRef source,
  LegacySourceRef provenance,
) {
  final member = LegacySourceClaimMember(
    provenance: provenance,
    sourceFingerprint: _legacyFingerprint,
  );
  final cohortId = computeLegacySourceCohortId(source, [provenance]);
  return LegacySourceClaim(
    cohortId: cohortId,
    source: source,
    members: [member],
    cohortFingerprint: computeLegacySourceCohortFingerprint(cohortId, [member]),
    targetEventIds: const [_eventId],
    migrationReceiptId: 'receipt',
  );
}

NarrativeEventProjectCatalog _catalog(
  NarrativeEventRegistry registry,
  NarrativeEventSourceRef source,
) {
  final mapId = source.when(
    entityInteract: (value, _) => value,
    triggerEnter: (value, _) => value,
    mapEnter: (value) => value,
    outcomeReceived: (_) => 'map',
  );
  final sceneIds = {
    for (final record in registry.records)
      if (record.definitionOrNull case final definition?) definition.sceneId,
  };
  final project = ProjectManifest(
    name: 'Map enter bridge fixture',
    maps: [
      ProjectMapEntry(
        id: mapId,
        name: mapId,
        relativePath: 'maps/$mapId.json',
      ),
    ],
    tilesets: const [],
    eventRegistry: registry,
    scenes: [for (final sceneId in sceneIds) _scene(sceneId)],
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
  return buildNarrativeEventProjectCatalog(
    project: project,
    maps: [
      MapData(
        id: mapId,
        name: mapId,
        size: const GridSize(width: 1, height: 1),
        layers: const [MapLayer.object(id: 'objects', name: 'Objects')],
      ),
    ],
  );
}

SceneAsset _scene(String id) {
  return SceneAsset.fromJson({
    'id': id,
    'name': id,
    'graph': const {
      'startNodeId': 'start',
      'nodes': [
        {'id': 'start', 'kind': 'start'},
        {'id': 'end', 'kind': 'end'},
      ],
      'edges': [
        {
          'id': 'edge',
          'fromNodeId': 'start',
          'fromPortId': 'completed',
          'toNodeId': 'end',
          'kind': 'default',
        },
      ],
    },
  });
}

NarrativeOutcomeDelivery _pendingDelivery(
  String deliveryId, {
  required String producerId,
  required String outcomeId,
}) {
  return NarrativeOutcomeDelivery(
    deliveryId: deliveryId,
    outcome: NarrativeOutcomeRef(
      producerKind: NarrativeOutcomeProducerKind.scene,
      producerId: producerId,
      outcomeId: outcomeId,
    ),
    causationExecutionId: _executionId,
    rootCorrelationId: _correlationId,
    depth: 0,
    attemptCount: 0,
  );
}
````

### 16.7 `packages/map_runtime/test/narrative_scene_runtime_execution_test.dart`

````dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/narrative_scene_runtime_execution.dart';

void main() {
  group('executeNarrativeEventScene', () {
    test('rebases buffered consequences onto host battle write-back', () async {
      const requestGameState = GameState(
        saveId: 'save_scene_runtime',
        party: PlayerParty(
          members: <PlayerPokemon>[
            PlayerPokemon(
              speciesId: 'sproutle',
              natureId: 'hardy',
              abilityId: 'overgrow',
              currentHp: 12,
            ),
          ],
        ),
      );
      var runtimeGameState = requestGameState;
      var battleCalls = 0;

      final result = await executeNarrativeEventScene(
        request: const NarrativeSceneExecutionRequest(
          eventId: 'event_scene_runtime',
          sceneId: 'scene_battle_then_fact',
          executionId: 'execution_scene_runtime',
          gameState: requestGameState,
        ),
        project: _project(),
        mapsById: const <String, MapData>{},
        currentGameState: () => runtimeGameState,
        callbacks: SceneRuntimeHostCallbacks(
          evaluateCondition: (_) => throw StateError('Unexpected condition.'),
          showDialogue: (_) => throw StateError('Unexpected dialogue.'),
          startBattle: (intent) {
            battleCalls++;
            expect(intent.trainerId, 'trainer_scene_runtime');
            runtimeGameState = runtimeGameState.copyWith(
              party: PlayerParty(
                members: <PlayerPokemon>[
                  runtimeGameState.party.members.single.copyWith(currentHp: 3),
                ],
              ),
              metadata: const <String, String>{
                'battleWriteBack': 'committed',
              },
            );
            return 'victory';
          },
          playCinematic: (_) => throw StateError('Unexpected cinematic.'),
        ),
      );

      expect(result, isA<NarrativeSceneExecutionCompleted>());
      final completed = result as NarrativeSceneExecutionCompleted;
      expect(battleCalls, 1);
      expect(completed.updatedGameState.party.members.single.currentHp, 3);
      expect(
        completed.updatedGameState.metadata['battleWriteBack'],
        'committed',
      );
      expect(
        completed.updatedGameState.storyFlags.activeFlags,
        contains('fact_scene_runtime_completed'),
      );
      expect(
        completed.updatedGameState.narrativeFactRuntimeState.overridesByFactId,
        containsPair('fact_scene_runtime_completed', true),
      );
    });

    test('fails closed on an initial GameState conflict before host callbacks',
        () async {
      const requestGameState = GameState(saveId: 'save_scene_runtime');
      final runtimeGameState = requestGameState.copyWith(
        metadata: const <String, String>{'newerRuntimeState': 'true'},
      );
      var hostCallbackCalls = 0;
      String unexpectedCallback(SceneRuntimePlanIntent _) {
        hostCallbackCalls++;
        return 'victory';
      }

      final result = await executeNarrativeEventScene(
        request: const NarrativeSceneExecutionRequest(
          eventId: 'event_scene_runtime',
          sceneId: 'scene_battle_then_fact',
          executionId: 'execution_scene_runtime',
          gameState: requestGameState,
        ),
        project: _project(),
        mapsById: const <String, MapData>{},
        currentGameState: () => runtimeGameState,
        callbacks: SceneRuntimeHostCallbacks(
          evaluateCondition: unexpectedCallback,
          showDialogue: unexpectedCallback,
          startBattle: unexpectedCallback,
          playCinematic: unexpectedCallback,
        ),
      );

      expect(result, isA<NarrativeSceneExecutionFailed>());
      final failed = result as NarrativeSceneExecutionFailed;
      expect(failed.failure, isA<StateError>());
      expect(failed.failure.toString(), contains('initial GameState conflict'));
      expect(hostCallbackCalls, 0);
    });
  });
}

ProjectManifest _project() {
  return ProjectManifest(
    name: 'Narrative Scene Runtime Execution Test',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    trainers: const <ProjectTrainerEntry>[
      ProjectTrainerEntry(
        id: 'trainer_scene_runtime',
        name: 'Runtime Trainer',
        trainerClass: 'Tester',
        team: <ProjectTrainerPokemonEntry>[
          ProjectTrainerPokemonEntry(speciesId: 'embercub', level: 5),
        ],
      ),
    ],
    facts: <NarrativeFactDefinition>[
      NarrativeFactDefinition(
        id: 'fact_scene_runtime_completed',
        label: 'Runtime scene completed',
      ),
    ],
    scenes: <SceneAsset>[_battleThenFactScene()],
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
  );
}

SceneAsset _battleThenFactScene() {
  return SceneAsset(
    id: 'scene_battle_then_fact',
    name: 'Battle then Fact',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: <SceneNode>[
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'battle',
          kind: SceneNodeKind.battle,
          payload: SceneBattlePayload(
            battleKind: 'trainer',
            trainerId: 'trainer_scene_runtime',
            declaredOutcomes: const <String>['victory', 'defeat'],
          ),
        ),
        SceneNode(
          id: 'set_fact',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.setFact(
              factId: 'fact_scene_runtime_completed',
              value: true,
            ),
          ),
        ),
        SceneNode(id: 'victory_end', kind: SceneNodeKind.end),
        SceneNode(id: 'defeat_end', kind: SceneNodeKind.end),
      ],
      edges: <SceneEdge>[
        SceneEdge(
          id: 'start_to_battle',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'battle',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'battle_victory_to_fact',
          fromNodeId: 'battle',
          fromPortId: 'victory',
          toNodeId: 'set_fact',
          kind: SceneEdgeKind.battleVictory,
        ),
        SceneEdge(
          id: 'fact_to_victory_end',
          fromNodeId: 'set_fact',
          fromPortId: 'completed',
          toNodeId: 'victory_end',
          kind: SceneEdgeKind.actionCompleted,
        ),
        SceneEdge(
          id: 'battle_defeat_to_end',
          fromNodeId: 'battle',
          fromPortId: 'defeat',
          toNodeId: 'defeat_end',
          kind: SceneEdgeKind.battleDefeat,
        ),
      ],
    ),
  );
}
````

### 16.8 `packages/map_runtime/test/playable_map_game_event_v2_boot_integration_test.dart`

````dart
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/dialogue_runtime_models.dart';

const _mapId = 'event_v2_boot_map';
const _eventId = 'evt_019abcde-1000-7000-8000-000000000001';
const _sceneId = 'scene_event_v2_boot';
const _factId = 'fact.event_v2.boot_scene_completed';
const _legacyFlag = 'test.event_v2.legacy_fallback_must_not_run';
const _dialogueEventId = 'evt_019abcde-1000-7000-8000-000000000002';
const _dialogueSceneId = 'scene_event_v2_boot_dialogue';
const _dialogueId = 'dialogue_event_v2_boot';
const _dialogueFactId = 'fact.event_v2.boot_dialogue_completed';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('v2Only mapEnter executes the real Scene and suppresses legacy',
      () async {
    final bundle = _bundle();
    final game = PlayableMapGame(
      bundle: bundle,
      projectFilePath: '/tmp/event_v2_boot/project.json',
    );

    game.onGameResize(Vector2(320, 240));
    await game.onLoad();
    await _waitForActivationDispatch(game);

    final state = game.gameStateSnapshot;
    expect(state.narrativeFactRuntimeState.overridesByFactId[_factId], isTrue);
    expect(
      state.narrativeEventProgress.consumedNarrativeEventIds,
      contains(_eventId),
      reason: 'The one-shot Event must be committed by the F1 coordinator.',
    );
    expect(
      state.storyFlags.activeFlags,
      isNot(contains(_legacyFlag)),
      reason: 'v2Only authority must never invoke the legacy Scenario.',
    );
    expect(game.debugCompletedMapActivationDispatchCount, 1);
    expect(
      game.debugLastCompletedMapActivation?.reason,
      MapActivationReason.initialBoot,
    );
  });

  test('dualRead validated ineligible claim suppresses legacy fallback',
      () async {
    final game = PlayableMapGame(
      bundle: _dualReadClaimedBundle(),
      projectFilePath: '/tmp/event_v2_dual_read/project.json',
    );

    game.onGameResize(Vector2(320, 240));
    await game.onLoad();
    await _waitForActivationDispatch(game);

    final state = game.gameStateSnapshot;
    expect(state.storyFlags.activeFlags, isNot(contains(_legacyFlag)));
    expect(
      state.narrativeFactRuntimeState.overridesByFactId,
      isNot(contains(_factId)),
      reason: 'The claimed Event is disabled and its Scene must not execute.',
    );
    expect(
      state.narrativeEventProgress.consumedNarrativeEventIds,
      isNot(contains(_eventId)),
    );
    expect(game.debugCompletedMapActivationDispatchCount, 1);
  });

  test('boot Scene dialogue starts after onLoad and remains interactive',
      () async {
    final game = _LifecycleTestPlayableMapGame(
      bundle: _dialogueBundle(),
      projectFilePath: '/tmp/event_v2_boot_dialogue/project.json',
      dialogueSessionLoader: (_) async => _singleLineDialogueSession(),
    );

    game.onGameResize(Vector2(320, 240));
    await game.onLoad().timeout(const Duration(seconds: 2));

    expect(game.debugIsMapActivationDispatchInFlight, isTrue);
    await _waitUntil(game, () => game.debugFlowPhaseName == 'dialogue');
    expect(game.debugCompletedMapActivationDispatchCount, 0);
    expect(
      game.gameStateSnapshot.narrativeEventProgress.consumedNarrativeEventIds,
      isNot(contains(_dialogueEventId)),
    );

    expect(
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.press(RuntimeInputControl.primary),
      ),
      isTrue,
    );
    await _waitForActivationDispatch(game);

    final state = game.gameStateSnapshot;
    expect(state.narrativeEventProgress.consumedNarrativeEventIds,
        contains(_dialogueEventId));
    expect(
      state.narrativeFactRuntimeState.overridesByFactId[_dialogueFactId],
      isTrue,
    );
    expect(game.debugCompletedMapActivationDispatchCount, 1);
    expect(
      game.debugLastCompletedMapActivation?.reason,
      MapActivationReason.initialBoot,
    );
  });
}

final class _LifecycleTestPlayableMapGame extends PlayableMapGame {
  _LifecycleTestPlayableMapGame({
    required super.bundle,
    required super.projectFilePath,
    required super.dialogueSessionLoader,
  });

  bool _onLoadCompleted = false;

  @override
  bool get isLoaded => _onLoadCompleted;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _onLoadCompleted = true;
  }
}

RuntimeMapBundle _bundle() {
  final scene = _scene();
  final registry = NarrativeEventRegistry(
    schemaVersion: 1,
    mode: EventSystemMode.v2Only,
    records: <NarrativeEventRecord>[
      _record(enabled: true),
    ],
    legacyClaims: const [],
  );
  return _bundleForRegistry(registry, scene);
}

RuntimeMapBundle _dialogueBundle() {
  final registry = NarrativeEventRegistry(
    schemaVersion: 1,
    mode: EventSystemMode.v2Only,
    records: <NarrativeEventRecord>[
      NarrativeEventRecord.configuredStructurallyUnchecked(
        NarrativeEventDefinition(
          id: _dialogueEventId,
          name: 'Boot dialogue Event V2',
          source: NarrativeEventSourceRef.mapEnter(_mapId),
          conditions: const <NarrativeEventCondition>[],
          sceneId: _dialogueSceneId,
          reusePolicy: NarrativeEventReusePolicy.oneShot,
          priority: 0,
          order: 0,
        ),
        enabled: true,
      ),
    ],
    legacyClaims: const <LegacySourceClaim>[],
  );
  final project = ProjectManifest(
    name: 'Event V2 boot dialogue integration',
    maps: const <ProjectMapEntry>[
      ProjectMapEntry(
        id: _mapId,
        name: 'Event V2 Boot Map',
        relativePath: 'maps/event_v2_boot.json',
      ),
    ],
    tilesets: const <ProjectTilesetEntry>[],
    dialogues: const <ProjectDialogueEntry>[
      ProjectDialogueEntry(
        id: _dialogueId,
        name: 'Boot dialogue',
        relativePath: 'dialogues/boot.yarn',
      ),
    ],
    facts: <NarrativeFactDefinition>[
      NarrativeFactDefinition(
        id: _dialogueFactId,
        label: 'Boot dialogue completed',
      ),
    ],
    eventRegistry: registry,
    scenes: <SceneAsset>[_dialogueScene()],
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
  );
  return RuntimeMapBundle(
    manifest: project,
    map: _map(),
    projectRootDirectory: '/tmp/event_v2_boot_dialogue',
    tilesetAbsolutePathsById: const <String, String>{},
  );
}

SceneAsset _dialogueScene() => SceneAsset(
      id: _dialogueSceneId,
      name: 'Event V2 boot dialogue Scene',
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: <SceneNode>[
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'dialogue',
            kind: SceneNodeKind.yarnDialogue,
            payload: SceneYarnDialoguePayload(dialogueId: _dialogueId),
          ),
          SceneNode(
            id: 'set_fact',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.consequence(
              SceneConsequence.setFact(
                factId: _dialogueFactId,
                value: true,
              ),
            ),
          ),
          SceneNode(id: 'end', kind: SceneNodeKind.end),
        ],
        edges: <SceneEdge>[
          SceneEdge(
            id: 'start_to_dialogue',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: 'dialogue',
            kind: SceneEdgeKind.defaultFlow,
          ),
          SceneEdge(
            id: 'dialogue_to_fact',
            fromNodeId: 'dialogue',
            fromPortId: 'completed',
            toNodeId: 'set_fact',
            kind: SceneEdgeKind.defaultFlow,
          ),
          SceneEdge(
            id: 'fact_to_end',
            fromNodeId: 'set_fact',
            fromPortId: 'completed',
            toNodeId: 'end',
            kind: SceneEdgeKind.actionCompleted,
          ),
        ],
      ),
    );

DialogueSession _singleLineDialogueSession() {
  return DialogueSession.start(
    <YarnNode>[
      YarnNode(
        title: 'Start',
        steps: <YarnStep>[YarnStepLine('Bienvenue.')],
      ),
    ],
    'Start',
  )!;
}

Future<void> _waitForActivationDispatch(PlayableMapGame game) {
  return _waitUntil(
    game,
    () => !game.debugIsMapActivationDispatchInFlight,
  );
}

Future<void> _waitUntil(
  PlayableMapGame game,
  bool Function() done, {
  int maxTicks = 240,
}) async {
  for (var i = 0; i < maxTicks; i++) {
    if (done()) {
      return;
    }
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
  }
  fail('Timed out waiting for the runtime activation dispatch.');
}

RuntimeMapBundle _dualReadClaimedBundle() {
  final source = NarrativeEventSourceRef.mapEnter(_mapId);
  final provenance = LegacySourceRef.scenarioSourceNode(
    _legacyMapEnterScenario.id,
    'source',
  );
  final member = LegacySourceClaimMember(
    provenance: provenance,
    sourceFingerprint: computeScenarioSourceFingerprint(
      scenarioId: _legacyMapEnterScenario.id,
      nodeId: 'source',
      scenario: _legacyMapEnterScenario,
    ),
  );
  final cohortId = computeLegacySourceCohortId(source, [provenance]);
  final claim = LegacySourceClaim(
    cohortId: cohortId,
    source: source,
    members: [member],
    cohortFingerprint: computeLegacySourceCohortFingerprint(
      cohortId,
      [member],
    ),
    targetEventIds: const [_eventId],
    migrationReceiptId: 'receipt-event-v2-boot-dual-read',
  );
  final registry = NarrativeEventRegistry(
    schemaVersion: 1,
    mode: EventSystemMode.dualRead,
    records: <NarrativeEventRecord>[_record(enabled: false)],
    legacyClaims: <LegacySourceClaim>[claim],
  );
  return _bundleForRegistry(registry, _scene());
}

NarrativeEventRecord _record({required bool enabled}) {
  return NarrativeEventRecord.configuredStructurallyUnchecked(
    NarrativeEventDefinition(
      id: _eventId,
      name: 'Boot Event V2',
      source: NarrativeEventSourceRef.mapEnter(_mapId),
      conditions: const <NarrativeEventCondition>[],
      sceneId: _sceneId,
      reusePolicy: NarrativeEventReusePolicy.oneShot,
      priority: 0,
      order: 0,
    ),
    enabled: enabled,
  );
}

SceneAsset _scene() {
  return SceneAsset(
    id: _sceneId,
    name: 'Event V2 boot Scene',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: <SceneNode>[
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'set_fact',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.setFact(factId: _factId, value: true),
          ),
        ),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ],
      edges: <SceneEdge>[
        SceneEdge(
          id: 'start_to_fact',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'set_fact',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'fact_to_end',
          fromNodeId: 'set_fact',
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.actionCompleted,
        ),
      ],
    ),
  );
}

RuntimeMapBundle _bundleForRegistry(
  NarrativeEventRegistry registry,
  SceneAsset scene,
) {
  final project = ProjectManifest(
    name: 'Event V2 boot integration',
    maps: const <ProjectMapEntry>[
      ProjectMapEntry(
        id: _mapId,
        name: 'Event V2 Boot Map',
        relativePath: 'maps/event_v2_boot.json',
      ),
    ],
    tilesets: const <ProjectTilesetEntry>[],
    facts: <NarrativeFactDefinition>[
      NarrativeFactDefinition(
        id: _factId,
        label: 'Boot Scene completed',
      ),
    ],
    scenarios: const <ScenarioAsset>[_legacyMapEnterScenario],
    eventRegistry: registry,
    scenes: <SceneAsset>[scene],
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
  );
  return RuntimeMapBundle(
    manifest: project,
    map: _map(),
    projectRootDirectory: '/tmp/event_v2_boot',
    tilesetAbsolutePathsById: const <String, String>{},
  );
}

MapData _map() => const MapData(
      id: _mapId,
      name: 'Event V2 Boot Map',
      size: GridSize(width: 3, height: 3),
      layers: <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: <MapEntity>[
        MapEntity(
          id: 'spawn',
          name: 'Spawn',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 1, y: 1),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.south,
          ),
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: 'spawn'),
    );

const _legacyMapEnterScenario = ScenarioAsset(
  id: 'legacy_map_enter_must_not_run',
  name: 'Legacy mapEnter must not run',
  scope: ScenarioScope.localEventFlow,
  entryNodeId: 'source',
  nodes: <ScenarioNode>[
    ScenarioNode(
      id: 'source',
      type: ScenarioNodeType.reference,
      payload: ScenarioNodePayload(actionKind: kScenarioSourceMapEnter),
      binding: ScenarioNodeBinding(mapId: _mapId),
    ),
    ScenarioNode(
      id: 'set_legacy_flag',
      type: ScenarioNodeType.action,
      payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
      binding: ScenarioNodeBinding(flagName: _legacyFlag),
    ),
    ScenarioNode(id: 'end', type: ScenarioNodeType.end),
  ],
  edges: <ScenarioEdge>[
    ScenarioEdge(
      id: 'source_to_flag',
      fromNodeId: 'source',
      toNodeId: 'set_legacy_flag',
    ),
    ScenarioEdge(
      id: 'flag_to_end',
      fromNodeId: 'set_legacy_flag',
      toNodeId: 'end',
    ),
  ],
);
````

### 16.9 `packages/map_runtime/test/playable_map_game_initial_save_restore_activation_test.dart`

````dart
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

const _sourceMapId = 'initial_bundle_map';
const _restoredMapId = 'restored_boot_map';
const _restoredFlag = 'test.initial_save_restore.map_enter';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('explicit saveRestore boot restores map and pose before one mapEnter',
      () async {
    final project = _project();
    final bundles = <String, RuntimeMapBundle>{
      _sourceMapId: _bundle(project, _sourceMap()),
      _restoredMapId: _bundle(project, _restoredMap()),
    };
    Future<RuntimeMapBundle> loadBundle({
      required String projectFilePath,
      required String mapId,
    }) async {
      return bundles[mapId] ?? (throw StateError('Unknown map $mapId'));
    }

    final game = PlayableMapGame(
      bundle: bundles[_sourceMapId]!,
      projectFilePath: '/tmp/initial_save_restore/project.json',
      saveData: const SaveData(
        saveId: 'versioned-launch-save',
        currentMapId: _restoredMapId,
        playerPosition: GridPos(x: 2, y: 1),
        playerFacing: EntityFacing.west,
      ),
      initialMapActivationReason: MapActivationReason.saveRestore,
      runtimeMapBundleLoader: loadBundle,
    );

    game.onGameResize(Vector2(320, 240));
    await game.onLoad();
    await _waitForActivationDispatch(game);

    expect(game.gameStateSnapshot.currentMapId, _restoredMapId);
    expect(game.debugPlayerGridPosition, const GridPos(x: 2, y: 1));
    expect(game.gameStateSnapshot.playerFacing, EntityFacing.west);
    expect(
        game.gameStateSnapshot.storyFlags.activeFlags, contains(_restoredFlag));
    expect(game.debugCompletedMapActivationDispatchCount, 1);
    expect(
      game.debugLastCompletedMapActivation?.reason,
      MapActivationReason.saveRestore,
    );
    expect(game.debugLastCompletedMapActivation?.mapId, _restoredMapId);
  });
}

Future<void> _waitForActivationDispatch(PlayableMapGame game) async {
  for (var i = 0; i < 240; i++) {
    if (!game.debugIsMapActivationDispatchInFlight) {
      return;
    }
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
  }
  fail('Timed out waiting for the saveRestore activation dispatch.');
}

ProjectManifest _project() {
  return const ProjectManifest(
    name: 'Initial save restore integration',
    maps: <ProjectMapEntry>[
      ProjectMapEntry(
        id: _sourceMapId,
        name: 'Initial Bundle Map',
        relativePath: 'maps/initial.json',
      ),
      ProjectMapEntry(
        id: _restoredMapId,
        name: 'Restored Boot Map',
        relativePath: 'maps/restored.json',
      ),
    ],
    tilesets: <ProjectTilesetEntry>[],
    scenarios: <ScenarioAsset>[_restoredMapEnterScenario],
    surfaceCatalog: ProjectSurfaceCatalog.empty(),
  );
}

RuntimeMapBundle _bundle(ProjectManifest project, MapData map) {
  return RuntimeMapBundle(
    manifest: project,
    map: map,
    projectRootDirectory: '/tmp/initial_save_restore',
    tilesetAbsolutePathsById: const <String, String>{},
  );
}

MapData _sourceMap() => const MapData(
      id: _sourceMapId,
      name: 'Initial Bundle Map',
      size: GridSize(width: 3, height: 3),
      layers: <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: <MapEntity>[
        MapEntity(
          id: 'source_spawn',
          name: 'Source Spawn',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 0, y: 0),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.south,
          ),
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: 'source_spawn'),
    );

MapData _restoredMap() => const MapData(
      id: _restoredMapId,
      name: 'Restored Boot Map',
      size: GridSize(width: 4, height: 3),
      layers: <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: <MapEntity>[
        MapEntity(
          id: 'restored_spawn',
          name: 'Restored Spawn',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 0, y: 0),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.south,
          ),
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: 'restored_spawn'),
    );

const _restoredMapEnterScenario = ScenarioAsset(
  id: 'restored_boot_map_enter_scenario',
  name: 'Restored boot map enter',
  scope: ScenarioScope.localEventFlow,
  entryNodeId: 'source_map_enter',
  nodes: <ScenarioNode>[
    ScenarioNode(
      id: 'source_map_enter',
      type: ScenarioNodeType.reference,
      payload: ScenarioNodePayload(actionKind: kScenarioSourceMapEnter),
      binding: ScenarioNodeBinding(mapId: _restoredMapId),
    ),
    ScenarioNode(
      id: 'set_restored_flag',
      type: ScenarioNodeType.action,
      payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
      binding: ScenarioNodeBinding(flagName: _restoredFlag),
    ),
    ScenarioNode(id: 'end', type: ScenarioNodeType.end),
  ],
  edges: <ScenarioEdge>[
    ScenarioEdge(
      id: 'source_to_flag',
      fromNodeId: 'source_map_enter',
      toNodeId: 'set_restored_flag',
    ),
    ScenarioEdge(
      id: 'flag_to_end',
      fromNodeId: 'set_restored_flag',
      toNodeId: 'end',
    ),
  ],
);
````

### 16.10 `packages/map_runtime/test/playable_map_game_map_activation_interlock_test.dart`

````dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;

const _sourceMapId = 'activation_interlock_source';
const _targetMapId = 'activation_interlock_target';
const _eventId = 'evt_019abcde-2000-7000-8000-000000000001';
const _sceneId = 'scene_activation_interlock_target_enter';
const _factId = 'fact.activation_interlock.target_enter_completed';
const _legacyFlag = 'test.activation_interlock.legacy_must_not_run';
const _legacyOutcomeId = 'activation_interlock_transition_requested';
const _legacyOutcomeProducerSceneId =
    'scene_activation_interlock_outcome_producer';
const _legacyMapEnterAFlag = 'test.activation_interlock.map_enter_a';
const _legacyMapEnterBFlag = 'test.activation_interlock.map_enter_b';
const _legacyDeliveryId = 'outd_019abcde-4000-7000-8000-000000000001';
const _legacyExecutionId = 'evx_019abcde-4000-7000-8000-000000000002';
const _legacyCorrelationId = 'corr_019abcde-4000-7000-8000-000000000003';
const _retryOutcomeId = 'activation_interlock_retry_outcome';
const _retryDeliveryId = 'outd_019abcde-4000-7000-8000-000000000011';
const _retryExecutionId = 'evx_019abcde-4000-7000-8000-000000000012';
const _retryCorrelationId = 'corr_019abcde-4000-7000-8000-000000000013';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'connection mapEnter dispatch interlocks movement, transitions and load',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'runtime_map_activation_interlock_',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });
      final projectFilePath = await _writeProject(root);
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: _sourceMapId,
      );
      final preparationStarted = Completer<void>();
      final releasePreparation = Completer<void>();
      var targetPreparationCount = 0;
      final repository = _CountingGameSaveRepository(
        const GameState(
          saveId: 'load-must-not-run',
          currentMapId: _sourceMapId,
          playerPosition: GridPos(x: 1, y: 0),
        ),
      );
      final game = _TestPlayableMapGame(
        bundle: bundle,
        projectFilePath: projectFilePath,
        saveRepository: repository,
        beforeNarrativeAuthorityPreparation: (occurrence) async {
          if (occurrence.source !=
              NarrativeEventSourceRef.mapEnter(_targetMapId)) {
            return;
          }
          targetPreparationCount++;
          if (!preparationStarted.isCompleted) {
            preparationStarted.complete();
          }
          await releasePreparation.future;
        },
      );

      game.onGameResize(Vector2(640, 480));
      await game.onLoad();
      await _pumpUntil(
        game,
        () => !game.debugIsMapActivationDispatchInFlight,
      );
      expect(game.debugCompletedMapActivationDispatchCount, 1);
      final initialActivationId =
          game.debugLastCompletedMapActivation?.activationId;

      await _runSingleMove(game, RuntimeInputControl.right);
      await preparationStarted.future.timeout(const Duration(seconds: 2));

      expect(game.gameStateSnapshot.currentMapId, _targetMapId);
      expect(game.debugFlowPhaseName, 'overworld');
      expect(game.debugIsMapActivationDispatchInFlight, isTrue);
      expect(game.debugPlayerGridPosition, const GridPos(x: 0, y: 0));
      expect(game.debugCompletedMapActivationDispatchCount, 1);
      expect(
        game.debugLastCompletedMapActivation?.reason,
        MapActivationReason.initialBoot,
      );
      expect(
        game.gameStateSnapshot.narrativeFactRuntimeState
            .overridesByFactId[_factId],
        isNot(isTrue),
      );

      expect(await game.loadGame(), isFalse);
      expect(repository.loadCount, 0);

      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.right),
        ),
        isTrue,
      );
      for (var i = 0; i < 30; i++) {
        game.update(0.016);
        await Future<void>.delayed(Duration.zero);
      }
      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.release(RuntimeInputControl.right),
        ),
        isTrue,
      );

      expect(game.gameStateSnapshot.currentMapId, _targetMapId);
      expect(game.debugPlayerGridPosition, const GridPos(x: 0, y: 0));
      expect(game.debugCompletedMapActivationDispatchCount, 1);
      expect(
        game.debugLastCompletedMapActivation?.activationId,
        initialActivationId,
      );

      releasePreparation.complete();
      await _pumpUntil(
        game,
        () =>
            !game.debugIsMapActivationDispatchInFlight &&
            game.gameStateSnapshot.narrativeFactRuntimeState
                    .overridesByFactId[_factId] ==
                true,
      );

      final state = game.gameStateSnapshot;
      expect(targetPreparationCount, 1);
      expect(
        state.narrativeEventProgress.consumedNarrativeEventIds
            .where((id) => id == _eventId),
        hasLength(1),
      );
      expect(state.storyFlags.activeFlags, isNot(contains(_legacyFlag)));
      expect(game.debugCompletedMapActivationDispatchCount, 2);
      expect(
        game.debugLastCompletedMapActivation?.reason,
        MapActivationReason.connection,
      );
      expect(
        game.debugLastCompletedMapActivation?.activationId,
        isNot(initialActivationId),
      );
    },
  );

  test(
    'load interlocks movement and connection until saveRestore dispatch',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'runtime_load_activation_interlock_',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });
      final projectFilePath = await _writeProject(root);
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: _sourceMapId,
      );
      final repository = _BlockingLoadGameSaveRepository(
        const GameState(
          saveId: 'blocked-load',
          currentMapId: _targetMapId,
          playerPosition: GridPos(x: 0, y: 0),
        ),
      );
      final game = _TestPlayableMapGame(
        bundle: bundle,
        projectFilePath: projectFilePath,
        saveRepository: repository,
      );

      game.onGameResize(Vector2(640, 480));
      await game.onLoad();
      await _pumpUntil(
        game,
        () => !game.debugIsMapActivationDispatchInFlight,
      );
      expect(game.debugCompletedMapActivationDispatchCount, 1);
      final initialActivationId =
          game.debugLastCompletedMapActivation?.activationId;

      final loadFuture = game.loadGame();
      await repository.loadStarted.future.timeout(const Duration(seconds: 2));

      expect(game.debugIsLoadActivationWorkInFlight, isTrue);
      expect(game.debugIsMapActivationDispatchInFlight, isFalse);
      expect(await game.loadGame(), isFalse);
      expect(repository.loadCount, 1);

      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.right),
        ),
        isTrue,
      );
      for (var i = 0; i < 30; i++) {
        game.update(0.016);
        await Future<void>.delayed(Duration.zero);
      }
      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.release(RuntimeInputControl.right),
        ),
        isTrue,
      );

      expect(game.gameStateSnapshot.currentMapId, _sourceMapId);
      expect(game.debugPlayerGridPosition, const GridPos(x: 1, y: 0));
      expect(game.debugHasPendingMapTransition, isFalse);
      expect(game.debugCompletedMapActivationDispatchCount, 1);
      expect(
        game.debugLastCompletedMapActivation?.activationId,
        initialActivationId,
      );

      repository.releaseLoad();
      expect(await loadFuture, isTrue);

      expect(game.debugIsLoadActivationWorkInFlight, isFalse);
      expect(game.gameStateSnapshot.currentMapId, _targetMapId);
      expect(game.debugPlayerGridPosition, const GridPos(x: 0, y: 0));
      expect(game.debugCompletedMapActivationDispatchCount, 2);
      expect(
        game.debugLastCompletedMapActivation?.reason,
        MapActivationReason.saveRestore,
      );
      expect(
        game.debugLastCompletedMapActivation?.activationId,
        isNot(initialActivationId),
      );
    },
  );

  test(
    'restored legacy outcome transition supersedes stale mapEnter activation',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'runtime_restore_outcome_transition_',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });
      final projectFilePath = await _writeLegacyOutcomeTransitionProject(root);
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: _sourceMapId,
      );
      final outcome = NarrativeOutcomeRef(
        producerKind: NarrativeOutcomeProducerKind.scene,
        producerId: _legacyOutcomeProducerSceneId,
        outcomeId: _legacyOutcomeId,
      );
      final game = PlayableMapGame(
        bundle: bundle,
        projectFilePath: projectFilePath,
        saveData: SaveData(
          saveId: 'restore-outcome-transition',
          currentMapId: _sourceMapId,
          playerPosition: const GridPos(x: 1, y: 0),
          narrativeEventProgress: NarrativeEventProgress(
            pendingNarrativeOutcomeDeliveries: <NarrativeOutcomeDelivery>[
              NarrativeOutcomeDelivery(
                deliveryId: _legacyDeliveryId,
                outcome: outcome,
                causationExecutionId: _legacyExecutionId,
                rootCorrelationId: _legacyCorrelationId,
                depth: 0,
                attemptCount: 0,
              ),
            ],
          ),
        ),
        initialMapActivationReason: MapActivationReason.saveRestore,
      );

      game.onGameResize(Vector2(640, 480));
      await game.onLoad().timeout(
            const Duration(seconds: 2),
          );
      await _pumpUntil(
        game,
        () => !game.debugIsMapActivationDispatchInFlight,
      );

      final state = game.gameStateSnapshot;
      expect(state.currentMapId, _targetMapId);
      expect(
          state.storyFlags.activeFlags, isNot(contains(_legacyMapEnterAFlag)));
      expect(state.storyFlags.activeFlags, contains(_legacyMapEnterBFlag));
      expect(
        state.narrativeEventProgress.pendingNarrativeOutcomeDeliveries,
        isEmpty,
      );
      expect(
        state.narrativeEventProgress.deliveredNarrativeOutcomeDeliveryIds,
        contains(_legacyDeliveryId),
      );
      expect(game.debugCompletedMapActivationDispatchCount, 1);
      expect(
        game.debugLastCompletedMapActivation?.reason,
        MapActivationReason.warp,
      );
    },
  );

  test(
    'failed restored outcome authority keeps pending delivery and load fails',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'runtime_restore_outcome_retry_',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });
      final projectFilePath = await _writeProject(root);
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: _sourceMapId,
      );
      final retryOutcome = NarrativeOutcomeRef(
        producerKind: NarrativeOutcomeProducerKind.scene,
        producerId: 'scene_activation_interlock_retry_producer',
        outcomeId: _retryOutcomeId,
      );
      final repository = _CountingGameSaveRepository(
        GameState(
          saveId: 'restore-outcome-retry',
          currentMapId: _sourceMapId,
          playerPosition: const GridPos(x: 1, y: 0),
          narrativeEventProgress: NarrativeEventProgress(
            pendingNarrativeOutcomeDeliveries: <NarrativeOutcomeDelivery>[
              NarrativeOutcomeDelivery(
                deliveryId: _retryDeliveryId,
                outcome: retryOutcome,
                causationExecutionId: _retryExecutionId,
                rootCorrelationId: _retryCorrelationId,
                depth: 0,
                attemptCount: 0,
              ),
            ],
          ),
        ),
      );
      final game = _TestPlayableMapGame(
        bundle: bundle,
        projectFilePath: projectFilePath,
        saveRepository: repository,
        beforeNarrativeAuthorityPreparation: (occurrence) async {
          if (occurrence.source.kind ==
              NarrativeEventSourceKind.outcomeReceived) {
            throw StateError('Injected restored outcome authority failure.');
          }
        },
      );

      game.onGameResize(Vector2(640, 480));
      await game.onLoad();
      await _pumpUntil(
        game,
        () => !game.debugIsMapActivationDispatchInFlight,
      );
      expect(game.debugCompletedMapActivationDispatchCount, 1);
      final initialActivation = game.debugLastCompletedMapActivation;

      expect(await game.loadGame(), isFalse);

      final state = game.gameStateSnapshot;
      expect(game.debugIsLoadActivationWorkInFlight, isFalse);
      expect(game.debugCompletedMapActivationDispatchCount, 1);
      expect(game.debugLastCompletedMapActivation, initialActivation);
      expect(
        state.narrativeEventProgress.pendingNarrativeOutcomeDeliveries,
        hasLength(1),
      );
      expect(
        state.narrativeEventProgress.pendingNarrativeOutcomeDeliveries.single
            .deliveryId,
        _retryDeliveryId,
      );
      expect(
        state.narrativeEventProgress.deliveredNarrativeOutcomeDeliveryIds,
        isNot(contains(_retryDeliveryId)),
      );
    },
  );
}

final class _TestPlayableMapGame extends PlayableMapGame {
  _TestPlayableMapGame({
    required super.bundle,
    required super.projectFilePath,
    required super.saveRepository,
    super.beforeNarrativeAuthorityPreparation,
  });

  @override
  bool get isLoaded => true;
}

final class _BlockingLoadGameSaveRepository implements GameSaveRepository {
  _BlockingLoadGameSaveRepository(this._state);

  final GameState _state;
  final Completer<void> loadStarted = Completer<void>();
  final Completer<GameState?> _loadResult = Completer<GameState?>();
  int loadCount = 0;

  void releaseLoad() {
    if (!_loadResult.isCompleted) {
      _loadResult.complete(_state);
    }
  }

  @override
  Future<void> save(GameState state) async {}

  @override
  Future<GameState?> load() {
    loadCount++;
    if (!loadStarted.isCompleted) {
      loadStarted.complete();
    }
    return _loadResult.future;
  }

  @override
  Future<bool> exists() async => true;

  @override
  Future<void> delete() async {}
}

final class _CountingGameSaveRepository implements GameSaveRepository {
  _CountingGameSaveRepository(this._state);

  GameState? _state;
  int loadCount = 0;

  @override
  Future<void> save(GameState state) async {
    _state = state;
  }

  @override
  Future<GameState?> load() async {
    loadCount++;
    return _state;
  }

  @override
  Future<bool> exists() async => _state != null;

  @override
  Future<void> delete() async {
    _state = null;
  }
}

Future<void> _runSingleMove(
  PlayableMapGame game,
  RuntimeInputControl control,
) async {
  expect(
    game.handleRuntimeInputEvent(RuntimeInputEvent.press(control)),
    isTrue,
  );
  game.update(0.016);
  expect(
    game.handleRuntimeInputEvent(RuntimeInputEvent.release(control)),
    isTrue,
  );
  await _pumpUntil(
    game,
    () => !game.debugIsPlayerStepping && !game.debugHasPendingMapTransition,
  );
}

Future<void> _pumpUntil(
  PlayableMapGame game,
  bool Function() done, {
  int maxTicks = 240,
}) async {
  for (var i = 0; i < maxTicks; i++) {
    if (done()) {
      return;
    }
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
  }
  fail('Timed out waiting for the runtime game to settle.');
}

Future<String> _writeProject(Directory root) async {
  final maps = <MapData>[_sourceMap(), _targetMap()];
  final manifest = ProjectManifest(
    name: 'Map activation interlock integration',
    settings: const ProjectSettings(tileWidth: 16, tileHeight: 16),
    maps: maps
        .map(
          (map) => ProjectMapEntry(
            id: map.id,
            name: map.name,
            relativePath: 'maps/${map.id}.json',
          ),
        )
        .toList(growable: false),
    tilesets: const <ProjectTilesetEntry>[],
    facts: <NarrativeFactDefinition>[
      NarrativeFactDefinition(
        id: _factId,
        label: 'Target map enter completed',
      ),
    ],
    scenarios: const <ScenarioAsset>[_legacyTargetMapEnterScenario],
    eventRegistry: NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.v2Only,
      records: <NarrativeEventRecord>[
        NarrativeEventRecord.configuredStructurallyUnchecked(
          NarrativeEventDefinition(
            id: _eventId,
            name: 'Target map enter',
            source: NarrativeEventSourceRef.mapEnter(_targetMapId),
            conditions: const <NarrativeEventCondition>[],
            sceneId: _sceneId,
            reusePolicy: NarrativeEventReusePolicy.oneShot,
            priority: 0,
            order: 0,
          ),
          enabled: true,
        ),
      ],
      legacyClaims: const <LegacySourceClaim>[],
    ),
    scenes: <SceneAsset>[_scene()],
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
  );
  final mapsDirectory = Directory(p.join(root.path, 'maps'));
  await mapsDirectory.create(recursive: true);
  for (final map in maps) {
    await File(p.join(mapsDirectory.path, '${map.id}.json')).writeAsString(
      const JsonEncoder.withIndent('  ').convert(map.toJson()),
    );
  }
  final projectFile = File(p.join(root.path, 'project.json'));
  await projectFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
  );
  return projectFile.path;
}

Future<String> _writeLegacyOutcomeTransitionProject(Directory root) async {
  final maps = <MapData>[_sourceMap(), _targetMap()];
  final manifest = ProjectManifest(
    name: 'Restored legacy outcome transition integration',
    settings: const ProjectSettings(tileWidth: 16, tileHeight: 16),
    maps: maps
        .map(
          (map) => ProjectMapEntry(
            id: map.id,
            name: map.name,
            relativePath: 'maps/${map.id}.json',
          ),
        )
        .toList(growable: false),
    tilesets: const <ProjectTilesetEntry>[],
    scenarios: const <ScenarioAsset>[
      _legacyOutcomeTransitionScenario,
      _legacyMapEnterAScenario,
      _legacyMapEnterBScenario,
    ],
    scenes: <SceneAsset>[_legacyOutcomeProducerScene()],
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
  );
  final mapsDirectory = Directory(p.join(root.path, 'maps'));
  await mapsDirectory.create(recursive: true);
  for (final map in maps) {
    await File(p.join(mapsDirectory.path, '${map.id}.json')).writeAsString(
      const JsonEncoder.withIndent('  ').convert(map.toJson()),
    );
  }
  final projectFile = File(p.join(root.path, 'project.json'));
  await projectFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
  );
  return projectFile.path;
}

SceneAsset _legacyOutcomeProducerScene() => SceneAsset(
      id: _legacyOutcomeProducerSceneId,
      name: 'Legacy transition outcome producer',
      declaredOutcomes: <SceneOutcome>[
        SceneOutcome(
          id: _legacyOutcomeId,
          label: 'Transition requested',
        ),
      ],
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: <SceneNode>[
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'end',
            kind: SceneNodeKind.end,
            payload: SceneEndPayload(
              sceneOutcomeId: _legacyOutcomeId,
            ),
          ),
        ],
        edges: <SceneEdge>[
          SceneEdge(
            id: 'start_to_end',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: 'end',
            kind: SceneEdgeKind.defaultFlow,
          ),
        ],
      ),
    );

MapData _sourceMap() => const MapData(
      id: _sourceMapId,
      name: 'Activation interlock source',
      size: GridSize(width: 2, height: 2),
      layers: <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: <MapEntity>[
        MapEntity(
          id: 'spawn_source',
          name: 'Source spawn',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 1, y: 0),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.east,
          ),
        ),
      ],
      connections: <MapConnection>[
        MapConnection(
          direction: MapConnectionDirection.east,
          targetMapId: _targetMapId,
          offset: 0,
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: 'spawn_source'),
    );

MapData _targetMap() => const MapData(
      id: _targetMapId,
      name: 'Activation interlock target',
      size: GridSize(width: 3, height: 2),
      layers: <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: <MapEntity>[
        MapEntity(
          id: 'spawn_target',
          name: 'Target spawn',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 0, y: 0),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.east,
          ),
        ),
      ],
      warps: <MapWarp>[
        MapWarp(
          id: 'warp_back_to_source',
          pos: GridPos(x: 1, y: 0),
          targetMapId: _sourceMapId,
          targetPos: GridPos(x: 1, y: 0),
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: 'spawn_target'),
    );

SceneAsset _scene() => SceneAsset(
      id: _sceneId,
      name: 'Target map enter Scene',
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: <SceneNode>[
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'set_fact',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.consequence(
              SceneConsequence.setFact(factId: _factId, value: true),
            ),
          ),
          SceneNode(id: 'end', kind: SceneNodeKind.end),
        ],
        edges: <SceneEdge>[
          SceneEdge(
            id: 'start_to_fact',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: 'set_fact',
            kind: SceneEdgeKind.defaultFlow,
          ),
          SceneEdge(
            id: 'fact_to_end',
            fromNodeId: 'set_fact',
            fromPortId: 'completed',
            toNodeId: 'end',
            kind: SceneEdgeKind.actionCompleted,
          ),
        ],
      ),
    );

const _legacyTargetMapEnterScenario = ScenarioAsset(
  id: 'legacy_target_map_enter_must_not_run',
  name: 'Legacy target mapEnter must not run',
  scope: ScenarioScope.localEventFlow,
  entryNodeId: 'start',
  nodes: <ScenarioNode>[
    ScenarioNode(id: 'start', type: ScenarioNodeType.start),
    ScenarioNode(
      id: 'source',
      type: ScenarioNodeType.reference,
      payload: ScenarioNodePayload(actionKind: kScenarioSourceMapEnter),
      binding: ScenarioNodeBinding(mapId: _targetMapId),
    ),
    ScenarioNode(
      id: 'set_legacy_flag',
      type: ScenarioNodeType.action,
      payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
      binding: ScenarioNodeBinding(flagName: _legacyFlag),
    ),
    ScenarioNode(id: 'end', type: ScenarioNodeType.end),
  ],
  edges: <ScenarioEdge>[
    ScenarioEdge(
      id: 'start_to_source',
      fromNodeId: 'start',
      toNodeId: 'source',
    ),
    ScenarioEdge(
      id: 'source_to_flag',
      fromNodeId: 'source',
      toNodeId: 'set_legacy_flag',
    ),
    ScenarioEdge(
      id: 'flag_to_end',
      fromNodeId: 'set_legacy_flag',
      toNodeId: 'end',
    ),
  ],
);

const _legacyOutcomeTransitionScenario = ScenarioAsset(
  id: 'legacy_restored_outcome_transition',
  name: 'Legacy restored outcome transition',
  scope: ScenarioScope.globalStory,
  entryNodeId: 'start',
  nodes: <ScenarioNode>[
    ScenarioNode(id: 'start', type: ScenarioNodeType.start),
    ScenarioNode(
      id: 'source_outcome',
      type: ScenarioNodeType.reference,
      payload: ScenarioNodePayload(actionKind: kScenarioSourceOutcome),
      binding: ScenarioNodeBinding(outcomeId: _legacyOutcomeId),
    ),
    ScenarioNode(
      id: 'transition_to_b',
      type: ScenarioNodeType.action,
      payload: ScenarioNodePayload(actionKind: kScenarioActionTransitionMap),
      binding: ScenarioNodeBinding(
        mapId: _targetMapId,
        warpId: 'warp_back_to_source',
      ),
    ),
    ScenarioNode(id: 'end', type: ScenarioNodeType.end),
  ],
  edges: <ScenarioEdge>[
    ScenarioEdge(
      id: 'start_to_source',
      fromNodeId: 'start',
      toNodeId: 'source_outcome',
    ),
    ScenarioEdge(
      id: 'source_to_transition',
      fromNodeId: 'source_outcome',
      toNodeId: 'transition_to_b',
    ),
    ScenarioEdge(
      id: 'transition_to_end',
      fromNodeId: 'transition_to_b',
      toNodeId: 'end',
    ),
  ],
);

const _legacyMapEnterAScenario = ScenarioAsset(
  id: 'legacy_map_enter_a',
  name: 'Legacy map enter A',
  scope: ScenarioScope.localEventFlow,
  entryNodeId: 'start',
  nodes: <ScenarioNode>[
    ScenarioNode(id: 'start', type: ScenarioNodeType.start),
    ScenarioNode(
      id: 'source_map_enter_a',
      type: ScenarioNodeType.reference,
      payload: ScenarioNodePayload(actionKind: kScenarioSourceMapEnter),
      binding: ScenarioNodeBinding(mapId: _sourceMapId),
    ),
    ScenarioNode(
      id: 'set_map_enter_a',
      type: ScenarioNodeType.action,
      payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
      binding: ScenarioNodeBinding(flagName: _legacyMapEnterAFlag),
    ),
    ScenarioNode(id: 'end', type: ScenarioNodeType.end),
  ],
  edges: <ScenarioEdge>[
    ScenarioEdge(
      id: 'start_to_source_a',
      fromNodeId: 'start',
      toNodeId: 'source_map_enter_a',
    ),
    ScenarioEdge(
      id: 'source_to_flag_a',
      fromNodeId: 'source_map_enter_a',
      toNodeId: 'set_map_enter_a',
    ),
    ScenarioEdge(
      id: 'flag_to_end_a',
      fromNodeId: 'set_map_enter_a',
      toNodeId: 'end',
    ),
  ],
);

const _legacyMapEnterBScenario = ScenarioAsset(
  id: 'legacy_map_enter_b',
  name: 'Legacy map enter B',
  scope: ScenarioScope.localEventFlow,
  entryNodeId: 'start',
  nodes: <ScenarioNode>[
    ScenarioNode(id: 'start', type: ScenarioNodeType.start),
    ScenarioNode(
      id: 'source_map_enter_b',
      type: ScenarioNodeType.reference,
      payload: ScenarioNodePayload(actionKind: kScenarioSourceMapEnter),
      binding: ScenarioNodeBinding(mapId: _targetMapId),
    ),
    ScenarioNode(
      id: 'set_map_enter_b',
      type: ScenarioNodeType.action,
      payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
      binding: ScenarioNodeBinding(flagName: _legacyMapEnterBFlag),
    ),
    ScenarioNode(id: 'end', type: ScenarioNodeType.end),
  ],
  edges: <ScenarioEdge>[
    ScenarioEdge(
      id: 'start_to_source_b',
      fromNodeId: 'start',
      toNodeId: 'source_map_enter_b',
    ),
    ScenarioEdge(
      id: 'source_to_flag_b',
      fromNodeId: 'source_map_enter_b',
      toNodeId: 'set_map_enter_b',
    ),
    ScenarioEdge(
      id: 'flag_to_end_b',
      fromNodeId: 'set_map_enter_b',
      toNodeId: 'end',
    ),
  ],
);
````

### 16.11 `packages/map_runtime/test/playable_map_game_map_enter_v2_integration_test.dart`

````dart
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

const _mapId = 'test_map_enter_load';
const _mapEnterFlag = 'test.map_enter.after_load';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loadGame dispatches legacy mapEnter after restoring the same map',
      () async {
    final repository = _MemoryGameSaveRepository(
      const GameState(
        saveId: 'restored-save',
        currentMapId: _mapId,
        playerPosition: GridPos(x: 1, y: 1),
      ),
    );
    final game = PlayableMapGame(
      bundle: _bundle(),
      projectFilePath: '/tmp/test_map_enter_load/project.json',
      saveRepository: repository,
    );

    game.onGameResize(Vector2(320, 240));
    await game.onLoad();
    await _waitForActivationDispatch(game);

    expect(
      game.gameStateSnapshot.storyFlags.activeFlags,
      contains(_mapEnterFlag),
      reason: 'The fixture must prove that the legacy mapEnter Scenario runs.',
    );
    expect(game.debugCompletedMapActivationDispatchCount, 1);
    expect(
      game.debugLastCompletedMapActivation?.reason,
      MapActivationReason.initialBoot,
    );
    expect(game.debugLastCompletedMapActivation?.mapId, _mapId);

    expect(await game.loadGame(), isTrue);
    expect(game.gameStateSnapshot.saveId, 'restored-save');
    expect(
      game.gameStateSnapshot.storyFlags.activeFlags,
      contains(_mapEnterFlag),
      reason: 'A successful load must dispatch mapEnter after state restore.',
    );
    expect(game.debugCompletedMapActivationDispatchCount, 2);
    expect(
      game.debugLastCompletedMapActivation?.reason,
      MapActivationReason.saveRestore,
    );
    expect(game.debugLastCompletedMapActivation?.mapId, _mapId);
  });

  test('missing save target never creates a completed map activation',
      () async {
    final repository = _MemoryGameSaveRepository(
      const GameState(
        saveId: 'missing-map-save',
        currentMapId: 'missing_save_target',
        playerPosition: GridPos(x: 1, y: 1),
      ),
    );
    var loaderCalls = 0;
    final game = PlayableMapGame(
      bundle: _bundle(),
      projectFilePath: '/tmp/test_map_enter_load/project.json',
      saveRepository: repository,
      runtimeMapBundleLoader: ({
        required String projectFilePath,
        required String mapId,
      }) async {
        loaderCalls++;
        throw StateError('Map $mapId is unavailable');
      },
    );

    game.onGameResize(Vector2(320, 240));
    await game.onLoad();
    await _waitForActivationDispatch(game);

    expect(await game.loadGame(), isFalse);
    expect(loaderCalls, 1);
    expect(game.gameStateSnapshot.currentMapId, _mapId);
    expect(game.debugCompletedMapActivationDispatchCount, 1);
    expect(
      game.debugLastCompletedMapActivation?.reason,
      MapActivationReason.initialBoot,
    );
    expect(game.debugLastCompletedMapActivation?.mapId, _mapId);
  });
}

Future<void> _waitForActivationDispatch(PlayableMapGame game) async {
  for (var i = 0; i < 240; i++) {
    if (!game.debugIsMapActivationDispatchInFlight) {
      return;
    }
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
  }
  fail('Timed out waiting for the initial map activation dispatch.');
}

RuntimeMapBundle _bundle() {
  return RuntimeMapBundle(
    manifest: ProjectManifest(
      name: 'Map Enter Load Integration Test',
      maps: const <ProjectMapEntry>[
        ProjectMapEntry(
          id: _mapId,
          name: 'Map Enter Load',
          relativePath: 'maps/test_map_enter_load.json',
        ),
      ],
      tilesets: const <ProjectTilesetEntry>[],
      scenarios: const <ScenarioAsset>[_mapEnterScenario],
      surfaceCatalog: ProjectSurfaceCatalog(),
    ),
    map: const MapData(
      id: _mapId,
      name: 'Map Enter Load',
      size: GridSize(width: 3, height: 3),
      layers: <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: <MapEntity>[
        MapEntity(
          id: 'spawn_start',
          name: 'Spawn Start',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 1, y: 1),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.south,
          ),
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: 'spawn_start'),
    ),
    projectRootDirectory: '/tmp/test_map_enter_load',
    tilesetAbsolutePathsById: const <String, String>{},
  );
}

const _mapEnterScenario = ScenarioAsset(
  id: 'test_map_enter_load_scenario',
  name: 'Set flag on map enter',
  scope: ScenarioScope.localEventFlow,
  entryNodeId: 'source_map_enter',
  nodes: <ScenarioNode>[
    ScenarioNode(
      id: 'source_map_enter',
      type: ScenarioNodeType.reference,
      payload: ScenarioNodePayload(actionKind: kScenarioSourceMapEnter),
      binding: ScenarioNodeBinding(mapId: _mapId),
    ),
    ScenarioNode(
      id: 'set_map_enter_flag',
      type: ScenarioNodeType.action,
      payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
      binding: ScenarioNodeBinding(flagName: _mapEnterFlag),
    ),
    ScenarioNode(
      id: 'end',
      type: ScenarioNodeType.end,
    ),
  ],
  edges: <ScenarioEdge>[
    ScenarioEdge(
      id: 'source_to_flag',
      fromNodeId: 'source_map_enter',
      toNodeId: 'set_map_enter_flag',
    ),
    ScenarioEdge(
      id: 'flag_to_end',
      fromNodeId: 'set_map_enter_flag',
      toNodeId: 'end',
    ),
  ],
);

final class _MemoryGameSaveRepository implements GameSaveRepository {
  _MemoryGameSaveRepository(this._state);

  GameState? _state;

  @override
  Future<void> save(GameState state) async {
    _state = state;
  }

  @override
  Future<GameState?> load() async => _state;

  @override
  Future<bool> exists() async => _state != null;

  @override
  Future<void> delete() async {
    _state = null;
  }
}
````

### 16.12 `packages/map_runtime/test/playable_map_game_save_restore_outbox_integration_test.dart`

````dart
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

const _mapId = 'save_restore_outbox_map';

const _outcomeOneProducerSceneId = 'scene_restore_producer_one';
const _outcomeTwoProducerSceneId = 'scene_restore_producer_two';
const _outcomeOneId = 'restore_outcome_one';
const _outcomeTwoId = 'restore_outcome_two';

const _outcomeOneEventId = 'evt_019abcde-3000-7000-8000-000000000001';
const _outcomeTwoEventId = 'evt_019abcde-3000-7000-8000-000000000002';
const _mapEnterEventId = 'evt_019abcde-3000-7000-8000-000000000003';

const _outcomeOneConsumerSceneId = 'scene_restore_sets_fact_a';
const _outcomeTwoConsumerSceneId = 'scene_restore_sets_fact_b';
const _mapEnterConsumerSceneId = 'scene_restore_sets_fact_c';

const _factA = 'fact.restore.outcome_one_processed';
const _factB = 'fact.restore.outcome_two_processed_after_a';
const _factC = 'fact.restore.map_enter_processed_after_b';

const _deliveryOneId = 'outd_019abcde-3000-7000-8000-000000000011';
const _deliveryTwoId = 'outd_019abcde-3000-7000-8000-000000000012';
const _causationExecutionId = 'evx_019abcde-3000-7000-8000-000000000013';
const _rootCorrelationId = 'corr_019abcde-3000-7000-8000-000000000014';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('saveRestore drains pending outcomes FIFO before mapEnter', () async {
    final project = _project();
    final game = PlayableMapGame(
      bundle: RuntimeMapBundle(
        manifest: project,
        map: _map(),
        projectRootDirectory: '/tmp/save_restore_outbox',
        tilesetAbsolutePathsById: const <String, String>{},
      ),
      projectFilePath: '/tmp/save_restore_outbox/project.json',
      saveData: SaveData(
        saveId: 'save-restore-outbox',
        currentMapId: _mapId,
        playerPosition: const GridPos(x: 1, y: 1),
        narrativeEventProgress: NarrativeEventProgress(
          pendingNarrativeOutcomeDeliveries: <NarrativeOutcomeDelivery>[
            _delivery(
              deliveryId: _deliveryOneId,
              outcome: _outcomeOne,
            ),
            _delivery(
              deliveryId: _deliveryTwoId,
              outcome: _outcomeTwo,
            ),
          ],
        ),
      ),
      initialMapActivationReason: MapActivationReason.saveRestore,
    );

    game.onGameResize(Vector2(320, 240));
    await game.onLoad();
    await _waitForActivationDispatch(game);

    final state = game.gameStateSnapshot;
    expect(
      state.narrativeFactRuntimeState.overridesByFactId,
      containsPair(_factA, true),
      reason: 'The FIFO head must execute the first outcome Event.',
    );
    expect(
      state.narrativeFactRuntimeState.overridesByFactId,
      containsPair(_factB, true),
      reason: 'The second outcome is eligible only after fact A is committed.',
    );
    expect(
      state.narrativeFactRuntimeState.overridesByFactId,
      containsPair(_factC, true),
      reason: 'mapEnter is eligible only after fact B is committed.',
    );
    expect(
      state.narrativeEventProgress.pendingNarrativeOutcomeDeliveries,
      isEmpty,
    );
    expect(
      state.narrativeEventProgress.deliveredNarrativeOutcomeDeliveryIds,
      {_deliveryOneId, _deliveryTwoId},
    );
    expect(game.debugCompletedMapActivationDispatchCount, 1);
    expect(
      game.debugLastCompletedMapActivation?.reason,
      MapActivationReason.saveRestore,
    );
  });
}

Future<void> _waitForActivationDispatch(PlayableMapGame game) async {
  for (var i = 0; i < 240; i++) {
    if (!game.debugIsMapActivationDispatchInFlight) {
      return;
    }
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
  }
  fail('Timed out waiting for the saveRestore outbox dispatch.');
}

final NarrativeOutcomeRef _outcomeOne = NarrativeOutcomeRef(
  producerKind: NarrativeOutcomeProducerKind.scene,
  producerId: _outcomeOneProducerSceneId,
  outcomeId: _outcomeOneId,
);

final NarrativeOutcomeRef _outcomeTwo = NarrativeOutcomeRef(
  producerKind: NarrativeOutcomeProducerKind.scene,
  producerId: _outcomeTwoProducerSceneId,
  outcomeId: _outcomeTwoId,
);

ProjectManifest _project() {
  final registry = NarrativeEventRegistry(
    schemaVersion: 1,
    mode: EventSystemMode.v2Only,
    records: <NarrativeEventRecord>[
      _eventRecord(
        id: _outcomeOneEventId,
        name: 'Restore outcome one',
        source: NarrativeEventSourceRef.outcomeReceived(_outcomeOne),
        sceneId: _outcomeOneConsumerSceneId,
      ),
      _eventRecord(
        id: _outcomeTwoEventId,
        name: 'Restore outcome two after A',
        source: NarrativeEventSourceRef.outcomeReceived(_outcomeTwo),
        conditions: <NarrativeEventCondition>[
          NarrativeEventCondition.fact(_factA, true),
        ],
        sceneId: _outcomeTwoConsumerSceneId,
      ),
      _eventRecord(
        id: _mapEnterEventId,
        name: 'Map enter after restored outcomes',
        source: NarrativeEventSourceRef.mapEnter(_mapId),
        conditions: <NarrativeEventCondition>[
          NarrativeEventCondition.fact(_factB, true),
        ],
        sceneId: _mapEnterConsumerSceneId,
      ),
    ],
    legacyClaims: const <LegacySourceClaim>[],
  );

  return ProjectManifest(
    name: 'Save restore outbox integration',
    maps: const <ProjectMapEntry>[
      ProjectMapEntry(
        id: _mapId,
        name: 'Save Restore Outbox Map',
        relativePath: 'maps/save_restore_outbox_map.json',
      ),
    ],
    tilesets: const <ProjectTilesetEntry>[],
    facts: <NarrativeFactDefinition>[
      NarrativeFactDefinition(id: _factA, label: 'Outcome one processed'),
      NarrativeFactDefinition(id: _factB, label: 'Outcome two processed'),
      NarrativeFactDefinition(id: _factC, label: 'Map enter processed'),
    ],
    eventRegistry: registry,
    scenes: <SceneAsset>[
      _outcomeProducerScene(
        id: _outcomeOneProducerSceneId,
        outcomeId: _outcomeOneId,
      ),
      _outcomeProducerScene(
        id: _outcomeTwoProducerSceneId,
        outcomeId: _outcomeTwoId,
      ),
      _factScene(id: _outcomeOneConsumerSceneId, factId: _factA),
      _factScene(id: _outcomeTwoConsumerSceneId, factId: _factB),
      _factScene(id: _mapEnterConsumerSceneId, factId: _factC),
    ],
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
  );
}

NarrativeEventRecord _eventRecord({
  required String id,
  required String name,
  required NarrativeEventSourceRef source,
  required String sceneId,
  List<NarrativeEventCondition> conditions = const <NarrativeEventCondition>[],
}) {
  return NarrativeEventRecord.configuredStructurallyUnchecked(
    NarrativeEventDefinition(
      id: id,
      name: name,
      source: source,
      conditions: conditions,
      sceneId: sceneId,
      reusePolicy: NarrativeEventReusePolicy.reusable,
      priority: 0,
      order: 0,
    ),
    enabled: true,
  );
}

SceneAsset _outcomeProducerScene({
  required String id,
  required String outcomeId,
}) {
  return SceneAsset(
    id: id,
    name: 'Outcome producer $outcomeId',
    declaredOutcomes: <SceneOutcome>[
      SceneOutcome(id: outcomeId, label: outcomeId),
    ],
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: <SceneNode>[
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'end',
          kind: SceneNodeKind.end,
          payload: SceneEndPayload(sceneOutcomeId: outcomeId),
        ),
      ],
      edges: <SceneEdge>[
        SceneEdge(
          id: 'start_to_end',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.defaultFlow,
        ),
      ],
    ),
  );
}

SceneAsset _factScene({required String id, required String factId}) {
  return SceneAsset(
    id: id,
    name: 'Set $factId',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: <SceneNode>[
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'set_fact',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.setFact(factId: factId, value: true),
          ),
        ),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ],
      edges: <SceneEdge>[
        SceneEdge(
          id: 'start_to_fact',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'set_fact',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'fact_to_end',
          fromNodeId: 'set_fact',
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.actionCompleted,
        ),
      ],
    ),
  );
}

NarrativeOutcomeDelivery _delivery({
  required String deliveryId,
  required NarrativeOutcomeRef outcome,
}) {
  return NarrativeOutcomeDelivery(
    deliveryId: deliveryId,
    outcome: outcome,
    causationExecutionId: _causationExecutionId,
    rootCorrelationId: _rootCorrelationId,
    depth: 0,
    attemptCount: 0,
  );
}

MapData _map() => const MapData(
      id: _mapId,
      name: 'Save Restore Outbox Map',
      size: GridSize(width: 3, height: 3),
      layers: <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: <MapEntity>[
        MapEntity(
          id: 'spawn',
          name: 'Spawn',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 1, y: 1),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.south,
          ),
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: 'spawn'),
    );
````

---

Fin de l'Evidence Pack NS-EVENT-V2-19.
~~~~~~~~
