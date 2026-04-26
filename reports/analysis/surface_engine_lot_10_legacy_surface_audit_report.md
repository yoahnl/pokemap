# Surface Engine Lot 10 — Legacy Surface Audit Report V0

## 1. Résumé exécutif

Le Lot 10 ajoute un point d'entrée pur dans `map_core` pour produire un rapport d'audit legacy Surface à partir d'un `ProjectManifest` et d'un ensemble de `MapData`.

L'API ajoutée est `createLegacySurfaceAuditReport(...)`. Elle assemble les briques existantes sans les réinterpréter :

- `createLegacyProjectSurfaceCatalogView(...)` pour inventorier les surfaces legacy déclarées.
- `createLegacyProjectSurfaceUsageView(...)` pour inventorier les usages réels dans les maps.
- `diagnoseLegacySurfaceCatalog(...)` pour les diagnostics du catalogue.
- `diagnoseLegacySurfaceUsage(...)` pour les diagnostics d'usage.
- `LegacySurfaceAuditSummary` pour les compteurs de synthèse.

Ce lot ne crée aucun modèle persistant `SurfaceDefinition`, aucun `SurfaceEngine`, aucun JSON, aucune migration, aucune vue unifiée terrain/path, et ne modifie pas les modèles existants.

## 2. Pourquoi ce lot est nécessaire après le Lot 9

Les Lots 4 à 9 ont créé des briques séparées :

- adaptateurs read-only pour les path presets ;
- adaptateurs read-only pour les terrain presets ;
- catalogue read-only au niveau manifest ;
- diagnostics du catalogue ;
- vue d'usage réelle dans les maps ;
- diagnostics d'usage.

Le Lot 10 évite que les prochains lots Surface Engine aient à recoller manuellement ces briques à chaque fois. Il fournit un snapshot unique, purement en mémoire, qui répond aux questions de pré-migration :

- quelles surfaces legacy sont déclarées ;
- quelles surfaces legacy sont réellement utilisées ;
- quels risques existent côté catalogue ;
- quels risques existent côté usages réels ;
- combien d'éléments et de warnings sont présents.

Ce rapport reste volontairement non persistant pour ne pas figer trop tôt le futur modèle `Surface`.

## 3. Fichiers consultés

- `packages/map_core/lib/src/operations/legacy_project_surface_catalog_view.dart`
- `packages/map_core/lib/src/operations/legacy_surface_catalog_diagnostics.dart`
- `packages/map_core/lib/src/operations/legacy_surface_usage_view.dart`
- `packages/map_core/lib/src/operations/legacy_surface_usage_diagnostics.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/map_data.dart`
- `packages/map_core/lib/src/models/map_layer.dart`
- `packages/map_core/lib/src/models/enums.dart`
- `packages/map_core/lib/map_core.dart`
- `packages/map_core/test/legacy_project_surface_catalog_view_test.dart`
- `packages/map_core/test/legacy_surface_catalog_diagnostics_test.dart`
- `packages/map_core/test/legacy_surface_usage_view_test.dart`
- `packages/map_core/test/legacy_surface_usage_diagnostics_test.dart`

## 4. Fichiers créés

- `packages/map_core/lib/src/operations/legacy_surface_audit_report.dart`
- `packages/map_core/test/legacy_surface_audit_report_test.dart`
- `reports/analysis/surface_engine_lot_10_legacy_surface_audit_report.md`

## 5. Fichiers modifiés

- `packages/map_core/lib/map_core.dart`

Note de contexte worktree : `packages/map_core/lib/map_core.dart` était déjà modifié avant ce lot pour exporter l'API du Lot 9. Dans le périmètre Lot 10, la seule intention ajoutée est l'export de `src/operations/legacy_surface_audit_report.dart`.

## 6. API ajoutée

### `LegacySurfaceAuditReport`

Rapport global read-only contenant :

- `catalog` : `LegacyProjectSurfaceCatalogView`
- `usage` : `LegacyProjectSurfaceUsageView`
- `catalogDiagnostics` : `List<LegacySurfaceCatalogDiagnostic>`
- `usageDiagnostics` : `List<LegacySurfaceUsageDiagnostic>`
- `summary` : `LegacySurfaceAuditSummary`

Getters ajoutés :

- `hasDiagnostics`
- `hasWarnings`
- `hasUsage`

