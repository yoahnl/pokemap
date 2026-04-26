# Surface Engine Lot 14 - Standard TerrainPathVariant Vertical Atlas Layout V0

## 1. Resume executif

Le Lot 14 ajoute une primitive pure dans `map_core` pour produire un layout standard V0 de colonnes `TerrainPathVariant -> column` destine aux atlas animes verticaux. Cette primitive ne cree aucun modele persistant, ne modifie aucun contrat JSON/Freezed et ne branche ni runtime ni editeur.

Ajouts :

- `standardTerrainPathVariantVerticalAtlasOrder`
- `createStandardTerrainPathVariantVerticalAtlasColumns(...)`

Validation :

- Nouveau test cible : `+14: All tests passed!`
- Lots precedents retestes : Lot 13 `+34`, Lot 12 `+28`, Lot 11 `+23`
- Suite complete `map_core` : `+384: All tests passed!`
- Analyse ciblee : `No issues found!`

## 2. Pourquoi ce lot est necessaire apres le Lot 13-ter

Les Lots 11 a 13 savent deja construire la chaine technique :

- Lot 11 : frames depuis une colonne d'atlas vertical.
- Lot 12 : mappings de variants depuis une liste explicite `TerrainPathVariant -> column`.
- Lot 13 : `ProjectPathPreset` legacy complet depuis ces mappings.

Il manquait une convention reutilisable pour eviter de reecrire manuellement les colonnes standard de chaque `TerrainPathVariant`. Le Lot 14 ajoute cette convention V0 sans pretendre qu'elle est universelle ou definitive.

## 3. Lien avec les atlas animes verticaux

Les atlas type Pokemon SDK utilisent souvent :

```text
colonne = variante visuelle
ligne   = frame temporelle
```

Le helper Lot 14 pose uniquement la partie "colonne = variante visuelle". Les frames, mappings, presets, images, dimensions reelles et integrations runtime/editor restent hors scope.

## 4. Fichiers consultes

- `packages/map_core/lib/src/models/enums.dart`
- `packages/map_core/lib/src/operations/map_terrain_autotile.dart`
- `packages/map_core/lib/src/operations/path_variant_vertical_atlas_mapping.dart`
- `packages/map_core/lib/src/operations/path_preset_vertical_atlas_builder.dart`
- `packages/map_core/lib/src/exceptions/map_exceptions.dart`
- `packages/map_core/lib/map_core.dart`
- `packages/map_core/test/map_terrain_autotile_characterization_test.dart`
- `packages/map_core/test/path_variant_vertical_atlas_mapping_test.dart`
- `packages/map_core/test/path_preset_vertical_atlas_builder_test.dart`

### Resume de l'audit initial obligatoire

- Fichiers concernes : uniquement `map_core`, avec un nouveau helper pur, son test, le barrel export et ce rapport.
- Contrats existants : `TerrainPathVariant` contient 20 valeurs ; `PathVariantVerticalAtlasColumn` est le contrat Lot 12 consomme par Lots 12 et 13.
- Tests existants : les tests Lots 11, 12, 13 couvrent deja frame builder, mapping variant->frames et preset builder.
- Rapports precedents : Lots 11 a 13-ter sous `reports/surface/`, avec totals actuels `23 + 28 + 34 = 85` et `map_core` complet a `370` avant ce lot.
- Risques principaux : confondre ordre d'atlas et table de masques autotile legacy ; modifier par accident les helpers precedents ; introduire un modele persistant hors scope.
- Limites de scope preservees : aucun modele Surface, aucun JSON/Freezed, aucun runtime/editor/gameplay, aucune modification des helpers Lots 11 a 13.
- Remise en cause du prompt : aucune instruction dangereuse detectee. Point clarifie : l'ordre standard d'atlas n'est pas l'ordre de resolution des masques dans `map_terrain_autotile.dart`.

## 5. Fichiers crees

