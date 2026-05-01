# Lot PathPattern-18 — Zoomable Tileset Image + Classic Alpha Preview V0

Rapport généré le 2026-05-01T01:49:06.

## 1. Résumé exécutif

Verdict : lot fonctionnellement terminé. Path Studio a maintenant des contrôles de zoom sur le picker image-backed, le clic reste calculé en coordonnées de tuiles, le fallback logique reste disponible, et le Path Mapping Editor classic gagne un zoom local plus une preview alpha non persistante.

Aucun changement map_core, ProjectManifest, codec, runtime, gameplay, battle, painter ou save flow n’a été effectué.

## 2. Audit initial

Context Mode disponible et utilisé via `mcp__context_mode__.ctx_batch_execute` pour indexer les recherches larges et éviter de charger tout le dépôt en contexte.

Commandes d’audit exécutées avant modification :

```bash
git status --short --untracked-files=all
git diff --stat
git diff --name-status
rg -n "Path Mapping Editor|Mapping Editor|Edit Mapping|Path preset|path mapping|variant mapping|PathMapping|TerrainPathVariant|PathPresetVariantMapping|path preset|pathPreset|pathPresets|variant" packages/map_editor/lib packages/map_editor/test
rg --files packages/map_editor/lib packages/map_editor/test | rg "path|mapping|preset|tileset|studio"
rg -n "Image.memory|CustomPainter|InteractiveViewer|GestureDetector|applyTilesetTransparentColorToPngBytes|TilesetTransparentColor|transparent|alpha|relativePath|tileWidth|tileHeight|sourceX|sourceY" packages/map_editor/lib packages/map_editor/test
```

État Git initial réel du Lot 18 :

```text
 M packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
 M packages/map_editor/test/path_pattern/path_studio_panel_test.dart
?? packages/map_editor/lib/src/features/path_studio/path_studio_tileset_image_picker.dart
?? packages/map_editor/test/path_pattern/path_studio_tileset_image_picker_test.dart
?? reports/pathPattern/pathpattern_17_image_backed_tileset_picker_v0.md
```

Diff stat initial réel du Lot 18 :

```text
 .../features/path_studio/path_studio_panel.dart    | 185 +++++++++++---
 .../test/path_pattern/path_studio_panel_test.dart  | 283 ++++++++++++++++++++-
 2 files changed, 425 insertions(+), 43 deletions(-)
```

Name-status initial réel du Lot 18 :

```text
M	packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
M	packages/map_editor/test/path_pattern/path_studio_panel_test.dart
```

Constats principaux :

- Path Studio Lot 17 disposait déjà de `path_studio_tileset_image_picker.dart`, avec image réelle, grille, clic de tuile et fallback logique.
- `PathStudioPanel` reçoit déjà `projectRootPath` et le transmet au picker image-backed.
- `ProjectTilesetEntry` expose `id`, `name`, `relativePath`; les dimensions de tuile viennent de `ProjectSettings.tileWidth/tileHeight`.
- Le classic Path Mapping Editor est dans `packages/map_editor/lib/src/ui/panels/terrain_editor/dialogs/terrain_preset_dialogs.dart`, avec painters/cache dans `terrain_mapping_workspace.dart`.
- Le classic chargeait une `ui.Image` via `_TerrainTilesetImageCache.load(path)`, affichait avec `CustomPaint`, et convertissait les clics via `_gridFromPickerLocal`.
- `TilesetTransparentColor` existe dans map_core et `applyTilesetTransparentColorToPngBytes(...)` existe côté map_editor, réutilisable pour une preview alpha locale.
- Un composant global partagé complet aurait été trop large ; la solution retenue partage seulement des helpers purs de zoom/clic/alpha pour le classic, et garde le picker Path Studio dans son composant dédié.

## 3. État constaté avant travaux

Le worktree contenait des changements hérités du Lot 17, notamment des fichiers non suivis. Aucun nettoyage, staging ou commit n’a été fait.

Le Lot 18 s’est appuyé sur ces fichiers hérités sans les supprimer ni les reclassifier. `git diff` ne peut pas représenter les fichiers non suivis ; leur contenu complet est donc inclus plus bas pour les fichiers source/test Path Studio concernés.

## 4. Path Studio zoom

Le picker image-backed Path Studio devient stateful et porte un zoom local :

- contrôles `Zoom -`, `Zoom +`, `100%`, `Ajuster` ;
- plage `0.5` à `8.0` ;
- pas de zoom global ni de service ;
- navigation horizontale et verticale via `SingleChildScrollView` imbriqués ;
- image affichée avec `FilterQuality.none` ;
- clic toujours basé sur `details.localPosition` et la taille affichée zoomée.

Le bouton `Ajuster` revient au zoom de base `1.0`, qui correspond au calcul local de fit/base width du picker.

## 5. Path Mapping Editor classic zoom

Le classic editor conserve son fonctionnement : sélection d’un variant dans le schema, puis clic dans le tileset pour mapper la tuile. Le Lot 18 ajoute :

- contrôles `Zoom -`, `Zoom +`, `100%`, `Ajuster` ;
- zoom local `mappingZoom`, sans persistance ;
- scroll horizontal et vertical autour du canvas zoomé ;
- conversion de clic via helper `pathMappingTileFromLocalPosition(...)`, en coordonnées de tuiles.

Le mapping variant continue de produire des `TilesetSourceRect(x, y, width: 1, height: 1)` en coordonnées de tuiles.

## 6. Classic alpha preview

Le classic editor reçoit un bloc discret `Transparence preview` :

- désactivé par défaut ;
- champ hex initial `f05ba1` ;
- erreur `Couleur hex invalide` si la valeur ne parse pas ;
- application via `applyTilesetTransparentColorToPngBytes(...)` ;
- le résultat remplace seulement l’image affichée (`displayedImage`) ;
- aucun fichier image, manifest ou preset projet n’est écrit.

## 7. Décisions prises

- Zoom step retenu : `1.25`, assez progressif pour les gros tilesets sans sauts brutaux.
- `minZoom = 0.5`, `maxZoom = 8.0` pour rester confortable sans rendre le canvas ingérable.
- Le bouton `Ajuster` est un reset de fit/base local en V0, pas un calcul dynamique complexe.
- Alpha preview non persistante : elle sert uniquement à inspecter une image rose/magenta, sans modifier le modèle.
- Pas de deep widget test pour la sheet private du classic ; couverture par helpers purs + analyze + review séparée.

## 8. Fichiers créés

- `packages/map_editor/lib/src/ui/panels/terrain_editor/path_mapping_editor_helpers.dart` : helpers purs zoom/clic/alpha preview pour le classic editor.
- `packages/map_editor/test/path_pattern/path_mapping_editor_helpers_test.dart` : tests unitaires des helpers classic.
- `reports/pathPattern/pathpattern_18_zoomable_tileset_image_classic_alpha_v0.md` : présent rapport.

## 9. Fichiers modifiés

- `packages/map_editor/lib/src/features/path_studio/path_studio_tileset_image_picker.dart` : zoom local et navigation scrollée Path Studio.
- `packages/map_editor/lib/src/ui/panels/terrain_editor_panel.dart` : import du helper classic.
- `packages/map_editor/lib/src/ui/panels/terrain_editor/dialogs/terrain_preset_dialogs.dart` : zoom classic, alpha preview, cache image asset bytes+image.
- `packages/map_editor/lib/src/ui/panels/terrain_editor/widgets/terrain_mapping_workspace.dart` : cache tileset enrichi avec bytes source et décodage preview.
- `packages/map_editor/test/path_pattern/path_studio_tileset_image_picker_test.dart` : test de conversion de clic avec taille zoomée.
- `packages/map_editor/test/path_pattern/path_studio_panel_test.dart` : assertions UI des contrôles zoom Path Studio.

Note : `packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart` est toujours modifié dans le worktree, mais cette modification est héritée du Lot 17 et n’a pas été retouchée par le Lot 18.

## 10. Fichiers supprimés

Aucun fichier supprimé.

## 11. Tests ajoutés / modifiés

- Ajout de `path_mapping_editor_helpers_test.dart` : coordonnées zoomées, clamp zoom, alpha preview désactivée/valide/invalide, non écriture du fichier source.
- Ajout dans `path_studio_tileset_image_picker_test.dart` : clic local sur canvas zoomé retourne toujours `sourceX/sourceY` en tuiles.
- Complément dans `path_studio_panel_test.dart` : contrôles zoom visibles, zoom +, zoom -, reset 100%, fit et assignation après zoom.

## 12. Commandes exécutées

- `git status --short --untracked-files=all` depuis `/Users/karim/Project/pokemonProject` -> code `0`
- `git diff --stat` depuis `/Users/karim/Project/pokemonProject` -> code `0`
- `git diff --name-status` depuis `/Users/karim/Project/pokemonProject` -> code `0`
- `git diff -- packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart packages/map_editor/lib/src/ui/panels/terrain_editor_panel.dart packages/map_editor/lib/src/ui/panels/terrain_editor/dialogs/terrain_preset_dialogs.dart packages/map_editor/lib/src/ui/panels/terrain_editor/widgets/terrain_mapping_workspace.dart packages/map_editor/test/path_pattern/path_studio_panel_test.dart` depuis `/Users/karim/Project/pokemonProject` -> code `0`
- `flutter test test/path_pattern/path_mapping_editor_helpers_test.dart --reporter expanded` depuis `/Users/karim/Project/pokemonProject/packages/map_editor` -> code `0`
- `flutter test test/path_pattern/path_studio_tileset_image_picker_test.dart --reporter expanded` depuis `/Users/karim/Project/pokemonProject/packages/map_editor` -> code `0`
- `flutter test test/path_pattern/path_studio_panel_test.dart --reporter expanded` depuis `/Users/karim/Project/pokemonProject/packages/map_editor` -> code `0`
- `flutter test test/path_pattern/ --reporter expanded` depuis `/Users/karim/Project/pokemonProject/packages/map_editor` -> code `0`
- `flutter test test/editor_shell_page_smoke_test.dart --reporter expanded` depuis `/Users/karim/Project/pokemonProject/packages/map_editor` -> code `0`
- `flutter test test/top_toolbar_test.dart --reporter expanded` depuis `/Users/karim/Project/pokemonProject/packages/map_editor` -> code `0`
- `flutter test test/editor_selectors_test.dart --reporter expanded` depuis `/Users/karim/Project/pokemonProject/packages/map_editor` -> code `0`
- `flutter analyze lib/src/features/path_studio lib/src/ui/panels/terrain_editor_panel.dart lib/src/ui/panels/terrain_editor test/path_pattern` depuis `/Users/karim/Project/pokemonProject/packages/map_editor` -> code `0`
- `dart test test/project_manifest_path_pattern_preset_operations_test.dart --reporter expanded --no-color` depuis `/Users/karim/Project/pokemonProject/packages/map_core` -> code `0`
- `dart test test/project_manifest_path_pattern_presets_test.dart --reporter expanded --no-color` depuis `/Users/karim/Project/pokemonProject/packages/map_core` -> code `0`
- `dart test test/project_path_pattern_preset_json_codec_test.dart --reporter expanded --no-color` depuis `/Users/karim/Project/pokemonProject/packages/map_core` -> code `0`
- `dart test test/project_path_pattern_preset_json_golden_test.dart --reporter expanded --no-color` depuis `/Users/karim/Project/pokemonProject/packages/map_core` -> code `0`
- `dart test test/project_path_pattern_preset_test.dart --reporter expanded --no-color` depuis `/Users/karim/Project/pokemonProject/packages/map_core` -> code `0`
- `dart test test/path_center_pattern_test.dart --reporter expanded --no-color` depuis `/Users/karim/Project/pokemonProject/packages/map_core` -> code `0`
- `dart test test/path_center_pattern_resolver_test.dart --reporter expanded --no-color` depuis `/Users/karim/Project/pokemonProject/packages/map_core` -> code `0`

## 13. Résultats des validations

Toutes les validations finales exécutées par le générateur de rapport ont terminé avec un code 0.

Résumé final exact des commandes longues :

- `flutter test path_mapping_editor_helpers_test` : `00:00 +6: All tests passed!`
- `flutter test path_studio_tileset_image_picker_test` : `00:00 +4: All tests passed!`
- `flutter test path_studio_panel_test` : `00:05 +19: All tests passed!`
- `flutter test test/path_pattern/` : `00:06 +84: All tests passed!`
- `flutter test editor_shell_page_smoke_test` : `00:02 +7: All tests passed!`
- `flutter test top_toolbar_test` : `00:01 +5: All tests passed!`
- `flutter test editor_selectors_test` : `00:00 +8: All tests passed!`
- `flutter analyze ciblé` : `No issues found! (ran in 2.5s)`
- `dart test project_manifest_path_pattern_preset_operations_test` : `00:00 +14: All tests passed!`
- `dart test project_manifest_path_pattern_presets_test` : `00:00 +8: All tests passed!`
- `dart test project_path_pattern_preset_json_codec_test` : `00:00 +9: All tests passed!`
- `dart test project_path_pattern_preset_json_golden_test` : `00:00 +6: All tests passed!`
- `dart test project_path_pattern_preset_test` : `00:00 +5: All tests passed!`
- `dart test path_center_pattern_test` : `00:00 +17: All tests passed!`
- `dart test path_center_pattern_resolver_test` : `00:00 +6: All tests passed!`

## 14. git status final

```text
 M packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
 M packages/map_editor/lib/src/ui/panels/terrain_editor/dialogs/terrain_preset_dialogs.dart
 M packages/map_editor/lib/src/ui/panels/terrain_editor/widgets/terrain_mapping_workspace.dart
 M packages/map_editor/lib/src/ui/panels/terrain_editor_panel.dart
 M packages/map_editor/test/path_pattern/path_studio_panel_test.dart
?? packages/map_editor/lib/src/features/path_studio/path_studio_tileset_image_picker.dart
?? packages/map_editor/lib/src/ui/panels/terrain_editor/path_mapping_editor_helpers.dart
?? packages/map_editor/test/path_pattern/path_mapping_editor_helpers_test.dart
?? packages/map_editor/test/path_pattern/path_studio_tileset_image_picker_test.dart
?? reports/pathPattern/pathpattern_17_image_backed_tileset_picker_v0.md
```

## 15. git diff --stat

```text
 .../features/path_studio/path_studio_panel.dart    | 185 +++++-
 .../dialogs/terrain_preset_dialogs.dart            | 708 ++++++++++++++-------
 .../widgets/terrain_mapping_workspace.dart         |  36 +-
 .../lib/src/ui/panels/terrain_editor_panel.dart    |   1 +
 .../test/path_pattern/path_studio_panel_test.dart  | 320 +++++++++-
 5 files changed, 956 insertions(+), 294 deletions(-)
```

## 16. git diff --name-status

```text
M	packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
M	packages/map_editor/lib/src/ui/panels/terrain_editor/dialogs/terrain_preset_dialogs.dart
M	packages/map_editor/lib/src/ui/panels/terrain_editor/widgets/terrain_mapping_workspace.dart
M	packages/map_editor/lib/src/ui/panels/terrain_editor_panel.dart
M	packages/map_editor/test/path_pattern/path_studio_panel_test.dart
```

## 17. Evidence Pack

### 17.1 Incident outil pendant RED

Un essai initial a lancé deux `flutter test` en parallèle. Le second a échoué avant exécution des tests sur le verrou de démarrage Flutter :

```text
Command: flutter test test/path_pattern/path_mapping_editor_helpers_test.dart --reporter expanded
Oops; flutter has exited unexpectedly: "PathExistsException: Cannot create link, path = '/Users/karim/Project/pokemonProject/packages/map_editor/macos/Flutter/ephemeral/Packages/.packages/macos_window_utils' (OS Error: File exists, errno = 17)".
Root cause: deux commandes Flutter simultanées dans le même package. Décision: relancer toutes les validations Flutter séquentiellement.
```

### 17.2 Sorties complètes des validations finales

#### git status --short --untracked-files=all final

Commande :

```bash
cd /Users/karim/Project/pokemonProject
git status --short --untracked-files=all
```

Code de sortie : `0`

Sortie :

```text
 M packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
 M packages/map_editor/lib/src/ui/panels/terrain_editor/dialogs/terrain_preset_dialogs.dart
 M packages/map_editor/lib/src/ui/panels/terrain_editor/widgets/terrain_mapping_workspace.dart
 M packages/map_editor/lib/src/ui/panels/terrain_editor_panel.dart
 M packages/map_editor/test/path_pattern/path_studio_panel_test.dart
?? packages/map_editor/lib/src/features/path_studio/path_studio_tileset_image_picker.dart
?? packages/map_editor/lib/src/ui/panels/terrain_editor/path_mapping_editor_helpers.dart
?? packages/map_editor/test/path_pattern/path_mapping_editor_helpers_test.dart
?? packages/map_editor/test/path_pattern/path_studio_tileset_image_picker_test.dart
?? reports/pathPattern/pathpattern_17_image_backed_tileset_picker_v0.md
```

#### git diff --stat final

Commande :

```bash
cd /Users/karim/Project/pokemonProject
git diff --stat
```

Code de sortie : `0`

Sortie :

```text
 .../features/path_studio/path_studio_panel.dart    | 185 +++++-
 .../dialogs/terrain_preset_dialogs.dart            | 708 ++++++++++++++-------
 .../widgets/terrain_mapping_workspace.dart         |  36 +-
 .../lib/src/ui/panels/terrain_editor_panel.dart    |   1 +
 .../test/path_pattern/path_studio_panel_test.dart  | 320 +++++++++-
 5 files changed, 956 insertions(+), 294 deletions(-)
```

#### git diff --name-status final

Commande :

```bash
cd /Users/karim/Project/pokemonProject
git diff --name-status
```

Code de sortie : `0`

Sortie :

```text
M	packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
M	packages/map_editor/lib/src/ui/panels/terrain_editor/dialogs/terrain_preset_dialogs.dart
M	packages/map_editor/lib/src/ui/panels/terrain_editor/widgets/terrain_mapping_workspace.dart
M	packages/map_editor/lib/src/ui/panels/terrain_editor_panel.dart
M	packages/map_editor/test/path_pattern/path_studio_panel_test.dart
```

#### git diff tracked files final

Commande :

```bash
cd /Users/karim/Project/pokemonProject
git diff -- packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart packages/map_editor/lib/src/ui/panels/terrain_editor_panel.dart packages/map_editor/lib/src/ui/panels/terrain_editor/dialogs/terrain_preset_dialogs.dart packages/map_editor/lib/src/ui/panels/terrain_editor/widgets/terrain_mapping_workspace.dart packages/map_editor/test/path_pattern/path_studio_panel_test.dart
```

Code de sortie : `0`

Sortie :

