# Lot 63-bis — Evidence / Missing Initial Status Clarification Only

## Résumé exécutif

Le Lot 63-bis ne modifie aucun code source, ne modifie pas le rapport `surface_engine_lot_63_surface_studio_save_flow_prep.md` du Lot 63, et n’exécute aucune commande Git d’écriture. Il constate que le `git status` initial frais pris **avant** toute modification de fichier du Lot 63 n’a pas été conservé et n’est pas reconstructible **avec certitude** a posteriori. Le présent document fournit un `git status` actuel frais (capture **avant** la création de ce rapport 63-bis) et un `git status` final frais (après écriture de ce fichier). L’état du worktree reste cohérent avec le périmètre du Lot 63 (deux fichiers Dart modifiés, rapport Lot 63 non suivi) plus ce rapport 63-bis. **Le code du Lot 63 n’est pas remis en cause** par l’absence de preuve de status initial. **Le Lot 63 peut être fermé** pour ce qui est de la preuve de procédure, sous réserve explicite de cette réserve documentaire clarifiée ici. Aucun travail Lot 64 n’est entrepris.

## Question à clarifier

Le rapport Lot 63 reconnaît que la sortie de `git status` initial frais **avant** la première écriture de fichier du Lot 63 n’a pas été conservée. Le Lot 63-bis clarifie l’impact de cette absence de preuve : elle **ne prouve pas** l’état exact des chemins modifiés ou non suivis **à cet instant** ; elle n’invalide pas la description technique des changements Lot 63 ni l’exécution des tests documentés dans le Lot 63, tant qu’on ne mélange pas preuve de procédure (status initial) et preuve d’implémentation (fichiers et diffs actuels).

## Périmètre

Documentation uniquement : un seul fichier créé, `reports/surface/surface_engine_lot_63_bis_missing_initial_status_clarification.md`. Aucune modification de code, de tests, d’autres rapports, ni d’outils. Aucun `build_runner`, aucun formatage ciblé sur les sources.

## Commandes exécutées

Les sorties exactes attendues sont reprises dans les sections et dans la section « Evidence Pack ». Commandes lancées depuis la racine du dépôt :

```bash
pwd
```

Sortie exacte :

```
/Users/karim/Project/pokemonProject
```

```bash
git branch --show-current
```

Sortie exacte :

```
codex/psdk-fight-next-move-wave
```

```bash
git status --short --untracked-files=all
```

**Statut** : exécuté **avant** la création du présent fichier `surface_engine_lot_63_bis_missing_initial_status_clarification.md` (cf. section « Git status actuel frais »).

```bash
git diff --stat
```

Sortie exacte (à ce même moment, avant création 63-bis) :

```
 .../surface_studio/surface_studio_panel.dart       |  65 +++++
 .../surface_studio/surface_studio_panel_test.dart  | 261 +++++++++++++++++++++
 2 files changed, 326 insertions(+)
```

```bash
git log --oneline -n 5
```

Sortie exacte :

```
9fe386ba feat(map_editor): Surface Studio work catalog state hardening (Lot 62)
4977cfa3 feat(map_editor): Surface Studio création atlas catalogue de travail (Lot 61)
a2e9fc08 feat(map_editor): Surface Studio atlas authoring prep (Lot 60) + rapport statut (60-bis)
19ef4032 feat(map_editor): Surface Studio sélection locale (Lot 58) et inspecteur (Lot 59)
68e0e552 feat(map_editor): Lot 57 — Surface Studio animation/preset detail views (read-only)
```

```bash
test -e reports/surface/surface_engine_lot_63_surface_studio_save_flow_prep.md; echo "lot63_report_exists=$?"
```

Sortie exacte :

```
lot63_report_exists=0
```

```bash
grep -n "Git status initial" reports/surface/surface_engine_lot_63_surface_studio_save_flow_prep.md || true
```

Sortie exacte :

```
11:## Git status initial
```

```bash
grep -n "n'a pas conservé\|n'a pas conservé\|status initial" reports/surface/surface_engine_lot_63_surface_studio_save_flow_prep.md || true
```

**Complément** : `grep -n "conservé" reports/surface/surface_engine_lot_63_surface_studio_save_flow_prep.md`

**Sortie exacte** :

```
13:Cette reprise de session n’a pas conservé la sortie de `git status --short --untracked-files=all` exécutée avant la première écriture de fichier du Lot 63. Pour un lot exécuté en une fois, l’exigence est de capturer ce statut avant toute modification.
33:Comportement Lot 62 conservé : `_workReadModel` et `widget.readModel` pour le dirty, reset et resync dans `didUpdateWidget`. Le Lot 63 ajoute uniquement le callback, la note et le bandeau d’action dans la zone existante `if (_hasWorkCatalogChanges)`.
```

La commande `grep` avec le motif `n'a pas conservé` du cahier des charges initial peut ne pas matcher l’apostrophe du fichier source (ligne 13) ; l’en-tête `## Git status initial` reste localisé (sortie de `grep -n "Git status initial"` ci‑dessus).

```bash
grep -n "Git status final" reports/surface/surface_engine_lot_63_surface_studio_save_flow_prep.md || true
```

Sortie exacte :

```
15:## Git status final
```

```bash
test -e packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart; echo "surface_studio_panel_exists=$?"
test -e packages/map_editor/test/surface_studio/surface_studio_panel_test.dart; echo "surface_studio_panel_test_exists=$?"
```

Sortie exacte :

```
surface_studio_panel_exists=0
surface_studio_panel_test_exists=0
```

```bash
git diff -- packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
git diff -- packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
```

Contenu de ces diffs : voir section « Audit des fichiers Lot 63 » (sorties reprises en entier).

```bash
find . -type f \( -name '_gen_*.py' -o -name 'build_*.py' -o -name '*.tmp' \) -print
```

Sortie exacte : **<vide>**

Aucun test `flutter test` n’a été relancé : le Lot 63-bis n’introduit aucun changement de code et la recommandation du cahier des charges est d’éviter les relances sauf doute de périmètre ; ici le périmètre est vérifié par `git status` et l’absence de modification par ce lot.

## Git status actuel frais

