# Lot 61 — Surface Studio Create Atlas V0

## Résumé exécutif

Action **Créer l’atlas dans le catalogue de travail** : `ProjectSurfaceAtlas` construit depuis le brouillon validé, append en fin de liste d’un `ProjectSurfaceCatalog` de travail (animations et presets conservés dans l’ordre), `buildSurfaceStudioReadModelFromCatalog`, mise à jour UI (compteurs, browser, sélection sur le dernier atlas). Aucune écriture disque, pas de provider, pas de modification `map_core`.

## Périmètre

Quatre fichiers Dart `map_editor` modifiés ; ce rapport créé. Rien d’autre.

## Audit initial

Lecture des widgets Surface Studio et des modèles `map_core` publics. Suppression de l’exemption de doublon d’identifiant incompatible avec une création stricte (pas d’écrasement d’atlas existant).

## Implémentation

- `SurfaceStudioAtlasAuthoringPrep` : `onSurfaceCatalogChanged`, append immuable, bouton `surface_studio_create_atlas_work_catalog`.
- `SurfaceStudioPanel` : état `_readModel`, callback → read model + sélection atlas.
- Pas d’appel manifeste de persistance.

## Fichiers créés

- `reports/surface/surface_engine_lot_61_surface_studio_create_atlas.md`

## Fichiers modifiés

- `packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart`
- `packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart`
- `packages/map_editor/test/surface_studio/surface_studio_panel_test.dart`

## Fichiers supprimés

Sortie : <vide>

## Tests lancés

Voir Evidence Pack (sorties exactes des commandes).

## Analyse lancée

`cd packages/map_editor && flutter analyze lib/src/features/surface_studio test/surface_studio`

## Résultats

Tous les tests ciblés et la suite `test/surface_studio` : succès. Analyse : aucun problème.

## Evidence Pack

### Audit initial (commandes lecture seule)

```
cd /Users/karim/Project/pokemonProject && git branch --show-current
codex/psdk-fight-next-move-wave
cd /Users/karim/Project/pokemonProject && git log --oneline -n 5
a2e9fc08 feat(map_editor): Surface Studio atlas authoring prep (Lot 60) + rapport statut (60-bis)
19ef4032 feat(map_editor): Surface Studio sélection locale (Lot 58) et inspecteur (Lot 59)
68e0e552 feat(map_editor): Lot 57 — Surface Studio animation/preset detail views (read-only)
0dc3faff feat(map_editor): Lot 56 — Surface Studio atlas detail view (read-only)
de40ae6b move previous reports to the folder previous
```

### `git diff --stat` (état Lot 61, avant ce rapport)

```
 .../surface_studio_atlas_authoring_prep.dart       | 141 +++++++++++++--
 .../surface_studio/surface_studio_panel.dart       |  40 ++++-
 .../surface_studio_atlas_authoring_prep_test.dart  | 199 ++++++++++++++++++++-
 .../surface_studio/surface_studio_panel_test.dart  |  92 +++++++++-
 4 files changed, 446 insertions(+), 26 deletions(-)
```

### Diff unifié Git (fichiers modifiés Lot 61, code uniquement)

```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart b/packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart
index ffb9768a..61e6d07d 100644
--- a/packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart
+++ b/packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart
@@ -19,7 +19,6 @@ List<String> validateSurfaceStudioAtlasDraft({
   required String rowsRaw,
   required String sortOrderRaw,
   required String? categoryIdRaw,
-  String? duplicateIdExemption,
 }) {
   final errors = <String>[];
   final id = idRaw.trim();
@@ -71,24 +70,44 @@ List<String> validateSurfaceStudioAtlasDraft({
   }
 
   if (id.isNotEmpty) {
-    var collides = false;
     for (final a in readModel.atlases) {
       if (a.id == id) {
-        if (duplicateIdExemption != null && duplicateIdExemption == id) {
-          continue;
-        }
-        collides = true;
+        errors.add('Un atlas existe déjà avec cet id.');
         break;
       }
     }
-    if (collides) {
-      errors.add('Cet identifiant existe déjà dans le catalogue');
-    }
   }
 
   return errors;
 }
 
+ProjectSurfaceAtlas? tryBuildProjectSurfaceAtlasFromDraft(
+  SurfaceStudioAtlasDraft draft,
+) {
+  try {
+    return ProjectSurfaceAtlas(
+      id: draft.id,
+      name: draft.name,
+      tilesetId: draft.tilesetId,
+      geometry: SurfaceAtlasGeometry(
+        tileSize: SurfaceAtlasTileSize(
+          width: draft.tileWidth,
+          height: draft.tileHeight,
+        ),
+        gridSize: SurfaceAtlasGridSize(
+          columns: draft.columns,
+          rows: draft.rows,
+        ),
+        layout: draft.layout,
+      ),
+      categoryId: draft.categoryId,
+      sortOrder: draft.sortOrder,
+    );
+  } on ValidationException {
+    return null;
+  }
+}
+
 class SurfaceStudioAtlasDraft {
   const SurfaceStudioAtlasDraft({
     required this.id,
@@ -170,10 +189,12 @@ class SurfaceStudioAtlasAuthoringPrep extends StatefulWidget {
     super.key,
     required this.readModel,
     required this.selection,
+    this.onSurfaceCatalogChanged,
   });
 
   final SurfaceStudioReadModel readModel;
   final SurfaceStudioSelection selection;
+  final ValueChanged<ProjectSurfaceCatalog>? onSurfaceCatalogChanged;
 
   @override
   State<SurfaceStudioAtlasAuthoringPrep> createState() =>
@@ -194,7 +215,7 @@ class _SurfaceStudioAtlasAuthoringPrepState
 
   SurfaceAtlasLayout _layout = SurfaceAtlasLayout.grid;
   bool _showPreview = false;
-  String? _duplicateExemption;
+  String? _creationNote;
 
   @override
   void dispose() {
@@ -222,7 +243,7 @@ class _SurfaceStudioAtlasAuthoringPrepState
       _sort.text = '0';
       _categoryId.clear();
       _layout = SurfaceAtlasLayout.grid;
-      _duplicateExemption = null;
+      _creationNote = null;
     });
   }
 
@@ -252,10 +273,75 @@ class _SurfaceStudioAtlasAuthoringPrepState
       _sort.text = '${row.sortOrder}';
       _layout = row.atlas.geometry.layout;
       _categoryId.text = row.categoryId ?? '';
-      _duplicateExemption = row.id;
+      _creationNote = null;
     });
   }
 
+  void _addToWorkCatalog() {
+    final callback = widget.onSurfaceCatalogChanged;
+    if (callback == null) {
+      return;
+    }
+    setState(() => _creationNote = null);
+    final errs = validateSurfaceStudioAtlasDraft(
+      readModel: widget.readModel,
+      idRaw: _id.text,
+      nameRaw: _name.text,
+      tilesetIdRaw: _tilesetId.text,
+      tileWidthRaw: _tileW.text,
+      tileHeightRaw: _tileH.text,
+      columnsRaw: _cols.text,
+      rowsRaw: _rows.text,
+      sortOrderRaw: _sort.text,
+      categoryIdRaw: _categoryId.text,
+    );
+    if (errs.isNotEmpty) {
+      return;
+    }
+    final draft = tryBuildDraftFromForm(
+      idRaw: _id.text,
+      nameRaw: _name.text,
+      tilesetIdRaw: _tilesetId.text,
+      tileWidthRaw: _tileW.text,
+      tileHeightRaw: _tileH.text,
+      columnsRaw: _cols.text,
+      rowsRaw: _rows.text,
+      sortOrderRaw: _sort.text,
+      categoryIdRaw: _categoryId.text,
+      layout: _layout,
+    );
+    if (draft == null) {
+      return;
+    }
+    final atlas = tryBuildProjectSurfaceAtlasFromDraft(draft);
+    if (atlas == null) {
+      return;
+    }
+    try {
+      final next = ProjectSurfaceCatalog(
+        atlases: [
+          ...widget.readModel.catalog.atlases,
+          atlas,
+        ],
+        animations: List<ProjectSurfaceAnimation>.from(
+          widget.readModel.catalog.animations,
+        ),
+        presets: List<ProjectSurfacePreset>.from(
+          widget.readModel.catalog.presets,
+        ),
+      );
+      callback(next);
+      setState(() {
+        _creationNote =
+            'Atlas créé dans le catalogue de travail. Sauvegarde projet non effectuée.';
+      });
+    } on ValidationException {
+      setState(() {
+        _creationNote = 'Un atlas existe déjà avec cet id.';
+      });
+    }
+  }
+
   String _layoutMenuLabel(SurfaceAtlasLayout l) {
     switch (l) {
       case SurfaceAtlasLayout.grid:
@@ -284,7 +370,6 @@ class _SurfaceStudioAtlasAuthoringPrepState
       rowsRaw: _rows.text,
       sortOrderRaw: _sort.text,
       categoryIdRaw: _categoryId.text,
-      duplicateIdExemption: _duplicateExemption,
     );
     final isValid = errs.isEmpty;
     final draft = tryBuildDraftFromForm(
@@ -348,13 +433,21 @@ class _SurfaceStudioAtlasAuthoringPrepState
           ),
           const SizedBox(height: 4),
           Text(
-            'Brouillon local non sauvegardé',
+            'Brouillon local non sauvegardé sur disque',
             style: TextStyle(
               color: subtle,
               fontSize: 12,
               fontWeight: FontWeight.w600,
             ),
           ),
+          const SizedBox(height: 4),
+          Text(
+            'Création locale : le projet n’est pas sauvegardé sur disque.',
+            style: TextStyle(
+              color: subtle.withValues(alpha: 0.95),
+              fontSize: 11,
+            ),
+          ),
           const SizedBox(height: 6),
           Wrap(
             spacing: 8,
@@ -373,7 +466,7 @@ class _SurfaceStudioAtlasAuthoringPrepState
               const SizedBox(width: 6),
               _localBadge(
                 context,
-                'Aucune modification du catalogue',
+                'Catalogue de travail (mémoire)',
                 label,
                 accent,
               ),
@@ -407,8 +500,26 @@ class _SurfaceStudioAtlasAuthoringPrepState
                 onPressed: _loadFromSelection,
                 child: const Text('Charger la sélection dans le brouillon'),
               ),
+              if (widget.onSurfaceCatalogChanged != null)
+                CupertinoButton(
+                  key: const ValueKey('surface_studio_create_atlas_work_catalog'),
+                  padding:
+                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
+                  onPressed: isValid ? _addToWorkCatalog : null,
+                  child: const Text('Créer l’atlas dans le catalogue de travail'),
+                ),
             ],
           ),
+          if (_creationNote != null) ...[
+            const SizedBox(height: 8),
+            Text(
+              _creationNote!,
+              style: const TextStyle(
+                fontSize: 12,
+                fontWeight: FontWeight.w600,
+              ).copyWith(color: accent),
+            ),
+          ],
           const SizedBox(height: 8),
           material.TextField(
             key: const ValueKey('atlas_draft_id'),
diff --git a/packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart b/packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
index 63bed7ac..3850cff1 100644
--- a/packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
+++ b/packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
@@ -49,10 +49,25 @@ class SurfaceStudioPanel extends StatefulWidget {
 class _SurfaceStudioPanelState extends State<SurfaceStudioPanel> {
   /// Sélection d’inspection : locale au widget, jamais écrite dans le manifest.
   SurfaceStudioSelection _selection = const SurfaceStudioSelection.none();
+  late SurfaceStudioReadModel _readModel;
+
+  @override
+  void initState() {
+    super.initState();
+    _readModel = widget.readModel;
+  }
+
+  @override
+  void didUpdateWidget(covariant SurfaceStudioPanel oldWidget) {
+    super.didUpdateWidget(oldWidget);
+    if (widget.readModel != oldWidget.readModel) {
+      _readModel = widget.readModel;
+    }
+  }
 
   @override
   Widget build(BuildContext context) {
-    final s = widget.readModel.summary;
+    final s = _readModel.summary;
     final label = EditorChrome.primaryLabel(context);
     final subtle = EditorChrome.subtleLabel(context);
 
@@ -92,8 +107,8 @@ class _SurfaceStudioPanelState extends State<SurfaceStudioPanel> {
           ),
           const SizedBox(height: 8),
           Text(
-            'Dans ce lot, il s’agit d’une vue de lecture et de préparation '
-            'uniquement : aucune création, édition, suppression ou sauvegarde.',
+            'Vous pouvez ajouter un atlas au catalogue de travail en mémoire. '
+            'Aucune sauvegarde projet sur disque, pas d’édition ni suppression d’atlas existant.',
             style: TextStyle(
               color: subtle.withValues(alpha: 0.92),
               fontSize: 12,
@@ -111,23 +126,34 @@ class _SurfaceStudioPanelState extends State<SurfaceStudioPanel> {
           SurfaceStudioSelectionSummary(selection: _selection),
           const SizedBox(height: 12),
           SurfaceStudioSelectionInspector(
-            readModel: widget.readModel,
+            readModel: _readModel,
             selection: _selection,
           ),
           const SizedBox(height: 12),
           SurfaceStudioCatalogBrowser(
-            readModel: widget.readModel,
+            readModel: _readModel,
             selection: _selection,
             onSelectionChanged: (v) {
               setState(() => _selection = v);
             },
           ),
           const SizedBox(height: 16),
-          SurfaceStudioDiagnosticsView(readModel: widget.readModel),
+          SurfaceStudioDiagnosticsView(readModel: _readModel),
           const SizedBox(height: 20),
           SurfaceStudioAtlasAuthoringPrep(
-            readModel: widget.readModel,
+            readModel: _readModel,
             selection: _selection,
+            onSurfaceCatalogChanged: (cat) {
+              final newId = cat.atlases.isNotEmpty
+                  ? cat.atlases.last.id
+                  : '';
+              setState(() {
+                _readModel = buildSurfaceStudioReadModelFromCatalog(cat);
+                if (newId.isNotEmpty) {
+                  _selection = SurfaceStudioSelection.atlas(newId);
+                }
+              });
+            },
           ),
           const SizedBox(height: 20),
           const _FutureActions(
diff --git a/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart b/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart
index 51581601..d3c1693c 100644
--- a/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart
+++ b/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart
@@ -1,3 +1,4 @@
+import 'package:flutter/cupertino.dart';
 import 'package:flutter/material.dart';
 import 'package:flutter_test/flutter_test.dart';
 import 'package:map_core/map_core.dart';
@@ -16,7 +17,10 @@ void main() {
         ),
       );
       expect(find.text('Préparation atlas'), findsOneWidget);
-      expect(find.text('Brouillon local non sauvegardé'), findsOneWidget);
+      expect(
+        find.text('Brouillon local non sauvegardé sur disque'),
+        findsOneWidget,
+      );
       expect(find.text('Brouillon local'), findsOneWidget);
       expect(find.text('Non sauvegardé'), findsOneWidget);
       final w = find.byKey(const ValueKey('atlas_draft_tile_w'));
@@ -136,7 +140,7 @@ void main() {
       );
     });
 
-    testWidgets('id dupliqué cat sans exemption: erreur', (tester) async {
+    testWidgets('id dupliqué dans le catalogue: erreur', (tester) async {
       await tester.pumpWidget(
         _wrap(
           SurfaceStudioAtlasAuthoringPrep(
@@ -153,7 +157,7 @@ void main() {
       await tester.enterText(tsF, 't');
       await tester.pump();
       expect(
-        find.text('Cet identifiant existe déjà dans le catalogue'),
+        find.text('Un atlas existe déjà avec cet id.'),
         findsOneWidget,
       );
     });
@@ -293,6 +297,195 @@ void main() {
       expect(find.textContaining('Aperçu : 32×32'), findsOneWidget);
     });
   });
+
+  group('SurfaceStudioAtlasAuthoringPrep (Lot 61)', () {
+    testWidgets('création brouillon valide émet le catalogue + atlas', (tester) async {
+      final out = <ProjectSurfaceCatalog>[];
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioAtlasAuthoringPrep(
+            readModel: _emptyReadModel(),
+            selection: const SurfaceStudioSelection.none(),
+            onSurfaceCatalogChanged: out.add,
+          ),
+        ),
+      );
+      final idF = find.byKey(const ValueKey('atlas_draft_id'));
+      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
+      final tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
+      await tester.enterText(idF, 'a-new');
+      await tester.enterText(nameF, 'My');
+      await tester.enterText(tsF, 'tset');
+      await tester.pump();
+      await tester.tap(
+        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
+      );
+      await tester.pump();
+      expect(out, hasLength(1));
+      final c = out.single;
+      expect(c.atlases, hasLength(1));
+      expect(c.animations, isEmpty);
+      expect(c.presets, isEmpty);
+      final a = c.atlases.single;
+      expect(a.id, 'a-new');
+      expect(a.name, 'My');
+      expect(a.tilesetId, 'tset');
+      expect(a.sortOrder, 0);
+      expect(a.categoryId, isNull);
+      expect(a.geometry.tileSize.width, 32);
+      expect(a.geometry.tileSize.height, 32);
+      expect(a.geometry.gridSize.columns, 1);
+      expect(a.geometry.gridSize.rows, 1);
+      expect(a.geometry.layout, SurfaceAtlasLayout.grid);
+      expect(
+        find.text(
+          'Atlas créé dans le catalogue de travail. Sauvegarde projet non effectuée.',
+        ),
+        findsOneWidget,
+      );
+    });
+
+    testWidgets('création refusée si brouillon invalide (pas de callback)',
+        (tester) async {
+      final out = <ProjectSurfaceCatalog>[];
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioAtlasAuthoringPrep(
+            readModel: _emptyReadModel(),
+            selection: const SurfaceStudioSelection.none(),
+            onSurfaceCatalogChanged: out.add,
+          ),
+        ),
+      );
+      final create = find.descendant(
+        of: find.byKey(kSurfaceStudioAtlasAuthoringPrepKey),
+        matching: find.byKey(
+          const ValueKey('surface_studio_create_atlas_work_catalog'),
+        ),
+      );
+      final btn = tester.widget<CupertinoButton>(create);
+      expect(btn.onPressed, isNull);
+      expect(out, isEmpty);
+    });
+
+    testWidgets('id vide: pas d’appel callback en tap (bouton inactif)',
+        (tester) async {
+      final out = <ProjectSurfaceCatalog>[];
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioAtlasAuthoringPrep(
+            readModel: _emptyReadModel(),
+            selection: const SurfaceStudioSelection.none(),
+            onSurfaceCatalogChanged: out.add,
+          ),
+        ),
+      );
+      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
+      final tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
+      await tester.enterText(nameF, 'N');
+      await tester.enterText(tsF, 't');
+      await tester.pump();
+      final create = find.descendant(
+        of: find.byKey(kSurfaceStudioAtlasAuthoringPrepKey),
+        matching: find.byKey(
+          const ValueKey('surface_studio_create_atlas_work_catalog'),
+        ),
+      );
+      expect(tester.widget<CupertinoButton>(create).onPressed, isNull);
+    });
+
+    testWidgets('dupliquer id: création inactivable', (tester) async {
+      final out = <ProjectSurfaceCatalog>[];
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioAtlasAuthoringPrep(
+            readModel: _minimalRead(),
+            selection: const SurfaceStudioSelection.none(),
+            onSurfaceCatalogChanged: out.add,
+          ),
+        ),
+      );
+      final idF = find.byKey(const ValueKey('atlas_draft_id'));
+      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
+      final tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
+      await tester.enterText(idF, 'water-atlas');
+      await tester.enterText(nameF, 'X');
+      await tester.enterText(tsF, 't');
+      await tester.pump();
+      final create = find.descendant(
+        of: find.byKey(kSurfaceStudioAtlasAuthoringPrepKey),
+        matching: find.byKey(
+          const ValueKey('surface_studio_create_atlas_work_catalog'),
+        ),
+      );
+      expect(tester.widget<CupertinoButton>(create).onPressed, isNull);
+      expect(out, isEmpty);
+    });
+
+    testWidgets('chargé depuis sélection: même id = doublon; nouvel id = ajout',
+        (tester) async {
+      final out = <ProjectSurfaceCatalog>[];
+      var rm = _minimalRead();
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioAtlasAuthoringPrep(
+            readModel: rm,
+            selection: SurfaceStudioSelection.atlas('water-atlas'),
+            onSurfaceCatalogChanged: out.add,
+          ),
+        ),
+      );
+      await tester.tap(
+        find.text('Charger la sélection dans le brouillon'),
+      );
+      await tester.pump();
+      var create = find.descendant(
+        of: find.byKey(kSurfaceStudioAtlasAuthoringPrepKey),
+        matching: find.byKey(
+          const ValueKey('surface_studio_create_atlas_work_catalog'),
+        ),
+      );
+      expect(tester.widget<CupertinoButton>(create).onPressed, isNull);
+      final idF = find.byKey(const ValueKey('atlas_draft_id'));
+      await tester.enterText(idF, 'water-bis');
+      await tester.pump();
+      expect(tester.widget<CupertinoButton>(create).onPressed, isNotNull);
+      final beforeAtlas = rm.catalog.atlases.single;
+      await tester.tap(create);
+      await tester.pump();
+      expect(out, hasLength(1));
+      expect(out.single.atlases, hasLength(2));
+      expect(
+        out.single.atlases.map((a) => a.id).toList(),
+        ['water-atlas', 'water-bis'],
+      );
+      expect(
+        out.single.atlases.first,
+        beforeAtlas,
+      );
+    });
+
+    testWidgets('interdits save projet (libellés)', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioAtlasAuthoringPrep(
+            readModel: _minimalRead(),
+            selection: const SurfaceStudioSelection.none(),
+            onSurfaceCatalogChanged: (_) {},
+          ),
+        ),
+      );
+      for (final s in <String>[
+        'Sauvegarder le projet',
+        'Enregistrer le projet',
+        'Écrire sur disque',
+        'Save project',
+        'Write to disk',
+      ]) {
+        expect(find.text(s), findsNothing);
+      }
+    });
+  });
 }
 
 Widget _wrap(Widget child) {
diff --git a/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart b/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
index 7f60b1d6..6f2af789 100644
--- a/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
+++ b/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
@@ -600,7 +600,97 @@ void main() {
       );
       await tester.ensureVisible(find.text('Préparation atlas'));
       expect(find.text('Préparation atlas'), findsOneWidget);
-      expect(find.text('Brouillon local non sauvegardé'), findsOneWidget);
+      expect(
+        find.text('Brouillon local non sauvegardé sur disque'),
+        findsOneWidget,
+      );
+    });
+
+    testWidgets('61.1 — action création atlas dans le catalogue de travail',
+        (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
+      );
+      await tester.ensureVisible(
+        find.text('Créer l’atlas dans le catalogue de travail'),
+      );
+      expect(
+        find.text('Créer l’atlas dans le catalogue de travail'),
+        findsOneWidget,
+      );
+    });
+
+    testWidgets(
+        '61.2 — créer atlas (catalogue vide) : compteur atlas 1, browser, '
+        'inspecteur',
+        (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
+      );
+      final idF = find.byKey(const ValueKey('atlas_draft_id'));
+      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
+      final tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
+      await tester.ensureVisible(idF);
+      await tester.enterText(idF, 'lot61-a');
+      await tester.enterText(nameF, 'Lot61 A');
+      await tester.enterText(tsF, 'tileset-x');
+      await tester.pump();
+      await tester.ensureVisible(
+        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
+      );
+      await tester.tap(
+        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
+      );
+      await tester.pump();
+      final counters =
+          find.byKey(const ValueKey('surface_studio_header_counters'));
+      expect(
+        find.descendant(of: counters, matching: find.text('1')),
+        findsOneWidget,
+      );
+      expect(
+        find.descendant(of: counters, matching: find.text('0')),
+        findsNWidgets(2),
+      );
+      expect(find.text('Lot61 A'), findsWidgets);
+      expect(find.text('Diagnostics Surface'), findsOneWidget);
+    });
+
+    testWidgets(
+        '61.3 — créer second atlas : compteur 2, animations/presets inchangés',
+        (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
+      );
+      final idF = find.byKey(const ValueKey('atlas_draft_id'));
+      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
+      final tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
+      await tester.ensureVisible(idF);
+      await tester.enterText(idF, 'grass-a');
+      await tester.enterText(nameF, 'Grass');
+      await tester.enterText(tsF, 'ts-g');
+      await tester.pump();
+      await tester.ensureVisible(
+        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
+      );
+      await tester.tap(
+        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
+      );
+      await tester.pump();
+      final counters =
+          find.byKey(const ValueKey('surface_studio_header_counters'));
+      expect(
+        find.descendant(of: counters, matching: find.text('2')),
+        findsOneWidget,
+      );
+      expect(
+        find.descendant(of: counters, matching: find.text('1')),
+        findsNWidgets(2),
+      );
+      expect(find.text('Water Atlas'), findsOneWidget);
+      expect(find.text('Water Isolated Loop'), findsOneWidget);
+      expect(find.text('Water Surface'), findsOneWidget);
+      expect(find.text('grass-a'), findsWidgets);
     });
   });
 }
```

