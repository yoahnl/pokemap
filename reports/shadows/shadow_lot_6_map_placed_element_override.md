# Shadow Lot 6 — MapPlacedElement Shadow Override V0

## 1. Résumé

Shadow-6 ajoute `ShadowOverrideMode`, `MapPlacedElementShadowOverride` et `MapPlacedElement.shadowOverride`.

L'override est optionnel et limité à :

- `inherit`
- `disabled`
- `custom`
- `shadowProfileId`
- `offsetX`
- `offsetY`
- `scaleX`
- `scaleY`
- `opacity`

Aucun resolver, aucun renderer, aucune UI, aucun runtime et aucun editor n'est ajouté.

Le rapport inclut aussi le code généré/modifié du lot, conformément à la règle de reporting ajoutée.

## 2. Fichiers créés

- `packages/map_core/lib/src/operations/map_placed_element_shadow_override_json_codec.dart`
- `packages/map_core/test/shadow/map_placed_element_shadow_override_test.dart`
- `packages/map_core/test/shadow/map_placed_element_shadow_override_json_codec_test.dart`
- `packages/map_core/test/shadow/map_placed_element_shadow_json_test.dart`
- `reports/shadows/shadow_lot_6_map_placed_element_override.md`

## 3. Fichiers modifiés

- `packages/map_core/lib/map_core.dart`
- `packages/map_core/lib/src/models/shadow.dart`
- `packages/map_core/lib/src/models/map_data.dart`
- `packages/map_core/lib/src/models/map_data.freezed.dart`
- `packages/map_core/lib/src/models/map_data.g.dart`

## 4. Modèles ajoutés

`ShadowOverrideMode` :

- `inherit`
- `disabled`
- `custom`

`MapPlacedElementShadowOverride` :

- `mode`
- `shadowProfileId`
- `offsetX`
- `offsetY`
- `scaleX`
- `scaleY`
- `opacity`

Le modèle est pur Dart, sans JSON embarqué, sans Flutter, sans Flame et sans dépendance runtime.

## 5. Champ MapPlacedElement ajouté

Le champ a été ajouté dans `packages/map_core/lib/src/models/map_data.dart`, dans le modèle Freezed `MapPlacedElement` :

```dart
@MapPlacedElementShadowOverrideJsonConverter()
MapPlacedElementShadowOverride? shadowOverride,
```

Décision :

- le champ est nullable ;
- `null` signifie `inherit` au niveau sémantique ;
- ancien JSON sans `shadowOverride` décode encore avec `shadowOverride == null` ;
- JSON avec `"shadowOverride": null` décode avec `shadowOverride == null` ;
- `copyWith` permet de modifier `shadowOverride` après génération Freezed ;
- `toJson` préserve `shadowOverride` quand il est non-null ;
- `toJson` avec `shadowOverride == null` conserve le style existant generated et émet la clé avec `null`.

## 6. Codec / converter JSON ajouté

API ajoutée :

```dart
Map<String, Object?> encodeMapPlacedElementShadowOverride(
  MapPlacedElementShadowOverride override,
);

MapPlacedElementShadowOverride? decodeMapPlacedElementShadowOverride(
  Object? json,
);

class MapPlacedElementShadowOverrideJsonConverter
    implements JsonConverter<MapPlacedElementShadowOverride?, Object?>
```

Décodage :

- `null` -> `null`
- `{}` -> `MapPlacedElementShadowOverride(mode: inherit)`
- mode absent -> `inherit`
- champs inconnus ignorés
- `shadowProfileId: null` accepté comme absent
- strings/nombres stricts, sans parsing implicite

Encodage :

- émet toujours `mode`
- émet les champs optionnels uniquement s'ils sont non-null
- n'émet aucun champ hors V0.

## 7. Compatibilité anciens JSON

Compatibilité vérifiée :

- `MapPlacedElement.fromJson` sans `shadowOverride` -> `shadowOverride == null`
- `MapPlacedElement.fromJson` avec `"shadowOverride": null` -> `shadowOverride == null`
- `MapData.fromJson` avec anciens `placedElements` sans `shadowOverride` -> decode encore
- `MapData.toJson` avec `shadowOverride` non-null préserve l'override

