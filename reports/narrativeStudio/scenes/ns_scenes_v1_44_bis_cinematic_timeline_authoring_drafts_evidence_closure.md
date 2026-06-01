# NS-SCENES-V1-44-bis — Cinematic Timeline Authoring Drafts Evidence Closure
## 1. Résumé exécutif

Ce bis ne modifie pas la feature. Ce bis ne modifie pas le code. Il complète uniquement l’Evidence Pack de V1-44 avec le contenu intégral du rapport V1-44, les hunks du commit V1-44, les sorties de validation et les checks anti-scope.

## 2. Pourquoi ce bis existe

Le rapport V1-44 résumait les fichiers, les diffs, les tests et les checks. Il ne reproduisait pas assez précisément le contenu complet du rapport, les hunks complets, les sorties exactes et le statut Git final. Ce bis ferme ce trou documentaire sans toucher au Builder, au runtime, à la timeline ou aux fichiers V1-44.

## 3. Gate 0

```bash
pwd
```

Exit code: 0

```text
/Users/karim/Project/pokemonProject
```

```bash
git branch --show-current
```

Exit code: 0

```text
main
```

```bash
git status --short --untracked-files=all
```

Exit code: 0

```text
<vide>
```

```bash
git diff --stat
```

Exit code: 0

```text
<vide>
```

```bash
git diff --name-only
```

Exit code: 0

```text
<vide>
```

```bash
git log --oneline -n 10
```

Exit code: 0

```text
eb0ea9b6 feat(narrative): add cinematic timeline authoring drafts v0 (NS-SCENES-V1-44)
2805560d feat(narrative): add cinematic timeline read-only step inspector evidence closure (NS-SCENES-V1-43-BIS)
6c3b1074 feat(narrative): add cinematic timeline read-only step inspector v0 (NS-SCENES-V1-43)
e95290ce feat(narrative): add cinematic builder v0 shell evidence closure (NS-SCENES-V1-42-BIS)
c9d44fc8 feat(narrative): add cinematic builder v0 shell (NS-SCENES-V1-42)
38f09efa feat(narrative): add cinematic builder v0 scope and runtime playback contract (NS-SCENES-V1-41)
9e1d45d9 feat(narrative): add cinematic runtime adapter v0 bis evidence closure (NS-SCENES-V1-40)
b39d596f feat(narrative): add cinematic runtime adapter v0 (NS-SCENES-V1-40)
eadb0052 chore(reports): add missing screenshot for V1-15 wire anchor color code
0fe8fa1f feat(narrative): add cinematic scene builder picker v0 (NS-SCENES-V1-39)
```

Interprétation Gate 0 : le lot V1-44 était déjà présent avant le bis et le dépôt était propre. Le bis part donc d’un HEAD contenant `NS-SCENES-V1-44`, sans diff de travail.

## 4. Fichiers V1-44 préexistants avant le bis

- `packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart`
- `packages/map_core/test/cinematic_authoring_operations_test.dart`
- `packages/map_core/test/cinematic_diagnostics_test.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `packages/map_editor/test/cinematics_library_workspace_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_44_cinematic_timeline_authoring_drafts_v0.md`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_44_cinematic_timeline_authoring_drafts_v0.png`

Ces fichiers existent dans le dépôt avant création du rapport bis. Le code V1-44 est donc une base préexistante pour ce bis evidence-only.

## 5. Fichier créé par le bis

- `reports/narrativeStudio/scenes/ns_scenes_v1_44_bis_cinematic_timeline_authoring_drafts_evidence_closure.md`

Aucun autre fichier n’est créé ou modifié par ce bis.

## 6. Contenu complet — rapport V1-44

```md
# NS-SCENES-V1-44 — Cinematic Timeline Authoring Drafts V0

## 1. Resume executif

Le lot est DONE. Le Cinematic Builder V0 sait maintenant ajouter un bloc brouillon neutre dans le deroule d'un `CinematicAsset`, le selectionner, l'inspecter en lecture seule et supprimer uniquement ce brouillon. La mutation passe par des operations pures sur `ProjectManifest.cinematics`, puis par l'etat memoire de l'editeur.

## 2. Gate 0

- Dossier : `/Users/karim/Project/pokemonProject`.
- Branche : `main`.
- Worktree avant lot : propre.
- Strategie : aucun Git write, changements limites a `map_core`, `map_editor` et rapports Scenes.
- Derniers commits observes :
  - `2805560d feat(narrative): add cinematic timeline read-only step inspector evidence closure (NS-SCENES-V1-43-BIS)`
  - `6c3b1074 feat(narrative): add cinematic timeline read-only step inspector v0 (NS-SCENES-V1-43)`
  - `e95290ce feat(narrative): add cinematic builder v0 shell evidence closure (NS-SCENES-V1-42-BIS)`
  - `c9d44fc8 feat(narrative): add cinematic builder v0 shell (NS-SCENES-V1-42)`
  - `38f09efa feat(narrative): add cinematic builder v0 scope and runtime playback contract (NS-SCENES-V1-41)`

## 3. Fichiers lus

- `AGENTS.md`
- `skills/README.md`
- `pokemap_roadmap_mecaniques_fangame.md`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_43_cinematic_timeline_read_only_step_inspector_v0.md`
- `packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart`
- `packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart`
- `packages/map_core/lib/src/models/cinematic_asset.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `packages/map_editor/test/cinematics_library_workspace_test.dart`

## 4. Design Gate

1. Les operations existantes de Cinematic authoring sont dans `cinematic_authoring_operations.dart`; V1-44 les etend sans nouveau package.
2. Le brouillon V0 est un `CinematicTimelineStepKind.marker` avec label `Bloc brouillon`.
3. Le brouillon est identifie par `kind == marker`, `authoring.kind=draft` et `authoring.source=cinematic-builder-v0`.
4. L'ID stable est produit par `_nextDraftStepId` avec base `step_draft`, puis suffixe numerique si besoin.
5. L'ajout insere apres le step selectionne quand il existe, sinon a la fin.
6. Le retrait est limite aux steps reconnus comme brouillons.
7. Les steps inconnus ou non-brouillons sont refuses par `ArgumentError`; l'UI masque aussi le bouton de retrait pour les autres steps.
8. L'editeur applique la mutation memoire via callbacks depuis `NarrativeWorkspaceCanvas`.
9. Le Builder reste canonical-only, car la Library continue d'ouvrir seulement les `CinematicAsset` canoniques.
10. Les bridges legacy restent consultables dans la Library mais n'entrent pas dans ce Builder.
11. La palette metier reste verrouillee.
12. Les seules actions actives sont `Ajouter un brouillon` et, sur brouillon selectionne, `Supprimer ce brouillon`.
13. Aucune gestion riche du deroule n'est ajoutee : pas d'edition de payload, pas de changement d'ordre, pas de vrai bloc moteur.
14. Les tests prouvent la mutation ciblee et la preservation du reste du projet.
15. La capture de preuve est `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_44_cinematic_timeline_authoring_drafts_v0.png`.

## 5. Modele de brouillon

Le brouillon ne contient aucun champ moteur. Il est volontairement neutre :

```text
kind: marker
label: Bloc brouillon
metadata:
  authoring.kind: draft
  authoring.source: cinematic-builder-v0
```

Cette forme permet de l'afficher et de le retirer sans inventer de contrat Camera, Fondu, Attente, Dialogue, FX, Son ou Acteur.

## 6. Operations pures

`addCinematicTimelineDraftStep` retourne `CinematicTimelineDraftStepResult` avec `updatedProject`, `cinematic` et `step`.

`removeCinematicTimelineDraftStep` retourne `CinematicTimelineDraftStepRemovalResult` avec `updatedProject`, `cinematic` et `removedStep`.

`isCinematicTimelineDraftStep` centralise la garde utilisee par les tests, les diagnostics et l'UI.

## 7. Integration editor

`CinematicBuilderWorkspace` recoit deux callbacks :

- `onAddDraftStep`
- `onRemoveDraftStep`

Le widget garde seulement `_selectedStepId`. Apres ajout, il selectionne le brouillon cree. Apres retrait, il remet la selection a `null`.

## 8. Integration Library et Canvas

`CinematicsLibraryWorkspace` relaie les callbacks au Builder. `NarrativeWorkspaceCanvas` applique les operations pures avec `editorNotifier.applyInMemoryProjectManifest`, sans disque et sans sauvegarde implicite.

## 9. Diagnostics

Le test de diagnostics confirme que le marker authoring n'est pas traite comme fuite gameplay. Le brouillon reste un placeholder honnete et ne produit pas de diagnostic runtime invente.

## 10. Tests RED initiaux

Avant implementation, les tests ajoutes echouaient comme attendu.

Core :

```text
Method not found: 'addCinematicTimelineDraftStep'
Method not found: 'isCinematicTimelineDraftStep'
Method not found: 'removeCinematicTimelineDraftStep'
```

Editor :

```text
No named parameter with the name 'onAddDraftStep'
Method not found: 'addCinematicTimelineDraftStep'
Method not found: 'removeCinematicTimelineDraftStep'
```

## 11. Tests core

Commande :

```bash
cd packages/map_core && dart test test/cinematic_authoring_operations_test.dart
```

Resultat :

```text
+12: All tests passed!
```

Commande :

```bash
cd packages/map_core && dart test test/cinematic_diagnostics_test.dart
```

Resultat :

```text
+7: All tests passed!
```

## 12. Tests editor

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
```

Resultat :

```text
+10: All tests passed!
```

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematics_library_workspace_test.dart
```

Resultat :

```text
+8: All tests passed!
```

Note d'execution : un lancement parallele de deux tests Flutter a produit une erreur d'artefact natif manquant avant les assertions. Le relancement isole de `cinematics_library_workspace_test.dart` a passe, ce qui localise l'incident dans la concurrence de build Flutter locale.

## 13. Visual Gate

Commande :

```bash
cd packages/map_editor && flutter test --update-goldens --dart-define=NS_SCENES_V1_44_CAPTURE_CINEMATIC_BUILDER_DRAFTS=true --reporter=compact test/cinematic_builder_workspace_test.dart
```

Resultat :

```text
+10: All tests passed!
```

Capture :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_44_cinematic_timeline_authoring_drafts_v0.png
```

Verification visuelle : Builder ouvert, bouton d'ajout de brouillon, inspecteur sur `step_draft`, bouton de retrait de brouillon, palette verrouillee et preview sandbox.

## 14. Preuve image

```text
-rw-r--r--  1 karim  staff   176K Jun  1 19:33 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_44_cinematic_timeline_authoring_drafts_v0.png
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_44_cinematic_timeline_authoring_drafts_v0.png: PNG image data, 1280 x 860, 8-bit/color RGBA, non-interlaced
a5acab66c15c47aa8df14c22ab1525849e8d7021107cdba1849895e03f95f805  reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_44_cinematic_timeline_authoring_drafts_v0.png
```

## 15. Analyse statique

Commande :

```bash
cd packages/map_core && dart analyze
```

Resultat :

```text
No issues found!
```

Commande :

```bash
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart lib/src/ui/canvas/narrative_workspace_canvas.dart test/cinematic_builder_workspace_test.dart test/cinematics_library_workspace_test.dart
```

