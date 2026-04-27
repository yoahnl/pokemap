# Rapport — Pokemon Project Config Mini-Fix Round 1

## 1. Résumé exécutif
Ce mini-fix corrige une redondance réelle dans le lot de config Pokémon projet.

Le problème corrigé :
- `legacy_editor_json_compat.dart` injectait encore artificiellement `pokemon: {}` dans les anciens manifests, alors que le fallback est déjà correctement assuré par `@Default(ProjectPokemonConfig())` dans `ProjectManifest`.

Le résultat :
- la compatibilité avec les anciens `project.json` sans bloc `pokemon` est conservée ;
- la migration legacy ne fait plus de travail redondant ;
- le diff reste minuscule et strictement centré sur ce comportement.

Ce qui n’a pas été changé :
- aucune structure du bloc `pokemon` ;
- aucun chemin par défaut ;
- aucune UI ;
- aucun runtime ;
- aucune lecture de `data/pokemon/...` ;
- aucune config globale supplémentaire.

## 2. Problème exact corrigé
Le code actuel avait encore une incohérence de responsabilité :

- `ProjectManifest` savait déjà fournir une valeur par défaut correcte quand `pokemon` est absent ;
- malgré cela, `migrateProjectManifestJson(...)` ajoutait encore un `pokemon: {}` vide dans le JSON legacy.

Techniquement, ce n’était pas cassant, mais c’était bancal pour trois raisons :
- la compatibilité était gérée à deux endroits au lieu d’un ;
- la migration legacy modifiait un champ qui n’avait pas besoin d’être migré ;
- cela brouillait la frontière entre “normaliser un vieux payload cassé” et “laisser le modèle appliquer ses defaults”.

## 3. Périmètre inclus
- suppression de l’injection redondante de `pokemon` dans `legacy_editor_json_compat.dart` ;
- ajout d’un test ciblé `map_core` qui prouve que l’absence de `pokemon` continue à retomber proprement sur `ProjectPokemonConfig()` ;
- revalidation ciblée des tests `map_core` et `map_editor` liés à la config projet Pokémon.

## 4. Périmètre explicitement exclu
- aucun changement dans `ProjectPokemonConfig` ;
- aucun changement dans `project_manifest.dart` ;
- aucun changement dans les chemins par défaut ;
- aucun changement dans `project_pokemon_config_test.dart` ;
- aucun changement de structure JSON ;
- aucune lecture des données Pokémon détaillées ;
- aucun refactor de migration hors ce point précis ;
- aucun fichier généré régénéré ;
- aucune modification de config globale du repo ou des packages.

## 5. Décisions techniques prises
### 5.1 Retirer la migration redondante
J’ai supprimé :

```dart
if (!next.containsKey('pokemon')) {
  next['pokemon'] = <String, dynamic>{};
}
```

La raison est simple : ce comportement est déjà correctement couvert par :

```dart
@Default(ProjectPokemonConfig()) ProjectPokemonConfig pokemon,
```

dans `ProjectManifest`.

### 5.2 Ajouter un test au bon niveau
J’ai ajouté un test dans `packages/map_core/test/legacy_editor_json_compat_collision_test.dart` pour verrouiller explicitement le comportement attendu :
- un ancien manifest sans bloc `pokemon` passe toujours par la migration ;
- `ProjectManifest.fromJson(...)` reconstruit bien `manifest.pokemon == const ProjectPokemonConfig()`.

Ce test est plus honnête que de laisser la migration injecter le champ silencieusement.

## 6. Justification de chaque changement
### 6.1 `packages/map_core/lib/src/io/legacy_editor_json_compat.dart`
Changement :
- suppression de l’injection de `pokemon`.

Justification :
- le fallback existe déjà au niveau du modèle ;
- garder cette injection dans la migration ajoute une responsabilité inutile ;
- enlever cette ligne réduit le risque de divergences futures entre migration et modèle.

### 6.2 `packages/map_core/test/legacy_editor_json_compat_collision_test.dart`
Changement :
- ajout d’un test ciblé sur l’absence du bloc `pokemon`.

Justification :
- on prouve le comportement réel au lieu de le supposer ;
- on verrouille la régression exacte que ce mini-fix touche ;
- on reste dans un diff minimal et reviewable.

