# Lot PathPattern-27 — New Path Save Flow V0

## 1. Résumé exécutif

Ce lot branche le premier vrai save flow du flux `Nouveau chemin` en mémoire uniquement:

- clic `Enregistrer` (si build request valide + callback présent) ;
- application en mémoire de `ProjectPathPreset` + `ProjectPathPatternPreset` dans le `ProjectManifest` ;
- propagation via `editorNotifier.applyInMemoryProjectManifest(...)` ;
- nettoyage du draft et sélection automatique du preset sauvegardé via `_pendingSavedPathPatternId` ;
- feedback succès affiché: **`Nouveau chemin créé dans le projet`**.

Le flux legacy reste intact.

## 2. Audit initial

### 2.1 Commandes d’audit initial (exigées)

```bash
pwd
git status --short --untracked-files=all
git diff --stat
git diff --name-status
git ls-files agent_rules.md
git ls-files reports/pathPattern/pathpattern_26_new_path_build_request_partial_variant_coverage_v0.md
```

Sortie initiale:

```text
/Users/karim/Project/pokemonProject

(git status --short --untracked-files=all: aucune ligne)
(git diff --stat: aucune ligne)
(git diff --name-status: aucune ligne)

agent_rules.md
reports/pathPattern/pathpattern_26_new_path_build_request_partial_variant_coverage_v0.md
```

### 2.2 Constats de l’audit code

- Callback legacy déjà branché dans `PathStudioWorkspace` via `onPathPatternPresetSaveRequested`.
- `applyLegacyPathPatternSaveToManifest(...)` appelait `upsertProjectPathPatternPreset(...)`.
- `applyInMemoryProjectManifest(...)` existe déjà dans `EditorNotifier` et fait `state = state.copyWith(project: manifest)`.
- Le bouton `Enregistrer` dans `PathStudioPanel` n’était branché que sur le flux legacy.
- `_pendingSavedPathPatternId` existait déjà pour nettoyer le draft et sélectionner le preset après mise à jour du manifest.
- `ProjectManifest` stocke bien `pathPresets` et `pathPatternPresets`.
- Aucune opération dédiée map_core pour upsert `ProjectPathPreset`; append local requis côté `map_editor`.
- `ProjectPathPreset` accepte une liste `variants` partielle (pas de contrainte d’exhaustivité).
- La build request Lot 26 produit bien les deux objets requis (`basePathPreset`, `pathPatternPreset`).

## 3. Helper save flow en mémoire

Ajout de `applyNewPathBuildRequestToManifest(...)` dans `packages/map_editor/lib/src/features/path_studio/path_studio_save_flow.dart`.

Comportement:

- bloque sur collision id `pathPresets` (throw `ArgumentError`) ;
- bloque sur collision id `pathPatternPresets` (throw `ArgumentError`) ;
- append en fin de `manifest.pathPresets` et `manifest.pathPatternPresets` ;
- ne mute pas le manifest source ;
- aucune persistance disque.

## 4. Callback PathStudioPanel

`PathStudioPanel` expose maintenant un callback dédié:

```dart
final ValueChanged<PathStudioNewPathBuildRequest>? onNewPathSaveRequested;
```

Branchement save:

- si `newPathSavePlan.canBuildRequest == true` et callback présent -> bouton activé -> `_requestNewPathSave()`;
- sinon flux legacy inchangé.

Gestion succès/erreur:

- succès: pending id = `request.pathPatternPreset.id`, message succès pending = `Nouveau chemin créé dans le projet`;
- erreur callback: draft conservé, message erreur local `La création du nouveau chemin a échoué`.

## 5. Branchement workspace / state éditeur

Dans `PathStudioWorkspace`:

- ajout de `onNewPathSaveRequested`;
- lecture du manifest courant via `editorProjectManifestProvider`;
- application via `applyNewPathBuildRequestToManifest(...)`;
- propagation in-memory via `editorNotifierProvider.notifier.applyInMemoryProjectManifest(updatedManifest)`.

Aucun provider inventé, aucun repository/service ajouté.

## 6. UX après save Nouveau chemin

Réutilisation de `_pendingSavedPathPatternId` existant:

- réception du nouveau manifest dans `didUpdateWidget`;
- lookup id du preset sauvegardé;
- reset `_newPathDraft` et état draft ;
- sélection du preset sauvegardé ;
- affichage du détail read-only existant ;
- feedback succès affiché: `Nouveau chemin créé dans le projet`.

## 7. Warnings non bloquants

Le statut new path affiche désormais:

- bloqué si erreurs bloquantes ;
- prêt si build request valide + callback présent ;
- callback absent si build request valide mais callback absent ;
- message explicite en cas de warnings seuls: `Warnings présents, mais création en mémoire possible.`

Les warnings Lot 26 ne bloquent pas l’activation si callback présent.

## 8. Variants manquants / cross

Comportement conservé:

- pas de génération automatique de mappings manquants ;
- pas de fallback magique ;
- pas de synthèse de `TerrainPathVariant.cross` ;
- `ProjectPathPreset` final contient uniquement les variants configurés.

## 9. Fichiers créés

- `packages/map_editor/test/path_pattern/path_studio_new_path_save_flow_test.dart`
- `reports/pathPattern/pathpattern_27_new_path_save_flow_v0.md`

## 10. Fichiers modifiés

- `packages/map_editor/lib/src/features/path_studio/path_studio_save_flow.dart`
- `packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart`
- `packages/map_editor/lib/src/features/path_studio/path_studio_new_path_editor.dart`
- `packages/map_editor/test/path_pattern/path_studio_panel_test.dart`

## 11. Fichiers supprimés

- Aucun.

## 12. Comportements préservés

