# NS-EVENT-V2 - Phase F1 - Evidence Pack

## 1. Identite

```text
Lot : NS-EVENT-V2 - PHASE F1
Objet : Unified Runtime Authority, Lifecycle, Progress & Outcome Outbox V0
Repository : /Users/karim/Project/pokemonProject
Branche : main
Baseline : 5bf62901d1071d3e17553baef016e4da3b733892
Verdict : BLOCKED at F1-0
Phase F2 : NOT READY
```

## 2. Gate 0

Commandes :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 30
```

Sortie utile exacte :

```text
/Users/karim/Project/pokemonProject
main
 M packages/map_editor/pubspec.lock
 packages/map_editor/pubspec.lock | 16 ++++++++--------
 1 file changed, 8 insertions(+), 8 deletions(-)
packages/map_editor/pubspec.lock
5bf62901 feat(event-v2): close NS-EVENT-V2 Phase E-bis
5d920469 feat(event-v2): complete NS-EVENT-V2 Phase E
```

## 3. Drift preexistant

```text
Path : packages/map_editor/pubspec.lock
SHA-256 initial : a6646437ad4410fa4859f0f8007b0b9589888febc0c6df8b165d7681a9ab52dc
Action F1 : aucune
```

Le hash final est verifie au Gate Git final.

## 4. Fichiers lus

Documents :

- prompt Phase F1 attache ;
- `AGENTS.md` fourni ;
- `codex_rule.md` ;
- `skills/README.md` et skills d'execution, TDD, sub-agents, verification et
  code review ;
- `pokemap_roadmap_mecaniques_fangame.md` ;
- `MVP Selbrume/event_builder_v2_architecture_decisions.md` ;
- `MVP Selbrume/road_map_event_builder_v2.md` ;
- rapports Phase A, D, E, E-bis et preuves Scene/runtime demandees.

Code principal :

- `packages/map_core/lib/src/models/narrative_fact.dart` ;
- `packages/map_core/lib/src/models/game_state.dart` ;
- `packages/map_core/lib/src/models/save_data.dart` ;
- `packages/map_core/lib/src/projection/world_rule_projection.dart` ;
- `packages/map_core/lib/src/authoring/event_builder_contract.dart` ;
- `packages/map_core/lib/src/operations/narrative_event_registry_codec.dart` ;
- `packages/map_core/lib/src/read_models/narrative_event_source_index.dart` ;
- `packages/map_core/lib/src/runtime/scene_runtime_executor.dart` ;
- `packages/map_gameplay/lib/src/script_condition_evaluator.dart` ;
- `packages/map_gameplay/lib/src/game_state_mutations.dart` ;
- `packages/map_runtime/lib/src/application/runtime_story_branching.dart` ;
- `packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_writer.dart` ;
- `packages/map_runtime/lib/src/application/scene_runtime/scene_event_runtime_hook.dart` ;
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart` ;
- repositories/use cases save/load et tests associes.

## 5. MCP Dart

```text
Disponibilite : indisponible
Symboles MCP invoques : aucun
Fallback : rg, sed, nl, tests Dart/Flutter, analyze
```

## 6. Sous-agents et incidents

| ID | Role | Statut/verdict |
|---|---|---|
| `019f611e-cd34-7fd3-b8d8-b1a938220e78` | A Dispatch Authority | termine, BLOCKED contractuellement |
| `019f611e-d1b6-74b1-bfb4-3515eeb1cd7d` | B Candidate Eligibility | termine, F1-0 BLOCKED |
| `019f611e-d499-7e90-a513-1ca06eea2276` | C Progress Domain | termine, non implemente apres stop |
| `019f611e-d7a7-7e63-887b-616f72cb142c` | D Lifecycle initial | termine, risques identifies |
| `019f611e-da89-7691-a06e-737e04292a97` | E Outbox | termine, contradiction overlap |
| `019f611e-ddef-7041-a338-89674242514d` | F Persistence Gate | termine, gate absent |
| `019f6129-16c6-7aa0-a5ab-1f54383b4d02` | G Legacy Compatibility | termine, blocker confirme |
| `019f6130-bd64-7f21-886a-d80feb18614d` | H Tests/F2 | termine, PARTIAL, F2 NOT READY |
| `019f6124-ca63-7b40-9468-f422c34ab33c` | B reassign | termine, blocker confirme |
| `019f6127-4677-76d0-b06a-2fc5feb78b78` | D reassign | termine, B2 bloque |
| `019f6131-e92d-7d73-8b9f-612825f7083a` | R1 Runtime Integrity | termine, BLOCKER-CONFIRMED |
| `019f6134-d41d-7152-883e-3503309fc1d3` | R2 Product Truthfulness | termine, BLOCKER-CONFIRMED |

