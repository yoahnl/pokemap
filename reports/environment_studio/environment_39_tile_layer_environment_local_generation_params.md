# Environment-39 — TileLayer Environment Local Generation Params V0

## 1. Résumé

Ce lot ajoute l’édition TileLayer-centric des paramètres locaux de génération de l’`EnvironmentArea` sélectionnée.

Ajouts principaux :
- exposition des paramètres effectifs, valeurs preset, override local et seed dans `TileLayerEnvironmentAttachmentReadModel` ;
- use cases purs pour écrire `EnvironmentArea.paramsOverride`, réinitialiser `paramsOverride` à `null`, et modifier `EnvironmentArea.seed` ;
- méthodes `EditorNotifier` côté TileLayer actif, en gardant `activeLayerId`, `selectedEnvironmentAreaId` et `environmentMaskEditMode` stables ;
- section UI compacte “Paramètres de génération” avec sliders macOS pour densité/variation/bords/espacement, reset local, seed explicite ;
- tests ciblés read model, use cases, notifier et widget.

## 2. Rappel de la décision UX

- Environment Studio reste l’atelier de presets.
- Map Editor / TileLayer inspector devient le lieu de peinture/génération.
- Ce lot ajoute seulement les paramètres locaux de génération.
- Pas de génération dans ce lot.

## 3. Audit de l’existant

Fichiers inspectés :
- `packages/map_core/lib/src/models/environment.dart`
- `packages/map_editor/lib/src/application/models/tile_layer_environment_attachment_read_model.dart`
- `packages/map_editor/lib/src/application/services/tile_layer_environment_attachment_read_model_builder.dart`
- `packages/map_editor/lib/src/application/services/environment_mask_paint_target_resolver.dart`
- `packages/map_editor/lib/src/application/use_cases/tile_layer_environment_attachment_use_cases.dart`
- `packages/map_editor/lib/src/application/use_cases/environment_mask_use_cases.dart`
- `packages/map_editor/lib/src/application/use_cases/environment_generator_regenerate_use_cases.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_state.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart`
- `packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_attachment_read_model_test.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_area_selection_test.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart`

Fonctionnement de `EnvironmentGenerationParams` :
- `density`, `variation`, `edgeDensity` sont validés dans `[0.0, 1.0]`.
- `minSpacingCells` doit être `>= 0`.
- `EnvironmentGenerationParams.standard()` existe déjà.

Fonctionnement de `paramsOverride` :
- `EnvironmentArea` porte déjà `paramsOverride`.
- Les générateurs utilisent déjà `area.paramsOverride ?? preset.defaultParams`.
- Aucun changement de modèle persistant n’était nécessaire.

Fonctionnement de `seed` :
- `EnvironmentArea.seed` existe déjà.
- Le flow legacy avait déjà `SetEnvironmentAreaSeedUseCase` sur `EnvironmentLayer`.
- Le lot 39 ajoute un wrapper/use case TileLayer-centric sans modifier le flow legacy.

Conventions réutilisées :
- validation par `EditorValidationException` ;
- reconstruction d’une seule `EnvironmentArea` dans `EnvironmentLayerContent` ;
- `setEnvironmentLayerContent(...)` + `MapValidator.validate(...)` ;
- résolution TileLayer actif → EnvironmentLayer attaché via `targetTileLayerId`.

## 4. Read model / paramètres effectifs

Champs ajoutés à `TileLayerEnvironmentAttachmentReadModel` :
- `selectedAreaEffectiveParams`
- `selectedAreaDefaultParams`
- `selectedAreaParamsOverride`
- `selectedAreaHasParamsOverride`
- `selectedAreaSeed`
- `canEditSelectedAreaGenerationParams`

Règles :
- `effectiveParams = area.paramsOverride ?? preset.defaultParams` quand le preset existe.
- `defaultParams = preset.defaultParams` quand le preset existe.
- `paramsOverride = area.paramsOverride`.
- `hasOverride = area.paramsOverride != null`.
- `seed = area.seed`.
- `canEdit = true` seulement si une area effective existe avec preset valide.
- preset manquant : `canEdit = false`, `default/effective = null`, seed et override restent exposés en lecture.
- aucune area effective : champs params/seed null et `canEdit = false`.

