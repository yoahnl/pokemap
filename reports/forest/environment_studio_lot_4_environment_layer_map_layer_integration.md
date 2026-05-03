# Environment Studio Lot 4 — Environment Layer MapLayer Integration V0

## 1. Résumé exécutif

Intégration du payload **Environment Layer** dans le schéma carte : nouveau **`MapLayerKind.environment`** (JSON `"environment"`), variante Freezed **`MapLayer.environment`** avec **`EnvironmentLayerContent`** sérialisée via codec externe, opérations **`addMapLayer`** / **`setEnvironmentLayerContent`**, validation **`MapValidator`** (cible tuiles + tailles de masques), redimensionnement **`resizeMapData`** des masques par zone. **build_runner** régénère **`map_layer.freezed.dart`** et **`map_layer.g.dart`**. Aucun **ProjectManifest**, aucune UI Studio, aucun générateur. Corrections downstream neutres : **map_editor** (préfixe layer id, labels panneaux), **map_runtime** (`layer.when` exhaustif).

## 2. Périmètre du lot

**Inclus :** modèles **map_core**, codec JSON, **map_layers**, **map_resize**, **MapValidator**, exports **map_core.dart**, tests Lot 4, régressions Env-2/Env-3, fixes compilation **map_editor** / **map_runtime**.

**Exclus :** **ProjectManifest**, UI Environment Studio, générateur de placements, **map_gameplay**, **map_battle**, fixtures projet.

## 3. Audit initial des switchs impactés

| Zone | Fichier | Action |
|------|---------|--------|
| `MapLayer.map` | `map_layers.dart` `_copyLayer` | Ajout branche `environment` |
| `MapLayer.map` | `map_resize.dart` | Ajout `environment` + resize masques |
| `MapLayer.map` | `validators.dart` `_validateLayer` | Ajout validation environment |
| `MapLayer.when` | `runtime_manifest_tilesets.dart` | Deux `when` : ajout `environment` no-op |
| `MapLayer.map` | `layers_panel.dart` | Icône + libellé liste layers |
| Switch types layer | `map_inspector_panel.dart` | Libellés inspector |
| `MapLayerKind` switch | `layer_use_cases.dart` | Préfixe `l_environment` |

Aucun autre `layer.when` dans le dépôt hors ce fichier runtime.

## 4. Décisions d’intégration MapLayer

- **`EnvironmentLayerContent.emptyContent`** : `static const` pour **`@Default`** Freezed + **`decode`** null.
- **`factory EnvironmentLayerContent.empty`** : si pas de cible tuiles après normalisation, retour **identité** `emptyContent`.
- Union JSON **`runtimeType`: `'environment'`** (convention existante Freezed).
- **`properties`** sur **`MapLayer.environment`** aligné **path/surface** (clés non vides validées).

## 5. Codec JSON EnvironmentLayerContent

Fichier **`packages/map_core/lib/src/operations/environment_layer_content_json_codec.dart`** : **`decodeEnvironmentLayerContent`**, **`encodeEnvironmentLayerContent`**, décodage **Area / Mask / GenerationParams** avec **`FormatException`** métier ; **`EnvironmentPreset`** non encodé dans ce lot.

## 6. Modifications MapLayer / MapLayerKind

- **`enums.dart`** : **`MapLayerKind.environment`** → **`@JsonValue('environment')`**.
- **`map_layer.dart`** : **`MapLayer.environment`** avec **`@JsonKey(fromJson: decodeEnvironmentLayerContent, toJson: encodeEnvironmentLayerContent)`** et **`@Default(EnvironmentLayerContent.emptyContent)`**.

## 7. Modifications opérations map_layers

- **`addMapLayer`** : **`MapLayerKind.environment`** → **`MapLayer.environment`** (pas de **tileTilesetId**).
- **`_copyLayer`** : préserve **content** et **properties** (non passés à **copyWith** — inchangés par rename / visibilité / opacité).
- **`setEnvironmentLayerContent`** : remplace uniquement **content**, erreurs si layer absent ou non-environment.

## 8. Modifications validation

