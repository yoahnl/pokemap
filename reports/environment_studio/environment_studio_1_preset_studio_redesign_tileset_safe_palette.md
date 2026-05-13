# EnvironmentStudio-1 — Preset Studio Redesign / Tileset-Safe Palette Editor V0

## 1. Résumé

Environment Studio a été recentré sur son rôle d’atelier de presets :

- header compact avec un seul titre `Environment Studio` ;
- sous-titre `Presets d’environnements réutilisables` ;
- banner produit indiquant que les presets se préparent ici et que la peinture/génération se font dans l’éditeur de carte ;
- colonne `Presets` avec bouton `Nouveau preset` ;
- panneau `Éditer le preset` avec `Identité`, `Paramètres par défaut`, `Tileset source`, `Palette du preset`, `Diagnostics (preset)` ;
- suppression des textes UI obsolètes `Lecture seule`, `arrivent dans les prochains lots`, `génération sur carte reste à venir` ;
- helper pur de compatibilité tileset pour les palettes de preset ;
- filtre du picker d’éléments de palette selon le tileset source ;
- validation applicative qui bloque un brouillon mélangeant plusieurs tilesets, même via saisie manuelle ;
- diagnostics UI pour les presets déjà mixtes et marquage des items incompatibles.

## 2. Rappel de la décision UX

- Environment Studio prépare les presets.
- Map Editor / TileLayer inspector utilise les presets sur les cartes.
- Aucune peinture ni génération sur carte n’a été remise dans Environment Studio.
- L’Environment Studio protège la palette contre le mélange d’éléments provenant de tilesets différents.
- Aucun champ persistant `sourceTilesetId` n’a été ajouté.
- Aucun modèle `map_core` n’a été modifié.

## 3. Orchestration sub-agents

| Passe | Rôle | Conclusion |
|---|---|---|
| Sub-agent A — Audit UI / IA | Inspecter le shell Studio, les widgets, tests et textes obsolètes | Le point d’entrée `EnvironmentStudioWorkspace` reste sain. Le changement doit rester local à `EnvironmentStudioPanel` et widgets Studio. Les textes `Lecture seule` / `prochains lots` sont obsolètes. |
| Sub-agent B — Preset / Tileset Compatibility | Auditer `EnvironmentPreset`, `EnvironmentPaletteItem`, `ProjectElementEntry` | Le tileset source doit être dérivé de `ProjectElementEntry.frames.first.tilesetId` si non vide, sinon `ProjectElementEntry.tilesetId`. Pas besoin de champ persistant. |
| Sub-agent C — UI Redesign Local | Proposer une refonte locale compacte | Garder le layout liste/détail existant, déplacer le bouton dans la colonne presets, remplacer la bannière, supprimer le bloc `Bientôt`. |
| Sub-agent D — Palette Editor Safety | Vérifier picker, saisie manuelle et save | Le picker seul ne suffit pas. Il faut aussi bloquer la validation du brouillon mixte avant l’upsert manifest mémoire. |
| Passe E — QA / Evidence Pack | Tests, analyse, diff, rapport | `flutter test test/environment_studio` échoue sur deux dettes hors lot reproduites isolément. La matrice ciblée Studio + Golden Slice passe. |

Stratégie retenue avant codage :

1. Écran actuel : panel central avec bannière read-only obsolète, bouton hors colonne, détail read-only, draft mémoire.
2. Écran cible : header compact, banner produit, colonne presets, détail preset, sections explicites.
3. Tileset source : premier élément valide de la palette dont le tileset est résolu.
4. Filtre compatible : si source connue, le picker ne propose que les éléments du même tileset ; si source inconnue, il propose les éléments avec source claire.
5. Guard applicatif : `validateEnvironmentPresetDraft` ajoute une erreur `mixedPaletteTilesets`.
6. Fichiers à modifier : widgets Studio, draft validation, tests Environment Studio.
7. Limite : les presets existants mixtes ne sont pas nettoyés automatiquement.

## 4. Audit de l’existant

Fichiers inspectés :

- `packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart`
- `packages/map_editor/lib/src/features/environment_studio/environment_studio_workspace.dart`
- `packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_detail.dart`
- `packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_list.dart`
- `packages/map_editor/lib/src/features/environment_studio/widgets/environment_palette_item_view.dart`
- `packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart`
- `packages/map_editor/lib/src/features/environment_studio/widgets/environment_palette_item_draft_editor.dart`
- `packages/map_editor/lib/src/features/environment_studio/authoring/environment_preset_draft.dart`
- `packages/map_core/lib/src/models/environment.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/validation/validators.dart`
- `packages/map_core/lib/src/operations/environment_preset_diagnostics.dart`
- tests Environment Studio existants dans `packages/map_editor/test/environment_studio/`

UI existante :

- `EnvironmentStudioWorkspace` lit le manifest et monte `EnvironmentStudioPanel`.
- `EnvironmentStudioPanel` avait trois modes locaux : browser, createDraft, editDraft.
- Le browser affichait déjà une liste de presets et un détail.
- Le détail parlait `Détail du preset`.
- Le bouton disait `Préparer un preset`.
- La bannière disait `Lecture seule... arrivent dans les prochains lots`.
- Un bloc `Bientôt` annonçait des capacités déjà partiellement présentes ou hors scope.

Modèles impliqués :

- `EnvironmentPreset.palette` contient des `EnvironmentPaletteItem.elementId`.
- `ProjectElementEntry` porte `tilesetId`.
- `TilesetVisualFrame.tilesetId` peut surcharger le tileset parent si non vide.
- `EnvironmentPreset` ne doit pas recevoir de nouveau champ persistant dans ce lot.

Dettes identifiées hors lot :

- `flutter test test/environment_studio` échoue déjà sur `environment_layer_area_model_editing_test.dart` avec un tap off-screen et `Bad state: No element`.
- `flutter test test/environment_studio/tile_layer_environment_erase_mode_test.dart` échoue déjà avec `Expected: null` / `Actual: EnvironmentMaskEditMode.erase`.
- Ces deux fichiers n’ont pas été modifiés par EnvironmentStudio-1.