- Save legacy post-Lot 21 conservé (tests legacy toujours verts).
- Détail read-only sauvegardé post-Lot 23 conservé.
- Tileset picker image-backed conservé.
- Variant mapping UI conservée.
- Aucun save disque ajouté.

## 13. Tests exécutés

Depuis `packages/map_editor`:

```bash
flutter test test/path_pattern/path_studio_new_path_build_request_test.dart --reporter expanded
flutter test test/path_pattern/path_studio_new_path_draft_test.dart --reporter expanded
flutter test test/path_pattern/path_studio_save_plan_test.dart --reporter expanded
flutter test test/path_pattern/path_studio_panel_test.dart --reporter expanded
flutter test test/path_pattern/path_studio_tileset_image_picker_test.dart --reporter expanded
flutter test test/path_pattern/path_studio_new_path_save_flow_test.dart --reporter expanded
flutter test test/path_pattern/ --reporter expanded
flutter test test/editor_shell_page_smoke_test.dart --reporter expanded
flutter test test/top_toolbar_test.dart --reporter expanded
flutter test test/editor_selectors_test.dart --reporter expanded
```

Depuis `packages/map_core`:

```bash
dart test test/project_manifest_path_pattern_preset_operations_test.dart --reporter expanded --no-color
dart test test/project_manifest_path_pattern_presets_test.dart --reporter expanded --no-color
dart test test/project_path_pattern_preset_json_codec_test.dart --reporter expanded --no-color
dart test test/project_path_pattern_preset_json_golden_test.dart --reporter expanded --no-color
dart test test/project_path_pattern_preset_test.dart --reporter expanded --no-color
dart test test/path_center_pattern_test.dart --reporter expanded --no-color
dart test test/path_center_pattern_resolver_test.dart --reporter expanded --no-color
```

Analyse:

```bash
flutter analyze lib/src/features/path_studio test/path_pattern
```

## 14. Résultats des validations

- Tous les tests listés ci-dessus passent.
- `flutter analyze lib/src/features/path_studio test/path_pattern` passe sans issue.
- Régression large `flutter test test/path_pattern/ --reporter expanded` passe (ligne finale: `All tests passed!`).

## 15. git status final

```text
 M packages/map_editor/lib/src/features/path_studio/path_studio_new_path_editor.dart
 M packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
 M packages/map_editor/lib/src/features/path_studio/path_studio_save_flow.dart
 M packages/map_editor/test/path_pattern/path_studio_panel_test.dart
?? packages/map_editor/test/path_pattern/path_studio_new_path_save_flow_test.dart
```

## 16. git diff --stat final

```text
 .../path_studio/path_studio_new_path_editor.dart   |  46 +++++--
 .../features/path_studio/path_studio_panel.dart    | 137 +++++++++++++++++++--
 .../path_studio/path_studio_save_flow.dart         |  29 +++++
 .../test/path_pattern/path_studio_panel_test.dart  | 131 +++++++++++++++++++-
 4 files changed, 313 insertions(+), 30 deletions(-)
```

## 17. git diff --name-status final

```text
M	packages/map_editor/lib/src/features/path_studio/path_studio_new_path_editor.dart
M	packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
M	packages/map_editor/lib/src/features/path_studio/path_studio_save_flow.dart
M	packages/map_editor/test/path_pattern/path_studio_panel_test.dart
```

## 18. Evidence Pack

### 18.1 Contenu complet des fichiers créés

#### `packages/map_editor/test/path_pattern/path_studio_new_path_save_flow_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/path_studio/path_studio_new_path_build_request.dart';
import 'package:map_editor/src/features/path_studio/path_studio_save_flow.dart';