### Contenu intégral des fichiers modifiés (version worktree post-Lot 61)

#### `packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' as material;
import 'package:map_core/map_core.dart';

import '../../ui/shared/cupertino_editor_widgets.dart';
import 'surface_studio_selection.dart';

const ValueKey<String> kSurfaceStudioAtlasAuthoringPrepKey =
    ValueKey<String>('SurfaceStudioAtlasAuthoringPrep');

List<String> validateSurfaceStudioAtlasDraft({
  required SurfaceStudioReadModel readModel,
  required String idRaw,
  required String nameRaw,
  required String tilesetIdRaw,
  required String tileWidthRaw,
  required String tileHeightRaw,
  required String columnsRaw,
  required String rowsRaw,
  required String sortOrderRaw,
  required String? categoryIdRaw,
}) {
  final errors = <String>[];
  final id = idRaw.trim();
  final name = nameRaw.trim();
  final tilesetId = tilesetIdRaw.trim();
  if (id.isEmpty) {
    errors.add('Identifiant requis');
  }
  if (name.isEmpty) {
    errors.add('Nom requis');
  }
  if (tilesetId.isEmpty) {
    errors.add('Identifiant tileset requis');
  }

  int? tw = int.tryParse(tileWidthRaw.trim());
  if (tw == null) {
    errors.add('Largeur de tuile : entier requis');
  } else if (tw <= 0) {
    errors.add('Largeur de tuile : valeur positive requise');
  }

  int? th = int.tryParse(tileHeightRaw.trim());
  if (th == null) {
    errors.add('Hauteur de tuile : entier requis');
  } else if (th <= 0) {
    errors.add('Hauteur de tuile : valeur positive requise');
  }

  int? c = int.tryParse(columnsRaw.trim());
  if (c == null) {
    errors.add('Colonnes : entier requis');
  } else if (c <= 0) {
    errors.add('Colonnes : valeur positive requise');
  }

  int? r = int.tryParse(rowsRaw.trim());
  if (r == null) {
    errors.add('Lignes : entier requis');
  } else if (r <= 0) {
    errors.add('Lignes : valeur positive requise');
  }

  int? so = int.tryParse(sortOrderRaw.trim());
  if (so == null) {
    errors.add('Ordre : entier requis');
  } else if (so < 0) {
    errors.add('Ordre : valeur négative interdite pour ce brouillon');
  }

  if (id.isNotEmpty) {
    for (final a in readModel.atlases) {
      if (a.id == id) {
        errors.add('Un atlas existe déjà avec cet id.');
        break;
      }
    }
  }

  return errors;
}

ProjectSurfaceAtlas? tryBuildProjectSurfaceAtlasFromDraft(
  SurfaceStudioAtlasDraft draft,
) {
  try {
    return ProjectSurfaceAtlas(
      id: draft.id,
      name: draft.name,
      tilesetId: draft.tilesetId,
      geometry: SurfaceAtlasGeometry(
        tileSize: SurfaceAtlasTileSize(
          width: draft.tileWidth,
          height: draft.tileHeight,
        ),
        gridSize: SurfaceAtlasGridSize(
          columns: draft.columns,
          rows: draft.rows,
        ),
        layout: draft.layout,
      ),
      categoryId: draft.categoryId,
      sortOrder: draft.sortOrder,
    );
  } on ValidationException {
    return null;
  }
}

class SurfaceStudioAtlasDraft {
  const SurfaceStudioAtlasDraft({
    required this.id,
    required this.name,
    required this.tilesetId,
    required this.tileWidth,
    required this.tileHeight,
    required this.columns,
    required this.rows,
    required this.layout,
    required this.sortOrder,
    this.categoryId,
  });

  final String id;
  final String name;
  final String tilesetId;
  final int tileWidth;
  final int tileHeight;
  final int columns;
  final int rows;
  final SurfaceAtlasLayout layout;
  final int sortOrder;
  final String? categoryId;

  int get tileCount => columns * rows;
}

SurfaceStudioAtlasDraft? tryBuildDraftFromForm({
  required String idRaw,
  required String nameRaw,
  required String tilesetIdRaw,
  required String tileWidthRaw,
  required String tileHeightRaw,
  required String columnsRaw,
  required String rowsRaw,
  required String sortOrderRaw,
  required String? categoryIdRaw,
  required SurfaceAtlasLayout layout,
}) {
  final id = idRaw.trim();
  final name = nameRaw.trim();
  final tilesetId = tilesetIdRaw.trim();
  final tw = int.tryParse(tileWidthRaw.trim());
  final th = int.tryParse(tileHeightRaw.trim());
  final c = int.tryParse(columnsRaw.trim());
  final r = int.tryParse(rowsRaw.trim());
  final so = int.tryParse(sortOrderRaw.trim());
  if (id.isEmpty ||
      name.isEmpty ||
      tilesetId.isEmpty ||
      tw == null ||
      th == null ||
      c == null ||
      r == null ||
      so == null) {
    return null;
  }
  if (tw <= 0 || th <= 0 || c <= 0 || r <= 0 || so < 0) {
    return null;
  }
  final cat = categoryIdRaw?.trim();
  return SurfaceStudioAtlasDraft(
    id: id,
    name: name,
    tilesetId: tilesetId,
    tileWidth: tw,
    tileHeight: th,
    columns: c,
    rows: r,
    layout: layout,
    sortOrder: so,
    categoryId: (cat == null || cat.isEmpty) ? null : cat,
  );
}

class SurfaceStudioAtlasAuthoringPrep extends StatefulWidget {
  const SurfaceStudioAtlasAuthoringPrep({
    super.key,
    required this.readModel,
    required this.selection,
    this.onSurfaceCatalogChanged,
  });

  final SurfaceStudioReadModel readModel;
  final SurfaceStudioSelection selection;
  final ValueChanged<ProjectSurfaceCatalog>? onSurfaceCatalogChanged;

  @override
  State<SurfaceStudioAtlasAuthoringPrep> createState() =>
      _SurfaceStudioAtlasAuthoringPrepState();
}

