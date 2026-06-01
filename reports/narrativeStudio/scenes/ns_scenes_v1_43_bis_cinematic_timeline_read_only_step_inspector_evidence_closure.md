# NS-SCENES-V1-43-bis — Cinematic Timeline Read-only / Step Inspector Evidence Closure

## 1. Résumé exécutif

Ce bis est evidence-only. Il ne modifie aucun fichier de production, aucun test, aucune roadmap, aucun rapport V1-43 et aucune capture V1-43. Il crée uniquement ce rapport de clôture documentaire pour reproduire les preuves du lot `NS-SCENES-V1-43`.

## 2. Pourquoi ce bis existe

Le lot V1-43 était fonctionnellement validé, mais son Evidence Pack était trop résumé. Ce bis reproduit le contenu complet du rapport V1-43, les hunks complets des fichiers modifiés par le commit V1-43, les sorties des tests/analyze, la preuve de la Visual Gate et l'état Git final.

## 3. Gate 0

$ pwd
(exit 0)

```text
/Users/karim/Project/pokemonProject
```

$ git branch --show-current
(exit 0)

```text
main
```

$ git status --short --untracked-files=all
(exit 0)

```text
<vide>
```

$ git diff --stat
(exit 0)

```text
<vide>
```

$ git diff --name-only
(exit 0)

```text
<vide>
```

$ git log --oneline -n 10
(exit 0)

```text
6c3b1074 feat(narrative): add cinematic timeline read-only step inspector v0 (NS-SCENES-V1-43)
e95290ce feat(narrative): add cinematic builder v0 shell evidence closure (NS-SCENES-V1-42-BIS)
c9d44fc8 feat(narrative): add cinematic builder v0 shell (NS-SCENES-V1-42)
38f09efa feat(narrative): add cinematic builder v0 scope and runtime playback contract (NS-SCENES-V1-41)
9e1d45d9 feat(narrative): add cinematic runtime adapter v0 bis evidence closure (NS-SCENES-V1-40)
b39d596f feat(narrative): add cinematic runtime adapter v0 (NS-SCENES-V1-40)
eadb0052 chore(reports): add missing screenshot for V1-15 wire anchor color code
0fe8fa1f feat(narrative): add cinematic scene builder picker v0 (NS-SCENES-V1-39)
6644def0 feat(narrative): add cinematics library v0 (NS-SCENES-V1-38)
05d631f8 feat(narrative): add cinematic asset core model v0 (NS-SCENES-V1-37)
```

## 4. Fichiers V1-43 préexistants avant le bis

Fichiers V1-43 présents avant ce bis selon `HEAD` :

$ git show --stat --oneline --name-only HEAD
(exit 0)

```text
6c3b1074 feat(narrative): add cinematic timeline read-only step inspector v0 (NS-SCENES-V1-43)
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
reports/narrativeStudio/scenes/ns_scenes_v1_43_cinematic_timeline_read_only_step_inspector_v0.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_43_cinematic_timeline_read_only_step_inspector_v0.png
```

## 5. Fichier créé par le bis

Création autorisée unique :

```text
reports/narrativeStudio/scenes/ns_scenes_v1_43_bis_cinematic_timeline_read_only_step_inspector_evidence_closure.md
```

## 6. Contenu complet — rapport V1-43

```md
# NS-SCENES-V1-43 — Cinematic Timeline Read-only / Step Inspector V0

## 1. Resume executif

Le lot est DONE. Le Cinematic Builder V0 affiche maintenant les steps reels d'un `CinematicAsset` canonique, permet une selection locale de bloc et montre un inspecteur detaille lecture seule avec diagnostics contextualises. Aucun contrat core/runtime n'a ete modifie.

## 2. Gate 0

- Branche : `main`.
- Worktree avant lot : propre.
- Derniers commits observes : V1-42-bis, V1-42, V1-41, V1-40-bis, V1-40.
- Strategie : changement editor-only dans `map_editor`, sans operation Git write.

## 3. Fichiers lus

- `AGENTS.md`
- `agent_rules.md`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- rapports V1-41, V1-42, V1-42-bis
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `packages/map_editor/test/cinematics_library_workspace_test.dart`
- `packages/map_core/lib/src/models/cinematic_asset.dart`
- `packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart`
- `packages/map_core/lib/src/read_models/cinematics_library_read_model.dart`

## 4. Design Gate — Cinematic Timeline Read-only / Step Inspector V0

1. Les donnees de steps detailles existent deja dans `CinematicAsset.timeline.steps`.
2. Le read model Library reste un resume ; pas d'enrichissement `map_core`.
3. La Library passe l'asset canonique complet au Builder via `findCinematicById`.
4. La selection vit dans `_CinematicBuilderWorkspaceState._selectedStepId`.
5. `didUpdateWidget` nettoie la selection si la cinematique change ou si le step n'existe plus.
6. La timeline est rendue par cartes `PokeMapCard`, sans callback de mutation.
7. L'inspecteur utilise uniquement `_KeyValue`, `PokeMapBadge` et textes lecture seule.
8. Champs exposes : titre, id, index, kind, duree, actorId, targetId, dialogue, assetRef, metadata.
9. Les diagnostics viennent de `diagnoseCinematicAsset(asset)` filtres par `stepId`.
10. La preview reste sandbox ; elle rappelle seulement le bloc selectionne.
11. Les couleurs viennent du design system et de `context.pokeMapColors`.
12. La visual gate est `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_43_cinematic_timeline_read_only_step_inspector_v0.png`.

## 5. Scope realise

- Builder converti en `StatefulWidget` pour porter une selection locale.
- Timeline remplacee par une liste ordonnee des steps existants.
- Cartes de step avec index, label fallback, kind, duree, acteur, cible, assetRef et badge diagnostic.
- Inspecteur de step selectionne complet et lecture seule.
- Empty state sans selection conserve.
- Palette verrouillee et boutons header toujours inactifs.

## 6. Donnees timeline / read model

Decision : `map_core` n'a pas besoin de nouveau read model pour V1-43. La Library continue d'utiliser `CinematicsLibraryEntry` pour l'exploration et transmet l'asset complet au Builder uniquement pour afficher les details.

## 7. Selection locale de step

La selection est locale, non serialisee et non propagee. Elle persiste tant que le meme asset reste ouvert et que le step selectionne est encore present.

## 8. Timeline read-only

Chaque step affiche son ordre, un titre lisible, son kind et les champs disponibles. L'etat vide reste honnete et ne propose aucune action.

## 9. Step Inspector read-only

Sans selection : `Aucun bloc selectionne` avec une aide courte. Avec selection : details du step, metadata triee, statut preview/runtime lecture seule, et diagnostics propres au bloc.

## 10. Diagnostics contextualises

Les diagnostics de step sont affiches dans l'inspecteur du bloc selectionne. Les diagnostics globaux deja exposes par la Library restent visibles quand ils ne ciblent pas le bloc courant.

## 11. Preview sandbox inchangée

La preview ne joue rien. Elle conserve le message sandbox et affiche seulement un badge indiquant le step selectionne.

## 12. Legacy bridge policy inchangée

Les bridges legacy restent exclus du Builder canonique. Les tests Library continuent de verifier que seuls les assets canoniques ouvrent le Builder.

## 13. Design system

Les nouvelles surfaces utilisent `PokeMapPanel`, `PokeMapCard`, `PokeMapBadge`, `PokeMapButton`, `PokeMapIconTile` et les tokens de theme. Aucun hardcode couleur n'a ete ajoute dans les fichiers UI modifies.

## 14. Tests ajoutes ou modifies

- Liste ordonnee des steps avec labels, kind, duree, acteur/cible/dialogue/assetRef.
- Selection locale de step et mise a jour de l'inspecteur.
- Diagnostics de step sans activation d'action.
- Etat timeline vide conserve.
- Non-mutation via comparaison `ProjectManifest.toJson()`.
- Capture V1-43 avec timeline multi-step et step selectionne.

## 15. Visual Gate

- Fichier cree : `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_43_cinematic_timeline_read_only_step_inspector_v0.png`.
- Contenu verifie visuellement : Builder ouvert, timeline multi-step, bloc dialogue selectionne, inspecteur detaille, palette verrouillee, preview sandbox.

## 16. Commandes executees

- `cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart`
- `cd packages/map_editor && flutter test --reporter=compact test/cinematics_library_workspace_test.dart`
- `cd packages/map_editor && flutter test --update-goldens --dart-define=NS_SCENES_V1_43_CAPTURE_CINEMATIC_BUILDER_TIMELINE=true --reporter=compact test/cinematic_builder_workspace_test.dart`
- `cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart test/cinematic_builder_workspace_test.dart test/cinematics_library_workspace_test.dart`
- Checks de perimetre code : packages runtime/gameplay/battle/examples, `map_core`, couleurs UI, references runtime interdites, operations de timeline hors scope, donnees produit nommees.
- `git diff --check`
- `git diff --stat`
- `git diff --name-only`
- `git status --short --untracked-files=all`

## 17. Resultats des tests

- RED initial : compilation bloquee car `CinematicBuilderWorkspace` n'avait pas encore le parametre `asset`.
- Builder final : `+7 All tests passed!`
- Library final : `+7 All tests passed!`
- Visual gate final : `+7 All tests passed!`

## 18. Analyze

`flutter analyze --no-fatal-infos` sur les quatre fichiers cibles : `No issues found!`.

## 19. Checks anti-scope

- `packages/map_runtime`, `packages/map_gameplay`, `packages/map_battle`, `examples` : aucun fichier modifie.
- `packages/map_core` : aucun fichier modifie.
- UI cinematics : aucun hardcode couleur detecte.
- UI/tests V1-43 : aucune reference runtime interdite detectee.
- UI/tests V1-43 : aucune operation de timeline hors scope detectee.
- UI/tests V1-43 : aucune donnee produit nommee ajoutee.
- `git diff --check` : OK.
- Etat Git final : 5 fichiers modifies suivis et 2 fichiers non suivis crees pour le rapport et la capture.

## 20. Fichiers crees

- `reports/narrativeStudio/scenes/ns_scenes_v1_43_cinematic_timeline_read_only_step_inspector_v0.md`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_43_cinematic_timeline_read_only_step_inspector_v0.png`

