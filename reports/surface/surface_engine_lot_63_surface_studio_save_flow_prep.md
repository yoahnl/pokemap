# Lot 63 — Surface Studio Save Flow Prep V0

## Résumé exécutif

Le panneau Surface Studio expose un paramètre optionnel `onSurfaceCatalogSaveRequested` (type `ValueChanged<ProjectSurfaceCatalog>?`). Lorsque le catalogue de travail diffère de la source (`readModel`) et qu’un callback est fourni, l’utilisateur voit l’action « Préparer la sauvegarde du catalogue Surface », une note d’absence d’écriture disque, et après un clic le catalogue de travail courant est transmis une fois au parent avec un accusé de réception local. Le dirty state n’est pas effacé par ce clic. Sans callback, un message indique que la sauvegarde n’est pas connectée. Aucune persistance disque, aucun `map_core` modifié, aucun provider ni repository.

## Périmètre

Contrat UI et callback de préparation de sauvegarde uniquement ; tests de contrat dans `surface_studio_panel_test.dart`. Pas de `build_runner`, pas de générés, pas d’appels `updateProjectManifestSurfaceCatalog` / `replace` / `clear` / `copyWith(surfaceCatalog: ...)`.

## Git status initial

Cette reprise de session n’a pas conservé la sortie de `git status --short --untracked-files=all` exécutée avant la première écriture de fichier du Lot 63. Pour un lot exécuté en une fois, l’exigence est de capturer ce statut avant toute modification.

## Git status final

```
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
 M packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
?? reports/surface/surface_engine_lot_63_surface_studio_save_flow_prep.md
```

## git diff --stat (final)

```
 .../surface_studio/surface_studio_panel.dart       |  65 +++++
 .../surface_studio/surface_studio_panel_test.dart  | 261 +++++++++++++++++++++
 2 files changed, 326 insertions(+)
```

## Audit initial

Comportement Lot 62 conservé : `_workReadModel` et `widget.readModel` pour le dirty, reset et resync dans `didUpdateWidget`. Le Lot 63 ajoute uniquement le callback, la note et le bandeau d’action dans la zone existante `if (_hasWorkCatalogChanges)`.

## Implémentation

- `SurfaceStudioPanel` : `onSurfaceCatalogSaveRequested` optionnel ; constantes de libellés ; `_saveFlowPrepNote` ; `_onSurfaceCatalogSavePrep` appelle `cb(_workReadModel.catalog)` une fois, sans toucher `widget.readModel` ; accusé textuel ; nettoyage de la note sur resync parent, reset, ou nouvelle émission de catalogue depuis le brouillon d’atlas.

## Fichiers créés

- `reports/surface/surface_engine_lot_63_surface_studio_save_flow_prep.md` (ce rapport)

## Fichiers modifiés

- `packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart`
- `packages/map_editor/test/surface_studio/surface_studio_panel_test.dart`

## Fichiers supprimés

Sortie : <vide>

## Tests lancés

Commande (panel Lot 63) : `cd packages/map_editor && flutter test test/surface_studio/surface_studio_panel_test.dart` — ligne finale : `00:11 +63: All tests passed!`.

Commande (atlas prep + workspace) : `cd packages/map_editor && flutter test test/surface_studio/surface_studio_atlas_authoring_prep_test.dart test/surface_studio/surface_studio_workspace_entry_test.dart` — ligne finale : `00:07 +30: All tests passed!`.

Commande (sélection) : `cd packages/map_editor && flutter test test/surface_studio/surface_studio_selection_inspector_test.dart test/surface_studio/surface_studio_selection_interaction_test.dart test/surface_studio/surface_studio_selection_summary_test.dart test/surface_studio/surface_studio_selection_test.dart` — ligne finale : `00:02 +37: All tests passed!`.

Commande (`map_core` read model) : `cd packages/map_core && dart test test/surface_studio_read_model_test.dart` — ligne finale : `00:00 +30: All tests passed!`.