## 7. Liste exacte des fichiers modifiés
- `packages/map_core/lib/src/io/legacy_editor_json_compat.dart`
- `packages/map_core/test/legacy_editor_json_compat_collision_test.dart`
- `reports/pokemon-project-config-mini-fix-round-1.md`

## 8. Liste exacte des fichiers volontairement non touchés
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/project_manifest.freezed.dart`
- `packages/map_core/lib/src/models/project_manifest.g.dart`
- `packages/map_editor/test/project_pokemon_config_test.dart`
- `packages/map_core/analysis_options.yaml`

Pourquoi :
- ils sont cohérents pour ce mini-fix ;
- aucun défaut objectif supplémentaire n’a été constaté sur leur périmètre ;
- les toucher aurait élargi inutilement le scope.

## 9. Commandes réellement exécutées
### 9.1 Tests ciblés `map_core`
```bash
cd /Users/karim/Project/pokemonProject/packages/map_core
dart test test/legacy_editor_json_compat_collision_test.dart
```

Résultat réel :
```text
00:00 +0: legacy collision profile compat migrates broken manual house profile from full padding base to authored silhouette
00:00 +1: legacy collision profile compat migrates broken manual house profile from full padding base to authored silhouette
00:00 +1: legacy collision profile compat unknown legacy keys do not prevent manifest parsing
00:00 +2: legacy collision profile compat unknown legacy keys do not prevent manifest parsing
00:00 +2: legacy collision profile compat missing pokemon config still falls back to the manifest default
00:00 +3: legacy collision profile compat missing pokemon config still falls back to the manifest default
00:00 +3: All tests passed!
```

### 9.2 Tests ciblés `map_editor`
```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor
flutter test test/project_pokemon_config_test.dart
```

Résultat réel :
```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/project_pokemon_config_test.dart
00:01 +0: Project pokemon config loads an older project without pokemon config and applies defaults
00:01 +1: Project pokemon config creates a new project with the default lightweight pokemon config
00:01 +2: Project pokemon config round-trips pokemon config through save and load without corruption
00:01 +3: Project pokemon config loads project config without reading pokemon data files
00:01 +4: Project pokemon config does not recreate data or assets at the monorepo root
00:01 +5: All tests passed!
```

### 9.3 Analyse ciblée `map_core`
```bash
cd /Users/karim/Project/pokemonProject/packages/map_core
dart analyze lib/src/io/legacy_editor_json_compat.dart lib/src/models/project_manifest.dart test/legacy_editor_json_compat_collision_test.dart
```

Résultat réel :
```text
Analyzing legacy_editor_json_compat.dart, project_manifest.dart, legacy_editor_json_compat_collision_test.dart...
No issues found!
```

### 9.4 Analyse ciblée `map_editor`
```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor
flutter analyze --no-pub test/project_pokemon_config_test.dart
```

Résultat réel :
```text
Analyzing project_pokemon_config_test.dart...
No issues found! (ran in 2.0s)
```

### 9.5 Vérification racine monorepo
```bash
cd /Users/karim/Project/pokemonProject
find . -maxdepth 2 \( -path './data' -o -path './assets' \) -print
```

Résultat réel :
```text

```

### 9.6 État Git ciblé
```bash
cd /Users/karim/Project/pokemonProject
git status --short
git diff --stat -- \
  packages/map_core/lib/src/io/legacy_editor_json_compat.dart \
  packages/map_core/test/legacy_editor_json_compat_collision_test.dart \
  packages/map_editor/test/project_pokemon_config_test.dart \
  reports/pokemon-project-config-mini-fix-round-1.md
git ls-files --others --exclude-standard \
  packages/map_core/test/legacy_editor_json_compat_collision_test.dart \
  packages/map_editor/test/project_pokemon_config_test.dart \
  reports/pokemon-project-config-mini-fix-round-1.md
```

## 10. Résultats réels des commandes Git
### 10.1 `git status --short`
```text
 M packages/map_core/lib/src/io/legacy_editor_json_compat.dart
 M packages/map_core/test/legacy_editor_json_compat_collision_test.dart
?? reports/pokemon-project-config-mini-fix-round-1.md
```

### 10.2 `git diff --stat -- ...`
```text
 packages/map_core/lib/src/io/legacy_editor_json_compat.dart        | 3 ---
 .../map_core/test/legacy_editor_json_compat_collision_test.dart    | 7 +++++++
 2 files changed, 7 insertions(+), 3 deletions(-)