## 5. Use cases

Nouveau fichier :

```text
packages/map_editor/lib/src/application/use_cases/tile_layer_environment_area_settings_use_cases.dart
```

Use cases ajoutés :
- `SetTileLayerEnvironmentAreaParamsOverrideUseCase`
- `ResetTileLayerEnvironmentAreaParamsOverrideUseCase`
- `SetTileLayerEnvironmentAreaSeedForTileLayerUseCase`

Entrées :
- `MapData map`
- `String tileLayerId`
- `String areaId`
- `EnvironmentGenerationParams paramsOverride` pour set params
- `int seed` pour set seed

Règles de validation :
- `tileLayerId` non vide ;
- `TileLayer` existant ;
- layer ciblé bien `TileLayer` ;
- `EnvironmentLayer` attaché existant ;
- `areaId` non vide ;
- area existante ;
- seed `>= 0`.

Sortie :
- `MapData` reconstruite avec uniquement l’area ciblée modifiée.

Reset :
- reconstruit l’area ciblée sans `paramsOverride`, donc `paramsOverride == null`.
- conserve seed, mask et `generatedPlacementIds`.

Seed :
- modifie uniquement `EnvironmentArea.seed`.
- conserve `paramsOverride`, mask et `generatedPlacementIds`.

Absence de modification du preset global :
- les use cases ne prennent pas `ProjectManifest`.
- ils n’écrivent jamais `ProjectManifest.environmentPresets`.
- ils ne changent jamais `EnvironmentPreset.defaultParams`.

## 6. Notifier

Méthodes ajoutées dans `EditorNotifier` :
- `setEnvironmentAreaParamsOverrideForActiveTileLayer(EnvironmentGenerationParams params)`
- `resetEnvironmentAreaParamsOverrideForActiveTileLayer()`
- `setEnvironmentAreaSeedForActiveTileLayer(int seed)`

Validation :
- carte active requise ;
- layer actif requis ;
- layer actif doit être un `TileLayer` ;
- `selectedEnvironmentAreaId` requis ;
- target de peinture/résolution attachée valide requise.

Impact état :
- `activeLayerId` reste le TileLayer.
- `selectedEnvironmentAreaId` reste stable.
- `environmentMaskEditMode` est capturé avant mutation puis restauré.
- `MapData` change seulement pour `paramsOverride` ou `seed`.
- aucune génération n’est lancée.
- aucun placement n’est créé.

## 7. Intégration UI

Section ajoutée dans `TileLayerEnvironmentInspectorSection` :

```text
Paramètres de génération
```

Contrôles :
- `Densité` via `MacosSlider`, borné `[0,1]`, discret en 21 positions, valeur affichée à deux décimales.
- `Variation` via `MacosSlider`, borné `[0,1]`, discret en 21 positions, valeur affichée à deux décimales.
- `Densité des bords` via `MacosSlider`, borné `[0,1]`, discret en 21 positions, valeur affichée à deux décimales.
- `Espacement minimal` via `MacosSlider` entier, minimum `0`, valeur arrondie à l’entier.
- `Seed` reste en boutons `- / +`, minimum `0` côté bouton décrément.

Décision UI complémentaire :
- les sliders remplacent les boutons `- / +` sur les paramètres perceptuels, car ce sont des valeurs de réglage continu ;
- les sliders sont grisés et ignorent le pointeur quand le callback d’édition est absent ;
- le composant natif `macos_ui` est utilisé pour ces sliders afin d’être plus proche des contrôles macOS ;
- le seed reste un contrôle discret : il sert à reproduire une génération déterministe, ce n’est pas une intensité visuelle.

États affichés :
- `Valeurs du preset` quand `paramsOverride == null`.
- `Override local` quand `paramsOverride != null`.
- `Preset introuvable : paramètres non modifiables.` quand le preset est manquant.

Reset :
- bouton `Réinitialiser les paramètres`.
- actif seulement si un override local existe et si le callback est fourni.