Incidents : limite de threads au premier fan-out, deux roles repris, une
configuration de fork invalide relancee. Aucun fichier touche par un agent.

## 7. Preuve normative du STOP

ADR-EV2-012 :

```text
Le resolver Fact utilise la semantique canonique de NarrativeFactDefinition
et doit prouver les valeurs par defaut avant l'activation runtime F1.
```

Prompt F1-0 :

```text
Si deux chemins production evaluent le meme Fact differemment :
STOP PHASE F1.
Produire un Blocker Report plutot que choisir arbitrairement.
```

## 8. Fact semantics matrix

| Definition/etat | World Rule | Scene write | Scene condition | Event legacy |
|---|---|---|---|---|
| definition absente, cle brute absente | false | unknownFact | unsupported canonical fact | false |
| default=false, flag absent | false | n/a | unsupported | false |
| default=true, flag absent | true | n/a | unsupported | false |
| alias present | true | alias | unsupported | Fact ID false |
| default=true, write false | true | clear alias, applied | unsupported | false |

Extraits cibles :

```text
world_rule_projection.dart:88-90
runtimeKey = fact.legacyFlagName ?? fact.id
active = activeFlags.contains(runtimeKey) || fact.defaultValue

scene_consequence_runtime_writer.dart:71-74
runtimeKey = fact.legacyFlagName ?? fact.id
false -> mutations.clearFlag(gameState, runtimeKey)

event_builder_contract.dart:201-204
factIsTrue -> flagIsSet(referenceId)
factIsFalse -> flagIsUnset(referenceId)

script_condition_evaluator.dart:86-95
contains(flagName) / !contains(flagName)

playable_map_game.dart:5489-5499
factLikeStoryFlag supported; canonical fact -> UnsupportedError
```

## 9. Authority/claim evidence

ADR-EV2-008 :

```text
global collision -> dualRead ne demarre pas
local invalid target/corpus -> tombstone source, autres sources continuent
```

Implementation :

```text
narrative_event_registry_codec.dart:322
canStartDualRead = globalConflicts.isEmpty && invalidBySource.isEmpty
```

Test existant : une cible absente remplit `invalidBySource` et rend
`canStartDualRead` false. Ce signal ne permet pas a lui seul de distinguer
blocage global et tombstone local au preflight demande.

## 10. Mode truth table cible

| Mode | Claim | Eligible | Decision | Legacy |
|---|---|---:|---|---|
| legacyOnly | quelconque | quelconque | noMatch | autorise |
| dualRead | absent | oui | handled | interdit |
| dualRead | absent | non | noMatch | autorise |
| dualRead | valide | oui | handled | interdit |
| dualRead | valide | non | claimedButIneligible | interdit |
| dualRead | tombstone | quelconque | claimedButIneligible | interdit |
| v2Only | quelconque | oui | handled | interdit |
| v2Only | quelconque | non | noMatch | interdit |

Etat : cible ratifiee, non implementee.

## 11. Candidate/condition evidence

- source index : configured + enabled seulement ;
- ordre : priority DESC, order ASC, eventId ASC ;
- conditions : union fermee Fact / V2 consumed ;
- liste : immutable, ordre preserve ;
- evaluator V2 : absent ;
- snapshot Fact : impossible a finaliser avant la ratification.

Aucune trace planner ou fixture condition F1 n'existe ; ne pas les inventer.

## 12. Progress/wire evidence

```text
NarrativeEventProgress : absent
NarrativeOutcomeDelivery : absent
GameState.narrativeEventProgress : absent
SaveData.narrativeEventProgress : absent
consumedEventIds legacy : present et inchange
```

Aucun JSON golden F1, old-save fixture V2 ou generated file n'a ete cree.

## 13. Lifecycle evidence

| Cas | Contrat existant | Besoin F1 |
|---|---|---|
| Scene awaits | executor awaitable | reusable |
| consequences | writer controle | reusable apres Fact closure |
| lock Event | absent | gate/lease memoire |
| cancelled | aplati par hook legacy | statut distinct |
| atomic V2 commit | absent | consequences + consume + outcomes |
| cross-event concurrence | non serialisee | revision/CAS ou serialize |