class _SurfaceStudioAtlasAuthoringPrepState
    extends State<SurfaceStudioAtlasAuthoringPrep> {
  late final TextEditingController _id = TextEditingController();
  late final TextEditingController _name = TextEditingController();
  late final TextEditingController _tilesetId = TextEditingController();
  late final TextEditingController _tileW = TextEditingController(text: '32');
  late final TextEditingController _tileH = TextEditingController(text: '32');
  late final TextEditingController _cols = TextEditingController(text: '1');
  late final TextEditingController _rows = TextEditingController(text: '1');
  late final TextEditingController _sort = TextEditingController(text: '0');
  late final TextEditingController _categoryId = TextEditingController();

  SurfaceAtlasLayout _layout = SurfaceAtlasLayout.grid;
  bool _showPreview = false;
  String? _creationNote;

  @override
  void dispose() {
    _id.dispose();
    _name.dispose();
    _tilesetId.dispose();
    _tileW.dispose();
    _tileH.dispose();
    _cols.dispose();
    _rows.dispose();
    _sort.dispose();
    _categoryId.dispose();
    super.dispose();
  }

  void _resetToDefaults() {
    setState(() {
      _id.clear();
      _name.clear();
      _tilesetId.clear();
      _tileW.text = '32';
      _tileH.text = '32';
      _cols.text = '1';
      _rows.text = '1';
      _sort.text = '0';
      _categoryId.clear();
      _layout = SurfaceAtlasLayout.grid;
      _creationNote = null;
    });
  }

  void _loadFromSelection() {
    final sel = widget.selection;
    if (!sel.isAtlas) {
      return;
    }
    SurfaceStudioAtlasReadModel? row;
    for (final a in widget.readModel.atlases) {
      if (a.id == sel.id) {
        row = a;
        break;
      }
    }
    if (row == null) {
      return;
    }
    setState(() {
      _id.text = row!.atlas.id;
      _name.text = row.atlas.name;
      _tilesetId.text = row.atlas.tilesetId;
      _tileW.text = '${row.tileWidth}';
      _tileH.text = '${row.tileHeight}';
      _cols.text = '${row.columns}';
      _rows.text = '${row.rows}';
      _sort.text = '${row.sortOrder}';
      _layout = row.atlas.geometry.layout;
      _categoryId.text = row.categoryId ?? '';
      _creationNote = null;
    });
  }

  void _addToWorkCatalog() {
    final callback = widget.onSurfaceCatalogChanged;
    if (callback == null) {
      return;
    }
    setState(() => _creationNote = null);
    final errs = validateSurfaceStudioAtlasDraft(
      readModel: widget.readModel,
      idRaw: _id.text,
      nameRaw: _name.text,
      tilesetIdRaw: _tilesetId.text,
      tileWidthRaw: _tileW.text,
      tileHeightRaw: _tileH.text,
      columnsRaw: _cols.text,
      rowsRaw: _rows.text,
      sortOrderRaw: _sort.text,
      categoryIdRaw: _categoryId.text,
    );
    if (errs.isNotEmpty) {
      return;
    }
    final draft = tryBuildDraftFromForm(
      idRaw: _id.text,
      nameRaw: _name.text,
      tilesetIdRaw: _tilesetId.text,
      tileWidthRaw: _tileW.text,
      tileHeightRaw: _tileH.text,
      columnsRaw: _cols.text,
      rowsRaw: _rows.text,
      sortOrderRaw: _sort.text,
      categoryIdRaw: _categoryId.text,
      layout: _layout,
    );
    if (draft == null) {
      return;
    }
    final atlas = tryBuildProjectSurfaceAtlasFromDraft(draft);
    if (atlas == null) {
      return;
    }
    try {
      final next = ProjectSurfaceCatalog(
        atlases: [
          ...widget.readModel.catalog.atlases,
          atlas,
        ],
        animations: List<ProjectSurfaceAnimation>.from(
          widget.readModel.catalog.animations,
        ),
        presets: List<ProjectSurfacePreset>.from(
          widget.readModel.catalog.presets,
        ),
      );
      callback(next);
      setState(() {
        _creationNote =
            'Atlas créé dans le catalogue de travail. Sauvegarde projet non effectuée.';
      });
    } on ValidationException {
      setState(() {
        _creationNote = 'Un atlas existe déjà avec cet id.';
      });
    }
  }

  String _layoutMenuLabel(SurfaceAtlasLayout l) {
    switch (l) {
      case SurfaceAtlasLayout.grid:
        return 'Grille libre';
      case SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames:
        return 'Colonnes = variantes, lignes = frames';
      case SurfaceAtlasLayout.rowsAreVariantsColumnsAreFrames:
        return 'Lignes = variantes, colonnes = frames';
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    const accent = Color(0xFF2DD4BF);

    final errs = validateSurfaceStudioAtlasDraft(
      readModel: widget.readModel,
      idRaw: _id.text,
      nameRaw: _name.text,
      tilesetIdRaw: _tilesetId.text,
      tileWidthRaw: _tileW.text,
      tileHeightRaw: _tileH.text,
      columnsRaw: _cols.text,
      rowsRaw: _rows.text,
      sortOrderRaw: _sort.text,
      categoryIdRaw: _categoryId.text,
    );
    final isValid = errs.isEmpty;
    final draft = tryBuildDraftFromForm(
      idRaw: _id.text,
      nameRaw: _name.text,
      tilesetIdRaw: _tilesetId.text,
      tileWidthRaw: _tileW.text,
      tileHeightRaw: _tileH.text,
      columnsRaw: _cols.text,
      rowsRaw: _rows.text,
      sortOrderRaw: _sort.text,
      categoryIdRaw: _categoryId.text,
      layout: _layout,
    );

    final sel = widget.selection;
    String? contextNote;
    if (sel.isAnimation || sel.isPreset) {
      contextNote = 'La sélection actuelle n’est pas un atlas.';
    } else if (sel.isAtlas) {
      var found = false;
      for (final a in widget.readModel.atlases) {
        if (a.id == sel.id) {
          found = true;
          break;
        }
      }
      if (!found) {
        contextNote =
            'Atlas sélectionné introuvable, brouillon atlas indépendant.';
      }
    }

    return material.Material(
      type: material.MaterialType.transparency,
      child: Container(
        key: kSurfaceStudioAtlasAuthoringPrepKey,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: EditorChrome.elevatedPanelBackground(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Color.lerp(
              EditorChrome.editorIslandRim(context),
              accent,
              0.35,
            )!,
          ),
          boxShadow: EditorChrome.sectionCardShadows(context),
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Préparation atlas',
            style: TextStyle(
              color: label,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Brouillon local non sauvegardé sur disque',
            style: TextStyle(
              color: subtle,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Création locale : le projet n’est pas sauvegardé sur disque.',
            style: TextStyle(
              color: subtle.withValues(alpha: 0.95),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _localBadge(context, 'Brouillon local', label, accent),
              const SizedBox(width: 6),
              _localBadge(context, 'Non sauvegardé', label, accent),
              const SizedBox(width: 6),
              _localBadge(
                context,
                'Validation locale uniquement',
                label,
                accent,
              ),
              const SizedBox(width: 6),
              _localBadge(
                context,
                'Catalogue de travail (mémoire)',
                label,
                accent,
              ),
            ],
          ),
          if (contextNote != null) ...[
            const SizedBox(height: 8),
            Text(
              contextNote,
              style: TextStyle(
                color: subtle,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              CupertinoButton(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                onPressed: _resetToDefaults,
                child: const Text('Réinitialiser le brouillon'),
              ),
              CupertinoButton(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                onPressed: _loadFromSelection,
                child: const Text('Charger la sélection dans le brouillon'),
              ),
              if (widget.onSurfaceCatalogChanged != null)
                CupertinoButton(
                  key: const ValueKey('surface_studio_create_atlas_work_catalog'),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  onPressed: isValid ? _addToWorkCatalog : null,
                  child: const Text('Créer l’atlas dans le catalogue de travail'),
                ),
            ],
          ),
          if (_creationNote != null) ...[
            const SizedBox(height: 8),
            Text(
              _creationNote!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ).copyWith(color: accent),
            ),
          ],
          const SizedBox(height: 8),
          material.TextField(
            key: const ValueKey('atlas_draft_id'),
            controller: _id,
            onChanged: (_) => setState(() {}),
            style: TextStyle(color: label, fontSize: 13),
            decoration: const material.InputDecoration(
              labelText: 'Identifiant',
              isDense: true,
            ),
          ),
          const SizedBox(height: 6),
          material.TextField(
            key: const ValueKey('atlas_draft_name'),
            controller: _name,
            onChanged: (_) => setState(() {}),
            style: TextStyle(color: label, fontSize: 13),
            decoration: const material.InputDecoration(
              labelText: 'Nom',
              isDense: true,
            ),
          ),
          const SizedBox(height: 6),
          material.TextField(
            key: const ValueKey('atlas_draft_tileset'),
            controller: _tilesetId,
            onChanged: (_) => setState(() {}),
            style: TextStyle(color: label, fontSize: 13),
            decoration: const material.InputDecoration(
              labelText: 'Identifiant tileset',
              isDense: true,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: material.TextField(
                  key: const ValueKey('atlas_draft_tile_w'),
                  controller: _tileW,
                  onChanged: (_) => setState(() {}),
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: label, fontSize: 13),
                  decoration: const material.InputDecoration(
                    labelText: 'Largeur tuile',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: material.TextField(
                  key: const ValueKey('atlas_draft_tile_h'),
                  controller: _tileH,
                  onChanged: (_) => setState(() {}),
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: label, fontSize: 13),
                  decoration: const material.InputDecoration(
                    labelText: 'Hauteur tuile',
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: material.TextField(
                  key: const ValueKey('atlas_draft_cols'),
                  controller: _cols,
                  onChanged: (_) => setState(() {}),
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: label, fontSize: 13),
                  decoration: const material.InputDecoration(
                    labelText: 'Colonnes',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: material.TextField(
                  key: const ValueKey('atlas_draft_rows'),
                  controller: _rows,
                  onChanged: (_) => setState(() {}),
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: label, fontSize: 13),
                  decoration: const material.InputDecoration(
                    labelText: 'Lignes',
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Disposition', style: TextStyle(color: label, fontSize: 12)),
              const SizedBox(width: 12),
              Expanded(
                child: material.DropdownButton<SurfaceAtlasLayout>(
                  isExpanded: true,
                  value: _layout,
                  items: SurfaceAtlasLayout.values
                      .map(
                        (e) => material.DropdownMenuItem(
                          value: e,
                          child: Text(
                            _layoutMenuLabel(e),
                            style: TextStyle(color: label, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _layout = v);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          material.TextField(
            key: const ValueKey('atlas_draft_category'),
            controller: _categoryId,
            onChanged: (_) => setState(() {}),
            style: TextStyle(color: label, fontSize: 13),
            decoration: const material.InputDecoration(
              labelText: 'Catégorie (optionnel)',
              isDense: true,
            ),
          ),
          const SizedBox(height: 6),
          material.TextField(
            key: const ValueKey('atlas_draft_sort'),
            controller: _sort,
            onChanged: (_) => setState(() {}),
            keyboardType: TextInputType.number,
            style: TextStyle(color: label, fontSize: 13),
            decoration: const material.InputDecoration(
              labelText: 'Ordre d’affichage',
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              material.Switch(
                value: _showPreview,
                onChanged: (v) => setState(() => _showPreview = v),
              ),
              const SizedBox(width: 4),
              Text(
                'Prévisualisation locale',
                style: TextStyle(color: label, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isValid ? 'Brouillon prêt localement' : 'Brouillon invalide',
            style: TextStyle(
              color: isValid ? accent : const Color(0xFFE8887A),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Aucune sauvegarde ne sera effectuée',
            style: TextStyle(color: subtle, fontSize: 11),
          ),
          if (errs.isNotEmpty) ...[
            const SizedBox(height: 6),
            for (final e in errs)
              Text(
                e,
                style: const TextStyle(
                  color: Color(0xFFE8887A),
                  fontSize: 11,
                ),
              ),
          ],
          if (_showPreview && draft != null) ...[
            const SizedBox(height: 10),
            Text(
              'Aperçu : ${draft.tileWidth}×${draft.tileHeight} · Grille ${draft.columns}×${draft.rows} · ${draft.tileCount} tuiles · ordre ${draft.sortOrder}',
              style: TextStyle(color: label, fontSize: 12),
            ),
            Text(
              'Disposition : ${_layoutMenuLabel(draft.layout)}',
              style: TextStyle(color: subtle, fontSize: 11),
            ),
            Text(
              'Catégorie : ${draft.categoryId ?? '—'}',
              style: TextStyle(color: subtle, fontSize: 11),
            ),
          ],
        ],
      ),
    ),
  );
  }
}

Widget _localBadge(
  BuildContext context,
  String text,
  Color labelColor,
  Color accent,
) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Color.lerp(
        EditorChrome.islandFillElevated(context),
        accent,
        0.1,
      ),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: accent.withValues(alpha: 0.4)),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: labelColor,
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
```

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
  static const String actionCreateAtlasLabel = 'Créer un atlas';
  static const String actionImportVerticalAtlasLabel =
      'Importer un atlas vertical';

  @override
  State<SurfaceStudioPanel> createState() => _SurfaceStudioPanelState();
}

class _SurfaceStudioPanelState extends State<SurfaceStudioPanel> {
  /// Sélection d’inspection : locale au widget, jamais écrite dans le manifest.
  SurfaceStudioSelection _selection = const SurfaceStudioSelection.none();
  late SurfaceStudioReadModel _readModel;

  @override
  void initState() {
    super.initState();
    _readModel = widget.readModel;
  }

  @override
  void didUpdateWidget(covariant SurfaceStudioPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.readModel != oldWidget.readModel) {
      _readModel = widget.readModel;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _readModel.summary;
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
            readModel: _readModel,
            selection: _selection,
          ),
          const SizedBox(height: 12),
          SurfaceStudioCatalogBrowser(
            readModel: _readModel,
            selection: _selection,
            onSelectionChanged: (v) {
              setState(() => _selection = v);
            },
          ),
          const SizedBox(height: 16),
          SurfaceStudioDiagnosticsView(readModel: _readModel),
          const SizedBox(height: 20),
          SurfaceStudioAtlasAuthoringPrep(
            readModel: _readModel,
            selection: _selection,
            onSurfaceCatalogChanged: (cat) {
              final newId = cat.atlases.isNotEmpty
                  ? cat.atlases.last.id
                  : '';
              setState(() {
                _readModel = buildSurfaceStudioReadModelFromCatalog(cat);
                if (newId.isNotEmpty) {
                  _selection = SurfaceStudioSelection.atlas(newId);
                }
              });
            },
          ),
          const SizedBox(height: 20),
          const _FutureActions(
            onCreateAtlas: null,
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
    required this.onCreateAtlas,
    required this.onImportVertical,
  });

  final VoidCallback? onCreateAtlas;
  final VoidCallback? onImportVertical;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions (non disponibles dans ce lot)',
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
              label: SurfaceStudioPanel.actionCreateAtlasLabel,
              onPressed: onCreateAtlas,
            ),
            const SizedBox(width: 12),
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

#### `packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_selection.dart';

void main() {
  group('SurfaceStudioAtlasAuthoringPrep (Lot 60)', () {
    testWidgets('titre, brouillon local, défauts 32/1/1', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasAuthoringPrep(
            readModel: _minimalRead(),
            selection: const SurfaceStudioSelection.none(),
          ),
        ),
      );
      expect(find.text('Préparation atlas'), findsOneWidget);
      expect(
        find.text('Brouillon local non sauvegardé sur disque'),
        findsOneWidget,
      );
      expect(find.text('Brouillon local'), findsOneWidget);
      expect(find.text('Non sauvegardé'), findsOneWidget);
      final w = find.byKey(const ValueKey('atlas_draft_tile_w'));
      final h = find.byKey(const ValueKey('atlas_draft_tile_h'));
      final c = find.byKey(const ValueKey('atlas_draft_cols'));
      final r = find.byKey(const ValueKey('atlas_draft_rows'));
      expect(
        (tester.widget(w) as TextField).controller!.text,
        '32',
      );
      expect(
        (tester.widget(h) as TextField).controller!.text,
        '32',
      );
      expect(
        (tester.widget(c) as TextField).controller!.text,
        '1',
      );
      expect(
        (tester.widget(r) as TextField).controller!.text,
        '1',
      );
    });

    testWidgets('id / nom / tileset vides: erreurs', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasAuthoringPrep(
            readModel: _emptyReadModel(),
            selection: const SurfaceStudioSelection.none(),
          ),
        ),
      );
      expect(find.text('Identifiant requis'), findsOneWidget);
      expect(find.text('Nom requis'), findsOneWidget);
      expect(find.text('Identifiant tileset requis'), findsOneWidget);
    });

    testWidgets('taille tuile x non entier: erreur', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasAuthoringPrep(
            readModel: _minimalRead(),
            selection: const SurfaceStudioSelection.none(),
          ),
        ),
      );
      final w = find.byKey(const ValueKey('atlas_draft_tile_w'));
      await tester.enterText(w, 'abc');
      await tester.pump();
      expect(find.text('Largeur de tuile : entier requis'), findsOneWidget);
    });

    testWidgets('hauteur / colonnes / lignes <= 0: erreur', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasAuthoringPrep(
            readModel: _minimalRead(),
            selection: const SurfaceStudioSelection.none(),
          ),
        ),
      );
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
      final hF = find.byKey(const ValueKey('atlas_draft_tile_h'));
      final cF = find.byKey(const ValueKey('atlas_draft_cols'));
      final rF = find.byKey(const ValueKey('atlas_draft_rows'));
      final sF = find.byKey(const ValueKey('atlas_draft_sort'));
      await tester.enterText(idF, 'n');
      await tester.enterText(nameF, 'N');
      await tester.enterText(tsF, 't');
      await tester.enterText(hF, '0');
      await tester.pump();
      expect(
        find.text('Hauteur de tuile : valeur positive requise'),
        findsOneWidget,
      );
      await tester.enterText(hF, '32');
      await tester.enterText(cF, '0');
      await tester.pump();
      expect(
        find.text('Colonnes : valeur positive requise'),
        findsOneWidget,
      );
      await tester.enterText(cF, '1');
      await tester.enterText(rF, '0');
      await tester.pump();
      expect(find.text('Lignes : valeur positive requise'), findsOneWidget);
      await tester.enterText(rF, '1');
      await tester.enterText(sF, 'notint');
      await tester.pump();
      expect(find.text('Ordre : entier requis'), findsOneWidget);
    });

    testWidgets('sortOrder négatif: erreur', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasAuthoringPrep(
            readModel: _minimalRead(),
            selection: const SurfaceStudioSelection.none(),
          ),
        ),
      );
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
      final sF = find.byKey(const ValueKey('atlas_draft_sort'));
      await tester.enterText(idF, 'n');
      await tester.enterText(nameF, 'N');
      await tester.enterText(tsF, 't');
      await tester.enterText(sF, '-1');
      await tester.pump();
      expect(
        find.text('Ordre : valeur négative interdite pour ce brouillon'),
        findsOneWidget,
      );
    });

    testWidgets('id dupliqué dans le catalogue: erreur', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasAuthoringPrep(
            readModel: _minimalRead(),
            selection: const SurfaceStudioSelection.none(),
          ),
        ),
      );
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
      await tester.enterText(idF, 'water-atlas');
      await tester.enterText(nameF, 'X');
      await tester.enterText(tsF, 't');
      await tester.pump();
      expect(
        find.text('Un atlas existe déjà avec cet id.'),
        findsOneWidget,
      );
    });

    testWidgets('Charger la sélection: champs = atlas, catalogue inchangé',
        (tester) async {
      final rm = _minimalRead();
      final beforeCat = rm.catalog;
      final sel = SurfaceStudioSelection.atlas('water-atlas');
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasAuthoringPrep(
            readModel: rm,
            selection: sel,
          ),
        ),
      );
      await tester.tap(
        find.text('Charger la sélection dans le brouillon'),
      );
      await tester.pump();
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      expect(
        (tester.widget(idF) as TextField).controller!.text,
        'water-atlas',
      );
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      expect(
        (tester.widget(nameF) as TextField).controller!.text,
        'Water Atlas',
      );
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
      expect(
        (tester.widget(tsF) as TextField).controller!.text,
        'nature-tileset',
      );
      expect(identical(rm.catalog, beforeCat), isTrue);
    });

    testWidgets('sélection animation: brouillon stable + note', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasAuthoringPrep(
            readModel: _minimalRead(),
            selection: SurfaceStudioSelection.animation('water-isolated-loop'),
          ),
        ),
      );
      expect(
        find.text('La sélection actuelle n’est pas un atlas.'),
        findsOneWidget,
      );
      expect(
        (tester.widget(find.byKey(const ValueKey('atlas_draft_id')))
                as TextField)
            .controller!
            .text
            .isEmpty,
        isTrue,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('sélection atlas manquant: note + stable', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasAuthoringPrep(
            readModel: _minimalRead(),
            selection: SurfaceStudioSelection.atlas('nope-missing'),
          ),
        ),
      );
      expect(
        find.text(
            'Atlas sélectionné introuvable, brouillon atlas indépendant.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('pas de libellés d’action dangereux', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasAuthoringPrep(
            readModel: _minimalRead(),
            selection: const SurfaceStudioSelection.none(),
          ),
        ),
      );
      for (final s in <String>[
        'Sauvegarder',
        'Enregistrer',
        'Créer l’atlas',
        'Modifier l’atlas',
        'Supprimer',
        'Delete',
        'Save',
        'Create',
        'Update',
      ]) {
        expect(find.text(s), findsNothing);
      }
    });

    testWidgets('sans ProviderScope', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasAuthoringPrep(
            readModel: _minimalRead(),
            selection: const SurfaceStudioSelection.none(),
          ),
        ),
      );
      expect(find.byKey(kSurfaceStudioAtlasAuthoringPrepKey), findsOneWidget);
    });

    testWidgets('brouillon valide + prévisu: texte aperçu', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasAuthoringPrep(
            readModel: _emptyReadModel(),
            selection: const SurfaceStudioSelection.none(),
          ),
        ),
      );
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
      await tester.enterText(idF, 'new-a');
      await tester.enterText(nameF, 'New');
      await tester.enterText(tsF, 'ts');
      await tester.pump();
      final swFinder = find.byType(Switch);
      await tester.ensureVisible(swFinder);
      await tester.tap(swFinder);
      await tester.pump();
      expect(find.textContaining('Aperçu : 32×32'), findsOneWidget);
    });
  });

  group('SurfaceStudioAtlasAuthoringPrep (Lot 61)', () {
    testWidgets('création brouillon valide émet le catalogue + atlas', (tester) async {
      final out = <ProjectSurfaceCatalog>[];
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasAuthoringPrep(
            readModel: _emptyReadModel(),
            selection: const SurfaceStudioSelection.none(),
            onSurfaceCatalogChanged: out.add,
          ),
        ),
      );
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
      await tester.enterText(idF, 'a-new');
      await tester.enterText(nameF, 'My');
      await tester.enterText(tsF, 'tset');
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.pump();
      expect(out, hasLength(1));
      final c = out.single;
      expect(c.atlases, hasLength(1));
      expect(c.animations, isEmpty);
      expect(c.presets, isEmpty);
      final a = c.atlases.single;
      expect(a.id, 'a-new');
      expect(a.name, 'My');
      expect(a.tilesetId, 'tset');
      expect(a.sortOrder, 0);
      expect(a.categoryId, isNull);
      expect(a.geometry.tileSize.width, 32);
      expect(a.geometry.tileSize.height, 32);
      expect(a.geometry.gridSize.columns, 1);
      expect(a.geometry.gridSize.rows, 1);
      expect(a.geometry.layout, SurfaceAtlasLayout.grid);
      expect(
        find.text(
          'Atlas créé dans le catalogue de travail. Sauvegarde projet non effectuée.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('création refusée si brouillon invalide (pas de callback)',
        (tester) async {
      final out = <ProjectSurfaceCatalog>[];
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasAuthoringPrep(
            readModel: _emptyReadModel(),
            selection: const SurfaceStudioSelection.none(),
            onSurfaceCatalogChanged: out.add,
          ),
        ),
      );
      final create = find.descendant(
        of: find.byKey(kSurfaceStudioAtlasAuthoringPrepKey),
        matching: find.byKey(
          const ValueKey('surface_studio_create_atlas_work_catalog'),
        ),
      );
      final btn = tester.widget<CupertinoButton>(create);
      expect(btn.onPressed, isNull);
      expect(out, isEmpty);
    });

    testWidgets('id vide: pas d’appel callback en tap (bouton inactif)',
        (tester) async {
      final out = <ProjectSurfaceCatalog>[];
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasAuthoringPrep(
            readModel: _emptyReadModel(),
            selection: const SurfaceStudioSelection.none(),
            onSurfaceCatalogChanged: out.add,
          ),
        ),
      );
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
      await tester.enterText(nameF, 'N');
      await tester.enterText(tsF, 't');
      await tester.pump();
      final create = find.descendant(
        of: find.byKey(kSurfaceStudioAtlasAuthoringPrepKey),
        matching: find.byKey(
          const ValueKey('surface_studio_create_atlas_work_catalog'),
        ),
      );
      expect(tester.widget<CupertinoButton>(create).onPressed, isNull);
    });

    testWidgets('dupliquer id: création inactivable', (tester) async {
      final out = <ProjectSurfaceCatalog>[];
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasAuthoringPrep(
            readModel: _minimalRead(),
            selection: const SurfaceStudioSelection.none(),
            onSurfaceCatalogChanged: out.add,
          ),
        ),
      );
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
      await tester.enterText(idF, 'water-atlas');
      await tester.enterText(nameF, 'X');
      await tester.enterText(tsF, 't');
      await tester.pump();
      final create = find.descendant(
        of: find.byKey(kSurfaceStudioAtlasAuthoringPrepKey),
        matching: find.byKey(
          const ValueKey('surface_studio_create_atlas_work_catalog'),
        ),
      );
      expect(tester.widget<CupertinoButton>(create).onPressed, isNull);
      expect(out, isEmpty);
    });

    testWidgets('chargé depuis sélection: même id = doublon; nouvel id = ajout',
        (tester) async {
      final out = <ProjectSurfaceCatalog>[];
      var rm = _minimalRead();
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasAuthoringPrep(
            readModel: rm,
            selection: SurfaceStudioSelection.atlas('water-atlas'),
            onSurfaceCatalogChanged: out.add,
          ),
        ),
      );
      await tester.tap(
        find.text('Charger la sélection dans le brouillon'),
      );
      await tester.pump();
      var create = find.descendant(
        of: find.byKey(kSurfaceStudioAtlasAuthoringPrepKey),
        matching: find.byKey(
          const ValueKey('surface_studio_create_atlas_work_catalog'),
        ),
      );
      expect(tester.widget<CupertinoButton>(create).onPressed, isNull);
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      await tester.enterText(idF, 'water-bis');
      await tester.pump();
      expect(tester.widget<CupertinoButton>(create).onPressed, isNotNull);
      final beforeAtlas = rm.catalog.atlases.single;
      await tester.tap(create);
      await tester.pump();
      expect(out, hasLength(1));
      expect(out.single.atlases, hasLength(2));
      expect(
        out.single.atlases.map((a) => a.id).toList(),
        ['water-atlas', 'water-bis'],
      );
      expect(
        out.single.atlases.first,
        beforeAtlas,
      );
    });

    testWidgets('interdits save projet (libellés)', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasAuthoringPrep(
            readModel: _minimalRead(),
            selection: const SurfaceStudioSelection.none(),
            onSurfaceCatalogChanged: (_) {},
          ),
        ),
      );
      for (final s in <String>[
        'Sauvegarder le projet',
        'Enregistrer le projet',
        'Écrire sur disque',
        'Save project',
        'Write to disk',
      ]) {
        expect(find.text(s), findsNothing);
      }
    });
  });
}

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    ),
  );
}

SurfaceStudioReadModel _minimalRead() {
  return buildSurfaceStudioReadModelFromCatalog(_cat());
}

SurfaceStudioReadModel _emptyReadModel() {
  return buildSurfaceStudioReadModelFromCatalog(ProjectSurfaceCatalog());
}

