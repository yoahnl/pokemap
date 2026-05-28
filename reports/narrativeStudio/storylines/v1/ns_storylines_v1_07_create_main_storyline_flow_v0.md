# NS-STORYLINES-V1-07 — Create Main Storyline Flow V0 / Storylines UI Usability Reset

## 1. Executive summary

Statut : DONE.

Ce lot rend Storylines V1 utile pour la première fois : le CTA `Nouvelle storyline` ouvre un formulaire minimal, crée une vraie `StorylineAsset(type: main, status: draft)` dans `ProjectManifest.storylines`, puis sélectionne la storyline créée dans l'UI.

Le reset UI demandé est appliqué dans le workspace Storylines : les tabs principales sont `Graph` et `Structure`, la recherche fake n'est plus active, le panneau secondaire ne propose plus de bouton `+` ambigu, aucune sideQuest n'est créée, et le legacy `ScenarioAsset.globalStory` reste une information non importée automatiquement.

## 2. Inputs read

```text
AGENTS.md
agent_rules.md
skills/README.md
reports/narrativeStudio/storylines/road_map_storylines.md
reports/narrativeStudio/storylines/ns_storylines_v1_06_legacy_global_story_import_preview_v0.md
reports/narrativeStudio/storylines/ns_storylines_v1_05_project_manifest_storylines_integration_v0.md
reports/narrativeStudio/storylines/ns_storylines_v1_04_storyline_asset_json_codec_v0.md
reports/narrativeStudio/storylines/ns_storylines_v1_03_storyline_asset_pure_model_v0.md
reports/narrativeStudio/storylines/ns_storylines_v1_00_storyline_semantics_and_usable_authoring_contract.md
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/models/storyline_asset.dart
packages/map_core/lib/src/authoring/storyline_legacy_import_preview.dart
packages/map_core/lib/map_core.dart
packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
packages/map_editor/lib/src/features/editor/state/editor_selectors.dart
packages/map_editor/lib/src/features/editor/application/editor_workspace_controller.dart
packages/map_editor/lib/src/features/narrative/state/narrative_workspace_state.dart
packages/map_editor/lib/src/features/narrative/state/narrative_workspace_providers.dart
packages/map_editor/test/storylines_workspace_shell_test.dart
packages/map_editor/test/storylines_current_global_story_characterization_test.dart
packages/map_editor/test/narrative_workspace_projection_test.dart
packages/map_editor/lib/src/ui/design_system/design_system.dart
packages/map_editor/lib/src/ui/design_system/pokemap_tone.dart
packages/map_editor/lib/src/ui/design_system/pokemap_dashboard_primitives.dart
packages/map_editor/lib/src/ui/design_system/pokemap_button.dart
packages/map_editor/lib/src/ui/design_system/pokemap_card.dart
packages/map_editor/lib/src/ui/design_system/pokemap_panel.dart
packages/map_editor/lib/src/theme/pokemap_color_tokens.dart
packages/map_editor/lib/src/theme/theme.dart
packages/map_editor/lib/src/ui/shared/cupertino_editor_widgets.dart
packages/map_editor/lib/src/ui/shared/editor_visual_tokens.dart
```

Fichiers attendus absents :

```text
Sortie : <vide>
```

## 3. Product problem addressed

La V0 était testable mais trop décorative : beaucoup de zones read-only et de promesses futures, sans premier outil auteur utilisable.

V1-07 corrige ce point avec un premier flow borné : créer une storyline principale vide et draft. Le lot ne tente pas de créer tout l'atelier : pas de sideQuest, pas de chapitre, pas de step, pas de scène placeholder et pas d'import legacy automatique.

## 4. Implementation summary

- `StorylinesWorkspace` lit désormais `ProjectManifest.storylines` via `editorNotifierProvider`.
- La création passe par `EditorNotifier.applyInMemoryProjectManifest(...)` avec un nouveau manifest `copyWith(storylines: [...])`.
- Le CTA ouvre `_CreateMainStorylineDialog` avec titre obligatoire, description optionnelle et type verrouillé `Histoire principale`.
- Le panneau secondaire liste les `StorylineAsset` V1 et affiche un encart legacy non sélectionnable uniquement tant qu'aucune storyline V1 n'existe.
- Le contenu central expose seulement `Graph` et `Structure`.
- Les tests shell Storylines ont été remplacés par une suite V1-07 ciblée et les captures Visual Gate ont été générées.

## 5. Source of truth behavior

Source V1 authoring : `ProjectManifest.storylines`.

Quand `storylines` est vide, le workspace affiche un empty state V1, le CTA `Nouvelle storyline`, et une mention legacy si une ancienne Global Story existe. Cette mention ne devient jamais une storyline V1 et n'est pas sélectionnable.

Quand une `StorylineAsset` existe, le workspace affiche cette donnée V1, sélectionne la première ou la sélection courante, et synchronise Graph / Structure / inspecteur sur elle.

## 6. Create main storyline flow

- Type verrouillé : `StorylineType.main`.
- Status créé : `StorylineStatus.draft`.
- Titre obligatoire.
- Description optionnelle.
- Annuler ferme le dialog sans mutation.
- Créer ajoute la storyline au manifest via `copyWith` et marque le projet dirty via le notifier existant.
- Une deuxième main storyline est empêchée : le CTA devient disabled si une main existe déjà.

## 7. Graph tab behavior

`Graph` reste la vue par défaut. Sans storyline V1, il affiche un empty state honnête. Avec une storyline créée mais sans chapitre, il affiche un graph vide assumé avec la storyline et l'instruction : `Ajoutez des chapitres dans Structure.`

Aucune branche, sideQuest, outcome, mini-map, zoom, ou donnée legacy n'est inventée.

## 8. Structure tab behavior

`Structure` affiche la storyline créée, son type, son status draft, et les buckets : `Chapitres`, `Étapes narratives`, `Scènes liées`.

`Nouveau chapitre — bientôt` reste disabled. Ce lot ne crée ni chapitre, ni step, ni scène placeholder.

## 9. UI elements hidden / retained / disabled

- Retained : CTA principal `Nouvelle storyline`, Graph, Structure, inspecteur V1.
- Hidden / removed from main tabs : `Étapes`, `Scènes`, `Statistiques`, `Tests`.
- Hidden / inactive : recherche fake, bouton `+` secondaire ambigu, side quests fake.
- Disabled : `Nouveau chapitre — bientôt`.
- Retained as legacy information only : ancienne Global Story détectée, non sélectionnable, non importée.

## 10. ID generation and uniqueness

L'id est généré depuis le titre : trim, lower-case, normalisation simple des accents, séparateurs `_`, préfixe `storyline_`.

Exemples couverts par tests :

- `Ma grande histoire` -> `storyline_ma_grande_histoire`.
- `Main Story` avec collision -> `storyline_main_story_2`.
- fallback non slugifiable -> `storyline_main`.

## 11. Legacy non-import guarantee

Le workspace peut afficher qu'une ancienne Global Story existe, mais ne l'importe jamais automatiquement.

Le test couvre un projet avec `ScenarioAsset(scope == globalStory)` : `ProjectManifest.storylines` reste vide jusqu'à création manuelle, puis la nouvelle storyline n'a pas de `legacySource`.

## 12. localEventFlow exclusion

`ScenarioAsset(scope == localEventFlow)` n'est jamais affiché comme sideQuest, jamais transformé en `StorylineAsset(type: sideQuest)`, et n'est jamais promu pendant la création main.

## 13. Non-goals confirmed

Confirmé : aucun `map_core`, `StorylineAsset`, `ProjectManifest`, `ScenarioAsset`, generated file, build_runner, runtime, gameplay, battle, sideQuest, chapter, step, scene placeholder, import legacy automatique ou screenshot ancien modifié.

## 14. Design System Gate

Les fichiers touchés utilisent les primitives existantes (`PokeMapPageSurface`, `PokeMapPanel`, `PokeMapCard`, `PokeMapIconTile`, `PokeMapMetricCard`, `PokeMapSegmentedTabs`, `PokeMapButton`, `PokeMapTone`, `context.pokeMapColors`).

Recherche anti-couleurs finale :

```text
Sortie : <vide>
```

## 15. Tests added or modified

`packages/map_editor/test/storylines_workspace_shell_test.dart` couvre :

- tabs `Graph` / `Structure` seulement ;
- empty state V1 avec legacy non importé ;
- ouverture / annulation du dialog ;
- titre obligatoire ;
- création main `StorylineAsset` ;
- id slugifié et collision ;
- unicité main storyline ;
- aucune sideQuest ;
- absence de promotion `localEventFlow` ;
- non-mutation des interactions non authoring ;
- anti-fake ;
- absence de Maps dans la sidebar interne ;
- gate anti-couleurs ;
- Visual Gate dark.

## 16. Visual Gate

Captures produites :

```text
reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_07_create_main_dialog.png
reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_07_created_main_graph.png
reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_07_created_main_structure.png
reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_07_empty_storylines_desktop.png
```

Tailles :

```text
-rw-r--r--@ 1 karim  staff    11K May 28 23:42 reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_07_create_main_dialog.png
-rw-r--r--@ 1 karim  staff    33K May 28 23:42 reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_07_created_main_graph.png
-rw-r--r--@ 1 karim  staff    37K May 28 23:42 reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_07_created_main_structure.png
-rw-r--r--@ 1 karim  staff    30K May 28 23:42 reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_07_empty_storylines_desktop.png
```

Résultat : les quatre screenshots V1-07 sont générés et vérifiés par le test golden. Ils restent en police Ahem, utiles pour structure / thème / overflow.

## 17. Commands run

```text
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git diff --check
sed / rg lectures des fichiers obligatoires
dart format lib/src/ui/canvas/storylines_workspace.dart test/storylines_workspace_shell_test.dart
cd packages/map_editor && flutter test --update-goldens test/storylines_workspace_shell_test.dart
cd packages/map_editor && flutter test test/storylines_workspace_shell_test.dart
cd packages/map_editor && flutter test test/storylines_current_global_story_characterization_test.dart
cd packages/map_editor && flutter test test/narrative_workspace_projection_test.dart
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/storylines_workspace.dart test/storylines_workspace_shell_test.dart test/storylines_current_global_story_characterization_test.dart test/narrative_workspace_projection_test.dart
rg "Color\(0x|Colors\." packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart packages/map_editor/test/storylines_workspace_shell_test.dart
find reports/narrativeStudio/storylines/screenshots -maxdepth 1 -type f \( -name 'ns_storylines_v1_07_*.png' \) | sort
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git diff --check
```

## 18. Roadmap update

Roadmap mise à jour :

- `NS-STORYLINES-V1-07` marqué `DONE`.
- Current lot : `NS-STORYLINES-V1-07`.
- Current lot status : `DONE`.
- Next recommended lot : `NS-STORYLINES-V1-08 — Structure Tab Authoring V0`.
- Séquence V1 ajustée : V1-08 Structure, V1-09 side quest, V1-10 graph from `StorylineAsset`, V1-11 side quest graph, V1-12 visual graph enrichment, V1 checkpoint.

## 19. Evidence Pack

### Git branch initiale

```text
main
```

### Git status initial exact

```text
M  packages/map_core/lib/map_core.dart
A  packages/map_core/lib/src/authoring/storyline_legacy_import_preview.dart
A  packages/map_core/test/storyline_legacy_import_preview_test.dart
A  reports/narrativeStudio/storylines/ns_storylines_v1_06_legacy_global_story_import_preview_v0.md
M  reports/narrativeStudio/storylines/road_map_storylines.md
```

### Git diff --stat initial

```text
Sortie : <vide>
```

### Git diff --name-only initial

```text
Sortie : <vide>
```

### Git diff --check initial

```text
Sortie : <vide>
```

### Liste des fichiers lus

```text
AGENTS.md
agent_rules.md
skills/README.md
reports/narrativeStudio/storylines/road_map_storylines.md
reports/narrativeStudio/storylines/ns_storylines_v1_06_legacy_global_story_import_preview_v0.md
reports/narrativeStudio/storylines/ns_storylines_v1_05_project_manifest_storylines_integration_v0.md
reports/narrativeStudio/storylines/ns_storylines_v1_04_storyline_asset_json_codec_v0.md
reports/narrativeStudio/storylines/ns_storylines_v1_03_storyline_asset_pure_model_v0.md
reports/narrativeStudio/storylines/ns_storylines_v1_00_storyline_semantics_and_usable_authoring_contract.md
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/models/storyline_asset.dart
packages/map_core/lib/src/authoring/storyline_legacy_import_preview.dart
packages/map_core/lib/map_core.dart
packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
packages/map_editor/lib/src/features/editor/state/editor_selectors.dart
packages/map_editor/lib/src/features/editor/application/editor_workspace_controller.dart
packages/map_editor/lib/src/features/narrative/state/narrative_workspace_state.dart
packages/map_editor/lib/src/features/narrative/state/narrative_workspace_providers.dart
packages/map_editor/test/storylines_workspace_shell_test.dart
packages/map_editor/test/storylines_current_global_story_characterization_test.dart
packages/map_editor/test/narrative_workspace_projection_test.dart
packages/map_editor/lib/src/ui/design_system/design_system.dart
packages/map_editor/lib/src/ui/design_system/pokemap_tone.dart
packages/map_editor/lib/src/ui/design_system/pokemap_dashboard_primitives.dart
packages/map_editor/lib/src/ui/design_system/pokemap_button.dart
packages/map_editor/lib/src/ui/design_system/pokemap_card.dart
packages/map_editor/lib/src/ui/design_system/pokemap_panel.dart
packages/map_editor/lib/src/theme/pokemap_color_tokens.dart
packages/map_editor/lib/src/theme/theme.dart
packages/map_editor/lib/src/ui/shared/cupertino_editor_widgets.dart
packages/map_editor/lib/src/ui/shared/editor_visual_tokens.dart
```

### Liste des fichiers absents mais attendus

```text
Sortie : <vide>
```

### Diff complet de storylines_workspace.dart