```

### 10.3 `git ls-files --others --exclude-standard ...`
```text
reports/pokemon-project-config-mini-fix-round-1.md
```

Note honnête :
- il n’y a pas de fichier non suivi dans le périmètre ciblé de ce mini-fix ;
- le seul fichier non suivi du périmètre ciblé est ce rapport lui-même ;
- le working tree peut contenir d’autres historiques de lots déjà commités ou nettoyés, mais rien d’autre n’apparaît ici dans le diff ciblé.

## 11. Bundle de review
Commande exécutée :
```bash
cd /Users/karim/Project/pokemonProject
./review_bundle.sh
```

Chemin du bundle généré :
```text
.review/review-20260409-231404.txt
```

Contenu intégral du bundle :
```text
# REVIEW BUNDLE

Generated at: 2026-04-09 23:14:04
Repository: pokemonProject
Branch: main
Base ref: HEAD
Head commit: 5df1f70b142ec4f0bf2077e10d2923ed480abe5e

## GIT STATUS --SHORT

 M packages/map_core/lib/src/io/legacy_editor_json_compat.dart
 M packages/map_core/test/legacy_editor_json_compat_collision_test.dart
?? reports/pokemon-project-config-mini-fix-round-1.md

## GIT DIFF --STAT

 packages/map_core/lib/src/io/legacy_editor_json_compat.dart        | 3 ---
 .../map_core/test/legacy_editor_json_compat_collision_test.dart    | 7 +++++++
 2 files changed, 7 insertions(+), 3 deletions(-)

## CHANGED FILES

packages/map_core/lib/src/io/legacy_editor_json_compat.dart
packages/map_core/test/legacy_editor_json_compat_collision_test.dart

## RECENT COMMITS

5df1f70 LOT 10-a-b:Add lightweight Pokémon config block to project manifest with defaults and targeted tests
ed6ceb1 LOT 9: Introduce `PokemonProjectValidator` for comprehensive Pokémon project validation
318a544 LOT 8: Add `PokemonWriteRepository` with integration tests for local Pokémon data saving
ff4a928 LOT 7: Introduce `PokemonReadRepository` abstraction and add tests
b4e651b LOT 6: Add Pokedex list use case and application model for minimal UI projection
c700532 LOT 5: Add Pokémon data models and reader service for structured JSON operations
f808d3f Seed Pokémon demo data use case with idempotent JSON generation
c4d2983 Enrich Pokémon JSON storage contract with manifest and minimal catalog structures
e266743 Add use case to initialize Pokémon project storage structure
c41fe7e Add data and assets folder structure with .gitkeep placeholders for future Pokémon content
3d81349 Add tests to confirm grid-based collision granularity limitations and document runtime constraints
8675f74 Add migration for broken legacy manual collision profiles
59dce2a Audit runtime collision logic to validate `cells` as the active source of truth
2aa52f4 Fix collision base model to support authored shapes and resolve padding-based overcapture issues
fc7cf31 Enhance polygon rasterization logic and add backend cell preview to collision editor

## FULL DIFF

diff --git a/packages/map_core/lib/src/io/legacy_editor_json_compat.dart b/packages/map_core/lib/src/io/legacy_editor_json_compat.dart
index 0b2933d..3adfdd6 100644
--- a/packages/map_core/lib/src/io/legacy_editor_json_compat.dart
+++ b/packages/map_core/lib/src/io/legacy_editor_json_compat.dart
@@ -12,9 +12,6 @@ Map<String, dynamic> migrateProjectManifestJson(Map<String, dynamic> raw) {
   if (!next.containsKey('characters')) {
     next['characters'] = <dynamic>[];
   }
-  if (!next.containsKey('pokemon')) {
-    next['pokemon'] = <String, dynamic>{};
-  }
   final settings = raw['settings'];
   if (settings is Map) {
     final migratedSettings =
diff --git a/packages/map_core/test/legacy_editor_json_compat_collision_test.dart b/packages/map_core/test/legacy_editor_json_compat_collision_test.dart
index c316e47..ee39cab 100644
--- a/packages/map_core/test/legacy_editor_json_compat_collision_test.dart
+++ b/packages/map_core/test/legacy_editor_json_compat_collision_test.dart
@@ -30,6 +30,13 @@ void main() {
       expect(
           manifest.elements.single.collisionProfile!.cells, _houseShapeCells);
     });
+
+    test('missing pokemon config still falls back to the manifest default', () {
+      final migrated = migrateProjectManifestJson(_legacyBrokenProjectJson());
+      final manifest = ProjectManifest.fromJson(migrated);
+
+      expect(manifest.pokemon, const ProjectPokemonConfig());
+    });
   });
 }
