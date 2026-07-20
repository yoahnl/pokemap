# NSC-74 Large Project Performance Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Figer et faire respecter des budgets reproductibles pour les index, la recherche, le Validator, Map Events, le graphe Storyline, la bibliothèque de 1 000 Cinematics, la timeline de 1 000 blocs et la persistance Event.

**Architecture:** Les chemins purs restent mesurés dans `map_core`; les projections et I/O d'authoring restent mesurées séquentiellement sous `flutter test` dans `map_editor`. Chaque benchmark possède une fixture déterministe, des warmups, un p50/p95, un checksum fonctionnel et un seuil figé après le premier run accepté. Aucune cache ni virtualisation produit n'est ajoutée sans dépassement observé.

**Tech Stack:** Dart 3, Flutter test debug/JIT, `map_core` read models, `map_editor` projections, `Stopwatch`, tests package-scoped.

---

## Inventaire et frontières

- `packages/map_core/test/narrative_dependency_index_performance_test.dart` : fixture 10 000 Facts, construction/lookup/checksum et stabilité après mutation locale.
- `packages/map_editor/test/narrative_global_search_performance_test.dart` : index de 10 000 entrées, requêtes exacte/accent/fuzzy, ordre et réponse stale.
- `packages/map_editor/test/narrative_large_project_workspace_performance_test.dart` : Map Events 1 000 sources/events, Storyline 1 000 Steps, Cinematics Library 1 000 assets et timeline 1 000 blocs.
- `packages/map_editor/test/narrative_event_validation_incremental_performance_test.dart` : conserver le budget historique et prouver que la mutation locale ne recalcule que son closure.
- `packages/map_editor/test/narrative_event_authoring_snapshot_performance_test.dart` : convertir les volumes max de snapshot/revalidation/recovery en budgets gelés.
- `packages/map_editor/test/event_registry_persistence_performance_test.dart` : convertir write/recovery 100 journaux en budgets gelés.
- `reports/narrativeStudio/completion/nsc_74_large_project_performance_evidence_pack.md` : profil machine, baselines, budgets, régression relative, preuves et limites.

Non-objectifs : aucun changement de schema, aucune cache globale mutable, aucune optimisation de rendu hors dépassement mesuré, aucune prétention AOT à partir de mesures JIT.

### Task 1: Baseline de l'index de dépendances

**Files:**
- Create: `packages/map_core/test/narrative_dependency_index_performance_test.dart`

- [ ] **Step 1: écrire le test de caractérisation déterministe**

Créer 10 000 `NarrativeFactDefinition`, construire le `ProjectManifest`, puis mesurer 5 warmups et 20 itérations de `buildNarrativeDependencyIndex`. À chaque run, vérifier `definitions.length == 10000`, les lookups `fact_00000`/`fact_09999` et un checksum stable basé sur `key.id`.

- [ ] **Step 2: prouver la mutation locale**

Créer un second manifest où seul `fact_05000.label` change. Vérifier que les clés, usages et lookups non concernés du nouvel index restent identiques en valeur, que l'ancien index reste inchangé et que la nouvelle définition porte le nouveau label.

- [ ] **Step 3: capturer la baseline puis figer le budget**

Exécuter :

```bash
cd packages/map_core
/Users/karim/develop/flutter/bin/cache/dart-sdk/bin/dart test test/narrative_dependency_index_performance_test.dart -r expanded
```

Imprimer `p50_us`, `p95_us`, checksum, volume, warmups, itérations et environnement. Figer avant le run final un budget arrondi au palier supérieur, au minimum 4 × le p95 accepté, sans le modifier en réponse au run final.

### Task 2: Baseline de la recherche globale

**Files:**
- Create: `packages/map_editor/test/narrative_global_search_performance_test.dart`

- [ ] **Step 1: écrire la fixture 10 000 entrées**

Construire directement des `NarrativeGlobalSearchEntry` déterministes, distribuées entre les kinds, avec labels accentués, IDs stables et tags identiques. Mesurer construction de l'index et requêtes `port selbrume`, `selbrumé` et `rival brume` sur 5 warmups et 20 itérations.

- [ ] **Step 2: vérifier le contrat fonctionnel**

Vérifier ordre stable, limite, filtre, checksum du premier résultat et `response.isStaleComparedTo(newerIndex) == true`.

- [ ] **Step 3: capturer puis figer les budgets build/search**

```bash
cd packages/map_editor
/Users/karim/develop/flutter/bin/flutter test --no-pub test/narrative_global_search_performance_test.dart -r expanded
```

Figer séparément construction et p95 des trois requêtes selon la même politique 4 × baseline arrondie.

### Task 3: Projections de gros workspaces

**Files:**
- Create: `packages/map_editor/test/narrative_large_project_workspace_performance_test.dart`

- [ ] **Step 1: mesurer les projections pures**

Créer quatre tests séparés : `buildNarrativeMapEventsReadModel` avec 100 maps et 1 000 sources/events; `StorylineGraphViewModel.fromProject` avec 10 chapitres × 100 Steps; `buildCinematicsLibraryReadModel` avec 1 000 assets; `buildCinematicTimelineTimeLayoutReadModel` avec 1 000 blocs.