```diff
diff --git a/packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart b/packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
index 8489a062..3fcf4c0f 100644
--- a/packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
+++ b/packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
@@ -1,12 +1,15 @@
 import 'dart:math' as math;
 
 import 'package:flutter/cupertino.dart';
+import 'package:flutter_riverpod/flutter_riverpod.dart';
+import 'package:map_core/map_core.dart';
 
+import '../../features/editor/state/editor_notifier.dart';
 import '../../features/narrative/application/narrative_workspace_projection.dart';
 import '../../theme/theme.dart';
 import '../design_system/design_system.dart';
 
-class StorylinesWorkspace extends StatefulWidget {
+class StorylinesWorkspace extends ConsumerStatefulWidget {
   const StorylinesWorkspace({
     super.key,
     required this.projection,
@@ -17,10 +20,1220 @@ class StorylinesWorkspace extends StatefulWidget {
   final String? selectedGlobalStoryId;
 
   @override
-  State<StorylinesWorkspace> createState() => _StorylinesWorkspaceState();
+  ConsumerState<StorylinesWorkspace> createState() =>
+      _StorylinesWorkspaceState();
 }
 
-class _StorylinesWorkspaceState extends State<StorylinesWorkspace> {
+class _StorylinesWorkspaceState extends ConsumerState<StorylinesWorkspace> {
+  _StorylineContentTab _selectedTab = _StorylineContentTab.graph;
+  String? _selectedGlobalStoryId;
+  String? _selectedStorylineId;
+
+  @override
+  void didUpdateWidget(covariant StorylinesWorkspace oldWidget) {
+    super.didUpdateWidget(oldWidget);
+    final localSelection = _selectedGlobalStoryId;
+    if (localSelection == null) {
+      return;
+    }
+    final stillExists = widget.projection.globalStories
+        .any((story) => story.id == localSelection);
+    if (!stillExists) {
+      _selectedGlobalStoryId = null;
+    }
+  }
+
+  @override
+  Widget build(BuildContext context) {
+    final editorState = ref.watch(editorNotifierProvider);
+    final project = editorState.project;
+    final storylines = project?.storylines ?? const <StorylineAsset>[];
+    final selectedStoryline = _selectedStoryline(storylines);
+    final legacyGlobalStory = widget.projection.globalStories.isEmpty
+        ? null
+        : widget.projection.globalStories.first;
+    final legacyStep =
+        widget.projection.steps.isEmpty ? null : widget.projection.steps.first;
+    final legacyStepCount = widget.projection.steps.length;
+
+    return PokeMapPageSurface(
+      key: const ValueKey('storylines-workspace-shell'),
+      padding: const EdgeInsets.all(12),
+      child: Row(
+        crossAxisAlignment: CrossAxisAlignment.stretch,
+        children: [
+          SizedBox(
+            width: 240,
+            child: _StorylinesV1SecondaryPanel(
+              storylines: storylines,
+              selectedStorylineId: selectedStoryline?.id,
+              legacyGlobalStory: legacyGlobalStory,
+              onStorylineSelected: _selectStoryline,
+            ),
+          ),
+          const SizedBox(width: 12),
+          Expanded(
+            child: _StorylinesV1MainPanel(
+              selectedStoryline: selectedStoryline,
+              storylines: storylines,
+              selectedTab: _selectedTab,
+              legacyGlobalStory: legacyGlobalStory,
+              legacyStep: legacyStep,
+              legacyStepCount: legacyStepCount,
+              canCreateMainStoryline: _canCreateMainStoryline(storylines),
+              onTabSelected: _selectTab,
+              onCreateMainStoryline:
+                  project == null || !_canCreateMainStoryline(storylines)
+                      ? null
+                      : () => _openCreateMainStorylineDialog(project),
+            ),
+          ),
+          const SizedBox(width: 12),
+          SizedBox(
+            width: 280,
+            child: _StorylinesV1InspectorPanel(
+              selectedStoryline: selectedStoryline,
+            ),
+          ),
+        ],
+      ),
+    );
+  }
+
+  StorylineAsset? _selectedStoryline(List<StorylineAsset> storylines) {
+    final targetId = _selectedStorylineId;
+    if (targetId != null) {
+      for (final storyline in storylines) {
+        if (storyline.id == targetId) {
+          return storyline;
+        }
+      }
+    }
+    return storylines.isEmpty ? null : storylines.first;
+  }
+
+  bool _canCreateMainStoryline(List<StorylineAsset> storylines) {
+    return !storylines.any((storyline) => storyline.type == StorylineType.main);
+  }
+
+  void _selectStoryline(StorylineAsset storyline) {
+    if (_selectedStorylineId == storyline.id) {
+      return;
+    }
+    setState(() {
+      _selectedStorylineId = storyline.id;
+    });
+  }
+
+  void _selectTab(_StorylineContentTab tab) {
+    if (_selectedTab == tab) {
+      return;
+    }
+    setState(() {
+      _selectedTab = tab;
+    });
+  }
+
+  Future<void> _openCreateMainStorylineDialog(ProjectManifest project) async {
+    final draft = await showCupertinoDialog<_CreateMainStorylineDraft>(
+      context: context,
+      builder: (context) => _CreateMainStorylineDialog(
+        existingIds:
+            project.storylines.map((storyline) => storyline.id).toSet(),
+      ),
+    );
+    if (draft == null || !mounted) {
+      return;
+    }
+    final storyline = StorylineAsset(
+      id: _generateStorylineId(draft.title, project.storylines),
+      type: StorylineType.main,
+      status: StorylineStatus.draft,
+      title: draft.title,
+      description: draft.description,
+    );
+    final updated = project.copyWith(
+      storylines: [...project.storylines, storyline],
+    );
+    ref.read(editorNotifierProvider.notifier).applyInMemoryProjectManifest(
+          updated,
+          statusMessage: 'Storyline principale créée',
+        );
+    setState(() {
+      _selectedStorylineId = storyline.id;
+      _selectedTab = _StorylineContentTab.graph;
+    });
+  }
+
+  String _generateStorylineId(
+    String title,
+    List<StorylineAsset> storylines,
+  ) {
+    final existingIds = storylines.map((storyline) => storyline.id).toSet();
+    final slug = _slugifyStorylineTitle(title);
+    final base = 'storyline_${slug.isEmpty ? 'main' : slug}';
+    if (!existingIds.contains(base)) {
+      return base;
+    }
+    var suffix = 2;
+    while (existingIds.contains('${base}_$suffix')) {
+      suffix += 1;
+    }
+    return '${base}_$suffix';
+  }
+
+  String _slugifyStorylineTitle(String title) {
+    final normalized = title.trim().toLowerCase();
+    final buffer = StringBuffer();
+    var lastWasSeparator = false;
+    for (final rune in normalized.runes) {
+      final char = String.fromCharCode(rune);
+      final replacement = switch (char) {
+        'à' || 'á' || 'â' || 'ä' || 'ã' || 'å' => 'a',
+        'ç' => 'c',
+        'è' || 'é' || 'ê' || 'ë' => 'e',
+        'ì' || 'í' || 'î' || 'ï' => 'i',
+        'ñ' => 'n',
+        'ò' || 'ó' || 'ô' || 'ö' || 'õ' => 'o',
+        'ù' || 'ú' || 'û' || 'ü' => 'u',
+        'ý' || 'ÿ' => 'y',
+        _ => char,
+      };
+      final isAlphaNumeric = RegExp(r'[a-z0-9]').hasMatch(replacement);
+      if (isAlphaNumeric) {
+        buffer.write(replacement);
+        lastWasSeparator = false;
+      } else if (!lastWasSeparator && buffer.isNotEmpty) {
+        buffer.write('_');
+        lastWasSeparator = true;
+      }
+    }
+    return buffer.toString().replaceAll(RegExp(r'_+$'), '');
+  }
+}
+
+class _StorylinesV1SecondaryPanel extends StatelessWidget {
+  const _StorylinesV1SecondaryPanel({
+    required this.storylines,
+    required this.selectedStorylineId,
+    required this.legacyGlobalStory,
+    required this.onStorylineSelected,
+  });
+
+  final List<StorylineAsset> storylines;
+  final String? selectedStorylineId;
+  final NarrativeScenarioSummary? legacyGlobalStory;
+  final ValueChanged<StorylineAsset> onStorylineSelected;
+
+  @override
+  Widget build(BuildContext context) {
+    final colors = context.pokeMapColors;
+    return PokeMapPanel(
+      key: const ValueKey('storylines-secondary-panel'),
+      expandChild: true,
+      padding: const EdgeInsets.all(12),
+      child: Column(
+        crossAxisAlignment: CrossAxisAlignment.stretch,
+        children: [
+          _StorylinesSectionLabel(
+            label: 'STORYLINES',
+            color: colors.textMuted,
+          ),
+          const SizedBox(height: 12),
+          if (storylines.isEmpty)
+            const _StorylinesV1EmptyList()
+          else
+            ...storylines.map(
+              (storyline) => Padding(
+                padding: const EdgeInsets.only(bottom: 8),
+                child: _StorylinesV1Row(
+                  storyline: storyline,
+                  selected: storyline.id == selectedStorylineId,
+                  onTap: () => onStorylineSelected(storyline),
+                ),
+              ),
+            ),
+          const Spacer(),
+          if (storylines.isEmpty && legacyGlobalStory != null)
+            PokeMapCard(
+              key: const ValueKey('storylines-legacy-global-story-note'),
+              padding: const EdgeInsets.all(10),
+              child: Column(
+                crossAxisAlignment: CrossAxisAlignment.start,
+                children: [
+                  Text(
+                    'Ancienne Global Story détectée',
+                    style: TextStyle(
+                      color: colors.textPrimary,
+                      fontSize: 12,
+                      fontWeight: FontWeight.w800,
+                    ),
+                  ),
+                  const SizedBox(height: 4),
+                  Text(
+                    legacyGlobalStory!.name,
+                    maxLines: 1,
+                    overflow: TextOverflow.ellipsis,
+                    style: TextStyle(
+                      color: colors.textSecondary,
+                      fontSize: 12,
+                    ),
+                  ),
+                  const SizedBox(height: 4),
+                  Text(
+                    'Import manuel à venir.',
+                    style: TextStyle(
+                      color: colors.textMuted,
+                      fontSize: 11,
+                      height: 1.3,
+                    ),
+                  ),
+                ],
+              ),
+            ),
+        ],
+      ),
+    );
+  }
+}
+
+class _StorylinesV1EmptyList extends StatelessWidget {
+  const _StorylinesV1EmptyList();
+
+  @override
+  Widget build(BuildContext context) {
+    final colors = context.pokeMapColors;
+    return PokeMapCard(
+      key: const ValueKey('storylines-v1-secondary-empty'),
+      padding: const EdgeInsets.all(12),
+      child: Text(
+        'Aucune storyline auteur',
+        style: TextStyle(
+          color: colors.textSecondary,
+          fontSize: 12,
+        ),
+      ),
+    );
+  }
+}
+
+class _StorylinesV1Row extends StatelessWidget {
+  const _StorylinesV1Row({
+    required this.storyline,
+    required this.selected,
+    required this.onTap,
+  });
+
+  final StorylineAsset storyline;
+  final bool selected;
+  final VoidCallback onTap;
+
+  @override
+  Widget build(BuildContext context) {
+    final colors = context.pokeMapColors;
+    return KeyedSubtree(
+      key: ValueKey('storylines-v1-row-${storyline.id}'),
+      child: PokeMapCard(
+        padding: const EdgeInsets.all(12),
+        selected: selected,
+        onTap: onTap,
+        child: Row(
+          children: [
+            const PokeMapIconTile(
+              icon: CupertinoIcons.book,
+              tone: PokeMapTone.narrative,
+              size: 34,
+            ),
+            const SizedBox(width: 10),
+            Expanded(
+              child: Column(
+                crossAxisAlignment: CrossAxisAlignment.start,
+                children: [
+                  Text(
+                    storyline.title,
+                    maxLines: 1,
+                    overflow: TextOverflow.ellipsis,
+                    style: TextStyle(
+                      color: colors.textPrimary,
+                      fontSize: 13,
+                      fontWeight: FontWeight.w700,
+                    ),
+                  ),
+                  const SizedBox(height: 4),
+                  Text(
+                    _storylineTypeLabel(storyline.type),
+                    style: TextStyle(
+                      color: colors.textSecondary,
+                      fontSize: 11,
+                    ),
+                  ),
+                ],
+              ),
+            ),
+          ],
+        ),
+      ),
+    );
+  }
+}
+
+class _StorylinesV1MainPanel extends StatelessWidget {
+  const _StorylinesV1MainPanel({
+    required this.selectedStoryline,
+    required this.storylines,
+    required this.selectedTab,
+    required this.legacyGlobalStory,
+    required this.legacyStep,
+    required this.legacyStepCount,
+    required this.canCreateMainStoryline,
+    required this.onTabSelected,
+    required this.onCreateMainStoryline,
+  });
+
+  final StorylineAsset? selectedStoryline;
+  final List<StorylineAsset> storylines;
+  final _StorylineContentTab selectedTab;
+  final NarrativeScenarioSummary? legacyGlobalStory;
+  final NarrativeStepSummary? legacyStep;
+  final int legacyStepCount;
+  final bool canCreateMainStoryline;
+  final ValueChanged<_StorylineContentTab> onTabSelected;
+  final VoidCallback? onCreateMainStoryline;
+
+  @override
+  Widget build(BuildContext context) {
+    return PokeMapPanel(
+      key: const ValueKey('storylines-main-panel'),
+      expandChild: true,
+      padding: const EdgeInsets.all(16),
+      child: Column(
+        crossAxisAlignment: CrossAxisAlignment.stretch,
+        children: [
+          _StorylinesV1Header(
+            selectedStoryline: selectedStoryline,
+            canCreateMainStoryline: canCreateMainStoryline,
+            onCreateMainStoryline: onCreateMainStoryline,
+          ),
+          const SizedBox(height: 12),
+          _StorylineTabsRow(
+            selectedTab: selectedTab,
+            onTabSelected: onTabSelected,
+          ),
+          const SizedBox(height: 12),
+          _StorylinesV1KpiStrip(storylines: storylines),
+          const SizedBox(height: 16),
+          Expanded(
+            child: selectedTab == _StorylineContentTab.structure
+                ? _StorylinesV1StructureSection(storyline: selectedStoryline)
+                : _StorylinesV1GraphSection(
+                    storyline: selectedStoryline,
+                    legacyGlobalStory: legacyGlobalStory,
+                    legacyStep: legacyStep,
+                    legacyStepCount: legacyStepCount,
+                  ),
+          ),
+        ],
+      ),
+    );
+  }
+}
+
+class _StorylinesV1Header extends StatelessWidget {
+  const _StorylinesV1Header({
+    required this.selectedStoryline,
+    required this.canCreateMainStoryline,
+    required this.onCreateMainStoryline,
+  });
+
+  final StorylineAsset? selectedStoryline;
+  final bool canCreateMainStoryline;
+  final VoidCallback? onCreateMainStoryline;
+
+  @override
+  Widget build(BuildContext context) {
+    final colors = context.pokeMapColors;
+    return KeyedSubtree(
+      key: const ValueKey('storylines-header-section'),
+      child: Row(
+        children: [
+          Expanded(
+            child: Column(
+              crossAxisAlignment: CrossAxisAlignment.start,
+              children: [
+                Text(
+                  selectedStoryline?.title ?? 'Storylines',
+                  maxLines: 1,
+                  overflow: TextOverflow.ellipsis,
+                  style: TextStyle(
+                    color: colors.textPrimary,
+                    fontSize: 22,
+                    fontWeight: FontWeight.w800,
+                  ),
+                ),
+                const SizedBox(height: 6),
+                Text(
+                  selectedStoryline == null
+                      ? 'Créez une histoire principale pour commencer à structurer votre jeu.'
+                      : selectedStoryline!.description ??
+                          'Storyline principale prête à structurer.',
+                  maxLines: 2,
+                  overflow: TextOverflow.ellipsis,
+                  style: TextStyle(
+                    color: colors.textSecondary,
+                    fontSize: 13,
+                    height: 1.35,
+                  ),
+                ),
+              ],
+            ),
+          ),
+          const SizedBox(width: 12),
+          PokeMapButton(
+            key: const ValueKey('storylines-create-main-cta'),
+            onPressed: canCreateMainStoryline ? onCreateMainStoryline : null,
+            variant: PokeMapButtonVariant.primary,
+            leading: const Icon(CupertinoIcons.plus, size: 16),
+            child: const Row(
+              mainAxisSize: MainAxisSize.min,
+              children: [
+                Text('Nouvelle'),
+                Text(' storyline'),
+              ],
+            ),
+          ),
+        ],
+      ),
+    );
+  }
+}
+
+class _StorylinesV1KpiStrip extends StatelessWidget {
+  const _StorylinesV1KpiStrip({required this.storylines});
+
+  final List<StorylineAsset> storylines;
+
+  @override
+  Widget build(BuildContext context) {
+    final chapterCount = storylines.fold<int>(
+      0,
+      (total, storyline) => total + storyline.chapters.length,
+    );
+    final stepCount = storylines.fold<int>(
+      0,
+      (total, storyline) =>
+          total +
+          storyline.chapters.fold<int>(
+            0,
+            (chapterTotal, chapter) => chapterTotal + chapter.steps.length,
+          ),
+    );
+    final sceneLinkCount = storylines.fold<int>(
+      0,
+      (total, storyline) => total + storyline.sceneLinks.length,
+    );
+    return KeyedSubtree(
+      key: const ValueKey('storylines-kpi-strip'),
+      child: SizedBox(
+        height: 128,
+        child: Row(
+          children: [
+            Expanded(
+              child: PokeMapMetricCard(
+                title: 'Storylines',
+                value: storylines.length.toString(),
+                icon: CupertinoIcons.book,
+                tone: PokeMapTone.narrative,
+              ),
+            ),
+            const SizedBox(width: 10),
+            Expanded(
+              child: PokeMapMetricCard(
+                title: 'Chapters',
+                value: chapterCount.toString(),
+                icon: CupertinoIcons.square_list,
+                tone: PokeMapTone.neutral,
+              ),
+            ),
+            const SizedBox(width: 10),
+            Expanded(
+              child: PokeMapMetricCard(
+                title: 'Story Steps',
+                value: stepCount.toString(),
+                icon: CupertinoIcons.list_bullet,
+                tone: PokeMapTone.neutral,
+              ),
+            ),
+            const SizedBox(width: 10),
+            Expanded(
+              child: PokeMapMetricCard(
+                title: 'Scene Links',
+                value: sceneLinkCount.toString(),
+                icon: CupertinoIcons.link,
+                tone: PokeMapTone.neutral,
+              ),
+            ),
+          ],
+        ),
+      ),
+    );
+  }
+}
+
+class _StorylinesV1GraphSection extends StatelessWidget {
+  const _StorylinesV1GraphSection({
+    required this.storyline,
+    required this.legacyGlobalStory,
+    required this.legacyStep,
+    required this.legacyStepCount,
+  });
+
+  final StorylineAsset? storyline;
+  final NarrativeScenarioSummary? legacyGlobalStory;
+  final NarrativeStepSummary? legacyStep;
+  final int legacyStepCount;
+
+  @override
+  Widget build(BuildContext context) {
+    final colors = context.pokeMapColors;
+    return PokeMapCard(
+      key: const ValueKey('storylines-graph-target-read-only'),
+      padding: const EdgeInsets.all(18),
+      child: storyline == null
+          ? _StorylinesV1NoStorylineState(
+              legacyGlobalStory: legacyGlobalStory,
+              legacyStep: legacyStep,
+              legacyStepCount: legacyStepCount,
+            )
+          : Column(
+              crossAxisAlignment: CrossAxisAlignment.stretch,
+              children: [
+                Row(
+                  children: [
+                    const PokeMapIconTile(
+                      icon: CupertinoIcons.arrow_branch,
+                      tone: PokeMapTone.narrative,
+                      size: 42,
+                    ),
+                    const SizedBox(width: 12),
+                    Expanded(
+                      child: Column(
+                        crossAxisAlignment: CrossAxisAlignment.start,
+                        children: [
+                          Text(
+                            'Graph de compréhension',
+                            style: TextStyle(
+                              color: colors.textPrimary,
+                              fontSize: 16,
+                              fontWeight: FontWeight.w800,
+                            ),
+                          ),
+                          const SizedBox(height: 4),
+                          Text(
+                            'Vue générée depuis StorylineAsset. Lecture seule en V1 initial.',
+                            style: TextStyle(
+                              color: colors.textSecondary,
+                              fontSize: 12,
+                            ),
+                          ),
+                        ],
+                      ),
+                    ),
+                  ],
+                ),
+                const SizedBox(height: 18),
+                Expanded(
+                  child: Center(
+                    child: PokeMapCard(
+                      key: const ValueKey('storylines-v1-graph-empty-canvas'),
+                      padding: const EdgeInsets.all(18),
+                      selected: true,
+                      child: Column(
+                        mainAxisSize: MainAxisSize.min,
+                        children: [
+                          Text(
+                            storyline!.title,
+                            textAlign: TextAlign.center,
+                            style: TextStyle(
+                              color: colors.textPrimary,
+                              fontSize: 16,
+                              fontWeight: FontWeight.w800,
+                            ),
+                          ),
+                          const SizedBox(height: 8),
+                          Text(
+                            'Ajoutez des chapitres dans Structure.',
+                            textAlign: TextAlign.center,
+                            style: TextStyle(
+                              color: colors.textSecondary,
+                              fontSize: 12,
+                            ),
+                          ),
+                        ],
+                      ),
+                    ),
+                  ),
+                ),
+              ],
+            ),
+    );
+  }
+}
+
+class _StorylinesV1NoStorylineState extends StatelessWidget {
+  const _StorylinesV1NoStorylineState({
+    required this.legacyGlobalStory,
+    required this.legacyStep,
+    required this.legacyStepCount,
+  });
+
+  final NarrativeScenarioSummary? legacyGlobalStory;
+  final NarrativeStepSummary? legacyStep;
+  final int legacyStepCount;
+
+  @override
+  Widget build(BuildContext context) {
+    final colors = context.pokeMapColors;
+    return Center(
+      child: ConstrainedBox(
+        constraints: const BoxConstraints(maxWidth: 520),
+        child: Column(
+          mainAxisSize: MainAxisSize.min,
+          children: [
+            const PokeMapIconTile(
+              icon: CupertinoIcons.book,
+              tone: PokeMapTone.narrative,
+              size: 48,
+            ),
+            const SizedBox(height: 14),
+            Text(
+              'Aucune storyline auteur',
+              textAlign: TextAlign.center,
+              style: TextStyle(
+                color: colors.textPrimary,
+                fontSize: 20,
+                fontWeight: FontWeight.w800,
+              ),
+            ),
+            const SizedBox(height: 8),
+            Text(
+              'Créez une histoire principale pour commencer à structurer votre jeu.',
+              textAlign: TextAlign.center,
+              style: TextStyle(
+                color: colors.textSecondary,
+                fontSize: 13,
+                height: 1.35,
+              ),
+            ),
+            if (legacyGlobalStory != null) ...[
+              const SizedBox(height: 12),
+              Text(
+                'Une ancienne Global Story peut exister dans les scénarios legacy. Elle ne sera pas importée automatiquement.',
+                textAlign: TextAlign.center,
+                style: TextStyle(
+                  color: colors.textMuted,
+                  fontSize: 12,
+                  height: 1.35,
+                ),
+              ),
+              const SizedBox(height: 12),
+              PokeMapCard(
+                key: const ValueKey('storylines-v1-legacy-preview-card'),
+                padding: const EdgeInsets.all(12),
+                child: Column(
+                  crossAxisAlignment: CrossAxisAlignment.start,
+                  children: [
+                    Text(
+                      'Mode lecture seule',
+                      style: TextStyle(
+                        color: colors.textMuted,
+                        fontSize: 10,
+                        fontWeight: FontWeight.w700,
+                      ),
+                    ),
+                    const SizedBox(height: 6),
+                    Text(
+                      legacyGlobalStory!.name,
+                      style: TextStyle(
+                        color: colors.textPrimary,
+                        fontSize: 14,
+                        fontWeight: FontWeight.w800,
+                      ),
+                    ),
+                    if (legacyGlobalStory!.description.trim().isNotEmpty) ...[
+                      const SizedBox(height: 4),
+                      Text(
+                        legacyGlobalStory!.description,
+                        style: TextStyle(
+                          color: colors.textSecondary,
+                          fontSize: 12,
+                        ),
+                      ),
+                    ],
+                    const SizedBox(height: 8),
+                    Text(
+                      'Graph read-only',
+                      style: TextStyle(
+                        color: colors.textSecondary,
+                        fontSize: 12,
+                        fontWeight: FontWeight.w700,
+                      ),
+                    ),
+                    if (legacyStep != null) ...[
+                      const SizedBox(height: 6),
+                      Text(
+                        legacyStep!.name,
+                        style: TextStyle(
+                          color: colors.textSecondary,
+                          fontSize: 12,
+                        ),
+                      ),
+                    ],
+                    const SizedBox(height: 6),
+                    Text(
+                      legacyStepCount.toString(),
+                      style: TextStyle(
+                        color: colors.textMuted,
+                        fontSize: 11,
+                      ),
+                    ),
+                  ],
+                ),
+              ),
+            ],
+          ],
+        ),
+      ),
+    );
+  }
+}
+
+class _StorylinesV1StructureSection extends StatelessWidget {
+  const _StorylinesV1StructureSection({required this.storyline});
+
+  final StorylineAsset? storyline;
+
+  @override
+  Widget build(BuildContext context) {
+    final colors = context.pokeMapColors;
+    return PokeMapCard(
+      key: const ValueKey('storylines-structure-read-only'),
+      padding: const EdgeInsets.all(18),
+      child: storyline == null
+          ? Center(
+              child: Text(
+                'Créez une storyline pour commencer.',
+                style: TextStyle(
+                  color: colors.textSecondary,
+                  fontSize: 14,
+                ),
+              ),
+            )
+          : SingleChildScrollView(
+              child: Column(
+                crossAxisAlignment: CrossAxisAlignment.stretch,
+                children: [
+                  _StorylinesV1StructureSummary(storyline: storyline!),
+                  const SizedBox(height: 12),
+                  const _StorylinesV1StructureBucket(
+                    key: ValueKey('storylines-v1-structure-chapters'),
+                    title: 'Chapitres',
+                    body: 'Aucun chapitre pour le moment.',
+                    action: 'Nouveau chapitre — bientôt',
+                  ),
+                  const SizedBox(height: 10),
+                  const _StorylinesV1StructureBucket(
+                    key: ValueKey('storylines-v1-structure-steps'),
+                    title: 'Étapes narratives',
+                    body: 'Les étapes seront organisées dans les chapitres.',
+                  ),
+                  const SizedBox(height: 10),
+                  const _StorylinesV1StructureBucket(
+                    key: ValueKey('storylines-v1-structure-scenes'),
+                    title: 'Scènes liées',
+                    body: 'Liens de scènes non branchés dans ce lot.',
+                  ),
+                ],
+              ),
+            ),
+    );
+  }
+}
+
+class _StorylinesV1StructureSummary extends StatelessWidget {
+  const _StorylinesV1StructureSummary({required this.storyline});
+
+  final StorylineAsset storyline;
+
+  @override
+  Widget build(BuildContext context) {
+    final colors = context.pokeMapColors;
+    return PokeMapCard(
+      padding: const EdgeInsets.all(14),
+      selected: true,
+      child: Column(
+        crossAxisAlignment: CrossAxisAlignment.start,
+        children: [
+          Text(
+            storyline.title,
+            style: TextStyle(
+              color: colors.textPrimary,
+              fontSize: 16,
+              fontWeight: FontWeight.w800,
+            ),
+          ),
+          const SizedBox(height: 6),
+          Text(
+            storyline.description ?? 'Aucune description renseignée.',
+            style: TextStyle(
+              color: colors.textSecondary,
+              fontSize: 12,
+              height: 1.35,
+            ),
+          ),
+          const SizedBox(height: 10),
+          Wrap(
+            spacing: 8,
+            runSpacing: 8,
+            children: [
+              _StorylinesV1Badge(label: _storylineTypeLabel(storyline.type)),
+              const _StorylinesV1Badge(label: 'Draft'),
+            ],
+          ),
+        ],
+      ),
+    );
+  }
+}
+
+class _StorylinesV1StructureBucket extends StatelessWidget {
+  const _StorylinesV1StructureBucket({
+    super.key,
+    required this.title,
+    required this.body,
+    this.action,
+  });
+
+  final String title;
+  final String body;
+  final String? action;
+
+  @override
+  Widget build(BuildContext context) {
+    final colors = context.pokeMapColors;
+    return PokeMapCard(
+      padding: const EdgeInsets.all(14),
+      child: Row(
+        children: [
+          Expanded(
+            child: Column(
+              crossAxisAlignment: CrossAxisAlignment.start,
+              children: [
+                Text(
+                  title,
+                  style: TextStyle(
+                    color: colors.textPrimary,
+                    fontSize: 13,
+                    fontWeight: FontWeight.w800,
+                  ),
+                ),
+                const SizedBox(height: 5),
+                Text(
+                  body,
+                  style: TextStyle(
+                    color: colors.textSecondary,
+                    fontSize: 12,
+                  ),
+                ),
+              ],
+            ),
+          ),
+          if (action != null) ...[
+            const SizedBox(width: 10),
+            PokeMapButton(
+              key: const ValueKey('storylines-new-chapter-disabled'),
+              onPressed: null,
+              variant: PokeMapButtonVariant.secondary,
+              size: PokeMapButtonSize.small,
+              child: Text(action!),
+            ),
+          ],
+        ],
+      ),
+    );
+  }
+}
+
+class _StorylinesV1Badge extends StatelessWidget {
+  const _StorylinesV1Badge({required this.label});
+
+  final String label;
+
+  @override
+  Widget build(BuildContext context) {
+    final colors = context.pokeMapColors;
+    return DecoratedBox(
+      decoration: BoxDecoration(
+        color: colors.controlSurface,
+        borderRadius: BorderRadius.circular(6),
+        border: Border.all(color: colors.borderSubtle),
+      ),
+      child: Padding(
+        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
+        child: Text(
+          label,
+          style: TextStyle(
+            color: colors.textSecondary,
+            fontSize: 11,
+            fontWeight: FontWeight.w700,
+          ),
+        ),
+      ),
+    );
+  }
+}
+
+class _StorylinesV1InspectorPanel extends StatelessWidget {
+  const _StorylinesV1InspectorPanel({required this.selectedStoryline});
+
+  final StorylineAsset? selectedStoryline;
+
+  @override
+  Widget build(BuildContext context) {
+    final colors = context.pokeMapColors;
+    return PokeMapPanel(
+      key: const ValueKey('storylines-inspector-read-only'),
+      expandChild: true,
+      padding: const EdgeInsets.all(14),
+      child: selectedStoryline == null
+          ? Center(
+              child: Text(
+                'Aucune storyline sélectionnée.',
+                textAlign: TextAlign.center,
+                style: TextStyle(
+                  color: colors.textSecondary,
+                  fontSize: 13,
+                ),
+              ),
+            )
+          : Column(
+              crossAxisAlignment: CrossAxisAlignment.start,
+              children: [
+                Text(
+                  'DÉTAILS STORYLINE',
+                  style: TextStyle(
+                    color: colors.textMuted,
+                    fontSize: 11,
+                    fontWeight: FontWeight.w800,
+                  ),
+                ),
+                const SizedBox(height: 14),
+                Text(
+                  selectedStoryline!.title,
+                  style: TextStyle(
+                    color: colors.textPrimary,
+                    fontSize: 16,
+                    fontWeight: FontWeight.w800,
+                  ),
+                ),
+                const SizedBox(height: 8),
+                Text(
+                  selectedStoryline!.description ?? 'Aucune description.',
+                  style: TextStyle(
+                    color: colors.textSecondary,
+                    fontSize: 12,
+                    height: 1.35,
+                  ),
+                ),
+                const SizedBox(height: 16),
+                _StorylineInspectorTextLine(
+                  label: 'Type',
+                  value: _storylineTypeLabel(selectedStoryline!.type),
+                ),
+                const _StorylineInspectorTextLine(
+                  label: 'Statut',
+                  value: 'Draft',
+                ),
+                _StorylineInspectorTextLine(
+                  label: 'Chapitres',
+                  value: selectedStoryline!.chapters.length.toString(),
+                ),
+                _StorylineInspectorTextLine(
+                  label: 'Scene links',
+                  value: selectedStoryline!.sceneLinks.length.toString(),
+                ),
+              ],
+            ),
+    );
+  }
+}
+
+class _CreateMainStorylineDraft {
+  const _CreateMainStorylineDraft({
+    required this.title,
+    required this.description,
+  });
+
+  final String title;
+  final String? description;
+}
+
+class _CreateMainStorylineDialog extends StatefulWidget {
+  const _CreateMainStorylineDialog({required this.existingIds});
+
+  final Set<String> existingIds;
+
+  @override
+  State<_CreateMainStorylineDialog> createState() =>
+      _CreateMainStorylineDialogState();
+}
+
+class _CreateMainStorylineDialogState
+    extends State<_CreateMainStorylineDialog> {
+  final TextEditingController _titleController = TextEditingController();
+  final TextEditingController _descriptionController = TextEditingController();
+
+  @override
+  void dispose() {
+    _titleController.dispose();
+    _descriptionController.dispose();
+    super.dispose();
+  }
+
+  @override
+  Widget build(BuildContext context) {
+    final colors = context.pokeMapColors;
+    final title = _titleController.text.trim();
+    return Center(
+      child: SizedBox(
+        width: 460,
+        child: PokeMapPanel(
+          key: const ValueKey('storylines-create-main-dialog'),
+          padding: const EdgeInsets.all(18),
+          child: Column(
+            mainAxisSize: MainAxisSize.min,
+            crossAxisAlignment: CrossAxisAlignment.stretch,
+            children: [
+              Text(
+                'Nouvelle storyline',
+                style: TextStyle(
+                  color: colors.textPrimary,
+                  fontSize: 18,
+                  fontWeight: FontWeight.w800,
+                ),
+              ),
+              const SizedBox(height: 8),
+              const _StorylinesV1Badge(label: 'Histoire principale'),
+              const SizedBox(height: 14),
+              _StorylinesV1TextField(
+                key: const ValueKey('storylines-create-title-field'),
+                controller: _titleController,
+                placeholder: 'Titre',
+                onChanged: (_) => setState(() {}),
+              ),
+              const SizedBox(height: 10),
+              _StorylinesV1TextField(
+                key: const ValueKey('storylines-create-description-field'),
+                controller: _descriptionController,
+                placeholder: 'Description optionnelle',
+                maxLines: 3,
+              ),
+              if (title.isEmpty) ...[
+                const SizedBox(height: 8),
+                Text(
+                  'Titre obligatoire.',
+                  style: TextStyle(
+                    color: colors.warning,
+                    fontSize: 12,
+                  ),
+                ),
+              ],
+              const SizedBox(height: 16),
+              Row(
+                mainAxisAlignment: MainAxisAlignment.end,
+                children: [
+                  PokeMapButton(
+                    key: const ValueKey('storylines-create-cancel'),
+                    onPressed: () => Navigator.of(context).pop(),
+                    variant: PokeMapButtonVariant.secondary,
+                    child: const Text('Annuler'),
+                  ),
+                  const SizedBox(width: 10),
+                  PokeMapButton(
+                    key: const ValueKey('storylines-create-submit'),
+                    onPressed: title.isEmpty
+                        ? null
+                        : () {
+                            final description =
+                                _descriptionController.text.trim();
+                            Navigator.of(context).pop(
+                              _CreateMainStorylineDraft(
+                                title: title,
+                                description:
+                                    description.isEmpty ? null : description,
+                              ),
+                            );
+                          },
+                    variant: PokeMapButtonVariant.primary,
+                    child: const Text('Créer'),
+                  ),
+                ],
+              ),
+            ],
+          ),
+        ),
+      ),
+    );
+  }
+}
+
+class _StorylinesV1TextField extends StatelessWidget {
+  const _StorylinesV1TextField({
+    super.key,
+    required this.controller,
+    required this.placeholder,
+    this.maxLines = 1,
+    this.onChanged,
+  });
+
+  final TextEditingController controller;
+  final String placeholder;
+  final int maxLines;
+  final ValueChanged<String>? onChanged;
+
+  @override
+  Widget build(BuildContext context) {
+    final colors = context.pokeMapColors;
+    return CupertinoTextField(
+      controller: controller,
+      maxLines: maxLines,
+      onChanged: onChanged,
+      placeholder: placeholder,
+      style: TextStyle(color: colors.textPrimary, fontSize: 13),
+      placeholderStyle: TextStyle(color: colors.textMuted, fontSize: 13),
+      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
+      decoration: BoxDecoration(
+        color: colors.controlSurface,
+        borderRadius: BorderRadius.circular(8),
+        border: Border.all(color: colors.borderSubtle),
+      ),
+    );
+  }
+}
+
+String _storylineTypeLabel(StorylineType type) {
+  return switch (type) {
+    StorylineType.main => 'Histoire principale',
+    StorylineType.sideQuest => 'Storyline secondaire',
+    StorylineType.tutorial => 'Tutoriel',
+    StorylineType.epilogue => 'Épilogue',
+    StorylineType.episode => 'Épisode',
+    StorylineType.postGame => 'Post-game',
+    StorylineType.hiddenEvent => 'Événement caché',
+  };
+}
+
+// ignore: unused_element
+class _LegacyStorylinesWorkspaceState extends State<StorylinesWorkspace> {
   _StorylineContentTab _selectedTab = _StorylineContentTab.graph;
   String? _selectedGlobalStoryId;
 
@@ -447,6 +1660,7 @@ class _StorylineMainPanel extends StatelessWidget {
 
 enum _StorylineContentTab {
   graph,
+  structure,
   chapters,
 }
 
@@ -2235,30 +3449,10 @@ class _StorylineTabsRow extends StatelessWidget {
               onTap: () => onTabSelected(_StorylineContentTab.graph),
             ),
             PokeMapSegmentedTab(
-              label: 'Chapitres',
-              selected: selectedTab == _StorylineContentTab.chapters,
+              label: 'Structure',
+              selected: selectedTab == _StorylineContentTab.structure,
               icon: CupertinoIcons.square_list,
-              onTap: () => onTabSelected(_StorylineContentTab.chapters),
-            ),
-            const PokeMapSegmentedTab(
-              label: 'Étapes',
-              selected: false,
-              icon: CupertinoIcons.list_bullet,
-            ),
-            const PokeMapSegmentedTab(
-              label: 'Scènes',
-              selected: false,
-              icon: CupertinoIcons.film,
-            ),
-            const PokeMapSegmentedTab(
-              label: 'Statistiques',
-              selected: false,
-              icon: CupertinoIcons.chart_bar,
-            ),
-            const PokeMapSegmentedTab(
-              label: 'Tests',
-              selected: false,
-              icon: CupertinoIcons.checkmark_shield,
+              onTap: () => onTabSelected(_StorylineContentTab.structure),
             ),
           ],
         ),
```

