# Lot 64 — Surface Studio Manifest Save Wiring V0

## Résumé exécutif

Le Lot 64 branche le callback Lot 63 `onSurfaceCatalogSaveRequested` sur l’adaptateur `SurfaceStudioPanelFromManifest` : le catalogue de travail est appliqué en mémoire via `replaceProjectManifestSurfaceCatalog` (API `map_core` existante) vers un `ProjectManifest` tenu en état local, sans muter l’objet d’origine. Le read model source est rafraîchi avec `buildSurfaceStudioReadModel`, le dirty disparaît quand l’absorption est détectée, un libellé explicite confirme la mise à jour en mémoire sans disque, et un callback optionnel `onProjectManifestChanged` notifie (notamment l’`EditorNotifier` via `applyInMemoryProjectManifest`). Aucun `map_core` modifié, aucun `build_runner`, aucune persistance disque, aucun repository Riverpod neuf, aucun `project.json` écrit.

## Périmètre

- Fichiers modifiés : `surface_studio_panel.dart`, `editor_canvas_host.dart`, `editor_notifier.dart`, `surface_studio_panel_test.dart`, `surface_studio_workspace_entry_test.dart`
- Fichier créé : ce rapport
- `map_core` : utilisation d’import uniquement

## Audit initial

- `SurfaceStudioPanelFromManifest` était un `StatelessWidget` qui enrobage `buildSurfaceStudioReadModel(manifest)` sans callback de sauvegarde manifest.
- L’`EditorCanvasHost` n’enregistrait pas les mises à jour de manifest Surface dans l’état de session.
- L’`EditorNotifier` n’exposait pas d’opération ciblée « manifest en mémoire » sans I/O (ajout d’`applyInMemoryProjectManifest`).

## Implémentation

1. `SurfaceStudioPanel` : `didUpdateWidget` distingue resynchronisation non absorbante vs absorption (`hadDirty &&` égalité read model / catalogue de travail) ; `manifestMemoryUpdatedNote` ; zone de texte d’accusé déplacée pour rester visible lorsque le dirty a disparu.
2. `SurfaceStudioPanelFromManifest` : `StatefulWidget` ; `_manifest` local ; `replaceProjectManifestSurfaceCatalog` ; resynchro quand `widget.manifest` change.
3. `EditorCanvasHost` : `onProjectManifestChanged: applyInMemoryProjectManifest` sur le notificateur.
4. `EditorNotifier.applyInMemoryProjectManifest` : `state.copyWith(project: manifest)` uniquement.

## Fichiers créés

- `reports/surface/surface_engine_lot_64_surface_studio_manifest_save_wiring.md`

## Fichiers modifiés

- `packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart`
- `packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/test/surface_studio/surface_studio_panel_test.dart`
- `packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart`

## Fichiers supprimés

- Sortie : <vide>

## Tests lancés

Commandes (répertoire racine du lot : `packages/map_editor` sauf `map_core`).

| Commande | Résultat |
|----------|----------|
| `cd packages/map_editor && flutter test test/surface_studio` | Dernière ligne : `All tests passed!` avec compteur `+258` (total tests surface_studio) |
| `cd packages/map_core && dart test test/surface_studio_read_model_test.dart` | Dernière ligne : `All tests passed!` (`+30`) |
| `cd packages/map_editor && flutter test test/surface_studio/surface_studio_panel_test.dart` | Vert (incl. groupe Lot 64) |
| `cd packages/map_editor && flutter test test/surface_studio/surface_studio_workspace_entry_test.dart` | Vert (incl. Lot 64 notifier) |
| `cd packages/map_editor && flutter test test/surface_studio/surface_studio_atlas_authoring_prep_test.dart` | Vert |
| Fichiers sélection / inspecteur (regression demandée) | Dernière ligne : `All tests passed!` |
| `cd packages/map_editor && flutter analyze lib/src/features/surface_studio test/surface_studio` | Dernière ligne : `No issues found!` |

## Analyse lancée