- [ ] **Step 2: vérifier les checksums métier**

Vérifier respectivement les compteurs map/source/event, le nombre de nodes/edges, l'ordre de recherche de la bibliothèque, et `stepCount/blocks/totalDurationMs` de la timeline.

- [ ] **Step 3: mesurer mutation locale et régression relative**

Comparer une fixture 500 et 1 000 éléments et refuser un ratio p95 supérieur à 3,5. Pour la timeline, muter un seul bloc et vérifier que le checksum des 999 IDs non concernés ne change pas.

- [ ] **Step 4: capturer puis figer les budgets**

```bash
cd packages/map_editor
/Users/karim/develop/flutter/bin/flutter test --no-pub test/narrative_large_project_workspace_performance_test.dart -r expanded
```

Figer un budget distinct par projection selon la baseline acceptée ; n'introduire une optimisation produit que si un seuil est dépassé.

### Task 4: Budgets Event existants

**Files:**
- Modify: `packages/map_editor/test/narrative_event_validation_incremental_performance_test.dart`
- Modify: `packages/map_editor/test/narrative_event_authoring_snapshot_performance_test.dart`
- Modify: `packages/map_editor/test/event_registry_persistence_performance_test.dart`

- [ ] **Step 1: conserver le budget Validator historique**

Conserver `36000 µs`, ajouter dans la sortie le nombre total et recalculé, et une assertion explicite que les 497 Events hors closure ne sont pas recalculés.

- [ ] **Step 2: capturer les baselines I/O historiques**

```bash
cd packages/map_editor
/Users/karim/develop/flutter/bin/flutter test --no-pub \
  test/narrative_event_authoring_snapshot_performance_test.dart \
  test/event_registry_persistence_performance_test.dart -r expanded
```

- [ ] **Step 3: figer les volumes maximaux**

Faire retourner le p95 par les helpers, imposer des budgets au volume 500 pour session/revalidation, au volume 100 pour recovery gate/recovery journal, et au write journalisé. Les volumes plus petits restent observés pour la pente.

### Task 5: Gate, Evidence Pack et commit

**Files:**
- Create: `reports/narrativeStudio/completion/nsc_74_large_project_performance_evidence_pack.md`

- [ ] **Step 1: exécuter les tests ciblés séquentiellement**

```bash
cd packages/map_core
/Users/karim/develop/flutter/bin/cache/dart-sdk/bin/dart test test/narrative_dependency_index_performance_test.dart
/Users/karim/develop/flutter/bin/cache/dart-sdk/bin/dart analyze test/narrative_dependency_index_performance_test.dart

cd packages/map_editor
/Users/karim/develop/flutter/bin/flutter test --no-pub \
  test/narrative_global_search_performance_test.dart \
  test/narrative_large_project_workspace_performance_test.dart \
  test/narrative_event_validation_incremental_performance_test.dart \
  test/narrative_event_authoring_snapshot_performance_test.dart \
  test/event_registry_persistence_performance_test.dart
/Users/karim/develop/flutter/bin/flutter analyze --no-pub \
  test/narrative_global_search_performance_test.dart \
  test/narrative_large_project_workspace_performance_test.dart \
  test/narrative_event_validation_incremental_performance_test.dart \
  test/narrative_event_authoring_snapshot_performance_test.dart \
  test/event_registry_persistence_performance_test.dart
```

- [ ] **Step 2: documenter sans extrapoler**

Consigner modèle machine, OS, SDK, commit de base, JIT/debug, exécution séquentielle, warmups/itérations, p50/p95, budgets, ratios 500→1 000, checksums, absence ou présence d'optimisation, limites AOT et variance.

- [ ] **Step 3: auto-revue**

Vérifier couverture de l'ensemble NSC-74, absence de marqueur d'attente, budgets définis avant le run final, `git diff --check`, fichiers exacts et état Git.

- [ ] **Step 4: commit isolé**

```bash
git add docs/superpowers/plans/2026-07-21-nsc-74-large-project-performance.md \
  packages/map_core/test/narrative_dependency_index_performance_test.dart \
  packages/map_editor/test/narrative_global_search_performance_test.dart \
  packages/map_editor/test/narrative_large_project_workspace_performance_test.dart \
  packages/map_editor/test/narrative_event_validation_incremental_performance_test.dart \
  packages/map_editor/test/narrative_event_authoring_snapshot_performance_test.dart \
  packages/map_editor/test/event_registry_persistence_performance_test.dart \
  reports/narrativeStudio/completion/nsc_74_large_project_performance_evidence_pack.md
git commit -m "test(narrative): enforce large project performance budgets"
```

## Self-review

- Couverture : index, search, Validator, Map Events, Storyline, Library, timeline et I/O Event ont chacun une fixture, une métrique, un checksum et un owner.
- Placeholders : aucun marqueur d'attente ou comportement non défini n'est laissé à l'implémentation.
- Cohérence : les tailles 10 000/1 000 et le protocole séquentiel reprennent exactement NSC-00 ; les budgets sont gelés après baseline mais avant gate finale.
