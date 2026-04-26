# Surface Engine Lot 9 - Legacy Surface Usage Diagnostics V0

## 1. Resume executif

Le Lot 9 ajoute une couche pure de diagnostics d'usage legacy dans `map_core`.

La nouvelle API `diagnoseLegacySurfaceUsage(...)` analyse ensemble:

- `LegacyProjectSurfaceCatalogView`, c'est-a-dire les surfaces legacy declarees dans le manifest;
- `LegacyProjectSurfaceUsageView`, c'est-a-dire les usages reels observes dans les maps.

Elle retourne une liste read-only de diagnostics qui documentent les risques de migration lies aux usages reels: terrains utilises sans surface declaree, ambiguites de plusieurs presets terrain pour un meme `TerrainType`, path presets manquants, `presetId == ''`, path presets declares mais jamais utilises, doublons d'id path utilises, et surfaces utilisees sans variants.

Le lot reste strictement non persistant: aucun `SurfaceDefinition`, aucun JSON, aucun Freezed, aucun runtime/editor/gameplay.

## 2. Pourquoi ce lot est necessaire apres le Lot 8

Le Lot 8 sait inventorier les usages reels:

- `TerrainLayer` -> usages par `TerrainType`;
- `PathLayer` -> usages par `presetId`;
- `PathLayer` actifs avec preset inconnu ou vide -> `LegacyMissingPathSurfaceUsage`.

Mais cette vue ne dit pas encore si ces usages sont migrables. Le Lot 9 ajoute cette lecture d'audit:

- est-ce qu'un `TerrainType` utilise a une surface terrain candidate declaree?
- est-ce qu'un `TerrainType` utilise a plusieurs candidats declares?
- est-ce qu'un candidat terrain utilise est vide?
- est-ce qu'un path usage pointe vers un preset absent?
- est-ce qu'un path usage actif a un id vide?
- est-ce qu'un path preset declare n'est jamais utilise?
- est-ce qu'un path id utilise a plusieurs surfaces declarees?
- est-ce qu'une surface path utilisee n'a aucun variant?

Cette etape prepare les futurs lots Surface Engine sans modifier les modeles persistants.

## 3. Fichiers consultes

- `packages/map_core/lib/src/operations/legacy_surface_usage_view.dart`
- `packages/map_core/lib/src/operations/legacy_project_surface_catalog_view.dart`
- `packages/map_core/lib/src/operations/legacy_surface_catalog_diagnostics.dart`
- `packages/map_core/lib/src/operations/legacy_path_surface_view.dart`
- `packages/map_core/lib/src/operations/legacy_terrain_surface_view.dart`
- `packages/map_core/lib/src/models/enums.dart`
- `packages/map_core/lib/map_core.dart`
- `packages/map_core/test/legacy_surface_usage_view_test.dart`
- `packages/map_core/test/legacy_surface_catalog_diagnostics_test.dart`
- `packages/map_core/test/legacy_project_surface_catalog_view_test.dart`
- `reports/analysis/surface_engine_lot_8_review.md`

## 4. Fichiers crees

- `packages/map_core/lib/src/operations/legacy_surface_usage_diagnostics.dart`
- `packages/map_core/test/legacy_surface_usage_diagnostics_test.dart`
- `reports/analysis/surface_engine_lot_9_legacy_surface_usage_diagnostics.md`

## 5. Fichiers modifies

- `packages/map_core/lib/map_core.dart`

Modification unique: export public de `src/operations/legacy_surface_usage_diagnostics.dart`.

## 6. API ajoutee

### `LegacySurfaceUsageDiagnosticSeverity`

```dart
enum LegacySurfaceUsageDiagnosticSeverity {
  info,
  warning,
}
```

### `LegacySurfaceUsageDiagnosticFamily`

```dart
enum LegacySurfaceUsageDiagnosticFamily {
  terrain,
  path,
}
```

### `LegacySurfaceUsageDiagnosticCode`

```dart
enum LegacySurfaceUsageDiagnosticCode {
  usedTerrainTypeWithoutDeclaredSurface,
  declaredTerrainSurfaceWithoutMatchingUsage,
  usedTerrainTypeWithMultipleDeclaredSurfaces,
  missingPathSurfaceUsage,
  emptyPathPresetIdUsage,
  declaredPathSurfaceWithoutUsage,
  usedPathPresetWithMultipleDeclaredSurfaces,
  usedPathSurfaceWithoutVariants,
  usedTerrainSurfaceCandidateWithoutVariants,
}
```