ProjectSurfaceCatalog _cat() {
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

    testWidgets('10. future action labels are visible', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      expect(find.text('Créer un atlas'), findsOneWidget);
      expect(find.text('Importer un atlas vertical'), findsOneWidget);
    });

    testWidgets('11. future actions are disabled (onPressed null)',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      final b1 = tester.widget<CupertinoButton>(
        find.ancestor(
          of: find.text('Créer un atlas'),
          matching: find.byType(CupertinoButton),
        ),
      );
      final b2 = tester.widget<CupertinoButton>(
        find.ancestor(
          of: find.text('Importer un atlas vertical'),
          matching: find.byType(CupertinoButton),
        ),
      );
      expect(b1.onPressed, isNull);
      expect(b2.onPressed, isNull);
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

### Sorties des tests ciblés

#### `flutter test test/surface_studio/surface_studio_atlas_authoring_prep_test.dart`

Dernière ligne exacte :

```
00:05 +18: All tests passed!
```

#### `flutter test test/surface_studio/surface_studio_panel_test.dart`

Dernière ligne exacte :

```
00:09 +49: All tests passed!
```

#### `flutter test` sélection (inspecteur, interaction, summary, selection)

Dernière ligne exacte :

```
00:02 +37: All tests passed!
```

#### `flutter test test/surface_studio` (régression groupe)

Commande complète :

```
cd packages/map_editor && flutter test test/surface_studio
```

Dernière ligne exacte :

```
00:10 +239: All tests passed!
```

#### `dart test test/surface_studio_read_model_test.dart` (map_core)

Dernière ligne exacte :

```
00:00 +30: All tests passed!
```

### `flutter analyze` ciblé

```
Analyzing 2 items...
No issues found! (ran in 2.5s)
```

### Vérification `find` fichiers temporaires (racine repo)

```
Sortie : <vide>
```


### Fichier créé — `git diff --no-index /dev/null` sur la passe 1 du rapport

*(La passe 1 est le corps du rapport avant ce bloc ; le diff décrit l’ajout initial du fichier.)*

```diff
diff --git a/Users/karim/Project/pokemonProject/reports/surface/surface_engine_lot_61_surface_studio_create_atlas.md b/Users/karim/Project/pokemonProject/reports/surface/surface_engine_lot_61_surface_studio_create_atlas.md
new file mode 100644
index 0000000..7daefd0
--- /dev/null
+++ b/Users/karim/Project/pokemonProject/reports/surface/surface_engine_lot_61_surface_studio_create_atlas.md
@@ -0,0 +1,3444 @@
+# Lot 61 — Surface Studio Create Atlas V0
+
+## Résumé exécutif
+
+Action **Créer l’atlas dans le catalogue de travail** : `ProjectSurfaceAtlas` construit depuis le brouillon validé, append en fin de liste d’un `ProjectSurfaceCatalog` de travail (animations et presets conservés dans l’ordre), `buildSurfaceStudioReadModelFromCatalog`, mise à jour UI (compteurs, browser, sélection sur le dernier atlas). Aucune écriture disque, pas de provider, pas de modification `map_core`.
+
+## Périmètre
+
+Quatre fichiers Dart `map_editor` modifiés ; ce rapport créé. Rien d’autre.
+
+## Audit initial
+
+Lecture des widgets Surface Studio et des modèles `map_core` publics. Suppression de l’exemption de doublon d’identifiant incompatible avec une création stricte (pas d’écrasement d’atlas existant).
+
+## Implémentation
+
+- `SurfaceStudioAtlasAuthoringPrep` : `onSurfaceCatalogChanged`, append immuable, bouton `surface_studio_create_atlas_work_catalog`.
+- `SurfaceStudioPanel` : état `_readModel`, callback → read model + sélection atlas.
+- Pas d’appel manifeste de persistance.
+
+## Fichiers créés
+
+- `reports/surface/surface_engine_lot_61_surface_studio_create_atlas.md`
+
+## Fichiers modifiés
+
+- `packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart`
+- `packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart`
+- `packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart`
+- `packages/map_editor/test/surface_studio/surface_studio_panel_test.dart`
+
+## Fichiers supprimés
+
+Sortie : <vide>
+
+## Tests lancés
+
+Voir Evidence Pack (sorties exactes des commandes).
+
+## Analyse lancée
+
+`cd packages/map_editor && flutter analyze lib/src/features/surface_studio test/surface_studio`
+
+## Résultats
+
+Tous les tests ciblés et la suite `test/surface_studio` : succès. Analyse : aucun problème.
+
+## Evidence Pack
+
+### Audit initial (commandes lecture seule)
+
+```
+cd /Users/karim/Project/pokemonProject && git branch --show-current
+codex/psdk-fight-next-move-wave
+cd /Users/karim/Project/pokemonProject && git log --oneline -n 5
+a2e9fc08 feat(map_editor): Surface Studio atlas authoring prep (Lot 60) + rapport statut (60-bis)
+19ef4032 feat(map_editor): Surface Studio sélection locale (Lot 58) et inspecteur (Lot 59)
+68e0e552 feat(map_editor): Lot 57 — Surface Studio animation/preset detail views (read-only)
+0dc3faff feat(map_editor): Lot 56 — Surface Studio atlas detail view (read-only)
+de40ae6b move previous reports to the folder previous
+```
+
+### `git diff --stat` (état Lot 61, avant ce rapport)
+
+```
+ .../surface_studio_atlas_authoring_prep.dart       | 141 +++++++++++++--
+ .../surface_studio/surface_studio_panel.dart       |  40 ++++-
+ .../surface_studio_atlas_authoring_prep_test.dart  | 199 ++++++++++++++++++++-
+ .../surface_studio/surface_studio_panel_test.dart  |  92 +++++++++-
+ 4 files changed, 446 insertions(+), 26 deletions(-)
+```
+
+### Diff unifié Git (fichiers modifiés Lot 61, code uniquement)
+
+```diff
+diff --git a/packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart b/packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart
+index ffb9768a..61e6d07d 100644
+--- a/packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart
++++ b/packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart
+@@ -19,7 +19,6 @@ List<String> validateSurfaceStudioAtlasDraft({
+   required String rowsRaw,
+   required String sortOrderRaw,
+   required String? categoryIdRaw,
+-  String? duplicateIdExemption,
+ }) {
+   final errors = <String>[];
+   final id = idRaw.trim();
+@@ -71,24 +70,44 @@ List<String> validateSurfaceStudioAtlasDraft({
+   }
+ 
+   if (id.isNotEmpty) {
+-    var collides = false;
+     for (final a in readModel.atlases) {
+       if (a.id == id) {
+-        if (duplicateIdExemption != null && duplicateIdExemption == id) {
+-          continue;
+-        }
+-        collides = true;
++        errors.add('Un atlas existe déjà avec cet id.');
+         break;
+       }
+     }
+-    if (collides) {
+-      errors.add('Cet identifiant existe déjà dans le catalogue');
+-    }
+   }
+ 
+   return errors;
+ }
+ 
++ProjectSurfaceAtlas? tryBuildProjectSurfaceAtlasFromDraft(
++  SurfaceStudioAtlasDraft draft,
++) {
++  try {
++    return ProjectSurfaceAtlas(
++      id: draft.id,
++      name: draft.name,
++      tilesetId: draft.tilesetId,
++      geometry: SurfaceAtlasGeometry(
++        tileSize: SurfaceAtlasTileSize(
++          width: draft.tileWidth,
++          height: draft.tileHeight,
++        ),
++        gridSize: SurfaceAtlasGridSize(
++          columns: draft.columns,
++          rows: draft.rows,
++        ),
++        layout: draft.layout,
++      ),
++      categoryId: draft.categoryId,
++      sortOrder: draft.sortOrder,
++    );
++  } on ValidationException {
++    return null;
++  }
++}
++
+ class SurfaceStudioAtlasDraft {
+   const SurfaceStudioAtlasDraft({
+     required this.id,
+@@ -170,10 +189,12 @@ class SurfaceStudioAtlasAuthoringPrep extends StatefulWidget {
+     super.key,
+     required this.readModel,
+     required this.selection,
++    this.onSurfaceCatalogChanged,
+   });
+ 
+   final SurfaceStudioReadModel readModel;
+   final SurfaceStudioSelection selection;
++  final ValueChanged<ProjectSurfaceCatalog>? onSurfaceCatalogChanged;
+ 
+   @override
+   State<SurfaceStudioAtlasAuthoringPrep> createState() =>
+@@ -194,7 +215,7 @@ class _SurfaceStudioAtlasAuthoringPrepState
+ 
+   SurfaceAtlasLayout _layout = SurfaceAtlasLayout.grid;
+   bool _showPreview = false;
+-  String? _duplicateExemption;
++  String? _creationNote;
+ 
+   @override
+   void dispose() {
+@@ -222,7 +243,7 @@ class _SurfaceStudioAtlasAuthoringPrepState
+       _sort.text = '0';
+       _categoryId.clear();
+       _layout = SurfaceAtlasLayout.grid;
+-      _duplicateExemption = null;
++      _creationNote = null;
+     });
+   }
+ 
+@@ -252,10 +273,75 @@ class _SurfaceStudioAtlasAuthoringPrepState
+       _sort.text = '${row.sortOrder}';
+       _layout = row.atlas.geometry.layout;
+       _categoryId.text = row.categoryId ?? '';
+-      _duplicateExemption = row.id;
++      _creationNote = null;
+     });
+   }
+ 
++  void _addToWorkCatalog() {
++    final callback = widget.onSurfaceCatalogChanged;
++    if (callback == null) {
++      return;
++    }
++    setState(() => _creationNote = null);
++    final errs = validateSurfaceStudioAtlasDraft(
++      readModel: widget.readModel,
++      idRaw: _id.text,
++      nameRaw: _name.text,
++      tilesetIdRaw: _tilesetId.text,
++      tileWidthRaw: _tileW.text,
++      tileHeightRaw: _tileH.text,
++      columnsRaw: _cols.text,
++      rowsRaw: _rows.text,
++      sortOrderRaw: _sort.text,
++      categoryIdRaw: _categoryId.text,
++    );
++    if (errs.isNotEmpty) {
++      return;
++    }
++    final draft = tryBuildDraftFromForm(
++      idRaw: _id.text,
++      nameRaw: _name.text,
++      tilesetIdRaw: _tilesetId.text,
++      tileWidthRaw: _tileW.text,
++      tileHeightRaw: _tileH.text,
++      columnsRaw: _cols.text,
++      rowsRaw: _rows.text,
++      sortOrderRaw: _sort.text,
++      categoryIdRaw: _categoryId.text,
++      layout: _layout,
++    );
++    if (draft == null) {
++      return;
++    }
++    final atlas = tryBuildProjectSurfaceAtlasFromDraft(draft);
++    if (atlas == null) {
++      return;
++    }
++    try {
++      final next = ProjectSurfaceCatalog(
++        atlases: [
++          ...widget.readModel.catalog.atlases,
++          atlas,
++        ],
++        animations: List<ProjectSurfaceAnimation>.from(
++          widget.readModel.catalog.animations,
++        ),
++        presets: List<ProjectSurfacePreset>.from(
++          widget.readModel.catalog.presets,
++        ),
++      );
++      callback(next);
++      setState(() {
++        _creationNote =
++            'Atlas créé dans le catalogue de travail. Sauvegarde projet non effectuée.';
++      });
++    } on ValidationException {
++      setState(() {
++        _creationNote = 'Un atlas existe déjà avec cet id.';
++      });
++    }
++  }
++
+   String _layoutMenuLabel(SurfaceAtlasLayout l) {
+     switch (l) {
+       case SurfaceAtlasLayout.grid:
+@@ -284,7 +370,6 @@ class _SurfaceStudioAtlasAuthoringPrepState
+       rowsRaw: _rows.text,
+       sortOrderRaw: _sort.text,
+       categoryIdRaw: _categoryId.text,
+-      duplicateIdExemption: _duplicateExemption,
+     );
+     final isValid = errs.isEmpty;
+     final draft = tryBuildDraftFromForm(
+@@ -348,13 +433,21 @@ class _SurfaceStudioAtlasAuthoringPrepState
+           ),
+           const SizedBox(height: 4),
+           Text(
+-            'Brouillon local non sauvegardé',
++            'Brouillon local non sauvegardé sur disque',
+             style: TextStyle(
+               color: subtle,
+               fontSize: 12,
+               fontWeight: FontWeight.w600,
+             ),
+           ),
++          const SizedBox(height: 4),
++          Text(
++            'Création locale : le projet n’est pas sauvegardé sur disque.',
++            style: TextStyle(
++              color: subtle.withValues(alpha: 0.95),
++              fontSize: 11,
++            ),
++          ),
+           const SizedBox(height: 6),
+           Wrap(
+             spacing: 8,
+@@ -373,7 +466,7 @@ class _SurfaceStudioAtlasAuthoringPrepState
+               const SizedBox(width: 6),
+               _localBadge(
+                 context,
+-                'Aucune modification du catalogue',
++                'Catalogue de travail (mémoire)',
+                 label,
+                 accent,
+               ),
+@@ -407,8 +500,26 @@ class _SurfaceStudioAtlasAuthoringPrepState
+                 onPressed: _loadFromSelection,
+                 child: const Text('Charger la sélection dans le brouillon'),
+               ),
++              if (widget.onSurfaceCatalogChanged != null)
++                CupertinoButton(
++                  key: const ValueKey('surface_studio_create_atlas_work_catalog'),
++                  padding:
++                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
++                  onPressed: isValid ? _addToWorkCatalog : null,
++                  child: const Text('Créer l’atlas dans le catalogue de travail'),
++                ),
+             ],
+           ),
++          if (_creationNote != null) ...[
++            const SizedBox(height: 8),
++            Text(
++              _creationNote!,
++              style: const TextStyle(
++                fontSize: 12,
++                fontWeight: FontWeight.w600,
++              ).copyWith(color: accent),
++            ),
++          ],
+           const SizedBox(height: 8),
+           material.TextField(
+             key: const ValueKey('atlas_draft_id'),
+diff --git a/packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart b/packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
+index 63bed7ac..3850cff1 100644
+--- a/packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
++++ b/packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
+@@ -49,10 +49,25 @@ class SurfaceStudioPanel extends StatefulWidget {
+ class _SurfaceStudioPanelState extends State<SurfaceStudioPanel> {
+   /// Sélection d’inspection : locale au widget, jamais écrite dans le manifest.
+   SurfaceStudioSelection _selection = const SurfaceStudioSelection.none();
++  late SurfaceStudioReadModel _readModel;
++
++  @override
++  void initState() {
++    super.initState();
++    _readModel = widget.readModel;
++  }
++
++  @override
++  void didUpdateWidget(covariant SurfaceStudioPanel oldWidget) {
++    super.didUpdateWidget(oldWidget);
++    if (widget.readModel != oldWidget.readModel) {
++      _readModel = widget.readModel;
++    }
++  }
+ 
+   @override
+   Widget build(BuildContext context) {
+-    final s = widget.readModel.summary;
++    final s = _readModel.summary;
+     final label = EditorChrome.primaryLabel(context);
+     final subtle = EditorChrome.subtleLabel(context);
+ 
+@@ -92,8 +107,8 @@ class _SurfaceStudioPanelState extends State<SurfaceStudioPanel> {
+           ),
+           const SizedBox(height: 8),
+           Text(
+-            'Dans ce lot, il s’agit d’une vue de lecture et de préparation '
+-            'uniquement : aucune création, édition, suppression ou sauvegarde.',
++            'Vous pouvez ajouter un atlas au catalogue de travail en mémoire. '
++            'Aucune sauvegarde projet sur disque, pas d’édition ni suppression d’atlas existant.',
+             style: TextStyle(
+               color: subtle.withValues(alpha: 0.92),
+               fontSize: 12,
+@@ -111,23 +126,34 @@ class _SurfaceStudioPanelState extends State<SurfaceStudioPanel> {
+           SurfaceStudioSelectionSummary(selection: _selection),
+           const SizedBox(height: 12),
+           SurfaceStudioSelectionInspector(
+-            readModel: widget.readModel,
++            readModel: _readModel,
+             selection: _selection,
+           ),
+           const SizedBox(height: 12),
+           SurfaceStudioCatalogBrowser(
+-            readModel: widget.readModel,
++            readModel: _readModel,
+             selection: _selection,
+             onSelectionChanged: (v) {
+               setState(() => _selection = v);
+             },
+           ),
+           const SizedBox(height: 16),
+-          SurfaceStudioDiagnosticsView(readModel: widget.readModel),
++          SurfaceStudioDiagnosticsView(readModel: _readModel),
+           const SizedBox(height: 20),
+           SurfaceStudioAtlasAuthoringPrep(
+-            readModel: widget.readModel,
++            readModel: _readModel,
+             selection: _selection,
++            onSurfaceCatalogChanged: (cat) {
++              final newId = cat.atlases.isNotEmpty
++                  ? cat.atlases.last.id
++                  : '';
++              setState(() {
++                _readModel = buildSurfaceStudioReadModelFromCatalog(cat);
++                if (newId.isNotEmpty) {
++                  _selection = SurfaceStudioSelection.atlas(newId);
++                }
++              });
++            },
+           ),
+           const SizedBox(height: 20),
+           const _FutureActions(
+diff --git a/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart b/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart
+index 51581601..d3c1693c 100644
+--- a/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart
++++ b/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart
+@@ -1,3 +1,4 @@
++import 'package:flutter/cupertino.dart';
+ import 'package:flutter/material.dart';
+ import 'package:flutter_test/flutter_test.dart';
+ import 'package:map_core/map_core.dart';
+@@ -16,7 +17,10 @@ void main() {
+         ),
+       );
+       expect(find.text('Préparation atlas'), findsOneWidget);
+-      expect(find.text('Brouillon local non sauvegardé'), findsOneWidget);
++      expect(
++        find.text('Brouillon local non sauvegardé sur disque'),
++        findsOneWidget,
++      );
+       expect(find.text('Brouillon local'), findsOneWidget);
+       expect(find.text('Non sauvegardé'), findsOneWidget);
+       final w = find.byKey(const ValueKey('atlas_draft_tile_w'));
+@@ -136,7 +140,7 @@ void main() {
+       );
+     });
+ 
+-    testWidgets('id dupliqué cat sans exemption: erreur', (tester) async {
++    testWidgets('id dupliqué dans le catalogue: erreur', (tester) async {
+       await tester.pumpWidget(
+         _wrap(
+           SurfaceStudioAtlasAuthoringPrep(
+@@ -153,7 +157,7 @@ void main() {
+       await tester.enterText(tsF, 't');
+       await tester.pump();
+       expect(
+-        find.text('Cet identifiant existe déjà dans le catalogue'),
++        find.text('Un atlas existe déjà avec cet id.'),
+         findsOneWidget,
+       );
+     });
+@@ -293,6 +297,195 @@ void main() {
+       expect(find.textContaining('Aperçu : 32×32'), findsOneWidget);
+     });
+   });
++
++  group('SurfaceStudioAtlasAuthoringPrep (Lot 61)', () {
++    testWidgets('création brouillon valide émet le catalogue + atlas', (tester) async {
++      final out = <ProjectSurfaceCatalog>[];
++      await tester.pumpWidget(
++        _wrap(
++          SurfaceStudioAtlasAuthoringPrep(
++            readModel: _emptyReadModel(),
++            selection: const SurfaceStudioSelection.none(),
++            onSurfaceCatalogChanged: out.add,
++          ),
++        ),
++      );
++      final idF = find.byKey(const ValueKey('atlas_draft_id'));
++      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
++      final tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
++      await tester.enterText(idF, 'a-new');
++      await tester.enterText(nameF, 'My');
++      await tester.enterText(tsF, 'tset');
++      await tester.pump();
++      await tester.tap(
++        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
++      );
++      await tester.pump();
++      expect(out, hasLength(1));
++      final c = out.single;
++      expect(c.atlases, hasLength(1));
++      expect(c.animations, isEmpty);
++      expect(c.presets, isEmpty);
++      final a = c.atlases.single;
++      expect(a.id, 'a-new');
++      expect(a.name, 'My');
++      expect(a.tilesetId, 'tset');
++      expect(a.sortOrder, 0);
++      expect(a.categoryId, isNull);
++      expect(a.geometry.tileSize.width, 32);
++      expect(a.geometry.tileSize.height, 32);
++      expect(a.geometry.gridSize.columns, 1);
++      expect(a.geometry.gridSize.rows, 1);
++      expect(a.geometry.layout, SurfaceAtlasLayout.grid);
++      expect(
++        find.text(
++          'Atlas créé dans le catalogue de travail. Sauvegarde projet non effectuée.',
++        ),
++        findsOneWidget,
++      );
++    });
++
++    testWidgets('création refusée si brouillon invalide (pas de callback)',
++        (tester) async {
++      final out = <ProjectSurfaceCatalog>[];
++      await tester.pumpWidget(
++        _wrap(
++          SurfaceStudioAtlasAuthoringPrep(
++            readModel: _emptyReadModel(),
++            selection: const SurfaceStudioSelection.none(),
++            onSurfaceCatalogChanged: out.add,
++          ),
++        ),
++      );
++      final create = find.descendant(
++        of: find.byKey(kSurfaceStudioAtlasAuthoringPrepKey),
++        matching: find.byKey(
++          const ValueKey('surface_studio_create_atlas_work_catalog'),
++        ),
++      );
++      final btn = tester.widget<CupertinoButton>(create);
++      expect(btn.onPressed, isNull);
++      expect(out, isEmpty);
++    });
++
++    testWidgets('id vide: pas d’appel callback en tap (bouton inactif)',
++        (tester) async {
++      final out = <ProjectSurfaceCatalog>[];
++      await tester.pumpWidget(
++        _wrap(
++          SurfaceStudioAtlasAuthoringPrep(
++            readModel: _emptyReadModel(),
++            selection: const SurfaceStudioSelection.none(),
++            onSurfaceCatalogChanged: out.add,
++          ),
++        ),
++      );
++      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
++      final tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
++      await tester.enterText(nameF, 'N');
++      await tester.enterText(tsF, 't');
++      await tester.pump();
++      final create = find.descendant(
++        of: find.byKey(kSurfaceStudioAtlasAuthoringPrepKey),
++        matching: find.byKey(
++          const ValueKey('surface_studio_create_atlas_work_catalog'),
++        ),
++      );
++      expect(tester.widget<CupertinoButton>(create).onPressed, isNull);
++    });
++
++    testWidgets('dupliquer id: création inactivable', (tester) async {
++      final out = <ProjectSurfaceCatalog>[];
++      await tester.pumpWidget(
++        _wrap(
++          SurfaceStudioAtlasAuthoringPrep(
++            readModel: _minimalRead(),
++            selection: const SurfaceStudioSelection.none(),
++            onSurfaceCatalogChanged: out.add,
++          ),
++        ),
++      );
++      final idF = find.byKey(const ValueKey('atlas_draft_id'));
++      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
++      final tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
++      await tester.enterText(idF, 'water-atlas');
++      await tester.enterText(nameF, 'X');
++      await tester.enterText(tsF, 't');
++      await tester.pump();
++      final create = find.descendant(
++        of: find.byKey(kSurfaceStudioAtlasAuthoringPrepKey),
++        matching: find.byKey(
++          const ValueKey('surface_studio_create_atlas_work_catalog'),
++        ),
++      );
++      expect(tester.widget<CupertinoButton>(create).onPressed, isNull);
++      expect(out, isEmpty);
++    });
++
++    testWidgets('chargé depuis sélection: même id = doublon; nouvel id = ajout',
++        (tester) async {
++      final out = <ProjectSurfaceCatalog>[];
++      var rm = _minimalRead();
++      await tester.pumpWidget(
++        _wrap(
++          SurfaceStudioAtlasAuthoringPrep(
++            readModel: rm,
++            selection: SurfaceStudioSelection.atlas('water-atlas'),
++            onSurfaceCatalogChanged: out.add,
++          ),
++        ),
++      );
++      await tester.tap(
++        find.text('Charger la sélection dans le brouillon'),
++      );
++      await tester.pump();
++      var create = find.descendant(
++        of: find.byKey(kSurfaceStudioAtlasAuthoringPrepKey),
++        matching: find.byKey(
++          const ValueKey('surface_studio_create_atlas_work_catalog'),
++        ),
++      );
++      expect(tester.widget<CupertinoButton>(create).onPressed, isNull);
++      final idF = find.byKey(const ValueKey('atlas_draft_id'));
++      await tester.enterText(idF, 'water-bis');
++      await tester.pump();
++      expect(tester.widget<CupertinoButton>(create).onPressed, isNotNull);
++      final beforeAtlas = rm.catalog.atlases.single;
++      await tester.tap(create);
++      await tester.pump();
++      expect(out, hasLength(1));
++      expect(out.single.atlases, hasLength(2));
++      expect(
++        out.single.atlases.map((a) => a.id).toList(),
++        ['water-atlas', 'water-bis'],
++      );
++      expect(
++        out.single.atlases.first,
++        beforeAtlas,
++      );
++    });
++
++    testWidgets('interdits save projet (libellés)', (tester) async {
++      await tester.pumpWidget(
++        _wrap(
++          SurfaceStudioAtlasAuthoringPrep(
++            readModel: _minimalRead(),
++            selection: const SurfaceStudioSelection.none(),
++            onSurfaceCatalogChanged: (_) {},
++          ),
++        ),
++      );
++      for (final s in <String>[
++        'Sauvegarder le projet',
++        'Enregistrer le projet',
++        'Écrire sur disque',
++        'Save project',
++        'Write to disk',
++      ]) {
++        expect(find.text(s), findsNothing);
++      }
++    });
++  });
+ }
+ 
+ Widget _wrap(Widget child) {
+diff --git a/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart b/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
+index 7f60b1d6..6f2af789 100644
+--- a/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
++++ b/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
+@@ -600,7 +600,97 @@ void main() {
+       );
+       await tester.ensureVisible(find.text('Préparation atlas'));
+       expect(find.text('Préparation atlas'), findsOneWidget);
+-      expect(find.text('Brouillon local non sauvegardé'), findsOneWidget);
++      expect(
++        find.text('Brouillon local non sauvegardé sur disque'),
++        findsOneWidget,
++      );
++    });
++
++    testWidgets('61.1 — action création atlas dans le catalogue de travail',
++        (tester) async {
++      await tester.pumpWidget(
++        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
++      );
++      await tester.ensureVisible(
++        find.text('Créer l’atlas dans le catalogue de travail'),
++      );
++      expect(
++        find.text('Créer l’atlas dans le catalogue de travail'),
++        findsOneWidget,
++      );
++    });
++
++    testWidgets(
++        '61.2 — créer atlas (catalogue vide) : compteur atlas 1, browser, '
++        'inspecteur',
++        (tester) async {
++      await tester.pumpWidget(
++        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
++      );
++      final idF = find.byKey(const ValueKey('atlas_draft_id'));
++      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
++      final tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
++      await tester.ensureVisible(idF);
++      await tester.enterText(idF, 'lot61-a');
++      await tester.enterText(nameF, 'Lot61 A');
++      await tester.enterText(tsF, 'tileset-x');
++      await tester.pump();
++      await tester.ensureVisible(
++        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
++      );
++      await tester.tap(
++        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
++      );
++      await tester.pump();
++      final counters =
++          find.byKey(const ValueKey('surface_studio_header_counters'));
++      expect(
++        find.descendant(of: counters, matching: find.text('1')),
++        findsOneWidget,
++      );
++      expect(
++        find.descendant(of: counters, matching: find.text('0')),
++        findsNWidgets(2),
++      );
++      expect(find.text('Lot61 A'), findsWidgets);
++      expect(find.text('Diagnostics Surface'), findsOneWidget);
++    });
++
++    testWidgets(
++        '61.3 — créer second atlas : compteur 2, animations/presets inchangés',
++        (tester) async {
++      await tester.pumpWidget(
++        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
++      );
++      final idF = find.byKey(const ValueKey('atlas_draft_id'));
++      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
++      final tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
++      await tester.ensureVisible(idF);
++      await tester.enterText(idF, 'grass-a');
++      await tester.enterText(nameF, 'Grass');
++      await tester.enterText(tsF, 'ts-g');
++      await tester.pump();
++      await tester.ensureVisible(
++        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
++      );
++      await tester.tap(
++        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
++      );
++      await tester.pump();
++      final counters =
++          find.byKey(const ValueKey('surface_studio_header_counters'));
++      expect(
++        find.descendant(of: counters, matching: find.text('2')),
++        findsOneWidget,
++      );
++      expect(
++        find.descendant(of: counters, matching: find.text('1')),
++        findsNWidgets(2),
++      );
++      expect(find.text('Water Atlas'), findsOneWidget);
++      expect(find.text('Water Isolated Loop'), findsOneWidget);
++      expect(find.text('Water Surface'), findsOneWidget);
++      expect(find.text('grass-a'), findsWidgets);
+     });
+   });
+ }
+```
+
+### Contenu intégral des fichiers modifiés (version worktree post-Lot 61)
+
+#### `packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart`
+
+```dart
+import 'package:flutter/cupertino.dart';
+import 'package:flutter/material.dart' as material;
+import 'package:map_core/map_core.dart';
+
+import '../../ui/shared/cupertino_editor_widgets.dart';
+import 'surface_studio_selection.dart';
+
+const ValueKey<String> kSurfaceStudioAtlasAuthoringPrepKey =
+    ValueKey<String>('SurfaceStudioAtlasAuthoringPrep');
+
+List<String> validateSurfaceStudioAtlasDraft({
+  required SurfaceStudioReadModel readModel,
+  required String idRaw,
+  required String nameRaw,
+  required String tilesetIdRaw,
+  required String tileWidthRaw,
+  required String tileHeightRaw,
+  required String columnsRaw,
+  required String rowsRaw,
+  required String sortOrderRaw,
+  required String? categoryIdRaw,
+}) {
+  final errors = <String>[];
+  final id = idRaw.trim();
+  final name = nameRaw.trim();
+  final tilesetId = tilesetIdRaw.trim();
+  if (id.isEmpty) {
+    errors.add('Identifiant requis');
+  }
+  if (name.isEmpty) {
+    errors.add('Nom requis');
+  }
+  if (tilesetId.isEmpty) {
+    errors.add('Identifiant tileset requis');
+  }
+
+  int? tw = int.tryParse(tileWidthRaw.trim());
+  if (tw == null) {
+    errors.add('Largeur de tuile : entier requis');
+  } else if (tw <= 0) {
+    errors.add('Largeur de tuile : valeur positive requise');
+  }
+
+  int? th = int.tryParse(tileHeightRaw.trim());
+  if (th == null) {
+    errors.add('Hauteur de tuile : entier requis');
+  } else if (th <= 0) {
+    errors.add('Hauteur de tuile : valeur positive requise');
+  }
+
+  int? c = int.tryParse(columnsRaw.trim());
+  if (c == null) {
+    errors.add('Colonnes : entier requis');
+  } else if (c <= 0) {
+    errors.add('Colonnes : valeur positive requise');
+  }
+
+  int? r = int.tryParse(rowsRaw.trim());
+  if (r == null) {
+    errors.add('Lignes : entier requis');
+  } else if (r <= 0) {
+    errors.add('Lignes : valeur positive requise');
+  }
+
+  int? so = int.tryParse(sortOrderRaw.trim());
+  if (so == null) {
+    errors.add('Ordre : entier requis');
+  } else if (so < 0) {
+    errors.add('Ordre : valeur négative interdite pour ce brouillon');
+  }
+
+  if (id.isNotEmpty) {
+    for (final a in readModel.atlases) {
+      if (a.id == id) {
+        errors.add('Un atlas existe déjà avec cet id.');
+        break;
+      }
+    }
+  }
+
+  return errors;
+}
+
+ProjectSurfaceAtlas? tryBuildProjectSurfaceAtlasFromDraft(
+  SurfaceStudioAtlasDraft draft,
+) {
+  try {
+    return ProjectSurfaceAtlas(
+      id: draft.id,
+      name: draft.name,
+      tilesetId: draft.tilesetId,
+      geometry: SurfaceAtlasGeometry(
+        tileSize: SurfaceAtlasTileSize(
+          width: draft.tileWidth,
+          height: draft.tileHeight,
+        ),
+        gridSize: SurfaceAtlasGridSize(
+          columns: draft.columns,
+          rows: draft.rows,
+        ),
+        layout: draft.layout,
+      ),
+      categoryId: draft.categoryId,
+      sortOrder: draft.sortOrder,
+    );
+  } on ValidationException {
+    return null;
+  }
+}
+
+class SurfaceStudioAtlasDraft {
+  const SurfaceStudioAtlasDraft({
+    required this.id,
+    required this.name,
+    required this.tilesetId,
+    required this.tileWidth,
+    required this.tileHeight,
+    required this.columns,
+    required this.rows,
+    required this.layout,
+    required this.sortOrder,
+    this.categoryId,
+  });
+
+  final String id;
+  final String name;
+  final String tilesetId;
+  final int tileWidth;
+  final int tileHeight;
+  final int columns;
+  final int rows;
+  final SurfaceAtlasLayout layout;
+  final int sortOrder;
+  final String? categoryId;
+
+  int get tileCount => columns * rows;
+}
+
+SurfaceStudioAtlasDraft? tryBuildDraftFromForm({
+  required String idRaw,
+  required String nameRaw,
+  required String tilesetIdRaw,
+  required String tileWidthRaw,
+  required String tileHeightRaw,
+  required String columnsRaw,
+  required String rowsRaw,
+  required String sortOrderRaw,
+  required String? categoryIdRaw,
+  required SurfaceAtlasLayout layout,
+}) {
+  final id = idRaw.trim();
+  final name = nameRaw.trim();
+  final tilesetId = tilesetIdRaw.trim();
+  final tw = int.tryParse(tileWidthRaw.trim());
+  final th = int.tryParse(tileHeightRaw.trim());
+  final c = int.tryParse(columnsRaw.trim());
+  final r = int.tryParse(rowsRaw.trim());
+  final so = int.tryParse(sortOrderRaw.trim());
+  if (id.isEmpty ||
+      name.isEmpty ||
+      tilesetId.isEmpty ||
+      tw == null ||
+      th == null ||
+      c == null ||
+      r == null ||
+      so == null) {
+    return null;
+  }
+  if (tw <= 0 || th <= 0 || c <= 0 || r <= 0 || so < 0) {
+    return null;
+  }
+  final cat = categoryIdRaw?.trim();
+  return SurfaceStudioAtlasDraft(
+    id: id,
+    name: name,
+    tilesetId: tilesetId,
+    tileWidth: tw,
+    tileHeight: th,
+    columns: c,
+    rows: r,
+    layout: layout,
+    sortOrder: so,
+    categoryId: (cat == null || cat.isEmpty) ? null : cat,
+  );
+}
+
+class SurfaceStudioAtlasAuthoringPrep extends StatefulWidget {
+  const SurfaceStudioAtlasAuthoringPrep({
+    super.key,
+    required this.readModel,
+    required this.selection,
+    this.onSurfaceCatalogChanged,
+  });
+
+  final SurfaceStudioReadModel readModel;
+  final SurfaceStudioSelection selection;
+  final ValueChanged<ProjectSurfaceCatalog>? onSurfaceCatalogChanged;
+
+  @override
+  State<SurfaceStudioAtlasAuthoringPrep> createState() =>
+      _SurfaceStudioAtlasAuthoringPrepState();
+}
+
+class _SurfaceStudioAtlasAuthoringPrepState
+    extends State<SurfaceStudioAtlasAuthoringPrep> {
+  late final TextEditingController _id = TextEditingController();
+  late final TextEditingController _name = TextEditingController();
+  late final TextEditingController _tilesetId = TextEditingController();
+  late final TextEditingController _tileW = TextEditingController(text: '32');
+  late final TextEditingController _tileH = TextEditingController(text: '32');
+  late final TextEditingController _cols = TextEditingController(text: '1');
+  late final TextEditingController _rows = TextEditingController(text: '1');
+  late final TextEditingController _sort = TextEditingController(text: '0');
+  late final TextEditingController _categoryId = TextEditingController();
+
+  SurfaceAtlasLayout _layout = SurfaceAtlasLayout.grid;
+  bool _showPreview = false;
+  String? _creationNote;
+
+  @override
+  void dispose() {
+    _id.dispose();
+    _name.dispose();
+    _tilesetId.dispose();
+    _tileW.dispose();
+    _tileH.dispose();
+    _cols.dispose();
+    _rows.dispose();
+    _sort.dispose();
+    _categoryId.dispose();
+    super.dispose();
+  }
+
+  void _resetToDefaults() {
+    setState(() {
+      _id.clear();
+      _name.clear();
+      _tilesetId.clear();
+      _tileW.text = '32';
+      _tileH.text = '32';
+      _cols.text = '1';
+      _rows.text = '1';
+      _sort.text = '0';
+      _categoryId.clear();
+      _layout = SurfaceAtlasLayout.grid;
+      _creationNote = null;
+    });
+  }
+
+  void _loadFromSelection() {
+    final sel = widget.selection;
+    if (!sel.isAtlas) {
+      return;
+    }
+    SurfaceStudioAtlasReadModel? row;
+    for (final a in widget.readModel.atlases) {
+      if (a.id == sel.id) {
+        row = a;
+        break;
+      }
+    }
+    if (row == null) {
+      return;
+    }
+    setState(() {
+      _id.text = row!.atlas.id;
+      _name.text = row.atlas.name;
+      _tilesetId.text = row.atlas.tilesetId;
+      _tileW.text = '${row.tileWidth}';
+      _tileH.text = '${row.tileHeight}';
+      _cols.text = '${row.columns}';
+      _rows.text = '${row.rows}';
+      _sort.text = '${row.sortOrder}';
+      _layout = row.atlas.geometry.layout;
+      _categoryId.text = row.categoryId ?? '';
+      _creationNote = null;
+    });
+  }
+
+  void _addToWorkCatalog() {
+    final callback = widget.onSurfaceCatalogChanged;
+    if (callback == null) {
+      return;
+    }
+    setState(() => _creationNote = null);
+    final errs = validateSurfaceStudioAtlasDraft(
+      readModel: widget.readModel,
+      idRaw: _id.text,
+      nameRaw: _name.text,
+      tilesetIdRaw: _tilesetId.text,
+      tileWidthRaw: _tileW.text,
+      tileHeightRaw: _tileH.text,
+      columnsRaw: _cols.text,
+      rowsRaw: _rows.text,
+      sortOrderRaw: _sort.text,
+      categoryIdRaw: _categoryId.text,
+    );
+    if (errs.isNotEmpty) {
+      return;
+    }
+    final draft = tryBuildDraftFromForm(
+      idRaw: _id.text,
+      nameRaw: _name.text,
+      tilesetIdRaw: _tilesetId.text,
+      tileWidthRaw: _tileW.text,
+      tileHeightRaw: _tileH.text,
+      columnsRaw: _cols.text,
+      rowsRaw: _rows.text,
+      sortOrderRaw: _sort.text,
+      categoryIdRaw: _categoryId.text,
+      layout: _layout,
+    );
+    if (draft == null) {
+      return;
+    }
+    final atlas = tryBuildProjectSurfaceAtlasFromDraft(draft);
+    if (atlas == null) {
+      return;
+    }
+    try {
+      final next = ProjectSurfaceCatalog(
+        atlases: [
+          ...widget.readModel.catalog.atlases,
+          atlas,
+        ],
+        animations: List<ProjectSurfaceAnimation>.from(
+          widget.readModel.catalog.animations,
+        ),
+        presets: List<ProjectSurfacePreset>.from(
+          widget.readModel.catalog.presets,
+        ),
+      );
+      callback(next);
+      setState(() {
+        _creationNote =
+            'Atlas créé dans le catalogue de travail. Sauvegarde projet non effectuée.';
+      });
+    } on ValidationException {
+      setState(() {
+        _creationNote = 'Un atlas existe déjà avec cet id.';
+      });
+    }
+  }
+
+  String _layoutMenuLabel(SurfaceAtlasLayout l) {
+    switch (l) {
+      case SurfaceAtlasLayout.grid:
+        return 'Grille libre';
+      case SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames:
+        return 'Colonnes = variantes, lignes = frames';
+      case SurfaceAtlasLayout.rowsAreVariantsColumnsAreFrames:
+        return 'Lignes = variantes, colonnes = frames';
+    }
+  }
+
+  @override
+  Widget build(BuildContext context) {
+    final label = EditorChrome.primaryLabel(context);
+    final subtle = EditorChrome.subtleLabel(context);
+    const accent = Color(0xFF2DD4BF);
+
+    final errs = validateSurfaceStudioAtlasDraft(
+      readModel: widget.readModel,
+      idRaw: _id.text,
+      nameRaw: _name.text,
+      tilesetIdRaw: _tilesetId.text,
+      tileWidthRaw: _tileW.text,
+      tileHeightRaw: _tileH.text,
+      columnsRaw: _cols.text,
+      rowsRaw: _rows.text,
+      sortOrderRaw: _sort.text,
+      categoryIdRaw: _categoryId.text,
+    );
+    final isValid = errs.isEmpty;
+    final draft = tryBuildDraftFromForm(
+      idRaw: _id.text,
+      nameRaw: _name.text,
+      tilesetIdRaw: _tilesetId.text,
+      tileWidthRaw: _tileW.text,
+      tileHeightRaw: _tileH.text,
+      columnsRaw: _cols.text,
+      rowsRaw: _rows.text,
+      sortOrderRaw: _sort.text,
+      categoryIdRaw: _categoryId.text,
+      layout: _layout,
+    );
+
+    final sel = widget.selection;
+    String? contextNote;
+    if (sel.isAnimation || sel.isPreset) {
+      contextNote = 'La sélection actuelle n’est pas un atlas.';
+    } else if (sel.isAtlas) {
+      var found = false;
+      for (final a in widget.readModel.atlases) {
+        if (a.id == sel.id) {
+          found = true;
+          break;
+        }
+      }
+      if (!found) {
+        contextNote =
+            'Atlas sélectionné introuvable, brouillon atlas indépendant.';
+      }
+    }
+
+    return material.Material(
+      type: material.MaterialType.transparency,
+      child: Container(
+        key: kSurfaceStudioAtlasAuthoringPrepKey,
+        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
+        decoration: BoxDecoration(
+          color: EditorChrome.elevatedPanelBackground(context),
+          borderRadius: BorderRadius.circular(14),
+          border: Border.all(
+            color: Color.lerp(
+              EditorChrome.editorIslandRim(context),
+              accent,
+              0.35,
+            )!,
+          ),
+          boxShadow: EditorChrome.sectionCardShadows(context),
+        ),
+        child: Column(
+        crossAxisAlignment: CrossAxisAlignment.stretch,
+        children: [
+          Text(
+            'Préparation atlas',
+            style: TextStyle(
+              color: label,
+              fontSize: 16,
+              fontWeight: FontWeight.w800,
+            ),
+          ),
+          const SizedBox(height: 4),
+          Text(
+            'Brouillon local non sauvegardé sur disque',
+            style: TextStyle(
+              color: subtle,
+              fontSize: 12,
+              fontWeight: FontWeight.w600,
+            ),
+          ),
+          const SizedBox(height: 4),
+          Text(
+            'Création locale : le projet n’est pas sauvegardé sur disque.',
+            style: TextStyle(
+              color: subtle.withValues(alpha: 0.95),
+              fontSize: 11,
+            ),
+          ),
+          const SizedBox(height: 6),
+          Wrap(
+            spacing: 8,
+            runSpacing: 4,
+            children: [
+              _localBadge(context, 'Brouillon local', label, accent),
+              const SizedBox(width: 6),
+              _localBadge(context, 'Non sauvegardé', label, accent),
+              const SizedBox(width: 6),
+              _localBadge(
+                context,
+                'Validation locale uniquement',
+                label,
+                accent,
+              ),
+              const SizedBox(width: 6),
+              _localBadge(
+                context,
+                'Catalogue de travail (mémoire)',
+                label,
+                accent,
+              ),
+            ],
+          ),
+          if (contextNote != null) ...[
+            const SizedBox(height: 8),
+            Text(
+              contextNote,
+              style: TextStyle(
+                color: subtle,
+                fontSize: 11,
+                fontStyle: FontStyle.italic,
+              ),
+            ),
+          ],
+          const SizedBox(height: 12),
+          Wrap(
+            spacing: 8,
+            runSpacing: 6,
+            children: [
+              CupertinoButton(
+                padding:
+                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
+                onPressed: _resetToDefaults,
+                child: const Text('Réinitialiser le brouillon'),
+              ),
+              CupertinoButton(
+                padding:
+                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
+                onPressed: _loadFromSelection,
+                child: const Text('Charger la sélection dans le brouillon'),
+              ),
+              if (widget.onSurfaceCatalogChanged != null)
+                CupertinoButton(
+                  key: const ValueKey('surface_studio_create_atlas_work_catalog'),
+                  padding:
+                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
+                  onPressed: isValid ? _addToWorkCatalog : null,
+                  child: const Text('Créer l’atlas dans le catalogue de travail'),
+                ),
+            ],
+          ),
+          if (_creationNote != null) ...[
+            const SizedBox(height: 8),
+            Text(
+              _creationNote!,
+              style: const TextStyle(
+                fontSize: 12,
+                fontWeight: FontWeight.w600,
+              ).copyWith(color: accent),
+            ),
+          ],
+          const SizedBox(height: 8),
+          material.TextField(
+            key: const ValueKey('atlas_draft_id'),
+            controller: _id,
+            onChanged: (_) => setState(() {}),
+            style: TextStyle(color: label, fontSize: 13),
+            decoration: const material.InputDecoration(
+              labelText: 'Identifiant',
+              isDense: true,
+            ),
+          ),
+          const SizedBox(height: 6),
+          material.TextField(
+            key: const ValueKey('atlas_draft_name'),
+            controller: _name,
+            onChanged: (_) => setState(() {}),
+            style: TextStyle(color: label, fontSize: 13),
+            decoration: const material.InputDecoration(
+              labelText: 'Nom',
+              isDense: true,
+            ),
+          ),
+          const SizedBox(height: 6),
+          material.TextField(
+            key: const ValueKey('atlas_draft_tileset'),
+            controller: _tilesetId,
+            onChanged: (_) => setState(() {}),
+            style: TextStyle(color: label, fontSize: 13),
+            decoration: const material.InputDecoration(
+              labelText: 'Identifiant tileset',
+              isDense: true,
+            ),
+          ),
+          const SizedBox(height: 6),
+          Row(
+            children: [
+              Expanded(
+                child: material.TextField(
+                  key: const ValueKey('atlas_draft_tile_w'),
+                  controller: _tileW,
+                  onChanged: (_) => setState(() {}),
+                  keyboardType: TextInputType.number,
+                  style: TextStyle(color: label, fontSize: 13),
+                  decoration: const material.InputDecoration(
+                    labelText: 'Largeur tuile',
+                    isDense: true,
+                  ),
+                ),
+              ),
+              const SizedBox(width: 8),
+              Expanded(
+                child: material.TextField(
+                  key: const ValueKey('atlas_draft_tile_h'),
+                  controller: _tileH,
+                  onChanged: (_) => setState(() {}),
+                  keyboardType: TextInputType.number,
+                  style: TextStyle(color: label, fontSize: 13),
+                  decoration: const material.InputDecoration(
+                    labelText: 'Hauteur tuile',
+                    isDense: true,
+                  ),
+                ),
+              ),
+            ],
+          ),
+          const SizedBox(height: 6),
+          Row(
+            children: [
+              Expanded(
+                child: material.TextField(
+                  key: const ValueKey('atlas_draft_cols'),
+                  controller: _cols,
+                  onChanged: (_) => setState(() {}),
+                  keyboardType: TextInputType.number,
+                  style: TextStyle(color: label, fontSize: 13),
+                  decoration: const material.InputDecoration(
+                    labelText: 'Colonnes',
+                    isDense: true,
+                  ),
+                ),
+              ),
+              const SizedBox(width: 8),
+              Expanded(
+                child: material.TextField(
+                  key: const ValueKey('atlas_draft_rows'),
+                  controller: _rows,
+                  onChanged: (_) => setState(() {}),
+                  keyboardType: TextInputType.number,
+                  style: TextStyle(color: label, fontSize: 13),
+                  decoration: const material.InputDecoration(
+                    labelText: 'Lignes',
+                    isDense: true,
+                  ),
+                ),
+              ),
+            ],
+          ),
+          const SizedBox(height: 6),
+          Row(
+            crossAxisAlignment: CrossAxisAlignment.center,
+            children: [
+              Text('Disposition', style: TextStyle(color: label, fontSize: 12)),
+              const SizedBox(width: 12),
+              Expanded(
+                child: material.DropdownButton<SurfaceAtlasLayout>(
+                  isExpanded: true,
+                  value: _layout,
+                  items: SurfaceAtlasLayout.values
+                      .map(
+                        (e) => material.DropdownMenuItem(
+                          value: e,
+                          child: Text(
+                            _layoutMenuLabel(e),
+                            style: TextStyle(color: label, fontSize: 12),
+                            overflow: TextOverflow.ellipsis,
+                          ),
+                        ),
+                      )
+                      .toList(),
+                  onChanged: (v) {
+                    if (v != null) {
+                      setState(() => _layout = v);
+                    }
+                  },
+                ),
+              ),
+            ],
+          ),
+          const SizedBox(height: 6),
+          material.TextField(
+            key: const ValueKey('atlas_draft_category'),
+            controller: _categoryId,
+            onChanged: (_) => setState(() {}),
+            style: TextStyle(color: label, fontSize: 13),
+            decoration: const material.InputDecoration(
+              labelText: 'Catégorie (optionnel)',
+              isDense: true,
+            ),
+          ),
+          const SizedBox(height: 6),
+          material.TextField(
+            key: const ValueKey('atlas_draft_sort'),
+            controller: _sort,
+            onChanged: (_) => setState(() {}),
+            keyboardType: TextInputType.number,
+            style: TextStyle(color: label, fontSize: 13),
+            decoration: const material.InputDecoration(
+              labelText: 'Ordre d’affichage',
+              isDense: true,
+            ),
+          ),
+          const SizedBox(height: 10),
+          Row(
+            children: [
+              material.Switch(
+                value: _showPreview,
+                onChanged: (v) => setState(() => _showPreview = v),
+              ),
+              const SizedBox(width: 4),
+              Text(
+                'Prévisualisation locale',
+                style: TextStyle(color: label, fontSize: 12),
+              ),
+            ],
+          ),
+          const SizedBox(height: 8),
+          Text(
+            isValid ? 'Brouillon prêt localement' : 'Brouillon invalide',
+            style: TextStyle(
+              color: isValid ? accent : const Color(0xFFE8887A),
+              fontSize: 13,
+              fontWeight: FontWeight.w700,
+            ),
+          ),
+          const SizedBox(height: 2),
+          Text(
+            'Aucune sauvegarde ne sera effectuée',
+            style: TextStyle(color: subtle, fontSize: 11),
+          ),
+          if (errs.isNotEmpty) ...[
+            const SizedBox(height: 6),
+            for (final e in errs)
+              Text(
+                e,
+                style: const TextStyle(
+                  color: Color(0xFFE8887A),
+                  fontSize: 11,
+                ),
+              ),
+          ],
+          if (_showPreview && draft != null) ...[
+            const SizedBox(height: 10),
+            Text(
+              'Aperçu : ${draft.tileWidth}×${draft.tileHeight} · Grille ${draft.columns}×${draft.rows} · ${draft.tileCount} tuiles · ordre ${draft.sortOrder}',
+              style: TextStyle(color: label, fontSize: 12),
+            ),
+            Text(
+              'Disposition : ${_layoutMenuLabel(draft.layout)}',
+              style: TextStyle(color: subtle, fontSize: 11),
+            ),
+            Text(
+              'Catégorie : ${draft.categoryId ?? '—'}',
+              style: TextStyle(color: subtle, fontSize: 11),
+            ),
+          ],
+        ],
+      ),
+    ),
+  );
+  }
+}
+
+Widget _localBadge(
+  BuildContext context,
+  String text,
+  Color labelColor,
+  Color accent,
+) {
+  return Container(
+    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
+    decoration: BoxDecoration(
+      color: Color.lerp(
+        EditorChrome.islandFillElevated(context),
+        accent,
+        0.1,
+      ),
+      borderRadius: BorderRadius.circular(6),
+      border: Border.all(color: accent.withValues(alpha: 0.4)),
+    ),
+    child: Text(
+      text,
+      style: TextStyle(
+        color: labelColor,
+        fontSize: 10,
+        fontWeight: FontWeight.w600,
+      ),
+    ),
+  );
+}
+```
+
+#### `packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart`
+
+```dart
+// Surface Studio — shell UI lecture seule (Lot 52).
+//
+// Consomme un [SurfaceStudioReadModel] déjà construit côté [map_core] : pas de
+// re-diagnostic, pas de mutation manifest, pas d’I/O. Les actions futures sont
+// désactivées ; seul le placeholder « Actions auteur » reste pour un lot ultérieur.
+//
+// Style : aligné sur [EditorChrome] / îlots de l’éditeur (pas de Card Material
+// clair isolé) — cohérent avec World Explorer et le shell macOS.
+
+import 'package:flutter/cupertino.dart';
+import 'package:flutter/material.dart' show Icons;
+import 'package:macos_ui/macos_ui.dart';
+import 'package:map_core/map_core.dart';
+
+import '../../ui/shared/cupertino_editor_widgets.dart';
+import 'surface_studio_atlas_authoring_prep.dart';
+import 'surface_studio_catalog_browser.dart';
+import 'surface_studio_diagnostics_view.dart';
+import 'surface_studio_selection.dart';
+import 'surface_studio_selection_inspector.dart';
+import 'surface_studio_selection_summary.dart';
+
+/// Accent produit Surface Studio (même base que la tuile World Explorer).
+const Color _surfaceStudioAccent = Color(0xFF2DD4BF);
+
+/// Panneau présentationnel **lecture seule** pour Surface Studio.
+class SurfaceStudioPanel extends StatefulWidget {
+  const SurfaceStudioPanel({
+    super.key,
+    required this.readModel,
+  });
+
+  final SurfaceStudioReadModel readModel;
+
+  static const String titleText = 'Surface Studio';
+  static const String readOnlyBadgeText = 'Lecture seule';
+  static const String productDescriptionText =
+      'Préparez et contrôlez les surfaces animées du projet : eau, lave, glace, hautes herbes.';
+  static const String placeholderActionsTitle = 'Actions auteur';
+  static const String placeholderSoonText = 'Bientôt';
+  static const String actionCreateAtlasLabel = 'Créer un atlas';
+  static const String actionImportVerticalAtlasLabel =
+      'Importer un atlas vertical';
+
+  @override
+  State<SurfaceStudioPanel> createState() => _SurfaceStudioPanelState();
+}
+
+class _SurfaceStudioPanelState extends State<SurfaceStudioPanel> {
+  /// Sélection d’inspection : locale au widget, jamais écrite dans le manifest.
+  SurfaceStudioSelection _selection = const SurfaceStudioSelection.none();
+  late SurfaceStudioReadModel _readModel;
+
+  @override
+  void initState() {
+    super.initState();
+    _readModel = widget.readModel;
+  }
+
+  @override
+  void didUpdateWidget(covariant SurfaceStudioPanel oldWidget) {
+    super.didUpdateWidget(oldWidget);
+    if (widget.readModel != oldWidget.readModel) {
+      _readModel = widget.readModel;
+    }
+  }
+
+  @override
+  Widget build(BuildContext context) {
+    final s = _readModel.summary;
+    final label = EditorChrome.primaryLabel(context);
+    final subtle = EditorChrome.subtleLabel(context);
+
+    return SingleChildScrollView(
+      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
+      child: Column(
+        crossAxisAlignment: CrossAxisAlignment.stretch,
+        children: [
+          Row(
+            crossAxisAlignment: CrossAxisAlignment.center,
+            children: [
+              const _StudioHeaderIcon(accent: _surfaceStudioAccent),
+              const SizedBox(width: 12),
+              Expanded(
+                child: Text(
+                  SurfaceStudioPanel.titleText,
+                  style: TextStyle(
+                    color: label,
+                    fontSize: 22,
+                    fontWeight: FontWeight.w700,
+                    letterSpacing: -0.35,
+                  ),
+                ),
+              ),
+              const _ReadOnlyBadge(label: SurfaceStudioPanel.readOnlyBadgeText),
+            ],
+          ),
+          const SizedBox(height: 12),
+          Text(
+            SurfaceStudioPanel.productDescriptionText,
+            style: TextStyle(
+              color: subtle,
+              fontSize: 13,
+              fontWeight: FontWeight.w500,
+              height: 1.35,
+            ),
+          ),
+          const SizedBox(height: 8),
+          Text(
+            'Vous pouvez ajouter un atlas au catalogue de travail en mémoire. '
+            'Aucune sauvegarde projet sur disque, pas d’édition ni suppression d’atlas existant.',
+            style: TextStyle(
+              color: subtle.withValues(alpha: 0.92),
+              fontSize: 12,
+              fontWeight: FontWeight.w500,
+              height: 1.35,
+            ),
+          ),
+          const SizedBox(height: 20),
+          _CounterRow(
+            atlas: s.atlasCount,
+            animations: s.animationCount,
+            presets: s.presetCount,
+          ),
+          const SizedBox(height: 12),
+          SurfaceStudioSelectionSummary(selection: _selection),
+          const SizedBox(height: 12),
+          SurfaceStudioSelectionInspector(
+            readModel: _readModel,
+            selection: _selection,
+          ),
+          const SizedBox(height: 12),
+          SurfaceStudioCatalogBrowser(
+            readModel: _readModel,
+            selection: _selection,
+            onSelectionChanged: (v) {
+              setState(() => _selection = v);
+            },
+          ),
+          const SizedBox(height: 16),
+          SurfaceStudioDiagnosticsView(readModel: _readModel),
+          const SizedBox(height: 20),
+          SurfaceStudioAtlasAuthoringPrep(
+            readModel: _readModel,
+            selection: _selection,
+            onSurfaceCatalogChanged: (cat) {
+              final newId = cat.atlases.isNotEmpty
+                  ? cat.atlases.last.id
+                  : '';
+              setState(() {
+                _readModel = buildSurfaceStudioReadModelFromCatalog(cat);
+                if (newId.isNotEmpty) {
+                  _selection = SurfaceStudioSelection.atlas(newId);
+                }
+              });
+            },
+          ),
+          const SizedBox(height: 20),
+          const _FutureActions(
+            onCreateAtlas: null,
+            onImportVertical: null,
+          ),
+          const SizedBox(height: 20),
+          const _SectionPlaceholder(
+            title: SurfaceStudioPanel.placeholderActionsTitle,
+          ),
+        ],
+      ),
+    );
+  }
+}
+
+class _StudioHeaderIcon extends StatelessWidget {
+  const _StudioHeaderIcon({required this.accent});
+
+  final Color accent;
+
+  @override
+  Widget build(BuildContext context) {
+    const hi = Color(0xFFFFFFFF);
+    const lo = Color(0xFF120808);
+    final onAccent =
+        accent.computeLuminance() > 0.55 ? const Color(0xFF1A0A08) : hi;
+
+    return Container(
+      width: 42,
+      height: 42,
+      decoration: BoxDecoration(
+        gradient: LinearGradient(
+          begin: Alignment.topLeft,
+          end: Alignment.bottomRight,
+          colors: [
+            Color.lerp(hi, accent, 0.72)!,
+            Color.lerp(accent, lo, 0.38)!,
+          ],
+        ),
+        borderRadius: BorderRadius.circular(14),
+        border: Border.all(
+          color: accent.withValues(alpha: 0.88),
+          width: 1.2,
+        ),
+        boxShadow: EditorChrome.toolbarCapsuleShadows(context),
+      ),
+      alignment: Alignment.center,
+      child: MacosIcon(
+        Icons.auto_awesome_motion,
+        color: onAccent,
+        size: 22,
+      ),
+    );
+  }
+}
+
+class _ReadOnlyBadge extends StatelessWidget {
+  const _ReadOnlyBadge({required this.label});
+
+  final String label;
+
+  @override
+  Widget build(BuildContext context) {
+    const accent = _surfaceStudioAccent;
+    final fill = Color.lerp(
+      EditorChrome.islandFillElevated(context),
+      accent,
+      0.14,
+    )!;
+
+    return Container(
+      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
+      decoration: BoxDecoration(
+        color: fill,
+        borderRadius: BorderRadius.circular(8),
+        border: Border.all(color: accent.withValues(alpha: 0.65)),
+        boxShadow: EditorChrome.toolbarCapsuleShadows(context),
+      ),
+      child: Text(
+        label,
+        style: const TextStyle(
+          color: _surfaceStudioAccent,
+          fontSize: 11,
+          fontWeight: FontWeight.w800,
+          letterSpacing: 0.2,
+        ),
+      ),
+    );
+  }
+}
+
+class _CounterRow extends StatelessWidget {
+  const _CounterRow({
+    required this.atlas,
+    required this.animations,
+    required this.presets,
+  });
+
+  final int atlas;
+  final int animations;
+  final int presets;
+
+  @override
+  Widget build(BuildContext context) {
+    return Wrap(
+      key: const ValueKey('surface_studio_header_counters'),
+      spacing: 12,
+      runSpacing: 10,
+      children: [
+        _CounterChip(label: 'Atlas', value: atlas),
+        _CounterChip(label: 'Animations', value: animations),
+        _CounterChip(label: 'Presets', value: presets),
+      ],
+    );
+  }
+}
+
+class _CounterChip extends StatelessWidget {
+  const _CounterChip({required this.label, required this.value});
+
+  final String label;
+  final int value;
+
+  @override
+  Widget build(BuildContext context) {
+    final subtle = EditorChrome.subtleLabel(context);
+    final labelColor = EditorChrome.primaryLabel(context);
+
+    return _StudioCard(
+      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
+      child: Column(
+        crossAxisAlignment: CrossAxisAlignment.start,
+        mainAxisSize: MainAxisSize.min,
+        children: [
+          Text(
+            label,
+            style: TextStyle(
+              color: subtle,
+              fontSize: 11,
+              fontWeight: FontWeight.w700,
+              letterSpacing: 0.3,
+            ),
+          ),
+          const SizedBox(height: 6),
+          Text(
+            '$value',
+            style: TextStyle(
+              color: labelColor,
+              fontSize: 22,
+              fontWeight: FontWeight.w700,
+              letterSpacing: -0.4,
+            ),
+          ),
+        ],
+      ),
+    );
+  }
+}
+
+/// Carte interne : même relief que les tuiles inspecteur / sections.
+class _StudioCard extends StatelessWidget {
+  const _StudioCard({
+    required this.child,
+    this.padding = const EdgeInsets.all(16),
+  });
+
+  final Widget child;
+  final EdgeInsetsGeometry padding;
+
+  @override
+  Widget build(BuildContext context) {
+    return Container(
+      padding: padding,
+      decoration: BoxDecoration(
+        color: EditorChrome.elevatedPanelBackground(context),
+        borderRadius: BorderRadius.circular(14),
+        border: Border.all(
+          color: EditorChrome.editorIslandRim(context),
+          width: 1,
+        ),
+        boxShadow: EditorChrome.sectionCardShadows(context),
+      ),
+      child: child,
+    );
+  }
+}
+
+class _FutureActions extends StatelessWidget {
+  const _FutureActions({
+    required this.onCreateAtlas,
+    required this.onImportVertical,
+  });
+
+  final VoidCallback? onCreateAtlas;
+  final VoidCallback? onImportVertical;
+
+  @override
+  Widget build(BuildContext context) {
+    final subtle = EditorChrome.subtleLabel(context);
+
+    return Column(
+      crossAxisAlignment: CrossAxisAlignment.start,
+      children: [
+        Text(
+          'Actions (non disponibles dans ce lot)',
+          style: TextStyle(
+            color: subtle,
+            fontSize: 12,
+            fontWeight: FontWeight.w700,
+          ),
+        ),
+        const SizedBox(height: 10),
+        Row(
+          children: [
+            _GhostAction(
+              label: SurfaceStudioPanel.actionCreateAtlasLabel,
+              onPressed: onCreateAtlas,
+            ),
+            const SizedBox(width: 12),
+            _GhostAction(
+              label: SurfaceStudioPanel.actionImportVerticalAtlasLabel,
+              onPressed: onImportVertical,
+            ),
+          ],
+        ),
+      ],
+    );
+  }
+}
+
+class _GhostAction extends StatelessWidget {
+  const _GhostAction({
+    required this.label,
+    required this.onPressed,
+  });
+
+  final String label;
+  final VoidCallback? onPressed;
+
+  @override
+  Widget build(BuildContext context) {
+    final subtle = EditorChrome.subtleLabel(context);
+    final enabled = onPressed != null;
+
+    return Opacity(
+      opacity: enabled ? 1.0 : 0.48,
+      child: CupertinoButton(
+        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
+        minimumSize: Size.zero,
+        onPressed: onPressed,
+        child: Text(
+          label,
+          style: TextStyle(
+            color: enabled ? EditorChrome.inspectorJoyCyan : subtle,
+            fontSize: 13,
+            fontWeight: FontWeight.w600,
+            decoration: TextDecoration.none,
+          ),
+        ),
+      ),
+    );
+  }
+}
+
+class _SectionPlaceholder extends StatelessWidget {
+  const _SectionPlaceholder({required this.title});
+
+  final String title;
+
+  @override
+  Widget build(BuildContext context) {
+    final label = EditorChrome.primaryLabel(context);
+    final subtle = EditorChrome.subtleLabel(context);
+
+    return _StudioCard(
+      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
+      child: Row(
+        children: [
+          Expanded(
+            child: Column(
+              crossAxisAlignment: CrossAxisAlignment.start,
+              children: [
+                Text(
+                  title,
+                  style: TextStyle(
+                    color: label,
+                    fontSize: 14,
+                    fontWeight: FontWeight.w700,
+                  ),
+                ),
+                const SizedBox(height: 2),
+                Text(
+                  SurfaceStudioPanel.placeholderSoonText,
+                  style: TextStyle(
+                    color: subtle,
+                    fontSize: 12,
+                    fontWeight: FontWeight.w500,
+                  ),
+                ),
+              ],
+            ),
+          ),
+          MacosIcon(
+            CupertinoIcons.chevron_right,
+            size: 16,
+            color: subtle,
+          ),
+        ],
+      ),
+    );
+  }
+}
+
+/// Adaptateur : construit le read model **sans** I/O à partir d’un [ProjectManifest].
+class SurfaceStudioPanelFromManifest extends StatelessWidget {
+  const SurfaceStudioPanelFromManifest({
+    super.key,
+    required this.manifest,
+  });
+
+  final ProjectManifest manifest;
+
+  @override
+  Widget build(BuildContext context) {
+    return SurfaceStudioPanel(
+      readModel: buildSurfaceStudioReadModel(manifest),
+    );
+  }
+}
+```
+
+#### `packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart`
+
+```dart
+import 'package:flutter/cupertino.dart';
+import 'package:flutter/material.dart';
+import 'package:flutter_test/flutter_test.dart';
+import 'package:map_core/map_core.dart';
+import 'package:map_editor/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart';
+import 'package:map_editor/src/features/surface_studio/surface_studio_selection.dart';
+
+void main() {
+  group('SurfaceStudioAtlasAuthoringPrep (Lot 60)', () {
+    testWidgets('titre, brouillon local, défauts 32/1/1', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioAtlasAuthoringPrep(
+            readModel: _minimalRead(),
+            selection: const SurfaceStudioSelection.none(),
+          ),
+        ),
+      );
+      expect(find.text('Préparation atlas'), findsOneWidget);
+      expect(
+        find.text('Brouillon local non sauvegardé sur disque'),
+        findsOneWidget,
+      );
+      expect(find.text('Brouillon local'), findsOneWidget);
+      expect(find.text('Non sauvegardé'), findsOneWidget);
+      final w = find.byKey(const ValueKey('atlas_draft_tile_w'));
+      final h = find.byKey(const ValueKey('atlas_draft_tile_h'));
+      final c = find.byKey(const ValueKey('atlas_draft_cols'));
+      final r = find.byKey(const ValueKey('atlas_draft_rows'));
+      expect(
+        (tester.widget(w) as TextField).controller!.text,
+        '32',
+      );
+      expect(
+        (tester.widget(h) as TextField).controller!.text,
+        '32',
+      );
+      expect(
+        (tester.widget(c) as TextField).controller!.text,
+        '1',
+      );
+      expect(
+        (tester.widget(r) as TextField).controller!.text,
+        '1',
+      );
+    });
+
+    testWidgets('id / nom / tileset vides: erreurs', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioAtlasAuthoringPrep(
+            readModel: _emptyReadModel(),
+            selection: const SurfaceStudioSelection.none(),
+          ),
+        ),
+      );
+      expect(find.text('Identifiant requis'), findsOneWidget);
+      expect(find.text('Nom requis'), findsOneWidget);
+      expect(find.text('Identifiant tileset requis'), findsOneWidget);
+    });
+
+    testWidgets('taille tuile x non entier: erreur', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioAtlasAuthoringPrep(
+            readModel: _minimalRead(),
+            selection: const SurfaceStudioSelection.none(),
+          ),
+        ),
+      );
+      final w = find.byKey(const ValueKey('atlas_draft_tile_w'));
+      await tester.enterText(w, 'abc');
+      await tester.pump();
+      expect(find.text('Largeur de tuile : entier requis'), findsOneWidget);
+    });
+
+    testWidgets('hauteur / colonnes / lignes <= 0: erreur', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioAtlasAuthoringPrep(
+            readModel: _minimalRead(),
+            selection: const SurfaceStudioSelection.none(),
+          ),
+        ),
+      );
+      final idF = find.byKey(const ValueKey('atlas_draft_id'));
+      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
+      final tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
+      final hF = find.byKey(const ValueKey('atlas_draft_tile_h'));
+      final cF = find.byKey(const ValueKey('atlas_draft_cols'));
+      final rF = find.byKey(const ValueKey('atlas_draft_rows'));
+      final sF = find.byKey(const ValueKey('atlas_draft_sort'));
+      await tester.enterText(idF, 'n');
+      await tester.enterText(nameF, 'N');
+      await tester.enterText(tsF, 't');
+      await tester.enterText(hF, '0');
+      await tester.pump();
+      expect(
+        find.text('Hauteur de tuile : valeur positive requise'),
+        findsOneWidget,
+      );
+      await tester.enterText(hF, '32');
+      await tester.enterText(cF, '0');
+      await tester.pump();
+      expect(
+        find.text('Colonnes : valeur positive requise'),
+        findsOneWidget,
+      );
+      await tester.enterText(cF, '1');
+      await tester.enterText(rF, '0');
+      await tester.pump();
+      expect(find.text('Lignes : valeur positive requise'), findsOneWidget);
+      await tester.enterText(rF, '1');
+      await tester.enterText(sF, 'notint');
+      await tester.pump();
+      expect(find.text('Ordre : entier requis'), findsOneWidget);
+    });
+
+    testWidgets('sortOrder négatif: erreur', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioAtlasAuthoringPrep(
+            readModel: _minimalRead(),
+            selection: const SurfaceStudioSelection.none(),
+          ),
+        ),
+      );
+      final idF = find.byKey(const ValueKey('atlas_draft_id'));
+      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
+      final tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
+      final sF = find.byKey(const ValueKey('atlas_draft_sort'));
+      await tester.enterText(idF, 'n');
+      await tester.enterText(nameF, 'N');
+      await tester.enterText(tsF, 't');
+      await tester.enterText(sF, '-1');
+      await tester.pump();
+      expect(
+        find.text('Ordre : valeur négative interdite pour ce brouillon'),
+        findsOneWidget,
+      );
+    });
+
+    testWidgets('id dupliqué dans le catalogue: erreur', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioAtlasAuthoringPrep(
+            readModel: _minimalRead(),
+            selection: const SurfaceStudioSelection.none(),
+          ),
+        ),
+      );
+      final idF = find.byKey(const ValueKey('atlas_draft_id'));
+      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
+      final tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
+      await tester.enterText(idF, 'water-atlas');
+      await tester.enterText(nameF, 'X');
+      await tester.enterText(tsF, 't');
+      await tester.pump();
+      expect(
+        find.text('Un atlas existe déjà avec cet id.'),
+        findsOneWidget,
+      );
+    });
+
+    testWidgets('Charger la sélection: champs = atlas, catalogue inchangé',
+        (tester) async {
+      final rm = _minimalRead();
+      final beforeCat = rm.catalog;
+      final sel = SurfaceStudioSelection.atlas('water-atlas');
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioAtlasAuthoringPrep(
+            readModel: rm,
+            selection: sel,
+          ),
+        ),
+      );
+      await tester.tap(
+        find.text('Charger la sélection dans le brouillon'),
+      );
+      await tester.pump();
+      final idF = find.byKey(const ValueKey('atlas_draft_id'));
+      expect(
+        (tester.widget(idF) as TextField).controller!.text,
+        'water-atlas',
+      );
+      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
+      expect(
+        (tester.widget(nameF) as TextField).controller!.text,
+        'Water Atlas',
+      );
+      final tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
+      expect(
+        (tester.widget(tsF) as TextField).controller!.text,
+        'nature-tileset',
+      );
+      expect(identical(rm.catalog, beforeCat), isTrue);
+    });
+
+    testWidgets('sélection animation: brouillon stable + note', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioAtlasAuthoringPrep(
+            readModel: _minimalRead(),
+            selection: SurfaceStudioSelection.animation('water-isolated-loop'),
+          ),
+        ),
+      );
+      expect(
+        find.text('La sélection actuelle n’est pas un atlas.'),
+        findsOneWidget,
+      );
+      expect(
+        (tester.widget(find.byKey(const ValueKey('atlas_draft_id')))
+                as TextField)
+            .controller!
+            .text
+            .isEmpty,
+        isTrue,
+      );
+      expect(tester.takeException(), isNull);
+    });
+
+    testWidgets('sélection atlas manquant: note + stable', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioAtlasAuthoringPrep(
+            readModel: _minimalRead(),
+            selection: SurfaceStudioSelection.atlas('nope-missing'),
+          ),
+        ),
+      );
+      expect(
+        find.text(
+            'Atlas sélectionné introuvable, brouillon atlas indépendant.'),
+        findsOneWidget,
+      );
+      expect(tester.takeException(), isNull);
+    });
+
+    testWidgets('pas de libellés d’action dangereux', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioAtlasAuthoringPrep(
+            readModel: _minimalRead(),
+            selection: const SurfaceStudioSelection.none(),
+          ),
+        ),
+      );
+      for (final s in <String>[
+        'Sauvegarder',
+        'Enregistrer',
+        'Créer l’atlas',
+        'Modifier l’atlas',
+        'Supprimer',
+        'Delete',
+        'Save',
+        'Create',
+        'Update',
+      ]) {
+        expect(find.text(s), findsNothing);
+      }
+    });
+
+    testWidgets('sans ProviderScope', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioAtlasAuthoringPrep(
+            readModel: _minimalRead(),
+            selection: const SurfaceStudioSelection.none(),
+          ),
+        ),
+      );
+      expect(find.byKey(kSurfaceStudioAtlasAuthoringPrepKey), findsOneWidget);
+    });
+
+    testWidgets('brouillon valide + prévisu: texte aperçu', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioAtlasAuthoringPrep(
+            readModel: _emptyReadModel(),
+            selection: const SurfaceStudioSelection.none(),
+          ),
+        ),
+      );
+      final idF = find.byKey(const ValueKey('atlas_draft_id'));
+      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
+      final tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
+      await tester.enterText(idF, 'new-a');
+      await tester.enterText(nameF, 'New');
+      await tester.enterText(tsF, 'ts');
+      await tester.pump();
+      final swFinder = find.byType(Switch);
+      await tester.ensureVisible(swFinder);
+      await tester.tap(swFinder);
+      await tester.pump();
+      expect(find.textContaining('Aperçu : 32×32'), findsOneWidget);
+    });
+  });
+
+  group('SurfaceStudioAtlasAuthoringPrep (Lot 61)', () {
+    testWidgets('création brouillon valide émet le catalogue + atlas', (tester) async {
+      final out = <ProjectSurfaceCatalog>[];
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioAtlasAuthoringPrep(
+            readModel: _emptyReadModel(),
+            selection: const SurfaceStudioSelection.none(),
+            onSurfaceCatalogChanged: out.add,
+          ),
+        ),
+      );
+      final idF = find.byKey(const ValueKey('atlas_draft_id'));
+      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
+      final tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
+      await tester.enterText(idF, 'a-new');
+      await tester.enterText(nameF, 'My');
+      await tester.enterText(tsF, 'tset');
+      await tester.pump();
+      await tester.tap(
+        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
+      );
+      await tester.pump();
+      expect(out, hasLength(1));
+      final c = out.single;
+      expect(c.atlases, hasLength(1));
+      expect(c.animations, isEmpty);
+      expect(c.presets, isEmpty);
+      final a = c.atlases.single;
+      expect(a.id, 'a-new');
+      expect(a.name, 'My');
+      expect(a.tilesetId, 'tset');
+      expect(a.sortOrder, 0);
+      expect(a.categoryId, isNull);
+      expect(a.geometry.tileSize.width, 32);
+      expect(a.geometry.tileSize.height, 32);
+      expect(a.geometry.gridSize.columns, 1);
+      expect(a.geometry.gridSize.rows, 1);
+      expect(a.geometry.layout, SurfaceAtlasLayout.grid);
+      expect(
+        find.text(
+          'Atlas créé dans le catalogue de travail. Sauvegarde projet non effectuée.',
+        ),
+        findsOneWidget,
+      );
+    });
+
+    testWidgets('création refusée si brouillon invalide (pas de callback)',
+        (tester) async {
+      final out = <ProjectSurfaceCatalog>[];
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioAtlasAuthoringPrep(
+            readModel: _emptyReadModel(),
+            selection: const SurfaceStudioSelection.none(),
+            onSurfaceCatalogChanged: out.add,
+          ),
+        ),
+      );
+      final create = find.descendant(
+        of: find.byKey(kSurfaceStudioAtlasAuthoringPrepKey),
+        matching: find.byKey(
+          const ValueKey('surface_studio_create_atlas_work_catalog'),
+        ),
+      );
+      final btn = tester.widget<CupertinoButton>(create);
+      expect(btn.onPressed, isNull);
+      expect(out, isEmpty);
+    });
+
+    testWidgets('id vide: pas d’appel callback en tap (bouton inactif)',
+        (tester) async {
+      final out = <ProjectSurfaceCatalog>[];
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioAtlasAuthoringPrep(
+            readModel: _emptyReadModel(),
+            selection: const SurfaceStudioSelection.none(),
+            onSurfaceCatalogChanged: out.add,
+          ),
+        ),
+      );
+      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
+      final tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
+      await tester.enterText(nameF, 'N');
+      await tester.enterText(tsF, 't');
+      await tester.pump();
+      final create = find.descendant(
+        of: find.byKey(kSurfaceStudioAtlasAuthoringPrepKey),
+        matching: find.byKey(
+          const ValueKey('surface_studio_create_atlas_work_catalog'),
+        ),
+      );
+      expect(tester.widget<CupertinoButton>(create).onPressed, isNull);
+    });
+
+    testWidgets('dupliquer id: création inactivable', (tester) async {
+      final out = <ProjectSurfaceCatalog>[];
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioAtlasAuthoringPrep(
+            readModel: _minimalRead(),
+            selection: const SurfaceStudioSelection.none(),
+            onSurfaceCatalogChanged: out.add,
+          ),
+        ),
+      );
+      final idF = find.byKey(const ValueKey('atlas_draft_id'));
+      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
+      final tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
+      await tester.enterText(idF, 'water-atlas');
+      await tester.enterText(nameF, 'X');
+      await tester.enterText(tsF, 't');
+      await tester.pump();
+      final create = find.descendant(
+        of: find.byKey(kSurfaceStudioAtlasAuthoringPrepKey),
+        matching: find.byKey(
+          const ValueKey('surface_studio_create_atlas_work_catalog'),
+        ),
+      );
+      expect(tester.widget<CupertinoButton>(create).onPressed, isNull);
+      expect(out, isEmpty);
+    });
+
+    testWidgets('chargé depuis sélection: même id = doublon; nouvel id = ajout',
+        (tester) async {
+      final out = <ProjectSurfaceCatalog>[];
+      var rm = _minimalRead();
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioAtlasAuthoringPrep(
+            readModel: rm,
+            selection: SurfaceStudioSelection.atlas('water-atlas'),
+            onSurfaceCatalogChanged: out.add,
+          ),
+        ),
+      );
+      await tester.tap(
+        find.text('Charger la sélection dans le brouillon'),
+      );
+      await tester.pump();
+      var create = find.descendant(
+        of: find.byKey(kSurfaceStudioAtlasAuthoringPrepKey),
+        matching: find.byKey(
+          const ValueKey('surface_studio_create_atlas_work_catalog'),
+        ),
+      );
+      expect(tester.widget<CupertinoButton>(create).onPressed, isNull);
+      final idF = find.byKey(const ValueKey('atlas_draft_id'));
+      await tester.enterText(idF, 'water-bis');
+      await tester.pump();
+      expect(tester.widget<CupertinoButton>(create).onPressed, isNotNull);
+      final beforeAtlas = rm.catalog.atlases.single;
+      await tester.tap(create);
+      await tester.pump();
+      expect(out, hasLength(1));
+      expect(out.single.atlases, hasLength(2));
+      expect(
+        out.single.atlases.map((a) => a.id).toList(),
+        ['water-atlas', 'water-bis'],
+      );
+      expect(
+        out.single.atlases.first,
+        beforeAtlas,
+      );
+    });
+
+    testWidgets('interdits save projet (libellés)', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioAtlasAuthoringPrep(
+            readModel: _minimalRead(),
+            selection: const SurfaceStudioSelection.none(),
+            onSurfaceCatalogChanged: (_) {},
+          ),
+        ),
+      );
+      for (final s in <String>[
+        'Sauvegarder le projet',
+        'Enregistrer le projet',
+        'Écrire sur disque',
+        'Save project',
+        'Write to disk',
+      ]) {
+        expect(find.text(s), findsNothing);
+      }
+    });
+  });
+}
+
+Widget _wrap(Widget child) {
+  return MaterialApp(
+    home: Scaffold(
+      body: SingleChildScrollView(
+        padding: const EdgeInsets.all(16),
+        child: child,
+      ),
+    ),
+  );
+}
+
+SurfaceStudioReadModel _minimalRead() {
+  return buildSurfaceStudioReadModelFromCatalog(_cat());
+}
+
+SurfaceStudioReadModel _emptyReadModel() {
+  return buildSurfaceStudioReadModelFromCatalog(ProjectSurfaceCatalog());
+}
+
+ProjectSurfaceCatalog _cat() {
+  final g = SurfaceAtlasGeometry(
+    tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
+    gridSize: SurfaceAtlasGridSize(columns: 2, rows: 2),
+    layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
+  );
+  final atlas = ProjectSurfaceAtlas(
+    id: 'water-atlas',
+    name: 'Water Atlas',
+    tilesetId: 'nature-tileset',
+    geometry: g,
+  );
+  final frame = SurfaceAnimationFrame(
+    tileRef: SurfaceAtlasTileRef(atlasId: 'water-atlas', column: 0, row: 0),
+    durationMs: 120,
+  );
+  final anim = ProjectSurfaceAnimation(
+    id: 'water-isolated-loop',
+    name: 'Water Isolated Loop',
+    timeline: SurfaceAnimationTimeline(frames: [frame]),
+  );
+  final refs = SurfaceVariantAnimationRefSet(
+    refs: [
+      SurfaceVariantAnimationRef(
+        role: SurfaceVariantRole.isolated,
+        animationId: 'water-isolated-loop',
+      ),
+    ],
+  );
+  final preset = ProjectSurfacePreset(
+    id: 'water-surface',
+    name: 'Water Surface',
+    variantAnimations: refs,
+  );
+  return ProjectSurfaceCatalog(
+    atlases: [atlas],
+    animations: [anim],
+    presets: [preset],
+  );
+}
+```
+
+#### `packages/map_editor/test/surface_studio/surface_studio_panel_test.dart`
+
+```dart
+// Tests widget — Surface Studio panel (Lot 52).
+// Imports `map_core` en API publique uniquement (pas de `map_core/src/...`).
+
+import 'package:flutter/cupertino.dart';
+import 'package:flutter/material.dart';
+import 'package:flutter_test/flutter_test.dart';
+import 'package:macos_ui/macos_ui.dart';
+import 'package:map_core/map_core.dart';
+import 'package:map_editor/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart';
+import 'package:map_editor/src/features/surface_studio/surface_studio_panel.dart';
+import 'package:map_editor/src/features/surface_studio/surface_studio_selection_inspector.dart';
+
+void main() {
+  group('SurfaceStudioPanel (Lot 52)', () {
+    testWidgets('1. title Surface Studio is visible', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
+      );
+      expect(find.text('Surface Studio'), findsOneWidget);
+    });
+
+    testWidgets('2. read-only badge is visible', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
+      );
+      // Bandeau panneau + inspecteur (Lot 59).
+      expect(find.text('Lecture seule'), findsNWidgets(2));
+    });
+
+    testWidgets('3. three counters are zero for empty catalog', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
+      );
+      final counters =
+          find.byKey(const ValueKey('surface_studio_header_counters'));
+      expect(
+        find.descendant(of: counters, matching: find.text('0')),
+        findsNWidgets(3),
+      );
+    });
+
+    testWidgets('4. empty catalog shows empty state copy', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
+      );
+      expect(
+        find.text('Le catalogue Surface est vide'),
+        findsOneWidget,
+      );
+    });
+
+    testWidgets('5. minimal catalog shows 1/1/1', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
+      );
+      final counters =
+          find.byKey(const ValueKey('surface_studio_header_counters'));
+      expect(
+        find.descendant(of: counters, matching: find.text('1')),
+        findsNWidgets(3),
+      );
+    });
+
+    testWidgets('6. non-empty shows catalog browser content', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
+      );
+      expect(find.text('Catalogue Surface'), findsOneWidget);
+      expect(find.text('Water Atlas'), findsOneWidget);
+    });
+
+    testWidgets('7. clean diagnostics for minimal coherent catalog',
+        (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
+      );
+      expect(find.text('Aucun diagnostic Surface'), findsOneWidget);
+    });
+
+    testWidgets('8. warning state when unused atlas', (tester) async {
+      final rm = _warningReadModel();
+      expect(rm.hasWarnings, isTrue);
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: rm)),
+      );
+      expect(find.text('Diagnostics Surface'), findsOneWidget);
+      // Atlas orphelin + animation non référencée par un preset (presets vides)
+      expect(find.textContaining('Avertissements : 2'), findsOneWidget);
+      expect(find.text('Atlas inutilisé'), findsOneWidget);
+      expect(find.text('Animation inutilisée'), findsOneWidget);
+    });
+
+    testWidgets('9. error state when preset animation missing', (tester) async {
+      final rm = _errorReadModel();
+      expect(rm.hasErrors, isTrue);
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: rm)),
+      );
+      expect(find.text('Diagnostics Surface'), findsOneWidget);
+      expect(find.textContaining('Erreurs : 1'), findsOneWidget);
+      expect(
+        find.text('Animation manquante dans un preset'),
+        findsOneWidget,
+      );
+    });
+
+    testWidgets('10. future action labels are visible', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
+      );
+      expect(find.text('Créer un atlas'), findsOneWidget);
+      expect(find.text('Importer un atlas vertical'), findsOneWidget);
+    });
+
+    testWidgets('11. future actions are disabled (onPressed null)',
+        (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
+      );
+      final b1 = tester.widget<CupertinoButton>(
+        find.ancestor(
+          of: find.text('Créer un atlas'),
+          matching: find.byType(CupertinoButton),
+        ),
+      );
+      final b2 = tester.widget<CupertinoButton>(
+        find.ancestor(
+          of: find.text('Importer un atlas vertical'),
+          matching: find.byType(CupertinoButton),
+        ),
+      );
+      expect(b1.onPressed, isNull);
+      expect(b2.onPressed, isNull);
+    });
+
+    testWidgets('12. section placeholder titles are visible', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
+      );
+      expect(find.text('Diagnostics Surface'), findsOneWidget);
+      expect(find.text('Actions auteur'), findsOneWidget);
+    });
+
+    testWidgets('13. SurfaceStudioPanelFromManifest uses manifest catalog',
+        (tester) async {
+      final cat = _minimalWaterCatalog();
+      final manifest = _manifest(cat);
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanelFromManifest(manifest: manifest)),
+      );
+      final counters =
+          find.byKey(const ValueKey('surface_studio_header_counters'));
+      expect(
+        find.descendant(of: counters, matching: find.text('1')),
+        findsNWidgets(3),
+      );
+    });
+
+    testWidgets('14. manifest is not mutated after pump', (tester) async {
+      final cat = _minimalWaterCatalog();
+      final before = cat.atlases.length;
+      final manifest = _manifest(cat);
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanelFromManifest(manifest: manifest)),
+      );
+      expect(manifest.surfaceCatalog.atlases.length, before);
+    });
+
+    testWidgets(
+      '15. does not require provider setup — panel builds without ProviderScope',
+      (tester) async {
+        await tester.pumpWidget(
+          MaterialApp(
+            home: Scaffold(
+              body: SurfaceStudioPanel(readModel: _emptyReadModel()),
+            ),
+          ),
+        );
+        expect(find.text('Surface Studio'), findsOneWidget);
+      },
+    );
+
+    testWidgets('16. content is in a scrollable', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
+      );
+      expect(find.byType(SingleChildScrollView), findsOneWidget);
+    });
+
+    testWidgets('17. no internal domain type names in user-visible strings',
+        (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
+      );
+      expect(find.textContaining('ProjectSurfaceCatalog'), findsNothing);
+      expect(find.textContaining('SurfaceStudioReadModel'), findsNothing);
+      expect(
+          find.textContaining('SurfaceVariantAnimationRefSet'), findsNothing);
+    });
+
+    testWidgets('18. error read model does not throw on build', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _errorReadModel())),
+      );
+      expect(tester.takeException(), isNull);
+    });
+
+    testWidgets('19. warning read model does not throw on build',
+        (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _warningReadModel())),
+      );
+      expect(tester.takeException(), isNull);
+    });
+
+    testWidgets('20. displayed counts match read model summary',
+        (tester) async {
+      final rm = _minimalWaterReadModel();
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: rm)),
+      );
+      expect(rm.summary.atlasCount, 1);
+      expect(rm.summary.animationCount, 1);
+      expect(rm.summary.presetCount, 1);
+    });
+
+    testWidgets('22. TextField seulement zone brouillon (Lot 60), pas dans inspecteur',
+        (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
+      );
+      expect(
+        find.descendant(
+          of: find.byKey(kSurfaceStudioSelectionInspectorKey),
+          matching: find.byType(TextField),
+        ),
+        findsNothing,
+      );
+      expect(
+        find.descendant(
+          of: find.byKey(kSurfaceStudioAtlasAuthoringPrepKey),
+          matching: find.byType(TextField),
+        ),
+        findsWidgets,
+      );
+    });
+
+    testWidgets('23. no save affordances', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
+      );
+      expect(find.textContaining('Sauvegarder'), findsNothing);
+      expect(find.textContaining('Enregistrer'), findsNothing);
+      expect(find.textContaining('Save'), findsNothing);
+    });
+
+    testWidgets('22. panel shows catalog browser for minimal catalog', (
+      tester,
+    ) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
+      );
+      expect(find.text('Catalogue Surface'), findsOneWidget);
+      expect(find.text('Atlas Surface'), findsOneWidget);
+      expect(find.text('Animations Surface'), findsOneWidget);
+      expect(find.text('Presets Surface'), findsOneWidget);
+      expect(find.text('Water Atlas'), findsOneWidget);
+      expect(find.text('Water Isolated Loop'), findsOneWidget);
+      expect(find.text('Water Surface'), findsOneWidget);
+    });
+
+    testWidgets('24. test file uses public map_core only (smoke)',
+        (tester) async {
+      // Vérification statique : seul `package:map_core/map_core.dart` est importé.
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
+      );
+      expect(find.text('Surface Studio'), findsOneWidget);
+    });
+
+    testWidgets('25. Lot 55 — clean diagnostics view in panel', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
+      );
+      expect(find.text('Diagnostics Surface'), findsOneWidget);
+      expect(find.text('Aucun diagnostic Surface'), findsOneWidget);
+    });
+
+    testWidgets('26. Lot 55 — error diagnostics visible in panel',
+        (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _errorReadModel())),
+      );
+      expect(find.text('Diagnostics Surface'), findsOneWidget);
+      expect(find.text('Erreurs'), findsOneWidget);
+    });
+
+    testWidgets('27. Lot 55 — browser and diagnostics cohabit (minimal cat)',
+        (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
+      );
+      expect(find.text('Catalogue Surface'), findsOneWidget);
+      expect(find.text('Atlas Surface'), findsOneWidget);
+      expect(find.text('Animations Surface'), findsOneWidget);
+      expect(find.text('Presets Surface'), findsOneWidget);
+      expect(find.text('Diagnostics Surface'), findsOneWidget);
+      expect(find.text('Water Atlas'), findsOneWidget);
+    });
+
+    testWidgets(
+        '48. Lot 57 — panel shows Atlas / Animations / Presets / Diagnostics',
+        (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
+      );
+      expect(find.text('Atlas Surface'), findsOneWidget);
+      expect(find.text('Animations Surface'), findsOneWidget);
+      expect(find.text('Presets Surface'), findsOneWidget);
+      expect(find.text('Diagnostics Surface'), findsOneWidget);
+    });
+
+    testWidgets('58.21 — Aucune sélection au départ (catalogue minimal)',
+        (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
+      );
+      expect(find.text('Aucune sélection'), findsOneWidget);
+    });
+
+    testWidgets('58.22 — sélection atlas après tap', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
+      );
+      await tester.ensureVisible(find.text('Water Atlas'));
+      await tester.tap(find.text('Water Atlas'));
+      await tester.pump();
+      expect(find.text('Atlas sélectionné'), findsWidgets);
+      expect(find.text('water-atlas'), findsWidgets);
+    });
+
+    testWidgets('58.23 — sélection animation après tap', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
+      );
+      await tester.ensureVisible(find.text('Water Isolated Loop'));
+      await tester.tap(find.text('Water Isolated Loop'));
+      await tester.pump();
+      expect(find.text('Animation sélectionnée'), findsWidgets);
+      expect(find.text('water-isolated-loop'), findsWidgets);
+    });
+
+    testWidgets('58.24 — sélection preset après tap', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
+      );
+      await tester.ensureVisible(find.text('Water Surface'));
+      await tester.tap(find.text('Water Surface'));
+      await tester.pump();
+      expect(find.text('Preset sélectionné'), findsWidgets);
+      expect(find.text('water-surface'), findsWidgets);
+    });
+
+    testWidgets('58.25 — changement de sélection remplace la précédente',
+        (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
+      );
+      await tester.ensureVisible(find.text('Water Atlas'));
+      await tester.tap(find.text('Water Atlas'));
+      await tester.pump();
+      await tester.ensureVisible(find.text('Water Isolated Loop'));
+      await tester.tap(find.text('Water Isolated Loop'));
+      await tester.pump();
+      expect(find.text('Animation sélectionnée'), findsWidgets);
+      final t = tester
+          .widgetList<Text>(find.byType(Text))
+          .map((e) => e.data ?? '')
+          .join('\n');
+      expect(t.contains('Atlas sélectionné'), isFalse);
+    });
+
+    testWidgets('58.26 — sélection ne mute pas surfaceCatalog', (tester) async {
+      final cat = _minimalWaterCatalog();
+      final manifest = _manifest(cat);
+      final before = manifest.surfaceCatalog;
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanelFromManifest(manifest: manifest)),
+      );
+      await tester.ensureVisible(find.text('Water Atlas'));
+      await tester.tap(find.text('Water Atlas'));
+      await tester.pump();
+      await tester.ensureVisible(find.text('Water Surface'));
+      await tester.tap(find.text('Water Surface'));
+      await tester.pump();
+      expect(identical(manifest.surfaceCatalog, before), isTrue);
+    });
+
+    testWidgets('58.27 — pas de TextField dans inspecteur après sélections', (
+        tester,
+    ) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
+      );
+      await tester.ensureVisible(find.text('Water Atlas'));
+      await tester.tap(find.text('Water Atlas'));
+      await tester.pump();
+      expect(
+        find.descendant(
+          of: find.byKey(kSurfaceStudioSelectionInspectorKey),
+          matching: find.byType(TextField),
+        ),
+        findsNothing,
+      );
+    });
+
+    testWidgets('58.28 — pas de libellés édition/save actifs', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
+      );
+      await tester.ensureVisible(find.text('Water Atlas'));
+      await tester.tap(find.text('Water Atlas'));
+      await tester.pump();
+      for (final s in <String>[
+        'Sauvegarder',
+        'Enregistrer',
+        'Modifier',
+        'Supprimer',
+        'Save',
+        'Edit',
+        'Delete',
+      ]) {
+        expect(find.text(s), findsNothing);
+      }
+    });
+
+    testWidgets('59.20 — inspecteur none au départ', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
+      );
+      expect(find.text('Inspecteur Surface'), findsOneWidget);
+      expect(find.text('Aucune sélection à inspecter'), findsOneWidget);
+    });
+
+    testWidgets('59.21 — inspecteur atlas après tap', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
+      );
+      await tester.ensureVisible(find.text('Water Atlas'));
+      await tester.tap(find.text('Water Atlas'));
+      await tester.pump();
+      final insp = find.byKey(kSurfaceStudioSelectionInspectorKey);
+      expect(
+          find.descendant(of: insp, matching: find.text('Inspecteur Surface')),
+          findsOneWidget);
+      expect(
+        find.descendant(of: insp, matching: find.text('Atlas sélectionné')),
+        findsWidgets,
+      );
+      expect(
+        find.descendant(
+          of: insp,
+          matching: find.textContaining('Identifiant : water-atlas'),
+        ),
+        findsOneWidget,
+      );
+    });
+
+    testWidgets('59.22 — inspecteur animation après tap', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
+      );
+      await tester.ensureVisible(find.text('Water Isolated Loop'));
+      await tester.tap(find.text('Water Isolated Loop'));
+      await tester.pump();
+      final insp = find.byKey(kSurfaceStudioSelectionInspectorKey);
+      expect(
+        find.descendant(
+          of: insp,
+          matching: find.textContaining('Identifiant : water-isolated-loop'),
+        ),
+        findsOneWidget,
+      );
+    });
+
+    testWidgets('59.23 — inspecteur preset après tap', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
+      );
+      await tester.ensureVisible(find.text('Water Surface'));
+      await tester.tap(find.text('Water Surface'));
+      await tester.pump();
+      final insp = find.byKey(kSurfaceStudioSelectionInspectorKey);
+      expect(
+        find.descendant(
+          of: insp,
+          matching: find.textContaining('Identifiant : water-surface'),
+        ),
+        findsOneWidget,
+      );
+    });
+
+    testWidgets('59.24 — changement de sélection met l’inspecteur à jour',
+        (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
+      );
+      await tester.ensureVisible(find.text('Water Atlas'));
+      await tester.tap(find.text('Water Atlas'));
+      await tester.pump();
+      await tester.ensureVisible(find.text('Water Isolated Loop'));
+      await tester.tap(find.text('Water Isolated Loop'));
+      await tester.pump();
+      final insp = find.byKey(kSurfaceStudioSelectionInspectorKey);
+      expect(
+        find.descendant(
+          of: insp,
+          matching: find.textContaining('Identifiant : water-isolated-loop'),
+        ),
+        findsOneWidget,
+      );
+      expect(
+        find.descendant(
+          of: insp,
+          matching: find.text('Atlas sélectionné'),
+        ),
+        findsNothing,
+      );
+    });
+
+    testWidgets('59.25 — inspecteur ne mute pas le manifest', (tester) async {
+      final cat = _minimalWaterCatalog();
+      final manifest = _manifest(cat);
+      final before = manifest.surfaceCatalog;
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanelFromManifest(manifest: manifest)),
+      );
+      await tester.ensureVisible(find.text('Water Atlas'));
+      await tester.tap(find.text('Water Atlas'));
+      await tester.pump();
+      await tester.ensureVisible(find.text('Water Surface'));
+      await tester.tap(find.text('Water Surface'));
+      await tester.pump();
+      expect(identical(manifest.surfaceCatalog, before), isTrue);
+    });
+
+    testWidgets(
+        '59.26 — inspecteur read-only : aucun TextField (Lot 60 brouillon ok)',
+        (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
+      );
+      await tester.ensureVisible(find.text('Water Atlas'));
+      await tester.tap(find.text('Water Atlas'));
+      await tester.pump();
+      expect(
+        find.descendant(
+          of: find.byKey(kSurfaceStudioSelectionInspectorKey),
+          matching: find.byType(TextField),
+        ),
+        findsNothing,
+      );
+    });
+
+    testWidgets('59.27 — pas de libellés édition/save (Lot 59)',
+        (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
+      );
+      await tester.ensureVisible(find.text('Water Surface'));
+      await tester.tap(find.text('Water Surface'));
+      await tester.pump();
+      for (final s in <String>[
+        'Sauvegarder',
+        'Enregistrer',
+        'Modifier',
+        'Supprimer',
+        'Save',
+        'Edit',
+        'Delete',
+      ]) {
+        expect(find.text(s), findsNothing);
+      }
+    });
+
+    testWidgets('30. Lot 55 — surfaceCatalog unchanged after panel pump',
+        (tester) async {
+      final cat = _minimalWaterCatalog();
+      final manifest = _manifest(cat);
+      final before = manifest.surfaceCatalog;
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanelFromManifest(manifest: manifest)),
+      );
+      expect(identical(manifest.surfaceCatalog, before), isTrue);
+    });
+
+    testWidgets('60.1 — Préparation atlas (brouillon) visible', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
+      );
+      await tester.ensureVisible(find.text('Préparation atlas'));
+      expect(find.text('Préparation atlas'), findsOneWidget);
+      expect(
+        find.text('Brouillon local non sauvegardé sur disque'),
+        findsOneWidget,
+      );
+    });
+
+    testWidgets('61.1 — action création atlas dans le catalogue de travail',
+        (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
+      );
+      await tester.ensureVisible(
+        find.text('Créer l’atlas dans le catalogue de travail'),
+      );
+      expect(
+        find.text('Créer l’atlas dans le catalogue de travail'),
+        findsOneWidget,
+      );
+    });
+
+    testWidgets(
+        '61.2 — créer atlas (catalogue vide) : compteur atlas 1, browser, '
+        'inspecteur',
+        (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
+      );
+      final idF = find.byKey(const ValueKey('atlas_draft_id'));
+      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
+      final tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
+      await tester.ensureVisible(idF);
+      await tester.enterText(idF, 'lot61-a');
+      await tester.enterText(nameF, 'Lot61 A');
+      await tester.enterText(tsF, 'tileset-x');
+      await tester.pump();
+      await tester.ensureVisible(
+        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
+      );
+      await tester.tap(
+        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
+      );
+      await tester.pump();
+      final counters =
+          find.byKey(const ValueKey('surface_studio_header_counters'));
+      expect(
+        find.descendant(of: counters, matching: find.text('1')),
+        findsOneWidget,
+      );
+      expect(
+        find.descendant(of: counters, matching: find.text('0')),
+        findsNWidgets(2),
+      );
+      expect(find.text('Lot61 A'), findsWidgets);
+      expect(find.text('Diagnostics Surface'), findsOneWidget);
+    });
+
+    testWidgets(
+        '61.3 — créer second atlas : compteur 2, animations/presets inchangés',
+        (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
+      );
+      final idF = find.byKey(const ValueKey('atlas_draft_id'));
+      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
+      final tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
+      await tester.ensureVisible(idF);
+      await tester.enterText(idF, 'grass-a');
+      await tester.enterText(nameF, 'Grass');
+      await tester.enterText(tsF, 'ts-g');
+      await tester.pump();
+      await tester.ensureVisible(
+        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
+      );
+      await tester.tap(
+        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
+      );
+      await tester.pump();
+      final counters =
+          find.byKey(const ValueKey('surface_studio_header_counters'));
+      expect(
+        find.descendant(of: counters, matching: find.text('2')),
+        findsOneWidget,
+      );
+      expect(
+        find.descendant(of: counters, matching: find.text('1')),
+        findsNWidgets(2),
+      );
+      expect(find.text('Water Atlas'), findsOneWidget);
+      expect(find.text('Water Isolated Loop'), findsOneWidget);
+      expect(find.text('Water Surface'), findsOneWidget);
+      expect(find.text('grass-a'), findsWidgets);
+    });
+  });
+}
+
+Widget _wrap(Widget child) {
+  // MacosApp + thème sombre : même [EditorChrome] que l’éditeur réel.
+  return MacosApp(
+    theme: MacosThemeData.dark(),
+    home: ColoredBox(
+      color: const Color(0xFF0F1218),
+      child: child,
+    ),
+  );
+}
+
+SurfaceStudioReadModel _emptyReadModel() {
+  return buildSurfaceStudioReadModelFromCatalog(ProjectSurfaceCatalog());
+}
+
+SurfaceStudioReadModel _minimalWaterReadModel() {
+  return buildSurfaceStudioReadModelFromCatalog(_minimalWaterCatalog());
+}
+
+SurfaceStudioReadModel _warningReadModel() {
+  return buildSurfaceStudioReadModelFromCatalog(_catalogWithUnusedAtlas());
+}
+
+SurfaceStudioReadModel _errorReadModel() {
+  return buildSurfaceStudioReadModelFromCatalog(_catalogWithMissingAnimation());
+}
+
+SurfaceAtlasGeometry _geom() {
+  return SurfaceAtlasGeometry(
+    tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
+    gridSize: SurfaceAtlasGridSize(columns: 2, rows: 2),
+    layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
+  );
+}
+
+ProjectSurfaceCatalog _minimalWaterCatalog() {
+  final g = _geom();
+  final atlas = ProjectSurfaceAtlas(
+    id: 'water-atlas',
+    name: 'Water Atlas',
+    tilesetId: 'nature-tileset',
+    geometry: g,
+  );
+  final frame = SurfaceAnimationFrame(
+    tileRef: SurfaceAtlasTileRef(atlasId: 'water-atlas', column: 0, row: 0),
+    durationMs: 120,
+  );
+  final anim = ProjectSurfaceAnimation(
+    id: 'water-isolated-loop',
+    name: 'Water Isolated Loop',
+    timeline: SurfaceAnimationTimeline(frames: [frame]),
+  );
+  final refs = SurfaceVariantAnimationRefSet(
+    refs: [
+      SurfaceVariantAnimationRef(
+        role: SurfaceVariantRole.isolated,
+        animationId: 'water-isolated-loop',
+      ),
+    ],
+  );
+  final preset = ProjectSurfacePreset(
+    id: 'water-surface',
+    name: 'Water Surface',
+    variantAnimations: refs,
+  );
+  return ProjectSurfaceCatalog(
+    atlases: [atlas],
+    animations: [anim],
+    presets: [preset],
+  );
+}
+
+ProjectSurfaceCatalog _catalogWithUnusedAtlas() {
+  final g = _geom();
+  final used = ProjectSurfaceAtlas(
+    id: 'used-atlas',
+    name: 'U',
+    tilesetId: 't',
+    geometry: g,
+  );
+  final unused = ProjectSurfaceAtlas(
+    id: 'orphan-atlas',
+    name: 'O',
+    tilesetId: 't',
+    geometry: g,
+  );
+  final f = SurfaceAnimationFrame(
+    tileRef: SurfaceAtlasTileRef(atlasId: 'used-atlas', column: 0, row: 0),
+    durationMs: 10,
+  );
+  final anim = ProjectSurfaceAnimation(
+    id: 'a',
+    name: 'a',
+    timeline: SurfaceAnimationTimeline(frames: [f]),
+  );
+  return ProjectSurfaceCatalog(
+    atlases: [used, unused],
+    animations: [anim],
+    presets: const [],
+  );
+}
+
+ProjectSurfaceCatalog _catalogWithMissingAnimation() {
+  final refs = SurfaceVariantAnimationRefSet(
+    refs: [
+      SurfaceVariantAnimationRef(
+        role: SurfaceVariantRole.isolated,
+        animationId: 'missing-anim',
+      ),
+    ],
+  );
+  return ProjectSurfaceCatalog(
+    atlases: const [],
+    animations: const [],
+    presets: [
+      ProjectSurfacePreset(
+        id: 'p',
+        name: 'p',
+        variantAnimations: refs,
+      ),
+    ],
+  );
+}
+
+ProjectManifest _manifest(ProjectSurfaceCatalog catalog) {
+  return ProjectManifest(
+    name: 'Test',
+    maps: const [],
+    tilesets: const [],
+    surfaceCatalog: catalog,
+  );
+}
+```
+
+### Sorties des tests ciblés
+
+#### `flutter test test/surface_studio/surface_studio_atlas_authoring_prep_test.dart`
+
+Dernière ligne exacte :
+
+```
+00:05 +18: All tests passed!
+```
+
+#### `flutter test test/surface_studio/surface_studio_panel_test.dart`
+
+Dernière ligne exacte :
+
+```
+00:09 +49: All tests passed!
+```
+
+#### `flutter test` sélection (inspecteur, interaction, summary, selection)
+
+Dernière ligne exacte :
+
+```
+00:02 +37: All tests passed!
+```
+
+#### `flutter test test/surface_studio` (régression groupe)
+
+Commande complète :
+
+```
+cd packages/map_editor && flutter test test/surface_studio
+```
+
+Dernière ligne exacte :
+
+```
+00:10 +239: All tests passed!
+```
+
+#### `dart test test/surface_studio_read_model_test.dart` (map_core)
+
+Dernière ligne exacte :
+
+```
+00:00 +30: All tests passed!
+```
+
+### `flutter analyze` ciblé
+
+```
+Analyzing 2 items...
+No issues found! (ran in 2.5s)
+```
+
+### Vérification `find` fichiers temporaires (racine repo)
+
+```
+Sortie : <vide>
+```
+
```