## 21. Fichiers modifies

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

## 22. Roadmaps mises a jour

- V1-43 ajoute en DONE.
- Prochain lot recommande : `NS-SCENES-V1-44 — Cinematic Timeline Authoring Drafts V0`.

## 23. Limites connues

- Pas d'edition de blocs.
- Pas de changement d'ordre.
- Pas de persistance de selection.
- Pas de vrai player visuel.
- Pas de migration legacy.
- Pas de nouveau contrat core.

## 24. Non-objectifs confirmes

- Aucun changement runtime/gameplay/battle/examples.
- Aucune mutation du `ProjectManifest` depuis le Builder.
- Aucun bouton d'action de timeline actif.
- Aucun callback de sauvegarde de deroule.
- Aucun champ editable dans l'inspecteur de step.

## 25. Evidence Pack

- `CinematicBuilderWorkspace` prend maintenant `asset`, garde `_selectedStepId` et derive `selectedStep`.
- `_TimelineStepCard` rend les cartes de step avec `selected` et `onTap` local.
- `_SelectedStepInspector` affiche les champs du step avec helpers `_stepTitle`, `_stepDurationLabel`, `_metadataLabel`.
- `_stepDiagnostics` filtre `diagnoseCinematicAsset(asset).diagnostics` par `stepId`.
- `CinematicsLibraryWorkspace` resolve l'asset canonique avec `findCinematicById`.
- Les tests fixtures `_richCinematic` et `_diagnosticCinematic` couvrent les champs detailles et le diagnostic de duree negative.

## 26. Auto-review critique

Risque principal : l'inspecteur appelle `diagnoseCinematicAsset` pour chaque carte/selection. Le volume V0 est faible ; si les timelines deviennent longues, un cache local par build pourra etre ajoute.

Point surveille : la selection est detruite au retour Library, ce qui est volontaire pour V1-43 mais devra etre reconsidere si un futur lot ajoute une navigation multi-pane persistante.

## 27. Recommandation pour le prochain lot

Lancer `NS-SCENES-V1-44 — Cinematic Timeline Authoring Drafts V0` seulement avec operations pures, tests de non-regression et UI no-code bornee. V1-43 fournit maintenant la surface d'inspection necessaire pour verifier ces futurs drafts.

```

## 7. Preuve de la Visual Gate

$ ls -lh reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_43_cinematic_timeline_read_only_step_inspector_v0.png
(exit 0)

```text
-rw-r--r--  1 karim  staff   164K Jun  1 18:56 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_43_cinematic_timeline_read_only_step_inspector_v0.png
```

$ file reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_43_cinematic_timeline_read_only_step_inspector_v0.png
(exit 0)

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_43_cinematic_timeline_read_only_step_inspector_v0.png: PNG image data, 1280 x 860, 8-bit/color RGBA, non-interlaced
```

$ shasum -a 256 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_43_cinematic_timeline_read_only_step_inspector_v0.png
(exit 0)

```text
66088b2fee13dd40d1bfeabe8eccc5ed5404d8787f9d96c342210b2a5a22708b  reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_43_cinematic_timeline_read_only_step_inspector_v0.png
```

## 8. Hunks complets — cinematic_builder_workspace.dart

$ git show --format= --patch HEAD -- packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
(exit 0)