```

## 12. Code intégral de chaque fichier modifié manuellement
### 12.1 `packages/map_core/lib/src/io/legacy_editor_json_compat.dart`
```dart
Map<String, dynamic> migrateProjectManifestJson(Map<String, dynamic> raw) {
  final next = Map<String, dynamic>.from(raw);
  if (!next.containsKey('dialogues')) {
    next['dialogues'] = <dynamic>[];
  }
  if (!next.containsKey('dialogueFolders')) {
    next['dialogueFolders'] = <dynamic>[];
  }
  if (!next.containsKey('tilesetFolders')) {
    next['tilesetFolders'] = <dynamic>[];
  }
  if (!next.containsKey('characters')) {
    next['characters'] = <dynamic>[];
  }
  final settings = raw['settings'];
  if (settings is Map) {
    final migratedSettings =
        Map<String, dynamic>.from(settings.cast<String, dynamic>());
    if (!migratedSettings.containsKey('defaultPlayerCharacterId') &&
        migratedSettings['playerCharacterId'] != null) {
      migratedSettings['defaultPlayerCharacterId'] =
          migratedSettings['playerCharacterId'];
    }
    next['settings'] = migratedSettings;
  }
  final legacyCategories = raw['terrainPresetCategories'];
  if (!next.containsKey('terrainCategories') && legacyCategories is List) {
    next['terrainCategories'] = legacyCategories
        .whereType<Map>()
        .map(
            (entry) => Map<String, dynamic>.from(entry.cast<String, dynamic>()))
        .where((entry) => entry['kind'] == 'terrain')
        .map((entry) {
      entry.remove('kind');
      return entry;
    }).toList(growable: false);
  }
  if (!next.containsKey('pathCategories') && legacyCategories is List) {
    next['pathCategories'] = legacyCategories
        .whereType<Map>()
        .map(
            (entry) => Map<String, dynamic>.from(entry.cast<String, dynamic>()))
        .where((entry) => entry['kind'] == 'path')
        .map((entry) {
      entry.remove('kind');
      return entry;
    }).toList(growable: false);
  }

  final pathPresets = raw['pathPresets'];
  if (pathPresets is! List) {
    final trainers = raw['trainers'];
    if (trainers is List) {
      next['trainers'] = trainers.map((entry) {
        if (entry is! Map) {
          return entry;
        }
        final trainer =
            Map<String, dynamic>.from(entry.cast<String, dynamic>());
        if (!trainer.containsKey('characterId')) {
          final legacyCharacterId = trainer['overworldCharacterId'] ??
              trainer['spriteCharacterId'] ??
              trainer['characterRef'];
          if (legacyCharacterId != null) {
            trainer['characterId'] = legacyCharacterId;
          }
        }
        return trainer;
      }).toList(growable: false);
    }
    _migrateElementCollisionProfiles(next);
    return next;
  }

  next['pathPresets'] = pathPresets.map((entry) {
    if (entry is! Map) {
      return entry;
    }
    final preset = Map<String, dynamic>.from(entry.cast<String, dynamic>());
    if (!preset.containsKey('surfaceKind')) {
      preset['surfaceKind'] = _legacyPathSurfaceKindValue(
        preset['groundTerrainType']?.toString(),
      );
    }
    return preset;
  }).toList(growable: false);

  final trainers = raw['trainers'];
  if (trainers is List) {
    next['trainers'] = trainers.map((entry) {
      if (entry is! Map) {
        return entry;
      }
      final trainer = Map<String, dynamic>.from(entry.cast<String, dynamic>());
      if (!trainer.containsKey('characterId')) {
        final legacyCharacterId = trainer['overworldCharacterId'] ??
            trainer['spriteCharacterId'] ??
            trainer['characterRef'];
        if (legacyCharacterId != null) {
          trainer['characterId'] = legacyCharacterId;
        }
      }
      return trainer;
    }).toList(growable: false);
  }

  _migrateElementCollisionProfiles(next);

  return next;
}