Les listes `catalogDiagnostics` et `usageDiagnostics` sont copiées avec `List.unmodifiable(...)`.

### `LegacySurfaceAuditSummary`

Compteurs ajoutés :

- `terrainSurfaceCount`
- `pathSurfaceCount`
- `terrainUsageCount`
- `pathUsageCount`
- `missingPathUsageCount`
- `catalogDiagnosticCount`
- `catalogWarningCount`
- `usageDiagnosticCount`
- `usageWarningCount`

### `createLegacySurfaceAuditReport(...)`

Signature :

```dart
LegacySurfaceAuditReport createLegacySurfaceAuditReport({
  required ProjectManifest manifest,
  required Iterable<MapData> maps,
})
```

La fonction :

1. crée le catalogue legacy depuis le manifest ;
2. crée la vue d'usage depuis le catalogue et les maps ;
3. exécute les diagnostics catalogue ;
4. exécute les diagnostics usage ;
5. calcule le summary ;
6. retourne un rapport read-only.

## 7. Sémantique du rapport d'audit

Le rapport est un snapshot d'audit :

- il ne mute pas le `ProjectManifest` ;
- il ne mute pas les `MapData` ;
- il ne corrige pas les diagnostics ;
- il ne filtre pas arbitrairement les diagnostics ;
- il ne fusionne pas les familles terrain/path ;
- il ne crée pas de modèle persistant ;
- il ne sérialise rien ;
- il ne dépend pas de Flutter, Flame, éditeur, runtime ou gameplay.

`hasWarnings` vérifie explicitement les deux enums de sévérité existants :

- `LegacySurfaceCatalogDiagnosticSeverity.warning`
- `LegacySurfaceUsageDiagnosticSeverity.warning`

Cela évite de créer une sévérité unifiée avant le futur modèle Surface.

## 8. Liste complète des cas testés

Le fichier `packages/map_core/test/legacy_surface_audit_report_test.dart` couvre :

1. Rapport vide : manifest sans terrain/path presets et `maps: []`.
2. Rapport sain avec usage terrain et usage path résolu.
3. Rapport contenant des diagnostics catalogue et des diagnostics d'usage pour surfaces déclarées non utilisées.
4. Rapport contenant des diagnostics d'usage pour `TerrainType` sans surface déclarée et path preset manquant.
5. Immutabilité de `catalogDiagnostics` et `usageDiagnostics`.
6. Non-mutation du manifest, des maps, des layers et des cellules.
7. Comptage séparé des warnings catalogue et usage.
8. Réutilisation observable des briques existantes : catalogue, usage, diagnostics catalogue, diagnostics usage.

## 9. Ce que les tests prouvent

Les tests prouvent que le rapport :

- assemble les briques existantes au lieu de les réimplémenter ;
- conserve terrain et path séparés ;
- expose les diagnostics sans filtrage ;
- calcule les compteurs de summary depuis les vues et diagnostics produits ;
- distingue correctement les warnings catalogue des warnings usage ;
- expose des listes de diagnostics non mutables ;
- ne modifie pas les objets sources.

Les tests prouvent aussi que le cas sain reste silencieux côté diagnostics, tandis que les cas à risque restent visibles dans le rapport global.

## 10. Ce qui n'a volontairement pas été fait

Ce lot n'a pas :

- créé `SurfaceDefinition` ;
- créé `SurfaceEngine` ;
- créé une vue unifiée `LegacySurfaceView` ;
- ajouté `surfaceDefinitions` dans `ProjectManifest` ;
- modifié `ProjectManifest`, `MapData`, `TerrainLayer`, `PathLayer`, `ProjectTerrainPreset` ou `ProjectPathPreset` ;
- modifié les fichiers generated `.g.dart` ou `.freezed.dart` ;
- lancé `build_runner` ;
- modifié `map_runtime`, `map_editor`, `map_gameplay` ou `map_battle` ;
- branché l'audit dans un runtime ou une UI ;
- créé de JSON ou de migration.

## 11. Impact pour les futurs modèles Surface

Le futur modèle Surface pourra utiliser ce rapport comme point d'entrée d'audit avant migration :

- identifier les surfaces déclarées candidates ;
- identifier les usages réels qui devront être migrés ;
- isoler les presets vides, doublons et usages manquants ;
- calculer une synthèse rapide pour une future UI ou un rapport de compatibilité.

