# Collision Lot 6 — Editor Persistence Uses Normalizer V0

## 1. Résumé exécutif

Collision-6 branche le normalizer pur `map_core` dans la persistance éditeur.

Verdict court :

- `FileProjectRepository.loadProject()` normalise maintenant les `collisionProfile` des `ProjectElementEntry` après `ProjectManifest.fromJson(...)` et avant `ProjectValidator.validate(...)`.
- `saveProject()` n'est pas modifié : il persiste uniquement le manifest que l'appelant lui passe.
- Les profils legacy `cells` pleines + `manualAddedCells` silhouette sont normalisés en mémoire.
- Les profils avec `pixelMask` / `collisionMask` projettent `cells` avec le `tileWidth` du projet.
- `visualMask` et `occlusionMask` sont conservés et ne deviennent pas collision.
- `loadProject()` ne réécrit pas le fichier sur disque.

Inventaire complet :

| Catégorie | Fichiers |
|---|---|
| Créés | `reports/collision/collision_lot_6_editor_persistence_uses_normalizer.md` |
| Modifiés | `packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart` |
| Modifiés | `packages/map_editor/test/project_element_collision_file_repository_roundtrip_test.dart` |
| Supprimés | Aucun |
| Générés | Aucun |
| Untracked touchés | `reports/collision/collision_lot_6_editor_persistence_uses_normalizer.md` |
| Hors lot préexistant | Aucun au status initial |

## 2. Git status initial

Commande :

```bash
git status --short --untracked-files=all
```

Sortie exacte :

```text
```

Conclusion : worktree propre au début de Collision-6.

## 3. Rapports précédents relus

Rapports relus :

```text
reports/collision/collision_lot_3_red_tests_triage.md
reports/collision/collision_lot_4_element_collision_profile_normalizer.md
reports/collision/collision_lot_5_collision_mask_cells_projection_contract.md
```

Contrats repris :

- Collision-3 : le test repository futur était skip tant que `FileProjectRepository` ne branchait pas le normalizer.
- Collision-4 : `normalizeElementCollisionProfile(profile, tileSize: ...)` est l'API pure à utiliser.
- Collision-5 : `collisionMask -> cells` passe par `ElementCollisionMaskCodec.cellsFromPixelMask(...)`, avec ordre stable et projection par `ceil`.

## 4. Audit ciblé FileProjectRepository

Fichiers inspectés :

```text
packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart
packages/map_editor/test/project_element_collision_file_repository_roundtrip_test.dart
packages/map_editor/test/project_element_collision_persistence_test.dart
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/validation/validators.dart
```

Recherche lancée :

```bash
rg -n "class FileProjectRepository|loadProject|saveProject|ProjectManifest.fromJson|ProjectValidator.validate|migrateProjectManifestJson|collisionProfile|normalizeElementCollisionProfile" packages/map_editor/lib/src/infrastructure/repositories packages/map_editor/test
```

Ordre de chargement avant Collision-6 :

```text
read file
jsonDecode
migrateProjectManifestJson
ProjectManifest.fromJson
ProjectValidator.validate(manifest)
return manifest
```

Insertion retenue :

```text
ProjectManifest.fromJson(json)
-> _normalizeProjectElementCollisionProfiles(...)
-> ProjectValidator.validate(normalizedManifest)
```

Pourquoi `saveProject()` n'est pas modifié :

- Le lot demande une normalisation au chargement.
- `loadProject()` retourne un manifest normalisé en mémoire.
- `saveProject()` persiste explicitement le manifest fourni, sans inventer une nouvelle migration implicite.

## 5. Design retenu

Design retenu :

- helper privé local à `file_repositories.dart`.
- aucune création de service applicatif.
- aucune modification `map_core`.
- aucun changement de modèle, JSON schema ou generated.
- aucune écriture disque pendant `loadProject()`.

API locale ajoutée :