Actions qui restent désactivées :
- `Générer dans ce layer`.
- `Effacer les placements générés`.

## 8. Tests

Commandes RED lancées :

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_attachment_read_model_test.dart
```

Résultat RED attendu :

```text
Exit code: 1
Error: The getter 'selectedAreaDefaultParams' isn't defined for the type 'TileLayerEnvironmentAttachmentReadModel'.
Error: The getter 'selectedAreaEffectiveParams' isn't defined for the type 'TileLayerEnvironmentAttachmentReadModel'.
Error: The getter 'selectedAreaParamsOverride' isn't defined for the type 'TileLayerEnvironmentAttachmentReadModel'.
Error: The getter 'selectedAreaHasParamsOverride' isn't defined for the type 'TileLayerEnvironmentAttachmentReadModel'.
Error: The getter 'selectedAreaSeed' isn't defined for the type 'TileLayerEnvironmentAttachmentReadModel'.
Error: The getter 'canEditSelectedAreaGenerationParams' isn't defined for the type 'TileLayerEnvironmentAttachmentReadModel'.
```

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_area_settings_use_case_test.dart
```

Résultat RED attendu :

```text
Exit code: 1
Error when reading 'lib/src/application/use_cases/tile_layer_environment_area_settings_use_cases.dart': No such file or directory
Error: Method not found: 'SetTileLayerEnvironmentAreaParamsOverrideUseCase'.
Error: Method not found: 'ResetTileLayerEnvironmentAreaParamsOverrideUseCase'.
Error: Method not found: 'SetTileLayerEnvironmentAreaSeedForTileLayerUseCase'.
```

Commandes GREEN finales lancées :

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_attachment_read_model_test.dart
```

Résultat :

```text
00:00 +27: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_area_settings_use_case_test.dart
```

Résultat :

```text
00:00 +4: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_area_settings_notifier_test.dart
```

Résultat :

```text
00:00 +6: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_inspector_section_test.dart
```

Résultat :

```text
00:01 +32: All tests passed!
```

Non-régressions lancées en une commande Flutter :

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_area_selection_test.dart test/environment_studio/tile_layer_environment_brush_mode_entry_test.dart test/environment_studio/tile_layer_environment_erase_mode_test.dart test/environment_studio/environment_mask_brush_size_use_case_test.dart test/environment_studio/tile_layer_environment_mask_paint_routing_test.dart
```

Résultat :

```text
00:01 +31: All tests passed!
```

Cas couverts :
- params effectifs depuis preset ;
- params effectifs depuis override ;
- preset manquant non éditable ;
- aucune area sélectionnée non éditable ;
- set/reset override ;
- set seed ;
- validations use case ;
- stabilité `activeLayerId`, `selectedEnvironmentAreaId`, `environmentMaskEditMode` ;
- UI labels, sliders macOS, état grisé, callbacks et seed discret ;
- non-régressions paint/erase/brush/routing/sélection.

## 9. Analyse ciblée

Commande lancée :

```bash
cd packages/map_editor
flutter analyze lib/src/application/models/tile_layer_environment_attachment_read_model.dart lib/src/application/services/tile_layer_environment_attachment_read_model_builder.dart lib/src/application/use_cases/tile_layer_environment_area_settings_use_cases.dart lib/src/features/editor/state/editor_notifier.dart lib/src/ui/panels/map_inspector_panel.dart lib/src/ui/panels/tile_layer_environment_inspector_section.dart test/environment_studio/tile_layer_environment_attachment_read_model_test.dart test/environment_studio/tile_layer_environment_area_settings_use_case_test.dart test/environment_studio/tile_layer_environment_area_settings_notifier_test.dart test/environment_studio/tile_layer_environment_inspector_section_test.dart
```

Résultat final :

```text
No issues found! (ran in 1.3s)
```

Dette détectée puis corrigée :

```text
warning • Unused import: 'layer_use_cases.dart' • lib/src/application/use_cases/tile_layer_environment_area_settings_use_cases.dart:4:8 • unused_import
```

Correction :
- suppression de l’import inutilisé.

Dettes préexistantes hors lot :
- aucune remontée par l’analyse ciblée finale.

