# Surface Engine Lot 7 - Legacy Surface Catalog Diagnostics V0

## 1. Resume executif

Le Lot 7 ajoute une couche pure de diagnostics read-only sur le catalogue cree
au Lot 6:

```text
LegacyProjectSurfaceCatalogView
  -> diagnoseLegacySurfaceCatalog(...)
  -> List<LegacySurfaceCatalogDiagnostic>
```

L'objectif est de produire des faits utiles pour la future migration Surface
Engine sans creer de modele persistant `SurfaceDefinition`, sans schema JSON,
sans Freezed, sans runtime, sans editeur et sans gameplay.

Le lot ajoute:

- des enums de severite, code et famille de diagnostic;
- une valeur immutable `LegacySurfaceCatalogDiagnostic`;
- la fonction pure `diagnoseLegacySurfaceCatalog`;
- des tests de caracterisation couvrant les diagnostics obligatoires;
- l'export public dans `map_core.dart`.

Le lot a suivi une boucle TDD: le test a d'abord echoue parce que l'API
diagnostics etait absente, puis l'implementation minimale a ete ajoutee. La
suite complete `map_core` passe avec 240 tests.

## 2. Pourquoi ce lot est necessaire apres le Lot 6

Le Lot 6 donne une vue d'inventaire:

- `terrainPresets -> LegacyTerrainSurfaceView[]`;
- `pathPresets -> LegacyPathSurfaceView[]`.

Ce catalogue preservait volontairement les limites legacy:

- terrains et paths restent separes;
- les ids peuvent etre dupliques;
- les lookups retournent le premier match;
- un terrain et un path peuvent partager un id;
- aucune validation ou correction n'est appliquee.

Le Lot 7 ajoute la couche d'audit qui manquait: detecter les risques et faits
de migration sans modifier les donnees. Cette couche aidera les futurs lots a
produire des rapports de compatibilite avant d'introduire un vrai modele
`Surface`.

## 3. Fichiers consultes

Fichiers source consultes:

- `packages/map_core/lib/src/operations/legacy_project_surface_catalog_view.dart`
- `packages/map_core/lib/src/operations/legacy_path_surface_view.dart`
- `packages/map_core/lib/src/operations/legacy_terrain_surface_view.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/enums.dart`
- `packages/map_core/lib/map_core.dart`

Tests consultes:

- `packages/map_core/test/legacy_project_surface_catalog_view_test.dart`
- `packages/map_core/test/legacy_path_surface_view_test.dart`
- `packages/map_core/test/legacy_terrain_surface_view_test.dart`

Constats:

- `LegacyProjectSurfaceCatalogView` expose deux listes separees:
  `terrainSurfaces` et `pathSurfaces`.
- Les lookups du catalogue retournent le premier match en cas de doublon.
- `LegacyTerrainSurfaceView` expose des variants ponderes et `hasWeightedVariants`.
- `LegacyPathSurfaceView` expose des mappings `TerrainPathVariant`.
- `TilesetVisualFrame.tilesetId == ''` represente l'absence d'override.
- Les vues existantes sont read-only; les diagnostics doivent seulement les
  lire.

## 4. Fichiers crees

- `packages/map_core/lib/src/operations/legacy_surface_catalog_diagnostics.dart`
- `packages/map_core/test/legacy_surface_catalog_diagnostics_test.dart`
- `reports/analysis/surface_engine_lot_7_legacy_surface_catalog_diagnostics.md`

## 5. Fichiers modifies

- `packages/map_core/lib/map_core.dart`

Modification exacte:

```dart
export 'src/operations/legacy_surface_catalog_diagnostics.dart';
```

Aucun modele Freezed/JSON, fichier generated, runtime, editeur, gameplay ou
battle n'a ete modifie.

## 6. API ajoutee

Enums:

```dart
enum LegacySurfaceCatalogDiagnosticSeverity {
  info,
  warning,
}

enum LegacySurfaceCatalogDiagnosticCode {
  duplicateTerrainSurfaceId,
  duplicatePathSurfaceId,
  sharedTerrainAndPathId,
  terrainSurfaceWithoutVariants,
  pathSurfaceWithoutVariants,
  terrainVariantWithoutFrames,
  pathVariantWithoutFrames,
  duplicatePathVariantMapping,
  terrainSurfaceWithWeightedVariants,
  terrainSurfaceWithAnimatedVariants,
  pathSurfaceWithAnimatedVariants,
  frameTilesetOverrideUsed,
}

enum LegacySurfaceCatalogDiagnosticFamily {
  terrain,
  path,
  crossFamily,
}
```