```diff
diff --git a/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart b/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
index ee4cd0e8..d5a7c59c 100644
--- a/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
+++ b/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
@@ -5,18 +5,41 @@ import 'package:map_core/map_core.dart';
 import '../../../theme/theme.dart';
 import '../../design_system/design_system.dart';
 
-class CinematicBuilderWorkspace extends StatelessWidget {
+class CinematicBuilderWorkspace extends StatefulWidget {
   const CinematicBuilderWorkspace({
     super.key,
     required this.entry,
+    required this.asset,
     required this.onBackToLibrary,
   });
 
   final CinematicsLibraryEntry entry;
+  final CinematicAsset asset;
   final VoidCallback onBackToLibrary;
 
+  @override
+  State<CinematicBuilderWorkspace> createState() =>
+      _CinematicBuilderWorkspaceState();
+}
+
+class _CinematicBuilderWorkspaceState extends State<CinematicBuilderWorkspace> {
+  String? _selectedStepId;
+
+  @override
+  void didUpdateWidget(CinematicBuilderWorkspace oldWidget) {
+    super.didUpdateWidget(oldWidget);
+    final sameCinematic = oldWidget.asset.id == widget.asset.id;
+    if (!sameCinematic || !_hasStep(widget.asset, _selectedStepId)) {
+      _selectedStepId = null;
+    }
+  }
+
   @override
   Widget build(BuildContext context) {
+    final selectedStep = _selectedStep(widget.asset, _selectedStepId);
+    final selectedStepIndex = selectedStep == null
+        ? null
+        : widget.asset.timeline.steps.indexOf(selectedStep);
     return Material(
       type: MaterialType.transparency,
       child: PokeMapPageSurface(
@@ -24,7 +47,10 @@ class CinematicBuilderWorkspace extends StatelessWidget {
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.stretch,
           children: [
-            _BuilderHeader(entry: entry, onBackToLibrary: onBackToLibrary),
+            _BuilderHeader(
+              entry: widget.entry,
+              onBackToLibrary: widget.onBackToLibrary,
+            ),
             const SizedBox(height: 12),
             Expanded(
               child: Row(
@@ -32,18 +58,31 @@ class CinematicBuilderWorkspace extends StatelessWidget {
                 children: [
                   SizedBox(
                     width: 250,
-                    child: _BlockPalette(entry: entry),
+                    child: _BlockPalette(entry: widget.entry),
                   ),
                   const SizedBox(width: 12),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.stretch,
                       children: [
-                        Expanded(child: _PreviewSandbox(entry: entry)),
+                        Expanded(
+                          child: _PreviewSandbox(
+                            entry: widget.entry,
+                            selectedStep: selectedStep,
+                            selectedStepIndex: selectedStepIndex,
+                          ),
+                        ),
                         const SizedBox(height: 12),
                         SizedBox(
                           height: 220,
-                          child: _TimelinePlaceholder(entry: entry),
+                          child: _TimelinePlaceholder(
+                            entry: widget.entry,
+                            asset: widget.asset,
+                            selectedStepId: _selectedStepId,
+                            onStepSelected: (step) {
+                              setState(() => _selectedStepId = step.id);
+                            },
+                          ),
                         ),
                       ],
                     ),
@@ -51,7 +90,12 @@ class CinematicBuilderWorkspace extends StatelessWidget {
                   const SizedBox(width: 12),
                   SizedBox(
                     width: 300,
-                    child: _InspectorPlaceholder(entry: entry),
+                    child: _InspectorPlaceholder(
+                      entry: widget.entry,
+                      asset: widget.asset,
+                      selectedStep: selectedStep,
+                      selectedStepIndex: selectedStepIndex,
+                    ),
                   ),
                 ],
               ),
@@ -311,9 +355,15 @@ class _PaletteBlockTile extends StatelessWidget {
 }
 
 class _PreviewSandbox extends StatelessWidget {
-  const _PreviewSandbox({required this.entry});
+  const _PreviewSandbox({
+    required this.entry,
+    required this.selectedStep,
+    required this.selectedStepIndex,
+  });
 
   final CinematicsLibraryEntry entry;
+  final CinematicTimelineStep? selectedStep;
+  final int? selectedStepIndex;
 
   @override
   Widget build(BuildContext context) {
@@ -370,6 +420,17 @@ class _PreviewSandbox extends StatelessWidget {
                   ),
                 ],
               ),
+              if (selectedStep != null && selectedStepIndex != null) ...[
+                const SizedBox(height: 12),
+                const _MutedText('Preview réelle à venir. Bloc sélectionné :'),
+                const SizedBox(height: 6),
+                PokeMapBadge(
+                  label: '${selectedStepIndex! + 1}. '
+                      '${_stepTitle(selectedStep!, selectedStepIndex!)} • '
+                      '${selectedStep!.kind.name}',
+                  variant: PokeMapBadgeVariant.info,
+                ),
+              ],
             ],
           ),
         ),
@@ -379,18 +440,27 @@ class _PreviewSandbox extends StatelessWidget {
 }
 
 class _TimelinePlaceholder extends StatelessWidget {
-  const _TimelinePlaceholder({required this.entry});
+  const _TimelinePlaceholder({
+    required this.entry,
+    required this.asset,
+    required this.selectedStepId,
+    required this.onStepSelected,
+  });
 
   final CinematicsLibraryEntry entry;
+  final CinematicAsset asset;
+  final String? selectedStepId;
+  final ValueChanged<CinematicTimelineStep> onStepSelected;
 
   @override
   Widget build(BuildContext context) {
     final timeline = entry.timeline;
+    final steps = asset.timeline.steps;
     return PokeMapPanel(
       key: const ValueKey('cinematic-builder-timeline-placeholder'),
       expandChild: true,
       padding: const EdgeInsets.all(12),
-      child: timeline.isEmpty
+      child: steps.isEmpty
           ? const _EmptyTimelineState()
           : SingleChildScrollView(
               child: Column(
@@ -398,7 +468,7 @@ class _TimelinePlaceholder extends StatelessWidget {
                 children: [
                   const _SectionTitle(
                     title: 'Déroulé read-only',
-                    subtitle: 'Résumé issu du CinematicAsset',
+                    subtitle: 'Steps existants dans l’ordre',
                   ),
                   const SizedBox(height: 8),
                   Wrap(
@@ -427,26 +497,15 @@ class _TimelinePlaceholder extends StatelessWidget {
                     ],
                   ),
                   const SizedBox(height: 10),
-                  if (timeline.stepKindLabels.isNotEmpty)
-                    _KeyValue(
-                      label: 'Types',
-                      value: timeline.stepKindLabels.join(', '),
-                    ),
-                  if (timeline.previewLabels.isNotEmpty) ...[
-                    const SizedBox(height: 4),
-                    const _MutedText('Aperçu textuel des blocs'),
-                    const SizedBox(height: 6),
-                    Wrap(
-                      spacing: 6,
-                      runSpacing: 6,
-                      children: [
-                        for (final label in timeline.previewLabels)
-                          PokeMapBadge(
-                            label: label,
-                            variant: PokeMapBadgeVariant.info,
-                          ),
-                      ],
+                  for (final indexedStep in steps.asMap().entries) ...[
+                    _TimelineStepCard(
+                      asset: asset,
+                      step: indexedStep.value,
+                      index: indexedStep.key,
+                      selected: selectedStepId == indexedStep.value.id,
+                      onTap: () => onStepSelected(indexedStep.value),
                     ),
+                    const SizedBox(height: 8),
                   ],
                 ],
               ),
@@ -455,6 +514,93 @@ class _TimelinePlaceholder extends StatelessWidget {
   }
 }
 
+class _TimelineStepCard extends StatelessWidget {
+  const _TimelineStepCard({
+    required this.asset,
+    required this.step,
+    required this.index,
+    required this.selected,
+    required this.onTap,
+  });
+
+  final CinematicAsset asset;
+  final CinematicTimelineStep step;
+  final int index;
+  final bool selected;
+  final VoidCallback onTap;
+
+  @override
+  Widget build(BuildContext context) {
+    final diagnostics = _stepDiagnostics(asset, step);
+    return PokeMapCard(
+      key: ValueKey('cinematic-builder-step-card-${step.id}'),
+      selected: selected,
+      onTap: onTap,
+      padding: const EdgeInsets.all(10),
+      child: Column(
+        crossAxisAlignment: CrossAxisAlignment.stretch,
+        children: [
+          Row(
+            children: [
+              PokeMapBadge(
+                label: '${index + 1}',
+                variant: selected
+                    ? PokeMapBadgeVariant.info
+                    : PokeMapBadgeVariant.neutral,
+              ),
+              const SizedBox(width: 8),
+              Expanded(child: _StrongText(_stepTitle(step, index))),
+              const SizedBox(width: 8),
+              PokeMapBadge(
+                label: step.kind.name,
+                variant: PokeMapBadgeVariant.narrative,
+              ),
+              if (selected) ...[
+                const SizedBox(width: 6),
+                const PokeMapBadge(
+                  label: 'Sélectionné',
+                  variant: PokeMapBadgeVariant.info,
+                ),
+              ],
+            ],
+          ),
+          const SizedBox(height: 8),
+          Wrap(
+            spacing: 6,
+            runSpacing: 6,
+            children: [
+              PokeMapBadge(
+                label: _stepDurationLabel(step),
+                variant: PokeMapBadgeVariant.neutral,
+              ),
+              if (step.actorId != null)
+                PokeMapBadge(
+                  label: step.actorId!,
+                  variant: PokeMapBadgeVariant.narrative,
+                ),
+              if (step.targetId != null)
+                PokeMapBadge(
+                  label: step.targetId!,
+                  variant: PokeMapBadgeVariant.info,
+                ),
+              if (step.assetRef != null)
+                PokeMapBadge(
+                  label: step.assetRef!,
+                  variant: PokeMapBadgeVariant.info,
+                ),
+              if (diagnostics.isNotEmpty)
+                PokeMapBadge(
+                  label: '${diagnostics.length} diagnostic(s)',
+                  variant: _diagnosticVariant(diagnostics.first.severity),
+                ),
+            ],
+          ),
+        ],
+      ),
+    );
+  }
+}
+
 class _EmptyTimelineState extends StatelessWidget {
   const _EmptyTimelineState();
 
@@ -478,12 +624,22 @@ class _EmptyTimelineState extends StatelessWidget {
 }
 
 class _InspectorPlaceholder extends StatelessWidget {
-  const _InspectorPlaceholder({required this.entry});
+  const _InspectorPlaceholder({
+    required this.entry,
+    required this.asset,
+    required this.selectedStep,
+    required this.selectedStepIndex,
+  });
 
   final CinematicsLibraryEntry entry;
+  final CinematicAsset asset;
+  final CinematicTimelineStep? selectedStep;
+  final int? selectedStepIndex;
 
   @override
   Widget build(BuildContext context) {
+    final selected = selectedStep;
+    final selectedIndex = selectedStepIndex;
     return PokeMapPanel(
       key: const ValueKey('cinematic-builder-inspector-placeholder'),
       expandChild: true,
@@ -497,7 +653,14 @@ class _InspectorPlaceholder extends StatelessWidget {
               subtitle: 'Bloc sélectionné',
             ),
             const SizedBox(height: 10),
-            const _EmptySelectionCard(),
+            if (selected == null || selectedIndex == null)
+              const _EmptySelectionCard()
+            else
+              _SelectedStepInspector(
+                asset: asset,
+                step: selected,
+                index: selectedIndex,
+              ),
             const SizedBox(height: 12),
             const _SectionTitle(
               title: 'Métadonnées',
@@ -533,7 +696,10 @@ class _InspectorPlaceholder extends StatelessWidget {
                   : entry.usages.map((usage) => usage.sceneTitle).join(', '),
             ),
             const SizedBox(height: 8),
-            _DiagnosticsSummary(entry: entry),
+            _DiagnosticsSummary(
+              entry: entry,
+              selectedStepId: selected?.id,
+            ),
           ],
         ),
       ),
@@ -541,6 +707,94 @@ class _InspectorPlaceholder extends StatelessWidget {
   }
 }
 
+class _SelectedStepInspector extends StatelessWidget {
+  const _SelectedStepInspector({
+    required this.asset,
+    required this.step,
+    required this.index,
+  });
+
+  final CinematicAsset asset;
+  final CinematicTimelineStep step;
+  final int index;
+
+  @override
+  Widget build(BuildContext context) {
+    final diagnostics = _stepDiagnostics(asset, step);
+    return Column(
+      crossAxisAlignment: CrossAxisAlignment.stretch,
+      children: [
+        _SectionTitle(
+          title: 'Bloc sélectionné',
+          subtitle: step.id,
+        ),
+        const SizedBox(height: 8),
+        _KeyValue(label: 'Titre', value: _stepTitle(step, index)),
+        _KeyValue(label: 'Id', value: step.id),
+        _KeyValue(label: 'Index', value: '${index + 1}'),
+        _KeyValue(label: 'Kind', value: step.kind.name),
+        _KeyValue(label: 'Durée', value: _stepDurationLabel(step)),
+        _KeyValue(label: 'Actor', value: step.actorId ?? 'Aucun acteur'),
+        _KeyValue(label: 'Cible', value: step.targetId ?? 'Aucune cible'),
+        _KeyValue(
+          label: 'Dialogue',
+          value: step.dialogueText ?? 'Aucun texte cinematic',
+        ),
+        _KeyValue(label: 'Asset', value: step.assetRef ?? 'Aucun assetRef'),
+        _KeyValue(label: 'Metadata', value: _metadataLabel(step.metadata)),
+        const _KeyValue(
+          label: 'Preview',
+          value: 'Preview réelle à venir.',
+        ),
+        const _KeyValue(
+          label: 'Statut runtime',
+          value: 'Lecture read-only dans ce lot.',
+        ),
+        const SizedBox(height: 8),
+        _StepDiagnosticsSummary(diagnostics: diagnostics),
+      ],
+    );
+  }
+}
+
+class _StepDiagnosticsSummary extends StatelessWidget {
+  const _StepDiagnosticsSummary({required this.diagnostics});
+
+  final List<CinematicDiagnostic> diagnostics;
+
+  @override
+  Widget build(BuildContext context) {
+    if (diagnostics.isEmpty) {
+      return const PokeMapBadge(
+        label: 'Bloc OK',
+        variant: PokeMapBadgeVariant.success,
+      );
+    }
+    return Column(
+      crossAxisAlignment: CrossAxisAlignment.stretch,
+      children: [
+        const _SectionTitle(
+          title: 'Diagnostics',
+          subtitle: 'Contexte du bloc',
+        ),
+        const SizedBox(height: 8),
+        for (final diagnostic in diagnostics) ...[
+          PokeMapBadge(
+            label: _diagnosticSeverityLabel(diagnostic.severity),
+            variant: _diagnosticVariant(diagnostic.severity),
+          ),
+          const SizedBox(height: 6),
+          _KeyValue(label: 'Code', value: diagnostic.code.name),
+          _MutedText(diagnostic.message),
+          const SizedBox(height: 4),
+          const _MutedText('Aucune action de correction dans ce lot.'),
+          const SizedBox(height: 8),
+        ],
+      ],
+    );
+  }
+}
+
 class _EmptySelectionCard extends StatelessWidget {
   const _EmptySelectionCard();
 
@@ -553,6 +807,8 @@ class _EmptySelectionCard extends StatelessWidget {
           _StrongText('Aucun bloc sélectionné'),
           SizedBox(height: 4),
           _MutedText('Sélection de bloc à venir'),
+          SizedBox(height: 4),
+          _MutedText('Sélectionnez un bloc existant dans le déroulé.'),
         ],
       ),
     );
@@ -560,13 +816,20 @@ class _EmptySelectionCard extends StatelessWidget {
 }
 
 class _DiagnosticsSummary extends StatelessWidget {
-  const _DiagnosticsSummary({required this.entry});
+  const _DiagnosticsSummary({
+    required this.entry,
+    required this.selectedStepId,
+  });
 
   final CinematicsLibraryEntry entry;
+  final String? selectedStepId;
 
   @override
   Widget build(BuildContext context) {
-    if (entry.diagnostics.isEmpty) {
+    final diagnostics = entry.diagnostics
+        .where((diagnostic) => diagnostic.sourceId != selectedStepId)
+        .toList(growable: false);
+    if (diagnostics.isEmpty) {
       return const PokeMapBadge(
         label: 'Aucun diagnostic',
         variant: PokeMapBadgeVariant.success,
@@ -575,9 +838,9 @@ class _DiagnosticsSummary extends StatelessWidget {
     return Column(
       crossAxisAlignment: CrossAxisAlignment.stretch,
       children: [
-        for (final diagnostic in entry.diagnostics) ...[
+        for (final diagnostic in diagnostics) ...[
           PokeMapBadge(
-            label: diagnostic.code,
+            label: _libraryDiagnosticSeverityLabel(diagnostic.severity),
             variant: switch (diagnostic.severity) {
               CinematicsLibraryDiagnosticSeverity.error =>
                 PokeMapBadgeVariant.error,
@@ -588,6 +851,7 @@ class _DiagnosticsSummary extends StatelessWidget {
             },
           ),
           const SizedBox(height: 6),
+          _KeyValue(label: 'Code', value: diagnostic.code),
           _MutedText(diagnostic.message),
           const SizedBox(height: 8),
         ],
@@ -767,3 +1031,80 @@ String _durationLabel(CinematicTimelineSummary timeline) {
   final duration = timeline.estimatedDurationMs;
   return duration == null ? 'Durée non calculable' : '$duration ms estimé(s)';
 }
+
+bool _hasStep(CinematicAsset asset, String? stepId) {
+  if (stepId == null) {
+    return true;
+  }
+  return asset.timeline.steps.any((step) => step.id == stepId);
+}
+
+CinematicTimelineStep? _selectedStep(CinematicAsset asset, String? stepId) {
+  if (stepId == null) {
+    return null;
+  }
+  for (final step in asset.timeline.steps) {
+    if (step.id == stepId) {
+      return step;
+    }
+  }
+  return null;
+}
+
+String _stepTitle(CinematicTimelineStep step, int index) {
+  final label = step.label;
+  if (label != null && label.trim().isNotEmpty) {
+    return label;
+  }
+  return 'Step ${index + 1}';
+}
+
+String _stepDurationLabel(CinematicTimelineStep step) {
+  final duration = step.durationMs;
+  return duration == null ? 'Durée non renseignée' : '$duration ms';
+}
+
+String _metadataLabel(Map<String, String> metadata) {
+  if (metadata.isEmpty) {
+    return 'Aucune metadata';
+  }
+  final entries = metadata.entries.toList()
+    ..sort((a, b) => a.key.compareTo(b.key));
+  return entries.map((entry) => '${entry.key} = ${entry.value}').join(', ');
+}
+
+List<CinematicDiagnostic> _stepDiagnostics(
+  CinematicAsset asset,
+  CinematicTimelineStep step,
+) {
+  return diagnoseCinematicAsset(asset)
+      .diagnostics
+      .where((diagnostic) => diagnostic.stepId == step.id)
+      .toList(growable: false);
+}
+
+PokeMapBadgeVariant _diagnosticVariant(CinematicDiagnosticSeverity severity) {
+  return switch (severity) {
+    CinematicDiagnosticSeverity.error => PokeMapBadgeVariant.error,
+    CinematicDiagnosticSeverity.warning => PokeMapBadgeVariant.warning,
+    CinematicDiagnosticSeverity.info => PokeMapBadgeVariant.info,
+  };
+}
+
+String _diagnosticSeverityLabel(CinematicDiagnosticSeverity severity) {
+  return switch (severity) {
+    CinematicDiagnosticSeverity.error => 'Erreur',
+    CinematicDiagnosticSeverity.warning => 'Attention',
+    CinematicDiagnosticSeverity.info => 'Info',
+  };
+}
+
+String _libraryDiagnosticSeverityLabel(
+  CinematicsLibraryDiagnosticSeverity severity,
+) {
+  return switch (severity) {
+    CinematicsLibraryDiagnosticSeverity.error => 'Erreur',
+    CinematicsLibraryDiagnosticSeverity.warning => 'Attention',
+    CinematicsLibraryDiagnosticSeverity.info => 'Info',
+  };
+}
```

