# ShadowV2-11 — Project Building Shadow Preset Catalog JSON Codec V0

## 1. Résumé exécutif

ShadowV2-11 ajoute uniquement le codec JSON manuel de `ProjectBuildingShadowPresetCatalog`.

Le codec :

- encode toujours un objet catalogue `{ "presets": [...] }` ;
- encode un catalogue vide en `{ "presets": [] }` ;
- décode un catalogue seulement si `presets` est présent et est une liste ;
- ignore les unknown keys au niveau catalogue ;
- réutilise `encodeProjectBuildingShadowPreset` et `decodeProjectBuildingShadowPreset` pour chaque preset ;
- laisse `ProjectBuildingShadowPresetCatalog` rejeter les IDs dupliqués.

Aucune intégration manifest, élément, runtime, éditeur ou Selbrume n’a été ajoutée.

## 2. Objectif du lot

Objectif exécuté :

```text
Créer uniquement le codec JSON de ProjectBuildingShadowPresetCatalog,
manuel,
testé,
sans effet de bord,
sans intégration manifest.
```

Question centrale traitée :

```text
Comment sérialiser ProjectBuildingShadowPresetCatalog de façon stable,
sans encore intégrer le catalogue dans ProjectManifest ?
```

## 3. Rappel ShadowV2-10

ShadowV2-10 a créé le codec JSON manuel de `ProjectBuildingShadowPreset`.

ShadowV2-11 s’appuie dessus et ne reparsing pas les champs internes d’un preset :

- `encodeProjectBuildingShadowPreset(...)` ;
- `decodeProjectBuildingShadowPreset(...)`.

## 4. État initial du worktree

Commande :

```bash
git status --short --untracked-files=all
```

Sortie initiale :

```text
?? packages/map_core/test/shadow_v2/project_building_shadow_preset_catalog_json_codec_test.dart
```

Interprétation :

- le test V2-11 était déjà présent comme fichier non suivi au moment de l’audit initial de ce lot ;
- il est resté dans le périmètre autorisé ;
- il a servi de test rouge avant l’implémentation du codec.

## 5. Décision AGENTS / design gate

Commandes :

```bash
find .. -name AGENTS.md -print
rg -n "Do not invoke implementation skills|design has been presented|creative|structural|architectural|product-facing" AGENTS.md
```

Sorties :

```text
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
```

```text
765:Before structural changes, read the nearest:
848:1. Brainstorming (`superpowers:brainstorming`) before creative work.
1094:Do not invoke implementation skills, write code, scaffold a project, or take implementation action until a design has been presented and approved when the task is creative, structural, architectural, or product-facing.
1096:For creative work such as features, components, behavior changes, or UI:
```

Décision :

- ShadowV2-8 a validé le design JSON ;
- ShadowV2-10 a implémenté le codec preset ;
- ShadowV2-11 est une implémentation bornée du codec catalogue prévu ;
- aucun nouveau design gate bloquant n’a été identifié.

Fichiers audités :

```text
packages/map_core/lib/src/models/projected_building_shadow.dart
packages/map_core/lib/src/operations/project_building_shadow_preset_json_codec.dart
packages/map_core/lib/src/operations/project_shadow_catalog_json_codec.dart
packages/map_core/lib/src/operations/projected_shadow_value_object_json_codecs.dart
packages/map_core/lib/map_core.dart
packages/map_core/test/shadow/project_shadow_catalog_json_codec_test.dart
packages/map_core/test/shadow_v2/project_building_shadow_preset_catalog_json_codec_test.dart
```

Synthèse d’audit :

- les codecs ShadowV2 récents utilisent `ValidationException` pour les erreurs de forme JSON ;
- le catalogue V2 rejette déjà les IDs dupliqués via `ArgumentError` ;
- `map_core.dart` exporte déjà les codecs atomiques V2-9 et le codec preset V2-10 ;
- le codec Shadow V1 catalogue fournit un modèle de collection JSON, mais V2-11 applique la règle plus stricte du prompt : `presets` requis si l’objet catalogue est présent.

## 6. Fichiers créés / modifiés

### Créés

