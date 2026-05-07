# Environment-33 — TileLayer Environment Area Create Action With Preset Gate V0

## 1. Résumé

Environment-33 ajoute l’action `Ajouter une zone` côté TileLayer inspector, derrière un gate de preset.

Le lot ajoute :

- un use case `CreateTileLayerEnvironmentAreaUseCase` qui crée une `EnvironmentArea` vide dans le premier `EnvironmentLayer` attaché au `TileLayer` actif ;
- une méthode notifier `createEnvironmentAreaForActiveTileLayer({required presetId})` ;
- un gate UI dans `TileLayerEnvironmentInspectorSection` ;
- deux tests ciblés nouveaux : use case et notifier ;
- des cas widget supplémentaires pour l’état `Ajouter une zone`.

La zone créée utilise un preset valide, garde le `TileLayer` sélectionné, sélectionne automatiquement la nouvelle area, garde `environmentMaskEditMode` à `null`, ne peint aucun masque, ne crée aucun `MapPlacedElement` et ne lance aucune génération.

## 2. Rappel de la décision UX

- Environment Studio reste l’atelier de presets / recettes.
- Map Editor / TileLayer inspector devient le lieu de peinture et génération sur la map.
- Ce lot ajoute seulement l’action `Ajouter une zone`.
- Aucune zone n’est créée sans preset valide.

## 3. Audit de l’existant

Fichiers inspectés :

- `packages/map_editor/lib/src/application/use_cases/tile_layer_environment_attachment_use_cases.dart` : use case Environment-32 existant pour activer l’environnement sur un TileLayer.
- `packages/map_editor/lib/src/application/use_cases/layer_use_cases.dart` : `AddEnvironmentAreaUseCase`, `emptyEnvironmentAreaMaskForMap`, id `env_area_<preset>`, seed `0`.
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart` : mutation via `_applyMapMutation`, ancien flow `addEnvironmentAreaToLayer`, sélection `selectedEnvironmentAreaId`, `environmentMaskEditMode`.
- `packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart` : section TileLayer-centric Environment-31/32.
- `packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart` : point d’intégration inspector.
- `packages/map_core/lib/src/models/environment.dart` : `EnvironmentArea`, `EnvironmentAreaMask`, `EnvironmentLayerContent`, `EnvironmentPreset`.
- `packages/map_core/lib/src/models/project_manifest.dart` : source `ProjectManifest.environmentPresets`.
- Tests Environment-30/31/32 dans `packages/map_editor/test/environment_studio/`.

Conventions retenues :

- Création d’area : réutilisation de `AddEnvironmentAreaUseCase`.
- Seed : `0`, convention existante stable.
- Mask : `emptyEnvironmentAreaMaskForMap(map)`.
- Id : `env_area_<presetId slug>` avec suffixe si nécessaire.
- Nom : nom du preset, convention existante Environment-21.
- Plusieurs `EnvironmentLayer` attachés : premier selon l’ordre des layers.
- Preset gate : validation dans le notifier et dans le use case via `ProjectManifest`.

## 4. Use case ajouté

Nom :

```dart
CreateTileLayerEnvironmentAreaUseCase
```

Entrées :

```dart
MapData map
ProjectManifest manifest
String tileLayerId
String presetId
```

Sortie :

```dart
CreateTileLayerEnvironmentAreaResult(
  map,
  tileLayerId,
  environmentLayerId,
  areaId,
  presetId,
  created,
)
```

Règles :

- refuse `tileLayerId` vide ;
- refuse TileLayer introuvable ;
- refuse layer non `TileLayer` ;
- refuse absence d’`EnvironmentLayer` attaché ;
- refuse `presetId` vide ;
- refuse preset absent du manifest via `AddEnvironmentAreaUseCase` ;
- ajoute la zone dans le premier `EnvironmentLayer` attaché ;
- ne crée aucun `MapPlacedElement`.

Diff pertinent :

```dart
final class CreateTileLayerEnvironmentAreaResult {
  const CreateTileLayerEnvironmentAreaResult({
    required this.map,
    required this.tileLayerId,
    required this.environmentLayerId,
    required this.areaId,
    required this.presetId,
    required this.created,
  });
}

