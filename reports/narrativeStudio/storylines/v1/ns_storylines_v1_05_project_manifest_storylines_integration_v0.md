# NS-STORYLINES-V1-05 — ProjectManifest.storylines Integration V0

## 1. Executive summary

NS-STORYLINES-V1-05 est livré. `ProjectManifest` porte maintenant `storylines: List<StorylineAsset>` avec un default `[]`, une sérialisation JSON via le codec `StorylineAsset` existant, et une compatibilité stricte avec les anciens `project.json` sans champ `storylines`.

Le lot reste volontairement borné : aucune migration legacy, aucun import automatique depuis `ScenarioAsset.globalStory`, aucune promotion de `localEventFlow` en `sideQuest`, aucune UI et aucun runtime modifié.

## 2. Inputs read

- AGENTS.md
- agent_rules.md
- skills/README.md
- reports/narrativeStudio/storylines/road_map_storylines.md
- reports/narrativeStudio/storylines/ns_storylines_v1_04_storyline_asset_json_codec_v0.md
- reports/narrativeStudio/storylines/ns_storylines_v1_03_storyline_asset_pure_model_v0.md
- reports/narrativeStudio/storylines/ns_storylines_v1_02_storyline_authoring_data_shape_contract.md
- reports/narrativeStudio/storylines/ns_storylines_v1_01_storyline_authoring_model_decision.md
- packages/map_core/lib/src/models/project_manifest.dart
- packages/map_core/lib/src/models/storyline_asset.dart
- packages/map_core/lib/src/models/scenario_asset.dart
- packages/map_core/lib/map_core.dart
- packages/map_core/test/
- packages/map_core/test/scenario_assets_test.dart

Fichiers attendus mais absents :

- packages/map_core/test/project_manifest_test.dart
- packages/map_core/test/project_manifest_json_test.dart

## 3. Implementation summary

- Ajout de l'import `storyline_asset.dart` dans `ProjectManifest`.
- Ajout du champ Freezed/json_serializable `storylines` avec `@Default([])` et `@JsonKey` dédié.
- Ajout de helpers JSON stricts pour décoder une liste de `StorylineAsset` sans migration implicite.
- Régénération contrôlée des fichiers Freezed/json_serializable du manifest, car `ProjectManifest` est un modèle généré.
- Ajout de `project_manifest_storylines_test.dart` pour couvrir compatibilité vieux JSON, decode storylines, roundtrip et non-migration.

## 4. ProjectManifest shape

Le manifest a maintenant la forme conceptuelle suivante côté Storylines :

```dart
@Default([])
@JsonKey(
  name: 'storylines',
  fromJson: _storylinesFromJson,
  toJson: _storylinesToJson,
)
List<StorylineAsset> storylines,
```

Le champ est non nullable, exposé par Freezed comme liste immuable, et inclus dans `copyWith`, equality, hashCode, `toString`, `fromJson` et `toJson` via les fichiers générés.

## 5. JSON compatibility behavior

- JSON sans champ `storylines` : decode en `[]`.
- JSON avec `storylines: null` : helper manuel prévu pour `[]`; le généré actuel traite le champ absent en `[]` et délègue au helper sinon.
- JSON avec liste valide : chaque item passe par `StorylineAsset.fromJson(...)`.
- JSON avec `storylines` non-liste : `ValidationException`.
- JSON avec item non-objet : `ValidationException`.
- JSON avec storyline invalide : erreur remontée par le codec / constructeur `StorylineAsset`.

## 6. Legacy non-migration guarantee

Ce lot ne migre rien. Un `ScenarioAsset(scope == globalStory)` reste dans `ProjectManifest.scenarios` et ne crée pas automatiquement de `StorylineAsset`. Un `ScenarioAsset(scope == localEventFlow)` reste un flow local et ne devient jamais une `sideQuest` par défaut.

Cette garantie est couverte par tests dédiés.

## 7. Generated files / build_runner decision

`ProjectManifest` utilise déjà Freezed/json_serializable. Modifier sa factory sans régénérer aurait laissé les fichiers générés incohérents avec le modèle source. Le build runner a donc été lancé uniquement dans `packages/map_core` :

```bash
cd packages/map_core && dart run build_runner build --delete-conflicting-outputs
```

Fichiers générés modifiés :

- `packages/map_core/lib/src/models/project_manifest.freezed.dart`
- `packages/map_core/lib/src/models/project_manifest.g.dart`

Aucun fichier généré n'a été modifié manuellement.

## 8. Non-goals confirmed

- `StorylineAsset` non modifié.
- `ScenarioAsset` non modifié.
- Aucun `ProjectManifest` legacy import ajouté.
- Aucun mapping `GlobalStoryStudioDocument -> StorylineAsset` ajouté.
- Aucun `localEventFlow` promu en `sideQuest`.
- Aucune UI modifiée.
- Aucun runtime / gameplay / battle modifié.
- Aucun screenshot modifié.
- V1-06 non démarré.

## 9. Tests added or modified

Test créé :

- `packages/map_core/test/project_manifest_storylines_test.dart`

Couverture ajoutée :

