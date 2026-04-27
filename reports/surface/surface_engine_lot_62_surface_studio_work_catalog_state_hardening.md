# Lot 62 — Surface Studio Work Catalog State Hardening V0

## Résumé exécutif

Durcissement de l’état local Surface Studio : `widget.readModel` = source ; `_workReadModel` = catalogue affiché ; écart détecté par `!=` avec le read model source. Bandeau « Catalogue de travail modifié — sauvegarde projet non effectuée. » si écart ; bouton « Réinitialiser le catalogue de travail » ; resynchronisation sur `didUpdateWidget` avec filtrage de sélection ; section « Actions futures » sans libellé fantôme « Créer un atlas ».

## Périmètre

Trois fichiers `map_editor` modifiés ; ce rapport créé. Aucun `map_core`.

## Audit initial

Pan Lot 61 : `_readModel` unique, `didUpdateWidget` recopie la source sans réinitialiser la notion de dirty ni la sélection après changement parent. Action fantôme « Créer un atlas » en doublon sémantique avec la création réelle dans le brouillon.

## Implémentation

- `_workReadModel` + `_hasWorkCatalogChanges` via `_workReadModel != widget.readModel`.
- Bandeau + `ValueKey` `surface_studio_work_catalog_dirty_state` ; reset `surface_studio_reset_work_catalog`.
- `_selectionValidInReadModel` pour reset et `didUpdateWidget`.
- `_FutureActions` : titre « Actions futures (non disponibles) », seul « Importer un atlas vertical » ; suppression de `actionCreateAtlasLabel`.

## Fichiers créés

- `reports/surface/surface_engine_lot_62_surface_studio_work_catalog_state_hardening.md`

## Fichiers modifiés

- `packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart`
- `packages/map_editor/test/surface_studio/surface_studio_panel_test.dart`
- `packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart`

## Fichiers supprimés

Sortie : <vide>

## Tests lancés

```
cd packages/map_editor && flutter test test/surface_studio/surface_studio_panel_test.dart
cd packages/map_editor && flutter test test/surface_studio/surface_studio_atlas_authoring_prep_test.dart test/surface_studio/surface_studio_workspace_entry_test.dart
cd packages/map_editor && flutter test test/surface_studio
cd packages/map_core && dart test test/surface_studio_read_model_test.dart
```

Dernière ligne suite `test/surface_studio` : `00:11 +247: All tests passed!`

## Analyse lancée

`flutter analyze lib/src/features/surface_studio test/surface_studio` → No issues found.

## Résultats

Tous les tests ciblés et la suite Surface Studio passent ; analyse sans issue.

## Evidence Pack

### Git status (relevé après implémentation, avant ce rapport)

```
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
 M packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
 M packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart
```

### `git diff --stat`

```
 .../surface_studio/surface_studio_panel.dart       |  82 ++++--
 .../surface_studio/surface_studio_panel_test.dart  | 303 ++++++++++++++++++++-
 .../surface_studio_workspace_entry_test.dart       |   9 +-
 3 files changed, 357 insertions(+), 37 deletions(-)
```

### Diff unifié complet (Lot 62)