## 10. Fichiers créés/modifiés

Fichiers déjà présents/modifiés avant Environment-39 :
- aucun fichier modifié au status initial.

Fichiers créés par Environment-39 :
- `packages/map_editor/lib/src/application/use_cases/tile_layer_environment_area_settings_use_cases.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_area_settings_use_case_test.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_area_settings_notifier_test.dart`
- `reports/environment_studio/environment_39_tile_layer_environment_local_generation_params.md`

Fichiers modifiés par Environment-39 :
- `packages/map_editor/lib/src/application/models/tile_layer_environment_attachment_read_model.dart`
- `packages/map_editor/lib/src/application/services/tile_layer_environment_attachment_read_model_builder.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart`
- `packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_attachment_read_model_test.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart`

Fichiers préexistants inspectés mais non touchés :
- `packages/map_core/lib/src/models/environment.dart`
- `packages/map_editor/lib/src/application/services/environment_mask_paint_target_resolver.dart`
- `packages/map_editor/lib/src/application/use_cases/tile_layer_environment_attachment_use_cases.dart`
- `packages/map_editor/lib/src/application/use_cases/environment_mask_use_cases.dart`
- `packages/map_editor/lib/src/application/use_cases/environment_generator_regenerate_use_cases.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_state.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_area_selection_test.dart`

## 11. Non-objectifs respectés

- pas de génération ;
- pas de preview de génération ;
- pas de MapPlacedElement créé ;
- pas de création d’area ;
- pas de suppression/renommage d’area ;
- pas de modification du preset global ;
- pas de migration ;
- pas de map_core ;
- pas de runtime ;
- pas de build_runner ;
- pas de generated files.

## 12. Evidence pack

### git status initial

Commande :

```bash
git status --short --untracked-files=all
```

Sortie exacte :

```text
```

### git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie attendue après création de ce rapport :

```text
 M packages/map_editor/lib/src/application/models/tile_layer_environment_attachment_read_model.dart
 M packages/map_editor/lib/src/application/services/tile_layer_environment_attachment_read_model_builder.dart
 M packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
 M packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart
 M packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart
 M packages/map_editor/test/environment_studio/tile_layer_environment_attachment_read_model_test.dart
 M packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart
?? packages/map_editor/lib/src/application/use_cases/tile_layer_environment_area_settings_use_cases.dart
?? packages/map_editor/test/environment_studio/tile_layer_environment_area_settings_notifier_test.dart
?? packages/map_editor/test/environment_studio/tile_layer_environment_area_settings_use_case_test.dart
?? reports/environment_studio/environment_39_tile_layer_environment_local_generation_params.md
```

### git diff --stat

Commande :

```bash
git diff --stat
```

Sortie exacte au moment de mesure, hors fichiers non suivis :

```text
 ...le_layer_environment_attachment_read_model.dart |  14 +
 ..._environment_attachment_read_model_builder.dart |   7 +
 .../src/features/editor/state/editor_notifier.dart | 118 +++++
 .../lib/src/ui/panels/map_inspector_panel.dart     |  20 +
 .../tile_layer_environment_inspector_section.dart  | 535 +++++++++++++++++++++
 ...yer_environment_attachment_read_model_test.dart | 143 +++++-
 ...e_layer_environment_inspector_section_test.dart | 323 +++++++++++++
 7 files changed, 1153 insertions(+), 7 deletions(-)
```

### git diff --name-only

Commande :

```bash
git diff --name-only
```

Sortie exacte au moment de mesure, hors fichiers non suivis :

```text
packages/map_editor/lib/src/application/models/tile_layer_environment_attachment_read_model.dart
packages/map_editor/lib/src/application/services/tile_layer_environment_attachment_read_model_builder.dart
packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart
packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart
packages/map_editor/test/environment_studio/tile_layer_environment_attachment_read_model_test.dart
packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart
```

### git ls-files --others --exclude-standard

Commande :

```bash
git ls-files --others --exclude-standard
```

Sortie exacte au moment de mesure :

