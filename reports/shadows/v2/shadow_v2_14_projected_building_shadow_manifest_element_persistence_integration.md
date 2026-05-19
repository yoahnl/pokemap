# ShadowV2-14 — Projected Building Shadow Manifest / Element Persistence Integration V0

## 1. Résumé exécutif

ShadowV2-14 intègre ShadowV2 dans `project.json` en persistance dormante uniquement.

Implémenté :

- `ProjectManifest.projectedBuildingShadowCatalog`
- `ProjectElementEntry.projectedBuildingShadow`
- branchement des codecs V2 existants ;
- omission du root V2 quand le catalogue est vide ;
- omission du champ élément V2 quand la config est `null` ;
- génération Freezed/json_serializable ciblée dans `packages/map_core` ;
- tests JSON/compatibilité ShadowV2-14.

Non implémenté :

- aucun runtime ;
- aucun éditeur ;
- aucun renderer ;
- aucun diagnostic avancé ;
- aucun preset par défaut ;
- aucune migration injective ;
- aucun changement Selbrume ;
- aucun commit.

## 2. Objectif du lot

Faire entrer les données ShadowV2 dans le `project.json` sans produire la moindre ombre :

- anciens projets sans V2 : restent sans sortie V2 ;
- root V2 absent/null : catalogue vide en mémoire ;
- root V2 vide : omis au `toJson` ;
- root V2 non vide : round-trip stable ;
- élément V2 absent/null : `null` en mémoire et champ omis ;
- élément V2 non-null : round-trip stable ;
- V1 `shadow` et V2 `projectedBuildingShadow` peuvent coexister explicitement.

## 3. Rappel ShadowV2-13

Décisions appliquées :

```text
ProjectManifest :
- champ Dart : projectedBuildingShadowCatalog
- type : ProjectBuildingShadowPresetCatalog non-nullable
- JSON root : projectedBuildingShadowCatalog
- root absent : catalogue vide
- root null : catalogue vide
- root vide : omis au toJson
- root non vide : émis au toJson
- pas de migration injective

ProjectElementEntry :
- champ Dart : projectedBuildingShadow
- type : ProjectElementProjectedBuildingShadowConfig?
- JSON field : projectedBuildingShadow
- absent : null
- null : null
- object : decode config V2
- null au toJson : champ omis
- non-null au toJson : champ émis
```

## 4. État initial du worktree

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text

```

## 5. Décision AGENTS / design gate satisfait

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

- ShadowV2-13 a fourni le design gate.
- ShadowV2-14 implémente exactement l'intégration persistante prévue.
- Aucun blocage AGENTS supplémentaire n'a été identifié.

## 6. Fichiers modifiés

Modifiés :

- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/project_manifest.freezed.dart`
- `packages/map_core/lib/src/models/project_manifest.g.dart`
- `packages/map_core/lib/src/models/projected_building_shadow.dart`
- `packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart`

Créés :

- `packages/map_core/test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart`
- `reports/shadows/v2/shadow_v2_14_projected_building_shadow_manifest_element_persistence_integration.md`

Fichiers générés modifiés :

- `packages/map_core/lib/src/models/project_manifest.freezed.dart`
- `packages/map_core/lib/src/models/project_manifest.g.dart`

Non modifiés :

- `packages/map_core/lib/map_core.dart`
- `packages/map_core/lib/src/operations/project_json_migrations.dart`
- `packages/map_runtime/**`
- `packages/map_editor/**`
- `packages/map_gameplay/**`
- `packages/map_battle/**`
- `examples/**`
- `/Users/karim/Desktop/selbrume/project.json`
- `/Users/karim/Desktop/selbrume/maps/Selbrume.json`

## 7. Modifications ProjectManifest

`ProjectManifest` importe les modèles/codecs ShadowV2, expose un catalogue non-nullable, et utilise un `JsonKey` qui délègue au codec catalogue.

Diff source lisible :

