# NS-EVENT-V2 — F1-PREREQ — Evidence Pack

## 1. Identité du lot

```text
Lot : NS-EVENT-V2 — F1-PREREQ
Baseline : a2ee6bbdb67389336452c5431e523f179a481335
Baseline production : 5bf62901d1071d3e17553baef016e4da3b733892
Branche : main
Date : 2026-07-14
F1-PREREQ : CLOSED
Phase F1 : READY
Phase F2 : NOT READY
```

## 2. Gate 0 exact

```text
pwd
/Users/karim/Project/pokemonProject

git branch --show-current
main

git status --short --untracked-files=all
 M packages/map_editor/pubspec.lock

git diff --stat
 packages/map_editor/pubspec.lock | 16 ++++++++--------
 1 file changed, 8 insertions(+), 8 deletions(-)

git diff --name-only
packages/map_editor/pubspec.lock
```

Le log exact partait de :

```text
a2ee6bbd docs(event-v2): report NS-EVENT-V2 Phase F1 blocker
5bf62901 feat(event-v2): close NS-EVENT-V2 Phase E-bis
5d920469 feat(event-v2): complete NS-EVENT-V2 Phase E
e932d9a2 feat(event-v2): enhance migration plan with context validation and strict JSON parsing
025bf9bc feat(event-v2): complete NS-EVENT-V2 Phase D
39a9f7bb ```text feat(selbrume): add forest layer to map bourg selbrume ```
56fd6342 feat(editor): use dropdown for layer creation type
85008b90 feat(selbrume): add terrain layer and update paths in map bourg selbrume
1fc32b4f feat(editor): allow confirmed bulk deletion of map layers and update selbrume project assets
e0e4876e test(editor): add smoke test for terrain preset dropdown menus
02de2ffe feat(editor): add design-system dropdown field
816671f7 feat: refine Port des Brisants visuals and editor controls
928cccae test(selbrume): add Port des Brisants visual refinement tests
9fae047b test
7797d332 feat(selbrume): rebuild Port des Brisants from reference
a9a12723 feat(selbrume): generate seamless water family v2
bd95861a feat(selbrume): add provenance-locked visual kit v2
459242b7 feat(selbrume): validate authored maps without rebuilding
5edc3cf4 fix(selbrume): recover authored map placements
a4c7dead feat(editor): add explicit placement origin migration
39e7dc37 fix(editor): guard placement ownership and bulk saves
96d1862f fix(editor): preserve authored map placements on load
d9e08979 chore: remove generated skill cache
60b3a8af tools: add reference-to-PokeMap authoring skill
fc40a09d SEL-MAP-001: normalize legacy map filenames
e0def288 SEL-MAP-001: build Selbrume beta maps and assets
eb1b4998 NS-EVENT-V2 PHASE C: Legacy Compatibility & Non-Destructive Migration
fdaf4e5d NS-EVENT-V2 PHASE B: Canonical Domain Contracts & Structural Source Index
61941c39 NS-EVENT-V2 PHASE A: Canonical Architecture Ratification
d26bfa9c NS-EVENT-RESET-00: Canonical Event Sources & Event Builder V2 Ultra Roadmap
```

Versions et résolution Gate 0 :

```text
packages/map_core: Dart SDK 3.12.1 stable macos_arm64; dart pub deps PASS
packages/map_gameplay: Dart SDK 3.12.1; dart pub deps initial FAIL (lock stale)
packages/map_gameplay: dart pub get PASS; dart pub deps PASS
packages/map_runtime: Flutter 3.46.0-0.3.pre beta, Dart 3.13.0 beta; flutter pub deps PASS
```

## 3. Drifts et hashes

| Fichier | HEAD SHA-256 | Worktree SHA-256 | Attribution |
|---|---|---|---|
| `packages/map_editor/pubspec.lock` | `78c3a9fe...` | `a6646437...` | préexistant, inchangé par le lot |
| `packages/map_gameplay/pubspec.lock` | `83b13b3f...` | `ef1601ab...` | `dart pub get` autorisé |
| `packages/map_gameplay/.dart_tool/package_config.json` | `e418e628...` | `3d83ef81...` | refresh package config autorisé |
| `packages/map_gameplay/.dart_tool/package_graph.json` | `c95df1a5...` | `fa40b1c3...` | refresh package graph autorisé |
| `selbrume/project.json` | `11d9af7f...` | `b1d7e582...` | concurrent, apparu après Gate 0 |

Hashes complets :

```text
map_editor lock HEAD     78c3a9fee5b8cb0949c518c93fd4fae70b18fe5567334957c581d59c3ede37da
map_editor lock worktree a6646437ad4410fa4859f0f8007b0b9589888febc0c6df8b165d7681a9ab52dc
map_gameplay lock HEAD   83b13b3f71daf4094211259784b259d33251d947f9c02bf9804ec0310fa2ad00
map_gameplay lock current ef1601ab55e8a3361fceb8c4d19071c752bccfc12f345190816f4afd4dbaaac5
package_config HEAD       e418e628ed2e1c053947b3a71bd8c4c69464cc34f4a250b31172f268a655a172
package_config current    3d83ef811cee2c52ebdf49cf7ca406d325f3a4f232784b4cd1ef80dba684594f
package_graph HEAD        c95df1a593d9ebe4e3565f006fcd686b4326e349f4e9e32705b32aef25bb097f
package_graph current     fa40b1c3d386861cd08ad17a372e0addafefefb08a6b292ea9df587f97f8d055
selbrume project HEAD     11d9af7fe0b7cc465af321725c4046b78bff2701c86c6c970b620984b7cd8f0a
selbrume project current  b1d7e582f40cf95776c07c5be004221cadd1ab044239b7817bc38c6ddb6815f3
```

Le lock gameplay ajoute uniquement `uuid 4.5.3` et `fixnum 1.1.1`
transitifs. Aucun changement volontaire de dépendance.

## 4. Documents et zones lus

- `MVP Selbrume/event_builder_v2_architecture_decisions.md`
- `MVP Selbrume/road_map_event_builder_v2.md`
- rapports Phases A et F1 blocker ;
- rapports Facts V1-18, World Rules V1-20, Scene Consequence V1-28-ter et
  Runtime State Persistence V1-33 ;
- modèles `NarrativeFactDefinition`, `GameState`, `SaveData`,
  `StoryFlags`, `ProjectManifest` ;
- conversions `gameStateFromSaveData`, `saveDataFromGameState`,
  `normalizeLoadedGameState` et new-game ;
- diagnostics/projections World Rules ;
- Scene writer, conditions, host callbacks et `PlayableMapGame` ;
- `ScriptConditionEvaluator` et tous ses call sites ;
- claims, provenance, migration planner/read models ;
- repository disque et tests de round-trip.

## 5. MCP Dart

MCP Dart indisponible dans l'environnement. Fallback réel : `rg`, `sed`,
tests, analyses, build_runner, build macOS et reviews. Aucun symbole MCP fictif.

## 6. Sous-agents

| ID | Rôle | Résultat |
|---|---|---|
| `019f617b-e1a7-7532-b4d5-850abc530734` | A Fact Domain & Save Codec | PASS |
| `019f618b-2d4d-7ba0-87d2-f549f5496462` | B Resolver & Writer | PASS |
| `019f619e-8ae1-77e1-ae3f-b001d29fbd33` | C Production Consumers | PASS avec réserve |
| `019f617b-e522-7802-90fe-3e9ef57a5cd3` | D Dual-Read | PASS après correction |
| `019f617b-e900-76d1-b462-67279aa8f2fc` | E Outbox | PASS après correction crash |
| `019f618b-3f7b-7292-9556-2ee0a86114de` | F Save/Load | PASS |
| `019f61a9-4509-76c3-be34-de42d91332bd` | G Tests/Docs | incident repris, PASS final |
| `019f6190-4ff0-76d3-b6a3-454c0b2951b2` | R1 Runtime Integrity | PASS |
| `019f6190-62ad-7d30-9004-fdad00d77835` | R2 Compatibility | PASS |

Incident G : quatre fichiers touchés malgré le mandat lecture seule. L'orchestrateur
a contrôlé, repris et retesté chaque modification. Le benchmark a été conservé ;
les gates PR-C ont été corrigés et stabilisés.

Incident PR-B : R2 a détecté que le premier branchement donnait le contexte
Fact à toutes les pages d'un événement, y compris les pages legacy non marquées.
L'orchestrateur a introduit `EventPageResolver.contextForPage`, une détection de
provenance Event Builder stricte et quatre cas de coexistence. R1 et R2 ont
revu l'arbre corrigé et rendu PASS sans blocker.

## 7. Addenda ADR

### ADR-EV2-012-A

- état exact `overridesByFactId` ;
- priorité override > alias/runtimeKey > default ;
- writer symétrique ;
- anciennes saves sans migration eager ;
- orphelins conservés ;
- collisions runtime key bloquantes.

### ADR-EV2-008-A

- `canStartDualRead == canEnterDualRead` ;
- entrée stricte ;
- runtime readiness séparée ;
- preuve corpus obligatoire avec claims ;
- tombstones locaux tolérés par `canRunDualRead` ;
- conflits globaux bloquants ;
- résolution source/provenance fermée.

### ADR-EV2-014-A

- `deliveryId` identité stable et clé d'idempotence ;
- wire/constructeurs stricts pour overlap et duplicate pending ;
- garde mémoire overlap sans dispatch et sans réparation au decode ;
- retry/reload gardent la même envelope ;
- création non durable, pending durable et terminal durable distingués ;
- limite exactly-once externe explicite ;
- matrice et 17 tests futurs.

## 8. Matrice Fact

| Default | Alias | Override | Valeur |
|---:|---:|---:|---:|
| false | absent | absent | false |
| true | absent | absent | true |
| false | true | absent | true |
| true | absent | false | false |
| true | true | false | false |
| false | absent | true | true |

Override orphelin : conservé, non appliqué.

## 9. JSON Fact goldens

```json
{
  "overridesByFactId": {
    "fact_gate_open": false,
    "fact_rival_defeated": true
  }
}
```

Ancien JSON sans `narrativeFactRuntimeState` : état vide. Un sous-arbre null,
une valeur non booléenne, un ID vide ou non trim-exact : rejet.

## 10. Collision fixtures

Les tests couvrent duplicate Fact ID, duplicate alias, alias égal à l'ID d'un
autre Fact et duplicate runtime key. Tous retournent un catalogue invalide ou
un résultat typé ; aucun premier gagnant.

## 11. Cross-consumer outputs

Les six lignes override/alias/default donnent la même valeur pour :

1. resolver direct ;
2. World Rule ;
3. Scene condition `kind=fact` ;
4. ScriptCondition avec contexte Fact.

`factLikeStoryFlag` et ScriptCondition sans contexte restent raw. Le contexte
production est maintenant page-scoped : schema Event Builder courant et ancien
`reusePolicy` valide sont canoniques ; page non marquée et schema futur restent
raw. La présence explicite d'un schema inconnu interdit le fallback legacy.

## 12. Save/reload outputs

- true, false et override orphelin survivent au disque ;
- default true + write false + save/reload reste false ;
- ancienne save charge l'état vide ;
- simple load n'infère aucun override depuis StoryFlags ;
- `consumedEventIds` reste séparé.

Réserve caractérisée : le chemin historique `GameState -> SaveData` ne possède
pas de paramètre pour tous les consumed IDs ; le vrai
`FileGameSaveRepository` les préserve. Aucun comportement legacy n'a été
réécrit dans ce prérequis.

## 13. Claim truth table

| Claims/evidence | Local | Global | canEnter | canRun |
|---|---|---|---:|---:|
| aucun claim | aucun | aucun | true | true |
| claim valide + evidence | aucun | aucun | true | true |
| claims sans evidence | non prouvé | aucun | false | false |
| target/provenance/fingerprint stale | tombstone | aucun | false | true |
| collision cohorte/source/provenance | variable | conflit | false | false |

`resolveSource` et `resolveProvenance` refusent une indexation runtime non
prouvée. Les résolutions valides d'une occurrence partagent la même cohorte.

## 14. Typed resolution fixtures

Cas testés : source absente, source valide, source tombstone, provenance absente,
provenance valide, provenance tombstone, target absent/draft/mauvaise source,
provenance absente/ambiguë/divergente, fingerprint stale, membre inattendu et
collision globale. Collections et diagnostics sont immuables et ordonnés.

## 15. Outbox matrix

| État | Wire futur | Processor mémoire futur |
|---|---|---|
| pending seulement | valide | dispatchable |
| delivered seulement | valide | non rejoué |
| pending + delivered même ID | rejet | nettoyage sans dispatch |
| duplicate pending même ID | rejet | incohérence, aucun premier gagnant |
| pending durable après crash pré-terminal | valide, même ID | retry même commande |
| création jamais sauvegardée après crash | absente | état producteur précédent |
| terminal durable | valide | jamais rejoué |
| effet externe | hors exactly-once V0 | protocole idempotent requis |

Aucun type outbox n'est implémenté par ce lot.

## 16. Inventaire des fichiers modifiés

| Fichier | Zones | Raison / impact |
|---|---|---|
| `MVP Selbrume/event_builder_v2_architecture_decisions.md` | trois addenda | ratification PR-0/PR-D |
| `MVP Selbrume/road_map_event_builder_v2.md` | pré-F1 + synthèse | F1-PREREQ CLOSED, F1 READY |
| `packages/map_core/lib/map_core.dart` | exports | API Fact publique |
| `packages/map_core/lib/src/authoring/event_builder_contract.dart` | provenance page | qualification canonical/raw stricte |
| `packages/map_core/lib/src/diagnostics/scene_diagnostics.dart` | operators Fact | equals bool accepté |
| `packages/map_core/lib/src/diagnostics/world_rule_diagnostics.dart` | préflight Fact | collisions bloquantes |
| `packages/map_core/lib/src/models/game_state.dart` + generated | champ Fact | runtime state persistant |
| `packages/map_core/lib/src/models/save_data.dart` + generated | champ Fact | wire save persistant |
| `packages/map_core/lib/src/operations/game_state_persistence.dart` | conversions | round-trip du champ |
| `packages/map_core/lib/src/operations/narrative_event_registry_codec.dart` | index claims | gates/evidence/tombstones |
| `packages/map_core/lib/src/projection/world_rule_projection.dart` | reader | resolver partagé |
| `packages/map_core/lib/src/validation/validators.dart` | project facts | collisions runtime keys |
| tests core existants | assertions | old saves, diagnostics, rules, claims |
| `packages/map_core/test/event_builder_authoring_operations_test.dart` | provenance | current/legacy/absent/malformed/future |
| `packages/map_gameplay/lib/src/event_page_resolver.dart` | contexte page | sélection canonical/raw par page |
| `packages/map_gameplay/lib/src/new_game_state_builder.dart` | default | état Fact vide |
| `packages/map_gameplay/lib/src/script_condition_evaluator.dart` | contexte Fact | canonical/raw compatibility |
| `packages/map_gameplay/pubspec.lock` + `.dart_tool` | résolution | uuid/fixnum transitifs |
| `packages/map_runtime/lib/map_runtime.dart` | export helper | API condition Fact |
| Scene writer/result | setFact | writer canonique + résultat |
| `file_game_save_repository.dart` | normalization | conservation Fact |
| `playable_map_game.dart` | Scene/Script contexts | consumers canoniques |
| tests runtime existants | assertions | rollback/save/consumers |

## 17. Fichiers créés

Les douze fichiers source/test créés sont reproduits intégralement dans les
annexes. Les deux rapports créés sont :

- `reports/narrativeStudio/events/ns_event_v2_f1_prereq_canonical_fact_runtime_closure_v0.md` ;
- `reports/narrativeStudio/events/ns_event_v2_f1_prereq_evidence_pack.md`.

Le premier est intégralement disponible comme artefact frère. Le second ne peut
pas s'inclure lui-même sans récursion infinie ; c'est l'unique limite
auto-référentielle à l'exigence de contenu complet de `codex_rule.md`.

## 18. Commandes ciblées et résultats

```text
map_core PR-A
dart test --reporter=compact   test/narrative_fact_runtime_state_test.dart   test/game_state_persistence_test.dart   test/save_data_test.dart
=> 48 PASS

map_runtime PR-A
flutter test --reporter=compact   test/narrative_fact_runtime_save_load_test.dart   test/p3_save_load_narrative_state_roundtrip_test.dart   test/p5_gameplay_save_load_beta_roundtrip_test.dart
=> 6 PASS

map_core PR-B
=> 21 PASS

map_gameplay PR-B
=> 23 PASS

map_runtime PR-B
=> 27 PASS

map_core provenance Event Builder
=> 13 PASS

map_editor comportement historique NS-EVENT-13
=> 1 PASS

map_core PR-C
=> 113 PASS

map_runtime cumul ciblé
=> 39 PASS

host smoke
=> 4 PASS
```

## 19. Suites complètes

```text
cd packages/map_core && dart test --reporter=compact
=> 2955 PASS

cd packages/map_gameplay && dart test --reporter=compact
=> 245 PASS

cd packages/map_runtime && flutter test --reporter=compact
=> 1559 PASS, 1 SKIP, 45 FAIL

runtime subset excluding files mentioning Selbrume/selbrume
=> 112 files, 1102 PASS
```

## 20. Liste exacte des 45 erreurs runtime globales

Toutes échouent au load du projet concurrent avec
`Invalid argument(s): v2 is not one of the supported values: v1`.

```text
(setUpAll)
P6-05 builds Grant trainer battle setup and persists a controlled victory outcome
P6-04 triggers repo-local Route 1 encounter and persists a minimal capture
P6-01 loads canonical Selbrume maps and builds New Game from explicit spawn
port navigation connects local anchors and blocks the boat basin
bourg navigation joins Port, Bois, spawn, Mael reserve and house
maison_joueur navigation keeps the doorway corridor reciprocal
bois navigation keeps exits loops clearings and canopy passable
marais navigation reaches every reserve and blocks all basins
passage navigation keeps a three-cell causeway and blocks the sea
phare_exterieur navigation reaches both open doors from Passage
phare_interieur navigation connects entrance note optional room and top
sommet keeps the full confrontation zone readable and return open
cabane_gardien reaches both exits journal and key from its arrival
keeps all ten Selbrume maps mutually reachable through static geometry
P6-08 boots repo-local Selbrume in PlayableMapGame without crashing
validates every image and frame referenced by the Selbrume beta maps
registered shared open-sea compatibility asset
port reference v3 atlases and provenance are runtime-ready
bourg asset resolution covers every preserved seed placement atlas
maison_joueur asset atlas exposes the exact twenty interior elements
cabane_gardien reuses only the exact Task8 cabin atlas contracts
bois asset atlas exposes twelve visible forest contracts
marais asset atlas exposes twenty-three exact marsh contracts
passage asset atlas exposes fourteen exact causeway contracts
phare_exterieur asset atlas exposes thirteen exact contracts
phare_interieur atlas exposes twenty-five exact dungeon contracts
sommet FX atlas exposes nine exact static and animated contracts
P6-07 validates repo-local Selbrume golden slice with no beta blocker
P6-06 persists the full Selbrume golden slice through real disk save/load
port render paints registered placements and planned landmarks
bourg render paints the four canonical landmarks and seed atlases
maison_joueur render paints the interior atlas and landmarks
cabane_gardien renders the closed state and hides journal reserve
bois render paints forest atlas landmarks and fog composition
marais render paints landmarks and cabin occlusion
passage render paints causeway props without false occlusion
phare_exterieur render paints both landmarks and occlusion
phare_interieur render paints the dungeon without false occlusion
sommet render separates the passable off FX from structural art
renders every Selbrume beta map overview at 320x240 through MapLayersComponent
the four Selbrume interiors expose the canonical seven layers
P6-03 triggers repo-local Selbrume first narrative interaction and persists its state
Selbrume Port visual-only invariants (setUpAll)
P6-02 builds repo-local Selbrume initial party and bag and roundtrips SaveData
```

## 21. Analyses et generation

```text
packages/map_core: dart analyze
No issues found!

packages/map_gameplay: dart analyze
No issues found!

packages/map_runtime: flutter analyze --no-fatal-infos <2 fichiers finaux>
No issues found!

packages/map_runtime: flutter analyze
348 info issues; exit 1 car infos fatales par défaut.

packages/map_runtime: flutter analyze --no-fatal-infos
348 infos; exit 0; aucune warning/error.

packages/map_core:
dart run build_runner build --delete-conflicting-outputs
success; second passage écrit 0 output.
warning: analyzer language 3.9 vs SDK 3.12.
```

## 22. Host smoke et build

```text
flutter test --reporter=compact   test/runtime_launch_save_test.dart   test/phase_a_golden_slice_launch_test.dart   test/p5_runtime_project_disk_smoke_test.dart
=> 4 PASS

flutter build macos --debug
=> PASS
build/macos/Build/Products/Debug/playable_runtime_host.app
```

## 23. Performance brute finale

Machine : MacBookPro18,3, Apple M1 Pro, 10 cœurs, 32 GB, macOS 27.0
26A5378j. Dart 3.12.1 stable macOS arm64, JIT, AOT non mesuré.

```text
resolver_override_hit v1       mean .214 median .183 p95 .526 us
resolver_alias_hit v1          mean .221 median .190 p95 .582 us
resolver_default_fallback v1   mean .207 median .142 p95 .396 us
resolver_absent v1             mean .032 median .024 p95 .088 us
resolver_override_hit v100     mean .051 median .048 p95 .072 us
resolver_alias_hit v100        mean .060 median .057 p95 .068 us
resolver_default v100          mean .055 median .053 p95 .055 us
resolver_absent v100           mean .034 median .031 p95 .050 us
resolver_override_hit v1000    mean .068 median .067 p95 .076 us
resolver_alias_hit v1000       mean .080 median .075 p95 .079 us
resolver_default v1000         mean .079 median .076 p95 .103 us
resolver_absent v1000          mean .025 median .025 p95 .030 us
resolver_override_hit v10000   mean .083 median .079 p95 .117 us
resolver_alias_hit v10000      mean .085 median .083 p95 .095 us
resolver_default v10000        mean .087 median .085 p95 .092 us
resolver_absent v10000         mean .024 median .024 p95 .025 us
save_codec v0                  mean .999 median .790 p95 1.780 us
save_codec v100                mean 40.135 median 35.000 p95 52.400 us
save_codec v10000              mean 4022.000 median 3769.000 p95 5751.000 us
claim_valid v0                 mean 2.532 median 2.150 p95 4.900 us
claim_valid v100               mean 541.600 median 500.500 p95 946.000 us
claim_valid v10000             mean 20842.857 median 21139.000 p95 25317.000 us
claim_tombstone v10000         mean 28249.857 median 23859.000 p95 49924.000 us
claim_collision v10000         mean 30634.000 median 29800.000 p95 33662.000 us
```

## 24. Anti-dérive

- Lecteurs/writers Fact inventoriés par `rg`.
- Aucun nouvel usage Fact de `consumedEventIds`.
- Aucun symbole `NarrativeEventDispatchDecision`,
  `NarrativeEventOccurrence`, `NarrativeEventProgress`,
  `NarrativeOutcomeDelivery` ou `OutcomeOutboxProcessor` ajouté aux libs.
- Aucun commentaire manuel/TODO/FIXME/HACK/TEMP ajouté. Quatre ignores inline
  Freezed sont générés automatiquement avec les nouveaux champs.
- Aucun cache global mutable.

## 25. Review finale

R1 : PASS sans blocker après correction PR-D et vérification finale de PR-B.
R2 : PASS sans blocker après avoir identifié puis revalidé la frontière de
provenance page-scoped. E : la frontière crash non durable a été corrigée, puis
re-reviewée. La demande initiale de champs outbox incompatibles a été retirée.

## 26. Gate de réouverture F1

```text
default true -> false durable           PASS
old saves -> overrides vides            PASS
orphans conservés                       PASS
override > alias > default              PASS
runtime keys collision-safe             PASS
World Rules shared resolver             PASS
Scene setFact shared writer             PASS
Scene kind=fact                         PASS
Script context canonical                PASS
raw flags sans contexte                 PASS
page Event Builder current canonical    PASS
page Event Builder legacy canonical     PASS
page non marquée reste raw              PASS
schema futur reste raw                  PASS
canStart == canEnter strict             PASS
canRun tolère tombstones locaux         PASS
global conflicts bloquent               PASS
source/provenance typed                 PASS
outbox strict/defensive ratifié         PASS
planner F1 absent                       PASS
reviewers sans blocker                  PASS
Phase F1                                READY
Phase F2                                NOT READY
```