## 8. Validations implémentées

`MapPlacedElementShadowOverride` valide :

- `shadowProfileId` non vide si fourni ;
- `offsetX`, `offsetY`, `scaleX`, `scaleY`, `opacity` finis si fournis ;
- `scaleX > 0` si fourni ;
- `scaleY > 0` si fourni ;
- `0 <= opacity <= 1` si fourni ;
- `inherit` refuse tout champ custom ;
- `disabled` refuse tout champ custom ;
- `custom` peut porter seulement `shadowProfileId`, offsets, scales et opacity.

Valeurs rejetées par tests :

- profil vide ou whitespace ;
- `inherit` avec `shadowProfileId`, `offsetX` ou `opacity` ;
- `disabled` avec `shadowProfileId`, `offsetX` ou `opacity` ;
- `NaN` et `Infinity` sur offsets/scales/opacity ;
- `scaleX <= 0` ;
- `scaleY <= 0` ;
- `opacity < 0` ;
- `opacity > 1`.

## 9. Tests ajoutés

Tests ajoutés :

- `map_placed_element_shadow_override_test.dart`
  - defaults, modes, custom sans profil, opacity bounds, validations, equality/hash.
- `map_placed_element_shadow_override_json_codec_test.dart`
  - encode/decode canonique, null/empty, unknown fields, types invalides, valeurs invalides.
- `map_placed_element_shadow_json_test.dart`
  - compat legacy `MapPlacedElement`, compat legacy `MapData`, `copyWith`, `toJson`, non-régression `applyCollision`, `opacity`, `animation`, `behaviors`, `properties`.

## 10. Commandes lancées

```bash
git status --short --untracked-files=all
dart test test/shadow/map_placed_element_shadow_override_test.dart test/shadow/map_placed_element_shadow_override_json_codec_test.dart test/shadow/map_placed_element_shadow_json_test.dart
dart format lib/src/models/shadow.dart lib/src/models/map_data.dart lib/src/operations/map_placed_element_shadow_override_json_codec.dart lib/map_core.dart test/shadow/map_placed_element_shadow_override_test.dart test/shadow/map_placed_element_shadow_override_json_codec_test.dart test/shadow/map_placed_element_shadow_json_test.dart
dart run build_runner build --delete-conflicting-outputs
dart test --reporter compact --no-color test/shadow/map_placed_element_shadow_override_test.dart test/shadow/map_placed_element_shadow_override_json_codec_test.dart test/shadow/map_placed_element_shadow_json_test.dart
dart test --reporter compact --no-color test/shadow
dart analyze lib/src/models/shadow.dart lib/src/models/map_data.dart lib/src/operations/map_placed_element_shadow_override_json_codec.dart test/shadow
dart test --reporter compact --no-color
dart analyze
rg -n "ShadowResolvedConfig|ShadowRuntimeRenderInstruction|WorldLightState|ShadowLightProfile|resolveShadow|shadow_config_resolver" packages/map_core/lib/src || true
rg -n "runtimeBlur|blurRadius|zOrder|zIndex|modeOverride|colorOverride|renderPassOverride|softnessOverride|shadowTilesetId|shadowSource|sourceMaskId" packages/map_core/lib/src/models packages/map_core/lib/src/operations || true
find packages/map_core/lib -name "*shadow*.g.dart" -o -name "*shadow*.freezed.dart"
git diff --check
git diff --stat
git status --short --untracked-files=all
git status --short --untracked-files=all -- packages/map_editor packages/map_runtime packages/map_gameplay packages/map_battle
```

## 11. Résultats des tests ciblés

RED attendu avant implémentation :

```text
Failed to load "test/shadow/map_placed_element_shadow_override_test.dart"
Error: Method not found: 'MapPlacedElementShadowOverride'.
Error: Undefined name 'ShadowOverrideMode'.
Error: The getter 'shadowOverride' isn't defined for the type 'MapPlacedElement'.
Some tests failed.
```

GREEN final :

```text
00:00 +25: All tests passed!
```

## 12. Résultat de dart test test/shadow

```text
00:00 +129: All tests passed!
```

## 13. Résultat de dart analyze

Analyse ciblée :