## 5. Nouvelle architecture UI

Header :

- `Environment Studio`
- `Presets d’environnements réutilisables`
- compteur de presets

Info banner :

- `Les presets se préparent ici. La peinture et la génération se font dans l’éditeur de carte.`

Preset browser :

- colonne gauche `Presets`
- bouton `Nouveau preset`
- rows compactes avec nom, catégorie et nombre d’éléments
- diagnostics de row conservés

Detail editor :

- titre `Éditer le preset`
- `Identité`
- `Paramètres par défaut`
- `Tileset source`
- `Palette du preset`
- `Diagnostics (preset)`

Draft editor :

- libellés alignés avec le nouveau wording : `Paramètres par défaut`, `Palette du preset`
- bloc `Tileset source` visible avant le picker
- message de protection anti-mélange visible dans le brouillon

## 6. Tileset safety

Calcul du tileset source :

- `resolveEnvironmentPresetElementTilesetId(ProjectElementEntry)` lit d’abord `element.frames.first.tilesetId.trim()` si une frame existe et si cette valeur est non vide.
- Sinon, il utilise `element.tilesetId.trim()`.
- Une valeur vide ou absente produit une source inconnue.
- Le premier élément palette valide avec source claire devient `sourceTilesetId`.

Filtrage picker :

- Si `sourceTilesetId == null`, le picker propose les éléments du projet qui ont une source tileset claire.
- Si `sourceTilesetId != null`, le picker propose seulement les éléments dont la source tileset résolue est égale à `sourceTilesetId`.
- Les éléments sans source claire sont exclus du picker compatible.

Presets mixtes :

- Le preset existant n’est pas modifié.
- Le panneau détail affiche `Ce preset contient des éléments provenant de plusieurs tilesets.`
- Les rows incompatibles reçoivent le chip `Tileset incompatible`.
- Le draft de palette mixte produit une erreur `Tilesets mélangés`.
- Le bouton `Ajouter au projet en mémoire` reste désactivé tant que cette erreur est présente.

UI-only vs applicatif :

- UI-only : banner, bloc tileset source, warning de preset mixte, chip row incompatible, picker filtré.
- Applicatif : validation `validateEnvironmentPresetDraft` avec `EnvironmentPresetDraftIssueKind.mixedPaletteTilesets`, utilisée avant `buildEnvironmentPresetFromDraft` et `upsertProjectEnvironmentPreset`.

## 7. Tests

### RED initial

Commande :

```bash
cd packages/map_editor
flutter test test/environment_studio/environment_preset_tileset_compatibility_test.dart
```

Résultat exact utile :

```text
test/environment_studio/environment_preset_tileset_compatibility_test.dart:3:8: Error: Error when reading 'lib/src/features/environment_studio/authoring/environment_preset_tileset_compatibility.dart': No such file or directory
Error: Method not found: 'buildEnvironmentPresetTilesetCompatibility'.
00:00 +0 -1: Some tests failed.
```

### Helper tileset compatibility

Commande :

```bash
cd packages/map_editor
flutter test test/environment_studio/environment_preset_tileset_compatibility_test.dart
```

Résultat :

```text
00:00 +7: All tests passed!
```

Cas couverts :

- preset vide ;
- source issue d’un seul élément ;
- plusieurs éléments du même tileset ;
- surcharge par `frames.first.tilesetId` ;
- mélange de tilesets ;
- élément palette introuvable ;
- élément sans source tileset claire exclu du picker.

### Draft validation

Commande :

```bash
cd packages/map_editor
flutter test test/environment_studio/environment_preset_draft_test.dart
```

Résultat :

```text
00:00 +44: All tests passed!
```

Cas ajouté :

- `mixedPaletteTilesets` bloque un brouillon qui mélange deux tilesets.

### Palette draft editor

Commande :

```bash
cd packages/map_editor
flutter test test/environment_studio/environment_preset_palette_draft_editor_test.dart
```

Résultat :

```text
00:02 +12: All tests passed!
```

Cas ajoutés :

- picker filtré par tileset source ;
- saisie manuelle incompatible détectée par validation.

### Save to manifest

Commande :

```bash
cd packages/map_editor
flutter test test/environment_studio/environment_preset_save_to_manifest_test.dart
```

Résultat :

```text
00:02 +13: All tests passed!
```

Sortie non bloquante attendue dans ce fichier : le test `callback qui lève` imprime volontairement `EnvironmentPresetDraftForm: ajout mémoire impossible: Bad state: simulé` et vérifie l’erreur locale.

Cas ajouté :

- palette mixte tilesets : bouton save désactivé, callback non invoqué.

### Browser / workspace / creation form

Commande :

```bash
cd packages/map_editor
flutter test test/environment_studio/environment_studio_preset_browser_test.dart
flutter test test/environment_studio/environment_studio_workspace_test.dart test/environment_studio/environment_studio_preset_creation_form_test.dart
```

Résultats :

```text
00:00 +9: All tests passed!
00:01 +14: All tests passed!
```

Cas couverts :

- sections `Identité`, `Paramètres par défaut`, `Tileset source`, `Palette du preset`, `Diagnostics` visibles ;
- `Éditer le preset` visible ;
- `Protection anti-mélange de tilesets activée` visible ;
- warning pour preset mixte ;
- bouton `Nouveau preset` ;
- disparition des textes obsolètes.

### Matrice ciblée Studio

Commande :

```bash
cd packages/map_editor
flutter test test/environment_studio/environment_preset_tileset_compatibility_test.dart test/environment_studio/environment_preset_draft_test.dart test/environment_studio/environment_preset_palette_draft_editor_test.dart test/environment_studio/environment_preset_save_to_manifest_test.dart test/environment_studio/environment_studio_preset_browser_test.dart test/environment_studio/environment_studio_preset_creation_form_test.dart test/environment_studio/environment_generation_params_draft_editor_test.dart test/environment_studio/environment_studio_workspace_test.dart test/environment_studio/environment_studio_workspace_entry_test.dart
```