Resultat :

```text
Analyzing 5 items...
No issues found! (ran in 2.1s)
```

## 16. Fichiers crees

- `reports/narrativeStudio/scenes/ns_scenes_v1_44_cinematic_timeline_authoring_drafts_v0.md`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_44_cinematic_timeline_authoring_drafts_v0.png`

## 17. Fichiers modifies

- `packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart`
- `packages/map_core/test/cinematic_authoring_operations_test.dart`
- `packages/map_core/test/cinematic_diagnostics_test.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `packages/map_editor/test/cinematics_library_workspace_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

## 18. Roadmaps

- `road_map_scenes.md` ajoute V1-44 en DONE et propose V1-45.
- `road_map_scene_builder_authoring.md` ajoute V1-44 en DONE et propose V1-45.

## 19. Evidence Pack core

- `CinematicTimelineDraftStepResult` capture le projet mis a jour, l'asset remplace et le step cree.
- `CinematicTimelineDraftStepRemovalResult` capture le projet mis a jour, l'asset remplace et le step retire.
- `addCinematicTimelineDraftStep` clone la liste de steps, calcule l'index d'insertion, cree un marker draft, remplace seulement la timeline de l'asset cible et renvoie le step cree.
- `removeCinematicTimelineDraftStep` refuse un id absent, refuse un step non-brouillon, retire seulement l'entree cible et preserve le reste.
- `_copyCinematicWithTimeline` recopie explicitement les champs existants de `CinematicAsset`.
- `_nextDraftStepId` produit `step_draft`, puis `step_draft_2`, `step_draft_3`, etc.

## 20. Evidence Pack tests core

- Ajout apres selection : ordre attendu `step_intro`, `step_draft`, `step_outro`.
- Ajout sans selection : append en fin de deroule.
- ID stable : `step_draft_3` quand `step_draft` et `step_draft_2` existent.
- Retrait : seul le marker draft cible disparait.
- Refus : step inconnu et step non-brouillon lancent `ArgumentError`.
- Diagnostics : le brouillon authoring n'ajoute pas d'erreur gameplay.

## 21. Evidence Pack UI

- Le bouton `cinematic-builder-add-draft-button` appelle le callback avec `cinematicId` et `afterStepId`.
- Le badge `Brouillon` apparait seulement pour un step reconnu comme draft.
- L'inspecteur affiche id, kind, label, metadata, statut et message placeholder.
- Le bouton `cinematic-builder-remove-draft-button` apparait seulement quand le step selectionne est un draft.
- Le retrait remet la selection a l'etat vide.

## 22. Evidence Pack integration

- `CinematicsLibraryWorkspace` expose `onAddTimelineDraft` et `onRemoveTimelineDraft`.
- `NarrativeWorkspaceCanvas` applique les operations pures au manifest memoire.
- Le test Library ajoute un brouillon depuis le Builder puis verifie que le resume Library passe a `3 step(s)`.

## 23. Checks anti-scope finaux

Commandes et resultats :

```text
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples
=> no output

rg -n 'Color\\(|Colors\\.|0xFF|0xff' packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart packages/map_editor/test/cinematic_builder_workspace_test.dart packages/map_editor/test/cinematics_library_workspace_test.dart || true
=> no output
```

Les scans des lignes ajoutees pour references runtime interdites, operations avancees de deroule, blocs gameplay prematures et donnees produit nommees ont aussi rendu `no output`.

## 24. Non-objectifs confirmes

- Pas de vrai bloc metier authorable.
- Pas de player visuel.
- Pas de preview moteur.
- Pas de modification runtime/gameplay/battle/examples.
- Pas de changement schema JSON.
- Pas de build runner.
- Pas de sauvegarde disque.
- Pas d'edition de payload.
- Pas de migration legacy.

## 25. Limites connues

Le brouillon est volontairement un marker neutre. Il aide a tester l'authoring borne et la selection, mais il ne represente pas encore une instruction cinematic executable.

## 26. Auto-review critique

Le helper `_copyCinematicWithTimeline` recopie les champs a la main. C'est acceptable dans ce lot car `CinematicAsset` n'a pas de `copyWith` public, mais un futur modele genere ou une extension dediee reduirait le risque si l'asset gagne beaucoup de champs.

## 27. Risques surveilles

- Eviter que les metadata de draft deviennent une API publique de gameplay.
- Garder la suppression stricte : les vrais steps restent intouchables par cette operation.
- Eviter de brancher un effet runtime tant que les vrais blocs ne sont pas modelises.

## 28. Recommandation prochain lot

Lancer `NS-SCENES-V1-45 — Cinematic Wait/Fade/Camera Basic Blocks V0` avec un sous-ensemble tres borne : un ou deux blocs simples, diagnostics et tests de non-regression, sans effet gameplay.

## 29. Etat final

Statut propose : `NS-SCENES-V1-44 — Cinematic Timeline Authoring Drafts V0` peut etre marque DONE.

`git diff --check` :

```text
no output
```

`git diff --name-only` :

```text
packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart
packages/map_core/test/cinematic_authoring_operations_test.dart
packages/map_core/test/cinematic_diagnostics_test.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
packages/map_editor/test/cinematics_library_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

`git status --short --untracked-files=all` :

```text
 M packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart
 M packages/map_core/test/cinematic_authoring_operations_test.dart
 M packages/map_core/test/cinematic_diagnostics_test.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
 M packages/map_editor/test/cinematic_builder_workspace_test.dart
 M packages/map_editor/test/cinematics_library_workspace_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_44_cinematic_timeline_authoring_drafts_v0.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_44_cinematic_timeline_authoring_drafts_v0.png
```
```

## 7. Preuve de la Visual Gate

```bash
ls -lh reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_44_cinematic_timeline_authoring_drafts_v0.png
```

Exit code: 0

```text
-rw-r--r--  1 karim  staff   176K Jun  1 19:33 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_44_cinematic_timeline_authoring_drafts_v0.png
```

```bash
file reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_44_cinematic_timeline_authoring_drafts_v0.png
```

Exit code: 0

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_44_cinematic_timeline_authoring_drafts_v0.png: PNG image data, 1280 x 860, 8-bit/color RGBA, non-interlaced
```

```bash
shasum -a 256 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_44_cinematic_timeline_authoring_drafts_v0.png
```

Exit code: 0

```text
a5acab66c15c47aa8df14c22ab1525849e8d7021107cdba1849895e03f95f805  reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_44_cinematic_timeline_authoring_drafts_v0.png
```

La Visual Gate n’a pas été relancée avec `--update-goldens` dans ce bis afin de ne pas réécrire la capture. Son artefact V1-44 est prouvé par taille, type PNG et empreinte SHA-256.

## 8. Hunks complets — cinematic_authoring_operations.dart

Commande utilisée : `git show --format= --no-ext-diff HEAD -- packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart`

Exit code: 0

```diff
diff --git a/packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart b/packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart
index 1119dc69..2520a988 100644
--- a/packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart
+++ b/packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart
@@ -22,6 +22,35 @@ final class CinematicAssetRemovalResult {
   final CinematicAsset removedCinematic;
 }
 
+final class CinematicTimelineDraftStepResult {
+  const CinematicTimelineDraftStepResult({
+    required this.updatedProject,
+    required this.cinematic,
+    required this.step,
+  });
+
+  final ProjectManifest updatedProject;
+  final CinematicAsset cinematic;
+  final CinematicTimelineStep step;
+}
+
+final class CinematicTimelineDraftStepRemovalResult {
+  const CinematicTimelineDraftStepRemovalResult({
+    required this.updatedProject,
+    required this.cinematic,
+    required this.removedStep,
+  });
+
+  final ProjectManifest updatedProject;
+  final CinematicAsset cinematic;
+  final CinematicTimelineStep removedStep;
+}
+
+const cinematicTimelineDraftMetadataKindKey = 'authoring.kind';
+const cinematicTimelineDraftMetadataKindValue = 'draft';
+const cinematicTimelineDraftMetadataSourceKey = 'authoring.source';
+const cinematicTimelineDraftMetadataSourceValue = 'cinematic-builder-v0';
+
 CinematicAssetAuthoringResult addCinematicAsset(
   ProjectManifest project,
   CinematicAsset cinematic,
@@ -133,6 +162,103 @@ CinematicAsset? findCinematicById(
   return null;
 }
 
+CinematicTimelineDraftStepResult addCinematicTimelineDraftStep(
+  ProjectManifest project, {
+  required String cinematicId,
+  String? afterStepId,
+}) {
+  final cinematic = _requireCinematic(project, cinematicId);
+  final steps = cinematic.timeline.steps.toList();
+  final trimmedAfterStepId = afterStepId?.trim();
+  var insertIndex = steps.length;
+  if (trimmedAfterStepId != null && trimmedAfterStepId.isNotEmpty) {
+    final selectedIndex =
+        steps.indexWhere((step) => step.id == trimmedAfterStepId);
+    if (selectedIndex == -1) {
+      throw ArgumentError.value(
+        afterStepId,
+        'afterStepId',
+        'Draft insertion references an unknown timeline step.',
+      );
+    }
+    insertIndex = selectedIndex + 1;
+  }
+
+  final draft = CinematicTimelineStep(
+    id: _nextDraftStepId(cinematic),
+    kind: CinematicTimelineStepKind.marker,
+    label: 'Bloc brouillon',
+    metadata: const {
+      cinematicTimelineDraftMetadataKindKey:
+          cinematicTimelineDraftMetadataKindValue,
+      cinematicTimelineDraftMetadataSourceKey:
+          cinematicTimelineDraftMetadataSourceValue,
+    },
+  );
+  steps.insert(insertIndex, draft);
+
+  final updatedCinematic = _copyCinematicWithTimeline(
+    cinematic,
+    CinematicTimeline(steps: steps),
+  );
+  final result = updateCinematicAsset(project, updatedCinematic);
+  return CinematicTimelineDraftStepResult(
+    updatedProject: result.updatedProject,
+    cinematic: result.cinematic,
+    step: draft,
+  );
+}
+
+CinematicTimelineDraftStepRemovalResult removeCinematicTimelineDraftStep(
+  ProjectManifest project, {
+  required String cinematicId,
+  required String stepId,
+}) {
+  final cinematic = _requireCinematic(project, cinematicId);
+  final id = _trimRequired(
+    stepId,
+    'stepId',
+    'Draft removal requires a timeline step id.',
+  );
+  final steps = cinematic.timeline.steps.toList();
+  final index = steps.indexWhere((step) => step.id == id);
+  if (index == -1) {
+    throw ArgumentError.value(
+      stepId,
+      'stepId',
+      'Draft removal references an unknown timeline step.',
+    );
+  }
+  final removedStep = steps[index];
+  if (!isCinematicTimelineDraftStep(removedStep)) {
+    throw ArgumentError.value(
+      stepId,
+      'stepId',
+      'Only authoring draft timeline steps can be removed here.',
+    );
+  }
+  steps.removeAt(index);
+
+  final updatedCinematic = _copyCinematicWithTimeline(
+    cinematic,
+    CinematicTimeline(steps: steps),
+  );
+  final result = updateCinematicAsset(project, updatedCinematic);
+  return CinematicTimelineDraftStepRemovalResult(
+    updatedProject: result.updatedProject,
+    cinematic: result.cinematic,
+    removedStep: removedStep,
+  );
+}
+
+bool isCinematicTimelineDraftStep(CinematicTimelineStep step) {
+  return step.kind == CinematicTimelineStepKind.marker &&
+      step.metadata[cinematicTimelineDraftMetadataKindKey] ==
+          cinematicTimelineDraftMetadataKindValue &&
+      step.metadata[cinematicTimelineDraftMetadataSourceKey] ==
+          cinematicTimelineDraftMetadataSourceValue;
+}
+
 void _validateCinematics(List<CinematicAsset> cinematics) {
   final ids = <String>{};
   for (final cinematic in cinematics) {
@@ -170,6 +296,59 @@ void _throwIfDuplicateId(String id, Iterable<String> existingIds) {
   }
 }
 
+CinematicAsset _requireCinematic(
+  ProjectManifest project,
+  String cinematicId,
+) {
+  final id = _trimRequired(
+    cinematicId,
+    'cinematicId',
+    'Timeline draft authoring requires a cinematic id.',
+  );
+  final cinematic = findCinematicById(project, id);
+  if (cinematic == null) {
+    throw ArgumentError.value(
+      cinematicId,
+      'cinematicId',
+      'Timeline draft authoring references an unknown cinematic.',
+    );
+  }
+  return cinematic;
+}
+
+CinematicAsset _copyCinematicWithTimeline(
+  CinematicAsset cinematic,
+  CinematicTimeline timeline,
+) {
+  return CinematicAsset(
+    id: cinematic.id,
+    title: cinematic.title,
+    description: cinematic.description,
+    storylineId: cinematic.storylineId,
+    chapterId: cinematic.chapterId,
+    mapId: cinematic.mapId,
+    tags: cinematic.tags,
+    requiredActors: cinematic.requiredActors,
+    timeline: timeline,
+    notes: cinematic.notes,
+    metadata: cinematic.metadata,
+    legacyBridge: cinematic.legacyBridge,
+  );
+}
+
+String _nextDraftStepId(CinematicAsset cinematic) {
+  final existingIds = cinematic.timeline.steps.map((step) => step.id).toSet();
+  const base = 'step_draft';
+  if (!existingIds.contains(base)) {
+    return base;
+  }
+  var index = 2;
+  while (existingIds.contains('${base}_$index')) {
+    index++;
+  }
+  return '${base}_$index';
+}
+
 List<String> _sceneIdsReferencingCinematic(
   ProjectManifest project,
   String cinematicId,
```