## 27. État Git final

`git status --short --untracked-files=all` :

```text
 M "MVP Selbrume/event_builder_v2_architecture_decisions.md"
 M "MVP Selbrume/road_map_event_builder_v2.md"
 M packages/map_core/lib/map_core.dart
 M packages/map_core/lib/src/authoring/event_builder_contract.dart
 M packages/map_core/lib/src/diagnostics/scene_diagnostics.dart
 M packages/map_core/lib/src/diagnostics/world_rule_diagnostics.dart
 M packages/map_core/lib/src/models/game_state.dart
 M packages/map_core/lib/src/models/game_state.freezed.dart
 M packages/map_core/lib/src/models/game_state.g.dart
 M packages/map_core/lib/src/models/save_data.dart
 M packages/map_core/lib/src/models/save_data.freezed.dart
 M packages/map_core/lib/src/models/save_data.g.dart
 M packages/map_core/lib/src/operations/game_state_persistence.dart
 M packages/map_core/lib/src/operations/narrative_event_registry_codec.dart
 M packages/map_core/lib/src/projection/world_rule_projection.dart
 M packages/map_core/lib/src/validation/validators.dart
 M packages/map_core/test/event_builder_authoring_operations_test.dart
 M packages/map_core/test/game_state_persistence_test.dart
 M packages/map_core/test/narrative_event_registry_test.dart
 M packages/map_core/test/save_data_test.dart
 M packages/map_core/test/scene_diagnostics_test.dart
 M packages/map_core/test/world_rule_projection_test.dart
 M packages/map_editor/pubspec.lock
 M packages/map_gameplay/.dart_tool/package_config.json
 M packages/map_gameplay/.dart_tool/package_graph.json
 M packages/map_gameplay/lib/src/event_page_resolver.dart
 M packages/map_gameplay/lib/src/new_game_state_builder.dart
 M packages/map_gameplay/lib/src/script_condition_evaluator.dart
 M packages/map_gameplay/pubspec.lock
 M packages/map_gameplay/test/new_game_state_builder_test.dart
 M packages/map_runtime/lib/map_runtime.dart
 M packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_write_result.dart
 M packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_writer.dart
 M packages/map_runtime/lib/src/infrastructure/file_game_save_repository.dart
 M packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
 M packages/map_runtime/test/scene_consequence_runtime_writer_test.dart
 M selbrume/project.json
?? packages/map_core/lib/src/models/narrative_fact_runtime_state.dart
?? packages/map_core/lib/src/operations/narrative_fact_runtime.dart
?? packages/map_core/test/narrative_fact_runtime_performance_test.dart
?? packages/map_core/test/narrative_fact_runtime_resolver_test.dart
?? packages/map_core/test/narrative_fact_runtime_state_test.dart
?? packages/map_core/test/narrative_fact_runtime_writer_test.dart
?? packages/map_core/test/project_validator_test.dart
?? packages/map_core/test/validated_legacy_claim_index_runtime_readiness_test.dart
?? packages/map_gameplay/test/narrative_fact_script_condition_test.dart
?? packages/map_runtime/lib/src/application/scene_runtime/scene_fact_condition_runtime_resolver.dart
?? packages/map_runtime/test/narrative_fact_runtime_cross_consumer_test.dart
?? packages/map_runtime/test/narrative_fact_runtime_save_load_test.dart
?? reports/narrativeStudio/events/ns_event_v2_f1_prereq_canonical_fact_runtime_closure_v0.md
?? reports/narrativeStudio/events/ns_event_v2_f1_prereq_evidence_pack.md
?? selbrume/assets/borders/snapshots/b9a77cfa1bf35d89d0854b7c180f974b1400474cc27e05db0d9ee93f82b5b38a/frame_0000.png
?? selbrume/assets/borders/snapshots/d12d89c830a4e1f88038afc8e868282ca24d8a1dfc42505b7e3593cc97ea95c0/frame_0000.png
?? selbrume/assets/borders/snapshots/f7dff67260a8197d15f892ecca9b8099cadb1f4c24176b4c64246c48e719e3c9/frame_0000.png
?? selbrume/assets/borders/snapshots/ff1052a8600830f40d9e04e5dce67d879962e567481f832e26249e4706d4d779/frame_0000.png
```

`git diff --check` : vide. Anti-scope :

```text
packages/map_editor/pubspec.lock
selbrume/project.json
```

Le premier est le drift préexistant hashé au Gate 0 ; le second et les quatre
snapshots Selbrume sont des changements concurrents apparus pendant le lot.


## 28. Limite de récursivité documentaire

Les contenus complets des douze fichiers source/test créés suivent. Le rapport
principal est l'artefact frère complet. Inclure le présent Evidence Pack dans
lui-même serait récursif ; cette impossibilité est explicitée plutôt que masquée.
Les annexes 13 et 14 sont des snapshots intermédiaires conservés pour la trace ;
l'annexe 15 est le rapport final et l'annexe 16 remplace l'annexe 11 pour le
test cross-consumer après la correction de provenance page-scoped.

## Annexe 1 — Contenu complet de `packages/map_core/lib/src/models/narrative_fact_runtime_state.dart`

```dart
import 'package:meta/meta.dart' show immutable;

@immutable
final class NarrativeFactRuntimeState {
  const NarrativeFactRuntimeState.empty()
      : overridesByFactId = const <String, bool>{};

  factory NarrativeFactRuntimeState({
    Map<String, bool> overridesByFactId = const <String, bool>{},
  }) {
    final entries = overridesByFactId.entries.toList(growable: false)
      ..sort((left, right) => left.key.compareTo(right.key));
    final sorted = <String, bool>{};
    for (final entry in entries) {
      _validateFactId(entry.key);
      sorted[entry.key] = entry.value;
    }
    return NarrativeFactRuntimeState._(Map.unmodifiable(sorted));
  }

  const NarrativeFactRuntimeState._(this.overridesByFactId);

  factory NarrativeFactRuntimeState.fromJson(Map<String, dynamic> json) {
    if (json.length != 1 || !json.containsKey('overridesByFactId')) {
      throw const FormatException(
        'NarrativeFactRuntimeState must contain only overridesByFactId.',
      );
    }
    final rawOverrides = json['overridesByFactId'];
    if (rawOverrides is! Map) {
      throw const FormatException('overridesByFactId must be an object.');
    }
    final overrides = <String, bool>{};
    for (final entry in rawOverrides.entries) {
      final key = entry.key;
      final value = entry.value;
      if (key is! String || value is! bool) {
        throw const FormatException(
          'overridesByFactId must contain boolean values keyed by Fact ID.',
        );
      }
      overrides[key] = value;
    }
    try {
      return NarrativeFactRuntimeState(overridesByFactId: overrides);
    } on ArgumentError catch (error) {
      throw FormatException(error.message?.toString() ?? 'Invalid Fact ID.');
    }
  }

  final Map<String, bool> overridesByFactId;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'overridesByFactId': <String, bool>{...overridesByFactId},
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! NarrativeFactRuntimeState ||
        other.overridesByFactId.length != overridesByFactId.length) {
      return false;
    }
    for (final entry in overridesByFactId.entries) {
      if (!other.overridesByFactId.containsKey(entry.key) ||
          other.overridesByFactId[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(
        overridesByFactId.entries.map(
          (entry) => Object.hash(entry.key, entry.value),
        ),
      );
}

Object? readNarrativeFactRuntimeStateJson(
  Map<dynamic, dynamic> json,
  String key,
) {
  if (!json.containsKey(key)) {
    return null;
  }
  final value = json[key];
  if (value == null) {
    throw FormatException('$key must not be null.');
  }
  return value;
}

void _validateFactId(String factId) {
  if (factId.isEmpty || factId.trim() != factId) {
    throw ArgumentError.value(
      factId,
      'factId',
      'must be non-empty and trim-exact',
    );
  }
}
```

## Annexe 2 — Contenu complet de `packages/map_core/lib/src/operations/narrative_fact_runtime.dart`

```dart
import 'package:meta/meta.dart' show immutable;

import '../models/game_state.dart';
import '../models/narrative_fact.dart';
import '../models/narrative_fact_runtime_state.dart';

enum NarrativeFactRuntimeValueSource {
  explicitOverride,
  legacyStoryFlag,
  defaultValue,
}

enum NarrativeFactRuntimeCatalogIssueCode {
  duplicateFactId,
  duplicateLegacyFlagName,
  legacyFlagNameConflictsWithFactId,
  duplicateRuntimeKey,
}

@immutable
final class NarrativeFactRuntimeCatalogIssue {
  NarrativeFactRuntimeCatalogIssue({
    required this.code,
    required this.runtimeKey,
    required List<String> factIds,
  }) : factIds = List<String>.unmodifiable(factIds);

  final NarrativeFactRuntimeCatalogIssueCode code;
  final String runtimeKey;
  final List<String> factIds;

  String get message =>
      '${code.name}: "$runtimeKey" is shared by ${factIds.join(', ')}.';
}

sealed class NarrativeFactRuntimeResolution {
  const NarrativeFactRuntimeResolution();
}

@immutable
final class NarrativeFactRuntimeResolved
    extends NarrativeFactRuntimeResolution {
  const NarrativeFactRuntimeResolved({
    required this.fact,
    required this.runtimeKey,
    required this.value,
    required this.source,
  });

  final NarrativeFactDefinition fact;
  final String runtimeKey;
  final bool value;
  final NarrativeFactRuntimeValueSource source;
}

@immutable
final class NarrativeFactRuntimeUnknownFact
    extends NarrativeFactRuntimeResolution {
  const NarrativeFactRuntimeUnknownFact(this.factId);

  final String factId;
}

@immutable
final class NarrativeFactRuntimeAmbiguousFact
    extends NarrativeFactRuntimeResolution {
  NarrativeFactRuntimeAmbiguousFact({
    required this.factId,
    required List<NarrativeFactRuntimeCatalogIssue> issues,
  }) : issues = List<NarrativeFactRuntimeCatalogIssue>.unmodifiable(issues);

  final String factId;
  final List<NarrativeFactRuntimeCatalogIssue> issues;
}

@immutable
final class NarrativeFactRuntimeInvalidRuntimeKey
    extends NarrativeFactRuntimeResolution {
  const NarrativeFactRuntimeInvalidRuntimeKey({
    required this.factId,
    required this.runtimeKey,
  });

  final String factId;
  final String runtimeKey;
}

@immutable
final class NarrativeFactRuntimeResolver {
  NarrativeFactRuntimeResolver._({
    required Map<String, List<NarrativeFactDefinition>> factsById,
    required List<NarrativeFactRuntimeCatalogIssue> issues,
  })  : _factsById = Map<String, List<NarrativeFactDefinition>>.unmodifiable({
          for (final entry in factsById.entries)
            entry.key: List<NarrativeFactDefinition>.unmodifiable(entry.value),
        }),
        issues = List<NarrativeFactRuntimeCatalogIssue>.unmodifiable(issues);

  factory NarrativeFactRuntimeResolver.fromFacts(
    Iterable<NarrativeFactDefinition> facts,
  ) {
    final definitions = List<NarrativeFactDefinition>.of(facts);
    final factsById = <String, List<NarrativeFactDefinition>>{};
    final factsByAlias = <String, List<NarrativeFactDefinition>>{};
    final factsByRuntimeKey = <String, List<NarrativeFactDefinition>>{};
    for (final fact in definitions) {
      factsById.putIfAbsent(fact.id, () => []).add(fact);
      final alias = fact.legacyFlagName;
      if (alias != null) {
        factsByAlias.putIfAbsent(alias, () => []).add(fact);
      }
      final runtimeKey = alias ?? fact.id;
      factsByRuntimeKey.putIfAbsent(runtimeKey, () => []).add(fact);
    }

    final issues = <NarrativeFactRuntimeCatalogIssue>[];
    _appendGroupedIssues(
      issues,
      NarrativeFactRuntimeCatalogIssueCode.duplicateFactId,
      factsById,
    );
    _appendGroupedIssues(
      issues,
      NarrativeFactRuntimeCatalogIssueCode.duplicateLegacyFlagName,
      factsByAlias,
    );

    final aliasIdConflicts = <String, List<NarrativeFactDefinition>>{};
    for (final entry in factsByAlias.entries) {
      final idOwners = factsById[entry.key];
      if (idOwners == null ||
          entry.value.every((fact) => fact.id == entry.key)) {
        continue;
      }
      aliasIdConflicts[entry.key] = <NarrativeFactDefinition>[
        ...entry.value,
        ...idOwners,
      ];
    }
    for (final entry in aliasIdConflicts.entries) {
      issues.add(
        NarrativeFactRuntimeCatalogIssue(
          code: NarrativeFactRuntimeCatalogIssueCode
              .legacyFlagNameConflictsWithFactId,
          runtimeKey: entry.key,
          factIds: _stableFactIds(entry.value),
        ),
      );
    }
    _appendGroupedIssues(
      issues,
      NarrativeFactRuntimeCatalogIssueCode.duplicateRuntimeKey,
      factsByRuntimeKey,
    );
    issues.sort(_compareCatalogIssues);

    return NarrativeFactRuntimeResolver._(
      factsById: factsById,
      issues: issues,
    );
  }

  final Map<String, List<NarrativeFactDefinition>> _factsById;
  final List<NarrativeFactRuntimeCatalogIssue> issues;

  bool get isValid => issues.isEmpty;

  NarrativeFactRuntimeResolution resolve({
    required String factId,
    required NarrativeFactRuntimeState runtimeState,
    required StoryFlags storyFlags,
  }) {
    if (factId.isEmpty || factId.trim() != factId) {
      return NarrativeFactRuntimeInvalidRuntimeKey(
        factId: factId,
        runtimeKey: factId,
      );
    }
    if (!isValid) {
      return NarrativeFactRuntimeAmbiguousFact(
        factId: factId,
        issues: issues,
      );
    }
    final matches = _factsById[factId];
    if (matches == null || matches.isEmpty) {
      return NarrativeFactRuntimeUnknownFact(factId);
    }
    if (matches.length != 1) {
      return NarrativeFactRuntimeAmbiguousFact(
        factId: factId,
        issues: issues,
      );
    }
    final fact = matches.single;
    final runtimeKey = fact.legacyFlagName ?? fact.id;
    if (runtimeKey.isEmpty || runtimeKey.trim() != runtimeKey) {
      return NarrativeFactRuntimeInvalidRuntimeKey(
        factId: factId,
        runtimeKey: runtimeKey,
      );
    }
    if (runtimeState.overridesByFactId.containsKey(fact.id)) {
      return NarrativeFactRuntimeResolved(
        fact: fact,
        runtimeKey: runtimeKey,
        value: runtimeState.overridesByFactId[fact.id]!,
        source: NarrativeFactRuntimeValueSource.explicitOverride,
      );
    }
    if (storyFlags.activeFlags.contains(runtimeKey)) {
      return NarrativeFactRuntimeResolved(
        fact: fact,
        runtimeKey: runtimeKey,
        value: true,
        source: NarrativeFactRuntimeValueSource.legacyStoryFlag,
      );
    }
    return NarrativeFactRuntimeResolved(
      fact: fact,
      runtimeKey: runtimeKey,
      value: fact.defaultValue,
      source: NarrativeFactRuntimeValueSource.defaultValue,
    );
  }
}

enum NarrativeFactRuntimeWriteErrorCode {
  unknownFact,
  ambiguousFact,
  invalidRuntimeKey,
}

sealed class NarrativeFactRuntimeWriteResult {
  const NarrativeFactRuntimeWriteResult();

  GameState get gameState;
  bool get success;
  NarrativeFactRuntimeWriteErrorCode? get errorCode;
}

@immutable
final class NarrativeFactRuntimeWriteApplied
    extends NarrativeFactRuntimeWriteResult {
  const NarrativeFactRuntimeWriteApplied({
    required this.gameState,
    required this.fact,
    required this.runtimeKey,
    required this.value,
  });

  @override
  final GameState gameState;
  final NarrativeFactDefinition fact;
  final String runtimeKey;
  final bool value;

  @override
  bool get success => true;

  @override
  NarrativeFactRuntimeWriteErrorCode? get errorCode => null;
}

@immutable
final class NarrativeFactRuntimeWriteRejected
    extends NarrativeFactRuntimeWriteResult {
  const NarrativeFactRuntimeWriteRejected({
    required this.gameState,
    required this.errorCode,
    required this.message,
  });

  @override
  final GameState gameState;
  @override
  final NarrativeFactRuntimeWriteErrorCode errorCode;
  final String message;

  @override
  bool get success => false;
}

@immutable
final class NarrativeFactRuntimeWriter {
  const NarrativeFactRuntimeWriter(this.resolver);

  final NarrativeFactRuntimeResolver resolver;

  NarrativeFactRuntimeWriteResult setFact({
    required GameState gameState,
    required String factId,
    required bool value,
  }) {
    final resolution = resolver.resolve(
      factId: factId,
      runtimeState: gameState.narrativeFactRuntimeState,
      storyFlags: gameState.storyFlags,
    );
    return switch (resolution) {
      NarrativeFactRuntimeResolved() => _apply(
          gameState,
          resolution.fact,
          resolution.runtimeKey,
          value,
        ),
      NarrativeFactRuntimeUnknownFact() => NarrativeFactRuntimeWriteRejected(
          gameState: gameState,
          errorCode: NarrativeFactRuntimeWriteErrorCode.unknownFact,
          message: 'Unknown Fact "${resolution.factId}".',
        ),
      NarrativeFactRuntimeAmbiguousFact() => NarrativeFactRuntimeWriteRejected(
          gameState: gameState,
          errorCode: NarrativeFactRuntimeWriteErrorCode.ambiguousFact,
          message: 'Ambiguous Fact catalog for "${resolution.factId}".',
        ),
      NarrativeFactRuntimeInvalidRuntimeKey() =>
        NarrativeFactRuntimeWriteRejected(
          gameState: gameState,
          errorCode: NarrativeFactRuntimeWriteErrorCode.invalidRuntimeKey,
          message: 'Invalid runtime key "${resolution.runtimeKey}".',
        ),
    };
  }

  NarrativeFactRuntimeWriteApplied _apply(
    GameState gameState,
    NarrativeFactDefinition fact,
    String runtimeKey,
    bool value,
  ) {
    final overrides = <String, bool>{
      ...gameState.narrativeFactRuntimeState.overridesByFactId,
      fact.id: value,
    };
    final runtimeFlags = <String>{...gameState.storyFlags.activeFlags};
    final progressionFlags = <String>[
      ...gameState.progression.storyFlags,
    ];
    if (value) {
      runtimeFlags.add(runtimeKey);
      if (!progressionFlags.contains(runtimeKey)) {
        progressionFlags.add(runtimeKey);
      }
    } else {
      runtimeFlags.remove(runtimeKey);
      progressionFlags.removeWhere((flag) => flag == runtimeKey);
    }
    final nextState = gameState.copyWith(
      narrativeFactRuntimeState: NarrativeFactRuntimeState(
        overridesByFactId: overrides,
      ),
      storyFlags: gameState.storyFlags.copyWith(activeFlags: runtimeFlags),
      progression: gameState.progression.copyWith(
        storyFlags: progressionFlags,
      ),
    );
    return NarrativeFactRuntimeWriteApplied(
      gameState: nextState,
      fact: fact,
      runtimeKey: runtimeKey,
      value: value,
    );
  }
}

void _appendGroupedIssues(
  List<NarrativeFactRuntimeCatalogIssue> issues,
  NarrativeFactRuntimeCatalogIssueCode code,
  Map<String, List<NarrativeFactDefinition>> groupedFacts,
) {
  for (final entry in groupedFacts.entries) {
    if (entry.value.length < 2) {
      continue;
    }
    issues.add(
      NarrativeFactRuntimeCatalogIssue(
        code: code,
        runtimeKey: entry.key,
        factIds: _stableFactIds(entry.value),
      ),
    );
  }
}

List<String> _stableFactIds(Iterable<NarrativeFactDefinition> facts) {
  final ids = facts.map((fact) => fact.id).toSet().toList(growable: false)
    ..sort();
  return ids;
}

int _compareCatalogIssues(
  NarrativeFactRuntimeCatalogIssue left,
  NarrativeFactRuntimeCatalogIssue right,
) {
  final byCode = left.code.index.compareTo(right.code.index);
  if (byCode != 0) {
    return byCode;
  }
  final byKey = left.runtimeKey.compareTo(right.runtimeKey);
  if (byKey != 0) {
    return byKey;
  }
  return left.factIds.join('\u0000').compareTo(right.factIds.join('\u0000'));
}
```

## Annexe 3 — Contenu complet de `packages/map_core/test/narrative_fact_runtime_performance_test.dart`

