# ShadowV2-9 — Projected Shadow Atomic JSON Codecs V0

## 1. Résumé exécutif

ShadowV2-9 ajoute uniquement les codecs JSON manuels des six value objects atomiques ShadowV2 :

- `ProjectedShadowDirection`
- `ProjectedShadowAnchor`
- `ProjectedShadowOffset`
- `ProjectedShadowShapeTuning`
- `ProjectedShadowAppearance`
- `ProjectedShadowTimeOfDayMode`

Le lot ne crée aucun codec composite, ne modifie aucun manifest, ne modifie aucun modèle persistant V1/V2, ne modifie aucun runtime/editor, ne lance pas `build_runner`, et ne crée aucun fichier généré.

## 2. Objectif du lot

Objectif : encoder/décoder les atomes ShadowV2 nécessaires aux prochains codecs de preset/config, sans brancher la V2 à `ProjectManifest`, `ProjectElementEntry`, `MapPlacedElement`, runtime ou éditeur.

Règle conservée :

```text
Les grandes ombres projetées doivent être asset-driven, authorées, previewées et validées.
Jamais réintroduites par genericProjection automatique.
```

## 3. Rappel ShadowV2-8

ShadowV2-8 a validé :

- root field futur : `projectedBuildingShadowCatalog`
- root shape future : `{ "presets": [...] }`
- element field futur : `projectedBuildingShadow`
- codecs : manuels externes dans `operations`
- migration : additive, aucune injection automatique

ShadowV2-9 applique uniquement la décision "codecs manuels externes" aux value objects atomiques.

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

- ShadowV2-8 a fourni le design JSON validé.
- ShadowV2-9 est une implémentation bornée des codecs atomiques prévus par ce design.
- Le design gate est respecté.

## 6. Fichiers créés / modifiés

Créés :

- `packages/map_core/lib/src/operations/projected_shadow_value_object_json_codecs.dart`
- `packages/map_core/test/shadow_v2/projected_shadow_value_object_json_codecs_test.dart`
- `reports/shadows/v2/shadow_v2_9_projected_shadow_atomic_json_codecs.md`

Modifiés :

- `packages/map_core/lib/map_core.dart`

Supprimés :

- Aucun

Generated files :

- Aucun

Fichiers Selbrume :

- Aucun

## 7. Codecs créés

Fonctions créées :

- `encodeProjectedShadowDirection`
- `decodeProjectedShadowDirection`
- `encodeProjectedShadowAnchor`
- `decodeProjectedShadowAnchor`
- `encodeProjectedShadowOffset`
- `decodeProjectedShadowOffset`
- `encodeProjectedShadowShapeTuning`
- `decodeProjectedShadowShapeTuning`
- `encodeProjectedShadowAppearance`
- `decodeProjectedShadowAppearance`
- `encodeProjectedShadowTimeOfDayMode`
- `decodeProjectedShadowTimeOfDayMode`

Non créés :

- `ProjectBuildingShadowPreset` codec
- `ProjectBuildingShadowPresetCatalog` codec
- `ProjectElementProjectedBuildingShadowConfig` codec
- manifest integration
- runtime resolver
- editor integration

Vérification anti-composite :

```bash
rg -n "ProjectBuildingShadowPreset|ProjectBuildingShadowPresetCatalog|ProjectElementProjectedBuildingShadowConfig|ProjectManifest|ProjectElementEntry|MapPlacedElement|migrateProjectManifestJson" packages/map_core/lib/src/operations/projected_shadow_value_object_json_codecs.dart packages/map_core/test/shadow_v2/projected_shadow_value_object_json_codecs_test.dart
```

Sortie :

```text
```

Exit code : `1`, ce qui signifie aucun match.

## 8. JSON canonique par value object

Direction :

```json
{
  "x": -0.55,
  "y": 0.35
}
```

Anchor :

```json
{
  "xRatio": 0.5,
  "yRatio": 0.98
}
```

Offset :

```json
{
  "x": 0,
  "y": -2.5
}
```

Shape tuning :

```json
{
  "lengthRatio": 0.28,
  "nearWidthRatio": 0.85,
  "farWidthRatio": 0.75
}
```

Appearance :

```json
{
  "opacity": 0.18,
  "colorHexRgb": "000000"
}
```

Time-of-day mode :

```json
"fixed"
```

```json
"followsSun"
```

