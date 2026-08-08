import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:map_core/map_core.dart';

import '../../../../ui/design_system/pokemap_desktop_layout.dart';
import '../../application/world_map_tool_activation.dart';
import '../../application/world_map_tool_family.dart';
import '../../state/editor_notifier.dart';
import '../../tools/editor_tool.dart';

part 'world_map_workspace_session.freezed.dart';

typedef WorldMapPaintReplayOutcome = ({
  ActivateWorldMapPaint request,
  WorldMapPaintRoutingResult routing,
});

enum WorldMapPaintRoutingOutcome {
  activated,
  setupRequired,
  choiceRequired,
  missingLayer,
  rejected,
}

typedef WorldMapPaintRoutingResult = ({
  WorldMapPaintRoutingOutcome outcome,
  ActivateWorldMapPaint request,
  String? layerId,
  List<String> compatibleLayerIds,
  WorldMapToolActivationResult? activation,
});

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

final worldMapAccessibilityErrorProvider = NotifierProvider<
    WorldMapAccessibilityErrorController, WorldMapAccessibilityAnnouncement?>(
  WorldMapAccessibilityErrorController.new,
);

class WorldMapAccessibilityAnnouncement {
  const WorldMapAccessibilityAnnouncement({
    required this.sequence,
    required this.message,
  });

  final int sequence;
  final String message;
}

class WorldMapAccessibilityErrorController
    extends Notifier<WorldMapAccessibilityAnnouncement?> {
  int _nextSequence = 0;

  @override
  WorldMapAccessibilityAnnouncement? build() => null;

  void announce(String message) {
    final normalized = message.trim();
    if (normalized.isEmpty) return;
    state = WorldMapAccessibilityAnnouncement(
      sequence: ++_nextSequence,
      message: normalized,
    );
  }

  void consume(int sequence) {
    if (state?.sequence == sequence) state = null;
  }

  void clear() {
    if (state != null) state = null;
  }
}