- `packages/map_core/lib/src/operations/terrain_path_variant_vertical_atlas_layout.dart`
- `packages/map_core/test/terrain_path_variant_vertical_atlas_layout_test.dart`
- `reports/surface/surface_engine_lot_14_terrain_path_variant_vertical_atlas_layout.md`

## 6. Fichiers modifies

- `packages/map_core/lib/map_core.dart`
  - Ajout unique de l'export `src/operations/terrain_path_variant_vertical_atlas_layout.dart`.

### Detail par fichier modifie

#### `packages/map_core/lib/map_core.dart`

- Zone modifiee : section exports `src/operations/...`.
- Raison : exposer l'API publique du Lot 14 depuis le barrel `map_core`.
- Impact attendu : les consommateurs peuvent importer `standardTerrainPathVariantVerticalAtlasOrder` et `createStandardTerrainPathVariantVerticalAtlasColumns(...)` via `package:map_core/map_core.dart`.

#### `packages/map_core/lib/src/operations/terrain_path_variant_vertical_atlas_layout.dart`

- Zone creee : nouveau helper pur.
- Raison : fournir une convention V0 de layout vertical atlas pour `TerrainPathVariant`.
- Impact attendu : eviter de reecrire manuellement les listes `PathVariantVerticalAtlasColumn(...)` dans les futurs builders.

#### `packages/map_core/test/terrain_path_variant_vertical_atlas_layout_test.dart`

- Zone creee : tests unitaires du nouveau helper.
- Raison : verrouiller l'ordre explicite, les validations, l'immutabilite et la compatibilite Lots 12/13.
- Impact attendu : toute evolution de `TerrainPathVariant` force une decision explicite sur l'ordre d'atlas.

#### `reports/surface/surface_engine_lot_14_terrain_path_variant_vertical_atlas_layout.md`

- Zone creee : rapport de lot.
- Raison : documenter audit, implementation, preuves, limites, commandes et auto-review.
- Impact attendu : fournir une trace verifiable du Lot 14.

## 7. API ajoutee

```dart
const List<TerrainPathVariant> standardTerrainPathVariantVerticalAtlasOrder = [
  TerrainPathVariant.isolated,
  TerrainPathVariant.endNorth,
  TerrainPathVariant.endEast,
  TerrainPathVariant.endSouth,
  TerrainPathVariant.endWest,
  TerrainPathVariant.horizontal,
  TerrainPathVariant.vertical,
  TerrainPathVariant.cornerNE,
  TerrainPathVariant.cornerSE,
  TerrainPathVariant.cornerSW,
  TerrainPathVariant.cornerNW,
  TerrainPathVariant.innerCornerNE,
  TerrainPathVariant.innerCornerSE,
  TerrainPathVariant.innerCornerSW,
  TerrainPathVariant.innerCornerNW,
  TerrainPathVariant.teeNorth,
  TerrainPathVariant.teeEast,
  TerrainPathVariant.teeSouth,
  TerrainPathVariant.teeWest,
  TerrainPathVariant.cross,
];
```

```dart
List<PathVariantVerticalAtlasColumn>
    createStandardTerrainPathVariantVerticalAtlasColumns({
  int firstColumn = 0,
  int startRow = 0,
  List<TerrainPathVariant> variants =
      standardTerrainPathVariantVerticalAtlasOrder,
})
```

## 8. Ordre standard retenu

L'ordre retenu couvre les 20 valeurs actuelles de `TerrainPathVariant` :

```text
0  isolated
1  endNorth
2  endEast
3  endSouth
4  endWest
5  horizontal
6  vertical
7  cornerNE
8  cornerSE
9  cornerSW
10 cornerNW
11 innerCornerNE
12 innerCornerSE
13 innerCornerSW
14 innerCornerNW
15 teeNorth
16 teeEast
17 teeSouth
18 teeWest
19 cross
```

Cet ordre est explicite et n'utilise pas `TerrainPathVariant.values`, afin d'eviter qu'un futur reorder de l'enum deplace silencieusement les colonnes d'atlas.