class CreateTileLayerEnvironmentAreaUseCase {
  CreateTileLayerEnvironmentAreaResult execute(
    MapData map, {
    required ProjectManifest manifest,
    required String tileLayerId,
    required String presetId,
  }) {
    final environmentLayer = _firstEnvironmentLayerTargeting(map, tid);
    if (environmentLayer == null) {
      throw const EditorValidationException(
        'Activez d’abord l’environnement sur ce layer.',
      );
    }

    final result = AddEnvironmentAreaUseCase().execute(
      map,
      manifest: manifest,
      environmentLayerId: environmentLayer.id,
      presetId: pid,
    );
  }
}
```

## 5. Intégration notifier

Méthode ajoutée :

```dart
void createEnvironmentAreaForActiveTileLayer({
  required String presetId,
})
```

Comportement :

- lit `activeMap`, `project`, `activeLayerId` ;
- vérifie que le layer actif est un `TileLayer` ;
- vérifie que le preset existe dans `project.environmentPresets` ;
- appelle `CreateTileLayerEnvironmentAreaUseCase` ;
- applique la mutation via `_applyMapMutation` ;
- garde `activeLayerId` sur le TileLayer ;
- définit `selectedEnvironmentAreaId` sur la nouvelle area ;
- force `environmentMaskEditMode` à `null`.

Diff pertinent :

```dart
final result = CreateTileLayerEnvironmentAreaUseCase().execute(
  map,
  manifest: project,
  tileLayerId: layerId,
  presetId: pid,
);
_applyMapMutation(
  previousMap: map,
  updatedMap: result.map,
  preferredActiveLayerId: layerId,
  statusMessage: 'Zone d’environnement ajoutée sur "${activeLayer.name}"',
);
state = state.copyWith(
  activeLayerId: layerId,
  selectedEnvironmentAreaId: result.areaId,
  environmentMaskEditMode: null,
);
```

## 6. Intégration UI

`TileLayerEnvironmentInspectorSection` accepte maintenant :

```dart
availablePresets
selectedPresetIdForNewArea
onSelectPresetForNewArea
onCreateArea
```

États :

- aucun preset : message `Créez d’abord un preset dans Environment Studio avant d’ajouter une zone.` et bouton désactivé ;
- un preset : `Preset utilisé : <nom>` et bouton actif si callback ;
- plusieurs presets sans sélection : message `Choisissez un preset avant d’ajouter une zone.` et bouton désactivé ;
- plusieurs presets avec sélection : `Preset pour la nouvelle zone : <nom>` et bouton actif si callback.

Les actions suivantes restent désactivées :

- `Peindre le masque` ;
- `Générer dans ce layer` ;
- `Effacer les placements générés`.

Diff pertinent :

```dart
if (_shouldShowCreateAreaGate(readModel)) {
  final hasPresetForNewArea =
      _selectedPreset(availablePresets, selectedPresetIdForNewArea) != null;
  actions.add(
    _ActionData(
      icon: CupertinoIcons.add_circled,
      label: readModel.primaryActionLabel ?? 'Ajouter une zone',
      enabled: !readModel.hasErrors &&
          hasPresetForNewArea &&
          onCreateArea != null,
      onPressed: onCreateArea,
    ),
  );
}
```

## 7. Tests

Commandes lancées :

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_area_create_use_case_test.dart
```

Résultat : `+9`, `All tests passed!`

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_area_notifier_test.dart
```

Résultat : `+2`, `All tests passed!`

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_inspector_section_test.dart
```

Résultat : `+15`, `All tests passed!`

Non-régressions :

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_attachment_read_model_test.dart
```

Résultat : `+21`, `All tests passed!`

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_attachment_enable_use_case_test.dart
```

Résultat : `+7`, `All tests passed!`

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_attachment_notifier_test.dart
```

Résultat : `+1`, `All tests passed!`

Passe finale groupée fraîche :

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_area_create_use_case_test.dart test/environment_studio/tile_layer_environment_area_notifier_test.dart test/environment_studio/tile_layer_environment_inspector_section_test.dart test/environment_studio/tile_layer_environment_attachment_read_model_test.dart test/environment_studio/tile_layer_environment_attachment_enable_use_case_test.dart test/environment_studio/tile_layer_environment_attachment_notifier_test.dart
```

Résultat : `+55`, `All tests passed!`

Cas couverts :