```text
Analyzing shadow.dart, map_data.dart, map_placed_element_shadow_override_json_codec.dart, shadow...
No issues found!
```

Analyse complète `map_core` :

```text
Analyzing map_core...
No issues found!
```

## 14. Résultat du test complet map_core

```text
00:02 +1485: All tests passed!
```

## 15. Build runner / génération

Build runner lancé : oui.

Commande :

```bash
cd packages/map_core && dart run build_runner build --delete-conflicting-outputs
```

Résultat :

```text
Built with build_runner in 8s; wrote 12 outputs.
```

Warnings observés :

```text
W SDK language version 3.11.0 is newer than `analyzer` language version 3.9.0. Run `dart pub upgrade`.
W json_serializable on lib/src/models/element_collision_profile.dart:
  The version constraint "^4.8.1" on json_annotation allows versions before 4.9.0 which is not allowed.
```

Fichiers generated modifiés :

- `packages/map_core/lib/src/models/map_data.freezed.dart`
- `packages/map_core/lib/src/models/map_data.g.dart`

Confirmation :

- aucun `*shadow*.g.dart` créé ;
- aucun `*shadow*.freezed.dart` créé.

## 16. Vérifications anti-dérive

Confirmé :

- aucun `ProjectManifest` modifié ;
- aucun `ProjectElementEntry` modifié ;
- aucun `ProjectShadowCatalog` modifié ;
- aucun `ShadowResolvedConfig` ;
- aucun Shadow Config Resolver ;
- aucun `ShadowRuntimeRenderInstruction` ;
- aucun `map_editor` modifié ;
- aucun `map_runtime` modifié ;
- aucun `map_gameplay` modifié ;
- aucun `applyCollision` modifié ;
- aucun `behaviors` / `properties` modifié ;
- aucune collision modifiée ;
- aucune occlusion modifiée ;
- aucun `visualMask` modifié ;
- aucun `cells` modifié ;
- aucun `runtimeBlur` ;
- aucun `blurRadius` ;
- aucun `zOrder` / `zIndex` ;
- aucun `modeOverride`, `colorOverride`, `renderPassOverride`, `softnessOverride` ;
- aucune UI ;
- aucun renderer.

Commandes anti-dérive :

```text
rg ShadowResolvedConfig/... -> aucune sortie
rg runtimeBlur/blurRadius/zOrder/... -> aucune sortie
find *shadow*.g.dart/*shadow*.freezed.dart -> aucune sortie
git diff --check -> aucune sortie
git status map_editor/map_runtime/map_gameplay/map_battle -> aucune sortie
```

## 17. Git status initial

Le tout premier status du lot avant écriture des tests RED était clean.

Status observé à la reprise, avant implémentation production, avec les tests RED déjà créés dans ce même lot :

```text
?? packages/map_core/test/shadow/map_placed_element_shadow_json_test.dart
?? packages/map_core/test/shadow/map_placed_element_shadow_override_json_codec_test.dart
?? packages/map_core/test/shadow/map_placed_element_shadow_override_test.dart
```

## 18. Git status final

```text
 M packages/map_core/lib/map_core.dart
 M packages/map_core/lib/src/models/map_data.dart
 M packages/map_core/lib/src/models/map_data.freezed.dart
 M packages/map_core/lib/src/models/map_data.g.dart
 M packages/map_core/lib/src/models/shadow.dart
?? packages/map_core/lib/src/operations/map_placed_element_shadow_override_json_codec.dart
?? packages/map_core/test/shadow/map_placed_element_shadow_json_test.dart
?? packages/map_core/test/shadow/map_placed_element_shadow_override_json_codec_test.dart
?? packages/map_core/test/shadow/map_placed_element_shadow_override_test.dart
?? reports/shadows/shadow_lot_6_map_placed_element_override.md
```

## 19. Git diff stat final

`git diff --stat` ne liste que les fichiers suivis modifiés, pas les nouveaux fichiers non suivis :

```text
 packages/map_core/lib/map_core.dart                |   1 +
 packages/map_core/lib/src/models/map_data.dart     |   5 +
 .../map_core/lib/src/models/map_data.freezed.dart  |  31 ++++-
 packages/map_core/lib/src/models/map_data.g.dart   |   4 +
 packages/map_core/lib/src/models/shadow.dart       | 135 +++++++++++++++++++++
 5 files changed, 175 insertions(+), 1 deletion(-)
```

