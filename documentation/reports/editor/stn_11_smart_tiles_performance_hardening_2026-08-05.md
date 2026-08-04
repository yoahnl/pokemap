# STN-11 — Durcissement des performances Smart Tiles

Date de clôture : 2026-08-05
Verdict : **DONE** pour STN-11.1, STN-11.2 et STN-11.3.

## 1. Résumé exécutif

STN-11 fournit désormais une chaîne reproductible complète pour mesurer et
protéger les grandes cartes Smart Tiles riches de 128² à 1024² : fixture
déterministe, receipts core/authoring/editor/runtime, profils de chargement et
de navigation, budgets de travail portables, baseline temporelle liée à une
machine cible, vérificateur CLI et campagne locale ERW sans persistance des
fichiers achetés.

Le résultat principal est mesuré : les opérations plein champ croissent avec la
surface, mais le travail de navigation éditeur/runtime reste constant entre
128² et 1024² pour un viewport identique. Aucun nouveau modèle, format projet ou
contrat d'authoring n'a été ajouté par STN-11.

## 2. Scope confirmé

| Lot | Cible | Verdict |
|---|---|---|
| STN-11.1 | Générateur riche 128²–1024², benchmarks core/authoring, p50/p95/max, RSS, checksums et work counts | DONE |
| STN-11.2 | Profils éditeur/runtime, culling viewport, caches et index bornés | DONE |
| STN-11.3 | Baseline cible, budgets anti-régression, vérificateur et campagne ERW locale | DONE |

Non-objectifs conservés : aucun asset ERW dans Git, aucune dépendance runtime à
Tiled, aucune augmentation de la limite de requête authoring par défaut, aucun
seuil temporel générique imposé aux runners CI hétérogènes.

## 3. Audit initial

L'audit de départ a établi les points suivants :

- le resolver core acceptait déjà un viewport, mais sans receipt combinant les
  terrains, chemins, motifs, forêts, objets fractionnaires, animations et
  collisions sur quatre tailles ;
- l'éditeur bornait une partie du travail visible, mais rescannait encore des
  strokes de motifs et des objets, et dessinait toutes les lignes de grille ;
- le runtime n'exposait pas les phases de chargement ni le travail exact d'une
  première frame et d'une frame stable ;
- aucun budget versionné ni vérificateur ne séparait régression algorithmique
  portable et régression temporelle propre à une machine ;
- les portes ERW existaient séparément, sans commande unique ni contrôle
  explicite de l'état Git avant/après ;
- pendant la première campagne 1024², le harness authoring a rencontré la
  limite interactive de 1 MiB avant toute mesure. Le composition root permet
  maintenant d'injecter des `AuthoringSecurityLimits`, tandis que la valeur par
  défaut reste strictement inchangée. Seul le benchmark demande une limite
  finie calculée depuis son fixture synthétique.

État Git initial : `main` pointait sur `ff60aafc9`; des modifications Avelune
préexistantes et le rapport d'audit Smart Tiles non suivi étaient déjà présents.
Ces fichiers n'appartenaient pas au scope et n'ont jamais été stagés par les
commits STN-11.

## 4. Changements par fichier

### STN-11.1 — commit `86dfff6db`

| Fichier | Zones | Raison et impact |
|---|---|---|
| `tools/performance/benchmark_support.dart` | `percentileFields` | Ajout de `maxUs` au schéma commun des receipts. |
| `tools/performance/smart_tiles_rich_map_fixture.dart` | `SmartTilesRichMapFixture`, générateur et catalogue riche | Fixture stable couvrant trois couches Smart Tile, motifs, D4, objets, collisions, éléments et animations. |
| `packages/map_core/benchmark/smart_tiles_rich_map_scaling.dart` | CLI, profils génération/résolution/édition/JSON | Mesures 128²–1024² avec checksums, p50/p95/p99/max et RSS. |
| `packages/map_core/test/benchmark/smart_tiles_rich_map_fixture_test.dart` | invariants de fixture | Prouve contenu riche, tailles et checksum déterministe. |
| `packages/map_core/test/benchmark/smart_tiles_rich_map_scaling_cli_test.dart` | contrat CLI/receipt | Prouve schéma, profils, work counts et confinement du chemin de sortie. |
| `packages/map_authoring/benchmark/smart_tiles_rich_authoring_scaling.dart` | import TMX synthétique, crash et recovery | Mesure plan/apply/reopen/recovery et journaux durables. |
| `packages/map_authoring/test/benchmark/smart_tiles_rich_authoring_scaling_cli_test.dart` | contrat CLI/receipt | Prouve transaction, réouverture et récupération. |