```text
packages/map_editor/lib/src/application/use_cases/tile_layer_environment_area_settings_use_cases.dart
packages/map_editor/test/environment_studio/tile_layer_environment_area_settings_notifier_test.dart
packages/map_editor/test/environment_studio/tile_layer_environment_area_settings_use_case_test.dart
reports/environment_studio/environment_39_tile_layer_environment_local_generation_params.md
```

### git diff --check

Commande :

```bash
git diff --check
```

Sortie exacte :

```text
```

Commandes principales :
- `git status --short --untracked-files=all`
- `rg -n "EnvironmentGenerationParams|paramsOverride|defaultParams|density|variation|edgeDensity|minSpacingCells|seed|SetEnvironmentAreaSeed|selectedEnvironmentAreaId|EnvironmentArea|TileLayerEnvironmentAttachmentReadModel" packages/map_core/lib/src packages/map_editor/lib/src packages/map_editor/test/environment_studio`
- `dart format ...`
- `flutter test ...`
- `flutter analyze ...`
- `git diff --check`

## 13. Diff pertinent

### Read model

```diff
diff --git a/packages/map_editor/lib/src/application/models/tile_layer_environment_attachment_read_model.dart b/packages/map_editor/lib/src/application/models/tile_layer_environment_attachment_read_model.dart
@@
+import 'package:map_core/map_core.dart';
+
 enum TileLayerEnvironmentSelectedLayerKind {
@@
     this.issues = const [],
     this.areaSummaries = const [],
+    this.selectedAreaEffectiveParams,
+    this.selectedAreaDefaultParams,
+    this.selectedAreaParamsOverride,
+    this.selectedAreaHasParamsOverride = false,
+    this.selectedAreaSeed,
+    this.canEditSelectedAreaGenerationParams = false,
   });
@@
   final List<TileLayerEnvironmentAttachmentIssue> issues;
   final List<TileLayerEnvironmentAreaSummary> areaSummaries;
+  final EnvironmentGenerationParams? selectedAreaEffectiveParams;
+  final EnvironmentGenerationParams? selectedAreaDefaultParams;
+  final EnvironmentGenerationParams? selectedAreaParamsOverride;
+  final bool selectedAreaHasParamsOverride;
+  final int? selectedAreaSeed;
+  final bool canEditSelectedAreaGenerationParams;
```

### Read model builder

```diff
@@
     primaryActionLabel: primaryActionLabel,
     issues: List.unmodifiable(issues),
+    selectedAreaEffectiveParams:
+        preset == null ? null : area.paramsOverride ?? preset.defaultParams,
+    selectedAreaDefaultParams: preset?.defaultParams,
+    selectedAreaParamsOverride: area.paramsOverride,
+    selectedAreaHasParamsOverride: area.paramsOverride != null,
+    selectedAreaSeed: area.seed,
+    canEditSelectedAreaGenerationParams: preset != null,
   );
 }
```

### Nouveau use case

```dart
import 'package:map_core/map_core.dart';

import '../errors/application_errors.dart';

class SetTileLayerEnvironmentAreaParamsOverrideUseCase {
  MapData execute(
    MapData map, {
    required String tileLayerId,
    required String areaId,
    required EnvironmentGenerationParams paramsOverride,
  }) {
    final target = _resolveTarget(
      map,
      tileLayerId: tileLayerId,
      areaId: areaId,
    );
    return _replaceTargetArea(
      map,
      environmentLayer: target.environmentLayer,
      areaId: target.area.id,
      updatedArea: EnvironmentArea(
        id: target.area.id,
        name: target.area.name,
        presetId: target.area.presetId,
        mask: target.area.mask,
        seed: target.area.seed,
        paramsOverride: paramsOverride,
        generatedPlacementIds: target.area.generatedPlacementIds,
      ),
    );
  }
}

class ResetTileLayerEnvironmentAreaParamsOverrideUseCase {
  MapData execute(
    MapData map, {
    required String tileLayerId,
    required String areaId,
  }) {
    final target = _resolveTarget(
      map,
      tileLayerId: tileLayerId,
      areaId: areaId,
    );
    return _replaceTargetArea(
      map,
      environmentLayer: target.environmentLayer,
      areaId: target.area.id,
      updatedArea: EnvironmentArea(
        id: target.area.id,
        name: target.area.name,
        presetId: target.area.presetId,
        mask: target.area.mask,
        seed: target.area.seed,
        generatedPlacementIds: target.area.generatedPlacementIds,
      ),
    );
  }
}

class SetTileLayerEnvironmentAreaSeedForTileLayerUseCase {
  MapData execute(
    MapData map, {
    required String tileLayerId,
    required String areaId,
    required int seed,
  }) {
    if (seed < 0) {
      throw const EditorValidationException(
          'EnvironmentArea seed must be >= 0');
    }
    final target = _resolveTarget(
      map,
      tileLayerId: tileLayerId,
      areaId: areaId,
    );
    return _replaceTargetArea(
      map,
      environmentLayer: target.environmentLayer,
      areaId: target.area.id,
      updatedArea: EnvironmentArea(
        id: target.area.id,
        name: target.area.name,
        presetId: target.area.presetId,
        mask: target.area.mask,
        seed: seed,
        paramsOverride: target.area.paramsOverride,
        generatedPlacementIds: target.area.generatedPlacementIds,
      ),
    );
  }
}
```