void _migrateElementCollisionProfiles(Map<String, dynamic> manifest) {
  // Collision profile compatibility:
  //
  // Older editor builds could save a "manual" building silhouette in a broken
  // shape:
  // - `source == manual`
  // - `padding == 0`
  // - `cells == full padding-derived rectangle`
  // - `manualAddedCells == intended building silhouette`
  //
  // The modern editor preview can reinterpret that payload in memory, but the
  // runtime only reads `collisionProfile.cells`. If we do not normalize the
  // manifest at load time, the runtime keeps blocking the full sprite bounds.
  //
  // We therefore repair only the proven legacy pattern here, at manifest-load
  // time, so editor, save/reload, and runtime all agree on the same final
  // `cells` without introducing a new runtime contract.
  final rawElements = manifest['elements'];
  if (rawElements is! List) {
    return;
  }

  final settings = manifest['settings'];
  final tileWidth =
      settings is Map ? (_asInt(settings['tileWidth']) ?? 16) : 16;
  final tileHeight =
      settings is Map ? (_asInt(settings['tileHeight']) ?? 16) : 16;

  manifest['elements'] = rawElements.map((entry) {
    if (entry is! Map) {
      return entry;
    }
    final element = Map<String, dynamic>.from(entry.cast<String, dynamic>());
    final rawProfile = element['collisionProfile'];
    if (rawProfile is! Map) {
      return element;
    }

    final sourceSize = _readElementSourceSize(element);
    if (sourceSize == null) {
      return element;
    }

    element['collisionProfile'] = _migrateCollisionProfileJson(
      rawProfile.cast<String, dynamic>(),
      sourceWidth: sourceSize.$1,
      sourceHeight: sourceSize.$2,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
    );
    return element;
  }).toList(growable: false);
}

Map<String, dynamic> _migrateCollisionProfileJson(
  Map<String, dynamic> rawProfile, {
  required int sourceWidth,
  required int sourceHeight,
  required int tileWidth,
  required int tileHeight,
}) {
  final profile = Map<String, dynamic>.from(rawProfile);
  final sourceMode = profile['source']?.toString() ?? 'generated';
  final padding = _readPadding(profile['padding']);
  final currentCells = _normalizeCells(
    profile['cells'],
    sourceWidth: sourceWidth,
    sourceHeight: sourceHeight,
  );
  final shapeCells = _normalizeCells(
    profile['shapeCells'],
    sourceWidth: sourceWidth,
    sourceHeight: sourceHeight,
  );
  final manualAddedCells = _normalizeCells(
    profile['manualAddedCells'],
    sourceWidth: sourceWidth,
    sourceHeight: sourceHeight,
  );
  final manualRemovedCells = _normalizeCells(
    profile['manualRemovedCells'],
    sourceWidth: sourceWidth,
    sourceHeight: sourceHeight,
  );
  final paddingBaseCells = _deriveBaseCellsFromPadding(
    sourceWidth: sourceWidth,
    sourceHeight: sourceHeight,
    tileWidth: tileWidth,
    tileHeight: tileHeight,
    padding: padding,
  );

  if (sourceMode == 'manual') {
    // Legacy broken payload:
    // `cells` persisted the full padding-derived base while the intended house
    // silhouette lived only in `manualAddedCells`. This is the exact failure
    // mode observed on the real `petite_maison_toit_bleu` project file.
    if (shapeCells.isEmpty &&
        manualAddedCells.isNotEmpty &&
        manualRemovedCells.isEmpty &&
        _sameCells(currentCells, paddingBaseCells)) {
      profile['shapeCells'] = _toJsonCells(manualAddedCells);
      profile['manualAddedCells'] = const <Map<String, dynamic>>[];
      profile['manualRemovedCells'] = const <Map<String, dynamic>>[];
      profile['cells'] = _toJsonCells(manualAddedCells);
      return profile;
    }

    // Older manual profiles may have stored the intended authored silhouette
    // directly in `shapeCells`/`cells` while still keeping stale manual deltas.
    // If the base rectangle is gone already, trust the authored shape and clear
    // the no-longer-meaningful deltas to prevent reapplying them later.
    if (shapeCells.isNotEmpty && !_sameCells(currentCells, paddingBaseCells)) {
      profile['manualAddedCells'] = const <Map<String, dynamic>>[];
      profile['manualRemovedCells'] = const <Map<String, dynamic>>[];
      profile['cells'] = _toJsonCells(shapeCells);
      return profile;
    }
  }

  return profile;
}