### `LegacySurfaceUsageDiagnostic`

Valeur Dart immutable, non Freezed, non JSON, contenant:

- severity;
- code;
- family;
- message;
- `terrainType`;
- `pathPresetId`;
- `surfaceId`;
- `surfaceName`;
- contexte map/layer;
- detail deterministe.

### `diagnoseLegacySurfaceUsage`

```dart
List<LegacySurfaceUsageDiagnostic> diagnoseLegacySurfaceUsage({
  required LegacyProjectSurfaceCatalogView catalog,
  required LegacyProjectSurfaceUsageView usage,
})
```

La fonction retourne `List.unmodifiable(...)`.

## 7. Semantique des diagnostics d'usage

### Terrain

- Les usages terrain restent par `TerrainType`, car `TerrainLayer` ne stocke pas d'id de `ProjectTerrainPreset`.
- `TerrainType.none` est ignore par securite dans les diagnostics d'usage.
- Un `TerrainType` utilise sans surface declaree produit `usedTerrainTypeWithoutDeclaredSurface`.
- Un `TerrainType` utilise avec plusieurs surfaces declarees produit `usedTerrainTypeWithMultipleDeclaredSurfaces`.
- Une surface terrain declaree sans usage correspondant produit `declaredTerrainSurfaceWithoutMatchingUsage`.
- Une surface terrain candidate vide pour un `TerrainType` utilise produit `usedTerrainSurfaceCandidateWithoutVariants`.

### Path

- Les usages path restent par `PathLayer.presetId`.
- Les usages manquants non vides produisent `missingPathSurfaceUsage`.
- Les usages manquants avec `presetId == ''` produisent `emptyPathPresetIdUsage`.
- Les path surfaces declarees sans usage resolu produisent `declaredPathSurfaceWithoutUsage`.
- Un path id utilise avec plusieurs surfaces declarees produit `usedPathPresetWithMultipleDeclaredSurfaces`.
- Un path usage resolu vers une surface sans variants produit `usedPathSurfaceWithoutVariants`.

### Ordre

L'ordre des diagnostics est deterministe:

1. diagnostics terrain lies aux usages, par premiere apparition des `TerrainType`;
2. diagnostics terrain declares mais non utilises, dans l'ordre du catalogue;
3. diagnostics path manquants, dans l'ordre des usages manquants;
4. diagnostics path utilises avec candidats declares multiples, par premiere apparition de `presetId`;
5. diagnostics path utilises sans variants, dans l'ordre des usages path;
6. diagnostics path declares mais non utilises, dans l'ordre du catalogue.

## 8. Liste complete des cas testes

1. Usage sain: aucun diagnostic.
2. `TerrainType.grass` utilise sans surface declaree.
3. `TerrainType.grass` utilise avec deux surfaces declarees.
4. Surface terrain `sand` declaree sans usage.
5. `TerrainType.rock` utilise avec candidate declaree sans variants.
6. Missing path preset non vide `missing-water`.
7. Missing path preset vide `''`.
8. Path surface declaree `unused-road` sans usage.
9. Path id `water` utilise avec deux surfaces declarees.
10. Path surface utilisee sans variants.
11. Ordre global deterministe des diagnostics.
12. Liste retournee non mutable.
13. Catalogue et usage sources non mutes.
14. Path id duplique mais utilise non considere comme inutilise.
15. Deux surfaces terrain `sand` non utilisees produisent deux diagnostics.

## 9. Ce que les tests prouvent

- L'API diagnostique les usages reels, pas seulement les declarations du catalogue.
- Les terrains restent audites par `TerrainType`.
- Les paths restent audites par `presetId`.
- Les path presets manquants sont diagnostiques sans correction automatique.
- `presetId == ''` reste un cas distinct.
- Les doublons path utilises sont documentes comme ambiguite de migration.
- Les surfaces utilisees sans variants sont signalees comme warnings.
- Les surfaces declarees mais non utilisees restent des infos, pas des erreurs.
- La sortie est non mutable.
- L'ordre des diagnostics est stable.
- Les entrees `catalog` et `usage` ne sont pas mutees.

## 10. Ce qui n'a volontairement pas ete fait