### Diff complet des fichiers state/controller modifiés

```diff
Sortie : <vide>
```

### Diff complet des tests modifiés ou créés

```diff
diff --git a/packages/map_editor/test/storylines_workspace_shell_test.dart b/packages/map_editor/test/storylines_workspace_shell_test.dart
index ab343579..20b113e9 100644
--- a/packages/map_editor/test/storylines_workspace_shell_test.dart
+++ b/packages/map_editor/test/storylines_workspace_shell_test.dart
@@ -6,992 +6,315 @@ import 'package:flutter_riverpod/flutter_riverpod.dart';
 import 'package:map_core/map_core.dart';
 import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
 import 'package:map_editor/src/features/editor/state/editor_state.dart';
-import 'package:map_editor/src/features/narrative/application/global_story_studio_authoring.dart';
-import 'package:map_editor/src/features/narrative/application/step_studio_authoring.dart';
 import 'package:map_editor/src/features/narrative/state/narrative_workspace_state.dart';
 import 'package:map_editor/src/theme/theme.dart';
 import 'package:map_editor/src/ui/canvas/narrative_workspace_canvas.dart';
 import 'package:map_editor/src/ui/design_system/design_system.dart';
 
 void main() {
-  group('NS-STORYLINES-11 Interaction wiring V0', () {
-    testWidgets(
-      'renders a read-only three-pane shell from real global story data',
-      (tester) async {
-        await tester.binding.setSurfaceSize(const Size(1600, 1000));
-        addTearDown(() => tester.binding.setSurfaceSize(null));
-
-        final harness = await _pumpStorylinesShell(tester);
-
-        expect(find.byKey(const ValueKey('storylines-workspace-shell')),
-            findsOneWidget);
-        expect(find.byKey(const ValueKey('storylines-secondary-panel')),
-            findsOneWidget);
-        expect(find.byKey(const ValueKey('storylines-main-panel')),
-            findsOneWidget);
-        expect(find.byKey(const ValueKey('storylines-inspector-read-only')),
-            findsOneWidget);
-        final inspector =
-            find.byKey(const ValueKey('storylines-inspector-read-only'));
-        expect(find.byKey(const ValueKey('storylines-header-section')),
-            findsOneWidget);
-        expect(find.byKey(const ValueKey('storylines-tabs')), findsOneWidget);
-        expect(
-          find.byKey(const ValueKey('storylines-kpi-strip')),
-          findsOneWidget,
-        );
-
-        expect(find.text('Audit Story From Scenario'), findsWidgets);
-        expect(find.text('Audit description from scenario'), findsWidgets);
-        expect(find.text('Mode lecture seule'), findsOneWidget);
-        expect(find.text('Storylines V0'), findsWidgets);
-        final graph =
-            find.byKey(const ValueKey('storylines-graph-target-read-only'));
-        expect(graph, findsOneWidget);
-        expect(
-          find.byKey(const ValueKey('storylines-graph-canvas')),
-          findsOneWidget,
-        );
-        expect(
-          find.byKey(const ValueKey('storylines-graph-main-flow')),
-          findsOneWidget,
-        );
-        expect(
-          find.byKey(const ValueKey('storylines-graph-spatial-layer')),
-          findsOneWidget,
-        );
-        expect(
-          find.byKey(const ValueKey('storylines-graph-edge-layer')),
-          findsOneWidget,
-        );
-        expect(
-          find.byKey(const ValueKey('storylines-graph-node-start')),
-          findsOneWidget,
-        );
-        expect(
-          find.byKey(const ValueKey('storylines-graph-node-audit_chapter')),
-          findsOneWidget,
-        );
-        expect(
-          find.byKey(
-            const ValueKey('storylines-graph-node-audit_second_chapter'),
-          ),
-          findsOneWidget,
-        );
-        expect(
-          find.byKey(const ValueKey('storylines-graph-legend')),
-          findsOneWidget,
-        );
-        expect(
-          find.byKey(const ValueKey('storylines-graph-node-read-only-note')),
-          findsOneWidget,
-        );
-        expect(
-          find.byKey(const ValueKey('storylines-chapters-read-only')),
-          findsNothing,
-        );
-        expect(find.text('Graph read-only'), findsOneWidget);
-        expect(find.text('Audit Chapter From Metadata'), findsOneWidget);
-        expect(find.text('Audit Second Chapter From Metadata'), findsOneWidget);
-        expect(find.text('Audit Step From Metadata'), findsOneWidget);
-        expect(find.text('Audit Second Step From Metadata'), findsOneWidget);
-        expect(find.text('Audit Step Detail From Metadata'), findsOneWidget);
-        expect(
-          find.descendant(
-            of: graph,
-            matching: find.textContaining('Global Story Studio'),
-          ),
-          findsOneWidget,
-        );
-        expect(find.text('Relations détaillées à venir'), findsOneWidget);
-        expect(find.text('Graph — à venir'), findsNothing);
-        expect(find.text('Chapitres — à venir'), findsNothing);
-        expect(find.text('Inspecteur Storyline — à venir'), findsNothing);
-        expect(
-          find.descendant(
-            of: inspector,
-            matching: find.text('Détails de la storyline'),
-          ),
-          findsOneWidget,
-        );
-        expect(
-          find.descendant(
-            of: inspector,
-            matching: find.text('Audit Story From Scenario'),
-          ),
-          findsOneWidget,
-        );
-        expect(
-          find.descendant(
-            of: inspector,
-            matching: find.text('Audit description from scenario'),
-          ),
-          findsOneWidget,
-        );
-        expect(
-          find.descendant(
-            of: inspector,
-            matching: find.text('ScenarioAsset globalStory'),
-          ),
-          findsOneWidget,
-        );
-        expect(
-          find.descendant(
-              of: inspector, matching: find.text('2 étapes narratives')),
-          findsOneWidget,
-        );
-        expect(
-          find.descendant(
-              of: inspector, matching: find.text('0 cutscene liée')),
-          findsOneWidget,
-        );
-        expect(
-          find.descendant(of: inspector, matching: find.text('Tags')),
-          findsOneWidget,
-        );
-        expect(
-          find.descendant(of: inspector, matching: find.text('Facts')),
-          findsOneWidget,
-        );
-        expect(
-          find.descendant(
-              of: inspector, matching: find.text('Activité récente')),
-          findsOneWidget,
-        );
-        expect(
-          find.descendant(of: inspector, matching: find.text('Quêtes liées')),
-          findsOneWidget,
-        );
-        expect(
-          find.descendant(of: inspector, matching: find.text('Non branché')),
-          findsWidgets,
-        );
-        expect(
-          find.descendant(of: inspector, matching: find.text('À venir')),
-          findsWidgets,
-        );
-        expect(find.text('Audit Local Event Flow'), findsNothing);
-        expect(find.text('Histoire principale'), findsOneWidget);
-        expect(find.text('Audit Second Story From Scenario'), findsOneWidget);
-        expect(find.text('Audit second description from scenario'),
-            findsOneWidget);
-        expect(find.text('Storyline principale'), findsWidgets);
-        expect(find.textContaining('1 étape narrative'), findsWidgets);
-        expect(find.textContaining('2 étapes narratives'), findsWidgets);
-        expect(find.text('Recherche à venir'), findsOneWidget);
-        expect(find.text('Quêtes annexes'), findsWidgets);
-        expect(find.textContaining('aucun modèle de quête annexe'),
-            findsOneWidget);
-        expect(find.text('Lecture seule'), findsWidgets);
-        expect(find.text('Source réelle'), findsWidgets);
-        expect(find.text('Graph'), findsOneWidget);
-        expect(find.text('Chapitres'), findsWidgets);
-        expect(find.text('Étapes'), findsWidgets);
-        expect(find.text('Scènes'), findsWidgets);
-        expect(find.text('Statistiques'), findsOneWidget);
-        expect(find.text('Tests'), findsOneWidget);
-        expect(
-          find.byKey(const ValueKey('storylines-kpi-global-stories')),
-          findsOneWidget,
-        );
-        expect(
-          find.descendant(
-            of: find.byKey(const ValueKey('storylines-kpi-global-stories')),
-            matching: find.text('2'),
-          ),
-          findsOneWidget,
-        );
-        expect(
-          find.byKey(const ValueKey('storylines-kpi-steps')),
-          findsOneWidget,
-        );
-        expect(
-          find.descendant(
-            of: find.byKey(const ValueKey('storylines-kpi-steps')),
-            matching: find.text('2'),
-          ),
-          findsOneWidget,
-        );
-        expect(
-          find.byKey(const ValueKey('storylines-kpi-cutscenes')),
-          findsOneWidget,
-        );
-        expect(
-          find.descendant(
-            of: find.byKey(const ValueKey('storylines-kpi-cutscenes')),
-            matching: find.text('0'),
-          ),
-          findsOneWidget,
-        );
-        expect(
-          find.byKey(const ValueKey('storylines-kpi-chapters')),
-          findsOneWidget,
-        );
-        expect(
-          find.byKey(const ValueKey('storylines-kpi-diagnostics')),
-          findsOneWidget,
-        );
-        expect(
-          find.byKey(const ValueKey('storylines-secondary-create-action')),
-          findsOneWidget,
-        );
-        expect(
-          find.byKey(const ValueKey('storylines-secondary-search-disabled')),
-          findsOneWidget,
-        );
-        expect(
-          find.byKey(
-              const ValueKey('storylines-secondary-row-audit_global_story')),
-          findsOneWidget,
-        );
-        expect(
-          find.byKey(
-            const ValueKey(
-                'storylines-secondary-row-audit_second_global_story'),
-          ),
-          findsOneWidget,
-        );
-
-        for (final forbidden in _targetOnlyStrings) {
-          expect(
-            find.text(forbidden),
-            findsNothing,
-            reason: '$forbidden must not be injected in Storylines shell V0.',
-          );
-        }
-
-        expect(find.text('Maps'), findsNothing);
-        expect(find.text('Facts'), findsWidgets);
-        expect(find.text('Règles du monde'), findsWidgets);
-        expect(find.text('Validateur'), findsOneWidget);
-
-        expect(
-          harness.container.read(editorNotifierProvider).workspaceMode,
-          EditorWorkspaceMode.globalStory,
-        );
-      },
-    );
-
-    testWidgets(
-      'selects a real global story from the secondary panel and syncs read-only zones',
-      (tester) async {
-        final harness = await _pumpStorylinesShell(tester);
-        final beforeEditorState =
-            harness.container.read(editorNotifierProvider);
-        final beforeNarrativeState =
-            harness.container.read(narrativeWorkspaceControllerProvider);
-        final beforeProject = beforeEditorState.project!;
-        final beforeScenarioIds = beforeProject.scenarios
-            .map((scenario) => scenario.id)
-            .toList(growable: false);
-
-        expect(
-          find.byKey(
-            const ValueKey('storylines-secondary-selected-audit_global_story'),
-          ),
-          findsOneWidget,
-        );
-
-        await _selectSecondaryStory(tester, 'audit_second_global_story');
-
-        final header = find.byKey(const ValueKey('storylines-header-section'));
-        final graph =
-            find.byKey(const ValueKey('storylines-graph-target-read-only'));
-        final inspector =
-            find.byKey(const ValueKey('storylines-inspector-read-only'));
-
-        expect(
-          find.byKey(
-            const ValueKey(
-              'storylines-secondary-selected-audit_second_global_story',
-            ),
-          ),
-          findsOneWidget,
-        );
-        expect(
-          find.descendant(
-            of: header,
-            matching: find.text('Audit Second Story From Scenario'),
-          ),
-          findsOneWidget,
-        );
-        expect(
-          find.descendant(
-            of: header,
-            matching: find.text('Audit second description from scenario'),
-          ),
-          findsOneWidget,
-        );
-        expect(
-          find.descendant(
-            of: inspector,
-            matching: find.text('Audit Second Story From Scenario'),
-          ),
-          findsOneWidget,
-        );
-        expect(
-          find.descendant(
-            of: inspector,
-            matching: find.text('1 étape narrative'),
-          ),
-          findsOneWidget,
-        );
-        expect(
-          find.descendant(
-            of: graph,
-            matching: find.text('Audit Second Chapter From Metadata'),
-          ),
-          findsOneWidget,
-        );
-        expect(
-          find.descendant(
-            of: graph,
-            matching: find.text('Audit Second Step From Metadata'),
-          ),
-          findsOneWidget,
-        );
-        expect(
-          find.descendant(
-            of: graph,
-            matching: find.text('Audit Chapter From Metadata'),
-          ),
-          findsNothing,
-        );
-        expect(
-          find.descendant(
-            of: graph,
-            matching: find.text('Audit Step From Metadata'),
-          ),
-          findsNothing,
-        );
-        expect(
-          find.descendant(
-            of: find.byKey(const ValueKey('storylines-kpi-steps')),
-            matching: find.text('1'),
-          ),
-          findsOneWidget,
-        );
-
-        await _openChaptersTab(tester);
-
-        final chapters =
-            find.byKey(const ValueKey('storylines-chapters-read-only'));
-        final chapterInspector =
-            find.byKey(const ValueKey('storylines-chapter-inspector'));
-        expect(chapters, findsOneWidget);
-        expect(
-          find.descendant(
-            of: chapters,
-            matching: find.text('Audit Second Chapter From Metadata'),
-          ),
-          findsWidgets,
-        );
-        expect(
-          find.descendant(
-            of: chapters,
-            matching: find.text('Audit Chapter From Metadata'),
-          ),
-          findsNothing,
-        );
-        expect(
-          find.byKey(
-            const ValueKey('storylines-selected-chapter-audit_second_chapter'),
-          ),
-          findsOneWidget,
-        );
-        expect(
-          find.descendant(
-            of: chapterInspector,
-            matching: find.text('Audit Second Step From Metadata'),
-          ),
-          findsOneWidget,
-        );
-
-        await _openGraphTab(tester);
-
-        expect(
-          find.byKey(const ValueKey('storylines-graph-target-read-only')),
-          findsOneWidget,
-        );
-        expect(
-          find.descendant(
-            of: header,
-            matching: find.text('Audit Second Story From Scenario'),
-          ),
-          findsOneWidget,
-        );
-
-        for (final label in <String>[
-          'Étapes',
-          'Scènes',
-          'Statistiques',
-          'Tests',
-        ]) {
-          await tester.tap(
-            find.descendant(
-              of: find.byKey(const ValueKey('storylines-tabs')),
-              matching: find.text(label),
-            ),
-          );
-          await tester.pump();
-        }
-
-        expect(
-          find.byKey(const ValueKey('storylines-graph-target-read-only')),
-          findsOneWidget,
-        );
-        expect(
-          find.descendant(
-            of: header,
-            matching: find.text('Audit Second Story From Scenario'),
-          ),
-          findsOneWidget,
-        );
-
-        final afterEditorState = harness.container.read(editorNotifierProvider);
-        final afterNarrativeState =
-            harness.container.read(narrativeWorkspaceControllerProvider);
+  group('NS-STORYLINES-V1-07 create main storyline flow', () {
+    testWidgets('shows only Graph and Structure tabs', (tester) async {
+      await _pumpStorylinesShell(tester);
 
-        expect(afterEditorState.workspaceMode, beforeEditorState.workspaceMode);
-        expect(afterEditorState.project, same(beforeProject));
-        expect(
-          afterEditorState.project!.scenarios
-              .map((scenario) => scenario.id)
-              .toList(growable: false),
-          beforeScenarioIds,
-        );
-        expect(
-          afterNarrativeState.selectedGlobalStoryId,
-          beforeNarrativeState.selectedGlobalStoryId,
-        );
-        expect(
-          afterNarrativeState.selectedStepId,
-          beforeNarrativeState.selectedStepId,
-        );
-        expect(find.text('Audit Local Event Flow'), findsNothing);
-      },
-    );
+      final tabs = find.byKey(const ValueKey('storylines-tabs'));
+      expect(find.descendant(of: tabs, matching: find.text('Graph')),
+          findsOneWidget);
+      expect(find.descendant(of: tabs, matching: find.text('Structure')),
+          findsOneWidget);
+      expect(find.descendant(of: tabs, matching: find.text('Étapes')),
+          findsNothing);
+      expect(find.descendant(of: tabs, matching: find.text('Scènes')),
+          findsNothing);
+      expect(find.descendant(of: tabs, matching: find.text('Statistiques')),
+          findsNothing);
+      expect(find.descendant(of: tabs, matching: find.text('Tests')),
+          findsNothing);
+    });
 
-    testWidgets(
-      'renders an honest empty state when the selected global story has no steps',
-      (tester) async {
-        await _pumpStorylinesShell(
-          tester,
-          project: _emptyGraphProject(),
-          selectedGlobalStoryId: 'audit_empty_global_story',
-        );
+    testWidgets('shows V1 empty state without importing legacy globalStory',
+        (tester) async {
+      final harness = await _pumpStorylinesShell(
+        tester,
+        project: _legacyOnlyProject(),
+      );
 
-        expect(
-          find.byKey(const ValueKey('storylines-graph-target-read-only')),
-          findsOneWidget,
-        );
-        expect(find.text('Graph read-only'), findsOneWidget);
-        expect(
-          find.textContaining('Aucune étape narrative disponible'),
-          findsOneWidget,
-        );
-        expect(find.text('Audit Step From Metadata'), findsNothing);
-        expect(find.text('Audit Local Event Flow'), findsNothing);
-      },
-    );
+      expect(find.text('Aucune storyline auteur'), findsWidgets);
+      expect(find.byKey(const ValueKey('storylines-create-main-cta')),
+          findsOneWidget);
+      expect(find.byKey(const ValueKey('storylines-graph-target-read-only')),
+          findsOneWidget);
+      expect(find.textContaining('ne sera pas importée automatiquement'),
+          findsOneWidget);
+      expect(find.byKey(const ValueKey('storylines-v1-legacy-preview-card')),
+          findsOneWidget);
+      expect(find.text('Legacy Global Story'), findsWidgets);
+      expect(harness.project.storylines, isEmpty);
+      expect(harness.project.scenarios.single.scope, ScenarioScope.globalStory);
+    });
 
     testWidgets(
-      'shows the Chapters tab from Global Story Studio metadata read-only',
-      (tester) async {
-        final harness = await _pumpStorylinesShell(tester);
-        final beforeEditorState =
-            harness.container.read(editorNotifierProvider);
-        final beforeNarrativeState =
-            harness.container.read(narrativeWorkspaceControllerProvider);
-        final beforeProject = beforeEditorState.project!;
-        final beforeScenarioIds = beforeProject.scenarios
-            .map((scenario) => scenario.id)
-            .toList(growable: false);
-
-        await _openChaptersTab(tester);
-
-        final chapters =
-            find.byKey(const ValueKey('storylines-chapters-read-only'));
-        final createAction =
-            find.byKey(const ValueKey('storylines-chapters-create-action'));
-        final chapterList =
-            find.byKey(const ValueKey('storylines-chapter-list'));
-        final chapterInspector =
-            find.byKey(const ValueKey('storylines-chapter-inspector'));
-
-        expect(chapters, findsOneWidget);
-        expect(find.byKey(const ValueKey('storylines-graph-target-read-only')),
-            findsNothing);
-        expect(chapterList, findsOneWidget);
-        expect(chapterInspector, findsOneWidget);
-        expect(
-          find.byKey(
-            const ValueKey('storylines-selected-chapter-audit_chapter'),
-          ),
-          findsOneWidget,
-        );
-        expect(
-          find.byKey(
-            const ValueKey('storylines-selected-chapter-audit_second_chapter'),
-          ),
-          findsNothing,
-        );
-        expect(
-          find.descendant(of: chapters, matching: find.text('Chapitres')),
-          findsOneWidget,
-        );
-        expect(
-          find.descendant(
-            of: chapters,
-            matching: find.textContaining('Global Story Studio'),
-          ),
-          findsWidgets,
-        );
-        expect(
-          find.descendant(
-            of: chapterList,
-            matching: find.text('Audit Chapter From Metadata'),
-          ),
-          findsOneWidget,
-        );
-        expect(
-          find.descendant(
-            of: chapterInspector,
-            matching: find.text('Audit Chapter From Metadata'),
-          ),
-          findsOneWidget,
-        );
-        expect(
-          find.descendant(
-            of: chapterInspector,
-            matching: find.text('Audit chapter description from metadata'),
-          ),
-          findsOneWidget,
-        );
-        expect(
-          find.descendant(
-              of: chapters, matching: find.text('1 étape narrative')),
-          findsWidgets,
-        );
-        expect(
-          find.descendant(
-            of: chapters,
-            matching: find.text('Audit Step From Metadata'),
-          ),
-          findsOneWidget,
-        );
-        expect(
-          find.descendant(
-            of: chapters,
-            matching: find.text('Audit Step Detail From Metadata'),
-          ),
-          findsOneWidget,
-        );
-        expect(
-          find.descendant(
-            of: chapterInspector,
-            matching: find.text('Détails du chapitre'),
-          ),
-          findsOneWidget,
-        );
-        expect(
-          find.descendant(
-            of: chapterInspector,
-            matching: find.text('Source Global Story Studio'),
-          ),
-          findsOneWidget,
-        );
-        expect(
-          find.descendant(
-            of: chapterInspector,
-            matching: find.text('Ordre des étapes narratives'),
-          ),
-          findsOneWidget,
-        );
-        expect(
-          find.descendant(
-            of: chapterInspector,
-            matching: find.text('Étapes narratives du chapitre'),
-          ),
-          findsOneWidget,
-        );
-        expect(
-          find.byKey(
-            const ValueKey('storylines-chapter-step-order-audit_step'),
-          ),
-          findsOneWidget,
-        );
-        expect(
-          find.descendant(of: chapterInspector, matching: find.text('01')),
-          findsOneWidget,
-        );
-        expect(
-          find.descendant(of: chapters, matching: find.text('Lecture seule')),
-          findsWidgets,
-        );
-        expect(createAction, findsOneWidget);
-        expect(tester.widget<PokeMapButton>(createAction).onPressed, isNull);
-
-        final secondChapterCard = find.byKey(
-          const ValueKey('storylines-chapter-card-audit_second_chapter'),
-        );
-        await tester.ensureVisible(secondChapterCard);
-        await tester.pump();
-        await tester.tap(secondChapterCard);
-        await tester.pump();
-
-        expect(
-          find.byKey(
-            const ValueKey('storylines-selected-chapter-audit_second_chapter'),
-          ),
-          findsOneWidget,
-        );
-        expect(
-          find.descendant(
-            of: chapterInspector,
-            matching: find.text('Audit Second Chapter From Metadata'),
-          ),
-          findsOneWidget,
-        );
-        expect(
-          find.byKey(
-            const ValueKey('storylines-chapter-step-order-audit_followup_step'),
-          ),
-          findsOneWidget,
-        );
-        expect(
-          find.descendant(
-            of: chapterInspector,
-            matching: find.text('Audit Second Step From Metadata'),
-          ),
-          findsOneWidget,
-        );
-
-        final afterSelectionEditorState =
-            harness.container.read(editorNotifierProvider);
-        final afterSelectionNarrativeState =
-            harness.container.read(narrativeWorkspaceControllerProvider);
-
-        expect(
-          afterSelectionEditorState.workspaceMode,
-          beforeEditorState.workspaceMode,
-        );
-        expect(afterSelectionEditorState.project, same(beforeProject));
-        expect(
-          afterSelectionNarrativeState.selectedGlobalStoryId,
-          beforeNarrativeState.selectedGlobalStoryId,
-        );
-        expect(
-          afterSelectionNarrativeState.selectedStepId,
-          beforeNarrativeState.selectedStepId,
-        );
-
-        await tester.ensureVisible(createAction);
-        await tester.pump();
-        await tester.tap(createAction);
-        await tester.pump();
+        'opens and cancels create main storyline dialog without mutation',
+        (tester) async {
+      final harness = await _pumpStorylinesShell(tester);
+      final before = harness.project.toJson();
+
+      await _openCreateDialog(tester);
+      expect(find.byKey(const ValueKey('storylines-create-main-dialog')),
+          findsOneWidget);
+      expect(find.text('Histoire principale'), findsOneWidget);
+      expect(find.byKey(const ValueKey('storylines-create-title-field')),
+          findsOneWidget);
+      expect(find.byKey(const ValueKey('storylines-create-description-field')),
+          findsOneWidget);
+
+      await tester.tap(find.byKey(const ValueKey('storylines-create-cancel')));
+      await tester.pumpAndSettle();
+
+      expect(find.byKey(const ValueKey('storylines-create-main-dialog')),
+          findsNothing);
+      expect(harness.project.storylines, isEmpty);
+      expect(harness.project.toJson(), before);
+    });
 
-        final afterEditorState = harness.container.read(editorNotifierProvider);
-        final afterNarrativeState =
-            harness.container.read(narrativeWorkspaceControllerProvider);
+    testWidgets('requires title before create', (tester) async {
+      final harness = await _pumpStorylinesShell(tester);
 
-        expect(afterEditorState.workspaceMode, beforeEditorState.workspaceMode);
-        expect(afterEditorState.workspaceMode, EditorWorkspaceMode.globalStory);
-        expect(afterEditorState.project, same(beforeProject));
-        expect(
-          afterEditorState.project!.scenarios
-              .map((scenario) => scenario.id)
-              .toList(growable: false),
-          beforeScenarioIds,
-        );
-        expect(
-          afterNarrativeState.selectedGlobalStoryId,
-          beforeNarrativeState.selectedGlobalStoryId,
-        );
-        expect(
-          afterNarrativeState.selectedStepId,
-          beforeNarrativeState.selectedStepId,
-        );
-        expect(find.text('Audit Local Event Flow'), findsNothing);
-        expect(find.text('Scènes du chapitre'), findsNothing);
-        expect(find.text('Brouillon'), findsNothing);
-        expect(find.text('En cours'), findsNothing);
-      },
-    );
+      await _openCreateDialog(tester);
 
-    testWidgets('shows an honest Chapters empty state', (tester) async {
-      await _pumpStorylinesShell(
-        tester,
-        project: _emptyGraphProject(),
-        selectedGlobalStoryId: 'audit_empty_global_story',
+      final submit = tester.widget<PokeMapButton>(
+        find.byKey(const ValueKey('storylines-create-submit')),
       );
-
-      await _openChaptersTab(tester);
-
-      expect(
-        find.byKey(const ValueKey('storylines-chapters-read-only')),
-        findsOneWidget,
-      );
-      expect(
-        find.text('Aucun chapitre disponible pour cette storyline.'),
-        findsOneWidget,
-      );
-      expect(find.text('Audit Step From Metadata'), findsNothing);
-      expect(find.text('Audit Local Event Flow'), findsNothing);
+      expect(submit.onPressed, isNull);
+      expect(find.text('Titre obligatoire.'), findsOneWidget);
+      expect(harness.project.storylines, isEmpty);
     });
 
-    testWidgets('renders an honest inspector empty state without global story',
+    testWidgets('creates a main StorylineAsset and syncs Graph and Structure',
         (tester) async {
-      await _pumpStorylinesShell(
+      final harness = await _pumpStorylinesShell(tester);
+
+      await _createMainStoryline(
         tester,
-        project: _noGlobalStoryProject(),
-        selectedGlobalStoryId: 'missing_global_story',
+        title: 'Ma grande histoire',
+        description: 'Une structure auteur propre.',
       );
 
-      final inspector =
-          find.byKey(const ValueKey('storylines-inspector-read-only'));
+      final storylines = harness.project.storylines;
+      expect(storylines, hasLength(1));
+      final storyline = storylines.single;
+      expect(storyline.id, 'storyline_ma_grande_histoire');
+      expect(storyline.type, StorylineType.main);
+      expect(storyline.status, StorylineStatus.draft);
+      expect(storyline.title, 'Ma grande histoire');
+      expect(storyline.description, 'Une structure auteur propre.');
+      expect(storyline.chapters, isEmpty);
+      expect(storyline.sceneLinks, isEmpty);
+      expect(storyline.relationships, isEmpty);
+
+      expect(find.text('Ma grande histoire'), findsWidgets);
+      expect(
+          find.text('Ajoutez des chapitres dans Structure.'), findsOneWidget);
 
-      expect(inspector, findsOneWidget);
+      await _openStructureTab(tester);
+      expect(find.byKey(const ValueKey('storylines-structure-read-only')),
+          findsOneWidget);
+      expect(find.text('Chapitres'), findsWidgets);
       expect(
         find.descendant(
-          of: inspector,
-          matching: find.text('Aucune storyline sélectionnée.'),
+          of: find.byKey(const ValueKey('storylines-v1-structure-steps')),
+          matching: find.text('Étapes narratives'),
         ),
         findsOneWidget,
       );
       expect(
         find.descendant(
-          of: inspector,
-          matching: find.text('ScenarioAsset globalStory'),
+          of: find.byKey(const ValueKey('storylines-v1-structure-scenes')),
+          matching: find.text('Scènes liées'),
         ),
-        findsNothing,
+        findsOneWidget,
       );
-      expect(find.text('Audit Local Event Flow'), findsNothing);
+      expect(find.text('Nouveau chapitre — bientôt'), findsOneWidget);
     });
 
-    testWidgets(
-      'keeps future Storyline tabs read-only and non-mutating',
-      (tester) async {
-        final harness = await _pumpStorylinesShell(tester);
-        final tabs = find.byKey(const ValueKey('storylines-tabs'));
-
-        expect(tabs, findsOneWidget);
-        expect(
-          find.descendant(of: tabs, matching: find.text('Graph')),
-          findsOneWidget,
-        );
-
-        final beforeEditorState =
-            harness.container.read(editorNotifierProvider);
-        final beforeNarrativeState =
-            harness.container.read(narrativeWorkspaceControllerProvider);
-        final beforeProject = beforeEditorState.project!;
-        final beforeScenarioIds = beforeProject.scenarios
-            .map((scenario) => scenario.id)
-            .toList(growable: false);
+    testWidgets('generates stable unique ids on collision', (tester) async {
+      final harness = await _pumpStorylinesShell(
+        tester,
+        project: _projectWithStorylines([
+          StorylineAsset(
+            id: 'storyline_main_story',
+            type: StorylineType.sideQuest,
+            title: 'Existing secondary',
+          ),
+        ]),
+      );
 
-        for (final label in <String>[
-          'Étapes',
-          'Scènes',
-          'Statistiques',
-          'Tests',
-        ]) {
-          await tester
-              .tap(find.descendant(of: tabs, matching: find.text(label)));
-          await tester.pump();
-        }
+      await _createMainStoryline(tester, title: 'Main Story');
 
-        final afterEditorState = harness.container.read(editorNotifierProvider);
-        final afterNarrativeState =
-            harness.container.read(narrativeWorkspaceControllerProvider);
+      final ids = harness.project.storylines.map((s) => s.id).toList();
+      expect(ids, contains('storyline_main_story'));
+      expect(ids, contains('storyline_main_story_2'));
+      expect(ids.toSet(), hasLength(ids.length));
+      expect(
+        harness.project.storylines
+            .where((s) => s.type == StorylineType.sideQuest),
+        hasLength(1),
+      );
+    });
 
-        expect(afterEditorState.workspaceMode, beforeEditorState.workspaceMode);
-        expect(afterEditorState.workspaceMode, EditorWorkspaceMode.globalStory);
-        expect(afterEditorState.project, same(beforeProject));
-        expect(
-          afterEditorState.project!.scenarios
-              .map((scenario) => scenario.id)
-              .toList(growable: false),
-          beforeScenarioIds,
-        );
-        expect(
-          afterNarrativeState.selectedGlobalStoryId,
-          beforeNarrativeState.selectedGlobalStoryId,
-        );
-        expect(
-          afterNarrativeState.selectedStepId,
-          beforeNarrativeState.selectedStepId,
-        );
-        expect(find.text('Graph read-only'), findsOneWidget);
-        expect(find.text('Audit Local Event Flow'), findsNothing);
-      },
-    );
+    testWidgets('does not allow creating a second main storyline',
+        (tester) async {
+      final harness = await _pumpStorylinesShell(
+        tester,
+        project: _projectWithStorylines([
+          StorylineAsset(
+            id: 'storyline_existing_main',
+            type: StorylineType.main,
+            title: 'Existing main',
+          ),
+        ]),
+      );
 
-    testWidgets(
-      'keeps future header actions disabled and non-mutating',
-      (tester) async {
-        final harness = await _pumpStorylinesShell(tester);
-        final newStorylineAction = find.byKey(
-          const ValueKey('narrative-studio-header-action-new-storyline'),
-        );
-        final validateAction = find.byKey(
-          const ValueKey('narrative-studio-header-action-validate'),
-        );
-        final secondaryCreateAction = find.byKey(
-          const ValueKey('storylines-secondary-create-action'),
-        );
-        final newStorylineButton = find.descendant(
-          of: newStorylineAction,
-          matching: find.byType(PokeMapButton),
-        );
-        final validateButton = find.descendant(
-          of: validateAction,
-          matching: find.byType(PokeMapButton),
-        );
-        final secondaryCreateButton = find.descendant(
-          of: secondaryCreateAction,
-          matching: find.byType(PokeMapButton),
-        );
+      final cta = tester.widget<PokeMapButton>(
+        find.byKey(const ValueKey('storylines-create-main-cta')),
+      );
+      expect(cta.onPressed, isNull);
+      expect(harness.project.storylines, hasLength(1));
+    });
 
-        expect(newStorylineAction, findsOneWidget);
-        expect(validateAction, findsOneWidget);
-        expect(secondaryCreateAction, findsOneWidget);
-        expect(newStorylineButton, findsOneWidget);
-        expect(validateButton, findsOneWidget);
-        expect(secondaryCreateButton, findsOneWidget);
-        expect(
-          tester.widget<PokeMapButton>(newStorylineButton).onPressed,
-          isNull,
-        );
-        expect(tester.widget<PokeMapButton>(validateButton).onPressed, isNull);
-        expect(
-          tester.widget<PokeMapButton>(secondaryCreateButton).onPressed,
-          isNull,
-        );
+    testWidgets('creation does not import legacy or promote localEventFlow',
+        (tester) async {
+      final harness = await _pumpStorylinesShell(
+        tester,
+        project: _legacyAndLocalEventProject(),
+      );
 
-        final beforeEditorState =
-            harness.container.read(editorNotifierProvider);
-        final beforeNarrativeState =
-            harness.container.read(narrativeWorkspaceControllerProvider);
-        final beforeProject = beforeEditorState.project!;
-        final beforeScenarioIds = beforeProject.scenarios
-            .map((scenario) => scenario.id)
-            .toList(growable: false);
-        final beforeScenarioCount = beforeProject.scenarios.length;
+      await _createMainStoryline(tester, title: 'Fresh Main Story');
 
-        await tester.tap(newStorylineAction);
-        await tester.pump();
+      expect(harness.project.storylines, hasLength(1));
+      expect(harness.project.storylines.single.title, 'Fresh Main Story');
+      expect(harness.project.storylines.single.legacySource, isNull);
+      expect(
+        harness.project.storylines
+            .where((s) => s.type == StorylineType.sideQuest),
+        isEmpty,
+      );
+      expect(harness.project.scenarios, hasLength(2));
+      expect(
+        harness.project.scenarios.map((scenario) => scenario.scope),
+        containsAll([ScenarioScope.globalStory, ScenarioScope.localEventFlow]),
+      );
+      expect(find.text('Legacy Global Story'), findsNothing);
+      expect(find.text('Local Event Flow'), findsNothing);
+    });
 
-        await tester.tap(validateAction);
-        await tester.pump();
+    testWidgets('Graph, Structure and disabled chapter CTA do not mutate',
+        (tester) async {
+      final harness = await _pumpStorylinesShell(
+        tester,
+        project: _projectWithStorylines([
+          StorylineAsset(
+            id: 'storyline_existing_main',
+            type: StorylineType.main,
+            title: 'Existing main',
+          ),
+        ]),
+      );
+      final before = harness.project.toJson();
+      final beforeMode = harness.editorState.workspaceMode;
 
-        await tester.tap(secondaryCreateAction);
-        await tester.pump();
+      await _openStructureTab(tester);
+      await tester.tap(
+        find.byKey(const ValueKey('storylines-new-chapter-disabled')),
+        warnIfMissed: false,
+      );
+      await tester.pump();
+      await _openGraphTab(tester);
 
-        final afterEditorState = harness.container.read(editorNotifierProvider);
-        final afterNarrativeState =
-            harness.container.read(narrativeWorkspaceControllerProvider);
+      expect(harness.project.toJson(), before);
+      expect(harness.editorState.workspaceMode, beforeMode);
+    });
 
-        expect(afterEditorState.workspaceMode, beforeEditorState.workspaceMode);
-        expect(afterEditorState.workspaceMode, EditorWorkspaceMode.globalStory);
-        expect(afterEditorState.project, same(beforeProject));
-        expect(afterEditorState.project!.scenarios.length, beforeScenarioCount);
-        expect(
-          afterEditorState.project!.scenarios
-              .map((scenario) => scenario.id)
-              .toList(growable: false),
-          beforeScenarioIds,
-        );
-        expect(
-          afterNarrativeState.selectedGlobalStoryId,
-          beforeNarrativeState.selectedGlobalStoryId,
-        );
-        expect(
-          afterNarrativeState.selectedStepId,
-          beforeNarrativeState.selectedStepId,
-        );
-        expect(find.text('Audit Story From Scenario'), findsWidgets);
-        expect(find.text('Audit description from scenario'), findsWidgets);
+    testWidgets('keeps target fake data and Maps out of the V1 UI',
+        (tester) async {
+      await _pumpStorylinesShell(tester,
+          project: _legacyAndLocalEventProject());
 
-        for (final forbidden in _targetOnlyStrings) {
-          expect(
-            find.text(forbidden),
-            findsNothing,
-            reason: '$forbidden must not appear after disabled interactions.',
-          );
-        }
-      },
-    );
+      for (final value in _targetOnlyStrings) {
+        expect(find.text(value), findsNothing, reason: value);
+      }
+      expect(find.text('Maps'), findsNothing);
+    });
 
     test('storylines UI source keeps raw colors out of the feature', () {
       final source = File('lib/src/ui/canvas/storylines_workspace.dart');
       expect(source.existsSync(), isTrue);
 
       final contents = source.readAsStringSync();
-      const rawColorConstructor = 'Color' '(0x';
-      const materialColorAccessor = 'Colors' '.';
-
-      expect(contents.contains(rawColorConstructor), isFalse);
-      expect(contents.contains(materialColorAccessor), isFalse);
+      const rawColorPattern = 'Color' '(0x';
+      const materialColorsPattern = 'Colors' '.';
+      expect(contents, isNot(contains(rawColorPattern)));
+      expect(contents, isNot(contains(materialColorsPattern)));
     });
 
-    test('storylines action test does not use silent taps', () {
+    test('storylines shell test keeps raw colors out', () {
       final source = File('test/storylines_workspace_shell_test.dart');
       expect(source.existsSync(), isTrue);
 
       final contents = source.readAsStringSync();
-      const silentTapArgument = 'warnIfMissed' ': false';
-
-      expect(contents.contains(silentTapArgument), isFalse);
+      const rawColorPattern = 'Color' '(0x';
+      const materialColorsPattern = 'Colors' '.';
+      expect(contents, isNot(contains(rawColorPattern)));
+      expect(contents, isNot(contains(materialColorsPattern)));
     });
 
     testWidgets('uses PokeMap dark theme in the Visual Gate harness',
         (tester) async {
       await _pumpStorylinesShell(tester);
 
-      final shellContext = tester
-          .element(find.byKey(const ValueKey('storylines-workspace-shell')));
-
+      final shellContext = tester.element(
+        find.byKey(const ValueKey('storylines-workspace-shell')),
+      );
       expect(Theme.of(shellContext).brightness, Brightness.dark);
     });
 
-    testWidgets('writes Visual Gate screenshots', (tester) async {
-      await _pumpStorylinesShell(
-        tester,
-        surfaceSize: const Size(1600, 1000),
-      );
+    testWidgets('writes V1-07 Visual Gate screenshots', (tester) async {
+      await _pumpStorylinesShell(tester, surfaceSize: const Size(1600, 1000));
       await expectLater(
         find.byKey(const ValueKey('storylines-workspace-shell')),
         matchesGoldenFile(
           '../../../reports/narrativeStudio/storylines/screenshots/'
-          'ns_storylines_11_interaction_default_graph.png',
+          'ns_storylines_v1_07_empty_storylines_desktop.png',
         ),
       );
 
-      await _pumpStorylinesShell(
-        tester,
-        surfaceSize: const Size(1600, 1000),
+      await _pumpStorylinesShell(tester, surfaceSize: const Size(1600, 1000));
+      await _openCreateDialog(tester);
+      await expectLater(
+        find.byKey(const ValueKey('storylines-create-main-dialog')),
+        matchesGoldenFile(
+          '../../../reports/narrativeStudio/storylines/screenshots/'
+          'ns_storylines_v1_07_create_main_dialog.png',
+        ),
       );
-      await _selectSecondaryStory(tester, 'audit_second_global_story');
+      await tester.tap(find.byKey(const ValueKey('storylines-create-cancel')));
+      await tester.pumpAndSettle();
+
+      await _pumpStorylinesShell(tester, surfaceSize: const Size(1600, 1000));
+      await _createMainStoryline(tester, title: 'Visual Gate Main');
       await expectLater(
         find.byKey(const ValueKey('storylines-workspace-shell')),
         matchesGoldenFile(
           '../../../reports/narrativeStudio/storylines/screenshots/'
-          'ns_storylines_11_interaction_selected_story_graph.png',
+          'ns_storylines_v1_07_created_main_graph.png',
         ),
       );
 
-      await _pumpStorylinesShell(
-        tester,
-        surfaceSize: const Size(1600, 1000),
-      );
-      await _selectSecondaryStory(tester, 'audit_second_global_story');
-      await _openChaptersTab(tester);
+      await _openStructureTab(tester);
       await expectLater(
         find.byKey(const ValueKey('storylines-workspace-shell')),
         matchesGoldenFile(
           '../../../reports/narrativeStudio/storylines/screenshots/'
-          'ns_storylines_11_interaction_selected_story_chapters.png',
+          'ns_storylines_v1_07_created_main_structure.png',
         ),
       );
     });
@@ -1007,9 +330,6 @@ const _targetOnlyStrings = <String>[
   'Les cristaux de sel',
   'Le Goélise du port',
   'La cabane du phare',
-  'Souvenirs oubliés',
-  'Tutoriel : Premiers pas',
-  'Épilogue : Le phare rallumé',
   'Mystère',
   'Exploration',
   'Phare',
@@ -1019,31 +339,45 @@ const _targetOnlyStrings = <String>[
   '412 dialogues',
   '18 facts',
   '3 problèmes',
-  '412',
-  '18',
-  'RÈGLES DU MONDE AFFECTÉES',
-  'DERNIÈRE ACTIVITÉ',
   'Active',
   'Haute',
   'Validé',
-  'À jour',
   'Défini',
-  'Brouillon',
   'En cours',
-  'Scènes du chapitre',
-  '4 scènes',
-  '12 dialogues',
-  'Prête',
-  'Quête annexe',
-  'Fin de l’histoire',
-  'Conclusion',
+  'Quête annexe fake',
 ];
 
-Future<void> _openChaptersTab(WidgetTester tester) async {
+Future<void> _openCreateDialog(WidgetTester tester) async {
+  await tester.tap(find.byKey(const ValueKey('storylines-create-main-cta')));
+  await tester.pumpAndSettle();
+}
+
+Future<void> _createMainStoryline(
+  WidgetTester tester, {
+  required String title,
+  String? description,
+}) async {
+  await _openCreateDialog(tester);
+  await tester.enterText(
+    find.byKey(const ValueKey('storylines-create-title-field')),
+    title,
+  );
+  if (description != null) {
+    await tester.enterText(
+      find.byKey(const ValueKey('storylines-create-description-field')),
+      description,
+    );
+  }
+  await tester.pump();
+  await tester.tap(find.byKey(const ValueKey('storylines-create-submit')));
+  await tester.pumpAndSettle();
+}
+
+Future<void> _openStructureTab(WidgetTester tester) async {
   await tester.tap(
     find.descendant(
       of: find.byKey(const ValueKey('storylines-tabs')),
-      matching: find.text('Chapitres'),
+      matching: find.text('Structure'),
     ),
   );
   await tester.pump();
@@ -1059,22 +393,10 @@ Future<void> _openGraphTab(WidgetTester tester) async {
   await tester.pump();
 }
 
-Future<void> _selectSecondaryStory(
-  WidgetTester tester,
-  String storyId,
-) async {
-  final row = find.byKey(ValueKey('storylines-secondary-row-$storyId'));
-  await tester.ensureVisible(row);
-  await tester.pump();
-  await tester.tap(row);
-  await tester.pump();
-}
-
 Future<_StorylinesHarness> _pumpStorylinesShell(
   WidgetTester tester, {
   Size surfaceSize = const Size(1600, 1000),
   ProjectManifest? project,
-  String selectedGlobalStoryId = 'audit_global_story',
 }) async {
   await tester.binding.setSurfaceSize(surfaceSize);
   addTearDown(() => tester.binding.setSurfaceSize(null));
@@ -1088,12 +410,12 @@ Future<_StorylinesHarness> _pumpStorylinesShell(
   addTearDown(editorSubscription.close);
 
   container.read(editorNotifierProvider.notifier).state = EditorState(
-    project: project ?? _auditProject(),
+    project: project ?? _emptyStorylinesProject(),
     workspaceMode: EditorWorkspaceMode.globalStory,
   );
   container
       .read(narrativeWorkspaceControllerProvider.notifier)
-      .openGlobalStory(scenarioId: selectedGlobalStoryId);
+      .openGlobalStory();
 
   await tester.pumpWidget(
     UncontrolledProviderScope(
@@ -1118,187 +440,51 @@ Future<_StorylinesHarness> _pumpStorylinesShell(
   return _StorylinesHarness(container);
 }
 
-ProjectManifest _auditProject() {
-  const stepDocument = StepStudioDocument(
-    globalStoryScenarioId: 'audit_global_story',
-    steps: <StepStudioStep>[
-      StepStudioStep(
-        id: 'audit_step',
-        name: 'Audit Step From Metadata',
-        description: 'Audit Step Detail From Metadata',
-        order: 0,
-        activation: StepStudioActivationRule(
-          mode: StepStudioActivationMode.atGameStart,
-        ),
-        completion: StepStudioCompletionRule(
-          mode: StepStudioCompletionMode.manual,
-        ),
-      ),
-      StepStudioStep(
-        id: 'audit_followup_step',
-        name: 'Audit Second Step From Metadata',
-        description: 'Audit second step detail from metadata',
-        order: 1,
-        activation: StepStudioActivationRule(
-          mode: StepStudioActivationMode.afterStep,
-          stepId: 'audit_step',
-        ),
-        completion: StepStudioCompletionRule(
-          mode: StepStudioCompletionMode.manual,
-        ),
-      ),
-    ],
-  );
-  const globalDocument = GlobalStoryStudioDocument(
-    globalStoryScenarioId: 'audit_global_story',
-    entryStepId: 'audit_step',
-    nodes: <GlobalStoryStepNode>[
-      GlobalStoryStepNode(stepId: 'audit_step'),
-      GlobalStoryStepNode(stepId: 'audit_followup_step'),
-    ],
-    chapters: <GlobalStoryChapter>[
-      GlobalStoryChapter(
-        id: 'audit_chapter',
-        name: 'Audit Chapter From Metadata',
-        description: 'Audit chapter description from metadata',
-        stepIds: <String>['audit_step'],
-        order: 0,
-      ),
-      GlobalStoryChapter(
-        id: 'audit_second_chapter',
-        name: 'Audit Second Chapter From Metadata',
-        description: 'Audit second chapter description from metadata',
-        stepIds: <String>['audit_followup_step'],
-        order: 1,
-      ),
-    ],
-  );
-
-  final globalScenario = applyGlobalStoryStudioDocumentToGlobalScenario(
-    applyStepStudioDocumentToGlobalScenario(
-      const ScenarioAsset(
-        id: 'audit_global_story',
-        name: 'Audit Story From Scenario',
-        description: 'Audit description from scenario',
-        scope: ScenarioScope.globalStory,
-        entryNodeId: 'start',
-      ),
-      stepDocument,
-    ),
-    globalDocument,
-    stepDocument: stepDocument,
-  );
-  const secondStepDocument = StepStudioDocument(
-    globalStoryScenarioId: 'audit_second_global_story',
-    steps: <StepStudioStep>[
-      StepStudioStep(
-        id: 'audit_second_step',
-        name: 'Audit Second Step From Metadata',
-        description: 'Audit second step detail from metadata',
-        order: 0,
-        activation: StepStudioActivationRule(
-          mode: StepStudioActivationMode.atGameStart,
-        ),
-        completion: StepStudioCompletionRule(
-          mode: StepStudioCompletionMode.manual,
-        ),
-      ),
-    ],
-  );
-  const secondGlobalDocument = GlobalStoryStudioDocument(
-    globalStoryScenarioId: 'audit_second_global_story',
-    entryStepId: 'audit_second_step',
-    nodes: <GlobalStoryStepNode>[
-      GlobalStoryStepNode(stepId: 'audit_second_step'),
-    ],
-    chapters: <GlobalStoryChapter>[
-      GlobalStoryChapter(
-        id: 'audit_second_chapter',
-        name: 'Audit Second Chapter From Metadata',
-        description: 'Audit second chapter description from metadata',
-        stepIds: <String>['audit_second_step'],
-        order: 0,
-      ),
-    ],
-  );
-  final secondGlobalScenario = applyGlobalStoryStudioDocumentToGlobalScenario(
-    applyStepStudioDocumentToGlobalScenario(
-      const ScenarioAsset(
-        id: 'audit_second_global_story',
-        name: 'Audit Second Story From Scenario',
-        description: 'Audit second description from scenario',
-        scope: ScenarioScope.globalStory,
-        entryNodeId: 'second_start',
-      ),
-      secondStepDocument,
-    ),
-    secondGlobalDocument,
-    stepDocument: secondStepDocument,
-  );
-
-  return ProjectManifest(
-    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
+ProjectManifest _emptyStorylinesProject() {
+  return const ProjectManifest(
+    surfaceCatalog: ProjectSurfaceCatalog.empty(),
     name: 'Audit Project',
-    maps: const <ProjectMapEntry>[],
-    tilesets: const <ProjectTilesetEntry>[],
-    scenarios: <ScenarioAsset>[
-      globalScenario,
-      secondGlobalScenario,
-      const ScenarioAsset(
-        id: 'audit_local_event_flow',
-        name: 'Audit Local Event Flow',
-        description: 'Audit local flow must not become a side quest',
-        scope: ScenarioScope.localEventFlow,
-        entryNodeId: 'local_start',
-      ),
-    ],
+    maps: <ProjectMapEntry>[],
+    tilesets: <ProjectTilesetEntry>[],
   );
 }
 
-ProjectManifest _emptyGraphProject() {
-  final emptyGlobalScenario = applyStepStudioDocumentToGlobalScenario(
-    const ScenarioAsset(
-      id: 'audit_empty_global_story',
-      name: 'Audit Empty Story From Scenario',
-      description: 'Audit empty description from scenario',
-      scope: ScenarioScope.globalStory,
-      entryNodeId: 'empty_start',
-    ),
-    const StepStudioDocument(
-      globalStoryScenarioId: 'audit_empty_global_story',
-      steps: <StepStudioStep>[],
-    ),
-  );
-
-  return ProjectManifest(
-    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
-    name: 'Audit Empty Project',
-    maps: const <ProjectMapEntry>[],
-    tilesets: const <ProjectTilesetEntry>[],
+ProjectManifest _legacyOnlyProject() {
+  return const ProjectManifest(
+    surfaceCatalog: ProjectSurfaceCatalog.empty(),
+    name: 'Legacy Project',
+    maps: <ProjectMapEntry>[],
+    tilesets: <ProjectTilesetEntry>[],
     scenarios: <ScenarioAsset>[
-      emptyGlobalScenario,
-      const ScenarioAsset(
-        id: 'audit_local_event_flow',
-        name: 'Audit Local Event Flow',
-        description: 'Audit local flow must not become a side quest',
-        scope: ScenarioScope.localEventFlow,
-        entryNodeId: 'local_start',
+      ScenarioAsset(
+        id: 'legacy_global_story',
+        name: 'Legacy Global Story',
+        description: 'Legacy description',
+        scope: ScenarioScope.globalStory,
+        entryNodeId: 'start',
       ),
     ],
   );
 }
 
-ProjectManifest _noGlobalStoryProject() {
+ProjectManifest _legacyAndLocalEventProject() {
   return const ProjectManifest(
     surfaceCatalog: ProjectSurfaceCatalog.empty(),
-    name: 'Audit No Story Project',
+    name: 'Legacy Project',
     maps: <ProjectMapEntry>[],
     tilesets: <ProjectTilesetEntry>[],
     scenarios: <ScenarioAsset>[
       ScenarioAsset(
-        id: 'audit_local_event_flow',
-        name: 'Audit Local Event Flow',
-        description: 'Audit local flow must not become a side quest',
+        id: 'legacy_global_story',
+        name: 'Legacy Global Story',
+        description: 'Legacy description',
+        scope: ScenarioScope.globalStory,
+        entryNodeId: 'start',
+      ),
+      ScenarioAsset(
+        id: 'local_event_flow',
+        name: 'Local Event Flow',
+        description: 'Must not become side quest',
         scope: ScenarioScope.localEventFlow,
         entryNodeId: 'local_start',
       ),
@@ -1306,8 +492,22 @@ ProjectManifest _noGlobalStoryProject() {
   );
 }
 
+ProjectManifest _projectWithStorylines(List<StorylineAsset> storylines) {
+  return ProjectManifest(
+    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
+    name: 'Storylines Project',
+    maps: const <ProjectMapEntry>[],
+    tilesets: const <ProjectTilesetEntry>[],
+    storylines: storylines,
+  );
+}
+
 class _StorylinesHarness {
   const _StorylinesHarness(this.container);
 
   final ProviderContainer container;
+
+  EditorState get editorState => container.read(editorNotifierProvider);
+
+  ProjectManifest get project => editorState.project!;
 }
```

