# PERF-RM-00 — Observabilité et baseline reproductible

Date : 2026-08-01  
Branche : `main`  
HEAD : `7f35d44d9f777d25046c6b94d8974a2fdd850a78`  
Verdict proposé : **DONE avec limites de provenance documentées**

## Résumé exécutif

La Phase 0 manquante est maintenant implémentée. Sept harnais Dart AOT, un runner
runtime Flutter profile multi-run et un journey éditeur Flutter profile produisent des
reçus JSON V2 déterministes, versionnés et comparables. Les reçus contiennent les
échantillons bruts, p50/p95/p99, warmups, itérations, empreintes de fixtures, commit,
état et empreinte de l’arbre, versions d’outils, OS/architecture, commande et mémoire
RSS ; les métriques indisponibles restent `null` avec une raison et ne deviennent jamais
zéro.

Trois runs finaux ont été capturés pour chaque famille. Les 21 reçus AOT partagent
l’empreinte `4d1daeed77048484`. Le reçu runtime et les trois reçus éditeur partagent
l’empreinte SHA-256
`2a000dca5a448ce8aa5d9f76677f6f45df1e9bba7cd1d2efc4dcc62a11307c0c`.
Les deux algorithmes d’empreinte diffèrent, mais chaque campagne est homogène et le
runtime/éditeur profile partagent bien exactement le même snapshot source.

La clôture est proposée `DONE` parce que les critères Go RM-00 sont couverts : schéma,
fixtures fingerprintées, trois runs comparables, métriques de frames séparées, deux
budgets de frame, profils réels et CI non bloquante. Deux limites n’invalident pas le
socle mais interdisent une attribution historique abusive : la baseline a été récupérée
après PERF-RM-01..04 dans un arbre déjà sale, et le snapshot auteur local utilise
`cycles=1` au lieu de la commande longue `cycles=10`. Le harnais supporte bien
`cycles=10`, mais cette campagne longue n’a pas été exécutée.

## Confirmation du scope

Le lot reste strictement un lot de mesure et de contrat :

- aucun comportement gameplay, battle, rendu, sauvegarde ou authoring utilisateur n’a
  été changé par RM-00 ;
- aucune gate dure n’a été activée ; la politique exige dix observations historiques et
  deux régressions consécutives avant tout blocage ;
- `map_core` mesure la peinture pure, tandis que l’éditeur mesure frames et parcours UI ;
- les 512² collision sont lancés dans trois processus isolés par reçu ;
- `promotion_checkpoint` est explicitement rejeté par le snapshot tant que sa ressource
  manque ;
- le fichier roadmap n’a pas été édité : conformément aux règles du dépôt, ce rapport
  propose le statut sans le marquer lui-même ;
- aucune opération Git d’écriture n’a été exécutée.

Parité PokeMap MCP : **N/A**. Le lot n’ajoute ni sémantique d’authoring visible, ni
commande éditeur, ni donnée projet ; il ajoute uniquement des harnais et de la collecte.

## Audit initial

L’audit a lu `AGENTS.md`, `codex_rule.md`, l’audit performance, la roadmap de
remédiation, les Evidence Packs RM-01..04, les scripts de benchmark existants, le runner
`pokemap_eval`, les métriques interactives et les workflows CI.

| Zone | Contrat trouvé | Manque constaté | Décision RM-00 |
|---|---|---|---|
| `map_core` | opérations pures et benchmark surface issu de RM-03 | peinture, hiérarchie, JSON, enveloppe commune | trois harnais réels + mise au contrat du benchmark surface |
| `map_gameplay` | stockage collision RM-04 | reçus communs et campagne isolée stabilisée | enrichissement du benchmark et 512² × 3 processus |
| `map_authoring` | `WorkspacePolicy`, `ProjectOpenService`, `ProjectSnapshotLoader` | aucun coût d’ouverture strict | benchmark fixtures réelles + synthétique 10 MiB |
| `map_battle` | `BattleEngine.submit` | aucune baseline de tours | tours déterministes indépendants avec checksum |
| runtime host | bridge interactif, `FrameTiming` partiel | pas de profile multi-run JSON V2 | `--build-mode profile`, `--runs`, agrégation stricte |
| éditeur | application et notifier réels | pas de journey profile reproductible | open → paint ×100 → undo → paint → save |
| CI | lane performance historique | pas de collecte RM-00 complète | job macOS non bloquant + artifact + manifeste explicite |

Risques identifiés avant implémentation : confondre JIT et AOT/profile, additionner build
et raster, mesurer la construction des fixtures au lieu de l’opération, retenir plusieurs
mondes 512² dans le même processus, accepter un output hors package, traiter une mesure
absente comme zéro, ou rendre une observation immédiatement bloquante.