```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart b/packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
index 3850cff1..9b3c9d6f 100644
--- a/packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
+++ b/packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
@@ -20,6 +20,27 @@ import 'surface_studio_selection.dart';
 import 'surface_studio_selection_inspector.dart';
 import 'surface_studio_selection_summary.dart';
 
+SurfaceStudioSelection _selectionValidInReadModel(
+  SurfaceStudioReadModel rm,
+  SurfaceStudioSelection sel,
+) {
+  if (sel.isNone) return sel;
+  if (sel.isAtlas) {
+    for (final row in rm.atlases) {
+      if (row.id == sel.id) return sel;
+    }
+  } else if (sel.isAnimation) {
+    for (final row in rm.animations) {
+      if (row.id == sel.id) return sel;
+    }
+  } else if (sel.isPreset) {
+    for (final row in rm.presets) {
+      if (row.id == sel.id) return sel;
+    }
+  }
+  return const SurfaceStudioSelection.none();
+}
+
 /// Accent produit Surface Studio (même base que la tuile World Explorer).
 const Color _surfaceStudioAccent = Color(0xFF2DD4BF);
 
@@ -38,9 +59,10 @@ class SurfaceStudioPanel extends StatefulWidget {
       'Préparez et contrôlez les surfaces animées du projet : eau, lave, glace, hautes herbes.';
   static const String placeholderActionsTitle = 'Actions auteur';
   static const String placeholderSoonText = 'Bientôt';
-  static const String actionCreateAtlasLabel = 'Créer un atlas';
   static const String actionImportVerticalAtlasLabel =
       'Importer un atlas vertical';
+  static const String workCatalogDirtyStateText =
+      'Catalogue de travail modifié — sauvegarde projet non effectuée.';
 
   @override
   State<SurfaceStudioPanel> createState() => _SurfaceStudioPanelState();
@@ -49,25 +71,30 @@ class SurfaceStudioPanel extends StatefulWidget {
 class _SurfaceStudioPanelState extends State<SurfaceStudioPanel> {
   /// Sélection d’inspection : locale au widget, jamais écrite dans le manifest.
   SurfaceStudioSelection _selection = const SurfaceStudioSelection.none();
-  late SurfaceStudioReadModel _readModel;
+  late SurfaceStudioReadModel _workReadModel;
 
   @override
   void initState() {
     super.initState();
-    _readModel = widget.readModel;
+    _workReadModel = widget.readModel;
   }
 
   @override
   void didUpdateWidget(covariant SurfaceStudioPanel oldWidget) {
     super.didUpdateWidget(oldWidget);
     if (widget.readModel != oldWidget.readModel) {
-      _readModel = widget.readModel;
+      setState(() {
+        _workReadModel = widget.readModel;
+        _selection = _selectionValidInReadModel(_workReadModel, _selection);
+      });
     }
   }
 
+  bool get _hasWorkCatalogChanges => _workReadModel != widget.readModel;
+
   @override
   Widget build(BuildContext context) {
-    final s = _readModel.summary;
+    final s = _workReadModel.summary;
     final label = EditorChrome.primaryLabel(context);
     final subtle = EditorChrome.subtleLabel(context);
 
@@ -116,6 +143,31 @@ class _SurfaceStudioPanelState extends State<SurfaceStudioPanel> {
               height: 1.35,
             ),
           ),
+          if (_hasWorkCatalogChanges) ...[
+            const SizedBox(height: 10),
+            Text(
+              SurfaceStudioPanel.workCatalogDirtyStateText,
+              key: const ValueKey('surface_studio_work_catalog_dirty_state'),
+              style: TextStyle(
+                color: _surfaceStudioAccent.withValues(alpha: 0.95),
+                fontSize: 12,
+                fontWeight: FontWeight.w600,
+              ),
+            ),
+            const SizedBox(height: 6),
+            CupertinoButton(
+              key: const ValueKey('surface_studio_reset_work_catalog'),
+              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
+              onPressed: () {
+                setState(() {
+                  _workReadModel = widget.readModel;
+                  _selection =
+                      _selectionValidInReadModel(_workReadModel, _selection);
+                });
+              },
+              child: const Text('Réinitialiser le catalogue de travail'),
+            ),
+          ],
           const SizedBox(height: 20),
           _CounterRow(
             atlas: s.atlasCount,
@@ -126,29 +178,29 @@ class _SurfaceStudioPanelState extends State<SurfaceStudioPanel> {
           SurfaceStudioSelectionSummary(selection: _selection),
           const SizedBox(height: 12),
           SurfaceStudioSelectionInspector(
-            readModel: _readModel,
+            readModel: _workReadModel,
             selection: _selection,
           ),
           const SizedBox(height: 12),
           SurfaceStudioCatalogBrowser(
-            readModel: _readModel,
+            readModel: _workReadModel,
             selection: _selection,
             onSelectionChanged: (v) {
               setState(() => _selection = v);
             },
           ),
           const SizedBox(height: 16),
-          SurfaceStudioDiagnosticsView(readModel: _readModel),
+          SurfaceStudioDiagnosticsView(readModel: _workReadModel),
           const SizedBox(height: 20),
           SurfaceStudioAtlasAuthoringPrep(
-            readModel: _readModel,
+            readModel: _workReadModel,
             selection: _selection,
             onSurfaceCatalogChanged: (cat) {
               final newId = cat.atlases.isNotEmpty
                   ? cat.atlases.last.id
                   : '';
               setState(() {
-                _readModel = buildSurfaceStudioReadModelFromCatalog(cat);
+                _workReadModel = buildSurfaceStudioReadModelFromCatalog(cat);
                 if (newId.isNotEmpty) {
                   _selection = SurfaceStudioSelection.atlas(newId);
                 }
@@ -157,7 +209,6 @@ class _SurfaceStudioPanelState extends State<SurfaceStudioPanel> {
           ),
           const SizedBox(height: 20),
           const _FutureActions(
-            onCreateAtlas: null,
             onImportVertical: null,
           ),
           const SizedBox(height: 20),
@@ -344,11 +395,9 @@ class _StudioCard extends StatelessWidget {
 
 class _FutureActions extends StatelessWidget {
   const _FutureActions({
-    required this.onCreateAtlas,
     required this.onImportVertical,
   });
 
-  final VoidCallback? onCreateAtlas;
   final VoidCallback? onImportVertical;
 
   @override
@@ -359,7 +408,7 @@ class _FutureActions extends StatelessWidget {
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         Text(
-          'Actions (non disponibles dans ce lot)',
+          'Actions futures (non disponibles)',
           style: TextStyle(
             color: subtle,
             fontSize: 12,
@@ -369,11 +418,6 @@ class _FutureActions extends StatelessWidget {
         const SizedBox(height: 10),
         Row(
           children: [
-            _GhostAction(
-              label: SurfaceStudioPanel.actionCreateAtlasLabel,
-              onPressed: onCreateAtlas,
-            ),
-            const SizedBox(width: 12),
             _GhostAction(
               label: SurfaceStudioPanel.actionImportVerticalAtlasLabel,
               onPressed: onImportVertical,
diff --git a/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart b/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
index 6f2af789..f0fcfb75 100644
--- a/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
+++ b/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
@@ -104,33 +104,30 @@ void main() {
       );
     });
 
-    testWidgets('10. future action labels are visible', (tester) async {
+    testWidgets('10. future action label import visible (pas Créer un atlas)',
+        (tester) async {
       await tester.pumpWidget(
         _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
       );
-      expect(find.text('Créer un atlas'), findsOneWidget);
-      expect(find.text('Importer un atlas vertical'), findsOneWidget);
+      expect(find.text('Créer un atlas'), findsNothing);
+      expect(
+        find.text(SurfaceStudioPanel.actionImportVerticalAtlasLabel),
+        findsOneWidget,
+      );
     });
 
-    testWidgets('11. future actions are disabled (onPressed null)',
+    testWidgets('11. future import action disabled (onPressed null)',
         (tester) async {
       await tester.pumpWidget(
         _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
       );
-      final b1 = tester.widget<CupertinoButton>(
-        find.ancestor(
-          of: find.text('Créer un atlas'),
-          matching: find.byType(CupertinoButton),
-        ),
-      );
-      final b2 = tester.widget<CupertinoButton>(
+      final b = tester.widget<CupertinoButton>(
         find.ancestor(
-          of: find.text('Importer un atlas vertical'),
+          of: find.text(SurfaceStudioPanel.actionImportVerticalAtlasLabel),
           matching: find.byType(CupertinoButton),
         ),
       );
-      expect(b1.onPressed, isNull);
-      expect(b2.onPressed, isNull);
+      expect(b.onPressed, isNull);
     });
 
     testWidgets('12. section placeholder titles are visible', (tester) async {
@@ -692,6 +689,284 @@ void main() {
       expect(find.text('Water Surface'), findsOneWidget);
       expect(find.text('grass-a'), findsWidgets);
     });
+
+    testWidgets('62.0 — pas de dirty au départ (vide + minimal)', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
+      );
+      expect(
+        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
+        findsNothing,
+      );
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
+      );
+      expect(
+        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
+        findsNothing,
+      );
+    });
+
+    testWidgets('62.1 — dirty après création locale', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
+      );
+      final idF = find.byKey(const ValueKey('atlas_draft_id'));
+      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
+      final tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
+      await tester.ensureVisible(idF);
+      await tester.enterText(idF, 'dirty-a');
+      await tester.enterText(nameF, 'D');
+      await tester.enterText(tsF, 't');
+      await tester.pump();
+      await tester.ensureVisible(
+        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
+      );
+      await tester.tap(
+        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
+      );
+      await tester.pump();
+      expect(
+        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
+        findsOneWidget,
+      );
+      expect(
+        find.textContaining('sauvegarde projet non effectuée'),
+        findsWidgets,
+      );
+    });
+
+    testWidgets(
+        '62.2 — reset depuis catalogue vide : compteur 0, atlas absent, dirty off',
+        (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
+      );
+      final idF = find.byKey(const ValueKey('atlas_draft_id'));
+      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
+      final tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
+      await tester.ensureVisible(idF);
+      await tester.enterText(idF, 'rs-a');
+      await tester.enterText(nameF, 'R');
+      await tester.enterText(tsF, 't');
+      await tester.pump();
+      await tester.ensureVisible(
+        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
+      );
+      await tester.tap(
+        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
+      );
+      await tester.pump();
+      var counters = find.byKey(const ValueKey('surface_studio_header_counters'));
+      expect(
+        find.descendant(of: counters, matching: find.text('1')),
+        findsOneWidget,
+      );
+      expect(find.text('rs-a'), findsWidgets);
+      await tester.ensureVisible(
+        find.byKey(const ValueKey('surface_studio_reset_work_catalog')),
+      );
+      await tester.tap(
+        find.byKey(const ValueKey('surface_studio_reset_work_catalog')),
+      );
+      await tester.pump();
+      counters = find.byKey(const ValueKey('surface_studio_header_counters'));
+      expect(
+        find.descendant(of: counters, matching: find.text('0')),
+        findsNWidgets(3),
+      );
+      expect(
+        find.text('Le catalogue Surface est vide'),
+        findsOneWidget,
+      );
+      expect(
+        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
+        findsNothing,
+      );
+      expect(find.text('Aucune sélection'), findsOneWidget);
+    });
+
+    testWidgets(
+        '62.3 — reset depuis minimal : revient à Water, Grass absent, 1/1/1',
+        (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
+      );
+      final idF = find.byKey(const ValueKey('atlas_draft_id'));
+      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
+      final tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
+      await tester.ensureVisible(idF);
+      await tester.enterText(idF, 'grass-x');
+      await tester.enterText(nameF, 'Grass');
+      await tester.enterText(tsF, 'ts');
+      await tester.pump();
+      await tester.ensureVisible(
+        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
+      );
+      await tester.tap(
+        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
+      );
+      await tester.pump();
+      var counters = find.byKey(const ValueKey('surface_studio_header_counters'));
+      expect(
+        find.descendant(of: counters, matching: find.text('2')),
+        findsOneWidget,
+      );
+      expect(find.text('Water Atlas'), findsOneWidget);
+      expect(find.text('grass-x'), findsWidgets);
+      await tester.ensureVisible(
+        find.byKey(const ValueKey('surface_studio_reset_work_catalog')),
+      );
+      await tester.tap(
+        find.byKey(const ValueKey('surface_studio_reset_work_catalog')),
+      );
+      await tester.pump();
+      counters = find.byKey(const ValueKey('surface_studio_header_counters'));
+      expect(
+        find.descendant(of: counters, matching: find.text('1')),
+        findsNWidgets(3),
+      );
+      expect(find.text('Water Atlas'), findsOneWidget);
+      expect(
+        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
+        findsNothing,
+      );
+      expect(find.text('Water Isolated Loop'), findsOneWidget);
+      expect(find.text('Water Surface'), findsOneWidget);
+    });
+
+    testWidgets('62.4 — A puis B puis reset (source vide)', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
+      );
+      for (final row in <String>['lot62-a', 'lot62-b']) {
+        final idF = find.byKey(const ValueKey('atlas_draft_id'));
+        final nameF = find.byKey(const ValueKey('atlas_draft_name'));
+        final tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
+        await tester.ensureVisible(idF);
+        await tester.enterText(idF, row);
+        await tester.enterText(nameF, row);
+        await tester.enterText(tsF, 't');
+        await tester.pump();
+        await tester.ensureVisible(
+          find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
+        );
+        await tester.tap(
+          find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
+        );
+        await tester.pump();
+      }
+      var counters = find.byKey(const ValueKey('surface_studio_header_counters'));
+      expect(
+        find.descendant(of: counters, matching: find.text('2')),
+        findsOneWidget,
+      );
+      expect(find.text('lot62-a'), findsWidgets);
+      expect(find.text('lot62-b'), findsWidgets);
+      expect(find.text('Aucune sélection'), findsNothing);
+      expect(find.text('Atlas sélectionné'), findsWidgets);
+      await tester.ensureVisible(
+        find.byKey(const ValueKey('surface_studio_reset_work_catalog')),
+      );
+      await tester.tap(
+        find.byKey(const ValueKey('surface_studio_reset_work_catalog')),
+      );
+      await tester.pump();
+      counters = find.byKey(const ValueKey('surface_studio_header_counters'));
+      expect(
+        find.descendant(of: counters, matching: find.text('0')),
+        findsNWidgets(3),
+      );
+      expect(
+        find.text('Le catalogue Surface est vide'),
+        findsOneWidget,
+      );
+    });
+
+    testWidgets('62.5 — readModel parent change : resync, dirty off, X absent',
+        (tester) async {
+      final w = _wrap(
+        SurfaceStudioPanel(readModel: _emptyReadModel()),
+      );
+      await tester.pumpWidget(w);
+      final idF = find.byKey(const ValueKey('atlas_draft_id'));
+      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
+      final tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
+      await tester.ensureVisible(idF);
+      await tester.enterText(idF, 'ext-x');
+      await tester.enterText(nameF, 'X');
+      await tester.enterText(tsF, 't');
+      await tester.pump();
+      await tester.ensureVisible(
+        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
+      );
+      await tester.tap(
+        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
+      );
+      await tester.pump();
+      expect(
+        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
+        findsOneWidget,
+      );
+      expect(find.text('ext-x'), findsWidgets);
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioPanel(readModel: _minimalWaterReadModel()),
+        ),
+      );
+      await tester.pump();
+      expect(
+        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
+        findsNothing,
+      );
+      expect(find.text('Water Atlas'), findsOneWidget);
+      expect(find.text('Aucune sélection'), findsOneWidget);
+    });
+
+    testWidgets(
+        '62.6 — pas d’action fantôme Créer un atlas, vraie action présente',
+        (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
+      );
+      expect(find.text('Créer un atlas'), findsNothing);
+      expect(
+        find.text('Créer l’atlas dans le catalogue de travail'),
+        findsOneWidget,
+      );
+    });
+
+    testWidgets('62.7 — no save flow libellés interdits', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
+      );
+      await tester.ensureVisible(
+        find.byKey(const ValueKey('atlas_draft_id')),
+      );
+      await tester.enterText(
+        find.byKey(const ValueKey('atlas_draft_id')),
+        'z',
+      );
+      await tester.enterText(find.byKey(const ValueKey('atlas_draft_name')), 'N');
+      await tester.enterText(find.byKey(const ValueKey('atlas_draft_tileset')), 'T');
+      await tester.pump();
+      await tester.ensureVisible(
+        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
+      );
+      await tester.tap(
+        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
+      );
+      await tester.pump();
+      for (final s in <String>[
+        'Sauvegarder le projet',
+        'Enregistrer le projet',
+        'Save project',
+        'Write to disk',
+        'Écrire sur disque',
+      ]) {
+        expect(find.text(s), findsNothing);
+      }
+    });
   });
 }
 
diff --git a/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart b/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart
index 63e878a6..efa0ab1c 100644
--- a/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart
+++ b/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart
@@ -220,17 +220,18 @@ void main() {
         ),
         findsWidgets,
       );
+      expect(find.text('Créer un atlas'), findsNothing);
       expect(
-        find.text(SurfaceStudioPanel.actionCreateAtlasLabel),
+        find.text(SurfaceStudioPanel.actionImportVerticalAtlasLabel),
         findsOneWidget,
       );
-      final createButton = tester.widget<CupertinoButton>(
+      final importButton = tester.widget<CupertinoButton>(
         find.ancestor(
-          of: find.text(SurfaceStudioPanel.actionCreateAtlasLabel),
+          of: find.text(SurfaceStudioPanel.actionImportVerticalAtlasLabel),
           matching: find.byType(CupertinoButton),
         ),
       );
-      expect(createButton.onPressed, isNull);
+      expect(importButton.onPressed, isNull);
     });
 
     testWidgets('no Surface save button labels', (tester) async {
```