```text
diff --git a/packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart b/packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
index bad7b526..b783aa2d 100644
--- a/packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
+++ b/packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
@@ -8,6 +8,7 @@ import 'path_pattern_draft.dart';
 import 'path_pattern_editor_read_model.dart';
 import 'path_studio_new_path_draft.dart';
 import 'path_studio_theme.dart';
+import 'path_studio_tileset_image_picker.dart';
 
 /// Workspace branché au shell global de l'éditeur.
 ///
@@ -20,10 +21,14 @@ class PathStudioWorkspace extends ConsumerWidget {
   @override
   Widget build(BuildContext context, WidgetRef ref) {
     final manifest = ref.watch(editorProjectManifestProvider);
+    final projectRootPath = ref.watch(editorProjectRootPathProvider);
     if (manifest == null) {
       return const _PathStudioProjectMissingState();
     }
-    return PathStudioPanel(manifest: manifest);
+    return PathStudioPanel(
+      manifest: manifest,
+      projectRootPath: projectRootPath,
+    );
   }
 }
 
@@ -37,9 +42,11 @@ class PathStudioPanel extends StatefulWidget {
   const PathStudioPanel({
     super.key,
     required this.manifest,
+    this.projectRootPath,
   });
 
   final ProjectManifest manifest;
+  final String? projectRootPath;
 
   @override
   State<PathStudioPanel> createState() => _PathStudioPanelState();
@@ -150,6 +157,8 @@ class _PathStudioPanelState extends State<PathStudioPanel> {
                   Expanded(
                     child: _CenterWorkspace(
                       tilesets: widget.manifest.tilesets,
+                      settings: widget.manifest.settings,
+                      projectRootPath: widget.projectRootPath,
                       newPathDraft: selectedNewPathDraft,
                       draft: selectedDraft,
                       selected: selected?.card,
@@ -1255,6 +1264,8 @@ class _MiniMetric extends StatelessWidget {
 class _CenterWorkspace extends StatelessWidget {
   const _CenterWorkspace({
     required this.tilesets,
+    required this.settings,
+    required this.projectRootPath,
     required this.newPathDraft,
     required this.draft,
     required this.selected,
@@ -1268,6 +1279,8 @@ class _CenterWorkspace extends StatelessWidget {
   });
 
   final List<ProjectTilesetEntry> tilesets;
+  final ProjectSettings settings;
+  final String? projectRootPath;
   final PathStudioNewPathDraft? newPathDraft;
   final PathPatternDraft? draft;
   final PathPatternPresetCardModel? selected;
@@ -1285,6 +1298,8 @@ class _CenterWorkspace extends StatelessWidget {
     if (newPathDraft != null) {
       return _NewPathCenterWorkspace(
         tilesets: tilesets,
+        settings: settings,
+        projectRootPath: projectRootPath,
         draft: newPathDraft,
         onSizeChanged: onNewPathSizeChanged,
         onCellSelected: onNewPathCellSelected,
@@ -1325,6 +1340,8 @@ class _CenterWorkspace extends StatelessWidget {
 class _NewPathCenterWorkspace extends StatelessWidget {
   const _NewPathCenterWorkspace({
     required this.tilesets,
+    required this.settings,
+    required this.projectRootPath,
     required this.draft,
     required this.onSizeChanged,
     required this.onCellSelected,
@@ -1333,6 +1350,8 @@ class _NewPathCenterWorkspace extends StatelessWidget {
   });
 
   final List<ProjectTilesetEntry> tilesets;
+  final ProjectSettings settings;
+  final String? projectRootPath;
   final PathStudioNewPathDraft draft;
   final void Function(int width, int height) onSizeChanged;
   final void Function(int localX, int localY) onCellSelected;
@@ -1353,6 +1372,8 @@ class _NewPathCenterWorkspace extends StatelessWidget {
           const SizedBox(height: 14),
           _NewPathCenterPatternEditor(
             tilesets: tilesets,
+            settings: settings,
+            projectRootPath: projectRootPath,
             draft: draft,
             onSizeChanged: onSizeChanged,
             onCellSelected: onCellSelected,
@@ -1460,6 +1481,8 @@ class _NewPathSummary extends StatelessWidget {
 class _NewPathCenterPatternEditor extends StatelessWidget {
   const _NewPathCenterPatternEditor({
     required this.tilesets,
+    required this.settings,
+    required this.projectRootPath,
     required this.draft,
     required this.onSizeChanged,
     required this.onCellSelected,
@@ -1468,6 +1491,8 @@ class _NewPathCenterPatternEditor extends StatelessWidget {
   });
 
   final List<ProjectTilesetEntry> tilesets;
+  final ProjectSettings settings;
+  final String? projectRootPath;
   final PathStudioNewPathDraft draft;
   final void Function(int width, int height) onSizeChanged;
   final void Function(int localX, int localY) onCellSelected;
@@ -1516,6 +1541,9 @@ class _NewPathCenterPatternEditor extends StatelessWidget {
           ),
           const SizedBox(height: 18),
           _NewPathPatternGrid(
+            tilesets: tilesets,
+            settings: settings,
+            projectRootPath: projectRootPath,
             draft: draft,
             onCellSelected: onCellSelected,
           ),
@@ -1527,6 +1555,8 @@ class _NewPathCenterPatternEditor extends StatelessWidget {
           const SizedBox(height: 14),
           _NewPathTilePickerPanel(
             tilesets: tilesets,
+            settings: settings,
+            projectRootPath: projectRootPath,
             draft: draft,
             onTileSelected: onTileSelected,
           ),
@@ -1538,10 +1568,16 @@ class _NewPathCenterPatternEditor extends StatelessWidget {
 
 class _NewPathPatternGrid extends StatelessWidget {
   const _NewPathPatternGrid({
+    required this.tilesets,
+    required this.settings,
+    required this.projectRootPath,
     required this.draft,
     required this.onCellSelected,
   });
 
+  final List<ProjectTilesetEntry> tilesets;
+  final ProjectSettings settings;
+  final String? projectRootPath;
   final PathStudioNewPathDraft draft;
   final void Function(int localX, int localY) onCellSelected;
 
@@ -1557,6 +1593,9 @@ class _NewPathPatternGrid extends StatelessWidget {
         cells.add(
           _NewPathPatternCell(
             key: Key('path-studio-new-path-cell-$x-$y'),
+            tilesets: tilesets,
+            settings: settings,
+            projectRootPath: projectRootPath,
             cell: cell,
             selected: draft.selectedCellX == x && draft.selectedCellY == y,
             onTap: () => onCellSelected(x, y),
@@ -1579,11 +1618,17 @@ class _NewPathPatternGrid extends StatelessWidget {
 class _NewPathPatternCell extends StatelessWidget {
   const _NewPathPatternCell({
     super.key,
+    required this.tilesets,
+    required this.settings,
+    required this.projectRootPath,
     required this.cell,
     required this.selected,
     required this.onTap,
   });
 
+  final List<ProjectTilesetEntry> tilesets;
+  final ProjectSettings settings;
+  final String? projectRootPath;
   final PathStudioNewPathDraftCell cell;
   final bool selected;
   final VoidCallback onTap;
@@ -1625,7 +1670,12 @@ class _NewPathPatternCell extends StatelessWidget {
             ),
             const Spacer(),
             if (tile != null)
-              _TilePreviewBadge(tile: tile)
+              _TilePreviewBadge(
+                tilesets: tilesets,
+                settings: settings,
+                projectRootPath: projectRootPath,
+                tile: tile,
+              )
             else
               const _EmptyTileBadge(),
             const SizedBox(height: 6),
@@ -1732,13 +1782,21 @@ class _NewPathSelectedCellDetails extends StatelessWidget {
 }
 
 class _TilePreviewBadge extends StatelessWidget {
-  const _TilePreviewBadge({required this.tile});
+  const _TilePreviewBadge({
+    required this.tilesets,
+    required this.settings,
+    required this.projectRootPath,
+    required this.tile,
+  });
 
+  final List<ProjectTilesetEntry> tilesets;
+  final ProjectSettings settings;
+  final String? projectRootPath;
   final PathStudioNewPathDraftTile tile;
 
   @override
   Widget build(BuildContext context) {
-    return Container(
+    final fallback = Container(
       width: 46,
       height: 28,
       decoration: BoxDecoration(
@@ -1757,6 +1815,13 @@ class _TilePreviewBadge extends StatelessWidget {
         ),
       ),
     );
+    return PathStudioTileSpritePreview(
+      projectRootPath: projectRootPath,
+      tilesets: tilesets,
+      settings: settings,
+      tile: tile,
+      fallback: fallback,
+    );
   }
 }
 
@@ -1788,19 +1853,27 @@ class _EmptyTileBadge extends StatelessWidget {
 class _NewPathTilePickerPanel extends StatelessWidget {
   const _NewPathTilePickerPanel({
     required this.tilesets,
+    required this.settings,
+    required this.projectRootPath,
     required this.draft,
     required this.onTileSelected,
   });
 
   final List<ProjectTilesetEntry> tilesets;
+  final ProjectSettings settings;
+  final String? projectRootPath;
   final PathStudioNewPathDraft draft;
   final void Function(int sourceX, int sourceY) onTileSelected;
 
   @override
   Widget build(BuildContext context) {
+    final selectedTileset = _selectedTileset(
+      tilesets: tilesets,
+      tilesetId: draft.tilesetId,
+    );
     final tilesetLabel =
         _selectedTilesetLabel(tilesets: tilesets, tilesetId: draft.tilesetId);
-    if (tilesetLabel == null) {
+    if (tilesetLabel == null || selectedTileset == null) {
       return Container(
         padding: const EdgeInsets.all(14),
         decoration: PathStudioTheme.subtleDecoration(
@@ -1884,32 +1957,19 @@ class _NewPathTilePickerPanel extends StatelessWidget {
             ),
           ),
           const SizedBox(height: 12),
-          Wrap(
-            spacing: 8,
-            runSpacing: 8,
-            children: [
-              for (var y = 0; y < 4; y += 1)
-                for (var x = 0; x < 8; x += 1)
-                  _NewPathTileButton(
-                    key: Key('path-studio-new-path-tile-$x-$y'),
-                    sourceX: x,
-                    sourceY: y,
-                    selected: selectedCell.tile?.sourceX == x &&
-                        selectedCell.tile?.sourceY == y &&
-                        selectedCell.tile?.tilesetId == draft.tilesetId,
-                    onTap: () => onTileSelected(x, y),
-                  ),
-            ],
-          ),
-          const SizedBox(height: 10),
-          const Text(
-            'Grille logique V0 : les coordonnées sont enregistrées dans le brouillon, sans lecture de l’image tileset ni preview PNG.',
-            style: TextStyle(
-              color: PathStudioTheme.textMuted,
-              fontSize: 10.5,
-              height: 1.35,
-              fontWeight: FontWeight.w700,
-            ),
+          PathStudioImageBackedTilesetPicker(
+            projectRootPath: projectRootPath,
+            tileset: selectedTileset,
+            settings: settings,
+            activeCell: selectedCell,
+            onTileSelected: (source) => onTileSelected(source.x, source.y),
+            fallbackBuilder: (context, result) {
+              return _LogicalNewPathTileGrid(
+                draft: draft,
+                selectedCell: selectedCell,
+                onTileSelected: onTileSelected,
+              );
+            },
           ),
         ],
       ),
@@ -1917,6 +1977,54 @@ class _NewPathTilePickerPanel extends StatelessWidget {
   }
 }
 
+class _LogicalNewPathTileGrid extends StatelessWidget {
+  const _LogicalNewPathTileGrid({
+    required this.draft,
+    required this.selectedCell,
+    required this.onTileSelected,
+  });
+
+  final PathStudioNewPathDraft draft;
+  final PathStudioNewPathDraftCell selectedCell;
+  final void Function(int sourceX, int sourceY) onTileSelected;
+
+  @override
+  Widget build(BuildContext context) {
+    return Column(
+      crossAxisAlignment: CrossAxisAlignment.start,
+      children: [
+        Wrap(
+          spacing: 8,
+          runSpacing: 8,
+          children: [
+            for (var y = 0; y < 4; y += 1)
+              for (var x = 0; x < 8; x += 1)
+                _NewPathTileButton(
+                  key: Key('path-studio-new-path-tile-$x-$y'),
+                  sourceX: x,
+                  sourceY: y,
+                  selected: selectedCell.tile?.sourceX == x &&
+                      selectedCell.tile?.sourceY == y &&
+                      selectedCell.tile?.tilesetId == draft.tilesetId,
+                  onTap: () => onTileSelected(x, y),
+                ),
+          ],
+        ),
+        const SizedBox(height: 10),
+        const Text(
+          'Fallback V0 : les coordonnées sont enregistrées dans le brouillon quand l’image tileset ne peut pas être chargée.',
+          style: TextStyle(
+            color: PathStudioTheme.textMuted,
+            fontSize: 10.5,
+            height: 1.35,
+            fontWeight: FontWeight.w700,
+          ),
+        ),
+      ],
+    );
+  }
+}
+
 class _NewPathTileButton extends StatelessWidget {
   const _NewPathTileButton({
     super.key,
@@ -3524,6 +3632,21 @@ String? _selectedTilesetLabel({
   return tilesetId;
 }
 
+ProjectTilesetEntry? _selectedTileset({
+  required List<ProjectTilesetEntry> tilesets,
+  required String? tilesetId,
+}) {
+  if (tilesetId == null || tilesetId.isEmpty) {
+    return null;
+  }
+  for (final tileset in tilesets) {
+    if (tileset.id == tilesetId) {
+      return tileset;
+    }
+  }
+  return null;
+}
+
 String _newPathDraftIssueLabel(PathStudioNewPathDraftIssueCode issue) {
   return switch (issue) {
     PathStudioNewPathDraftIssueCode.nameRequired => 'Nom requis',
diff --git a/packages/map_editor/lib/src/ui/panels/terrain_editor/dialogs/terrain_preset_dialogs.dart b/packages/map_editor/lib/src/ui/panels/terrain_editor/dialogs/terrain_preset_dialogs.dart
index 67f635ea..4eccc7a1 100644
--- a/packages/map_editor/lib/src/ui/panels/terrain_editor/dialogs/terrain_preset_dialogs.dart
+++ b/packages/map_editor/lib/src/ui/panels/terrain_editor/dialogs/terrain_preset_dialogs.dart
@@ -1003,10 +1003,11 @@ Future<TilesetSourceRect?> _showTilesetRectPickerDialog(
   if (path == null) {
     return null;
   }
-  final image = await _TerrainTilesetImageCache.load(path);
-  if (image == null) {
+  final imageAsset = await _TerrainTilesetImageCache.loadAsset(path);
+  if (imageAsset == null) {
     return null;
   }
+  final image = imageAsset.image;
   if (settings.tileWidth <= 0 || settings.tileHeight <= 0) {
     return null;
   }
@@ -1167,13 +1168,12 @@ GridPos _gridFromPickerLocal(
   int columns,
   int rows,
 ) {
-  final maxX = math.max(0.0, columns * cellWidth - 0.000001);
-  final maxY = math.max(0.0, rows * cellHeight - 0.000001);
-  final dx = localPosition.dx.clamp(0.0, maxX).toDouble();
-  final dy = localPosition.dy.clamp(0.0, maxY).toDouble();
-  final x = (dx / cellWidth).floor().clamp(0, columns - 1);
-  final y = (dy / cellHeight).floor().clamp(0, rows - 1);
-  return GridPos(x: x, y: y);
+  return pathMappingTileFromLocalPosition(
+    localPosition: localPosition,
+    displaySize: ui.Size(columns * cellWidth, rows * cellHeight),
+    columns: columns,
+    rows: rows,
+  );
 }
 
 TilesetSourceRect _rectFromGridPoints(GridPos start, GridPos end) {
@@ -1206,10 +1206,11 @@ Future<Map<TerrainPathVariant, List<TilesetVisualFrame>>?>
   if (path == null || path.isEmpty) {
     return null;
   }
-  final image = await _TerrainTilesetImageCache.load(path);
-  if (image == null) {
+  final imageAsset = await _TerrainTilesetImageCache.loadAsset(path);
+  if (imageAsset == null) {
     return null;
   }
+  final image = imageAsset.image;
 
   final sourceTileWidth = settings.tileWidth;
   final sourceTileHeight = settings.tileHeight;
@@ -1238,127 +1239,77 @@ Future<Map<TerrainPathVariant, List<TilesetVisualFrame>>?>
           orElse: () => _pathSchemaEditableVariants.first,
         );
   Map<TerrainPathVariant, List<TilesetVisualFrame>>? result;
+  var displayedImage = image;
+  var mappingZoom = 1.0;
+  var alphaPreviewEnabled = false;
+  var alphaPreviewErrorMessage = '';
+  var alphaPreviewRevision = 0;
+  final alphaPreviewController = TextEditingController(text: 'f05ba1');
+
+  Future<void> updateAlphaPreview(StateSetter setState) async {
+    final revision = ++alphaPreviewRevision;
+    final preview = createPathMappingAlphaPreviewBytes(
+      originalPngBytes: imageAsset.bytes,
+      enabled: alphaPreviewEnabled,
+      hexRgb: alphaPreviewController.text,
+    );
+    if (!alphaPreviewEnabled || preview.errorMessage != null) {
+      if (!context.mounted || revision != alphaPreviewRevision) {
+        return;
+      }
+      setState(() {
+        displayedImage = image;
+        alphaPreviewErrorMessage = preview.errorMessage ?? '';
+      });
+      return;
+    }
+    final decoded = await _TerrainTilesetImageCache.decodeBytes(preview.bytes);
+    if (!context.mounted || revision != alphaPreviewRevision) {
+      return;
+    }
+    setState(() {
+      displayedImage = decoded ?? image;
+      alphaPreviewErrorMessage =
+          decoded == null ? 'Preview alpha indisponible' : '';
+    });
+  }
 
   if (!context.mounted) {
+    alphaPreviewController.dispose();
     return null;
   }
-  await showMacosSheet<void>(
-    context: context,
-    builder: (ctx) => StatefulBuilder(
-      builder: (ctx, setState) => Center(
-        child: MacosSheet(
-          insetPadding:
-              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
-          child: Padding(
-            padding: const EdgeInsets.all(12),
-            child: SizedBox(
-              width: 980,
-              height: 660,
-              child: Column(
-                crossAxisAlignment: CrossAxisAlignment.stretch,
-                children: [
-                  Text(
-                    'Path Mapping Editor',
-                    style: editorMacosSheetTitleStyle(ctx),
-                  ),
-                  const SizedBox(height: 8),
-                  Expanded(
-                    child: Row(
-                      crossAxisAlignment: CrossAxisAlignment.stretch,
-                      children: [
-                        SizedBox(
-                          width: 430,
-                          child: Column(
-                            crossAxisAlignment: CrossAxisAlignment.stretch,
-                            children: [
-                              Text(
-                                'Step 1: Complete the schema',
-                                style: TextStyle(
-                                  color: CupertinoColors.label
-                                      .resolveFrom(ctx)
-                                      .withValues(alpha: 0.9),
-                                  fontSize: 12,
-                                  fontWeight: FontWeight.w700,
-                                ),
-                              ),
-                              const SizedBox(height: 6),
-                              Text(
-                                '${mappings.length}/${TerrainPathVariant.values.length} mapped',
-                                style: TextStyle(
-                                  color: CupertinoColors.secondaryLabel
-                                      .resolveFrom(ctx),
-                                  fontSize: 11,
-                                ),
-                              ),
-                              const SizedBox(height: 8),
-                              Container(
-                                padding: const EdgeInsets.symmetric(
-                                  horizontal: 8,
-                                  vertical: 7,
-                                ),
-                                decoration: BoxDecoration(
-                                  color: CupertinoColors.systemFill
-                                      .resolveFrom(ctx),
-                                  borderRadius: BorderRadius.circular(8),
-                                  border: Border.all(
-                                    color: CupertinoColors.separator
-                                        .resolveFrom(ctx),
-                                  ),
-                                ),
-                                child: Text(
-                                  'Select a slot in the schema, then click a cell in the tileset on the right to assign it.',
-                                  style: TextStyle(
-                                    fontSize: 10,
-                                    color: CupertinoColors.secondaryLabel
-                                        .resolveFrom(ctx),
-                                  ),
-                                ),
-                              ),
-                              const SizedBox(height: 10),
-                              Expanded(
-                                child: Container(
-                                  padding: const EdgeInsets.all(8),
-                                  decoration: BoxDecoration(
-                                    color: CupertinoColors.systemFill
-                                        .resolveFrom(ctx),
-                                    borderRadius: BorderRadius.circular(10),
-                                    border: Border.all(
-                                      color: CupertinoColors.separator
-                                          .resolveFrom(ctx),
-                                    ),
-                                  ),
-                                  child: _PathSchemaCanvas(
-                                    mappings: mappings,
-                                    selectedVariant: selectedVariant,
-                                    image: image,
-                                    sourceTileWidth: sourceTileWidth,
-                                    sourceTileHeight: sourceTileHeight,
-                                    onSelect: (variant) => setState(
-                                        () => selectedVariant = variant),
-                                  ),
-                                ),
-                              ),
-                            ],
-                          ),
-                        ),
-                        const SizedBox(width: 12),
-                        Expanded(
-                          child: Container(
-                            padding: const EdgeInsets.all(10),
-                            decoration: BoxDecoration(
-                              color:
-                                  CupertinoColors.systemFill.resolveFrom(ctx),
-                              borderRadius: BorderRadius.circular(10),
-                              border: Border.all(
-                                color:
-                                    CupertinoColors.separator.resolveFrom(ctx),
-                              ),
-                            ),
+  try {
+    await showMacosSheet<void>(
+      context: context,
+      builder: (ctx) => StatefulBuilder(
+        builder: (ctx, setState) => Center(
+          child: MacosSheet(
+            insetPadding:
+                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
+            child: Padding(
+              padding: const EdgeInsets.all(12),
+              child: SizedBox(
+                width: 980,
+                height: 660,
+                child: Column(
+                  crossAxisAlignment: CrossAxisAlignment.stretch,
+                  children: [
+                    Text(
+                      'Path Mapping Editor',
+                      style: editorMacosSheetTitleStyle(ctx),
+                    ),
+                    const SizedBox(height: 8),
+                    Expanded(
+                      child: Row(
+                        crossAxisAlignment: CrossAxisAlignment.stretch,
+                        children: [
+                          SizedBox(
+                            width: 430,
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.stretch,
                               children: [
                                 Text(
-                                  'Step 2: Click the tileset to map "${_pathVariantDisplayName(selectedVariant)}"',
+                                  'Step 1: Complete the schema',
                                   style: TextStyle(
                                     color: CupertinoColors.label
                                         .resolveFrom(ctx)
@@ -1369,7 +1320,7 @@ Future<Map<TerrainPathVariant, List<TilesetVisualFrame>>?>
                                 ),
                                 const SizedBox(height: 6),
                                 Text(
-                                  'Tileset: ${notifier.getTilesetById(normalizedTilesetId)?.name ?? normalizedTilesetId}',
+                                  '${mappings.length}/${TerrainPathVariant.values.length} mapped',
                                   style: TextStyle(
                                     color: CupertinoColors.secondaryLabel
                                         .resolveFrom(ctx),
@@ -1378,101 +1329,354 @@ Future<Map<TerrainPathVariant, List<TilesetVisualFrame>>?>
                                 ),
                                 const SizedBox(height: 8),
                                 Container(
-                                  padding: const EdgeInsets.all(8),
+                                  padding: const EdgeInsets.symmetric(
+                                    horizontal: 8,
+                                    vertical: 7,
+                                  ),
                                   decoration: BoxDecoration(
-                                    color: EditorPaintColors.blueGrey
-                                        .withValues(alpha: 0.2),
+                                    color: CupertinoColors.systemFill
+                                        .resolveFrom(ctx),
                                     borderRadius: BorderRadius.circular(8),
                                     border: Border.all(
                                       color: CupertinoColors.separator
                                           .resolveFrom(ctx),
                                     ),
                                   ),
-                                  child: Column(
-                                    crossAxisAlignment:
-                                        CrossAxisAlignment.start,
-                                    children: [
-                                      Text(
-                                        'Active variant: ${_pathVariantDisplayName(selectedVariant)}',
-                                        style: TextStyle(
-                                          fontSize: 11,
-                                          color: CupertinoColors.label
-                                              .resolveFrom(ctx),
-                                          fontWeight: FontWeight.w700,
+                                  child: Text(
+                                    'Select a slot in the schema, then click a cell in the tileset on the right to assign it.',
+                                    style: TextStyle(
+                                      fontSize: 10,
+                                      color: CupertinoColors.secondaryLabel
+                                          .resolveFrom(ctx),
+                                    ),
+                                  ),
+                                ),
+                                const SizedBox(height: 10),
+                                Expanded(
+                                  child: Container(
+                                    padding: const EdgeInsets.all(8),
+                                    decoration: BoxDecoration(
+                                      color: CupertinoColors.systemFill
+                                          .resolveFrom(ctx),
+                                      borderRadius: BorderRadius.circular(10),
+                                      border: Border.all(
+                                        color: CupertinoColors.separator
+                                            .resolveFrom(ctx),
+                                      ),
+                                    ),
+                                    child: _PathSchemaCanvas(
+                                      mappings: mappings,
+                                      selectedVariant: selectedVariant,
+                                      image: displayedImage,
+                                      sourceTileWidth: sourceTileWidth,
+                                      sourceTileHeight: sourceTileHeight,
+                                      onSelect: (variant) => setState(
+                                          () => selectedVariant = variant),
+                                    ),
+                                  ),
+                                ),
+                              ],
+                            ),
+                          ),
+                          const SizedBox(width: 12),
+                          Expanded(
+                            child: Container(
+                              padding: const EdgeInsets.all(10),
+                              decoration: BoxDecoration(
+                                color:
+                                    CupertinoColors.systemFill.resolveFrom(ctx),
+                                borderRadius: BorderRadius.circular(10),
+                                border: Border.all(
+                                  color: CupertinoColors.separator
+                                      .resolveFrom(ctx),
+                                ),
+                              ),
+                              child: Column(
+                                crossAxisAlignment: CrossAxisAlignment.stretch,
+                                children: [
+                                  Text(
+                                    'Step 2: Click the tileset to map "${_pathVariantDisplayName(selectedVariant)}"',
+                                    style: TextStyle(
+                                      color: CupertinoColors.label
+                                          .resolveFrom(ctx)
+                                          .withValues(alpha: 0.9),
+                                      fontSize: 12,
+                                      fontWeight: FontWeight.w700,
+                                    ),
+                                  ),
+                                  const SizedBox(height: 6),
+                                  Text(
+                                    'Tileset: ${notifier.getTilesetById(normalizedTilesetId)?.name ?? normalizedTilesetId}',
+                                    style: TextStyle(
+                                      color: CupertinoColors.secondaryLabel
+                                          .resolveFrom(ctx),
+                                      fontSize: 11,
+                                    ),
+                                  ),
+                                  const SizedBox(height: 8),
+                                  Container(
+                                    padding: const EdgeInsets.all(8),
+                                    decoration: BoxDecoration(
+                                      color: EditorPaintColors.blueGrey
+                                          .withValues(alpha: 0.2),
+                                      borderRadius: BorderRadius.circular(8),
+                                      border: Border.all(
+                                        color: CupertinoColors.separator
+                                            .resolveFrom(ctx),
+                                      ),
+                                    ),
+                                    child: Column(
+                                      crossAxisAlignment:
+                                          CrossAxisAlignment.start,
+                                      children: [
+                                        Text(
+                                          'Active variant: ${_pathVariantDisplayName(selectedVariant)}',
+                                          style: TextStyle(
+                                            fontSize: 11,
+                                            color: CupertinoColors.label
+                                                .resolveFrom(ctx),
+                                            fontWeight: FontWeight.w700,
+                                          ),
+                                        ),
+                                        const SizedBox(height: 2),
+                                        Text(
+                                          'Connections: ${_pathVariantDirectionsLabel(selectedVariant)}',
+                                          style: TextStyle(
+                                            fontSize: 10,
+                                            color: CupertinoColors
+                                                .secondaryLabel
+                                                .resolveFrom(ctx),
+                                          ),
+                                        ),
+                                        const SizedBox(height: 2),
+                                        Text(
+                                          _pathVariantUsageDescription(
+                                            selectedVariant,
+                                          ),
+                                          style: TextStyle(
+                                            fontSize: 10,
+                                            color: CupertinoColors
+                                                .secondaryLabel
+                                                .resolveFrom(ctx),
+                                          ),
                                         ),
+                                      ],
+                                    ),
+                                  ),
+                                  const SizedBox(height: 8),
+                                  Container(
+                                    padding: const EdgeInsets.all(8),
+                                    decoration: BoxDecoration(
+                                      color: EditorPaintColors.black
+                                          .withValues(alpha: 0.16),
+                                      borderRadius: BorderRadius.circular(8),
+                                      border: Border.all(
+                                        color: CupertinoColors.separator
+                                            .resolveFrom(ctx),
                                       ),
-                                      const SizedBox(height: 2),
-                                      Text(
-                                        'Connections: ${_pathVariantDirectionsLabel(selectedVariant)}',
-                                        style: TextStyle(
-                                          fontSize: 10,
-                                          color: CupertinoColors.secondaryLabel
-                                              .resolveFrom(ctx),
+                                    ),
+                                    child: Column(
+                                      crossAxisAlignment:
+                                          CrossAxisAlignment.stretch,
+                                      children: [
+                                        Row(
+                                          children: [
+                                            Text(
+                                              'Transparence preview',
+                                              style: TextStyle(
+                                                fontSize: 11,
+                                                color: CupertinoColors.label
+                                                    .resolveFrom(ctx),
+                                                fontWeight: FontWeight.w700,
+                                              ),
+                                            ),
+                                            const Spacer(),
+                                            CupertinoSwitch(
+                                              key: const Key(
+                                                'path-mapping-alpha-toggle',
+                                              ),
+                                              value: alphaPreviewEnabled,
+                                              onChanged: (value) {
+                                                setState(() {
+                                                  alphaPreviewEnabled = value;
+                                                  if (!value) {
+                                                    displayedImage = image;
+                                                    alphaPreviewErrorMessage =
+                                                        '';
+                                                  }
+                                                });
+                                                if (value) {
+                                                  unawaited(
+                                                    updateAlphaPreview(
+                                                        setState),
+                                                  );
+                                                }
+                                              },
+                                            ),
+                                          ],
+                                        ),
+                                        const SizedBox(height: 6),
+                                        CupertinoTextField(
+                                          key: const Key(
+                                            'path-mapping-alpha-hex-field',
+                                          ),
+                                          controller: alphaPreviewController,
+                                          enabled: alphaPreviewEnabled,
+                                          placeholder: 'f05ba1',
+                                          padding: const EdgeInsets.symmetric(
+                                            horizontal: 8,
+                                            vertical: 6,
+                                          ),
+                                          onChanged: (_) {
+                                            if (alphaPreviewEnabled) {
+                                              unawaited(
+                                                updateAlphaPreview(setState),
+                                              );
+                                            }
+                                          },
                                         ),
+                                        if (alphaPreviewErrorMessage.isNotEmpty)
+                                          Padding(
+                                            padding:
+                                                const EdgeInsets.only(top: 5),
+                                            child: Text(
+                                              alphaPreviewErrorMessage,
+                                              style: const TextStyle(
+                                                fontSize: 10,
+                                                color:
+                                                    EditorPaintColors.redAccent,
+                                              ),
+                                            ),
+                                          ),
+                                      ],
+                                    ),
+                                  ),
+                                  const SizedBox(height: 10),
+                                  _PathVariantFramesEditor(
+                                    image: displayedImage,
+                                    sourceTileWidth: sourceTileWidth,
+                                    sourceTileHeight: sourceTileHeight,
+                                    frames: mappings[selectedVariant] ??
+                                        const <TilesetVisualFrame>[],
+                                    onChanged: (next) {
+                                      setState(() {
+                                        if (next.isEmpty) {
+                                          mappings.remove(selectedVariant);
+                                        } else {
+                                          mappings[selectedVariant] = next;
+                                        }
+                                      });
+                                    },
+                                    onPickFrame: (initial) async {
+                                      final picked =
+                                          await _showTilesetRectPickerDialog(
+                                        context,
+                                        notifier: notifier,
+                                        settings: settings,
+                                        tilesetId: normalizedTilesetId,
+                                        initial: initial,
+                                        title: 'Pick path frame source',
+                                      );
+                                      if (picked == null) {
+                                        return null;
+                                      }
+                                      return TilesetSourceRect(
+                                        x: picked.x,
+                                        y: picked.y,
+                                        width: 1,
+                                        height: 1,
+                                      );
+                                    },
+                                  ),
+                                  const SizedBox(height: 10),
+                                  Row(
+                                    children: [
+                                      PushButton(
+                                        key: const Key('path-mapping-zoom-out'),
+                                        controlSize: ControlSize.small,
+                                        secondary: true,
+                                        onPressed: mappingZoom >
+                                                pathMappingTilesetMinZoom
+                                            ? () => setState(() {
+                                                  mappingZoom =
+                                                      pathMappingTilesetZoomOut(
+                                                    mappingZoom,
+                                                  );
+                                                })
+                                            : null,
+                                        child: const Text('Zoom -'),
                                       ),
-                                      const SizedBox(height: 2),
+                                      const SizedBox(width: 6),
+                                      PushButton(
+                                        key: const Key('path-mapping-zoom-in'),
+                                        controlSize: ControlSize.small,
+                                        secondary: true,
+                                        onPressed: mappingZoom <
+                                                pathMappingTilesetMaxZoom
+                                            ? () => setState(() {
+                                                  mappingZoom =
+                                                      pathMappingTilesetZoomIn(
+                                                    mappingZoom,
+                                                  );
+                                                })
+                                            : null,
+                                        child: const Text('Zoom +'),
+                                      ),
+                                      const SizedBox(width: 6),
+                                      PushButton(
+                                        key: const Key(
+                                            'path-mapping-zoom-reset'),
+                                        controlSize: ControlSize.small,
+                                        secondary: true,
+                                        onPressed: mappingZoom == 1.0
+                                            ? null
+                                            : () => setState(
+                                                  () => mappingZoom = 1.0,
+                                                ),
+                                        child: const Text('100%'),
+                                      ),
+                                      const SizedBox(width: 6),
+                                      PushButton(
+                                        key: const Key('path-mapping-zoom-fit'),
+                                        controlSize: ControlSize.small,
+                                        secondary: true,
+                                        onPressed: mappingZoom == 1.0
+                                            ? null
+                                            : () => setState(
+                                                  () => mappingZoom = 1.0,
+                                                ),
+                                        child: const Text('Ajuster'),
+                                      ),
+                                      const Spacer(),
                                       Text(
-                                        _pathVariantUsageDescription(
-                                          selectedVariant,
+                                        '${(mappingZoom * 100).round()}%',
+                                        key: const Key(
+                                          'path-mapping-zoom-label',
                                         ),
                                         style: TextStyle(
-                                          fontSize: 10,
+                                          fontSize: 11,
                                           color: CupertinoColors.secondaryLabel
                                               .resolveFrom(ctx),
+                                          fontWeight: FontWeight.w700,
                                         ),
                                       ),
                                     ],
                                   ),
-                                ),
-                                const SizedBox(height: 10),
-                                _PathVariantFramesEditor(
-                                  image: image,
-                                  sourceTileWidth: sourceTileWidth,
-                                  sourceTileHeight: sourceTileHeight,
-                                  frames: mappings[selectedVariant] ??
-                                      const <TilesetVisualFrame>[],
-                                  onChanged: (next) {
-                                    setState(() {
-                                      if (next.isEmpty) {
-                                        mappings.remove(selectedVariant);
-                                      } else {
-                                        mappings[selectedVariant] = next;
-                                      }
-                                    });
-                                  },
-                                  onPickFrame: (initial) async {
-                                    final picked =
-                                        await _showTilesetRectPickerDialog(
-                                      context,
-                                      notifier: notifier,
-                                      settings: settings,
-                                      tilesetId: normalizedTilesetId,
-                                      initial: initial,
-                                      title: 'Pick path frame source',
-                                    );
-                                    if (picked == null) {
-                                      return null;
-                                    }
-                                    return TilesetSourceRect(
-                                      x: picked.x,
-                                      y: picked.y,
-                                      width: 1,
-                                      height: 1,
-                                    );
-                                  },
-                                ),
-                                const SizedBox(height: 10),
-                                Expanded(
-                                  child: Center(
+                                  const SizedBox(height: 8),
+                                  Expanded(
                                     child: LayoutBuilder(
                                       builder: (context, constraints) {
-                                        final scale = math.min(
-                                          constraints.maxWidth / image.width,
-                                          constraints.maxHeight / image.height,
+                                        final fitScale = math.min(
+                                          constraints.maxWidth /
+                                              displayedImage.width,
+                                          constraints.maxHeight /
+                                              displayedImage.height,
                                         );
-                                        final renderWidth = image.width * scale;
+                                        final scale = fitScale * mappingZoom;
+                                        final renderWidth =
+                                            displayedImage.width * scale;
                                         final renderHeight =
-                                            image.height * scale;
+                                            displayedImage.height * scale;
                                         final cellWidth = renderWidth / columns;
                                         final cellHeight = renderHeight / rows;
 
@@ -1500,7 +1704,7 @@ Future<Map<TerrainPathVariant, List<TilesetVisualFrame>>?>
                                           });
                                         }
 
-                                        return SizedBox(
+                                        final canvas = SizedBox(
                                           width: renderWidth,
                                           height: renderHeight,
                                           child: GestureDetector(
@@ -1515,7 +1719,7 @@ Future<Map<TerrainPathVariant, List<TilesetVisualFrame>>?>
                                             child: CustomPaint(
                                               painter:
                                                   _PathTilesetMappingPainter(
-                                                image: image,
+                                                image: displayedImage,
                                                 columns: columns,
                                                 rows: rows,
                                                 mappings: mappings,
@@ -1526,66 +1730,76 @@ Future<Map<TerrainPathVariant, List<TilesetVisualFrame>>?>
                                             ),
                                           ),
                                         );
+                                        return SingleChildScrollView(
+                                          primary: false,
+                                          child: SingleChildScrollView(
+                                            primary: false,
+                                            scrollDirection: Axis.horizontal,
+                                            child: canvas,
+                                          ),
+                                        );
                                       },
                                     ),
                                   ),
-                                ),
-                              ],
+                                ],
+                              ),
                             ),
                           ),
+                        ],
+                      ),
+                    ),
+                    const SizedBox(height: 12),
+                    Row(
+                      mainAxisAlignment: MainAxisAlignment.end,
+                      children: [
+                        PushButton(
+                          controlSize: ControlSize.large,
+                          secondary: true,
+                          onPressed: () => Navigator.pop(ctx),
+                          child: const Text('Cancel'),
+                        ),
+                        const SizedBox(width: 8),
+                        PushButton(
+                          controlSize: ControlSize.large,
+                          secondary: true,
+                          onPressed: mappings.containsKey(selectedVariant)
+                              ? () => setState(
+                                    () => mappings.remove(selectedVariant),
+                                  )
+                              : null,
+                          child: const Text('Clear Variant'),
+                        ),
+                        const SizedBox(width: 8),
+                        PushButton(
+                          controlSize: ControlSize.large,
+                          onPressed: () {
+                            result = _completePathMappings(
+                              <TerrainPathVariant, List<TilesetVisualFrame>>{
+                                for (final entry in mappings.entries)
+                                  if (entry.value.isNotEmpty)
+                                    entry.key: List<TilesetVisualFrame>.from(
+                                      entry.value,
+                                      growable: false,
+                                    ),
+                              },
+                            );
+                            Navigator.pop(ctx);
+                          },
+                          child: const Text('Apply'),
                         ),
                       ],
                     ),
-                  ),
-                  const SizedBox(height: 12),
-                  Row(
-                    mainAxisAlignment: MainAxisAlignment.end,
-                    children: [
-                      PushButton(
-                        controlSize: ControlSize.large,
-                        secondary: true,
-                        onPressed: () => Navigator.pop(ctx),
-                        child: const Text('Cancel'),
-                      ),
-                      const SizedBox(width: 8),
-                      PushButton(
-                        controlSize: ControlSize.large,
-                        secondary: true,
-                        onPressed: mappings.containsKey(selectedVariant)
-                            ? () => setState(
-                                  () => mappings.remove(selectedVariant),
-                                )
-                            : null,
-                        child: const Text('Clear Variant'),
-                      ),
-                      const SizedBox(width: 8),
-                      PushButton(
-                        controlSize: ControlSize.large,
-                        onPressed: () {
-                          result = _completePathMappings(
-                            <TerrainPathVariant, List<TilesetVisualFrame>>{
-                              for (final entry in mappings.entries)
-                                if (entry.value.isNotEmpty)
-                                  entry.key: List<TilesetVisualFrame>.from(
-                                    entry.value,
-                                    growable: false,
-                                  ),
-                            },
-                          );
-                          Navigator.pop(ctx);
-                        },
-                        child: const Text('Apply'),
-                      ),
-                    ],
-                  ),
-                ],
+                  ],
+                ),
               ),
             ),
           ),
         ),
       ),
-    ),
-  );
+    );
+  } finally {
+    alphaPreviewController.dispose();
+  }
 
   return result;
 }
@@ -1848,7 +2062,9 @@ Widget _buildPresetDetailsContent({
   required ProjectSettings settings,
   required List<ProjectTilesetEntry> tilesets,
 }) {
-  final color = kind == PresetLibraryKind.terrain ? EditorChrome.accentJade : EditorChrome.accentWarm;
+  final color = kind == PresetLibraryKind.terrain
+      ? EditorChrome.accentJade
+      : EditorChrome.accentWarm;
   return _PresetDetailsCard(
     kind: kind,
     preset: preset,
diff --git a/packages/map_editor/lib/src/ui/panels/terrain_editor/widgets/terrain_mapping_workspace.dart b/packages/map_editor/lib/src/ui/panels/terrain_editor/widgets/terrain_mapping_workspace.dart
index b8d67dcc..04cdbfd6 100644
--- a/packages/map_editor/lib/src/ui/panels/terrain_editor/widgets/terrain_mapping_workspace.dart
+++ b/packages/map_editor/lib/src/ui/panels/terrain_editor/widgets/terrain_mapping_workspace.dart
@@ -1242,10 +1242,24 @@ class _TilesetRectSelectionPainter extends CustomPainter {
   }
 }
 
+class _TerrainTilesetImageAsset {
+  const _TerrainTilesetImageAsset({
+    required this.bytes,
+    required this.image,
+  });
+
+  final Uint8List bytes;
+  final ui.Image image;
+}
+
 class _TerrainTilesetImageCache {
-  static final Map<String, Future<ui.Image?>> _cache = {};
+  static final Map<String, Future<_TerrainTilesetImageAsset?>> _cache = {};
 
-  static Future<ui.Image?> load(String? path) {
+  static Future<ui.Image?> load(String? path) async {
+    return (await loadAsset(path))?.image;
+  }
+
+  static Future<_TerrainTilesetImageAsset?> loadAsset(String? path) {
     if (path == null || path.isEmpty) {
       return Future.value(null);
     }
@@ -1259,12 +1273,24 @@ class _TerrainTilesetImageCache {
         if (bytes.isEmpty) {
           return null;
         }
-        final codec = await ui.instantiateImageCodec(bytes);
-        final frame = await codec.getNextFrame();
-        return frame.image;
+        final image = await decodeBytes(bytes);
+        if (image == null) {
+          return null;
+        }
+        return _TerrainTilesetImageAsset(bytes: bytes, image: image);
       } catch (_) {
         return null;
       }
     });
   }
+
+  static Future<ui.Image?> decodeBytes(Uint8List bytes) async {
+    try {
+      final codec = await ui.instantiateImageCodec(bytes);
+      final frame = await codec.getNextFrame();
+      return frame.image;
+    } catch (_) {
+      return null;
+    }
+  }
 }
diff --git a/packages/map_editor/lib/src/ui/panels/terrain_editor_panel.dart b/packages/map_editor/lib/src/ui/panels/terrain_editor_panel.dart
index d872fe87..c87159ba 100644
--- a/packages/map_editor/lib/src/ui/panels/terrain_editor_panel.dart
+++ b/packages/map_editor/lib/src/ui/panels/terrain_editor_panel.dart
@@ -13,6 +13,7 @@ import 'package:map_editor/src/ui/shared/editor_paint_palette.dart';
 
 import '../../features/editor/state/editor_notifier.dart';
 import '../../features/editor/state/editor_selectors.dart';
+import 'terrain_editor/path_mapping_editor_helpers.dart';
 
 part 'terrain_editor/dialogs/terrain_preset_dialogs.dart';
 part 'terrain_editor/widgets/terrain_mapping_workspace.dart';
diff --git a/packages/map_editor/test/path_pattern/path_studio_panel_test.dart b/packages/map_editor/test/path_pattern/path_studio_panel_test.dart
index 3511aa41..1395a5aa 100644
--- a/packages/map_editor/test/path_pattern/path_studio_panel_test.dart
+++ b/packages/map_editor/test/path_pattern/path_studio_panel_test.dart
@@ -1,8 +1,13 @@
+import 'dart:io';
+import 'dart:typed_data';
+import 'dart:ui' as ui;
+
 import 'package:flutter/cupertino.dart';
 import 'package:flutter_test/flutter_test.dart';
 import 'package:macos_ui/macos_ui.dart';
 import 'package:map_core/map_core.dart';
 import 'package:map_editor/src/features/path_studio/path_studio_panel.dart';
+import 'package:path/path.dart' as p;
 
 void main() {
   group('PathStudioPanel', () {
@@ -118,7 +123,7 @@ void main() {
       expect(find.text('lot futur'), findsWidgets);
 
       await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
-      await tester.pumpAndSettle();
+      await _pumpPathStudioAsync(tester);
 
       expect(find.text('Brouillon nouveau chemin'), findsWidgets);
       expect(find.text('Brouillon non sauvegardé'), findsWidgets);
@@ -147,7 +152,7 @@ void main() {
       );
 
       await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
-      await tester.pumpAndSettle();
+      await _pumpPathStudioAsync(tester);
 
       expect(find.text('Propriétés du nouveau chemin'), findsOneWidget);
       expect(find.text('mountain rock'), findsNothing);
@@ -170,7 +175,7 @@ void main() {
       );
 
       await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
-      await tester.pumpAndSettle();
+      await _pumpPathStudioAsync(tester);
 
       expect(find.text('Tileset'), findsWidgets);
       expect(find.text('À choisir'), findsWidgets);
@@ -199,7 +204,7 @@ void main() {
       );
 
       await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
-      await tester.pumpAndSettle();
+      await _pumpPathStudioAsync(tester);
 
       expect(find.text('Brouillon nouveau chemin'), findsWidgets);
       expect(
@@ -218,14 +223,14 @@ void main() {
       );
 
       await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
-      await tester.pumpAndSettle();
+      await _pumpPathStudioAsync(tester);
       tester
           .widget<MacosPopupButton<String>>(
             find.byKey(const Key('path-studio-new-path-tileset-popup')),
           )
           .onChanged
           ?.call('tileset-main');
-      await tester.pumpAndSettle();
+      await _pumpPathStudioAsync(tester);
 
       final tile = find.byKey(const Key('path-studio-new-path-tile-2-1'));
       await tester.ensureVisible(tile);
@@ -239,6 +244,203 @@ void main() {
       expect(find.text('Tileset à choisir'), findsNothing);
     });
 
+    testWidgets('missing tileset image keeps the logical picker fallback',
+        (tester) async {
+      final temp = (await tester.runAsync(
+        () => Directory.systemTemp.createTemp('path_studio_missing_'),
+      ))!;
+      addTearDown(() => temp.delete(recursive: true));
+      await _pumpPathStudio(
+        tester,
+        manifest: _manifest(
+          tilesets: [_tileset(id: 'tileset-main', name: 'Chemins principaux')],
+        ),
+        projectRootPath: temp.path,
+      );
+
+      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
+      await _pumpPathStudioAsync(tester);
+      tester
+          .widget<MacosPopupButton<String>>(
+            find.byKey(const Key('path-studio-new-path-tileset-popup')),
+          )
+          .onChanged
+          ?.call('tileset-main');
+      await _pumpPathStudioAsync(tester);
+
+      expect(find.text('Image du tileset introuvable'), findsWidgets);
+      expect(find.byKey(const Key('path-studio-new-path-tile-2-1')),
+          findsOneWidget);
+
+      await _tapNewPathTile(tester, tileX: 2, tileY: 1);
+
+      expect(find.text('Tuile 2,1'), findsWidgets);
+      expect(find.text('Cellules à configurer'), findsNothing);
+    });
+
+    testWidgets('image-backed tileset picker assigns the active cell',
+        (tester) async {
+      final temp = (await tester.runAsync(
+        () => Directory.systemTemp.createTemp('path_studio_image_'),
+      ))!;
+      addTearDown(() => temp.delete(recursive: true));
+      final imageFile = File(p.join(temp.path, 'tilesets/tileset-main.png'));
+      await tester.runAsync(() async {
+        await imageFile.parent.create(recursive: true);
+        await imageFile.writeAsBytes(await _pngBytes(width: 64, height: 32));
+      });
+
+      await _pumpPathStudio(
+        tester,
+        manifest: _manifest(
+          settings: const ProjectSettings(tileWidth: 16, tileHeight: 16),
+          tilesets: [_tileset(id: 'tileset-main', name: 'Chemins principaux')],
+        ),
+        projectRootPath: temp.path,
+      );
+
+      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
+      await _pumpPathStudioAsync(tester);
+      tester
+          .widget<MacosPopupButton<String>>(
+            find.byKey(const Key('path-studio-new-path-tileset-popup')),
+          )
+          .onChanged
+          ?.call('tileset-main');
+      await _pumpPathStudioAsync(tester);
+
+      expect(find.byKey(const Key('path-studio-image-backed-tileset-picker')),
+          findsOneWidget);
+      expect(find.text('Image du tileset chargée'), findsWidgets);
+      expect(find.text('Grille 4×2'), findsWidgets);
+      expect(find.byKey(const Key('path-studio-tileset-zoom-out')),
+          findsOneWidget);
+      expect(
+          find.byKey(const Key('path-studio-tileset-zoom-in')), findsOneWidget);
+      expect(find.byKey(const Key('path-studio-tileset-zoom-reset')),
+          findsOneWidget);
+      expect(find.byKey(const Key('path-studio-tileset-zoom-fit')),
+          findsOneWidget);
+
+      final zoomIn = find.byKey(const Key('path-studio-tileset-zoom-in'));
+      await tester.ensureVisible(zoomIn);
+      await _pumpPathStudioAsync(tester);
+      await tester.tap(zoomIn);
+      await _pumpPathStudioAsync(tester);
+      expect(find.text('125%'), findsOneWidget);
+      await tester.tap(find.byKey(const Key('path-studio-tileset-zoom-out')));
+      await _pumpPathStudioAsync(tester);
+      _expectPathStudioZoomLabel(tester, '100%');
+      await tester.tap(zoomIn);
+      await _pumpPathStudioAsync(tester);
+      await tester.tap(find.byKey(const Key('path-studio-tileset-zoom-reset')));
+      await _pumpPathStudioAsync(tester);
+      _expectPathStudioZoomLabel(tester, '100%');
+      await tester.tap(zoomIn);
+      await _pumpPathStudioAsync(tester);
+      await tester.tap(find.byKey(const Key('path-studio-tileset-zoom-fit')));
+      await _pumpPathStudioAsync(tester);
+      _expectPathStudioZoomLabel(tester, '100%');
+      await tester.tap(zoomIn);
+      await _pumpPathStudioAsync(tester);
+
+      await _tapImageBackedTile(tester,
+          tileX: 2, tileY: 1, columns: 4, rows: 2);
+
+      expect(find.text('Tuile 2,1'), findsWidgets);
+      expect(find.text('Cellules à configurer'), findsNothing);
+    });
+
+    testWidgets('image-backed picker fills all 2x2 cells and supports clear',
+        (tester) async {
+      final temp = (await tester.runAsync(
+        () => Directory.systemTemp.createTemp('path_studio_2x2_'),
+      ))!;
+      addTearDown(() => temp.delete(recursive: true));
+      final imageFile = File(p.join(temp.path, 'tilesets/tileset-main.png'));
+      await tester.runAsync(() async {
+        await imageFile.parent.create(recursive: true);
+        await imageFile.writeAsBytes(await _pngBytes(width: 64, height: 32));
+      });
+
+      await _pumpPathStudio(
+        tester,
+        manifest: _manifest(
+          settings: const ProjectSettings(tileWidth: 16, tileHeight: 16),
+          tilesets: [_tileset(id: 'tileset-main', name: 'Chemins principaux')],
+        ),
+        projectRootPath: temp.path,
+      );
+
+      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
+      await _pumpPathStudioAsync(tester);
+      tester
+          .widget<MacosPopupButton<String>>(
+            find.byKey(const Key('path-studio-new-path-tileset-popup')),
+          )
+          .onChanged
+          ?.call('tileset-main');
+      await _pumpPathStudioAsync(tester);
+      await tester.tap(
+        find.byKey(const Key('path-studio-new-path-size-2x2')),
+      );
+      await tester.pumpAndSettle();
+
+      await _assignImageBackedTile(
+        tester,
+        cellX: 0,
+        cellY: 0,
+        tileX: 0,
+        tileY: 0,
+        columns: 4,
+        rows: 2,
+      );
+      await _assignImageBackedTile(
+        tester,
+        cellX: 1,
+        cellY: 0,
+        tileX: 1,
+        tileY: 0,
+        columns: 4,
+        rows: 2,
+      );
+      await _assignImageBackedTile(
+        tester,
+        cellX: 0,
+        cellY: 1,
+        tileX: 2,
+        tileY: 0,
+        columns: 4,
+        rows: 2,
+      );
+
+      expect(find.text('Cellules à configurer'), findsWidgets);
+
+      await _assignImageBackedTile(
+        tester,
+        cellX: 1,
+        cellY: 1,
+        tileX: 3,
+        tileY: 0,
+        columns: 4,
+        rows: 2,
+      );
+
+      expect(find.text('Cellules à configurer'), findsNothing);
+      expect(find.text('Tuile 3,0'), findsWidgets);
+
+      final clearButton =
+          find.byKey(const Key('path-studio-new-path-clear-selected-cell'));
+      await tester.ensureVisible(clearButton);
+      await tester.pumpAndSettle();
+      await tester.tap(clearButton);
+      await tester.pumpAndSettle();
+
+      expect(find.text('Cellules à configurer'), findsWidgets);
+      expect(find.text('Aucune tuile configurée pour cette cellule.'),
+          findsWidgets);
+    });
+
     testWidgets('assigns independent tiles to all 2x2 center cells',
         (tester) async {
       await _pumpPathStudio(
@@ -520,6 +722,7 @@ void main() {
 Future<void> _pumpPathStudio(
   WidgetTester tester, {
   required ProjectManifest manifest,
+  String? projectRootPath,
 }) async {
   await tester.binding.setSurfaceSize(const Size(1440, 920));
   addTearDown(() => tester.binding.setSurfaceSize(null));
@@ -531,14 +734,76 @@ Future<void> _pumpPathStudio(
         children: [
           ContentArea(
             builder: (context, scrollController) {
-              return PathStudioPanel(manifest: manifest);
+              return PathStudioPanel(
+                manifest: manifest,
+                projectRootPath: projectRootPath,
+              );
             },
           ),
         ],
       ),
     ),
   );
-  await tester.pumpAndSettle();
+  await _pumpPathStudioAsync(tester);
+}
+
+Future<void> _pumpPathStudioAsync(WidgetTester tester) async {
+  await tester.pump();
+  await tester.pump(const Duration(milliseconds: 250));
+  await tester.pump(const Duration(milliseconds: 250));
+}
+
+void _expectPathStudioZoomLabel(WidgetTester tester, String value) {
+  final label = tester.widget<Text>(
+    find.byKey(const Key('path-studio-tileset-zoom-label')),
+  );
+  expect(label.data, value);
+}
+
+Future<void> _assignImageBackedTile(
+  WidgetTester tester, {
+  required int cellX,
+  required int cellY,
+  required int tileX,
+  required int tileY,
+  required int columns,
+  required int rows,
+}) async {
+  final cell = find.byKey(Key('path-studio-new-path-cell-$cellX-$cellY'));
+  await tester.ensureVisible(cell);
+  await _pumpPathStudioAsync(tester);
+  await tester.tap(cell);
+  await _pumpPathStudioAsync(tester);
+  await _tapImageBackedTile(
+    tester,
+    tileX: tileX,
+    tileY: tileY,
+    columns: columns,
+    rows: rows,
+  );
+}
+
+Future<void> _tapImageBackedTile(
+  WidgetTester tester, {
+  required int tileX,
+  required int tileY,
+  required int columns,
+  required int rows,
+}) async {
+  final picker =
+      find.byKey(const Key('path-studio-image-backed-tileset-canvas'));
+  await tester.ensureVisible(picker);
+  await _pumpPathStudioAsync(tester);
+  final topLeft = tester.getTopLeft(picker);
+  final size = tester.getSize(picker);
+  await tester.tapAt(
+    topLeft +
+        Offset(
+          (tileX + 0.5) * size.width / columns,
+          (tileY + 0.5) * size.height / rows,
+        ),
+  );
+  await _pumpPathStudioAsync(tester);
 }
 
 Future<void> _assignNewPathTile(
@@ -550,9 +815,9 @@ Future<void> _assignNewPathTile(
 }) async {
   final cell = find.byKey(Key('path-studio-new-path-cell-$cellX-$cellY'));
   await tester.ensureVisible(cell);
-  await tester.pumpAndSettle();
+  await _pumpPathStudioAsync(tester);
   await tester.tap(cell);
-  await tester.pumpAndSettle();
+  await _pumpPathStudioAsync(tester);
   await _tapNewPathTile(tester, tileX: tileX, tileY: tileY);
 }
 
@@ -563,18 +828,20 @@ Future<void> _tapNewPathTile(
 }) async {
   final tile = find.byKey(Key('path-studio-new-path-tile-$tileX-$tileY'));
   await tester.ensureVisible(tile);
-  await tester.pumpAndSettle();
+  await _pumpPathStudioAsync(tester);
   await tester.tap(tile);
-  await tester.pumpAndSettle();
+  await _pumpPathStudioAsync(tester);
 }
 
 ProjectManifest _manifest({
   List<ProjectPathPreset> pathPresets = const [],
   List<ProjectPathPatternPreset> pathPatternPresets = const [],
   List<ProjectTilesetEntry> tilesets = const [],
+  ProjectSettings settings = const ProjectSettings(),
 }) {
   return ProjectManifest(
     name: 'Project',
+    settings: settings,
     maps: const [],
     tilesets: tilesets,
     pathPresets: pathPresets,
@@ -583,6 +850,35 @@ ProjectManifest _manifest({
   );
 }
 
+Future<Uint8List> _pngBytes({
+  required int width,
+  required int height,
+}) async {
+  final recorder = ui.PictureRecorder();
+  final canvas = ui.Canvas(recorder);
+  final colors = [
+    const ui.Color(0xFFEBCB8B),
+    const ui.Color(0xFFA3BE8C),
+    const ui.Color(0xFF88C0D0),
+    const ui.Color(0xFFB48EAD),
+  ];
+  var colorIndex = 0;
+  for (var y = 0; y < height; y += 16) {
+    for (var x = 0; x < width; x += 16) {
+      final paint = ui.Paint()..color = colors[colorIndex % colors.length];
+      canvas.drawRect(
+        ui.Rect.fromLTWH(x.toDouble(), y.toDouble(), 16, 16),
+        paint,
+      );
+      colorIndex += 1;
+    }
+  }
+  final picture = recorder.endRecording();
+  final image = await picture.toImage(width, height);
+  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
+  return byteData!.buffer.asUint8List();
+}
+
 ProjectTilesetEntry _tileset({
   required String id,
   required String name,
```

