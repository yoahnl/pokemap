# ShadowV2-7 — Projected Building Shadow Element Config Model V0

## 1. Résumé exécutif

ShadowV2-7 ajoute le modèle domaine pur `ProjectElementProjectedBuildingShadowConfig`.

Le modèle stocke :

- `enabled` ;
- `presetId` ;
- `anchor` ;
- `localOffset`.

Il valide uniquement `presetId.trim().isNotEmpty`, conserve la valeur fournie si elle est valide, compose les value objects `ProjectedShadowAnchor` et `ProjectedShadowOffset`, et fournit une égalité de valeur sur tous les champs.

Aucun JSON, manifest, runtime, editor, resolver, override instance, preset par défaut ou fichier généré n'a été ajouté.

## 2. Objectif du lot

Créer la fiche élément V2 minimale :

```text
cet élément pointe vers ce preset d'ombre projetée, avec cet ancrage, cet offset, et cet état enabled.
```

Le modèle reste non branché à `ProjectElementEntry`.

## 3. Rappel ShadowV2-6

ShadowV2-6 a introduit `ProjectBuildingShadowPresetCatalog`, un catalogue pur, ordonné et immuable de `ProjectBuildingShadowPreset`.

ShadowV2-7 ajoute maintenant la configuration par élément, mais ne la connecte pas encore au catalogue, au manifest ou au JSON.

## 4. État initial du worktree

Commande :

```bash
cd /Users/karim/Project/pokemonProject
git status --short --untracked-files=all
```

Sortie initiale :

```text
```

Interprétation : worktree propre au début de ShadowV2-7.

## 5. Décision AGENTS / design gate

Commandes :

```bash
cd /Users/karim/Project/pokemonProject
find .. -name AGENTS.md -print
rg -n "Do not invoke implementation skills|design has been presented|creative|structural|architectural|product-facing" AGENTS.md
```

Sortie :

```text
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
765:Before structural changes, read the nearest:
848:1. Brainstorming (`superpowers:brainstorming`) before creative work.
1094:Do not invoke implementation skills, write code, scaffold a project, or take implementation action until a design has been presented and approved when the task is creative, structural, architectural, or product-facing.
1096:For creative work such as features, components, behavior changes, or UI:
```

Décision :

- ShadowV2-1 et ShadowV2-2 ont fourni le design produit / modèle.
- ShadowV2-3 a fourni la caractérisation JSON.
- ShadowV2-4 a introduit les value objects purs.
- ShadowV2-5 a introduit `ProjectBuildingShadowPreset`.
- ShadowV2-6 a introduit `ProjectBuildingShadowPresetCatalog`.
- ShadowV2-7 implémente uniquement la config élément pure.

Aucun nouveau design gate bloquant n'a été déclenché.

## 6. Fichiers créés / modifiés

Fichiers modifiés :

- `packages/map_core/lib/src/models/projected_building_shadow.dart`

Fichiers créés :

- `packages/map_core/test/shadow_v2/projected_building_shadow_element_config_test.dart`
- `reports/shadows/v2/shadow_v2_7_projected_building_shadow_element_config_model.md`

Fichiers supprimés :

- Aucun

Fichiers générés :

- Aucun

Fichiers Selbrume modifiés :

- Aucun

## 7. Modèle créé

Modèle ajouté :

```text
ProjectElementProjectedBuildingShadowConfig
```

Il vit dans :

```text
packages/map_core/lib/src/models/projected_building_shadow.dart
```

Le modèle est `@immutable`, final, pure Dart, sans JSON et sans dépendance runtime/editor.

## 8. Champs du modèle

Champs créés :

```dart
final bool enabled;
final String presetId;
final ProjectedShadowAnchor anchor;
final ProjectedShadowOffset localOffset;
```

Champs volontairement non ajoutés :

- `timeOfDayModeOverride`
- `appearanceOverride`
- `shapeOverride`
- `directionOverride`
- `assetRef`
- `shadowImagePath`
- `maskPath`
- `instanceOverride`
- debug flags
- editor-only state
- JSON fields

## 9. Validations

Validation ajoutée :

```text
presetId.trim().isNotEmpty
```

