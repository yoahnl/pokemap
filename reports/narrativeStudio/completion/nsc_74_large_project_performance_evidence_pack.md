# NSC-74 — Performance et budgets gros projet

Date : 2026-07-21

Statut proposé : **DONE**

## Audit initial et verdict

L'audit a retrouvé un budget Validator Event V2 déjà figé à 36 ms, mais les
mesures snapshot et persistence restaient explicitement informatives. L'index
de dépendances et la recherche globale n'avaient aucune fixture 10 000 entrées ;
Map Events, le graphe Storyline et la timeline n'avaient aucune gate commune à
1 000 éléments. La Cinematics Library possédait une caractérisation 1 000 assets
sans seuil cross-machine.

Le protocole NSC-00 a été appliqué avant le run final : fixture déterministe,
exécution séquentielle, warmups, p50/p95, checksum, baseline acceptée puis budget
numérique figé. Aucun cache ou mécanisme de virtualisation produit n'a été ajouté,
car les premières mesures respectent les budgets avec une pente 500→1 000 sous
3,5×. Le lot reste donc purement préventif et n'introduit aucun état mutable.

Aucun sub-agent n'a été lancé conformément à l'instruction active. Les passes
manuelles Audit/Architecture, Fixtures, Baselines, Budgets, Déterminisme,
Mutation locale, Tests, Analyse et Critique sont **GO**. La passe Build UI globale
reste **INCONCLUSIVE ENVIRONNEMENT** : le SDK local Flutter 3.41.6 est antérieur
aux API Flutter 3.44 déjà présentes dans des workspaces hors de ce lot.

## Profil reproductible

| Champ | Valeur |
|---|---|
| Commit de base | `1cb16ec7d475` |
| Machine | MacBookPro18,3, Apple M1 Pro, 10 cœurs, 32 Go, arm64 |
| OS | macOS 27.0, build 26A5378n |
| Flutter | 3.41.6 stable, debug test/JIT |
| Dart | 3.11.4 stable, JIT |
| Exécution | séquentielle, aucun test de performance concurrent |
| Index/search | 5 warmups, 20 itérations |
| Gros workspaces | 3 warmups, 10 itérations |
| Validator Event | 10 warmups, 50 itérations |
| I/O Event | warmup 1 quand applicable, 5 ou 7 itérations |
| AOT/profile/release | non mesuré, aucune extrapolation |

## Baselines et budgets figés

Les budgets ont été définis après le premier run accepté et avant le run final.
La règle est au moins quatre fois le p95 observé, arrondi à une borne lisible ;
un plancher protège les opérations très courtes du bruit des machines/CI.

| Surface / fixture | Premier p95 accepté | Run final p95 | Budget p95 figé | Résultat |
|---|---:|---:|---:|---|
| Dependency index, 10 000 Facts | 19 468 µs | 20 015 µs | 80 000 µs | GO |
| Search index construction, 10 000 entrées | 79 µs | 65 µs | 20 000 µs | GO |
| Search exacte | 51 351 µs | 48 145 µs | 220 000 µs | GO |
| Search accentuée | 49 680 µs | 47 218 µs | 220 000 µs | GO |
| Search fuzzy | 51 825 µs | 48 628 µs | 220 000 µs | GO |
| Map Events, 100 maps / 1 000 Events | 747 218 µs | 505 059 µs | 3 000 000 µs | GO |
| Graphe Storyline, 10 chapitres / 1 000 Steps | 3 297 µs | 3 141 µs | 20 000 µs | GO |
| Cinematics Library, 1 000 assets + filtre | 5 295 µs | 5 518 µs | 30 000 µs | GO |
| Timeline, 1 000 blocs | 972 µs | 1 010 µs | 10 000 µs | GO |
| Validator incrémental, 500 Events | 11 610 µs | 11 641 µs | 36 000 µs historique | GO |
| Snapshot prepare, 500 maps | 307 123 µs | 315 394 µs | 1 250 000 µs | GO |
| Revalidation snapshot, 500 maps | 175 572 µs | 173 301 µs | 750 000 µs | GO |
| Recovery gate, 100 journaux | 95 897 µs | 100 608 µs | 400 000 µs | GO |
| Écriture journalisée | 39 454 µs | 41 128 µs | 180 000 µs | GO |
| Recovery, 100 journaux | 238 364 µs | 313 202 µs | 1 000 000 µs | GO |