## 9. Hunks complets — cinematics_library_workspace.dart

$ git show --format= --patch HEAD -- packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
(exit 0)

```diff
diff --git a/packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart b/packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
index c89efd0a..9d53534f 100644
--- a/packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
+++ b/packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
@@ -81,10 +81,15 @@ class _CinematicsLibraryWorkspaceState
     _syncMetadataEditor(selectedEntry);
     final builderEntry =
         _builderEntryId == null ? null : readModel.entryById(_builderEntryId!);
+    final builderAsset = _builderEntryId == null
+        ? null
+        : findCinematicById(widget.project, _builderEntryId!);
     if (builderEntry != null &&
-        builderEntry.kind == CinematicsLibraryEntryKind.canonical) {
+        builderEntry.kind == CinematicsLibraryEntryKind.canonical &&
+        builderAsset != null) {
       return CinematicBuilderWorkspace(
         entry: builderEntry,
+        asset: builderAsset,
         onBackToLibrary: () {
           setState(() => _builderEntryId = null);
         },
```

## 10. Hunks complets — cinematic_builder_workspace_test.dart

$ git show --format= --patch HEAD -- packages/map_editor/test/cinematic_builder_workspace_test.dart
(exit 0)

```diff
diff --git a/packages/map_editor/test/cinematic_builder_workspace_test.dart b/packages/map_editor/test/cinematic_builder_workspace_test.dart
index 534e9be1..36a76c08 100644
--- a/packages/map_editor/test/cinematic_builder_workspace_test.dart
+++ b/packages/map_editor/test/cinematic_builder_workspace_test.dart
@@ -1,5 +1,6 @@
 import 'dart:io';
 
+import 'package:flutter/cupertino.dart';
 import 'package:flutter/material.dart';
 import 'package:flutter/services.dart';
 import 'package:flutter_test/flutter_test.dart';
@@ -14,7 +15,11 @@ void main() {
     _setLargeSurface(tester);
     final project = _project();
     final before = project.toJson();
-    await _pumpBuilder(tester, _entry(project, 'cinematic_intro'));
+    await _pumpBuilder(
+      tester,
+      _entry(project, 'cinematic_intro'),
+      asset: _asset(project, 'cinematic_intro'),
+    );
 
     expect(
       find.byKey(const ValueKey('cinematic-builder-workspace')),
@@ -62,6 +67,121 @@ void main() {
     expect(project.toJson(), before);
   });
 
+  testWidgets('lists timeline steps in order with read-only details',
+      (tester) async {
+    _setLargeSurface(tester);
+    final project = _project(cinematics: [_richCinematic()]);
+    final before = project.toJson();
+    await _pumpBuilder(
+      tester,
+      _entry(project, 'cinematic_rich'),
+      asset: _asset(project, 'cinematic_rich'),
+    );
+
+    expect(find.text('Déroulé read-only'), findsOneWidget);
+    expect(find.text('1'), findsOneWidget);
+    expect(find.text('Camera to door'), findsWidgets);
+    expect(find.text('camera'), findsWidgets);
+    expect(find.text('400 ms'), findsWidgets);
+    expect(find.text('target_camera_focus'), findsWidgets);
+    expect(find.text('2'), findsOneWidget);
+    expect(find.text('Professor line'), findsWidgets);
+    expect(find.text('dialogueLine'), findsWidgets);
+    expect(find.text('actor_professor'), findsWidgets);
+    expect(find.text('3'), findsOneWidget);
+    expect(find.text('Door chime'), findsWidgets);
+    expect(find.text('sound'), findsWidgets);
+    expect(find.text('door_chime'), findsWidgets);
+
+    expect(find.text('Ajouter un bloc'), findsNothing);
+    expect(find.text('Supprimer le bloc'), findsNothing);
+    expect(find.byType(CupertinoTextField), findsNothing);
+    expect(project.toJson(), before);
+  });
+
+  testWidgets('selects a step locally and updates read-only inspector',
+      (tester) async {
+    _setLargeSurface(tester);
+    final project = _project(cinematics: [_richCinematic()]);
+    final before = project.toJson();
+    await _pumpBuilder(
+      tester,
+      _entry(project, 'cinematic_rich'),
+      asset: _asset(project, 'cinematic_rich'),
+    );
+
+    expect(find.text('Aucun bloc sélectionné'), findsOneWidget);
+    await tester.ensureVisible(
+      find.byKey(const ValueKey('cinematic-builder-step-card-step_dialogue')),
+    );
+    await tester.tap(
+      find.byKey(const ValueKey('cinematic-builder-step-card-step_dialogue')),
+    );
+    await tester.pumpAndSettle();
+
+    final selectedDialogueCard = tester.widget<PokeMapCard>(
+      find.byKey(const ValueKey('cinematic-builder-step-card-step_dialogue')),
+    );
+    expect(selectedDialogueCard.selected, isTrue);
+    expect(find.text('Bloc sélectionné'), findsWidgets);
+    expect(find.text('step_dialogue'), findsWidgets);
+    expect(find.text('Index'), findsWidgets);
+    expect(find.text('2'), findsWidgets);
+    expect(find.text('Kind'), findsWidgets);
+    expect(find.text('dialogueLine'), findsWidgets);
+    expect(find.text('Dialogue'), findsWidgets);
+    expect(find.text('Labo sécurisé.'), findsOneWidget);
+
+    await tester.ensureVisible(
+      find.byKey(const ValueKey('cinematic-builder-step-card-step_sound')),
+    );
+    await tester.tap(
+      find.byKey(const ValueKey('cinematic-builder-step-card-step_sound')),
+    );
+    await tester.pumpAndSettle();
+
+    final selectedSoundCard = tester.widget<PokeMapCard>(
+      find.byKey(const ValueKey('cinematic-builder-step-card-step_sound')),
+    );
+    expect(selectedSoundCard.selected, isTrue);
+    expect(find.text('step_sound'), findsWidgets);
+    expect(find.text('Asset'), findsWidgets);
+    expect(find.text('door_chime'), findsWidgets);
+    expect(find.text('volume = 0.8'), findsOneWidget);
+    expect(project.toJson(), before);
+  });
+
+  testWidgets('shows step diagnostics without enabling timeline changes',
+      (tester) async {
+    _setLargeSurface(tester);
+    final project = _project(cinematics: [_diagnosticCinematic()]);
+    final before = project.toJson();
+    await _pumpBuilder(
+      tester,
+      _entry(project, 'cinematic_diagnostic'),
+      asset: _asset(project, 'cinematic_diagnostic'),
+    );
+
+    await tester.ensureVisible(
+      find.byKey(const ValueKey('cinematic-builder-step-card-step_bad')),
+    );
+    await tester.tap(
+      find.byKey(const ValueKey('cinematic-builder-step-card-step_bad')),
+    );
+    await tester.pumpAndSettle();
+
+    expect(find.text('Step 1'), findsWidgets);
+    expect(find.text('cinematicInvalidStepDuration'), findsWidgets);
+    expect(
+      find.text('Une durée de step cinematic ne peut pas être négative.'),
+      findsOneWidget,
+    );
+    expect(find.text('Aucune action de correction dans ce lot.'), findsWidgets);
+    expect(find.text('Ajouter un bloc'), findsNothing);
+    expect(find.text('Sauvegarder'), findsWidgets);
+    expect(project.toJson(), before);
+  });
+
   testWidgets('shows empty timeline state without authoring controls',
       (tester) async {
     _setLargeSurface(tester);
@@ -75,7 +195,11 @@ void main() {
       ],
       includeBridge: false,
     );
-    await _pumpBuilder(tester, _entry(project, 'cinematic_empty'));
+    await _pumpBuilder(
+      tester,
+      _entry(project, 'cinematic_empty'),
+      asset: _asset(project, 'cinematic_empty'),
+    );
 
     expect(find.text('Empty cinematic'), findsWidgets);
     expect(find.text('Timeline vide'), findsWidgets);
@@ -94,6 +218,7 @@ void main() {
     await _pumpBuilder(
       tester,
       _entry(_project(), 'cinematic_intro'),
+      asset: _asset(_project(), 'cinematic_intro'),
       onBackToLibrary: () => returned = true,
     );
 
@@ -105,21 +230,33 @@ void main() {
     expect(returned, isTrue);
   });
 
-  testWidgets('captures V1-42 builder shell screenshot when requested',
+  testWidgets('captures V1-43 builder timeline screenshot when requested',
       (tester) async {
     if (!const bool.fromEnvironment(
-      'NS_SCENES_V1_42_CAPTURE_CINEMATIC_BUILDER',
+      'NS_SCENES_V1_43_CAPTURE_CINEMATIC_BUILDER_TIMELINE',
     )) {
       return;
     }
 
     _setLargeSurface(tester);
     await _loadScreenshotFonts();
-    await _pumpBuilder(tester, _entry(_project(), 'cinematic_intro'));
+    final project = _project(cinematics: [_richCinematic()]);
+    await _pumpBuilder(
+      tester,
+      _entry(project, 'cinematic_rich'),
+      asset: _asset(project, 'cinematic_rich'),
+    );
+    await tester.ensureVisible(
+      find.byKey(const ValueKey('cinematic-builder-step-card-step_dialogue')),
+    );
+    await tester.tap(
+      find.byKey(const ValueKey('cinematic-builder-step-card-step_dialogue')),
+    );
+    await tester.pumpAndSettle();
 
     final screenshotFile = File(
       '../../reports/narrativeStudio/scenes/screenshots/'
-      'ns_scenes_v1_42_cinematic_builder_v0_shell.png',
+      'ns_scenes_v1_43_cinematic_timeline_read_only_step_inspector_v0.png',
     );
     screenshotFile.parent.createSync(recursive: true);
     await expectLater(
@@ -134,6 +271,7 @@ void main() {
 Future<void> _pumpBuilder(
   WidgetTester tester,
   CinematicsLibraryEntry entry, {
+  required CinematicAsset asset,
   VoidCallback? onBackToLibrary,
 }) async {
   await tester.pumpWidget(
@@ -146,6 +284,7 @@ Future<void> _pumpBuilder(
             height: 860,
             child: CinematicBuilderWorkspace(
               entry: entry,
+              asset: asset,
               onBackToLibrary: onBackToLibrary ?? () {},
             ),
           ),
@@ -156,6 +295,72 @@ Future<void> _pumpBuilder(
   await tester.pumpAndSettle();
 }
 
+CinematicAsset _asset(ProjectManifest project, String id) {
+  final asset = findCinematicById(project, id);
+  if (asset == null) {
+    throw StateError('Missing cinematic asset $id');
+  }
+  return asset;
+}
+
+CinematicAsset _richCinematic() {
+  return CinematicAsset(
+    id: 'cinematic_rich',
+    title: 'Rich cinematic',
+    description: 'Readable step details.',
+    mapId: 'map_lab',
+    requiredActors: [
+      CinematicActorRef(
+        actorId: 'actor_professor',
+        label: 'Professor',
+      ),
+    ],
+    timeline: CinematicTimeline(
+      steps: [
+        CinematicTimelineStep(
+          id: 'step_camera',
+          kind: CinematicTimelineStepKind.camera,
+          label: 'Camera to door',
+          durationMs: 400,
+          targetId: 'target_camera_focus',
+        ),
+        CinematicTimelineStep(
+          id: 'step_dialogue',
+          kind: CinematicTimelineStepKind.dialogueLine,
+          label: 'Professor line',
+          durationMs: 1200,
+          actorId: 'actor_professor',
+          dialogueText: 'Labo sécurisé.',
+        ),
+        CinematicTimelineStep(
+          id: 'step_sound',
+          kind: CinematicTimelineStepKind.sound,
+          label: 'Door chime',
+          durationMs: 300,
+          assetRef: 'door_chime',
+          metadata: const {'volume': '0.8'},
+        ),
+      ],
+    ),
+  );
+}
+
+CinematicAsset _diagnosticCinematic() {
+  return CinematicAsset(
+    id: 'cinematic_diagnostic',
+    title: 'Diagnostic cinematic',
+    timeline: CinematicTimeline(
+      steps: [
+        CinematicTimelineStep(
+          id: 'step_bad',
+          kind: CinematicTimelineStepKind.wait,
+          durationMs: -5,
+        ),
+      ],
+    ),
+  );
+}
+
 CinematicsLibraryEntry _entry(ProjectManifest project, String id) {
   final entry = buildCinematicsLibraryReadModel(project).entryById(id);
   if (entry == null) {
```