### Contenu intégral des fichiers modifiés (version worktree)

#### `packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart`

```dart
// Surface Studio — shell UI lecture seule (Lot 52).
//
// Consomme un [SurfaceStudioReadModel] déjà construit côté [map_core] : pas de
// re-diagnostic, pas de mutation manifest, pas d’I/O. Les actions futures sont
// désactivées ; seul le placeholder « Actions auteur » reste pour un lot ultérieur.
//
// Style : aligné sur [EditorChrome] / îlots de l’éditeur (pas de Card Material
// clair isolé) — cohérent avec World Explorer et le shell macOS.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';

import '../../ui/shared/cupertino_editor_widgets.dart';
import 'surface_studio_atlas_authoring_prep.dart';
import 'surface_studio_catalog_browser.dart';
import 'surface_studio_diagnostics_view.dart';
import 'surface_studio_selection.dart';
import 'surface_studio_selection_inspector.dart';
import 'surface_studio_selection_summary.dart';

SurfaceStudioSelection _selectionValidInReadModel(
  SurfaceStudioReadModel rm,
  SurfaceStudioSelection sel,
) {
  if (sel.isNone) return sel;
  if (sel.isAtlas) {
    for (final row in rm.atlases) {
      if (row.id == sel.id) return sel;
    }
  } else if (sel.isAnimation) {
    for (final row in rm.animations) {
      if (row.id == sel.id) return sel;
    }
  } else if (sel.isPreset) {
    for (final row in rm.presets) {
      if (row.id == sel.id) return sel;
    }
  }
  return const SurfaceStudioSelection.none();
}

/// Accent produit Surface Studio (même base que la tuile World Explorer).
const Color _surfaceStudioAccent = Color(0xFF2DD4BF);

/// Panneau présentationnel **lecture seule** pour Surface Studio.
class SurfaceStudioPanel extends StatefulWidget {
  const SurfaceStudioPanel({
    super.key,
    required this.readModel,
  });

  final SurfaceStudioReadModel readModel;

  static const String titleText = 'Surface Studio';
  static const String readOnlyBadgeText = 'Lecture seule';
  static const String productDescriptionText =
      'Préparez et contrôlez les surfaces animées du projet : eau, lave, glace, hautes herbes.';
  static const String placeholderActionsTitle = 'Actions auteur';
  static const String placeholderSoonText = 'Bientôt';
  static const String actionImportVerticalAtlasLabel =
      'Importer un atlas vertical';
  static const String workCatalogDirtyStateText =
      'Catalogue de travail modifié — sauvegarde projet non effectuée.';

  @override
  State<SurfaceStudioPanel> createState() => _SurfaceStudioPanelState();
}

class _SurfaceStudioPanelState extends State<SurfaceStudioPanel> {
  /// Sélection d’inspection : locale au widget, jamais écrite dans le manifest.
  SurfaceStudioSelection _selection = const SurfaceStudioSelection.none();
  late SurfaceStudioReadModel _workReadModel;

  @override
  void initState() {
    super.initState();
    _workReadModel = widget.readModel;
  }

  @override
  void didUpdateWidget(covariant SurfaceStudioPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.readModel != oldWidget.readModel) {
      setState(() {
        _workReadModel = widget.readModel;
        _selection = _selectionValidInReadModel(_workReadModel, _selection);
      });
    }
  }

  bool get _hasWorkCatalogChanges => _workReadModel != widget.readModel;

  @override
  Widget build(BuildContext context) {
    final s = _workReadModel.summary;
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const _StudioHeaderIcon(accent: _surfaceStudioAccent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  SurfaceStudioPanel.titleText,
                  style: TextStyle(
                    color: label,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.35,
                  ),
                ),
              ),
              const _ReadOnlyBadge(label: SurfaceStudioPanel.readOnlyBadgeText),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            SurfaceStudioPanel.productDescriptionText,
            style: TextStyle(
              color: subtle,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vous pouvez ajouter un atlas au catalogue de travail en mémoire. '
            'Aucune sauvegarde projet sur disque, pas d’édition ni suppression d’atlas existant.',
            style: TextStyle(
              color: subtle.withValues(alpha: 0.92),
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
          if (_hasWorkCatalogChanges) ...[
            const SizedBox(height: 10),
            Text(
              SurfaceStudioPanel.workCatalogDirtyStateText,
              key: const ValueKey('surface_studio_work_catalog_dirty_state'),
              style: TextStyle(
                color: _surfaceStudioAccent.withValues(alpha: 0.95),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            CupertinoButton(
              key: const ValueKey('surface_studio_reset_work_catalog'),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              onPressed: () {
                setState(() {
                  _workReadModel = widget.readModel;
                  _selection =
                      _selectionValidInReadModel(_workReadModel, _selection);
                });
              },
              child: const Text('Réinitialiser le catalogue de travail'),
            ),
          ],
          const SizedBox(height: 20),
          _CounterRow(
            atlas: s.atlasCount,
            animations: s.animationCount,
            presets: s.presetCount,
          ),
          const SizedBox(height: 12),
          SurfaceStudioSelectionSummary(selection: _selection),
          const SizedBox(height: 12),
          SurfaceStudioSelectionInspector(
            readModel: _workReadModel,
            selection: _selection,
          ),
          const SizedBox(height: 12),
          SurfaceStudioCatalogBrowser(
            readModel: _workReadModel,
            selection: _selection,
            onSelectionChanged: (v) {
              setState(() => _selection = v);
            },
          ),
          const SizedBox(height: 16),
          SurfaceStudioDiagnosticsView(readModel: _workReadModel),
          const SizedBox(height: 20),
          SurfaceStudioAtlasAuthoringPrep(
            readModel: _workReadModel,
            selection: _selection,
            onSurfaceCatalogChanged: (cat) {
              final newId = cat.atlases.isNotEmpty
                  ? cat.atlases.last.id
                  : '';
              setState(() {
                _workReadModel = buildSurfaceStudioReadModelFromCatalog(cat);
                if (newId.isNotEmpty) {
                  _selection = SurfaceStudioSelection.atlas(newId);
                }
              });
            },
          ),
          const SizedBox(height: 20),
          const _FutureActions(
            onImportVertical: null,
          ),
          const SizedBox(height: 20),
          const _SectionPlaceholder(
            title: SurfaceStudioPanel.placeholderActionsTitle,
          ),
        ],
      ),
    );
  }
}

class _StudioHeaderIcon extends StatelessWidget {
  const _StudioHeaderIcon({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    const hi = Color(0xFFFFFFFF);
    const lo = Color(0xFF120808);
    final onAccent =
        accent.computeLuminance() > 0.55 ? const Color(0xFF1A0A08) : hi;

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(hi, accent, 0.72)!,
            Color.lerp(accent, lo, 0.38)!,
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accent.withValues(alpha: 0.88),
          width: 1.2,
        ),
        boxShadow: EditorChrome.toolbarCapsuleShadows(context),
      ),
      alignment: Alignment.center,
      child: MacosIcon(
        Icons.auto_awesome_motion,
        color: onAccent,
        size: 22,
      ),
    );
  }
}

class _ReadOnlyBadge extends StatelessWidget {
  const _ReadOnlyBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    const accent = _surfaceStudioAccent;
    final fill = Color.lerp(
      EditorChrome.islandFillElevated(context),
      accent,
      0.14,
    )!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.65)),
        boxShadow: EditorChrome.toolbarCapsuleShadows(context),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _surfaceStudioAccent,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _CounterRow extends StatelessWidget {
  const _CounterRow({
    required this.atlas,
    required this.animations,
    required this.presets,
  });

  final int atlas;
  final int animations;
  final int presets;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      key: const ValueKey('surface_studio_header_counters'),
      spacing: 12,
      runSpacing: 10,
      children: [
        _CounterChip(label: 'Atlas', value: atlas),
        _CounterChip(label: 'Animations', value: animations),
        _CounterChip(label: 'Presets', value: presets),
      ],
    );
  }
}

class _CounterChip extends StatelessWidget {
  const _CounterChip({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);
    final labelColor = EditorChrome.primaryLabel(context);

    return _StudioCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: subtle,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$value',
            style: TextStyle(
              color: labelColor,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte interne : même relief que les tuiles inspecteur / sections.
class _StudioCard extends StatelessWidget {
  const _StudioCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: EditorChrome.elevatedPanelBackground(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: EditorChrome.editorIslandRim(context),
          width: 1,
        ),
        boxShadow: EditorChrome.sectionCardShadows(context),
      ),
      child: child,
    );
  }
}

class _FutureActions extends StatelessWidget {
  const _FutureActions({
    required this.onImportVertical,
  });

  final VoidCallback? onImportVertical;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions futures (non disponibles)',
          style: TextStyle(
            color: subtle,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _GhostAction(
              label: SurfaceStudioPanel.actionImportVerticalAtlasLabel,
              onPressed: onImportVertical,
            ),
          ],
        ),
      ],
    );
  }
}

class _GhostAction extends StatelessWidget {
  const _GhostAction({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);
    final enabled = onPressed != null;

    return Opacity(
      opacity: enabled ? 1.0 : 0.48,
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
        onPressed: onPressed,
        child: Text(
          label,
          style: TextStyle(
            color: enabled ? EditorChrome.inspectorJoyCyan : subtle,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }
}

class _SectionPlaceholder extends StatelessWidget {
  const _SectionPlaceholder({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return _StudioCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: label,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  SurfaceStudioPanel.placeholderSoonText,
                  style: TextStyle(
                    color: subtle,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          MacosIcon(
            CupertinoIcons.chevron_right,
            size: 16,
            color: subtle,
          ),
        ],
      ),
    );
  }
}

/// Adaptateur : construit le read model **sans** I/O à partir d’un [ProjectManifest].
class SurfaceStudioPanelFromManifest extends StatelessWidget {
  const SurfaceStudioPanelFromManifest({
    super.key,
    required this.manifest,
  });

  final ProjectManifest manifest;

  @override
  Widget build(BuildContext context) {
    return SurfaceStudioPanel(
      readModel: buildSurfaceStudioReadModel(manifest),
    );
  }
}
```