class WorldMapWorkspaceSessionController
    extends Notifier<WorldMapWorkspaceSession> {
  static const int _paintRoutingMemoryScopeLimit = 32;

  WorldMapDocumentScope? _currentMapScope;
  // Routing memory is session-only and keyed by project/document scope as
  // well as subtool. It never enters EditorState, JSON, or Undo/Redo.
  final LinkedHashMap<WorldMapDocumentScope, Map<WorldMapPaintSubtool, String>>
      _lastCompatiblePaintLayerIdByScope = LinkedHashMap();

  @override
  WorldMapWorkspaceSession build() {
    final editorState = ref.read(editorNotifierProvider);
    _currentMapScope = worldMapDocumentScopeFromState(editorState);
    ref.listen<WorldMapDocumentScope>(
      editorNotifierProvider.select(
        worldMapDocumentScopeFromState,
      ),
      (_, scope) => _resetForScope(scope),
    );
    return const WorldMapWorkspaceSession();
  }

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
      worldMapDocumentScopeFromSnapshot(
        editorNotifier.worldMapToolActivationSessionSnapshot,
      ),
    );
    candidate = candidate.copyWith(activeFamily: WorldMapToolFamily.layers);
    state = candidate;
    return result;
  }

  WorldMapToolActivationResult activateConnections(
    WorldMapToolActivationHost editorNotifier,
  ) {
    final result = editorNotifier.activateWorldMapTool(
      const ActivateWorldMapSelection(),
    );
    if (!result.accepted) return result;
    var candidate = _forMapOwnership(
      state,
      worldMapDocumentScopeFromSnapshot(
        editorNotifier.worldMapToolActivationSessionSnapshot,
      ),
    );
    candidate = candidate.copyWith(
      activeFamily: WorldMapToolFamily.connections,
    );
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
    var candidate = _forMapOwnership(state, _scopeForMapId(mapId));
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
    _resetForScope(_scopeForMapId(mapId));
  }

  void _resetForScope(WorldMapDocumentScope scope) {
    final candidate = _forMapOwnership(state, scope);
    if (candidate == state) return;
    state = candidate;
  }

  WorldMapToolActivationResult activateTool(
    WorldMapToolActivationHost editorNotifier,
    WorldMapToolActivationRequest request,
  ) {
    final result = editorNotifier.activateWorldMapTool(request);
    if (!result.accepted) return result;

    _publishAcceptedToolActivation(editorNotifier, request);
    return result;
  }

  void _publishAcceptedToolActivation(
    WorldMapToolActivationHost editorNotifier,
    WorldMapToolActivationRequest request,
  ) {
    final editorState = editorNotifier.worldMapToolActivationSessionSnapshot;
    var candidate = _forMapOwnership(
      state,
      worldMapDocumentScopeFromSnapshot(editorState),
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
  }

  WorldMapToolActivationResult activateWorldMapTool(
    WorldMapToolActivationHost editorNotifier,
    WorldMapToolActivationRequest request,
  ) {
    return activateTool(editorNotifier, request);
  }

  WorldMapPaintRoutingResult routePaintSubtool(
    WorldMapToolActivationHost editorNotifier,
    WorldMapPaintSubtool subtool, {
    String? chosenLayerId,
  }) {
    final request = ActivateWorldMapPaint(subtool);
    final map = editorNotifier.worldMapToolActivationMap;
    final snapshot = editorNotifier.worldMapToolActivationSessionSnapshot;
    final scope = worldMapDocumentScopeFromSnapshot(snapshot);
    if (map == null) {
      final activation = activateTool(editorNotifier, request);
      return (
        outcome: WorldMapPaintRoutingOutcome.rejected,
        request: request,
        layerId: null,
        compatibleLayerIds: const <String>[],
        activation: activation,
      );
    }
    final rememberedLayerId = _readCompatiblePaintLayer(
      scope: scope,
      subtool: subtool,
    );
    final routing = resolveWorldMapPaintLayerRouting(
      map: map,
      activeLayerId: snapshot.activeLayerId,
      subtool: subtool,
      rememberedLayerId: rememberedLayerId,
    );
    final compatibleLayerIds = routing.compatibleLayerIds;
    final targetLayerId = chosenLayerId == null
        ? routing.targetLayerId
        : compatibleLayerIds.contains(chosenLayerId)
            ? chosenLayerId
            : null;
    if (targetLayerId == null) {
      // Choice and missing-layer outcomes are pure presentation decisions:
      // the caller opens the existing inspection intent before any editor
      // layer/tool mutation is allowed.
      return (
        outcome: compatibleLayerIds.isEmpty
            ? WorldMapPaintRoutingOutcome.missingLayer
            : WorldMapPaintRoutingOutcome.choiceRequired,
        request: request,
        layerId: null,
        compatibleLayerIds: compatibleLayerIds,
        activation: null,
      );
    }

    final activation = targetLayerId == snapshot.activeLayerId
        ? editorNotifier.activateWorldMapTool(request)
        : editorNotifier.setActiveWorldMapLayer(
            layerId: targetLayerId,
            toolRequest: request,
          );
    _rememberCompatiblePaintLayer(
      scope: scope,
      subtool: subtool,
      layerId: targetLayerId,
    );
    if (activation.accepted) {
      _publishAcceptedToolActivation(editorNotifier, request);
      return (
        outcome: WorldMapPaintRoutingOutcome.activated,
        request: request,
        layerId: targetLayerId,
        compatibleLayerIds: compatibleLayerIds,
        activation: activation,
      );
    }

    final destination = editorNotifier.worldMapToolActivationSessionSnapshot;
    if (targetLayerId != snapshot.activeLayerId &&
        destination.activeLayerId == targetLayerId &&
        destination.activeTool == EditorToolType.selection) {
      var candidate = _forMapOwnership(
        state,
        worldMapDocumentScopeFromSnapshot(destination),
      );
      candidate = candidate.copyWith(
        activeFamily: WorldMapToolFamily.selection,
      );
      if (candidate != state) {
        state = candidate;
      }
    }
    return (
      outcome: WorldMapPaintRoutingOutcome.setupRequired,
      request: request,
      layerId: targetLayerId,
      compatibleLayerIds: compatibleLayerIds,
      activation: activation,
    );
  }

  void _rememberCompatiblePaintLayer({
    required WorldMapDocumentScope scope,
    required WorldMapPaintSubtool subtool,
    required String layerId,
  }) {
    final existing = _lastCompatiblePaintLayerIdByScope.remove(scope);
    _lastCompatiblePaintLayerIdByScope[scope] = <WorldMapPaintSubtool, String>{
      ...?existing,
      subtool: layerId,
    };
    while (_lastCompatiblePaintLayerIdByScope.length >
        _paintRoutingMemoryScopeLimit) {
      _lastCompatiblePaintLayerIdByScope.remove(
        _lastCompatiblePaintLayerIdByScope.keys.first,
      );
    }
  }

  String? _readCompatiblePaintLayer({
    required WorldMapDocumentScope scope,
    required WorldMapPaintSubtool subtool,
  }) {
    final remembered = _lastCompatiblePaintLayerIdByScope.remove(scope);
    if (remembered == null) {
      return null;
    }
    _lastCompatiblePaintLayerIdByScope[scope] = remembered;
    return remembered[subtool];
  }

  WorldMapPaintSubtool resolveRememberedPaintSubtool({
    required String? mapId,
    required String? layerId,
  }) {
    if (_currentMapScope?.activeMapId != mapId) {
      return WorldMapPaintSubtool.tile;
    }
    if (layerId == null) return state.lastPaintSubtool;
    return state.lastPaintSubtoolByLayerId[layerId] ?? state.lastPaintSubtool;
  }

  WorldMapPaintReplayOutcome activatePaintReplay(
    WorldMapToolActivationHost editorNotifier, {
    required String? observedMapId,
    required String? observedLayerId,
    required WorldMapPaintSubtool observedSubtool,
  }) {
    final snapshot = editorNotifier.worldMapToolActivationSessionSnapshot;
    final subtool = snapshot.activeMapId == observedMapId &&
            snapshot.activeLayerId == observedLayerId
        ? observedSubtool
        : resolveRememberedPaintSubtool(
            mapId: snapshot.activeMapId,
            layerId: snapshot.activeLayerId,
          );
    final request = ActivateWorldMapPaint(subtool);
    return (
      request: request,
      routing: routePaintSubtool(editorNotifier, subtool),
    );
  }

  void setActiveLayer(
    WorldMapToolActivationHost editorNotifier,
    String layerId,
  ) {
    final request = _toolRequestForLayer(state, layerId);
    final result = editorNotifier.setActiveWorldMapLayer(
      layerId: layerId,
      toolRequest: request,
    );
    final editorState = editorNotifier.worldMapToolActivationSessionSnapshot;
    if (editorState.activeLayerId != layerId) return;

    final scope = worldMapDocumentScopeFromSnapshot(editorState);
    var candidate = _forMapOwnership(state, scope);
    if (result.accepted && request is ActivateWorldMapPaint) {
      final subtool = request.subtool;
      final layer = editorNotifier.worldMapToolActivationMap?.layers
          .where((candidate) => candidate.id == layerId)
          .firstOrNull;
      if (layer != null && isWorldMapPaintLayerCompatible(subtool, layer)) {
        _rememberCompatiblePaintLayer(
          scope: scope,
          subtool: subtool,
          layerId: layerId,
        );
        candidate = candidate.copyWith(
          lastPaintSubtool: subtool,
          lastPaintSubtoolByLayerId: <String, WorldMapPaintSubtool>{
            ...candidate.lastPaintSubtoolByLayerId,
            layerId: subtool,
          },
        );
      }
    }
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
      WorldMapToolFamily.connections ||
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

  WorldMapDocumentScope _scopeForMapId(String? mapId) {
    return (
      projectRootPath: _currentMapScope?.projectRootPath,
      activeMapPath: _currentMapScope?.activeMapPath,
      activeMapId: mapId,
    );
  }

  WorldMapWorkspaceSession _forMapOwnership(
    WorldMapWorkspaceSession source,
    WorldMapDocumentScope scope,
  ) {
    if (_currentMapScope == scope) return source;
    _currentMapScope = scope;
    return source.copyWith(
      lastPaintSubtool: WorldMapPaintSubtool.tile,
      lastPaintSubtoolByLayerId: const <String, WorldMapPaintSubtool>{},
      selectedCell: null,
      selectedCellMapId: null,
    );
  }
}