```diff
diff --git a/packages/map_core/lib/src/models/project_manifest.dart b/packages/map_core/lib/src/models/project_manifest.dart
index 0a2ef588..96d4bc75 100644
--- a/packages/map_core/lib/src/models/project_manifest.dart
+++ b/packages/map_core/lib/src/models/project_manifest.dart
@@ -6,6 +6,7 @@ import 'environment.dart';
 import 'enums.dart';
 import 'project_trainer.dart';
 import 'project_path_pattern_preset.dart';
+import 'projected_building_shadow.dart';
 import 'scenario_asset.dart';
 import 'script_asset.dart';
 import 'shadow.dart';
@@ -17,6 +18,8 @@ import 'visual_frame_json.dart';
 import '../exceptions/map_exceptions.dart';
 import '../operations/environment_preset_json_codec.dart';
 import '../operations/project_element_shadow_config_json_codec.dart';
+import '../operations/project_building_shadow_preset_catalog_json_codec.dart';
+import '../operations/project_element_projected_building_shadow_config_json_codec.dart';
 import '../operations/project_path_pattern_preset_json_codec.dart';
 import '../operations/project_shadow_catalog_json_codec.dart';
 import '../operations/project_surface_catalog_json_codec.dart';
@@ -44,6 +47,49 @@ Map<String, Object?> _projectSurfaceCatalogToJson(
   return encodeProjectSurfaceCatalog(catalog);
 }
 
+/// JSON -> ShadowV2 projected building shadow catalog.
+///
+/// Missing or `null` root data remains an empty in-memory catalog. When the
+/// object is present, it must use the explicit catalog codec shape.
+ProjectBuildingShadowPresetCatalog _projectedBuildingShadowCatalogFromJson(
+    Object? json) {
+  if (json == null) {
+    return const ProjectBuildingShadowPresetCatalog.empty();
+  }
+  if (json is! Map) {
+    throw const ValidationException(
+      'projectedBuildingShadowCatalog must be a JSON object',
+    );
+  }
+  return decodeProjectBuildingShadowPresetCatalog(json);
+}
+
+Map<String, Object?>? _projectedBuildingShadowCatalogToJson(
+  ProjectBuildingShadowPresetCatalog catalog,
+) {
+  if (catalog.isEmpty) {
+    return null;
+  }
+  return encodeProjectBuildingShadowPresetCatalog(catalog);
+}
+
+ProjectElementProjectedBuildingShadowConfig?
+    _projectedBuildingShadowConfigFromJson(Object? json) {
+  if (json == null) {
+    return null;
+  }
+  return decodeProjectElementProjectedBuildingShadowConfig(json);
+}
+
+Map<String, Object?>? _projectedBuildingShadowConfigToJson(
+  ProjectElementProjectedBuildingShadowConfig? config,
+) {
+  if (config == null) {
+    return null;
+  }
+  return encodeProjectElementProjectedBuildingShadowConfig(config);
+}
+
 Object? _readDefaultPlayerCharacterId(Map json, String _) {
   return json['defaultPlayerCharacterId'] ?? json['playerCharacterId'];
 }
@@ -133,6 +179,14 @@ class ProjectManifest with _$ProjectManifest {
     @Default(ProjectShadowCatalog.empty())
     @ProjectShadowCatalogJsonConverter()
     ProjectShadowCatalog shadowCatalog,
+    @Default(ProjectBuildingShadowPresetCatalog.empty())
+    @JsonKey(
+      name: 'projectedBuildingShadowCatalog',
+      fromJson: _projectedBuildingShadowCatalogFromJson,
+      toJson: _projectedBuildingShadowCatalogToJson,
+      includeIfNull: false,
+    )
+    ProjectBuildingShadowPresetCatalog projectedBuildingShadowCatalog,
   }) = _ProjectManifest;
```

`ProjectBuildingShadowPresetCatalog.empty()` a été ajouté pour permettre un `@Default(...)` Freezed non-nullable sans casser les constructions existantes de `ProjectManifest`.

```diff
diff --git a/packages/map_core/lib/src/models/projected_building_shadow.dart b/packages/map_core/lib/src/models/projected_building_shadow.dart
index 7d0795c2..a41e3b62 100644
--- a/packages/map_core/lib/src/models/projected_building_shadow.dart
+++ b/packages/map_core/lib/src/models/projected_building_shadow.dart
@@ -293,6 +293,8 @@ final class ProjectBuildingShadowPresetCatalog {
     List<ProjectBuildingShadowPreset> presets = const [],
   }) : _presets = _copyBuildingShadowPresets(presets);
 
+  const ProjectBuildingShadowPresetCatalog.empty() : _presets = const [];
+
   final List<ProjectBuildingShadowPreset> _presets;
```

## 8. Modifications ProjectElementEntry

`ProjectElementEntry` reçoit un champ nullable `projectedBuildingShadow` et un `JsonKey` qui omet le champ quand il est `null`.