## 20. Non-objectifs respectés

Non implémenté dans Shadow-6 :

- pas de modification `ProjectManifest` ;
- pas de modification `ProjectElementEntry` ;
- pas de modification `ProjectElementShadowConfig` ;
- pas de modification `ProjectShadowCatalog` ;
- pas de modification `ProjectShadowProfile` ;
- pas de `ShadowResolvedConfig` ;
- pas de resolver ;
- pas de renderer ;
- pas de Flame ;
- pas d'éditeur ;
- pas de gameplay ;
- pas de collision/occlusion ;
- pas de `runtimeBlur` ;
- pas de `blurRadius` ;
- pas de `zOrder` / `zIndex` ;
- pas de `shadowTilesetId` / `shadowSource` ;
- pas de custom shadow sprite ;
- pas de time-of-day.

## 21. Risques / réserves

- Le champ generated `toJson` émet `shadowOverride: null` quand l'override est absent, ce qui suit le style Freezed/JsonSerializable existant de `MapPlacedElement`.
- Le codec accepte `shadowProfileId: null` comme absent. C'est une tolérance JSON locale pour les données optionnelles ; les strings non-null restent strictement typées.
- Shadow-6 ne vérifie pas l'existence de `shadowProfileId` dans `ProjectManifest.shadowCatalog`. Ce point reste volontairement pour Shadow-7.
- Aucun test editor/runtime n'a été lancé, car le lot est strictement `map_core`.

## 22. Prochain lot recommandé

Shadow-7 — Shadow Config Resolver / Merge Rules V0.

Ne pas l'implémenter dans Shadow-6.

## 23. Code généré / modifié dans ce lot

### 23.1 `packages/map_core/lib/src/models/shadow.dart`

Code Shadow-6 ajouté au fichier :

```dart
/// Per-instance V0 override mode for a placed element shadow.
enum ShadowOverrideMode {
  /// Use the default shadow configuration from the project element.
  inherit,

  /// Disable the shadow for this placed element instance.
  disabled,

  /// Apply limited per-instance profile and numeric overrides later.
  custom,
}

/// Optional per-instance shadow override carried by a placed element.
///
/// This is only an authoring/data contract. Shadow-6 does not resolve profiles,
/// merge element defaults, affect collision, or render anything.
@immutable
final class MapPlacedElementShadowOverride {
  MapPlacedElementShadowOverride({
    this.mode = ShadowOverrideMode.inherit,
    this.shadowProfileId,
    this.offsetX,
    this.offsetY,
    this.scaleX,
    this.scaleY,
    this.opacity,
  }) {
    final profileId = shadowProfileId;
    if (profileId != null) {
      _validateMapPlacedElementShadowProfileId(profileId);
    }
    _validateMapPlacedElementShadowOptionalFinite(offsetX, 'offsetX');
    _validateMapPlacedElementShadowOptionalFinite(offsetY, 'offsetY');
    _validateMapPlacedElementShadowOptionalPositive(scaleX, 'scaleX');
    _validateMapPlacedElementShadowOptionalPositive(scaleY, 'scaleY');
    _validateMapPlacedElementShadowOptionalOpacity(opacity);

    if (mode != ShadowOverrideMode.custom &&
        _hasMapPlacedElementShadowCustomFields) {
      throw ValidationException(
        'MapPlacedElementShadowOverride.${mode.name} cannot carry custom shadow fields',
      );
    }
  }

  /// Whether this instance inherits, disables, or customizes its shadow.
  final ShadowOverrideMode mode;

  /// Optional profile replacement for [ShadowOverrideMode.custom].
  ///
  /// Shadow-6 intentionally does not resolve this id against a catalog.
  final String? shadowProfileId;

  /// Optional numeric instance overrides applied later by the Shadow resolver.
  final double? offsetX;
  final double? offsetY;
  final double? scaleX;
  final double? scaleY;
  final double? opacity;

  bool get _hasMapPlacedElementShadowCustomFields =>
      shadowProfileId != null ||
      offsetX != null ||
      offsetY != null ||
      scaleX != null ||
      scaleY != null ||
      opacity != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapPlacedElementShadowOverride &&
          other.mode == mode &&
          other.shadowProfileId == shadowProfileId &&
          other.offsetX == offsetX &&
          other.offsetY == offsetY &&
          other.scaleX == scaleX &&
          other.scaleY == scaleY &&
          other.opacity == opacity;

  @override
  int get hashCode => Object.hash(
        mode,
        shadowProfileId,
        offsetX,
        offsetY,
        scaleX,
        scaleY,
        opacity,
      );
}

void _validateMapPlacedElementShadowProfileId(String value) {
  if (value.trim().isEmpty) {
    throw const ValidationException(
      'MapPlacedElementShadowOverride.shadowProfileId must be non-empty',
    );
  }
}

void _validateMapPlacedElementShadowOptionalFinite(
  double? value,
  String name,
) {
  if (value == null) {
    return;
  }
  if (!value.isFinite) {
    throw ValidationException(
      'MapPlacedElementShadowOverride.$name must be finite',
    );
  }
}

void _validateMapPlacedElementShadowOptionalPositive(
  double? value,
  String name,
) {
  _validateMapPlacedElementShadowOptionalFinite(value, name);
  if (value != null && value <= 0) {
    throw ValidationException(
      'MapPlacedElementShadowOverride.$name must be > 0',
    );
  }
}

void _validateMapPlacedElementShadowOptionalOpacity(double? value) {
  _validateMapPlacedElementShadowOptionalFinite(value, 'opacity');
  if (value != null && (value < 0 || value > 1)) {
    throw const ValidationException(
      'MapPlacedElementShadowOverride.opacity must be between 0 and 1',
    );
  }
}
```