Valeur diagnostic:

```dart
final class LegacySurfaceCatalogDiagnostic {
  const LegacySurfaceCatalogDiagnostic({
    required this.severity,
    required this.code,
    required this.family,
    required this.message,
    this.surfaceId,
    this.surfaceName,
    this.detail,
  });
}
```

Fonction principale:

```dart
List<LegacySurfaceCatalogDiagnostic> diagnoseLegacySurfaceCatalog(
  LegacyProjectSurfaceCatalogView catalog,
)
```

## 7. Semantique des diagnostics

`diagnoseLegacySurfaceCatalog`:

- lit `catalog.terrainSurfaces`;
- lit `catalog.pathSurfaces`;
- retourne une liste non mutable;
- ne mute pas le catalogue;
- ne corrige pas les donnees;
- ne throw pas sur doublons;
- ne valide pas le manifest source;
- ne cree pas de surface unifiee;
- reste deterministe.

Severites:

- `warning`: probleme structurel pouvant gener une migration ou un rendu;
- `info`: fait utile pour migration, mais pas necessairement problematique.

Familles:

- `terrain`: diagnostic sur les terrains legacy;
- `path`: diagnostic sur les paths legacy;
- `crossFamily`: fait qui concerne les deux familles sans les fusionner.

Ordre garanti:

1. doublons globaux terrain;
2. doublons globaux path;
3. ids partages terrain/path;
4. diagnostics detailles terrain dans l'ordre du catalogue;
5. diagnostics detailles path dans l'ordre du catalogue.

Dans les groupes de doublons, l'ordre de premiere apparition est preserve.

## 8. Liste complete des cas testes

Fichier:

```text
packages/map_core/test/legacy_surface_catalog_diagnostics_test.dart
```

Cas testes:

1. Catalogue sain:
   - un terrain avec variant/frame;
   - un path avec mapping/frame;
   - aucun diagnostic.

2. Doublons terrain:
   - `duplicateTerrainSurfaceId`;
   - `warning`;
   - `family: terrain`;
   - un seul diagnostic pour l'id.

3. Doublons path:
   - `duplicatePathSurfaceId`;
   - `warning`;
   - `family: path`.

4. Id partage terrain/path:
   - `sharedTerrainAndPathId`;
   - `info`;
   - `family: crossFamily`.

5. Terrain sans variants:
   - `terrainSurfaceWithoutVariants`;
   - `warning`;
   - id et nom renseignes.

6. Path sans variants:
   - `pathSurfaceWithoutVariants`;
   - `warning`;
   - id et nom renseignes.

7. Terrain variant sans frames:
   - `terrainVariantWithoutFrames`;
   - `warning`;
   - detail contient l'index du variant.

8. Path variant sans frames:
   - `pathVariantWithoutFrames`;
   - `warning`;
   - detail contient `TerrainPathVariant.cross` et l'index du mapping.

9. Duplicate path variant mapping:
   - `duplicatePathVariantMapping`;
   - `warning`;
   - detail contient le variant et les indices.

10. Terrain avec weighted variants:
    - `terrainSurfaceWithWeightedVariants`;
    - `info`.

11. Terrain avec animated variants:
    - `terrainSurfaceWithAnimatedVariants`;
    - `info`.

12. Path avec animated variants:
    - `pathSurfaceWithAnimatedVariants`;
    - `info`.

13. Override tileset sur terrain:
    - `frameTilesetOverrideUsed`;
    - `info`;
    - `family: terrain`;
    - detail contient l'override.

14. Override tileset sur path:
    - `frameTilesetOverrideUsed`;
    - `info`;
    - `family: path`;
    - detail contient l'override.

15. Ordre deterministe:
    - verification exacte de l'ordre global demande par le prompt.

16. Liste retournee non mutable:
    - `diagnostics.add(...)` throw.

17. Catalogue source non mute:
    - listes terrain/path intactes;
    - variants et frames intactes;
    - objets frames preserves.

## 9. Ce que les tests prouvent

Les tests prouvent que les diagnostics:

- couvrent les risques de migration demandes;
- gardent terrain et path separes;
- ne corrigent pas les doublons;
- reportent un seul diagnostic par id duplique;
- reportent un seul diagnostic par surface pour les overrides `tilesetId`;
- respectent `tilesetId.isNotEmpty` comme detection d'override;
- restent deterministes;
- retournent une liste non mutable;
- ne mutent pas le catalogue source;
- restent compatibles avec les tests des lots precedents.