Commande (suite `test/surface_studio` groupée) : `cd packages/map_editor && flutter test test/surface_studio` — ligne finale : `00:14 +253: All tests passed!`.

## Analyse lancée

Commande : `cd packages/map_editor && flutter analyze lib/src/features/surface_studio test/surface_studio`.

Sortie :
```
Analyzing 2 items...
No issues found! (ran in 4.0s)
```

## Vérification fichiers temporaires

Commande : `find . -type f \( -name '_gen_*.py' -o -name 'build_*.py' -o -name '*.tmp' \) -print` depuis la racine du dépôt.

Sortie : <vide>

## Résultats

Tous les tests listés en section « Tests lancés » ont abouti. `flutter analyze` ciblé est sans avertissement ni erreur.

## Changements préexistants

Aucune autre modification de fichier suivie n’est mélangée au diff du Lot 63 sur cette branche : `git status` ne montre que les deux chemins `map_editor` listés.

## Changements du Lot 63

Callback optionnel, UI de préparation de sauvegarde dans le bandeau dirty, accusé de transmission, six tests d’intégration (groupe `SurfaceStudioPanel (Lot 63)`), et extension de la liste de libellés interdits dans le test 62.7.

## Evidence Pack

### Diff complet (fichiers modifiés)

```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart b/packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
index 9b3c9d6f..abbb5e8f 100644
--- a/packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
+++ b/packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
@@ -49,9 +49,11 @@ class SurfaceStudioPanel extends StatefulWidget {
   const SurfaceStudioPanel({
     super.key,
     required this.readModel,
+    this.onSurfaceCatalogSaveRequested,
   });
 
   final SurfaceStudioReadModel readModel;
+  final ValueChanged<ProjectSurfaceCatalog>? onSurfaceCatalogSaveRequested;
 
   static const String titleText = 'Surface Studio';
   static const String readOnlyBadgeText = 'Lecture seule';
@@ -63,6 +65,14 @@ class SurfaceStudioPanel extends StatefulWidget {
       'Importer un atlas vertical';
   static const String workCatalogDirtyStateText =
       'Catalogue de travail modifié — sauvegarde projet non effectuée.';
+  static const String savePrepActionLabel =
+      'Préparer la sauvegarde du catalogue Surface';
+  static const String savePrepTransmittedNote =
+      'Catalogue de travail transmis au parent.';
+  static const String savePrepNotConnectedNote =
+      'Sauvegarde non connectée dans ce contexte.';
+  static const String savePrepNoDiskNote =
+      'Aucune écriture disque ne sera effectuée par Surface Studio.';
 
   @override
   State<SurfaceStudioPanel> createState() => _SurfaceStudioPanelState();
@@ -72,6 +82,7 @@ class _SurfaceStudioPanelState extends State<SurfaceStudioPanel> {
   /// Sélection d’inspection : locale au widget, jamais écrite dans le manifest.
   SurfaceStudioSelection _selection = const SurfaceStudioSelection.none();
   late SurfaceStudioReadModel _workReadModel;
+  String? _saveFlowPrepNote;
 
   @override
   void initState() {
@@ -86,12 +97,24 @@ class _SurfaceStudioPanelState extends State<SurfaceStudioPanel> {
       setState(() {
         _workReadModel = widget.readModel;
         _selection = _selectionValidInReadModel(_workReadModel, _selection);
+        _saveFlowPrepNote = null;
       });
     }
   }
 
   bool get _hasWorkCatalogChanges => _workReadModel != widget.readModel;
 
+  void _onSurfaceCatalogSavePrep() {
+    final cb = widget.onSurfaceCatalogSaveRequested;
+    if (cb == null) {
+      return;
+    }
+    cb(_workReadModel.catalog);
+    setState(() {
+      _saveFlowPrepNote = SurfaceStudioPanel.savePrepTransmittedNote;
+    });
+  }
+
   @override
   Widget build(BuildContext context) {
     final s = _workReadModel.summary;
@@ -154,6 +177,46 @@ class _SurfaceStudioPanelState extends State<SurfaceStudioPanel> {
                 fontWeight: FontWeight.w600,
               ),
             ),
+            const SizedBox(height: 4),
+            Text(
+              SurfaceStudioPanel.savePrepNoDiskNote,
+              style: TextStyle(
+                color: subtle.withValues(alpha: 0.9),
+                fontSize: 11,
+              ),
+            ),
+            const SizedBox(height: 6),
+            if (widget.onSurfaceCatalogSaveRequested != null) ...[
+              CupertinoButton(
+                key: const ValueKey('surface_studio_save_prep_catalog'),
+                padding:
+                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
+                onPressed: _onSurfaceCatalogSavePrep,
+                child: const Text(SurfaceStudioPanel.savePrepActionLabel),
+              ),
+            ] else ...[
+              Text(
+                key: const ValueKey('surface_studio_save_prep_not_connected'),
+                SurfaceStudioPanel.savePrepNotConnectedNote,
+                style: TextStyle(
+                  color: subtle.withValues(alpha: 0.95),
+                  fontSize: 11,
+                  fontStyle: FontStyle.italic,
+                ),
+              ),
+            ],
+            if (_saveFlowPrepNote != null) ...[
+              const SizedBox(height: 6),
+              Text(
+                _saveFlowPrepNote!,
+                key: const ValueKey('surface_studio_save_prep_transmitted'),
+                style: TextStyle(
+                  color: _surfaceStudioAccent.withValues(alpha: 0.9),
+                  fontSize: 11,
+                  fontWeight: FontWeight.w600,
+                ),
+              ),
+            ],
             const SizedBox(height: 6),
             CupertinoButton(
               key: const ValueKey('surface_studio_reset_work_catalog'),
@@ -163,6 +226,7 @@ class _SurfaceStudioPanelState extends State<SurfaceStudioPanel> {
                   _workReadModel = widget.readModel;
                   _selection =
                       _selectionValidInReadModel(_workReadModel, _selection);
+                  _saveFlowPrepNote = null;
                 });
               },
               child: const Text('Réinitialiser le catalogue de travail'),
@@ -200,6 +264,7 @@ class _SurfaceStudioPanelState extends State<SurfaceStudioPanel> {
                   ? cat.atlases.last.id
                   : '';
               setState(() {
+                _saveFlowPrepNote = null;
                 _workReadModel = buildSurfaceStudioReadModelFromCatalog(cat);
                 if (newId.isNotEmpty) {
                   _selection = SurfaceStudioSelection.atlas(newId);
diff --git a/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart b/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
index f0fcfb75..4a47f9e9 100644
--- a/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
+++ b/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
@@ -960,6 +960,7 @@ void main() {
       for (final s in <String>[
         'Sauvegarder le projet',
         'Enregistrer le projet',
+        'Sauvegarder maintenant',
         'Save project',
         'Write to disk',
         'Écrire sur disque',
@@ -968,6 +969,266 @@ void main() {
       }
     });
   });
+
+  group('SurfaceStudioPanel (Lot 63)', () {
+    testWidgets('63.1 — sans modification : pas d’action préparation, callback jamais',
+        (tester) async {
+      var calls = 0;
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioPanel(
+            readModel: _minimalWaterReadModel(),
+            onSurfaceCatalogSaveRequested: (_) => calls++,
+          ),
+        ),
+      );
+      expect(
+        find.byKey(const ValueKey('surface_studio_save_prep_catalog')),
+        findsNothing,
+      );
+      expect(
+        find.text(SurfaceStudioPanel.savePrepActionLabel),
+        findsNothing,
+      );
+      expect(calls, 0);
+    });
+
+    testWidgets(
+        '63.2 — dirty + callback : action, un appel, catalogue complet, dirty et accusé',
+        (tester) async {
+      ProjectSurfaceCatalog? received;
+      var calls = 0;
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioPanel(
+            readModel: _emptyReadModel(),
+            onSurfaceCatalogSaveRequested: (c) {
+              calls++;
+              received = c;
+            },
+          ),
+        ),
+      );
+      final idF = find.byKey(const ValueKey('atlas_draft_id'));
+      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
+      final tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
+      await tester.ensureVisible(idF);
+      await tester.enterText(idF, 'prep-one');
+      await tester.enterText(nameF, 'P');
+      await tester.enterText(tsF, 't');
+      await tester.pump();
+      await tester.ensureVisible(
+        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
+      );
+      await tester.tap(
+        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
+      );
+      await tester.pump();
+      final prep = find.byKey(const ValueKey('surface_studio_save_prep_catalog'));
+      expect(prep, findsOneWidget);
+      await tester.ensureVisible(prep);
+      await tester.tap(prep);
+      await tester.pump();
+      expect(calls, 1);
+      expect(received, isNotNull);
+      expect(received!.atlases.length, 1);
+      expect(received!.atlases.first.id, 'prep-one');
+      expect(
+        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
+        findsOneWidget,
+      );
+      expect(
+        find.text(SurfaceStudioPanel.savePrepTransmittedNote),
+        findsOneWidget,
+      );
+    });
+
+    testWidgets('63.3 — sans callback : stable, message not connected, pas de bouton',
+        (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
+      );
+      final idF = find.byKey(const ValueKey('atlas_draft_id'));
+      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
+      final tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
+      await tester.ensureVisible(idF);
+      await tester.enterText(idF, 'nccb');
+      await tester.enterText(nameF, 'N');
+      await tester.enterText(tsF, 't');
+      await tester.pump();
+      await tester.ensureVisible(
+        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
+      );
+      await tester.tap(
+        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
+      );
+      await tester.pump();
+      expect(tester.takeException(), isNull);
+      expect(
+        find.text(SurfaceStudioPanel.savePrepNotConnectedNote),
+        findsOneWidget,
+      );
+      expect(
+        find.byKey(const ValueKey('surface_studio_save_prep_catalog')),
+        findsNothing,
+      );
+    });
+
+    testWidgets('63.4 — resync parent : dirty off, atlas source, pas d’accusé',
+        (tester) async {
+      ProjectSurfaceCatalog? out;
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioPanel(
+            readModel: _emptyReadModel(),
+            onSurfaceCatalogSaveRequested: (c) => out = c,
+          ),
+        ),
+      );
+      var idF = find.byKey(const ValueKey('atlas_draft_id'));
+      var nameF = find.byKey(const ValueKey('atlas_draft_name'));
+      var tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
+      await tester.ensureVisible(idF);
+      await tester.enterText(idF, 'sync-x');
+      await tester.enterText(nameF, 'S');
+      await tester.enterText(tsF, 't');
+      await tester.pump();
+      await tester.ensureVisible(
+        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
+      );
+      await tester.tap(
+        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
+      );
+      await tester.pump();
+      final prep = find.byKey(const ValueKey('surface_studio_save_prep_catalog'));
+      await tester.ensureVisible(prep);
+      await tester.tap(prep);
+      await tester.pump();
+      expect(out, isNotNull);
+      final synced = buildSurfaceStudioReadModelFromCatalog(out!);
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioPanel(
+            readModel: synced,
+            onSurfaceCatalogSaveRequested: (c) => out = c,
+          ),
+        ),
+      );
+      await tester.pump();
+      expect(
+        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
+        findsNothing,
+      );
+      expect(
+        find.text(SurfaceStudioPanel.savePrepTransmittedNote),
+        findsNothing,
+      );
+      expect(find.text('sync-x'), findsWidgets);
+    });
+
+    testWidgets('63.5 — reset après préparation : clean, accusé nettoyé, vide',
+        (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioPanel(
+            readModel: _emptyReadModel(),
+            onSurfaceCatalogSaveRequested: (_) {},
+          ),
+        ),
+      );
+      var idF = find.byKey(const ValueKey('atlas_draft_id'));
+      var nameF = find.byKey(const ValueKey('atlas_draft_name'));
+      var tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
+      await tester.ensureVisible(idF);
+      await tester.enterText(idF, 'reset-p');
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
+      final prep = find.byKey(const ValueKey('surface_studio_save_prep_catalog'));
+      await tester.ensureVisible(prep);
+      await tester.tap(prep);
+      await tester.pump();
+      expect(
+        find.text(SurfaceStudioPanel.savePrepTransmittedNote),
+        findsOneWidget,
+      );
+      await tester.ensureVisible(
+        find.byKey(const ValueKey('surface_studio_reset_work_catalog')),
+      );
+      await tester.tap(
+        find.byKey(const ValueKey('surface_studio_reset_work_catalog')),
+      );
+      await tester.pump();
+      expect(
+        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
+        findsNothing,
+      );
+      expect(
+        find.text(SurfaceStudioPanel.savePrepTransmittedNote),
+        findsNothing,
+      );
+      final counters = find.byKey(const ValueKey('surface_studio_header_counters'));
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
+    testWidgets('63.6 — A puis B puis préparation : ordre des atlas', (tester) async {
+      ProjectSurfaceCatalog? got;
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioPanel(
+            readModel: _emptyReadModel(),
+            onSurfaceCatalogSaveRequested: (c) => got = c,
+          ),
+        ),
+      );
+      for (final row in <(String, String, String)>[
+        ('lot63-a', 'A', 'ta'),
+        ('lot63-b', 'B', 'tb'),
+      ]) {
+        final idF = find.byKey(const ValueKey('atlas_draft_id'));
+        final nameF = find.byKey(const ValueKey('atlas_draft_name'));
+        final tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
+        await tester.ensureVisible(idF);
+        await tester.enterText(idF, row.$1);
+        await tester.enterText(nameF, row.$2);
+        await tester.enterText(tsF, row.$3);
+        await tester.pump();
+        await tester.ensureVisible(
+          find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
+        );
+        await tester.tap(
+          find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
+        );
+        await tester.pump();
+      }
+      final prep = find.byKey(const ValueKey('surface_studio_save_prep_catalog'));
+      await tester.ensureVisible(prep);
+      await tester.tap(prep);
+      await tester.pump();
+      expect(got, isNotNull);
+      expect(got!.atlases.length, 2);
+      expect(got!.atlases[0].id, 'lot63-a');
+      expect(got!.atlases[1].id, 'lot63-b');
+      expect(
+        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
+        findsOneWidget,
+      );
+    });
+  });
 }
 
 Widget _wrap(Widget child) {
```