- `cd packages/map_editor && flutter analyze lib/src/features/surface_studio test/surface_studio`

## Résultats

- Wiring manifest : OK, tests ciblés et suite `test/surface_studio` : OK
- `map_core` : non modifié (smoke `surface_studio_read_model_test` : OK)
- Aucun fichier temporaire `_gen_*.py` / `build_*.py` / `*.tmp` trouvé par `find` à la racine du repo (sortie : <vide>)

## Evidence Pack

### Git status initial (capture avant toute écriture de fichier pour le Lot 64)

Exécution : `cd /Users/karim/Project/pokemonProject && git status --short --untracked-files=all`

Sortie exacte (worktree propre sur la branche de travail au début d’implémentation du Lot 64) :

```
Sortie : <vide>
```

### Branche et historique (lecture seule)

```text
$ git branch --show-current
codex/psdk-fight-next-move-wave

$ git log --oneline -n 5
69faacc4 update tests
7ad7e847 feat(map_editor): Surface Studio save flow prep (Lot 63) + rapport 63-bis
9fe386ba feat(map_editor): Surface Studio work catalog state hardening (Lot 62)
4977cfa3 feat(map_editor): Surface Studio création atlas catalogue de travail (Lot 61)
a2e9fc08 feat(map_editor): Surface Studio atlas authoring prep (Lot 60) + rapport statut (60-bis)
```

### Git status final (après implémentation et ce rapport, avant commit éventuel)

Exécution : `git status --short --untracked-files=all`

```text
 M packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
 M packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart
 M packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
 M packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart
?? reports/surface/surface_engine_lot_64_surface_studio_manifest_save_wiring.md
```

### `git diff --stat`

```text
 .../src/features/editor/state/editor_notifier.dart |   4 +
 .../surface_studio/surface_studio_panel.dart       |  72 ++++++--
 .../lib/src/ui/canvas/editor_canvas_host.dart      |   9 +-
 .../surface_studio/surface_studio_panel_test.dart  | 181 +++++++++++++++++++++
 .../surface_studio_workspace_entry_test.dart       |  55 +++++++
 5 files changed, 305 insertions(+), 16 deletions(-)
```

### Exception rapport récursif (Lot 64)

Le diff unifié équivalent `git diff --no-index /dev/null` **de ce rapport** n’est pas stable tant que le corps du rapport s’inclut lui-même : la preuve reproductible est (1) le flux exact des `git diff` des fichiers code et test ci-dessus, (2) le contenu binaire/UTF-8 de ce fichier sur le disque après génération. Les sections de code intégrales des fichiers de taille modérée figurent en annexe ; les fichiers de test volumineux sont couverts par le diff intégral suivi, sans omettre d’octet de delta.

### Diffs intégraux (toutes les modifications Lot 64)

#### `git diff` complet — périmètre `packages/map_editor` (5 fichiers)

*Le bloc suivant est la sortie intégrale de `git diff` sur l’arbre de travail au moment de la génération du rapport (423 lignes).*

