# Lot PathPattern-14 — PathPattern Draft Editor State V0

Date: 2026-04-30

Verdict: implémenté et vérifié. Path Studio permet maintenant de créer un brouillon local non sauvegardé, de modifier son nom, de changer sa base legacy, de basculer son centre entre 1×1 et 2×2, de sélectionner une cellule, et de voir inspector/diagnostics se mettre à jour. Aucune persistance manifest n’a été ajoutée.

## 1. Résumé exécutif

Ce lot transforme le shell read-only du Lot 13 en première interaction locale: le bouton `Nouveau preset` crée un `PathPatternDraft` en mémoire seulement. Le draft est initialisé depuis le premier `ProjectPathPreset` legacy disponible, via le centre legacy `TerrainPathVariant.cross`. Les boutons `Dupliquer` et `Enregistrer` restent désactivés. Le manifest n’est jamais muté.

## 2. Audit initial

```text
$ pwd
/Users/karim/Project/pokemonProject
$ git status --short
(aucune sortie)
$ git diff --stat
(aucune sortie)
$ git diff --name-status
(aucune sortie)
```

Context Mode utilisé.
Stats au moment du rapport:
1.7M tokens saved · 82.4% reduction · 26h 38m
v1.0.103

Un seul `AGENTS.md` a été trouvé: `./AGENTS.md`. Aucun `AGENTS.md` plus profond.

## 3. État initial du repo

Le worktree était propre au début du lot. Lot 13 était déjà intégré dans le baseline local: `path_studio_panel.dart`, `path_studio_theme.dart`, le mode `pathStudio`, l’entrée Project Explorer et les tests Lot 13 existaient déjà.

## 4. Fichiers inspectés

- `packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart`

- `packages/map_editor/lib/src/features/path_studio/path_pattern_editor_read_model.dart`

- `packages/map_editor/lib/src/features/path_studio/path_studio_theme.dart`

- `packages/map_core/lib/src/operations/project_path_preset_center_pattern_adapter.dart`

- `packages/map_core/lib/src/models/path_center_pattern.dart`

- `packages/map_core/lib/src/models/project_manifest.dart`

- `packages/map_editor/test/path_pattern/path_studio_panel_test.dart`

- `packages/map_editor/test/path_pattern/path_pattern_editor_read_model_test.dart`

## 5. Stratégie retenue

Stratégie: ajouter un modèle local `PathPatternDraft` côté `map_editor`, puis brancher le panneau existant en deux modes: preset existant read-only et draft local éditable. Le draft n’est pas un modèle persistant et ne vit pas dans `map_core`. La sélection de draft est séparée de la sélection de preset existant pour ne pas brouiller les ids dupliqués déjà diagnostiqués par le read model.

Le centre initial et les reconstructions 1×1/2×2 utilisent `createLegacyProjectPathPresetCenterPatternView` avec `TerrainPathVariant.cross`. Chaque cellule du draft reçoit les frames du centre cross, conformément au V0 sans tile picker.

## 6. Fichiers créés

- `packages/map_editor/lib/src/features/path_studio/path_pattern_draft.dart`

- `packages/map_editor/test/path_pattern/path_pattern_draft_test.dart`

## 7. Fichiers modifiés

- `packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart`

- `packages/map_editor/test/path_pattern/path_studio_panel_test.dart`

## 8. Fichiers supprimés

Aucun.

## 9. Fonctionnement du draft local

- `createInitialPathPatternDraftFromManifest`: retourne `null` si aucun `ProjectPathPreset` legacy n’existe.

- `createInitialPathPatternDraft`: crée `draft-path-pattern`, nom `Nouveau motif de chemin`, base = premier legacy, centre 1×1 depuis `cross`, dirty = true.

- `resizePathPatternDraftCenter`: reconstruit 1×1 ou 2×2 depuis les frames cross de la base courante.

- `changePathPatternDraftBase`: conserve le nom et la taille, change la base et reconstruit les cellules depuis le nouveau cross.

- `renamePathPatternDraft`: modifie seulement le nom local.

- `selectPathPatternDraftCell`: sélection locale validée par `PathCenterPattern.cellAt`.

- Issue locale V0: `nameRequired` si `name.trim().isEmpty`.

## 10. Fonctionnement UI

- `Nouveau preset`: activé; crée un brouillon local ou affiche `Aucun preset Path de base disponible`.

- Sidebar: affiche le draft en haut avec badge `Brouillon` et état `Non sauvegardé`.

- Zone centrale: affiche bannière brouillon, résumé, segmented control 1×1/2×2, grille A/B/C/D, détails de cellule sélectionnée, diagnostics locaux.

- Inspector: passe à `Propriétés du brouillon`, champ nom, popup base legacy, contrôle taille, métriques et état `Brouillon non sauvegardé`.

- `Dupliquer` et `Enregistrer`: restent sans `onPressed`.

## 11. Comportements volontairement non faits

- Pas de sauvegarde dans `ProjectManifest.pathPatternPresets`.

- Pas de mutation réelle du manifest.

- Pas de save flow, repository, service de persistance.

- Pas de modification `map_core`, `ProjectManifest`, codecs ou generated files.

- Pas de drag & drop, tile picker, frame picker, preview PNG réelle ou animée.

- Pas de painter/canvas/runtime/gameplay/battle/tall grass/Surface Studio/TSX/TMX/Mistral/PixelLab/MCP.

## 12. Tests exécutés

### 12.1 TDD RED

```text
Commande RED: cd packages/map_editor && flutter test test/path_pattern/path_pattern_draft_test.dart test/path_pattern/path_studio_panel_test.dart
Résultat attendu: échec avant implémentation.
Lignes importantes exactes:
test/path_pattern/path_pattern_draft_test.dart:3:8: Error: Error when reading 'lib/src/features/path_studio/path_pattern_draft.dart': No such file or directory
Expected: not null
  Actual: <null>
The finder "Found 0 widgets with key [<'path-studio-draft-size-2x2'>]: []" (used in a call to "tap()") could not find any matching widgets.
Expected: at least one matching candidate
  Actual: _TextWidgetFinder:<Found 0 widgets with text "Aucun preset Path de base disponible": []>
00:04 +3 -5: Some tests failed.
```

### 12.2 Tests ciblés unit + widget

```text
cd packages/map_editor && flutter test test/path_pattern/path_pattern_draft_test.dart && flutter test test/path_pattern/path_studio_panel_test.dart
```

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_draft_test.dart
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_draft_test.dart
00:01 +0: PathPatternDraft creates an initial draft from the legacy cross center
00:01 +1: PathPatternDraft creates an initial draft from the legacy cross center
00:01 +1: PathPatternDraft returns null when a manifest has no legacy base path preset
00:01 +2: PathPatternDraft returns null when a manifest has no legacy base path preset
00:01 +2: PathPatternDraft resizes a 1x1 draft to a 2x2 center with copied cross frames
00:01 +3: PathPatternDraft resizes a 1x1 draft to a 2x2 center with copied cross frames
00:01 +3: PathPatternDraft resizes a 2x2 draft back to a valid 1x1 center
00:01 +4: PathPatternDraft resizes a 2x2 draft back to a valid 1x1 center
00:01 +4: PathPatternDraft changes base while preserving name and current size
00:01 +5: PathPatternDraft changes base while preserving name and current size
00:01 +5: PathPatternDraft empty draft name exposes a local nameRequired issue
00:01 +6: PathPatternDraft empty draft name exposes a local nameRequired issue
00:01 +6: All tests passed!

00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart
00:02 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart
00:02 +0: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:02 +1: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:02 +1: PathStudioPanel lists presets and updates summary and inspector selection
00:03 +1: PathStudioPanel lists presets and updates summary and inspector selection
00:03 +2: PathStudioPanel lists presets and updates summary and inspector selection
00:03 +2: PathStudioPanel filters presets locally and clears selection on no result
00:03 +3: PathStudioPanel filters presets locally and clears selection on no result
00:03 +3: PathStudioPanel creates a local draft from Nouveau preset
00:03 +4: PathStudioPanel creates a local draft from Nouveau preset
00:03 +4: PathStudioPanel resizes the local draft to 2x2 and selects a cell
00:03 +5: PathStudioPanel resizes the local draft to 2x2 and selects a cell
00:03 +5: PathStudioPanel edits draft name and keeps save disabled
00:03 +6: PathStudioPanel edits draft name and keeps save disabled
00:03 +6: PathStudioPanel changes draft base locally without saving
00:03 +7: PathStudioPanel changes draft base locally without saving
00:03 +7: PathStudioPanel empty draft name shows a local diagnostic
00:03 +8: PathStudioPanel empty draft name shows a local diagnostic
00:03 +8: PathStudioPanel does not create a draft without legacy base path presets
00:04 +8: PathStudioPanel does not create a draft without legacy base path presets
00:04 +9: PathStudioPanel does not create a draft without legacy base path presets
00:04 +9: All tests passed!
```

### 12.3 Régressions PathPattern editor

```text
Commande: cd packages/map_editor && flutter test test/path_pattern/
Ligne finale exacte: 00:03 +52: All tests passed!
Sortie complète disponible dans la session d'exécution; le résultat couvre les tests PathPattern editor, preview statique/animée, transparent color, read model, draft et panel.
```

### 12.4 Régressions shell

```text
Commande: cd packages/map_editor && flutter test test/editor_shell_page_smoke_test.dart test/top_toolbar_test.dart test/editor_selectors_test.dart
Ligne finale exacte: 00:06 +20: All tests passed!
Note: la sortie contient deux warnings macos_ui connus sur la résolution lente de couleur accent et un log FileProjectRepository existant; exit code 0.
```

## 13. Analyze exécuté

```text
Commande: cd packages/map_editor && flutter analyze lib/src/features/path_studio test/path_pattern
Sortie exacte:
Analyzing 2 items...

No issues found! (ran in 2.4s)
```

## 14. Régressions map_core

```text
Commande: cd packages/map_core && dart test test/project_manifest_path_pattern_preset_operations_test.dart test/project_manifest_path_pattern_presets_test.dart test/project_path_pattern_preset_json_codec_test.dart test/project_path_pattern_preset_json_golden_test.dart test/project_path_pattern_preset_test.dart test/path_center_pattern_test.dart test/path_center_pattern_resolver_test.dart
Ligne finale exacte: 00:00 +65: All tests passed!
```

## 15. git status final

```text
 M packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
 M packages/map_editor/test/path_pattern/path_studio_panel_test.dart
?? packages/map_editor/lib/src/features/path_studio/path_pattern_draft.dart
?? packages/map_editor/test/path_pattern/path_pattern_draft_test.dart
?? reports/pathPattern/pathpattern_14_draft_editor_state_v0.md
```

## 16. git diff --stat

```text
 .../features/path_studio/path_studio_panel.dart    | 888 ++++++++++++++++++++-
 .../test/path_pattern/path_studio_panel_test.dart  | 149 +++-
 2 files changed, 1016 insertions(+), 21 deletions(-)
```

## 17. git diff --name-status

```text
M	packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
M	packages/map_editor/test/path_pattern/path_studio_panel_test.dart
```

## 18. Evidence Pack

### 18.1 Diff complet réel des fichiers suivis

```text
diff --git a/packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart b/packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
index a2b00e1b..7e29b6d8 100644
--- a/packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
+++ b/packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
@@ -4,6 +4,7 @@ import 'package:macos_ui/macos_ui.dart';
 import 'package:map_core/map_core.dart';
 
 import '../editor/state/editor_selectors.dart';
+import 'path_pattern_draft.dart';
 import 'path_pattern_editor_read_model.dart';
 import 'path_studio_theme.dart';
 
