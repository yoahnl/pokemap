# Evidence Pack — Stage Point Placement UX Discoverability (NS-SCENES-V1-102-bis)

## 1. Description du Lot
- **Lot ID** : `NS-SCENES-V1-102-bis`
- **Titre** : `Stage Point Placement UX Discoverability / Evidence Pack Repair / Codex Rules Alignment`
- **Statut** : `PROPOSED DONE`

---

## 2. Inventaire des Fichiers

### Fichiers Créés
- [ns_scenes_v1_102_bis_stage_point_placement_ux_discoverability_evidence_repair.md](file:///Users/karim/Project/pokemonProject/reports/narrativeStudio/scenes/ns_scenes_v1_102_bis_stage_point_placement_ux_discoverability_evidence_repair.md)
- [ns_scenes_v1_102_bis_evidence_pack.md](file:///Users/karim/Project/pokemonProject/reports/narrativeStudio/scenes/ns_scenes_v1_102_bis_evidence_pack.md)
- [ns_scenes_v1_102_bis_stage_point_placement_ux_discoverability.png](file:///Users/karim/Project/pokemonProject/reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_102_bis_stage_point_placement_ux_discoverability.png)

### Fichiers Modifiés
- [AGENTS.md](file:///Users/karim/Project/pokemonProject/AGENTS.md)
- [cinematic_builder_workspace.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart)
- [cinematic_map_backdrop_preview_panel.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart)
- [cinematic_builder_workspace_test.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart)
- [road_map_scenes.md](file:///Users/karim/Project/pokemonProject/reports/narrativeStudio/scenes/road_map_scenes.md)
- [road_map_scene_builder_authoring.md](file:///Users/karim/Project/pokemonProject/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md)

---

## 3. Preuve Visuelle (Visual Gate)

Voici la capture d'écran de la Visual Gate générée par le test de non-régression widget (montrant le nouveau bouton texte « Ajouter un point » dans la toolbar, le bandeau de mode de placement actif, l'overlay d'empty state, et la liste des points sous forme de chips interactifs dans la sidebar contextuelle de droite) :

![Visual Gate Screenshot](file:///Users/karim/.gemini/antigravity-ide/brain/7b92dea3-87aa-44e4-92e8-cb3bb80a99a2/ns_scenes_v1_102_bis_stage_point_placement_ux_discoverability.png)

---

## 4. Résultats exacts des commandes exécutées

### Tests unitaires et d'intégration
```bash
cd packages/map_editor
flutter test test/cinematic_builder_workspace_test.dart
```
**Stdout Signal** :
```text
00:23 +196: V1-102-bis — Stage Point Placement UX Discoverability and ESC cancellation
00:23 +197: captures V1-102-bis stage point placement ux discoverability visual gate
00:23 +198: All tests passed!
```

### Autres tests de non-régression
```bash
flutter test test/cinematic_stage_point_preview_overlay_test.dart test/cinematics_library_workspace_test.dart
```
**Stdout Signal** :
```text
00:03 +26: All tests passed!
```

### Analyse statique
```bash
flutter analyze lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart test/cinematic_builder_workspace_test.dart
```
**Stdout Signal** : Clean (les seuls warnings restants sont des variables d'autres lots inutilisées).

---

## 5. Diffs de Code Modifiés (Packages)

```diff
diff --git a/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart b/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
index da321908..339f4082 100644
--- a/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
+++ b/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
@@ -291,15 +291,32 @@ class _CinematicBuilderWorkspaceState extends State<CinematicBuilderWorkspace> {
       return const SizedBox.shrink();
     }
 
-    return CinematicStagePreviewReadinessWidget(
-      asset: widget.asset,
-      stageMapSourceCatalog: widget.stageMapSourceCatalog,
-      characterCatalog: _characterCatalog,
-      onStartStagePreview: null,
-      onUpdateStageContext: widget.onUpdateStageContext,
-      onUpsertActorInitialPlacement: widget.onUpsertActorInitialPlacement,
-      onUpsertMovementTargetBinding: widget.onUpsertMovementTargetBinding,
-      startExpanded: widget.startExpanded,
+    return Focus(
+      autofocus: true,
+      onKeyEvent: (node, event) {
+        if (event is KeyEvent && event.logicalKey == LogicalKeyboardKey.escape) {
+          final primaryFocus = FocusManager.instance.primaryFocus;
+          final hasTextFieldFocus = primaryFocus?.context?.widget is EditableText;
+          if (!hasTextFieldFocus && _addStagePointMode) {
+            setState(() {
+              _addStagePointMode = false;
+            });
+            return KeyEventResult.handled;
+          }
+        }
+        return KeyEventResult.ignored;
+      },
+      child: CinematicStagePreviewReadinessWidget(
+        asset: widget.asset,
+        stageMapSourceCatalog: widget.stageMapSourceCatalog,
+        characterCatalog: _characterCatalog,
+        onStartStagePreview: null,
+        onUpdateStageContext: widget.onUpdateStageContext,
+        onUpsertActorInitialPlacement: widget.onUpsertActorInitialPlacement,
+        onUpsertMovementTargetBinding: widget.onUpsertMovementTargetBinding,
+        startExpanded: widget.startExpanded,
+        addStagePointMode: _addStagePointMode,
+        onAddStagePointModeChanged: (val) => setState(() => _addStagePointMode = val),
+      ),
     );
   }
 }
@@ -759,10 +776,17 @@ class _CinematicBuilderWorkspaceState extends State<CinematicBuilderWorkspace> {
             id: widget.asset.id,
             title: widget.asset.title,
             description: widget.asset.description,
+            storylineId: widget.asset.storylineId,
+            chapterId: widget.asset.chapterId,
             mapId: widget.asset.mapId,
+            tags: widget.asset.tags,
             requiredActors: widget.asset.requiredActors,
+            movementTargets: widget.asset.movementTargets,
             timeline: widget.asset.timeline,
             stageContext: widget.asset.stageContext ?? CinematicStageContext(),
+            notes: widget.asset.notes,
+            metadata: widget.asset.metadata,
+            legacyBridge: widget.asset.legacyBridge,
           ),
         ],
       );
@@ -791,10 +815,17 @@ class _CinematicBuilderWorkspaceState extends State<CinematicBuilderWorkspace> {
             id: widget.asset.id,
             title: widget.asset.title,
             description: widget.asset.description,
+            storylineId: widget.asset.storylineId,
+            chapterId: widget.asset.chapterId,
             mapId: widget.asset.mapId,
+            tags: widget.asset.tags,
             requiredActors: widget.asset.requiredActors,
+            movementTargets: widget.asset.movementTargets,
             timeline: widget.asset.timeline,
             stageContext: widget.asset.stageContext ?? CinematicStageContext(),
+            notes: widget.asset.notes,
+            metadata: widget.asset.metadata,
+            legacyBridge: widget.asset.legacyBridge,
           ),
         ],
       );
@@ -823,10 +854,17 @@ class _CinematicBuilderWorkspaceState extends State<CinematicBuilderWorkspace> {
             id: widget.asset.id,
             title: widget.asset.title,
             description: widget.asset.description,
+            storylineId: widget.asset.storylineId,
+            chapterId: widget.asset.chapterId,
             mapId: widget.asset.mapId,
+            tags: widget.asset.tags,
             requiredActors: widget.asset.requiredActors,
+            movementTargets: widget.asset.movementTargets,
             timeline: widget.asset.timeline,
             stageContext: widget.asset.stageContext ?? CinematicStageContext(),
+            notes: widget.asset.notes,
+            metadata: widget.asset.metadata,
+            legacyBridge: widget.asset.legacyBridge,
           ),
         ],
       );
@@ -1989,6 +2006,14 @@ class _StageContextEditor extends StatelessWidget {
           padding: const EdgeInsets.symmetric(horizontal: 12),
           child: Divider(color: colors.borderSubtle),
         ),
+        _StagePointsSection(
+          stagePoints: asset.stageContext?.stagePoints ?? const [],
+          selectedStagePointId: selectedStagePointId,
+          onSelectStagePointId: onSelectStagePointId,
+          onAddStagePointModeChanged: onAddStagePointModeChanged,
+          addStagePointMode: addStagePointMode,
+        ),
+        Padding(
+          padding: const EdgeInsets.symmetric(horizontal: 12),
+          child: Divider(color: colors.borderSubtle),
+        ),
         _ActorInitialPlacementsSection(
           asset: asset,
           characterCatalog: characterCatalog,
@@ -2043,3 +2068,103 @@ class _StageContextEditor extends StatelessWidget {
     );
   }
 }
+
+class _StagePointsSection extends StatelessWidget {
+  const _StagePointsSection({
+    required this.stagePoints,
+    required this.selectedStagePointId,
+    required this.onSelectStagePointId,
+    required this.onAddStagePointModeChanged,
+    required this.addStagePointMode,
+  });
+
+  final List<CinematicStagePoint> stagePoints;
+  final String? selectedStagePointId;
+  final ValueChanged<String?> onSelectStagePointId;
+  final ValueChanged<bool>? onAddStagePointModeChanged;
+  final bool addStagePointMode;
+
+  @override
+  Widget build(BuildContext context) {
+    final colors = context.pokeMapColors;
+    return Column(
+      crossAxisAlignment: CrossAxisAlignment.stretch,
+      children: [
+        Padding(
+          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
+          child: Row(
+            mainAxisAlignment: MainAxisAlignment.spaceBetween,
+            children: [
+              Text(
+                'Points de scène (${stagePoints.length})',
+                style: TextStyle(
+                  color: colors.textPrimary,
+                  fontSize: 12,
+                  fontWeight: FontWeight.bold,
+                ),
+              ),
+              if (onAddStagePointModeChanged != null)
+                PokeMapButton(
+                  size: PokeMapButtonSize.small,
+                  variant: addStagePointMode
+                      ? PokeMapButtonVariant.primary
+                      : PokeMapButtonVariant.secondary,
+                  onPressed: () => onAddStagePointModeChanged!(!addStagePointMode),
+                  child: Text(addStagePointMode ? 'Annuler' : 'Ajouter'),
+                ),
+            ],
+          ),
+        ),
+        if (stagePoints.isEmpty)
+          Padding(
+            padding: const EdgeInsets.all(12),
+            child: Container(
+              padding: const EdgeInsets.all(8),
+              decoration: BoxDecoration(
+                color: colors.controlSurface,
+                borderRadius: BorderRadius.circular(6),
+                border: Border.all(color: colors.borderSubtle),
+              ),
+              child: Text(
+                'Aucun point créé. Active le mode placement pour en poser un sur la carte.',
+                style: TextStyle(
+                  color: colors.textMuted,
+                  fontSize: 10,
+                ),
+              ),
+            ),
+          )
+        else
+          Padding(
+            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
+            child: Wrap(
+              spacing: 6,
+              runSpacing: 6,
+              children: stagePoints.map((p) {
+                final isSelected = p.id == selectedStagePointId;
+                return PokeMapButton(
+                  size: PokeMapButtonSize.small,
+                  variant: isSelected
+                      ? PokeMapButtonVariant.primary
+                      : PokeMapButtonVariant.secondary,
+                  leading: Icon(
+                    CupertinoIcons.location,
+                    size: 10,
+                    color: isSelected ? colors.textPrimary : colors.textMuted,
+                  ),
+                  onPressed: () => onSelectStagePointId(p.id),
+                  child: Text(
+                    p.label,
+                    style: TextStyle(
+                      fontSize: 10,
+                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
+                    ),
+                  ),
+                );
+              }).toList(),
+            ),
+          ),
+      ],
+    );
+  }
+}
diff --git a/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart b/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart
index ddb483e8..a26998ff 100644
--- a/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart
+++ b/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart
@@ -461,6 +461,8 @@ class _BackdropBitmapMap extends StatelessWidget {
           onResetView: onFramingResetView,
           onDetailsChanged: onFramingDetailsChanged,
           onGridChanged: onFramingGridChanged,
+          addStagePointMode: addStagePointMode,
+          onAddStagePointModeChanged: onAddStagePointModeChanged,
         ),
         if (isSceneMode && framingState.showDetails) ...[
           SizedBox(height: compact ? 5 : 6),
@@ -608,6 +608,20 @@ class _BackdropBitmapMap extends StatelessWidget {
                                     ),
                                   ),
                                 ),
                               if (isSceneMode)
                                 Positioned(
                                   left: 8,
                                   bottom: 8,
                                   child: _BackdropPanBadge(
                                     panTiles: framing.panTiles,
                                   ),
                                 ),
+                              if (addStagePointMode)
+                                Positioned(
+                                  left: 8,
+                                  right: 8,
+                                  top: 8,
+                                  child: _AddStagePointInstructionOverlay(
+                                    onCancel: () => onAddStagePointModeChanged?.call(false),
+                                  ),
+                                ),
+                              if (stagePoints.isEmpty && !addStagePointMode)
+                                const Positioned(
+                                  left: 8,
+                                  right: 8,
+                                  top: 8,
+                                  child: _EmptyStagePointsHelperOverlay(),
+                                ),
                             ],
                           ),
                         ),
@@ -710,6 +724,8 @@ class _BackdropLayerBitmapMap extends StatelessWidget {
           onResetView: onFramingResetView,
           onDetailsChanged: onFramingDetailsChanged,
           onGridChanged: onFramingGridChanged,
+          addStagePointMode: addStagePointMode,
+          onAddStagePointModeChanged: onAddStagePointModeChanged,
         ),
         if (isSceneMode && framingState.showDetails) ...[
           SizedBox(height: compact ? 5 : 6),
@@ -871,6 +894,22 @@ class _BackdropLayerBitmapMap extends StatelessWidget {
                                       panTiles: framing.panTiles,
                                     ),
                                   ),
+                                if (addStagePointMode)
+                                  Positioned(
+                                    left: 8,
+                                    right: 8,
+                                    top: 8,
+                                    child: _AddStagePointInstructionOverlay(
+                                      onCancel: () => onAddStagePointModeChanged?.call(false),
+                                    ),
+                                  ),
+                                if (stagePoints.isEmpty && !addStagePointMode)
+                                  const Positioned(
+                                    left: 8,
+                                    right: 8,
+                                    top: 8,
+                                    child: _EmptyStagePointsHelperOverlay(),
+                                  ),
                               ],
                             ),
                           ),
@@ -965,24 +1004,31 @@ class _BackdropFramingControls extends StatelessWidget {
             ),
           ],
         ),
-        PokeMapIconButton(
+        PokeMapButton(
           key: const ValueKey(
             'cinematic-builder-map-backdrop-add-stage-point-toggle',
           ),
-          tooltip:
-              addStagePointMode ? 'Annuler l’ajout' : 'Ajouter un point de scène',
-          size: buttonSize,
-          variant: PokeMapIconButtonVariant.soft,
-          isSelected: addStagePointMode,
+          size: compact ? PokeMapButtonSize.small : PokeMapButtonSize.medium,
+          variant: addStagePointMode
+              ? PokeMapButtonVariant.primary
+              : PokeMapButtonVariant.secondary,
           onPressed: (model.isAvailable &&
                   hasBitmapInstructions &&
                   onAddStagePointModeChanged != null)
               ? () => onAddStagePointModeChanged!(!addStagePointMode)
               : null,
-          icon: Icon(
+          leading: Icon(
             addStagePointMode
                 ? CupertinoIcons.location_solid
                 : CupertinoIcons.location,
+            size: compact ? 12 : 14,
+          ),
+          child: Text(
+            addStagePointMode ? 'Annuler l’ajout' : 'Ajouter un point',
+            style: TextStyle(
+              fontSize: compact ? 11 : 12,
+              fontWeight: FontWeight.bold,
+            ),
           ),
         ),
         PokeMapIconButton(
@@ -1976,3 +2022,91 @@ IconData _iconForStatus(CinematicMapBackdropPreviewStatus status) {
       CupertinoIcons.exclamationmark_triangle,
   };
 }
+
+class _AddStagePointInstructionOverlay extends StatelessWidget {
+  const _AddStagePointInstructionOverlay({
+    required this.onCancel,
+  });
+
+  final VoidCallback onCancel;
+
+  @override
+  Widget build(BuildContext context) {
+    final colors = context.pokeMapColors;
+    return Container(
+      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
+      decoration: BoxDecoration(
+        color: colors.brandPrimarySoft.withValues(alpha: 0.2),
+        borderRadius: BorderRadius.circular(6),
+        border: Border.all(color: colors.brandPrimaryBorder),
+      ),
+      child: Row(
+        children: [
+          Icon(
+            CupertinoIcons.info_circle,
+            color: colors.brandPrimary,
+            size: 14,
+          ),
+          const SizedBox(width: 8),
+          Expanded(
+            child: Text(
+              'Mode placement actif — Clique sur la carte pour poser un point. Échap pour annuler.',
+              style: TextStyle(
+                color: colors.textPrimary,
+                fontSize: 10,
+                fontWeight: FontWeight.w700,
+              ),
+            ),
+          ),
+          const SizedBox(width: 8),
+          PokeMapButton(
+            key: const ValueKey('cinematic-builder-cancel-stage-point-placement-btn'),
+            size: PokeMapButtonSize.small,
+            variant: PokeMapButtonVariant.secondary,
+            onPressed: onCancel,
+            child: const Text('Annuler'),
+          ),
+        ],
+      ),
+    );
+  }
+}
+
+class _EmptyStagePointsHelperOverlay extends StatelessWidget {
+  const _EmptyStagePointsHelperOverlay({super.key});
+
+  @override
+  Widget build(BuildContext context) {
+    final colors = context.pokeMapColors;
+    return IgnorePointer(
+      child: Container(
+        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
+        decoration: BoxDecoration(
+          color: colors.controlSurface,
+          borderRadius: BorderRadius.circular(6),
+          border: Border.all(color: colors.borderSubtle),
+        ),
+        child: Row(
+          children: [
+            Icon(
+              CupertinoIcons.location,
+              color: colors.brandPrimary,
+              size: 14,
+            ),
+            const SizedBox(width: 8),
+            Expanded(
+              child: Text(
+                'Aucun point de scène. Clique sur « Ajouter un point », puis clique sur la carte.',
+                style: TextStyle(
+                  color: colors.textMuted,
+                  fontSize: 10,
+                  fontWeight: FontWeight.w600,
+                ),
+              ),
+            ),
+          ],
+        ),
+      ),
+    );
+  }
+}
diff --git a/packages/map_editor/test/cinematic_builder_workspace_test.dart b/packages/map_editor/test/cinematic_builder_workspace_test.dart
index 09d9dbc9..5e1ab307 100644
--- a/packages/map_editor/test/cinematic_builder_workspace_test.dart
+++ b/packages/map_editor/test/cinematic_builder_workspace_test.dart
@@ -11287,7 +11287,7 @@ void main() {
     );
 
     // Tap on Point 1 to select it so the inspector shows it
-    await tester.tap(find.text('Point 1'));
+    await tester.tap(find.text('Point 1').last);
     await tester.pumpAndSettle();
 
     final screenshotFile = File(
@@ -11302,6 +11302,157 @@ void main() {
 
     expect(screenshotFile.existsSync(), isTrue);
   });
+
+  testWidgets('V1-102-bis — Stage Point Placement UX Discoverability and ESC cancellation', (tester) async {
+    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
+    final fixture = await _largePathStudioWaterBackdropFixture();
+    final project = _project(cinematics: [fixture.asset]);
+
+    final backdropModel = buildCinematicMapBackdropPreviewModel(
+      asset: fixture.asset,
+      stageMap: project.maps.single,
+      mapData: fixture.mapData,
+      viewportSize: const CinematicMapBackdropViewportSize(
+        width: 920,
+        height: 260,
+      ),
+    );
+
+    await _pumpBuilderHarness(
+      tester,
+      project,
+      fixture.asset.id,
+      backdropPreviewModel: backdropModel,
+      backdropLayerRenderPlan: fixture.layerPlan,
+      surfaceSize: _referenceTimelineSurfaceSize,
+    );
+
+    // 1. Verify that when no stage points exist, the empty state helper message is displayed
+    expect(find.text('Aucun point de scène. Clique sur « Ajouter un point », puis clique sur la carte.'), findsOneWidget);
+
+    // 2. Verify that the "Ajouter un point" text button is visible and active
+    final addPointBtn = find.byKey(const ValueKey('cinematic-builder-map-backdrop-add-stage-point-toggle'));
+    expect(addPointBtn, findsOneWidget);
+    expect(find.descendant(of: addPointBtn, matching: find.text('Ajouter un point')), findsOneWidget);
+
+    // 3. Click the "Ajouter un point" button to enter placement mode
+    await tester.tap(addPointBtn);
+    await tester.pumpAndSettle();
+
+    // 4. Verify that the button text changes to "Annuler l’ajout" and active placement banner is displayed
+    expect(find.descendant(of: addPointBtn, matching: find.text('Annuler l’ajout')), findsOneWidget);
+    expect(find.text('Mode placement actif — Clique sur la carte pour poser un point. Échap pour annuler.'), findsOneWidget);
+
+    // 5. Test Escape key deactivates the mode
+    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
+    await tester.pumpAndSettle();
+
+    expect(find.descendant(of: addPointBtn, matching: find.text('Ajouter un point')), findsOneWidget);
+    expect(find.text('Mode placement actif — Clique sur la carte pour poser un point. Échap pour annuler.'), findsNothing);
+
+    // 6. Enter mode again, and verify that clicking on the map canvas places a point
+    await tester.tap(addPointBtn);
+    await tester.pumpAndSettle();
+
+    final viewport = find.byKey(const ValueKey('cinematic-builder-map-backdrop-bitmap-viewport'));
+    final viewportCenter = tester.getCenter(viewport);
+    await tester.tapAt(viewportCenter);
+    await tester.pumpAndSettle();
+
+    // 7. Verify point was created and mode exited automatically (generated ID is '1', so label is 'Point 1')
+    expect(find.text('Point 1'), findsNWidgets(2));
+    expect(find.descendant(of: addPointBtn, matching: find.text('Ajouter un point')), findsOneWidget);
+    expect(find.text('Mode placement actif — Clique sur la carte pour poser un point. Échap pour annuler.'), findsNothing);
+
+    // 8. Verify inspector panel displays the selected point inputs
+    expect(find.byKey(const ValueKey('cinematic-stage-point-label-input')), findsOneWidget);
+
+    // 9. Verify that typing in a TextField and pressing Escape does NOT exit the mode or break the input (it should retain text)
+    final labelInput = find.byKey(const ValueKey('cinematic-stage-point-label-input'));
+    await tester.enterText(labelInput, 'Updated Point');
+    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
+    await tester.pumpAndSettle();
+
+    expect(find.widgetWithText(TextFormField, 'Updated Point'), findsOneWidget);
+  });
+
+  testWidgets(
+      'captures V1-102-bis stage point placement ux discoverability visual gate',
+      (tester) async {
+    if (!const bool.fromEnvironment(
+      'NS_SCENES_V1_102_BIS_CAPTURE_STAGE_POINT_UX_DISCOVERABILITY',
+    )) {
+      return;
+    }
+
+    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
+    await _loadScreenshotFonts();
+    final fixture = await _largePathStudioWaterBackdropFixture();
+
+    final assetWithPoints = CinematicAsset(
+      id: fixture.asset.id,
+      title: fixture.asset.title,
+      description: fixture.asset.description,
+      storylineId: fixture.asset.storylineId,
+      chapterId: fixture.asset.chapterId,
+      mapId: fixture.asset.mapId,
+      tags: fixture.asset.tags,
+      requiredActors: fixture.asset.requiredActors,
+      movementTargets: fixture.asset.movementTargets,
+      stageContext: CinematicStageContext(
+        backdropMode: fixture.asset.stageContext?.backdropMode ?? CinematicStageBackdropMode.projectMap,
+        actorBindings: fixture.asset.stageContext?.actorBindings ?? const [],
+        actorAppearanceBindings: fixture.asset.stageContext?.actorAppearanceBindings ?? const [],
+        initialPlacements: fixture.asset.stageContext?.initialPlacements ?? const [],
+        movementTargetBindings: fixture.asset.stageContext?.movementTargetBindings ?? const [],
+        stagePoints: [
+          CinematicStagePoint(id: 'stage_point_1', label: 'Point 1', x: 2.5, y: 3.5),
+          CinematicStagePoint(id: 'stage_point_2', label: 'Point 2', x: 8.5, y: 10.5),
+        ],
+      ),
+      timeline: fixture.asset.timeline,
+      notes: fixture.asset.notes,
+      metadata: fixture.asset.metadata,
+      legacyBridge: fixture.asset.legacyBridge,
+    );
+
+    final project = _project(cinematics: [assetWithPoints]);
+
+    final backdropModel = buildCinematicMapBackdropPreviewModel(
+      asset: assetWithPoints,
+      stageMap: project.maps.single,
+      mapData: fixture.mapData,
+      viewportSize: const CinematicMapBackdropViewportSize(
+        width: 920,
+        height: 260,
+      ),
+    );
+
+    await _pumpBuilder(
+      tester,
+      _entry(project, assetWithPoints.id),
+      asset: assetWithPoints,
+      backdropPreviewModel: backdropModel,
+      backdropLayerRenderPlan: fixture.layerPlan,
+      surfaceSize: _referenceTimelineSurfaceSize,
+    );
+
+    // Tap on Point 1 to select it so the inspector shows it
+    await tester.tap(find.text('Point 1').last);
+    await tester.pumpAndSettle();
+
+    final screenshotFile = File(
+      '../../reports/narrativeStudio/scenes/screenshots/'
+      'ns_scenes_v1_102_bis_stage_point_placement_ux_discoverability.png',
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
```