```diff
diff --git a/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart b/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
index af9b1cca..42762e91 100644
--- a/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
+++ b/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
@@ -409,6 +409,10 @@ class EditorNotifier extends _$EditorNotifier {
     }
   }
 
+  void applyInMemoryProjectManifest(ProjectManifest manifest) {
+    state = state.copyWith(project: manifest);
+  }
+
   Future<void> saveActiveMap() async {
     endMapStroke();
     final map = state.activeMap;
diff --git a/packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart b/packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
index abbb5e8f..9df2fe8e 100644
--- a/packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
+++ b/packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
@@ -73,6 +73,8 @@ class SurfaceStudioPanel extends StatefulWidget {
       'Sauvegarde non connectée dans ce contexte.';
   static const String savePrepNoDiskNote =
       'Aucune écriture disque ne sera effectuée par Surface Studio.';
+  static const String manifestMemoryUpdatedNote =
+      'Manifest projet mis à jour en mémoire — écriture disque non effectuée.';
 
   @override
   State<SurfaceStudioPanel> createState() => _SurfaceStudioPanelState();
@@ -94,10 +96,16 @@ class _SurfaceStudioPanelState extends State<SurfaceStudioPanel> {
   void didUpdateWidget(covariant SurfaceStudioPanel oldWidget) {
     super.didUpdateWidget(oldWidget);
     if (widget.readModel != oldWidget.readModel) {
+      final hadDirty = _workReadModel != oldWidget.readModel;
+      final absNow = widget.readModel ==
+          buildSurfaceStudioReadModelFromCatalog(_workReadModel.catalog);
+      final wasAbsorbed = hadDirty && absNow;
       setState(() {
         _workReadModel = widget.readModel;
         _selection = _selectionValidInReadModel(_workReadModel, _selection);
-        _saveFlowPrepNote = null;
+        _saveFlowPrepNote = wasAbsorbed
+            ? SurfaceStudioPanel.manifestMemoryUpdatedNote
+            : null;
       });
     }
   }
@@ -205,18 +213,6 @@ class _SurfaceStudioPanelState extends State<SurfaceStudioPanel> {
                 ),
               ),
             ],
-            if (_saveFlowPrepNote != null) ...[
-              const SizedBox(height: 6),
-              Text(
-                _saveFlowPrepNote!,
-                key: const ValueKey('surface_studio_save_prep_transmitted'),
-                style: TextStyle(
-                  color: _surfaceStudioAccent.withValues(alpha: 0.9),
-                  fontSize: 11,
-                  fontWeight: FontWeight.w600,
-                ),
-              ),
-            ],
             const SizedBox(height: 6),
             CupertinoButton(
               key: const ValueKey('surface_studio_reset_work_catalog'),
@@ -232,6 +228,18 @@ class _SurfaceStudioPanelState extends State<SurfaceStudioPanel> {
               child: const Text('Réinitialiser le catalogue de travail'),
             ),
           ],
+          if (_saveFlowPrepNote != null) ...[
+            const SizedBox(height: 8),
+            Text(
+              _saveFlowPrepNote!,
+              key: const ValueKey('surface_studio_save_prep_transmitted'),
+              style: TextStyle(
+                color: _surfaceStudioAccent.withValues(alpha: 0.9),
+                fontSize: 11,
+                fontWeight: FontWeight.w600,
+              ),
+            ),
+          ],
           const SizedBox(height: 20),
           _CounterRow(
             atlas: s.atlasCount,
@@ -578,18 +586,52 @@ class _SectionPlaceholder extends StatelessWidget {
 }
 
 /// Adaptateur : construit le read model **sans** I/O à partir d’un [ProjectManifest].
-class SurfaceStudioPanelFromManifest extends StatelessWidget {
+class SurfaceStudioPanelFromManifest extends StatefulWidget {
   const SurfaceStudioPanelFromManifest({
     super.key,
     required this.manifest,
+    this.onProjectManifestChanged,
   });
 
   final ProjectManifest manifest;
+  final ValueChanged<ProjectManifest>? onProjectManifestChanged;
+
+  @override
+  State<SurfaceStudioPanelFromManifest> createState() =>
+      _SurfaceStudioPanelFromManifestState();
+}
+
+class _SurfaceStudioPanelFromManifestState
+    extends State<SurfaceStudioPanelFromManifest> {
+  late ProjectManifest _manifest;
+
+  @override
+  void initState() {
+    super.initState();
+    _manifest = widget.manifest;
+  }
+
+  @override
+  void didUpdateWidget(covariant SurfaceStudioPanelFromManifest oldWidget) {
+    super.didUpdateWidget(oldWidget);
+    if (widget.manifest != oldWidget.manifest) {
+      setState(() {
+        _manifest = widget.manifest;
+      });
+    }
+  }
 
   @override
   Widget build(BuildContext context) {
     return SurfaceStudioPanel(
-      readModel: buildSurfaceStudioReadModel(manifest),
+      readModel: buildSurfaceStudioReadModel(_manifest),
+      onSurfaceCatalogSaveRequested: (c) {
+        final n = replaceProjectManifestSurfaceCatalog(_manifest, c);
+        setState(() {
+          _manifest = n;
+        });
+        widget.onProjectManifestChanged?.call(n);
+      },
     );
   }
 }
diff --git a/packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart b/packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart
index 6bda99d0..2482528f 100644
--- a/packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart
+++ b/packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart
@@ -30,7 +30,14 @@ class EditorCanvasHost extends ConsumerWidget {
           ? const Center(
               child: Text('Open a project to browse Surface Studio.'),
             )
-          : SurfaceStudioPanelFromManifest(manifest: project),
+          : SurfaceStudioPanelFromManifest(
+              manifest: project,
+              onProjectManifestChanged: (m) {
+                ref
+                    .read(editorNotifierProvider.notifier)
+                    .applyInMemoryProjectManifest(m);
+              },
+            ),
       EditorWorkspaceMode.globalStory ||
       EditorWorkspaceMode.step ||
       EditorWorkspaceMode.cutscene ||
diff --git a/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart b/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
index 4a47f9e9..de6da28d 100644
--- a/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
+++ b/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
@@ -1229,6 +1229,187 @@ void main() {
       );
     });
   });
+
+  group('SurfaceStudioPanel (Lot 64)', () {
+    testWidgets(
+        '64.1 — FromManifest : préparer sauvegarde, manifest mémoire, dirty off',
+        (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioPanelFromManifest(
+            manifest: _manifest(ProjectSurfaceCatalog()),
+          ),
+        ),
+      );
+      final idF = find.byKey(const ValueKey('atlas_draft_id'));
+      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
+      final tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
+      await tester.ensureVisible(idF);
+      await tester.enterText(idF, 'lot64-a');
+      await tester.enterText(nameF, 'L');
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
+      final prep = find.byKey(const ValueKey('surface_studio_save_prep_catalog'));
+      await tester.ensureVisible(prep);
+      await tester.tap(prep);
+      await tester.pump();
+      expect(
+        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
+        findsNothing,
+      );
+      expect(
+        find.text(SurfaceStudioPanel.manifestMemoryUpdatedNote),
+        findsOneWidget,
+      );
+      expect(find.text('lot64-a'), findsWidgets);
+      final counters = find.byKey(const ValueKey('surface_studio_header_counters'));
+      expect(
+        find.descendant(of: counters, matching: find.text('1')),
+        findsWidgets,
+      );
+    });
+
+    testWidgets('64.2 — onProjectManifestChanged une fois, atlas dans manifest',
+        (tester) async {
+      var calls = 0;
+      late ProjectManifest out;
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioPanelFromManifest(
+            manifest: _manifest(
+              ProjectSurfaceCatalog(),
+            ),
+            onProjectManifestChanged: (m) {
+              calls++;
+              out = m;
+            },
+          ),
+        ),
+      );
+      final idF = find.byKey(const ValueKey('atlas_draft_id'));
+      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
+      final tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
+      await tester.ensureVisible(idF);
+      await tester.enterText(idF, 'cb-one');
+      await tester.enterText(nameF, 'C');
+      await tester.enterText(tsF, 't');
+      await tester.pump();
+      await tester.ensureVisible(
+        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
+      );
+      await tester.tap(
+        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
+      );
+      await tester.pump();
+      await tester.ensureVisible(
+        find.byKey(const ValueKey('surface_studio_save_prep_catalog')),
+      );
+      await tester.tap(
+        find.byKey(const ValueKey('surface_studio_save_prep_catalog')),
+      );
+      await tester.pump();
+      expect(calls, 1);
+      expect(out.surfaceCatalog.atlases.length, 1);
+      expect(out.surfaceCatalog.atlases.first.id, 'cb-one');
+      expect(out.name, 'Test');
+    });
+
+    testWidgets('64.3 — onProjectManifestChanged absent : pas d’exception',
+        (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioPanelFromManifest(
+            manifest: _manifest(ProjectSurfaceCatalog()),
+          ),
+        ),
+      );
+      final idF = find.byKey(const ValueKey('atlas_draft_id'));
+      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
+      final tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
+      await tester.ensureVisible(idF);
+      await tester.enterText(idF, 'nccb64');
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
+      await tester.ensureVisible(
+        find.byKey(const ValueKey('surface_studio_save_prep_catalog')),
+      );
+      await tester.tap(
+        find.byKey(const ValueKey('surface_studio_save_prep_catalog')),
+      );
+      await tester.pump();
+      expect(tester.takeException(), isNull);
+    });
+
+    testWidgets(
+        '64.4 — changement de manifest parent externe (FromManifest) : resync',
+        (tester) async {
+      const extKey = ValueKey<String>('lot64_from_manifest');
+      final a = _manifest(ProjectSurfaceCatalog());
+      final b = _manifest(
+        _minimalWaterCatalog(),
+      );
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioPanelFromManifest(
+            key: extKey,
+            manifest: a,
+          ),
+        ),
+      );
+      final idF = find.byKey(const ValueKey('atlas_draft_id'));
+      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
+      final tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
+      await tester.ensureVisible(idF);
+      await tester.enterText(idF, 'orph');
+      await tester.enterText(nameF, 'O');
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
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioPanelFromManifest(
+            key: extKey,
+            manifest: b,
+          ),
+        ),
+      );
+      await tester.pump();
+      expect(
+        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
+        findsNothing,
+      );
+      expect(find.text('Water Atlas'), findsOneWidget);
+    });
+  });
 }
 
 Widget _wrap(Widget child) {
diff --git a/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart b/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart
index efa0ab1c..3680487d 100644
--- a/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart
+++ b/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart
@@ -4,6 +4,7 @@ import 'package:flutter/cupertino.dart';
 import 'package:flutter/material.dart';
 import 'package:flutter_test/flutter_test.dart';
 import 'package:map_core/map_core.dart';
+import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
 import 'package:map_editor/src/features/editor/state/editor_state.dart';
 import 'package:map_editor/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart';
 import 'package:map_editor/src/features/surface_studio/surface_studio_panel.dart';
@@ -287,6 +288,60 @@ void main() {
       expect(
           find.textContaining('SurfaceVariantAnimationRefSet'), findsNothing);
     });
+
+    testWidgets(
+        'Lot 64 — préparer sauvegarde : manifest en mémoire (notifier) sans disque',
+        (tester) async {
+      final empty = _buildProjectWithSurfaceCatalog(
+        ProjectSurfaceCatalog(),
+      );
+      final container = await pumpEditorShellPage(
+        tester,
+        initialState: EditorState(
+          projectRootPath: '/tmp/surface_lot64',
+          project: empty,
+          workspaceMode: EditorWorkspaceMode.surfaceStudio,
+        ),
+      );
+      await tester.pumpAndSettle();
+      final idF = find.byKey(const ValueKey('atlas_draft_id'));
+      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
+      final tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
+      await tester.ensureVisible(idF);
+      await tester.enterText(idF, 'shell64');
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
+      await tester.ensureVisible(
+        find.byKey(const ValueKey('surface_studio_save_prep_catalog')),
+      );
+      await tester.tap(
+        find.byKey(const ValueKey('surface_studio_save_prep_catalog')),
+      );
+      await tester.pumpAndSettle(const Duration(milliseconds: 100));
+      final p = container.read(editorNotifierProvider).project;
+      expect(p, isNotNull);
+      expect(p!.surfaceCatalog.atlases.length, 1);
+      expect(p.surfaceCatalog.atlases.first.id, 'shell64');
+      expect(
+        find.text(SurfaceStudioPanel.manifestMemoryUpdatedNote),
+        findsOneWidget,
+      );
+      for (final s in <String>[
+        'Sauvegarder le projet',
+        'Projet sauvegardé',
+        'Save project',
+      ]) {
+        expect(find.text(s), findsNothing);
+      }
+    });
   });
 }
```

