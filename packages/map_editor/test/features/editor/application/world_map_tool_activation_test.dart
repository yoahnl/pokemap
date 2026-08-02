import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/map_history_snapshot.dart';
import 'package:map_editor/src/application/models/terrain_selection_mode.dart';
import 'package:map_editor/src/features/border_map_editing/application/border_tool_availability.dart';
import 'package:map_editor/src/features/border_map_editing/state/border_map_editing_providers.dart';
import 'package:map_editor/src/features/editor/application/world_map_tool_activation.dart';
import 'package:map_editor/src/features/editor/application/world_map_tool_family.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_workspace_session.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';

void main() {
  group('EditorNotifier.activateWorldMapTool', () {
    test('maps selection and every paint subtool to an existing engine tool',
        () {
      final container = _createContainer();
      final notifier = container.read(editorNotifierProvider.notifier);

      notifier.state = _stateForLayer('tile').copyWith(
        activeTool: EditorToolType.entityPlacement,
        selectedEntityId: 'npc',
      );
      var result = notifier.activateWorldMapTool(
        const ActivateWorldMapSelection(),
      );
      expect(result.accepted, isTrue);
      expect(result.resultingTool, EditorToolType.selection);
      expect(result.rejectionReason, isNull);
      expect(notifier.state.selectedEntityId, 'npc');

      final cases = <({
        String layerId,
        WorldMapPaintSubtool subtool,
        EditorToolType tool,
        TerrainSelectionMode? terrainMode,
      })>[
        (
          layerId: 'tile',
          subtool: WorldMapPaintSubtool.tile,
          tool: EditorToolType.tilePaint,
          terrainMode: null,
        ),
        (
          layerId: 'smart-terrain',
          subtool: WorldMapPaintSubtool.terrain,
          tool: EditorToolType.terrainPaint,
          terrainMode: TerrainSelectionMode.terrain,
        ),
        (
          layerId: 'smart-path',
          subtool: WorldMapPaintSubtool.path,
          tool: EditorToolType.terrainPaint,
          terrainMode: TerrainSelectionMode.path,
        ),
        (
          layerId: 'surface',
          subtool: WorldMapPaintSubtool.surface,
          tool: EditorToolType.surfacePaint,
          terrainMode: null,
        ),
        (
          layerId: 'border',
          subtool: WorldMapPaintSubtool.border,
          tool: EditorToolType.borderPaint,
          terrainMode: null,
        ),
        (
          layerId: 'collision',
          subtool: WorldMapPaintSubtool.collision,
          tool: EditorToolType.collisionPaint,
          terrainMode: null,
        ),
      ];

      for (final testCase in cases) {
        notifier.state = _stateForLayer(testCase.layerId).copyWith(
          activeBrush: const EditorBrush.projectElement(elementId: 'tree'),
        );
        if (testCase.layerId == 'border') {
          container
              .read(activeBorderFeatureControllerProvider.notifier)
              .selectFeature(
                map: _map,
                layerId: 'border',
                featureId: 'coast',
              );
        }

        result = notifier.activateWorldMapTool(
          ActivateWorldMapPaint(testCase.subtool),
        );

        expect(result.accepted, isTrue, reason: testCase.subtool.name);
        expect(
          result.resultingTool,
          testCase.tool,
          reason: testCase.subtool.name,
        );
        expect(result.rejectionReason, isNull, reason: testCase.subtool.name);
        expect(
          notifier.state.activeTool,
          testCase.tool,
          reason: testCase.subtool.name,
        );
        if (testCase.terrainMode != null) {
          expect(
            notifier.state.terrainSelectionMode,
            testCase.terrainMode,
            reason: testCase.subtool.name,
          );
        }
        expect(
          notifier.state.activeBrush,
          testCase.subtool == WorldMapPaintSubtool.tile
              ? const EditorBrush.projectElement(elementId: 'tree')
              : const EditorBrush.none(),
          reason: '${testCase.subtool.name} must retain only a compatible '
              'project-element brush',
        );
      }

      notifier.state = _stateForLayer('smart-terrain');
      result = notifier.activateWorldMapTool(
        const ActivateWorldMapPaint(WorldMapPaintSubtool.terrain),
      );
      expect(result.accepted, isTrue);
      expect(result.resultingTool, EditorToolType.terrainPaint);
      expect(
        notifier.state.terrainSelectionMode,
        TerrainSelectionMode.terrain,
      );

      notifier.state = _stateForLayer('smart-path');
      result = notifier.activateWorldMapTool(
        const ActivateWorldMapPaint(WorldMapPaintSubtool.path),
      );
      expect(result.accepted, isTrue);
      expect(result.resultingTool, EditorToolType.terrainPaint);
      expect(
        notifier.state.terrainSelectionMode,
        TerrainSelectionMode.path,
      );
    });

    test(
        'selection preserves the current object while exiting secondary edit '
        'modes atomically', () {
      final container = _createContainer();
      final notifier = container.read(editorNotifierProvider.notifier)
        ..state = _stateForLayer('tile').copyWith(
          activeTool: EditorToolType.gameplayZonePlacement,
          activeBrush: const EditorBrush.tile(
            tileId: 3,
            tilesetId: 'world',
          ),
          selectedEntityId: 'entity',
          selectedEnvironmentAreaId: 'environment',
          npcWaypointPlacementEntityId: 'entity',
          environmentMaskEditMode: EnvironmentMaskEditMode.paint,
          gameplayZoneDraftArea: const MapRect(
            pos: GridPos(x: 0, y: 0),
            size: GridSize(width: 2, height: 2),
          ),
        );
      final emissions = <EditorState>[];
      final subscription = container.listen<EditorState>(
        editorNotifierProvider,
        (_, next) => emissions.add(next),
      );

      final result = notifier.activateWorldMapTool(
        const ActivateWorldMapSelection(),
      );

      subscription.close();
      expect(result.accepted, isTrue);
      expect(emissions, hasLength(1));
      final emitted = emissions.single;
      expect(emitted.activeTool, EditorToolType.selection);
      expect(
        emitted.activeBrush,
        const EditorBrush.tile(tileId: 3, tilesetId: 'world'),
      );
      expect(emitted.selectedEntityId, 'entity');
      expect(emitted.selectedEnvironmentAreaId, 'environment');
      expect(emitted.npcWaypointPlacementEntityId, isNull);
      expect(emitted.environmentMaskEditMode, isNull);
      expect(emitted.gameplayZoneDraftArea, isNull);
    });

    test('maps erase by canonical layer capability', () {
      final container = _createContainer();
      final notifier = container.read(editorNotifierProvider.notifier);

      for (final layerId in <String>[
        'tile',
        'surface',
        'collision',
        'smart-terrain',
        'smart-path',
      ]) {
        notifier.state = _stateForLayer(layerId).copyWith(
          activeBrush: const EditorBrush.tile(
            tileId: 3,
            tilesetId: 'world',
          ),
        );
        final result = notifier.activateWorldMapTool(
          const ActivateWorldMapErase(),
        );
        expect(result.accepted, isTrue, reason: layerId);
        expect(result.resultingTool, EditorToolType.eraser, reason: layerId);
        expect(
          notifier.state.activeBrush,
          const EditorBrush.none(),
          reason: layerId,
        );
      }

      notifier.state = _stateForLayer('border').copyWith(
        activeBrush: const EditorBrush.tile(
          tileId: 3,
          tilesetId: 'world',
        ),
      );
      container
          .read(activeBorderFeatureControllerProvider.notifier)
          .selectFeature(
            map: _map,
            layerId: 'border',
            featureId: 'coast',
          );
      final borderResult = notifier.activateWorldMapTool(
        const ActivateWorldMapErase(),
      );
      expect(borderResult.accepted, isTrue);
      expect(borderResult.resultingTool, EditorToolType.borderErase);
      expect(notifier.state.activeBrush, const EditorBrush.none());
    });

    test('maps every placement subtool and keeps universal layer capability',
        () {
      final container = _createContainer();
      final notifier = container.read(editorNotifierProvider.notifier);
      final cases = <WorldMapPlacementSubtool, EditorToolType>{
        WorldMapPlacementSubtool.object: EditorToolType.tilePaint,
        WorldMapPlacementSubtool.entity: EditorToolType.entityPlacement,
        WorldMapPlacementSubtool.event: EditorToolType.eventPlacement,
        WorldMapPlacementSubtool.trigger: EditorToolType.triggerPlacement,
        WorldMapPlacementSubtool.warp: EditorToolType.warpPlacement,
        WorldMapPlacementSubtool.gameplayZone:
            EditorToolType.gameplayZonePlacement,
      };

      for (final entry in cases.entries) {
        notifier.state = _stateForLayer(
          entry.key == WorldMapPlacementSubtool.object ? 'tile' : 'terrain',
        ).copyWith(
          activeBrush: const EditorBrush.tile(
            tileId: 3,
            tilesetId: 'world',
          ),
        );
        final result = notifier.activateWorldMapTool(
          ActivateWorldMapPlacement(entry.key),
        );
        expect(result.accepted, isTrue, reason: entry.key.name);
        expect(result.resultingTool, entry.value, reason: entry.key.name);
        expect(notifier.state.activeTool, entry.value, reason: entry.key.name);
        expect(
          notifier.state.activeBrush,
          const EditorBrush.none(),
          reason: entry.key.name,
        );
      }
    });

    test('rejects editing activations when no map is active', () {
      final container = _createContainer();
      final notifier = container.read(editorNotifierProvider.notifier)
        ..state = EditorState(
          project: _project,
          activeTool: EditorToolType.selection,
          activeBrush: const EditorBrush.tile(
            tileId: 3,
            tilesetId: 'world',
          ),
          statusMessage: 'status-sentinel',
          errorMessage: 'error-sentinel',
        );
      final before = notifier.state;
      final emissions = <EditorState>[];
      final subscription = container.listen<EditorState>(
        editorNotifierProvider,
        (_, next) => emissions.add(next),
      );

      for (final request in <WorldMapToolActivationRequest>[
        const ActivateWorldMapPaint(WorldMapPaintSubtool.tile),
        const ActivateWorldMapErase(),
        const ActivateWorldMapPlacement(WorldMapPlacementSubtool.entity),
        const ActivateWorldMapPlacement(WorldMapPlacementSubtool.event),
        const ActivateWorldMapPlacement(WorldMapPlacementSubtool.trigger),
        const ActivateWorldMapPlacement(WorldMapPlacementSubtool.warp),
        const ActivateWorldMapPlacement(
          WorldMapPlacementSubtool.gameplayZone,
        ),
      ]) {
        final result = notifier.activateWorldMapTool(request);

        expect(result.accepted, isFalse,
            reason: request.runtimeType.toString());
        expect(
          result.rejectionReason,
          isNotEmpty,
          reason: request.runtimeType.toString(),
        );
        expect(notifier.state, before, reason: request.runtimeType.toString());
      }

      subscription.close();
      expect(emissions, isEmpty);
    });

    test('rejects incompatible paint capabilities without any state write', () {
      final container = _createContainer();
      final notifier = container.read(editorNotifierProvider.notifier);
      final cases = <({WorldMapPaintSubtool subtool, String layerId})>[
        (subtool: WorldMapPaintSubtool.tile, layerId: 'terrain'),
        (subtool: WorldMapPaintSubtool.terrain, layerId: 'tile'),
        (subtool: WorldMapPaintSubtool.path, layerId: 'terrain'),
        (subtool: WorldMapPaintSubtool.surface, layerId: 'terrain'),
        (subtool: WorldMapPaintSubtool.border, layerId: 'terrain'),
        (subtool: WorldMapPaintSubtool.collision, layerId: 'terrain'),
      ];

      for (final testCase in cases) {
        notifier.state = _stateForLayer(testCase.layerId).copyWith(
          activeTool: EditorToolType.entityPlacement,
          activeBrush: const EditorBrush.tile(
            tileId: 7,
            tilesetId: 'world',
          ),
          errorMessage: 'sentinel-error',
          statusMessage: 'sentinel-status',
        );
        final before = notifier.state;
        final emissions = <EditorState>[];
        final subscription = container.listen<EditorState>(
          editorNotifierProvider,
          (_, next) => emissions.add(next),
        );

        final result = notifier.activateWorldMapTool(
          ActivateWorldMapPaint(testCase.subtool),
        );

        subscription.close();
        expect(result.accepted, isFalse, reason: testCase.subtool.name);
        expect(result.resultingTool, isNull, reason: testCase.subtool.name);
        expect(
          result.rejectionReason,
          isNotEmpty,
          reason: testCase.subtool.name,
        );
        expect(notifier.state, before, reason: testCase.subtool.name);
        expect(emissions, isEmpty, reason: testCase.subtool.name);
      }
    });

    test(
      'place object drops tile brushes, accepts inert, then arms a compatible element',
      () {
        final container = _createContainer();
        final notifier = container.read(editorNotifierProvider.notifier)
          ..state = _stateForLayer('tile').copyWith(
            activeBrush: const EditorBrush.tile(
              tileId: 4,
              tilesetId: 'world',
            ),
          );

        final result = notifier.activateWorldMapTool(
          const ActivateWorldMapPlacement(
            WorldMapPlacementSubtool.object,
          ),
        );

        expect(result.accepted, isTrue);
        expect(result.resultingTool, EditorToolType.tilePaint);
        expect(notifier.state.activeTool, EditorToolType.tilePaint);
        expect(notifier.state.activeBrush, const EditorBrush.none());
        expect(
          notifier.state.tilesElementsPanelMode,
          TilesElementsPanelMode.palette,
        );
        final afterActivation = notifier.state;

        notifier.selectProjectElement('tree');

        expect(
          notifier.state.activeBrush,
          const EditorBrush.projectElement(elementId: 'tree'),
        );
        expect(notifier.state.activeTool, EditorToolType.tilePaint);
        expect(notifier.state.activeMap, same(afterActivation.activeMap));
        expect(notifier.state.mapUndoStack, afterActivation.mapUndoStack);
        expect(notifier.state.mapRedoStack, afterActivation.mapRedoStack);
      },
    );

    test('place object retains only a current compatible project element', () {
      final container = _createContainer();
      final notifier = container.read(editorNotifierProvider.notifier);

      notifier.state = _stateForLayer('tile').copyWith(
        activeBrush: const EditorBrush.projectElement(elementId: 'tree'),
      );
      var result = notifier.activateWorldMapTool(
        const ActivateWorldMapPlacement(WorldMapPlacementSubtool.object),
      );
      expect(result.accepted, isTrue);
      expect(
        notifier.state.activeBrush,
        const EditorBrush.projectElement(elementId: 'tree'),
      );

      notifier.state = _stateForLayer('tile').copyWith(
        activeBrush: const EditorBrush.projectElement(elementId: 'lamp'),
      );
      result = notifier.activateWorldMapTool(
        const ActivateWorldMapPlacement(WorldMapPlacementSubtool.object),
      );
      expect(result.accepted, isTrue);
      expect(notifier.state.activeBrush, const EditorBrush.none());

      notifier.state = _stateForLayer('tile').copyWith(
        activeBrush:
            const EditorBrush.projectElement(elementId: 'missing-element'),
      );
      result = notifier.activateWorldMapTool(
        const ActivateWorldMapPlacement(WorldMapPlacementSubtool.object),
      );
      expect(result.accepted, isTrue);
      expect(notifier.state.activeBrush, const EditorBrush.none());
    });

    test('paint tile retains a project element compatible with the layer', () {
      final container = _createContainer();
      final notifier = container.read(editorNotifierProvider.notifier)
        ..state = _stateForLayer('tile').copyWith(
          activeBrush: const EditorBrush.projectElement(elementId: 'tree'),
        );

      final result = notifier.activateWorldMapTool(
        const ActivateWorldMapPaint(WorldMapPaintSubtool.tile),
      );

      expect(result.accepted, isTrue);
      expect(notifier.state.activeTool, EditorToolType.tilePaint);
      expect(
        notifier.state.activeBrush,
        const EditorBrush.projectElement(elementId: 'tree'),
      );
    });

    test('paint tile rejects project elements from another or missing source',
        () {
      final container = _createContainer();
      final notifier = container.read(editorNotifierProvider.notifier);

      for (final elementId in <String>['lamp', 'missing-element']) {
        notifier.state = _stateForLayer('tile').copyWith(
          activeBrush: EditorBrush.projectElement(elementId: elementId),
        );

        final result = notifier.activateWorldMapTool(
          const ActivateWorldMapPaint(WorldMapPaintSubtool.tile),
        );

        expect(result.accepted, isTrue, reason: elementId);
        expect(notifier.state.activeTool, EditorToolType.tilePaint);
        expect(
          notifier.state.activeBrush,
          const EditorBrush.none(),
          reason: elementId,
        );
      }
    });

    test('paint tile retains only a compatible current tile source', () {
      final container = _createContainer();
      final notifier = container.read(editorNotifierProvider.notifier);

      notifier.state = _stateForLayer('tile').copyWith(
        activeBrush: const EditorBrush.tile(tileId: 4, tilesetId: 'world'),
      );
      var result = notifier.activateWorldMapTool(
        const ActivateWorldMapPaint(WorldMapPaintSubtool.tile),
      );
      expect(result.accepted, isTrue);
      expect(
        notifier.state.activeBrush,
        const EditorBrush.tile(tileId: 4, tilesetId: 'world'),
      );

      notifier.state = _stateForLayer('tile').copyWith(
        activeBrush: const EditorBrush.tile(tileId: 4, tilesetId: 'details'),
      );
      result = notifier.activateWorldMapTool(
        const ActivateWorldMapPaint(WorldMapPaintSubtool.tile),
      );
      expect(result.accepted, isTrue);
      expect(notifier.state.activeBrush, const EditorBrush.none());
    });

    for (final testCase in <({
      String label,
      WorldMapToolActivationRequest borderRequest,
      WorldMapToolActivationRequest? tileRequest,
      EditorToolType resultingTool,
      WorldMapToolFamily family,
    })>[
      (
        label: 'paint',
        borderRequest: const ActivateWorldMapPaint(WorldMapPaintSubtool.border),
        tileRequest: const ActivateWorldMapPaint(WorldMapPaintSubtool.tile),
        resultingTool: EditorToolType.borderPaint,
        family: WorldMapToolFamily.paint,
      ),
      (
        label: 'erase',
        borderRequest: const ActivateWorldMapErase(),
        tileRequest: null,
        resultingTool: EditorToolType.borderErase,
        family: WorldMapToolFamily.erase,
      ),
    ]) {
      test(
          'returning to a Border layer atomically restores ${testCase.label} '
          'with its canonical feature', () {
        final container = _createContainer();
        final editor = container.read(editorNotifierProvider.notifier)
          ..state = _stateForLayer('border').copyWith(
            activeTool: EditorToolType.selection,
          );
        final controller =
            container.read(worldMapWorkspaceSessionProvider.notifier);
        controller.resetForMap('map-a');
        container
            .read(activeBorderFeatureControllerProvider.notifier)
            .selectFeature(
              map: _map,
              layerId: 'border',
              featureId: 'coast',
            );
        expect(
          controller.activateTool(editor, testCase.borderRequest).accepted,
          isTrue,
        );

        controller.setActiveLayer(editor, 'tile');
        if (testCase.tileRequest case final tileRequest?) {
          expect(
            controller.activateTool(editor, tileRequest).accepted,
            isTrue,
          );
        }
        expect(
          container.read(activeBorderFeatureControllerProvider).activeFeatureId,
          isNull,
        );

        final emissions = <EditorState>[];
        final subscription = container.listen<EditorState>(
          editorNotifierProvider,
          (_, next) => emissions.add(next),
        );

        controller.setActiveLayer(editor, 'border');

        subscription.close();
        expect(emissions, hasLength(1));
        expect(editor.state.activeLayerId, 'border');
        expect(editor.state.activeTool, testCase.resultingTool);
        final session = container.read(worldMapWorkspaceSessionProvider);
        expect(session.activeFamily, testCase.family);
        if (testCase.family == WorldMapToolFamily.paint) {
          expect(session.lastPaintSubtool, WorldMapPaintSubtool.border);
          expect(
            session.lastPaintSubtoolByLayerId['border'],
            WorldMapPaintSubtool.border,
          );
        }
        final borderSelection =
            container.read(activeBorderFeatureControllerProvider);
        expect(borderSelection.activeLayerId, 'border');
        expect(borderSelection.activeFeatureId, 'coast');
      });
    }

    test('border rejection reuses the canonical availability reason', () {
      final container = _createContainer();
      final notifier = container.read(editorNotifierProvider.notifier)
        ..state = _stateForLayer('border');
      container.read(activeBorderFeatureControllerProvider.notifier).clear();
      final before = notifier.state;
      final expected = assessBorderToolAvailability(
        manifest: before.project,
        map: before.activeMap,
        activeLayerId: before.activeLayerId,
        activeFeatureId: null,
      ).disabledReason;

      for (final request in <WorldMapToolActivationRequest>[
        const ActivateWorldMapPaint(WorldMapPaintSubtool.border),
        const ActivateWorldMapErase(),
      ]) {
        final result = notifier.activateWorldMapTool(request);

        expect(result.accepted, isFalse);
        expect(result.resultingTool, isNull);
        expect(result.rejectionReason, expected);
        expect(notifier.state, before);
      }
    });

    test(
      'surface preflight rejects wrong layer and stale preset with full preservation',
      () {
        final container = _createContainer();
        final notifier = container.read(editorNotifierProvider.notifier);
        final undo = MapHistorySnapshot(
          map: _map,
          activeLayerId: 'undo-layer',
        );
        final redo = MapHistorySnapshot(
          map: _map,
          activeLayerId: 'redo-layer',
        );

        for (final initial in <EditorState>[
          _stateForLayer('tile').copyWith(selectedSurfacePresetId: 'water'),
          _stateForLayer('surface').copyWith(
            selectedSurfacePresetId: 'stale-surface',
          ),
        ]) {
          notifier.state = initial.copyWith(
            activeTool: EditorToolType.eventPlacement,
            activeBrush: const EditorBrush.tile(
              tileId: 3,
              tilesetId: 'world',
            ),
            selectedPlacedElementInstanceId: 'placed',
            selectedEntityId: 'entity',
            selectedMapEventId: 'event',
            selectedWarpId: 'warp',
            selectedTriggerId: 'trigger',
            selectedGameplayZoneId: 'zone',
            mapUndoStack: <MapHistorySnapshot>[undo],
            mapRedoStack: <MapHistorySnapshot>[redo],
            canUndoMap: true,
            canRedoMap: true,
            isDirty: true,
            statusMessage: 'status-sentinel',
            errorMessage: 'error-sentinel',
          );
          final before = notifier.state;
          final emissions = <EditorState>[];
          final subscription = container.listen<EditorState>(
            editorNotifierProvider,
            (_, next) => emissions.add(next),
          );

          final result = notifier.activateWorldMapTool(
            const ActivateWorldMapPaint(WorldMapPaintSubtool.surface),
          );

          subscription.close();
          expect(result.accepted, isFalse);
          expect(result.resultingTool, isNull);
          expect(result.rejectionReason, isNotEmpty);
          expect(notifier.state, before);
          expect(emissions, isEmpty);
        }
      },
    );

    test(
        'accepted paint, place and erase transitions each emit once and clear '
        'every stale edit selection', () {
      final container = _createContainer();
      final notifier = container.read(editorNotifierProvider.notifier);
      final cases = <({
        WorldMapToolActivationRequest request,
        EditorToolType expectedTool,
        EditorBrush? expectedBrush,
      })>[
        (
          request: const ActivateWorldMapPaint(WorldMapPaintSubtool.tile),
          expectedTool: EditorToolType.tilePaint,
          expectedBrush: const EditorBrush.projectElement(elementId: 'tree'),
        ),
        (
          request: const ActivateWorldMapPlacement(
            WorldMapPlacementSubtool.object,
          ),
          expectedTool: EditorToolType.tilePaint,
          expectedBrush: const EditorBrush.projectElement(elementId: 'tree'),
        ),
        (
          request: const ActivateWorldMapErase(),
          expectedTool: EditorToolType.eraser,
          expectedBrush: const EditorBrush.none(),
        ),
      ];

      for (final testCase in cases) {
        notifier.state = _stateForLayer('tile').copyWith(
          activeTool: EditorToolType.selection,
          activeBrush: const EditorBrush.projectElement(elementId: 'tree'),
          selectedPlacedElementInstanceId: 'placed',
          selectedEntityId: 'entity',
          selectedMapEventId: 'event',
          selectedWarpId: 'warp',
          selectedTriggerId: 'trigger',
          selectedGameplayZoneId: 'zone',
          npcWaypointPlacementEntityId: 'entity',
          selectedEnvironmentAreaId: 'environment',
          environmentMaskEditMode: EnvironmentMaskEditMode.paint,
          gameplayZoneDraftArea: const MapRect(
            pos: GridPos(x: 0, y: 0),
            size: GridSize(width: 2, height: 2),
          ),
        );
        final emissions = <EditorState>[];
        final subscription = container.listen<EditorState>(
          editorNotifierProvider,
          (_, next) => emissions.add(next),
        );

        final result = notifier.activateWorldMapTool(testCase.request);

        subscription.close();
        expect(
          result.accepted,
          isTrue,
          reason: testCase.request.runtimeType.toString(),
        );
        expect(
          emissions,
          hasLength(1),
          reason: testCase.request.runtimeType.toString(),
        );
        final emitted = emissions.single;
        expect(emitted.activeTool, testCase.expectedTool);
        if (testCase.expectedBrush case final expectedBrush?) {
          expect(emitted.activeBrush, expectedBrush);
        }
        _expectEditSelectionsCleared(emitted);
      }
    });
  });
}