Résultat :

```text
00:04 +110: All tests passed!
```

Sorties non bloquantes observées :

```text
EnvironmentPresetDraftForm: ajout mémoire impossible: Bad state: simulé
Warning: Falling back on slow accent color resolution.
```

Ces sorties proviennent de tests existants qui simulent une exception de callback et de `macos_ui`.

### Commande globale demandée

Commande :

```bash
cd packages/map_editor
flutter test test/environment_studio
```

Résultat :

```text
Exit code: 1
00:17 +521 -2: Some tests failed.
```

Messages d’échec reproduits :

```text
test/environment_studio/environment_layer_area_model_editing_test.dart
The following StateError was thrown running a test:
Bad state: No element
The test description was:
  ajout zone via picker + affichage + dirty
```

```text
test/environment_studio/tile_layer_environment_erase_mode_test.dart
Expected: null
  Actual: EnvironmentMaskEditMode:<EnvironmentMaskEditMode.erase>
The test description was:
  refuse si aucune area est sélectionnée
```

Reproduction isolée :

```bash
cd packages/map_editor
flutter test test/environment_studio/environment_layer_area_model_editing_test.dart
```

Résultat :

```text
00:01 +15 -1: Some tests failed.
The following StateError was thrown running a test:
Bad state: No element
The test description was:
  ajout zone via picker + affichage + dirty
```

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_erase_mode_test.dart
```

Résultat :

```text
00:00 +5 -1: Some tests failed.
Expected: null
  Actual: EnvironmentMaskEditMode:<EnvironmentMaskEditMode.erase>
The test description was:
  refuse si aucune area est sélectionnée
```

Interprétation :

- Ces échecs sont hors lot : fichiers non modifiés, chemins TileLayer inspector/notifier, pas Environment Studio.
- Ils sont documentés comme dettes préexistantes à traiter séparément.

### Non-régressions Environment critiques

Commande :

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_inspector_section_test.dart test/environment_studio/environment_golden_slice_workflow_test.dart test/environment_studio/tile_layer_environment_golden_slice_save_reload_test.dart test/environment_studio/tile_layer_environment_area_management_use_case_test.dart test/environment_studio/tile_layer_environment_area_management_notifier_test.dart test/environment_studio/tile_layer_environment_attachment_safety_test.dart
```

Résultat :

```text
00:02 +90: All tests passed!
```

## 8. Analyse ciblée

Première commande :

```bash
cd packages/map_editor
flutter analyze lib/src/features/environment_studio/authoring/environment_preset_draft.dart lib/src/features/environment_studio/authoring/environment_preset_tileset_compatibility.dart lib/src/features/environment_studio/environment_studio_panel.dart lib/src/features/environment_studio/widgets/environment_generation_params_draft_editor.dart lib/src/features/environment_studio/widgets/environment_palette_item_view.dart lib/src/features/environment_studio/widgets/environment_preset_detail.dart lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart lib/src/features/environment_studio/widgets/environment_preset_draft_presentation.dart lib/src/features/environment_studio/widgets/environment_preset_list.dart test/environment_studio/environment_generation_params_draft_editor_test.dart test/environment_studio/environment_preset_draft_test.dart test/environment_studio/environment_preset_palette_draft_editor_test.dart test/environment_studio/environment_preset_save_to_manifest_test.dart test/environment_studio/environment_studio_preset_browser_test.dart test/environment_studio/environment_studio_preset_creation_form_test.dart test/environment_studio/environment_studio_workspace_test.dart test/environment_studio/environment_preset_tileset_compatibility_test.dart
```

Résultat :

```text
Analyzing 17 items...

   info • Use the '??' operator rather than '?:' when testing for 'null' • lib/src/features/environment_studio/widgets/environment_preset_detail.dart:248:11 • prefer_if_null_operators

1 issue found. (ran in 2.0s)
```

Correction appliquée :

- remplacement de `source == null ? 'Tileset source non défini' : source` par `source ?? 'Tileset source non défini'`.

Commande relancée :

```bash
cd packages/map_editor
flutter analyze lib/src/features/environment_studio/authoring/environment_preset_draft.dart lib/src/features/environment_studio/authoring/environment_preset_tileset_compatibility.dart lib/src/features/environment_studio/environment_studio_panel.dart lib/src/features/environment_studio/widgets/environment_generation_params_draft_editor.dart lib/src/features/environment_studio/widgets/environment_palette_item_view.dart lib/src/features/environment_studio/widgets/environment_preset_detail.dart lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart lib/src/features/environment_studio/widgets/environment_preset_draft_presentation.dart lib/src/features/environment_studio/widgets/environment_preset_list.dart test/environment_studio/environment_generation_params_draft_editor_test.dart test/environment_studio/environment_preset_draft_test.dart test/environment_studio/environment_preset_palette_draft_editor_test.dart test/environment_studio/environment_preset_save_to_manifest_test.dart test/environment_studio/environment_studio_preset_browser_test.dart test/environment_studio/environment_studio_preset_creation_form_test.dart test/environment_studio/environment_studio_workspace_test.dart test/environment_studio/environment_preset_tileset_compatibility_test.dart
```

Résultat final :

```text
Analyzing 17 items...
No issues found! (ran in 1.3s)
```

## 9. Fichiers créés/modifiés

Fichiers créés par EnvironmentStudio-1 :

- `packages/map_editor/lib/src/features/environment_studio/authoring/environment_preset_tileset_compatibility.dart`
- `packages/map_editor/test/environment_studio/environment_preset_tileset_compatibility_test.dart`
- `reports/environment_studio/environment_studio_1_preset_studio_redesign_tileset_safe_palette.md`

Fichiers modifiés par EnvironmentStudio-1 :

