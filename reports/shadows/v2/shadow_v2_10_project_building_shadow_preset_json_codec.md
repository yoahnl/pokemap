# ShadowV2-10 — Project Building Shadow Preset JSON Codec V0

## 1. Résumé exécutif

ShadowV2-10 ajoute uniquement le codec JSON manuel de `ProjectBuildingShadowPreset`.

Le codec :

- réutilise les codecs atomiques ShadowV2-9 ;
- encode le JSON canonique du preset ;
- décode `categoryId` absent/null comme `null` ;
- décode `sortOrder` absent comme `0` ;
- ignore les unknown keys ;
- ne crée aucun codec catalogue ;
- ne crée aucun codec config élément ;
- ne modifie aucun manifest, runtime, éditeur, fichier Selbrume, screenshot ou baseline.

## 2. Objectif du lot

Objectif : sérialiser `ProjectBuildingShadowPreset` de façon stable avant le futur codec de catalogue, sans brancher la V2 à `ProjectManifest`, `ProjectElementEntry`, `MapPlacedElement`, runtime ou éditeur.

Règle conservée :

```text
Les grandes ombres projetées doivent être asset-driven, authorées, previewées et validées.
Jamais réintroduites par genericProjection automatique.
```

## 3. Rappel ShadowV2-9

ShadowV2-9 a créé les codecs atomiques :

- `encodeProjectedShadowDirection` / `decodeProjectedShadowDirection`
- `encodeProjectedShadowAnchor` / `decodeProjectedShadowAnchor`
- `encodeProjectedShadowOffset` / `decodeProjectedShadowOffset`
- `encodeProjectedShadowShapeTuning` / `decodeProjectedShadowShapeTuning`
- `encodeProjectedShadowAppearance` / `decodeProjectedShadowAppearance`
- `encodeProjectedShadowTimeOfDayMode` / `decodeProjectedShadowTimeOfDayMode`

ShadowV2-10 réutilise ces fonctions pour `direction`, `shape`, `appearance` et `timeOfDayMode`.

## 4. État initial du worktree

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
```

Le worktree initial était propre.

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

Interprétation :

- ShadowV2-8 a validé le design JSON.
- ShadowV2-9 a implémenté les codecs atomiques.
- ShadowV2-10 implémente seulement le codec `ProjectBuildingShadowPreset` prévu.
- Le design gate est respecté.

## 6. Fichiers créés / modifiés

Créés :

- `packages/map_core/lib/src/operations/project_building_shadow_preset_json_codec.dart`
- `packages/map_core/test/shadow_v2/project_building_shadow_preset_json_codec_test.dart`
- `reports/shadows/v2/shadow_v2_10_project_building_shadow_preset_json_codec.md`

Modifiés :

- `packages/map_core/lib/map_core.dart`

Supprimés :

- Aucun

Generated files :

- Aucun

Fichiers Selbrume :

- Aucun

## 7. Codec créé

Fonctions créées :

```dart
Map<String, dynamic> encodeProjectBuildingShadowPreset(
  ProjectBuildingShadowPreset preset,
)