Le reste du nouveau fichier contient les helpers privés `_resolveTarget`, `_replaceTargetArea`, `_findLayerById`, `_firstEnvironmentLayerTargeting` et `_TileLayerEnvironmentAreaTarget`; ils valident TileLayer, EnvironmentLayer attaché, area et reconstruisent l’EnvironmentLayer via `setEnvironmentLayerContent`.

### Notifier

```diff
@@
 import '../../../application/use_cases/environment_mask_use_cases.dart';
 import '../../../application/use_cases/layer_use_cases.dart';
+import '../../../application/use_cases/tile_layer_environment_area_settings_use_cases.dart';
 import '../../../application/use_cases/tile_layer_environment_attachment_use_cases.dart';
@@
+  void setEnvironmentAreaParamsOverrideForActiveTileLayer(
+    EnvironmentGenerationParams params,
+  ) {
+    _updateEnvironmentAreaSettingsForActiveTileLayer(
+      statusMessage: 'Paramètres locaux de génération mis à jour.',
+      update: (map, layerId, areaId) {
+        return SetTileLayerEnvironmentAreaParamsOverrideUseCase().execute(
+          map,
+          tileLayerId: layerId,
+          areaId: areaId,
+          paramsOverride: params,
+        );
+      },
+    );
+  }
+
+  void resetEnvironmentAreaParamsOverrideForActiveTileLayer() {
+    _updateEnvironmentAreaSettingsForActiveTileLayer(
+      statusMessage:
+          'Paramètres locaux réinitialisés sur les valeurs du preset.',
+      update: (map, layerId, areaId) {
+        return ResetTileLayerEnvironmentAreaParamsOverrideUseCase().execute(
+          map,
+          tileLayerId: layerId,
+          areaId: areaId,
+        );
+      },
+    );
+  }
+
+  void setEnvironmentAreaSeedForActiveTileLayer(int seed) {
+    _updateEnvironmentAreaSettingsForActiveTileLayer(
+      statusMessage: 'Seed de la zone d’environnement mis à jour.',
+      update: (map, layerId, areaId) {
+        return SetTileLayerEnvironmentAreaSeedForTileLayerUseCase().execute(
+          map,
+          tileLayerId: layerId,
+          areaId: areaId,
+          seed: seed,
+        );
+      },
+    );
+  }
```

### MapInspectorPanel

```diff
@@
+    final canEditTileLayerEnvironmentGenerationParams =
+        activeLayer is TileLayer &&
+            tileLayerEnvironmentReadModel != null &&
+            tileLayerEnvironmentReadModel.canEditSelectedAreaGenerationParams &&
+            state.selectedEnvironmentAreaId != null;
@@
+                    onSetGenerationParams:
+                        canEditTileLayerEnvironmentGenerationParams
+                            ? notifier
+                                .setEnvironmentAreaParamsOverrideForActiveTileLayer
+                            : null,
+                    onResetGenerationParams:
+                        canEditTileLayerEnvironmentGenerationParams &&
+                                tileLayerEnvironmentReadModel
+                                    .selectedAreaHasParamsOverride
+                            ? notifier
+                                .resetEnvironmentAreaParamsOverrideForActiveTileLayer
+                            : null,
+                    onSetSeed: canEditTileLayerEnvironmentGenerationParams
+                        ? notifier.setEnvironmentAreaSeedForActiveTileLayer
+                        : null,
```

