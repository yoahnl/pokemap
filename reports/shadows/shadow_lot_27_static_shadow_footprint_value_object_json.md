# Shadow-27 — Static Shadow Footprint Value Object / JSON V0

## 1. Résumé du lot

Shadow-27 ajoute dans `map_core` la première brique persistable du modèle footprint statique :

- `StaticShadowFootprintConfig` ;
- validation des ratios d'ancre et d'emprise ;
- branchement optionnel dans `ProjectElementShadowConfig` ;
- branchement optionnel custom-only dans `MapPlacedElementShadowOverride` ;
- codec JSON dédié ;
- wiring des codecs JSON existants.

Le lot ne change pas la géométrie runtime/editor. Il rend seulement le footprint représentable, validé, sérialisable et compatible avec les anciens JSON.

## 2. Design retenu

Le design validé a été appliqué avec une adaptation explicite : le constructeur de `StaticShadowFootprintConfig` est non-`const`, comme les autres modèles Shadow validés de `shadow.dart`, afin de lever `ValidationException` sur les entrées invalides.

Le modèle reste manuel, sans Freezed, sans build_runner et sans changement des modèles persistants Freezed existants.

## 3. Fichiers créés

- `packages/map_core/lib/src/operations/static_shadow_footprint_config_json_codec.dart`
- `packages/map_core/test/shadow/static_shadow_footprint_config_test.dart`
- `packages/map_core/test/shadow/static_shadow_footprint_config_json_codec_test.dart`
- `reports/shadows/shadow_lot_27_static_shadow_footprint_value_object_json.md`

## 4. Fichiers modifiés

- `packages/map_core/lib/src/models/shadow.dart`
- `packages/map_core/lib/src/operations/project_element_shadow_config_json_codec.dart`
- `packages/map_core/lib/src/operations/map_placed_element_shadow_override_json_codec.dart`
- `packages/map_core/lib/map_core.dart`
- `packages/map_core/test/shadow/project_element_shadow_config_json_codec_test.dart`
- `packages/map_core/test/shadow/map_placed_element_shadow_override_json_codec_test.dart`

## 5. Fichiers non modifiés explicitement

- `packages/map_editor/**`
- `packages/map_runtime/**`
- `packages/map_gameplay/**`
- `packages/map_battle/**`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/map_data.dart`
- fichiers `.g.dart`
- fichiers `.freezed.dart`

## 6. StaticShadowFootprintConfig ajouté

`StaticShadowFootprintConfig` porte :

- `anchorXRatio`
- `anchorYRatio`
- `footprintWidthRatio`
- `footprintHeightRatio`

Il expose aussi :

- `isEmpty`
- `isNotEmpty`

L'égalité et le `hashCode` incluent les quatre champs.

## 7. Validation des ratios

Règles appliquées :

- `anchorXRatio` et `anchorYRatio` : `null` ou valeur finite entre `0` et `1` inclus.
- `footprintWidthRatio` et `footprintHeightRatio` : `null` ou valeur finite strictement supérieure à `0`.

Les valeurs `NaN`, `Infinity`, `-Infinity`, ancres hors bornes et footprints non positifs lèvent `ValidationException`.

## 8. Intégration ProjectElementShadowConfig

`ProjectElementShadowConfig` a un champ optionnel :

```dart
final StaticShadowFootprintConfig? footprint;
```

`footprint == null` conserve le comportement JSON et modèle existant.

`castsShadow: false` avec un `footprint` est autorisé, comme les autres champs optionnels existants : cela permet de conserver des valeurs authoring sans forcer la projection d'ombre.

## 9. Intégration MapPlacedElementShadowOverride

`MapPlacedElementShadowOverride` a un champ optionnel :

```dart
final StaticShadowFootprintConfig? footprint;
```

Règle appliquée :

- `mode == ShadowOverrideMode.custom` peut porter `footprint`.
- `inherit` avec `footprint != null` lève `ValidationException`.
- `disabled` avec `footprint != null` lève `ValidationException`.

Le reset/héritage au niveau `MapPlacedElement` reste représenté par `shadowOverride == null`.

## 10. Format JSON footprint

Format non vide :

```json
{
  "footprint": {
    "anchorXRatio": 0.5,
    "anchorYRatio": 1.0,
    "footprintWidthRatio": 0.75,
    "footprintHeightRatio": 0.25
  }
}
```

Règles du codec dédié :

- `encodeStaticShadowFootprintConfig(null)` retourne `null`.
- `encodeStaticShadowFootprintConfig(StaticShadowFootprintConfig())` retourne `null`.
- `decodeStaticShadowFootprintConfig(null)` retourne `null`.
- `decodeStaticShadowFootprintConfig({})` retourne `null`.
- Les champs inconnus sont ignorés.
- Un root non-map lève `ValidationException`.
- Les ratios invalides lèvent `ValidationException`.
- Les champs explicitement `null` dans l'objet footprint sont traités comme absents.

## 11. Compatibilité anciens JSON

Les anciens JSON sans clé `footprint` continuent à décoder :

- `ProjectElementShadowConfig.footprint == null`
- `MapPlacedElementShadowOverride.footprint == null`

L'encodage omet `footprint` quand il est `null` ou vide.

## 12. Pourquoi ce lot ne touche pas au runtime/editor

Shadow-27 ne fait qu'ajouter la capacité de représenter et sérialiser le footprint côté `map_core`. Le runtime et l'éditeur continueront à utiliser leur géométrie actuelle tant qu'un lot ultérieur ne consomme pas ce champ.

## 13. Pourquoi ce lot ne crée pas encore la géométrie commune

La géométrie commune runtime/editor doit être un lot séparé pour éviter de mélanger :

- extension JSON ;
- résolution géométrique ;
- intégration runtime ;
- preview editor.

Shadow-27 garde donc le modèle prêt, sans changer le rendu.

## 14. Tests ajoutés

Ajoutés :

- `static_shadow_footprint_config_test.dart`
- `static_shadow_footprint_config_json_codec_test.dart`

Étendus :

- `project_element_shadow_config_json_codec_test.dart`
- `map_placed_element_shadow_override_json_codec_test.dart`

## 15. Commandes lancées

```bash
find .. -name AGENTS.md -print
git status --short --untracked-files=all
dart test test/shadow/static_shadow_footprint_config_test.dart test/shadow/static_shadow_footprint_config_json_codec_test.dart test/shadow/project_element_shadow_config_json_codec_test.dart test/shadow/map_placed_element_shadow_override_json_codec_test.dart
dart format lib/src/models/shadow.dart lib/src/operations/static_shadow_footprint_config_json_codec.dart lib/src/operations/project_element_shadow_config_json_codec.dart lib/src/operations/map_placed_element_shadow_override_json_codec.dart lib/map_core.dart test/shadow/static_shadow_footprint_config_test.dart test/shadow/static_shadow_footprint_config_json_codec_test.dart test/shadow/project_element_shadow_config_json_codec_test.dart test/shadow/map_placed_element_shadow_override_json_codec_test.dart
dart test test/shadow/static_shadow_footprint_config_test.dart --reporter expanded
dart test test/shadow/static_shadow_footprint_config_json_codec_test.dart --reporter expanded
dart test test/shadow/project_element_shadow_config_json_codec_test.dart --reporter expanded
dart test test/shadow/map_placed_element_shadow_override_json_codec_test.dart --reporter expanded
dart test test/shadow --reporter expanded
dart analyze lib test/shadow
dart test --reporter expanded
dart analyze
git diff --name-only | rg -n "packages/map_editor|packages/map_runtime|packages/map_gameplay|packages/map_battle"
git diff --name-only | rg -n "\.g\.dart|\.freezed\.dart"
git diff -U0 -- packages/map_core | rg -n "build_runner|part .*\.g\.dart|part .*\.freezed\.dart"
git diff -U0 -- packages/map_core | rg -n "Canvas|Flame|drawOval|drawImageRect|saveLayer|ImageFilter|runtimeBlur|WorldLightState|ShadowLightProfile|LightDirection|timeOfDay|zOrder|zIndex"
git diff --check
git diff --stat
git diff --name-status
git status --short --untracked-files=all
```

## 16. Résultats complets des tests ciblés

### RED initial

Commande :

```bash
cd packages/map_core && dart test test/shadow/static_shadow_footprint_config_test.dart test/shadow/static_shadow_footprint_config_json_codec_test.dart test/shadow/project_element_shadow_config_json_codec_test.dart test/shadow/map_placed_element_shadow_override_json_codec_test.dart
```

Résultat utile :

```text
Failed to load "test/shadow/static_shadow_footprint_config_test.dart":
test/shadow/static_shadow_footprint_config_test.dart:7:22: Error: Method not found: 'StaticShadowFootprintConfig'.