La documentation Flame MCP attendue n’était pas disponible dans les outils configurés.
Le travail runtime s’est donc fondé sur les versions verrouillées et les patterns déjà
fonctionnels du dépôt : Flame `1.37.0` dans le host et `1.38.0` dans l’éditeur.

## État Git initial

Le lot a commencé sur `main@7f35d44d9f777d25046c6b94d8974a2fdd850a78`, avec
les changements non commités de la Phase 1 et les documents d’audit déjà présents :

```text
 M examples/playable_runtime_host/lib/main.dart
 M packages/map_authoring/lib/src/domains/maps/autotile_actions.dart
 M packages/map_core/lib/src/operations/surface_variant_role_resolver.dart
 M packages/map_core/test/surface_variant_role_resolver_test.dart
 M packages/map_editor/lib/src/features/border_map_editing/presentation/editor_map_layer_paint_order.dart
 M packages/map_editor/lib/src/features/surface_painter/surface_layer_static_preview.dart
 M packages/map_editor/lib/src/features/surface_painter/surface_tile_preview_resolver.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_render_plan.dart
 M packages/map_editor/lib/src/ui/canvas/map_canvas.dart
 M packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
 M packages/map_editor/lib/src/ui/editor_shell_page.dart
 M packages/map_editor/test/border_map_editing/editor_map_layer_paint_order_test.dart
 M packages/map_editor/test/editor_shell_page_smoke_test.dart
 M packages/map_editor/test/map_grid_painter_test.dart
 M packages/map_editor/test/surface_painter/surface_layer_static_preview_test.dart
 M packages/map_editor/test/surface_painter/surface_tile_preview_resolver_test.dart
 M packages/map_gameplay/lib/src/gameplay_world_state.dart
 M packages/map_gameplay/test/gameplay_world_state_entity_move_test.dart
 M packages/map_runtime/lib/src/infrastructure/runtime_tileset_image.dart
 M packages/map_runtime/lib/src/infrastructure/tile_image_loader.dart
 M packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
 M packages/map_runtime/lib/src/presentation/flame/placed_element_occlusion_patch_component.dart
 M packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
 M packages/map_runtime/lib/src/presentation/flame/quarter_turn_pixel_renderer.dart
 M packages/map_runtime/lib/src/presentation/flutter/battle_mobile_command_overlay.dart
 M packages/map_runtime/lib/src/surface/surface_runtime_resolver.dart
 M packages/map_runtime/test/placed_element_occlusion_patch_component_test.dart
 M packages/map_runtime/test/quarter_turn_pixel_renderer_test.dart
 M packages/map_runtime/test/surface/surface_runtime_resolver_test.dart
?? packages/map_core/benchmark/surface_role_scaling.dart
?? packages/map_core/test/benchmark/surface_role_scaling_cli_test.dart
?? packages/map_gameplay/benchmark/world_collision_scaling.dart
?? packages/map_gameplay/lib/src/collision/world_collision_storage.dart
?? packages/map_gameplay/test/benchmark/world_collision_scaling_cli_test.dart
?? packages/map_gameplay/test/gameplay_world_state_collision_storage_characterization_test.dart
?? packages/map_runtime/test/battle_mobile_command_overlay_asset_loading_test.dart
?? packages/map_runtime/test/playable_map_game_tileset_lifecycle_test.dart
?? packages/map_runtime/test/tile_image_loader_codec_disposal_test.dart
?? packages/map_runtime/test/tile_image_loader_singleflight_test.dart
?? reports/performance/perf_rm_01_runtime_asset_ownership.md
?? reports/performance/perf_rm_02_runtime_occlusion.md
?? reports/performance/perf_rm_03_surface_topology.md
?? reports/performance/perf_rm_04_gameplay_collision.md
?? reports/performance/plans/2026-08-01-pokemap-perf-rm-01-runtime-asset-ownership.md
?? reports/performance/plans/2026-08-01-pokemap-perf-rm-02-runtime-occlusion.md
?? reports/performance/plans/2026-08-01-pokemap-perf-rm-03-surface-topology.md
?? reports/performance/plans/2026-08-01-pokemap-perf-rm-04-gameplay-collision.md
?? reports/performance/pokemap_full_performance_audit.md
?? reports/performance/pokemap_performance_remediation_roadmap.md
?? skills/creating-pokemap-maps-from-reference/scripts/__pycache__/inventory_assets.cpython-314.pyc
```

Pendant la campagne, des modifications étrangères au lot sont apparues dans
`world_map_tool_activation.dart`, `world_map_layers_inspector.dart` et leurs tests. Elles
ont invalidé les premiers essais éditeur par changement d’empreinte ; ces essais ont été
jetés, les fichiers ont été préservés et n’ont pas été modifiés par RM-00.

## Passes nommées et verdicts

La règle développeur active interdisait de lancer des sub-agents sans demande explicite
de l’utilisateur. `codex_rule.md` autorise alors des passes séparées nommées. Aucun
sub-agent RM-00 n’a donc été créé ; les agents terminés visibles dans l’environnement
appartenaient à la revue Phase 1.