({int, int})? _readElementSourceSize(Map<String, dynamic> element) {
  final frames = element['frames'];
  if (frames is! List || frames.isEmpty) {
    return null;
  }
  final firstFrame = frames.first;
  if (firstFrame is! Map) {
    return null;
  }
  final source = firstFrame['source'];
  if (source is! Map) {
    return null;
  }
  final width = _asInt(source['width']);
  final height = _asInt(source['height']);
  if (width == null || height == null || width <= 0 || height <= 0) {
    return null;
  }
  return (width, height);
}

int? _asInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '');
}

String _legacyPathSurfaceKindValue(String? terrainType) {
  switch (terrainType) {
    case 'water':
      return 'water';
    case 'bridge':
      return 'bridge';
    case 'stair':
      return 'stairs';
    default:
      return 'ground';
  }
}

({int top, int right, int bottom, int left}) _readPadding(Object? value) {
  if (value is Map) {
    return (
      top: _asInt(value['top']) ?? 0,
      right: _asInt(value['right']) ?? 0,
      bottom: _asInt(value['bottom']) ?? 0,
      left: _asInt(value['left']) ?? 0,
    );
  }
  return (top: 0, right: 0, bottom: 0, left: 0);
}

Set<GridPos> _normalizeCells(
  Object? rawCells, {
  required int sourceWidth,
  required int sourceHeight,
}) {
  if (rawCells is! List) {
    return <GridPos>{};
  }
  return rawCells
      .whereType<Map>()
      .map((cell) => cell.cast<String, dynamic>())
      .map((cell) => GridPos(x: _asInt(cell['x']) ?? -1, y: _asInt(cell['y']) ?? -1))
      .where((cell) => cell.x >= 0 && cell.y >= 0)
      .where(
        (cell) =>
            cell.x < sourceWidth &&
            cell.y < sourceHeight,
      )
      .toSet();
}

List<Map<String, dynamic>> _toJsonCells(Set<GridPos> cells) {
  final sorted = cells.toList()
    ..sort((a, b) {
      final yCompare = a.y.compareTo(b.y);
      if (yCompare != 0) {
        return yCompare;
      }
      return a.x.compareTo(b.x);
    });
  return sorted
      .map((cell) => <String, dynamic>{'x': cell.x, 'y': cell.y})
      .toList(growable: false);
}

Set<GridPos> _deriveBaseCellsFromPadding({
  required int sourceWidth,
  required int sourceHeight,
  required int tileWidth,
  required int tileHeight,
  required ({int top, int right, int bottom, int left}) padding,
}) {
  final left = padding.left;
  final top = padding.top;
  final right = sourceWidth - 1 - padding.right;
  final bottom = sourceHeight - 1 - padding.bottom;
  if (left > right || top > bottom) {
    return <GridPos>{};
  }
  return <GridPos>{
    for (var y = top ~/ tileHeight; y <= bottom ~/ tileHeight; y++)
      for (var x = left ~/ tileWidth; x <= right ~/ tileWidth; x++)
        GridPos(x: x, y: y),
  };
}

bool _sameCells(Set<GridPos> a, Set<GridPos> b) {
  if (a.length != b.length) {
    return false;
  }
  return a.containsAll(b);
}
```

### 12.2 `packages/map_core/test/legacy_editor_json_compat_collision_test.dart`
```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('legacy collision profile compat', () {
    test(
        'migrates broken manual house profile from full padding base to authored silhouette',
        () {
      final migrated = migrateProjectManifestJson(_legacyBrokenProjectJson());
      final manifest = ProjectManifest.fromJson(migrated);
      final profile = manifest.elements.single.collisionProfile!;

      expect(profile.source, ElementCollisionProfileSource.manual);
      expect(profile.shapeCells, _houseShapeCells);
      expect(profile.manualAddedCells, isEmpty);
      expect(profile.manualRemovedCells, isEmpty);
      expect(profile.cells, _houseShapeCells);
      expect(profile.cells.length, 14);
    });

    test('unknown legacy keys do not prevent manifest parsing', () {
      final raw = _legacyBrokenProjectJson();
      (((raw['elements'] as List).single
              as Map<String, dynamic>)['collisionProfile']
          as Map<String, dynamic>)['pixelMask'] = <int>[1, 0, 1];
      final migrated = migrateProjectManifestJson(raw);
      final manifest = ProjectManifest.fromJson(migrated);

      expect(manifest.elements.single.collisionProfile, isNotNull);
      expect(
          manifest.elements.single.collisionProfile!.cells, _houseShapeCells);
    });

    test('missing pokemon config still falls back to the manifest default', () {
      final migrated = migrateProjectManifestJson(_legacyBrokenProjectJson());
      final manifest = ProjectManifest.fromJson(migrated);

      expect(manifest.pokemon, const ProjectPokemonConfig());
    });
  });
}