```dart
ProjectManifest _normalizeProjectElementCollisionProfiles(
  ProjectManifest manifest,
)
```

Elle parcourt `manifest.elements` et remplace seulement les `collisionProfile` présents par :

```dart
normalizeElementCollisionProfile(
  profile,
  tileSize: _collisionProfileTileSize(settings, profile),
)
```

## 6. Ordre de chargement final

Ordre final dans `FileProjectRepository.loadProject()` :

```text
1. lire le fichier JSON ;
2. décoder JSON brut ;
3. appliquer migrateProjectManifestJson(...) ;
4. ProjectManifest.fromJson(...) ;
5. _normalizeProjectElementCollisionProfiles(...) ;
6. ProjectValidator.validate(...) sur le projet normalisé ;
7. retourner le projet normalisé.
```

La validation voit donc le projet normalisé.

## 7. Règle tileSize utilisée

Source utilisée :

```text
project.settings.tileWidth
```

Règle :

- si le profil n'a pas de `collisionMask`, `tileWidth` est passé au normalizer ; pour le legacy coarse, il sert surtout à la validation `tileSize > 0`.
- si le profil a un `collisionMask` et que `tileWidth != tileHeight`, le helper lève une `ValidationException`.

Raison :

- Collision-4 expose seulement `tileSize`, pas une paire rectangulaire.
- Collision-5 a verrouillé une projection carrée `tileWidth == tileHeight` via le normalizer.
- Le modèle `ProjectSettings` possède bien `tileWidth` et `tileHeight`, mais aucun chemin audité ne prouve un contrat collision pixel-mask rectangulaire officiel.

## 8. Fichiers modifiés

```text
packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart
packages/map_editor/test/project_element_collision_file_repository_roundtrip_test.dart
```

Fichier créé :

```text
reports/collision/collision_lot_6_editor_persistence_uses_normalizer.md
```

## 9. Fichiers explicitement non modifiés

```text
packages/map_core/lib/**
packages/map_gameplay/lib/**
packages/map_gameplay/test/placed_elements_collision_test.dart
packages/map_runtime/**
packages/map_battle/**
examples/**
packages/map_editor/lib/src/ui/**
packages/map_editor/lib/src/application/collision_generation/**
packages/map_editor/test/project_element_collision_persistence_test.dart
```

## 10. Tests modifiés / ajoutés

Fichier :

```text
packages/map_editor/test/project_element_collision_file_repository_roundtrip_test.dart
```

Tests actifs après Collision-6 :

- `load normalizes legacy cells after Collision-6 normalizer in memory`
- `normalizer contract migrates broken manual profile and save persists corrected cells`
- `load projects collisionMask into cells using project settings tile size`
- `load leaves elements without collisionProfile unchanged`

Changements principaux :

- le test de comportement actuel Collision-3 est remplacé par le comportement cible Collision-6.
- le test futur skip est activé.
- les assertions du test futur sont alignées avec le normalizer réel : `cells` corrigées, `shapeCells` conservé vide, `manualAddedCells` conservées comme intention auteur.
- un test vérifie que `loadProject()` ne réécrit pas le fichier.
- un test vérifie que `tileWidth` des settings est réellement utilisé.
- un test vérifie `visualMask` et `occlusionMask` conservés.

## 11. Commandes lancées

Audit :

```bash
git status --short --untracked-files=all
rg --files -g 'AGENTS.md' -g '!build' -g '!.dart_tool'
sed -n '1,220p' AGENTS.md
ls -1 reports/collision
sed -n '1,220p' reports/collision/collision_lot_3_red_tests_triage.md
sed -n '1,240p' reports/collision/collision_lot_4_element_collision_profile_normalizer.md
sed -n '1,220p' reports/collision/collision_lot_5_collision_mask_cells_projection_contract.md
rg -n "class FileProjectRepository|loadProject|saveProject|ProjectManifest.fromJson|ProjectValidator.validate|migrateProjectManifestJson|collisionProfile|normalizeElementCollisionProfile" packages/map_editor/lib/src/infrastructure/repositories packages/map_editor/test
rg -n "class ProjectSettings|ProjectSettings\(|tileWidth|tileHeight" packages/map_core/lib packages/map_editor/test
```