Diff source lisible :

```diff
@@ -380,6 +434,13 @@ class ProjectElementEntry with _$ProjectElementEntry {
     ElementCollisionProfile? collisionProfile,
     @ProjectElementShadowConfigJsonConverter()
     ProjectElementShadowConfig? shadow,
+    @JsonKey(
+      name: 'projectedBuildingShadow',
+      fromJson: _projectedBuildingShadowConfigFromJson,
+      toJson: _projectedBuildingShadowConfigToJson,
+      includeIfNull: false,
+    )
+    ProjectElementProjectedBuildingShadowConfig? projectedBuildingShadow,
     String? groupId,
     String? recommendedLayerId,
     @Default([]) List<String> tags,
```

## 9. JSON behavior implemented

Manifest :

```text
root absent -> const ProjectBuildingShadowPresetCatalog.empty()
root null -> const ProjectBuildingShadowPresetCatalog.empty()
root object -> decodeProjectBuildingShadowPresetCatalog(...)
root {} -> ValidationException via missing presets
empty catalog toJson -> root omitted
non-empty catalog toJson -> root emitted
```

Element :

```text
field absent -> null
field null -> null
field object -> decodeProjectElementProjectedBuildingShadowConfig(...)
field malformed -> ValidationException from codec
null toJson -> field omitted
non-null toJson -> field emitted
```

Generated `project_manifest.g.dart` confirms the omit behavior:

```diff
@@ -149,6 +154,10 @@ Map<String, dynamic> _$$ProjectManifestImplToJson(
       'surfaceCatalog': _projectSurfaceCatalogToJson(instance.surfaceCatalog),
       'shadowCatalog': const ProjectShadowCatalogJsonConverter()
           .toJson(instance.shadowCatalog),
+      if (_projectedBuildingShadowCatalogToJson(
+              instance.projectedBuildingShadowCatalog)
+          case final value?)
+        'projectedBuildingShadowCatalog': value,
     };
@@ -546,6 +557,9 @@ Map<String, dynamic> _$$ProjectElementEntryImplToJson(
       'collisionProfile': instance.collisionProfile?.toJson(),
       'shadow': const ProjectElementShadowConfigJsonConverter()
           .toJson(instance.shadow),
+      if (_projectedBuildingShadowConfigToJson(instance.projectedBuildingShadow)
+          case final value?)
+        'projectedBuildingShadow': value,
       'groupId': instance.groupId,
```

## 10. Migration behavior

`project_json_migrations.dart` n'a pas été modifié.

Décision appliquée :

```text
Aucune migration injective.
Aucun root V2 ajouté aux vieux projets.
Aucun preset V2 par défaut.
Aucune config élément V2 par défaut.
```

## 11. Tests ajoutés/modifiés

Test créé :

- `packages/map_core/test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart`

Test modifié :

- `packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart`

Raison de modification :

- les anciens tests de caractérisation utilisaient `projectedBuildingShadow` comme clé inconnue ;
- après V2-14, cette clé est connue et une config incomplète est correctement rejetée ;
- les tests ont été recentrés sur des clés futures encore inconnues (`projectedShadow`, `projectedBuildingShadowPresets`).

Contenu complet du test créé :