#### flutter test path_mapping_editor_helpers_test

Commande :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor
flutter test test/path_pattern/path_mapping_editor_helpers_test.dart --reporter expanded
```

Code de sortie : `0`

Sortie :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_mapping_editor_helpers_test.dart
00:00 +0: path mapping editor helpers converts zoomed local positions to tile coordinates
00:00 +1: path mapping editor helpers clamps zoom controls to the supported range
00:00 +2: path mapping editor helpers keeps original bytes when alpha preview is disabled
00:00 +3: path mapping editor helpers applies alpha preview for a valid RGB hex color
00:00 +4: path mapping editor helpers reports invalid alpha preview hex without modifying bytes
00:00 +5: path mapping editor helpers alpha preview never writes back to the source image file
00:00 +6: All tests passed!
```

#### flutter test path_studio_tileset_image_picker_test

Commande :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor
flutter test test/path_pattern/path_studio_tileset_image_picker_test.dart --reporter expanded
```

Code de sortie : `0`

Sortie :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_tileset_image_picker_test.dart
00:00 +0: PathStudioTilesetImagePicker image support resolves an image from project root and tileset relativePath
00:00 +1: PathStudioTilesetImagePicker image support returns a fallback status when the image file is absent
00:00 +2: PathStudioTilesetImagePicker image support converts a local click position to tile coordinates
00:00 +3: PathStudioTilesetImagePicker image support converts a zoomed local click position to tile coordinates
00:00 +4: All tests passed!
```