```text
packages/map_core/lib/src/operations/project_building_shadow_preset_catalog_json_codec.dart
packages/map_core/test/shadow_v2/project_building_shadow_preset_catalog_json_codec_test.dart
reports/shadows/v2/shadow_v2_11_project_building_shadow_preset_catalog_json_codec.md
```

### Modifiés

```text
packages/map_core/lib/map_core.dart
```

### Supprimés

```text
Aucun
```

### Generated files

```text
Aucun
```

### Fichiers Selbrume

```text
Aucun fichier Selbrume modifié
```

## 7. Codec créé

Fichier :

```text
packages/map_core/lib/src/operations/project_building_shadow_preset_catalog_json_codec.dart
```

Fonctions créées :

```dart
Map<String, dynamic> encodeProjectBuildingShadowPresetCatalog(
  ProjectBuildingShadowPresetCatalog catalog,
)

ProjectBuildingShadowPresetCatalog decodeProjectBuildingShadowPresetCatalog(
  Object? json,
)
```

## 8. JSON canonique

Catalogue vide :

```json
{
  "presets": []
}
```

Catalogue avec presets :

```json
{
  "presets": [
    {
      "id": "short-west-building-shadow",
      "name": "Short west building shadow",
      "direction": {
        "x": -0.55,
        "y": 0.35
      },
      "shape": {
        "lengthRatio": 0.28,
        "nearWidthRatio": 0.85,
        "farWidthRatio": 0.75
      },
      "appearance": {
        "opacity": 0.18,
        "colorHexRgb": "000000"
      },
      "timeOfDayMode": "fixed",
      "sortOrder": 0
    },
    {
      "id": "long-east-building-shadow",
      "name": "Long east building shadow",
      "direction": {
        "x": 0.65,
        "y": 0.35
      },
      "shape": {
        "lengthRatio": 0.42,
        "nearWidthRatio": 0.9,
        "farWidthRatio": 0.7
      },
      "appearance": {
        "opacity": 0.16,
        "colorHexRgb": "000000"
      },
      "timeOfDayMode": "followsSun",
      "categoryId": "buildings",
      "sortOrder": 10
    }
  ]
}
```

## 9. Champs requis / optionnels

Au niveau catalogue :

- `presets` est requis ;
- `presets` doit être une liste ;
- aucun default silencieux n’est appliqué par ce codec.

Chaque item de `presets` :

- doit être un objet JSON ;
- est décodé par `decodeProjectBuildingShadowPreset(...)`.

## 10. Stratégie empty catalog

Décision appliquée :

```text
ProjectBuildingShadowPresetCatalog()
-> { "presets": [] }
```

Le codec catalogue encode toujours l’objet catalogue. L’omission future du champ root `projectedBuildingShadowCatalog` reste la responsabilité du futur codec `ProjectManifest`.

## 11. Stratégie unknown keys

Décision appliquée :

- unknown keys au niveau catalogue : ignorées au decode ;
- unknown keys dans les presets : ignorées par le codec preset V2-10 ;
- unknown keys dans les value objects : ignorées par les codecs atomiques V2-9 ;
- encode ne réémet aucune unknown key.

## 12. Stratégie d’erreurs

Conventions appliquées :

- `ValidationException` pour forme JSON invalide, type invalide, champ requis manquant ;
- `ArgumentError` laissé au modèle `ProjectBuildingShadowPresetCatalog` pour les IDs dupliqués ;
- validations de preset/value objects déléguées aux codecs et modèles déjà existants.

Cas rejetés par les tests :

- `json null` ;
- `json non-map` ;
- `presets` absent ;
- `presets` null ;
- `presets` non-list ;
- item non-map ;
- item preset invalide ;
- direction invalide dans un preset ;
- IDs dupliqués.

## 13. Réutilisation du codec preset

Le codec catalogue réutilise directement :

```dart
encodeProjectBuildingShadowPreset(preset)
decodeProjectBuildingShadowPreset(item)
```

Il ne duplique pas la logique de parsing :

- `id` ;
- `name` ;
- `direction` ;
- `shape` ;
- `appearance` ;
- `timeOfDayMode` ;
- `categoryId` ;
- `sortOrder`.

## 14. Tests ajoutés

Fichier :

```text
packages/map_core/test/shadow_v2/project_building_shadow_preset_catalog_json_codec_test.dart
```