- ancien JSON sans `storylines` decode en liste vide ;
- JSON avec storyline `main` et `sideQuest` ;
- roundtrip `ProjectManifest.toJson()` / `ProjectManifest.fromJson(...)` ;
- absence d'import automatique depuis `ScenarioAsset.globalStory` ;
- absence de promotion `localEventFlow` en `sideQuest` ;
- invalid JSON storylines.

Aucun test existant de ProjectManifest n'a été modifié. Les fichiers `test/project_manifest_test.dart` et `test/project_manifest_json_test.dart` sont absents dans `packages/map_core`.

## 10. Commands run

```bash
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git diff --check
sed -n '1,220p' packages/map_core/lib/src/models/project_manifest.dart
sed -n '1,240p' packages/map_core/lib/src/models/storyline_asset.dart
sed -n '1,220p' packages/map_core/lib/src/models/scenario_asset.dart
sed -n '1,160p' packages/map_core/lib/map_core.dart
find packages/map_core/test -maxdepth 1 -type f | sort
rg -n "class ProjectManifest|freezed|fromJson|toJson|ScenarioScope|storylines" packages/map_core/lib/src/models packages/map_core/test reports/narrativeStudio/storylines/road_map_storylines.md
cd packages/map_core && dart run build_runner build --delete-conflicting-outputs
dart format lib/src/models/project_manifest.dart test/project_manifest_storylines_test.dart
cd packages/map_core && dart test --reporter json test/project_manifest_storylines_test.dart | tail -n 1
cd packages/map_core && dart test --reporter json test/storyline_asset_json_test.dart | tail -n 1
cd packages/map_core && dart test --reporter json test/storyline_asset_test.dart | tail -n 1
cd packages/map_core && dart test --reporter json test/scenario_assets_test.dart | tail -n 1
cd packages/map_core && dart analyze lib/src/models/project_manifest.dart test/project_manifest_storylines_test.dart
cd packages/map_core && dart test --reporter json | tail -n 1
cd packages/map_core && test -f test/project_manifest_test.dart && echo exists || echo missing; test -f test/project_manifest_json_test.dart && echo exists || echo missing
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git diff --check
```

## 11. Roadmap update

`reports/narrativeStudio/storylines/road_map_storylines.md` a été mis à jour :

- `NS-STORYLINES-V1-05` marqué `DONE`.
- Résumé du champ `ProjectManifest.storylines` ajouté.
- Tests et analyse listés.
- Generated files et build_runner documentés.
- Non-migration legacy confirmée.
- Prochain lot recommandé : `NS-STORYLINES-V1-06 — Legacy GlobalStory Import Preview V0`.

## 12. Evidence Pack

### Git branch initiale

```text
main
```

### Git status initial exact

```text
Sortie : <vide>
```

### Git diff --stat initial

```text
Sortie : <vide>
```

### Git diff --name-only initial

```text
Sortie : <vide>
```

### Git diff --check initial

```text
Sortie : <vide>
```

### Liste des fichiers lus

- AGENTS.md
- agent_rules.md
- skills/README.md
- reports/narrativeStudio/storylines/road_map_storylines.md
- reports/narrativeStudio/storylines/ns_storylines_v1_04_storyline_asset_json_codec_v0.md
- reports/narrativeStudio/storylines/ns_storylines_v1_03_storyline_asset_pure_model_v0.md
- reports/narrativeStudio/storylines/ns_storylines_v1_02_storyline_authoring_data_shape_contract.md
- reports/narrativeStudio/storylines/ns_storylines_v1_01_storyline_authoring_model_decision.md
- packages/map_core/lib/src/models/project_manifest.dart
- packages/map_core/lib/src/models/storyline_asset.dart
- packages/map_core/lib/src/models/scenario_asset.dart
- packages/map_core/lib/map_core.dart
- packages/map_core/test/
- packages/map_core/test/scenario_assets_test.dart

### Liste des fichiers absents mais attendus

- packages/map_core/test/project_manifest_test.dart
- packages/map_core/test/project_manifest_json_test.dart

Vérification :

```text
missing
missing
```

### Diff complet de project_manifest.dart