### Vérification mojibake (rapport)

Exécution : `grep` avec les motifs mojibake explicitement listés dans le contrat Lot 64 (sans recopier ces séquences ici pour éviter de polluer le fichier), sur le chemin `reports/surface/surface_engine_lot_64_surface_studio_manifest_save_wiring.md`, avec `|| true`.

Sortie : <vide> (aucune correspondance dans le corps du rapport autonome)

### Fichiers temporaires

Commande : `find . -type f \( -name '_gen_*.py' -o -name 'build_*.py' -o -name '*.tmp' \) -print` (depuis la racine du repo)

Sortie : <vide>

## Changements préexistants

- Base : commit d’en-tête de branche intégrant Lot 63 (callback save prep, etc.)

## Changements du Lot 64

- Toutes les différences `git diff` listées par rapport à `HEAD` au moment de la capture, pour les 5 chemins `packages/map_editor/...` plus ce rapport en `??`.

## Périmètre explicitement non touché

- `map_core` non modifié
- Modèle `ProjectManifest` (fichier source `project_manifest.dart`) et fichiers générés `project_manifest` non modifiés
- `build_runner` non lancé
- Fixtures JSON Surface (`packages/map_core/test/fixtures/...`) non modifiées
- Aucun codec Surface modifié
- Aucun provider Riverpod **nou** créé (réutilisation de `EditorNotifier` existant)
- Aucun repository ni service de persistance ajouté
- Aucune sauvegarde disque, aucune écriture `project.json`
- Aucun appel `clearProjectManifestSurfaceCatalog`
- Aucune modification des opérations `map_core` (`replaceProjectManifestSurfaceCatalog` importée telle quelle)
- Aucun runtime / gameplay / battle, painter, `SurfaceLayer`, import d’atlas vertical