### Fichier modifié — contenu complet `surface_studio_panel.dart`

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
    this.onSurfaceCatalogSaveRequested,
  });

  final SurfaceStudioReadModel readModel;
  final ValueChanged<ProjectSurfaceCatalog>? onSurfaceCatalogSaveRequested;

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
  static const String savePrepActionLabel =
      'Préparer la sauvegarde du catalogue Surface';
  static const String savePrepTransmittedNote =
      'Catalogue de travail transmis au parent.';
  static const String savePrepNotConnectedNote =
      'Sauvegarde non connectée dans ce contexte.';
  static const String savePrepNoDiskNote =
      'Aucune écriture disque ne sera effectuée par Surface Studio.';

  @override
  State<SurfaceStudioPanel> createState() => _SurfaceStudioPanelState();
}

class _SurfaceStudioPanelState extends State<SurfaceStudioPanel> {
  /// Sélection d’inspection : locale au widget, jamais écrite dans le manifest.
  SurfaceStudioSelection _selection = const SurfaceStudioSelection.none();
  late SurfaceStudioReadModel _workReadModel;
  String? _saveFlowPrepNote;

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
        _saveFlowPrepNote = null;
      });
    }
  }

  bool get _hasWorkCatalogChanges => _workReadModel != widget.readModel;

  void _onSurfaceCatalogSavePrep() {
    final cb = widget.onSurfaceCatalogSaveRequested;
    if (cb == null) {
      return;
    }
    cb(_workReadModel.catalog);
    setState(() {
      _saveFlowPrepNote = SurfaceStudioPanel.savePrepTransmittedNote;
    });
  }

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
            const SizedBox(height: 4),
            Text(
              SurfaceStudioPanel.savePrepNoDiskNote,
              style: TextStyle(
                color: subtle.withValues(alpha: 0.9),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 6),
            if (widget.onSurfaceCatalogSaveRequested != null) ...[
              CupertinoButton(
                key: const ValueKey('surface_studio_save_prep_catalog'),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                onPressed: _onSurfaceCatalogSavePrep,
                child: const Text(SurfaceStudioPanel.savePrepActionLabel),
              ),
            ] else ...[
              Text(
                key: const ValueKey('surface_studio_save_prep_not_connected'),
                SurfaceStudioPanel.savePrepNotConnectedNote,
                style: TextStyle(
                  color: subtle.withValues(alpha: 0.95),
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            if (_saveFlowPrepNote != null) ...[
              const SizedBox(height: 6),
              Text(
                _saveFlowPrepNote!,
                key: const ValueKey('surface_studio_save_prep_transmitted'),
                style: TextStyle(
                  color: _surfaceStudioAccent.withValues(alpha: 0.9),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 6),
            CupertinoButton(
              key: const ValueKey('surface_studio_reset_work_catalog'),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              onPressed: () {
                setState(() {
                  _workReadModel = widget.readModel;
                  _selection =
                      _selectionValidInReadModel(_workReadModel, _selection);
                  _saveFlowPrepNote = null;
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
                _saveFlowPrepNote = null;
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

### Fichier modifié — contenu complet `surface_studio_panel_test.dart`

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
        'Sauvegarder maintenant',
        'Save project',
        'Write to disk',
        'Écrire sur disque',
      ]) {
        expect(find.text(s), findsNothing);
      }
    });
  });

  group('SurfaceStudioPanel (Lot 63)', () {
    testWidgets('63.1 — sans modification : pas d’action préparation, callback jamais',
        (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPanel(
            readModel: _minimalWaterReadModel(),
            onSurfaceCatalogSaveRequested: (_) => calls++,
          ),
        ),
      );
      expect(
        find.byKey(const ValueKey('surface_studio_save_prep_catalog')),
        findsNothing,
      );
      expect(
        find.text(SurfaceStudioPanel.savePrepActionLabel),
        findsNothing,
      );
      expect(calls, 0);
    });

    testWidgets(
        '63.2 — dirty + callback : action, un appel, catalogue complet, dirty et accusé',
        (tester) async {
      ProjectSurfaceCatalog? received;
      var calls = 0;
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPanel(
            readModel: _emptyReadModel(),
            onSurfaceCatalogSaveRequested: (c) {
              calls++;
              received = c;
            },
          ),
        ),
      );
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
      await tester.ensureVisible(idF);
      await tester.enterText(idF, 'prep-one');
      await tester.enterText(nameF, 'P');
      await tester.enterText(tsF, 't');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.pump();
      final prep = find.byKey(const ValueKey('surface_studio_save_prep_catalog'));
      expect(prep, findsOneWidget);
      await tester.ensureVisible(prep);
      await tester.tap(prep);
      await tester.pump();
      expect(calls, 1);
      expect(received, isNotNull);
      expect(received!.atlases.length, 1);
      expect(received!.atlases.first.id, 'prep-one');
      expect(
        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
        findsOneWidget,
      );
      expect(
        find.text(SurfaceStudioPanel.savePrepTransmittedNote),
        findsOneWidget,
      );
    });

    testWidgets('63.3 — sans callback : stable, message not connected, pas de bouton',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
      await tester.ensureVisible(idF);
      await tester.enterText(idF, 'nccb');
      await tester.enterText(nameF, 'N');
      await tester.enterText(tsF, 't');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(
        find.text(SurfaceStudioPanel.savePrepNotConnectedNote),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('surface_studio_save_prep_catalog')),
        findsNothing,
      );
    });

    testWidgets('63.4 — resync parent : dirty off, atlas source, pas d’accusé',
        (tester) async {
      ProjectSurfaceCatalog? out;
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPanel(
            readModel: _emptyReadModel(),
            onSurfaceCatalogSaveRequested: (c) => out = c,
          ),
        ),
      );
      var idF = find.byKey(const ValueKey('atlas_draft_id'));
      var nameF = find.byKey(const ValueKey('atlas_draft_name'));
      var tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
      await tester.ensureVisible(idF);
      await tester.enterText(idF, 'sync-x');
      await tester.enterText(nameF, 'S');
      await tester.enterText(tsF, 't');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.pump();
      final prep = find.byKey(const ValueKey('surface_studio_save_prep_catalog'));
      await tester.ensureVisible(prep);
      await tester.tap(prep);
      await tester.pump();
      expect(out, isNotNull);
      final synced = buildSurfaceStudioReadModelFromCatalog(out!);
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPanel(
            readModel: synced,
            onSurfaceCatalogSaveRequested: (c) => out = c,
          ),
        ),
      );
      await tester.pump();
      expect(
        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
        findsNothing,
      );
      expect(
        find.text(SurfaceStudioPanel.savePrepTransmittedNote),
        findsNothing,
      );
      expect(find.text('sync-x'), findsWidgets);
    });

    testWidgets('63.5 — reset après préparation : clean, accusé nettoyé, vide',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPanel(
            readModel: _emptyReadModel(),
            onSurfaceCatalogSaveRequested: (_) {},
          ),
        ),
      );
      var idF = find.byKey(const ValueKey('atlas_draft_id'));
      var nameF = find.byKey(const ValueKey('atlas_draft_name'));
      var tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
      await tester.ensureVisible(idF);
      await tester.enterText(idF, 'reset-p');
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
      final prep = find.byKey(const ValueKey('surface_studio_save_prep_catalog'));
      await tester.ensureVisible(prep);
      await tester.tap(prep);
      await tester.pump();
      expect(
        find.text(SurfaceStudioPanel.savePrepTransmittedNote),
        findsOneWidget,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_reset_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_reset_work_catalog')),
      );
      await tester.pump();
      expect(
        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
        findsNothing,
      );
      expect(
        find.text(SurfaceStudioPanel.savePrepTransmittedNote),
        findsNothing,
      );
      final counters = find.byKey(const ValueKey('surface_studio_header_counters'));
      expect(
        find.descendant(of: counters, matching: find.text('0')),
        findsNWidgets(3),
      );
      expect(
        find.text('Le catalogue Surface est vide'),
        findsOneWidget,
      );
    });

    testWidgets('63.6 — A puis B puis préparation : ordre des atlas', (tester) async {
      ProjectSurfaceCatalog? got;
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPanel(
            readModel: _emptyReadModel(),
            onSurfaceCatalogSaveRequested: (c) => got = c,
          ),
        ),
      );
      for (final row in <(String, String, String)>[
        ('lot63-a', 'A', 'ta'),
        ('lot63-b', 'B', 'tb'),
      ]) {
        final idF = find.byKey(const ValueKey('atlas_draft_id'));
        final nameF = find.byKey(const ValueKey('atlas_draft_name'));
        final tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
        await tester.ensureVisible(idF);
        await tester.enterText(idF, row.$1);
        await tester.enterText(nameF, row.$2);
        await tester.enterText(tsF, row.$3);
        await tester.pump();
        await tester.ensureVisible(
          find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
        );
        await tester.tap(
          find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
        );
        await tester.pump();
      }
      final prep = find.byKey(const ValueKey('surface_studio_save_prep_catalog'));
      await tester.ensureVisible(prep);
      await tester.tap(prep);
      await tester.pump();
      expect(got, isNotNull);
      expect(got!.atlases.length, 2);
      expect(got!.atlases[0].id, 'lot63-a');
      expect(got!.atlases[1].id, 'lot63-b');
      expect(
        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
        findsOneWidget,
      );
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