| Passe | Verdict | Signal principal |
|---|---|---|
| Audit / Architecture | `PASS_WITH_CHANGES` | Phase 0 réellement absente ; baseline clean pré-Phase-1 impossible sans écraser l’arbre utilisateur |
| Implémentation | `PASS` | enveloppe V2, sept AOT, runtime multi-run, journey éditeur, CI observation |
| Tests | `PASS_WITH_EXTERNAL_FAILURES` | tous les tests RM-00 verts ; suites Flutter complètes conservent des échecs hors lot détaillés plus bas |
| Build / Validation | `PASS_WITH_LIMITATION` | AOT et profile réels verts ; snapshot local borné à `cycles=1` |
| Critique finale | `PASS_WITH_RESERVATIONS` | aucune gate autorisée avant historique ; baseline post-Phase-1 non utilisable comme « before » RM-01..04 |

## Architecture du contrat de mesure

Tous les reçus partagent l’enveloppe V2 suivante :

- `schemaVersion`, `generatorVersion`, `benchmark`, `executionMode` ;
- `sdk`, `toolchain.dart`, `toolchain.flutter`, `toolchain.flame` ;
- `os`, `osVersion`, `architecture`, `commit`, `treeState`,
  `treeFingerprint` ;
- `warmups`, `sampleCount`, `command`, `memory`, `results` ;
- échantillons bruts et percentiles nearest-rank ;
- RSS réel lorsque disponible, heap/rebuild `null` avec raison sinon.

L’empreinte est calculée depuis la racine Git, sur le status, le diff binaire et le
contenu hashé de tous les fichiers non suivis. Cette correction a été ajoutée après qu’une
première validation a prouvé que `git ls-files` lancé depuis chaque package donnait des
empreintes différentes. Les sorties `build/` sont ignorées et ne perturbent pas la
comparaison.

Pour les frames, build, raster et `FrameTiming.totalSpan` restent séparés. Les taux
`>16,67 ms` et `>33,3 ms` portent uniquement sur `totalSpan`. Aucun calcul n’additionne
build et raster.

## Inventaire complet des fichiers RM-00

Le contenu intégral des 18 fichiers créés ou repris est dans
[`perf_rm_00_created_files_full_content.md`](perf_rm_00_created_files_full_content.md).
Le diff exact des neuf fichiers suivis modifiés est dans
[`perf_rm_00_modified_file_diffs.md`](perf_rm_00_modified_file_diffs.md).