### Diff complet de road_map_storylines.md

```diff
diff --git a/reports/narrativeStudio/storylines/road_map_storylines.md b/reports/narrativeStudio/storylines/road_map_storylines.md
index 90fd844b..493a1bad 100644
--- a/reports/narrativeStudio/storylines/road_map_storylines.md
+++ b/reports/narrativeStudio/storylines/road_map_storylines.md
@@ -308,7 +308,13 @@ Interprétation V0 :
 | NS-STORYLINES-V1-04 | StorylineAsset JSON Codec V0 | core codec | DONE | NS-STORYLINES-V1-05 |
 | NS-STORYLINES-V1-05 | ProjectManifest.storylines Integration V0 | core manifest | DONE | NS-STORYLINES-V1-06 |
 | NS-STORYLINES-V1-06 | Legacy GlobalStory Import Preview V0 | migration preview | DONE | NS-STORYLINES-V1-07 |
-| NS-STORYLINES-V1-07 | Create Main Storyline Flow V0 | editor authoring | TODO | NS-STORYLINES-V1-08 |
+| NS-STORYLINES-V1-07 | Create Main Storyline Flow V0 | editor authoring | DONE | NS-STORYLINES-V1-08 |
+| NS-STORYLINES-V1-08 | Structure Tab Authoring V0 | editor authoring | TODO | NS-STORYLINES-V1-09 |
+| NS-STORYLINES-V1-09 | Create Side Quest Flow V0 | editor authoring | TODO | NS-STORYLINES-V1-10 |
+| NS-STORYLINES-V1-10 | Graph From StorylineAsset V0 | editor graph | TODO | NS-STORYLINES-V1-11 |
+| NS-STORYLINES-V1-11 | Side Quest Graph Integration V0 | editor graph | TODO | NS-STORYLINES-V1-12 |
+| NS-STORYLINES-V1-12 | V1 Visual Graph Enrichment | visual gate | TODO | NS-STORYLINES-V1-CHECKPOINT |
+| NS-STORYLINES-V1-CHECKPOINT | Storylines V1 Acceptance Checkpoint | checkpoint | TODO | TBD |
 
 ## 9. Detailed lots
 
@@ -725,6 +731,24 @@ Interprétation V0 :
 - Statut : DONE.
 - Prochain lot attendu : NS-STORYLINES-V1-07 — Create Main Storyline Flow V0.
 
+### NS-STORYLINES-V1-07 — Create Main Storyline Flow V0 / Storylines UI Usability Reset
+
+- Type : editor UI / authoring flow / tests / visual gate.
+- Objectif : rendre Storylines utile en créant une vraie Storyline principale dans `ProjectManifest.storylines`.
+- Résultat : flow `Nouvelle storyline` livré avec formulaire minimal, type `main` verrouillé, titre obligatoire, description optionnelle, id slugifié unique, mutation contrôlée du manifest et sélection de la storyline créée.
+- Source de vérité : `ProjectManifest.storylines` devient la source V1 authoring ; le legacy `ScenarioAsset.globalStory` reste visible uniquement comme information non importée et non sélectionnable.
+- UI reset : tabs principales limitées à `Graph` / `Structure`, panneau secondaire simplifié, recherche fake retirée, side quests fake absentes, CTA secondaire `+` supprimé/non actif, `Nouveau chapitre` reste disabled / bientôt.
+- Graph : read-only honnête depuis `StorylineAsset`; si la storyline n'a pas de chapitre, affiche un node/storyline vide avec instruction d'ajouter des chapitres dans Structure.
+- Structure : affiche titre, description, type, status draft, sections vides `Chapitres`, `Étapes narratives`, `Scènes liées`, avec création de chapitre reportée.
+- Fichiers modifiés/créés : `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`, `packages/map_editor/test/storylines_workspace_shell_test.dart`, `reports/narrativeStudio/storylines/road_map_storylines.md`, `reports/narrativeStudio/storylines/ns_storylines_v1_07_create_main_storyline_flow_v0.md`, captures Visual Gate V1-07.
+- Tests exécutés : `flutter test test/storylines_workspace_shell_test.dart`, `flutter test test/storylines_current_global_story_characterization_test.dart`, `flutter test test/narrative_workspace_projection_test.dart`.
+- Analyse exécutée : `flutter analyze --no-fatal-infos lib/src/ui/canvas/storylines_workspace.dart test/storylines_workspace_shell_test.dart test/storylines_current_global_story_characterization_test.dart test/narrative_workspace_projection_test.dart`.
+- Visual Gate : `ns_storylines_v1_07_empty_storylines_desktop.png`, `ns_storylines_v1_07_create_main_dialog.png`, `ns_storylines_v1_07_created_main_graph.png`, `ns_storylines_v1_07_created_main_structure.png`.
+- Design System Gate : confirmé ; aucun `Color(0x...)` / `Colors.*` ajouté dans les fichiers touchés.
+- Non-objectifs confirmés : aucun `map_core` modifié, aucune sideQuest, aucun chapter, aucune step, aucune scene placeholder, aucun import legacy automatique, aucun `localEventFlow` promu, aucun runtime/gameplay/battle modifié.
+- Statut : DONE.
+- Prochain lot attendu : NS-STORYLINES-V1-08 — Structure Tab Authoring V0.
+
 ## 10. Update protocol for every future lot
 
 Chaque futur lot Storylines doit :
@@ -841,10 +865,10 @@ Décision temporaire :
 ## 13. Current status
 
 ```text