```diff
diff --git a/packages/map_core/lib/src/models/project_manifest.dart b/packages/map_core/lib/src/models/project_manifest.dart
index fda7b272..eda59fab 100644
--- a/packages/map_core/lib/src/models/project_manifest.dart
+++ b/packages/map_core/lib/src/models/project_manifest.dart
@@ -11,6 +11,7 @@ import 'scenario_asset.dart';
 import 'script_asset.dart';
 import 'shadow.dart';
 import 'shadow_catalog.dart';
+import 'storyline_asset.dart';
 import 'surface_catalog.dart';
 import 'tileset_transparent_color.dart';
 import 'visual_frame_json.dart';
@@ -47,6 +48,41 @@ Map<String, Object?> _projectSurfaceCatalogToJson(
   return encodeProjectSurfaceCatalog(catalog);
 }
 
+/// JSON -> authoring Storylines.
+///
+/// Missing or `null` keeps old projects readable as an empty list. This is
+/// intentionally not a legacy import from `ScenarioAsset.globalStory`.
+List<StorylineAsset> _storylinesFromJson(Object? json) {
+  if (json == null) {
+    return const <StorylineAsset>[];
+  }
+  if (json is! List) {
+    throw const ValidationException('storylines must be a JSON list');
+  }
+  return [
+    for (final item in json)
+      StorylineAsset.fromJson(_storylineJsonObject(item)),
+  ];
+}
+
+List<Map<String, dynamic>> _storylinesToJson(
+  List<StorylineAsset> storylines,
+) {
+  return [for (final storyline in storylines) storyline.toJson()];
+}
+
+Map<String, dynamic> _storylineJsonObject(Object? json) {
+  if (json is! Map) {
+    throw const ValidationException('storyline must be a JSON object');
+  }
+  return json.map((key, value) {
+    if (key is! String) {
+      throw const ValidationException('storyline JSON keys must be strings');
+    }
+    return MapEntry(key, value);
+  });
+}
+
 /// JSON -> ShadowV2 projected building shadow catalog.
 ///
 /// Missing or `null` root data remains an empty in-memory catalog. When the
@@ -165,6 +201,13 @@ class ProjectManifest with _$ProjectManifest {
     @Default([]) List<ProjectDialogueEntry> dialogues,
     @Default([]) List<ProjectScriptEntry> scripts,
     @Default([]) List<ScenarioAsset> scenarios,
+    @Default([])
+    @JsonKey(
+      name: 'storylines',
+      fromJson: _storylinesFromJson,
+      toJson: _storylinesToJson,
+    )
+    List<StorylineAsset> storylines,
     @Default([]) List<ProjectTrainerEntry> trainers,
     @Default([]) List<ProjectCharacterEntry> characters,
     @Default(ProjectSettings()) ProjectSettings settings,
```

### Contenu complet de project_manifest_storylines_test.dart

```dart
import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectManifest storylines integration', () {
    test('decodes old project JSON without storylines as empty list', () {
      final manifest = ProjectManifest.fromJson(_minimalProjectJson());

      expect(manifest.storylines, isEmpty);
      expect(manifest.scenarios, isEmpty);
    });

    test('decodes project JSON with main and side quest storylines', () {
      final manifest = ProjectManifest.fromJson({
        ..._minimalProjectJson(),
        'storylines': [
          _mainStoryline().toJson(),
          _sideQuestStoryline().toJson(),
        ],
      });

      expect(manifest.storylines, hasLength(2));
      expect(manifest.storylines[0].type, StorylineType.main);
      expect(manifest.storylines[0].title, 'Main Story');
      expect(manifest.storylines[1].type, StorylineType.sideQuest);
      expect(manifest.storylines[1].title, 'Side Quest');
    });

    test('round-trips manifest with storylines through JSON', () {
      final manifest = ProjectManifest(
        name: 'Project',
        maps: const [],
        tilesets: const [],
        storylines: [_mainStoryline(), _sideQuestStoryline()],
      );

      final json =
          jsonDecode(jsonEncode(manifest.toJson())) as Map<String, dynamic>;
      final decoded = ProjectManifest.fromJson(json);

      expect(decoded.storylines, equals(manifest.storylines));
      expect(decoded.toJson()['storylines'], isA<List<dynamic>>());
    });

    test('does not import legacy globalStory scenarios automatically', () {
      final scenario = const ScenarioAsset(
        id: 'legacy_global_story',
        name: 'Legacy Global Story',
        scope: ScenarioScope.globalStory,
        entryNodeId: 'start',
        nodes: [
          ScenarioNode(id: 'start', type: ScenarioNodeType.start),
        ],
      );
      final manifest = ProjectManifest.fromJson({
        ..._minimalProjectJson(),
        'scenarios': [scenario.toJson()],
      });

      expect(manifest.storylines, isEmpty);
      expect(manifest.scenarios, hasLength(1));
      expect(manifest.scenarios.single.scope, ScenarioScope.globalStory);
      expect(manifest.scenarios.single.id, 'legacy_global_story');
    });

    test('does not promote localEventFlow scenario to side quest', () {
      final scenario = const ScenarioAsset(
        id: 'local_event_flow',
        name: 'Local Event Flow',
        scope: ScenarioScope.localEventFlow,
        entryNodeId: 'start',
        nodes: [
          ScenarioNode(id: 'start', type: ScenarioNodeType.start),
        ],
      );
      final manifest = ProjectManifest.fromJson({
        ..._minimalProjectJson(),
        'scenarios': [scenario.toJson()],
      });

      expect(manifest.storylines, isEmpty);
      expect(manifest.scenarios.single.scope, ScenarioScope.localEventFlow);
    });

    test('rejects invalid storylines JSON shape', () {
      expect(
        () => ProjectManifest.fromJson({
          ..._minimalProjectJson(),
          'storylines': 'not-a-list',
        }),
        _throwsDecode,
      );
      expect(
        () => ProjectManifest.fromJson({
          ..._minimalProjectJson(),
          'storylines': ['not-an-object'],
        }),
        _throwsDecode,
      );
      expect(
        () => ProjectManifest.fromJson({
          ..._minimalProjectJson(),
          'storylines': [
            {
              'id': 'broken',
              'type': 'unknown',
              'title': 'Broken',
            },
          ],
        }),
        _throwsDecode,
      );
      expect(
        () => ProjectManifest.fromJson({
          ..._minimalProjectJson(),
          'storylines': [
            {
              'id': '',
              'type': 'main',
              'title': 'Broken',
            },
          ],
        }),
        _throwsDecode,
      );
    });
  });
}

final Matcher _throwsDecode = throwsA(
  anyOf(isA<FormatException>(), isA<ValidationException>()),
);

Map<String, dynamic> _minimalProjectJson() {
  return {
    'name': 'Project',
    'maps': <Object?>[],
    'tilesets': <Object?>[],
  };
}

StorylineAsset _mainStoryline() {
  return StorylineAsset(
    id: 'main_story',
    type: StorylineType.main,
    title: 'Main Story',
  );
}

StorylineAsset _sideQuestStoryline() {
  return StorylineAsset(
    id: 'side_quest',
    type: StorylineType.sideQuest,
    title: 'Side Quest',
  );
}

```