| Fichier | Zone / raison | Impact attendu |
|---|---|---|
| `.github/workflows/pokemap_hub_product_certification.yml` | job `performance-observation`, paths, AOT borné, tests explicites, profile éditeur, upload | collecte visible mais non bloquante |
| `tool/performance/benchmark_support.dart` | CLI stricte, nearest-rank, enveloppe, mémoire, Git root, contenu untracked, output atomique/symlink-safe | contrat commun sans faux comparables |
| `packages/map_core/benchmark/surface_role_scaling.dart` | enveloppe V2 enrichie, RSS, fingerprint arbre, validation output précoce | baseline topology comparable |
| `packages/map_core/test/benchmark/surface_role_scaling_cli_test.dart` | succès, parité checksum, options invalides, confinement | garde-fous surface |
| `packages/map_core/benchmark/map_paint_gesture.dart` | vraie opération pure `paintSurfacePlacement`, tailles/strokes | coût pur séparé de Flutter |
| `packages/map_core/test/benchmark/map_paint_gesture_cli_test.dart` | reçu déterministe et erreurs CLI | non-régression du contrat peinture |
| `packages/map_core/benchmark/group_hierarchy_scaling.dart` | vraie `ProjectValidator.validate` sur hiérarchies | scaling groupes |
| `packages/map_core/test/benchmark/group_hierarchy_scaling_cli_test.dart` | checksum, percentiles, output | contrat hiérarchie |
| `packages/map_core/benchmark/json_roundtrip_scaling.dart` | encode/decode et reconstruction typée 1 KiB–10 MiB | scaling JSON réel |
| `packages/map_core/test/benchmark/json_roundtrip_scaling_cli_test.dart` | tailles, percentiles, cas négatifs | contrat JSON |
| `packages/map_gameplay/benchmark/world_collision_scaling.dart` | build/move/1 000 queries, masque sparse, 512² isolé, V2 | baseline collision sans rétention multi-monde |
| `packages/map_gameplay/test/benchmark/world_collision_scaling_cli_test.dart` | child checksum/no-mask, isolation/output invalides | garde-fous collision |
| `packages/map_authoring/benchmark/authoring_snapshot_open.dart` | services production, strict snapshot, fixtures réelles/synthétique, racines | coût d’ouverture auteur réel |
| `packages/map_authoring/test/benchmark/authoring_snapshot_open_cli_test.dart` | succès synthétique, rejet checkpoint/zéro/escape | pas de faux snapshot JSON-only |
| `packages/map_battle/benchmark/battle_turn_baseline.dart` | `BattleEngine.submit`, tours indépendants, checksum | baseline battle reproductible |
| `packages/map_battle/test/benchmark/battle_turn_baseline_cli_test.dart` | succès et options négatives | contrat battle |
| `examples/playable_runtime_host/lib/src/evaluation/interactive/interactive_frame_metrics.dart` | snapshot V2 strict, raw build/raster/span, percentiles et taux | frames profile interprétables |
| `examples/playable_runtime_host/lib/src/evaluation/interactive/interactive_worker_client.dart` | `EvaluationBuildMode`, `--profile`, timeout 120 s | démarrage profile froid robuste |
| `examples/playable_runtime_host/tool/src/pokemap_eval_cli.dart` | `--build-mode`, `--runs`, `--json-output`, runs isolés, agrégation et empreinte | preuve runtime automatisable |
| `examples/playable_runtime_host/test/evaluation/interactive_frame_metrics_test.dart` | percentiles connus, zéro, non trié, roundtrip, schémas invalides | collector non mensonger |
| `examples/playable_runtime_host/test/evaluation/interactive_worker_client_test.dart` | debug/profile, timeout, auth | lancement correctement câblé |
| `examples/playable_runtime_host/test/evaluation/pokemap_eval_cli_test.dart` | agrégat V2, artifacts manquants, options et output | runner profile strict |
| `packages/map_editor/pubspec.yaml` | dev deps `flutter_driver`, `integration_test` | driver profile supporté |
| `packages/map_editor/pubspec.lock` | résolution correspondante | build reproductible |
| `packages/map_editor/integration_test/editor_project_journey_test.dart` | projet/map réels, open, 100 paints, undo, repaint, save, timings/RSS | journey utilisateur représentatif |
| `packages/map_editor/test_driver/performance_driver.dart` | callback, metadata, empreinte racine, output atomique | reçu profile comparable |
| `reports/performance/plans/2026-08-01-pokemap-perf-rm-00-observability.md` | plan d’exécution | décisions et séquencement |
| `reports/performance/perf_rm_00_created_files_full_content.md` | annexe intégrale | exigence `codex_rule.md` |
| `reports/performance/perf_rm_00_modified_file_diffs.md` | diff exact | zones modifiées auditables |
| `reports/performance/perf_rm_00_observability.md` | présent Evidence Pack | verdict, preuves et limites |

Le roadmap cite `examples/playable_runtime_host/tool/pokemap_eval.dart`. Ce point d’entrée
reste un wrapper ; l’implémentation réelle se trouve déjà dans
`tool/src/pokemap_eval_cli.dart`. Modifier le wrapper sans nécessité aurait été
cérémoniel, donc seul le fichier d’implémentation a changé.

## Tests créés ou modifiés

Les tests CLI couvrent succès, schéma, checksum/fingerprint, sorties confinées, nombres
nuls/malformés et options inconnues. Le collector runtime couvre percentiles connus,
échantillons non triés sans mutation, zéro frame, JSON malformé, version inconnue et
roundtrip. Le journey profile prouve les appels réels open/paint/undo/save.

### TDD rouge et défauts découverts

- `map_core` : `dart test test/benchmark` a d’abord échoué `+0 -6`, fichiers absents ;
- `map_authoring` et `map_battle` : `+0 -2`, harnais absents ;
- runtime : erreurs de compilation sur le nouveau snapshot V2 et les options profile ;
- premier profile runtime : exit `3`, timeout 60 s avant bridge ; corrigé à 120 s ;
- premier journey éditeur : save sans changement après undo, puis dart-define invisible
  au processus driver ; corrigés par un paint post-undo et le chemin dans `reportData` ;
- `dart analyze map_core` : un import `dart:convert` inutilisé, supprimé ;
- tests négatifs authoring/battle : timeouts car la validation d’output arrivait après la
  mesure par défaut ; validation déplacée avant tout travail coûteux ;
- premières séries éditeur : empreintes différentes à cause de modifications externes
  concurrentes ; séries rejetées puis recapturées ;
- première validation multi-package : quatre empreintes au lieu d’une à cause du cwd
  Git ; calcul déplacé à la racine et contenu untracked inclus.

### Résultats ciblés finaux

```text
cd packages/map_core && dart test test/benchmark -r compact
00:19 +8: All tests passed!

cd packages/map_gameplay && dart test test/benchmark/world_collision_scaling_cli_test.dart -r compact
00:10 +2: All tests passed!

cd packages/map_authoring && dart test test/benchmark/authoring_snapshot_open_cli_test.dart -r compact
00:15 +2: All tests passed!

cd packages/map_battle && dart test test/benchmark/battle_turn_baseline_cli_test.dart -r compact
00:05 +2: All tests passed!

cd examples/playable_runtime_host && flutter test \
  test/evaluation/interactive_frame_metrics_test.dart \
  test/evaluation/interactive_worker_client_test.dart \
  test/evaluation/pokemap_eval_cli_test.dart -r compact
00:03 +20: All tests passed!
```