```dart
import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ShadowV2 manifest and element persistence integration', () {
    test(
      'ProjectManifest without projectedBuildingShadowCatalog decodes an empty '
      'catalog and omits the root on toJson',
      () {
        final manifest = ProjectManifest.fromJson(_manifestJson());

        expect(manifest.projectedBuildingShadowCatalog.isEmpty, isTrue);

        final json = _wireJson(manifest.toJson());
        expect(json, isNot(contains('projectedBuildingShadowCatalog')));
        expect(_elementJsonAt(json, 0),
            isNot(contains('projectedBuildingShadow')));
      },
    );

    test(
      'ProjectManifest with projectedBuildingShadowCatalog null decodes empty '
      'and omits the root on toJson',
      () {
        final manifest = ProjectManifest.fromJson(
          _manifestJson(projectedBuildingShadowCatalog: null),
        );

        expect(manifest.projectedBuildingShadowCatalog.isEmpty, isTrue);

        final json = _wireJson(manifest.toJson());
        expect(json, isNot(contains('projectedBuildingShadowCatalog')));
      },
    );

    test(
      'ProjectManifest rejects an object projectedBuildingShadowCatalog without '
      'presets',
      () {
        expect(
          () => ProjectManifest.fromJson(
            _manifestJson(
              projectedBuildingShadowCatalog: <String, Object?>{},
            ),
          ),
          throwsA(isA<ValidationException>()),
        );
      },
    );

    test(
      'ProjectManifest with empty projectedBuildingShadowCatalog presets decodes '
      'empty and omits the root on toJson',
      () {
        final manifest = ProjectManifest.fromJson(
          _manifestJson(
            projectedBuildingShadowCatalog: <String, Object?>{
              'presets': <Object?>[],
            },
          ),
        );

        expect(manifest.projectedBuildingShadowCatalog.isEmpty, isTrue);

        final json = _wireJson(manifest.toJson());
        expect(json, isNot(contains('projectedBuildingShadowCatalog')));
      },
    );

    test(
      'ProjectManifest with non-empty projectedBuildingShadowCatalog round-trips '
      'and emits the root',
      () {
        final manifest = ProjectManifest.fromJson(
          _manifestJson(projectedBuildingShadowCatalog: _catalogJson()),
        );

        expect(manifest.projectedBuildingShadowCatalog.length, 2);
        expect(
          manifest.projectedBuildingShadowCatalog
              .presetById('short-west-building-shadow')
              ?.appearance
              .colorHexRgb,
          '000000',
        );

        final json = _wireJson(manifest.toJson());
        expect(json['projectedBuildingShadowCatalog'], _catalogJson());

        final roundTripped = ProjectManifest.fromJson(json);
        expect(
          roundTripped.projectedBuildingShadowCatalog,
          manifest.projectedBuildingShadowCatalog,
        );
      },
    );

    test(
      'ProjectElementEntry without projectedBuildingShadow decodes null and '
      'omits the field on toJson',
      () {
        final element = ProjectElementEntry.fromJson(_elementJson());

        expect(element.projectedBuildingShadow, isNull);
        expect(element.toJson(), isNot(contains('projectedBuildingShadow')));
      },
    );

    test(
      'ProjectElementEntry with projectedBuildingShadow null decodes null and '
      'omits the field on toJson',
      () {
        final element = ProjectElementEntry.fromJson(
          _elementJson(projectedBuildingShadow: null),
        );

        expect(element.projectedBuildingShadow, isNull);
        expect(element.toJson(), isNot(contains('projectedBuildingShadow')));
      },
    );

    test(
      'ProjectElementEntry with projectedBuildingShadow round-trips and emits '
      'the field',
      () {
        final element = ProjectElementEntry.fromJson(
          _elementJson(projectedBuildingShadow: _projectedShadowConfigJson()),
        );

        expect(element.projectedBuildingShadow, _projectedShadowConfig());

        final json = _wireJson(element.toJson());
        expect(json['projectedBuildingShadow'], _projectedShadowConfigJson());

        final roundTripped = ProjectElementEntry.fromJson(json);
        expect(roundTripped.projectedBuildingShadow,
            element.projectedBuildingShadow);
      },
    );

    test(
      'ProjectElementEntry preserves V1 shadow and V2 projectedBuildingShadow '
      'together',
      () {
        final element = ProjectElementEntry.fromJson(
          _elementJson(
            shadow: _v1ShadowJson(),
            projectedBuildingShadow: _projectedShadowConfigJson(enabled: false),
          ),
        );

        expect(element.shadow?.castsShadow, isTrue);
        expect(element.shadow?.shadowProfileId, 'default-ground-wide-ellipse');
        expect(
          element.projectedBuildingShadow,
          _projectedShadowConfig(enabled: false),
        );

        final json = _wireJson(element.toJson());
        expect(json['shadow'], _v1ShadowJson());
        expect(
          json['projectedBuildingShadow'],
          _projectedShadowConfigJson(enabled: false),
        );
      },
    );

    test(
      'existing V1-only manifest round-trip stays free of projected building '
      'shadow output',
      () {
        final manifest = ProjectManifest.fromJson(
          _manifestJson(
            shadowCatalog: _v1ShadowCatalogJson(),
            elements: <Object?>[
              _elementJson(id: 'house', shadow: _v1ShadowJson()),
              _elementJson(id: 'crate'),
            ],
          ),
        );

        final json = _wireJson(manifest.toJson());
        final elements =
            (json['elements'] as List<Object?>).cast<Map<String, Object?>>();

        expect(json['shadowCatalog'], _v1ShadowCatalogJson());
        expect(json, isNot(contains('projectedBuildingShadowCatalog')));
        expect(elements[0], isNot(contains('projectedBuildingShadow')));
        expect(elements[1], isNot(contains('projectedBuildingShadow')));
      },
    );

    test('copyWith can replace manifest catalog and element config', () {
      final manifest = ProjectManifest.fromJson(_manifestJson());
      final catalog = ProjectBuildingShadowPresetCatalog(
        presets: <ProjectBuildingShadowPreset>[_shortWestPreset()],
      );

      final updatedManifest = manifest.copyWith(
        projectedBuildingShadowCatalog: catalog,
      );

      expect(updatedManifest.projectedBuildingShadowCatalog, catalog);
      expect(manifest.projectedBuildingShadowCatalog.isEmpty, isTrue);

      final element = ProjectElementEntry.fromJson(_elementJson());
      final config = _projectedShadowConfig();
      final updatedElement = element.copyWith(projectedBuildingShadow: config);

      expect(updatedElement.projectedBuildingShadow, config);
      expect(element.projectedBuildingShadow, isNull);
    });
  });
}

Map<String, Object?> _manifestJson({
  Object? projectedBuildingShadowCatalog = _absent,
  Object? shadowCatalog = _absent,
  List<Object?>? elements,
}) {
  return <String, Object?>{
    'name': 'Project',
    'maps': <Object?>[],
    'tilesets': <Object?>[],
    if (!identical(shadowCatalog, _absent)) 'shadowCatalog': shadowCatalog,
    if (!identical(projectedBuildingShadowCatalog, _absent))
      'projectedBuildingShadowCatalog': projectedBuildingShadowCatalog,
    'elements': elements ?? <Object?>[_elementJson()],
  };
}

Map<String, Object?> _elementJson({
  String id = 'house',
  Object? shadow = _absent,
  Object? projectedBuildingShadow = _absent,
}) {
  return <String, Object?>{
    'id': id,
    'name': id,
    'tilesetId': 'tileset',
    'categoryId': 'building',
    'frames': <Object?>[
      <String, Object?>{
        'source': <String, Object?>{'x': 0, 'y': 0},
      },
    ],
    if (!identical(shadow, _absent)) 'shadow': shadow,
    if (!identical(projectedBuildingShadow, _absent))
      'projectedBuildingShadow': projectedBuildingShadow,
  };
}

Map<String, Object?> _catalogJson() {
  return <String, Object?>{
    'presets': <Object?>[
      _shortWestPresetJson(),
      _longEastPresetJson(),
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

Map<String, Object?> _longEastPresetJson() {
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
      'colorHexRgb': '000000',
    },
    'timeOfDayMode': 'followsSun',
    'categoryId': 'buildings',
    'sortOrder': 10,
  };
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

Map<String, Object?> _projectedShadowConfigJson({
  bool enabled = true,
}) {
  return <String, Object?>{
    'enabled': enabled,
    'presetId': 'short-west-building-shadow',
    'anchor': <String, Object?>{
      'xRatio': 0.5,
      'yRatio': 0.98,
    },
    'localOffset': <String, Object?>{
      'x': 0,
      'y': 0,
    },
  };
}

ProjectElementProjectedBuildingShadowConfig _projectedShadowConfig({
  bool enabled = true,
}) {
  return ProjectElementProjectedBuildingShadowConfig(
    enabled: enabled,
    presetId: 'short-west-building-shadow',
    anchor: ProjectedShadowAnchor(xRatio: 0.5, yRatio: 0.98),
    localOffset: ProjectedShadowOffset(x: 0, y: 0),
  );
}

Map<String, Object?> _v1ShadowJson() {
  return <String, Object?>{
    'castsShadow': true,
    'shadowProfileId': 'default-ground-wide-ellipse',
  };
}

Map<String, Object?> _v1ShadowCatalogJson() {
  return <String, Object?>{
    'profiles': <Object?>[
      <String, Object?>{
        'id': 'default-ground-wide-ellipse',
        'name': 'Default ground wide ellipse',
        'mode': 'ellipse',
        'renderPass': 'groundStatic',
        'offsetX': 0.0,
        'offsetY': 0.0,
        'scaleX': 1.0,
        'scaleY': 1.0,
        'opacity': 0.18,
        'colorHexRgb': '000000',
        'softnessMode': 'hardEdge',
      },
    ],
  };
}

Map<String, Object?> _wireJson(Map<String, dynamic> json) {
  return (jsonDecode(jsonEncode(json)) as Map<String, dynamic>)
      .cast<String, Object?>();
}

Map<String, Object?> _elementJsonAt(Map<String, Object?> json, int index) {
  return (json['elements'] as List<Object?>)
      .cast<Map<String, Object?>>()[index];
}

const _absent = Object();
```