## 11. Hunks complets — road_map_scenes.md

$ git show --format= --patch HEAD -- reports/narrativeStudio/scenes/road_map_scenes.md
(exit 0)

```diff
diff --git a/reports/narrativeStudio/scenes/road_map_scenes.md b/reports/narrativeStudio/scenes/road_map_scenes.md
index 25bfb995..9cd7e089 100644
--- a/reports/narrativeStudio/scenes/road_map_scenes.md
+++ b/reports/narrativeStudio/scenes/road_map_scenes.md
@@ -97,16 +97,17 @@ Ces briques sont utiles, mais elles ne constituent pas encore une Scene V1 propr
 | NS-SCENES-V1-40 — Cinematic Runtime Adapter V0 | DONE | Runtime Scene V1 : `playCinematic(cinematicId)` resout un `CinematicAsset` canonique, passe par un adapter awaitable/player V0, attend la completion reelle, retourne `completed`, preserve les bridges legacy explicites et bloque les refs inconnues sans commit partiel. |
 | NS-SCENES-V1-41 — Cinematic Builder V0 Scope / Runtime Playback Contract | DONE | Lot documentaire : contrat strict du futur Builder V0 comme assembleur no-code de sequences moteur simples, lineaires et sandboxees, plus contrat Runtime Playback V0/V1 borne, sans Builder code, sans timeline editor, sans playback visuel et sans effet gameplay depuis Cinematic. |
 | NS-SCENES-V1-42 — Cinematic Builder V0 Shell | DONE | Shell editor read-only ouvert depuis la Cinematics Library pour les `CinematicAsset` canoniques : header, palette verrouillee, apercu sandbox, deroule et inspecteur placeholders, bridges legacy exclus du Builder canonique, visual gate et tests widget. |
+| NS-SCENES-V1-43 — Cinematic Timeline Read-only / Step Inspector V0 | DONE | Le Builder liste les steps existants dans l'ordre, permet une selection locale non persistante et affiche un inspecteur detaille lecture seule avec diagnostics contextualises, sans mutation de timeline ni changement core/runtime. |
 
 ## Prochain lot recommande
 
-`NS-SCENES-V1-43 — Cinematic Timeline Read-only / Step Inspector V0`
+`NS-SCENES-V1-44 — Cinematic Timeline Authoring Drafts V0`
 
-Raison : V1-42 a pose la coque navigable du Builder sans mutation. Le prochain verrou est de rendre le deroule plus utile en lecture seule : selection locale de bloc, inspecteur detaille du step existant, diagnostics contextualises et aucune operation de creation/suppression/reordonnancement.
+Raison : V1-43 a rendu le deroule inspectable sans mutation. Le prochain verrou est de cadrer des drafts authoring bornes, avec operations pures et preuves de non-regression, avant toute persistance plus ambitieuse.
 
-Ordre apres V1-42 : `NS-SCENES-V1-43 — Cinematic Timeline Read-only / Step Inspector V0`.
+Ordre apres V1-43 : `NS-SCENES-V1-44 — Cinematic Timeline Authoring Drafts V0`.
 
-Ordre corrige : Payload Pickers V0, puis Event -> Scene Trigger Prep, puis Event -> Scene Link V0, puis Scene Runtime Plan V0, puis Diagnostics / Validator Expansion, puis Dialogue/Battle Ports Authoring V0, puis Runtime Executor MVP, puis Evidence & Review Hardening, puis World Rules Map Editor Integration V0, puis Golden Slice Selbrume Scene/Event Prep, puis Event to Scene Runtime Hook V0, puis Scene Consequence Contract Prep, puis Scene Consequence Model V0, puis Scene Consequence Runtime Write V0, puis Battle Runtime Outcome Adapter V0, puis Dialogue Runtime Awaitable Adapter V0, puis Golden Slice Runtime Smoke V0, puis StorylineStep to Scene Link, puis Scene Node Payload Editing V0, puis Scene Node Deletion UX V0, puis Scene Consequence Authoring UI V0, puis Scene V1 Beta Readiness Checkpoint, puis Runtime State Persistence Gate V0, puis World Rules Runtime Projection Hook V0, puis Facts & World Rules Manager UI V0, puis Cinematic V1 Contract / Bridge Decision, puis CinematicAsset Core Model V0, puis Cinematics Library V0, puis Cinematic Scene Builder Picker V0, puis Cinematic Runtime Adapter V0, puis Cinematic Builder V0 Scope / Runtime Playback Contract, puis Cinematic Builder V0 Shell.
+Ordre corrige : Payload Pickers V0, puis Event -> Scene Trigger Prep, puis Event -> Scene Link V0, puis Scene Runtime Plan V0, puis Diagnostics / Validator Expansion, puis Dialogue/Battle Ports Authoring V0, puis Runtime Executor MVP, puis Evidence & Review Hardening, puis World Rules Map Editor Integration V0, puis Golden Slice Scene/Event Prep, puis Event to Scene Runtime Hook V0, puis Scene Consequence Contract Prep, puis Scene Consequence Model V0, puis Scene Consequence Runtime Write V0, puis Battle Runtime Outcome Adapter V0, puis Dialogue Runtime Awaitable Adapter V0, puis Golden Slice Runtime Smoke V0, puis StorylineStep to Scene Link, puis Scene Node Payload Editing V0, puis Scene Node Deletion UX V0, puis Scene Consequence Authoring UI V0, puis Scene V1 Beta Readiness Checkpoint, puis Runtime State Persistence Gate V0, puis World Rules Runtime Projection Hook V0, puis Facts & World Rules Manager UI V0, puis Cinematic V1 Contract / Bridge Decision, puis CinematicAsset Core Model V0, puis Cinematics Library V0, puis Cinematic Scene Builder Picker V0, puis Cinematic Runtime Adapter V0, puis Cinematic Builder V0 Scope / Runtime Playback Contract, puis Cinematic Builder V0 Shell, puis Cinematic Timeline Read-only / Step Inspector V0.
 
 Note : l'overview n'affiche plus `Facts — necessite un modele`; Facts et Regles du monde pointent maintenant vers des workspaces actifs.
 
@@ -268,6 +269,20 @@ Limites : aucune edition de timeline, aucune creation/suppression/reorganisation
 
 Prochain lot exact : `NS-SCENES-V1-43 — Cinematic Timeline Read-only / Step Inspector V0`.
 
+## Mise a jour V1-43
+
+Statut : `NS-SCENES-V1-43 — Cinematic Timeline Read-only / Step Inspector V0` est DONE.
+
+Decision : le Builder consomme le `CinematicAsset` canonique complet depuis la Library pour afficher les steps reels, sans enrichir le read model core. La selection de step reste locale au widget, non persistante, et se remet a zero si la cinematique change ou si le step selectionne n'existe plus.
+
+Scope realise : timeline read-only ordonnee avec index, titre fallback, kind, duree, acteur, cible, assetRef et badge diagnostic ; inspecteur de bloc selectionne avec id, index, kind, duree, actorId, targetId, texte dialogue, asset, metadata, statut preview/runtime lecture seule et diagnostics contextualises ; preview sandbox inchangée avec rappel du bloc selectionne ; palette toujours verrouillee.
+
+Limites : aucune creation de blocs, aucune suppression de blocs, aucun changement d'ordre, aucune sauvegarde de deroule, aucun vrai player visuel, aucune mutation de `ProjectManifest`, aucun changement `map_core`, aucun package runtime/gameplay/battle/examples modifie et aucune migration legacy.
+
+Preuve : tests widget Builder et Library verts, analyse ciblee sans issue, visual gate `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_43_cinematic_timeline_read_only_step_inspector_v0.png`.
+
+Prochain lot exact : `NS-SCENES-V1-44 — Cinematic Timeline Authoring Drafts V0`.
+
 ## Mise a jour V1-30-bis
 
 Statut : `NS-SCENES-V1-30-bis — Scene Node Deletion UX V0` est DONE.
```

