# Shadow-50 — Selbrume Static Shadow Visual Calibration V0

## 1. Resume Du Lot

Shadow-50 calibre les ombres statiques automatiques de Selbrume dans `map_core` uniquement. Le lot resserre les specs de projection par famille, reclassifie les proportions Selbrume problematiques, et remplace les anciennes configs auto larges qui ressemblaient a des reglages manuels mais etaient en pratique la source des grandes dalles visibles.

Resultat attendu: les maisons, lampadaires et elements larges ne doivent plus repartir avec les anciennes ombres diagonales massives lorsque la politique automatique est appliquee.

## 2. Root Cause Selbrume

Audit du projet local `/Users/karim/Desktop/selbrume/project.json`: plusieurs elements avaient des shadows stockees de type large legacy:

```text
castsShadow: true
shadowProfileId: default-ground-wide-ellipse
scaleX: 1.0
scaleY: 0.85
opacity: 0.3
family: null ou building
footprint: anchorX 0.5, anchorY 0.92, width 0.82, height 0.12
```

Avant ce lot, `_isRecognizedAutoShadow(...)` ne reconnaissait pas cette forme. La backfill conservait donc ces configs comme `skippedManual`, et le runtime continuait de rendre les anciennes grandes ombres.

## 3. Files Created

```text
reports/shadows/shadow_lot_50_selbrume_visual_calibration.md
```

## 4. Files Modified By Shadow-50

```text
packages/map_core/lib/src/operations/static_shadow_family_projection.dart
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart
packages/map_core/test/shadow/static_shadow_family_projection_test.dart
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart
```

## 5. Pre-Existing / Out-Of-Scope Files

Untracked pre-existing plan file:

```text
reports/shadows/shadow_lot_50_selbrume_visual_calibration_plan.md
```

Out-of-scope tracked files present in final status:

```text
packages/map_battle/lib/src/application/battle_turn_runner.dart
packages/map_battle/lib/src/data/static_basic_move_registry.dart
packages/map_battle/lib/src/domain/move/battle_move_behavior.dart
packages/map_battle/lib/src/psdk/application/psdk_battle_move_behavior.dart
packages/map_battle/test/psdk_move_families/copy_call_move_behavior_test.dart
```

Out-of-scope untracked files present in final status:

```text
Aucun
```

Note: the workspace changed during final scans. These `map_battle` files are out-of-scope for Shadow-50 and were not staged or committed by this lot.

## 6. Family Projection V1 Values

```text
compactProp: length 0.0704, near 0.3312, far 0.2832
tallProp:    length 0.0704, near 0.2208, far 0.1770
building:    length 0.0832, near 0.4416, far 0.3422
foliage:     length 0.0960, near 0.5060, far 0.4720
```

The implementation still preserves custom base direction and scales custom base values proportionally.

## 7. Auto Policy V1 Values

```text
tallThin:
  profile default-ground-contact-blob
  scaleX 0.80
  scaleY 0.55
  opacity 0.20
  family tallProp
  footprint 0.5 / 1.0 / 0.28 / 0.05

buildingLarge:
  profile default-ground-wide-ellipse
  scaleX 0.72
  scaleY 0.48
  opacity 0.20
  family building
  footprint 0.5 / 0.98 / 0.60 / 0.06

wideLow:
  profile default-ground-wide-ellipse
  scaleX 0.74
  scaleY 0.50
  opacity 0.20
  family compactProp
  footprint 0.5 / 0.98 / 0.58 / 0.06
```

## 8. Legacy Broad Config Replacement

`_isLegacyBroadSelbrumeAutoShadow(...)` recognizes only the exact old broad generated shape: default wide profile, zero offset, `scaleX: 1`, `scaleY: 0.85`, `opacity: 0.30`, old footprint `0.5 / 0.92 / 0.82 / 0.12`, and family `null`, `building`, or `compactProp`.

This is intentionally strict: custom profile ids, custom offsets, custom scales, custom opacity, or non-matching footprints remain protected as manual.

## 9. Classification Changes

```text
3x5 lamp-like elements -> tallThin
very wide low elements with width >= 4, height <= 6, width/height >= 2 -> wideLow
large remaining elements -> buildingLarge
```

This specifically fixes the Selbrume lampadaire shape and the wide barrier shape that were previously classified as `buildingLarge`.

## 10. Why Runtime / Editor Were Not Modified

The runtime and editor already consume `ProjectElementShadowConfig.family`, `footprint`, and `resolveStaticShadowFamilyProjectionSpec(...)`. Shadow-50 changes only the pure `map_core` policy and projection constants; no Flame component, renderer, canvas painter, editor UI, persistent model, or JSON codec was needed.

## 11. Tests Added / Modified

```text
static_shadow_family_projection_test.dart:
- V1 constant tests for compactProp, tallProp, building, foliage.
- Selbrume house compactness test.
- V1 projected area < 30% of legacy Selbrume slab test.

element_auto_shadow_policy_test.dart:
- 3x5 lamp produces tallThin/tallProp V1 config.
- 13x6 barrier produces wideLow/compactProp V1 config.
- 6x7 house produces building V1 config.
- V1 building auto config projected area < 30% of legacy broad config.
- backfill replaces legacy broad shadow without family.
- backfill replaces legacy broad shadow with building family.
```

## 12. Commands Run

```bash
cd /Users/karim/Project/pokemonProject
sed -n '1,260p' reports/shadows/shadow_lot_50_selbrume_visual_calibration_plan.md
sed -n '260,620p' reports/shadows/shadow_lot_50_selbrume_visual_calibration_plan.md
sed -n '620,980p' reports/shadows/shadow_lot_50_selbrume_visual_calibration_plan.md
cd packages/map_core && dart test test/shadow/static_shadow_family_projection_test.dart
cd packages/map_core && dart test test/shadow/element_auto_shadow_policy_test.dart
cd packages/map_core && dart format lib/src/operations/static_shadow_family_projection.dart test/shadow/static_shadow_family_projection_test.dart test/shadow/element_auto_shadow_policy_test.dart lib/src/operations/element_auto_shadow_policy.dart
cd packages/map_core && dart test test/shadow
cd packages/map_core && dart analyze lib test/shadow
cd packages/map_runtime && flutter test test/shadow/runtime_static_placed_element_shadow_collection_test.dart
cd packages/map_runtime && flutter test test/shadow/shadow_runtime_renderer_test.dart
git diff --name-only | rg -n "packages/map_runtime/lib|packages/map_editor/lib|packages/map_gameplay|packages/map_battle"
git diff --name-only | rg -n "packages/map_core/lib/src/models|project_element_shadow_config_json_codec|map_placed_element_shadow_override_json_codec|static_shadow_footprint_config_json_codec|\.g\.dart|\.freezed\.dart"
git diff -U0 -- packages/map_core | rg -n "Canvas|Flame|saveLayer|ImageFilter|runtimeBlur|WorldLightState|ShadowLightProfile|LightDirection|timeOfDay|zOrder|zIndex|drawAtlas"
git diff --check
git status --short --branch --untracked-files=all
git diff --stat
git diff --name-status
find .. -name AGENTS.md -print
```

## 13. RED Outputs

Family projection RED:

```text
Expected: a numeric value within <1e-7> of <0.0704>
Actual: <0.1216>
Which: differs by <0.051199999999999996>

Expected: a numeric value within <1e-7> of <0.0704>
Actual: <0.1536>
Which: differs by <0.08319999999999998>

Expected: a numeric value within <1e-7> of <0.0832>
Actual: <0.1984>
Which: differs by <0.1152>

Expected: a numeric value within <1e-7> of <0.096>
Actual: <0.14400000000000002>
Which: differs by <0.048000000000000015>

Expected: a value less than <20>
Actual: <44.4416>
```

Auto policy RED:

```text
Expected: ElementAutoShadowSuggestionKind:<ElementAutoShadowSuggestionKind.tallThin>
Actual: ElementAutoShadowSuggestionKind:<ElementAutoShadowSuggestionKind.buildingLarge>

Expected: ElementAutoShadowSuggestionKind:<ElementAutoShadowSuggestionKind.wideLow>
Actual: ElementAutoShadowSuggestionKind:<ElementAutoShadowSuggestionKind.buildingLarge>

Expected: a numeric value within <1e-7> of <0.72>
Actual: <1.0>

Expected: <1>
Actual: <0>
```

Area test debugging RED:

```text
Expected: a value less than <344.97128300544074>
Actual: <605.8032286924808>
```

Root cause: the test compared the legacy broad config through the already-calibrated V1 family resolver. The fixed test now uses the explicit legacy building projection spec values `0.1984 / 0.7176 / 0.7316`.

## 14. GREEN Outputs

```text
cd packages/map_core && dart test test/shadow/static_shadow_family_projection_test.dart
00:00 +18: All tests passed!
```

```text
cd packages/map_core && dart test test/shadow/element_auto_shadow_policy_test.dart
00:00 +12: All tests passed!
```

## 15. Regression Outputs

```text
cd packages/map_core && dart test test/shadow
00:00 +273: All tests passed!
```

```text
cd packages/map_core && dart analyze lib test/shadow
Analyzing lib, shadow...
No issues found!
```

Optional runtime safety checks:

```text
cd packages/map_runtime && flutter test test/shadow/runtime_static_placed_element_shadow_collection_test.dart
00:00 +24: All tests passed!
```

```text
cd packages/map_runtime && flutter test test/shadow/shadow_runtime_renderer_test.dart
00:00 +17: All tests passed!
```

## 16. Anti-Drift Scans

```text
git diff --name-only | rg -n "packages/map_runtime/lib|packages/map_editor/lib|packages/map_gameplay|packages/map_battle"
1:packages/map_battle/lib/src/application/battle_turn_runner.dart
2:packages/map_battle/lib/src/data/static_basic_move_registry.dart
3:packages/map_battle/lib/src/domain/move/battle_move_behavior.dart
4:packages/map_battle/lib/src/psdk/application/psdk_battle_move_behavior.dart
5:packages/map_battle/test/psdk_move_families/copy_call_move_behavior_test.dart
```

This output is out-of-scope and unrelated to Shadow-50. No runtime/editor/gameplay production files were reported.

```text
git diff --name-only | rg -n "packages/map_core/lib/src/models|project_element_shadow_config_json_codec|map_placed_element_shadow_override_json_codec|static_shadow_footprint_config_json_codec|\.g\.dart|\.freezed\.dart"
```

No output.

```text
git diff -U0 -- packages/map_core | rg -n "Canvas|Flame|saveLayer|ImageFilter|runtimeBlur|WorldLightState|ShadowLightProfile|LightDirection|timeOfDay|zOrder|zIndex|drawAtlas"
```

No output.

```text
git diff --check
```

No output.

## 17. Git Status Initial / Final

Initial status observed at implementation resume:

```text
 M packages/map_core/test/shadow/static_shadow_family_projection_test.dart
?? reports/shadows/shadow_lot_50_selbrume_visual_calibration_plan.md
```

Final status:

```text
## main...origin/main [ahead 6]
 M packages/map_battle/lib/src/application/battle_turn_runner.dart
 M packages/map_battle/lib/src/data/static_basic_move_registry.dart
 M packages/map_battle/lib/src/domain/move/battle_move_behavior.dart
 M packages/map_battle/lib/src/psdk/application/psdk_battle_move_behavior.dart
 M packages/map_battle/test/psdk_move_families/copy_call_move_behavior_test.dart
 M packages/map_core/lib/src/operations/element_auto_shadow_policy.dart
 M packages/map_core/lib/src/operations/static_shadow_family_projection.dart
 M packages/map_core/test/shadow/element_auto_shadow_policy_test.dart
 M packages/map_core/test/shadow/static_shadow_family_projection_test.dart
?? reports/shadows/shadow_lot_50_selbrume_visual_calibration.md
?? reports/shadows/shadow_lot_50_selbrume_visual_calibration_plan.md
```