## 9. Stratégie d’erreurs

Audit ciblé :

```bash
rg -n "ValidationException|ProjectShadowProfile JSON must be|must be a num|unknown value|StaticShadowFootprintConfig JSON" packages/map_core/lib/src/operations/project_shadow_profile_json_codec.dart packages/map_core/lib/src/operations/static_shadow_footprint_config_json_codec.dart packages/map_core/lib/src/operations/static_shadow_family_json_codec.dart
```

Sortie :

```text
packages/map_core/lib/src/operations/project_shadow_profile_json_codec.dart:22:    throw ValidationException('$fieldKey is required');
packages/map_core/lib/src/operations/project_shadow_profile_json_codec.dart:34:    throw ValidationException('$fieldKey must be a non-null String');
packages/map_core/lib/src/operations/project_shadow_profile_json_codec.dart:50:    throw ValidationException('$fieldKey must be a non-null String');
packages/map_core/lib/src/operations/project_shadow_profile_json_codec.dart:66:    throw ValidationException('$fieldKey must be a num');
packages/map_core/lib/src/operations/project_shadow_profile_json_codec.dart:77:  throw ValidationException(
packages/map_core/lib/src/operations/project_shadow_profile_json_codec.dart:78:      'ProjectShadowProfile.mode has unknown value "$value"');
packages/map_core/lib/src/operations/project_shadow_profile_json_codec.dart:87:  throw ValidationException(
packages/map_core/lib/src/operations/project_shadow_profile_json_codec.dart:88:    'ProjectShadowProfile.renderPass has unknown value "$value"',
packages/map_core/lib/src/operations/project_shadow_profile_json_codec.dart:98:  throw ValidationException(
packages/map_core/lib/src/operations/project_shadow_profile_json_codec.dart:99:    'ProjectShadowProfile.softnessMode has unknown value "$value"',
packages/map_core/lib/src/operations/project_shadow_profile_json_codec.dart:137:    throw ValidationException(
packages/map_core/lib/src/operations/project_shadow_profile_json_codec.dart:138:      'ProjectShadowProfile JSON must be an Object, got ${json.runtimeType}',
packages/map_core/lib/src/operations/static_shadow_family_json_codec.dart:13:    throw ValidationException(
packages/map_core/lib/src/operations/static_shadow_family_json_codec.dart:22:  throw ValidationException('Unknown StaticShadowFamily "$json"');
packages/map_core/lib/src/operations/static_shadow_footprint_config_json_codec.dart:29:    throw ValidationException('$fieldKey must be a num');
packages/map_core/lib/src/operations/static_shadow_footprint_config_json_codec.dart:55:    throw ValidationException(
packages/map_core/lib/src/operations/static_shadow_footprint_config_json_codec.dart:56:      'StaticShadowFootprintConfig JSON must be an Object or null, got ${json.runtimeType}',
```

Décision appliquée :

- `ValidationException` pour forme JSON invalide, champ requis absent, type invalide, valeur non finie, enum inconnue.
- Les validations métier finales restent portées par les value objects existants.
- Les unknown keys sont ignorées au decode.
- L’encode n’émet que les champs canoniques.
- `ProjectedShadowTimeOfDayMode` est strict : pas de fallback, pas de case-insensitive.

## 10. Tests ajoutés

Test ajouté :

- `packages/map_core/test/shadow_v2/projected_shadow_value_object_json_codecs_test.dart`

Couverture :

- encode canonique
- decode canonique
- round-trip
- unknown keys ignorées
- champs requis absents rejetés
- types invalides rejetés
- validations déléguées aux value objects
- couleur lowercase réémise uppercase
- enum inconnue / non-string / mauvaise casse rejetée

Phase TDD rouge :

```bash
cd packages/map_core && dart test test/shadow_v2/projected_shadow_value_object_json_codecs_test.dart
```

Résultat initial attendu :

```text
Failed to load "test/shadow_v2/projected_shadow_value_object_json_codecs_test.dart":
Error: Method not found: 'encodeProjectedShadowDirection'.
...
00:00 +0 -1: Some tests failed.
```

## 11. Résultats des tests

Test ciblé final :

```bash
cd packages/map_core && dart test -r expanded test/shadow_v2/projected_shadow_value_object_json_codecs_test.dart
```

Sortie complète :