- création d’area avec preset valide ;
- id unique ;
- mask vide aux dimensions de la map ;
- seed stable ;
- `generatedPlacementIds` vide ;
- refus des layers invalides ;
- refus absence d’attachment ;
- refus preset vide/manquant ;
- plusieurs attachments : premier selon l’ordre ;
- notifier : TileLayer conservé, area sélectionnée, brush non activée ;
- UI : aucun preset, preset unique, plusieurs presets sans/avec sélection, actions futures désactivées.

## 8. Analyse ciblée

Commande :

```bash
cd packages/map_editor
flutter analyze lib/src/application/use_cases/tile_layer_environment_attachment_use_cases.dart lib/src/features/editor/state/editor_notifier.dart lib/src/ui/panels/tile_layer_environment_inspector_section.dart lib/src/ui/panels/map_inspector_panel.dart test/environment_studio/tile_layer_environment_area_create_use_case_test.dart test/environment_studio/tile_layer_environment_area_notifier_test.dart test/environment_studio/tile_layer_environment_inspector_section_test.dart test/environment_studio/tile_layer_environment_attachment_read_model_test.dart test/environment_studio/tile_layer_environment_attachment_enable_use_case_test.dart test/environment_studio/tile_layer_environment_attachment_notifier_test.dart
```

Résultat final :

```text
Analyzing 10 items...
No issues found! (ran in 2.9s)
```

Une première passe a signalé un `unnecessary_non_null_assertion` dans `map_inspector_panel.dart`; il a été retiré puis l’analyse a été relancée.

## 9. Fichiers créés/modifiés

Créés par Environment-33 :

- `packages/map_editor/test/environment_studio/tile_layer_environment_area_create_use_case_test.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_area_notifier_test.dart`
- `reports/environment_studio/environment_33_tile_layer_environment_area_create_action.md`

Modifiés par Environment-33 :

- `packages/map_editor/lib/src/application/use_cases/tile_layer_environment_attachment_use_cases.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart`
- `packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart`

Fichiers préexistants dans le worktree non touchés par ce lot :

- `packages/map_editor/lib/src/ui/canvas/map_canvas.dart`
- `packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart`
- `packages/map_editor/lib/src/ui/canvas/tileset_editor_canvas.dart`
- `packages/map_editor/lib/src/application/services/environment_generated_placement_hover_resolver.dart`
- `packages/map_editor/lib/src/ui/canvas/tileset_grid_metrics.dart`
- `packages/map_editor/test/environment_studio/environment_generated_placement_hover_preview_test.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_attachment_enable_use_case_test.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_attachment_notifier_test.dart`
- `packages/map_editor/test/tileset_grid_metrics_test.dart`
- `reports/environment_studio/environment_32_tile_layer_environment_attachment_enable_action.md`
- `reports/environment_studio/environment_studio_map_centric_workflow_review.md`

Note : `tile_layer_environment_attachment_use_cases.dart` était déjà un fichier non suivi issu d’Environment-32 ; Environment-33 l’a étendu.

## 10. Non-objectifs respectés

- Pas de brush.
- Pas de generate.
- Pas de preview.
- Pas de clear/regenerate/shuffle.
- Pas de `MapPlacedElement`.
- Pas de preset creation/editing.
- Pas de migration.
- Pas de modification `map_core`.
- Pas de runtime.
- Pas de gameplay/battle.
- Pas de build_runner.
- Pas de generated files.

## 11. Evidence pack

Git status initial :

```text
 M packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
 M packages/map_editor/lib/src/ui/canvas/map_canvas.dart
 M packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
 M packages/map_editor/lib/src/ui/canvas/tileset_editor_canvas.dart
 M packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart
 M packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart
 M packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart
?? packages/map_editor/lib/src/application/services/environment_generated_placement_hover_resolver.dart
?? packages/map_editor/lib/src/application/use_cases/tile_layer_environment_attachment_use_cases.dart
?? packages/map_editor/lib/src/ui/canvas/tileset_grid_metrics.dart
?? packages/map_editor/test/environment_studio/environment_generated_placement_hover_preview_test.dart
?? packages/map_editor/test/environment_studio/tile_layer_environment_attachment_enable_use_case_test.dart
?? packages/map_editor/test/environment_studio/tile_layer_environment_attachment_notifier_test.dart
?? packages/map_editor/test/tileset_grid_metrics_test.dart
?? reports/environment_studio/environment_32_tile_layer_environment_attachment_enable_action.md
?? reports/environment_studio/environment_studio_map_centric_workflow_review.md
```