- Pas de `SurfaceDefinition`.
- Pas de `SurfaceEngine`.
- Pas de vue Surface unifiee.
- Pas de champ `surfaceDefinitions` dans `ProjectManifest`.
- Pas de modification de `ProjectManifest`, `MapData`, `TerrainLayer`, `PathLayer`, `ProjectTerrainPreset`, ou `ProjectPathPreset`.
- Pas de JSON.
- Pas de Freezed.
- Pas de `build_runner`.
- Pas de modification de `.g.dart` ou `.freezed.dart`.
- Pas de modification de `map_runtime`, `map_editor`, `map_gameplay`, ou `map_battle`.
- Pas de branchement dans Flame ou dans l'editeur.
- Pas de migration ou auto-correction des donnees legacy.
- Pas de reutilisation ou extension des diagnostics catalogue du Lot 7: les diagnostics d'usage ont leur propre vocabulaire.

## 11. Impact pour les futurs modeles Surface

Ce lot rend visibles les zones de risque avant d'ajouter des modeles persistants:

- les `TerrainType` sans surface candidate devront recevoir une strategie de creation, fallback ou erreur;
- les `TerrainType` avec plusieurs candidates demanderont une politique de resolution;
- les path presets manquants ou vides devront etre traites avant migration;
- les doublons d'id path utilises confirment que le "premier match" legacy est insuffisant pour une migration explicite;
- les surfaces utilisees sans variants devront etre completees ou marquees non migrables;
- les surfaces declarees mais non utilisees pourront etre preservees comme bibliotheque ou retirees plus tard, selon une decision produit.

## 12. Points de vigilance

- Les usages terrain ne permettent toujours pas d'identifier le preset terrain exact qui a servi a peindre une cellule.
- Le diagnostic path reste id-based: si deux path surfaces partagent un id et que cet id est utilise, aucune des deux n'est marquee "unused" dans ce lot.
- Le diagnostic `emptyPathPresetIdUsage` depend de la vue Lot 8: il apparait pour les `LegacyMissingPathSurfaceUsage` avec id vide. Si un catalogue legacy contenait une path surface avec id vide, Lot 8 pourrait la resoudre comme usage path normal; ce cas n'est pas corrige ici.
- Les messages sont destines a l'audit et aux tests, pas a une UI finale localisee.

## 13. Commandes lancees

### Red TDD initial

```bash
cd packages/map_core
/opt/homebrew/bin/dart test test/legacy_surface_usage_diagnostics_test.dart
```

Resultat attendu avant implementation: echec de compilation parce que `LegacySurfaceUsageDiagnostic`, ses enums et `diagnoseLegacySurfaceUsage` n'existaient pas encore.

### Test Lot 9 cible

```bash
cd packages/map_core
/opt/homebrew/bin/dart test test/legacy_surface_usage_diagnostics_test.dart
```

Resultat apres implementation et apres formatage: `+15: All tests passed!`

### Analyse statique ciblee

```bash
cd packages/map_core
/opt/homebrew/bin/dart analyze \
  lib/src/operations/legacy_surface_usage_diagnostics.dart \
  test/legacy_surface_usage_diagnostics_test.dart \
  lib/map_core.dart
```

Resultat: `No issues found!`

### Tests des lots precedents

```bash
cd packages/map_core
/opt/homebrew/bin/dart test test/legacy_surface_usage_view_test.dart
```

Resultat: `+22: All tests passed!`

```bash
cd packages/map_core
/opt/homebrew/bin/dart test test/legacy_surface_catalog_diagnostics_test.dart
```

Resultat: `+17: All tests passed!`

```bash
cd packages/map_core
/opt/homebrew/bin/dart test test/legacy_project_surface_catalog_view_test.dart
```

Resultat: `+12: All tests passed!`

```bash
cd packages/map_core
/opt/homebrew/bin/dart test test/legacy_terrain_surface_view_test.dart
```

Resultat: `+12: All tests passed!`

```bash
cd packages/map_core
/opt/homebrew/bin/dart test test/legacy_path_surface_view_test.dart
```

Resultat: `+11: All tests passed!`

```bash
cd packages/map_core
/opt/homebrew/bin/dart test test/project_manifest_surface_json_characterization_test.dart
```

Resultat: `+15: All tests passed!`

```bash
cd packages/map_core
/opt/homebrew/bin/dart test test/map_terrain_autotile_characterization_test.dart
```

