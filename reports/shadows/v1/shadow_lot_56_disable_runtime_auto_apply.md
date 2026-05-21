# Shadow-56 — Disable Runtime Auto Apply / Runtime Uses Authored Manifest Only

## 1. Résumé exécutif

Shadow-56 coupe l'application automatique de la policy Shadow dans le runtime.

Avant :

```text
manifest décodé
-> applyElementAutoShadowPolicyToProject(manifest)
-> manifest modifié en mémoire
-> runtime bundle
```

Après :

```text
manifest décodé
-> validation
-> manifest authoré tel quel
-> runtime bundle
```

Aucun tuning visuel, aucun profil, aucune famille, aucun renderer, aucun fichier Selbrume.

## 2. Rappel du diagnostic Shadow-55

Shadow-55 a conclu :

```text
Architecture récupérable.
Politique visuelle à simplifier fortement.
```

Le risque principal identifié était le runtime auto-apply :

```text
packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart
appelait applyElementAutoShadowPolicyToProject(manifest).project
```

Ce comportement transformait une décision artistique en mutation runtime silencieuse.

## 3. État initial du worktree

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
Aucune sortie.
```

## 4. Fichiers modifiés

Production :

```text
packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart
```

Tests :

```text
packages/map_runtime/test/application/load_runtime_map_bundle_shadow_policy_test.dart
```

Rapport :

```text
reports/shadows/shadow_lot_56_disable_runtime_auto_apply.md
```

Fichiers explicitement non modifiés :

```text
packages/map_core/lib/src/models/**
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart
packages/map_core/lib/src/operations/static_shadow_projection_geometry.dart
packages/map_core/lib/src/operations/static_shadow_family_projection.dart
packages/map_core/lib/src/operations/static_shadow_contact_ledge_geometry.dart
packages/map_editor/lib/src/**
packages/map_runtime/lib/src/shadow/**
/Users/karim/Desktop/selbrume/project.json
/Users/karim/Desktop/selbrume/maps/Selbrume.json
```

## 5. Changement exact réalisé

Dans `loadProjectManifestFromFile`, suppression de :

```dart
final normalized = applyElementAutoShadowPolicyToProject(manifest).project;
ProjectValidator.validate(normalized);
return normalized;
```

Remplacement par :

```dart
ProjectValidator.validate(manifest);
return manifest;
```

Le runtime ne déclenche donc plus le backfill Shadow.

## 6. Preuve que le runtime ne backfill plus les shadows

Test ajouté/modifié :

```text
loadProjectManifestFromFile authored shadow manifest keeps missing shadow configs absent at runtime load
```

RED avant changement production :

```text
Expected: null
  Actual: <Instance of 'ProjectElementShadowConfig'>

00:00 +0 -2: Some tests failed.
```

GREEN après changement :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/application/load_runtime_map_bundle_shadow_policy_test.dart
00:00 +0: loadProjectManifestFromFile authored shadow manifest keeps missing shadow configs absent at runtime load
00:00 +1: loadProjectManifestFromFile authored shadow manifest preserves recognized old auto shadows as authored data
00:00 +2: loadProjectManifestFromFile authored shadow manifest preserves manual and disabled shadows
00:00 +3: All tests passed!
```

## 7. Preuve que les shadows authorées restent conservées

Test ajouté/modifié :

```text
loadProjectManifestFromFile authored shadow manifest preserves recognized old auto shadows as authored data
```

RED avant changement production :

```text
Expected: <Instance of 'ProjectElementShadowConfig'>
  Actual: <null>
```

Ce RED prouvait que le runtime supprimait encore une config reconnue comme ancienne auto-shadow.

GREEN :

```text
00:00 +3: All tests passed!
```

Le test `preserves manual and disabled shadows` reste vert.

## 8. Preuve que la policy auto-shadow reste hors runtime

Commande :

```bash
rg -n "applyElementAutoShadowPolicyToProject" packages/map_runtime packages/map_editor packages/map_core
```

Résultat :

```text
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:142:ElementAutoShadowBackfillResult applyElementAutoShadowPolicyToProject(
packages/map_editor/test/application/shadow/element_auto_shadow_backfill_test.dart:451:      final coreResult = applyElementAutoShadowPolicyToProject(project);
packages/map_editor/lib/src/application/shadow/element_auto_shadow_backfill.dart:8:        applyElementAutoShadowPolicyToProject;
packages/map_editor/lib/src/application/shadow/element_auto_shadow_backfill.dart:13:  return applyElementAutoShadowPolicyToProject(project);
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:142:  group('applyElementAutoShadowPolicyToProject', () {
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:144:      final result = applyElementAutoShadowPolicyToProject(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:169:      final result = applyElementAutoShadowPolicyToProject(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:194:      final result = applyElementAutoShadowPolicyToProject(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:221:      final result = applyElementAutoShadowPolicyToProject(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:256:      final result = applyElementAutoShadowPolicyToProject(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:293:      final result = applyElementAutoShadowPolicyToProject(
```

Conclusion :

```text
map_runtime : aucun appel.
map_core : policy conservée.
map_editor : backfill explicite conservé.
```

## 9. Tests ajoutés/modifiés

Fichier :

```text
packages/map_runtime/test/application/load_runtime_map_bundle_shadow_policy_test.dart
```

Tests :

```text
keeps missing shadow configs absent at runtime load
preserves recognized old auto shadows as authored data
preserves manual and disabled shadows
```

## 10. Commandes lancées

Audit initial :

```bash
git status --short --untracked-files=all
find .. -name AGENTS.md -print
rg -n "applyElementAutoShadowPolicyToProject|applyElementAutoShadowSuggestionsToProject|buildElementAutoShadowSuggestion" packages
rg -n "applyElementAutoShadowPolicyToProject" packages/map_runtime packages/map_editor packages/map_core
```

RED :

```bash
cd packages/map_runtime && flutter test test/application/load_runtime_map_bundle_shadow_policy_test.dart
```

Format :

```bash
cd packages/map_runtime && dart format lib/src/application/load_runtime_map_bundle.dart test/application/load_runtime_map_bundle_shadow_policy_test.dart
```

Vérifications :

```bash
cd packages/map_runtime && flutter test test/application/load_runtime_map_bundle_shadow_policy_test.dart
cd packages/map_runtime && flutter test test/shadow
cd packages/map_core && dart test test/shadow
cd packages/map_editor && flutter test test/application/shadow
cd packages/map_runtime && flutter analyze lib/src/application/load_runtime_map_bundle.dart
git diff --stat
git diff --name-status
git diff --check
git status --short --untracked-files=all
```

## 11. Résultats des tests

Test ciblé runtime load :

```text
00:00 +3: All tests passed!
```

Runtime shadow :

```text
00:02 +233: All tests passed!
```

Core shadow :

```text
00:00 +283: All tests passed!
```

Editor application shadow :

```text
00:00 +96: All tests passed!
```

Analyze ciblé :

```text
Analyzing load_runtime_map_bundle.dart...
No issues found! (ran in 0.4s)
```

## 12. Résultat de rg applyElementAutoShadowPolicyToProject

Avant :

```text
packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart:42:    final normalized = applyElementAutoShadowPolicyToProject(manifest).project;
```

Après :

```text
map_runtime : aucun appel.
map_core : définition et tests conservés.
map_editor : backfill explicite conservé.
```

## 13. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie avant création du rapport :

```text
 .../src/application/load_runtime_map_bundle.dart   |  5 ++-
 ...load_runtime_map_bundle_shadow_policy_test.dart | 39 ++++++++++------------
 2 files changed, 20 insertions(+), 24 deletions(-)
```

## 14. git diff --name-status

Commande :

```bash
git diff --name-status
```

Sortie avant création du rapport :

```text
M	packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart
M	packages/map_runtime/test/application/load_runtime_map_bundle_shadow_policy_test.dart
```

## 15. git diff --check

Commande :

```bash
git diff --check
```

Sortie :

```text
Aucune sortie.
```

## 16. git status final

Sortie finale :

```text
 M packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart
 M packages/map_runtime/test/application/load_runtime_map_bundle_shadow_policy_test.dart
?? reports/shadows/shadow_lot_56_disable_runtime_auto_apply.md
```

## 17. Diffs utiles

Production :

```diff
diff --git a/packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart b/packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart
@@
     final manifest = _normalizeProjectElementCollisionProfiles(
       ProjectManifest.fromJson(migrated),
     );
-    final normalized = applyElementAutoShadowPolicyToProject(manifest).project;
-    ProjectValidator.validate(normalized);
-    return normalized;
+    ProjectValidator.validate(manifest);
+    return manifest;
```

Test :

```diff
-  group('loadProjectManifestFromFile shadow policy', () {
-    test('clears recognized obsolete auto shadows in memory', () async {
+  group('loadProjectManifestFromFile authored shadow manifest', () {
+    test('keeps missing shadow configs absent at runtime load', () async {
...
-    test('applies eligible missing auto shadows in memory', () async {
+    test('preserves recognized old auto shadows as authored data', () async {
```

## 18. Risques / réserves

- Si certaines maps dépendaient uniquement du runtime auto-apply pour voir des ombres statiques, elles verront moins d'ombres.
- C'est voulu : le runtime ne doit plus inventer une décision artistique.
- L'éditeur conserve le workflow explicite de suggestion/backfill.
- Selbrume n'a pas été modifié ; son rendu ne change que pour les ombres que le runtime ajoutait ou supprimait silencieusement.

## 19. Auto-critique

- Ai-je supprimé l'auto-apply runtime ? oui.
- Ai-je évité un flag runtime ou option debug ? oui.
- Ai-je préservé la policy côté core/editor ? oui.
- Ai-je évité renderer/profils/familles/projections ? oui.
- Ai-je évité Selbrume ? oui.
- Ai-je testé RED puis GREEN ? oui.
- Ai-je fait un commit ? non.

## 20. Regard critique sur le prompt

Le prompt est bien cadré. La contrainte principale est que le changement peut faire disparaître des ombres qui n'étaient jamais vraiment authorées. C'est un effet attendu et sain pour restaurer une frontière claire :

```text
Runtime consomme.
Editor propose.
Utilisateur valide.
```

## 21. Prochain lot recommandé

```text
Shadow-57 — Selbrume Shadow Inventory & Runtime Instruction Debug Report
```

Objectif :

```text
Lister, pour Selbrume, les instructions runtime réellement générées par élément/instance.
Identifier les ombres encore moches qui viennent désormais uniquement du manifest authoré.
Ne pas modifier le rendu.
```

## 22. Contenu complet des fichiers modifiés

### packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart

```dart
import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import 'runtime_manifest_tilesets.dart';
import 'runtime_map_bundle.dart';

Map<String, String> resolveTilesetAbsolutePaths({
  required ProjectManifest manifest,
  required String projectRoot,
  required Set<String> tilesetIds,
}) {
  final byId = {for (final t in manifest.tilesets) t.id: t};
  final out = <String, String>{};
  for (final id in tilesetIds) {
    final entry = byId[id];
    if (entry == null) {
      throw AssetNotFoundException('Tileset not in manifest: $id');
    }
    final rel = entry.relativePath.trim();
    if (rel.isEmpty) {
      throw AssetNotFoundException('Tileset $id has empty relativePath');
    }
    out[id] = p.normalize(p.join(projectRoot, rel));
  }
  return out;
}

Future<ProjectManifest> loadProjectManifestFromFile(String manifestPath) async {
  final file = File(manifestPath);
  if (!await file.exists()) {
    throw const ProjectLoadException('Project file not found');
  }
  try {
    final raw = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    final migrated = migrateProjectManifestJson(raw);
    final manifest = _normalizeProjectElementCollisionProfiles(
      ProjectManifest.fromJson(migrated),
    );
    ProjectValidator.validate(manifest);
    return manifest;
  } catch (e) {
    throw ProjectLoadException('Failed to load project: $e');
  }
}

ProjectManifest _normalizeProjectElementCollisionProfiles(
  ProjectManifest manifest,
) {
  final tileSize = manifest.settings.tileWidth;
  return manifest.copyWith(
    elements: [
      for (final element in manifest.elements)
        element.collisionProfile == null
            ? element
            : element.copyWith(
                collisionProfile: normalizeElementCollisionProfile(
                  element.collisionProfile!,
                  tileSize: tileSize,
                ),
              ),
    ],
  );
}

Future<MapData> loadMapDataFromFile(
  String absoluteMapPath, {
  required ProjectManifest projectDialogueContext,
}) async {
  final file = File(absoluteMapPath);
  if (!await file.exists()) {
    throw MapLoadException('Map file not found: $absoluteMapPath');
  }
  try {
    final raw = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    final migrated = migrateMapDataJson(raw);
    final map = MapData.fromJson(migrated);
    MapValidator.validate(
      map,
      projectDialogueContext: projectDialogueContext,
    );
    return map;
  } catch (e) {
    throw MapLoadException('Failed to load map: $e');
  }
}

ProjectMapEntry? projectMapEntryForId(ProjectManifest manifest, String mapId) {
  for (final entry in manifest.maps) {
    if (entry.id == mapId) {
      return entry;
    }
  }
  return null;
}

Future<RuntimeMapBundle> loadRuntimeMapBundle({
  required String projectFilePath,
  required String mapId,
}) async {
  final manifest = await loadProjectManifestFromFile(projectFilePath);
  final entry = projectMapEntryForId(manifest, mapId);
  if (entry == null) {
    throw MapLoadException('Map id not in project manifest: $mapId');
  }
  final projectRoot = p.normalize(p.dirname(projectFilePath));
  final rel = entry.relativePath.trim();
  if (rel.isEmpty) {
    throw const MapLoadException('Map entry has empty relativePath');
  }
  final mapPath = p.normalize(p.join(projectRoot, rel));
  final map = await loadMapDataFromFile(
    mapPath,
    projectDialogueContext: manifest,
  );
  final tilesetIds = collectAllRuntimeTilesetIds(map, manifest);
  final paths = resolveTilesetAbsolutePaths(
    manifest: manifest,
    projectRoot: projectRoot,
    tilesetIds: tilesetIds,
  );
  return RuntimeMapBundle(
    manifest: manifest,
    map: map,
    projectRootDirectory: projectRoot,
    tilesetAbsolutePathsById: paths,
  );
}
```

### packages/map_runtime/test/application/load_runtime_map_bundle_shadow_policy_test.dart

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/load_runtime_map_bundle.dart';
import 'package:path/path.dart' as p;

void main() {
  group('loadProjectManifestFromFile authored shadow manifest', () {
    test('keeps missing shadow configs absent at runtime load', () async {
      final root =
          await Directory.systemTemp.createTemp('runtime_shadow_manifest_');
      addTearDown(() => root.delete(recursive: true));
      final manifestPath = p.join(root.path, 'project.json');
      await File(manifestPath).writeAsString(
        jsonEncode(
          _project(
            elements: [
              _element(id: 'lamp', width: 1, height: 4),
            ],
            shadowCatalog: const ProjectShadowCatalog.empty(),
          ).toJson(),
        ),
      );

      final manifest = await loadProjectManifestFromFile(manifestPath);

      expect(manifest.elements.single.shadow, isNull);
    });

    test('preserves recognized old auto shadows as authored data', () async {
      final oldAutoShadow = _oldAutoSmallSquareShadow();
      final root =
          await Directory.systemTemp.createTemp('runtime_shadow_manifest_');
      addTearDown(() => root.delete(recursive: true));
      final manifestPath = p.join(root.path, 'project.json');
      await File(manifestPath).writeAsString(
        jsonEncode(
          _project(
            elements: [
              _element(
                id: 'small',
                width: 2,
                height: 2,
                shadow: oldAutoShadow,
              ),
            ],
            shadowCatalog: _defaultCatalog(),
          ).toJson(),
        ),
      );

      final manifest = await loadProjectManifestFromFile(manifestPath);

      expect(manifest.elements.single.shadow, oldAutoShadow);
    });

    test('preserves manual and disabled shadows', () async {
      final manual = ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: 'custom-ground-shadow',
      );
      final disabled = ProjectElementShadowConfig(castsShadow: false);
      final root =
          await Directory.systemTemp.createTemp('runtime_shadow_manifest_');
      addTearDown(() => root.delete(recursive: true));
      final manifestPath = p.join(root.path, 'project.json');
      await File(manifestPath).writeAsString(
        jsonEncode(
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
          ).toJson(),
        ),
      );

      final manifest = await loadProjectManifestFromFile(manifestPath);

      expect(manifest.elements[0].shadow, manual);
      expect(manifest.elements[1].shadow, disabled);
    });
  });
}

ProjectManifest _project({
  required List<ProjectElementEntry> elements,
  required ProjectShadowCatalog shadowCatalog,
}) {
  return ProjectManifest(
    name: 'Runtime shadow manifest test',
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
```