## 10. Ce qui n'a volontairement pas ete fait

Ce lot n'a pas:

- cree `SurfaceDefinition`;
- cree `SurfaceEngine`;
- cree une vue unifiee Surface;
- ajoute `surfaceDefinitions` dans `ProjectManifest`;
- modifie `ProjectManifest`;
- modifie `ProjectTerrainPreset`;
- modifie `ProjectPathPreset`;
- modifie `LegacyProjectSurfaceCatalogView`;
- modifie `LegacyTerrainSurfaceView`;
- modifie `LegacyPathSurfaceView`;
- modifie `tile_visual_frame_timeline.dart`;
- modifie `map_terrain_autotile.dart`;
- modifie le runtime, l'editeur, le gameplay ou le battle;
- modifie des fichiers generated;
- lance `build_runner`;
- cree une migration.

## 11. Impact pour les futurs modeles Surface

Ce lot donne un premier outil d'audit utilisable avant de creer des surfaces
persistantes.

Impacts utiles:

- les futurs lots pourront afficher ou exporter des warnings de migration;
- les doublons d'ids seront visibles avant schema persistant;
- les surfaces vides seront detectees avant conversion;
- les mappings path ambigus seront detectes sans changer la regle legacy
  "premier mapping";
- les animations et overrides multi-atlas seront identifies comme faits de
  migration a preserver.

Le point important est que le diagnostic reste separe du modele cible. Il aide a
comprendre le legacy; il ne decide pas encore de la forme du futur Surface
Engine.

## 12. Points de vigilance

- Les diagnostics lisent les presets du catalogue, pas les usages reels dans
  les maps. Un futur lot devra auditer les layers si l'objectif devient de
  mesurer l'usage effectif.
- `sharedTerrainAndPathId` est `info`, pas `warning`, car le Lot 6 a defini que
  les familles restent separees.
- Les diagnostics d'override ne produisent qu'un diagnostic par surface. C'est
  suffisant pour V0, mais un rapport plus detaille pourrait lister toutes les
  frames plus tard.
- Les messages et details sont utiles, mais les tests verrouillent surtout les
  codes, severites, familles et ordre.
- Les lookups du catalogue restent non validants. Les diagnostics ne doivent
  pas etre confondus avec une correction automatique.

## 13. Commandes lancees

TDD rouge initial:

```bash
cd packages/map_core
/opt/homebrew/bin/dart test test/legacy_surface_catalog_diagnostics_test.dart
```

Resultat initial attendu:

```text
Failed to load "test/legacy_surface_catalog_diagnostics_test.dart":
Type 'LegacySurfaceCatalogDiagnostic' not found.
Method not found: 'diagnoseLegacySurfaceCatalog'.
```

Formatage:

```bash
cd packages/map_core
/opt/homebrew/bin/dart format \
  lib/src/operations/legacy_surface_catalog_diagnostics.dart \
  test/legacy_surface_catalog_diagnostics_test.dart \
  lib/map_core.dart
```

Analyse:

```bash
cd packages/map_core
/opt/homebrew/bin/dart analyze \
  lib/src/operations/legacy_surface_catalog_diagnostics.dart \
  test/legacy_surface_catalog_diagnostics_test.dart \
  lib/map_core.dart
```

Tests cibles:

```bash
cd packages/map_core
/opt/homebrew/bin/dart test test/legacy_surface_catalog_diagnostics_test.dart
/opt/homebrew/bin/dart test test/legacy_project_surface_catalog_view_test.dart
/opt/homebrew/bin/dart test test/legacy_terrain_surface_view_test.dart
/opt/homebrew/bin/dart test test/legacy_path_surface_view_test.dart
/opt/homebrew/bin/dart test test/project_manifest_surface_json_characterization_test.dart
/opt/homebrew/bin/dart test test/map_terrain_autotile_characterization_test.dart
/opt/homebrew/bin/dart test test/tile_visual_frame_timeline_test.dart
/opt/homebrew/bin/dart test test/legacy_editor_json_compat_collision_test.dart
/opt/homebrew/bin/dart test test/element_collision_profile_pixel_mask_json_test.dart
```

Suite complete:

```bash
cd packages/map_core
/opt/homebrew/bin/dart test
```

Commandes Git en lecture:

```bash
git status --short
```

Aucune commande Git d'ecriture n'a ete lancee.

## 14. Resultats des tests

Resultats observes:

- `dart analyze ...`: `No issues found!`
- `legacy_surface_catalog_diagnostics_test.dart`: 17 tests, tous passent.
- `legacy_project_surface_catalog_view_test.dart`: 12 tests, tous passent.
- `legacy_terrain_surface_view_test.dart`: 12 tests, tous passent.
- `legacy_path_surface_view_test.dart`: 11 tests, tous passent.
- `project_manifest_surface_json_characterization_test.dart`: 15 tests, tous
  passent.
- `map_terrain_autotile_characterization_test.dart`: 21 tests, tous passent.
- `tile_visual_frame_timeline_test.dart`: 16 tests, tous passent.
- `legacy_editor_json_compat_collision_test.dart`: 3 tests, tous passent.
- `element_collision_profile_pixel_mask_json_test.dart`: 6 tests, tous passent.
- `dart test` complet dans `packages/map_core`: 240 tests, tous passent.

## 15. Autocritique finale

Points positifs:

- Le lot reste purement read-only.
- L'API est petite et non persistante.
- Les diagnostics gardent terrain/path separes.
- Les tests couvrent tous les codes demandes.
- L'ordre deterministe est teste explicitement.
- Les tests des lots precedents et la suite complete restent verts.

Limites:

- Les diagnostics ne regardent pas encore les layers ni les usages reels sur les
  maps.
- Les details de diagnostic sont volontairement simples; un futur reporter
  pourrait vouloir des donnees plus structurees que des strings.
- Les overrides `tilesetId` sont resumes a un diagnostic par surface; cela
  suffit pour V0 mais pas pour un audit exhaustif de frames.
- Les messages ne sont pas localises et ne sont pas une UI finale.

## 16. Ce que le prompt semble discutable ou incomplet

Le prompt est coherent avec les lots precedents. Quelques points restent
volontairement ouverts:

- Le prompt demande une couche de diagnostics, mais pas de modele structure pour
  les details. V0 utilise `detail: String?`, ce qui est simple mais moins riche
  qu'une future structure de rapport.
- Le prompt parle de risques de migration, mais limite le scope aux presets. Il
  faudra un lot distinct pour diagnostiquer les usages reels dans les maps.
- `sharedTerrainAndPathId` est classe en `info`. C'est coherent avec le Lot 6,
  mais un futur validateur de manifest pourrait choisir une severite plus forte
  si des ids globaux deviennent requis.
- Les diagnostics ne proposent pas de remediation. C'est intentionnel, mais un
  futur Surface Studio aura probablement besoin d'actions guidees.

## 17. Auto-review independante

- Est-ce que le lot est reste strictement limite a des diagnostics legacy
  read-only ? Oui.
- Est-ce qu'aucun modele Surface persistant n'a ete cree ? Oui.
- Est-ce qu'aucune vue unifiee Surface n'a ete creee ? Oui.
- Est-ce qu'aucun modele Freezed/JSON n'a ete modifie ? Oui.
- Est-ce qu'aucun fichier generated n'a ete modifie ? Oui.
- Est-ce qu'aucun runtime/editor/gameplay n'a ete modifie ? Oui.
- Est-ce que `ProjectManifest` n'a pas ete modifie ? Oui.
- Est-ce que `ProjectTerrainPreset` n'a pas ete modifie ? Oui.
- Est-ce que `ProjectPathPreset` n'a pas ete modifie ? Oui.
- Est-ce que les diagnostics gardent terrain et path separes ? Oui.
- Est-ce que les doublons sont diagnostiques sans etre corriges ? Oui.
- Est-ce que les diagnostics restent deterministes ? Oui.
- Est-ce que la liste retournee est non mutable ? Oui.
- Est-ce que les tests documentent le comportement actuel plutot qu'un
  comportement futur ideal ? Oui.
- Est-ce que les tests des lots precedents passent toujours ? Oui.
- Est-ce que `map_core` complet passe ? Oui, 240 tests passent.
- Est-ce que les commandes Git interdites n'ont pas ete utilisees ? Oui.
- Est-ce que le rapport est assez detaille ? Oui.
- Est-ce que quelque chose du prompt etait ambigu ou discutable ? Oui: la forme
  de `detail` reste volontairement textuelle, et l'audit ne couvre pas encore
  l'usage reel des presets dans les layers.