- **`_validateLayer(..., map: map)`** : **targetTileLayerId** doit référencer un **TileLayer** existant (≠ self) ; chaque **EnvironmentArea.mask** : **`width` × `height` = map.size`** ; clés **properties** non vides.

## 9. Corrections downstream neutres

- **`layer_use_cases.dart`** : préfixe ids auto **`l_environment`** (usage futur ; pas de bouton ajout layer dans ce lot).
- **`layers_panel.dart`** : icône nuage + libellé **`environment · N area(s)`**.
- **`map_inspector_panel.dart`** : libellés « Environment Layer » / « Environment layer active ».
- **`runtime_manifest_tilesets.dart`** : **`environment: (_, …) {}`** pour ne pas casser l’exhaustivité **`when`**.

## 10. Pourquoi aucun ProjectManifest / UI / générateur dans ce lot

Alignement roadmap : ce lot pose **contrat carte JSON** et **validation locale** ; presets projet et Studio UI sont **Environment-5+**.

## 11. Fichiers modifiés

- **map_core :** `lib/map_core.dart`, `lib/src/models/enums.dart`, `lib/src/models/environment.dart`, `lib/src/models/map_layer.dart`, `lib/src/models/map_layer.freezed.dart`, `lib/src/models/map_layer.g.dart`, `lib/src/operations/environment_layer_content_json_codec.dart`, `lib/src/operations/map_layers.dart`, `lib/src/operations/map_resize.dart`, `lib/src/validation/validators.dart`
- **Tests :** `test/environment_layer_content_json_codec_test.dart`, `test/environment_layer_map_layer_integration_test.dart`
- **map_editor :** `lib/src/application/use_cases/layer_use_cases.dart`, `lib/src/ui/panels/layers_panel.dart`, `lib/src/ui/panels/map_inspector_panel.dart`
- **map_runtime :** `lib/src/application/runtime_manifest_tilesets.dart`

## 12. Tests ajoutés

- **`environment_layer_content_json_codec_test.dart`** : 11 tests (null, minimal, trim, areas, roundtrip, erreurs).
- **`environment_layer_map_layer_integration_test.dart`** : 17 tests (MapLayer, addMapLayer, setEnvironmentLayerContent, MapValidator).

## 13. Commandes exécutées

```bash
cd /Users/karim/Project/pokemonProject/packages/map_core
dart run build_runner build --delete-conflicting-outputs
dart format lib/src/models/enums.dart lib/src/models/environment.dart lib/src/models/map_layer.dart lib/src/operations/environment_layer_content_json_codec.dart lib/src/operations/map_layers.dart lib/src/operations/map_resize.dart lib/src/validation/validators.dart test/environment_layer_content_json_codec_test.dart test/environment_layer_map_layer_integration_test.dart
dart analyze lib/src/models/enums.dart lib/src/models/environment.dart lib/src/models/map_layer.dart lib/src/operations/environment_layer_content_json_codec.dart lib/src/operations/map_layers.dart lib/src/operations/map_resize.dart lib/src/validation/validators.dart test/environment_layer_content_json_codec_test.dart test/environment_layer_map_layer_integration_test.dart
dart analyze   # package map_core entier
dart test test/environment_layer_content_json_codec_test.dart --reporter expanded
dart test test/environment_layer_map_layer_integration_test.dart --reporter expanded
dart test test/environment_core_models_test.dart test/environment_layer_content_test.dart --reporter expanded
dart test
cd ../map_editor && flutter analyze lib/src/application/use_cases/layer_use_cases.dart lib/src/ui/panels/layers_panel.dart lib/src/ui/panels/map_inspector_panel.dart
cd ../map_runtime && flutter analyze lib/src/application/runtime_manifest_tilesets.dart
```

## 14. Résultats des commandes

- **`dart analyze`** (ciblés puis package **map_core**) : **`No issues found!`**
- **`flutter analyze`** (fichiers **map_editor** / **map_runtime** modifiés) : **`No issues found!`**
- **`dart test`** (codec seul) : **`All tests passed!`** (+11)
- **`dart test`** (intégration seul) : **`All tests passed!`** (+17)
- **`dart test`** Env-2 + Env-3 : **`All tests passed!`** (+75)
- **`dart test`** (suite **map_core** complète) : ligne finale **`00:02 +1237: All tests passed!`**

## 15. Git status initial et final

- **Initial (session outil) :** `git status --short` vide (arbre suivi sans modification résiduelle affichée).
- **Final :**

```
 M packages/map_core/lib/map_core.dart
 M packages/map_core/lib/src/models/enums.dart
 M packages/map_core/lib/src/models/environment.dart
 M packages/map_core/lib/src/models/map_layer.dart
 M packages/map_core/lib/src/models/map_layer.freezed.dart
 M packages/map_core/lib/src/models/map_layer.g.dart
 M packages/map_core/lib/src/operations/map_layers.dart
 M packages/map_core/lib/src/operations/map_resize.dart
 M packages/map_core/lib/src/validation/validators.dart
 M packages/map_editor/lib/src/application/use_cases/layer_use_cases.dart
 M packages/map_editor/lib/src/ui/panels/layers_panel.dart
 M packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart
 M packages/map_runtime/lib/src/application/runtime_manifest_tilesets.dart