Failed to load "test/shadow/static_shadow_footprint_config_json_codec_test.dart":
test/shadow/static_shadow_footprint_config_json_codec_test.dart:7:14: Error: Method not found: 'encodeStaticShadowFootprintConfig'.
test/shadow/static_shadow_footprint_config_json_codec_test.dart:42:14: Error: Method not found: 'decodeStaticShadowFootprintConfig'.

Failed to load "test/shadow/project_element_shadow_config_json_codec_test.dart":
Error: No named parameter with the name 'footprint'.
Error: The getter 'footprint' isn't defined for the type 'ProjectElementShadowConfig'.

Failed to load "test/shadow/map_placed_element_shadow_override_json_codec_test.dart":
Error: No named parameter with the name 'footprint'.
Error: The getter 'footprint' isn't defined for the type 'MapPlacedElementShadowOverride'.

00:00 +0 -4: Some tests failed.
```

### static_shadow_footprint_config_test.dart

Commande :

```bash
cd packages/map_core && dart test test/shadow/static_shadow_footprint_config_test.dart --reporter expanded
```

Sortie complète utile :

```text
00:00 +0: loading test/shadow/static_shadow_footprint_config_test.dart
00:00 +0: StaticShadowFootprintConfig constructor all null is empty
00:00 +1: StaticShadowFootprintConfig accepts anchor ratios at bounds
00:00 +2: StaticShadowFootprintConfig rejects anchor ratios outside 0 to 1 or non-finite
00:00 +3: StaticShadowFootprintConfig accepts positive footprint ratios
00:00 +4: StaticShadowFootprintConfig rejects footprint ratios that are not positive finite values
00:00 +5: StaticShadowFootprintConfig equality and hashCode include all fields
00:00 +6: All tests passed!
```

### static_shadow_footprint_config_json_codec_test.dart

Commande :

```bash
cd packages/map_core && dart test test/shadow/static_shadow_footprint_config_json_codec_test.dart --reporter expanded
```

Sortie complète utile :

```text
00:00 +0: loading test/shadow/static_shadow_footprint_config_json_codec_test.dart
00:00 +0: StaticShadowFootprintConfig JSON codec encodes null and empty footprint as null
00:00 +1: StaticShadowFootprintConfig JSON codec encodes non-empty footprints with only non-null fields
00:00 +2: StaticShadowFootprintConfig JSON codec decodes null and empty map as null
00:00 +3: StaticShadowFootprintConfig JSON codec decodes full and partial objects
00:00 +4: StaticShadowFootprintConfig JSON codec ignores unknown keys
00:00 +5: StaticShadowFootprintConfig JSON codec rejects non-map and invalid ratio values
00:00 +6: All tests passed!
```

### project_element_shadow_config_json_codec_test.dart

Commande :

```bash
cd packages/map_core && dart test test/shadow/project_element_shadow_config_json_codec_test.dart --reporter expanded
```

Sortie complète utile :

```text
00:00 +0: loading test/shadow/project_element_shadow_config_json_codec_test.dart
00:00 +0: ProjectElementShadowConfig JSON codec encodes a complete config to canonical JSON
00:00 +1: ProjectElementShadowConfig JSON codec decodes a complete config
00:00 +2: ProjectElementShadowConfig JSON codec old JSON without footprint decodes footprint null
00:00 +3: ProjectElementShadowConfig JSON codec encodes null and empty footprint by omitting footprint key
00:00 +4: ProjectElementShadowConfig JSON codec equality includes footprint
00:00 +5: ProjectElementShadowConfig JSON codec castsShadow false can carry footprint
00:00 +6: ProjectElementShadowConfig JSON codec roundtrips encode to decode
00:00 +7: ProjectElementShadowConfig JSON codec roundtrips decode to canonical encode
00:00 +8: ProjectElementShadowConfig JSON codec decodes null as null
00:00 +9: ProjectElementShadowConfig JSON codec decodes empty and minimal objects with defaults
00:00 +10: ProjectElementShadowConfig JSON codec ignores unknown fields and does not encode them
00:00 +11: ProjectElementShadowConfig JSON codec rejects invalid root and field types
00:00 +12: ProjectElementShadowConfig JSON codec rejects invalid decoded values
00:00 +13: All tests passed!
```

### map_placed_element_shadow_override_json_codec_test.dart

Commande :

```bash
cd packages/map_core && dart test test/shadow/map_placed_element_shadow_override_json_codec_test.dart --reporter expanded
```

Sortie complète utile :

```text
00:00 +0: loading test/shadow/map_placed_element_shadow_override_json_codec_test.dart
00:00 +0: MapPlacedElementShadowOverride JSON codec encodes inherit, disabled, and custom canonically
00:00 +1: MapPlacedElementShadowOverride JSON codec decodes inherit, disabled, and custom
00:00 +2: MapPlacedElementShadowOverride JSON codec old JSON without footprint decodes footprint null
00:00 +3: MapPlacedElementShadowOverride JSON codec encodes null and empty footprint by omitting footprint key
00:00 +4: MapPlacedElementShadowOverride JSON codec equality includes footprint
00:00 +5: MapPlacedElementShadowOverride JSON codec rejects inherit and disabled overrides with footprint
00:00 +6: MapPlacedElementShadowOverride JSON codec roundtrips encode/decode and canonicalizes unknown fields
00:00 +7: MapPlacedElementShadowOverride JSON codec decodes null and empty objects as inherit/null contract
00:00 +8: MapPlacedElementShadowOverride JSON codec rejects invalid root, mode, and field types
00:00 +9: MapPlacedElementShadowOverride JSON codec rejects invalid decoded values
00:00 +10: All tests passed!
```

## 17. Ligne finale exacte des tests globaux

Commande :

```bash
cd packages/map_core && dart test test/shadow --reporter expanded
```

Résultat final exact :

```text
00:00 +185: All tests passed!
```

Commande :

```bash
cd packages/map_core && dart test --reporter expanded
```

Résultat final exact :

```text
00:03 +1541: All tests passed!
```

Commande :

```bash
cd packages/map_core && dart analyze lib test/shadow
```

Résultat :

```text
Analyzing lib, shadow...
No issues found!
```

Commande :

```bash
cd packages/map_core && dart analyze
```

Résultat :

```text
Analyzing map_core...
No issues found!
```

## 18. Résultats des scans anti-dérive

Commande :

```bash
find .. -name AGENTS.md -print
```

Résultat :

```text
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
```

Commande :

```bash
git diff --name-only | rg -n "packages/map_editor|packages/map_runtime|packages/map_gameplay|packages/map_battle"
```

Résultat : aucune sortie.

Commande :

```bash
git diff --name-only | rg -n "\.g\.dart|\.freezed\.dart"
```

Résultat : aucune sortie.

Commande :

```bash
git diff -U0 -- packages/map_core | rg -n "build_runner|part .*\.g\.dart|part .*\.freezed\.dart"
```

Résultat : aucune sortie.

Commande :

```bash
git diff -U0 -- packages/map_core | rg -n "Canvas|Flame|drawOval|drawImageRect|saveLayer|ImageFilter|runtimeBlur|WorldLightState|ShadowLightProfile|LightDirection|timeOfDay|zOrder|zIndex"
```

Résultat : aucune sortie.

Commande :

```bash
git diff --check
```

Résultat : aucune sortie.

## 19. git status initial

Commande :

```bash
git status --short --untracked-files=all
```

Résultat initial : aucune sortie.

## 20. git status final

Commande :

```bash
git status --short --untracked-files=all
```

Résultat final vérifié après création de ce rapport :

```text
 M packages/map_core/lib/map_core.dart
 M packages/map_core/lib/src/models/shadow.dart
 M packages/map_core/lib/src/operations/map_placed_element_shadow_override_json_codec.dart
 M packages/map_core/lib/src/operations/project_element_shadow_config_json_codec.dart
 M packages/map_core/test/shadow/map_placed_element_shadow_override_json_codec_test.dart
 M packages/map_core/test/shadow/project_element_shadow_config_json_codec_test.dart