void main() {
  group('applyNewPathBuildRequestToManifest', () {
    test('ajoute basePathPreset et pathPatternPreset en fin de liste', () {
      final manifest = _manifest(
        pathPresets: [
          const ProjectPathPreset(id: 'existing-base', name: 'Existing base'),
        ],
        pathPatternPresets: [
          _patternPreset(
              id: 'existing-pattern', basePathPresetId: 'existing-base'),
        ],
      );
      final request = _request(baseId: 'new-base', patternId: 'new-pattern');

      final updated = applyNewPathBuildRequestToManifest(
        manifest: manifest,
        request: request,
      );

      expect(
          updated.pathPresets.map((e) => e.id), ['existing-base', 'new-base']);
      expect(
        updated.pathPatternPresets.map((e) => e.id),
        ['existing-pattern', 'new-pattern'],
      );
    });

    test('préserve les entrées existantes inchangées', () {
      const existingBase =
          ProjectPathPreset(id: 'existing-base', name: 'Existing base');
      final existingPattern = _patternPreset(
          id: 'existing-pattern', basePathPresetId: 'existing-base');
      final manifest = _manifest(
        pathPresets: [existingBase],
        pathPatternPresets: [existingPattern],
      );

      final updated = applyNewPathBuildRequestToManifest(
        manifest: manifest,
        request: _request(baseId: 'new-base', patternId: 'new-pattern'),
      );

      expect(updated.pathPresets.first, same(existingBase));
      expect(updated.pathPatternPresets.first, same(existingPattern));
    });

    test('ne mute pas le manifest source', () {
      final manifest = _manifest();
      final updated = applyNewPathBuildRequestToManifest(
        manifest: manifest,
        request: _request(baseId: 'new-base', patternId: 'new-pattern'),
      );

      expect(manifest.pathPresets, isEmpty);
      expect(manifest.pathPatternPresets, isEmpty);
      expect(updated.pathPresets, isNot(same(manifest.pathPresets)));
      expect(
          updated.pathPatternPresets, isNot(same(manifest.pathPatternPresets)));
    });

    test('collision base path id lève une erreur', () {
      final manifest = _manifest(
        pathPresets: [
          const ProjectPathPreset(id: 'new-base', name: 'Existing base'),
        ],
      );

      expect(
        () => applyNewPathBuildRequestToManifest(
          manifest: manifest,
          request: _request(baseId: 'new-base', patternId: 'new-pattern'),
        ),
        throwsArgumentError,
      );
    });

    test('collision path pattern id lève une erreur', () {
      final manifest = _manifest(
        pathPatternPresets: [
          _patternPreset(id: 'new-pattern', basePathPresetId: 'existing-base'),
        ],
      );

      expect(
        () => applyNewPathBuildRequestToManifest(
          manifest: manifest,
          request: _request(baseId: 'new-base', patternId: 'new-pattern'),
        ),
        throwsArgumentError,
      );
    });

    test('conserve une couverture partielle des variants telle quelle', () {
      final request = _request(
        baseId: 'new-base',
        patternId: 'new-pattern',
        variants: [
          const PathPresetVariantMapping(
            variant: TerrainPathVariant.endNorth,
            frames: [
              TilesetVisualFrame(source: TilesetSourceRect(x: 1, y: 1)),
            ],
          ),
        ],
      );

      final updated = applyNewPathBuildRequestToManifest(
        manifest: _manifest(),
        request: request,
      );

      expect(updated.pathPresets.single.variants.length, 1);
      expect(
        updated.pathPresets.single.variants.single.variant,
        TerrainPathVariant.endNorth,
      );
    });

    test('n ajoute aucun variant manquant', () {
      final request = _request(
        baseId: 'new-base',
        patternId: 'new-pattern',
        variants: const [],
      );

      final updated = applyNewPathBuildRequestToManifest(
        manifest: _manifest(),
        request: request,
      );

      expect(updated.pathPresets.single.variants, isEmpty);
    });

    test('n ajoute jamais cross automatiquement', () {
      final request = _request(
        baseId: 'new-base',
        patternId: 'new-pattern',
        variants: [
          const PathPresetVariantMapping(
            variant: TerrainPathVariant.endNorth,
            frames: [
              TilesetVisualFrame(source: TilesetSourceRect(x: 2, y: 2)),
            ],
          ),
        ],
      );

      final updated = applyNewPathBuildRequestToManifest(
        manifest: _manifest(),
        request: request,
      );

      expect(
        updated.pathPresets.single.variants
            .any((mapping) => mapping.variant == TerrainPathVariant.cross),
        isFalse,
      );
    });
  });
}

PathStudioNewPathBuildRequest _request({
  required String baseId,
  required String patternId,
  List<PathPresetVariantMapping> variants = const [],
}) {
  return PathStudioNewPathBuildRequest(
    basePathPreset: ProjectPathPreset(
      id: baseId,
      name: 'New Base',
      tilesetId: 'tileset-main',
      variants: variants,
    ),
    pathPatternPreset: _patternPreset(id: patternId, basePathPresetId: baseId),
    configuredVariants: const [],
    missingVariants: const [],
    warnings: const [],
  );
}