```text
00:00 +0: loading test/shadow_v2/projected_shadow_value_object_json_codecs_test.dart
00:00 +0: ProjectedShadowDirection JSON codec encodes the canonical x/y object
00:00 +1: ProjectedShadowDirection JSON codec decodes the canonical x/y object and ignores unknown keys
00:00 +2: ProjectedShadowDirection JSON codec round-trips through the canonical object
00:00 +3: ProjectedShadowDirection JSON codec rejects invalid JSON shape and required fields
00:00 +4: ProjectedShadowAnchor JSON codec encodes the canonical xRatio/yRatio object
00:00 +5: ProjectedShadowAnchor JSON codec decodes the canonical ratio object and ignores unknown keys
00:00 +6: ProjectedShadowAnchor JSON codec round-trips through the canonical object
00:00 +7: ProjectedShadowAnchor JSON codec rejects missing fields and invalid ratios
00:00 +8: ProjectedShadowOffset JSON codec encodes the canonical x/y object
00:00 +9: ProjectedShadowOffset JSON codec decodes positive, zero, and negative offsets with unknown keys ignored
00:00 +10: ProjectedShadowOffset JSON codec round-trips through the canonical object
00:00 +11: ProjectedShadowOffset JSON codec rejects missing and non-numeric coordinates
00:00 +12: ProjectedShadowShapeTuning JSON codec encodes the canonical shape object
00:00 +13: ProjectedShadowShapeTuning JSON codec decodes the canonical shape object and ignores unknown keys
00:00 +14: ProjectedShadowShapeTuning JSON codec round-trips through the canonical object
00:00 +15: ProjectedShadowShapeTuning JSON codec rejects missing fields and invalid ratios
00:00 +16: ProjectedShadowAppearance JSON codec encodes the canonical appearance object with uppercase color
00:00 +17: ProjectedShadowAppearance JSON codec decodes the canonical appearance object and ignores unknown keys
00:00 +18: ProjectedShadowAppearance JSON codec round-trips lowercase color as uppercase
00:00 +19: ProjectedShadowAppearance JSON codec accepts opacity boundaries
00:00 +20: ProjectedShadowAppearance JSON codec rejects missing fields and invalid appearance values
00:00 +21: ProjectedShadowTimeOfDayMode JSON codec encodes fixed and followsSun
00:00 +22: ProjectedShadowTimeOfDayMode JSON codec decodes fixed and followsSun
00:00 +23: ProjectedShadowTimeOfDayMode JSON codec rejects unknown, non-string, and wrongly-cased values
00:00 +24: All tests passed!
```

Régression ShadowV2 :

```bash
cd packages/map_core && dart test test/shadow_v2
```

Ligne finale exacte :

```text
00:00 +85: All tests passed!
```

Régression Shadow V1 :

```bash
cd packages/map_core && dart test test/shadow
```

Ligne finale exacte :

```text
00:01 +284: All tests passed!
```

## 12. Résultat analyze

Commande :

```bash
cd packages/map_core && dart analyze lib/src/operations/projected_shadow_value_object_json_codecs.dart test/shadow_v2/projected_shadow_value_object_json_codecs_test.dart
```

Sortie :

```text
Analyzing projected_shadow_value_object_json_codecs.dart, projected_shadow_value_object_json_codecs_test.dart...
No issues found!
```

## 13. Export public

Export ajouté : oui.

Raison : `packages/map_core/lib/map_core.dart` exporte déjà les codecs manuels existants (`project_shadow_profile_json_codec.dart`, `project_shadow_catalog_json_codec.dart`, `static_shadow_footprint_config_json_codec.dart`, etc.). Le nouveau codec suit cette convention.

Diff :

```diff
diff --git a/packages/map_core/lib/map_core.dart b/packages/map_core/lib/map_core.dart
index e70461e0..681099a3 100644
--- a/packages/map_core/lib/map_core.dart
+++ b/packages/map_core/lib/map_core.dart
@@ -47,6 +47,7 @@ export 'src/operations/project_manifest_shadow_catalog_operations.dart';
 export 'src/operations/project_path_pattern_preset_json_codec.dart';
 export 'src/operations/project_shadow_catalog_json_codec.dart';
 export 'src/operations/project_shadow_profile_json_codec.dart';
+export 'src/operations/projected_shadow_value_object_json_codecs.dart';
 export 'src/operations/static_shadow_family_json_codec.dart';
 export 'src/operations/static_shadow_footprint_config_json_codec.dart';
 export 'src/operations/project_json_migrations.dart';
```