### TileLayerEnvironmentInspectorSection

```diff
@@
 import 'package:flutter/cupertino.dart';
+import 'package:map_core/map_core.dart';
@@
+    this.onSetGenerationParams,
+    this.onResetGenerationParams,
+    this.onSetSeed,
@@
+  final ValueChanged<EnvironmentGenerationParams>? onSetGenerationParams;
+  final VoidCallback? onResetGenerationParams;
+  final ValueChanged<int>? onSetSeed;
@@
+          if (_shouldShowGenerationParamsSection(readModel)) ...[
+            const SizedBox(height: 12),
+            _GenerationParamsSection(
+              readModel: readModel,
+              onSetGenerationParams: onSetGenerationParams,
+              onResetGenerationParams: onResetGenerationParams,
+              onSetSeed: onSetSeed,
+            ),
+          ],
```

UI ajoutée :
- `_GenerationParamsSection`
- `_GenerationParamSlider`
- `_GenerationIntSlider`
- `_GenerationParamHeader`
- `_GenerationParamStepper`
- `_StepButton`
- `_shouldShowGenerationParamsSection`
- `_clampUnit`
- `_roundUnit`

Les contrôles construisent toujours un `EnvironmentGenerationParams` complet à partir des valeurs effectives courantes.

### Tests ajoutés/modifiés

Read model :

```diff
+    test('expose les paramètres effectifs depuis le preset sans override', () {
+      final defaultParams = _params(
+        density: 0.45,
+        variation: 0.15,
+        edgeDensity: 0.85,
+        minSpacingCells: 2,
+      );
+      ...
+      expect(model.selectedAreaDefaultParams, defaultParams);
+      expect(model.selectedAreaEffectiveParams, defaultParams);
+      expect(model.selectedAreaParamsOverride, isNull);
+      expect(model.selectedAreaHasParamsOverride, isFalse);
+      expect(model.selectedAreaSeed, 123);
+      expect(model.canEditSelectedAreaGenerationParams, isTrue);
+    });
```

Widget :

```diff
+    testWidgets('changer le slider density construit un override complet',
+        (tester) async {
+      EnvironmentGenerationParams? changed;
+      ...
+      final slider = tester.widget<MacosSlider>(
+        find.byKey(const ValueKey('env-generation-density-slider')),
+      );
+      slider.onChanged(0.8);
+      await tester.pump();
+
+      expect(changed, isNotNull);
+      expect(changed!.density, 0.8);
+      expect(changed!.variation, 0.25);
+      expect(changed!.edgeDensity, 0.75);
+      expect(changed!.minSpacingCells, 2);
+    });
+
+    testWidgets('changer le slider spacing construit un override entier',
+        (tester) async {
+      ...
+      final slider = tester.widget<MacosSlider>(
+        find.byKey(const ValueKey('env-generation-min-spacing-slider')),
+      );
+      slider.onChanged(6.4);
+      await tester.pump();
+
+      expect(changed!.minSpacingCells, 6);
+    });
+
+    testWidgets('sans callback les sliders de génération sont grisés',
+        (tester) async {
+      ...
+      expect(tester.widget<IgnorePointer>(disabledSlider).ignoring, isTrue);
+      expect(disabledOpacity.opacity, lessThan(1));
+    });
```

Nouveaux tests :
- `tile_layer_environment_area_settings_use_case_test.dart` couvre set/reset/seed, validations, conservation autres areas/layers/placedElements/mask/generated ids.
- `tile_layer_environment_area_settings_notifier_test.dart` couvre les méthodes notifier, la stabilité de sélection et le maintien de `environmentMaskEditMode`.