## 9. Semantique du helper

Pour chaque variant a l'index `i`, le helper genere :

```dart
PathVariantVerticalAtlasColumn(
  variant: variant,
  column: firstColumn + i,
  startRow: startRow,
)
```

Validations :

- `firstColumn < 0` leve `ValidationException`.
- `startRow < 0` leve `ValidationException`.
- `variants.isEmpty` leve `ValidationException`.
- un variant duplique leve `ValidationException`.

La liste retournee est non mutable via `List.unmodifiable(...)`.

## 10. Liste complete des cas testes

1. L'ordre standard couvre exactement les valeurs de `TerrainPathVariant`.
2. L'ordre standard est explicitement celui attendu.
3. La generation par defaut cree les colonnes depuis 0.
4. `firstColumn` decale les colonnes.
5. `startRow` est applique a toutes les entrees.
6. Un sous-layout conserve l'ordre fourni.
7. Un sous-layout avec `firstColumn` genere les colonnes attendues.
8. La liste retournee est non mutable.
9. Compatibilite avec `createPathVariantMappingsFromVerticalAtlas(...)`.
10. Compatibilite avec `createProjectPathPresetFromVerticalAtlas(...)`.
11. Validation de `firstColumn`.
12. Validation de `startRow`.
13. Validation de `variants` vide.
14. Validation des variants dupliques.

## 11. Ce que les tests prouvent

- La convention V0 couvre toutes les variantes actuelles.
- L'ordre standard est stable, explicite et teste.
- Le helper genere les colonnes et `startRow` correctement.
- Les sous-layouts sont supportes sans tri ni auto-completion.
- Les validations empechent les layouts ambigus.
- La liste retournee est immutable.
- La sortie est directement consommable par les helpers Lots 12 et 13.

## 12. Ce qui n'a volontairement pas ete fait

- Pas de `SurfaceDefinition`.
- Pas de `SurfaceEngine`.
- Pas de vue Surface unifiee.
- Pas de champ `surfaceDefinitions` dans `ProjectManifest`.
- Pas de modification de `ProjectManifest`, `MapData`, `TerrainLayer`, `PathLayer`, `ProjectTerrainPreset` ou `ProjectPathPreset`.
- Pas de modification Freezed/JSON.
- Pas de `build_runner`.
- Pas de modification de fichiers `.g.dart` ou `.freezed.dart`.
- Pas de modification `map_runtime`, `map_editor`, `map_gameplay` ou `map_battle`.
- Pas de modification des helpers Lots 11, 12 ou 13.
- Pas de mapping specifique eau/lave/glace.
- Pas de verification d'image ou de tileset reel.

## 13. Impact pour les futurs modeles Surface / Tile Animation Engine

Ce helper fournit une convention commune que les prochains builders pourront reutiliser pour l'eau, la lave, la glace, les rails ou d'autres surfaces animees. Il reste volontairement non persistant : les futurs modeles Surface pourront choisir de l'utiliser, de l'adapter ou de proposer une autre convention sans migration de schema imposee par ce lot.

## 14. Points de vigilance

- La convention V0 n'est pas un standard universel garanti pour tous les assets.
- Tout ajout futur a `TerrainPathVariant` fera echouer le test de couverture et devra etre traite explicitement.
- L'ordre d'atlas est distinct de la table de masques legacy dans `map_terrain_autotile.dart`.
- Le helper ne valide pas les dimensions d'image : un atlas trop petit reste une erreur d'asset hors scope.

## 15. Commandes lancees

Etat Git initial :

```bash
git status --short
```

```text
(aucune sortie)
```

```bash
git diff --stat
```

```text
(aucune sortie)
```

```bash
git diff
```

```text
(aucune sortie)
```

```bash
git log --oneline -5
```

```text
a5d4a020 update lot 13
5f9a1736 update lot 13
fcad54ba lot 11
301048c6 lot 8 - 10
29ff071b lot 1 - 8: refactor runtime
```