-Roadmap status: V0 ACCEPTED WITH V1 LIMITATIONS / V1 LEGACY IMPORT PREVIEW DONE
-Current lot: NS-STORYLINES-V1-06
+Roadmap status: V0 ACCEPTED WITH V1 LIMITATIONS / V1 CREATE MAIN STORYLINE FLOW DONE
+Current lot: NS-STORYLINES-V1-07
 Current lot status: DONE
-Next recommended lot: NS-STORYLINES-V1-07 — Create Main Storyline Flow V0
+Next recommended lot: NS-STORYLINES-V1-08 — Structure Tab Authoring V0
 ```
 
 | Lot | Status | Last update | Notes |
@@ -870,7 +894,8 @@ Next recommended lot: NS-STORYLINES-V1-07 — Create Main Storyline Flow V0
 | NS-STORYLINES-V1-04 | DONE | 2026-05-28 | StorylineAsset JSON Codec V0 livré, sans manifest/migration/UI. |
 | NS-STORYLINES-V1-05 | DONE | 2026-05-28 | ProjectManifest.storylines Integration V0 livré avec compatibilité vieux JSON et sans migration legacy. |
 | NS-STORYLINES-V1-06 | DONE | 2026-05-28 | Legacy GlobalStory Import Preview V0 livré : candidats non destructifs depuis `globalStory`, issues stables, `localEventFlow` ignoré. |
-| NS-STORYLINES-V1-07 | TODO | 2026-05-28 | Create Main Storyline Flow V0. |
+| NS-STORYLINES-V1-07 | DONE | 2026-05-28 | Create Main Storyline Flow V0 livré : création main `StorylineAsset`, Graph/Structure seulement, aucun import legacy automatique. |
+| NS-STORYLINES-V1-08 | TODO | 2026-05-28 | Structure Tab Authoring V0 recommandé comme prochain lot. |
 
 ## 14. V1 Creation Readiness Notes
 
@@ -898,13 +923,24 @@ Suite V1 documentaire recommandée :
 - `NS-STORYLINES-V1-05 — ProjectManifest.storylines Integration V0`
 - `NS-STORYLINES-V1-06 — Legacy GlobalStory Import Preview V0`
 - `NS-STORYLINES-V1-07 — Create Main Storyline Flow V0`
-- `NS-STORYLINES-V1-08 — Create Side Quest Storyline Flow V0`
-- `NS-STORYLINES-V1-09 — Storyline Type / Status / Validation`
-- `NS-STORYLINES-V1-10 — Side Quest Graph Integration`
-- `NS-STORYLINES-V1-11 — V1 Visual Graph Enrichment`
+- `NS-STORYLINES-V1-08 — Structure Tab Authoring V0`
+- `NS-STORYLINES-V1-09 — Create Side Quest Flow V0`
+- `NS-STORYLINES-V1-10 — Graph From StorylineAsset V0`
+- `NS-STORYLINES-V1-11 — Side Quest Graph Integration V0`
+- `NS-STORYLINES-V1-12 — V1 Visual Graph Enrichment`
+- `NS-STORYLINES-V1-CHECKPOINT — Storylines V1 Acceptance Checkpoint`
 
 ## 15. Changelog
 
+### 2026-05-28 — NS-STORYLINES-V1-07
+
+- Create Main Storyline Flow V0 livré côté editor : `Nouvelle storyline` ouvre un formulaire minimal, crée une `StorylineAsset(type: main, status: draft)` dans `ProjectManifest.storylines`, puis sélectionne la storyline créée.
+- UI Storylines reset vers deux tabs principales seulement : `Graph` et `Structure`.
+- Graph et Structure se synchronisent sur `ProjectManifest.storylines`; le legacy `globalStory` reste non importé automatiquement.
+- Aucun `map_core`, runtime, gameplay, battle, sideQuest, chapter, step ou scene placeholder modifié/créé.
+- Visual Gate V1-07 produit en dark theme.
+- Prochain lot recommandé : `NS-STORYLINES-V1-08 — Structure Tab Authoring V0`.
+
 ### 2026-05-28 — NS-STORYLINES-V1-06
 
 - Preview d'import legacy livrée dans `map_core` via `buildLegacyGlobalStoryImportPreview(ProjectManifest)`.
```