## 12. Hunks complets — road_map_scene_builder_authoring.md

$ git show --format= --patch HEAD -- reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
(exit 0)

```diff
diff --git a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
index 9e2fcc5b..54c5391c 100644
--- a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
+++ b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
@@ -9,7 +9,7 @@ Le runtime reste indispensable, mais le prochain blocage produit est plus basiqu
 ## Prochain lot exact recommande
 
 ```text
-NS-SCENES-V1-43 — Cinematic Timeline Read-only / Step Inspector V0
+NS-SCENES-V1-44 — Cinematic Timeline Authoring Drafts V0
 ```
 
 ## Principes
@@ -76,6 +76,7 @@ NS-SCENES-V1-43 — Cinematic Timeline Read-only / Step Inspector V0
 | NS-SCENES-V1-40 | Cinematic Runtime Adapter V0 | runtime / integration | Remplacer l'ack cinematic bridge par un adapter awaitable qui resout un `CinematicAsset` canonique, attend une completion reelle et retourne `completed`. | Pas de Builder V2, pas de timeline editor UI, pas de migration ScenarioAsset, pas de playback visuel complet, pas d'effets gameplay depuis cinematic. | adapter cinematic runtime, result/request/player V0, wiring PlayableMapGame, tests hook no partial writes, rapport. | DONE : canonical awaitable, bridge legacy explicite, unknown failed, consequences post-cinematic commit apres completion, tests/analyze. | Continuer a ack immediatement ; traiter scenarioBridge comme canonical ; laisser une cinematic ecrire le monde. | DONE : pont runtime propre Scene -> CinematicAsset -> completed. | V1-39. |
 | NS-SCENES-V1-41 | Cinematic Builder V0 Scope / Runtime Playback Contract | doc / architecture-review | Cadrer le futur Builder V0 et le futur contrat Runtime Playback avant de coder l'UI, la timeline, les blocs authorables ou le player visuel. | Pas de code Dart, pas de widget, pas de timeline editor, pas de playback visuel, pas de migration ScenarioAsset, pas d'effet gameplay cinematic. | rapport V1-41, roadmaps. | DONE : rapport contractuel, capability matrix, taxonomie blocs, frontieres anti-scope, `git diff --check`. | Coder le Builder trop tot ; refaire ScenarioAsset ; ouvrir branches/failures authorables ; laisser Cinematic ecrire le monde. | DONE : Builder V0 = assembleur lineaire sandboxe ; Runtime Playback V0/V1 = lecture bornee sans gameplay effect ; prochain lot shell seulement. | V1-40. |
 | NS-SCENES-V1-42 | Cinematic Builder V0 Shell | editor / ui-shell | Ouvrir un shell Builder depuis la Cinematics Library pour un `CinematicAsset` canonique, avec zones read-only et navigation retour. | Pas de timeline editor, pas de mutation `ProjectManifest`, pas de preview runtime, pas de migration bridge, pas de modele core. | `cinematic_builder_workspace.dart`, `cinematics_library_workspace.dart`, tests widget, rapport, screenshot. | DONE : Library -> Builder -> retour, bridge legacy exclu, palette/preview/deroule/inspecteur visibles, boutons inactifs, visual gate, analyze cible. | Confondre shell et authoring ; promouvoir bridge legacy ; laisser croire que la preview est jouable. | DONE : shell V0 lisible, strictement read-only et canonique-only. | V1-41. |
+| NS-SCENES-V1-43 | Cinematic Timeline Read-only / Step Inspector V0 | editor / ui-readonly | Rendre le deroule du Builder inspectable : steps reels ordonnes, selection locale, inspecteur detaille lecture seule et diagnostics contextualises. | Pas de mutation de timeline, pas de modele core, pas de preview runtime, pas de migration bridge. | `cinematic_builder_workspace.dart`, `cinematics_library_workspace.dart`, tests widget, rapport, screenshot. | DONE : liste steps, selection locale, inspecteur step, diagnostics, non-mutation, visual gate, analyze cible. | Confondre inspection et authoring ; dupliquer le read model core ; creer une selection persistante inutile. | DONE : Builder inspectable sans changer `ProjectManifest`, core ou runtime. | V1-42. |
 
 ## Options comparees
 
@@ -682,6 +683,18 @@ Limites : pas de creation de blocs, pas de suppression de blocs, pas de reorgani
 
 Prochain lot exact : `NS-SCENES-V1-43 — Cinematic Timeline Read-only / Step Inspector V0`.
 
+## Mise a jour V1-43
+
+Statut : `NS-SCENES-V1-43 — Cinematic Timeline Read-only / Step Inspector V0` est DONE.
+
+Decision : le Builder V0 reste read-only mais devient inspectable. La Library passe le `CinematicAsset` canonique complet au Builder ; aucun enrichissement `map_core` n'etait necessaire. La selection est locale dans `CinematicBuilderWorkspace` et ne touche jamais au manifest.
+
+Scope realise : cartes de steps ordonnees, selection visuelle, inspecteur de bloc detaille, diagnostics du step selectionne, preview sandbox avec rappel du bloc, palette verrouillee, tests de non-mutation et screenshot V1-43.
+
+Limites : pas de creation de blocs, pas de suppression de blocs, pas de changement d'ordre, pas de sauvegarde de deroule, pas de vrai playback visuel, pas de runtime, pas de migration legacy et pas de modele core modifie.
+
+Prochain lot exact : `NS-SCENES-V1-44 — Cinematic Timeline Authoring Drafts V0`.
+
 ## Selbrume golden slice
 
 Avant le golden slice, il faut au minimum :
```