Tests avant modification :

```bash
cd packages/map_editor
flutter test --no-pub --reporter expanded test/project_element_collision_file_repository_roundtrip_test.dart
```

RED après modification des tests, avant code production :

```bash
cd packages/map_editor
flutter test --no-pub --reporter expanded test/project_element_collision_file_repository_roundtrip_test.dart
```

Format :

```bash
dart format packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart packages/map_editor/test/project_element_collision_file_repository_roundtrip_test.dart
```

Tests après modification :

```bash
cd packages/map_editor
flutter test --no-pub --reporter expanded test/project_element_collision_file_repository_roundtrip_test.dart
flutter test --no-pub --reporter compact test/project_element_collision_persistence_test.dart test/project_element_collision_file_repository_roundtrip_test.dart
```

Analyse :

```bash
cd packages/map_editor
flutter analyze lib/src/infrastructure/repositories/file_repositories.dart test/project_element_collision_file_repository_roundtrip_test.dart
```

Périmètre :

```bash
git diff --name-only
git diff --stat
git status --short --untracked-files=all
```

## 12. Résultats des tests avant modification

Commande :

```bash
cd packages/map_editor
flutter test --no-pub --reporter expanded test/project_element_collision_file_repository_roundtrip_test.dart
```

Sortie utile :

```text
00:00 +0: FileProjectRepository collision roundtrip load currently preserves legacy cells before Collision-4 normalizer
FileProjectRepository: Loading project from .../collision_repo_roundtrip_current_epv2ML/project.json
00:00 +1: FileProjectRepository collision roundtrip future normalizer contract migrates broken manual profile and save persists corrected cells
  Skip: Pending Collision-4/Collision-6: legacy collision profile normalizer is not implemented or wired into FileProjectRepository yet.
00:00 +1 ~1: All tests passed!
```

RED après modification des tests, avant branchement production :

```text
00:00 +0 -1: FileProjectRepository collision roundtrip load normalizes legacy cells after Collision-6 normalizer in memory [E]
Expected: [GridPos(x: 0, y: 3), ...]
Actual: [GridPos(x: 0, y: 0), ...]
Which: at location [0] is GridPos(x: 0, y: 0) instead of GridPos(x: 0, y: 3)

00:00 +0 -2: FileProjectRepository collision roundtrip normalizer contract migrates broken manual profile and save persists corrected cells [E]
Expected: [GridPos(x: 0, y: 3), ...]
Actual: [GridPos(x: 0, y: 0), ...]

00:00 +0 -3: FileProjectRepository collision roundtrip load projects collisionMask into cells using project settings tile size [E]
Expected: [GridPos(x: 1, y: 0)]
Actual: [GridPos(x: 0, y: 0)]

00:00 +1 -3: Some tests failed.
```

Conclusion : le RED prouve que les tests ciblent bien l'absence de normalisation dans `loadProject()`.

## 13. Résultats des tests après modification

Commande :

```bash
cd packages/map_editor
flutter test --no-pub --reporter expanded test/project_element_collision_file_repository_roundtrip_test.dart
```

Sortie finale :

```text
00:00 +0: FileProjectRepository collision roundtrip load normalizes legacy cells after Collision-6 normalizer in memory
FileProjectRepository: Loading project from .../collision_repo_roundtrip_legacy_load_twUHFq/project.json
00:00 +1: FileProjectRepository collision roundtrip normalizer contract migrates broken manual profile and save persists corrected cells
FileProjectRepository: Loading project from .../collision_repo_roundtrip_legacy_save_ty1aU3/project.json
FileProjectRepository: Validating and saving project to .../collision_repo_roundtrip_legacy_save_ty1aU3/project.json
FileProjectRepository: Loading project from .../collision_repo_roundtrip_legacy_save_ty1aU3/project.json
00:00 +2: FileProjectRepository collision roundtrip load projects collisionMask into cells using project settings tile size
FileProjectRepository: Loading project from .../collision_repo_roundtrip_mask_onB2AB/project.json
00:00 +3: FileProjectRepository collision roundtrip load leaves elements without collisionProfile unchanged
FileProjectRepository: Loading project from .../collision_repo_roundtrip_no_profile_pOyrih/project.json
00:00 +4: All tests passed!
```