Si `presetId` est vide ou composé uniquement d'espaces :

```text
ArgumentError
```

Convention conservée :

- un `presetId` avec espaces autour est accepté ;
- la valeur fournie est stockée telle quelle ;
- le modèle ne normalise pas.

`anchor` et `localOffset` ne sont pas revalidés manuellement : leurs invariants sont déjà garantis par `ProjectedShadowAnchor` et `ProjectedShadowOffset`.

## 10. Égalité / hashCode

L'égalité inclut tous les champs :

- `enabled`
- `presetId`
- `anchor`
- `localOffset`

`hashCode` utilise :

```dart
Object.hash(enabled, presetId, anchor, localOffset)
```

## 11. Décision defaults

Aucun default/factory artistique n'a été créé.

Non créés :

- `ProjectElementProjectedBuildingShadowConfig.default()`
- `createDefaultProjectedBuildingShadowConfig()`
- presetId magique

Raison : les defaults artistiques et UX doivent être décidés plus tard dans un lot d'authoring/editor, pas imposés par le modèle pur.

## 12. Décision copyWith

`copyWith` n'a pas été ajouté.

Raison : ShadowV2-7 reste un modèle minimal. Les opérations d'édition viendront plus tard, probablement dans un lot d'opérations ou d'authoring.

## 13. Décision resolver

Aucun resolver n'a été créé.

Non créés :

- `resolvePreset(...)`
- diagnostics de preset manquant
- dépendance au `ProjectBuildingShadowPresetCatalog`

La config stocke seulement :

```text
enabled + presetId + anchor + localOffset
```

## 14. Séparation V1/V2

Le modèle ne dépend pas directement de :

- `ProjectElementShadowConfig`
- `MapPlacedElementShadowOverride`
- `StaticShadowFamily`
- `ShadowCasterMode`
- `ShadowRenderPass`

V2 reste donc séparée de V1. La coexistence V1/V2 sera décidée plus tard.

## 15. Tests ajoutés

Test créé :

```text
packages/map_core/test/shadow_v2/projected_building_shadow_element_config_test.dart
```

Comportements couverts :

- accepte `enabled: true` ;
- accepte `enabled: false` ;
- stocke `presetId` ;
- stocke `anchor` ;
- stocke `localOffset` ;
- refuse `presetId` vide ;
- refuse `presetId` espaces ;
- accepte et conserve `presetId` avec espaces autour ;
- compose anchor et offsets positifs/négatifs ;
- égalité de valeur ;
- `hashCode` cohérent ;
- différence sur `enabled` ;
- différence sur `presetId` ;
- différence sur `anchor` ;
- différence sur `localOffset`.

### RED TDD observé