Couverture ajoutée :

- encode catalogue vide ;
- decode catalogue vide ;
- encode multi-presets ;
- decode multi-presets ;
- conservation de l’ordre ;
- lookup après decode ;
- round-trip catalogue -> JSON -> catalogue ;
- round-trip JSON -> catalogue -> JSON canonique ;
- unknown keys ignorées ;
- formes invalides rejetées ;
- items invalides rejetés ;
- IDs dupliqués rejetés via le modèle catalogue.

## 15. Résultats des tests

### Test ciblé

Commande :

```bash
cd packages/map_core && dart test test/shadow_v2/project_building_shadow_preset_catalog_json_codec_test.dart
```

Sortie complète :

```text
00:00 +0: loading test/shadow_v2/project_building_shadow_preset_catalog_json_codec_test.dart
00:00 +0: ProjectBuildingShadowPresetCatalog JSON codec encodes an empty catalog canonically
00:00 +1: ProjectBuildingShadowPresetCatalog JSON codec encodes an empty catalog canonically
00:00 +1: ProjectBuildingShadowPresetCatalog JSON codec decodes an empty catalog
00:00 +2: ProjectBuildingShadowPresetCatalog JSON codec decodes an empty catalog
00:00 +2: ProjectBuildingShadowPresetCatalog JSON codec encodes multiple presets preserving order
00:00 +3: ProjectBuildingShadowPresetCatalog JSON codec encodes multiple presets preserving order
00:00 +3: ProjectBuildingShadowPresetCatalog JSON codec decodes multiple presets preserving order and lookup behavior
00:00 +4: ProjectBuildingShadowPresetCatalog JSON codec decodes multiple presets preserving order and lookup behavior
00:00 +4: ProjectBuildingShadowPresetCatalog JSON codec round-trips catalog instances through canonical JSON
00:00 +5: ProjectBuildingShadowPresetCatalog JSON codec round-trips catalog instances through canonical JSON
00:00 +5: ProjectBuildingShadowPresetCatalog JSON codec round-trips JSON without re-emitting unknown keys
00:00 +6: ProjectBuildingShadowPresetCatalog JSON codec round-trips JSON without re-emitting unknown keys
00:00 +6: ProjectBuildingShadowPresetCatalog JSON codec rejects invalid catalog shape
00:00 +7: ProjectBuildingShadowPresetCatalog JSON codec rejects invalid catalog shape
00:00 +7: ProjectBuildingShadowPresetCatalog JSON codec rejects invalid preset items
00:00 +8: ProjectBuildingShadowPresetCatalog JSON codec rejects invalid preset items
00:00 +8: ProjectBuildingShadowPresetCatalog JSON codec rejects duplicate preset ids through the catalog model
00:00 +9: ProjectBuildingShadowPresetCatalog JSON codec rejects duplicate preset ids through the catalog model
00:00 +9: All tests passed!
```

### Régression ShadowV2

Commande :

```bash
cd packages/map_core && dart test test/shadow_v2
```

Ligne finale exacte :

```text
00:00 +104: All tests passed!
```

### Régression Shadow V1

Commande :

```bash
cd packages/map_core && dart test test/shadow
```

Ligne finale exacte :

```text
00:01 +284: All tests passed!
```

## 16. Résultat analyze

Commande :

```bash
cd packages/map_core && dart analyze lib/src/operations/project_building_shadow_preset_catalog_json_codec.dart test/shadow_v2/project_building_shadow_preset_catalog_json_codec_test.dart
```

Sortie :

```text
Analyzing project_building_shadow_preset_catalog_json_codec.dart, project_building_shadow_preset_catalog_json_codec_test.dart...
No issues found!
```

## 17. Export public

Export ajouté dans `packages/map_core/lib/map_core.dart` :

```dart
export 'src/operations/project_building_shadow_preset_catalog_json_codec.dart';
```

Raison :

- les codecs atomiques V2-9 et le codec preset V2-10 sont déjà exportés publiquement ;
- le codec catalogue suit cette même convention.

## 18. Ce qui n’a volontairement pas été créé

Non créés :