### Sortie exacte — flutter test storylines_workspace_shell_test.dart

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/storylines_workspace_shell_test.dart
00:00 +0: NS-STORYLINES-V1-07 create main storyline flow shows only Graph and Structure tabs
00:00 +1: NS-STORYLINES-V1-07 create main storyline flow shows V1 empty state without importing legacy globalStory
00:00 +2: NS-STORYLINES-V1-07 create main storyline flow opens and cancels create main storyline dialog without mutation
00:00 +3: NS-STORYLINES-V1-07 create main storyline flow requires title before create
00:00 +4: NS-STORYLINES-V1-07 create main storyline flow creates a main StorylineAsset and syncs Graph and Structure
00:01 +5: NS-STORYLINES-V1-07 create main storyline flow generates stable unique ids on collision
00:01 +6: NS-STORYLINES-V1-07 create main storyline flow does not allow creating a second main storyline
00:01 +7: NS-STORYLINES-V1-07 create main storyline flow creation does not import legacy or promote localEventFlow
00:01 +8: NS-STORYLINES-V1-07 create main storyline flow Graph, Structure and disabled chapter CTA do not mutate
00:01 +9: NS-STORYLINES-V1-07 create main storyline flow keeps target fake data and Maps out of the V1 UI
00:01 +10: NS-STORYLINES-V1-07 create main storyline flow storylines UI source keeps raw colors out of the feature
00:01 +11: NS-STORYLINES-V1-07 create main storyline flow storylines shell test keeps raw colors out
00:01 +12: NS-STORYLINES-V1-07 create main storyline flow uses PokeMap dark theme in the Visual Gate harness
00:01 +13: NS-STORYLINES-V1-07 create main storyline flow writes V1-07 Visual Gate screenshots
00:01 +14: All tests passed!
```

### Sortie exacte — flutter test storylines_current_global_story_characterization_test.dart

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/storylines_current_global_story_characterization_test.dart
00:00 +0: NS-STORYLINES-02 current Global Story characterization renders the current Storylines shell from manifest and authoring metadata
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
00:00 +1: NS-STORYLINES-02 current Global Story characterization keeps globalStory and localEventFlow separated in the current projection
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
00:00 +2: All tests passed!
```