Commande groupée :

```bash
cd packages/map_editor
flutter test --no-pub --reporter compact test/project_element_collision_persistence_test.dart test/project_element_collision_file_repository_roundtrip_test.dart
```

Sortie finale :

```text
00:01 +7: All tests passed!
```

## 14. Analyse statique / format

Commande :

```bash
dart format packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart packages/map_editor/test/project_element_collision_file_repository_roundtrip_test.dart
```

Sortie finale :

```text
Formatted 2 files (0 changed) in 0.01 seconds.
```

Commande :

```bash
cd packages/map_editor
flutter analyze lib/src/infrastructure/repositories/file_repositories.dart test/project_element_collision_file_repository_roundtrip_test.dart
```

Première sortie utile :

```text
warning • The declaration '_legacyFullCells' isn't referenced • test/project_element_collision_file_repository_roundtrip_test.dart:178:15 • unused_element
1 issue found. (ran in 2.1s)
```

Correction :

```text
Suppression du helper de test inutilisé `_legacyFullCells`.
```

Sortie finale :

```text
Analyzing 2 items...
No issues found! (ran in 2.4s)
```

Note : `flutter analyze` a résolu les dépendances et affiché des versions plus récentes disponibles. Le `git status` est resté limité aux fichiers du lot.

## 15. Vérification du périmètre

Commande :

```bash
git diff --name-only
```

Sortie avant création du rapport :

```text
packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart
packages/map_editor/test/project_element_collision_file_repository_roundtrip_test.dart
```

Commande :

```bash
git diff --stat
```

Sortie avant création du rapport :

```text
 .../repositories/file_repositories.dart            |  46 ++++-
 ...t_collision_file_repository_roundtrip_test.dart | 207 +++++++++++++++++----
 2 files changed, 212 insertions(+), 41 deletions(-)
```

Confirmation :

- aucun `packages/map_core/lib/**` modifié ;
- aucun `packages/map_gameplay/**` modifié ;
- aucun `packages/map_runtime/**` modifié ;
- aucun fichier generated modifié ;
- `build_runner` non lancé ;
- `saveProject()` non modifié.

## 16. Git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie finale exacte après création de ce rapport :

```text
 M packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart
 M packages/map_editor/test/project_element_collision_file_repository_roundtrip_test.dart
?? reports/collision/collision_lot_6_editor_persistence_uses_normalizer.md
```

## 17. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie :

```text
 .../repositories/file_repositories.dart            |  46 ++++-
 ...t_collision_file_repository_roundtrip_test.dart | 207 +++++++++++++++++----
 2 files changed, 212 insertions(+), 41 deletions(-)
```

Note : le rapport est untracked, donc absent de `git diff --stat`.

## 18. Risques / réserves

- Les projets avec `collisionMask` et `tileWidth != tileHeight` lèvent désormais une `ValidationException` pendant la normalisation de chargement. Ce choix évite d'inventer une projection rectangulaire dans Collision-6.
- Les profils legacy sans `collisionMask` utilisent `tileWidth`, mais le normalizer ne s'en sert que pour la validation `tileSize > 0` dans ce chemin.
- `loadProject()` normalise en mémoire seulement ; le fichier disque n'est corrigé qu'après un `saveProject()` explicite.
- Les tests gameplay skip de Collision-3 ne sont pas modifiés ; ils restent pour Collision-7.

