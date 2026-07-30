import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../application/map_context_command.dart';
import '../../application/map_context_command_projector.dart';
import '../../application/map_context_target.dart';
import '../../application/world_map_target_editor_intent.dart';
import '../../state/editor_notifier.dart';
import '../../../../ui/canvas/map_canvas.dart';

sealed class MapContextMenuState {
  const MapContextMenuState();
}

@immutable
final class MapContextMenuClosed extends MapContextMenuState {
  const MapContextMenuClosed();
}

@immutable
final class MapContextMenuOpen extends MapContextMenuState {
  const MapContextMenuOpen({
    required this.target,
    required this.anchor,
    required this.invocation,
    required this.entries,
    this.targetEditorResolution,
  });

  final MapContextTarget target;
  final Offset anchor;
  final MapContextMenuInvocation invocation;
  final List<MapContextCommandEntry> entries;
  final WorldMapTargetEditorResolution? targetEditorResolution;
}

final mapContextMenuControllerProvider =
    NotifierProvider<MapContextMenuController, MapContextMenuState>(
  MapContextMenuController.new,
);

/// Owns the transient, projected snapshot for the one World Map context menu.
///
/// Map mutation remains in the workspace orchestration layer. In particular,
/// [open] projects capabilities exactly once and freezes that result until the
/// menu closes or another target replaces it.
final class MapContextMenuController extends Notifier<MapContextMenuState> {
  FocusNode? _invokerFocusNode;
  int _latestOpenRequestRevision = 0;

  FocusNode? get invokerFocusNode => _invokerFocusNode;

  @override
  MapContextMenuState build() {
    ref.listen(
      editorNotifierProvider.select(
        (editor) => (
          map: editor.activeMap,
          tool: editor.activeTool,
          placedElementId: editor.selectedPlacedElementInstanceId,
          entityId: editor.selectedEntityId,
          mapEventId: editor.selectedMapEventId,
          gameplayZoneId: editor.selectedGameplayZoneId,
          triggerId: editor.selectedTriggerId,
          warpId: editor.selectedWarpId,
        ),
      ),
      (_, __) => close(),
    );
    return const MapContextMenuClosed();
  }

  /// Reserves the next menu publication and invalidates any in-flight request.
  ///
  /// This lets callers resolve an asynchronous capability snapshot without an
  /// older request replacing a newer target when it completes.
  int beginOpenRequest() {
    final revision = ++_latestOpenRequestRevision;
    _closeCurrent(restoreFocus: false);
    return revision;
  }

  bool open({
    required MapContextTarget target,
    required Offset anchor,
    required MapContextMenuInvocation invocation,
    required MapData map,
    required ProjectManifest? project,
    required NarrativeEventBuilderProjectReadModel? eventBuilderReadModel,
    required String? activeLayerId,
    FocusNode? invokerFocusNode,
    int? requestRevision,
  }) {
    if (requestRevision != null &&
        requestRevision != _latestOpenRequestRevision) {
      return false;
    }
    if (requestRevision == null) {
      _latestOpenRequestRevision++;
    }
    final projection = const MapContextCommandProjector().project(
      target: target,
      map: map,
      project: project,
      eventBuilderReadModel: eventBuilderReadModel,
      activeLayerId: activeLayerId,
    );
    _invokerFocusNode = invokerFocusNode;
    state = MapContextMenuOpen(
      target: target,
      anchor: anchor,
      invocation: invocation,
      entries: projection.entries,
      targetEditorResolution: projection.targetEditorResolution,
    );
    return true;
  }

  void close({bool restoreFocus = true}) {
    _latestOpenRequestRevision++;
    _closeCurrent(restoreFocus: restoreFocus);
  }

  void _closeCurrent({required bool restoreFocus}) {
    if (state is MapContextMenuClosed) return;
    final invoker = _invokerFocusNode;
    _invokerFocusNode = null;
    state = const MapContextMenuClosed();
    if (!restoreFocus || invoker == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (invoker.context != null && invoker.canRequestFocus) {
        invoker.requestFocus();
      }
    });
  }

  void closeForToolChange() => close();
}