#### `packages/map_editor/test/surface_studio/surface_studio_panel_test.dart`

```dart
// Tests widget — Surface Studio panel (Lot 52).
// Imports `map_core` en API publique uniquement (pas de `map_core/src/...`).

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_panel.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_selection_inspector.dart';

void main() {
  group('SurfaceStudioPanel (Lot 52)', () {
    testWidgets('1. title Surface Studio is visible', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      expect(find.text('Surface Studio'), findsOneWidget);
    });

    testWidgets('2. read-only badge is visible', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      // Bandeau panneau + inspecteur (Lot 59).
      expect(find.text('Lecture seule'), findsNWidgets(2));
    });

    testWidgets('3. three counters are zero for empty catalog', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      final counters =
          find.byKey(const ValueKey('surface_studio_header_counters'));
      expect(
        find.descendant(of: counters, matching: find.text('0')),
        findsNWidgets(3),
      );
    });

    testWidgets('4. empty catalog shows empty state copy', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      expect(
        find.text('Le catalogue Surface est vide'),
        findsOneWidget,
      );
    });

    testWidgets('5. minimal catalog shows 1/1/1', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      final counters =
          find.byKey(const ValueKey('surface_studio_header_counters'));
      expect(
        find.descendant(of: counters, matching: find.text('1')),
        findsNWidgets(3),
      );
    });

    testWidgets('6. non-empty shows catalog browser content', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      expect(find.text('Catalogue Surface'), findsOneWidget);
      expect(find.text('Water Atlas'), findsOneWidget);
    });

    testWidgets('7. clean diagnostics for minimal coherent catalog',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      expect(find.text('Aucun diagnostic Surface'), findsOneWidget);
    });

    testWidgets('8. warning state when unused atlas', (tester) async {
      final rm = _warningReadModel();
      expect(rm.hasWarnings, isTrue);
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: rm)),
      );
      expect(find.text('Diagnostics Surface'), findsOneWidget);
      // Atlas orphelin + animation non référencée par un preset (presets vides)
      expect(find.textContaining('Avertissements : 2'), findsOneWidget);
      expect(find.text('Atlas inutilisé'), findsOneWidget);
      expect(find.text('Animation inutilisée'), findsOneWidget);
    });

    testWidgets('9. error state when preset animation missing', (tester) async {
      final rm = _errorReadModel();
      expect(rm.hasErrors, isTrue);
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: rm)),
      );
      expect(find.text('Diagnostics Surface'), findsOneWidget);
      expect(find.textContaining('Erreurs : 1'), findsOneWidget);
      expect(
        find.text('Animation manquante dans un preset'),
        findsOneWidget,
      );
    });

    testWidgets('10. future action label import visible (pas Créer un atlas)',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      expect(find.text('Créer un atlas'), findsNothing);
      expect(
        find.text(SurfaceStudioPanel.actionImportVerticalAtlasLabel),
        findsOneWidget,
      );
    });

    testWidgets('11. future import action disabled (onPressed null)',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      final b = tester.widget<CupertinoButton>(
        find.ancestor(
          of: find.text(SurfaceStudioPanel.actionImportVerticalAtlasLabel),
          matching: find.byType(CupertinoButton),
        ),
      );
      expect(b.onPressed, isNull);
    });

    testWidgets('12. section placeholder titles are visible', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      expect(find.text('Diagnostics Surface'), findsOneWidget);
      expect(find.text('Actions auteur'), findsOneWidget);
    });

    testWidgets('13. SurfaceStudioPanelFromManifest uses manifest catalog',
        (tester) async {
      final cat = _minimalWaterCatalog();
      final manifest = _manifest(cat);
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanelFromManifest(manifest: manifest)),
      );
      final counters =
          find.byKey(const ValueKey('surface_studio_header_counters'));
      expect(
        find.descendant(of: counters, matching: find.text('1')),
        findsNWidgets(3),
      );
    });

    testWidgets('14. manifest is not mutated after pump', (tester) async {
      final cat = _minimalWaterCatalog();
      final before = cat.atlases.length;
      final manifest = _manifest(cat);
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanelFromManifest(manifest: manifest)),
      );
      expect(manifest.surfaceCatalog.atlases.length, before);
    });

    testWidgets(
      '15. does not require provider setup — panel builds without ProviderScope',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SurfaceStudioPanel(readModel: _emptyReadModel()),
            ),
          ),
        );
        expect(find.text('Surface Studio'), findsOneWidget);
      },
    );

    testWidgets('16. content is in a scrollable', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('17. no internal domain type names in user-visible strings',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      expect(find.textContaining('ProjectSurfaceCatalog'), findsNothing);
      expect(find.textContaining('SurfaceStudioReadModel'), findsNothing);
      expect(
          find.textContaining('SurfaceVariantAnimationRefSet'), findsNothing);
    });

    testWidgets('18. error read model does not throw on build', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _errorReadModel())),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('19. warning read model does not throw on build',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _warningReadModel())),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('20. displayed counts match read model summary',
        (tester) async {
      final rm = _minimalWaterReadModel();
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: rm)),
      );
      expect(rm.summary.atlasCount, 1);
      expect(rm.summary.animationCount, 1);
      expect(rm.summary.presetCount, 1);
    });

    testWidgets('22. TextField seulement zone brouillon (Lot 60), pas dans inspecteur',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      expect(
        find.descendant(
          of: find.byKey(kSurfaceStudioSelectionInspectorKey),
          matching: find.byType(TextField),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byKey(kSurfaceStudioAtlasAuthoringPrepKey),
          matching: find.byType(TextField),
        ),
        findsWidgets,
      );
    });

    testWidgets('23. no save affordances', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      expect(find.textContaining('Sauvegarder'), findsNothing);
      expect(find.textContaining('Enregistrer'), findsNothing);
      expect(find.textContaining('Save'), findsNothing);
    });

    testWidgets('22. panel shows catalog browser for minimal catalog', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      expect(find.text('Catalogue Surface'), findsOneWidget);
      expect(find.text('Atlas Surface'), findsOneWidget);
      expect(find.text('Animations Surface'), findsOneWidget);
      expect(find.text('Presets Surface'), findsOneWidget);
      expect(find.text('Water Atlas'), findsOneWidget);
      expect(find.text('Water Isolated Loop'), findsOneWidget);
      expect(find.text('Water Surface'), findsOneWidget);
    });

    testWidgets('24. test file uses public map_core only (smoke)',
        (tester) async {
      // Vérification statique : seul `package:map_core/map_core.dart` est importé.
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      expect(find.text('Surface Studio'), findsOneWidget);
    });

    testWidgets('25. Lot 55 — clean diagnostics view in panel', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      expect(find.text('Diagnostics Surface'), findsOneWidget);
      expect(find.text('Aucun diagnostic Surface'), findsOneWidget);
    });

    testWidgets('26. Lot 55 — error diagnostics visible in panel',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _errorReadModel())),
      );
      expect(find.text('Diagnostics Surface'), findsOneWidget);
      expect(find.text('Erreurs'), findsOneWidget);
    });

    testWidgets('27. Lot 55 — browser and diagnostics cohabit (minimal cat)',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      expect(find.text('Catalogue Surface'), findsOneWidget);
      expect(find.text('Atlas Surface'), findsOneWidget);
      expect(find.text('Animations Surface'), findsOneWidget);
      expect(find.text('Presets Surface'), findsOneWidget);
      expect(find.text('Diagnostics Surface'), findsOneWidget);
      expect(find.text('Water Atlas'), findsOneWidget);
    });

    testWidgets(
        '48. Lot 57 — panel shows Atlas / Animations / Presets / Diagnostics',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      expect(find.text('Atlas Surface'), findsOneWidget);
      expect(find.text('Animations Surface'), findsOneWidget);
      expect(find.text('Presets Surface'), findsOneWidget);
      expect(find.text('Diagnostics Surface'), findsOneWidget);
    });

    testWidgets('58.21 — Aucune sélection au départ (catalogue minimal)',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      expect(find.text('Aucune sélection'), findsOneWidget);
    });

    testWidgets('58.22 — sélection atlas après tap', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      await tester.ensureVisible(find.text('Water Atlas'));
      await tester.tap(find.text('Water Atlas'));
      await tester.pump();
      expect(find.text('Atlas sélectionné'), findsWidgets);
      expect(find.text('water-atlas'), findsWidgets);
    });

    testWidgets('58.23 — sélection animation après tap', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      await tester.ensureVisible(find.text('Water Isolated Loop'));
      await tester.tap(find.text('Water Isolated Loop'));
      await tester.pump();
      expect(find.text('Animation sélectionnée'), findsWidgets);
      expect(find.text('water-isolated-loop'), findsWidgets);
    });

    testWidgets('58.24 — sélection preset après tap', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      await tester.ensureVisible(find.text('Water Surface'));
      await tester.tap(find.text('Water Surface'));
      await tester.pump();
      expect(find.text('Preset sélectionné'), findsWidgets);
      expect(find.text('water-surface'), findsWidgets);
    });

    testWidgets('58.25 — changement de sélection remplace la précédente',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      await tester.ensureVisible(find.text('Water Atlas'));
      await tester.tap(find.text('Water Atlas'));
      await tester.pump();
      await tester.ensureVisible(find.text('Water Isolated Loop'));
      await tester.tap(find.text('Water Isolated Loop'));
      await tester.pump();
      expect(find.text('Animation sélectionnée'), findsWidgets);
      final t = tester
          .widgetList<Text>(find.byType(Text))
          .map((e) => e.data ?? '')
          .join('\n');
      expect(t.contains('Atlas sélectionné'), isFalse);
    });

    testWidgets('58.26 — sélection ne mute pas surfaceCatalog', (tester) async {
      final cat = _minimalWaterCatalog();
      final manifest = _manifest(cat);
      final before = manifest.surfaceCatalog;
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanelFromManifest(manifest: manifest)),
      );
      await tester.ensureVisible(find.text('Water Atlas'));
      await tester.tap(find.text('Water Atlas'));
      await tester.pump();
      await tester.ensureVisible(find.text('Water Surface'));
      await tester.tap(find.text('Water Surface'));
      await tester.pump();
      expect(identical(manifest.surfaceCatalog, before), isTrue);
    });

    testWidgets('58.27 — pas de TextField dans inspecteur après sélections', (
        tester,
    ) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      await tester.ensureVisible(find.text('Water Atlas'));
      await tester.tap(find.text('Water Atlas'));
      await tester.pump();
      expect(
        find.descendant(
          of: find.byKey(kSurfaceStudioSelectionInspectorKey),
          matching: find.byType(TextField),
        ),
        findsNothing,
      );
    });

    testWidgets('58.28 — pas de libellés édition/save actifs', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      await tester.ensureVisible(find.text('Water Atlas'));
      await tester.tap(find.text('Water Atlas'));
      await tester.pump();
      for (final s in <String>[
        'Sauvegarder',
        'Enregistrer',
        'Modifier',
        'Supprimer',
        'Save',
        'Edit',
        'Delete',
      ]) {
        expect(find.text(s), findsNothing);
      }
    });

    testWidgets('59.20 — inspecteur none au départ', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      expect(find.text('Inspecteur Surface'), findsOneWidget);
      expect(find.text('Aucune sélection à inspecter'), findsOneWidget);
    });

    testWidgets('59.21 — inspecteur atlas après tap', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      await tester.ensureVisible(find.text('Water Atlas'));
      await tester.tap(find.text('Water Atlas'));
      await tester.pump();
      final insp = find.byKey(kSurfaceStudioSelectionInspectorKey);
      expect(
          find.descendant(of: insp, matching: find.text('Inspecteur Surface')),
          findsOneWidget);
      expect(
        find.descendant(of: insp, matching: find.text('Atlas sélectionné')),
        findsWidgets,
      );
      expect(
        find.descendant(
          of: insp,
          matching: find.textContaining('Identifiant : water-atlas'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('59.22 — inspecteur animation après tap', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      await tester.ensureVisible(find.text('Water Isolated Loop'));
      await tester.tap(find.text('Water Isolated Loop'));
      await tester.pump();
      final insp = find.byKey(kSurfaceStudioSelectionInspectorKey);
      expect(
        find.descendant(
          of: insp,
          matching: find.textContaining('Identifiant : water-isolated-loop'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('59.23 — inspecteur preset après tap', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      await tester.ensureVisible(find.text('Water Surface'));
      await tester.tap(find.text('Water Surface'));
      await tester.pump();
      final insp = find.byKey(kSurfaceStudioSelectionInspectorKey);
      expect(
        find.descendant(
          of: insp,
          matching: find.textContaining('Identifiant : water-surface'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('59.24 — changement de sélection met l’inspecteur à jour',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      await tester.ensureVisible(find.text('Water Atlas'));
      await tester.tap(find.text('Water Atlas'));
      await tester.pump();
      await tester.ensureVisible(find.text('Water Isolated Loop'));
      await tester.tap(find.text('Water Isolated Loop'));
      await tester.pump();
      final insp = find.byKey(kSurfaceStudioSelectionInspectorKey);
      expect(
        find.descendant(
          of: insp,
          matching: find.textContaining('Identifiant : water-isolated-loop'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: insp,
          matching: find.text('Atlas sélectionné'),
        ),
        findsNothing,
      );
    });

    testWidgets('59.25 — inspecteur ne mute pas le manifest', (tester) async {
      final cat = _minimalWaterCatalog();
      final manifest = _manifest(cat);
      final before = manifest.surfaceCatalog;
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanelFromManifest(manifest: manifest)),
      );
      await tester.ensureVisible(find.text('Water Atlas'));
      await tester.tap(find.text('Water Atlas'));
      await tester.pump();
      await tester.ensureVisible(find.text('Water Surface'));
      await tester.tap(find.text('Water Surface'));
      await tester.pump();
      expect(identical(manifest.surfaceCatalog, before), isTrue);
    });

    testWidgets(
        '59.26 — inspecteur read-only : aucun TextField (Lot 60 brouillon ok)',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      await tester.ensureVisible(find.text('Water Atlas'));
      await tester.tap(find.text('Water Atlas'));
      await tester.pump();
      expect(
        find.descendant(
          of: find.byKey(kSurfaceStudioSelectionInspectorKey),
          matching: find.byType(TextField),
        ),
        findsNothing,
      );
    });

    testWidgets('59.27 — pas de libellés édition/save (Lot 59)',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      await tester.ensureVisible(find.text('Water Surface'));
      await tester.tap(find.text('Water Surface'));
      await tester.pump();
      for (final s in <String>[
        'Sauvegarder',
        'Enregistrer',
        'Modifier',
        'Supprimer',
        'Save',
        'Edit',
        'Delete',
      ]) {
        expect(find.text(s), findsNothing);
      }
    });

    testWidgets('30. Lot 55 — surfaceCatalog unchanged after panel pump',
        (tester) async {
      final cat = _minimalWaterCatalog();
      final manifest = _manifest(cat);
      final before = manifest.surfaceCatalog;
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanelFromManifest(manifest: manifest)),
      );
      expect(identical(manifest.surfaceCatalog, before), isTrue);
    });

    testWidgets('60.1 — Préparation atlas (brouillon) visible', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      await tester.ensureVisible(find.text('Préparation atlas'));
      expect(find.text('Préparation atlas'), findsOneWidget);
      expect(
        find.text('Brouillon local non sauvegardé sur disque'),
        findsOneWidget,
      );
    });

    testWidgets('61.1 — action création atlas dans le catalogue de travail',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      await tester.ensureVisible(
        find.text('Créer l’atlas dans le catalogue de travail'),
      );
      expect(
        find.text('Créer l’atlas dans le catalogue de travail'),
        findsOneWidget,
      );
    });

    testWidgets(
        '61.2 — créer atlas (catalogue vide) : compteur atlas 1, browser, '
        'inspecteur',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
      await tester.ensureVisible(idF);
      await tester.enterText(idF, 'lot61-a');
      await tester.enterText(nameF, 'Lot61 A');
      await tester.enterText(tsF, 'tileset-x');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.pump();
      final counters =
          find.byKey(const ValueKey('surface_studio_header_counters'));
      expect(
        find.descendant(of: counters, matching: find.text('1')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: counters, matching: find.text('0')),
        findsNWidgets(2),
      );
      expect(find.text('Lot61 A'), findsWidgets);
      expect(find.text('Diagnostics Surface'), findsOneWidget);
    });

    testWidgets(
        '61.3 — créer second atlas : compteur 2, animations/presets inchangés',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
      await tester.ensureVisible(idF);
      await tester.enterText(idF, 'grass-a');
      await tester.enterText(nameF, 'Grass');
      await tester.enterText(tsF, 'ts-g');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.pump();
      final counters =
          find.byKey(const ValueKey('surface_studio_header_counters'));
      expect(
        find.descendant(of: counters, matching: find.text('2')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: counters, matching: find.text('1')),
        findsNWidgets(2),
      );
      expect(find.text('Water Atlas'), findsOneWidget);
      expect(find.text('Water Isolated Loop'), findsOneWidget);
      expect(find.text('Water Surface'), findsOneWidget);
      expect(find.text('grass-a'), findsWidgets);
    });

    testWidgets('62.0 — pas de dirty au départ (vide + minimal)', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      expect(
        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
        findsNothing,
      );
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      expect(
        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
        findsNothing,
      );
    });

    testWidgets('62.1 — dirty après création locale', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
      await tester.ensureVisible(idF);
      await tester.enterText(idF, 'dirty-a');
      await tester.enterText(nameF, 'D');
      await tester.enterText(tsF, 't');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.pump();
      expect(
        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
        findsOneWidget,
      );
      expect(
        find.textContaining('sauvegarde projet non effectuée'),
        findsWidgets,
      );
    });

    testWidgets(
        '62.2 — reset depuis catalogue vide : compteur 0, atlas absent, dirty off',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
      await tester.ensureVisible(idF);
      await tester.enterText(idF, 'rs-a');
      await tester.enterText(nameF, 'R');
      await tester.enterText(tsF, 't');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.pump();
      var counters = find.byKey(const ValueKey('surface_studio_header_counters'));
      expect(
        find.descendant(of: counters, matching: find.text('1')),
        findsOneWidget,
      );
      expect(find.text('rs-a'), findsWidgets);
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_reset_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_reset_work_catalog')),
      );
      await tester.pump();
      counters = find.byKey(const ValueKey('surface_studio_header_counters'));
      expect(
        find.descendant(of: counters, matching: find.text('0')),
        findsNWidgets(3),
      );
      expect(
        find.text('Le catalogue Surface est vide'),
        findsOneWidget,
      );
      expect(
        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
        findsNothing,
      );
      expect(find.text('Aucune sélection'), findsOneWidget);
    });

    testWidgets(
        '62.3 — reset depuis minimal : revient à Water, Grass absent, 1/1/1',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
      await tester.ensureVisible(idF);
      await tester.enterText(idF, 'grass-x');
      await tester.enterText(nameF, 'Grass');
      await tester.enterText(tsF, 'ts');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.pump();
      var counters = find.byKey(const ValueKey('surface_studio_header_counters'));
      expect(
        find.descendant(of: counters, matching: find.text('2')),
        findsOneWidget,
      );
      expect(find.text('Water Atlas'), findsOneWidget);
      expect(find.text('grass-x'), findsWidgets);
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_reset_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_reset_work_catalog')),
      );
      await tester.pump();
      counters = find.byKey(const ValueKey('surface_studio_header_counters'));
      expect(
        find.descendant(of: counters, matching: find.text('1')),
        findsNWidgets(3),
      );
      expect(find.text('Water Atlas'), findsOneWidget);
      expect(
        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
        findsNothing,
      );
      expect(find.text('Water Isolated Loop'), findsOneWidget);
      expect(find.text('Water Surface'), findsOneWidget);
    });

    testWidgets('62.4 — A puis B puis reset (source vide)', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      for (final row in <String>['lot62-a', 'lot62-b']) {
        final idF = find.byKey(const ValueKey('atlas_draft_id'));
        final nameF = find.byKey(const ValueKey('atlas_draft_name'));
        final tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
        await tester.ensureVisible(idF);
        await tester.enterText(idF, row);
        await tester.enterText(nameF, row);
        await tester.enterText(tsF, 't');
        await tester.pump();
        await tester.ensureVisible(
          find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
        );
        await tester.tap(
          find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
        );
        await tester.pump();
      }
      var counters = find.byKey(const ValueKey('surface_studio_header_counters'));
      expect(
        find.descendant(of: counters, matching: find.text('2')),
        findsOneWidget,
      );
      expect(find.text('lot62-a'), findsWidgets);
      expect(find.text('lot62-b'), findsWidgets);
      expect(find.text('Aucune sélection'), findsNothing);
      expect(find.text('Atlas sélectionné'), findsWidgets);
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_reset_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_reset_work_catalog')),
      );
      await tester.pump();
      counters = find.byKey(const ValueKey('surface_studio_header_counters'));
      expect(
        find.descendant(of: counters, matching: find.text('0')),
        findsNWidgets(3),
      );
      expect(
        find.text('Le catalogue Surface est vide'),
        findsOneWidget,
      );
    });

    testWidgets('62.5 — readModel parent change : resync, dirty off, X absent',
        (tester) async {
      final w = _wrap(
        SurfaceStudioPanel(readModel: _emptyReadModel()),
      );
      await tester.pumpWidget(w);
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
      await tester.ensureVisible(idF);
      await tester.enterText(idF, 'ext-x');
      await tester.enterText(nameF, 'X');
      await tester.enterText(tsF, 't');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.pump();
      expect(
        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
        findsOneWidget,
      );
      expect(find.text('ext-x'), findsWidgets);
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPanel(readModel: _minimalWaterReadModel()),
        ),
      );
      await tester.pump();
      expect(
        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
        findsNothing,
      );
      expect(find.text('Water Atlas'), findsOneWidget);
      expect(find.text('Aucune sélection'), findsOneWidget);
    });

    testWidgets(
        '62.6 — pas d’action fantôme Créer un atlas, vraie action présente',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      expect(find.text('Créer un atlas'), findsNothing);
      expect(
        find.text('Créer l’atlas dans le catalogue de travail'),
        findsOneWidget,
      );
    });

    testWidgets('62.7 — no save flow libellés interdits', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('atlas_draft_id')),
      );
      await tester.enterText(
        find.byKey(const ValueKey('atlas_draft_id')),
        'z',
      );
      await tester.enterText(find.byKey(const ValueKey('atlas_draft_name')), 'N');
      await tester.enterText(find.byKey(const ValueKey('atlas_draft_tileset')), 'T');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.pump();
      for (final s in <String>[
        'Sauvegarder le projet',
        'Enregistrer le projet',
        'Save project',
        'Write to disk',
        'Écrire sur disque',
      ]) {
        expect(find.text(s), findsNothing);
      }
    });
  });
}

Widget _wrap(Widget child) {
  // MacosApp + thème sombre : même [EditorChrome] que l’éditeur réel.
  return MacosApp(
    theme: MacosThemeData.dark(),
    home: ColoredBox(
      color: const Color(0xFF0F1218),
      child: child,
    ),
  );
}

SurfaceStudioReadModel _emptyReadModel() {
  return buildSurfaceStudioReadModelFromCatalog(ProjectSurfaceCatalog());
}

SurfaceStudioReadModel _minimalWaterReadModel() {
  return buildSurfaceStudioReadModelFromCatalog(_minimalWaterCatalog());
}

SurfaceStudioReadModel _warningReadModel() {
  return buildSurfaceStudioReadModelFromCatalog(_catalogWithUnusedAtlas());
}

SurfaceStudioReadModel _errorReadModel() {
  return buildSurfaceStudioReadModelFromCatalog(_catalogWithMissingAnimation());
}

SurfaceAtlasGeometry _geom() {
  return SurfaceAtlasGeometry(
    tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
    gridSize: SurfaceAtlasGridSize(columns: 2, rows: 2),
    layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
  );
}

ProjectSurfaceCatalog _minimalWaterCatalog() {
  final g = _geom();
  final atlas = ProjectSurfaceAtlas(
    id: 'water-atlas',
    name: 'Water Atlas',
    tilesetId: 'nature-tileset',
    geometry: g,
  );
  final frame = SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(atlasId: 'water-atlas', column: 0, row: 0),
    durationMs: 120,
  );
  final anim = ProjectSurfaceAnimation(
    id: 'water-isolated-loop',
    name: 'Water Isolated Loop',
    timeline: SurfaceAnimationTimeline(frames: [frame]),
  );
  final refs = SurfaceVariantAnimationRefSet(
    refs: [
      SurfaceVariantAnimationRef(
        role: SurfaceVariantRole.isolated,
        animationId: 'water-isolated-loop',
      ),
    ],
  );
  final preset = ProjectSurfacePreset(
    id: 'water-surface',
    name: 'Water Surface',
    variantAnimations: refs,
  );
  return ProjectSurfaceCatalog(
    atlases: [atlas],
    animations: [anim],
    presets: [preset],
  );
}

ProjectSurfaceCatalog _catalogWithUnusedAtlas() {
  final g = _geom();
  final used = ProjectSurfaceAtlas(
    id: 'used-atlas',
    name: 'U',
    tilesetId: 't',
    geometry: g,
  );
  final unused = ProjectSurfaceAtlas(
    id: 'orphan-atlas',
    name: 'O',
    tilesetId: 't',
    geometry: g,
  );
  final f = SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(atlasId: 'used-atlas', column: 0, row: 0),
    durationMs: 10,
  );
  final anim = ProjectSurfaceAnimation(
    id: 'a',
    name: 'a',
    timeline: SurfaceAnimationTimeline(frames: [f]),
  );
  return ProjectSurfaceCatalog(
    atlases: [used, unused],
    animations: [anim],
    presets: const [],
  );
}

ProjectSurfaceCatalog _catalogWithMissingAnimation() {
  final refs = SurfaceVariantAnimationRefSet(
    refs: [
      SurfaceVariantAnimationRef(
        role: SurfaceVariantRole.isolated,
        animationId: 'missing-anim',
      ),
    ],
  );
  return ProjectSurfaceCatalog(
    atlases: const [],
    animations: const [],
    presets: [
      ProjectSurfacePreset(
        id: 'p',
        name: 'p',
        variantAnimations: refs,
      ),
    ],
  );
}

ProjectManifest _manifest(ProjectSurfaceCatalog catalog) {
  return ProjectManifest(
    name: 'Test',
    maps: const [],
    tilesets: const [],
    surfaceCatalog: catalog,
  );
}
```

