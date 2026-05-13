# Environment-49 — TileLayer Environment Inspector UX Cleanup V0

## 1. Résumé

Environment-49 réorganise localement `TileLayerEnvironmentInspectorSection` pour sortir du mur de boutons unique.

Ajouts UI :
- section `Éditer le masque` avec peinture, effacement, stop commun et taille de pinceau ;
- section `Génération` avec generate / clear placements / regenerate / shuffle ;
- section `Affinage manuel` avec palette, ajout individuel, suppression individuelle et états actifs ;
- section `Diagnostics` placée en bas ;
- wording plus clair pour le stop masque : `Arrêter l’édition du masque`.

Aucun comportement métier n’a été modifié.

## 2. Rappel de la décision UX

- Environment Studio reste l’atelier de presets.
- Map Editor / TileLayer inspector reste le lieu de peinture, génération et affinage.
- Ce lot est uniquement un cleanup UI local de l’inspecteur.
- Aucun use case, notifier, canvas, modèle persistant ou `map_core` n’a été modifié.

## 3. Orchestration sub-agents

Sub-agents utilisés :
- Sub-agent A / Audit UI : `Pauli`
- Sub-agent B / Copywriting : `Heisenberg`
- Sub-agent D / Regression safety : `Schrodinger`

Passe C / UI refactor local et passe E / QA + rapport ont été réalisées dans le thread principal pour éviter des éditions concurrentes sur le même widget et le même test.

Conclusions des passes :
- Audit UI : l’ordre existant était `État de génération` → summary → zones → issues → bannières actives → brush → params → palette → gate création → `_FutureActions`. Le risque principal était le mélange de toutes les actions dans une seule liste.
- Copywriting : le point le plus ambigu était `Arrêter la peinture` utilisé aussi pour l’effacement. Plusieurs renommages plus larges ont été proposés, mais non retenus pour rester dans le wording demandé par le lot (`Ajouter/Supprimer un élément généré`).
- Regression safety : les callbacks existants étaient largement couverts par les tests widget. Le risque principal était le scroll dans le harness `360x520`, traité par un `ensureVisible` ciblé dans le test `Générer dans ce layer est actif avec callback`.

Stratégie retenue :
1. Garder les callbacks publics inchangés.
2. Remplacer `_FutureActions` par des groupes locaux.
3. Ajouter un test d’ordre textuel principal.
4. Mettre à jour uniquement le wording stop masque.
5. Lancer les tests UI, non-régressions Environment, analyse ciblée et `git diff --check`.

## 4. Audit UI existant

Ordre actuel avant Environment-49 :
1. `État de génération`
2. summary rows layer/preset/zone/masque/placements
3. `Zones d’environnement`
4. issue banners
5. bannières actives masque/delete/add
6. `Taille du pinceau`
7. `Paramètres de génération`
8. `Palette du preset`
9. gate `Preset pour la nouvelle zone`
10. liste plate `_FutureActions`

Problèmes constatés :
- `Peindre le masque`, `Effacer du masque`, `Effacer les placements générés`, `Régénérer`, `Shuffle`, `Ajouter un élément généré` et `Supprimer un élément généré` étaient au même niveau visuel.
- `Arrêter la peinture` était ambigu quand `Effacement actif` était affiché.
- Les diagnostics étaient très hauts dans la section et pouvaient interrompre la lecture du flow principal.
- La palette et l’ajout individuel étaient visuellement séparés alors qu’ils appartiennent au même geste utilisateur.

## 5. Ordre cible des sections

Ordre retenu :
1. `État de génération`
2. summary rows existantes
3. `Zones d’environnement`
4. gate de création de zone si nécessaire
5. `Éditer le masque`
6. `Paramètres de génération`
7. `Génération`
8. `Affinage manuel`
9. `Palette du preset` dans `Affinage manuel`
10. `Diagnostics`

Écart volontaire par rapport au prompt :
- Le gate de création reste avant les outils, car il n’existe pas encore de zone à éditer.
- La palette est intégrée dans `Affinage manuel`, conformément à la recommandation du prompt.

## 6. Wording / copy

Libellés modifiés :
- `Arrêter la peinture` → `Arrêter l’édition du masque`
- `Mode peinture actif : cliquez sur la carte pour peindre le masque.` → `Cliquez sur la carte pour ajouter des cellules au masque.`
- `Mode effacement actif : cliquez sur la carte pour retirer des cellules du masque.` → `Cliquez sur la carte pour retirer des cellules du masque.`