### Diff complet des tests ProjectManifest modifiés

Aucun test ProjectManifest existant n'a été modifié. Le nouveau test est reproduit intégralement ci-dessus.

### Diff complet des fichiers générés modifiés

```diff
diff --git a/packages/map_core/lib/src/models/project_manifest.freezed.dart b/packages/map_core/lib/src/models/project_manifest.freezed.dart
index e5981b9b..56de7193 100644
--- a/packages/map_core/lib/src/models/project_manifest.freezed.dart
+++ b/packages/map_core/lib/src/models/project_manifest.freezed.dart
@@ -57,6 +57,11 @@ mixin _$ProjectManifest {
       throw _privateConstructorUsedError;
   List<ProjectScriptEntry> get scripts => throw _privateConstructorUsedError;
   List<ScenarioAsset> get scenarios => throw _privateConstructorUsedError;
+  @JsonKey(
+      name: 'storylines',
+      fromJson: _storylinesFromJson,
+      toJson: _storylinesToJson)
+  List<StorylineAsset> get storylines => throw _privateConstructorUsedError;
   List<ProjectTrainerEntry> get trainers => throw _privateConstructorUsedError;
   List<ProjectCharacterEntry> get characters =>
       throw _privateConstructorUsedError;
@@ -124,6 +129,11 @@ abstract class $ProjectManifestCopyWith<$Res> {
       List<ProjectDialogueEntry> dialogues,
       List<ProjectScriptEntry> scripts,
       List<ScenarioAsset> scenarios,
+      @JsonKey(
+          name: 'storylines',
+          fromJson: _storylinesFromJson,
+          toJson: _storylinesToJson)
+      List<StorylineAsset> storylines,
       List<ProjectTrainerEntry> trainers,
       List<ProjectCharacterEntry> characters,
       ProjectSettings settings,
@@ -180,6 +190,7 @@ class _$ProjectManifestCopyWithImpl<$Res, $Val extends ProjectManifest>
     Object? dialogues = null,
     Object? scripts = null,
     Object? scenarios = null,
+    Object? storylines = null,
     Object? trainers = null,
     Object? characters = null,
     Object? settings = null,
@@ -266,6 +277,10 @@ class _$ProjectManifestCopyWithImpl<$Res, $Val extends ProjectManifest>
           ? _value.scenarios
           : scenarios // ignore: cast_nullable_to_non_nullable
               as List<ScenarioAsset>,
+      storylines: null == storylines
+          ? _value.storylines
+          : storylines // ignore: cast_nullable_to_non_nullable
+              as List<StorylineAsset>,
       trainers: null == trainers
           ? _value.trainers
           : trainers // ignore: cast_nullable_to_non_nullable
@@ -358,6 +373,11 @@ abstract class _$$ProjectManifestImplCopyWith<$Res>
       List<ProjectDialogueEntry> dialogues,
       List<ProjectScriptEntry> scripts,
       List<ScenarioAsset> scenarios,
+      @JsonKey(
+          name: 'storylines',
+          fromJson: _storylinesFromJson,
+          toJson: _storylinesToJson)
+      List<StorylineAsset> storylines,
       List<ProjectTrainerEntry> trainers,
       List<ProjectCharacterEntry> characters,
       ProjectSettings settings,
@@ -414,6 +434,7 @@ class __$$ProjectManifestImplCopyWithImpl<$Res>
     Object? dialogues = null,
     Object? scripts = null,
     Object? scenarios = null,
+    Object? storylines = null,
     Object? trainers = null,
     Object? characters = null,
     Object? settings = null,
@@ -500,6 +521,10 @@ class __$$ProjectManifestImplCopyWithImpl<$Res>
           ? _value._scenarios
           : scenarios // ignore: cast_nullable_to_non_nullable
               as List<ScenarioAsset>,
+      storylines: null == storylines
+          ? _value._storylines
+          : storylines // ignore: cast_nullable_to_non_nullable
+              as List<StorylineAsset>,
       trainers: null == trainers
           ? _value._trainers
           : trainers // ignore: cast_nullable_to_non_nullable
@@ -568,6 +593,11 @@ class _$ProjectManifestImpl implements _ProjectManifest {
       final List<ProjectDialogueEntry> dialogues = const [],
       final List<ProjectScriptEntry> scripts = const [],
       final List<ScenarioAsset> scenarios = const [],
+      @JsonKey(
+          name: 'storylines',
+          fromJson: _storylinesFromJson,
+          toJson: _storylinesToJson)
+      final List<StorylineAsset> storylines = const [],
       final List<ProjectTrainerEntry> trainers = const [],
       final List<ProjectCharacterEntry> characters = const [],
       this.settings = const ProjectSettings(),
@@ -604,6 +634,7 @@ class _$ProjectManifestImpl implements _ProjectManifest {
         _dialogues = dialogues,
         _scripts = scripts,
         _scenarios = scenarios,
+        _storylines = storylines,
         _trainers = trainers,
         _characters = characters,
         _globalProperties = globalProperties;
@@ -777,6 +808,18 @@ class _$ProjectManifestImpl implements _ProjectManifest {
     return EqualUnmodifiableListView(_scenarios);
   }
 
+  final List<StorylineAsset> _storylines;
+  @override
+  @JsonKey(
+      name: 'storylines',
+      fromJson: _storylinesFromJson,
+      toJson: _storylinesToJson)
+  List<StorylineAsset> get storylines {
+    if (_storylines is EqualUnmodifiableListView) return _storylines;
+    // ignore: implicit_dynamic_type
+    return EqualUnmodifiableListView(_storylines);
+  }
+
   final List<ProjectTrainerEntry> _trainers;
   @override
   @JsonKey()
@@ -830,7 +873,7 @@ class _$ProjectManifestImpl implements _ProjectManifest {
 
   @override
   String toString() {
-    return 'ProjectManifest(name: $name, version: $version, maps: $maps, groups: $groups, tilesetFolders: $tilesetFolders, tilesets: $tilesets, elementCategories: $elementCategories, elements: $elements, terrainCategories: $terrainCategories, pathCategories: $pathCategories, terrainPresets: $terrainPresets, pathPresets: $pathPresets, pathPatternPresets: $pathPatternPresets, environmentPresets: $environmentPresets, encounterTables: $encounterTables, dialogueFolders: $dialogueFolders, dialogues: $dialogues, scripts: $scripts, scenarios: $scenarios, trainers: $trainers, characters: $characters, settings: $settings, pokemon: $pokemon, globalProperties: $globalProperties, surfaceCatalog: $surfaceCatalog, shadowCatalog: $shadowCatalog, projectedBuildingShadowCatalog: $projectedBuildingShadowCatalog)';
+    return 'ProjectManifest(name: $name, version: $version, maps: $maps, groups: $groups, tilesetFolders: $tilesetFolders, tilesets: $tilesets, elementCategories: $elementCategories, elements: $elements, terrainCategories: $terrainCategories, pathCategories: $pathCategories, terrainPresets: $terrainPresets, pathPresets: $pathPresets, pathPatternPresets: $pathPatternPresets, environmentPresets: $environmentPresets, encounterTables: $encounterTables, dialogueFolders: $dialogueFolders, dialogues: $dialogues, scripts: $scripts, scenarios: $scenarios, storylines: $storylines, trainers: $trainers, characters: $characters, settings: $settings, pokemon: $pokemon, globalProperties: $globalProperties, surfaceCatalog: $surfaceCatalog, shadowCatalog: $shadowCatalog, projectedBuildingShadowCatalog: $projectedBuildingShadowCatalog)';
   }
 
   @override
@@ -869,6 +912,8 @@ class _$ProjectManifestImpl implements _ProjectManifest {
             const DeepCollectionEquality().equals(other._scripts, _scripts) &&
             const DeepCollectionEquality()
                 .equals(other._scenarios, _scenarios) &&
+            const DeepCollectionEquality()
+                .equals(other._storylines, _storylines) &&
             const DeepCollectionEquality().equals(other._trainers, _trainers) &&
             const DeepCollectionEquality()
                 .equals(other._characters, _characters) &&
@@ -910,6 +955,7 @@ class _$ProjectManifestImpl implements _ProjectManifest {
         const DeepCollectionEquality().hash(_dialogues),
         const DeepCollectionEquality().hash(_scripts),
         const DeepCollectionEquality().hash(_scenarios),
+        const DeepCollectionEquality().hash(_storylines),
         const DeepCollectionEquality().hash(_trainers),
         const DeepCollectionEquality().hash(_characters),
         settings,
@@ -966,6 +1012,11 @@ abstract class _ProjectManifest implements ProjectManifest {
       final List<ProjectDialogueEntry> dialogues,
       final List<ProjectScriptEntry> scripts,
       final List<ScenarioAsset> scenarios,
+      @JsonKey(
+          name: 'storylines',
+          fromJson: _storylinesFromJson,
+          toJson: _storylinesToJson)
+      final List<StorylineAsset> storylines,
       final List<ProjectTrainerEntry> trainers,
       final List<ProjectCharacterEntry> characters,
       final ProjectSettings settings,
@@ -1036,6 +1087,12 @@ abstract class _ProjectManifest implements ProjectManifest {
   @override
   List<ScenarioAsset> get scenarios;
   @override
+  @JsonKey(
+      name: 'storylines',
+      fromJson: _storylinesFromJson,
+      toJson: _storylinesToJson)
+  List<StorylineAsset> get storylines;
+  @override
   List<ProjectTrainerEntry> get trainers;
   @override
   List<ProjectCharacterEntry> get characters;
diff --git a/packages/map_core/lib/src/models/project_manifest.g.dart b/packages/map_core/lib/src/models/project_manifest.g.dart
index 6dc870f8..3b0e143c 100644
--- a/packages/map_core/lib/src/models/project_manifest.g.dart
+++ b/packages/map_core/lib/src/models/project_manifest.g.dart
@@ -87,6 +87,9 @@ _$ProjectManifestImpl _$$ProjectManifestImplFromJson(
               ?.map((e) => ScenarioAsset.fromJson(e as Map<String, dynamic>))
               .toList() ??
           const [],
+      storylines: json['storylines'] == null
+          ? const []
+          : _storylinesFromJson(json['storylines']),
       trainers: (json['trainers'] as List<dynamic>?)
               ?.map((e) =>
                   ProjectTrainerEntry.fromJson(e as Map<String, dynamic>))
@@ -148,6 +151,7 @@ Map<String, dynamic> _$$ProjectManifestImplToJson(
       'dialogues': instance.dialogues.map((e) => e.toJson()).toList(),
       'scripts': instance.scripts.map((e) => e.toJson()).toList(),
       'scenarios': instance.scenarios.map((e) => e.toJson()).toList(),
+      'storylines': _storylinesToJson(instance.storylines),
       'trainers': instance.trainers.map((e) => e.toJson()).toList(),
       'characters': instance.characters.map((e) => e.toJson()).toList(),
       'settings': instance.settings.toJson(),
```