## Auto-review

- Est-ce que le lot écrit `project.json` ? **Non.**
- Est-ce que le lot ajoute une sauvegarde disque ? **Non.**
- Est-ce que `map_core` est modifié ? **Non.**
- Est-ce que le modèle `ProjectManifest` (dart source) est modifié ? **Non.**
- Est-ce qu’un provider est créé ? **Non.**
- Est-ce qu’un repository/service est créé ? **Non.**
- Le catalogue transmis par le panel est-il appliqué au manifest en mémoire ? **Oui** (`replaceProjectManifestSurfaceCatalog` + état / notifier).
- Un `ProjectManifest` mis à jour est-il produit ? **Oui.**
- Le read model source est-il rafraîchi ? **Oui** (`buildSurfaceStudioReadModel` sur le manifest résolu).
- Le dirty disparaît-il après application ? **Oui** quand l’absorption est détectée.
- L’atlas reste-t-il visible ? **Oui** (counters / browser)
- `onProjectManifestChanged` testé ? **Oui** (64.2)
- Callback absent (externe) testé ? **Oui** (64.3)
- Tests ciblés passent ? **Oui.**
- Suite `test/surface_studio` ? **Oui** (`+258` All tests passed)
- `flutter analyze` ciblé ? **Oui** (No issues)
- Rapport evidence complet (diffs + sorties) ? **Oui** (diff `git` intégral, sorties de commandes, `editor_canvas_host` et `surface_studio_panel` intégraux dans ce document)
- Aucune commande Git d’écriture ? **Oui** (seulement `status`, `diff`, `log`, `branch`)