**Moment** : immédiatement **avant** la première écriture du fichier `reports/surface/surface_engine_lot_63_bis_missing_initial_status_clarification.md` sur le disque.

**Commande** : `git status --short --untracked-files=all`

**Sortie exacte** :

```
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
 M packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
?? reports/surface/surface_engine_lot_63_surface_studio_save_flow_prep.md
```

Cette sortie comporte le rapport Lot 63 en non suivi (`??`) et ne comporte **pas** encore le rapport 63-bis, puisque celui-ci n’existait pas.

## Audit du rapport Lot 63

- **Fichier présent** : `test -e` sur `reports/surface/surface_engine_lot_63_surface_studio_save_flow_prep.md` retourne `lot63_report_exists=0` (fichier existe).
- **Section « Git status initial »** : présente (ligne 11 selon `grep -n "Git status initial"`).
- **Réserves** : le texte affirme qu’une reprise de session n’a pas conservé la sortie de `git status` avant la première écriture de fichier du Lot 63 ; formulation relevée dans le grep du fichier (ligne 13) : *« Cette reprise de session n’a pas conservé la sortie de `git status --short --untracked-files=all` exécutée avant la première écriture de fichier du Lot 63. »*
- **Section « Git status final »** : présente (ligne 15 selon `grep`).
- **Conclusion d’audit** : le rapport Lot 63 **n’inclut pas** une pastille reproductible `git status` initial (sortie d’outils) : il en explique l’**absence**. La question « l’existe-t-il dans le rapport ? » a pour réponse : **la sortie exacte, non** ; seule l’**explication** y figure.

## Audit des fichiers Lot 63

- **Existence** : `surface_studio_panel.dart` et `surface_studio_panel_test.dart` existent (`surface_studio_panel_exists=0`, `surface_studio_panel_test_exists=0`).
- **Diffs actuels (non modifiés par 63-bis)** : enregistrés dans l’index de travail ; ils correspondent au **Lot 63** (callback `onSurfaceCatalogSaveRequested`, libellés de préparation de sauvegarde, tests groupe Lot 63, extension du test 62.7). Les diffs ne sont **pas** produits par le Lot 63-bis, qui ne touche à aucun fichier Dart.
- **Diff complet — `surface_studio_panel.dart`** :

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
   /// Sélection d'inspection : locale au widget, jamais écrite dans le manifest.
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
```

- **Indicateur** : `git diff --stat` pour ces seuls chemins = **2 files changed, 326 insertions(+)** (aucune suppression), cohérent avec un lot purement additif côté panneau et tests.

- **Diff complet — `surface_studio_panel_test.dart`** : voir bloc suivant (sortie exacte de `git diff -- packages/map_editor/test/surface_studio/surface_studio_panel_test.dart`).

```diff
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

## Git status final

**Commande** : `git status --short --untracked-files=all` (racine du dépôt). **Instantané** : exécuté lorsque le fichier 63-bis était rédigé jusqu’à la fin de la section « Vérification fichiers temporaires (Lot 63-bis) », **avant** l’insertion de la présente section « Git status final » et de la section « Evidence Pack ».

**Sortie exacte** :

```
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
 M packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
?? reports/surface/surface_engine_lot_63_bis_missing_initial_status_clarification.md
?? reports/surface/surface_engine_lot_63_surface_studio_save_flow_prep.md
```

**Commande** : `git diff --stat` (même instant).

**Sortie exacte** :

```
 .../surface_studio/surface_studio_panel.dart       |  65 +++++
 .../surface_studio/surface_studio_panel_test.dart  | 261 +++++++++++++++++++++
 2 files changed, 326 insertions(+)
```

## Analyse

**Confirmé** :

- Le `git status` initial frais (sortie d’outil avant la première modification de fichier du Lot 63) **n’est pas présent** dans le rapport Lot 63 sous forme de bloc reproductible : le rapport contient une **section** « Git status initial » et une **explication narrative** de l’absence de capture, pas la sortie `git status` elle-même.
- Le `git status` actuel frais (avant ce rapport 63-bis) montre exactement deux fichiers Dart modifiés attendus pour le Lot 63 et le rapport Lot 63 en non suivi.
- Les diffs actuels sur ces deux fichiers Dart correspondent au périmètre fonctionnel décrit pour le Lot 63 (callback, UI de préparation, tests).

**Non prouvé** :

- L’état exact du worktree (liste et états de tous les chemins) **au tout premier instant** avant la première écriture du Lot 63 : cette information ne peut être **reconstruite avec certitude** après coup si la sortie n’a pas été archivée.

**Exclu pour le Lot 63-bis** :

- Toute modification de code : le statut final attendu après 63-bis ne doit ajouter que le présent fichier de rapport (et aucune modification indexée sur les sources).

## Impact sur le Lot 63

- **Le manque de `git status` initial remet-il en cause le code ?** Non : les changements Lot 63 sont toujours inspectables via `git diff` sur les fichiers concernés et cohérents avec la livraison attendue.
- **Remet-il en cause les tests ?** Non : le Lot 63-bis ne modifie pas les tests ; la crédibilité des tests publiés dans le rapport Lot 63 repose sur les exécutions documentées dans ce rapport, pas sur le `git status` initial.
- **Remet-il en cause le périmètre ?** Non : le périmètre réel actuel (deux fichiers Dart + rapports non suivis) reste **borné** au Lot 63 + documentation.
- **Faut-il corriger la feature ?** Non.
- **Faut-il modifier le rapport Lot 63 ?** Non pour le Lot 63-bis (interdit) ; la clarification est portée par **ce** document.

## Recommandation

- **Lot 63** : peut être **fermé** au sens « implémentation et preuves techniques inchangées », avec **réserve documentaire** : absence de preuve de procédure pour le `git status` initial frais, désormais explicitement traitée.
- **Lot 64** : peut être **préparé** ou démarré selon la feuille de route du projet ; ce 63-bis **n’implémente** rien du Lot 64.

## Fichiers créés

- `reports/surface/surface_engine_lot_63_bis_missing_initial_status_clarification.md`

## Fichiers modifiés

Sortie : <vide> (aucun fichier existant modifié par le Lot 63-bis ; les fichiers Dart listés par `git status` restent des changements **préexistants** du Lot 63 tant qu’ils ne sont pas commités autrement).