### Diff complet de road_map_storylines.md

```diff
diff --git a/reports/narrativeStudio/storylines/road_map_storylines.md b/reports/narrativeStudio/storylines/road_map_storylines.md
index a1fc7cd3..6f1058db 100644
--- a/reports/narrativeStudio/storylines/road_map_storylines.md
+++ b/reports/narrativeStudio/storylines/road_map_storylines.md
@@ -306,7 +306,7 @@ Interprétation V0 :
 | NS-STORYLINES-V1-02 | Storyline Authoring Data Shape Contract | data contract | DONE | NS-STORYLINES-V1-03 |
 | NS-STORYLINES-V1-03 | StorylineAsset Pure Model V0 | core model / pure dart | DONE | NS-STORYLINES-V1-04 |
 | NS-STORYLINES-V1-04 | StorylineAsset JSON Codec V0 | core codec | DONE | NS-STORYLINES-V1-05 |
-| NS-STORYLINES-V1-05 | ProjectManifest.storylines Integration V0 | core manifest | TODO | NS-STORYLINES-V1-06 |
+| NS-STORYLINES-V1-05 | ProjectManifest.storylines Integration V0 | core manifest | DONE | NS-STORYLINES-V1-06 |
 | NS-STORYLINES-V1-06 | Legacy GlobalStory Import Preview V0 | migration preview | TODO | NS-STORYLINES-V1-07 |
 | NS-STORYLINES-V1-07 | Create Main Storyline Flow V0 | editor authoring | TODO | NS-STORYLINES-V1-08 |
 
@@ -690,6 +690,23 @@ Interprétation V0 :
 - Statut : DONE.
 - Prochain lot attendu : NS-STORYLINES-V1-05 — ProjectManifest.storylines Integration V0.
 
+### NS-STORYLINES-V1-05 — ProjectManifest.storylines Integration V0
+
+- Type : core manifest / JSON compatibility / pure Dart / tests.
+- Objectif : intégrer `StorylineAsset` dans `ProjectManifest.storylines`, sans migration legacy, sans UI et sans runtime.
+- Résultat : `ProjectManifest` porte désormais `storylines: List<StorylineAsset>` avec default `[]`, roundtrip JSON et compatibilité vieux projets sans champ `storylines`.
+- JSON : `storylines` est sérialisé via `StorylineAsset.toJson()` et désérialisé via `StorylineAsset.fromJson(...)`; champ absent ou `null` donne `[]`.
+- Compatibilité : les anciens `ScenarioAsset(scope == globalStory)` restent dans `ProjectManifest.scenarios`; aucune `StorylineAsset` n'est créée automatiquement.
+- Non-promotion : `ScenarioAsset(scope == localEventFlow)` reste un scénario local et n'est jamais promu en `sideQuest`.
+- Generated files : `ProjectManifest` utilise Freezed/json_serializable ; build_runner limité à `packages/map_core` a régénéré uniquement les fichiers générés du manifest.
+- Fichiers créés/modifiés : `packages/map_core/lib/src/models/project_manifest.dart`, `packages/map_core/lib/src/models/project_manifest.freezed.dart`, `packages/map_core/lib/src/models/project_manifest.g.dart`, `packages/map_core/test/project_manifest_storylines_test.dart`, `reports/narrativeStudio/storylines/ns_storylines_v1_05_project_manifest_storylines_integration_v0.md`, `reports/narrativeStudio/storylines/road_map_storylines.md`.
+- Tests exécutés : `dart test test/project_manifest_storylines_test.dart`, `dart test test/storyline_asset_json_test.dart`, `dart test test/storyline_asset_test.dart`, `dart test test/scenario_assets_test.dart`, `dart test`.
+- Analyse exécutée : `dart analyze lib/src/models/project_manifest.dart test/project_manifest_storylines_test.dart`.
+- Non-objectifs confirmés : `StorylineAsset` non modifié, `ScenarioAsset` non modifié, aucune migration legacy, aucun import globalStory, aucune UI, aucun runtime.
+- Dépendances : NS-STORYLINES-V1-04.
+- Statut : DONE.
+- Prochain lot attendu : NS-STORYLINES-V1-06 — Legacy GlobalStory Import Preview V0.
+
 ## 10. Update protocol for every future lot
 
 Chaque futur lot Storylines doit :
@@ -806,10 +823,10 @@ Décision temporaire :
 ## 13. Current status
 
 ```text