## 18. Git Diff Stat

```text
 .../lib/src/application/battle_turn_runner.dart    |   2 +
 .../lib/src/data/static_basic_move_registry.dart   |   3 +-
 .../lib/src/domain/move/battle_move_behavior.dart  |   2 +
 .../application/psdk_battle_move_behavior.dart     |   5 +
 .../copy_call_move_behavior_test.dart              | 105 +++++++-
 .../src/operations/element_auto_shadow_policy.dart |  69 ++++--
 .../static_shadow_family_projection.dart           |  70 ++++--
 .../shadow/element_auto_shadow_policy_test.dart    | 268 +++++++++++++++++++++
 .../static_shadow_family_projection_test.dart      | 102 ++++++--
 9 files changed, 556 insertions(+), 70 deletions(-)
```

## 19. Git Diff Name-Status

```text
M	packages/map_battle/lib/src/application/battle_turn_runner.dart
M	packages/map_battle/lib/src/data/static_basic_move_registry.dart
M	packages/map_battle/lib/src/domain/move/battle_move_behavior.dart
M	packages/map_battle/lib/src/psdk/application/psdk_battle_move_behavior.dart
M	packages/map_battle/test/psdk_move_families/copy_call_move_behavior_test.dart
M	packages/map_core/lib/src/operations/element_auto_shadow_policy.dart
M	packages/map_core/lib/src/operations/static_shadow_family_projection.dart
M	packages/map_core/test/shadow/element_auto_shadow_policy_test.dart
M	packages/map_core/test/shadow/static_shadow_family_projection_test.dart
```

## 20. Non-Goals Respected

```text
No runtime production files modified by Shadow-50.
No editor production files modified by Shadow-50.
No map_gameplay files modified by Shadow-50.
No map_battle files modified by Shadow-50.
No persistent models modified by Shadow-50.
No JSON codecs modified by Shadow-50.
No generated files modified by Shadow-50.
No Flame component or renderer introduced.
No UI introduced.
No global light or time-of-day introduced.
No build_runner run.
No commit performed.
```

## 21. Risks / Reserves

This lot makes the automatic baseline substantially smaller, but it is still generated geometry, not hand-authored Pokemon-style asset masks. If the visual result still feels too geometric, the next step should be a different model: contact ledge shadows for building bases, then optional asset/family masks. More numeric tuning alone is unlikely to produce the reference look.

Legacy replacement is strict and may not catch user-edited variants of the old broad shadows. That is intentional to avoid overwriting real manual work.

## 22. Auto-Review

```text
Ai-je calibre les specs famille V1 ? oui.
Ai-je rendu les projections short/tapered ? oui.
Ai-je reclassifie les lampadaires Selbrume 3x5 en tallThin ? oui.
Ai-je reclassifie les elements tres larges et bas en wideLow ? oui.
Ai-je remplace les anciennes configs broad Selbrume exactes ? oui.
Ai-je protege les configs manuelles non reconnues ? oui.
Ai-je garde le lot dans map_core ? oui.
Ai-je evite runtime/editor ? oui.
Ai-je evite les modeles/codecs/generation ? oui.
Ai-je evite une lumiere globale ? oui.
Ai-je verifie les tests cibles et regressions ? oui.
Ai-je evite de commit ? oui.
```

## 23. Complete Contents Of Shadow-50 Modified Files

### `packages/map_core/lib/src/operations/static_shadow_family_projection.dart`

```dart
import '../models/shadow.dart';
import 'static_shadow_projection_geometry.dart';

const _compactPropLengthRatio = 0.0704;
const _compactPropNearWidthMultiplier = 0.3312;
const _compactPropFarWidthMultiplier = 0.2832;

const _tallPropLengthRatio = 0.0704;
const _tallPropNearWidthMultiplier = 0.2208;
const _tallPropFarWidthMultiplier = 0.1770;

const _buildingLengthRatio = 0.0832;
const _buildingNearWidthMultiplier = 0.4416;
const _buildingFarWidthMultiplier = 0.3422;

const _foliageLengthRatio = 0.0960;
const _foliageNearWidthMultiplier = 0.5060;
const _foliageFarWidthMultiplier = 0.4720;

StaticShadowFamily resolveStaticShadowFamily({
  StaticShadowFamily? elementFamily,
  StaticShadowFamily? overrideFamily,
}) {
  return overrideFamily ??
      elementFamily ??
      StaticShadowFamily.genericProjection;
}

StaticShadowProjectionSpec resolveStaticShadowFamilyProjectionSpec({
  required StaticShadowFamily family,
  StaticShadowProjectionSpec baseProjectionSpec =
      defaultStaticShadowProjectionSpec,
}) {
  switch (family) {
    case StaticShadowFamily.genericProjection:
      return baseProjectionSpec;
    case StaticShadowFamily.compactProp:
      return _calibratedProjectionSpec(
        baseProjectionSpec,
        defaultLengthRatio: _compactPropLengthRatio,
        defaultNearWidthMultiplier: _compactPropNearWidthMultiplier,
        defaultFarWidthMultiplier: _compactPropFarWidthMultiplier,
      );
    case StaticShadowFamily.tallProp:
      return _calibratedProjectionSpec(
        baseProjectionSpec,
        defaultLengthRatio: _tallPropLengthRatio,
        defaultNearWidthMultiplier: _tallPropNearWidthMultiplier,
        defaultFarWidthMultiplier: _tallPropFarWidthMultiplier,
      );
    case StaticShadowFamily.building:
      return _calibratedProjectionSpec(
        baseProjectionSpec,
        defaultLengthRatio: _buildingLengthRatio,
        defaultNearWidthMultiplier: _buildingNearWidthMultiplier,
        defaultFarWidthMultiplier: _buildingFarWidthMultiplier,
      );
    case StaticShadowFamily.foliage:
      return _calibratedProjectionSpec(
        baseProjectionSpec,
        defaultLengthRatio: _foliageLengthRatio,
        defaultNearWidthMultiplier: _foliageNearWidthMultiplier,
        defaultFarWidthMultiplier: _foliageFarWidthMultiplier,
      );
  }
}

StaticShadowProjectionSpec _calibratedProjectionSpec(
  StaticShadowProjectionSpec baseProjectionSpec, {
  required double defaultLengthRatio,
  required double defaultNearWidthMultiplier,
  required double defaultFarWidthMultiplier,
}) {
  return StaticShadowProjectionSpec(
    directionX: baseProjectionSpec.directionX,
    directionY: baseProjectionSpec.directionY,
    lengthRatio: baseProjectionSpec.lengthRatio *
        defaultLengthRatio /
        defaultStaticShadowProjectionLengthRatio,
    nearWidthMultiplier: baseProjectionSpec.nearWidthMultiplier *
        defaultNearWidthMultiplier /
        defaultStaticShadowProjectionNearWidthMultiplier,
    farWidthMultiplier: baseProjectionSpec.farWidthMultiplier *
        defaultFarWidthMultiplier /
        defaultStaticShadowProjectionFarWidthMultiplier,
  );
}

```
### `packages/map_core/lib/src/operations/element_auto_shadow_policy.dart`