## 9. Hunks complets — cinematic_authoring_operations_test.dart

Commande utilisée : `git show --format= --no-ext-diff HEAD -- packages/map_core/test/cinematic_authoring_operations_test.dart`

Exit code: 0

```diff
diff --git a/packages/map_core/test/cinematic_authoring_operations_test.dart b/packages/map_core/test/cinematic_authoring_operations_test.dart
index f3fda2aa..23ed56f1 100644
--- a/packages/map_core/test/cinematic_authoring_operations_test.dart
+++ b/packages/map_core/test/cinematic_authoring_operations_test.dart
@@ -94,6 +94,134 @@ void main() {
       expect(findCinematicById(project, 'cinematic_intro'), cinematic);
       expect(findCinematicById(project, 'missing'), isNull);
     });
+
+    test('addCinematicTimelineDraftStep inserts a marker draft after selection',
+        () {
+      final cinematic = _cinematic(id: 'cinematic_intro');
+      final project = _project(cinematics: [cinematic]);
+
+      final result = addCinematicTimelineDraftStep(
+        project,
+        cinematicId: 'cinematic_intro',
+        afterStepId: 'step_wait',
+      );
+
+      expect(project.cinematics.single.timeline.steps, hasLength(1));
+      expect(result.updatedProject.cinematics, hasLength(1));
+      expect(result.cinematic.id, 'cinematic_intro');
+      expect(result.step.id, 'step_draft');
+      expect(result.step.kind, CinematicTimelineStepKind.marker);
+      expect(result.step.label, 'Bloc brouillon');
+      expect(result.step.durationMs, isNull);
+      expect(result.step.actorId, isNull);
+      expect(result.step.targetId, isNull);
+      expect(result.step.dialogueText, isNull);
+      expect(result.step.assetRef, isNull);
+      expect(isCinematicTimelineDraftStep(result.step), isTrue);
+      expect(
+        result.cinematic.timeline.steps.map((step) => step.id),
+        ['step_wait', 'step_draft'],
+      );
+      expect(result.updatedProject.scenes, project.scenes);
+      expect(result.updatedProject.scenarios, project.scenarios);
+    });
+
+    test('addCinematicTimelineDraftStep appends when no step is selected', () {
+      final cinematic = _cinematicWithSteps(
+        id: 'cinematic_intro',
+        stepIds: ['step_camera', 'step_dialogue'],
+      );
+      final project = _project(cinematics: [cinematic]);
+
+      final result = addCinematicTimelineDraftStep(
+        project,
+        cinematicId: 'cinematic_intro',
+      );
+
+      expect(
+        result.cinematic.timeline.steps.map((step) => step.id),
+        ['step_camera', 'step_dialogue', 'step_draft'],
+      );
+    });
+
+    test('addCinematicTimelineDraftStep generates deterministic unique ids',
+        () {
+      final cinematic = _cinematicWithSteps(
+        id: 'cinematic_intro',
+        stepIds: ['step_draft', 'step_draft_2'],
+      );
+      final project = _project(cinematics: [cinematic]);
+
+      final result = addCinematicTimelineDraftStep(
+        project,
+        cinematicId: 'cinematic_intro',
+      );
+
+      expect(result.step.id, 'step_draft_3');
+    });
+
+    test('removeCinematicTimelineDraftStep removes only draft markers', () {
+      final draft = CinematicTimelineStep(
+        id: 'step_draft',
+        kind: CinematicTimelineStepKind.marker,
+        label: 'Bloc brouillon',
+        metadata: const {
+          'authoring.kind': 'draft',
+          'authoring.source': 'cinematic-builder-v0',
+        },
+      );
+      final cinematic = CinematicAsset(
+        id: 'cinematic_intro',
+        title: 'Intro cinematic',
+        timeline: CinematicTimeline(
+          steps: [
+            CinematicTimelineStep(
+              id: 'step_wait',
+              kind: CinematicTimelineStepKind.wait,
+              durationMs: 100,
+            ),
+            draft,
+          ],
+        ),
+      );
+      final project = _project(cinematics: [cinematic]);
+
+      final result = removeCinematicTimelineDraftStep(
+        project,
+        cinematicId: 'cinematic_intro',
+        stepId: 'step_draft',
+      );
+
+      expect(result.removedStep, draft);
+      expect(
+        result.cinematic.timeline.steps.map((step) => step.id),
+        ['step_wait'],
+      );
+      expect(project.cinematics.single.timeline.steps, hasLength(2));
+    });
+
+    test('removeCinematicTimelineDraftStep refuses unknown and non-draft steps',
+        () {
+      final cinematic = _cinematic(id: 'cinematic_intro');
+      final project = _project(cinematics: [cinematic]);
+
+      expect(
+        () => removeCinematicTimelineDraftStep(
+          project,
+          cinematicId: 'cinematic_intro',
+          stepId: 'step_missing',
+        ),
+        throwsA(isA<ArgumentError>()),
+      );
+      expect(
+        () => removeCinematicTimelineDraftStep(
+          project,
+          cinematicId: 'cinematic_intro',
+          stepId: 'step_wait',
+        ),
+        throwsA(isA<ArgumentError>()),
+      );
+    });
   });
 }
 
@@ -133,6 +261,26 @@ CinematicAsset _cinematic({
   );
 }
 
+CinematicAsset _cinematicWithSteps({
+  required String id,
+  required List<String> stepIds,
+}) {
+  return CinematicAsset(
+    id: id,
+    title: 'Intro cinematic',
+    timeline: CinematicTimeline(
+      steps: [
+        for (final stepId in stepIds)
+          CinematicTimelineStep(
+            id: stepId,
+            kind: CinematicTimelineStepKind.wait,
+            durationMs: 100,
+          ),
+      ],
+    ),
+  );
+}
+
 SceneAsset _sceneReferencingCinematic(String cinematicId) {
   return SceneAsset(
     id: 'scene_intro',
```

## 10. Hunks complets — cinematic_diagnostics_test.dart

Commande utilisée : `git show --format= --no-ext-diff HEAD -- packages/map_core/test/cinematic_diagnostics_test.dart`

Exit code: 0

```diff
diff --git a/packages/map_core/test/cinematic_diagnostics_test.dart b/packages/map_core/test/cinematic_diagnostics_test.dart
index 2f3c21e3..7b43a6d4 100644
--- a/packages/map_core/test/cinematic_diagnostics_test.dart
+++ b/packages/map_core/test/cinematic_diagnostics_test.dart
@@ -73,6 +73,30 @@ void main() {
       expect(diagnostic.stepId, 'step_legacy');
     });
 
+    test('accepts authoring draft marker without gameplay diagnostics', () {
+      final project = ProjectManifest(
+        name: 'Cinematic diagnostics test',
+        maps: const [],
+        tilesets: const [],
+        cinematics: [
+          _cinematic(id: 'cinematic_intro'),
+        ],
+      );
+      final result = addCinematicTimelineDraftStep(
+        project,
+        cinematicId: 'cinematic_intro',
+      );
+
+      final report = diagnoseCinematicAsset(result.cinematic);
+
+      expect(isCinematicTimelineDraftStep(result.step), isTrue);
+      expect(
+        report.byCode(CinematicDiagnosticCode.cinematicUnsupportedGameplayStep),
+        isEmpty,
+      );
+      expect(report.hasErrors, isFalse);
+    });
+
     test('reports duplicate cinematic ids in a collection', () {
       final report = diagnoseCinematics([
         _cinematic(id: 'cinematic_intro'),
```

## 11. Hunks complets — cinematic_builder_workspace.dart

Commande utilisée : `git show --format= --no-ext-diff HEAD -- packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`

Exit code: 0