## 14. Outbox evidence

Machine cible uniquement :

```text
pending persisted -> dispatching memory -> delivered persisted
```

Tension a documenter : le codec B1 rejette l'overlap, tandis que le processor
B3 garde une defense si un etat incoherent est injecte directement en memoire.
Ces deux protections peuvent coexister.

## 15. Save/load evidence

Les tests existants prouvent le save/reload legacy post-completion. Ils ne
prouvent ni progression V2, ni busy pendant Scene, ni dispatching. Aucun faux
checkpoint n'a ete ajoute.

## 16. Commandes baseline et resultats

### map_core

```bash
dart test --reporter=compact \
  test/narrative_event_registry_test.dart \
  test/narrative_event_source_index_test.dart \
  test/game_state_persistence_test.dart \
  test/scene_runtime_executor_test.dart
```

```text
+47: All tests passed!
```

```bash
dart test --reporter=compact \
  test/event_builder_contract_test.dart \
  test/world_rule_projection_test.dart
```

```text
+10: All tests passed!
```

```bash
dart analyze
```

```text
No issues found!
```

### map_gameplay

Commande adaptee au vrai nom `script_system_integration_test.dart` :

```bash
dart test --reporter=compact \
  test/script_system_integration_test.dart \
  test/game_state_mutations_test.dart
```

Echec de chargement baseline : package config stale, package `uuid` de
`map_core` non resolu et language versions obsoletes. `dart pub deps` demande un
`dart pub get`; non lance pour eviter un lockfile hors scope.

```bash
dart analyze
```

```text
No issues found!
```

### map_runtime

```bash
flutter test --reporter=compact \
  test/scene_event_runtime_hook_test.dart \
  test/scene_consequence_runtime_writer_test.dart \
  test/scene_runtime_state_persistence_gate_test.dart \
  test/p3_save_load_narrative_state_roundtrip_test.dart \
  test/p5_gameplay_save_load_beta_roundtrip_test.dart
```

```text
+40: All tests passed!
```

```bash
flutter test --reporter=compact \
  test/runtime_story_branching_test.dart \
  test/scene_consequence_runtime_writer_test.dart
```

```text
+15: All tests passed!
```

Une premiere commande avait melange tests runtime et map_core sous le package
config Flutter runtime ; elle a echoue car `package:test` de map_core n'etait
pas resolu dans ce contexte. Les suites ont ete relancees dans leur package et
ont passe, comme montre ci-dessus.

### Suites completes et host

```bash
# packages/map_core
dart test --reporter=compact
```

```text
+2908: All tests passed!
```

```bash
# packages/map_runtime
flutter test --reporter=compact
flutter test --no-color --reporter=expanded
```

```text
+1592 ~1 -17: suite en echec
```

Tests en echec :

1. `selbrume_map_catalog_integrity_test.dart`: port catalog exact structural contracts ;
2. `selbrume_map_catalog_integrity_test.dart`: bourg catalog canonical map ;
3. `selbrume_map_catalog_integrity_test.dart`: zones/narrative placements/landmarks ;
4. `p6_selbrume_first_trainer_battle_golden_slice_test.dart`: Grant battle setup ;
5. `selbrume_map_navigation_contract_test.dart`: port navigation ;
6. `selbrume_map_navigation_contract_test.dart`: bourg navigation ;
7. `selbrume_map_navigation_contract_test.dart`: ten maps mutually reachable ;
8. `selbrume_asset_integrity_contract_test.dart`: referenced images/frames ;
9. `selbrume_asset_integrity_contract_test.dart`: open-sea compatibility asset ;
10. `selbrume_asset_integrity_contract_test.dart`: port v3 atlases/provenance ;
11. `selbrume_asset_integrity_contract_test.dart`: bourg atlas resolution ;
12. `p6_selbrume_beta_validator_pass_test.dart`: beta validator no blocker ;
13. `selbrume_map_render_smoke_test.dart`: port render ;
14. `selbrume_map_render_smoke_test.dart`: bourg render ;
15. `selbrume_port_visual_invariants_test.dart`: south-east visual water ;
16. `selbrume_port_visual_invariants_test.dart`: continuous non-black render ;
17. `selbrume_port_visual_invariants_test.dart`: review crops without gaps.

Ils concernent des contrats/fixtures/assets Selbrume preexistants. Aucun fichier
F1 de production n'existe, donc ils ne peuvent pas etre une regression F1.