## Fichiers supprimés

Sortie : <vide>

## Périmètre explicitement non touché

- Aucun code modifié par le Lot 63-bis
- Rapport Lot 63 non modifié
- `map_core` non modifié
- `ProjectManifest` et générés associés non modifiés
- Fichiers générés non modifiés
- `build_runner` non lancé
- Fixtures Surface JSON non modifiées
- Aucun codec Surface modifié
- Aucun provider Riverpod créé
- Aucun repository ni service créé
- Aucune sauvegarde disque ni écriture `project.json`
- Aucune suppression ni édition d’atlas au-delà du hors périmètre habituel
- Aucune animation ni preset créé ou modifié
- Aucun runtime, gameplay ou battle modifié
- Aucun painter de carte ni `SurfaceLayer` ni import d’atlas vertical
- Aucun appel `clearProjectManifestSurfaceCatalog`, `updateProjectManifestSurfaceCatalog`, `replaceProjectManifestSurfaceCatalog`, ni `copyWith(surfaceCatalog: …)` ajouté par ce lot

## Auto-review

- Est-ce que du code a été modifié ? Non (le Lot 63-bis ne modifie que ce rapport).
- Est-ce que le rapport Lot 63 a été modifié ? Non.
- Est-ce qu’une commande Git d’écriture a été utilisée ? Non.
- Est-ce que le status initial frais du Lot 63 peut être reconstruit ? Non avec certitude à partir des seuls artefacts actuels ; le rapport Lot 63 l’admet.
- Est-ce que le status actuel est fourni ? Oui (section dédiée, capture avant création du 63-bis).
- Est-ce que le status final est fourni ? Oui (section « Git status final »).
- Est-ce que les fichiers modifiés actuels correspondent au Lot 63 ? Oui : deux chemins Dart cohérents avec le save flow prep ; le Lot 63-bis n’y a pas touché.
- Est-ce que le Lot 63 peut être fermé après ce 63-bis ? Oui, avec la réserve sur la preuve de `git status` initial.
- Est-ce que le Lot 64 peut démarrer ? Oui du point de vue de ce 63-bis (pas de blocage technique ici).

## Critique du prompt

Exiger un `git status` initial **reconstructible a posteriori** quand la sortie n’a pas été conservée est **impossible** : seuls des instantanés pris à l’époque ou l’équivalent (reflog, bundle, autre outil) pourraient le restituer, ce qui sort du rôle d’un simple correctif 63-bis. Le meilleur diagnostic factuel est : conserver pour l’avenir la procédure « `git status` avant premier edit », et consigner ici l’**absence** de preuve pour le Lot 63.

## Vérification fichiers temporaires (Lot 63-bis)

Commande : `find . -type f \( -name '_gen_*.py' -o -name 'build_*.py' -o -name '*.tmp' \) -print`

Sortie : <vide>

## Evidence Pack

### Distinction des changements

- **Lot 63 (worktree non committé)** : `surface_studio_panel.dart` et `surface_studio_panel_test.dart` (diff indexé, 326 insertions).
- **Lot 63 (rapport non suivi)** : `surface_engine_lot_63_surface_studio_save_flow_prep.md` (inchangé par 63-bis).
- **Lot 63-bis** : seule la création de `surface_engine_lot_63_bis_missing_initial_status_clarification.md` ; aucun code modifié par ce lot.

### Contenu : équivalence avec le diff ci-dessous

L’**intégralité** du contenu de la version de ce rapport **avant** l’ajout de la présente section Evidence Pack est égale, ligne à ligne, au fichier décrit par le diff unifié suivant (préfixe `+`, fichier de 692 lignes au moment de la génération du diff).

### Diff unifié équivalent `/dev/null` → fichier (version 692 lignes, avant Evidence Pack)

Commande : `git diff --no-index -- /dev/null reports/surface/surface_engine_lot_63_bis_missing_initial_status_clarification.md` (exécutée sur la copie tronquée à 692 lignes ; sortie : **698** lignes).