-Roadmap status: V0 ACCEPTED WITH V1 LIMITATIONS / V1 JSON CODEC DONE
-Current lot: NS-STORYLINES-V1-04
+Roadmap status: V0 ACCEPTED WITH V1 LIMITATIONS / V1 MANIFEST STORYLINES DONE
+Current lot: NS-STORYLINES-V1-05
 Current lot status: DONE
-Next recommended lot: NS-STORYLINES-V1-05 — ProjectManifest.storylines Integration V0
+Next recommended lot: NS-STORYLINES-V1-06 — Legacy GlobalStory Import Preview V0
 ```
 
 | Lot | Status | Last update | Notes |
@@ -833,7 +850,7 @@ Next recommended lot: NS-STORYLINES-V1-05 — ProjectManifest.storylines Integra
 | NS-STORYLINES-V1-02 | DONE | 2026-05-28 | Contrat data shape `StorylineAsset` livré : champs, enums, invariants, validations, JSON, migration legacy, UI actions et tests futurs. |
 | NS-STORYLINES-V1-03 | DONE | 2026-05-28 | StorylineAsset Pure Model V0 livré dans `map_core`, sans JSON/manifest/UI. |
 | NS-STORYLINES-V1-04 | DONE | 2026-05-28 | StorylineAsset JSON Codec V0 livré, sans manifest/migration/UI. |
-| NS-STORYLINES-V1-05 | TODO | 2026-05-28 | ProjectManifest.storylines Integration V0. |
+| NS-STORYLINES-V1-05 | DONE | 2026-05-28 | ProjectManifest.storylines Integration V0 livré avec compatibilité vieux JSON et sans migration legacy. |
 | NS-STORYLINES-V1-06 | TODO | 2026-05-28 | Legacy GlobalStory Import Preview V0. |
 | NS-STORYLINES-V1-07 | TODO | 2026-05-28 | Create Main Storyline Flow V0. |
 
@@ -870,6 +887,16 @@ Suite V1 documentaire recommandée :
 
 ## 15. Changelog
 
+### 2026-05-28 — NS-STORYLINES-V1-05
+
+- `ProjectManifest.storylines: List<StorylineAsset>` intégré dans `map_core`.
+- Compatibilité vieux projets confirmée : absence du champ `storylines` décodée en `[]`.
+- Roundtrip JSON `ProjectManifest` avec storylines couvert par tests.
+- Aucune migration legacy : `ScenarioAsset.globalStory` reste dans `scenarios` et ne crée pas automatiquement de `StorylineAsset`.
+- `localEventFlow` reste exclu comme `sideQuest` par défaut.
+- Non-objectifs respectés : `StorylineAsset` non modifié, `ScenarioAsset` non modifié, aucune UI, aucun runtime.
+- Prochain lot recommandé : `NS-STORYLINES-V1-06 — Legacy GlobalStory Import Preview V0`.
+
 ### 2026-05-28 — NS-STORYLINES-V1-04
 
 - Codec JSON manuel livré pour `StorylineAsset` et ses sous-objets essentiels.
```