void _expectEditSelectionsCleared(EditorState state) {
  expect(state.selectedPlacedElementInstanceId, isNull);
  expect(state.selectedEntityId, isNull);
  expect(state.selectedMapEventId, isNull);
  expect(state.selectedWarpId, isNull);
  expect(state.selectedTriggerId, isNull);
  expect(state.selectedGameplayZoneId, isNull);
  expect(state.npcWaypointPlacementEntityId, isNull);
  expect(state.selectedEnvironmentAreaId, isNull);
  expect(state.environmentMaskEditMode, isNull);
  expect(state.gameplayZoneDraftArea, isNull);
}

ProviderContainer _createContainer() {
  final container = ProviderContainer();
  final keepAlive = container.listen<EditorState>(
    editorNotifierProvider,
    (_, __) {},
    fireImmediately: true,
  );
  addTearDown(() {
    keepAlive.close();
    container.dispose();
  });
  return container;
}

EditorState _stateForLayer(String layerId) {
  return EditorState(
    project: _project,
    activeMap: _map,
    activeLayerId: layerId,
    selectedSurfacePresetId: 'water',
    savedMapSnapshot: _map,
  );
}

final _project = ProjectManifest(
  name: 'World map tools',
  version: ProjectVersion.v5,
  maps: const <ProjectMapEntry>[
    ProjectMapEntry(
      id: 'map-a',
      name: 'Map A',
      relativePath: 'maps/map-a.json',
    ),
  ],
  tilesets: const <ProjectTilesetEntry>[
    ProjectTilesetEntry(
      id: 'world',
      name: 'World',
      relativePath: 'tilesets/world.png',
    ),
    ProjectTilesetEntry(
      id: 'details',
      name: 'Details',
      relativePath: 'tilesets/details.png',
    ),
  ],
  elements: const <ProjectElementEntry>[
    ProjectElementEntry(
      id: 'tree',
      name: 'Tree',
      tilesetId: 'world',
      categoryId: 'decor',
      frames: <TilesetVisualFrame>[
        TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
      ],
    ),
    ProjectElementEntry(
      id: 'lamp',
      name: 'Lamp',
      tilesetId: 'details',
      categoryId: 'decor',
      frames: <TilesetVisualFrame>[
        TilesetVisualFrame(source: TilesetSourceRect(x: 1, y: 0)),
      ],
    ),
  ],
  surfaceCatalog: ProjectSurfaceCatalog(
    presets: <ProjectSurfacePreset>[
      ProjectSurfacePreset(
        id: 'water',
        name: 'Water',
        variantAnimations: SurfaceVariantAnimationRefSet(
          refs: <SurfaceVariantAnimationRef>[
            SurfaceVariantAnimationRef(
              role: SurfaceVariantRole.isolated,
              animationId: 'water-isolated',
            ),
          ],
        ),
      ),
    ],
  ),
  borderCatalog: ProjectBorderCatalog(
    records: <BorderBlueprintRecord>[
      BorderBlueprintRecord(
        id: 'coast-blueprint',
        draft: BorderBlueprintDraft(
          baseRevision: 1,
          definition: BorderBlueprintDraftDefinition(
            name: 'Coast',
            previewSeed: BorderSignedInt64.zero,
            template: BorderBlueprintTemplate.organicEdge,
            primitives: const <BorderPrimitiveDraft>[],
            defaults: _borderParams,
            sortOrder: 0,
          ),
        ),
        latestPublished: BorderBlueprintRevision(
          revision: 1,
          definition: BorderBlueprintPublishedDefinition(
            name: 'Coast',
            previewSeed: BorderSignedInt64.zero,
            template: BorderBlueprintTemplate.organicEdge,
            primitives: const <BorderPublishedPrimitive>[],
            defaults: _borderParams,
            sortOrder: 0,
          ),
        ),
      ),
    ],
  ),
  smartTileCatalog: ProjectSmartTileCatalog(
    materials: const <ProjectSmartTileMaterial>[
      ProjectSmartTileMaterial(
        id: 'grass',
        name: 'Grass',
        connectionGroupId: 'ground',
      ),
      ProjectSmartTileMaterial(
        id: 'road',
        name: 'Road',
        connectionGroupId: 'road',
      ),
    ],
    presets: const <ProjectSmartTilePreset>[
      ProjectSmartTilePreset(
        id: 'smart-terrain-preset',
        name: 'Smart Terrain',
        usage: SmartTileUsage.terrain,
        topology: SmartTileTopology.cardinal4,
        templateHint: SmartTileTemplateHint.edge16,
        coveragePolicy: SmartTileCoveragePolicy.sparse,
        coverageProfile: SmartTileCoverageProfile(
          mode: SmartTileCoverageMode.template,
        ),
        transformPolicy: SmartTileTransformPolicy(),
        defaultMaterialId: 'grass',
        allowedMaterialIds: <String>['grass'],
      ),
      ProjectSmartTilePreset(
        id: 'smart-path-preset',
        name: 'Smart Path',
        usage: SmartTileUsage.path,
        topology: SmartTileTopology.uniform,
        templateHint: SmartTileTemplateHint.simple,
        coveragePolicy: SmartTileCoveragePolicy.sparse,
        coverageProfile: SmartTileCoverageProfile(
          mode: SmartTileCoverageMode.template,
        ),
        transformPolicy: SmartTileTransformPolicy(),
        defaultMaterialId: 'road',
        allowedMaterialIds: <String>['road'],
      ),
    ],
  ),
);