```dart
import '../models/project_manifest.dart';
import '../models/shadow.dart';
import '../models/shadow_catalog.dart';
import 'default_shadow_profiles.dart';

enum ElementAutoShadowSuggestionKind {
  tallThin,
  buildingLarge,
  wideLow,
  smallSquare,
  defaultProp,
}

final class ElementAutoShadowSuggestion {
  const ElementAutoShadowSuggestion({
    required this.kind,
    required this.config,
    required this.summary,
  });

  final ElementAutoShadowSuggestionKind kind;
  final ProjectElementShadowConfig config;
  final String summary;
}

enum ElementAutoShadowBackfillStatus {
  appliedMissing,
  appliedGeneric,
  skippedDisabled,
  skippedManual,
  skippedNoSuggestion,
  clearedAutoNoSuggestion,
}

final class ElementAutoShadowBackfillEntry {
  const ElementAutoShadowBackfillEntry({
    required this.elementId,
    required this.elementName,
    required this.status,
    this.suggestionKind,
  });

  final String elementId;
  final String elementName;
  final ElementAutoShadowBackfillStatus status;
  final ElementAutoShadowSuggestionKind? suggestionKind;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ElementAutoShadowBackfillEntry &&
            elementId == other.elementId &&
            elementName == other.elementName &&
            status == other.status &&
            suggestionKind == other.suggestionKind;
  }

  @override
  int get hashCode => Object.hash(
        elementId,
        elementName,
        status,
        suggestionKind,
      );
}

final class ElementAutoShadowBackfillResult {
  const ElementAutoShadowBackfillResult({
    required this.project,
    required this.entries,
    required this.addedDefaultProfiles,
  });

  final ProjectManifest project;
  final List<ElementAutoShadowBackfillEntry> entries;
  final bool addedDefaultProfiles;

  int get appliedCount => entries
      .where(
        (entry) =>
            entry.status == ElementAutoShadowBackfillStatus.appliedMissing ||
            entry.status == ElementAutoShadowBackfillStatus.appliedGeneric,
      )
      .length;

  int get clearedCount => entries
      .where(
        (entry) =>
            entry.status ==
            ElementAutoShadowBackfillStatus.clearedAutoNoSuggestion,
      )
      .length;

  int get changedCount => entries.where(_entryChangesProject).length;

  int get skippedCount => entries.length - changedCount;

  bool get hasChanges => addedDefaultProfiles || changedCount > 0;
}

ElementAutoShadowSuggestion? buildElementAutoShadowSuggestion({
  required ProjectElementEntry element,
  required ProjectShadowCatalog shadowCatalog,
}) {
  if (element.frames.isEmpty) {
    return null;
  }
  final source = element.frames.first.source;
  if (source.width <= 0 || source.height <= 0) {
    return null;
  }
  final width = source.width.toDouble();
  final height = source.height.toDouble();
  if (_isMicroDecor(
    width: width,
    height: height,
  )) {
    return null;
  }
  final kind = _classifyElement(
    width: width,
    height: height,
  );
  if (!_autoShadowKindIsArtisticallySafe(
    kind,
    width: width,
    height: height,
  )) {
    return null;
  }
  final profile = _profileForKind(shadowCatalog, kind);
  if (profile == null) {
    return null;
  }
  return ElementAutoShadowSuggestion(
    kind: kind,
    config: _configForKind(kind, profile.id),
    summary: _summaryForKind(kind),
  );
}

ElementAutoShadowBackfillResult applyElementAutoShadowPolicyToProject(
  ProjectManifest project,
) {
  final projectWithDefaults =
      ensureDefaultGroundStaticShadowProfilesForProject(project);
  final addedDefaultProfiles = projectWithDefaults != project;
  final entries = <ElementAutoShadowBackfillEntry>[];
  final elements = <ProjectElementEntry>[];

  for (final element in projectWithDefaults.elements) {
    final currentShadow = element.shadow;
    if (currentShadow != null && !currentShadow.castsShadow) {
      entries.add(
        _entry(element, ElementAutoShadowBackfillStatus.skippedDisabled),
      );
      elements.add(element);
      continue;
    }

    final suggestion = buildElementAutoShadowSuggestion(
      element: element,
      shadowCatalog: projectWithDefaults.shadowCatalog,
    );
    if (suggestion == null) {
      if (currentShadow != null &&
          _isRecognizedAutoShadow(
            currentShadow,
            projectWithDefaults.shadowCatalog,
          )) {
        entries.add(
          _entry(
            element,
            ElementAutoShadowBackfillStatus.clearedAutoNoSuggestion,
          ),
        );
        elements.add(element.copyWith(shadow: null));
        continue;
      }
      entries.add(
        _entry(
          element,
          currentShadow == null
              ? ElementAutoShadowBackfillStatus.skippedNoSuggestion
              : ElementAutoShadowBackfillStatus.skippedManual,
        ),
      );
      elements.add(element);
      continue;
    }
    if (currentShadow != null &&
        !_isRecognizedAutoShadow(
          currentShadow,
          projectWithDefaults.shadowCatalog,
        )) {
      entries.add(
        _entry(element, ElementAutoShadowBackfillStatus.skippedManual),
      );
      elements.add(element);
      continue;
    }

    final status = currentShadow == null
        ? ElementAutoShadowBackfillStatus.appliedMissing
        : ElementAutoShadowBackfillStatus.appliedGeneric;
    entries.add(
      _entry(
        element,
        status,
        suggestionKind: suggestion.kind,
      ),
    );
    elements.add(element.copyWith(shadow: suggestion.config));
  }

  return ElementAutoShadowBackfillResult(
    project: addedDefaultProfiles || entries.any(_entryChangesProject)
        ? projectWithDefaults.copyWith(elements: elements)
        : project,
    entries: entries,
    addedDefaultProfiles: addedDefaultProfiles,
  );
}

bool _isMicroDecor({
  required double width,
  required double height,
}) {
  return width <= 1 && height <= 2;
}

ElementAutoShadowSuggestionKind _classifyElement({
  required double width,
  required double height,
}) {
  final area = width * height;
  final aspect = height / width;
  final wideAspect = width / height;
  if ((aspect >= 2.2 && width <= 2) ||
      (width <= 3 && height >= 5 && aspect >= 1.4)) {
    return ElementAutoShadowSuggestionKind.tallThin;
  }
  if (width >= 3 && height <= 2) {
    return ElementAutoShadowSuggestionKind.wideLow;
  }
  if (width >= 4 && height <= 6 && wideAspect >= 2.0) {
    return ElementAutoShadowSuggestionKind.wideLow;
  }
  if (width >= 4 || area >= 12) {
    return ElementAutoShadowSuggestionKind.buildingLarge;
  }
  if (width >= 3 && height <= 3) {
    return ElementAutoShadowSuggestionKind.wideLow;
  }
  if (area <= 4) {
    return ElementAutoShadowSuggestionKind.smallSquare;
  }
  return ElementAutoShadowSuggestionKind.defaultProp;
}

bool _autoShadowKindIsArtisticallySafe(
  ElementAutoShadowSuggestionKind kind, {
  required double width,
  required double height,
}) {
  switch (kind) {
    case ElementAutoShadowSuggestionKind.tallThin:
    case ElementAutoShadowSuggestionKind.buildingLarge:
      return true;
    case ElementAutoShadowSuggestionKind.wideLow:
      return width >= 4 || width * height >= 10;
    case ElementAutoShadowSuggestionKind.smallSquare:
    case ElementAutoShadowSuggestionKind.defaultProp:
      return false;
  }
}

ProjectShadowProfile? _profileForKind(
  ProjectShadowCatalog catalog,
  ElementAutoShadowSuggestionKind kind,
) {
  switch (kind) {
    case ElementAutoShadowSuggestionKind.tallThin:
    case ElementAutoShadowSuggestionKind.smallSquare:
      return _preferredCompactProfile(catalog);
    case ElementAutoShadowSuggestionKind.buildingLarge:
    case ElementAutoShadowSuggestionKind.wideLow:
      return _preferredWideProfile(catalog);
    case ElementAutoShadowSuggestionKind.defaultProp:
      return _preferredSoftProfile(catalog);
  }
}

ProjectShadowProfile? _preferredCompactProfile(ProjectShadowCatalog catalog) {
  return _compatibleProfileById(catalog, 'default-ground-contact-blob') ??
      _firstCompatibleProfileWithMode(catalog, ShadowCasterMode.contactBlob) ??
      _firstCompatibleProfile(catalog);
}

ProjectShadowProfile? _preferredWideProfile(ProjectShadowCatalog catalog) {
  return _compatibleProfileById(catalog, 'default-ground-wide-ellipse') ??
      _firstCompatibleProfileWithMode(catalog, ShadowCasterMode.ellipse) ??
      _firstCompatibleProfile(catalog);
}

ProjectShadowProfile? _preferredSoftProfile(ProjectShadowCatalog catalog) {
  return _compatibleProfileById(catalog, 'default-ground-soft-ellipse') ??
      _firstCompatibleProfileWithMode(catalog, ShadowCasterMode.ellipse) ??
      _firstCompatibleProfile(catalog);
}

ProjectShadowProfile? _compatibleProfileById(
  ProjectShadowCatalog catalog,
  String id,
) {
  final profile = catalog.profileById(id);
  if (profile == null || !isGroundStaticElementShadowProfile(profile)) {
    return null;
  }
  return profile;
}

ProjectShadowProfile? _firstCompatibleProfileWithMode(
  ProjectShadowCatalog catalog,
  ShadowCasterMode mode,
) {
  for (final profile in catalog.profiles) {
    if (profile.mode == mode && isGroundStaticElementShadowProfile(profile)) {
      return profile;
    }
  }
  return null;
}

ProjectShadowProfile? _firstCompatibleProfile(ProjectShadowCatalog catalog) {
  for (final profile in catalog.profiles) {
    if (isGroundStaticElementShadowProfile(profile)) {
      return profile;
    }
  }
  return null;
}

ProjectElementShadowConfig _configForKind(
  ElementAutoShadowSuggestionKind kind,
  String profileId,
) {
  switch (kind) {
    case ElementAutoShadowSuggestionKind.tallThin:
      return ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: profileId,
        offsetX: 0,
        offsetY: 0,
        scaleX: 0.80,
        scaleY: 0.55,
        opacity: 0.20,
        family: StaticShadowFamily.tallProp,
        footprint: StaticShadowFootprintConfig(
          anchorXRatio: 0.5,
          anchorYRatio: 1.0,
          footprintWidthRatio: 0.28,
          footprintHeightRatio: 0.05,
        ),
      );
    case ElementAutoShadowSuggestionKind.buildingLarge:
      return ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: profileId,
        offsetX: 0,
        offsetY: 0,
        scaleX: 0.72,
        scaleY: 0.48,
        opacity: 0.20,
        family: StaticShadowFamily.building,
        footprint: StaticShadowFootprintConfig(
          anchorXRatio: 0.5,
          anchorYRatio: 0.98,
          footprintWidthRatio: 0.60,
          footprintHeightRatio: 0.06,
        ),
      );
    case ElementAutoShadowSuggestionKind.wideLow:
      return ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: profileId,
        offsetX: 0,
        offsetY: 0,
        scaleX: 0.74,
        scaleY: 0.50,
        opacity: 0.20,
        family: StaticShadowFamily.compactProp,
        footprint: StaticShadowFootprintConfig(
          anchorXRatio: 0.5,
          anchorYRatio: 0.98,
          footprintWidthRatio: 0.58,
          footprintHeightRatio: 0.06,
        ),
      );
    case ElementAutoShadowSuggestionKind.smallSquare:
      return ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: profileId,
        offsetX: 0,
        offsetY: 0,
        scaleX: 0.78,
        scaleY: 0.70,
        opacity: 0.26,
        family: StaticShadowFamily.compactProp,
        footprint: StaticShadowFootprintConfig(
          anchorXRatio: 0.5,
          anchorYRatio: 0.96,
          footprintWidthRatio: 0.46,
          footprintHeightRatio: 0.10,
        ),
      );
    case ElementAutoShadowSuggestionKind.defaultProp:
      return ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: profileId,
        offsetX: 0,
        offsetY: 0,
        scaleX: 0.90,
        scaleY: 0.80,
        opacity: 0.28,
        family: StaticShadowFamily.genericProjection,
        footprint: StaticShadowFootprintConfig(
          anchorXRatio: 0.5,
          anchorYRatio: 0.95,
          footprintWidthRatio: 0.62,
          footprintHeightRatio: 0.12,
        ),
      );
  }
}

String _summaryForKind(ElementAutoShadowSuggestionKind kind) {
  switch (kind) {
    case ElementAutoShadowSuggestionKind.tallThin:
      return 'lampadaire fin';
    case ElementAutoShadowSuggestionKind.buildingLarge:
      return 'grand bâtiment';
    case ElementAutoShadowSuggestionKind.wideLow:
      return 'élément large et bas';
    case ElementAutoShadowSuggestionKind.smallSquare:
      return 'petit élément compact';
    case ElementAutoShadowSuggestionKind.defaultProp:
      return 'élément standard';
  }
}

bool _entryChangesProject(ElementAutoShadowBackfillEntry entry) {
  return entry.status == ElementAutoShadowBackfillStatus.appliedMissing ||
      entry.status == ElementAutoShadowBackfillStatus.appliedGeneric ||
      entry.status == ElementAutoShadowBackfillStatus.clearedAutoNoSuggestion;
}

ElementAutoShadowBackfillEntry _entry(
  ProjectElementEntry element,
  ElementAutoShadowBackfillStatus status, {
  ElementAutoShadowSuggestionKind? suggestionKind,
}) {
  return ElementAutoShadowBackfillEntry(
    elementId: element.id,
    elementName: element.name,
    status: status,
    suggestionKind: suggestionKind,
  );
}

bool _isRecognizedAutoShadow(
  ProjectElementShadowConfig shadow,
  ProjectShadowCatalog catalog,
) {
  return _canReplaceExistingShadow(shadow, catalog) ||
      shadow == _oldAutoSmallSquareShadow() ||
      shadow == _oldAutoDefaultPropShadow() ||
      shadow == _oldAutoWideLowShadow() ||
      _isLegacyBroadSelbrumeAutoShadow(shadow);
}

bool _canReplaceExistingShadow(
  ProjectElementShadowConfig shadow,
  ProjectShadowCatalog catalog,
) {
  if (!shadow.castsShadow) {
    return false;
  }
  if (shadow.footprint != null) {
    return false;
  }
  if (shadow.offsetX != null ||
      shadow.offsetY != null ||
      shadow.scaleX != null ||
      shadow.scaleY != null ||
      shadow.opacity != null) {
    return false;
  }

  final profileId = shadow.shadowProfileId;
  if (profileId == null) {
    return true;
  }
  if (_defaultGroundStaticProfileIds.contains(profileId)) {
    return true;
  }
  return catalog.profileById(profileId) == null;
}

ProjectElementShadowConfig _oldAutoSmallSquareShadow() {
  return ProjectElementShadowConfig(
    castsShadow: true,
    shadowProfileId: 'default-ground-contact-blob',
    offsetX: 0,
    offsetY: 0,
    scaleX: 0.78,
    scaleY: 0.70,
    opacity: 0.26,
    family: StaticShadowFamily.compactProp,
    footprint: StaticShadowFootprintConfig(
      anchorXRatio: 0.5,
      anchorYRatio: 0.96,
      footprintWidthRatio: 0.46,
      footprintHeightRatio: 0.10,
    ),
  );
}

ProjectElementShadowConfig _oldAutoDefaultPropShadow() {
  return ProjectElementShadowConfig(
    castsShadow: true,
    shadowProfileId: 'default-ground-soft-ellipse',
    offsetX: 0,
    offsetY: 0,
    scaleX: 0.90,
    scaleY: 0.80,
    opacity: 0.28,
    family: StaticShadowFamily.genericProjection,
    footprint: StaticShadowFootprintConfig(
      anchorXRatio: 0.5,
      anchorYRatio: 0.95,
      footprintWidthRatio: 0.62,
      footprintHeightRatio: 0.12,
    ),
  );
}

ProjectElementShadowConfig _oldAutoWideLowShadow() {
  return ProjectElementShadowConfig(
    castsShadow: true,
    shadowProfileId: 'default-ground-wide-ellipse',
    offsetX: 0,
    offsetY: 0,
    scaleX: 0.92,
    scaleY: 0.75,
    opacity: 0.27,
    family: StaticShadowFamily.compactProp,
    footprint: StaticShadowFootprintConfig(
      anchorXRatio: 0.5,
      anchorYRatio: 0.95,
      footprintWidthRatio: 0.72,
      footprintHeightRatio: 0.10,
    ),
  );
}

bool _isLegacyBroadSelbrumeAutoShadow(ProjectElementShadowConfig shadow) {
  if (!shadow.castsShadow ||
      shadow.shadowProfileId != 'default-ground-wide-ellipse' ||
      shadow.offsetX != 0 ||
      shadow.offsetY != 0 ||
      shadow.scaleX != 1 ||
      shadow.scaleY != 0.85 ||
      shadow.opacity != 0.30) {
    return false;
  }
  final family = shadow.family;
  if (family != null &&
      family != StaticShadowFamily.building &&
      family != StaticShadowFamily.compactProp) {
    return false;
  }
  return shadow.footprint ==
      StaticShadowFootprintConfig(
        anchorXRatio: 0.5,
        anchorYRatio: 0.92,
        footprintWidthRatio: 0.82,
        footprintHeightRatio: 0.12,
      );
}

const _defaultGroundStaticProfileIds = <String>{
  'default-ground-soft-ellipse',
  'default-ground-wide-ellipse',
  'default-ground-contact-blob',
};

```
### `packages/map_core/test/shadow/static_shadow_family_projection_test.dart`