- codec `ProjectElementProjectedBuildingShadowConfig` ;
- intégration `ProjectManifest` ;
- intégration `ProjectElementEntry` ;
- intégration `MapPlacedElement` ;
- migrations JSON ;
- defaults artistiques ;
- runtime resolver ;
- éditeur ;
- renderer ;
- screenshots/baselines ;
- generated files.

## 19. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie :

```text
 packages/map_core/lib/map_core.dart | 1 +
 1 file changed, 1 insertion(+)
```

Note : les nouveaux fichiers non suivis sont listés dans `git status final`.

## 20. git diff --name-status

Commande :

```bash
git diff --name-status
```

Sortie :

```text
M	packages/map_core/lib/map_core.dart
```

## 21. git diff --check

Commande :

```bash
git diff --check
```

Sortie :

```text

```

## 22. git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie finale :

```text
 M packages/map_core/lib/map_core.dart
?? packages/map_core/lib/src/operations/project_building_shadow_preset_catalog_json_codec.dart
?? packages/map_core/test/shadow_v2/project_building_shadow_preset_catalog_json_codec_test.dart
?? reports/shadows/v2/shadow_v2_11_project_building_shadow_preset_catalog_json_codec.md
```

## 23. Risques / réserves

- Le codec catalogue exige `presets` dès que l’objet catalogue est présent. C’est volontaire : l’absence du root entier sera gérée plus tard par le codec `ProjectManifest`.
- Les unknown keys sont ignorées au decode et non réémises au encode. Cela protège le contrat canonique actuel mais ne conserve pas des extensions futures inconnues.
- Les IDs dupliqués lèvent `ArgumentError` via le modèle, pas `ValidationException`. Cette séparation garde les erreurs de forme JSON dans les codecs et les invariants métier dans les modèles.

## 24. Auto-critique

Le lot reste bien borné : le codec catalogue ne fait que transformer `{ "presets": [...] }` vers `ProjectBuildingShadowPresetCatalog`.

Le principal point de vigilance est le choix strict `missing presets -> erreur`. Il est cohérent avec le prompt, mais devra être explicitement compensé dans le futur codec manifest par :

```text
root projectedBuildingShadowCatalog absent -> ProjectBuildingShadowPresetCatalog()
```

## 25. Regard critique sur le prompt

Le prompt est précis et utile : il distingue correctement le codec catalogue de l’intégration manifest. Cette distinction évite d’introduire trop tôt la logique d’omission du root vide, qui doit rester au niveau `ProjectManifest`.

La contrainte “pas de codec config élément” est importante : le lot V2-11 ne crée aucun chemin JSON permettant encore d’attacher une ombre projetée à un élément.

## 26. Prochain lot recommandé

Prochain lot recommandé :

```text
ShadowV2-12 — Project Element Projected Building Shadow Config JSON Codec V0
```

Pourquoi maintenant :

- les codecs atomiques existent ;
- le codec preset existe ;
- le codec catalogue existe ;
- il reste à encoder/décoder la config élément pure V2-7 avant toute intégration `ProjectElementEntry` / `ProjectManifest`.

## Code complet des fichiers créés/modifiés

### packages/map_core/lib/src/operations/project_building_shadow_preset_catalog_json_codec.dart