## 12. Build runner

Commande :

```bash
cd packages/map_core
dart run build_runner build --delete-conflicting-outputs
```

Sortie :

```text
  Generating the build script.
  Reading the asset graph.
  Checking for updates.
  Updating the asset graph.
  Building, incremental build.
  0s freezed on 254 inputs; lib/map_core.dart
W SDK language version 3.11.0 is newer than `analyzer` language version 3.9.0. Run `dart pub upgrade`.
  0s freezed on 254 inputs: 1 no-op; lib/src/collision/pixel_rect.dart
  1s freezed on 254 inputs: 3 skipped, 1 same, 1 no-op; spent 1s analyzing; lib/src/models/enums.dart
  3s freezed on 254 inputs: 84 skipped, 1 output, 3 same, 22 no-op; spent 2s analyzing; lib/src/operations/surface_to_gameplay_zone_generation_assessment.dart
  3s freezed on 254 inputs: 200 skipped, 1 output, 3 same, 50 no-op; spent 2s analyzing
  0s json_serializable on 508 inputs; lib/map_core.dart
  1s json_serializable on 508 inputs: 1 no-op; lib/map_core.freezed.dart
W json_serializable on lib/src/models/element_collision_profile.dart:
  The version constraint "^4.8.1" on json_annotation allows versions before 4.9.0 which is not allowed.
  2s json_serializable on 508 inputs: 78 skipped, 1 output, 3 same, 21 no-op; spent 2s analyzing; lib/src/operations/map_gameplay_zones.freezed.dart
  3s json_serializable on 508 inputs: 169 skipped, 1 output, 3 same, 78 no-op; spent 3s analyzing; test/dialogue_library_tree_test.freezed.dart
  4s json_serializable on 508 inputs: 228 skipped, 1 output, 3 same, 137 no-op; spent 3s analyzing; test/project_trainer_validation_test.freezed.dart
  5s json_serializable on 508 inputs: 298 skipped, 1 output, 3 same, 206 no-op; spent 4s analyzing
  0s source_gen:combining_builder on 508 inputs; lib/map_core.dart
  0s source_gen:combining_builder on 508 inputs: 144 skipped, 1 output, 3 same, 7 no-op; lib/src/operations/project_manifest_shadow_catalog_operations.freezed.dart
  0s source_gen:combining_builder on 508 inputs: 466 skipped, 1 output, 3 same, 38 no-op
  Running the post build.
  Writing the asset graph.
  Built with build_runner in 9s; wrote 12 outputs.
```