ProjectBuildingShadowPreset decodeProjectBuildingShadowPreset(
  Object? json,
)
```

Le codec créé est limité à `ProjectBuildingShadowPreset`.

## 8. JSON canonique

Sans `categoryId` :

```json
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
}
```

Avec `categoryId` :

```json
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
  "categoryId": "buildings",
  "sortOrder": 10
}
```

## 9. Champs requis / optionnels

Champs requis au decode :

- `id`
- `name`
- `direction`
- `shape`
- `appearance`
- `timeOfDayMode`

Champs optionnels au decode :

- `categoryId`
- `sortOrder`

Encode :

- émet toujours `id`, `name`, `direction`, `shape`, `appearance`, `timeOfDayMode`, `sortOrder` ;
- émet `categoryId` uniquement si non-null.

## 10. Stratégie categoryId / sortOrder

`categoryId` :

- absent -> `null`
- `null` -> `null`
- non-string non-null -> `ValidationException`
- blank string -> rejeté par le modèle `ProjectBuildingShadowPreset` via `ArgumentError`
- encode omet le champ si `null`

`sortOrder` :

- absent -> `0`
- présent -> doit être un `int`
- non-int -> `ValidationException`
- encode émet toujours `sortOrder`

## 11. Stratégie unknown keys

Le decode ignore les unknown keys au niveau preset.

Les unknown keys imbriquées dans `direction`, `shape` et `appearance` sont ignorées par les codecs atomiques ShadowV2-9.

L’encode ne réémet pas les unknown keys.

## 12. Stratégie d’erreurs

Audit conventions JSON :

```bash
rg -n "throw FormatException|throw ArgumentError|throw ValidationException|decode.*Json|encode.*Json|is! Map|as Map<String, dynamic>" packages/map_core/lib/src/operations/*json_codec*.dart packages/map_core/lib/src/operations/projected_shadow_value_object_json_codecs.dart packages/map_core/test
```

Constat :

- Les codecs Shadow/Surface récents utilisent `ValidationException` pour JSON invalide, champ manquant et type invalide.
- Certains codecs plus anciens Environment utilisent `FormatException`.
- Les modèles purs peuvent encore jeter leurs propres exceptions de validation, notamment `ArgumentError` pour `ProjectBuildingShadowPreset.id` et `ProjectBuildingShadowPreset.name` blank.

Décision appliquée :

- `ValidationException` pour forme JSON invalide, champ requis absent, type invalide, enum inconnue via codec atomique.
- `ArgumentError` conservé quand le constructeur `ProjectBuildingShadowPreset` rejette `id` / `name` blank.
- Validations atomiques déléguées aux codecs V2-9 et aux value objects.

## 13. Réutilisation des codecs atomiques

Le codec preset réutilise :

- `encodeProjectedShadowDirection`
- `decodeProjectedShadowDirection`
- `encodeProjectedShadowShapeTuning`
- `decodeProjectedShadowShapeTuning`
- `encodeProjectedShadowAppearance`
- `decodeProjectedShadowAppearance`
- `encodeProjectedShadowTimeOfDayMode`
- `decodeProjectedShadowTimeOfDayMode`

Il ne parse pas manuellement `direction.x`, `shape.lengthRatio`, `appearance.opacity` ou `timeOfDayMode`.

## 14. Tests ajoutés

Test ajouté :

- `packages/map_core/test/shadow_v2/project_building_shadow_preset_json_codec_test.dart`

Couverture :

- encode canonique sans `categoryId`
- encode avec `categoryId`
- decode canonique
- `categoryId` absent -> `null`
- `categoryId: null` -> `null`
- `sortOrder` absent -> `0`
- round-trip preset
- round-trip JSON sans unknown keys
- champs requis manquants
- types invalides
- valeurs invalides déléguées au modèle et aux codecs atomiques

Phase TDD rouge :

```bash
cd packages/map_core && dart test test/shadow_v2/project_building_shadow_preset_json_codec_test.dart
```

Résultat initial attendu :

```text
Failed to load "test/shadow_v2/project_building_shadow_preset_json_codec_test.dart":
Error: Method not found: 'encodeProjectBuildingShadowPreset'.
Error: Method not found: 'decodeProjectBuildingShadowPreset'.
00:00 +0 -1: Some tests failed.
```

## 15. Résultats des tests

Test ciblé :

```bash
cd packages/map_core && dart test -r expanded test/shadow_v2/project_building_shadow_preset_json_codec_test.dart
```

Sortie complète :

```text
00:00 +0: loading test/shadow_v2/project_building_shadow_preset_json_codec_test.dart
00:00 +0: ProjectBuildingShadowPreset JSON codec encodes canonical preset JSON without categoryId
00:00 +1: ProjectBuildingShadowPreset JSON codec encodes categoryId when non-null and always emits sortOrder
00:00 +2: ProjectBuildingShadowPreset JSON codec decodes canonical preset JSON with defaults for omitted optionals
00:00 +3: ProjectBuildingShadowPreset JSON codec decodes categoryId null as null
00:00 +4: ProjectBuildingShadowPreset JSON codec round-trips preset instances through canonical JSON
00:00 +5: ProjectBuildingShadowPreset JSON codec round-trips JSON without re-emitting unknown keys
00:00 +6: ProjectBuildingShadowPreset JSON codec rejects null and non-map preset JSON
00:00 +7: ProjectBuildingShadowPreset JSON codec rejects missing required fields
00:00 +8: ProjectBuildingShadowPreset JSON codec rejects invalid field types
00:00 +9: ProjectBuildingShadowPreset JSON codec rejects invalid values delegated to model and atomic codecs
00:00 +10: All tests passed!
```

Régression ShadowV2 :

```bash
cd packages/map_core && dart test test/shadow_v2
```

Ligne finale exacte :

```text
00:00 +95: All tests passed!
```

Régression Shadow V1 :

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
cd packages/map_core && dart analyze lib/src/operations/project_building_shadow_preset_json_codec.dart test/shadow_v2/project_building_shadow_preset_json_codec_test.dart
```

Sortie :

```text
Analyzing project_building_shadow_preset_json_codec.dart, project_building_shadow_preset_json_codec_test.dart...
No issues found!
```

## 17. Export public

Export ajouté : oui.

Raison : `packages/map_core/lib/map_core.dart` exporte déjà les codecs manuels existants, dont les codecs Shadow V1 et les codecs atomiques ShadowV2-9.

Diff :

```diff
diff --git a/packages/map_core/lib/map_core.dart b/packages/map_core/lib/map_core.dart
index 681099a3..dd4f2cc7 100644
--- a/packages/map_core/lib/map_core.dart
+++ b/packages/map_core/lib/map_core.dart
@@ -43,6 +43,7 @@ export 'src/operations/path_center_pattern_resolver.dart';
 export 'src/operations/path_pattern_visual_resolution.dart';
 export 'src/operations/project_path_preset_center_pattern_adapter.dart';
 export 'src/operations/project_element_shadow_config_json_codec.dart';
+export 'src/operations/project_building_shadow_preset_json_codec.dart';
 export 'src/operations/project_manifest_shadow_catalog_operations.dart';
 export 'src/operations/project_path_pattern_preset_json_codec.dart';
 export 'src/operations/project_shadow_catalog_json_codec.dart';
```

## 18. Ce qui n’a volontairement pas été créé

Non créé :

- `ProjectBuildingShadowPresetCatalog` codec
- `ProjectElementProjectedBuildingShadowConfig` codec
- intégration `ProjectManifest`
- intégration `ProjectElementEntry`
- intégration `MapPlacedElement`
- migration JSON
- resolver runtime
- UI éditeur
- screenshot/baseline
- generated files

Vérification anti-catalogue/manifest :

```bash
rg -n "ProjectBuildingShadowPresetCatalog|ProjectElementProjectedBuildingShadowConfig|ProjectManifest|ProjectElementEntry|MapPlacedElement|migrateProjectManifestJson" packages/map_core/lib/src/operations/project_building_shadow_preset_json_codec.dart packages/map_core/test/shadow_v2/project_building_shadow_preset_json_codec_test.dart
```

Sortie :

```text
```

Exit code : `1`, donc aucun match.

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

Note : les nouveaux fichiers non trackés sont listés dans `git status final` et dans l’inventaire des fichiers ; `git diff --stat` ne les inclut pas tant qu’ils ne sont pas indexés.

## 20. git diff --name-status

Commande :

```bash
git diff --name-status
```

Sortie :

```text
M	packages/map_core/lib/map_core.dart
```

Note : les nouveaux fichiers non trackés sont listés dans `git status final` et dans l’inventaire des fichiers ; `git diff --name-status` ne les inclut pas tant qu’ils ne sont pas indexés.

## 21. git diff --check

Commande :

```bash
git diff --check
```

Sortie :

```text
```

Exit code : `0`.

## 22. git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie finale :

```text
 M packages/map_core/lib/map_core.dart
?? packages/map_core/lib/src/operations/project_building_shadow_preset_json_codec.dart
?? packages/map_core/test/shadow_v2/project_building_shadow_preset_json_codec_test.dart
?? reports/shadows/v2/shadow_v2_10_project_building_shadow_preset_json_codec.md
```

## 23. Risques / réserves

- `id` et `name` blank sont rejetés par le modèle pur avec `ArgumentError`, pas `ValidationException`. C’est cohérent avec le modèle existant, mais les futurs codecs composite devront accepter cette convention ou l’envelopper explicitement.
- Le codec ignore les unknown keys. C’est cohérent avec V2-9, mais le futur codec catalogue devra décider sa propre stratégie pour unknown keys au niveau catalogue.
- Le codec est exporté publiquement pour suivre les conventions actuelles ; un futur changement de politique d’exports devra être explicite.

## 24. Auto-critique

Le lot reste dans le périmètre demandé : un seul codec preset, aucune intégration manifest, aucun codec catalogue/config élément. Les tests couvrent les cas demandés, y compris `categoryId`, `sortOrder`, unknown keys et invalid values.

Le test utilise une fixture inline plutôt qu’un fichier golden JSON. C’est volontairement proportionné à un codec de preset isolé ; les fixtures fichier seront plus utiles pour les futurs tests de manifest/catalogue.

## 25. Regard critique sur le prompt

Le prompt est bien borné et empêche l’effet tunnel vers le catalogue/manifest. La seule nuance est la stratégie d’exception : il mentionne une recommandation possible autour de `FormatException`, mais les conventions locales Shadow/Surface récentes pointent vers `ValidationException`, avec `ArgumentError` conservé côté modèle pur.

## 26. Prochain lot recommandé

Prochain lot recommandé :

```text
ShadowV2-11 — Project Building Shadow Preset Catalog JSON Codec V0
```

Justification : le codec atomique et le codec preset sont maintenant disponibles. Le prochain incrément naturel est le codec de `ProjectBuildingShadowPresetCatalog`, sans encore intégrer le manifest.

## Code complet des fichiers créés/modifiés

### `packages/map_core/lib/src/operations/project_building_shadow_preset_json_codec.dart`

```dart
import '../exceptions/map_exceptions.dart';
import '../models/projected_building_shadow.dart';
import 'projected_shadow_value_object_json_codecs.dart';

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

String _requiredString(
  Map<String, Object?> json,
  String key,
  String fieldKey,
) {
  final value = _valueForRequiredKey(json, key, fieldKey);
  if (value is! String) {
    throw ValidationException('$fieldKey must be a non-null String');
  }
  return value;
}

String? _optionalNullableString(
  Map<String, Object?> json,
  String key,
  String fieldKey,
) {
  if (!json.containsKey(key)) {
    return null;
  }
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is! String) {
    throw ValidationException('$fieldKey must be a String or null');
  }
  return value;
}

int _optionalInt(
  Map<String, Object?> json,
  String key,
  String fieldKey,
  int defaultValue,
) {
  if (!json.containsKey(key)) {
    return defaultValue;
  }
  final value = json[key];
  if (value is! int) {
    throw ValidationException('$fieldKey must be an int');
  }
  return value;
}

/// Encodes a parametric projected building shadow preset.
Map<String, dynamic> encodeProjectBuildingShadowPreset(
  ProjectBuildingShadowPreset preset,
) {
  return <String, dynamic>{
    'id': preset.id,
    'name': preset.name,
    'direction': encodeProjectedShadowDirection(preset.direction),
    'shape': encodeProjectedShadowShapeTuning(preset.shape),
    'appearance': encodeProjectedShadowAppearance(preset.appearance),
    'timeOfDayMode': encodeProjectedShadowTimeOfDayMode(
      preset.timeOfDayMode,
    ),
    if (preset.categoryId != null) 'categoryId': preset.categoryId,
    'sortOrder': preset.sortOrder,
  };
}

/// Decodes a parametric projected building shadow preset.
///
/// Unknown keys are ignored. Nested atomic objects are decoded by their own
/// ShadowV2 value-object codecs.
ProjectBuildingShadowPreset decodeProjectBuildingShadowPreset(Object? json) {
  final map = _requiredObject(json, 'ProjectBuildingShadowPreset');
  return ProjectBuildingShadowPreset(
    id: _requiredString(map, 'id', 'ProjectBuildingShadowPreset.id'),
    name: _requiredString(map, 'name', 'ProjectBuildingShadowPreset.name'),
    direction: decodeProjectedShadowDirection(
      _valueForRequiredKey(
        map,
        'direction',
        'ProjectBuildingShadowPreset.direction',
      ),
    ),
    shape: decodeProjectedShadowShapeTuning(
      _valueForRequiredKey(map, 'shape', 'ProjectBuildingShadowPreset.shape'),
    ),
    appearance: decodeProjectedShadowAppearance(
      _valueForRequiredKey(
        map,
        'appearance',
        'ProjectBuildingShadowPreset.appearance',
      ),
    ),
    timeOfDayMode: decodeProjectedShadowTimeOfDayMode(
      _valueForRequiredKey(
        map,
        'timeOfDayMode',
        'ProjectBuildingShadowPreset.timeOfDayMode',
      ),
    ),
    categoryId: _optionalNullableString(
      map,
      'categoryId',
      'ProjectBuildingShadowPreset.categoryId',
    ),
    sortOrder: _optionalInt(
      map,
      'sortOrder',
      'ProjectBuildingShadowPreset.sortOrder',
      0,
    ),
  );
}
```

### `packages/map_core/test/shadow_v2/project_building_shadow_preset_json_codec_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectBuildingShadowPreset JSON codec', () {
    test('encodes canonical preset JSON without categoryId', () {
      final preset = _preset(colorHexRgb: 'abcdef');

      expect(
        encodeProjectBuildingShadowPreset(preset),
        <String, Object?>{
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
            'colorHexRgb': 'ABCDEF',
          },
          'timeOfDayMode': 'fixed',
          'sortOrder': 0,
        },
      );
    });

    test('encodes categoryId when non-null and always emits sortOrder', () {
      final preset = _preset(categoryId: 'buildings', sortOrder: 10);

      expect(
        encodeProjectBuildingShadowPreset(preset),
        <String, Object?>{
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
          'categoryId': 'buildings',
          'sortOrder': 10,
        },
      );
    });

    test('decodes canonical preset JSON with defaults for omitted optionals',
        () {
      final preset = decodeProjectBuildingShadowPreset(
        _canonicalJson(includeSortOrder: false),
      );

      expect(preset.id, 'short-west-building-shadow');
      expect(preset.name, 'Short west building shadow');
      expect(preset.direction, ProjectedShadowDirection(x: -0.55, y: 0.35));
      expect(
        preset.shape,
        ProjectedShadowShapeTuning(
          lengthRatio: 0.28,
          nearWidthRatio: 0.85,
          farWidthRatio: 0.75,
        ),
      );
      expect(
        preset.appearance,
        ProjectedShadowAppearance(opacity: 0.18, colorHexRgb: '000000'),
      );
      expect(preset.timeOfDayMode, ProjectedShadowTimeOfDayMode.fixed);
      expect(preset.categoryId, isNull);
      expect(preset.sortOrder, 0);
    });

    test('decodes categoryId null as null', () {
      final json = _canonicalJson(categoryId: null)..['categoryId'] = null;

      final preset = decodeProjectBuildingShadowPreset(json);

      expect(preset.categoryId, isNull);
    });

    test('round-trips preset instances through canonical JSON', () {
      final preset = _preset(categoryId: 'buildings', sortOrder: 10);

      expect(
        decodeProjectBuildingShadowPreset(
          encodeProjectBuildingShadowPreset(preset),
        ),
        preset,
      );
    });

    test('round-trips JSON without re-emitting unknown keys', () {
      final json = _canonicalJson(
        categoryId: 'buildings',
        sortOrder: 10,
      )
        ..['futureField'] = 'ignored'
        ..['direction'] = <String, Object?>{
          'x': -0.55,
          'y': 0.35,
          'futureDirectionField': 'ignored',
        }
        ..['shape'] = <String, Object?>{
          'lengthRatio': 0.28,
          'nearWidthRatio': 0.85,
          'farWidthRatio': 0.75,
          'futureShapeField': 'ignored',
        }
        ..['appearance'] = <String, Object?>{
          'opacity': 0.18,
          'colorHexRgb': 'abcdef',
          'futureAppearanceField': 'ignored',
        };

      final encoded = encodeProjectBuildingShadowPreset(
        decodeProjectBuildingShadowPreset(json),
      );

      expect(
        encoded,
        _canonicalJson(
          categoryId: 'buildings',
          sortOrder: 10,
          colorHexRgb: 'ABCDEF',
        ),
      );
    });

    test('rejects null and non-map preset JSON', () {
      expect(
        () => decodeProjectBuildingShadowPreset(null),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectBuildingShadowPreset('preset'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects missing required fields', () {
      for (final field in <String>{
        'id',
        'name',
        'direction',
        'shape',
        'appearance',
        'timeOfDayMode',
      }) {
        final json = _canonicalJson()..remove(field);

        expect(
          () => decodeProjectBuildingShadowPreset(json),
          throwsA(isA<ValidationException>()),
          reason: 'missing $field should be rejected',
        );
      }
    });

    test('rejects invalid field types', () {
      expect(
        () => decodeProjectBuildingShadowPreset(
          _canonicalJson()..['id'] = 123,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectBuildingShadowPreset(
          _canonicalJson()..['name'] = 123,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectBuildingShadowPreset(
          _canonicalJson()..['direction'] = 'west',
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectBuildingShadowPreset(
          _canonicalJson()..['shape'] = 'wide',
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectBuildingShadowPreset(
          _canonicalJson()..['appearance'] = 'soft',
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectBuildingShadowPreset(
          _canonicalJson()..['timeOfDayMode'] = 0,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectBuildingShadowPreset(
          _canonicalJson()..['categoryId'] = 123,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectBuildingShadowPreset(
          _canonicalJson()..['sortOrder'] = 1.5,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects invalid values delegated to model and atomic codecs', () {
      expect(
        () => decodeProjectBuildingShadowPreset(
          _canonicalJson()..['id'] = '   ',
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => decodeProjectBuildingShadowPreset(
          _canonicalJson()..['name'] = '   ',
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => decodeProjectBuildingShadowPreset(
          _canonicalJson()..['direction'] = <String, Object?>{'x': 0, 'y': 0},
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectBuildingShadowPreset(
          _canonicalJson()
            ..['shape'] = <String, Object?>{
              'lengthRatio': -0.01,
              'nearWidthRatio': 0.85,
              'farWidthRatio': 0.75,
            },
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectBuildingShadowPreset(
          _canonicalJson()
            ..['appearance'] = <String, Object?>{
              'opacity': 1.01,
              'colorHexRgb': '000000',
            },
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectBuildingShadowPreset(
          _canonicalJson()..['timeOfDayMode'] = 'moonlight',
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}

ProjectBuildingShadowPreset _preset({
  String? categoryId,
  int sortOrder = 0,
  String colorHexRgb = '000000',
}) {
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
      colorHexRgb: colorHexRgb,
    ),
    timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
    categoryId: categoryId,
    sortOrder: sortOrder,
  );
}

Map<String, Object?> _canonicalJson({
  Object? categoryId = _absent,
  int sortOrder = 0,
  bool includeSortOrder = true,
  String colorHexRgb = '000000',
}) {
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
      'colorHexRgb': colorHexRgb,
    },
    'timeOfDayMode': 'fixed',
    if (categoryId != _absent) 'categoryId': categoryId,
    if (includeSortOrder) 'sortOrder': sortOrder,
  };
}

const Object _absent = Object();
```

### `packages/map_core/lib/map_core.dart`

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
