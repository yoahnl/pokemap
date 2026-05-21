# Shadow-41 Static Shadow Family Model / Style V0 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Repository rule wins over generic plan guidance: do not commit unless the user explicitly asks after implementation.

**Goal:** Add a persistent, JSON-compatible static shadow family/style field so source elements and custom instance overrides can declare what kind of static object shadow they need before the geometry and renderer consume it.

**Architecture:** Keep `ProjectShadowProfile` as shared visual style only. Add the shadow family to `ProjectElementShadowConfig` as the source-element default and to `MapPlacedElementShadowOverride` as a custom per-instance exception, mirroring the footprint model from Shadow-27. Update the existing auto-shadow suggestions so the automatic path starts writing semantic families without touching runtime, editor canvas, Flame, or rendering in this lot.

**Tech Stack:** Dart, Flutter tests for `map_editor`, pure Dart tests for `map_core`, manual JSON codecs, no `build_runner`.

---

## 1. Current Audit

### Existing Shadow Model

Relevant file:

```text
packages/map_core/lib/src/models/shadow.dart
```

Current shape:

```dart
enum ShadowCasterMode {
  none,
  contactBlob,
  ellipse,
}

final class ProjectElementShadowConfig {
  ProjectElementShadowConfig({
    this.castsShadow = false,
    this.shadowProfileId,
    this.offsetX,
    this.offsetY,
    this.scaleX,
    this.scaleY,
    this.opacity,
    this.footprint,
  });
}

final class MapPlacedElementShadowOverride {
  MapPlacedElementShadowOverride({
    this.mode = ShadowOverrideMode.inherit,
    this.shadowProfileId,
    this.offsetX,
    this.offsetY,
    this.scaleX,
    this.scaleY,
    this.opacity,
    this.footprint,
  });
}
```

The existing model can tune footprint and numeric values, but cannot say "this object is a building" or "this object is a tall prop". That is why the same projection logic still produces visually generic shapes.

### Existing Geometry

Relevant files:

```text
packages/map_core/lib/src/operations/static_shadow_geometry.dart
packages/map_core/lib/src/operations/static_shadow_projection_geometry.dart
```

Current behavior:

- `resolveStaticShadowGeometry(...)` resolves anchor and footprint.
- `resolveProjectedStaticShadowGeometry(...)` creates one generic projected quadrilateral from the resolved footprint.
- The projection has one global default spec:

```dart
const defaultStaticShadowProjectionDirectionX = 1.0;
const defaultStaticShadowProjectionDirectionY = 0.45;
const defaultStaticShadowProjectionLengthRatio = 0.32;
const defaultStaticShadowProjectionNearWidthMultiplier = 0.92;
const defaultStaticShadowProjectionFarWidthMultiplier = 1.18;
```

This is useful as a shared base, but it is still one-size-fits-all.

### Existing Automatic Authoring

Relevant file:

```text
packages/map_editor/lib/src/application/shadow/element_auto_shadow_suggestion.dart
```

Current kinds:

```dart
enum ElementAutoShadowSuggestionKind {
  tallThin,
  buildingLarge,
  wideLow,
  smallSquare,
  defaultProp,
}
```

Current suggestions already choose:

- profile id;
- offset;
- scale;
- opacity;
- `StaticShadowFootprintConfig`.

They do not yet write a semantic shadow family.

### Flame Documentation Check

Shadow-41 is not a Flame implementation lot. It must not modify:

```text
packages/map_runtime/**
packages/map_editor/lib/src/ui/canvas/**
```

The Flame MCP documentation search was attempted for render/component topics and returned no matching entries. For this lot, that is not blocking because no Flame APIs are used. The first future runtime/rendering lot that consumes the family must re-run `flame_docs` and document the relevant Flame rendering facts.

### Pre-existing Worktree State To Preserve

At plan creation time, these entries were already present and are outside Shadow-41:

```text
 M AGENTS.md
 M packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart
 M packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart
 M packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
 M packages/map_editor/test/ui/canvas/editor_static_shadow_preview_painter_test.dart
?? reports/analysis/psdk_fight_100_percent_lot_plan_2026-05-16.md
?? reports/analysis/psdk_fight_parity_audit_2026-05-16.md
?? reports/shadows/shadow_lot_38_editor_static_projected_shadow_preview.md
?? reports/shadows/shadow_lot_38_editor_static_projected_shadow_preview_plan.md
```