```dart
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

Object? _benchmarkSink;

void main() {
  test('NS-EVENT-V2 F1-PREREQ performance measurements', () {
    stdout.writeln(
      'NS_EVENT_V2_F1_PREREQ_PERF_ENV os=${Platform.operatingSystem} '
      'os_version=${Platform.operatingSystemVersion.replaceAll(' ', '_')} '
      'dart=${Platform.version.split(' ').first} mode=jit aot=not_measured '
      'processors=${Platform.numberOfProcessors}',
    );
    _measureResolver();
    _measureSaveCodec();
    _measureClaimIndex();
  });
}

void _measureResolver() {
  for (final volume in const [1, 100, 1000, 10000]) {
    final facts = [
      for (var index = 0; index < volume; index++)
        NarrativeFactDefinition(
          id: _factId(index),
          label: 'Fact $index',
          defaultValue: index.isEven,
          legacyFlagName: _legacyFlag(index),
        ),
    ];
    final target = facts.last;
    final resolver = NarrativeFactRuntimeResolver.fromFacts(facts);
    final overrideState = NarrativeFactRuntimeState(
      overridesByFactId: {target.id: false},
    );
    final aliasFlags = StoryFlags(activeFlags: {_legacyFlag(volume - 1)});

    _measure(
      operation: 'resolver_override_hit',
      volume: volume,
      iterations: 30,
      batchSize: 1000,
      complexity: 'O(1)_lookup_after_O(n)_index',
      run: () {
        _benchmarkSink = resolver.resolve(
          factId: target.id,
          runtimeState: overrideState,
          storyFlags: aliasFlags,
        );
      },
    );
    expect(
      (_benchmarkSink as NarrativeFactRuntimeResolved).source,
      NarrativeFactRuntimeValueSource.explicitOverride,
    );

    _measure(
      operation: 'resolver_alias_hit',
      volume: volume,
      iterations: 30,
      batchSize: 1000,
      complexity: 'O(1)_lookup_after_O(n)_index',
      run: () {
        _benchmarkSink = resolver.resolve(
          factId: target.id,
          runtimeState: const NarrativeFactRuntimeState.empty(),
          storyFlags: aliasFlags,
        );
      },
    );
    expect(
      (_benchmarkSink as NarrativeFactRuntimeResolved).source,
      NarrativeFactRuntimeValueSource.legacyStoryFlag,
    );

    _measure(
      operation: 'resolver_default_fallback',
      volume: volume,
      iterations: 30,
      batchSize: 1000,
      complexity: 'O(1)_lookup_after_O(n)_index',
      run: () {
        _benchmarkSink = resolver.resolve(
          factId: target.id,
          runtimeState: const NarrativeFactRuntimeState.empty(),
          storyFlags: const StoryFlags(),
        );
      },
    );
    expect(
      (_benchmarkSink as NarrativeFactRuntimeResolved).source,
      NarrativeFactRuntimeValueSource.defaultValue,
    );

    _measure(
      operation: 'resolver_absent',
      volume: volume,
      iterations: 30,
      batchSize: 1000,
      complexity: 'O(1)_lookup_after_O(n)_index',
      run: () {
        _benchmarkSink = resolver.resolve(
          factId: 'fact_absent',
          runtimeState: const NarrativeFactRuntimeState.empty(),
          storyFlags: const StoryFlags(),
        );
      },
    );
    expect(_benchmarkSink, isA<NarrativeFactRuntimeUnknownFact>());
  }
}

void _measureSaveCodec() {
  for (final volume in const [0, 100, 10000]) {
    final state = NarrativeFactRuntimeState(
      overridesByFactId: {
        for (var index = 0; index < volume; index++)
          _factId(index): index.isEven,
      },
    );
    final iterations = switch (volume) {
      0 => 30,
      100 => 20,
      _ => 7,
    };
    final batchSize = switch (volume) {
      0 => 100,
      100 => 10,
      _ => 1,
    };
    _measure(
      operation: 'save_codec_roundtrip',
      volume: volume,
      iterations: iterations,
      batchSize: batchSize,
      complexity: 'O(k_log_k)_decode_plus_O(k)_encode',
      run: () {
        _benchmarkSink = NarrativeFactRuntimeState.fromJson(state.toJson());
      },
    );
    expect(_benchmarkSink, state);
  }
}

void _measureClaimIndex() {
  for (final volume in const [0, 100, 10000]) {
    final corpus = _claimCorpus(volume);
    ValidatedLegacyClaimIndex? index;
    _measure(
      operation: 'claim_index_valid',
      volume: volume,
      iterations: volume == 10000 ? 7 : 20,
      batchSize: volume == 0 ? 20 : 1,
      complexity: 'O(records_plus_claims_plus_targets)',
      run: () {
        index = buildRuntimeValidatedLegacyClaimIndex(
          corpus.registry,
          runtimeEvidence: corpus.runtimeEvidence,
        );
        _benchmarkSink = index;
      },
    );
    expect(index?.canEnterDualRead, isTrue);
    expect(index?.canRunDualRead, isTrue);

    if (volume != 10000) {
      continue;
    }

    final tombstoneRegistry = NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.dualRead,
      records: corpus.registry.records.take(volume - 1).toList(),
      legacyClaims: corpus.registry.legacyClaims,
    );
    _measure(
      operation: 'claim_index_local_tombstone',
      volume: volume,
      iterations: 7,
      batchSize: 1,
      complexity: 'O(records_plus_claims_plus_targets)',
      run: () {
        index = buildRuntimeValidatedLegacyClaimIndex(
          tombstoneRegistry,
          runtimeEvidence: corpus.runtimeEvidence,
        );
        _benchmarkSink = index;
      },
    );
    expect(index?.canEnterDualRead, isFalse);
    expect(index?.canRunDualRead, isTrue);
    expect(
      index?.resolveSource(corpus.lastSource),
      isA<LegacyClaimSourceTombstone>(),
    );

    final collisionRegistry = NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.dualRead,
      records: corpus.registry.records,
      legacyClaims: [
        ...corpus.registry.legacyClaims,
        corpus.registry.legacyClaims.last,
      ],
    );
    _measure(
      operation: 'claim_index_global_collision',
      volume: volume,
      iterations: 7,
      batchSize: 1,
      complexity: 'O(records_plus_claims_plus_targets_plus_conflict_sort)',
      run: () {
        index = buildRuntimeValidatedLegacyClaimIndex(
          collisionRegistry,
          runtimeEvidence: corpus.runtimeEvidence,
        );
        _benchmarkSink = index;
      },
    );
    expect(index?.canEnterDualRead, isFalse);
    expect(index?.canRunDualRead, isFalse);
  }
}

({
  NarrativeEventRegistry registry,
  NarrativeEventSourceRef lastSource,
  LegacyClaimRuntimeEvidence runtimeEvidence,
}) _claimCorpus(int volume) {
  final records = <NarrativeEventRecord>[];
  final claims = <LegacySourceClaim>[];
  final evidenceEntries = <LegacyClaimRuntimeEvidenceEntry>[];
  NarrativeEventSourceRef lastSource =
      NarrativeEventSourceRef.mapEnter('map_empty');
  for (var index = 0; index < volume; index++) {
    final source = NarrativeEventSourceRef.mapEnter(_mapId(index));
    final provenance = LegacySourceRef.mapEvent(
      _mapId(index),
      'legacy_${index.toString().padLeft(5, '0')}',
    );
    final member = LegacySourceClaimMember(
      provenance: provenance,
      sourceFingerprint:
          'sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
    );
    final cohortId = computeLegacySourceCohortId(source, [provenance]);
    final eventId = _eventId(index);
    records.add(
      NarrativeEventRecord.configuredStructurallyUnchecked(
        NarrativeEventDefinition(
          id: eventId,
          name: eventId,
          source: source,
          conditions: const [],
          sceneId: 'scene',
          reusePolicy: NarrativeEventReusePolicy.oneShot,
          priority: 0,
          order: index,
        ),
        enabled: true,
      ),
    );
    claims.add(
      LegacySourceClaim(
        cohortId: cohortId,
        source: source,
        members: [member],
        cohortFingerprint: computeLegacySourceCohortFingerprint(
          cohortId,
          [member],
        ),
        targetEventIds: [eventId],
        migrationReceiptId: 'receipt_$index',
      ),
    );
    evidenceEntries.add(
      LegacyClaimRuntimeEvidenceEntry(
        provenance: provenance,
        source: source,
        sourceFingerprint: member.sourceFingerprint,
      ),
    );
    lastSource = source;
  }
  return (
    registry: NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.dualRead,
      records: records,
      legacyClaims: claims,
    ),
    lastSource: lastSource,
    runtimeEvidence: LegacyClaimRuntimeEvidence(entries: evidenceEntries),
  );
}

String _factId(int index) => 'fact_${index.toString().padLeft(5, '0')}';

String _legacyFlag(int index) =>
    'legacy_fact_${index.toString().padLeft(5, '0')}';

String _mapId(int index) => 'map_${index.toString().padLeft(5, '0')}';

String _eventId(int index) {
  return 'evt_019abcde-0000-7000-8000-${index.toString().padLeft(12, '0')}';
}

void _measure({
  required String operation,
  required int volume,
  required int iterations,
  required int batchSize,
  required String complexity,
  required void Function() run,
}) {
  for (var index = 0; index < batchSize; index++) {
    run();
  }
  final samples = <double>[];
  for (var iteration = 0; iteration < iterations; iteration++) {
    final stopwatch = Stopwatch()..start();
    for (var index = 0; index < batchSize; index++) {
      run();
    }
    stopwatch.stop();
    samples.add(stopwatch.elapsedMicroseconds / batchSize);
  }
  samples.sort();
  final mean =
      samples.fold<double>(0, (sum, value) => sum + value) / samples.length;
  final median = samples.length.isOdd
      ? samples[samples.length ~/ 2]
      : (samples[samples.length ~/ 2 - 1] + samples[samples.length ~/ 2]) / 2;
  final p95Index =
      ((samples.length * 0.95).ceil() - 1).clamp(0, samples.length - 1);
  stdout.writeln(
    'NS_EVENT_V2_F1_PREREQ_PERF operation=$operation volume=$volume '
    'iterations=$iterations batch=$batchSize '
    'mean_us=${mean.toStringAsFixed(3)} '
    'median_us=${median.toStringAsFixed(3)} '
    'p95_us=${samples[p95Index].toStringAsFixed(3)} mode=jit '
    'complexity=$complexity aot=not_measured',
  );
}
```