```bash
cd packages/map_core
/opt/homebrew/bin/dart format lib/src/operations/terrain_path_variant_vertical_atlas_layout.dart test/terrain_path_variant_vertical_atlas_layout_test.dart lib/map_core.dart
```

```bash
cd packages/map_core
/opt/homebrew/bin/dart test test/terrain_path_variant_vertical_atlas_layout_test.dart
```

```bash
cd packages/map_core
/opt/homebrew/bin/dart test test/path_preset_vertical_atlas_builder_test.dart
```

```bash
cd packages/map_core
/opt/homebrew/bin/dart test test/path_variant_vertical_atlas_mapping_test.dart
```

```bash
cd packages/map_core
/opt/homebrew/bin/dart test test/tile_visual_frame_vertical_atlas_test.dart
```

```bash
cd packages/map_core
/opt/homebrew/bin/dart test
```

```bash
cd packages/map_core
/opt/homebrew/bin/dart analyze \
  lib/src/operations/terrain_path_variant_vertical_atlas_layout.dart \
  test/terrain_path_variant_vertical_atlas_layout_test.dart \
  lib/map_core.dart
```

Build :

```text
Build applicatif non lance : `packages/map_core` est un package Dart de bibliotheque sans executable/app a builder pour ce lot. Validation alternative lancee : tests cibles, suite complete `dart test`, et `dart analyze` cible.
```

Etat Git final :

```bash
git status --short
```

```text
 M packages/map_core/lib/map_core.dart
?? packages/map_core/lib/src/operations/terrain_path_variant_vertical_atlas_layout.dart
?? packages/map_core/test/terrain_path_variant_vertical_atlas_layout_test.dart
?? reports/surface/surface_engine_lot_14_terrain_path_variant_vertical_atlas_layout.md
```

```bash
git diff --stat
```

```text
 packages/map_core/lib/map_core.dart | 1 +
 1 file changed, 1 insertion(+)
```

## 16. Resultats exacts des tests

Format :

```text
Formatted test/terrain_path_variant_vertical_atlas_layout_test.dart
Formatted 3 files (1 changed) in 0.01 seconds.
```

Nouveau test Lot 14 :

```text
00:00 +14: All tests passed!
```

Lot 13 :

```text
00:00 +34: All tests passed!
```

Lot 12 :

```text
00:00 +28: All tests passed!
```

Lot 11 :

```text
00:00 +23: All tests passed!
```

Test complet `map_core` :

```text
00:01 +382: test/legacy_editor_json_compat_collision_test.dart: legacy collision profile compat unknown legacy keys do not prevent manifest parsing
00:01 +383: test/legacy_editor_json_compat_collision_test.dart: legacy collision profile compat unknown legacy keys do not prevent manifest parsing
00:01 +383: test/legacy_editor_json_compat_collision_test.dart: legacy collision profile compat missing pokemon config still falls back to the manifest default
00:01 +384: test/legacy_editor_json_compat_collision_test.dart: legacy collision profile compat missing pokemon config still falls back to the manifest default
00:01 +384: All tests passed!
```

Analyse ciblee :

```text
Analyzing terrain_path_variant_vertical_atlas_layout.dart, terrain_path_variant_vertical_atlas_layout_test.dart, map_core.dart...
No issues found!
```

## 17. Total exact du `dart test` complet

Total exact actuel :

```text
+384: All tests passed!
```

Explication : le Lot 13-ter avait documente `+370`; le Lot 14 ajoute 14 tests, donc `370 + 14 = 384`.

## 18. Autocritique finale

Points solides :

- Scope strictement limite a une primitive de layout pure.
- Ordre explicite et protege contre les evolutions de l'enum.
- Compatibilite prouvee avec les Lots 12 et 13.
- Tests cibles et suite complete verts.

Points perfectibles :