- `packages/map_editor/lib/src/features/environment_studio/authoring/environment_preset_draft.dart`
- `packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart`
- `packages/map_editor/lib/src/features/environment_studio/widgets/environment_generation_params_draft_editor.dart`
- `packages/map_editor/lib/src/features/environment_studio/widgets/environment_palette_item_view.dart`
- `packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_detail.dart`
- `packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart`
- `packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_draft_presentation.dart`
- `packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_list.dart`
- `packages/map_editor/test/environment_studio/environment_generation_params_draft_editor_test.dart`
- `packages/map_editor/test/environment_studio/environment_preset_draft_test.dart`
- `packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart`
- `packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart`
- `packages/map_editor/test/environment_studio/environment_studio_preset_browser_test.dart`
- `packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart`
- `packages/map_editor/test/environment_studio/environment_studio_workspace_test.dart`

Fichiers préexistants dans le worktree non touchés :

- Aucun fichier modifié ou non suivi n’était présent au `git status --short --untracked-files=all` initial.

Dettes préexistantes hors lot :

- `packages/map_editor/test/environment_studio/environment_layer_area_model_editing_test.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_erase_mode_test.dart`

Ces fichiers n’ont pas été modifiés.

## 10. Non-objectifs respectés

- Pas de peinture/génération dans Environment Studio.
- Pas de modification `map_core`.
- Pas de modification `ProjectManifest`.
- Pas de nouveau champ JSON persistant.
- Pas de modification `map_runtime`, `map_gameplay`, `map_battle`.
- Pas de modification canvas.
- Pas de modification du workflow TileLayer inspector.
- Pas de modification des use cases generate / clear / regenerate / shuffle.
- Pas de modification add/delete individuel.
- Pas de build_runner.
- Pas de generated files.
- Pas de sauvegarde disque nouvelle.
- Pas de refonte left sidebar ou top toolbar.

## 11. Evidence pack

### git status initial

Commande :

```bash
git status --short --untracked-files=all
```

Résultat exact :

```text
```

Aucune ligne affichée.

### git status final

Commande :

```bash
git status --short --untracked-files=all
```

Résultat exact à jour après création du rapport :

```text
 M packages/map_editor/lib/src/features/environment_studio/authoring/environment_preset_draft.dart
 M packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart
 M packages/map_editor/lib/src/features/environment_studio/widgets/environment_generation_params_draft_editor.dart
 M packages/map_editor/lib/src/features/environment_studio/widgets/environment_palette_item_view.dart
 M packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_detail.dart
 M packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart
 M packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_draft_presentation.dart
 M packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_list.dart
 M packages/map_editor/test/environment_studio/environment_generation_params_draft_editor_test.dart
 M packages/map_editor/test/environment_studio/environment_preset_draft_test.dart
 M packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart
 M packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart
 M packages/map_editor/test/environment_studio/environment_studio_preset_browser_test.dart
 M packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart
 M packages/map_editor/test/environment_studio/environment_studio_workspace_test.dart
?? packages/map_editor/lib/src/features/environment_studio/authoring/environment_preset_tileset_compatibility.dart
?? packages/map_editor/test/environment_studio/environment_preset_tileset_compatibility_test.dart
?? reports/environment_studio/environment_studio_1_preset_studio_redesign_tileset_safe_palette.md
```

### git diff --stat

Commande :

```bash
git diff --stat
```

Résultat exact :

```text
 .../authoring/environment_preset_draft.dart        |  19 +++
 .../environment_studio_panel.dart                  | 157 ++++++++++-----------
 ...environment_generation_params_draft_editor.dart |   2 +-
 .../widgets/environment_palette_item_view.dart     |  38 ++++-
 .../widgets/environment_preset_detail.dart         | 110 ++++++++++++++-
 .../widgets/environment_preset_draft_form.dart     |  89 +++++++++++-
 .../environment_preset_draft_presentation.dart     |   1 +
 .../widgets/environment_preset_list.dart           |   4 +-
 ...onment_generation_params_draft_editor_test.dart |   2 +-
 .../environment_preset_draft_test.dart             |  38 ++++-
 ...vironment_preset_palette_draft_editor_test.dart |  94 +++++++++++-
 .../environment_preset_save_to_manifest_test.dart  |  75 +++++++++-
 .../environment_studio_preset_browser_test.dart    |  66 ++++++++-
 ...vironment_studio_preset_creation_form_test.dart |  14 +-
 .../environment_studio_workspace_test.dart         |  28 ++--
 15 files changed, 613 insertions(+), 124 deletions(-)
```

Note : cette commande ne liste pas les fichiers non suivis. Les fichiers créés apparaissent dans `git status final`.

### git diff --name-only

Commande :

```bash
git diff --name-only
```

Résultat exact :

```text
packages/map_editor/lib/src/features/environment_studio/authoring/environment_preset_draft.dart
packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart
packages/map_editor/lib/src/features/environment_studio/widgets/environment_generation_params_draft_editor.dart
packages/map_editor/lib/src/features/environment_studio/widgets/environment_palette_item_view.dart
packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_detail.dart
packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart
packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_draft_presentation.dart
packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_list.dart
packages/map_editor/test/environment_studio/environment_generation_params_draft_editor_test.dart
packages/map_editor/test/environment_studio/environment_preset_draft_test.dart
packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart
packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart
packages/map_editor/test/environment_studio/environment_studio_preset_browser_test.dart
packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart
packages/map_editor/test/environment_studio/environment_studio_workspace_test.dart
```

### git diff --check

Commande :

```bash
git diff --check
```

Résultat exact :

```text
```

Aucune ligne affichée.

### Commandes principales