### SHA256 (passe 1 du rapport, avant ce bloc)

`4c856b6fe2fc1557ca7f117b57afed5f2cba97ec15980f3714b1e1cfc1adb06d`

### SHA256 (fichier rapport final)

`269561958d0b046b1214755bcb64050678214b15bb6b91bc58f6fa0211869562`

## Git status initial

État du worktree **après implémentation Lot 61, avant ajout de ce rapport** (quatre fichiers modifiés uniquement) :

```
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
 M packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart
 M packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
```

## Changements préexistants

Aucun dans les cibles du Lot 61 : le commit de base `a2e9fc08` est le Lot 60. Les `M` listées en statut initial sont le travail Lot 61 jusqu’à commit. Si d’autres fichiers apparaissent ailleurs sur une autre branche, ils ne font pas partie de ce lot.

## Changements du Lot 61

- Création d’atlas en mémoire, tests, rapport : voir le diff unifié dans l’Evidence Pack.

## Périmètre explicitement non touché

- `map_core` non modifié
- Fichiers source du modèle `ProjectManifest` / generated non modifiés pour ce lot
- Aucun generated file modifié
- `build_runner` non lancé
- Fixtures JSON Surface `map_core` non modifiées
- Aucun codec Surface modifié
- Aucun provider Riverpod créé
- Aucun repository / service de persistance créé
- Aucune sauvegarde disque, aucune écriture `project.json`
- Aucune suppression d’atlas, aucune édition d’atlas existant (append seulement)
- Aucune animation ni preset créé ou modifié par l’action création
- Aucun `map_runtime` / `map_gameplay` / `map_battle` modifié
- Aucun painter de map, aucun `SurfaceLayer`, aucun import atlas vertical

