# EnvironmentStudio-2 — Preset Palette Editor Save Flow V0

## 1. Résumé

EnvironmentStudio-2 ajoute un vrai flow d’édition de palette en mémoire depuis le browser Environment Studio :

- bouton `Modifier la palette` sur le preset sélectionné ;
- brouillon local de palette ;
- état `Brouillon non enregistré` puis `Palette modifiée — enregistrez pour appliquer au projet.` ;
- actions `Enregistrer la palette` et `Annuler les changements` ;
- sauvegarde mémoire via le callback existant `onEnvironmentPresetSaved` ;
- use case applicatif `UpdateEnvironmentPresetPaletteUseCase` qui remplace uniquement `EnvironmentPreset.palette` ;
- guard anti-mélange de tilesets hors UI ;
- picker qui continue à ne proposer que les éléments compatibles avec le tileset source.

## 2. Rappel de la décision UX

- Environment Studio prépare les presets.
- Map Editor utilise les presets.
- Ce lot édite uniquement la palette.
- Pas de peinture/génération.
- Pas de sauvegarde disque.
- Pas de modification `map_core` ni de nouveau champ persistant `sourceTilesetId`.

## 3. Orchestration sub-agents

Sub-agents / passes utilisés :

- Passe A locale : audit du panel Environment Studio, du workspace Riverpod, du formulaire de draft, du notifier mémoire et des tests existants.
- Sub-agent A `Hypatia` : audit architecture read-only.
- Sub-agent B `Fermat` : audit compatibilité tileset read-only.
- Passes C/D/E locales : UI draft/save, tests widget, QA et rapport. Deux sub-agents supplémentaires n’ont pas pu être lancés car la limite de threads agents était atteinte.

Conclusions Hypatia :

- `EnvironmentStudioWorkspace` lit `editorProjectManifestProvider`.
- `EnvironmentStudioPanel` garde `_selectedPresetId` et les modes browser/createDraft/editDraft.
- Le chemin mémoire existant est `onEnvironmentPresetSaved` puis `EditorNotifier.applyInMemoryProjectManifest`.
- Le flow de palette devait réutiliser ce chemin au lieu d’ajouter un store global.

Conclusions Fermat :

- `resolveEnvironmentPresetElementTilesetId` priorise `frames.first.tilesetId.trim()`, puis `ProjectElementEntry.tilesetId.trim()`, puis `null`.
- `upsertProjectEnvironmentPreset` ne valide que les doublons d’id.
- Le helper de compatibilité du Lot 1 était déjà côté `map_editor`.
- Il manquait un guard pur de remplacement de palette.

## 4. Audit de l’existant

Fichiers inspectés :

- `packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart`
- `packages/map_editor/lib/src/features/environment_studio/environment_studio_workspace.dart`
- `packages/map_editor/lib/src/features/environment_studio/environment_preset_memory_write_kind.dart`
- `packages/map_editor/lib/src/features/environment_studio/authoring/environment_preset_draft.dart`
- `packages/map_editor/lib/src/features/environment_studio/authoring/environment_preset_tileset_compatibility.dart`
- `packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_detail.dart`
- `packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart`
- `packages/map_editor/lib/src/features/environment_studio/widgets/environment_palette_item_draft_editor.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_core/lib/src/models/environment.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/operations/project_manifest_environment_preset_operations.dart`
- `packages/map_editor/test/environment_studio/environment_preset_draft_test.dart`
- `packages/map_editor/test/environment_studio/environment_preset_tileset_compatibility_test.dart`
- `packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart`
- `packages/map_editor/test/environment_studio/environment_studio_preset_browser_test.dart`
- `packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart`

Architecture héritée du Lot 1 :

- Le browser affiche `EnvironmentPresetList` à gauche et `EnvironmentPresetDetail` à droite.
- `EnvironmentPresetDetail` était read-only hors bouton de draft complet.
- Le formulaire complet `EnvironmentPresetDraftForm` existe déjà pour création/édition globale de preset.
- `EnvironmentPaletteItemDraftEditor` savait déjà ajouter, retirer, modifier poids/collision/tags et utiliser un picker filtré.
- Le Lot 2 réutilise ce widget, mais l’insère dans un mode palette dédié.

Risque identifié :

- Le prompt indique que la palette vide est autorisée en V0, mais `map_core.EnvironmentPreset` refuse une palette vide à la construction. Comme le lot interdit de modifier `map_core`, le use case refuse donc la palette vide et le rapport documente cette limite.

## 5. Use case / guard palette

Fichier créé :

- `packages/map_editor/lib/src/features/environment_studio/authoring/environment_preset_palette_use_cases.dart`

Use case ajouté :

- `UpdateEnvironmentPresetPaletteUseCase`

Entrées :

- `ProjectManifest manifest`
- `String presetId`
- `List<EnvironmentPaletteItem> palette`

Sortie :

- `UpdateEnvironmentPresetPaletteResult`
- `manifest`
- `updatedPreset`
- `sourceTilesetId`

Validations :

- `presetId.trim()` non vide ;
- palette non vide, par contrainte `map_core` existante ;
- preset existant ;
- chaque `EnvironmentPaletteItem.elementId` existe dans `manifest.elements` ;
- chaque élément a un tileset source résolvable ;
- la palette ne mélange pas plusieurs tilesets.

Préservations :

- `id`
- `name`
- `templateId`
- `categoryId`
- `sortOrder`
- `defaultParams`
- tous les autres presets
- le manifest original n’est pas muté.

## 6. Draft / state flow

Le brouillon vit localement dans `EnvironmentStudioPanel` :

- `_paletteDraftPresetId`
- `_paletteDraft`
- `_paletteSaveFeedbackPresetName`
- `_paletteSaveErrorMessage`

Dirty state :

- calculé par comparaison entre la palette source du preset sélectionné et `_paletteDraft`.
- au repos, `Enregistrer la palette` et `Annuler les changements` sont désactivés.
- après ajout/retrait/modification, les boutons deviennent actifs si le brouillon est valide.

Save :

- convertit `EnvironmentPaletteItemDraft` vers `EnvironmentPaletteItem` ;
- appelle `UpdateEnvironmentPresetPaletteUseCase` ;
- appelle `onEnvironmentPresetSaved(nextManifest, updatedPreset, EnvironmentPresetMemoryWriteKind.update)` ;
- revient au détail preset ;
- affiche `Palette enregistrée dans le projet en mémoire.`

Cancel :

- nettoie le brouillon local ;
- revient au détail preset ;
- ne mute pas le `ProjectManifest`.