```bash
cd packages/map_editor
dart format lib/src/features/environment_studio/authoring/environment_preset_draft.dart lib/src/features/environment_studio/authoring/environment_preset_tileset_compatibility.dart lib/src/features/environment_studio/environment_studio_panel.dart lib/src/features/environment_studio/widgets/environment_generation_params_draft_editor.dart lib/src/features/environment_studio/widgets/environment_palette_item_view.dart lib/src/features/environment_studio/widgets/environment_preset_detail.dart lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart lib/src/features/environment_studio/widgets/environment_preset_draft_presentation.dart lib/src/features/environment_studio/widgets/environment_preset_list.dart test/environment_studio/environment_generation_params_draft_editor_test.dart test/environment_studio/environment_preset_draft_test.dart test/environment_studio/environment_preset_palette_draft_editor_test.dart test/environment_studio/environment_preset_save_to_manifest_test.dart test/environment_studio/environment_studio_preset_browser_test.dart test/environment_studio/environment_studio_preset_creation_form_test.dart test/environment_studio/environment_studio_workspace_test.dart test/environment_studio/environment_preset_tileset_compatibility_test.dart
flutter test test/environment_studio/environment_preset_tileset_compatibility_test.dart
flutter test test/environment_studio/environment_preset_draft_test.dart
flutter test test/environment_studio/environment_preset_palette_draft_editor_test.dart
flutter test test/environment_studio/environment_preset_save_to_manifest_test.dart
flutter test test/environment_studio/environment_studio_preset_browser_test.dart
flutter test test/environment_studio/environment_studio_workspace_test.dart test/environment_studio/environment_studio_preset_creation_form_test.dart
flutter test test/environment_studio
flutter test test/environment_studio/environment_layer_area_model_editing_test.dart
flutter test test/environment_studio/tile_layer_environment_erase_mode_test.dart
flutter test test/environment_studio/environment_preset_tileset_compatibility_test.dart test/environment_studio/environment_preset_draft_test.dart test/environment_studio/environment_preset_palette_draft_editor_test.dart test/environment_studio/environment_preset_save_to_manifest_test.dart test/environment_studio/environment_studio_preset_browser_test.dart test/environment_studio/environment_studio_preset_creation_form_test.dart test/environment_studio/environment_generation_params_draft_editor_test.dart test/environment_studio/environment_studio_workspace_test.dart test/environment_studio/environment_studio_workspace_entry_test.dart
flutter test test/environment_studio/tile_layer_environment_inspector_section_test.dart test/environment_studio/environment_golden_slice_workflow_test.dart test/environment_studio/tile_layer_environment_golden_slice_save_reload_test.dart test/environment_studio/tile_layer_environment_area_management_use_case_test.dart test/environment_studio/tile_layer_environment_area_management_notifier_test.dart test/environment_studio/tile_layer_environment_attachment_safety_test.dart
flutter analyze lib/src/features/environment_studio/authoring/environment_preset_draft.dart lib/src/features/environment_studio/authoring/environment_preset_tileset_compatibility.dart lib/src/features/environment_studio/environment_studio_panel.dart lib/src/features/environment_studio/widgets/environment_generation_params_draft_editor.dart lib/src/features/environment_studio/widgets/environment_palette_item_view.dart lib/src/features/environment_studio/widgets/environment_preset_detail.dart lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart lib/src/features/environment_studio/widgets/environment_preset_draft_presentation.dart lib/src/features/environment_studio/widgets/environment_preset_list.dart test/environment_studio/environment_generation_params_draft_editor_test.dart test/environment_studio/environment_preset_draft_test.dart test/environment_studio/environment_preset_palette_draft_editor_test.dart test/environment_studio/environment_preset_save_to_manifest_test.dart test/environment_studio/environment_studio_preset_browser_test.dart test/environment_studio/environment_studio_preset_creation_form_test.dart test/environment_studio/environment_studio_workspace_test.dart test/environment_studio/environment_preset_tileset_compatibility_test.dart
git diff --check
git status --short --untracked-files=all
```

## 12. Diff pertinent

### Nouveau fichier complet : `environment_preset_tileset_compatibility.dart`