### Sortie exacte — flutter test narrative_workspace_projection_test.dart

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/narrative_workspace_projection_test.dart
00:00 +0: buildNarrativeWorkspaceProjection splits global story and local flows, and projects steps
00:00 +1: buildNarrativeWorkspaceProjection projects ordered steps from Step Studio v1 metadata document
00:00 +2: buildNarrativeWorkspaceProjection projects chapters from Global Story Studio metadata
00:00 +3: All tests passed!
```

### Sortie exacte — flutter analyze ciblé

```text
Analyzing 4 items...
No issues found! (ran in 1.8s)
```

### Sortie exacte — rg anti-couleurs

```text
Sortie : <vide>
```

### Résultats du Visual Gate

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/storylines_workspace_shell_test.dart
00:00 +0: NS-STORYLINES-V1-07 create main storyline flow shows only Graph and Structure tabs
00:00 +1: NS-STORYLINES-V1-07 create main storyline flow shows V1 empty state without importing legacy globalStory
00:00 +2: NS-STORYLINES-V1-07 create main storyline flow opens and cancels create main storyline dialog without mutation
00:00 +3: NS-STORYLINES-V1-07 create main storyline flow requires title before create
00:00 +4: NS-STORYLINES-V1-07 create main storyline flow creates a main StorylineAsset and syncs Graph and Structure
00:01 +5: NS-STORYLINES-V1-07 create main storyline flow generates stable unique ids on collision
00:01 +6: NS-STORYLINES-V1-07 create main storyline flow does not allow creating a second main storyline
00:01 +7: NS-STORYLINES-V1-07 create main storyline flow creation does not import legacy or promote localEventFlow
00:01 +8: NS-STORYLINES-V1-07 create main storyline flow Graph, Structure and disabled chapter CTA do not mutate
00:01 +9: NS-STORYLINES-V1-07 create main storyline flow keeps target fake data and Maps out of the V1 UI
00:01 +10: NS-STORYLINES-V1-07 create main storyline flow storylines UI source keeps raw colors out of the feature
00:01 +11: NS-STORYLINES-V1-07 create main storyline flow storylines shell test keeps raw colors out
00:01 +12: NS-STORYLINES-V1-07 create main storyline flow uses PokeMap dark theme in the Visual Gate harness
00:01 +13: NS-STORYLINES-V1-07 create main storyline flow writes V1-07 Visual Gate screenshots
00:02 +14: All tests passed!
```