Non vérifié.

**Sujet :**
Suite complète `packages/map_editor`.

**Raison :**
Le lot est limité à `FileProjectRepository` et au test repository collision ; la commande groupée éditeur collision est passée.

**Impact :**
Faible risque résiduel hors collision repository.

**Comment vérifier dans Collision-7 :**
Relancer les tests gameplay ciblés après branchement ou durcissement côté `map_gameplay`.

## 19. Préparation de Collision-7

Collision-7 peut maintenant s'appuyer sur :

- les projets chargés par `FileProjectRepository.loadProject()` ont des profils collision normalisés en mémoire ;
- `collisionMask` reste prioritaire ;
- `cells` est une projection ou un fallback legacy cohérent ;
- `map_gameplay` peut rester simple et éviter une migration lourde au runtime.

## 20. Auto-review finale

- Ai-je modifié uniquement `FileProjectRepository` et son test repository ? Oui.
- Ai-je évité `map_core` production ? Oui.
- Ai-je évité `map_gameplay` production ? Oui.
- Ai-je évité `map_runtime` production ? Oui.
- Ai-je évité `ProjectManifest` ? Oui.
- Ai-je évité `build_runner/generated` ? Oui.
- Ai-je branché `normalizeElementCollisionProfile(...)` après `fromJson` ? Oui.
- Ai-je validé le projet normalisé, pas le projet brut ? Oui.
- Ai-je évité toute écriture disque implicite pendant `loadProject()` ? Oui, test dédié.
- Ai-je retiré ou remplacé le test de comportement actuel devenu obsolète ? Oui.
- Ai-je rendu vert le contrat repository futur de Collision-3 ? Oui.
- Ai-je laissé les skips gameplay pour Collision-7 ? Oui.
- Ai-je documenté la règle `tileSize` ? Oui.
- Ai-je relancé les tests ciblés ? Oui.

Auto-critique : le helper local est volontairement simple et privé. Le seul arbitrage notable est le guard sur les tiles non carrées pour `collisionMask`; il est strict, mais préférable à une projection silencieusement fausse dans un lot où le normalizer `map_core` n'accepte qu'un `tileSize`.

## 21. Contenu complet des fichiers créés/modifiés

Le rapport lui-même n'est pas recopié ici pour éviter une inclusion récursive.

### Diff complet — `packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart`

```diff
diff --git a/packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart b/packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart
index d6a8581b..3559495c 100644
--- a/packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart
+++ b/packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart
@@ -37,7 +37,9 @@ class FileProjectRepository implements ProjectRepository {
       final json = migrateProjectManifestJson(
         jsonDecode(content) as Map<String, dynamic>,
       );
-      final manifest = ProjectManifest.fromJson(json);
+      final manifest = _normalizeProjectElementCollisionProfiles(
+        ProjectManifest.fromJson(json),
+      );
       ProjectValidator.validate(manifest);
       return manifest;
     } catch (e) {
@@ -46,6 +48,48 @@ class FileProjectRepository implements ProjectRepository {
   }
 }
 
+ProjectManifest _normalizeProjectElementCollisionProfiles(
+  ProjectManifest manifest,
+) {
+  return manifest.copyWith(
+    elements: [
+      for (final element in manifest.elements)
+        _normalizeProjectElementCollisionProfile(element, manifest.settings),
+    ],
+  );
+}
+
+ProjectElementEntry _normalizeProjectElementCollisionProfile(
+  ProjectElementEntry element,
+  ProjectSettings settings,
+) {
+  final profile = element.collisionProfile;
+  if (profile == null) {
+    return element;
+  }
+
+  return element.copyWith(
+    collisionProfile: normalizeElementCollisionProfile(
+      profile,
+      tileSize: _collisionProfileTileSize(settings, profile),
+    ),
+  );
+}
+
+int _collisionProfileTileSize(
+  ProjectSettings settings,
+  ElementCollisionProfile profile,
+) {
+  if (profile.collisionMask != null &&
+      settings.tileWidth != settings.tileHeight) {
+    throw ValidationException(
+      'Cannot normalize collision masks for non-square project tiles: '
+      '${settings.tileWidth}x${settings.tileHeight}',
+    );
+  }
+  return settings.tileWidth;
+}
+
 class FileMapRepository implements MapRepository {
   @override
   Future<void> saveMap(
```

