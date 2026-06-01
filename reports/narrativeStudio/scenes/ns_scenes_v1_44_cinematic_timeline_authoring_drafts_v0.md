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