```dart
import 'package:map_core/map_core.dart';

final class EnvironmentPresetTilesetCompatibility {
  factory EnvironmentPresetTilesetCompatibility({
    required String? sourceTilesetId,
    required List<String> tilesetIds,
    required List<String> compatiblePaletteElementIds,
    required List<String> incompatiblePaletteElementIds,
    required List<String> missingPaletteElementIds,
    required List<String> unknownTilesetElementIds,
    required List<ProjectElementEntry> availableCompatibleElements,
  }) {
    return EnvironmentPresetTilesetCompatibility._(
      sourceTilesetId: sourceTilesetId,
      tilesetIds: List<String>.unmodifiable(tilesetIds),
      compatiblePaletteElementIds:
          List<String>.unmodifiable(compatiblePaletteElementIds),
      incompatiblePaletteElementIds:
          List<String>.unmodifiable(incompatiblePaletteElementIds),
      missingPaletteElementIds: List<String>.unmodifiable(
        missingPaletteElementIds,
      ),
      unknownTilesetElementIds: List<String>.unmodifiable(
        unknownTilesetElementIds,
      ),
      availableCompatibleElements: List<ProjectElementEntry>.unmodifiable(
        availableCompatibleElements,
      ),
    );
  }

  const EnvironmentPresetTilesetCompatibility._({
    required this.sourceTilesetId,
    required this.tilesetIds,
    required this.compatiblePaletteElementIds,
    required this.incompatiblePaletteElementIds,
    required this.missingPaletteElementIds,
    required this.unknownTilesetElementIds,
    required this.availableCompatibleElements,
  });

  final String? sourceTilesetId;
  final List<String> tilesetIds;
  final List<String> compatiblePaletteElementIds;
  final List<String> incompatiblePaletteElementIds;
  final List<String> missingPaletteElementIds;
  final List<String> unknownTilesetElementIds;
  final List<ProjectElementEntry> availableCompatibleElements;

  bool get hasSourceTileset => sourceTilesetId != null;

  bool get hasMixedTilesets => tilesetIds.length > 1;
}

String? resolveEnvironmentPresetElementTilesetId(ProjectElementEntry element) {
  if (element.frames.isNotEmpty) {
    final frameTilesetId = element.frames.first.tilesetId.trim();
    if (frameTilesetId.isNotEmpty) {
      return frameTilesetId;
    }
  }
  final elementTilesetId = element.tilesetId.trim();
  return elementTilesetId.isEmpty ? null : elementTilesetId;
}

EnvironmentPresetTilesetCompatibility
    buildEnvironmentPresetTilesetCompatibility({
  required Iterable<String> paletteElementIds,
  required Iterable<ProjectElementEntry> projectElements,
}) {
  final elements = projectElements.toList(growable: false);
  final elementsById = <String, ProjectElementEntry>{};
  for (final element in elements) {
    final id = element.id.trim();
    if (id.isNotEmpty) {
      elementsById[id] = element;
    }
  }

  String? sourceTilesetId;
  final tilesetIds = <String>[];
  final seenTilesetIds = <String>{};
  final compatiblePaletteElementIds = <String>[];
  final incompatiblePaletteElementIds = <String>[];
  final missingPaletteElementIds = <String>[];
  final unknownTilesetElementIds = <String>[];

  for (final rawElementId in paletteElementIds) {
    final elementId = rawElementId.trim();
    if (elementId.isEmpty) {
      continue;
    }
    final element = elementsById[elementId];
    if (element == null) {
      missingPaletteElementIds.add(elementId);
      continue;
    }
    final tilesetId = resolveEnvironmentPresetElementTilesetId(element);
    if (tilesetId == null) {
      unknownTilesetElementIds.add(elementId);
      continue;
    }
    sourceTilesetId ??= tilesetId;
    if (seenTilesetIds.add(tilesetId)) {
      tilesetIds.add(tilesetId);
    }
    if (tilesetId == sourceTilesetId) {
      compatiblePaletteElementIds.add(elementId);
    } else {
      incompatiblePaletteElementIds.add(elementId);
    }
  }

  final availableCompatibleElements = <ProjectElementEntry>[];
  for (final element in elements) {
    final tilesetId = resolveEnvironmentPresetElementTilesetId(element);
    if (tilesetId == null) {
      continue;
    }
    if (sourceTilesetId == null || tilesetId == sourceTilesetId) {
      availableCompatibleElements.add(element);
    }
  }

  return EnvironmentPresetTilesetCompatibility(
    sourceTilesetId: sourceTilesetId,
    tilesetIds: tilesetIds,
    compatiblePaletteElementIds: compatiblePaletteElementIds,
    incompatiblePaletteElementIds: incompatiblePaletteElementIds,
    missingPaletteElementIds: missingPaletteElementIds,
    unknownTilesetElementIds: unknownTilesetElementIds,
    availableCompatibleElements: availableCompatibleElements,
  );
}
```

### Nouveau fichier complet : `environment_preset_tileset_compatibility_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/environment_studio/authoring/environment_preset_tileset_compatibility.dart';

void main() {
  group('buildEnvironmentPresetTilesetCompatibility', () {
    test('preset vide : source inconnue, aucun mélange', () {
      final compatibility = buildEnvironmentPresetTilesetCompatibility(
        paletteElementIds: const [],
        projectElements: [_element(id: 'grass_a', tilesetId: 'grass')],
      );

      expect(compatibility.sourceTilesetId, isNull);
      expect(compatibility.hasSourceTileset, isFalse);
      expect(compatibility.hasMixedTilesets, isFalse);
      expect(compatibility.availableCompatibleElements.map((e) => e.id),
          ['grass_a']);
    });

    test('un élément : source = tileset résolu', () {
      final compatibility = buildEnvironmentPresetTilesetCompatibility(
        paletteElementIds: const ['grass_a'],
        projectElements: [_element(id: 'grass_a', tilesetId: 'grass')],
      );

      expect(compatibility.sourceTilesetId, 'grass');
      expect(compatibility.hasSourceTileset, isTrue);
      expect(compatibility.hasMixedTilesets, isFalse);
      expect(compatibility.compatiblePaletteElementIds, ['grass_a']);
      expect(compatibility.incompatiblePaletteElementIds, isEmpty);
    });

    test('plusieurs éléments du même tileset : compatible', () {
      final compatibility = buildEnvironmentPresetTilesetCompatibility(
        paletteElementIds: const ['grass_a', 'grass_b'],
        projectElements: [
          _element(id: 'grass_a', tilesetId: 'grass'),
          _element(id: 'grass_b', tilesetId: 'grass'),
          _element(id: 'rock_a', tilesetId: 'rocks'),
        ],
      );

      expect(compatibility.sourceTilesetId, 'grass');
      expect(compatibility.hasMixedTilesets, isFalse);
      expect(compatibility.tilesetIds, ['grass']);
      expect(
        compatibility.availableCompatibleElements.map((e) => e.id),
        ['grass_a', 'grass_b'],
      );
    });

    test('frames.primaryFrame.tilesetId surcharge element.tilesetId', () {
      final compatibility = buildEnvironmentPresetTilesetCompatibility(
        paletteElementIds: const ['flower'],
        projectElements: [
          _element(
            id: 'flower',
            tilesetId: 'fallback',
            frameTilesetId: 'frame_tileset',
          ),
        ],
      );

      expect(compatibility.sourceTilesetId, 'frame_tileset');
    });

    test('plusieurs tilesets : warning de mélange et éléments incompatibles',
        () {
      final compatibility = buildEnvironmentPresetTilesetCompatibility(
        paletteElementIds: const ['grass_a', 'rock_a', 'grass_b'],
        projectElements: [
          _element(id: 'grass_a', tilesetId: 'grass'),
          _element(id: 'rock_a', tilesetId: 'rocks'),
          _element(id: 'grass_b', tilesetId: 'grass'),
        ],
      );

      expect(compatibility.sourceTilesetId, 'grass');
      expect(compatibility.hasMixedTilesets, isTrue);
      expect(compatibility.tilesetIds, ['grass', 'rocks']);
      expect(compatibility.compatiblePaletteElementIds, ['grass_a', 'grass_b']);
      expect(compatibility.incompatiblePaletteElementIds, ['rock_a']);
      expect(
        compatibility.availableCompatibleElements.map((e) => e.id),
        ['grass_a', 'grass_b'],
      );
    });

    test('élément palette introuvable : diagnostic sans crash', () {
      final compatibility = buildEnvironmentPresetTilesetCompatibility(
        paletteElementIds: const ['grass_a', 'missing'],
        projectElements: [_element(id: 'grass_a', tilesetId: 'grass')],
      );

      expect(compatibility.sourceTilesetId, 'grass');
      expect(compatibility.missingPaletteElementIds, ['missing']);
      expect(compatibility.hasMixedTilesets, isFalse);
    });

    test('élément sans tileset clair : exclu du picker compatible', () {
      final compatibility = buildEnvironmentPresetTilesetCompatibility(
        paletteElementIds: const ['grass_a', 'unknown_source'],
        projectElements: [
          _element(id: 'grass_a', tilesetId: 'grass'),
          _element(id: 'unknown_source', tilesetId: ''),
        ],
      );

      expect(compatibility.sourceTilesetId, 'grass');
      expect(compatibility.unknownTilesetElementIds, ['unknown_source']);
      expect(
        compatibility.availableCompatibleElements.map((e) => e.id),
        ['grass_a'],
      );
    });
  });
}