`git diff --stat` :

```text
 .../src/features/editor/state/editor_notifier.dart | 114 +++++++
 .../map_editor/lib/src/ui/canvas/map_canvas.dart   |  34 ++
 .../src/ui/canvas/map_canvas/map_grid_painter.dart | 138 ++++++++-
 .../lib/src/ui/canvas/tileset_editor_canvas.dart   | 344 +++++++++++----------
 .../lib/src/ui/panels/map_inspector_panel.dart     |  71 ++++-
 .../tile_layer_environment_inspector_section.dart  | 184 ++++++++++-
 ...e_layer_environment_inspector_section_test.dart | 244 ++++++++++++++-
 7 files changed, 947 insertions(+), 182 deletions(-)
```

Note : ce `git diff --stat` inclut des fichiers modifiés avant Environment-33 et n’inclut pas les fichiers non suivis.

`git diff --name-only` :

```text
packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
packages/map_editor/lib/src/ui/canvas/map_canvas.dart
packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
packages/map_editor/lib/src/ui/canvas/tileset_editor_canvas.dart
packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart
packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart
packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart
```

Git status final :

```text
 M packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
 M packages/map_editor/lib/src/ui/canvas/map_canvas.dart
 M packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
 M packages/map_editor/lib/src/ui/canvas/tileset_editor_canvas.dart
 M packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart
 M packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart
 M packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart
?? packages/map_editor/lib/src/application/services/environment_generated_placement_hover_resolver.dart
?? packages/map_editor/lib/src/application/use_cases/tile_layer_environment_attachment_use_cases.dart
?? packages/map_editor/lib/src/ui/canvas/tileset_grid_metrics.dart
?? packages/map_editor/test/environment_studio/environment_generated_placement_hover_preview_test.dart
?? packages/map_editor/test/environment_studio/tile_layer_environment_area_create_use_case_test.dart
?? packages/map_editor/test/environment_studio/tile_layer_environment_area_notifier_test.dart
?? packages/map_editor/test/environment_studio/tile_layer_environment_attachment_enable_use_case_test.dart
?? packages/map_editor/test/environment_studio/tile_layer_environment_attachment_notifier_test.dart
?? packages/map_editor/test/tileset_grid_metrics_test.dart
?? reports/environment_studio/environment_32_tile_layer_environment_attachment_enable_action.md
?? reports/environment_studio/environment_33_tile_layer_environment_area_create_action.md
?? reports/environment_studio/environment_studio_map_centric_workflow_review.md
```

Commandes principales :

```bash
git status --short --untracked-files=all
rg -n "EnvironmentArea|EnvironmentAreaMask|selectedEnvironmentAreaId|add.*EnvironmentArea|create.*EnvironmentArea|setEnvironmentArea|nextEnvironmentAreaSeed|EnvironmentLayerContent|targetTileLayerId|environmentPresets|paramsOverride|generatedPlacementIds" packages/map_core/lib/src packages/map_editor/lib/src packages/map_editor/test/environment_studio
dart format packages/map_editor/lib/src/application/use_cases/tile_layer_environment_attachment_use_cases.dart packages/map_editor/lib/src/features/editor/state/editor_notifier.dart packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart packages/map_editor/test/environment_studio/tile_layer_environment_area_create_use_case_test.dart packages/map_editor/test/environment_studio/tile_layer_environment_area_notifier_test.dart packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart
flutter test test/environment_studio/tile_layer_environment_area_create_use_case_test.dart
flutter test test/environment_studio/tile_layer_environment_area_notifier_test.dart
flutter test test/environment_studio/tile_layer_environment_inspector_section_test.dart
flutter test test/environment_studio/tile_layer_environment_attachment_read_model_test.dart
flutter test test/environment_studio/tile_layer_environment_attachment_enable_use_case_test.dart
flutter test test/environment_studio/tile_layer_environment_attachment_notifier_test.dart
flutter analyze lib/src/application/use_cases/tile_layer_environment_attachment_use_cases.dart lib/src/features/editor/state/editor_notifier.dart lib/src/ui/panels/tile_layer_environment_inspector_section.dart lib/src/ui/panels/map_inspector_panel.dart test/environment_studio/tile_layer_environment_area_create_use_case_test.dart test/environment_studio/tile_layer_environment_area_notifier_test.dart test/environment_studio/tile_layer_environment_inspector_section_test.dart test/environment_studio/tile_layer_environment_attachment_read_model_test.dart test/environment_studio/tile_layer_environment_attachment_enable_use_case_test.dart test/environment_studio/tile_layer_environment_attachment_notifier_test.dart
```