- La convention V0 reste arbitraire cote assets et devra etre validee avec de vrais packs graphiques.
- Les commentaires sont volontairement nombreux pour poser la convention ; ils pourront etre alleges si le pattern devient familier.

## 19. Ce que le prompt semble discutable ou incomplet

- Le prompt donne un ordre attendu qui correspond a l'enum courant, mais cet ordre n'est pas identique a la table de masques legacy. J'ai retenu l'ordre du prompt comme convention d'atlas, et documente que la table autotile reste separee.
- Le prompt demande une convention standard V0 sans dire si les variants interieurs doivent etre pres des corners ou en fin de liste. J'ai conserve l'ordre fourni, qui place les inner corners apres les outer corners.
- Le prompt ne demande pas de messages d'erreur exacts ; j'ai utilise des messages courts et coherents avec les helpers existants.

## 20. Auto-review independante

- Est-ce que le lot est reste strictement limite a un layout standard de `TerrainPathVariant` ? Oui.
- Est-ce qu'aucun modele Surface persistant n'a ete cree ? Oui.
- Est-ce qu'aucun modele Freezed/JSON n'a ete modifie ? Oui.
- Est-ce qu'aucun fichier generated n'a ete modifie ? Oui.
- Est-ce qu'aucun runtime/editor/gameplay n'a ete modifie ? Oui.
- Est-ce que l'ordre standard est explicite et teste ? Oui.
- Est-ce que l'ordre standard couvre toutes les valeurs de `TerrainPathVariant` ? Oui.
- Est-ce que le helper genere les colonnes correctement ? Oui.
- Est-ce que les validations sont strictes et testees ? Oui.
- Est-ce que la liste retournee est non mutable ? Oui.
- Est-ce que le helper est compatible avec les helpers Lots 12 et 13 ? Oui.
- Est-ce que les tests des lots precedents passent toujours ? Oui.
- Est-ce que `map_core` complet passe avec un total exact documente ? Oui, `+384`.
- Est-ce que les contenus complets et diffs complets sont fournis ? A fournir dans la reponse finale.
- Est-ce que les commandes Git interdites n'ont pas ete utilisees ? Oui.

## Verdict

Lot 14 complet et conforme : la convention standard V0 de layout vertical atlas pour `TerrainPathVariant` est ajoutee, testee, exportee et documentee sans elargir le scope Surface Engine.

## 21. Verdict des passes type sub-agents

### Sub-agent Audit / Architecture

Verdict : conforme. L'ordre reel de `TerrainPathVariant` a ete confirme dans `enums.dart`; la table de masques legacy a ete identifiee comme un contrat distinct de l'ordre d'atlas.

### Sub-agent Implementation

Verdict : conforme. Le helper ajoute uniquement une constante d'ordre standard et une fonction pure retournant des `PathVariantVerticalAtlasColumn` immutables.

### Sub-agent Tests

Verdict : conforme. Les 14 tests couvrent comportement positif, sous-layouts, validations negatives, immutabilite et compatibilite Lots 12/13.

### Sub-agent Build / Validation

Verdict : conforme. Build applicatif non applicable pour ce package bibliotheque ; validation alternative complete effectuee avec tests cibles, suite complete et analyse statique.

### Sub-agent Critique finale

Verdict : conforme. Aucun fichier hors scope modifie, aucun modele persistant cree, aucune integration runtime/editor/gameplay ajoutee, aucun helper precedent modifie.

## 22. Contenu complet des fichiers crees

### `packages/map_core/lib/src/operations/terrain_path_variant_vertical_atlas_layout.dart`

