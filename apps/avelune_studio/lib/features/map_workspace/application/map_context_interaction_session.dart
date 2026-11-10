import 'package:flutter/painting.dart' show Offset;
import 'package:map_core/map_core_domain.dart';

import 'editable_map_document.dart';
import 'map_context_command_runner.dart';
import 'map_context_menu_actions.dart';
import 'map_context_menu_model.dart';
import 'map_selection_context.dart';
import 'map_workspace_editing_state.dart';

class MapContextMenuRequest {
  const MapContextMenuRequest({
    required this.position,
    required this.targets,
    required this.selected,
    required this.actions,
  });
  final Offset position;
  final List<MapContextTarget> targets;
  final MapContextTarget? selected;
  final List<MapContextAction> actions;
}

class MapContextInteractionSession {
  MapContextInteractionSession({
    required this.contextAt,
    required this.view,
    required this.navigation,
    this.changed,
  });
  final MapContextActionContext? Function(GridPos) contextAt;
  final MapWorkspaceEditingState? Function() view;
  final MapContextNavigation Function(MapContextActionContext) navigation;
  final void Function()? changed;
  GridPos? _cell;
  String? _mapId;
  EditableMapDocument? _document;
  MapContextMenuRequest? request;
  bool _disposed = false;

  void releaseIfStale(String? mapId, {bool exterior = false}) {
    if (_mapId != null && (_mapId != mapId || exterior)) close(notify: false);
  }

  bool open(GridPos cell, Offset position, {MapContextTarget? target}) {
    if (_disposed) return false;
    final context = contextAt(cell);
    if (context == null) return false;
    final targets = mapContextTargetsAt(
      context.document,
      context.project,
      cell,
    );
    final selected = target == null
        ? targets.firstOrNull
        : targets.where(target.sameAs).firstOrNull;
    _cell = cell;
    _mapId = context.document.current.id;
    _document = context.document;
    request = MapContextMenuRequest(
      position: position,
      targets: targets,
      selected: selected,
      actions: mapContextActionsFor(selected, context),
    );
    _applySelection(context);
    changed?.call();
    return true;
  }

  bool select(MapContextTarget target) {
    if (_disposed || request == null || _cell == null) return false;
    final context = contextAt(_cell!);
    if (context == null ||
        !identical(context.document, _document) ||
        context.document.current.id != _mapId) {
      close();
      return false;
    }
    request = MapContextMenuRequest(
      position: request!.position,
      targets: request!.targets,
      selected: target,
      actions: mapContextActionsFor(target, context),
    );
    _applySelection(context);
    changed?.call();
    return true;
  }

  void _applySelection(MapContextActionContext context) {
    final target = request?.selected;
    if (target == null) {
      view()?.clearSelection(context.document);
    } else {
      view()?.select(
        context.document,
        selectionFamilyOf(target.family),
        target.id,
      );
    }
  }

  void close({bool notify = true}) {
    if (request == null) return;
    request = null;
    _cell = null;
    _mapId = null;
    _document = null;
    if (notify && !_disposed) changed?.call();
  }

  bool run(MapContextCommand command) {
    if (_disposed) return false;
    final cell = _cell;
    final target = request?.selected;
    final context = cell == null ? null : contextAt(cell);
    if (context == null ||
        !identical(context.document, _document) ||
        _mapId != context.document.current.id) {
      close();
      return false;
    }
    close();
    final refusal = MapContextCommandRunner(
      context,
      navigation: navigation(context),
    ).run(command, target);
    if (refusal != null) context.document.error = refusal;
    changed?.call();
    return refusal == null;
  }

  void dispose() {
    _disposed = true;
    close(notify: false);
  }
}