#### flutter test path_studio_panel_test

Commande :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor
flutter test test/path_pattern/path_studio_panel_test.dart --reporter expanded
```

Code de sortie : `0`

Sortie :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart
00:00 +0: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:00 +1: PathStudioPanel lists presets and updates summary and inspector selection
00:01 +2: PathStudioPanel filters presets locally and clears selection on no result
00:01 +3: PathStudioPanel creates a new path draft without legacy base presets
00:01 +4: PathStudioPanel new path draft does not force existing legacy path choices
00:02 +5: PathStudioPanel new path draft can select a project tileset
00:02 +6: PathStudioPanel new path draft stays usable when the project has no tileset
00:02 +7: PathStudioPanel assigns a tileset tile to the 1x1 active cell
00:02 +8: PathStudioPanel missing tileset image keeps the logical picker fallback
00:03 +9: PathStudioPanel image-backed tileset picker assigns the active cell
00:03 +10: PathStudioPanel image-backed picker fills all 2x2 cells and supports clear
00:04 +11: PathStudioPanel assigns independent tiles to all 2x2 center cells
00:04 +12: PathStudioPanel replaces and clears the active cell tile
00:04 +13: PathStudioPanel changing tileset clears configured center cells
00:04 +14: PathStudioPanel resizes the new path draft to 2x2 and selects a cell
00:04 +15: PathStudioPanel edits new path draft name and keeps save disabled
00:05 +16: PathStudioPanel secondary legacy flow changes inherited structure locally
00:05 +17: PathStudioPanel empty new path name shows a local diagnostic
00:05 +18: PathStudioPanel secondary legacy flow reports missing existing paths
00:05 +19: All tests passed!
```

#### flutter test test/path_pattern/

Commande :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor
flutter test test/path_pattern/ --reporter expanded
```

Code de sortie : `0`

Sortie :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_editor_read_model_test.dart
00:00 +0: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_editor_read_model_test.dart: createPathPatternEditorReadModel empty manifest exposes an empty summary and no cards
00:00 +1: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_editor_read_model_test.dart: createPathPatternEditorReadModel ready 1x1 preset exposes list card details
00:00 +2: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_editor_read_model_test.dart: createPathPatternEditorReadModel ready 2x2 transparent animated preset exposes counts
00:00 +3: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_editor_read_model_test.dart: createPathPatternEditorReadModel missing basePathPresetId blocks the card
00:00 +4: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_editor_read_model_test.dart: createPathPatternEditorReadModel duplicate PathPattern ids block every affected card
00:00 +5: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_editor_read_model_test.dart: createPathPatternEditorReadModel duplicate legacy base path preset ids block referencing cards
00:00 +6: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_editor_read_model_test.dart: createPathPatternEditorReadModel preserves manifest pathPatternPresets order
00:00 +7: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_editor_read_model_test.dart: createPathPatternEditorReadModel matches basePathPresetId exactly without trimming
00:00 +8: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_editor_read_model_test.dart: createPathPatternEditorReadModel ids that differ only by spaces are distinct exact ids
00:00 +9: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_editor_read_model_test.dart: createPathPatternEditorReadModel summary counts ready, blocked, duplicates, and multi-cell presets
00:00 +10: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_editor_read_model_test.dart: createPathPatternEditorReadModel read model and card lists are immutable defensive copies
00:00 +11: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_editor_read_model_test.dart: createPathPatternEditorReadModel read model, summary, and card use value equality
00:00 +12: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_mapping_editor_helpers_test.dart: path mapping editor helpers converts zoomed local positions to tile coordinates
00:00 +13: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_mapping_editor_helpers_test.dart: path mapping editor helpers clamps zoom controls to the supported range
00:00 +14: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_mapping_editor_helpers_test.dart: path mapping editor helpers keeps original bytes when alpha preview is disabled
00:00 +15: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_mapping_editor_helpers_test.dart: path mapping editor helpers applies alpha preview for a valid RGB hex color
00:00 +16: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_mapping_editor_helpers_test.dart: path mapping editor helpers reports invalid alpha preview hex without modifying bytes
00:00 +17: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_mapping_editor_helpers_test.dart: path mapping editor helpers alpha preview never writes back to the source image file
00:00 +18: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_center_pattern_static_preview_renderer_test.dart: renderPathCenterPatternStaticPreviewPng renders a 1x1 preview from the first frame source tile
00:00 +19: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_center_pattern_static_preview_renderer_test.dart: renderPathCenterPatternStaticPreviewPng renders a 2x2 preview in local cell positions
00:00 +20: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_center_pattern_static_preview_renderer_test.dart: renderPathCenterPatternStaticPreviewPng applies optional transparentColor before composing preview
00:00 +21: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_center_pattern_static_preview_renderer_test.dart: renderPathCenterPatternStaticPreviewPng keeps transparent-color-looking pixels opaque when color is null
00:00 +22: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_center_pattern_static_preview_renderer_test.dart: renderPathCenterPatternStaticPreviewPng rejects source rects outside the tileset image
00:00 +23: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_center_pattern_static_preview_renderer_test.dart: renderPathCenterPatternStaticPreviewPng rejects non-1x1 source rects in V0
00:00 +24: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_center_pattern_static_preview_renderer_test.dart: renderPathCenterPatternStaticPreviewPng rejects invalid PNG bytes
00:00 +25: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_center_pattern_static_preview_renderer_test.dart: renderPathCenterPatternStaticPreviewPng rejects non-positive tile dimensions
00:00 +26: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_tileset_image_picker_test.dart: PathStudioTilesetImagePicker image support resolves an image from project root and tileset relativePath
00:00 +27: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_tileset_image_picker_test.dart: PathStudioTilesetImagePicker image support returns a fallback status when the image file is absent
00:00 +28: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_tileset_image_picker_test.dart: PathStudioTilesetImagePicker image support converts a local click position to tile coordinates
00:00 +29: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_tileset_image_picker_test.dart: PathStudioTilesetImagePicker image support converts a zoomed local click position to tile coordinates
00:00 +30: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:00 +31: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel lists presets and updates summary and inspector selection
00:00 +32: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel lists presets and updates summary and inspector selection
00:01 +33: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel lists presets and updates summary and inspector selection
00:01 +34: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel lists presets and updates summary and inspector selection
00:01 +35: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel lists presets and updates summary and inspector selection
00:01 +36: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel lists presets and updates summary and inspector selection
00:01 +37: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel lists presets and updates summary and inspector selection
00:01 +38: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel lists presets and updates summary and inspector selection
00:01 +39: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel lists presets and updates summary and inspector selection
00:01 +40: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel lists presets and updates summary and inspector selection
00:01 +41: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel lists presets and updates summary and inspector selection
00:01 +42: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel lists presets and updates summary and inspector selection
00:01 +43: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel lists presets and updates summary and inspector selection
00:01 +44: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_new_path_draft_test.dart: PathStudioNewPathDraft creates an initial draft without a legacy ProjectPathPreset
00:01 +45: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel filters presets locally and clears selection on no result
00:01 +46: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel filters presets locally and clears selection on no result
00:01 +47: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel filters presets locally and clears selection on no result
00:01 +48: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel filters presets locally and clears selection on no result
00:01 +49: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel filters presets locally and clears selection on no result
00:01 +50: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel filters presets locally and clears selection on no result
00:01 +51: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel filters presets locally and clears selection on no result
00:01 +52: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel filters presets locally and clears selection on no result
00:01 +53: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel filters presets locally and clears selection on no result
00:01 +54: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel filters presets locally and clears selection on no result
00:01 +55: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel filters presets locally and clears selection on no result
00:01 +56: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel filters presets locally and clears selection on no result
00:01 +57: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel filters presets locally and clears selection on no result
00:01 +58: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel filters presets locally and clears selection on no result
00:01 +59: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel filters presets locally and clears selection on no result
00:01 +60: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel filters presets locally and clears selection on no result
00:01 +61: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel filters presets locally and clears selection on no result
00:01 +62: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel filters presets locally and clears selection on no result
00:01 +63: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel filters presets locally and clears selection on no result
00:01 +64: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel filters presets locally and clears selection on no result
00:01 +65: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel filters presets locally and clears selection on no result
00:01 +66: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel filters presets locally and clears selection on no result
00:01 +67: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel filters presets locally and clears selection on no result
00:01 +68: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel creates a new path draft without legacy base presets
00:01 +69: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel new path draft does not force existing legacy path choices
00:01 +70: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel new path draft can select a project tileset
00:01 +71: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel new path draft stays usable when the project has no tileset
00:01 +72: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel assigns a tileset tile to the 1x1 active cell
00:02 +73: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel missing tileset image keeps the logical picker fallback
00:02 +74: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel image-backed tileset picker assigns the active cell
00:03 +75: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel image-backed picker fills all 2x2 cells and supports clear
00:03 +76: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel assigns independent tiles to all 2x2 center cells
00:04 +77: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel replaces and clears the active cell tile
00:04 +78: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel changing tileset clears configured center cells
00:05 +79: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel resizes the new path draft to 2x2 and selects a cell
00:05 +80: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel edits new path draft name and keeps save disabled
00:05 +81: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel secondary legacy flow changes inherited structure locally
00:05 +82: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel empty new path name shows a local diagnostic
00:05 +83: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel secondary legacy flow reports missing existing paths
00:06 +84: All tests passed!
```

#### flutter test editor_shell_page_smoke_test

Commande :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor
flutter test test/editor_shell_page_smoke_test.dart --reporter expanded
```

Code de sortie : `0`

Sortie :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_shell_page_smoke_test.dart
00:00 +0: EditorShellPage smoke renders map workspace chrome and toggles the right panel
Warning: Falling back on slow accent color resolution. It’s possible that the accent colors have changed in a recent version of macOS, thus invalidating macos_ui’s accent colors, which were captured on macOS Ventura. If you see this message, please notify a maintainer of the macos_ui package.
00:00 +1: EditorShellPage smoke updates the workspace header for tileset mode
00:01 +2: EditorShellPage smoke renders the trainer studio workspace chrome
FileProjectRepository: Loading project from /tmp/editor_shell_trainer/project.json
00:01 +3: EditorShellPage smoke renders the Pokémon catalogs workspace shell
00:01 +4: EditorShellPage smoke renders the Items catalogs workspace shell
00:01 +5: EditorShellPage smoke opens Path Studio from the project explorer
00:01 +6: EditorShellPage smoke renders shell chrome with an error state already present
00:02 +7: All tests passed!
```

#### flutter test top_toolbar_test

Commande :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor
flutter test test/top_toolbar_test.dart --reporter expanded
```

Code de sortie : `0`

Sortie :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/top_toolbar_test.dart
00:00 +0: TopToolbar shows the app brand and project workspace label
Warning: Falling back on slow accent color resolution. It’s possible that the accent colors have changed in a recent version of macOS, thus invalidating macos_ui’s accent colors, which were captured on macOS Ventura. If you see this message, please notify a maintainer of the macos_ui package.
00:00 +1: TopToolbar falls back to the workspace label when no project is loaded
00:01 +2: TopToolbar shows the toolbar status chip when a status is present
00:01 +3: TopToolbar shows the trainer studio label for the trainer workspace
00:01 +4: TopToolbar disables map save and history actions in Path Studio
00:01 +5: All tests passed!
```

#### flutter test editor_selectors_test

Commande :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor
flutter test test/editor_selectors_test.dart --reporter expanded
```

Code de sortie : `0`

Sortie :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_selectors_test.dart
00:00 +0: editor selectors editorShellSnapshotProvider derives map title and save affordance
00:00 +1: editor selectors editorToolbarSnapshotProvider resolves selected tileset from layer
00:00 +2: editor selectors Path Studio snapshots hide map save and history actions
00:00 +3: editor selectors editorProjectExplorerSnapshotProvider exposes active map selection
00:00 +4: editor selectors editorShellSnapshotProvider exposes trainer studio labels
00:00 +5: editor selectors editorShellSnapshotProvider exposes Pokémon catalogs labels
00:00 +6: editor selectors editorTerrainLibrarySnapshotProvider exposes preset selection inputs
00:00 +7: editor selectors editorTilesetPaletteSnapshotProvider exposes palette panel state
00:00 +8: All tests passed!
```

#### flutter analyze ciblé

Commande :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor
flutter analyze lib/src/features/path_studio lib/src/ui/panels/terrain_editor_panel.dart lib/src/ui/panels/terrain_editor test/path_pattern
```

Code de sortie : `0`

Sortie :

```text
Analyzing 4 items...                                            
No issues found! (ran in 2.5s)
```

#### dart test project_manifest_path_pattern_preset_operations_test

Commande :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_core
dart test test/project_manifest_path_pattern_preset_operations_test.dart --reporter expanded --no-color
```

Code de sortie : `0`

Sortie :

```text
00:00 +0: loading test/project_manifest_path_pattern_preset_operations_test.dart
00:00 +0: ProjectManifest PathPattern preset operations read returns the manifest pathPatternPresets in order
00:00 +1: ProjectManifest PathPattern preset operations replace swaps the list, preserves other fields, and keeps order
00:00 +2: ProjectManifest PathPattern preset operations replace accepts an empty list and rejects duplicate exact ids
00:00 +3: ProjectManifest PathPattern preset operations replace treats ids with different whitespace as distinct ids
00:00 +4: ProjectManifest PathPattern preset operations upsert appends a new preset at the end
00:00 +5: ProjectManifest PathPattern preset operations upsert replaces an existing preset in place
00:00 +6: ProjectManifest PathPattern preset operations upsert rejects ambiguous existing duplicate ids
00:00 +7: ProjectManifest PathPattern preset operations remove deletes an existing id and preserves order
00:00 +8: ProjectManifest PathPattern preset operations remove missing id is a no-op with an equivalent new manifest
00:00 +9: ProjectManifest PathPattern preset operations remove rejects blank ids and duplicate matching ids
00:00 +10: ProjectManifest PathPattern preset operations clear removes all path pattern presets without mutating original
00:00 +11: ProjectManifest PathPattern preset operations lookup helpers find exact ids, report missing ids, and reject blanks
00:00 +12: ProjectManifest PathPattern preset operations lookup helpers reject duplicate exact ids
00:00 +13: ProjectManifest PathPattern preset operations operations keep pathPatternPresets JSON stable
00:00 +14: All tests passed!
```

#### dart test project_manifest_path_pattern_presets_test

Commande :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_core
dart test test/project_manifest_path_pattern_presets_test.dart --reporter expanded --no-color
```

Code de sortie : `0`

Sortie :

```text
00:00 +0: loading test/project_manifest_path_pattern_presets_test.dart
00:00 +0: ProjectManifest pathPatternPresets decodes old manifests without pathPatternPresets as empty
00:00 +1: ProjectManifest pathPatternPresets decodes pathPatternPresets null as empty
00:00 +2: ProjectManifest pathPatternPresets decodes and encodes empty pathPatternPresets stably
00:00 +3: ProjectManifest pathPatternPresets decodes the Lot 9 minimal golden through ProjectManifest
00:00 +4: ProjectManifest pathPatternPresets decodes the Lot 9 complete golden through ProjectManifest
00:00 +5: ProjectManifest pathPatternPresets roundtrips manifest pathPatternPresets without changing order
00:00 +6: ProjectManifest pathPatternPresets does not migrate legacy pathPresets into pathPatternPresets
00:00 +7: ProjectManifest pathPatternPresets rejects invalid pathPatternPresets payloads
00:00 +8: All tests passed!
```

#### dart test project_path_pattern_preset_json_codec_test

Commande :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_core
dart test test/project_path_pattern_preset_json_codec_test.dart --reporter expanded --no-color
```

Code de sortie : `0`

Sortie :

```text
00:00 +0: loading test/project_path_pattern_preset_json_codec_test.dart
00:00 +0: ProjectPathPatternPreset JSON codec encodes a minimal preset
00:00 +1: ProjectPathPatternPreset JSON codec decodes a minimal preset
00:00 +2: ProjectPathPatternPreset JSON codec roundtrips a minimal preset
00:00 +3: ProjectPathPatternPreset JSON codec encodes a complete 2x2 preset in row-major cell order
00:00 +4: ProjectPathPatternPreset JSON codec roundtrips a complete 2x2 preset
00:00 +5: ProjectPathPatternPreset JSON codec canonicalizes transparentColor after decode and encode
00:00 +6: ProjectPathPatternPreset JSON codec roundtrips frame tileset overrides
00:00 +7: ProjectPathPatternPreset JSON codec roundtrips null and non-null frame durations
00:00 +8: ProjectPathPatternPreset JSON codec rejects invalid JSON
00:00 +9: All tests passed!
```

#### dart test project_path_pattern_preset_json_golden_test

Commande :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_core
dart test test/project_path_pattern_preset_json_golden_test.dart --reporter expanded --no-color
```

Code de sortie : `0`

Sortie :

```text
00:00 +0: loading test/project_path_pattern_preset_json_golden_test.dart
00:00 +0: ProjectPathPatternPreset JSON golden samples minimal 1x1 golden decodes to the expected preset
00:00 +1: ProjectPathPatternPreset JSON golden samples minimal 1x1 golden matches encode output
00:00 +2: ProjectPathPatternPreset JSON golden samples complete 2x2 golden decodes to the expected preset
00:00 +3: ProjectPathPatternPreset JSON golden samples complete 2x2 golden matches encode output
00:00 +4: ProjectPathPatternPreset JSON golden samples goldens roundtrip through decode and encode
00:00 +5: ProjectPathPatternPreset JSON golden samples goldens use two-space canonical formatting with final newline
00:00 +6: All tests passed!
```

#### dart test project_path_pattern_preset_test

Commande :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_core
dart test test/project_path_pattern_preset_test.dart --reporter expanded --no-color
```

Code de sortie : `0`

Sortie :

```text
00:00 +0: loading test/project_path_pattern_preset_test.dart
00:00 +0: ProjectPathPatternPreset creates a minimal preset with defaults
00:00 +1: ProjectPathPatternPreset creates a complete preset with a 2x2 center pattern
00:00 +2: ProjectPathPatternPreset rejects blank identity fields
00:00 +3: ProjectPathPatternPreset validates with trim but stores original strings
00:00 +4: ProjectPathPatternPreset supports value equality and stable hashCode
00:00 +5: All tests passed!
```

#### dart test path_center_pattern_test