~~~diff
diff --git a/reports/surface/surface_engine_lot_63_bis_missing_initial_status_clarification.md b/reports/surface/surface_engine_lot_63_bis_missing_initial_status_clarification.md
new file mode 100644
index 00000000..58bae7c5
--- /dev/null
+++ b/reports/surface/surface_engine_lot_63_bis_missing_initial_status_clarification.md
@@ -0,0 +1,692 @@
+# Lot 63-bis — Evidence / Missing Initial Status Clarification Only
+
+## Résumé exécutif
+
+Le Lot 63-bis ne modifie aucun code source, ne modifie pas le rapport `surface_engine_lot_63_surface_studio_save_flow_prep.md` du Lot 63, et n’exécute aucune commande Git d’écriture. Il constate que le `git status` initial frais pris **avant** toute modification de fichier du Lot 63 n’a pas été conservé et n’est pas reconstructible **avec certitude** a posteriori. Le présent document fournit un `git status` actuel frais (capture **avant** la création de ce rapport 63-bis) et un `git status` final frais (après écriture de ce fichier). L’état du worktree reste cohérent avec le périmètre du Lot 63 (deux fichiers Dart modifiés, rapport Lot 63 non suivi) plus ce rapport 63-bis. **Le code du Lot 63 n’est pas remis en cause** par l’absence de preuve de status initial. **Le Lot 63 peut être fermé** pour ce qui est de la preuve de procédure, sous réserve explicite de cette réserve documentaire clarifiée ici. Aucun travail Lot 64 n’est entrepris.
+
+## Question à clarifier
+
+Le rapport Lot 63 reconnaît que la sortie de `git status` initial frais **avant** la première écriture de fichier du Lot 63 n’a pas été conservée. Le Lot 63-bis clarifie l’impact de cette absence de preuve : elle **ne prouve pas** l’état exact des chemins modifiés ou non suivis **à cet instant** ; elle n’invalide pas la description technique des changements Lot 63 ni l’exécution des tests documentés dans le Lot 63, tant qu’on ne mélange pas preuve de procédure (status initial) et preuve d’implémentation (fichiers et diffs actuels).
+
+## Périmètre
+
+Documentation uniquement : un seul fichier créé, `reports/surface/surface_engine_lot_63_bis_missing_initial_status_clarification.md`. Aucune modification de code, de tests, d’autres rapports, ni d’outils. Aucun `build_runner`, aucun formatage ciblé sur les sources.
+
+## Commandes exécutées
+
+Les sorties exactes attendues sont reprises dans les sections et dans la section « Evidence Pack ». Commandes lancées depuis la racine du dépôt :
+
+```bash
+pwd
+```
+
+Sortie exacte :
+
+```
+/Users/karim/Project/pokemonProject
+```
+
+```bash
+git branch --show-current
+```
+
+Sortie exacte :
+
+```
+codex/psdk-fight-next-move-wave
+```
+
+```bash
+git status --short --untracked-files=all
+```
+
+**Statut** : exécuté **avant** la création du présent fichier `surface_engine_lot_63_bis_missing_initial_status_clarification.md` (cf. section « Git status actuel frais »).
+
+```bash
+git diff --stat
+```
+
+Sortie exacte (à ce même moment, avant création 63-bis) :
+
+```
+ .../surface_studio/surface_studio_panel.dart       |  65 +++++
+ .../surface_studio/surface_studio_panel_test.dart  | 261 +++++++++++++++++++++
+ 2 files changed, 326 insertions(+)
+```
+
+```bash
+git log --oneline -n 5
+```
+
+Sortie exacte :
+
+```
+9fe386ba feat(map_editor): Surface Studio work catalog state hardening (Lot 62)
+4977cfa3 feat(map_editor): Surface Studio création atlas catalogue de travail (Lot 61)
+a2e9fc08 feat(map_editor): Surface Studio atlas authoring prep (Lot 60) + rapport statut (60-bis)
+19ef4032 feat(map_editor): Surface Studio sélection locale (Lot 58) et inspecteur (Lot 59)
+68e0e552 feat(map_editor): Lot 57 — Surface Studio animation/preset detail views (read-only)
+```
+
+```bash
+test -e reports/surface/surface_engine_lot_63_surface_studio_save_flow_prep.md; echo "lot63_report_exists=$?"
+```
+
+Sortie exacte :
+
+```
+lot63_report_exists=0
+```
+
+```bash
+grep -n "Git status initial" reports/surface/surface_engine_lot_63_surface_studio_save_flow_prep.md || true
+```
+
+Sortie exacte :
+
+```
+11:## Git status initial
+```
+
+```bash
+grep -n "n'a pas conservé\|n'a pas conservé\|status initial" reports/surface/surface_engine_lot_63_surface_studio_save_flow_prep.md || true
+```
+
+**Complément** : `grep -n "conservé" reports/surface/surface_engine_lot_63_surface_studio_save_flow_prep.md`
+
+**Sortie exacte** :
+
+```
+13:Cette reprise de session n’a pas conservé la sortie de `git status --short --untracked-files=all` exécutée avant la première écriture de fichier du Lot 63. Pour un lot exécuté en une fois, l’exigence est de capturer ce statut avant toute modification.
+33:Comportement Lot 62 conservé : `_workReadModel` et `widget.readModel` pour le dirty, reset et resync dans `didUpdateWidget`. Le Lot 63 ajoute uniquement le callback, la note et le bandeau d’action dans la zone existante `if (_hasWorkCatalogChanges)`.
+```
+
+La commande `grep` avec le motif `n'a pas conservé` du cahier des charges initial peut ne pas matcher l’apostrophe du fichier source (ligne 13) ; l’en-tête `## Git status initial` reste localisé (sortie de `grep -n "Git status initial"` ci‑dessus).
+
+```bash
+grep -n "Git status final" reports/surface/surface_engine_lot_63_surface_studio_save_flow_prep.md || true
+```
+
+Sortie exacte :
+
+```
+15:## Git status final
+```
+
+```bash
+test -e packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart; echo "surface_studio_panel_exists=$?"
+test -e packages/map_editor/test/surface_studio/surface_studio_panel_test.dart; echo "surface_studio_panel_test_exists=$?"
+```
+
+Sortie exacte :
+
+```
+surface_studio_panel_exists=0
+surface_studio_panel_test_exists=0
+```
+
+```bash
+git diff -- packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
+git diff -- packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
+```
+
+Contenu de ces diffs : voir section « Audit des fichiers Lot 63 » (sorties reprises en entier).
+
+```bash
+find . -type f \( -name '_gen_*.py' -o -name 'build_*.py' -o -name '*.tmp' \) -print
+```
+
+Sortie exacte : **<vide>**
+
+Aucun test `flutter test` n’a été relancé : le Lot 63-bis n’introduit aucun changement de code et la recommandation du cahier des charges est d’éviter les relances sauf doute de périmètre ; ici le périmètre est vérifié par `git status` et l’absence de modification par ce lot.
+
+## Git status actuel frais
+
+**Moment** : immédiatement **avant** la première écriture du fichier `reports/surface/surface_engine_lot_63_bis_missing_initial_status_clarification.md` sur le disque.
+
+**Commande** : `git status --short --untracked-files=all`
+
+**Sortie exacte** :
+
+```
+ M packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
+ M packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
+?? reports/surface/surface_engine_lot_63_surface_studio_save_flow_prep.md
+```
+
+Cette sortie comporte le rapport Lot 63 en non suivi (`??`) et ne comporte **pas** encore le rapport 63-bis, puisque celui-ci n’existait pas.
+
+## Audit du rapport Lot 63
+
+- **Fichier présent** : `test -e` sur `reports/surface/surface_engine_lot_63_surface_studio_save_flow_prep.md` retourne `lot63_report_exists=0` (fichier existe).
+- **Section « Git status initial »** : présente (ligne 11 selon `grep -n "Git status initial"`).
+- **Réserves** : le texte affirme qu’une reprise de session n’a pas conservé la sortie de `git status` avant la première écriture de fichier du Lot 63 ; formulation relevée dans le grep du fichier (ligne 13) : *« Cette reprise de session n’a pas conservé la sortie de `git status --short --untracked-files=all` exécutée avant la première écriture de fichier du Lot 63. »*
+- **Section « Git status final »** : présente (ligne 15 selon `grep`).
+- **Conclusion d’audit** : le rapport Lot 63 **n’inclut pas** une pastille reproductible `git status` initial (sortie d’outils) : il en explique l’**absence**. La question « l’existe-t-il dans le rapport ? » a pour réponse : **la sortie exacte, non** ; seule l’**explication** y figure.
+
+## Audit des fichiers Lot 63
+
+- **Existence** : `surface_studio_panel.dart` et `surface_studio_panel_test.dart` existent (`surface_studio_panel_exists=0`, `surface_studio_panel_test_exists=0`).
+- **Diffs actuels (non modifiés par 63-bis)** : enregistrés dans l’index de travail ; ils correspondent au **Lot 63** (callback `onSurfaceCatalogSaveRequested`, libellés de préparation de sauvegarde, tests groupe Lot 63, extension du test 62.7). Les diffs ne sont **pas** produits par le Lot 63-bis, qui ne touche à aucun fichier Dart.
+- **Diff complet — `surface_studio_panel.dart`** :
+
+```diff
+diff --git a/packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart b/packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
+index 9b3c9d6f..abbb5e8f 100644
+--- a/packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
++++ b/packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
+@@ -49,9 +49,11 @@ class SurfaceStudioPanel extends StatefulWidget {
+   const SurfaceStudioPanel({
+     super.key,
+     required this.readModel,
++    this.onSurfaceCatalogSaveRequested,
+   });
+ 
+   final SurfaceStudioReadModel readModel;
++  final ValueChanged<ProjectSurfaceCatalog>? onSurfaceCatalogSaveRequested;
+ 
+   static const String titleText = 'Surface Studio';
+   static const String readOnlyBadgeText = 'Lecture seule';
+@@ -63,6 +65,14 @@ class SurfaceStudioPanel extends StatefulWidget {
+       'Importer un atlas vertical';
+   static const String workCatalogDirtyStateText =
+       'Catalogue de travail modifié — sauvegarde projet non effectuée.';
++  static const String savePrepActionLabel =
++      'Préparer la sauvegarde du catalogue Surface';
++  static const String savePrepTransmittedNote =
++      'Catalogue de travail transmis au parent.';
++  static const String savePrepNotConnectedNote =
++      'Sauvegarde non connectée dans ce contexte.';
++  static const String savePrepNoDiskNote =
++      'Aucune écriture disque ne sera effectuée par Surface Studio.';
+ 
+   @override
+   State<SurfaceStudioPanel> createState() => _SurfaceStudioPanelState();
+@@ -72,6 +82,7 @@ class _SurfaceStudioPanelState extends State<SurfaceStudioPanel> {
+   /// Sélection d'inspection : locale au widget, jamais écrite dans le manifest.
+   SurfaceStudioSelection _selection = const SurfaceStudioSelection.none();
+   late SurfaceStudioReadModel _workReadModel;
++  String? _saveFlowPrepNote;
+ 
+   @override
+   void initState() {
+@@ -86,12 +97,24 @@ class _SurfaceStudioPanelState extends State<SurfaceStudioPanel> {
+       setState(() {
+         _workReadModel = widget.readModel;
+         _selection = _selectionValidInReadModel(_workReadModel, _selection);
++        _saveFlowPrepNote = null;
+       });
+     }
+   }
+ 
+   bool get _hasWorkCatalogChanges => _workReadModel != widget.readModel;
+ 
++  void _onSurfaceCatalogSavePrep() {
++    final cb = widget.onSurfaceCatalogSaveRequested;
++    if (cb == null) {
++      return;
++    }
++    cb(_workReadModel.catalog);
++    setState(() {
++      _saveFlowPrepNote = SurfaceStudioPanel.savePrepTransmittedNote;
++    });
++  }
++
+   @override
+   Widget build(BuildContext context) {
+     final s = _workReadModel.summary;
+@@ -154,6 +177,46 @@ class _SurfaceStudioPanelState extends State<SurfaceStudioPanel> {
+                 fontWeight: FontWeight.w600,
+               ),
+             ),
++            const SizedBox(height: 4),
++            Text(
++              SurfaceStudioPanel.savePrepNoDiskNote,
++              style: TextStyle(
++                color: subtle.withValues(alpha: 0.9),
++                fontSize: 11,
++              ),
++            ),
++            const SizedBox(height: 6),
++            if (widget.onSurfaceCatalogSaveRequested != null) ...[
++              CupertinoButton(
++                key: const ValueKey('surface_studio_save_prep_catalog'),
++                padding:
++                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
++                onPressed: _onSurfaceCatalogSavePrep,
++                child: const Text(SurfaceStudioPanel.savePrepActionLabel),
++              ),
++            ] else ...[
++              Text(
++                key: const ValueKey('surface_studio_save_prep_not_connected'),
++                SurfaceStudioPanel.savePrepNotConnectedNote,
++                style: TextStyle(
++                  color: subtle.withValues(alpha: 0.95),
++                  fontSize: 11,
++                  fontStyle: FontStyle.italic,
++                ),
++              ),
++            ],
++            if (_saveFlowPrepNote != null) ...[
++              const SizedBox(height: 6),
++              Text(
++                _saveFlowPrepNote!,
++                key: const ValueKey('surface_studio_save_prep_transmitted'),
++                style: TextStyle(
++                  color: _surfaceStudioAccent.withValues(alpha: 0.9),
++                  fontSize: 11,
++                  fontWeight: FontWeight.w600,
++                ),
++              ),
++            ],
+             const SizedBox(height: 6),
+             CupertinoButton(
+               key: const ValueKey('surface_studio_reset_work_catalog'),
+@@ -163,6 +226,7 @@ class _SurfaceStudioPanelState extends State<SurfaceStudioPanel> {
+                   _workReadModel = widget.readModel;
+                   _selection =
+                       _selectionValidInReadModel(_workReadModel, _selection);
++                  _saveFlowPrepNote = null;
+                 });
+               },
+               child: const Text('Réinitialiser le catalogue de travail'),
+@@ -200,6 +264,7 @@ class _SurfaceStudioPanelState extends State<SurfaceStudioPanel> {
+                   ? cat.atlases.last.id
+                   : '';
+               setState(() {
++                _saveFlowPrepNote = null;
+                 _workReadModel = buildSurfaceStudioReadModelFromCatalog(cat);
+                 if (newId.isNotEmpty) {
+                   _selection = SurfaceStudioSelection.atlas(newId);
+```
+
+- **Indicateur** : `git diff --stat` pour ces seuls chemins = **2 files changed, 326 insertions(+)** (aucune suppression), cohérent avec un lot purement additif côté panneau et tests.
+
+- **Diff complet — `surface_studio_panel_test.dart`** : voir bloc suivant (sortie exacte de `git diff -- packages/map_editor/test/surface_studio/surface_studio_panel_test.dart`).
+
+```diff
+diff --git a/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart b/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
+index f0fcfb75..4a47f9e9 100644
+--- a/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
++++ b/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
+@@ -960,6 +960,7 @@ void main() {
+       for (final s in <String>[
+         'Sauvegarder le projet',
+         'Enregistrer le projet',
++        'Sauvegarder maintenant',
+         'Save project',
+         'Write to disk',
+         'Écrire sur disque',
+@@ -968,6 +969,266 @@ void main() {
+       }
+     });
+   });
++
++  group('SurfaceStudioPanel (Lot 63)', () {
++    testWidgets('63.1 — sans modification : pas d’action préparation, callback jamais',
++        (tester) async {
++      var calls = 0;
++      await tester.pumpWidget(
++        _wrap(
++          SurfaceStudioPanel(
++            readModel: _minimalWaterReadModel(),
++            onSurfaceCatalogSaveRequested: (_) => calls++,
++          ),
++        ),
++      );
++      expect(
++        find.byKey(const ValueKey('surface_studio_save_prep_catalog')),
++        findsNothing,
++      );
++      expect(
++        find.text(SurfaceStudioPanel.savePrepActionLabel),
++        findsNothing,
++      );
++      expect(calls, 0);
++    });
++
++    testWidgets(
++        '63.2 — dirty + callback : action, un appel, catalogue complet, dirty et accusé',
++        (tester) async {
++      ProjectSurfaceCatalog? received;
++      var calls = 0;
++      await tester.pumpWidget(
++        _wrap(
++          SurfaceStudioPanel(
++            readModel: _emptyReadModel(),
++            onSurfaceCatalogSaveRequested: (c) {
++              calls++;
++              received = c;
++            },
++          ),
++        ),
++      );
++      final idF = find.byKey(const ValueKey('atlas_draft_id'));
++      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
++      final tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
++      await tester.ensureVisible(idF);
++      await tester.enterText(idF, 'prep-one');
++      await tester.enterText(nameF, 'P');
++      await tester.enterText(tsF, 't');
++      await tester.pump();
++      await tester.ensureVisible(
++        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
++      );
++      await tester.tap(
++        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
++      );
++      await tester.pump();
++      final prep = find.byKey(const ValueKey('surface_studio_save_prep_catalog'));
++      expect(prep, findsOneWidget);
++      await tester.ensureVisible(prep);
++      await tester.tap(prep);
++      await tester.pump();
++      expect(calls, 1);
++      expect(received, isNotNull);
++      expect(received!.atlases.length, 1);
++      expect(received!.atlases.first.id, 'prep-one');
++      expect(
++        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
++        findsOneWidget,
++      );
++      expect(
++        find.text(SurfaceStudioPanel.savePrepTransmittedNote),
++        findsOneWidget,
++      );
++    });
++
++    testWidgets('63.3 — sans callback : stable, message not connected, pas de bouton',
++        (tester) async {
++      await tester.pumpWidget(
++        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
++      );
++      final idF = find.byKey(const ValueKey('atlas_draft_id'));
++      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
++      final tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
++      await tester.ensureVisible(idF);
++      await tester.enterText(idF, 'nccb');
++      await tester.enterText(nameF, 'N');
++      await tester.enterText(tsF, 't');
++      await tester.pump();
++      await tester.ensureVisible(
++        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
++      );
++      await tester.tap(
++        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
++      );
++      await tester.pump();
++      expect(tester.takeException(), isNull);
++      expect(
++        find.text(SurfaceStudioPanel.savePrepNotConnectedNote),
++        findsOneWidget,
++      );
++      expect(
++        find.byKey(const ValueKey('surface_studio_save_prep_catalog')),
++        findsNothing,
++      );
++    });
++
++    testWidgets('63.4 — resync parent : dirty off, atlas source, pas d’accusé',
++        (tester) async {
++      ProjectSurfaceCatalog? out;
++      await tester.pumpWidget(
++        _wrap(
++          SurfaceStudioPanel(
++            readModel: _emptyReadModel(),
++            onSurfaceCatalogSaveRequested: (c) => out = c,
++          ),
++        ),
++      );
++      var idF = find.byKey(const ValueKey('atlas_draft_id'));
++      var nameF = find.byKey(const ValueKey('atlas_draft_name'));
++      var tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
++      await tester.ensureVisible(idF);
++      await tester.enterText(idF, 'sync-x');
++      await tester.enterText(nameF, 'S');
++      await tester.enterText(tsF, 't');
++      await tester.pump();
++      await tester.ensureVisible(
++        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
++      );
++      await tester.tap(
++        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
++      );
++      await tester.pump();
++      final prep = find.byKey(const ValueKey('surface_studio_save_prep_catalog'));
++      await tester.ensureVisible(prep);
++      await tester.tap(prep);
++      await tester.pump();
++      expect(out, isNotNull);
++      final synced = buildSurfaceStudioReadModelFromCatalog(out!);
++      await tester.pumpWidget(
++        _wrap(
++          SurfaceStudioPanel(
++            readModel: synced,
++            onSurfaceCatalogSaveRequested: (c) => out = c,
++          ),
++        ),
++      );
++      await tester.pump();
++      expect(
++        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
++        findsNothing,
++      );
++      expect(
++        find.text(SurfaceStudioPanel.savePrepTransmittedNote),
++        findsNothing,
++      );
++      expect(find.text('sync-x'), findsWidgets);
++    });
++
++    testWidgets('63.5 — reset après préparation : clean, accusé nettoyé, vide',
++        (tester) async {
++      await tester.pumpWidget(
++        _wrap(
++          SurfaceStudioPanel(
++            readModel: _emptyReadModel(),
++            onSurfaceCatalogSaveRequested: (_) {},
++          ),
++        ),
++      );
++      var idF = find.byKey(const ValueKey('atlas_draft_id'));
++      var nameF = find.byKey(const ValueKey('atlas_draft_name'));
++      var tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
++      await tester.ensureVisible(idF);
++      await tester.enterText(idF, 'reset-p');
++      await tester.enterText(nameF, 'R');
++      await tester.enterText(tsF, 't');
++      await tester.pump();
++      await tester.ensureVisible(
++        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
++      );
++      await tester.tap(
++        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
++      );
++      await tester.pump();
++      final prep = find.byKey(const ValueKey('surface_studio_save_prep_catalog'));
++      await tester.ensureVisible(prep);
++      await tester.tap(prep);
++      await tester.pump();
++      expect(
++        find.text(SurfaceStudioPanel.savePrepTransmittedNote),
++        findsOneWidget,
++      );
++      await tester.ensureVisible(
++        find.byKey(const ValueKey('surface_studio_reset_work_catalog')),
++      );
++      await tester.tap(
++        find.byKey(const ValueKey('surface_studio_reset_work_catalog')),
++      );
++      await tester.pump();
++      expect(
++        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
++        findsNothing,
++      );
++      expect(
++        find.text(SurfaceStudioPanel.savePrepTransmittedNote),
++        findsNothing,
++      );
++      final counters = find.byKey(const ValueKey('surface_studio_header_counters'));
++      expect(
++        find.descendant(of: counters, matching: find.text('0')),
++        findsNWidgets(3),
++      );
++      expect(
++        find.text('Le catalogue Surface est vide'),
++        findsOneWidget,
++      );
++    });
++
++    testWidgets('63.6 — A puis B puis préparation : ordre des atlas', (tester) async {
++      ProjectSurfaceCatalog? got;
++      await tester.pumpWidget(
++        _wrap(
++          SurfaceStudioPanel(
++            readModel: _emptyReadModel(),
++            onSurfaceCatalogSaveRequested: (c) => got = c,
++          ),
++        ),
++      );
++      for (final row in <(String, String, String)>[
++        ('lot63-a', 'A', 'ta'),
++        ('lot63-b', 'B', 'tb'),
++      ]) {
++        final idF = find.byKey(const ValueKey('atlas_draft_id'));
++        final nameF = find.byKey(const ValueKey('atlas_draft_name'));
++        final tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
++        await tester.ensureVisible(idF);
++        await tester.enterText(idF, row.$1);
++        await tester.enterText(nameF, row.$2);
++        await tester.enterText(tsF, row.$3);
++        await tester.pump();
++        await tester.ensureVisible(
++          find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
++        );
++        await tester.tap(
++          find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
++        );
++        await tester.pump();
++      }
++      final prep = find.byKey(const ValueKey('surface_studio_save_prep_catalog'));
++      await tester.ensureVisible(prep);
++      await tester.tap(prep);
++      await tester.pump();
++      expect(got, isNotNull);
++      expect(got!.atlases.length, 2);
++      expect(got!.atlases[0].id, 'lot63-a');
++      expect(got!.atlases[1].id, 'lot63-b');
++      expect(
++        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
++        findsOneWidget,
++      );
++    });
++  });
+ }
+
+ Widget _wrap(Widget child) {
+```
+
+## Git status final
+
+**Commande** : `git status --short --untracked-files=all` (racine du dépôt). **Instantané** : exécuté lorsque le fichier 63-bis était rédigé jusqu’à la fin de la section « Vérification fichiers temporaires (Lot 63-bis) », **avant** l’insertion de la présente section « Git status final » et de la section « Evidence Pack ».
+
+**Sortie exacte** :
+
+```
+ M packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
+ M packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
+?? reports/surface/surface_engine_lot_63_bis_missing_initial_status_clarification.md
+?? reports/surface/surface_engine_lot_63_surface_studio_save_flow_prep.md
+```
+
+**Commande** : `git diff --stat` (même instant).
+
+**Sortie exacte** :
+
+```
+ .../surface_studio/surface_studio_panel.dart       |  65 +++++
+ .../surface_studio/surface_studio_panel_test.dart  | 261 +++++++++++++++++++++
+ 2 files changed, 326 insertions(+)
+```
+
+## Analyse
+
+**Confirmé** :
+
+- Le `git status` initial frais (sortie d’outil avant la première modification de fichier du Lot 63) **n’est pas présent** dans le rapport Lot 63 sous forme de bloc reproductible : le rapport contient une **section** « Git status initial » et une **explication narrative** de l’absence de capture, pas la sortie `git status` elle-même.
+- Le `git status` actuel frais (avant ce rapport 63-bis) montre exactement deux fichiers Dart modifiés attendus pour le Lot 63 et le rapport Lot 63 en non suivi.
+- Les diffs actuels sur ces deux fichiers Dart correspondent au périmètre fonctionnel décrit pour le Lot 63 (callback, UI de préparation, tests).
+
+**Non prouvé** :
+
+- L’état exact du worktree (liste et états de tous les chemins) **au tout premier instant** avant la première écriture du Lot 63 : cette information ne peut être **reconstruite avec certitude** après coup si la sortie n’a pas été archivée.
+
+**Exclu pour le Lot 63-bis** :
+
+- Toute modification de code : le statut final attendu après 63-bis ne doit ajouter que le présent fichier de rapport (et aucune modification indexée sur les sources).
+
+## Impact sur le Lot 63
+
+- **Le manque de `git status` initial remet-il en cause le code ?** Non : les changements Lot 63 sont toujours inspectables via `git diff` sur les fichiers concernés et cohérents avec la livraison attendue.
+- **Remet-il en cause les tests ?** Non : le Lot 63-bis ne modifie pas les tests ; la crédibilité des tests publiés dans le rapport Lot 63 repose sur les exécutions documentées dans ce rapport, pas sur le `git status` initial.
+- **Remet-il en cause le périmètre ?** Non : le périmètre réel actuel (deux fichiers Dart + rapports non suivis) reste **borné** au Lot 63 + documentation.
+- **Faut-il corriger la feature ?** Non.
+- **Faut-il modifier le rapport Lot 63 ?** Non pour le Lot 63-bis (interdit) ; la clarification est portée par **ce** document.
+
+## Recommandation
+
+- **Lot 63** : peut être **fermé** au sens « implémentation et preuves techniques inchangées », avec **réserve documentaire** : absence de preuve de procédure pour le `git status` initial frais, désormais explicitement traitée.
+- **Lot 64** : peut être **préparé** ou démarré selon la feuille de route du projet ; ce 63-bis **n’implémente** rien du Lot 64.
+
+## Fichiers créés
+
+- `reports/surface/surface_engine_lot_63_bis_missing_initial_status_clarification.md`
+
+## Fichiers modifiés
+
+Sortie : <vide> (aucun fichier existant modifié par le Lot 63-bis ; les fichiers Dart listés par `git status` restent des changements **préexistants** du Lot 63 tant qu’ils ne sont pas commités autrement).
+
+## Fichiers supprimés
+
+Sortie : <vide>
+
+## Périmètre explicitement non touché
+
+- Aucun code modifié par le Lot 63-bis
+- Rapport Lot 63 non modifié
+- `map_core` non modifié
+- `ProjectManifest` et générés associés non modifiés
+- Fichiers générés non modifiés
+- `build_runner` non lancé
+- Fixtures Surface JSON non modifiées
+- Aucun codec Surface modifié
+- Aucun provider Riverpod créé
+- Aucun repository ni service créé
+- Aucune sauvegarde disque ni écriture `project.json`
+- Aucune suppression ni édition d’atlas au-delà du hors périmètre habituel
+- Aucune animation ni preset créé ou modifié
+- Aucun runtime, gameplay ou battle modifié
+- Aucun painter de carte ni `SurfaceLayer` ni import d’atlas vertical
+- Aucun appel `clearProjectManifestSurfaceCatalog`, `updateProjectManifestSurfaceCatalog`, `replaceProjectManifestSurfaceCatalog`, ni `copyWith(surfaceCatalog: …)` ajouté par ce lot
+
+## Auto-review
+
+- Est-ce que du code a été modifié ? Non (le Lot 63-bis ne modifie que ce rapport).
+- Est-ce que le rapport Lot 63 a été modifié ? Non.
+- Est-ce qu’une commande Git d’écriture a été utilisée ? Non.
+- Est-ce que le status initial frais du Lot 63 peut être reconstruit ? Non avec certitude à partir des seuls artefacts actuels ; le rapport Lot 63 l’admet.
+- Est-ce que le status actuel est fourni ? Oui (section dédiée, capture avant création du 63-bis).
+- Est-ce que le status final est fourni ? Oui (section « Git status final »).
+- Est-ce que les fichiers modifiés actuels correspondent au Lot 63 ? Oui : deux chemins Dart cohérents avec le save flow prep ; le Lot 63-bis n’y a pas touché.
+- Est-ce que le Lot 63 peut être fermé après ce 63-bis ? Oui, avec la réserve sur la preuve de `git status` initial.
+- Est-ce que le Lot 64 peut démarrer ? Oui du point de vue de ce 63-bis (pas de blocage technique ici).
+
+## Critique du prompt
+
+Exiger un `git status` initial **reconstructible a posteriori** quand la sortie n’a pas été conservée est **impossible** : seuls des instantanés pris à l’époque ou l’équivalent (reflog, bundle, autre outil) pourraient le restituer, ce qui sort du rôle d’un simple correctif 63-bis. Le meilleur diagnostic factuel est : conserver pour l’avenir la procédure « `git status` avant premier edit », et consigner ici l’**absence** de preuve pour le Lot 63.
+
+## Vérification fichiers temporaires (Lot 63-bis)
+
+Commande : `find . -type f \( -name '_gen_*.py' -o -name 'build_*.py' -o -name '*.tmp' \) -print`
+
+Sortie : <vide>
~~~