## 14. Ce qui n’a volontairement pas été créé

Non créé :

- `ProjectBuildingShadowPreset` codec
- `ProjectBuildingShadowPresetCatalog` codec
- `ProjectElementProjectedBuildingShadowConfig` codec
- intégration `ProjectManifest`
- intégration `ProjectElementEntry`
- intégration `MapPlacedElement`
- migration JSON
- preset par défaut
- resolver runtime
- UI éditeur
- screenshot/baseline
- generated files

## 15. git diff --stat

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

## 16. git diff --name-status

Commande :

```bash
git diff --name-status
```

Sortie :

```text
M	packages/map_core/lib/map_core.dart
```

Note : les nouveaux fichiers non trackés sont listés dans `git status final` et dans l’inventaire des fichiers ; `git diff --name-status` ne les inclut pas tant qu’ils ne sont pas indexés.

## 17. git diff --check

Commande :

```bash
git diff --check
```

Sortie :

```text
```

Exit code : `0`.

## 18. git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie finale :

```text
 M packages/map_core/lib/map_core.dart
?? packages/map_core/lib/src/operations/projected_shadow_value_object_json_codecs.dart
?? packages/map_core/test/shadow_v2/projected_shadow_value_object_json_codecs_test.dart
?? reports/shadows/v2/shadow_v2_9_projected_shadow_atomic_json_codecs.md
```

## 19. Risques / réserves

- Les codecs atomiques sont exportés publiquement pour suivre la convention actuelle. Si un futur lot décide de limiter l’exposition des codecs V2, il faudra le faire explicitement.
- Les erreurs utilisent `ValidationException`, ce qui est cohérent avec les codecs Shadow/Surface récents, mais quelques codecs historiques utilisent encore `FormatException`.
- Les codecs ignorent les unknown keys au niveau atomique ; les futurs codecs composite devront décider explicitement leur politique pour les unknown keys de preset/catalog/config.

## 20. Auto-critique

Le lot reste dans le périmètre demandé : aucun codec composite, aucun champ persistant, aucune migration, aucun runtime/editor. Les tests couvrent les erreurs demandées, les round-trips et le comportement strict de l’enum.

Point à surveiller : le test d’erreur JSON est volontairement ciblé par atome, pas exhaustif sur toutes les permutations possibles de types invalides. C’est suffisant pour V0, mais les codecs composite devront ajouter leurs propres tests de champs manquants et comportements null/empty.

## 21. Regard critique sur le prompt

Le prompt est bien borné : il sépare les codecs atomiques des codecs composite, ce qui évite de brancher trop tôt le manifest ou de réintroduire une V2 automatique. La seule tension pratique est l’exigence de `git diff --stat` alors que les fichiers nouveaux restent non trackés par règle Git ; le rapport compense avec un inventaire explicite et le `git status`.

## 22. Prochain lot recommandé

Prochain lot recommandé :

```text
ShadowV2-10 — Project Building Shadow Preset JSON Codec V0
```

Justification : les atomes ont maintenant des codecs stables. Le prochain incrément naturel est le codec de `ProjectBuildingShadowPreset`, sans encore créer le codec catalogue, sans config élément, sans manifest.

## Code complet des fichiers créés/modifiés

### `packages/map_core/lib/src/operations/projected_shadow_value_object_json_codecs.dart`

