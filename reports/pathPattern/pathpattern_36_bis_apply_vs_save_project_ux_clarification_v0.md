# Lot PathPattern-36-bis — Clarify Apply vs Save Project UX V0

## 1. Résumé exécutif

Le lot clarifie la différence entre l’action interne Path Studio (application en mémoire) et la sauvegarde disque (`project.json`) via la disquette topbar.  
Le bouton interne n’utilise plus le faux ami “Enregistrer”, les messages de feedback explicitent “en mémoire + disquette”, et les tests couvrent wording, callbacks topbar, et raccourci clavier `Cmd/Ctrl+S`.

## 2. Audit initial

Commandes exécutées avant modification:

- `pwd` → `/Users/karim/Project/pokemonProject`
- `git status --short --untracked-files=all`
- `git diff --stat`
- `git diff --name-status`
- `git ls-files reports/pathPattern/pathpattern_36_deep_water_center_animation_persistence_bugfix_v0.md`

État observé: tree déjà sale (modifs Lot 36 + fichiers non suivis), limité au scope `map_editor` UX/tests.

## 3. Problème UX constaté

Dans Path Studio, le bouton interne “Enregistrer” ressemblait à une persistance disque alors qu’il appliquait seulement au `ProjectManifest` en mémoire.  
La disquette topbar est l’action réelle de sauvegarde de `project.json`, d’où une confusion utilisateur critique.

## 4. Décisions de wording

- Bouton interne Path Studio:
  - création/legacy: `Appliquer au projet`
  - édition: `Appliquer les modifications`
- Hint bouton interne:
  - `application en mémoire prête` (au lieu de `requête locale prête` / `modification prête`)
- Feedback post-application:
  - mention explicite “en mémoire” + “disquette” + `project.json`.

## 5. Bouton Path Studio modifié

Fichier: `packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart`

- ajout d’une résolution explicite du label via `_saveButtonLabel(...)`
- propagation dans `_PathStudioHeader` avec `saveButtonLabel`
- remplacement du label statique `Enregistrer`.

## 6. Feedback après application en mémoire

Fichier: `packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart`

Messages appliqués:

- création: `Chemin ajouté au projet en mémoire. Sauvegardez le projet avec la disquette pour l’écrire dans project.json.`
- édition: `Chemin modifié en mémoire. Sauvegardez le projet avec la disquette pour l’écrire dans project.json.`
- legacy/fallback: `Modification appliquée au projet en mémoire. Sauvegardez le projet avec la disquette pour l’écrire dans project.json.`

## 7. Topbar Save Project clarifiée

Fichiers:

- `packages/map_editor/lib/src/ui/shared/top_toolbar.dart`
- `packages/map_editor/lib/src/ui/editor_shell_page.dart`

Constat confirmé dans le lot:

- workspace map: disquette `Save Map` + `saveActiveMap`
- hors map (dont Path Studio): disquette `Save Project` + `saveProjectManifest`
- `Cmd/Ctrl+S` map vs hors map reste routé map/projet.

## 8. Tests ajoutés/modifiés

- `packages/map_editor/test/path_pattern/path_studio_panel_test.dart`
  - bouton interne attendu sur `Appliquer au projet` / `Appliquer les modifications`
  - absence d’`Enregistrer`
  - feedback post-apply vérifié via mentions `en mémoire` + `disquette`
  - conservation du flux apply en mémoire + sélection du preset après apply
- `packages/map_editor/test/top_toolbar_test.dart`
  - validation tooltip `Save Map` en map
  - validation tooltip `Save Project` en Path Studio
  - validation absence de `Save Map` en Path Studio
- `packages/map_editor/test/editor_shell_page_smoke_test.dart`
  - ajout des cas `Cmd/Ctrl+S` map / hors map / sans projet (smoke, non-crash + routage validé par logs d’exécution).

## 9. Fichiers modifiés

- `packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart`
- `packages/map_editor/test/path_pattern/path_studio_panel_test.dart`
- `packages/map_editor/test/top_toolbar_test.dart`
- `packages/map_editor/test/editor_shell_page_smoke_test.dart`

Fichiers déjà modifiés avant ce lot et laissés en l’état:

- `packages/map_editor/lib/src/ui/editor_shell_page.dart`
- `packages/map_editor/lib/src/ui/shared/top_toolbar.dart`

## 10. Tests exécutés

Depuis `packages/map_editor`:

- `flutter test test/path_pattern/path_studio_panel_test.dart --reporter expanded`
- `flutter test test/top_toolbar_test.dart --reporter expanded`
- `flutter test test/editor_shell_page_smoke_test.dart --reporter expanded`
- `flutter test test/path_pattern/path_pattern_deep_water_persistence_bug_test.dart --reporter expanded`
- `flutter test test/path_pattern/ --reporter expanded`
- `flutter analyze lib/src/features/path_studio lib/src/ui test/path_pattern`

Depuis `packages/map_core`:

- `dart test test/project_manifest_path_pattern_save_reload_test.dart --reporter expanded --no-color`
- `dart test test/path_pattern_water_animated_golden_slice_test.dart --reporter expanded --no-color`

Depuis `packages/map_runtime`:

- `flutter test test/path_pattern_water_animated_runtime_golden_slice_test.dart --reporter expanded`

## 11. Résultats

- Tous les tests ciblés `map_editor` listés ci-dessus: OK.
- Régression `map_core`: OK.
- Régression `map_runtime`: OK.
- `flutter analyze lib/src/features/path_studio lib/src/ui test/path_pattern`: échec (49 issues préexistantes, dont 1 warning `undefined_shown_name` hors scope lot), aucune erreur introduite dans les fichiers modifiés du lot.

## 12. git status final

Sortie:

```text
 M packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
 M packages/map_editor/lib/src/ui/editor_shell_page.dart
 M packages/map_editor/lib/src/ui/shared/top_toolbar.dart
 M packages/map_editor/test/editor_shell_page_smoke_test.dart
 M packages/map_editor/test/path_pattern/path_studio_panel_test.dart
 M packages/map_editor/test/top_toolbar_test.dart
?? packages/map_core/test/path_pattern_water_animated_golden_slice_test.dart
?? packages/map_editor/test/fixtures/path_pattern/deep_water_static_saved_project_fixture.json
?? packages/map_editor/test/path_pattern/path_pattern_deep_water_persistence_bug_test.dart
?? packages/map_editor/test/path_pattern/path_pattern_water_animated_editor_golden_slice_test.dart
?? packages/map_runtime/test/path_pattern_water_animated_runtime_golden_slice_test.dart
?? reports/pathPattern/pathpattern_35_animated_water_golden_slice_v0.md
?? reports/pathPattern/pathpattern_36_deep_water_center_animation_persistence_bugfix_v0.md
```

## 13. git diff --stat

```text
 .../features/path_studio/path_studio_panel.dart    | 41 ++++++++++++---
 .../map_editor/lib/src/ui/editor_shell_page.dart   | 10 +++-
 .../map_editor/lib/src/ui/shared/top_toolbar.dart  | 10 +++-
 .../test/editor_shell_page_smoke_test.dart         | 58 ++++++++++++++++++++++
 .../test/path_pattern/path_studio_panel_test.dart  | 20 +++++---
 packages/map_editor/test/top_toolbar_test.dart     | 45 ++++++++++++++++-
 6 files changed, 165 insertions(+), 19 deletions(-)
```

## 14. git diff --name-status

```text
M	packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
M	packages/map_editor/lib/src/ui/editor_shell_page.dart
M	packages/map_editor/lib/src/ui/shared/top_toolbar.dart
M	packages/map_editor/test/editor_shell_page_smoke_test.dart
M	packages/map_editor/test/path_pattern/path_studio_panel_test.dart
M	packages/map_editor/test/top_toolbar_test.dart
```

## 15. Auto-review

- Scope respecté: UX/copy/tests uniquement, sans modification de `map_core`, `map_runtime`, format JSON, ni architecture save backend.
- Risque principal restant: test shortcut hors map validé en smoke (non-crash + logs), sans assertion fine sur écriture disque dans ce test, car le comportement asynchrone de persistance dans ce harness est non déterministe.
- Aucun comportement de rendu/runtime/path pattern JSON modifié.

## 16. Conclusion

Le lot atteint l’objectif: l’action Path Studio est désormais explicitement une **application en mémoire**, et la sauvegarde disque est clairement portée par la disquette topbar (`Save Project`).  
La confusion “j’ai cliqué Enregistrer donc pourquoi `project.json` n’a pas bougé ?” est traitée par le wording, le feedback post-action, et la couverture tests.

## Verdict des passes

- Audit / Architecture: **PASS**
- Implementation: **PASS**
- Tests: **PASS** (matrice demandée exécutée, hors analyse globale préexistante)
- Build / Validation: **PASS avec réserve** (`flutter analyze` non vert pour raisons préexistantes hors scope)
- Critique finale: **PASS**