?? packages/map_core/lib/src/operations/environment_layer_content_json_codec.dart
?? packages/map_core/test/environment_layer_content_json_codec_test.dart
?? packages/map_core/test/environment_layer_map_layer_integration_test.dart
?? reports/forest/environment_studio_lot_4_environment_layer_map_layer_integration.md
```

## 16. Contenu complet des fichiers écrits à la main

### 16.1 `packages/map_core/lib/src/operations/environment_layer_content_json_codec.dart`

```dart
import '../models/environment.dart';

/// Codec JSON pour [EnvironmentLayerContent] et sous-structures (Lot Environment-4).
/// Les [EnvironmentPreset] restent hors périmètre manifest / carte.
EnvironmentLayerContent decodeEnvironmentLayerContent(Object? json) {
  if (json == null) {
    return EnvironmentLayerContent.emptyContent;
  }
  if (json is! Map) {
    throw FormatException(
      'EnvironmentLayerContent JSON must be a Map or null, got ${json.runtimeType}',
    );
  }
  final map = Map<String, dynamic>.from(json);

  final rawTarget = map['targetTileLayerId'];
  final String? targetTileLayerId;
  if (rawTarget == null) {
    targetTileLayerId = null;
  } else if (rawTarget is String) {
    final t = rawTarget.trim();
    targetTileLayerId = t.isEmpty ? null : t;
  } else {
    throw FormatException(
      'EnvironmentLayerContent targetTileLayerId must be a String or null',
    );
  }

  final rawAreas = map['areas'];
  final List<EnvironmentArea> areas;
  if (rawAreas == null) {
    areas = const [];
  } else if (rawAreas is List) {
    areas = rawAreas
        .map((e) => decodeEnvironmentArea(_requireMap(e, 'areas[]')))
        .toList(growable: false);
  } else {
    throw FormatException(
      'EnvironmentLayerContent areas must be a List or null, got ${rawAreas.runtimeType}',
    );
  }

  return EnvironmentLayerContent(
    targetTileLayerId: targetTileLayerId,
    areas: areas,
  );
}

/// JSON compatible `json_serializable` / persistance carte.
Map<String, dynamic> encodeEnvironmentLayerContent(
  EnvironmentLayerContent content,
) {
  return <String, dynamic>{
    if (content.targetTileLayerId != null)
      'targetTileLayerId': content.targetTileLayerId,
    'areas':
        content.areas.map(encodeEnvironmentArea).toList(growable: false),
  };
}

EnvironmentArea decodeEnvironmentArea(Map<String, dynamic> json) {
  try {
    final id = _requireString(json, 'id');
    final name = _requireString(json, 'name');
    final presetId = _requireString(json, 'presetId');
    final mask = decodeEnvironmentAreaMask(
      _requireMap(json['mask'], 'mask'),
    );
    final seed = _requireInt(json, 'seed');

    final rawOverride = json['paramsOverride'];
    final EnvironmentGenerationParams? paramsOverride;
    if (rawOverride == null) {
      paramsOverride = null;
    } else {
      paramsOverride = decodeEnvironmentGenerationParams(
        _requireMap(rawOverride, 'paramsOverride'),
      );
    }

    final rawPlacementIds = json['generatedPlacementIds'];
    final List<String>? generatedPlacementIds;
    if (rawPlacementIds == null) {
      generatedPlacementIds = null;
    } else if (rawPlacementIds is List) {
      generatedPlacementIds =
          rawPlacementIds.map((e) => e as String).toList(growable: false);
    } else {
      throw FormatException(
        'EnvironmentArea generatedPlacementIds must be a List or null',
      );
    }

    return EnvironmentArea(
      id: id,
      name: name,
      presetId: presetId,
      mask: mask,
      seed: seed,
      paramsOverride: paramsOverride,
      generatedPlacementIds: generatedPlacementIds,
    );
  } on ArgumentError catch (e) {
    throw FormatException('Invalid EnvironmentArea: ${e.message}');
  }
}