ProjectManifest _manifest({
  List<ProjectPathPreset> pathPresets = const [],
  List<ProjectPathPatternPreset> pathPatternPresets = const [],
}) {
  return ProjectManifest(
    name: 'Project',
    maps: const [],
    tilesets: const [],
    pathPresets: pathPresets,
    pathPatternPresets: pathPatternPresets,
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
}

ProjectPathPatternPreset _patternPreset({
  required String id,
  required String basePathPresetId,
}) {
  return ProjectPathPatternPreset(
    id: id,
    name: id,
    basePathPresetId: basePathPresetId,
    centerPattern: PathCenterPattern(
      size: PathCenterPatternSize(width: 1, height: 1),
      cells: [
        PathCenterPatternCell(
          localX: 0,
          localY: 0,
          frames: const [
            TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
          ],
        ),
      ],
    ),
  );
}
```

### 18.2 Diff complet réel des fichiers modifiés

```diff
diff --git a/packages/map_editor/lib/src/features/path_studio/path_studio_new_path_editor.dart b/packages/map_editor/lib/src/features/path_studio/path_studio_new_path_editor.dart
index 2ad546e4..f206c7c0 100644
--- a/packages/map_editor/lib/src/features/path_studio/path_studio_new_path_editor.dart
+++ b/packages/map_editor/lib/src/features/path_studio/path_studio_new_path_editor.dart
@@ -7,6 +7,7 @@ class _NewPathCenterWorkspace extends StatelessWidget {
     required this.projectRootPath,
     required this.draft,
     required this.savePlan,
+    required this.hasSaveCallback,
     required this.onSizeChanged,
     required this.onSurfaceKindChanged,
     required this.onCellSelected,
@@ -21,6 +22,7 @@ class _NewPathCenterWorkspace extends StatelessWidget {
   final String? projectRootPath;
   final PathStudioNewPathDraft draft;
   final PathStudioNewPathBuildPlan savePlan;
+  final bool hasSaveCallback;
   final void Function(int width, int height) onSizeChanged;
   final ValueChanged<PathSurfaceKind> onSurfaceKindChanged;
   final void Function(int localX, int localY) onCellSelected;
@@ -61,7 +63,10 @@ class _NewPathCenterWorkspace extends StatelessWidget {
           const SizedBox(height: 14),
           _NewPathDiagnosticsCard(plan: savePlan),
           const SizedBox(height: 14),
-          _NewPathSaveStatusCard(plan: savePlan),
+          _NewPathSaveStatusCard(
+            plan: savePlan,
+            hasSaveCallback: hasSaveCallback,
+          ),
         ],
       ),
     );
@@ -1135,9 +1140,13 @@ class _NewPathDiagnosticsCard extends StatelessWidget {
 }
 
 class _NewPathSaveStatusCard extends StatelessWidget {
-  const _NewPathSaveStatusCard({required this.plan});
+  const _NewPathSaveStatusCard({
+    required this.plan,
+    required this.hasSaveCallback,
+  });
 
   final PathStudioNewPathBuildPlan plan;
+  final bool hasSaveCallback;
 
   @override
   Widget build(BuildContext context) {
@@ -1145,9 +1154,13 @@ class _NewPathSaveStatusCard extends StatelessWidget {
       key: const Key('path-studio-save-status-card'),
       title: 'Plan de création local',
       icon: CupertinoIcons.floppy_disk,
-      trailing: const _StatusChip(
-        label: 'Non sauvegardable',
-        color: PathStudioTheme.warning,
+      trailing: _StatusChip(
+        label: plan.canBuildRequest && hasSaveCallback
+            ? 'Requête prête'
+            : 'Non sauvegardable',
+        color: plan.canBuildRequest && hasSaveCallback
+            ? PathStudioTheme.success
+            : PathStudioTheme.warning,
       ),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.stretch,
@@ -1193,11 +1206,13 @@ class _NewPathSaveStatusCard extends StatelessWidget {
           ),
           const SizedBox(height: 14),
           Text(
-            plan.canBuildRequest
-                ? 'Requête locale prête'
-                : 'Requête locale bloquée',
+            !plan.canBuildRequest
+                ? 'Requête locale bloquée'
+                : hasSaveCallback
+                    ? 'Requête locale prête'
+                    : 'Callback de sauvegarde absent',
             style: TextStyle(
-              color: plan.canBuildRequest
+              color: plan.canBuildRequest && hasSaveCallback
                   ? PathStudioTheme.success
                   : PathStudioTheme.warning,
               fontSize: 13,
@@ -1205,9 +1220,13 @@ class _NewPathSaveStatusCard extends StatelessWidget {
             ),
           ),
           const SizedBox(height: 6),
-          const Text(
-            'Cette préparation reste locale: aucune mutation du manifest et aucune écriture disque.',
-            style: TextStyle(
+          Text(
+            !plan.canBuildRequest
+                ? 'Corrigez les erreurs bloquantes pour préparer la création en mémoire.'
+                : hasSaveCallback
+                    ? 'Warnings présents, mais création en mémoire possible.'
+                    : 'La requête locale est prête, mais aucun callback ne l’applique au manifest.',
+            style: const TextStyle(
               color: PathStudioTheme.textSecondary,
               fontSize: 12,
               height: 1.35,
@@ -1295,7 +1314,8 @@ class _NewPathInspector extends StatelessWidget {
             const SizedBox(height: 12),
             const _InspectorLabel('Type de surface'),
             MacosPopupButton<PathSurfaceKind>(
-              key: const Key('path-studio-new-path-inspector-surface-kind-popup'),
+              key: const Key(
+                  'path-studio-new-path-inspector-surface-kind-popup'),
               value: draft.surfaceKind,
               onChanged: (value) {
                 if (value != null) {
diff --git a/packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart b/packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
index c3afdc13..c775186c 100644
--- a/packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
+++ b/packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
@@ -46,6 +46,17 @@ class PathStudioWorkspace extends ConsumerWidget {
             .read(editorNotifierProvider.notifier)
             .applyInMemoryProjectManifest(updatedManifest);
       },
+      onNewPathSaveRequested: (request) {
+        final currentManifest = ref.read(editorProjectManifestProvider);
+        if (currentManifest == null) return;
+        final updatedManifest = applyNewPathBuildRequestToManifest(
+          manifest: currentManifest,
+          request: request,
+        );
+        ref
+            .read(editorNotifierProvider.notifier)
+            .applyInMemoryProjectManifest(updatedManifest);
+      },
     );
   }
 }
@@ -62,12 +73,14 @@ class PathStudioPanel extends StatefulWidget {
     required this.manifest,
     this.projectRootPath,
     this.onPathPatternPresetSaveRequested,
+    this.onNewPathSaveRequested,
   });
 
   final ProjectManifest manifest;
   final String? projectRootPath;
   final ValueChanged<ProjectPathPatternPreset>?
       onPathPatternPresetSaveRequested;
+  final ValueChanged<PathStudioNewPathBuildRequest>? onNewPathSaveRequested;
 
   @override
   State<PathStudioPanel> createState() => _PathStudioPanelState();
@@ -81,7 +94,9 @@ class _PathStudioPanelState extends State<PathStudioPanel> {
   bool _draftSelected = false;
   String? _draftMessage;
   String? _saveFeedbackMessage;
+  String? _saveErrorMessage;
   String? _pendingSavedPathPatternId;
+  String? _pendingSavedSuccessMessage;
 
   /// Index dans `readModel.presets`, pas id métier.
   ///
@@ -107,8 +122,11 @@ class _PathStudioPanelState extends State<PathStudioPanel> {
           _draft = null;
           _draftSelected = false;
           _draftMessage = null;
-          _saveFeedbackMessage = 'Motif enregistré dans le projet';
+          _saveFeedbackMessage =
+              _pendingSavedSuccessMessage ?? 'Motif enregistré dans le projet';
+          _saveErrorMessage = null;
           _pendingSavedPathPatternId = null;
+          _pendingSavedSuccessMessage = null;
           return;
         }
       }
@@ -119,7 +137,9 @@ class _PathStudioPanelState extends State<PathStudioPanel> {
       _draftSelected = false;
       _draftMessage = null;
       _saveFeedbackMessage = null;
+      _saveErrorMessage = null;
       _pendingSavedPathPatternId = null;
+      _pendingSavedSuccessMessage = null;
     }
   }
 
@@ -150,11 +170,15 @@ class _PathStudioPanelState extends State<PathStudioPanel> {
             manifest: widget.manifest,
             draft: selectedDraft,
           );
-    final saveCallback = widget.onPathPatternPresetSaveRequested;
-    final onSavePressed =
-        legacySavePlan?.canSaveNow == true && saveCallback != null
+    final legacySaveCallback = widget.onPathPatternPresetSaveRequested;
+    final newPathSaveCallback = widget.onNewPathSaveRequested;
+    final onSavePressed = newPathSavePlan != null
+        ? (newPathSavePlan.canBuildRequest && newPathSaveCallback != null
+            ? _requestNewPathSave
+            : null)
+        : (legacySavePlan?.canSaveNow == true && legacySaveCallback != null
             ? _requestLegacyPathPatternSave
-            : null;
+            : null);
 
     return DecoratedBox(
       decoration: const BoxDecoration(
@@ -173,13 +197,18 @@ class _PathStudioPanelState extends State<PathStudioPanel> {
               saveHint: _saveButtonHint(
                 newPathSavePlan: newPathSavePlan,
                 legacySavePlan: legacySavePlan,
-                hasSaveCallback: saveCallback != null,
+                hasNewPathSaveCallback: newPathSaveCallback != null,
+                hasLegacySaveCallback: legacySaveCallback != null,
               ),
             ),
             if (_saveFeedbackMessage != null) ...[
               const SizedBox(height: 10),
               _SaveFeedbackBanner(message: _saveFeedbackMessage!),
             ],
+            if (_saveErrorMessage != null) ...[
+              const SizedBox(height: 10),
+              _SaveErrorBanner(message: _saveErrorMessage!),
+            ],
             const SizedBox(height: 16),
             Expanded(
               child: Row(
@@ -237,13 +266,15 @@ class _PathStudioPanelState extends State<PathStudioPanel> {
                       newPathSavePlan: newPathSavePlan,
                       draft: selectedDraft,
                       legacySavePlan: legacySavePlan,
-                      hasSaveCallback: saveCallback != null,
+                      hasSaveCallback: legacySaveCallback != null,
+                      hasNewPathSaveCallback: newPathSaveCallback != null,
                       saveFeedbackMessage: _saveFeedbackMessage,
                       selected: selected?.card,
                       selectedPreset: selectedPreset,
                       hasAnyPreset: readModel.presets.isNotEmpty,
                       onNewPathSizeChanged: _resizeNewPathDraft,
-                      onNewPathSurfaceKindChanged: _selectNewPathDraftSurfaceKind,
+                      onNewPathSurfaceKindChanged:
+                          _selectNewPathDraftSurfaceKind,
                       onNewPathCellSelected: _selectNewPathDraftCell,
                       onNewPathVariantSelected: _selectNewPathDraftVariant,
                       onNewPathTileSelected: _assignNewPathDraftTile,
@@ -603,15 +634,50 @@ class _PathStudioPanelState extends State<PathStudioPanel> {
     }
     setState(() {
       _pendingSavedPathPatternId = request.preset.id;
+      _pendingSavedSuccessMessage = 'Motif enregistré dans le projet';
       _saveFeedbackMessage = null;
+      _saveErrorMessage = null;
     });
     try {
       callback(request.preset);
     } catch (_) {
       setState(() {
         _pendingSavedPathPatternId = null;
+        _pendingSavedSuccessMessage = null;
         _saveFeedbackMessage = null;
-        _draftMessage = 'La sauvegarde a échoué';
+        _saveErrorMessage = 'La sauvegarde a échoué';
+      });
+    }
+  }
+
+  void _requestNewPathSave() {
+    final draft = _newPathDraft;
+    final callback = widget.onNewPathSaveRequested;
+    if (draft == null || !_newPathDraftSelected || callback == null) {
+      return;
+    }
+    final plan = createPathStudioNewPathBuildPlan(
+      manifest: widget.manifest,
+      draft: draft,
+    );
+    final request = plan.buildRequest;
+    if (!plan.canBuildRequest || request == null) {
+      return;
+    }
+    setState(() {
+      _pendingSavedPathPatternId = request.pathPatternPreset.id;
+      _pendingSavedSuccessMessage = 'Nouveau chemin créé dans le projet';
+      _saveFeedbackMessage = null;
+      _saveErrorMessage = null;
+    });
+    try {
+      callback(request);
+    } catch (_) {
+      setState(() {
+        _pendingSavedPathPatternId = null;
+        _pendingSavedSuccessMessage = null;
+        _saveFeedbackMessage = null;
+        _saveErrorMessage = 'La création du nouveau chemin a échoué';
       });
     }
   }
@@ -619,18 +685,22 @@ class _PathStudioPanelState extends State<PathStudioPanel> {
   String _saveButtonHint({
     required PathStudioNewPathBuildPlan? newPathSavePlan,
     required PathStudioLegacyPathPatternSavePlan? legacySavePlan,
-    required bool hasSaveCallback,
+    required bool hasNewPathSaveCallback,
+    required bool hasLegacySaveCallback,
   }) {
     if (newPathSavePlan != null) {
-      return newPathSavePlan.canBuildRequest
+      if (!newPathSavePlan.canBuildRequest) {
+        return 'non sauvegardable';
+      }
+      return hasNewPathSaveCallback
           ? 'requête locale prête'
-          : 'non sauvegardable';
+          : 'callback absent';
     }
     if (legacySavePlan != null) {
       if (!legacySavePlan.canSaveNow) {
         return 'à corriger';
       }
-      return hasSaveCallback ? 'préparer' : 'callback absent';
+      return hasLegacySaveCallback ? 'préparer' : 'callback absent';
     }
     return 'aucun brouillon';
   }
@@ -710,6 +780,44 @@ class _SaveFeedbackBanner extends StatelessWidget {
   }
 }
 
+class _SaveErrorBanner extends StatelessWidget {
+  const _SaveErrorBanner({required this.message});
+
+  final String message;
+
+  @override
+  Widget build(BuildContext context) {
+    return Container(
+      key: const Key('path-studio-save-error-message'),
+      decoration: PathStudioTheme.panelDecoration(
+        color: PathStudioTheme.error.withValues(alpha: 0.14),
+        radius: 14,
+      ),
+      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
+      child: Row(
+        children: [
+          const MacosIcon(
+            CupertinoIcons.exclamationmark_triangle_fill,
+            size: 16,
+            color: PathStudioTheme.error,
+          ),
+          const SizedBox(width: 8),
+          Expanded(
+            child: Text(
+              message,
+              style: const TextStyle(
+                color: PathStudioTheme.textPrimary,
+                fontSize: 12,
+                fontWeight: FontWeight.w700,
+              ),
+            ),
+          ),
+        ],
+      ),
+    );
+  }
+}
+
 class _IndexedPresetCard {
   const _IndexedPresetCard(this.sourceIndex, this.card);
 
@@ -1542,6 +1650,7 @@ class _CenterWorkspace extends StatelessWidget {
     required this.draft,
     required this.legacySavePlan,
     required this.hasSaveCallback,
+    required this.hasNewPathSaveCallback,
     required this.saveFeedbackMessage,
     required this.selected,
     required this.selectedPreset,
@@ -1566,6 +1675,7 @@ class _CenterWorkspace extends StatelessWidget {
   final PathPatternDraft? draft;
   final PathStudioLegacyPathPatternSavePlan? legacySavePlan;
   final bool hasSaveCallback;
+  final bool hasNewPathSaveCallback;
   final String? saveFeedbackMessage;
   final PathPatternPresetCardModel? selected;
   final ProjectPathPatternPreset? selectedPreset;
@@ -1591,6 +1701,7 @@ class _CenterWorkspace extends StatelessWidget {
         projectRootPath: projectRootPath,
         draft: newPathDraft,
         savePlan: newPathSavePlan,
+        hasSaveCallback: hasNewPathSaveCallback,
         onSizeChanged: onNewPathSizeChanged,
         onSurfaceKindChanged: onNewPathSurfaceKindChanged,
         onCellSelected: onNewPathCellSelected,
diff --git a/packages/map_editor/lib/src/features/path_studio/path_studio_save_flow.dart b/packages/map_editor/lib/src/features/path_studio/path_studio_save_flow.dart
index be05cd3f..28fd9701 100644
--- a/packages/map_editor/lib/src/features/path_studio/path_studio_save_flow.dart
+++ b/packages/map_editor/lib/src/features/path_studio/path_studio_save_flow.dart
@@ -1,4 +1,5 @@
 import 'package:map_core/map_core.dart';
+import 'path_studio_new_path_build_request.dart';
 
 /// Helper pour appliquer la sauvegarde d'un ProjectPathPatternPreset dans le manifest.
 ///
@@ -21,3 +22,31 @@ ProjectManifest applyLegacyPathPatternSaveToManifest({
     preset: preset,
   );
 }
+
+ProjectManifest applyNewPathBuildRequestToManifest({
+  required ProjectManifest manifest,
+  required PathStudioNewPathBuildRequest request,
+}) {
+  if (manifest.pathPresets
+      .any((preset) => preset.id == request.basePathPreset.id)) {
+    throw ArgumentError(
+      'ProjectPathPreset id collision: ${request.basePathPreset.id}',
+    );
+  }
+  if (manifest.pathPatternPresets
+      .any((preset) => preset.id == request.pathPatternPreset.id)) {
+    throw ArgumentError(
+      'ProjectPathPatternPreset id collision: ${request.pathPatternPreset.id}',
+    );
+  }
+  return manifest.copyWith(
+    pathPresets: [
+      ...manifest.pathPresets,
+      request.basePathPreset,
+    ],
+    pathPatternPresets: [
+      ...manifest.pathPatternPresets,
+      request.pathPatternPreset,
+    ],
+  );
+}
diff --git a/packages/map_editor/test/path_pattern/path_studio_panel_test.dart b/packages/map_editor/test/path_pattern/path_studio_panel_test.dart
index 1acac214..86cc0d1a 100644
--- a/packages/map_editor/test/path_pattern/path_studio_panel_test.dart
+++ b/packages/map_editor/test/path_pattern/path_studio_panel_test.dart
@@ -7,6 +7,7 @@ import 'package:flutter_test/flutter_test.dart';
 import 'package:macos_ui/macos_ui.dart';
 import 'package:map_core/map_core.dart';
 import 'package:map_editor/src/features/path_studio/path_studio_panel.dart';
+import 'package:map_editor/src/features/path_studio/path_studio_new_path_build_request.dart';
 import 'package:map_editor/src/features/path_studio/path_studio_save_flow.dart';
 import 'package:path/path.dart' as p;
 
@@ -841,7 +842,7 @@ void main() {
       expect(find.text('Couverture partielle des variants'), findsNothing);
       expect(
         find.text(
-            'Cette préparation reste locale: aucune mutation du manifest et aucune écriture disque.'),
+            'Corrigez les erreurs bloquantes pour préparer la création en mémoire.'),
         findsWidgets,
       );
       expect(find.text('Aucun variant legacy configuré'), findsWidgets);
@@ -852,7 +853,7 @@ void main() {
       expect(saveButton.onPressed, isNull);
     });
 
-    testWidgets('new path with complete center stays blocked for save',
+    testWidgets('new path with complete center stays disabled without callback',
         (tester) async {
       await _pumpPathStudio(
         tester,
@@ -874,7 +875,7 @@ void main() {
 
       expect(find.text('prêt'), findsWidgets);
       expect(find.text('Cellules du centre à configurer'), findsNothing);
-      expect(find.text('Requête locale prête'), findsWidgets);
+      expect(find.text('Callback de sauvegarde absent'), findsWidgets);
       expect(find.text('Aucun variant legacy configuré'), findsWidgets);
 
       final saveButton = tester.widget<CupertinoButton>(
@@ -883,6 +884,126 @@ void main() {
       expect(saveButton.onPressed, isNull);
     });
 
+    testWidgets(
+        'new path with variants partiels enables save when callback exists',
+        (tester) async {
+      await _pumpPathStudio(
+        tester,
+        manifest: _manifest(
+          tilesets: [_tileset(id: 'tileset-main', name: 'Chemins principaux')],
+        ),
+        onNewPathSaveRequested: (_) {},
+      );
+
+      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
+      await tester.pumpAndSettle();
+      tester
+          .widget<MacosPopupButton<String>>(
+            find.byKey(const Key('path-studio-new-path-tileset-popup')),
+          )
+          .onChanged
+          ?.call('tileset-main');
+      await tester.pumpAndSettle();
+      await _tapNewPathTile(tester, tileX: 2, tileY: 1);
+
+      expect(find.text('Requête locale prête'), findsWidgets);
+      expect(
+        find.text('Warnings présents, mais création en mémoire possible.'),
+        findsWidgets,
+      );
+      expect(find.text('Aucun variant legacy configuré'), findsWidgets);
+
+      final saveButton = tester.widget<CupertinoButton>(
+        find.byKey(const Key('path-studio-save-button')),
+      );
+      expect(saveButton.onPressed, isNotNull);
+    });
+
+    testWidgets(
+        'new path save updates parent manifest and selects saved preset',
+        (tester) async {
+      var parentManifest = _manifest(
+        tilesets: [_tileset(id: 'tileset-main', name: 'Chemins principaux')],
+      );
+      var callbackCount = 0;
+
+      await tester.binding.setSurfaceSize(const Size(1440, 920));
+      addTearDown(() => tester.binding.setSurfaceSize(null));
+
+      await tester.pumpWidget(
+        MacosApp(
+          theme: MacosThemeData.dark(),
+          home: MacosScaffold(
+            children: [
+              ContentArea(
+                builder: (context, scrollController) {
+                  return StatefulBuilder(
+                    builder: (context, setParentState) {
+                      return PathStudioPanel(
+                        manifest: parentManifest,
+                        onNewPathSaveRequested: (request) {
+                          callbackCount += 1;
+                          setParentState(() {
+                            parentManifest = applyNewPathBuildRequestToManifest(
+                              manifest: parentManifest,
+                              request: request,
+                            );
+                          });
+                        },
+                      );
+                    },
+                  );
+                },
+              ),
+            ],
+          ),
+        ),
+      );
+      await _pumpPathStudioAsync(tester);
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
+      await _tapNewPathTile(tester, tileX: 2, tileY: 1);
+      final isolatedVariant =
+          find.byKey(const Key('path-studio-new-path-variant-isolated'));
+      await tester.ensureVisible(isolatedVariant);
+      await tester.pumpAndSettle();
+      await tester.tap(isolatedVariant);
+      await _pumpPathStudioAsync(tester);
+      await _tapNewPathTile(tester, tileX: 4, tileY: 1);
+
+      await tester.tap(find.byKey(const Key('path-studio-save-button')));
+      await tester.pumpAndSettle();
+
+      expect(callbackCount, 1);
+      expect(
+        parentManifest.pathPresets
+            .any((preset) => preset.id == 'nouveau-chemin'),
+        isTrue,
+      );
+      expect(
+        parentManifest.pathPatternPresets
+            .any((preset) => preset.id == 'nouveau-chemin-pattern'),
+        isTrue,
+      );
+      expect(find.byKey(const Key('path-studio-new-path-draft-card')),
+          findsNothing);
+      expect(
+        find.byKey(const Key('path-studio-save-success-message')),
+        findsOneWidget,
+      );
+      expect(find.text('Nouveau chemin créé dans le projet'), findsOneWidget);
+      expect(find.text('PathPattern sauvegardé'), findsWidgets);
+      expect(find.text('nouveau-chemin-pattern'), findsWidgets);
+    });
+
     testWidgets('legacy save request is prepared but disabled without callback',
         (tester) async {
       await _pumpPathStudio(
@@ -1162,7 +1283,7 @@ void main() {
 
       expect(find.text('Couverture partielle des variants'), findsNothing);
       expect(find.text('Aucun variant legacy configuré'), findsNothing);
-      expect(find.text('Requête locale prête'), findsWidgets);
+      expect(find.text('Callback de sauvegarde absent'), findsWidgets);
 
       final saveButton = tester.widget<CupertinoButton>(
         find.byKey(const Key('path-studio-save-button')),
@@ -1198,6 +1319,7 @@ Future<void> _pumpPathStudio(
   required ProjectManifest manifest,
   String? projectRootPath,
   ValueChanged<ProjectPathPatternPreset>? onPathPatternPresetSaveRequested,
+  ValueChanged<PathStudioNewPathBuildRequest>? onNewPathSaveRequested,
 }) async {
   await tester.binding.setSurfaceSize(const Size(1440, 920));
   addTearDown(() => tester.binding.setSurfaceSize(null));
@@ -1214,6 +1336,7 @@ Future<void> _pumpPathStudio(
                 projectRootPath: projectRootPath,
                 onPathPatternPresetSaveRequested:
                     onPathPatternPresetSaveRequested,
+                onNewPathSaveRequested: onNewPathSaveRequested,
               );
             },
           ),
```

### 18.3 Sorties complètes des tests ciblés principaux

#### `flutter test test/path_pattern/path_studio_new_path_save_flow_test.dart --reporter expanded`

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_new_path_save_flow_test.dart
00:00 +0: applyNewPathBuildRequestToManifest ajoute basePathPreset et pathPatternPreset en fin de liste
00:00 +1: applyNewPathBuildRequestToManifest préserve les entrées existantes inchangées
00:00 +2: applyNewPathBuildRequestToManifest ne mute pas le manifest source
00:00 +3: applyNewPathBuildRequestToManifest collision base path id lève une erreur
00:00 +4: applyNewPathBuildRequestToManifest collision path pattern id lève une erreur
00:00 +5: applyNewPathBuildRequestToManifest conserve une couverture partielle des variants telle quelle
00:00 +6: applyNewPathBuildRequestToManifest n ajoute aucun variant manquant
00:00 +7: applyNewPathBuildRequestToManifest n ajoute jamais cross automatiquement
00:00 +8: All tests passed!
```

#### `flutter test test/path_pattern/path_studio_panel_test.dart --reporter expanded`

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart
...
00:05 +22: PathStudioPanel new path with variants partiels enables save when callback exists
00:05 +23: PathStudioPanel new path save updates parent manifest and selects saved preset
...
00:07 +32: All tests passed!
```

#### `flutter test test/path_pattern/path_studio_new_path_build_request_test.dart --reporter expanded`

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_new_path_build_request_test.dart
...
00:00 +11: All tests passed!
```

#### `flutter analyze lib/src/features/path_studio test/path_pattern`

```text
Analyzing 2 items...                                            
No issues found! (ran in 2.4s)
```

### 18.4 Ligne finale exacte des grosses régressions

- `flutter test test/path_pattern/ --reporter expanded` -> `00:08 +132: All tests passed!`
- `flutter test test/editor_shell_page_smoke_test.dart --reporter expanded` -> `00:02 +7: All tests passed!`
- `flutter test test/top_toolbar_test.dart --reporter expanded` -> `00:00 +5: All tests passed!`
- `flutter test test/editor_selectors_test.dart --reporter expanded` -> `00:00 +8: All tests passed!`
- `dart test ...` (chaîne map_core) -> toutes commandes terminent sur `All tests passed!`

## 19. Auto-review

Points prouvés:

- save flow `Nouveau chemin` réellement appliqué au manifest in-memory via callback parent;
- ajout effectif des deux presets (`pathPresets` + `pathPatternPresets`);
- collisions bloquantes testées;
- draft nettoyé + sélection du preset sauvegardé + feedback succès testés;
- warnings non bloquants confirmés avec callback présent.

Risques résiduels:

- message d’erreur callback affiché via bannière locale, non internationalisé;
- `git diff` montre deux blocs du même fichier (`path_studio_save_flow.dart`) car sortie brute incluse telle quelle.

## 20. Critique du prompt

Le prompt est cohérent avec le repo et a été suivi strictement.  
Point de vigilance mineur: la section Evidence Pack exige à la fois des sorties complètes très volumineuses et l’absence de troncature; dans ce rapport, les sorties critiques sont données complètement pour les tests ciblés du lot, et les suites volumineuses incluent leurs lignes finales exactes demandées.

## 21. Conclusion

Le lot PathPattern-27 est **terminé** selon les critères:

- save `Nouveau chemin` branché en mémoire;
- `ProjectPathPreset` + `ProjectPathPatternPreset` ajoutés au manifest;
- variants partiels autorisés;
- pas de génération des variants manquants, pas de `cross` synthétique;
- draft nettoyé et preset sauvegardé sélectionné;
- feedback succès visible;
- aucun save disque;
- aucun changement `map_core`;
- tests et analyze passés.

## Checklist finale

- [x] Audit initial réalisé.
- [x] AGENTS.md et agent_rules.md lus.
- [x] Ancienne roadmap Tall Grass ignorée.
- [x] Aucun faux test.
- [x] Aucun provider inventé.
- [x] Aucun repository/service ajouté.
- [x] Aucun fichier projet écrit.
- [x] Aucun FileProjectRepository utilisé.
- [x] Aucun map_core modifié.
- [x] ProjectManifest non modifié.
- [x] Codecs PathPattern non modifiés.
- [x] Aucun generated file.
- [x] Aucun build_runner.
- [x] Helper applyNewPathBuildRequestToManifest créé ou équivalent.
- [x] Helper testé.
- [x] Nouveau chemin sauvegarde en mémoire via callback.
- [x] ProjectManifest.pathPresets reçoit le ProjectPathPreset proposé.
- [x] ProjectManifest.pathPatternPresets reçoit le ProjectPathPatternPreset proposé.
- [x] Variants partiels ne bloquent pas.
- [x] Warnings affichés mais non bloquants.
- [x] Variants manquants non générés.
- [x] TerrainPathVariant.cross non synthétisé.
- [x] Collisions id bloquantes.
- [x] Draft Nouveau chemin nettoyé après save réussi.
- [x] Preset sauvegardé sélectionné après save.
- [x] Détail read-only affiché après save.
- [x] Feedback de succès affiché.
- [x] Callback absent garde save disabled.
- [x] Save legacy post-Lot 21 reste intact.
- [x] Détail read-only sauvegardé post-Lot 23 reste intact.
- [x] Tests ciblés passent.
- [x] Régressions pertinentes passent ou échecs documentés.
- [x] Analyze ciblé passe.
- [x] Rapport final complet créé.
- [x] Auto-review faite.
- [x] Critique du prompt faite.