Fichiers générés modifiés selon Git :

```text
packages/map_core/lib/src/models/project_manifest.freezed.dart
packages/map_core/lib/src/models/project_manifest.g.dart
```

## 13. Résultats des tests

### Test RED initial

Commande :

```bash
cd packages/map_core && dart test test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart
```

Résultat avant implémentation :

```text
Failed to load "test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart":
test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart:14:25: Error: The getter 'projectedBuildingShadowCatalog' isn't defined for the type 'ProjectManifest'.
test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart:105:24: Error: The getter 'projectedBuildingShadow' isn't defined for the type 'ProjectElementEntry'.
test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart:200:9: Error: No named parameter with the name 'projectedBuildingShadowCatalog'.
test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart:208:47: Error: No named parameter with the name 'projectedBuildingShadow'.
00:00 +0 -1: Some tests failed.
```

### Test ciblé final

Commande :

```bash
cd packages/map_core && dart test test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart
```

Sortie complète :

```text
00:00 +0: loading test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart
00:00 +0: ShadowV2 manifest and element persistence integration ProjectManifest without projectedBuildingShadowCatalog decodes an empty catalog and omits the root on toJson
00:00 +1: ShadowV2 manifest and element persistence integration ProjectManifest without projectedBuildingShadowCatalog decodes an empty catalog and omits the root on toJson
00:00 +1: ShadowV2 manifest and element persistence integration ProjectManifest with projectedBuildingShadowCatalog null decodes empty and omits the root on toJson
00:00 +2: ShadowV2 manifest and element persistence integration ProjectManifest with projectedBuildingShadowCatalog null decodes empty and omits the root on toJson
00:00 +2: ShadowV2 manifest and element persistence integration ProjectManifest rejects an object projectedBuildingShadowCatalog without presets
00:00 +3: ShadowV2 manifest and element persistence integration ProjectManifest rejects an object projectedBuildingShadowCatalog without presets
00:00 +3: ShadowV2 manifest and element persistence integration ProjectManifest with empty projectedBuildingShadowCatalog presets decodes empty and omits the root on toJson
00:00 +4: ShadowV2 manifest and element persistence integration ProjectManifest with empty projectedBuildingShadowCatalog presets decodes empty and omits the root on toJson
00:00 +4: ShadowV2 manifest and element persistence integration ProjectManifest with non-empty projectedBuildingShadowCatalog round-trips and emits the root
00:00 +5: ShadowV2 manifest and element persistence integration ProjectManifest with non-empty projectedBuildingShadowCatalog round-trips and emits the root
00:00 +5: ShadowV2 manifest and element persistence integration ProjectElementEntry without projectedBuildingShadow decodes null and omits the field on toJson
00:00 +6: ShadowV2 manifest and element persistence integration ProjectElementEntry without projectedBuildingShadow decodes null and omits the field on toJson
00:00 +6: ShadowV2 manifest and element persistence integration ProjectElementEntry with projectedBuildingShadow null decodes null and omits the field on toJson
00:00 +7: ShadowV2 manifest and element persistence integration ProjectElementEntry with projectedBuildingShadow null decodes null and omits the field on toJson
00:00 +7: ShadowV2 manifest and element persistence integration ProjectElementEntry with projectedBuildingShadow round-trips and emits the field
00:00 +8: ShadowV2 manifest and element persistence integration ProjectElementEntry with projectedBuildingShadow round-trips and emits the field
00:00 +8: ShadowV2 manifest and element persistence integration ProjectElementEntry preserves V1 shadow and V2 projectedBuildingShadow together
00:00 +9: ShadowV2 manifest and element persistence integration ProjectElementEntry preserves V1 shadow and V2 projectedBuildingShadow together
00:00 +9: ShadowV2 manifest and element persistence integration existing V1-only manifest round-trip stays free of projected building shadow output
00:00 +10: ShadowV2 manifest and element persistence integration existing V1-only manifest round-trip stays free of projected building shadow output
00:00 +10: ShadowV2 manifest and element persistence integration copyWith can replace manifest catalog and element config
00:00 +11: ShadowV2 manifest and element persistence integration copyWith can replace manifest catalog and element config
00:00 +11: All tests passed!
```