```diff
diff --git a/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart b/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
index d5a7c59c..32bafabd 100644
--- a/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
+++ b/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
@@ -5,17 +5,31 @@ import 'package:map_core/map_core.dart';
 import '../../../theme/theme.dart';
 import '../../design_system/design_system.dart';
 
+typedef AddCinematicDraftStepCallback = Future<String?> Function({
+  required String cinematicId,
+  String? afterStepId,
+});
+
+typedef RemoveCinematicDraftStepCallback = Future<bool> Function({
+  required String cinematicId,
+  required String stepId,
+});
+
 class CinematicBuilderWorkspace extends StatefulWidget {
   const CinematicBuilderWorkspace({
     super.key,
     required this.entry,
     required this.asset,
     required this.onBackToLibrary,
+    required this.onAddDraftStep,
+    required this.onRemoveDraftStep,
   });
 
   final CinematicsLibraryEntry entry;
   final CinematicAsset asset;
   final VoidCallback onBackToLibrary;
+  final AddCinematicDraftStepCallback onAddDraftStep;
+  final RemoveCinematicDraftStepCallback onRemoveDraftStep;
 
   @override
   State<CinematicBuilderWorkspace> createState() =>
@@ -82,6 +96,7 @@ class _CinematicBuilderWorkspaceState extends State<CinematicBuilderWorkspace> {
                             onStepSelected: (step) {
                               setState(() => _selectedStepId = step.id);
                             },
+                            onAddDraftStep: _addDraftStep,
                           ),
                         ),
                       ],
@@ -95,6 +110,7 @@ class _CinematicBuilderWorkspaceState extends State<CinematicBuilderWorkspace> {
                       asset: widget.asset,
                       selectedStep: selectedStep,
                       selectedStepIndex: selectedStepIndex,
+                      onRemoveDraftStep: _removeDraftStep,
                     ),
                   ),
                 ],
@@ -105,6 +121,31 @@ class _CinematicBuilderWorkspaceState extends State<CinematicBuilderWorkspace> {
       ),
     );
   }
+
+  Future<void> _addDraftStep() async {
+    final createdStepId = await widget.onAddDraftStep(
+      cinematicId: widget.asset.id,
+      afterStepId: _selectedStepId,
+    );
+    if (!mounted || createdStepId == null) {
+      return;
+    }
+    setState(() => _selectedStepId = createdStepId);
+  }
+
+  Future<void> _removeDraftStep(CinematicTimelineStep step) async {
+    if (!isCinematicTimelineDraftStep(step)) {
+      return;
+    }
+    final removed = await widget.onRemoveDraftStep(
+      cinematicId: widget.asset.id,
+      stepId: step.id,
+    );
+    if (!mounted || !removed) {
+      return;
+    }
+    setState(() => _selectedStepId = null);
+  }
 }
 
 class _BuilderHeader extends StatelessWidget {
@@ -445,12 +486,14 @@ class _TimelinePlaceholder extends StatelessWidget {
     required this.asset,
     required this.selectedStepId,
     required this.onStepSelected,
+    required this.onAddDraftStep,
   });
 
   final CinematicsLibraryEntry entry;
   final CinematicAsset asset;
   final String? selectedStepId;
   final ValueChanged<CinematicTimelineStep> onStepSelected;
+  final VoidCallback onAddDraftStep;
 
   @override
   Widget build(BuildContext context) {
@@ -460,56 +503,76 @@ class _TimelinePlaceholder extends StatelessWidget {
       key: const ValueKey('cinematic-builder-timeline-placeholder'),
       expandChild: true,
       padding: const EdgeInsets.all(12),
-      child: steps.isEmpty
-          ? const _EmptyTimelineState()
-          : SingleChildScrollView(
-              child: Column(
-                crossAxisAlignment: CrossAxisAlignment.stretch,
-                children: [
-                  const _SectionTitle(
+      child: SingleChildScrollView(
+        child: Column(
+          crossAxisAlignment: CrossAxisAlignment.stretch,
+          children: [
+            Row(
+              crossAxisAlignment: CrossAxisAlignment.start,
+              children: [
+                const Expanded(
+                  child: _SectionTitle(
                     title: 'Déroulé read-only',
-                    subtitle: 'Steps existants dans l’ordre',
+                    subtitle: 'Steps existants et brouillons contrôlés',
                   ),
-                  const SizedBox(height: 8),
-                  Wrap(
-                    spacing: 6,
-                    runSpacing: 6,
-                    children: [
-                      PokeMapBadge(
-                        label: '${timeline.stepCount} step(s)',
-                        variant: PokeMapBadgeVariant.info,
-                      ),
-                      PokeMapBadge(
-                        label: _durationLabel(timeline),
-                        variant: PokeMapBadgeVariant.neutral,
-                      ),
-                      if (timeline.actorIds.isEmpty)
-                        const PokeMapBadge(
-                          label: 'Aucun acteur',
-                          variant: PokeMapBadgeVariant.neutral,
-                        )
-                      else
-                        for (final actorId in timeline.actorIds)
-                          PokeMapBadge(
-                            label: actorId,
-                            variant: PokeMapBadgeVariant.narrative,
-                          ),
-                    ],
+                ),
+                const SizedBox(width: 8),
+                _HeaderAction(
+                  label: 'Ajouter un brouillon',
+                  button: PokeMapButton(
+                    key: const ValueKey('cinematic-builder-add-draft-button'),
+                    onPressed: onAddDraftStep,
+                    variant: PokeMapButtonVariant.secondary,
+                    size: PokeMapButtonSize.small,
+                    leading: const Icon(CupertinoIcons.plus),
+                    child: const SizedBox.shrink(),
                   ),
-                  const SizedBox(height: 10),
-                  for (final indexedStep in steps.asMap().entries) ...[
-                    _TimelineStepCard(
-                      asset: asset,
-                      step: indexedStep.value,
-                      index: indexedStep.key,
-                      selected: selectedStepId == indexedStep.value.id,
-                      onTap: () => onStepSelected(indexedStep.value),
+                ),
+              ],
+            ),
+            const SizedBox(height: 8),
+            Wrap(
+              spacing: 6,
+              runSpacing: 6,
+              children: [
+                PokeMapBadge(
+                  label: '${timeline.stepCount} step(s)',
+                  variant: PokeMapBadgeVariant.info,
+                ),
+                PokeMapBadge(
+                  label: _durationLabel(timeline),
+                  variant: PokeMapBadgeVariant.neutral,
+                ),
+                if (timeline.actorIds.isEmpty)
+                  const PokeMapBadge(
+                    label: 'Aucun acteur',
+                    variant: PokeMapBadgeVariant.neutral,
+                  )
+                else
+                  for (final actorId in timeline.actorIds)
+                    PokeMapBadge(
+                      label: actorId,
+                      variant: PokeMapBadgeVariant.narrative,
                     ),
-                    const SizedBox(height: 8),
-                  ],
-                ],
-              ),
+              ],
             ),
+            const SizedBox(height: 10),
+            if (steps.isEmpty)
+              const _EmptyTimelineState()
+            else
+              for (final indexedStep in steps.asMap().entries) ...[
+                _TimelineStepCard(
+                  asset: asset,
+                  step: indexedStep.value,
+                  index: indexedStep.key,
+                  selected: selectedStepId == indexedStep.value.id,
+                  onTap: () => onStepSelected(indexedStep.value),
+                ),
+                const SizedBox(height: 8),
+              ],
+          ],
+        ),
+      ),
     );
   }
 }
@@ -532,6 +595,7 @@ class _TimelineStepCard extends StatelessWidget {
   @override
   Widget build(BuildContext context) {
     final diagnostics = _stepDiagnostics(asset, step);
+    final isDraft = isCinematicTimelineDraftStep(step);
     return PokeMapCard(
       key: ValueKey('cinematic-builder-step-card-${step.id}'),
       selected: selected,
@@ -551,6 +615,13 @@ class _TimelineStepCard extends StatelessWidget {
               const SizedBox(width: 8),
               Expanded(child: _StrongText(_stepTitle(step, index))),
               const SizedBox(width: 8),
+              if (isDraft) ...[
+                const PokeMapBadge(
+                  label: 'Brouillon',
+                  variant: PokeMapBadgeVariant.warning,
+                ),
+                const SizedBox(width: 6),
+              ],
               PokeMapBadge(
                 label: step.kind.name,
                 variant: PokeMapBadgeVariant.narrative,
@@ -629,12 +700,14 @@ class _InspectorPlaceholder extends StatelessWidget {
     required this.asset,
     required this.selectedStep,
     required this.selectedStepIndex,
+    required this.onRemoveDraftStep,
   });
 
   final CinematicsLibraryEntry entry;
   final CinematicAsset asset;
   final CinematicTimelineStep? selectedStep;
   final int? selectedStepIndex;
+  final ValueChanged<CinematicTimelineStep> onRemoveDraftStep;
 
   @override
   Widget build(BuildContext context) {
@@ -660,6 +733,7 @@ class _InspectorPlaceholder extends StatelessWidget {
                 asset: asset,
                 step: selected,
                 index: selectedIndex,
+                onRemoveDraftStep: onRemoveDraftStep,
               ),
             const SizedBox(height: 12),
             const _SectionTitle(
@@ -712,15 +786,18 @@ class _SelectedStepInspector extends StatelessWidget {
     required this.asset,
     required this.step,
     required this.index,
+    required this.onRemoveDraftStep,
   });
 
   final CinematicAsset asset;
   final CinematicTimelineStep step;
   final int index;
+  final ValueChanged<CinematicTimelineStep> onRemoveDraftStep;
 
   @override
   Widget build(BuildContext context) {
     final diagnostics = _stepDiagnostics(asset, step);
+    final isDraft = isCinematicTimelineDraftStep(step);
     return Column(
       crossAxisAlignment: CrossAxisAlignment.stretch,
       children: [
@@ -742,6 +819,28 @@ class _SelectedStepInspector extends StatelessWidget {
         ),
         _KeyValue(label: 'Asset', value: step.assetRef ?? 'Aucun assetRef'),
         _KeyValue(label: 'Metadata', value: _metadataLabel(step.metadata)),
+        if (isDraft) ...[
+          const _KeyValue(
+            label: 'Statut',
+            value: 'Placeholder authoring',
+          ),
+          const _BodyText(
+            'Ce bloc est un placeholder authoring. '
+            'Les vrais blocs arrivent dans un lot futur.',
+          ),
+          const SizedBox(height: 8),
+          PokeMapButton(
+            key: const ValueKey('cinematic-builder-remove-draft-button'),
+            onPressed: () => onRemoveDraftStep(step),
+            variant: PokeMapButtonVariant.danger,
+            size: PokeMapButtonSize.small,
+            leading: const Icon(CupertinoIcons.trash),
+            child: const SizedBox.shrink(),
+          ),
+          const SizedBox(height: 4),
+          const _MutedText('Supprimer ce brouillon'),
+          const SizedBox(height: 8),
+        ],
         const _KeyValue(
           label: 'Preview',
           value: 'Preview réelle à venir.',
```

## 12. Hunks complets — cinematics_library_workspace.dart

Commande utilisée : `git show --format= --no-ext-diff HEAD -- packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart`

Exit code: 0

```diff
diff --git a/packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart b/packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
index 9d53534f..feac4897 100644
--- a/packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
+++ b/packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
@@ -21,6 +21,16 @@ typedef RemoveCinematicCallback = Future<bool> Function({
   required String cinematicId,
 });
 
+typedef AddTimelineDraftCallback = Future<String?> Function({
+  required String cinematicId,
+  String? afterStepId,
+});
+
+typedef RemoveTimelineDraftCallback = Future<bool> Function({
+  required String cinematicId,
+  required String stepId,
+});
+
 enum _CinematicsLibraryFilter {
   all,
   canonical,
@@ -34,6 +44,8 @@ class CinematicsLibraryWorkspace extends StatefulWidget {
     required this.onCreateCinematicShell,
     required this.onUpdateCinematicMetadata,
     required this.onRemoveCinematic,
+    required this.onAddTimelineDraft,
+    required this.onRemoveTimelineDraft,
     this.onOpenLegacyCutsceneStudio,
   });
 
@@ -41,6 +53,8 @@ class CinematicsLibraryWorkspace extends StatefulWidget {
   final CreateCinematicShellCallback onCreateCinematicShell;
   final UpdateCinematicMetadataCallback onUpdateCinematicMetadata;
   final RemoveCinematicCallback onRemoveCinematic;
+  final AddTimelineDraftCallback onAddTimelineDraft;
+  final RemoveTimelineDraftCallback onRemoveTimelineDraft;
   final VoidCallback? onOpenLegacyCutsceneStudio;
 
   @override
@@ -93,6 +107,8 @@ class _CinematicsLibraryWorkspaceState
         onBackToLibrary: () {
           setState(() => _builderEntryId = null);
         },
+        onAddDraftStep: widget.onAddTimelineDraft,
+        onRemoveDraftStep: widget.onRemoveTimelineDraft,
       );
     }
     if (_builderEntryId != null) {
```