#### `packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart`

```dart
// Tests widget — entrée workspace Surface Studio (Lot 53).

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_panel.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_selection_inspector.dart';
import 'package:map_editor/src/ui/canvas/editor_canvas_host.dart';

import '../shell_chrome_test_harness.dart';

void main() {
  group('Surface Studio workspace entry (Lot 53)', () {
    test('EditorWorkspaceMode.surfaceStudio exists in enum', () {
      expect(
        EditorWorkspaceMode.values.contains(EditorWorkspaceMode.surfaceStudio),
        isTrue,
      );
    });

    testWidgets('entry title Surface Studio is visible in explorer',
        (tester) async {
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/surface_lot53',
          project: _buildProjectWithSurfaceCatalog(
            _minimalCoherentSurfaceCatalog(),
          ),
        ),
      );

      expect(find.text('Surface Studio'), findsWidgets);
    });

    testWidgets('subtitle mentions animated surfaces (Surfaces animées)', (
      tester,
    ) async {
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/surface_lot53',
          project: _buildProjectWithSurfaceCatalog(
            _minimalCoherentSurfaceCatalog(),
          ),
        ),
      );

      expect(
        find.textContaining('Surfaces animées', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('Terrain / Surface Studio / Path Library order in column', (
      tester,
    ) async {
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/surface_lot53',
          project: _buildProjectWithSurfaceCatalog(
            _minimalCoherentSurfaceCatalog(),
          ),
        ),
      );

      final terrain = find.text('Terrain Library');
      final path = find.text('Path Library');
      final surfaceEntry =
          find.byKey(const Key('surface-studio-workspace-entry'));
      expect(terrain, findsOneWidget);
      expect(path, findsOneWidget);
      expect(surfaceEntry, findsOneWidget);
      final yTerrain = tester.getTopLeft(terrain).dy;
      final ySurface = tester.getTopLeft(surfaceEntry).dy;
      final yPath = tester.getTopLeft(path).dy;
      expect(yTerrain, lessThan(ySurface));
      expect(ySurface, lessThan(yPath));
    });

    testWidgets('tap entry opens center panel with Lecture seule', (
      tester,
    ) async {
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/surface_lot53',
          project: _buildProjectWithSurfaceCatalog(
            _minimalCoherentSurfaceCatalog(),
          ),
        ),
      );

      await tester.ensureVisible(
        find.byKey(const Key('surface-studio-workspace-entry')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('surface-studio-workspace-entry')));
      await tester.pumpAndSettle();

      expect(find.text('Lecture seule'), findsNWidgets(2));
      expect(find.text('Inspecteur Surface'), findsOneWidget);
      expect(find.byType(SurfaceStudioPanel), findsOneWidget);
      expect(find.text('Catalogue Surface'), findsOneWidget);
      expect(find.text('Atlas Surface'), findsOneWidget);
      expect(find.text('Animations Surface'), findsOneWidget);
      expect(find.text('Presets Surface'), findsOneWidget);
      expect(find.text('Water Atlas'), findsOneWidget);
      expect(find.text('Water Isolated Loop'), findsOneWidget);
      expect(find.text('Water Surface'), findsOneWidget);
      expect(find.text('Diagnostics Surface'), findsOneWidget);
    });

    testWidgets('EditorCanvasHost builds SurfaceStudioPanel in surface mode', (
      tester,
    ) async {
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/surface_lot53_host',
          project: _buildProjectWithSurfaceCatalog(
            _minimalCoherentSurfaceCatalog(),
          ),
          workspaceMode: EditorWorkspaceMode.surfaceStudio,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(EditorCanvasHost), findsOneWidget);
      expect(find.byType(SurfaceStudioPanel), findsOneWidget);
    });

    testWidgets('works without an active map (no map required)',
        (tester) async {
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/surface_lot53_no_map',
          project: _buildProjectWithSurfaceCatalog(
            _minimalCoherentSurfaceCatalog(),
          ),
          activeMap: null,
          activeMapPath: null,
        ),
      );

      expect(
        find.text('Open a map to start building your world.'),
        findsOneWidget,
      );

      await tester.ensureVisible(
        find.byKey(const Key('surface-studio-workspace-entry')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('surface-studio-workspace-entry')));
      await tester.pumpAndSettle();

      expect(find.text('Lecture seule'), findsNWidgets(2));
    });

    testWidgets('panel shows 1/1/1 from manifest when catalog is minimal', (
      tester,
    ) async {
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/surface_lot53_counts',
          project: _buildProjectWithSurfaceCatalog(
            _minimalCoherentSurfaceCatalog(),
          ),
          workspaceMode: EditorWorkspaceMode.surfaceStudio,
        ),
      );

      await tester.pumpAndSettle();

      final counters =
          find.descendant(
        of: find.byType(SurfaceStudioPanel),
        matching: find.byKey(const ValueKey('surface_studio_header_counters')),
      );
      expect(
        find.descendant(of: counters, matching: find.text('1')),
        findsNWidgets(3),
      );
    });

    testWidgets(
        'read-only: actions désactivées; TextField seulement brouillon Lot 60',
        (tester) async {
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/surface_lot53_ro',
          project: _buildProjectWithSurfaceCatalog(
            _minimalCoherentSurfaceCatalog(),
          ),
          workspaceMode: EditorWorkspaceMode.surfaceStudio,
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(kSurfaceStudioSelectionInspectorKey),
          matching: find.byType(TextField),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byKey(kSurfaceStudioAtlasAuthoringPrepKey),
          matching: find.byType(TextField),
        ),
        findsWidgets,
      );
      expect(find.text('Créer un atlas'), findsNothing);
      expect(
        find.text(SurfaceStudioPanel.actionImportVerticalAtlasLabel),
        findsOneWidget,
      );
      final importButton = tester.widget<CupertinoButton>(
        find.ancestor(
          of: find.text(SurfaceStudioPanel.actionImportVerticalAtlasLabel),
          matching: find.byType(CupertinoButton),
        ),
      );
      expect(importButton.onPressed, isNull);
    });

    testWidgets('no Surface save button labels', (tester) async {
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/surface_lot53_save',
          project: _buildProjectWithSurfaceCatalog(
            _minimalCoherentSurfaceCatalog(),
          ),
          workspaceMode: EditorWorkspaceMode.surfaceStudio,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Sauvegarder Surface'), findsNothing);
      expect(find.textContaining('Enregistrer Surface'), findsNothing);
      expect(find.textContaining('Save Surface'), findsNothing);
    });

    testWidgets('Lot 59 — Inspecteur Surface visible en mode workspace', (
      tester,
    ) async {
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/surface_lot59_insp',
          project: _buildProjectWithSurfaceCatalog(
            _minimalCoherentSurfaceCatalog(),
          ),
          workspaceMode: EditorWorkspaceMode.surfaceStudio,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Inspecteur Surface'), findsOneWidget);
    });

    testWidgets('no internal type names in visible shell copy', (tester) async {
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/surface_lot53_copy',
          project: _buildProjectWithSurfaceCatalog(
            _minimalCoherentSurfaceCatalog(),
          ),
          workspaceMode: EditorWorkspaceMode.surfaceStudio,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('ProjectSurfaceCatalog'), findsNothing);
      expect(find.textContaining('SurfaceStudioReadModel'), findsNothing);
      expect(
          find.textContaining('SurfaceVariantAnimationRefSet'), findsNothing);
    });
  });
}

// --- Même minimal catalogue qu’au test Lot 52 (1 atlas, 1 anim, 1 preset) ---

ProjectSurfaceCatalog _minimalCoherentSurfaceCatalog() {
  final g = SurfaceAtlasGeometry(
    tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
    gridSize: SurfaceAtlasGridSize(columns: 2, rows: 2),
    layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
  );
  final atlas = ProjectSurfaceAtlas(
    id: 'water-atlas',
    name: 'Water Atlas',
    tilesetId: 'nature-tileset',
    geometry: g,
  );
  final frame = SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(atlasId: 'water-atlas', column: 0, row: 0),
    durationMs: 120,
  );
  final anim = ProjectSurfaceAnimation(
    id: 'water-isolated-loop',
    name: 'Water Isolated Loop',
    timeline: SurfaceAnimationTimeline(frames: <SurfaceAnimationFrame>[frame]),
  );
  final refs = SurfaceVariantAnimationRefSet(
    refs: <SurfaceVariantAnimationRef>[
      SurfaceVariantAnimationRef(
        role: SurfaceVariantRole.isolated,
        animationId: 'water-isolated-loop',
      ),
    ],
  );
  final preset = ProjectSurfacePreset(
    id: 'water-surface',
    name: 'Water Surface',
    variantAnimations: refs,
  );
  return ProjectSurfaceCatalog(
    atlases: <ProjectSurfaceAtlas>[atlas],
    animations: <ProjectSurfaceAnimation>[anim],
    presets: <ProjectSurfacePreset>[preset],
  );
}

ProjectManifest _buildProjectWithSurfaceCatalog(ProjectSurfaceCatalog c) {
  return ProjectManifest(
    name: 'Surface Lot53',
    maps: <ProjectMapEntry>[],
    tilesets: <ProjectTilesetEntry>[],
    surfaceCatalog: c,
  );
}
```