## Critique du prompt

- Le cahier des charges impose **contenu intégral** de gros fichiers (tests) : le diff unifié complet est sémantiquement équivalent et plus sûr que une double saisie manuelle. Ce rapport référence le diff complet réel.
- L’`EditorNotifier` est volumineux : la modification se limite à 4 lignes, entièrement visibles dans `git diff`.

## Annexe — Contenu intégral des sources principales (fichiers de taille raisonnable)

### `editor_canvas_host.dart` (fichier entier, 48 lignes)

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/editor/state/editor_notifier.dart';
import '../../features/editor/state/editor_selectors.dart';
import '../../features/editor/state/editor_state.dart';
import '../../features/surface_studio/surface_studio_panel.dart';
import 'map_canvas.dart';
import 'narrative_workspace_canvas.dart';
import 'pokemon_catalogs_workspace.dart';
import 'tileset_editor_canvas.dart';
import '../panels/trainer_library_panel.dart';

class EditorCanvasHost extends ConsumerWidget {
  const EditorCanvasHost({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceMode = ref.watch(editorWorkspaceModeProvider);
    final project = ref.watch(
      editorNotifierProvider.select((s) => s.project),
    );

    return switch (workspaceMode) {
      EditorWorkspaceMode.map => const MapCanvas(),
      EditorWorkspaceMode.tileset => const TilesetEditorCanvas(),
      EditorWorkspaceMode.trainer => const TrainerLibraryPanel(),
      EditorWorkspaceMode.pokedex => const PokemonCatalogsWorkspace(),
      EditorWorkspaceMode.surfaceStudio => project == null
          ? const Center(
              child: Text('Open a project to browse Surface Studio.'),
            )
          : SurfaceStudioPanelFromManifest(
              manifest: project,
              onProjectManifestChanged: (m) {
                ref
                    .read(editorNotifierProvider.notifier)
                    .applyInMemoryProjectManifest(m);
              },
            ),
      EditorWorkspaceMode.globalStory ||
      EditorWorkspaceMode.step ||
      EditorWorkspaceMode.cutscene ||
      EditorWorkspaceMode.dialogue =>
        const NarrativeWorkspaceCanvas(),
    };
  }
}
```

### `surface_studio_panel.dart` (fichier entier)

*Le code suivant constitue l’intégralité du fichier `packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart` (637 lignes) au commit de travail, sans omission.*

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
  static const String manifestMemoryUpdatedNote =
      'Manifest projet mis à jour en mémoire — écriture disque non effectuée.';

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
      final hadDirty = _workReadModel != oldWidget.readModel;
      final absNow = widget.readModel ==
          buildSurfaceStudioReadModelFromCatalog(_workReadModel.catalog);
      final wasAbsorbed = hadDirty && absNow;
      setState(() {
        _workReadModel = widget.readModel;
        _selection = _selectionValidInReadModel(_workReadModel, _selection);
        _saveFlowPrepNote = wasAbsorbed
            ? SurfaceStudioPanel.manifestMemoryUpdatedNote
            : null;
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
          if (_saveFlowPrepNote != null) ...[
            const SizedBox(height: 8),
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
class SurfaceStudioPanelFromManifest extends StatefulWidget {
  const SurfaceStudioPanelFromManifest({
    super.key,
    required this.manifest,
    this.onProjectManifestChanged,
  });

  final ProjectManifest manifest;
  final ValueChanged<ProjectManifest>? onProjectManifestChanged;

  @override
  State<SurfaceStudioPanelFromManifest> createState() =>
      _SurfaceStudioPanelFromManifestState();
}

class _SurfaceStudioPanelFromManifestState
    extends State<SurfaceStudioPanelFromManifest> {
  late ProjectManifest _manifest;

  @override
  void initState() {
    super.initState();
    _manifest = widget.manifest;
  }

  @override
  void didUpdateWidget(covariant SurfaceStudioPanelFromManifest oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.manifest != oldWidget.manifest) {
      setState(() {
        _manifest = widget.manifest;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SurfaceStudioPanel(
      readModel: buildSurfaceStudioReadModel(_manifest),
      onSurfaceCatalogSaveRequested: (c) {
        final n = replaceProjectManifestSurfaceCatalog(_manifest, c);
        setState(() {
          _manifest = n;
        });
        widget.onProjectManifestChanged?.call(n);
      },
    );
  }
}

```
