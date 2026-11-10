import 'package:flutter/foundation.dart';
import 'package:map_core/map_core_domain.dart';

import '../application/editable_map_document.dart';
import '../application/map_context_command_runner.dart';
import '../application/map_context_menu_actions.dart';
import '../application/map_context_menu_model.dart';
import '../application/map_entity_editing_commands.dart';
import '../application/map_selection_context.dart';
import '../application/map_workspace_controller.dart';
import '../application/map_workspace_editing_state.dart';

class MapEditingInputSession extends ChangeNotifier {
  MapEditingInputSession({
    required this.controller,
    required this.view,
    this.referenceGuard,
    this.navigation,
  });

  final MapWorkspaceController controller;
  final MapWorkspaceEditingState? Function() view;
  final MapReferenceGuard? referenceGuard;
  final MapContextNavigation? navigation;
  GridPos? cell;
  String? mapId;
  EditableMapDocument? _document;
  MapContextTarget? target;
  List<MapContextTarget> targets = const [];
  List<MapContextAction> actions = const [];
  bool get contextOpen => cell != null;
  bool get editingAvailable =>
      !controller.loading && !controller.catalogBusy && !contextOpen;

  MapContextActionContext? contextAt(GridPos position) {
    final document = controller.active;
    final project = controller.project;
    if (document == null ||
        project == null ||
        document.exteriorDecoration?.editingExterior == true) {
      return null;
    }
    return MapContextActionContext(
      document: document,
      project: project,
      position: position,
      referenceGuard: referenceGuard,
    );
  }

  void open(GridPos position, {MapContextTarget? selected}) {
    final context = contextAt(position);
    if (context == null) return;
    cell = position;
    mapId = context.document.current.id;
    _document = context.document;
    targets = mapContextTargetsAt(context.document, context.project, position);
    target = selected == null
        ? targets.firstOrNull
        : targets.where(selected.sameAs).firstOrNull;
    actions = mapContextActionsFor(target, context);
    _applySelection();
    notifyListeners();
  }

  void select(MapContextTarget selected) {
    final context = cell == null ? null : contextAt(cell!);
    if (context == null ||
        !identical(context.document, _document) ||
        context.document.current.id != mapId) {
      dismiss();
      return;
    }
    if (!targets.any(selected.sameAs)) return;
    target = selected;
    actions = mapContextActionsFor(selected, context);
    _applySelection();
    notifyListeners();
  }

  void _applySelection() {
    final document = controller.active;
    if (document == null) return;
    final selected = target;
    if (selected == null) {
      view()?.clearSelection(document);
    } else {
      view()?.select(document, selectionFamilyOf(selected.family), selected.id);
    }
  }

  void dismiss() {
    if (!contextOpen) return;
    cell = null;
    mapId = null;
    _document = null;
    target = null;
    targets = const [];
    actions = const [];
    notifyListeners();
  }

  void reconcile() {
    final document = controller.active;
    if (mapId != null &&
        (!identical(document, _document) ||
            mapId != document?.current.id ||
            document?.exteriorDecoration?.editingExterior == true)) {
      dismiss();
    }
  }

  void run(MapContextCommand command) {
    final position = cell;
    final selected = target;
    final context = position == null ? null : contextAt(position);
    if (context == null ||
        !identical(context.document, _document) ||
        mapId != context.document.current.id) {
      dismiss();
      return;
    }
    dismiss();
    final refusal = MapContextCommandRunner(
      context,
      navigation:
          navigation ??
          MapContextNavigation(
            startMove: (target) {
              final state = view();
              if (state != null) {
                armMapContextMove(
                  document: context.document,
                  view: state,
                  target: target,
                  anchor: context.position,
                );
              }
            },
          ),
    ).run(command, selected);
    if (refusal != null) context.document.error = refusal;
    notifyListeners();
  }
}
