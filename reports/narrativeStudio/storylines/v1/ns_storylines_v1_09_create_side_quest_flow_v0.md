# NS-STORYLINES-V1-09 — Create Side Quest Flow V0

## 1. Executive summary

NS-STORYLINES-V1-09 est livré. Le workspace Storylines permet maintenant de créer une vraie `StorylineAsset(type: sideQuest, status: draft)` depuis le CTA unique `Nouvelle storyline`, après existence d'une main storyline. La sideQuest est ajoutée à `ProjectManifest.storylines`, sélectionnée dans l'UI, listée séparément des storylines principales, et réutilise Structure pour créer chapitres et étapes narratives.

Aucun modèle `map_core`, runtime, gameplay ou battle n'a été modifié. Aucune `StorylineRelationship`, `SideQuestAvailability`, scene placeholder ou `StorylineSceneLink` n'est créée. Le legacy `globalStory` n'est pas importé automatiquement et `localEventFlow` reste exclu.

## 2. Inputs read

Fichiers lus :

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `reports/narrativeStudio/storylines/road_map_storylines.md`
- `packages/map_core/lib/src/models/storyline_asset.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/map_core.dart`
- `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`
- `packages/map_editor/test/storylines_workspace_shell_test.dart`
- `packages/map_editor/test/storylines_current_global_story_characterization_test.dart`
- `packages/map_editor/test/narrative_workspace_projection_test.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_selectors.dart`
- `packages/map_editor/lib/src/ui/design_system/design_system.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_tone.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_dashboard_primitives.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_button.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_card.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_panel.dart`
- `packages/map_editor/lib/src/theme/pokemap_color_tokens.dart`
- `packages/map_editor/lib/src/theme/theme.dart`

Fichiers attendus mais absents :

- `reports/narrativeStudio/storylines/ns_storylines_v1_08_structure_tab_authoring_v0.md`
- `reports/narrativeStudio/storylines/ns_storylines_v1_07_create_main_storyline_flow_v0.md`
- `reports/narrativeStudio/storylines/ns_storylines_v1_06_legacy_global_story_import_preview_v0.md`
- `reports/narrativeStudio/storylines/ns_storylines_v1_03_storyline_asset_pure_model_v0.md`
- `reports/narrativeStudio/storylines/ns_storylines_v1_00_storyline_semantics_and_usable_authoring_contract.md`

## 3. Product problem addressed

Avant ce lot, Storylines V1 permettait de créer une main storyline et de structurer chapitres/steps, mais les quêtes annexes restaient seulement une décision de modèle. Le créateur ne pouvait pas encore créer une storyline secondaire réelle.

Ce lot ajoute le premier flow sideQuest concret sans anticiper les lots graph/relation : la quête annexe existe comme authoring data, reste indépendante, et l'UI dit clairement qu'elle n'est pas reliée au graph principal pour l'instant.

## 4. Implementation summary

- Le dialog `Nouvelle storyline` propose désormais `Histoire principale` et `Quête annexe`.
- Sans main storyline, `Histoire principale` est sélectionnée et `Quête annexe` est indisponible.
- Avec une main storyline, `Quête annexe` est sélectionnée et `Histoire principale` est indisponible.
- La création sideQuest génère une `StorylineAsset(type: sideQuest, status: draft)` avec `chapters`, `sceneLinks` et `relationships` vides.
- Le panneau secondaire sépare `Histoire principale` et `Quêtes annexes`.
- Structure fonctionne avec une sideQuest sélectionnée et ajoute ses chapitres/steps dans cette sideQuest uniquement.
- Graph affiche un état minimal honnête pour sideQuest : non reliée au graph principal.

## 5. Storyline type selection behavior

Le CTA reste unique : `Nouvelle storyline`. Le choix de type est localisé dans le dialog.

Règles V1-09 :

- `main` reste unique dans le projet.
- `sideQuest` nécessite une main storyline existante.
- Les types futurs ne sont pas affichés dans ce lot.
- Les options indisponibles restent visibles avec une raison courte, mais ne mutent rien.

## 6. Side quest creation flow

Le submit sideQuest crée :

```text
StorylineAsset(
  id: sidequest_<slug>,
  type: StorylineType.sideQuest,
  status: StorylineStatus.draft,
  title: <titre>,
  description: <description ou null>,
  chapters: [],
  sceneLinks: [],
  relationships: [],
)
```

Après création, la sideQuest est ajoutée à `ProjectManifest.storylines`, sélectionnée, et l'onglet Structure est affiché pour encourager l'organisation auteur.

## 7. Side quest list behavior

Le panneau secondaire affiche deux groupes :

- `HISTOIRE PRINCIPALE` pour `StorylineType.main`.
- `QUÊTES ANNEXES` pour `StorylineType.sideQuest`.

Les compteurs affichés sont réels : chapitres et étapes viennent de la `StorylineAsset`. Aucune quête annexe fake, aucun legacy `localEventFlow`, aucune donnée Selbrume n'est affichée.

## 8. Structure behavior for side quests

Structure réutilise le flow V1-08 : `Nouveau chapitre`, puis `Nouvelle étape narrative`. Quand la sideQuest est sélectionnée, les nouveaux chapitres et steps sont écrits dans la sideQuest uniquement. La main storyline reste inchangée.

## 9. Graph behavior for side quests

Graph reste minimal. Quand une sideQuest est sélectionnée, il affiche son titre, ses vrais compteurs et le message : `Quête annexe non reliée au graph principal pour l’instant.`

La main storyline ne montre pas encore les sideQuests comme branches. L'intégration graph principal reste réservée à `NS-STORYLINES-V1-11 — Side Quest Graph Integration V0`, après `NS-STORYLINES-V1-10 — Graph From StorylineAsset V0`.

## 10. ID generation and uniqueness

La génération d'id réutilise le slugifier existant :

- main : `storyline_<slug>`.
- sideQuest : `sidequest_<slug>`.
- collisions : suffixes `_2`, `_3`, etc.

Les tests couvrent la collision sideQuest avec deux titres identiques.

## 11. Mutation strategy

Les mutations restent immuables via le notifier editor existant : construction d'une nouvelle liste `storylines`, `project.copyWith(storylines: updatedStorylines)`, puis `EditorNotifier.applyInMemoryProjectManifest(...)`.

Aucune liste de `ProjectManifest` ou `StorylineAsset` n'est mutée directement.

## 12. Legacy non-import guarantee

Le flow de création sideQuest ne lit pas et n'applique pas `buildLegacyGlobalStoryImportPreview`. Un `ScenarioAsset(scope == globalStory)` peut rester présent dans `ProjectManifest.scenarios`; il n'est pas converti pendant ce lot.

## 13. localEventFlow exclusion

`ScenarioAsset(scope == localEventFlow)` n'est jamais affiché comme Storyline, sideQuest, chapter, step ou node de graph. Le test sideQuest legacy/localEvent confirme que les scenarios restent intacts et que la sideQuest vient uniquement du formulaire.

## 14. Non-goals confirmed

Confirmé hors scope :

- aucun changement `map_core` ;
- aucune modification `StorylineAsset`, `ProjectManifest`, `ScenarioAsset` ;
- aucune relation `sideQuestAvailableDuring` ;
- aucune `SideQuestAvailability` ;
- aucune `StorylineRelationship` ;
- aucun scene placeholder ;
- aucun `StorylineSceneLink` ;
- aucun import legacy automatique ;
- aucun graph riche ;
- aucun drag/drop, réordonnancement, édition ou suppression ;
- aucun runtime/gameplay/battle modifié.

## 15. Design System Gate

Le patch conserve les primitives existantes : `PokeMapButton`, `PokeMapCard`, `PokeMapPanel`, `PokeMapIconTile`, `PokeMapMetricCard`, `PokeMapSegmentedTabs`, `PokeMapTone` et `context.pokeMapColors`.

Le `rg` anti-couleurs ne retourne aucune occurrence.

## 16. Tests added or modified

Tests ajoutés/modifiés dans `packages/map_editor/test/storylines_workspace_shell_test.dart` :

- dialog sans main : sideQuest indisponible ;
- tentative sideQuest sans main : création main uniquement, aucune sideQuest ;
- dialog avec main : sideQuest sélectionnée ;
- création sideQuest valide ;
- ids sideQuest slugifiés et collision-safe ;
- impossibilité de créer une deuxième main ;
- panneau secondaire main/sideQuest ;
- Structure sur sideQuest sans mutation de la main ;
- Graph sideQuest non relié ;
- main graph sans branche sideQuest ;
- legacy et `localEventFlow` non importés ;
- anti-fake, Maps absent, anti-couleurs ;
- Visual Gate V1-09.