## Annexe 4 — Contenu complet de `packages/map_core/test/narrative_fact_runtime_resolver_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('NarrativeFactRuntimeResolver', () {
    test('resolves override before alias and default', () {
      final fact = NarrativeFactDefinition(
        id: 'fact_gate',
        label: 'Gate',
        defaultValue: true,
        legacyFlagName: 'legacy_gate',
      );
      final resolver = NarrativeFactRuntimeResolver.fromFacts([fact]);
      final result = resolver.resolve(
        factId: fact.id,
        runtimeState: NarrativeFactRuntimeState(
          overridesByFactId: const {'fact_gate': false},
        ),
        storyFlags: const StoryFlags(activeFlags: {'legacy_gate'}),
      );

      expect(result, isA<NarrativeFactRuntimeResolved>());
      final resolved = result as NarrativeFactRuntimeResolved;
      expect(resolved.value, isFalse);
      expect(resolved.source, NarrativeFactRuntimeValueSource.explicitOverride);
      expect(resolved.runtimeKey, 'legacy_gate');
    });

    test('resolves alias before a false default', () {
      final resolver = NarrativeFactRuntimeResolver.fromFacts([
        NarrativeFactDefinition(
          id: 'fact_gate',
          label: 'Gate',
          legacyFlagName: 'legacy_gate',
        ),
      ]);

      final result = resolver.resolve(
        factId: 'fact_gate',
        runtimeState: const NarrativeFactRuntimeState.empty(),
        storyFlags: const StoryFlags(activeFlags: {'legacy_gate'}),
      ) as NarrativeFactRuntimeResolved;

      expect(result.value, isTrue);
      expect(result.source, NarrativeFactRuntimeValueSource.legacyStoryFlag);
    });

    test('falls back to false and true defaults', () {
      final resolver = NarrativeFactRuntimeResolver.fromFacts([
        NarrativeFactDefinition(id: 'fact_false', label: 'False'),
        NarrativeFactDefinition(
          id: 'fact_true',
          label: 'True',
          defaultValue: true,
        ),
      ]);

      final falseResult = resolver.resolve(
        factId: 'fact_false',
        runtimeState: const NarrativeFactRuntimeState.empty(),
        storyFlags: const StoryFlags(),
      ) as NarrativeFactRuntimeResolved;
      final trueResult = resolver.resolve(
        factId: 'fact_true',
        runtimeState: const NarrativeFactRuntimeState.empty(),
        storyFlags: const StoryFlags(),
      ) as NarrativeFactRuntimeResolved;

      expect(falseResult.value, isFalse);
      expect(trueResult.value, isTrue);
      expect(falseResult.source, NarrativeFactRuntimeValueSource.defaultValue);
      expect(trueResult.source, NarrativeFactRuntimeValueSource.defaultValue);
    });

    test('does not use the raw Fact ID when an alias exists', () {
      final resolver = NarrativeFactRuntimeResolver.fromFacts([
        NarrativeFactDefinition(
          id: 'fact_gate',
          label: 'Gate',
          legacyFlagName: 'legacy_gate',
        ),
      ]);

      final result = resolver.resolve(
        factId: 'fact_gate',
        runtimeState: const NarrativeFactRuntimeState.empty(),
        storyFlags: const StoryFlags(activeFlags: {'fact_gate'}),
      ) as NarrativeFactRuntimeResolved;

      expect(result.value, isFalse);
      expect(result.source, NarrativeFactRuntimeValueSource.defaultValue);
    });

    test('returns typed unknown and invalid key results', () {
      final resolver = NarrativeFactRuntimeResolver.fromFacts(const []);

      expect(
        resolver.resolve(
          factId: 'fact_missing',
          runtimeState: const NarrativeFactRuntimeState.empty(),
          storyFlags: const StoryFlags(),
        ),
        isA<NarrativeFactRuntimeUnknownFact>(),
      );
      expect(
        resolver.resolve(
          factId: ' fact_missing ',
          runtimeState: const NarrativeFactRuntimeState.empty(),
          storyFlags: const StoryFlags(),
        ),
        isA<NarrativeFactRuntimeInvalidRuntimeKey>(),
      );
    });

    test('detects every runtime catalog collision without choosing a winner',
        () {
      final resolver = NarrativeFactRuntimeResolver.fromFacts([
        NarrativeFactDefinition(id: 'fact_duplicate', label: 'Duplicate A'),
        NarrativeFactDefinition(id: 'fact_duplicate', label: 'Duplicate B'),
        NarrativeFactDefinition(
          id: 'fact_alias_a',
          label: 'Alias A',
          legacyFlagName: 'shared_alias',
        ),
        NarrativeFactDefinition(
          id: 'fact_alias_b',
          label: 'Alias B',
          legacyFlagName: 'shared_alias',
        ),
        NarrativeFactDefinition(id: 'fact_collision', label: 'Collision'),
        NarrativeFactDefinition(
          id: 'fact_other',
          label: 'Other',
          legacyFlagName: 'fact_collision',
        ),
      ]);

      expect(resolver.isValid, isFalse);
      expect(
        resolver.issues.map((issue) => issue.code),
        containsAll({
          NarrativeFactRuntimeCatalogIssueCode.duplicateFactId,
          NarrativeFactRuntimeCatalogIssueCode.duplicateLegacyFlagName,
          NarrativeFactRuntimeCatalogIssueCode
              .legacyFlagNameConflictsWithFactId,
          NarrativeFactRuntimeCatalogIssueCode.duplicateRuntimeKey,
        }),
      );
      expect(
        resolver.resolve(
          factId: 'fact_other',
          runtimeState: const NarrativeFactRuntimeState.empty(),
          storyFlags: const StoryFlags(),
        ),
        isA<NarrativeFactRuntimeAmbiguousFact>(),
      );
      expect(
        () => resolver.issues.add(
          resolver.issues.first,
        ),
        throwsUnsupportedError,
      );
    });

    test('keeps orphan overrides but never applies them to another Fact', () {
      final resolver = NarrativeFactRuntimeResolver.fromFacts([
        NarrativeFactDefinition(id: 'fact_known', label: 'Known'),
      ]);
      final runtimeState = NarrativeFactRuntimeState(
        overridesByFactId: const {'fact_orphan': true},
      );

      final known = resolver.resolve(
        factId: 'fact_known',
        runtimeState: runtimeState,
        storyFlags: const StoryFlags(),
      ) as NarrativeFactRuntimeResolved;
      final orphan = resolver.resolve(
        factId: 'fact_orphan',
        runtimeState: runtimeState,
        storyFlags: const StoryFlags(),
      );

      expect(known.value, isFalse);
      expect(orphan, isA<NarrativeFactRuntimeUnknownFact>());
      expect(runtimeState.overridesByFactId['fact_orphan'], isTrue);
    });
  });
}
```

## Annexe 5 — Contenu complet de `packages/map_core/test/narrative_fact_runtime_state_test.dart`

```dart
import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('NarrativeFactRuntimeState', () {
    test('defaults to an empty immutable override map', () {
      const state = NarrativeFactRuntimeState.empty();

      expect(state.overridesByFactId, isEmpty);
      expect(
        () => state.overridesByFactId['fact_test'] = true,
        throwsUnsupportedError,
      );
    });

    test('defensively copies overrides and keeps explicit booleans', () {
      final input = <String, bool>{
        'fact_true': true,
        'fact_false': false,
      };
      final state = NarrativeFactRuntimeState(overridesByFactId: input);

      input['fact_true'] = false;
      input['fact_new'] = true;

      expect(state.overridesByFactId, {
        'fact_false': false,
        'fact_true': true,
      });
      expect(
        () => state.overridesByFactId['fact_true'] = false,
        throwsUnsupportedError,
      );
    });

    test('encodes override keys in stable lexical order', () {
      final state = NarrativeFactRuntimeState(
        overridesByFactId: const {
          'fact_z': true,
          'fact_a': false,
          'fact_m': true,
        },
      );

      final overrides = state.toJson()['overridesByFactId'] as Map;

      expect(overrides.keys, ['fact_a', 'fact_m', 'fact_z']);
      expect(
        jsonEncode(state.toJson()),
        '{"overridesByFactId":{"fact_a":false,"fact_m":true,"fact_z":true}}',
      );
    });

    test('rejects empty and non trim-exact fact IDs', () {
      expect(
        () => NarrativeFactRuntimeState(
          overridesByFactId: const {'': true},
        ),
        throwsArgumentError,
      );
      expect(
        () => NarrativeFactRuntimeState(
          overridesByFactId: const {' fact_test ': false},
        ),
        throwsArgumentError,
      );
    });

    test('rejects invalid JSON values and shape', () {
      expect(
        () => NarrativeFactRuntimeState.fromJson({
          'overridesByFactId': {'fact_test': 'false'},
        }),
        throwsFormatException,
      );
      expect(
        () => NarrativeFactRuntimeState.fromJson(const {}),
        throwsFormatException,
      );
      expect(
        () => NarrativeFactRuntimeState.fromJson({
          'overridesByFactId': <String, dynamic>{},
          'unexpected': true,
        }),
        throwsFormatException,
      );
      expect(
        () => NarrativeFactRuntimeState.fromJson({
          'overridesByFactId': {' fact_test ': false},
        }),
        throwsFormatException,
      );
    });

    test('round-trips orphan and default-equal overrides without dropping', () {
      final state = NarrativeFactRuntimeState(
        overridesByFactId: const {
          'fact_default_false': false,
          'fact_orphan': true,
        },
      );

      final decoded = NarrativeFactRuntimeState.fromJson(
        jsonDecode(jsonEncode(state.toJson())) as Map<String, dynamic>,
      );

      expect(decoded, state);
      expect(decoded.hashCode, state.hashCode);
      expect(decoded.overridesByFactId['fact_default_false'], isFalse);
      expect(decoded.overridesByFactId['fact_orphan'], isTrue);
    });
  });

  group('NarrativeFactRuntimeState persistence defaults', () {
    test('old GameState JSON without the subtree loads empty', () {
      final state = GameState.fromJson({'saveId': 'legacy_game_state'});

      expect(state.narrativeFactRuntimeState.overridesByFactId, isEmpty);
    });

    test('old SaveData JSON without the subtree loads empty', () {
      final save = SaveData.fromJson({'saveId': 'legacy_save_data'});

      expect(save.narrativeFactRuntimeState.overridesByFactId, isEmpty);
    });

    test('explicit null subtree is rejected by GameState and SaveData', () {
      expect(
        () => GameState.fromJson({
          'saveId': 'invalid_game_state',
          'narrativeFactRuntimeState': null,
        }),
        throwsFormatException,
      );
      expect(
        () => SaveData.fromJson({
          'saveId': 'invalid_save_data',
          'narrativeFactRuntimeState': null,
        }),
        throwsFormatException,
      );
    });

    test('GameState round-trip preserves true false and orphan overrides', () {
      final state = GameState(
        saveId: 'fact_state',
        narrativeFactRuntimeState: NarrativeFactRuntimeState(
          overridesByFactId: const {
            'fact_false': false,
            'fact_orphan': true,
          },
        ),
      );

      final decoded = GameState.fromJson(
        jsonDecode(jsonEncode(state.toJson())) as Map<String, dynamic>,
      );

      expect(
          decoded.narrativeFactRuntimeState, state.narrativeFactRuntimeState);
    });

    test('SaveData round-trip preserves true false and orphan overrides', () {
      final save = SaveData(
        saveId: 'fact_save',
        narrativeFactRuntimeState: NarrativeFactRuntimeState(
          overridesByFactId: const {
            'fact_false': false,
            'fact_orphan': true,
          },
        ),
      );

      final decoded = SaveData.fromJson(
        jsonDecode(jsonEncode(save.toJson())) as Map<String, dynamic>,
      );

      expect(decoded.narrativeFactRuntimeState, save.narrativeFactRuntimeState);
    });
  });
}
```

## Annexe 6 — Contenu complet de `packages/map_core/test/narrative_fact_runtime_writer_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('NarrativeFactRuntimeWriter', () {
    test('writes explicit false and synchronizes both legacy stores', () {
      final resolver = NarrativeFactRuntimeResolver.fromFacts([
        NarrativeFactDefinition(
          id: 'fact_gate',
          label: 'Gate',
          defaultValue: true,
          legacyFlagName: 'legacy_gate',
        ),
      ]);
      final writer = NarrativeFactRuntimeWriter(resolver);
      const original = GameState(
        saveId: 'writer_false',
        storyFlags: StoryFlags(
          activeFlags: {'legacy_gate', 'unrelated_runtime'},
        ),
        progression: PlayerProgression(
          storyFlags: ['legacy_gate', 'unrelated_progression'],
        ),
        consumedEventIds: {'legacy_event'},
      );

      final result = writer.setFact(
        gameState: original,
        factId: 'fact_gate',
        value: false,
      );

      expect(result, isA<NarrativeFactRuntimeWriteApplied>());
      expect(result.gameState.narrativeFactRuntimeState.overridesByFactId, {
        'fact_gate': false,
      });
      expect(result.gameState.storyFlags.activeFlags, {'unrelated_runtime'});
      expect(
        result.gameState.progression.storyFlags,
        ['unrelated_progression'],
      );
      expect(result.gameState.consumedEventIds, {'legacy_event'});
      expect(original.storyFlags.activeFlags, contains('legacy_gate'));
    });

    test('writes explicit true while preserving orphan overrides', () {
      final resolver = NarrativeFactRuntimeResolver.fromFacts([
        NarrativeFactDefinition(
          id: 'fact_gate',
          label: 'Gate',
          legacyFlagName: 'legacy_gate',
        ),
      ]);
      final writer = NarrativeFactRuntimeWriter(resolver);
      final original = GameState(
        saveId: 'writer_true',
        narrativeFactRuntimeState: NarrativeFactRuntimeState(
          overridesByFactId: const {'fact_orphan': false},
        ),
      );

      final result = writer.setFact(
        gameState: original,
        factId: 'fact_gate',
        value: true,
      );

      expect(result.success, isTrue);
      expect(result.gameState.narrativeFactRuntimeState.overridesByFactId, {
        'fact_gate': true,
        'fact_orphan': false,
      });
      expect(result.gameState.storyFlags.activeFlags, {'legacy_gate'});
      expect(result.gameState.progression.storyFlags, ['legacy_gate']);
    });

    test('keeps explicit intent across default and alias changes', () {
      final firstResolver = NarrativeFactRuntimeResolver.fromFacts([
        NarrativeFactDefinition(
          id: 'fact_gate',
          label: 'Gate',
          defaultValue: true,
          legacyFlagName: 'legacy_old',
        ),
      ]);
      final written = NarrativeFactRuntimeWriter(firstResolver).setFact(
        gameState: const GameState(saveId: 'writer_change'),
        factId: 'fact_gate',
        value: false,
      );
      final changedResolver = NarrativeFactRuntimeResolver.fromFacts([
        NarrativeFactDefinition(
          id: 'fact_gate',
          label: 'Gate changed',
          defaultValue: false,
          legacyFlagName: 'legacy_new',
        ),
      ]);

      final resolved = changedResolver.resolve(
        factId: 'fact_gate',
        runtimeState: written.gameState.narrativeFactRuntimeState,
        storyFlags: const StoryFlags(activeFlags: {'legacy_new'}),
      ) as NarrativeFactRuntimeResolved;

      expect(resolved.value, isFalse);
      expect(resolved.source, NarrativeFactRuntimeValueSource.explicitOverride);
    });

    test('rejects unknown and ambiguous Facts with the original state', () {
      const original = GameState(saveId: 'writer_rejected');
      final unknown = NarrativeFactRuntimeWriter(
        NarrativeFactRuntimeResolver.fromFacts(const []),
      ).setFact(
        gameState: original,
        factId: 'fact_missing',
        value: true,
      );
      final ambiguous = NarrativeFactRuntimeWriter(
        NarrativeFactRuntimeResolver.fromFacts([
          NarrativeFactDefinition(id: 'fact_dup', label: 'A'),
          NarrativeFactDefinition(id: 'fact_dup', label: 'B'),
        ]),
      ).setFact(
        gameState: original,
        factId: 'fact_dup',
        value: true,
      );

      expect(unknown.success, isFalse);
      expect(unknown.errorCode, NarrativeFactRuntimeWriteErrorCode.unknownFact);
      expect(identical(unknown.gameState, original), isTrue);
      expect(
        ambiguous.errorCode,
        NarrativeFactRuntimeWriteErrorCode.ambiguousFact,
      );
      expect(identical(ambiguous.gameState, original), isTrue);
    });

    test('survives SaveData round-trip after explicit false', () {
      final resolver = NarrativeFactRuntimeResolver.fromFacts([
        NarrativeFactDefinition(
          id: 'fact_gate',
          label: 'Gate',
          defaultValue: true,
          legacyFlagName: 'legacy_gate',
        ),
      ]);
      final written = NarrativeFactRuntimeWriter(resolver).setFact(
        gameState: const GameState(
          saveId: 'writer_round_trip',
          storyFlags: StoryFlags(activeFlags: {'legacy_gate'}),
          progression: PlayerProgression(storyFlags: ['legacy_gate']),
        ),
        factId: 'fact_gate',
        value: false,
      );

      final restored = gameStateFromSaveData(
        saveDataFromGameState(written.gameState),
      );
      final resolved = resolver.resolve(
        factId: 'fact_gate',
        runtimeState: restored.narrativeFactRuntimeState,
        storyFlags: restored.storyFlags,
      ) as NarrativeFactRuntimeResolved;

      expect(resolved.value, isFalse);
      expect(restored.storyFlags.activeFlags, isNot(contains('legacy_gate')));
      expect(
        restored.progression.storyFlags,
        isNot(contains('legacy_gate')),
      );
    });
  });
}
```

## Annexe 7 — Contenu complet de `packages/map_core/test/project_validator_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectValidator Fact runtime keys', () {
    test('accepts unique Fact IDs aliases and runtime keys', () {
      final project = _project([
        NarrativeFactDefinition(id: 'fact_a', label: 'A'),
        NarrativeFactDefinition(
          id: 'fact_b',
          label: 'B',
          legacyFlagName: 'legacy_b',
        ),
      ]);

      expect(() => ProjectValidator.validate(project), returnsNormally);
    });

    test('rejects duplicate Fact IDs', () {
      final project = _project([
        NarrativeFactDefinition(id: 'fact_dup', label: 'A'),
        NarrativeFactDefinition(id: 'fact_dup', label: 'B'),
      ]);

      expect(
        () => ProjectValidator.validate(project),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects duplicate aliases', () {
      final project = _project([
        NarrativeFactDefinition(
          id: 'fact_a',
          label: 'A',
          legacyFlagName: 'legacy_shared',
        ),
        NarrativeFactDefinition(
          id: 'fact_b',
          label: 'B',
          legacyFlagName: 'legacy_shared',
        ),
      ]);

      expect(
        () => ProjectValidator.validate(project),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects an alias equal to another Fact ID', () {
      final project = _project([
        NarrativeFactDefinition(id: 'fact_a', label: 'A'),
        NarrativeFactDefinition(
          id: 'fact_b',
          label: 'B',
          legacyFlagName: 'fact_a',
        ),
      ]);

      expect(
        () => ProjectValidator.validate(project),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}

ProjectManifest _project(List<NarrativeFactDefinition> facts) {
  return ProjectManifest(
    name: 'Fact validator project',
    maps: const [],
    tilesets: const [],
    facts: facts,
  );
}
```

## Annexe 8 — Contenu complet de `packages/map_core/test/validated_legacy_claim_index_runtime_readiness_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const _eventA = 'evt_019abcde-0000-7000-8000-000000000001';
const _eventB = 'evt_019abcde-0000-7000-8000-000000000002';
const _fingerprintA =
    'sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _fingerprintB =
    'sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

void main() {
  group('ValidatedLegacyClaimIndex runtime readiness', () {
    test('empty registry is ready and resolves absent without null', () {
      final index = buildValidatedLegacyClaimIndex(_registry());
      final source = NarrativeEventSourceRef.mapEnter('map_port');
      final provenance = LegacySourceRef.mapEvent('map_port', 'legacy');

      expect(index.canStartDualRead, isTrue);
      expect(index.canEnterDualRead, isTrue);
      expect(index.canRunDualRead, isTrue);
      expect(index.resolveSource(source), isA<LegacyClaimSourceAbsent>());
      expect(
        index.resolveProvenance(provenance),
        isA<LegacyClaimProvenanceAbsent>(),
      );
    });

    test('valid source and provenance resolve to the same cohort', () {
      final source = NarrativeEventSourceRef.mapEnter('map_port');
      final provenance = LegacySourceRef.mapEvent('map_port', 'legacy');
      final claim = _claim(
        source: source,
        provenance: provenance,
        targetIds: const [_eventA],
      );
      final index = buildRuntimeValidatedLegacyClaimIndex(
        _registry(
          records: [_configured(_eventA, source: source)],
          claims: [claim],
        ),
        runtimeEvidence: _evidence([
          _evidenceEntry(source: source, provenance: provenance),
        ]),
      );

      final sourceResolution = index.resolveSource(source);
      final provenanceResolution = index.resolveProvenance(provenance);

      expect(index.canStartDualRead, isTrue);
      expect(index.canEnterDualRead, isTrue);
      expect(index.canRunDualRead, isTrue);
      expect(sourceResolution, isA<LegacyClaimSourceValid>());
      expect(provenanceResolution, isA<LegacyClaimProvenanceValid>());
      expect(sourceResolution.claim, same(claim));
      expect(provenanceResolution.claim, same(claim));
      expect(sourceResolution.cohortId, claim.cohortId);
      expect(provenanceResolution.cohortId, claim.cohortId);
      expect(
        index.requireMatchingValidCohort(
          source: source,
          provenance: provenance,
        ),
        same(claim),
      );
    });

    test('local target failures become typed source and provenance tombstones',
        () {
      final cases = <({
        NarrativeEventRecord? record,
        LegacyClaimTombstoneDiagnosticCode code,
      })>[
        (
          record: null,
          code: LegacyClaimTombstoneDiagnosticCode.targetEventAbsent,
        ),
        (
          record: NarrativeEventRecord.draft(_draft(_eventA)),
          code: LegacyClaimTombstoneDiagnosticCode.targetEventDraft,
        ),
        (
          record: _configured(
            _eventA,
            source: NarrativeEventSourceRef.mapEnter('map_elsewhere'),
          ),
          code: LegacyClaimTombstoneDiagnosticCode.targetEventSourceMismatch,
        ),
      ];

      for (final testCase in cases) {
        final source = NarrativeEventSourceRef.mapEnter('map_port');
        final provenance = LegacySourceRef.mapEvent('map_port', 'legacy');
        final claim = _claim(
          source: source,
          provenance: provenance,
          targetIds: const [_eventA],
        );
        final index = buildRuntimeValidatedLegacyClaimIndex(
          _registry(
            records: [if (testCase.record != null) testCase.record!],
            claims: [claim],
          ),
          runtimeEvidence: _evidence([
            _evidenceEntry(source: source, provenance: provenance),
          ]),
        );

        final sourceResolution = index.resolveSource(source);
        final provenanceResolution = index.resolveProvenance(provenance);

        expect(index.canStartDualRead, isFalse);
        expect(index.canEnterDualRead, isFalse);
        expect(index.canRunDualRead, isTrue);
        expect(sourceResolution, isA<LegacyClaimSourceTombstone>());
        expect(provenanceResolution, isA<LegacyClaimProvenanceTombstone>());
        expect(sourceResolution.claim, same(claim));
        expect(provenanceResolution.claim, same(claim));
        expect(sourceResolution.cohortId, claim.cohortId);
        expect(provenanceResolution.cohortId, claim.cohortId);
        expect(sourceResolution.diagnostics.single.code, testCase.code);
        expect(provenanceResolution.diagnostics.single.code, testCase.code);
        expect(
          sourceResolution.diagnostics.single.targetEventId,
          _eventA,
        );
        expect(
          () => sourceResolution.diagnostics.add(
            sourceResolution.diagnostics.single,
          ),
          throwsUnsupportedError,
        );
      }
    });

    test('a local tombstone does not block another valid source', () {
      final tombstoneSource = NarrativeEventSourceRef.mapEnter('map_port');
      final validSource = NarrativeEventSourceRef.mapEnter('map_forest');
      final tombstoneClaim = _claim(
        source: tombstoneSource,
        provenance: LegacySourceRef.mapEvent('map_port', 'legacy'),
        targetIds: const [_eventA],
      );
      final validClaim = _claim(
        source: validSource,
        provenance: LegacySourceRef.mapEvent('map_forest', 'legacy'),
        targetIds: const [_eventB],
        sourceFingerprint: _fingerprintB,
      );
      final index = buildRuntimeValidatedLegacyClaimIndex(
        _registry(
          records: [_configured(_eventB, source: validSource)],
          claims: [tombstoneClaim, validClaim],
        ),
        runtimeEvidence: _evidence([
          _evidenceEntry(
            source: tombstoneSource,
            provenance: tombstoneClaim.members.single.provenance,
          ),
          _evidenceEntry(
            source: validSource,
            provenance: validClaim.members.single.provenance,
            sourceFingerprint: _fingerprintB,
          ),
        ]),
      );

      expect(index.canEnterDualRead, isFalse);
      expect(index.canRunDualRead, isTrue);
      expect(
        index.resolveSource(tombstoneSource),
        isA<LegacyClaimSourceTombstone>(),
      );
      expect(index.resolveSource(validSource), isA<LegacyClaimSourceValid>());
    });

    test('global cohort source and provenance collisions block runtime', () {
      final sourceA = NarrativeEventSourceRef.mapEnter('map_a');
      final sourceB = NarrativeEventSourceRef.mapEnter('map_b');
      final provenanceA = LegacySourceRef.mapEvent('map_a', 'legacy_a');
      final provenanceB = LegacySourceRef.mapEvent('map_b', 'legacy_b');
      final claimA = _claim(
        source: sourceA,
        provenance: provenanceA,
        targetIds: const [_eventA],
      );
      final records = [
        _configured(_eventA, source: sourceA),
        _configured(_eventB, source: sourceB),
      ];
      final cases = [
        [claimA, claimA],
        [
          claimA,
          _claim(
            source: sourceA,
            provenance: provenanceB,
            targetIds: const [_eventB],
            sourceFingerprint: _fingerprintB,
          ),
        ],
        [
          claimA,
          _claim(
            source: sourceB,
            provenance: provenanceA,
            targetIds: const [_eventB],
            sourceFingerprint: _fingerprintB,
          ),
        ],
      ];

      for (final claims in cases) {
        final index = buildRuntimeValidatedLegacyClaimIndex(
          _registry(records: records, claims: claims),
          runtimeEvidence: _evidence([
            _evidenceEntry(source: sourceA, provenance: provenanceA),
            _evidenceEntry(
              source: sourceB,
              provenance: provenanceB,
              sourceFingerprint: _fingerprintB,
            ),
          ]),
        );

        expect(index.canStartDualRead, isFalse);
        expect(index.canEnterDualRead, isFalse);
        expect(index.canRunDualRead, isFalse);
        expect(index.globalConflicts, isNotEmpty);
        expect(() => index.resolveSource(sourceA), throwsStateError);
        expect(() => index.resolveProvenance(provenanceA), throwsStateError);
      }
    });

    test('mismatched valid source and provenance cohorts fail preparation', () {
      final sourceA = NarrativeEventSourceRef.mapEnter('map_a');
      final sourceB = NarrativeEventSourceRef.mapEnter('map_b');
      final provenanceA = LegacySourceRef.mapEvent('map_a', 'legacy_a');
      final provenanceB = LegacySourceRef.mapEvent('map_b', 'legacy_b');
      final claimA = _claim(
        source: sourceA,
        provenance: provenanceA,
        targetIds: const [_eventA],
      );
      final claimB = _claim(
        source: sourceB,
        provenance: provenanceB,
        targetIds: const [_eventB],
        sourceFingerprint: _fingerprintB,
      );
      final index = buildRuntimeValidatedLegacyClaimIndex(
        _registry(
          records: [
            _configured(_eventA, source: sourceA),
            _configured(_eventB, source: sourceB),
          ],
          claims: [claimA, claimB],
        ),
        runtimeEvidence: _evidence([
          _evidenceEntry(source: sourceA, provenance: provenanceA),
          _evidenceEntry(
            source: sourceB,
            provenance: provenanceB,
            sourceFingerprint: _fingerprintB,
          ),
        ]),
      );

      expect(
        () => index.requireMatchingValidCohort(
          source: sourceA,
          provenance: provenanceB,
        ),
        throwsStateError,
      );
    });

    test('typed diagnostics are immutable and stable across builds', () {
      final source = NarrativeEventSourceRef.mapEnter('map_port');
      final provenance = LegacySourceRef.mapEvent('map_port', 'legacy');
      final claim = _claim(
        source: source,
        provenance: provenance,
        targetIds: const [_eventA, _eventB],
      );
      final registry = _registry(claims: [claim]);

      final evidence = _evidence([
        _evidenceEntry(source: source, provenance: provenance),
      ]);
      final first = buildRuntimeValidatedLegacyClaimIndex(
        registry,
        runtimeEvidence: evidence,
      );
      final second = buildRuntimeValidatedLegacyClaimIndex(
        registry,
        runtimeEvidence: evidence,
      );
      final firstDiagnostics = first.resolveSource(source).diagnostics;
      final secondDiagnostics = second.resolveSource(source).diagnostics;

      expect(firstDiagnostics, secondDiagnostics);
      expect(
        firstDiagnostics.map((diagnostic) => diagnostic.code.code),
        ['targetEventAbsent', 'targetEventAbsent'],
      );
      expect(
        firstDiagnostics.map((diagnostic) => diagnostic.targetEventId),
        [_eventA, _eventB],
      );
      expect(() => firstDiagnostics.clear(), throwsUnsupportedError);
    });

    test('registry-only claims cannot announce runtime readiness', () {
      final source = NarrativeEventSourceRef.mapEnter('map_port');
      final provenance = LegacySourceRef.mapEvent('map_port', 'legacy');
      final claim = _claim(
        source: source,
        provenance: provenance,
        targetIds: const [_eventA],
      );
      final index = buildValidatedLegacyClaimIndex(
        _registry(
          records: [_configured(_eventA, source: source)],
          claims: [claim],
        ),
      );

      expect(index.runtimeEvidenceValidated, isFalse);
      expect(index.canStartDualRead, isFalse);
      expect(index.canEnterDualRead, isFalse);
      expect(index.canRunDualRead, isFalse);
      expect(() => index.resolveSource(source), throwsStateError);
      expect(() => index.resolveProvenance(provenance), throwsStateError);
    });

    test('missing stale and source-mismatched evidence become tombstones', () {
      final source = NarrativeEventSourceRef.mapEnter('map_port');
      final provenance = LegacySourceRef.mapEvent('map_port', 'legacy');
      final claim = _claim(
        source: source,
        provenance: provenance,
        targetIds: const [_eventA],
      );
      final registry = _registry(
        records: [_configured(_eventA, source: source)],
        claims: [claim],
      );
      final cases = <({
        LegacyClaimRuntimeEvidence evidence,
        LegacyClaimTombstoneDiagnosticCode code,
      })>[
        (
          evidence: _evidence(const []),
          code: LegacyClaimTombstoneDiagnosticCode.provenanceMissing,
        ),
        (
          evidence: _evidence([
            _evidenceEntry(
              source: source,
              provenance: provenance,
              sourceFingerprint: _fingerprintB,
            ),
          ]),
          code: LegacyClaimTombstoneDiagnosticCode.sourceFingerprintMismatch,
        ),
        (
          evidence: _evidence([
            _evidenceEntry(
              source: NarrativeEventSourceRef.mapEnter('map_elsewhere'),
              provenance: provenance,
            ),
          ]),
          code: LegacyClaimTombstoneDiagnosticCode.provenanceSourceMismatch,
        ),
      ];

      for (final testCase in cases) {
        final index = buildRuntimeValidatedLegacyClaimIndex(
          registry,
          runtimeEvidence: testCase.evidence,
        );
        final sourceResolution = index.resolveSource(source);
        final provenanceResolution = index.resolveProvenance(provenance);

        expect(index.runtimeEvidenceValidated, isTrue);
        expect(index.canEnterDualRead, isFalse);
        expect(index.canRunDualRead, isTrue);
        expect(sourceResolution, isA<LegacyClaimSourceTombstone>());
        expect(provenanceResolution, isA<LegacyClaimProvenanceTombstone>());
        expect(
          sourceResolution.diagnostics.map((entry) => entry.code),
          contains(testCase.code),
        );
        expect(
          provenanceResolution.diagnostics.map((entry) => entry.code),
          contains(testCase.code),
        );
      }
    });

    test('an unexpected cohort member tombstones source and provenance', () {
      final source = NarrativeEventSourceRef.mapEnter('map_port');
      final claimed = LegacySourceRef.mapEvent('map_port', 'legacy_a');
      final unexpected = LegacySourceRef.mapEvent('map_port', 'legacy_b');
      final claim = _claim(
        source: source,
        provenance: claimed,
        targetIds: const [_eventA],
      );
      final index = buildRuntimeValidatedLegacyClaimIndex(
        _registry(
          records: [_configured(_eventA, source: source)],
          claims: [claim],
        ),
        runtimeEvidence: _evidence([
          _evidenceEntry(source: source, provenance: claimed),
          _evidenceEntry(
            source: source,
            provenance: unexpected,
            sourceFingerprint: _fingerprintB,
          ),
        ]),
      );

      final sourceResolution = index.resolveSource(source);
      final unexpectedResolution = index.resolveProvenance(unexpected);

      expect(index.canRunDualRead, isTrue);
      expect(index.canEnterDualRead, isFalse);
      expect(sourceResolution, isA<LegacyClaimSourceTombstone>());
      expect(unexpectedResolution, isA<LegacyClaimProvenanceTombstone>());
      expect(
        sourceResolution.diagnostics.map((entry) => entry.code),
        contains(LegacyClaimTombstoneDiagnosticCode.cohortMemberUnexpected),
      );
      expect(unexpectedResolution.claim, same(claim));
      expect(unexpectedResolution.cohortId, claim.cohortId);
    });
  });
}

NarrativeEventRegistry _registry({
  List<NarrativeEventRecord> records = const [],
  List<LegacySourceClaim> claims = const [],
}) {
  return NarrativeEventRegistry(
    schemaVersion: 1,
    mode: EventSystemMode.dualRead,
    records: records,
    legacyClaims: claims,
  );
}

NarrativeEventRecord _configured(
  String id, {
  required NarrativeEventSourceRef source,
}) {
  return NarrativeEventRecord.configuredStructurallyUnchecked(
    NarrativeEventDefinition(
      id: id,
      name: id,
      source: source,
      conditions: const [],
      sceneId: 'scene',
      reusePolicy: NarrativeEventReusePolicy.oneShot,
      priority: 0,
      order: 0,
    ),
    enabled: true,
  );
}

NarrativeEventDraft _draft(String id) {
  return NarrativeEventDraft(
    id: id,
    name: id,
    conditions: const [],
    priority: 0,
    order: 0,
  );
}

LegacySourceClaim _claim({
  required NarrativeEventSourceRef source,
  required LegacySourceRef provenance,
  required List<String> targetIds,
  String sourceFingerprint = _fingerprintA,
}) {
  final member = LegacySourceClaimMember(
    provenance: provenance,
    sourceFingerprint: sourceFingerprint,
  );
  final cohortId = computeLegacySourceCohortId(source, [provenance]);
  return LegacySourceClaim(
    cohortId: cohortId,
    source: source,
    members: [member],
    cohortFingerprint: computeLegacySourceCohortFingerprint(
      cohortId,
      [member],
    ),
    targetEventIds: targetIds,
    migrationReceiptId: 'receipt_1',
  );
}

LegacyClaimRuntimeEvidence _evidence(
  List<LegacyClaimRuntimeEvidenceEntry> entries,
) {
  return LegacyClaimRuntimeEvidence(entries: entries);
}

LegacyClaimRuntimeEvidenceEntry _evidenceEntry({
  required NarrativeEventSourceRef source,
  required LegacySourceRef provenance,
  String sourceFingerprint = _fingerprintA,
}) {
  return LegacyClaimRuntimeEvidenceEntry(
    source: source,
    provenance: provenance,
    sourceFingerprint: sourceFingerprint,
  );
}
```

## Annexe 9 — Contenu complet de `packages/map_gameplay/test/narrative_fact_script_condition_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  const evaluator = ScriptConditionEvaluator();

  group('Narrative Fact ScriptCondition context', () {
    test('uses canonical override alias and default precedence', () {
      final resolver = NarrativeFactRuntimeResolver.fromFacts([
        NarrativeFactDefinition(
          id: 'fact_false',
          label: 'False',
        ),
        NarrativeFactDefinition(
          id: 'fact_true',
          label: 'True',
          defaultValue: true,
        ),
        NarrativeFactDefinition(
          id: 'fact_alias',
          label: 'Alias',
          legacyFlagName: 'legacy_alias',
        ),
        NarrativeFactDefinition(
          id: 'fact_override_false',
          label: 'Override false',
          defaultValue: true,
          legacyFlagName: 'legacy_override_false',
        ),
        NarrativeFactDefinition(
          id: 'fact_override_true',
          label: 'Override true',
        ),
      ]);
      final context = ScriptEvaluationContext(
        narrativeFactResolver: resolver,
      );
      final state = GameState(
        saveId: 'script_fact_matrix',
        storyFlags: const StoryFlags(
          activeFlags: {'legacy_alias', 'legacy_override_false'},
        ),
        narrativeFactRuntimeState: NarrativeFactRuntimeState(
          overridesByFactId: const {
            'fact_override_false': false,
            'fact_override_true': true,
          },
        ),
      );

      expect(
        evaluator.evaluate(
          ScriptConditionFactory.flagIsSet('fact_false'),
          state,
          context: context,
        ),
        isFalse,
      );
      expect(
        evaluator.evaluate(
          ScriptConditionFactory.flagIsSet('fact_true'),
          state,
          context: context,
        ),
        isTrue,
      );
      expect(
        evaluator.evaluate(
          ScriptConditionFactory.flagIsSet('fact_alias'),
          state,
          context: context,
        ),
        isTrue,
      );
      expect(
        evaluator.evaluate(
          ScriptConditionFactory.flagIsSet('fact_override_false'),
          state,
          context: context,
        ),
        isFalse,
      );
      expect(
        evaluator.evaluate(
          ScriptConditionFactory.flagIsUnset('fact_override_false'),
          state,
          context: context,
        ),
        isTrue,
      );
      expect(
        evaluator.evaluate(
          ScriptConditionFactory.flagIsSet('fact_override_true'),
          state,
          context: context,
        ),
        isTrue,
      );
    });

    test('keeps raw flag behavior without a canonical context', () {
      final state = GameState(
        saveId: 'script_fact_raw',
        storyFlags: const StoryFlags(activeFlags: {'raw_flag'}),
      );

      expect(
        evaluator.evaluate(
          ScriptConditionFactory.flagIsSet('raw_flag'),
          state,
        ),
        isTrue,
      );
      expect(
        evaluator.evaluate(
          ScriptConditionFactory.flagIsSet('fact_default_true'),
          state,
        ),
        isFalse,
      );
      expect(
        evaluator.evaluate(
          ScriptConditionFactory.flagIsUnset('fact_default_true'),
          state,
        ),
        isTrue,
      );
    });

    test('falls back to raw behavior for an unknown contextual reference', () {
      final context = ScriptEvaluationContext(
        narrativeFactResolver: NarrativeFactRuntimeResolver.fromFacts(const []),
      );
      const state = GameState(
        saveId: 'script_fact_unknown',
        storyFlags: StoryFlags(activeFlags: {'raw_flag'}),
      );

      expect(
        evaluator.evaluate(
          ScriptConditionFactory.flagIsSet('raw_flag'),
          state,
          context: context,
        ),
        isTrue,
      );
    });

    test('fails closed for an ambiguous canonical catalog', () {
      final context = ScriptEvaluationContext(
        narrativeFactResolver: NarrativeFactRuntimeResolver.fromFacts([
          NarrativeFactDefinition(id: 'fact_dup', label: 'A'),
          NarrativeFactDefinition(id: 'fact_dup', label: 'B'),
        ]),
      );
      const state = GameState(
        saveId: 'script_fact_ambiguous',
        storyFlags: StoryFlags(activeFlags: {'fact_dup'}),
      );

      expect(
        evaluator.evaluate(
          ScriptConditionFactory.flagIsSet('fact_dup'),
          state,
          context: context,
        ),
        isFalse,
      );
      expect(
        evaluator.evaluate(
          ScriptConditionFactory.flagIsUnset('fact_dup'),
          state,
          context: context,
        ),
        isFalse,
      );
    });
  });
}
```

## Annexe 10 — Contenu complet de `packages/map_runtime/lib/src/application/scene_runtime/scene_fact_condition_runtime_resolver.dart`

```dart
import 'package:map_core/map_core.dart';

bool evaluateCanonicalNarrativeFactSceneCondition({
  required SceneConditionSource source,
  required GameState gameState,
  required NarrativeFactRuntimeResolver resolver,
}) {
  if (source.sourceKind != SceneConditionSourceKind.fact) {
    throw ArgumentError.value(
      source.sourceKind,
      'source.sourceKind',
      'must be SceneConditionSourceKind.fact',
    );
  }
  final resolution = resolver.resolve(
    factId: source.sourceId,
    runtimeState: gameState.narrativeFactRuntimeState,
    storyFlags: gameState.storyFlags,
  );
  if (resolution is! NarrativeFactRuntimeResolved) {
    throw StateError(
      'Canonical Fact condition "${source.sourceId}" could not be resolved: '
      '${resolution.runtimeType}.',
    );
  }
  return switch (source.operator) {
    SceneConditionOperator.isTrue => resolution.value,
    SceneConditionOperator.isFalse => !resolution.value,
    SceneConditionOperator.equals => switch (source.value) {
        'true' => resolution.value,
        'false' => !resolution.value,
        _ => throw UnsupportedError(
            'Canonical Fact equality value "${source.value}" is not '
            'supported.',
          ),
      },
  };
}
```

## Annexe 11 — Contenu complet de `packages/map_runtime/test/narrative_fact_runtime_cross_consumer_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  group('Narrative Fact runtime cross consumer matrix', () {
    for (final testCase in _cases()) {
      test(testCase.name, () {
        final resolver =
            NarrativeFactRuntimeResolver.fromFacts([testCase.fact]);
        final direct = resolver.resolve(
          factId: testCase.fact.id,
          runtimeState: testCase.state.narrativeFactRuntimeState,
          storyFlags: testCase.state.storyFlags,
        ) as NarrativeFactRuntimeResolved;
        final project = _project(testCase.fact);
        final worldRule = projectWorldRuleEffects(
          project,
          testCase.state,
          maps: const [_map],
          mapId: 'map_test',
        );
        final sceneCondition = evaluateCanonicalNarrativeFactSceneCondition(
          source: SceneConditionSource(
            sourceKind: SceneConditionSourceKind.fact,
            sourceId: testCase.fact.id,
            operator: SceneConditionOperator.isTrue,
          ),
          gameState: testCase.state,
          resolver: resolver,
        );
        final scriptCondition = const ScriptConditionEvaluator().evaluate(
          ScriptConditionFactory.flagIsSet(testCase.fact.id),
          testCase.state,
          context: ScriptEvaluationContext(
            narrativeFactResolver: resolver,
          ),
        );

        expect(direct.value, testCase.expected);
        expect(worldRule.isNotEmpty, testCase.expected);
        expect(sceneCondition, testCase.expected);
        expect(scriptCondition, testCase.expected);
      });
    }

    test('supports isFalse and equals boolean operators', () {
      final fact = NarrativeFactDefinition(
        id: 'fact_false',
        label: 'False',
      );
      final resolver = NarrativeFactRuntimeResolver.fromFacts([fact]);
      const state = GameState(saveId: 'scene_operators');

      expect(
        evaluateCanonicalNarrativeFactSceneCondition(
          source: SceneConditionSource(
            sourceKind: SceneConditionSourceKind.fact,
            sourceId: fact.id,
            operator: SceneConditionOperator.isFalse,
          ),
          gameState: state,
          resolver: resolver,
        ),
        isTrue,
      );
      expect(
        evaluateCanonicalNarrativeFactSceneCondition(
          source: SceneConditionSource(
            sourceKind: SceneConditionSourceKind.fact,
            sourceId: fact.id,
            operator: SceneConditionOperator.equals,
            value: 'false',
          ),
          gameState: state,
          resolver: resolver,
        ),
        isTrue,
      );
    });

    test('fails closed for unknown and ambiguous canonical Facts', () {
      const state = GameState(saveId: 'scene_invalid');
      final unknown = NarrativeFactRuntimeResolver.fromFacts(const []);
      final ambiguous = NarrativeFactRuntimeResolver.fromFacts([
        NarrativeFactDefinition(id: 'fact_dup', label: 'A'),
        NarrativeFactDefinition(id: 'fact_dup', label: 'B'),
      ]);

      expect(
        () => evaluateCanonicalNarrativeFactSceneCondition(
          source: SceneConditionSource(
            sourceKind: SceneConditionSourceKind.fact,
            sourceId: 'fact_missing',
            operator: SceneConditionOperator.isTrue,
          ),
          gameState: state,
          resolver: unknown,
        ),
        throwsStateError,
      );
      expect(
        () => evaluateCanonicalNarrativeFactSceneCondition(
          source: SceneConditionSource(
            sourceKind: SceneConditionSourceKind.fact,
            sourceId: 'fact_dup',
            operator: SceneConditionOperator.isTrue,
          ),
          gameState: state,
          resolver: ambiguous,
        ),
        throwsStateError,
      );
    });

    test('RuntimeStoryBranching resolves authored Fact bindings canonically',
        () {
      final fact = NarrativeFactDefinition(
        id: 'fact_page',
        label: 'Page',
        defaultValue: true,
      );
      final resolver = NarrativeFactRuntimeResolver.fromFacts([fact]);
      final state = GameState(
        saveId: 'page_binding',
        narrativeFactRuntimeState: NarrativeFactRuntimeState(
          overridesByFactId: const {'fact_page': false},
        ),
      );
      final event = MapEventDefinition(
        id: 'event_page',
        position: const EventPosition(layerId: 'events', x: 0, y: 0),
        pages: [
          MapEventPage(
            pageNumber: 0,
            condition: ScriptConditionFactory.flagIsSet('fact_page'),
          ),
          const MapEventPage(pageNumber: 1),
        ],
      );

      final active = const RuntimeStoryBranching().resolveEventPage(
        event,
        state,
        context: ScriptEvaluationContext(narrativeFactResolver: resolver),
      );

      expect(active, isNotNull);
      expect(active!.pageIndex, 1);
    });
  });
}

List<_FactCase> _cases() {
  return [
    _FactCase(
      name: 'default false without flag or override',
      fact: NarrativeFactDefinition(id: 'fact_matrix', label: 'Matrix'),
      state: const GameState(saveId: 'matrix_default_false'),
      expected: false,
    ),
    _FactCase(
      name: 'default true without flag or override',
      fact: NarrativeFactDefinition(
        id: 'fact_matrix',
        label: 'Matrix',
        defaultValue: true,
      ),
      state: const GameState(saveId: 'matrix_default_true'),
      expected: true,
    ),
    _FactCase(
      name: 'active legacy alias without override',
      fact: NarrativeFactDefinition(
        id: 'fact_matrix',
        label: 'Matrix',
        legacyFlagName: 'legacy_matrix',
      ),
      state: const GameState(
        saveId: 'matrix_alias',
        storyFlags: StoryFlags(activeFlags: {'legacy_matrix'}),
      ),
      expected: true,
    ),
    _FactCase(
      name: 'explicit false overrides a true default',
      fact: NarrativeFactDefinition(
        id: 'fact_matrix',
        label: 'Matrix',
        defaultValue: true,
      ),
      state: GameState(
        saveId: 'matrix_override_false',
        narrativeFactRuntimeState: NarrativeFactRuntimeState(
          overridesByFactId: const {'fact_matrix': false},
        ),
      ),
      expected: false,
    ),
    _FactCase(
      name: 'explicit false overrides an active alias',
      fact: NarrativeFactDefinition(
        id: 'fact_matrix',
        label: 'Matrix',
        legacyFlagName: 'legacy_matrix',
      ),
      state: GameState(
        saveId: 'matrix_alias_override_false',
        storyFlags: const StoryFlags(activeFlags: {'legacy_matrix'}),
        narrativeFactRuntimeState: NarrativeFactRuntimeState(
          overridesByFactId: const {'fact_matrix': false},
        ),
      ),
      expected: false,
    ),
    _FactCase(
      name: 'explicit true overrides a false default',
      fact: NarrativeFactDefinition(id: 'fact_matrix', label: 'Matrix'),
      state: GameState(
        saveId: 'matrix_override_true',
        narrativeFactRuntimeState: NarrativeFactRuntimeState(
          overridesByFactId: const {'fact_matrix': true},
        ),
      ),
      expected: true,
    ),
  ];
}

ProjectManifest _project(NarrativeFactDefinition fact) {
  return ProjectManifest(
    name: 'Cross consumer project',
    maps: const [
      ProjectMapEntry(
        id: 'map_test',
        name: 'Map test',
        relativePath: 'maps/map_test.json',
      ),
    ],
    tilesets: const [],
    facts: [fact],
    worldRules: [
      WorldRuleDefinition(
        id: 'world_rule_fact',
        label: 'Fact rule',
        source: const WorldRuleSource(
          kind: WorldRuleSourceKind.fact,
          sourceId: 'fact_matrix',
          predicate: WorldRuleSourcePredicate.isTrue,
        ),
        target: const WorldRuleTarget(
          kind: WorldRuleTargetKind.mapEntity,
          mapId: 'map_test',
          entityId: 'npc_test',
        ),
        effect: const WorldRuleEffect(
          kind: WorldRuleEffectKind.entityVisible,
        ),
      ),
    ],
  );
}

const _map = MapData(
  id: 'map_test',
  name: 'Map test',
  size: GridSize(width: 4, height: 4),
  entities: [
    MapEntity(
      id: 'npc_test',
      name: 'NPC test',
      kind: MapEntityKind.npc,
      pos: GridPos(x: 1, y: 1),
      npc: MapEntityNpcData(displayName: 'NPC test'),
    ),
  ],
);

final class _FactCase {
  const _FactCase({
    required this.name,
    required this.fact,
    required this.state,
    required this.expected,
  });

  final String name;
  final NarrativeFactDefinition fact;
  final GameState state;
  final bool expected;
}
```

## Annexe 12 — Contenu complet de `packages/map_runtime/test/narrative_fact_runtime_save_load_test.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Narrative Fact runtime save load', () {
    late Directory directory;
    late _FactSaveRepository repository;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('fact_save_test_');
      repository = _FactSaveRepository(directory);
    });

    tearDown(() async {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });

    test('preserves explicit false true and orphan overrides', () async {
      final original = GameState(
        saveId: 'fact_runtime',
        storyFlags: const StoryFlags(activeFlags: {'legacy_flag'}),
        consumedEventIds: const {'legacy_event'},
        narrativeFactRuntimeState: NarrativeFactRuntimeState(
          overridesByFactId: const {
            'fact_default_true': false,
            'fact_orphan': true,
          },
        ),
      );

      await repository.save(original);
      final loaded = await repository.load();

      expect(loaded, isNotNull);
      expect(loaded!.narrativeFactRuntimeState,
          original.narrativeFactRuntimeState);
      expect(loaded.storyFlags, original.storyFlags);
      expect(loaded.consumedEventIds, original.consumedEventIds);

      final file = File(await repository.filePath());
      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final runtimeState =
          json['narrativeFactRuntimeState'] as Map<String, dynamic>;
      final overrides =
          runtimeState['overridesByFactId'] as Map<String, dynamic>;
      expect(overrides['fact_default_true'], isFalse);
      expect(overrides['fact_orphan'], isTrue);
    });

    test('loads old disk JSON with an empty Fact runtime state', () async {
      final file = File(await repository.filePath());
      await file.writeAsString(jsonEncode({
        'saveId': 'legacy_runtime',
        'storyFlags': {
          'activeFlags': ['legacy_flag'],
        },
      }));

      final loaded = await repository.load();

      expect(loaded, isNotNull);
      expect(loaded!.narrativeFactRuntimeState.overridesByFactId, isEmpty);
      expect(loaded.storyFlags.activeFlags, {'legacy_flag'});
    });

    test('keeps explicit false after canonical write save and reload',
        () async {
      final resolver = NarrativeFactRuntimeResolver.fromFacts([
        NarrativeFactDefinition(
          id: 'fact_gate',
          label: 'Gate',
          defaultValue: true,
          legacyFlagName: 'legacy_gate',
        ),
      ]);
      final written = NarrativeFactRuntimeWriter(resolver).setFact(
        gameState: const GameState(
          saveId: 'fact_false_disk',
          storyFlags: StoryFlags(activeFlags: {'legacy_gate'}),
          progression: PlayerProgression(storyFlags: ['legacy_gate']),
        ),
        factId: 'fact_gate',
        value: false,
      );

      await repository.save(written.gameState);
      final loaded = await repository.load();
      final resolved = resolver.resolve(
        factId: 'fact_gate',
        runtimeState: loaded!.narrativeFactRuntimeState,
        storyFlags: loaded.storyFlags,
      ) as NarrativeFactRuntimeResolved;

      expect(resolved.value, isFalse);
      expect(
        resolved.source,
        NarrativeFactRuntimeValueSource.explicitOverride,
      );
      expect(loaded.storyFlags.activeFlags, isNot(contains('legacy_gate')));
      expect(
        loaded.progression.storyFlags,
        isNot(contains('legacy_gate')),
      );
    });
  });
}