## 13. Tests relancés

$ cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
(exit 0)

```text

00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart                                                                                   
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart                                                                                   
00:01 +0: shows populated read-only cinematic builder shell                                                                                                                                            
00:01 +1: shows populated read-only cinematic builder shell                                                                                                                                            
00:01 +1: lists timeline steps in order with read-only details                                                                                                                                         
00:01 +2: lists timeline steps in order with read-only details                                                                                                                                         
00:01 +2: selects a step locally and updates read-only inspector                                                                                                                                       
00:02 +2: selects a step locally and updates read-only inspector                                                                                                                                       
00:02 +3: selects a step locally and updates read-only inspector                                                                                                                                       
00:02 +3: shows step diagnostics without enabling timeline changes                                                                                                                                     
00:02 +4: shows step diagnostics without enabling timeline changes                                                                                                                                     
00:02 +4: shows empty timeline state without authoring controls                                                                                                                                        
00:02 +5: shows empty timeline state without authoring controls                                                                                                                                        
00:02 +5: calls back to library from builder header                                                                                                                                                    
00:02 +6: calls back to library from builder header                                                                                                                                                    
00:02 +6: captures V1-43 builder timeline screenshot when requested                                                                                                                                    
00:02 +7: captures V1-43 builder timeline screenshot when requested                                                                                                                                    
00:02 +7: All tests passed!                                                                                                                                                                            
```