## Périmètre explicitement non touché

- `map_core` non modifié
- Modèle `ProjectManifest` et fichiers générés associés non modifiés
- Aucun fichier généré modifié
- `build_runner` non lancé
- Fixtures Surface JSON non modifiées
- Aucun codec Surface modifié
- Aucun provider Riverpod créé
- Aucun repository ni service créé
- Aucune sauvegarde disque ni écriture `project.json`
- Aucune suppression ni édition d’atlas au-delà du flux existant (brouillon → travail)
- Aucune animation ni preset créé ou modifié
- `map_runtime`, `map_gameplay`, `map_battle` non modifiés
- Aucun painter de carte ni `SurfaceLayer` ni import d’atlas vertical
- Aucun appel `clearProjectManifestSurfaceCatalog`, `updateProjectManifestSurfaceCatalog`, `replaceProjectManifestSurfaceCatalog`, ni `copyWith(surfaceCatalog: ...)` ajouté

## Vérification mojibake

Recherche des séquences interdites `RÃ`, `Ã©`, `â€`, `Â` dans ce rapport : aucune occurrence introduite.

## Auto-review

- Est-ce que le lot ajoute une sauvegarde disque ? Non.
- Est-ce que `project.json` est écrit ? Non.
- Est-ce que `map_core` est modifié ? Non.
- Est-ce qu’un provider est créé ? Non.
- Est-ce qu’un repository ou service est créé ? Non.
- Est-ce que le catalogue de travail est transmis via callback ? Oui : `onSurfaceCatalogSaveRequested` avec `_workReadModel.catalog`.
- Est-ce que le callback reçoit le catalogue complet et pas seulement le dernier atlas ? Oui : un seul `ProjectSurfaceCatalog` avec toutes les listes ; test 63.6 sur l’ordre `lot63-a`, `lot63-b`.
- Est-ce que le dirty state reste visible après transmission ? Oui (test 63.2).
- Est-ce que le dirty state disparaît seulement après reset ou resync parent ? Oui : tests 62.x existants + 63.4 et 63.5.
- Est-ce que le cas callback absent est testé ? Oui (63.3).
- Est-ce que plusieurs créations avant préparation sont testées ? Oui (63.6).
- Est-ce que les tests ciblés passent ? Oui (panel, 63 tests).
- Est-ce que la suite Surface Studio passe ? Oui (`+253: All tests passed!`).
- Est-ce que `flutter analyze` ciblé passe ? Oui.
- Est-ce que le rapport contient les diffs et les fichiers modifiés en entier ? Oui.
- Est-ce qu’aucune commande Git d’écriture n’a été utilisée ? Oui (uniquement statut et diff en lecture).

## Critique du prompt

Le périmètre est serré et cohérent avec l’architecture actuelle (panneau contrôlé par `readModel` parent). Le seul point de procédure : exiger un `git status` initial exact impose de l’exécuter avant toute écriture sur le disque de travail ; en reprise de session, cette capture peut manquer. Le contenu du Evidence Pack (fichiers entiers) duplique la taille des sources mais reste vérifiable mécaniquement.