## 13. Hunks complets — narrative_workspace_canvas.dart

Commande utilisée : `git show --format= --no-ext-diff HEAD -- packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`

Exit code: 0

```diff
diff --git a/packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart b/packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
index 8361a47a..2ae88bec 100644
--- a/packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
+++ b/packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
@@ -1101,6 +1101,8 @@ class _CinematicsWorkspaceBodyState extends State<_CinematicsWorkspaceBody> {
       onCreateCinematicShell: _createCinematicShell,
       onUpdateCinematicMetadata: _updateCinematicMetadata,
       onRemoveCinematic: _removeCinematic,
+      onAddTimelineDraft: _addCinematicTimelineDraft,
+      onRemoveTimelineDraft: _removeCinematicTimelineDraft,
       onOpenLegacyCutsceneStudio: () {
         setState(() => _showLegacyCutsceneStudio = true);
       },
@@ -1194,6 +1196,54 @@ class _CinematicsWorkspaceBodyState extends State<_CinematicsWorkspaceBody> {
       return false;
     }
   }
+
+  Future<String?> _addCinematicTimelineDraft({
+    required String cinematicId,
+    String? afterStepId,
+  }) async {
+    final project = widget.project;
+    if (project == null) {
+      return null;
+    }
+    try {
+      final result = addCinematicTimelineDraftStep(
+        project,
+        cinematicId: cinematicId,
+        afterStepId: afterStepId,
+      );
+      widget.editorNotifier.applyInMemoryProjectManifest(
+        result.updatedProject,
+        statusMessage: 'Cinematic timeline draft created',
+      );
+      return result.step.id;
+    } on ArgumentError {
+      return null;
+    }
+  }
+
+  Future<bool> _removeCinematicTimelineDraft({
+    required String cinematicId,
+    required String stepId,
+  }) async {
+    final project = widget.project;
+    if (project == null) {
+      return false;
+    }
+    try {
+      final result = removeCinematicTimelineDraftStep(
+        project,
+        cinematicId: cinematicId,
+        stepId: stepId,
+      );
+      widget.editorNotifier.applyInMemoryProjectManifest(
+        result.updatedProject,
+        statusMessage: 'Cinematic timeline draft removed',
+      );
+      return true;
+    } on ArgumentError {
+      return false;
+    }
+  }
 }
 
 String _nextCinematicAssetId(ProjectManifest project, String title) {
```

## 14. Hunks complets — cinematic_builder_workspace_test.dart

Commande utilisée : `git show --format= --no-ext-diff HEAD -- packages/map_editor/test/cinematic_builder_workspace_test.dart`

Exit code: 0

```diff
diff --git a/packages/map_editor/test/cinematic_builder_workspace_test.dart b/packages/map_editor/test/cinematic_builder_workspace_test.dart
index 36a76c08..30b1718d 100644
--- a/packages/map_editor/test/cinematic_builder_workspace_test.dart
+++ b/packages/map_editor/test/cinematic_builder_workspace_test.dart
@@ -182,6 +182,101 @@ void main() {
     expect(project.toJson(), before);
   });
 
+  testWidgets('adds a safe draft after selected step and inspects it',
+      (tester) async {
+    _setLargeSurface(tester);
+    late ProjectManifest latestProject;
+    final project = _project(cinematics: [_richCinematic()]);
+    await _pumpBuilderHarness(
+      tester,
+      project,
+      'cinematic_rich',
+      onProjectChanged: (project) => latestProject = project,
+    );
+
+    await tester.ensureVisible(
+      find.byKey(const ValueKey('cinematic-builder-step-card-step_dialogue')),
+    );
+    await tester.tap(
+      find.byKey(const ValueKey('cinematic-builder-step-card-step_dialogue')),
+    );
+    await tester.pumpAndSettle();
+    await tester.ensureVisible(
+      find.byKey(const ValueKey('cinematic-builder-add-draft-button')),
+    );
+    await tester.tap(
+      find.byKey(const ValueKey('cinematic-builder-add-draft-button')),
+    );
+    await tester.pumpAndSettle();
+
+    expect(find.text('Bloc brouillon'), findsWidgets);
+    expect(find.text('Brouillon'), findsWidgets);
+    expect(find.text('marker'), findsWidgets);
+    expect(find.text('Statut'), findsWidgets);
+    expect(find.text('Placeholder authoring'), findsOneWidget);
+    expect(
+      find.text(
+        'Ce bloc est un placeholder authoring. '
+        'Les vrais blocs arrivent dans un lot futur.',
+      ),
+      findsOneWidget,
+    );
+    expect(
+        find.text(
+            'authoring.kind = draft, authoring.source = cinematic-builder-v0'),
+        findsOneWidget);
+    final selectedDraftCard = tester.widget<PokeMapCard>(
+      find.byKey(const ValueKey('cinematic-builder-step-card-step_draft')),
+    );
+    expect(selectedDraftCard.selected, isTrue);
+    expect(
+      latestProject.cinematics.single.timeline.steps.map((step) => step.id),
+      ['step_camera', 'step_dialogue', 'step_draft', 'step_sound'],
+    );
+    expect(latestProject.scenes, project.scenes);
+    expect(latestProject.scenarios, project.scenarios);
+  });
+
+  testWidgets('removes only the selected draft from the builder',
+      (tester) async {
+    _setLargeSurface(tester);
+    late ProjectManifest latestProject;
+    final project = _project(cinematics: [_richCinematic()]);
+    await _pumpBuilderHarness(
+      tester,
+      project,
+      'cinematic_rich',
+      onProjectChanged: (project) => latestProject = project,
+    );
+
+    await tester.tap(
+      find.byKey(const ValueKey('cinematic-builder-step-card-step_camera')),
+    );
+    await tester.pumpAndSettle();
+    expect(
+      find.byKey(const ValueKey('cinematic-builder-remove-draft-button')),
+      findsNothing,
+    );
+
+    await tester.tap(
+      find.byKey(const ValueKey('cinematic-builder-add-draft-button')),
+    );
+    await tester.pumpAndSettle();
+    expect(find.text('Bloc brouillon'), findsWidgets);
+    await tester.tap(
+      find.byKey(const ValueKey('cinematic-builder-remove-draft-button')),
+    );
+    await tester.pumpAndSettle();
+
+    expect(find.byKey(const ValueKey('cinematic-builder-step-card-step_draft')),
+        findsNothing);
+    expect(find.text('Aucun bloc sélectionné'), findsOneWidget);
+    expect(
+      latestProject.cinematics.single.timeline.steps.map((step) => step.id),
+      ['step_camera', 'step_dialogue', 'step_sound'],
+    );
+  });
+
   testWidgets('shows empty timeline state without authoring controls',
       (tester) async {
     _setLargeSurface(tester);
@@ -266,6 +361,39 @@ void main() {
 
     expect(screenshotFile.existsSync(), isTrue);
   });
+
+  testWidgets('captures V1-44 builder draft screenshot when requested',
+      (tester) async {
+    if (!const bool.fromEnvironment(
+      'NS_SCENES_V1_44_CAPTURE_CINEMATIC_BUILDER_DRAFTS',
+    )) {
+      return;
+    }
+
+    _setLargeSurface(tester);
+    await _loadScreenshotFonts();
+    await _pumpBuilderHarness(
+      tester,
+      _project(cinematics: [_richCinematic()]),
+      'cinematic_rich',
+    );
+    await tester.tap(
+      find.byKey(const ValueKey('cinematic-builder-add-draft-button')),
+    );
+    await tester.pumpAndSettle();
+
+    final screenshotFile = File(
+      '../../reports/narrativeStudio/scenes/screenshots/'
+      'ns_scenes_v1_44_cinematic_timeline_authoring_drafts_v0.png',
+    );
+    screenshotFile.parent.createSync(recursive: true);
+    await expectLater(
+      find.byKey(const ValueKey('cinematic-builder-workspace')),
+      matchesGoldenFile(screenshotFile.absolute.path),
+    );
+
+    expect(screenshotFile.existsSync(), isTrue);
+  });
 }
 
 Future<void> _pumpBuilder(
@@ -286,6 +414,16 @@ Future<void> _pumpBuilder(
               entry: entry,
               asset: asset,
               onBackToLibrary: onBackToLibrary ?? () {},
+              onAddDraftStep: ({
+                required String cinematicId,
+                String? afterStepId,
+              }) async =>
+                  null,
+              onRemoveDraftStep: ({
+                required String cinematicId,
+                required String stepId,
+              }) async =>
+                  false,
             ),
           ),
         ),
@@ -295,6 +433,93 @@ Future<void> _pumpBuilder(
   await tester.pumpAndSettle();
 }
 
+Future<void> _pumpBuilderHarness(
+  WidgetTester tester,
+  ProjectManifest project,
+  String cinematicId, {
+  ValueChanged<ProjectManifest>? onProjectChanged,
+}) async {
+  await tester.pumpWidget(
+    _BuilderHarness(
+      project: project,
+      cinematicId: cinematicId,
+      onProjectChanged: onProjectChanged,
+    ),
+  );
+  await tester.pumpAndSettle();
+}
+
+class _BuilderHarness extends StatefulWidget {
+  const _BuilderHarness({
+    required this.project,
+    required this.cinematicId,
+    this.onProjectChanged,
+  });
+
+  final ProjectManifest project;
+  final String cinematicId;
+  final ValueChanged<ProjectManifest>? onProjectChanged;
+
+  @override
+  State<_BuilderHarness> createState() => _BuilderHarnessState();
+}
+
+class _BuilderHarnessState extends State<_BuilderHarness> {
+  late ProjectManifest _project = widget.project;
+
+  @override
+  Widget build(BuildContext context) {
+    final entry = _entry(_project, widget.cinematicId);
+    final asset = _asset(_project, widget.cinematicId);
+    return MacosTheme(
+      data: MacosThemeData.dark(),
+      child: MaterialApp(
+        home: Scaffold(
+          body: SizedBox(
+            width: 1280,
+            height: 860,
+            child: CinematicBuilderWorkspace(
+              entry: entry,
+              asset: asset,
+              onBackToLibrary: () {},
+              onAddDraftStep: _addDraftStep,
+              onRemoveDraftStep: _removeDraftStep,
+            ),
+          ),
+        ),
+      ),
+    );
+  }
+
+  Future<String?> _addDraftStep({
+    required String cinematicId,
+    String? afterStepId,
+  }) async {
+    final result = addCinematicTimelineDraftStep(
+      _project,
+      cinematicId: cinematicId,
+      afterStepId: afterStepId,
+    );
+    setState(() => _project = result.updatedProject);
+    widget.onProjectChanged?.call(_project);
+    return result.step.id;
+  }
+
+  Future<bool> _removeDraftStep({
+    required String cinematicId,
+    required String stepId,
+  }) async {
+    final result = removeCinematicTimelineDraftStep(
+      _project,
+      cinematicId: cinematicId,
+      stepId: stepId,
+    );
+    setState(() => _project = result.updatedProject);
+    widget.onProjectChanged?.call(_project);
+    return true;
+  }
+}
+
 CinematicAsset _asset(ProjectManifest project, String id) {
   final asset = findCinematicById(project, id);
   if (asset == null) {
```