Map<String, dynamic> _legacyBrokenProjectJson() {
  return <String, dynamic>{
    'name': 'Legacy',
    'maps': <dynamic>[],
    'tilesets': <dynamic>[
      <String, dynamic>{
        'id': 'house',
        'name': 'house',
        'relativePath': 'tilesets/house.png',
      },
    ],
    'elementCategories': <dynamic>[
      <String, dynamic>{'id': 'building', 'name': 'building'},
    ],
    'settings': <String, dynamic>{
      'tileWidth': 16,
      'tileHeight': 16,
    },
    'elements': <dynamic>[
      <String, dynamic>{
        'id': 'petite_maison_toit_bleu',
        'name': 'petite maison toit bleu',
        'tilesetId': 'house',
        'categoryId': 'building',
        'frames': <dynamic>[
          <String, dynamic>{
            'tilesetId': '',
            'source': <String, dynamic>{
              'x': 0,
              'y': 341,
              'width': 6,
              'height': 7,
            },
          },
        ],
        'presetKind': 'building',
        'collisionProfile': <String, dynamic>{
          'source': 'manual',
          'padding': const <String, dynamic>{
            'top': 0,
            'right': 0,
            'bottom': 0,
            'left': 0,
          },
          'shapeCells': <dynamic>[],
          'cells': <dynamic>[
            for (var y = 0; y < 7; y++)
              for (var x = 0; x < 6; x++) <String, dynamic>{'x': x, 'y': y},
          ],
          'manualAddedCells': _houseShapeCells
              .map((cell) => <String, dynamic>{'x': cell.x, 'y': cell.y})
              .toList(growable: false),
          'manualRemovedCells': <dynamic>[],
        },
      },
    ],
  };
}

const List<GridPos> _houseShapeCells = <GridPos>[
  GridPos(x: 0, y: 3),
  GridPos(x: 1, y: 3),
  GridPos(x: 2, y: 3),
  GridPos(x: 3, y: 3),
  GridPos(x: 4, y: 3),
  GridPos(x: 5, y: 3),
  GridPos(x: 1, y: 4),
  GridPos(x: 2, y: 4),
  GridPos(x: 3, y: 4),
  GridPos(x: 4, y: 4),
  GridPos(x: 1, y: 5),
  GridPos(x: 2, y: 5),
  GridPos(x: 3, y: 5),
  GridPos(x: 4, y: 5),
];
```

## 13. Explication fichier par fichier
- `legacy_editor_json_compat.dart` :
  - avant : la migration ajoutait un bloc `pokemon` vide ;
  - après : elle laisse le JSON legacy intact sur ce point et délègue le fallback au modèle ;
  - intérêt : réduction de redondance et séparation plus propre des responsabilités.

- `legacy_editor_json_compat_collision_test.dart` :
  - ajout d’un test centré sur l’absence du bloc `pokemon` ;
  - intérêt : prouver que la compatibilité reste vraie après suppression de la migration redondante.

## 14. Limites restantes
- ce mini-fix ne cherche pas à nettoyer d’autres choix du lot 10 déjà commités si ces choix sont cohérents ;
- il ne traite pas les warnings `build_runner` déjà présents sur d’autres dépendances ;
- il ne revoit pas la stratégie globale de migration du manifest au-delà de ce point précis.

## 15. Conclusion honnête
Le mini-fix reste très petit et vraiment ciblé. Il n’ajoute aucune fonctionnalité : il retire un fallback redondant dans la migration et le remplace par une preuve de comportement au bon niveau, via test.

Le résultat est plus propre parce que :
- la compatibilité “ancien projet sans bloc `pokemon`” repose maintenant sur une seule vérité claire : le default du modèle ;
- le diff est très réduit ;
- rien d’autre n’a été touché dans le périmètre projet/Pokémon.