```bash
# packages/map_runtime
flutter analyze --no-fatal-infos
```

```text
Exit 0; 348 infos; 0 warning; 0 erreur.
```

```bash
# examples/playable_runtime_host
flutter test --reporter=compact \
  test/runtime_launch_save_test.dart \
  test/phase_a_golden_slice_launch_test.dart \
  test/p5_runtime_project_disk_smoke_test.dart
```

```text
+4: All tests passed!
```

## 17. Build et performance

```text
Build produit F1 : non execute, aucun code F1 apres STOP
Suite runtime complete : executee, 17 echecs baseline Selbrume
Performance F1 p50/p95 : non mesuree, contrats inexistants
```

Meilleure validation alternative : compilation des tests Flutter cibles et
analyses Dart `map_core`/`map_gameplay`.

## 18. Inventaire des fichiers

Crees :

- `reports/narrativeStudio/events/ns_event_v2_phase_f1_runtime_authority_progress_v0.md` ;
- `reports/narrativeStudio/events/ns_event_v2_phase_f1_evidence_pack.md`.

Modifies en production/tests/generated/roadmap : aucun.

Supprimes : aucun.

Le contenu complet des fichiers crees est le contenu present de ces deux
artefacts. Les auto-inclure recursivement dans eux-memes serait non fini ; les
fichiers sont fournis integralement dans le working tree et leurs diffs complets
sont inspectables par Git.

## 19. Reviews R1/R2

R1 a tente de refuter activement le blocker. Verdict :
`BLOCKER-CONFIRMED`. Il n'existe aucun resolver public qui combine alias,
default, override false et definitions ambiguës. Les deux contre-exemples
cross-production sont certains.

R2 a cherche les faux blockers et les suraffirmations. Verdict :
`BLOCKER-CONFIRMED`. Il confirme qu'aucune interpretation plus etroite ne permet
de poursuivre, mais a exige six corrections de veracite, toutes appliquees :

- preuve de divergence qualifiee par inspection, pas par test cross-path ;
- statuts agents finalises ;
- overlap outbox reclasse en garde defensive compatible avec codec strict ;
- hypothese de cle brute absente explicitee ;
- timing oneShot reformule autour du commit GameState ;
- identite source/provenance des maps invalides reconnue.

## 20. Git final et anti-scope

```bash
git status --short --untracked-files=all
```

```text
 M packages/map_editor/pubspec.lock
?? reports/narrativeStudio/events/ns_event_v2_phase_f1_evidence_pack.md
?? reports/narrativeStudio/events/ns_event_v2_phase_f1_runtime_authority_progress_v0.md
```

```bash
git diff --stat
```

```text
 packages/map_editor/pubspec.lock | 16 ++++++++--------
 1 file changed, 8 insertions(+), 8 deletions(-)
```

```bash
git diff --name-only
```

```text
packages/map_editor/pubspec.lock
```

Les deux commandes `git diff` n'incluent pas les rapports non suivis. Leur
presence est prouvee par `git status --untracked-files=all`.

```bash
git diff --check
```

```text
<empty>
```

Anti-scope demande :

```text
packages/map_editor/pubspec.lock
```

Cette sortie est exclusivement le drift preexistant. Aucun autre fichier
editor/battle/bridge/scenario/host/selbrume/asset n'apparait.

```text
SHA-256 final packages/map_editor/pubspec.lock:
a6646437ad4410fa4859f0f8007b0b9589888febc0c6df8b165d7681a9ab52dc

HEAD final:
5bf62901d1071d3e17553baef016e4da3b733892
```

Le hash est identique au Gate 0. Aucun commit Git n'a ete cree.

## 21. Entry Gate F2

```text
F1-0 : BLOCKED
F1-A : BLOCKED
F1-B1 : BLOCKED
F1-B2 : BLOCKED
F1-B3 : BLOCKED
Phase F2 : NOT READY
```

## 22. Risques et prochain lot

Blocker principal : absence de semantique Fact canonique cross-production.

Clarifications secondaires :

- gate global claim versus tombstone local ;
- articulation codec strict / garde defensive overlap ;
- transaction host/cancellation avant bridges F2 ;
- metadata dependencies `map_gameplay` stale ;
- reserve E-bis editor map undo hors scope.

Prochain lot recommande : **Canonical Fact Runtime Semantics & F1 Contract
Clarification V0**, puis reprise de F1 depuis F1-0.