### STN-11.2 — commit `0bfe01dbf`

| Fichier | Zones | Raison et impact |
|---|---|---|
| `packages/map_core/lib/src/operations/smart_tile_layer_visual_resolver.dart` | `SmartTileLayerVisualBatch`, work counts, `SmartTilePatternOwnerIndex` | Résolution viewport instrumentée et index de motifs construit une fois. |
| `packages/map_core/lib/src/operations/map_placed_tile_visual_resolver.dart` | batch, `MapPlacedTileVisualIndex`, cache de définitions | Candidats spatiaux et cache borné sans changer l'API historique. |
| `packages/map_core/test/map_placed_tile_visual_index_test.dart` | index/caches | Parité exacte et travail constant 128²/1024². |
| `packages/map_core/test/smart_tiles/smart_tile_layer_visual_work_counts_test.dart` | batch/work counts | Parité de rendu et absence de scan plein champ. |
| `packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart` | snapshot de culling, Expando caches, grille visible | Index réutilisés par identité de couche/manifest et lignes limitées au viewport. |
| `packages/map_editor/test/ui/world_map/world_map_large_map_performance_test.dart` | tests Smart Tiles riches | Travail égal 128²/1024² et caches bornés. |
| `packages/map_runtime/lib/map_runtime.dart` | exports de profiling | Rend le profil de chargement consommable. |
| `packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart` | `RuntimeMapBundleLoadProfile` | Décompose manifest, map, catalogue, tilesets, bordures et total. |
| `packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart` | `MapLayersRenderProfile`, index spatiaux et caches | Première/stable frame instrumentées, collisions/objets/éléments/entités culled. |
| `packages/map_runtime/test/map_layers_component_performance_profile_test.dart` | profil 128²/1024² | Prouve travail visible constant et capacités de caches respectées. |
| `packages/map_runtime/test/runtime_map_bundle_load_profile_test.dart` | phases de chargement | Prouve l'émission et la cohérence de chaque phase. |

### STN-11.3 — commit contenant ce rapport

| Fichier | Zones | Raison et impact |
|---|---|---|
| `packages/map_authoring/lib/src/api/local_map_authoring_mutation_api.dart` | constructeur et `_LocalMapAuthoringSession.open` | Injection optionnelle de limites ; défaut de sécurité inchangé. |
| `packages/map_authoring/benchmark/smart_tiles_rich_authoring_scaling.dart` | composition du benchmark | Limite finie propre au fixture afin de mesurer réellement 1024². |
| `tools/performance/smart_tiles_performance_policy.dart` | budgets éditeur/runtime et violations | Gate CI portable fondé sur le travail, pas sur l'horloge. |
| `tools/performance/smart_tiles_performance_baseline.dart` | `verifySmartTilesPerformanceBaseline` | Vérifie identités, présence des quatre tailles, work counts et timings opt-in. |
| `tools/performance/verify_smart_tiles_performance.dart` | CLI | Agrège plusieurs receipts et retourne des codes de sortie stables. |
| `tools/performance/baselines/smart_tiles_m1_pro_macos27.json` | cible, mesures et budgets | Baseline M1 Pro/macOS 27, marge temporelle 1,5× et RSS observée. |
| `tools/performance/run_stn11_erw_campaign.sh` | campagne 4 étapes | Dérive TMX/TSX/PNG depuis `POKEMAP_ERW_ROOT` et compare Git avant/après. |
| `packages/map_core/test/benchmark/smart_tiles_performance_policy_test.dart` | politique portable | Prouve compteurs manquants et dépassements. |
| `packages/map_core/test/benchmark/smart_tiles_performance_baseline_test.dart` | baseline/vérificateur | Prouve identité, budgets, target gate et couverture des quatre harnesses. |
| `packages/map_core/test/benchmark/verify_smart_tiles_performance_cli_test.dart` | CLI | Prouve succès portable et échec temporel déterministe. |
| `packages/map_editor/tool/performance/smart_tiles_rich_editor_scaling_test.dart` | first paint/navigation | Produit le receipt éditeur sur cinq positions/zooms. |
| `packages/map_editor/test/ui/world_map/world_map_large_map_performance_test.dart` | budget portable | Branche le snapshot réel sur la politique CI. |
| `packages/map_runtime/tool/performance/smart_tiles_rich_runtime_scaling_test.dart` | load/build/frame/navigation | Produit le receipt runtime et les sous-phases de chargement. |
| `packages/map_runtime/test/map_layers_component_performance_profile_test.dart` | budget portable | Branche la frame réelle sur la politique CI. |
| `documentation/reports/editor/stn_11_smart_tiles_performance_hardening_2026-08-05.md` | présent document | Evidence Pack consolidé et reproductible. |