### Suites complètes Dart

```text
packages/map_core:      02:19 +4678: All tests passed!
packages/map_gameplay:  00:11 +455: All tests passed!
packages/map_authoring: 00:19 +306: All tests passed!
packages/map_battle:    00:20 +1771: All tests passed!
```

Ces suites complètes ont été lancées avant la dernière passe uniquement documentaire de
commentaires dans les harnais. Après cette passe, les quatre suites benchmark ciblées et
les quatre analyzers ont été relancés et sont verts.

### Suites complètes Flutter : échecs hors lot

Le dépôt complet n’est pas « all green » :

```text
examples/playable_runtime_host: 06:26 +273 ~2 -2: Some tests failed.
packages/map_editor:            05:15 +5202 ~6 -36: Some tests failed.
```

Les deux échecs host ont été isolés :

1. `selbrume_player_journey_e2e_test.dart` —
   `FG-182 product journey source excludes forged gameplay shortcuts` : attendu
   `not contains 'GameStateMutations'`, mais
   `selbrume_evaluation_driver.dart:1169` appelle déjà
   `const GameStateMutations().sellToResolvedShop(...)`. Le test isolé reste rouge.
2. `phase_7a_installed_golden_journey_test.dart` —
   `Phase 7A certifies all 19 MVP criteria from the installed package` :
   `GamePackageExportException(gameplayReadinessFailed)`, avec notamment espèce cible
   `porygon-z` absente, doublons de learnsets et « 452 autre(s) erreur(s) ». Le test
   isolé reste rouge.

Le premier échec éditeur a également été isolé :

```text
test/border_map_editing/pending_border_save_entry_points_test.dart
Cmd/Ctrl+S uses the shared guard and Apply saves the candidate
Expected: length 1
Actual: []
EditorNotifier: Map revision conflict while saving:
Cette carte ne possède pas de révision disque attestée.
```

Il reste rouge isolément à la ligne 54. Aucun de ces fichiers ou contrats n’est modifié
par RM-00. Les `-36` éditeur sont donc conservés comme dette externe ; les tests RM-00,
les analyses et les trois journeys profile restent verts.

## Analyses, format et validation structurelle

```text
dart format <23 fichiers RM-00>
Formatted 23 files (0 changed).

cd packages/map_core && dart analyze
No issues found!
cd packages/map_gameplay && dart analyze
No issues found!
cd packages/map_authoring && dart analyze
No issues found!
cd packages/map_battle && dart analyze
No issues found!
cd examples/playable_runtime_host && flutter analyze
No issues found!
cd packages/map_editor && flutter analyze
No issues found!

git diff --check
exit 0, aucune sortie

ruby -e "require 'yaml'; YAML.load_file('.github/workflows/pokemap_hub_product_certification.yml')"
workflow YAML parsed

actionlint .github/workflows/pokemap_hub_product_certification.yml
non lancé : actionlint unavailable
```

Le validateur de reçus a parcouru 21 reçus AOT et 294 vecteurs d’échantillons :
`pure_fp_count=1`, `profile_fp_count=1`, `errors=0`. Il a recalculé chaque
p50/p95/p99 nearest-rank et vérifié les longueurs build/raster/span.

## Builds et commandes de baseline

Les sept exécutables ont été compilés avec `dart compile exe`; chaque commande a
retourné `0` et affiché `Generated:`. Les commandes de mesure finales sont :

```bash
cd packages/map_core
dart compile exe benchmark/surface_role_scaling.dart -o build/performance/final/bin/surface_role_scaling
dart compile exe benchmark/map_paint_gesture.dart -o build/performance/final/bin/map_paint_gesture
dart compile exe benchmark/group_hierarchy_scaling.dart -o build/performance/final/bin/group_hierarchy_scaling
dart compile exe benchmark/json_roundtrip_scaling.dart -o build/performance/final/bin/json_roundtrip_scaling
# Chaque binaire : 3 runs, warmups 5, samples 30, paramètres complets roadmap.

cd packages/map_gameplay
dart compile exe benchmark/world_collision_scaling.dart -o build/performance/final/bin/world_collision_scaling
# 3 runs, warmups 5, samples 30, tailles 32–256, 512 × 3 processus isolés.

cd packages/map_authoring
dart compile exe benchmark/authoring_snapshot_open.dart -o build/performance/final/bin/authoring_snapshot_open
# 3 runs, warmups 2, samples 15, 4 fixtures, racines 1/3/10, cycles 1.

cd packages/map_battle
dart compile exe benchmark/battle_turn_baseline.dart -o build/performance/final/bin/battle_turn_baseline
# 3 runs, warmups 5, samples 30, 100/500/1000/2000/5000 tours.
```