### 23.2 `packages/map_core/lib/src/operations/map_placed_element_shadow_override_json_codec.dart`

```dart
import 'package:json_annotation/json_annotation.dart';

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
    throw ValidationException('$fieldKey must be a non-null String');
  }
  return value;
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
  if (value is! num) {
    throw ValidationException('$fieldKey must be a num');
  }
  return value.toDouble();
}

ShadowOverrideMode _decodeShadowOverrideMode(Map<String, Object?> json) {
  if (!json.containsKey('mode')) {
    return ShadowOverrideMode.inherit;
  }

  final value = json['mode'];
  if (value is! String) {
    throw const ValidationException(
      'MapPlacedElementShadowOverride.mode must be a String',
    );
  }

  for (final mode in ShadowOverrideMode.values) {
    if (mode.name == value) {
      return mode;
    }
  }

  throw ValidationException(
    'Unknown MapPlacedElementShadowOverride.mode "$value"',
  );
}

/// Encodes a [MapPlacedElementShadowOverride] using the external Shadow V0
/// JSON shape.
Map<String, Object?> encodeMapPlacedElementShadowOverride(
  MapPlacedElementShadowOverride override,
) {
  return <String, Object?>{
    'mode': override.mode.name,
    if (override.shadowProfileId != null)
      'shadowProfileId': override.shadowProfileId,
    if (override.offsetX != null) 'offsetX': override.offsetX,
    if (override.offsetY != null) 'offsetY': override.offsetY,
    if (override.scaleX != null) 'scaleX': override.scaleX,
    if (override.scaleY != null) 'scaleY': override.scaleY,
    if (override.opacity != null) 'opacity': override.opacity,
  };
}

/// Decodes an optional [MapPlacedElementShadowOverride] from its external
/// Shadow V0 JSON shape.
///
/// `null` means no per-instance override, which is equivalent to inherit.
/// Unknown keys are ignored.
MapPlacedElementShadowOverride? decodeMapPlacedElementShadowOverride(
  Object? json,
) {
  if (json == null) {
    return null;
  }
  if (json is! Map) {
    throw ValidationException(
      'MapPlacedElementShadowOverride JSON must be an Object or null, got ${json.runtimeType}',
    );
  }

  final map = _stringKeyMapFrom(json);
  return MapPlacedElementShadowOverride(
    mode: _decodeShadowOverrideMode(map),
    shadowProfileId: _optionalNullableString(
      map,
      'shadowProfileId',
      'MapPlacedElementShadowOverride.shadowProfileId',
    ),
    offsetX: _optionalNullableDouble(
      map,
      'offsetX',
      'MapPlacedElementShadowOverride.offsetX',
    ),
    offsetY: _optionalNullableDouble(
      map,
      'offsetY',
      'MapPlacedElementShadowOverride.offsetY',
    ),
    scaleX: _optionalNullableDouble(
      map,
      'scaleX',
      'MapPlacedElementShadowOverride.scaleX',
    ),
    scaleY: _optionalNullableDouble(
      map,
      'scaleY',
      'MapPlacedElementShadowOverride.scaleY',
    ),
    opacity: _optionalNullableDouble(
      map,
      'opacity',
      'MapPlacedElementShadowOverride.opacity',
    ),
  );
}

class MapPlacedElementShadowOverrideJsonConverter
    implements JsonConverter<MapPlacedElementShadowOverride?, Object?> {
  const MapPlacedElementShadowOverrideJsonConverter();

  @override
  MapPlacedElementShadowOverride? fromJson(Object? json) {
    return decodeMapPlacedElementShadowOverride(json);
  }

  @override
  Object? toJson(MapPlacedElementShadowOverride? override) {
    return override == null
        ? null
        : encodeMapPlacedElementShadowOverride(override);
  }
}
```