## 5. Baseline cible et résultats

Machine : Apple M1 Pro, 32 Gio, macOS 27.0 build 26A5378n. Dart pur
3.12.1 arm64 ; Flutter 3.46.0-0.3.pre/Flame 1.37.0 avec `flutter_tester`
x64. Les receipts indiquent `treeState=dirty` car les changements STN-11.3 et
des travaux Avelune indépendants étaient présents ; leurs fingerprints sont
conservés dans la baseline.

### Valeurs 1024² représentatives

| Profil | p50 | p95/max de la campagne |
|---|---:|---:|
| Core full-field resolve | 34,851 s | 35,045 s |
| Core viewport resolve, 24×18 | 15,274 ms | 15,536 ms |
| Core JSON round-trip | 485,523 ms | 501,941 ms |
| Authoring plan | 2,276 s | 2,345 s |
| Authoring apply | 7,408 s | 7,501 s |
| Authoring reopen | 1,683 s | 1,683 s |
| Authoring recovery après crash | 10,318 s | 10,318 s |
| Éditeur first paint | 49,025 ms | 57,622 ms |
| Éditeur navigation stable | 44,217 ms | 72,226 ms |
| Runtime bundle load | 333,363 ms | 335,479 ms |
| Runtime first frame | 22,998 ms | 23,087 ms |
| Runtime navigation stable | 20,389 ms | 20,941 ms |

Le travail éditeur maximal est identique sur les quatre tailles : 1792 cellules
visibles, 2100 visites de tiles, 1792 collisions, 11620 propriétaires Smart
Tile, 2 objets candidats et 4 définitions en cache. Le runtime reste également
identique : 960 cellules visibles, 1025 visites de tiles, 960 collisions, 3100
propriétaires, 2 objets, 2 éléments placés, 3 entrées de cache régulier et 4
entrées de cache objet.

RSS observée aux points d'échantillonnage : core 603734016 octets au maximum,
authoring 860618752, éditeur 429293568, runtime 520192000. Il ne s'agit pas d'un
pic OS instrumenté, mais de snapshots RSS reproductibles après les samples.

## 6. Politique de non-régression

- CI portable : checksums/identités et plafonds de work counts, toujours actifs
  dans les tests éditeur/runtime et via le vérificateur.
- Temps : contrôle uniquement avec
  `--enforce-time m1-pro-32gb-macos27-flutter3460-beta`.
- Marge : chaque plafond temporel est le p95 mesuré multiplié par 1,5 puis
  arrondi vers le haut.
- Une baseline doit être mise à jour intentionnellement si le fixture, la cible
  ou le toolchain change ; un changement silencieux de checksum échoue.

Commande de vérification :

```bash
dart tools/performance/verify_smart_tiles_performance.dart \
  --baseline tools/performance/baselines/smart_tiles_m1_pro_macos27.json \
  --receipt packages/map_core/build/performance/stn11_core_target.json \
  --receipt packages/map_authoring/build/performance/stn11_authoring_target.json \
  --receipt packages/map_editor/build/performance/stn11_editor_target.json \
  --receipt packages/map_runtime/build/performance/stn11_runtime_target.json \
  --enforce-time m1-pro-32gb-macos27-flutter3460-beta
```

Résultat frais : `{"status":"pass","receiptCount":4,"timingGate":true}`.

## 7. Campagne ERW locale

Commande reproductible, sans chemin machine dans Git :

```bash
POKEMAP_ERW_ROOT=/chemin/local/ERW \
  tools/performance/run_stn11_erw_campaign.sh
```

Inventaire observé : 38 TSX, 24 TMX, 5823 PNG. Résultats : corpus TMX PASS,
quatre image collections/1318 définitions et réouverture durable PASS, Wang
atlas PASS, projection arbre en canopée/tronc/collision PASS. Le script a
confirmé un état Git strictement identique avant et après.