Runtime profile final :

```bash
cd examples/playable_runtime_host
dart run tool/pokemap_eval.dart run selbrume.healing-service \
  --target interactive --build-mode profile --runs 3 \
  --json-output build/performance/final/runtime_selbrume_journey.json
```

Résultat exact : exit `0`,
`Profile evidence: examples/playable_runtime_host/build/performance/final/runtime_selbrume_journey.json (3 isolated runs)`.
macOS a imprimé `Failed to foreground app; open returned 1` sur les trois lancements,
mais le bridge s’est connecté et les trois runs ont produit leurs artifacts.

Éditeur profile final, trois fois :

```bash
cd packages/map_editor
flutter drive --profile -d macos \
  --driver=test_driver/performance_driver.dart \
  --target=integration_test/editor_project_journey_test.dart \
  --dart-define=POKEMAP_PERF_OUTPUT=build/performance/final/run-N/editor_project_journey.json
```

Résultat exact : trois exits `0`. Les runs visibles antérieurs ont confirmé
`All tests passed` et `✓ Built build/macos/Build/Products/Profile/PokeMap.app`; les
commandes finales ont été volontairement silencieuses, mais leurs trois reçus V2 sont
présents et validés.

## Baseline locale finale

### AOT pur — p95 représentatif

Les valeurs ci-dessous sont les p95 de chaque run puis leur médiane. Elles sont des
observations, pas des budgets produit.

| Harnais / point | Runs p95 | Médiane |
|---|---:|---:|
| surface topology `mixed/2500` | 746 / 689 / 686 µs | 689 µs |
| paint `1024 / stroke 1000` | 37 307 / 33 743 / 34 181 µs | 34 181 µs |
| groupes `3200` | 19 740 / 19 219 / 19 367 µs | 19 367 µs |
| JSON `10 MiB` | 29 775 / 29 583 / 30 104 µs | 29 775 µs |
| collision 256² build | 3 375 / 3 141 / 3 205 µs | 3 205 µs |
| collision 256² move | 5 / 4 / 6 µs | 5 µs |
| collision 256², 1 000 queries | 46 / 206 / 239 µs | 206 µs |
| snapshot synthétique 10 MiB, 10 roots, cycle 1 | 1 329 679 / 1 511 899 / 1 444 569 µs | 1 444 569 µs |
| battle 5 000 tours indépendants | 510 952 / 503 808 / 499 520 µs | 503 808 µs |

Chaque reçu collision contient exactement trois `isolatedResults` 512².

### Runtime profile

| Mesure agrégée | Valeur |
|---|---:|
| runs / frames | 3 / 740 (`237`, `249`, `254`) |
| build p95 | 34,730 ms |
| raster p95 | 1,157 ms |
| full-frame p95 | 58,894 ms |
| frames >16,67 ms | 74,1892 % |
| frames >33,3 ms | 13,9189 % |

Ces chiffres montrent que les lots d’optimisation restent nécessaires ; RM-00 ne les
transforme pas en gate.

### Éditeur profile

| Run | Frames | build p95 | raster p95 | full-frame p95 | >16,67 ms | >33,3 ms | RSS |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 18 | 17,381 ms | 11,047 ms | 217,356 ms | 33,3333 % | 22,2222 % | 327 827 456 B |
| 2 | 18 | 11,145 ms | 10,532 ms | 214,270 ms | 33,3333 % | 16,6667 % | 329 678 848 B |
| 3 | 18 | 11,438 ms | 9,631 ms | 210,789 ms | 27,7778 % | 16,6667 % | 329 940 992 B |

Le rebuild count est `null`, avec l’explication que les callbacks debug ne sont pas
exposés en profile. Le heap est également `null`; le RSS natif est enregistré.

## CI d’observation

Le job `performance-observation` :

- tourne sur `macos-15`, avec Flutter pinning identique au workflow ;
- est `continue-on-error: true` au niveau job et aux étapes de collecte ;
- compile et lance des variantes AOT bornées ;
- utilise un manifeste de fichiers tests explicite ;
- lance le journey éditeur en profile, jamais comme proxy debug ;
- publie tous les JSON sous un artifact conservé 30 jours ;
- n’applique aucun seuil.

Les trois profiles runtime et les campagnes longues restent destinés au nightly prévu
par la Phase 5 ; le mode et la campagne locale trois-runs sont déjà prouvés ici.

## Limites conservées et risques restants

1. **Provenance post-Phase-1.** Le HEAD est bien `7f35d44d9`, mais l’arbre est sale et
   contient déjà RM-01..04. Cette baseline sert aux comparaisons futures ; elle ne peut
   pas prouver le gain before/after de la Phase 1 déjà appliquée.