Reset sur sélection :

- changer de preset nettoie le brouillon palette et le feedback palette.

## 7. Intégration UI

Ajouts UI :

- bouton `Modifier la palette` dans `EnvironmentPresetDetail` ;
- header de mode palette `Palette du preset` ;
- état `Brouillon non enregistré` ;
- état dirty `Palette modifiée — enregistrez pour appliquer au projet.` ;
- bloc `Tileset source` ;
- bouton `Ajouter un élément` ;
- rows `EnvironmentPaletteItemDraftEditor` pour modifier élément, poids, collision et tags ;
- erreurs inline : palette vide, élément vide, élément introuvable, élément dupliqué, poids invalide, tag vide, tileset source introuvable, tilesets mélangés ;
- boutons `Enregistrer la palette` et `Annuler les changements` ;
- feedback post-save.

Le picker reçoit `compatibility.availableCompatibleElements`, donc :

- si la palette a une source, seuls les éléments du même tileset sont proposés ;
- si la palette est vide, le premier élément compatible définit implicitement la source du brouillon ;
- si un preset existant est mixte, l’utilisateur peut retirer les lignes incompatibles, mais le save reste bloqué tant que le mélange existe.

## 8. Tests

RED initial use case :

```bash
cd packages/map_editor
flutter test test/environment_studio/environment_preset_palette_use_case_test.dart
```

Résultat exact :

```text
00:00 +0 -1: Some tests failed.
```

Échec attendu :

```text
Error when reading 'lib/src/features/environment_studio/authoring/environment_preset_palette_use_cases.dart': No such file or directory
Method not found: 'UpdateEnvironmentPresetPaletteUseCase'
```

Commande use case finale :

```bash
cd packages/map_editor
flutter test test/environment_studio/environment_preset_palette_use_case_test.dart
```

Résultat exact :

```text
00:00 +9: All tests passed!
```

Commande widget palette finale :

```bash
cd packages/map_editor
flutter test test/environment_studio/environment_preset_palette_draft_editor_test.dart
```

Résultat exact :

```text
00:03 +16: All tests passed!
```

Commande Environment Studio Lot 1 / Studio ciblée :

```bash
cd packages/map_editor
flutter test test/environment_studio/environment_preset_tileset_compatibility_test.dart test/environment_studio/environment_preset_draft_test.dart test/environment_studio/environment_preset_save_to_manifest_test.dart test/environment_studio/environment_studio_preset_browser_test.dart test/environment_studio/environment_studio_preset_creation_form_test.dart test/environment_studio/environment_generation_params_draft_editor_test.dart test/environment_studio/environment_studio_workspace_test.dart test/environment_studio/environment_studio_workspace_entry_test.dart
```

Résultat exact :

```text
00:07 +98: All tests passed!
```

Note : cette commande imprime volontairement une stack `Bad state: simulé` dans un test de callback qui lève. La ligne finale est verte.

Commande régressions TileLayer-centric :

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_inspector_section_test.dart test/environment_studio/environment_golden_slice_workflow_test.dart test/environment_studio/tile_layer_environment_area_management_use_case_test.dart test/environment_studio/tile_layer_environment_attachment_safety_test.dart
```

Résultat exact :

```text
00:02 +84: All tests passed!
```

Commande globale demandée :

```bash
cd packages/map_editor
flutter test test/environment_studio
```

Résultat exact :

```text
00:19 +534 -2: Some tests failed.
```

Échec hors lot 1, fichier non modifié par EnvironmentStudio-2 :

```text
test/environment_studio/environment_layer_area_model_editing_test.dart: Lot 21 — EnvironmentArea model (inspector) ajout zone via picker + affichage + dirty [E]
Bad state: No element
file:///Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_area_model_editing_test.dart:559:20
```

Contexte exact du même échec :

```text
Warning: A call to tap() with finder "Found 1 widget with key [<'env-layer-inspector-add-area'>]"
derived an Offset (Offset(210.0, 1429.0)) that would not hit test on the specified widget.
Indeed, Offset(210.0, 1429.0) is outside the bounds of the root of the render tree, Size(520.0, 1000.0).
```

Échec hors lot 2, fichier non modifié par EnvironmentStudio-2 :

```text
test/environment_studio/tile_layer_environment_erase_mode_test.dart: EditorNotifier.startEnvironmentMaskErasingForActiveTileLayer refuse si aucune area est sélectionnée [E]
Expected: null
  Actual: EnvironmentMaskEditMode:<EnvironmentMaskEditMode.erase>
test/environment_studio/tile_layer_environment_erase_mode_test.dart 104:7
```

La commande globale produit beaucoup de lignes passantes ; les deux blocs ci-dessus sont les seules défaillances et ils concernent des fichiers non modifiés par ce lot.

## 9. Analyse ciblée

Commande :

```bash
cd packages/map_editor
flutter analyze lib/src/features/environment_studio/authoring/environment_preset_palette_use_cases.dart lib/src/features/environment_studio/environment_studio_panel.dart lib/src/features/environment_studio/widgets/environment_preset_detail.dart test/environment_studio/environment_preset_palette_use_case_test.dart test/environment_studio/environment_preset_palette_draft_editor_test.dart
```

Résultat exact :

```text
Analyzing 5 items...
No issues found! (ran in 1.4s)
```

## 10. Fichiers créés/modifiés

Fichiers créés par EnvironmentStudio-2 :

- `packages/map_editor/lib/src/features/environment_studio/authoring/environment_preset_palette_use_cases.dart`
- `packages/map_editor/test/environment_studio/environment_preset_palette_use_case_test.dart`
- `reports/environment_studio/environment_studio_2_preset_palette_editor_save_flow.md`

Fichiers modifiés par EnvironmentStudio-2 :

- `packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart`
- `packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_detail.dart`
- `packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart`

Fichiers préexistants dans le worktree non touchés :

- Aucun au `git status --short --untracked-files=all` initial du lot.

Dettes préexistantes hors lot :

- `environment_layer_area_model_editing_test.dart` : tap offscreen puis `Bad state: No element`.
- `tile_layer_environment_erase_mode_test.dart` : expectation historique `environmentMaskEditMode == null`, état actuel `erase`.

Problème introduit par EnvironmentStudio-2 :

- Aucun identifié par les tests ciblés et l’analyse ciblée.

## 11. Non-objectifs respectés

- Pas d’édition identité/default params.
- Pas de création/suppression preset.
- Pas de sauvegarde disque.
- Pas de peinture/génération.
- Pas de modification `map_core`.
- Pas de modification du modèle `ProjectManifest`.
- Pas de generated/build_runner.
- Pas de modification runtime/gameplay/battle.
- Pas de modification canvas.
- Pas de modification TileLayer inspector.

## 12. Evidence pack

Git status initial :

```bash
git status --short --untracked-files=all
```

Résultat exact :

```text
```

Git status final :

```bash
git status --short --untracked-files=all
```

Résultat exact :

```text
 M packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart
 M packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_detail.dart
 M packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart
?? packages/map_editor/lib/src/features/environment_studio/authoring/environment_preset_palette_use_cases.dart
?? packages/map_editor/test/environment_studio/environment_preset_palette_use_case_test.dart
?? reports/environment_studio/environment_studio_2_preset_palette_editor_save_flow.md
```

Diff stat :

```bash
git diff --stat
```

Résultat exact :

```text
 .../environment_studio_panel.dart                  | 497 ++++++++++++++++++++-
 .../widgets/environment_preset_detail.dart         |  56 ++-
 ...vironment_preset_palette_draft_editor_test.dart | 239 +++++++++-
 3 files changed, 753 insertions(+), 39 deletions(-)
```

Note : `git diff --stat` ne liste pas les fichiers non suivis. Les fichiers créés par ce lot sont listés explicitement dans la section 10 et dans le `git status final`.

Diff name-only :

```bash
git diff --name-only
```

Résultat exact :

```text
packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart
packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_detail.dart
packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart
```

Note : `git diff --name-only` ne liste pas les fichiers non suivis. Les fichiers créés par ce lot sont listés explicitement dans la section 10 et dans le `git status final`.

Diff check :

```bash
git diff --check
```

Résultat exact :

```text
```

Commandes principales :

```text
flutter test test/environment_studio/environment_preset_palette_use_case_test.dart
flutter test test/environment_studio/environment_preset_palette_draft_editor_test.dart
flutter test test/environment_studio/environment_preset_tileset_compatibility_test.dart test/environment_studio/environment_preset_draft_test.dart test/environment_studio/environment_preset_save_to_manifest_test.dart test/environment_studio/environment_studio_preset_browser_test.dart test/environment_studio/environment_studio_preset_creation_form_test.dart test/environment_studio/environment_generation_params_draft_editor_test.dart test/environment_studio/environment_studio_workspace_test.dart test/environment_studio/environment_studio_workspace_entry_test.dart
flutter test test/environment_studio/tile_layer_environment_inspector_section_test.dart test/environment_studio/environment_golden_slice_workflow_test.dart test/environment_studio/tile_layer_environment_area_management_use_case_test.dart test/environment_studio/tile_layer_environment_attachment_safety_test.dart
flutter test test/environment_studio
flutter analyze lib/src/features/environment_studio/authoring/environment_preset_palette_use_cases.dart lib/src/features/environment_studio/environment_studio_panel.dart lib/src/features/environment_studio/widgets/environment_preset_detail.dart test/environment_studio/environment_preset_palette_use_case_test.dart test/environment_studio/environment_preset_palette_draft_editor_test.dart
git diff --check
git status --short --untracked-files=all
```

## 13. Diff pertinent

Nouveau fichier complet : `packages/map_editor/lib/src/features/environment_studio/authoring/environment_preset_palette_use_cases.dart`

```dart
import 'package:map_core/map_core.dart';

import 'environment_preset_tileset_compatibility.dart';

final class UpdateEnvironmentPresetPaletteResult {
  const UpdateEnvironmentPresetPaletteResult({
    required this.manifest,
    required this.updatedPreset,
    required this.sourceTilesetId,
  });

  final ProjectManifest manifest;
  final EnvironmentPreset updatedPreset;
  final String sourceTilesetId;
}

final class UpdateEnvironmentPresetPaletteUseCase {
  const UpdateEnvironmentPresetPaletteUseCase();

  UpdateEnvironmentPresetPaletteResult call({
    required ProjectManifest manifest,
    required String presetId,
    required List<EnvironmentPaletteItem> palette,
  }) {
    final key = presetId.trim();
    if (key.isEmpty) {
      throw ArgumentError.value(
        presetId,
        'presetId',
        'Environment preset id must not be blank.',
      );
    }
    if (palette.isEmpty) {
      throw ArgumentError.value(
        palette,
        'palette',
        'Environment preset palette must not be empty.',
      );
    }

    final elementsById = <String, ProjectElementEntry>{
      for (final element in manifest.elements) element.id: element,
    };
    final tilesetIds = <String>{};
    for (final item in palette) {
      final element = elementsById[item.elementId];
      if (element == null) {
        throw ArgumentError.value(
          item.elementId,
          'palette',
          'Environment preset palette references a missing element.',
        );
      }
      final tilesetId = resolveEnvironmentPresetElementTilesetId(element);
      if (tilesetId == null) {
        throw ArgumentError.value(
          item.elementId,
          'palette',
          'Environment preset palette element has no resolvable tileset.',
        );
      }
      tilesetIds.add(tilesetId);
    }
    if (tilesetIds.length > 1) {
      throw ArgumentError.value(
        palette.map((item) => item.elementId).toList(growable: false),
        'palette',
        'Environment preset palette cannot mix multiple tilesets.',
      );
    }

    final presets = manifest.environmentPresets;
    final index = presets.indexWhere((preset) => preset.id == key);
    if (index < 0) {
      throw StateError('Environment preset "$key" not found.');
    }
    final source = presets[index];
    final updatedPreset = EnvironmentPreset(
      id: source.id,
      name: source.name,
      templateId: source.templateId,
      palette: palette,
      defaultParams: source.defaultParams,
      categoryId: source.categoryId,
      sortOrder: source.sortOrder,
    );
    final updatedPresets = List<EnvironmentPreset>.from(presets);
    updatedPresets[index] = updatedPreset;
    return UpdateEnvironmentPresetPaletteResult(
      manifest: manifest.copyWith(environmentPresets: updatedPresets),
      updatedPreset: updatedPreset,
      sourceTilesetId: tilesetIds.single,
    );
  }
}
```

Nouveau fichier complet : `packages/map_editor/test/environment_studio/environment_preset_palette_use_case_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/environment_studio/authoring/environment_preset_palette_use_cases.dart';