?? packages/map_core/lib/src/operations/static_shadow_footprint_config_json_codec.dart
?? packages/map_core/test/shadow/static_shadow_footprint_config_json_codec_test.dart
?? packages/map_core/test/shadow/static_shadow_footprint_config_test.dart
?? reports/shadows/shadow_lot_27_static_shadow_footprint_value_object_json.md
```

## 21. git diff --stat

Commande :

```bash
git diff --stat
```

Résultat :

```text
 packages/map_core/lib/map_core.dart                |   1 +
 packages/map_core/lib/src/models/shadow.dart       |  91 ++++++++++++++++-
 ..._placed_element_shadow_override_json_codec.dart |   4 +
 .../project_element_shadow_config_json_codec.dart  |   4 +
 ...ed_element_shadow_override_json_codec_test.dart | 107 ++++++++++++++++++++
 ...ject_element_shadow_config_json_codec_test.dart | 108 +++++++++++++++++++++
 6 files changed, 312 insertions(+), 3 deletions(-)
```

Les nouveaux fichiers non suivis sont listés dans `git status final` et reproduits dans les sections 26 et 27.

## 22. Non-objectifs respectés

- Aucun `map_editor`.
- Aucun `map_runtime`.
- Aucun `map_gameplay`.
- Aucun `map_battle`.
- Aucun fichier généré.
- Aucun build_runner.
- Aucune géométrie runtime/editor.
- Aucune UI.
- Aucun Shadow Studio.
- Aucune lumière globale.
- Aucun blur, atlas, zOrder ou zIndex.
- Aucun commit.

## 23. Risques / réserves

- `StaticShadowFootprintConfig` n'est pas encore consommé par le runtime ni par la preview editor ; c'est volontaire.
- Le constructeur n'est pas `const` afin de conserver la validation par `ValidationException`.
- `git diff --stat` ne liste pas les fichiers non suivis tant qu'aucun `git add` n'est fait ; le contrat interdit `git add`, donc `git status` et les diffs `/dev/null` ci-dessous documentent les nouveaux fichiers.

## 24. Auto-review finale

- Ai-je ajouté StaticShadowFootprintConfig ? oui.
- Ai-je validé anchor ratios 0..1 ? oui.
- Ai-je validé footprint ratios > 0 ? oui.
- Ai-je branché footprint dans ProjectElementShadowConfig ? oui.
- Ai-je branché footprint dans MapPlacedElementShadowOverride ? oui.
- Ai-je interdit footprint sur override inherit/disabled ? oui.
- Ai-je gardé old JSON compatible ? oui.
- Ai-je évité build_runner ? oui.
- Ai-je évité runtime/editor ? oui.
- Ai-je évité une géométrie commune prématurée ? oui.
- Ai-je évité toute lumière globale ? oui.

## 25. Regard critique sur le prompt

Le prompt montre un exemple avec constructeur `const`. Dans ce codebase, les modèles Shadow validés utilisent des constructeurs non-`const` pour lever `ValidationException`. Conserver `const` aurait imposé des `assert` ou une validation incomplète, ce qui aurait contredit les tests demandés.

## 26. Contenu complet des fichiers créés/modifiés

### Nouveau fichier : packages/map_core/lib/src/operations/static_shadow_footprint_config_json_codec.dart

```dart
import '../exceptions/map_exceptions.dart';
import '../models/shadow.dart';

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