### Sortie exacte build_runner

```text
Generating the build script.
Generating the build script.
Compiling the build script.
Reading the asset graph.
Generating the build script.
Compiling the build script.
Reading the asset graph.
Creating the asset graph.
Doing initial build cleanup.
Updating the asset graph.
Building, full build because builders changed.
0s freezed on 284 inputs; lib/map_core.dart
W SDK language version 3.12.0 is newer than `analyzer` language version 3.9.0. Run `dart pub upgrade`.
3s freezed on 284 inputs: 1 no-op; spent 3s sdk; lib/src/authoring/narrative_event_source_authoring_operations.dart
4s freezed on 284 inputs: 5 no-op; spent 3s sdk; lib/src/authoring/narrative_validator_authoring_adapter.dart
5s freezed on 284 inputs: 13 output, 12 no-op; spent 3s sdk, 1s analyzing; lib/src/models/project_manifest.dart
7s freezed on 284 inputs: 19 output, 18 no-op; spent 3s sdk, 2s analyzing, 1s building; lib/src/models/surface_catalog.dart
7s freezed on 284 inputs: 20 output, 264 no-op; spent 3s sdk, 2s analyzing, 1s building
0s json_serializable on 568 inputs; lib/map_core.dart
1s json_serializable on 568 inputs: 1 no-op; lib/map_core.freezed.dart
W json_serializable on lib/src/models/element_collision_profile.dart:
The version constraint "^4.8.1" on json_annotation allows versions before 4.9.0 which is not allowed.
2s json_serializable on 568 inputs: 12 skipped, 14 output, 25 no-op; spent 1s analyzing; lib/src/models/project_manifest.freezed.dart
3s json_serializable on 568 inputs: 117 skipped, 20 output, 138 no-op; spent 3s analyzing; test/beta_playability_validator_test.freezed.dart
4s json_serializable on 568 inputs: 209 skipped, 20 output, 230 no-op; spent 4s analyzing; test/shadow/static_shadow_footprint_config_test.freezed.dart
5s json_serializable on 568 inputs: 264 skipped, 20 output, 284 no-op; spent 4s analyzing
0s source_gen:combining_builder on 568 inputs; lib/map_core.dart
0s source_gen:combining_builder on 568 inputs: 264 skipped, 20 output, 284 no-op
Running the post build.
Writing the asset graph.
Built with build_runner in 17s; wrote 60 outputs.
```