```dart
import '../exceptions/map_exceptions.dart';
import '../models/projected_building_shadow.dart';
import 'project_building_shadow_preset_json_codec.dart';

Map<String, Object?> _stringKeyMapFrom(Object mapLike) {
  final map = mapLike as Map<dynamic, dynamic>;
  return Map<String, Object?>.from(
    map.map(
      (dynamic key, dynamic value) => MapEntry(
        key is String ? key : key.toString(),
        value as Object?,
      ),
    ),
  );
}

Map<String, Object?> _requiredObject(Object? json, String label) {
  if (json is! Map) {
    throw ValidationException(
      '$label JSON must be an Object, got ${json.runtimeType}',
    );
  }
  return _stringKeyMapFrom(json);
}

Object? _valueForRequiredKey(
  Map<String, Object?> json,
  String key,
  String fieldKey,
) {
  if (!json.containsKey(key)) {
    throw ValidationException('$fieldKey is required');
  }
  return json[key];
}

/// Encodes an ordered ShadowV2 projected building shadow preset catalog.
Map<String, dynamic> encodeProjectBuildingShadowPresetCatalog(
  ProjectBuildingShadowPresetCatalog catalog,
) {
  return <String, dynamic>{
    'presets': <Object?>[
      for (final preset in catalog.presets)
        encodeProjectBuildingShadowPreset(preset),
    ],
  };
}

/// Decodes an ordered ShadowV2 projected building shadow preset catalog.
///
/// The catalog object must explicitly contain `presets`. Unknown catalog-level
/// keys are ignored; individual preset objects are delegated to the preset
/// codec so the preset contract remains centralized.
ProjectBuildingShadowPresetCatalog decodeProjectBuildingShadowPresetCatalog(
  Object? json,
) {
  final map = _requiredObject(json, 'ProjectBuildingShadowPresetCatalog');
  final rawPresets = _valueForRequiredKey(
    map,
    'presets',
    'ProjectBuildingShadowPresetCatalog.presets',
  );
  if (rawPresets is! List) {
    throw const ValidationException(
      'ProjectBuildingShadowPresetCatalog.presets must be a List',
    );
  }

  final presets = <ProjectBuildingShadowPreset>[];
  for (var index = 0; index < rawPresets.length; index += 1) {
    final item = rawPresets[index];
    if (item is! Map) {
      throw ValidationException(
        'ProjectBuildingShadowPresetCatalog.presets[$index] must be an Object',
      );
    }
    presets.add(decodeProjectBuildingShadowPreset(item));
  }

  return ProjectBuildingShadowPresetCatalog(presets: presets);
}
```