## 8. Tests, analyses et build

| Commande | Résultat exact utile |
|---|---|
| `dart test test/benchmark` dans `map_core` | exit 0, 16 tests passés |
| `dart analyze` dans `map_core` | exit 0, `No issues found!` |
| `dart test test/benchmark` dans `map_authoring` | exit 0, 4 tests passés |
| `dart analyze` dans `map_authoring` | exit 0, `No issues found!` |
| `flutter test test/ui/world_map/world_map_large_map_performance_test.dart` | exit 0, 9 tests passés |
| `flutter analyze` dans `map_editor` | exit 0, `No issues found!` |
| `flutter build macos --debug` dans `map_editor` | exit 0, `Built build/macos/Build/Products/Debug/PokeMap.app` |
| `flutter test test/map_layers_component_performance_profile_test.dart test/runtime_map_bundle_load_profile_test.dart` | exit 0, 2 tests passés |
| `flutter analyze` dans `map_runtime` | exit 0, `No issues found!` |
| analyse des trois outils Dart de politique/baseline/CLI | exit 0, `No issues found!` |
| `bash -n tools/performance/run_stn11_erw_campaign.sh` | exit 0 |
| vérificateur des quatre receipts avec timing cible | exit 0, PASS |
| campagne ERW via `POKEMAP_ERW_ROOT` | exit 0, quatre étapes PASS, Git inchangé |
| `npm test` dans `tools/pokemap_mcp` | exit 0, build TypeScript puis 32/32 tests passés |
| appel live `pokemap_describe` | `ok: true`; ressources et actions Smart Tiles présentes |
| `POKEMAP_MARKDOWN_MAX_NEW=2 bash tools/scripts/check_markdown_hygiene.sh` | exit 0 ; ce rapport et l'audit utilisateur préexistant sont tous deux dans un emplacement canonique |

La compilation macOS debug de l'éditeur a réussi. Le build TypeScript MCP a été
exécuté par `npm test` et a également réussi.

## 9. Parité PokeMap MCP

STN-11 modifie les instruments de mesure et l'implémentation interne du rendu,
pas les sémantiques d'une action. Aucune nouvelle action MCP n'est requise. Les
tests MCP ont néanmoins prouvé les transports Smart Tiles/Tiled existants et le
catalogue live expose toujours les ressources `smartTile*`, les imports Tiled et
les actions de peinture canonique.

## 10. Passes de review et auto-critique

Aucun sub-agent n'a été utilisé : l'orchestration parallèle n'était pas
autorisée pour ce tour. Trois passes locales ont été réalisées : audit des
contrats et limites, revue du diff sécurité/performance, puis vérification
indépendante des receipts et de l'absence d'assets suivis.

Risques et limites conservés :

- la baseline est JIT/`flutter_tester`, pas un profil AOT GPU de l'application
  desktop ; elle protège surtout les tendances et le travail algorithmique ;
- 3 à 5 échantillons suffisent pour une baseline de lot mais pas pour une étude
  statistique longue ; le headroom 1,5× absorbe le bruit observé ;
- la résolution core plein champ à 1024² reste coûteuse (~35 s). La navigation
  ne l'appelle pas, mais une future optimisation des opérations bulk est
  recommandée ;
- la limite authoring interactive de 1 MiB reste intentionnellement en place.
  Un futur transport d'import très volumineux devrait référencer un artefact
  TMX stagé plutôt qu'augmenter globalement cette limite ;
- les receipts bruts restent sous `build/performance/` et ne sont pas suivis.
  La baseline versionnée conserve les identités, budgets, RSS et métadonnées
  nécessaires sans stocker les longs tableaux de samples.

## 11. État Git de clôture

Avant le commit STN-11.3, `git diff --check` est propre. Le scope à committer est
strictement constitué des fichiers STN-11.3 listés en section 4. Les
modifications et assets Avelune, ainsi que le rapport d'audit source
`smart_tiles_tiled_imports_and_performance_audit_2026-08-04.md`, restent
hors staging et appartiennent à l'utilisateur.

Prochaine étape proposée, non implémentée : profiler en mode release/AOT sur le
desktop cible, puis concevoir un import TMX volumineux par artifact handle si la
limite interactive de 1 MiB devient un cas utilisateur réel.