```dart
import '../exceptions/map_exceptions.dart';
import '../models/projected_building_shadow.dart';

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

double _requiredDouble(
  Map<String, Object?> json,
  String key,
  String fieldKey,
) {
  final value = _valueForRequiredKey(json, key, fieldKey);
  if (value is! num) {
    throw ValidationException('$fieldKey must be a num');
  }
  final result = value.toDouble();
  if (!result.isFinite) {
    throw ValidationException('$fieldKey must be finite');
  }
  return result;
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

/// Encodes the authored direction of a projected building shadow.
Map<String, dynamic> encodeProjectedShadowDirection(
  ProjectedShadowDirection direction,
) {
  return <String, dynamic>{
    'x': direction.x,
    'y': direction.y,
  };
}

/// Decodes the authored direction of a projected building shadow.
///
/// Unknown keys are ignored. Known keys keep strict numeric types.
ProjectedShadowDirection decodeProjectedShadowDirection(Object? json) {
  final map = _requiredObject(json, 'ProjectedShadowDirection');
  return ProjectedShadowDirection(
    x: _requiredDouble(map, 'x', 'ProjectedShadowDirection.x'),
    y: _requiredDouble(map, 'y', 'ProjectedShadowDirection.y'),
  );
}

/// Encodes the local asset anchor for a projected building shadow.
Map<String, dynamic> encodeProjectedShadowAnchor(
  ProjectedShadowAnchor anchor,
) {
  return <String, dynamic>{
    'xRatio': anchor.xRatio,
    'yRatio': anchor.yRatio,
  };
}

/// Decodes the local asset anchor for a projected building shadow.
///
/// Unknown keys are ignored. Known keys keep strict numeric types.
ProjectedShadowAnchor decodeProjectedShadowAnchor(Object? json) {
  final map = _requiredObject(json, 'ProjectedShadowAnchor');
  return ProjectedShadowAnchor(
    xRatio: _requiredDouble(map, 'xRatio', 'ProjectedShadowAnchor.xRatio'),
    yRatio: _requiredDouble(map, 'yRatio', 'ProjectedShadowAnchor.yRatio'),
  );
}

/// Encodes the local offset applied after anchor resolution.
Map<String, dynamic> encodeProjectedShadowOffset(
  ProjectedShadowOffset offset,
) {
  return <String, dynamic>{
    'x': offset.x,
    'y': offset.y,
  };
}

/// Decodes the local offset applied after anchor resolution.
///
/// Unknown keys are ignored. Known keys keep strict numeric types.
ProjectedShadowOffset decodeProjectedShadowOffset(Object? json) {
  final map = _requiredObject(json, 'ProjectedShadowOffset');
  return ProjectedShadowOffset(
    x: _requiredDouble(map, 'x', 'ProjectedShadowOffset.x'),
    y: _requiredDouble(map, 'y', 'ProjectedShadowOffset.y'),
  );
}

/// Encodes the parametric shape tuning for a projected building shadow.
Map<String, dynamic> encodeProjectedShadowShapeTuning(
  ProjectedShadowShapeTuning shape,
) {
  return <String, dynamic>{
    'lengthRatio': shape.lengthRatio,
    'nearWidthRatio': shape.nearWidthRatio,
    'farWidthRatio': shape.farWidthRatio,
  };
}

/// Decodes the parametric shape tuning for a projected building shadow.
///
/// Unknown keys are ignored. Known keys keep strict numeric types.
ProjectedShadowShapeTuning decodeProjectedShadowShapeTuning(Object? json) {
  final map = _requiredObject(json, 'ProjectedShadowShapeTuning');
  return ProjectedShadowShapeTuning(
    lengthRatio: _requiredDouble(
      map,
      'lengthRatio',
      'ProjectedShadowShapeTuning.lengthRatio',
    ),
    nearWidthRatio: _requiredDouble(
      map,
      'nearWidthRatio',
      'ProjectedShadowShapeTuning.nearWidthRatio',
    ),
    farWidthRatio: _requiredDouble(
      map,
      'farWidthRatio',
      'ProjectedShadowShapeTuning.farWidthRatio',
    ),
  );
}

/// Encodes the simple visual appearance of a projected building shadow.
Map<String, dynamic> encodeProjectedShadowAppearance(
  ProjectedShadowAppearance appearance,
) {
  return <String, dynamic>{
    'opacity': appearance.opacity,
    'colorHexRgb': appearance.colorHexRgb,
  };
}

/// Decodes the simple visual appearance of a projected building shadow.
///
/// Unknown keys are ignored. The value object normalizes color to uppercase.
ProjectedShadowAppearance decodeProjectedShadowAppearance(Object? json) {
  final map = _requiredObject(json, 'ProjectedShadowAppearance');
  return ProjectedShadowAppearance(
    opacity: _requiredDouble(
      map,
      'opacity',
      'ProjectedShadowAppearance.opacity',
    ),
    colorHexRgb: _requiredString(
      map,
      'colorHexRgb',
      'ProjectedShadowAppearance.colorHexRgb',
    ),
  );
}

/// Encodes the future time-of-day behavior flag.
String encodeProjectedShadowTimeOfDayMode(
  ProjectedShadowTimeOfDayMode mode,
) {
  return switch (mode) {
    ProjectedShadowTimeOfDayMode.fixed => 'fixed',
    ProjectedShadowTimeOfDayMode.followsSun => 'followsSun',
  };
}

/// Decodes the future time-of-day behavior flag.
///
/// Values are intentionally strict: no silent fallback and no case folding.
ProjectedShadowTimeOfDayMode decodeProjectedShadowTimeOfDayMode(Object? json) {
  if (json is! String) {
    throw ValidationException(
      'ProjectedShadowTimeOfDayMode must be a String, got ${json.runtimeType}',
    );
  }
  return switch (json) {
    'fixed' => ProjectedShadowTimeOfDayMode.fixed,
    'followsSun' => ProjectedShadowTimeOfDayMode.followsSun,
    _ => throw ValidationException(
        'ProjectedShadowTimeOfDayMode has unknown value "$json"',
      ),
  };
}
```