### Vérification mojibake (rapport 63-bis)

Commande : `grep -E 'RÃ|Ã©|â€|Â' "reports/surface/surface_engine_lot_63_bis_missing_initial_status_clarification.md" || true`

Sortie exacte :

Sortie : <vide> (aucune correspondance parmi les séquences `RÃ`, `Ã©`, `â€`, `Â`).

### Empreinte du fichier livrable (après toutes les sections, dont Evidence Pack)

Un digest SHA-256 du **fichier entier** ne peut figurer de façon cohérente *dans* le fichier : toute insertion de l’empreinte modifie le contenu. La preuve reproductible ci-dessous porte sur le **corps figé** : octets des lignes **1 à 1418** (tout le rapport strictement **avant** le titre de cette section).

**Commande** : `wc -l reports/surface/surface_engine_lot_63_bis_missing_initial_status_clarification.md`

**Commande** : `head -n 1418 reports/surface/surface_engine_lot_63_bis_missing_initial_status_clarification.md | shasum -a 256`

**Sorties exactes** (capturées sur le livrable dont le préfixe de 1418 premières lignes est inchangé) :

```
    1458 reports/surface/surface_engine_lot_63_bis_missing_initial_status_clarification.md
47b734394c2227f9ede20a178dd45678d621b696a2f406b2cdf355e8af3f5f99  -
```

Le second champ du `shasum` vaut `-` lorsque l’entrée provient d’un pipeline (stdin).

### Git status après clôture du rapport 63-bis

**Commande** : `git status --short --untracked-files=all`

**Sortie exacte** :

```
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
 M packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
?? reports/surface/surface_engine_lot_63_bis_missing_initial_status_clarification.md
?? reports/surface/surface_engine_lot_63_surface_studio_save_flow_prep.md
```

**Commande** : `git diff --stat`

**Sortie exacte** :

```
 .../surface_studio/surface_studio_panel.dart       |  65 +++++
 .../surface_studio/surface_studio_panel_test.dart  | 261 +++++++++++++++++++++
 2 files changed, 326 insertions(+)
```