Le rapport courant est le fichier de preuve demandé pour ce lot ; reproduire intégralement ce document dans sa propre section de diff créerait une récursion sans information supplémentaire.

## 14. Auto-review

- Les valeurs affichées viennent-elles du preset si aucun override ? Oui.
- Les valeurs affichées viennent-elles de paramsOverride si présent ? Oui.
- Modifier un paramètre crée-t-il un override local ? Oui, via `SetTileLayerEnvironmentAreaParamsOverrideUseCase`.
- Reset remet-il paramsOverride à null ? Oui.
- Le seed est-il modifiable sans génération ? Oui.
- Le preset global reste-t-il inchangé ? Oui, aucun use case ne prend ni ne modifie `ProjectManifest`.
- activeLayerId reste-t-il le TileLayer ? Oui.
- selectedEnvironmentAreaId reste-t-il stable ? Oui.
- environmentMaskEditMode reste-t-il inchangé ? Oui.
- Aucun MapPlacedElement n’est-il créé ? Oui.
- Aucune génération n’est-elle lancée ? Oui.
- Le flow legacy reste-t-il intact ? Oui, le legacy EnvironmentLayer n’a pas été modifié.
- Les tests ciblés passent-ils ? Oui : `+27`, `+4`, `+6`, `+32`, non-régressions `+31`.
- L’analyse ciblée passe-t-elle ? Oui : `No issues found!`.
- Aucun commit n’a-t-il été fait ? Oui.

## 15. Critique du prompt et du lot

Ce qui était clair :
- le scope est strictement `paramsOverride` + `seed` ;
- ne pas modifier le preset global ;
- ne pas générer ;
- garder TileLayer, area sélectionnée et mask mode stables.

Ce qui était ambigu :
- l’édition du seed en cas de preset manquant. J’ai choisi de désactiver toute la section mutation quand le preset est introuvable, comme demandé pour les paramètres locaux.
- le type de contrôle UI. Le premier passage utilisait des boutons `- / +`; après revue visuelle, les paramètres perceptuels sont passés en sliders macOS, et le seed reste discret.

À trancher avant Environment-40 :
- le bouton `Générer dans ce layer` devra-t-il utiliser les params effectifs depuis le read model ou réévaluer directement `area.paramsOverride ?? preset.defaultParams` côté use case ?
- faut-il arrêter automatiquement paint/erase avant génération ?
- faut-il autoriser génération si `paramsOverride` existe mais preset manquant ? Recommandation : non.
- faut-il expliquer le seed dans l’UI, le masquer derrière une option avancée, ou le remplacer plus tard par un bouton explicite de variation déterministe ?

## 16. Verdict

```text
Environment-39 livré
Code produit modifié : oui
Code UI modifié : oui
Tests ciblés : pass
Analyze ciblé : pass
Prochain lot recommandé : Environment-40 — TileLayer Environment Generate From Selected Area V0
```

## Checklist finale

- [x] Je n’ai fait aucun commit.
- [x] Je n’ai pas utilisé git add.
- [x] Je n’ai pas utilisé git reset/restore/checkout/switch/stash.
- [x] Je n’ai pas lancé build_runner.
- [x] Je n’ai modifié aucun generated file.
- [x] Je n’ai pas modifié map_core.
- [x] Je n’ai pas modifié le modèle persistant.
- [x] Je n’ai pas modifié runtime/gameplay/battle.
- [x] J’ai ajouté uniquement les paramètres locaux de génération.
- [x] Je n’ai pas lancé de génération.
- [x] Je n’ai pas créé de MapPlacedElement.
- [x] Je n’ai pas modifié le preset global.
- [x] Je n’ai pas créé/supprimé/renommé d’EnvironmentArea.
- [x] Le TileLayer reste sélectionné.
- [x] selectedEnvironmentAreaId reste stable.
- [x] environmentMaskEditMode reste inchangé.
- [x] Le flow legacy EnvironmentLayer reste intact.
- [x] Les tests ciblés passent.
- [x] L’analyse ciblée est documentée.
- [x] Le rapport distingue les fichiers préexistants des fichiers du lot.