Commande :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_core
dart format test/shadow_v2/projected_building_shadow_element_config_test.dart && dart test test/shadow_v2/projected_building_shadow_element_config_test.dart
```

Sortie RED :

```text
Formatted test/shadow_v2/projected_building_shadow_element_config_test.dart
Formatted 1 file (1 changed) in 0.01 seconds.
00:00 +0: loading test/shadow_v2/projected_building_shadow_element_config_test.dart
00:00 +0 -1: loading test/shadow_v2/projected_building_shadow_element_config_test.dart [E]
Failed to load "test/shadow_v2/projected_building_shadow_element_config_test.dart":
test/shadow_v2/projected_building_shadow_element_config_test.dart:101:1: Error: Type 'ProjectElementProjectedBuildingShadowConfig' not found.
ProjectElementProjectedBuildingShadowConfig _config({
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/shadow_v2/projected_building_shadow_element_config_test.dart:10:22: Error: Method not found: 'ProjectElementProjectedBuildingShadowConfig'.
      final config = ProjectElementProjectedBuildingShadowConfig(
                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/shadow_v2/projected_building_shadow_element_config_test.dart:107:10: Error: Method not found: 'ProjectElementProjectedBuildingShadowConfig'.
  return ProjectElementProjectedBuildingShadowConfig(
         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
To run this test again: dart test test/shadow_v2/projected_building_shadow_element_config_test.dart -p vm --plain-name 'loading test/shadow_v2/projected_building_shadow_element_config_test.dart'
00:00 +0 -1: Some tests failed.
```

Interprétation : le test échoue pour la bonne raison, le type n'existe pas encore.

## 16. Résultats des tests

### Test ciblé

Commande :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_core
dart format test/shadow_v2/projected_building_shadow_element_config_test.dart && dart test --reporter expanded --no-color test/shadow_v2/projected_building_shadow_element_config_test.dart
```

Sortie complète :

```text
Formatted 1 file (0 changed) in 0.01 seconds.
00:00 +0: loading test/shadow_v2/projected_building_shadow_element_config_test.dart
00:00 +0: ProjectElementProjectedBuildingShadowConfig accepts enabled true and stores all values
00:00 +1: ProjectElementProjectedBuildingShadowConfig accepts enabled false and preserves preset intent
00:00 +2: ProjectElementProjectedBuildingShadowConfig rejects blank preset ids
00:00 +3: ProjectElementProjectedBuildingShadowConfig stores spaced preset ids unchanged
00:00 +4: ProjectElementProjectedBuildingShadowConfig composes valid anchor and positive or negative offsets
00:00 +5: ProjectElementProjectedBuildingShadowConfig uses value equality and matching hashCode
00:00 +6: ProjectElementProjectedBuildingShadowConfig value equality includes enabled
00:00 +7: ProjectElementProjectedBuildingShadowConfig value equality includes presetId
00:00 +8: ProjectElementProjectedBuildingShadowConfig value equality includes anchor
00:00 +9: ProjectElementProjectedBuildingShadowConfig value equality includes localOffset
00:00 +10: All tests passed!
```

### Régression ShadowV2

Commande :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_core
dart test --no-color test/shadow_v2
```

Ligne finale exacte :

```text
00:00 +61: All tests passed!
```

### Régression Shadow V1

Commande :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_core
dart test --no-color test/shadow
```

Ligne finale exacte :

```text
00:00 +284: All tests passed!
```

## 17. Résultat analyze

Commande :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_core
dart analyze lib/src/models/projected_building_shadow.dart test/shadow_v2/projected_building_shadow_element_config_test.dart
```

Sortie complète :

```text
Analyzing projected_building_shadow.dart, projected_building_shadow_element_config_test.dart...
No issues found!
```

## 18. Export public

Vérification :

```bash
cd /Users/karim/Project/pokemonProject
rg -n "projected_building_shadow" packages/map_core/lib/map_core.dart
git diff -- packages/map_core/lib/map_core.dart
```

Sortie :

```text
31:export 'src/models/projected_building_shadow.dart';
```

Conclusion :

- export déjà présent : oui ;
- export ajouté dans ce lot : non ;
- `map_core.dart` non modifié.

## 19. Ce qui n'a volontairement pas été créé

Non créés :

- `ProjectElementEntry` integration
- `ProjectBuildingShadowPresetCatalog` integration
- JSON codecs
- resolver
- runtime/editor
- defaults
- override instance
- migrations
- fichiers generated

Vérification absence JSON / generated :

```bash
cd /Users/karim/Project/pokemonProject
rg -n "ProjectElementProjectedBuildingShadowConfig|ProjectElementEntry|ProjectManifest|MapPlacedElement|ProjectElementShadowConfig|MapPlacedElementShadowOverride|toJson|fromJson|JsonSerializable|freezed|g\\.dart|resolvePreset|default\\(" packages/map_core/lib/src/models/projected_building_shadow.dart packages/map_core/test/shadow_v2/projected_building_shadow_element_config_test.dart || true
find packages/map_core/lib/src/models -maxdepth 1 \( -name 'projected_building_shadow.g.dart' -o -name 'projected_building_shadow.freezed.dart' \) -print
```

Sortie utile :

```text
packages/map_core/test/shadow_v2/projected_building_shadow_element_config_test.dart:5:  group('ProjectElementProjectedBuildingShadowConfig', () {
packages/map_core/test/shadow_v2/projected_building_shadow_element_config_test.dart:10:      final config = ProjectElementProjectedBuildingShadowConfig(
packages/map_core/test/shadow_v2/projected_building_shadow_element_config_test.dart:101:ProjectElementProjectedBuildingShadowConfig _config({
packages/map_core/test/shadow_v2/projected_building_shadow_element_config_test.dart:107:  return ProjectElementProjectedBuildingShadowConfig(
packages/map_core/lib/src/models/projected_building_shadow.dart:370:/// ProjectElementEntry, JSON, manifests, runtime resolution, or editor UI.
packages/map_core/lib/src/models/projected_building_shadow.dart:372:final class ProjectElementProjectedBuildingShadowConfig {
packages/map_core/lib/src/models/projected_building_shadow.dart:373:  factory ProjectElementProjectedBuildingShadowConfig({
packages/map_core/lib/src/models/projected_building_shadow.dart:381:      'ProjectElementProjectedBuildingShadowConfig.presetId',
packages/map_core/lib/src/models/projected_building_shadow.dart:383:    return ProjectElementProjectedBuildingShadowConfig._(
packages/map_core/lib/src/models/projected_building_shadow.dart:391:  const ProjectElementProjectedBuildingShadowConfig._({
packages/map_core/lib/src/models/projected_building_shadow.dart:406:      other is ProjectElementProjectedBuildingShadowConfig &&
```

Le `find` generated n'a produit aucune sortie.

## 20. git diff --stat

Commande :

```bash
cd /Users/karim/Project/pokemonProject
git diff --stat
```

Sortie :

```text
 .../lib/src/models/projected_building_shadow.dart  | 54 ++++++++++++++++++++++
 1 file changed, 54 insertions(+)
```

Note : les fichiers non suivis sont listés dans `git status final`.

## 21. git diff --name-status

Commande :

```bash
cd /Users/karim/Project/pokemonProject
git diff --name-status
```

Sortie :

```text
M	packages/map_core/lib/src/models/projected_building_shadow.dart
```

## 22. git diff --check

Commande :

```bash
cd /Users/karim/Project/pokemonProject
git diff --check
```

Sortie :

```text
```

## 23. git status final

Commande :

```bash
cd /Users/karim/Project/pokemonProject
git status --short --untracked-files=all
```

Sortie finale :

```text
 M packages/map_core/lib/src/models/projected_building_shadow.dart
?? packages/map_core/test/shadow_v2/projected_building_shadow_element_config_test.dart
?? reports/shadows/v2/shadow_v2_7_projected_building_shadow_element_config_model.md
```

## 24. Risques / réserves

- Le modèle référence un `presetId` sous forme de chaîne, mais aucun diagnostic de preset manquant n'existe encore. C'est volontaire : les diagnostics viendront quand la config sera branchée au catalogue.
- `enabled: false` conserve un `presetId`; cela préserve l'intention d'authoring future, mais le comportement exact côté editor devra être conçu.
- Le modèle n'étant pas encore dans `ProjectElementEntry`, aucun projet existant ne peut l'utiliser pour l'instant.

## 25. Auto-critique

Le lot reste borné : une seule classe de production, un seul fichier de test, aucun export modifié. Le choix de ne pas ajouter `copyWith`, defaults ou resolver évite d'inventer des besoins UX avant le prochain design.

Le commentaire de classe mentionne explicitement l'absence d'intégration à `ProjectElementEntry`, JSON, manifest, runtime et editor, ce qui rend le statut non branché lisible directement dans le code.

## 26. Regard critique sur le prompt

Le prompt est très utile parce qu'il interdit explicitement les zones dangereuses : intégration élément, JSON, resolver et runtime/editor. Le risque principal aurait été de vouloir "aider" en branchant la config au catalogue ; le prompt évite cette dérive.

La prochaine étape devra garder la même progression : soit un lot de design/diagnostics avant branchement, soit une intégration manifest/JSON très caractérisée.

## 27. Prochain lot recommandé

Prochain lot recommandé :

```text
ShadowV2-8 — Projected Building Shadow Element Config JSON Design / Compatibility Gate
```

Objectif proposé : concevoir précisément comment ajouter `ProjectElementProjectedBuildingShadowConfig` à `ProjectElementEntry` et au JSON sans casser la compatibilité V1, avant de modifier le manifest ou les codecs.

## Code complet des fichiers créés/modifiés

### packages/map_core/lib/src/models/projected_building_shadow.dart

```dart
import 'dart:math' as math;

import 'package:meta/meta.dart' show immutable;

import '../exceptions/map_exceptions.dart';

/// Minimal placeholder for future time-aware projected building shadows.
///
/// ShadowV2-4 only models the authoring intent. It does not interpolate light,
/// inspect the clock, or affect runtime rendering.
enum ProjectedShadowTimeOfDayMode {
  fixed,
  followsSun,
}

/// Authored 2D direction for a future projected building shadow.
///
/// The raw values are intentionally preserved so the editor can keep the
/// author's intent. Consumers that need a unit vector can use [normalized].
@immutable
final class ProjectedShadowDirection {
  factory ProjectedShadowDirection({
    required double x,
    required double y,
  }) {
    _validateFinite(x, 'ProjectedShadowDirection.x');
    _validateFinite(y, 'ProjectedShadowDirection.y');
    if (x == 0 && y == 0) {
      throw const ValidationException(
        'ProjectedShadowDirection must not be the zero vector',
      );
    }
    return ProjectedShadowDirection._(x: x, y: y);
  }

  const ProjectedShadowDirection._({
    required this.x,
    required this.y,
  });

  final double x;
  final double y;

  double get magnitude => math.sqrt(x * x + y * y);

  ProjectedShadowDirection get normalized {
    final length = magnitude;
    return ProjectedShadowDirection(x: x / length, y: y / length);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectedShadowDirection && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}

/// Local anchor on the source building asset, expressed as normalized ratios.
@immutable
final class ProjectedShadowAnchor {
  factory ProjectedShadowAnchor({
    required double xRatio,
    required double yRatio,
  }) {
    _validateRatio01(xRatio, 'ProjectedShadowAnchor.xRatio');
    _validateRatio01(yRatio, 'ProjectedShadowAnchor.yRatio');
    return ProjectedShadowAnchor._(xRatio: xRatio, yRatio: yRatio);
  }

  const ProjectedShadowAnchor._({
    required this.xRatio,
    required this.yRatio,
  });

  final double xRatio;
  final double yRatio;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectedShadowAnchor &&
          other.xRatio == xRatio &&
          other.yRatio == yRatio;

  @override
  int get hashCode => Object.hash(xRatio, yRatio);
}

/// Local authored offset applied after the anchor is resolved.
@immutable
final class ProjectedShadowOffset {
  factory ProjectedShadowOffset({
    required double x,
    required double y,
  }) {
    _validateFinite(x, 'ProjectedShadowOffset.x');
    _validateFinite(y, 'ProjectedShadowOffset.y');
    return ProjectedShadowOffset._(x: x, y: y);
  }

  const ProjectedShadowOffset._({
    required this.x,
    required this.y,
  });

  final double x;
  final double y;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectedShadowOffset && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}

/// Parametric shape tuning for a simple projected building shadow.
@immutable
final class ProjectedShadowShapeTuning {
  factory ProjectedShadowShapeTuning({
    required double lengthRatio,
    required double nearWidthRatio,
    required double farWidthRatio,
  }) {
    _validateNonNegativeFinite(
      lengthRatio,
      'ProjectedShadowShapeTuning.lengthRatio',
    );
    _validatePositiveFinite(
      nearWidthRatio,
      'ProjectedShadowShapeTuning.nearWidthRatio',
    );
    _validatePositiveFinite(
      farWidthRatio,
      'ProjectedShadowShapeTuning.farWidthRatio',
    );
    return ProjectedShadowShapeTuning._(
      lengthRatio: lengthRatio,
      nearWidthRatio: nearWidthRatio,
      farWidthRatio: farWidthRatio,
    );
  }

  const ProjectedShadowShapeTuning._({
    required this.lengthRatio,
    required this.nearWidthRatio,
    required this.farWidthRatio,
  });

  final double lengthRatio;
  final double nearWidthRatio;
  final double farWidthRatio;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectedShadowShapeTuning &&
          other.lengthRatio == lengthRatio &&
          other.nearWidthRatio == nearWidthRatio &&
          other.farWidthRatio == farWidthRatio;

  @override
  int get hashCode => Object.hash(
        lengthRatio,
        nearWidthRatio,
        farWidthRatio,
      );
}

/// Simple visual appearance for a future projected building shadow.
@immutable
final class ProjectedShadowAppearance {
  factory ProjectedShadowAppearance({
    double opacity = 0.18,
    String colorHexRgb = '000000',
  }) {
    _validateOpacity(opacity, 'ProjectedShadowAppearance.opacity');
    return ProjectedShadowAppearance._(
      opacity: opacity,
      colorHexRgb: _normalizeColorHexRgb(colorHexRgb),
    );
  }

  const ProjectedShadowAppearance._({
    required this.opacity,
    required this.colorHexRgb,
  });

  final double opacity;
  final String colorHexRgb;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectedShadowAppearance &&
          other.opacity == opacity &&
          other.colorHexRgb == colorHexRgb;

  @override
  int get hashCode => Object.hash(opacity, colorHexRgb);
}

/// Reusable parametric preset for a future authored building shadow.
///
/// This model is intentionally not connected to JSON, manifests, runtime
/// resolution, or editor UI in ShadowV2-5.
@immutable
final class ProjectBuildingShadowPreset {
  factory ProjectBuildingShadowPreset({
    required String id,
    required String name,
    required ProjectedShadowDirection direction,
    required ProjectedShadowShapeTuning shape,
    required ProjectedShadowAppearance appearance,
    required ProjectedShadowTimeOfDayMode timeOfDayMode,
    String? categoryId,
    int sortOrder = 0,
  }) {
    _validateNonBlank(id, 'ProjectBuildingShadowPreset.id');
    _validateNonBlank(name, 'ProjectBuildingShadowPreset.name');
    final category = categoryId;
    if (category != null) {
      _validateNonBlank(category, 'ProjectBuildingShadowPreset.categoryId');
    }
    return ProjectBuildingShadowPreset._(
      id: id,
      name: name,
      direction: direction,
      shape: shape,
      appearance: appearance,
      timeOfDayMode: timeOfDayMode,
      categoryId: categoryId,
      sortOrder: sortOrder,
    );
  }

  const ProjectBuildingShadowPreset._({
    required this.id,
    required this.name,
    required this.direction,
    required this.shape,
    required this.appearance,
    required this.timeOfDayMode,
    required this.categoryId,
    required this.sortOrder,
  });

  final String id;
  final String name;
  final ProjectedShadowDirection direction;
  final ProjectedShadowShapeTuning shape;
  final ProjectedShadowAppearance appearance;
  final ProjectedShadowTimeOfDayMode timeOfDayMode;
  final String? categoryId;
  final int sortOrder;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectBuildingShadowPreset &&
          other.id == id &&
          other.name == name &&
          other.direction == direction &&
          other.shape == shape &&
          other.appearance == appearance &&
          other.timeOfDayMode == timeOfDayMode &&
          other.categoryId == categoryId &&
          other.sortOrder == sortOrder;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        direction,
        shape,
        appearance,
        timeOfDayMode,
        categoryId,
        sortOrder,
      );
}

/// Ordered in-memory catalog of future projected building shadow presets.
///
/// ShadowV2-6 keeps this as a pure domain collection. It has no JSON shape,
/// manifest integration, default presets, editor behavior, or runtime behavior.
@immutable
final class ProjectBuildingShadowPresetCatalog {
  ProjectBuildingShadowPresetCatalog({
    List<ProjectBuildingShadowPreset> presets = const [],
  }) : _presets = _copyBuildingShadowPresets(presets);

  final List<ProjectBuildingShadowPreset> _presets;

  /// Presets in authored order. The returned list is unmodifiable.
  List<ProjectBuildingShadowPreset> get presets => _presets;

  int get length => _presets.length;

  bool get isEmpty => _presets.isEmpty;

  bool get isNotEmpty => !isEmpty;

  /// Exact, case-sensitive lookup by [ProjectBuildingShadowPreset.id].
  ProjectBuildingShadowPreset? presetById(String id) {
    for (final preset in _presets) {
      if (preset.id == id) {
        return preset;
      }
    }
    return null;
  }

  bool containsPresetId(String id) => presetById(id) != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectBuildingShadowPresetCatalog &&
          _projectBuildingShadowPresetsEqualInOrder(_presets, other._presets);

  @override
  int get hashCode => Object.hashAll(_presets);
}

List<ProjectBuildingShadowPreset> _copyBuildingShadowPresets(
  List<ProjectBuildingShadowPreset> presets,
) {
  final copiedPresets = List<ProjectBuildingShadowPreset>.from(presets);
  _rejectDuplicateBuildingShadowPresetIds(copiedPresets);
  return List<ProjectBuildingShadowPreset>.unmodifiable(copiedPresets);
}

void _rejectDuplicateBuildingShadowPresetIds(
  List<ProjectBuildingShadowPreset> presets,
) {
  final seen = <String>{};
  for (final preset in presets) {
    if (!seen.add(preset.id)) {
      throw ArgumentError.value(
        preset.id,
        'presets',
        'ProjectBuildingShadowPresetCatalog.presets must not contain duplicate ProjectBuildingShadowPreset.id',
      );
    }
  }
}

bool _projectBuildingShadowPresetsEqualInOrder(
  List<ProjectBuildingShadowPreset> a,
  List<ProjectBuildingShadowPreset> b,
) {
  if (a.length != b.length) {
    return false;
  }
  for (var index = 0; index < a.length; index += 1) {
    if (a[index] != b[index]) {
      return false;
    }
  }
  return true;
}

/// Element-level opt-in config for a future projected building shadow.
///
/// ShadowV2-7 keeps this as a pure domain value. It is not attached to
/// ProjectElementEntry, JSON, manifests, runtime resolution, or editor UI.
@immutable
final class ProjectElementProjectedBuildingShadowConfig {
  factory ProjectElementProjectedBuildingShadowConfig({
    required bool enabled,
    required String presetId,
    required ProjectedShadowAnchor anchor,
    required ProjectedShadowOffset localOffset,
  }) {
    _validateNonBlank(
      presetId,
      'ProjectElementProjectedBuildingShadowConfig.presetId',
    );
    return ProjectElementProjectedBuildingShadowConfig._(
      enabled: enabled,
      presetId: presetId,
      anchor: anchor,
      localOffset: localOffset,
    );
  }

  const ProjectElementProjectedBuildingShadowConfig._({
    required this.enabled,
    required this.presetId,
    required this.anchor,
    required this.localOffset,
  });

  final bool enabled;
  final String presetId;
  final ProjectedShadowAnchor anchor;
  final ProjectedShadowOffset localOffset;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectElementProjectedBuildingShadowConfig &&
          other.enabled == enabled &&
          other.presetId == presetId &&
          other.anchor == anchor &&
          other.localOffset == localOffset;

  @override
  int get hashCode => Object.hash(
        enabled,
        presetId,
        anchor,
        localOffset,
      );
}

void _validateNonBlank(String value, String name) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, name, '$name must be non-empty');
  }
}

void _validateFinite(double value, String name) {
  if (!value.isFinite) {
    throw ValidationException('$name must be finite');
  }
}

void _validateRatio01(double value, String name) {
  _validateFinite(value, name);
  if (value < 0 || value > 1) {
    throw ValidationException('$name must be between 0 and 1');
  }
}

void _validateNonNegativeFinite(double value, String name) {
  _validateFinite(value, name);
  if (value < 0) {
    throw ValidationException('$name must be >= 0');
  }
}

void _validatePositiveFinite(double value, String name) {
  _validateFinite(value, name);
  if (value <= 0) {
    throw ValidationException('$name must be > 0');
  }
}

void _validateOpacity(double value, String name) {
  _validateRatio01(value, name);
}

String _normalizeColorHexRgb(String value) {
  if (value.length != 6 || !_isHexRgb(value)) {
    throw ValidationException(
      'ProjectedShadowAppearance.colorHexRgb must contain exactly '
      '6 hexadecimal RGB characters without #',
    );
  }
  return value.toUpperCase();
}

bool _isHexRgb(String value) {
  for (var index = 0; index < value.length; index += 1) {
    final codeUnit = value.codeUnitAt(index);
    final isDigit = codeUnit >= 0x30 && codeUnit <= 0x39;
    final isUppercaseHex = codeUnit >= 0x41 && codeUnit <= 0x46;
    final isLowercaseHex = codeUnit >= 0x61 && codeUnit <= 0x66;
    if (!isDigit && !isUppercaseHex && !isLowercaseHex) {
      return false;
    }
  }
  return true;
}
```

### packages/map_core/test/shadow_v2/projected_building_shadow_element_config_test.dart

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectElementProjectedBuildingShadowConfig', () {
    test('accepts enabled true and stores all values', () {
      final anchor = ProjectedShadowAnchor(xRatio: 0.5, yRatio: 0.98);
      final offset = ProjectedShadowOffset(x: 4, y: -2);

      final config = ProjectElementProjectedBuildingShadowConfig(
        enabled: true,
        presetId: 'short-west',
        anchor: anchor,
        localOffset: offset,
      );

      expect(config.enabled, isTrue);
      expect(config.presetId, 'short-west');
      expect(config.anchor, same(anchor));
      expect(config.localOffset, same(offset));
    });

    test('accepts enabled false and preserves preset intent', () {
      final config = _config(enabled: false);

      expect(config.enabled, isFalse);
      expect(config.presetId, 'short-west');
    });

    test('rejects blank preset ids', () {
      expect(
        () => _config(presetId: ''),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => _config(presetId: '   '),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('stores spaced preset ids unchanged', () {
      final config = _config(presetId: ' short-west ');

      expect(config.presetId, ' short-west ');
    });

    test('composes valid anchor and positive or negative offsets', () {
      final positiveOffset = _config(
        anchor: ProjectedShadowAnchor(xRatio: 0, yRatio: 1),
        localOffset: ProjectedShadowOffset(x: 12, y: 6),
      );
      final negativeOffset = _config(
        anchor: ProjectedShadowAnchor(xRatio: 1, yRatio: 0),
        localOffset: ProjectedShadowOffset(x: -12, y: -6),
      );

      expect(positiveOffset.anchor.xRatio, 0);
      expect(positiveOffset.anchor.yRatio, 1);
      expect(positiveOffset.localOffset.x, 12);
      expect(positiveOffset.localOffset.y, 6);
      expect(negativeOffset.anchor.xRatio, 1);
      expect(negativeOffset.anchor.yRatio, 0);
      expect(negativeOffset.localOffset.x, -12);
      expect(negativeOffset.localOffset.y, -6);
    });

    test('uses value equality and matching hashCode', () {
      final a = _config();
      final b = _config();

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('value equality includes enabled', () {
      expect(_config(enabled: true), isNot(_config(enabled: false)));
    });

    test('value equality includes presetId', () {
      expect(
        _config(presetId: 'short-west'),
        isNot(_config(presetId: 'long-east')),
      );
    });

    test('value equality includes anchor', () {
      expect(
        _config(anchor: ProjectedShadowAnchor(xRatio: 0.5, yRatio: 0.98)),
        isNot(_config(anchor: ProjectedShadowAnchor(xRatio: 0.5, yRatio: 0.9))),
      );
    });

    test('value equality includes localOffset', () {
      expect(
        _config(localOffset: ProjectedShadowOffset(x: 0, y: 0)),
        isNot(_config(localOffset: ProjectedShadowOffset(x: 1, y: 0))),
      );
    });
  });
}

ProjectElementProjectedBuildingShadowConfig _config({
  bool enabled = true,
  String presetId = 'short-west',
  ProjectedShadowAnchor? anchor,
  ProjectedShadowOffset? localOffset,
}) {
  return ProjectElementProjectedBuildingShadowConfig(
    enabled: enabled,
    presetId: presetId,
    anchor: anchor ?? ProjectedShadowAnchor(xRatio: 0.5, yRatio: 0.98),
    localOffset: localOffset ?? ProjectedShadowOffset(x: 0, y: 0),
  );
}
```