void main() {
  group('UpdateEnvironmentPresetPaletteUseCase', () {
    const useCase = UpdateEnvironmentPresetPaletteUseCase();

    test('update palette modifie uniquement le preset ciblé', () {
      final project = _project();
      final updated = useCase(
        manifest: project,
        presetId: 'forest',
        palette: [
          EnvironmentPaletteItem(
            elementId: 'grass_b',
            weight: 7,
            collisionMode: EnvironmentCollisionMode.forceEnabled,
            tags: {'haut'},
          ),
        ],
      ).manifest;

      final preset = findProjectEnvironmentPresetById(updated, 'forest')!;
      expect(preset.palette.map((item) => item.elementId), ['grass_b']);
      expect(preset.palette.single.weight, 7);
      expect(preset.palette.single.collisionMode,
          EnvironmentCollisionMode.forceEnabled);
      expect(preset.palette.single.tags, {'haut'});
      expect(preset.id, 'forest');
      expect(preset.name, 'Forêt');
      expect(preset.templateId, 'forest_dense');
      expect(preset.categoryId, 'nature');
      expect(preset.defaultParams, _forestParams);
      expect(preset.sortOrder, 4);
      expect(findProjectEnvironmentPresetById(updated, 'props')!.palette,
          findProjectEnvironmentPresetById(project, 'props')!.palette);
    });

    test('préserve les autres presets et ne mute pas le project original', () {
      final project = _project();
      final originalPalette =
          findProjectEnvironmentPresetById(project, 'forest')!.palette;

      final updated = useCase(
        manifest: project,
        presetId: 'forest',
        palette: [
          EnvironmentPaletteItem(elementId: 'grass_b', weight: 3),
        ],
      ).manifest;

      expect(identical(updated, project), isFalse);
      expect(findProjectEnvironmentPresetById(project, 'forest')!.palette,
          originalPalette);
      expect(findProjectEnvironmentPresetById(updated, 'props')!.name, 'Props');
    });

    test('refuse presetId vide', () {
      expect(
        () => useCase(
          manifest: _project(),
          presetId: ' ',
          palette: [
            EnvironmentPaletteItem(elementId: 'grass_a', weight: 1),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('refuse preset introuvable', () {
      expect(
        () => useCase(
          manifest: _project(),
          presetId: 'missing',
          palette: [
            EnvironmentPaletteItem(elementId: 'grass_a', weight: 1),
          ],
        ),
        throwsStateError,
      );
    });

    test('refuse élément introuvable', () {
      expect(
        () => useCase(
          manifest: _project(),
          presetId: 'forest',
          palette: [
            EnvironmentPaletteItem(elementId: 'missing', weight: 1),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('refuse palette mélangeant deux tilesets', () {
      expect(
        () => useCase(
          manifest: _project(),
          presetId: 'forest',
          palette: [
            EnvironmentPaletteItem(elementId: 'grass_a', weight: 1),
            EnvironmentPaletteItem(elementId: 'rock_a', weight: 1),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('refuse élément sans tileset source', () {
      expect(
        () => useCase(
          manifest: _project(elements: [
            _element(id: 'unknown', tilesetId: ''),
          ]),
          presetId: 'forest',
          palette: [
            EnvironmentPaletteItem(elementId: 'unknown', weight: 1),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('refuse palette vide car EnvironmentPreset map_core la rejette', () {
      expect(
        () => useCase(
          manifest: _project(),
          presetId: 'forest',
          palette: const [],
        ),
        throwsArgumentError,
      );
    });

    test('accepte plusieurs éléments du même tileset', () {
      final result = useCase(
        manifest: _project(),
        presetId: 'forest',
        palette: [
          EnvironmentPaletteItem(elementId: 'grass_a', weight: 1),
          EnvironmentPaletteItem(elementId: 'grass_b', weight: 2),
        ],
      );

      expect(result.updatedPreset.palette.map((item) => item.elementId),
          ['grass_a', 'grass_b']);
      expect(result.sourceTilesetId, 'grass');
    });
  });
}

final _forestParams = EnvironmentGenerationParams(
  density: 0.2,
  variation: 0.3,
  edgeDensity: 0.4,
  minSpacingCells: 2,
);

ProjectManifest _project({
  List<ProjectElementEntry>? elements,
}) {
  return ProjectManifest(
    name: 'palette-use-case',
    maps: const [],
    tilesets: const [],
    elements: elements ??
        [
          _element(id: 'grass_a', tilesetId: 'grass'),
          _element(id: 'grass_b', tilesetId: 'grass'),
          _element(id: 'rock_a', tilesetId: 'rocks'),
        ],
    environmentPresets: [
      EnvironmentPreset(
        id: 'forest',
        name: 'Forêt',
        templateId: 'forest_dense',
        categoryId: 'nature',
        palette: [
          EnvironmentPaletteItem(elementId: 'grass_a', weight: 1),
        ],
        defaultParams: _forestParams,
        sortOrder: 4,
      ),
      EnvironmentPreset(
        id: 'props',
        name: 'Props',
        templateId: 'props',
        categoryId: 'decor',
        palette: [
          EnvironmentPaletteItem(elementId: 'rock_a', weight: 1),
        ],
        defaultParams: EnvironmentGenerationParams.standard(),
        sortOrder: 9,
      ),
    ],
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
}

ProjectElementEntry _element({
  required String id,
  required String tilesetId,
}) {
  return ProjectElementEntry(
    id: id,
    name: 'El $id',
    tilesetId: tilesetId,
    categoryId: 'cat',
    frames: const [
      TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
    ],
  );
}
```

Hunks pertinents `packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart` :

```diff
diff --git a/packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart b/packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart
index 6c948d09..7f1c2716 100644
--- a/packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart
+++ b/packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart
@@ -3,7 +3,10 @@ import 'package:map_core/map_core.dart';
 
 import '../../ui/shared/cupertino_editor_widgets.dart';
 import 'authoring/environment_preset_draft.dart';
+import 'authoring/environment_preset_palette_use_cases.dart';
+import 'authoring/environment_preset_tileset_compatibility.dart';
 import 'environment_preset_memory_write_kind.dart';
+import 'widgets/environment_palette_item_draft_editor.dart';
 import 'widgets/environment_preset_detail.dart';
 import 'widgets/environment_preset_draft_form.dart';
 import 'widgets/environment_preset_list.dart';
@@ -72,6 +75,10 @@ class _EnvironmentStudioPanelState extends State<EnvironmentStudioPanel> {
 
   /// Lot 18 : dernier type d’écriture pour le feedback local (create/update).
   EnvironmentPresetMemoryWriteKind? _lastMemoryWriteKind;
+  String? _paletteDraftPresetId;
+  List<EnvironmentPaletteItemDraft> _paletteDraft = const [];
+  String? _paletteSaveFeedbackPresetName;
+  String? _paletteSaveErrorMessage;
 
   @override
   void initState() {
@@ -87,7 +94,15 @@ class _EnvironmentStudioPanelState extends State<EnvironmentStudioPanel> {
       _selectedPresetId,
     );
     if (next != _selectedPresetId) {
-      setState(() => _selectedPresetId = next);
+      setState(() {
+        _selectedPresetId = next;
+        _clearPaletteDraft();
+      });
+    } else if (_paletteDraftPresetId != null &&
+        !widget.manifest.environmentPresets.any(
+          (preset) => preset.id == _paletteDraftPresetId,
+        )) {
+      setState(_clearPaletteDraft);
     }
   }
 
@@ -193,9 +212,93 @@ class _EnvironmentStudioPanelState extends State<EnvironmentStudioPanel> {
       _draftFormEpoch++;
       _localSaveFeedbackPresetName = savedPreset.name;
       _lastMemoryWriteKind = kind;
+      _paletteSaveFeedbackPresetName = null;
+    });
+  }
+
+  void _clearPaletteDraft() {
+    _paletteDraftPresetId = null;
+    _paletteDraft = const [];
+    _paletteSaveErrorMessage = null;
+  }
+
+  void _openPaletteDraft(EnvironmentPreset preset) {
+    setState(() {
+      _paletteDraftPresetId = preset.id;
+      _paletteDraft = _paletteDraftFromPreset(preset);
+      _paletteSaveErrorMessage = null;
+      _paletteSaveFeedbackPresetName = null;
+      _localSaveFeedbackPresetName = null;
+      _lastMemoryWriteKind = null;
+    });
+  }
+
+  void _replacePaletteDraftItem(int index, EnvironmentPaletteItemDraft item) {
+    setState(() {
+      _paletteSaveErrorMessage = null;
+      final next = List<EnvironmentPaletteItemDraft>.from(_paletteDraft);
+      next[index] = item;
+      _paletteDraft = List<EnvironmentPaletteItemDraft>.unmodifiable(next);
+    });
+  }
+
+  void _removePaletteDraftItem(int index) {
+    setState(() {
+      _paletteSaveErrorMessage = null;
+      final next = List<EnvironmentPaletteItemDraft>.from(_paletteDraft)
+        ..removeAt(index);
+      _paletteDraft = List<EnvironmentPaletteItemDraft>.unmodifiable(next);
     });
   }
 
+  void _addPaletteDraftItem() {
+    setState(() {
+      _paletteSaveErrorMessage = null;
+      _paletteDraft = List<EnvironmentPaletteItemDraft>.unmodifiable([
+        ..._paletteDraft,
+        EnvironmentPaletteItemDraft(elementId: '', weight: 1),
+      ]);
+    });
+  }
+
+  void _cancelPaletteDraft() {
+    setState(_clearPaletteDraft);
+  }
+
+  void _savePaletteDraft(EnvironmentPreset preset) {
+    final save = widget.onEnvironmentPresetSaved;
+    if (save == null) {
+      return;
+    }
+    final issues = _paletteDraftIssues(_paletteDraft, widget.manifest.elements);
+    if (issues.isNotEmpty) {
+      return;
+    }
+    try {
+      final palette = _paletteItemsFromDraft(_paletteDraft);
+      final result = const UpdateEnvironmentPresetPaletteUseCase()(
+        manifest: widget.manifest,
+        presetId: preset.id,
+        palette: palette,
+      );
+      save(
+        result.manifest,
+        result.updatedPreset,
+        EnvironmentPresetMemoryWriteKind.update,
+      );
+      setState(() {
+        _selectedPresetId = result.updatedPreset.id;
+        _clearPaletteDraft();
+        _paletteSaveFeedbackPresetName = result.updatedPreset.name;
+      });
+    } catch (_) {
+      setState(() {
+        _paletteSaveErrorMessage =
+            'Impossible d’enregistrer la palette dans le projet en mémoire.';
+      });
+    }
+  }
+
   @override
   Widget build(BuildContext context) {
     final label = EditorChrome.primaryLabel(context);
@@ -483,17 +593,30 @@ class _EnvironmentStudioPanelState extends State<EnvironmentStudioPanel> {
                       : SingleChildScrollView(
                           key: const Key('environment-studio-detail-scroll'),
                           padding: const EdgeInsets.all(20),
-                          child: EnvironmentPresetDetail(
-                            preset: selected,
-                            projectElements: widget.manifest.elements,
-                            report: report,
-                            labelColor: label,
-                            subtleColor: subtle,
-                            onEditAsDraft:
-                                widget.onEnvironmentPresetSaved == null
-                                    ? null
-                                    : () => _openEditDraftFromPreset(selected),
-                          ),
+                          child: _paletteDraftPresetId == selected.id
+                              ? _buildPaletteDraftDetail(
+                                  context,
+                                  selected,
+                                  label,
+                                  subtle,
+                                )
+                              : EnvironmentPresetDetail(
+                                  preset: selected,
+                                  projectElements: widget.manifest.elements,
+                                  report: report,
+                                  labelColor: label,
+                                  subtleColor: subtle,
+                                  onEditAsDraft: widget
+                                              .onEnvironmentPresetSaved ==
+                                          null
+                                      ? null
+                                      : () =>
+                                          _openEditDraftFromPreset(selected),
+                                  onEditPalette:
+                                      widget.onEnvironmentPresetSaved == null
+                                          ? null
+                                          : () => _openPaletteDraft(selected),
+                                ),
                         ),
                 ),
               ),
@@ -627,6 +750,132 @@ class _EnvironmentStudioPanelState extends State<EnvironmentStudioPanel> {
     );
   }
 
+  Widget _buildPaletteDraftDetail(
+    BuildContext context,
+    EnvironmentPreset preset,
+    Color label,
+    Color subtle,
+  ) {
+    final sourceDraft = _paletteDraftFromPreset(preset);
+    final isDirty = !_paletteDraftEquals(_paletteDraft, sourceDraft);
+    final issues = _paletteDraftIssues(_paletteDraft, widget.manifest.elements);
+    final compatibility = buildEnvironmentPresetTilesetCompatibility(
+      paletteElementIds: [
+        for (final item in _paletteDraft) item.elementId,
+      ],
+      projectElements: widget.manifest.elements,
+    );
+    final canSave = widget.onEnvironmentPresetSaved != null &&
+        isDirty &&
+        issues.isEmpty &&
+        _paletteDraft.isNotEmpty;
+    final canCancel = isDirty;
+
+    return Column(
+      key: const Key('environment-studio-palette-draft-root'),
+      crossAxisAlignment: CrossAxisAlignment.stretch,
+      children: [
+        Text(
+          'Palette du preset',
+          style: TextStyle(
+            color: label,
+            fontSize: 17,
+            fontWeight: FontWeight.w800,
+          ),
+        ),
+        const SizedBox(height: 10),
+        Text(
+          isDirty
+              ? 'Palette modifiée — enregistrez pour appliquer au projet.'
+              : 'Brouillon non enregistré',
+          style: TextStyle(
+            color: isDirty ? EditorChrome.accentWarm : subtle,
+            fontSize: 12,
+            fontWeight: FontWeight.w700,
+          ),
+        ),
+        const SizedBox(height: 12),
+        _buildPaletteDraftTilesetBlock(context, compatibility, label, subtle),
+        const SizedBox(height: 12),
+        Align(
+          alignment: Alignment.centerLeft,
+          child: CupertinoButton(
+            key: const Key('environment-studio-draft-palette-add-item'),
+            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
+            onPressed: _addPaletteDraftItem,
+            child: const Text('Ajouter un élément'),
+          ),
+        ),
+        const SizedBox(height: 10),
+        if (_paletteDraft.isEmpty)
+          Text(
+            'Aucun item pour l’instant.',
+            key: const Key('environment-studio-draft-palette-no-items'),
+            style: TextStyle(color: subtle, fontSize: 13),
+          )
+        else
+          for (var i = 0; i < _paletteDraft.length; i++)
+            Padding(
+              padding: EdgeInsets.only(
+                bottom: i < _paletteDraft.length - 1 ? 12 : 0,
+              ),
+              child: EnvironmentPaletteItemDraftEditor(
+                key: ValueKey('palette-draft-slot-$i'),
+                index: i,
+                item: _paletteDraft[i],
+                projectElements: compatibility.availableCompatibleElements,
+                onChanged: (item) => _replacePaletteDraftItem(i, item),
+                onRemove: () => _removePaletteDraftItem(i),
+              ),
+            ),
+        if (issues.isNotEmpty) ...[
+          const SizedBox(height: 14),
+          _buildPaletteDraftIssues(context, issues),
+        ],
+        if (_paletteSaveErrorMessage != null) ...[
+          const SizedBox(height: 10),
+          Text(
+            _paletteSaveErrorMessage!,
+            key: const Key('environment-studio-palette-save-error'),
+            style: TextStyle(
+              color: CupertinoColors.systemRed.resolveFrom(context),
+              fontSize: 12,
+              fontWeight: FontWeight.w700,
+            ),
+          ),
+        ],
+        const SizedBox(height: 18),
+        Wrap(
+          spacing: 8,
+          runSpacing: 8,
+          children: [
+            CupertinoButton(
+              key: const Key('environment-studio-palette-save'),
+              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
+              onPressed: canSave ? () => _savePaletteDraft(preset) : null,
+              child: const Text('Enregistrer la palette'),
+            ),
+            CupertinoButton(
+              key: const Key('environment-studio-palette-cancel'),
+              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
+              onPressed: canCancel ? _cancelPaletteDraft : null,
+              child: const Text('Annuler les changements'),
+            ),
+          ],
+        ),
+      ],
+    );
+  }
+
   Widget _buildGlobalDiagnostics(
     BuildContext context,
     Color label,
@@ -547,3 +919,100 @@ class _EnvironmentStudioPanelState extends State<EnvironmentStudioPanel> {
     );
   }
 }
+
+List<EnvironmentPaletteItemDraft> _paletteDraftFromPreset(
+  EnvironmentPreset preset,
+) {
+  return List<EnvironmentPaletteItemDraft>.unmodifiable([
+    for (final item in preset.palette)
+      EnvironmentPaletteItemDraft(
+        elementId: item.elementId,
+        weight: item.weight,
+        collisionMode: item.collisionMode,
+        tags: item.tags,
+      ),
+  ]);
+}
+
+List<String> _paletteDraftIssues(
+  List<EnvironmentPaletteItemDraft> draft,
+  List<ProjectElementEntry> projectElements,
+) {
+  final issues = <String>[];
+  if (draft.isEmpty) {
+    issues.add('Palette vide');
+  }
+  final elementsById = <String, ProjectElementEntry>{
+    for (final element in projectElements) element.id: element,
+  };
+  final seen = <String>{};
+  final duplicateIds = <String>{};
+  for (final item in draft) {
+    final elementId = item.elementId.trim();
+    if (elementId.isEmpty) {
+      issues.add('Élément de palette vide');
+    } else {
+      if (!seen.add(elementId)) {
+        duplicateIds.add(elementId);
+      }
+      if (!elementsById.containsKey(elementId)) {
+        issues.add('Élément introuvable : $elementId');
+      }
+    }
+    if (item.weight < 1) {
+      issues.add('Poids invalide');
+    }
+    for (final tag in item.tags) {
+      if (tag.trim().isEmpty) {
+        issues.add('Tag vide');
+      }
+    }
+  }
+  for (final id in duplicateIds) {
+    issues.add('Élément dupliqué : $id');
+  }
+  final compatibility = buildEnvironmentPresetTilesetCompatibility(
+    paletteElementIds: [
+      for (final item in draft) item.elementId,
+    ],
+    projectElements: projectElements,
+  );
+  for (final elementId in compatibility.unknownTilesetElementIds) {
+    issues.add('Tileset source introuvable : $elementId');
+  }
+  if (compatibility.hasMixedTilesets) {
+    issues.add(
+      'Tilesets mélangés : ce preset mélange plusieurs tilesets.',
+    );
+  }
+  return List<String>.unmodifiable(issues.toSet());
+}
```

Hunks pertinents `packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_detail.dart` :

```diff
diff --git a/packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_detail.dart b/packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_detail.dart
index d36fe6aa..6772f714 100644
--- a/packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_detail.dart
+++ b/packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_detail.dart
@@ -16,6 +16,7 @@ class EnvironmentPresetDetail extends StatelessWidget {
     required this.labelColor,
     required this.subtleColor,
     this.onEditAsDraft,
+    this.onEditPalette,
   });
 
   final EnvironmentPreset preset;
@@ -26,6 +27,7 @@ class EnvironmentPresetDetail extends StatelessWidget {
 
   /// Lot 18 : ouvre le brouillon d’édition (null = action masquée).
   final VoidCallback? onEditAsDraft;
+  final VoidCallback? onEditPalette;
 
   @override
   Widget build(BuildContext context) {
@@ -46,31 +48,39 @@ class EnvironmentPresetDetail extends StatelessWidget {
       crossAxisAlignment: CrossAxisAlignment.stretch,
       key: const Key('environment-studio-detail-root'),
       children: [
-        Row(
-          crossAxisAlignment: CrossAxisAlignment.start,
-          children: [
-            Expanded(
-              child: Text(
-                'Éditer le preset',
-                style: TextStyle(
-                  color: labelColor,
-                  fontSize: 17,
-                  fontWeight: FontWeight.w800,
+        Text(
+          'Éditer le preset',
+          style: TextStyle(
+            color: labelColor,
+            fontSize: 17,
+            fontWeight: FontWeight.w800,
+          ),
+        ),
+        if (onEditAsDraft != null || onEditPalette != null) ...[
+          const SizedBox(height: 8),
+          Wrap(
+            spacing: 8,
+            runSpacing: 8,
+            children: [
+              if (onEditAsDraft != null)
+                CupertinoButton(
+                  key: const Key('environment-studio-edit-as-draft'),
+                  padding:
+                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
+                  onPressed: onEditAsDraft,
+                  child: const Text('Modifier en brouillon'),
+                ),
+              if (onEditPalette != null)
+                CupertinoButton(
+                  key: const Key('environment-studio-edit-palette'),
+                  padding:
+                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
+                  onPressed: onEditPalette,
+                  child: const Text('Modifier la palette'),
                 ),
-              ),
-            ),
-            if (onEditAsDraft != null) ...[
-              const SizedBox(width: 10),
-              CupertinoButton(
-                key: const Key('environment-studio-edit-as-draft'),
-                padding:
-                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
-                onPressed: onEditAsDraft,
-                child: const Text('Modifier en brouillon'),
-              ),
             ],
-          ],
-        ),
+          ),
+        ],
         const SizedBox(height: 14),
         _sectionCard(
           context,
```

Hunks pertinents `packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart` :

```diff
diff --git a/packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart b/packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart
index f5d0a97d..5eb456db 100644
--- a/packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart
+++ b/packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart
@@ -2,6 +2,7 @@ import 'package:flutter/cupertino.dart';
 import 'package:flutter_test/flutter_test.dart';
 import 'package:macos_ui/macos_ui.dart';
 import 'package:map_core/map_core.dart';
+import 'package:map_editor/src/features/environment_studio/environment_preset_memory_write_kind.dart';
 import 'package:map_editor/src/features/environment_studio/environment_studio_panel.dart';
 
 void main() {
@@ -416,6 +417,209 @@ void main() {
       expect(manifest.environmentPresets.length, 1);
     });
   });
+
+  group('EnvironmentStudioPanel — palette save flow (EnvironmentStudio-2)', () {
+    testWidgets(
+        'modifier palette affiche un brouillon sale puis annuler restaure',
+        (tester) async {
+      final manifest = _manifest(
+        environmentPresets: [_preset(id: 'forest')],
+        elements: [
+          _element(id: 'elm'),
+          _element(id: 'elm_b'),
+        ],
+      );
+
+      await _pumpWithSave(tester, manifest);
+      await tester
+          .tap(find.byKey(const Key('environment-studio-edit-palette')));
+      await tester.pumpAndSettle();
+
+      expect(find.text('Brouillon non enregistré'), findsOneWidget);
+      final saveBefore = tester.widget<CupertinoButton>(
+        find.byKey(const Key('environment-studio-palette-save')),
+      );
+      final cancelBefore = tester.widget<CupertinoButton>(
+        find.byKey(const Key('environment-studio-palette-cancel')),
+      );
+      expect(saveBefore.onPressed, isNull);
+      expect(cancelBefore.onPressed, isNull);
+
+      await tester.tap(
+        find.byKey(const Key('environment-studio-draft-palette-add-item')),
+      );
+      await tester.pumpAndSettle();
+      await tester.enterText(
+        find.byKey(const Key('environment-studio-palette-draft-element-1')),
+        'elm_b',
+      );
+      await tester.pumpAndSettle();
+
+      expect(
+          find.text('Palette modifiée — enregistrez pour appliquer au projet.'),
+          findsOneWidget);
+      final saveDirty = tester.widget<CupertinoButton>(
+        find.byKey(const Key('environment-studio-palette-save')),
+      );
+      final cancelDirty = tester.widget<CupertinoButton>(
+        find.byKey(const Key('environment-studio-palette-cancel')),
+      );
+      expect(saveDirty.onPressed, isNotNull);
+      expect(cancelDirty.onPressed, isNotNull);
+
+      await tester
+          .tap(find.byKey(const Key('environment-studio-palette-cancel')));
+      await tester.pumpAndSettle();
+
+      expect(find.byKey(const Key('environment-studio-palette-draft-item-1')),
+          findsNothing);
+      expect(
+        find.byKey(const Key('environment-studio-palette-item-elm')),
+        findsOneWidget,
+      );
+    });
+
+    testWidgets('enregistrer la palette appelle le callback et garde le preset',
+        (tester) async {
+      ProjectManifest? receivedManifest;
+      EnvironmentPreset? receivedPreset;
+      EnvironmentPresetMemoryWriteKind? receivedKind;
+      final manifest = _manifest(
+        environmentPresets: [_preset(id: 'forest')],
+        elements: [
+          _element(id: 'elm'),
+          _element(id: 'elm_b'),
+        ],
+      );
+
+      await _pumpWithSave(
+        tester,
+        manifest,
+        onSaved: (m, p, k) {
+          receivedManifest = m;
+          receivedPreset = p;
+          receivedKind = k;
+        },
+      );
+      await tester
+          .tap(find.byKey(const Key('environment-studio-edit-palette')));
+      await tester.pumpAndSettle();
+      await tester.tap(
+        find.byKey(const Key('environment-studio-draft-palette-add-item')),
+      );
+      await tester.pumpAndSettle();
+      await tester.enterText(
+        find.byKey(const Key('environment-studio-palette-draft-element-1')),
+        'elm_b',
+      );
+      await tester.pumpAndSettle();
+
+      await tester
+          .tap(find.byKey(const Key('environment-studio-palette-save')));
+      await tester.pumpAndSettle();
+
+      expect(receivedManifest, isNotNull);
+      expect(receivedPreset, isNotNull);
+      expect(receivedKind, EnvironmentPresetMemoryWriteKind.update);
+      expect(receivedPreset!.id, 'forest');
+      expect(receivedPreset!.name, 'P forest');
+      expect(receivedPreset!.templateId, 'tpl');
+      expect(receivedPreset!.defaultParams,
+          EnvironmentGenerationParams.standard());
+      expect(receivedPreset!.palette.map((item) => item.elementId),
+          ['elm', 'elm_b']);
+      expect(
+        findProjectEnvironmentPresetById(receivedManifest!, 'forest')!
+            .palette
+            .map((item) => item.elementId),
+        ['elm', 'elm_b'],
+      );
+      expect(find.byKey(const Key('environment-studio-detail-id')),
+          findsOneWidget);
+      expect(
+          find.textContaining('Palette enregistrée dans le projet en mémoire.'),
+          findsOneWidget);
+    });
+
+    testWidgets('picker palette exclut un élément incompatible',
+        (tester) async {
+      await _pumpWithSave(
+        tester,
+        _manifest(
+          environmentPresets: [
+            _preset(id: 'forest', elementId: 'grass_a'),
+          ],
+          elements: [
+            _element(id: 'grass_a', tilesetId: 'grass'),
+            _element(id: 'grass_b', tilesetId: 'grass'),
+            _element(id: 'rock_a', tilesetId: 'rocks'),
+          ],
+        ),
+      );
+
+      await tester
+          .tap(find.byKey(const Key('environment-studio-edit-palette')));
+      await tester.pumpAndSettle();
+      await tester.tap(
+        find.byKey(const Key('environment-studio-draft-palette-add-item')),
+      );
+      await tester.pumpAndSettle();
+      await tester.tap(
+        find.byKey(
+            const Key('environment-studio-palette-draft-pick-element-1')),
+      );
+      await tester.pumpAndSettle();
+
+      expect(find.text('grass_b — El grass_b'), findsOneWidget);
+      expect(find.text('rock_a — El rock_a'), findsNothing);
+    });
+
+    testWidgets('preset mixte bloque save mais permet retirer incompatible',
+        (tester) async {
+      await _pumpWithSave(
+        tester,
+        _manifest(
+          environmentPresets: [
+            EnvironmentPreset(
+              id: 'mixed',
+              name: 'Mixed',
+              templateId: 'tpl',
+              palette: [
+                EnvironmentPaletteItem(elementId: 'grass_a', weight: 1),
+                EnvironmentPaletteItem(elementId: 'rock_a', weight: 1),
+              ],
+              defaultParams: EnvironmentGenerationParams.standard(),
+              sortOrder: 0,
+            ),
+          ],
+          elements: [
+            _element(id: 'grass_a', tilesetId: 'grass'),
+            _element(id: 'rock_a', tilesetId: 'rocks'),
+          ],
+        ),
+      );
+      await tester
+          .tap(find.byKey(const Key('environment-studio-edit-palette')));
+      await tester.pumpAndSettle();
+
+      expect(find.textContaining('mélange plusieurs tilesets'), findsOneWidget);
+      final saveMixed = tester.widget<CupertinoButton>(
+        find.byKey(const Key('environment-studio-palette-save')),
+      );
+      expect(saveMixed.onPressed, isNull);
+
+      await tester.tap(
+        find.byKey(const Key('environment-studio-palette-draft-remove-1')),
+      );
+      await tester.pumpAndSettle();
+
+      expect(find.textContaining('mélange plusieurs tilesets'), findsNothing);
+      final saveAfterCleanup = tester.widget<CupertinoButton>(
+        find.byKey(const Key('environment-studio-palette-save')),
+      );
+      expect(saveAfterCleanup.onPressed, isNotNull);
+    });
+  });
 }
```

## 14. Auto-review

- Le `ProjectManifest` n’est-il muté qu’au save ? Oui. Les changements de palette restent dans `_paletteDraft` avant save.
- Annuler restaure-t-il bien la palette source ? Oui. Le brouillon est nettoyé et le détail read-only revient.
- Le save préserve-t-il les autres champs du preset ? Oui. Testé sur `id/name/templateId/categoryId/defaultParams/sortOrder`.
- Les éléments incompatibles sont-ils exclus du picker ? Oui. Test widget dédié.
- Le guard applicatif bloque-t-il une palette mixte ? Oui. Test use case dédié.
- Les éléments sans tileset source sont-ils traités clairement ? Oui. Le use case refuse ; le draft affiche `Tileset source introuvable`.
- Les tests ciblés passent-ils ? Oui.
- L’analyse ciblée passe-t-elle ? Oui.
- Aucun commit n’a-t-il été fait ? Oui pour EnvironmentStudio-2.

## 15. Critique du prompt et du lot

Clair :

- périmètre palette uniquement ;
- mémoire uniquement ;
- sécurité tileset applicative + UI ;
- pas de retour peinture/génération dans Studio.

Ambigu :

- le prompt autorise la palette vide, mais le modèle existant `EnvironmentPreset` l’interdit. Le lot interdit aussi `map_core`, donc la décision sûre est de refuser la palette vide dans ce lot.

À trancher avant EnvironmentStudio-3 :

- faut-il modifier `map_core` pour autoriser un preset vide ?
- faut-il sauvegarder identité/default params via un use case dédié ou réutiliser le draft complet existant ?
- faut-il ajouter un concept de `sourceTilesetId` draft non persistant pour les palettes vides ?

## 16. Verdict

```text
EnvironmentStudio-2 livré
Code produit modifié : oui
Code UI modifié : oui
Tests ciblés : pass
Analyze ciblé : pass
Prochain lot recommandé : EnvironmentStudio-3 — Preset Identity / Default Params Save Flow V0
```

## Checklist finale

- [x] Je n’ai fait aucun commit.
- [x] Je n’ai pas utilisé git add.
- [x] Je n’ai pas utilisé git reset/restore/checkout/stash.
- [x] Je n’ai pas lancé build_runner.
- [x] Je n’ai modifié aucun generated file.
- [x] Je n’ai pas modifié map_core.
- [x] Je n’ai pas modifié runtime/gameplay/battle.
- [x] Je n’ai pas ajouté de sauvegarde disque.
- [x] Je n’ai pas remis la peinture/génération dans Environment Studio.
- [x] J’ai ajouté uniquement le flow palette draft/save.
- [x] Le save palette garde les autres champs du preset.
- [x] Le picker filtre les éléments incompatibles.
- [x] Le guard applicatif bloque les palettes mixtes.
- [x] Les tests ciblés passent.
- [x] L’analyse ciblée est documentée.
- [x] Le rapport distingue les fichiers préexistants des fichiers du lot.