```dart
import '../exceptions/map_exceptions.dart';
import '../models/enums.dart';
import 'path_variant_vertical_atlas_mapping.dart';

/// Standard V0 order for path variants in a vertical animation atlas.
///
/// This is deliberately an explicit list instead of [TerrainPathVariant.values].
/// The enum order is a Dart source detail, while an atlas layout is an asset
/// contract: if the enum is reordered later, existing atlas columns should not
/// silently move.
///
/// V0 keeps the current legacy variant vocabulary and uses a readable authoring
/// order: isolated tile, cardinal ends, straight segments, outer corners, inner
/// corners, tees, then cross.
const List<TerrainPathVariant> standardTerrainPathVariantVerticalAtlasOrder = [
  TerrainPathVariant.isolated,
  TerrainPathVariant.endNorth,
  TerrainPathVariant.endEast,
  TerrainPathVariant.endSouth,
  TerrainPathVariant.endWest,
  TerrainPathVariant.horizontal,
  TerrainPathVariant.vertical,
  TerrainPathVariant.cornerNE,
  TerrainPathVariant.cornerSE,
  TerrainPathVariant.cornerSW,
  TerrainPathVariant.cornerNW,
  TerrainPathVariant.innerCornerNE,
  TerrainPathVariant.innerCornerSE,
  TerrainPathVariant.innerCornerSW,
  TerrainPathVariant.innerCornerNW,
  TerrainPathVariant.teeNorth,
  TerrainPathVariant.teeEast,
  TerrainPathVariant.teeSouth,
  TerrainPathVariant.teeWest,
  TerrainPathVariant.cross,
];

/// Creates a standard column layout for [TerrainPathVariant] vertical atlases.
///
/// Each returned [PathVariantVerticalAtlasColumn] maps one variant to:
///
/// ```text
/// column = firstColumn + variantIndex
/// row    = startRow
/// ```
///
/// This helper only describes where variants live in an atlas. It intentionally
/// does not create frames, path mappings, presets, JSON, or persistent Surface
/// models. Callers can pass its result to
/// [createPathVariantMappingsFromVerticalAtlas] or
/// [createProjectPathPresetFromVerticalAtlas] when they want to build the next
/// legacy layer.
List<PathVariantVerticalAtlasColumn>
    createStandardTerrainPathVariantVerticalAtlasColumns({
  int firstColumn = 0,
  int startRow = 0,
  List<TerrainPathVariant> variants =
      standardTerrainPathVariantVerticalAtlasOrder,
}) {
  _validateStandardTerrainPathVariantVerticalAtlasLayoutParameters(
    firstColumn: firstColumn,
    startRow: startRow,
    variants: variants,
  );

  final columns = <PathVariantVerticalAtlasColumn>[];
  for (var i = 0; i < variants.length; i += 1) {
    columns.add(
      PathVariantVerticalAtlasColumn(
        variant: variants[i],
        column: firstColumn + i,
        startRow: startRow,
      ),
    );
  }

  return List.unmodifiable(columns);
}