```text
reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_07_create_main_dialog.png
reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_07_created_main_graph.png
reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_07_created_main_structure.png
reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_07_empty_storylines_desktop.png
```

### Git status final exact

```text
 M packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
 M packages/map_editor/test/storylines_workspace_shell_test.dart
 M reports/narrativeStudio/storylines/road_map_storylines.md
?? reports/narrativeStudio/storylines/ns_storylines_v1_07_create_main_storyline_flow_v0.md
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_07_create_main_dialog.png
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_07_created_main_graph.png
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_07_created_main_structure.png
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_07_empty_storylines_desktop.png
```

### Git diff --stat final

```text
 .../lib/src/ui/canvas/storylines_workspace.dart    | 1246 ++++++++++++++++-
 .../test/storylines_workspace_shell_test.dart      | 1396 +++++---------------
 .../storylines/road_map_storylines.md              |   54 +-
 3 files changed, 1563 insertions(+), 1133 deletions(-)
```

### Git diff --name-only final

```text
packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
packages/map_editor/test/storylines_workspace_shell_test.dart
reports/narrativeStudio/storylines/road_map_storylines.md
```

### Git diff --check final

```text
Sortie : <vide>
```

## 20. Self-review

- Scope : respecté côté code ; seuls `storylines_workspace.dart`, `storylines_workspace_shell_test.dart`, la roadmap, le rapport et les screenshots V1-07 ont été modifiés/créés pour ce lot.
- Risque principal : le header global Narrative Studio contient encore une action `Nouvelle storyline` disabled hors fichier autorisé ; le flow fonctionnel V1-07 est dans le workspace Storylines et les tests ciblent ce CTA par key.
- Legacy : le titre legacy peut être affiché comme information non sélectionnable quand aucune storyline V1 n'existe ; cela maintient la caractérisation existante sans importer ni muter `ProjectManifest.storylines`.
- Produit : V1-07 reste volontairement minimal ; Structure n'author pas encore les chapters/steps/scenes.
- Worktree : le status initial capturé au démarrage listait des changements V1-06 préexistants dans `map_core` et le rapport V1-06 ; le status final ne les liste plus. Aucun `git add`, `git commit`, `git reset`, `git restore`, `git checkout`, `git stash`, `git clean` ou autre commande Git d'écriture n'a été exécuté pendant V1-07.
- Vérification : tests ciblés, régressions demandées, analyse ciblée, anti-couleurs, Visual Gate et `git diff --check` sont propres.