### Régression ShadowV2

Commande :

```bash
cd packages/map_core && dart test test/shadow_v2
```

Ligne finale exacte :

```text
00:00 +124: All tests passed!
```

### Régression Shadow V1

Commande :

```bash
cd packages/map_core && dart test test/shadow
```

Ligne finale exacte :

```text
00:00 +284: All tests passed!
```

### Régression JSON / manifest ciblée

Commande :

```bash
cd packages/map_core && dart test test/shadow/project_manifest_shadow_catalog_json_test.dart test/shadow/project_element_entry_shadow_json_test.dart test/project_manifest_surface_integration_test.dart
```

Ligne finale exacte :

```text
00:00 +41: All tests passed!
```

## 14. Résultat analyze

Commande :

```bash
cd packages/map_core && dart analyze
```

Sortie :

```text
Analyzing map_core...
No issues found!
```

## 15. Exports

`packages/map_core/lib/map_core.dart` n'a pas été modifié.

Raison :

- `projected_building_shadow.dart` est déjà exporté ;
- les codecs V2 sont déjà exportés ;
- l'intégration se fait dans `project_manifest.dart`, sans nouvelle API publique à exposer.

## 16. Ce qui n'a volontairement pas été créé

Non créés :

- runtime resolver ;
- editor UI ;
- diagnostics avancés ;
- default presets ;
- migration injective ;
- rendu V2 ;
- preview V2 ;
- override `MapPlacedElement` V2 ;
- modification `genericProjection` ;
- baseline screenshot.

## 17. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie :

```text
 .../map_core/lib/src/models/project_manifest.dart  |  61 +++++++++
 .../lib/src/models/project_manifest.freezed.dart   | 138 +++++++++++++++++++--
 .../lib/src/models/project_manifest.g.dart         |  14 +++
 .../lib/src/models/projected_building_shadow.dart  |   2 +
 ...building_shadow_json_characterization_test.dart |  21 ++--
 5 files changed, 217 insertions(+), 19 deletions(-)
```

Note :

- Les fichiers non suivis ne sont pas inclus dans `git diff --stat`.
- Ils sont listés dans `git status final` et dans l'inventaire.

## 18. git diff --name-status

Commande :

```bash
git diff --name-status
```

Sortie :

```text
M	packages/map_core/lib/src/models/project_manifest.dart
M	packages/map_core/lib/src/models/project_manifest.freezed.dart
M	packages/map_core/lib/src/models/project_manifest.g.dart
M	packages/map_core/lib/src/models/projected_building_shadow.dart
M	packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart
```

## 19. git diff --check

Commande :

```bash
git diff --check
```

Sortie :

```text

```

## 20. git status final

Commande :

```bash
git status --short --untracked-files=all
```

```text
 M packages/map_core/lib/src/models/project_manifest.dart
 M packages/map_core/lib/src/models/project_manifest.freezed.dart
 M packages/map_core/lib/src/models/project_manifest.g.dart
 M packages/map_core/lib/src/models/projected_building_shadow.dart
 M packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart
?? packages/map_core/test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart
?? reports/shadows/v2/shadow_v2_14_projected_building_shadow_manifest_element_persistence_integration.md
```

## 21. Risques / réserves

- Le prompt n'a pas listé explicitement `packages/map_core/lib/src/models/projected_building_shadow.dart` dans les fichiers modifiables, mais le champ Freezed non-nullable nécessite un default const. Le changement appliqué est limité à `const ProjectBuildingShadowPresetCatalog.empty()` et ne crée aucune donnée V2.
- `build_runner` signale deux warnings existants liés aux versions SDK/analyzer et `json_annotation`. Ils n'ont pas bloqué la génération.
- Le comportement V2 diverge volontairement de V1 : `shadowCatalog` vide est émis, mais `projectedBuildingShadowCatalog` vide est omis.
- Les diagnostics sémantiques `presetId` manquant dans le catalogue ne sont pas encore implémentés.

## 22. Auto-critique

Le point principal à surveiller est le passage de tests de caractérisation V2-3 à une vraie intégration V2. Le test historique qui traitait `projectedBuildingShadow` comme clé inconnue devait être ajusté, car ce champ est maintenant connu et validé.

La modification reste bornée : elle ajoute la persistance et les hooks JSON, mais ne consomme pas les données ailleurs.

## 23. Regard critique sur le prompt

Le prompt est cohérent et protège bien le périmètre runtime/editor.

Un point aurait mérité d'être explicitement autorisé :

```text
packages/map_core/lib/src/models/projected_building_shadow.dart
```

Raison :

- `ProjectManifest.projectedBuildingShadowCatalog` doit être non-nullable ;
- Freezed a besoin d'une valeur default const pour ne pas casser les constructeurs existants ;
- le constructeur vide const du catalogue est le plus petit ajustement possible.

## 24. Prochain lot recommandé

```text
ShadowV2-15 — Projected Building Shadow Semantic Diagnostics Design Gate
```

Objectif recommandé :

```text
Définir, sans runtime/editor, les diagnostics futurs :
- element presetId absent du catalogue ;
- presets inutilisés ;
- catalogue vide mais éléments référencent des presets ;
- coexistence V1/V2 à signaler selon policy ;
- followsSun sans système jour/nuit actif.
```

## 25. Inventaire complet des fichiers

Créés :

- `packages/map_core/test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart`
- `reports/shadows/v2/shadow_v2_14_projected_building_shadow_manifest_element_persistence_integration.md`

Modifiés :

- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/project_manifest.freezed.dart`
- `packages/map_core/lib/src/models/project_manifest.g.dart`
- `packages/map_core/lib/src/models/projected_building_shadow.dart`
- `packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart`

Supprimés :

- Aucun.

Generated modifiés :

- `packages/map_core/lib/src/models/project_manifest.freezed.dart`
- `packages/map_core/lib/src/models/project_manifest.g.dart`

Selbrume :

- Aucun fichier Selbrume modifié.

Commits :

- Aucun commit effectué.