```dart
import 'dart:math' as math;

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('resolveStaticShadowFamily', () {
    test('uses generic projection when no family is provided', () {
      expect(
        resolveStaticShadowFamily(),
        StaticShadowFamily.genericProjection,
      );
    });

    test('uses element family when no override family is provided', () {
      expect(
        resolveStaticShadowFamily(
          elementFamily: StaticShadowFamily.building,
        ),
        StaticShadowFamily.building,
      );
    });

    test('uses override family over element family', () {
      expect(
        resolveStaticShadowFamily(
          elementFamily: StaticShadowFamily.building,
          overrideFamily: StaticShadowFamily.tallProp,
        ),
        StaticShadowFamily.tallProp,
      );
    });
  });

  group('resolveStaticShadowFamilyProjectionSpec', () {
    test('genericProjection returns the base projection unchanged', () {
      final base = StaticShadowProjectionSpec(
        directionX: -1,
        directionY: 0.5,
        lengthRatio: 0.4,
        nearWidthMultiplier: 0.9,
        farWidthMultiplier: 1.1,
      );

      expect(
        resolveStaticShadowFamilyProjectionSpec(
          family: StaticShadowFamily.genericProjection,
          baseProjectionSpec: base,
        ),
        base,
      );
    });

    test('preserves base direction for every non-generic family', () {
      final base = StaticShadowProjectionSpec(
        directionX: -0.75,
        directionY: 0.35,
        lengthRatio: 0.32,
        nearWidthMultiplier: 0.92,
        farWidthMultiplier: 1.18,
      );

      for (final family in <StaticShadowFamily>[
        StaticShadowFamily.compactProp,
        StaticShadowFamily.tallProp,
        StaticShadowFamily.building,
        StaticShadowFamily.foliage,
      ]) {
        final spec = resolveStaticShadowFamilyProjectionSpec(
          family: family,
          baseProjectionSpec: base,
        );

        expect(spec.directionX, base.directionX);
        expect(spec.directionY, base.directionY);
      }
    });

    test('compact props are shorter and tighter than generic projection', () {
      final spec = resolveStaticShadowFamilyProjectionSpec(
        family: StaticShadowFamily.compactProp,
      );

      expect(
        spec.lengthRatio,
        lessThan(defaultStaticShadowProjectionSpec.lengthRatio),
      );
      expect(
        spec.nearWidthMultiplier,
        lessThan(defaultStaticShadowProjectionSpec.nearWidthMultiplier),
      );
      expect(
        spec.farWidthMultiplier,
        lessThan(defaultStaticShadowProjectionSpec.farWidthMultiplier),
      );
    });

    test('tall props are narrow and shorter than generic', () {
      final spec = resolveStaticShadowFamilyProjectionSpec(
        family: StaticShadowFamily.tallProp,
      );

      expect(
        spec.lengthRatio,
        lessThan(defaultStaticShadowProjectionSpec.lengthRatio),
      );
      expect(
        spec.nearWidthMultiplier,
        lessThan(defaultStaticShadowProjectionSpec.nearWidthMultiplier),
      );
      expect(
        spec.farWidthMultiplier,
        lessThan(defaultStaticShadowProjectionSpec.farWidthMultiplier),
      );
    });

    test('buildings keep a broad but shorter block-like projection', () {
      final spec = resolveStaticShadowFamilyProjectionSpec(
        family: StaticShadowFamily.building,
      );
      final tall = resolveStaticShadowFamilyProjectionSpec(
        family: StaticShadowFamily.tallProp,
      );

      expect(
        spec.lengthRatio,
        lessThan(defaultStaticShadowProjectionSpec.lengthRatio),
      );
      expect(
        spec.nearWidthMultiplier,
        lessThan(defaultStaticShadowProjectionSpec.nearWidthMultiplier),
      );
      expect(
        spec.nearWidthMultiplier,
        greaterThan(tall.nearWidthMultiplier),
      );
      expect(
        spec.farWidthMultiplier,
        lessThan(defaultStaticShadowProjectionSpec.farWidthMultiplier),
      );
    });

    test('foliage is broader than tall prop', () {
      final foliage = resolveStaticShadowFamilyProjectionSpec(
        family: StaticShadowFamily.foliage,
      );
      final tallProp = resolveStaticShadowFamilyProjectionSpec(
        family: StaticShadowFamily.tallProp,
      );

      expect(
        foliage.nearWidthMultiplier,
        greaterThan(tallProp.nearWidthMultiplier),
      );
      expect(
        foliage.farWidthMultiplier,
        greaterThan(tallProp.farWidthMultiplier),
      );
    });

    test('compactProp V1 calibration is short and tapered', () {
      final spec = resolveStaticShadowFamilyProjectionSpec(
        family: StaticShadowFamily.compactProp,
      );

      expect(spec.lengthRatio, closeTo(0.0704, 0.0000001));
      expect(spec.nearWidthMultiplier, closeTo(0.3312, 0.0000001));
      expect(spec.farWidthMultiplier, closeTo(0.2832, 0.0000001));
      expect(spec.farWidthMultiplier, lessThan(spec.nearWidthMultiplier));
    });

    test('tallProp V1 calibration is very narrow and short', () {
      final spec = resolveStaticShadowFamilyProjectionSpec(
        family: StaticShadowFamily.tallProp,
      );

      expect(spec.lengthRatio, closeTo(0.0704, 0.0000001));
      expect(spec.nearWidthMultiplier, closeTo(0.2208, 0.0000001));
      expect(spec.farWidthMultiplier, closeTo(0.1770, 0.0000001));
      expect(spec.farWidthMultiplier, lessThan(spec.nearWidthMultiplier));
    });

    test('building V1 calibration avoids broad slabs', () {
      final spec = resolveStaticShadowFamilyProjectionSpec(
        family: StaticShadowFamily.building,
      );

      expect(spec.lengthRatio, closeTo(0.0832, 0.0000001));
      expect(spec.nearWidthMultiplier, closeTo(0.4416, 0.0000001));
      expect(spec.farWidthMultiplier, closeTo(0.3422, 0.0000001));
      expect(spec.farWidthMultiplier, lessThan(spec.nearWidthMultiplier));
    });

    test('foliage V1 calibration is restrained but broader than tall props',
        () {
      final spec = resolveStaticShadowFamilyProjectionSpec(
        family: StaticShadowFamily.foliage,
      );
      final tall = resolveStaticShadowFamilyProjectionSpec(
        family: StaticShadowFamily.tallProp,
      );

      expect(spec.lengthRatio, closeTo(0.0960, 0.0000001));
      expect(spec.nearWidthMultiplier, closeTo(0.5060, 0.0000001));
      expect(spec.farWidthMultiplier, closeTo(0.4720, 0.0000001));
      expect(spec.nearWidthMultiplier, greaterThan(tall.nearWidthMultiplier));
    });

    test('scaled family specs remain valid for a custom positive base', () {
      final base = StaticShadowProjectionSpec(
        directionX: 1,
        directionY: 0.45,
        lengthRatio: 0.1,
        nearWidthMultiplier: 0.2,
        farWidthMultiplier: 0.3,
      );

      for (final family in StaticShadowFamily.values) {
        final spec = resolveStaticShadowFamilyProjectionSpec(
          family: family,
          baseProjectionSpec: base,
        );

        expect(spec.directionX.isFinite, isTrue);
        expect(spec.directionY.isFinite, isTrue);
        expect(spec.lengthRatio, greaterThan(0));
        expect(spec.nearWidthMultiplier, greaterThan(0));
        expect(spec.farWidthMultiplier, greaterThan(0));
      }
    });
  });

  group('family projection geometry composition', () {
    test('tall prop polygon stays much narrower than building polygon', () {
      final tall = _projectedCase(
        family: StaticShadowFamily.tallProp,
        visualWidth: 16,
        visualHeight: 64,
        footprintWidthRatio: 0.18,
        footprintHeightRatio: 0.07,
      );
      final building = _projectedCase(
        family: StaticShadowFamily.building,
        visualWidth: 96,
        visualHeight: 80,
        footprintWidthRatio: 0.82,
        footprintHeightRatio: 0.12,
      );

      expect(_maxWidth(tall), lessThan(_maxWidth(building) * 0.45));
      expect(_polygonArea(tall), lessThan(_polygonArea(building) * 0.45));
    });

    test('compact prop projects less area than generic for same metrics', () {
      final compact = _projectedCase(
        family: StaticShadowFamily.compactProp,
        visualWidth: 72,
        visualHeight: 48,
        footprintWidthRatio: 0.72,
        footprintHeightRatio: 0.10,
      );
      final generic = _projectedCase(
        family: StaticShadowFamily.genericProjection,
        visualWidth: 72,
        visualHeight: 48,
        footprintWidthRatio: 0.72,
        footprintHeightRatio: 0.10,
      );

      expect(_polygonArea(compact), lessThan(_polygonArea(generic)));
    });

    test('building V1 projected geometry stays compact for a Selbrume house',
        () {
      final geometry = _projectedCase(
        family: StaticShadowFamily.building,
        visualWidth: 192,
        visualHeight: 224,
        footprintWidthRatio: 0.60 * 0.72,
        footprintHeightRatio: 0.06 * 0.48,
      );

      expect(_projectedLength(geometry), lessThan(20));
      expect(_maxWidth(geometry), lessThan(40));
      expect(_polygonArea(geometry), lessThan(700));
    });

    test('building V1 projected area is far smaller than legacy Selbrume slab',
        () {
      final v1 = _projectedCase(
        family: StaticShadowFamily.building,
        visualWidth: 192,
        visualHeight: 224,
        footprintWidthRatio: 0.60 * 0.72,
        footprintHeightRatio: 0.06 * 0.48,
      );
      final legacy = _projectedCase(
        family: StaticShadowFamily.building,
        visualWidth: 192,
        visualHeight: 224,
        footprintWidthRatio: 0.82,
        footprintHeightRatio: 0.12 * 0.85,
        projectionSpec: StaticShadowProjectionSpec(
          directionX: defaultStaticShadowProjectionDirectionX,
          directionY: defaultStaticShadowProjectionDirectionY,
          lengthRatio: 0.1984,
          nearWidthMultiplier: 0.7176,
          farWidthMultiplier: 0.7316,
        ),
      );

      expect(_polygonArea(v1), lessThan(_polygonArea(legacy) * 0.30));
    });
  });
}

ProjectedStaticShadowGeometry _projectedCase({
  required StaticShadowFamily family,
  required double visualWidth,
  required double visualHeight,
  required double footprintWidthRatio,
  required double footprintHeightRatio,
  StaticShadowProjectionSpec? projectionSpec,
}) {
  final metrics = StaticShadowVisualMetrics(
    left: 0,
    top: 0,
    visualWidth: visualWidth,
    visualHeight: visualHeight,
  );
  final baseGeometry = resolveStaticShadowGeometry(
    metrics: metrics,
    shadowConfig: ResolvedShadowConfig(
      shadowProfileId: 'default-ground-soft-ellipse',
      mode: ShadowCasterMode.ellipse,
      renderPass: ShadowRenderPass.groundStatic,
      offsetX: 0,
      offsetY: 0,
      scaleX: 1,
      scaleY: 1,
      opacity: 0.3,
      colorHexRgb: '000000',
      softnessMode: ShadowSoftnessMode.hardEdge,
    ),
    elementFootprint: StaticShadowFootprintConfig(
      anchorXRatio: 0.5,
      anchorYRatio: 1,
      footprintWidthRatio: footprintWidthRatio,
      footprintHeightRatio: footprintHeightRatio,
    ),
  );

  return resolveProjectedStaticShadowGeometry(
    baseGeometry: baseGeometry,
    metrics: metrics,
    projectionSpec: projectionSpec ??
        resolveStaticShadowFamilyProjectionSpec(family: family),
  );
}

double _maxWidth(ProjectedStaticShadowGeometry geometry) {
  return [
    _distance(geometry.nearLeft, geometry.nearRight),
    _distance(geometry.farLeft, geometry.farRight),
  ].reduce((first, second) => first > second ? first : second);
}

double _projectedLength(ProjectedStaticShadowGeometry geometry) {
  final near = _midpoint(geometry.nearLeft, geometry.nearRight);
  final far = _midpoint(geometry.farLeft, geometry.farRight);
  return _distance(near, far);
}

ProjectedStaticShadowPoint _midpoint(
  ProjectedStaticShadowPoint first,
  ProjectedStaticShadowPoint second,
) {
  return ProjectedStaticShadowPoint(
    x: (first.x + second.x) / 2,
    y: (first.y + second.y) / 2,
  );
}

double _distance(
  ProjectedStaticShadowPoint first,
  ProjectedStaticShadowPoint second,
) {
  final dx = first.x - second.x;
  final dy = first.y - second.y;
  return math.sqrt(dx * dx + dy * dy);
}

double _polygonArea(ProjectedStaticShadowGeometry geometry) {
  final points = geometry.points;
  var area = 0.0;
  for (var i = 0; i < points.length; i += 1) {
    final current = points[i];
    final next = points[(i + 1) % points.length];
    area += current.x * next.y - next.x * current.y;
  }
  return area.abs() / 2;
}

```
### `packages/map_core/test/shadow/element_auto_shadow_policy_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('buildElementAutoShadowSuggestion', () {
    test('small square and default prop return null', () {
      expect(
        buildElementAutoShadowSuggestion(
          element: _element(id: 'small', width: 2, height: 2),
          shadowCatalog: _defaultCatalog(),
        ),
        isNull,
      );
      expect(
        buildElementAutoShadowSuggestion(
          element: _element(id: 'prop', width: 2, height: 3),
          shadowCatalog: _defaultCatalog(),
        ),
        isNull,
      );
    });

    test('wide low needs enough surface', () {
      expect(
        buildElementAutoShadowSuggestion(
          element: _element(id: 'small-wide', width: 3, height: 2),
          shadowCatalog: _defaultCatalog(),
        ),
        isNull,
      );
      final suggestion = buildElementAutoShadowSuggestion(
        element: _element(id: 'wide', width: 4, height: 2),
        shadowCatalog: _defaultCatalog(),
      );

      expect(suggestion!.kind, ElementAutoShadowSuggestionKind.wideLow);
      expect(suggestion.config.shadowProfileId, 'default-ground-wide-ellipse');
    });

    test('tall thin and building elements receive suggestions', () {
      final tall = buildElementAutoShadowSuggestion(
        element: _element(id: 'lamp', width: 1, height: 4),
        shadowCatalog: _defaultCatalog(),
      );
      final building = buildElementAutoShadowSuggestion(
        element: _element(id: 'house', width: 4, height: 3),
        shadowCatalog: _defaultCatalog(),
      );

      expect(tall!.kind, ElementAutoShadowSuggestionKind.tallThin);
      expect(tall.config.family, StaticShadowFamily.tallProp);
      expect(building!.kind, ElementAutoShadowSuggestionKind.buildingLarge);
      expect(building.config.family, StaticShadowFamily.building);
    });

    test('Selbrume lamp proportions receive calibrated tall thin config', () {
      final suggestion = buildElementAutoShadowSuggestion(
        element: _element(id: 'lampadaire', width: 3, height: 5),
        shadowCatalog: _defaultCatalog(),
      );

      expect(suggestion!.kind, ElementAutoShadowSuggestionKind.tallThin);
      _expectConfig(
        suggestion.config,
        profileId: 'default-ground-contact-blob',
        scaleX: 0.80,
        scaleY: 0.55,
        opacity: 0.20,
        family: StaticShadowFamily.tallProp,
        anchorXRatio: 0.5,
        anchorYRatio: 1.0,
        footprintWidthRatio: 0.28,
        footprintHeightRatio: 0.05,
      );
    });

    test('Selbrume wide barriers stay wide low instead of building', () {
      final suggestion = buildElementAutoShadowSuggestion(
        element: _element(id: 'barriere_pierre', width: 13, height: 6),
        shadowCatalog: _defaultCatalog(),
      );

      expect(suggestion!.kind, ElementAutoShadowSuggestionKind.wideLow);
      _expectConfig(
        suggestion.config,
        profileId: 'default-ground-wide-ellipse',
        scaleX: 0.74,
        scaleY: 0.50,
        opacity: 0.20,
        family: StaticShadowFamily.compactProp,
        anchorXRatio: 0.5,
        anchorYRatio: 0.98,
        footprintWidthRatio: 0.58,
        footprintHeightRatio: 0.06,
      );
    });

    test('Selbrume houses receive calibrated building config', () {
      final suggestion = buildElementAutoShadowSuggestion(
        element: _element(id: 'maison', width: 6, height: 7),
        shadowCatalog: _defaultCatalog(),
      );

      expect(suggestion!.kind, ElementAutoShadowSuggestionKind.buildingLarge);
      _expectConfig(
        suggestion.config,
        profileId: 'default-ground-wide-ellipse',
        scaleX: 0.72,
        scaleY: 0.48,
        opacity: 0.20,
        family: StaticShadowFamily.building,
        anchorXRatio: 0.5,
        anchorYRatio: 0.98,
        footprintWidthRatio: 0.60,
        footprintHeightRatio: 0.06,
      );
    });

    test('V1 building auto config projects far less area than legacy broad',
        () {
      final legacy = _projectedAreaForShadow(
        _legacyBroadSelbrumeShadow(family: StaticShadowFamily.building),
        visualWidth: 192,
        visualHeight: 224,
        projectionSpec: _legacyBuildingProjectionSpec(),
      );
      final suggestion = buildElementAutoShadowSuggestion(
        element: _element(id: 'maison', width: 6, height: 7),
        shadowCatalog: _defaultCatalog(),
      )!;
      final v1 = _projectedAreaForShadow(
        suggestion.config,
        visualWidth: 192,
        visualHeight: 224,
      );

      expect(v1, lessThan(legacy * 0.30));
    });
  });

  group('applyElementAutoShadowPolicyToProject', () {
    test('backfill clears recognized old auto shadows without suggestion', () {
      final result = applyElementAutoShadowPolicyToProject(
        _project(
          elements: [
            _element(
              id: 'small',
              width: 2,
              height: 2,
              shadow: _oldAutoSmallSquareShadow(),
            ),
          ],
          shadowCatalog: _defaultCatalog(),
        ),
      );

      expect(result.appliedCount, 0);
      expect(result.clearedCount, 1);
      expect(result.changedCount, 1);
      expect(
        result.entries.single.status,
        ElementAutoShadowBackfillStatus.clearedAutoNoSuggestion,
      );
      expect(result.project.elements.single.shadow, isNull);
    });

    test('backfill applies eligible missing shadows', () {
      final result = applyElementAutoShadowPolicyToProject(
        _project(
          elements: [
            _element(id: 'lamp', width: 1, height: 4),
          ],
          shadowCatalog: const ProjectShadowCatalog.empty(),
        ),
      );

      expect(result.addedDefaultProfiles, isTrue);
      expect(result.appliedCount, 1);
      expect(result.clearedCount, 0);
      expect(result.changedCount, 1);
      expect(
        result.project.elements.single.shadow!.shadowProfileId,
        'default-ground-contact-blob',
      );
    });

    test('manual and disabled shadows are preserved', () {
      final manual = ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: 'custom-ground-shadow',
      );
      final disabled = ProjectElementShadowConfig(castsShadow: false);
      final result = applyElementAutoShadowPolicyToProject(
        _project(
          elements: [
            _element(id: 'manual', width: 2, height: 2, shadow: manual),
            _element(id: 'disabled', width: 4, height: 3, shadow: disabled),
          ],
          shadowCatalog: ProjectShadowCatalog(
            profiles: [
              ...createDefaultGroundStaticShadowProfiles(),
              ProjectShadowProfile(
                id: 'custom-ground-shadow',
                name: 'Custom ground shadow',
                mode: ShadowCasterMode.ellipse,
                renderPass: ShadowRenderPass.groundStatic,
              ),
            ],
          ),
        ),
      );

      expect(result.changedCount, 0);
      expect(result.hasChanges, isFalse);
      expect(result.project.elements[0].shadow, manual);
      expect(result.project.elements[1].shadow, disabled);
    });

    test('backfill replaces broad legacy Selbrume shadow without family', () {
      final result = applyElementAutoShadowPolicyToProject(
        _project(
          elements: [
            _element(
              id: 'lampadaire',
              width: 3,
              height: 5,
              shadow: _legacyBroadSelbrumeShadow(),
            ),
          ],
          shadowCatalog: _defaultCatalog(),
        ),
      );

      expect(result.appliedCount, 1);
      expect(result.changedCount, 1);
      expect(
        result.entries.single.status,
        ElementAutoShadowBackfillStatus.appliedGeneric,
      );
      _expectConfig(
        result.project.elements.single.shadow!,
        profileId: 'default-ground-contact-blob',
        scaleX: 0.80,
        scaleY: 0.55,
        opacity: 0.20,
        family: StaticShadowFamily.tallProp,
        anchorXRatio: 0.5,
        anchorYRatio: 1.0,
        footprintWidthRatio: 0.28,
        footprintHeightRatio: 0.05,
      );
    });

    test('backfill replaces broad legacy Selbrume building shadow', () {
      final result = applyElementAutoShadowPolicyToProject(
        _project(
          elements: [
            _element(
              id: 'maison',
              width: 6,
              height: 7,
              shadow: _legacyBroadSelbrumeShadow(
                family: StaticShadowFamily.building,
              ),
            ),
          ],
          shadowCatalog: _defaultCatalog(),
        ),
      );

      expect(result.appliedCount, 1);
      expect(result.changedCount, 1);
      expect(
        result.entries.single.status,
        ElementAutoShadowBackfillStatus.appliedGeneric,
      );
      _expectConfig(
        result.project.elements.single.shadow!,
        profileId: 'default-ground-wide-ellipse',
        scaleX: 0.72,
        scaleY: 0.48,
        opacity: 0.20,
        family: StaticShadowFamily.building,
        anchorXRatio: 0.5,
        anchorYRatio: 0.98,
        footprintWidthRatio: 0.60,
        footprintHeightRatio: 0.06,
      );
    });
  });
}