double? _optionalNullableDouble(
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
  if (value is! num) {
    throw ValidationException('$fieldKey must be a num');
  }
  return value.toDouble();
}

Map<String, Object?>? encodeStaticShadowFootprintConfig(
  StaticShadowFootprintConfig? footprint,
) {
  if (footprint == null || footprint.isEmpty) {
    return null;
  }
  return <String, Object?>{
    if (footprint.anchorXRatio != null) 'anchorXRatio': footprint.anchorXRatio,
    if (footprint.anchorYRatio != null) 'anchorYRatio': footprint.anchorYRatio,
    if (footprint.footprintWidthRatio != null)
      'footprintWidthRatio': footprint.footprintWidthRatio,
    if (footprint.footprintHeightRatio != null)
      'footprintHeightRatio': footprint.footprintHeightRatio,
  };
}

StaticShadowFootprintConfig? decodeStaticShadowFootprintConfig(Object? json) {
  if (json == null) {
    return null;
  }
  if (json is! Map) {
    throw ValidationException(
      'StaticShadowFootprintConfig JSON must be an Object or null, got ${json.runtimeType}',
    );
  }

  final map = _stringKeyMapFrom(json);
  final footprint = StaticShadowFootprintConfig(
    anchorXRatio: _optionalNullableDouble(
      map,
      'anchorXRatio',
      'StaticShadowFootprintConfig.anchorXRatio',
    ),
    anchorYRatio: _optionalNullableDouble(
      map,
      'anchorYRatio',
      'StaticShadowFootprintConfig.anchorYRatio',
    ),
    footprintWidthRatio: _optionalNullableDouble(
      map,
      'footprintWidthRatio',
      'StaticShadowFootprintConfig.footprintWidthRatio',
    ),
    footprintHeightRatio: _optionalNullableDouble(
      map,
      'footprintHeightRatio',
      'StaticShadowFootprintConfig.footprintHeightRatio',
    ),
  );

  return footprint.isEmpty ? null : footprint;
}
```

### Nouveau fichier : packages/map_core/test/shadow/static_shadow_footprint_config_test.dart

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('StaticShadowFootprintConfig', () {
    test('constructor all null is empty', () {
      final config = StaticShadowFootprintConfig();

      expect(config.anchorXRatio, isNull);
      expect(config.anchorYRatio, isNull);
      expect(config.footprintWidthRatio, isNull);
      expect(config.footprintHeightRatio, isNull);
      expect(config.isEmpty, isTrue);
      expect(config.isNotEmpty, isFalse);
    });

    test('accepts anchor ratios at bounds', () {
      final config = StaticShadowFootprintConfig(
        anchorXRatio: 0,
        anchorYRatio: 1,
      );

      expect(config.anchorXRatio, 0);
      expect(config.anchorYRatio, 1);
      expect(config.isEmpty, isFalse);
      expect(config.isNotEmpty, isTrue);
    });

    test('rejects anchor ratios outside 0 to 1 or non-finite', () {
      for (final value in <double>[
        -0.01,
        1.01,
        double.nan,
        double.infinity,
        double.negativeInfinity,
      ]) {
        expect(
          () => StaticShadowFootprintConfig(anchorXRatio: value),
          throwsA(isA<ValidationException>()),
        );
        expect(
          () => StaticShadowFootprintConfig(anchorYRatio: value),
          throwsA(isA<ValidationException>()),
        );
      }
    });

    test('accepts positive footprint ratios', () {
      final config = StaticShadowFootprintConfig(
        footprintWidthRatio: 0.75,
        footprintHeightRatio: 0.25,
      );

      expect(config.footprintWidthRatio, 0.75);
      expect(config.footprintHeightRatio, 0.25);
      expect(config.isEmpty, isFalse);
      expect(config.isNotEmpty, isTrue);
    });

    test('rejects footprint ratios that are not positive finite values', () {
      for (final value in <double>[
        0,
        -0.01,
        double.nan,
        double.infinity,
        double.negativeInfinity,
      ]) {
        expect(
          () => StaticShadowFootprintConfig(footprintWidthRatio: value),
          throwsA(isA<ValidationException>()),
        );
        expect(
          () => StaticShadowFootprintConfig(footprintHeightRatio: value),
          throwsA(isA<ValidationException>()),
        );
      }
    });

    test('equality and hashCode include all fields', () {
      final first = StaticShadowFootprintConfig(
        anchorXRatio: 0.5,
        anchorYRatio: 1,
        footprintWidthRatio: 0.75,
        footprintHeightRatio: 0.25,
      );
      final same = StaticShadowFootprintConfig(
        anchorXRatio: 0.5,
        anchorYRatio: 1,
        footprintWidthRatio: 0.75,
        footprintHeightRatio: 0.25,
      );
      final differentAnchor = StaticShadowFootprintConfig(
        anchorXRatio: 0.4,
        anchorYRatio: 1,
        footprintWidthRatio: 0.75,
        footprintHeightRatio: 0.25,
      );
      final differentFootprint = StaticShadowFootprintConfig(
        anchorXRatio: 0.5,
        anchorYRatio: 1,
        footprintWidthRatio: 0.8,
        footprintHeightRatio: 0.25,
      );

      expect(first, same);
      expect(first.hashCode, same.hashCode);
      expect(first, isNot(differentAnchor));
      expect(first, isNot(differentFootprint));
    });
  });
}
```