$ cd packages/map_editor && flutter test --reporter=compact test/cinematics_library_workspace_test.dart
(exit 0)

```text

00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematics_library_workspace_test.dart                                                                                  
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematics_library_workspace_test.dart                                                                                  
00:01 +0: shows empty state and creates a cinematic shell                                                                                                                                              
00:01 +1: shows empty state and creates a cinematic shell                                                                                                                                              
00:01 +1: lists canonical and bridge entries with read-only details                                                                                                                                    
00:02 +1: lists canonical and bridge entries with read-only details                                                                                                                                    
00:02 +2: lists canonical and bridge entries with read-only details                                                                                                                                    
00:02 +2: shows timeline summary and scene usages for canonical entry                                                                                                                                  
00:02 +3: shows timeline summary and scene usages for canonical entry                                                                                                                                  
00:02 +3: opens builder shell for canonical cinematic and returns                                                                                                                                      
00:02 +4: opens builder shell for canonical cinematic and returns                                                                                                                                      
00:02 +4: keeps legacy bridge out of canonical builder shell                                                                                                                                           
00:02 +5: keeps legacy bridge out of canonical builder shell                                                                                                                                           
00:02 +5: edits metadata and deletes only unused canonicals                                                                                                                                            
00:02 +6: edits metadata and deletes only unused canonicals                                                                                                                                            
00:02 +6: captures V1-38 Cinematics Library screenshot when requested                                                                                                                                  
00:02 +7: captures V1-38 Cinematics Library screenshot when requested                                                                                                                                  
00:02 +7: All tests passed!                                                                                                                                                                            
```

$ cd packages/map_editor && flutter test --update-goldens --dart-define=NS_SCENES_V1_43_CAPTURE_CINEMATIC_BUILDER_TIMELINE=true --reporter=compact test/cinematic_builder_workspace_test.dart
(exit 0)

```text

00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart                                                                                   
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart                                                                                   
00:01 +0: shows populated read-only cinematic builder shell                                                                                                                                            
00:01 +1: shows populated read-only cinematic builder shell                                                                                                                                            
00:01 +1: lists timeline steps in order with read-only details                                                                                                                                         
00:01 +2: lists timeline steps in order with read-only details                                                                                                                                         
00:01 +2: selects a step locally and updates read-only inspector                                                                                                                                       
00:02 +2: selects a step locally and updates read-only inspector                                                                                                                                       
00:02 +3: selects a step locally and updates read-only inspector                                                                                                                                       
00:02 +3: shows step diagnostics without enabling timeline changes                                                                                                                                     
00:02 +4: shows step diagnostics without enabling timeline changes                                                                                                                                     
00:02 +4: shows empty timeline state without authoring controls                                                                                                                                        
00:02 +5: shows empty timeline state without authoring controls                                                                                                                                        
00:02 +5: calls back to library from builder header                                                                                                                                                    
00:02 +6: calls back to library from builder header                                                                                                                                                    
00:02 +6: captures V1-43 builder timeline screenshot when requested                                                                                                                                    
00:02 +7: captures V1-43 builder timeline screenshot when requested                                                                                                                                    
00:02 +7: All tests passed!                                                                                                                                                                            
```

## 14. Analyze relancé

$ cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart test/cinematic_builder_workspace_test.dart test/cinematics_library_workspace_test.dart
(exit 0)

```text
Analyzing 4 items...                                            
No issues found! (ran in 1.1s)
```

## 15. Checks anti-scope

$ git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples
(exit 0)

```text
<vide>
```

$ git diff --name-only -- packages/map_core
(exit 0)

```text
<vide>
```

$ rg -n "PlayableMapGame|SceneRuntimeExecutor|SceneEventRuntimeHook|SceneCinematicRuntimeAwaitableAdapter|SceneCinematicRuntimeNoVisualPlayer|playCinematic" packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart || true
(exit 0)

```text
<vide>
```

$ rg -n "add.*Step|remove.*Step|reorder|drag|drop|TimelineEditor|scrubber|keyframe|save.*timeline|copyWith\(.*timeline" packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/test/cinematics_library_workspace_test.dart packages/map_editor/test/cinematic_builder_workspace_test.dart || true
(exit 0)

```text
<vide>
```

$ rg -n "Color\(|Colors\.|0xFF|0xff" packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart || true
(exit 0)

```text
<vide>
```

$ rg -n "selbrume|mael|maël|lysa|port_brisants|bourg_selbrume|phare|brume|marais" packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/test/cinematics_library_workspace_test.dart packages/map_editor/test/cinematic_builder_workspace_test.dart reports/narrativeStudio/scenes/ns_scenes_v1_43_cinematic_timeline_read_only_step_inspector_v0.md || true
(exit 0)

```text
<vide>
```

## 16. Git diff --check final

$ git diff --check
(exit 0)

```text
<vide>
```

## 17. Git diff --stat final

$ git diff --stat
(exit 0)

```text
<vide>
```

## 18. Git diff --name-only final

$ git diff --name-only
(exit 0)

```text
<vide>
```

## 19. Git status final

$ git status --short --untracked-files=all
(exit 0)

```text
?? reports/narrativeStudio/scenes/ns_scenes_v1_43_bis_cinematic_timeline_read_only_step_inspector_evidence_closure.md
```

## 20. Auto-review critique

Le bis a uniquement créé le rapport evidence closure. Les commandes prouvent que le code V1-43 est déjà dans `HEAD`, que le worktree fonctionnel reste propre hors ce rapport non suivi, et que les tests/analyze/checks demandés passent. La seule réserve est documentaire : le rapport est volontairement long, car il reproduit les preuves au lieu de les résumer.

## 21. Verdict de clôture V1-43

V1-43 est clôturable d'un point de vue evidence : tests V1-43 verts, analyze ciblé vert, Visual Gate prouvée, hunks du commit V1-43 reproduits, aucun code modifié par le bis. Le commit V1-43 existe déjà dans `HEAD`; le fichier de bis peut être ajouté séparément comme preuve documentaire.