2. **Snapshot borné.** `cycles=1` a été utilisé localement. Avec `cycles=10`, les 4
   fixtures × 3 roots × 17 passages représentent environ 2 040 ouvertures par run ; la
   commande est supportée mais non exécutée dans ce lot interactif.
3. **Historique insuffisant.** Il existe trois runs locaux, pas dix observations CI.
   Toute gate dure reste interdite.
4. **Warnings macOS.** `open returned 1` et un warning de détection du plugin
   `integration_test` apparaissent, malgré bridge connecté et exit `0`. À surveiller sur
   CI, sans convertir ces warnings en succès silencieux si un artifact manque.
5. **Suites globales rouges.** Les échecs host/éditeur détaillés sont hors RM-00 mais
   empêchent de déclarer le dépôt entier vert.
6. **Outils.** `actionlint` et la documentation Flame MCP ne sont pas disponibles ; le
   YAML est parsé et les commandes de job critiques ont été exécutées localement.
7. **Artifacts non suivis.** Les reçus résident sous `build/` et sont volontairement
   ignorés. L’ajout de cet Evidence Pack après capture change le contenu untracked du
   worktree, mais aucun source de harnais n’a changé après la campagne finale.

## Auto-critique finale

- La première version de l’empreinte était insuffisante : elle dépendait du cwd et
  ignorait le contenu untracked. La validation cross-package a évité de publier ces
  reçus ; les campagnes concernées ont été refaites.
- Les validations output arrivaient initialement trop tard pour authoring/battle. Les
  timeouts négatifs ont révélé ce problème et le confinement est maintenant vérifié
  avant le coût de mesure.
- Les premiers profils ont montré deux fragilités réelles du tooling : timeout 60 s et
  dart-define non transmis au driver. Elles sont couvertes par tests/profile réels.
- La campagne a été recapturée après chaque modification de source, y compris les
  commentaires obligatoires. Cela coûte du temps mais évite une preuve attachée à un
  autre snapshot.
- Le rapport ne prétend pas que les p95 actuels sont acceptables. Ils sont élevés, en
  particulier runtime/editor, et servent précisément de point de départ aux phases
  suivantes.

Verdict critique : aucun comportement manquant n’est transformé en zéro, aucun JIT
n’est présenté comme AOT/profile, aucun seuil prématuré n’est actif, et les artifacts
finaux sont comparables. `PERF-RM-00` peut être proposé `DONE`; la dette globale et la
provenance post-Phase-1 restent explicitement visibles.

## Prochaines étapes proposées, non implémentées

1. Reporter `PERF-RM-00` en `DONE` dans la roadmap après revue humaine de cet Evidence
   Pack.
2. Utiliser cette baseline pour requalifier RM-01..04 sans prétendre reconstituer leur
   « before » historique.
3. Démarrer la Phase 2 avec ses lots de chargement/lifecycle, en conservant les mêmes
   empreintes et commandes.
4. Après dix artifacts CI comparables, calibrer les seuils absolus et relatifs ; aucune
   gate avant cela.
5. Réserver au nightly la commande snapshot `cycles=10` et les trois profiles runtime
   longs, comme prévu par la roadmap.

## État Git final