Commande :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_core
dart test test/path_center_pattern_test.dart --reporter expanded --no-color
```

Code de sortie : `0`

Sortie :

```text
00:00 +0: loading test/path_center_pattern_test.dart
00:00 +0: PathCenterPatternSize accepts 1x1 and 2x2 sizes
00:00 +1: PathCenterPatternSize rejects non-positive dimensions
00:00 +2: PathCenterPatternSize reports tile count and coordinate containment
00:00 +3: PathCenterPatternSize uses value equality and stable hashCode
00:00 +4: PathCenterPatternCell accepts non-negative local coordinates and frames
00:00 +5: PathCenterPatternCell rejects negative coordinates and empty frames
00:00 +6: PathCenterPatternCell defensively copies frames and exposes an immutable list
00:00 +7: PathCenterPatternCell uses value equality and stable hashCode
00:00 +8: PathCenterPattern 1x1 accepts a complete single-cell grid
00:00 +9: PathCenterPattern 2x2 accepts a complete grid and exposes cells in row-major order
00:00 +10: PathCenterPattern 2x2 defensively copies cells and exposes an immutable list
00:00 +11: PathCenterPattern 2x2 uses value equality and stable hashCode
00:00 +12: PathCenterPattern invalid grids rejects an empty cell list
00:00 +13: PathCenterPattern invalid grids rejects a missing cell
00:00 +14: PathCenterPattern invalid grids rejects a cell outside the grid
00:00 +15: PathCenterPattern invalid grids rejects duplicate coordinates
00:00 +16: PathCenterPattern invalid grids cellAt rejects coordinates outside the grid
00:00 +17: All tests passed!
```

#### dart test path_center_pattern_resolver_test

Commande :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_core
dart test test/path_center_pattern_resolver_test.dart --reporter expanded --no-color
```

Code de sortie : `0`

Sortie :

```text
00:00 +0: loading test/path_center_pattern_resolver_test.dart
00:00 +0: resolvePathCenterPatternCell 1x1 always resolves to the single local cell
00:00 +1: resolvePathCenterPatternCell 2x2 uses absolute map coordinates modulo pattern size
00:00 +2: resolvePathCenterPatternCell rectangular 3x2 does not assume square patterns
00:00 +3: resolvePathCenterPatternCell invalid coordinates rejects negative map coordinates
00:00 +4: PathCenterPatternCellResolution keeps map coordinates, local coordinates, and selected cell
00:00 +5: PathCenterPatternCellResolution uses value equality and stable hashCode
00:00 +6: All tests passed!
```

### 17.3 Diff complet réel des fichiers suivis modifiés