### Nouveau fichier : packages/map_core/test/shadow/static_shadow_footprint_config_json_codec_test.dart

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('StaticShadowFootprintConfig JSON codec', () {
    test('encodes null and empty footprint as null', () {
      expect(encodeStaticShadowFootprintConfig(null), isNull);
      expect(
        encodeStaticShadowFootprintConfig(
          StaticShadowFootprintConfig(),
        ),
        isNull,
      );
    });

    test('encodes non-empty footprints with only non-null fields', () {
      expect(
        encodeStaticShadowFootprintConfig(
          StaticShadowFootprintConfig(
            anchorXRatio: 0.5,
            anchorYRatio: 1,
            footprintWidthRatio: 0.75,
            footprintHeightRatio: 0.25,
          ),
        ),
        <String, Object?>{
          'anchorXRatio': 0.5,
          'anchorYRatio': 1.0,
          'footprintWidthRatio': 0.75,
          'footprintHeightRatio': 0.25,
        },
      );
      expect(
        encodeStaticShadowFootprintConfig(
          StaticShadowFootprintConfig(footprintWidthRatio: 0.5),
        ),
        <String, Object?>{'footprintWidthRatio': 0.5},
      );
    });

    test('decodes null and empty map as null', () {
      expect(decodeStaticShadowFootprintConfig(null), isNull);
      expect(decodeStaticShadowFootprintConfig(<String, Object?>{}), isNull);
    });

    test('decodes full and partial objects', () {
      expect(
        decodeStaticShadowFootprintConfig(<String, Object?>{
          'anchorXRatio': 0.5,
          'anchorYRatio': 1,
          'footprintWidthRatio': 0.75,
          'footprintHeightRatio': 0.25,
        }),
        StaticShadowFootprintConfig(
          anchorXRatio: 0.5,
          anchorYRatio: 1,
          footprintWidthRatio: 0.75,
          footprintHeightRatio: 0.25,
        ),
      );
      expect(
        decodeStaticShadowFootprintConfig(<String, Object?>{
          'footprintHeightRatio': 0.3,
        }),
        StaticShadowFootprintConfig(footprintHeightRatio: 0.3),
      );
    });

    test('ignores unknown keys', () {
      expect(
        decodeStaticShadowFootprintConfig(<String, Object?>{
          'anchorXRatio': 0.5,
          'unknown': true,
        }),
        StaticShadowFootprintConfig(anchorXRatio: 0.5),
      );
    });

    test('rejects non-map and invalid ratio values', () {
      expect(
        () => decodeStaticShadowFootprintConfig('footprint'),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeStaticShadowFootprintConfig(<String, Object?>{
          'anchorXRatio': '0.5',
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeStaticShadowFootprintConfig(<String, Object?>{
          'anchorYRatio': 2,
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeStaticShadowFootprintConfig(<String, Object?>{
          'footprintWidthRatio': 0,
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeStaticShadowFootprintConfig(<String, Object?>{
          'footprintHeightRatio': double.infinity,
        }),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
```

Pour les fichiers modifiés existants, les sections modifiées complètes sont dans le diff de la section 27.

## 27. Diffs complets ou équivalents /dev/null pour fichiers créés

### Diff tracked

```diff
diff --git a/packages/map_core/lib/map_core.dart b/packages/map_core/lib/map_core.dart
index 268dbfd8..c9471247 100644
--- a/packages/map_core/lib/map_core.dart
+++ b/packages/map_core/lib/map_core.dart
@@ -46,6 +46,7 @@ export 'src/operations/project_manifest_shadow_catalog_operations.dart';
 export 'src/operations/project_path_pattern_preset_json_codec.dart';
 export 'src/operations/project_shadow_catalog_json_codec.dart';
 export 'src/operations/project_shadow_profile_json_codec.dart';
+export 'src/operations/static_shadow_footprint_config_json_codec.dart';
 export 'src/operations/project_json_migrations.dart';
 export 'src/operations/default_shadow_profiles.dart';
 export 'src/operations/tile_visual_frame_timeline.dart';
diff --git a/packages/map_core/lib/src/models/shadow.dart b/packages/map_core/lib/src/models/shadow.dart
index 08d7c1eb..79d0409c 100644
--- a/packages/map_core/lib/src/models/shadow.dart
+++ b/packages/map_core/lib/src/models/shadow.dart
@@ -41,6 +41,57 @@ enum ShadowOverrideMode {
   custom,
 }
 
+@immutable
+final class StaticShadowFootprintConfig {
+  StaticShadowFootprintConfig({
+    this.anchorXRatio,
+    this.anchorYRatio,
+    this.footprintWidthRatio,
+    this.footprintHeightRatio,
+  }) {
+    _validateStaticShadowOptionalAnchorRatio(anchorXRatio, 'anchorXRatio');
+    _validateStaticShadowOptionalAnchorRatio(anchorYRatio, 'anchorYRatio');
+    _validateStaticShadowOptionalFootprintRatio(
+      footprintWidthRatio,
+      'footprintWidthRatio',
+    );
+    _validateStaticShadowOptionalFootprintRatio(
+      footprintHeightRatio,
+      'footprintHeightRatio',
+    );
+  }
+
+  final double? anchorXRatio;
+  final double? anchorYRatio;
+  final double? footprintWidthRatio;
+  final double? footprintHeightRatio;
+
+  bool get isEmpty =>
+      anchorXRatio == null &&
+      anchorYRatio == null &&
+      footprintWidthRatio == null &&
+      footprintHeightRatio == null;
+
+  bool get isNotEmpty => !isEmpty;
+
+  @override
+  bool operator ==(Object other) =>
+      identical(this, other) ||
+      other is StaticShadowFootprintConfig &&
+          other.anchorXRatio == anchorXRatio &&
+          other.anchorYRatio == anchorYRatio &&
+          other.footprintWidthRatio == footprintWidthRatio &&
+          other.footprintHeightRatio == footprintHeightRatio;
+
+  @override
+  int get hashCode => Object.hash(
+        anchorXRatio,
+        anchorYRatio,
+        footprintWidthRatio,
+        footprintHeightRatio,
+      );
+}
+
 /// Pure authoring profile for a simple V0 shadow.
 ///
 /// This model has no JSON API and no dependency on Flutter or Flame.
@@ -126,6 +177,7 @@ final class ProjectElementShadowConfig {
     this.scaleX,
     this.scaleY,
     this.opacity,
+    this.footprint,
   }) {
@@ -157,6 +209,7 @@ final class ProjectElementShadowConfig {
   final double? scaleX;
   final double? scaleY;
   final double? opacity;
+  final StaticShadowFootprintConfig? footprint;
@@ -168,7 +221,8 @@ final class ProjectElementShadowConfig {
           other.offsetY == offsetY &&
           other.scaleX == scaleX &&
           other.scaleY == scaleY &&
-          other.opacity == opacity;
+          other.opacity == opacity &&
+          other.footprint == footprint;
@@ -179,6 +233,7 @@ final class ProjectElementShadowConfig {
         scaleX,
         scaleY,
         opacity,
+        footprint,
       );
 }
@@ -196,6 +251,7 @@ final class MapPlacedElementShadowOverride {
     this.scaleX,
     this.scaleY,
     this.opacity,
+    this.footprint,
   }) {
@@ -229,6 +285,7 @@ final class MapPlacedElementShadowOverride {
   final double? scaleX;
   final double? scaleY;
   final double? opacity;
+  final StaticShadowFootprintConfig? footprint;
@@ -236,7 +293,8 @@ final class MapPlacedElementShadowOverride {
       offsetY != null ||
       scaleX != null ||
       scaleY != null ||
-      opacity != null;
+      opacity != null ||
+      footprint != null;
@@ -248,7 +306,8 @@ final class MapPlacedElementShadowOverride {
           other.offsetY == offsetY &&
           other.scaleX == scaleX &&
           other.scaleY == scaleY &&
-          other.opacity == opacity;
+          other.opacity == opacity &&
+          other.footprint == footprint;
@@ -259,9 +318,35 @@ final class MapPlacedElementShadowOverride {
         scaleX,
         scaleY,
         opacity,
+        footprint,
       );
 }
 
+void _validateStaticShadowOptionalAnchorRatio(double? value, String name) {
+  if (value == null) {
+    return;
+  }
+  if (!value.isFinite || value < 0 || value > 1) {
+    throw ValidationException(
+      'StaticShadowFootprintConfig.$name must be between 0 and 1',
+    );
+  }
+}
+
+void _validateStaticShadowOptionalFootprintRatio(double? value, String name) {
+  if (value == null) {
+    return;
+  }
+  if (!value.isFinite) {
+    throw ValidationException(
+      'StaticShadowFootprintConfig.$name must be finite',
+    );
+  }
+  if (value <= 0) {
+    throw ValidationException('StaticShadowFootprintConfig.$name must be > 0');
+  }
+}
+
 void _validateMapPlacedElementShadowProfileId(String value) {
diff --git a/packages/map_core/lib/src/operations/map_placed_element_shadow_override_json_codec.dart b/packages/map_core/lib/src/operations/map_placed_element_shadow_override_json_codec.dart
index 957b11e2..4b2a3776 100644
--- a/packages/map_core/lib/src/operations/map_placed_element_shadow_override_json_codec.dart
+++ b/packages/map_core/lib/src/operations/map_placed_element_shadow_override_json_codec.dart
@@ -2,6 +2,7 @@ import 'package:json_annotation/json_annotation.dart';
 
 import '../exceptions/map_exceptions.dart';
 import '../models/shadow.dart';
+import 'static_shadow_footprint_config_json_codec.dart';
@@ -76,6 +77,7 @@ ShadowOverrideMode _decodeShadowOverrideMode(Map<String, Object?> json) {
 Map<String, Object?> encodeMapPlacedElementShadowOverride(
   MapPlacedElementShadowOverride override,
 ) {
+  final footprintJson = encodeStaticShadowFootprintConfig(override.footprint);
@@ -85,6 +87,7 @@ Map<String, Object?> encodeMapPlacedElementShadowOverride(
     if (override.scaleX != null) 'scaleX': override.scaleX,
     if (override.scaleY != null) 'scaleY': override.scaleY,
     if (override.opacity != null) 'opacity': override.opacity,
+    if (footprintJson != null) 'footprint': footprintJson,
   };
 }
@@ -138,6 +141,7 @@ MapPlacedElementShadowOverride? decodeMapPlacedElementShadowOverride(
       'opacity',
       'MapPlacedElementShadowOverride.opacity',
     ),
+    footprint: decodeStaticShadowFootprintConfig(map['footprint']),
   );
 }
diff --git a/packages/map_core/lib/src/operations/project_element_shadow_config_json_codec.dart b/packages/map_core/lib/src/operations/project_element_shadow_config_json_codec.dart
index 4fc70f83..9160e4e5 100644
--- a/packages/map_core/lib/src/operations/project_element_shadow_config_json_codec.dart
+++ b/packages/map_core/lib/src/operations/project_element_shadow_config_json_codec.dart
@@ -2,6 +2,7 @@ import 'package:json_annotation/json_annotation.dart';
 
 import '../exceptions/map_exceptions.dart';
 import '../models/shadow.dart';
+import 'static_shadow_footprint_config_json_codec.dart';
@@ -66,6 +67,7 @@ double? _optionalNullableDouble(
 Map<String, Object?> encodeProjectElementShadowConfig(
   ProjectElementShadowConfig config,
 ) {
+  final footprintJson = encodeStaticShadowFootprintConfig(config.footprint);
@@ -75,6 +77,7 @@ Map<String, Object?> encodeProjectElementShadowConfig(
     if (config.scaleX != null) 'scaleX': config.scaleX,
     if (config.scaleY != null) 'scaleY': config.scaleY,
     if (config.opacity != null) 'opacity': config.opacity,
+    if (footprintJson != null) 'footprint': footprintJson,
   };
 }
@@ -130,6 +133,7 @@ ProjectElementShadowConfig? decodeProjectElementShadowConfig(Object? json) {
       'opacity',
       'ProjectElementShadowConfig.opacity',
     ),
+    footprint: decodeStaticShadowFootprintConfig(map['footprint']),
   );
 }
diff --git a/packages/map_core/test/shadow/map_placed_element_shadow_override_json_codec_test.dart b/packages/map_core/test/shadow/map_placed_element_shadow_override_json_codec_test.dart
index 9d6ae688..6a17d432 100644
--- a/packages/map_core/test/shadow/map_placed_element_shadow_override_json_codec_test.dart
+++ b/packages/map_core/test/shadow/map_placed_element_shadow_override_json_codec_test.dart
@@ -24,6 +24,12 @@ void main() {
           'scaleX': 0.8,
           'scaleY': 0.35,
           'opacity': 0.25,
+          'footprint': <String, Object?>{
+            'anchorXRatio': 0.5,
+            'anchorYRatio': 1.0,
+            'footprintWidthRatio': 0.75,
+            'footprintHeightRatio': 0.25,
+          },
         },
       );
     });
@@ -50,11 +56,79 @@ void main() {
           'scaleX': 0.8,
           'scaleY': 0.35,
           'opacity': 0.25,
+          'footprint': <String, Object?>{
+            'anchorXRatio': 0.5,
+            'anchorYRatio': 1,
+            'footprintWidthRatio': 0.75,
+            'footprintHeightRatio': 0.25,
+          },
         }),
         _customOverride(),
       );
     });
 
+    test('old JSON without footprint decodes footprint null', () {
+      final override = decodeMapPlacedElementShadowOverride(<String, Object?>{
+        'mode': 'custom',
+        'offsetX': 2,
+      });
+
+      expect(override!.footprint, isNull);
+    });
+
+    test('encodes null and empty footprint by omitting footprint key', () {
+      expect(
+        encodeMapPlacedElementShadowOverride(
+          MapPlacedElementShadowOverride(mode: ShadowOverrideMode.custom),
+        ),
+        <String, Object?>{'mode': 'custom'},
+      );
+      expect(
+        encodeMapPlacedElementShadowOverride(
+          MapPlacedElementShadowOverride(
+            mode: ShadowOverrideMode.custom,
+            footprint: StaticShadowFootprintConfig(),
+          ),
+        ),
+        <String, Object?>{'mode': 'custom'},
+      );
+    });
+
+    test('equality includes footprint', () {
+      final base = MapPlacedElementShadowOverride(
+        mode: ShadowOverrideMode.custom,
+        footprint: StaticShadowFootprintConfig(anchorXRatio: 0.5),
+      );
+      final same = MapPlacedElementShadowOverride(
+        mode: ShadowOverrideMode.custom,
+        footprint: StaticShadowFootprintConfig(anchorXRatio: 0.5),
+      );
+      final different = MapPlacedElementShadowOverride(
+        mode: ShadowOverrideMode.custom,
+        footprint: StaticShadowFootprintConfig(anchorXRatio: 0.4),
+      );
+
+      expect(base, same);
+      expect(base.hashCode, same.hashCode);
+      expect(base, isNot(different));
+    });
+
+    test('rejects inherit and disabled overrides with footprint', () {
+      expect(
+        () => MapPlacedElementShadowOverride(
+          footprint: StaticShadowFootprintConfig(anchorXRatio: 0.5),
+        ),
+        throwsA(isA<ValidationException>()),
+      );
+      expect(
+        () => MapPlacedElementShadowOverride(
+          mode: ShadowOverrideMode.disabled,
+          footprint: StaticShadowFootprintConfig(anchorXRatio: 0.5),
+        ),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
     test('roundtrips encode/decode and canonicalizes unknown fields', () {
       final custom = _customOverride();
       expect(
@@ -181,6 +255,33 @@ void main() {
         }),
         throwsA(isA<ValidationException>()),
       );
+      expect(
+        () => decodeMapPlacedElementShadowOverride(<String, Object?>{
+          'mode': 'inherit',
+          'footprint': <String, Object?>{
+            'anchorXRatio': 0.5,
+          },
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+      expect(
+        () => decodeMapPlacedElementShadowOverride(<String, Object?>{
+          'mode': 'disabled',
+          'footprint': <String, Object?>{
+            'anchorXRatio': 0.5,
+          },
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+      expect(
+        () => decodeMapPlacedElementShadowOverride(<String, Object?>{
+          'mode': 'custom',
+          'footprint': <String, Object?>{
+            'footprintHeightRatio': 0,
+          },
+        }),
+        throwsA(isA<ValidationException>()),
+      );
     });
   });
 }
@@ -194,5 +295,11 @@ MapPlacedElementShadowOverride _customOverride() {
     scaleX: 0.8,
     scaleY: 0.35,
     opacity: 0.25,
+    footprint: StaticShadowFootprintConfig(
+      anchorXRatio: 0.5,
+      anchorYRatio: 1,
+      footprintWidthRatio: 0.75,
+      footprintHeightRatio: 0.25,
+    ),
   );
 }
diff --git a/packages/map_core/test/shadow/project_element_shadow_config_json_codec_test.dart b/packages/map_core/test/shadow/project_element_shadow_config_json_codec_test.dart
index c4465df4..8ded62ad 100644
--- a/packages/map_core/test/shadow/project_element_shadow_config_json_codec_test.dart
+++ b/packages/map_core/test/shadow/project_element_shadow_config_json_codec_test.dart
@@ -12,6 +12,12 @@ void main() {
         scaleX: 1.2,
         scaleY: 0.45,
         opacity: 0.35,
+        footprint: StaticShadowFootprintConfig(
+          anchorXRatio: 0.5,
+          anchorYRatio: 1,
+          footprintWidthRatio: 0.75,
+          footprintHeightRatio: 0.25,
+        ),
       );
 
       expect(encodeProjectElementShadowConfig(config), <String, Object?>{
@@ -22,6 +28,12 @@ void main() {
         'scaleX': 1.2,
         'scaleY': 0.45,
         'opacity': 0.35,
+        'footprint': <String, Object?>{
+          'anchorXRatio': 0.5,
+          'anchorYRatio': 1.0,
+          'footprintWidthRatio': 0.75,
+          'footprintHeightRatio': 0.25,
+        },
       });
     });
 
@@ -34,6 +46,12 @@ void main() {
         'scaleX': 1.2,
         'scaleY': 0.45,
         'opacity': 0.35,
+        'footprint': <String, Object?>{
+          'anchorXRatio': 0.5,
+          'anchorYRatio': 1,
+          'footprintWidthRatio': 0.75,
+          'footprintHeightRatio': 0.25,
+        },
       });
 
       expect(
@@ -46,10 +64,84 @@ void main() {
           scaleX: 1.2,
           scaleY: 0.45,
           opacity: 0.35,
+          footprint: StaticShadowFootprintConfig(
+            anchorXRatio: 0.5,
+            anchorYRatio: 1,
+            footprintWidthRatio: 0.75,
+            footprintHeightRatio: 0.25,
+          ),
         ),
       );
     });
 
+    test('old JSON without footprint decodes footprint null', () {
+      final config = decodeProjectElementShadowConfig(<String, Object?>{
+        'castsShadow': true,
+        'shadowProfileId': 'tree_large',
+      });
+
+      expect(config!.footprint, isNull);
+    });
+
+    test('encodes null and empty footprint by omitting footprint key', () {
+      expect(
+        encodeProjectElementShadowConfig(
+          ProjectElementShadowConfig(
+            castsShadow: true,
+            shadowProfileId: 'tree_large',
+          ),
+        ),
+        <String, Object?>{
+          'castsShadow': true,
+          'shadowProfileId': 'tree_large',
+        },
+      );
+      expect(
+        encodeProjectElementShadowConfig(
+          ProjectElementShadowConfig(
+            castsShadow: true,
+            shadowProfileId: 'tree_large',
+            footprint: StaticShadowFootprintConfig(),
+          ),
+        ),
+        <String, Object?>{
+          'castsShadow': true,
+          'shadowProfileId': 'tree_large',
+        },
+      );
+    });
+
+    test('equality includes footprint', () {
+      final base = ProjectElementShadowConfig(
+        castsShadow: true,
+        shadowProfileId: 'tree_large',
+        footprint: StaticShadowFootprintConfig(anchorXRatio: 0.5),
+      );
+      final same = ProjectElementShadowConfig(
+        castsShadow: true,
+        shadowProfileId: 'tree_large',
+        footprint: StaticShadowFootprintConfig(anchorXRatio: 0.5),
+      );
+      final different = ProjectElementShadowConfig(
+        castsShadow: true,
+        shadowProfileId: 'tree_large',
+        footprint: StaticShadowFootprintConfig(anchorXRatio: 0.4),
+      );
+
+      expect(base, same);
+      expect(base.hashCode, same.hashCode);
+      expect(base, isNot(different));
+    });
+
+    test('castsShadow false can carry footprint', () {
+      final config = ProjectElementShadowConfig(
+        footprint: StaticShadowFootprintConfig(footprintWidthRatio: 0.7),
+      );
+
+      expect(config.castsShadow, isFalse);
+      expect(config.footprint!.footprintWidthRatio, 0.7);
+    });
+
     test('roundtrips encode to decode', () {
       final config = ProjectElementShadowConfig(
         castsShadow: true,
@@ -182,6 +274,12 @@ void main() {
         }),
         throwsA(isA<ValidationException>()),
       );
+      expect(
+        () => decodeProjectElementShadowConfig(<String, Object?>{
+          'footprint': 'wide',
+        }),
+        throwsA(isA<ValidationException>()),
+      );
     });
 
     test('rejects invalid decoded values', () {
@@ -222,6 +320,16 @@ void main() {
         }),
         throwsA(isA<ValidationException>()),
       );
+      expect(
+        () => decodeProjectElementShadowConfig(<String, Object?>{
+          'castsShadow': true,
+          'shadowProfileId': 'tree_large',
+          'footprint': <String, Object?>{
+            'footprintWidthRatio': 0,
+          },
+        }),
+        throwsA(isA<ValidationException>()),
+      );
     });
   });
 }