final class _FactSaveRepository extends FileGameSaveRepository {
  _FactSaveRepository(this.directory);

  final Directory directory;

  Future<String> filePath() => getSaveFilePath();

  @override
  Future<String> getSaveFilePath() async {
    final saveDirectory = Directory('${directory.path}/pokemonProject');
    if (!await saveDirectory.exists()) {
      await saveDirectory.create(recursive: true);
    }
    return '${saveDirectory.path}/game_save.json';
  }
}
```
+
## Annexe 13 — Contenu complet du rapport principal

````markdown
# NS-EVENT-V2 — F1-PREREQ — Canonical Fact Runtime Semantics, Dual-Read Readiness & Outbox Contract Closure V0

## 1. Résumé exécutif

```text
F1-PREREQ : CLOSED

PR-0 : PASS
PR-A : PASS
PR-B : PASS
PR-C : PASS
PR-D : PASS

default true -> explicit false : PASS
World Rules canonical Fact : PASS
Scene condition canonical Fact : PASS
Fact save/reload : PASS
canEnterDualRead : PASS
canRunDualRead : PASS
typed tombstones : PASS
outbox contract : PASS

F1 implementation added : NO
Production source bridge added : NO
Real project data modified by this lot : NO

Phase F1 : READY
Phase F2 : NOT READY
```

Le lot ajoute un état runtime Fact explicite et persistant, un resolver et un
writer partagés, l'alignement des quatre familles de consommateurs canoniques,
et une readiness dual-read qui distingue les conflits globaux des tombstones
locaux. Il ratifie aussi le contrat outbox strict-wire/defensive-memory sans
implémenter l'outbox.

La suite runtime complète n'est pas verte dans le worktree partagé : 45 tests
Selbrume échouent parce qu'une autre conversation a changé
`selbrume/project.json` vers `ProjectSchemaVersion.v2`, alors que ce runtime
courant ne décode que `v1`. Le fichier était propre au Gate 0 et n'a pas été
touché par ce lot. Les 140 tests files ne mentionnant pas Selbrume passent avec
1402 tests, les 36 tests runtime ciblés passent, et le host macOS build. Cette
réserve concurrente est conservée honnêtement sans élargir le scope interdit.

## 2. Baseline et Blocker F1

- HEAD de départ : `a2ee6bbdb67389336452c5431e523f179a481335`.
- Commit : `docs(event-v2): report NS-EVENT-V2 Phase F1 blocker`.
- Dernière baseline production : `5bf62901d1071d3e17553baef016e4da3b733892`.
- Cause du STOP F1-0 : sémantique Fact divergente, readiness claims sans preuve
  corpus et contradiction overlap outbox non ratifiée.
- Les deux rapports historiques F1 ont été conservés sans réécriture.

## 3. Usage MCP Dart

Le MCP Dart n'était pas disponible dans les outils de cette session. Aucun
usage MCP n'est revendiqué. La compensation a utilisé `rg`, lectures ciblées,
tests Dart/Flutter, analyses, build_runner, build macOS et reviews indépendantes.

## 4. Sous-agents et incidents

| Rôle | Mission | Verdict |
|---|---|---|
| A | Fact Domain & Save Codec | PASS |
| B | Fact Resolver & Writer | PASS |
| C | Production Consumers | PASS avec réserve raw fallback non bloquante |
| D | Dual-Read Contract | PASS après fermeture de la preuve corpus |
| E | Outbox Contract | PASS après correction des frontières de crash |
| F | Save/Load & Compatibility | PASS |
| G | Tests, Docs & F1 Reopening | PASS après reprise orchestrateur |
| R1 | Runtime Integrity | PASS PR-A/B/C/D |
| R2 | Compatibility Truthfulness | PASS PR-A/B/C/D |
| Orchestrateur | intégration, arbitrage et preuves finales | PASS avec réserve runtime concurrente |

Incident G : le rôle, pourtant assigné en lecture seule, a créé le benchmark et
modifié le codec/tests PR-C. Il a été interrompu. L'orchestrateur a audité les
quatre fichiers, repris ou corrigé chaque changement, puis relancé les tests. Le
benchmark utile a été adopté. Aucun incident n'a réduit les critères.

Incident PR-D : une première review a demandé des champs d'enveloppe étrangers
au modèle canonique exact. Ce finding a été rejeté avec preuve de la spec F1.
Les remarques pertinentes ont conduit à définir `deliveryId` comme identité
stable, puis à corriger une vraie ambiguïté entre pending durable et création
jamais sauvegardée. Les reviews finales concluent PASS.

## 5. Gate 0

```text
pwd
/Users/karim/Project/pokemonProject

git branch --show-current
main

git status --short --untracked-files=all
 M packages/map_editor/pubspec.lock

git diff --stat
 packages/map_editor/pubspec.lock | 16 ++++++++--------
 1 file changed, 8 insertions(+), 8 deletions(-)

git diff --name-only
packages/map_editor/pubspec.lock
```

Le lock editor préexistant avait et conserve le SHA-256
`a6646437ad4410fa4859f0f8007b0b9589888febc0c6df8b165d7681a9ab52dc`.

`dart pub deps` dans `map_gameplay` a signalé le lock/package config stale.
Le `dart pub get` explicitement autorisé a ajouté uniquement les transitives
`uuid 4.5.3` et `fixnum 1.1.1`, nécessaires au `map_core` courant. Hash lock :
`83b13b3f...` -> `ef1601ab...`. Les deux fichiers `.dart_tool` déjà suivis ont
été rafraîchis en cohérence avec ce lock.

Baselines avant code : `map_core` 42 tests PASS + analyze PASS ;
`map_gameplay` 25 tests PASS + analyze PASS ; `map_runtime` 16 tests PASS.

## 6. PR-0 Contract Ratification

Trois addenda `Accepted` ont été ajoutés sans réécrire les ADR historiques :

- `ADR-EV2-012-A — Canonical Fact Runtime Overrides & Resolution` ;
- `ADR-EV2-008-A — Dual-Read Entry Gate vs Runtime Readiness` ;
- `ADR-EV2-014-A — Strict Outbox Wire Invariant & Defensive Runtime Guard`.

Les matrices Facts, dual-read et outbox sont explicites. Les passes architecture
et compatibilité ont conclu PASS avant PR-A.

## 7. Fact Semantic Decision

La valeur canonique suit exactement : override explicite par `fact.id`, puis
runtime key legacy active, puis `defaultValue`. Une valeur false explicite ne
disparaît jamais quand elle égale le default courant.

## 8. Fact Runtime State

`NarrativeFactRuntimeState` expose une map immuable
`overridesByFactId: Map<String, bool>`. Il valide les IDs non vides et
trim-exacts, copie défensivement les entrées et possède equality/hash stable.

## 9. Wire Format

```json
{
  "overridesByFactId": {
    "fact_gate_open": false,
    "fact_rival_defeated": true
  }
}
```

Les clés sont triées lexicalement. Les valeurs non booléennes, sous-arbres
invalides, IDs vides ou non trim-exacts sont rejetés sans normalisation.

## 10. Old Save Compatibility

L'absence du sous-arbre dans `GameState` ou `SaveData` produit l'état vide. Les
story flags ne sont pas transformés en overrides au load. Les overrides
orphelins sont conservés et jamais rapprochés par label/alias.

## 11. Runtime Key Collision Policy

Le catalogue détecte : duplicate Fact ID, duplicate alias, alias égal à l'ID
d'un autre Fact et duplicate runtime key. Une ambiguïté retourne un résultat
typé et bloque les consommateurs canoniques ; aucun premier gagnant.

## 12. Canonical Resolver

`NarrativeFactRuntimeResolver` construit un index immuable en O(n), puis résout
en lookup O(1). Les résultats sont typés : valeur résolue et source,
`unknownFact`, `ambiguousFact` ou `invalidRuntimeKey`.

## 13. Canonical Writer

`writeNarrativeFactRuntimeValue` écrit toujours l'override, synchronise le
runtime key legacy dans `StoryFlags`, conserve les autres champs et ne touche
jamais `consumedEventIds`. Un rejet retourne l'état original et une raison
stable.

## 14. World Rules Alignment

`projectWorldRuleEffects` et les diagnostics utilisent le resolver partagé.
Le cas `default true + override false` projette false. Les catalogues ambigus
restent fail-closed et diagnostiqués.

## 15. Scene Consequence Alignment

`SceneConsequenceRuntimeWriter` délègue `setFact` au writer partagé. Le commit
multi-conséquences reste atomique : une écriture Fact rejetée annule le lot.

## 16. Scene Condition Alignment

`SceneConditionSourceKind.fact` est résolu par le helper partagé avec les
opérateurs `isTrue`, `isFalse` et `equals bool`. `factLikeStoryFlag` reste un
flag brut legacy.

## 17. ScriptCondition Compatibility

`ScriptEvaluationContext` accepte un contexte Fact canonique optionnel.
`flagIsSet/flagIsUnset` ciblant un Fact utilisent le resolver ; sans contexte,
le comportement raw historique est inchangé. `RuntimeStoryBranching` et le
chemin Event Builder V1 fournissent le contexte quand le registry Fact existe.

Réserve non bloquante : un catalogue globalement ambigu fait échouer fermé une
référence contextuelle inconnue avant fallback raw. Le loader production bloque
déjà ces projets invalides ; un test de coexistence supplémentaire reste utile.

## 18. Cross-Consumer Matrix

| Cas | Resolver | World Rule | Scene Fact | Script contextuel |
|---|---:|---:|---:|---:|
| default false, rien | false | false | false | false |
| default true, rien | true | true | true | true |
| alias actif | true | true | true | true |
| override false | false | false | false | false |
| alias + override false | false | false | false | false |
| override true | true | true | true | true |

## 19. Save/Reload Evidence

Le chemin `default true -> setFact(false) -> save -> reload` reste false. Le
round-trip disque conserve true, false et override orphelin. Une ancienne save
sans champ charge un état vide. `consumedEventIds` et story flags simples restent
inchangés au load.

## 20. PR-A Review

R1 et R2 : PASS. Gate final PR-A : 48 tests core PASS, 6 tests runtime PASS,
analyze core PASS, format PASS et build_runner PASS.

## 21. PR-B Review

R1 et R2 : PASS. Gate final PR-B : 21 tests core PASS, 23 tests gameplay PASS,
24 tests runtime PASS ; analyses sans erreur.

## 22. Dual-Read Entry Gate

`canStartDualRead` reste l'alias strict de `canEnterDualRead`. Avec claims, le
builder registry-only sans evidence runtime reste fail-closed. L'entrée exige
absence de conflit global, absence de tombstone local et preuve corpus validée.

## 23. Runtime Readiness

`canRunDualRead` exige absence de conflit global et evidence runtime validée.
Les tombstones locaux n'arrêtent pas les autres sources. Une collision globale
de cohorte/source/provenance bloque toute résolution runtime.

## 24. Typed Source Tombstones

`resolveSource` retourne une union fermée `absent`, `valid` ou `tombstone`.
Le tombstone conserve source, claim/cohort quand disponibles et diagnostics
stables/immuables. Aucun null ambigu.

## 25. Typed Provenance Tombstones

`resolveProvenance` expose les mêmes variantes pour `LegacySourceRef`. Une
source et sa provenance valides doivent pointer la même cohorte ; la divergence
échoue pendant la préparation.

## 26. Claim Compatibility

Le codec registry, le JSON claims, fingerprints, receipts, plans et règles de
création de claims sont inchangés. La preuve corpus est fournie séparément via
`LegacyClaimRuntimeEvidence`. Les claims sans preuve ne sont pas déclarés
runtime-ready.

## 27. PR-C Review

Le premier R2 a bloqué la validation registry-only, qui pouvait présenter un
fingerprint stale comme valide. La correction a ajouté le builder corpus-aware,
les diagnostics typed tombstones et les gates fail-closed. Reviews finales R1
et R2 : PASS. Gate PR-C : 113 tests PASS, analyze PASS.

## 28. Outbox Contract Closure

`deliveryId` est l'identité stable d'une commande logique et sa clé
d'idempotence ; aucun `dispatchId` secondaire n'est inventé. Wire et
constructeurs futurs rejetteront overlap pending/delivered et duplicate pending.
Une incohérence mémoire overlap est terminalisée sans dispatch, sans tentative
ni enfant, avec `dataInconsistency` ; le decode ne la répare jamais.

Les frontières de crash distinguent : création jamais sauvegardée (delivery et
effets producteur absents après reload), pending déjà durable (même ID restauré)
et terminal delivered durable (aucun replay). L'exactly-once d'un effet externe
hors commit `GameState` reste hors garantie V0 et exige un protocole idempotent.

## 29. PR-D Review

Après deux boucles contradictoires, R1, R2 et le rôle E concluent PASS. La
matrice wire/mémoire et 17 tests futurs sont ratifiés. Aucun modèle, codec ou
processor outbox n'est présent dans ce lot.

## 30. Public API

Exports ajoutés : `NarrativeFactRuntimeState`, resolver/catalog/results/writer
Fact, et helper Scene condition via le barrel runtime. Les types de résolution
claims sont publics ; leurs constructeurs restent contrôlés par l'index.

## 31. Generated Files

Les generated `GameState` et `SaveData` ont été régénérés. Aucun autre modèle
généré n'a dérivé. Second passage build_runner : succès, `0 outputs` écrits ;
warning non bloquant analyzer language `3.9` vs SDK `3.12`.

## 32. Tests ciblés

```text
PR-A core       : 48 PASS
PR-A runtime    : 6 PASS
PR-B core       : 21 PASS
PR-B gameplay   : 23 PASS
PR-B runtime    : 24 PASS
PR-C core       : 113 PASS
Runtime cumulé  : 36 PASS
Host smoke      : 4 PASS
Performance     : 1 PASS
```

## 33. Tests cumulés

```text
map_core complet       : 2953 PASS
map_gameplay complet   : 245 PASS
map_runtime ciblé      : 36 PASS
map_runtime complet    : 1556 PASS, 1 SKIP, 45 FAIL
runtime non-Selbrume   : 140 files, 1402 PASS
host smoke             : 4 PASS
```

Les 45 erreurs complètes ont toutes la même cause racine :
`Invalid argument(s): v2 is not one of the supported values: v1` en lisant le
`selbrume/project.json` concurrent. La liste exacte est dans l'Evidence Pack.

## 34. Analyze/build

```text
map_core dart analyze                  : No issues found
map_gameplay dart analyze              : No issues found
map_runtime flutter analyze            : 348 infos, exit 1 avec fatal-infos
map_runtime --no-fatal-infos            : exit 0, aucune warning/error
map_core build_runner, second passage  : success, 0 outputs
host flutter build macos --debug       : PASS
  build/macos/Build/Products/Debug/playable_runtime_host.app