```diff
diff --git a/packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart b/packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
index bad7b526..b783aa2d 100644
--- a/packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
+++ b/packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
@@ -8,6 +8,7 @@ import 'path_pattern_draft.dart';
 import 'path_pattern_editor_read_model.dart';
 import 'path_studio_new_path_draft.dart';
 import 'path_studio_theme.dart';
+import 'path_studio_tileset_image_picker.dart';
 
 /// Workspace branché au shell global de l'éditeur.
 ///
@@ -20,10 +21,14 @@ class PathStudioWorkspace extends ConsumerWidget {
   @override
   Widget build(BuildContext context, WidgetRef ref) {
     final manifest = ref.watch(editorProjectManifestProvider);
+    final projectRootPath = ref.watch(editorProjectRootPathProvider);
     if (manifest == null) {
       return const _PathStudioProjectMissingState();
     }
-    return PathStudioPanel(manifest: manifest);
+    return PathStudioPanel(
+      manifest: manifest,
+      projectRootPath: projectRootPath,
+    );
   }
 }
 
@@ -37,9 +42,11 @@ class PathStudioPanel extends StatefulWidget {
   const PathStudioPanel({
     super.key,
     required this.manifest,
+    this.projectRootPath,
   });
 
   final ProjectManifest manifest;
+  final String? projectRootPath;
 
   @override
   State<PathStudioPanel> createState() => _PathStudioPanelState();
@@ -150,6 +157,8 @@ class _PathStudioPanelState extends State<PathStudioPanel> {
                   Expanded(
                     child: _CenterWorkspace(
                       tilesets: widget.manifest.tilesets,
+                      settings: widget.manifest.settings,
+                      projectRootPath: widget.projectRootPath,
                       newPathDraft: selectedNewPathDraft,
                       draft: selectedDraft,
                       selected: selected?.card,
@@ -1255,6 +1264,8 @@ class _MiniMetric extends StatelessWidget {
 class _CenterWorkspace extends StatelessWidget {
   const _CenterWorkspace({
     required this.tilesets,
+    required this.settings,
+    required this.projectRootPath,
     required this.newPathDraft,
     required this.draft,
     required this.selected,
@@ -1268,6 +1279,8 @@ class _CenterWorkspace extends StatelessWidget {
   });
 
   final List<ProjectTilesetEntry> tilesets;
+  final ProjectSettings settings;
+  final String? projectRootPath;
   final PathStudioNewPathDraft? newPathDraft;
   final PathPatternDraft? draft;
   final PathPatternPresetCardModel? selected;
@@ -1285,6 +1298,8 @@ class _CenterWorkspace extends StatelessWidget {
     if (newPathDraft != null) {
       return _NewPathCenterWorkspace(
         tilesets: tilesets,
+        settings: settings,
+        projectRootPath: projectRootPath,
         draft: newPathDraft,
         onSizeChanged: onNewPathSizeChanged,
         onCellSelected: onNewPathCellSelected,
@@ -1325,6 +1340,8 @@ class _CenterWorkspace extends StatelessWidget {
 class _NewPathCenterWorkspace extends StatelessWidget {
   const _NewPathCenterWorkspace({
     required this.tilesets,
+    required this.settings,
+    required this.projectRootPath,
     required this.draft,
     required this.onSizeChanged,
     required this.onCellSelected,
@@ -1333,6 +1350,8 @@ class _NewPathCenterWorkspace extends StatelessWidget {
   });
 
   final List<ProjectTilesetEntry> tilesets;
+  final ProjectSettings settings;
+  final String? projectRootPath;
   final PathStudioNewPathDraft draft;
   final void Function(int width, int height) onSizeChanged;
   final void Function(int localX, int localY) onCellSelected;
@@ -1353,6 +1372,8 @@ class _NewPathCenterWorkspace extends StatelessWidget {
           const SizedBox(height: 14),
           _NewPathCenterPatternEditor(
             tilesets: tilesets,
+            settings: settings,
+            projectRootPath: projectRootPath,
             draft: draft,
             onSizeChanged: onSizeChanged,
             onCellSelected: onCellSelected,
@@ -1460,6 +1481,8 @@ class _NewPathSummary extends StatelessWidget {
 class _NewPathCenterPatternEditor extends StatelessWidget {
   const _NewPathCenterPatternEditor({
     required this.tilesets,
+    required this.settings,
+    required this.projectRootPath,
     required this.draft,
     required this.onSizeChanged,
     required this.onCellSelected,
@@ -1468,6 +1491,8 @@ class _NewPathCenterPatternEditor extends StatelessWidget {
   });
 
   final List<ProjectTilesetEntry> tilesets;
+  final ProjectSettings settings;
+  final String? projectRootPath;
   final PathStudioNewPathDraft draft;
   final void Function(int width, int height) onSizeChanged;
   final void Function(int localX, int localY) onCellSelected;
@@ -1516,6 +1541,9 @@ class _NewPathCenterPatternEditor extends StatelessWidget {
           ),
           const SizedBox(height: 18),
           _NewPathPatternGrid(
+            tilesets: tilesets,
+            settings: settings,
+            projectRootPath: projectRootPath,
             draft: draft,
             onCellSelected: onCellSelected,
           ),
@@ -1527,6 +1555,8 @@ class _NewPathCenterPatternEditor extends StatelessWidget {
           const SizedBox(height: 14),
           _NewPathTilePickerPanel(
             tilesets: tilesets,
+            settings: settings,
+            projectRootPath: projectRootPath,
             draft: draft,
             onTileSelected: onTileSelected,
           ),
@@ -1538,10 +1568,16 @@ class _NewPathCenterPatternEditor extends StatelessWidget {
 
 class _NewPathPatternGrid extends StatelessWidget {
   const _NewPathPatternGrid({
+    required this.tilesets,
+    required this.settings,
+    required this.projectRootPath,
     required this.draft,
     required this.onCellSelected,
   });
 
+  final List<ProjectTilesetEntry> tilesets;
+  final ProjectSettings settings;
+  final String? projectRootPath;
   final PathStudioNewPathDraft draft;
   final void Function(int localX, int localY) onCellSelected;
 
@@ -1557,6 +1593,9 @@ class _NewPathPatternGrid extends StatelessWidget {
         cells.add(
           _NewPathPatternCell(
             key: Key('path-studio-new-path-cell-$x-$y'),
+            tilesets: tilesets,
+            settings: settings,
+            projectRootPath: projectRootPath,
             cell: cell,
             selected: draft.selectedCellX == x && draft.selectedCellY == y,
             onTap: () => onCellSelected(x, y),
@@ -1579,11 +1618,17 @@ class _NewPathPatternGrid extends StatelessWidget {
 class _NewPathPatternCell extends StatelessWidget {
   const _NewPathPatternCell({
     super.key,
+    required this.tilesets,
+    required this.settings,
+    required this.projectRootPath,
     required this.cell,
     required this.selected,
     required this.onTap,
   });
 
+  final List<ProjectTilesetEntry> tilesets;
+  final ProjectSettings settings;
+  final String? projectRootPath;
   final PathStudioNewPathDraftCell cell;
   final bool selected;
   final VoidCallback onTap;
@@ -1625,7 +1670,12 @@ class _NewPathPatternCell extends StatelessWidget {
             ),
             const Spacer(),
             if (tile != null)
-              _TilePreviewBadge(tile: tile)
+              _TilePreviewBadge(
+                tilesets: tilesets,
+                settings: settings,
+                projectRootPath: projectRootPath,
+                tile: tile,
+              )
             else
               const _EmptyTileBadge(),
             const SizedBox(height: 6),
@@ -1732,13 +1782,21 @@ class _NewPathSelectedCellDetails extends StatelessWidget {
 }
 
 class _TilePreviewBadge extends StatelessWidget {
-  const _TilePreviewBadge({required this.tile});
+  const _TilePreviewBadge({
+    required this.tilesets,
+    required this.settings,
+    required this.projectRootPath,
+    required this.tile,
+  });
 
+  final List<ProjectTilesetEntry> tilesets;
+  final ProjectSettings settings;
+  final String? projectRootPath;
   final PathStudioNewPathDraftTile tile;
 
   @override
   Widget build(BuildContext context) {
-    return Container(
+    final fallback = Container(
       width: 46,
       height: 28,
       decoration: BoxDecoration(
@@ -1757,6 +1815,13 @@ class _TilePreviewBadge extends StatelessWidget {
         ),
       ),
     );
+    return PathStudioTileSpritePreview(
+      projectRootPath: projectRootPath,
+      tilesets: tilesets,
+      settings: settings,
+      tile: tile,
+      fallback: fallback,
+    );
   }
 }
 
@@ -1788,19 +1853,27 @@ class _EmptyTileBadge extends StatelessWidget {
 class _NewPathTilePickerPanel extends StatelessWidget {
   const _NewPathTilePickerPanel({
     required this.tilesets,
+    required this.settings,
+    required this.projectRootPath,
     required this.draft,
     required this.onTileSelected,
   });
 
   final List<ProjectTilesetEntry> tilesets;
+  final ProjectSettings settings;
+  final String? projectRootPath;
   final PathStudioNewPathDraft draft;
   final void Function(int sourceX, int sourceY) onTileSelected;
 
   @override
   Widget build(BuildContext context) {
+    final selectedTileset = _selectedTileset(
+      tilesets: tilesets,
+      tilesetId: draft.tilesetId,
+    );
     final tilesetLabel =
         _selectedTilesetLabel(tilesets: tilesets, tilesetId: draft.tilesetId);
-    if (tilesetLabel == null) {
+    if (tilesetLabel == null || selectedTileset == null) {
       return Container(
         padding: const EdgeInsets.all(14),
         decoration: PathStudioTheme.subtleDecoration(
@@ -1884,32 +1957,19 @@ class _NewPathTilePickerPanel extends StatelessWidget {
             ),
           ),
           const SizedBox(height: 12),
-          Wrap(
-            spacing: 8,
-            runSpacing: 8,
-            children: [
-              for (var y = 0; y < 4; y += 1)
-                for (var x = 0; x < 8; x += 1)
-                  _NewPathTileButton(
-                    key: Key('path-studio-new-path-tile-$x-$y'),
-                    sourceX: x,
-                    sourceY: y,
-                    selected: selectedCell.tile?.sourceX == x &&
-                        selectedCell.tile?.sourceY == y &&
-                        selectedCell.tile?.tilesetId == draft.tilesetId,
-                    onTap: () => onTileSelected(x, y),
-                  ),
-            ],
-          ),
-          const SizedBox(height: 10),
-          const Text(
-            'Grille logique V0 : les coordonnées sont enregistrées dans le brouillon, sans lecture de l’image tileset ni preview PNG.',
-            style: TextStyle(
-              color: PathStudioTheme.textMuted,
-              fontSize: 10.5,
-              height: 1.35,
-              fontWeight: FontWeight.w700,
-            ),
+          PathStudioImageBackedTilesetPicker(
+            projectRootPath: projectRootPath,
+            tileset: selectedTileset,
+            settings: settings,
+            activeCell: selectedCell,
+            onTileSelected: (source) => onTileSelected(source.x, source.y),
+            fallbackBuilder: (context, result) {
+              return _LogicalNewPathTileGrid(
+                draft: draft,
+                selectedCell: selectedCell,
+                onTileSelected: onTileSelected,
+              );
+            },
           ),
         ],
       ),
@@ -1917,6 +1977,54 @@ class _NewPathTilePickerPanel extends StatelessWidget {
   }
 }
 
+class _LogicalNewPathTileGrid extends StatelessWidget {
+  const _LogicalNewPathTileGrid({
+    required this.draft,
+    required this.selectedCell,
+    required this.onTileSelected,
+  });
+
+  final PathStudioNewPathDraft draft;
+  final PathStudioNewPathDraftCell selectedCell;
+  final void Function(int sourceX, int sourceY) onTileSelected;
+
+  @override
+  Widget build(BuildContext context) {
+    return Column(
+      crossAxisAlignment: CrossAxisAlignment.start,
+      children: [
+        Wrap(
+          spacing: 8,
+          runSpacing: 8,
+          children: [
+            for (var y = 0; y < 4; y += 1)
+              for (var x = 0; x < 8; x += 1)
+                _NewPathTileButton(
+                  key: Key('path-studio-new-path-tile-$x-$y'),
+                  sourceX: x,
+                  sourceY: y,
+                  selected: selectedCell.tile?.sourceX == x &&
+                      selectedCell.tile?.sourceY == y &&
+                      selectedCell.tile?.tilesetId == draft.tilesetId,
+                  onTap: () => onTileSelected(x, y),
+                ),
+          ],
+        ),
+        const SizedBox(height: 10),
+        const Text(
+          'Fallback V0 : les coordonnées sont enregistrées dans le brouillon quand l’image tileset ne peut pas être chargée.',
+          style: TextStyle(
+            color: PathStudioTheme.textMuted,
+            fontSize: 10.5,
+            height: 1.35,
+            fontWeight: FontWeight.w700,
+          ),
+        ),
+      ],
+    );
+  }
+}
+
 class _NewPathTileButton extends StatelessWidget {
   const _NewPathTileButton({
     super.key,
@@ -3524,6 +3632,21 @@ String? _selectedTilesetLabel({
   return tilesetId;
 }
 
+ProjectTilesetEntry? _selectedTileset({
+  required List<ProjectTilesetEntry> tilesets,
+  required String? tilesetId,
+}) {
+  if (tilesetId == null || tilesetId.isEmpty) {
+    return null;
+  }
+  for (final tileset in tilesets) {
+    if (tileset.id == tilesetId) {
+      return tileset;
+    }
+  }
+  return null;
+}
+
 String _newPathDraftIssueLabel(PathStudioNewPathDraftIssueCode issue) {
   return switch (issue) {
     PathStudioNewPathDraftIssueCode.nameRequired => 'Nom requis',
diff --git a/packages/map_editor/lib/src/ui/panels/terrain_editor/dialogs/terrain_preset_dialogs.dart b/packages/map_editor/lib/src/ui/panels/terrain_editor/dialogs/terrain_preset_dialogs.dart
index 67f635ea..4eccc7a1 100644
--- a/packages/map_editor/lib/src/ui/panels/terrain_editor/dialogs/terrain_preset_dialogs.dart
+++ b/packages/map_editor/lib/src/ui/panels/terrain_editor/dialogs/terrain_preset_dialogs.dart
@@ -1003,10 +1003,11 @@ Future<TilesetSourceRect?> _showTilesetRectPickerDialog(
   if (path == null) {
     return null;
   }
-  final image = await _TerrainTilesetImageCache.load(path);
-  if (image == null) {
+  final imageAsset = await _TerrainTilesetImageCache.loadAsset(path);
+  if (imageAsset == null) {
     return null;
   }
+  final image = imageAsset.image;
   if (settings.tileWidth <= 0 || settings.tileHeight <= 0) {
     return null;
   }
@@ -1167,13 +1168,12 @@ GridPos _gridFromPickerLocal(
   int columns,
   int rows,
 ) {
-  final maxX = math.max(0.0, columns * cellWidth - 0.000001);
-  final maxY = math.max(0.0, rows * cellHeight - 0.000001);
-  final dx = localPosition.dx.clamp(0.0, maxX).toDouble();
-  final dy = localPosition.dy.clamp(0.0, maxY).toDouble();
-  final x = (dx / cellWidth).floor().clamp(0, columns - 1);
-  final y = (dy / cellHeight).floor().clamp(0, rows - 1);
-  return GridPos(x: x, y: y);
+  return pathMappingTileFromLocalPosition(
+    localPosition: localPosition,
+    displaySize: ui.Size(columns * cellWidth, rows * cellHeight),
+    columns: columns,
+    rows: rows,
+  );
 }
 
 TilesetSourceRect _rectFromGridPoints(GridPos start, GridPos end) {
@@ -1206,10 +1206,11 @@ Future<Map<TerrainPathVariant, List<TilesetVisualFrame>>?>
   if (path == null || path.isEmpty) {
     return null;
   }
-  final image = await _TerrainTilesetImageCache.load(path);
-  if (image == null) {
+  final imageAsset = await _TerrainTilesetImageCache.loadAsset(path);
+  if (imageAsset == null) {
     return null;
   }
+  final image = imageAsset.image;
 
   final sourceTileWidth = settings.tileWidth;
   final sourceTileHeight = settings.tileHeight;
@@ -1238,127 +1239,77 @@ Future<Map<TerrainPathVariant, List<TilesetVisualFrame>>?>
           orElse: () => _pathSchemaEditableVariants.first,
         );
   Map<TerrainPathVariant, List<TilesetVisualFrame>>? result;
+  var displayedImage = image;
+  var mappingZoom = 1.0;
+  var alphaPreviewEnabled = false;
+  var alphaPreviewErrorMessage = '';
+  var alphaPreviewRevision = 0;
+  final alphaPreviewController = TextEditingController(text: 'f05ba1');
+
+  Future<void> updateAlphaPreview(StateSetter setState) async {
+    final revision = ++alphaPreviewRevision;
+    final preview = createPathMappingAlphaPreviewBytes(
+      originalPngBytes: imageAsset.bytes,
+      enabled: alphaPreviewEnabled,
+      hexRgb: alphaPreviewController.text,
+    );
+    if (!alphaPreviewEnabled || preview.errorMessage != null) {
+      if (!context.mounted || revision != alphaPreviewRevision) {
+        return;
+      }
+      setState(() {
+        displayedImage = image;
+        alphaPreviewErrorMessage = preview.errorMessage ?? '';
+      });
+      return;
+    }
+    final decoded = await _TerrainTilesetImageCache.decodeBytes(preview.bytes);
+    if (!context.mounted || revision != alphaPreviewRevision) {
+      return;
+    }
+    setState(() {
+      displayedImage = decoded ?? image;
+      alphaPreviewErrorMessage =
+          decoded == null ? 'Preview alpha indisponible' : '';
+    });
+  }
 
   if (!context.mounted) {
+    alphaPreviewController.dispose();
     return null;
   }
-  await showMacosSheet<void>(
-    context: context,
-    builder: (ctx) => StatefulBuilder(
-      builder: (ctx, setState) => Center(
-        child: MacosSheet(
-          insetPadding:
-              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
-          child: Padding(
-            padding: const EdgeInsets.all(12),
-            child: SizedBox(
-              width: 980,
-              height: 660,
-              child: Column(
-                crossAxisAlignment: CrossAxisAlignment.stretch,
-                children: [
-                  Text(
-                    'Path Mapping Editor',
-                    style: editorMacosSheetTitleStyle(ctx),
-                  ),
-                  const SizedBox(height: 8),
-                  Expanded(
-                    child: Row(
-                      crossAxisAlignment: CrossAxisAlignment.stretch,
-                      children: [
-                        SizedBox(
-                          width: 430,
-                          child: Column(
-                            crossAxisAlignment: CrossAxisAlignment.stretch,
-                            children: [
-                              Text(
-                                'Step 1: Complete the schema',
-                                style: TextStyle(
-                                  color: CupertinoColors.label
-                                      .resolveFrom(ctx)
-                                      .withValues(alpha: 0.9),
-                                  fontSize: 12,
-                                  fontWeight: FontWeight.w700,
-                                ),
-                              ),
-                              const SizedBox(height: 6),
-                              Text(
-                                '${mappings.length}/${TerrainPathVariant.values.length} mapped',
-                                style: TextStyle(
-                                  color: CupertinoColors.secondaryLabel
-                                      .resolveFrom(ctx),
-                                  fontSize: 11,
-                                ),
-                              ),
-                              const SizedBox(height: 8),
-                              Container(
-                                padding: const EdgeInsets.symmetric(
-                                  horizontal: 8,
-                                  vertical: 7,
-                                ),
-                                decoration: BoxDecoration(
-                                  color: CupertinoColors.systemFill
-                                      .resolveFrom(ctx),
-                                  borderRadius: BorderRadius.circular(8),
-                                  border: Border.all(
-                                    color: CupertinoColors.separator
-                                        .resolveFrom(ctx),
-                                  ),
-                                ),
-                                child: Text(
-                                  'Select a slot in the schema, then click a cell in the tileset on the right to assign it.',
-                                  style: TextStyle(
-                                    fontSize: 10,
-                                    color: CupertinoColors.secondaryLabel
-                                        .resolveFrom(ctx),
-                                  ),
-                                ),
-                              ),
-                              const SizedBox(height: 10),
-                              Expanded(
-                                child: Container(
-                                  padding: const EdgeInsets.all(8),
-                                  decoration: BoxDecoration(
-                                    color: CupertinoColors.systemFill
-                                        .resolveFrom(ctx),
-                                    borderRadius: BorderRadius.circular(10),
-                                    border: Border.all(
-                                      color: CupertinoColors.separator
-                                          .resolveFrom(ctx),
-                                    ),
-                                  ),
-                                  child: _PathSchemaCanvas(
-                                    mappings: mappings,
-                                    selectedVariant: selectedVariant,
-                                    image: image,
-                                    sourceTileWidth: sourceTileWidth,
-                                    sourceTileHeight: sourceTileHeight,
-                                    onSelect: (variant) => setState(
-                                        () => selectedVariant = variant),
-                                  ),
-                                ),
-                              ),
-                            ],
-                          ),
-                        ),
-                        const SizedBox(width: 12),
-                        Expanded(
-                          child: Container(
-                            padding: const EdgeInsets.all(10),
-                            decoration: BoxDecoration(
-                              color:
-                                  CupertinoColors.systemFill.resolveFrom(ctx),
-                              borderRadius: BorderRadius.circular(10),
-                              border: Border.all(
-                                color:
-                                    CupertinoColors.separator.resolveFrom(ctx),
-                              ),
-                            ),
+  try {
+    await showMacosSheet<void>(
+      context: context,
+      builder: (ctx) => StatefulBuilder(
+        builder: (ctx, setState) => Center(
+          child: MacosSheet(
+            insetPadding:
+                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
+            child: Padding(
+              padding: const EdgeInsets.all(12),
+              child: SizedBox(
+                width: 980,
+                height: 660,
+                child: Column(
+                  crossAxisAlignment: CrossAxisAlignment.stretch,
+                  children: [
+                    Text(
+                      'Path Mapping Editor',
+                      style: editorMacosSheetTitleStyle(ctx),
+                    ),
+                    const SizedBox(height: 8),
+                    Expanded(
+                      child: Row(
+                        crossAxisAlignment: CrossAxisAlignment.stretch,
+                        children: [
+                          SizedBox(
+                            width: 430,
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.stretch,
                               children: [
                                 Text(
-                                  'Step 2: Click the tileset to map "${_pathVariantDisplayName(selectedVariant)}"',
+                                  'Step 1: Complete the schema',
                                   style: TextStyle(
                                     color: CupertinoColors.label
                                         .resolveFrom(ctx)
@@ -1369,7 +1320,7 @@ Future<Map<TerrainPathVariant, List<TilesetVisualFrame>>?>
                                 ),
                                 const SizedBox(height: 6),
                                 Text(
-                                  'Tileset: ${notifier.getTilesetById(normalizedTilesetId)?.name ?? normalizedTilesetId}',
+                                  '${mappings.length}/${TerrainPathVariant.values.length} mapped',
                                   style: TextStyle(
                                     color: CupertinoColors.secondaryLabel
                                         .resolveFrom(ctx),
@@ -1378,101 +1329,354 @@ Future<Map<TerrainPathVariant, List<TilesetVisualFrame>>?>
                                 ),
                                 const SizedBox(height: 8),
                                 Container(
-                                  padding: const EdgeInsets.all(8),
+                                  padding: const EdgeInsets.symmetric(
+                                    horizontal: 8,
+                                    vertical: 7,
+                                  ),
                                   decoration: BoxDecoration(
-                                    color: EditorPaintColors.blueGrey
-                                        .withValues(alpha: 0.2),
+                                    color: CupertinoColors.systemFill
+                                        .resolveFrom(ctx),
                                     borderRadius: BorderRadius.circular(8),
                                     border: Border.all(
                                       color: CupertinoColors.separator
                                           .resolveFrom(ctx),
                                     ),
                                   ),
-                                  child: Column(
-                                    crossAxisAlignment:
-                                        CrossAxisAlignment.start,
-                                    children: [
-                                      Text(
-                                        'Active variant: ${_pathVariantDisplayName(selectedVariant)}',
-                                        style: TextStyle(
-                                          fontSize: 11,
-                                          color: CupertinoColors.label
-                                              .resolveFrom(ctx),
-                                          fontWeight: FontWeight.w700,
+                                  child: Text(
+                                    'Select a slot in the schema, then click a cell in the tileset on the right to assign it.',
+                                    style: TextStyle(
+                                      fontSize: 10,
+                                      color: CupertinoColors.secondaryLabel
+                                          .resolveFrom(ctx),
+                                    ),
+                                  ),
+                                ),
+                                const SizedBox(height: 10),
+                                Expanded(
+                                  child: Container(
+                                    padding: const EdgeInsets.all(8),
+                                    decoration: BoxDecoration(
+                                      color: CupertinoColors.systemFill
+                                          .resolveFrom(ctx),
+                                      borderRadius: BorderRadius.circular(10),
+                                      border: Border.all(
+                                        color: CupertinoColors.separator
+                                            .resolveFrom(ctx),
+                                      ),
+                                    ),
+                                    child: _PathSchemaCanvas(
+                                      mappings: mappings,
+                                      selectedVariant: selectedVariant,
+                                      image: displayedImage,
+                                      sourceTileWidth: sourceTileWidth,
+                                      sourceTileHeight: sourceTileHeight,
+                                      onSelect: (variant) => setState(
+                                          () => selectedVariant = variant),
+                                    ),
+                                  ),
+                                ),
+                              ],
+                            ),
+                          ),
+                          const SizedBox(width: 12),
+                          Expanded(
+                            child: Container(
+                              padding: const EdgeInsets.all(10),
+                              decoration: BoxDecoration(
+                                color:
+                                    CupertinoColors.systemFill.resolveFrom(ctx),
+                                borderRadius: BorderRadius.circular(10),
+                                border: Border.all(
+                                  color: CupertinoColors.separator
+                                      .resolveFrom(ctx),
+                                ),
+                              ),
+                              child: Column(
+                                crossAxisAlignment: CrossAxisAlignment.stretch,
+                                children: [
+                                  Text(
+                                    'Step 2: Click the tileset to map "${_pathVariantDisplayName(selectedVariant)}"',
+                                    style: TextStyle(
+                                      color: CupertinoColors.label
+                                          .resolveFrom(ctx)
+                                          .withValues(alpha: 0.9),
+                                      fontSize: 12,
+                                      fontWeight: FontWeight.w700,
+                                    ),
+                                  ),
+                                  const SizedBox(height: 6),
+                                  Text(
+                                    'Tileset: ${notifier.getTilesetById(normalizedTilesetId)?.name ?? normalizedTilesetId}',
+                                    style: TextStyle(
+                                      color: CupertinoColors.secondaryLabel
+                                          .resolveFrom(ctx),
+                                      fontSize: 11,
+                                    ),
+                                  ),
+                                  const SizedBox(height: 8),
+                                  Container(
+                                    padding: const EdgeInsets.all(8),
+                                    decoration: BoxDecoration(
+                                      color: EditorPaintColors.blueGrey
+                                          .withValues(alpha: 0.2),
+                                      borderRadius: BorderRadius.circular(8),
+                                      border: Border.all(
+                                        color: CupertinoColors.separator
+                                            .resolveFrom(ctx),
+                                      ),
+                                    ),
+                                    child: Column(
+                                      crossAxisAlignment:
+                                          CrossAxisAlignment.start,
+                                      children: [
+                                        Text(
+                                          'Active variant: ${_pathVariantDisplayName(selectedVariant)}',
+                                          style: TextStyle(
+                                            fontSize: 11,
+                                            color: CupertinoColors.label
+                                                .resolveFrom(ctx),
+                                            fontWeight: FontWeight.w700,
+                                          ),
+                                        ),
+                                        const SizedBox(height: 2),
+                                        Text(
+                                          'Connections: ${_pathVariantDirectionsLabel(selectedVariant)}',
+                                          style: TextStyle(
+                                            fontSize: 10,
+                                            color: CupertinoColors
+                                                .secondaryLabel
+                                                .resolveFrom(ctx),
+                                          ),
+                                        ),
+                                        const SizedBox(height: 2),
+                                        Text(
+                                          _pathVariantUsageDescription(
+                                            selectedVariant,
+                                          ),
+                                          style: TextStyle(
+                                            fontSize: 10,
+                                            color: CupertinoColors
+                                                .secondaryLabel
+                                                .resolveFrom(ctx),
+                                          ),
                                         ),
+                                      ],
+                                    ),
+                                  ),
+                                  const SizedBox(height: 8),
+                                  Container(
+                                    padding: const EdgeInsets.all(8),
+                                    decoration: BoxDecoration(
+                                      color: EditorPaintColors.black
+                                          .withValues(alpha: 0.16),
+                                      borderRadius: BorderRadius.circular(8),
+                                      border: Border.all(
+                                        color: CupertinoColors.separator
+                                            .resolveFrom(ctx),
                                       ),
-                                      const SizedBox(height: 2),
-                                      Text(
-                                        'Connections: ${_pathVariantDirectionsLabel(selectedVariant)}',
-                                        style: TextStyle(
-                                          fontSize: 10,
-                                          color: CupertinoColors.secondaryLabel
-                                              .resolveFrom(ctx),
+                                    ),
+                                    child: Column(
+                                      crossAxisAlignment:
+                                          CrossAxisAlignment.stretch,
+                                      children: [
+                                        Row(
+                                          children: [
+                                            Text(
+                                              'Transparence preview',
+                                              style: TextStyle(
+                                                fontSize: 11,
+                                                color: CupertinoColors.label
+                                                    .resolveFrom(ctx),
+                                                fontWeight: FontWeight.w700,
+                                              ),
+                                            ),
+                                            const Spacer(),
+                                            CupertinoSwitch(
+                                              key: const Key(
+                                                'path-mapping-alpha-toggle',
+                                              ),
+                                              value: alphaPreviewEnabled,
+                                              onChanged: (value) {
+                                                setState(() {
+                                                  alphaPreviewEnabled = value;
+                                                  if (!value) {
+                                                    displayedImage = image;
+                                                    alphaPreviewErrorMessage =
+                                                        '';
+                                                  }
+                                                });
+                                                if (value) {
+                                                  unawaited(
+                                                    updateAlphaPreview(
+                                                        setState),
+                                                  );
+                                                }
+                                              },
+                                            ),
+                                          ],
+                                        ),
+                                        const SizedBox(height: 6),
+                                        CupertinoTextField(
+                                          key: const Key(
+                                            'path-mapping-alpha-hex-field',
+                                          ),
+                                          controller: alphaPreviewController,
+                                          enabled: alphaPreviewEnabled,
+                                          placeholder: 'f05ba1',
+                                          padding: const EdgeInsets.symmetric(
+                                            horizontal: 8,
+                                            vertical: 6,
+                                          ),
+                                          onChanged: (_) {
+                                            if (alphaPreviewEnabled) {
+                                              unawaited(
+                                                updateAlphaPreview(setState),
+                                              );
+                                            }
+                                          },
                                         ),
+                                        if (alphaPreviewErrorMessage.isNotEmpty)
+                                          Padding(
+                                            padding:
+                                                const EdgeInsets.only(top: 5),
+                                            child: Text(
+                                              alphaPreviewErrorMessage,
+                                              style: const TextStyle(
+                                                fontSize: 10,
+                                                color:
+                                                    EditorPaintColors.redAccent,
+                                              ),
+                                            ),
+                                          ),
+                                      ],
+                                    ),
+                                  ),
+                                  const SizedBox(height: 10),
+                                  _PathVariantFramesEditor(
+                                    image: displayedImage,
+                                    sourceTileWidth: sourceTileWidth,
+                                    sourceTileHeight: sourceTileHeight,
+                                    frames: mappings[selectedVariant] ??
+                                        const <TilesetVisualFrame>[],
+                                    onChanged: (next) {
+                                      setState(() {
+                                        if (next.isEmpty) {
+                                          mappings.remove(selectedVariant);
+                                        } else {
+                                          mappings[selectedVariant] = next;
+                                        }
+                                      });
+                                    },
+                                    onPickFrame: (initial) async {
+                                      final picked =
+                                          await _showTilesetRectPickerDialog(
+                                        context,
+                                        notifier: notifier,
+                                        settings: settings,
+                                        tilesetId: normalizedTilesetId,
+                                        initial: initial,
+                                        title: 'Pick path frame source',
+                                      );
+                                      if (picked == null) {
+                                        return null;
+                                      }
+                                      return TilesetSourceRect(
+                                        x: picked.x,
+                                        y: picked.y,
+                                        width: 1,
+                                        height: 1,
+                                      );
+                                    },
+                                  ),
+                                  const SizedBox(height: 10),
+                                  Row(
+                                    children: [
+                                      PushButton(
+                                        key: const Key('path-mapping-zoom-out'),
+                                        controlSize: ControlSize.small,
+                                        secondary: true,
+                                        onPressed: mappingZoom >
+                                                pathMappingTilesetMinZoom
+                                            ? () => setState(() {
+                                                  mappingZoom =
+                                                      pathMappingTilesetZoomOut(
+                                                    mappingZoom,
+                                                  );
+                                                })
+                                            : null,
+                                        child: const Text('Zoom -'),
                                       ),
-                                      const SizedBox(height: 2),
+                                      const SizedBox(width: 6),
+                                      PushButton(
+                                        key: const Key('path-mapping-zoom-in'),
+                                        controlSize: ControlSize.small,
+                                        secondary: true,
+                                        onPressed: mappingZoom <
+                                                pathMappingTilesetMaxZoom
+                                            ? () => setState(() {
+                                                  mappingZoom =
+                                                      pathMappingTilesetZoomIn(
+                                                    mappingZoom,
+                                                  );
+                                                })
+                                            : null,
+                                        child: const Text('Zoom +'),
+                                      ),
+                                      const SizedBox(width: 6),
+                                      PushButton(
+                                        key: const Key(
+                                            'path-mapping-zoom-reset'),
+                                        controlSize: ControlSize.small,
+                                        secondary: true,
+                                        onPressed: mappingZoom == 1.0
+                                            ? null
+                                            : () => setState(
+                                                  () => mappingZoom = 1.0,
+                                                ),
+                                        child: const Text('100%'),
+                                      ),
+                                      const SizedBox(width: 6),
+                                      PushButton(
+                                        key: const Key('path-mapping-zoom-fit'),
+                                        controlSize: ControlSize.small,
+                                        secondary: true,
+                                        onPressed: mappingZoom == 1.0
+                                            ? null
+                                            : () => setState(
+                                                  () => mappingZoom = 1.0,
+                                                ),
+                                        child: const Text('Ajuster'),
+                                      ),
+                                      const Spacer(),
                                       Text(
-                                        _pathVariantUsageDescription(
-                                          selectedVariant,
+                                        '${(mappingZoom * 100).round()}%',
+                                        key: const Key(
+                                          'path-mapping-zoom-label',
                                         ),
                                         style: TextStyle(
-                                          fontSize: 10,
+                                          fontSize: 11,
                                           color: CupertinoColors.secondaryLabel
                                               .resolveFrom(ctx),
+                                          fontWeight: FontWeight.w700,
                                         ),
                                       ),
                                     ],
                                   ),
-                                ),
-                                const SizedBox(height: 10),
-                                _PathVariantFramesEditor(
-                                  image: image,
-                                  sourceTileWidth: sourceTileWidth,
-                                  sourceTileHeight: sourceTileHeight,
-                                  frames: mappings[selectedVariant] ??
-                                      const <TilesetVisualFrame>[],
-                                  onChanged: (next) {
-                                    setState(() {
-                                      if (next.isEmpty) {
-                                        mappings.remove(selectedVariant);
-                                      } else {
-                                        mappings[selectedVariant] = next;
-                                      }
-                                    });
-                                  },
-                                  onPickFrame: (initial) async {
-                                    final picked =
-                                        await _showTilesetRectPickerDialog(
-                                      context,
-                                      notifier: notifier,
-                                      settings: settings,
-                                      tilesetId: normalizedTilesetId,
-                                      initial: initial,
-                                      title: 'Pick path frame source',
-                                    );
-                                    if (picked == null) {
-                                      return null;
-                                    }
-                                    return TilesetSourceRect(
-                                      x: picked.x,
-                                      y: picked.y,
-                                      width: 1,
-                                      height: 1,
-                                    );
-                                  },
-                                ),
-                                const SizedBox(height: 10),
-                                Expanded(
-                                  child: Center(
+                                  const SizedBox(height: 8),
+                                  Expanded(
                                     child: LayoutBuilder(
                                       builder: (context, constraints) {
-                                        final scale = math.min(
-                                          constraints.maxWidth / image.width,
-                                          constraints.maxHeight / image.height,
+                                        final fitScale = math.min(
+                                          constraints.maxWidth /
+                                              displayedImage.width,
+                                          constraints.maxHeight /
+                                              displayedImage.height,
                                         );
-                                        final renderWidth = image.width * scale;
+                                        final scale = fitScale * mappingZoom;
+                                        final renderWidth =
+                                            displayedImage.width * scale;
                                         final renderHeight =
-                                            image.height * scale;
+                                            displayedImage.height * scale;
                                         final cellWidth = renderWidth / columns;
                                         final cellHeight = renderHeight / rows;
 
@@ -1500,7 +1704,7 @@ Future<Map<TerrainPathVariant, List<TilesetVisualFrame>>?>
                                           });
                                         }
 
-                                        return SizedBox(
+                                        final canvas = SizedBox(
                                           width: renderWidth,
                                           height: renderHeight,
                                           child: GestureDetector(
@@ -1515,7 +1719,7 @@ Future<Map<TerrainPathVariant, List<TilesetVisualFrame>>?>
                                             child: CustomPaint(
                                               painter:
                                                   _PathTilesetMappingPainter(
-                                                image: image,
+                                                image: displayedImage,
                                                 columns: columns,
                                                 rows: rows,
                                                 mappings: mappings,
@@ -1526,66 +1730,76 @@ Future<Map<TerrainPathVariant, List<TilesetVisualFrame>>?>
                                             ),
                                           ),
                                         );
+                                        return SingleChildScrollView(
+                                          primary: false,
+                                          child: SingleChildScrollView(
+                                            primary: false,
+                                            scrollDirection: Axis.horizontal,
+                                            child: canvas,
+                                          ),
+                                        );
                                       },
                                     ),
                                   ),
-                                ),
-                              ],
+                                ],
+                              ),
                             ),
                           ),
+                        ],
+                      ),
+                    ),
+                    const SizedBox(height: 12),
+                    Row(
+                      mainAxisAlignment: MainAxisAlignment.end,
+                      children: [
+                        PushButton(
+                          controlSize: ControlSize.large,
+                          secondary: true,
+                          onPressed: () => Navigator.pop(ctx),
+                          child: const Text('Cancel'),
+                        ),
+                        const SizedBox(width: 8),
+                        PushButton(
+                          controlSize: ControlSize.large,
+                          secondary: true,
+                          onPressed: mappings.containsKey(selectedVariant)
+                              ? () => setState(
+                                    () => mappings.remove(selectedVariant),
+                                  )
+                              : null,
+                          child: const Text('Clear Variant'),
+                        ),
+                        const SizedBox(width: 8),
+                        PushButton(
+                          controlSize: ControlSize.large,
+                          onPressed: () {
+                            result = _completePathMappings(
+                              <TerrainPathVariant, List<TilesetVisualFrame>>{
+                                for (final entry in mappings.entries)
+                                  if (entry.value.isNotEmpty)
+                                    entry.key: List<TilesetVisualFrame>.from(
+                                      entry.value,
+                                      growable: false,
+                                    ),
+                              },
+                            );
+                            Navigator.pop(ctx);
+                          },
+                          child: const Text('Apply'),
                         ),
                       ],
                     ),
-                  ),
-                  const SizedBox(height: 12),
-                  Row(
-                    mainAxisAlignment: MainAxisAlignment.end,
-                    children: [
-                      PushButton(
-                        controlSize: ControlSize.large,
-                        secondary: true,
-                        onPressed: () => Navigator.pop(ctx),
-                        child: const Text('Cancel'),
-                      ),
-                      const SizedBox(width: 8),
-                      PushButton(
-                        controlSize: ControlSize.large,
-                        secondary: true,
-                        onPressed: mappings.containsKey(selectedVariant)
-                            ? () => setState(
-                                  () => mappings.remove(selectedVariant),
-                                )
-                            : null,
-                        child: const Text('Clear Variant'),
-                      ),
-                      const SizedBox(width: 8),
-                      PushButton(
-                        controlSize: ControlSize.large,
-                        onPressed: () {
-                          result = _completePathMappings(
-                            <TerrainPathVariant, List<TilesetVisualFrame>>{
-                              for (final entry in mappings.entries)
-                                if (entry.value.isNotEmpty)
-                                  entry.key: List<TilesetVisualFrame>.from(
-                                    entry.value,
-                                    growable: false,
-                                  ),
-                            },
-                          );
-                          Navigator.pop(ctx);
-                        },
-                        child: const Text('Apply'),
-                      ),
-                    ],
-                  ),
-                ],
+                  ],
+                ),
               ),
             ),
           ),
         ),
       ),
-    ),
-  );
+    );
+  } finally {
+    alphaPreviewController.dispose();
+  }
 
   return result;
 }
@@ -1848,7 +2062,9 @@ Widget _buildPresetDetailsContent({
   required ProjectSettings settings,
   required List<ProjectTilesetEntry> tilesets,
 }) {
-  final color = kind == PresetLibraryKind.terrain ? EditorChrome.accentJade : EditorChrome.accentWarm;
+  final color = kind == PresetLibraryKind.terrain
+      ? EditorChrome.accentJade
+      : EditorChrome.accentWarm;
   return _PresetDetailsCard(
     kind: kind,
     preset: preset,
diff --git a/packages/map_editor/lib/src/ui/panels/terrain_editor/widgets/terrain_mapping_workspace.dart b/packages/map_editor/lib/src/ui/panels/terrain_editor/widgets/terrain_mapping_workspace.dart
index b8d67dcc..04cdbfd6 100644
--- a/packages/map_editor/lib/src/ui/panels/terrain_editor/widgets/terrain_mapping_workspace.dart
+++ b/packages/map_editor/lib/src/ui/panels/terrain_editor/widgets/terrain_mapping_workspace.dart
@@ -1242,10 +1242,24 @@ class _TilesetRectSelectionPainter extends CustomPainter {
   }
 }
 
+class _TerrainTilesetImageAsset {
+  const _TerrainTilesetImageAsset({
+    required this.bytes,
+    required this.image,
+  });
+
+  final Uint8List bytes;
+  final ui.Image image;
+}
+
 class _TerrainTilesetImageCache {
-  static final Map<String, Future<ui.Image?>> _cache = {};
+  static final Map<String, Future<_TerrainTilesetImageAsset?>> _cache = {};
 
-  static Future<ui.Image?> load(String? path) {
+  static Future<ui.Image?> load(String? path) async {
+    return (await loadAsset(path))?.image;
+  }
+
+  static Future<_TerrainTilesetImageAsset?> loadAsset(String? path) {
     if (path == null || path.isEmpty) {
       return Future.value(null);
     }
@@ -1259,12 +1273,24 @@ class _TerrainTilesetImageCache {
         if (bytes.isEmpty) {
           return null;
         }
-        final codec = await ui.instantiateImageCodec(bytes);
-        final frame = await codec.getNextFrame();
-        return frame.image;
+        final image = await decodeBytes(bytes);
+        if (image == null) {
+          return null;
+        }
+        return _TerrainTilesetImageAsset(bytes: bytes, image: image);
       } catch (_) {
         return null;
       }
     });
   }
+
+  static Future<ui.Image?> decodeBytes(Uint8List bytes) async {
+    try {
+      final codec = await ui.instantiateImageCodec(bytes);
+      final frame = await codec.getNextFrame();
+      return frame.image;
+    } catch (_) {
+      return null;
+    }
+  }
 }
diff --git a/packages/map_editor/lib/src/ui/panels/terrain_editor_panel.dart b/packages/map_editor/lib/src/ui/panels/terrain_editor_panel.dart
index d872fe87..c87159ba 100644
--- a/packages/map_editor/lib/src/ui/panels/terrain_editor_panel.dart
+++ b/packages/map_editor/lib/src/ui/panels/terrain_editor_panel.dart
@@ -13,6 +13,7 @@ import 'package:map_editor/src/ui/shared/editor_paint_palette.dart';
 
 import '../../features/editor/state/editor_notifier.dart';
 import '../../features/editor/state/editor_selectors.dart';
+import 'terrain_editor/path_mapping_editor_helpers.dart';
 
 part 'terrain_editor/dialogs/terrain_preset_dialogs.dart';
 part 'terrain_editor/widgets/terrain_mapping_workspace.dart';
diff --git a/packages/map_editor/test/path_pattern/path_studio_panel_test.dart b/packages/map_editor/test/path_pattern/path_studio_panel_test.dart
index 3511aa41..1395a5aa 100644
--- a/packages/map_editor/test/path_pattern/path_studio_panel_test.dart
+++ b/packages/map_editor/test/path_pattern/path_studio_panel_test.dart
@@ -1,8 +1,13 @@
+import 'dart:io';
+import 'dart:typed_data';
+import 'dart:ui' as ui;
+
 import 'package:flutter/cupertino.dart';
 import 'package:flutter_test/flutter_test.dart';
 import 'package:macos_ui/macos_ui.dart';
 import 'package:map_core/map_core.dart';
 import 'package:map_editor/src/features/path_studio/path_studio_panel.dart';
+import 'package:path/path.dart' as p;
 
 void main() {
   group('PathStudioPanel', () {
@@ -118,7 +123,7 @@ void main() {
       expect(find.text('lot futur'), findsWidgets);
 
       await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
-      await tester.pumpAndSettle();
+      await _pumpPathStudioAsync(tester);
 
       expect(find.text('Brouillon nouveau chemin'), findsWidgets);
       expect(find.text('Brouillon non sauvegardé'), findsWidgets);
@@ -147,7 +152,7 @@ void main() {
       );
 
       await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
-      await tester.pumpAndSettle();
+      await _pumpPathStudioAsync(tester);
 
       expect(find.text('Propriétés du nouveau chemin'), findsOneWidget);
       expect(find.text('mountain rock'), findsNothing);
@@ -170,7 +175,7 @@ void main() {
       );
 
       await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
-      await tester.pumpAndSettle();
+      await _pumpPathStudioAsync(tester);
 
       expect(find.text('Tileset'), findsWidgets);
       expect(find.text('À choisir'), findsWidgets);
@@ -199,7 +204,7 @@ void main() {
       );
 
       await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
-      await tester.pumpAndSettle();
+      await _pumpPathStudioAsync(tester);
 
       expect(find.text('Brouillon nouveau chemin'), findsWidgets);
       expect(
@@ -218,14 +223,14 @@ void main() {
       );
 
       await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
-      await tester.pumpAndSettle();
+      await _pumpPathStudioAsync(tester);
       tester
           .widget<MacosPopupButton<String>>(
             find.byKey(const Key('path-studio-new-path-tileset-popup')),
           )
           .onChanged
           ?.call('tileset-main');
-      await tester.pumpAndSettle();
+      await _pumpPathStudioAsync(tester);
 
       final tile = find.byKey(const Key('path-studio-new-path-tile-2-1'));
       await tester.ensureVisible(tile);
@@ -239,6 +244,203 @@ void main() {
       expect(find.text('Tileset à choisir'), findsNothing);
     });
 
+    testWidgets('missing tileset image keeps the logical picker fallback',
+        (tester) async {
+      final temp = (await tester.runAsync(
+        () => Directory.systemTemp.createTemp('path_studio_missing_'),
+      ))!;
+      addTearDown(() => temp.delete(recursive: true));
+      await _pumpPathStudio(
+        tester,
+        manifest: _manifest(
+          tilesets: [_tileset(id: 'tileset-main', name: 'Chemins principaux')],
+        ),
+        projectRootPath: temp.path,
+      );
+
+      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
+      await _pumpPathStudioAsync(tester);
+      tester
+          .widget<MacosPopupButton<String>>(
+            find.byKey(const Key('path-studio-new-path-tileset-popup')),
+          )
+          .onChanged
+          ?.call('tileset-main');
+      await _pumpPathStudioAsync(tester);
+
+      expect(find.text('Image du tileset introuvable'), findsWidgets);
+      expect(find.byKey(const Key('path-studio-new-path-tile-2-1')),
+          findsOneWidget);
+
+      await _tapNewPathTile(tester, tileX: 2, tileY: 1);
+
+      expect(find.text('Tuile 2,1'), findsWidgets);
+      expect(find.text('Cellules à configurer'), findsNothing);
+    });
+
+    testWidgets('image-backed tileset picker assigns the active cell',
+        (tester) async {
+      final temp = (await tester.runAsync(
+        () => Directory.systemTemp.createTemp('path_studio_image_'),
+      ))!;
+      addTearDown(() => temp.delete(recursive: true));
+      final imageFile = File(p.join(temp.path, 'tilesets/tileset-main.png'));
+      await tester.runAsync(() async {
+        await imageFile.parent.create(recursive: true);
+        await imageFile.writeAsBytes(await _pngBytes(width: 64, height: 32));
+      });
+
+      await _pumpPathStudio(
+        tester,
+        manifest: _manifest(
+          settings: const ProjectSettings(tileWidth: 16, tileHeight: 16),
+          tilesets: [_tileset(id: 'tileset-main', name: 'Chemins principaux')],
+        ),
+        projectRootPath: temp.path,
+      );
+
+      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
+      await _pumpPathStudioAsync(tester);
+      tester
+          .widget<MacosPopupButton<String>>(
+            find.byKey(const Key('path-studio-new-path-tileset-popup')),
+          )
+          .onChanged
+          ?.call('tileset-main');
+      await _pumpPathStudioAsync(tester);
+
+      expect(find.byKey(const Key('path-studio-image-backed-tileset-picker')),
+          findsOneWidget);
+      expect(find.text('Image du tileset chargée'), findsWidgets);
+      expect(find.text('Grille 4×2'), findsWidgets);
+      expect(find.byKey(const Key('path-studio-tileset-zoom-out')),
+          findsOneWidget);
+      expect(
+          find.byKey(const Key('path-studio-tileset-zoom-in')), findsOneWidget);
+      expect(find.byKey(const Key('path-studio-tileset-zoom-reset')),
+          findsOneWidget);
+      expect(find.byKey(const Key('path-studio-tileset-zoom-fit')),
+          findsOneWidget);
+
+      final zoomIn = find.byKey(const Key('path-studio-tileset-zoom-in'));
+      await tester.ensureVisible(zoomIn);
+      await _pumpPathStudioAsync(tester);
+      await tester.tap(zoomIn);
+      await _pumpPathStudioAsync(tester);
+      expect(find.text('125%'), findsOneWidget);
+      await tester.tap(find.byKey(const Key('path-studio-tileset-zoom-out')));
+      await _pumpPathStudioAsync(tester);
+      _expectPathStudioZoomLabel(tester, '100%');
+      await tester.tap(zoomIn);
+      await _pumpPathStudioAsync(tester);
+      await tester.tap(find.byKey(const Key('path-studio-tileset-zoom-reset')));
+      await _pumpPathStudioAsync(tester);
+      _expectPathStudioZoomLabel(tester, '100%');
+      await tester.tap(zoomIn);
+      await _pumpPathStudioAsync(tester);
+      await tester.tap(find.byKey(const Key('path-studio-tileset-zoom-fit')));
+      await _pumpPathStudioAsync(tester);
+      _expectPathStudioZoomLabel(tester, '100%');
+      await tester.tap(zoomIn);
+      await _pumpPathStudioAsync(tester);
+
+      await _tapImageBackedTile(tester,
+          tileX: 2, tileY: 1, columns: 4, rows: 2);
+
+      expect(find.text('Tuile 2,1'), findsWidgets);
+      expect(find.text('Cellules à configurer'), findsNothing);
+    });
+
+    testWidgets('image-backed picker fills all 2x2 cells and supports clear',
+        (tester) async {
+      final temp = (await tester.runAsync(
+        () => Directory.systemTemp.createTemp('path_studio_2x2_'),
+      ))!;
+      addTearDown(() => temp.delete(recursive: true));
+      final imageFile = File(p.join(temp.path, 'tilesets/tileset-main.png'));
+      await tester.runAsync(() async {
+        await imageFile.parent.create(recursive: true);
+        await imageFile.writeAsBytes(await _pngBytes(width: 64, height: 32));
+      });
+
+      await _pumpPathStudio(
+        tester,
+        manifest: _manifest(
+          settings: const ProjectSettings(tileWidth: 16, tileHeight: 16),
+          tilesets: [_tileset(id: 'tileset-main', name: 'Chemins principaux')],
+        ),
+        projectRootPath: temp.path,
+      );
+
+      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
+      await _pumpPathStudioAsync(tester);
+      tester
+          .widget<MacosPopupButton<String>>(
+            find.byKey(const Key('path-studio-new-path-tileset-popup')),
+          )
+          .onChanged
+          ?.call('tileset-main');
+      await _pumpPathStudioAsync(tester);
+      await tester.tap(
+        find.byKey(const Key('path-studio-new-path-size-2x2')),
+      );
+      await tester.pumpAndSettle();
+
+      await _assignImageBackedTile(
+        tester,
+        cellX: 0,
+        cellY: 0,
+        tileX: 0,
+        tileY: 0,
+        columns: 4,
+        rows: 2,
+      );
+      await _assignImageBackedTile(
+        tester,
+        cellX: 1,
+        cellY: 0,
+        tileX: 1,
+        tileY: 0,
+        columns: 4,
+        rows: 2,
+      );
+      await _assignImageBackedTile(
+        tester,
+        cellX: 0,
+        cellY: 1,
+        tileX: 2,
+        tileY: 0,
+        columns: 4,
+        rows: 2,
+      );
+
+      expect(find.text('Cellules à configurer'), findsWidgets);
+
+      await _assignImageBackedTile(
+        tester,
+        cellX: 1,
+        cellY: 1,
+        tileX: 3,
+        tileY: 0,
+        columns: 4,
+        rows: 2,
+      );
+
+      expect(find.text('Cellules à configurer'), findsNothing);
+      expect(find.text('Tuile 3,0'), findsWidgets);
+
+      final clearButton =
+          find.byKey(const Key('path-studio-new-path-clear-selected-cell'));
+      await tester.ensureVisible(clearButton);
+      await tester.pumpAndSettle();
+      await tester.tap(clearButton);
+      await tester.pumpAndSettle();
+
+      expect(find.text('Cellules à configurer'), findsWidgets);
+      expect(find.text('Aucune tuile configurée pour cette cellule.'),
+          findsWidgets);
+    });
+
     testWidgets('assigns independent tiles to all 2x2 center cells',
         (tester) async {
       await _pumpPathStudio(
@@ -520,6 +722,7 @@ void main() {
 Future<void> _pumpPathStudio(
   WidgetTester tester, {
   required ProjectManifest manifest,
+  String? projectRootPath,
 }) async {
   await tester.binding.setSurfaceSize(const Size(1440, 920));
   addTearDown(() => tester.binding.setSurfaceSize(null));
@@ -531,14 +734,76 @@ Future<void> _pumpPathStudio(
         children: [
           ContentArea(
             builder: (context, scrollController) {
-              return PathStudioPanel(manifest: manifest);
+              return PathStudioPanel(
+                manifest: manifest,
+                projectRootPath: projectRootPath,
+              );
             },
           ),
         ],
       ),
     ),
   );
-  await tester.pumpAndSettle();
+  await _pumpPathStudioAsync(tester);
+}
+
+Future<void> _pumpPathStudioAsync(WidgetTester tester) async {
+  await tester.pump();
+  await tester.pump(const Duration(milliseconds: 250));
+  await tester.pump(const Duration(milliseconds: 250));
+}
+
+void _expectPathStudioZoomLabel(WidgetTester tester, String value) {
+  final label = tester.widget<Text>(
+    find.byKey(const Key('path-studio-tileset-zoom-label')),
+  );
+  expect(label.data, value);
+}
+
+Future<void> _assignImageBackedTile(
+  WidgetTester tester, {
+  required int cellX,
+  required int cellY,
+  required int tileX,
+  required int tileY,
+  required int columns,
+  required int rows,
+}) async {
+  final cell = find.byKey(Key('path-studio-new-path-cell-$cellX-$cellY'));
+  await tester.ensureVisible(cell);
+  await _pumpPathStudioAsync(tester);
+  await tester.tap(cell);
+  await _pumpPathStudioAsync(tester);
+  await _tapImageBackedTile(
+    tester,
+    tileX: tileX,
+    tileY: tileY,
+    columns: columns,
+    rows: rows,
+  );
+}
+
+Future<void> _tapImageBackedTile(
+  WidgetTester tester, {
+  required int tileX,
+  required int tileY,
+  required int columns,
+  required int rows,
+}) async {
+  final picker =
+      find.byKey(const Key('path-studio-image-backed-tileset-canvas'));
+  await tester.ensureVisible(picker);
+  await _pumpPathStudioAsync(tester);
+  final topLeft = tester.getTopLeft(picker);
+  final size = tester.getSize(picker);
+  await tester.tapAt(
+    topLeft +
+        Offset(
+          (tileX + 0.5) * size.width / columns,
+          (tileY + 0.5) * size.height / rows,
+        ),
+  );
+  await _pumpPathStudioAsync(tester);
 }
 
 Future<void> _assignNewPathTile(
@@ -550,9 +815,9 @@ Future<void> _assignNewPathTile(
 }) async {
   final cell = find.byKey(Key('path-studio-new-path-cell-$cellX-$cellY'));
   await tester.ensureVisible(cell);
-  await tester.pumpAndSettle();
+  await _pumpPathStudioAsync(tester);
   await tester.tap(cell);
-  await tester.pumpAndSettle();
+  await _pumpPathStudioAsync(tester);
   await _tapNewPathTile(tester, tileX: tileX, tileY: tileY);
 }
 
@@ -563,18 +828,20 @@ Future<void> _tapNewPathTile(
 }) async {
   final tile = find.byKey(Key('path-studio-new-path-tile-$tileX-$tileY'));
   await tester.ensureVisible(tile);
-  await tester.pumpAndSettle();
+  await _pumpPathStudioAsync(tester);
   await tester.tap(tile);
-  await tester.pumpAndSettle();
+  await _pumpPathStudioAsync(tester);
 }
 
 ProjectManifest _manifest({
   List<ProjectPathPreset> pathPresets = const [],
   List<ProjectPathPatternPreset> pathPatternPresets = const [],
   List<ProjectTilesetEntry> tilesets = const [],
+  ProjectSettings settings = const ProjectSettings(),
 }) {
   return ProjectManifest(
     name: 'Project',
+    settings: settings,
     maps: const [],
     tilesets: tilesets,
     pathPresets: pathPresets,
@@ -583,6 +850,35 @@ ProjectManifest _manifest({
   );
 }
 
+Future<Uint8List> _pngBytes({
+  required int width,
+  required int height,
+}) async {
+  final recorder = ui.PictureRecorder();
+  final canvas = ui.Canvas(recorder);
+  final colors = [
+    const ui.Color(0xFFEBCB8B),
+    const ui.Color(0xFFA3BE8C),
+    const ui.Color(0xFF88C0D0),
+    const ui.Color(0xFFB48EAD),
+  ];
+  var colorIndex = 0;
+  for (var y = 0; y < height; y += 16) {
+    for (var x = 0; x < width; x += 16) {
+      final paint = ui.Paint()..color = colors[colorIndex % colors.length];
+      canvas.drawRect(
+        ui.Rect.fromLTWH(x.toDouble(), y.toDouble(), 16, 16),
+        paint,
+      );
+      colorIndex += 1;
+    }
+  }
+  final picture = recorder.endRecording();
+  final image = await picture.toImage(width, height);
+  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
+  return byteData!.buffer.asUint8List();
+}
+
 ProjectTilesetEntry _tileset({
   required String id,
   required String name,
```