## 15. Hunks complets — cinematics_library_workspace_test.dart

Commande utilisée : `git show --format= --no-ext-diff HEAD -- packages/map_editor/test/cinematics_library_workspace_test.dart`

Exit code: 0

```diff
diff --git a/packages/map_editor/test/cinematics_library_workspace_test.dart b/packages/map_editor/test/cinematics_library_workspace_test.dart
index bca96bff..299d3d8c 100644
--- a/packages/map_editor/test/cinematics_library_workspace_test.dart
+++ b/packages/map_editor/test/cinematics_library_workspace_test.dart
@@ -136,6 +136,38 @@ void main() {
     expect(find.text('Bibliothèque'), findsWidgets);
   });
 
+  testWidgets('adds a draft from builder and refreshes library summary',
+      (tester) async {
+    _setLargeSurface(tester);
+    await tester.pumpWidget(_Harness(project: _project()));
+    await tester.pumpAndSettle();
+
+    await tester.tap(
+      find.byKey(const ValueKey('cinematic-entry-cinematic_intro')),
+    );
+    await tester.pumpAndSettle();
+    await tester.tap(
+      find.byKey(const ValueKey('cinematics-library-open-builder-button')),
+    );
+    await tester.pumpAndSettle();
+    await tester.tap(
+      find.byKey(const ValueKey('cinematic-builder-add-draft-button')),
+    );
+    await tester.pumpAndSettle();
+
+    expect(find.text('Bloc brouillon'), findsWidgets);
+    expect(find.text('Brouillon'), findsWidgets);
+
+    await tester.tap(
+      find.byKey(const ValueKey('cinematic-builder-back-button')),
+    );
+    await tester.pumpAndSettle();
+
+    expect(find.byKey(const ValueKey('cinematics-library-workspace')),
+        findsOneWidget);
+    expect(find.text('3 step(s)'), findsWidgets);
+  });
+
   testWidgets('keeps legacy bridge out of canonical builder shell',
       (tester) async {
     _setLargeSurface(tester);
@@ -325,6 +357,30 @@ class _HarnessState extends State<_Harness> {
                 setState(() => _project = result.updatedProject);
                 return true;
               },
+              onAddTimelineDraft: ({
+                required String cinematicId,
+                String? afterStepId,
+              }) async {
+                final result = addCinematicTimelineDraftStep(
+                  _project,
+                  cinematicId: cinematicId,
+                  afterStepId: afterStepId,
+                );
+                setState(() => _project = result.updatedProject);
+                return result.step.id;
+              },
+              onRemoveTimelineDraft: ({
+                required String cinematicId,
+                required String stepId,
+              }) async {
+                final result = removeCinematicTimelineDraftStep(
+                  _project,
+                  cinematicId: cinematicId,
+                  stepId: stepId,
+                );
+                setState(() => _project = result.updatedProject);
+                return result.removedStep.id == stepId;
+              },
               onOpenLegacyCutsceneStudio: () {},
             ),
           ),
```

## 16. Hunks complets — road_map_scenes.md

Commande utilisée : `git show --format= --no-ext-diff HEAD -- reports/narrativeStudio/scenes/road_map_scenes.md`

Exit code: 0

```diff
diff --git a/reports/narrativeStudio/scenes/road_map_scenes.md b/reports/narrativeStudio/scenes/road_map_scenes.md
index 9cd7e089..30fa8c8c 100644
--- a/reports/narrativeStudio/scenes/road_map_scenes.md
+++ b/reports/narrativeStudio/scenes/road_map_scenes.md
@@ -98,16 +98,17 @@ Ces briques sont utiles, mais elles ne constituent pas encore une Scene V1 propr
 | NS-SCENES-V1-41 — Cinematic Builder V0 Scope / Runtime Playback Contract | DONE | Lot documentaire : contrat strict du futur Builder V0 comme assembleur no-code de sequences moteur simples, lineaires et sandboxees, plus contrat Runtime Playback V0/V1 borne, sans Builder code, sans timeline editor, sans playback visuel et sans effet gameplay depuis Cinematic. |
 | NS-SCENES-V1-42 — Cinematic Builder V0 Shell | DONE | Shell editor read-only ouvert depuis la Cinematics Library pour les `CinematicAsset` canoniques : header, palette verrouillee, apercu sandbox, deroule et inspecteur placeholders, bridges legacy exclus du Builder canonique, visual gate et tests widget. |
 | NS-SCENES-V1-43 — Cinematic Timeline Read-only / Step Inspector V0 | DONE | Le Builder liste les steps existants dans l'ordre, permet une selection locale non persistante et affiche un inspecteur detaille lecture seule avec diagnostics contextualises, sans mutation de timeline ni changement core/runtime. |
+| NS-SCENES-V1-44 — Cinematic Timeline Authoring Drafts V0 | DONE | Le Builder peut ajouter un bloc brouillon marker borne, l'inspecter en lecture seule et supprimer uniquement ce brouillon via operations pures `ProjectManifest.cinematics`, sans effet runtime ni vrai bloc metier. |
 
 ## Prochain lot recommande
 
-`NS-SCENES-V1-44 — Cinematic Timeline Authoring Drafts V0`
+`NS-SCENES-V1-45 — Cinematic Wait/Fade/Camera Basic Blocks V0`
 
-Raison : V1-43 a rendu le deroule inspectable sans mutation. Le prochain verrou est de cadrer des drafts authoring bornes, avec operations pures et preuves de non-regression, avant toute persistance plus ambitieuse.
+Raison : V1-44 a prouve la mutation bornee du deroule avec un bloc brouillon neutre. Le prochain verrou est d'introduire les premiers vrais blocs cinematic simples, toujours authorables et diagnostiques sans ecrire de gameplay.
 
-Ordre apres V1-43 : `NS-SCENES-V1-44 — Cinematic Timeline Authoring Drafts V0`.
+Ordre apres V1-44 : `NS-SCENES-V1-45 — Cinematic Wait/Fade/Camera Basic Blocks V0`.
 
-Ordre corrige : Payload Pickers V0, puis Event -> Scene Trigger Prep, puis Event -> Scene Link V0, puis Scene Runtime Plan V0, puis Diagnostics / Validator Expansion, puis Dialogue/Battle Ports Authoring V0, puis Runtime Executor MVP, puis Evidence & Review Hardening, puis World Rules Map Editor Integration V0, puis Golden Slice Scene/Event Prep, puis Event to Scene Runtime Hook V0, puis Scene Consequence Contract Prep, puis Scene Consequence Model V0, puis Scene Consequence Runtime Write V0, puis Battle Runtime Outcome Adapter V0, puis Dialogue Runtime Awaitable Adapter V0, puis Golden Slice Runtime Smoke V0, puis StorylineStep to Scene Link, puis Scene Node Payload Editing V0, puis Scene Node Deletion UX V0, puis Scene Consequence Authoring UI V0, puis Scene V1 Beta Readiness Checkpoint, puis Runtime State Persistence Gate V0, puis World Rules Runtime Projection Hook V0, puis Facts & World Rules Manager UI V0, puis Cinematic V1 Contract / Bridge Decision, puis CinematicAsset Core Model V0, puis Cinematics Library V0, puis Cinematic Scene Builder Picker V0, puis Cinematic Runtime Adapter V0, puis Cinematic Builder V0 Scope / Runtime Playback Contract, puis Cinematic Builder V0 Shell, puis Cinematic Timeline Read-only / Step Inspector V0.
+Ordre corrige : Payload Pickers V0, puis Event -> Scene Trigger Prep, puis Event -> Scene Link V0, puis Scene Runtime Plan V0, puis Diagnostics / Validator Expansion, puis Dialogue/Battle Ports Authoring V0, puis Runtime Executor MVP, puis Evidence & Review Hardening, puis World Rules Map Editor Integration V0, puis Golden Slice Scene/Event Prep, puis Event to Scene Runtime Hook V0, puis Scene Consequence Contract Prep, puis Scene Consequence Model V0, puis Scene Consequence Runtime Write V0, puis Battle Runtime Outcome Adapter V0, puis Dialogue Runtime Awaitable Adapter V0, puis Golden Slice Runtime Smoke V0, puis StorylineStep to Scene Link, puis Scene Node Payload Editing V0, puis Scene Node Deletion UX V0, puis Scene Consequence Authoring UI V0, puis Scene V1 Beta Readiness Checkpoint, puis Runtime State Persistence Gate V0, puis World Rules Runtime Projection Hook V0, puis Facts & World Rules Manager UI V0, puis Cinematic V1 Contract / Bridge Decision, puis CinematicAsset Core Model V0, puis Cinematics Library V0, puis Cinematic Scene Builder Picker V0, puis Cinematic Runtime Adapter V0, puis Cinematic Builder V0 Scope / Runtime Playback Contract, puis Cinematic Builder V0 Shell, puis Cinematic Timeline Read-only / Step Inspector V0, puis Cinematic Timeline Authoring Drafts V0.
 
 Note : l'overview n'affiche plus `Facts — necessite un modele`; Facts et Regles du monde pointent maintenant vers des workspaces actifs.
 
@@ -283,6 +284,20 @@ Preuve : tests widget Builder et Library verts, analyse ciblee sans issue, visua
 
 Prochain lot exact : `NS-SCENES-V1-44 — Cinematic Timeline Authoring Drafts V0`.
 
+## Mise a jour V1-44
+
+Statut : `NS-SCENES-V1-44 — Cinematic Timeline Authoring Drafts V0` est DONE.
+
+Decision : le premier authoring de deroule Cinematic reste volontairement neutre. Un bloc brouillon est un `CinematicTimelineStep.marker` identifie par metadata `authoring.kind=draft` et `authoring.source=cinematic-builder-v0`; il ne porte ni duree, ni acteur, ni cible, ni dialogue, ni asset, ni effet moteur.
+
+Scope realise : operations pures `addCinematicTimelineDraftStep`, `removeCinematicTimelineDraftStep` et `isCinematicTimelineDraftStep`, mutation en memoire de `ProjectManifest.cinematics`, insertion apres selection ou en fin de deroule, selection automatique du brouillon cree, inspecteur lecture seule, bouton d'ajout no-code, suppression disponible seulement pour un brouillon, Library rafraichie.
+
+Limites : aucun vrai bloc Camera/Fondu/Attente/Dialogue/FX/Son/Acteur, aucune edition de champ, aucune gestion d'ordre avancee, aucun player visuel, aucun changement de schema JSON, aucun package gameplay/battle/runtime/examples modifie et aucune migration legacy.
+
+Preuve : tests core authoring et diagnostics verts, tests widget Builder et Library verts, analyse `map_core` et analyse editor ciblee sans issue, visual gate `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_44_cinematic_timeline_authoring_drafts_v0.png`.
+
+Prochain lot exact : `NS-SCENES-V1-45 — Cinematic Wait/Fade/Camera Basic Blocks V0`.
+
 ## Mise a jour V1-30-bis
 
 Statut : `NS-SCENES-V1-30-bis — Scene Node Deletion UX V0` est DONE.
```