```

Les 348 infos runtime sont une dette de lint existante, sans warning/error et
hors scope. Aucun build map_editor n'était demandé ni pertinent.

## 35. Performance

Machine : MacBook Pro `MacBookPro18,3`, Apple M1 Pro 10 cœurs, 32 Go, macOS
27.0 build 26A5378j. Dart 3.12.1 stable macOS arm64, JIT ; AOT non mesuré.

| Opération | Volume | moyenne µs | médiane µs | p95 µs |
|---|---:|---:|---:|---:|
| resolver override | 1 | 0.214 | 0.183 | 0.526 |
| resolver override | 100 | 0.051 | 0.048 | 0.072 |
| resolver override | 1 000 | 0.068 | 0.067 | 0.076 |
| resolver override | 10 000 | 0.083 | 0.079 | 0.117 |
| resolver alias | 10 000 | 0.085 | 0.083 | 0.095 |
| resolver default | 10 000 | 0.087 | 0.085 | 0.092 |
| resolver absent | 10 000 | 0.024 | 0.024 | 0.025 |
| codec round-trip | 0 | 0.999 | 0.790 | 1.780 |
| codec round-trip | 100 | 40.135 | 35.000 | 52.400 |
| codec round-trip | 10 000 | 4022.000 | 3769.000 | 5751.000 |
| claim valide | 0 | 2.532 | 2.150 | 4.900 |
| claim valide | 100 | 541.600 | 500.500 | 946.000 |
| claim valide | 10 000 | 20842.857 | 21139.000 | 25317.000 |
| tombstone local | 10 000 | 28249.857 | 23859.000 | 49924.000 |
| collision globale | 10 000 | 30634.000 | 29800.000 | 33662.000 |

Resolver : index O(n), lookup O(1). Codec : O(k log k) pour le tri stable.
Claim index : O(records + claims + targets), avec tri supplémentaire des
conflits. 30 itérations x batch 1000 pour resolver ; codec 30/20/7 ; claims
20/20/7. Aucun seuil flaky ni cache global mutable.

## 36. Scope final

Fichiers du lot : deux docs normatifs, `map_core`, `map_gameplay`, `map_runtime`,
tests et deux rapports. Aucun `map_editor`, `map_battle`, asset, source host,
bridge, UI, migration ou donnée projet n'a été modifié par ce lot.

Le worktree partagé contient néanmoins le lock editor préexistant et des
changements Selbrume apparus pendant l'exécution. Leurs hashes et leur statut
sont isolés dans l'Evidence Pack ; ils ne sont ni revendiqués ni nettoyés.

## 37. Risques résiduels

1. La suite runtime complète doit être relancée après convergence du chantier
   concurrent `ProjectSchemaVersion.v2`.
2. Le fallback raw face à un catalogue Fact ambigu mérite un test de
   caractérisation supplémentaire, sans impact production valide actuel.
3. F1 doit réellement implémenter et tester les 17 cas outbox ; ce lot ne fait
   que ratifier leur contrat.
4. La garantie exactly-once externe reste volontairement hors V0.

## 38. F1 Reopening Gate

Tous les critères fonctionnels propres au prérequis sont prouvés : false
explicite persistant, consumers alignés, collision-safe, claims corpus-aware,
tombstones locaux, global conflicts bloquants et contrat outbox accepté. Aucun
planner prématuré n'existe. F1 est READY pour V2-17/V2-18 ; F1 n'est pas CLOSED.
F2 reste PLANNED / NOT READY.

## 39. Auto-review

Le changement est large parce qu'il ferme trois blockers transverses, mais les
frontières restent celles du prompt. Les principales vigilances ont été la
propagation de l'état Fact dans tous les codecs, l'absence de second resolver,
la preuve corpus obligatoire et la séparation contract/implementation outbox.

Le choix registry-only fail-closed avec claims est plus strict que le
comportement historique, mais il empêche précisément un runtime de confondre
structure plausible et readiness prouvée. Les projections structurelles restent
disponibles ; les résolutions runtime refusent l'absence d'evidence.

## 40. Review contradictoire

R1 a cherché les pertes d'override, divergences de readers, writes legacy-only,
double dispatch et confusion conflit/tombstone. R2 a cherché migration eager,
drop orphelin, mutation consumed IDs, raw flags requalifiés, roadmap mensongère
et save/load regressé. Les blockers initiaux PR-B, PR-C et PR-D ont été corrigés,
puis les deux reviewers ont rendu PASS sur l'arbre final.

## 41. Critique du prompt

Le prompt est précis et a correctement séparé prérequis et F1. Deux tensions ont
été arbitrées : `codex_rule.md` demande un maximum de commentaires, tandis que
le prompt interdit tout nouveau commentaire de code ; l'instruction directe,
plus prioritaire, a été respectée. Les seuls commentaires ajoutés visibles dans
le diff sont des ignores générés automatiquement par Freezed.

La formule PR-C littérale ne mentionnait pas la preuve corpus découverte par la
review. Déclarer `canRunDualRead` depuis le registry seul aurait menti. L'API a
donc été étendue avec `LegacyClaimRuntimeEvidence`, conformément à l'objectif
runtime readiness, sans modifier le wire claims.

Enfin, exiger une suite complète verte tout en interdisant Selbrume devient
impossible quand une autre conversation change ce fichier pendant le lot. La
réponse la plus sûre a été de ne pas le restaurer et de produire une isolation
reproductible des 45 erreurs plus une suite non-Selbrume verte.

## 42. Verdict

```text
F1-PREREQ : CLOSED
PR-0 — Contract Ratification : PASS
PR-A — Fact Runtime Domain & Persistence : PASS
PR-B — Canonical Production Alignment : PASS
PR-C — Dual-Read Runtime Readiness : PASS
PR-D — Outbox Contract Closure : PASS
PHASE F1 : READY
PHASE F2 : NOT READY
```

Réserve : le worktree partagé ne permet pas d'affirmer que la suite runtime
globale est verte tant que le projet Selbrume v2 concurrent n'est pas pris en
charge. Cette réserve n'est pas une régression du lot F1-PREREQ et ne justifie
aucune modification hors scope.
````

## Annexe 15 — Contenu complet final du rapport principal après clôture PR-B

````markdown
# NS-EVENT-V2 — F1-PREREQ — Canonical Fact Runtime Semantics, Dual-Read Readiness & Outbox Contract Closure V0

## 1. Résumé exécutif

```text
F1-PREREQ : CLOSED

PR-0 : PASS
PR-A : PASS
PR-B : PASS
PR-C : PASS
PR-D : PASS

default true -> explicit false : PASS
World Rules canonical Fact : PASS
Scene condition canonical Fact : PASS
Fact save/reload : PASS
canEnterDualRead : PASS
canRunDualRead : PASS
typed tombstones : PASS
outbox contract : PASS

F1 implementation added : NO
Production source bridge added : NO
Real project data modified by this lot : NO

Phase F1 : READY
Phase F2 : NOT READY
```

Le lot ajoute un état runtime Fact explicite et persistant, un resolver et un
writer partagés, l'alignement des quatre familles de consommateurs canoniques,
et une readiness dual-read qui distingue les conflits globaux des tombstones
locaux. Il ratifie aussi le contrat outbox strict-wire/defensive-memory sans
implémenter l'outbox.

La suite runtime complète n'est pas verte dans le worktree partagé : 45 tests
Selbrume échouent parce qu'une autre conversation a changé
`selbrume/project.json` vers `ProjectSchemaVersion.v2`, alors que ce runtime
courant ne décode que `v1`. Le fichier était propre au Gate 0 et n'a pas été
touché par ce lot. Les 112 fichiers de test sans référence textuelle à Selbrume
passent avec 1102 tests, les 39 tests runtime ciblés passent, et le host macOS
build. Cette réserve concurrente est conservée honnêtement sans élargir le
scope interdit.

## 2. Baseline et Blocker F1

- HEAD de départ : `a2ee6bbdb67389336452c5431e523f179a481335`.
- Commit : `docs(event-v2): report NS-EVENT-V2 Phase F1 blocker`.
- Dernière baseline production : `5bf62901d1071d3e17553baef016e4da3b733892`.
- Cause du STOP F1-0 : sémantique Fact divergente, readiness claims sans preuve
  corpus et contradiction overlap outbox non ratifiée.
- Les deux rapports historiques F1 ont été conservés sans réécriture.

## 3. Usage MCP Dart

Le MCP Dart n'était pas disponible dans les outils de cette session. Aucun
usage MCP n'est revendiqué. La compensation a utilisé `rg`, lectures ciblées,
tests Dart/Flutter, analyses, build_runner, build macOS et reviews indépendantes.

## 4. Sous-agents et incidents

| Rôle | Mission | Verdict |
|---|---|---|
| A | Fact Domain & Save Codec | PASS |
| B | Fact Resolver & Writer | PASS |
| C | Production Consumers | PASS après fermeture du faux fallback raw |
| D | Dual-Read Contract | PASS après fermeture de la preuve corpus |
| E | Outbox Contract | PASS après correction des frontières de crash |
| F | Save/Load & Compatibility | PASS |
| G | Tests, Docs & F1 Reopening | PASS après reprise orchestrateur |
| R1 | Runtime Integrity | PASS PR-A/B/C/D |
| R2 | Compatibility Truthfulness | PASS PR-A/B/C/D |
| Orchestrateur | intégration, arbitrage et preuves finales | PASS avec réserve runtime concurrente |

Incident G : le rôle, pourtant assigné en lecture seule, a créé le benchmark et
modifié le codec/tests PR-C. Il a été interrompu. L'orchestrateur a audité les
quatre fichiers, repris ou corrigé chaque changement, puis relancé les tests. Le
benchmark utile a été adopté. Aucun incident n'a réduit les critères.

Incident PR-B : R2 a identifié qu'un contexte Fact global requalifiait aussi
les pages legacy non marquées. La correction rend le contexte page-scoped via
`EventPageResolver.contextForPage` et l'active seulement pour une provenance
Event Builder reconnue. Le schema courant et le legacy `reusePolicy` valide
sont acceptés ; un schema futur, malformed ou absent sans marqueur reste raw.
Les deux reviewers ont ensuite rendu PASS sans blocker.

Incident tooling : une commande de test a d'abord nommé un fichier inexistant,
puis le bon test gameplay a passé. Une invocation Flutter via le SDK FVM stable,
incompatible avec le package config beta du repo, a aussi été arrêtée ; toutes
les validations Flutter finales utilisent `/opt/homebrew/share/flutter/bin`.

Incident PR-D : une première review a demandé des champs d'enveloppe étrangers
au modèle canonique exact. Ce finding a été rejeté avec preuve de la spec F1.
Les remarques pertinentes ont conduit à définir `deliveryId` comme identité
stable, puis à corriger une vraie ambiguïté entre pending durable et création
jamais sauvegardée. Les reviews finales concluent PASS.

## 5. Gate 0

```text
pwd
/Users/karim/Project/pokemonProject

git branch --show-current
main

git status --short --untracked-files=all
 M packages/map_editor/pubspec.lock

git diff --stat
 packages/map_editor/pubspec.lock | 16 ++++++++--------
 1 file changed, 8 insertions(+), 8 deletions(-)

git diff --name-only
packages/map_editor/pubspec.lock
```

Le lock editor préexistant avait et conserve le SHA-256
`a6646437ad4410fa4859f0f8007b0b9589888febc0c6df8b165d7681a9ab52dc`.

`dart pub deps` dans `map_gameplay` a signalé le lock/package config stale.
Le `dart pub get` explicitement autorisé a ajouté uniquement les transitives
`uuid 4.5.3` et `fixnum 1.1.1`, nécessaires au `map_core` courant. Hash lock :
`83b13b3f...` -> `ef1601ab...`. Les deux fichiers `.dart_tool` déjà suivis ont
été rafraîchis en cohérence avec ce lock.

Baselines avant code : `map_core` 42 tests PASS + analyze PASS ;
`map_gameplay` 25 tests PASS + analyze PASS ; `map_runtime` 16 tests PASS.

## 6. PR-0 Contract Ratification

Trois addenda `Accepted` ont été ajoutés sans réécrire les ADR historiques :

- `ADR-EV2-012-A — Canonical Fact Runtime Overrides & Resolution` ;
- `ADR-EV2-008-A — Dual-Read Entry Gate vs Runtime Readiness` ;
- `ADR-EV2-014-A — Strict Outbox Wire Invariant & Defensive Runtime Guard`.

Les matrices Facts, dual-read et outbox sont explicites. Les passes architecture
et compatibilité ont conclu PASS avant PR-A.

## 7. Fact Semantic Decision

La valeur canonique suit exactement : override explicite par `fact.id`, puis
runtime key legacy active, puis `defaultValue`. Une valeur false explicite ne
disparaît jamais quand elle égale le default courant.

## 8. Fact Runtime State

`NarrativeFactRuntimeState` expose une map immuable
`overridesByFactId: Map<String, bool>`. Il valide les IDs non vides et
trim-exacts, copie défensivement les entrées et possède equality/hash stable.

## 9. Wire Format

```json
{
  "overridesByFactId": {
    "fact_gate_open": false,
    "fact_rival_defeated": true
  }
}
```

Les clés sont triées lexicalement. Les valeurs non booléennes, sous-arbres
invalides, IDs vides ou non trim-exacts sont rejetés sans normalisation.

## 10. Old Save Compatibility

L'absence du sous-arbre dans `GameState` ou `SaveData` produit l'état vide. Les
story flags ne sont pas transformés en overrides au load. Les overrides
orphelins sont conservés et jamais rapprochés par label/alias.

## 11. Runtime Key Collision Policy

Le catalogue détecte : duplicate Fact ID, duplicate alias, alias égal à l'ID
d'un autre Fact et duplicate runtime key. Une ambiguïté retourne un résultat
typé et bloque les consommateurs canoniques ; aucun premier gagnant.

## 12. Canonical Resolver

`NarrativeFactRuntimeResolver` construit un index immuable en O(n), puis résout
en lookup O(1). Les résultats sont typés : valeur résolue et source,
`unknownFact`, `ambiguousFact` ou `invalidRuntimeKey`.

## 13. Canonical Writer

`writeNarrativeFactRuntimeValue` écrit toujours l'override, synchronise le
runtime key legacy dans `StoryFlags`, conserve les autres champs et ne touche
jamais `consumedEventIds`. Un rejet retourne l'état original et une raison
stable.

## 14. World Rules Alignment

`projectWorldRuleEffects` et les diagnostics utilisent le resolver partagé.
Le cas `default true + override false` projette false. Les catalogues ambigus
restent fail-closed et diagnostiqués.

## 15. Scene Consequence Alignment

`SceneConsequenceRuntimeWriter` délègue `setFact` au writer partagé. Le commit
multi-conséquences reste atomique : une écriture Fact rejetée annule le lot.

## 16. Scene Condition Alignment

`SceneConditionSourceKind.fact` est résolu par le helper partagé avec les
opérateurs `isTrue`, `isFalse` et `equals bool`. `factLikeStoryFlag` reste un
flag brut legacy.

## 17. ScriptCondition Compatibility

`ScriptEvaluationContext` accepte un contexte Fact canonique optionnel.
`flagIsSet/flagIsUnset` ciblant un Fact utilisent le resolver ; sans contexte,
le comportement raw historique est inchangé. `EventPageResolver` accepte un
`contextForPage` afin de décider cette qualification pour chaque page.

`PlayableMapGame` fournit le contexte canonique uniquement si
`hasEventBuilderPageProvenance(page)` reconnaît le schema Event Builder courant
ou, pour les anciennes pages sans schema, un `reusePolicy` historique valide.
La présence d'un schema futur ou malformed interdit expressément le fallback
legacy. Une page non marquée qui utilise par hasard le même nom qu'un Fact reste
donc un flag brut, ce qui ferme le faux correctif détecté par R2.

## 18. Cross-Consumer Matrix

| Cas | Resolver | World Rule | Scene Fact | Script contextuel |
|---|---:|---:|---:|---:|
| default false, rien | false | false | false | false |
| default true, rien | true | true | true | true |
| alias actif | true | true | true | true |
| override false | false | false | false | false |
| alias + override false | false | false | false | false |
| override true | true | true | true | true |

Les tests de frontière page-scoped prouvent en plus : provenance schema
courante canonicalisée, provenance legacy `reusePolicy` canonicalisée, page
non marquée conservée raw, et schema futur conservé raw même avec un
`reusePolicy` par ailleurs valide.

## 19. Save/Reload Evidence

Le chemin `default true -> setFact(false) -> save -> reload` reste false. Le
round-trip disque conserve true, false et override orphelin. Une ancienne save
sans champ charge un état vide. `consumedEventIds` et story flags simples restent
inchangés au load.

## 20. PR-A Review

R1 et R2 : PASS. Gate final PR-A : 48 tests core PASS, 6 tests runtime PASS,
analyze core PASS, format PASS et build_runner PASS.

## 21. PR-B Review

R1 et R2 : PASS. Gate final PR-B : 21 tests core PASS, 23 tests gameplay PASS,
27 tests runtime PASS. La clôture de compatibilité ajoute 13 tests core de
provenance et 1 test editor historique ; analyses sans erreur.

## 22. Dual-Read Entry Gate

`canStartDualRead` reste l'alias strict de `canEnterDualRead`. Avec claims, le
builder registry-only sans evidence runtime reste fail-closed. L'entrée exige
absence de conflit global, absence de tombstone local et preuve corpus validée.

## 23. Runtime Readiness

`canRunDualRead` exige absence de conflit global et evidence runtime validée.
Les tombstones locaux n'arrêtent pas les autres sources. Une collision globale
de cohorte/source/provenance bloque toute résolution runtime.

## 24. Typed Source Tombstones

`resolveSource` retourne une union fermée `absent`, `valid` ou `tombstone`.
Le tombstone conserve source, claim/cohort quand disponibles et diagnostics
stables/immuables. Aucun null ambigu.

## 25. Typed Provenance Tombstones

`resolveProvenance` expose les mêmes variantes pour `LegacySourceRef`. Une
source et sa provenance valides doivent pointer la même cohorte ; la divergence
échoue pendant la préparation.

## 26. Claim Compatibility

Le codec registry, le JSON claims, fingerprints, receipts, plans et règles de
création de claims sont inchangés. La preuve corpus est fournie séparément via
`LegacyClaimRuntimeEvidence`. Les claims sans preuve ne sont pas déclarés
runtime-ready.

## 27. PR-C Review

Le premier R2 a bloqué la validation registry-only, qui pouvait présenter un
fingerprint stale comme valide. La correction a ajouté le builder corpus-aware,
les diagnostics typed tombstones et les gates fail-closed. Reviews finales R1
et R2 : PASS. Gate PR-C : 113 tests PASS, analyze PASS.

## 28. Outbox Contract Closure

`deliveryId` est l'identité stable d'une commande logique et sa clé
d'idempotence ; aucun `dispatchId` secondaire n'est inventé. Wire et
constructeurs futurs rejetteront overlap pending/delivered et duplicate pending.
Une incohérence mémoire overlap est terminalisée sans dispatch, sans tentative
ni enfant, avec `dataInconsistency` ; le decode ne la répare jamais.

Les frontières de crash distinguent : création jamais sauvegardée (delivery et
effets producteur absents après reload), pending déjà durable (même ID restauré)
et terminal delivered durable (aucun replay). L'exactly-once d'un effet externe
hors commit `GameState` reste hors garantie V0 et exige un protocole idempotent.

## 29. PR-D Review

Après deux boucles contradictoires, R1, R2 et le rôle E concluent PASS. La
matrice wire/mémoire et 17 tests futurs sont ratifiés. Aucun modèle, codec ou
processor outbox n'est présent dans ce lot.

## 30. Public API

Exports ajoutés : `NarrativeFactRuntimeState`, resolver/catalog/results/writer
Fact, et helper Scene condition via le barrel runtime. Les types de résolution
claims sont publics ; leurs constructeurs restent contrôlés par l'index.

## 31. Generated Files

Les generated `GameState` et `SaveData` ont été régénérés. Aucun autre modèle
généré n'a dérivé. Second passage build_runner : succès, `0 outputs` écrits ;
warning non bloquant analyzer language `3.9` vs SDK `3.12`.

## 32. Tests ciblés

```text
PR-A core       : 48 PASS
PR-A runtime    : 6 PASS
PR-B core       : 21 PASS
PR-B gameplay   : 23 PASS
PR-B runtime    : 27 PASS
Provenance core : 13 PASS
Editor legacy   : 1 PASS
PR-C core       : 113 PASS
Runtime cumulé  : 39 PASS
Host smoke      : 4 PASS
Performance     : 1 PASS
```

## 33. Tests cumulés

```text
map_core complet       : 2955 PASS
map_gameplay complet   : 245 PASS
map_runtime ciblé      : 39 PASS
map_runtime complet    : 1559 PASS, 1 SKIP, 45 FAIL
runtime non-Selbrume   : 112 files, 1102 PASS
host smoke             : 4 PASS
```

Les 45 erreurs complètes ont toutes la même cause racine :
`Invalid argument(s): v2 is not one of the supported values: v1` en lisant le
`selbrume/project.json` concurrent. La liste exacte est dans l'Evidence Pack.

## 34. Analyze/build

```text
map_core dart analyze                  : No issues found
map_gameplay dart analyze              : No issues found
map_runtime analyze ciblé final, 2 items: No issues found
map_runtime flutter analyze            : 348 infos, exit 1 avec fatal-infos
map_runtime --no-fatal-infos            : exit 0, aucune warning/error
map_core build_runner, second passage  : success, 0 outputs
host flutter build macos --debug       : PASS
  build/macos/Build/Products/Debug/playable_runtime_host.app