### 23.3 `packages/map_core/lib/src/models/map_data.dart`

Imports Shadow-6 ajoutés :

```dart
import 'shadow.dart';

import '../operations/map_placed_element_shadow_override_json_codec.dart';
```

Champ ajouté dans `MapPlacedElement` :

```dart
@freezed
class MapPlacedElement with _$MapPlacedElement {
  @JsonSerializable(explicitToJson: true)
  const factory MapPlacedElement({
    required String id,
    required String layerId,
    required String elementId,
    required GridPos pos,
    @Default(true) bool applyCollision,
    @Default(1.0) double opacity,
    MapPlacedElementAnimation? animation,
    @MapPlacedElementShadowOverrideJsonConverter()
    MapPlacedElementShadowOverride? shadowOverride,
    @Default([]) List<MapPlacedElementBehavior> behaviors,
    @Default({}) Map<String, String> properties,
  }) = _MapPlacedElement;

  factory MapPlacedElement.fromJson(Map<String, dynamic> json) =>
      _$MapPlacedElementFromJson(migrateMapPlacedElementJson(json));
}
```

### 23.4 `packages/map_core/lib/map_core.dart`

Export ajouté :

```dart
export 'src/operations/map_placed_element_shadow_override_json_codec.dart';
```

### 23.5 Extraits generated `map_data.g.dart`

```dart
_$MapPlacedElementImpl _$$MapPlacedElementImplFromJson(
        Map<String, dynamic> json) =>
    _$MapPlacedElementImpl(
      id: json['id'] as String,
      layerId: json['layerId'] as String,
      elementId: json['elementId'] as String,
      pos: GridPos.fromJson(json['pos'] as Map<String, dynamic>),
      applyCollision: json['applyCollision'] as bool? ?? true,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      animation: json['animation'] == null
          ? null
          : MapPlacedElementAnimation.fromJson(
              json['animation'] as Map<String, dynamic>),
      shadowOverride: const MapPlacedElementShadowOverrideJsonConverter()
          .fromJson(json['shadowOverride']),
      behaviors: (json['behaviors'] as List<dynamic>?)
              ?.map((e) =>
                  MapPlacedElementBehavior.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      properties: (json['properties'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
    );

Map<String, dynamic> _$$MapPlacedElementImplToJson(
        _$MapPlacedElementImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'layerId': instance.layerId,
      'elementId': instance.elementId,
      'pos': instance.pos.toJson(),
      'applyCollision': instance.applyCollision,
      'opacity': instance.opacity,
      'animation': instance.animation?.toJson(),
      'shadowOverride': const MapPlacedElementShadowOverrideJsonConverter()
          .toJson(instance.shadowOverride),
      'behaviors': instance.behaviors.map((e) => e.toJson()).toList(),
      'properties': instance.properties,
    };
```

### 23.6 Extraits generated `map_data.freezed.dart`

