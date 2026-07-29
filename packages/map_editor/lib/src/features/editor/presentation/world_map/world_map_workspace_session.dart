import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:map_core/map_core.dart';

import '../../../../ui/design_system/pokemap_desktop_layout.dart';
import '../../application/world_map_tool_activation.dart';
import '../../application/world_map_tool_family.dart';

part 'world_map_workspace_session.freezed.dart';

@freezed
class WorldMapWorkspaceSession with _$WorldMapWorkspaceSession {
  const factory WorldMapWorkspaceSession({
    @Default(true) bool explorerExpanded,
    @Default(true) bool inspectorVisible,
    @Default(PokeMapDesktopLayoutTokens.inspectorWidth) double inspectorWidth,
    @Default(WorldMapToolFamily.selection) WorldMapToolFamily activeFamily,
    @Default(WorldMapPaintSubtool.tile) WorldMapPaintSubtool lastPaintSubtool,
    @Default(WorldMapPlacementSubtool.object)
    WorldMapPlacementSubtool lastPlacementSubtool,
    @Default(<String, WorldMapPaintSubtool>{})
    Map<String, WorldMapPaintSubtool> lastPaintSubtoolByLayerId,
    WorldMapInspectorKind? pinnedInspectorKind,
    GridPos? selectedCell,
    String? selectedCellMapId,
  }) = _WorldMapWorkspaceSession;
}

final worldMapWorkspaceSessionProvider = NotifierProvider<
    WorldMapWorkspaceSessionController, WorldMapWorkspaceSession>(
  WorldMapWorkspaceSessionController.new,
);

class WorldMapWorkspaceSessionController
    extends Notifier<WorldMapWorkspaceSession> {
  String? _currentMapId;

  @override
  WorldMapWorkspaceSession build() => const WorldMapWorkspaceSession();

  void setExplorerExpanded(bool expanded) {
    if (state.explorerExpanded == expanded) return;
    state = state.copyWith(explorerExpanded: expanded);
  }

  void setInspectorVisible(bool visible) {
    if (state.inspectorVisible == visible) return;
    state = state.copyWith(inspectorVisible: visible);
  }

  void setInspectorWidth(double width) {
    if (!width.isFinite || width <= 0 || state.inspectorWidth == width) {
      return;
    }
    state = state.copyWith(inspectorWidth: width);
  }

  WorldMapToolActivationResult activateLayers(
    WorldMapToolActivationHost editorNotifier,
  ) {
    final result = editorNotifier.activateWorldMapTool(
      const ActivateWorldMapSelection(),
    );
    if (!result.accepted) return result;
    var candidate = _forMapOwnership(
      state,
      editorNotifier.worldMapToolActivationSessionSnapshot.activeMapId,
    );
    candidate = candidate.copyWith(activeFamily: WorldMapToolFamily.layers);
    state = candidate;
    return result;
  }

  void pinInspector(WorldMapInspectorKind? kind) {
    if (state.pinnedInspectorKind == kind) return;
    state = state.copyWith(pinnedInspectorKind: kind);
  }

  void selectCell({
    required String mapId,
    required GridPos? cell,
  }) {
    var candidate = _forMapOwnership(state, mapId);
    candidate = candidate.copyWith(
      selectedCell: cell,
      selectedCellMapId: cell == null ? null : mapId,
    );
    if (candidate == state) return;
    state = candidate;
  }

  void clearSelectedCell() {
    if (state.selectedCell == null && state.selectedCellMapId == null) return;
    state = state.copyWith(
      selectedCell: null,
      selectedCellMapId: null,
    );
  }

  void resetForMap(String? mapId) {
    final candidate = _forMapOwnership(state, mapId);
    if (candidate == state) return;
    state = candidate;
  }

  WorldMapToolActivationResult activateTool(
    WorldMapToolActivationHost editorNotifier,
    WorldMapToolActivationRequest request,
  ) {
    final result = editorNotifier.activateWorldMapTool(request);
    if (!result.accepted) return result;

    final editorState = editorNotifier.worldMapToolActivationSessionSnapshot;
    var candidate = _forMapOwnership(
      state,
      editorState.activeMapId,
    );
    candidate = switch (request) {
      ActivateWorldMapSelection() => candidate.copyWith(
          activeFamily: WorldMapToolFamily.selection,
        ),
      ActivateWorldMapPaint(:final subtool) => candidate.copyWith(
          activeFamily: WorldMapToolFamily.paint,
          lastPaintSubtool: subtool,
          lastPaintSubtoolByLayerId: editorState.activeLayerId == null
              ? candidate.lastPaintSubtoolByLayerId
              : <String, WorldMapPaintSubtool>{
                  ...candidate.lastPaintSubtoolByLayerId,
                  editorState.activeLayerId!: subtool,
                },
          selectedCell: null,
          selectedCellMapId: null,
        ),
      ActivateWorldMapErase() => candidate.copyWith(
          activeFamily: WorldMapToolFamily.erase,
          selectedCell: null,
          selectedCellMapId: null,
        ),
      ActivateWorldMapPlacement(:final subtool) => candidate.copyWith(
          activeFamily: WorldMapToolFamily.place,
          lastPlacementSubtool: subtool,
          selectedCell: null,
          selectedCellMapId: null,
        ),
    };
    state = candidate;
    return result;
  }

  WorldMapToolActivationResult activateWorldMapTool(
    WorldMapToolActivationHost editorNotifier,
    WorldMapToolActivationRequest request,
  ) {
    return activateTool(editorNotifier, request);
  }

  void setActiveLayer(
    WorldMapToolActivationHost editorNotifier,
    String layerId,
  ) {
    final result = editorNotifier.setActiveWorldMapLayer(
      layerId: layerId,
      toolRequest: _toolRequestForLayer(state, layerId),
    );
    final editorState = editorNotifier.worldMapToolActivationSessionSnapshot;
    if (editorState.activeLayerId != layerId) return;

    var candidate = _forMapOwnership(state, editorState.activeMapId);
    final remembered = candidate.lastPaintSubtoolByLayerId[layerId];
    if (remembered != null) {
      candidate = candidate.copyWith(lastPaintSubtool: remembered);
    }
    if (!result.accepted) {
      candidate = candidate.copyWith(
        activeFamily: WorldMapToolFamily.selection,
      );
    }
    if (candidate == state) return;
    state = candidate;
  }

  WorldMapToolActivationRequest _toolRequestForLayer(
    WorldMapWorkspaceSession source,
    String layerId,
  ) {
    return switch (source.activeFamily) {
      WorldMapToolFamily.selection ||
      WorldMapToolFamily.layers =>
        const ActivateWorldMapSelection(),
      WorldMapToolFamily.paint => ActivateWorldMapPaint(
          source.lastPaintSubtoolByLayerId[layerId] ?? source.lastPaintSubtool,
        ),
      WorldMapToolFamily.erase => const ActivateWorldMapErase(),
      WorldMapToolFamily.place => ActivateWorldMapPlacement(
          source.lastPlacementSubtool,
        ),
    };
  }

  WorldMapWorkspaceSession _forMapOwnership(
    WorldMapWorkspaceSession source,
    String? mapId,
  ) {
    if (_currentMapId == mapId) return source;
    _currentMapId = mapId;
    return source.copyWith(
      lastPaintSubtool: WorldMapPaintSubtool.tile,
      lastPaintSubtoolByLayerId: const <String, WorldMapPaintSubtool>{},
      selectedCell: null,
      selectedCellMapId: null,
    );
  }
}