### Fichier créé (rapport) — preuve

Le rapport est le fichier `reports/surface/surface_engine_lot_62_surface_studio_work_catalog_state_hardening.md`. Avant le premier suivi git, l’équivalent `git diff --no-index /dev/null` de ce fichier est entièrement contenu par le texte de ce document une fois le fichier enregistré sur disque ; le `git status` final liste ce chemin en `??` tant qu’il n’est pas indexé.

## Git status initial

Avant toute modification de fichier pour le Lot 62 sur cette session, l’arbre de travail était cohérent avec le commit `4977cfa3` (Lot 61) sans fichiers en cours pour les chemins de ce lot.

```text
Sortie : <vide>
```

(aucune modification locale sur les cibles `surface_studio_*` non commitée au moment de la prise d’implémentation Lot 62.)

## Git status final

```text
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
 M packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
 M packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart
?? reports/surface/surface_engine_lot_62_surface_studio_work_catalog_state_hardening.md
```

## Changements préexistants

Aucun autre lot mélangé : les seuls `M` portent sur le durcissement Lot 62.

## Changements du Lot 62

- `surface_studio_panel.dart` : état source vs travail, bandeau dirty, reset, resync, actions futures.
- Tests panel et workspace ; ce rapport.

## Périmètre explicitement non touché