```dart
mixin _$MapPlacedElement {
  String get id => throw _privateConstructorUsedError;
  String get layerId => throw _privateConstructorUsedError;
  String get elementId => throw _privateConstructorUsedError;
  GridPos get pos => throw _privateConstructorUsedError;
  bool get applyCollision => throw _privateConstructorUsedError;
  double get opacity => throw _privateConstructorUsedError;
  MapPlacedElementAnimation? get animation =>
      throw _privateConstructorUsedError;
  @MapPlacedElementShadowOverrideJsonConverter()
  MapPlacedElementShadowOverride? get shadowOverride =>
      throw _privateConstructorUsedError;
  List<MapPlacedElementBehavior> get behaviors =>
      throw _privateConstructorUsedError;
  Map<String, String> get properties => throw _privateConstructorUsedError;
}
```

```dart
class _$MapPlacedElementImpl implements _MapPlacedElement {
  const _$MapPlacedElementImpl(
      {required this.id,
      required this.layerId,
      required this.elementId,
      required this.pos,
      this.applyCollision = true,
      this.opacity = 1.0,
      this.animation,
      @MapPlacedElementShadowOverrideJsonConverter() this.shadowOverride,
      final List<MapPlacedElementBehavior> behaviors = const [],
      final Map<String, String> properties = const {}})
      : _behaviors = behaviors,
        _properties = properties;

  @override
  @MapPlacedElementShadowOverrideJsonConverter()
  final MapPlacedElementShadowOverride? shadowOverride;
}
```

### 23.7 Tests Shadow-6 générés

Extraits des tests créés :

```dart
test('defaults to inherit', () {
  final override = MapPlacedElementShadowOverride();

  expect(override.mode, ShadowOverrideMode.inherit);
  expect(override.shadowProfileId, isNull);
  expect(override.offsetX, isNull);
  expect(override.offsetY, isNull);
  expect(override.scaleX, isNull);
  expect(override.scaleY, isNull);
  expect(override.opacity, isNull);
});
```

```dart
test('encodes inherit, disabled, and custom canonically', () {
  expect(
    encodeMapPlacedElementShadowOverride(MapPlacedElementShadowOverride()),
    <String, Object?>{'mode': 'inherit'},
  );
  expect(
    encodeMapPlacedElementShadowOverride(
      MapPlacedElementShadowOverride(mode: ShadowOverrideMode.disabled),
    ),
    <String, Object?>{'mode': 'disabled'},
  );
  expect(
    encodeMapPlacedElementShadowOverride(_customOverride()),
    <String, Object?>{
      'mode': 'custom',
      'shadowProfileId': 'tree_short',
      'offsetX': 2.0,
      'offsetY': 8.0,
      'scaleX': 0.8,
      'scaleY': 0.35,
      'opacity': 0.25,
    },
  );
});
```

```dart
test('legacy MapData JSON decodes placed element without shadowOverride', () {
  final map = MapData.fromJson(<String, Object?>{
    'id': 'map',
    'name': 'Map',
    'size': <String, Object?>{'width': 10, 'height': 8},
    'placedElements': <Object?>[_placedElementJson()],
  });

  expect(map.placedElements.single.shadowOverride, isNull);
});
```

```dart
test('adding shadowOverride does not modify gameplay or authoring fields', () {
  const behavior = MapPlacedElementBehavior(
    id: 'behavior',
    trigger: MapPlacedElementTriggerType.onAction,
    effect: MapPlacedElementEffect(
      type: MapPlacedElementEffectType.showMessage,
      message: 'Hello',
    ),
  );
  const animation = MapPlacedElementAnimation(
    enabled: true,
    speed: 1.5,
    startOffsetMs: 120,
  );
  final element = _placedElement(
    applyCollision: false,
    opacity: 0.4,
    animation: animation,
    behaviors: const [behavior],
    properties: const {'purpose': 'authoring'},
  );

  final updated = element.copyWith(shadowOverride: _customOverride());

  expect(updated.applyCollision, element.applyCollision);
  expect(updated.opacity, element.opacity);
  expect(updated.animation, same(animation));
  expect(updated.behaviors, element.behaviors);
  expect(updated.properties, element.properties);
});
```