Resultat: `+21: All tests passed!`

```bash
cd packages/map_core
/opt/homebrew/bin/dart test test/tile_visual_frame_timeline_test.dart
```

Resultat: `+16: All tests passed!`

```bash
cd packages/map_core
/opt/homebrew/bin/dart test test/legacy_editor_json_compat_collision_test.dart
```

Resultat: `+3: All tests passed!`

```bash
cd packages/map_core
/opt/homebrew/bin/dart test test/element_collision_profile_pixel_mask_json_test.dart
```

Resultat: `+6: All tests passed!`

### Test complet map_core

```bash
cd packages/map_core
/opt/homebrew/bin/dart test
```

Resultat: `+277: All tests passed!`

## 14. Resultats des tests

Tous les tests demandes sont verts.

Le test complet `map_core` passe avec le total exact:

```text
+277: All tests passed!
```

Total exact: **277 tests passes**.

## 15. Autocritique finale

Points solides:

- Lot strictement limite a une API pure de diagnostics d'usage.
- Tests ecrits avant implementation et run rouge observe.
- Aucun modele persistant ajoute.
- Aucun modele existant modifie.
- Diagnostics terrain/path gardes separes.
- Ordre de sortie explicitement teste.
- Full `map_core` vert avec total exact.

Limites:

- Les helpers de test dupliquent des helpers presents dans d'autres fichiers de test; c'est volontaire pour garder le fichier autonome, mais cela augmente un peu la maintenance.
- Le cas path `presetId == ''` depend de la representation fournie par Lot 8. Ce lot ne modifie pas Lot 8 pour forcer l'id vide a etre missing si un preset declare avec id vide existait.
- Les messages ne sont pas localises et ne sont pas concus comme texte UI final.

## 16. Ce que le prompt semble discutable ou incomplet

- Le prompt demande de diagnostiquer les usages reels, mais ne precise pas si un diagnostic doit agregger plusieurs usages identiques dans plusieurs maps. J'ai suivi la specification detaillee: un seul diagnostic par `TerrainType` pour certains cas terrain, un diagnostic par missing path usage, un diagnostic par usage path sans variants.
- Le prompt indique qu'un path id duplique utilise ne doit pas rendre les surfaces declarees "unused". C'est coherent avec un audit id-based, mais cela peut masquer le fait qu'une des deux declarations n'est jamais choisie par le "premier match" legacy.
- Le prompt ne definit pas de severite `error`; le lot reste donc a deux niveaux `warning`/`info`, meme pour les cas probablement bloquants.

## 17. Auto-review independante

- Est-ce que le lot est reste strictement limite a des diagnostics d'usage legacy read-only ? Oui.
- Est-ce qu'aucun modele Surface persistant n'a ete cree ? Oui.
- Est-ce qu'aucune vue unifiee Surface n'a ete creee ? Oui.
- Est-ce qu'aucun modele Freezed/JSON n'a ete modifie ? Oui.
- Est-ce qu'aucun fichier generated n'a ete modifie ? Oui.
- Est-ce qu'aucun runtime/editor/gameplay n'a ete modifie ? Oui.
- Est-ce que `ProjectManifest` n'a pas ete modifie ? Oui.
- Est-ce que `MapData` n'a pas ete modifie ? Oui.
- Est-ce que `TerrainLayer` n'a pas ete modifie ? Oui.
- Est-ce que `PathLayer` n'a pas ete modifie ? Oui.
- Est-ce que les diagnostics gardent terrain et path separes ? Oui.
- Est-ce que l'usage terrain reste par `TerrainType` ? Oui.
- Est-ce que les path presets manquants sont diagnostiques sans etre corriges ? Oui.
- Est-ce que les diagnostics restent deterministes ? Oui.
- Est-ce que la liste retournee est non mutable ? Oui.
- Est-ce que les tests documentent le comportement actuel plutot qu'un comportement futur ideal ? Oui.
- Est-ce que les tests des lots precedents passent toujours ? Oui.
- Est-ce que `map_core` complet passe avec un total exact documente ? Oui, `+277: All tests passed!`.
- Est-ce que les commandes Git interdites n'ont pas ete utilisees ? Oui.
- Est-ce que le rapport est assez detaille ? Oui.
- Est-ce que quelque chose du prompt etait ambigu ou discutable ? Oui, les points ci-dessus sont documentes.