```text
 M .github/workflows/pokemap_hub_product_certification.yml
 M examples/playable_runtime_host/lib/main.dart
 M examples/playable_runtime_host/lib/src/evaluation/interactive/interactive_frame_metrics.dart
 M examples/playable_runtime_host/lib/src/evaluation/interactive/interactive_worker_client.dart
 M examples/playable_runtime_host/test/evaluation/interactive_frame_metrics_test.dart
 M examples/playable_runtime_host/test/evaluation/interactive_worker_client_test.dart
 M examples/playable_runtime_host/test/evaluation/pokemap_eval_cli_test.dart
 M examples/playable_runtime_host/tool/src/pokemap_eval_cli.dart
 M packages/map_authoring/lib/src/domains/maps/autotile_actions.dart
 M packages/map_core/lib/src/operations/surface_variant_role_resolver.dart
 M packages/map_core/test/surface_variant_role_resolver_test.dart
 M packages/map_editor/lib/src/features/border_map_editing/presentation/editor_map_layer_paint_order.dart
 M packages/map_editor/lib/src/features/editor/application/world_map_tool_activation.dart
 M packages/map_editor/lib/src/features/editor/presentation/world_map/world_map_layers_inspector.dart
 M packages/map_editor/lib/src/features/surface_painter/surface_layer_static_preview.dart
 M packages/map_editor/lib/src/features/surface_painter/surface_tile_preview_resolver.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_render_plan.dart
 M packages/map_editor/lib/src/ui/canvas/map_canvas.dart
 M packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
 M packages/map_editor/lib/src/ui/editor_shell_page.dart
 M packages/map_editor/pubspec.lock
 M packages/map_editor/pubspec.yaml
 M packages/map_editor/test/border_map_editing/editor_map_layer_paint_order_test.dart
 M packages/map_editor/test/editor_shell_page_smoke_test.dart
 M packages/map_editor/test/features/editor/application/world_map_paint_layer_routing_test.dart
 M packages/map_editor/test/features/editor/application/world_map_tool_activation_test.dart
 M packages/map_editor/test/features/editor/presentation/world_map/world_map_layers_inspector_test.dart
 M packages/map_editor/test/map_grid_painter_test.dart
 M packages/map_editor/test/surface_painter/surface_layer_static_preview_test.dart
 M packages/map_editor/test/surface_painter/surface_tile_preview_resolver_test.dart
 M packages/map_gameplay/lib/src/gameplay_world_state.dart
 M packages/map_gameplay/test/gameplay_world_state_entity_move_test.dart
 M packages/map_runtime/lib/src/infrastructure/runtime_tileset_image.dart
 M packages/map_runtime/lib/src/infrastructure/tile_image_loader.dart
 M packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
 M packages/map_runtime/lib/src/presentation/flame/placed_element_occlusion_patch_component.dart
 M packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
 M packages/map_runtime/lib/src/presentation/flame/quarter_turn_pixel_renderer.dart
 M packages/map_runtime/lib/src/presentation/flutter/battle_mobile_command_overlay.dart
 M packages/map_runtime/lib/src/surface/surface_runtime_resolver.dart
 M packages/map_runtime/test/placed_element_occlusion_patch_component_test.dart
 M packages/map_runtime/test/quarter_turn_pixel_renderer_test.dart
 M packages/map_runtime/test/surface/surface_runtime_resolver_test.dart
?? packages/map_authoring/benchmark/authoring_snapshot_open.dart
?? packages/map_authoring/test/benchmark/authoring_snapshot_open_cli_test.dart
?? packages/map_battle/benchmark/battle_turn_baseline.dart
?? packages/map_battle/test/benchmark/battle_turn_baseline_cli_test.dart
?? packages/map_core/benchmark/group_hierarchy_scaling.dart
?? packages/map_core/benchmark/json_roundtrip_scaling.dart
?? packages/map_core/benchmark/map_paint_gesture.dart
?? packages/map_core/benchmark/surface_role_scaling.dart
?? packages/map_core/test/benchmark/group_hierarchy_scaling_cli_test.dart
?? packages/map_core/test/benchmark/json_roundtrip_scaling_cli_test.dart
?? packages/map_core/test/benchmark/map_paint_gesture_cli_test.dart
?? packages/map_core/test/benchmark/surface_role_scaling_cli_test.dart
?? packages/map_editor/integration_test/editor_project_journey_test.dart
?? packages/map_editor/test_driver/performance_driver.dart
?? packages/map_gameplay/benchmark/world_collision_scaling.dart
?? packages/map_gameplay/lib/src/collision/world_collision_storage.dart
?? packages/map_gameplay/test/benchmark/world_collision_scaling_cli_test.dart
?? packages/map_gameplay/test/gameplay_world_state_collision_storage_characterization_test.dart
?? packages/map_runtime/test/battle_mobile_command_overlay_asset_loading_test.dart
?? packages/map_runtime/test/playable_map_game_tileset_lifecycle_test.dart
?? packages/map_runtime/test/tile_image_loader_codec_disposal_test.dart
?? packages/map_runtime/test/tile_image_loader_singleflight_test.dart
?? reports/performance/perf_rm_00_created_files_full_content.md
?? reports/performance/perf_rm_00_modified_file_diffs.md
?? reports/performance/perf_rm_00_observability.md
?? reports/performance/perf_rm_01_runtime_asset_ownership.md
?? reports/performance/perf_rm_02_runtime_occlusion.md
?? reports/performance/perf_rm_03_surface_topology.md
?? reports/performance/perf_rm_04_gameplay_collision.md
?? reports/performance/plans/2026-08-01-pokemap-perf-rm-00-observability.md
?? reports/performance/plans/2026-08-01-pokemap-perf-rm-01-runtime-asset-ownership.md
?? reports/performance/plans/2026-08-01-pokemap-perf-rm-02-runtime-occlusion.md
?? reports/performance/plans/2026-08-01-pokemap-perf-rm-03-surface-topology.md
?? reports/performance/plans/2026-08-01-pokemap-perf-rm-04-gameplay-collision.md
?? reports/performance/pokemap_full_performance_audit.md
?? reports/performance/pokemap_performance_remediation_roadmap.md
?? skills/creating-pokemap-maps-from-reference/scripts/__pycache__/inventory_assets.cpython-314.pyc
?? tool/performance/benchmark_support.dart
```

Aucun fichier de la Phase 1 ni aucune modification concurrente de l’utilisateur n’a été
écrasé, nettoyé, stagé ou commit.