### 17.4 Contenu complet des fichiers créés ou non suivis touchés

#### packages/map_editor/lib/src/ui/panels/terrain_editor/path_mapping_editor_helpers.dart

Lignes : `84`
SHA-256 : `c0507ac9622eb56463a3d343f7e198a71575102778608c946f132e53ffae3aab`

```dart
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/tileset_transparent_color_processor.dart';

const double pathMappingTilesetMinZoom = 0.5;
const double pathMappingTilesetMaxZoom = 8.0;
const double pathMappingTilesetZoomStep = 1.25;

final class PathMappingAlphaPreviewBytesResult {
  const PathMappingAlphaPreviewBytesResult({
    required this.bytes,
    required this.errorMessage,
  });

  final Uint8List bytes;
  final String? errorMessage;
}

GridPos pathMappingTileFromLocalPosition({
  required ui.Offset localPosition,
  required ui.Size displaySize,
  required int columns,
  required int rows,
}) {
  if (displaySize.width <= 0 ||
      displaySize.height <= 0 ||
      columns <= 0 ||
      rows <= 0) {
    return const GridPos(x: 0, y: 0);
  }
  final maxX = math.max(0.0, displaySize.width - 0.000001);
  final maxY = math.max(0.0, displaySize.height - 0.000001);
  final dx = localPosition.dx.clamp(0.0, maxX).toDouble();
  final dy = localPosition.dy.clamp(0.0, maxY).toDouble();
  return GridPos(
    x: (dx / displaySize.width * columns).floor().clamp(0, columns - 1),
    y: (dy / displaySize.height * rows).floor().clamp(0, rows - 1),
  );
}

double pathMappingClampTilesetZoom(double zoom) {
  final clamped =
      zoom.clamp(pathMappingTilesetMinZoom, pathMappingTilesetMaxZoom);
  return double.parse(clamped.toStringAsFixed(4));
}

double pathMappingTilesetZoomIn(double currentZoom) {
  return pathMappingClampTilesetZoom(currentZoom * pathMappingTilesetZoomStep);
}

double pathMappingTilesetZoomOut(double currentZoom) {
  return pathMappingClampTilesetZoom(currentZoom / pathMappingTilesetZoomStep);
}

PathMappingAlphaPreviewBytesResult createPathMappingAlphaPreviewBytes({
  required Uint8List originalPngBytes,
  required bool enabled,
  required String hexRgb,
}) {
  if (!enabled) {
    return PathMappingAlphaPreviewBytesResult(
      bytes: originalPngBytes,
      errorMessage: null,
    );
  }
  try {
    final transparentColor = TilesetTransparentColor.fromHexRgb(hexRgb.trim());
    return PathMappingAlphaPreviewBytesResult(
      bytes: applyTilesetTransparentColorToPngBytes(
        imageBytes: originalPngBytes,
        transparentColor: transparentColor,
      ),
      errorMessage: null,
    );
  } on ArgumentError {
    return PathMappingAlphaPreviewBytesResult(
      bytes: originalPngBytes,
      errorMessage: 'Couleur hex invalide',
    );
  }
}
```

#### packages/map_editor/test/path_pattern/path_mapping_editor_helpers_test.dart

Lignes : `151`
SHA-256 : `d0f7d3c18e04f8a2e6bed235cdb5432a98c18dae6a720b31e308afafc754b13a`

```dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/ui/panels/terrain_editor/path_mapping_editor_helpers.dart';

void main() {
  group('path mapping editor helpers', () {
    test('converts zoomed local positions to tile coordinates', () {
      final pos = pathMappingTileFromLocalPosition(
        localPosition: const ui.Offset(175, 72),
        displaySize: const ui.Size(256, 128),
        columns: 4,
        rows: 2,
      );

      expect(pos, const GridPos(x: 2, y: 1));
    });

    test('clamps zoom controls to the supported range', () {
      expect(pathMappingTilesetZoomIn(1), 1.25);
      expect(pathMappingTilesetZoomOut(1.25), 1);
      expect(pathMappingTilesetZoomOut(0.5), 0.5);
      expect(pathMappingTilesetZoomIn(8), 8);
    });

    test('keeps original bytes when alpha preview is disabled', () {
      final imageBytes = _pngBytes([
        const _Pixel(red: 240, green: 91, blue: 161, alpha: 255),
      ]);

      final result = createPathMappingAlphaPreviewBytes(
        originalPngBytes: imageBytes,
        enabled: false,
        hexRgb: 'f05ba1',
      );

      expect(identical(result.bytes, imageBytes), isTrue);
      expect(result.errorMessage, isNull);
    });

    test('applies alpha preview for a valid RGB hex color', () {
      final imageBytes = _pngBytes([
        const _Pixel(red: 240, green: 91, blue: 161, alpha: 255),
        const _Pixel(red: 0, green: 0, blue: 255, alpha: 255),
      ]);

      final result = createPathMappingAlphaPreviewBytes(
        originalPngBytes: imageBytes,
        enabled: true,
        hexRgb: 'f05ba1',
      );
      final image = img.decodePng(result.bytes)!;

      expect(result.errorMessage, isNull);
      expect(_pixelAt(image, 0, 0),
          const _Pixel(red: 240, green: 91, blue: 161, alpha: 0));
      expect(_pixelAt(image, 1, 0),
          const _Pixel(red: 0, green: 0, blue: 255, alpha: 255));
    });

    test('reports invalid alpha preview hex without modifying bytes', () {
      final imageBytes = _pngBytes([
        const _Pixel(red: 240, green: 91, blue: 161, alpha: 255),
      ]);

      final result = createPathMappingAlphaPreviewBytes(
        originalPngBytes: imageBytes,
        enabled: true,
        hexRgb: 'not-hex',
      );

      expect(identical(result.bytes, imageBytes), isTrue);
      expect(result.errorMessage, 'Couleur hex invalide');
    });

    test('alpha preview never writes back to the source image file', () async {
      final temp = await Directory.systemTemp.createTemp('path_mapping_alpha_');
      addTearDown(() => temp.delete(recursive: true));
      final imageBytes = _pngBytes([
        const _Pixel(red: 240, green: 91, blue: 161, alpha: 255),
      ]);
      final file = File('${temp.path}/tileset.png');
      await file.writeAsBytes(imageBytes);

      final result = createPathMappingAlphaPreviewBytes(
        originalPngBytes: await file.readAsBytes(),
        enabled: true,
        hexRgb: 'f05ba1',
      );
      final after = await file.readAsBytes();

      expect(result.bytes, isNot(imageBytes));
      expect(after, imageBytes);
    });
  });
}

Uint8List _pngBytes(List<_Pixel> pixels) {
  final image = img.Image(width: pixels.length, height: 1, numChannels: 4);
  for (var x = 0; x < pixels.length; x += 1) {
    final pixel = pixels[x];
    image.setPixelRgba(x, 0, pixel.red, pixel.green, pixel.blue, pixel.alpha);
  }
  return img.encodePng(image);
}

_Pixel _pixelAt(img.Image image, int x, int y) {
  final pixel = image.getPixel(x, y);
  return _Pixel(
    red: pixel.r.toInt(),
    green: pixel.g.toInt(),
    blue: pixel.b.toInt(),
    alpha: pixel.a.toInt(),
  );
}

final class _Pixel {
  const _Pixel({
    required this.red,
    required this.green,
    required this.blue,
    required this.alpha,
  });

  final int red;
  final int green;
  final int blue;
  final int alpha;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is _Pixel &&
            other.red == red &&
            other.green == green &&
            other.blue == blue &&
            other.alpha == alpha;
  }

  @override
  int get hashCode => Object.hash(red, green, blue, alpha);

  @override
  String toString() {
    return '_Pixel(red: $red, green: $green, blue: $blue, alpha: $alpha)';
  }
}
```

#### packages/map_editor/lib/src/features/path_studio/path_studio_tileset_image_picker.dart

Lignes : `746`
SHA-256 : `4e90667637b4004c034d950198d401d9fff222456cee30b6a8826d80cbcc39f0`