## Régression relative, déterminisme et mutation locale

| Preuve | Valeur finale | Verdict |
|---|---:|---|
| Map Events 500→1 000 | 2,40× | GO, sous 3,5× |
| Graphe Storyline 500→1 000 | 1,64× | GO |
| Cinematics Library 500→1 000 | 1,25× | GO |
| Timeline 500→1 000 | 0,08×, p95 500 perturbé par un outlier | GO temporel, ratio non interprété comme accélération |
| Index checksum | 49 995 000 | stable |
| Search checksum | 15 000 | stable, même cible exact/accent/fuzzy |
| Map Events checksum | 2 100 | 1 100 sources + 1 000 Events |
| Cinematics checksum | 249 500 | ordre/résultats stables |
| Validator mutation locale | 3 recalculés, 497 non concernés | GO |
| Timeline mutation locale | 999 IDs non concernés inchangés | GO |
| Réponse search stale | rejetée contre revision 75 | GO |

Le ratio timeline n'est pas présenté comme un gain réel : le p95 de la fixture
500 a subi une pause JIT/GC de 12 253 µs alors que la fixture 1 000 a mesuré
1 010 µs. Le budget absolu et le checksum portent la décision ; le ratio reste
consigné honnêtement.

## Critères NSC-74

| Critère | Preuve | Verdict |
|---|---|---|
| Fixtures NSC-00 | 10 000 index/search, 1 000 Events/Steps/Cinematics/blocs | GO |
| Index et recherche | p50/p95, checksums, accents/fuzzy/stale | GO |
| Validator | équivalence full, closure locale, budget 36 ms | GO |
| Map Events | 100 maps, 1 000 Events liés, aucun orphan/unassigned | GO |
| Storyline graph | 1 011 nodes, 1 000 Steps, edges projetés | GO |
| Cinematics Library | 1 000 assets, 500 résultats, tri stable | GO |
| Timeline | 1 000 blocs, durée 100 000 ms, mutation stable | GO |
| Persistence/recovery | seuils figés aux volumes maximaux | GO |
| Cache/virtualisation | profilage ne justifie pas de mutation produit | GO, non requis |
| Reproductibilité | profil, mode, warmups, itérations et sorties versionnés | GO |

## Fichiers modifiés

- `packages/map_editor/test/narrative_event_validation_incremental_performance_test.dart`
- `packages/map_editor/test/narrative_event_authoring_snapshot_performance_test.dart`
- `packages/map_editor/test/event_registry_persistence_performance_test.dart`

## Fichiers créés

- `docs/superpowers/plans/2026-07-21-nsc-74-large-project-performance.md`
- `packages/map_core/test/narrative_dependency_index_performance_test.dart`
- `packages/map_editor/test/narrative_global_search_performance_test.dart`
- `packages/map_editor/test/narrative_large_project_workspace_performance_test.dart`
- `reports/narrativeStudio/completion/nsc_74_large_project_performance_evidence_pack.md`

Le contenu complet des fichiers créés est versionné dans le commit du lot.
Le micro-plan est ajouté explicitement malgré la règle historique `/docs/*` du
`.gitignore`. Aucun cache, lockfile ou artefact machine n'est inclus.

## Zones précises et décisions

### Index et recherche

- L'index est construit avec 10 000 définitions réelles du manifest, et pas une
  boucle artificielle sur une fonction vide.
- La recherche utilise 10 000 entrées immuables et mesure chaque famille de
  requête séparément. Ordre, filtre, limite et revision stale sont vérifiés.
- La mutation locale reconstruit un snapshot immuable et prouve que les lectures
  non concernées restent identiques en valeur ; aucune cache globale n'est créée.

### Workspaces

- Map Events compose le catalogue spatial réel et le read model Event V2 sur
  100 maps, 1 000 NPC et 1 000 Events exactement liés.
- Le graphe Storyline passe par `StorylineGraphViewModel.fromProject`, donc la
  projection Core et l'adaptation Editor sont toutes deux dans la mesure.
- La Cinematics Library inclut build, filtre et tri ; la timeline inclut lanes,
  blocks, ticks et durée, sans pomper un arbre widget non virtualisé.