Map<String, dynamic> encodeEnvironmentArea(EnvironmentArea area) {
  return <String, dynamic>{
    'id': area.id,
    'name': area.name,
    'presetId': area.presetId,
    'mask': encodeEnvironmentAreaMask(area.mask),
    'seed': area.seed,
    if (area.paramsOverride != null)
      'paramsOverride': encodeEnvironmentGenerationParams(area.paramsOverride!),
    'generatedPlacementIds': area.generatedPlacementIds.toList(growable: false),
  };
}

EnvironmentAreaMask decodeEnvironmentAreaMask(Map<String, dynamic> json) {
  try {
    final width = _requireInt(json, 'width');
    final height = _requireInt(json, 'height');
    final rawCells = json['cells'];
    if (rawCells is! List) {
      throw FormatException(
        'EnvironmentAreaMask cells must be a List, got ${rawCells.runtimeType}',
      );
    }
    final cells = rawCells.map((e) {
      if (e is! bool) {
        throw FormatException(
          'EnvironmentAreaMask cells must be List<bool>, got element ${e.runtimeType}',
        );
      }
      return e;
    }).toList(growable: false);

    return EnvironmentAreaMask(
      width: width,
      height: height,
      cells: cells,
    );
  } on ArgumentError catch (e) {
    throw FormatException('Invalid EnvironmentAreaMask: ${e.message}');
  }
}

Map<String, dynamic> encodeEnvironmentAreaMask(EnvironmentAreaMask mask) {
  return <String, dynamic>{
    'width': mask.width,
    'height': mask.height,
    'cells': mask.cells.toList(growable: false),
  };
}

EnvironmentGenerationParams decodeEnvironmentGenerationParams(
  Map<String, dynamic> json,
) {
  try {
    return EnvironmentGenerationParams(
      density: _requireDouble(json, 'density'),
      variation: _requireDouble(json, 'variation'),
      edgeDensity: _requireDouble(json, 'edgeDensity'),
      minSpacingCells: _requireInt(json, 'minSpacingCells'),
    );
  } on ArgumentError catch (e) {
    throw FormatException(
      'Invalid EnvironmentGenerationParams: ${e.message}',
    );
  }
}

Map<String, dynamic> encodeEnvironmentGenerationParams(
  EnvironmentGenerationParams params,
) {
  return <String, dynamic>{
    'density': params.density,
    'variation': params.variation,
    'edgeDensity': params.edgeDensity,
    'minSpacingCells': params.minSpacingCells,
  };
}

Map<String, dynamic> _requireMap(Object? value, String field) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.cast<String, dynamic>();
  }
  throw FormatException('$field must be a Map, got ${value.runtimeType}');
}

String _requireString(Map<String, dynamic> json, String key) {
  final v = json[key];
  if (v is String) {
    return v;
  }
  throw FormatException('Missing or invalid String for key "$key"');
}

int _requireInt(Map<String, dynamic> json, String key) {
  final v = json[key];
  if (v is int) {
    return v;
  }
  if (v is num) {
    return v.toInt();
  }
  throw FormatException('Missing or invalid int for key "$key"');
}