## 12. Diff pertinent

Use case :

```diff
+final class CreateTileLayerEnvironmentAreaResult { ... }
+class CreateTileLayerEnvironmentAreaUseCase {
+  CreateTileLayerEnvironmentAreaResult execute(
+    MapData map, {
+    required ProjectManifest manifest,
+    required String tileLayerId,
+    required String presetId,
+  }) { ... }
+}
```

Notifier :

```diff
+void createEnvironmentAreaForActiveTileLayer({
+  required String presetId,
+}) { ... }
```

UI :

```diff
+final List<TileLayerEnvironmentPresetOption> availablePresets;
+final String? selectedPresetIdForNewArea;
+final ValueChanged<String>? onSelectPresetForNewArea;
+final VoidCallback? onCreateArea;
```

Tests :

```diff
+packages/map_editor/test/environment_studio/tile_layer_environment_area_create_use_case_test.dart
+packages/map_editor/test/environment_studio/tile_layer_environment_area_notifier_test.dart
```

## 13. Auto-review

- L’action `Ajouter une zone` est-elle gated par un preset ? Oui.
- Une area sans preset peut-elle être créée ? Non, `EnvironmentArea` exige `presetId` et le notifier/use case valident le preset.
- Le TileLayer reste-t-il sélectionné ? Oui, `preferredActiveLayerId` et `state.copyWith(activeLayerId: layerId)`.
- `selectedEnvironmentAreaId` pointe-t-il vers la nouvelle area ? Oui.
- `environmentMaskEditMode` reste-t-il null ? Oui.
- Aucun `MapPlacedElement` n’est-il créé ? Oui, couvert par tests.
- Aucun masque n’est-il peint ? Oui, mask vide et `activeCellCount == 0`.
- Le flow legacy reste-t-il intact ? Oui, l’ancien `EnvironmentLayerInspectorPanel` et `addEnvironmentAreaToLayer` restent en place.
- Les tests ciblés passent-ils ? Oui, passe groupée finale `+55`.
- L’analyse ciblée passe-t-elle ? Oui, `No issues found!`.
- Aucun commit n’a-t-il été fait ? Oui, aucun git write.

## 14. Critique du prompt et du lot

Clair :

- séparation preset/application map ;
- pas d’area sans preset ;
- pas de brush ni génération ;
- TileLayer doit rester sélectionné.

Ambigu :

- la vraie UX de choix multi-preset peut devenir plus riche. V0 utilise un dropdown compact existant, sans modale.
- le nom d’area réutilise la convention existante `preset.name`. C’est cohérent mais peut être amélioré plus tard en `Zone - <preset>`.

À trancher avant Environment-34 :

- doit-on afficher l’area sélectionnée dans une liste si plusieurs zones existent ?
- le mode brush doit-il démarrer par `Peindre le masque` depuis la section ou depuis un outil global ?
- faut-il auto-scroll/focus canvas après création d’area ?

## 15. Verdict

```text
Environment-33 livré
Code produit modifié : oui
Code UI modifié : oui
Tests ciblés : pass
Analyze ciblé : pass
Prochain lot recommandé : Environment-34 — TileLayer Environment Brush Mode Entry V0
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
- [x] J’ai ajouté uniquement l’action “Ajouter une zone”.
- [x] Je n’ai pas créé de zone sans preset.
- [x] Je n’ai pas créé de MapPlacedElement.
- [x] Je n’ai pas ajouté de brush.
- [x] Je n’ai pas lancé de génération.
- [x] Le TileLayer reste sélectionné après création.
- [x] selectedEnvironmentAreaId pointe vers la nouvelle area.
- [x] environmentMaskEditMode reste null.
- [x] Le flow legacy EnvironmentLayer reste intact.
- [x] Les tests ciblés passent.
- [x] L’analyse ciblée est documentée.
- [x] Le rapport distingue les fichiers préexistants des fichiers du lot.