@@ -45,6 +46,9 @@ class PathStudioPanel extends StatefulWidget {
 
 class _PathStudioPanelState extends State<PathStudioPanel> {
   String _searchQuery = '';
+  PathPatternDraft? _draft;
+  bool _draftSelected = false;
+  String? _draftMessage;
 
   /// Index dans `readModel.presets`, pas id métier.
   ///
@@ -58,6 +62,9 @@ class _PathStudioPanelState extends State<PathStudioPanel> {
     super.didUpdateWidget(oldWidget);
     if (oldWidget.manifest != widget.manifest) {
       _selectedSourceIndex = null;
+      _draft = null;
+      _draftSelected = false;
+      _draftMessage = null;
     }
   }
 
@@ -68,7 +75,8 @@ class _PathStudioPanelState extends State<PathStudioPanel> {
     );
     final query = _searchQuery.trim().toLowerCase();
     final filtered = _filteredCards(readModel, query);
-    final selected = _selectedCard(filtered);
+    final selected = _draftSelected ? null : _selectedCard(filtered);
+    final selectedDraft = _draftSelected ? _draft : null;
 
     return DecoratedBox(
       decoration: const BoxDecoration(
@@ -81,6 +89,7 @@ class _PathStudioPanelState extends State<PathStudioPanel> {
           children: [
             _PathStudioHeader(
               summary: readModel.summary,
+              onCreateDraft: _createDraft,
             ),
             const SizedBox(height: 16),
             Expanded(
@@ -92,26 +101,48 @@ class _PathStudioPanelState extends State<PathStudioPanel> {
                     child: _PresetSidebar(
                       readModel: readModel,
                       filteredCards: filtered,
+                      draft: _draft,
+                      draftSelected: _draftSelected,
+                      draftMatchesQuery: _draft == null ||
+                          query.isEmpty ||
+                          _matchesDraftQuery(_draft!, query),
+                      draftMessage: _draftMessage,
                       selectedSourceIndex: selected?.sourceIndex,
                       onQueryChanged: (value) {
                         setState(() => _searchQuery = value);
                       },
+                      onSelectDraft: () {
+                        setState(() => _draftSelected = true);
+                      },
                       onSelect: (sourceIndex) {
-                        setState(() => _selectedSourceIndex = sourceIndex);
+                        setState(() {
+                          _draftSelected = false;
+                          _selectedSourceIndex = sourceIndex;
+                        });
                       },
                     ),
                   ),
                   const SizedBox(width: 16),
                   Expanded(
                     child: _CenterWorkspace(
+                      draft: selectedDraft,
                       selected: selected?.card,
                       hasAnyPreset: readModel.presets.isNotEmpty,
+                      onDraftSizeChanged: _resizeDraft,
+                      onDraftCellSelected: _selectDraftCell,
                     ),
                   ),
                   const SizedBox(width: 16),
                   SizedBox(
                     width: 326,
-                    child: _PresetInspector(selected: selected?.card),
+                    child: _PresetInspector(
+                      manifest: widget.manifest,
+                      draft: selectedDraft,
+                      selected: selected?.card,
+                      onDraftNameChanged: _renameDraft,
+                      onDraftBaseChanged: _changeDraftBase,
+                      onDraftSizeChanged: _resizeDraft,
+                    ),
                   ),
                 ],
               ),
@@ -150,6 +181,16 @@ class _PathStudioPanelState extends State<PathStudioPanel> {
         .any((field) => field.toLowerCase().contains(query));
   }
 
+  bool _matchesDraftQuery(PathPatternDraft draft, String query) {
+    final fields = [
+      draft.name,
+      draft.id,
+      draft.basePathPresetId,
+      draft.centerPatternLabel,
+    ];
+    return fields.any((field) => field.toLowerCase().contains(query));
+  }
+
   _IndexedPresetCard? _selectedCard(List<_IndexedPresetCard> filtered) {
     if (filtered.isEmpty) {
       return null;
@@ -161,6 +202,105 @@ class _PathStudioPanelState extends State<PathStudioPanel> {
     }
     return filtered.first;
   }
+
+  void _createDraft() {
+    if (widget.manifest.pathPresets.isEmpty) {
+      setState(() {
+        _draftMessage = 'Aucun preset Path de base disponible';
+        _draftSelected = false;
+      });
+      return;
+    }
+    try {
+      final draft = createInitialPathPatternDraftFromManifest(
+        manifest: widget.manifest,
+      );
+      setState(() {
+        _draft = draft;
+        _draftSelected = draft != null;
+        _draftMessage = draft == null
+            ? 'Aucun preset Path de base disponible'
+            : 'Brouillon non sauvegardé';
+      });
+    } on ArgumentError {
+      setState(() {
+        _draftMessage =
+            'Le preset Path de base ne contient pas de centre cross';
+        _draftSelected = false;
+      });
+    }
+  }
+
+  void _renameDraft(String name) {
+    final draft = _draft;
+    if (draft == null) {
+      return;
+    }
+    setState(() => _draft = renamePathPatternDraft(draft, name));
+  }
+
+  void _resizeDraft(int width, int height) {
+    final draft = _draft;
+    final base = _basePathPresetForDraft(draft);
+    if (draft == null || base == null) {
+      return;
+    }
+    setState(() {
+      _draft = resizePathPatternDraftCenter(
+        draft: draft,
+        basePathPreset: base,
+        width: width,
+        height: height,
+      );
+    });
+  }
+
+  void _changeDraftBase(String basePathPresetId) {
+    final draft = _draft;
+    if (draft == null) {
+      return;
+    }
+    final base = _basePathPresetById(basePathPresetId);
+    if (base == null) {
+      return;
+    }
+    setState(() {
+      _draft = changePathPatternDraftBase(
+        draft: draft,
+        basePathPreset: base,
+      );
+    });
+  }
+
+  void _selectDraftCell(int localX, int localY) {
+    final draft = _draft;
+    if (draft == null) {
+      return;
+    }
+    setState(() {
+      _draft = selectPathPatternDraftCell(
+        draft: draft,
+        localX: localX,
+        localY: localY,
+      );
+    });
+  }
+
+  ProjectPathPreset? _basePathPresetForDraft(PathPatternDraft? draft) {
+    if (draft == null) {
+      return null;
+    }
+    return _basePathPresetById(draft.basePathPresetId);
+  }
+
+  ProjectPathPreset? _basePathPresetById(String id) {
+    for (final preset in widget.manifest.pathPresets) {
+      if (preset.id == id) {
+        return preset;
+      }
+    }
+    return null;
+  }
 }
 
 class _IndexedPresetCard {
@@ -194,9 +334,11 @@ class _PathStudioProjectMissingState extends StatelessWidget {
 class _PathStudioHeader extends StatelessWidget {
   const _PathStudioHeader({
     required this.summary,
+    required this.onCreateDraft,
   });
 
   final PathPatternEditorSummary summary;
+  final VoidCallback onCreateDraft;
 
   @override
   Widget build(BuildContext context) {
@@ -260,19 +402,23 @@ class _PathStudioHeader extends StatelessWidget {
           const SizedBox(width: 8),
           _SummaryPill(label: 'Prêts', value: '${summary.readyCount}'),
           const SizedBox(width: 12),
-          const _ShellActionButton(
+          _ShellActionButton(
             icon: CupertinoIcons.plus,
             label: 'Nouveau preset',
+            hint: 'brouillon local',
+            onPressed: onCreateDraft,
           ),
           const SizedBox(width: 8),
           const _ShellActionButton(
             icon: CupertinoIcons.square_on_square,
             label: 'Dupliquer',
+            hint: 'lot futur',
           ),
           const SizedBox(width: 8),
           const _ShellActionButton(
             icon: CupertinoIcons.floppy_disk,
             label: 'Enregistrer',
+            hint: 'lot futur',
           ),
         ],
       ),
@@ -328,17 +474,21 @@ class _ShellActionButton extends StatelessWidget {
   const _ShellActionButton({
     required this.icon,
     required this.label,
+    this.hint = 'lot futur',
+    this.onPressed,
   });
 
   final IconData icon;
   final String label;
+  final String hint;
+  final VoidCallback? onPressed;
 
   @override
   Widget build(BuildContext context) {
     return CupertinoButton(
       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
       minimumSize: Size.zero,
-      onPressed: null,
+      onPressed: onPressed,
       disabledColor: PathStudioTheme.surfaceRaised.withValues(alpha: 0.72),
       color: PathStudioTheme.accent,
       borderRadius: BorderRadius.circular(13),
@@ -347,7 +497,9 @@ class _ShellActionButton extends StatelessWidget {
         children: [
           MacosIcon(
             icon,
-            color: PathStudioTheme.textMuted.withValues(alpha: 0.72),
+            color: onPressed == null
+                ? PathStudioTheme.textMuted.withValues(alpha: 0.72)
+                : CupertinoColors.white,
             size: 15,
           ),
           const SizedBox(width: 8),
@@ -357,15 +509,19 @@ class _ShellActionButton extends StatelessWidget {
               Text(
                 label,
                 style: TextStyle(
-                  color: PathStudioTheme.textSecondary.withValues(alpha: 0.7),
+                  color: onPressed == null
+                      ? PathStudioTheme.textSecondary.withValues(alpha: 0.7)
+                      : CupertinoColors.white,
                   fontSize: 12,
                   fontWeight: FontWeight.w800,
                 ),
               ),
-              const Text(
-                'lot futur',
+              Text(
+                hint,
                 style: TextStyle(
-                  color: PathStudioTheme.textMuted,
+                  color: onPressed == null
+                      ? PathStudioTheme.textMuted
+                      : CupertinoColors.white.withValues(alpha: 0.72),
                   fontSize: 9,
                   fontWeight: FontWeight.w700,
                 ),
@@ -382,15 +538,25 @@ class _PresetSidebar extends StatelessWidget {
   const _PresetSidebar({
     required this.readModel,
     required this.filteredCards,
+    required this.draft,
+    required this.draftSelected,
+    required this.draftMatchesQuery,
+    required this.draftMessage,
     required this.selectedSourceIndex,
     required this.onQueryChanged,
+    required this.onSelectDraft,
     required this.onSelect,
   });
 
   final PathPatternEditorReadModel readModel;
   final List<_IndexedPresetCard> filteredCards;
+  final PathPatternDraft? draft;
+  final bool draftSelected;
+  final bool draftMatchesQuery;
+  final String? draftMessage;
   final int? selectedSourceIndex;
   final ValueChanged<String> onQueryChanged;
+  final VoidCallback onSelectDraft;
   final ValueChanged<int> onSelect;
 
   @override
@@ -453,23 +619,36 @@ class _PresetSidebar extends StatelessWidget {
   }
 
   Widget _buildPresetList() {
-    if (readModel.presets.isEmpty) {
-      return const _SidebarNotice(
+    final draftCard = draft;
+    if (readModel.presets.isEmpty && draftCard == null) {
+      return _SidebarNotice(
         title: 'Aucun motif PathPattern',
-        message: 'Les presets apparaîtront ici après le lot création.',
+        message: draftMessage ??
+            'Cliquez sur Nouveau preset pour créer un brouillon local.',
       );
     }
-    if (filteredCards.isEmpty) {
+    if (filteredCards.isEmpty &&
+        (draftCard == null || draftMatchesQuery == false)) {
       return const _SidebarNotice(
         title: 'Aucun preset trouvé',
         message: 'Essayez un autre nom, id ou preset de base.',
       );
     }
     return ListView.separated(
-      itemCount: filteredCards.length,
+      itemCount: filteredCards.length +
+          (draftCard != null && draftMatchesQuery ? 1 : 0),
       separatorBuilder: (_, __) => const SizedBox(height: 10),
       itemBuilder: (context, index) {
-        final entry = filteredCards[index];
+        if (draftCard != null && draftMatchesQuery && index == 0) {
+          return _DraftListCard(
+            draft: draftCard,
+            selected: draftSelected,
+            onTap: onSelectDraft,
+          );
+        }
+        final presetIndex =
+            draftCard != null && draftMatchesQuery ? index - 1 : index;
+        final entry = filteredCards[presetIndex];
         return _PresetListCard(
           key: Key('path-studio-preset-card-${entry.sourceIndex}'),
           card: entry.card,
@@ -481,6 +660,95 @@ class _PresetSidebar extends StatelessWidget {
   }
 }
 
+class _DraftListCard extends StatelessWidget {
+  const _DraftListCard({
+    required this.draft,
+    required this.selected,
+    required this.onTap,
+  });
+
+  final PathPatternDraft draft;
+  final bool selected;
+  final VoidCallback onTap;
+
+  @override
+  Widget build(BuildContext context) {
+    return GestureDetector(
+      onTap: onTap,
+      child: Container(
+        key: const Key('path-studio-draft-card'),
+        padding: const EdgeInsets.all(12),
+        decoration: BoxDecoration(
+          color: selected
+              ? Color.lerp(
+                  PathStudioTheme.surfaceStrong,
+                  PathStudioTheme.accentCyan,
+                  0.22,
+                )
+              : PathStudioTheme.surfaceRaised,
+          borderRadius: BorderRadius.circular(16),
+          border: Border.all(
+            color: selected
+                ? PathStudioTheme.accentCyan
+                : PathStudioTheme.accentCyan.withValues(alpha: 0.4),
+            width: selected ? 2 : 1,
+          ),
+        ),
+        child: Column(
+          crossAxisAlignment: CrossAxisAlignment.start,
+          children: [
+            Row(
+              children: [
+                Expanded(
+                  child: Text(
+                    draft.name,
+                    maxLines: 1,
+                    overflow: TextOverflow.ellipsis,
+                    style: const TextStyle(
+                      color: PathStudioTheme.textPrimary,
+                      fontSize: 13,
+                      fontWeight: FontWeight.w800,
+                    ),
+                  ),
+                ),
+                const _StatusChip(
+                  label: 'Brouillon',
+                  color: PathStudioTheme.accentCyan,
+                ),
+              ],
+            ),
+            const SizedBox(height: 8),
+            const Text(
+              'Brouillon local • Non sauvegardé',
+              style: TextStyle(
+                color: PathStudioTheme.textMuted,
+                fontSize: 11,
+                fontWeight: FontWeight.w700,
+              ),
+            ),
+            const SizedBox(height: 10),
+            Row(
+              children: [
+                _MiniMetric(
+                  icon: CupertinoIcons.square_grid_2x2,
+                  label: draft.centerPatternLabel,
+                ),
+                const SizedBox(width: 8),
+                _MiniMetric(
+                  icon: draft.animatedCellCount > 0
+                      ? CupertinoIcons.play_circle
+                      : CupertinoIcons.circle,
+                  label: draft.animatedCellCount > 0 ? 'animé' : 'statique',
+                ),
+              ],
+            ),
+          ],
+        ),
+      ),
+    );
+  }
+}
+
 class _SidebarCounter extends StatelessWidget {
   const _SidebarCounter({required this.value});
 
@@ -728,15 +996,29 @@ class _MiniMetric extends StatelessWidget {
 
 class _CenterWorkspace extends StatelessWidget {
   const _CenterWorkspace({
+    required this.draft,
     required this.selected,
     required this.hasAnyPreset,
+    required this.onDraftSizeChanged,
+    required this.onDraftCellSelected,
   });
 
+  final PathPatternDraft? draft;
   final PathPatternPresetCardModel? selected;
   final bool hasAnyPreset;
+  final void Function(int width, int height) onDraftSizeChanged;
+  final void Function(int localX, int localY) onDraftCellSelected;
 
   @override
   Widget build(BuildContext context) {
+    final draft = this.draft;
+    if (draft != null) {
+      return _DraftCenterWorkspace(
+        draft: draft,
+        onSizeChanged: onDraftSizeChanged,
+        onCellSelected: onDraftCellSelected,
+      );
+    }
     final card = selected;
     if (card == null) {
       return _NoSelectionCenter(hasAnyPreset: hasAnyPreset);
@@ -759,6 +1041,368 @@ class _CenterWorkspace extends StatelessWidget {
   }
 }
 
+class _DraftCenterWorkspace extends StatelessWidget {
+  const _DraftCenterWorkspace({
+    required this.draft,
+    required this.onSizeChanged,
+    required this.onCellSelected,
+  });
+
+  final PathPatternDraft draft;
+  final void Function(int width, int height) onSizeChanged;
+  final void Function(int localX, int localY) onCellSelected;
+
+  @override
+  Widget build(BuildContext context) {
+    return SingleChildScrollView(
+      child: Column(
+        crossAxisAlignment: CrossAxisAlignment.stretch,
+        children: [
+          const _DraftBanner(),
+          const SizedBox(height: 14),
+          const _WorkflowSteps(
+            status: PathPatternPresetReadinessStatus.needsReview,
+          ),
+          const SizedBox(height: 14),
+          _DraftSummary(draft: draft),
+          const SizedBox(height: 14),
+          _DraftCenterPatternEditor(
+            draft: draft,
+            onSizeChanged: onSizeChanged,
+            onCellSelected: onCellSelected,
+          ),
+          const SizedBox(height: 14),
+          _DraftDiagnosticsCard(draft: draft),
+        ],
+      ),
+    );
+  }
+}
+
+class _DraftBanner extends StatelessWidget {
+  const _DraftBanner();
+
+  @override
+  Widget build(BuildContext context) {
+    return const _SectionCard(
+      title: 'Brouillon local',
+      icon: CupertinoIcons.pencil_outline,
+      trailing: _StatusChip(
+        label: 'Non sauvegardé',
+        color: PathStudioTheme.warning,
+      ),
+      child: Text(
+        'Ce brouillon vit uniquement en mémoire. Il sera enregistrable dans un lot futur.',
+        style: TextStyle(
+          color: PathStudioTheme.textSecondary,
+          fontSize: 13,
+          height: 1.4,
+        ),
+      ),
+    );
+  }
+}
+
+class _DraftSummary extends StatelessWidget {
+  const _DraftSummary({required this.draft});
+
+  final PathPatternDraft draft;
+
+  @override
+  Widget build(BuildContext context) {
+    return _SectionCard(
+      title: 'Résumé du brouillon',
+      icon: CupertinoIcons.doc_text,
+      child: Wrap(
+        spacing: 10,
+        runSpacing: 10,
+        children: [
+          _InfoTile(label: 'Nom', value: draft.name),
+          _InfoTile(label: 'Base', value: draft.basePathPresetId),
+          _InfoTile(label: 'Centre', value: draft.centerPatternLabel),
+          _InfoTile(label: 'Cellules', value: '${draft.centerCellCount}'),
+          _InfoTile(label: 'Frames', value: '${draft.centerFrameCount}'),
+          _InfoTile(
+            label: 'Animation',
+            value: '${draft.animatedCellCount} cellules',
+          ),
+          const _InfoTile(label: 'État', value: 'Brouillon non sauvegardé'),
+        ],
+      ),
+    );
+  }
+}
+
+class _DraftCenterPatternEditor extends StatelessWidget {
+  const _DraftCenterPatternEditor({
+    required this.draft,
+    required this.onSizeChanged,
+    required this.onCellSelected,
+  });
+
+  final PathPatternDraft draft;
+  final void Function(int width, int height) onSizeChanged;
+  final void Function(int localX, int localY) onCellSelected;
+
+  @override
+  Widget build(BuildContext context) {
+    return _SectionCard(
+      title: 'Motif du centre',
+      icon: CupertinoIcons.square_grid_2x2,
+      child: Column(
+        crossAxisAlignment: CrossAxisAlignment.start,
+        children: [
+          const Text(
+            'Le motif du centre sera répété dans les grandes zones pleines.',
+            style: TextStyle(
+              color: PathStudioTheme.textSecondary,
+              fontSize: 13,
+              height: 1.35,
+            ),
+          ),
+          const SizedBox(height: 14),
+          CupertinoSlidingSegmentedControl<String>(
+            key: const Key('path-studio-draft-size-control'),
+            groupValue: draft.centerPatternLabel,
+            onValueChanged: (value) {
+              if (value == '1×1') {
+                onSizeChanged(1, 1);
+              } else if (value == '2×2') {
+                onSizeChanged(2, 2);
+              }
+            },
+            children: const {
+              '1×1': Padding(
+                key: Key('path-studio-draft-size-1x1'),
+                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
+                child: Text('1×1'),
+              ),
+              '2×2': Padding(
+                key: Key('path-studio-draft-size-2x2'),
+                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
+                child: Text('2×2'),
+              ),
+            },
+          ),
+          const SizedBox(height: 18),
+          _DraftPatternGrid(
+            draft: draft,
+            onCellSelected: onCellSelected,
+          ),
+          const SizedBox(height: 14),
+          _DraftSelectedCellDetails(draft: draft),
+        ],
+      ),
+    );
+  }
+}
+
+class _DraftPatternGrid extends StatelessWidget {
+  const _DraftPatternGrid({
+    required this.draft,
+    required this.onCellSelected,
+  });
+
+  final PathPatternDraft draft;
+  final void Function(int localX, int localY) onCellSelected;
+
+  @override
+  Widget build(BuildContext context) {
+    final rows = <Widget>[];
+    var labelCode = 'A'.codeUnitAt(0);
+    for (var y = 0; y < draft.centerPattern.size.height; y += 1) {
+      final cells = <Widget>[];
+      for (var x = 0; x < draft.centerPattern.size.width; x += 1) {
+        final cell = draft.centerPattern.cellAt(x, y);
+        cells.add(
+          _DraftPatternCell(
+            key: Key('path-studio-draft-cell-$x-$y'),
+            label: String.fromCharCode(labelCode),
+            cell: cell,
+            selected: draft.selectedCellX == x && draft.selectedCellY == y,
+            onTap: () => onCellSelected(x, y),
+          ),
+        );
+        labelCode += 1;
+      }
+      rows.add(Row(mainAxisSize: MainAxisSize.min, children: cells));
+    }
+
+    return Container(
+      padding: const EdgeInsets.all(12),
+      decoration: PathStudioTheme.subtleDecoration(
+        color: PathStudioTheme.backgroundAlt,
+      ),
+      child: Column(mainAxisSize: MainAxisSize.min, children: rows),
+    );
+  }
+}
+
+class _DraftPatternCell extends StatelessWidget {
+  const _DraftPatternCell({
+    super.key,
+    required this.label,
+    required this.cell,
+    required this.selected,
+    required this.onTap,
+  });
+
+  final String label;
+  final PathCenterPatternCell cell;
+  final bool selected;
+  final VoidCallback onTap;
+
+  @override
+  Widget build(BuildContext context) {
+    final source = cell.frames.first.source;
+    return GestureDetector(
+      onTap: onTap,
+      child: Container(
+        width: 112,
+        height: 92,
+        margin: const EdgeInsets.all(6),
+        padding: const EdgeInsets.all(10),
+        decoration: BoxDecoration(
+          color: Color.lerp(
+            PathStudioTheme.surfaceStrong,
+            selected ? PathStudioTheme.accent : PathStudioTheme.accentCyan,
+            selected ? 0.32 : 0.16,
+          ),
+          borderRadius: BorderRadius.circular(16),
+          border: Border.all(
+            color: selected
+                ? PathStudioTheme.accentHover
+                : PathStudioTheme.accentCyan.withValues(alpha: 0.45),
+            width: selected ? 2 : 1,
+          ),
+        ),
+        child: Column(
+          crossAxisAlignment: CrossAxisAlignment.start,
+          children: [
+            Text(
+              label,
+              style: const TextStyle(
+                color: PathStudioTheme.textPrimary,
+                fontSize: 18,
+                fontWeight: FontWeight.w900,
+              ),
+            ),
+            const Spacer(),
+            Text(
+              '${cell.frames.length} frame${cell.frames.length > 1 ? 's' : ''}',
+              style: const TextStyle(
+                color: PathStudioTheme.textSecondary,
+                fontSize: 11,
+                fontWeight: FontWeight.w800,
+              ),
+            ),
+            Text(
+              cell.frames.length > 1 ? 'animé' : 'statique',
+              style: const TextStyle(
+                color: PathStudioTheme.textMuted,
+                fontSize: 10,
+                fontWeight: FontWeight.w700,
+              ),
+            ),
+            Text(
+              'source ${source.x},${source.y}',
+              style: const TextStyle(
+                color: PathStudioTheme.textMuted,
+                fontSize: 10,
+                fontWeight: FontWeight.w700,
+              ),
+            ),
+          ],
+        ),
+      ),
+    );
+  }
+}
+
+class _DraftSelectedCellDetails extends StatelessWidget {
+  const _DraftSelectedCellDetails({required this.draft});
+
+  final PathPatternDraft draft;
+
+  @override
+  Widget build(BuildContext context) {
+    final cell = draft.selectedCell;
+    final source = cell.frames.first.source;
+    return Container(
+      padding: const EdgeInsets.all(12),
+      decoration: PathStudioTheme.subtleDecoration(),
+      child: Column(
+        crossAxisAlignment: CrossAxisAlignment.start,
+        children: [
+          const Text(
+            'Cellule sélectionnée',
+            style: TextStyle(
+              color: PathStudioTheme.textPrimary,
+              fontSize: 13,
+              fontWeight: FontWeight.w800,
+            ),
+          ),
+          const SizedBox(height: 6),
+          Text(
+            'Position ${cell.localX},${cell.localY}',
+            style: const TextStyle(
+              color: PathStudioTheme.textSecondary,
+              fontSize: 12,
+              fontWeight: FontWeight.w700,
+            ),
+          ),
+          Text(
+            '${cell.frames.length} frame${cell.frames.length > 1 ? 's' : ''} • source ${source.x},${source.y}',
+            style: const TextStyle(
+              color: PathStudioTheme.textMuted,
+              fontSize: 11,
+              fontWeight: FontWeight.w700,
+            ),
+          ),
+        ],
+      ),
+    );
+  }
+}
+
+class _DraftDiagnosticsCard extends StatelessWidget {
+  const _DraftDiagnosticsCard({required this.draft});
+
+  final PathPatternDraft draft;
+
+  @override
+  Widget build(BuildContext context) {
+    final issues = draft.issues;
+    return _SectionCard(
+      title: 'Diagnostics locaux',
+      icon: CupertinoIcons.check_mark_circled,
+      child: issues.isEmpty
+          ? const _DiagnosticRow(
+              icon: CupertinoIcons.check_mark_circled_solid,
+              color: PathStudioTheme.success,
+              title: 'Aucune erreur locale',
+              message: 'Le brouillon est éditable en mémoire.',
+            )
+          : Column(
+              crossAxisAlignment: CrossAxisAlignment.stretch,
+              children: issues
+                  .map(
+                    (issue) => Padding(
+                      padding: const EdgeInsets.only(bottom: 8),
+                      child: _DiagnosticRow(
+                        icon: CupertinoIcons.exclamationmark_triangle_fill,
+                        color: PathStudioTheme.warning,
+                        title: _draftIssueLabel(issue),
+                        message: _draftIssueDescription(issue),
+                      ),
+                    ),
+                  )
+                  .toList(growable: false),
+            ),
+    );
+  }
+}
+
 class _NoSelectionCenter extends StatelessWidget {
   const _NoSelectionCenter({required this.hasAnyPreset});
 
@@ -1112,12 +1756,34 @@ class _DiagnosticsCard extends StatelessWidget {
 }
 
 class _PresetInspector extends StatelessWidget {
-  const _PresetInspector({required this.selected});
+  const _PresetInspector({
+    required this.manifest,
+    required this.draft,
+    required this.selected,
+    required this.onDraftNameChanged,
+    required this.onDraftBaseChanged,
+    required this.onDraftSizeChanged,
+  });
 
+  final ProjectManifest manifest;
+  final PathPatternDraft? draft;
   final PathPatternPresetCardModel? selected;
+  final ValueChanged<String> onDraftNameChanged;
+  final ValueChanged<String> onDraftBaseChanged;
+  final void Function(int width, int height) onDraftSizeChanged;
 
   @override
   Widget build(BuildContext context) {
+    final draft = this.draft;
+    if (draft != null) {
+      return _DraftInspector(
+        manifest: manifest,
+        draft: draft,
+        onNameChanged: onDraftNameChanged,
+        onBaseChanged: onDraftBaseChanged,
+        onSizeChanged: onDraftSizeChanged,
+      );
+    }
     final card = selected;
     return Container(
       decoration: PathStudioTheme.panelDecoration(),
@@ -1170,6 +1836,181 @@ class _PresetInspector extends StatelessWidget {
   }
 }
 
+class _DraftInspector extends StatelessWidget {
+  const _DraftInspector({
+    required this.manifest,
+    required this.draft,
+    required this.onNameChanged,
+    required this.onBaseChanged,
+    required this.onSizeChanged,
+  });
+
+  final ProjectManifest manifest;
+  final PathPatternDraft draft;
+  final ValueChanged<String> onNameChanged;
+  final ValueChanged<String> onBaseChanged;
+  final void Function(int width, int height) onSizeChanged;
+
+  @override
+  Widget build(BuildContext context) {
+    return Container(
+      decoration: PathStudioTheme.panelDecoration(),
+      padding: const EdgeInsets.all(16),
+      child: SingleChildScrollView(
+        child: Column(
+          crossAxisAlignment: CrossAxisAlignment.stretch,
+          children: [
+            const Text(
+              'Propriétés du brouillon',
+              style: TextStyle(
+                color: PathStudioTheme.textPrimary,
+                fontSize: 16,
+                fontWeight: FontWeight.w800,
+              ),
+            ),
+            const SizedBox(height: 14),
+            const _StatusChip(
+              label: 'Brouillon non sauvegardé',
+              color: PathStudioTheme.warning,
+            ),
+            const SizedBox(height: 14),
+            const _InspectorLabel('Nom'),
+            CupertinoTextField(
+              key: const Key('path-studio-draft-name-field'),
+              placeholder: draft.name,
+              onChanged: onNameChanged,
+              style: const TextStyle(
+                color: PathStudioTheme.textPrimary,
+                fontSize: 13,
+                fontWeight: FontWeight.w700,
+              ),
+              placeholderStyle: const TextStyle(
+                color: PathStudioTheme.textSecondary,
+                fontSize: 13,
+                fontWeight: FontWeight.w700,
+              ),
+              decoration: BoxDecoration(
+                color: PathStudioTheme.surfaceRaised,
+                borderRadius: BorderRadius.circular(12),
+                border: Border.all(color: PathStudioTheme.border),
+              ),
+              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
+            ),
+            const SizedBox(height: 12),
+            const _InspectorLabel('Preset de base'),
+            _DraftBasePopup(
+              manifest: manifest,
+              draft: draft,
+              onBaseChanged: onBaseChanged,
+            ),
+            const SizedBox(height: 12),
+            const _InspectorLabel('Taille du centre'),
+            CupertinoSlidingSegmentedControl<String>(
+              groupValue: draft.centerPatternLabel,
+              onValueChanged: (value) {
+                if (value == '1×1') {
+                  onSizeChanged(1, 1);
+                } else if (value == '2×2') {
+                  onSizeChanged(2, 2);
+                }
+              },
+              children: const {
+                '1×1': Padding(
+                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
+                  child: Text('1×1'),
+                ),
+                '2×2': Padding(
+                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
+                  child: Text('2×2'),
+                ),
+              },
+            ),
+            const SizedBox(height: 14),
+            _InspectorRow(label: 'ID temporaire', value: draft.id),
+            _InspectorRow(
+                label: 'Base path preset id', value: draft.basePathPresetId),
+            _InspectorRow(label: 'Cellules', value: '${draft.centerCellCount}'),
+            _InspectorRow(label: 'Frames', value: '${draft.centerFrameCount}'),
+            _InspectorRow(
+              label: 'Cellules animées',
+              value: '${draft.animatedCellCount}',
+            ),
+            _InspectorRow(
+              label: 'Transparent color',
+              value: draft.transparentColor?.toHexRgb() ?? 'Aucune',
+            ),
+            const _InspectorRow(
+              label: 'État',
+              value: 'Brouillon non sauvegardé',
+            ),
+            const SizedBox(height: 14),
+            _DraftDiagnosticsCard(draft: draft),
+          ],
+        ),
+      ),
+    );
+  }
+}
+
+class _DraftBasePopup extends StatelessWidget {
+  const _DraftBasePopup({
+    required this.manifest,
+    required this.draft,
+    required this.onBaseChanged,
+  });
+
+  final ProjectManifest manifest;
+  final PathPatternDraft draft;
+  final ValueChanged<String> onBaseChanged;
+
+  @override
+  Widget build(BuildContext context) {
+    return MacosPopupButton<String>(
+      key: const Key('path-studio-draft-base-popup'),
+      value: draft.basePathPresetId,
+      onChanged: (value) {
+        if (value != null) {
+          onBaseChanged(value);
+        }
+      },
+      items: [
+        for (final preset in manifest.pathPresets)
+          MacosPopupMenuItem<String>(
+            value: preset.id,
+            child: SizedBox(
+              width: 220,
+              child: Text(
+                '${preset.name} (${preset.id})',
+                overflow: TextOverflow.ellipsis,
+              ),
+            ),
+          ),
+      ],
+    );
+  }
+}
+
+class _InspectorLabel extends StatelessWidget {
+  const _InspectorLabel(this.label);
+
+  final String label;
+
+  @override
+  Widget build(BuildContext context) {
+    return Padding(
+      padding: const EdgeInsets.only(bottom: 6),
+      child: Text(
+        label,
+        style: const TextStyle(
+          color: PathStudioTheme.textMuted,
+          fontSize: 10,
+          fontWeight: FontWeight.w800,
+        ),
+      ),
+    );
+  }
+}
+
 class _InspectorEmptyState extends StatelessWidget {
   const _InspectorEmptyState();
 
@@ -1439,3 +2280,16 @@ String _issueDescription(PathPatternPresetIssueCode issue) {
       'Plusieurs ProjectPathPreset legacy correspondent à la même base.',
   };
 }
+
+String _draftIssueLabel(PathPatternDraftIssueCode issue) {
+  return switch (issue) {
+    PathPatternDraftIssueCode.nameRequired => 'Nom requis',
+  };
+}
+
+String _draftIssueDescription(PathPatternDraftIssueCode issue) {
+  return switch (issue) {
+    PathPatternDraftIssueCode.nameRequired =>
+      'Le brouillon peut rester éditable, mais son nom devra être renseigné avant une future sauvegarde.',
+  };
+}
diff --git a/packages/map_editor/test/path_pattern/path_studio_panel_test.dart b/packages/map_editor/test/path_pattern/path_studio_panel_test.dart
index 56a8ddbb..b695d753 100644
--- a/packages/map_editor/test/path_pattern/path_studio_panel_test.dart
+++ b/packages/map_editor/test/path_pattern/path_studio_panel_test.dart
@@ -94,13 +94,11 @@ void main() {
       expect(find.text('Aucun preset sélectionné'), findsWidgets);
     });
 
-    testWidgets('shows shell actions as visibly disabled placeholders',
-        (tester) async {
+    testWidgets('creates a local draft from Nouveau preset', (tester) async {
       await _pumpPathStudio(
         tester,
         manifest: _manifest(
           pathPresets: [_legacyPathPreset(id: 'legacy-water')],
-          pathPatternPresets: [_pathPatternPreset(id: 'water')],
         ),
       );
 
@@ -114,10 +112,146 @@ void main() {
         find.widgetWithText(CupertinoButton, 'Enregistrer'),
       );
 
-      expect(newPresetButton.onPressed, isNull);
+      expect(newPresetButton.onPressed, isNotNull);
       expect(duplicateButton.onPressed, isNull);
       expect(saveButton.onPressed, isNull);
       expect(find.text('lot futur'), findsWidgets);
+
+      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau preset'));
+      await tester.pumpAndSettle();
+
+      expect(find.text('Brouillon local'), findsWidgets);
+      expect(find.text('Brouillon non sauvegardé'), findsWidgets);
+      expect(find.text('Propriétés du brouillon'), findsOneWidget);
+      expect(find.text('Nouveau motif de chemin'), findsWidgets);
+      expect(find.text('1×1'), findsWidgets);
+      expect(
+          find.byKey(const Key('path-studio-draft-cell-0-0')), findsOneWidget);
+    });
+
+    testWidgets('resizes the local draft to 2x2 and selects a cell',
+        (tester) async {
+      await _pumpPathStudio(
+        tester,
+        manifest: _manifest(
+          pathPresets: [_legacyPathPreset(id: 'legacy-water')],
+        ),
+      );
+
+      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau preset'));
+      await tester.pumpAndSettle();
+      await tester.tap(find.byKey(const Key('path-studio-draft-size-2x2')));
+      await tester.pumpAndSettle();
+
+      expect(
+          find.byKey(const Key('path-studio-draft-cell-0-0')), findsOneWidget);
+      expect(
+          find.byKey(const Key('path-studio-draft-cell-1-0')), findsOneWidget);
+      expect(
+          find.byKey(const Key('path-studio-draft-cell-0-1')), findsOneWidget);
+      expect(
+          find.byKey(const Key('path-studio-draft-cell-1-1')), findsOneWidget);
+      expect(find.text('A'), findsWidgets);
+      expect(find.text('B'), findsWidgets);
+      expect(find.text('C'), findsWidgets);
+      expect(find.text('D'), findsWidgets);
+
+      await tester.tap(find.byKey(const Key('path-studio-draft-cell-1-1')));
+      await tester.pumpAndSettle();
+
+      expect(find.text('Cellule sélectionnée'), findsWidgets);
+      expect(find.text('Position 1,1'), findsWidgets);
+    });
+
+    testWidgets('edits draft name and keeps save disabled', (tester) async {
+      await _pumpPathStudio(
+        tester,
+        manifest: _manifest(
+          pathPresets: [_legacyPathPreset(id: 'legacy-water')],
+        ),
+      );
+
+      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau preset'));
+      await tester.pumpAndSettle();
+      await tester.enterText(
+        find.byKey(const Key('path-studio-draft-name-field')),
+        'Mer brouillon',
+      );
+      await tester.pumpAndSettle();
+
+      expect(find.text('Mer brouillon'), findsWidgets);
+      final saveButton = tester.widget<CupertinoButton>(
+        find.widgetWithText(CupertinoButton, 'Enregistrer'),
+      );
+      expect(saveButton.onPressed, isNull);
+    });
+
+    testWidgets('changes draft base locally without saving', (tester) async {
+      await _pumpPathStudio(
+        tester,
+        manifest: _manifest(
+          pathPresets: [
+            _legacyPathPreset(id: 'legacy-water', name: 'Base eau'),
+            _legacyPathPreset(
+              id: 'legacy-sand',
+              name: 'Base sable',
+              crossSourceX: 5,
+            ),
+          ],
+        ),
+      );
+
+      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau preset'));
+      await tester.pumpAndSettle();
+      await tester.enterText(
+        find.byKey(const Key('path-studio-draft-name-field')),
+        'Mer brouillon',
+      );
+      await tester.pumpAndSettle();
+
+      final popup = tester.widget<MacosPopupButton<String>>(
+        find.byKey(const Key('path-studio-draft-base-popup')),
+      );
+      popup.onChanged?.call('legacy-sand');
+      await tester.pumpAndSettle();
+
+      expect(find.text('Mer brouillon'), findsWidgets);
+      expect(find.text('legacy-sand'), findsWidgets);
+      expect(find.text('source 5,0'), findsWidgets);
+      expect(find.text('Brouillon non sauvegardé'), findsWidgets);
+    });
+
+    testWidgets('empty draft name shows a local diagnostic', (tester) async {
+      await _pumpPathStudio(
+        tester,
+        manifest: _manifest(
+          pathPresets: [_legacyPathPreset(id: 'legacy-water')],
+        ),
+      );
+
+      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau preset'));
+      await tester.pumpAndSettle();
+      await tester.enterText(
+        find.byKey(const Key('path-studio-draft-name-field')),
+        '   ',
+      );
+      await tester.pumpAndSettle();
+
+      expect(find.text('Nom requis'), findsWidgets);
+    });
+
+    testWidgets('does not create a draft without legacy base path presets',
+        (tester) async {
+      await _pumpPathStudio(
+        tester,
+        manifest: _manifest(),
+      );
+
+      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau preset'));
+      await tester.pumpAndSettle();
+
+      expect(find.text('Aucun preset Path de base disponible'), findsWidgets);
+      expect(find.text('Brouillon local'), findsNothing);
     });
   });
 }
@@ -163,11 +297,18 @@ ProjectManifest _manifest({
 ProjectPathPreset _legacyPathPreset({
   required String id,
   String name = 'Legacy Water',
+  int crossSourceX = 0,
 }) {
   return ProjectPathPreset(
     id: id,
     name: name,
     surfaceKind: PathSurfaceKind.water,
+    variants: [
+      PathPresetVariantMapping(
+        variant: TerrainPathVariant.cross,
+        frames: [_frame(crossSourceX)],
+      ),
+    ],
   );
 }
```

### 18.2 Diff /dev/null des fichiers créés

#### packages/map_editor/lib/src/features/path_studio/path_pattern_draft.dart

```text
--- /dev/null	2026-04-30 20:22:33
+++ packages/map_editor/lib/src/features/path_studio/path_pattern_draft.dart	2026-04-30 20:15:23
@@ -0,0 +1,230 @@
+import 'package:map_core/map_core.dart';
+
+/// Issues locales propres au brouillon Path Studio.
+///
+/// Elles ne sont pas des erreurs de manifest : le brouillon n'est pas encore
+/// persistant. Le but est seulement de guider l'utilisateur pendant l'édition
+/// locale V0.
+enum PathPatternDraftIssueCode {
+  nameRequired,
+}
+
+/// Brouillon local et non sauvegardé d'un `ProjectPathPatternPreset`.
+///
+/// Ce modèle vit côté `map_editor` parce qu'il décrit un état d'édition UI,
+/// pas un contrat projet. Il ne mute jamais le `ProjectManifest`.
+final class PathPatternDraft {
+  PathPatternDraft({
+    required this.id,
+    required this.name,
+    required this.basePathPresetId,
+    required this.centerPattern,
+    this.transparentColor,
+    this.categoryId,
+    required this.sortOrder,
+    required this.selectedCellX,
+    required this.selectedCellY,
+    required this.isDirty,
+  });
+
+  final String id;
+  final String name;
+  final String basePathPresetId;
+  final PathCenterPattern centerPattern;
+  final TilesetTransparentColor? transparentColor;
+  final String? categoryId;
+  final int sortOrder;
+  final int selectedCellX;
+  final int selectedCellY;
+  final bool isDirty;
+
+  String get centerPatternLabel =>
+      '${centerPattern.size.width}×${centerPattern.size.height}';
+
+  int get centerCellCount => centerPattern.cells.length;
+
+  int get centerFrameCount => centerPattern.cells.fold(
+        0,
+        (total, cell) => total + cell.frames.length,
+      );
+
+  int get animatedCellCount =>
+      centerPattern.cells.where((cell) => cell.frames.length > 1).length;
+
+  PathCenterPatternCell get selectedCell =>
+      centerPattern.cellAt(selectedCellX, selectedCellY);
+
+  List<PathPatternDraftIssueCode> get issues {
+    final result = <PathPatternDraftIssueCode>[];
+    if (name.trim().isEmpty) {
+      result.add(PathPatternDraftIssueCode.nameRequired);
+    }
+    return List<PathPatternDraftIssueCode>.unmodifiable(result);
+  }
+
+  PathPatternDraft copyWith({
+    String? id,
+    String? name,
+    String? basePathPresetId,
+    PathCenterPattern? centerPattern,
+    TilesetTransparentColor? transparentColor,
+    String? categoryId,
+    int? sortOrder,
+    int? selectedCellX,
+    int? selectedCellY,
+    bool? isDirty,
+  }) {
+    return PathPatternDraft(
+      id: id ?? this.id,
+      name: name ?? this.name,
+      basePathPresetId: basePathPresetId ?? this.basePathPresetId,
+      centerPattern: centerPattern ?? this.centerPattern,
+      transparentColor: transparentColor ?? this.transparentColor,
+      categoryId: categoryId ?? this.categoryId,
+      sortOrder: sortOrder ?? this.sortOrder,
+      selectedCellX: selectedCellX ?? this.selectedCellX,
+      selectedCellY: selectedCellY ?? this.selectedCellY,
+      isDirty: isDirty ?? this.isDirty,
+    );
+  }
+
+  @override
+  bool operator ==(Object other) {
+    return identical(this, other) ||
+        other is PathPatternDraft &&
+            id == other.id &&
+            name == other.name &&
+            basePathPresetId == other.basePathPresetId &&
+            centerPattern == other.centerPattern &&
+            transparentColor == other.transparentColor &&
+            categoryId == other.categoryId &&
+            sortOrder == other.sortOrder &&
+            selectedCellX == other.selectedCellX &&
+            selectedCellY == other.selectedCellY &&
+            isDirty == other.isDirty;
+  }
+
+  @override
+  int get hashCode => Object.hash(
+        id,
+        name,
+        basePathPresetId,
+        centerPattern,
+        transparentColor,
+        categoryId,
+        sortOrder,
+        selectedCellX,
+        selectedCellY,
+        isDirty,
+      );
+}
+
+PathPatternDraft? createInitialPathPatternDraftFromManifest({
+  required ProjectManifest manifest,
+}) {
+  if (manifest.pathPresets.isEmpty) {
+    return null;
+  }
+  return createInitialPathPatternDraft(
+    basePathPreset: manifest.pathPresets.first,
+    sortOrder: manifest.pathPatternPresets.length,
+  );
+}
+
+PathPatternDraft createInitialPathPatternDraft({
+  required ProjectPathPreset basePathPreset,
+  int sortOrder = 0,
+}) {
+  return PathPatternDraft(
+    id: 'draft-path-pattern',
+    name: 'Nouveau motif de chemin',
+    basePathPresetId: basePathPreset.id,
+    centerPattern: rebuildDraftCenterPattern(
+      basePathPreset: basePathPreset,
+      size: PathCenterPatternSize(width: 1, height: 1),
+    ),
+    categoryId: null,
+    sortOrder: sortOrder,
+    selectedCellX: 0,
+    selectedCellY: 0,
+    isDirty: true,
+  );
+}
+
+PathCenterPattern rebuildDraftCenterPattern({
+  required ProjectPathPreset basePathPreset,
+  required PathCenterPatternSize size,
+}) {
+  final centerView = createLegacyProjectPathPresetCenterPatternView(
+    preset: basePathPreset,
+    centerVariant: TerrainPathVariant.cross,
+  );
+  final frames = centerView.centerPattern.cellAt(0, 0).frames;
+  final cells = <PathCenterPatternCell>[];
+  for (var y = 0; y < size.height; y += 1) {
+    for (var x = 0; x < size.width; x += 1) {
+      cells.add(
+        PathCenterPatternCell(
+          localX: x,
+          localY: y,
+          frames: frames,
+        ),
+      );
+    }
+  }
+  return PathCenterPattern(size: size, cells: cells);
+}
+
+PathPatternDraft resizePathPatternDraftCenter({
+  required PathPatternDraft draft,
+  required ProjectPathPreset basePathPreset,
+  required int width,
+  required int height,
+}) {
+  final size = PathCenterPatternSize(width: width, height: height);
+  return draft.copyWith(
+    centerPattern: rebuildDraftCenterPattern(
+      basePathPreset: basePathPreset,
+      size: size,
+    ),
+    selectedCellX: draft.selectedCellX.clamp(0, width - 1).toInt(),
+    selectedCellY: draft.selectedCellY.clamp(0, height - 1).toInt(),
+    isDirty: true,
+  );
+}
+
+PathPatternDraft changePathPatternDraftBase({
+  required PathPatternDraft draft,
+  required ProjectPathPreset basePathPreset,
+}) {
+  return draft.copyWith(
+    basePathPresetId: basePathPreset.id,
+    centerPattern: rebuildDraftCenterPattern(
+      basePathPreset: basePathPreset,
+      size: draft.centerPattern.size,
+    ),
+    isDirty: true,
+  );
+}
+
+PathPatternDraft renamePathPatternDraft(
+  PathPatternDraft draft,
+  String name,
+) {
+  return draft.copyWith(name: name, isDirty: true);
+}
+
+PathPatternDraft selectPathPatternDraftCell({
+  required PathPatternDraft draft,
+  required int localX,
+  required int localY,
+}) {
+  // `cellAt` intentionally performs the bounds validation for this local
+  // editor state. A failing caller should surface during tests rather than
+  // silently selecting a different cell.
+  draft.centerPattern.cellAt(localX, localY);
+  return draft.copyWith(
+    selectedCellX: localX,
+    selectedCellY: localY,
+  );
+}
```

#### packages/map_editor/test/path_pattern/path_pattern_draft_test.dart

```text
--- /dev/null	2026-04-30 20:22:33
+++ packages/map_editor/test/path_pattern/path_pattern_draft_test.dart	2026-04-30 20:10:58
@@ -0,0 +1,145 @@
+import 'package:flutter_test/flutter_test.dart';
+import 'package:map_core/map_core.dart';
+import 'package:map_editor/src/features/path_studio/path_pattern_draft.dart';
+
+void main() {
+  group('PathPatternDraft', () {
+    test('creates an initial draft from the legacy cross center', () {
+      final draft = createInitialPathPatternDraft(
+        basePathPreset: _legacyPathPreset(id: 'legacy-water', crossSourceX: 7),
+      );
+
+      expect(draft.id, 'draft-path-pattern');
+      expect(draft.name, 'Nouveau motif de chemin');
+      expect(draft.basePathPresetId, 'legacy-water');
+      expect(
+          draft.centerPattern.size, PathCenterPatternSize(width: 1, height: 1));
+      expect(draft.centerPattern.cellAt(0, 0).frames, [_frame(7)]);
+      expect(draft.isDirty, isTrue);
+      expect(draft.selectedCellX, 0);
+      expect(draft.selectedCellY, 0);
+      expect(draft.issues, isEmpty);
+    });
+
+    test('returns null when a manifest has no legacy base path preset', () {
+      final draft = createInitialPathPatternDraftFromManifest(
+        manifest: ProjectManifest(
+          name: 'Project',
+          maps: const [],
+          tilesets: const [],
+          surfaceCatalog: ProjectSurfaceCatalog(),
+        ),
+      );
+
+      expect(draft, isNull);
+    });
+
+    test('resizes a 1x1 draft to a 2x2 center with copied cross frames', () {
+      final base = _legacyPathPreset(id: 'legacy-water', crossSourceX: 3);
+      final draft = createInitialPathPatternDraft(basePathPreset: base);
+
+      final resized = resizePathPatternDraftCenter(
+        draft: draft,
+        basePathPreset: base,
+        width: 2,
+        height: 2,
+      );
+
+      expect(resized.centerPattern.size,
+          PathCenterPatternSize(width: 2, height: 2));
+      expect(
+          resized.centerPattern.cells.map((cell) => (cell.localX, cell.localY)),
+          [
+            (0, 0),
+            (1, 0),
+            (0, 1),
+            (1, 1),
+          ]);
+      for (final cell in resized.centerPattern.cells) {
+        expect(cell.frames, [_frame(3)]);
+      }
+    });
+
+    test('resizes a 2x2 draft back to a valid 1x1 center', () {
+      final base = _legacyPathPreset(id: 'legacy-water');
+      final draft = resizePathPatternDraftCenter(
+        draft: createInitialPathPatternDraft(basePathPreset: base),
+        basePathPreset: base,
+        width: 2,
+        height: 2,
+      );
+
+      final resized = resizePathPatternDraftCenter(
+        draft: draft,
+        basePathPreset: base,
+        width: 1,
+        height: 1,
+      );
+
+      expect(resized.centerPattern.size,
+          PathCenterPatternSize(width: 1, height: 1));
+      expect(resized.centerPattern.cells, hasLength(1));
+      expect(resized.selectedCellX, 0);
+      expect(resized.selectedCellY, 0);
+    });
+
+    test('changes base while preserving name and current size', () {
+      final water = _legacyPathPreset(id: 'legacy-water', crossSourceX: 1);
+      final sand = _legacyPathPreset(id: 'legacy-sand', crossSourceX: 9);
+      final draft = renamePathPatternDraft(
+        createInitialPathPatternDraft(basePathPreset: water),
+        'Nom conservé',
+      );
+      final twoByTwo = resizePathPatternDraftCenter(
+        draft: draft,
+        basePathPreset: water,
+        width: 2,
+        height: 2,
+      );
+
+      final changed = changePathPatternDraftBase(
+        draft: twoByTwo,
+        basePathPreset: sand,
+      );
+
+      expect(changed.name, 'Nom conservé');
+      expect(changed.basePathPresetId, 'legacy-sand');
+      expect(changed.centerPattern.size,
+          PathCenterPatternSize(width: 2, height: 2));
+      expect(changed.centerPattern.cellAt(1, 1).frames, [_frame(9)]);
+    });
+
+    test('empty draft name exposes a local nameRequired issue', () {
+      final draft = renamePathPatternDraft(
+        createInitialPathPatternDraft(
+            basePathPreset: _legacyPathPreset(id: 'legacy-water')),
+        '   ',
+      );
+
+      expect(draft.issues, [PathPatternDraftIssueCode.nameRequired]);
+    });
+  });
+}
+
+ProjectPathPreset _legacyPathPreset({
+  required String id,
+  int crossSourceX = 0,
+}) {
+  return ProjectPathPreset(
+    id: id,
+    name: id,
+    surfaceKind: PathSurfaceKind.water,
+    variants: [
+      PathPresetVariantMapping(
+        variant: TerrainPathVariant.cross,
+        frames: [_frame(crossSourceX)],
+      ),
+    ],
+  );
+}
+
+TilesetVisualFrame _frame(int sourceX) {
+  return TilesetVisualFrame(
+    source: TilesetSourceRect(x: sourceX, y: 0),
+  );
+}
```

### 18.3 Contenu complet des fichiers créés

#### packages/map_editor/lib/src/features/path_studio/path_pattern_draft.dart

```dart
import 'package:map_core/map_core.dart';

/// Issues locales propres au brouillon Path Studio.
///
/// Elles ne sont pas des erreurs de manifest : le brouillon n'est pas encore
/// persistant. Le but est seulement de guider l'utilisateur pendant l'édition
/// locale V0.
enum PathPatternDraftIssueCode {
  nameRequired,
}

/// Brouillon local et non sauvegardé d'un `ProjectPathPatternPreset`.
///
/// Ce modèle vit côté `map_editor` parce qu'il décrit un état d'édition UI,
/// pas un contrat projet. Il ne mute jamais le `ProjectManifest`.
final class PathPatternDraft {
  PathPatternDraft({
    required this.id,
    required this.name,
    required this.basePathPresetId,
    required this.centerPattern,
    this.transparentColor,
    this.categoryId,
    required this.sortOrder,
    required this.selectedCellX,
    required this.selectedCellY,
    required this.isDirty,
  });

  final String id;
  final String name;
  final String basePathPresetId;
  final PathCenterPattern centerPattern;
  final TilesetTransparentColor? transparentColor;
  final String? categoryId;
  final int sortOrder;
  final int selectedCellX;
  final int selectedCellY;
  final bool isDirty;

  String get centerPatternLabel =>
      '${centerPattern.size.width}×${centerPattern.size.height}';

  int get centerCellCount => centerPattern.cells.length;

  int get centerFrameCount => centerPattern.cells.fold(
        0,
        (total, cell) => total + cell.frames.length,
      );

  int get animatedCellCount =>
      centerPattern.cells.where((cell) => cell.frames.length > 1).length;

  PathCenterPatternCell get selectedCell =>
      centerPattern.cellAt(selectedCellX, selectedCellY);

  List<PathPatternDraftIssueCode> get issues {
    final result = <PathPatternDraftIssueCode>[];
    if (name.trim().isEmpty) {
      result.add(PathPatternDraftIssueCode.nameRequired);
    }
    return List<PathPatternDraftIssueCode>.unmodifiable(result);
  }

  PathPatternDraft copyWith({
    String? id,
    String? name,
    String? basePathPresetId,
    PathCenterPattern? centerPattern,
    TilesetTransparentColor? transparentColor,
    String? categoryId,
    int? sortOrder,
    int? selectedCellX,
    int? selectedCellY,
    bool? isDirty,
  }) {
    return PathPatternDraft(
      id: id ?? this.id,
      name: name ?? this.name,
      basePathPresetId: basePathPresetId ?? this.basePathPresetId,
      centerPattern: centerPattern ?? this.centerPattern,
      transparentColor: transparentColor ?? this.transparentColor,
      categoryId: categoryId ?? this.categoryId,
      sortOrder: sortOrder ?? this.sortOrder,
      selectedCellX: selectedCellX ?? this.selectedCellX,
      selectedCellY: selectedCellY ?? this.selectedCellY,
      isDirty: isDirty ?? this.isDirty,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PathPatternDraft &&
            id == other.id &&
            name == other.name &&
            basePathPresetId == other.basePathPresetId &&
            centerPattern == other.centerPattern &&
            transparentColor == other.transparentColor &&
            categoryId == other.categoryId &&
            sortOrder == other.sortOrder &&
            selectedCellX == other.selectedCellX &&
            selectedCellY == other.selectedCellY &&
            isDirty == other.isDirty;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        basePathPresetId,
        centerPattern,
        transparentColor,
        categoryId,
        sortOrder,
        selectedCellX,
        selectedCellY,
        isDirty,
      );
}

PathPatternDraft? createInitialPathPatternDraftFromManifest({
  required ProjectManifest manifest,
}) {
  if (manifest.pathPresets.isEmpty) {
    return null;
  }
  return createInitialPathPatternDraft(
    basePathPreset: manifest.pathPresets.first,
    sortOrder: manifest.pathPatternPresets.length,
  );
}

PathPatternDraft createInitialPathPatternDraft({
  required ProjectPathPreset basePathPreset,
  int sortOrder = 0,
}) {
  return PathPatternDraft(
    id: 'draft-path-pattern',
    name: 'Nouveau motif de chemin',
    basePathPresetId: basePathPreset.id,
    centerPattern: rebuildDraftCenterPattern(
      basePathPreset: basePathPreset,
      size: PathCenterPatternSize(width: 1, height: 1),
    ),
    categoryId: null,
    sortOrder: sortOrder,
    selectedCellX: 0,
    selectedCellY: 0,
    isDirty: true,
  );
}

PathCenterPattern rebuildDraftCenterPattern({
  required ProjectPathPreset basePathPreset,
  required PathCenterPatternSize size,
}) {
  final centerView = createLegacyProjectPathPresetCenterPatternView(
    preset: basePathPreset,
    centerVariant: TerrainPathVariant.cross,
  );
  final frames = centerView.centerPattern.cellAt(0, 0).frames;
  final cells = <PathCenterPatternCell>[];
  for (var y = 0; y < size.height; y += 1) {
    for (var x = 0; x < size.width; x += 1) {
      cells.add(
        PathCenterPatternCell(
          localX: x,
          localY: y,
          frames: frames,
        ),
      );
    }
  }
  return PathCenterPattern(size: size, cells: cells);
}

PathPatternDraft resizePathPatternDraftCenter({
  required PathPatternDraft draft,
  required ProjectPathPreset basePathPreset,
  required int width,
  required int height,
}) {
  final size = PathCenterPatternSize(width: width, height: height);
  return draft.copyWith(
    centerPattern: rebuildDraftCenterPattern(
      basePathPreset: basePathPreset,
      size: size,
    ),
    selectedCellX: draft.selectedCellX.clamp(0, width - 1).toInt(),
    selectedCellY: draft.selectedCellY.clamp(0, height - 1).toInt(),
    isDirty: true,
  );
}

PathPatternDraft changePathPatternDraftBase({
  required PathPatternDraft draft,
  required ProjectPathPreset basePathPreset,
}) {
  return draft.copyWith(
    basePathPresetId: basePathPreset.id,
    centerPattern: rebuildDraftCenterPattern(
      basePathPreset: basePathPreset,
      size: draft.centerPattern.size,
    ),
    isDirty: true,
  );
}

PathPatternDraft renamePathPatternDraft(
  PathPatternDraft draft,
  String name,
) {
  return draft.copyWith(name: name, isDirty: true);
}

PathPatternDraft selectPathPatternDraftCell({
  required PathPatternDraft draft,
  required int localX,
  required int localY,
}) {
  // `cellAt` intentionally performs the bounds validation for this local
  // editor state. A failing caller should surface during tests rather than
  // silently selecting a different cell.
  draft.centerPattern.cellAt(localX, localY);
  return draft.copyWith(
    selectedCellX: localX,
    selectedCellY: localY,
  );
}
```

#### packages/map_editor/test/path_pattern/path_pattern_draft_test.dart

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/path_studio/path_pattern_draft.dart';

void main() {
  group('PathPatternDraft', () {
    test('creates an initial draft from the legacy cross center', () {
      final draft = createInitialPathPatternDraft(
        basePathPreset: _legacyPathPreset(id: 'legacy-water', crossSourceX: 7),
      );

      expect(draft.id, 'draft-path-pattern');
      expect(draft.name, 'Nouveau motif de chemin');
      expect(draft.basePathPresetId, 'legacy-water');
      expect(
          draft.centerPattern.size, PathCenterPatternSize(width: 1, height: 1));
      expect(draft.centerPattern.cellAt(0, 0).frames, [_frame(7)]);
      expect(draft.isDirty, isTrue);
      expect(draft.selectedCellX, 0);
      expect(draft.selectedCellY, 0);
      expect(draft.issues, isEmpty);
    });

    test('returns null when a manifest has no legacy base path preset', () {
      final draft = createInitialPathPatternDraftFromManifest(
        manifest: ProjectManifest(
          name: 'Project',
          maps: const [],
          tilesets: const [],
          surfaceCatalog: ProjectSurfaceCatalog(),
        ),
      );

      expect(draft, isNull);
    });

    test('resizes a 1x1 draft to a 2x2 center with copied cross frames', () {
      final base = _legacyPathPreset(id: 'legacy-water', crossSourceX: 3);
      final draft = createInitialPathPatternDraft(basePathPreset: base);

      final resized = resizePathPatternDraftCenter(
        draft: draft,
        basePathPreset: base,
        width: 2,
        height: 2,
      );

      expect(resized.centerPattern.size,
          PathCenterPatternSize(width: 2, height: 2));
      expect(
          resized.centerPattern.cells.map((cell) => (cell.localX, cell.localY)),
          [
            (0, 0),
            (1, 0),
            (0, 1),
            (1, 1),
          ]);
      for (final cell in resized.centerPattern.cells) {
        expect(cell.frames, [_frame(3)]);
      }
    });

    test('resizes a 2x2 draft back to a valid 1x1 center', () {
      final base = _legacyPathPreset(id: 'legacy-water');
      final draft = resizePathPatternDraftCenter(
        draft: createInitialPathPatternDraft(basePathPreset: base),
        basePathPreset: base,
        width: 2,
        height: 2,
      );

      final resized = resizePathPatternDraftCenter(
        draft: draft,
        basePathPreset: base,
        width: 1,
        height: 1,
      );

      expect(resized.centerPattern.size,
          PathCenterPatternSize(width: 1, height: 1));
      expect(resized.centerPattern.cells, hasLength(1));
      expect(resized.selectedCellX, 0);
      expect(resized.selectedCellY, 0);
    });

    test('changes base while preserving name and current size', () {
      final water = _legacyPathPreset(id: 'legacy-water', crossSourceX: 1);
      final sand = _legacyPathPreset(id: 'legacy-sand', crossSourceX: 9);
      final draft = renamePathPatternDraft(
        createInitialPathPatternDraft(basePathPreset: water),
        'Nom conservé',
      );
      final twoByTwo = resizePathPatternDraftCenter(
        draft: draft,
        basePathPreset: water,
        width: 2,
        height: 2,
      );

      final changed = changePathPatternDraftBase(
        draft: twoByTwo,
        basePathPreset: sand,
      );

      expect(changed.name, 'Nom conservé');
      expect(changed.basePathPresetId, 'legacy-sand');
      expect(changed.centerPattern.size,
          PathCenterPatternSize(width: 2, height: 2));
      expect(changed.centerPattern.cellAt(1, 1).frames, [_frame(9)]);
    });

    test('empty draft name exposes a local nameRequired issue', () {
      final draft = renamePathPatternDraft(
        createInitialPathPatternDraft(
            basePathPreset: _legacyPathPreset(id: 'legacy-water')),
        '   ',
      );

      expect(draft.issues, [PathPatternDraftIssueCode.nameRequired]);
    });
  });
}

ProjectPathPreset _legacyPathPreset({
  required String id,
  int crossSourceX = 0,
}) {
  return ProjectPathPreset(
    id: id,
    name: id,
    surfaceKind: PathSurfaceKind.water,
    variants: [
      PathPresetVariantMapping(
        variant: TerrainPathVariant.cross,
        frames: [_frame(crossSourceX)],
      ),
    ],
  );
}

TilesetVisualFrame _frame(int sourceX) {
  return TilesetVisualFrame(
    source: TilesetSourceRect(x: sourceX, y: 0),
  );
}
```

### 18.4 Contenu complet des fichiers modifiés

#### packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';

import '../editor/state/editor_selectors.dart';
import 'path_pattern_draft.dart';
import 'path_pattern_editor_read_model.dart';
import 'path_studio_theme.dart';

/// Workspace branché au shell global de l'éditeur.
///
/// Ce wrapper Riverpod reste volontairement fin : il lit seulement le manifest
/// courant et délègue tout le rendu read-only à [PathStudioPanel]. Le lot 13 ne
/// crée ni repository, ni provider dédié, ni contrôleur de sauvegarde.
class PathStudioWorkspace extends ConsumerWidget {
  const PathStudioWorkspace({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final manifest = ref.watch(editorProjectManifestProvider);
    if (manifest == null) {
      return const _PathStudioProjectMissingState();
    }
    return PathStudioPanel(manifest: manifest);
  }
}

/// Shell visuel read-only du Path Studio.
///
/// Le widget reçoit un [ProjectManifest] explicite pour rester testable sans
/// dépendance à l'infrastructure éditeur. Toute l'information métier affichée
/// passe par le read model du lot 12 : aucune logique de diagnostic PathPattern
/// n'est recalculée ici.
class PathStudioPanel extends StatefulWidget {
  const PathStudioPanel({
    super.key,
    required this.manifest,
  });

  final ProjectManifest manifest;

  @override
  State<PathStudioPanel> createState() => _PathStudioPanelState();
}

class _PathStudioPanelState extends State<PathStudioPanel> {
  String _searchQuery = '';
  PathPatternDraft? _draft;
  bool _draftSelected = false;
  String? _draftMessage;

  /// Index dans `readModel.presets`, pas id métier.
  ///
  /// Les ids dupliqués sont précisément un diagnostic V0 ; sélectionner par id
  /// rendrait une card ambiguë. L'index source garde donc une sélection stable
  /// même quand deux presets portent le même identifiant.
  int? _selectedSourceIndex;

  @override
  void didUpdateWidget(covariant PathStudioPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.manifest != widget.manifest) {
      _selectedSourceIndex = null;
      _draft = null;
      _draftSelected = false;
      _draftMessage = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final readModel = createPathPatternEditorReadModel(
      manifest: widget.manifest,
    );
    final query = _searchQuery.trim().toLowerCase();
    final filtered = _filteredCards(readModel, query);
    final selected = _draftSelected ? null : _selectedCard(filtered);
    final selectedDraft = _draftSelected ? _draft : null;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: PathStudioTheme.backgroundGradient,
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PathStudioHeader(
              summary: readModel.summary,
              onCreateDraft: _createDraft,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 292,
                    child: _PresetSidebar(
                      readModel: readModel,
                      filteredCards: filtered,
                      draft: _draft,
                      draftSelected: _draftSelected,
                      draftMatchesQuery: _draft == null ||
                          query.isEmpty ||
                          _matchesDraftQuery(_draft!, query),
                      draftMessage: _draftMessage,
                      selectedSourceIndex: selected?.sourceIndex,
                      onQueryChanged: (value) {
                        setState(() => _searchQuery = value);
                      },
                      onSelectDraft: () {
                        setState(() => _draftSelected = true);
                      },
                      onSelect: (sourceIndex) {
                        setState(() {
                          _draftSelected = false;
                          _selectedSourceIndex = sourceIndex;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _CenterWorkspace(
                      draft: selectedDraft,
                      selected: selected?.card,
                      hasAnyPreset: readModel.presets.isNotEmpty,
                      onDraftSizeChanged: _resizeDraft,
                      onDraftCellSelected: _selectDraftCell,
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 326,
                    child: _PresetInspector(
                      manifest: widget.manifest,
                      draft: selectedDraft,
                      selected: selected?.card,
                      onDraftNameChanged: _renameDraft,
                      onDraftBaseChanged: _changeDraftBase,
                      onDraftSizeChanged: _resizeDraft,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_IndexedPresetCard> _filteredCards(
    PathPatternEditorReadModel readModel,
    String query,
  ) {
    final indexed = <_IndexedPresetCard>[];
    for (var index = 0; index < readModel.presets.length; index += 1) {
      final card = readModel.presets[index];
      if (query.isEmpty || _matchesQuery(card, query)) {
        indexed.add(_IndexedPresetCard(index, card));
      }
    }
    return indexed;
  }

  bool _matchesQuery(PathPatternPresetCardModel card, String query) {
    final fields = [
      card.name,
      card.id,
      card.basePathPresetId,
      card.basePathPresetName,
      card.basePathSurfaceKindLabel,
      card.centerPatternLabel,
    ];
    return fields
        .whereType<String>()
        .any((field) => field.toLowerCase().contains(query));
  }

  bool _matchesDraftQuery(PathPatternDraft draft, String query) {
    final fields = [
      draft.name,
      draft.id,
      draft.basePathPresetId,
      draft.centerPatternLabel,
    ];
    return fields.any((field) => field.toLowerCase().contains(query));
  }

  _IndexedPresetCard? _selectedCard(List<_IndexedPresetCard> filtered) {
    if (filtered.isEmpty) {
      return null;
    }
    for (final entry in filtered) {
      if (entry.sourceIndex == _selectedSourceIndex) {
        return entry;
      }
    }
    return filtered.first;
  }

  void _createDraft() {
    if (widget.manifest.pathPresets.isEmpty) {
      setState(() {
        _draftMessage = 'Aucun preset Path de base disponible';
        _draftSelected = false;
      });
      return;
    }
    try {
      final draft = createInitialPathPatternDraftFromManifest(
        manifest: widget.manifest,
      );
      setState(() {
        _draft = draft;
        _draftSelected = draft != null;
        _draftMessage = draft == null
            ? 'Aucun preset Path de base disponible'
            : 'Brouillon non sauvegardé';
      });
    } on ArgumentError {
      setState(() {
        _draftMessage =
            'Le preset Path de base ne contient pas de centre cross';
        _draftSelected = false;
      });
    }
  }

  void _renameDraft(String name) {
    final draft = _draft;
    if (draft == null) {
      return;
    }
    setState(() => _draft = renamePathPatternDraft(draft, name));
  }

  void _resizeDraft(int width, int height) {
    final draft = _draft;
    final base = _basePathPresetForDraft(draft);
    if (draft == null || base == null) {
      return;
    }
    setState(() {
      _draft = resizePathPatternDraftCenter(
        draft: draft,
        basePathPreset: base,
        width: width,
        height: height,
      );
    });
  }

  void _changeDraftBase(String basePathPresetId) {
    final draft = _draft;
    if (draft == null) {
      return;
    }
    final base = _basePathPresetById(basePathPresetId);
    if (base == null) {
      return;
    }
    setState(() {
      _draft = changePathPatternDraftBase(
        draft: draft,
        basePathPreset: base,
      );
    });
  }

  void _selectDraftCell(int localX, int localY) {
    final draft = _draft;
    if (draft == null) {
      return;
    }
    setState(() {
      _draft = selectPathPatternDraftCell(
        draft: draft,
        localX: localX,
        localY: localY,
      );
    });
  }

  ProjectPathPreset? _basePathPresetForDraft(PathPatternDraft? draft) {
    if (draft == null) {
      return null;
    }
    return _basePathPresetById(draft.basePathPresetId);
  }

  ProjectPathPreset? _basePathPresetById(String id) {
    for (final preset in widget.manifest.pathPresets) {
      if (preset.id == id) {
        return preset;
      }
    }
    return null;
  }
}

class _IndexedPresetCard {
  const _IndexedPresetCard(this.sourceIndex, this.card);

  final int sourceIndex;
  final PathPatternPresetCardModel card;
}

class _PathStudioProjectMissingState extends StatelessWidget {
  const _PathStudioProjectMissingState();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: PathStudioTheme.background,
      child: Center(
        child: Text(
          'Charger un projet pour ouvrir Path Studio.',
          style: TextStyle(
            color: PathStudioTheme.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _PathStudioHeader extends StatelessWidget {
  const _PathStudioHeader({
    required this.summary,
    required this.onCreateDraft,
  });

  final PathPatternEditorSummary summary;
  final VoidCallback onCreateDraft;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: PathStudioTheme.panelDecoration(
        color: PathStudioTheme.surface,
        radius: 24,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  PathStudioTheme.accentHover,
                  PathStudioTheme.accent,
                ],
              ),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: PathStudioTheme.accentHover.withValues(alpha: 0.8),
              ),
            ),
            child: const MacosIcon(
              CupertinoIcons.arrow_branch,
              color: CupertinoColors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Path Studio',
                  style: TextStyle(
                    color: PathStudioTheme.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Créer des motifs de chemin',
                  style: TextStyle(
                    color: PathStudioTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          _SummaryPill(label: 'Presets', value: '${summary.totalCount}'),
          const SizedBox(width: 8),
          _SummaryPill(label: 'Prêts', value: '${summary.readyCount}'),
          const SizedBox(width: 12),
          _ShellActionButton(
            icon: CupertinoIcons.plus,
            label: 'Nouveau preset',
            hint: 'brouillon local',
            onPressed: onCreateDraft,
          ),
          const SizedBox(width: 8),
          const _ShellActionButton(
            icon: CupertinoIcons.square_on_square,
            label: 'Dupliquer',
            hint: 'lot futur',
          ),
          const SizedBox(width: 8),
          const _ShellActionButton(
            icon: CupertinoIcons.floppy_disk,
            label: 'Enregistrer',
            hint: 'lot futur',
          ),
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: PathStudioTheme.surfaceRaised,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: PathStudioTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: PathStudioTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: PathStudioTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShellActionButton extends StatelessWidget {
  const _ShellActionButton({
    required this.icon,
    required this.label,
    this.hint = 'lot futur',
    this.onPressed,
  });

  final IconData icon;
  final String label;
  final String hint;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      minimumSize: Size.zero,
      onPressed: onPressed,
      disabledColor: PathStudioTheme.surfaceRaised.withValues(alpha: 0.72),
      color: PathStudioTheme.accent,
      borderRadius: BorderRadius.circular(13),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MacosIcon(
            icon,
            color: onPressed == null
                ? PathStudioTheme.textMuted.withValues(alpha: 0.72)
                : CupertinoColors.white,
            size: 15,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: onPressed == null
                      ? PathStudioTheme.textSecondary.withValues(alpha: 0.7)
                      : CupertinoColors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                hint,
                style: TextStyle(
                  color: onPressed == null
                      ? PathStudioTheme.textMuted
                      : CupertinoColors.white.withValues(alpha: 0.72),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PresetSidebar extends StatelessWidget {
  const _PresetSidebar({
    required this.readModel,
    required this.filteredCards,
    required this.draft,
    required this.draftSelected,
    required this.draftMatchesQuery,
    required this.draftMessage,
    required this.selectedSourceIndex,
    required this.onQueryChanged,
    required this.onSelectDraft,
    required this.onSelect,
  });

  final PathPatternEditorReadModel readModel;
  final List<_IndexedPresetCard> filteredCards;
  final PathPatternDraft? draft;
  final bool draftSelected;
  final bool draftMatchesQuery;
  final String? draftMessage;
  final int? selectedSourceIndex;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onSelectDraft;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: PathStudioTheme.panelDecoration(),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Presets',
                  style: TextStyle(
                    color: PathStudioTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _SidebarCounter(value: readModel.summary.totalCount),
            ],
          ),
          const SizedBox(height: 12),
          CupertinoTextField(
            key: const Key('path-studio-search-field'),
            onChanged: onQueryChanged,
            placeholder: 'Rechercher un preset...',
            prefix: const Padding(
              padding: EdgeInsets.only(left: 10),
              child: MacosIcon(
                CupertinoIcons.search,
                size: 15,
                color: PathStudioTheme.textMuted,
              ),
            ),
            style: const TextStyle(
              color: PathStudioTheme.textPrimary,
              fontSize: 13,
            ),
            placeholderStyle: const TextStyle(
              color: PathStudioTheme.textMuted,
              fontSize: 13,
            ),
            decoration: BoxDecoration(
              color: PathStudioTheme.surfaceStrong,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: PathStudioTheme.border),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _buildPresetList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetList() {
    final draftCard = draft;
    if (readModel.presets.isEmpty && draftCard == null) {
      return _SidebarNotice(
        title: 'Aucun motif PathPattern',
        message: draftMessage ??
            'Cliquez sur Nouveau preset pour créer un brouillon local.',
      );
    }
    if (filteredCards.isEmpty &&
        (draftCard == null || draftMatchesQuery == false)) {
      return const _SidebarNotice(
        title: 'Aucun preset trouvé',
        message: 'Essayez un autre nom, id ou preset de base.',
      );
    }
    return ListView.separated(
      itemCount: filteredCards.length +
          (draftCard != null && draftMatchesQuery ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (draftCard != null && draftMatchesQuery && index == 0) {
          return _DraftListCard(
            draft: draftCard,
            selected: draftSelected,
            onTap: onSelectDraft,
          );
        }
        final presetIndex =
            draftCard != null && draftMatchesQuery ? index - 1 : index;
        final entry = filteredCards[presetIndex];
        return _PresetListCard(
          key: Key('path-studio-preset-card-${entry.sourceIndex}'),
          card: entry.card,
          selected: entry.sourceIndex == selectedSourceIndex,
          onTap: () => onSelect(entry.sourceIndex),
        );
      },
    );
  }
}

class _DraftListCard extends StatelessWidget {
  const _DraftListCard({
    required this.draft,
    required this.selected,
    required this.onTap,
  });

  final PathPatternDraft draft;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        key: const Key('path-studio-draft-card'),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? Color.lerp(
                  PathStudioTheme.surfaceStrong,
                  PathStudioTheme.accentCyan,
                  0.22,
                )
              : PathStudioTheme.surfaceRaised,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? PathStudioTheme.accentCyan
                : PathStudioTheme.accentCyan.withValues(alpha: 0.4),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    draft.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: PathStudioTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const _StatusChip(
                  label: 'Brouillon',
                  color: PathStudioTheme.accentCyan,
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Brouillon local • Non sauvegardé',
              style: TextStyle(
                color: PathStudioTheme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _MiniMetric(
                  icon: CupertinoIcons.square_grid_2x2,
                  label: draft.centerPatternLabel,
                ),
                const SizedBox(width: 8),
                _MiniMetric(
                  icon: draft.animatedCellCount > 0
                      ? CupertinoIcons.play_circle
                      : CupertinoIcons.circle,
                  label: draft.animatedCellCount > 0 ? 'animé' : 'statique',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarCounter extends StatelessWidget {
  const _SidebarCounter({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: PathStudioTheme.accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border:
            Border.all(color: PathStudioTheme.accent.withValues(alpha: 0.4)),
      ),
      child: Text(
        '$value',
        style: const TextStyle(
          color: PathStudioTheme.accentHover,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SidebarNotice extends StatelessWidget {
  const _SidebarNotice({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: PathStudioTheme.subtleDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MacosIcon(
              CupertinoIcons.tray,
              color: PathStudioTheme.textMuted,
              size: 26,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: PathStudioTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: PathStudioTheme.textMuted,
                fontSize: 11,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetListCard extends StatefulWidget {
  const _PresetListCard({
    super.key,
    required this.card,
    required this.selected,
    required this.onTap,
  });

  final PathPatternPresetCardModel card;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_PresetListCard> createState() => _PresetListCardState();
}

class _PresetListCardState extends State<_PresetListCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final status = _statusPresentation(widget.card.status);
    final borderColor = widget.selected
        ? PathStudioTheme.accentHover
        : widget.card.status == PathPatternPresetReadinessStatus.blocked
            ? PathStudioTheme.error.withValues(alpha: 0.45)
            : PathStudioTheme.border;
    final fill = widget.selected
        ? Color.lerp(
            PathStudioTheme.surfaceStrong, PathStudioTheme.accent, 0.2)!
        : _hovered
            ? Color.lerp(
                PathStudioTheme.surfaceRaised,
                PathStudioTheme.accent,
                0.08,
              )!
            : PathStudioTheme.surfaceRaised;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: borderColor, width: widget.selected ? 2 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.card.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: PathStudioTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _StatusChip(label: status.label, color: status.color),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.card.id,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: PathStudioTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _MiniMetric(
                    icon: CupertinoIcons.square_grid_2x2,
                    label: widget.card.centerPatternLabel,
                  ),
                  const SizedBox(width: 8),
                  _MiniMetric(
                    icon: widget.card.animatedCellCount > 0
                        ? CupertinoIcons.play_circle
                        : CupertinoIcons.circle,
                    label: widget.card.animatedCellCount > 0
                        ? 'animé'
                        : 'statique',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.48)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MacosIcon(icon, size: 12, color: PathStudioTheme.textMuted),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: PathStudioTheme.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _CenterWorkspace extends StatelessWidget {
  const _CenterWorkspace({
    required this.draft,
    required this.selected,
    required this.hasAnyPreset,
    required this.onDraftSizeChanged,
    required this.onDraftCellSelected,
  });

  final PathPatternDraft? draft;
  final PathPatternPresetCardModel? selected;
  final bool hasAnyPreset;
  final void Function(int width, int height) onDraftSizeChanged;
  final void Function(int localX, int localY) onDraftCellSelected;

  @override
  Widget build(BuildContext context) {
    final draft = this.draft;
    if (draft != null) {
      return _DraftCenterWorkspace(
        draft: draft,
        onSizeChanged: onDraftSizeChanged,
        onCellSelected: onDraftCellSelected,
      );
    }
    final card = selected;
    if (card == null) {
      return _NoSelectionCenter(hasAnyPreset: hasAnyPreset);
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _WorkflowSteps(status: card.status),
          const SizedBox(height: 14),
          _SelectedSummary(card: card),
          const SizedBox(height: 14),
          _CenterPatternPlaceholder(card: card),
          const SizedBox(height: 14),
          _DiagnosticsCard(card: card),
        ],
      ),
    );
  }
}

class _DraftCenterWorkspace extends StatelessWidget {
  const _DraftCenterWorkspace({
    required this.draft,
    required this.onSizeChanged,
    required this.onCellSelected,
  });

  final PathPatternDraft draft;
  final void Function(int width, int height) onSizeChanged;
  final void Function(int localX, int localY) onCellSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _DraftBanner(),
          const SizedBox(height: 14),
          const _WorkflowSteps(
            status: PathPatternPresetReadinessStatus.needsReview,
          ),
          const SizedBox(height: 14),
          _DraftSummary(draft: draft),
          const SizedBox(height: 14),
          _DraftCenterPatternEditor(
            draft: draft,
            onSizeChanged: onSizeChanged,
            onCellSelected: onCellSelected,
          ),
          const SizedBox(height: 14),
          _DraftDiagnosticsCard(draft: draft),
        ],
      ),
    );
  }
}

class _DraftBanner extends StatelessWidget {
  const _DraftBanner();

  @override
  Widget build(BuildContext context) {
    return const _SectionCard(
      title: 'Brouillon local',
      icon: CupertinoIcons.pencil_outline,
      trailing: _StatusChip(
        label: 'Non sauvegardé',
        color: PathStudioTheme.warning,
      ),
      child: Text(
        'Ce brouillon vit uniquement en mémoire. Il sera enregistrable dans un lot futur.',
        style: TextStyle(
          color: PathStudioTheme.textSecondary,
          fontSize: 13,
          height: 1.4,
        ),
      ),
    );
  }
}

class _DraftSummary extends StatelessWidget {
  const _DraftSummary({required this.draft});

  final PathPatternDraft draft;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Résumé du brouillon',
      icon: CupertinoIcons.doc_text,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _InfoTile(label: 'Nom', value: draft.name),
          _InfoTile(label: 'Base', value: draft.basePathPresetId),
          _InfoTile(label: 'Centre', value: draft.centerPatternLabel),
          _InfoTile(label: 'Cellules', value: '${draft.centerCellCount}'),
          _InfoTile(label: 'Frames', value: '${draft.centerFrameCount}'),
          _InfoTile(
            label: 'Animation',
            value: '${draft.animatedCellCount} cellules',
          ),
          const _InfoTile(label: 'État', value: 'Brouillon non sauvegardé'),
        ],
      ),
    );
  }
}

class _DraftCenterPatternEditor extends StatelessWidget {
  const _DraftCenterPatternEditor({
    required this.draft,
    required this.onSizeChanged,
    required this.onCellSelected,
  });

  final PathPatternDraft draft;
  final void Function(int width, int height) onSizeChanged;
  final void Function(int localX, int localY) onCellSelected;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Motif du centre',
      icon: CupertinoIcons.square_grid_2x2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Le motif du centre sera répété dans les grandes zones pleines.',
            style: TextStyle(
              color: PathStudioTheme.textSecondary,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          CupertinoSlidingSegmentedControl<String>(
            key: const Key('path-studio-draft-size-control'),
            groupValue: draft.centerPatternLabel,
            onValueChanged: (value) {
              if (value == '1×1') {
                onSizeChanged(1, 1);
              } else if (value == '2×2') {
                onSizeChanged(2, 2);
              }
            },
            children: const {
              '1×1': Padding(
                key: Key('path-studio-draft-size-1x1'),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                child: Text('1×1'),
              ),
              '2×2': Padding(
                key: Key('path-studio-draft-size-2x2'),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                child: Text('2×2'),
              ),
            },
          ),
          const SizedBox(height: 18),
          _DraftPatternGrid(
            draft: draft,
            onCellSelected: onCellSelected,
          ),
          const SizedBox(height: 14),
          _DraftSelectedCellDetails(draft: draft),
        ],
      ),
    );
  }
}

class _DraftPatternGrid extends StatelessWidget {
  const _DraftPatternGrid({
    required this.draft,
    required this.onCellSelected,
  });

  final PathPatternDraft draft;
  final void Function(int localX, int localY) onCellSelected;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    var labelCode = 'A'.codeUnitAt(0);
    for (var y = 0; y < draft.centerPattern.size.height; y += 1) {
      final cells = <Widget>[];
      for (var x = 0; x < draft.centerPattern.size.width; x += 1) {
        final cell = draft.centerPattern.cellAt(x, y);
        cells.add(
          _DraftPatternCell(
            key: Key('path-studio-draft-cell-$x-$y'),
            label: String.fromCharCode(labelCode),
            cell: cell,
            selected: draft.selectedCellX == x && draft.selectedCellY == y,
            onTap: () => onCellSelected(x, y),
          ),
        );
        labelCode += 1;
      }
      rows.add(Row(mainAxisSize: MainAxisSize.min, children: cells));
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: PathStudioTheme.subtleDecoration(
        color: PathStudioTheme.backgroundAlt,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: rows),
    );
  }
}

class _DraftPatternCell extends StatelessWidget {
  const _DraftPatternCell({
    super.key,
    required this.label,
    required this.cell,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final PathCenterPatternCell cell;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final source = cell.frames.first.source;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 112,
        height: 92,
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Color.lerp(
            PathStudioTheme.surfaceStrong,
            selected ? PathStudioTheme.accent : PathStudioTheme.accentCyan,
            selected ? 0.32 : 0.16,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? PathStudioTheme.accentHover
                : PathStudioTheme.accentCyan.withValues(alpha: 0.45),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: PathStudioTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            Text(
              '${cell.frames.length} frame${cell.frames.length > 1 ? 's' : ''}',
              style: const TextStyle(
                color: PathStudioTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              cell.frames.length > 1 ? 'animé' : 'statique',
              style: const TextStyle(
                color: PathStudioTheme.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'source ${source.x},${source.y}',
              style: const TextStyle(
                color: PathStudioTheme.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DraftSelectedCellDetails extends StatelessWidget {
  const _DraftSelectedCellDetails({required this.draft});

  final PathPatternDraft draft;

  @override
  Widget build(BuildContext context) {
    final cell = draft.selectedCell;
    final source = cell.frames.first.source;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: PathStudioTheme.subtleDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cellule sélectionnée',
            style: TextStyle(
              color: PathStudioTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Position ${cell.localX},${cell.localY}',
            style: const TextStyle(
              color: PathStudioTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            '${cell.frames.length} frame${cell.frames.length > 1 ? 's' : ''} • source ${source.x},${source.y}',
            style: const TextStyle(
              color: PathStudioTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DraftDiagnosticsCard extends StatelessWidget {
  const _DraftDiagnosticsCard({required this.draft});

  final PathPatternDraft draft;

  @override
  Widget build(BuildContext context) {
    final issues = draft.issues;
    return _SectionCard(
      title: 'Diagnostics locaux',
      icon: CupertinoIcons.check_mark_circled,
      child: issues.isEmpty
          ? const _DiagnosticRow(
              icon: CupertinoIcons.check_mark_circled_solid,
              color: PathStudioTheme.success,
              title: 'Aucune erreur locale',
              message: 'Le brouillon est éditable en mémoire.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: issues
                  .map(
                    (issue) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _DiagnosticRow(
                        icon: CupertinoIcons.exclamationmark_triangle_fill,
                        color: PathStudioTheme.warning,
                        title: _draftIssueLabel(issue),
                        message: _draftIssueDescription(issue),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
    );
  }
}

class _NoSelectionCenter extends StatelessWidget {
  const _NoSelectionCenter({required this.hasAnyPreset});

  final bool hasAnyPreset;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: PathStudioTheme.panelDecoration(
        color: PathStudioTheme.surface,
      ),
      padding: const EdgeInsets.all(28),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MacosIcon(
              CupertinoIcons.square_grid_2x2,
              color: PathStudioTheme.accentCyan,
              size: 44,
            ),
            const SizedBox(height: 16),
            Text(
              hasAnyPreset
                  ? 'Aucun preset sélectionné'
                  : 'Aucun motif PathPattern',
              style: const TextStyle(
                color: PathStudioTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasAnyPreset
                  ? 'Sélectionnez un preset dans la liste pour inspecter sa structure.'
                  : 'Les futurs lots permettront de créer un premier motif de centre.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: PathStudioTheme.textSecondary,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkflowSteps extends StatelessWidget {
  const _WorkflowSteps({required this.status});

  final PathPatternPresetReadinessStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: PathStudioTheme.panelDecoration(
        color: PathStudioTheme.surface,
        radius: 18,
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                const _StepPill(
                  index: 1,
                  label: 'Base',
                  active: false,
                  complete: true,
                ),
                const _StepArrow(),
                const _StepPill(
                  index: 2,
                  label: 'Motif du centre',
                  active: true,
                ),
                const _StepArrow(),
                _StepPill(
                  index: 3,
                  label: 'Aperçu',
                  active: false,
                  complete: status == PathPatternPresetReadinessStatus.ready,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepPill extends StatelessWidget {
  const _StepPill({
    required this.index,
    required this.label,
    required this.active,
    this.complete = false,
  });

  final int index;
  final String label;
  final bool active;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? PathStudioTheme.accentHover
        : complete
            ? PathStudioTheme.success
            : PathStudioTheme.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: active ? 0.2 : 0.11),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              complete ? '✓' : '$index',
              style: const TextStyle(
                color: CupertinoColors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: active ? PathStudioTheme.textPrimary : color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepArrow extends StatelessWidget {
  const _StepArrow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 10),
      child: MacosIcon(
        CupertinoIcons.chevron_right,
        size: 13,
        color: PathStudioTheme.textMuted,
      ),
    );
  }
}

class _SelectedSummary extends StatelessWidget {
  const _SelectedSummary({required this.card});

  final PathPatternPresetCardModel card;

  @override
  Widget build(BuildContext context) {
    final status = _statusPresentation(card.status);
    return _SectionCard(
      title: 'Résumé du preset',
      icon: CupertinoIcons.doc_text,
      trailing: _StatusChip(label: status.label, color: status.color),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _InfoTile(label: 'Nom', value: card.name),
          _InfoTile(
              label: 'Base', value: card.basePathPresetName ?? 'Introuvable'),
          _InfoTile(label: 'Centre', value: card.centerPatternLabel),
          _InfoTile(label: 'Cellules', value: '${card.centerCellCount}'),
          _InfoTile(label: 'Frames', value: '${card.centerFrameCount}'),
          _InfoTile(
              label: 'Animation', value: '${card.animatedCellCount} cellules'),
          _InfoTile(
            label: 'Transparent',
            value: card.transparentColorHex ?? 'Absent',
          ),
        ],
      ),
    );
  }
}

class _CenterPatternPlaceholder extends StatelessWidget {
  const _CenterPatternPlaceholder({required this.card});

  final PathPatternPresetCardModel card;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Motif du centre',
      icon: CupertinoIcons.square_grid_2x2,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MiniPatternGrid(card: card),
          const SizedBox(width: 18),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Éditeur read-only',
                  style: TextStyle(
                    color: PathStudioTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'L’édition 1×1 / 2×2 arrivera au lot 14. Cette zone pose seulement la structure du futur espace de travail, sans drag & drop ni génération PNG.',
                  style: TextStyle(
                    color: PathStudioTheme.textSecondary,
                    fontSize: 13,
                    height: 1.4,
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

class _MiniPatternGrid extends StatelessWidget {
  const _MiniPatternGrid({required this.card});

  final PathPatternPresetCardModel card;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    var labelCode = 'A'.codeUnitAt(0);
    for (var y = 0; y < card.centerHeight; y += 1) {
      final cells = <Widget>[];
      for (var x = 0; x < card.centerWidth; x += 1) {
        cells.add(_PatternCell(label: String.fromCharCode(labelCode)));
        labelCode += 1;
      }
      rows.add(Row(mainAxisSize: MainAxisSize.min, children: cells));
    }
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: PathStudioTheme.subtleDecoration(
        color: PathStudioTheme.backgroundAlt,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: rows),
    );
  }
}

class _PatternCell extends StatelessWidget {
  const _PatternCell({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Color.lerp(
          PathStudioTheme.surfaceStrong,
          PathStudioTheme.accentCyan,
          0.18,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: PathStudioTheme.accentCyan.withValues(alpha: 0.5)),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: PathStudioTheme.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _DiagnosticsCard extends StatelessWidget {
  const _DiagnosticsCard({required this.card});

  final PathPatternPresetCardModel card;

  @override
  Widget build(BuildContext context) {
    final issues = card.issues;
    return _SectionCard(
      title: 'Diagnostics',
      icon: CupertinoIcons.check_mark_circled,
      child: issues.isEmpty
          ? const _DiagnosticRow(
              icon: CupertinoIcons.check_mark_circled_solid,
              color: PathStudioTheme.success,
              title: 'Aucune erreur',
              message: 'Le preset est valide pour le shell V0.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: issues
                  .map(
                    (issue) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _DiagnosticRow(
                        icon: CupertinoIcons.exclamationmark_triangle_fill,
                        color: PathStudioTheme.error,
                        title: _issueLabel(issue),
                        message: _issueDescription(issue),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
    );
  }
}

class _PresetInspector extends StatelessWidget {
  const _PresetInspector({
    required this.manifest,
    required this.draft,
    required this.selected,
    required this.onDraftNameChanged,
    required this.onDraftBaseChanged,
    required this.onDraftSizeChanged,
  });

  final ProjectManifest manifest;
  final PathPatternDraft? draft;
  final PathPatternPresetCardModel? selected;
  final ValueChanged<String> onDraftNameChanged;
  final ValueChanged<String> onDraftBaseChanged;
  final void Function(int width, int height) onDraftSizeChanged;

  @override
  Widget build(BuildContext context) {
    final draft = this.draft;
    if (draft != null) {
      return _DraftInspector(
        manifest: manifest,
        draft: draft,
        onNameChanged: onDraftNameChanged,
        onBaseChanged: onDraftBaseChanged,
        onSizeChanged: onDraftSizeChanged,
      );
    }
    final card = selected;
    return Container(
      decoration: PathStudioTheme.panelDecoration(),
      padding: const EdgeInsets.all(16),
      child: card == null
          ? const _InspectorEmptyState()
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Propriétés du preset',
                    style: TextStyle(
                      color: PathStudioTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _InspectorRow(label: 'Nom', value: card.name),
                  _InspectorRow(label: 'ID', value: card.id),
                  _InspectorRow(
                    label: 'Base path preset id',
                    value: card.basePathPresetId,
                  ),
                  _InspectorRow(
                      label: 'Preset de base',
                      value: card.basePathPresetName ?? 'Introuvable'),
                  _InspectorRow(
                      label: 'Surface',
                      value: card.basePathSurfaceKindLabel ?? 'Non disponible'),
                  _InspectorRow(
                      label: 'Taille centre', value: card.centerPatternLabel),
                  _InspectorRow(
                      label: 'Cellules', value: '${card.centerCellCount}'),
                  _InspectorRow(
                      label: 'Frames', value: '${card.centerFrameCount}'),
                  _InspectorRow(
                      label: 'Cellules animées',
                      value: '${card.animatedCellCount}'),
                  _InspectorRow(
                      label: 'Transparent color',
                      value: card.transparentColorHex ?? 'Aucune'),
                  const SizedBox(height: 14),
                  _DiagnosticsCard(card: card),
                ],
              ),
            ),
    );
  }
}

class _DraftInspector extends StatelessWidget {
  const _DraftInspector({
    required this.manifest,
    required this.draft,
    required this.onNameChanged,
    required this.onBaseChanged,
    required this.onSizeChanged,
  });

  final ProjectManifest manifest;
  final PathPatternDraft draft;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onBaseChanged;
  final void Function(int width, int height) onSizeChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: PathStudioTheme.panelDecoration(),
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Propriétés du brouillon',
              style: TextStyle(
                color: PathStudioTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            const _StatusChip(
              label: 'Brouillon non sauvegardé',
              color: PathStudioTheme.warning,
            ),
            const SizedBox(height: 14),
            const _InspectorLabel('Nom'),
            CupertinoTextField(
              key: const Key('path-studio-draft-name-field'),
              placeholder: draft.name,
              onChanged: onNameChanged,
              style: const TextStyle(
                color: PathStudioTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              placeholderStyle: const TextStyle(
                color: PathStudioTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              decoration: BoxDecoration(
                color: PathStudioTheme.surfaceRaised,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: PathStudioTheme.border),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            ),
            const SizedBox(height: 12),
            const _InspectorLabel('Preset de base'),
            _DraftBasePopup(
              manifest: manifest,
              draft: draft,
              onBaseChanged: onBaseChanged,
            ),
            const SizedBox(height: 12),
            const _InspectorLabel('Taille du centre'),
            CupertinoSlidingSegmentedControl<String>(
              groupValue: draft.centerPatternLabel,
              onValueChanged: (value) {
                if (value == '1×1') {
                  onSizeChanged(1, 1);
                } else if (value == '2×2') {
                  onSizeChanged(2, 2);
                }
              },
              children: const {
                '1×1': Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Text('1×1'),
                ),
                '2×2': Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Text('2×2'),
                ),
              },
            ),
            const SizedBox(height: 14),
            _InspectorRow(label: 'ID temporaire', value: draft.id),
            _InspectorRow(
                label: 'Base path preset id', value: draft.basePathPresetId),
            _InspectorRow(label: 'Cellules', value: '${draft.centerCellCount}'),
            _InspectorRow(label: 'Frames', value: '${draft.centerFrameCount}'),
            _InspectorRow(
              label: 'Cellules animées',
              value: '${draft.animatedCellCount}',
            ),
            _InspectorRow(
              label: 'Transparent color',
              value: draft.transparentColor?.toHexRgb() ?? 'Aucune',
            ),
            const _InspectorRow(
              label: 'État',
              value: 'Brouillon non sauvegardé',
            ),
            const SizedBox(height: 14),
            _DraftDiagnosticsCard(draft: draft),
          ],
        ),
      ),
    );
  }
}

class _DraftBasePopup extends StatelessWidget {
  const _DraftBasePopup({
    required this.manifest,
    required this.draft,
    required this.onBaseChanged,
  });

  final ProjectManifest manifest;
  final PathPatternDraft draft;
  final ValueChanged<String> onBaseChanged;

  @override
  Widget build(BuildContext context) {
    return MacosPopupButton<String>(
      key: const Key('path-studio-draft-base-popup'),
      value: draft.basePathPresetId,
      onChanged: (value) {
        if (value != null) {
          onBaseChanged(value);
        }
      },
      items: [
        for (final preset in manifest.pathPresets)
          MacosPopupMenuItem<String>(
            value: preset.id,
            child: SizedBox(
              width: 220,
              child: Text(
                '${preset.name} (${preset.id})',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
      ],
    );
  }
}

class _InspectorLabel extends StatelessWidget {
  const _InspectorLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          color: PathStudioTheme.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InspectorEmptyState extends StatelessWidget {
  const _InspectorEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Propriétés du preset',
          style: TextStyle(
            color: PathStudioTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 18),
        _SidebarNotice(
          title: 'Aucun preset sélectionné',
          message: 'Les détails s’afficheront ici après sélection.',
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: PathStudioTheme.panelDecoration(
        color: PathStudioTheme.surface,
        radius: 20,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              MacosIcon(icon, color: PathStudioTheme.accentCyan, size: 18),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: PathStudioTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 138,
      padding: const EdgeInsets.all(12),
      decoration: PathStudioTheme.subtleDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: PathStudioTheme.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: PathStudioTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _InspectorRow extends StatelessWidget {
  const _InspectorRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: PathStudioTheme.subtleDecoration(
        color: PathStudioTheme.surfaceRaised,
        radius: 14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: PathStudioTheme.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: PathStudioTheme.textPrimary,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DiagnosticRow extends StatelessWidget {
  const _DiagnosticRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MacosIcon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: const TextStyle(
                    color: PathStudioTheme.textSecondary,
                    fontSize: 11.5,
                    height: 1.3,
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

_StatusPresentation _statusPresentation(
  PathPatternPresetReadinessStatus status,
) {
  return switch (status) {
    PathPatternPresetReadinessStatus.ready => const _StatusPresentation(
        label: 'Prêt',
        color: PathStudioTheme.success,
      ),
    PathPatternPresetReadinessStatus.needsReview => const _StatusPresentation(
        label: 'À vérifier',
        color: PathStudioTheme.warning,
      ),
    PathPatternPresetReadinessStatus.blocked => const _StatusPresentation(
        label: 'Bloqué',
        color: PathStudioTheme.error,
      ),
  };
}

class _StatusPresentation {
  const _StatusPresentation({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;
}

String _issueLabel(PathPatternPresetIssueCode issue) {
  return switch (issue) {
    PathPatternPresetIssueCode.missingBasePathPreset =>
      'Preset de base introuvable',
    PathPatternPresetIssueCode.duplicatePathPatternId =>
      'ID PathPattern dupliqué',
    PathPatternPresetIssueCode.duplicateBasePathPresetId =>
      'Preset de base dupliqué',
  };
}

String _issueDescription(PathPatternPresetIssueCode issue) {
  return switch (issue) {
    PathPatternPresetIssueCode.missingBasePathPreset =>
      'Le preset référence un basePathPresetId absent du manifest.',
    PathPatternPresetIssueCode.duplicatePathPatternId =>
      'Plusieurs PathPattern partagent exactement le même id.',
    PathPatternPresetIssueCode.duplicateBasePathPresetId =>
      'Plusieurs ProjectPathPreset legacy correspondent à la même base.',
  };
}

String _draftIssueLabel(PathPatternDraftIssueCode issue) {
  return switch (issue) {
    PathPatternDraftIssueCode.nameRequired => 'Nom requis',
  };
}

String _draftIssueDescription(PathPatternDraftIssueCode issue) {
  return switch (issue) {
    PathPatternDraftIssueCode.nameRequired =>
      'Le brouillon peut rester éditable, mais son nom devra être renseigné avant une future sauvegarde.',
  };
}
```

#### packages/map_editor/test/path_pattern/path_studio_panel_test.dart

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/path_studio/path_studio_panel.dart';

void main() {
  group('PathStudioPanel', () {
    testWidgets('renders a dark empty state when no PathPattern preset exists',
        (tester) async {
      await _pumpPathStudio(
        tester,
        manifest: _manifest(),
      );

      expect(find.text('Path Studio'), findsOneWidget);
      expect(find.text('Créer des motifs de chemin'), findsOneWidget);
      expect(find.text('Aucun motif PathPattern'), findsWidgets);
      expect(find.text('Aucun preset sélectionné'), findsOneWidget);
      expect(find.text('Propriétés du preset'), findsOneWidget);
    });

    testWidgets('lists presets and updates summary and inspector selection',
        (tester) async {
      await _pumpPathStudio(
        tester,
        manifest: _manifest(
          pathPresets: [
            _legacyPathPreset(id: 'legacy-water', name: 'Base eau'),
          ],
          pathPatternPresets: [
            _pathPatternPreset(
              id: 'water-sea-2x2',
              name: 'Mer 2x2',
              pattern: _twoByTwoPattern(animatedTopLeft: true),
              transparentColor: TilesetTransparentColor.fromHexRgb('f05ba1'),
            ),
            _pathPatternPreset(
              id: 'sand-broken',
              name: 'Sable cassé',
              basePathPresetId: 'missing-base',
            ),
          ],
        ),
      );

      expect(find.text('Mer 2x2'), findsWidgets);
      expect(find.text('Sable cassé'), findsOneWidget);
      expect(find.text('Prêt'), findsWidgets);
      expect(find.text('2×2'), findsWidgets);
      expect(find.text('water-sea-2x2'), findsWidgets);
      expect(find.text('f05ba1'), findsWidgets);

      await tester.tap(find.text('Sable cassé'));
      await tester.pumpAndSettle();

      expect(find.text('missing-base'), findsWidgets);
      expect(find.text('Bloqué'), findsWidgets);
      expect(find.text('Preset de base introuvable'), findsWidgets);
    });

    testWidgets('filters presets locally and clears selection on no result',
        (tester) async {
      await _pumpPathStudio(
        tester,
        manifest: _manifest(
          pathPresets: [
            _legacyPathPreset(id: 'legacy-water'),
          ],
          pathPatternPresets: [
            _pathPatternPreset(id: 'water-sea', name: 'Mer profonde'),
            _pathPatternPreset(id: 'stone-road', name: 'Route pavée'),
          ],
        ),
      );

      await tester.enterText(
        find.byKey(const Key('path-studio-search-field')),
        'pavée',
      );
      await tester.pumpAndSettle();

      expect(find.text('Route pavée'), findsWidgets);
      expect(find.text('Mer profonde'), findsNothing);
      expect(find.text('stone-road'), findsWidgets);

      await tester.enterText(
        find.byKey(const Key('path-studio-search-field')),
        'zzz',
      );
      await tester.pumpAndSettle();

      expect(find.text('Aucun preset trouvé'), findsOneWidget);
      expect(find.text('Aucun preset sélectionné'), findsWidgets);
    });

    testWidgets('creates a local draft from Nouveau preset', (tester) async {
      await _pumpPathStudio(
        tester,
        manifest: _manifest(
          pathPresets: [_legacyPathPreset(id: 'legacy-water')],
        ),
      );

      final newPresetButton = tester.widget<CupertinoButton>(
        find.widgetWithText(CupertinoButton, 'Nouveau preset'),
      );
      final duplicateButton = tester.widget<CupertinoButton>(
        find.widgetWithText(CupertinoButton, 'Dupliquer'),
      );
      final saveButton = tester.widget<CupertinoButton>(
        find.widgetWithText(CupertinoButton, 'Enregistrer'),
      );

      expect(newPresetButton.onPressed, isNotNull);
      expect(duplicateButton.onPressed, isNull);
      expect(saveButton.onPressed, isNull);
      expect(find.text('lot futur'), findsWidgets);

      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau preset'));
      await tester.pumpAndSettle();

      expect(find.text('Brouillon local'), findsWidgets);
      expect(find.text('Brouillon non sauvegardé'), findsWidgets);
      expect(find.text('Propriétés du brouillon'), findsOneWidget);
      expect(find.text('Nouveau motif de chemin'), findsWidgets);
      expect(find.text('1×1'), findsWidgets);
      expect(
          find.byKey(const Key('path-studio-draft-cell-0-0')), findsOneWidget);
    });

    testWidgets('resizes the local draft to 2x2 and selects a cell',
        (tester) async {
      await _pumpPathStudio(
        tester,
        manifest: _manifest(
          pathPresets: [_legacyPathPreset(id: 'legacy-water')],
        ),
      );

      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau preset'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('path-studio-draft-size-2x2')));
      await tester.pumpAndSettle();

      expect(
          find.byKey(const Key('path-studio-draft-cell-0-0')), findsOneWidget);
      expect(
          find.byKey(const Key('path-studio-draft-cell-1-0')), findsOneWidget);
      expect(
          find.byKey(const Key('path-studio-draft-cell-0-1')), findsOneWidget);
      expect(
          find.byKey(const Key('path-studio-draft-cell-1-1')), findsOneWidget);
      expect(find.text('A'), findsWidgets);
      expect(find.text('B'), findsWidgets);
      expect(find.text('C'), findsWidgets);
      expect(find.text('D'), findsWidgets);

      await tester.tap(find.byKey(const Key('path-studio-draft-cell-1-1')));
      await tester.pumpAndSettle();

      expect(find.text('Cellule sélectionnée'), findsWidgets);
      expect(find.text('Position 1,1'), findsWidgets);
    });

    testWidgets('edits draft name and keeps save disabled', (tester) async {
      await _pumpPathStudio(
        tester,
        manifest: _manifest(
          pathPresets: [_legacyPathPreset(id: 'legacy-water')],
        ),
      );

      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau preset'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('path-studio-draft-name-field')),
        'Mer brouillon',
      );
      await tester.pumpAndSettle();

      expect(find.text('Mer brouillon'), findsWidgets);
      final saveButton = tester.widget<CupertinoButton>(
        find.widgetWithText(CupertinoButton, 'Enregistrer'),
      );
      expect(saveButton.onPressed, isNull);
    });

    testWidgets('changes draft base locally without saving', (tester) async {
      await _pumpPathStudio(
        tester,
        manifest: _manifest(
          pathPresets: [
            _legacyPathPreset(id: 'legacy-water', name: 'Base eau'),
            _legacyPathPreset(
              id: 'legacy-sand',
              name: 'Base sable',
              crossSourceX: 5,
            ),
          ],
        ),
      );

      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau preset'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('path-studio-draft-name-field')),
        'Mer brouillon',
      );
      await tester.pumpAndSettle();

      final popup = tester.widget<MacosPopupButton<String>>(
        find.byKey(const Key('path-studio-draft-base-popup')),
      );
      popup.onChanged?.call('legacy-sand');
      await tester.pumpAndSettle();

      expect(find.text('Mer brouillon'), findsWidgets);
      expect(find.text('legacy-sand'), findsWidgets);
      expect(find.text('source 5,0'), findsWidgets);
      expect(find.text('Brouillon non sauvegardé'), findsWidgets);
    });

    testWidgets('empty draft name shows a local diagnostic', (tester) async {
      await _pumpPathStudio(
        tester,
        manifest: _manifest(
          pathPresets: [_legacyPathPreset(id: 'legacy-water')],
        ),
      );

      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau preset'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('path-studio-draft-name-field')),
        '   ',
      );
      await tester.pumpAndSettle();

      expect(find.text('Nom requis'), findsWidgets);
    });

    testWidgets('does not create a draft without legacy base path presets',
        (tester) async {
      await _pumpPathStudio(
        tester,
        manifest: _manifest(),
      );

      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau preset'));
      await tester.pumpAndSettle();

      expect(find.text('Aucun preset Path de base disponible'), findsWidgets);
      expect(find.text('Brouillon local'), findsNothing);
    });
  });
}

Future<void> _pumpPathStudio(
  WidgetTester tester, {
  required ProjectManifest manifest,
}) async {
  await tester.binding.setSurfaceSize(const Size(1440, 920));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    MacosApp(
      theme: MacosThemeData.dark(),
      home: MacosScaffold(
        children: [
          ContentArea(
            builder: (context, scrollController) {
              return PathStudioPanel(manifest: manifest);
            },
          ),
        ],
      ),
    ),
  );
  await tester.pumpAndSettle();
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

ProjectPathPreset _legacyPathPreset({
  required String id,
  String name = 'Legacy Water',
  int crossSourceX = 0,
}) {
  return ProjectPathPreset(
    id: id,
    name: name,
    surfaceKind: PathSurfaceKind.water,
    variants: [
      PathPresetVariantMapping(
        variant: TerrainPathVariant.cross,
        frames: [_frame(crossSourceX)],
      ),
    ],
  );
}

ProjectPathPatternPreset _pathPatternPreset({
  required String id,
  String? name,
  String basePathPresetId = 'legacy-water',
  PathCenterPattern? pattern,
  TilesetTransparentColor? transparentColor,
}) {
  return ProjectPathPatternPreset(
    id: id,
    name: name ?? id,
    basePathPresetId: basePathPresetId,
    centerPattern: pattern ?? _singleCellPattern(),
    transparentColor: transparentColor,
  );
}

PathCenterPattern _singleCellPattern() {
  return PathCenterPattern(
    size: PathCenterPatternSize(width: 1, height: 1),
    cells: [
      PathCenterPatternCell(
        localX: 0,
        localY: 0,
        frames: [_frame(0)],
      ),
    ],
  );
}

PathCenterPattern _twoByTwoPattern({bool animatedTopLeft = false}) {
  return PathCenterPattern(
    size: PathCenterPatternSize(width: 2, height: 2),
    cells: [
      PathCenterPatternCell(
        localX: 0,
        localY: 0,
        frames: animatedTopLeft ? [_frame(0), _frame(1)] : [_frame(0)],
      ),
      PathCenterPatternCell(localX: 1, localY: 0, frames: [_frame(2)]),
      PathCenterPatternCell(localX: 0, localY: 1, frames: [_frame(3)]),
      PathCenterPatternCell(localX: 1, localY: 1, frames: [_frame(4)]),
    ],
  );
}

TilesetVisualFrame _frame(int sourceX) {
  return TilesetVisualFrame(
    source: TilesetSourceRect(x: sourceX, y: 0),
  );
}
```

### 18.5 Contenu du rapport

Ce rapport est le fichier créé `reports/pathPattern/pathpattern_14_draft_editor_state_v0.md`. Son auto-inclusion complète dans lui-même créerait une récursion sans terminaison; cette limite est explicitée ici.

## 19. Auto-review

- Le draft est local et non persistant.

- Aucune mutation manifest n’est appelée.

- Le centre initial utilise `TerrainPathVariant.cross`.

- La taille 1×1 et 2×2 est testée.

- Le changement de base reconstruit le centre et conserve le nom.

- Le nom vide produit un diagnostic local sans bloquer l’édition.

- Enregistrer et Dupliquer restent désactivés.

- Aucun renderer PNG n’est appelé.

- Aucun map_core ou ProjectManifest n’est modifié.

- Les tests ciblés, régressions et analyze passent.

## 20. Review séparée

```text
Reviewer séparé: Pauli (sub-agent) — review-only, aucune modification.
Verdict: No findings.
Points vérifiés:
- Diff/status limité à map_editor.
- Aucun map_core, ProjectManifest, codec ou generated file modifié.
- Draft local dans path_pattern_draft.dart.
- Centre legacy construit via createLegacyProjectPathPresetCenterPatternView(..., TerrainPathVariant.cross).
- Nouveau preset activé; Dupliquer/Enregistrer sans onPressed.
- Couverture V0 présente pour création, resize/select, rename/save-disabled, base switch, missing base et diagnostics locaux.
Risque résiduel signalé: review sans tests/analyze car la vérification executable reste portée par l'agent principal.
```

## 21. Critique du prompt

Clair: le prompt bornait bien le lot à un brouillon local sans sauvegarde, avec les comportements 1×1/2×2 et base legacy attendus.

Ambigu: “beaucoup de commentaires utiles” peut pousser à commenter plus que le style habituel du repo. J’ai limité les commentaires aux frontières importantes: draft local, absence de persistance, validation par `cellAt`, et usage editor-only.

Discutable: demander le contenu complet de fichiers modifiés devient très lourd quand `path_studio_panel.dart` dépasse 2200 lignes. Le rapport l’inclut tout de même, mais le diff complet reste l’artefact de revue le plus utile.

Arbitrage: pas de helper `toProjectPathPatternPreset()` en V0. Il aurait été plausible, mais sans save flow il crée une tentation de persistance prématurée.

## 22. Risques / limites

- `path_studio_panel.dart` grossit fortement; un découpage en sous-widgets publics/privés sera probablement nécessaire si le Lot 15 ajoute plus d’interactions.

- Le popup base est testé via callback direct; un test d’ouverture menu complet serait plus proche utilisateur mais plus fragile avec `macos_ui`.

- Le draft ne couvre que 1×1/2×2, sans tile/frame picker. Toutes les cellules copient les frames cross, volontairement.

- Aucun golden visuel; les tests vérifient structure et comportement, pas pixel-perfect.

## 23. Prochaine étape recommandée

Lot 15 recommandé: extraire les sous-surfaces Path Studio si nécessaire et ajouter un mini picker local de cellule/frame ou une preview statique contrôlée, toujours sans sauvegarde tant que le modèle d’édition n’est pas stabilisé.

## 24. Checklist finale

- [x] Audit initial réalisé avant modification.

- [x] Git utilisé uniquement en lecture.

- [x] Aucun commit / push / reset / restore / stash / checkout.

- [x] map_core non modifié.

- [x] ProjectManifest non modifié.

- [x] Codecs PathPattern non modifiés.

- [x] Aucun generated file.

- [x] Aucun build_runner.

- [x] Aucun save flow.

- [x] Aucune mutation manifest.

- [x] Aucun painter.

- [x] Aucun canvas render.

- [x] Aucun runtime.

- [x] Aucun gameplay / battle.

- [x] Aucun tall grass.

- [x] Nouveau preset crée seulement un draft local.

- [x] Enregistrer reste désactivé ou non opérationnel.

- [x] Dupliquer reste désactivé ou non opérationnel.

- [x] La taille 1×1 fonctionne.

- [x] La taille 2×2 fonctionne.

- [x] Le centre initial utilise bien le centre legacy cross.

- [x] Les tests ciblés passent.

- [x] Les régressions pertinentes passent ou les échecs hors lot sont documentés.

- [x] Analyze ciblé passe.

- [x] Rapport final complet créé.

- [x] Auto-review faite.

- [x] Critique du prompt faite.