### `packages/map_core/test/shadow_v2/projected_shadow_value_object_json_codecs_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectedShadowDirection JSON codec', () {
    test('encodes the canonical x/y object', () {
      final direction = ProjectedShadowDirection(x: -0.55, y: 0.35);

      expect(
        encodeProjectedShadowDirection(direction),
        <String, Object?>{'x': -0.55, 'y': 0.35},
      );
    });

    test('decodes the canonical x/y object and ignores unknown keys', () {
      final direction = decodeProjectedShadowDirection(<String, Object?>{
        'x': -0.55,
        'y': 0.35,
        'debug': true,
      });

      expect(direction, ProjectedShadowDirection(x: -0.55, y: 0.35));
      expect(
        encodeProjectedShadowDirection(direction),
        <String, Object?>{'x': -0.55, 'y': 0.35},
      );
    });

    test('round-trips through the canonical object', () {
      final encoded = encodeProjectedShadowDirection(
        ProjectedShadowDirection(x: -0.55, y: 0.35),
      );

      expect(
        encodeProjectedShadowDirection(
          decodeProjectedShadowDirection(encoded),
        ),
        encoded,
      );
    });

    test('rejects invalid JSON shape and required fields', () {
      expect(
        () => decodeProjectedShadowDirection(null),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectedShadowDirection(<String, Object?>{'y': 0.35}),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectedShadowDirection(<String, Object?>{'x': -0.55}),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectedShadowDirection(<String, Object?>{
          'x': 'west',
          'y': 0.35,
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectedShadowDirection(<String, Object?>{'x': 0, 'y': 0}),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('ProjectedShadowAnchor JSON codec', () {
    test('encodes the canonical xRatio/yRatio object', () {
      final anchor = ProjectedShadowAnchor(xRatio: 0.5, yRatio: 0.98);

      expect(
        encodeProjectedShadowAnchor(anchor),
        <String, Object?>{'xRatio': 0.5, 'yRatio': 0.98},
      );
    });

    test('decodes the canonical ratio object and ignores unknown keys', () {
      final anchor = decodeProjectedShadowAnchor(<String, Object?>{
        'xRatio': 0.5,
        'yRatio': 0.98,
        'editorLabel': 'south door',
      });

      expect(anchor, ProjectedShadowAnchor(xRatio: 0.5, yRatio: 0.98));
      expect(
        encodeProjectedShadowAnchor(anchor),
        <String, Object?>{'xRatio': 0.5, 'yRatio': 0.98},
      );
    });

    test('round-trips through the canonical object', () {
      final encoded = encodeProjectedShadowAnchor(
        ProjectedShadowAnchor(xRatio: 0.5, yRatio: 0.98),
      );

      expect(
        encodeProjectedShadowAnchor(decodeProjectedShadowAnchor(encoded)),
        encoded,
      );
    });

    test('rejects missing fields and invalid ratios', () {
      expect(
        () => decodeProjectedShadowAnchor(<String, Object?>{'yRatio': 0.98}),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectedShadowAnchor(<String, Object?>{'xRatio': 0.5}),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectedShadowAnchor(<String, Object?>{
          'xRatio': 1.01,
          'yRatio': 0.98,
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectedShadowAnchor(<String, Object?>{
          'xRatio': 0.5,
          'yRatio': 'bottom',
        }),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('ProjectedShadowOffset JSON codec', () {
    test('encodes the canonical x/y object', () {
      final offset = ProjectedShadowOffset(x: 0, y: -2.5);

      expect(
        encodeProjectedShadowOffset(offset),
        <String, Object?>{'x': 0, 'y': -2.5},
      );
    });

    test(
        'decodes positive, zero, and negative offsets with unknown keys ignored',
        () {
      final offset = decodeProjectedShadowOffset(<String, Object?>{
        'x': 3.25,
        'y': -2.5,
        'note': 'local tweak',
      });

      expect(offset, ProjectedShadowOffset(x: 3.25, y: -2.5));
      expect(
        encodeProjectedShadowOffset(offset),
        <String, Object?>{'x': 3.25, 'y': -2.5},
      );
    });

    test('round-trips through the canonical object', () {
      final encoded = encodeProjectedShadowOffset(
        ProjectedShadowOffset(x: 0, y: -2.5),
      );

      expect(
        encodeProjectedShadowOffset(decodeProjectedShadowOffset(encoded)),
        encoded,
      );
    });

    test('rejects missing and non-numeric coordinates', () {
      expect(
        () => decodeProjectedShadowOffset(<String, Object?>{'y': -2.5}),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectedShadowOffset(<String, Object?>{'x': 0}),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectedShadowOffset(<String, Object?>{
          'x': 0,
          'y': double.infinity,
        }),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('ProjectedShadowShapeTuning JSON codec', () {
    test('encodes the canonical shape object', () {
      final shape = ProjectedShadowShapeTuning(
        lengthRatio: 0.28,
        nearWidthRatio: 0.85,
        farWidthRatio: 0.75,
      );

      expect(
        encodeProjectedShadowShapeTuning(shape),
        <String, Object?>{
          'lengthRatio': 0.28,
          'nearWidthRatio': 0.85,
          'farWidthRatio': 0.75,
        },
      );
    });

    test('decodes the canonical shape object and ignores unknown keys', () {
      final shape = decodeProjectedShadowShapeTuning(<String, Object?>{
        'lengthRatio': 0.28,
        'nearWidthRatio': 0.85,
        'farWidthRatio': 0.75,
        'legacyWidth': 12,
      });

      expect(
        shape,
        ProjectedShadowShapeTuning(
          lengthRatio: 0.28,
          nearWidthRatio: 0.85,
          farWidthRatio: 0.75,
        ),
      );
      expect(
        encodeProjectedShadowShapeTuning(shape),
        <String, Object?>{
          'lengthRatio': 0.28,
          'nearWidthRatio': 0.85,
          'farWidthRatio': 0.75,
        },
      );
    });

    test('round-trips through the canonical object', () {
      final encoded = encodeProjectedShadowShapeTuning(
        ProjectedShadowShapeTuning(
          lengthRatio: 0.28,
          nearWidthRatio: 0.85,
          farWidthRatio: 0.75,
        ),
      );

      expect(
        encodeProjectedShadowShapeTuning(
          decodeProjectedShadowShapeTuning(encoded),
        ),
        encoded,
      );
    });

    test('rejects missing fields and invalid ratios', () {
      expect(
        () => decodeProjectedShadowShapeTuning(<String, Object?>{
          'nearWidthRatio': 0.85,
          'farWidthRatio': 0.75,
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectedShadowShapeTuning(<String, Object?>{
          'lengthRatio': 0.28,
          'farWidthRatio': 0.75,
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectedShadowShapeTuning(<String, Object?>{
          'lengthRatio': 0.28,
          'nearWidthRatio': 0.85,
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectedShadowShapeTuning(<String, Object?>{
          'lengthRatio': -0.01,
          'nearWidthRatio': 0.85,
          'farWidthRatio': 0.75,
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectedShadowShapeTuning(<String, Object?>{
          'lengthRatio': 0.28,
          'nearWidthRatio': 0,
          'farWidthRatio': 0.75,
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectedShadowShapeTuning(<String, Object?>{
          'lengthRatio': 0.28,
          'nearWidthRatio': 0.85,
          'farWidthRatio': 'wide',
        }),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('ProjectedShadowAppearance JSON codec', () {
    test('encodes the canonical appearance object with uppercase color', () {
      final appearance = ProjectedShadowAppearance(
        opacity: 0.18,
        colorHexRgb: 'abcdef',
      );

      expect(
        encodeProjectedShadowAppearance(appearance),
        <String, Object?>{'opacity': 0.18, 'colorHexRgb': 'ABCDEF'},
      );
    });

    test('decodes the canonical appearance object and ignores unknown keys',
        () {
      final appearance = decodeProjectedShadowAppearance(<String, Object?>{
        'opacity': 0.18,
        'colorHexRgb': '000000',
        'debugColorName': 'soft black',
      });

      expect(
        appearance,
        ProjectedShadowAppearance(opacity: 0.18, colorHexRgb: '000000'),
      );
      expect(
        encodeProjectedShadowAppearance(appearance),
        <String, Object?>{'opacity': 0.18, 'colorHexRgb': '000000'},
      );
    });

    test('round-trips lowercase color as uppercase', () {
      final appearance = decodeProjectedShadowAppearance(<String, Object?>{
        'opacity': 0.18,
        'colorHexRgb': 'abcdef',
      });

      expect(appearance.colorHexRgb, 'ABCDEF');
      expect(
        encodeProjectedShadowAppearance(appearance),
        <String, Object?>{'opacity': 0.18, 'colorHexRgb': 'ABCDEF'},
      );
    });

    test('accepts opacity boundaries', () {
      expect(
        decodeProjectedShadowAppearance(<String, Object?>{
          'opacity': 0,
          'colorHexRgb': '000000',
        }).opacity,
        0,
      );
      expect(
        decodeProjectedShadowAppearance(<String, Object?>{
          'opacity': 1,
          'colorHexRgb': 'FFFFFF',
        }).opacity,
        1,
      );
    });

    test('rejects missing fields and invalid appearance values', () {
      expect(
        () => decodeProjectedShadowAppearance(<String, Object?>{
          'colorHexRgb': '000000',
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectedShadowAppearance(<String, Object?>{
          'opacity': 0.18,
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectedShadowAppearance(<String, Object?>{
          'opacity': -0.01,
          'colorHexRgb': '000000',
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectedShadowAppearance(<String, Object?>{
          'opacity': 1.01,
          'colorHexRgb': '000000',
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectedShadowAppearance(<String, Object?>{
          'opacity': 0.18,
          'colorHexRgb': '00000',
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectedShadowAppearance(<String, Object?>{
          'opacity': 0.18,
          'colorHexRgb': 0,
        }),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('ProjectedShadowTimeOfDayMode JSON codec', () {
    test('encodes fixed and followsSun', () {
      expect(
        encodeProjectedShadowTimeOfDayMode(ProjectedShadowTimeOfDayMode.fixed),
        'fixed',
      );
      expect(
        encodeProjectedShadowTimeOfDayMode(
          ProjectedShadowTimeOfDayMode.followsSun,
        ),
        'followsSun',
      );
    });

    test('decodes fixed and followsSun', () {
      expect(
        decodeProjectedShadowTimeOfDayMode('fixed'),
        ProjectedShadowTimeOfDayMode.fixed,
      );
      expect(
        decodeProjectedShadowTimeOfDayMode('followsSun'),
        ProjectedShadowTimeOfDayMode.followsSun,
      );
    });

    test('rejects unknown, non-string, and wrongly-cased values', () {
      expect(
        () => decodeProjectedShadowTimeOfDayMode('moonlight'),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectedShadowTimeOfDayMode(0),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectedShadowTimeOfDayMode('FollowsSun'),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
```

### `packages/map_core/lib/map_core.dart` diff

```diff
diff --git a/packages/map_core/lib/map_core.dart b/packages/map_core/lib/map_core.dart
index e70461e0..681099a3 100644
--- a/packages/map_core/lib/map_core.dart
+++ b/packages/map_core/lib/map_core.dart
@@ -47,6 +47,7 @@ export 'src/operations/project_manifest_shadow_catalog_operations.dart';
 export 'src/operations/project_path_pattern_preset_json_codec.dart';
 export 'src/operations/project_shadow_catalog_json_codec.dart';
 export 'src/operations/project_shadow_profile_json_codec.dart';
+export 'src/operations/projected_shadow_value_object_json_codecs.dart';
 export 'src/operations/static_shadow_family_json_codec.dart';
 export 'src/operations/static_shadow_footprint_config_json_codec.dart';
 export 'src/operations/project_json_migrations.dart';
```