**Manifeste** : `updateProjectManifestSurfaceCatalog` / `replace...` **non utilisés** ; state panel + `buildSurfaceStudioReadModelFromCatalog` (mémoire) uniquement.

## Vérification fichiers temporaires

Même `find` qu’en Evidence Pack (racine repo).

```
Sortie : <vide>
```

## Vérification mojibake

Vérification : le texte de ce rapport évite les motifs de mojibake listés dans la spec du lot (combinaisons accentuées erronées pour de l’UTF-8).

## Auto-review

- Crée un atlas (objet + entrée catalogue de travail) : **Oui**.
- Catalogue de travail en mémoire du panel : **Oui**.
- Projet sauvegardé / `project.json` : **Non**.
- Écrasement / modification d’atlas existant : **Non** (id dupliqué bloqué ; append seulement).
- Suppression d’atlas : **Non**.
- Animations / presets stables à l’ajout : **Oui** (tests 61.3).
- Tests ciblés, suite `test/surface_studio`, analyze ciblée : **Oui** (voir preuves).
- Rapport (diffs, contenus, commandes) : **Oui**.
- Aucune commande Git d’écriture : **Oui** (agent).

## Critique du prompt

L’approche callback + state local est adaptée et évite un save flow prématuré. L’Evidence Pack complet allonge beaucoup le Markdown mais correspond au cahier des charges.

*Fin du rapport (Lot 61).*

## Git status final

```
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
 M packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart
 M packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
?? reports/surface/surface_engine_lot_61_surface_studio_create_atlas.md
```