ProjectElementEntry _element({
  required String id,
  required String tilesetId,
  String frameTilesetId = '',
}) {
  return ProjectElementEntry(
    id: id,
    name: 'El $id',
    tilesetId: tilesetId,
    categoryId: 'cat',
    frames: [
      TilesetVisualFrame(
        tilesetId: frameTilesetId,
        source: const TilesetSourceRect(x: 0, y: 0),
      ),
    ],
  );
}
```

### Hunks pertinents existants

`environment_preset_draft.dart` :

```diff
+import 'environment_preset_tileset_compatibility.dart';
...
+  mixedPaletteTilesets,
...
+  final tilesetCompatibility = buildEnvironmentPresetTilesetCompatibility(
+    paletteElementIds: [
+      for (final item in draft.palette) item.elementId,
+    ],
+    projectElements: manifest.elements,
+  );
+  for (final elementId in tilesetCompatibility.incompatiblePaletteElementIds) {
+    add(EnvironmentPresetDraftIssue(
+      severity: EnvironmentPresetDraftIssueSeverity.error,
+      kind: EnvironmentPresetDraftIssueKind.mixedPaletteTilesets,
+      message:
+          'Le brouillon mélange plusieurs tilesets. Gardez une palette compatible avec le tileset source "${tilesetCompatibility.sourceTilesetId}".',
+      elementId: elementId,
+    ));
+  }
```

`environment_studio_panel.dart` :

```diff
-                  _buildHeader(context, label, subtle, n),
+                  _buildHeader(label, subtle, n),
+                  const SizedBox(height: 10),
+                  _buildInfoBanner(context),
...
-                        onPressed: _openDraftForm,
-                        child: const Text('Préparer un preset'),
+                      child: _newPresetButton(),
...
-                  const SizedBox(height: 16),
-                  _buildSoon(context, label, subtle),
...
-          'Presets d’environnements organiques',
+          'Presets d’environnements réutilisables',
...
+  Widget _buildInfoBanner(BuildContext context) {
+    return Container(
+      key: const Key('environment-studio-info-banner'),
+      child: const Text(
+        'Les presets se préparent ici. La peinture et la génération se font dans l’éditeur de carte.',
+      ),
+    );
+  }
...
+  Widget _newPresetButton() {
+    return CupertinoButton(
+      key: const Key('environment-studio-open-draft'),
+      onPressed: _openDraftForm,
+      child: const Text('Nouveau preset'),
+    );
+  }
...
+                          child: Text('Presets'),
+                        _newPresetButton(),
...
+                            projectElements: widget.manifest.elements,
```

`environment_preset_detail.dart` :

```diff
+import '../authoring/environment_preset_tileset_compatibility.dart';
...
+    required this.projectElements,
...
+    final tilesetCompatibility = buildEnvironmentPresetTilesetCompatibility(
+      paletteElementIds: [
+        for (final item in p.palette) item.elementId,
+      ],
+      projectElements: projectElements,
+    );
+    final incompatibleElementIds =
+        tilesetCompatibility.incompatiblePaletteElementIds.toSet();
...
-                'Détail du preset',
+                'Éditer le preset',
...
+          key: const Key('environment-studio-section-tileset-source'),
+          title: 'Tileset source',
+          child: _tilesetSourceBlock(context, tilesetCompatibility),
...
-          title: 'Palette',
+          title: 'Palette du preset',
...
+                          isIncompatibleTileset:
+                              incompatibleElementIds.contains(item.elementId),
...
+  Widget _tilesetSourceBlock(
+    BuildContext context,
+    EnvironmentPresetTilesetCompatibility compatibility,
+  ) {
+    final source = compatibility.sourceTilesetId;
+    return Column(
+      children: [
+        Text(source ?? 'Tileset source non défini'),
+        Text(source == null
+            ? 'Ajoutez un premier élément ou choisissez un tileset source.'
+            : 'Seuls les éléments compatibles avec ce tileset sont proposés.'),
+        _protectionPill(),
+        if (compatibility.hasMixedTilesets)
+          Text('Ce preset contient des éléments provenant de plusieurs tilesets.'),
+      ],
+    );
+  }
```

`environment_preset_draft_form.dart` :

```diff
+import '../authoring/environment_preset_tileset_compatibility.dart';
...
+    final tilesetCompatibility = buildEnvironmentPresetTilesetCompatibility(
+      paletteElementIds: [
+        for (final item in widget.draft.palette) item.elementId,
+      ],
+      projectElements: widget.projectElements,
+    );
...
-            'Palette du brouillon',
+            'Palette du preset',
...
-            'Les éléments doivent exister dans le projet ; ils sont copiés dans le '
-            'preset lors de l’application au projet en mémoire.',
+            'Les éléments doivent exister dans le projet et partager le même tileset source.',
...
+          _buildTilesetSourceBlock(context, tilesetCompatibility),
...
-                  projectElements: widget.projectElements,
+                  projectElements:
+                      tilesetCompatibility.availableCompatibleElements,
```

`environment_palette_item_view.dart` :

```diff
+    this.isIncompatibleTileset = false,
...
+  final bool isIncompatibleTileset;
...
+      key: isIncompatibleTileset
+          ? Key('environment-studio-palette-incompatible-${item.elementId}')
+          : null,
...
+                if (isIncompatibleTileset) ...[
+                  const SizedBox(width: 6),
+                  _warningChip(
+                    context,
+                    label: 'Tileset incompatible',
+                  ),
+                ],
```

`environment_preset_draft_presentation.dart` :

```diff
+    EnvironmentPresetDraftIssueKind.mixedPaletteTilesets => 'Tilesets mélangés',
```

`environment_preset_list.dart` :

```diff
+    final paletteLabel = nPalette == 1 ? '1 élément' : '$nPalette éléments';
+    final category = preset.categoryId ?? 'sans catégorie';
...
-                '${preset.id} · $nPalette items · ${preset.templateId}',
+                'Catégorie : $category • $paletteLabel',
```

`environment_generation_params_draft_editor.dart` :

```diff
-              'Paramètres de génération',
+              'Paramètres par défaut',
```

Tests existants modifiés :

- `environment_preset_draft_test.dart` ajoute `mixedPaletteTilesets`.
- `environment_preset_palette_draft_editor_test.dart` ajoute le filtrage picker et la saisie manuelle incompatible.
- `environment_preset_save_to_manifest_test.dart` ajoute le blocage save palette mixte.
- `environment_studio_preset_browser_test.dart` vérifie le panneau `Tileset source`, le warning mixte et le chip incompatible.
- `environment_studio_workspace_test.dart` vérifie la nouvelle bannière et l’absence de textes obsolètes.
- `environment_studio_preset_creation_form_test.dart` met à jour le wording et le label d’erreur.
- `environment_generation_params_draft_editor_test.dart` suit le nouveau wording `Paramètres par défaut`.

## 13. Auto-review

- L’écran n’a-t-il plus de titre dupliqué ? Oui, un seul `Environment Studio` est rendu dans le Studio.
- Les textes obsolètes ont-ils disparu ? Oui pour les textes UI `Lecture seule`, `arrivent dans les prochains lots`, `génération sur carte reste à venir`.
- Le studio est-il clairement limité à la gestion de presets ? Oui, la bannière dit explicitement que peinture/génération se font dans l’éditeur de carte.
- Le picker exclut-il les éléments d’autres tilesets ? Oui, testé via `picker bibliothèque filtre les éléments du tileset source`.
- Les presets mixtes sont-ils diagnostiqués ? Oui, warning détail + chip item incompatible.
- Le guard applicatif empêche-t-il l’ajout d’un élément incompatible ? Oui, le save mémoire est bloqué par `mixedPaletteTilesets` même avec saisie manuelle.
- Les tests ciblés passent-ils ? Oui, matrice ciblée Studio `+110`, non-régressions critiques `+90`.
- L’analyse ciblée passe-t-elle ? Oui, `No issues found!`.
- Aucun commit n’a-t-il été fait ? Oui.

## 14. Critique du prompt et du lot

Ce qui était clair :

- Le rôle produit du Studio : presets uniquement.
- L’interdiction de modifier `map_core` ou d’ajouter un champ JSON persistant.
- La priorité tileset safety : filtre UI + guard applicatif.
- Le besoin de retirer les textes obsolètes.

Ce qui était ambigu :

- Le lot demande un picker “Ajouter un élément” mais l’UI existante a déjà un mode brouillon mémoire et un picker modal simple, pas encore un vrai éditeur sauvegardé complet.
- `Tileset source` pouvait être calculé depuis `ProjectElementEntry.tilesetId` ou depuis la frame primaire. L’audit a retenu la convention déjà présente dans les validators : frame primaire non vide, sinon fallback element.
- Le full `flutter test test/environment_studio` est demandé, mais il contient deux dettes hors lot qui échouent indépendamment du Studio redesign.

À trancher avant EnvironmentStudio-2 :

- Faut-il rendre l’édition de l’identité/defaults/palette vraiment durable côté disque dans ce sous-chantier, ou rester sur l’upsert manifest mémoire existant ?
- Faut-il introduire un choix explicite de tileset source pour preset vide, ou garder le premier élément comme source implicite ?
- Faut-il ajouter une action de nettoyage assisté pour les presets mixtes existants ?

## 15. Verdict

```text
EnvironmentStudio-1 livré
Code produit modifié : oui
Code UI modifié : oui
Tests ciblés : pass
Analyze ciblé : pass
Commande globale test/environment_studio : fail sur dettes hors lot documentées
Prochain lot recommandé : EnvironmentStudio-2 — Preset Palette Editor Save Flow V0
```

## Checklist finale

- [x] Je n’ai fait aucun commit.
- [x] Je n’ai pas utilisé git add.
- [x] Je n’ai pas utilisé git reset/restore/checkout/stash.
- [x] Je n’ai pas lancé build_runner.
- [x] Je n’ai modifié aucun generated file.
- [x] Je n’ai pas modifié map_core.
- [x] Je n’ai pas modifié runtime/gameplay/battle.
- [x] Je n’ai pas remis la peinture/génération dans Environment Studio.
- [x] J’ai retiré les textes obsolètes.
- [x] L’écran n’a plus de titre Environment Studio dupliqué.
- [x] La palette est protégée contre les éléments d’autres tilesets.
- [x] Les presets mixtes sont diagnostiqués.
- [x] Les tests ciblés passent.
- [x] L’analyse ciblée est documentée.
- [x] Le rapport distingue les fichiers préexistants des fichiers du lot.