Le rapport rend aussi explicite une limite importante : terrain et path restent deux familles legacy séparées. La future Surface Engine devra décider comment les rapprocher sans perdre les différences métier entre `TerrainType` et `PathSurfaceKind`.

## 12. Points de vigilance

- `LegacySurfaceAuditReport` est un snapshot en mémoire, pas un contrat de persistance.
- Les diagnostics ne sont pas filtrés : un appelant UI devra choisir comment les présenter.
- `hasWarnings` dépend de deux enums distinctes, ce qui est volontaire tant qu'il n'existe pas de modèle Surface commun.
- Les usages terrain restent par `TerrainType`, pas par preset id, conformément au modèle legacy.
- Les usages path résolus restent basés sur les ids et sur la logique du catalogue existant.
- Le rapport ne mesure pas encore l'usage réel des frames, variants ou atlas au niveau rendu ; il agrège les vues legacy déjà disponibles.

## 13. Commandes lancées

Commande TDD rouge initiale :

```bash
cd packages/map_core
/opt/homebrew/bin/dart test test/legacy_surface_audit_report_test.dart
```

Résultat attendu avant implémentation :

```text
Failed to load "test/legacy_surface_audit_report_test.dart":
Error: Type 'LegacySurfaceAuditReport' not found.
Error: Method not found: 'createLegacySurfaceAuditReport'.
```

Note : le tout premier lancement du test a aussi révélé deux helpers de test
typés trop largement en `MapLayer`. Ils ont été corrigés en `TerrainLayer` et
`PathLayer` avant l'implémentation afin que le rouge TDD caractérise uniquement
l'API Lot 10 manquante.

Analyse statique :

```bash
cd packages/map_core
/opt/homebrew/bin/dart analyze \
  lib/src/operations/legacy_surface_audit_report.dart \
  test/legacy_surface_audit_report_test.dart \
  lib/map_core.dart
```

Tests ciblés et régressions :

```bash
cd packages/map_core
/opt/homebrew/bin/dart test test/legacy_surface_audit_report_test.dart
/opt/homebrew/bin/dart test test/legacy_surface_usage_diagnostics_test.dart
/opt/homebrew/bin/dart test test/legacy_surface_usage_view_test.dart
/opt/homebrew/bin/dart test test/legacy_surface_catalog_diagnostics_test.dart
/opt/homebrew/bin/dart test test/legacy_project_surface_catalog_view_test.dart
/opt/homebrew/bin/dart test test/legacy_terrain_surface_view_test.dart
/opt/homebrew/bin/dart test test/legacy_path_surface_view_test.dart
/opt/homebrew/bin/dart test test/project_manifest_surface_json_characterization_test.dart
/opt/homebrew/bin/dart test test/map_terrain_autotile_characterization_test.dart
/opt/homebrew/bin/dart test test/tile_visual_frame_timeline_test.dart
/opt/homebrew/bin/dart test test/legacy_editor_json_compat_collision_test.dart
/opt/homebrew/bin/dart test test/element_collision_profile_pixel_mask_json_test.dart
/opt/homebrew/bin/dart test
```

Formatage :

```bash
cd packages/map_core
/opt/homebrew/bin/dart format \
  lib/src/operations/legacy_surface_audit_report.dart \
  test/legacy_surface_audit_report_test.dart \
  lib/map_core.dart
```

Commandes Git lecture uniquement :

```bash
git status --short
git diff --stat
git diff -- packages/map_core/lib/src/operations/legacy_surface_audit_report.dart packages/map_core/test/legacy_surface_audit_report_test.dart packages/map_core/lib/map_core.dart
```

## 14. Résultats exacts des tests

Analyse statique :

```text
Analyzing legacy_surface_audit_report.dart, legacy_surface_audit_report_test.dart, map_core.dart...
No issues found!
```

Tests ciblés :