```

Les 348 infos runtime sont une dette de lint existante, sans warning/error et
hors scope. Aucun build map_editor n'était demandé ni pertinent.

## 35. Performance

Machine : MacBook Pro `MacBookPro18,3`, Apple M1 Pro 10 cœurs, 32 Go, macOS
27.0 build 26A5378j. Dart 3.12.1 stable macOS arm64, JIT ; AOT non mesuré.

| Opération | Volume | moyenne µs | médiane µs | p95 µs |
|---|---:|---:|---:|---:|
| resolver override | 1 | 0.214 | 0.183 | 0.526 |
| resolver override | 100 | 0.051 | 0.048 | 0.072 |
| resolver override | 1 000 | 0.068 | 0.067 | 0.076 |
| resolver override | 10 000 | 0.083 | 0.079 | 0.117 |
| resolver alias | 10 000 | 0.085 | 0.083 | 0.095 |
| resolver default | 10 000 | 0.087 | 0.085 | 0.092 |
| resolver absent | 10 000 | 0.024 | 0.024 | 0.025 |
| codec round-trip | 0 | 0.999 | 0.790 | 1.780 |
| codec round-trip | 100 | 40.135 | 35.000 | 52.400 |
| codec round-trip | 10 000 | 4022.000 | 3769.000 | 5751.000 |
| claim valide | 0 | 2.532 | 2.150 | 4.900 |
| claim valide | 100 | 541.600 | 500.500 | 946.000 |
| claim valide | 10 000 | 20842.857 | 21139.000 | 25317.000 |
| tombstone local | 10 000 | 28249.857 | 23859.000 | 49924.000 |
| collision globale | 10 000 | 30634.000 | 29800.000 | 33662.000 |

Resolver : index O(n), lookup O(1). Codec : O(k log k) pour le tri stable.
Claim index : O(records + claims + targets), avec tri supplémentaire des
conflits. 30 itérations x batch 1000 pour resolver ; codec 30/20/7 ; claims
20/20/7. Aucun seuil flaky ni cache global mutable.

## 36. Scope final

```text
 M "MVP Selbrume/event_builder_v2_architecture_decisions.md"
 M "MVP Selbrume/road_map_event_builder_v2.md"
 M packages/map_core/lib/map_core.dart
 M packages/map_core/lib/src/authoring/event_builder_contract.dart
 M packages/map_core/lib/src/diagnostics/scene_diagnostics.dart
 M packages/map_core/lib/src/diagnostics/world_rule_diagnostics.dart
 M packages/map_core/lib/src/models/game_state.dart
 M packages/map_core/lib/src/models/game_state.freezed.dart
 M packages/map_core/lib/src/models/game_state.g.dart
 M packages/map_core/lib/src/models/save_data.dart
 M packages/map_core/lib/src/models/save_data.freezed.dart
 M packages/map_core/lib/src/models/save_data.g.dart
 M packages/map_core/lib/src/operations/game_state_persistence.dart
 M packages/map_core/lib/src/operations/narrative_event_registry_codec.dart
 M packages/map_core/lib/src/projection/world_rule_projection.dart
 M packages/map_core/lib/src/validation/validators.dart
 M packages/map_core/test/event_builder_authoring_operations_test.dart
 M packages/map_core/test/game_state_persistence_test.dart
 M packages/map_core/test/narrative_event_registry_test.dart
 M packages/map_core/test/save_data_test.dart
 M packages/map_core/test/scene_diagnostics_test.dart
 M packages/map_core/test/world_rule_projection_test.dart
 M packages/map_editor/pubspec.lock
 M packages/map_gameplay/.dart_tool/package_config.json
 M packages/map_gameplay/.dart_tool/package_graph.json
 M packages/map_gameplay/lib/src/event_page_resolver.dart
 M packages/map_gameplay/lib/src/new_game_state_builder.dart
 M packages/map_gameplay/lib/src/script_condition_evaluator.dart
 M packages/map_gameplay/pubspec.lock
 M packages/map_gameplay/test/new_game_state_builder_test.dart
 M packages/map_runtime/lib/map_runtime.dart
 M packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_write_result.dart
 M packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_writer.dart
 M packages/map_runtime/lib/src/infrastructure/file_game_save_repository.dart
 M packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
 M packages/map_runtime/test/scene_consequence_runtime_writer_test.dart
 M selbrume/project.json
?? packages/map_core/lib/src/models/narrative_fact_runtime_state.dart
?? packages/map_core/lib/src/operations/narrative_fact_runtime.dart
?? packages/map_core/test/narrative_fact_runtime_performance_test.dart
?? packages/map_core/test/narrative_fact_runtime_resolver_test.dart
?? packages/map_core/test/narrative_fact_runtime_state_test.dart
?? packages/map_core/test/narrative_fact_runtime_writer_test.dart
?? packages/map_core/test/project_validator_test.dart
?? packages/map_core/test/validated_legacy_claim_index_runtime_readiness_test.dart
?? packages/map_gameplay/test/narrative_fact_script_condition_test.dart
?? packages/map_runtime/lib/src/application/scene_runtime/scene_fact_condition_runtime_resolver.dart
?? packages/map_runtime/test/narrative_fact_runtime_cross_consumer_test.dart
?? packages/map_runtime/test/narrative_fact_runtime_save_load_test.dart
?? reports/narrativeStudio/events/ns_event_v2_f1_prereq_canonical_fact_runtime_closure_v0.md
?? reports/narrativeStudio/events/ns_event_v2_f1_prereq_evidence_pack.md
?? selbrume/assets/borders/snapshots/b9a77cfa1bf35d89d0854b7c180f974b1400474cc27e05db0d9ee93f82b5b38a/frame_0000.png
?? selbrume/assets/borders/snapshots/d12d89c830a4e1f88038afc8e868282ca24d8a1dfc42505b7e3593cc97ea95c0/frame_0000.png
?? selbrume/assets/borders/snapshots/f7dff67260a8197d15f892ecca9b8099cadb1f4c24176b4c64246c48e719e3c9/frame_0000.png
?? selbrume/assets/borders/snapshots/ff1052a8600830f40d9e04e5dce67d879962e567481f832e26249e4706d4d779/frame_0000.png
```

`git diff --check` : vide. Anti-scope :

```text
packages/map_editor/pubspec.lock
selbrume/project.json
```

Le premier est le drift préexistant hashé au Gate 0 ; le second et les quatre
snapshots Selbrume sont des changements concurrents apparus pendant le lot.


Fichiers du lot : deux docs normatifs, `map_core`, `map_gameplay`, `map_runtime`,
tests et deux rapports. Aucun `map_editor`, `map_battle`, asset, source host,
bridge, UI, migration ou donnée projet n'a été modifié par ce lot.

Le worktree partagé contient néanmoins le lock editor préexistant et des
changements Selbrume apparus pendant l'exécution. Leurs hashes et leur statut
sont isolés dans l'Evidence Pack ; ils ne sont ni revendiqués ni nettoyés.

## 37. Risques résiduels

1. La suite runtime complète doit être relancée après convergence du chantier
   concurrent `ProjectSchemaVersion.v2`.
2. Les pages legacy sans marqueur Event Builder restent volontairement raw ;
   toute future extension de provenance devra conserver le refus des schemas
   inconnus et être accompagnée d'une preuve de compatibilité.
3. F1 doit réellement implémenter et tester les 17 cas outbox ; ce lot ne fait
   que ratifier leur contrat.
4. La garantie exactly-once externe reste volontairement hors V0.

## 38. F1 Reopening Gate

Tous les critères fonctionnels propres au prérequis sont prouvés : false
explicite persistant, consumers alignés, collision-safe, claims corpus-aware,
tombstones locaux, global conflicts bloquants et contrat outbox accepté. Aucun
planner prématuré n'existe. F1 est READY pour V2-17/V2-18 ; F1 n'est pas CLOSED.
F2 reste PLANNED / NOT READY.

## 39. Auto-review

Le changement est large parce qu'il ferme trois blockers transverses, mais les
frontières restent celles du prompt. Les principales vigilances ont été la
propagation de l'état Fact dans tous les codecs, l'absence de second resolver,
la preuve corpus obligatoire et la séparation contract/implementation outbox.

Le choix registry-only fail-closed avec claims est plus strict que le
comportement historique, mais il empêche précisément un runtime de confondre
structure plausible et readiness prouvée. Les projections structurelles restent
disponibles ; les résolutions runtime refusent l'absence d'evidence.

La première intégration PR-B était trop large : disposer d'un registry Fact ne
suffit pas à prouver qu'une condition de page legacy vise ce Fact. Le contexte
par page et la provenance stricte restaurent le comportement raw historique
sans réduire la sémantique canonique des pages réellement issues du builder.

## 40. Review contradictoire

R1 a cherché les pertes d'override, divergences de readers, writes legacy-only,
double dispatch et confusion conflit/tombstone. R2 a cherché migration eager,
drop orphelin, mutation consumed IDs, raw flags requalifiés, roadmap mensongère
et save/load regressé. R2 a effectivement trouvé la requalification trop large
des pages non marquées ; après `contextForPage`, détection de provenance stricte
et matrices current/legacy/absent/future, R1 et R2 ont rendu PASS sans blocker
sur l'arbre final.

## 41. Critique du prompt

Le prompt est précis et a correctement séparé prérequis et F1. Deux tensions ont
été arbitrées : `codex_rule.md` demande un maximum de commentaires, tandis que
le prompt interdit tout nouveau commentaire de code ; l'instruction directe,
plus prioritaire, a été respectée. Les seuls commentaires ajoutés visibles dans
le diff sont des ignores générés automatiquement par Freezed.

La formule PR-C littérale ne mentionnait pas la preuve corpus découverte par la
review. Déclarer `canRunDualRead` depuis le registry seul aurait menti. L'API a
donc été étendue avec `LegacyClaimRuntimeEvidence`, conformément à l'objectif
runtime readiness, sans modifier le wire claims.

Enfin, exiger une suite complète verte tout en interdisant Selbrume devient
impossible quand une autre conversation change ce fichier pendant le lot. La
réponse la plus sûre a été de ne pas le restaurer et de produire une isolation
reproductible des 45 erreurs plus une suite non-Selbrume verte.

## 42. Verdict

```text
F1-PREREQ : CLOSED
PR-0 — Contract Ratification : PASS
PR-A — Fact Runtime Domain & Persistence : PASS
PR-B — Canonical Production Alignment : PASS
PR-C — Dual-Read Runtime Readiness : PASS
PR-D — Outbox Contract Closure : PASS
PHASE F1 : READY
PHASE F2 : NOT READY
```

Réserve : le worktree partagé ne permet pas d'affirmer que la suite runtime
globale est verte tant que le projet Selbrume v2 concurrent n'est pas pris en
charge. Cette réserve n'est pas une régression du lot F1-PREREQ et ne justifie
aucune modification hors scope.
````

## Annexe 16 — Contenu complet final de `packages/map_runtime/test/narrative_fact_runtime_cross_consumer_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  group('Narrative Fact runtime cross consumer matrix', () {
    for (final testCase in _cases()) {
      test(testCase.name, () {
        final resolver =
            NarrativeFactRuntimeResolver.fromFacts([testCase.fact]);
        final direct = resolver.resolve(
          factId: testCase.fact.id,
          runtimeState: testCase.state.narrativeFactRuntimeState,
          storyFlags: testCase.state.storyFlags,
        ) as NarrativeFactRuntimeResolved;
        final project = _project(testCase.fact);
        final worldRule = projectWorldRuleEffects(
          project,
          testCase.state,
          maps: const [_map],
          mapId: 'map_test',
        );
        final sceneCondition = evaluateCanonicalNarrativeFactSceneCondition(
          source: SceneConditionSource(
            sourceKind: SceneConditionSourceKind.fact,
            sourceId: testCase.fact.id,
            operator: SceneConditionOperator.isTrue,
          ),
          gameState: testCase.state,
          resolver: resolver,
        );
        final scriptCondition = const ScriptConditionEvaluator().evaluate(
          ScriptConditionFactory.flagIsSet(testCase.fact.id),
          testCase.state,
          context: ScriptEvaluationContext(
            narrativeFactResolver: resolver,
          ),
        );

        expect(direct.value, testCase.expected);
        expect(worldRule.isNotEmpty, testCase.expected);
        expect(sceneCondition, testCase.expected);
        expect(scriptCondition, testCase.expected);
      });
    }

    test('supports isFalse and equals boolean operators', () {
      final fact = NarrativeFactDefinition(
        id: 'fact_false',
        label: 'False',
      );
      final resolver = NarrativeFactRuntimeResolver.fromFacts([fact]);
      const state = GameState(saveId: 'scene_operators');

      expect(
        evaluateCanonicalNarrativeFactSceneCondition(
          source: SceneConditionSource(
            sourceKind: SceneConditionSourceKind.fact,
            sourceId: fact.id,
            operator: SceneConditionOperator.isFalse,
          ),
          gameState: state,
          resolver: resolver,
        ),
        isTrue,
      );
      expect(
        evaluateCanonicalNarrativeFactSceneCondition(
          source: SceneConditionSource(
            sourceKind: SceneConditionSourceKind.fact,
            sourceId: fact.id,
            operator: SceneConditionOperator.equals,
            value: 'false',
          ),
          gameState: state,
          resolver: resolver,
        ),
        isTrue,
      );
    });

    test('fails closed for unknown and ambiguous canonical Facts', () {
      const state = GameState(saveId: 'scene_invalid');
      final unknown = NarrativeFactRuntimeResolver.fromFacts(const []);
      final ambiguous = NarrativeFactRuntimeResolver.fromFacts([
        NarrativeFactDefinition(id: 'fact_dup', label: 'A'),
        NarrativeFactDefinition(id: 'fact_dup', label: 'B'),
      ]);

      expect(
        () => evaluateCanonicalNarrativeFactSceneCondition(
          source: SceneConditionSource(
            sourceKind: SceneConditionSourceKind.fact,
            sourceId: 'fact_missing',
            operator: SceneConditionOperator.isTrue,
          ),
          gameState: state,
          resolver: unknown,
        ),
        throwsStateError,
      );
      expect(
        () => evaluateCanonicalNarrativeFactSceneCondition(
          source: SceneConditionSource(
            sourceKind: SceneConditionSourceKind.fact,
            sourceId: 'fact_dup',
            operator: SceneConditionOperator.isTrue,
          ),
          gameState: state,
          resolver: ambiguous,
        ),
        throwsStateError,
      );
    });

    test('EventPageResolver resolves authored Fact bindings canonically', () {
      final fact = NarrativeFactDefinition(
        id: 'fact_page',
        label: 'Page',
        defaultValue: true,
      );
      final resolver = NarrativeFactRuntimeResolver.fromFacts([fact]);
      final state = GameState(
        saveId: 'page_binding',
        narrativeFactRuntimeState: NarrativeFactRuntimeState(
          overridesByFactId: const {'fact_page': false},
        ),
      );
      final event = MapEventDefinition(
        id: 'event_page',
        position: const EventPosition(layerId: 'events', x: 0, y: 0),
        pages: [
          MapEventPage(
            pageNumber: 0,
            condition: ScriptConditionFactory.flagIsSet('fact_page'),
            metadata: const {
              EventBuilderMetadataKeys.schemaVersion:
                  EventBuilderMetadataKeys.currentSchemaVersion,
            },
          ),
          const MapEventPage(pageNumber: 1),
        ],
      );

      final context = ScriptEvaluationContext(narrativeFactResolver: resolver);
      final active = const RuntimeStoryBranching().pageResolver.resolve(
            event,
            state,
            contextForPage: (page) =>
                hasEventBuilderPageProvenance(page) ? context : null,
          );

      expect(active, isNotNull);
      expect(active!.pageIndex, 1);
    });

    test('keeps a colliding legacy MapEvent condition raw', () {
      final resolver = NarrativeFactRuntimeResolver.fromFacts([
        NarrativeFactDefinition(
          id: 'quest_gate',
          label: 'Quest gate',
          legacyFlagName: 'canonical_quest_gate',
        ),
      ]);
      const state = GameState(
        saveId: 'legacy_page_collision',
        storyFlags: StoryFlags(activeFlags: {'quest_gate'}),
      );
      final event = MapEventDefinition(
        id: 'legacy_event',
        position: const EventPosition(layerId: 'events', x: 0, y: 0),
        pages: [
          MapEventPage(
            pageNumber: 0,
            condition: ScriptConditionFactory.flagIsSet('quest_gate'),
          ),
          const MapEventPage(pageNumber: 1),
        ],
      );
      final context = ScriptEvaluationContext(narrativeFactResolver: resolver);

      final active = const RuntimeStoryBranching().pageResolver.resolve(
            event,
            state,
            contextForPage: (page) =>
                hasEventBuilderPageProvenance(page) ? context : null,
          );

      expect(active, isNotNull);
      expect(active!.pageIndex, 0);
    });

    test('resolves legacy Event Builder reuse metadata canonically', () {
      final resolver = NarrativeFactRuntimeResolver.fromFacts([
        NarrativeFactDefinition(
          id: 'fact_started',
          label: 'Started',
        ),
      ]);
      final state = GameState(
        saveId: 'legacy_event_builder_page',
        narrativeFactRuntimeState: NarrativeFactRuntimeState(
          overridesByFactId: const {'fact_started': true},
        ),
      );
      final event = MapEventDefinition(
        id: 'legacy_event_builder_event',
        position: const EventPosition(layerId: 'events', x: 0, y: 0),
        pages: [
          MapEventPage(
            pageNumber: 0,
            condition: ScriptConditionFactory.flagIsSet('fact_started'),
            metadata: const {
              EventBuilderMetadataKeys.reusePolicy: 'oneShot',
            },
          ),
          const MapEventPage(pageNumber: 1),
        ],
      );
      final context = ScriptEvaluationContext(narrativeFactResolver: resolver);

      final active = const RuntimeStoryBranching().pageResolver.resolve(
            event,
            state,
            contextForPage: (page) =>
                hasEventBuilderPageProvenance(page) ? context : null,
          );

      expect(active, isNotNull);
      expect(active!.pageIndex, 0);
    });

    test('keeps a future Event Builder schema raw', () {
      final resolver = NarrativeFactRuntimeResolver.fromFacts([
        NarrativeFactDefinition(
          id: 'future_gate',
          label: 'Future gate',
          legacyFlagName: 'canonical_future_gate',
        ),
      ]);
      const state = GameState(
        saveId: 'future_event_builder_page',
        storyFlags: StoryFlags(activeFlags: {'future_gate'}),
      );
      final event = MapEventDefinition(
        id: 'future_event_builder_event',
        position: const EventPosition(layerId: 'events', x: 0, y: 0),
        pages: [
          MapEventPage(
            pageNumber: 0,
            condition: ScriptConditionFactory.flagIsSet('future_gate'),
            metadata: const {
              EventBuilderMetadataKeys.schemaVersion: '2',
              EventBuilderMetadataKeys.reusePolicy: 'oneShot',
            },
          ),
          const MapEventPage(pageNumber: 1),
        ],
      );
      final context = ScriptEvaluationContext(narrativeFactResolver: resolver);

      final active = const RuntimeStoryBranching().pageResolver.resolve(
            event,
            state,
            contextForPage: (page) =>
                hasEventBuilderPageProvenance(page) ? context : null,
          );

      expect(active, isNotNull);
      expect(active!.pageIndex, 0);
    });
  });
}

List<_FactCase> _cases() {
  return [
    _FactCase(
      name: 'default false without flag or override',
      fact: NarrativeFactDefinition(id: 'fact_matrix', label: 'Matrix'),
      state: const GameState(saveId: 'matrix_default_false'),
      expected: false,
    ),
    _FactCase(
      name: 'default true without flag or override',
      fact: NarrativeFactDefinition(
        id: 'fact_matrix',
        label: 'Matrix',
        defaultValue: true,
      ),
      state: const GameState(saveId: 'matrix_default_true'),
      expected: true,
    ),
    _FactCase(
      name: 'active legacy alias without override',
      fact: NarrativeFactDefinition(
        id: 'fact_matrix',
        label: 'Matrix',
        legacyFlagName: 'legacy_matrix',
      ),
      state: const GameState(
        saveId: 'matrix_alias',
        storyFlags: StoryFlags(activeFlags: {'legacy_matrix'}),
      ),
      expected: true,
    ),
    _FactCase(
      name: 'explicit false overrides a true default',
      fact: NarrativeFactDefinition(
        id: 'fact_matrix',
        label: 'Matrix',
        defaultValue: true,
      ),
      state: GameState(
        saveId: 'matrix_override_false',
        narrativeFactRuntimeState: NarrativeFactRuntimeState(
          overridesByFactId: const {'fact_matrix': false},
        ),
      ),
      expected: false,
    ),
    _FactCase(
      name: 'explicit false overrides an active alias',
      fact: NarrativeFactDefinition(
        id: 'fact_matrix',
        label: 'Matrix',
        legacyFlagName: 'legacy_matrix',
      ),
      state: GameState(
        saveId: 'matrix_alias_override_false',
        storyFlags: const StoryFlags(activeFlags: {'legacy_matrix'}),
        narrativeFactRuntimeState: NarrativeFactRuntimeState(
          overridesByFactId: const {'fact_matrix': false},
        ),
      ),
      expected: false,
    ),
    _FactCase(
      name: 'explicit true overrides a false default',
      fact: NarrativeFactDefinition(id: 'fact_matrix', label: 'Matrix'),
      state: GameState(
        saveId: 'matrix_override_true',
        narrativeFactRuntimeState: NarrativeFactRuntimeState(
          overridesByFactId: const {'fact_matrix': true},
        ),
      ),
      expected: true,
    ),
  ];
}

ProjectManifest _project(NarrativeFactDefinition fact) {
  return ProjectManifest(
    name: 'Cross consumer project',
    maps: const [
      ProjectMapEntry(
        id: 'map_test',
        name: 'Map test',
        relativePath: 'maps/map_test.json',
      ),
    ],
    tilesets: const [],
    facts: [fact],
    worldRules: [
      WorldRuleDefinition(
        id: 'world_rule_fact',
        label: 'Fact rule',
        source: const WorldRuleSource(
          kind: WorldRuleSourceKind.fact,
          sourceId: 'fact_matrix',
          predicate: WorldRuleSourcePredicate.isTrue,
        ),
        target: const WorldRuleTarget(
          kind: WorldRuleTargetKind.mapEntity,
          mapId: 'map_test',
          entityId: 'npc_test',
        ),
        effect: const WorldRuleEffect(
          kind: WorldRuleEffectKind.entityVisible,
        ),
      ),
    ],
  );
}

const _map = MapData(
  id: 'map_test',
  name: 'Map test',
  size: GridSize(width: 4, height: 4),
  entities: [
    MapEntity(
      id: 'npc_test',
      name: 'NPC test',
      kind: MapEntityKind.npc,
      pos: GridPos(x: 1, y: 1),
      npc: MapEntityNpcData(displayName: 'NPC test'),
    ),
  ],
);

final class _FactCase {
  const _FactCase({
    required this.name,
    required this.fact,
    required this.state,
    required this.expected,
  });

  final String name;
  final NarrativeFactDefinition fact;
  final GameState state;
  final bool expected;
}
```
+
## Annexe 14 — Snapshot intermédiaire antérieur du rapport principal

L'annexe 13 est le snapshot avant insertion de l'état Git final. La présente
annexe est la version complète finale et fait foi.

````markdown
# NS-EVENT-V2 — F1-PREREQ — Canonical Fact Runtime Semantics, Dual-Read Readiness & Outbox Contract Closure V0

## 1. Résumé exécutif

```text
F1-PREREQ : CLOSED