void _validateStandardTerrainPathVariantVerticalAtlasLayoutParameters({
  required int firstColumn,
  required int startRow,
  required List<TerrainPathVariant> variants,
}) {
  if (firstColumn < 0) {
    throw const ValidationException('firstColumn must be non-negative');
  }
  if (startRow < 0) {
    throw const ValidationException('startRow must be non-negative');
  }
  if (variants.isEmpty) {
    throw const ValidationException('variants must not be empty');
  }

  final seenVariants = <TerrainPathVariant>{};
  for (final variant in variants) {
    if (!seenVariants.add(variant)) {
      throw ValidationException('Duplicate TerrainPathVariant: $variant');
    }
  }
}
```

### `packages/map_core/test/terrain_path_variant_vertical_atlas_layout_test.dart`

```dart
// ignore_for_file: prefer_const_literals_to_create_immutables

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('standardTerrainPathVariantVerticalAtlasOrder', () {
    test('covers exactly the TerrainPathVariant enum values once', () {
      // This test is an enum-evolution guard. If a future lot adds a path
      // variant, the standard atlas order must be reviewed explicitly instead
      // of inheriting an accidental enum order.
      expect(
        standardTerrainPathVariantVerticalAtlasOrder.toSet(),
        TerrainPathVariant.values.toSet(),
      );
      expect(
        standardTerrainPathVariantVerticalAtlasOrder,
        hasLength(TerrainPathVariant.values.length),
      );
    });

    test('uses the explicit V0 atlas order', () {
      expect(
        standardTerrainPathVariantVerticalAtlasOrder,
        [
          TerrainPathVariant.isolated,
          TerrainPathVariant.endNorth,
          TerrainPathVariant.endEast,
          TerrainPathVariant.endSouth,
          TerrainPathVariant.endWest,
          TerrainPathVariant.horizontal,
          TerrainPathVariant.vertical,
          TerrainPathVariant.cornerNE,
          TerrainPathVariant.cornerSE,
          TerrainPathVariant.cornerSW,
          TerrainPathVariant.cornerNW,
          TerrainPathVariant.innerCornerNE,
          TerrainPathVariant.innerCornerSE,
          TerrainPathVariant.innerCornerSW,
          TerrainPathVariant.innerCornerNW,
          TerrainPathVariant.teeNorth,
          TerrainPathVariant.teeEast,
          TerrainPathVariant.teeSouth,
          TerrainPathVariant.teeWest,
          TerrainPathVariant.cross,
        ],
      );
    });
  });

  group('createStandardTerrainPathVariantVerticalAtlasColumns', () {
    test('generates columns from zero', () {
      final columns = createStandardTerrainPathVariantVerticalAtlasColumns();

      expect(columns,
          hasLength(standardTerrainPathVariantVerticalAtlasOrder.length));
      for (var i = 0; i < columns.length; i += 1) {
        expect(columns[i].variant,
            standardTerrainPathVariantVerticalAtlasOrder[i]);
        expect(columns[i].column, i);
        expect(columns[i].startRow, 0);
      }
    });

    test('respects firstColumn', () {
      final columns = createStandardTerrainPathVariantVerticalAtlasColumns(
        firstColumn: 10,
      );

      expect(columns.first.column, 10);
      expect(columns[1].column, 11);
      expect(columns.last.column, 10 + columns.length - 1);
    });

    test('respects startRow', () {
      final columns = createStandardTerrainPathVariantVerticalAtlasColumns(
        startRow: 5,
      );

      expect(columns.every((column) => column.startRow == 5), isTrue);
    });

    test('generates a sub-layout', () {
      final columns = createStandardTerrainPathVariantVerticalAtlasColumns(
        variants: [
          TerrainPathVariant.isolated,
          TerrainPathVariant.horizontal,
          TerrainPathVariant.vertical,
        ],
      );

      expect(columns, hasLength(3));
      expect(columns[0].variant, TerrainPathVariant.isolated);
      expect(columns[0].column, 0);
      expect(columns[1].variant, TerrainPathVariant.horizontal);
      expect(columns[1].column, 1);
      expect(columns[2].variant, TerrainPathVariant.vertical);
      expect(columns[2].column, 2);
    });

    test('generates a sub-layout with firstColumn', () {
      final columns = createStandardTerrainPathVariantVerticalAtlasColumns(
        firstColumn: 20,
        variants: [
          TerrainPathVariant.isolated,
          TerrainPathVariant.horizontal,
          TerrainPathVariant.vertical,
        ],
      );

      expect(columns.map((column) => column.column), [20, 21, 22]);
    });

    test('returns an unmodifiable list', () {
      final columns = createStandardTerrainPathVariantVerticalAtlasColumns(
        variants: [TerrainPathVariant.isolated],
      );

      expect(
        () => columns.add(
          PathVariantVerticalAtlasColumn(
            variant: TerrainPathVariant.horizontal,
            column: 1,
          ),
        ),
        throwsUnsupportedError,
      );
    });

    test('is compatible with createPathVariantMappingsFromVerticalAtlas', () {
      // Lot 14 only creates the column layout. Lot 12 remains responsible for
      // turning that layout into legacy variant mappings and animation frames.
      final columns = createStandardTerrainPathVariantVerticalAtlasColumns(
        firstColumn: 3,
        startRow: 2,
        variants: [
          TerrainPathVariant.isolated,
          TerrainPathVariant.horizontal,
          TerrainPathVariant.vertical,
        ],
      );

      final mappings = createPathVariantMappingsFromVerticalAtlas(
        columns: columns,
        frameCount: 2,
      );

      expect(mappings, hasLength(3));
      expect(mappings[0].variant, TerrainPathVariant.isolated);
      expect(mappings[0].frames[0].source.x, 3);
      expect(mappings[0].frames[0].source.y, 2);
      expect(mappings[1].variant, TerrainPathVariant.horizontal);
      expect(mappings[1].frames[0].source.x, 4);
      expect(mappings[2].variant, TerrainPathVariant.vertical);
      expect(mappings[2].frames[0].source.x, 5);
    });

    test('is compatible with createProjectPathPresetFromVerticalAtlas', () {
      // Lot 13 can consume this standard layout without any runtime/editor
      // integration or new persistent Surface model.
      final columns = createStandardTerrainPathVariantVerticalAtlasColumns(
        firstColumn: 7,
        variants: [
          TerrainPathVariant.isolated,
          TerrainPathVariant.horizontal,
        ],
      );

      final preset = createProjectPathPresetFromVerticalAtlas(
        id: 'standard-water',
        name: 'Standard Water',
        surfaceKind: PathSurfaceKind.water,
        tilesetId: 'water-tileset',
        columns: columns,
        frameCount: 3,
      );

      expect(preset.id, 'standard-water');
      expect(preset.variants, hasLength(2));
      expect(preset.variants[0].variant, TerrainPathVariant.isolated);
      expect(preset.variants[0].frames, hasLength(3));
      expect(preset.variants[0].frames[0].source.x, 7);
      expect(preset.variants[1].variant, TerrainPathVariant.horizontal);
      expect(preset.variants[1].frames[0].source.x, 8);
    });

    test('rejects negative firstColumn', () {
      expect(
        () => createStandardTerrainPathVariantVerticalAtlasColumns(
          firstColumn: -1,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects negative startRow', () {
      expect(
        () => createStandardTerrainPathVariantVerticalAtlasColumns(
          startRow: -1,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects empty variants', () {
      expect(
        () => createStandardTerrainPathVariantVerticalAtlasColumns(
          variants: [],
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects duplicate variants', () {
      expect(
        () => createStandardTerrainPathVariantVerticalAtlasColumns(
          variants: [
            TerrainPathVariant.isolated,
            TerrainPathVariant.isolated,
          ],
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
```

### `reports/surface/surface_engine_lot_14_terrain_path_variant_vertical_atlas_layout.md`

Le present fichier est le rapport cree. Son contenu complet correspond a ce document.

## 23. Diff des fichiers modifies

### `packages/map_core/lib/map_core.dart`

```diff
diff --git a/packages/map_core/lib/map_core.dart b/packages/map_core/lib/map_core.dart
index c912edef..1ebfa8a9 100644
--- a/packages/map_core/lib/map_core.dart
+++ b/packages/map_core/lib/map_core.dart
@@ -32,6 +32,7 @@ export 'src/operations/tile_visual_frame_timeline.dart';
 export 'src/operations/tile_visual_frame_vertical_atlas.dart';
 export 'src/operations/path_variant_vertical_atlas_mapping.dart';
 export 'src/operations/path_preset_vertical_atlas_builder.dart';
+export 'src/operations/terrain_path_variant_vertical_atlas_layout.dart';
 export 'src/operations/legacy_path_surface_view.dart';
 export 'src/operations/legacy_terrain_surface_view.dart';
 export 'src/operations/legacy_project_surface_catalog_view.dart';
```

Les fichiers crees sont fournis en contenu complet dans la section precedente ; leur diff complet est un ajout integral depuis `/dev/null`.