### Diff complet — `packages/map_editor/test/project_element_collision_file_repository_roundtrip_test.dart`

```diff
diff --git a/packages/map_editor/test/project_element_collision_file_repository_roundtrip_test.dart b/packages/map_editor/test/project_element_collision_file_repository_roundtrip_test.dart
index 3148a1cd..8e5a8572 100644
--- a/packages/map_editor/test/project_element_collision_file_repository_roundtrip_test.dart
+++ b/packages/map_editor/test/project_element_collision_file_repository_roundtrip_test.dart
@@ -8,10 +8,10 @@ import 'package:path/path.dart' as p;
 
 void main() {
   group('FileProjectRepository collision roundtrip', () {
-    test('load currently preserves legacy cells before Collision-4 normalizer',
+    test('load normalizes legacy cells after Collision-6 normalizer in memory',
         () async {
       final tempDir = await Directory.systemTemp.createTemp(
-        'collision_repo_roundtrip_current_',
+        'collision_repo_roundtrip_legacy_load_',
       );
       addTearDown(() async {
         if (await tempDir.exists()) {
@@ -24,22 +24,25 @@ void main() {
       await file.writeAsString(
         const JsonEncoder.withIndent('  ').convert(_legacyBrokenProjectJson()),
       );
+      final beforeLoad = await file.readAsString();
 
       final repo = FileProjectRepository();
       final loaded = await repo.loadProject(manifestPath);
       final loadedProfile = loaded.elements.single.collisionProfile!;
+      final afterLoad = await file.readAsString();
 
-      expect(loadedProfile.cells, _legacyFullCells());
+      expect(loadedProfile.cells, _houseShapeCells);
       expect(loadedProfile.shapeCells, isEmpty);
       expect(loadedProfile.manualAddedCells, _houseShapeCells);
       expect(loadedProfile.manualRemovedCells, isEmpty);
+      expect(afterLoad, beforeLoad);
     });
 
     test(
-        'future normalizer contract migrates broken manual profile and save persists corrected cells',
-        () async {
+        'normalizer contract migrates broken manual profile and save persists '
+        'corrected cells', () async {
       final tempDir = await Directory.systemTemp.createTemp(
-        'collision_repo_roundtrip_future_',
+        'collision_repo_roundtrip_legacy_save_',
       );
       addTearDown(() async {
         if (await tempDir.exists()) {
@@ -58,7 +61,9 @@ void main() {
       final loadedProfile = loaded.elements.single.collisionProfile!;
 
       expect(loadedProfile.cells, _houseShapeCells);
-      expect(loadedProfile.shapeCells, _houseShapeCells);
+      expect(loadedProfile.shapeCells, isEmpty);
+      expect(loadedProfile.manualAddedCells, _houseShapeCells);
+      expect(loadedProfile.manualRemovedCells, isEmpty);
 
       await repo.saveProject(loaded, manifestPath);
 
@@ -67,29 +72,118 @@ void main() {
       final savedProfile = (((rawSaved['elements'] as List).single
           as Map<String, dynamic>)['collisionProfile'] as Map<String, dynamic>);
 
-      expect((savedProfile['cells'] as List).length, _houseShapeCells.length);
-      expect(
-          (savedProfile['shapeCells'] as List).length, _houseShapeCells.length);
-      expect(savedProfile['manualAddedCells'], isEmpty);
+      expect(savedProfile['cells'], _houseShapeCellsJson());
+      expect(savedProfile['shapeCells'], isEmpty);
+      expect(savedProfile['manualAddedCells'], _houseShapeCellsJson());
       expect(savedProfile['manualRemovedCells'], isEmpty);
 
       final reloaded = await repo.loadProject(manifestPath);
       expect(
           reloaded.elements.single.collisionProfile!.cells, _houseShapeCells);
-    },
-        skip:
-            'Pending Collision-4/Collision-6: legacy collision profile normalizer is not implemented or wired into FileProjectRepository yet.');
+    });
+
+    test(
+        'load projects collisionMask into cells using project settings tile size',
+        () async {
+      final collisionMask = _maskJson(
+        widthPx: 16,
+        heightPx: 16,
+        solidPoints: const [GridPos(x: 8, y: 0)],
+      );
+      final visualMask = _maskJson(
+        widthPx: 4,
+        heightPx: 4,
+        solidPoints: const [GridPos(x: 0, y: 0)],
+      );
+      final occlusionMask = _maskJson(
+        widthPx: 2,
+        heightPx: 2,
+        solidPoints: const [GridPos(x: 1, y: 1)],
+      );
+      final tempDir = await Directory.systemTemp.createTemp(
+        'collision_repo_roundtrip_mask_',
+      );
+      addTearDown(() async {
+        if (await tempDir.exists()) {
+          await tempDir.delete(recursive: true);
+        }
+      });
+
+      final manifestPath = p.join(tempDir.path, 'project.json');
+      final file = File(manifestPath);
+      await file.writeAsString(
+        const JsonEncoder.withIndent('  ').convert(
+          _projectJson(
+            tileWidth: 8,
+            tileHeight: 8,
+            collisionProfile: <String, dynamic>{
+              'source': 'manual',
+              'pixelMask': collisionMask,
+              'visualMask': visualMask,
+              'occlusionMask': occlusionMask,
+              'cells': <dynamic>[
+                <String, dynamic>{'x': 0, 'y': 0},
+              ],
+              'shapeCells': <dynamic>[],
+              'manualAddedCells': <dynamic>[],
+              'manualRemovedCells': <dynamic>[],
+            },
+          ),
+        ),
+      );
+
+      final repo = FileProjectRepository();
+      final loaded = await repo.loadProject(manifestPath);
+      final loadedProfile = loaded.elements.single.collisionProfile!;
+
+      expect(loadedProfile.cells, const [GridPos(x: 1, y: 0)]);
+      expect(loadedProfile.collisionMask, isNotNull);
+      expect(
+          loadedProfile.collisionMask!.dataBase64, collisionMask['dataBase64']);
+      expect(loadedProfile.visualMask, isNotNull);
+      expect(loadedProfile.visualMask!.dataBase64, visualMask['dataBase64']);
+      expect(loadedProfile.occlusionMask, isNotNull);
+      expect(
+          loadedProfile.occlusionMask!.dataBase64, occlusionMask['dataBase64']);
+    });
+
+    test('load leaves elements without collisionProfile unchanged', () async {
+      final tempDir = await Directory.systemTemp.createTemp(
+        'collision_repo_roundtrip_no_profile_',
+      );
+      addTearDown(() async {
+        if (await tempDir.exists()) {
+          await tempDir.delete(recursive: true);
+        }
+      });
+
+      final manifestPath = p.join(tempDir.path, 'project.json');
+      final file = File(manifestPath);
+      await file.writeAsString(
+        const JsonEncoder.withIndent('  ').convert(
+          _projectJson(collisionProfile: null),
+        ),
+      );
+
+      final repo = FileProjectRepository();
+      final loaded = await repo.loadProject(manifestPath);
+
+      expect(loaded.elements.single.collisionProfile, isNull);
+      expect(loaded.elements.single.id, 'petite_maison_toit_bleu');
+      expect(loaded.settings.tileWidth, 16);
+    });
   });
 }
 
-List<GridPos> _legacyFullCells() {
-  return <GridPos>[
-    for (var y = 0; y < 7; y++)
-      for (var x = 0; x < 6; x++) GridPos(x: x, y: y),
-  ];
+Map<String, dynamic> _legacyBrokenProjectJson() {
+  return _projectJson(collisionProfile: _legacyBrokenCollisionProfileJson());
 }
 
-Map<String, dynamic> _legacyBrokenProjectJson() {
+Map<String, dynamic> _projectJson({
+  required Map<String, dynamic>? collisionProfile,
+  int tileWidth = 16,
+  int tileHeight = 16,
+}) {
   return <String, dynamic>{
     'name': 'Legacy',
     'maps': <dynamic>[],
@@ -104,8 +198,8 @@ Map<String, dynamic> _legacyBrokenProjectJson() {
       <String, dynamic>{'id': 'building', 'name': 'building'},
     ],
     'settings': <String, dynamic>{
-      'tileWidth': 16,
-      'tileHeight': 16,
+      'tileWidth': tileWidth,
+      'tileHeight': tileHeight,
     },
     'elements': <dynamic>[
       <String, dynamic>{
@@ -125,29 +219,62 @@ Map<String, dynamic> _legacyBrokenProjectJson() {
           },
         ],
         'presetKind': 'building',
-        'collisionProfile': <String, dynamic>{
-          'source': 'manual',
-          'padding': const <String, dynamic>{
-            'top': 0,
-            'right': 0,
-            'bottom': 0,
-            'left': 0,
-          },
-          'shapeCells': <dynamic>[],
-          'cells': <dynamic>[
-            for (var y = 0; y < 7; y++)
-              for (var x = 0; x < 6; x++) <String, dynamic>{'x': x, 'y': y},
-          ],
-          'manualAddedCells': _houseShapeCells
-              .map((cell) => <String, dynamic>{'x': cell.x, 'y': cell.y})
-              .toList(growable: false),
-          'manualRemovedCells': <dynamic>[],
-        },
+        if (collisionProfile != null) 'collisionProfile': collisionProfile,
       },
     ],
   };
 }
 
+Map<String, dynamic> _legacyBrokenCollisionProfileJson() {
+  return <String, dynamic>{
+    'source': 'manual',
+    'padding': const <String, dynamic>{
+      'top': 0,
+      'right': 0,
+      'bottom': 0,
+      'left': 0,
+    },
+    'shapeCells': <dynamic>[],
+    'cells': _legacyFullCellsJson(),
+    'manualAddedCells': _houseShapeCellsJson(),
+    'manualRemovedCells': <dynamic>[],
+  };
+}
+
+List<Map<String, dynamic>> _legacyFullCellsJson() {
+  return <Map<String, dynamic>>[
+    for (var y = 0; y < 7; y++)
+      for (var x = 0; x < 6; x++) <String, dynamic>{'x': x, 'y': y},
+  ];
+}
+
+List<Map<String, dynamic>> _houseShapeCellsJson() {
+  return _houseShapeCells
+      .map((cell) => <String, dynamic>{'x': cell.x, 'y': cell.y})
+      .toList(growable: false);
+}
+
+Map<String, dynamic> _maskJson({
+  required int widthPx,
+  required int heightPx,
+  required List<GridPos> solidPoints,
+}) {
+  final pixels = List<bool>.filled(widthPx * heightPx, false);
+  for (final point in solidPoints) {
+    pixels[point.y * widthPx + point.x] = true;
+  }
+  return <String, dynamic>{
+    'widthPx': widthPx,
+    'heightPx': heightPx,
+    'encoding': 'packed_bits_v1',
+    'dataBase64': ElementCollisionMaskCodec.encodePackedBits(
+      widthPx: widthPx,
+      heightPx: heightPx,
+      solidPixels: pixels,
+    ),
+  };
+}
+
 const List<GridPos> _houseShapeCells = <GridPos>[
   GridPos(x: 0, y: 3),
   GridPos(x: 1, y: 3),
```