ProjectManifest _project({
  required List<ProjectElementEntry> elements,
  required ProjectShadowCatalog shadowCatalog,
}) {
  return ProjectManifest(
    name: 'Auto shadow policy test',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[
      ProjectTilesetEntry(
        id: 'tileset_main',
        name: 'Main tileset',
        relativePath: 'tilesets/main.png',
      ),
    ],
    elementCategories: const <ProjectElementCategory>[
      ProjectElementCategory(id: 'decor', name: 'Decor'),
    ],
    elements: elements,
    shadowCatalog: shadowCatalog,
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
}

ProjectShadowCatalog _defaultCatalog() {
  return ProjectShadowCatalog(
    profiles: createDefaultGroundStaticShadowProfiles(),
  );
}

ProjectElementEntry _element({
  required String id,
  required int width,
  required int height,
  ProjectElementShadowConfig? shadow,
}) {
  return ProjectElementEntry(
    id: id,
    name: id,
    tilesetId: 'tileset_main',
    categoryId: 'decor',
    frames: [
      TilesetVisualFrame(
        source: TilesetSourceRect(x: 0, y: 0, width: width, height: height),
      ),
    ],
    shadow: shadow,
  );
}

ProjectElementShadowConfig _oldAutoSmallSquareShadow() {
  return ProjectElementShadowConfig(
    castsShadow: true,
    shadowProfileId: 'default-ground-contact-blob',
    offsetX: 0,
    offsetY: 0,
    scaleX: 0.78,
    scaleY: 0.70,
    opacity: 0.26,
    family: StaticShadowFamily.compactProp,
    footprint: StaticShadowFootprintConfig(
      anchorXRatio: 0.5,
      anchorYRatio: 0.96,
      footprintWidthRatio: 0.46,
      footprintHeightRatio: 0.10,
    ),
  );
}

ProjectElementShadowConfig _legacyBroadSelbrumeShadow({
  StaticShadowFamily? family,
}) {
  return ProjectElementShadowConfig(
    castsShadow: true,
    shadowProfileId: 'default-ground-wide-ellipse',
    offsetX: 0,
    offsetY: 0,
    scaleX: 1,
    scaleY: 0.85,
    opacity: 0.30,
    family: family,
    footprint: StaticShadowFootprintConfig(
      anchorXRatio: 0.5,
      anchorYRatio: 0.92,
      footprintWidthRatio: 0.82,
      footprintHeightRatio: 0.12,
    ),
  );
}

void _expectConfig(
  ProjectElementShadowConfig config, {
  required String profileId,
  required double scaleX,
  required double scaleY,
  required double opacity,
  required StaticShadowFamily family,
  required double anchorXRatio,
  required double anchorYRatio,
  required double footprintWidthRatio,
  required double footprintHeightRatio,
}) {
  expect(config.castsShadow, isTrue);
  expect(config.shadowProfileId, profileId);
  expect(config.offsetX, 0);
  expect(config.offsetY, 0);
  expect(config.scaleX, closeTo(scaleX, 0.0000001));
  expect(config.scaleY, closeTo(scaleY, 0.0000001));
  expect(config.opacity, closeTo(opacity, 0.0000001));
  expect(config.family, family);
  expect(config.footprint!.anchorXRatio, closeTo(anchorXRatio, 0.0000001));
  expect(config.footprint!.anchorYRatio, closeTo(anchorYRatio, 0.0000001));
  expect(
    config.footprint!.footprintWidthRatio,
    closeTo(footprintWidthRatio, 0.0000001),
  );
  expect(
    config.footprint!.footprintHeightRatio,
    closeTo(footprintHeightRatio, 0.0000001),
  );
}

double _projectedAreaForShadow(
  ProjectElementShadowConfig shadow, {
  required double visualWidth,
  required double visualHeight,
  StaticShadowProjectionSpec? projectionSpec,
}) {
  final metrics = StaticShadowVisualMetrics(
    left: 0,
    top: 0,
    visualWidth: visualWidth,
    visualHeight: visualHeight,
  );
  final geometry = resolveStaticShadowGeometry(
    metrics: metrics,
    shadowConfig: ResolvedShadowConfig(
      shadowProfileId: shadow.shadowProfileId!,
      mode: ShadowCasterMode.ellipse,
      renderPass: ShadowRenderPass.groundStatic,
      offsetX: shadow.offsetX ?? 0,
      offsetY: shadow.offsetY ?? 0,
      scaleX: shadow.scaleX ?? 1,
      scaleY: shadow.scaleY ?? 1,
      opacity: shadow.opacity ?? 0.35,
      colorHexRgb: '000000',
      softnessMode: ShadowSoftnessMode.hardEdge,
    ),
    elementFootprint: shadow.footprint,
  );
  final projected = resolveProjectedStaticShadowGeometry(
    baseGeometry: geometry,
    metrics: metrics,
    projectionSpec: projectionSpec ??
        resolveStaticShadowFamilyProjectionSpec(
          family: shadow.family ?? StaticShadowFamily.genericProjection,
        ),
  );
  return _projectedPolygonArea(projected.points);
}

StaticShadowProjectionSpec _legacyBuildingProjectionSpec() {
  return StaticShadowProjectionSpec(
    directionX: defaultStaticShadowProjectionDirectionX,
    directionY: defaultStaticShadowProjectionDirectionY,
    lengthRatio: 0.1984,
    nearWidthMultiplier: 0.7176,
    farWidthMultiplier: 0.7316,
  );
}

double _projectedPolygonArea(List<ProjectedStaticShadowPoint> points) {
  var area = 0.0;
  for (var index = 0; index < points.length; index += 1) {
    final current = points[index];
    final next = points[(index + 1) % points.length];
    area += current.x * next.y - next.x * current.y;
  }
  return area.abs() / 2;
}

```


## 24. Focused Diff

```diff
diff --git a/packages/map_core/lib/src/operations/element_auto_shadow_policy.dart b/packages/map_core/lib/src/operations/element_auto_shadow_policy.dart
index 894cf357..24086e3f 100644
--- a/packages/map_core/lib/src/operations/element_auto_shadow_policy.dart
+++ b/packages/map_core/lib/src/operations/element_auto_shadow_policy.dart
@@ -235,12 +235,17 @@ ElementAutoShadowSuggestionKind _classifyElement({
 }) {
   final area = width * height;
   final aspect = height / width;
-  if (aspect >= 2.2 && width <= 2) {
+  final wideAspect = width / height;
+  if ((aspect >= 2.2 && width <= 2) ||
+      (width <= 3 && height >= 5 && aspect >= 1.4)) {
     return ElementAutoShadowSuggestionKind.tallThin;
   }
   if (width >= 3 && height <= 2) {
     return ElementAutoShadowSuggestionKind.wideLow;
   }
+  if (width >= 4 && height <= 6 && wideAspect >= 2.0) {
+    return ElementAutoShadowSuggestionKind.wideLow;
+  }
   if (width >= 4 || area >= 12) {
     return ElementAutoShadowSuggestionKind.buildingLarge;
   }
@@ -347,15 +352,15 @@ ProjectElementShadowConfig _configForKind(
         shadowProfileId: profileId,
         offsetX: 0,
         offsetY: 0,
-        scaleX: 1,
-        scaleY: 1,
-        opacity: 0.28,
+        scaleX: 0.80,
+        scaleY: 0.55,
+        opacity: 0.20,
         family: StaticShadowFamily.tallProp,
         footprint: StaticShadowFootprintConfig(
           anchorXRatio: 0.5,
           anchorYRatio: 1.0,
-          footprintWidthRatio: 0.18,
-          footprintHeightRatio: 0.07,
+          footprintWidthRatio: 0.28,
+          footprintHeightRatio: 0.05,
         ),
       );
     case ElementAutoShadowSuggestionKind.buildingLarge:
@@ -364,15 +369,15 @@ ProjectElementShadowConfig _configForKind(
         shadowProfileId: profileId,
         offsetX: 0,
         offsetY: 0,
-        scaleX: 1,
-        scaleY: 0.85,
-        opacity: 0.30,
+        scaleX: 0.72,
+        scaleY: 0.48,
+        opacity: 0.20,
         family: StaticShadowFamily.building,
         footprint: StaticShadowFootprintConfig(
           anchorXRatio: 0.5,
-          anchorYRatio: 0.92,
-          footprintWidthRatio: 0.82,
-          footprintHeightRatio: 0.12,
+          anchorYRatio: 0.98,
+          footprintWidthRatio: 0.60,
+          footprintHeightRatio: 0.06,
         ),
       );
     case ElementAutoShadowSuggestionKind.wideLow:
@@ -381,15 +386,15 @@ ProjectElementShadowConfig _configForKind(
         shadowProfileId: profileId,
         offsetX: 0,
         offsetY: 0,
-        scaleX: 0.92,
-        scaleY: 0.75,
-        opacity: 0.27,
+        scaleX: 0.74,
+        scaleY: 0.50,
+        opacity: 0.20,
         family: StaticShadowFamily.compactProp,
         footprint: StaticShadowFootprintConfig(
           anchorXRatio: 0.5,
-          anchorYRatio: 0.95,
-          footprintWidthRatio: 0.72,
-          footprintHeightRatio: 0.10,
+          anchorYRatio: 0.98,
+          footprintWidthRatio: 0.58,
+          footprintHeightRatio: 0.06,
         ),
       );
     case ElementAutoShadowSuggestionKind.smallSquare:
@@ -470,7 +475,8 @@ bool _isRecognizedAutoShadow(
   return _canReplaceExistingShadow(shadow, catalog) ||
       shadow == _oldAutoSmallSquareShadow() ||
       shadow == _oldAutoDefaultPropShadow() ||
-      shadow == _oldAutoWideLowShadow();
+      shadow == _oldAutoWideLowShadow() ||
+      _isLegacyBroadSelbrumeAutoShadow(shadow);
 }
 
 bool _canReplaceExistingShadow(
@@ -558,6 +564,31 @@ ProjectElementShadowConfig _oldAutoWideLowShadow() {
   );
 }
 
+bool _isLegacyBroadSelbrumeAutoShadow(ProjectElementShadowConfig shadow) {
+  if (!shadow.castsShadow ||
+      shadow.shadowProfileId != 'default-ground-wide-ellipse' ||
+      shadow.offsetX != 0 ||
+      shadow.offsetY != 0 ||
+      shadow.scaleX != 1 ||
+      shadow.scaleY != 0.85 ||
+      shadow.opacity != 0.30) {
+    return false;
+  }
+  final family = shadow.family;
+  if (family != null &&
+      family != StaticShadowFamily.building &&
+      family != StaticShadowFamily.compactProp) {
+    return false;
+  }
+  return shadow.footprint ==
+      StaticShadowFootprintConfig(
+        anchorXRatio: 0.5,
+        anchorYRatio: 0.92,
+        footprintWidthRatio: 0.82,
+        footprintHeightRatio: 0.12,
+      );
+}
+
 const _defaultGroundStaticProfileIds = <String>{
   'default-ground-soft-ellipse',
   'default-ground-wide-ellipse',
diff --git a/packages/map_core/lib/src/operations/static_shadow_family_projection.dart b/packages/map_core/lib/src/operations/static_shadow_family_projection.dart
index 4ef5f7c7..fdcdbda4 100644
--- a/packages/map_core/lib/src/operations/static_shadow_family_projection.dart
+++ b/packages/map_core/lib/src/operations/static_shadow_family_projection.dart
@@ -1,6 +1,22 @@
 import '../models/shadow.dart';
 import 'static_shadow_projection_geometry.dart';
 
+const _compactPropLengthRatio = 0.0704;
+const _compactPropNearWidthMultiplier = 0.3312;
+const _compactPropFarWidthMultiplier = 0.2832;
+
+const _tallPropLengthRatio = 0.0704;
+const _tallPropNearWidthMultiplier = 0.2208;
+const _tallPropFarWidthMultiplier = 0.1770;
+
+const _buildingLengthRatio = 0.0832;
+const _buildingNearWidthMultiplier = 0.4416;
+const _buildingFarWidthMultiplier = 0.3422;
+
+const _foliageLengthRatio = 0.0960;
+const _foliageNearWidthMultiplier = 0.5060;
+const _foliageFarWidthMultiplier = 0.4720;
+
 StaticShadowFamily resolveStaticShadowFamily({
   StaticShadowFamily? elementFamily,
   StaticShadowFamily? overrideFamily,
@@ -19,49 +35,53 @@ StaticShadowProjectionSpec resolveStaticShadowFamilyProjectionSpec({
     case StaticShadowFamily.genericProjection:
       return baseProjectionSpec;
     case StaticShadowFamily.compactProp:
-      return _scaledProjectionSpec(
+      return _calibratedProjectionSpec(
         baseProjectionSpec,
-        lengthRatioScale: 0.38,
-        nearWidthMultiplierScale: 0.58,
-        farWidthMultiplierScale: 0.44,
+        defaultLengthRatio: _compactPropLengthRatio,
+        defaultNearWidthMultiplier: _compactPropNearWidthMultiplier,
+        defaultFarWidthMultiplier: _compactPropFarWidthMultiplier,
       );
     case StaticShadowFamily.tallProp:
-      return _scaledProjectionSpec(
+      return _calibratedProjectionSpec(
         baseProjectionSpec,
-        lengthRatioScale: 0.48,
-        nearWidthMultiplierScale: 0.32,
-        farWidthMultiplierScale: 0.28,
+        defaultLengthRatio: _tallPropLengthRatio,
+        defaultNearWidthMultiplier: _tallPropNearWidthMultiplier,
+        defaultFarWidthMultiplier: _tallPropFarWidthMultiplier,
       );
     case StaticShadowFamily.building:
-      return _scaledProjectionSpec(
+      return _calibratedProjectionSpec(
         baseProjectionSpec,
-        lengthRatioScale: 0.62,
-        nearWidthMultiplierScale: 0.78,
-        farWidthMultiplierScale: 0.62,
+        defaultLengthRatio: _buildingLengthRatio,
+        defaultNearWidthMultiplier: _buildingNearWidthMultiplier,
+        defaultFarWidthMultiplier: _buildingFarWidthMultiplier,
       );
     case StaticShadowFamily.foliage:
-      return _scaledProjectionSpec(
+      return _calibratedProjectionSpec(
         baseProjectionSpec,
-        lengthRatioScale: 0.45,
-        nearWidthMultiplierScale: 0.72,
-        farWidthMultiplierScale: 0.70,
+        defaultLengthRatio: _foliageLengthRatio,
+        defaultNearWidthMultiplier: _foliageNearWidthMultiplier,
+        defaultFarWidthMultiplier: _foliageFarWidthMultiplier,
       );
   }
 }
 
-StaticShadowProjectionSpec _scaledProjectionSpec(
+StaticShadowProjectionSpec _calibratedProjectionSpec(
   StaticShadowProjectionSpec baseProjectionSpec, {
-  required double lengthRatioScale,
-  required double nearWidthMultiplierScale,
-  required double farWidthMultiplierScale,
+  required double defaultLengthRatio,
+  required double defaultNearWidthMultiplier,
+  required double defaultFarWidthMultiplier,
 }) {
   return StaticShadowProjectionSpec(
     directionX: baseProjectionSpec.directionX,
     directionY: baseProjectionSpec.directionY,
-    lengthRatio: baseProjectionSpec.lengthRatio * lengthRatioScale,
-    nearWidthMultiplier:
-        baseProjectionSpec.nearWidthMultiplier * nearWidthMultiplierScale,
-    farWidthMultiplier:
-        baseProjectionSpec.farWidthMultiplier * farWidthMultiplierScale,
+    lengthRatio: baseProjectionSpec.lengthRatio *
+        defaultLengthRatio /
+        defaultStaticShadowProjectionLengthRatio,
+    nearWidthMultiplier: baseProjectionSpec.nearWidthMultiplier *
+        defaultNearWidthMultiplier /
+        defaultStaticShadowProjectionNearWidthMultiplier,
+    farWidthMultiplier: baseProjectionSpec.farWidthMultiplier *
+        defaultFarWidthMultiplier /
+        defaultStaticShadowProjectionFarWidthMultiplier,
   );
 }
diff --git a/packages/map_core/test/shadow/element_auto_shadow_policy_test.dart b/packages/map_core/test/shadow/element_auto_shadow_policy_test.dart
index 65da6c1b..c91ca269 100644
--- a/packages/map_core/test/shadow/element_auto_shadow_policy_test.dart
+++ b/packages/map_core/test/shadow/element_auto_shadow_policy_test.dart
@@ -52,6 +52,90 @@ void main() {
       expect(building!.kind, ElementAutoShadowSuggestionKind.buildingLarge);
       expect(building.config.family, StaticShadowFamily.building);
     });
+
+    test('Selbrume lamp proportions receive calibrated tall thin config', () {
+      final suggestion = buildElementAutoShadowSuggestion(
+        element: _element(id: 'lampadaire', width: 3, height: 5),
+        shadowCatalog: _defaultCatalog(),
+      );
+
+      expect(suggestion!.kind, ElementAutoShadowSuggestionKind.tallThin);
+      _expectConfig(
+        suggestion.config,
+        profileId: 'default-ground-contact-blob',
+        scaleX: 0.80,
+        scaleY: 0.55,
+        opacity: 0.20,
+        family: StaticShadowFamily.tallProp,
+        anchorXRatio: 0.5,
+        anchorYRatio: 1.0,
+        footprintWidthRatio: 0.28,
+        footprintHeightRatio: 0.05,
+      );
+    });
+
+    test('Selbrume wide barriers stay wide low instead of building', () {
+      final suggestion = buildElementAutoShadowSuggestion(
+        element: _element(id: 'barriere_pierre', width: 13, height: 6),
+        shadowCatalog: _defaultCatalog(),
+      );
+
+      expect(suggestion!.kind, ElementAutoShadowSuggestionKind.wideLow);
+      _expectConfig(
+        suggestion.config,
+        profileId: 'default-ground-wide-ellipse',
+        scaleX: 0.74,
+        scaleY: 0.50,
+        opacity: 0.20,
+        family: StaticShadowFamily.compactProp,
+        anchorXRatio: 0.5,
+        anchorYRatio: 0.98,
+        footprintWidthRatio: 0.58,
+        footprintHeightRatio: 0.06,
+      );
+    });
+
+    test('Selbrume houses receive calibrated building config', () {
+      final suggestion = buildElementAutoShadowSuggestion(
+        element: _element(id: 'maison', width: 6, height: 7),
+        shadowCatalog: _defaultCatalog(),
+      );
+
+      expect(suggestion!.kind, ElementAutoShadowSuggestionKind.buildingLarge);
+      _expectConfig(
+        suggestion.config,
+        profileId: 'default-ground-wide-ellipse',
+        scaleX: 0.72,
+        scaleY: 0.48,
+        opacity: 0.20,
+        family: StaticShadowFamily.building,
+        anchorXRatio: 0.5,
+        anchorYRatio: 0.98,
+        footprintWidthRatio: 0.60,
+        footprintHeightRatio: 0.06,
+      );
+    });
+
+    test('V1 building auto config projects far less area than legacy broad',
+        () {
+      final legacy = _projectedAreaForShadow(
+        _legacyBroadSelbrumeShadow(family: StaticShadowFamily.building),
+        visualWidth: 192,
+        visualHeight: 224,
+        projectionSpec: _legacyBuildingProjectionSpec(),
+      );
+      final suggestion = buildElementAutoShadowSuggestion(
+        element: _element(id: 'maison', width: 6, height: 7),
+        shadowCatalog: _defaultCatalog(),
+      )!;
+      final v1 = _projectedAreaForShadow(
+        suggestion.config,
+        visualWidth: 192,
+        visualHeight: 224,
+      );
+
+      expect(v1, lessThan(legacy * 0.30));
+    });
   });
 
   group('applyElementAutoShadowPolicyToProject', () {
@@ -131,6 +215,78 @@ void main() {
       expect(result.project.elements[0].shadow, manual);
       expect(result.project.elements[1].shadow, disabled);
     });
+
+    test('backfill replaces broad legacy Selbrume shadow without family', () {
+      final result = applyElementAutoShadowPolicyToProject(
+        _project(
+          elements: [
+            _element(
+              id: 'lampadaire',
+              width: 3,
+              height: 5,
+              shadow: _legacyBroadSelbrumeShadow(),
+            ),
+          ],
+          shadowCatalog: _defaultCatalog(),
+        ),
+      );
+
+      expect(result.appliedCount, 1);
+      expect(result.changedCount, 1);
+      expect(
+        result.entries.single.status,
+        ElementAutoShadowBackfillStatus.appliedGeneric,
+      );
+      _expectConfig(
+        result.project.elements.single.shadow!,
+        profileId: 'default-ground-contact-blob',
+        scaleX: 0.80,
+        scaleY: 0.55,
+        opacity: 0.20,
+        family: StaticShadowFamily.tallProp,
+        anchorXRatio: 0.5,
+        anchorYRatio: 1.0,
+        footprintWidthRatio: 0.28,
+        footprintHeightRatio: 0.05,
+      );
+    });
+
+    test('backfill replaces broad legacy Selbrume building shadow', () {
+      final result = applyElementAutoShadowPolicyToProject(
+        _project(
+          elements: [
+            _element(
+              id: 'maison',
+              width: 6,
+              height: 7,
+              shadow: _legacyBroadSelbrumeShadow(
+                family: StaticShadowFamily.building,
+              ),
+            ),
+          ],
+          shadowCatalog: _defaultCatalog(),
+        ),
+      );
+
+      expect(result.appliedCount, 1);
+      expect(result.changedCount, 1);
+      expect(
+        result.entries.single.status,
+        ElementAutoShadowBackfillStatus.appliedGeneric,
+      );
+      _expectConfig(
+        result.project.elements.single.shadow!,
+        profileId: 'default-ground-wide-ellipse',
+        scaleX: 0.72,
+        scaleY: 0.48,
+        opacity: 0.20,
+        family: StaticShadowFamily.building,
+        anchorXRatio: 0.5,
+        anchorYRatio: 0.98,
+        footprintWidthRatio: 0.60,
+        footprintHeightRatio: 0.06,
+      );
+    });
   });
 }
 
@@ -201,3 +357,115 @@ ProjectElementShadowConfig _oldAutoSmallSquareShadow() {
     ),
   );
 }
+
+ProjectElementShadowConfig _legacyBroadSelbrumeShadow({
+  StaticShadowFamily? family,
+}) {
+  return ProjectElementShadowConfig(
+    castsShadow: true,
+    shadowProfileId: 'default-ground-wide-ellipse',
+    offsetX: 0,
+    offsetY: 0,
+    scaleX: 1,
+    scaleY: 0.85,
+    opacity: 0.30,
+    family: family,
+    footprint: StaticShadowFootprintConfig(
+      anchorXRatio: 0.5,
+      anchorYRatio: 0.92,
+      footprintWidthRatio: 0.82,
+      footprintHeightRatio: 0.12,
+    ),
+  );
+}
+
+void _expectConfig(
+  ProjectElementShadowConfig config, {
+  required String profileId,
+  required double scaleX,
+  required double scaleY,
+  required double opacity,
+  required StaticShadowFamily family,
+  required double anchorXRatio,
+  required double anchorYRatio,
+  required double footprintWidthRatio,
+  required double footprintHeightRatio,
+}) {
+  expect(config.castsShadow, isTrue);
+  expect(config.shadowProfileId, profileId);
+  expect(config.offsetX, 0);
+  expect(config.offsetY, 0);
+  expect(config.scaleX, closeTo(scaleX, 0.0000001));
+  expect(config.scaleY, closeTo(scaleY, 0.0000001));
+  expect(config.opacity, closeTo(opacity, 0.0000001));
+  expect(config.family, family);
+  expect(config.footprint!.anchorXRatio, closeTo(anchorXRatio, 0.0000001));
+  expect(config.footprint!.anchorYRatio, closeTo(anchorYRatio, 0.0000001));
+  expect(
+    config.footprint!.footprintWidthRatio,
+    closeTo(footprintWidthRatio, 0.0000001),
+  );
+  expect(
+    config.footprint!.footprintHeightRatio,
+    closeTo(footprintHeightRatio, 0.0000001),
+  );
+}
+
+double _projectedAreaForShadow(
+  ProjectElementShadowConfig shadow, {
+  required double visualWidth,
+  required double visualHeight,
+  StaticShadowProjectionSpec? projectionSpec,
+}) {
+  final metrics = StaticShadowVisualMetrics(
+    left: 0,
+    top: 0,
+    visualWidth: visualWidth,
+    visualHeight: visualHeight,
+  );
+  final geometry = resolveStaticShadowGeometry(
+    metrics: metrics,
+    shadowConfig: ResolvedShadowConfig(
+      shadowProfileId: shadow.shadowProfileId!,
+      mode: ShadowCasterMode.ellipse,
+      renderPass: ShadowRenderPass.groundStatic,
+      offsetX: shadow.offsetX ?? 0,
+      offsetY: shadow.offsetY ?? 0,
+      scaleX: shadow.scaleX ?? 1,
+      scaleY: shadow.scaleY ?? 1,
+      opacity: shadow.opacity ?? 0.35,
+      colorHexRgb: '000000',
+      softnessMode: ShadowSoftnessMode.hardEdge,
+    ),
+    elementFootprint: shadow.footprint,
+  );
+  final projected = resolveProjectedStaticShadowGeometry(
+    baseGeometry: geometry,
+    metrics: metrics,
+    projectionSpec: projectionSpec ??
+        resolveStaticShadowFamilyProjectionSpec(
+          family: shadow.family ?? StaticShadowFamily.genericProjection,
+        ),
+  );
+  return _projectedPolygonArea(projected.points);
+}
+
+StaticShadowProjectionSpec _legacyBuildingProjectionSpec() {
+  return StaticShadowProjectionSpec(
+    directionX: defaultStaticShadowProjectionDirectionX,
+    directionY: defaultStaticShadowProjectionDirectionY,
+    lengthRatio: 0.1984,
+    nearWidthMultiplier: 0.7176,
+    farWidthMultiplier: 0.7316,
+  );
+}
+
+double _projectedPolygonArea(List<ProjectedStaticShadowPoint> points) {
+  var area = 0.0;
+  for (var index = 0; index < points.length; index += 1) {
+    final current = points[index];
+    final next = points[(index + 1) % points.length];
+    area += current.x * next.y - next.x * current.y;
+  }
+  return area.abs() / 2;
+}
diff --git a/packages/map_core/test/shadow/static_shadow_family_projection_test.dart b/packages/map_core/test/shadow/static_shadow_family_projection_test.dart
index d51fbeff..fc04a293 100644
--- a/packages/map_core/test/shadow/static_shadow_family_projection_test.dart
+++ b/packages/map_core/test/shadow/static_shadow_family_projection_test.dart
@@ -158,44 +158,52 @@ void main() {
       );
     });
 
-    test('compactProp V0 constants are stable', () {
+    test('compactProp V1 calibration is short and tapered', () {
       final spec = resolveStaticShadowFamilyProjectionSpec(
         family: StaticShadowFamily.compactProp,
       );
 
-      expect(spec.lengthRatio, closeTo(0.1216, 0.0000001));
-      expect(spec.nearWidthMultiplier, closeTo(0.5336, 0.0000001));
-      expect(spec.farWidthMultiplier, closeTo(0.5192, 0.0000001));
+      expect(spec.lengthRatio, closeTo(0.0704, 0.0000001));
+      expect(spec.nearWidthMultiplier, closeTo(0.3312, 0.0000001));
+      expect(spec.farWidthMultiplier, closeTo(0.2832, 0.0000001));
+      expect(spec.farWidthMultiplier, lessThan(spec.nearWidthMultiplier));
     });
 
-    test('tallProp V0 constants are stable', () {
+    test('tallProp V1 calibration is very narrow and short', () {
       final spec = resolveStaticShadowFamilyProjectionSpec(
         family: StaticShadowFamily.tallProp,
       );
 
-      expect(spec.lengthRatio, closeTo(0.1536, 0.0000001));
-      expect(spec.nearWidthMultiplier, closeTo(0.2944, 0.0000001));
-      expect(spec.farWidthMultiplier, closeTo(0.3304, 0.0000001));
+      expect(spec.lengthRatio, closeTo(0.0704, 0.0000001));
+      expect(spec.nearWidthMultiplier, closeTo(0.2208, 0.0000001));
+      expect(spec.farWidthMultiplier, closeTo(0.1770, 0.0000001));
+      expect(spec.farWidthMultiplier, lessThan(spec.nearWidthMultiplier));
     });
 
-    test('building V0 constants are stable', () {
+    test('building V1 calibration avoids broad slabs', () {
       final spec = resolveStaticShadowFamilyProjectionSpec(
         family: StaticShadowFamily.building,
       );
 
-      expect(spec.lengthRatio, closeTo(0.1984, 0.0000001));
-      expect(spec.nearWidthMultiplier, closeTo(0.7176, 0.0000001));
-      expect(spec.farWidthMultiplier, closeTo(0.7316, 0.0000001));
+      expect(spec.lengthRatio, closeTo(0.0832, 0.0000001));
+      expect(spec.nearWidthMultiplier, closeTo(0.4416, 0.0000001));
+      expect(spec.farWidthMultiplier, closeTo(0.3422, 0.0000001));
+      expect(spec.farWidthMultiplier, lessThan(spec.nearWidthMultiplier));
     });
 
-    test('foliage V0 constants are stable', () {
+    test('foliage V1 calibration is restrained but broader than tall props',
+        () {
       final spec = resolveStaticShadowFamilyProjectionSpec(
         family: StaticShadowFamily.foliage,
       );
+      final tall = resolveStaticShadowFamilyProjectionSpec(
+        family: StaticShadowFamily.tallProp,
+      );
 
-      expect(spec.lengthRatio, closeTo(0.144, 0.0000001));
-      expect(spec.nearWidthMultiplier, closeTo(0.6624, 0.0000001));
-      expect(spec.farWidthMultiplier, closeTo(0.826, 0.0000001));
+      expect(spec.lengthRatio, closeTo(0.0960, 0.0000001));
+      expect(spec.nearWidthMultiplier, closeTo(0.5060, 0.0000001));
+      expect(spec.farWidthMultiplier, closeTo(0.4720, 0.0000001));
+      expect(spec.nearWidthMultiplier, greaterThan(tall.nearWidthMultiplier));
     });
 
     test('scaled family specs remain valid for a custom positive base', () {
@@ -261,6 +269,48 @@ void main() {
 
       expect(_polygonArea(compact), lessThan(_polygonArea(generic)));
     });
+
+    test('building V1 projected geometry stays compact for a Selbrume house',
+        () {
+      final geometry = _projectedCase(
+        family: StaticShadowFamily.building,
+        visualWidth: 192,
+        visualHeight: 224,
+        footprintWidthRatio: 0.60 * 0.72,
+        footprintHeightRatio: 0.06 * 0.48,
+      );
+
+      expect(_projectedLength(geometry), lessThan(20));
+      expect(_maxWidth(geometry), lessThan(40));
+      expect(_polygonArea(geometry), lessThan(700));
+    });
+
+    test('building V1 projected area is far smaller than legacy Selbrume slab',
+        () {
+      final v1 = _projectedCase(
+        family: StaticShadowFamily.building,
+        visualWidth: 192,
+        visualHeight: 224,
+        footprintWidthRatio: 0.60 * 0.72,
+        footprintHeightRatio: 0.06 * 0.48,
+      );
+      final legacy = _projectedCase(
+        family: StaticShadowFamily.building,
+        visualWidth: 192,
+        visualHeight: 224,
+        footprintWidthRatio: 0.82,
+        footprintHeightRatio: 0.12 * 0.85,
+        projectionSpec: StaticShadowProjectionSpec(
+          directionX: defaultStaticShadowProjectionDirectionX,
+          directionY: defaultStaticShadowProjectionDirectionY,
+          lengthRatio: 0.1984,
+          nearWidthMultiplier: 0.7176,
+          farWidthMultiplier: 0.7316,
+        ),
+      );
+
+      expect(_polygonArea(v1), lessThan(_polygonArea(legacy) * 0.30));
+    });
   });
 }
 
@@ -270,6 +320,7 @@ ProjectedStaticShadowGeometry _projectedCase({
   required double visualHeight,
   required double footprintWidthRatio,
   required double footprintHeightRatio,
+  StaticShadowProjectionSpec? projectionSpec,
 }) {
   final metrics = StaticShadowVisualMetrics(
     left: 0,
@@ -302,7 +353,8 @@ ProjectedStaticShadowGeometry _projectedCase({
   return resolveProjectedStaticShadowGeometry(
     baseGeometry: baseGeometry,
     metrics: metrics,
-    projectionSpec: resolveStaticShadowFamilyProjectionSpec(family: family),
+    projectionSpec: projectionSpec ??
+        resolveStaticShadowFamilyProjectionSpec(family: family),
   );
 }
 
@@ -313,6 +365,22 @@ double _maxWidth(ProjectedStaticShadowGeometry geometry) {
   ].reduce((first, second) => first > second ? first : second);
 }
 
+double _projectedLength(ProjectedStaticShadowGeometry geometry) {
+  final near = _midpoint(geometry.nearLeft, geometry.nearRight);
+  final far = _midpoint(geometry.farLeft, geometry.farRight);
+  return _distance(near, far);
+}
+
+ProjectedStaticShadowPoint _midpoint(
+  ProjectedStaticShadowPoint first,
+  ProjectedStaticShadowPoint second,
+) {
+  return ProjectedStaticShadowPoint(
+    x: (first.x + second.x) / 2,
+    y: (first.y + second.y) / 2,
+  );
+}
+
 double _distance(
   ProjectedStaticShadowPoint first,
   ProjectedStaticShadowPoint second,
```