final _borderParams = BorderGenerationParams(
  irregularityPermille: 0,
  detailDensityPermille: 0,
  variationPermille: 0,
  maxOverlapPx: 0,
  gapTolerancePx: 0,
  depthRows: 1,
);

final _map = MapData(
  id: 'map-a',
  name: 'Map A',
  version: ProjectVersion.v5,
  size: const GridSize(width: 4, height: 4),
  layers: <MapLayer>[
    const TileLayer(
      id: 'tile',
      name: 'Tile',
      tilesetId: 'world',
      tiles: <int>[],
    ),
    const ObjectLayer(id: 'terrain', name: 'Non-paint layer'),
    const SmartTileLayer(
      id: 'smart-terrain',
      name: 'Smart Terrain',
      presetId: 'smart-terrain-preset',
      usage: SmartTileUsage.terrain,
      materialPalette: <String>['', 'grass'],
      field: SmartTileField.cell(
        semanticCells: <int>[
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
        ],
      ),
    ),
    const SmartTileLayer(
      id: 'smart-path',
      name: 'Smart Path',
      presetId: 'smart-path-preset',
      usage: SmartTileUsage.path,
      materialPalette: <String>['', 'road'],
      field: SmartTileField.cell(
        semanticCells: <int>[
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
        ],
      ),
    ),
    const SurfaceLayer(id: 'surface', name: 'Surface'),
    const CollisionLayer(
      id: 'collision',
      name: 'Collision',
      collisions: <bool>[
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
      ],
    ),
    MapLayer.border(
      id: 'border',
      name: 'Border',
      content: BorderLayerContent(
        features: <BorderFeature>[
          BorderFeature(
            id: 'coast',
            name: 'Coast',
            blueprintId: 'coast-blueprint',
            seed: BorderSignedInt64.zero,
            geometry: BorderRegionGeometry(
              width: 4,
              height: 4,
              cells: const <bool>[
                false,
                false,
                false,
                false,
                false,
                false,
                false,
                false,
                false,
                false,
                false,
                false,
                false,
                false,
                false,
                false,
              ],
            ),
            overrides: const <BorderSlotOverride>[],
            keepOutRegions: const <BorderKeepOutRegion>[],
          ),
        ],
      ),
    ),
  ],
);