## 17. Hunks complets — road_map_scene_builder_authoring.md

Commande utilisée : `git show --format= --no-ext-diff HEAD -- reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

Exit code: 0

```diff
diff --git a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
index 54c5391c..b1319068 100644
--- a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
+++ b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
@@ -9,7 +9,7 @@ Le runtime reste indispensable, mais le prochain blocage produit est plus basiqu
 ## Prochain lot exact recommande
 
 ```text
-NS-SCENES-V1-44 — Cinematic Timeline Authoring Drafts V0
+NS-SCENES-V1-45 — Cinematic Wait/Fade/Camera Basic Blocks V0
 ```
 
 ## Principes
@@ -77,6 +77,7 @@ NS-SCENES-V1-44 — Cinematic Timeline Authoring Drafts V0
 | NS-SCENES-V1-41 | Cinematic Builder V0 Scope / Runtime Playback Contract | doc / architecture-review | Cadrer le futur Builder V0 et le futur contrat Runtime Playback avant de coder l'UI, la timeline, les blocs authorables ou le player visuel. | Pas de code Dart, pas de widget, pas de timeline editor, pas de playback visuel, pas de migration ScenarioAsset, pas d'effet gameplay cinematic. | rapport V1-41, roadmaps. | DONE : rapport contractuel, capability matrix, taxonomie blocs, frontieres anti-scope, `git diff --check`. | Coder le Builder trop tot ; refaire ScenarioAsset ; ouvrir branches/failures authorables ; laisser Cinematic ecrire le monde. | DONE : Builder V0 = assembleur lineaire sandboxe ; Runtime Playback V0/V1 = lecture bornee sans gameplay effect ; prochain lot shell seulement. | V1-40. |
 | NS-SCENES-V1-42 | Cinematic Builder V0 Shell | editor / ui-shell | Ouvrir un shell Builder depuis la Cinematics Library pour un `CinematicAsset` canonique, avec zones read-only et navigation retour. | Pas de timeline editor, pas de mutation `ProjectManifest`, pas de preview runtime, pas de migration bridge, pas de modele core. | `cinematic_builder_workspace.dart`, `cinematics_library_workspace.dart`, tests widget, rapport, screenshot. | DONE : Library -> Builder -> retour, bridge legacy exclu, palette/preview/deroule/inspecteur visibles, boutons inactifs, visual gate, analyze cible. | Confondre shell et authoring ; promouvoir bridge legacy ; laisser croire que la preview est jouable. | DONE : shell V0 lisible, strictement read-only et canonique-only. | V1-41. |
 | NS-SCENES-V1-43 | Cinematic Timeline Read-only / Step Inspector V0 | editor / ui-readonly | Rendre le deroule du Builder inspectable : steps reels ordonnes, selection locale, inspecteur detaille lecture seule et diagnostics contextualises. | Pas de mutation de timeline, pas de modele core, pas de preview runtime, pas de migration bridge. | `cinematic_builder_workspace.dart`, `cinematics_library_workspace.dart`, tests widget, rapport, screenshot. | DONE : liste steps, selection locale, inspecteur step, diagnostics, non-mutation, visual gate, analyze cible. | Confondre inspection et authoring ; dupliquer le read model core ; creer une selection persistante inutile. | DONE : Builder inspectable sans changer `ProjectManifest`, core ou runtime. | V1-42. |
+| NS-SCENES-V1-44 | Cinematic Timeline Authoring Drafts V0 | core / editor | Ajouter un brouillon neutre dans le deroule Cinematic, l'inspecter et le retirer de facon bornee via operations pures. | Pas de vrais blocs metier, pas d'edition de champs, pas de player visuel, pas de runtime, pas de changement schema. | `cinematic_authoring_operations.dart`, Builder/Library cinematics, tests core/widget, rapport, screenshot. | DONE : add/remove draft purs, insertion apres selection ou fin, suppression refusee hors brouillon, mutation memoire, visual gate, analyses. | Laisser un brouillon produire un effet ; supprimer un vrai step ; confondre marker neutre et bloc moteur. | DONE : marker draft identifie par metadata, UI no-code bornee, non-regression core/editor prouvee. | V1-43. |
 
 ## Options comparees
 
@@ -695,6 +696,20 @@ Limites : pas de creation de blocs, pas de suppression de blocs, pas de changeme
 
 Prochain lot exact : `NS-SCENES-V1-44 — Cinematic Timeline Authoring Drafts V0`.
 
+## Mise a jour V1-44
+
+Statut : `NS-SCENES-V1-44 — Cinematic Timeline Authoring Drafts V0` est DONE.
+
+Decision : le Cinematic Builder gagne seulement un brouillon authoring neutre. Il est stocke comme `CinematicTimelineStep.marker` avec metadata de provenance authoring, ce qui garde le deroule inspectable et modifiable sans ouvrir les vrais blocs moteur.
+
+Scope realise : ajout et retrait via operations pures, ID stable, insertion apres le bloc selectionne ou a la fin, refus des steps inconnus et non-brouillons, mutation `ProjectManifest.cinematics` en memoire, selection automatique, inspecteur lecture seule et bouton de retrait visible seulement sur un brouillon.
+
+Limites : pas de Camera/Fondu/Attente/Dialogue/FX/Son/Acteur authorables, pas d'edition de payload, pas de changement d'ordre, pas de preview jouable, pas de runtime, pas de migration legacy.
+
+Preuve : tests core `cinematic_authoring_operations` et `cinematic_diagnostics`, tests widget Builder et Library, analyse ciblee et capture V1-44.
+
+Prochain lot exact : `NS-SCENES-V1-45 — Cinematic Wait/Fade/Camera Basic Blocks V0`.
+
 ## Selbrume golden slice
 
 Avant le golden slice, il faut au minimum :
```

## 18. Tests relancés

```bash
cd packages/map_core && dart test test/cinematic_authoring_operations_test.dart
```

Exit code: 0

```text