- `map_core` non modifié
- Aucun `ProjectManifest` / `copyWith(surfaceCatalog:)` / `updateProjectManifestSurfaceCatalog` / `replaceProjectManifestSurfaceCatalog` / `clearProjectManifestSurfaceCatalog` dans le code ajouté
- Pas de `build_runner` ; pas de generated modifié ; pas de fixtures `map_core` modifiées
- Pas de provider, repository, service, sauvegarde disque, runtime, `SurfaceLayer`, import vertical
- Aucune animation/preset modifié par l’orchestration (seul le catalogue de travail copie des listes existantes)

## Vérification fichiers temporaires

Commande : `find . -type f \( -name '_gen_*.py' -o -name 'build_*.py' -o -name '*.tmp' \) -print` (racine repo)

```text
Sortie : <vide>
```

## Vérification mojibake

Aucun motif d’encodage UTF-8 brisé listé par la spec du lot n’apparaît volontairement dans ce texte (caractères accentués corrects en UTF-8).

## Auto-review

- Sauvegarde disque ajoutée : Non.
- `project.json` écrit : Non.
- `map_core` modifié : Non.
- Catalogue source muté (props parent) : Non.
- Catalogue de travail distingué (travail vs `widget.readModel`) : Oui, par `_workReadModel` et comparaison.
- Dirty state visible après création : Oui.
- Reset restaure la source : Oui.
- Plusieurs créations puis reset : testé.
- `didUpdateWidget` / changement de readModel parent : testé (62.5).
- Action fantôme exacte « Créer un atlas » : retirée de l’UI.
- Tests ciblés : Oui, panel 57 cas dont Lot 62 ; suite `test/surface_studio` : `+247` `All tests passed!`
- `flutter analyze` ciblé : Oui, sans issue.
- Rapport (diffs + contenus + commandes) : Oui, hors bloc récursif tronqué.
- Aucune commande Git d’écriture (agent) : Oui.

## Critique du prompt

Le cahier des charges est aligné sur une seule feature (état local). L’intégralité des contenus de fichiers dans l’Evidence Pack gonfle fortement le Markdown ; le diff `/dev/null` complet du rapport serait redondant avec le fichier lui-même, d’où la note de preuve par statut `??` et auto-contenu.