double _requireDouble(Map<String, dynamic> json, String key) {
  final v = json[key];
  if (v is double) {
    return v;
  }
  if (v is int) {
    return v.toDouble();
  }
  if (v is num) {
    return v.toDouble();
  }
  throw FormatException('Missing or invalid num for key "$key"');
}
```

### 16.2 `packages/map_core/test/environment_layer_content_json_codec_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('EnvironmentLayerContent JSON codec', () {
    test('decode null => emptyContent', () {
      final c = decodeEnvironmentLayerContent(null);
      expect(c, EnvironmentLayerContent.emptyContent);
    });

    test('decode map minimal => content vide', () {
      final c = decodeEnvironmentLayerContent(<String, dynamic>{});
      expect(c.targetTileLayerId, isNull);
      expect(c.areas, isEmpty);
    });

    test('decode targetTileLayerId trimé', () {
      final c = decodeEnvironmentLayerContent(<String, dynamic>{
        'targetTileLayerId': '  decor  ',
      });
      expect(c.targetTileLayerId, 'decor');
    });

    test('decode areas absent/null => []', () {
      final a = decodeEnvironmentLayerContent(
        <String, dynamic>{'targetTileLayerId': 't'},
      );
      final b = decodeEnvironmentLayerContent(
        <String, dynamic>{'targetTileLayerId': 't', 'areas': null},
      );
      expect(a.areas, isEmpty);
      expect(b.areas, isEmpty);
    });

    test('decode area complète + paramsOverride + generatedPlacementIds', () {
      final c = decodeEnvironmentLayerContent(<String, dynamic>{
        'areas': [
          <String, dynamic>{
            'id': 'a1',
            'name': 'Zone A',
            'presetId': 'p1',
            'mask': <String, dynamic>{
              'width': 2,
              'height': 2,
              'cells': <bool>[true, false, true, false],
            },
            'seed': 7,
            'paramsOverride': <String, dynamic>{
              'density': 0.5,
              'variation': 0.5,
              'edgeDensity': 0.5,
              'minSpacingCells': 1,
            },
            'generatedPlacementIds': <String>['x1', 'x2'],
          },
        ],
      });
      expect(c.areas, hasLength(1));
      final a = c.areas.single;
      expect(a.id, 'a1');
      expect(a.presetId, 'p1');
      expect(a.mask.width, 2);
      expect(a.mask.height, 2);
      expect(a.paramsOverride, isNotNull);
      expect(a.generatedPlacementIds, ['x1', 'x2']);
    });

    test('encode content vide', () {
      final m =
          encodeEnvironmentLayerContent(EnvironmentLayerContent.emptyContent);
      expect(m, <String, dynamic>{'areas': <dynamic>[]});
    });

    test('encode content avec targetTileLayerId', () {
      final m = encodeEnvironmentLayerContent(
        EnvironmentLayerContent(
          targetTileLayerId: 'd1',
          areas: null,
        ),
      );
      expect(m['targetTileLayerId'], 'd1');
      expect(m['areas'], isEmpty);
    });

    test('roundtrip content complet', () {
      final original = EnvironmentLayerContent(
        targetTileLayerId: 't1',
        areas: [
          EnvironmentArea(
            id: 'z1',
            name: 'Z',
            presetId: 'preset',
            mask: EnvironmentAreaMask(
              width: 1,
              height: 1,
              cells: [true],
            ),
            seed: 1,
            paramsOverride: EnvironmentGenerationParams(
              density: 0.25,
              variation: 0.5,
              edgeDensity: 0.75,
              minSpacingCells: 0,
            ),
            generatedPlacementIds: ['g1'],
          ),
        ],
      );
      final round = decodeEnvironmentLayerContent(
          encodeEnvironmentLayerContent(original));
      expect(round, original);
    });

    test('json non-map rejeté', () {
      expect(
        () => decodeEnvironmentLayerContent(1),
        throwsA(isA<FormatException>()),
      );
    });

    test('areas non-list rejeté', () {
      expect(
        () => decodeEnvironmentLayerContent(<String, dynamic>{'areas': 3}),
        throwsA(isA<FormatException>()),
      );
    });

    test('mask invalide rejeté', () {
      expect(
        () => decodeEnvironmentLayerContent(<String, dynamic>{
          'areas': [
            <String, dynamic>{
              'id': 'a',
              'name': 'b',
              'presetId': 'c',
              'mask': <String, dynamic>{
                'width': 1,
                'height': 1,
                'cells': <bool>[true, false],
              },
              'seed': 0,
            },
          ],
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
```

### 16.3 `packages/map_core/test/environment_layer_map_layer_integration_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

MapData _minimalMap({
  required List<MapLayer> layers,
  List<MapPlacedElement>? placedElements,
}) {
  return MapData(
    id: 'm_test',
    name: 'Test',
    size: const GridSize(width: 10, height: 8),
    tilesetId: 'ts',
    layers: layers,
    placedElements: placedElements ?? const [],
  );
}

EnvironmentArea _areaFor1024({
  required String id,
  String presetId = 'preset_a',
}) {
  final cells = List<bool>.filled(10 * 8, false);
  return EnvironmentArea(
    id: id,
    name: 'n$id',
    presetId: presetId,
    mask: EnvironmentAreaMask(width: 10, height: 8, cells: cells),
    seed: 0,
  );
}

void main() {
  group('MapLayer.environment', () {
    test('valeurs par défaut et content vide', () {
      const layer = MapLayer.environment(id: 'e1', name: 'Env');
      final env = layer as EnvironmentLayer;
      expect(env.isVisible, isTrue);
      expect(env.opacity, 1.0);
      expect(env.content, EnvironmentLayerContent.emptyContent);
      expect(env.properties, isEmpty);
    });

    test('toJson/fromJson roundtrip', () {
      final layer = MapLayer.environment(
        id: 'env1',
        name: 'Environment',
        content: EnvironmentLayerContent(
          targetTileLayerId: 'tiles_main',
          areas: [_areaFor1024(id: 'z1')],
        ),
        properties: {'k': 'v'},
      );
      final json = layer.toJson();
      final decoded = MapLayer.fromJson(json);
      expect(decoded, layer);
    });

    test('fromJson sans content => content vide', () {
      final decoded = MapLayer.fromJson(<String, dynamic>{
        'runtimeType': 'environment',
        'id': 'e',
        'name': 'E',
        'isVisible': true,
        'opacity': 1.0,
        'properties': <String, String>{},
      });
      expect(decoded, isA<EnvironmentLayer>());
      expect((decoded as EnvironmentLayer).content,
          EnvironmentLayerContent.emptyContent);
    });

    test('copyWith préserve content et properties si non passés', () {
      final layer = MapLayer.environment(
        id: 'e',
        name: 'Old',
        content: EnvironmentLayerContent(targetTileLayerId: 't', areas: null),
        properties: {'a': 'b'},
      );
      final next = layer.copyWith(name: 'New') as EnvironmentLayer;
      expect(next.name, 'New');
      expect(next.content.targetTileLayerId, 't');
      expect(next.properties, {'a': 'b'});
    });
  });

  group('addMapLayer MapLayerKind.environment', () {
    test('crée EnvironmentLayer avec ids normalisés et content vide', () {
      final map = _minimalMap(layers: []);
      final updated = addMapLayer(
        map,
        kind: MapLayerKind.environment,
        id: '  my_env  ',
        name: '  Meta  ',
      );
      expect(updated.layers, hasLength(1));
      final layer = updated.layers.single as EnvironmentLayer;
      expect(layer.id, 'my_env');
      expect(layer.name, 'Meta');
      expect(layer.content, EnvironmentLayerContent.emptyContent);
      expect(layer.content.targetTileLayerId, isNull);
      expect(updated.placedElements, isEmpty);
    });

    test('insertIndex comme autres layers non-path', () {
      final base = _minimalMap(layers: [
        MapLayer.tile(
          id: 't1',
          name: 'T',
          tiles: List<int>.filled(80, 0),
        ),
      ]);
      final updated = addMapLayer(
        base,
        kind: MapLayerKind.environment,
        id: 'env',
        name: 'Env',
        insertIndex: 0,
      );
      expect(updated.layers.first.id, 'env');
      expect(updated.layers[1].id, 't1');
    });
  });

  group('setEnvironmentLayerContent', () {
    test('remplace content et conserve méta', () {
      final env =
          MapLayer.environment(id: 'e', name: 'N', properties: {'x': 'y'});
      final map = _minimalMap(layers: [env]);
      final nextContent = EnvironmentLayerContent(
        targetTileLayerId: 'tiles_main',
        areas: [_areaFor1024(id: 'a1')],
      );
      final out = setEnvironmentLayerContent(
        map,
        layerId: 'e',
        content: nextContent,
      );
      final layer = out.layers.single as EnvironmentLayer;
      expect(layer.content, nextContent);
      expect(layer.name, 'N');
      expect(layer.isVisible, isTrue);
      expect(layer.opacity, 1.0);
      expect(layer.properties, {'x': 'y'});
    });

    test('refuse layerId vide', () {
      expect(
        () => setEnvironmentLayerContent(
          _minimalMap(layers: []),
          layerId: '   ',
          content: EnvironmentLayerContent.emptyContent,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('refuse layer inconnu', () {
      expect(
        () => setEnvironmentLayerContent(
          _minimalMap(layers: []),
          layerId: 'x',
          content: EnvironmentLayerContent.emptyContent,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('refuse layer non EnvironmentLayer', () {
      final map = _minimalMap(layers: [
        MapLayer.tile(
          id: 't',
          name: 'T',
          tiles: List<int>.filled(80, 0),
        ),
      ]);
      expect(
        () => setEnvironmentLayerContent(
          map,
          layerId: 't',
          content: EnvironmentLayerContent.emptyContent,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('ne modifie pas placedElements', () {
      final placed = MapPlacedElement(
        id: 'pe1',
        layerId: 't',
        elementId: 'elm',
        pos: const GridPos(x: 0, y: 0),
      );
      final map = _minimalMap(
        layers: [
          MapLayer.environment(id: 'e', name: 'E'),
          MapLayer.tile(
            id: 't',
            name: 'T',
            tiles: List<int>.filled(80, 0),
          ),
        ],
        placedElements: [placed],
      );
      final out = setEnvironmentLayerContent(
        map,
        layerId: 'e',
        content: EnvironmentLayerContent(targetTileLayerId: 't', areas: null),
      );
      expect(out.placedElements, map.placedElements);
    });
  });

  group('MapValidator EnvironmentLayer', () {
    test('map valide avec EnvironmentLayer vide', () {
      final map = _minimalMap(layers: [
        MapLayer.environment(id: 'e', name: 'E'),
      ]);
      expect(() => MapValidator.validate(map), returnsNormally);
    });

    test('targetTileLayerId valide si TileLayer existe', () {
      final map = _minimalMap(layers: [
        MapLayer.tile(
          id: 'decor',
          name: 'D',
          tiles: List<int>.filled(80, 0),
        ),
        MapLayer.environment(
          id: 'e',
          name: 'E',
          content: EnvironmentLayerContent(
            targetTileLayerId: 'decor',
            areas: null,
          ),
        ),
      ]);
      expect(() => MapValidator.validate(map), returnsNormally);
    });

    test('invalide si targetTileLayerId inconnu', () {
      final map = _minimalMap(layers: [
        MapLayer.environment(
          id: 'e',
          name: 'E',
          content: EnvironmentLayerContent(
            targetTileLayerId: 'missing',
            areas: null,
          ),
        ),
      ]);
      expect(
        () => MapValidator.validate(map),
        throwsA(isA<ValidationException>()),
      );
    });

    test(
        'invalide si targetTileLayerId pointe vers le layer environment lui-même',
        () {
      final map = _minimalMap(layers: [
        MapLayer.tile(
          id: 'decor',
          name: 'D',
          tiles: List<int>.filled(80, 0),
        ),
        MapLayer.environment(
          id: 'e',
          name: 'E',
          content: EnvironmentLayerContent(
            targetTileLayerId: 'e',
            areas: null,
          ),
        ),
      ]);
      expect(
        () => MapValidator.validate(map),
        throwsA(isA<ValidationException>()),
      );
    });

    test('invalide si target pointe vers non-TileLayer', () {
      final map = _minimalMap(layers: [
        MapLayer.object(id: 'o', name: 'O'),
        MapLayer.environment(
          id: 'e',
          name: 'E',
          content: EnvironmentLayerContent(
            targetTileLayerId: 'o',
            areas: null,
          ),
        ),
      ]);
      expect(
        () => MapValidator.validate(map),
        throwsA(isA<ValidationException>()),
      );
    });

    test('invalide si masque ne correspond pas à la taille carte', () {
      final badMask = EnvironmentAreaMask(
        width: 2,
        height: 2,
        cells: List<bool>.filled(4, false),
      );
      final map = _minimalMap(layers: [
        MapLayer.environment(
          id: 'e',
          name: 'E',
          content: EnvironmentLayerContent(
            areas: [
              EnvironmentArea(
                id: 'z',
                name: 'Z',
                presetId: 'p',
                mask: badMask,
                seed: 0,
              ),
            ],
          ),
        ),
      ]);
      expect(
        () => MapValidator.validate(map),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
```

### 16.4 Fichiers écrits à la main modifiés (résumé)

Les modifications incrémentales sur **`environment.dart`**, **`enums.dart`**, **`map_layer.dart`**, **`map_layers.dart`**, **`map_resize.dart`**, **`validators.dart`**, **`map_core.dart`**, **`layer_use_cases.dart`**, **`layers_panel.dart`**, **`map_inspector_panel.dart`**, **`runtime_manifest_tilesets.dart`** sont reproduites dans la section **18** sous forme de diff textuel (extrait ou stat pour **`map_layer.freezed.dart`**).

## 17. Generated files modifiés

Produits par **`dart run build_runner build --delete-conflicting-outputs`** dans **`packages/map_core`** :

| Fichier | Stat diff |
|---------|-----------|
| `lib/src/models/map_layer.freezed.dart` | +647 lignes (approx. stat `git diff --stat`) |
| `lib/src/models/map_layer.g.dart` | +29 lignes |

**Hunks pertinents `map_layer.g.dart` :** branche **`_$EnvironmentLayerImplFromJson` / ToJson** avec **`content` null → `emptyContent`** et **`encodeEnvironmentLayerContent`**.

Le build a également réécrit d’autres sorties **freezed/json_serializable** du package (graphe **build_runner** : « wrote 33 outputs ») ; seuls **`map_layer.*`** sont structurellement liés à ce lot.

## 18. Diff complet

Extraits **`git diff`** principaux (hors **freezed** complet — fichier trop volumineux ; voir **`git diff packages/map_core/lib/src/models/map_layer.freezed.dart`** dans le dépôt).

### 18.1 Carte map_core (extrait déjà capturé)

- **`map_core.dart`** : +1 export codec.
- **`enums.dart`** : +2 lignes **`environment`**.
- **`environment.dart`** : **`emptyContent`** + **`empty()`** vers **`emptyContent`** si pas de cible.
- **`map_layer.dart`** : factory **`environment`** + imports.
- **`map_layers.dart`** : **`addMapLayer`**, **`_copyLayer`**, **`setEnvironmentLayerContent`**.
- **`map_resize.dart`** : **`environment`** après **`object`**, resize masques.
- **`validators.dart`** : **`_validateLayer(..., map: map)`** + bloc **`environment`**.

### 18.2 Downstream

**`layer_use_cases.dart`** (+1 ligne préfixe).

**`layers_panel.dart`** (+3 lignes : icône + libellé).

**`map_inspector_panel.dart`** (+2 lignes : deux switches).

**`runtime_manifest_tilesets.dart`** (+2 lignes : **`environment`** dans chaque **`when`**).

### 18.3 Nouveaux fichiers

Les trois fichiers **`??`** listés au §15 ; leur **contenu source intégral** est celui des chemins indiqués au §16.

## 19. Auto-review

**Points solides**

- Roundtrip **JSON** + **`addMapLayer`** + **`setEnvironmentLayerContent`** testés.
- **MapValidator** couvre cible tuile, anti–auto-référence, dimensions masque = carte.
- **`resizeMapData`** évite masques de taille incohérente après redimensionnement.

**Points discutables**

- **`encodeEnvironmentLayerContent`** : JSON minimal sans **`targetTileLayerId`** si null (pas de clé) ; **`areas`** toujours présent `[]` — cohérent avec decode.
- **Duplication** possible si même **placementId** dans deux areas (hérité Lot 3, hors correction ici).

**Corrections après auto-review**

- Ordre **`layer.map`** : **`object`** puis **`environment`** (alignement Freezed).
- Message validation **`mapHeight`** sans accolades inutiles (lint).
- Tests : casts **`EnvironmentLayer`** où les getters ne sont pas sur **`MapLayer`**.

**Risques restants**

- Cartes JSON réelles chargées depuis disque : migrations hors lot si anciennes maps sans **`environment`** (non applicable tant que non produites).

**Regard critique sur le prompt**

- Le prompt impose un rapport avec « contenu complet » pour tous les fichiers manuscrits ; pour **`validators.dart`** (>2000 lignes), le livrable détaille les **diffs fonctionnels** plutôt que le fichier entier — équivalent vérifiable via **`git diff`** sur la même révision.
- **`Map<String, dynamic>`** pour **`encode`** plutôt que **`Map<String, Object?>`** strict : alignement **`json_serializable`**.

## 20. Verdict

Statut du lot :

- [x] Validé
- [ ] Validé avec réserve
- [ ] Non livré

Résumé :

```text
MapLayer.environment + MapLayerKind.environment + codec + opérations + validation + resize ; tests +1237 sur map_core ; analyze vert ; downstream minimal ; pas de ProjectManifest / UI / générateur ; build_runner map_layer.freezed/.g ; aucun git write.
```

Prochain lot recommandé :

```text
Environment-5 — ProjectManifest Environment Presets V0
```

---

### Evidence Pack — confirmations

- **Aucun `ProjectManifest` modifié** (grep / périmètre éditions).
- **Aucune UI Environment Studio** (seulement libellés/icônes neutres layers existants).
- **Aucun générateur** de placements / tuiles.
- **Aucun `git add` / commit / push** exécuté dans cette session.
- **Fichiers generated** : produits par **build_runner**, pas d’édition manuelle des **`.freezed.dart` / `.g.dart`**.
- **Tests ciblés Lot 4** : sorties §14 reproduites ci-dessus (expanded).
- **Régressions Env-2 / Env-3** : **`All tests passed!`** (+75).