### Sortie exacte dart format

```text
Formatted test/project_manifest_storylines_test.dart
Formatted 2 files (1 changed) in 0.01 seconds.
```

### Sorties exactes des tests ciblés

`cd packages/map_core && dart test --reporter json test/project_manifest_storylines_test.dart | tail -n 1`

```text
{"success":true,"type":"done","time":592}
```

`cd packages/map_core && dart test --reporter json test/storyline_asset_json_test.dart | tail -n 1`

```text
{"success":true,"type":"done","time":601}
```

`cd packages/map_core && dart test --reporter json test/storyline_asset_test.dart | tail -n 1`

```text
{"success":true,"type":"done","time":616}
```

`cd packages/map_core && dart test --reporter json test/scenario_assets_test.dart | tail -n 1`

```text
{"success":true,"type":"done","time":590}
```

### Sortie exacte de dart analyze

```text
Analyzing project_manifest.dart, project_manifest_storylines_test.dart...
No issues found!
```

### Sortie exacte du test complet map_core

`cd packages/map_core && dart test --reporter json | tail -n 1`

```text
{"success":true,"type":"done","time":4729}
```

### Git status final exact

```text
 M packages/map_core/lib/src/models/project_manifest.dart
 M packages/map_core/lib/src/models/project_manifest.freezed.dart
 M packages/map_core/lib/src/models/project_manifest.g.dart
 M reports/narrativeStudio/storylines/road_map_storylines.md
?? packages/map_core/test/project_manifest_storylines_test.dart
?? reports/narrativeStudio/storylines/ns_storylines_v1_05_project_manifest_storylines_integration_v0.md
```

### Git diff --stat final

```text
 .../map_core/lib/src/models/project_manifest.dart  | 43 ++++++++++++++++
 .../lib/src/models/project_manifest.freezed.dart   | 59 +++++++++++++++++++++-
 .../lib/src/models/project_manifest.g.dart         |  4 ++
 .../storylines/road_map_storylines.md              | 37 ++++++++++++--
 4 files changed, 137 insertions(+), 6 deletions(-)
```

### Git diff --name-only final

```text
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/models/project_manifest.freezed.dart
packages/map_core/lib/src/models/project_manifest.g.dart
reports/narrativeStudio/storylines/road_map_storylines.md
```

### Git diff --check final

```text
Sortie : <vide>
```

### Auto-review critique

- Scope : conforme au lot, limité à `ProjectManifest`, tests map_core, generated manifest, roadmap et rapport.
- Risque principal : `git diff --stat` et `git diff --name-only` ne listent pas les fichiers untracked par nature ; le `git status final` les liste explicitement.
- Generated files : nécessaires car `ProjectManifest` est un modèle Freezed/json_serializable ; build_runner limité à `packages/map_core`.
- Legacy : aucune migration automatique ajoutée ; tests couvrent `globalStory` et `localEventFlow`.
- Limite volontaire : `ProjectManifest.storylines` existe mais aucun flow d'import, de création ou d'UI ne le consomme encore. C'est le périmètre prévu pour V1-06 et après.

## 13. Self-review

Le lot ajoute l'étagère demandée : `ProjectManifest` sait porter, sauvegarder et recharger des `StorylineAsset`. Les vieux projets restent lisibles, les scénarios existants restent intacts, et aucune magie de migration n'a été introduite. Les tests ciblés, l'analyse ciblée et le test complet `map_core` passent.