PR-0 : PASS
PR-A : PASS
PR-B : PASS
PR-C : PASS
PR-D : PASS

default true -> explicit false : PASS
World Rules canonical Fact : PASS
Scene condition canonical Fact : PASS
Fact save/reload : PASS
canEnterDualRead : PASS
canRunDualRead : PASS
typed tombstones : PASS
outbox contract : PASS

F1 implementation added : NO
Production source bridge added : NO
Real project data modified by this lot : NO

Phase F1 : READY
Phase F2 : NOT READY
```

Le lot ajoute un état runtime Fact explicite et persistant, un resolver et un
writer partagés, l'alignement des quatre familles de consommateurs canoniques,
et une readiness dual-read qui distingue les conflits globaux des tombstones
locaux. Il ratifie aussi le contrat outbox strict-wire/defensive-memory sans
implémenter l'outbox.

La suite runtime complète n'est pas verte dans le worktree partagé : 45 tests
Selbrume échouent parce qu'une autre conversation a changé
`selbrume/project.json` vers `ProjectSchemaVersion.v2`, alors que ce runtime
courant ne décode que `v1`. Le fichier était propre au Gate 0 et n'a pas été
touché par ce lot. Les 140 tests files ne mentionnant pas Selbrume passent avec
1402 tests, les 36 tests runtime ciblés passent, et le host macOS build. Cette
réserve concurrente est conservée honnêtement sans élargir le scope interdit.

## 2. Baseline et Blocker F1

- HEAD de départ : `a2ee6bbdb67389336452c5431e523f179a481335`.
- Commit : `docs(event-v2): report NS-EVENT-V2 Phase F1 blocker`.
- Dernière baseline production : `5bf62901d1071d3e17553baef016e4da3b733892`.
- Cause du STOP F1-0 : sémantique Fact divergente, readiness claims sans preuve
  corpus et contradiction overlap outbox non ratifiée.
- Les deux rapports historiques F1 ont été conservés sans réécriture.

## 3. Usage MCP Dart

Le MCP Dart n'était pas disponible dans les outils de cette session. Aucun
usage MCP n'est revendiqué. La compensation a utilisé `rg`, lectures ciblées,
tests Dart/Flutter, analyses, build_runner, build macOS et reviews indépendantes.

## 4. Sous-agents et incidents

| Rôle | Mission | Verdict |
|---|---|---|
| A | Fact Domain & Save Codec | PASS |
| B | Fact Resolver & Writer | PASS |
| C | Production Consumers | PASS avec réserve raw fallback non bloquante |
| D | Dual-Read Contract | PASS après fermeture de la preuve corpus |
| E | Outbox Contract | PASS après correction des frontières de crash |
| F | Save/Load & Compatibility | PASS |
| G | Tests, Docs & F1 Reopening | PASS après reprise orchestrateur |
| R1 | Runtime Integrity | PASS PR-A/B/C/D |
| R2 | Compatibility Truthfulness | PASS PR-A/B/C/D |
| Orchestrateur | intégration, arbitrage et preuves finales | PASS avec réserve runtime concurrente |

Incident G : le rôle, pourtant assigné en lecture seule, a créé le benchmark et
modifié le codec/tests PR-C. Il a été interrompu. L'orchestrateur a audité les
quatre fichiers, repris ou corrigé chaque changement, puis relancé les tests. Le
benchmark utile a été adopté. Aucun incident n'a réduit les critères.

Incident PR-D : une première review a demandé des champs d'enveloppe étrangers
au modèle canonique exact. Ce finding a été rejeté avec preuve de la spec F1.
Les remarques pertinentes ont conduit à définir `deliveryId` comme identité
stable, puis à corriger une vraie ambiguïté entre pending durable et création
jamais sauvegardée. Les reviews finales concluent PASS.

## 5. Gate 0

```text
pwd
/Users/karim/Project/pokemonProject

git branch --show-current
main

git status --short --untracked-files=all
 M packages/map_editor/pubspec.lock

git diff --stat
 packages/map_editor/pubspec.lock | 16 ++++++++--------
 1 file changed, 8 insertions(+), 8 deletions(-)

git diff --name-only
packages/map_editor/pubspec.lock
```

Le lock editor préexistant avait et conserve le SHA-256
`a6646437ad4410fa4859f0f8007b0b9589888febc0c6df8b165d7681a9ab52dc`.

`dart pub deps` dans `map_gameplay` a signalé le lock/package config stale.
Le `dart pub get` explicitement autorisé a ajouté uniquement les transitives
`uuid 4.5.3` et `fixnum 1.1.1`, nécessaires au `map_core` courant. Hash lock :
`83b13b3f...` -> `ef1601ab...`. Les deux fichiers `.dart_tool` déjà suivis ont
été rafraîchis en cohérence avec ce lock.

Baselines avant code : `map_core` 42 tests PASS + analyze PASS ;
`map_gameplay` 25 tests PASS + analyze PASS ; `map_runtime` 16 tests PASS.

## 6. PR-0 Contract Ratification

Trois addenda `Accepted` ont été ajoutés sans réécrire les ADR historiques :

- `ADR-EV2-012-A — Canonical Fact Runtime Overrides & Resolution` ;
- `ADR-EV2-008-A — Dual-Read Entry Gate vs Runtime Readiness` ;
- `ADR-EV2-014-A — Strict Outbox Wire Invariant & Defensive Runtime Guard`.

Les matrices Facts, dual-read et outbox sont explicites. Les passes architecture
et compatibilité ont conclu PASS avant PR-A.

## 7. Fact Semantic Decision

La valeur canonique suit exactement : override explicite par `fact.id`, puis
runtime key legacy active, puis `defaultValue`. Une valeur false explicite ne
disparaît jamais quand elle égale le default courant.

## 8. Fact Runtime State

`NarrativeFactRuntimeState` expose une map immuable
`overridesByFactId: Map<String, bool>`. Il valide les IDs non vides et
trim-exacts, copie défensivement les entrées et possède equality/hash stable.

## 9. Wire Format

```json
{
  "overridesByFactId": {
    "fact_gate_open": false,
    "fact_rival_defeated": true
  }
}
```

Les clés sont triées lexicalement. Les valeurs non booléennes, sous-arbres
invalides, IDs vides ou non trim-exacts sont rejetés sans normalisation.

## 10. Old Save Compatibility

L'absence du sous-arbre dans `GameState` ou `SaveData` produit l'état vide. Les
story flags ne sont pas transformés en overrides au load. Les overrides
orphelins sont conservés et jamais rapprochés par label/alias.

## 11. Runtime Key Collision Policy

Le catalogue détecte : duplicate Fact ID, duplicate alias, alias égal à l'ID
d'un autre Fact et duplicate runtime key. Une ambiguïté retourne un résultat
typé et bloque les consommateurs canoniques ; aucun premier gagnant.

## 12. Canonical Resolver

`NarrativeFactRuntimeResolver` construit un index immuable en O(n), puis résout
en lookup O(1). Les résultats sont typés : valeur résolue et source,
`unknownFact`, `ambiguousFact` ou `invalidRuntimeKey`.

## 13. Canonical Writer

`writeNarrativeFactRuntimeValue` écrit toujours l'override, synchronise le
runtime key legacy dans `StoryFlags`, conserve les autres champs et ne touche
jamais `consumedEventIds`. Un rejet retourne l'état original et une raison
stable.

## 14. World Rules Alignment

`projectWorldRuleEffects` et les diagnostics utilisent le resolver partagé.
Le cas `default true + override false` projette false. Les catalogues ambigus
restent fail-closed et diagnostiqués.

## 15. Scene Consequence Alignment

`SceneConsequenceRuntimeWriter` délègue `setFact` au writer partagé. Le commit
multi-conséquences reste atomique : une écriture Fact rejetée annule le lot.

## 16. Scene Condition Alignment

`SceneConditionSourceKind.fact` est résolu par le helper partagé avec les
opérateurs `isTrue`, `isFalse` et `equals bool`. `factLikeStoryFlag` reste un
flag brut legacy.

## 17. ScriptCondition Compatibility

`ScriptEvaluationContext` accepte un contexte Fact canonique optionnel.
`flagIsSet/flagIsUnset` ciblant un Fact utilisent le resolver ; sans contexte,
le comportement raw historique est inchangé. `RuntimeStoryBranching` et le
chemin Event Builder V1 fournissent le contexte quand le registry Fact existe.

Réserve non bloquante : un catalogue globalement ambigu fait échouer fermé une
référence contextuelle inconnue avant fallback raw. Le loader production bloque
déjà ces projets invalides ; un test de coexistence supplémentaire reste utile.

## 18. Cross-Consumer Matrix

| Cas | Resolver | World Rule | Scene Fact | Script contextuel |
|---|---:|---:|---:|---:|
| default false, rien | false | false | false | false |
| default true, rien | true | true | true | true |
| alias actif | true | true | true | true |
| override false | false | false | false | false |
| alias + override false | false | false | false | false |
| override true | true | true | true | true |

## 19. Save/Reload Evidence

Le chemin `default true -> setFact(false) -> save -> reload` reste false. Le
round-trip disque conserve true, false et override orphelin. Une ancienne save
sans champ charge un état vide. `consumedEventIds` et story flags simples restent
inchangés au load.

## 20. PR-A Review

R1 et R2 : PASS. Gate final PR-A : 48 tests core PASS, 6 tests runtime PASS,
analyze core PASS, format PASS et build_runner PASS.

## 21. PR-B Review

R1 et R2 : PASS. Gate final PR-B : 21 tests core PASS, 23 tests gameplay PASS,
24 tests runtime PASS ; analyses sans erreur.

## 22. Dual-Read Entry Gate

`canStartDualRead` reste l'alias strict de `canEnterDualRead`. Avec claims, le
builder registry-only sans evidence runtime reste fail-closed. L'entrée exige
absence de conflit global, absence de tombstone local et preuve corpus validée.

## 23. Runtime Readiness

`canRunDualRead` exige absence de conflit global et evidence runtime validée.
Les tombstones locaux n'arrêtent pas les autres sources. Une collision globale
de cohorte/source/provenance bloque toute résolution runtime.

## 24. Typed Source Tombstones

`resolveSource` retourne une union fermée `absent`, `valid` ou `tombstone`.
Le tombstone conserve source, claim/cohort quand disponibles et diagnostics
stables/immuables. Aucun null ambigu.

## 25. Typed Provenance Tombstones

`resolveProvenance` expose les mêmes variantes pour `LegacySourceRef`. Une
source et sa provenance valides doivent pointer la même cohorte ; la divergence
échoue pendant la préparation.

## 26. Claim Compatibility

Le codec registry, le JSON claims, fingerprints, receipts, plans et règles de
création de claims sont inchangés. La preuve corpus est fournie séparément via
`LegacyClaimRuntimeEvidence`. Les claims sans preuve ne sont pas déclarés
runtime-ready.

## 27. PR-C Review

Le premier R2 a bloqué la validation registry-only, qui pouvait présenter un
fingerprint stale comme valide. La correction a ajouté le builder corpus-aware,
les diagnostics typed tombstones et les gates fail-closed. Reviews finales R1
et R2 : PASS. Gate PR-C : 113 tests PASS, analyze PASS.

## 28. Outbox Contract Closure

`deliveryId` est l'identité stable d'une commande logique et sa clé
d'idempotence ; aucun `dispatchId` secondaire n'est inventé. Wire et
constructeurs futurs rejetteront overlap pending/delivered et duplicate pending.
Une incohérence mémoire overlap est terminalisée sans dispatch, sans tentative
ni enfant, avec `dataInconsistency` ; le decode ne la répare jamais.

Les frontières de crash distinguent : création jamais sauvegardée (delivery et
effets producteur absents après reload), pending déjà durable (même ID restauré)
et terminal delivered durable (aucun replay). L'exactly-once d'un effet externe
hors commit `GameState` reste hors garantie V0 et exige un protocole idempotent.

## 29. PR-D Review

Après deux boucles contradictoires, R1, R2 et le rôle E concluent PASS. La
matrice wire/mémoire et 17 tests futurs sont ratifiés. Aucun modèle, codec ou
processor outbox n'est présent dans ce lot.

## 30. Public API

Exports ajoutés : `NarrativeFactRuntimeState`, resolver/catalog/results/writer
Fact, et helper Scene condition via le barrel runtime. Les types de résolution
claims sont publics ; leurs constructeurs restent contrôlés par l'index.

## 31. Generated Files

Les generated `GameState` et `SaveData` ont été régénérés. Aucun autre modèle
généré n'a dérivé. Second passage build_runner : succès, `0 outputs` écrits ;
warning non bloquant analyzer language `3.9` vs SDK `3.12`.

## 32. Tests ciblés

```text
PR-A core       : 48 PASS
PR-A runtime    : 6 PASS
PR-B core       : 21 PASS
PR-B gameplay   : 23 PASS
PR-B runtime    : 24 PASS
PR-C core       : 113 PASS
Runtime cumulé  : 36 PASS
Host smoke      : 4 PASS
Performance     : 1 PASS
```

## 33. Tests cumulés

```text
map_core complet       : 2953 PASS
map_gameplay complet   : 245 PASS
map_runtime ciblé      : 36 PASS
map_runtime complet    : 1556 PASS, 1 SKIP, 45 FAIL
runtime non-Selbrume   : 140 files, 1402 PASS
host smoke             : 4 PASS
```

Les 45 erreurs complètes ont toutes la même cause racine :
`Invalid argument(s): v2 is not one of the supported values: v1` en lisant le
`selbrume/project.json` concurrent. La liste exacte est dans l'Evidence Pack.

## 34. Analyze/build

```text
map_core dart analyze                  : No issues found
map_gameplay dart analyze              : No issues found
map_runtime flutter analyze            : 348 infos, exit 1 avec fatal-infos
map_runtime --no-fatal-infos            : exit 0, aucune warning/error
map_core build_runner, second passage  : success, 0 outputs
host flutter build macos --debug       : PASS
  build/macos/Build/Products/Debug/playable_runtime_host.app
```

Les 348 infos runtime sont une dette de lint existante, sans warning/error et
hors scope. Aucun build map_editor n'était demandé ni pertinent.

## 35. Performance

Machine : MacBook Pro `MacBookPro18,3`, Apple M1 Pro 10 cœurs, 32 Go, macOS
27.0 build 26A5378j. Dart 3.12.1 stable macOS arm64, JIT ; AOT non mesuré.

| Opération | Volume | moyenne µs | médiane µs | p95 µs |
|---|---:|---:|---:|---:|
| resolver override | 1 | 0.214 | 0.183 | 0.526 |
| resolver override | 100 | 0.051 | 0.048 | 0.072 |
| resolver override | 1 000 | 0.068 | 0.067 | 0.076 |
| resolver override | 10 000 | 0.083 | 0.079 | 0.117 |
| resolver alias | 10 000 | 0.085 | 0.083 | 0.095 |
| resolver default | 10 000 | 0.087 | 0.085 | 0.092 |
| resolver absent | 10 000 | 0.024 | 0.024 | 0.025 |
| codec round-trip | 0 | 0.999 | 0.790 | 1.780 |
| codec round-trip | 100 | 40.135 | 35.000 | 52.400 |
| codec round-trip | 10 000 | 4022.000 | 3769.000 | 5751.000 |
| claim valide | 0 | 2.532 | 2.150 | 4.900 |
| claim valide | 100 | 541.600 | 500.500 | 946.000 |
| claim valide | 10 000 | 20842.857 | 21139.000 | 25317.000 |
| tombstone local | 10 000 | 28249.857 | 23859.000 | 49924.000 |
| collision globale | 10 000 | 30634.000 | 29800.000 | 33662.000 |

Resolver : index O(n), lookup O(1). Codec : O(k log k) pour le tri stable.
Claim index : O(records + claims + targets), avec tri supplémentaire des
conflits. 30 itérations x batch 1000 pour resolver ; codec 30/20/7 ; claims
20/20/7. Aucun seuil flaky ni cache global mutable.

## 36. Scope final
+
```text
 M "MVP Selbrume/event_builder_v2_architecture_decisions.md"
 M "MVP Selbrume/road_map_event_builder_v2.md"
 M packages/map_core/lib/map_core.dart
 M packages/map_core/lib/src/diagnostics/scene_diagnostics.dart
 M packages/map_core/lib/src/diagnostics/world_rule_diagnostics.dart
 M packages/map_core/lib/src/models/game_state.dart
 M packages/map_core/lib/src/models/game_state.freezed.dart
 M packages/map_core/lib/src/models/game_state.g.dart
 M packages/map_core/lib/src/models/save_data.dart
 M packages/map_core/lib/src/models/save_data.freezed.dart
 M packages/map_core/lib/src/models/save_data.g.dart
 M packages/map_core/lib/src/operations/game_state_persistence.dart
 M packages/map_core/lib/src/operations/narrative_event_registry_codec.dart
 M packages/map_core/lib/src/projection/world_rule_projection.dart
 M packages/map_core/lib/src/validation/validators.dart
 M packages/map_core/test/game_state_persistence_test.dart
 M packages/map_core/test/narrative_event_registry_test.dart
 M packages/map_core/test/save_data_test.dart
 M packages/map_core/test/scene_diagnostics_test.dart
 M packages/map_core/test/world_rule_projection_test.dart
 M packages/map_editor/pubspec.lock
 M packages/map_gameplay/.dart_tool/package_config.json
 M packages/map_gameplay/.dart_tool/package_graph.json
 M packages/map_gameplay/lib/src/new_game_state_builder.dart
 M packages/map_gameplay/lib/src/script_condition_evaluator.dart
 M packages/map_gameplay/pubspec.lock
 M packages/map_gameplay/test/new_game_state_builder_test.dart
 M packages/map_runtime/lib/map_runtime.dart
 M packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_write_result.dart
 M packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_writer.dart
 M packages/map_runtime/lib/src/infrastructure/file_game_save_repository.dart
 M packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
 M packages/map_runtime/test/scene_consequence_runtime_writer_test.dart
 M selbrume/project.json
?? packages/map_core/lib/src/models/narrative_fact_runtime_state.dart
?? packages/map_core/lib/src/operations/narrative_fact_runtime.dart
?? packages/map_core/test/narrative_fact_runtime_performance_test.dart
?? packages/map_core/test/narrative_fact_runtime_resolver_test.dart
?? packages/map_core/test/narrative_fact_runtime_state_test.dart
?? packages/map_core/test/narrative_fact_runtime_writer_test.dart
?? packages/map_core/test/project_validator_test.dart
?? packages/map_core/test/validated_legacy_claim_index_runtime_readiness_test.dart
?? packages/map_gameplay/test/narrative_fact_script_condition_test.dart
?? packages/map_runtime/lib/src/application/scene_runtime/scene_fact_condition_runtime_resolver.dart
?? packages/map_runtime/test/narrative_fact_runtime_cross_consumer_test.dart
?? packages/map_runtime/test/narrative_fact_runtime_save_load_test.dart
?? reports/narrativeStudio/events/ns_event_v2_f1_prereq_canonical_fact_runtime_closure_v0.md
?? reports/narrativeStudio/events/ns_event_v2_f1_prereq_evidence_pack.md
?? selbrume/assets/borders/snapshots/b9a77cfa1bf35d89d0854b7c180f974b1400474cc27e05db0d9ee93f82b5b38a/frame_0000.png
?? selbrume/assets/borders/snapshots/d12d89c830a4e1f88038afc8e868282ca24d8a1dfc42505b7e3593cc97ea95c0/frame_0000.png
?? selbrume/assets/borders/snapshots/f7dff67260a8197d15f892ecca9b8099cadb1f4c24176b4c64246c48e719e3c9/frame_0000.png
?? selbrume/assets/borders/snapshots/ff1052a8600830f40d9e04e5dce67d879962e567481f832e26249e4706d4d779/frame_0000.png
```

`git diff --check` : vide. Anti-scope :

```text
packages/map_editor/pubspec.lock
selbrume/project.json
```

Le premier est le drift préexistant hashé au Gate 0 ; le second et les quatre
snapshots Selbrume sont des changements concurrents apparus pendant le lot.


Fichiers du lot : deux docs normatifs, `map_core`, `map_gameplay`, `map_runtime`,
tests et deux rapports. Aucun `map_editor`, `map_battle`, asset, source host,
bridge, UI, migration ou donnée projet n'a été modifié par ce lot.

Le worktree partagé contient néanmoins le lock editor préexistant et des
changements Selbrume apparus pendant l'exécution. Leurs hashes et leur statut
sont isolés dans l'Evidence Pack ; ils ne sont ni revendiqués ni nettoyés.

## 37. Risques résiduels

1. La suite runtime complète doit être relancée après convergence du chantier
   concurrent `ProjectSchemaVersion.v2`.
2. Le fallback raw face à un catalogue Fact ambigu mérite un test de
   caractérisation supplémentaire, sans impact production valide actuel.
3. F1 doit réellement implémenter et tester les 17 cas outbox ; ce lot ne fait
   que ratifier leur contrat.
4. La garantie exactly-once externe reste volontairement hors V0.

## 38. F1 Reopening Gate

Tous les critères fonctionnels propres au prérequis sont prouvés : false
explicite persistant, consumers alignés, collision-safe, claims corpus-aware,
tombstones locaux, global conflicts bloquants et contrat outbox accepté. Aucun
planner prématuré n'existe. F1 est READY pour V2-17/V2-18 ; F1 n'est pas CLOSED.
F2 reste PLANNED / NOT READY.

## 39. Auto-review

Le changement est large parce qu'il ferme trois blockers transverses, mais les
frontières restent celles du prompt. Les principales vigilances ont été la
propagation de l'état Fact dans tous les codecs, l'absence de second resolver,
la preuve corpus obligatoire et la séparation contract/implementation outbox.

Le choix registry-only fail-closed avec claims est plus strict que le
comportement historique, mais il empêche précisément un runtime de confondre
structure plausible et readiness prouvée. Les projections structurelles restent
disponibles ; les résolutions runtime refusent l'absence d'evidence.

## 40. Review contradictoire

R1 a cherché les pertes d'override, divergences de readers, writes legacy-only,
double dispatch et confusion conflit/tombstone. R2 a cherché migration eager,
drop orphelin, mutation consumed IDs, raw flags requalifiés, roadmap mensongère
et save/load regressé. Les blockers initiaux PR-B, PR-C et PR-D ont été corrigés,
puis les deux reviewers ont rendu PASS sur l'arbre final.

## 41. Critique du prompt

Le prompt est précis et a correctement séparé prérequis et F1. Deux tensions ont
été arbitrées : `codex_rule.md` demande un maximum de commentaires, tandis que
le prompt interdit tout nouveau commentaire de code ; l'instruction directe,
plus prioritaire, a été respectée. Les seuls commentaires ajoutés visibles dans
le diff sont des ignores générés automatiquement par Freezed.

La formule PR-C littérale ne mentionnait pas la preuve corpus découverte par la
review. Déclarer `canRunDualRead` depuis le registry seul aurait menti. L'API a
donc été étendue avec `LegacyClaimRuntimeEvidence`, conformément à l'objectif
runtime readiness, sans modifier le wire claims.

Enfin, exiger une suite complète verte tout en interdisant Selbrume devient
impossible quand une autre conversation change ce fichier pendant le lot. La
réponse la plus sûre a été de ne pas le restaurer et de produire une isolation
reproductible des 45 erreurs plus une suite non-Selbrume verte.

## 42. Verdict

```text
F1-PREREQ : CLOSED
PR-0 — Contract Ratification : PASS
PR-A — Fact Runtime Domain & Persistence : PASS
PR-B — Canonical Production Alignment : PASS
PR-C — Dual-Read Runtime Readiness : PASS
PR-D — Outbox Contract Closure : PASS
PHASE F1 : READY
PHASE F2 : NOT READY
```

Réserve : le worktree partagé ne permet pas d'affirmer que la suite runtime
globale est verte tant que le projet Selbrume v2 concurrent n'est pas pris en
charge. Cette réserve n'est pas une régression du lot F1-PREREQ et ne justifie
aucune modification hors scope.
````