Shadow-41 must not edit those files unless explicitly called out by a later implementation prompt.

---

## 2. Lot Scope Decision

Shadow-41 should do this:

```text
Static Shadow Family Model / Style V0
```

Meaning:

1. Add a pure `map_core` enum describing static shadow family.
2. Persist that family in element shadow configs.
3. Persist that family in custom placed-instance overrides.
4. Update manual JSON codecs.
5. Update auto-shadow suggestions so automatic authoring starts setting family.
6. Test model, JSON, and suggestion behavior.
7. Produce an implementation report.

Shadow-41 should not do this:

```text
runtime geometry consumption
editor canvas consumption
new painter
new Flame component
new UI fields
time-of-day
global light model
blur
asset/sprite shadows
build_runner
```

Visible shadows may not change after Shadow-41. That is expected. Shadow-41 creates the data needed for Shadow-42 and Shadow-43 to make the visual difference.

---

## 3. Recommended Model

Add this enum in:

```text
packages/map_core/lib/src/models/shadow.dart
```

Recommended location: after `ShadowOverrideMode`.

```dart
enum StaticShadowFamily {
  genericProjection,
  compactProp,
  tallProp,
  building,
  foliage,
}
```

Semantics:

```text
genericProjection
  Backward-compatible default when no family is set.
  Used for ordinary props until more specific data exists.

compactProp
  Small or low static object.
  Future geometry should stay short, close to the footprint, and less invasive.

tallProp
  Lamp posts, thin signs, poles, narrow objects.
  Future geometry should remain narrow and avoid giant ground slabs.

building
  Houses, market stands, large constructed objects.
  Future geometry should use a broader, more Pokemon-like block/shadow silhouette.

foliage
  Trees, bushes, large vegetation.
  Future geometry can use canopy-aware organic/blocky projection rules.
```

Why an enum:

- stable JSON string values through `.name`;
- easy tests for unknown values;
- no renderer coupling;
- no raw user-entered string;
- no accidental "global light" promise.

Why not in `ProjectShadowProfile`:

- profiles are shared visual styles: mode, render pass, color, opacity, softness;
- one profile can be used by a lamp post and a house, but those objects need different geometry;
- element source and instance override are the correct ownership levels.

---

## 4. File Inventory For Implementation

### Create

```text
packages/map_core/lib/src/operations/static_shadow_family_json_codec.dart
packages/map_core/test/shadow/static_shadow_family_json_codec_test.dart
reports/shadows/shadow_lot_41_static_shadow_family_model_style.md
```

### Modify

```text
packages/map_core/lib/src/models/shadow.dart
packages/map_core/lib/src/operations/project_element_shadow_config_json_codec.dart
packages/map_core/lib/src/operations/map_placed_element_shadow_override_json_codec.dart
packages/map_core/lib/map_core.dart
packages/map_core/test/shadow/project_element_shadow_config_test.dart
packages/map_core/test/shadow/map_placed_element_shadow_override_test.dart
packages/map_core/test/shadow/project_element_shadow_config_json_codec_test.dart
packages/map_core/test/shadow/map_placed_element_shadow_override_json_codec_test.dart
packages/map_editor/lib/src/application/shadow/element_auto_shadow_suggestion.dart
packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart
```

### Do Not Modify

```text
packages/map_runtime/**
packages/map_gameplay/**
packages/map_battle/**
packages/map_editor/lib/src/ui/canvas/**
packages/map_editor/lib/src/ui/panels/**
packages/map_editor/lib/src/features/editor/state/**
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/models/map_data.dart
*.g.dart
*.freezed.dart
```

---

## 5. JSON Format

Use key:

```json
{
  "family": "building"
}
```

Rules:

```text
family absent -> null
family null -> null
family valid string -> StaticShadowFamily
family unknown string -> ValidationException
family non-string -> ValidationException
encode null -> omit key
encode non-null -> write family.name
old JSON without family -> still decodes
unknown JSON keys -> still ignored
```

For `MapPlacedElementShadowOverride`:

```text
family non-null is allowed only when mode == custom.
inherit/disabled + family must throw ValidationException through the model.
```