## 17. Visual Gate

Captures V1-09 générées :

```text
EXISTS reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_09_create_side_quest_dialog.png (15535 bytes)
EXISTS reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_09_created_side_quest_graph.png (40174 bytes)
EXISTS reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_09_created_side_quest_structure.png (47962 bytes)
EXISTS reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_09_storyline_list_with_side_quest.png (47962 bytes)
```

Commande de génération :

Commande : `cd packages/map_editor && flutter test --update-goldens test/storylines_workspace_shell_test.dart`

Exit code : `0`

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/storylines_workspace_shell_test.dart
00:00 +0: NS-STORYLINES-V1-09 side quest authoring flow shows only Graph and Structure tabs
00:00 +1: NS-STORYLINES-V1-09 side quest authoring flow shows V1 empty state without importing legacy globalStory
00:00 +2: NS-STORYLINES-V1-09 side quest authoring flow opens and cancels create main storyline dialog without mutation
00:00 +3: NS-STORYLINES-V1-09 side quest authoring flow requires title before create
00:00 +4: NS-STORYLINES-V1-09 side quest authoring flow does not create sideQuest before a main storyline exists
00:01 +5: NS-STORYLINES-V1-09 side quest authoring flow dialog selects sideQuest when a main storyline exists
00:01 +6: NS-STORYLINES-V1-09 side quest authoring flow creates a main StorylineAsset and syncs Graph and Structure
00:01 +7: NS-STORYLINES-V1-09 side quest authoring flow creates a sideQuest StorylineAsset and selects it
00:01 +8: NS-STORYLINES-V1-09 side quest authoring flow Structure without storyline has no chapter or step action
00:01 +9: NS-STORYLINES-V1-09 side quest authoring flow opens and cancels create chapter without mutation
00:01 +10: NS-STORYLINES-V1-09 side quest authoring flow requires chapter title before create
00:01 +11: NS-STORYLINES-V1-09 side quest authoring flow creates chapters with stable ids, order and selection
00:01 +12: NS-STORYLINES-V1-09 side quest authoring flow step action requires a selected chapter
00:02 +13: NS-STORYLINES-V1-09 side quest authoring flow opens and cancels create step without mutation
00:02 +14: NS-STORYLINES-V1-09 side quest authoring flow requires step title before create
00:02 +15: NS-STORYLINES-V1-09 side quest authoring flow creates steps with global unique ids and order
00:02 +16: NS-STORYLINES-V1-09 side quest authoring flow Structure authoring works on sideQuest without mutating main
00:02 +17: NS-STORYLINES-V1-09 side quest authoring flow Graph summarizes created structure without fake edges
00:02 +18: NS-STORYLINES-V1-09 side quest authoring flow Graph explains sideQuest is not linked to main graph yet
00:03 +19: NS-STORYLINES-V1-09 side quest authoring flow main graph does not show sideQuest as a branch yet
00:03 +20: NS-STORYLINES-V1-09 side quest authoring flow generates stable unique main ids on collision
00:03 +21: NS-STORYLINES-V1-09 side quest authoring flow generates stable unique sideQuest ids on collision
00:03 +22: NS-STORYLINES-V1-09 side quest authoring flow does not allow creating a second main storyline
00:03 +23: NS-STORYLINES-V1-09 side quest authoring flow creation does not import legacy or promote localEventFlow
00:03 +24: NS-STORYLINES-V1-09 side quest authoring flow sideQuest creation never imports legacy or localEventFlow
00:03 +25: NS-STORYLINES-V1-09 side quest authoring flow Graph, Structure and disabled future actions do not mutate
00:03 +26: NS-STORYLINES-V1-09 side quest authoring flow Structure authoring does not import legacy or localEventFlow
00:03 +27: NS-STORYLINES-V1-09 side quest authoring flow keeps target fake data and Maps out of the V1 UI
00:03 +28: NS-STORYLINES-V1-09 side quest authoring flow storylines UI source keeps raw colors out of the feature
00:03 +29: NS-STORYLINES-V1-09 side quest authoring flow storylines shell test keeps raw colors out
00:03 +30: NS-STORYLINES-V1-09 side quest authoring flow uses PokeMap dark theme in the Visual Gate harness
00:03 +31: NS-STORYLINES-V1-09 side quest authoring flow writes V1-09 Side Quest Visual Gate screenshots
00:04 +32: All tests passed!
```

## 18. Commands run

Commandes exécutées pendant le lot :

- `git branch --show-current`
- `git status --short --untracked-files=all`
- `git diff --stat`
- `git diff --name-only`
- `git diff --check`
- `dart format packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart packages/map_editor/test/storylines_workspace_shell_test.dart`
- `dart format test/storylines_workspace_shell_test.dart`
- `cd packages/map_editor && flutter test --update-goldens test/storylines_workspace_shell_test.dart`
- `cd packages/map_editor && flutter test test/storylines_workspace_shell_test.dart`
- `cd packages/map_editor && flutter test test/storylines_current_global_story_characterization_test.dart`
- `cd packages/map_editor && flutter test test/narrative_workspace_projection_test.dart`
- `cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/storylines_workspace.dart test/storylines_workspace_shell_test.dart test/storylines_current_global_story_characterization_test.dart test/narrative_workspace_projection_test.dart`
- `rg "Color\(0x|Colors\." packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart packages/map_editor/test/storylines_workspace_shell_test.dart`

## 19. Roadmap update

`reports/narrativeStudio/storylines/road_map_storylines.md` marque `NS-STORYLINES-V1-09` comme `DONE`, confirme que le flow crée une vraie `StorylineAsset(type: sideQuest)`, qu'aucune relationship/availability/sceneLink/import legacy n'est créée, et recommande le prochain lot : `NS-STORYLINES-V1-10 — Graph From StorylineAsset V0`.

## 20. Evidence Pack

### Git branch initiale

```text
main
```

### Git status initial exact

Sortie : <vide>

### Git diff --stat initial

Sortie : <vide>

### Git diff --name-only initial

Sortie : <vide>

### Git diff --check initial

Sortie : <vide>

### Liste des fichiers lus

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `reports/narrativeStudio/storylines/road_map_storylines.md`
- `packages/map_core/lib/src/models/storyline_asset.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/map_core.dart`
- `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`
- `packages/map_editor/test/storylines_workspace_shell_test.dart`
- `packages/map_editor/test/storylines_current_global_story_characterization_test.dart`
- `packages/map_editor/test/narrative_workspace_projection_test.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_selectors.dart`
- `packages/map_editor/lib/src/ui/design_system/design_system.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_tone.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_dashboard_primitives.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_button.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_card.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_panel.dart`
- `packages/map_editor/lib/src/theme/pokemap_color_tokens.dart`
- `packages/map_editor/lib/src/theme/theme.dart`

### Liste des fichiers absents mais attendus

- `reports/narrativeStudio/storylines/ns_storylines_v1_08_structure_tab_authoring_v0.md`
- `reports/narrativeStudio/storylines/ns_storylines_v1_07_create_main_storyline_flow_v0.md`
- `reports/narrativeStudio/storylines/ns_storylines_v1_06_legacy_global_story_import_preview_v0.md`
- `reports/narrativeStudio/storylines/ns_storylines_v1_03_storyline_asset_pure_model_v0.md`
- `reports/narrativeStudio/storylines/ns_storylines_v1_00_storyline_semantics_and_usable_authoring_contract.md`

### Diff complet de storylines_workspace.dart

```text
diff --git a/packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart b/packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
index dec818b2..2c0059ca 100644
--- a/packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
+++ b/packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
@@ -66,13 +66,12 @@ class _StorylinesWorkspaceState extends ConsumerState<StorylinesWorkspace> {
               legacyGlobalStory: legacyGlobalStory,
               legacyStep: legacyStep,
               legacyStepCount: legacyStepCount,
-              canCreateMainStoryline: _canCreateMainStoryline(storylines),
+              canCreateStoryline: project != null,
               onTabSelected: _selectTab,
               onChapterSelected: _selectChapter,
-              onCreateMainStoryline:
-                  project == null || !_canCreateMainStoryline(storylines)
-                      ? null
-                      : () => _openCreateMainStorylineDialog(project),
+              onCreateStoryline: project == null
+                  ? null
+                  : () => _openCreateStorylineDialog(project),
               onCreateChapter: project == null || selectedStoryline == null
                   ? null
                   : () => _openCreateChapterDialog(project, selectedStoryline),
@@ -111,10 +110,6 @@ class _StorylinesWorkspaceState extends ConsumerState<StorylinesWorkspace> {
     return storylines.isEmpty ? null : storylines.first;
   }
 
-  bool _canCreateMainStoryline(List<StorylineAsset> storylines) {
-    return !storylines.any((storyline) => storyline.type == StorylineType.main);
-  }
-
   StorylineChapter? _selectedChapter(StorylineAsset? storyline) {
     if (storyline == null || storyline.chapters.isEmpty) {
       return null;
@@ -159,20 +154,19 @@ class _StorylinesWorkspaceState extends ConsumerState<StorylinesWorkspace> {
     });
   }
 
-  Future<void> _openCreateMainStorylineDialog(ProjectManifest project) async {
-    final draft = await showCupertinoDialog<_CreateMainStorylineDraft>(
+  Future<void> _openCreateStorylineDialog(ProjectManifest project) async {
+    final draft = await showCupertinoDialog<_CreateStorylineDraft>(
       context: context,
-      builder: (context) => _CreateMainStorylineDialog(
-        existingIds:
-            project.storylines.map((storyline) => storyline.id).toSet(),
+      builder: (context) => _CreateStorylineDialog(
+        storylines: project.storylines,
       ),
     );
     if (draft == null || !mounted) {
       return;
     }
     final storyline = StorylineAsset(
-      id: _generateStorylineId(draft.title, project.storylines),
-      type: StorylineType.main,
+      id: _generateStorylineId(draft.title, draft.type, project.storylines),
+      type: draft.type,
       status: StorylineStatus.draft,
       title: draft.title,
       description: draft.description,
@@ -182,12 +176,16 @@ class _StorylinesWorkspaceState extends ConsumerState<StorylinesWorkspace> {
     );
     ref.read(editorNotifierProvider.notifier).applyInMemoryProjectManifest(
           updated,
-          statusMessage: 'Storyline principale créée',
+          statusMessage: draft.type == StorylineType.sideQuest
+              ? 'Quête annexe créée'
+              : 'Storyline principale créée',
         );
     setState(() {
       _selectedStorylineId = storyline.id;
       _selectedChapterId = null;
-      _selectedTab = _StorylineContentTab.graph;
+      _selectedTab = draft.type == StorylineType.sideQuest
+          ? _StorylineContentTab.structure
+          : _StorylineContentTab.graph;
     });
   }
 
@@ -294,14 +292,15 @@ class _StorylinesWorkspaceState extends ConsumerState<StorylinesWorkspace> {
 
   String _generateStorylineId(
     String title,
+    StorylineType type,
     List<StorylineAsset> storylines,
   ) {
     final existingIds = storylines.map((storyline) => storyline.id).toSet();
     return _generateScopedId(
-      prefix: 'storyline',
+      prefix: type == StorylineType.sideQuest ? 'sidequest' : 'storyline',
       title: title,
       existingIds: existingIds,
-      fallback: 'main',
+      fallback: type == StorylineType.sideQuest ? 'sidequest' : 'main',
     );
   }
 
@@ -466,6 +465,12 @@ class _StorylinesV1SecondaryPanel extends StatelessWidget {
   @override
   Widget build(BuildContext context) {
     final colors = context.pokeMapColors;
+    final mainStorylines = storylines
+        .where((storyline) => storyline.type == StorylineType.main)
+        .toList(growable: false);
+    final sideQuests = storylines
+        .where((storyline) => storyline.type == StorylineType.sideQuest)
+        .toList(growable: false);
     return PokeMapPanel(
       key: const ValueKey('storylines-secondary-panel'),
       expandChild: true,
@@ -480,17 +485,52 @@ class _StorylinesV1SecondaryPanel extends StatelessWidget {
           const SizedBox(height: 12),
           if (storylines.isEmpty)
             const _StorylinesV1EmptyList()
-          else
-            ...storylines.map(
-              (storyline) => Padding(
-                padding: const EdgeInsets.only(bottom: 8),
-                child: _StorylinesV1Row(
-                  storyline: storyline,
-                  selected: storyline.id == selectedStorylineId,
-                  onTap: () => onStorylineSelected(storyline),
+          else ...[
+            _StorylinesSectionLabel(
+              label: 'HISTOIRE PRINCIPALE',
+              color: colors.textMuted,
+            ),
+            const SizedBox(height: 8),
+            if (mainStorylines.isEmpty)
+              const _StorylinesV1CompactEmpty(
+                title: 'Aucune histoire principale',
+                body:
+                    'Créez une histoire principale depuis Nouvelle storyline.',
+              )
+            else
+              ...mainStorylines.map(
+                (storyline) => Padding(
+                  padding: const EdgeInsets.only(bottom: 8),
+                  child: _StorylinesV1Row(
+                    storyline: storyline,
+                    selected: storyline.id == selectedStorylineId,
+                    onTap: () => onStorylineSelected(storyline),
+                  ),
                 ),
               ),
+            const SizedBox(height: 8),
+            _StorylinesSectionLabel(
+              label: 'QUÊTES ANNEXES',
+              color: colors.textMuted,
             ),
+            const SizedBox(height: 8),
+            if (sideQuests.isEmpty)
+              const _StorylinesV1CompactEmpty(
+                title: 'Aucune quête annexe',
+                body: 'Créez une quête annexe depuis Nouvelle storyline.',
+              )
+            else
+              ...sideQuests.map(
+                (storyline) => Padding(
+                  padding: const EdgeInsets.only(bottom: 8),
+                  child: _StorylinesV1Row(
+                    storyline: storyline,
+                    selected: storyline.id == selectedStorylineId,
+                    onTap: () => onStorylineSelected(storyline),
+                  ),
+                ),
+              ),
+          ],
           const Spacer(),
           if (storylines.isEmpty && legacyGlobalStory != null)
             PokeMapCard(
@@ -555,6 +595,46 @@ class _StorylinesV1EmptyList extends StatelessWidget {
   }
 }
 
+class _StorylinesV1CompactEmpty extends StatelessWidget {
+  const _StorylinesV1CompactEmpty({
+    required this.title,
+    required this.body,
+  });
+
+  final String title;
+  final String body;
+
+  @override
+  Widget build(BuildContext context) {
+    final colors = context.pokeMapColors;
+    return PokeMapCard(
+      padding: const EdgeInsets.all(12),
+      child: Column(
+        crossAxisAlignment: CrossAxisAlignment.start,
+        children: [
+          Text(
+            title,
+            style: TextStyle(
+              color: colors.textSecondary,
+              fontSize: 12,
+              fontWeight: FontWeight.w700,
+            ),
+          ),
+          const SizedBox(height: 4),
+          Text(
+            body,
+            style: TextStyle(
+              color: colors.textMuted,
+              fontSize: 11,
+              height: 1.3,
+            ),
+          ),
+        ],
+      ),
+    );
+  }
+}
+
 class _StorylinesV1Row extends StatelessWidget {
   const _StorylinesV1Row({
     required this.storyline,
@@ -605,6 +685,16 @@ class _StorylinesV1Row extends StatelessWidget {
                       fontSize: 11,
                     ),
                   ),
+                  if (storyline.type == StorylineType.sideQuest) ...[
+                    const SizedBox(height: 3),
+                    Text(
+                      'Non reliée au graph principal',
+                      style: TextStyle(
+                        color: colors.textMuted,
+                        fontSize: 11,
+                      ),
+                    ),
+                  ],
                   if (storyline.chapters.isNotEmpty) ...[
                     const SizedBox(height: 3),
                     Text(
@@ -634,10 +724,10 @@ class _StorylinesV1MainPanel extends StatelessWidget {
     required this.legacyGlobalStory,
     required this.legacyStep,
     required this.legacyStepCount,
-    required this.canCreateMainStoryline,
+    required this.canCreateStoryline,
     required this.onTabSelected,
     required this.onChapterSelected,
-    required this.onCreateMainStoryline,
+    required this.onCreateStoryline,
     required this.onCreateChapter,
     required this.onCreateStep,
   });
@@ -649,10 +739,10 @@ class _StorylinesV1MainPanel extends StatelessWidget {
   final NarrativeScenarioSummary? legacyGlobalStory;
   final NarrativeStepSummary? legacyStep;
   final int legacyStepCount;
-  final bool canCreateMainStoryline;
+  final bool canCreateStoryline;
   final ValueChanged<_StorylineContentTab> onTabSelected;
   final ValueChanged<StorylineChapter> onChapterSelected;
-  final VoidCallback? onCreateMainStoryline;
+  final VoidCallback? onCreateStoryline;
   final VoidCallback? onCreateChapter;
   final VoidCallback? onCreateStep;
 
@@ -667,8 +757,8 @@ class _StorylinesV1MainPanel extends StatelessWidget {
         children: [
           _StorylinesV1Header(
             selectedStoryline: selectedStoryline,
-            canCreateMainStoryline: canCreateMainStoryline,
-            onCreateMainStoryline: onCreateMainStoryline,
+            canCreateStoryline: canCreateStoryline,
+            onCreateStoryline: onCreateStoryline,
           ),
           const SizedBox(height: 12),
           _StorylineTabsRow(
@@ -703,13 +793,13 @@ class _StorylinesV1MainPanel extends StatelessWidget {
 class _StorylinesV1Header extends StatelessWidget {
   const _StorylinesV1Header({
     required this.selectedStoryline,
-    required this.canCreateMainStoryline,
-    required this.onCreateMainStoryline,
+    required this.canCreateStoryline,
+    required this.onCreateStoryline,
   });
 
   final StorylineAsset? selectedStoryline;
-  final bool canCreateMainStoryline;
-  final VoidCallback? onCreateMainStoryline;
+  final bool canCreateStoryline;
+  final VoidCallback? onCreateStoryline;
 
   @override
   Widget build(BuildContext context) {
@@ -733,11 +823,30 @@ class _StorylinesV1Header extends StatelessWidget {
                   ),
                 ),
                 const SizedBox(height: 6),
+                if (selectedStoryline != null) ...[
+                  Wrap(
+                    spacing: 6,
+                    runSpacing: 6,
+                    children: [
+                      _StorylinesV1Badge(
+                        label: _storylineTypeLabel(selectedStoryline!.type),
+                      ),
+                      const _StorylinesV1Badge(label: 'Brouillon'),
+                      if (selectedStoryline!.type == StorylineType.sideQuest)
+                        const _StorylinesV1Badge(
+                          label: 'Non reliée au graph principal',
+                        ),
+                    ],
+                  ),
+                  const SizedBox(height: 6),
+                ],
                 Text(
                   selectedStoryline == null
                       ? 'Créez une histoire principale pour commencer à structurer votre jeu.'
                       : selectedStoryline!.description ??
-                          'Storyline principale prête à structurer.',
+                          (selectedStoryline!.type == StorylineType.sideQuest
+                              ? 'Quête annexe prête à structurer.'
+                              : 'Storyline principale prête à structurer.'),
                   maxLines: 2,
                   overflow: TextOverflow.ellipsis,
                   style: TextStyle(
@@ -752,7 +861,7 @@ class _StorylinesV1Header extends StatelessWidget {
           const SizedBox(width: 12),
           PokeMapButton(
             key: const ValueKey('storylines-create-main-cta'),
-            onPressed: canCreateMainStoryline ? onCreateMainStoryline : null,
+            onPressed: canCreateStoryline ? onCreateStoryline : null,
             variant: PokeMapButtonVariant.primary,
             leading: const Icon(CupertinoIcons.plus, size: 16),
             child: const Row(
@@ -858,6 +967,7 @@ class _StorylinesV1GraphSection extends StatelessWidget {
   Widget build(BuildContext context) {
     final colors = context.pokeMapColors;
     final selectedStoryline = storyline;
+    final isSideQuest = selectedStoryline?.type == StorylineType.sideQuest;
     final chapterCount = selectedStoryline?.chapters.length ?? 0;
     final stepCount =
         selectedStoryline == null ? 0 : _storylineStepCount(selectedStoryline);
@@ -936,10 +1046,12 @@ class _StorylinesV1GraphSection extends StatelessWidget {
                               fontSize: 12,
                             ),
                           ),
-                          if (chapterCount > 0) ...[
+                          if (isSideQuest || chapterCount > 0) ...[
                             const SizedBox(height: 8),
                             Text(
-                              'Graph détaillé à venir au lot Graph From StorylineAsset.',
+                              isSideQuest
+                                  ? 'Quête annexe non reliée au graph principal pour l’instant.'
+                                  : 'Graph détaillé à venir au lot Graph From StorylineAsset.',
                               textAlign: TextAlign.center,
                               style: TextStyle(
                                 color: colors.textSecondary,
@@ -947,6 +1059,17 @@ class _StorylinesV1GraphSection extends StatelessWidget {
                               ),
                             ),
                           ],
+                          if (isSideQuest) ...[
+                            const SizedBox(height: 6),
+                            Text(
+                              'L’intégration au graph principal viendra dans Side Quest Graph Integration.',
+                              textAlign: TextAlign.center,
+                              style: TextStyle(
+                                color: colors.textMuted,
+                                fontSize: 11,
+                              ),
+                            ),
+                          ],
                         ],
                       ),
                     ),
@@ -1690,18 +1813,25 @@ class _StorylinesV1InspectorPanel extends StatelessWidget {
                   label: 'Scene links',
                   value: selectedStoryline!.sceneLinks.length.toString(),
                 ),
+                if (selectedStoryline!.type == StorylineType.sideQuest)
+                  const _StorylineInspectorTextLine(
+                    label: 'Relation principale',
+                    value: 'Non reliée',
+                  ),
               ],
             ),
     );
   }
 }
 
-class _CreateMainStorylineDraft {
-  const _CreateMainStorylineDraft({
+class _CreateStorylineDraft {
+  const _CreateStorylineDraft({
+    required this.type,
     required this.title,
     required this.description,
   });
 
+  final StorylineType type;
   final String title;
   final String? description;
 }
@@ -1835,20 +1965,41 @@ class _CreateStructureItemDialogState
   }
 }
 
-class _CreateMainStorylineDialog extends StatefulWidget {
-  const _CreateMainStorylineDialog({required this.existingIds});
+class _CreateStorylineDialog extends StatefulWidget {
+  const _CreateStorylineDialog({required this.storylines});
 
-  final Set<String> existingIds;
+  final List<StorylineAsset> storylines;
 
   @override
-  State<_CreateMainStorylineDialog> createState() =>
-      _CreateMainStorylineDialogState();
+  State<_CreateStorylineDialog> createState() => _CreateStorylineDialogState();
 }
 
-class _CreateMainStorylineDialogState
-    extends State<_CreateMainStorylineDialog> {
+class _CreateStorylineDialogState extends State<_CreateStorylineDialog> {
   final TextEditingController _titleController = TextEditingController();
   final TextEditingController _descriptionController = TextEditingController();
+  late StorylineType _selectedType;
+
+  bool get _hasMainStoryline => widget.storylines
+      .any((storyline) => storyline.type == StorylineType.main);
+
+  bool get _canCreateMain => !_hasMainStoryline;
+
+  bool get _canCreateSideQuest => _hasMainStoryline;
+
+  bool get _canCreateSelectedType {
+    return switch (_selectedType) {
+      StorylineType.main => _canCreateMain,
+      StorylineType.sideQuest => _canCreateSideQuest,
+      _ => false,
+    };
+  }
+
+  @override
+  void initState() {
+    super.initState();
+    _selectedType =
+        _hasMainStoryline ? StorylineType.sideQuest : StorylineType.main;
+  }
 
   @override
   void dispose() {
@@ -1861,9 +2012,10 @@ class _CreateMainStorylineDialogState
   Widget build(BuildContext context) {
     final colors = context.pokeMapColors;
     final title = _titleController.text.trim();
+    final canSubmit = title.isNotEmpty && _canCreateSelectedType;
     return Center(
       child: SizedBox(
-        width: 460,
+        width: 520,
         child: PokeMapPanel(
           key: const ValueKey('storylines-create-main-dialog'),
           padding: const EdgeInsets.all(18),
@@ -1879,8 +2031,34 @@ class _CreateMainStorylineDialogState
                   fontWeight: FontWeight.w800,
                 ),
               ),
+              const SizedBox(height: 14),
+              _StorylineTypeChoice(
+                key: const ValueKey('storylines-create-type-main'),
+                label: 'Histoire principale',
+                description: 'Structure principale du jeu.',
+                selected: _selectedType == StorylineType.main,
+                enabled: _canCreateMain,
+                disabledReason: _hasMainStoryline
+                    ? 'Une histoire principale existe déjà.'
+                    : null,
+                onTap: () => setState(() {
+                  _selectedType = StorylineType.main;
+                }),
+              ),
               const SizedBox(height: 8),
-              const _StorylinesV1Badge(label: 'Histoire principale'),
+              _StorylineTypeChoice(
+                key: const ValueKey('storylines-create-type-sidequest'),
+                label: 'Quête annexe',
+                description: 'Histoire secondaire optionnelle.',
+                selected: _selectedType == StorylineType.sideQuest,
+                enabled: _canCreateSideQuest,
+                disabledReason: _canCreateSideQuest
+                    ? null
+                    : 'Créez d’abord une histoire principale pour organiser les quêtes annexes.',
+                onTap: () => setState(() {
+                  _selectedType = StorylineType.sideQuest;
+                }),
+              ),
               const SizedBox(height: 14),
               _StorylinesV1TextField(
                 key: const ValueKey('storylines-create-title-field'),
@@ -1905,6 +2083,18 @@ class _CreateMainStorylineDialogState
                   ),
                 ),
               ],
+              if (!_canCreateSelectedType) ...[
+                const SizedBox(height: 8),
+                Text(
+                  _selectedType == StorylineType.sideQuest
+                      ? 'Créez d’abord une histoire principale.'
+                      : 'Une histoire principale existe déjà.',
+                  style: TextStyle(
+                    color: colors.textMuted,
+                    fontSize: 12,
+                  ),
+                ),
+              ],
               const SizedBox(height: 16),
               Row(
                 mainAxisAlignment: MainAxisAlignment.end,
@@ -1918,13 +2108,14 @@ class _CreateMainStorylineDialogState
                   const SizedBox(width: 10),
                   PokeMapButton(
                     key: const ValueKey('storylines-create-submit'),
-                    onPressed: title.isEmpty
+                    onPressed: !canSubmit
                         ? null
                         : () {
                             final description =
                                 _descriptionController.text.trim();
                             Navigator.of(context).pop(
-                              _CreateMainStorylineDraft(
+                              _CreateStorylineDraft(
+                                type: _selectedType,
                                 title: title,
                                 description:
                                     description.isEmpty ? null : description,
@@ -1944,6 +2135,79 @@ class _CreateMainStorylineDialogState
   }
 }
 
+class _StorylineTypeChoice extends StatelessWidget {
+  const _StorylineTypeChoice({
+    super.key,
+    required this.label,
+    required this.description,
+    required this.selected,
+    required this.enabled,
+    required this.disabledReason,
+    required this.onTap,
+  });
+
+  final String label;
+  final String description;
+  final bool selected;
+  final bool enabled;
+  final String? disabledReason;
+  final VoidCallback onTap;
+
+  @override
+  Widget build(BuildContext context) {
+    final colors = context.pokeMapColors;
+    return PokeMapCard(
+      selected: selected,
+      padding: const EdgeInsets.all(12),
+      onTap: enabled ? onTap : null,
+      child: Row(
+        crossAxisAlignment: CrossAxisAlignment.start,
+        children: [
+          Expanded(
+            child: Column(
+              crossAxisAlignment: CrossAxisAlignment.start,
+              children: [
+                Text(
+                  label,
+                  style: TextStyle(
+                    color: enabled ? colors.textPrimary : colors.textMuted,
+                    fontSize: 13,
+                    fontWeight: FontWeight.w800,
+                  ),
+                ),
+                const SizedBox(height: 4),
+                Text(
+                  description,
+                  style: TextStyle(
+                    color: enabled ? colors.textSecondary : colors.textMuted,
+                    fontSize: 12,
+                  ),
+                ),
+                if (!enabled && disabledReason != null) ...[
+                  const SizedBox(height: 6),
+                  Text(
+                    disabledReason!,
+                    style: TextStyle(
+                      color: colors.textMuted,
+                      fontSize: 11,
+                      height: 1.3,
+                    ),
+                  ),
+                ],
+              ],
+            ),
+          ),
+          const SizedBox(width: 10),
+          if (selected)
+            const _StorylinesV1Badge(label: 'Sélectionné')
+          else if (!enabled)
+            const _StorylinesV1Badge(label: 'Indisponible'),
+        ],
+      ),
+    );
+  }
+}
+
 class _StorylinesV1TextField extends StatelessWidget {
   const _StorylinesV1TextField({
     super.key,
@@ -1981,7 +2245,7 @@ class _StorylinesV1TextField extends StatelessWidget {
 String _storylineTypeLabel(StorylineType type) {
   return switch (type) {
     StorylineType.main => 'Histoire principale',
-    StorylineType.sideQuest => 'Storyline secondaire',
+    StorylineType.sideQuest => 'Quête annexe',
     StorylineType.tutorial => 'Tutoriel',
     StorylineType.epilogue => 'Épilogue',
     StorylineType.episode => 'Épisode',
```

### Diff complet des tests modifiés ou créés

```text
diff --git a/packages/map_editor/test/storylines_workspace_shell_test.dart b/packages/map_editor/test/storylines_workspace_shell_test.dart
index f57269a7..eef998de 100644
--- a/packages/map_editor/test/storylines_workspace_shell_test.dart
+++ b/packages/map_editor/test/storylines_workspace_shell_test.dart
@@ -12,7 +12,7 @@ import 'package:map_editor/src/ui/canvas/narrative_workspace_canvas.dart';
 import 'package:map_editor/src/ui/design_system/design_system.dart';
 
 void main() {
-  group('NS-STORYLINES-V1-08 structure tab authoring flow', () {
+  group('NS-STORYLINES-V1-09 side quest authoring flow', () {
     testWidgets('shows only Graph and Structure tabs', (tester) async {
       await _pumpStorylinesShell(tester);
 
@@ -62,6 +62,14 @@ void main() {
       expect(find.byKey(const ValueKey('storylines-create-main-dialog')),
           findsOneWidget);
       expect(find.text('Histoire principale'), findsOneWidget);
+      expect(find.text('Quête annexe'), findsOneWidget);
+      expect(
+        find.text(
+          'Créez d’abord une histoire principale pour organiser les quêtes annexes.',
+        ),
+        findsOneWidget,
+      );
+      expect(find.text('Sélectionné'), findsOneWidget);
       expect(find.byKey(const ValueKey('storylines-create-title-field')),
           findsOneWidget);
       expect(find.byKey(const ValueKey('storylines-create-description-field')),
@@ -89,6 +97,65 @@ void main() {
       expect(harness.project.storylines, isEmpty);
     });
 
+    testWidgets('does not create sideQuest before a main storyline exists',
+        (tester) async {
+      final harness = await _pumpStorylinesShell(tester);
+
+      await _openCreateDialog(tester);
+      await tester
+          .tap(find.byKey(const ValueKey('storylines-create-type-sidequest')));
+      await tester.pump();
+      await tester.enterText(
+        find.byKey(const ValueKey('storylines-create-title-field')),
+        'Early side quest',
+      );
+      await tester.pump();
+      await tester.tap(find.byKey(const ValueKey('storylines-create-submit')));
+      await tester.pumpAndSettle();
+
+      expect(harness.project.storylines, hasLength(1));
+      expect(harness.project.storylines.single.type, StorylineType.main);
+      expect(
+        harness.project.storylines
+            .where((storyline) => storyline.type == StorylineType.sideQuest),
+        isEmpty,
+      );
+    });
+
+    testWidgets('dialog selects sideQuest when a main storyline exists',
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
+
+      await _openCreateDialog(tester);
+
+      expect(find.text('Une histoire principale existe déjà.'), findsWidgets);
+      expect(find.text('Quête annexe'), findsOneWidget);
+      expect(find.text('Sélectionné'), findsOneWidget);
+      expect(find.byKey(const ValueKey('storylines-create-title-field')),
+          findsOneWidget);
+      expect(find.byKey(const ValueKey('storylines-create-description-field')),
+          findsOneWidget);
+
+      final submit = tester.widget<PokeMapButton>(
+        find.byKey(const ValueKey('storylines-create-submit')),
+      );
+      expect(submit.onPressed, isNull);
+
+      await tester.tap(find.byKey(const ValueKey('storylines-create-cancel')));
+      await tester.pumpAndSettle();
+      expect(harness.project.toJson(), before);
+    });
+
     testWidgets('creates a main StorylineAsset and syncs Graph and Structure',
         (tester) async {
       final harness = await _pumpStorylinesShell(tester);
@@ -138,6 +205,47 @@ void main() {
       expect(find.text('Nouveau chapitre'), findsOneWidget);
     });
 
+    testWidgets('creates a sideQuest StorylineAsset and selects it',
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
+
+      await _createSideQuest(
+        tester,
+        title: 'Missing Bell',
+        description: 'Optional story arc.',
+      );
+
+      final storylines = harness.project.storylines;
+      expect(storylines, hasLength(2));
+      final sideQuest = storylines.singleWhere(
+        (storyline) => storyline.type == StorylineType.sideQuest,
+      );
+      expect(sideQuest.id, 'sidequest_missing_bell');
+      expect(sideQuest.status, StorylineStatus.draft);
+      expect(sideQuest.title, 'Missing Bell');
+      expect(sideQuest.description, 'Optional story arc.');
+      expect(sideQuest.chapters, isEmpty);
+      expect(sideQuest.sceneLinks, isEmpty);
+      expect(sideQuest.relationships, isEmpty);
+
+      expect(find.text('Missing Bell'), findsWidgets);
+      expect(find.text('Quête annexe'), findsWidgets);
+      expect(find.text('HISTOIRE PRINCIPALE'), findsOneWidget);
+      expect(find.text('QUÊTES ANNEXES'), findsOneWidget);
+      expect(find.text('Non reliée au graph principal'), findsWidgets);
+      expect(find.byKey(const ValueKey('storylines-structure-read-only')),
+          findsOneWidget);
+    });
+
     testWidgets('Structure without storyline has no chapter or step action',
         (tester) async {
       final harness = await _pumpStorylinesShell(tester);
@@ -380,6 +488,42 @@ void main() {
           findsOneWidget);
     });
 
+    testWidgets('Structure authoring works on sideQuest without mutating main',
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
+
+      await _createSideQuest(tester, title: 'Missing Bell');
+      await _createChapter(tester, title: 'Side intro');
+      await _createStep(tester, title: 'Find clue');
+
+      final main = harness.project.storylines.singleWhere(
+        (storyline) => storyline.type == StorylineType.main,
+      );
+      final sideQuest = harness.project.storylines.singleWhere(
+        (storyline) => storyline.type == StorylineType.sideQuest,
+      );
+      expect(main.chapters, isEmpty);
+      expect(sideQuest.chapters, hasLength(1));
+      expect(sideQuest.chapters.single.id, 'chapter_side_intro');
+      expect(sideQuest.chapters.single.steps, hasLength(1));
+      expect(sideQuest.chapters.single.steps.single.id, 'step_find_clue');
+      expect(sideQuest.chapters.single.steps.single.sceneLinkIds, isEmpty);
+      expect(sideQuest.sceneLinks, isEmpty);
+      expect(sideQuest.relationships, isEmpty);
+      expect(find.text('Missing Bell'), findsWidgets);
+      expect(find.byKey(const ValueKey('storylines-step-row-step_find_clue')),
+          findsOneWidget);
+    });
+
     testWidgets('Graph summarizes created structure without fake edges',
         (tester) async {
       await _pumpStorylinesShell(
@@ -412,7 +556,80 @@ void main() {
       expect(find.text('Quête annexe fake'), findsNothing);
     });
 
-    testWidgets('generates stable unique ids on collision', (tester) async {
+    testWidgets('Graph explains sideQuest is not linked to main graph yet',
+        (tester) async {
+      await _pumpStorylinesShell(
+        tester,
+        project: _projectWithStorylines([
+          StorylineAsset(
+            id: 'storyline_existing_main',
+            type: StorylineType.main,
+            title: 'Existing main',
+          ),
+        ]),
+      );
+
+      await _createSideQuest(tester, title: 'Missing Bell');
+      await _createChapter(tester, title: 'Side intro');
+      await _createStep(tester, title: 'Find clue');
+      await _openGraphTab(tester);
+
+      final graphCanvas =
+          find.byKey(const ValueKey('storylines-v1-graph-empty-canvas'));
+      expect(
+        find.descendant(of: graphCanvas, matching: find.text('Missing Bell')),
+        findsOneWidget,
+      );
+      expect(
+        find.descendant(
+            of: graphCanvas, matching: find.text('1 chapitre · 1 étape')),
+        findsOneWidget,
+      );
+      expect(
+        find.text('Quête annexe non reliée au graph principal pour l’instant.'),
+        findsOneWidget,
+      );
+      expect(find.textContaining('availability'), findsNothing);
+    });
+
+    testWidgets('main graph does not show sideQuest as a branch yet',
+        (tester) async {
+      await _pumpStorylinesShell(
+        tester,
+        project: _projectWithStorylines([
+          StorylineAsset(
+            id: 'storyline_existing_main',
+            type: StorylineType.main,
+            title: 'Existing main',
+          ),
+        ]),
+      );
+
+      await _createSideQuest(tester, title: 'Missing Bell');
+      await tester.tap(
+        find.byKey(const ValueKey('storylines-v1-row-storyline_existing_main')),
+      );
+      await tester.pump();
+      await _openGraphTab(tester);
+
+      final graphCanvas =
+          find.byKey(const ValueKey('storylines-v1-graph-empty-canvas'));
+      expect(
+        find.descendant(of: graphCanvas, matching: find.text('Existing main')),
+        findsOneWidget,
+      );
+      expect(
+        find.descendant(of: graphCanvas, matching: find.text('Missing Bell')),
+        findsNothing,
+      );
+      expect(
+        find.text('Quête annexe non reliée au graph principal pour l’instant.'),
+        findsNothing,
+      );
+    });
+
+    testWidgets('generates stable unique main ids on collision',
+        (tester) async {
       final harness = await _pumpStorylinesShell(
         tester,
         project: _projectWithStorylines([
@@ -437,6 +654,34 @@ void main() {
       );
     });
 
+    testWidgets('generates stable unique sideQuest ids on collision',
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
+
+      await _createSideQuest(tester, title: 'Lost Key');
+      await _createSideQuest(tester, title: 'Lost Key');
+
+      final ids = harness.project.storylines.map((s) => s.id).toList();
+      expect(ids, contains('sidequest_lost_key'));
+      expect(ids, contains('sidequest_lost_key_2'));
+      expect(ids.toSet(), hasLength(ids.length));
+      expect(
+        harness.project.storylines.where(
+          (storyline) => storyline.type == StorylineType.sideQuest,
+        ),
+        hasLength(2),
+      );
+    });
+
     testWidgets('does not allow creating a second main storyline',
         (tester) async {
       final harness = await _pumpStorylinesShell(
@@ -450,11 +695,29 @@ void main() {
         ]),
       );
 
-      final cta = tester.widget<PokeMapButton>(
-        find.byKey(const ValueKey('storylines-create-main-cta')),
+      await _openCreateDialog(tester);
+      expect(find.text('Une histoire principale existe déjà.'), findsWidgets);
+      await tester
+          .tap(find.byKey(const ValueKey('storylines-create-type-main')));
+      await tester.pump();
+      await tester.enterText(
+        find.byKey(const ValueKey('storylines-create-title-field')),
+        'Second main',
+      );
+      await tester.pump();
+      await tester.tap(find.byKey(const ValueKey('storylines-create-submit')));
+      await tester.pumpAndSettle();
+
+      expect(
+        harness.project.storylines
+            .where((storyline) => storyline.type == StorylineType.main),
+        hasLength(1),
+      );
+      expect(
+        harness.project.storylines
+            .where((storyline) => storyline.type == StorylineType.sideQuest),
+        hasLength(1),
       );
-      expect(cta.onPressed, isNull);
-      expect(harness.project.storylines, hasLength(1));
     });
 
     testWidgets('creation does not import legacy or promote localEventFlow',
@@ -483,6 +746,41 @@ void main() {
       expect(find.text('Local Event Flow'), findsNothing);
     });
 
+    testWidgets('sideQuest creation never imports legacy or localEventFlow',
+        (tester) async {
+      final base = _legacyAndLocalEventProject();
+      final project = ProjectManifest(
+        surfaceCatalog: const ProjectSurfaceCatalog.empty(),
+        name: 'Legacy With Main',
+        maps: const <ProjectMapEntry>[],
+        tilesets: const <ProjectTilesetEntry>[],
+        scenarios: base.scenarios,
+        storylines: [
+          StorylineAsset(
+            id: 'storyline_existing_main',
+            type: StorylineType.main,
+            title: 'Existing main',
+          ),
+        ],
+      );
+      final harness = await _pumpStorylinesShell(tester, project: project);
+      final beforeScenarios = harness.project.scenarios;
+
+      await _createSideQuest(tester, title: 'Missing Bell');
+
+      expect(harness.project.scenarios, beforeScenarios);
+      expect(harness.project.storylines, hasLength(2));
+      expect(
+        harness.project.storylines
+            .singleWhere(
+                (storyline) => storyline.type == StorylineType.sideQuest)
+            .legacySource,
+        isNull,
+      );
+      expect(find.text('Legacy Global Story'), findsNothing);
+      expect(find.text('Local Event Flow'), findsNothing);
+    });
+
     testWidgets('Graph, Structure and disabled future actions do not mutate',
         (tester) async {
       final harness = await _pumpStorylinesShell(
@@ -589,7 +887,7 @@ void main() {
       expect(Theme.of(shellContext).brightness, Brightness.dark);
     });
 
-    testWidgets('writes V1-08 Structure Visual Gate screenshots',
+    testWidgets('writes V1-09 Side Quest Visual Gate screenshots',
         (tester) async {
       final project = _projectWithStorylines([
         StorylineAsset(
@@ -604,45 +902,48 @@ void main() {
         surfaceSize: const Size(1600, 1000),
         project: project,
       );
-      await _openStructureTab(tester);
+
+      await _openCreateDialog(tester);
       await expectLater(
-        find.byKey(const ValueKey('storylines-workspace-shell')),
+        find.byKey(const ValueKey('storylines-create-main-dialog')),
         matchesGoldenFile(
           '../../../reports/narrativeStudio/storylines/screenshots/'
-          'ns_storylines_v1_08_structure_empty.png',
+          'ns_storylines_v1_09_create_side_quest_dialog.png',
         ),
       );
-
-      await tester
-          .tap(find.byKey(const ValueKey('storylines-new-chapter-action')));
+      await tester.tap(find.byKey(const ValueKey('storylines-create-cancel')));
       await tester.pumpAndSettle();
+
+      await _createSideQuest(
+        tester,
+        title: 'Visual Side Quest',
+        description: 'Optional visual storyline.',
+      );
+      await _openGraphTab(tester);
       await expectLater(
-        find.byKey(const ValueKey('storylines-create-chapter-dialog')),
+        find.byKey(const ValueKey('storylines-workspace-shell')),
         matchesGoldenFile(
           '../../../reports/narrativeStudio/storylines/screenshots/'
-          'ns_storylines_v1_08_create_chapter_dialog.png',
+          'ns_storylines_v1_09_created_side_quest_graph.png',
         ),
       );
-      await tester.tap(
-        find.byKey(const ValueKey('storylines-create-chapter-cancel')),
-      );
-      await tester.pumpAndSettle();
 
-      await _createChapter(tester, title: 'Visual Chapter');
+      await _openStructureTab(tester);
+      await _createChapter(tester, title: 'Visual Side Chapter');
+      await _createStep(tester, title: 'Visual Side Step');
       await expectLater(
         find.byKey(const ValueKey('storylines-workspace-shell')),
         matchesGoldenFile(
           '../../../reports/narrativeStudio/storylines/screenshots/'
-          'ns_storylines_v1_08_created_chapter.png',
+          'ns_storylines_v1_09_created_side_quest_structure.png',
         ),
       );
 
-      await _createStep(tester, title: 'Visual Step');
       await expectLater(
-        find.byKey(const ValueKey('storylines-workspace-shell')),
+        find.byKey(const ValueKey('storylines-secondary-panel')),
         matchesGoldenFile(
           '../../../reports/narrativeStudio/storylines/screenshots/'
-          'ns_storylines_v1_08_created_step.png',
+          'ns_storylines_v1_09_storyline_list_with_side_quest.png',
         ),
       );
     });
@@ -701,6 +1002,30 @@ Future<void> _createMainStoryline(
   await tester.pumpAndSettle();
 }
 
+Future<void> _createSideQuest(
+  WidgetTester tester, {
+  required String title,
+  String? description,
+}) async {
+  await _openCreateDialog(tester);
+  await tester
+      .tap(find.byKey(const ValueKey('storylines-create-type-sidequest')));
+  await tester.pump();
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
 Future<void> _openCreateChapterDialog(WidgetTester tester) async {
   await _openStructureTab(tester);
   await tester.tap(find.byKey(const ValueKey('storylines-new-chapter-action')));
```

### Diff complet de road_map_storylines.md

```text
diff --git a/reports/narrativeStudio/storylines/road_map_storylines.md b/reports/narrativeStudio/storylines/road_map_storylines.md
index 17694454..ac7b82cb 100644
--- a/reports/narrativeStudio/storylines/road_map_storylines.md
+++ b/reports/narrativeStudio/storylines/road_map_storylines.md
@@ -311,7 +311,7 @@ Interprétation V0 :
 | NS-STORYLINES-V1-07 | Create Main Storyline Flow V0 | editor authoring | DONE | NS-STORYLINES-V1-07-bis |
 | NS-STORYLINES-V1-07-bis | Storylines Workspace Cleanup / Dead Legacy Removal | editor UI cleanup | DONE | NS-STORYLINES-V1-08 |
 | NS-STORYLINES-V1-08 | Structure Tab Authoring V0 | editor authoring | DONE | NS-STORYLINES-V1-09 |
-| NS-STORYLINES-V1-09 | Create Side Quest Flow V0 | editor authoring | TODO | NS-STORYLINES-V1-10 |
+| NS-STORYLINES-V1-09 | Create Side Quest Flow V0 | editor authoring | DONE | NS-STORYLINES-V1-10 |
 | NS-STORYLINES-V1-10 | Graph From StorylineAsset V0 | editor graph | TODO | NS-STORYLINES-V1-11 |
 | NS-STORYLINES-V1-11 | Side Quest Graph Integration V0 | editor graph | TODO | NS-STORYLINES-V1-12 |
 | NS-STORYLINES-V1-12 | V1 Visual Graph Enrichment | visual gate | TODO | NS-STORYLINES-V1-CHECKPOINT |
@@ -896,10 +896,10 @@ Décision temporaire :
 ## 13. Current status
 
 ```text
-Roadmap status: V0 ACCEPTED WITH V1 LIMITATIONS / V1 STRUCTURE AUTHORING DONE
-Current lot: NS-STORYLINES-V1-08
+Roadmap status: V0 ACCEPTED WITH V1 LIMITATIONS / V1 SIDE QUEST AUTHORING DONE
+Current lot: NS-STORYLINES-V1-09
 Current lot status: DONE
-Next recommended lot: NS-STORYLINES-V1-09 — Create Side Quest Flow V0
+Next recommended lot: NS-STORYLINES-V1-10 — Graph From StorylineAsset V0
 ```
 
 | Lot | Status | Last update | Notes |
@@ -928,7 +928,7 @@ Next recommended lot: NS-STORYLINES-V1-09 — Create Side Quest Flow V0
 | NS-STORYLINES-V1-07 | DONE | 2026-05-28 | Create Main Storyline Flow V0 livré : création main `StorylineAsset`, Graph/Structure seulement, aucun import legacy automatique. |
 | NS-STORYLINES-V1-07-bis | DONE | 2026-05-28 | Cleanup technique Storylines livré sans changement produit : legacy mort absent, tap silencieux supprimé, Visual Gate V1-07 régénéré. |
 | NS-STORYLINES-V1-08 | DONE | 2026-05-29 | Structure Tab Authoring V0 livré : création de chapitres et steps, Graph minimal honnête, aucun sceneLink/sideQuest/import legacy. |
-| NS-STORYLINES-V1-09 | TODO | 2026-05-29 | Create Side Quest Flow V0 recommandé comme prochain lot. |
+| NS-STORYLINES-V1-09 | DONE | 2026-05-29 | Create Side Quest Flow V0 livré : création réelle de `StorylineAsset(type: sideQuest, status: draft)`, liste main/sideQuest séparée, Structure réutilisée, aucune relationship/availability/sceneLink/import legacy. |
 
 ## 14. V1 Creation Readiness Notes
 
@@ -965,6 +965,19 @@ Suite V1 documentaire recommandée :
 
 ## 15. Changelog
 
+### 2026-05-29 — NS-STORYLINES-V1-09
+
+- Create Side Quest Flow V0 livré côté editor : `Nouvelle storyline` peut créer une vraie `StorylineAsset(type: sideQuest, status: draft)` après existence d'une main storyline.
+- Le dialog de création choisit entre `Histoire principale` et `Quête annexe` ; la main reste unique et la sideQuest est sélectionnée après création.
+- Le panneau secondaire sépare `Histoire principale` et `Quêtes annexes`, avec compteurs réels depuis `ProjectManifest.storylines`.
+- Structure réutilise le même authoring chapters/steps pour une sideQuest sans modifier la main storyline.
+- Graph reste minimal et honnête : une sideQuest sélectionnée indique qu'elle n'est pas reliée au graph principal ; aucune `StorylineRelationship`, `SideQuestAvailability`, scene placeholder ou `StorylineSceneLink` n'est créée.
+- Aucun import legacy automatique ; `localEventFlow` reste exclu.
+- Visual Gate V1-09 produit en dark theme.
+- Fichiers modifiés/créés : `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`, `packages/map_editor/test/storylines_workspace_shell_test.dart`, captures V1-09, rapport V1-09.
+- Tests exécutés : `flutter test test/storylines_workspace_shell_test.dart`, `flutter test test/storylines_current_global_story_characterization_test.dart`, `flutter test test/narrative_workspace_projection_test.dart`, analyse ciblée, `rg` anti-couleurs.
+- Prochain lot recommandé : `NS-STORYLINES-V1-10 — Graph From StorylineAsset V0`.
+
 ### 2026-05-29 — NS-STORYLINES-V1-08
 
 - Structure Tab Authoring V0 livré côté editor : création de chapitres et d'étapes narratives dans `ProjectManifest.storylines`.
```

### Sortie exacte du test shell Storylines

Commande : `cd packages/map_editor && flutter test test/storylines_workspace_shell_test.dart`

Exit code : `0`

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/storylines_workspace_shell_test.dart
00:00 +0: NS-STORYLINES-V1-09 side quest authoring flow shows only Graph and Structure tabs
00:00 +1: NS-STORYLINES-V1-09 side quest authoring flow shows V1 empty state without importing legacy globalStory
00:00 +2: NS-STORYLINES-V1-09 side quest authoring flow opens and cancels create main storyline dialog without mutation
00:00 +3: NS-STORYLINES-V1-09 side quest authoring flow requires title before create
00:00 +4: NS-STORYLINES-V1-09 side quest authoring flow does not create sideQuest before a main storyline exists
00:01 +5: NS-STORYLINES-V1-09 side quest authoring flow dialog selects sideQuest when a main storyline exists
00:01 +6: NS-STORYLINES-V1-09 side quest authoring flow creates a main StorylineAsset and syncs Graph and Structure
00:01 +7: NS-STORYLINES-V1-09 side quest authoring flow creates a sideQuest StorylineAsset and selects it
00:01 +8: NS-STORYLINES-V1-09 side quest authoring flow Structure without storyline has no chapter or step action
00:01 +9: NS-STORYLINES-V1-09 side quest authoring flow opens and cancels create chapter without mutation
00:01 +10: NS-STORYLINES-V1-09 side quest authoring flow requires chapter title before create
00:01 +11: NS-STORYLINES-V1-09 side quest authoring flow creates chapters with stable ids, order and selection
00:01 +12: NS-STORYLINES-V1-09 side quest authoring flow step action requires a selected chapter
00:01 +13: NS-STORYLINES-V1-09 side quest authoring flow opens and cancels create step without mutation
00:02 +14: NS-STORYLINES-V1-09 side quest authoring flow requires step title before create
00:02 +15: NS-STORYLINES-V1-09 side quest authoring flow creates steps with global unique ids and order
00:02 +16: NS-STORYLINES-V1-09 side quest authoring flow Structure authoring works on sideQuest without mutating main
00:02 +17: NS-STORYLINES-V1-09 side quest authoring flow Graph summarizes created structure without fake edges
00:02 +18: NS-STORYLINES-V1-09 side quest authoring flow Graph explains sideQuest is not linked to main graph yet
00:02 +19: NS-STORYLINES-V1-09 side quest authoring flow main graph does not show sideQuest as a branch yet
00:03 +20: NS-STORYLINES-V1-09 side quest authoring flow generates stable unique main ids on collision
00:03 +21: NS-STORYLINES-V1-09 side quest authoring flow generates stable unique sideQuest ids on collision
00:03 +22: NS-STORYLINES-V1-09 side quest authoring flow does not allow creating a second main storyline
00:03 +23: NS-STORYLINES-V1-09 side quest authoring flow creation does not import legacy or promote localEventFlow
00:03 +24: NS-STORYLINES-V1-09 side quest authoring flow sideQuest creation never imports legacy or localEventFlow
00:03 +25: NS-STORYLINES-V1-09 side quest authoring flow Graph, Structure and disabled future actions do not mutate
00:03 +26: NS-STORYLINES-V1-09 side quest authoring flow Structure authoring does not import legacy or localEventFlow
00:03 +27: NS-STORYLINES-V1-09 side quest authoring flow keeps target fake data and Maps out of the V1 UI
00:03 +28: NS-STORYLINES-V1-09 side quest authoring flow storylines UI source keeps raw colors out of the feature
00:03 +29: NS-STORYLINES-V1-09 side quest authoring flow storylines shell test keeps raw colors out
00:03 +30: NS-STORYLINES-V1-09 side quest authoring flow uses PokeMap dark theme in the Visual Gate harness
00:03 +31: NS-STORYLINES-V1-09 side quest authoring flow writes V1-09 Side Quest Visual Gate screenshots
00:04 +32: All tests passed!
```

### Sortie exacte de la régression Global Story characterization

Commande : `cd packages/map_editor && flutter test test/storylines_current_global_story_characterization_test.dart`

Exit code : `0`

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

### Sortie exacte de la régression projection narrative

Commande : `cd packages/map_editor && flutter test test/narrative_workspace_projection_test.dart`

Exit code : `0`

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/narrative_workspace_projection_test.dart
00:00 +0: buildNarrativeWorkspaceProjection splits global story and local flows, and projects steps
00:00 +1: buildNarrativeWorkspaceProjection projects ordered steps from Step Studio v1 metadata document
00:00 +2: buildNarrativeWorkspaceProjection projects chapters from Global Story Studio metadata
00:00 +3: All tests passed!
```

### Sortie exacte de flutter analyze ciblé

Commande : `cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/storylines_workspace.dart test/storylines_workspace_shell_test.dart test/storylines_current_global_story_characterization_test.dart test/narrative_workspace_projection_test.dart`

Exit code : `0`

```text
Analyzing 4 items...                                            
No issues found! (ran in 1.4s)
```

### Sortie exacte du rg anti-couleurs

Commande : `rg "Color\(0x|Colors\." packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart packages/map_editor/test/storylines_workspace_shell_test.dart`

Exit code : `1`

Sortie : <vide>

### Résultats du Visual Gate

```text
EXISTS reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_09_create_side_quest_dialog.png (15535 bytes)
EXISTS reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_09_created_side_quest_graph.png (40174 bytes)
EXISTS reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_09_created_side_quest_structure.png (47962 bytes)
EXISTS reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_09_storyline_list_with_side_quest.png (47962 bytes)
```

### Git status final exact

```text
 M packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
 M packages/map_editor/test/storylines_workspace_shell_test.dart
 M reports/narrativeStudio/storylines/road_map_storylines.md
?? reports/narrativeStudio/storylines/ns_storylines_v1_09_create_side_quest_flow_v0.md
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_09_create_side_quest_dialog.png
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_09_created_side_quest_graph.png
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_09_created_side_quest_structure.png
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_09_storyline_list_with_side_quest.png
```

### Git diff --stat final

```text
 .../lib/src/ui/canvas/storylines_workspace.dart    | 376 ++++++++++++++++++---
 .../test/storylines_workspace_shell_test.dart      | 373 ++++++++++++++++++--
 .../storylines/road_map_storylines.md              |  23 +-
 3 files changed, 687 insertions(+), 85 deletions(-)
```

### Git diff --name-only final

```text
packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
packages/map_editor/test/storylines_workspace_shell_test.dart
reports/narrativeStudio/storylines/road_map_storylines.md
```

### Git diff --check final

Sortie : <vide>

## 21. Self-review

- Le lot reste dans le scope V1-09 : création de sideQuest seulement.
- La main storyline reste unique ; une sideQuest nécessite une main existante dans le dialog.
- Structure fonctionne sur sideQuest sans dupliquer la logique de mutation.
- Graph est volontairement minimal et signale l'absence de relation au graph principal.
- Les champs `relationships` et `sceneLinks` restent vides sur les sideQuests créées.
- Les tests couvrent legacy/globalStory/localEventFlow pour éviter une importation implicite.
- Risque restant : le fichier `storylines_workspace.dart` grossit encore ; V1-10 devrait éviter de mélanger un vrai graph riche dans ce même fichier sans extraction prudente.