Libellés conservés :
- `Peindre le masque`
- `Effacer du masque`
- `Effacer les placements générés`
- `Régénérer`
- `Shuffle`
- `Ajouter un élément généré`
- `Supprimer un élément généré`
- `Arrêter l’ajout`
- `Arrêter la suppression`

Justification :
- Le stop masque était réellement contradictoire avec l’état `Effacement actif`.
- Les libellés add/delete restent ceux demandés par les lots 44/45 et par le prompt Environment-49.
- `Effacer les placements générés` reste inchangé pour conserver la distinction globale déjà validée.

## 7. Modifications UI

`TileLayerEnvironmentInspectorSection` :
- remplace la liste plate `_FutureActions` par `_SetupActionsSection`, `_MaskEditingSection`, `_GenerationActionsSection`, `_ManualRefinementSection`, `_DiagnosticsSection` ;
- ajoute `_EnvironmentSubsection` pour les titres locaux ;
- garde `_ActionData` et les capsules existantes ;
- ne change aucun callback exposé par le widget ;
- déplace les warnings dans `Diagnostics` ;
- regroupe la palette dans `Affinage manuel` ;
- garde les actions destructives globales et individuelles dans des groupes différents.

Tests :
- ajoute un test d’ordre principal des sections ;
- met à jour les attentes du wording stop masque ;
- garde la vérification des callbacks existants.

## 8. Tests

Commande RED :

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_inspector_section_test.dart
```

Résultat RED exact utile :

```text
Expected: a value greater than or equal to <0>
  Actual: <-1>
Texte absent : Éditer le masque

Expected: exactly one matching candidate
  Actual: _TextWidgetFinder:<Found 0 widgets with text "Cliquez sur la carte pour ajouter des
cellules au masque.": []>

Expected: exactly one matching candidate
  Actual: _TextWidgetFinder:<Found 0 widgets with text "Cliquez sur la carte pour retirer des
cellules du masque.": []>

00:02 +51 -3: Some tests failed.
```

Commande ciblée finale :

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_inspector_section_test.dart
```

Résultat exact :

```text
00:02 +54: All tests passed!
```

Non-régressions :

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_attachment_read_model_test.dart
```

```text
00:00 +29: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/environment_generate_button_wiring_test.dart
```

```text
00:01 +13: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/environment_golden_slice_workflow_test.dart
```

```text
00:00 +6: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_golden_slice_save_reload_test.dart
```

```text
00:00 +1: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_individual_add_canvas_test.dart
```

```text
00:00 +2: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_individual_delete_canvas_test.dart
```

```text
00:00 +3: All tests passed!
```

Cas couverts :
- ordre textuel principal des sections ;
- boutons masque, génération, clear, regenerate, shuffle, add/delete toujours présents ;
- stop masque en mode paint et erase ;
- callbacks existants conservés ;
- read model inchangé ;
- wiring parent generate inchangé ;
- golden workflow inchangé ;
- save/reload Environment-48 inchangé ;
- canvas add/delete inchangés.

## 9. Analyse ciblée

Commande :

```bash
cd packages/map_editor
flutter analyze lib/src/ui/panels/tile_layer_environment_inspector_section.dart test/environment_studio/tile_layer_environment_inspector_section_test.dart
```

Résultat exact :

```text
Analyzing 2 items...                                            
No issues found! (ran in 1.6s)
```

Dette préexistante hors lot :
- aucune dette bloquante détectée par l’analyse ciblée.

## 10. Fichiers créés/modifiés

Fichiers créés par Environment-49 :
- `reports/environment_studio/environment_49_tile_layer_environment_inspector_ux_cleanup.md`

Fichiers modifiés par Environment-49 :
- `packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart`

Fichiers préexistants dans le worktree non touchés :
- `packages/map_editor/test/environment_studio/tile_layer_environment_golden_slice_save_reload_test.dart`
- `reports/environment_studio/environment_48_tile_layer_centric_golden_slice_save_reload.md`

Problèmes introduits par Environment-49 :
- aucun problème détecté par les tests ciblés, non-régressions lancées, analyse ciblée et `git diff --check`.

## 11. Non-objectifs respectés

- Pas de nouvelle feature.
- Pas de modification use cases.
- Pas de modification notifier.
- Pas de modification `map_core`.
- Pas de modification canvas.
- Pas de modification `LayersPanel`.
- Pas de migration modèle.
- Pas de modification runtime/gameplay/battle.
- Pas de build_runner.
- Pas de generated files.

## 12. Evidence pack

Git status initial :

```bash
git status --short --untracked-files=all
```

```text
?? packages/map_editor/test/environment_studio/tile_layer_environment_golden_slice_save_reload_test.dart
?? reports/environment_studio/environment_48_tile_layer_centric_golden_slice_save_reload.md
```

Git status final :

```bash
git status --short --untracked-files=all
```

```text
 M packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart
 M packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart
?? packages/map_editor/test/environment_studio/tile_layer_environment_golden_slice_save_reload_test.dart
?? reports/environment_studio/environment_48_tile_layer_centric_golden_slice_save_reload.md
?? reports/environment_studio/environment_49_tile_layer_environment_inspector_ux_cleanup.md
```

Diff stat :

```bash
git diff --stat
```

```text
 .../tile_layer_environment_inspector_section.dart  | 447 ++++++++++++++-------
 ...e_layer_environment_inspector_section_test.dart | 141 ++++++-
 2 files changed, 438 insertions(+), 150 deletions(-)
```

Diff name-only :

```bash
git diff --name-only
```

```text
packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart
packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart
```

Diff check :

```bash
git diff --check
```

```text
```

Résultat : aucune sortie, code 0.

Commandes principales :

```bash
find . -path '*/AGENTS.md' -print
```

```text
./AGENTS.md
```

```bash
dart format packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart
```

```text
Formatted packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart
Formatted packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart
Formatted 2 files (2 changed) in 0.03 seconds.
```

```bash
cd packages/map_editor
dart format test/environment_studio/tile_layer_environment_inspector_section_test.dart
```

```text
Formatted 1 file (0 changed) in 0.01 seconds.
```

## 13. Diff pertinent

Les fichiers modifiés sont des fichiers existants déjà longs. Les hunks ci-dessous sont les hunks modifiés pertinents pour Environment-49.

### `packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart`

```diff
@@
   @override
   Widget build(BuildContext context) {
     final isMaskEditingActive = isMaskPaintingActive || isMaskErasingActive;
     final isEnvironmentActionActive = isMaskEditingActive ||
         isDeletingGeneratedPlacement ||
         isAddingGeneratedPlacement;
+    final showSetupActions = _shouldShowSetupActions(readModel);
+    final showMaskTools =
+        readModel.canPaintMask || isMaskPaintingActive || isMaskErasingActive;
+    final showGenerationActions = _shouldShowGenerationActions(readModel);
+    final showManualRefinement = _shouldShowManualRefinement(
+      readModel,
+      isEnvironmentActionActive: isEnvironmentActionActive,
+    );
@@
-          if (readModel.issues.isNotEmpty) ...[
+          if (showSetupActions) ...[
             const SizedBox(height: 12),
-            ...readModel.issues.map(
-              (issue) => Padding(
-                padding: const EdgeInsets.only(bottom: 6),
-                child: _IssueBanner(issue: issue),
-              ),
+            _SetupActionsSection(
+              readModel: readModel,
+              onEnableEnvironment: onEnableEnvironment,
+              availablePresets: availablePresets,
+              selectedPresetIdForNewArea: selectedPresetIdForNewArea,
+              onCreateArea: onCreateArea,
             ),
           ],
-          if (isMaskEditingActive) ...[
-            const SizedBox(height: 12),
-            _ActiveMaskEditingBanner(isErasing: isMaskErasingActive),
-          ],
-          if (isDeletingGeneratedPlacement) ...[
+          if (_shouldShowCreateAreaGate(readModel)) ...[
             const SizedBox(height: 12),
-            const _ActiveGeneratedPlacementDeleteBanner(),
+            _CreateAreaPresetGate(
+              availablePresets: availablePresets,
+              selectedPresetIdForNewArea: selectedPresetIdForNewArea,
+              onSelectPresetForNewArea: onSelectPresetForNewArea,
+            ),
           ],
-          if (isAddingGeneratedPlacement) ...[
-            const SizedBox(height: 12),
-            const _ActiveGeneratedPlacementAddBanner(),
-          ],
-          if (readModel.canPaintMask || isEnvironmentActionActive) ...[
+          if (showMaskTools) ...[
             const SizedBox(height: 12),
-            _BrushSizeSelector(
-              selectedSize: environmentMaskBrushSize,
-              onChanged: onSetEnvironmentMaskBrushSize,
+            _MaskEditingSection(
+              isMaskPaintingActive: isMaskPaintingActive,
+              isMaskErasingActive: isMaskErasingActive,
+              environmentMaskBrushSize: environmentMaskBrushSize,
+              onStartMaskPainting: onStartMaskPainting,
+              onStartMaskErasing: onStartMaskErasing,
+              onStopMaskPainting: onStopMaskPainting,
+              onSetEnvironmentMaskBrushSize: onSetEnvironmentMaskBrushSize,
+              readModel: readModel,
             ),
           ],
@@
-          if (_shouldShowGeneratedPlacementPalette(readModel)) ...[
+          if (showGenerationActions) ...[
             const SizedBox(height: 12),
-            _GeneratedPlacementPaletteSection(
-              items: readModel.selectedAreaPaletteItems,
-              onSelectGeneratedPlacementElement:
-                  onSelectGeneratedPlacementElement,
+            _GenerationActionsSection(
+              readModel: readModel,
+              onGenerateEnvironment: onGenerateEnvironment,
+              onClearGeneratedPlacements: onClearGeneratedPlacements,
+              onRegenerateEnvironment: onRegenerateEnvironment,
+              onShuffleEnvironment: onShuffleEnvironment,
             ),
           ],
-          const SizedBox(height: 12),
-          if (_shouldShowCreateAreaGate(readModel)) ...[
-            _CreateAreaPresetGate(
-              availablePresets: availablePresets,
-              selectedPresetIdForNewArea: selectedPresetIdForNewArea,
-              onSelectPresetForNewArea: onSelectPresetForNewArea,
+          if (showManualRefinement) ...[
+            const SizedBox(height: 12),
+            _ManualRefinementSection(
+              readModel: readModel,
+              isMaskEditingActive: isMaskEditingActive,
+              isDeletingGeneratedPlacement: isDeletingGeneratedPlacement,
+              isAddingGeneratedPlacement: isAddingGeneratedPlacement,
+              onSelectGeneratedPlacementElement:
+                  onSelectGeneratedPlacementElement,
+              onStartAddGeneratedPlacement: onStartAddGeneratedPlacement,
+              onStopAddGeneratedPlacement: onStopAddGeneratedPlacement,
+              onStartDeleteGeneratedPlacement: onStartDeleteGeneratedPlacement,
+              onStopDeleteGeneratedPlacement: onStopDeleteGeneratedPlacement,
             ),
-            const SizedBox(height: 12),
           ],
-          _FutureActions(
-            readModel: readModel,
-            onEnableEnvironment: onEnableEnvironment,
-            availablePresets: availablePresets,
-            selectedPresetIdForNewArea: selectedPresetIdForNewArea,
-            onCreateArea: onCreateArea,
-            isMaskPaintingActive: isMaskPaintingActive,
-            isMaskErasingActive: isMaskErasingActive,
-            isDeletingGeneratedPlacement: isDeletingGeneratedPlacement,
-            isAddingGeneratedPlacement: isAddingGeneratedPlacement,
-            onStartMaskPainting: onStartMaskPainting,
-            onStartMaskErasing: onStartMaskErasing,
-            onStopMaskPainting: onStopMaskPainting,
-            onStartAddGeneratedPlacement: onStartAddGeneratedPlacement,
-            onStopAddGeneratedPlacement: onStopAddGeneratedPlacement,
-            onStartDeleteGeneratedPlacement: onStartDeleteGeneratedPlacement,
-            onStopDeleteGeneratedPlacement: onStopDeleteGeneratedPlacement,
-            onGenerateEnvironment: onGenerateEnvironment,
-            onClearGeneratedPlacements: onClearGeneratedPlacements,
-            onRegenerateEnvironment: onRegenerateEnvironment,
-            onShuffleEnvironment: onShuffleEnvironment,
-          ),
+          if (readModel.issues.isNotEmpty) ...[
+            const SizedBox(height: 12),
+            _DiagnosticsSection(issues: readModel.issues),
+          ],
```

```diff
@@
   Widget build(BuildContext context) {
     final title = isErasing ? 'Effacement actif' : 'Peinture active';
     final message = isErasing
-        ? 'Mode effacement actif : cliquez sur la carte pour retirer des cellules du masque.'
-        : 'Mode peinture actif : cliquez sur la carte pour peindre le masque.';
+        ? 'Cliquez sur la carte pour retirer des cellules du masque.'
+        : 'Cliquez sur la carte pour ajouter des cellules au masque.';
```

```diff
+class _MaskEditingSection extends StatelessWidget {
+  const _MaskEditingSection({
+    required this.readModel,
+    required this.isMaskPaintingActive,
+    required this.isMaskErasingActive,
+    required this.environmentMaskBrushSize,
+    required this.onStartMaskPainting,
+    required this.onStartMaskErasing,
+    required this.onStopMaskPainting,
+    required this.onSetEnvironmentMaskBrushSize,
+  });
+...
+          label: 'Arrêter l’édition du masque',
+...
+      title: 'Éditer le masque',
+...
+        _BrushSizeSelector(
+          selectedSize: environmentMaskBrushSize,
+          onChanged: onSetEnvironmentMaskBrushSize,
+        ),
+      ],
+    );
+  }
+}
+
+class _GenerationActionsSection extends StatelessWidget {
+...
+    return _EnvironmentSubsection(
+      title: 'Génération',
+      children: [_ActionButtonColumn(actions: actions)],
+    );
+  }
+}
+
+class _ManualRefinementSection extends StatelessWidget {
+...
+    return _EnvironmentSubsection(
+      title: 'Affinage manuel',
+      children: [
+        if (isDeletingGeneratedPlacement) ...[
+          const _ActiveGeneratedPlacementDeleteBanner(),
+          const SizedBox(height: 8),
+        ],
+        if (isAddingGeneratedPlacement) ...[
+          const _ActiveGeneratedPlacementAddBanner(),
+          const SizedBox(height: 8),
+        ],
+        if (_shouldShowGeneratedPlacementPalette(readModel)) ...[
+          _GeneratedPlacementPaletteSection(
+            items: readModel.selectedAreaPaletteItems,
+            onSelectGeneratedPlacementElement:
+                onSelectGeneratedPlacementElement,
+          ),
+          const SizedBox(height: 8),
+        ],
+        _ActionButtonColumn(actions: actions),
+      ],
+    );
+  }
+}
+
+class _DiagnosticsSection extends StatelessWidget {
+...
+      title: 'Diagnostics',
+...
+}
```

```diff
+bool _shouldShowSetupActions(TileLayerEnvironmentAttachmentReadModel model) {
+  return model.canEnableEnvironment || _shouldShowCreateAreaGate(model);
+}
+
+bool _shouldShowGenerationActions(
+    TileLayerEnvironmentAttachmentReadModel model) {
+  return model.canGenerate ||
+      model.canPaintMask ||
+      model.canClearGeneratedPlacements ||
+      model.canRegenerate ||
+      model.canShuffle;
+}
+
+bool _shouldShowManualRefinement(
+  TileLayerEnvironmentAttachmentReadModel model, {
+  required bool isEnvironmentActionActive,
+}) {
+  return isEnvironmentActionActive ||
+      model.hasGeneratedPlacements ||
+      model.canPaintMask ||
+      model.selectedAreaPaletteItems.isNotEmpty;
+}
```

### `packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart`

```diff
+    testWidgets('organise les sections principales dans l’ordre UX cible',
+        (tester) async {
+      final params = _params(
+        density: 0.65,
+        variation: 0.1,
+        edgeDensity: 0.2,
+        minSpacingCells: 2,
+      );
+      await _pump(
+        tester,
+        TileLayerEnvironmentAttachmentReadModel(
+          state: TileLayerEnvironmentAttachmentState.generated,
+          selectedLayerKind: TileLayerEnvironmentSelectedLayerKind.tile,
+          activeTileLayerId: 'tiles',
+          activeTileLayerName: 'Décor',
+          attachedEnvironmentLayerId: 'env',
+          attachedEnvironmentLayerName: 'Environnement',
+          hasAttachment: true,
+          hasValidTargetTileLayer: true,
+          selectedEnvironmentAreaId: 'area_a',
+          selectedEnvironmentAreaName: 'Bosquet nord',
+          selectedPresetId: 'forest',
+          selectedPresetName: 'Forêt',
+          maskActiveCellCount: 42,
+          hasMask: true,
+          generatedPlacementCount: 18,
+          missingGeneratedPlacementCount: 3,
+          hasGeneratedPlacements: true,
+          canPaintMask: true,
+          canClearGeneratedPlacements: true,
+          canRegenerate: true,
+          canShuffle: true,
+          canAddGeneratedPlacement: true,
+          emptyStateTitle: 'Placements générés',
+          emptyStateMessage: 'Cette zone contient déjà des placements générés.',
+          selectedAreaEffectiveParams: params,
+          selectedAreaDefaultParams: params,
+          selectedAreaHasParamsOverride: false,
+          selectedAreaSeed: 12,
+          canEditSelectedAreaGenerationParams: true,
+          selectedAreaPaletteItems: _paletteItems(selectedId: 'tree'),
+          areaSummaries: const [
+            TileLayerEnvironmentAreaSummary(
+              id: 'area_a',
+              name: 'Bosquet nord',
+              presetId: 'forest',
+              presetName: 'Forêt',
+              isSelected: true,
+              maskActiveCellCount: 42,
+              generatedPlacementCount: 18,
+              missingGeneratedPlacementCount: 3,
+              hasMissingPreset: false,
+            ),
+          ],
+          issues: const [
+            TileLayerEnvironmentAttachmentIssue(
+              severity: TileLayerEnvironmentAttachmentIssueSeverity.warning,
+              message: '3 placements générés référencés sont introuvables.',
+            ),
+          ],
+        ),
+        onStartMaskPainting: () {},
+        onStartMaskErasing: () {},
+        onSetEnvironmentMaskBrushSize: (_) {},
+        onSetGenerationParams: (_) {},
+        onSetSeed: (_) {},
+        onGenerateEnvironment: () {},
+        onClearGeneratedPlacements: () {},
+        onRegenerateEnvironment: () {},
+        onShuffleEnvironment: () {},
+        onSelectGeneratedPlacementElement: (_) {},
+        onStartAddGeneratedPlacement: () {},
+        onStartDeleteGeneratedPlacement: () {},
+      );
+
+      _expectTextOrder(tester, const [
+        'État de génération',
+        'Zones d’environnement',
+        'Éditer le masque',
+        'Paramètres de génération',
+        'Génération',
+        'Affinage manuel',
+        'Palette du preset',
+        'Diagnostics',
+      ]);
+      expect(find.text('Peindre le masque'), findsOneWidget);
+      expect(find.text('Effacer du masque'), findsOneWidget);
+      expect(find.text('Effacer les placements générés'), findsOneWidget);
+      expect(find.text('Régénérer'), findsOneWidget);
+      expect(find.text('Shuffle'), findsOneWidget);
+      expect(find.text('Ajouter un élément généré'), findsOneWidget);
+      expect(find.text('Supprimer un élément généré'), findsOneWidget);
+      expect(
+        find.text(
+            'Attention : 3 placements générés référencés sont introuvables.'),
+        findsOneWidget,
+      );
+    });
```

```diff
-          'Mode peinture actif : cliquez sur la carte pour peindre le masque.',
+          'Cliquez sur la carte pour ajouter des cellules au masque.',
...
-      expect(find.text('Arrêter la peinture'), findsOneWidget);
-      expect(_buttonFor(tester, 'Arrêter la peinture').onPressed, isNotNull);
+      expect(find.text('Arrêter l’édition du masque'), findsOneWidget);
+      expect(
+        _buttonFor(tester, 'Arrêter l’édition du masque').onPressed,
+        isNotNull,
+      );
...
-      await tester.tap(find.text('Arrêter la peinture'));
+      await tester.tap(find.text('Arrêter l’édition du masque'));
```

```diff
+void _expectTextOrder(WidgetTester tester, List<String> labels) {
+  final texts = tester
+      .widgetList<Text>(find.byType(Text))
+      .map((text) => text.data)
+      .whereType<String>()
+      .toList();
+  var previousIndex = -1;
+  for (final label in labels) {
+    final index = texts.indexOf(label);
+    expect(index, greaterThanOrEqualTo(0), reason: 'Texte absent : $label');
+    expect(
+      index,
+      greaterThan(previousIndex),
+      reason: 'Texte hors ordre : $label',
+    );
+    previousIndex = index;
+  }
+}
```

## 14. Auto-review

- Les sections sont-elles plus lisibles ? Oui : les outils masque, génération, affinage et diagnostics sont séparés.
- Les actions globales et individuelles sont-elles distinguées ? Oui : `Effacer les placements générés` est dans `Génération`, add/delete individuel dans `Affinage manuel`.
- Les actions destructives sont-elles séparées ? Oui : clear global n’est plus adjacent aux actions de masque ni à la suppression individuelle dans une liste plate.
- Les modes actifs sont-ils clairs ? Oui : paint/erase gardent leur bannière et le stop commun dit `Arrêter l’édition du masque`.
- Les callbacks existants sont-ils préservés ? Oui : aucun callback public n’a changé, les tests widget continuent de vérifier les callbacks.
- Aucun comportement métier n’a-t-il changé ? Oui : seulement le rendu local du widget.
- Le flow TileLayer-centric reste-t-il intact ? Oui : tests Environment ciblés et golden slice passent.
- Le flow legacy reste-t-il intact ? Oui : le test legacy de l’inspecteur passe.
- Les tests ciblés passent-ils ? Oui.
- L’analyse ciblée passe-t-elle ? Oui.
- Aucun commit n’a-t-il été fait ? Oui.

## 15. Critique du prompt et du lot

Clair :
- le périmètre UI cleanup only ;
- l’ordre cible ;
- les non-objectifs ;
- les preuves attendues.

Ambigu :
- le prompt propose `Peindre / Effacer` mais demande aussi de préserver les callbacks et les tests existants ; j’ai gardé `Peindre le masque / Effacer du masque` pour limiter le changement de vocabulaire.
- le copywriting sub-agent proposait de remplacer `élément généré` par `placement généré`, mais les lots 44/45 et le prompt Environment-49 demandaient explicitement `Ajouter/Supprimer un élément généré`.

À trancher avant Environment-50 :
- choix final entre vocabulaire utilisateur `élément généré` et vocabulaire plus précis `placement généré` ;
- placement exact du gate création de zone dans la section si l’inspecteur gagne rename/delete area ;
- éventuelle séparation visuelle plus forte des actions destructives avec un style dédié.

## 16. Verdict

```text
Environment-49 livré
Code produit modifié : oui
Code UI modifié : oui
Tests ciblés : pass
Analyze ciblé : pass
Prochain lot recommandé : Environment-50 — Area Rename / Delete V0
```

## Checklist finale

- [x] Je n’ai fait aucun commit.
- [x] Je n’ai pas utilisé git add.
- [x] Je n’ai pas utilisé git reset/restore/checkout/stash.
- [x] Je n’ai pas lancé build_runner.
- [x] Je n’ai modifié aucun generated file.
- [x] Je n’ai pas modifié map_core.
- [x] Je n’ai pas modifié runtime/gameplay/battle.
- [x] J’ai ajouté uniquement du cleanup UI.
- [x] Je n’ai pas ajouté de nouvelle feature.
- [x] Je n’ai pas modifié les use cases.
- [x] Je n’ai pas modifié le notifier.
- [x] Je n’ai pas modifié le canvas.
- [x] Je n’ai pas modifié LayersPanel.
- [x] Les callbacks existants restent fonctionnels.
- [x] Le flow TileLayer-centric reste intact.
- [x] Le flow legacy EnvironmentLayer reste intact.
- [x] Les tests ciblés passent.
- [x] L’analyse ciblée est documentée.
- [x] Le rapport distingue les fichiers préexistants des fichiers du lot.

## Commande finale obligatoire

```bash
git status --short --untracked-files=all
```

Résultat exact :

```text
 M packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart
 M packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart
?? packages/map_editor/test/environment_studio/tile_layer_environment_golden_slice_save_reload_test.dart
?? reports/environment_studio/environment_48_tile_layer_centric_golden_slice_save_reload.md
?? reports/environment_studio/environment_49_tile_layer_environment_inspector_ux_cleanup.md
```