For `ProjectElementShadowConfig`:

```text
castsShadow false + family is allowed.
```

Reason: this matches the footprint decision. Disabled source configs may preserve authoring values without forcing destructive cleanup when toggled off.

---

## 6. Implementation Tasks

### Task 1: Add Core Family Enum And Model Fields

**Files:**

- Modify: `packages/map_core/lib/src/models/shadow.dart`
- Test: `packages/map_core/test/shadow/project_element_shadow_config_test.dart`
- Test: `packages/map_core/test/shadow/map_placed_element_shadow_override_test.dart`

- [ ] **Step 1: Add focused failing tests for element config**

Add tests similar to:

```dart
test('equality and hashCode include family', () {
  final base = ProjectElementShadowConfig(
    castsShadow: true,
    shadowProfileId: 'profile',
    family: StaticShadowFamily.building,
  );
  final same = ProjectElementShadowConfig(
    castsShadow: true,
    shadowProfileId: 'profile',
    family: StaticShadowFamily.building,
  );
  final different = ProjectElementShadowConfig(
    castsShadow: true,
    shadowProfileId: 'profile',
    family: StaticShadowFamily.tallProp,
  );

  expect(base, same);
  expect(base.hashCode, same.hashCode);
  expect(base, isNot(different));
});

test('castsShadow false can carry family', () {
  final config = ProjectElementShadowConfig(
    family: StaticShadowFamily.compactProp,
  );

  expect(config.castsShadow, isFalse);
  expect(config.family, StaticShadowFamily.compactProp);
});
```

- [ ] **Step 2: Add focused failing tests for placed override**

Add tests similar to:

```dart
test('custom override can carry family', () {
  final override = MapPlacedElementShadowOverride(
    mode: ShadowOverrideMode.custom,
    family: StaticShadowFamily.tallProp,
  );

  expect(override.family, StaticShadowFamily.tallProp);
});

test('inherit and disabled cannot carry family', () {
  expect(
    () => MapPlacedElementShadowOverride(
      family: StaticShadowFamily.building,
    ),
    throwsA(isA<ValidationException>()),
  );
  expect(
    () => MapPlacedElementShadowOverride(
      mode: ShadowOverrideMode.disabled,
      family: StaticShadowFamily.building,
    ),
    throwsA(isA<ValidationException>()),
  );
});

test('equality and hashCode include family', () {
  final base = MapPlacedElementShadowOverride(
    mode: ShadowOverrideMode.custom,
    family: StaticShadowFamily.building,
  );
  final same = MapPlacedElementShadowOverride(
    mode: ShadowOverrideMode.custom,
    family: StaticShadowFamily.building,
  );
  final different = MapPlacedElementShadowOverride(
    mode: ShadowOverrideMode.custom,
    family: StaticShadowFamily.compactProp,
  );

  expect(base, same);
  expect(base.hashCode, same.hashCode);
  expect(base, isNot(different));
});
```

- [ ] **Step 3: Run tests and verify failure**

```bash
cd packages/map_core && dart test test/shadow/project_element_shadow_config_test.dart test/shadow/map_placed_element_shadow_override_test.dart
```

Expected before implementation:

```text
Compilation fails because StaticShadowFamily and family fields do not exist.
```

- [ ] **Step 4: Implement model changes**

In `shadow.dart`, add:

```dart
enum StaticShadowFamily {
  genericProjection,
  compactProp,
  tallProp,
  building,
  foliage,
}
```

Extend `ProjectElementShadowConfig`:

```dart
ProjectElementShadowConfig({
  this.castsShadow = false,
  this.shadowProfileId,
  this.offsetX,
  this.offsetY,
  this.scaleX,
  this.scaleY,
  this.opacity,
  this.family,
  this.footprint,
})
```

Add field:

```dart
final StaticShadowFamily? family;
```

Update equality:

```dart
other.opacity == opacity &&
other.family == family &&
other.footprint == footprint;
```

Update hash:

```dart
int get hashCode => Object.hash(
      castsShadow,
      shadowProfileId,
      offsetX,
      offsetY,
      scaleX,
      scaleY,
      opacity,
      family,
      footprint,
    );
```

Extend `MapPlacedElementShadowOverride`:

```dart
MapPlacedElementShadowOverride({
  this.mode = ShadowOverrideMode.inherit,
  this.shadowProfileId,
  this.offsetX,
  this.offsetY,
  this.scaleX,
  this.scaleY,
  this.opacity,
  this.family,
  this.footprint,
})
```

Add field:

```dart
final StaticShadowFamily? family;
```

Update custom-field guard:

```dart
bool get _hasMapPlacedElementShadowCustomFields =>
    shadowProfileId != null ||
    offsetX != null ||
    offsetY != null ||
    scaleX != null ||
    scaleY != null ||
    opacity != null ||
    family != null ||
    footprint != null;
```

Update equality and hash to include `family`.

- [ ] **Step 5: Run model tests**

```bash
cd packages/map_core && dart test test/shadow/project_element_shadow_config_test.dart test/shadow/map_placed_element_shadow_override_test.dart
```

Expected after implementation:

```text
All tests passed!
```

---

### Task 2: Add Static Shadow Family JSON Codec

**Files:**

- Create: `packages/map_core/lib/src/operations/static_shadow_family_json_codec.dart`
- Modify: `packages/map_core/lib/map_core.dart`
- Test: `packages/map_core/test/shadow/static_shadow_family_json_codec_test.dart`

- [ ] **Step 1: Write failing codec tests**