```dart
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:image/image.dart' as img;
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import 'path_studio_new_path_draft.dart';
import 'path_studio_theme.dart';

enum PathStudioTilesetImageStatus {
  missingProjectRoot,
  missingFile,
  invalidTileSize,
  invalidGrid,
  invalidImage,
  loaded,
}

final class PathStudioResolvedTilesetImage {
  const PathStudioResolvedTilesetImage({
    required this.absolutePath,
    required this.bytes,
    required this.imageWidthPx,
    required this.imageHeightPx,
    required this.tileWidthPx,
    required this.tileHeightPx,
    required this.columns,
    required this.rows,
  });

  final String absolutePath;
  final Uint8List bytes;
  final int imageWidthPx;
  final int imageHeightPx;
  final int tileWidthPx;
  final int tileHeightPx;
  final int columns;
  final int rows;
}

final class PathStudioTilesetImageLoadResult {
  const PathStudioTilesetImageLoadResult({
    required this.status,
    required this.message,
    this.image,
  });

  final PathStudioTilesetImageStatus status;
  final String message;
  final PathStudioResolvedTilesetImage? image;

  bool get hasImage =>
      status == PathStudioTilesetImageStatus.loaded && image != null;
}

Future<PathStudioTilesetImageLoadResult> loadPathStudioTilesetImage({
  required String? projectRootPath,
  required ProjectTilesetEntry tileset,
  required ProjectSettings settings,
}) async {
  final root = projectRootPath?.trim();
  if (root == null || root.isEmpty) {
    return const PathStudioTilesetImageLoadResult(
      status: PathStudioTilesetImageStatus.missingProjectRoot,
      message: 'Racine projet indisponible',
    );
  }

  final tileWidth = settings.tileWidth;
  final tileHeight = settings.tileHeight;
  if (tileWidth <= 0 || tileHeight <= 0) {
    return const PathStudioTilesetImageLoadResult(
      status: PathStudioTilesetImageStatus.invalidTileSize,
      message: 'Dimensions de tuile invalides',
    );
  }

  final absolutePath = p.normalize(p.join(root, tileset.relativePath));
  final file = File(absolutePath);
  if (!file.existsSync()) {
    return const PathStudioTilesetImageLoadResult(
      status: PathStudioTilesetImageStatus.missingFile,
      message: 'Image du tileset introuvable',
    );
  }

  try {
    final bytes = file.readAsBytesSync();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return const PathStudioTilesetImageLoadResult(
        status: PathStudioTilesetImageStatus.invalidImage,
        message: 'Image du tileset illisible',
      );
    }
    final columns = decoded.width ~/ tileWidth;
    final rows = decoded.height ~/ tileHeight;
    if (columns <= 0 || rows <= 0) {
      return const PathStudioTilesetImageLoadResult(
        status: PathStudioTilesetImageStatus.invalidGrid,
        message: 'Impossible de découper ce tileset',
      );
    }
    return PathStudioTilesetImageLoadResult(
      status: PathStudioTilesetImageStatus.loaded,
      message: 'Image du tileset chargée',
      image: PathStudioResolvedTilesetImage(
        absolutePath: absolutePath,
        bytes: bytes,
        imageWidthPx: decoded.width,
        imageHeightPx: decoded.height,
        tileWidthPx: tileWidth,
        tileHeightPx: tileHeight,
        columns: columns,
        rows: rows,
      ),
    );
  } catch (_) {
    return const PathStudioTilesetImageLoadResult(
      status: PathStudioTilesetImageStatus.invalidImage,
      message: 'Image du tileset illisible',
    );
  }
}

TilesetSourceRect pathStudioTileSourceFromLocalPosition({
  required ui.Offset localPosition,
  required ui.Size displaySize,
  required int columns,
  required int rows,
}) {
  if (displaySize.width <= 0 || displaySize.height <= 0) {
    return const TilesetSourceRect(x: 0, y: 0);
  }
  final rawX = (localPosition.dx / displaySize.width * columns).floor();
  final rawY = (localPosition.dy / displaySize.height * rows).floor();
  return TilesetSourceRect(
    x: rawX.clamp(0, columns - 1).toInt(),
    y: rawY.clamp(0, rows - 1).toInt(),
  );
}

typedef PathStudioTilesetFallbackBuilder = Widget Function(
  BuildContext context,
  PathStudioTilesetImageLoadResult result,
);

class PathStudioImageBackedTilesetPicker extends StatefulWidget {
  const PathStudioImageBackedTilesetPicker({
    super.key,
    required this.projectRootPath,
    required this.tileset,
    required this.settings,
    required this.activeCell,
    required this.onTileSelected,
    required this.fallbackBuilder,
  });

  final String? projectRootPath;
  final ProjectTilesetEntry tileset;
  final ProjectSettings settings;
  final PathStudioNewPathDraftCell activeCell;
  final ValueChanged<TilesetSourceRect> onTileSelected;
  final PathStudioTilesetFallbackBuilder fallbackBuilder;

  @override
  State<PathStudioImageBackedTilesetPicker> createState() =>
      _PathStudioImageBackedTilesetPickerState();
}

class _PathStudioImageBackedTilesetPickerState
    extends State<PathStudioImageBackedTilesetPicker> {
  late Future<PathStudioTilesetImageLoadResult> _loadFuture;

  @override
  void initState() {
    super.initState();
    _loadFuture = _load();
  }

  @override
  void didUpdateWidget(covariant PathStudioImageBackedTilesetPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.projectRootPath != widget.projectRootPath ||
        oldWidget.tileset.id != widget.tileset.id ||
        oldWidget.tileset.relativePath != widget.tileset.relativePath ||
        oldWidget.settings.tileWidth != widget.settings.tileWidth ||
        oldWidget.settings.tileHeight != widget.settings.tileHeight) {
      _loadFuture = _load();
    }
  }

  Future<PathStudioTilesetImageLoadResult> _load() {
    return loadPathStudioTilesetImage(
      projectRootPath: widget.projectRootPath,
      tileset: widget.tileset,
      settings: widget.settings,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PathStudioTilesetImageLoadResult>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const _TilesetImageLoadingState();
        }
        final result = snapshot.requireData;
        final image = result.image;
        if (!result.hasImage || image == null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TilesetImageFallbackNotice(message: result.message),
              const SizedBox(height: 12),
              widget.fallbackBuilder(context, result),
            ],
          );
        }
        return _LoadedTilesetImagePicker(
          image: image,
          activeCell: widget.activeCell,
          onTileSelected: widget.onTileSelected,
        );
      },
    );
  }
}

class PathStudioTileSpritePreview extends StatefulWidget {
  const PathStudioTileSpritePreview({
    super.key,
    required this.projectRootPath,
    required this.tilesets,
    required this.settings,
    required this.tile,
    required this.fallback,
  });

  final String? projectRootPath;
  final List<ProjectTilesetEntry> tilesets;
  final ProjectSettings settings;
  final PathStudioNewPathDraftTile tile;
  final Widget fallback;

  @override
  State<PathStudioTileSpritePreview> createState() =>
      _PathStudioTileSpritePreviewState();
}

class _PathStudioTileSpritePreviewState
    extends State<PathStudioTileSpritePreview> {
  late Future<PathStudioTilesetImageLoadResult>? _loadFuture;

  @override
  void initState() {
    super.initState();
    _loadFuture = _load();
  }

  @override
  void didUpdateWidget(covariant PathStudioTileSpritePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.projectRootPath != widget.projectRootPath ||
        oldWidget.tile.tilesetId != widget.tile.tilesetId ||
        _tilesetFingerprint(oldWidget.tilesets, oldWidget.tile.tilesetId) !=
            _tilesetFingerprint(widget.tilesets, widget.tile.tilesetId) ||
        oldWidget.settings.tileWidth != widget.settings.tileWidth ||
        oldWidget.settings.tileHeight != widget.settings.tileHeight) {
      _loadFuture = _load();
    }
  }

  Future<PathStudioTilesetImageLoadResult>? _load() {
    final tileset = _tilesetById(widget.tilesets, widget.tile.tilesetId);
    if (tileset == null) {
      return null;
    }
    return loadPathStudioTilesetImage(
      projectRootPath: widget.projectRootPath,
      tileset: tileset,
      settings: widget.settings,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loadFuture = _loadFuture;
    if (loadFuture == null) {
      return widget.fallback;
    }
    return FutureBuilder<PathStudioTilesetImageLoadResult>(
      future: loadFuture,
      builder: (context, snapshot) {
        final image = snapshot.data?.image;
        if (image == null) {
          return widget.fallback;
        }
        if (widget.tile.sourceX >= image.columns ||
            widget.tile.sourceY >= image.rows) {
          return widget.fallback;
        }
        return _TileSpritePreview(
          key: const Key('path-studio-tile-preview-image'),
          image: image,
          tile: widget.tile,
        );
      },
    );
  }
}

class _TileSpritePreview extends StatelessWidget {
  const _TileSpritePreview({
    super.key,
    required this.image,
    required this.tile,
  });

  final PathStudioResolvedTilesetImage image;
  final PathStudioNewPathDraftTile tile;

  @override
  Widget build(BuildContext context) {
    const previewWidth = 46.0;
    const previewHeight = 28.0;
    return Container(
      width: previewWidth,
      height: previewHeight,
      decoration: BoxDecoration(
        color: PathStudioTheme.backgroundAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: PathStudioTheme.success.withValues(alpha: 0.7),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: ClipRect(
        child: Transform.translate(
          offset: Offset(
            -tile.sourceX * previewWidth,
            -tile.sourceY * previewHeight,
          ),
          child: Image.memory(
            image.bytes,
            width: image.columns * previewWidth,
            height: image.rows * previewHeight,
            fit: BoxFit.fill,
            filterQuality: FilterQuality.none,
            gaplessPlayback: true,
          ),
        ),
      ),
    );
  }
}

class _LoadedTilesetImagePicker extends StatefulWidget {
  const _LoadedTilesetImagePicker({
    required this.image,
    required this.activeCell,
    required this.onTileSelected,
  });

  final PathStudioResolvedTilesetImage image;
  final PathStudioNewPathDraftCell activeCell;
  final ValueChanged<TilesetSourceRect> onTileSelected;

  @override
  State<_LoadedTilesetImagePicker> createState() =>
      _LoadedTilesetImagePickerState();
}

class _LoadedTilesetImagePickerState extends State<_LoadedTilesetImagePicker> {
  static const double _minZoom = 0.5;
  static const double _maxZoom = 8.0;
  static const double _zoomStep = 1.25;

  double _zoom = 1.0;

  void _setZoom(double value) {
    setState(() {
      _zoom = double.parse(value.clamp(_minZoom, _maxZoom).toStringAsFixed(4));
    });
  }

  void _zoomIn() {
    _setZoom(_zoom * _zoomStep);
  }

  void _zoomOut() {
    _setZoom(_zoom / _zoomStep);
  }

  void _resetZoom() {
    _setZoom(1.0);
  }

  @override
  Widget build(BuildContext context) {
    final image = widget.image;
    final selectedTile = widget.activeCell.tile;
    final zoomLabel = '${(_zoom * 100).round()}%';
    return Container(
      key: const Key('path-studio-image-backed-tileset-picker'),
      padding: const EdgeInsets.all(12),
      decoration: PathStudioTheme.subtleDecoration(
        color: PathStudioTheme.surfaceStrong,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const MacosIcon(
                CupertinoIcons.photo,
                color: PathStudioTheme.accentCyan,
                size: 16,
              ),
              const SizedBox(width: 8),
              const Text(
                'Image du tileset chargée',
                style: TextStyle(
                  color: PathStudioTheme.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                'Grille ${image.columns}×${image.rows}',
                style: const TextStyle(
                  color: PathStudioTheme.textMuted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _TilesetZoomButton(
                key: const Key('path-studio-tileset-zoom-out'),
                label: 'Zoom -',
                onPressed: _zoom > _minZoom ? _zoomOut : null,
              ),
              const SizedBox(width: 6),
              _TilesetZoomButton(
                key: const Key('path-studio-tileset-zoom-in'),
                label: 'Zoom +',
                onPressed: _zoom < _maxZoom ? _zoomIn : null,
              ),
              const SizedBox(width: 6),
              _TilesetZoomButton(
                key: const Key('path-studio-tileset-zoom-reset'),
                label: '100%',
                onPressed: _zoom == 1.0 ? null : _resetZoom,
              ),
              const SizedBox(width: 6),
              _TilesetZoomButton(
                key: const Key('path-studio-tileset-zoom-fit'),
                label: 'Ajuster',
                onPressed: _zoom == 1.0 ? null : _resetZoom,
              ),
              const Spacer(),
              Text(
                zoomLabel,
                key: const Key('path-studio-tileset-zoom-label'),
                style: const TextStyle(
                  color: PathStudioTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final naturalWidth = image.imageWidthPx.toDouble();
              final naturalHeight = image.imageHeightPx.toDouble();
              final maxWidth = constraints.maxWidth.isFinite
                  ? constraints.maxWidth
                  : naturalWidth;
              final baseWidth = math.min(
                maxWidth,
                math.max(naturalWidth, image.columns * 40.0),
              );
              final displayWidth = baseWidth * _zoom;
              final displayHeight = displayWidth * naturalHeight / naturalWidth;
              final displaySize = ui.Size(displayWidth, displayHeight);
              final viewportHeight = math.min(
                360.0,
                math.max(180.0, displayHeight),
              );
              return SizedBox(
                height: viewportHeight,
                child: SingleChildScrollView(
                  primary: false,
                  child: SingleChildScrollView(
                    primary: false,
                    scrollDirection: Axis.horizontal,
                    child: GestureDetector(
                      onTapDown: (details) {
                        widget.onTileSelected(
                          pathStudioTileSourceFromLocalPosition(
                            localPosition: details.localPosition,
                            displaySize: displaySize,
                            columns: image.columns,
                            rows: image.rows,
                          ),
                        );
                      },
                      child: SizedBox(
                        key: const Key(
                            'path-studio-image-backed-tileset-canvas'),
                        width: displayWidth,
                        height: displayHeight,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.memory(
                                image.bytes,
                                width: displayWidth,
                                height: displayHeight,
                                fit: BoxFit.fill,
                                filterQuality: FilterQuality.none,
                                gaplessPlayback: true,
                              ),
                            ),
                            CustomPaint(
                              painter: _TilesetImageGridPainter(
                                image: image,
                                selectedSource: selectedTile?.tilesetId == null
                                    ? null
                                    : TilesetSourceRect(
                                        x: selectedTile!.sourceX,
                                        y: selectedTile.sourceY,
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TilesetZoomButton extends StatelessWidget {
  const _TilesetZoomButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return PushButton(
      controlSize: ControlSize.small,
      secondary: true,
      onPressed: onPressed,
      child: Text(label),
    );
  }
}

class _TilesetImageLoadingState extends StatelessWidget {
  const _TilesetImageLoadingState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: PathStudioTheme.subtleDecoration(),
      child: const Text(
        'Chargement du tileset…',
        style: TextStyle(
          color: PathStudioTheme.textSecondary,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TilesetImageFallbackNotice extends StatelessWidget {
  const _TilesetImageFallbackNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: PathStudioTheme.subtleDecoration(
        color: PathStudioTheme.warning.withValues(alpha: 0.1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MacosIcon(
            CupertinoIcons.exclamationmark_triangle,
            color: PathStudioTheme.warning,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: const TextStyle(
                    color: PathStudioTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Utilisation du picker logique',
                  style: TextStyle(
                    color: PathStudioTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TilesetImageGridPainter extends CustomPainter {
  const _TilesetImageGridPainter({
    required this.image,
    required this.selectedSource,
  });

  final PathStudioResolvedTilesetImage image;
  final TilesetSourceRect? selectedSource;

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    final target = ui.Offset.zero & size;
    canvas.save();
    canvas.clipRRect(
      ui.RRect.fromRectAndRadius(target, const ui.Radius.circular(14)),
    );
    final cellWidth = size.width / image.columns;
    final cellHeight = size.height / image.rows;
    final gridPaint = ui.Paint()
      ..color = CupertinoColors.black.withValues(alpha: 0.45)
      ..strokeWidth = 1;
    for (var x = 1; x < image.columns; x += 1) {
      final dx = x * cellWidth;
      canvas.drawLine(ui.Offset(dx, 0), ui.Offset(dx, size.height), gridPaint);
    }
    for (var y = 1; y < image.rows; y += 1) {
      final dy = y * cellHeight;
      canvas.drawLine(ui.Offset(0, dy), ui.Offset(size.width, dy), gridPaint);
    }

    final selected = selectedSource;
    if (selected != null &&
        selected.x >= 0 &&
        selected.y >= 0 &&
        selected.x < image.columns &&
        selected.y < image.rows) {
      final rect = ui.Rect.fromLTWH(
        selected.x * cellWidth,
        selected.y * cellHeight,
        cellWidth,
        cellHeight,
      );
      canvas.drawRect(
        rect.deflate(1),
        ui.Paint()
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = PathStudioTheme.accentHover,
      );
      canvas.drawRect(
        rect.deflate(3),
        ui.Paint()
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = PathStudioTheme.accentCyan,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TilesetImageGridPainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.selectedSource != selectedSource;
  }
}

ProjectTilesetEntry? _tilesetById(
  List<ProjectTilesetEntry> tilesets,
  String tilesetId,
) {
  for (final tileset in tilesets) {
    if (tileset.id == tilesetId) {
      return tileset;
    }
  }
  return null;
}

String? _tilesetFingerprint(
  List<ProjectTilesetEntry> tilesets,
  String tilesetId,
) {
  final tileset = _tilesetById(tilesets, tilesetId);
  if (tileset == null) {
    return null;
  }
  return '${tileset.id}|${tileset.relativePath}|${tileset.name}';
}
```

#### packages/map_editor/test/path_pattern/path_studio_tileset_image_picker_test.dart

Lignes : `101`
SHA-256 : `12848d5f697118e8f04947002f66b33c331fc3ce3cb4480c113beed7398520e9`

```dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/path_studio/path_studio_tileset_image_picker.dart';
import 'package:path/path.dart' as p;

void main() {
  group('PathStudioTilesetImagePicker image support', () {
    test('resolves an image from project root and tileset relativePath',
        () async {
      final temp = await Directory.systemTemp.createTemp('path_studio_image_');
      addTearDown(() => temp.delete(recursive: true));
      final imageFile = File(p.join(temp.path, 'tilesets/main.png'));
      await imageFile.parent.create(recursive: true);
      await imageFile.writeAsBytes(await _pngBytes(width: 64, height: 32));

      final result = await loadPathStudioTilesetImage(
        projectRootPath: temp.path,
        tileset: const ProjectTilesetEntry(
          id: 'main',
          name: 'Main',
          relativePath: 'tilesets/main.png',
        ),
        settings: const ProjectSettings(tileWidth: 16, tileHeight: 16),
      );

      expect(result.status, PathStudioTilesetImageStatus.loaded);
      expect(result.image!.absolutePath, imageFile.path);
      expect(result.image!.imageWidthPx, 64);
      expect(result.image!.imageHeightPx, 32);
      expect(result.image!.columns, 4);
      expect(result.image!.rows, 2);
    });

    test('returns a fallback status when the image file is absent', () async {
      final temp =
          await Directory.systemTemp.createTemp('path_studio_missing_');
      addTearDown(() => temp.delete(recursive: true));

      final result = await loadPathStudioTilesetImage(
        projectRootPath: temp.path,
        tileset: const ProjectTilesetEntry(
          id: 'missing',
          name: 'Missing',
          relativePath: 'tilesets/missing.png',
        ),
        settings: const ProjectSettings(tileWidth: 16, tileHeight: 16),
      );

      expect(result.status, PathStudioTilesetImageStatus.missingFile);
      expect(result.image, isNull);
      expect(result.message, contains('introuvable'));
    });

    test('converts a local click position to tile coordinates', () {
      final source = pathStudioTileSourceFromLocalPosition(
        localPosition: const ui.Offset(35, 17),
        displaySize: const ui.Size(128, 64),
        columns: 4,
        rows: 2,
      );

      expect(source.x, 1);
      expect(source.y, 0);
      expect(source.width, 1);
      expect(source.height, 1);
    });

    test('converts a zoomed local click position to tile coordinates', () {
      final source = pathStudioTileSourceFromLocalPosition(
        localPosition: const ui.Offset(175, 72),
        displaySize: const ui.Size(256, 128),
        columns: 4,
        rows: 2,
      );

      expect(source.x, 2);
      expect(source.y, 1);
    });
  });
}

Future<Uint8List> _pngBytes({
  required int width,
  required int height,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  final paint = ui.Paint()..color = const ui.Color(0xFFFF00FF);
  canvas.drawRect(
    ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    paint,
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}
```

## 18. Limites connues

- Le classic Path Mapping Editor reste une sheet privée lourde ; le Lot 18 teste surtout les helpers de calcul et de preview alpha, pas un parcours modal complet.
- `Ajuster` est un reset de zoom simple en V0. Un vrai fit dynamique avec mémorisation viewport pourrait venir plus tard si l’UX le justifie.
- Les fichiers non suivis hérités du Lot 17 restent non suivis ; le Lot 18 ne corrige pas l’hygiène Git par contrat.

## 19. Auto-review

- [x] Audit initial réalisé.
- [x] Git utilisé uniquement en lecture.
- [x] Aucun commit / push / reset / restore / stash / checkout.
- [x] map_core non modifié.
- [x] ProjectManifest non modifié.
- [x] Codecs PathPattern non modifiés.
- [x] Aucun generated file.
- [x] Aucun build_runner.
- [x] Aucun save flow.
- [x] Aucune mutation manifest.
- [x] Aucun painter runtime ajouté.
- [x] Aucun runtime.
- [x] Aucun gameplay / battle.
- [x] Aucun tall grass.
- [x] Aucun Surface Studio / TSX / TMX.
- [x] Path Studio image picker zoomable.
- [x] Path Studio clic après zoom garde les bonnes coordonnées de tuiles.
- [x] Path Studio fallback logique conservé.
- [x] Path Mapping Editor classic zoomable.
- [x] Path Mapping Editor classic alpha preview disponible.
- [x] Alpha preview ne modifie pas le fichier image source.
- [x] Alpha preview ne modifie pas ProjectManifest.
- [x] Tests ciblés passent.
- [x] Régressions pertinentes passent ou échecs documentés.
- [x] Analyze ciblé passe.
- [x] Rapport final complet créé.
- [x] Auto-review faite.
- [x] Critique du prompt faite.

## 20. Review séparée si disponible

Review séparée effectuée par le sub-agent Bernoulli en lecture seule.

Conclusion du reviewer : aucun finding bloquant. Points vérifiés :

- calcul de clic Path Studio lié à la taille affichée zoomée ;
- classic mapping via helper partagé ;
- alpha preview à partir des bytes originaux, sans mutation source/manifest ;
- fallback logique conservé ;
- aucun fichier map_core modifié.

Risque résiduel signalé : couverture classic surtout helper-level, pas test widget profond de la sheet complète.

## 21. Critique du prompt

- Clair : le périmètre ergonomique image était précis et les non-objectifs empêchaient bien une dérive vers save/runtime/painter.
- Ambigu : “Ajuster / Fit” pouvait signifier fit réel à chaque viewport ou simple retour au fit de base. J’ai retenu le retour au fit/base local V0.
- Ambigu : le niveau de test attendu pour le classic editor est difficile car l’UI est une sheet privée et fortement couplée au notifier. J’ai privilégié helpers purs + analyze plutôt qu’un test modal fragile.
- Discutable : demander un Evidence Pack très complet dans un repo avec des fichiers non suivis hérités force à documenter des deltas qui ne viennent pas tous du lot courant.
- Non optimal : le prompt demande “beaucoup de preuves” mais aussi des lots courts ; cela rend le rapport plus coûteux que le code lui-même.

## 22. Prochaine étape recommandée

Lot recommandé : stabiliser le flux de sauvegarde local Path Studio vers une opération projet explicite, ou isoler davantage le classic Path Mapping Editor en composant testable avant d’ajouter de nouvelles options visuelles.

## 23. Confirmation explicite des non-objectifs

- confirmé : pas de sauvegarde dans ProjectManifest.pathPatternPresets.
- confirmé : pas de création persistée de ProjectPathPreset.
- confirmé : pas de mutation réelle du manifest.
- confirmé : pas de save flow.
- confirmé : pas de repository/service de persistance.
- confirmé : pas de provider Riverpod complexe ajouté.
- confirmé : pas de modification map_core.
- confirmé : pas de modification ProjectManifest.
- confirmé : pas de modification codecs PathPattern.
- confirmé : pas de build_runner.
- confirmé : pas de generated files.
- confirmé : pas de painter.
- confirmé : pas de canvas render editor.
- confirmé : pas de runtime render.
- confirmé : pas de gameplay.
- confirmé : pas de battle.
- confirmé : pas de tall grass.
- confirmé : pas de Surface Studio.
- confirmé : pas de TSX/TMX.
- confirmé : pas de Mistral.
- confirmé : pas de PixelLab.
- confirmé : pas de MCP.
- confirmé : pas d’animation de cellule.
- confirmé : pas de multi-frame editor.
- confirmé : pas de timeline.
- confirmé : pas de drag & drop obligatoire.
- confirmé : pas de sélection multi-tuile.
- confirmé : pas de crop manuel.
- confirmé : pas d’édition des bords/coins/jonctions dans le nouveau Path Studio.
- confirmé : pas de migration classic editor vers nouveau Path Studio.
- confirmé : pas de suppression du classic editor.


## 24. Statut Git après écriture du présent rapport

Cette section corrige le fait que les commandes finales intégrées plus haut ont été capturées juste avant l’écriture du fichier rapport. Elle reflète l’état réel une fois ce rapport présent sur disque.

### git status --short --untracked-files=all après écriture du rapport

```bash
cd /Users/karim/Project/pokemonProject
git status --short --untracked-files=all
```

Code de sortie : `0`

```text
 M packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
 M packages/map_editor/lib/src/ui/panels/terrain_editor/dialogs/terrain_preset_dialogs.dart
 M packages/map_editor/lib/src/ui/panels/terrain_editor/widgets/terrain_mapping_workspace.dart
 M packages/map_editor/lib/src/ui/panels/terrain_editor_panel.dart
 M packages/map_editor/test/path_pattern/path_studio_panel_test.dart
?? packages/map_editor/lib/src/features/path_studio/path_studio_tileset_image_picker.dart
?? packages/map_editor/lib/src/ui/panels/terrain_editor/path_mapping_editor_helpers.dart
?? packages/map_editor/test/path_pattern/path_mapping_editor_helpers_test.dart
?? packages/map_editor/test/path_pattern/path_studio_tileset_image_picker_test.dart
?? reports/pathPattern/pathpattern_17_image_backed_tileset_picker_v0.md
?? reports/pathPattern/pathpattern_18_zoomable_tileset_image_classic_alpha_v0.md
```

### git diff --stat après écriture du rapport

```bash
cd /Users/karim/Project/pokemonProject
git diff --stat
```

Code de sortie : `0`

```text
 .../features/path_studio/path_studio_panel.dart    | 185 +++++-
 .../dialogs/terrain_preset_dialogs.dart            | 708 ++++++++++++++-------
 .../widgets/terrain_mapping_workspace.dart         |  36 +-
 .../lib/src/ui/panels/terrain_editor_panel.dart    |   1 +
 .../test/path_pattern/path_studio_panel_test.dart  | 320 +++++++++-
 5 files changed, 956 insertions(+), 294 deletions(-)
```

### git diff --name-status après écriture du rapport

```bash
cd /Users/karim/Project/pokemonProject
git diff --name-status
```

Code de sortie : `0`

```text
M	packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
M	packages/map_editor/lib/src/ui/panels/terrain_editor/dialogs/terrain_preset_dialogs.dart
M	packages/map_editor/lib/src/ui/panels/terrain_editor/widgets/terrain_mapping_workspace.dart
M	packages/map_editor/lib/src/ui/panels/terrain_editor_panel.dart
M	packages/map_editor/test/path_pattern/path_studio_panel_test.dart
```