```

### /dev/null — packages/map_core/lib/src/operations/static_shadow_footprint_config_json_codec.dart

```diff
diff --git a/packages/map_core/lib/src/operations/static_shadow_footprint_config_json_codec.dart b/packages/map_core/lib/src/operations/static_shadow_footprint_config_json_codec.dart
new file mode 100644
index 00000000..fcd14c06
--- /dev/null
+++ b/packages/map_core/lib/src/operations/static_shadow_footprint_config_json_codec.dart
@@ -0,0 +1,85 @@
+import '../exceptions/map_exceptions.dart';
+import '../models/shadow.dart';
+
+Map<String, Object?> _stringKeyMapFrom(Object mapLike) {
+  final map = mapLike as Map<dynamic, dynamic>;
+  return Map<String, Object?>.from(
+    map.map(
+      (dynamic key, dynamic value) => MapEntry(
+        key is String ? key : key.toString(),
+        value as Object?,
+      ),
+    ),
+  );
+}
+
+double? _optionalNullableDouble(
+  Map<String, Object?> json,
+  String key,
+  String fieldKey,
+) {
+  if (!json.containsKey(key)) {
+    return null;
+  }
+  final value = json[key];
+  if (value == null) {
+    return null;
+  }
+  if (value is! num) {
+    throw ValidationException('$fieldKey must be a num');
+  }
+  return value.toDouble();
+}
+
+Map<String, Object?>? encodeStaticShadowFootprintConfig(
+  StaticShadowFootprintConfig? footprint,
+) {
+  if (footprint == null || footprint.isEmpty) {
+    return null;
+  }
+  return <String, Object?>{
+    if (footprint.anchorXRatio != null) 'anchorXRatio': footprint.anchorXRatio,
+    if (footprint.anchorYRatio != null) 'anchorYRatio': footprint.anchorYRatio,
+    if (footprint.footprintWidthRatio != null)
+      'footprintWidthRatio': footprint.footprintWidthRatio,
+    if (footprint.footprintHeightRatio != null)
+      'footprintHeightRatio': footprint.footprintHeightRatio,
+  };
+}
+
+StaticShadowFootprintConfig? decodeStaticShadowFootprintConfig(Object? json) {
+  if (json == null) {
+    return null;
+  }
+  if (json is! Map) {
+    throw ValidationException(
+      'StaticShadowFootprintConfig JSON must be an Object or null, got ${json.runtimeType}',
+    );
+  }
+
+  final map = _stringKeyMapFrom(json);
+  final footprint = StaticShadowFootprintConfig(
+    anchorXRatio: _optionalNullableDouble(
+      map,
+      'anchorXRatio',
+      'StaticShadowFootprintConfig.anchorXRatio',
+    ),
+    anchorYRatio: _optionalNullableDouble(
+      map,
+      'anchorYRatio',
+      'StaticShadowFootprintConfig.anchorYRatio',
+    ),
+    footprintWidthRatio: _optionalNullableDouble(
+      map,
+      'footprintWidthRatio',
+      'StaticShadowFootprintConfig.footprintWidthRatio',
+    ),
+    footprintHeightRatio: _optionalNullableDouble(
+      map,
+      'footprintHeightRatio',
+      'StaticShadowFootprintConfig.footprintHeightRatio',
+    ),
+  );
+
+  return footprint.isEmpty ? null : footprint;
+}
```

Les deux fichiers de tests créés sont reproduits intégralement en section 26.