```text
test/legacy_surface_audit_report_test.dart: +8: All tests passed!
test/legacy_surface_usage_diagnostics_test.dart: +15: All tests passed!
test/legacy_surface_usage_view_test.dart: +22: All tests passed!
test/legacy_surface_catalog_diagnostics_test.dart: +17: All tests passed!
test/legacy_project_surface_catalog_view_test.dart: +12: All tests passed!
test/legacy_terrain_surface_view_test.dart: +12: All tests passed!
test/legacy_path_surface_view_test.dart: +11: All tests passed!
test/project_manifest_surface_json_characterization_test.dart: +15: All tests passed!
test/map_terrain_autotile_characterization_test.dart: +21: All tests passed!
test/tile_visual_frame_timeline_test.dart: +16: All tests passed!
test/legacy_editor_json_compat_collision_test.dart: +3: All tests passed!
test/element_collision_profile_pixel_mask_json_test.dart: +6: All tests passed!
```

## 15. Total exact du `dart test` complet

Le test complet `map_core` passe avec :

```text
+285: All tests passed!
```

Le prompt mentionnait que le Lot 9 passait avec `+277`. Le total `+285` est cohérent avec l'ajout des 8 tests du Lot 10.

## 16. Autocritique finale

Le lot est volontairement mécanique : il assemble des vues et diagnostics existants. C'est le bon niveau de risque pour un point d'entrée d'audit, mais cela signifie aussi que le rapport hérite directement des limites des lots précédents.

Les tests couvrent les comportements demandés, mais restent centrés sur les compteurs, les codes et l'immuabilité. Ils ne font pas de comparaison profonde exhaustive de chaque champ interne des diagnostics, parce que ces champs sont déjà couverts par les tests des fonctions de diagnostics sous-jacentes.

Le summary ne contient pas encore de compte par sévérité `info`, par famille terrain/path, ou par code. C'est un choix de périmètre : le prompt demandait seulement les compteurs listés.

## 17. Ce que le prompt semble discutable ou incomplet

- Le prompt demande un rapport global, mais ne précise pas si les diagnostics doivent être recalculés à la demande ou stockés comme snapshot. J'ai retenu le snapshot read-only, plus cohérent avec les vues précédentes.
- Le prompt ne demande pas de compteur `info`. Cela pourrait devenir utile plus tard pour une UI d'audit, mais ce lot n'ajoute pas de champ non demandé.
- Le prompt ne précise pas comment traiter un `Iterable<MapData>` non réitérable. La fonction actuelle le passe une seule fois à `createLegacyProjectSurfaceUsageView`, puis travaille sur la vue produite. Elle ne réitère pas `maps`.
- Le prompt demande de réutiliser les briques existantes, mais ne demande pas de garanties d'identité objet entre un rapport et un appel externe fait séparément. Les tests comparent donc les données observables plutôt qu'une égalité profonde d'instances.

## 18. Auto-review indépendante

- Est-ce que le lot est resté strictement limité à un rapport d'audit legacy read-only ? Oui.
- Est-ce qu'aucun modèle Surface persistant n'a été créé ? Oui.
- Est-ce qu'aucune vue unifiée Surface n'a été créée ? Oui.
- Est-ce qu'aucun modèle Freezed/JSON n'a été modifié ? Oui.
- Est-ce qu'aucun fichier generated n'a été modifié ? Oui.
- Est-ce qu'aucun runtime/editor/gameplay n'a été modifié ? Oui.
- Est-ce que `ProjectManifest` n'a pas été modifié ? Oui.
- Est-ce que `MapData` n'a pas été modifié ? Oui.
- Est-ce que le rapport réutilise bien les briques existantes ? Oui : il appelle directement les fonctions des Lots 6, 7, 8 et 9.
- Est-ce que les diagnostics sont conservés sans filtrage arbitraire ? Oui.
- Est-ce que les listes exposées sont non mutables ? Oui, via `List.unmodifiable(...)` et test dédié.
- Est-ce que les tests documentent le comportement actuel plutôt qu'un comportement futur idéal ? Oui.
- Est-ce que les tests des lots précédents passent toujours ? Oui.
- Est-ce que `map_core` complet passe avec un total exact documenté ? Oui, `+285: All tests passed!`.
- Est-ce que les commandes Git interdites n'ont pas été utilisées ? Oui, seulement `git status --short`, `git diff --stat` et `git diff` en lecture.
- Est-ce que le rapport est assez détaillé ? Oui.
- Est-ce que quelque chose du prompt était ambigu ou discutable ? Oui, principalement le choix snapshot vs recalcul et l'absence de compteur `info`, documentés ci-dessus.