### packages/map_core/test/shadow_v2/project_building_shadow_preset_catalog_json_codec_test.dart

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectBuildingShadowPresetCatalog JSON codec', () {
    test('encodes an empty catalog canonically', () {
      expect(
        encodeProjectBuildingShadowPresetCatalog(
          ProjectBuildingShadowPresetCatalog(),
        ),
        <String, Object?>{'presets': <Object?>[]},
      );
    });

    test('decodes an empty catalog', () {
      final catalog = decodeProjectBuildingShadowPresetCatalog(
        <String, Object?>{'presets': <Object?>[]},
      );

      expect(catalog.isEmpty, isTrue);
      expect(catalog.length, 0);
      expect(catalog.presetById('missing'), isNull);
    });

    test('encodes multiple presets preserving order', () {
      final catalog = ProjectBuildingShadowPresetCatalog(
        presets: <ProjectBuildingShadowPreset>[
          _shortWestPreset(),
          _longEastPreset(),
        ],
      );

      expect(encodeProjectBuildingShadowPresetCatalog(catalog), _catalogJson());
    });

    test('decodes multiple presets preserving order and lookup behavior', () {
      final catalog = decodeProjectBuildingShadowPresetCatalog(_catalogJson());

      expect(
        catalog.presets.map((preset) => preset.id),
        <String>[
          'short-west-building-shadow',
          'long-east-building-shadow',
        ],
      );
      expect(
        catalog.presetById('short-west-building-shadow')?.timeOfDayMode,
        ProjectedShadowTimeOfDayMode.fixed,
      );
      expect(
        catalog.presetById('long-east-building-shadow')?.timeOfDayMode,
        ProjectedShadowTimeOfDayMode.followsSun,
      );
      expect(catalog.containsPresetId('missing'), isFalse);
    });

    test('round-trips catalog instances through canonical JSON', () {
      final catalog = ProjectBuildingShadowPresetCatalog(
        presets: <ProjectBuildingShadowPreset>[
          _shortWestPreset(),
          _longEastPreset(),
        ],
      );

      expect(
        decodeProjectBuildingShadowPresetCatalog(
          encodeProjectBuildingShadowPresetCatalog(catalog),
        ),
        catalog,
      );
    });

    test('round-trips JSON without re-emitting unknown keys', () {
      final json = _catalogJson()
        ..['futureCatalogField'] = true
        ..['presets'] = <Object?>[
          _shortWestPresetJson()
            ..['futurePresetField'] = 'ignored'
            ..['direction'] = <String, Object?>{
              'x': -0.55,
              'y': 0.35,
              'futureDirectionField': 'ignored',
            },
          _longEastPresetJson()
            ..['appearance'] = <String, Object?>{
              'opacity': 0.16,
              'colorHexRgb': 'abcdef',
              'futureAppearanceField': 'ignored',
            },
        ];

      expect(
        encodeProjectBuildingShadowPresetCatalog(
          decodeProjectBuildingShadowPresetCatalog(json),
        ),
        _catalogJson(secondColorHexRgb: 'ABCDEF'),
      );
    });

    test('rejects invalid catalog shape', () {
      expect(
        () => decodeProjectBuildingShadowPresetCatalog(null),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectBuildingShadowPresetCatalog('catalog'),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectBuildingShadowPresetCatalog(<String, Object?>{}),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectBuildingShadowPresetCatalog(<String, Object?>{
          'presets': null,
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectBuildingShadowPresetCatalog(<String, Object?>{
          'presets': 'short-west',
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects invalid preset items', () {
      expect(
        () => decodeProjectBuildingShadowPresetCatalog(<String, Object?>{
          'presets': <Object?>['preset'],
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectBuildingShadowPresetCatalog(<String, Object?>{
          'presets': <Object?>[
            _shortWestPresetJson()..remove('id'),
          ],
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectBuildingShadowPresetCatalog(<String, Object?>{
          'presets': <Object?>[
            _shortWestPresetJson()
              ..['direction'] = <String, Object?>{'x': 0, 'y': 0},
          ],
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects duplicate preset ids through the catalog model', () {
      expect(
        () => decodeProjectBuildingShadowPresetCatalog(<String, Object?>{
          'presets': <Object?>[
            _shortWestPresetJson(),
            _shortWestPresetJson()..['name'] = 'Short west copy',
          ],
        }),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}

ProjectBuildingShadowPreset _shortWestPreset() {
  return ProjectBuildingShadowPreset(
    id: 'short-west-building-shadow',
    name: 'Short west building shadow',
    direction: ProjectedShadowDirection(x: -0.55, y: 0.35),
    shape: ProjectedShadowShapeTuning(
      lengthRatio: 0.28,
      nearWidthRatio: 0.85,
      farWidthRatio: 0.75,
    ),
    appearance: ProjectedShadowAppearance(
      opacity: 0.18,
      colorHexRgb: '000000',
    ),
    timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
  );
}

ProjectBuildingShadowPreset _longEastPreset() {
  return ProjectBuildingShadowPreset(
    id: 'long-east-building-shadow',
    name: 'Long east building shadow',
    direction: ProjectedShadowDirection(x: 0.65, y: 0.35),
    shape: ProjectedShadowShapeTuning(
      lengthRatio: 0.42,
      nearWidthRatio: 0.9,
      farWidthRatio: 0.7,
    ),
    appearance: ProjectedShadowAppearance(
      opacity: 0.16,
      colorHexRgb: '000000',
    ),
    timeOfDayMode: ProjectedShadowTimeOfDayMode.followsSun,
    categoryId: 'buildings',
    sortOrder: 10,
  );
}

Map<String, Object?> _catalogJson({
  String secondColorHexRgb = '000000',
}) {
  return <String, Object?>{
    'presets': <Object?>[
      _shortWestPresetJson(),
      _longEastPresetJson(colorHexRgb: secondColorHexRgb),
    ],
  };
}

Map<String, Object?> _shortWestPresetJson() {
  return <String, Object?>{
    'id': 'short-west-building-shadow',
    'name': 'Short west building shadow',
    'direction': <String, Object?>{'x': -0.55, 'y': 0.35},
    'shape': <String, Object?>{
      'lengthRatio': 0.28,
      'nearWidthRatio': 0.85,
      'farWidthRatio': 0.75,
    },
    'appearance': <String, Object?>{
      'opacity': 0.18,
      'colorHexRgb': '000000',
    },
    'timeOfDayMode': 'fixed',
    'sortOrder': 0,
  };
}

Map<String, Object?> _longEastPresetJson({
  String colorHexRgb = '000000',
}) {
  return <String, Object?>{
    'id': 'long-east-building-shadow',
    'name': 'Long east building shadow',
    'direction': <String, Object?>{'x': 0.65, 'y': 0.35},
    'shape': <String, Object?>{
      'lengthRatio': 0.42,
      'nearWidthRatio': 0.9,
      'farWidthRatio': 0.7,
    },
    'appearance': <String, Object?>{
      'opacity': 0.16,
      'colorHexRgb': colorHexRgb,
    },
    'timeOfDayMode': 'followsSun',
    'categoryId': 'buildings',
    'sortOrder': 10,
  };
}
```

### packages/map_core/lib/map_core.dart

```dart
library map_core;

export 'src/models/enums.dart';
export 'src/models/geometry.dart';
export 'src/models/tileset.dart';
export 'src/models/tileset_transparent_color.dart';
export 'src/models/map_data.dart';
export 'src/models/element_collision_profile.dart';
export 'src/models/environment.dart';
export 'src/models/map_entity_payloads.dart';
export 'src/models/map_entity_editor_visual.dart';
export 'src/models/map_gameplay_zone_payloads.dart';
export 'src/models/map_layer.dart';
export 'src/models/map_metadata.dart';
export 'src/models/path_center_pattern.dart';
export 'src/models/project_path_pattern_preset.dart';
export 'src/models/project_manifest.dart';
export 'src/models/save_data.dart';
export 'src/models/game_state.dart';
export 'src/models/pokemon_move.dart';
export 'src/models/pokemon_move_accuracy.dart';
export 'src/models/pokemon_move_effect.dart';
export 'src/models/script_asset.dart';
export 'src/models/script_conditions.dart';
export 'src/models/map_event_definition.dart';
export 'src/models/project_trainer.dart';
export 'src/models/scenario_asset.dart';
export 'src/models/visual_frame_json.dart';
export 'src/models/shadow.dart';
export 'src/models/shadow_catalog.dart';
export 'src/models/projected_building_shadow.dart';
export 'src/models/surface.dart';
export 'src/models/surface_catalog.dart';
export 'src/operations/map_resize.dart';
export 'src/operations/map_paint.dart';
export 'src/operations/map_collision.dart';
export 'src/operations/map_path.dart';
export 'src/operations/map_terrain.dart';
export 'src/operations/map_terrain_autotile.dart';
export 'src/operations/terrain_preset_subtile_for_map_cell.dart';
export 'src/operations/terrain_preset_variant_pick.dart';
export 'src/operations/path_center_pattern_resolver.dart';
export 'src/operations/path_pattern_visual_resolution.dart';
export 'src/operations/project_path_preset_center_pattern_adapter.dart';
export 'src/operations/project_element_shadow_config_json_codec.dart';
export 'src/operations/project_building_shadow_preset_catalog_json_codec.dart';
export 'src/operations/project_building_shadow_preset_json_codec.dart';
export 'src/operations/project_manifest_shadow_catalog_operations.dart';
export 'src/operations/project_path_pattern_preset_json_codec.dart';
export 'src/operations/project_shadow_catalog_json_codec.dart';
export 'src/operations/project_shadow_profile_json_codec.dart';
export 'src/operations/projected_shadow_value_object_json_codecs.dart';
export 'src/operations/static_shadow_family_json_codec.dart';
export 'src/operations/static_shadow_footprint_config_json_codec.dart';
export 'src/operations/project_json_migrations.dart';
export 'src/operations/default_shadow_profiles.dart';
export 'src/operations/tile_visual_frame_timeline.dart';
export 'src/operations/tile_visual_frame_vertical_atlas.dart';
export 'src/operations/path_variant_vertical_atlas_mapping.dart';
export 'src/operations/path_preset_vertical_atlas_builder.dart';
export 'src/operations/terrain_path_variant_vertical_atlas_layout.dart';
export 'src/operations/standard_path_preset_vertical_atlas_builder.dart';
export 'src/operations/standard_water_path_preset_vertical_atlas_builder.dart';
export 'src/operations/standard_lava_path_preset_vertical_atlas_builder.dart';
export 'src/operations/standard_ice_path_preset_vertical_atlas_builder.dart';
export 'src/operations/standard_tall_grass_path_preset_vertical_atlas_builder.dart';
export 'src/operations/standard_surface_preset_builder.dart';
export 'src/operations/surface_catalog_diagnostics.dart';
export 'src/operations/surface_catalog_authoring_diagnostics.dart';
export 'src/operations/surface_catalog_diagnostics_summary.dart';
export 'src/operations/surface_catalog_diagnostics_presentation.dart';
export 'src/operations/static_shadow_geometry.dart';
export 'src/operations/static_shadow_family_projection.dart';
export 'src/operations/static_shadow_projection_geometry.dart';
export 'src/operations/static_shadow_contact_ledge_geometry.dart';
export 'src/operations/element_auto_shadow_policy.dart';
export 'src/operations/surface_atlas_json_codec.dart';
export 'src/operations/surface_animation_frame_json_codec.dart';
export 'src/operations/surface_animation_timeline_json_codec.dart';
export 'src/operations/project_surface_animation_json_codec.dart';
export 'src/operations/surface_variant_animation_ref_json_codec.dart';
export 'src/operations/surface_variant_animation_ref_set_json_codec.dart';
export 'src/operations/project_surface_preset_json_codec.dart';
export 'src/operations/project_surface_catalog_json_codec.dart';
export 'src/operations/project_manifest_surface_catalog_operations.dart';
export 'src/operations/project_manifest_path_pattern_preset_operations.dart';
export 'src/operations/surface_studio_read_model.dart';
export 'src/operations/tall_grass_authoring_view.dart';
export 'src/operations/path_animation_rules.dart';
export 'src/operations/element_collision_mask_codec.dart';
export 'src/operations/element_collision_profile_normalizer.dart';
export 'src/collision/pixel_rect.dart';
export 'src/collision/player_collision_conventions_v1.dart';
export 'src/operations/map_layers.dart';
export 'src/operations/environment_layer_content_json_codec.dart';
export 'src/operations/environment_preset_json_codec.dart';
export 'src/operations/project_manifest_environment_preset_operations.dart';
export 'src/operations/environment_preset_diagnostics.dart';
export 'src/operations/environment_layer_usage_diagnostics.dart';
export 'src/operations/environment_authoring_diagnostics.dart';
export 'src/operations/shadow_authoring_diagnostics.dart';
export 'src/operations/shadow_config_resolver.dart';
export 'src/operations/surface_layer_placements.dart';
export 'src/operations/surface_to_gameplay_zone_generation_assessment.dart';
export 'src/operations/surface_to_gameplay_zone_generation_plan.dart';
export 'src/operations/surface_variant_role_resolver.dart';
export 'src/operations/map_connections.dart';
export 'src/operations/map_entities.dart';
export 'src/operations/map_events.dart';
export 'src/operations/map_placed_elements.dart';
export 'src/operations/map_placed_element_animation.dart';
export 'src/operations/map_placed_element_shadow_override_json_codec.dart';
export 'src/operations/map_entity_collision_footprint.dart';
export 'src/operations/map_triggers.dart';
export 'src/operations/map_warps.dart';
export 'src/operations/map_gameplay_zones.dart';
export 'src/operations/map_map_metadata.dart';
export 'src/operations/game_state_persistence.dart';
export 'src/operations/tileset_library_tree.dart';
export 'src/operations/dialogue_library_tree.dart';
export 'src/operations/project_dialogue_refs.dart';
export 'src/validation/validators.dart';
export 'src/validation/dialogue_validation.dart';
export 'src/validation/entity_editor_visual_validation.dart';
export 'src/exceptions/map_exceptions.dart';
```

## Diff de map_core.dart

```diff
diff --git a/packages/map_core/lib/map_core.dart b/packages/map_core/lib/map_core.dart
index dd4f2cc7..4511f4b9 100644
--- a/packages/map_core/lib/map_core.dart
+++ b/packages/map_core/lib/map_core.dart
@@ -43,6 +43,7 @@ export 'src/operations/path_center_pattern_resolver.dart';
 export 'src/operations/path_pattern_visual_resolution.dart';
 export 'src/operations/project_path_preset_center_pattern_adapter.dart';
 export 'src/operations/project_element_shadow_config_json_codec.dart';
+export 'src/operations/project_building_shadow_preset_catalog_json_codec.dart';
 export 'src/operations/project_building_shadow_preset_json_codec.dart';
 export 'src/operations/project_manifest_shadow_catalog_operations.dart';
 export 'src/operations/project_path_pattern_preset_json_codec.dart';
```