00:00 [32m+0[0m: [1m[90mloading test/cinematic_authoring_operations_test.dart[0m[0m                                                                                                                                        
00:00 [32m+0[0m: Cinematic authoring operations addCinematicAsset adds an asset without mutating project[0m                                                                                                      
00:00 [32m+1[0m: Cinematic authoring operations addCinematicAsset adds an asset without mutating project[0m                                                                                                      
00:00 [32m+1[0m: Cinematic authoring operations addCinematicAsset refuses duplicate ids[0m                                                                                                                       
00:00 [32m+2[0m: Cinematic authoring operations addCinematicAsset refuses duplicate ids[0m                                                                                                                       
00:00 [32m+2[0m: Cinematic authoring operations updateCinematicAsset replaces an existing asset only[0m                                                                                                          
00:00 [32m+3[0m: Cinematic authoring operations updateCinematicAsset replaces an existing asset only[0m                                                                                                          
00:00 [32m+3[0m: Cinematic authoring operations removeCinematicAsset removes unused asset[0m                                                                                                                     
00:00 [32m+4[0m: Cinematic authoring operations removeCinematicAsset removes unused asset[0m                                                                                                                     
00:00 [32m+4[0m: Cinematic authoring operations removeCinematicAsset refuses a cinematic referenced by a Scene[0m                                                                                                
00:00 [32m+5[0m: Cinematic authoring operations removeCinematicAsset refuses a cinematic referenced by a Scene[0m                                                                                                
00:00 [32m+5[0m: Cinematic authoring operations replaceCinematics validates duplicate ids and preserves other data[0m                                                                                            
00:00 [32m+6[0m: Cinematic authoring operations replaceCinematics validates duplicate ids and preserves other data[0m                                                                                            
00:00 [32m+6[0m: Cinematic authoring operations findCinematicById returns matching asset or null[0m                                                                                                              
00:00 [32m+7[0m: Cinematic authoring operations findCinematicById returns matching asset or null[0m                                                                                                              
00:00 [32m+7[0m: Cinematic authoring operations addCinematicTimelineDraftStep inserts a marker draft after selection[0m                                                                                          
00:00 [32m+8[0m: Cinematic authoring operations addCinematicTimelineDraftStep inserts a marker draft after selection[0m                                                                                          
00:00 [32m+8[0m: Cinematic authoring operations addCinematicTimelineDraftStep appends when no step is selected[0m                                                                                                
00:00 [32m+9[0m: Cinematic authoring operations addCinematicTimelineDraftStep appends when no step is selected[0m                                                                                                
00:00 [32m+9[0m: Cinematic authoring operations addCinematicTimelineDraftStep generates deterministic unique ids[0m                                                                                              
00:00 [32m+10[0m: Cinematic authoring operations addCinematicTimelineDraftStep generates deterministic unique ids[0m                                                                                             
00:00 [32m+10[0m: Cinematic authoring operations removeCinematicTimelineDraftStep removes only draft markers[0m                                                                                                  
00:00 [32m+11[0m: Cinematic authoring operations removeCinematicTimelineDraftStep removes only draft markers[0m                                                                                                  
00:00 [32m+11[0m: Cinematic authoring operations removeCinematicTimelineDraftStep refuses unknown and non-draft steps[0m                                                                                         
00:00 [32m+12[0m: Cinematic authoring operations removeCinematicTimelineDraftStep refuses unknown and non-draft steps[0m                                                                                         
00:00 [32m+12[0m: All tests passed![0m                                                                                                                                                                           
```

```bash
cd packages/map_core && dart test test/cinematic_diagnostics_test.dart
```

Exit code: 0

```text

00:00 [32m+0[0m: [1m[90mloading test/cinematic_diagnostics_test.dart[0m[0m                                                                                                                                                 
00:00 [32m+0[0m: Cinematic diagnostics reports empty timeline as authoring warning[0m                                                                                                                            
00:00 [32m+1[0m: Cinematic diagnostics reports empty timeline as authoring warning[0m                                                                                                                            
00:00 [32m+1[0m: Cinematic diagnostics reports duplicate step ids and invalid durations[0m                                                                                                                       
00:00 [32m+2[0m: Cinematic diagnostics reports duplicate step ids and invalid durations[0m                                                                                                                       
00:00 [32m+2[0m: Cinematic diagnostics reports legacy gameplay step leakage carried by metadata[0m                                                                                                               
00:00 [32m+3[0m: Cinematic diagnostics reports legacy gameplay step leakage carried by metadata[0m                                                                                                               
00:00 [32m+3[0m: Cinematic diagnostics accepts authoring draft marker without gameplay diagnostics[0m                                                                                                            
00:00 [32m+4[0m: Cinematic diagnostics accepts authoring draft marker without gameplay diagnostics[0m                                                                                                            
00:00 [32m+4[0m: Cinematic diagnostics reports duplicate cinematic ids in a collection[0m                                                                                                                        
00:00 [32m+5[0m: Cinematic diagnostics reports duplicate cinematic ids in a collection[0m                                                                                                                        
00:00 [32m+5[0m: Cinematic diagnostics reports unknown storyline, chapter, and map references[0m                                                                                                                 
00:00 [32m+6[0m: Cinematic diagnostics reports unknown storyline, chapter, and map references[0m                                                                                                                 
00:00 [32m+6[0m: Cinematic diagnostics reports legacy bridge without making it canonical runtime[0m                                                                                                              
00:00 [32m+7[0m: Cinematic diagnostics reports legacy bridge without making it canonical runtime[0m                                                                                                              
00:00 [32m+7[0m: All tests passed![0m                                                                                                                                                                            
```

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
```

Exit code: 0

```text

00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart                                                                                   
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart                                                                                   
00:01 +0: shows populated read-only cinematic builder shell                                                                                                                                            
00:02 +0: shows populated read-only cinematic builder shell                                                                                                                                            
00:02 +1: shows populated read-only cinematic builder shell                                                                                                                                            
00:02 +1: lists timeline steps in order with read-only details                                                                                                                                         
00:02 +2: lists timeline steps in order with read-only details                                                                                                                                         
00:02 +2: selects a step locally and updates read-only inspector                                                                                                                                       
00:02 +3: selects a step locally and updates read-only inspector                                                                                                                                       
00:02 +3: shows step diagnostics without enabling timeline changes                                                                                                                                     
00:02 +4: shows step diagnostics without enabling timeline changes                                                                                                                                     
00:02 +4: adds a safe draft after selected step and inspects it                                                                                                                                        
00:02 +5: adds a safe draft after selected step and inspects it                                                                                                                                        
00:02 +5: removes only the selected draft from the builder                                                                                                                                             
00:02 +6: removes only the selected draft from the builder                                                                                                                                             
00:02 +6: shows empty timeline state without authoring controls                                                                                                                                        
00:02 +7: shows empty timeline state without authoring controls                                                                                                                                        
00:02 +7: calls back to library from builder header                                                                                                                                                    
00:02 +8: calls back to library from builder header                                                                                                                                                    
00:02 +8: captures V1-43 builder timeline screenshot when requested                                                                                                                                    
00:02 +9: captures V1-43 builder timeline screenshot when requested                                                                                                                                    
00:02 +9: captures V1-44 builder draft screenshot when requested                                                                                                                                       
00:02 +10: captures V1-44 builder draft screenshot when requested                                                                                                                                      
00:02 +10: All tests passed!                                                                                                                                                                           
```

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematics_library_workspace_test.dart
```

Exit code: 0

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
00:02 +4: adds a draft from builder and refreshes library summary                                                                                                                                      
00:02 +5: adds a draft from builder and refreshes library summary                                                                                                                                      
00:02 +5: keeps legacy bridge out of canonical builder shell                                                                                                                                           
00:02 +6: keeps legacy bridge out of canonical builder shell                                                                                                                                           
00:02 +6: edits metadata and deletes only unused canonicals                                                                                                                                            
00:02 +7: edits metadata and deletes only unused canonicals                                                                                                                                            
00:02 +7: captures V1-38 Cinematics Library screenshot when requested                                                                                                                                  
00:02 +8: captures V1-38 Cinematics Library screenshot when requested                                                                                                                                  
00:02 +8: All tests passed!                                                                                                                                                                            
```

Verdict tests : les quatre commandes principales V1-44 ont un exit code 0.

## 19. Analyze relancé

```bash
cd packages/map_core && dart analyze
```

Exit code: 0

```text
Analyzing map_core...
No issues found!
```

```bash
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart lib/src/ui/canvas/narrative_workspace_canvas.dart test/cinematic_builder_workspace_test.dart test/cinematics_library_workspace_test.dart
```

Exit code: 0

```text
Analyzing 5 items...                                            
No issues found! (ran in 1.5s)
```

Verdict analyze : `map_core` et la cible editor V1-44 ont un exit code 0.

## 20. Checks anti-scope

```bash
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples
```

Exit code: 0

```text
<vide>
```

```bash
rg -n "PlayableMapGame|SceneRuntimeExecutor|SceneEventRuntimeHook|SceneCinematicRuntimeAwaitableAdapter|SceneCinematicRuntimeNoVisualPlayer|playCinematic" packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart || true
```

Exit code: 0

```text
<vide>
```

```bash
rg -n "drag|drop|TimelineEditor|scrubber|keyframe|reorder|moveUp|moveDown|copyWith\(.*GameState|PlayableMapGame" packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart packages/map_core/test/cinematic_authoring_operations_test.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart packages/map_editor/test/cinematic_builder_workspace_test.dart packages/map_editor/test/cinematics_library_workspace_test.dart || true
```

Exit code: 0

```text
<vide>
```

```bash
rg -n "CameraController|ActorResolver|AudioCue|FxPlayer|startBattle|setFact|WorldRule|teleport|giveItem|completeStoryStep" packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart || true
```

Exit code: 0

```text
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart:117:    void openWorldRules() {
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart:118:      editorNotifier.selectWorldRulesWorkspace();
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart:131:          onOpenWorldRules: openWorldRules,
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart:598:      EditorWorkspaceMode.facts => _buildFactsWorldRulesWorkspace(
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart:602:          initialMode: FactsWorldRulesWorkspaceMode.facts,
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart:604:      EditorWorkspaceMode.worldRules => _buildFactsWorldRulesWorkspace(
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart:608:          initialMode: FactsWorldRulesWorkspaceMode.worldRules,
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart:623:      onSelectWorldRules: openWorldRules,
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart:629:Widget _buildFactsWorldRulesWorkspace({
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart:633:  required FactsWorldRulesWorkspaceMode initialMode,
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart:641:  return FactsWorldRulesWorkspace(
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart:702:    onCreateWorldRule: ({
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart:706:      required WorldRuleSource source,
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart:707:      required WorldRuleTarget target,
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart:708:      required WorldRuleEffect effect,
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart:716:        final result = addWorldRule(
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart:736:    onUpdateWorldRule: ({
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart:741:      required WorldRuleSource source,
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart:742:      required WorldRuleTarget target,
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart:743:      required WorldRuleEffect effect,
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart:751:        final result = updateWorldRule(
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart:772:    onRemoveWorldRule: ({required String ruleId}) async {
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart:778:        final result = removeWorldRule(latest, ruleId: ruleId);
```

Interprétation : ces lignes `WorldRule` sont préexistantes dans le workspace Facts/World Rules de `narrative_workspace_canvas.dart`; elles ne viennent pas du lot V1-44 et ne sont pas du code authoring cinematic. La preuve ciblée sur les lignes ajoutées par le commit V1-44 est vide :

```bash
git show -U0 --format= --no-ext-diff HEAD -- packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart | rg '^\+[^+].*(CameraController|ActorResolver|AudioCue|FxPlayer|startBattle|setFact|WorldRule|teleport|giveItem|completeStoryStep)' || true
```

Exit code: 0

```text
<vide>
```

```bash
rg -n "Color\(|Colors\.|0xFF|0xff" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart || true
```

Exit code: 0

```text
<vide>
```

```bash
rg -n "selbrume|mael|maël|lysa|port_brisants|bourg_selbrume|phare|brume|marais" packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart packages/map_core/test/cinematic_authoring_operations_test.dart packages/map_core/test/cinematic_diagnostics_test.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart packages/map_editor/test/cinematic_builder_workspace_test.dart packages/map_editor/test/cinematics_library_workspace_test.dart reports/narrativeStudio/scenes/ns_scenes_v1_44_cinematic_timeline_authoring_drafts_v0.md || true
```

Exit code: 0

```text
<vide>
```

Verdict anti-scope : les recherches demandées ne montrent aucun couplage runtime, aucun vrai bloc métier ajouté par V1-44, aucune couleur hardcodée et aucune donnée produit nommée dans le périmètre contrôlé. Les occurrences `WorldRule` listées par la commande large appartiennent à un workspace préexistant et ne sont pas des lignes ajoutées par V1-44. Les opérations add/remove draft restent explicitement autorisées par le lot.

## 21. Git diff --check final

```bash
git diff --check
```

Exit code: 0

```text
<vide>
```

## 22. Git diff --stat final

```bash
git diff --stat
```

Exit code: 0

```text
<vide>
```

## 23. Git diff --name-only final

```bash
git diff --name-only
```

Exit code: 0

```text
<vide>
```

## 24. Git status final

```bash
git status --short --untracked-files=all
```

Exit code: 0

```text
?? reports/narrativeStudio/scenes/ns_scenes_v1_44_bis_cinematic_timeline_authoring_drafts_evidence_closure.md
```

## 25. Auto-review critique

1. Est-ce que le bis a modifié du code produit ?

   Non. Le final status ne montre que le rapport bis non tracké.
2. Est-ce que le rapport V1-44 est reproduit intégralement ?

   Oui. La section 6 reproduit le fichier complet.
3. Est-ce que les hunks des fichiers modifiés sont suffisamment complets ?

   Oui. Les sections 8 à 17 reproduisent les patches `git show` complets du commit V1-44 pour chaque fichier demandé.
4. Est-ce que la Visual Gate est prouvée ?

   Oui. Taille, type PNG et SHA-256 sont consignés.
5. Est-ce que les tests V1-44 passent encore ?

   Oui si les commandes de la section 18 ont toutes exit code 0.
6. Est-ce que l’analyze ciblé passe encore ?

   Oui si les commandes de la section 19 ont toutes exit code 0.
7. Est-ce qu’aucun package runtime/gameplay/battle/examples n’est modifié ?

   Oui. Le check dédié rend une sortie vide.
8. Est-ce qu’aucun runtime n’est couplé au Builder ?

   Oui. La recherche anti-runtime rend une sortie vide.
9. Est-ce qu’aucun vrai bloc métier n’a été ajouté ?

   Oui. La commande large retrouve des lignes `WorldRule` préexistantes dans `narrative_workspace_canvas.dart`, mais la preuve ciblée sur les lignes ajoutées par V1-44 rend une sortie vide.
10. Est-ce que la suppression reste limitée aux brouillons ?

   Oui. Les hunks core montrent la garde `isCinematicTimelineDraftStep` avant suppression.
11. Est-ce qu’aucun drag/drop/réordonnancement n’a été ajouté ?

   Oui. La recherche anti-rich timeline editor rend une sortie vide.
12. Est-ce qu’aucune couleur hardcodée n’a été ajoutée ?

   Oui. La recherche anti-couleurs rend une sortie vide.
13. Est-ce qu’aucune donnée Selbrume n’apparaît ?

   Oui. La recherche anti-données produit rend une sortie vide.
14. Est-ce que V1-44 peut être commité ?

   Oui, le commit V1-44 existe déjà en HEAD et ce bis conclut qu’il est clôturable.

## 26. Verdict de clôture V1-44

Verdict : V1-44 est clôturable. Le bis ne modifie pas la feature, ne modifie pas le code, prouve le rapport V1-44, les hunks du commit, la capture, les tests, les analyses, les checks anti-scope et le statut Git final.