### Event V2 historique

- Le seuil Validator 36 ms est conservé byte-for-byte ; le lot ajoute la preuve
  explicite des 497 Events épargnés.
- Les anciennes sorties `informative_only`/`unconfigured` deviennent des seuils
  `frozen` uniquement aux volumes maximaux. Les petits volumes restent des points
  de pente et ne sont pas maquillés en budgets.

## Commandes et résultats exacts

### RED observé

```text
flutter test --no-pub test/narrative_large_project_workspace_performance_test.dart
Compilation failed: SceneNode/SceneEdge non const et type legacy claim erroné.
```

Le test a ensuite utilisé les constructeurs réels non const et l'inférence du
contrat `legacyClaims`; aucune assertion métier n'a été retirée.

### Core final

```text
cd packages/map_core
dart test test/narrative_dependency_index_performance_test.dart -r expanded
+2: All tests passed!
NSC_74_DEPENDENCY_INDEX ... p50_us=8954 p95_us=20015 ...
budget_p95_us=80000 threshold=frozen

dart analyze test/narrative_dependency_index_performance_test.dart
No issues found!
```

### Editor final, exécutions séquentielles séparées

```text
cd packages/map_editor
flutter test --no-pub test/narrative_global_search_performance_test.dart -r expanded
+1: All tests passed!
build_p95_us=65 exact_p95_us=48145 accent_p95_us=47218 fuzzy_p95_us=48628

flutter test --no-pub test/narrative_large_project_workspace_performance_test.dart -r expanded
+4: All tests passed!
map_events p95_us=505059 ratio=2.40
storyline_graph p95_us=3141 ratio=1.64
cinematics_library p95_us=5518 ratio=1.25
cinematic_timeline p95_us=1010 ratio=0.08

flutter test --no-pub test/narrative_event_validation_incremental_performance_test.dart -r expanded
+2: All tests passed!
p95_us=11641 recalculated=3 unaffected=497 budget_p95_us=36000

flutter test --no-pub test/narrative_event_authoring_snapshot_performance_test.dart -r expanded
+1: All tests passed!
volume=500 session_prepare p95_us=315394 budget_p95_us=1250000
volume=500 final_map_revalidation_workload p95_us=173301 budget_p95_us=750000
volume=100 recovery_gate_scan p95_us=100608 budget_p95_us=400000

flutter test --no-pub test/event_registry_persistence_performance_test.dart -r expanded
+1: All tests passed!
journaled_write p95_us=41128 budget_p95_us=180000
recovery_scan volume=100 p95_us=313202 budget_p95_us=1000000

flutter analyze --no-pub \
  test/narrative_global_search_performance_test.dart \
  test/narrative_large_project_workspace_performance_test.dart \
  test/narrative_event_validation_incremental_performance_test.dart \
  test/narrative_event_authoring_snapshot_performance_test.dart \
  test/event_registry_persistence_performance_test.dart
No issues found! (ran in 2.0s)
```

## Risques, limites et auto-critique

- Map Events est de loin le chemin le plus coûteux (~505 ms p95 sur cette
  machine). Le budget de 3 s détecte une catastrophe, pas une micro-régression ;
  la pente 2,40× doit rester surveillée avant d'augmenter la fixture.
- Les budgets muraux varient selon CPU, charge, JIT, filesystem et antivirus.
  Les marges 4× et checksums réduisent le bruit sans en faire des benchmarks AOT.
- La timeline et le graphe mesurent les projections qui nourrissent l'UI, pas le
  coût raster complet d'une fenêtre native à 1 000 éléments.
- L'I/O emploie des répertoires temporaires locaux ; une CI distante ou chiffrée
  pourra approcher les plafonds plus vite.
- Aucune optimisation n'est ajoutée par anticipation. Si Map Events dépasse le
  budget, le prochain travail devra profiler catalogue spatial et projection
  Event séparément avant d'introduire une cache avec invalidation.
- La suite Flutter globale n'est pas déclarée verte avec le SDK local ancien ;
  seuls les fichiers ciblés, qui ne chargent pas les API incompatibles, le sont.

État Git initial : propre après `1cb16ec7`. État avant commit : uniquement le
micro-plan, les tests et cet Evidence Pack NSC-74. `git diff --check` est propre.