Create `static_shadow_family_json_codec_test.dart`:

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('StaticShadowFamily JSON codec', () {
    test('encodes null as null', () {
      expect(encodeStaticShadowFamily(null), isNull);
    });

    test('encodes family by stable enum name', () {
      expect(
        encodeStaticShadowFamily(StaticShadowFamily.building),
        'building',
      );
      expect(
        encodeStaticShadowFamily(StaticShadowFamily.tallProp),
        'tallProp',
      );
    });

    test('decodes null as null', () {
      expect(decodeStaticShadowFamily(null), isNull);
    });

    test('decodes valid family names', () {
      expect(
        decodeStaticShadowFamily('genericProjection'),
        StaticShadowFamily.genericProjection,
      );
      expect(
        decodeStaticShadowFamily('compactProp'),
        StaticShadowFamily.compactProp,
      );
      expect(
        decodeStaticShadowFamily('tallProp'),
        StaticShadowFamily.tallProp,
      );
      expect(
        decodeStaticShadowFamily('building'),
        StaticShadowFamily.building,
      );
      expect(
        decodeStaticShadowFamily('foliage'),
        StaticShadowFamily.foliage,
      );
    });

    test('rejects non-string values', () {
      expect(
        () => decodeStaticShadowFamily(42),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects unknown family values', () {
      expect(
        () => decodeStaticShadowFamily('houseButMaybeLater'),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
```

- [ ] **Step 2: Run test and verify failure**

```bash
cd packages/map_core && dart test test/shadow/static_shadow_family_json_codec_test.dart
```

Expected before implementation:

```text
Compilation fails because the codec functions do not exist.
```

- [ ] **Step 3: Implement codec**

Create `static_shadow_family_json_codec.dart`:

```dart
import '../exceptions/map_exceptions.dart';
import '../models/shadow.dart';

String? encodeStaticShadowFamily(StaticShadowFamily? family) {
  return family?.name;
}

StaticShadowFamily? decodeStaticShadowFamily(Object? json) {
  if (json == null) {
    return null;
  }
  if (json is! String) {
    throw ValidationException(
      'StaticShadowFamily JSON must be a String or null, got ${json.runtimeType}',
    );
  }
  for (final family in StaticShadowFamily.values) {
    if (family.name == json) {
      return family;
    }
  }
  throw ValidationException('Unknown StaticShadowFamily "$json"');
}
```

Export it from `packages/map_core/lib/map_core.dart`:

```dart
export 'src/operations/static_shadow_family_json_codec.dart';
```

- [ ] **Step 4: Run codec test**

```bash
cd packages/map_core && dart test test/shadow/static_shadow_family_json_codec_test.dart
```

Expected:

```text
All tests passed!
```

---

### Task 3: Wire Family Into Existing Shadow JSON Codecs

**Files:**

- Modify: `packages/map_core/lib/src/operations/project_element_shadow_config_json_codec.dart`
- Modify: `packages/map_core/lib/src/operations/map_placed_element_shadow_override_json_codec.dart`
- Test: `packages/map_core/test/shadow/project_element_shadow_config_json_codec_test.dart`
- Test: `packages/map_core/test/shadow/map_placed_element_shadow_override_json_codec_test.dart`

- [ ] **Step 1: Add failing ProjectElementShadowConfig JSON tests**

Add cases:

```dart
test('encodes family when present', () {
  final config = ProjectElementShadowConfig(
    castsShadow: true,
    shadowProfileId: 'tree_large',
    family: StaticShadowFamily.building,
  );

  expect(encodeProjectElementShadowConfig(config), <String, Object?>{
    'castsShadow': true,
    'shadowProfileId': 'tree_large',
    'family': 'building',
  });
});

test('old JSON without family decodes family null', () {
  final config = decodeProjectElementShadowConfig(<String, Object?>{
    'castsShadow': true,
    'shadowProfileId': 'tree_large',
  });

  expect(config!.family, isNull);
});

test('decodes family when present', () {
  final config = decodeProjectElementShadowConfig(<String, Object?>{
    'castsShadow': true,
    'shadowProfileId': 'tree_large',
    'family': 'tallProp',
  });

  expect(config!.family, StaticShadowFamily.tallProp);
});

test('rejects invalid family values', () {
  expect(
    () => decodeProjectElementShadowConfig(<String, Object?>{
      'castsShadow': true,
      'shadowProfileId': 'tree_large',
      'family': 'zeppelin',
    }),
    throwsA(isA<ValidationException>()),
  );
});
```

- [ ] **Step 2: Add failing MapPlacedElementShadowOverride JSON tests**

Add cases:

```dart
test('encodes custom family when present', () {
  final override = MapPlacedElementShadowOverride(
    mode: ShadowOverrideMode.custom,
    family: StaticShadowFamily.compactProp,
  );

  expect(encodeMapPlacedElementShadowOverride(override), <String, Object?>{
    'mode': 'custom',
    'family': 'compactProp',
  });
});

test('old JSON without family decodes family null', () {
  final override = decodeMapPlacedElementShadowOverride(<String, Object?>{
    'mode': 'custom',
    'offsetX': 2,
  });

  expect(override!.family, isNull);
});

test('decodes custom family when present', () {
  final override = decodeMapPlacedElementShadowOverride(<String, Object?>{
    'mode': 'custom',
    'family': 'building',
  });

  expect(override!.family, StaticShadowFamily.building);
});

test('rejects inherit and disabled family through model validation', () {
  expect(
    () => decodeMapPlacedElementShadowOverride(<String, Object?>{
      'mode': 'inherit',
      'family': 'building',
    }),
    throwsA(isA<ValidationException>()),
  );
  expect(
    () => decodeMapPlacedElementShadowOverride(<String, Object?>{
      'mode': 'disabled',
      'family': 'building',
    }),
    throwsA(isA<ValidationException>()),
  );
});
```

- [ ] **Step 3: Run JSON tests and verify failure**

```bash
cd packages/map_core && dart test test/shadow/project_element_shadow_config_json_codec_test.dart test/shadow/map_placed_element_shadow_override_json_codec_test.dart
```

Expected before implementation:

```text
New family expectations fail.
```

- [ ] **Step 4: Update codecs**

In both codec files, import:

```dart
import 'static_shadow_family_json_codec.dart';
```

In `encodeProjectElementShadowConfig(...)`, add:

```dart
if (config.family != null)
  'family': encodeStaticShadowFamily(config.family),
```

In `decodeProjectElementShadowConfig(...)`, pass:

```dart
family: decodeStaticShadowFamily(map['family']),
```

In `encodeMapPlacedElementShadowOverride(...)`, add:

```dart
if (override.family != null)
  'family': encodeStaticShadowFamily(override.family),
```

In `decodeMapPlacedElementShadowOverride(...)`, pass:

```dart
family: decodeStaticShadowFamily(map['family']),
```

- [ ] **Step 5: Run JSON tests**

```bash
cd packages/map_core && dart test test/shadow/project_element_shadow_config_json_codec_test.dart test/shadow/map_placed_element_shadow_override_json_codec_test.dart
```

Expected:

```text
All tests passed!
```

---

### Task 4: Update Automatic Shadow Suggestions To Write Family

**Files:**

- Modify: `packages/map_editor/lib/src/application/shadow/element_auto_shadow_suggestion.dart`
- Test: `packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart`

- [ ] **Step 1: Add failing tests for family assignment**

Add these checks to the existing classification tests:

```dart
expect(suggestion.config.family, StaticShadowFamily.tallProp);
```

for `tallThin`.

```dart
expect(suggestion.config.family, StaticShadowFamily.building);
```

for `buildingLarge`.

```dart
expect(suggestion.config.family, StaticShadowFamily.compactProp);
```

for `wideLow` and `smallSquare`.

```dart
expect(suggestion.config.family, StaticShadowFamily.genericProjection);
```

for `defaultProp`.

Also add:

```dart
test('all suggestions carry a static shadow family', () {
  for (final suggestion in _allSuggestionKinds()) {
    expect(suggestion.config.family, isNotNull);
  }
});
```

- [ ] **Step 2: Run suggestion test and verify failure**

```bash
cd packages/map_editor && flutter test test/application/shadow/element_auto_shadow_suggestion_test.dart
```

Expected before implementation:

```text
Family expectations fail because suggestions do not set family yet.
```

- [ ] **Step 3: Implement family mapping**

In each `_configForKind(...)` return, add:

```dart
family: StaticShadowFamily.tallProp,
```

for `tallThin`.

```dart
family: StaticShadowFamily.building,
```

for `buildingLarge`.

```dart
family: StaticShadowFamily.compactProp,
```

for `wideLow` and `smallSquare`.

```dart
family: StaticShadowFamily.genericProjection,
```

for `defaultProp`.

Do not change profile, footprint, offset, scale, or opacity values in this lot.

- [ ] **Step 4: Run suggestion test**

```bash
cd packages/map_editor && flutter test test/application/shadow/element_auto_shadow_suggestion_test.dart
```

Expected:

```text
All tests passed!
```

---

### Task 5: Verify Backfill Keeps Working Without Special Changes

**Files:**

- Test only: `packages/map_editor/test/application/shadow/element_auto_shadow_backfill_test.dart`

The Shadow-40 backfill applies `suggestion.config`. Once suggestions carry `family`, the backfill should persist family automatically.

- [ ] **Step 1: Add one focused backfill assertion**

In the "applies suggestions to elements without shadow configs" or equivalent test, assert:

```dart
expect(
  result.project.elements.single.shadow!.family,
  StaticShadowFamily.tallProp,
);
```

Use the expected family that matches the fixture dimensions in the test.

- [ ] **Step 2: Run backfill test**

```bash
cd packages/map_editor && flutter test test/application/shadow/element_auto_shadow_backfill_test.dart
```

Expected:

```text
All tests passed!
```

If the test fixture has multiple elements, assert family on the element by id instead of using `.single`.

---

### Task 6: Formatting And Analysis

**Files:**

- All touched Dart files.

- [ ] **Step 1: Format touched files**

```bash
cd packages/map_core && dart format lib/src/models/shadow.dart lib/src/operations/static_shadow_family_json_codec.dart lib/src/operations/project_element_shadow_config_json_codec.dart lib/src/operations/map_placed_element_shadow_override_json_codec.dart lib/map_core.dart test/shadow/static_shadow_family_json_codec_test.dart test/shadow/project_element_shadow_config_test.dart test/shadow/map_placed_element_shadow_override_test.dart test/shadow/project_element_shadow_config_json_codec_test.dart test/shadow/map_placed_element_shadow_override_json_codec_test.dart
cd packages/map_editor && dart format lib/src/application/shadow/element_auto_shadow_suggestion.dart test/application/shadow/element_auto_shadow_suggestion_test.dart test/application/shadow/element_auto_shadow_backfill_test.dart
```

- [ ] **Step 2: Run targeted map_core tests**

```bash
cd packages/map_core && dart test test/shadow/static_shadow_family_json_codec_test.dart
cd packages/map_core && dart test test/shadow/project_element_shadow_config_test.dart
cd packages/map_core && dart test test/shadow/map_placed_element_shadow_override_test.dart
cd packages/map_core && dart test test/shadow/project_element_shadow_config_json_codec_test.dart
cd packages/map_core && dart test test/shadow/map_placed_element_shadow_override_json_codec_test.dart
```

Expected for each:

```text
All tests passed!
```

- [ ] **Step 3: Run targeted map_editor tests**

```bash
cd packages/map_editor && flutter test test/application/shadow/element_auto_shadow_suggestion_test.dart
cd packages/map_editor && flutter test test/application/shadow/element_auto_shadow_backfill_test.dart
```

Expected for each:

```text
All tests passed!
```

- [ ] **Step 4: Run broader shadow suites**

```bash
cd packages/map_core && dart test test/shadow
cd packages/map_editor && flutter test test/application/shadow
```

Expected final lines:

```text
All tests passed!
```

- [ ] **Step 5: Run targeted analysis**

```bash
cd packages/map_core && dart analyze lib test/shadow
cd packages/map_editor && flutter analyze lib/src/application/shadow test/application/shadow
```

Expected:

```text
No issues found!
```

If analyzer output includes pre-existing issues outside touched files, document them precisely in the report and do not hide them.

---

### Task 7: Anti-Drift Scans

Run from repository root:

```bash
cd /Users/karim/Project/pokemonProject
```

- [ ] **Step 1: Runtime/gameplay/battle forbidden diff**

```bash
git diff --name-only | rg -n "packages/map_runtime|packages/map_gameplay|packages/map_battle"
```

Expected:

```text
aucune sortie
```

- [ ] **Step 2: Editor canvas/painter forbidden diff**

```bash
git diff --name-only | rg -n "packages/map_editor/lib/src/ui/canvas"
```

Expected:

```text
aucune nouvelle sortie Shadow-41
```

Important: pre-existing Shadow-38 canvas files may already be modified in the worktree. The report must distinguish them from Shadow-41.

- [ ] **Step 3: Generated files forbidden diff**

```bash
git diff --name-only | rg -n "\\.g\\.dart|\\.freezed\\.dart"
```

Expected:

```text
aucune sortie
```

- [ ] **Step 4: Renderer and global light concepts forbidden diff**

```bash
git diff -U0 -- packages/map_core packages/map_editor \
  | rg -n "Canvas|drawOval|drawPath|drawImageRect|saveLayer|ImageFilter|runtimeBlur|WorldLightState|ShadowLightProfile|LightDirection|timeOfDay|zOrder|zIndex|drawAtlas"
```

Expected:

```text
aucune nouvelle sortie liée à Shadow-41
```

Note: existing uncommitted Shadow-38 editor preview/painter changes may contain `drawPath`; they must be reported as pre-existing, not introduced by Shadow-41.

- [ ] **Step 5: Runtime import forbidden in editor**

```bash
git diff -U0 -- packages/map_editor \
  | rg -n "package:map_runtime|map_runtime/src"
```

Expected:

```text
aucune sortie
```

- [ ] **Step 6: General diff checks**

```bash
git diff --check
git diff --stat
git diff --name-status
git status --short --untracked-files=all
```

Expected:

```text
No whitespace errors.
Only Shadow-41 files plus pre-existing outside-lot files are present.
```

---

## 7. Implementation Report Requirements

Create:

```text
reports/shadows/shadow_lot_41_static_shadow_family_model_style.md
```

The report must include:

```text
1. Résumé du lot
2. Design retenu
3. Fichiers créés
4. Fichiers modifiés
5. Fichiers préexistants hors lot
6. StaticShadowFamily ajouté
7. Intégration ProjectElementShadowConfig
8. Intégration MapPlacedElementShadowOverride
9. Format JSON family
10. Compatibilité anciens JSON
11. Suggestions auto et mapping des familles
12. Pourquoi ce lot ne touche pas runtime/editor canvas
13. Pourquoi ce lot ne crée pas de vraie lumière globale
14. Tests ajoutés/modifiés
15. Commandes lancées
16. Résultats complets des tests ciblés
17. Lignes finales exactes des tests globaux ciblés
18. Résultats des scans anti-dérive
19. git status initial
20. git status final
21. git diff --stat
22. Non-objectifs respectés
23. Risques / réserves
24. Auto-review finale
25. Regard critique sur le prompt
26. Contenu complet des fichiers créés/modifiés
27. Diffs complets ou équivalents /dev/null pour fichiers créés
```

The report must list the pre-existing modified/untracked files separately from Shadow-41 files.

The report must include the complete contents of small created files:

```text
packages/map_core/lib/src/operations/static_shadow_family_json_codec.dart
packages/map_core/test/shadow/static_shadow_family_json_codec_test.dart
reports/shadows/shadow_lot_41_static_shadow_family_model_style.md
```

The report itself does not need to recursively include its own complete contents.

---

## 8. Auto-Review Checklist For Shadow-41

The final report must answer:

```text
- Ai-je ajouté StaticShadowFamily ? oui.
- Ai-je gardé ProjectShadowProfile comme style partagé ? oui.
- Ai-je ajouté family à ProjectElementShadowConfig ? oui.
- Ai-je ajouté family à MapPlacedElementShadowOverride ? oui.
- Ai-je interdit family sur override inherit/disabled ? oui.
- Ai-je gardé les anciens JSON compatibles ? oui.
- Ai-je encodé family seulement si non-null ? oui.
- Ai-je mis à jour les suggestions auto ? oui.
- Ai-je évité le runtime ? oui.
- Ai-je évité le canvas/painter éditeur ? oui.
- Ai-je évité build_runner/generated files ? oui.
- Ai-je évité une lumière globale/time-of-day ? oui.
- Ai-je documenté que le rendu visible viendra après ? oui.
```

---

## 9. Risks And Constraints

1. `StaticShadowFamily.foliage` may be unused immediately.
   This is acceptable because it is a stable semantic bucket needed for the next visual pass. Do not add name-based foliage detection in Shadow-41 unless the implementation prompt explicitly expands scope.

2. Shadow-41 will not make the screenshot look better by itself.
   It only persists the semantic signal. The visible improvement requires Shadow-42 and Shadow-43.

3. `family` can feel close to `ShadowCasterMode`.
   Keep the distinction strict:
   - `ShadowCasterMode` belongs to profile/render shape compatibility.
   - `StaticShadowFamily` belongs to object-specific geometry strategy.

4. Adding fields to manual `map_core` models does not require `build_runner`.
   Do not touch Freezed/generated files.

5. Existing uncommitted Shadow-38 canvas files can make anti-drift scans noisy.
   The report must call this out instead of pretending Shadow-41 touched canvas.

---

## 10. Roadmap After Shadow-41

### Shadow-42 — Static Shadow Family Geometry Core V0

Use `StaticShadowFamily` to select projection specs and geometry families in pure `map_core`.

Likely files:

```text
packages/map_core/lib/src/operations/static_shadow_family_geometry.dart
packages/map_core/test/shadow/static_shadow_family_geometry_test.dart
```

Expected behavior:

```text
genericProjection -> current projection
compactProp -> shorter, closer projection
tallProp -> narrow projection with limited far widening
building -> blockier broad cast shape, closer to Pokemon building shadows
foliage -> broader canopy-aware cast shape
```

No runtime/editor integration yet.

### Shadow-43 — Runtime + Editor Static Shadow Family Integration V0

Make runtime and editor preview pass the resolved family into the core family geometry.

Likely files:

```text
packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart
packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart
```

Must use `flame_docs` before runtime changes.

### Shadow-44 — Selbrume Visual Tuning / Golden Slice V0

Tune defaults and fixtures against visible Selbrume cases:

```text
lamp post
house/building
market stand
tree/foliage
small signs
well/statue-like props
```

This is the lot where screenshots should finally start looking closer to Pokemon-style cast shadows.

---

## 11. Success Criteria

Shadow-41 is successful if:

```text
- StaticShadowFamily exists in map_core;
- ProjectElementShadowConfig.family exists and is tested;
- MapPlacedElementShadowOverride.family exists and is tested;
- override family is custom-only;
- JSON old projects remain compatible;
- JSON unknown family values are rejected;
- auto shadow suggestions write family;
- backfill inherits suggestion family automatically;
- no runtime is modified;
- no editor canvas/painter is modified;
- no generated files are modified;
- targeted tests pass;
- Evidence Pack report exists;
- no commit is made unless the user explicitly asks afterward.
```
